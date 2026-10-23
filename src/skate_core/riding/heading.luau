--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/riding/heading.rs (коммит 2e16697)
--
-- Complete TU3 Toolkit_CalcHeadingTorque 82D92CF8. Ground calls this before
-- AntiFlipTorque; the two are distinct. The caller owns board+284 history.

local rt = require("../../rt")
local reciprocal_sqrt = require("../physics/reciprocal_sqrt")
local point_graph = require("../point_graph")
local trigonometry = require("../trigonometry")
local vector_mod = require("./vector")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local estimate = reciprocal_sqrt.estimate
local PointGraph = point_graph.PointGraph
local dot3 = vector_mod.dot3

type F4 = { number }

local heading = {}

export type HeadingSettings = {
	manual_wrong_wheel_scalar: number, -- +904
	manual_damping: number, -- +908
	speed_max: number, -- +912
	heading_strength: number, -- +916
	turn_strength: number, -- +920
	angular_response: point_graph.PointGraph, -- +940/+972
	manual_response: point_graph.PointGraph, -- +1020/+1052
	inclination_response: point_graph.PointGraph, -- +1084/+1116
	speed_response: point_graph.PointGraph, -- +1148/+1180
	-- Live four-lane threshold at 830BD350, initialized by 82F826F8.
	normal_threshold: F4,
}

export type HeadingInput = {
	balance: number, -- Processed +2720
	manual_turn: number, -- +2672
	flags_2472: number,
	timestep: number, -- +2604
	signed_speed: number, -- +2612
	manual_curve_input: number, -- +2652
	turn_2712: number,
	scalar_2740: number,
	velocity: F4, -- +432
	normal: F4, -- +464
	angular_velocity: F4, -- +720
	-- Ground caller's r6 matrix, in native column order. No host orthogonalization.
	transform: { F4 },
}

local function clamp(value: number, lower: number, upper: number): number
	local v = if f32(lower - value) >= 0.0 then lower else value
	return if f32(upper - v) >= 0.0 then v else upper
end

local function map(v: F4, s: number): F4
	return { f32(v[1] * s), f32(v[2] * s), f32(v[3] * s), f32(v[4] * s) }
end

-- ROBLOX: previous: &mut f32 -> ячейка { value }.
function heading.calculate(settings: HeadingSettings, input: HeadingInput, previous: { value: number }): F4
	if input.balance ~= 0.0 and input.manual_turn ~= 0.0 then
		local wrong = (bit32.btest(input.flags_2472, 0x0800_0000) and input.balance < 0.0)
			or (bit32.btest(input.flags_2472, 0x0400_0000) and input.balance > 0.0)
		local turn = if wrong then f32(input.manual_turn * settings.manual_wrong_wheel_scalar) else input.manual_turn
		local target = f32(PointGraph.evaluate(settings.manual_response, input.manual_curve_input) * from_bits(0x3C8E_FA35))
		previous.value = mul_add(f32(1.0 - settings.manual_damping), previous.value, f32(target * settings.manual_damping))
		local scalar = f32(f32(input.timestep * previous.value) * turn)
		return map(input.normal, scalar)
	end
	previous.value = 0.0
	local matrix = input.transform
	local rows = {}
	for i = 1, 3 do
		rows[i] = { matrix[1][i], matrix[2][i], matrix[3][i], 0.0 }
	end
	local cosine = clamp(rows[2][2], -1.0, 1.0)
	local angle = f32(trigonometry.acos(cosine) * from_bits(0x3F22_F983))
	if angle > f32(1.2) then
		angle = 0.0
	end
	local downhill = {}
	for i = 1, 4 do
		local v = f32(rows[1][i] * 0.0)
		v = mul_add(rows[2][i], -1.0, v)
		downhill[i] = mul_add(rows[3][i], 0.0, v)
	end
	downhill[2] = 0.0
	local squared = dot3(downhill, downhill)
	local inverse = estimate(squared)
	for _ = 1, 2 do
		local correction = mul_add(-squared, f32(inverse * inverse), 1.0)
		inverse = mul_add(f32(inverse * 0.5), correction, inverse)
	end
	local length = if squared == 0.0 then 0.0 else f32(squared * inverse)
	local inclination = PointGraph.evaluate(settings.inclination_response, angle)
	for i = 1, 4 do
		local d = if length > settings.normal_threshold[i] then f32(downhill[i] * inverse) else 0.0
		downhill[i] = f32(d * inclination)
	end
	local velocity = {}
	for i = 1, 4 do
		local v = f32(rows[1][i] * input.velocity[1])
		v = mul_add(rows[2][i], input.velocity[2], v)
		velocity[i] = mul_add(rows[3][i], input.velocity[3], v)
	end
	velocity[2] = 0.0
	-- Native cyclic permutations select the Y component of velocity x downhill.
	local cross_y = mul_add(-velocity[1], downhill[3], f32(velocity[3] * downhill[1]))
	local speed = clamp(math.abs(input.signed_speed), 0.0, settings.speed_max)
	local heading_value = f32(f32(cross_y * settings.heading_strength) * PointGraph.evaluate(settings.speed_response, f32(speed / settings.speed_max)))
	local opposing = f32(dot3(input.angular_velocity, input.normal) * -input.turn_2712)
	opposing = if opposing >= 0.0 then opposing else 0.0
	local turn = f32(f32(f32(PointGraph.evaluate(settings.angular_response, opposing) * input.scalar_2740) * settings.turn_strength) * input.turn_2712)
	local scalar = if not (f32(heading_value * turn) < 0.0) and not (math.abs(turn) > math.abs(heading_value)) then heading_value else turn
	return map(input.normal, scalar)
end

return heading
