--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/skeleton_root.rs (коммит 2e16697)
--
-- Skeleton::UpdateRootTransforms82BE0318: actual board prediction and the
-- retained animation-to-board/world frames. Full Reckoning is an input owner.

local rt = require("../../rt")
local board_ground = require("./board_ground")
local board_motion_output = require("./board_motion_output")
local native_arithmetic = require("./native_arithmetic")
local sar = require("./skeleton_animation_record")
local trigonometry = require("../trigonometry")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local dot3 = native_arithmetic.dot3
local inverse_length_squared = board_motion_output.inverse_length_squared
local angle_between = board_ground.angle_between
local IDENTITY = sar.IDENTITY
local compose_affine = sar.compose_affine

type F4 = { number }
type AnimationPartTransform = sar.AnimationPartTransform

local skeleton_root = {}

export type SkeletonRootFrames = {
	board: AnimationPartTransform,
	inverse_board: AnimationPartTransform,
	previous_board_position: F4,
	predicted_board_position: F4,
	-- ROBLOX: Option<[f32; 4]> -> значение или nil.
	supplied_prediction: F4?,
	animation_to_board: AnimationPartTransform,
	animation_to_world: AnimationPartTransform,
	world_to_animation: AnimationPartTransform,
	heading_alignment: AnimationPartTransform,
	initialize_heading: boolean,
}

local SkeletonRootFrames = {}
skeleton_root.SkeletonRootFrames = SkeletonRootFrames

-- ROBLOX: impl Default.
function SkeletonRootFrames.default(): SkeletonRootFrames
	-- Skeleton ctor82BD7260 matrix seeds,16416=0 and16417=1.
	return {
		board = IDENTITY(),
		inverse_board = IDENTITY(),
		previous_board_position = { 0.0, 0.0, 0.0, 0.0 },
		predicted_board_position = { 0.0, 0.0, 0.0, 0.0 },
		supplied_prediction = nil,
		animation_to_board = IDENTITY(),
		animation_to_world = IDENTITY(),
		world_to_animation = IDENTITY(),
		heading_alignment = IDENTITY(),
		initialize_heading = true,
	}
end

-- ///825C5710: reverse-axis Gram-Schmidt, two rsqrt refinements, translation copy.
function skeleton_root.orthonormalize(source: AnimationPartTransform): AnimationPartTransform
	local result = sar.copy_transform(source)
	local identity = IDENTITY()
	for axis = 3, 1, -1 do
		local vector = table.clone(source[axis])
		for prior = 3, axis + 1, -1 do
			local projection = dot3(result[prior], source[axis])
			for lane = 1, 4 do
				vector[lane] = f32(vector[lane] - f32(result[prior][lane] * projection))
			end
		end
		local squared = dot3(vector, vector)
		if squared <= from_bits(0x3586_37bd) then
			-- Degenerate axes appear after wipeout bail teleports when heading
			-- initialization and ragdoll frames disagree. NaN here poisons COM
			-- frames and deck torque before the shared solve.
			result[axis] = identity[axis]
		else
			local reciprocal = inverse_length_squared(squared, 2)
			result[axis] = { f32(vector[1] * reciprocal), f32(vector[2] * reciprocal), f32(vector[3] * reciprocal), f32(vector[4] * reciprocal) }
		end
	end
	return result
end
local orthonormalize = skeleton_root.orthonormalize

-- /// Inline rigid inverse: transposeXYZ, zero stored W, translation Z,Y,X FMA.
function skeleton_root.inverse_rigid(source: AnimationPartTransform): AnimationPartTransform
	local result = IDENTITY()
	for axis = 1, 3 do
		result[axis] = { source[1][axis], source[2][axis], source[3][axis], 0.0 }
	end
	local t = source[4]
	local translation = { f32(0.0 - t[1]), f32(0.0 - t[2]), f32(0.0 - t[3]), f32(0.0 - t[4]) }
	local out = {}
	for i = 1, 4 do
		local z = f32(translation[3] * result[3][i])
		local y = mul_add(translation[2], result[2][i], z)
		out[i] = mul_add(translation[1], result[1][i], y)
	end
	result[4] = out
	return result
