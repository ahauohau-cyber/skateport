--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/skeleton_body/runtime.rs (коммит 2e16697)
--
-- Actual 26-part ownership and Reset82BD9990 / physical-record publication.

local rt = require("../../../rt")
local assembly = require("../assembly")
local part_mod = require("../board_pose/part")
local normalization = require("../board_pose/normalization")
local board_runtime = require("../board_runtime")
local rigid_body = require("../rigid_body")
local native_arithmetic = require("../native_arithmetic")
local sar = require("../skeleton_animation_record")
local skeleton_root = require("../skeleton_root")
local record_mod = require("./record")
local construction = require("./construction")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local to_bits = rt.to_bits
local IDENTITY = sar.IDENTITY
local compose_affine = sar.compose_affine
local inverse_rigid = skeleton_root.inverse_rigid
local SkeletonPhysicalRecord = record_mod.SkeletonPhysicalRecord

type AnimationPartTransform = sar.AnimationPartTransform
type BodySnapshot = assembly.BodySnapshot

-- ROBLOX: константы из mod.rs продублированы, чтобы не было циклического require.
local PART_COUNT = 26
local ANIMATION_PART_COUNT = 24

local runtime = {}

-- ROBLOX: поле bodies в Rust приватное; доступ через bodies()/bodies_mut().
export type SkeletonBody = {
	definition: construction.SkeletonBodyDefinition,
	record: record_mod.SkeletonPhysicalRecord,
	animation_to_world: AnimationPartTransform,
	bodies: { BodySnapshot },
}

local SkeletonBody = {}
runtime.SkeletonBody = SkeletonBody

