--!strict
-- Сверка riding: push, push_animation, push_behaviors, pumping,
-- ground_correction_math с настоящим skate-core (golden/src/riding3.rs)
-- и перенос Rust-тестов push, push_behaviors, ground_correction_math.

local harness = require("../../harness")
local u = require("../../util")
local rt = require("../../../src/rt")
local push = require("../../../src/skate_core/riding/push")
local push_animation = require("../../../src/skate_core/riding/push_animation")
local pb = require("../../../src/skate_core/riding/push_behaviors")
local pumping = require("../../../src/skate_core/riding/pumping")
local gcm = require("../../../src/skate_core/riding/ground_correction_math")
local board_runtime = require("../../../src/skate_core/physics/board_runtime")
local drive_frames = require("../../../src/skate_core/physics/drive_frames")
local mass = require("../../../src/skate_core/physics/mass")
local rigid_body = require("../../../src/skate_core/physics/rigid_body")
local golden = require("../../golden/riding3") :: any

local fb, f32 = u.fb, rt.f32
local Curves = push_animation.PushAnimationCurves
local controller = pumping.controller
local PumpingState = pumping.state.PumpingState
local Native = pumping.geometry.NativePumpingGeometry

local function G(t: any): any
	local x, y = {}, {}
	for i = 1, #t[1] do
		x[i] = fb(t[1][i])
		y[i] = fb(t[2][i])
	end
	return { x = x, y = y }
end
local function F4(t: { number }): { number }
	return { fb(t[1]), fb(t[2]), fb(t[3]), fb(t[4]) }
end
local function sameN(a: { number }, t: { number }): boolean
	for i = 1, #t do
		if not u.same(a[i], t[i]) then
			return false
		end
	end
	return true
end
local function PB(t: any): any
	return { hstr_vel_b = fb(t[1]), lstr_vel_b = fb(t[2]), vel_e = fb(t[3]) }
end
local function same_pb(p: any, t: any): boolean
	return u.same(p.hstr_vel_b, t[1]) and u.same(p.lstr_vel_b, t[2]) and u.same(p.vel_e, t[3])
end
local function CU(t: any): any
	return { button_time_max = G(t[1]), button_time_to_dv = G(t[2]), blend_speed_over_frames = G(t[3]), blend_acc_over_frames = G(t[4]) }
end
local function same_state(s: any, t: any): boolean
	return u.same(s.out_factor, t[1]) and u.same(s.current_push_dv, t[2]) and same_pb(s.current, t[3]) and same_pb(s.target, t[4]) and s.continue_push == t[5]
end
local function OPT(x: any): number?
	return if x == false then nil else fb(x)
end

