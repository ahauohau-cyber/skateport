--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/input_phase/motion_math.rs (коммит 2e16697)
--
-- Inlined physical input calculations from TU3 82DB4048.
-- Xenon estimates use the shared, explicitly approximation-derived model.
-- ROBLOX: RawVector -> таблица из 4 слов; f32::from_bits/to_bits -> rt.

local rt = require("../../../rt")
local requests = require("./requests")
local native_arithmetic = require("../../physics/native_arithmetic")
local board_motion_output = require("../../physics/board_motion_output")

local f32 = rt.f32
local dot3 = native_arithmetic.dot3
local reciprocal_estimate = native_arithmetic.reciprocal_estimate
local inverse_length_squared = board_motion_output.inverse_length_squared

type RawVector = requests.RawVector

local motion_math = {}

local function from_bits4(v: RawVector): { number }
	return { rt.from_bits(v[1]), rt.from_bits(v[2]), rt.from_bits(v[3]), rt.from_bits(v[4]) }
end

-- 82DB5184..51D4: retain displacement separately from the damped velocity.
function motion_math.ground_history(request: requests.GroundHistoryRequest): requests.GroundHistoryResult
	local old = from_bits4(request.previous_position)
	local current = from_bits4(request.current_position)
	local previous = from_bits4(request.previous_filtered_delta)
	local delta = table.create(4, 0)
	for i = 1, 4 do
		delta[i] = f32(current[i] - old[i])
	end
	local timestep = rt.from_bits(request.timestep_bits)
	local reciprocal = reciprocal_estimate(timestep)
	for _ = 1, 2 do
		local err = rt.mul_add(-reciprocal, timestep, 1.0)
		reciprocal = rt.mul_add(reciprocal, err, reciprocal)
	end
	-- Literal82072818, then8231A844 minus that coefficient.
	local retention = rt.from_bits(0x3f733333)
	local change = f32(1.0 - retention)
	local delta_bits = table.create(4, 0)
	local filtered = table.create(4, 0)
	for i = 1, 4 do
		delta_bits[i] = rt.to_bits(delta[i])
		local scaled = f32(reciprocal * f32(delta[i] * change))
		filtered[i] = rt.to_bits(rt.mul_add(previous[i], retention, scaled))
	end
	return { delta = delta_bits, filtered_delta = filtered }
end

-- 82DB53F0..5508 integrates the gravity component along the board velocity.
-- The PrepareJump flag's direct velocity copy is handled by the caller.
function motion_math.prepared_jump_velocity(request: requests.PrepareJumpRequest): RawVector
	local velocity = from_bits4(request.skateboard_vector)
	local previous = from_bits4(request.previous_velocity)
	local squared = dot3(velocity, velocity)
	local inverse = inverse_length_squared(squared, 2)
	local length = if squared == 0.0 then 0.0 else f32(squared * inverse)
	-- Initializer82F826F8 broadcasts82181A88 into830BD350.
	local direction = if length > rt.from_bits(0x358637bd)
		then { f32(velocity[1] * inverse), f32(velocity[2] * inverse), f32(velocity[3] * inverse), f32(velocity[4] * inverse) }
		else { 0.0, 0.0, 0.0, 0.0 }
	local down_component = rt.from_bits(bit32.bxor(rt.to_bits(direction[2]), 0x80000000))
	local acceleration = f32(down_component * rt.from_bits(0x411ccccd)) -- 822F8BD4
	local result = table.create(4, 0)
	for i = 1, 4 do
		result[i] = rt.to_bits(rt.mul_add(f32(direction[i] * acceleration), rt.from_bits(0x3c888889), previous[i])) -- 820849C8
	end
	return result
end

return motion_math
