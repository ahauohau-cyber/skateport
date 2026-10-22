--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/collision/arithmetic.rs (коммит 2e16697)
--
-- ROBLOX: V::new(x, y, z) -> vector.create(x, y, z). vector хранит f32,
-- поэтому последняя операция в каждой компоненте округляется самим vector;
-- промежуточные операции округляем явно через f32(...).

local rt = require("../../../rt")
local native_arithmetic = require("../native_arithmetic")
local reciprocal_sqrt = require("../reciprocal_sqrt")

local f32 = rt.f32
local mul_add = rt.mul_add
local estimate = reciprocal_sqrt.estimate
local dot3 = native_arithmetic.dot3

local arithmetic = {}

-- pub(super) fn dot(a: V, b: V) -> f32
function arithmetic.dot(a: vector, b: vector): number
	return dot3({ a.x, a.y, a.z, 0.0 }, { b.x, b.y, b.z, 0.0 })
end

-- pub(super) fn cross(a: V, b: V) -> V
function arithmetic.cross(a: vector, b: vector): vector
	return vector.create(
		mul_add(-a.z, b.y, f32(a.y * b.z)),
		mul_add(-a.x, b.z, f32(a.z * b.x)),
		mul_add(-a.y, b.x, f32(a.x * b.y))
	)
end

-- pub(super) fn scale(a: V, b: f32) -> V
function arithmetic.scale(a: vector, b: number): vector
	return vector.create(a.x * b, a.y * b, a.z * b)
end

-- pub(super) fn neg(a: V) -> V
function arithmetic.neg(a: vector): vector
	return vector.create(-a.x, -a.y, -a.z)
end

-- pub(super) fn sub(a: V, b: V) -> V
function arithmetic.sub(a: vector, b: vector): vector
	return vector.create(a.x - b.x, a.y - b.y, a.z - b.z)
end

-- pub(super) fn madd(a: V, b: f32, c: V) -> V
function arithmetic.madd(a: vector, b: number, c: vector): vector
	return vector.create(mul_add(a.x, b, c.x), mul_add(a.y, b, c.y), mul_add(a.z, b, c.z))
end

-- pub(super) fn inverse_length_squared(value: f32, refinements: u32) -> f32
function arithmetic.inverse_length_squared(value: number, refinements: number): number
	local r = estimate(value)
	for _ = 1, refinements do
		r = mul_add(f32(r * 0.5), mul_add(-value, f32(r * r), 1.0), r)
	end
	return r
end

-- pub(super) fn normalize(a: V, refinements: u32) -> V
function arithmetic.normalize(a: vector, refinements: number): vector
	return arithmetic.scale(a, arithmetic.inverse_length_squared(arithmetic.dot(a, a), refinements))
end

return arithmetic
