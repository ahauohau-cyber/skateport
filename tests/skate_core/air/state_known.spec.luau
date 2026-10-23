--!strict
--!nolint SameLineStatement
-- air::state (PhysicsAir), air::known (KnownAir), air::ground_jump:
-- перенос Rust-тестов с поддельными runtime (state/tests, known/tests) и
-- сверка математики с настоящим Rust (golden/src/gjump.rs).

local harness = require("../../harness")
local u = require("../../util")
local rt = require("../../../src/rt")
local air_state = require("../../../src/skate_core/air/state")
local known = require("../../../src/skate_core/air/known")
local ground_jump = require("../../../src/skate_core/air/ground_jump")
local golden = require("../../golden/gjump") :: any
assert(type(golden) == "table", tostring(golden))

local f32 = rt.f32

local function check(d: string?, what: string)
	if d then
		error(what .. d, 2)
	end
end
-- ROBLOX: assert_eq! сравнивает f32 через == (-0.0 == 0.0).
local function eq(a: any, b: any): boolean
	if type(b) == "table" then
		if type(a) ~= "table" or #a ~= #b then
			return false
		end
		for k, v in b do
			if not eq(a[k], v) then
				return false
			end
		end
		return true
	end
	return a == b
end
local function close(a: number, b: number)
	assert(math.abs(a - b) < 0.00001, string.format("%g != %g", a, b))
end
local function index_of(list: { string }, value: string): number
	local i = table.find(list, value)
	assert(i, "нет вызова " .. value)
	return i :: number
end
local function flat(value: number): any
	return { x = { 0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0 }, y = table.create(8, f32(value)) }
end
local function sumsq(v: { number }): number
	return f32(f32(f32(v[1] * v[1]) + f32(v[2] * v[2])) + f32(v[3] * v[3]))
end

----------------------------------------------------------------------------
-- air::state — FakeRuntime из state/tests/mod.rs
----------------------------------------------------------------------------
local function fake_launch_info(): any
	local info = {
		start_velocity = { 0.0, 0.0, 0.0, 0.0 },
		animation_position = { 0.0, 0.0, 0.0, 0.0 },
		trajectory_override = { 0.0, 0.0, 0.0, 0.0 },
		board_override = { 0.0, 0.0, 0.0, 0.0 },
		cone = { 0.0, 0.0 }, -- ROBLOX: поле cone_angles в Rust; имя занято методом.
		jumped_writes = {},
		use_override = false,
		trajectory_count = 0,
	}
	function info.set_start_velocity(self: any, v: any) self.start_velocity = v end
	function info.centre_of_mass_animation_position(self: any): any return self.animation_position end
	function info.set_trajectory_start_position_override(self: any, p: any) self.trajectory_override = p end
	function info.set_board_position_override(self: any, p: any) self.board_override = p end
	function info.cone_angles(self: any): any return self.cone end
	function info.set_cone_angles(self: any, a: any) self.cone = a end
	function info.set_player_jumped(self: any, j: boolean) table.insert(self.jumped_writes, j) end
	function info.set_use_trajectory_start_position_override(self: any, e: boolean) self.use_override = e end
	function info.set_trajectory_count(self: any, c: number) self.trajectory_count = c end
	return info
end
local function air_reckoning(): any
	return {
		current_landing_normal_1152 = { 0.0, 1.0, 0.0, 0.0 },
		collision_reference_normal_1216 = { 0.0, 0.0, 1.0, 0.0 },
		body_spin_angle_1568 = 2.0,
		body_spin_speed_1572 = 3.0,
	}
