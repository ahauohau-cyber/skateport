--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-game/src/graph_runtime.rs (коммит 2e16697)
--
-- Lossless bridge from the stock on-disk graph binding to the recovered TU3
-- dynamic-controller runtime.
--
-- Concrete operations are intentionally retained by source operation ID. The
-- registration layer must construct every named operation before either graph
-- can execute; this module never substitutes a default handler.
-- ROBLOX: bevy::Resource -> обычная таблица; индексы с нуля, как в Rust;
-- Option<usize> в векторах -> число или false.

local rt = require("../rt")
local state_graph = require("../skate_data/state_graph")
local manifest = require("../skate_data/manifest")

local StateGraph = state_graph.StateGraph
local Binding = state_graph.binding.Binding

local graph_runtime = {}

-- ROBLOX: enum GraphCompileError -> { kind = ..., поля }.
export type GraphCompileError = { kind: string, [string]: any }

-- ROBLOX: impl Display for GraphCompileError.
function graph_runtime.compile_error_to_string(e: GraphCompileError): string
	local k = e.kind
	if k == "UnresolvedTransitionTarget" then
		return string.format("stock graph transition %d has no resolved target", e.transition)
	elseif k == "InvalidOperationParent" then
		return string.format("stock graph operation %d does not have its required %s parent", e.operation, e.expected)
	elseif k == "InvalidStateBehavior" then
		return string.format("stock graph state %d references non-behavior operation %d", e.state, e.operation)
	elseif k == "InvalidTransitionHook" then
		return string.format("stock graph transition %d references non-hook operation %d", e.transition, e.operation)
	elseif k == "InvalidExpressionChild" then
		-- ROBLOX: {node:?} -> "State(3)" и т.п.
		return string.format("stock graph expression %d has invalid child %s(%d)", e.expression, e.node.kind, e.node.id)
	elseif k == "MissingConditionMask" then
		return string.format("stock graph condition %d has no parsed TU3 mask", e.operation)
	end
	return tostring(k)
end

-- /// Compact runtime IDs map back to the original binding operation IDs. The
-- /// future concrete host uses these tables to reach its exact factory instances.
export type OperationRemap = {
	behaviors: { number },
	conditions: { number },
	hooks: { number },
}

export type CompiledGraph = {
	program: any,
	operations: OperationRemap,
}

local CompiledGraph = {}
graph_runtime.CompiledGraph = CompiledGraph

