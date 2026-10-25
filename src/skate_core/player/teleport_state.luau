--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/teleport_state.rs (коммит 2e16697)
--
-- Teleporting702 from original TU3 VT823272FC.
-- Enter82D431D8, Update82D431F0 and FillPhysOut82D43280.
-- ROBLOX: RawMatrix -> 4 строки по 4 слова; enum Update -> строки
-- "RequestCheckpoint" / "Captured"; Option<Output> -> Output или nil.

local input_types = require("./input_phase/types")

type RawMatrix = input_types.RawMatrix

local teleport_state = {}

export type Target = {
	transform: RawMatrix,
	on_board: boolean,
}

-- RequestCheckpoint: Skeleton16552 virtual36: ask the actor for a reset target.
export type Update = "RequestCheckpoint" | "Captured"

export type Output = {
	transform: RawMatrix,
	next_state: number,
	state_61: number,
	board_272: number,
}

export type TeleportState = {
	target: RawMatrix, -- 48
	ready: boolean, -- 116 bit31
	received: boolean, -- 116 bit30; native serialization retains this bit.
	on_board: boolean, -- 116 bit29
}

local TeleportState = {}
teleport_state.TeleportState = TeleportState

-- ROBLOX: impl Default for TeleportState.
function TeleportState.default(): TeleportState
	return {
		target = { { 0, 0, 0, 0 }, { 0, 0, 0, 0 }, { 0, 0, 0, 0 }, { 0, 0, 0, 0 } },
		ready = false,
		received = false,
		on_board = true,
	}
end

-- Clears only the three lifecycle flags; the retained matrix is unread
-- until Update captures a new target. Native Exit is an empty leaf.
function TeleportState.enter(self: TeleportState)
	self.ready = false
	self.received = false
	self.on_board = true
end

function TeleportState.update(self: TeleportState, flags_2468: number, matrix_1536: RawMatrix, byte_1600: number): Update
	if bit32.band(flags_2468, 2) == 0 then
		return "RequestCheckpoint"
	end
	self.received = true
	-- ROBLOX: копия матрицы (в Rust — Copy).
	self.target = { table.clone(matrix_1536[1]), table.clone(matrix_1536[2]), table.clone(matrix_1536[3]), table.clone(matrix_1536[4]) }
	self.ready = true
	-- rlwimi82D43254 inserts only byte1600 bit0, not a nonzero test.
	self.on_board = bit32.band(byte_1600, 1) ~= 0
	return "Captured"
end

-- This publisher does not clear the output when no target is ready.
function TeleportState.output(self: TeleportState): Output?
	if not self.ready then
		return nil
	end
	local t = self.target
	return {
		transform = { table.clone(t[1]), table.clone(t[2]), table.clone(t[3]), table.clone(t[4]) },
		next_state = if self.on_board then 100 else 500,
		state_61 = 1,
		board_272 = 1,
	}
end

return teleport_state