end
local function fake_runtime(fields: any?): any
	local r: any = {
		events = {},
		board_height = 0.0,
		board_velocity = { 0.0, 0.0, 0.0, 0.0 },
		query_started = false,
		selector_normal = nil,
		selector_com_ready = false,
		angle = 0.0,
		collision = false,
		collision_force = air_state.AirBoardForce.ZERO(),
		enqueued_force = nil,
		set_velocity = nil,
		launched = nil,
		reckoning_call = nil,
		reckoning_output = air_reckoning(),
		collision_reference = nil,
		known_air_position = nil,
		forced_squared_length = nil,
		forced_length = nil,
		forced_clamp = nil,
	}
	if fields then
		for k, v in fields do
			r[k] = v
		end
	end
	local function ev(self: any, e: string) table.insert(self.events, e) end
	function r.minimum_vminfp(_self: any, a: number, b: number): number return if a < b then a else b end
	function r.length_squared_vmsum3fp(self: any, v: any): number
		if self.forced_squared_length ~= nil then return self.forced_squared_length end
		return sumsq(v)
	end
	function r.length_vmsum3fp_vrsqrte(self: any, v: any): number
		if self.forced_length ~= nil then return self.forced_length end
		return f32(math.sqrt(sumsq(v)))
	end
	function r.clamp_vector_within_max_length(self: any, v: any, maximum: number): any
		if self.forced_clamp ~= nil then return self.forced_clamp end
		local length = f32(math.sqrt(sumsq(v)))
		if length > maximum then
			local s = f32(maximum / length)
			return { f32(v[1] * s), f32(v[2] * s), f32(v[3] * s), f32(v[4] * s) }
		end
		return v
	end
	function r.set_air_collision_update_enabled(self: any, e: boolean) ev(self, "collision-enabled:" .. tostring(e)) end
	function r.set_skeleton_collision_state(self: any, s: number) ev(self, "collision-state:" .. s) end
	function r.set_skeleton_inverse_kinematics_enabled(self: any, e: boolean) ev(self, "ik:" .. tostring(e)) end
	function r.enable_board_angular_drive_only(self: any) ev(self, "angular-drive") end
	function r.set_footplant_flag_240(self: any, v: boolean) ev(self, "footplant-240:" .. tostring(v)) end
	function r.reset_footplants(self: any) ev(self, "footplant-reset") end
	function r.board_transform_height(self: any): number ev(self, "board-height") return self.board_height end
	function r.request_skeleton_heading_update(self: any) ev(self, "heading") end
	function r.update_air_collision(self: any) ev(self, "air-collision") end
	function r.trajectory_query_just_started(self: any): boolean return self.query_started end
	function r.construct_trajectory_launch_info(self: any): any ev(self, "launch-construct") return fake_launch_info() end
	function r.fill_skeleton_launch_info(self: any, info: any)
		ev(self, "launch-fill")
		info.animation_position = { 10.0, 20.0, 30.0, 40.0 }
		info.cone = { 2.0, 4.0 }
	end
	function r.launch_trajectory(self: any, info: any) ev(self, "launch") self.launched = info end
	function r.update_trajectory_selector(self: any) ev(self, "selector-update") end
	function r.selector_landing_normal(self: any): any return self.selector_normal end
	function r.selector_centre_of_mass_trajectory_ready(self: any): boolean return self.selector_com_ready end
	function r.angle_between_vectors(self: any, _a: any, _b: any): number ev(self, "angle") return self.angle end
	function r.update_reckoning_air_states(self: any, n: any, b: number, s: number, fl: number): any
		ev(self, "reckoning")
		self.reckoning_call = { n, b, s, fl }
		return table.clone(self.reckoning_output)
	end
	function r.update_known_air_skeleton(self: any, p: any) ev(self, "known-air") self.known_air_position = p end
	function r.update_animated_skateboard_skeleton(self: any, a: boolean) ev(self, "animated-board:" .. tostring(a)) end
	function r.update_board_steering_tilt(self: any, t: number) ev(self, "steering-tilt:" .. string.format("%g", t)) end
	function r.calculate_air_collision_force(self: any, n: any, force: any): boolean
		ev(self, "collision-force")
		self.collision_reference = n
		force.force_world = self.collision_force.force_world
		force.point_board_local = self.collision_force.point_board_local
		return self.collision
	end
	function r.enqueue_board_force(self: any, tag: number, force: any) ev(self, "enqueue-force") self.enqueued_force = { tag, force } end
	function r.set_board_velocity(self: any, v: any) ev(self, "set-board-velocity") self.set_velocity = v end
	function r.enable_skateboard_error_on_skeleton(self: any) ev(self, "board-error") end
	function r.board_body_velocity(self: any): any ev(self, "board-velocity") return self.board_velocity end
	function r.check_for_air_wipeout(self: any, a: boolean) ev(self, "wipeout:" .. tostring(a)) end
	return r
end
local function air_frame(): any
	return {
		current_velocity_400 = { 1.0, 2.0, 3.0, 0.0 },
		ground_position_y_500 = 4.0,
		trajectory_position_592 = { 1.0, 5.0, 2.0, 0.0 },
		trajectory_velocity_608 = { 2.0, 10.0, 4.0, 0.0 },
		jump_velocity_848 = { 2.0, 8.0, 4.0, 0.0 },
		flags_2468 = 0,
		previous_physics_state_2504 = 500,
		previous_physics_category_2516 = 0,
		frames_since_jump_correction_2576 = 12,
		delta_time_2604 = f32(0.1),
		body_spin_input_2640 = 3.0,
		gravity_y_2648 = -10.0,
		state_timer_2664 = 1.0,
	}
end
local function air_state_value(): any
	return {
		centre_of_mass_trajectory = {
			position = table.create(4, 90.0),
			velocity = table.create(4, 80.0),
			acceleration = table.create(4, 70.0),
			scalar_48 = 60.0,
		},
		landing_normal = table.create(4, 9.0),
		time_in_state = 9.0,
		start_y = 9.0,
		max_y = 9.0,
		reached_apex = true,
		use_centre_of_mass_velocity = false,
		selector_latch_174 = true,
		trajectory_query_countdown = 9,
	}
end
local function air_settings(): any
	return {
		body_spin_over_time_320 = { x = { 0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0 }, y = table.create(8, 2.0) },
		landing_normal_blend_388 = 0.25,
		body_spin_scale_428 = 4.0,
		landing_normal_angle_limit_444 = 1.0,
	}
end

----------------------------------------------------------------------------
-- air::known — MockRuntime из known/tests/mock.rs
----------------------------------------------------------------------------
local function k_trajectory(): any
	return { position = { 0.0, 0.0, 0.0, 0.0 }, velocity = { 0.0, 0.0, 0.0, 0.0 }, acceleration = { 0.0, 0.0, 0.0, 0.0 }, scalar_48 = 1.0, word_52 = 0, word_56 = 0, word_60 = 0 }
