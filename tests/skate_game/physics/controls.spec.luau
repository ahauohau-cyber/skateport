--!strict
-- Перенос Rust-тестов crates/skate-game/src/physics/controls/{offboard_tests,bail_tests}.rs.

local harness = require("../../harness")
local rt = require("../../../src/rt")
local controls = require("../../../src/skate_game/physics/controls")
local intents = require("../../../src/skate_core/graph/intents")

local f32 = rt.f32
local PC = controls.PlayerControls
local IntentMap = intents.IntentMap

local function close(actual: { number }, expected: { number })
	for i = 1, 2 do
		if math.abs(actual[i] - expected[i]) >= 2.0e-6 then
			error(string.format("actual={%g,%g}, expected={%g,%g}", actual[1], actual[2], expected[1], expected[2]), 2)
		end
	end
end

local function packet(): any
	local self = { values = {}, states = {} }
	for i = 0, 81 do
		self.values[i] = f32(i / 100)
		self.states[i] = i % 2
	end
	function self:value(a: number): number
		return self.values[a]
	end
	function self:state(a: number): number
		return self.states[a]
	end
	return self
end

local function sticks(v: { number }): any
	local self = {}
	function self:value(a: number): number
		if a == 64 then
			return v[1]
		elseif a == 65 then
			return v[2]
		elseif a == 67 then
			return v[3]
		elseif a == 68 then
			return v[4]
		end
		return 0.0
	end
	function self:state(_a: number): number
		return 0
	end
	return self
end

return function(report: harness.Report)
	local cra = controls.camera_relative_axes
	harness.test(report, "controls: offboard_remap_preserves_native_left_axis_sign_and_yaw", function()
		close(cra({ 0.25, 0.75 }, { { 1, 0, 0 }, { 0, 1, 0 }, { 0, 0, 1 } }), { -0.25, 0.75 })
		local quarter = { { 0, 0, -1 }, { 0, 1, 0 }, { 1, 0, 0 } }
		close(cra({ 0.25, 0.75 }, quarter), { 0.75, 0.25 })
		close(cra({ -0.25, -0.75 }, quarter), { -0.75, -0.25 })
		close(cra({ 0, 0 }, quarter), { 0, 0 })
	end)
	harness.test(report, "controls: offboard_remap_flattens_pitch_below_native_threshold", function()
		close(cra({ 0.25, 0.75 }, { { 1, 0, 0 }, { 0, f32(0.8), f32(-0.6) }, { 0, f32(0.6), f32(0.8) } }), { -0.25, 0.75 })
	end)
	harness.test(report, "controls: offboard_remap_retains_camera_basis_at_both_threshold_poles", function()
		local threshold = rt.from_bits(0x3f7d70a4)
		local horizontal = f32(math.sqrt(f32(1.0 - f32(threshold * threshold))))
		for _, vertical in { threshold, -threshold } do
			close(cra({ 0.25, 0.75 }, { { 1, 0, 0 }, { 0, horizontal, -vertical }, { 0, vertical, horizontal } }), { -0.25, f32(0.75 * horizontal) })
		end
		close(cra({ 0, 1 }, { { 1, 0, 0 }, { 0, 0, -1 }, { 0, 1, 0 } }), { 0, 0 })
	end)
	harness.test(report, "controls: offboard_simulation_adapter_overrides_only_the_sampled_pair", function()
		local p = packet()
		local c = PC.default()
		c.offboard_axes = { -0.25, 0.0 }
		local mapped = PC.simulation_actions(c, p)
		c.offboard_axes = { 0.9, 0.8 }
		for action = 0, 81 do
			local value, state = p.values[action], p.states[action]
			if action == 64 then
				value, state = -0.25, 1
			elseif action == 65 then
				value, state = 0.0, 0
			end
			assert(rt.to_bits(mapped:value(action)) == rt.to_bits(value) and mapped:state(action) == state)
		end
	end)
	harness.test(report, "controls: offboard_inactive_adapter_preserves_every_onboard_action", function()
		local p = packet()
		local mapped = PC.simulation_actions(PC.default(), p)
		for action = 0, 81 do
			assert(rt.to_bits(mapped:value(action)) == rt.to_bits(p.values[action]) and mapped:state(action) == p.states[action])
		end
	end)
	harness.test(report, "controls: offboard_sample_reaches_derived_history_and_raw_tick_clears_override", function()
		local p = packet()
		local c = PC.default()
		PC.update(c, controls.SimulationActions.new(p, { -0.25, 0.75 }), f32(1 / 60), f32(0.1), 0)
		assert(c.controller.words[8] == rt.to_bits(-0.25) and c.controller.words[9] == rt.to_bits(0.75))
		c.offboard_axes = { -0.25, 0.75 }
		PC.update(c, p, f32(1 / 60), f32(0.1), 0)
		assert(c.offboard_axes == nil)
		assert(c.controller.words[1] == rt.to_bits(-0.25) and c.controller.words[2] == rt.to_bits(0.75))
		assert(c.controller.words[8] == rt.to_bits(p.values[64]) and c.controller.words[9] == rt.to_bits(p.values[65]))
	end)
	harness.test(report, "controls: bail_horizontal_steering_reverses_without_changing_other_axes_or_raw_input", function()
		local c = PC.default()
		local function value(name: string): number
			return IntentMap.get(c.action_intents, name) or 0.0
		end
		for _, x in { -1.0, -0.25, 0.0, 0.25, 1.0 } do
			for _, y in { -1.0, 1.0 } do
				PC.update(c, sticks({ x, y, 0.75, -0.5 }), f32(1 / 60), f32(0.1), 0x180)
				assert(value("WipeoutControlX") == -x and value("WipeoutControlY") == y)
				assert(value("WipeoutGestureX") == 0.75 and value("WipeoutGestureY") == -0.5)
				assert(rt.from_bits(c.controller.words[8]) == x)
				assert((c.named_intents["WipeoutControlX"] or 0.0) == -x)
			end
		end
		for _, capabilities in { 0x180, 0 } do
			PC.update(c, sticks({ 0, 0, 0, 0 }), f32(1 / 60), f32(0.1), capabilities)
			assert(not IntentMap.contains_key(c.action_intents, "WipeoutControlX"))
		end
		PC.update(c, sticks({ 1, 1, 1, 1 }), f32(1 / 60), f32(0.1), 0)
		assert(not IntentMap.contains_key(c.action_intents, "WipeoutControlX") and not IntentMap.contains_key(c.action_intents, "WipeoutControlY"))
	end)
	harness.test(report, "intents: IntentMap uses native six-word identity (case folding, 36 bytes)", function()
		local m = IntentMap.new()
		assert(IntentMap.insert(m, "Pushing", 1.0) == nil)
		assert(IntentMap.get(m, "pushing") == 1.0 and IntentMap.len(m) == 1)
		assert(IntentMap.insert(m, "PUSHING", 2.0) == 1.0 and IntentMap.len(m) == 1)
		assert(IntentMap.remove(m, "Pushing") == 2.0 and IntentMap.is_empty(m))
	end)
end
