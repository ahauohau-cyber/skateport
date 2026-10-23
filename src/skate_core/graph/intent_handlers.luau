--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/graph/intent_handlers.rs (коммит 2e16697)
--
-- Source-backed constant and clock-derived MotionGraph intent behaviours.
--
-- These are the small stateful operation boundaries used by the stock graph
-- host. They deliberately return the existing `IntentMutation` protocol so
-- the host remains the sole owner of the intent map.

local rt = require("../../rt")
local graph_intents = require("../input/graph_intents")

local Mutation = graph_intents.IntentMutation

local intent_handlers = {}

-- TU3 `CreateConstMGIntent` (factory 0x82BC26D8, ctor 0x82BA1768,
-- Begin 0x82BA18A0, Update 0x82BA1938, End 0x82BA1988/0x82BA1990).
export type ConstMgIntent = { value: number, on_update: boolean, created: boolean }

local ConstMgIntent = {}
intent_handlers.ConstMgIntent = ConstMgIntent

function ConstMgIntent.new(value: number, on_update: boolean): ConstMgIntent
	return { value = value, on_update = on_update, created = false }
end

-- Begin publishes the authored constant and marks the instance alive.
function ConstMgIntent.begin(self: ConstMgIntent): graph_intents.IntentMutation
	self.created = true
	return Mutation.Set(self.value)
end

-- TU3 does not republish the constant when `onUpdate` is true. It keeps
-- the existing map value. A false `onUpdate` instance removes its value
-- only after the begin frame has elapsed.
function ConstMgIntent.update(self: ConstMgIntent): graph_intents.IntentMutation
	local mutation = if self.on_update or self.created then Mutation.None else Mutation.Remove
	self.created = false
	return mutation
end

-- End removes the owned intent unconditionally. Native End only emits
-- the remove operation; instance storage is released by the host.
ConstMgIntent["end"] = function(self: ConstMgIntent): graph_intents.IntentMutation
	return Mutation.Remove
end

-- TU3 `CreateMGTimeIntentFromAGIntent` (factory 0x82BC2778, ctor 0x82BA3040,
-- Update 0x82BA3158, End 0x82BA28B8). The graph-clock value is supplied by
-- the host; this operation only applies the verified dt accumulation rule.
export type TimeMgIntent = { elapsed: number }

local TimeMgIntent = {}
intent_handlers.TimeMgIntent = TimeMgIntent

function TimeMgIntent.default(): TimeMgIntent
	return { elapsed = 0.0 }
end

-- The AG lookup is an existence check only. Any present value advances
-- the instance clock by the caller's dt; its amplitude is not consumed.
-- An absent AG key resets the clock and removes the MG entry.
function TimeMgIntent.update(self: TimeMgIntent, action_value: number?, dt: number): graph_intents.IntentMutation
	if action_value ~= nil then
		self.elapsed = rt.f32(self.elapsed + dt)
		return Mutation.Set(self.elapsed)
	end
	self.elapsed = 0.0
	return Mutation.Remove
end

-- Native End removes the map entry and does not reset elapsed state.
TimeMgIntent["end"] = function(self: TimeMgIntent): graph_intents.IntentMutation
	return Mutation.Remove
end

return intent_handlers
