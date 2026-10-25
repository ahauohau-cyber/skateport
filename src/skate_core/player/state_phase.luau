--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/state_phase.rs (коммит 2e16697)
--
-- TU3 `PhysicalPlayerHiLOD::State` wrapper (`0x82DB6120`).
--
-- State bodies, skateboard-controller modes, the board force queue, and the
-- board's fixed-step cache are separate recovered systems. This module owns
-- their exact wrapper order and Player+1344 accumulation.
-- ROBLOX: trait StatePhaseServices -> таблица с методами.

local rt = require("../../rt")

local state_phase = {}

export type StatePhaseFields = {
	-- PhysicalPlayer+1344.
	elapsed_1344: number,
	-- ProcessedPhysIn+2604.
	timestep_2604: number,
	-- SkateboardController+448.
	controller_state_448: number,
	-- SkateboardController+452.
	controller_system_on_452: boolean,
}

-- Calls made by `0x82DB6120`. Implementors must connect each method to the
-- corresponding recovered system; no fallback behavior is defined here.
export type StatePhaseServices = {
	-- Current-state vtable slot `+8`.
	update_current_state_vtable_8: (self: any) -> (),
	update_controller_82d75f00: (self: any) -> (),
	update_controller_mode_1_82d751d8: (self: any) -> (),
	update_controller_mode_2_82d750f0: (self: any) -> (),
	update_controller_mode_3_82d75bb8: (self: any) -> (),
	update_controller_mode_4_82d75d58: (self: any) -> (),
	-- First Player vtable `+116` lookup at `0x82DB61C4`.
	touch_skateboard_vtable_116: (self: any) -> (),
	-- Second Player vtable `+116` lookup followed by `0x82C03718`.
	apply_skateboard_force_queue_82c03718: (self: any) -> (),
	-- Third Player vtable `+116` lookup and the fixed-`1/60` VMX cache update
	-- at `0x82DB61F0..0x82DB62D0`.
	update_skateboard_fixed_step_cache_82db61f0: (self: any) -> (),
}

function state_phase.run_state_phase(fields: StatePhaseFields, services: any)
	services:update_current_state_vtable_8()

	if fields.controller_system_on_452 then
		services:update_controller_82d75f00()
		local mode = fields.controller_state_448
		if mode == 1 then
			services:update_controller_mode_1_82d751d8()
		elseif mode == 2 then
			services:update_controller_mode_2_82d750f0()
		elseif mode == 3 then
			services:update_controller_mode_3_82d75bb8()
		elseif mode == 4 then
			services:update_controller_mode_4_82d75d58()
		end
	end

	services:touch_skateboard_vtable_116()
	services:apply_skateboard_force_queue_82c03718()
	services:update_skateboard_fixed_step_cache_82db61f0()
	fields.elapsed_1344 = rt.f32(fields.elapsed_1344 + fields.timestep_2604)
end

return state_phase
