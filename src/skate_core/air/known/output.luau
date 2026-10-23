--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/air/known/output.rs (коммит 2e16697)
--
-- TU3 KnownAir PhysOut publication.

local rt = require("../../../rt")
local data = require("./data")
local trajectory = require("./trajectory")

local f32 = rt.f32
local from_bits = rt.from_bits
local add, sub = trajectory.add, trajectory.sub
local trajectory_position, trajectory_velocity = trajectory.trajectory_position, trajectory.trajectory_velocity

local output_mod = {}

local FIXED_STEP = from_bits(0x3C88_8889) -- 0x820849C8, 1/60.
local MAX_FINITE = from_bits(0x7F7F_FFFF) -- 0x8206D108.

-- `PhysState_KnownAir::FillPhysOut`, TU3 `0x82D36880`.
function output_mod.fill_physics_output(state: data.KnownAirState, frame: data.KnownAirFrame, output: data.KnownAirOutput, runtime: any)
	local prediction = runtime:selected_prediction()
	if bit32.btest(frame.flags_2468, 0x0000_0008) then
		output.locked_trajectory_velocity_valid_452 = true
		local time = f32(f32(state.trajectory_index_216) * FIXED_STEP)
		output.locked_trajectory_velocity_160 = trajectory_velocity(prediction.trajectory, time)
	end

	output.reached_apex_436 = state.reached_apex_208
	output.jump_height_200 = f32(state.max_y_188 - state.start_y_184)
	output.trajectory_apex_0 = state.trajectory_apex_96
	output.time_to_apex_196 = state.time_to_apex_200
	output.collision_position_16 = state.collision_position_112
	output.landing_normal_32 = state.landing_normal_64
	output.landing_normal_copy_144 = state.landing_normal_64
	output.time_until_collision_184 = if bit32.btest(frame.flags_2468, 0x0000_0008)
		then MAX_FINITE
		else f32(state.collision_time_196 - state.time_in_state_180)
	output.time_in_state_176 = state.time_in_state_180
	output.selector_vector_48 = state.selector_vector_128

	local output_index = math.max(state.trajectory_index_216, 1)
	output.trajectory_position_64 = trajectory_position(prediction.trajectory, f32(f32(output_index) * FIXED_STEP))
	output.landing_heading_80 = state.landing_heading_80
	output.collision_normal_speed_188 = state.collision_normal_speed_176
	output.known_air_valid_437 = true
	output.selected_trajectory_240 = table.clone(prediction.trajectory)
	output.trajectory_index_220 = state.trajectory_index_216

	local selector_com = runtime:selector_com_position_2784()
	output.selector_com_position_96 = selector_com
	output.collision_time_180 = state.collision_time_196
	local com_transform = runtime:reckoning_com_transform_816()
	local local_com = runtime:transform_point_82d36880(com_transform, selector_com)
	local first_sample = math.max(rt.to_i32(state.trajectory_index_216 - 1), 0)
	local samples = {}
	for sample_offset = 0, 24 do
		local sample_index = rt.to_i32(first_sample + sample_offset)
		local sample = trajectory_position(prediction.trajectory, f32(f32(sample_index) * FIXED_STEP))
		local relative = sub(add(sample, local_com), state.collision_position_112)
		samples[sample_offset + 1] = runtime:dot3(relative, state.landing_normal_64)
	end
	output.trajectory_plane_samples_336 = samples
end

return output_mod
