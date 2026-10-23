--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/air/known/trajectory.rs (коммит 2e16697)
--
-- KnownAir trajectory setup, ground restoration, and follow update.
-- ROBLOX: `x as f32` для i32 -> f32(x); wrapping_* для i32 -> rt.to_i32.

local rt = require("../../../rt")
local point_graph = require("../../point_graph")
local data = require("./data")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits

type Vector4 = data.Vector4

local trajectory = {}

local FIXED_STEP = from_bits(0x3C88_8889) -- 0x820849C8, 1/60.
local HALF = from_bits(0x3F00_0000) -- 0x8209975C.
local ONE = from_bits(0x3F80_0000) -- 0x8231A844.
local PERFECT_FLIP_NUMERATOR = from_bits(0xC0F1_463B) -- 0x822F9450.
local NEGATIVE_TWO_PI = from_bits(0xC0C9_0FDB) -- 0x822F9434.
local HEADING_LENGTH_SQUARED_MIN = from_bits(0x3DCC_CCCD) -- 0x820641A8.

function trajectory.trajectory_position(t: data.KnownAirTrajectory, time: number): Vector4
	local time_squared = f32(time * time)
	local out = {}
	for lane = 1, 4 do
		local linear = mul_add(t.velocity[lane], time, t.position[lane])
		local half_acceleration = f32(t.acceleration[lane] * HALF)
		out[lane] = mul_add(half_acceleration, time_squared, linear)
	end
	return out
end
function trajectory.trajectory_velocity(t: data.KnownAirTrajectory, time: number): Vector4
	local out = {}
	for lane = 1, 4 do
		out[lane] = mul_add(t.acceleration[lane], time, t.velocity[lane])
	end
	return out
end
function trajectory.add(left: Vector4, right: Vector4): Vector4
	return { f32(left[1] + right[1]), f32(left[2] + right[2]), f32(left[3] + right[3]), f32(left[4] + right[4]) }
end
function trajectory.sub(left: Vector4, right: Vector4): Vector4
	return { f32(left[1] - right[1]), f32(left[2] - right[2]), f32(left[3] - right[3]), f32(left[4] - right[4]) }
end
function trajectory.mul_scalar(v: Vector4, scalar: number): Vector4
	return { f32(v[1] * scalar), f32(v[2] * scalar), f32(v[3] * scalar), f32(v[4] * scalar) }
end
function trajectory.select(test: number, nonnegative: number, negative: number): number
	if test >= 0.0 then
		return nonnegative
	end
	return negative
end
local trajectory_position, trajectory_velocity = trajectory.trajectory_position, trajectory.trajectory_velocity
local sub, mul_scalar, select = trajectory.sub, trajectory.mul_scalar, trajectory.select

-- `PhysState_KnownAir::InitTrajectoryInfo`, TU3 `0x82D35508`.
function trajectory.init_trajectory_info(
	state: data.KnownAirState,
	frame: data.KnownAirFrame,
	settings: data.KnownAirSettings,
	mode: data.KnownAirModeSettings,
	runtime: any
)
	state.landing_normal_64 = frame.selector_landing_normal_2656

	local prediction = runtime:selected_prediction()
	local apex, time_to_apex = runtime:highest_trajectory_position(prediction.trajectory)
	state.time_to_apex_200 = time_to_apex
	state.trajectory_apex_96 = apex

	state.collision_position_112 = runtime:selector_contact_position()
	-- 82D35580 reads r30+48; r30 is the complete winning result.
	state.collision_time_196 = prediction.collision_time_48
	if mode.perfect_body_flips_28 then
		state.body_flip_target_speed_204 = f32(PERFECT_FLIP_NUMERATOR / state.collision_time_196)
	else
		state.body_flip_target_speed_204 = f32(f32(settings.flip_scalar / state.collision_time_196) * NEGATIVE_TWO_PI)
	end
	state.selector_vector_128 = runtime:selector_vector_2848()

	local heading = { 0.0, 0.0, 0.0, 0.0 }
	local heading_valid = false
	state.collision_normal_speed_176 = 0.0
	if state.collision_time_196 >= 0.0 then
		local collision_frame = prediction.collision_frame_128
		local previous_time = f32(f32(rt.to_i32(collision_frame - 2)) * FIXED_STEP)
		local collision_time = f32(f32(rt.to_i32(collision_frame - 1)) * FIXED_STEP)
		local previous = trajectory_position(prediction.trajectory, previous_time)
		local collision = trajectory_position(prediction.trajectory, collision_time)
		local delta = sub(collision, previous)
		local velocity = runtime:divide_vector_by_scalar(delta, FIXED_STEP)

		state.collision_normal_speed_176 = runtime:dot3(state.landing_normal_64, velocity)
		local normal_velocity = mul_scalar(state.landing_normal_64, state.collision_normal_speed_176)
		local tangent = sub(velocity, normal_velocity)
		local normalized, length = runtime:normalize_safe_with_length(tangent)
		if not (settings.min_target_heading_velocity_420 > length) then
			heading = normalized
			heading_valid = true
		end
	end

	state.landing_heading_80 = heading
	state.landing_heading_valid_209 = heading_valid
	local heading_length_squared = runtime:dot3(heading, heading)
	if HEADING_LENGTH_SQUARED_MIN > heading_length_squared then
		state.landing_heading_valid_209 = false
	end
