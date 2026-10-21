--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/world_contact/prism_math.rs (коммит 2e16697)
--
-- ROBLOX: V = [f32; 4] -> таблица из четырёх чисел (индексы 1..4).

local rt = require("../../../rt")
local reciprocal_sqrt = require("../reciprocal_sqrt")
local native_arithmetic = require("../native_arithmetic")
local arithmetic = require("./arithmetic")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local estimate = reciprocal_sqrt.estimate

local prism_math = {}

export type V = { number }

-- pub(super) fn load(words: &[u32], offset: usize) -> V
function prism_math.load(words: { number }, offset: number): V
	return {
		from_bits(words[offset + 1]),
		from_bits(words[offset + 2]),
		from_bits(words[offset + 3]),
		from_bits(words[offset + 4]),
	}
end

-- ROBLOX: `v.map(f32::to_bits)` для четырёх полос.
function prism_math.bits(v: V): { number }
	return { rt.to_bits(v[1]), rt.to_bits(v[2]), rt.to_bits(v[3]), rt.to_bits(v[4]) }
end

-- pub(super) fn dot(a: V, b: V) -> f32
function prism_math.dot(a: V, b: V): number
	return arithmetic.dot({ a[1], a[2], a[3] }, { b[1], b[2], b[3] })
end

-- pub(super) fn sub(a: V, b: V) -> V
function prism_math.sub(a: V, b: V): V
	return { f32(a[1] - b[1]), f32(a[2] - b[2]), f32(a[3] - b[3]), f32(a[4] - b[4]) }
end

-- pub(super) fn scale(a: V, s: f32) -> V
function prism_math.scale(a: V, s: number): V
	return { f32(a[1] * s), f32(a[2] * s), f32(a[3] * s), f32(a[4] * s) }
end

-- pub(super) fn madd(a: V, s: f32, b: V) -> V
function prism_math.madd(a: V, s: number, b: V): V
	return { mul_add(a[1], s, b[1]), mul_add(a[2], s, b[2]), mul_add(a[3], s, b[3]), mul_add(a[4], s, b[4]) }
end

-- pub(super) fn cross(a: V, b: V) -> V
function prism_math.cross(a: V, b: V): V
	return {
		mul_add(-a[3], b[2], f32(a[2] * b[3])),
		mul_add(-a[1], b[3], f32(a[3] * b[1])),
		mul_add(-a[2], b[1], f32(a[1] * b[2])),
		mul_add(-a[4], b[4], f32(a[4] * b[4])),
	}
end

-- pub(super) fn inverse_length(squared: f32) -> f32
function prism_math.inverse_length(squared: number): number
	local r = estimate(squared)
	for _ = 1, 2 do
		r = mul_add(f32(r * 0.5), mul_add(-squared, f32(r * r), 1.0), r)
	end
	return r
end

-- pub(super) fn normalized(a: V) -> V
function prism_math.normalized(a: V): V
	local squared = prism_math.dot(a, a)
	return prism_math.scale(a, prism_math.inverse_length(squared))
end

-- pub(super) fn reciprocal_estimate(value: f32) -> f32
function prism_math.reciprocal_estimate(value: number): number
	return native_arithmetic.reciprocal_estimate(value)
end

-- pub(super) fn reciprocal(value: f32) -> f32
function prism_math.reciprocal(value: number): number
	local r = prism_math.reciprocal_estimate(value)
	for _ = 1, 2 do
		r = mul_add(r, mul_add(-r, value, 1.0), r)
	end
	return r
end

return prism_math
