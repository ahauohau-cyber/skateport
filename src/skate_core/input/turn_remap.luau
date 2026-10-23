--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/input/turn_remap.rs (коммит 2e16697)
--
-- Complete TU3 SetTurning vector remap, 82BB4248.
-- Curves and offsets are supplied from the native animation_turning layout.

local rt = require("../../rt")
local point_graph = require("../point_graph")
local trigonometry = require("../trigonometry")
local angle_mod = require("./angle")
local controller = require("./controller")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local to_bits = rt.to_bits
local evaluate = point_graph.PointGraph.evaluate

local turn_remap = {}

-- ROBLOX: PointGraph<16> -> PointGraph (длина массивов 16).
export type TurnRemap = { magnitude: point_graph.PointGraph, angle: point_graph.PointGraph, angle_offset: number }

local function clamp(value: number): number
	local lower = if f32(-1.0 - value) >= 0.0 then -1.0 else value
	return if f32(1.0 - lower) >= 0.0 then lower else 1.0
end

local function angle(x: number, y: number, magnitude: number): number
	if not (magnitude > from_bits(0x37800000)) then
		return 0.0
	end
	local reciprocal = angle_mod.reciprocal_estimate(x)
	reciprocal = mul_add(reciprocal, mul_add(-reciprocal, x, 1.0), reciprocal)
	local basic = angle_mod.atan(mul_add(y, reciprocal, 0.0))
	local sign = bit32.band(to_bits(y), 0x80000000)
	local result = if x < 0.0 then f32(from_bits(bit32.bor(0x40490fdb, sign)) + basic) else basic
	if x == 0.0 then
		return from_bits(bit32.bor(0x3fc90fdb, sign))
	end
	return result
end

local COS_COEFFICIENTS = {
	from_bits(0x3d2aaaab),
	from_bits(0xbab60b61),
	from_bits(0x37d00d01),
	from_bits(0xb493f27e),
	from_bits(0x310f76c8),
	from_bits(0xad49cba5),
	from_bits(0x29573f9f),
	from_bits(0xa53413c3),
	from_bits(0x20f2a15d),
	from_bits(0x9c8671cb),
}

-- Scalar lane of standalone cosine 82473930; its power tree differs from SinCos.
local function cosine(a: number): number
	local turns = rt.round_ties_even(f32(a * from_bits(0x3e22f983)))
	local x = mul_add(-from_bits(0x40c90fdb), turns, a)
	local x2 = f32(x * x)
	local x4 = f32(x2 * x2)
	local x6 = f32(x4 * x2)
	local x8 = f32(x4 * x4)
	local x10 = f32(x6 * x4)
	local x12 = f32(x6 * x6)
	local x14 = f32(x8 * x6)
	local x16 = f32(x8 * x8)
	local x18 = f32(x10 * x8)
	local x22 = f32(x12 * x10)
	local x20 = f32(x10 * x10)
	local value = mul_add(-0.5, x2, 1.0)
	local powers = { x4, x6, x8, x10, x12, x14, x16, x18, x20, x22 }
	for i = 1, 10 do
		value = mul_add(COS_COEFFICIENTS[i], powers[i], value)
	end
	return value
end
turn_remap.cosine = cosine

local PI = from_bits(0x40490fdb)

local TurnRemap = {}
turn_remap.TurnRemap = TurnRemap

-- ROBLOX: [f32; 2] -> { x, y }, результат [f32; 4] -> таблица из 4 чисел.
function TurnRemap.apply(self: TurnRemap, input: { number }): { number }
	local magnitude = controller.magnitude(f32(f32(input[1] * input[1]) + f32(input[2] * input[2])))
	local first_angle = angle(input[1], input[2], magnitude)
	local graph_input = if first_angle >= 0.0 then first_angle else f32(first_angle + PI)
	local scaled = f32(magnitude * evaluate(self.magnitude, graph_input))
	local x = clamp(f32(cosine(first_angle) * scaled))
	local y = clamp(f32(trigonometry.sin(first_angle) * scaled))
	magnitude = controller.magnitude(f32(f32(x * x) + f32(y * y)))
	local second_angle = angle(x, y, magnitude)
	graph_input = if second_angle >= 0.0 then second_angle else f32(second_angle + PI)
	local mapped = evaluate(self.angle, graph_input)
	mapped = if second_angle >= 0.0 then mapped else f32(mapped + PI)
	local result_angle = f32(self.angle_offset + mapped)
	return {
		clamp(f32(cosine(result_angle) * magnitude)),
		clamp(f32(trigonometry.sin(result_angle) * magnitude)),
		0.0,
		0.0,
	}
end

return turn_remap
