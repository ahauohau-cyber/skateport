--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/riding/vector.rs (коммит 2e16697)
--
-- Общие векторные помощники модулей riding (в Rust — pub(super)).
-- ROBLOX: [f32; 4] -> таблица из 4 чисел, индексы с 1.

local rt = require("../../rt")
local native_arithmetic = require("../physics/native_arithmetic")
local reciprocal_sqrt = require("../physics/reciprocal_sqrt")

local f32 = rt.f32
local mul_add = rt.mul_add
local estimate = reciprocal_sqrt.estimate

type F4 = { number }

local vector_mod = {}

function vector_mod.dot3(a: F4, b: F4): number
	return native_arithmetic.dot3(a, b)
end
local dot3 = vector_mod.dot3

-- Inline NormalizeSafe sequence in TU3 82C04F68 / 82D92CF8.
function vector_mod.normalize(v: F4, threshold: F4): F4
	local squared = dot3(v, v)
	local inverse = estimate(squared)
	for _ = 1, 2 do
		local correction = mul_add(-squared, f32(inverse * inverse), 1.0)
		inverse = mul_add(f32(inverse * 0.5), correction, inverse)
	end
	local length = if squared == 0.0 then 0.0 else f32(squared * inverse)
	local out = {}
	for i = 1, 4 do
		out[i] = if length > threshold[i] then f32(v[i] * inverse) else 0.0
	end
	return out
end

function vector_mod.clamp(value: number, lower: number, upper: number): number
	local v = if f32(lower - value) >= 0.0 then lower else value
	return if f32(upper - v) >= 0.0 then v else upper
end

function vector_mod.cross(a: F4, b: F4): F4
	local out = {}
	for i0 = 0, 3 do
		local j = if i0 == 3 then 3 else (i0 + 1) % 3
		local k = if i0 == 3 then 3 else (i0 + 2) % 3
		out[i0 + 1] = mul_add(-a[k + 1], b[j + 1], f32(a[j + 1] * b[k + 1]))
	end
	return out
end

return vector_mod
