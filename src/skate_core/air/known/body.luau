--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/air/known/body.rs (коммит 2e16697)
--
-- Body flip and spin targets selected by TU3 KnownAir.

local rt = require("../../../rt")
local point_graph = require("../../point_graph")
local data = require("./data")
local trajectory = require("./trajectory")

local f32 = rt.f32
local from_bits = rt.from_bits
local to_bits = rt.to_bits
local select = trajectory.select
local evaluate = point_graph.PointGraph.evaluate

type Vector4 = data.Vector4

local body = {}

local DEGREES_TO_RADIANS = from_bits(0x3C8E_FA35) -- 0x8206D110.
local RADIANS_TO_DEGREES = from_bits(0x4265_2EE1) -- 0x82084620.
local DIRECTION_EPSILON = from_bits(0x3A83_126F) -- 0x82063A48.
local PI = from_bits(0x4049_0FDB) -- 0x82060C44.
local ALIGNMENT_DELAY = from_bits(0x3D03_126F) -- 0x822F91E8.
local AUTO_SPIN_SCALE = from_bits(0x3F99_999A) -- 0x821659F4.
local FORTY_FIVE_DEGREES = from_bits(0x4234_0000) -- 0x82099018.
local HALF = from_bits(0x3F00_0000) -- 0x8209975C.
local REVERSE_SCALE = from_bits(0x3BA3_D70A) -- 0x82099920.
local DECELERATION_SCALE = from_bits(0x3F40_0000) -- 0x821814A0.

local function flip_sign_bits(v: Vector4): Vector4
	local out = {}
	for i = 1, 4 do
		out[i] = from_bits(bit32.bxor(to_bits(v[i]), 0x8000_0000))
	end
	return out
end

local function native_clamp(value: number, lower: number, upper: number): number
	value = select(f32(lower - value), lower, value)
	return select(f32(upper - value), value, upper)
end

-- `PhysState_KnownAir::CalculateBodyFlipSpeed`, TU3 `0x82D35F40`.
function body.calculate_body_flip_speed(
	state: data.KnownAirState,
	frame: data.KnownAirFrame,
	settings: data.KnownAirSettings,
	mode: data.KnownAirModeSettings,
	reckoning: data.KnownAirReckoningFields,
	runtime: any
): number
	if not state.body_flipping_211 then
		local flags = frame.flags_2468
		local has_flip = bit32.btest(flags, 0x20) or bit32.btest(flags, 0x10)
		local has_grab = bit32.btest(flags, 0x80) or bit32.btest(flags, 0x40)
		if has_flip and has_grab and not bit32.btest(frame.flags_2488, 0x0200_0000) then
			local threshold = evaluate(settings.flip_start_collision_time_vs_normal_y, reckoning.landing_normal_1152[2])
			if state.collision_time_196 > threshold then
				runtime:begin_reckoning_body_flip(bit32.band(bit32.rshift(flags, 7), 1) ~= 0)
				state.body_flipping_211 = true
			end
		end
	end

	if mode.perfect_body_flips_28 then
		return state.body_flip_target_speed_204
	end
	local flags = frame.flags_2468
	if bit32.btest(flags, 0x20) or bit32.btest(flags, 0x10) or state.time_in_state_180 < settings.body_flip_min_grab_time_fraction_456 then
		return state.body_flip_target_speed_204
	end
	return 0.0
end

-- `PhysState_KnownAir::CalculateBodySpinSpeed`, TU3 `0x82D360B0`.
function body.calculate_body_spin_speed(
	state: data.KnownAirState,
	frame: data.KnownAirFrame,
	settings: data.KnownAirSettings,
	mode: data.KnownAirModeSettings,
	reckoning: data.KnownAirReckoningFields,
	runtime: any
): number
	local scaled_input = f32(frame.body_spin_input_2640 * settings.max_spin_speed_428)
	local manual_spin = f32(scaled_input * DEGREES_TO_RADIANS)
	local result = if bit32.btest(frame.flags_2472, 0x1000_0000) then manual_spin else 0.0

	-- Native tests the unmasked manual value, not `result`.
	if manual_spin == 0.0 and state.landing_heading_valid_209 and not bit32.btest(frame.flags_2484, 0x0000_8000) then
		local heading_axis = reckoning.heading_axis_1200
		if (bit32.band(bit32.rshift(frame.flags_2468, 20), 1) ~= 0) ~= state.start_flipped_210 then
			heading_axis = flip_sign_bits(heading_axis)
		end

		local unwrapped_angle = 0.0
		if runtime:dot3(reckoning.landing_normal_1152, state.landing_normal_64) > DIRECTION_EPSILON then
			unwrapped_angle = runtime:signed_angle_about_axis(heading_axis, state.landing_heading_80, reckoning.landing_normal_1152)
			if bit32.btest(frame.flags_2468, 0x0010_0000) then
				unwrapped_angle = f32(unwrapped_angle + PI)
			end
		end

		local corrected_angle = runtime:wrap_angle_8258db98(unwrapped_angle)
		local heading_degrees = f32(corrected_angle * RADIANS_TO_DEGREES)
		local max_adjust = evaluate(settings.max_heading_adjust_vs_up_y_160, frame.skater_up_544[2])
		if math.abs(heading_degrees) > max_adjust then
			local wrapped_pi = runtime:wrap_angle_8258db98(PI)
			corrected_angle = runtime:wrap_angle_8258db98(f32(wrapped_pi + corrected_angle))
		end

		local current_speed = reckoning.body_spin_speed_1572
		local remaining = f32(state.collision_time_196 - state.time_in_state_180)
		local alignment_time = select(f32(remaining - ALIGNMENT_DELAY), remaining, ALIGNMENT_DELAY)
		local reciprocal_time = f32(1.0 / alignment_time)
		local target = f32(f32(reciprocal_time * corrected_angle) * AUTO_SPIN_SCALE)

		if math.abs(current_speed) < DIRECTION_EPSILON then
			current_speed = 0.0
		end
		if f32(current_speed * target) < 0.0 then
			local alternate = runtime:wrap_angle_8258db98(f32(unwrapped_angle + PI))
			if f32(FORTY_FIVE_DEGREES * DEGREES_TO_RADIANS) > math.abs(alternate) and f32(f32(reciprocal_time * alternate) * current_speed) > 0.0 then
				target = f32(reciprocal_time * alternate)
			end
		end

		result = native_clamp(target, -mode.body_spin_speed_limit_56, mode.body_spin_speed_limit_56)
		if math.abs(result) < settings.min_auto_body_speed_424 then
			result = f32(result * HALF)
		end
		if math.abs(unwrapped_angle) < settings.min_auto_body_speed_424 then
			result = f32(f32(unwrapped_angle / frame.delta_time_2604) * HALF)
		end
		if f32(result * current_speed) < 0.0 then
			result = f32(result * REVERSE_SCALE)
		elseif math.abs(current_speed) > math.abs(result) then
			result = f32(result * DECELERATION_SCALE)
		end
	end

	return result
end

return body
