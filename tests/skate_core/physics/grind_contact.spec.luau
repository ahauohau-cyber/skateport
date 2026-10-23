--!strict
-- Сверка physics::grind_contact с настоящим Rust (golden/src/grind.rs) +
-- перенос Rust-тестов (tests.rs, admission_tests, entry_tests,
-- investigator_tests, manager_tests, balance_tests).

local harness = require("../../harness")
local u = require("../../util")
local rt = require("../../../src/rt")
local gc = require("../../../src/skate_core/physics/grind_contact")
local grind_surface = require("../../../src/skate_core/air/trajectory/grind_surface")
local golden = require("../../golden/grind") :: any
assert(type(golden) == "table", tostring(golden))

local f32 = rt.f32
local families = gc.families
local admission = gc.admission
local entry = gc.entry
local control = gc.control
local investigator = gc.investigator
local manager = gc.manager
local balance = gc.balance
local Admission = admission.Admission
local EntryKind = admission.EntryKind
local GeometryType = grind_surface.GeometryType
local BalanceState = balance.BalanceState

local X = { 1.0, 0.0, 0.0, 0.0 }
local Y = { 0.0, 1.0, 0.0, 0.0 }
local Z = { 0.0, 0.0, 1.0, 0.0 }
local O = { 0.0, 0.0, 0.0, 0.0 }
local BOARD = { X, Y, Z, O }
local GRAPH = { x = { 0.0, f32(0.3), f32(0.7), 1.0 }, y = { 1.0, 1.0, 1.0, 1.0 } }

local function check(d: string?, what: string)
	if d then
		error(what .. d, 2)
	end
end
local function deep(t: any): any
	if type(t) ~= "table" then
		return t
	end
	local c = {}
	for k, v in t do
		c[k] = deep(v)
	end
	return c
end
local function V(a: number, b: number, c: number, d: number?): { number }
	return { f32(a), f32(b), f32(c), f32(d or 0.0) }
end
local function close(a: { number }, b: { number })
	for i = 1, 4 do
		assert(math.abs(a[i] - b[i]) < 0.00001, string.format("lane%d: %g vs %g", i - 1, a[i], b[i]))
	end
end
local function adm(category: number, state: number): any
	return { category = category, state = state, speed = 2.0, velocity = { 0.0, 0.0, 2.0, 0.0 }, threshold_vs_slope = GRAPH }
end
local function rail(start: { number }, end_: { number }): any
	return { start = start, ["end"] = end_, owner = 1 }
end
local function with(t: any, fields: any): any
	local c = table.clone(t)
	for k, v in fields do
		c[k] = v
	end
	return c
end
local function contact_l(c: any): any
	if c == nil then
		return { some = false }
	end
	return { some = true, geometry = c.geometry, front = c.front, kind = c.kind, entry_kind = c.entry_kind }
end

