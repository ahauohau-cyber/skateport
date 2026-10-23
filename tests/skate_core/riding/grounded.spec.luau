--!strict
-- Сверка physics/manual, riding/ground_contact_response и riding/grounded
-- с настоящим skate-core (golden/src/grounded.rs): board.update с теми же
-- детерминированными сервисами-заглушками, что в эталоне, вывод FillPhysOut,
-- математика motion. Плюс перенос Rust-тестов этих модулей.

local harness = require("../../harness")
local u = require("../../util")
local rt = require("../../../src/rt")
local angle = require("../../../src/skate_core/physics/manual/angle")
local controller = require("../../../src/skate_core/physics/manual/controller")
local manual_state = require("../../../src/skate_core/physics/manual/state")
local force_queue = require("../../../src/skate_core/physics/force_queue")
local cr = require("../../../src/skate_core/riding/collision_response")
local gcm = require("../../../src/skate_core/riding/ground_correction_math")
local gcr = require("../../../src/skate_core/riding/ground_contact_response")
local speed_wobble = require("../../../src/skate_core/riding/speed_wobble")
local steering = require("../../../src/skate_core/riding/steering")
local grounded = require("../../../src/skate_core/riding/grounded")
local golden = require("../../golden/grounded") :: any

local f32 = rt.f32
local ManualState = manual_state.ManualState
local data = grounded.state.data
local board = grounded.state.board
local output = grounded.state.output
local motion = grounded.state.motion
local corrections = grounded.state.corrections
local contact_state = grounded.state.contact_state
local update_mod = grounded.state.update
local Q = force_queue.BoardForceQueue

local function xyz(v: { number }): vector
	return vector.create(v[1], v[2], v[3])
end
local function check(d: string?, what: string)
	if d then
		error(what .. d, 2)
	end
end

-- Те же заглушки, что struct Mock в golden/src/grounded.rs.
local function mock(m: any): any
	local self = { events = {}, vectors = {} }
	local function ev(s: string)
		table.insert(self.events, s)
	end
	function self:angle_between(d, z, x)
		ev("angle")
		return cr.signed_angle(xyz(d), xyz(z), xyz(x))
	end
	function self:dot3(a, b)
		ev("dot3")
		return gcm.dot_product(a, b)
	end
	function self:scale_to_magnitude(v, sq, mg)
		ev("scale")
		return gcm.scale_to_magnitude(v, sq, mg)
	end
	function self:build_hang_force()
		ev("build_hang")
		return gcm.hang_force(m.edge[1], m.edge[2], m.edge[3])
	end
	function self:apply_hang_force(f)
		ev("apply_hang")
		table.insert(self.vectors, f)
	end
	function self:detect_hung_up_geometry()
		ev("detect_hung")
		return m.hung
	end
	function self:request_wipeout()
		ev("wipeout")
	end
	function self:angular_displacement()
		ev("catch_disp")
		return gcm.wheel_catch_displacement(m.deck_y, m.deck_z)
	end
	function self:apply_angular_displacement(v)
		ev("catch_apply")
		table.insert(self.vectors, v)
	end
	function self:pin_to_captured_position(x, z)
		ev("pin")
		table.insert(self.vectors, { x, 0.0, z, 0.0 })
	end
	function self:center_of_mass_height_82d38838()
		ev("com_height")
		return m.com_height
	end
	function self:set_contact_wheel_materials()
		ev("wheel_materials")
	end
	function self:contact_response_82d93df0(frame, prev)
		ev("contact_response")
		return gcr.wall_ride_response(m.wall, m.wall_physical, frame, prev)
	end
	function self:update_body_accumulator_82d389dc()
		ev("accumulator")
	end
	function self:set_animated_velocity_82c04168(v)
		ev("set_animated_velocity")
		table.insert(self.vectors, v)
	end
	function self:write_processed_velocity_400(v)
		ev("write_velocity")
		table.insert(self.vectors, v)
	end
	function self:build_animated_pose_82d33448()
		ev("build_pose")
		return 7
	end
	function self:publish_animated_pose_82be33d0(p)
		ev("publish_pose" .. p)
	end
	function self:update_external_player_82d67848(p, v)
		ev("external" .. p)
		table.insert(self.vectors, v)
	end
	function self:commit_external_player_82d68800()
		ev("commit_external")
	end
	function self:finalize_animated_board_sk83_na_f_01a4()
		ev("finalize")
	end
	function self:collision_force_82d944e8(v)
		ev("collision_force")
		table.insert(self.vectors, v)
		return m.collision
	end
	function self:collision_force_dot_velocity_82d38e18(f, v)
		ev("collision_dot")
		return gcm.collision_force_projection(f, v)
	end
	function self:apply_vector_82c07000(v)
		ev("apply_vector")
		table.insert(self.vectors, v)
	end
	function self:apply_angular_displacement_82c075b8(v)
		ev("apply_angular")
		table.insert(self.vectors, v)
	end
	return self
