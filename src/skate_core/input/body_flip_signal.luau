--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/input/body_flip_signal.rs (коммит 2e16697)
--
-- BodyFlippingSignal 82BA3380/33B8/35E0/3790. Both windows update on
-- every call before deciding whether to create or remove the motion intent.

local rt = require("../../rt")

local f32 = rt.f32

local body_flip_signal = {}

export type Settings = {
	-- anim_motion.extend_bodyflip_gesture and extend_takeoff_point.
	gesture_window: number,
	takeoff_window: number,
}

export type State = {
	gesture_time: number,
	takeoff_time: number,
	-- Ordered native keys 830C01B4 then 830BE3A8. None is the constructor's
	-- null name. The host binds their recovered text to its intent storage.
	-- ROBLOX: Option<usize> -> индекс с нуля или nil.
	selected: number?,
}

local State = {}
body_flip_signal.State = State

function State.default(): State
	return { gesture_time = 0.0, takeoff_time = 0.0, selected = nil }
end

function State.begin(self: State, settings: Settings)
	self.gesture_time = settings.gesture_window
	self.takeoff_time = settings.takeoff_window
end

local function cap(value: number, limit: number): number
	return if f32(value - limit) >= 0.0 then limit else value
end

-- Some(index) sets only that intent to 1. None removes BOTH keys.
-- Incoming intentions are tested for presence, not their scalar value.
-- ROBLOX: present: [bool; 2] -> { bool, bool }.
function State.update(self: State, present: { boolean }, filtered_category: number, dt: number, settings: Settings): number?
	local index = if present[1] then 0 elseif present[2] then 1 else nil
	if index ~= nil then
		self.gesture_time = 0.0
		self.selected = index
	else
		self.gesture_time = cap(f32(self.gesture_time + dt), settings.gesture_window)
	end
	local gesture = self.gesture_time < settings.gesture_window
	self.takeoff_time = if filtered_category == 2 then cap(f32(self.takeoff_time + dt), settings.takeoff_window) else 0.0
	local takeoff = not (self.takeoff_time <= 0.0) and self.takeoff_time < settings.takeoff_window
	return if gesture and takeoff then self.selected else nil
end

return body_flip_signal
