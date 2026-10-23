--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/vbr/transform.rs (коммит 2e16697)
--
-- TU3 Init 82E891D8, IDCT table 82E88C58, DecompressFrameBlock 82E89770.
-- All coefficient words below were read from the original TU3 mapped image.

local rt = require("../../../rt")
local trigonometry = require("../../trigonometry")
local native_arithmetic = require("../../physics/native_arithmetic")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local to_bits = rt.to_bits

local transform = {}

local C = {}
for i, w in { 0x3fb8aa0e, 0xbf389e52, 0x3ef5162d, 0xbeb1d204, 0x3e77adbd, 0xbe0cd4fb, 0x3d5541c6, 0xbc188b0b } do
	C[i] = from_bits(w)
end

-- Original logarithm polynomial 82E89598..5DC, evaluated only at integers 2..9.
-- For this bounded positive domain, exponent extraction supplies exactly the
-- integer requested by the original floor(log2-estimate) instruction pair.
local function logarithm_for_frequency(integer: number): number
	local input = f32(integer)
	local b = to_bits(input)
	local exponent = bit32.band(bit32.rshift(b, 23), 255) - 127
	local mantissa = from_bits(bit32.bor(bit32.band(b, 0x007fffff), 0x3f800000))
	local a = f32(mantissa - 1.0)
	local a2 = f32(a * a)
	local a3 = f32(a * a2)
	local a4 = f32(a2 * a2)
	-- Original vectors 8230EA70 and 8230EA80.
	local low = mul_add(a, C[2], C[1])
	local high = mul_add(a, C[6], C[5])
	low = mul_add(a2, C[3], low)
	high = mul_add(a2, C[7], high)
	low = mul_add(a3, C[4], low)
	high = mul_add(a3, C[8], high)
	local polynomial = mul_add(a4, high, low)
	return f32(mul_add(a, polynomial, exponent) * from_bits(0x3f317218)) -- 82139A70
end

type Tables = { quantization: { { number } }, inverse_dct: { { number } } }
local cached: Tables? = nil

-- ROBLOX: OnceLock -> ленивое вычисление при первом вызове.
local function tables(): Tables
	if cached then
		return cached
	end
	local base = {}
	for i = 0, 7 do
		base[i + 1] = f32(logarithm_for_frequency(i + 2) * from_bits(0x38000000))
	end
	local multiplier = 1.0
	local quantization: { { number } } = {}
	for _ = 1, 256 do
		local row = {}
		for i = 1, 8 do
			row[i] = f32(base[i] * multiplier)
		end
		multiplier = f32(multiplier + from_bits(0x3e4ccccd)) -- 82099280; accumulated fadds
		table.insert(quantization, row)
	end
	-- 822F8B48..58 and individual .785398/.1.570796 literal loads.
	local angles = { 0, 0x3ec90fdb, 0x3f490fdb, 0x3f96cbe4, 0x3fc90fdb, 0x3ffb53d2, 0x4016cbe4, 0x402fede0 }
	local inverse_dct: { { number } } = {}
	for frame = 0, 7 do
		local phase = f32(frame + 0.5)
		local row = {}
		for i, a in angles do
			row[i] = f32(trigonometry.cos(f32(phase * from_bits(a))) * 0.25)
		end
		row[1] = f32(row[1] * 0.5)
		table.insert(inverse_dct, row)
	end
	local t = { quantization = quantization, inverse_dct = inverse_dct }
	cached = t
	return t
end

-- pub(super) fn decode
-- ROBLOX: frame — номер кадра в блоке (0..7), quantization_index — байт.
function transform.decode(frame: number, quantization_index: number, scale: number, coefficients: { number }, channel_min: number, channel_range: number): number
	local t = tables()
	local squared = f32(scale * scale)
	-- Literal 820612E0 is 2^-15. This equation was independently recovered
	-- from original vmulfp/vmaddcfp instructions 82E89930..4C.
	local bias = f32(scale * from_bits(0x38000000))
	local q = t.quantization[quantization_index + 1]
	local idct = t.inverse_dct[frame + 1]
	local weights = {}
	for i = 1, 8 do
		weights[i] = f32(mul_add(q[i], squared, bias) * idct[i])
	end
	local first = native_arithmetic.dot4({ coefficients[1], coefficients[2], coefficients[3], coefficients[4] }, { weights[1], weights[2], weights[3], weights[4] })
	local last = native_arithmetic.dot4({ coefficients[5], coefficients[6], coefficients[7], coefficients[8] }, { weights[5], weights[6], weights[7], weights[8] })
	-- BSS 830CEAF0 initializer 82F96D58 converts integer 1 with scale 1 -> .5.
	return mul_add(f32(f32(first + last) + 0.5), channel_range, channel_min)
end

return transform
