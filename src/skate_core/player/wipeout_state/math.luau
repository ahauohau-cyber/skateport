--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/wipeout_state/math.rs (коммит 2e16697)
--
-- Scalar/vector expressions recovered from original Wipeout control kernels.

local rt = require("../../../rt")
local board_motion_output = require("../../physics/board_motion_output")
local native_arithmetic = require("../../physics/native_arithmetic")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local inverse_length_squared = board_motion_output.inverse_length_squared

export type V = { number }

local math_ = {}

function math_.add(a: V, b: V): V
	return { f32(a[1] + b[1]), f32(a[2] + b[2]), f32(a[3] + b[3]), f32(a[4] + b[4]) }
end

function math_.sub(a: V, b: V): V
	return { f32(a[1] - b[1]), f32(a[2] - b[2]), f32(a[3] - b[3]), f32(a[4] - b[4]) }
end

function math_.scale(a: V, b: number): V
	return { f32(a[1] * b), f32(a[2] * b), f32(a[3] * b), f32(a[4] * b) }
end
local scale = math_.scale

function math_.madd(a: V, b: number, c: V): V
	return { mul_add(a[1], b, c[1]), mul_add(a[2], b, c[2]), mul_add(a[3], b, c[3]), mul_add(a[4], b, c[4]) }
end

function math_.dot(a: V, b: V): number
	return native_arithmetic.dot3(a, b)
end
local dot = math_.dot

function math_.cross(a: V, b: V): V
	return {
		mul_add(-a[3], b[2], f32(a[2] * b[3])),
		mul_add(-a[1], b[3], f32(a[3] * b[1])),
		mul_add(-a[2], b[1], f32(a[1] * b[2])),
		mul_add(-a[4], b[4], f32(a[4] * b[4])),
	}
end

function math_.length(a: V): number
	local square = dot(a, a)
	return if square == 0.0 then 0.0 else f32(square * inverse_length_squared(square, 2))
end
local length = math_.length

function math_.normalize(a: V): V
	return scale(a, inverse_length_squared(dot(a, a), 2))
end
local normalize = math_.normalize

-- ///Original830BD350 is initialized to splatted358637BD, not a fitted tolerance.
function math_.normalize_or(a: V, fallback: V): V
	if length(a) > from_bits(0x3586_37BD) then
		return normalize(a)
	end
	return fallback
end

function math_.reciprocal(v: number): number
	local inv = native_arithmetic.reciprocal_estimate(v)
	for _ = 1, 2 do
		inv = mul_add(inv, mul_add(-inv, v, 1.0), inv)
	end
	return inv
end
local reciprocal = math_.reciprocal

function math_.clamp(v_in: number, low: number, high: number): number
	local v = if f32(low - v_in) >= 0.0 then low else v_in
	return if f32(high - v) >= 0.0 then v else high
end

-- ///Original82BD3D90: short vectors retain all four lanes.
function math_.limit_length(v: V, maximum: number): V
	local len = length(v)
	if not (len >= from_bits(0x3780_0000)) then
		return v
	end
	local cap = if f32(maximum - len) >= 0.0 then len else maximum
	return scale(scale(v, cap), reciprocal(len))
end

function math_.wrap_angle(angle: number): number
	local turns = f32(angle * from_bits(0x3E22_F983))
	local fraction = f32(turns - math.floor(turns))
	local centered = if fraction > 0.5 then f32(fraction - 1.0) else fraction
	return f32(centered * from_bits(0x40C9_0FDB))
end

return math_
