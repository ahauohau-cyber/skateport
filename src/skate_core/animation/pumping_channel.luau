--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/pumping_channel.rs (коммит 2e16697)
--
-- Pumping behavior 82BAC1B0 and instance seeds 82BAC528.

local rt = require("../../rt")
local point_graph = require("../point_graph")

local f32 = rt.f32
local mul_add = rt.mul_add

local pumping_channel = {}

export type Settings = {
	amplify: point_graph.PointGraph,
	input_blend: number,
	maximum_physics_pump: number,
	new_pump_threshold: number,
	blend_in: number,
	blend_out: number,
}

-- ROBLOX: channel — индекс канала с нуля или nil.
export type State = { value: number, filtered: number, channel: number?, peak: number }

-- ROBLOX: influence: Option<(usize, f32)> -> { канал, значение } или nil.
export type Update = { start: number?, influence: { number }? }

local State = {}
pumping_channel.State = State

function State.default(): State
	return { value = 0.0, filtered = 0.0, channel = nil, peak = 0.0 }
end

function State.update(self: State, physics_pump: number, occupied: { boolean }, s: Settings): Update
	local previous = self.value
	local input = f32(physics_pump / s.maximum_physics_pump)
	local lower = if -input >= 0.0 then 0.0 else input
	input = if f32(1.0 - lower) >= 0.0 then lower else 1.0
	-- 82BAC2F8 is fmadds; preserve the single final rounding.
	self.filtered = mul_add(input, s.input_blend, f32(f32(1.0 - s.input_blend) * self.filtered))
	self.value = point_graph.PointGraph.evaluate(s.amplify, self.filtered)
	local start = nil
	if not (previous > s.new_pump_threshold) and self.value > s.new_pump_threshold then
		for i, exists in occupied do
			if not exists then
				start = i - 1
				break
			end
		end
	end
	if start ~= nil then
		self.channel = start
		self.peak = self.value
	end
	local influence = nil
	if self.value >= previous and self.value >= self.peak and self.channel ~= nil then
		self.peak = self.value
		influence = { self.channel :: number, self.value }
	end
	return { start = start, influence = influence }
end

return pumping_channel
