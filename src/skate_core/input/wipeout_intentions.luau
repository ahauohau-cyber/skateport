--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/input/wipeout_intentions.rs (коммит 2e16697)
--
-- Wipeout intention helper 8259BC28, called by Fill 825999F0 at 8259AA6C.
-- Uses the existing evaluated stock action map and completed output flags.

local rt = require("../../rt")
local controller = require("./controller")
local riding_intentions = require("./riding_intentions")

local from_bits = rt.from_bits

local wipeout_intentions = {}

function wipeout_intentions.produce(ctrl: controller.DerivedControllerInput, actor_flags_1908: number, physical_flags_204: number): { riding_intentions.RidingIntent }
	local words = ctrl.words
	local old_buttons = words[7]
	local buttons = words[14]
	local function axis(slot: number): number
		return from_bits(words[slot + 1])
	end
	local function rising(b: number): boolean
		return bit32.band(old_buttons, bit32.lshift(1, b)) == 0 and bit32.band(buttons, bit32.lshift(1, b)) ~= 0
	end
	local function trigger_edge(previous: number, current: number): boolean
		return axis(previous) ~= 1.0 and axis(current) == 1.0
	end
	local output: { riding_intentions.RidingIntent } = {}
	local function emit(name: string, value: number)
		table.insert(output, { name = name, value = value })
	end

	-- 8259BC7C..BCEC: both names always exist, including disabled/centered zeros.
	local gesture = bit32.band(physical_flags_204, 0x80) ~= 0
	emit("WipeoutGestureX", if gesture then axis(9) else 0.0)
	emit("WipeoutGestureY", if gesture then axis(10) else 0.0)
	local control = bit32.band(physical_flags_204, 0x100) ~= 0
	local x = if control then axis(7) else 0.0
	local y = if control then axis(8) else 0.0
	if x ~= 0.0 then
		emit("WipeoutControlX", x)
	end
	if y ~= 0.0 then
		emit("WipeoutControlY", y)
	end
	-- 8259BD28..BDBC: raw rising edges, not push repeat timers or held buttons.
	if rising(21) or rising(23) then
		emit("WipeOutRecover", 1.0)
	end
	-- 8259BDCC..BEF0: exact full trigger endpoints, both stick buttons, and
	-- a fresh edge from any of the four; actor disable bit6 gates this request.
	if
		bit32.band(actor_flags_1908, 0x40) == 0
		and axis(11) == 1.0
		and axis(12) == 1.0
		and bit32.band(buttons, 0xC0000000) == 0xC0000000
		and (trigger_edge(4, 11) or trigger_edge(5, 12) or rising(31) or rising(30))
	then
		emit("WipeOutRequest", 1.0)
	end
	-- 8259BEFC..BF3C: only the second trigger's new full endpoint.
	if bit32.band(physical_flags_204, 0x40) ~= 0 and trigger_edge(5, 12) then
		emit("WipeOutPushOff", 1.0)
	end
	return output
end

return wipeout_intentions
