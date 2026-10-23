--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/input/trick_intentions.rs (коммит 2e16697)
--
-- Player grab and aerial trick-control intents.
--
-- This is the controller half of the TU3 `ActionGraphInputListener::Fill`
-- path.  The listener publishes both grab variants every tick; the authored
-- ActionGraph/MotionGraph decides which one is legal for the current stance.

local rt = require("../../rt")
local controller = require("./controller")

local f32 = rt.f32
local mul_add = rt.mul_add
local from_bits = rt.from_bits

local trick_intentions = {}

export type TrickIntent = { name: string, value: number }

-- Recovered from `ActionGraphInputListener::Fill` (`825fb4c8`/`825999f0`):
-- ground grabs use exact trigger values, while air grabs use positive trigger
-- values.  Dark-catch requests come from the packed action flags, not from
-- gesture timing.
function trick_intentions.produce(ctrl: controller.DerivedControllerInput): { TrickIntent }
	-- ROBLOX: words[k] в Rust -> words[k + 1].
	local words = ctrl.words
	local left_trigger = from_bits(words[12])
	local right_trigger = from_bits(words[13])
	local right_x = from_bits(words[10])
	local right_y = from_bits(words[11])

	-- Fill 825992D8 advances the grab timers only when the trigger action is
	-- exactly 1.0; partial analog values are not a held grab in Skate 3.
	local left_ground = left_trigger == 1.0
	local right_ground = right_trigger == 1.0
	local left_air = left_trigger > 0.0
	local right_air = right_trigger > 0.0

	local output: { TrickIntent } = {}
	local function emit(name: string, value: number)
		table.insert(output, { name = name, value = value })
	end
	if left_ground then
		emit("LeftGroundGrab", 1.0)
	end
	if left_air then
		emit("LeftAirGrab", 1.0)
	end
	if right_ground then
		emit("RightGroundGrab", 1.0)
	end
	if right_air then
		emit("RightAirGrab", 1.0)
	end

	local previous_flags = words[7]
	local current_flags = words[14]
	-- TU3 Fill 8259A9E4..AA54: B publishes Dismount while held and
	-- NewDismount only on its rising edge. No grab/state/actor gate here;
	-- the authored graphs decide whether this means dismount or no-foot air.
	-- Names: 82F84B20 -> 830BE378, 82F84B08 -> 830C07AC.
	local dismount_button = bit32.lshift(1, 20)
	if bit32.band(current_flags, dismount_button) ~= 0 then
		emit("Dismount", 1.0)
		if bit32.band(previous_flags, dismount_button) == 0 then
			emit("NewDismount", 1.0)
		end
	end
	local dark_flags = bit32.bor(bit32.lshift(1, 20), bit32.lshift(1, 28))
	if bit32.band(current_flags, dark_flags) ~= 0 then
		emit("DarkCatch", 1.0)
	end
	if bit32.band(current_flags, dark_flags) ~= 0 and bit32.band(previous_flags, dark_flags) == 0 then
		emit("NewDarkCatch", 1.0)
	end
	-- Fill 825999F0 publishes the board-adjust pair from the same normalized
	-- stick vector used by the authored air board-adjust states.  The native
	-- 82599B08..BB4: v125 = -RStickY is the denominator and v126 =
	-- RStickX is the numerator. The quadrant correction also tests -RStickY.
	-- This is atan2(RStickX, -RStickY), in that argument order.
	-- ROBLOX: f32::sqrt -> f32(math.sqrt) (корень округляется корректно).
	local board_adjust_magnitude = f32(math.sqrt(mul_add(right_x, right_x, f32(right_y * right_y))))
	if board_adjust_magnitude > 0.0 then
		-- ROBLOX: f32::atan2 -> rt.atan2f (fdlibm atan2f, как libm эталона).
		emit("BoardAdjustAngle", rt.atan2f(right_x, -right_y))
		emit("BoardAdjustMag", board_adjust_magnitude)
	end
	if right_x ~= 0.0 then
		emit("TweakX", right_x)
	end
	if right_y ~= 0.0 then
		emit("TweakY", right_y)
	end
	-- Fill 8259A554/8259AF60: current packed bit28 (RB), without an actor gate.
	-- The stock ground graph attaches GrabWorld; physics selects valid coping.
	if bit32.band(current_flags, bit32.lshift(1, 28)) ~= 0 then
		emit("GrabWorld", 1.0)
	end
	-- Fill calls 8259BB18 with the CURRENT RawControllerInput (words 7..13).
	-- Descriptor constructors 82F84F28..82F84F98 establish these five names.
	if right_x ~= 0.0 then
		emit("HandPlantTweakX", right_x)
	end
	if right_y ~= 0.0 then
		emit("HandPlantTweakY", right_y)
	end
	for _, pair in { { 20, "HandPlantDismount" }, { 21, "HandPlantOneFootRight" }, { 23, "HandPlantOneFootLeft" } } do
		if bit32.band(current_flags, bit32.lshift(1, pair[1] :: number)) ~= 0 then
			emit(pair[2] :: string, 1.0)
		end
	end
	return output
end

return trick_intentions
