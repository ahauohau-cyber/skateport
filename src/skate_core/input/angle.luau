--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/input/angle.rs (коммит 2e16697)
--
-- Scalar lane of native SIMD atan 82473B98 and intention left-stick angle.

local rt = require("../../rt")
local native_arithmetic = require("../physics/native_arithmetic")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local to_bits = rt.to_bits

local angle = {}

-- pub(super) fn reciprocal_estimate(value: f32) -> f32
function angle.reciprocal_estimate(value: number): number
	return native_arithmetic.reciprocal_estimate(value)
end
local reciprocal_estimate = angle.reciprocal_estimate

local function refined_reciprocal(value: number): number
	local initial = reciprocal_estimate(value)
	local first = mul_add(initial, mul_add(-value, initial, 1.0), initial)
	local second = mul_add(first, mul_add(-value, first, 1.0), first)
	if first ~= first then
		return initial
	end
	return second
end

local C_TRANSFORM = from_bits(0x3e8930a3)
local OFF_INV_T = from_bits(0x3f860a92)
local OFF_T = from_bits(0x3f060a92)
local HALF_PI = from_bits(0x3fc90fdb)
local HUGE_ = from_bits(0x7e800000)

function angle.atan(value: number): number
	local absolute = math.abs(value)
	local invert = absolute > 1.0
	local reduced = if invert then refined_reciprocal(absolute) else absolute
	local transform = reduced > C_TRANSFORM
	local offset
	if transform then
		offset = if invert then OFF_INV_T else OFF_T
	elseif invert then
		offset = HALF_PI
	else
		offset = 0.0
	end
	local transformed = f32(f32(mul_add(reduced, from_bits(0x3f3b67af), reduced) - 1.0) * refined_reciprocal(f32(reduced + from_bits(0x3fddb3d7))))
	local t = if transform then transformed else reduced
	local square = f32(t * t)
	local numerator = mul_add(square, from_bits(0xbf566bd7), from_bits(0xc107e9fb))
	numerator = mul_add(square, numerator, from_bits(0xc1a40bfe))
	numerator = mul_add(square, numerator, from_bits(0xc15b0533))
	local denominator = mul_add(square, f32(square + from_bits(0x4170624f)), from_bits(0x426e5052))
	denominator = mul_add(square, denominator, from_bits(0x42ac5090))
	denominator = mul_add(square, denominator, from_bits(0x422443e6))
	local polynomial = mul_add(t, f32(f32(numerator * square) * refined_reciprocal(denominator)), t)
	local result = if from_bits(0x39800000) > math.abs(t) then t else polynomial
	result = f32((if invert then -result else result) + offset)
	if value < 0.0 then
		result = -result
	end
	if value > HUGE_ then
		result = HALF_PI
	end
	if -HUGE_ > value then
		return -HALF_PI
	end
	return result
end

-- pub(super) fn left_stick_angle(x: f32, y: f32) -> f32
function angle.left_stick_angle(x: number, y: number): number
	if x == 0.0 and y == 0.0 then
		return 0.0
	end
	local vertical = -y
	local reciprocal = reciprocal_estimate(vertical)
	local refined = mul_add(reciprocal, mul_add(-reciprocal, vertical, 1.0), reciprocal)
	local basic = angle.atan(mul_add(x, refined, 0.0))
	local sign = bit32.band(to_bits(x), 0x80000000)
	local pi = from_bits(bit32.bor(0x40490fdb, sign))
	local half_pi = from_bits(bit32.bor(0x3fc90fdb, sign))
	local result = if 0.0 > vertical then f32(pi + basic) else basic
	if vertical == 0.0 then
		return half_pi
	end
	return result
end

return angle
