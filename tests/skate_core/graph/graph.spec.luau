--!strict
-- Сверка skate_core/graph с настоящим skate-core (golden/src/graph.rs):
-- случайные графы через Controller.update с журналом вызовов хоста,
-- NumericCondition, DisablePushBrake. Плюс перенос Rust-тестов graph.

local harness = require("../../harness")
local u = require("../../util")
local rt = require("../../../src/rt")
local graph = require("../../../src/skate_core/graph")
local golden = require("../../golden/graph") :: any

local f32 = rt.f32
local Controller = graph.controller.Controller
local IntentMap = graph.intents.IntentMap
local ActionCondition = graph.conditions.ActionCondition
local NumericCondition = graph.conditions.NumericCondition
local PushBrakeInputs = graph.conditions.PushBrakeInputs
local ConstMgIntent = graph.intent_handlers.ConstMgIntent
local TimeMgIntent = graph.intent_handlers.TimeMgIntent

local function check(d: string?, what: string)
	if d then
		error(what .. d, 2)
	end
end

-- Тот же хост, что LogHost в эталоне.
local function log_host(values: { number }, next_instance: number): any
	local self: any = { log = {}, next_instance = next_instance }
	local function cur(f: any): string
		return if f.current == nil then "-1" else tostring(f.current)
	end
	function self:condition_activation(c: number, _f: any): number
		table.insert(self.log, "cond:" .. c)
		return values[c + 1]
	end
	function self:context(): { number }
		return { 1, 2, 0, 4, 5, 6 }
	end
	function self:allocate(b: number, f: any): number
		self.next_instance += 1
		table.insert(self.log, "alloc:" .. b .. ":" .. cur(f))
		return self.next_instance
	end
	function self:begin(b: number, c: { number }, _f: any)
		table.insert(self.log, "begin:" .. b .. ":" .. c[3] .. ":" .. c[6])
	end
	function self:update(b: number, c: { number }, _f: any)
		table.insert(self.log, "update:" .. b .. ":" .. c[3])
	end
	self["end"] = function(_, b: number, c: { number }, _f: any)
		table.insert(self.log, "end:" .. b .. ":" .. c[3])
	end
	function self:hook(h: number, _f: any)
		table.insert(self.log, "hook:" .. h)
	end
	function self:release(i: number)
		table.insert(self.log, "release:" .. i)
	end
	return self
end

local function actives(c: any): { { number } }
	local out = {}
	for _, a in c.active do
		table.insert(out, { a.behavior, a.instance })
	end
	return out
end

