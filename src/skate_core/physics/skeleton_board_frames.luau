--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/skeleton_board_frames.rs (коммит 2e16697)
--
-- Ground skeleton frame publication82BDF530 and COM lift82BDE310.
-- The authored board11728, world target15952 and physical board12496 have
-- different producers. Keep them separate through the animation/physics tick.

local rt = require("../../rt")
local native_arithmetic = require("./native_arithmetic")
local sar = require("./skeleton_animation_record")
local skeleton_root = require("./skeleton_root")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local IDENTITY = sar.IDENTITY
local compose_affine = sar.compose_affine
local transform_point = sar.transform_point
local copy_transform = sar.copy_transform
local orthonormalize = skeleton_root.orthonormalize

type Transform = sar.AnimationPartTransform
type F4 = { number }

local skeleton_board_frames = {}

export type SkeletonBoardFrames = {
	physical_board: Transform,
	skate_root: Transform,
	animation_target: Transform,
	com_frame: Transform,
	lifted_com_frame: Transform,
	centre_of_mass: F4,
	previous_centre_of_mass: F4,
	com_velocity: F4,
	local_centre_of_mass: F4,
	local_board_position: F4,
	--Skeleton16412, a per-update height limiter, not a timestep spring.
	lift_height: number,
}

local SkeletonBoardFrames = {}
skeleton_board_frames.SkeletonBoardFrames = SkeletonBoardFrames

-- ROBLOX: impl Default.
function SkeletonBoardFrames.default(): SkeletonBoardFrames
	return {
		physical_board = IDENTITY(),
		skate_root = IDENTITY(),
		animation_target = IDENTITY(),
		com_frame = IDENTITY(),
		lifted_com_frame = IDENTITY(),
		centre_of_mass = { 0.0, 0.0, 0.0, 0.0 },
		previous_centre_of_mass = { 0.0, 0.0, 0.0, 0.0 },
		com_velocity = { 0.0, 0.0, 0.0, 0.0 },
		local_centre_of_mass = { 0.0, 0.0, 0.0, 0.0 },
		local_board_position = { 0.0, 0.0, 0.0, 0.0 },
		lift_height = 0.0,
	}
end

-- ///Reset82BD9990: the retained COM seed is the supplied spawn position;
-- ///the two COM drive frames initially share spawn plus one world-Y unit.
-- ///The following physical observations replace the seed with weighted COM.
function SkeletonBoardFrames.reset(self: SkeletonBoardFrames, spawn: Transform)
	self.com_frame = copy_transform(spawn)
	self.com_frame[4][2] = f32(self.com_frame[4][2] + 1.0)
	self.lifted_com_frame = copy_transform(self.com_frame)
	self.centre_of_mass = table.clone(spawn[4])
	self.local_centre_of_mass = { 0.0, 0.0, 0.0, 0.0 }
end

-- ///82BD9EA8, after the physical record observation: inverse-transform
-- ///the retained physical COM and actual board position independently.
function SkeletonBoardFrames.publish_local_observations(self: SkeletonBoardFrames, roots: skeleton_root.SkeletonRootFrames, physical_board: Transform)
	self.local_centre_of_mass = transform_point(roots.world_to_animation, self.centre_of_mass)
	self.local_board_position = transform_point(roots.world_to_animation, physical_board[4])
end

-- ///82BD9FB0..82BDA060 after animation/physics errors are updated. This is
-- ///physical weighted COM4464, not physical hips23 or authored hips height.
function SkeletonBoardFrames.publish_centre_of_mass(self: SkeletonBoardFrames, com: F4, dt: number, flags_2472: number)
	self.previous_centre_of_mass = self.centre_of_mass
	self.centre_of_mass = table.clone(com)
	local inverse = native_arithmetic.reciprocal_estimate(dt)
	for _ = 1, 2 do
		inverse = mul_add(inverse, mul_add(-inverse, dt, 1.0), inverse)
	end
	local v = {}
	for i = 1, 4 do
		v[i] = f32(f32(com[i] - self.previous_centre_of_mass[i]) * inverse)
	end
	self.com_velocity = v
	if bit32.band(flags_2472, 0x400) ~= 0 then
		--Native updates previous COM after calculating velocity.
		self.previous_centre_of_mass = table.clone(com)
	end
end

-- ///82BDE310. Preserve both fsel comparisons and the later vector FMA.
function SkeletonBoardFrames.update_com_lift(self: SkeletonBoardFrames, animation_to_world: Transform, position: F4, requested_height: number)
	local step = from_bits(0x3D23_D70A) --82216FEC .04
	local low = f32(self.lift_height - step)
	local high = f32(self.lift_height + step)
	local above_low = if f32(low - requested_height) >= 0.0 then low else requested_height
	self.lift_height = if f32(high - above_low) >= 0.0 then above_low else high
	local frame = copy_transform(animation_to_world)
	frame[4] = table.clone(position)
	self.com_frame = orthonormalize(frame)
	self.lifted_com_frame = copy_transform(self.com_frame)
	local height = f32(self.lift_height + from_bits(0x3E99_999A)) --820D06C0 .3
	local lifted = {}
	for i = 1, 4 do
		lifted[i] = mul_add(self.com_frame[2][i], height, self.com_frame[4][i])
	end
	self.lifted_com_frame[4] = lifted
end

-- ///82BDF55C..F774, following UpdateRootTransforms and preceding GeneralUpdate.
-- ///Returns the complete frame published to ProcessedPhysIn0..48.
-- ROBLOX: flags_2468: &mut u32 -> ячейка { value }.
function SkeletonBoardFrames.prepare_ground(self: SkeletonBoardFrames, roots: skeleton_root.SkeletonRootFrames, mapped_board: Transform, actual_board: Transform, flags_2468: { value: number }): Transform
	local local_target = compose_affine(roots.animation_to_board, mapped_board)
	local world_position = IDENTITY()
	world_position[4] = table.clone(roots.predicted_board_position)
	self.animation_target = compose_affine(world_position, local_target)
	flags_2468.value = bit32.band(flags_2468.value, bit32.bnot(0x80000))
	self.physical_board = copy_transform(actual_board)
	self.skate_root = copy_transform(actual_board)
	SkeletonBoardFrames.update_com_lift(self, roots.animation_to_world, self.centre_of_mass, 0.0)
	return copy_transform(self.animation_target)
end

-- ///82BDF7C0. Teleport shares the authored target composition, but its COM
-- ///drive frame starts one world-Y unit above the physical deck position.
function SkeletonBoardFrames.prepare_teleport(self: SkeletonBoardFrames, roots: skeleton_root.SkeletonRootFrames, mapped_board: Transform, actual_board: Transform, flags_2468: { value: number }): Transform
	local local_target = compose_affine(roots.animation_to_board, mapped_board)
	local world_position = IDENTITY()
	world_position[4] = table.clone(roots.predicted_board_position)
	self.animation_target = compose_affine(world_position, local_target)
	flags_2468.value = bit32.band(flags_2468.value, bit32.bnot(0x80000))
	self.physical_board = copy_transform(actual_board)
	self.skate_root = copy_transform(actual_board)
	local position = table.clone(actual_board[4])
	position[2] = f32(position[2] + 1.0) --82BDFA20..30 replaces Y only.
	SkeletonBoardFrames.update_com_lift(self, roots.animation_to_world, position, 0.0)
	return copy_transform(self.animation_target)
end

return skeleton_board_frames
