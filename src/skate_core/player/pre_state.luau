--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/pre_state.rs (коммит 2e16697)
--
-- Complete TU3 `PhysicalPlayerHiLOD::PreState` (`0x82DB6050`).
-- ROBLOX: trait PreStateServices -> таблица с методами; [u32; 18] -> таблица.

local rt = require("../../rt")

local pre_state = {}

-- The 72-byte stack packet filled through current-state vtable slot `+24`.
-- Only the vector at byte `+48` is consumed by the player wrapper, but the
-- entire packet remains part of the state callback contract.
export type PreStatePacket = {
	words: { number },
}

local PreStatePacket = {}
pre_state.PreStatePacket = PreStatePacket

-- ROBLOX: const ZERO -> функция, создающая новый пакет.
function PreStatePacket.zero(): PreStatePacket
	return { words = table.create(18, 0) }
end

function PreStatePacket.vector_48(self: PreStatePacket): { number }
	-- ROBLOX: words[12..16] -> индексы 13..16.
	return { self.words[13], self.words[14], self.words[15], self.words[16] }
end

export type PreStatePlayerFields = {
	-- PhysicalPlayer+1312.
	frame_counter_1312: number,
	-- Whether PhysicalPlayer+1840 owns the optional pre-state component.
	component_1840_present: boolean,
}

export type PreStateSkeletonFields = {
	-- Skeleton+16112.
	predicted_position_16112: { number },
	-- Skeleton+16416.
	predicted_position_set_16416: boolean,
	-- Skeleton+16432 -> nested object +3184.
	nested_flag_3184: boolean,
}

-- Every call made by the wrapper, in native order. There is deliberately no
-- default implementation: state and component behavior must be supplied by
-- their recovered modules.
export type PreStateServices = {
	-- Current-state vtable slot `+24`.
	fill_packet_vtable_24: (self: any, packet: PreStatePacket) -> (),
	-- `0x82D74270`, reached only when Player+1840 is present.
	update_component_1840_82d74270: (self: any) -> (),
	-- Current-state vtable slot `+4`.
	update_before_state_vtable_4: (self: any) -> (),
}

function pre_state.run_pre_state(player: PreStatePlayerFields, skeleton: PreStateSkeletonFields, services: any)
	player.frame_counter_1312 = rt.wrapping_add_u32(player.frame_counter_1312, 1)

	local packet = PreStatePacket.zero()
	services:fill_packet_vtable_24(packet)
	skeleton.predicted_position_16112 = PreStatePacket.vector_48(packet)
	skeleton.predicted_position_set_16416 = true
	skeleton.nested_flag_3184 = false

	if player.component_1840_present then
		services:update_component_1840_82d74270()
	end
	services:update_before_state_vtable_4()
end

return pre_state
