--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-data/src/state_graph/binding.rs (коммит 2e16697)
--
-- Dynamic graph object construction and name binding from TU3 82C15F50,
-- 82C11930, 82C16708, 82C169B8, 82C16D68, 82C16FF0 and 82C16C10.
-- Concrete operations are created through the native factory boundary and
-- receive each nested parameter in authored order.
-- ROBLOX: все индексы (state, transition, expression, operation, element)
-- хранятся с нуля, как в Rust; Option -> значение или nil.

local rt = require("../../rt")
local attributes_mod = require("./attributes")

local Attributes = attributes_mod.Attributes
local key_hash = attributes_mod.key_hash

local binding = {}

-- ROBLOX: enum Node -> { kind = "State" | "Transition" | "Expression" | "Operation", id }.
export type Node = { kind: "State" | "Transition" | "Expression" | "Operation", id: number }

local function node(kind: "State" | "Transition" | "Expression" | "Operation", id: number): Node
	return { kind = kind, id = id }
end
binding.node = node

export type State = {
	element: number,
	name: string,
	parent: number?,
	children: { number },
	behaviors: { number },
	transitions: { number },
	expression: number?,
	enabled: number,
	active: number,
	interruptibility: number,
	interrupt_ancestor: number?,
}

export type Transition = {
	element: number,
	owner: number,
	target: number?,
	enabled: number,
	priority: number,
	expression: number?,
	hooks: { number },
}

export type Expression = {
	element: number,
	enabled: number,
	operator: number,
	-- Ordered nested expressions and concrete condition operations.
	children: { Node },
}

-- ROBLOX: enum OperationKind -> "Behavior" | "Condition" | "Hook".
export type OperationKind = "Behavior" | "Condition" | "Hook"

export type Operation = {
	element: number,
	parent: Node,
	kind: OperationKind,
	name: string,
	enabled: number,
	-- Condition::mMask from 82C12CB0/82C12BB0. Other operation kinds have no
	-- condition mask.
	condition_mask: number?,
	-- Ordered `param` elements, consumed by the concrete virtual40 handler.
	parameters: { number },
}

export type Binding = {
	states: { State },
	transitions: { Transition },
	expressions: { Expression },
	operations: { Operation },
	root: number,
}

export type OperationInstances = {
	-- Same indices as `Binding::operations`.
	operations: { any },
}

-- /// Readable boundary for 8241BFF0 (factory create) and the parser's virtual+40
-- /// parameter dispatch in 82C15F50. A missing registration is represented by
-- /// `Ok(None)` and is rejected by `instantiate_operations` with source context.
-- ROBLOX: trait OperationFactory -> таблица с методами
--   create(self, kind, parent, attributes) -> instance или nil (ошибка — rt.raise);
--   add_parameter(self, instance, attributes) (ошибка — rt.raise).
export type OperationFactory = {
	create: (self: any, kind: OperationKind, parent: Node, attributes: any) -> any?,
	add_parameter: (self: any, instance: any, attributes: any) -> (),
}

local Binding = {}
binding.Binding = Binding

-- /// Native interned-name comparison 82C118A0 uses FNV-1, without string equality
-- /// after the hash comparison. This differs from BinaryAttributeMap's key hash.
function binding.name_hash(text: string): number
	local hash = 0x811c9dc5
	for i = 1, #text do
		-- ROBLOX: wrapping_mul по модулю 2^32 без потери точности (разбиение на 16 бит).
		local lo = bit32.band(hash, 0xffff)
		local hi = bit32.rshift(hash, 16)
		hash = (lo * 0x01000193 + bit32.lshift(bit32.band(hi * 0x0193, 0xffff), 16)) % 0x1_0000_0000
		hash = bit32.bxor(hash, string.byte(text, i))
	end
	return hash
end
local name_hash = binding.name_hash

-- /// StateGraph::ParseMask 82C12BB0. Comparison is case-sensitive. TU3 returns
-- /// the precondition mask for a missing or unrecognized value.
function binding.parse_condition_mask(value: string?): number
	if value == "sustain" then
		return 2
	elseif value == "always" then
		return 3
	elseif value == "postcond" then
		return 4
	end
	return 1
end

local function error_(source: any, element: number, message: string): string
	local e = source.elements[element + 1]
	return string.format("Graph %s at byte %d: %s", e.tag, e.source_offset, message)
end

local function operation_kind(kind: OperationKind): string
	if kind == "Behavior" then
		return "behaviour"
	elseif kind == "Condition" then
		return "condition"
	end
	return "hook"
end

local function operation_error(source: any, operation: Operation, message: string): string
	return error_(source, operation.element, string.format("%s `%s`: %s", operation_kind(operation.kind), operation.name, message))
end

