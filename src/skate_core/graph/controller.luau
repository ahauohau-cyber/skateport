--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/graph/controller.rs (коммит 2e16697)
--
-- Dynamic controller 82C13260, list preparation 82C13A00, Enter 82C13B20 and
-- Exit 82C13E58. The host owns concrete behavior/condition implementations and
-- instance storage. Graph topology is the processed stock asset.

local activation = require("./activation")
local selection = require("./selection")
local rt = require("../../rt")

local F32 = rt.f32

local controller = {}

export type Behavior = { owner: number, enabled: boolean }

export type Program = {
	topology: selection.Topology,
	root: number,
	activation: activation.ActivationProgram,
	behaviors: { Behavior },
	-- State+64 vector, in authored order.
	state_behaviors: { { number } },
	-- Transition+44 vector, in authored order.
	transition_hooks: { { number } },
}

-- ROBLOX: Vec<Option<f32>> -> таблица, None -> false.
export type Frame = {
	dt: number,
	current: number?,
	last: number?,
	-- Missing entries correspond to absent native state-time map entries.
	state_times: { number | false },
}

export type ActiveBehavior = {
	behavior: number,
	-- Opaque host instance handle; zero is the native null instance.
	instance: number,
}

-- Concrete nodes run immediately. Effects of End, hooks and Begin are visible
-- to subsequent calls in this tick. A context is the native six-word value;
-- its pointer words are opaque handles at this platform-independent boundary.
-- The host resolves them and owns instance lifetime (including external refs).
-- ROBLOX: трейт Host: ConditionHost -> таблица методов; context — 6 слов
-- (context[3] в Luau = context[2] в Rust — экземпляр).
export type Host = {
	condition_activation: (self: any, condition: number, frame: Frame) -> number,
	context: (self: any) -> { number },
	allocate: (self: any, behavior: number, frame: Frame) -> number,
	begin: (self: any, behavior: number, context: { number }, frame: Frame) -> (),
	update: (self: any, behavior: number, context: { number }, frame: Frame) -> (),
	["end"]: (self: any, behavior: number, context: { number }, frame: Frame) -> (),
	hook: (self: any, hook: number, frame: Frame) -> (),
	-- Release the controller's instance ownership after its End callback.
	release: (self: any, instance: number) -> (),
}

export type Controller = { frame: Frame, active: { ActiveBehavior } }

local Controller = {}
controller.Controller = Controller

function Controller.new(state_count: number): Controller
	return {
		frame = { dt = 0.0, current = nil, last = nil, state_times = table.create(state_count, false) },
		active = {},
	}
end

local function path(graph: selection.Topology, s: number?): { number }
	local result = {}
	while s ~= nil do
		table.insert(result, 1, s)
		s = graph.states[s + 1].parent
	end
	return result
end

local function contains(list: { number }, value: number): boolean
	return table.find(list, value) ~= nil
end

local function with_instance(host: Host, instance: number): { number }
	local context = host:context()
	context[3] = instance
	return context
end

-- Complete 82C13A00 / 82C122E8 / 82C12260. Explicit transitions to a
-- current ancestor re-enter that ancestor, including self transitions.
local function prepare_lists(self: Controller, program: Program, transition: number?, next_: number?): ({ number }, { number })
	local old_path = path(program.topology, self.frame.current)
	local boundary
	if transition == nil then
		boundary = next_
	else
		local target = program.topology.transitions[transition + 1].target
		if contains(old_path, target) then
			boundary = program.topology.states[target + 1].parent
		else
			boundary = target
		end
	end
	local boundary_path = path(program.topology, boundary)
	local common = 0
	while common < #old_path and common < #boundary_path and old_path[common + 1] == boundary_path[common + 1] do
		common += 1
	end
	local exiting = table.move(old_path, common + 1, #old_path, 1, {})
	local next_path = path(program.topology, next_)
	local entering = table.move(next_path, common + 1, #next_path, 1, {})
	self.frame.last = self.frame.current
	self.frame.current = next_
	return exiting, entering
end

local function exit(self: Controller, program: Program, exiting: { number }, host: Host)
	for index = #self.active, 1, -1 do
		local active = self.active[index]
		if contains(exiting, program.behaviors[active.behavior + 1].owner) then
			host["end"](host, active.behavior, with_instance(host, active.instance), self.frame)
			table.remove(self.active, index)
			host:release(active.instance)
		end
	end
	-- End observes the old state's final incremented time. Erasure follows
	-- every End callback, before transition hooks and new state timers.
	for _, s in exiting do
		self.frame.state_times[s + 1] = false
	end
end

local function enter(self: Controller, program: Program, entering: { number }, host: Host)
	-- All new state timers exist before the first allocation or Begin.
	for _, s in entering do
		self.frame.state_times[s + 1] = 0.0
	end
	for _, s in entering do
		for _, behavior in program.state_behaviors[s + 1] do
			if program.behaviors[behavior + 1].enabled then
				local instance = host:allocate(behavior, self.frame)
				table.insert(self.active, { behavior = behavior, instance = instance })
				host:begin(behavior, with_instance(host, instance), self.frame)
			end
		end
	end
end

function Controller.update(self: Controller, program: Program, dt: number, host: Host)
	self.frame.dt = dt
	local next_ = { value = nil :: number? }
	local sel = { graph = program.topology, root = program.root, current = self.frame.current }
	local transition = selection.Selection.next(sel, next_, function(node, mask)
		return activation.ActivationProgram.node_activation(program.activation, node, mask, self.frame, host)
	end)
	local exiting, entering = prepare_lists(self, program, transition, next_.value)

	-- ROBLOX: f32-сложение времени состояний.
	for i, time in self.frame.state_times do
		if time ~= false then
			self.frame.state_times[i] = F32(time :: number + dt)
		end
	end
	exit(self, program, exiting, host)
	if transition ~= nil then
		for _, hook in program.transition_hooks[transition + 1] do
			host:hook(hook, self.frame)
		end
	end
	enter(self, program, entering, host)
	for _, active in self.active do
		host:update(active.behavior, with_instance(host, active.instance), self.frame)
	end
end

-- DynamicHierarchicalController::EndAllBehaviours (82C13498). Native
-- shutdown visits active behaviours in reverse order and does not alter
-- the current state or state-time map; graph reset remains a separate act.
function Controller.end_all_behaviors(self: Controller, host: Host)
	while #self.active > 0 do
		local active = self.active[#self.active]
		host["end"](host, active.behavior, with_instance(host, active.instance), self.frame)
		table.remove(self.active)
		host:release(active.instance)
	end
end

return controller
