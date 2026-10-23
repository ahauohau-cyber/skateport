--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/input_phase/requests.rs (коммит 2e16697)
--
-- ROBLOX: только типы-записи; RawVector -> таблица из 4 слов (u32).

local requests = {}

export type RawVector = { number }

export type GroundHistoryRequest = {
	previous_position: RawVector,
	current_position: RawVector,
	previous_filtered_delta: RawVector,
	-- Processed +2604. The native block also consumes constants at
	-- `0x82072818` and `0x8231A844`; the service owns those exact values.
	timestep_bits: number,
}

export type GroundHistoryResult = {
	delta: RawVector,
	filtered_delta: RawVector,
}

export type PrepareJumpRequest = {
	skateboard_vector: RawVector,
	previous_velocity: RawVector,
}

return requests
