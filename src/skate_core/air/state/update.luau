--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/air/state/update.rs (коммит 2e16697)
--
-- TU3 PhysicsAir Update (`0x82D346C0`) and COM launch helper (`0x82D34570`).
-- ROBLOX: runtime/info — таблицы с методами (вызов через двоеточие).

local rt = require("../../../rt")
local point_graph = require("../../point_graph")
local data = require("./data")
local board = require("./board")
local jump_velocity = require("./jump_velocity")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits

type Vector4 = data.Vector4

local update_mod = {}

local FIXED_STEP = from_bits(0x3C88_8889) -- 1/60, 0x82098D40
local HALF = from_bits(0x3F00_0000)
local ONE = from_bits(0x3F80_0000)
local TRAJECTORY_UNBOUNDED = from_bits(0xBF80_0000)
local TWO = from_bits(0x4000_0000)
local DEGREES_TO_RADIANS = from_bits(0x3C8E_FA35)
local TWO_PI = from_bits(0x40C9_0FDB)
local RECIPROCAL_TWO_PI = from_bits(0x3E22_F983)
local HALF_TURN = from_bits(0x3F00_0000)
local COM_START_Y_OFFSET = from_bits(0xBF26_6666) -- -0.65
local BOARD_START_Y_OFFSET = from_bits(0xBF4C_CCCD) -- -0.8
local CONE_SCALE = from_bits(0x3ECC_CCCD) -- 0.4

-- Scalar wrap at `0x82D347E8..0x82D34848`, after AngleBetweenVectors.
function update_mod.wrap_signed_angle(angle: number): number
	local turns = f32(angle * RECIPROCAL_TWO_PI)
	local fraction = f32(turns - math.floor(turns))
	local signed_fraction = if fraction > HALF_TURN then f32(fraction - ONE) else fraction
	return f32(signed_fraction * TWO_PI)
end

-- Fixed 1/60 ballistic step at `0x82D349B8..0x82D34A20`.
function update_mod.integrate_trajectory_fixed_step(trajectory: data.AirTrajectory)
	local step_squared = f32(FIXED_STEP * FIXED_STEP)
	local half = f32(ONE * HALF)
	local next_position, next_velocity = {}, {}
	for lane = 1, 4 do
		local linear = mul_add(trajectory.velocity[lane], FIXED_STEP, trajectory.position[lane])
		next_velocity[lane] = mul_add(trajectory.acceleration[lane], FIXED_STEP, trajectory.velocity[lane])
		next_position[lane] = mul_add(f32(trajectory.acceleration[lane] * half), step_squared, linear)
	end
	trajectory.position = next_position
	trajectory.velocity = next_velocity
end

local function adjust_centre_of_mass_launch_info(state: data.PhysicsAirState, world_acceleration: Vector4, runtime: any, info: any)
	runtime:fill_skeleton_launch_info(info)

	local velocity = {}
	for lane = 1, 4 do
		velocity[lane] = mul_add(world_acceleration[lane], FIXED_STEP, state.centre_of_mass_trajectory.velocity[lane])
	end
	info:set_start_velocity(velocity)
	info:set_player_jumped(true)

	local p = info:centre_of_mass_animation_position()
	local trajectory_offset = { 0.0, COM_START_Y_OFFSET, 0.0, 0.0 }
	local board_offset = { 0.0, BOARD_START_Y_OFFSET, 0.0, 0.0 }
	local t, b = {}, {}
	for lane = 1, 4 do
		t[lane] = f32(p[lane] + trajectory_offset[lane])
		b[lane] = f32(p[lane] + board_offset[lane])
	end
	info:set_trajectory_start_position_override(t)
	info:set_board_position_override(b)
	info:set_use_trajectory_start_position_override(true)
	info:set_trajectory_count(5)

	local cone_angles = info:cone_angles()
	info:set_cone_angles({ f32(cone_angles[1] * CONE_SCALE), f32(cone_angles[2] * CONE_SCALE) })
end

