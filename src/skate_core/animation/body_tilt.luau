--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/body_tilt.rs (коммит 2e16697)
--
-- SettingBodyTilt Update 82BA88A0 and CreateInstance 82BA8B40.

local rt = require("../../rt")
local point_graph = require("../point_graph")

local f32 = rt.f32

local body_tilt = {}

export type Settings = {
	body_spin_factor: point_graph.PointGraph,
	ground_velocity: number,
	ground_acceleration: number,
	air_velocity: number,
	air_acceleration: number,
}

export type Physical = {
	-- PhysOutAnimation vector+0 X, consumed with mirrored stance sign.
	lateral_tilt: number,
	-- Expanded PhysOut bundle+8 scalar 204; the curve consumes its magnitude.
	body_spin_speed: number,
	filtered_category: number,
}

export type State = { value: number, velocity: number, was_enabled: boolean }

local State = {}
body_tilt.State = State

function State.default(): State
	return { value = 0.0, velocity = 0.0, was_enabled = false }
end

function State.disable(self: State)
	self.was_enabled = false
end

local function bound(value: number, lo: number, hi: number): number
	local lower = if f32(lo - value) >= 0.0 then lo else value
	return if f32(hi - lower) >= 0.0 then lower else hi
end

function State.update(self: State, enabled: boolean, mirrored: boolean, p: Physical, s: Settings): number?
	if not self.was_enabled and enabled then
		self.value = 0.0
		self.velocity = 0.0
	end
	self.was_enabled = enabled
	if not enabled then
		return nil
	end
	-- 82B97140 tests fullSkaterAnim 15180 bit30. The nonmirrored branch
	-- flips the sign bit of the source X component before multiplication.
	local tilt = if mirrored then p.lateral_tilt else -p.lateral_tilt
	local target = f32(point_graph.PointGraph.evaluate(s.body_spin_factor, math.abs(p.body_spin_speed)) * tilt)
	local velocity, acceleration
	if p.filtered_category == 2 then
		velocity, acceleration = s.air_velocity, s.air_acceleration
	else
		velocity, acceleration = s.ground_velocity, s.ground_acceleration
	end
	local desired = bound(f32(target - self.value), -velocity, velocity)
	local change = bound(f32(desired - self.velocity), -acceleration, acceleration)
	self.velocity = f32(self.velocity + change)
	self.value = f32(self.value + self.velocity)
	return self.value
end

return body_tilt
