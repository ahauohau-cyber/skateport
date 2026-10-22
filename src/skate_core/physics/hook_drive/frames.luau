--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/hook_drive/frames.rs (коммит 2e16697)
--
-- Full 82C00940/82C00AF0 matrix33 conversion. Unlike Part::SetTransform,
-- these functions do not normalize the selected quaternion afterward.

local rt = require("../../../rt")
local reciprocal_sqrt = require("../reciprocal_sqrt")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local to_bits = rt.to_bits

type V = { number }

local frames = {}

local function add(a: V, b: V): V
	return { f32(a[1] + b[1]), f32(a[2] + b[2]), f32(a[3] + b[3]), f32(a[4] + b[4]) }
end
local function sub(a: V, b: V): V
	return { f32(a[1] - b[1]), f32(a[2] - b[2]), f32(a[3] - b[3]), f32(a[4] - b[4]) }
end
local function mul(a: V, b: V): V
	return { f32(a[1] * b[1]), f32(a[2] * b[2]), f32(a[3] * b[3]), f32(a[4] * b[4]) }
end

-- pub(super) fn rsqrt(v: f32) -> f32
function frames.rsqrt(v: number): number
	local e = reciprocal_sqrt.estimate(v)
	for _ = 1, 2 do
		local s = f32(e * e)
		local h = f32(e * 0.5)
		e = mul_add(h, mul_add(-v, s, 1.0), e)
	end
	return e
end
local rsqrt = frames.rsqrt

local function quaternion(m: { V }): V
	local ri, up, at = m[1], m[2], m[3]
	-- Sign masks are initialized by TU3 82F83360/90/C0, not image defaults.
	local rx = { ri[1], ri[1], -ri[1], -ri[1] }
	local uy = { up[2], -up[2], up[2], -up[2] }
	local az = { at[3], -at[3], -at[3], at[3] }
	local first = add(rx, uy)
	local d = add(first, add(az, { 1.0, 1.0, 1.0, 1.0 }))
	local inv = { rsqrt(d[1]), rsqrt(d[2]), rsqrt(d[3]), rsqrt(d[4]) }
	local roots = mul(d, inv)
	local halves = mul({ 0.5, 0.5, 0.5, 0.5 }, inv)
	local a = { up[3], at[1], ri[2], 0.5 }
	local b = { at[2], ri[3], up[1], 0.0 }
	local minus = sub(a, b)
	local plus = add(a, b)
	local y = mul({ plus[3], minus[4], plus[1], minus[2] }, { halves[3], roots[3], halves[3], halves[3] })
	local z = mul({ plus[2], plus[1], minus[4], minus[3] }, { halves[4], halves[4], roots[4], halves[4] })
	local x = mul({ minus[4], plus[3], plus[2], minus[1] }, { roots[2], halves[2], halves[2], halves[2] })
	local w = mul(minus, { halves[1], halves[1], halves[1], roots[1] })
	local yz = if up[2] > at[3] then y else z
	local xyz = if ri[1] > up[2] and ri[1] > at[3] then x else yz
	if f32(first[1] + at[3]) > 0.0 then
		return w
	end
	return xyz
end

local function convert(basis: { number }): { number }
	local m = {}
	for i = 0, 2 do
		m[i + 1] = {}
		for j = 0, 3 do
			m[i + 1][j + 1] = from_bits(basis[i * 4 + j + 1])
		end
	end
	local q = quaternion(m)
	return { to_bits(q[1]), to_bits(q[2]), to_bits(q[3]), to_bits(q[4]) }
end

-- 82C00940 preserves both translations and the parent quaternion.
-- ROBLOX: `&mut [u32; 16]` — таблица меняется на месте.
function frames.set_child_angular_frame(f: { number }, basis: { number })
	rt.copy_into(f, 0, convert(basis))
end

-- 82C00AF0 preserves both translations and the child quaternion.
function frames.set_parent_angular_frame(f: { number }, basis: { number })
	rt.copy_into(f, 8, convert(basis))
end

return frames
