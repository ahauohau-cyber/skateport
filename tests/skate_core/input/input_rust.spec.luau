--!strict
-- Перенос Rust-тестов skate_core/input: gesture, steering_intentions,
-- riding_intentions_tests, grind_intentions/tests, offboard_intentions/tests,
-- history_tests, controller_startup, gameplay_map_tests, trick_intentions,
-- anticipation_intentions, gameplay_gestures.

local harness = require("../../harness")
local rt = require("../../../src/rt")
local input = require("../../../src/skate_core/input")

local f32 = rt.f32
local tb = rt.to_bits
local fb = rt.from_bits
local Derived = input.controller.DerivedControllerInput
local GameplayActions = input.gameplay_map.GameplayActions
local riding = input.riding_intentions
local offboard = input.offboard_intentions
local history = input.history
local Pad = input.pad.Pad

-- ROBLOX: [u32; 26] с индексами Rust -> words[k + 1].
local function words26(set: { [number]: number }?): { number }
	local w = rt.zeros(26)
	if set then
		for k, v in set do
			w[k + 1] = v
		end
	end
	return w
end
local function derived(w: { number }): any
	return Derived.from_words(w)
end
local function names(list: { any }): { string }
	local out = {}
	for _, i in list do
		table.insert(out, i.name)
	end
	return out
end
local function find(list: { any }, name: string): any
	for _, i in list do
		if i.name == name then
			return i
		end
	end
	return nil
end
local function has(list: { any }, name: string): boolean
	return find(list, name) ~= nil
end
local function same_list(a: { string }, b: { string }): boolean
	if #a ~= #b then
		return false
	end
	for i = 1, #a do
		if a[i] ~= b[i] then
			return false
		end
	end
	return true
end
local NOPREFS = riding.default_push_preferences()

