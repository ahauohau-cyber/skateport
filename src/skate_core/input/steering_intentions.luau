--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/input/steering_intentions.rs (коммит 2e16697)
--
-- Complete local Turn/HardTurn/HardTurnCrouch emission dataflow in 825999F0.
-- Other intention outputs and the subsequent action/motion graphs are separate.

local rt = require("../../rt")
local angle_mod = require("./angle")
local controller = require("./controller")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits
local left_stick_angle = angle_mod.left_stick_angle
local magnitude = controller.magnitude

local steering_intentions = {}

export type SteeringIntentions = {
	-- Absence is retained: native does not emit a zero Turn intention.
	turn: number?,
	hard_turn: number?,
	hard_turn_crouch: number?,
}

local K_40433333 = from_bits(0x40433333)
local K_40166666 = from_bits(0x40166666)
local K_3fb6db6d = from_bits(0x3fb6db6d)
local K_3f666666 = from_bits(0x3f666666)
local K_3fb1eb85 = from_bits(0x3fb1eb85)
local K_3f68f5c3 = from_bits(0x3f68f5c3)
local K_c0055556 = from_bits(0xc0055556)
local K_3a83126f = from_bits(0x3a83126f)
local K_3f59999a = from_bits(0x3f59999a)

-- Consumes the current record after 825992D8 and actor+1908 captured at
-- 82599A38. No history field affects these three local emission sites.
function steering_intentions.produce(left: { number }, actor_flags_1908: number): SteeringIntentions
	local x, y = left[1], left[2]
	local angle = left_stick_angle(x, y)
	local absolute = math.abs(angle)
	local length = if x == 0.0 and y == 0.0 then 0.0 else magnitude(mul_add(y, y, f32(x * x)))
	local signed_length = if x >= 0.0 then length else -length
	local turn
	if y > 0.0 then
		if absolute > K_40433333 then
			turn = 0.0
		elseif absolute > K_40166666 then
			turn = f32(f32(f32(K_40433333 - absolute) * K_3fb6db6d) * signed_length)
		else
			turn = signed_length
		end
	else
		turn = x
	end
	local active = length > K_3f666666 and not (absolute > K_3fb1eb85) and not (absolute < K_3f68f5c3)
	local hard = f32(f32(absolute - K_3fb1eb85) * K_c0055556)
	local minimum = K_3a83126f
	hard = if f32(hard - minimum) >= 0.0 then hard else minimum
	hard = if angle >= 0.0 then hard else -hard
	local allowed = bit32.band(actor_flags_1908, 1) == 0
	return {
		turn = if turn ~= 0.0 and allowed then turn else nil,
		hard_turn = if active and allowed then hard else nil,
		hard_turn_crouch = if active and allowed then math.abs(f32(hard * K_3f59999a)) else nil,
	}
end

return steering_intentions
