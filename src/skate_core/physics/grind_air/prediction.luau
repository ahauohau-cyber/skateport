--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/grind_air/prediction.rs (коммит 2e16697)
--
-- ROBLOX: Samples = [[V; 5]; 12] -> samples[frame + 1][point + 1];
-- headings: &mut [f32; 12] -> таблица, меняется на месте.

local rt = require("../../../rt")
local trigonometry = require("../../trigonometry")
local sar = require("../skeleton_animation_record")
local pose = require("./pose")

local f32 = rt.f32
local from_bits = rt.from_bits
local fmin, fmax = rt.fmin, rt.fmax

type V = { number }

local prediction = {}
prediction.parent = (nil :: any)

export type Samples = { { V } }

-- 82D71430: frame zero is the actual processed deck; advance velocity before position.
function prediction.project(input: any, s: any, rail: V, normal: V, headings: { number }): Samples
	local P = prediction.parent
	local dot, sub, add, scale, madd, cross, length, unit = P.dot, P.sub, P.add, P.scale, P.madd, P.cross, P.length, P.unit
	local samples: Samples = {}
	for i = 1, 12 do
		samples[i] = { P.zero(), P.zero(), P.zero(), P.zero(), P.zero() }
	end
	local board = table.clone(input.board)
	local velocity = input.velocity
	local speed = length(input.angular_velocity)
	local rotation
	if speed < from_bits(0x3780_0000) then
		rotation = sar.IDENTITY()
	else
		rotation = pose.axis_rotation(scale(input.angular_velocity, f32(1.0 / speed)), f32(speed * input.timestep))
	end
	local acceleration_step = madd(input.up, f32(s.stomp * input.timestep), { 0.0, f32(input.timestep * from_bits(0xc11c_cccd)), 0.0, 0.0 })
	for frame = 1, s.frames do
		local row = {}
		for k, p in s.points do
			row[k] = madd(board[3], p[3], madd(board[2], p[2], madd(board[1], p[1], board[4])))
		end
		samples[frame] = row
		-- 82D71F40, preserve the target's literal post-ACos 90/180 fold.
		local forward = sub(row[2], row[5])
		local projected = unit(sub(forward, scale(normal, dot(normal, forward))))
		local aligned = if dot(projected, rail) < 0.0 then scale(projected, -1.0) else projected
		local angle = math.abs(trigonometry.acos(fmin(fmax(dot(aligned, rail), -1.0), 1.0)))
		if angle > 90.0 then
			angle = f32(180.0 - angle)
		end
		local sign = if dot(normal, cross(aligned, rail)) < 0.0 then -1.0 else 1.0
		headings[frame] = -f32(f32(sign * angle) * P.RAD)
		for axis = 1, 3 do
			board[axis] = pose.direction(rotation, board[axis])
		end
		velocity = add(velocity, acceleration_step)
		board[4] = madd(velocity, input.timestep, board[4])
	end
	return samples
end

return prediction
