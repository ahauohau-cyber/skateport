--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/graph/selection.rs (коммит 2e16697)
--
-- Native dynamic-controller selection: 82C140D8 and its complete state-search
-- helpers. Topology and flags come from loaded graph objects, never a riding
-- state machine. The activation callback is Node::GetActivation's boundary.
--
-- ROBLOX: StateId/TransitionId — индексы с нуля, как в Rust (states[id + 1]).
-- Option<StateId> -> число или nil.

local selection = {}

-- ROBLOX: enum NodeId -> { kind = "State" | "Transition", id = number }.
export type NodeId = { kind: string, id: number }

function selection.State(id: number): NodeId
	return { kind = "State", id = id }
end
function selection.Transition(id: number): NodeId
	return { kind = "Transition", id = id }
end

export type State = {
	parent: number?,
	enabled: boolean,
	active: boolean,
	-- Native state+36: 0=false, 1=true, 2=resolved ancestor name.
	interruptibility: number,
	interrupt_ancestor: number?,
	children: { number },
	transitions: { number },
}

export type Transition = { enabled: boolean, target: number, priority: number }

export type Topology = { states: { State }, transitions: { Transition } }

export type Selection = { graph: Topology, root: number, current: number? }

-- ROBLOX: FnMut(NodeId, u32) -> bool.
export type Activate = (NodeId, number) -> boolean

local Selection = {}
selection.Selection = Selection

local function state(self: Selection, id: number): State
	return self.graph.states[id + 1]
end

local function is_ancestor(self: Selection, ancestor: number, s: number?): boolean
	while s ~= nil do
		if s == ancestor then
			return true
		end
		s = state(self, s).parent
	end
	return false
end

-- Complete state-parent activation chain 82C16B88 for State objects.
local function ancestors_active(self: Selection, s: number, mask: number, activate: Activate): boolean
	while true do
		if not activate(selection.State(s), mask) then
			return false
		end
		local parent = state(self, s).parent
		if parent == nil then
			return true
		end
		s = parent
	end
end

local descend: (Selection, number, number, Activate) -> number?

local function first_child_or_leaf(self: Selection, s: number, mask: number, activate: Activate): number?
	local children = state(self, s).children
	if #children == 0 then
		return s
	end
	for _, child in children do
		local node = state(self, child)
		if node.enabled and node.active then
			local leaf = descend(self, child, mask, activate)
			if leaf ~= nil then
				return leaf
			end
		end
	end
	return nil
end

-- Complete 82C14710 (82C14708 is its thunk).
function descend(self: Selection, s: number, mask: number, activate: Activate): number?
	local effective_mask = if mask == 2 and is_ancestor(self, s, self.current) then 2 else 1
	if not activate(selection.State(s), effective_mask) then
		return nil
	end
	return first_child_or_leaf(self, s, mask, activate)
end

-- Complete ValidTarget 82C14978. Target and new ancestors use preconditions;
-- a shared ancestor (other than target) and its parents use mask 2.
local function valid_target(self: Selection, current: number?, target: number, activate: Activate): boolean
	local next_: number? = target
	while next_ ~= nil do
		local s = next_
		if s ~= target and is_ancestor(self, s, current) then
			return ancestors_active(self, s, 2, activate)
		end
		if not activate(selection.State(s), 1) then
			return false
		end
		next_ = state(self, s).parent
	end
	return true
end

-- Complete priority-specific SearchTransitions 82C14810, leaf to root.
local function search_transitions(self: Selection, s: number, priority: number, activate: Activate): (number?, number?)
	while true do
		for _, id in state(self, s).transitions do
			local transition = self.graph.transitions[id + 1]
			local target = transition.target
			if transition.priority == priority and transition.enabled and state(self, target).enabled then
				if activate(selection.Transition(id), 1) and valid_target(self, self.current, target, activate) and activate(selection.State(target), 1) then
					local leaf = first_child_or_leaf(self, target, 1, activate)
					if leaf ~= nil then
						return id, leaf
					end
				end
			end
		end
		local parent = state(self, s).parent
		if parent == nil then
			return nil, nil
		end
		s = parent
	end
end

-- Complete GetNextState 82C140D8. The output slot is explicit because an
-- unrecognized interruptibility ordinal leaves it untouched in TU3.
-- ROBLOX: target: &mut Option<StateId> -> ячейка { value = number? }.
function Selection.next(self: Selection, target: { value: number? }, activate: Activate): number?
	local current = self.current
	if current == nil then
		target.value = descend(self, self.root, 1, activate)
		return nil
	end
	for priority = 3, 0, -1 do
		local transition, s = search_transitions(self, current, priority, activate)
		if transition ~= nil then
			target.value = s
			return transition
		end
	end
	-- Complete retained/reselected-state path 82C14248.
	local interruptibility = state(self, current).interruptibility
	if interruptibility == 0 and ancestors_active(self, current, 2, activate) then
		target.value = current
	elseif interruptibility == 0 or interruptibility == 1 then
		target.value = descend(self, self.root, 2, activate)
	elseif interruptibility == 2 then
		local ancestor = state(self, current).interrupt_ancestor
		assert(ancestor ~= nil, "native processed interrupt ancestor must resolve")
		if ancestors_active(self, ancestor, 2, activate) then
			target.value = descend(self, ancestor, 2, activate)
			if target.value ~= nil then
				return nil
			end
		end
		target.value = descend(self, self.root, 2, activate)
	end
	return nil
end

return selection
