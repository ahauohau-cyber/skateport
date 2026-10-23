--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/input/turn_conditioner.rs (коммит 2e16697)
--
-- Complete steering conditioner 82DEFF38, called by 82DEFB30.
-- The settings decoder supplies global 830CFDA4 slot 204's verified layout.

local rt = require("../../rt")
local point_graph = require("../point_graph")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local evaluate = point_graph.PointGraph.evaluate

local turn_conditioner = {}

export type Settings = {
	-- Layout 688/704/720, corresponding to conditioner 216/180/144.
	filter_coefficients: { { number } },
	-- Layout x304/y336, x240/y272, x32/y64, x384/y400.
	input_curve: point_graph.PointGraph,
	quickness_curve: point_graph.PointGraph,
	speed_curve: point_graph.PointGraph,
	smoothing_curve: point_graph.PointGraph,
	-- Layout 768,868,872,896,900,904,908,912,924,928,932,936,940.
	-- ROBLOX: [f32; 13] -> таблица, p[k] в Rust -> parameters[k + 1].
	parameters: { number },
}

export type State = {
	-- Conditioner 112..140, in native order.
	history: { number },
	-- Complete 9-word filters at 216,180,144; first 4 words refresh every call.
	filters: { { number } },
}

local State = {}
turn_conditioner.State = State

-- Steering-history portion of native reset 82DEFAA0. Cached coefficients
-- survive reset; the update refreshes them from the settings layout.
function State.reset_history(self: State)
	for i = 1, 8 do
		self.history[i] = 0.0
	end
	for _, filter in self.filters do
		for i = 5, 9 do
			filter[i] = 0.0
		end
	end
end

export type Input = {
	body_160: number,
	body_176: number,
	bundle_36_field_160: number,
	bundle_32_field_264: number,
	animation_152: number,
	animation_156: number,
}

-- PhysOut_Animation 32/36/40/44/48/52/56/60, in native memory order.
export type Output = { number }

local function clamp(value: number, low: number, high: number): number
	value = if f32(low - value) >= 0.0 then low else value
	return if f32(high - value) >= 0.0 then value else high
end

-- ROBLOX: state[k] в Rust -> s[k + 1].
local function filter(s: { number }, coefficients: { number }, input: number): number
	for i = 1, 4 do
		s[i] = coefficients[i]
	end
	local difference = f32(input - s[5])
	local input_difference = f32(input - s[6])
	local complement = f32(1.0 - s[4])
	s[6] = input
	s[9] = mul_add(input_difference, s[4], f32(s[9] * complement))
	s[7] = mul_add(difference, s[4], f32(complement * s[7]))
	local term = mul_add(f32(s[9] - s[8]), s[3], f32(s[2] * s[7]))
	term = mul_add(difference, s[1], term)
	local result = f32(term + s[5])
	s[8] = f32(result - s[5])
	s[5] = result
	return result
end

local EPSILON = from_bits(0x3c23d70a)

function turn_conditioner.update(state: State, input: Input, settings: Settings): Output
	local q = settings.parameters
	local function p(k: number): number
		return q[k + 1]
	end
	local h = state.history -- ROBLOX: history[k] -> h[k + 1]
	local sign = if input.animation_156 ~= 0 then -1.0 else 1.0
	local scaled = f32(input.bundle_32_field_264 * sign)
	local speed_fraction = clamp(f32(input.body_160 / p(11)), 0.0, 1.0)
	local other_fraction = clamp(f32(f32(input.bundle_36_field_160 / p(10)) * sign), -1.0, 1.0)
	local base = f32(evaluate(settings.input_curve, speed_fraction) * scaled)
	local attenuated = f32(mul_add(-f32(1.0 - p(8)), input.body_176, 1.0) * other_fraction)
	local target = mul_add(attenuated, p(9), f32(f32(1.0 - p(9)) * base))
	local first = filter(state.filters[1], settings.filter_coefficients[1], target)
	first = if math.abs(first) > EPSILON then first else 0.0
	local second = filter(state.filters[2], settings.filter_coefficients[2], target)
	second = if math.abs(second) > EPSILON then second else 0.0
	local third = filter(state.filters[3], settings.filter_coefficients[3], f32(f32(target - second) / p(12)))
	local movement = if input.animation_152 ~= 0 then scaled else 0.0
	local difference = f32(movement - h[1])
	h[1] = movement
	h[3] = mul_add(math.abs(difference), p(2), f32(f32(1.0 - p(2)) * h[3]))
	local ratio = f32(h[3] / p(1))
	local squared = f32(ratio * ratio)
	local bounded = if f32(squared - 1.0) >= 0.0 then 1.0 else squared
	h[4] = clamp(bounded, f32(h[4] - p(0)), f32(h[4] + p(0)))
	local quick = evaluate(settings.quickness_curve, h[4])
	quick = clamp(quick, 0.0, 1.0)
	quick = f32(evaluate(settings.speed_curve, input.body_160) * quick)
	movement = if input.animation_152 ~= 0 then second else 0.0
	difference = f32(movement - h[2])
	h[2] = movement
	h[6] = mul_add(math.abs(difference), p(5), f32(f32(1.0 - p(5)) * h[6]))
	local hold = if h[6] < p(3) then 1.0 else 0.0
	local alpha = mul_add(f32(1.0 - hold), p(7), f32(p(6) * hold))
	local next_ = mul_add(f32(1.0 - alpha), h[5], f32(alpha * hold))
	difference = f32(next_ - h[5])
	h[7] = clamp(difference, f32(h[7] - p(4)), f32(h[7] + p(4)))
	h[5] = clamp(f32(h[5] + h[7]), 0.0, 1.0)
	alpha = evaluate(settings.smoothing_curve, input.body_176)
	h[8] = mul_add(f32(1.0 - alpha), h[8], f32(alpha * first))
	local turn = clamp(h[8], -1.0, 1.0)
	return {
		turn,
		clamp(target, -1.0, 1.0),
		base,
		f32(turn * sign),
		f32(base * sign),
		quick,
		clamp(third, -1.0, 1.0),
		clamp(h[5], 0.0, 1.0),
	}
end

return turn_conditioner
