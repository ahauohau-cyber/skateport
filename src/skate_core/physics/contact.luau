--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/contact.rs (коммит 2e16697)
--
-- Skate 3 TU3's RenderWare contact-record construction.
--
-- This is the scalar form of the VMX128 block in TU3's two recovered
-- add-contact paths. It builds the 256-byte logical `rw::physics::Contact`
-- payload consumed in place by `ContactBatchBuild`; it does not solve the
-- contact or move a body.

local rt = require("../../rt")
local reciprocal_sqrt = require("./reciprocal_sqrt")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits

type Vector3 = vector

local contact = {}

-- pub mod tu3
contact.tu3 = {
	-- Game-side physical-material combine helper used before both recovered
	-- collision-to-contact record writers.
	COMBINE_PHYSICAL_MATERIALS = 0x8276_3078,
	-- First recovered collision-to-contact record block, end exclusive.
	GENERATE_CONTACT_A = 0x8277_A828,
	GENERATE_CONTACT_A_END = 0x8277_AA88,
	-- Second field-for-field collision-to-contact record block, end exclusive.
	GENERATE_CONTACT_B = 0x8277_BFAC,
	GENERATE_CONTACT_B_END = 0x8277_C21C,
	-- In-place contact Jacobian builder.
	CONTACT_BATCH_BUILD = 0x82AE_10C8,
}

-- Exact TU3 constant used to reject a degenerate velocity-derived tangent.
-- The Xbox data table at `0x830382B0` contains `0x00800000` in every lane.
-- This is the smallest positive normal binary32 value, not a tuned gameplay
-- threshold.
contact.CONTACT_TANGENT_MINIMUM_SQUARED = from_bits(0x0080_0000)
contact.CONTACT_FALLBACK_HALF = from_bits(0x3F00_0000)

-- The five 16-byte body vectors copied into a contact's solver workspace.
-- Original member names and offsets (Skate-era EA SDK DWARF, confirmed by TU3):
-- mCom/mId +0x10; mIfull/mInvm +0x70; mIsplt/mState +0x80; mForce/mKine +0x90;
-- mTorque/mCool +0xa0.
-- ROBLOX: Copy-структура -> таблица; поля и имена те же.
export type RetailContactBodyState = {
	-- ID written to the contact header from the collision queue's body-ref
	-- entry. Kept separate from `reaction_id` because TU3 loads them from
	-- different records.
	contact_body_id: number,
	center_of_mass: Vector3,
	reaction_id: number,
	-- Retail packed world inverse-inertia vector `mIfull = (Ixx, Ixy, Ixz)`.
	inverse_inertia_full: Vector3,
	inverse_mass: number,
	-- Retail packed world inverse-inertia vector `mIsplt = (Izz, Iyy, Iyz)`.
	inverse_inertia_split: Vector3,
	state: number,
	force_acceleration: Vector3,
	kinetic_energy: number,
	torque_acceleration: Vector3,
	cool_down: number,
	linear_velocity: Vector3,
	angular_velocity: Vector3,
}

-- Collision result and already-combined material values consumed by TU3's
-- contact generator.
export type RetailContactInput = {
	position_on_a: Vector3,
	position_on_b: Vector3,
	-- Positive normal impulse acts along this vector on A and opposite it on
	-- B. For wheel A over static ground B, this points upward.
	normal: Vector3,
	restitution: number,
	static_friction: number,
	dynamic_friction: number,
	tag: number,
}

-- Three scalar fields in the game-side physical material record consumed by
-- TU3 `0x82763078`.
export type RetailContactMaterial = {
	static_friction: number,
	dynamic_friction: number,
	restitution: number,
}

export type RetailContactWorkspace = {
	center_of_mass: Vector3,
	reaction_id: number,
	inverse_inertia_full: Vector3,
	inverse_mass: number,
	inverse_inertia_split: Vector3,
	state: number,
	force_acceleration: Vector3,
	kinetic_energy: number,
	torque_acceleration: Vector3,
	cool_down: number,
}

