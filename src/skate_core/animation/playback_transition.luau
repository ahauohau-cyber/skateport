--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/playback_transition.rs (коммит 2e16697)
--
-- TU3 Sequence 82B95C18 and Blend 82B96058/82B961F8/82B963D8.
-- ROBLOX: методы дерева — через playback_transition.tree (см. playback_tree).

local rt = require("../../rt")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits

local playback_transition = {}
playback_transition.tree = (nil :: any)

export type PlaybackTransition = { from: any, to: any, settings: any, elapsed: number, sequence_complete: boolean }

local PlaybackTransition = {}
playback_transition.PlaybackTransition = PlaybackTransition

function PlaybackTransition.new(from: any, to: any, settings: any): PlaybackTransition
	return { from = from, to = to, settings = settings, elapsed = 0.0, sequence_complete = false }
end

function PlaybackTransition.complete(self: PlaybackTransition): boolean
	if self.settings.kind == 4 then
		return self.sequence_complete
	end
	return self.elapsed > self.settings.seconds
end

function PlaybackTransition.advance(self: PlaybackTransition, dt: number, phase: number, property: any)
	local T = playback_transition.tree
	local discarded = { crossed_end = false, overshoot = -1.0, remaining_before_wrap = -1.0 }
	if self.settings.kind == 4 then
		if self.sequence_complete then
			T.advance(self.to, dt, phase, property)
		else
			T.advance(self.from, dt, phase, discarded)
			if discarded.crossed_end then
				self.sequence_complete = true
				T.advance(self.to, discarded.overshoot, phase, property)
			else
				property.crossed_end = false
				property.remaining_before_wrap = f32(T.length(self.to) + discarded.remaining_before_wrap)
			end
		end
		return
	end
	if self.settings.matching ~= 1 then
		T.advance(self.from, dt, phase, discarded)
	end
	if self.settings.matching == 3 then
		local length = T.length(self.to)
		local time = T.time(self.from)
		T.set_time(self.to, if f32(time - length) >= 0.0 then length else time)
	elseif self.settings.matching == 2 and T.length(self.from) > 0.0 then
		T.set_time(self.to, f32(T.length(self.to) * f32(T.time(self.from) / T.length(self.from))))
	else
		T.advance(self.to, dt, phase, property)
	end
	self.elapsed = f32(self.elapsed + dt)
end

function PlaybackTransition.set_attributes(self: PlaybackTransition, attrs: { any }): boolean
	local T = playback_transition.tree
	local result = T.set_attributes(self.to, attrs)
	if self.settings.kind == 4 and not self.sequence_complete then
		return T.set_attributes(self.from, attrs)
	end
	return result
end

local function attributes_child(self: PlaybackTransition): any
	return if self.settings.kind == 4 and not self.sequence_complete then self.from else self.to
end

function PlaybackTransition.attributes(self: PlaybackTransition, mask: number): { any }
	return playback_transition.tree.attributes(attributes_child(self), mask)
end

function PlaybackTransition.query_attribute(self: PlaybackTransition, name: { number }, mask: number, output: any): boolean
	return playback_transition.tree.query_attribute(attributes_child(self), name, mask, output)
end

local K_3d4ccccd = from_bits(0x3d4ccccd)

function PlaybackTransition.weight(self: PlaybackTransition): number
	local value = f32(self.elapsed / self.settings.seconds)
	local lower = if -value >= 0.0 then 0.0 else value
	local weight = if f32(1.0 - lower) >= 0.0 then lower else 1.0
	if self.settings.seconds < K_3d4ccccd or weight > 1.0 or weight < 0.0 then
		return weight
	end
	local square = f32(weight * weight)
	local cube = f32(square * weight)
	return mul_add(square, 3.0, -f32(cube * 2.0))
end

function PlaybackTransition.evaluate(self: PlaybackTransition, parameters: any, enabled: boolean, output: { any }): boolean
	local T = playback_transition.tree
	if self.settings.kind == 4 then
		return if self.sequence_complete then T.evaluate(self.to, parameters, enabled, output) else T.evaluate(self.from, parameters, enabled, output)
	end
	local weight = PlaybackTransition.weight(self)
	local from = T.evaluate(self.from, parameters, enabled, output)
	local to = T.evaluate(self.to, parameters, enabled, output)
	if enabled and from and to then
		if self.settings.kind == 3 then
			table.insert(output, { kind = "ChannelBlend", weight = weight, use_channels_from_weights = self.settings.use_channels_from_weights })
		else
			table.insert(output, { kind = "Blend", weight = weight })
		end
	end
	return from or to
end

return playback_transition
