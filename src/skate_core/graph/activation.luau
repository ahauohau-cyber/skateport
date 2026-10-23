--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/graph/activation.rs (коммит 2e16697)
--
-- Data-driven activation for the stock state graph.
--
-- Node::GetActivation 82C14C28 delegates to its expression with the caller's
-- mask. Condition::GetActivationMasked 82C12D48 excludes disabled conditions
-- and conditions whose authored mask does not intersect that mask. Expression
-- combination and its excluded-child rules are implemented in `expression`.

local expression_mod = require("./expression")
local selection = require("./selection")

local evaluate_operator = expression_mod.evaluate_operator

local activation = {}

-- ROBLOX: enum Child -> { kind = "Expression" | "Condition", id = number }.
export type Child = { kind: string, id: number }

export type Expression = {
	operator: number,
	-- Native child vector order. Evaluation is lazy, so this order is visible.
	children: { Child },
}

export type Condition = {
	enabled: boolean,
	-- Parsed CondMask bits from the stock condition's `mask` attribute.
	mask: number,
}

-- ROBLOX: Vec<Option<ExpressionId>> -> таблица, None -> false.
export type ActivationProgram = {
	state_expressions: { number | false },
	transition_expressions: { number | false },
	expressions: { Expression },
	conditions: { Condition },
}

-- Concrete condition implementations are registered by the game. The graph
-- runtime decides whether they run; the host only evaluates an included leaf.
-- ROBLOX: трейт -> таблица с методом condition_activation(condition, frame) -> u32.
export type ConditionHost = { condition_activation: (self: any, condition: number, frame: any) -> number }

local ActivationProgram = {}
activation.ActivationProgram = ActivationProgram

local expression_activation: (ActivationProgram, number, number, any, expression_mod.Cell, ConditionHost) -> number

-- Complete Condition::GetActivationMasked gate (82C12D48).
local function condition_activation(self: ActivationProgram, id: number, mask: number, frame: any, excluded: expression_mod.Cell, host: ConditionHost): number
	local condition = self.conditions[id + 1]
	if not condition.enabled or bit32.band(condition.mask, mask) == 0 then
		excluded.value = 1
		return 1
	end
	excluded.value = 0
	return host:condition_activation(id, frame)
end

function expression_activation(self: ActivationProgram, id: number, mask: number, frame: any, excluded: expression_mod.Cell, host: ConditionHost): number
	local e = self.expressions[id + 1]
	return evaluate_operator(e.operator, #e.children, excluded, function(index, child_excluded)
		local child = e.children[index + 1]
		if child.kind == "Expression" then
			return expression_activation(self, child.id, mask, frame, child_excluded, host)
		end
		return condition_activation(self, child.id, mask, frame, child_excluded, host)
	end)
end

-- Complete Node::GetActivation boundary (82C14C28).
function ActivationProgram.node_activation(self: ActivationProgram, node: selection.NodeId, mask: number, frame: any, host: ConditionHost): boolean
	local e = if node.kind == "State" then self.state_expressions[node.id + 1] else self.transition_expressions[node.id + 1]
	if e == nil or e == false then
		return true
	end
	local excluded = { value = 1 }
	local result = expression_activation(self, e :: number, mask, frame, excluded, host)
	return excluded.value ~= 0 or bit32.band(result, 255) ~= 0
end

return activation
