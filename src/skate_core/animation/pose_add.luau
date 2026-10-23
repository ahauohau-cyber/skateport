--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/pose_add.rs (коммит 2e16697)
--
-- ACS immediate AddSQT 828CCC08, used by SkaterAnim::AddBindPose 82B98118.

local rt = require("../../rt")
local sqt = require("./output/sqt")
local pose_trajectory = require("./pose_trajectory")

local f32 = rt.f32

local pose_add = {}

-- Native operand B supplies the reference frame. The designated motion
-- operand supplies the channel weight, independently of operand ordering.
function pose_add.add(a: sqt.Sqt, b: sqt.Sqt, motion_is_a: boolean): sqt.Sqt
	local rotated = pose_trajectory.rotate(b.rotation, { a.translation[1], a.translation[2], a.translation[3] })
	return {
		scale = { f32(b.scale[1] * a.scale[1]), f32(b.scale[2] * a.scale[2]), f32(b.scale[3] * a.scale[3]), f32(b.scale[4] * a.scale[4]) },
		rotation = pose_trajectory.multiply(b.rotation, a.rotation),
		translation = {
			f32(rotated[1] + b.translation[1]),
			f32(rotated[2] + b.translation[2]),
			f32(rotated[3] + b.translation[3]),
			if motion_is_a then a.translation[4] else b.translation[4],
		},
	}
end

return pose_add
