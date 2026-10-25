--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/adjust.rs (коммит 2e16697)
--
-- TU3 `PhysicalPlayerHiLOD::Adjust` (`0x82DB6CF0`).
--
-- This phase runs only after the solver completion fence. It publishes the
-- solved board condition, performs the first skeleton adjustment, calls the
-- current state's post-physics slot, then performs the final skeleton update.
-- ROBLOX: trait AdjustServices -> таблица с методами.

local rt = require("../../rt")

local adjust = {}

export type AdjustFields = {
	-- ProcessedPhysIn+2512.
	processed_word_2512: number,
	-- ProcessedPhysIn+2604.
	timestep_2604: number,
	-- SkateboardController+448.
	controller_state_448: number,
	-- Player+1876 output staging +42.
	output_flag_42: boolean,
	-- Player+1876 output staging +144.
	output_scalar_144: number,
	-- Player+1876 output staging +200.
	output_counter_200: number,
}

-- Required object calls in the exact order used by `0x82DB6CF0`.
export type AdjustServices = {
	-- Player vtable `+116`, then SkateboardBody `0x82C02138`.
	board_condition_82c02138: (self: any) -> number,
	-- BoardBody vtable `+4`, byte `+868`. Called only in controller mode 1.
	controller_mode_one_board_flag_868: (self: any) -> boolean,
	-- Skeleton update `0x82BD80D8` with the board flag and frame timestep.
	adjust_skeleton_82bd80d8: (self: any, board_flag: boolean, timestep: number) -> (),
	-- Current physical-state vtable slot `+40`.
	update_current_state_post_physics_vtable_40: (self: any) -> (),
	-- Player helper `0x82DB9100`; its exact result is forwarded unchanged.
	player_output_selector_82db9100: (self: any) -> number,
	-- Final skeleton update `0x82BD83E0`.
	finish_skeleton_adjustment_82bd83e0: (self: any, selector: number) -> (),
}

-- Runs the complete TU3 Adjust wrapper after solver completion.
function adjust.run_adjust(fields: AdjustFields, services: any)
	if services:board_condition_82c02138() == 1 and fields.processed_word_2512 ~= 500 then
		fields.output_flag_42 = true
		fields.output_scalar_144 = 0.0
		fields.output_counter_200 = rt.wrapping_add_u32(fields.output_counter_200, 1)
	end

	local board_flag = if fields.controller_state_448 == 1 then services:controller_mode_one_board_flag_868() else false
	services:adjust_skeleton_82bd80d8(board_flag, fields.timestep_2604)
	services:update_current_state_post_physics_vtable_40()
	local selector = services:player_output_selector_82db9100()
	services:finish_skeleton_adjustment_82bd83e0(selector)
end

return adjust
