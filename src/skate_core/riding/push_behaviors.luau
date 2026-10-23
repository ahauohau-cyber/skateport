--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/riding/push_behaviors.rs (коммит 2e16697)
--
-- Push behavior state and coefficient calculations from Skate 3 TU3.
-- Animation-tree selection and graph transitions belong to the authored graph.

local rt = require("../../rt")
local native_arithmetic = require("../physics/native_arithmetic")
local point_graph = require("../point_graph")
local push_animation = require("./push_animation")

local f32 = rt.f32
local mul_add = rt.mul_add
local PointGraph = point_graph.PointGraph
local PushAnimationCurves = push_animation.PushAnimationCurves

type PushBlendParameters = push_animation.PushBlendParameters

local push_behaviors = {}

export type PushClipMetrics = { length: number, begin_velocity: number, end_velocity: number }

export type PushAttributes = {
	-- Native order: low-speed/high-strength, high-speed/high-strength,
	-- low-speed/low-strength, high-speed/low-strength.
	clips: { PushClipMetrics },
	minimum_begin_velocity: number,
	maximum_begin_velocity: number,
	minimum_delta_velocity: number,
	maximum_delta_velocity: number,
}

local function native_min(a: number, b: number): number
	return if f32(a - b) >= 0.0 then b else a
end
local function native_max(a: number, b: number): number
	return if f32(a - b) >= 0.0 then a else b
end
local function bounded(value: number, minimum: number, maximum: number): number
	return native_min(maximum, native_max(minimum, value))
end
local function nonnegative(value: number): number
	return if value >= 0.0 then value else 0.0
end
local function unit(value: number): number
	local lower = if -value >= 0.0 then 0.0 else value
	return if f32(1.0 - lower) >= 0.0 then lower else 1.0
end

local function velocity_blend(speed: number, low_length: number, low_velocity: number, high_length: number, high_velocity: number): number
	local low_distance = f32(low_length * low_velocity)
	local speed_distance = f32(speed * low_length)
	local sum = mul_add(high_length, high_velocity, speed_distance)
	local numerator = f32(speed_distance - low_distance)
	-- ROBLOX: в Rust `-x.mul_add(..)` = `-(x.mul_add(..))`.
	local denominator = -mul_add(speed, high_length, -f32(sum - low_distance))
	return unit(f32(numerator / denominator))
end

local function blended_end(coefficient: number, low: PushClipMetrics, high: PushClipMetrics): number
	coefficient = unit(coefficient)
	local high_weight = f32(coefficient * high.length)
	local low_weight = f32(f32(1.0 - coefficient) * low.length)
	return f32(mul_add(high.end_velocity, high_weight, f32(low.end_velocity * low_weight)) / f32(high_weight + low_weight))
end

local PushAttributes = {}
push_behaviors.PushAttributes = PushAttributes

-- 82B954D8, after 82B95620 obtains each tree's length and its last
-- HStr_Vel_B/LStr_Vel_B and Vel_E attributes. No fitted clip coefficients.
function PushAttributes.from_clips(clips: { PushClipMetrics }): PushAttributes
	local begin, delta = {}, {}
	for i = 1, 4 do
		begin[i] = clips[i].begin_velocity
		delta[i] = f32(clips[i].end_velocity - clips[i].begin_velocity)
	end
	return {
		clips = clips,
		minimum_begin_velocity = native_min(native_min(begin[1], begin[2]), native_min(begin[3], begin[4])),
		maximum_begin_velocity = native_max(native_max(begin[1], begin[2]), native_max(begin[3], begin[4])),
		minimum_delta_velocity = native_min(native_min(delta[1], delta[2]), native_min(delta[3], delta[4])),
		maximum_delta_velocity = native_max(native_max(delta[1], delta[2]), native_max(delta[3], delta[4])),
	}
end

