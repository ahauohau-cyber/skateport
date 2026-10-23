--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-game/src/input/controllers.rs (коммит 2e16697)
--
-- Persistent platform-input owner. Device collection runs on host frames;
-- this does not choose the skater simulation clock or advance Derived input.

local history_mod = require("../../skate_core/input/history")
local pad_mod = require("../../skate_core/input/pad")
local gameplay_map = require("../../skate_core/input/gameplay_map")
local xbox = require("../../skate_core/input/xbox")
local rt = require("../../rt")
local tick_mod = require("../../skate_core/input/tick")

local HistoryRecord = history_mod.HistoryRecord
local PadHistory = history_mod.PadHistory
local Pad = pad_mod.Pad
local GameplayActions = gameplay_map.GameplayActions
local DEVICE_SLOTS = history_mod.DEVICE_SLOTS

local controllers = {}

-- ROBLOX: enum DeviceError -> { kind = "Disconnected" | "State" | "Capabilities" | "Unavailable", code = number? }.
export type DeviceError = { kind: string, code: number? }

-- ROBLOX: DevicePacket из platform.rs. kind (ControllerKind) — только метаданные;
-- controller_kind.rs в Roblox не переносится (нет XInput/SDL), поэтому kind = nil.
export type DevicePacket = { number: number, state: xbox.XboxState, subtype: number, kind: any? }

-- ROBLOX: Result<DevicePacket, DeviceError> -> { ok = DevicePacket } или { err = DeviceError }.
export type Sample = { ok: DevicePacket?, err: DeviceError? }

-- ROBLOX: enum ControllerStatus -> { kind = "Unpolled" | "Ready" | "Unavailable", error = DeviceError? }.
export type ControllerStatus = { kind: string, error: DeviceError? }

export type RawInput = { buttons: number, triggers: { number }, left: { number }, right: { number } }

local function raw_default(): RawInput
	return { buttons = 0, triggers = { 0, 0 }, left = { 0, 0 }, right = { 0, 0 } }
end
controllers.raw_default = raw_default

local function is_ready(s: ControllerStatus): boolean
	return s.kind == "Ready"
end

export type ControllerInput = {
	raw: { RawInput },
	cache: { { history_mod.HistoryRecord } },
	active: number,
	history: history_mod.PadHistory,
	pads: { pad_mod.Pad },
	status: { ControllerStatus },
	packet_numbers: { number | false },
	-- Identity of each slot's controller (None while unavailable).
	kinds: { any },
	mapped_actions: { { number } },
	publications: number,
	consumed_batches: number,
	tick: number,
}

local ControllerInput = {}
controllers.ControllerInput = ControllerInput

local function new_pads(): { pad_mod.Pad }
	local pads = {}
	for i = 1, DEVICE_SLOTS do
		pads[i] = Pad.new()
	end
	return pads
end
local function zero_actions(): { { number } }
	local a = {}
	for i = 1, DEVICE_SLOTS do
		a[i] = table.create(18, 0.0)
	end
	return a
end

function ControllerInput.default(): ControllerInput
	local cache = {}
	for c = 1, 2 do
		cache[c] = {}
		for d = 1, DEVICE_SLOTS do
			cache[c][d] = HistoryRecord.new({})
		end
	end
	local raw: { RawInput }, status: { ControllerStatus }, numbers: { number | false }, kinds: { any } = {}, {}, {}, {}
	for d = 1, DEVICE_SLOTS do
		raw[d] = raw_default()
		status[d] = { kind = "Unpolled" }
		numbers[d] = false
		kinds[d] = false
	end
	return {
		raw = raw,
		cache = cache,
		active = 0,
		history = PadHistory.new(),
		pads = new_pads(),
		status = status,
		packet_numbers = numbers,
		kinds = kinds,
		mapped_actions = zero_actions(),
		publications = 0,
		consumed_batches = 0,
		tick = 0,
	}
end

-- ROBLOX: индекс устройства — с нуля, как в Rust (Option<usize> -> число или nil).
local function first_ready(self: ControllerInput): number?
	for i, s in self.status do
		if is_ready(s) then
			return i - 1
		end
	end
	return nil
end

