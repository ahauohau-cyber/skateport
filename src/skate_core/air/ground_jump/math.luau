--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/air/ground_jump/math.rs (коммит 2e16697)
--
-- Original arithmetic ordering and two estimate-refinement steps.

local rt = require("../../../rt")
local board_motion_output = require("../../physics/board_motion_output")
local native_arithmetic = require("../../physics/native_arithmetic")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local inverse_length_squared = board_motion_output.inverse_length_squared

type Vector = { number }

local math_ = {}

function math_.up(): Vector
	return { 0.0, 1.0, 0.0, 0.0 }
end
function math_.dot(a: Vector, b: Vector): number
	return native_arithmetic.dot3(a, b)
end
function math_.add(a: Vector, b: Vector): Vector
	return { f32(a[1] + b[1]), f32(a[2] + b[2]), f32(a[3] + b[3]), f32(a[4] + b[4]) }
end
function math_.sub(a: Vector, b: Vector): Vector
	return { f32(a[1] - b[1]), f32(a[2] - b[2]), f32(a[3] - b[3]), f32(a[4] - b[4]) }
end
function math_.scale(a: Vector, b: number): Vector
	return { f32(a[1] * b), f32(a[2] * b), f32(a[3] * b), f32(a[4] * b) }
end
function math_.madd(a: Vector, b: number, c: Vector): Vector
	return { mul_add(a[1], b, c[1]), mul_add(a[2], b, c[2]), mul_add(a[3], b, c[3]), mul_add(a[4], b, c[4]) }
end
function math_.planar(value: Vector, normal: Vector): Vector
	return math_.sub(value, math_.scale(normal, math_.dot(value, normal)))
end
function math_.maximum(a: number, b: number): number
	if f32(a - b) >= -0.0 then
		return a
	end
	return b
end
function math_.clamp(v: number, low: number, high: number): number
	local lower = if f32(low - v) >= -0.0 then low else v
	if f32(high - lower) >= -0.0 then
		return lower
	end
	return high
end
function math_.vector_clamp(v: number, low: number, high: number): number
	return native_arithmetic.vector_min(high, native_arithmetic.vector_max(low, v))
end
function math_.reciprocal(v: number): number
	local r = native_arithmetic.reciprocal_estimate(v)
	for _ = 1, 2 do
		r = mul_add(r, mul_add(-r, v, 1.0), r)
	end
	return r
end
function math_.square_root(square: number): number
	local value = f32(square * inverse_length_squared(square, 2))
	if square == 0.0 then
		return 0.0
	end
	return value
end
function math_.length(value: Vector): number
	return math_.square_root(math_.dot(value, value))
end
function math_.normalize(value: Vector): Vector
	local square = math_.dot(value, value)
	local inverse = inverse_length_squared(square, 2)
	local length = if square == 0.0 then 0.0 else f32(square * inverse)
	-- 82F826F8 initializes830BD350 from82181A88 (1e-6), not its IDA BSS zero.
	if length > from_bits(0x3586_37bd) then
		return math_.scale(value, inverse)
	end
	return { 0.0, 0.0, 0.0, 0.0 }
end
function math_.cross(a: Vector, b: Vector): Vector
	return {
		mul_add(-a[3], b[2], f32(a[2] * b[3])),
		mul_add(-a[1], b[3], f32(a[3] * b[1])),
		mul_add(-a[2], b[1], f32(a[1] * b[2])),
		0.0,
	}
end

return math_
