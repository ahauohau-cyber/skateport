--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/skeleton_body/collision_vector.rs (коммит 2e16697)
--
-- Original vector arithmetic used by82BD4A30 and82BD5A00.

local rt = require("../../../rt")
local native_arithmetic = require("../native_arithmetic")
local reciprocal_sqrt = require("../reciprocal_sqrt")
local sar = require("../skeleton_animation_record")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local dot3 = native_arithmetic.dot3

-- ROBLOX: V = [f32; 4] -> таблица из 4 чисел.
type V = { number }

local collision_vector = {}

function collision_vector.dot(a: V, b: V): number
	return dot3(a, b)
end
local dot = collision_vector.dot

function collision_vector.scale(v: V, s: number): V
	return { f32(v[1] * s), f32(v[2] * s), f32(v[3] * s), f32(v[4] * s) }
end
local scale = collision_vector.scale

function collision_vector.sub(a: V, b: V): V
	return { f32(a[1] - b[1]), f32(a[2] - b[2]), f32(a[3] - b[3]), f32(a[4] - b[4]) }
end

function collision_vector.add(a: V, b: V): V
	return { f32(a[1] + b[1]), f32(a[2] + b[2]), f32(a[3] + b[3]), f32(a[4] + b[4]) }
end

function collision_vector.inverse_length(square: number): number
	local inverse = reciprocal_sqrt.estimate(square)
	for _ = 1, 2 do
		inverse = mul_add(f32(inverse * 0.5), mul_add(-square, f32(inverse * inverse), 1.0), inverse)
	end
	return inverse
end
local inverse_length = collision_vector.inverse_length

function collision_vector.length(v: V): number
	local square = dot(v, v)
	local result = f32(square * inverse_length(square))
	return if square == 0.0 then 0.0 else result
end
local length = collision_vector.length

function collision_vector.normalize(v: V): V
	local square = dot(v, v)
	local inverse = inverse_length(square)
	local size = if square == 0.0 then 0.0 else f32(square * inverse)
	if size > f32(1.0e-6) then
		return scale(v, inverse)
	end
	return { 0.0, 0.0, 0.0, 0.0 }
end

-- ///82BD3D90 keeps all stored lanes, including the unused fourth velocity lane.
function collision_vector.clamp_length(v: V, maximum: number): V
	local size = length(v)
	if size < from_bits(0x3780_0000) then
		return v
	end
	local bounded = if f32(maximum - size) >= 0.0 then size else maximum
	local inverse = native_arithmetic.reciprocal_estimate(size)
	for _ = 1, 2 do
		inverse = mul_add(inverse, mul_add(-inverse, size, 1.0), inverse)
	end
	return scale(scale(v, bounded), inverse)
end

function collision_vector.transform(m: sar.AnimationPartTransform, v: V): V
	local out = {}
	for i = 1, 4 do
		out[i] = mul_add(m[3][i], v[3], mul_add(m[2][i], v[2], mul_add(m[1][i], v[1], m[4][i])))
	end
	return out
end

function collision_vector.cross(a: V, b: V): V
	return {
		mul_add(-a[3], b[2], f32(a[2] * b[3])),
		mul_add(-a[1], b[3], f32(a[3] * b[1])),
		mul_add(-a[2], b[1], f32(a[1] * b[2])),
		mul_add(-a[4], b[4], f32(a[4] * b[4])),
	}
end

return collision_vector
