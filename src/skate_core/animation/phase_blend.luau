--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/phase_blend.rs (коммит 2e16697)
--
-- Andale PhaseBlend, TU3 82D24C40..82D25808; construction 82D1B67C.
--
-- ROBLOX: phase_blend и playback_tree ссылаются друг на друга. В Luau цикл
-- require запрещён, поэтому методы дерева берутся через phase_blend.tree,
-- который заполняет playback_tree при загрузке.

local rt = require("../../rt")
local attributes = require("./output/attributes")
local playback_attributes = require("./playback_attributes")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits

local phase_blend = {}
phase_blend.tree = (nil :: any)

-- ROBLOX: order — индексы детей с нуля, как в Rust (children[i + 1]).
export type PhaseBlend = {
	parameter: attributes.AttributeName,
	children: { any },
	order: { number },
	values: { number },
	left: number,
	right: number,
	weight: number,
	parameter_value: number,
	normalized: boolean,
	cull_threshold: number,
	length: number,
	time: number,
}

local PhaseBlend = {}
phase_blend.PhaseBlend = PhaseBlend

local F32_MAX = from_bits(0x7f7fffff)

local function child(self: PhaseBlend, i: number): any
	return self.children[i + 1]
end

-- ROBLOX: Result<Self, String> -> значение или rt.raise.
function PhaseBlend.new(parameter: attributes.AttributeName, children: { any }): PhaseBlend
	if #children < 2 then
		rt.raise("PhaseBlend requires at least two authored children")
	end
	local count = #children
	local order, values = {}, {}
	for i = 0, count - 1 do
		order[i + 1] = i
		values[i + 1] = 0.0
	end
	return {
		parameter = parameter,
		length = phase_blend.tree.length(children[1]),
		children = children,
		order = order,
		values = values,
		left = 0,
		right = 1,
		weight = 0.0,
		parameter_value = F32_MAX,
		normalized = true,
		cull_threshold = 0.0,
		time = 0.0,
	}
end

function PhaseBlend.set_time(self: PhaseBlend, time: number)
	local T = phase_blend.tree
	local phase = f32(time / self.length)
	local left_time = f32(T.length(child(self, self.left)) * phase)
	local right_time = f32(T.length(child(self, self.right)) * phase)
	T.set_time(child(self, self.left), left_time)
	T.set_time(child(self, self.right), right_time)
	self.time = time
end

local function phase(self: PhaseBlend): number
	return f32(self.time / (if -self.length >= 0.0 then 1.0 else self.length))
end

local function update_length(self: PhaseBlend, p: number)
	local T = phase_blend.tree
	self.length = mul_add(T.length(child(self, self.right)), self.weight, f32(T.length(child(self, self.left)) * f32(1.0 - self.weight)))
	PhaseBlend.set_time(self, f32(self.length * p))
end

function PhaseBlend.set_speed(self: PhaseBlend, speed: number)
	local p = phase(self)
	for _, index in self.order do
		phase_blend.tree.set_speed(child(self, index), speed)
	end
	update_length(self, p)
end

function PhaseBlend.advance(self: PhaseBlend, dt: number, phase_value: number, property: any)
	local T = phase_blend.tree
	local left_length = T.length(child(self, self.left))
	local right_length = T.length(child(self, self.right))
	local fraction = f32(dt / self.length)
	T.advance(child(self, self.left), f32(fraction * left_length), phase_value, property)
	local discarded = { crossed_end = false, overshoot = -1.0, remaining_before_wrap = -1.0 }
	T.advance(child(self, self.right), f32(fraction * right_length), phase_value, discarded)
	local inverse_left = f32(1.0 / left_length)
	self.time = f32(f32(T.time(child(self, self.left)) * inverse_left) * self.length)
	property.remaining_before_wrap = f32(f32(property.remaining_before_wrap * inverse_left) * self.length)
	property.overshoot = f32(f32(inverse_left * self.length) * property.overshoot)
end

local K_38d1b717 = from_bits(0x38d1b717)

