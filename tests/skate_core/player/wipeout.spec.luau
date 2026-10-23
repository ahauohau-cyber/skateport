--!strict
-- Сверка player::wipeout и physics::grind_forces::post с настоящим Rust
-- (golden/src/wipeout.rs) + перенос player/wipeout/tests.rs.

local harness = require("../../harness")
local u = require("../../util")
local rt = require("../../../src/rt")
local wipeout = require("../../../src/skate_core/player/wipeout")
local post = require("../../../src/skate_core/physics/grind_forces/post")
local sar = require("../../../src/skate_core/physics/skeleton_animation_record")
local golden = require("../../golden/wipeout") :: any
assert(type(golden) == "table", tostring(golden))

local f32 = rt.f32
local Requests = wipeout.Requests

local function check(d: string?, what: string)
	if d then
		error(what .. d, 2)
	end
end
local function count_true(t: { boolean }): number
	local n = 0
	for _, v in t do
		if v then
			n += 1
		end
	end
	return n
end

local function input(): any
	return {
		flags_2468 = 0, flags_2472 = 0, flags_2476 = 0, flags_2480 = 0, flags_2484 = 0, category = 100,
		timestep = f32(1.0 / 60.0), time_on_ground = 1.0, speed = 0.0, animation_up = { 0.0, 1.0, 0.0, 0.0 },
		landing_angle = 0.0, deck_velocity = { 0.0, 0.0, 0.0, 0.0 }, com_velocity = { 0.0, 0.0, 0.0, 0.0 }, jump_fix_frames = 1000,
		deck = sar.IDENTITY(), input_board = sar.IDENTITY(), world_to_animation = sar.IDENTITY(),
		closing_velocity = { 0.0, 0.0, 0.0, 0.0 }, board_material_flags = 0, board_contact = true, wheel_contact = true,
		board_contact_normal = { 0.0, 1.0, 0.0, 0.0 }, opposing_contact = 0.0, regions_force = table.create(8, 0.0),
		maximum_skater_force = 0.0, vehicle_force = 0.0, group_8 = false, conflicting = false, compliant = false,
		highest_normal = { 0.0, 1.0, 0.0, 0.0 }, pose_error = { 0.0, 0.0, 0.0, 0.0 }, maximum_pose_error = 0.0,
		flip_active = false, flip_requested_speed = 0.0, system_up_y = 1.0, grind_selected = false, grind_normal_valid = false,
		grind_normal = { 0.0, 1.0, 0.0, 0.0 },
	}
end
local function mode(): any
	return { check_squash = true, check_bad_landing = true, ground_xz = 10.0, bad_landing_scale = 1.0 }
end
local function settings(): any
	return {
		ground = {
			vehicle_scalar = 1.0, vehicle_contact = 100.0, skitch_contact = 100.0, skitch_scalar = 1.0, skitch_arms_scalar = 1.0,
			skater_scalar = 1.0, max_squash = 100.0, max_squash_coffin = 100.0, max_displacement = 100.0, max_contact = 100.0,
			max_arm_contact = 100.0, max_deck_error = 1.0, opposing_contact = 1.0, y_acceleration = 10.0, light_dmo_scalar = 1.0,
			player_scalar = 1.0, ai_scalar = 1.0, skitch_acc_scalar = 1.0, balance_total = 100.0, balance_min_speed = 1.0, balance_base = 1.0,
		},
		air = {
			xz_trick = 10.0, y_trick = 10.0, xz_acceleration = 10.0, y_acceleration = 10.0, max_squash = 100.0, max_displacement = 100.0,
			max_contact = 100.0, max_arm_contact = 100.0, body_flip_scalar = 1.0, body_flip_acc_scalar = 1.0, light_dmo_scalar = 1.0,
			ignore_danger_frames = 10, max_landing_speed = 6.0, max_stairs_speed = 8.0, max_grind_speed = 5.0,
			max_landing_angle = { x = { 0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0 }, y = table.create(8, 1.0) },
		},
		lean_contact_y = -1.0,
	}
end
local function request_input(): any
	return { flags_2468 = 0, flags_2476 = 0, flags_2480 = 0, flags_2484 = 0, animation_up_y = 1.0, category = 100 }
end

