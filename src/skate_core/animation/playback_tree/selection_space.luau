--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/playback_tree/selection_space.rs (коммит 2e16697)
--
-- Type11's authored metric and first-update selection: 82D26CC0/82D26FF8.
-- Native construction clears transition/reselect bits. No exposed operation
-- on this tree enables them; ordinary playback therefore latches one child.
-- ROBLOX: методы дерева — через selection_space.tree (см. phase_blend).

local rt = require("../../../rt")
local attributes = require("../output/attributes")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits

local selection_space = {}
selection_space.tree = (nil :: any)

export type Parameter = { name: attributes.AttributeName, mode: number, weight: number, minimum: number, maximum: number }
export type Candidate = { name: string, values: { number }, tree: any }

-- ROBLOX: selected — индекс с нуля или nil; values: Vec<Option<f32>> -> false для None.
export type SelectionSpace = {
	parameters: { Parameter },
	candidates: { Candidate },
	selected: number?,
	values: { number | false },
	speed: number,
	requested_time: number,
}

local SelectionSpace = {}
selection_space.SelectionSpace = SelectionSpace

function SelectionSpace.new(parameters: { Parameter }, candidates: { Candidate }): SelectionSpace
	local bad = #parameters > 10 or #candidates == 0
	for _, c in candidates do
		if #c.values ~= #parameters then
			bad = true
		end
	end
	if bad then
		rt.raise("Invalid native selection space dimensions")
	end
	return { parameters = parameters, candidates = candidates, selected = nil, values = table.create(#parameters, false), speed = 1.0, requested_time = 0.0 }
end

function SelectionSpace.current(self: SelectionSpace): any?
	return if self.selected ~= nil then self.candidates[self.selected + 1].tree else nil
end
SelectionSpace.current_mut = SelectionSpace.current

function SelectionSpace.set_time(self: SelectionSpace, time: number)
	self.requested_time = time
	local c = SelectionSpace.current(self)
	if c ~= nil then
		selection_space.tree.set_time(c, time)
	end
end

function SelectionSpace.set_speed(self: SelectionSpace, speed: number)
	self.speed = speed
	local c = SelectionSpace.current(self)
	if c ~= nil then
		selection_space.tree.set_speed(c, speed)
	end
end

local function delta(parameter: Parameter, value: number, candidate: number): number
	local range = f32(parameter.maximum - parameter.minimum)
	if range > from_bits(0x37800000) then
		candidate = f32(candidate / range)
		value = f32(value / range)
	end
	if parameter.mode == 1 and value > candidate then
		return f32(f32(1.0 - value) + candidate)
	elseif parameter.mode == 2 then
		local difference = math.abs(f32(value - candidate))
		local wrapped = f32(1.0 - difference)
		return if f32(difference - wrapped) >= 0.0 then wrapped else difference
	end
	return f32(candidate - value)
end

-- Original 82D26FF8 uses two accumulators and FMA for pairs, then a separate
-- multiply/multiply/add for an odd tail. Do not reorder into a generic sum.
function selection_space.distance(parameters: { Parameter }, values: { number }, candidate: { number }): number
	local even, odd = 0.0, 0.0
	local pairs = #parameters // 2 * 2
	for i = 1, pairs, 2 do
		local d = delta(parameters[i], values[i], candidate[i])
		even = mul_add(f32(parameters[i].weight * d), d, even)
		d = delta(parameters[i + 1], values[i + 1], candidate[i + 1])
		odd = mul_add(f32(parameters[i + 1].weight * d), d, odd)
	end
	local sum = f32(odd + even)
	if pairs < #parameters then
		local i = pairs + 1
		local d = delta(parameters[i], values[i], candidate[i])
		return f32(sum + f32(f32(parameters[i].weight * d) * d))
	end
	return f32(sum + 0.0)
end

function SelectionSpace.select(self: SelectionSpace, attrs: { any })
	for _, attribute in attrs do
		for i, parameter in self.parameters do
			if attributes.name_eq(parameter.name, attribute.name) then
				self.values[i] = attribute.value
			end
		end
	end
	if self.selected == nil then
		local values = {}
		for i, v in self.values do
			if v == false then
				rt.raise(string.format("SelectionSpace parameter %d has no source producer", i - 1))
			end
			values[i] = v :: number
		end
		local best = from_bits(0x7f7fffff)
		local selected = nil
		for i, candidate in self.candidates do
			local d = selection_space.distance(self.parameters, values, candidate.values)
			if d < best then
				best = d
				selected = i
			end
		end
		if selected == nil then
			rt.raise("SelectionSpace has no finite native minimum")
		end
		-- 82D26EE4..F88 resolves the first child record with the chosen name.
		local chosen = self.candidates[selected :: number].name
		for i, c in self.candidates do
			if c.name == chosen then
				self.selected = i - 1
				break
			end
		end
	end
end

function SelectionSpace.set_attributes(self: SelectionSpace, attrs: { any }): boolean
	SelectionSpace.select(self, attrs)
	local c = SelectionSpace.current(self)
	if c ~= nil then
		selection_space.tree.set_attributes(c, attrs)
		selection_space.tree.set_speed(c, self.speed)
	end
	return true
end

return selection_space
