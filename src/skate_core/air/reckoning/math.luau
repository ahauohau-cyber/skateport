--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/air/reckoning/math.rs (коммит 2e16697)
--
-- Original TU3 angle limiter82BD3E78 and Air heading rotation82D8DFD4.
-- Basic arithmetic runs on the host; this is not bit-exact Xenon emulation.
-- ROBLOX: V = [f32; 4] -> таблица из 4 чисел.

local rt = require("../../../rt")
local board_ground = require("../../physics/board_ground")
local board_motion_output = require("../../physics/board_motion_output")
local native_arithmetic = require("../../physics/native_arithmetic")
local trigonometry = require("../../trigonometry")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local dot3 = native_arithmetic.dot3
local inverse_length_squared = board_motion_output.inverse_length_squared

type V = { number }

local math_ = {}

local EPSILON = from_bits(0x3586_37bd)
local TAU = from_bits(0x40c9_0fdb)
local INV_TAU = from_bits(0x3e22_f983)

local function map(v: V, s: number): V
	return { f32(v[1] * s), f32(v[2] * s), f32(v[3] * s), f32(v[4] * s) }
end

function math_.angle(a: V, b: V): number
	return board_ground.angle_between(vector.create(a[1], a[2], a[3]), vector.create(b[1], b[2], b[3]))
end
function math_.wrap(angle: number): number
	local turns = f32(angle * INV_TAU)
	local fraction = f32(turns - math.floor(turns))
	return f32(f32(fraction - (if fraction > 0.5 then 1.0 else 0.0)) * TAU)
end
function math_.length(v: V): number
	local sq = dot3(v, v)
	local inverse = inverse_length_squared(sq, 2)
	if sq == 0.0 then
		return 0.0
	end
	return f32(sq * inverse)
end
function math_.normalize(v: V): V
	return map(v, inverse_length_squared(dot3(v, v), 2))
end
function math_.normalize_safe(v: V, fallback: V): V
	local sq = dot3(v, v)
	local inverse = inverse_length_squared(sq, 2)
	local magnitude = if sq == 0.0 then 0.0 else f32(sq * inverse)
	if magnitude > EPSILON then
		return map(v, inverse)
	end
	return fallback
end
local function cross(a: V, b: V): V
	return {
		mul_add(-a[3], b[2], f32(a[2] * b[3])),
		mul_add(-a[1], b[3], f32(a[3] * b[1])),
		mul_add(-a[2], b[1], f32(a[1] * b[2])),
		mul_add(-a[4], b[4], f32(a[4] * b[4])),
	}
end

-- 82BD3E78. Retains the source's original (not normalized) endpoint operands
-- and final target magnitude. The parallel-axis branch returns target as-is.
function math_.limit_angle(target: V, from: V, maximum: number): V
	local zero = { 0.0, 0.0, 0.0, 0.0 }
	local normalized_from = math_.normalize_safe(from, zero)
	local normalized_target = math_.normalize_safe(target, zero)
	local axis = cross(normalized_target, normalized_from)
	local cosine = native_arithmetic.vector_min(native_arithmetic.vector_max(dot3(normalized_target, normalized_from), -1.0), 1.0)
	local angle = trigonometry.acos(cosine)
	-- The limiter uses floor(angle/tau + .5), unlike its caller's fraction wrap.
	local turns = math.floor(mul_add(angle, INV_TAU, 0.5))
	local closest_angle = mul_add(-turns, TAU, angle)
	if math.abs(closest_angle) < maximum or dot3(axis, axis) < from_bits(0x3780_0000) then
		return target
	end
	local unit_axis = math_.normalize(axis)
	local sin, cos = trigonometry.sin_cos(f32(-maximum * 0.5))
	local q = map(unit_axis, sin)
	local first = cross(q, from)
	local intermediate = {}
	for i = 1, 4 do
		intermediate[i] = mul_add(cos, from[i], first[i])
	end
	local second = cross(q, intermediate)
	local rotated = {}
	for i = 1, 4 do
		rotated[i] = mul_add(second[i], 2.0, from[i])
	end
	return map(rotated, math_.length(target))
end

-- 82D8DFD4..E0B0: Rodrigues columns followed by X/Y/Z ordered FMAs.
-- The native permutation repeats each column's X into its W lane.
function math_.rotate_heading(heading: V, up: V, angle: number): V
	local x, y, z = up[1], up[2], up[3]
	local s, c = trigonometry.sin_cos(angle)
	local t = f32(1.0 - c)
	local tx, ty, tz = f32(t * x), f32(t * y), f32(t * z)
	local sx, sy, sz = f32(s * x), f32(s * y), f32(s * z)
	local xx = mul_add(tx, x, c)
	local yx = f32(f32(ty * x) - sz)
	local zx = mul_add(tz, x, sy)
	local columns = {
		{ xx, mul_add(tx, y, sz), f32(f32(tx * z) - sy), xx },
		{ yx, mul_add(ty, y, c), mul_add(ty, z, sx), yx },
		{ zx, f32(f32(tz * y) - sx), mul_add(tz, z, c), zx },
	}
	local out = {}
	for i = 1, 4 do
		local first = f32(columns[1][i] * heading[1])
		local second = mul_add(columns[2][i], heading[2], first)
		out[i] = mul_add(columns[3][i], heading[3], second)
	end
	return out
end

return math_
