--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/rigid_body.rs (коммит 2e16697)
--
-- TU3 RenderWare rigid-body accumulation and integration primitives.
--
-- These routines are ports of the arithmetic in the Skate 3 TU3 executable,
-- not a wrapper around a generic rigid-body engine. The caller supplies
-- solver corrections; this module does not own collision or solver scheduling.
-- ROBLOX: RetailForceAccumulator и accumulate_point_force лежат в point_force.luau,
-- DynamicUpdateResult и dynamic_update_packed — в @self/dynamic_update.

local rt = require("../../rt")
local math_mod = require("../math")
local dynamic_update = require("@self/dynamic_update")

local f32 = rt.f32
local from_bits = rt.from_bits
local to_bits = rt.to_bits

type Vector3 = vector
type Basis3 = math_mod.Basis3

local rigid_body = {}

-- pub mod tu3
rigid_body.tu3 = {
	-- Per-active-body integration routine called by
	-- `rw::physics::Simulation::BatchIntegrator`.
	BATCH_INTEGRATOR_BODY = 0x82AE_6590,
	-- `Sk8::Physics::Skateboard::ApplyQueuedSkateboardForces`.
	APPLY_QUEUED_SKATEBOARD_FORCES = 0x82C0_3718,
}

-- Exact scalar fields read from TU3's `rw::physics::Simulation` by `0x82AE6590`.
export type RetailSimulationStep = {
	time_step: number,
	frequency: number,
	cool_down: number,
	minimum_energy: number,
	gravity_acceleration: Vector3,
}

local RetailSimulationStep = {}
rigid_body.RetailSimulationStep = RetailSimulationStep

-- pub fn fixed_60_hz(cool_down, minimum_energy, gravity_acceleration) -> Self
function RetailSimulationStep.fixed_60_hz(cool_down: number, minimum_energy: number, gravity_acceleration: Vector3): RetailSimulationStep
	local time_step = from_bits(0x3C88_8889)
	return {
		time_step = time_step,
		-- ROBLOX: f32::recip -> f32(1 / x).
		frequency = f32(1 / time_step),
		cool_down = cool_down,
		minimum_energy = minimum_energy,
		gravity_acceleration = gravity_acceleration,
	}
end

-- Exact scalar layout of `rw::physics::Inertia` after its inverse-tensor vector.
export type RetailInertiaDynamics = {
	inverse_tensor: Vector3,
	inverse_mass: number,
	spherical: number,
	maximum_linear_velocity: number,
	maximum_angular_velocity: number,
	linear_drag: number,
	angular_drag: number,
}

-- Inverse local principal-axis frame stored by TU3 `ComputeMassProperties`
-- (`0x82AE7770`) at `PartDefinition + 64` (`inverseBodyLTM`).
-- The stock wheel and truck retain identity. Deck construction `0x82C09290`
-- also explicitly resets this frame to identity after computing aggregate
-- principal inertia; that override does not discard the calculated inertia.
export type RetailLocalMassFrame = {
	-- Column vectors in RenderWare `Ri`, `Up`, `At` order.
	basis: Basis3,
	translation: Vector3,
}

local RetailLocalMassFrame = {}
rigid_body.RetailLocalMassFrame = RetailLocalMassFrame

-- pub const IDENTITY: Self
-- ROBLOX: константа-таблица; функцией, чтобы каждый получал свою копию.
function RetailLocalMassFrame.IDENTITY(): RetailLocalMassFrame
	return {
		basis = { columns = { { 1.0, 0.0, 0.0 }, { 0.0, 1.0, 0.0 }, { 0.0, 0.0, 1.0 } } },
		translation = vector.create(0, 0, 0),
	}
end

-- Complete per-part mass data needed by the TU3 rigid-body integrator.
export type RetailBodyMassProperties = {
	local_mass_frame: RetailLocalMassFrame,
	dynamics: RetailInertiaDynamics,
}

-- The four 16-byte correction vectors indexed by `RigidBody::mId`.
-- The first and third vectors participate in the velocity-producing frame
-- displacement. The second and fourth correct position and orientation only.
export type RetailReactionCorrections = {
	linear_displacement: Vector3,
	position_displacement: Vector3,
	angular_displacement: Vector3,
	orientation_displacement: Vector3,
}

local RetailReactionCorrections = {}
rigid_body.RetailReactionCorrections = RetailReactionCorrections

-- #[derive(Default)]
function RetailReactionCorrections.default(): RetailReactionCorrections
	local zero = vector.create(0, 0, 0)
	return {
		linear_displacement = zero,
		position_displacement = zero,
		angular_displacement = zero,
		orientation_displacement = zero,
	}
end

-- RenderWare quaternion lane order is `(x, y, z, w)`.
export type RetailQuaternion = { x: number, y: number, z: number, w: number }

