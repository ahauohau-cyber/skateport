--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/manual/angle.rs (коммит 2e16697)
--
-- Finite scalar Angle::Normalize 8258DB98, from direct TU3 disassembly.
-- Kept local pending coordinator's shared angle-operation audit.

local rt = require("../../../rt")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits

local angle = {}

-- ROBLOX: enum AngleError -> строка.
-- Native fctiwz result for nonfinite/overflow input is not reconstructed.
angle.IntegerConversionUnavailable = "IntegerConversionUnavailable"

local PI = from_bits(0x4049_0fdb)
local TAU = from_bits(0x40c9_0fdb)

-- ROBLOX: Result<f32, AngleError> -> (значение) или (nil, ошибка).
function angle.normalize(value: number): (number?, string?)
	if value >= -PI and value < PI then
		return value, nil
	end
	local turns = f32(value * from_bits(0x3e22_f983))
	if not rt.is_finite(turns) or turns < -2147483648 or turns > 2147483647 then
		return nil, angle.IntegerConversionUnavailable
	end
	local whole_turns = rt.float_as_i32(turns)
	-- fnmsubs performs fused -(count*tau - angle), then binary32 rounding.
	-- ROBLOX: `whole_turns as f32` — округление i32 до f32.
	local reduced = -mul_add(f32(whole_turns), TAU, -value)
	if reduced >= PI then
		return f32(reduced - TAU), nil
	elseif reduced < -PI then
		return f32(reduced + TAU), nil
	end
	return reduced, nil
end

return angle
