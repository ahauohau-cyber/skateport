--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/camera/slow_motion.rs (коммит 2e16697)
--
-- SlowMotionController TU382BB1DD8/82BB1EE0/82BB20A8. The host owns
-- message delivery; this retains the curve, latching and timestep calculation.

local rt = require("../../rt")
local point_graph = require("../point_graph")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local PointGraph = point_graph.PointGraph

local slow_motion = {}

-- pub struct SlowMotionSettings { timescale: PointGraph<16>, fps_at_scale_one: f32 }
export type SlowMotionSettings = {
	timescale: point_graph.PointGraph,
	fps_at_scale_one: number,
}

-- pub struct SimulationRateRequest { timestep: f32, ticks: u32 }
export type SimulationRateRequest = {
	timestep: number,
	ticks: number,
}

-- pub struct SlowMotionController { elapsed, air_duration, time_before_prediction: f32, latched_prediction: bool }
export type SlowMotionController = {
	elapsed: number,
	air_duration: number,
	time_before_prediction: number,
	latched_prediction: boolean,
}

local SlowMotionSettings = {}
local SlowMotionController = {}
slow_motion.SlowMotionSettings = SlowMotionSettings
slow_motion.SlowMotionController = SlowMotionController

-- pub fn begin(settings: SlowMotionSettings) -> (Self, SimulationRateRequest)
-- ROBLOX: кортеж -> два возвращаемых значения.
function SlowMotionController.begin(settings: SlowMotionSettings): (SlowMotionController, SimulationRateRequest)
	return {
		elapsed = 0.0,
		air_duration = 0.0,
		time_before_prediction = 0.0,
		latched_prediction = false,
	}, SlowMotionSettings.request(settings, 0.0)
end

-- pub fn update(&mut self, dt: f32, air_duration: f32, settings: SlowMotionSettings) -> SimulationRateRequest
function SlowMotionController.update(
	self: SlowMotionController,
	dt: number,
	air_duration: number,
	settings: SlowMotionSettings
): SimulationRateRequest
	self.elapsed = f32(self.elapsed + dt)
	-- 82BB1FC8 uses ble (not GT), which also takes the unordered case.
	local progress
	if not (air_duration > 0.0) then
		if not self.latched_prediction then
			self.time_before_prediction = f32(self.time_before_prediction + dt)
		end
		progress = from_bits(0x3dcccccd)
	else
		if not self.latched_prediction then
			self.air_duration = air_duration
			self.latched_prediction = true
		end
		progress = f32(self.elapsed / f32(self.time_before_prediction + self.air_duration))
	end
	return SlowMotionSettings.request(settings, progress)
end

-- pub fn end() -> SimulationRateRequest
-- ROBLOX: `end` — ключевое слово Luau, поэтому функция называется end_ (имя в Rust — end).
function SlowMotionController.end_(): SimulationRateRequest
	return {
		timestep = from_bits(0x3c888889),
		ticks = 0,
	}
end

-- fn request(self, progress: f32) -> SimulationRateRequest
function SlowMotionSettings.request(self: SlowMotionSettings, progress: number): SimulationRateRequest
	local curve = PointGraph.evaluate(self.timescale, progress)
	return {
		timestep = f32(1.0 / mul_add(curve, f32(self.fps_at_scale_one - 60.0), 60.0)),
		ticks = 1,
	}
end

return slow_motion