end
local inverse_rigid = skeleton_root.inverse_rigid

-- ///82BDFE58: teleport prediction uses the current physical deck position;
-- ///the heading and remaining root composition match82BE0318.
function SkeletonRootFrames.update_teleport(self: SkeletonRootFrames, board: AnimationPartTransform, animation_board: AnimationPartTransform, reckoning_frame_816: AnimationPartTransform)
	self.initialize_heading = true
	self.supplied_prediction = table.clone(board[4])
	SkeletonRootFrames.update(self, board, { 0.0, 0.0, 0.0, 0.0 }, 0.0, animation_board, reckoning_frame_816)
	--82BDFF0C differs from ordinary update's previous-position snapshot.
	self.previous_board_position = table.clone(board[4])
end

-- /// Reset82BD9990 writes these two frames from the initial mapped pose.
-- /// Other root histories retain their independently initialized state.
function SkeletonRootFrames.reset_initial_alignment(self: SkeletonRootFrames, animation_to_world: AnimationPartTransform)
	self.animation_to_world = sar.copy_transform(animation_to_world)
	self.world_to_animation = inverse_rigid(animation_to_world)
end

function SkeletonRootFrames.update(self: SkeletonRootFrames, board: AnimationPartTransform, board_velocity: F4, time_step: number, animation_board: AnimationPartTransform, reckoning: AnimationPartTransform)
	self.previous_board_position = table.clone(self.board[4])
	self.board = sar.copy_transform(board)
	self.inverse_board = inverse_rigid(board)
	-- ROBLOX: Option::take().unwrap_or_else(...).
	local supplied = self.supplied_prediction
	self.supplied_prediction = nil
	if supplied ~= nil then
		self.predicted_board_position = supplied
	else
		local p = {}
		for i = 1, 4 do
			p[i] = mul_add(board_velocity[i], time_step, board[4][i])
		end
		self.predicted_board_position = p
	end
	if self.initialize_heading then
		--8296EC98 uses one rsqrt refinement, angle in[0,2pi], not atan2.
		local at = vector.create(animation_board[3][1], 0.0, animation_board[3][3])
		local forward = vector.create(0.0, 0.0, 1.0)
		local angle = angle_between(at, forward)
		-- Normalize before the sign test, exactly as the angle helper.
		local at4 = { at.x, at.y, at.z, 0.0 }
		local sq = dot3(at4, at4)
		if sq > from_bits(0x38D1_B717) then
			local inverse = inverse_length_squared(sq, 1)
			local x = f32(at.x * inverse)
			-- dot(cross(normalized_at, forward), world_up) == -x.
			if 0.0 > -x then
				angle = f32(from_bits(0x40C9_0FDB) - angle)
			end
		end
		local sin, cos = trigonometry.sin_cos(angle)
		self.heading_alignment = {
			{ cos, 0.0, -sin, 0.0 },
			{ 0.0, 1.0, 0.0, 0.0 },
			{ sin, 0.0, cos, 0.0 },
			{ 0.0, 0.0, 0.0, 0.0 },
		}
		self.initialize_heading = false
	end
	local remove_board_translation = IDENTITY()
	local ab = animation_board[4]
	remove_board_translation[4] = { -ab[1], -ab[2], -ab[3], -ab[4] }
	local loc = compose_affine(self.heading_alignment, remove_board_translation)
	self.animation_to_board = compose_affine(reckoning, loc)
	local world_translation = IDENTITY()
	world_translation[4] = table.clone(self.predicted_board_position)
	self.animation_to_world = orthonormalize(compose_affine(world_translation, self.animation_to_board))
	self.world_to_animation = inverse_rigid(self.animation_to_world)
end

return skeleton_root
