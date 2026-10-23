--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/kickturn.rs (коммит 2e16697)
--
-- Original Skate 3 TU3 KickTurnSteering: constructor 82BAE730,
-- Begin 82BAE430 and Update 82BAE4A8. Curves are Globals 324 anim_motion/kickturn.

local rt = require("../../rt")
local point_graph = require("../point_graph")

local f32 = rt.f32
local mul_add = rt.mul_add
local evaluate = point_graph.PointGraph.evaluate

local kickturn = {}

export type Settings = { spin: point_graph.PointGraph, height: point_graph.PointGraph }

-- Authored behavior fields 28/32; constructor 82BC7218 defaults both to 0.5.
export type Parameters = { max_height: number, spin_scale: number }

export type State = {
	animation_length: number,
	elapsed: number,
	first_update: boolean,
	previous_height: number,
	last_nonzero_intent: number,
}

export type Output = {
	-- Published first, to the actual MotionGraph Balance attribute.
	balance: number,
	spin: number,
}

-- Source fsel(-value,0,value), then fsel(max-lower,lower,max).
-- Preserves source unordered handling: a NaN selects the upper bound.
local function bound(value: number, maximum: number): number
	local lower = if -value >= 0.0 then 0.0 else value
	return if f32(maximum - lower) >= 0.0 then lower else maximum
end

local State = {}
kickturn.State = State

function State.new(): State
	return { animation_length = 0.0, elapsed = 0.0, first_update = true, previous_height = 0.0, last_nonzero_intent = 0.0 }
end

function State.begin(self: State, settings: Settings)
	local fresh = State.new()
	for k, v in fresh :: any do
		(self :: any)[k] = v
	end
	-- 82BAE480 seeds the unscaled curve value, before applying max_height.
	self.previous_height = evaluate(settings.height, 0.0)
end

function State.needs_animation_length(self: State): boolean
	return self.first_update
end

-- The caller first applies pending animation parameters, then reads the
-- base animation tree's length. No time is added on that first update.
function State.capture_animation_length(self: State, length: number)
	self.animation_length = length
end

function State.update(self: State, dt: number, intent: number, parameters: Parameters, settings: Settings): Output
	if not self.first_update then
		self.elapsed = f32(self.elapsed + dt)
	end
	local phase = bound(f32(self.elapsed / self.animation_length), 1.0)
	local spin_curve = evaluate(settings.spin, phase)
	local height_curve = evaluate(settings.height, phase)
	-- 82BAE660 fmadds, followed by separate 82BAE670 fmuls. TU3 fixes
	-- the blend coefficient at 0.5; the S2 debug alternatives are absent.
	local sum = mul_add(height_curve, parameters.max_height, self.previous_height)
	local height = bound(f32(sum * 0.5), parameters.max_height)
	self.previous_height = height
	if intent ~= 0.0 then
		self.last_nonzero_intent = intent
	end
	local sign = if self.last_nonzero_intent >= 0.0 then 1.0 else -1.0
	local output = { balance = -height, spin = f32(f32(parameters.spin_scale * sign) * spin_curve) }
	self.first_update = false
	return output
end

return kickturn