-- ROBLOX: Result<Self, GraphCompileError> -> CompiledGraph или rt.raise(GraphCompileError).
function CompiledGraph.from_binding(binding: any): CompiledGraph
	local operation_count = #binding.operations
	local behavior_for_operation: { number | false } = table.create(operation_count, false)
	local condition_for_operation: { number | false } = table.create(operation_count, false)
	local hook_for_operation: { number | false } = table.create(operation_count, false)
	local behavior_operations, condition_operations, hook_operations = {}, {}, {}

	for operation_id0, operation in binding.operations do
		local operation_id = operation_id0 - 1
		if operation.kind == "Behavior" then
			behavior_for_operation[operation_id0] = #behavior_operations
			table.insert(behavior_operations, operation_id)
		elseif operation.kind == "Condition" then
			condition_for_operation[operation_id0] = #condition_operations
			table.insert(condition_operations, operation_id)
		else
			hook_for_operation[operation_id0] = #hook_operations
			table.insert(hook_operations, operation_id)
		end
	end

	local states = {}
	for _, state in binding.states do
		table.insert(states, {
			parent = state.parent,
			enabled = state.enabled ~= 0,
			active = state.active ~= 0,
			interruptibility = state.interruptibility,
			interrupt_ancestor = state.interrupt_ancestor,
			children = table.clone(state.children),
			transitions = table.clone(state.transitions),
		})
	end
	local transitions = {}
	for id0, transition in binding.transitions do
		if transition.target == nil then
			rt.raise({ kind = "UnresolvedTransitionTarget", transition = id0 - 1 })
		end
		table.insert(transitions, { enabled = transition.enabled ~= 0, target = transition.target, priority = transition.priority })
	end
	local topology = { states = states, transitions = transitions }

	local conditions = {}
	for _, operation_id in condition_operations do
		local operation = binding.operations[operation_id + 1]
		if operation.condition_mask == nil then
			rt.raise({ kind = "MissingConditionMask", operation = operation_id })
		end
		table.insert(conditions, { enabled = operation.enabled ~= 0, mask = operation.condition_mask })
	end

	local expressions = {}
	for expression_id0, expression in binding.expressions do
		local expression_id = expression_id0 - 1
		local children = {}
		for _, node in expression.children do
			if node.kind == "Expression" then
				table.insert(children, { kind = "Expression", id = node.id })
			elseif node.kind == "Operation" and condition_for_operation[node.id + 1] ~= false then
				table.insert(children, { kind = "Condition", id = condition_for_operation[node.id + 1] })
			else
				rt.raise({ kind = "InvalidExpressionChild", expression = expression_id, node = node })
			end
		end
		table.insert(expressions, { operator = expression.operator, children = children })
	end

	local behaviors = {}
	for _, operation_id in behavior_operations do
		local operation = binding.operations[operation_id + 1]
		if operation.parent.kind ~= "State" then
			rt.raise({ kind = "InvalidOperationParent", operation = operation_id, expected = "state" })
		end
		table.insert(behaviors, { owner = operation.parent.id, enabled = operation.enabled ~= 0 })
	end

	local state_behaviors = {}
	for state0, source in binding.states do
		local list = {}
		for _, operation in source.behaviors do
			local b = behavior_for_operation[operation + 1]
			if b == false then
				rt.raise({ kind = "InvalidStateBehavior", state = state0 - 1, operation = operation })
			end
			table.insert(list, b)
		end
		table.insert(state_behaviors, list)
	end

	local transition_hooks = {}
	for transition0, source in binding.transitions do
		local list = {}
		for _, operation in source.hooks do
			local h = hook_for_operation[operation + 1]
			if h == false then
				rt.raise({ kind = "InvalidTransitionHook", transition = transition0 - 1, operation = operation })
			end
			table.insert(list, h)
		end
		table.insert(transition_hooks, list)
	end

	local state_expressions, transition_expressions = {}, {}
	for i, state in binding.states do
		state_expressions[i] = if state.expression ~= nil then state.expression else false
	end
	for i, transition in binding.transitions do
		transition_expressions[i] = if transition.expression ~= nil then transition.expression else false
	end

	return {
		program = {
			topology = topology,
			root = binding.root,
			activation = {
				state_expressions = state_expressions,
				transition_expressions = transition_expressions,
				expressions = expressions,
				conditions = conditions,
			},
			behaviors = behaviors,
			state_behaviors = state_behaviors,
			transition_hooks = transition_hooks,
		},
		operations = {
			behaviors = behavior_operations,
			conditions = condition_operations,
			hooks = hook_operations,
		},
	}
end

export type LoadedGraph = {
	source: any,
	binding: any,
	runtime: CompiledGraph,
}

export type StockGraphs = {
	action: LoadedGraph,
	motion: LoadedGraph,
}

local StockGraphs = {}
graph_runtime.StockGraphs = StockGraphs

local function load_graph(relative: string): LoadedGraph
	-- ROBLOX: root.join(relative) -> путь в упакованных файлах без "private/".
	local path = manifest.private_path(relative)
	local source = StateGraph.load(path)
	local binding = Binding.from_graph(source)
	local runtime, err = rt.catch(CompiledGraph.from_binding, binding)
	if err ~= nil then
		rt.raise(string.format("Invalid runtime graph %s: %s", relative, graph_runtime.compile_error_to_string(err)))
	end
	return { source = source, binding = binding, runtime = runtime }
end

-- ROBLOX: Result<Self, String> -> StockGraphs или rt.raise(строка).
function StockGraphs.load(game_assets: manifest.GameAssets): StockGraphs
	return {
		action = load_graph(game_assets.action_graph),
		motion = load_graph(game_assets.motion_graph),
	}
end

return graph_runtime