-- ComputeTargetCoefsFromSpeedAndStrength, 82BAD260. The blend accounts
-- for differing clip lengths; a linear velocity interpolation is wrong.
function PushAttributes.target(self: PushAttributes, forward_speed: number, strength: number): PushBlendParameters
	local speed = bounded(nonnegative(forward_speed), self.minimum_begin_velocity, self.maximum_begin_velocity)
	strength = bounded(strength, self.minimum_delta_velocity, self.maximum_delta_velocity)
	local slow_strong, fast_strong, slow_gentle, fast_gentle = self.clips[1], self.clips[2], self.clips[3], self.clips[4]
	local strong_speed = bounded(speed, slow_strong.begin_velocity, fast_strong.begin_velocity)
	local gentle_speed = bounded(speed, slow_gentle.begin_velocity, fast_gentle.begin_velocity)
	local strong = velocity_blend(strong_speed, slow_strong.length, slow_strong.begin_velocity, fast_strong.length, fast_strong.begin_velocity)
	local gentle = velocity_blend(gentle_speed, slow_gentle.length, slow_gentle.begin_velocity, fast_gentle.length, fast_gentle.begin_velocity)
	local strong_length = mul_add(f32(1.0 - strong), slow_strong.length, f32(fast_strong.length * strong))
	local gentle_length = mul_add(f32(1.0 - gentle), slow_gentle.length, f32(fast_gentle.length * gentle))
	local strong_end = blended_end(strong, slow_strong, fast_strong)
	local gentle_end = blended_end(gentle, slow_gentle, fast_gentle)
	local target_end = bounded(f32(strength + speed), gentle_end, strong_end)
	local strength_blend = velocity_blend(target_end, gentle_length, gentle_end, strong_length, strong_end)
	return { hstr_vel_b = unit(strong), lstr_vel_b = unit(gentle), vel_e = unit(strength_blend) }
end

-- ComputeRepushDeadline::End, 82BADA90. Despite its graph name, this
-- writes PushState.out_factor, not a time deadline or a graph transition.
function PushAttributes.out_factor(self: PushAttributes, forward_speed: number, strength: number, speed_weight: number, maximum_out: number): number
	local first_speed = f32(self.minimum_begin_velocity + self.minimum_delta_velocity)
	local speed = bounded(nonnegative(forward_speed), first_speed, self.maximum_begin_velocity)
	strength = bounded(strength, self.minimum_delta_velocity, self.maximum_delta_velocity)
	local strength_factor = unit(f32(f32(strength - self.minimum_delta_velocity) / f32(self.maximum_delta_velocity - self.minimum_delta_velocity)))
	local speed_factor = unit(f32(f32(speed - first_speed) / f32(self.maximum_begin_velocity - first_speed)))
	local combined = mul_add(strength_factor, f32(1.0 - speed_weight), f32(speed_factor * speed_weight))
	local lower = if -combined >= 0.0 then 0.0 else combined
	return native_min(maximum_out, lower)
end

export type PushState = {
	out_factor: number,
	current_push_dv: number,
	current: PushBlendParameters,
	target: PushBlendParameters,
	continue_push: boolean,
}

local PushState = {}
push_behaviors.PushState = PushState

-- InitPush::Begin, 82BAD5B8, preserves out_factor.
function PushState.initialize_push(self: PushState)
	self.continue_push = false
	self.current_push_dv = 0.0
	self.current = { hstr_vel_b = -1.0, lstr_vel_b = -1.0, vel_e = -1.0 }
	self.target = table.clone(self.current)
end

export type FirstPushStrength = {
	simulated_held_seconds: number,
	push_from_teleport: boolean,
	first_push: boolean,
	first_update: boolean,
}

local FirstPushStrength = {}
push_behaviors.FirstPushStrength = FirstPushStrength

-- Begin82BAD6E8: capture teleport eligibility once per activation.
function FirstPushStrength.begin(time_since_teleport: number, teleport_window: number): FirstPushStrength
	return { simulated_held_seconds = 0.0, push_from_teleport = time_since_teleport < teleport_window, first_push = true, first_update = true }
end

-- Update82BAD7A8: the teleport path evaluates the old simulated time
-- before adding dt. A released first push cannot be resumed here.
-- ROBLOX: pushing: Option<f32> -> number или nil.
function FirstPushStrength.update(self: FirstPushStrength, state: PushState, curves: any, pushing: number?, forward_speed: number, dt: number)
	if pushing == nil then
		self.first_push = false
	end
	if self.first_push or self.push_from_teleport then
		local held
		if self.push_from_teleport then
			held = self.simulated_held_seconds
			self.simulated_held_seconds = f32(dt + self.simulated_held_seconds)
		else
			held = pushing or 0.0
		end
		local strength = PushAnimationCurves.strength(curves, held, nonnegative(forward_speed))
		if strength > state.current_push_dv then
			state.current_push_dv = strength
		end
	end
	self.first_update = false