return function(report: harness.Report)
	-- gesture.rs
	local function recognizer(): any
		return input.gesture.Recognizer.new({
			{
				name = "360Flip",
				points = { { f32(-0.965714), f32(0.268571) }, { f32(-0.497143), f32(0.84) }, { f32(0.211429), f32(0.988571) }, { f32(0.908571), f32(-0.405714) } },
				tolerance_squared = f32(f32(0.4) * f32(0.4)),
			},
		})
	end
	local SETTINGS = { maximum_misses = 3, difficulty = 0 }
	local R = input.gesture.Recognizer
	harness.test(report, "gesture: anticipation_hold_does_not_weaken_authored_scoop", function()
		local r = recognizer()
		local points = r.patterns[1].points
		R.sample(r, { 0, 0 }, SETTINGS)
		for _ = 1, 120 do
			assert(R.sample(r, points[1], SETTINGS) == nil)
		end
		assert(R.sample(r, points[2], SETTINGS) == nil)
		assert(R.sample(r, points[3], SETTINGS) == nil)
		local result = R.sample(r, points[4], SETTINGS) :: any
		assert(result.pattern == 0 and result.strength == 1.0 and result.elapsed == 4.0)
		assert(R.held(r, points[4]) == 0)
		assert(R.sample(r, points[4], SETTINGS) == nil)
		assert(R.held(r, { 0, 0 }) == nil)
	end)
	harness.test(report, "gesture: disconnected_scoop_and_reverse_path_do_not_trigger", function()
		local r = recognizer()
		local points = r.patterns[1].points
		R.sample(r, { 0, 0 }, SETTINGS)
		R.sample(r, points[1], SETTINGS)
		for _ = 1, 4 do
			assert(R.sample(r, { 0, 0 }, SETTINGS) == nil)
		end
		for i = 2, #points do
			assert(R.sample(r, points[i], SETTINGS) == nil)
		end
		r = recognizer()
		R.sample(r, { 0, 0 }, SETTINGS)
		for i = #points, 1, -1 do
			assert(R.sample(r, points[i], SETTINGS) == nil)
		end
	end)

	-- steering_intentions.rs
	harness.test(report, "steering_intentions: left_steering_preserves_signed_turn_and_hard_turn_symmetry", function()
		local left = input.steering_intentions.produce({ -0.75, 0 }, 0)
		local right = input.steering_intentions.produce({ 0.75, 0 }, 0)
		assert(left.turn == -0.75 and right.turn == 0.75)
		assert(left.hard_turn == (if right.hard_turn ~= nil then -right.hard_turn else nil))
		assert(left.hard_turn_crouch == right.hard_turn_crouch)
	end)
	harness.test(report, "steering_intentions: steering_gate_suppresses_all_three_emissions_without_changing_input", function()
		local g = input.steering_intentions.produce({ -0.75, 0 }, 1)
		assert(g.turn == nil and g.hard_turn == nil and g.hard_turn_crouch == nil)
	end)

	-- riding_intentions_tests.rs
	local function snapshot(previous: number, current: number, held: number): any
		return derived(words26({ [6] = previous, [13] = current, [20] = tb(held), [22] = tb(held) }))
	end
	harness.test(report, "riding_intentions: right_bumper_publishes_held_grab_world_without_actor_gate", function()
		for _, c in { { 0, bit32.lshift(1, 28), true }, { bit32.lshift(1, 28), bit32.lshift(1, 28), true }, { bit32.lshift(1, 28), 0, false }, { 0, bit32.lshift(1, 29), false } } do
			for _, actor in { 0, 0xffffffff } do
				local out = riding.produce(snapshot(c[1] :: number, c[2] :: number, 0.5), actor, NOPREFS)
				local n = 0
				for _, i in out do
					if i.name == "GrabWorld" then
						n += 1
						assert(i.value == 1.0)
					end
				end
				assert(n == (if c[3] then 1 else 0))
			end
		end
	end)
	harness.test(report, "riding_intentions: crouch_preserves_zero_presence_and_uses_maximum_trigger", function()
		local w = words26({ [8] = tb(1.0) })
		assert(find(riding.produce(derived(w), 1, NOPREFS), "Crouch").value == 0.0)
		w[12] = tb(f32(0.4))
		w[13] = tb(f32(0.7))
		w[8] = tb(0.5)
		local values = riding.produce(derived(w), 0, NOPREFS)
		assert(find(values, "Crouch").value == f32(0.7))
		assert(find(values, "KickTurn").value == 0.5)
		assert(find(values, "Turn").value ~= 0.5)
	end)
	harness.test(report, "riding_intentions: held_push_continues_after_new_push_allowance_expires", function()
		local button = bit32.lshift(1, 21)
		assert(has(riding.produce(snapshot(0, button, 0.5), 0, NOPREFS), "NewPush"))
		assert(same_list(names(riding.produce(snapshot(button, button, 0.5), 0, NOPREFS)), { "RightPush", "Pushing" }))
		assert(#riding.produce(snapshot(0, button, 0.0), bit32.lshift(1, 11), NOPREFS) == 0)
	end)
	harness.test(report, "riding_intentions: dual_push_gate_requires_both_feet_and_brake_uses_actor_mode", function()
		assert(#riding.produce(snapshot(0, bit32.lshift(1, 21), 0.0), bit32.lshift(1, 6), NOPREFS) > 0)
		assert(#riding.produce(snapshot(0, bit32.bor(bit32.lshift(1, 21), bit32.lshift(1, 23)), 0.0), bit32.lshift(1, 6), NOPREFS) == 0)
		local brake = snapshot(0, bit32.lshift(1, 20), 0.0)
		assert(riding.produce(brake, 0, NOPREFS)[1].name == "Brake")
		assert(#riding.produce(brake, bit32.lshift(1, 7), NOPREFS) == 0)
	end)
	harness.test(report, "riding_intentions: powerslide_queries_are_separate_from_signed_continuous_values", function()
		local function intents(x: number, y: number, flags: number)
			return riding.produce(derived(words26({ [7] = tb(f32(x)), [8] = tb(f32(y)) })), flags, NOPREFS)
		end
		local function any(list: { any }, pred: (any) -> boolean): boolean
			for _, i in list do
				if pred(i) then
					return true
				end
			end
			return false
		end
		local function ends(s: string, suffix: string): boolean
			return s:sub(-#suffix) == suffix
		end
		for _, x in { -1.0, 1.0 } do
			local values = intents(x, 0, 0)
			assert(not any(values, function(i) return ends(i.name, "SlideStart") end))
			assert(has(values, "Turn"))
		end
		for _, c in { { 0.6, "RightSlideStart" }, { -0.6, "LeftSlideStart" } } do
			local x = c[1] :: number
			local values = intents(x, -0.8, 0)
			assert(any(values, function(i) return i.name == c[2] and i.value == 1.0 end))
			assert(any(values, function(i) return i.name == "LeftSlide" and i.value < 0 end))
			assert(any(values, function(i) return i.name == "RightSlide" and i.value > 0 end))
			local inhibited = intents(x, -0.8, bit32.lshift(1, 11))
			for _, v in values do
				if v.name:find("Slide") then
					assert(any(inhibited, function(i) return i.name == v.name and i.value == v.value end))
				end
			end
			assert(not any(intents(x, -0.8, bit32.lshift(1, 8)), function(i) return i.name:find("Slide") ~= nil end))
		end
		for _, c in { { 0, 0 }, { 0, 1 }, { 0, -1 }, { 0.3, -0.4 } } do
			assert(not any(intents(c[1], c[2], 0), function(i) return ends(i.name, "SlideStart") end))
		end
		assert(not any(intents(0.3, -0.4, 0), function(i) return i.name:find("Slide") ~= nil end))
	end)

	-- grind_intentions/tests.rs
	local function gvalues(x: number, rx: number, ry: number): { any }
		return input.grind_intentions.produce(derived(words26({ [7] = tb(f32(x)), [9] = tb(f32(rx)), [10] = tb(f32(ry)) })))
	end
	harness.test(report, "grind_intentions: all_four_s3_emissions_preserve_order_and_sign", function()
		local v = gvalues(0.25, 0.5, -0.75)
		assert(same_list(names(v), { "GrindBalanceX", "PhysGrindTranslation", "PhysGrindStabilityNudge", "PhysGrindUpDown" }))
		assert(v[1].value == -0.25 and v[2].value == 0.75 and v[3].value == 0.25 and v[4].value == -0.75)
	end)
	harness.test(report, "grind_intentions: translation_saturates_both_directions_and_cancellation_omits_only_it", function()
		assert(gvalues(0.75, 0.75, 0)[2].value == 1.0)
		assert(gvalues(-0.75, -0.75, 0)[2].value == -1.0)
		local v = gvalues(0.5, -0.5, 0)
		assert(same_list(names(v), { "GrindBalanceX", "PhysGrindStabilityNudge" }) and v[1].value == -0.5 and v[2].value == 0.5)
		assert(#gvalues(0, -0.0, 0) == 0)
	end)
	harness.test(report, "grind_intentions: left_only_translation_distinguishes_s3_from_s2", function()
		local v = gvalues(0.5, 0, 0)[2]
		assert(v.name == "PhysGrindTranslation" and v.value == 0.5)
	end)

	-- offboard_intentions/tests.rs
	local function ovalues(w: { number }, flags: number, blocked: boolean)
		return offboard.produce_discrete(derived(w), flags, blocked)
	end
	local function toggle_words(previous: boolean, timer: number): { number }
		return words26({ [6] = if previous then bit32.lshift(1, 22) else 0, [13] = bit32.lshift(1, 22), [23] = tb(timer) })
	end
	harness.test(report, "offboard: toggle_rise_and_short_hold_are_distinct_from_continuous_hold", function()
		local new, held = "NewToggleOffBoardState", "ToggleOffBoardState"
		assert(has(ovalues(toggle_words(false, 9.0), 0, false), new))
		assert(has(ovalues(toggle_words(true, f32(0.02)), 0, false), new))
		local boundary = ovalues(toggle_words(true, fb(0x3cf5c28f)), 0, false)
		assert(not has(boundary, new) and has(boundary, held))
		assert(has(ovalues(toggle_words(true, 0 / 0), 0, false), new))
		local released = toggle_words(true, 0)
		released[14] = 0
		local r = ovalues(released, 0, false)
		assert(not has(r, new) and not has(r, held))
	end)
	harness.test(report, "offboard: physical_and_modifier_gates_block_both_but_actor_gate_only_blocks_new", function()
		local w = toggle_words(false, 0)
		local disabled = ovalues(w, bit32.lshift(1, 10), false)
		assert(not has(disabled, "NewToggleOffBoardState") and has(disabled, "ToggleOffBoardState"))
		local modifier = table.clone(w)
		modifier[14] = bit32.bor(modifier[14], bit32.lshift(1, 29))
		for _, out in { ovalues(w, 0, true), ovalues(modifier, 0, false) } do
			assert(not has(out, "NewToggleOffBoardState") and not has(out, "ToggleOffBoardState"))
		end
	end)
	harness.test(report, "offboard: y_remains_toggle_for_stock_offboard_mount_not_board_recall", function()
		local out = ovalues(toggle_words(false, 0), 0, false)
		assert(has(out, "NewToggleOffBoardState") and has(out, "ToggleOffBoardState") and not has(out, "OB_RetrieveBoard"))
	end)
	harness.test(report, "offboard: jump_requires_new_button_and_does_not_inherit_toggle_gates", function()
		local w = words26({ [13] = bit32.bor(bit32.lshift(1, 23), bit32.lshift(1, 29)), [22] = tb(f32(0.01)) })
		assert(has(ovalues(w, 0xffffffff, true), "OB_Jump"))
		w[7] = bit32.lshift(1, 23)
		assert(not has(ovalues(w, 0, false), "OB_Jump"))
	end)
	harness.test(report, "offboard: full_trigger_edges_publish_board_actions_together_and_do_not_repeat", function()
		local w = words26({ [11] = tb(f32(0.99)) })
		assert(not has(ovalues(w, 0, false), "OB_RetrieveBoard"))
		w[12] = tb(1.0)
		w[13] = tb(1.0)
		local board = {}
		for _, i in ovalues(w, 0xffffffff, true) do
			if i.name:sub(-5) == "Board" then
				table.insert(board, i.name)
			end
		end
		assert(same_list(board, { "OB_DropBoard", "OB_ThrowBoard", "OB_RetrieveBoard" }))
		w[5] = w[12]
		w[6] = w[13]
		assert(not has(ovalues(w, 0, false), "OB_RetrieveBoard"))
		w[6] = 0
		local r = ovalues(w, 0, false)
		assert(not has(r, "OB_DropBoard") and has(r, "OB_ThrowBoard") and has(r, "OB_RetrieveBoard"))
	end)
	harness.test(report, "offboard: sprint_uses_competing_held_timers_and_axes_preserve_zero_presence", function()
		local w = words26({ [20] = tb(f32(0.01)) })
		local out = ovalues(w, 0xffffffff, true)
		assert(has(out, "OB_Sprint") and not has(out, "OB_LookAtX") and not has(out, "OB_LookAtY"))
		assert(has(out, "OB_AirBodyTweakX") and has(out, "OB_AirBodyTweakY"))
		w[22] = tb(f32(0.01))
		assert(not has(ovalues(w, 0, false), "OB_Sprint"))
		w[10] = tb(-0.5)
		w[14] = bit32.lshift(1, 30)
		out = ovalues(w, 0, false)
		assert(has(out, "OB_DoAirBodyTweak"))
		assert(find(out, "OB_LookAtX").value == -0.5 and find(out, "OB_AirBodyTweakX").value == -0.5)
	end)
	local function analog(x: number, z: number, forward: { number }, correction: { number }?)
		return offboard.produce_analog(derived(words26({ [7] = tb(f32(x)), [8] = tb(f32(z)) })), { effective_skeleton_z = forward, biped_correction = correction })
	end
	harness.test(report, "offboard: movement_preserves_signed_projection_and_raw_axes", function()
		local out = analog(0.75, -0.5, { 0, 8, 3, 0 }, nil)
		assert(math.abs(out[1].value + 0.5) < 1e-6 and out[2].value == -0.5 and out[3].value == 0.75)
		assert(math.abs(out[4].value - f32(math.sqrt(f32(0.75 * 0.75 + 0.25)))) < 1e-6)
		assert(math.abs(analog(0.75, -0.5, { 0, 0, -3, 0 }, nil)[1].value - 0.5) < 1e-6)
	end)
	harness.test(report, "offboard: obstacle_correction_stops_direct_approach_but_preserves_tangent_motion", function()
		local forward = { 0, 0, 1, 0 }
		local wall = { 0, 0, -1, 0 }
		assert(analog(0, 1, forward, wall)[1].value == 0.0)
		assert(math.abs(analog(0.6, 0.8, { 1, 0, 0, 0 }, wall)[1].value - f32(0.6)) < 1e-6)
		assert(math.abs(analog(0, -0.5, forward, wall)[1].value + 0.5) < 1e-6)
		assert(math.abs(analog(0, 1, forward, { 0, 0, -0.5, 0 })[1].value - 0.75) < 1e-6)
	end)
	harness.test(report, "offboard: zero_and_tiny_headings_use_original_length_threshold", function()
		assert(analog(0, 1, { 0, 0, 0, 0 }, nil)[1].value == 0.0)
		assert(analog(0, 1, { 0, 0, f32(0.5e-6), 0 }, nil)[1].value == 0.0)
		assert(math.abs(analog(0, 1, { 0, 0, f32(2.0e-6), 0 }, nil)[1].value - 1.0) < 1e-6)
		for _, i in analog(0, 0, { 0, 0, 1, 0 }, nil) do
			assert(i.value == 0.0)
		end
	end)

	-- history_tests.rs
	local function pads()
		return { Pad.new(), Pad.new(), Pad.new(), Pad.new() }
	end
	local function batch(seed: number)
		local HR = history.HistoryRecord
		return { HR.new({ seed }), HR.new({ seed + 1 }), HR.new({ seed + 2 }), HR.new({ seed + 3 }) }
	end
	local PH = history.PadHistory
	harness.test(report, "history: drains_newest_batch_once_for_all_devices", function()
		local h = PH.new()
		PH.publish(h, batch(10))
		PH.publish(h, batch(20))
		local out = pads()
		assert(PH.drain_to_latest(h, out))
		for i, expected in { 20.0, 21.0, 22.0, 23.0 } do
			assert(out[i].count == 1 and out[i].records[1][1] == tb(expected) and out[i].records[1][4] == 1)
		end
		assert(not PH.drain_to_latest(h, out))
	end)
	harness.test(report, "history: producer_wraps_at_full_lap_without_overflow_policy", function()
		local h = PH.new()
		for i = 0, history.HISTORY_CAPACITY - 2 do
			PH.publish(h, batch(i))
		end
		assert(PH.write_index(h) == 0)
		local out = pads()
		assert(PH.drain_to_latest(h, out))
		PH.publish(h, batch(99))
		assert(PH.write_index(h) == 1)
		assert(PH.drain_to_latest(h, out))
		local full = PH.new()
		for i = 0, history.HISTORY_CAPACITY - 1 do
			PH.publish(full, batch(i))
		end
		assert(PH.write_index(full) == 1)
		assert(not PH.drain_to_latest(full, out))
	end)
	harness.test(report, "history: empty_publish_advances_once", function()
		local h = PH.new()
		PH.publish(h, batch(1))
		PH.publish(h, {})
		assert(PH.write_index(h) == 3)
	end)
	harness.test(report, "history: reused_batch_retains_unregistered_slots", function()
		local h = PH.new()
		h.batches[2] = batch(40)
		local out = pads()
		PH.publish(h, { history.HistoryRecord.new({ 99 }) })
		assert(PH.drain_to_latest(h, out))
		for i, v in { 99.0, 41.0, 42.0, 43.0 } do
			assert(out[i].records[1][1] == tb(v))
		end
	end)
	harness.test(report, "history: clear_count_preserves_visibility_contract", function()
		local r = history.HistoryRecord.new({ 3.5, 4.5 })
		history.HistoryRecord.clear_count(r)
		assert(r.count == 0 and #history.HistoryRecord.values(r) == 0)
		assert(r.values[1] == 3.5 and r.values[2] == 4.5)
	end)

	-- controller_startup.rs
	harness.test(report, "controller: initialize_preserves_only_native_low_twenty_flag_bits", function()
		local c = derived(words26({ [6] = 0xfff01234, [13] = 0xabcd5678, [0] = 1, [24] = 2 }))
		Derived.initialize(c)
		assert(c.words[7] == 0x00001234 and c.words[14] == 0x000d5678)
		for i = 0, 25 do
			if not (i == 6 or i == 13 or (i >= 16 and i < 20)) then
				assert(c.words[i + 1] == 0, "word " .. i)
			end
		end
		for i = 17, 20 do
			assert(c.words[i] == 0x7effffff)
		end
	end)

	-- trick_intentions.rs
	local function tcontroller(pl: number, pr: number, l: number, r: number)
		return derived(words26({ [4] = tb(pl), [5] = tb(pr), [11] = tb(l), [12] = tb(r), [9] = tb(0.25), [10] = tb(-0.5) }))
	end
	harness.test(report, "trick_intentions: publishes_holds_edges_and_tweaks", function()
		local out = input.trick_intentions.produce(tcontroller(0, 0.25, 1, 0.25))
		assert(has(out, "LeftAirGrab") and not has(out, "NewLeftAirGrab") and not has(out, "NewRightAirGrab"))
		assert(find(out, "TweakX").value == 0.25 and find(out, "TweakY").value == -0.5)
		assert(math.abs(find(out, "BoardAdjustAngle").value - 0.4636476) < 0.00001)
		assert(math.abs(find(out, "BoardAdjustMag").value - 0.559017) < 0.00001)
	end)
	harness.test(report, "trick_intentions: board_adjust_cardinals_follow_fill_register_order", function()
		local half, pi = fb(0x3fc90fdb), fb(0x40490fdb)
		for _, c in { { 0, -1, 0 }, { 1, 0, half }, { 0, 1, pi }, { -1, 0, -half } } do
			local out = input.trick_intentions.produce(derived(words26({ [9] = tb(c[1]), [10] = tb(c[2]) })))
			assert(math.abs(find(out, "BoardAdjustAngle").value - c[3]) < 0.00001)
		end
	end)

	-- anticipation_intentions.rs
	harness.test(report, "anticipation: neutral_removes_anticipation_and_tail_hold_selects_ollie_range", function()
		assert(#input.anticipation_intentions.produce(derived(words26())) == 0)
		local w = words26({ [10] = tb(-1.0) })
		local i = input.anticipation_intentions.produce(derived(w))
		assert(math.abs(i[1].value - 1.0) < 0.000001 and math.abs(i[2].value) <= f32(0.52))
		w[11] = tb(1.0)
		assert(math.abs(input.anticipation_intentions.produce(derived(w))[2].value) >= f32(2.62))
	end)

	-- gameplay_gestures.rs
	local function gintents(previous: number, current: number): { string }
		return names(input.gameplay_gestures.produce(derived(words26({ [6] = previous, [13] = current }))))
	end
	harness.test(report, "gameplay_gestures: preserve_direction_edges_holds_and_release", function()
		for _, c in { { 27, "Up" }, { 26, "Down" }, { 25, "Left" }, { 24, "Right" } } do
			local b = bit32.lshift(1, c[1] :: number)
			local n = c[2] :: string
			assert(same_list(gintents(0, b), { "Gesture" .. n .. "Start", "Gesture" .. n .. "Held" }))
			assert(same_list(gintents(b, b), { "Gesture" .. n .. "Held" }))
			assert(#gintents(b, 0) == 0)
		end
	end)
	harness.test(report, "gameplay_gestures: bumpers_suppress_gestures_without_synthesizing_a_new_edge_on_release", function()
		for _, bumper in { bit32.lshift(1, 28), bit32.lshift(1, 29) } do
			assert(#gintents(0, bit32.bor(bumper, bit32.lshift(1, 27))) == 0)
			assert(same_list(gintents(bit32.bor(bumper, bit32.lshift(1, 27)), bit32.lshift(1, 27)), { "GestureUpHeld" }))
		end
		assert(same_list(gintents(0, 0x0f000000), {
			"GestureDownStart", "GestureLeftStart", "GestureRightStart", "GestureUpStart",
			"GestureDownHeld", "GestureLeftHeld", "GestureRightHeld", "GestureUpHeld",
		}))
	end)

	-- gameplay_map_tests.rs
	local DT = f32(1.0 / 30.0)
	local function overridden(overrides: { { number } }): { number }
		local v = table.create(18, 0.0)
		for _, o in overrides do
			v[o[1] - 64 + 1] = f32(o[2])
		end
		return v
	end
	local function intents(overrides: { { number } }): { [string]: boolean }
		local settings: any = { attribute = 0.5, missing_attribute_value = 0.5 }
		local c = derived(words26())
		Derived.initialize(c)
		for _, values in { table.create(18, 0.0), overridden(overrides) } do
			Derived.update(c, GameplayActions.as_map(GameplayActions.from_values(values)), DT, false, false, settings)
		end
		local set = {}
		local function add(list: { any })
			for _, i in list do
				set[i.name] = true
			end
		end
		add(riding.produce(c, 0, NOPREFS))
		add(input.trick_intentions.produce(c))
		add(offboard.produce_discrete(c, 0, false))
		add(input.gameplay_gestures.produce(c))
		add(input.manual_intentions.produce(c, 0))
		add(input.grind_intentions.produce(c))
		add(input.wipeout_intentions.produce(c, 0, bit32.bor(0x40, 0x80, 0x100)))
		return set
	end
	local function added(overrides: { { number } }): { [string]: boolean }
		local neutral = intents({})
		local out = {}
		for k in intents(overrides) do
			if not neutral[k] then
				out[k] = true
			end
		end
		return out
	end
	local function reaches(overrides: { { number } }, expected: { string })
		local got = added(overrides)
		for _, n in expected do
			if not got[n] then
				error("должно публиковать " .. n, 2)
			end
		end
	end
	harness.test(report, "gameplay_map: table_is_the_retail_registration_order", function()
		local slots = { "DPadU", "DPadD", "DPadL", "DPadR", "Start", "Back", "LStick", "RStick", "LBumper", "RBumper", "LTrigger", "RTrigger", "A", "B", "X", "Y", "LStickR", "LStickL", "LStickU", "LStickD", "RStickR", "RStickL", "RStickU", "RStickD" }
		local pad_slots = { { 16, 17 }, { 18, 19 }, { 6 }, { 20, 21 }, { 22, 23 }, { 7 }, { 10 }, { 11 }, { 8 }, { 9 }, { 0 }, { 1 }, { 2 }, { 3 }, { 14 }, { 15 }, { 12 }, { 13 } }
		for index, action in input.gameplay_map.ACTIONS do
			assert(action.id == 64 + index - 1)
			assert(input.gameplay_map.action_by_key(action.key) == action)
			local used = {}
			for name in action.expression:gmatch("[^-]+") do
				table.insert(used, (table.find(slots, name) :: number) - 1)
			end
			assert(#used == #pad_slots[index], action.name)
			for k = 1, #used do
				assert(used[k] == pad_slots[index][k], action.name)
			end
		end
	end)
	harness.test(report, "gameplay_map: neutral_input_publishes_no_button_intents", function()
		local neutral = intents({})
		for _, n in { "Brake", "Pushing", "Dismount", "GrabWorld", "ToggleOffBoardState", "OB_Jump" } do
			assert(not neutral[n], n)
		end
	end)
	harness.test(report, "gameplay_map: sticks_reach_steering_tricks_manuals_and_grinds", function()
		reaches({ { 64, 0.8 } }, { "BodySpin", "KickTurn", "GrindBalanceX", "PhysGrindTranslation", "WipeoutControlX" })
		reaches({ { 65, 0.8 } }, { "WipeoutControlY" })
		reaches({ { 67, 0.8 } }, { "TweakX", "BoardAdjustAngle", "HandPlantTweakX", "OB_LookAtX" })
		reaches({ { 68, 0.8 } }, { "Manual", "TweakY", "HandPlantTweakY", "OB_LookAtY", "PhysGrindUpDown" })
		reaches({ { 68, -0.95 } }, { "Manual", "ManualBrake" })
	end)
	harness.test(report, "gameplay_map: stick_clicks_and_full_triggers_together_request_a_bail", function()
		local all = { { 66, 1 }, { 69, 1 }, { 70, 1 }, { 71, 1 } }
		reaches(all, { "WipeOutRequest" })
		for skip = 1, 4 do
			local partial = {}
			for i, a in all do
				if i ~= skip then
					table.insert(partial, a)
				end
			end
			assert(not added(partial).WipeOutRequest)
		end
		reaches({ { 69, 1 } }, { "OB_DoAirBodyTweak" })
	end)
	harness.test(report, "gameplay_map: triggers_are_grabs_crouch_and_board_drop_or_throw", function()
		reaches({ { 70, 1 } }, { "LeftGroundGrab", "LeftAirGrab", "Crouch", "OB_DropBoard", "OB_RetrieveBoard" })
		reaches({ { 71, 1 } }, { "RightGroundGrab", "RightAirGrab", "Crouch", "OB_ThrowBoard", "WipeOutPushOff" })
		local half = added({ { 70, 0.5 } })
		assert(half.LeftAirGrab and not half.LeftGroundGrab and not half.OB_DropBoard)
	end)
	harness.test(report, "gameplay_map: bumpers_grab_the_world_and_gate_dpad_and_board_toggle", function()
		reaches({ { 73, 1 } }, { "GrabWorld", "DarkCatch", "NewDarkCatch", "OB_DoAirBodyTweak" })
		assert(not added({ { 72, 1 } }).GrabWorld)
		for _, bumper in { 72, 73 } do
			assert(not added({ { bumper, 1 }, { 74, 1 } }).GestureUpStart)
		end
		assert(not added({ { 72, 1 }, { 79, 1 } }).ToggleOffBoardState)
		assert(not added({ { 72, 1 }, { 73, 1 } }).GrabWorld)
	end)
	harness.test(report, "gameplay_map: dpad_publishes_gesture_starts_and_holds", function()
		for _, c in { { 74, "Up" }, { 75, "Down" }, { 76, "Left" }, { 77, "Right" } } do
			local got = added({ { c[1] :: number, 1 } })
			assert(got["Gesture" .. c[2] .. "Start"] and got["Gesture" .. c[2] .. "Held"])
		end
	end)
	harness.test(report, "gameplay_map: face_buttons_push_brake_dismount_and_leave_the_board", function()
		reaches({ { 78, 1 } }, { "LeftPush", "Pushing", "NewPush", "HandPlantOneFootLeft", "OB_Jump", "WipeOutRecover" })
		reaches({ { 79, 1 } }, { "ToggleOffBoardState", "NewToggleOffBoardState" })
		reaches({ { 80, 1 } }, { "RightPush", "Pushing", "NewPush", "HandPlantOneFootRight", "OB_Sprint", "WipeOutRecover" })
		reaches({ { 81, 1 } }, { "Brake", "Dismount", "NewDismount", "DarkCatch", "HandPlantDismount" })
		assert(not added({ { 80, 1 }, { 81, 1 } }).OB_Sprint)
	end)
end