end
local function k_state(): any
	local z = function() return { 0.0, 0.0, 0.0, 0.0 } end
	return {
		landing_normal_64 = { 0.0, 1.0, 0.0, 0.0 }, landing_heading_80 = { 1.0, 0.0, 0.0, 0.0 }, trajectory_apex_96 = z(),
		collision_position_112 = z(), selector_vector_128 = z(), trajectory_follow_offset_144 = z(), target_com_position_160 = z(),
		collision_normal_speed_176 = 0.0, time_in_state_180 = 0.0, start_y_184 = 0.0, max_y_188 = 0.0, com_max_y_192 = 0.0,
		collision_time_196 = 1.0, time_to_apex_200 = 0.0, body_flip_target_speed_204 = 0.0, reached_apex_208 = false,
		landing_heading_valid_209 = false, start_flipped_210 = false, body_flipping_211 = false, grind_air_adjust_activated_212 = false,
		targeting_grind_213 = false, trajectory_index_216 = 0,
	}
end
local function k_frame(): any
	local z = function() return { 0.0, 0.0, 0.0, 0.0 } end
	return {
		start_flip_reference_96 = z(), alternate_head_target_112 = z(), velocity_400 = z(), ground_normal_464 = { 0.0, 1.0, 0.0, 0.0 },
		start_height_484 = 0.0, skater_up_544 = { 0.0, 1.0, 0.0, 0.0 }, flags_2468 = 0, flags_2472 = 0, flags_2476 = 0, flags_2480 = 0,
		flags_2484 = 0, flags_2488 = 0, next_physics_state_2500 = 0, delta_time_2604 = f32(1.0 / 60.0), forward_speed_2612 = 0.0,
		body_spin_input_2640 = 0.0, selector_landing_normal_2656 = { 0.0, 1.0, 0.0, 0.0 },
	}
end
local function k_settings(): any
	return {
		max_heading_adjust_vs_up_y_160 = flat(180.0), landing_speed_scalar_vs_ground_normal_y_240 = flat(1.0),
		flip_start_collision_time_vs_normal_y = flat(10.0), trajectory_error_blend_away_time_384 = 1.0,
		min_target_heading_velocity_420 = f32(0.1), min_auto_body_speed_424 = f32(0.01), max_spin_speed_428 = 360.0,
		frames_for_grind_air_assist_436 = 4.0, body_flip_min_grab_time_fraction_456 = 0.25, flip_scalar = 1.0,
	}
end
local function k_mode(): any
	return { upside_down_falling_wipeout_enabled_2 = true, perfect_body_flips_28 = false, body_spin_speed_limit_56 = 20.0 }
end
local function k_reckoning(): any
	return { landing_normal_1152 = { 0.0, 1.0, 0.0, 0.0 }, heading_axis_1200 = { 1.0, 0.0, 0.0, 0.0 }, body_spin_angle_1568 = 0.0, body_spin_speed_1572 = 0.0 }
end
local function k_output(): any
	local z = function() return { 0.0, 0.0, 0.0, 0.0 } end
	return {
		trajectory_apex_0 = z(), collision_position_16 = z(), landing_normal_32 = z(), selector_vector_48 = z(), trajectory_position_64 = z(),
		landing_heading_80 = z(), selector_com_position_96 = z(), landing_normal_copy_144 = z(), locked_trajectory_velocity_160 = z(),
		time_in_state_176 = 0.0, collision_time_180 = 0.0, time_until_collision_184 = 0.0, collision_normal_speed_188 = 0.0,
		time_to_apex_196 = 0.0, jump_height_200 = 0.0, trajectory_index_220 = 0, selected_trajectory_240 = k_trajectory(),
		trajectory_plane_samples_336 = table.create(25, 0.0), reached_apex_436 = false, known_air_valid_437 = false,
		locked_trajectory_velocity_valid_452 = false,
	}
