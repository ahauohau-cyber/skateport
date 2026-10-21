--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/trigonometry.rs (коммит 2e16697)
--
-- Scalar lane of TU3 `XMVectorSinCos`, `0x82473A08`.
--
-- Coefficients are the executable words at 0x822F97C0..0x822F9860.
-- Arithmetic follows the recovered polynomial structure. Numerical agreement
-- with the original game requires independent validation.
--
-- ROBLOX: во всём файле
--   f32::from_bits(c)   -> from_bits(c)
--   a.mul_add(b, c)     -> mul_add(a, b, c)   (одно округление до f32)
--   a * b, a + b, a - b -> f32(...)           (округление до f32, как в Rust)
--   round_ties_even()   -> round_ties_even()

local rt = require("../rt")
local reciprocal_sqrt = require("./physics/reciprocal_sqrt")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local round_ties_even = rt.round_ties_even

local trigonometry = {}

-- pub fn sin_cos(angle: f32) -> (f32, f32)
-- ROBLOX: кортеж (sin, cos) -> два возвращаемых значения.
function trigonometry.sin_cos(angle: number): (number, number)
	local turns = round_ties_even(f32(angle * from_bits(0x3E22_F983)))
	local x = mul_add(-from_bits(0x40C9_0FDB), turns, angle)
	local x2 = f32(x * x)
	local x3 = f32(x2 * x)
	local x4 = f32(x2 * x2)
	local x5 = f32(x3 * x2)
	local x6 = f32(x3 * x3)
	local x7 = f32(x4 * x3)
	local x8 = f32(x4 * x4)
	local x9 = f32(x5 * x4)
	local x10 = f32(x5 * x5)
	local x11 = f32(x6 * x5)
	local x12 = f32(x6 * x6)
	local x13 = f32(x7 * x6)
	local x15 = f32(x8 * x7)
	local x14 = f32(x7 * x7)
	local x16 = f32(x8 * x8)
	local x17 = f32(x9 * x8)
	local x19 = f32(x10 * x9)
	local x18 = f32(x9 * x9)
	local x21 = f32(x11 * x10)
	local x20 = f32(x10 * x10)
	local x23 = f32(x12 * x11)
	local x22 = f32(x11 * x11)

	local sin = mul_add(from_bits(0xBE2A_AAAB), x3, x)
	sin = mul_add(from_bits(0x3C08_8889), x5, sin)
	sin = mul_add(x7, from_bits(0xB950_0D01), sin)
	sin = mul_add(from_bits(0x3638_EF1D), x9, sin)
	sin = mul_add(from_bits(0xB2D7_322B), x11, sin)
	sin = mul_add(from_bits(0x2F30_9231), x13, sin)
	sin = mul_add(from_bits(0xAB57_3F9F), x15, sin)
	sin = mul_add(from_bits(0x274A_963C), x17, sin)
	sin = mul_add(from_bits(0xA317_A4DA), x19, sin)
	sin = mul_add(from_bits(0x1EB8_DC78), x21, sin)
	sin = mul_add(from_bits(0x9A3B_0DA1), x23, sin)

	local cos = mul_add(-0.5, x2, 1.0)
	cos = mul_add(from_bits(0x3D2A_AAAB), x4, cos)
	cos = mul_add(from_bits(0xBAB6_0B61), x6, cos)
	cos = mul_add(from_bits(0x37D0_0D01), x8, cos)
	cos = mul_add(from_bits(0xB493_F27E), x10, cos)
	cos = mul_add(from_bits(0x310F_76C8), x12, cos)
	cos = mul_add(from_bits(0xAD49_CBA5), x14, cos)
	cos = mul_add(from_bits(0x2957_3F9F), x16, cos)
	cos = mul_add(from_bits(0xA534_13C3), x18, cos)
	cos = mul_add(from_bits(0x20F2_A15D), x20, cos)
	cos = mul_add(from_bits(0x9C86_71CB), x22, cos)
	return sin, cos
end