return function(report: harness.Report)
	harness.test(report, "wipeout: handplant_air_check_preserves_contact_threshold_and_real_impact_bails", function()
		local f = input()
		f.category = 600
		f.closing_velocity = { f32(0.2), 0.0, 0.0, 0.0 }
		local s = settings()
		s.air.xz_trick = f32(0.1)
		s.air.y_trick = f32(0.6)
		local foot = Requests.new()
		wipeout.check_plant(foot, s, f)
		assert(foot.reasons[3])
		local hand = Requests.new()
		wipeout.check_air(hand, s, mode(), f, false)
		assert(hand.count == 0)
		f.closing_velocity = { 11.0, 0.0, 0.0, 0.0 }
		wipeout.check_air(hand, s, mode(), f, false)
		assert(hand.reasons[3])
	end)
	harness.test(report, "wipeout: ground_priority_and_repeated_force_change_runout_selection", function()
		local state, f, s = Requests.new(), input(), settings()
		f.closing_velocity = { 11.0, 0.0, 0.0, 0.0 }
		wipeout.check_ground(state, s, mode(), f)
		assert(state.count == 1 and state.reasons[3])
		assert(Requests.requests_runout(state, request_input()))
		assert(not Requests.requests_wipeout(state, request_input()))
		Requests.clear_after_selection(state)
		f.maximum_pose_error = 101.0
		f.pose_error = { 101.0, 0.0, 0.0, 0.0 }
		f.regions_force[1] = 101.0
		wipeout.check_ground(state, s, mode(), f)
		assert(state.count == 3)
		assert(state.reasons[19] and state.reasons[3] and state.reasons[1])
		assert(not state.reasons[2])
		assert(not Requests.requests_runout(state, request_input()))
		assert(Requests.requests_wipeout(state, request_input()))
		Requests.clear_after_selection(state)
		f.maximum_pose_error = 0.0
		f.pose_error = { 0.0, 0.0, 0.0, 0.0 }
		wipeout.check_ground(state, s, mode(), f)
		assert(state.count == 3)
		assert(count_true(state.reasons) == 2)
	end)
	harness.test(report, "wipeout: air_landing_uses_selected_velocity_and_preserves_impact_value", function()
		local state, f, s = Requests.new(), input(), settings()
		f.deck_velocity = { 0.0, -2.0, 0.0, 0.0 }
		f.com_velocity = { 0.0, -7.0, 0.0, 0.0 }
		wipeout.check_air(state, s, mode(), f, false)
		assert(state.count == 0)
		wipeout.check_air(state, s, mode(), f, true)
		assert(state.count == 1 and state.reasons[7] and state.values[7] == 7.0)
		Requests.clear_after_selection(state)
		f.grind_selected = true
		f.grind_normal_valid = true
		f.grind_normal = { 1.0, 0.0, 0.0, 0.0 }
		wipeout.check_air(state, s, mode(), f, true)
		assert(state.count == 0)
		f.grind_normal_valid = false
		wipeout.check_air(state, s, mode(), f, true)
		assert(state.count == 1 and state.reasons[9] and not state.reasons[7])
	end)
	harness.test(report, "wipeout: sensitive_conditions_count_both_triggers_and_clear_only_requests", function()
		local state, f = Requests.new(), input()
		f.flags_2476 = bit32.lshift(1, 26)
		f.flags_2472 = bit32.lshift(1, 6)
		f.compliant = true
		wipeout.check_air(state, settings(), mode(), f, false)
		assert(state.count == 2 and state.reasons[22] and count_true(state.reasons) == 1)
		state.balance = 3.0
		state.cooldown = f32(0.2)
		Requests.clear_after_selection(state)
		assert(state.count == 0 and state.balance == 3.0 and state.cooldown == f32(0.2) and state.mode == 2 and state.contact_frames == 3)
		Requests.reset_systems(state)
		assert(state.mode == 0 and state.balance == 3.0 and state.cooldown == f32(0.2))
	end)
	harness.test(report, "wipeout: cooldown_has_native_initial_and_teleport_lifetimes", function()
		local state, f = Requests.new(), input()
		Requests.initialize_player(state)
		assert(rt.to_bits(state.cooldown) == 0x3d23d70a)
		f.maximum_pose_error = 101.0
		wipeout.check_air(state, settings(), mode(), f, false)
		assert(state.count == 0 and state.contact_frames == 3 and state.cooldown > 0.0)
		Requests.teleport(state)
		assert(rt.to_bits(state.cooldown) == 0x3ecccccd)
		Requests.reset_systems(state)
		assert(rt.to_bits(state.cooldown) == 0x3ecccccd)
		state.cooldown = f32(0.001)
		wipeout.check_ground(state, settings(), mode(), f)
		assert(state.cooldown < 0.0 and state.count == 0)
		wipeout.check_ground(state, settings(), mode(), f)
		assert(state.count == 1 and state.reasons[19])
	end)
	harness.test(report, "wipeout: ground_animation_keeps_additional_checks_during_cooldown", function()
		local state, f = Requests.new(), input()
		Requests.teleport(state)
		f.regions_force[1] = 101.0
		f.opposing_contact = 1.5
		wipeout.check_ground_animation(state, settings(), mode(), f, 1.0)
		assert(state.count == 2 and state.reasons[1] and state.reasons[21])
		Requests.clear_after_selection(state)
		wipeout.check_ground_animation(state, settings(), mode(), f, 2.0)
		assert(state.count == 1 and state.reasons[1] and not state.reasons[21])
	end)

	harness.test(report, "wipeout: все проверки и Requests последовательно vs Rust", function()
		for n, c in golden do
			local q = Requests.new()
			if c.init == 1 then
				Requests.initialize_player(q)
			elseif c.init == 2 then
				Requests.teleport(q)
			end
			for k, st in c.steps do
				local w = string.format("wipeout#%d step#%d (action %d)", n, k, st.action)
				local a, f = st.action, st.frame
				if a == 0 or a == 1 then
					wipeout.check_air(q, c.settings, st.mode, f, st.use_com)
				elseif a == 2 then
					wipeout.check_air_collision(q, c.settings, st.mode, f)
				elseif a == 3 or a == 4 then
					wipeout.check_ground(q, c.settings, st.mode, f)
				elseif a == 5 then
					wipeout.check_ground_animation(q, c.settings, st.mode, f, st.scale)
				elseif a == 6 then
					wipeout.check_plant(q, c.settings, f)
				elseif a == 7 then
					post.check(q, c.post, f)
				elseif st.sub then
					Requests.clear_after_selection(q)
				else
					Requests.reset_systems(q)
				end
				check(u.diff(q, st.requests), w)
				local ri = {
					flags_2468 = f.flags_2468, flags_2476 = f.flags_2476, flags_2480 = f.flags_2480, flags_2484 = f.flags_2484,
					animation_up_y = f.animation_up[2], category = f.category,
				}
				assert(Requests.requests_runout(q, ri) == st.runout, w .. " runout")
				assert(Requests.requests_wipeout(q, ri) == st.wipeout, w .. " wipeout")
				if st.clear then
					Requests.clear_after_selection(q)
				end
			end
		end
	end)
end
