--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/playback_tree/blend_space.rs (коммит 2e16697)
--
-- Andale BlendSpace 82D22DA0..82D24B90. Authored simplex planes, original
-- scalar selection 82D23A50 and phase-coupled child clocks; no fitted metric.
-- ROBLOX: методы дерева — через blend_space.tree (см. phase_blend).

local rt = require("../../../rt")
local attributes = require("../output/attributes")
local playback_attributes = require("../playback_attributes")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits

local blend_space = {}
blend_space.tree = (nil :: any)

-- ROBLOX: children — индексы детей с нуля.
export type Simplex = { children: { number }, vertices: { { number } }, normals: { { number } }, scales: { number } }

local Simplex = {}
blend_space.Simplex = Simplex

-- 82D23898: signed distances to the opposite planes, scaled by inverse height.
function Simplex.coordinates(self: Simplex, point: { number }): { number }
	local n = #self.children
	local out = {}
	for i = 0, n - 1 do
		local anchor = self.vertices[(i + 1) % n + 1]
		local normal = self.normals[i + 1]
		local even, odd = 0.0, 0.0
		local pairs = #point // 2
		for j = 0, pairs - 1 do
			even = mul_add(normal[j * 2 + 1], f32(point[j * 2 + 1] - anchor[j * 2 + 1]), even)
			odd = mul_add(normal[j * 2 + 2], f32(point[j * 2 + 2] - anchor[j * 2 + 2]), odd)
		end
		local dot = f32(even + odd)
		if #point % 2 ~= 0 then
			local j = #point
			dot = f32(dot + f32(normal[j] * f32(point[j] - anchor[j])))
		end
		out[i + 1] = f32(dot * self.scales[i + 1])
	end
	return out
end

local K_3727c5ac = from_bits(0x3727c5ac)
local F32_MAX = from_bits(0x7f7fffff)

