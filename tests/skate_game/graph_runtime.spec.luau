--!strict
-- Перенос Rust-тестов skate-game/src/tests/graph_runtime.rs и компиляция
-- стоковых графов (если файлы игры упакованы).

local harness = require("../harness")
local u = require("../util")
local rt = require("../../src/rt")
local files = require("../../src/skate_data/files")
local manifest = require("../../src/skate_data/manifest")
local graph_runtime = require("../../src/skate_game/graph_runtime")

local CompiledGraph = graph_runtime.CompiledGraph

local function binding(): any
	return {
		states = { {
			element = 0, name = "root", parent = nil, children = {}, behaviors = { 0 }, transitions = { 0 },
			expression = 0, enabled = 1, active = 1, interruptibility = 2, interrupt_ancestor = 0,
		} },
		transitions = { { element = 1, owner = 0, target = 0, enabled = 1, priority = 3, expression = 0, hooks = { 2 } } },
		expressions = { { element = 2, enabled = 1, operator = 1, children = { { kind = "Operation", id = 1 } } } },
		operations = {
			{ element = 3, parent = { kind = "State", id = 0 }, kind = "Behavior", name = "behavior", enabled = 1, condition_mask = nil, parameters = { 6 } },
			{ element = 4, parent = { kind = "Expression", id = 0 }, kind = "Condition", name = "condition", enabled = 1, condition_mask = 3, parameters = { 7, 8 } },
			{ element = 5, parent = { kind = "Transition", id = 0 }, kind = "Hook", name = "hook", enabled = 1, condition_mask = nil, parameters = {} },
		},
		root = 0,
	}
end

return function(report: harness.Report)
	harness.test(report, "graph_runtime: preserves_topology_and_authored_operation_identity", function()
		local compiled = CompiledGraph.from_binding(binding())
		local p = compiled.program
		assert(p.root == 0)
		assert(p.topology.states[1].interruptibility == 2)
		assert(p.topology.transitions[1].target == 0)
		assert(p.topology.transitions[1].priority == 3)
		u.diff(p.activation.state_expressions, { 0 })
		assert(p.activation.state_expressions[1] == 0 and p.activation.transition_expressions[1] == 0)
		assert(u.diff(p.activation.expressions[1].children, { { kind = "Condition", id = 0 } }) == nil)
		assert(p.activation.conditions[1].mask == 3)
		assert(p.behaviors[1].owner == 0)
		assert(u.diff(p.state_behaviors, { { 0 } }) == nil)
		assert(u.diff(p.transition_hooks, { { 0 } }) == nil)
		assert(u.diff(compiled.operations, { behaviors = { 0 }, conditions = { 1 }, hooks = { 2 } }) == nil)
	end)

	harness.test(report, "graph_runtime: refuses_an_unresolved_transition_instead_of_choosing_a_fallback", function()
		local source = binding()
		source.transitions[1].target = nil
		local _, err = rt.catch(CompiledGraph.from_binding, source)
		assert(u.diff(err, { kind = "UnresolvedTransitionTarget", transition = 0 }) == nil)
	end)

	local ok, src = pcall(require, "../../src/skate_data/stock_files")
	if not ok or type(src) ~= "table" then
		return
	end
	files.set_source(src)
	harness.test(report, "graph_runtime: StockGraphs.load компилирует оба стоковых графа", function()
		local graphs = graph_runtime.StockGraphs.load(manifest.GameAssets.load())
		assert(#graphs.motion.runtime.program.topology.states == #graphs.motion.binding.states)
		assert(#graphs.action.runtime.operations.behaviors + #graphs.action.runtime.operations.conditions + #graphs.action.runtime.operations.hooks == #graphs.action.binding.operations)
	end)
end
