--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/grind_air/angles.rs (коммит 2e16697)
--
-- ROBLOX: `use super::*` -> angles.parent; state: &mut GrindAir -> таблица.

local rt = require("../../../rt")
local targets = require("./targets")

local f32 = rt.f32
local fmin, fmax = rt.fmin, rt.fmax

type V = { number }

local angles = {}
angles.parent = (nil :: any)

function angles.update(state: any, input: any, s: any, target: any, samples: { { V } }, rail: V, normal: V, kind: number, time: number)
	local P = angles.parent
	local dot, sub, scale, unit, signed_angle, add = P.dot, P.sub, P.scale, P.unit, P.signed_angle, P.add
	local DEG, RAD, PI = P.DEG, P.RAD, P.PI
	-- 82D723D0 stores angleArray[type], NOT the range validator's frame index.
	local heading = state.headings[kind + 1]
	local desired = if heading > 0.0 then targets.DESIRED[kind + 1] else -targets.DESIRED[kind + 1]
	local speed = fmin(fmax(f32(f32(f32(desired - heading) / time) * s.yaw_assist[kind + 1]), -s.max_angle), s.max_angle)
	local ad = table.clone(state.angle_delta)
	ad[2] = f32(fmin(fmax(f32(f32(ad[2] * RAD) + speed), -s.max_angle), s.max_angle) * DEG)
	local points = samples[math.floor(f32(time + 0.5)) + 1]
	local forward = sub(points[2], points[5])
	local projected = unit(sub(forward, scale(rail, dot(rail, forward))))
	local o = target.orientation
	local err
	if kind == 0 or kind == 3 then
		local angle = signed_angle(projected, o.boardslide_dir, rail)
		local half = f32(PI * 0.5)
		if angle > half then
			err = f32(angle - PI)
		elseif angle < -half then
			err = f32(angle + PI)
		else
			err = angle
		end
	elseif kind == 1 or kind == 2 then
		local from = if kind == 1 then scale(projected, -1.0) else projected
		local a = signed_angle(from, o.tipslide_dir, rail)
		local b = signed_angle(from, o.backslash_dir, rail)
		err = if math.abs(a) < math.abs(b) then a else b
	else
		err = 0.0
	end
	local maximum = f32(s.max_angle * DEG)
	ad[1] = fmin(fmax(f32(ad[1] + f32(err / time)), -maximum), maximum)
	-- 82D71BB0 native broadcast subtraction is intentional, not vector rejection.
	local b0 = input.board[1]
	local d = dot(b0, normal)
	local projected_right = unit({ f32(b0[1] - d), f32(b0[2] - d), f32(b0[3] - d), f32(b0[4] - d) })
	local correction = if dot(projected_right, projected_right) > f32(0.9)
		then f32(signed_angle(b0, projected_right, input.board[3]) * f32(0.9))
		else 0.0
	ad[3] = if kind < 4 then f32(correction / time) else 0.0
	state.angle_delta = ad
	state.angles = add(state.angles, ad)
end

return angles
