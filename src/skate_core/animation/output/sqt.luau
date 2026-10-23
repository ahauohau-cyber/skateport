--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/output/sqt.rs (коммит 2e16697)

local rt = require("../../../rt")

local f32 = rt.f32
local mul_add = rt.mul_add

local sqt = {}

-- ROBLOX: NativeMatrix = [[f32; 4]; 4] -> 4 строки по 4 числа (индексы с 1).
export type NativeMatrix = { { number } }

-- TU3 48-byte SQT record: scale, quaternion (x,y,z,w), translation.
export type Sqt = { scale: { number }, rotation: { number }, translation: { number } }

-- Per-bone numerical result 828D3800. The game owns its vector allocations;
-- cache-line padding and speculative DMA loads are not gameplay behavior.
function sqt.sqt_to_matrix(input: Sqt): NativeMatrix
	local q = input.rotation
	local x, y, z, w = q[1], q[2], q[3], q[4]
	local s = input.scale
	local sx, sy, sz = s[1], s[2], s[3]
	-- Separate products and sums reflect the native VMX instruction order.
	local xx = f32(x * x)
	local yy = f32(y * y)
	local zz = f32(z * z)
	local xy = f32(x * y)
	local wz = f32(w * z)
	local xz = f32(x * z)
	local wy = f32(w * y)
	local yz = f32(y * z)
	local wx = f32(w * x)
	local t = input.translation
	return {
		{
			f32(mul_add(-f32(yy + zz), 2.0, 1.0) * sx),
			f32(f32(f32(xy + wz) * 2.0) * sx),
			f32(f32(f32(xz - wy) * 2.0) * sx),
			0.0,
		},
		{
			f32(f32(f32(xy - wz) * 2.0) * sy),
			f32(mul_add(-f32(xx + zz), 2.0, 1.0) * sy),
			f32(f32(f32(yz + wx) * 2.0) * sy),
			0.0,
		},
		{
			f32(f32(f32(xz + wy) * 2.0) * sz),
			f32(f32(f32(yz - wx) * 2.0) * sz),
			f32(mul_add(-f32(xx + yy), 2.0, 1.0) * sz),
			0.0,
		},
		{ t[1], t[2], t[3], 1.0 },
	}
end

-- Complete arithmetic/store behavior of TU3 0x828D3800.
--
-- The native SIMD loop writes four records at a time, including padding beyond
-- `bone_count`. The native `dcbzl` additionally zeros the following cache line;
-- `cache_offset` specifies the destination address modulo 128 (a multiple of 16).
-- Destination must include that trailing storage. No normalization or
-- bind-pose composition occurs. Unlike native speculative loads, this safe
-- adapter does not read a further unused group beyond the padded inputs.
-- ROBLOX: Result<usize, PoseBufferError> -> число или rt.raise({ kind = ... }).
function sqt.sqt_to_local(bone_count: number, cache_offset: number, source: { Sqt }, destination: { NativeMatrix }): number
	if cache_offset >= 128 or cache_offset % 16 ~= 0 then
		rt.raise({ kind = "InvalidCacheOffset" })
	end
	local padded = bit32.band(bone_count + 3, bit32.bnot(3))
	if #source < padded then
		rt.raise({ kind = "ShortInput" })
	end
	local trailing_words = if padded == 0 then 0 else (128 - cache_offset) // 4
	local required = padded + (trailing_words + 15) // 16
	if #destination < required then
		rt.raise({ kind = "ShortOutput" })
	end
	-- Earlier zeroed lines are overwritten by later groups; only the final tail
	-- remains visible. No typed input/output aliasing is allowed by this adapter.
	local remaining = trailing_words
	for m = padded + 1, required do
		for r = 1, 4 do
			for l = 1, 4 do
				if remaining > 0 then
					destination[m][r][l] = 0.0
					remaining -= 1
				end
			end
		end
	end
	for i = 1, padded do
		destination[i] = sqt.sqt_to_matrix(source[i])
	end
	return padded
end

return sqt