-- ROBLOX: PoseMatrix ([u32; 16]) -> таблица из 16 слов, индексы с 1.
local function words(frame: AnimationPartTransform): { number }
	local w = table.create(16) :: any
	for i = 0, 15 do
		w[i + 1] = to_bits(frame[i // 4 + 1][i % 4 + 1])
	end
	return w
end

local function floats(frame: { number }): AnimationPartTransform
	local m = {}
	for i = 0, 3 do
		m[i + 1] = { from_bits(frame[i * 4 + 1]), from_bits(frame[i * 4 + 2]), from_bits(frame[i * 4 + 3]), from_bits(frame[i * 4 + 4]) }
	end
	return m
end

local function mass_words(frame: rigid_body.RetailLocalMassFrame): { number }
	local m = IDENTITY()
	for column, axis in frame.basis.columns do
		m[column][1] = axis[1]
		m[column][2] = axis[2]
		m[column][3] = axis[3]
	end
	local t = frame.translation
	m[4] = { t.x, t.y, t.z, 0.0 }
	return words(m)
end

local function inertia_words(d: rigid_body.RetailInertiaDynamics): { number }
	local values = {
		d.inverse_tensor.x, d.inverse_tensor.y, d.inverse_tensor.z, 0.0, d.inverse_mass,
		d.spherical, d.maximum_linear_velocity, d.maximum_angular_velocity,
		d.linear_drag, d.angular_drag,
	}
	for i, v in values do
		values[i] = to_bits(v)
	end
	return values
end

local function body_words(rates: rigid_body.RetailBodyRates): { number }
	local w = table.create(44, 0) :: any
	local q = rates.orientation
	w[1], w[2], w[3], w[4] = to_bits(q.x), to_bits(q.y), to_bits(q.z), to_bits(q.w)
	w[5], w[6], w[7] = to_bits(rates.position.x), to_bits(rates.position.y), to_bits(rates.position.z)
	for i, axis in rates.basis.columns do
		local base = 16 + (i - 1) * 4
		w[base + 1], w[base + 2], w[base + 3] = to_bits(axis[1]), to_bits(axis[2]), to_bits(axis[3])
	end
	return w
end

-- /// `authored` is SkeletonData's initialization pose after forward physical
-- /// bone-frame mapping. The actor's native initialization pose producer must
-- /// supply it; the current graph's first frame is a separate publication.
function SkeletonBody.new(definition: construction.SkeletonBodyDefinition, authored_in: { AnimationPartTransform }, spawn: AnimationPartTransform, simulation: rigid_body.RetailSimulationStep): SkeletonBody
	-- GetPartFrame82BD9878 normalizes the mapped animation frame before
	-- Reset composes the world alignment. PartSetTransform normalizes
	-- again after applying the local mass frame; the two stages differ.
	local authored = {}
	for i, frame in authored_in do
		authored[i] = floats(normalization.orthonormalize_part_basis(words(frame)))
	end
	local animation_to_world = compose_affine(spawn, inverse_rigid(authored[1]))
	local bodies = table.create(PART_COUNT) :: any
	for i = 0, PART_COUNT - 1 do
		local desired = if i < ANIMATION_PART_COUNT then compose_affine(animation_to_world, authored[i + 1]) else spawn
		local m = definition.parts[i + 1].animated
		local inertia = table.clone(m.dynamics)
		-- SetUpNormal82BE7280 loads the independently cached inverse mass
		-- for the 23 skater bones. Root/extra bodies retain their setup.
		if i >= 1 and i < ANIMATION_PART_COUNT then
			inertia.inverse_mass = definition.parts[i + 1].inverse_mass_animated
		end
		local part: part_mod.PartPose = {
			transform = words(desired),
			local_mass_frame = mass_words(m.local_mass_frame),
			body = table.create(44, 0),
			inertia = inertia_words(inertia),
		}
		part_mod.set_part_transform(part, words(desired))
		bodies[i + 1] = board_runtime.initialized_body(part, inertia, simulation, board_runtime.BoardMotion.Active)
	end
	local result: SkeletonBody = {
		definition = definition,
		bodies = bodies,
		animation_to_world = animation_to_world,
		record = SkeletonPhysicalRecord.default(),
	}
	-- SkeletonInit82BD8010..804C makes two real physical observations.
	-- The second eliminates the constructor's zero-position derivative.
	local pose = SkeletonBody.part_transforms(result)
	SkeletonPhysicalRecord.update(result.record, pose, pose[1], result.definition.animation_masses.fractional)
	SkeletonPhysicalRecord.update(result.record, pose, pose[1], result.definition.animation_masses.fractional)
	return result
end

function SkeletonBody.bodies(self: SkeletonBody): { BodySnapshot }
	return self.bodies
end

-- /// The shared solver owns these same states; do not maintain a second
-- /// kinematic pose array beside the states receiving its corrections.
function SkeletonBody.bodies_mut(self: SkeletonBody): { BodySnapshot }
	return self.bodies
end

-- /// Skeleton::SetPartTransform82BE2A38 updates the live part through
-- ///82BD4318 and then retains the ORIGINAL requested physical-record frame.
-- ///Only pose and its inertia cache change; solved velocities survive.
function SkeletonBody.set_part_transform(self: SkeletonBody, part: number, frame: AnimationPartTransform)
	local body = self.bodies[part + 1]
	local pose: part_mod.PartPose = {
		transform = words(frame),
		local_mass_frame = mass_words(self.definition.parts[part + 1].animated.local_mass_frame),
		body = body_words(body.rates),
		inertia = inertia_words(body.inertia),
	}
	part_mod.set_part_transform(pose, words(frame))
	local packed = pose.body :: { number }
	local function f(i: number): number
		return from_bits(packed[i + 1])
	end
	body.rates.orientation = { x = f(0), y = f(1), z = f(2), w = f(3) }
	body.rates.position = vector.create(f(4), f(5), f(6))
	body.rates.basis = { columns = { { f(16), f(17), f(18) }, { f(20), f(21), f(22) }, { f(24), f(25), f(26) } } }
	body.rates.world_inverse_inertia = { columns = { { f(28), f(29), f(30) }, { f(29), f(33), f(34) }, { f(30), f(34), f(32) } } }
	self.record.pose[part + 1] = sar.copy_transform(frame)
end

function SkeletonBody.part_transforms(self: SkeletonBody): { AnimationPartTransform }
	local out = table.create(PART_COUNT) :: any
	for i = 1, PART_COUNT do
		local part: part_mod.PartPose = {
			transform = words(IDENTITY()),
			local_mass_frame = mass_words(self.definition.parts[i].animated.local_mass_frame),
			body = body_words(self.bodies[i].rates),
			inertia = nil,
		}
		out[i] = floats(part_mod.part_transform(part))
	end
	return out
end

function SkeletonBody.publish_physical_record(self: SkeletonBody, board: AnimationPartTransform)
	local pose = SkeletonBody.part_transforms(self)
	SkeletonPhysicalRecord.update(self.record, pose, board, self.definition.animation_masses.fractional)
end

-- /// ApplyDisplacementToPart82BE7788. Despite its name this writes the
-- /// rigid body's force accumulator and clears cooldown; it is not a pose
-- /// adjustment. GeneralUpdate calls it for all24 animation parts.
function SkeletonBody.apply_part_displacement(self: SkeletonBody, part: number, displacement: { number })
	local step = from_bits(0x3C88_8889)
	local inverse_step = native_arithmetic.reciprocal_estimate(step)
	for _ = 1, 2 do
		inverse_step = mul_add(inverse_step, mul_add(-inverse_step, step, 1.0), inverse_step)
	end
	local body = self.bodies[part + 1]
	local inverse_mass = body.inertia.inverse_mass
	local value = {}
	for i = 1, 4 do
		value[i] = f32(f32(displacement[i] * inverse_step) * inverse_mass)
	end
	local fa = body.rates.force_acceleration
	body.rates.force_acceleration = vector.create(f32(fa.x + value[1]), f32(fa.y + value[2]), f32(fa.z + value[3]))
	body.rates.cool_down = 0
end

return runtime