return function(report: harness.Report)
	harness.test(report, "push: 1500 calculate_acceleration vs Rust", function()
		for ci, c in golden.push do
			local i, l = c[1], c[2]
			local o = push.calculate_acceleration(
				{ flags_2468 = i[1], flags_2472 = i[2], target_speed = fb(i[3]), current_speed = fb(i[4]), absolute_body_speed = fb(i[5]), scale = fb(i[6]), delta_seconds = fb(i[7]), direction = u.V(i[8]) },
				{ maximum_pushable_speed = fb(l[1]), low_speed_change = fb(l[2]), high_speed_change = fb(l[3]) })
			assert(u.same_v(o.vector, c[3][1]) and u.same_v(o.local_point, c[3][2]) and o.suppressed == c[3][3], "случай " .. ci)
		end
	end)

	harness.test(report, "push_animation: 200 × 10 strength/update_blend vs Rust", function()
		for ci, c in golden.animation do
			local curves = CU(c.curves)
			local cur = PB(c.init)
			for si, st in c.steps do
				assert(u.same(Curves.strength(curves, fb(st[1]), fb(st[2])), st[3]), string.format("случай %d шаг %d: strength", ci, si))
				cur = Curves.update_blend(curves, cur, PB(st[4]), fb(st[2]), fb(st[5]))
				assert(same_pb(cur, st[6]), string.format("случай %d шаг %d: blend", ci, si))
			end
		end
	end)

	harness.test(report, "push_behaviors: 150 атрибутов/состояний/циклов vs Rust", function()
		for ci, c in golden.behaviors do
			local clips = {}
			for i, k in c.clips do
				clips[i] = { length = fb(k[1]), begin_velocity = fb(k[2]), end_velocity = fb(k[3]) }
			end
			local a = pb.PushAttributes.from_clips(clips)
			assert(u.same(a.minimum_begin_velocity, c.attrs[1]) and u.same(a.maximum_begin_velocity, c.attrs[2])
				and u.same(a.minimum_delta_velocity, c.attrs[3]) and u.same(a.maximum_delta_velocity, c.attrs[4]), "атрибуты " .. ci)
			for k, t in c.targets do
				local tg = pb.PushAttributes.target(a, fb(t[1]), fb(t[2]))
				assert(same_pb(tg, t[5]), string.format("случай %d target %d", ci, k))
				assert(u.same(pb.PushAttributes.out_factor(a, fb(t[1]), fb(t[2]), fb(t[3]), fb(t[4])), t[6]), string.format("случай %d out_factor %d", ci, k))
			end
			local curves = CU(c.curves)
			-- ROBLOX: стартовое состояние до initialize_push повторяет эталон (golden/src/riding3.rs).
			local state: any = { out_factor = 0, current_push_dv = 0, current = {}, target = {}, continue_push = true }
			state.out_factor = fb(c.after_init[1])
			pb.PushState.initialize_push(state)
			assert(same_state(state, c.after_init), "initialize_push " .. ci)
			local first = pb.FirstPushStrength.begin(fb(c.first[1]), fb(c.first[2]))
			for si, st in c.first[3] do
				pb.FirstPushStrength.update(first, state, curves, OPT(st[1]), fb(st[2]), f32(1 / 60))
				local w = st[4]
				assert(same_state(state, st[3]) and u.same(first.simulated_held_seconds, w[1]) and first.push_from_teleport == w[2]
					and first.first_push == w[3] and first.first_update == w[4], string.format("случай %d first %d", ci, si))
			end
			local i0 = c.intents0
			local cycle = pb.PushCycle.begin(state, curves, { pushing = OPT(i0[1]), new_push = i0[2], configured_foot = i0[3] })
			local c0 = c.cycle[1]
			assert(cycle.phase == c0[1] and u.same(cycle.next_push_dv, c0[2]) and same_state(state, c0[3]), "cycle begin " .. ci)
			for si = 2, #c.cycle do
				local st = c.cycle[si]
				local it = st[1]
				pb.PushCycle.update(cycle, state, curves, { pushing = OPT(it[1]), new_push = it[2], configured_foot = it[3] }, fb(st[2]), fb(st[3]))
				assert(cycle.phase == st[4] and u.same(cycle.next_push_dv, st[5]) and same_state(state, st[6]), string.format("случай %d cycle %d", ci, si))
			end
			local f = c.foot
			local frame = { left_foot = F4(f[1]), right_foot = F4(f[2]), deck_position = F4(f[3]), deck_y = F4(f[4]), deck_z = F4(f[5]), skateboard_flipped = f[6] }
			local l, r = pb.PushFootFrame.out_distance(frame, false), pb.PushFootFrame.out_distance(frame, true)
			assert(u.same(l[1], c.out[1]) and u.same(l[2], c.out[2]) and u.same(r[1], c.out[3]) and u.same(r[2], c.out[4]), "out_distance " .. ci)
		end
	end)

	harness.test(report, "pumping: 80 × 40 update/update_ground vs Rust", function()
		for ci, c in golden.pumping do
			local s = c.settings
			local st = {
				pump_vs_speed = G(s[1]), pump_vs_time = G(s[2]), min_crouch_vs_ground_angle = G(s[3]), compression_vs_ground_angle = G(s[4]),
				compression_vs_deck_angle = G(s[5]), height_change_damping = fb(s[6]), minimum_height_change = fb(s[7]), maximum_height_change = fb(s[8]),
				ground_compression_scale = fb(s[9]), deck_compression_scale = fb(s[10]), angular_speed_damping = fb(s[11]),
			}
			local m = c.mode
			local mode = { maximum_absorption_per_second = fb(m[1]), maximum_acceleration_per_second = fb(m[2]), absorption_factor = fb(m[3]), acceleration_factor = fb(m[4]) }
			local state = PumpingState.reset_state()
			for si, step in c.steps do
				local sample = { position = F4(step[1]), normal = F4(step[2]), com_to_deck_world = F4(step[3]), deck_angle = fb(step[4]), intentional_pumping = step[5] }
				if step[8] then
					PumpingState.reset(state)
				end
				if step[6] then
					assert(controller.update_ground(state, st, mode, sample, Native :: any))
				else
					assert(controller.update(state, st, mode, sample, fb(step[7]), Native :: any))
				end
				local w = step[9]
				assert(sameN(state.previous_position, w[1]) and sameN(state.previous_normal, w[2]) and u.same(state.smoothed_height_change, w[3])
					and u.same(state.pumping_time, w[4]) and u.same(state.previous_height, w[5]) and u.same(state.pumping, w[6])
					and u.same(state.pump_acceleration, w[7]) and u.same(state.angular_speed, w[8]) and u.same(state.absorption, w[9])
					and u.same(state.ground_normal_absorption, w[10]) and u.same(state.minimum_crouch, w[11]) and u.same(state.deck_angle_absorption, w[12])
					and u.same(state.reset_only_scalar, w[13]) and state.record_valid == w[14] and state.intentional_pumping == w[15],
					string.format("случай %d шаг %d", ci, si))
				local o, wo = PumpingState.physics_output(state), step[10]
				assert(u.same(o.compression, wo[1]) and u.same(o.absorption, wo[2]) and u.same(o.ground_normal_absorption, wo[3]) and u.same(o.minimum_crouch, wo[4])
					and u.same(o.deck_angle_absorption, wo[5]) and u.same(o.pump_acceleration, wo[6]) and o.intentional_pumping == wo[7], string.format("случай %d шаг %d: выход", ci, si))
			end
		end
	end)

	harness.test(report, "pumping: 800 calculate (сила пампинга) vs Rust", function()
		for ci, c in golden.pump_force do
			local i = c[1]
			local o = pumping.calculate({ flags_2476 = i[1], mode_multiplier = fb(i[2]), pumping_scalar = fb(i[3]), input_scalar_2660 = fb(i[4]), timestep = fb(i[5]), direction_432 = F4(i[6]), normal_threshold = F4(i[7]) })
			assert(sameN(o, c[2]), "случай " .. ci)
		end
	end)

	harness.test(report, "ground_correction_math: 1000 × 9 функций vs Rust", function()
		for ci, c in golden.corrections do
			local i, o = c[1], c[2]
			local a, cc, d, edge_end, dir = F4(i[1]), F4(i[2]), F4(i[3]), F4(i[4]), F4(i[5])
			assert(u.same(gcm.center_of_mass_height(a), o[1]) and u.same(gcm.dot_product(a, cc), o[2]), "случай " .. ci .. ": скаляры")
			local force = if o[10] then { 0, 0, 0, 0 } else a
			assert(u.same(gcm.collision_force_projection(force, cc), o[3]), "случай " .. ci .. ": projection")
			assert(sameN(gcm.edge_direction(a, edge_end), o[4]) and sameN(gcm.edge_up(dir), o[5]) and sameN(gcm.hang_force(a, edge_end, d), o[6]), "случай " .. ci .. ": кромка")
			assert(sameN(gcm.wheel_catch_displacement(F4(i[11]), F4(i[12])), o[7]), "случай " .. ci .. ": wheel_catch")
			assert(sameN(gcm.pinning_velocity(d, fb(i[8]), fb(i[9]), fb(i[10])), o[8]), "случай " .. ci .. ": pinning")
			assert(sameN(gcm.scale_to_magnitude(a, fb(i[6]), fb(i[7])), o[9]), "случай " .. ci .. ": scale")
		end
	end)

	harness.test(report, "ground_correction_math: 300 apply_world_force vs Rust", function()
		local sim = rigid_body.RetailSimulationStep.fixed_60_hz(0, f32(0.001), vector.create(0, f32(-9.81), 0))
		local b = board_runtime.BoardRuntime.new(mass.default_skateboard_mass_properties(), drive_frames.default_body_transforms(),
			drive_frames.RetailAffineTransform.IDENTITY(), sim, board_runtime.BoardMotion.Active)
		local body = board_runtime.BoardRuntime.bodies_mut(b)[7]
		for ci, c in golden.world_force do
			gcm.apply_world_force(body, u.V(c[1]), u.V(c[2]), u.V(c[3]))
			assert(u.same_v(body.rates.force_acceleration, c[4]) and u.same_v(body.rates.torque_acceleration, c[5]) and body.rates.cool_down == c[6], "случай " .. ci)
		end
	end)

	-- Перенос Rust-тестов crates/skate-core/src/riding/tests/push.rs
	local function pinput(): any
		return { flags_2468 = 0x0200_0000, flags_2472 = 0, target_speed = 10.0, current_speed = 0.0, absolute_body_speed = 0.0, scale = 0.5, delta_seconds = 0.125, direction = vector.create(0, 0, 1) }
	end
	local LIMITS = { maximum_pushable_speed = 8.5, low_speed_change = 2.0, high_speed_change = 1.0 }
	harness.test(report, "push: inactive_and_suppressed_push_clear_both_output_vectors", function()
		local i = pinput()
		i.flags_2468, i.flags_2472 = 0, 0x200
		local o = push.calculate_acceleration(i, LIMITS)
		assert(o.vector == vector.zero and o.local_point == vector.zero and not o.suppressed)
		i.flags_2468 = 0x0200_0000
		o = push.calculate_acceleration(i, LIMITS)
		assert(o.vector == vector.zero and o.suppressed)
	end)
	harness.test(report, "push: tu3_blends_the_two_speed_limits_before_time_conversion", function()
		assert(push.calculate_acceleration(pinput(), LIMITS).vector.z == 8.0)
		local i = pinput()
		i.current_speed, i.absolute_body_speed = 4.25, 4.25
		assert(push.calculate_acceleration(i, LIMITS).vector.z == 6.0)
	end)
	harness.test(report, "push: speed_cap_is_based_on_absolute_speed_and_never_brakes", function()
		local i = pinput()
		i.current_speed, i.absolute_body_speed = 8.25, 8.25
		assert(push.calculate_acceleration(i, LIMITS).vector.z == 1.0)
		i.absolute_body_speed = 9.0
		assert(push.calculate_acceleration(i, LIMITS).vector == vector.zero)
		local j = pinput()
		j.target_speed = -1.0
		assert(push.calculate_acceleration(j, LIMITS).vector == vector.zero)
	end)
	harness.test(report, "push: native_force_direction_keeps_vertical_component_and_zero_application_point", function()
		local i = pinput()
		i.direction = vector.create(0, f32(0.6), f32(0.8))
		local o = push.calculate_acceleration(i, LIMITS)
		assert(o.vector == vector.create(0, f32(4.8), f32(6.4)) and o.local_point == vector.zero)
	end)

	-- Перенос Rust-тестов crates/skate-core/src/riding/tests/push_behaviors.rs
	local function curves(): any
		local x, y = {}, {}
		for i = 0, 7 do
			x[i + 1] = f32(i / 7)
			y[i + 1] = i
		end
		return { button_time_max = { x = x, y = table.create(8, 1.0) }, button_time_to_dv = { x = x, y = y },
			blend_speed_over_frames = { x = x, y = table.create(8, 1.0) }, blend_acc_over_frames = { x = x, y = table.create(8, 1.0) } }
	end
	local function state(): any
		return { out_factor = 0.375, current_push_dv = 0.0, current = { hstr_vel_b = 0, lstr_vel_b = 0, vel_e = 0 }, target = { hstr_vel_b = 0, lstr_vel_b = 0, vel_e = 0 }, continue_push = false }
	end
	local function clips(): any
		return pb.PushAttributes.from_clips({
			{ length = 1, begin_velocity = 0, end_velocity = 4 }, { length = 2, begin_velocity = 4, end_velocity = 8 },
			{ length = 1, begin_velocity = 0, end_velocity = 1 }, { length = 2, begin_velocity = 4, end_velocity = 5 },
		})
	end
	local function near(a: number, b: number)
		assert(math.abs(a - b) < 0.000002, string.format("%.9g != %.9g", a, b))
	end
	harness.test(report, "push_behaviors: unequal_clip_lengths_require_distance_weighted_velocity_blend", function()
		local t = pb.PushAttributes.target(clips(), 2.0, 2.5)
		near(t.hstr_vel_b, f32(1 / 3))
		near(t.lstr_vel_b, f32(1 / 3))
		near(t.vel_e, 0.5)
	end)
	harness.test(report, "push_behaviors: authored_bounds_cap_begin_speed_and_strength_before_blending", function()
		local a = clips()
		assert(a.minimum_begin_velocity == 0 and a.maximum_begin_velocity == 4 and a.minimum_delta_velocity == 1 and a.maximum_delta_velocity == 4)
		local lo, hi = pb.PushAttributes.target(a, -5, -3), pb.PushAttributes.target(a, 10, 20)
		assert(lo.hstr_vel_b == 0 and lo.lstr_vel_b == 0 and lo.vel_e == 0 and hi.hstr_vel_b == 1 and hi.lstr_vel_b == 1 and hi.vel_e == 1)
	end)
	harness.test(report, "push_behaviors: out_factor_combines_normalized_speed_strength_then_caps_at_stock_limit", function()
		near(pb.PushAttributes.out_factor(clips(), 2.5, 2.5, f32(0.4), f32(0.659)), 0.5)
		assert(pb.PushAttributes.out_factor(clips(), 50, 50, f32(0.4), f32(0.659)) == f32(0.659))
		assert(pb.PushAttributes.out_factor(clips(), -20, -20, f32(0.4), f32(0.659)) == 0)
	end)
	harness.test(report, "push_behaviors: init_push_preserves_out_factor_and_marks_all_blends_uninitialized", function()
		local s = state()
		s.current_push_dv, s.continue_push = 4.0, true
		pb.PushState.initialize_push(s)
		assert(s.out_factor == 0.375 and s.current_push_dv == 0 and not s.continue_push and s.current.vel_e == -1 and s.target.vel_e == -1 and s.current.hstr_vel_b == s.target.hstr_vel_b)
	end)
	harness.test(report, "push_behaviors: teleport_push_evaluates_previous_held_time_before_advancing", function()
		local first = pb.FirstPushStrength.begin(f32(0.1), 0.5)
		local s = state()
		pb.FirstPushStrength.update(first, s, curves(), nil, 0.0, 0.25)
		assert(s.current_push_dv == 0 and first.simulated_held_seconds == 0.25 and not first.first_push and not first.first_update)
		pb.FirstPushStrength.update(first, s, curves(), nil, 0.0, 0.25)
		near(s.current_push_dv, 1.75)
	end)
	harness.test(report, "push_behaviors: first_push_release_latches_until_fresh_activation", function()
		local first = pb.FirstPushStrength.begin(0.5, 0.5)
		assert(not first.push_from_teleport)
		local s = state()
		pb.FirstPushStrength.update(first, s, curves(), 0.25, 0.0, f32(0.1))
		local strength = s.current_push_dv
		pb.FirstPushStrength.update(first, s, curves(), nil, 0.0, f32(0.1))
		pb.FirstPushStrength.update(first, s, curves(), 1.0, 0.0, f32(0.1))
		assert(s.current_push_dv == strength)
	end)
	local NONE = { pushing = nil, new_push = false, configured_foot = false }
	harness.test(report, "push_behaviors: holding_first_cap_can_reduce_strength_but_next_hold_is_uncapped", function()
		local s = state()
		s.current_push_dv = 6.0
		local c = curves()
		local cycle = pb.PushCycle.begin(s, c, { pushing = 1.0, configured_foot = true, new_push = false })
		pb.PushCycle.update(cycle, s, c, { pushing = 1.0, configured_foot = true, new_push = false }, 0.0, 4.0)
		assert(s.current_push_dv == 4.0)
		pb.PushCycle.update(cycle, s, c, NONE, 0.0, 4.0)
		assert(not s.continue_push)
		pb.PushCycle.update(cycle, s, c, { pushing = 1.0, configured_foot = true, new_push = true }, 0.0, 4.0)
		assert(s.current_push_dv == 7.0 and cycle.phase == pb.PushCyclePhase.HoldingNext)
		s.current_push_dv = 9.0
		pb.PushCycle.update(cycle, s, c, NONE, 0.0, 4.0)
		assert(s.current_push_dv == 7.0 and cycle.phase == pb.PushCyclePhase.NextReleased and s.continue_push)
	end)
	harness.test(report, "push_behaviors: released_first_and_new_push_checks_can_cascade_in_one_update", function()
		local s = state()
		local c = curves()
		local cycle = pb.PushCycle.begin(s, c, { pushing = 0.25, configured_foot = true, new_push = false })
		pb.PushCycle.update(cycle, s, c, { pushing = nil, configured_foot = true, new_push = true }, 0.0, 4.0)
		assert(cycle.phase == pb.PushCyclePhase.HoldingNext and s.continue_push and cycle.next_push_dv == 0)
	end)
	harness.test(report, "push_behaviors: out_distance_uses_live_foot_and_deck_axes_with_only_z_flipped", function()
		local frame = { left_foot = { 11, 22, 33, 0 }, right_foot = { 14, 25, 36, 0 }, deck_position = { 10, 20, 30, 0 }, deck_y = { 0, 1, 0, 0 }, deck_z = { 1, 0, 0, 0 }, skateboard_flipped = false }
		local l, r = pb.PushFootFrame.out_distance(frame, false), pb.PushFootFrame.out_distance(frame, true)
		assert(l[1] == 1 and l[2] == 2 and r[1] == 4 and r[2] == 5)
		frame.skateboard_flipped = true
		r = pb.PushFootFrame.out_distance(frame, true)
		assert(r[1] == -4 and r[2] == 5)
	end)

	harness.test(report, "ground_correction_math: corrections_preserve_native_axes_and_units", function()
		local force = gcm.hang_force({ 0, 0, 0, 0 }, { 0, 0, 2, 0 }, { 1, 0, 0, 0 })
		assert(math.abs(force[1] - 50) < 0.0001 and force[2] == 160)
		local up = gcm.edge_up({ 0, 1, 0, 0 })
		assert(up[1] == 1 and up[2] == 0 and up[3] == 0 and up[4] == 0)
		assert(gcm.collision_force_projection({ 0, 0, 4, 0 }, { 0, 0, -3, 0 }) == -3)
		assert(gcm.collision_force_projection({ 0, 0, 0, 0 }, { 1, 2, 3, 0 }) == 0)
		local pin = gcm.pinning_velocity({ 4, 9, 8, 0 }, 3, 10, f32(1 / 60))
		assert(math.abs(pin[1] + 60) < 0.00001 and pin[2] == 0 and math.abs(pin[3] - 120) < 0.00002)
		assert(gcm.wheel_catch_displacement({ 0, 0, 1, 0 }, { 0, 1, 0, 0 })[1] > 0)
	end)
end
