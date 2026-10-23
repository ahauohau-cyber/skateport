--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/channel_playback.rs (коммит 2e16697)
--
-- Persistent channel timing from TU3 NewChannel 82D1CC20, AddTime 82D266A8,
-- RemoveExpiredChannels 82D1DA00 and EndChannelPrematurely 82D1D6A8.

local rt = require("../../rt")
local attributes = require("./output/attributes")
local clip_clock = require("./clip_clock")

local f32 = rt.f32

local channel_playback = {}

export type ChannelSettings = {
	priority: number,
	keep_alive: boolean,
	mirrored: boolean,
	speed: number,
	blend_in: number,
	hold_during_blend_in: boolean,
	blend_out: number,
	hold_during_blend_out: boolean,
	use_attributes: boolean,
}

export type ChannelPlayback = {
	settings: ChannelSettings,
	weight: number,
	influence: number,
	blend_in_elapsed: number,
	blend_out_elapsed: number,
	resurrection_elapsed: number,
	resurrection_duration: number,
	flags: number,
}

local function b(v: boolean, shift: number): number
	return if v then bit32.lshift(1, shift) else 0
end

local function unit(value: number): number
	local low = if -value >= 0.0 then 0.0 else value
	return if f32(1.0 - low) >= 0.0 then low else 1.0
end

local ChannelPlayback = {}
channel_playback.ChannelPlayback = ChannelPlayback

function ChannelPlayback.new(settings: ChannelSettings): ChannelPlayback
	local flags = bit32.bor(b(settings.keep_alive, 28), b(settings.hold_during_blend_in, 31), b(settings.hold_during_blend_out, 30), b(settings.blend_out > 0.0, 27), b(settings.use_attributes, 25))
	return { settings = table.clone(settings), weight = 0.0, influence = 1.0, blend_in_elapsed = 0.0, blend_out_elapsed = 0.0, resurrection_elapsed = 0.0, resurrection_duration = 0.0, flags = flags }
end

-- Called before advancing any trees, in the native actor AddTime order.
function ChannelPlayback.expired(self: ChannelPlayback): boolean
	if bit32.band(self.flags, 0x08000000) ~= 0 then
		return self.blend_out_elapsed >= self.settings.blend_out
	end
	return bit32.band(self.flags, 0x10000000) == 0 and bit32.band(self.flags, 0x04000000) ~= 0
end

ChannelPlayback["end"] = function(self: ChannelPlayback)
	if self.blend_out_elapsed == 0.0 then
		self.flags = bit32.bor(self.flags, 0x28000000)
	end
end

function ChannelPlayback.end_with(self: ChannelPlayback, seconds: number, from_last_frame: boolean)
	if self.blend_out_elapsed == 0.0 then
		self.settings.blend_out = seconds
		self.settings.hold_during_blend_out = from_last_frame
		self.flags = bit32.bor(bit32.band(self.flags, bit32.bnot(0x40000000)), b(from_last_frame, 30), 0x28000000)
	end
end

function ChannelPlayback.can_transition(self: ChannelPlayback, resurrect: boolean): boolean
	return not (self.blend_out_elapsed > 0.0) or resurrect
end

-- StartTransition 82D1D398..D47C preserves fade-in time/influence and
-- priority, replaces fade-out settings, and optionally restores a fading
-- channel from its existing coefficient rather than restarting at zero.
function ChannelPlayback.transition(self: ChannelPlayback, settings: ChannelSettings, resurrect: boolean)
	if self.blend_out_elapsed > 0.0 and resurrect then
		self.resurrection_duration = settings.blend_in
		self.resurrection_elapsed = f32(unit(f32(1.0 - f32(self.blend_out_elapsed / self.settings.blend_out))) * settings.blend_in)
	end
	self.blend_out_elapsed = 0.0
	self.settings.keep_alive = settings.keep_alive
	self.settings.blend_out = settings.blend_out
	self.settings.hold_during_blend_out = settings.hold_during_blend_out
	self.settings.use_attributes = settings.use_attributes
	self.flags = bit32.bor(bit32.band(self.flags, bit32.bnot(0x7a000000)), b(settings.keep_alive, 28), b(settings.hold_during_blend_out, 30), b(settings.blend_out > 0.0, 27), b(settings.use_attributes, 25))
end

-- Returns whether the channel child should advance. The base has already
-- advanced; fade weights use PRE-update elapsed times, then increment them.
function ChannelPlayback.advance(self: ChannelPlayback, dt: number, length: number, time: number): boolean
	local s = self.settings
	local fade_in = 1.0
	if s.blend_in > 0.0 and self.blend_in_elapsed < s.blend_in then
		fade_in = unit(f32(self.blend_in_elapsed / s.blend_in))
		self.blend_in_elapsed = f32(self.blend_in_elapsed + dt)
	end
	local remaining = f32(length - time)
	remaining = if remaining >= 0.0 then remaining else 0.0
	local hold_end = bit32.band(self.flags, 0x40000000) ~= 0
	local ended = bit32.band(self.flags, 0x04000000) ~= 0
	local fade_automatically = if hold_end then ended else remaining < s.blend_out
	local fade_out = 1.0
	if s.blend_out > 0.0 and (bit32.band(self.flags, 0x20000000) ~= 0 or (bit32.band(self.flags, 0x10000000) == 0 and fade_automatically)) then
		fade_out = unit(f32(1.0 - f32(self.blend_out_elapsed / s.blend_out)))
		self.blend_out_elapsed = f32(self.blend_out_elapsed + dt)
	end
	local resurrection = 1.0
	if self.resurrection_duration > 0.0 and self.resurrection_elapsed < self.resurrection_duration then
		resurrection = unit(f32(self.resurrection_elapsed / self.resurrection_duration))
		self.resurrection_elapsed = f32(self.resurrection_elapsed + dt)
	end
	local fade = if f32(fade_in - fade_out) >= 0.0 then fade_out else fade_in
	fade = if f32(fade - resurrection) >= 0.0 then resurrection else fade
	self.weight = unit(f32(fade * self.influence))
	return not (bit32.band(self.flags, 0x80000000) ~= 0 and self.blend_in_elapsed < s.blend_in) and not (hold_end and self.blend_out_elapsed > 0.0)
end

function ChannelPlayback.did_advance(self: ChannelPlayback, property: clip_clock.AdvanceResult)
	self.flags = bit32.bor(bit32.band(self.flags, bit32.bnot(0x04000000)), b(property.crossed_end, 26))
end

-- ROBLOX: [u32; 5]::cmp — лексикографическое сравнение слов.
local function compare(a: { number }, c: { number }): number
	for i = 1, 5 do
		if a[i] < c[i] then
			return -1
		elseif a[i] > c[i] then
			return 1
		end
	end
	return 0
end

function ChannelPlayback.merge_attributes(self: ChannelPlayback, base: { attributes.AnimationAttribute }, channel: { attributes.AnimationAttribute }): { attributes.AnimationAttribute }
	if not self.settings.use_attributes then
		return base
	end
	-- 82B966D0: ordered union, channel wins equal names without scaling.
	local output = {}
	local bi, ci = 1, 1
	while bi <= #base and ci <= #channel do
		local order = compare(base[bi].name, channel[ci].name)
		if order < 0 then
			table.insert(output, base[bi])
			bi += 1
		elseif order > 0 then
			table.insert(output, channel[ci])
			ci += 1
		else
			table.insert(output, channel[ci])
			bi += 1
			ci += 1
		end
	end
	for i = bi, #base do
		table.insert(output, base[i])
	end
	for i = ci, #channel do
		table.insert(output, channel[i])
	end
	return output
end

return channel_playback
