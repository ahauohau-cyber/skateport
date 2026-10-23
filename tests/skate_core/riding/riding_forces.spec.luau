--!strict
-- Сверка riding: steering, heading, braking, ground_force, anti_flip, straighten,
-- slide_friction, speed_wobble, speed_model с настоящим skate-core
-- (golden/src/riding2.rs) и перенос Rust-тестов steering.

local harness = require("../../harness")
local u = require("../../util")
local rt = require("../../../src/rt")
local steering = require("../../../src/skate_core/riding/steering")
local heading = require("../../../src/skate_core/riding/heading")
local braking = require("../../../src/skate_core/riding/braking")
local ground_force = require("../../../src/skate_core/riding/ground_force")
local anti_flip = require("../../../src/skate_core/riding/anti_flip")
local straighten = require("../../../src/skate_core/riding/straighten")
local slide_friction = require("../../../src/skate_core/riding/slide_friction")
local speed_wobble = require("../../../src/skate_core/riding/speed_wobble")
local speed_model = require("../../../src/skate_core/riding/speed_model")
local golden = require("../../golden/riding2") :: any

local fb, f32 = u.fb, rt.f32
local TruckSteeringState = steering.TruckSteeringState

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

return function(report: harness.Report)
	harness.test(report, "steering: 200 × 30 calculate_tilt/TruckSteeringState vs Rust", function()
		for ci, c in golden.steering do
			local s = c.settings
			local st = {
				hard_turn_increase = fb(s[1]), damping = fb(s[2]), speed_graph_max_speed = fb(s[3]), push_scalar_increment = fb(s[4]),
				push_scalar_decrement = fb(s[5]), push_scalar_min = fb(s[6]), manual_scalar = fb(s[7]), general_scalar = fb(s[8]),
				tight_trucks_scalar = fb(s[9]), speed_graph = G(s[10]), input_graph = G(s[11]), tilt_blending = fb(s[12]),
			}
			local push = { value = fb(c.init[1]) }
			local damped = { value = fb(c.init[2]) }
			local truck = TruckSteeringState.default()
			for si, step in c.steps do
				local i = step[1]
				local inp = { turn = fb(i[1]), hard_turn = fb(i[2]), absolute_body_speed = fb(i[3]), flipped_controls_scalar = fb(i[4]), balance = fb(i[5]), truck_tightness = fb(i[6]), pushing = i[7] }
				local mode = step[2]
				local tilt = steering.calculate_tilt(st, inp, if mode == 0 or mode == 2 then push else nil, if mode == 0 or mode == 1 then damped else nil)
				TruckSteeringState.update(truck, tilt, st.tilt_blending, step[6], step[7])
				local w = step[8]
				assert(u.same(tilt, step[3]) and u.same(push.value, step[4]) and u.same(damped.value, step[5]), string.format("случай %d шаг %d: tilt", ci, si))
				assert(u.same(truck.deck_tilt, w[1]) and u.same(truck.targets[1], w[2]) and u.same(truck.targets[2], w[3])
					and u.same(truck.activation_time[1], w[4]) and u.same(truck.activation_time[2], w[5]), string.format("случай %d шаг %d: траки", ci, si))
			end
		end
	end)

	harness.test(report, "heading: 600 calculate vs Rust", function()
		for ci, c in golden.heading do
			local s, i = c[1], c[2]
			local st = {
				manual_wrong_wheel_scalar = fb(s[1]), manual_damping = fb(s[2]), speed_max = fb(s[3]), heading_strength = fb(s[4]), turn_strength = fb(s[5]),
				angular_response = G(s[6]), manual_response = G(s[7]), inclination_response = G(s[8]), speed_response = G(s[9]), normal_threshold = F4(s[10]),
			}
			local inp = {
				balance = fb(i[1]), manual_turn = fb(i[2]), flags_2472 = i[3], timestep = fb(i[4]), signed_speed = fb(i[5]), manual_curve_input = fb(i[6]),
				turn_2712 = fb(i[7]), scalar_2740 = fb(i[8]), velocity = F4(i[9]), normal = F4(i[10]), angular_velocity = F4(i[11]),
				transform = { F4(i[12][1]), F4(i[12][2]), F4(i[12][3]), F4(i[12][4]) },
			}
			local prev = { value = fb(c[3]) }
			local out = heading.calculate(st, inp, prev)
			assert(sameN(out, c[4]) and u.same(prev.value, c[5]), "случай " .. ci)
		end
	end)

	harness.test(report, "braking: 800 calculate_braking/calculate_linear_drag vs Rust", function()
		for ci, c in golden.braking do
			local st = { input_force = fb(c[1][1]), override_force = fb(c[1][2]), minimum_speed = fb(c[1][3]) }
			local i = c[2]
			local inp = { flags_2468 = i[1], input_2728 = fb(i[2]), signed_speed = fb(i[3]), absolute_body_speed = fb(i[4]), surface_factor = fb(i[5]), direction = u.V(i[6]) }
			local out = braking.calculate_braking(inp, st)
			assert(out.tag == 2 and u.same_v(out.force_world, c[3]) and out.point_body == vector.zero, "тормоз " .. ci)
			local ds = { brake_speed = fb(c[4][1]), balance_speed = fb(c[4][2]), comparison_threshold = fb(c[4][3]), balance_drag = fb(c[4][4]) }
			local di = { flags_2468 = i[1], absolute_body_speed = inp.absolute_body_speed, balance_2720 = fb(c[5][1]), scalar_2724 = fb(c[5][2]), comparison_scalar = fb(c[5][3]) }
			assert(u.same(braking.calculate_linear_drag(di, ds), c[6]), "сопротивление " .. ci)
		end
	end)

	harness.test(report, "ground_force: 800 calculate vs Rust", function()
		for ci, c in golden.ground_force do
			local s, i = c[1], c[2]
			local out = ground_force.calculate(
				{ range_1220 = fb(s[1]), speed_scale_1224 = fb(s[2]), scale_1228 = fb(s[3]), normal_threshold = F4(s[4]) },
				{ argument_1 = fb(i[1]), application_z = fb(i[2]), argument_3 = fb(i[3]), argument_4 = fb(i[4]), balance = fb(i[5]), surface_speed = fb(i[6]),
					axis_384 = F4(i[7]), velocity_400 = F4(i[8]), axis_544 = F4(i[9]) })
			assert(sameN(out, c[3]), "случай " .. ci)
		end
	end)

	harness.test(report, "anti_flip: 800 calculate vs Rust", function()
		for ci, c in golden.anti_flip do
			local s, i = c[1], c[2]
			local out = anti_flip.calculate(
				{ axis_96_response = G(s[1]), axis_64_response = G(s[2]), normal_threshold = F4(s[3]) },
				{ flags_2468 = i[1], balance = fb(i[2]), axis_96 = F4(i[3]), axis_64 = F4(i[4]), projection_axis_544 = F4(i[5]) })
			assert(sameN(out, c[3]), "случай " .. ci)
		end
	end)

	harness.test(report, "straighten: 800 calculate vs Rust", function()
		for ci, c in golden.straighten do
			local s, i = c[1], c[2]
			local out = straighten.calculate(
				{ time_response = G(s[1]), opposite_turn_limit = fb(s[2]), time_scalar = fb(s[3]), heading_time_limit = fb(s[4]), strength = fb(s[5]) },
				{ heading_time = fb(i[1]), scalar_2764 = fb(i[2]), turn = fb(i[3]), forward = F4(i[4]), velocity = F4(i[5]), normal = F4(i[6]) })
			assert(sameN(out, c[3]), "случай " .. ci)
		end
	end)

	harness.test(report, "slide_friction: 800 calculate vs Rust", function()
		for ci, c in golden.slide do
			local s, i = c[1], c[2]
			local out = slide_friction.calculate(
				{ angle_response = G(s[1]), speed_response = G(s[2]), time_response = G(s[3]), scalar_516 = fb(s[4]), heading_time_limit = fb(s[5]), friction = fb(s[6]) },
				{ heading_time = fb(i[1]), normal = F4(i[2]), velocity = F4(i[3]), side_axis = F4(i[4]), surface_speed = fb(i[5]), scalar_2764 = fb(i[6]) })
			assert(sameN(out, c[3]), "случай " .. ci)
		end
	end)

	harness.test(report, "speed_wobble: 100 × 40 calculate vs Rust", function()
		for ci, c in golden.wobble do
			local s = c.settings
			local st = {
				frequency_time = G(s[1]), frequency_speed = G(s[2]), amplitude_time = G(s[3]), amplitude_speed = G(s[4]), tightness_threshold = fb(s[5]),
				time_range = fb(s[6]), speed_range = fb(s[7]), frequency_scale = fb(s[8]), amplitude_scale = fb(s[9]), crouch_threshold = fb(s[10]),
				height_min = fb(s[11]), height_max = fb(s[12]),
			}
			local state = speed_wobble.SpeedWobbleState.new(c.init)
			for si, step in c.steps do
				local i = step[1]
				local out = speed_wobble.calculate(state, st, { tilt = fb(i[1]), speed = fb(i[2]), center_of_mass_height = fb(i[3]), truck_tightness = fb(i[4]), activation_threshold = fb(i[5]), amplitude_multiplier = fb(i[6]) })
				assert(u.same(out, step[2]) and u.same_words(state.words, step[3]), string.format("случай %d шаг %d", ci, si))
			end
		end
	end)

	harness.test(report, "speed_model: 100 × 40 update vs Rust", function()
		for ci, c in golden.speed_model do
			local s = c.settings
			local st = {
				negative_gain = fb(s[1]), maximum_gravity_acceleration = fb(s[2]), gravity = fb(s[3]), positive_gain = fb(s[4]), coffin_acceleration = fb(s[5]),
				speed_error_bound = fb(s[6]), surface_friction = G(s[7]), manual_acceleration = fb(s[8]), negative_manual_angle_limit = fb(s[9]),
				manual_angle_limit = fb(s[10]), no_input_delay = fb(s[11]), no_input_friction = G(s[12]), manual_friction = G(s[13]), override_enabled = s[14],
				override_speed = fb(s[15]), normal_threshold = F4(s[16]), override_direction_threshold = F4(s[17]),
			}
			local state = { target_speed = fb(c.init[1]), flags_1360 = c.init[2] }
			for si, step in c.steps do
				state.flags_1360 = step[1]
				local i = step[2]
				local out = speed_model.update(state, st, {
					flags_2468 = i[1], flags_2476 = i[2], wheel_contact_count = i[3], frames_2580 = i[4], timestep = fb(i[5]), signed_speed = fb(i[6]),
					angle_2652 = fb(i[7]), surface_speed = fb(i[8]), turn_2672 = fb(i[9]), balance = fb(i[10]), elapsed_without_input = fb(i[11]),
					manual_state_276 = fb(i[12]), vector_160 = F4(i[13]), vector_352 = F4(i[14]), velocity_416 = F4(i[15]), normal_464 = F4(i[16]),
					effective_forward = F4(i[17]), mass = fb(i[18]),
				})
				assert(sameN(out, step[3]) and u.same(state.target_speed, step[4][1]) and state.flags_1360 == step[4][2], string.format("случай %d шаг %d", ci, si))
			end
		end
	end)

	-- Перенос Rust-тестов crates/skate-core/src/riding/tests/steering.rs
	local function settings(): any
		local keys = { 0.0, f32(0.1), f32(0.2), f32(0.3), f32(0.4), 0.5, f32(0.6), 1.0 }
		return {
			hard_turn_increase = 1.0, damping = f32(0.7), speed_graph_max_speed = 50.0, push_scalar_increment = f32(0.05),
			push_scalar_decrement = f32(0.015), push_scalar_min = 0.5, manual_scalar = 0.25, general_scalar = f32(0.6),
			tight_trucks_scalar = f32(0.7), tilt_blending = f32(0.2),
			speed_graph = { x = table.clone(keys), y = table.create(8, 1.0) },
			input_graph = { x = table.clone(keys), y = table.create(8, 1.0) },
		}
	end
	local function input(): any
		local i = steering.default_input()
		i.turn = 0.5
		i.flipped_controls_scalar = 1.0
		return i
	end

	harness.test(report, "steering: hard_turn_uses_turn_sign_including_zero_not_hard_turn_sign", function()
		local s, i = settings(), input()
		i.hard_turn = -1.0
		assert(steering.calculate_tilt(s, i, nil, nil) == f32(1.2))
		i.turn = -0.5
		assert(steering.calculate_tilt(s, i, nil, nil) == f32(-1.2))
		i.turn = -0.0
		assert(steering.calculate_tilt(s, i, nil, nil) == f32(1.2))
	end)

	harness.test(report, "steering: optional_state_pointers_and_pushing_recovery_preserve_native_limits", function()
		local s, i = settings(), input()
		local scalar, turn = { value = 1.0 }, { value = 0.0 }
		i.pushing = true
		steering.calculate_tilt(s, i, scalar, turn)
		assert(turn.value == f32(0.35) and scalar.value == f32(0.985))
		for _ = 1, 100 do
			steering.calculate_tilt(s, i, scalar, nil)
		end
		assert(scalar.value == 0.5)
		i.pushing = false
		for _ = 1, 100 do
			steering.calculate_tilt(s, i, scalar, nil)
		end
		assert(scalar.value == 1.0)
	end)

	harness.test(report, "steering: manual_tightness_and_flipped_controls_multiply_the_tilt", function()
		local s = settings()
		local base = steering.calculate_tilt(s, input(), nil, nil)
		local i = input()
		i.balance, i.truck_tightness, i.flipped_controls_scalar = 1.0, 1.0, -1.0
		assert(math.abs(steering.calculate_tilt(s, i, nil, nil) - f32(f32(base * -0.25) * f32(0.7))) < 1e-7)
	end)

	harness.test(report, "steering: truck_contact_flags_swap_with_stance_and_first_inactive_tick_holds_angle", function()
		local regular = TruckSteeringState.default()
		TruckSteeringState.update(regular, f32(0.6), f32(0.2), 0, bit32.lshift(1, 27))
		assert(regular.targets[1] > 0.0 and regular.targets[2] == 0.0)
		local switch = TruckSteeringState.default()
		TruckSteeringState.update(switch, f32(0.6), f32(0.2), bit32.lshift(1, 20), bit32.lshift(1, 27))
		assert(regular.targets[1] == switch.targets[2] and regular.targets[2] == switch.targets[1])
		local previous = regular.targets[1]
		TruckSteeringState.update(regular, f32(0.6), f32(0.2), 0, 0)
		assert(regular.targets[1] == previous)
		TruckSteeringState.update(regular, f32(0.6), f32(0.2), 0, 0)
		assert(regular.targets[1] == f32(previous * f32(0.983)))
	end)

	harness.test(report, "steering: truck_reactivation_completes_the_native_ramp", function()
		local state = TruckSteeringState.default()
		for _ = 1, 11 do
			TruckSteeringState.update(state, f32(0.6), 1.0, 0, bit32.lshift(3, 26))
		end
		assert(state.targets[1] == f32(0.6) and state.targets[2] == f32(0.6))
		assert(state.activation_time[1] > f32(0.165))
	end)
end
