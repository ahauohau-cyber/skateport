--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/input/graph_intents.rs (коммит 2e16697)
--
-- Native CreateMGIntentFromAGIntent and AttachIntent behavior boundaries.

local rt = require("../../rt")

local f32 = rt.f32
local from_bits = rt.from_bits

local graph_intents = {}

local PI = from_bits(0x40490fdb)
local HALF_PI = from_bits(0x3fc90fdb)
local TAU = from_bits(0x40c90fdb)

-- Complete 82BA0C20. Ordinals come from 82BA0A48 and stock filter names.
function graph_intents.apply_filter(value: number, kind: number): number
	if kind == 0 then
		return value
	elseif kind == 1 then
		return f32(value * -1.0)
	elseif kind == 2 then
		return math.abs(value)
	elseif kind == 3 then
		return if value >= 0.0 then f32(1.0 - value) else f32(-1.0 - value)
	elseif kind == 4 then
		local lower = if -value >= 0.0 then 0.0 else value
		return if f32(1.0 - lower) >= 0.0 then lower else 1.0
	elseif kind == 5 then
		return if value >= 0.0 then f32(PI - value) else f32(-PI - value)
	elseif kind == 6 then
		local rotated = f32(value - HALF_PI)
		return if rotated < -PI then f32(rotated + TAU) else rotated
	else
		local rotated = f32(value + HALF_PI)
		return if rotated > PI then f32(rotated - TAU) else rotated
	end
end

-- ROBLOX: Option<(bool, bool)> -> { fakie, mirror } или nil.
export type Stance = { boolean }

-- Four source ordinals: filter1, filter2, fakieFilter, mirrorFilter.
-- Missing stance component bypasses every filter, matching 82BA2930.
function graph_intents.filter_chain(value: number, filters: { number }, stance: Stance?): number
	if stance ~= nil then
		local enabled = { true, true, stance[1], stance[2] }
		for i = 1, 4 do
			local kind = filters[i]
			if enabled[i] and kind <= 7 then
				value = graph_intents.apply_filter(value, kind)
			end
		end
	end
	return value
end

-- ROBLOX: enum IntentMutation -> { kind = "None" | "Remove" | "Set", value }.
export type IntentMutation = { kind: string, value: number? }

graph_intents.IntentMutation = {
	None = table.freeze({ kind = "None" }) :: IntentMutation,
	Remove = table.freeze({ kind = "Remove" }) :: IntentMutation,
	Set = function(value: number): IntentMutation
		return { kind = "Set", value = value }
	end,
}
local Mutation = graph_intents.IntentMutation

export type CreateMgIntent = { on_update: boolean, default_value: number?, scale: number, filters: { number } }

local CreateMgIntent = {}
graph_intents.CreateMgIntent = CreateMgIntent

-- Complete 82BA2790 with container lookup/removal/insertion represented by
-- an explicit mutation. Keys are the caller's decoded MGIntent/AGIntent.
function CreateMgIntent.emit(self: CreateMgIntent, action_value: number?, stance: Stance?): IntentMutation
	local value = if action_value ~= nil then action_value else self.default_value
	if value == nil then
		return Mutation.Remove
	end
	return Mutation.Set(graph_intents.filter_chain(f32(self.scale * value), self.filters, stance))
end

-- Complete 82BA26F0 lifecycle write, including absent-input removal.
-- ROBLOX: &mut bool -> ячейка { value = ... }.
function CreateMgIntent.enter(self: CreateMgIntent, created_this_frame: { value: boolean }, action_value: number?, stance: Stance?): IntentMutation
	local result = CreateMgIntent.emit(self, action_value, stance)
	created_this_frame.value = true
	return result
end

-- Complete 82BA2728: onUpdate=false removes on subsequent updates.
function CreateMgIntent.update(self: CreateMgIntent, created_this_frame: { value: boolean }, action_value: number?, stance: Stance?): IntentMutation
	local result
	if self.on_update then
		result = CreateMgIntent.emit(self, action_value, stance)
	elseif not created_this_frame.value then
		result = Mutation.Remove
	else
		result = Mutation.None
	end
	created_this_frame.value = false
	return result
end

-- 82BA2788 -> 82BA28B8 unconditionally removes the owned MG intent.
function CreateMgIntent.exit(self: CreateMgIntent): IntentMutation
	return Mutation.Remove
end

-- Complete 82BB5AE0 at resolved lookup/sink boundaries. The packet sink is
-- invoked first; optional skeleton sink receives the same value afterwards.
function graph_intents.attach_intent(value: number?, set_skeleton: boolean, packet: (number) -> (), skeleton: (number) -> ())
	if value ~= nil then
		packet(value)
		if set_skeleton then
			skeleton(value)
		end
	end
end

return graph_intents