-- Original input.cfg: LB.held && DPadD.pressed / LB.held && DPadU.held.
-- Use the same debounced native Pad publication as ordinary gameplay.
function ControllerInput.session_marker_actions(self: ControllerInput): (boolean, boolean, boolean)
	local device = first_ready(self)
	if device == nil then
		return false, false, false
	end
	local p = self.pads[device + 1]
	if p.count == 0 then
		return false, false, false
	end
	local function flags(i: number): number
		local r = p.records[i + 1]
		return if r then r[2] else 0
	end
	local modifier = bit32.band(flags(8), 0xff00) ~= 0
	return modifier, modifier and bit32.band(flags(1), 0xff000000) ~= 0, modifier and bit32.band(flags(0), 0xff00) ~= 0
end

-- The slot gameplay reads: the first ready one.
function ControllerInput.active_slot(self: ControllerInput): number?
	return first_ready(self)
end

function ControllerInput.kind(self: ControllerInput, slot: number): any?
	local k = self.kinds[slot + 1]
	return if k then k else nil
end

function ControllerInput.raw_input(self: ControllerInput): RawInput
	local i = first_ready(self)
	return if i ~= nil then self.raw[i + 1] else raw_default()
end

-- Replay controls must never queue a flick or a button press for gameplay.
function ControllerInput.discard_gameplay(self: ControllerInput)
	self.history = PadHistory.new()
	self.pads = new_pads()
	self.mapped_actions = zero_actions()
end

-- #[cfg(test)] player_actions
function ControllerInput.player_actions(self: ControllerInput): gameplay_map.GameplayActions
	local device = first_ready(self) or 0
	return GameplayActions.from_pad(self.pads[device + 1])
end

function ControllerInput.tick_input(self: ControllerInput): tick_mod.TickInput
	local device = first_ready(self)
	local actions = if device ~= nil then GameplayActions.from_pad(self.pads[device + 1]) else GameplayActions.from_values(table.create(18, 0.0))
	return tick_mod.TickInput.new(self.tick, actions, device ~= nil)
end

-- TU3 8296D288/8296D0D0: write the inactive cache, publish one four-device
-- batch. Even an unchanged platform packet is sampled; packet-number
-- deduplication would alter native Pad edge/repeat behavior.
function ControllerInput.collect(self: ControllerInput, samples: { Sample })
	local next_ = bit32.bxor(self.active, 1)
	for i = 1, DEVICE_SLOTS do
		local sample = samples[i]
		local packet = sample.ok
		if packet ~= nil then
			local st = packet.state
			-- ROBLOX: f32::from(u8/i16) / 255.0 или / 32768.0 -> rt.f32(деление).
			local f32 = rt.f32
			self.raw[i] = {
				buttons = st.buttons,
				triggers = { f32(st.triggers[1] / 255), f32(st.triggers[2] / 255) },
				left = { f32(st.left[1] / 32768), f32(st.left[2] / 32768) },
				right = { f32(st.right[1] / 32768), f32(st.right[2] / 32768) },
			}
			-- 8296D480 sets byte13 only when capability SubType == 7.
			local values = xbox.convert(st, if packet.subtype == 7 then 1 else 0)
			self.cache[next_ + 1][i] = HistoryRecord.new(values)
			self.packet_numbers[i] = packet.number
			self.kinds[i] = if packet.kind ~= nil then packet.kind else false
			self.status[i] = { kind = "Ready" }
		else
			self.raw[i] = raw_default()
			HistoryRecord.clear_count(self.cache[next_ + 1][i])
			self.packet_numbers[i] = false
			self.kinds[i] = false
			self.status[i] = { kind = "Unavailable", error = sample.err }
		end
	end
	self.active = next_
	PadHistory.publish(self.history, self.cache[self.active + 1])
	self.publications += 1
end

-- TU3 82699230 drains first, then updates each Pad once. The game owns
-- this snapshot for subsequent consumers; Derived timers require the
-- actual actor timestep and state flags and are not driven by render dt.
function ControllerInput.publish_actions(self: ControllerInput): boolean
	-- ROBLOX: wrapping_add для u64 — счётчик в Luau не переполнится за время игры.
	self.tick += 1
	if not PadHistory.drain_to_latest(self.history, self.pads) then
		return false
	end
	for device, p in self.pads do
		local actions = GameplayActions.from_pad(p)
		for i = 0, 17 do
			self.mapped_actions[device][i + 1] = GameplayActions.value(actions, 64 + i)
		end
	end
	self.consumed_batches += 1
	return true
end

return controllers
