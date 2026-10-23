--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/skeleton_landing_on_board.rs (коммит 2e16697)
--
-- Skeleton82BDDC68,82BE0858,82BE0CC0 and82BDCC28, original S3 TU3.
-- These calculate animation targets; the existing skeleton drives own physics.

local rt = require("../../rt")
local sar = require("./skeleton_animation_record")
local skeleton_root = require("./skeleton_root")
local board_motion_output = require("./board_motion_output")
local foot_ik_math = require("../animation/foot_ik/math")
local point_graph = require("../point_graph")
local wmath = require("../player/wipeout_state/math")
local trigonometry = require("../trigonometry")

local f32 = rt.f32
local from_bits = rt.from_bits
local compose_affine = sar.compose_affine
local transform_point = sar.transform_point
local copy_transform = sar.copy_transform
local orthonormalize = skeleton_root.orthonormalize
local inverse_rigid = skeleton_root.inverse_rigid
local SkeletonRootFrames = skeleton_root.SkeletonRootFrames
local inverse_length_squared = board_motion_output.inverse_length_squared
local interpolate_affine = foot_ik_math.interpolate_affine
local PointGraph = point_graph.PointGraph
local cross, dot, scale, sub = wmath.cross, wmath.dot, wmath.scale, wmath.sub

type Frame = sar.AnimationPartTransform
export type Vector = { number }

local skeleton_landing_on_board = {}

local function UP(): Vector
	return { 0.0, 1.0, 0.0, 0.0 }
end
local EPSILON = from_bits(0x37800000)

export type Settings = { root_y_offset: number, capsule_radius: number, capsule_length: number }

-- ROBLOX: f32::clamp(min, max) (без паники; при min > max Rust паникует — TODO).
local function clamp(value: number, min: number, max: number): number
	if value < min then
		return min
	end
	if value > max then
		return max
	end
	return value
end

-- ///82BDDC68 changes only skate-root and invokes COM-lift on the OLD animation root.
function skeleton_landing_on_board.skate_root(old: Frame, physical_com: Vector, flags2480: number, ground_y: number, settings: Settings): Frame
	local position = table.clone(physical_com)
	position[2] = f32(old[4][2] + settings.root_y_offset)
	if bit32.band(flags2480, 1) ~= 0 then
		local requested = f32(f32(ground_y + settings.capsule_length) + settings.capsule_radius)
		position[2] = clamp(requested, position[2], f32(position[2] + f32(0.3)))
	end
	return { table.clone(old[3]), table.clone(old[1]), table.clone(old[2]), position }
end

-- ///82BE0858. Packet trajectory reset is performed by the owning host before this.
-- ROBLOX: revert_frames: Option<u32> -> число или nil.
function skeleton_landing_on_board.update_root(roots: skeleton_root.SkeletonRootFrames, com: Vector, local_com: Vector, spin: number, revert_frames: number?, reversed: boolean)
	roots.initialize_heading = true
	local angle = spin
	if revert_frames ~= nil then
		local magnitude = f32(from_bits(0x4049_0FDB) / f32(revert_frames))
		angle = if reversed then magnitude else -magnitude
	end
	local sin, cos = trigonometry.sin_cos(angle)
	local yaw = { { cos, 0.0, -sin, 0.0 }, { 0.0, 1.0, 0.0, 0.0 }, { sin, 0.0, cos, 0.0 }, { 0.0, 0.0, 0.0, 0.0 } }
	local frame = compose_affine(roots.animation_to_world, yaw)
	if revert_frames ~= nil then
		frame = orthonormalize(frame)
	end
	--82BE0CC0: world-up correction with two independent degeneracy tests.
	local deviation = cross(frame[2], UP())
	if dot(deviation, deviation) > EPSILON then
		local right = cross(UP(), frame[3])
		local sq = dot(right, right)
		if sq > EPSILON then
			local unit = scale(right, inverse_length_squared(sq, 2))
			local target = { unit, UP(), cross(unit, UP()), table.clone(frame[4]) }
			frame = interpolate_affine(frame, target, f32(0.1))
		end
	end
	local rotation = copy_transform(frame)
	rotation[4] = { 0.0, 0.0, 0.0, 0.0 }
	frame[4] = sub(com, transform_point(rotation, local_com))
	SkeletonRootFrames.reset_initial_alignment(roots, orthonormalize(frame))
end

-- ///82BDCC28 returns no write outside its descending/unsuppressed branch.
-- ROBLOX: Option<Frame> -> Frame или nil.
function skeleton_landing_on_board.pose_adjustment(world_to_animation: Frame, actual_board: Frame, mapped_board: Frame, ik_offset: Vector, com_velocity_y: number, flags2480: number, time: number, blend: point_graph.PointGraph): Frame?
	if not (com_velocity_y < 0.0) or bit32.band(flags2480, 2) ~= 0 then
		return nil
	end
	local target = compose_affine(world_to_animation, actual_board)
	local rotation = copy_transform(world_to_animation)
	rotation[4] = { 0.0, 0.0, 0.0, 0.0 }
	local correction = transform_point(rotation, ik_offset)
	correction[2] = 0.0
	if target[4][2] > mapped_board[4][2] then
		correction[2] = f32(target[4][2] - mapped_board[4][2])
	end
	local t = {}
	for lane = 1, 4 do
		t[lane] = f32(mapped_board[4][lane] + correction[lane])
	end
	target[4] = t
	local blended = interpolate_affine(mapped_board, target, PointGraph.evaluate(blend, time))
	local offset = compose_affine(blended, inverse_rigid(mapped_board))
	offset[4][2] = -offset[4][2]
	return offset
end

return skeleton_landing_on_board
