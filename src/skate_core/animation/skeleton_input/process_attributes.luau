--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/skeleton_input/process_attributes.rs (коммит 2e16697)
--
-- Full ordered Skeleton::ProcessAnimAttributes dispatch 82BDA0D0. The game
-- supplies actual stock settings, pose and input map, and retains owned state.

local rt = require("../../../rt")
local attribute_finalization = require("./attribute_finalization")
local catalog = require("./catalog")
local contact_events = require("./contact_events")
local extended_attributes = require("./extended_attributes")
local scalar_attributes = require("./scalar_attributes")

local from_bits = rt.from_bits
local Accumulator = attribute_finalization.Accumulator

local process_attributes = {}

local function describe(e: any): string
	if type(e) == "table" then
		return tostring(e.kind)
	end
	return tostring(e)
end

-- ROBLOX: Result<(), String> -> rt.raise(строка); input_map — ActionMap или nil.
function process_attributes.process(attributes: { any }, pose: contact_events.ContactEventPose, fields: scalar_attributes.ScalarAttributeInputs, extra: extended_attributes.ExtendedAttributes, contacts: contact_events.ContactEventState, cached_jump: attribute_finalization.JumpAttributeState, output: scalar_attributes.AnimationControlOutput, finalization: attribute_finalization.FinalizationInput, input_map: any?)
	local accumulator = Accumulator.new()
	for index, attribute in attributes do
		local function step()
			if attribute.kind == 3 then
				contact_events.dispatch(attribute, pose, fields, contacts)
				return
			end
			local _, err = rt.catch(scalar_attributes.dispatch_attribute, attribute, fields, output)
			if err == nil then
				return
			elseif err.kind ~= "KnownScalarUnavailable" then
				rt.raise("Invalid scalar payload: " .. describe(err))
			end
			local name = (catalog.lookup(attribute.name) :: any).name
			local function scalar(): number
				local w = attribute.payload[1]
				if w == false or w == nil then
					rt.raise(name .. ": scalar payload absent")
				end
				return from_bits(w)
			end
			if Accumulator.dispatch(accumulator, name, scalar, fields, cached_jump, input_map) or extended_attributes.dispatch(name, scalar, fields, extra, output) then
				return
			end
			rt.raise("Unimplemented known Skeleton attribute " .. name)
		end
		local _, err = rt.catch(step)
		if err ~= nil then
			rt.raise(string.format("Skeleton attribute%d: %s", index - 1, tostring(err)))
		end
	end
	Accumulator.finish(accumulator, fields, extra, cached_jump, finalization, input_map)
end

return process_attributes
