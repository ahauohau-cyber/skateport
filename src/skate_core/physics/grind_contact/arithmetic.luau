--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/grind_contact/arithmetic.rs (коммит 2e16697)
--
-- Refinement sequence used by S3 82D861D8/82D88518/82D886B8.
-- Seeds use existing independent PC math, not a Xenon bit-exact claim.

local rt = require("../../../rt")
local native_arithmetic = require("../native_arithmetic")

local f32 = rt.f32
local mul_add = rt.mul_add

local arithmetic = {}

function arithmetic.reciprocal(value: number): number
	local result = native_arithmetic.reciprocal_estimate(value)
	for _ = 1, 2 do
		local err = mul_add(-result, value, 1.0)
		result = mul_add(result, err, result)
	end
	return result
end

function arithmetic.inverse_square_root(value: number): number
	local result = native_arithmetic.reciprocal_square_root_estimate(value)
	for _ = 1, 2 do
		local square = f32(result * result)
		local half = f32(result * 0.5)
		local err = mul_add(-value, square, 1.0)
		result = mul_add(half, err, result)
	end
	return result
end

function arithmetic.square_root(value: number): number
	local result = f32(value * arithmetic.inverse_square_root(value))
	-- The original vector select explicitly chooses zero for a zero radicand.
	if value == 0.0 then
		return 0.0
	end
	return result
end

return arithmetic
