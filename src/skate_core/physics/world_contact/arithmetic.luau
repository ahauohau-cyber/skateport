--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/world_contact/arithmetic.rs (коммит 2e16697)
--
-- ROBLOX: V = [f32; 3] -> таблица из трёх чисел (индексы 1..3).
-- Записи [u32] — таблицы слов; слово k в Rust лежит в [k + 1].

local rt = require("../../../rt")
local native_arithmetic = require("../native_arithmetic")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits

local arithmetic = {}

export type V = { number }

-- pub(super) fn vector(record: &[u32], offset: usize) -> V
function arithmetic.vector(record: { number }, offset: number): V
	return { from_bits(record[offset + 1]), from_bits(record[offset + 2]), from_bits(record[offset + 3]) }
end

-- pub(super) fn sub(a: V, b: V) -> V
function arithmetic.sub(a: V, b: V): V
	return { f32(a[1] - b[1]), f32(a[2] - b[2]), f32(a[3] - b[3]) }
end

-- pub(super) fn dot(a: V, b: V) -> f32
function arithmetic.dot(a: V, b: V): number
	return native_arithmetic.dot3({ a[1], a[2], a[3], 0.0 }, { b[1], b[2], b[3], 0.0 })
end

-- pub(super) fn cross(a: V, b: V) -> V
function arithmetic.cross(a: V, b: V): V
	return {
		mul_add(-a[3], b[2], f32(a[2] * b[3])),
		mul_add(-a[1], b[3], f32(a[3] * b[1])),
		mul_add(-a[2], b[1], f32(a[1] * b[2])),
	}
end

-- pub(super) fn scale(a: V, b: f32) -> V
function arithmetic.scale(a: V, b: number): V
	return { f32(a[1] * b), f32(a[2] * b), f32(a[3] * b) }
end

return arithmetic
