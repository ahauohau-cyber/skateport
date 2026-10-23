--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/graph/intents.rs (коммит 2e16697)
--
-- Canonical ActionGraph/MotionGraph intent identity.
-- TU3 FastString constructor 823C3BF8 uses six words of 82382B50 encoding.
-- Storage is ours; aliases share one value and the most recent write wins.

local playback_parameters = require("../animation/playback_parameters")

local intent_key = playback_parameters.intent_key

local intents = {}

-- Decoded names cannot bypass native case folding, NUL termination or the
-- 36-byte limit on insert, read or removal. Kept separate from five-word
-- animation attribute names and graph time tags.
-- ROBLOX: BTreeMap<[u32; 6], f32> -> словарь по строке из 6 слов + счётчик.
export type IntentMap = { values: { [string]: number }, count: number }

local IntentMap = {}
intents.IntentMap = IntentMap

local function key(name: string): string
	local k = intent_key(name)
	return table.concat(k, ",")
end

function IntentMap.new(): IntentMap
	return { values = {}, count = 0 }
end

function IntentMap.insert(self: IntentMap, name: string, value: number): number?
	local k = key(name)
	local old = self.values[k]
	if old == nil then
		self.count += 1
	end
	self.values[k] = value
	return old
end

function IntentMap.get(self: IntentMap, name: string): number?
	return self.values[key(name)]
end

function IntentMap.remove(self: IntentMap, name: string): number?
	local k = key(name)
	local old = self.values[k]
	if old ~= nil then
		self.values[k] = nil
		self.count -= 1
	end
	return old
end

function IntentMap.contains_key(self: IntentMap, name: string): boolean
	return self.values[key(name)] ~= nil
end

function IntentMap.clear(self: IntentMap)
	table.clear(self.values)
	self.count = 0
end

function IntentMap.len(self: IntentMap): number
	return self.count
end

function IntentMap.is_empty(self: IntentMap): boolean
	return self.count == 0
end

return intents
