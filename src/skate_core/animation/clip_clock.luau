--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/clip_clock.rs (коммит 2e16697)
--
-- Andale Clip timing: 0x82D25A00, 0x825902C0, 0x827B8BD8,
-- 0x827B8C38, 0x827B8B90; attribute status 0x82D264C0.

local rt = require("../../rt")

local f32 = rt.f32

local clip_clock = {}

export type ClipClock = {
	frames: number,
	fps: number,
	base_speed: number,
	speed: number,
	length: number,
	time: number,
	previous_time: number,
	-- Native +40; retained until pose evaluation commits previous time.
	loops_since_evaluation: number,
	looping: boolean,
	-- Clip flags word bit 30 / native object byte +49.
	phase_controlled: boolean,
}

export type AdvanceResult = {
	-- Native output byte +1. Exact equality with the end does not cross it.
	crossed_end: boolean,
	-- Native output +4; unchanged on updates that do not cross the end.
	overshoot: number,
	-- Native output +8, measured before wrapping, so it may be negative.
	remaining_before_wrap: number,
}

function clip_clock.advance_result_default(): AdvanceResult
	return { crossed_end = false, overshoot = 0.0, remaining_before_wrap = 0.0 }
end

local ClipClock = {}
clip_clock.ClipClock = ClipClock

function ClipClock.set_time(self: ClipClock, time: number)
	self.time = time
	self.previous_time = time
	self.loops_since_evaluation = 0
end

-- Preserve the native multiply/divide order when changing playback rate.
-- In particular, simplifying this to old_speed/new_speed changes rounding.
function ClipClock.set_speed(self: ClipClock, speed: number)
	local new_rate = f32(self.base_speed * speed)
	local old_rate = f32(self.speed * self.base_speed)
	local frames_per_second = f32(self.fps * self.base_speed)
	local inverse_new_rate = f32(1.0 / new_rate)
	self.time = f32(f32(self.time * old_rate) * inverse_new_rate)
	self.previous_time = f32(f32(self.previous_time * old_rate) * inverse_new_rate)
	self.length = f32(f32(self.frames - 1.0) / f32(frames_per_second * speed))
	self.speed = speed
end

function ClipClock.sample_time(self: ClipClock): number
	return if f32(self.length - self.time) >= 0.0 then self.time else self.length
end

function ClipClock.advance(self: ClipClock, delta_seconds: number, phase: number, result: AdvanceResult)
	if self.phase_controlled then
		self.previous_time = self.time
		local lower = if -phase >= 0.0 then 0.0 else phase
		local p = if f32(1.0 - lower) >= 0.0 then lower else 1.0
		self.time = f32(self.length * p)
		self.loops_since_evaluation = if self.time < self.previous_time then 1 else 0
		-- The native phase branch does not touch the AdvanceResult fields.
		return
	end
	self.time = f32(self.time + delta_seconds)
	result.remaining_before_wrap = f32(self.length - self.time)
	-- ROBLOX: partial_cmp != Some(Greater) -> not (time > length) (NaN тоже сюда).
	if not (self.time > self.length) then
		result.crossed_end = false
	elseif self.looping then
		-- Invalid lengths cannot make progress in the native subtraction
		-- loop. Fail explicitly rather than hang or invent a replacement.
		assert(self.length > 0.0 and rt.is_finite(self.time), "invalid looping clip clock")
		while self.time > self.length do
			result.crossed_end = true
			result.overshoot = f32(self.time - self.length)
			local next_ = f32(self.time - self.length)
			assert(next_ < self.time, "clip clock cannot advance at this precision")
			self.time = next_
			self.loops_since_evaluation = rt.wrapping_add_u32(self.loops_since_evaluation, 1)
		end
	else
		result.crossed_end = true
		result.overshoot = f32(self.time - self.length)
	end
end

-- 0x82D25C20/24, called when pose evaluation's update-history flag is set.
-- Advancing time alone does not perform this commit in the elapsed mode.
function ClipClock.commit_evaluation(self: ClipClock)
	self.previous_time = self.time
	self.loops_since_evaluation = 0
end

-- Return the native status byte used by GetAttribute/GetAttributes and
-- the physics contact consumer. Times in the bank are normalized to length.
function ClipClock.attribute_status(self: ClipClock, begin: number, end_: number): number
	if begin == -1.0 then
		return 6
	end
	local b = f32(self.length * begin)
	local e = f32(self.length * end_)
	local intersects
	if self.loops_since_evaluation == 0 then
		intersects = e > self.previous_time and b <= self.time
	else
		intersects = e > self.previous_time or b <= self.time
	end
	if not intersects then
		return 17
	elseif self.time < b or self.time > e then
		return 9
	end
	return 5
end

return clip_clock