local function launch_trajectory(state: data.PhysicsAirState, frame: data.PhysicsAirFrame, world_acceleration: Vector4, runtime: any)
	local info = runtime:construct_trajectory_launch_info()
	runtime:fill_skeleton_launch_info(info)
	if frame.frames_since_jump_correction_2576 < 12 then
		local velocity = jump_velocity.calculate_velocity_from_jump(frame, frame.frames_since_jump_correction_2576, runtime)
		info:set_start_velocity(velocity)
	elseif state.use_centre_of_mass_velocity then
		adjust_centre_of_mass_launch_info(state, world_acceleration, runtime, info)
	end

	-- The caller always clears +268, including after the COM helper sets it.
	info:set_player_jumped(false)
	runtime:launch_trajectory(info)
end

-- Full recovered outer update, retaining native effect order.
-- ROBLOX: reckoning: &mut — `*reckoning = ...` переписывает поля той же таблицы.
function update_mod.update(
	state: data.PhysicsAirState,
	frame: data.PhysicsAirFrame,
	settings: data.PhysicsAirSettings,
	reckoning: data.PhysicsAirReckoningFields,
	world_acceleration: Vector4,
	runtime: any
)
	runtime:update_air_collision()

	-- ROBLOX: i32::wrapping_sub(1).
	state.trajectory_query_countdown = rt.to_i32(state.trajectory_query_countdown - 1)
	if
		state.trajectory_query_countdown <= 0
		and not bit32.btest(frame.flags_2468, 0x0000_8000)
		and frame.previous_physics_state_2504 ~= 0
		and not runtime:trajectory_query_just_started()
	then
		launch_trajectory(state, frame, world_acceleration, runtime)
		state.trajectory_query_countdown = 7
	end

	runtime:update_trajectory_selector()

	local current_normal = reckoning.current_landing_normal_1152
	local selected = runtime:selector_landing_normal()
	local landing_normal = if selected ~= nil then selected else current_normal
	state.landing_normal = landing_normal

	local raw_angle = runtime:angle_between_vectors(landing_normal, current_normal)
	local wrapped_angle = update_mod.wrap_signed_angle(raw_angle)
	local normal_blend = if wrapped_angle <= settings.landing_normal_angle_limit_444 then settings.landing_normal_blend_388 else 0.0

	if not state.use_centre_of_mass_velocity then
		if not state.selector_latch_174 then
			state.selector_latch_174 = runtime:selector_centre_of_mass_trajectory_ready()
		end
		if state.selector_latch_174 then
			state.use_centre_of_mass_velocity = true
			state.centre_of_mass_trajectory = {
				position = frame.trajectory_position_592,
				velocity = frame.trajectory_velocity_608,
				acceleration = world_acceleration,
				scalar_48 = TRAJECTORY_UNBOUNDED,
			}
		end
	end

	if frame.state_timer_2664 <= 0.0 then
		normal_blend = 0.0
	elseif bit32.btest(frame.flags_2468, 0x0000_4000) then
		state.use_centre_of_mass_velocity = false
	end

	local scaled_spin_input = f32(frame.body_spin_input_2640 * settings.body_spin_scale_428)
	local spin_radians = f32(scaled_spin_input * DEGREES_TO_RADIANS)
	local curve = point_graph.PointGraph.evaluate(settings.body_spin_over_time_320, f32(state.time_in_state * TWO))
	local target_body_spin = f32(curve * spin_radians)
	local fields = runtime:update_reckoning_air_states(landing_normal, normal_blend, target_body_spin, 0.0)
	reckoning.current_landing_normal_1152 = fields.current_landing_normal_1152
	reckoning.collision_reference_normal_1216 = fields.collision_reference_normal_1216
	reckoning.body_spin_angle_1568 = fields.body_spin_angle_1568
	reckoning.body_spin_speed_1572 = fields.body_spin_speed_1572

	if state.use_centre_of_mass_velocity then
		update_mod.integrate_trajectory_fixed_step(state.centre_of_mass_trajectory)
		runtime:update_known_air_skeleton(state.centre_of_mass_trajectory.position)
	else
		runtime:update_animated_skateboard_skeleton(false)
	end

	board.update_skateboard(state, frame, reckoning, runtime)
	runtime:enable_skateboard_error_on_skeleton()

	local board_y = runtime:board_transform_height()
	-- fcmpu+bgt keeps the old value only for an ordered old > new result;
	-- unordered values take the board-height write.
	if not (state.max_y > board_y) then
		state.max_y = board_y
	end
	state.time_in_state = f32(state.time_in_state + frame.delta_time_2604)
end

return update_mod
