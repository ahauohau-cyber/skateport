--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/playback_parameters.rs (коммит 2e16697)
--
-- PlayAnimation's parameter refresh 82BB4760 and settable queue 82D19100.

local rt = require("../../rt")
local attributes = require("./output/attributes")
local name = require("./skeleton_input/name")

local playback_parameters = {}

-- ROBLOX: enum ParameterSource -> { kind = "MotionIntent" | "FilteredIntent", name = string }
-- или { kind = "LastAnimation", attribute = AttributeName }.
export type ParameterSource = { kind: string, name: string?, attribute: attributes.AttributeName? }

export type PlaybackParameter = {
	source: ParameterSource,
	rename: attributes.AttributeName?,
	default_value: number?,
	normalized: boolean,
}

export type SettableAttribute = {
	name: attributes.AttributeName,
	value: number,
	normalized: boolean,
	sequence_id: number,
}

-- Gameplay providers are queried when a node executes, preserving visibility
-- of earlier same-tick graph operations and the last animation tree output.
-- ROBLOX: трейт -> таблица методов; last_attribute возвращает
-- (атрибут или nil) или (nil, ошибка) — второй результат = Err.
export type ParameterInputs = {
	motion_intent: (self: any, name: string) -> number?,
	filtered_intent: (self: any, name: string) -> number?,
	last_attribute: (self: any, name: attributes.AttributeName) -> (attributes.AnimationAttribute?, any),
}

export type AttributeSink = {
	set_attribute: (self: any, attribute: SettableAttribute) -> (),
}

export type SettableAttributes = { entries: { SettableAttribute } }

local SettableAttributes = {}
playback_parameters.SettableAttributes = SettableAttributes

function SettableAttributes.default(): SettableAttributes
	return setmetatable({ entries = {} }, { __index = SettableAttributes }) :: any
end
function SettableAttributes.entries(self: SettableAttributes): { SettableAttribute }
	return self.entries
end
function SettableAttributes.clear(self: SettableAttributes)
	table.clear(self.entries)
end
-- impl AttributeSink for SettableAttributes
function SettableAttributes.set_attribute(self: SettableAttributes, attribute: SettableAttribute)
	for i, entry in self.entries do
		if attributes.name_eq(entry.name, attribute.name) and entry.sequence_id == attribute.sequence_id then
			self.entries[i] = attribute
			return
		end
	end
	table.insert(self.entries, attribute)
end

-- Six-word intent/animation identifiers use the same native six-character
-- chunks as the five-word attribute encoder, but retain up to 36 input bytes.
function playback_parameters.intent_key(text: string): { number }
	local first = name.encode(text)
	local tail = 0
	if #text > 30 and not string.find(string.sub(text, 1, 30), "\0", 1, true) then
		tail = name.encode(string.sub(text, 31))[1]
	end
	return { first[1], first[2], first[3], first[4], first[5], tail }
end

local PlaybackParameter = {}
playback_parameters.PlaybackParameter = PlaybackParameter

-- Last-animation parameters execute only on Begin. Existing non-scalar
-- attributes suppress the default too: native does not reinterpret them.
-- ROBLOX: Result<(), String> -> ошибка через rt.raise.
function PlaybackParameter.update(self: PlaybackParameter, beginning: boolean, inputs: ParameterInputs, output: AttributeSink)
	local encode = name.encode
	local n, value, normalized
	local source = self.source
	if source.kind == "MotionIntent" then
		local text = source.name :: string
		n = if self.rename ~= nil then self.rename else encode(text)
		value = inputs:motion_intent(text)
		if value == nil then
			value = self.default_value
		end
		normalized = self.normalized
	elseif source.kind == "FilteredIntent" then
		local text = source.name :: string
		local found = inputs:filtered_intent(text)
		n = if self.rename ~= nil then self.rename else encode(text)
		value = if found ~= nil then found else self.default_value
		-- 82BB4908..491C goes through 4AF8 and explicitly passes 0.
		normalized = found ~= nil and self.normalized
	else
		if not beginning then
			return
		end
		local attr_name = source.attribute :: attributes.AttributeName
		local attribute, err = inputs:last_attribute(attr_name)
		if err ~= nil then
			rt.raise(err)
		end
		if attribute ~= nil then
			if attribute.kind == 0 or attribute.kind == 2 then
				local word = attribute.payload[1]
				if word == false then
					rt.raise("Last animation scalar payload is uninitialized")
				end
				value = rt.from_bits(word :: number)
			else
				return
			end
		else
			value = self.default_value
		end
		n = if self.rename ~= nil then self.rename else attr_name
		normalized = false
	end
	if value ~= nil then
		output:set_attribute({ name = n, value = value, normalized = normalized, sequence_id = -1 })
	end
end

return playback_parameters
