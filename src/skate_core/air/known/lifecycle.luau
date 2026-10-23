--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/air/known/lifecycle.rs (коммит 2e16697)
--
-- TU3 KnownAir entry and exit lifecycle.

local data = require("./data")
local trajectory = require("./trajectory")

local lifecycle = {}

-- `PhysState_KnownAir::Enter`, TU3 `0x82D352D0`.
function lifecycle.enter(
	state: data.KnownAirState,
	frame: data.KnownAirFrame,
	settings: data.KnownAirSettings,
	mode: data.KnownAirModeSettings,
	runtime: any
)
	runtime:enable_board_angular_drive_only()
	runtime:set_air_collision_update_enabled(true)
	runtime:set_skeleton_collision_state(7)
	runtime:set_skeleton_physics_truck_tilt_enabled(false)
	runtime:set_skeleton_inverse_kinematics_enabled(true)

	state.body_flipping_211 = false
	state.grind_air_adjust_activated_212 = false
	state.targeting_grind_213 = false
	runtime:reset_reckoning_flipping()
	runtime:set_footplant_flag_240(false)
	runtime:reset_footplants()

	state.reached_apex_208 = false
	state.time_in_state_180 = 0.0
	state.start_y_184 = frame.start_height_484
	state.max_y_188 = runtime:board_transform_height()
	state.com_max_y_192 = runtime:skeleton_com_position()[2]

	trajectory.init_trajectory_info(state, frame, settings, mode, runtime)

	if runtime:selector_targeting_grind() then
		runtime:start_grind_air_adjust_from_selector()
		state.targeting_grind_213 = true
	end

	local skeleton_com = runtime:skeleton_com_position()
	-- ZERO_VECTOR 0x830BD350.
	local index, offset = runtime:selector_closest_trajectory_point(skeleton_com, { 0.0, 0.0, 0.0, 0.0 })
	state.trajectory_index_216 = index
	state.trajectory_follow_offset_144 = offset

	state.start_flipped_210 = 0.0 > runtime:dot3(frame.velocity_400, frame.start_flip_reference_96)
end

-- `PhysState_KnownAir::Exit`, TU3 `0x82D35920`.
function lifecycle.exit(
	state: data.KnownAirState,
	frame: data.KnownAirFrame,
	settings: data.KnownAirSettings,
	reckoning: data.KnownAirReckoningFields,
	runtime: any
)
	runtime:reset_reckoning_flipping()
	if frame.next_physics_state_2500 == 100 then
		trajectory.restore_velocity(state, frame, settings, runtime)
	end
	runtime:reset_trajectory_selector()
	reckoning.body_spin_speed_1572 = 0.0
	reckoning.body_spin_angle_1568 = 0.0
	runtime:set_grind_air_adjust_started(false)
	runtime:set_grind_air_adjust_activated(false)
end

return lifecycle
