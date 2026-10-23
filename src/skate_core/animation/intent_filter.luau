--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/intent_filter.rs (коммит 2e16697)
--
-- FilterMotionGraphIntent TU3 82BB1730/17D0/19F0 and 82BB1B78.
-- Coefficients and limits are per graph update; only the ramp uses elapsed time.

local rt = require("../../rt")
local graph_intents = require("../input/graph_intents")

local f32 = rt.f32
local mul_add = rt.mul_add
local apply_filter = graph_intents.apply_filter

local intent_filter = {}

export type Settings = {
	starting_value: number,
	default_value: number,
	scale: number,
	filters: { number },
	ramp_time: number?,
	blend_rising: number,
	blend_falling: number,
	blend_out: number?,
	clamp_velocity: number?,
	clamp_acceleration: number?,
}

export type State = { elapsed: number, previous_delta: number, value: number }

local State = {}
intent_filter.State = State

function State.default(): State
	return { elapsed = 0.0, previous_delta = 0.0, value = 0.0 }
end

-- Begin publishes startingValue directly, without scaling or filtering.
function State.begin(self: State, settings: Settings): number
	self.elapsed = 0.0
	self.previous_delta = 0.0
	self.value = settings.starting_value
	return self.value
end

local function limit_delta(value: number, lower: number, upper: number): number
	-- Preserve the original subtract/select ordering, including unordered input.
	local selected = if f32(lower - value) >= 0.0 then lower else value
	return if f32(upper - selected) >= 0.0 then selected else upper
end

local function ramp(elapsed: number, time: number): number
	-- 82BA8720 uses signed integer comparisons of float bits in lower_bound.
	-- Constructor 82BB1570..15BC supplies precisely (0,0),(rampTime,1).
	local keys = { 0.0, time }
	local begin = 0
	local count = 2
	local e = rt.to_i32(rt.to_bits(elapsed))
	while count ~= 0 do
		local step = count // 2
		local middle = begin + step
		if rt.to_i32(rt.to_bits(keys[middle + 1])) < e then
			begin = middle + 1
			count -= step + 1
		else
			count = step
		end
	end
	if begin == 0 then
		return 0.0
	elseif begin == 2 then
		return 1.0
	end
	return mul_add(f32(f32(1.0 - 0.0) / f32(time - 0.0)), f32(elapsed - 0.0), 0.0)
end

-- Stance is the live animation component's fakie/mirrored getter pair.
-- ROBLOX: stance (bool, bool) -> { fakie, mirrored }.
function State.update(self: State, settings: Settings, input: number?, dt: number, stance: { boolean }): number
	self.elapsed = f32(self.elapsed + dt)
	local target = f32(settings.scale * (if input ~= nil then input else settings.default_value))
	local enabled = { true, true, stance[1], stance[2] }
	for i = 1, 4 do
		local kind = settings.filters[i]
		if enabled[i] and kind <= 7 then
			target = apply_filter(target, kind)
		end
	end
	local blend = if target < self.value then settings.blend_falling else settings.blend_rising
	if input ~= nil then
		if settings.ramp_time ~= nil then
			blend = f32(ramp(self.elapsed, settings.ramp_time) * blend)
		end
	elseif settings.blend_out ~= nil then
		blend = settings.blend_out
	end
	-- 82BB194C..1968: separate target product, then fmadds, then subtract.
	local weighted_target = f32(blend * target)
	local candidate = mul_add(f32(1.0 - blend), self.value, weighted_target)
	local delta = f32(candidate - self.value)
	if settings.clamp_acceleration ~= nil then
		local limit = settings.clamp_acceleration
		delta = limit_delta(delta, f32(self.previous_delta - limit), f32(self.previous_delta + limit))
	end
	if settings.clamp_velocity ~= nil then
		local limit = settings.clamp_velocity
		delta = limit_delta(delta, -limit, limit)
	end
	self.previous_delta = delta
	self.value = f32(delta + self.value)
	return self.value
end

return intent_filter