local function rust_tests(report: harness.Report)
	-- tests.rs
	harness.test(report, "grind_contact: one_truck_admission_happens_before_front_rear_selection", function()
		local edges = { rail(O, V(0.5, 0, 0.8660254)), rail(O, Z) }
		local hits: any = { { position = V(0, 0, 0.2), primitive = 0 }, { position = V(0, 0, -0.2), primitive = 1 } }
		local result = families.five_o(BOARD, hits, edges, { 0.0, 0.0, 2.0, 0.0 }, 0, 0, 0, 1.0, adm(400, 400)) :: any
		assert(not result.front)
		assert(result.geometry.primitive == 1)
		assert(result.entry_kind == EntryKind.ChangeGrind)
	end)
	harness.test(report, "grind_contact: tipslide_drop_in_rejects_contact_above_deck_without_descent", function()
		local edges = { rail(O, Z) }
		local hit = { position = V(0, 0.01, 0.2), primitive = 0 }
		local input = with(adm(100, 100), { speed = 1.0, velocity = V(0, 0.1, 0) })
		assert(families.tipslide(BOARD, { hit, false }, edges, input.velocity, 100, 0, 0, 0, 0.0, BOARD[1], input) == nil)
	end)
	harness.test(report, "grind_contact: darkslide_uses_its_own_tilt_and_depth_thresholds", function()
		local edges = { rail(O, Z) }
		local board = { V(-0.6, -0.8, 0), V(0.8, -0.6, 0), Z, V(0.056, -0.042, 0) }
		local hit = { position = O, primitive = 0 }
		assert(families.darkslide(board, hit, edges[1], V(0, 0, 2), 200, 0, adm(200, 201)) ~= nil)
		local deeper = table.clone(board)
		deeper[4] = gc.scale(board[2], f32(0.08))
		assert(families.darkslide(deeper, hit, edges[1], V(0, 0, 2), 200, 0, adm(200, 201)) == nil)
	end)
	harness.test(report, "grind_contact: one_truck_clamps_match_both_originals_not_zip_reversed_signs", function()
		for _, c: any in {
			{ true, -0.3, 0.5, 0.0 },
			{ true, -0.3, -0.5, -0.011249996 },
			{ false, 0.3, -0.5, 0.0 },
			{ false, 0.3, 0.5, 0.011249996 },
			{ true, 0.3, -0.5, 0.0 },
			{ true, 0.3, 0.5, 0.011249996 },
			{ false, -0.3, 0.5, 0.0 },
			{ false, -0.3, -0.5, -0.011249996 },
		} do
			local ctl = control.Control.default()
			control.Control.update(ctl, 3, Z, V(0, 1, c[2]), c[1], false, false, 0.0, 0.0, f32(c[3]), 0.0)
			assert(math.abs(ctl.pitch - c[4]) < 1e-7, tostring(ctl.pitch))
		end
	end)
	-- admission_tests.rs
	local RAIL = X
	local function context(category: number, state: number, velocity: { number }): any
		return { category = category, state = state, speed = 2.0, velocity = velocity, threshold_vs_slope = GRAPH }
	end
	harness.test(report, "grind_contact/admission: current_grind_and_family_change_have_different_angle_gates", function()
		local input = context(400, 401, V(0.8660254, 0, 0.5))
		check(u.diff(Admission.test(input, 401, RAIL, false), { kind = EntryKind.StayInGrind, allowed = true }), "stay")
		check(u.diff(Admission.test(input, 403, RAIL, true), { kind = EntryKind.ChangeGrind, allowed = false }), "change")
		assert(Admission.test(with(input, { state = 404 }), 402, RAIL, true).kind == EntryKind.StayInGrind)
	end)
	harness.test(report, "grind_contact/admission: ground_entries_distinguish_above_below_coping_and_drop_in", function()
		local above = context(100, 100, V(2, -1, 0))
		assert(Admission.test(above, 401, RAIL, false).kind == EntryKind.RideFromAbove)
		assert(Admission.test(context(100, 100, V(2, 1, 1)), 401, RAIL, false).kind == EntryKind.RideFromBelow)
		assert(Admission.test(context(100, 100, V(2, 1, 0)), 401, RAIL, false).kind == EntryKind.RideIntoCoping)
		local drop_in = with(above, { speed = 1.0 })
		check(u.diff(Admission.test(drop_in, 403, RAIL, true), { kind = EntryKind.DropIn, allowed = true }), "drop")
		assert(Admission.test(drop_in, 401, RAIL, false).kind == EntryKind.RideFromAbove)
		assert(Admission.test(with(drop_in, { speed = f32(1.45) }), 403, RAIL, true).kind ~= EntryKind.DropIn)
	end)
	harness.test(report, "grind_contact/admission: coping_admission_uses_cross_rail_speed_and_the_authored_graph", function()
		local slow = context(100, 100, V(1, 1, 0))
		assert(Admission.test(slow, 401, RAIL, false).allowed)
		assert(not Admission.test(context(100, 100, V(1, 10, 0)), 401, RAIL, false).allowed)
		local zero = { x = GRAPH.x, y = { 0.0, 0.0, 0.0, 0.0 } }
		assert(not Admission.test(with(slow, { threshold_vs_slope = zero }), 401, RAIL, false).allowed)
	end)
	harness.test(report, "grind_contact/admission: airborne_admission_and_projection_keep_the_original_leaf_boundary", function()
		check(u.diff(Admission.test(context(200, 201, V(0, 0, 8)), 401, RAIL, false), { kind = EntryKind.AirToGrind, allowed = true }), "air")
		assert(Admission.test(context(100, 100, V(0, -8, 0)), 401, RAIL, false).allowed)
		assert(admission.approach_slope_sine(RAIL, V(3, 0, 0)) == 0.0)
		assert(admission.approach_slope_sine(RAIL, V(3, 0.01, 0)) == 0.0)
	end)
	-- entry_tests.rs
	local HELP = { x = { -1.0, 0.0, 0.5, 1.0 }, y = { 0.0, 0.0, 0.0, 0.0 } }
	local function einput(fields: any?): any
		local t = {
			valid = true, kind = 0, category = 200, previous_state_2504 = 200,
			speed = 4.0, balance_2720 = 0.0, direction = X, normal = Y, up = Y,
			board_velocity = V(4, -2, 3), air_velocity = V(4, -2, 3),
			surface_kind = 0, high_side = Z, vertical_help = HELP,
			max_delta = 100.0, flags = 0, previous_entry_velocity = { 9.0, 9.0, 9.0, 9.0 },
		}
		return if fields then with(t, fields) else t
	end
	local Engagement = entry.Engagement
	harness.test(report, "grind_contact/entry: ground_and_air_use_different_velocity_projections", function()
		local state = Engagement.default()
		local air = Engagement.update(state, einput())
		local ground = Engagement.update(state, einput({ category = 100 }))
		assert(math.abs(air.entry_velocity[2] + 2.0) < 0.00001)
		assert(math.abs(air.entry_velocity[3] - 1.8) < 0.00001)
		assert(math.abs(ground.entry_velocity[2] + 1.6) < 0.00001)
		assert(math.abs(ground.entry_velocity[3] - 2.4) < 0.00001)
	end)
	harness.test(report, "grind_contact/entry: steep_ground_entry_rejects_without_air_wipeout", function()
		local state = Engagement.default()
		local air = Engagement.update(state, einput({ up = X }))
		assert(not air.valid)
		check(u.diff(air.wipeout_reasons, { 13 }), "air")
		local ground = Engagement.update(state, einput({ up = X, category = 100 }))
		assert(not ground.valid)
		assert(#ground.wipeout_reasons == 0)
		assert(not bit32.btest(ground.flags, 0x4000_0000))
	end)
	harness.test(report, "grind_contact/entry: both_impact_requests_survive_first_rejection_including_on_ground", function()
		local result = Engagement.update(Engagement.default(), einput({ category = 100, max_delta = 0.0, board_velocity = V(4, 0, 8) }))
		assert(not result.valid)
		check(u.diff(result.wipeout_reasons, { 9, 14 }), "reasons")
	end)
	harness.test(report, "grind_contact/entry: tipslide_latch_counts_down_during_invalid_investigations", function()
		local state = Engagement.default()
		local result = Engagement.update(state, einput({ kind = 2, previous_state_2504 = 403 }))
		assert(bit32.btest(result.flags, 0x0200_0000))
		assert(state.tipslide_frames == 8)
		for remaining = 7, 0, -1 do
			local r = Engagement.update(state, einput({ valid = false }))
			assert(state.tipslide_frames == remaining)
			check(u.diff(r.entry_velocity, { 9.0, 9.0, 9.0, 9.0 }), "velocity")
			assert(r.impact_speed == 0.0)
		end
		Engagement.update(state, einput({ valid = false }))
		assert(state.tipslide_frames == 0)
	end)
	harness.test(report, "grind_contact/entry: coping_and_entry_slope_dead_zones_are_distinct", function()
		local velocity = V(1, 0.005, 0)
		assert(admission.approach_slope_sine(X, velocity) == 0.0)
		assert(math.abs(admission.engagement_slope_sine(X, velocity) - 1.0) < 0.00001)
	end)
	-- investigator_tests.rs
	harness.test(report, "grind_contact/investigator: fallback_keeps_native_contact_order_and_classifies_only_ordinary_deck", function()
		local function hit(p: number): any
			return { position = O, primitive = p }
		end
		local r: any = investigator.fallback({ hit(1), hit(2) }, hit(3), hit(4), { hit(5), hit(6) })
		assert(r.contact.primitive == 1 and not r.deck_contact)
		r = investigator.fallback({ false, false }, hit(3), hit(4), { hit(5), hit(6) })
		assert(r.contact.primitive == 3 and r.deck_contact)
		r = investigator.fallback({ false, false }, nil, hit(4), { hit(5), hit(6) })
		assert(r.contact.primitive == 4 and not r.deck_contact)
		r = investigator.fallback({ false, false }, nil, nil, { false, hit(6) })
		assert(r.contact.primitive == 6 and not r.deck_contact)
		assert(investigator.fallback({ false, false }, nil, nil, { false, false }) == nil)
	end)
	-- manager_tests.rs
	local function geometry(fields: any?): any
		local t = {
			valid = true, family = 2, current_state = 100, category = 100,
			air_frames = 0, geometry_kind = 2, geometry_flags = 0,
			far_points = { V(0, 0.1, 0.2), V(0, -0.1, -0.2) },
			upmost = Y, high_side = Z, point = O, direction = X,
			board_position = V(0, 0.1, 0.2), board_forward = X,
			velocity = X, deck_to_truck = f32(0.243),
			previous_exit_angle = 0.0, previous_exit_direction = X, flags = 0,
		}
		return if fields then with(t, fields) else t
	end
	harness.test(report, "grind_contact/manager: backslash_uses_height_difference_and_preserves_existing_tipslide", function()
		local counter = { value = 0 }
		assert(manager.tweak_geometry(geometry(), counter).family == 4)
		assert(manager.tweak_geometry(geometry({ current_state = 402 }), counter).family == 2)
		assert(manager.tweak_geometry(geometry({ board_position = V(0, 0, -1) }), counter).family == 2)
	end)
	harness.test(report, "grind_contact/manager: five_o_hanging_deck_sets_pry_then_excludes_thirty_frames", function()
		local counter = { value = 0 }
		local input = geometry({ family = 3, board_forward = V(0, -0.1, 0.9) })
		local result = manager.tweak_geometry(input, counter)
		assert(not result.valid)
		assert(bit32.btest(result.flags, 0x1000_0000))
		assert(counter.value == 30)
		assert(not manager.tweak_geometry(with(input, { board_forward = X }), counter).valid)
	end)
	harness.test(report, "grind_contact/manager: coping_timer_is_reduced_on_activation_and_expires_without_contact", function()
		local vertical = { x = { -1.0, 0.0, 1.0, 2.0 }, y = { 2.0, 2.0, 2.0, 2.0 } }
		local linear = { x = { 0.0, 1.0, 2.0, 3.0 }, y = { 0.5, 0.5, 0.5, 0.5 } }
		local timer = { value = 0.0 }
		assert(manager.gravity_relief(timer, true, 100, X, V(3, 1, 0), 0.25, vertical, linear) == 0.75)
		assert(manager.gravity_relief(timer, false, 200, X, V(3, 1, 0), 1.0, vertical, linear) == 0.0)
	end)
	harness.test(report, "grind_contact/manager: jumper_retains_geometry_and_regenerates_per_update_not_per_second", function()
		local jumper = manager.Jumper.default()
		jumper.cooldown = 2
		jumper.energy = f32(0.4)
		assert(manager.Jumper.update(jumper, nil, 0xFFFF_FFFF) == 0x0200_0000)
		assert(jumper.family == 3)
		check(u.diff(jumper.geometry.normal, Y), "normal")
		assert(jumper.energy == f32(f32(0.4) + f32(0.0035)))
		assert(manager.Jumper.update(jumper, nil, 5) == 0)
		assert(jumper.family == 5)
	end)
	harness.test(report, "grind_contact/manager: directed_rail_retains_previous_sign_only_at_low_speed", function()
		assert(manager.directed_tangent(O, X, V(0.05, 0, 0), V(-1, 0, 0))[1] < 0.0)
		assert(manager.directed_tangent(O, X, V(0.1, 0, 0), V(-1, 0, 0))[1] > 0.0)
	end)
	-- balance_tests.rs
	local negate = balance.negate
	local function surface(kind: number): any
		return {
			center = O, far_points = { negate(Z), Z }, upmost_normal = Y, direction = Z, high_side = X,
			normal_limits = { 0.0, 6.0 }, kind = kind, audio_surface = 0, physics_surface = 0, flags = 0,
			tilted_upmost_normal = Y,
		}
	end
	local function bcontact(s: any, kind: number, entry_kind: number): any
		return { surface = s, primitive_direction = Z, directed_grind_direction = Z, kind = kind, entry_kind = entry_kind }
	end
	local function vectors(): any
		return { grind_normal = Y, target_up = Y }
	end
	local function exit_input(dt: number): any
		return { category = 100, current_state = 100, grind_substate = 0, timestep = f32(dt) }
	end
	local LEAN = { x = { 0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0 }, y = { 0.0, 10.0, 20.0, 30.0, 40.0, 50.0, 60.0, 70.0 } }
	harness.test(report, "grind_contact/balance: constructor_and_invalid_target_preserve_the_source_history", function()
		local state = BalanceState.default()
		check(u.diff(state, { elapsed = 0.0, exit_angle_degrees = 0.0, entry_delay = 2.0, frames_away = 21, previous_normal = Y, exit_direction = X }), "default")
		local original = deep(state)
		local output = { grind_normal = X, target_up = Z }
		BalanceState.update_target_up(state, { category = 400, previous_state = 402, board_up = Y }, nil, output)
		check(u.diff(state, original), "state")
		check(u.diff(output, { grind_normal = X, target_up = Z }), "output")
	end)
	harness.test(report, "grind_contact/balance: target_selects_previous_tip_state_and_separate_tilted_normal", function()
		local g = surface(GeometryType.Ledge)
		g.tilted_upmost_normal = X
		local candidate = bcontact(g, 1, EntryKind.StayInGrind)
		for _, previous_state in { 400, 402, 404 } do
			local state = BalanceState.default()
			local output = vectors()
			BalanceState.update_target_up(state, { category = 400, previous_state = previous_state, board_up = Y }, candidate, output)
			if previous_state == 400 then
				local a, b = rt.from_bits(0x3d99_9998), 0.925
				local l = math.sqrt(a * a + b * b)
				close(output.grind_normal, { a / l, b / l, 0.0, 0.0 })
			else
				close(output.grind_normal, Y)
			end
			check(u.diff(state.previous_normal, output.grind_normal), "previous")
		end
	end)
	harness.test(report, "grind_contact/balance: target_non_grind_uses_current_up_and_projection_fallback", function()
		local candidate = bcontact(surface(GeometryType.ThinRail), 0, EntryKind.AirToGrind)
		local state = BalanceState.default()
		local output = vectors()
		BalanceState.update_target_up(state, { category = 200, previous_state = 402, board_up = X }, candidate, output)
		close(output.grind_normal, X)
		BalanceState.update_target_up(state, { category = 200, previous_state = 402, board_up = Z }, candidate, output)
		close(output.grind_normal, Y)
	end)
	harness.test(report, "grind_contact/balance: target_clamps_to_fourteen_degrees_with_the_native_rotation", function()
		local candidate = bcontact(surface(GeometryType.Ledge), 1, EntryKind.StayInGrind)
		local state = BalanceState.default()
		local output = vectors()
		BalanceState.update_target_up(state, { category = 400, previous_state = 400, board_up = X }, candidate, output)
		local angle = math.rad(14)
		close(output.target_up, { math.sin(angle), math.cos(angle), 0.0, 0.0 })
		close(state.previous_normal, Y)
		BalanceState.update_target_up(state, { category = 400, previous_state = 400, board_up = negate(Y) }, candidate, output)
		close(output.target_up, Y)
	end)
	harness.test(report, "grind_contact/balance: quaternion_rotation_preserves_axis_component_and_direction", function()
		local half_pi = rt.from_bits(0x3fc9_0fdb)
		local rotate = balance.rotate
		close(rotate(Z, X, half_pi), Y)
		close(rotate(Z, Y, half_pi), negate(X))
		close(rotate(Y, Z, half_pi), X)
		close(rotate(Z, { 1.0, 0.0, 2.0, 0.0 }, half_pi), { 0.0, 1.0, 2.0, 0.0 })
		close(rotate(Z, X, -half_pi), negate(Y))
	end)
	harness.test(report, "grind_contact/balance: exit_entry_delays_and_tipslide_geometry_eligibility", function()
		for _, c: any in {
			{ EntryKind.RideFromBelow, f32(0.8) },
			{ EntryKind.RideIntoCoping, f32(0.1) },
			{ EntryKind.RideFromAbove, 2.0 },
			{ EntryKind.StayInGrind, 2.0 },
			{ EntryKind.ChangeGrind, 2.0 },
			{ EntryKind.AirToGrind, 2.0 },
			{ EntryKind.DropIn, 2.0 },
		} do
			local state = BalanceState.default()
			BalanceState.update_exit_lean(state, exit_input(0.01), bcontact(surface(GeometryType.Ledge), 1, c[1]), LEAN, vectors())
			assert(state.entry_delay == c[2])
			assert(state.elapsed == f32(0.01))
			assert(state.frames_away == 0)
			assert(state.exit_angle_degrees == 0.0)
		end
		for _, gt in { GeometryType.ThinRail, GeometryType.FatRail, GeometryType.Ledge } do
			for kind = 0, 5 do
				local state = BalanceState.default()
				BalanceState.update_exit_lean(state, exit_input(0.01), bcontact(surface(gt), kind, EntryKind.RideFromAbove), LEAN, vectors())
				local starts = gt == GeometryType.Ledge or (kind == 2 and gt ~= GeometryType.ThinRail)
				assert((state.elapsed > 0.0) == starts, string.format("kind%d %d", kind, gt))
			end
		end
	end)
	harness.test(report, "grind_contact/balance: exit_substate_two_freezes_time_and_zero_dt_does_not_update_side", function()
		local g = surface(GeometryType.Ledge)
		g.high_side = negate(X)
		local candidate = bcontact(g, 1, EntryKind.RideIntoCoping)
		local state = BalanceState.default()
		local input = exit_input(0.2)
		input.grind_substate = 2
		BalanceState.update_exit_lean(state, input, candidate, LEAN, vectors())
		assert(state.elapsed == 0.0)
		assert(state.entry_delay == f32(0.1))
		check(u.diff(state.exit_direction, X), "x")
		input.grind_substate = 0
		BalanceState.update_exit_lean(state, input, candidate, LEAN, vectors())
		check(u.diff(state.exit_direction, negate(X)), "-x")
		local old = state.elapsed
		input.grind_substate = 2
		BalanceState.update_exit_lean(state, input, candidate, LEAN, vectors())
		assert(state.elapsed == old)
		local s2 = BalanceState.default()
		BalanceState.update_exit_lean(s2, exit_input(0.0), candidate, LEAN, vectors())
		check(u.diff(s2.exit_direction, X), "zero dt")
	end)
	harness.test(report, "grind_contact/balance: exit_history_retains_twenty_away_frames_then_resets_only_timers", function()
		local state = BalanceState.default()
		BalanceState.update_exit_lean(state, exit_input(0.2), bcontact(surface(GeometryType.Ledge), 1, EntryKind.RideIntoCoping), LEAN, vectors())
		local output = { grind_normal = X, target_up = Z }
		for count = 1, 20 do
			BalanceState.update_exit_lean(state, exit_input(0.01), nil, LEAN, output)
			assert(state.frames_away == count)
			assert(state.elapsed > 0.0)
		end
		check(u.diff(output, { grind_normal = X, target_up = Z }), "output")
		state.previous_normal = Z
		state.exit_direction = negate(X)
		BalanceState.update_exit_lean(state, exit_input(0.01), nil, LEAN, output)
		assert(state.elapsed == 0.0 and state.exit_angle_degrees == 0.0 and state.entry_delay == 2.0)
		check(u.diff(state.previous_normal, Z), "prev")
		check(u.diff(state.exit_direction, negate(X)), "exit")
		state.frames_away = 2147483647
		state.elapsed = 1.0
		BalanceState.update_exit_lean(state, exit_input(0.01), nil, LEAN, output)
		assert(state.frames_away == -2147483648)
		assert(state.elapsed > 1.0)
	end)
	harness.test(report, "grind_contact/balance: grind_category_and_current_701_keep_existing_timer_alive_without_contact", function()
		for _, c in { { 400, 401 }, { 700, 701 } } do
			local state = BalanceState.default()
			state.elapsed = f32(0.5)
			state.frames_away = 20
			local input = with(exit_input(0.1), { category = c[1], current_state = c[2] })
			BalanceState.update_exit_lean(state, input, nil, LEAN, vectors())
			assert(state.frames_away == 0)
			assert(state.elapsed == f32(f32(0.1) + f32(0.5)))
		end
	end)
	harness.test(report, "grind_contact/balance: exit_side_continuity_and_both_output_rotations_leave_history_unrotated", function()
		local g = surface(GeometryType.Ledge)
		local state = BalanceState.default()
		local output = vectors()
		local angle = BalanceState.update_exit_lean(state, exit_input(0.6), bcontact(g, 1, EntryKind.RideIntoCoping), LEAN, output)
		assert(math.abs(angle - 5.0) < 0.00001)
		local radians = math.rad(angle)
		local expected = { -math.sin(radians), math.cos(radians), 0.0, 0.0 }
		close(output.grind_normal, expected)
		close(output.target_up, expected)
		check(u.diff(state.previous_normal, Y), "prev")
		g.high_side = negate(X)
		BalanceState.update_exit_lean(state, exit_input(0.0), bcontact(g, 1, EntryKind.StayInGrind), LEAN, vectors())
		close(state.exit_direction, X)
		g.kind = GeometryType.ThinRail
		local candidate = bcontact(g, 0, EntryKind.StayInGrind)
		candidate.directed_grind_direction = negate(Z)
		BalanceState.update_exit_lean(state, exit_input(0.0), candidate, LEAN, vectors())
		close(state.exit_direction, X)
		state.exit_direction = Z
		BalanceState.update_exit_lean(state, exit_input(0.0), candidate, LEAN, vectors())
		close(state.exit_direction, negate(X))
	end)
	harness.test(report, "grind_contact/balance: force_exit_thresholds_query_geometry_and_other_bits", function()
		local location = { 4.0, 3.0, 2.0, 0.0 }
		for _, c: any in { { 15.0, false, 0 }, { 15.001, true, 1 }, { 28.0, true, 1 }, { 28.001, true, 0 } } do
			local state = BalanceState.default()
			state.exit_angle_degrees = f32(c[1])
			local flags = { value = 0x8123_4567 }
			local calls = 0
			BalanceState.update_force_exit(state, location, flags, function(probe)
				calls += 1
				check(u.diff(probe, { start = V(3.9, 3, 2), ["end"] = V(3.9, -2, 2) }), "probe")
				return nil
			end)
			assert(calls == c[3])
			assert(bit32.band(flags.value, 0x7fff_ffff) == 0x0123_4567)
			assert(bit32.btest(flags.value, 0x8000_0000) == c[2])
		end
	end)
	harness.test(report, "grind_contact/balance: force_exit_normal_comparison_is_strict_and_query_errors_preserve_flags", function()
		local state = BalanceState.default()
		state.exit_angle_degrees = 20.0
		for _, c: any in { { -0.10001, false }, { -0.1, false }, { -0.09999, true } } do
			local flags = { value = 0x8123_4567 }
			BalanceState.update_force_exit(state, O, flags, function(_)
				return { normal = V(c[1], 1, 0) }
			end)
			assert(bit32.btest(flags.value, 0x8000_0000) == c[2])
		end
		local flags = { value = 0x8123_4567 }
		local _, err = rt.catch(BalanceState.update_force_exit, state, O, flags, function(_): any
			rt.raise("world unavailable")
			return nil
		end)
		assert(err == "world unavailable")
		assert(flags.value == 0x8123_4567)
	end)
end

local function golden_tests(report: harness.Report)
	harness.test(report, "grind_contact: segment_triangle, контакты, upright, Admission vs Rust", function()
		for n, c in golden.segment do
			local out = gc.segment_triangle(c.start, c.finish, c.triangle)
			assert((out ~= nil) == c.some, "segment#" .. n)
			if out then
				check(u.diff(out, c.out), "segment#" .. n)
			end
		end
		for n, c in golden.contacts do
			local w = "contacts#" .. n
			check(u.diff(gc.truck_contacts(c.board, c.flags, c.truck_to_wheel, c.deck_center_to_truck, c.edges), c.trucks), w .. " trucks")
			check(u.diff(gc.deck_contact(c.board, c.flags, c.above, c.below, c.deck_center_to_truck, c.edges) or false, c.deck), w .. " deck")
			check(u.diff(families.inverted_contact(c.board, c.flags, c.above, c.below, c.edges) or false, c.inverted), w .. " inverted")
			check(u.diff(families.tip_contacts(c.board, c.flags, c.state, c.flags_2468, c.deck_center_to_truck, c.edges), c.tips), w .. " tips")
		end
		for n, c in golden.upright do
			local w = "upright#" .. n
			check(u.diff(gc.upright_normal(c.direction), c.normal), w)
			assert(gc.within_approach_angle(c.direction, c.velocity, c.degrees) == c.within, w .. " within")
			check(u.diff(admission.approach_slope_sine(c.direction, c.velocity), c.approach), w .. " approach")
			check(u.diff(admission.engagement_slope_sine(c.direction, c.velocity), c.engagement), w .. " engagement")
		end
		for n, c in golden.admission do
			check(u.diff(Admission.test(c.adm, c.requested, c.tangent, c.drop_in), { kind = c.kind, allowed = c.allowed }), "admission#" .. n)
		end
	end)
	harness.test(report, "grind_contact/families: boardslide, 50-50, 5-0, tipslide, darkslide, backslash vs Rust", function()
		local counts = { slide = 0, ff = 0, five = 0, tip = 0, dark = 0 }
		for n, c in golden.families do
			local w = "families#" .. n
			local a = c.adm
			local deck = if c.deck then c.deck else nil
			local slide = if deck then gc.boardslide_candidate(c.board, deck, c.edges[deck.primitive + 1], a.velocity, a.category, c.frames, c.flags_2476, c.deck_center_to_truck, c.truck_to_wheel, a) else nil
			assert((slide ~= nil) == c.slide_some, w .. " slide some")
			if slide then
				counts.slide += 1
				check(u.diff(slide, c.slide), w .. " slide")
			end
			local ff = gc.fifty_fifty_candidate_on_splines(c.board, { c.translation, c.nudge }, c.trucks, c.edges)
			assert((ff ~= nil) == c.ff_some, w .. " ff some")
			if ff then
				counts.ff += 1
				check(u.diff(ff, c.ff), w .. " ff")
			end
			local five = families.five_o(c.board, c.trucks, c.edges, a.velocity, c.flags_2476, c.flags_2472, c.ground_frames, c.translation, a)
			check(u.diff(contact_l(five), c.five), w .. " five")
			local tip = families.tipslide(c.board, c.tips, c.edges, a.velocity, a.category, c.flags_2476, c.flags_2472, c.ground_frames, c.balance, c.reference_right, a)
			check(u.diff(contact_l(tip), c.tip), w .. " tip")
			local inv = if c.inverted then c.inverted else nil
			local dark = if inv then families.darkslide(c.inv_board, inv, c.edges[inv.primitive + 1], a.velocity, a.category, c.frames, a) else nil
			check(u.diff(contact_l(dark), c.dark), w .. " dark")
			if five then counts.five += 1 end
			if tip then counts.tip += 1 end
			if dark then counts.dark += 1 end
			local bs = c.bs
			assert(families.is_backslash(c.board[4], bs.point, bs.far_points, bs.support, bs.truck_distance, bs.state) == bs.out, w .. " backslash")
		end
		table.insert(report.lines, string.format("      семейства: slide %d, 50-50 %d, 5-0 %d, tip %d, dark %d из %d", counts.slide, counts.ff, counts.five, counts.tip, counts.dark, #golden.families))
	end)
	harness.test(report, "grind_contact/entry + control: Engagement, скорости входа, Control, кадры vs Rust", function()
		for n, case in golden.engagement do
			local eng = entry.Engagement.default()
			for k, st in case.steps do
				local w = string.format("engagement#%d step#%d", n, k)
				local input = with(st.input, { vertical_help = case.help })
				local out = entry.Engagement.update(eng, input)
				check(u.diff(out, st.out), w)
				assert(eng.tipslide_frames == st.frames, w .. " frames")
				check(u.diff(entry.airborne_rejections(input.direction, input.up, input.board_velocity, input.air_velocity, out.entry_velocity, input.surface_kind, input.high_side, input.max_delta), st.rejections), w .. " rejections")
			end
		end
		for n, case in golden.control do
			local ctl = control.Control.default()
			for k, st in case do
				local w = string.format("control#%d step#%d", n, k)
				control.Control.update(ctl, st.kind, st.board[3], st.normal, st.front, st.switched, st.hanging_back, st.translation, st.nudge, st.up_down, st.grab_min_height)
				check(u.diff({ ctl.yaw, ctl.pitch }, { st.yaw, st.pitch }), w)
				check(u.diff(control.truck_frame(st.board, st.normal, ctl, st.switched), st.truck_frame), w .. " truck_frame")
				check(u.diff(control.tip_frame(st.board, st.direction, st.normal, st.point, st.backslash), st.tip_frame), w .. " tip_frame")
			end
		end
	end)
	harness.test(report, "grind_contact/investigator: investigate vs Rust", function()
		local found, prox = 0, 0
		for n, c in golden.investigate do
			local res = investigator.investigate(c.query, c.edges)
			check(u.diff(contact_l(res.candidate), c.candidate), "investigate#" .. n .. " candidate")
			assert((res.proximity ~= nil) == c.has_proximity, "investigate#" .. n .. " proximity")
			if res.proximity then
				prox += 1
				check(u.diff(res.proximity, c.proximity), "investigate#" .. n .. " proximity")
			end
			if res.candidate then
				found += 1
			end
		end
		table.insert(report.lines, string.format("      investigate: %d случаев, кандидатов %d, proximity %d", #golden.investigate, found, prox))
	end)
	harness.test(report, "grind_contact/manager: directed_tangent, tweak_geometry, gravity_relief, Jumper vs Rust", function()
		for n, c in golden.manager do
			local w = "manager#" .. n
			check(u.diff(manager.directed_tangent(c.start, c.finish, c.velocity, c.previous), c.tangent), w .. " tangent")
			local avoid = { value = c.avoid_in }
			check(u.diff(manager.tweak_geometry(c.gi, avoid), c.go), w .. " tweak")
			assert(avoid.value == c.avoid, w .. " avoid")
			local r = c.relief
			local timer = { value = r.timer_in }
			check(u.diff(manager.gravity_relief(timer, r.valid, r.category, r.tangent, r.velocity, r.dt, r.vertical, r.linear), r.out), w .. " relief")
			check(u.diff(timer.value, r.timer), w .. " timer")
		end
		for n, c in golden.jumper do
			local j = manager.Jumper.default()
			j.cooldown = c.cooldown
			j.energy = c.energy
			for k, st in c.steps do
				local w = string.format("jumper#%d step#%d", n, k)
				check(u.diff(manager.Jumper.update(j, st.geometry, st.family_in), st.out), w)
				check(u.diff({ j.launched, j.cooldown, j.family, j.energy }, { st.launched, st.cooldown, st.family, st.energy }), w .. " state")
				check(u.diff(j.geometry, st.state_geometry), w .. " geometry")
			end
		end
	end)
	harness.test(report, "grind_contact/balance: target_up, exit_lean, force_exit последовательно vs Rust", function()
		for n, case in golden.balance do
			local st = BalanceState.default()
			local vecs = { grind_normal = case.grind_normal0, target_up = case.target_up0 }
			for k, s in case.steps do
				local w = string.format("balance#%d step#%d", n, k)
				local contact = {
					surface = s.surface,
					primitive_direction = s.primitive_direction,
					directed_grind_direction = s.directed_grind_direction,
					kind = s.kind,
					entry_kind = s.entry_kind,
				}
				BalanceState.update_target_up(st, s.target_input, if s.has_contact then contact else nil, vecs)
				check(u.diff({ state = st, grind_normal = vecs.grind_normal, target_up = vecs.target_up }, s.after_target), w .. " target")
				local angle = BalanceState.update_exit_lean(st, s.exit_input, if s.has_contact2 then contact else nil, case.lean, vecs)
				check(u.diff(angle, s.angle), w .. " angle")
				check(u.diff({ state = st, grind_normal = vecs.grind_normal, target_up = vecs.target_up }, s.after_exit), w .. " exit")
				local flags = { value = s.flags_in }
				local calls = 0
				local _, err = rt.catch(BalanceState.update_force_exit, st, s.location, flags, function(p): any
					calls += 1
					local rec = s.calls[calls]
					assert(rec, w .. " лишний вызов")
					check(u.diff({ p.start, p["end"] }, { rec.start, rec.finish }), w .. " probe")
					if s.fail then
						rt.raise("world unavailable")
					end
					return if s.hit_some then { normal = s.hit } else nil
				end)
				assert(calls == #s.calls, w .. " число вызовов")
				check(u.diff(err, s.err), w .. " err")
				assert(flags.value == s.flags, w .. " flags")
			end
		end
	end)
end

return function(report: harness.Report)
	rust_tests(report)
	golden_tests(report)
end
