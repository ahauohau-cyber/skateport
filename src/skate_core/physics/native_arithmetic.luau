--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/native_arithmetic.rs (коммит 2e16697)
--
-- Independent host math for the operations used by recovered TU3 callers.
--
-- Uses Rust floating-point operations without external estimate tables or
-- translator-specific special cases. Callers retain their recovered refinement
-- steps. This is working PC math, not bit-exact Xenon instruction emulation.

local rt = require("../../rt")

local native_arithmetic = {}

local f32 = rt.f32

-- pub(crate) fn reciprocal_estimate(value: f32) -> f32
function native_arithmetic.reciprocal_estimate(value: number): number
	-- ROBLOX: value.recip() -> f32(1 / value).
	return f32(1 / value)
end

-- pub(crate) fn reciprocal_square_root_estimate(value: f32) -> f32
function native_arithmetic.reciprocal_square_root_estimate(value: number): number
	-- ROBLOX: value.sqrt().recip() -> два округления, как в Rust.
	return f32(1 / f32(math.sqrt(value)))
end

-- pub(crate) fn dot3(left: [f32; 4], right: [f32; 4]) -> f32
-- ROBLOX: массивы [f32; 4] -> таблицы, индексы с 1.
function native_arithmetic.dot3(left: { number }, right: { number }): number
	return f32(f32(f32(left[1] * right[1]) + f32(left[2] * right[2])) + f32(left[3] * right[3]))
end

-- pub(crate) fn dot4(left: [f32; 4], right: [f32; 4]) -> f32
function native_arithmetic.dot4(left: { number }, right: { number }): number
	return f32(native_arithmetic.dot3(left, right) + f32(left[4] * right[4]))
end

-- pub(crate) fn vector_min(left: f32, right: f32) -> f32
function native_arithmetic.vector_min(left: number, right: number): number
	-- ROBLOX: left.min(right) -> rt.fmin (правила Rust для NaN).
	return rt.fmin(left, right)
end

-- pub(crate) fn vector_max(left: f32, right: f32) -> f32
function native_arithmetic.vector_max(left: number, right: number): number
	-- ROBLOX: left.max(right) -> rt.fmax (правила Rust для NaN).
	return rt.fmax(left, right)
end

return native_arithmetic
