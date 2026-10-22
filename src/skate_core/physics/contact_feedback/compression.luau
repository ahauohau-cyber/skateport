--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/contact_feedback/compression.rs (коммит 2e16697)

local rt = require("../../../rt")
local native_arithmetic = require("../native_arithmetic")
local part_mod = require("../board_pose/part")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local to_bits = rt.to_bits

type V = { number }
type M = { V }

local compression = {}

local function matrix(w: { number }): M
	local m = {}
	for i = 0, 3 do
		m[i + 1] = { from_bits(w[i * 4 + 1]), from_bits(w[i * 4 + 2]), from_bits(w[i * 4 + 3]), from_bits(w[i * 4 + 4]) }
	end
	return m
end
local function madd(a: V, s: number, b: V): V
	return { mul_add(a[1], s, b[1]), mul_add(a[2], s, b[2]), mul_add(a[3], s, b[3]), mul_add(a[4], s, b[4]) }
end
local function scale(a: V, s: number): V
	return { f32(a[1] * s), f32(a[2] * s), f32(a[3] * s), f32(a[4] * s) }
end
local function cross(a: V, b: V): V
	return {
		mul_add(-a[3], b[2], f32(a[2] * b[3])),
		mul_add(-a[1], b[3], f32(a[3] * b[1])),
		mul_add(-a[2], b[1], f32(a[1] * b[2])),
		mul_add(-a[4], b[4], f32(a[4] * b[4])),
	}
end
local function dot(a: V, b: V): number
	return native_arithmetic.dot3(a, b)
end

-- Complete 82585B58. Live bodies return their mass-frame basis/COM directly.
-- A body-less part with a local mass frame removes that frame from its cache.
-- This is distinct from 82585CB0's geometric-part transform getter.
function compression.part_mass_transform(p: part_mod.PartPose): { number }
	local body = p.body
	if body ~= nil then
		local out = table.create(16) :: { number }
		local rows = { 16, 20, 24, 4 }
		for i = 0, 15 do
			out[i + 1] = body[rows[i // 4 + 1] + i % 4 + 1]
		end
		return out
	end
	local local_frame = p.local_mass_frame
	if local_frame == nil then
		return p.transform
	end
	local l = matrix(local_frame)
	local basis = {}
	for i = 1, 3 do
		basis[i] = { l[1][i], l[2][i], l[3][i], 0.0 }
	end
	local neg = { f32(0.0 - l[4][1]), f32(0.0 - l[4][2]), f32(0.0 - l[4][3]), f32(0.0 - l[4][4]) }
	local position = madd(basis[1], neg[1], madd(basis[2], neg[2], scale(basis[3], neg[3])))
	local cached = matrix(p.transform)
	local result = {}
	for i = 1, 4 do
		local v = if i == 4 then position else basis[i]
		local first = if i == 4 then madd(cached[1], v[1], cached[4]) else scale(cached[1], v[1])
		result[i] = madd(cached[3], v[3], madd(cached[2], v[2], first))
	end
	local out = table.create(16) :: { number }
	for i = 0, 15 do
		out[i + 1] = to_bits(result[i // 4 + 1][i % 4 + 1])
	end
	return out
end

-- 82C08968, with live mass-frame observations rather than a byte-buffer owner.
-- Rest height is physicstrucks/default.TruckYPos, copied to8380 by82C08D18.
function compression.average_wheel_compressions(deck: M, wheel_positions: { V }, rest_height: number): { number }
	local c0 = cross(deck[2], deck[3])
	local c1 = cross(deck[3], deck[1])
	local c2 = cross(deck[1], deck[2])
	local determinant = dot(deck[1], c0)
	-- Native reciprocal estimate and two refinements.
	local inverse = native_arithmetic.reciprocal_estimate(determinant)
	for _ = 1, 2 do
		inverse = mul_add(inverse, mul_add(-inverse, determinant, 1.0), inverse)
	end
	local basis = {}
	for i = 1, 3 do
		basis[i] = scale({ c0[i], c1[i], c2[i], c1[i] }, inverse)
	end
	local neg = {}
	for i = 1, 4 do
		-- ROBLOX: смена знака через бит 31, как в Rust (to_bits ^ 0x8000_0000).
		neg[i] = from_bits(bit32.bxor(to_bits(deck[4][i]), 0x8000_0000))
	end
	local position = madd(basis[3], neg[3], madd(basis[2], neg[2], scale(basis[1], neg[1])))
	local heights = {}
	for i = 1, 4 do
		local p = wheel_positions[i]
		local l = madd(basis[3], p[3], madd(basis[2], p[2], madd(basis[1], p[1], position)))
		heights[i] = l[2]
	end
	return {
		f32(f32(f32(heights[1] + heights[2]) * 0.5) - rest_height),
		f32(f32(f32(heights[3] + heights[4]) * 0.5) - rest_height),
	}
end

-- Complete 82C08968: observe wheel COM positions in inverse deck mass space,
-- average native pairs0/1 and2/3, subtract board+8380, store+8372/+8376 only.
-- ROBLOX: board = buffer из 8400 байт (big-endian), меняется на месте.
function compression.calculate_wheel_compressions(board: buffer, parts: { part_mod.PartPose })
	local deck = matrix(compression.part_mass_transform(parts[7]))
	local wheels = {}
	for i = 1, 4 do
		wheels[i] = matrix(compression.part_mass_transform(parts[i]))[4]
	end
	local distance = from_bits(bit32.byteswap(buffer.readu32(board, 8380)))
	local heights = compression.average_wheel_compressions(deck, wheels, distance)
	for k, offset in { 8372, 8376 } do
		local height = heights[k]
		local w = if height ~= height then bit32.bor(to_bits(height), 0x0040_0000) else to_bits(height)
		buffer.writeu32(board, offset, bit32.byteswap(w))
	end
end

return compression
