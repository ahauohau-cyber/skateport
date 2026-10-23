--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/input/gameplay_gestures.rs (коммит 2e16697)
--
-- Skate 3 TU3 gameplay D-pad gestures, Fill helper 8259BF50.
-- These are emote intents, independent of trick-stick gesture recognition.

local controller = require("./controller")
local riding_intentions = require("./riding_intentions")

local gameplay_gestures = {}

local DIRECTIONS = {
	{ 26, "GestureDownStart", "GestureDownHeld" },
	{ 25, "GestureLeftStart", "GestureLeftHeld" },
	{ 24, "GestureRightStart", "GestureRightHeld" },
	{ 27, "GestureUpStart", "GestureUpHeld" },
}

function gameplay_gestures.produce(ctrl: controller.DerivedControllerInput): { riding_intentions.RidingIntent }
	local words = ctrl.words
	local previous = words[7]
	local current = words[14]
	if bit32.band(current, bit32.bor(bit32.lshift(1, 29), bit32.lshift(1, 28))) ~= 0 then
		return {}
	end
	local out: { riding_intentions.RidingIntent } = {}
	-- The native producer emits all starts before held intents.
	for _, d in DIRECTIONS do
		local mask = bit32.lshift(1, d[1] :: number)
		if bit32.band(current, mask) ~= 0 and bit32.band(previous, mask) == 0 then
			table.insert(out, { name = d[2] :: string, value = 1.0 })
		end
	end
	for _, d in DIRECTIONS do
		local mask = bit32.lshift(1, d[1] :: number)
		if bit32.band(current, mask) ~= 0 then
			table.insert(out, { name = d[3] :: string, value = 1.0 })
		end
	end
	return out
end

return gameplay_gestures