-- Scalar representation of the complete logical 256-byte retail contact.
-- `body_a_workspace` and `body_b_workspace` correspond to the ten alternating
-- 16-byte vectors at offsets `0x60..0xff`. `ContactBatchBuild` reads them from
-- the contact and does not dereference the live bodies.
export type RetailContact = {
	position_on_a: Vector3,
	body_a_id: number,
	position_on_b: Vector3,
	body_b_id: number,
	normal: Vector3,
	restitution: number,
	tangent_0: Vector3,
	static_friction: number,
	tangent_1: Vector3,
	dynamic_friction: number,
	-- Velocity at B's contact point minus velocity at A's contact point.
	relative_velocity: Vector3,
	tag: number,
	body_a_workspace: RetailContactWorkspace,
	body_b_workspace: RetailContactWorkspace,
}

-- Scalar lfs/stfs quiet a selected signalling NaN while preserving payload.
-- fn material_scalar_store(value: f32) -> f32
local function material_scalar_store(value: number): number
	if value ~= value then
		-- ROBLOX: `f32::from_bits(value.to_bits() | 0x0040_0000)` через bit32.
		return from_bits(bit32.bor(rt.to_bits(value), 0x0040_0000))
	end
	return value
end

-- Exact game-side material combine used immediately before the recovered
-- contact writers. Static and dynamic friction take the greater operand,
-- restitution the lesser; equality and unordered comparisons select B.
-- pub fn combine_contact_materials(material_a, material_b) -> RetailContactMaterial
function contact.combine_contact_materials(
	material_a: RetailContactMaterial,
	material_b: RetailContactMaterial
): RetailContactMaterial
	local static_friction = if material_a.static_friction > material_b.static_friction
		then material_a.static_friction
		else material_b.static_friction
	local dynamic_friction = if material_a.dynamic_friction > material_b.dynamic_friction
		then material_a.dynamic_friction
		else material_b.dynamic_friction
	local restitution = if material_a.restitution < material_b.restitution
		then material_a.restitution
		else material_b.restitution
	return {
		static_friction = material_scalar_store(static_friction),
		dynamic_friction = material_scalar_store(dynamic_friction),
		restitution = material_scalar_store(restitution),
	}
end

-- impl From<RetailContactBodyState> for RetailContactWorkspace
-- ROBLOX: `body.into()` -> явная функция.
function contact.workspace_from_body(body: RetailContactBodyState): RetailContactWorkspace
	return {
		center_of_mass = body.center_of_mass,
		reaction_id = body.reaction_id,
		inverse_inertia_full = body.inverse_inertia_full,
		inverse_mass = body.inverse_mass,
		inverse_inertia_split = body.inverse_inertia_split,
		state = body.state,
		force_acceleration = body.force_acceleration,
		kinetic_energy = body.kinetic_energy,
		torque_acceleration = body.torque_acceleration,
		cool_down = body.cool_down,
	}
end

-- ROBLOX: #[derive(PartialEq)] для RetailContactWorkspace.
function contact.workspace_eq(left: RetailContactWorkspace, right: RetailContactWorkspace): boolean
	for key, value in left :: any do
		if (right :: any)[key] ~= value then
			return false
		end
	end
	return true
end

local function sub(left: Vector3, right: Vector3): Vector3
	return vector.create(f32(left.x - right.x), f32(left.y - right.y), f32(left.z - right.z))
end

local function scale(v: Vector3, scalar: number): Vector3
	return vector.create(mul_add(v.x, scalar, 0.0), mul_add(v.y, scalar, 0.0), mul_add(v.z, scalar, 0.0))
end

local function cross(left: Vector3, right: Vector3): Vector3
	return vector.create(
		mul_add(left.y, right.z, mul_add(-left.z, right.y, 0.0)),
		mul_add(left.z, right.x, mul_add(-left.x, right.z, 0.0)),
		mul_add(left.x, right.y, mul_add(-left.y, right.x, 0.0))
	)
end
contact.cross = cross

local function dot(left: Vector3, right: Vector3): number
	return mul_add(left.z, right.z, mul_add(left.y, right.y, mul_add(left.x, right.x, 0.0)))
end
contact.dot = dot

local function length_squared(v: Vector3): number
	return dot(v, v)
end

local function point_velocity(linear: Vector3, omega: Vector3, arm: Vector3): Vector3
	-- Native folds the linear velocity into two fused cross-product terms.
	return vector.create(
		mul_add(arm.z, omega.y, mul_add(-arm.y, omega.z, linear.x)),
		mul_add(arm.x, omega.z, mul_add(-arm.z, omega.x, linear.y)),
		mul_add(arm.y, omega.x, mul_add(-arm.x, omega.y, linear.z))
	)
