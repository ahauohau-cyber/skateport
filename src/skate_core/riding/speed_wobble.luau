--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/riding/speed_wobble.rs (коммит 2e16697)
--
-- Complete TU3 SpeedWobble::CalculateSpeedWobble (82C0DBE8).
-- UpdateSpeedWobble 82C03638 supplies the selected-mode attributes and body
-- inputs; Ground Update 82D38800 applies the returned tilt before truck targets.

local rt = require("../../rt")
local point_graph = require("../point_graph")
local trigonometry = require("../trigonometry")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local to_bits = rt.to_bits
local PointGraph = point_graph.PointGraph

local speed_wobble = {}

export type SpeedWobbleSettings = {
	-- Layout arrays +0/+32, +64/+96, +128/+160, +192/+224.
	frequency_time: point_graph.PointGraph,
	frequency_speed: point_graph.PointGraph,
	amplitude_time: point_graph.PointGraph,
	amplitude_speed: point_graph.PointGraph,
	-- Layout +256 through +284, in native order.
	tightness_threshold: number,
	time_range: number,
	speed_range: number,
	frequency_scale: number,
	amplitude_scale: number,
	crouch_threshold: number,
	height_min: number,
	height_max: number,
}

-- Fields +16..+44, including untouched +20 and opaque/reset-only +24/+28.
-- The active flag is a byte; retain its other three packed bytes.
-- ROBLOX: SpeedWobbleState(pub [u32; 8]) -> { words = {8 слов} }, слово k в [k + 1].
export type SpeedWobbleState = { words: { number } }

local SpeedWobbleState = {}
speed_wobble.SpeedWobbleState = SpeedWobbleState

function SpeedWobbleState.new(words: { number }?): SpeedWobbleState
	return { words = if words then table.clone(words) else rt.zeros(8) }
end

-- The same six-float/one-byte reset used in Ground Enter 82D376D0.
function SpeedWobbleState.reset(self: SpeedWobbleState)
	for _, index in { 0, 2, 3, 4, 5, 6 } do
		self.words[index + 1] = 0
	end
	self.words[8] = bit32.band(self.words[8], 0x00ff_ffff)
end

local function active(self: SpeedWobbleState): boolean
	return bit32.rshift(self.words[8], 24) ~= 0
end

export type SpeedWobbleInput = {
	tilt: number,
	-- Signed speed, ProcessedPhysIn +2612. This routine does not take abs().
	speed: number,
	center_of_mass_height: number,
	truck_tightness: number,
	-- Resolved mode Hash_77AFCE78FE1206CA / Hash_5B57F2CCCCEEF430.
	activation_threshold: number,
	amplitude_multiplier: number,
}

local function unit(value: number): number
	local lower = if -value >= 0.0 then 0.0 else value
	return if f32(1.0 - lower) >= 0.0 then lower else 1.0
end

function speed_wobble.calculate(state: SpeedWobbleState, settings: SpeedWobbleSettings, input: SpeedWobbleInput): number
	local height = f32(f32(input.center_of_mass_height - settings.height_min) / f32(settings.height_max - settings.height_min))
	local crouch = unit(f32(1.0 - height))
	local threshold = f32(mul_add(crouch, settings.crouch_threshold, f32(settings.tightness_threshold * input.truck_tightness)) + input.activation_threshold)
	if not active(state) and input.speed > threshold then
		SpeedWobbleState.reset(state)
		state.words[8] = bit32.bor(state.words[8], 0x0100_0000)
	end
	if not active(state) then
		return input.tilt
	end

	local time = from_bits(state.words[1])
	local time_fraction = unit(f32(time / settings.time_range))
	local speed_fraction = unit(f32(f32(input.speed - threshold) / settings.speed_range))
	local frequency = f32(f32(PointGraph.evaluate(settings.frequency_time, time_fraction) * PointGraph.evaluate(settings.frequency_speed, speed_fraction)) * settings.frequency_scale)
	local amplitude = f32(PointGraph.evaluate(settings.amplitude_speed, speed_fraction) * PointGraph.evaluate(settings.amplitude_time, time_fraction))
	local phase = mul_add(frequency, from_bits(0x3DD6_7751), from_bits(state.words[5]))
	local scale = f32(f32(settings.amplitude_scale * amplitude) * input.amplitude_multiplier)
	local displacement = f32(trigonometry.sin(phase) * scale)
	state.words[1] = to_bits(f32(time + from_bits(0x3C88_8889)))
	state.words[5] = to_bits(phase)
	state.words[6] = to_bits(amplitude)
	state.words[7] = to_bits(displacement)
	local result = f32(f32(displacement + input.tilt) * 0.5)
	-- This frame still returns the computed tilt when speed drops below threshold.
	if input.speed < threshold then
		SpeedWobbleState.reset(state)
	end
	return result
end

return speed_wobble
