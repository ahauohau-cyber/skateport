--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/skeleton_motion.rs (коммит 2e16697)
--
-- Trajectory and board-orientation publications inside ProcessData82BD8918.

local rt = require("../../rt")
local native_arithmetic = require("./native_arithmetic")
local sar = require("./skeleton_animation_record")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local IDENTITY = sar.IDENTITY
local compose_affine = sar.compose_affine
local copy_transform = sar.copy_transform

type AnimationPartTransform = sar.AnimationPartTransform

local skeleton_motion = {}

-- ROBLOX: previous_board_at_y в Rust приватное поле.
export type SkeletonMotion = {
	--Skeleton12048,12112,12176. Later skeleton modes may set the next frame.
	trajectory: AnimationPartTransform,
	inverse_trajectory: AnimationPartTransform,
	next_trajectory: AnimationPartTransform,
	--Skeleton16320: current trajectory translation/dt, transformed to world.
	velocity_world: { number },
	--Skeleton16500, initialized zero by82BD7A6C.
	previous_board_at_y: number,
}

local SkeletonMotion = {}
skeleton_motion.SkeletonMotion = SkeletonMotion

-- ROBLOX: impl Default.
function SkeletonMotion.default(): SkeletonMotion
	--82BD7260 seeds the three frames from82139A10/20/30 and zero pos.
	return {
		trajectory = IDENTITY(),
		inverse_trajectory = IDENTITY(),
		next_trajectory = IDENTITY(),
		velocity_world = { 0.0, 0.0, 0.0, 0.0 },
		previous_board_at_y = 0.0,
	}
end

-- ///82BE3538 resets only the board-orientation history, not trajectory.
function SkeletonMotion.reset_board_orientation_history(self: SkeletonMotion)
	self.previous_board_at_y = 0.0
end

-- ///82BD89D0..8BA0. Bone0 is the source trajectory, not the animated foot.
-- ///Preserve the two reciprocal refinements after the shared estimate model.
function SkeletonMotion.process_trajectory(self: SkeletonMotion, trajectory_bone: AnimationPartTransform, animation_to_world: AnimationPartTransform, dt: number)
	self.trajectory = compose_affine(trajectory_bone, self.next_trajectory)
	self.next_trajectory = copy_transform(self.trajectory)
	local reciprocal = native_arithmetic.reciprocal_estimate(dt)
	for _ = 1, 2 do
		local error_ = mul_add(-reciprocal, dt, 1.0)
		reciprocal = mul_add(reciprocal, error_, reciprocal)
	end
	local t = self.trajectory[4]
	local velocity = { f32(t[1] * reciprocal), f32(t[2] * reciprocal), f32(t[3] * reciprocal), f32(t[4] * reciprocal) }
	local world = {}
	for lane = 1, 4 do
		local x = f32(animation_to_world[1][lane] * velocity[1])
		local y = mul_add(animation_to_world[2][lane], velocity[2], x)
		world[lane] = mul_add(animation_to_world[3][lane], velocity[3], y)
	end
	self.velocity_world = world
	local source = self.trajectory
	local inverse = {}
	for axis = 1, 3 do
		inverse[axis] = { source[1][axis], source[2][axis], source[3][axis], 0.0 }
	end
	local translation = {}
	for lane = 1, 4 do
		local z = f32(f32(0.0 - source[4][3]) * inverse[3][lane])
		local y = mul_add(f32(0.0 - source[4][2]), inverse[2][lane], z)
		translation[lane] = mul_add(f32(0.0 - source[4][1]), inverse[1][lane], y)
	end
	inverse[4] = translation
	self.inverse_trajectory = inverse
end

-- ///82BD8CB0..8D2C precedes the landing/board-offset adjustment. Only sets
-- ///the side-on flag; this stage does not clear an already published flag.
-- ROBLOX: flags_2472: &mut u32 -> ячейка { value }.
function SkeletonMotion.publish_unadjusted_board(board: AnimationPartTransform, flags_2472: { value: number })
	if math.abs(board[1][2]) > from_bits(0x3f35_c28f) then
		flags_2472.value = bit32.bor(flags_2472.value, 0x8000)
	end
end

-- ///82BD8E14..8E50 uses board At.y, not height or translation. Returns the
-- ///difference published to Processed2768 and updates its complementary bits.
function SkeletonMotion.publish_adjusted_board(self: SkeletonMotion, board: AnimationPartTransform, flags_2468: { value: number }): number
	local at_y = board[3][2]
	local delta = f32(at_y - self.previous_board_at_y)
	self.previous_board_at_y = at_y
	local positive = at_y > 0.0
	flags_2468.value = bit32.bor(
		bit32.band(flags_2468.value, bit32.bnot(0x1800)),
		bit32.lshift(if positive then 1 else 0, 12),
		bit32.lshift(if positive then 0 else 1, 11)
	)
	return delta
end

return skeleton_motion
