--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/skeleton_body/record.rs (коммит 2e16697)
--
-- SkeletonState's physical record: TU3 82BEBD28 and 82BEC1E8.

local rt = require("../../../rt")
local sar = require("../skeleton_animation_record")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local IDENTITY = sar.IDENTITY
local copy_transform = sar.copy_transform

type F4 = { number }
type AnimationPartTransform = sar.AnimationPartTransform

-- ROBLOX: PART_COUNT/ANIMATION_PART_COUNT из mod.rs (init.luau) продублированы,
-- чтобы не было циклического require.
local PART_COUNT = 26

local record = {}

export type SkeletonPhysicalRecord = {
	-- SkeletonState1552: actual part frames, including the mass-frame inverse.
	pose: { AnimationPartTransform },
	-- SkeletonState3216: previous positions used by the fixed-step derivative.
	positions: { F4 },
	-- SkeletonState3632: pose-derived velocities, not rigid body rates.
	velocities: { F4 },
	-- SkeletonState4048: difference from the preceding derived velocity.
	velocity_changes: { F4 },
	-- SkeletonState4464/4480; only the first 24 weighted parts contribute.
	centre_of_mass: F4,
	centre_of_mass_velocity: F4,
	timestep: number,
}

local SkeletonPhysicalRecord = {}
record.SkeletonPhysicalRecord = SkeletonPhysicalRecord

local function zeros(): { F4 }
	local t = table.create(PART_COUNT) :: any
	for i = 1, PART_COUNT do
		t[i] = { 0.0, 0.0, 0.0, 0.0 }
	end
	return t
end

-- ROBLOX: impl Default.
function SkeletonPhysicalRecord.default(): SkeletonPhysicalRecord
	-- Constructor82BEB8C8 initializes all26 physical transforms and history.
	local pose = table.create(PART_COUNT) :: any
	for i = 1, PART_COUNT do
		pose[i] = IDENTITY()
	end
	return {
		pose = pose,
		positions = zeros(),
		velocities = zeros(),
		velocity_changes = zeros(),
		centre_of_mass = { 0.0, 0.0, 0.0, 0.0 },
		centre_of_mass_velocity = { 0.0, 0.0, 0.0, 0.0 },
		timestep = 0.0,
	}
end

-- /// Physical subset of Reset82BEBBB0. The native reset preserves physical
-- /// COM, velocity changes and timestep; other animation/error owners reset
-- /// their own fields at this same phase.
function SkeletonPhysicalRecord.reset(self: SkeletonPhysicalRecord, parts: { AnimationPartTransform })
	for i, part in parts do
		self.pose[i] = copy_transform(part)
		self.positions[i] = table.clone(part[4])
		self.velocities[i] = { 0.0, 0.0, 0.0, 0.0 }
	end
end

-- /// The caller supplies the actual GetPartTransform results. Native part0
-- /// uses the explicit board-frame argument; all other parts come from the
-- /// skeleton assembly. Keep this distinction when the board drives a proxy.
function SkeletonPhysicalRecord.update(self: SkeletonPhysicalRecord, parts: { AnimationPartTransform }, board_frame: AnimationPartTransform, fractional: { number })
	self.timestep = from_bits(0x3C88_8889)
	local frequency = from_bits(0x426F_FFFF)
	for i, part in parts do
		local transform = if i == 1 then board_frame else part
		self.pose[i] = copy_transform(transform)
		for lane = 1, 4 do
			local velocity = f32(f32(transform[4][lane] - self.positions[i][lane]) * frequency)
			self.velocity_changes[i][lane] = f32(velocity - self.velocities[i][lane])
			self.velocities[i][lane] = velocity
		end
		self.positions[i] = table.clone(transform[4])
	end
	local position = { 0.0, 0.0, 0.0, 0.0 }
	local velocity = { 0.0, 0.0, 0.0, 0.0 }
	for i, weight in fractional do
		for lane = 1, 4 do
			position[lane] = mul_add(self.pose[i][4][lane], weight, position[lane])
			velocity[lane] = mul_add(self.velocities[i][lane], weight, velocity[lane])
		end
	end
	self.centre_of_mass = position
	self.centre_of_mass_velocity = velocity
end

return record
