--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/input/manual_intentions.rs (коммит 2e16697)
--
-- TU3 Fill 825999F0 -> manual producer 8259BA28, after Derived input.

local rt = require("../../rt")
local controller = require("./controller")
local riding_intentions = require("./riding_intentions")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits

local manual_intentions = {}

local THRESHOLD = from_bits(0x3f666666)
local SCALE = from_bits(0x411ffffe)

-- Continuous Manual/ManualBrake belong to the input listener. The authored
-- graphs own engagement time, allowed states, balance and animation selection.
function manual_intentions.produce(ctrl: controller.DerivedControllerInput, actor_flags: number): { riding_intentions.RidingIntent }
	local intents: { riding_intentions.RidingIntent } = {}
	if bit32.band(actor_flags, bit32.lshift(1, 9)) ~= 0 then
		return intents
	end
	local words = ctrl.words
	local x, y = from_bits(words[10]), from_bits(words[11])
	-- Fill 82599BC8..9C40: x*x + rounded(y*y), then two rsqrt refinements.
	local length = controller.magnitude(mul_add(x, x, f32(y * y)))
	if y ~= 0.0 then
		table.insert(intents, { name = "Manual", value = if y > 0.0 then length else -length })
	end
	-- Original constants 820997B8/822F9274; strictly greater, independent
	-- of the Manual presence gate. A horizontal stick can emit ManualBrake.
	if length > THRESHOLD then
		local brake = f32(f32(length - THRESHOLD) * SCALE)
		table.insert(intents, { name = "ManualBrake", value = if y > 0.0 then brake else -brake })
	end
	return intents
end

return manual_intentions
