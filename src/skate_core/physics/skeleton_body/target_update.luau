--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/skeleton_body/target_update.rs (коммит 2e16697)
--
-- Original Skeleton::UpdateHookPositions82BE1618 and extra followers82BE18B8.
-- Their target changes precede the returned teleport/large-displacement gate.
-- ROBLOX: `impl SkeletonTargets` в другом файле -> функции добавляются в таблицу
-- SkeletonTargets из targets.luau при загрузке модуля.

local rt = require("../../../rt")
local normalization = require("../board_pose/normalization")
local native_arithmetic = require("../native_arithmetic")
local sar = require("../skeleton_animation_record")
local ground_orientation = require("../../riding/ground_orientation")
local targets_mod = require("./targets")
local runtime = require("./runtime")

local f32 = rt.f32
local from_bits = rt.from_bits
local to_bits = rt.to_bits
local dot3 = native_arithmetic.dot3
local compose_affine = sar.compose_affine
local SkeletonTargets = targets_mod.SkeletonTargets
local SkeletonBody = runtime.SkeletonBody

type Transform = sar.AnimationPartTransform
type F4 = { number }

local target_update = {}

export type SkeletonTargetInput = {
	--Skeleton11792, mapped physical animation hips, not physical COM.
	animation_hips: Transform,
	--Skeleton11728, mapped physical animation board.
	animation_board: Transform,
	--Skeleton11920.
	animation_to_world: Transform,
	--Skeleton12368, inverse of the actual physical board.
	inverse_board: Transform,
	--Skeleton15760, published by the current movement branch.
	skate_root: Transform,
	--Skeleton15824 and15888 from the actual COM/lift producer.
	com_frame: Transform,
	lifted_com_frame: Transform,
	--Skeleton16508.
	teleporting: boolean,
}

export type ExtraTargetPositions = {
	--Skeleton11632,11648,11664 respectively.
	com: F4,
	lifted_com: F4,
	following_com: F4,
}

export type SkeletonTargetUpdate = {
	--Skeleton12240, inverse physical board * animated board in world space.
	animation_board_to_physics: Transform,
	positions: ExtraTargetPositions,
	--False triggers GeneralUpdate's real teleport/reset behavior after all
	--target and velocity writes, not a guard suppressing those writes.
	continuous: boolean,
}

local function orthonormalize(frame: Transform): Transform
	local w = table.create(16) :: any
	for i = 0, 15 do
		w[i + 1] = to_bits(frame[i // 4 + 1][i % 4 + 1])
	end
	local words = normalization.orthonormalize_rotation(w)
	local m = {}
	for i = 0, 3 do
		m[i + 1] = { from_bits(words[i * 4 + 1]), from_bits(words[i * 4 + 2]), from_bits(words[i * 4 + 3]), from_bits(words[i * 4 + 4]) }
	end
	return m
end

-- ///82BE1618 updates only the two hook targets and returns the board-space
-- /// transform consumed by the skeleton input owner.
function target_update.update_hook_positions(self: targets_mod.SkeletonTargets, input: SkeletonTargetInput): Transform
	local hips = compose_affine(input.animation_to_world, input.animation_hips)
	local board = compose_affine(input.animation_to_world, input.animation_board)
	local animation_board_to_physics = compose_affine(input.inverse_board, board)
	SkeletonTargets.set_transform(self, 0, orthonormalize(hips))
	SkeletonTargets.set_transform(self, 1, orthonormalize(input.skate_root))
	return animation_board_to_physics
end

-- ///Complete82BE18B8, also called by Reset82BD9990 after constructing its
-- ///COM frames. Replaces only physical extra-body velocities, never forces.
function target_update.update_extra_targets(self: targets_mod.SkeletonTargets, skeleton: runtime.SkeletonBody, com_frame: Transform, lifted_com_frame: Transform): ExtraTargetPositions
	SkeletonTargets.set_transform(self, 2, lifted_com_frame)
	SkeletonTargets.set_transform(self, 3, com_frame)
	local positions = {
		com = table.clone(com_frame[4]),
		lifted_com = table.clone(lifted_com_frame[4]),
		following_com = table.clone(com_frame[4]),
	}
	--GetPartTransform includes the actual local mass frame. Keep that
	--source even though these centered extra capsules have identity frames.
	local parts = SkeletonBody.part_transforms(skeleton)
	for _, pair in { { 24, lifted_com_frame[4] }, { 25, com_frame[4] } } do
		local part = pair[1] :: number
		local target = pair[2] :: F4
		local current = parts[part + 1][4]
		local velocity = vector.create(
			f32(f32(target[1] - current[1]) * 60.0),
			f32(f32(target[2] - current[2]) * 60.0),
			f32(f32(target[3] - current[3]) * 60.0)
		)
		SkeletonBody.bodies_mut(skeleton)[part + 1].rates.linear_velocity = ground_orientation.clamp_length(velocity, 40.0)
	end
	return positions
end

function target_update.update_positions(self: targets_mod.SkeletonTargets, input: SkeletonTargetInput, skeleton: runtime.SkeletonBody): SkeletonTargetUpdate
	local previous = SkeletonTargets.transform(self, 0)[4]
	local animation_board_to_physics = target_update.update_hook_positions(self, input)
	local hips = SkeletonTargets.transform(self, 0)[4]
	local change = { f32(previous[1] - hips[1]), f32(previous[2] - hips[2]), f32(previous[3] - hips[3]), f32(previous[4] - hips[4]) }
	local positions = target_update.update_extra_targets(self, skeleton, input.com_frame, input.lifted_com_frame)
	--82BE18A0 checks strictly greater; unordered distance alone does not
	--force this returnfalse. Preserve the independent teleport byte test.
	local continuous = not input.teleporting and not (dot3(change, change) > 1.0)
	return {
		animation_board_to_physics = animation_board_to_physics,
		positions = positions,
		continuous = continuous,
	}
end

-- ROBLOX: методы impl-блока.
;(SkeletonTargets :: any).update_hook_positions = target_update.update_hook_positions
;(SkeletonTargets :: any).update_positions = target_update.update_positions
;(SkeletonTargets :: any).update_extra_targets = target_update.update_extra_targets

return target_update
