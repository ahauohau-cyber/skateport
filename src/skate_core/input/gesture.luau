--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/input/gesture.rs (коммит 2e16697)
--
-- TU3 pattern recognition, 82697168/826972B8/826974A8.
-- Points are supplied in PAT authoring order. Native 82696B18 pushes them
-- to the front of a ring buffer, then the matcher walks that buffer backwards.

local rt = require("../../rt")

local f32 = rt.f32
local mul_add = rt.mul_add
local fmax = rt.fmax
local fmin = rt.fmin

local gesture = {}

-- ROBLOX: points: Vec<[f32; 2]> -> таблица пар { x, y } (индексы с 1).
export type Pattern = { name: string, points: { { number } }, tolerance_squared: number }

export type Settings = {
	-- Recognizer config byte 33. Supplied by the owner, never inferred here.
	maximum_misses: number,
	difficulty: number,
}

-- ROBLOX: next — индекс точки с нуля, как в Rust.
type Node = { active: boolean, complete: boolean, next: number, elapsed: number, misses: number, distance: number }

local function node_default(): Node
	return { active = false, complete = false, next = 0, elapsed = 0, misses = 0, distance = 0.0 }
end

local function reset_node(node: Node)
	node.active = false
	node.complete = false
	node.next = 0
	node.elapsed = 0
	node.misses = 0
	node.distance = 0.0
end

local function distance_squared(a: { number }, b: { number }): number
	local x = f32(a[1] - b[1])
	local y = f32(a[2] - b[2])
	-- VMX multiplies then adds; do not contract to FMA.
	return f32(f32(x * x) + f32(y * y))
end

local function node_tick(self: Node, pattern: Pattern, sample: { number }, maximum_misses: number)
	if not self.active then
		local distance = distance_squared(pattern.points[1], sample)
		if distance <= pattern.tolerance_squared then
			reset_node(self)
			self.active = true
			self.next = 1
			self.elapsed = 1
			self.distance = distance
		end
	elseif not self.complete then
		local distance = distance_squared(pattern.points[self.next + 1], sample)
		if distance <= pattern.tolerance_squared then
			self.distance = f32(self.distance + distance)
			self.elapsed = bit32.band(self.elapsed + 1, 0x3ff)
			if self.next + 1 == #pattern.points then
				self.complete = true
			else
				self.next += 1
				self.misses = 0
			end
		else
			-- Holding the first point does not age a pending gesture.
			if self.next ~= 1 or distance_squared(pattern.points[1], sample) > pattern.tolerance_squared then
				self.elapsed = bit32.band(self.elapsed + 1, 0x3ff)
				self.misses = bit32.band(self.misses + 1, 0x3f)
			end
			if self.misses > maximum_misses then
				reset_node(self)
			end
		end
	end
end

local F015 = f32(0.15)

local function node_score(self: Node, count_: number): number
	local count = f32(count_)
	-- The unusual two-sided 0.15 operation is present in 826972B8.
	local mean = fmin(f32(fmax(self.distance, F015) / count), F015)
	return f32(f32(f32(f32(count * count) * count) * count) / f32(mean * self.elapsed))
end

export type Recognition = { pattern: number, strength: number, distance: number, elapsed: number }

-- ROBLOX: held: Option<usize> -> индекс с нуля или nil.
export type Recognizer = {
	patterns: { Pattern },
	nodes: { Node },
	has_previous_sample: boolean,
	refractory: boolean,
	held: number?,
}

local Recognizer = {}
gesture.Recognizer = Recognizer

-- ROBLOX: Result<Self, String> -> ошибка через rt.raise (ловится rt.catch).
function Recognizer.new(patterns: { Pattern }): Recognizer
	for _, pattern in patterns do
		local bad = #pattern.points < 2 or #pattern.points > 15 or not rt.is_finite(pattern.tolerance_squared) or pattern.tolerance_squared < 0.0
		if not bad then
			for _, point in pattern.points do
				if not rt.is_finite(point[1]) or not rt.is_finite(point[2]) then
					bad = true
				end
			end
		end
		if bad then
			rt.raise("invalid native gesture pattern " .. pattern.name)
		end
	end
	local nodes = {}
	for i = 1, #patterns do
		nodes[i] = node_default()
	end
	return { nodes = nodes, patterns = patterns, has_previous_sample = false, refractory = false, held = nil }
end

function Recognizer.patterns(self: Recognizer): { Pattern }
	return self.patterns
end

-- Held messages are checked before recognition in 826962D8. Native point
-- zero is the final authored coordinate (82699738 push-front).
function Recognizer.held(self: Recognizer, sample: { number }): number?
	local index = self.held
	if index ~= nil then
		local pattern = self.patterns[index + 1]
		if distance_squared(pattern.points[#pattern.points], sample) > pattern.tolerance_squared then
			self.held = nil
		end
	end
	return self.held
end

local LOW_2, HIGH_2 = f32(1.5), f32(3.0)
local LOW, HIGH = f32(1.75), f32(4.4)

function Recognizer.sample(self: Recognizer, sample: { number }, settings: Settings): Recognition?
	if self.refractory then
		for _, node in self.nodes do
			reset_node(node)
		end
		self.refractory = false
		return nil
	end
	if not self.has_previous_sample then
		self.has_previous_sample = true
		return nil
	end
	local best: number? = nil
	for i, node in self.nodes do
		node_tick(node, self.patterns[i], sample, settings.maximum_misses)
	end
	for i, node in self.nodes do
		local index = i - 1
		if node.complete then
			local old = best
			if old == nil or node_score(node, #self.patterns[i].points) > node_score(self.nodes[old + 1], #self.patterns[old + 1].points) then
				best = index
			end
		end
	end
	local pattern = best
	if pattern == nil then
		return nil
	end
	local node = table.clone(self.nodes[pattern + 1])
	local ratio = f32(f32(node.elapsed) / f32(#self.patterns[pattern + 1].points))
	-- 822249B4/82063B08 and 821E63E8/821E63EC, checked against TU3.
	local low, high
	if settings.difficulty == 2 then
		low, high = LOW_2, HIGH_2
	else
		low, high = LOW, HIGH
	end
	local strength
	if ratio <= low then
		strength = 1.0
	elseif ratio >= high then
		strength = 0.0
	else
		local slope = f32(1.0 / f32(low - high))
		strength = mul_add(slope, ratio, -f32(slope * high))
	end
	self.refractory = true
	self.held = pattern
	return { pattern = pattern, strength = strength, distance = node.distance, elapsed = f32(node.elapsed) }
end

return gesture