end
local function mock_runtime(): any
	local z = function() return { 0.0, 0.0, 0.0, 0.0 } end
	local r: any = {
		calls = {},
		prediction = { trajectory = k_trajectory(), collision_time_48 = 1.0, collision_frame_128 = 2 },
		selector_trajectory = k_trajectory(), contact = z(), selector_vector = z(), selector_com = z(),
		highest = { z(), 0.0 }, board_y = 0.0, com = z(), targeting_grind = false, closest = { 0, z() },
		grind_started = false, grind_adjusting = false, board_velocity = z(), written_board_velocity = z(),
		forward = { 1.0, 0.0, 0.0, 0.0 }, signed_angle = 0.0,
		restore_geometry = { tangential_velocity = z(), landing_speed_curve_input = 0.0, landing_speed_blend_source = 0.0 },
	}
	local function call(self: any, s: string) table.insert(self.calls, s) end
	function r.dot3(_self: any, a: any, b: any): number return f32(f32(f32(a[1] * b[1]) + f32(a[2] * b[2])) + f32(a[3] * b[3])) end
	function r.divide_vector_by_scalar(_self: any, v: any, s: number): any return { f32(v[1] / s), f32(v[2] / s), f32(v[3] / s), f32(v[4] / s) } end
	function r.normalize_safe_with_length(_self: any, v: any): (any, number)
		local length = f32(math.sqrt(sumsq(v)))
		if length == 0.0 then return { 0.0, 0.0, 0.0, 0.0 }, 0.0 end
		return { f32(v[1] / length), f32(v[2] / length), f32(v[3] / length), f32(v[4] / length) }, length
	end
	function r.signed_angle_about_axis(self: any, _a: any, _b: any, _c: any): number call(self, "math.signed_angle") return self.signed_angle end
	function r.wrap_angle_8258db98(self: any, a: number): number call(self, "math.wrap") return a end
	function r.restore_velocity_geometry_82d35998(self: any, _a: any, _b: any): any call(self, "math.restore_geometry") return self.restore_geometry end
	function r.transform_point_82d36880(_self: any, _t: any, p: any): any return p end
	function r.enable_board_angular_drive_only(self: any) call(self, "board.angular_only") end
	function r.set_air_collision_update_enabled(self: any, v: boolean) call(self, "collision.enabled:" .. tostring(v)) end
	function r.set_skeleton_collision_state(self: any, v: number) call(self, "collision.state:" .. v) end
	function r.set_skeleton_physics_truck_tilt_enabled(self: any, v: boolean) call(self, "skeleton.truck_tilt:" .. tostring(v)) end
	function r.set_skeleton_inverse_kinematics_enabled(self: any, v: boolean) call(self, "skeleton.ik:" .. tostring(v)) end
	function r.reset_reckoning_flipping(self: any) call(self, "reckoning.reset_flip") end
	function r.set_footplant_flag_240(self: any, v: boolean) call(self, "footplant.flag:" .. tostring(v)) end
	function r.reset_footplants(self: any) call(self, "footplant.reset") end
	function r.board_transform_height(self: any): number call(self, "board.height") return self.board_y end
	function r.skeleton_com_position(self: any): any call(self, "skeleton.com") return self.com end
	function r.selector_targeting_grind(self: any): boolean return self.targeting_grind end
	function r.start_grind_air_adjust_from_selector(self: any) call(self, "grind.start") end
	function r.selector_closest_trajectory_point(self: any, _a: any, _b: any): (number, any) call(self, "selector.closest") return self.closest[1], self.closest[2] end
	function r.selected_prediction(self: any): any return self.prediction end
	function r.selector_trajectory_2704(self: any): any return self.selector_trajectory end
	function r.selector_contact_position(self: any): any call(self, "selector.contact") return self.contact end
	function r.selector_vector_2848(self: any): any return self.selector_vector end
	function r.selector_com_position_2784(self: any): any return self.selector_com end
	function r.highest_trajectory_position(self: any, _t: any): (any, number) call(self, "trajectory.highest") return self.highest[1], self.highest[2] end
	function r.selector_has_just_changed(_self: any): boolean return false end
	function r.reset_trajectory_selector(self: any) call(self, "selector.reset") end
	function r.begin_reckoning_body_flip(self: any, side: boolean) call(self, "reckoning.begin_flip:" .. tostring(side)) end
	function r.update_air_collision(self: any) call(self, "collision.update") end
	function r.grind_air_adjust_started(self: any): boolean return self.grind_started end
	function r.set_grind_air_adjust_started(self: any, v: boolean) call(self, "grind.started:" .. tostring(v)) end
	function r.set_grind_air_adjust_activated(self: any, v: boolean) call(self, "grind.activated:" .. tostring(v)) end
	function r.grind_air_adjust_adjusting(self: any): boolean return self.grind_adjusting end
	function r.disable_grind_foot_collision(self: any, body: string) call(self, "grind.disable:" .. string.sub(body, 5)) end
	function r.update_reckoning_air_states(self: any, _a: any, _b: number, _c: number, _d: number) call(self, "reckoning.update_air") end
	function r.update_known_air_skeleton(self: any, _p: any) call(self, "skeleton.update_known_air") end
	function r.set_skeleton_add_skateboard_error(self: any, v: boolean) call(self, "skeleton.board_error:" .. tostring(v)) end
	function r.set_head_tracking_target(self: any, _t: any, valid: boolean) call(self, "head.target:" .. tostring(valid)) end
	function r.update_board_steering_tilt(self: any, _t: number) call(self, "board.steering_zero") end
	function r.shift_footplant_trajectory_to_index(self: any, _t: any, _i: number) call(self, "footplant.shift") end
	function r.update_footplant_prediction(self: any, _i: any) call(self, "footplant.prediction") end
	function r.update_footplant_lock(self: any, _i: any) call(self, "footplant.lock") end
	function r.update_footplant_pose(self: any, _i: any) call(self, "footplant.pose") end
	function r.board_body_velocity(self: any): any call(self, "board.velocity") return self.board_velocity end
	function r.set_board_velocity(self: any, v: any) call(self, "board.set_velocity") self.written_board_velocity = v end
	function r.board_forward_axis(self: any): any call(self, "board.forward") return self.forward end
	function r.check_for_air_wipeout(self: any, v: boolean) call(self, "wipeout.check:" .. tostring(v)) end
	function r.reckoning_com_transform_816(_self: any): any return { vectors = { { 0.0, 0.0, 0.0, 0.0 }, { 0.0, 0.0, 0.0, 0.0 }, { 0.0, 0.0, 0.0, 0.0 }, { 0.0, 0.0, 0.0, 0.0 } } } end
	return r
