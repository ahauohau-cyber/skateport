--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/bump.rs (коммит 2e16697)
--
-- SetBumpCoefficients Begin 82BB0660, ctor 82BC7318/vtable 823200C8+48.

local rt = require("../../rt")
local native_arithmetic = require("../physics/native_arithmetic")

local f32 = rt.f32
local mul_add = rt.mul_add

local bump = {}

export type Settings = { scale_x_acc: number, min_bump_mag: number, min_bump_blend_value: number, max_bump_mag: number }

local THRESHOLD = rt.from_bits(0x358637bd)

-- Input is PhysOutAnimation 112 (already ground-conditioned), not raw world acceleration.
function bump.coefficients(acceleration_in: { number }, mirrored: boolean, settings: Settings): { number }
	local acceleration = table.clone(acceleration_in)
	acceleration[1] = f32(acceleration[1] * settings.scale_x_acc)
	local squared = native_arithmetic.dot3(acceleration, acceleration)
	local inverse = native_arithmetic.reciprocal_square_root_estimate(squared)
	for _ = 1, 2 do
		inverse = mul_add(f32(inverse * 0.5), mul_add(-squared, f32(inverse * inverse), 1.0), inverse)
	end
	local magnitude = if squared == 0.0 then 0.0 else f32(squared * inverse)
	local t = rt.fclamp(f32(f32(magnitude - settings.min_bump_mag) / f32(settings.max_bump_mag - settings.min_bump_mag)), 0.0, 1.0)
	local weight = mul_add(t, f32(1.0 - settings.min_bump_blend_value), settings.min_bump_blend_value)
	-- Initializer 82F826F8 broadcasts 82181A88 into 830BD350: length threshold 1e-6.
	local direction
	if magnitude > THRESHOLD then
		direction = { f32(acceleration[1] * inverse), f32(acceleration[3] * inverse) }
	else
		direction = { 0.0, 0.0 }
	end
	for i = 1, 2 do
		local value = f32(direction[i] * weight)
		direction[i] = if mirrored then -value else value
	end
	return direction
end

return bump
