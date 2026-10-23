--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/air/body_flip.rs (коммит 2e16697)
--
-- TU3 Reckoning::UpdateBodyFlip 82D8EC70, with explicit attribute-read inputs.
-- Full scalar gates, spin matrix and conditional combined-matrix publication.
-- ROBLOX: Matrix = [[f32; 4]; 4] -> таблица из 4 столбцов по 4 числа;
-- Option<f32> -> число или nil.

local rt = require("../../rt")
local trigonometry = require("../trigonometry")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local sin_cos = trigonometry.sin_cos

local body_flip = {}

export type Matrix = { { number } }

export type BodyFlipState = {
	-- Reckoning +1584, +1588, +1592.
	angle: number,
	speed: number,
	requested_speed: number,
	-- Reckoning +1072 and +1008. These are distinct native output buffers.
	spin_transform: Matrix,
	combined_transform: Matrix,
}

-- Actual Attrib::GetAttributePointer results (82B72420), not guessed settings.
-- Missing collection/attribute resolves to the supplied live 830D0850 value.
export type BodyFlipSettings = {
	-- Hash 26E7322CCDC3FE23.
	smoothing: number?,
	-- Hash 3D95C06DC6E3A002.
	maximum_speed: number?,
	-- Hash 89763E47712871C3.
	spin_scale: number?,
	missing_attribute_value: number,
}

export type BodyFlipInput = {
	requested_speed: number,
	-- Reckoning +1568, +1152 and +1232; caller-provided axes, without repair.
	spin_angle: number,
	normal: { number },
	flip_axis: { number },
	-- Processed +2604; only the non-perfect branch uses this dt.
	timestep: number,
	-- Processed +2548 -> layout +4 -> byte +28.
	perfect_body_flips: boolean,
}

local function clamp(value: number, lower: number, upper: number): number
	if f32(lower - value) >= 0.0 then
		value = lower
	end
	if f32(upper - value) >= 0.0 then
		return value
	end
	return upper
end

local function rotation(axis: { number }, angle: number): Matrix
	local x, y, z = axis[1], axis[2], axis[3]
	local s, c = sin_cos(angle)
	local t = f32(1.0 - c)
	local tx, ty, tz = f32(t * x), f32(t * y), f32(t * z)
	local sx, sy, sz = f32(s * x), f32(s * y), f32(s * z)
	local xx = mul_add(tx, x, c)
	local yx = f32(f32(ty * x) - sz)
	local zx = mul_add(tz, x, sy)
	-- The native 822FB890 permute repeats column.x into lane w. It does not
	-- create a renderer-style affine matrix with zero w basis lanes.
	return {
		{ xx, mul_add(tx, y, sz), f32(f32(tx * z) - sy), xx },
		{ yx, mul_add(ty, y, c), mul_add(ty, z, sx), yx },
		{ zx, f32(f32(tz * y) - sx), mul_add(tz, z, c), zx },
		{ 0.0, 0.0, 0.0, 0.0 },
	}
end
-- ROBLOX: приватная fn rotation открыта для air::reckoning (тот же порядок FMA).
body_flip.rotation = rotation

function body_flip.update(state: BodyFlipState, settings: BodyFlipSettings, input: BodyFlipInput)
	local fallback = settings.missing_attribute_value
	local smoothing = if settings.smoothing ~= nil then settings.smoothing else fallback
	local maximum = if settings.maximum_speed ~= nil then settings.maximum_speed else fallback
	local spin_scale = if settings.spin_scale ~= nil then settings.spin_scale else fallback
	state.requested_speed = input.requested_speed
	local speed = mul_add(f32(input.requested_speed - state.speed), smoothing, state.speed)
	if input.perfect_body_flips then
		local full_turn = from_bits(0x40C9_0FDB)
		local remaining_rate = f32(f32(full_turn - math.abs(state.angle)) * 12.0)
		local sign = if speed > 0.0 then 1.0 else -1.0
		if not (math.abs(speed) < remaining_rate) then
			speed = f32(sign * remaining_rate)
		end
		state.angle = clamp(mul_add(speed, from_bits(0x3C88_8889), state.angle), -full_turn, full_turn)
	else
		speed = clamp(speed, -maximum, maximum)
		state.angle = mul_add(input.timestep, speed, state.angle)
	end
	state.speed = speed
	state.spin_transform = rotation(input.normal, f32(input.spin_angle * spin_scale))
	-- Native zero-angle branch leaves the +1008 matrix untouched.
	if state.angle ~= 0.0 then
		local flip = rotation(input.flip_axis, state.angle)
		local spin = state.spin_transform
		local combined = {}
		for col = 1, 4 do
			local c = {}
			for lane = 1, 4 do
				local first
				if col == 4 then
					first = mul_add(spin[col][1], flip[1][lane], flip[4][lane])
				else
					first = f32(spin[col][1] * flip[1][lane])
				end
				local second = mul_add(spin[col][2], flip[2][lane], first)
				c[lane] = mul_add(spin[col][3], flip[3][lane], second)
			end
			combined[col] = c
		end
		state.combined_transform = combined
	end
end

return body_flip