local function enabled_of(self: Binding, n: Node): number
	if n.kind == "State" then
		return self.states[n.id + 1].enabled
	elseif n.kind == "Transition" then
		return self.transitions[n.id + 1].enabled
	elseif n.kind == "Expression" then
		return self.expressions[n.id + 1].enabled
	end
	return self.operations[n.id + 1].enabled
end

-- /// Complete 82C16C10 search: first direct child, then self/ancestors if
-- /// allowed. Dotted paths search their first component with ascent enabled,
-- /// even if the caller disabled ascent, then resolve the suffix locally.
function Binding.find_state(self: Binding, start: number, name: string, ascend: boolean): number?
	local dot = string.find(name, ".", 1, true)
	if dot ~= nil then
		local first = string.sub(name, 1, dot - 1)
		local rest = string.sub(name, dot + 1)
		local found = Binding.find_state(self, start, first, true)
		if found == nil then
			return nil
		end
		return Binding.find_state(self, found, rest, false)
	end
	local key = name_hash(name)
	local state = start
	while true do
		for _, child in self.states[state + 1].children do
			if name_hash(self.states[child + 1].name) == key then
				return child
			end
		end
		if not ascend then
			return nil
		end
		if name_hash(self.states[state + 1].name) == key then
			return state
		end
		local parent = self.states[state + 1].parent
		if parent == nil then
			return nil
		end
		state = parent
	end
end

local function process_names(self: Binding, source: any)
	for id = 0, #self.states - 1 do
		local state = self.states[id + 1]
		if state.interruptibility == 2 then
			local attrs = Attributes.new(source.elements[state.element + 1].attributes)
			local name = Attributes.text(attrs, "interruptable") :: string
			local target = Binding.find_state(self, id, name, true)
			if target == nil then
				rt.raise(error_(source, state.element, "unresolved interrupt ancestor"))
			end
			local ancestor: number? = id
			while ancestor ~= nil and ancestor ~= target do
				ancestor = self.states[ancestor + 1].parent
			end
			if ancestor == nil then
				rt.raise(error_(source, state.element, "interrupt target is not an ancestor"))
			end
			self.states[id + 1].interrupt_ancestor = target
		end
	end
	for id = 0, #self.transitions - 1 do
		local transition = self.transitions[id + 1]
		local attrs = Attributes.new(source.elements[transition.element + 1].attributes)
		local target = Binding.find_state(self, transition.owner, Attributes.text(attrs, "target") or "", true)
		transition.target = target
		-- 82C16FF0 disables unresolved/disabled targets; no invented fallback.
		if target == nil or self.states[target + 1].enabled == 0 then
			transition.enabled = 0
		end
	end
end

