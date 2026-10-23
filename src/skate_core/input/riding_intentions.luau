--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/input/riding_intentions.rs (коммит 2e16697)
--
-- Push, brake, body-spin, steering, kick-turn, crouch, powerslide and world-grab intents
-- from the TU3 ActionGraph input listener (`825999F0`).

local rt = require("../../rt")
local angle_mod = require("./angle")
local controller = require("./controller")
local steering_intentions = require("./steering_intentions")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local left_stick_angle = angle_mod.left_stick_angle
local magnitude = controller.magnitude

local riding_intentions = {}

export type PushPreferences = {
	-- Profile component+52, byte58. The host owns profile storage/selection.
	automatic_push_enabled: boolean,
	-- Profile component+56, byte156 selects the automatic push foot.
	automatic_push_right: boolean,
}

function riding_intentions.default_push_preferences(): PushPreferences
	return { automatic_push_enabled = false, automatic_push_right = false }
end

export type RidingIntent = { name: string, value: number }

local PI = from_bits(0x40490fdb)
local HALF_PI = from_bits(0x3fc90fdb)
local F03 = f32(0.3)
local F06 = f32(0.6)
local F08 = f32(0.8)
local F09 = f32(0.89999998)
local F091 = f32(0.91000003)
local SLIDE_SCALE = f32(0.28004956)
local CROUCH_START = from_bits(0x3ff5c28f) -- 1.92
local CROUCH_END = from_bits(0x40166666) -- 2.35
local CROUCH_SLOPE = from_bits(0x4014d655)

local function bit(n: number): number
	return bit32.lshift(1, n)
end

function riding_intentions.produce(ctrl: controller.DerivedControllerInput, actor_flags: number, preferences: PushPreferences): { RidingIntent }
	-- ROBLOX: words[k] в Rust -> words[k + 1].
	local words = ctrl.words
	local previous = words[7]
	local current = words[14]
	local left = { from_bits(words[8]), from_bits(words[9]) }
	local allowed = bit32.band(actor_flags, bit(11)) == 0
	local function held(b: number): boolean
		return bit32.band(current, bit(b)) ~= 0 and allowed
	end
	local function new(b: number, timer: number): boolean
		return held(b) and (bit32.band(previous, bit(b)) == 0 or from_bits(words[timer + 1]) < F03)
	end
	local right = held(21)
	local left_push = held(23)
	local new_right = new(21, 20)
	local new_left = new(23, 22)
	local angle = left_stick_angle(left[1], left[2])
	local from_forward = if angle >= 0.0 then f32(PI - angle) else f32(-PI - angle)
	local length = magnitude(mul_add(left[2], left[2], f32(left[1] * left[1])))
	if preferences.automatic_push_enabled and allowed and not (right or left_push or new_right or new_left) and math.abs(from_forward) < F06 and length > F08 then
		if preferences.automatic_push_right then
			right = true
			new_right = true
		else
			left_push = true
			new_left = true
		end
	end
	if bit32.band(actor_flags, bit(6)) ~= 0 and (right or new_right) and (left_push or new_left) then
		right = false
		left_push = false
		new_right = false
		new_left = false
	end
	local output: { RidingIntent } = {}
	local function emit(name: string, value: number)
		table.insert(output, { name = name, value = value })
	end
	if bit32.band(current, bit(20)) ~= 0 and bit32.band(actor_flags, bit(7)) == 0 then
		emit("Brake", 1.0)
	end
	if new_right or new_left then
		emit("NewPush", 1.0)
	end
	if right then
		emit("RightPush", 1.0)
		emit("Pushing", 1.0)
	end
	if left_push then
		emit("LeftPush", 1.0)
		emit("Pushing", 1.0)
	end
	-- 8259AC1C..AC54 emits this ordered pair from current left X. Actor 1908
	-- bit1 gates both; steering's bit0 and the physical state do not gate it.
	-- BodySpin's later animation-attribute handler owns its sign conversion.
	if left[1] ~= 0.0 and bit32.band(actor_flags, bit(1)) == 0 then
		emit("BodySpin", left[1])
		emit("PhysBodySpin", left[1])
	end
	-- 8259ACDC..ACE8 selects KickTurn from current left X, not shaped Turn.
	if left[1] ~= 0.0 and bit32.band(actor_flags, 1) == 0 then
		emit("KickTurn", left[1])
	end
	local steering = steering_intentions.produce(left, actor_flags)
	if steering.hard_turn_crouch ~= nil then
		emit("HardTurnCrouch", steering.hard_turn_crouch)
	end
	if steering.hard_turn ~= nil then
		emit("HardTurn", steering.hard_turn)
	end
	-- 8259A398..A424, emission key 8259AE30..AE3C: the stick-based crouch ramp is
	-- multiplied by literal zero (f24). The two fsel instructions select the
	-- MAXIMUM of that result and the two trigger values, not a subtraction.
	-- An active gate can therefore intentionally emit Crouch with value zero.
	local absolute = math.abs(angle)
	local ramp
	if absolute <= CROUCH_START then
		ramp = 0.0
	elseif absolute < CROUCH_END then
		ramp = f32(f32(f32(absolute - CROUCH_START) * CROUCH_SLOPE) * length)
	else
		ramp = length
	end
	local stick_crouch = f32(ramp * 0.0)
	local left_trigger, right_trigger = from_bits(words[12]), from_bits(words[13])
	if absolute > CROUCH_START or left_trigger > 0.0 or right_trigger ~= 0.0 then
		local trigger = if f32(left_trigger - right_trigger) >= -0.0 then left_trigger else right_trigger
		emit("Crouch", if f32(stick_crouch - trigger) >= -0.0 then stick_crouch else trigger)
	end
	if steering.turn ~= nil then
		emit("Turn", steering.turn)
	end

	-- 8259A430..A50C: start queries and continuous values have distinct open
	-- heading windows. Both continuous descriptors can be present together.
	-- 8259AECC..AF5C gates only actor bit8, independently of push inhibition.
	if bit32.band(actor_flags, bit(8)) == 0 and length > F09 then
		if angle > 0.0 and angle < F091 then
			emit("RightSlideStart", 1.0)
		end
		if angle > -F091 and angle < 0.0 then
			emit("LeftSlideStart", 1.0)
		end
		if angle > -2.0 and angle < HALF_PI then
			emit("LeftSlide", -f32(f32(angle + 2.0) * SLIDE_SCALE))
		end
		if angle > -HALF_PI and angle < 2.0 then
			emit("RightSlide", f32(f32(2.0 - angle) * SLIDE_SCALE))
		end
	end
	-- 8259A54C/554 reads current raw flags bit28; 8259AF68..7C emits
	-- GrabWorld (830BE780, named by initializer 82F84EB0) while held.
	-- No actor inhibition or rising-edge gate applies to this intention.
	if bit32.band(current, bit(28)) ~= 0 then
		emit("GrabWorld", 1.0)
	end
	return output
end

return riding_intentions