end

-- Exact normal-only fallback selected by the TU3 VMX block.
-- fn fallback_tangent(normal: Vector3) -> (Vector3, f32)
local function fallback_tangent(normal: Vector3): (Vector3, number)
	local candidate_x = vector.create(
		mul_add(-normal.x, normal.x, 1.0),
		mul_add(-normal.y, normal.x, 0.0),
		mul_add(-normal.z, normal.x, 0.0)
	)
	local candidate_z = vector.create(
		mul_add(-normal.x, normal.z, 0.0),
		mul_add(-normal.y, normal.z, 0.0),
		mul_add(-normal.z, normal.z, 1.0)
	)
	if mul_add(-normal.x, normal.x, contact.CONTACT_FALLBACK_HALF) >= -0.0 then
		return candidate_x, candidate_x.x
	end
	return vector.create(-candidate_z.x, -candidate_z.y, -candidate_z.z), candidate_z.z
end

-- Port of TU3 `0x8277A828..0x8277AA88` and its duplicate
-- `0x8277BFAC..0x8277C21C`. VMX128 operation order is retained:
-- 1. contact arms from the copied body center of mass;
-- 2. point rates as `linear + angular cross arm`;
-- 3. tangent 0 from `relative_velocity cross normal`;
-- 4. if that axis is subnormal, the exact X/Z projection fallback;
-- 5. tangent 1 as `normal cross tangent_0`;
-- 6. copy the ten body-state vectors used by `ContactBatchBuild`.
-- The input normal is already unit length and is not renormalized.
-- pub fn generate_contact(input, body_a, body_b) -> RetailContact
function contact.generate_contact(
	input: RetailContactInput,
	body_a: RetailContactBodyState,
	body_b: RetailContactBodyState
): RetailContact
	local arm_a = sub(input.position_on_a, body_a.center_of_mass)
	local arm_b = sub(input.position_on_b, body_b.center_of_mass)
	local point_velocity_a = point_velocity(body_a.linear_velocity, body_a.angular_velocity, arm_a)
	local point_velocity_b = point_velocity(body_b.linear_velocity, body_b.angular_velocity, arm_b)
	local relative_velocity = sub(point_velocity_b, point_velocity_a)

	local velocity_tangent = cross(relative_velocity, input.normal)
	local velocity_tangent_squared = length_squared(velocity_tangent)
	local unnormalized_tangent, tangent_squared
	if velocity_tangent_squared >= contact.CONTACT_TANGENT_MINIMUM_SQUARED then
		unnormalized_tangent, tangent_squared = velocity_tangent, velocity_tangent_squared
	else
		unnormalized_tangent, tangent_squared = fallback_tangent(input.normal)
	end

	-- TU3 issues one reciprocal-square-root estimate and applies it to both
	-- axes. `tangent_1` therefore assumes the collision normal is unit length.
	local inverse_length = reciprocal_sqrt.estimate(tangent_squared)
	local tangent_0 = scale(unnormalized_tangent, inverse_length)
	-- The second cross product rounds the positive product first, then uses
	-- vnmsubfp for the negative term; tangent_0 uses the opposite order.
	local n = input.normal
	local t = unnormalized_tangent
	local tangent_1 = scale(
		vector.create(
			mul_add(-t.y, n.z, mul_add(t.z, n.y, 0.0)),
			mul_add(-t.z, n.x, mul_add(t.x, n.z, 0.0)),
			mul_add(-t.x, n.y, mul_add(t.y, n.x, 0.0))
		),
		inverse_length
	)

	return {
		position_on_a = input.position_on_a,
		body_a_id = body_a.contact_body_id,
		position_on_b = input.position_on_b,
		body_b_id = body_b.contact_body_id,
		normal = input.normal,
		restitution = input.restitution,
		tangent_0 = tangent_0,
		static_friction = input.static_friction,
		tangent_1 = tangent_1,
		dynamic_friction = input.dynamic_friction,
		relative_velocity = relative_velocity,
		tag = input.tag,
		body_a_workspace = contact.workspace_from_body(body_a),
		body_b_workspace = contact.workspace_from_body(body_b),
	}
end

return contact