local function tail(row: { number }): { number }
	return table.move(row, 2, #row, 1, {})
end

-- 82D23530/82D23080: successive coordinate-plane slices, retaining edge
-- enumeration order. On an empty slice choose its nearest remaining vertex.
function Simplex.project(self: Simplex, point: { number }): { number }
	local matrix = {}
	for i, v in self.vertices do
		matrix[i] = table.clone(v)
	end
	local projected = {}
	for _, target in point do
		local count = #matrix - 1
		local sliced: { { number } } = {}
		local stop = false
		for i = 1, count do
			for j = i + 1, #matrix do
				if #sliced == count then
					stop = true
					break
				end
				local a, b = matrix[i], matrix[j]
				if (a[1] < target) ~= (b[1] < target) then
					local delta = f32(b[1] - a[1])
					if math.abs(delta) <= K_3727c5ac then
						-- 8219B100
						table.insert(sliced, tail(a))
						if #sliced < count then
							table.insert(sliced, tail(b))
						end
					else
						local t = f32(f32(target - a[1]) / delta)
						local row = {}
						for k = 2, #a do
							row[k - 1] = mul_add(f32(b[k] - a[k]), t, a[k])
						end
						table.insert(sliced, row)
					end
				end
			end
			if stop then
				break
			end
		end
		if #sliced == 0 then
			local nearest = 1
			local distance = F32_MAX
			for i, row in matrix do
				local d = f32(f32(row[1] - target) * f32(row[1] - target))
				if d < distance then
					distance = d
					nearest = i
				end
			end
			for _, v in matrix[nearest] do
				table.insert(projected, v)
			end
			break
		end
		table.insert(projected, target)
		while #sliced < count do
			table.insert(sliced, table.clone(sliced[#sliced]))
		end
		matrix = sliced
	end
	return projected
end

export type BlendSpace = {
	parameters: { attributes.AttributeName },
	children: { any },
	simplexes: { Simplex },
	values: { number },
	current: number,
	weights: { number },
	time: number,
}

local BlendSpace = {}
blend_space.BlendSpace = BlendSpace

local function finite(v: number): boolean
	return rt.is_finite(v)
end

function BlendSpace.new(parameters: { attributes.AttributeName }, children: { any }, simplexes: { Simplex }): BlendSpace
	local d = #parameters
	local bad = d == 0 or d > 4 or #children < d + 1 or #simplexes == 0
	if not bad then
		for _, s in simplexes do
			if #s.children ~= d + 1 or #s.vertices ~= d + 1 or #s.normals ~= d + 1 or #s.scales ~= d + 1 then
				bad = true
			end
			for _, i in s.children do
				if i >= #children then
					bad = true
				end
			end
			for _, list in { s.vertices, s.normals } do
				for _, v in list do
					if #v ~= d then
						bad = true
					end
					for _, x in v do
						if not finite(x) then
							bad = true
						end
					end
				end
			end
			for _, x in s.scales do
				if not finite(x) then
					bad = true
				end
			end
		end
	end
	if bad then
		rt.raise("Invalid authored BlendSpace topology")
	end
	local weights = table.create(d + 1, 0.0)
	weights[1] = 1.0
	return { parameters = parameters, children = children, simplexes = simplexes, values = table.create(d, 0.0), current = 0, weights = weights, time = 0.0 }
end

local function active(self: BlendSpace): Simplex
	return self.simplexes[self.current + 1]
end

-- ROBLOX: active_weights -> таблица пар { индекс ребёнка, вес }.
function BlendSpace.active_weights(self: BlendSpace): { { number } }
	local out = {}
	for slot, i in active(self).children do
		table.insert(out, { i, self.weights[slot] })
	end
	return out
end

function BlendSpace.length(self: BlendSpace): number
	local sum = 0.0
	for _, pair in BlendSpace.active_weights(self) do
		sum = mul_add(pair[2], blend_space.tree.length(self.children[pair[1] + 1]), sum)
	end
	return sum
end

function BlendSpace.set_time(self: BlendSpace, time: number)
	local T = blend_space.tree
	local phase = f32(time / BlendSpace.length(self))
	for _, i in active(self).children do
		local c = self.children[i + 1]
		T.set_time(c, f32(phase * T.length(c)))
	end
	-- 82D24AB0 updates child clocks; the cached time is written by Advance.
end

function BlendSpace.set_speed(self: BlendSpace, speed: number)
	for _, c in self.children do
		blend_space.tree.set_speed(c, speed)
	end
end

function BlendSpace.advance(self: BlendSpace, dt: number, phase: number, property: any)
	local T = blend_space.tree
	local length = BlendSpace.length(self)
	local indices = active(self).children
	local first = indices[1]
	local first_length = T.length(self.children[first + 1])
	for slot, i in indices do
		local c = self.children[i + 1]
		local result = { crossed_end = false, overshoot = -1.0, remaining_before_wrap = -1.0 }
		T.advance(c, f32(f32(T.length(c) * f32(1.0 / length)) * dt), phase, result)
		if slot == 1 then
			property.crossed_end = result.crossed_end
			property.overshoot = result.overshoot
			property.remaining_before_wrap = result.remaining_before_wrap
		end
	end
	local scale = f32(length / first_length)
	property.overshoot = f32(property.overshoot * scale)
	property.remaining_before_wrap = f32(property.remaining_before_wrap * scale)
	self.time = f32(T.time(self.children[first + 1]) * scale)
end

local function normalize(weights: { number })
	local sum = 0.0
	for _, w in weights do
		sum = f32(sum + w)
	end
	if not finite(sum) or sum <= 0.0 then
		rt.raise("Degenerate BlendSpace weights")
	end
	local inverse = f32(1.0 / sum)
	for i, w in weights do
		weights[i] = f32(w * inverse)
	end
end

function BlendSpace.set_attributes(self: BlendSpace, attrs: { any }): boolean
	local T = blend_space.tree
	local changed = false
	for _, attribute in attrs do
		for i, n in self.parameters do
			if attributes.name_eq(n, attribute.name) then
				if not finite(attribute.value) then
					rt.raise("Nonfinite BlendSpace parameter")
				end
				self.values[i] = attribute.value
				changed = true
				break
			end
		end
	end
	if not changed then
		return false
	end
	local selected_index, selected_weights = nil, nil
	local closest = F32_MAX
	for index, simplex in self.simplexes do
		local weights = Simplex.coordinates(simplex, self.values)
		local all = true
		for _, w in weights do
			if not (w >= 0.0) then
				all = false
			end
		end
		if all then
			selected_index, selected_weights = index, weights
			break
		end
		weights = Simplex.coordinates(simplex, Simplex.project(simplex, self.values))
		for k, w in weights do
			if w < 0.0 then
				weights[k] = 0.0
			end
		end
		normalize(weights)
		local distance = 0.0
		for j, target in self.values do
			local projected = 0.0
			for k, v in simplex.vertices do
				projected = mul_add(v[j], weights[k], projected)
			end
			distance = mul_add(f32(projected - target), f32(projected - target), distance)
		end
		if distance < closest then
			closest = distance
			selected_index, selected_weights = index, weights
		end
	end
	if selected_index == nil then
		rt.raise("BlendSpace has no finite projection")
	end
	local weights = selected_weights :: { number }
	for k, w in weights do
		weights[k] = rt.fclamp(w, 0.0, 1.0)
	end
	normalize(weights)
	local index = (selected_index :: number) - 1
	if index ~= self.current then
		local old = self.children[active(self).children[1] + 1]
		local phase = f32(T.time(old) / T.length(old))
		for _, i in self.simplexes[index + 1].children do
			local c = self.children[i + 1]
			T.set_time(c, f32(phase * T.length(c)))
		end
		self.current = index
	end
	self.weights = weights
	return true
end

local function less(a: { number }, b: { number }): boolean
	for i = 1, 5 do
		if a[i] ~= b[i] then
			return a[i] < b[i]
		end
	end
	return false
end

function BlendSpace.attributes(self: BlendSpace, mask: number): { any }
	local T = blend_space.tree
	local indices = active(self).children
	local output = T.attributes(self.children[indices[1] + 1], mask)
	for _, a in output do
		playback_attributes.scale(a, self.weights[1])
	end
	for slot = 2, #indices do
		local right = T.attributes(self.children[indices[slot] + 1], mask)
		local next_ = 1
		local combined = {}
		for _, a in output do
			while next_ <= #right and less(right[next_].name, a.name) do
				next_ += 1
			end
			local b = right[next_]
			if b ~= nil and attributes.name_eq(b.name, a.name) then
				playback_attributes.add_weighted(a, b, self.weights[slot])
				table.insert(combined, a)
			end
		end
		output = combined
	end
	return output
end

function BlendSpace.query_attribute(self: BlendSpace, name: attributes.AttributeName, mask: number, output: any): boolean
	local T = blend_space.tree
	-- 82D24580 indexes the first d+1 authored children directly (unlike
	-- GetAttributes, which follows the active simplex). Preserve that distinction.
	if not T.query_attribute(self.children[1], name, mask, output) then
		return false
	end
	playback_attributes.scale(output, self.weights[1])
	for i = 2, #self.weights do
		local right = attributes.MotionGraphAttribute.to_animation({ name = name, value = 0.0 })
		if not T.query_attribute(self.children[i], name, 15, right) then
			return false
		end
		playback_attributes.add_weighted(output, right, self.weights[i])
	end
	return true
end

function BlendSpace.evaluate(self: BlendSpace, parameters: any, enabled: boolean, output: { any }): boolean
	if not enabled then
		return false
	end
	for _, i in active(self).children do
		if not blend_space.tree.evaluate(self.children[i + 1], parameters, true, output) then
			rt.raise("BlendSpace child produced no pose")
		end
	end
	table.insert(output, { kind = "WeightedBlend", weights = table.clone(self.weights) })
	return true
end

return blend_space