-- /// Binds the compiled dynamic graph structure, not its registered gameplay
-- /// operations. The source graph remains the owner of raw typed attributes.
-- ROBLOX: Result<Self, AssetError> -> Binding или rt.raise(строка).
function Binding.from_graph(source: any): Binding
	local result: Binding = { states = {}, transitions = {}, expressions = {}, operations = {}, root = 0 }
	local count = #source.elements
	local parents: { number | false } = table.create(count, false)
	local nodes: { Node | false } = table.create(count, false)
	local STATE, TRANSITION, EXPRESSION, PARAM = key_hash("state"), key_hash("transition"), key_hash("expression"), key_hash("param")
	local BEHAVIOUR, CONDITION, HOOK = key_hash("behaviour"), key_hash("condition"), key_hash("hook")
	for i0 = 0, count - 1 do
		local element = source.elements[i0 + 1]
		for _, child in element.children do
			if child <= i0 or child >= count or parents[child + 1] ~= false then
				rt.raise(error_(source, i0, "invalid preorder ownership"))
			end
			parents[child + 1] = i0
		end
		local p = parents[i0 + 1]
		local parent: Node? = nil
		if p ~= false then
			local n = nodes[(p :: number) + 1]
			if n ~= false then
				parent = n :: Node
			end
		end
		local attrs = Attributes.new(element.attributes)
		local enabled = if parent ~= nil and enabled_of(result, parent) == 0 then 0 else Attributes.boolean_byte(attrs, "enabled", 1)
		local name = Attributes.text(attrs, "name") or "__unknown__"
		local tag = key_hash(element.tag)
		local this: Node
		if tag == STATE then
			local parent_state: number? = nil
			if parent == nil and i0 == 0 then
				parent_state = nil
			elseif parent ~= nil and parent.kind == "State" then
				parent_state = parent.id
			else
				rt.raise(error_(source, i0, "state requires a state parent"))
			end
			local text = Attributes.text(attrs, "interruptable") or "true"
			local interruptibility = if text == "true" then 1 elseif text == "false" then 0 else 2
			local id = #result.states
			table.insert(result.states, {
				element = i0,
				name = name,
				parent = parent_state,
				children = {},
				behaviors = {},
				transitions = {},
				expression = nil,
				enabled = enabled,
				active = Attributes.boolean_byte(attrs, "active", 1),
				interruptibility = interruptibility,
				interrupt_ancestor = nil,
			})
			if parent_state ~= nil then
				table.insert(result.states[parent_state + 1].children, id)
			end
			this = node("State", id)
		elseif tag == TRANSITION then
			if parent == nil or parent.kind ~= "State" then
				rt.raise(error_(source, i0, "transition requires a state parent"))
			end
			local owner = (parent :: Node).id
			local id = #result.transitions
			local text = Attributes.text(attrs, "priority")
			local priority = if text == "med" then 1 elseif text == "high" then 2 elseif text == "urgent" then 3 else 0
			table.insert(result.transitions, {
				element = i0,
				owner = owner,
				target = nil,
				enabled = enabled,
				priority = priority,
				expression = nil,
				hooks = {},
			})
			table.insert(result.states[owner + 1].transitions, id)
			this = node("Transition", id)
		elseif tag == EXPRESSION then
			local id = #result.expressions
			local text = Attributes.text(attrs, "op")
			local operator = if text == "and" then 1 elseif text == "or" then 2 elseif text == "not" then 3 else 0
			table.insert(result.expressions, { element = i0, enabled = enabled, operator = operator, children = {} } :: Expression)
			if parent ~= nil and parent.kind == "State" then
				result.states[parent.id + 1].expression = id
			elseif parent ~= nil and parent.kind == "Transition" then
				result.transitions[parent.id + 1].expression = id
			elseif parent ~= nil and parent.kind == "Expression" then
				table.insert(result.expressions[parent.id + 1].children, node("Expression", id))
			else
				rt.raise(error_(source, i0, "expression requires state, transition or expression parent"))
			end
			this = node("Expression", id)
		elseif tag == PARAM then
			if parent == nil or parent.kind ~= "Operation" then
				rt.raise(error_(source, i0, "unbound parameter handler"))
			end
			table.insert(result.operations[(parent :: Node).id + 1].parameters, i0)
			if #element.children > 0 then
				rt.raise(error_(source, i0, "parameter children have no native object parent"))
			end
			continue
		else
			local kind: OperationKind
			if tag == BEHAVIOUR then
				kind = "Behavior"
			elseif tag == CONDITION then
				kind = "Condition"
			elseif tag == HOOK then
				kind = "Hook"
			else
				rt.raise(error_(source, i0, "unsupported graph element"))
			end
			if parent == nil then
				rt.raise(error_(source, i0, "operation requires a parent"))
			end
			local par = parent :: Node
			local id = #result.operations
			if kind == "Behavior" and par.kind == "State" then
				table.insert(result.states[par.id + 1].behaviors, id)
			elseif kind == "Condition" and par.kind == "Expression" then
				table.insert(result.expressions[par.id + 1].children, node("Operation", id))
			elseif kind == "Hook" and par.kind == "Transition" then
				table.insert(result.transitions[par.id + 1].hooks, id)
			else
				rt.raise(error_(source, i0, "unsupported operation parent"))
			end
			table.insert(result.operations, {
				element = i0,
				parent = par,
				kind = kind,
				name = name,
				enabled = enabled,
				condition_mask = if kind == "Condition" then binding.parse_condition_mask(Attributes.text(attrs, "mask")) else nil,
				parameters = {},
			} :: Operation)
			this = node("Operation", id)
		end
		nodes[i0 + 1] = this
	end
	if #result.states == 0 then
		rt.raise("Graph has no root state")
	end
	process_names(result, source)
	return result
end

-- /// Instantiates every concrete operation from its complete attribute map,
-- /// then passes its `param` maps one at a time in stock child order.
function Binding.instantiate_operations(self: Binding, source: any, factory: OperationFactory): OperationInstances
	local instances = table.create(#self.operations)
	for _, operation in self.operations do
		local attrs = Attributes.new(source.elements[operation.element + 1].attributes)
		local instance, err = rt.catch(factory.create, factory, operation.kind, operation.parent, attrs)
		if err ~= nil then
			rt.raise(operation_error(source, operation, tostring(err)))
		end
		if instance == nil then
			rt.raise(operation_error(source, operation, "unregistered operation"))
		end
		for _, element in operation.parameters do
			local pattrs = Attributes.new(source.elements[element + 1].attributes)
			local _, perr = rt.catch(factory.add_parameter, factory, instance, pattrs)
			if perr ~= nil then
				rt.raise(operation_error(source, operation, tostring(perr)))
			end
		end
		table.insert(instances, instance)
	end
	return { operations = instances }
end

return binding
