--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/ground_acceleration.rs (коммит 2e16697)
--
-- Deck acceleration conditioning 82DF0508 and IsBumped 82BA7310, original TU3.
-- Matrices are the raw physical deck and Reckoning ground frames; the effective
-- animation deck is a different source. No render transform participates here.

local rt = require("../../rt")
local native_arithmetic = require("../physics/native_arithmetic")

local f32 = rt.f32
local mul_add = rt.mul_add

local ground_acceleration = {}

-- ROBLOX: AnimationPartTransform = [[f32; 4]; 4].
export type Input = {
	-- PhysOutDeck 0..48, actual Part6 transform (82C02AD8..2B20).
	deck: { { number } },
	-- PhysOutGround 0..48, Reckoning 752..800 (82DB70E0..7100).
	ground: { { number } },
	-- PhysOutMotion 112, BoardBody 528 from observed deck velocity differences.
	world_acceleration: { number },
}

export type Settings = {
	-- Globals 344 anim_motion/bumps layout 1700, scale_x_acc.
	scale_x_acc: number,
	-- Same collection layout 1768, min_bump_mag.
	min_bump_mag: number,
}

export type Output = { acceleration: { number }, bumped: boolean }

local function inverse_rotate(frame: { { number } }, vector: { number }): { number }
	local out = {}
	for lane = 1, 4 do
		out[lane] = mul_add(frame[lane][3], vector[3], mul_add(frame[lane][2], vector[2], f32(frame[lane][1] * vector[1])))
	end
	return out
end
local function rotate(frame: { { number } }, vector: { number }): { number }
	local out = {}
	for lane = 1, 4 do
		out[lane] = mul_add(frame[3][lane], vector[3], mul_add(frame[2][lane], vector[2], f32(frame[1][lane] * vector[1])))
	end
	return out
end

-- 82DF0508: remove deck-local Y, rotate back to world, express in the
-- ground frame, then remove ground-local Y. Both original stores are required.
function ground_acceleration.condition(input: Input): { number }
	local deck_local = inverse_rotate(input.deck, input.world_acceleration)
	deck_local[2] = 0.0 -- 82DF05C4
	local world = rotate(input.deck, deck_local)
	local ground_local = inverse_rotate(input.ground, world)
	ground_local[2] = 0.0 -- 82DF0600
	return ground_local
end

-- 82BA7310 scales X only, then compares the refined length strictly > threshold.
-- Independent Rust estimates are used; this is not a bit-exact Xenon claim.
function ground_acceleration.is_bumped(acceleration_in: { number }, settings: Settings): boolean
	local acceleration = table.clone(acceleration_in)
	acceleration[1] = f32(acceleration[1] * settings.scale_x_acc)
	local squared = native_arithmetic.dot3(acceleration, acceleration)
	local reciprocal = native_arithmetic.reciprocal_square_root_estimate(squared)
	for _ = 1, 2 do
		local square = f32(reciprocal * reciprocal)
		local half = f32(reciprocal * 0.5)
		local err = mul_add(-squared, square, 1.0)
		reciprocal = mul_add(half, err, reciprocal)
	end
	local magnitude = if squared == 0.0 then 0.0 else f32(squared * reciprocal)
	return magnitude > settings.min_bump_mag
end

function ground_acceleration.publish(input: Input, settings: Settings): Output
	local acceleration = ground_acceleration.condition(input)
	return { acceleration = acceleration, bumped = ground_acceleration.is_bumped(acceleration, settings) }
end

return ground_acceleration