function PhaseBlend.set_attributes(self: PhaseBlend, attrs: { any }): boolean
	local T = phase_blend.tree
	local changed = false
	for _, index in self.order do
		changed = T.set_attributes(child(self, index), attrs) or changed
	end
	for _, attribute in attrs do
		if attributes.name_eq(attribute.name, self.parameter) then
			if attribute.normalized ~= self.normalized or not (math.abs(f32(attribute.value - self.parameter_value)) < K_38d1b717) then
				self.parameter_value = attribute.value
				self.normalized = attribute.normalized
				changed = true
			end
			break
		end
	end
	if not changed then
		return false
	end
	for _, index in self.order do
		local attribute = attributes.MotionGraphAttribute.to_animation({ name = self.parameter, value = 0.0 })
		-- Native deliberately ignores success; partial output from nested
		-- GetAttribute remains visible, and a complete miss retains zero.
		T.query_attribute(child(self, index), self.parameter, 15, attribute)
		local w = attribute.payload[1]
		if w == false then
			rt.raise("Uninitialized PhaseBlend parameter")
		end
		self.values[index + 1] = from_bits(w :: number)
	end
	local order, values = self.order, self.values
	for end_ = #order - 1, 1, -1 do
		for i = 0, end_ - 1 do
			if values[order[i + 2] + 1] < values[order[i + 1] + 1] then
				order[i + 1], order[i + 2] = order[i + 2], order[i + 1]
			end
		end
	end
	local minimum = values[order[1] + 1]
	local maximum = values[order[#order] + 1]
	local target = if self.normalized then mul_add(f32(maximum - minimum), self.parameter_value, minimum) else self.parameter_value
	local low = 0
	local count = #order
	while count ~= 0 do
		local step = count // 2
		local middle = low + step
		if values[order[middle + 1] + 1] < target then
			low = middle + 1
			count -= step + 1
		else
			count = step
		end
	end
	local upper = math.clamp(low, 1, #order - 1)
	local left = order[upper]
	local right = order[upper + 1]
	local lower_value = values[left + 1]
	local upper_value = values[right + 1]
	local delta = f32(upper_value - lower_value)
	local lower = if f32(lower_value - target) >= 0.0 then lower_value else target
	local clamped = if f32(upper_value - lower) >= 0.0 then lower else upper_value
	local weight = f32(f32(clamped - lower_value) / (if delta == 0.0 then 1.0 else delta))
	local lw = if -weight >= 0.0 then 0.0 else weight
	self.weight = if f32(1.0 - lw) >= 0.0 then lw else 1.0
	local p = phase(self)
	self.left = left
	self.right = right
	update_length(self, p)
	return true
end

function PhaseBlend.attributes(self: PhaseBlend, mask: number): { any }
	local T = phase_blend.tree
	if self.weight < self.cull_threshold then
		return T.attributes(child(self, self.left), mask)
	end
	if self.weight > f32(1.0 - self.cull_threshold) then
		return T.attributes(child(self, self.right), mask)
	end
	return playback_attributes.intersection(T.attributes(child(self, self.left), mask), T.attributes(child(self, self.right), 31), self.weight)
end

function PhaseBlend.query_attribute(self: PhaseBlend, name: attributes.AttributeName, mask: number, output: any): boolean
	local T = phase_blend.tree
	if self.weight < self.cull_threshold then
		return T.query_attribute(child(self, self.left), name, mask, output)
	end
	if self.weight > f32(1.0 - self.cull_threshold) then
		return T.query_attribute(child(self, self.right), name, mask, output)
	end
	local left = T.query_attribute(child(self, self.left), name, mask, output)
	local right = attributes.MotionGraphAttribute.to_animation({ name = name, value = 0.0 })
	local found_right = T.query_attribute(child(self, self.right), name, 31, right)
	if left and found_right then
		playback_attributes.blend(output, right, self.weight)
		return true
	end
	return false
end

function PhaseBlend.evaluate(self: PhaseBlend, parameters: any, enabled: boolean, output: { any }): boolean
	local T = phase_blend.tree
	self.cull_threshold = parameters.cull_threshold
	local c = parameters.cull_threshold
	local lower = if f32(c - self.weight) >= 0.0 then c else self.weight
	local upper = f32(1.0 - c)
	local clamped = if f32(upper - lower) >= 0.0 then lower else upper
	local t = f32(f32(clamped - c) / mul_add(-c, 2.0, 1.0))
	local square = f32(t * t)
	local weight
	if not (t > 0.5) and self.left == self.order[1] then
		weight = f32(mul_add(-t, 4.0, 4.0) * square)
	elseif t > 0.5 and self.right == self.order[#self.order] then
		local four = f32(t * 4.0)
		weight = f32(mul_add(f32(8.0 - four), square, -four) + 1.0)
	else
		weight = self.weight
	end
	local left = T.evaluate(child(self, self.left), parameters, enabled and weight < 1.0, output)
	local right = T.evaluate(child(self, self.right), parameters, enabled and weight > 0.0, output)
	if left and right then
		table.insert(output, { kind = "Blend", weight = weight })
	end
	return left or right
end

return phase_blend