end

-- A snapshot of the authored MG intent list, not raw controller buttons.
export type PushIntents = {
	pushing: number?,
	new_push: boolean,
	-- Presence of the configured newPushName (RightPush or LeftPush in stock).
	configured_foot: boolean,
}

-- ROBLOX: enum PushCyclePhase -> числа.
push_behaviors.PushCyclePhase = { HoldingFirst = 0, WaitingNext = 1, HoldingNext = 2, NextReleased = 3 }
local Phase = push_behaviors.PushCyclePhase

export type PushCycle = { phase: number, next_push_dv: number }

local PushCycle = {}
push_behaviors.PushCycle = PushCycle

-- Begin82BADCD0.
function PushCycle.begin(state: PushState, curves: any, intents: PushIntents): PushCycle
	local holding = intents.pushing ~= nil and intents.configured_foot
	state.continue_push = holding
	return {
		phase = if holding then Phase.HoldingFirst else Phase.WaitingNext,
		next_push_dv = PointGraph.evaluate(curves.button_time_to_dv, 0.0),
	}
end

-- Update82BADE38. Separate phase checks intentionally allow the release
-- and next-press path to run in one graph update, as in the recovered code.
function PushCycle.update(self: PushCycle, state: PushState, curves: any, intents: PushIntents, forward_speed: number, maximum_holding_acceleration: number)
	local speed = nonnegative(forward_speed)
	if self.phase == Phase.HoldingFirst then
		local held = intents.pushing
		if held ~= nil then
			self.next_push_dv = PushAnimationCurves.strength(curves, held, speed)
			if self.next_push_dv > maximum_holding_acceleration then
				self.next_push_dv = maximum_holding_acceleration
				state.current_push_dv = maximum_holding_acceleration
			end
			if state.current_push_dv < self.next_push_dv then
				state.current_push_dv = self.next_push_dv
			end
		else
			self.phase = Phase.WaitingNext
			self.next_push_dv = PointGraph.evaluate(curves.button_time_to_dv, 0.0)
			state.continue_push = false
		end
	end
	if self.phase == Phase.WaitingNext and intents.new_push and intents.configured_foot then
		self.phase = Phase.HoldingNext
	end
	if self.phase == Phase.HoldingNext and not intents.configured_foot then
		self.phase = Phase.NextReleased
		state.current_push_dv = self.next_push_dv
	end
	if self.phase == Phase.HoldingNext then
		self.next_push_dv = PushAnimationCurves.strength(curves, intents.pushing or 0.0, speed)
		if state.current_push_dv < self.next_push_dv then
			state.current_push_dv = self.next_push_dv
		end
		state.continue_push = true
	end
end

-- Physics outputs consumed by GetFootPos82595B28. All positions are world
-- space; deck axes come from the live reckoning transform, not a render pose.
export type PushFootFrame = {
	left_foot: { number },
	right_foot: { number },
	deck_position: { number },
	deck_y: { number },
	deck_z: { number },
	skateboard_flipped: boolean,
}

local PushFootFrame = {}
push_behaviors.PushFootFrame = PushFootFrame

-- TU382595B28. Reuses the isolated, approximation-derived Xenon dot
-- lowering; independent hardware arithmetic validation remains pending.
function PushFootFrame.out_distance(self: PushFootFrame, right_foot: boolean): { number }
	local foot = if right_foot then self.right_foot else self.left_foot
	local relative = {}
	for i = 1, 4 do
		relative[i] = f32(foot[i] - self.deck_position[i])
	end
	local z = if self.skateboard_flipped then { -self.deck_z[1], -self.deck_z[2], -self.deck_z[3], -self.deck_z[4] } else self.deck_z
	return { native_arithmetic.dot3(relative, z), native_arithmetic.dot3(relative, self.deck_y) }
end

return push_behaviors
