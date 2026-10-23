--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/manual.rs (коммит 2e16697)
--
-- SetManualAngle Begin 82BA8C48/Update 82BA8C60. Animation selection only;
-- physical balance is separately emitted by the authored AttachIntent node.

local rt = require("../../rt")
local point_graph = require("../point_graph")

local f32 = rt.f32

local manual = {}

export type Settings = {
	-- anim_motion/manual layout 1216..1276, native eight-point evaluator.
	balance: point_graph.PointGraph,
	-- Layout 1800/1804. Limits are per graph update, not per second.
	velocity_limit: number,
	acceleration_limit: number,
}

export type State = { angle: number, velocity: number }

local State = {}
manual.State = State

function State.default(): State
	return { angle = 0.0, velocity = 0.0 }
end

function State.begin(self: State)
	self.angle = 0.0
	self.velocity = 0.0
end

local function clamp(value: number, limit: number): number
	-- Preserve the source fsubs/fsel selection, including signed zero.
	local lower = if f32(-limit - value) >= -0.0 then -limit else value
	return if f32(limit - lower) >= -0.0 then lower else limit
end

function State.update(self: State, manual_value: number?, settings: Settings): number
	-- The native lookup begins with zero; an absent intent leaves it zero.
	local m = if manual_value ~= nil then manual_value else 0.0
	local target = point_graph.PointGraph.evaluate(settings.balance, math.abs(m))
	target = if m >= -0.0 then target else -target
	local desired_velocity = clamp(f32(target - self.angle), settings.velocity_limit)
	local acceleration = clamp(f32(desired_velocity - self.velocity), settings.acceleration_limit)
	self.velocity = f32(self.velocity + acceleration)
	self.angle = f32(self.angle + self.velocity)
	return self.angle
end

return manual
