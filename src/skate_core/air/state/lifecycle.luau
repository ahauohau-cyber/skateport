--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/air/state/lifecycle.rs (коммит 2e16697)
--
-- TU3 PhysicsAir Enter/Exit/output lifecycle.

local rt = require("../../../rt")
local data = require("./data")
local jump_velocity = require("./jump_velocity")

local f32 = rt.f32
local from_bits = rt.from_bits

local lifecycle = {}

local TRAJECTORY_UNBOUNDED = from_bits(0xBF80_0000) -- -1.0
local OFFBOARD_VERTICAL_SCALE = from_bits(0x3F26_6666) -- 0.65
local OFFBOARD_VERTICAL_LIMIT = from_bits(0x4040_0000) -- 3.0
local OUTPUT_SCALAR_184 = from_bits(0x4080_0000) -- 4.0

-- ROBLOX: кортеж (bool, bool) -> два значения.
local function initial_centre_of_mass_mode(frame: data.PhysicsAirFrame): (boolean, boolean)
	if frame.previous_physics_category_2516 == 400 or frame.previous_physics_state_2504 == 701 then
		return not bit32.btest(frame.flags_2468, 0x0000_4000), false
	end
	local s = frame.previous_physics_state_2504
	local selected = not (s == 100 or s == 103 or s == 201)
	return selected, selected
end

-- Full TU3 `PhysState_PhysicsAir::Enter`, `0x82D34388`.
function lifecycle.enter(state: data.PhysicsAirState, frame: data.PhysicsAirFrame, world_acceleration: data.Vector4, runtime: any)
	runtime:set_air_collision_update_enabled(true)
	runtime:set_skeleton_collision_state(7)
	runtime:set_skeleton_inverse_kinematics_enabled(true)
	runtime:set_skeleton_collision_state(6)
	runtime:enable_board_angular_drive_only()
	runtime:set_footplant_flag_240(false)
	runtime:reset_footplants()

	state.selector_latch_174 = false
	state.reached_apex = false
	state.trajectory_query_countdown = 0
	state.landing_normal = { 0.0, 1.0, 0.0, 0.0 }
	state.time_in_state = 0.0
	state.max_y = runtime:board_transform_height()
	state.start_y = frame.ground_position_y_500

	local use_centre_of_mass_velocity, request_heading_update = initial_centre_of_mass_mode(frame)
	state.use_centre_of_mass_velocity = use_centre_of_mass_velocity

	if use_centre_of_mass_velocity then
		local velocity = table.clone(frame.trajectory_velocity_608)
		if frame.previous_physics_state_2504 == 500 then
			local scaled_y = f32(velocity[2] * OFFBOARD_VERTICAL_SCALE)
			velocity[2] = runtime:minimum_vminfp(scaled_y, OFFBOARD_VERTICAL_LIMIT)
		end
		if frame.frames_since_jump_correction_2576 < 12 then
			velocity = jump_velocity.calculate_velocity_from_jump(frame, frame.frames_since_jump_correction_2576, runtime)
		end
		state.centre_of_mass_trajectory = {
			position = frame.trajectory_position_592,
			velocity = velocity,
			acceleration = world_acceleration,
			scalar_48 = TRAJECTORY_UNBOUNDED,
		}
	end

	-- This branch-local flag deliberately differs from the COM selection in
	-- the grind/category-400 path.
	if request_heading_update then
		runtime:request_skeleton_heading_update()
	end
end

-- TU3 `PhysState_PhysicsAir::Exit`, `0x82D346A0`.
function lifecycle.exit(state: data.PhysicsAirState, reckoning: data.PhysicsAirReckoningFields)
	state.use_centre_of_mass_velocity = false
	reckoning.body_spin_speed_1572 = 0.0
	reckoning.body_spin_angle_1568 = 0.0
end

-- TU3 `PhysState_PhysicsAir::FillPhysOut`, `0x82D34E90`.
function lifecycle.fill_physics_output(state: data.PhysicsAirState): data.PhysicsAirOutput
	return {
		is_at_apex = state.reached_apex,
		jump_height = f32(state.max_y - state.start_y),
		landing_normal = state.landing_normal,
		scalar_184_write = if state.selector_latch_174 then OUTPUT_SCALAR_184 else nil,
	}
end

return lifecycle