end

return function(report: harness.Report)
	-- air::state tests
	harness.test(report, "air/state: enter_preserves_order_and_offboard_velocity_rule", function()
		local state, frame = air_state_value(), air_frame()
		local runtime = fake_runtime({ board_height = 6.0 })
		air_state.enter(state, frame, { 0.0, -9.0, 0.0, 0.0 }, runtime)
		check(u.diff(runtime.events, {
			"collision-enabled:true", "collision-state:7", "ik:true", "collision-state:6", "angular-drive",
			"footplant-240:false", "footplant-reset", "board-height", "heading",
		}), "events")
		assert(state.use_centre_of_mass_velocity)
		assert(eq(state.centre_of_mass_trajectory.velocity, { 2.0, 3.0, 4.0, 0.0 }))
		assert(eq(state.landing_normal, { 0.0, 1.0, 0.0, 0.0 }))
		assert(state.start_y == 4.0 and state.max_y == 6.0)
		assert(not state.reached_apex and not state.selector_latch_174)
		assert(state.trajectory_query_countdown == 0)
	end)
	harness.test(report, "air/state: category_400_can_select_com_without_requesting_heading", function()
		local state, frame = air_state_value(), air_frame()
		frame.previous_physics_category_2516 = 400
		frame.previous_physics_state_2504 = 100
		local runtime = fake_runtime()
		air_state.enter(state, frame, { 0.0, 0.0, 0.0, 0.0 }, runtime)
		assert(state.use_centre_of_mass_velocity)
		assert(table.find(runtime.events, "heading") == nil)
	end)
	harness.test(report, "air/state: jump_velocity_uses_current_vertical_and_clamped_current_horizontal", function()
		local frame = air_frame()
		frame.current_velocity_400 = { 10.0, 4.0, 0.0, 7.0 }
		frame.jump_velocity_848 = { 2.0, 10.0, 0.0, 5.0 }
		local runtime = fake_runtime({ forced_squared_length = 64.0, forced_length = 2.0, forced_clamp = { 2.0, 0.0, 0.0, 99.0 } })
		assert(eq(air_state.calculate_velocity_from_jump(frame, 2, runtime), { 2.0, 4.0, 0.0, 5.0 }))
	end)
	harness.test(report, "air/state: update_runs_com_launch_and_fixed_step_in_native_order", function()
		local state = air_state_value()
		state.use_centre_of_mass_velocity = true
		state.selector_latch_174 = false
		state.trajectory_query_countdown = 0
		state.time_in_state = 0.25
		state.max_y = 5.0
		state.centre_of_mass_trajectory = { position = { 1.0, 2.0, 3.0, 0.0 }, velocity = { 4.0, 5.0, 6.0, 0.0 }, acceleration = { 0.0, -6.0, 0.0, 0.0 }, scalar_48 = -1.0 }
		local frame = air_frame()
		local out = air_reckoning()
		out.collision_reference_normal_1216 = { 1.0, 0.0, 0.0, 0.0 }
		local runtime = fake_runtime({ board_height = 7.0, selector_normal = { 0.0, f32(0.8), f32(0.2), 0.0 }, reckoning_output = out })
		air_state.update(state, frame, air_settings(), air_reckoning(), { 0.0, -6.0, 0.0, 0.0 }, runtime)
		check(u.diff(runtime.events, {
			"air-collision", "launch-construct", "launch-fill", "launch-fill", "launch", "selector-update", "angle",
			"reckoning", "known-air", "steering-tilt:0", "collision-force", "board-error", "board-height",
		}), "events")
		local launch = runtime.launched
		check(u.diff(launch.jumped_writes, { true, false }), "jumped")
		assert(eq(launch.trajectory_override, { 10.0, f32(19.35), 30.0, 40.0 }))
		assert(eq(launch.board_override, { 10.0, f32(19.2), 30.0, 40.0 }))
		assert(eq(launch.cone, { f32(0.8), f32(1.6) }))
		assert(launch.use_override)
		assert(launch.trajectory_count == 5)
		assert(state.trajectory_query_countdown == 7)
		assert(state.max_y == 7.0)
		assert(state.time_in_state == f32(0.35))
		assert(eq(runtime.collision_reference, { 1.0, 0.0, 0.0, 0.0 }), "Board collision used the pre-update reckoning normal")
	end)
	harness.test(report, "air/state: skateboard_collision_force_wins_over_direct_velocity_correction", function()
		local force = { force_world = { 1.0, 2.0, 3.0, 4.0 }, point_board_local = { 5.0, 6.0, 7.0, 8.0 } }
		local runtime = fake_runtime({ collision = true, collision_force = force })
		local frame = air_frame()
		frame.frames_since_jump_correction_2576 = 0
		air_state.update_skateboard(air_state_value(), frame, air_reckoning(), runtime)
		assert(runtime.enqueued_force[1] == 15)
		assert(eq(runtime.enqueued_force[2], force))
		assert(runtime.set_velocity == nil)
	end)
	harness.test(report, "air/state: skateboard_miss_applies_jump_velocity_only_before_frame_twelve", function()
		local state = air_state_value()
		state.use_centre_of_mass_velocity = false
		local frame = air_frame()
		frame.frames_since_jump_correction_2576 = 2
		frame.current_velocity_400 = { 2.0, 4.0, 4.0, 0.0 }
		frame.jump_velocity_848 = { 2.0, 10.0, 4.0, 0.0 }
		local runtime = fake_runtime({ forced_squared_length = 0.0 })
		air_state.update_skateboard(state, frame, air_reckoning(), runtime)
		assert(eq(runtime.set_velocity, { 2.0, 4.0, 4.0, 0.0 }))
		check(u.diff(runtime.events, { "steering-tilt:0", "collision-force", "set-board-velocity" }), "events")
	end)
	harness.test(report, "air/state: post_physics_latches_only_strict_downward_velocity_then_checks_wipeout", function()
		local state = air_state_value()
		state.reached_apex = false
		local runtime = fake_runtime({ board_velocity = { 0.0, -0.0, 0.0, 0.0 } })
		air_state.update_post_physics(state, runtime)
		assert(not state.reached_apex)
		runtime.board_velocity[2] = f32(-0.01)
		air_state.update_post_physics(state, runtime)
		assert(state.reached_apex)
		check(u.diff(runtime.events, { "board-velocity", "wipeout:false", "board-velocity", "wipeout:false" }), "events")
	end)
	harness.test(report, "air/state: exit_and_output_publish_only_recovered_fields", function()
		local state = air_state_value()
		state.max_y = 9.0
		state.start_y = 4.0
		state.reached_apex = true
		state.selector_latch_174 = true
		state.landing_normal = { 1.0, 2.0, 3.0, 4.0 }
		local reckoning = air_reckoning()
		local output = air_state.fill_physics_output(state)
		assert(output.jump_height == 5.0)
		assert(rt.to_bits(output.scalar_184_write :: number) == 0x4080_0000)
		assert(eq(output.landing_normal, { 1.0, 2.0, 3.0, 4.0 }))
		air_state.exit(state, reckoning)
		assert(not state.use_centre_of_mass_velocity)
		assert(reckoning.body_spin_angle_1568 == 0.0 and reckoning.body_spin_speed_1572 == 0.0)
	end)
	harness.test(report, "air/state: angle_wrap_uses_recovered_turn_constants", function()
		assert(rt.to_bits(air_state.wrap_signed_angle(0.0)) == rt.to_bits(0.0))
		assert(air_state.wrap_signed_angle(4.0) < 0.0)
		assert(air_state.wrap_signed_angle(2.0) > 0.0)
	end)

	-- air::known tests
	harness.test(report, "air/known: init_trajectory_info_builds_stock_landing_values", function()
		local state, frame, settings, mode, runtime = k_state(), k_frame(), k_settings(), k_mode(), mock_runtime()
		frame.selector_landing_normal_2656 = { 0.0, 1.0, 0.0, 0.0 }
		settings.flip_scalar = 0.5
		settings.min_target_heading_velocity_420 = 0.5
		runtime.prediction.trajectory.velocity = { 3.0, 4.0, 0.0, 0.0 }
		runtime.prediction.trajectory.scalar_48 = 9.0
		runtime.prediction.collision_time_48 = 2.0
		runtime.prediction.collision_frame_128 = 3
		runtime.contact = { 9.0, 8.0, 7.0, 0.0 }
		runtime.selector_vector = { 6.0, 5.0, 4.0, 0.0 }
		runtime.highest = { { 1.0, 12.0, 3.0, 0.0 }, 0.75 }
		known.init_trajectory_info(state, frame, settings, mode, runtime)
		assert(eq(state.trajectory_apex_96, runtime.highest[1]))
		assert(state.time_to_apex_200 == 0.75)
		assert(eq(state.collision_position_112, runtime.contact))
		assert(eq(state.selector_vector_128, runtime.selector_vector))
		close(state.collision_normal_speed_176, 4.0)
		assert(eq(state.landing_heading_80, { 1.0, 0.0, 0.0, 0.0 }))
		assert(state.landing_heading_valid_209)
		close(state.body_flip_target_speed_204, -math.pi / 2)
	end)
	harness.test(report, "air/known: init_negative_collision_clears_speed_and_heading_validity", function()
		local state, runtime = k_state(), mock_runtime()
		state.collision_normal_speed_176 = 99.0
		state.landing_heading_valid_209 = true
		runtime.prediction.collision_time_48 = -1.0
		known.init_trajectory_info(state, k_frame(), k_settings(), k_mode(), runtime)
		assert(state.collision_normal_speed_176 == 0.0)
		assert(eq(state.landing_heading_80, { 0.0, 0.0, 0.0, 0.0 }))
		assert(not state.landing_heading_valid_209)
	end)
	harness.test(report, "air/known: enter_preserves_recovered_effect_order_and_initializes_heights", function()
		local state, frame, runtime = k_state(), k_frame(), mock_runtime()
		frame.start_height_484 = 3.0
		frame.velocity_400 = { -1.0, 0.0, 0.0, 0.0 }
		frame.start_flip_reference_96 = { 1.0, 0.0, 0.0, 0.0 }
		runtime.board_y = 4.0
		runtime.com = { 0.0, 5.0, 0.0, 0.0 }
		runtime.targeting_grind = true
		runtime.closest = { 11, { 0.25, 0.0, 0.0, 0.0 } }
		known.enter(state, frame, k_settings(), k_mode(), runtime)
		assert(state.start_y_184 == 3.0 and state.max_y_188 == 4.0 and state.com_max_y_192 == 5.0)
		assert(state.trajectory_index_216 == 11)
		assert(eq(state.trajectory_follow_offset_144, runtime.closest[2]))
		assert(state.targeting_grind_213 and state.start_flipped_210)
		check(u.diff(table.move(runtime.calls, 1, 9, 1, {}), {
			"board.angular_only", "collision.enabled:true", "collision.state:7", "skeleton.truck_tilt:false", "skeleton.ik:true",
			"reckoning.reset_flip", "footplant.flag:false", "footplant.reset", "board.height",
		}), "calls")
		assert(table.find(runtime.calls, "grind.start"))
	end)
	harness.test(report, "air/known: exit_restores_velocity_before_selector_and_grind_cleanup", function()
		local state, frame, settings, reckoning, runtime = k_state(), k_frame(), k_settings(), k_reckoning(), mock_runtime()
		state.trajectory_index_216 = 0
		frame.next_physics_state_2500 = 100
		settings.landing_speed_scalar_vs_ground_normal_y_240 = flat(2.0)
		reckoning.body_spin_angle_1568 = 2.0
		reckoning.body_spin_speed_1572 = 3.0
		runtime.restore_geometry = { tangential_velocity = { 2.0, 0.0, 0.0, 0.0 }, landing_speed_curve_input = 0.0, landing_speed_blend_source = 0.5 }
		runtime.board_velocity = { 0.0, 1.0, 0.0, 0.0 }
		known.exit(state, frame, settings, reckoning, runtime)
		assert(state.trajectory_index_216 == 1)
		assert(eq(runtime.written_board_velocity, { 3.0, 1.0, 0.0, 0.0 }))
		assert(frame.forward_speed_2612 == 3.0)
		assert(reckoning.body_spin_speed_1572 == 0.0 and reckoning.body_spin_angle_1568 == 0.0)
		local c = runtime.calls
		assert(index_of(c, "reckoning.reset_flip") < index_of(c, "board.set_velocity"))
		assert(index_of(c, "board.set_velocity") < index_of(c, "selector.reset"))
		assert(index_of(c, "selector.reset") < index_of(c, "grind.started:false"))
	end)
	harness.test(report, "air/known: update_runs_footplant_grind_and_publication_in_native_order", function()
		local state, frame, runtime = k_state(), k_frame(), mock_runtime()
		state.time_in_state_180 = f32(0.2)
		state.collision_time_196 = 0.25
		state.reached_apex_208 = true
		state.targeting_grind_213 = true
		state.trajectory_index_216 = 4
		frame.flags_2480 = 0x0400_0000
		runtime.grind_started = true
		runtime.grind_adjusting = true
		runtime.board_y = 7.0
		runtime.com = { 0.0, 8.0, 0.0, 0.0 }
		known.update(state, frame, k_settings(), k_mode(), k_reckoning(), runtime)
		assert(state.grind_air_adjust_activated_212)
		assert(state.trajectory_index_216 == 5)
		close(state.time_in_state_180, 0.2 + frame.delta_time_2604)
		assert(state.max_y_188 == 7.0 and state.com_max_y_192 == 8.0)
		local bodies = {}
		for _, c in runtime.calls do
			if string.sub(c, 1, 14) == "grind.disable:" then
				table.insert(bodies, string.sub(c, 15))
			end
		end
		check(u.diff(bodies, { "3152", "3156", "3160", "3168", "3172", "3176" }), "bodies")
		local c = runtime.calls
		assert(index_of(c, "footplant.shift") < index_of(c, "collision.update"))
		assert(index_of(c, "collision.update") < index_of(c, "reckoning.update_air"))
		assert(index_of(c, "reckoning.update_air") < index_of(c, "skeleton.update_known_air"))
		assert(index_of(c, "skeleton.update_known_air") < index_of(c, "head.target:true"))
		assert(index_of(c, "head.target:true") < index_of(c, "board.steering_zero"))
	end)
	harness.test(report, "air/known: trajectory_follow_uses_selector_2704_and_honors_locked_index", function()
		local state, frame, runtime = k_state(), k_frame(), mock_runtime()
		state.trajectory_index_216 = 0
		state.time_in_state_180 = 2.0
		frame.flags_2468 = 0x8
		runtime.prediction.trajectory.position = { 100.0, 0.0, 0.0, 0.0 }
		runtime.selector_trajectory.position = { 10.0, 0.0, 0.0, 0.0 }
		known.update_trajectory_follow(state, frame, k_settings(), runtime)
		assert(state.trajectory_index_216 == 0)
		assert(eq(state.target_com_position_160, { 10.0, 0.0, 0.0, 0.0 }))
	end)
	harness.test(report, "air/known: auto_spin_uses_recovered_alignment_chain_and_manual_gate", function()
		local state, frame, settings, runtime = k_state(), k_frame(), k_settings(), mock_runtime()
		state.landing_heading_valid_209 = true
		state.collision_time_196 = 1.0
		runtime.signed_angle = 0.5
		close(known.calculate_body_spin_speed(state, frame, settings, k_mode(), k_reckoning(), runtime), 0.6)
		frame.body_spin_input_2640 = 1.0
		frame.flags_2472 = 0
		runtime.calls = {}
		assert(known.calculate_body_spin_speed(state, frame, settings, k_mode(), k_reckoning(), runtime) == 0.0)
		assert(table.find(runtime.calls, "math.signed_angle") == nil)
	end)
	harness.test(report, "air/known: body_flip_starts_only_after_stock_flag_and_curve_gates", function()
		local state, frame, settings, runtime = k_state(), k_frame(), k_settings(), mock_runtime()
		state.collision_time_196 = 2.0
		state.body_flip_target_speed_204 = -3.0
		frame.flags_2468 = bit32.bor(0x20, 0x80)
		settings.flip_start_collision_time_vs_normal_y = flat(1.0)
		local speed = known.calculate_body_flip_speed(state, frame, settings, k_mode(), k_reckoning(), runtime)
		assert(state.body_flipping_211)
		assert(speed == -3.0)
		assert(table.find(runtime.calls, "reckoning.begin_flip:true"))
		state.body_flipping_211 = false
		frame.flags_2488 = 0x0200_0000
		runtime.calls = {}
		known.calculate_body_flip_speed(state, frame, settings, k_mode(), k_reckoning(), runtime)
		assert(not state.body_flipping_211)
		assert(#runtime.calls == 0)
	end)
	harness.test(report, "air/known: post_physics_sets_apex_then_requests_upside_down_wipeout", function()
		local state, frame, runtime = k_state(), k_frame(), mock_runtime()
		frame.skater_up_544 = { 0.0, -1.0, 0.0, 0.0 }
		local request = { requested_35 = false, scalar_116 = 9.0, counter_200 = 4 }
		runtime.board_velocity = { 0.0, -2.0, 0.0, 0.0 }
		known.update_post_physics(state, frame, k_mode(), { air_falling_min_up_y_260 = 0.0, air_falling_max_angle_264 = 0.0 }, request, runtime)
		assert(state.reached_apex_208)
		assert(request.requested_35 and request.scalar_116 == 0.0 and request.counter_200 == 5)
		assert(runtime.calls[1] == "board.velocity" and runtime.calls[2] == "wipeout.check:true")
	end)
	harness.test(report, "air/known: output_writes_all_samples_and_preserves_conditional_fields", function()
		local state, runtime, output = k_state(), mock_runtime(), k_output()
		state.trajectory_index_216 = 2
		state.collision_position_112 = { 1.0, 0.0, 0.0, 0.0 }
		state.landing_normal_64 = { 1.0, 0.0, 0.0, 0.0 }
		state.max_y_188 = 7.0
		state.start_y_184 = 2.0
		state.collision_time_196 = 3.0
		state.time_in_state_180 = 1.0
		output.locked_trajectory_velocity_valid_452 = true
		output.locked_trajectory_velocity_160 = table.create(4, 9.0)
		runtime.prediction.trajectory.velocity = { 60.0, 0.0, 0.0, 0.0 }
		runtime.selector_trajectory.position = { 999.0, 0.0, 0.0, 0.0 }
		known.fill_physics_output(state, k_frame(), output, runtime)
		assert(eq(output.locked_trajectory_velocity_160, table.create(4, 9.0)))
		assert(output.locked_trajectory_velocity_valid_452)
		assert(output.jump_height_200 == 5.0 and output.time_until_collision_184 == 2.0)
		assert(output.trajectory_position_64[1] == 2.0)
		assert(output.trajectory_plane_samples_336[1] == 0.0)
		close(output.trajectory_plane_samples_336[25], 24.0)
		assert(output.known_air_valid_437)
	end)

	-- golden
	harness.test(report, "air/ground_jump.calculate + air/state математика vs Rust", function()
		for n, c in golden.jump do
			check(u.diff(ground_jump.calculate(c.input, c.mode, c.settings), c.out), "jump#" .. n)
		end
		local AirMath = air_state.AirMath
		for n, c in golden.math do
			local w = "math#" .. n
			check(u.diff(AirMath.minimum_vminfp(AirMath, c.maximum, c.angle_in), c.min), w .. " min")
			check(u.diff(AirMath.length_squared_vmsum3fp(AirMath, c.a), c.length_squared), w .. " length_squared")
			check(u.diff(AirMath.length_vmsum3fp_vrsqrte(AirMath, c.a), c.length), w .. " length")
			check(u.diff(AirMath.clamp_vector_within_max_length(AirMath, c.a, c.maximum), c.clamp), w .. " clamp")
			check(u.diff(air_state.clamp_jump_velocity(c.a, c.b), c.clamp_jump), w .. " clamp_jump")
			check(u.diff(air_state.angle_between_vectors(c.a, c.b), c.angle), w .. " angle")
			check(u.diff(air_state.wrap_signed_angle(c.angle_in), c.wrap), w .. " wrap")
			check(u.diff(air_state.calculate_velocity_from_jump(c.frame, c.frames, AirMath), c.from_jump), w .. " from_jump")
			local t = table.clone(c.trajectory_in)
			air_state.integrate_trajectory_fixed_step(t)
			check(u.diff(t, c.trajectory_out), w .. " integrate")
		end
	end)
end