local RetailQuaternion = {}
rigid_body.RetailQuaternion = RetailQuaternion

-- pub const IDENTITY: Self
function RetailQuaternion.IDENTITY(): RetailQuaternion
	return { x = 0.0, y = 0.0, z = 0.0, w = 1.0 }
end

export type RetailBodyRates = {
	orientation: RetailQuaternion,
	basis: Basis3,
	world_inverse_inertia: Basis3,
	position: Vector3,
	linear_velocity: Vector3,
	angular_velocity: Vector3,
	-- Acceleration accumulator. `RigidBody::AddForce` has already multiplied
	-- physical force by inverse mass before this field reaches the integrator.
	force_acceleration: Vector3,
	-- Angular-acceleration accumulator. Point-force torque has already passed
	-- through the body's world inverse inertia.
	torque_acceleration: Vector3,
	kinetic_energy: number,
	cool_down: number,
}

export type RetailBodyRateStep = {
	state: RetailBodyRates,
	-- Rotation increment consumed by the quaternion branch in the same retail
	-- function. Keeping this explicit prevents a presentation system from
	-- replacing it with a surface-normal snap.
	orientation_displacement: Vector3,
	linear_speed_squared: number,
	angular_speed_squared: number,
}

-- Skate-era RenderWare's six-value packed symmetric world inverse-inertia
-- tensor: `mIfull = (Ixx, Ixy, Ixz)`; `mIsplt = (Izz, Iyy, Iyz)`.
export type RetailPackedWorldInverseInertia = {
	full: Vector3,
	split: Vector3,
}

local function unpack_world_inverse_inertia(full: Vector3, split: Vector3): Basis3
	return {
		columns = {
			{ full.x, full.y, full.z },
			{ full.y, split.y, split.z },
			{ full.z, split.z, split.x },
		},
	}
end

-- Typed adapter to the complete TU3 `RigidBody::DynamicUpdate` (`0x82AE6590`).
-- The order matters:
-- 1. acceleration is integrated to a candidate velocity;
-- 2. candidate velocity is converted to a frame displacement;
-- 3. solver correction displacements are added;
-- 4. position is advanced;
-- 5. velocity is reconstructed from displacement with retail drag;
-- 6. linear and angular speed caps are applied;
-- 7. energy/cool-down is updated;
-- 8. force/torque accumulators are reset for the next step.
-- ROBLOX: `mut body` по значению -> возвращается новая таблица state,
-- аргумент не меняется.
-- pub fn integrate_body_rates(body, inertia, simulation, reactions) -> RetailBodyRateStep
function rigid_body.integrate_body_rates(
	body_in: RetailBodyRates,
	inertia: RetailInertiaDynamics,
	simulation: RetailSimulationStep,
	reactions: RetailReactionCorrections
): RetailBodyRateStep
	local words = rt.zeros(44)
	words[1] = to_bits(body_in.orientation.x)
	words[2] = to_bits(body_in.orientation.y)
	words[3] = to_bits(body_in.orientation.z)
	words[4] = to_bits(body_in.orientation.w)
	for _, item in
		{
			{ 4, body_in.position },
			{ 8, body_in.linear_velocity },
			{ 12, body_in.angular_velocity },
			{ 36, body_in.force_acceleration },
			{ 40, body_in.torque_acceleration },
		} :: { { any } }
	do
		local offset: number, value: Vector3 = item[1], item[2]
		words[offset + 1] = to_bits(value.x)
		words[offset + 2] = to_bits(value.y)
		words[offset + 3] = to_bits(value.z)
	end
	words[32] = to_bits(inertia.inverse_mass)
	words[40] = to_bits(body_in.kinetic_energy)
	words[44] = body_in.cool_down
	local native_inertia = {
		to_bits(inertia.inverse_tensor.x),
		to_bits(inertia.inverse_tensor.y),
		to_bits(inertia.inverse_tensor.z),
		to_bits(0.0),
		to_bits(inertia.inverse_mass),
		to_bits(inertia.spherical),
		to_bits(inertia.maximum_linear_velocity),
		to_bits(inertia.maximum_angular_velocity),
		to_bits(inertia.linear_drag),
		to_bits(inertia.angular_drag),
	}
	local correction_words = rt.zeros(16)
	for index, value in
		{
			reactions.linear_displacement,
			reactions.position_displacement,
			reactions.angular_displacement,
			reactions.orientation_displacement,
		}
	do
		local base = (index - 1) * 4
		correction_words[base + 1] = to_bits(value.x)
		correction_words[base + 2] = to_bits(value.y)
		correction_words[base + 3] = to_bits(value.z)
	end
	local result = dynamic_update.dynamic_update_packed(words, native_inertia, simulation, correction_words)
	local function vec(offset: number): Vector3
		return vector.create(from_bits(words[offset + 1]), from_bits(words[offset + 2]), from_bits(words[offset + 3]))
	end
	local columns = {}
	for i = 0, 2 do
		columns[i + 1] = {
			from_bits(words[16 + i * 4 + 1]),
			from_bits(words[16 + i * 4 + 2]),
			from_bits(words[16 + i * 4 + 3]),
		}
	end
	local body: RetailBodyRates = {
		orientation = {
			x = from_bits(words[1]),
			y = from_bits(words[2]),
			z = from_bits(words[3]),
			w = from_bits(words[4]),
		},
		basis = { columns = columns },
		world_inverse_inertia = unpack_world_inverse_inertia(vec(28), vec(32)),
		position = vec(4),
		linear_velocity = vec(8),
		angular_velocity = vec(12),
		force_acceleration = vec(36),
		torque_acceleration = vec(40),
		kinetic_energy = from_bits(words[40]),
		cool_down = words[44],
	}
	local d = result.orientation_displacement
	return {
		state = body,
		orientation_displacement = vector.create(d[1], d[2], d[3]),
		linear_speed_squared = result.linear_speed_squared,
		angular_speed_squared = result.angular_speed_squared,
	}