-- Standalone TU3 cosine82473930. The even-power tree differs from SinCos;
-- normal gameplay camera roll82BD35B8 calls this function independently.
-- This is the retained readable polynomial also audited for SetTurning.
-- pub fn cos(angle: f32) -> f32
function trigonometry.cos(angle: number): number
	local turns = round_ties_even(f32(angle * from_bits(0x3e22_f983)))
	local x = mul_add(-from_bits(0x40c9_0fdb), turns, angle)
	local x2 = f32(x * x)
	local x4 = f32(x2 * x2)
	local x6 = f32(x4 * x2)
	local x8 = f32(x4 * x4)
	local x10 = f32(x6 * x4)
	local x12 = f32(x6 * x6)
	local x14 = f32(x8 * x6)
	local x16 = f32(x8 * x8)
	local x18 = f32(x10 * x8)
	local x22 = f32(x12 * x10)
	local x20 = f32(x10 * x10)
	local value = mul_add(-0.5, x2, 1.0)
	-- ROBLOX: массив пар (power, coefficient) -> таблица пар, порядок тот же.
	for _, pair in
		{
			{ x4, 0x3d2a_aaab },
			{ x6, 0xbab6_0b61 },
			{ x8, 0x37d0_0d01 },
			{ x10, 0xb493_f27e },
			{ x12, 0x310f_76c8 },
			{ x14, 0xad49_cba5 },
			{ x16, 0x2957_3f9f },
			{ x18, 0xa534_13c3 },
			{ x20, 0x20f2_a15d },
			{ x22, 0x9c86_71cb },
		}
	do
		local power, coefficient = pair[1], pair[2]
		value = mul_add(from_bits(coefficient), power, value)
	end
	return value
end

-- TU3 vector sine 824531C8. Its sequential odd powers differ from SinCos's
-- multiplication tree, so callers of the standalone sine must use this path.
-- pub fn sin(angle: f32) -> f32
function trigonometry.sin(angle: number): number
	local turns = round_ties_even(f32(angle * from_bits(0x3E22_F983)))
	local x = mul_add(-from_bits(0x40C9_0FDB), turns, angle)
	local x2 = f32(x * x)
	local power = f32(x * x2)
	local result = x
	for _, coefficient in
		{
			0xBE2A_AAAB,
			0x3C08_8889,
			0xB950_0D01,
			0x3638_EF1D,
			0xB2D7_322B,
			0x2F30_9231,
			0xAB57_3F9F,
			0x274A_963C,
			0xA317_A4DA,
			0x1EB8_DC78,
			0x9A3B_0DA1,
		}
	do
		result = mul_add(from_bits(coefficient), power, result)
		power = f32(power * x2)
	end
	return result
end

-- Scalar lane of TU3 vector acos 82453298. The native radicand constant is
-- 0x3f800001, and its reciprocal square root receives one refinement.
-- pub fn acos(value: f32) -> f32
function trigonometry.acos(value: number): number
	return f32(f32(from_bits(0x4049_0FDB) * 0.5) - trigonometry.asin(value))
end

-- Shared inverse-sine polynomial, also inlined by DisablePushBrake82BA5150.
-- Keep this intermediate separate: that caller subtracts degrees from90,
-- whereas vector acos subtracts radians from half pi.
-- pub fn asin(value: f32) -> f32
function trigonometry.asin(value: number): number
	local a = math.abs(value)
	local cube = f32(f32(value * value) * a)
	local c = from_bits
	local p0 = mul_add(c(0x400B_1889), a, c(0xC0D1_360E))
	local p1 = mul_add(c(0x3E66_3246), a, c(0xBF98_3F2F))
	local p2 = mul_add(c(0xBED6_5553), a, c(0x4089_80BD))
	local p3 = mul_add(c(0xBD6D_D42D), a, c(0x3F1D_D7B6))
	p0 = mul_add(p0, a, c(0x40AF_6AD8))
	p1 = mul_add(p1, a, c(0x3FB5_8485))
	p2 = mul_add(p2, a, c(0xC08F_6AD9))
	p3 = mul_add(p3, a, c(0xBFAF_4418))
	local left = mul_add(p1, cube, p0)
	local right = mul_add(p3, cube, p2)
	local radicand = f32(c(0x3F80_0001) - a)
	local r = reciprocal_sqrt.estimate(radicand)
	local correction = mul_add(-f32(radicand * 0.5), f32(r * r), 0.5)
	r = mul_add(r, correction, r)
	local residual = f32(mul_add(-a, value, value) * right)
	return mul_add(residual, r, f32(value * left))
end

return trigonometry
