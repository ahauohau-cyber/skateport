--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/wipeout_state/body.rs (коммит 2e16697)
--
-- Original body adjustments used by WipeoutGround300.
-- ROBLOX: bodies()[i] (i с нуля) -> bodies[i + 1]; linear_velocity — vector.

local rt = require("../../../rt")
local m = require("./math")
local skeleton_body = require("../../physics/skeleton_body")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local SkeletonBody = skeleton_body.SkeletonBody

type V = m.V

local body = {}

function body.set_velocity(b: any, velocity: V)
	local bodies = SkeletonBody.bodies_mut(b)
	for i = 2, 24 do
		bodies[i].rates.linear_velocity = vector.create(velocity[1], velocity[2], velocity[3])
	end
end
function body.add_velocity(b: any, velocity: V)
	local bodies = SkeletonBody.bodies_mut(b)
	for i = 2, 24 do
		local v = bodies[i].rates.linear_velocity
		bodies[i].rates.linear_velocity = vector.create(f32(v.x + velocity[1]), f32(v.y + velocity[2]), f32(v.z + velocity[3]))
	end
end
-- 82BE74C8. Upper parts retain a tenth of the normal component; lower parts zero it.
function body.remove_normal_velocity(b: any, normal: V)
	local bodies = SkeletonBody.bodies_mut(b)
	for i = 1, 23 do
		local lv = bodies[i + 1].rates.linear_velocity
		local v = { lv.x, lv.y, lv.z, 0.0 }
		local projected = m.scale(normal, m.dot(normal, v))
		local nxt = m.madd(projected, if i < 15 then f32(0.1) else 0.0, m.sub(v, projected))
		bodies[i + 1].rates.linear_velocity = vector.create(nxt[1], nxt[2], nxt[3])
	end
end
-- 82BE75B0 then82BD41B0: average with the requested velocity and limit distance2.
function body.blend_velocity(b: any, target: V)
	local bodies = SkeletonBody.bodies_mut(b)
	for i = 2, 24 do
		local v = bodies[i].rates.linear_velocity
		local average = m.madd(target, 0.5, { f32(v.x * 0.5), f32(v.y * 0.5), f32(v.z * 0.5), 0.0 })
		local delta = m.sub(average, target)
		local length = m.length(delta)
		local nxt = if length <= 2.0 then average else m.madd(delta, f32(2.0 / length), target)
		bodies[i].rates.linear_velocity = vector.create(nxt[1], nxt[2], nxt[3])
	end
end
-- 82BE76B0: length and reciprocal each use the original two refinements.
function body.limit_velocity(b: any, maximum: number)
	local bodies = SkeletonBody.bodies_mut(b)
	for i = 2, 24 do
		local lv = bodies[i].rates.linear_velocity
		local v = { lv.x, lv.y, lv.z, 0.0 }
		if m.dot(v, v) > f32(maximum * maximum) then
			local nxt = m.scale(v, f32(m.reciprocal(m.length(v)) * maximum))
			bodies[i].rates.linear_velocity = vector.create(nxt[1], nxt[2], nxt[3])
		end
	end
end
-- 82D9CD60 and82D9CE58 publish per-second drag into the same live inertia.
function body.set_drag(b: any, linear: number, angular: number)
	for _, part in SkeletonBody.bodies_mut(b) do
		part.inertia.linear_drag = f32(linear * from_bits(0x426F_FFFF))
		part.inertia.angular_drag = f32(angular * from_bits(0x426F_FFFF))
	end
end
-- 82BE32D0.
function body.set_wipeout_drag(b: any, drag: number)
	body.set_drag(b, m.clamp(drag, 0.0, 1.0), m.clamp(f32(f32(drag + 1.0) * 0.5), 0.0, 1.0))
end
-- 82BE3998. Source uses cached physical-record positions before the live writes.
local WEIGHTS = {
	1.7, 1.5, 1.2, 1.0, 1.0, 1.0, 1.2, 1.0, 1.0, 1.0,
	1.2, 1.0, 1.0, 1.0, 0.5, 0.5, 0.5, 0.6, 0.5, 0.5, 0.5, 0.6, 1.0,
}
for i, w in WEIGHTS do
	WEIGHTS[i] = f32(w)
end
function body.special_surface(b: any, height: number)
	-- 82BE3A70..3B38 tests cached part depth only; no world/floor-depth gate.
	local bodies = SkeletonBody.bodies_mut(b)
	for i = 1, 23 do
		local depth = f32(f32(height + f32(0.1)) - b.record.pose[i + 1][4][2])
		local drag
		if depth > 0.0 then
			SkeletonBody.apply_part_displacement(b, i, { 0.0, f32(mul_add(depth, f32(0.6), f32(0.1)) * WEIGHTS[i]), 0.0, 0.0 })
			drag = f32(0.1)
		else
			drag = f32(0.005)
		end
		bodies[i + 1].inertia.angular_drag = f32(drag * from_bits(0x426F_FFFF))
		bodies[i + 1].inertia.linear_drag = f32(drag * from_bits(0x426F_FFFF))
	end
end

return body
