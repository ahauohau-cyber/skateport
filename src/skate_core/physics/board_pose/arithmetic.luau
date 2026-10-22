--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/board_pose/arithmetic.rs (коммит 2e16697)
--
-- Arithmetic order from the retained TU3 pose functions; guest lane order.
-- ROBLOX: V = [f32; 4] -> таблица из 4 чисел; M = [V; 4] -> таблица из 4 таких.

local rt = require("../../../rt")
local native_arithmetic = require("../native_arithmetic")
local reciprocal_sqrt = require("../reciprocal_sqrt")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local to_bits = rt.to_bits

export type V = { number }
export type M = { V }

local arithmetic = {}

function arithmetic.splat(x: number): V
	return { x, x, x, x }
end

function arithmetic.matrix(w: { number }): M
	local m = {}
	for i = 0, 3 do
		m[i + 1] = { from_bits(w[i * 4 + 1]), from_bits(w[i * 4 + 2]), from_bits(w[i * 4 + 3]), from_bits(w[i * 4 + 4]) }
	end
	return m
end

function arithmetic.words(m: M): { number }
	local w = table.create(16) :: { number }
	for i = 0, 15 do
		w[i + 1] = to_bits(m[i // 4 + 1][i % 4 + 1])
	end
	return w
end

function arithmetic.add(a: V, b: V): V
	return { f32(a[1] + b[1]), f32(a[2] + b[2]), f32(a[3] + b[3]), f32(a[4] + b[4]) }
end
function arithmetic.sub(a: V, b: V): V
	return { f32(a[1] - b[1]), f32(a[2] - b[2]), f32(a[3] - b[3]), f32(a[4] - b[4]) }
end
function arithmetic.mul(a: V, b: V): V
	return { f32(a[1] * b[1]), f32(a[2] * b[2]), f32(a[3] * b[3]), f32(a[4] * b[4]) }
end
function arithmetic.madd(a: V, b: V, c: V): V
	return { mul_add(a[1], b[1], c[1]), mul_add(a[2], b[2], c[2]), mul_add(a[3], b[3], c[3]), mul_add(a[4], b[4], c[4]) }
end
function arithmetic.nmsub(a: V, b: V, c: V): V
	return {
		mul_add(-a[1], b[1], c[1]),
		mul_add(-a[2], b[2], c[2]),
		mul_add(-a[3], b[3], c[3]),
		mul_add(-a[4], b[4], c[4]),
	}
end
-- ROBLOX: индексы перестановки — как в Rust (с нуля).
function arithmetic.perm(a: V, p: { number }): V
	return { a[p[1] + 1], a[p[2] + 1], a[p[3] + 1], a[p[4] + 1] }
end
function arithmetic.dot(a: V, b: V, four: boolean): number
	if four then
		return native_arithmetic.dot4(a, b)
	end
	return native_arithmetic.dot3(a, b)
end
function arithmetic.rsqrt(v: number): number
	local e = reciprocal_sqrt.estimate(v)
	for _ = 1, 2 do
		local s = f32(e * e)
		local h = f32(e * 0.5)
		e = mul_add(h, mul_add(-v, s, 1.0), e)
	end
	return e
end
function arithmetic.normalize(v: V, four: boolean): V
	return arithmetic.mul(v, arithmetic.splat(arithmetic.rsqrt(arithmetic.dot(v, v, four))))
end
function arithmetic.cross(a: V, b: V): V
	local P = { 1, 2, 0, 3 }
	return arithmetic.perm(arithmetic.nmsub(arithmetic.perm(a, P), b, arithmetic.mul(a, arithmetic.perm(b, P))), P)
end
function arithmetic.compose(a: M, b: M): M
	local splat, madd, mul = arithmetic.splat, arithmetic.madd, arithmetic.mul
	local out = {}
	for i = 1, 4 do
		local first = if i == 4 then madd(splat(b[i][1]), a[1], a[4]) else mul(splat(b[i][1]), a[1])
		out[i] = madd(splat(b[i][3]), a[3], madd(splat(b[i][2]), a[2], first))
	end
	return out
end
function arithmetic.inverse_rigid(m: M): M
	local splat, madd, mul = arithmetic.splat, arithmetic.madd, arithmetic.mul
	local out = {}
	for i = 1, 3 do
		out[i] = { m[1][i], m[2][i], m[3][i], 0.0 }
	end
	out[4] = { 0.0, 0.0, 0.0, 0.0 }
	local neg = arithmetic.sub({ 0.0, 0.0, 0.0, 0.0 }, m[4])
	out[4] = madd(splat(neg[1]), out[1], madd(splat(neg[2]), out[2], mul(splat(neg[3]), out[3])))
	return out
end

return arithmetic