end

local Angle = {
	angle_between = function(_self: any, d: { number }, z: { number }, x: { number }): (number?, any)
		return cr.signed_angle(xyz(d), xyz(z), xyz(x)), nil
	end,
}

return function(report: harness.Report)
	harness.test(report, "manual/angle: 2000 normalize vs Rust", function()
		for i, c in golden.angle do
			local v, err = angle.normalize(c[1])
			if c[2] == false then
				assert(v == nil and err == angle.IntegerConversionUnavailable, "случай " .. i .. ": нет ошибки")
			else
				check(u.diff(v, c[2]), "случай " .. i)
			end
		end
	end)

	harness.test(report, "manual/controller: 120 × 25 calculate + enter_ground vs Rust", function()
		for ci, c in golden.manual do
			local state = ManualState.new()
			for si, st in c.steps do
				local effect = assert(controller.calculate(state, c.settings, c.mode, st.input, Angle :: any))
				check(u.diff(effect, st.effect), string.format("случай %d шаг %d: effect", ci, si))
				check(u.diff(state, st.state), string.format("случай %d шаг %d: state", ci, si))
			end
			for ei, e in c.entry do
				check(u.diff(state, e[3]), "entry before " .. ei)
				local cont = ManualState.enter_ground(state, e[1], e[2])
				assert((cont == manual_state.ManualEntryContinuation.RemoveVelocityIntoGround) == e[4], "entry continuation " .. ei)
				check(u.diff(state, e[5]), string.format("случай %d entry %d", ci, ei))
			end
		end
	end)

	harness.test(report, "ground_contact_response: 1500 wall_ride_response vs Rust", function()
		for i, c in golden.wall do
			check(u.diff(gcr.wall_ride_response(c[1], c[2], c[3], c[4]), c[5]), "случай " .. i)
		end
	end)

	harness.test(report, "grounded/board: 25 × 20 update (обычная, анимация, столкновение) vs Rust", function()
		for ci, c in golden.board do
			local state = data.PhysicsGroundState.clone(c.init.state)
			local wob = speed_wobble.SpeedWobbleState.new()
			local truck = steering.TruckSteeringState.default()
			local sm = { target_speed = c.init.target_speed, flags_1360 = 0 }
			local mstate = ManualState.new()
			local heading_prev = { value = 0.0 }
			local inertias = {}
			for i, k in c.init.inertias do
				inertias[i] = { linear_drag = k.linear_drag }
			end
			for ti, tick in c.ticks do
				local services = mock(tick.mock)
				local queue = force_queue.BoardForceQueue.default()
				local components = {
					speed_wobble = wob, truck_steering = truck, speed_model = sm, manual = mstate, heading_previous = heading_prev,
					force_queue = queue, inertias = { part_inertia_indices = c.init.indices, inertias = inertias },
				}
				local outcome, err = board.update(state, components, c.settings, tick.input, services)
				assert(outcome, "ошибка " .. tostring(err and (err.stage or err.kind)))
				local w = tick.out
				local where = string.format("случай %d тик %d: ", ci, ti)
				check(u.diff(outcome, w.outcome), where .. "outcome")
				check(u.diff(services.events, w.events), where .. "events")
				check(u.diff(services.vectors, w.vectors), where .. "vectors")
				check(u.diff(state, w.state), where .. "state")
				check(u.diff(Q.entries(queue), w.queue), where .. "queue")
				check(u.diff(wob.words, w.wobble), where .. "wobble")
				check(u.diff(truck, w.truck), where .. "truck")
				check(u.diff(sm, w.speed_model), where .. "speed_model")
				check(u.diff(mstate, w.manual), where .. "manual")
				check(u.diff(heading_prev.value, w.heading_previous), where .. "heading")
				local drags = {}
				for i, k in inertias do
					drags[i] = k.linear_drag
				end
				check(u.diff(drags, w.drags), where .. "drag")
			end
		end
	end)

	harness.test(report, "grounded/output: 500 fill_physics_output vs Rust", function()
		for i, c in golden.output do
			check(u.diff(output.fill_physics_output(c.state, c.frame, c.settings), c.out), "случай " .. i)
		end
	end)

	harness.test(report, "grounded/motion: 800 × 4 функций vs Rust", function()
		for i, c in golden.motion do
			local inp = c.input
			local q = force_queue.BoardForceQueue.default()
			for _, f in inp.forces do
				Q.append(q, f)
			end
			check(u.diff(motion.entry_angular_velocity(inp.normal, inp.angular), c.out.entry_angular_velocity), i .. " angular")
			check(u.diff(motion.entry_target_speed(inp.velocity, inp.normal, inp.forward), c.out.entry_target_speed), i .. " speed")
			check(u.diff(motion.landing_on_deck_force(inp.physical, inp.animation, inp.normal, inp.mass, inp.strength, inp.point_y), c.out.landing), i .. " landing")
			local fut = motion.future_deck_displacement(q, inp.mass, inp.dt, inp.normal, inp.pushing, inp.manual_correction)
			assert((fut == nil) == (c.out.future == nil), i .. " future nil")
			if fut then
				check(u.diff(fut, c.out.future), i .. " future")
			end
		end
	end)

	-- Перенос Rust-тестов grounded/state/contact_state.rs
	local function cs_services(initial: any, identified: any): any
		local s = { events = {}, initial = initial, identified = identified, published = "none" }
		function s:stop_contact_tracking_82d62f20() table.insert(self.events, "stop") end
		function s:clear_inactive_contact_output_3024() table.insert(self.events, "clear") end
		function s:initial_contact_handle_1920() table.insert(self.events, "initial") return self.initial end
		function s:identify_contact_82d63c30(_f) table.insert(self.events, "identify") return self.identified end
		function s:publish_contact_82d61268(_f, retained) table.insert(self.events, "publish") self.published = retained end
		return s
	end
	local function cs_input(): any
		return { flags_2476 = 0x0040_0000, flags_2480 = 0x1000_0000, velocity_400 = { 1, 1, 1, 1 }, axis_464 = { 0, 0.5, 0, 0 },
			contact_position_560 = { 2, 2, 2, 2 }, trajectory_position_592 = { 3, 3, 3, 3 }, reckoning_vector_1200 = { 4, 4, 4, 4 }, differing_contact_frame_limit = 5 }
	end
	harness.test(report, "contact_state: inactive_branch_preserves_history_and_runs_both_owner_calls", function()
		local history = { differing_contact_frames_2756 = 7, tracked_contact_2760 = 9 }
		local frame = cs_input()
		frame.flags_2476 = 0
		local s = cs_services(nil, nil)
		assert(contact_state.update(history, frame, s))
		assert(table.concat(s.events, ",") == "stop,clear" and history.differing_contact_frames_2756 == 7 and history.tracked_contact_2760 == 9)
	end)
	harness.test(report, "contact_state: candidate_latches_initial_handle_then_counts_identity_changes", function()
		local history = data.GroundContactHistory.empty()
		local s = cs_services(10, 11)
		assert(contact_state.update(history, cs_input(), s))
		assert(table.concat(s.events, ",") == "initial,identify,publish" and history.differing_contact_frames_2756 == 1 and history.tracked_contact_2760 == 10 and s.published == 10)
	end)
	harness.test(report, "contact_state: limit_and_axis_rejection_clear_only_the_native_fields", function()
		local history = { differing_contact_frames_2756 = 5, tracked_contact_2760 = 10 }
		local frame = cs_input()
		local s = cs_services(nil, 11)
		assert(contact_state.update(history, frame, s))
		assert(history.differing_contact_frames_2756 == 6 and history.tracked_contact_2760 == nil and s.published == nil)
		history.differing_contact_frames_2756, history.tracked_contact_2760 = 13, 12
		frame.axis_464[2] = f32(0.95)
		s.events = {}
		s.published = "none"
		assert(contact_state.update(history, frame, s))
		assert(history.differing_contact_frames_2756 == 13 and history.tracked_contact_2760 == nil and table.concat(s.events, ",") == "publish")
	end)

	-- Перенос Rust-тестов grounded/state/corrections.rs
	local function nudge_state(): any
		local st = data.PhysicsGroundState.before_first_enter(false)
		st.anti_flip_torque_2624 = { 1, 0, 0, 0 }
		st.steering_push_scalar_2640 = 1.0
		st.straighten_scale_2672 = 1.0
		st.anti_flip_nudge_frames_2752 = 13
		return st
	end
	local function nudge_math(dots: { number }): any
		local m = { dots = dots, dot_count = 0, scale_count = 0 }
		function m:dot3(_a, _b) self.dot_count += 1 return self.dots[self.dot_count] end
		function m:scale_to_magnitude(v, _sq, mg) self.scale_count += 1 return { v[1] * mg, v[2] * mg, v[3] * mg, v[4] * mg } end
		return m
	end
	harness.test(report, "corrections: nudge_unordered_comparisons_take_the_native_rejection_paths", function()
		local st = nudge_state()
		local q = Q.default()
		local m = nudge_math({ 0 / 0, 1.0 })
		local r1 = assert(corrections.update_anti_flip_nudge(st, { deck_speed_2652 = 0.0, deck_axis_96 = { 1, 0, 0, 0 } }, q, m))
		assert(st.anti_flip_nudge_frames_2752 == 0 and not r1.attempted)
		st.anti_flip_nudge_frames_2752 = 13
		m.dots, m.dot_count = { 1.0, 0 / 0 }, 0
		local r2 = assert(corrections.update_anti_flip_nudge(st, { deck_speed_2652 = 0.0, deck_axis_96 = { 1, 0, 0, 0 } }, q, m))
		assert(not r2.attempted and m.scale_count == 0)
	end)
	harness.test(report, "corrections: nudge_latches_presence_even_when_the_native_queue_is_full", function()
		local st = nudge_state()
		local q = Q.default()
		for _ = 1, force_queue.FORCE_CAPACITY do
			assert(Q.append(q, { tag = 0, force_world = vector.zero, point_body = vector.zero }))
		end
		local m = nudge_math({ 1.0, 1.0 })
		local r = assert(corrections.update_anti_flip_nudge(st, { deck_speed_2652 = 0.0, deck_axis_96 = { 1, 0, 0, 0 } }, q, m))
		assert(r.attempted and not r.queued and st.anti_flip_nudge_applied_2723 and #Q.entries(q) == force_queue.FORCE_CAPACITY)
	end)

	-- Перенос Rust-тестов grounded/state/update.rs
	local function up_services(collision_signal: boolean): any
		local s = { events = {}, collision_signal = collision_signal }
		local function ev(x: string) table.insert(s.events, x) end
		function s:height(_n, _c) ev("pumping-height") return 2.0 end
		function s:speed() return nil, "unexpected speed" end
		function s:angular_speed() return nil, "unexpected angular speed" end
		function s:inclination_radians() return nil, "unexpected inclination" end
		function s:stop_contact_tracking_82d62f20() ev("contact-stop") end
		function s:clear_inactive_contact_output_3024() ev("contact-clear") end
		function s:initial_contact_handle_1920() ev("contact-initial") return nil end
		function s:identify_contact_82d63c30(_f) ev("contact-identify") return nil end
		function s:publish_contact_82d61268(_f, _r) ev("contact-publish") end
		function s:set_elapsed_skeleton_flag() ev("elapsed-flag") end
		function s:pumping_frame()
			ev("pumping-frame")
			local g = { x = table.create(8, 0.0), y = table.create(8, 0.0) }
			return {
				settings = { pump_vs_speed = g, pump_vs_time = g, min_crouch_vs_ground_angle = g, compression_vs_ground_angle = g, compression_vs_deck_angle = g,
					height_change_damping = 0, minimum_height_change = 0, maximum_height_change = 0, ground_compression_scale = 0, deck_compression_scale = 0, angular_speed_damping = 0 },
				mode = { maximum_absorption_per_second = 0, maximum_acceleration_per_second = 0, absorption_factor = 0, acceleration_factor = 0 },
				sample = { position = { 0, 0, 0, 0 }, normal = { 0, 1, 0, 0 }, com_to_deck_world = { 0, 0, 0, 0 }, deck_angle = 0, intentional_pumping = 0 },
			}
		end
		function s:update_skateboard(state) ev("skateboard") state.flag_2722 = self.collision_signal end
		function s:predict_future_deck() ev("predict") end
		function s:set_collision_skeleton_flag() ev("collision-flag") end
		function s:set_ground_skeleton_flag() ev("ground-flag") end
		function s:update_special_state() ev("special") end
		function s:update_trajectory() ev("trajectory") end
		return s
	end
	local function up_state(): any
		local st = data.PhysicsGroundState.before_first_enter(false)
		st.anti_flip_torque_2624 = { 9, 9, 9, 9 }
		st.steering_push_scalar_2640 = 1.0
		st.elapsed_2648 = f32(0.1)
		st.scalar_2664 = 8.0
		st.straighten_scale_2672 = 1.0
		st.anti_flip_nudge_applied_2723 = true
		st.pinning_2727 = true
		st.flag_2729 = true
		return st
	end
	local function up_input(flags_2476: number): any
		return { wheel_contact_count_2556 = 1, position_112 = { 3, 4, 5, 0 }, timestep_2604 = 0.25,
			contact_state = { flags_2476 = flags_2476, flags_2480 = 0, velocity_400 = { 0, 0, 0, 0 }, axis_464 = { 0, 0, 0, 0 }, contact_position_560 = { 0, 0, 0, 0 },
				trajectory_position_592 = { 0, 0, 0, 0 }, reckoning_vector_1200 = { 0, 0, 0, 0 }, differing_contact_frame_limit = 0 } }
	end
	local PumpingState = require("../../../src/skate_core/riding/pumping/state").PumpingState
	harness.test(report, "grounded/update: update_preserves_complete_outer_order_and_state_prefix", function()
		local st = up_state()
		local s = up_services(true)
		assert(update_mod.update(st, PumpingState.reset_state(), data.GroundContactHistory.empty(), up_input(0), s))
		assert(table.concat(s.events, ",") == "elapsed-flag,contact-stop,contact-clear,pumping-frame,pumping-height,skateboard,predict,collision-flag,ground-flag,trajectory")
		assert(st.captured_position_x_2656 == 3 and st.captured_position_z_2660 == 5 and st.captured_position_valid_2726)
		assert(st.anti_flip_torque_2624[1] == 0 and not st.anti_flip_nudge_applied_2723 and not st.pinning_2727 and not st.flag_2729 and st.scalar_2664 == -1)
		assert(st.elapsed_2648 == f32(0.35))
	end)
	harness.test(report, "grounded/update: active_contact_and_special_tail_select_only_their_native_paths", function()
		local st = up_state()
		st.elapsed_2648 = 0.0
		local s = up_services(false)
		assert(update_mod.update(st, PumpingState.reset_state(), data.GroundContactHistory.empty(), up_input(0x0040_0000), s))
		assert(table.concat(s.events, ",") == "contact-publish,pumping-frame,pumping-height,skateboard,predict,ground-flag,special")
	end)

	-- Перенос Rust-теста ground_contact_response.rs
	harness.test(report, "ground_contact_response: contact_force_and_auto_jump_have_distinct_gates_and_keep_old_velocity", function()
		local settings = { anti_gravity_vs_time = { x = { 0, 1, 2, 3, 4, 5, 6, 7 }, y = table.create(8, f32(0.1)) }, max_dot_floor_wall = 0.5, foot_force_time = f32(0.09),
			auto_jump_height = f32(0.6), max_time = 1.0, velocity_time_to_consider = 0.25, auto_jump_y_down_scalar = f32(0.66), auto_jump_force = 3.0 }
		local physical = { board_normal = { 1, 0, 0, 0 }, up = { 1, 0, 0, 0 }, velocity = { 2, -2, 4, 0 }, board_mass = 8, gravity = f32(9.81), speed = 5, contact_count = 0 }
		local frame = { vector_8032 = { 0, 0, 0, 0 }, vector_8048 = { 0, f32(0.2), 0, 0 }, vector_8064 = { 0, 1, 0, 0 }, word_8080 = 0, flag_8084 = true, scalar_2752 = 0, scalar_2756 = 0 }
		local old = { 9, 9, 9, 9 }
		local force = gcr.wall_ride_response(settings, physical, frame, old)
		assert(force.active_2731 and not force.animated_board_2708 and u.diff(force.vector_2688, old) == nil)
		assert(math.abs(force.tag_16_force.force_world.y + 7.848) < 0.00001)
		frame.scalar_2752 = f32(0.1)
		local launch = gcr.wall_ride_response(settings, physical, frame, old)
		assert(launch.animated_board_2708 and u.diff(launch.vector_2688, { 3, f32(-1.32), 4, 0 }) == nil)
		frame.vector_8064 = physical.board_normal
		assert(not gcr.wall_ride_response(settings, physical, frame, old).animated_board_2708)
		frame.flag_8084 = false
		local none = gcr.wall_ride_response(settings, physical, frame, old)
		assert(not none.active_2731 and none.tag_16_force.force_world == vector.zero)
	end)
end