end

-- Quaternion branch from TU3 `0x82AE6668..0x82AE66C8`, paired with
-- Skate 2 `0x82AE455C..0x82AE45C8`:
-- `q += 0.5 * Quaternion(angular_displacement, 0) * q` followed by
-- normalization. This pre-multiplication order is important.
-- pub fn integrate_orientation(orientation, angular_displacement) -> RetailQuaternion
function rigid_body.integrate_orientation(orientation: RetailQuaternion, angular_displacement: Vector3): RetailQuaternion
	local q = dynamic_update.orientation(
		{ orientation.x, orientation.y, orientation.z, orientation.w },
		{ angular_displacement.x, angular_displacement.y, angular_displacement.z, 0.0 }
	)
	return { x = q[1], y = q[2], z = q[3], w = q[4] }
end

-- `Ri`, `Up`, and `At` columns rebuilt immediately after TU3 normalizes the
-- quaternion in `0x82AE6590`.
-- pub fn basis_from_quaternion(q: RetailQuaternion) -> Basis3
function rigid_body.basis_from_quaternion(q: RetailQuaternion): Basis3
	local columns = dynamic_update.quaternion_basis({ q.x, q.y, q.z, q.w })
	return {
		columns = {
			{ columns[1][1], columns[1][2], columns[1][3] },
			{ columns[2][1], columns[2][2], columns[2][3] },
			{ columns[3][1], columns[3][2], columns[3][3] },
		},
	}
end

-- Native packed inverse-inertia rebuild in 82AE6590, with its fused order.
-- pub fn world_inverse_inertia(basis: Basis3, inverse_tensor: Vector3) -> Basis3
function rigid_body.world_inverse_inertia(basis: Basis3, inverse_tensor: Vector3): Basis3
	local c = basis.columns
	local native_basis = {
		{ c[1][1], c[1][2], c[1][3], 0.0 },
		{ c[2][1], c[2][2], c[2][3], 0.0 },
		{ c[3][1], c[3][2], c[3][3], 0.0 },
	}
	local tensor = { to_bits(inverse_tensor.x), to_bits(inverse_tensor.y), to_bits(inverse_tensor.z) }
	local full, split = dynamic_update.inverse_inertia(native_basis, tensor)
	return unpack_world_inverse_inertia(
		vector.create(full[1], full[2], full[3]),
		vector.create(split[1], split[2], split[3])
	)
end

-- Packs a symmetric world inverse-inertia tensor in RenderWare's `mIfull` /
-- `mIsplt` lane order.
-- pub fn pack_world_inverse_inertia(tensor: Basis3) -> RetailPackedWorldInverseInertia
function rigid_body.pack_world_inverse_inertia(tensor: Basis3): RetailPackedWorldInverseInertia
	local c = tensor.columns
	return {
		full = vector.create(c[1][1], c[2][1], c[3][1]),
		split = vector.create(c[3][3], c[2][2], c[3][2]),
	}
end

-- Multiplies a vector by the exact symmetric tensor represented by retail
-- `mIfull` and `mIsplt`.
-- pub fn multiply_packed_world_inverse_inertia(tensor, vector) -> Vector3
function rigid_body.multiply_packed_world_inverse_inertia(tensor: RetailPackedWorldInverseInertia, v: Vector3): Vector3
	local full, split = tensor.full, tensor.split
	return vector.create(
		f32(f32(f32(full.x * v.x) + f32(full.y * v.y)) + f32(full.z * v.z)),
		f32(f32(f32(full.y * v.x) + f32(split.y * v.y)) + f32(split.z * v.z)),
		f32(f32(f32(full.z * v.x) + f32(split.z * v.y)) + f32(split.x * v.z))
	)
end

return rigid_body
