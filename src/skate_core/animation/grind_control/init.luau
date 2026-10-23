--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/grind_control.rs (коммит 2e16697)
--
-- S3 TU3 GrindControlFade 82BB0D40 and ControlGrindCrouch 82BB10F8.
-- Adapted from the authorized ZIP after independent original-image comparison.
-- Animation selection, physical observations and tuning remain external inputs.

local rt = require("../../rt")

local f32 = rt.f32
local mul_add = rt.mul_add

local grind_control = {}

grind_control.facing = require("@self/facing")

export type FadeSettings = {
	-- anim_motion/grind_twist: offsets 1640/1644/1648/1652.
	response: number,
	input_scale: number,
	acceleration: number,
	maximum_step: number,
}

export type Fade = {
	just_began: boolean,
	elapsed: number,
	value: number,
	target: number,
	step: number,
	minimum: number,
	maximum: number,
}

local function bound(value: number, minimum: number, maximum: number): number
	value = if f32(minimum - value) >= 0.0 then minimum else value
	return if f32(maximum - value) >= 0.0 then value else maximum
end

local Fade = {}
grind_control.Fade = Fade

function Fade.default(): Fade
	return { just_began = false, elapsed = 0.0, value = 0.0, target = 0.0, step = 0.0, minimum = 0.0, maximum = 0.0 }
end

-- Begin 82BB0A30 supplies the actual queried endpoints and mirrored twist.
function Fade.begin(self: Fade, minimum: number, maximum: number, twist: number): number
	local value = bound(twist, minimum, maximum)
	self.just_began = true
	self.elapsed = 0.0
	self.value = value
	self.target = value
	self.step = 0.0
	self.minimum = minimum
	self.maximum = maximum
	return value
end

-- First Update only clears the latch. dt affects elapsed, NOT twist speed.
function Fade.update(self: Fade, dt: number, intent: number, settings: FadeSettings): number?
	if self.just_began then
		self.just_began = false
		return nil
	end
	self.elapsed = f32(self.elapsed + dt)
	self.target = bound(mul_add(settings.input_scale, intent, self.target), self.minimum, self.maximum)
	local desired = mul_add(f32(1.0 - settings.response), self.value, f32(self.target * settings.response))
	local step = bound(f32(desired - self.value), f32(self.step - settings.acceleration), f32(self.step + settings.acceleration))
	self.step = bound(step, -settings.maximum_step, settings.maximum_step)
	self.value = bound(f32(self.value + self.step), self.minimum, self.maximum)
	return self.value
end

-- S3 always includes physical crouch; S2's optional enable switch is absent.
-- anim_motion/grind_height: min 1760/max 1792/rate 1816; previous starts at Anim+72.
function grind_control.crouch(previous: number, intent: number, grind_crouch: number, minimum: number, maximum: number, rate: number, dt: number): number
	local input = bound(f32(1.0 - intent), minimum, maximum)
	local physical = bound(f32(1.0 - grind_crouch), minimum, maximum)
	local desired = if f32(input - physical) >= 0.0 then physical else input
	local step = f32(dt * rate)
	return bound(desired, f32(previous - step), f32(previous + step))
end

local PI = rt.from_bits(0x40490fdb)

-- Begin 82BB0CBC..CE4: mirror the Skeleton+504 angle exactly once.
function grind_control.mirrored_twist(twist: number, mirrored: boolean): number
	if not mirrored then
		return twist
	end
	return if twist >= 0.0 then f32(PI - twist) else f32(-PI - twist)
end

return grind_control