return function(report: harness.Report)
	harness.test(report, "graph/controller: 60 случайных графов × 30 тиков vs Rust", function()
		for gi, g in golden.controller do
			local c = Controller.new(#g.program.topology.states)
			local instance = 0
			for ti, t in g.ticks do
				local at = string.format("граф %d тик %d", gi, ti)
				if t.end_all then
					local host = log_host({}, instance)
					Controller.end_all_behaviors(c, host)
					instance = host.next_instance
					check(u.diff(host.log, t.log), at .. " log")
					check(u.diff(actives(c), t.active), at .. " active")
				else
					local host = log_host(t.values, instance)
					Controller.update(c, g.program, t.dt, host)
					instance = host.next_instance
					check(u.diff(host.log, t.log), at .. " log")
					assert(c.frame.current == t.current and c.frame.last == t.last, at .. " current/last")
					check(u.diff(c.frame.state_times, t.state_times), at .. " state_times")
					check(u.diff(actives(c), t.active), at .. " active")
				end
			end
		end
	end)
	harness.test(report, "graph/conditions: NumericCondition 600 и DisablePushBrake 600 vs Rust", function()
		for i, c in golden.numeric do
			assert(NumericCondition.matches({ comparison = c.comparison, threshold = c.threshold, absolute = c.absolute }, c.value) == c.out, "numeric #" .. i)
		end
		for i, c in golden.push_brake do
			assert(PushBrakeInputs.disabled(c) == c.out, "push_brake #" .. i)
		end
	end)

	-- activation.rs
	local function frame(): any
		return { dt = 0, current = nil, last = nil, state_times = {} }
	end
	local function host(values: { number }): any
		local self = { values = values, calls = {} }
		function self:condition_activation(c: number, _f: any): number
			table.insert(self.calls, c)
			return self.values[c + 1]
		end
		return self
	end
	local function program(operator: number, conds: { any }): any
		local children = {}
		for i = 0, #conds - 1 do
			table.insert(children, { kind = "Condition", id = i })
		end
		return { state_expressions = { 0 }, transition_expressions = {}, expressions = { { operator = operator, children = children } }, conditions = conds }
	end
	local AP = graph.activation.ActivationProgram
	local S = graph.selection.State
	harness.test(report, "activation: excluded_conditions_do_not_participate_and_all_excluded_is_true", function()
		local g = program(1, { { enabled = false, mask = 1 }, { enabled = true, mask = 2 } })
		local h = host({ 0, 0 })
		assert(AP.node_activation(g, S(0), 1, frame(), h))
		assert(#h.calls == 0)
	end)
	harness.test(report, "activation: included_false_condition_controls_result_and_or_short_circuits", function()
		local g = program(2, { { enabled = true, mask = 1 }, { enabled = true, mask = 1 } })
		local h = host({ 1, 0 })
		assert(AP.node_activation(g, S(0), 1, frame(), h))
		assert(#h.calls == 1 and h.calls[1] == 0)
		h.values[1] = 0
		h.calls = {}
		assert(not AP.node_activation(g, S(0), 1, frame(), h))
		assert(#h.calls == 2 and h.calls[1] == 0 and h.calls[2] == 1)
	end)
	harness.test(report, "activation: nodes_without_expressions_are_active", function()
		local g = { state_expressions = { false }, transition_expressions = { false }, expressions = {}, conditions = {} }
		local h = host({})
		assert(AP.node_activation(g :: any, S(0), 1, frame(), h))
		assert(AP.node_activation(g :: any, graph.selection.Transition(0), 2, frame(), h))
	end)

	-- controller.rs
	harness.test(report, "controller: end_all_behaviors_uses_reverse_order_and_instance_context", function()
		local c = Controller.new(0)
		c.active = { { behavior = 4, instance = 40 }, { behavior = 7, instance = 70 } }
		local h = log_host({}, 0)
		Controller.end_all_behaviors(c, h)
		assert(table.concat(h.log, ",") == "end:7:70,release:70,end:4:40,release:40")
		assert(#c.active == 0)
	end)

	-- tests/conditions.rs
	local function numeric(comparison: any, threshold: number): any
		return { comparison = comparison, threshold = threshold, absolute = false }
	end
	harness.test(report, "conditions: comparison_preserves_presence_and_unordered_branch_semantics", function()
		local none = numeric("None", 0)
		local cond: any = { kind = "HasIntent", name = "Pushing", numeric = none }
		local intents = IntentMap.new()
		local input = graph.conditions.default_inputs()
		assert(not ActionCondition.evaluate(cond, input, intents, nil, {}))
		IntentMap.insert(intents, "Pushing", 0)
		assert(ActionCondition.evaluate(cond, input, intents, nil, {}))
		assert(not NumericCondition.matches(none, 0))
		assert(NumericCondition.matches(numeric("GreaterAbsolute", 0.5), -0.75))
		assert(NumericCondition.matches(numeric("GreaterEqual", 1), 0 / 0))
		assert(NumericCondition.matches(numeric("LessEqual", 1), 0 / 0))
		assert(not NumericCondition.matches(numeric("Greater", 1), 0 / 0))
		assert(not NumericCondition.matches(numeric("Less", 1), 0 / 0))
	end)
	harness.test(report, "conditions: speed_and_state_conditions_require_their_real_distinct_outputs", function()
		local input: any = graph.conditions.default_inputs()
		local speed: any = { kind = "Speed", along_skate_z = true, numeric = numeric("Less", 0) }
		assert(rt.catch(ActionCondition.evaluate, speed, input, IntentMap.new(), nil, {}) == nil)
		input.speeds = { speed = 4, forward_speed = -3, speed_and_slope = 2 }
		assert(ActionCondition.evaluate(speed, input, IntentMap.new(), nil, {}))
		local state: any = { kind = "CurrentState", name = "Riding", target = 1 }
		local parents = { false, 0, 1, 0 }
		assert(ActionCondition.evaluate(state, input, IntentMap.new(), 1, parents))
		assert(ActionCondition.evaluate(state, input, IntentMap.new(), 2, parents))
		assert(not ActionCondition.evaluate(state, input, IntentMap.new(), 3, parents))
		assert(not ActionCondition.evaluate(state, input, IntentMap.new(), nil, parents))
	end)
	harness.test(report, "conditions: push_brake_uses_ground_angle_and_skeleton_override", function()
		local ground = { ground_axis_y = 1, skeleton_disables_push_brake = false, maximum_ground_angle_degrees = 45 }
		assert(not PushBrakeInputs.disabled(ground))
		assert(PushBrakeInputs.disabled({ ground_axis_y = 0, skeleton_disables_push_brake = false, maximum_ground_angle_degrees = 45 }))
		assert(PushBrakeInputs.disabled({ ground_axis_y = 1, skeleton_disables_push_brake = true, maximum_ground_angle_degrees = 45 }))
	end)

	-- tests/intent_handlers.rs
	local function is(m: any, kind: string, value: number?): boolean
		return m.kind == kind and m.value == value
	end
	harness.test(report, "intent_handlers: constant_keeps_begin_value_for_one_frame_then_removes", function()
		local i = ConstMgIntent.new(2.5, false)
		assert(is(ConstMgIntent.begin(i), "Set", 2.5) and is(ConstMgIntent.update(i), "None") and is(ConstMgIntent.update(i), "Remove"))
	end)
	harness.test(report, "intent_handlers: constant_on_update_does_not_republish", function()
		local i = ConstMgIntent.new(-1, true)
		assert(is(ConstMgIntent.begin(i), "Set", -1))
		assert(is(ConstMgIntent.update(i), "None"))
		assert(is(ConstMgIntent.update(i), "None"))
	end)
	harness.test(report, "intent_handlers: constant_end_removes_without_changing_instance_state", function()
		local i = ConstMgIntent.new(2.5, false)
		ConstMgIntent.begin(i)
		local prev = table.clone(i)
		assert(is(ConstMgIntent["end"](i), "Remove"))
		assert(u.diff(i, prev) == nil)
	end)
	harness.test(report, "intent_handlers: time_uses_presence_and_accumulates_instance_clock", function()
		local i = TimeMgIntent.default()
		assert(is(TimeMgIntent.update(i, 0, 0.25), "Set", 0.25))
		assert(is(TimeMgIntent.update(i, 99, 0.5), "Set", 0.75))
		assert(is(TimeMgIntent.update(i, nil, 0.5), "Remove") and i.elapsed == 0)
	end)
	harness.test(report, "intent_handlers: time_end_removes_without_resetting_instance_clock", function()
		local i = TimeMgIntent.default()
		assert(is(TimeMgIntent.update(i, 0, 0.25), "Set", 0.25))
		assert(is(TimeMgIntent["end"](i), "Remove") and i.elapsed == 0.25)
		local _ = f32
	end)
end
