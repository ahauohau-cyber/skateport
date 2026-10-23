--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/input/anticipation_intentions.rs (коммит 2e16697)
--
-- Right-stick anticipation publication, Fill 825999F0:
-- angle/magnitude 82599AD0..9C4C, emissions 8259AD0C..AD40.

local rt = require("../../rt")
local angle_mod = require("./angle")
local controller = require("./controller")
local riding_intentions = require("./riding_intentions")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits

local anticipation_intentions = {}

function anticipation_intentions.produce(ctrl: controller.DerivedControllerInput): { riding_intentions.RidingIntent }
	local words = ctrl.words
	local x = from_bits(words[10])
	local y = from_bits(words[11])
	if x == 0.0 and y == 0.0 then
		return {}
	end
	-- Unlike steering, these two records have no actor 1908 bit gate.
	return {
		{ name = "AnticMag", value = controller.magnitude(mul_add(x, x, f32(y * y))) },
		{ name = "AnticAngle", value = angle_mod.left_stick_angle(x, y) },
	}
end

return anticipation_intentions
