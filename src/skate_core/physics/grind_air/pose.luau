--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/grind_air/pose.rs (коммит 2e16697)
--
-- ROBLOX: `use super::*` -> pose.parent; impl Adjustment -> pose.Adjustment.local_transform.

local rt = require("../../../rt")
local trigonometry = require("../../trigonometry")
local sar = require("../skeleton_animation_record")

local f32 = rt.f32
local mul_add = rt.mul_add

type V = { number }
type Frame = { V }

local pose = {}
pose.parent = (nil :: any)

export type PoseInput = {
	-- Skeleton11920, not the processed physical board frame.
	animation_to_world: Frame,
	-- Skeleton11984, already produced by UpdateRootTransforms.
	world_to_animation: Frame,
	-- Skeleton12528: retained physical-board Z axis.
	physical_forward: V,
	-- Skeleton12672: this frame's mapped animation board translation.
	animation_board_position: V,
}

-- Full-angle axis matrix used by82D71430 and82BDCFB0 (not half-angle quaternion).
function pose.axis_rotation(axis: V, angle: number): Frame
	local sin, cos = trigonometry.sin_cos(angle)
	local x, y, z = axis[1], axis[2], axis[3]
	local k = f32(1.0 - cos)
	local kx, ky, kz = f32(k * x), f32(k * y), f32(k * z)
	return {
		{ mul_add(kx, x, cos), mul_add(kx, y, f32(sin * z)), mul_add(kx, z, f32(-sin * y)), 0.0 },
		{ mul_add(ky, x, f32(-sin * z)), mul_add(ky, y, cos), mul_add(ky, z, f32(sin * x)), 0.0 },
		{ mul_add(kz, x, f32(sin * y)), mul_add(kz, y, f32(-sin * x)), mul_add(kz, z, cos), 0.0 },
		{ 0.0, 0.0, 0.0, 0.0 },
	}
end

function pose.direction(frame: Frame, vector: V): V
	local P = pose.parent
	return P.madd(frame[3], vector[3], P.madd(frame[2], vector[2], P.scale(frame[1], vector[1])))
end
local direction = pose.direction

local Adjustment = {}
pose.Adjustment = Adjustment

-- 82BDCFB0: R(up,Y)*R(rail,X)*R(physicalZ,Z), converted to animation space,
-- then pivot around the current mapped board and add the local displacement.
function Adjustment.local_transform(self: any, input: PoseInput): Frame
	local P = pose.parent
	-- Unlike NormalizeSafe, this native wrapper has no zero-vector fallback.
	local across = P.cross(P.UP, self.axis)
	across = P.scale(across, P.inverse_length(P.dot(across, across)))
	local up = P.cross(self.axis, across)
	up = P.scale(up, P.inverse_length(P.dot(up, up)))
	local yaw = pose.axis_rotation(up, self.angles[2])
	local lean = pose.axis_rotation(self.axis, self.angles[1])
	local pitch = pose.axis_rotation(input.physical_forward, self.angles[3])
	local loc = sar.IDENTITY() :: any
	for i = 1, 3 do
		loc[i] = direction(input.world_to_animation, direction(yaw, direction(lean, direction(pitch, input.animation_to_world[i]))))
	end
	local pivot = input.animation_board_position
	loc[4] = P.sub(P.add(direction(input.world_to_animation, self.offset), pivot), direction(loc, pivot))
	return loc
end

return pose
