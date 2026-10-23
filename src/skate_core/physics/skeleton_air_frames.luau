--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/skeleton_air_frames.rs (коммит 2e16697)
--
-- Original TU3 animated-board and COM-controlled air frame calculations.
-- 82BDDA10, 82BDE600 and 82BDE7B8. Persistent frames remain in their owners.

local rt = require("../../rt")
local sar = require("./skeleton_animation_record")
local skeleton_board_frames = require("./skeleton_board_frames")
local skeleton_root = require("./skeleton_root")
local trigonometry = require("../trigonometry")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local IDENTITY = sar.IDENTITY
local compose_affine = sar.compose_affine
local copy_transform = sar.copy_transform
local inverse_rigid = skeleton_root.inverse_rigid
local orthonormalize = skeleton_root.orthonormalize
local SkeletonBoardFrames = skeleton_board_frames.SkeletonBoardFrames

type Transform = sar.AnimationPartTransform
type F4 = { number }
type SkeletonRootFrames = skeleton_root.SkeletonRootFrames
type SkeletonBoardFrames = skeleton_board_frames.SkeletonBoardFrames

local skeleton_air_frames = {}

-- /// 82B985E8 publishes the one-frame request and retained frame count;
-- /// 82BDE920 loads that count with lwz before unsigned-to-floating conversion.
export type AirDismountRevert = {
	requested: boolean,
	frames: number,
	goofy: boolean,
}

-- /// 82BDDA5C..DBBC, after the common UpdateRootTransforms82BE0318.
-- /// The skate root uses the unblended animation target in this path.
-- ROBLOX: flags: &mut u32 -> ячейка { value }.
function skeleton_air_frames.prepare_animated(roots: SkeletonRootFrames, board: SkeletonBoardFrames, mapped_board: Transform, flags: { value: number }): Transform
	local loc = compose_affine(roots.animation_to_board, mapped_board)
	local placement = IDENTITY()
	placement[4] = table.clone(roots.predicted_board_position)
	local target = compose_affine(placement, loc)
	flags.value = bit32.bor(flags.value, bit32.lshift(1, 19))
	board.animation_target = copy_transform(target)
	board.skate_root = copy_transform(target)
	SkeletonBoardFrames.update_com_lift(board, roots.animation_to_world, board.centre_of_mass, 0.0)
	return target
end

-- /// 82BDE7B8: preserve prior heading on entry, apply an authored dismount
-- /// revert, then place the current animation COM at the integrated air target.
-- /// It does not update animation_to_board/inverse_board or consume prediction.
function skeleton_air_frames.update_known_air_roots(roots: SkeletonRootFrames, reckoning: Transform, target_com: F4, animation_com: F4, revert: AirDismountRevert)
	if roots.initialize_heading then
		roots.heading_alignment = compose_affine(inverse_rigid(reckoning), roots.animation_to_world)
		--82BDE8EC overwrites the entire affine translation with zero.
		roots.heading_alignment[4] = { 0.0, 0.0, 0.0, 0.0 }
		roots.initialize_heading = false
	end
	if revert.requested then
		-- ROBLOX: `frames as f32` — u32 -> f32.
		local angle = f32(from_bits(0x4049_0fdb) / f32(revert.frames))
		if not revert.goofy then
			angle = -angle
		end
		local sin, cos = trigonometry.sin_cos(angle)
		local rotation = {
			{ cos, 0.0, -sin, 0.0 },
			{ 0.0, 1.0, 0.0, 0.0 },
			{ sin, 0.0, cos, 0.0 },
			{ 0.0, 0.0, 0.0, 0.0 },
		}
		roots.heading_alignment = orthonormalize(compose_affine(roots.heading_alignment, rotation))
	end
	local world = compose_affine(reckoning, roots.heading_alignment)
	--82BDEB98..BB8: rotate COM without adding the prior translation.
	local t = {}
	for lane = 1, 4 do
		local x = f32(world[1][lane] * animation_com[1])
		local y = mul_add(world[2][lane], animation_com[2], x)
		t[lane] = f32(target_com[lane] - mul_add(world[3][lane], animation_com[3], y))
	end
	world[4] = t
	roots.animation_to_world = orthonormalize(world)
	roots.world_to_animation = inverse_rigid(roots.animation_to_world)
end

-- ///82BDE634..6DC. ApplyBoardAnimation follows before the completion below.
function skeleton_air_frames.prepare_known_air(roots: SkeletonRootFrames, board: SkeletonBoardFrames, mapped_board: Transform, flags: { value: number }): Transform
	local target = compose_affine(roots.animation_to_world, mapped_board)
	flags.value = bit32.bor(flags.value, bit32.lshift(1, 19))
	board.animation_target = copy_transform(target)
	return target
end

-- ///82BDE748..7A4, after applying the target and the board velocity update.
function skeleton_air_frames.finish_known_air(roots: SkeletonRootFrames, board: SkeletonBoardFrames, effective_board: Transform)
	board.physical_board = copy_transform(effective_board)
	board.skate_root = copy_transform(effective_board)
	SkeletonBoardFrames.update_com_lift(board, roots.animation_to_world, board.centre_of_mass, 0.0)
	roots.predicted_board_position = table.clone(effective_board[4])
	roots.supplied_prediction = table.clone(effective_board[4])
end

-- ///82BDEEB8/82BE0E80: anchor an animation bone or COM in world space.
-- ///Plants retain heading_alignment and do not consume board prediction.
function skeleton_air_frames.update_plant_roots(roots: SkeletonRootFrames, reckoning: Transform, world_anchor: F4, animation_anchor: F4)
	local world = compose_affine(reckoning, roots.heading_alignment)
	local t = {}
	for i = 1, 4 do
		local x = f32(world[1][i] * animation_anchor[1])
		local y = mul_add(world[2][i], animation_anchor[2], x)
		t[i] = f32(world_anchor[i] - mul_add(world[3][i], animation_anchor[3], y))
	end
	world[4] = t
	roots.animation_to_world = orthonormalize(world)
	roots.world_to_animation = inverse_rigid(roots.animation_to_world)
end

return skeleton_air_frames