end

-- Ground transition velocity restoration, TU3 `0x82D35998`.
function trajectory.restore_velocity(state: data.KnownAirState, frame: data.KnownAirFrame, settings: data.KnownAirSettings, runtime: any)
	local prediction = runtime:selected_prediction()
	if state.trajectory_index_216 == 0 then
		state.trajectory_index_216 = 1
	end

	local sample_time = f32(f32(state.trajectory_index_216) * FIXED_STEP)
	local tv = trajectory_velocity(prediction.trajectory, sample_time)
	local geometry = runtime:restore_velocity_geometry_82d35998(tv, frame.ground_normal_464)
	local curve_value = point_graph.PointGraph.evaluate(settings.landing_speed_scalar_vs_ground_normal_y_240, geometry.landing_speed_curve_input)
	local lower_clamped = select(-geometry.landing_speed_blend_source, 0.0, geometry.landing_speed_blend_source)
	local blend_weight = select(f32(ONE - lower_clamped), lower_clamped, ONE)
	local speed_scale = mul_add(f32(curve_value - ONE), blend_weight, ONE)
	local scaled_tangent = mul_scalar(geometry.tangential_velocity, speed_scale)
	local current_board_velocity = runtime:board_body_velocity()
	local preserved_normal_speed = runtime:dot3(current_board_velocity, frame.ground_normal_464)
	local restored = {}
	for lane = 1, 4 do
		restored[lane] = mul_add(frame.ground_normal_464[lane], preserved_normal_speed, scaled_tangent[lane])
	end
	runtime:set_board_velocity(restored)

	local forward = runtime:board_forward_axis()
	frame.forward_speed_2612 = runtime:dot3(restored, forward)
end

-- `PhysState_KnownAir::UpdateTrajectoryFollow`, TU3 `0x82D36460`.
function trajectory.update_trajectory_follow(state: data.KnownAirState, frame: data.KnownAirFrame, settings: data.KnownAirSettings, runtime: any)
	state.trajectory_index_216 = rt.to_i32(state.trajectory_index_216 + 1)

	local ratio = f32(f32(settings.trajectory_error_blend_away_time_384 - state.time_in_state_180) / settings.trajectory_error_blend_away_time_384)
	local lower_clamped = select(-ratio, 0.0, ratio)
	local blend = select(f32(ONE - lower_clamped), lower_clamped, ONE)
	local sample_time = f32(f32(state.trajectory_index_216) * FIXED_STEP)
	local t = runtime:selector_trajectory_2704()
	local position = trajectory_position(t, sample_time)
	local target = {}
	for lane = 1, 4 do
		target[lane] = mul_add(state.trajectory_follow_offset_144[lane], blend, position[lane])
	end
	state.target_com_position_160 = target

	if bit32.btest(frame.flags_2468, 0x0000_0008) then
		state.trajectory_index_216 = rt.to_i32(state.trajectory_index_216 - 1)
	end
end

return trajectory
