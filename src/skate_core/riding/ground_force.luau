--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/riding/ground_force.rs (коммит 2e16697)
--
-- Complete TU3 82D931E8, called twice by Ground Update for tags 4 and 5.
-- The research index has not recovered its original name. Keep its four
-- caller-supplied scalar arguments explicit instead of inventing units.

local rt = require("../../rt")
local vector_mod = require("./vector")

local f32 = rt.f32
local mul_add = rt.mul_add
local clamp, dot3, normalize = vector_mod.clamp, vector_mod.dot3, vector_mod.normalize

type F4 = { number }

local ground_force = {}

export type GroundForceSettings = {
	range_1220: number,
	speed_scale_1224: number,
	scale_1228: number,
	normal_threshold: F4,
}

export type GroundForceInput = {
	argument_1: number,
	application_z: number,
	argument_3: number,
	argument_4: number,
	balance: number, -- Processed +2720
	surface_speed: number, -- +2656
	axis_384: F4,
	velocity_400: F4,
	axis_544: F4,
}

-- ROBLOX: [f32; 8] -> таблица из 8.
function ground_force.calculate(s: GroundForceSettings, i: GroundForceInput): { number }
	local fraction = clamp(f32(i.argument_1 / s.range_1220), 0.0, 1.0)
	-- Native double literals at822F8700/+8 are0 and1, narrowed at zero arg1.
	local zero_scalar = if i.argument_1 ~= 0.0 or i.balance ~= 0.0 then 1.0 else 0.0
	local speed = f32(f32(i.surface_speed * 0.125) * s.speed_scale_1224)
	local remainder = f32(f32(f32(1.0 - fraction) * s.scale_1228) * zero_scalar)
	local magnitude = -f32(mul_add(speed, fraction, remainder) * i.argument_4)
	local force = {}
	for n = 1, 4 do
		force[n] = mul_add(i.axis_544[n], magnitude, f32(-i.axis_384[n] * i.argument_3))
	end
	local direction = normalize(i.velocity_400, s.normal_threshold)
	local projected = dot3(direction, force)
	local result = table.create(8, 0.0)
	for n = 1, 4 do
		result[n] = f32(force[n] - f32(direction[n] * projected))
	end
	result[7] = i.application_z
	return result
end

return ground_force
