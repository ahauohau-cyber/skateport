--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/post_output.rs (коммит 2e16697)
--
-- TU3 `PhysicalPlayerHiLOD::PostOutput` (`0x82DB6CB0`).
--
-- This is the final player-owned phase before the world finishes output and
-- conditioners. The native body performs exactly two calls in this order.
-- ROBLOX: trait PostOutputServices -> таблица с методами.

local post_output = {}

-- Opaque Player+1392-owned object passed to `0x82909510`.
--
-- Its internal layout is deliberately absent: PostOutput only passes its
-- address and the fixed native arguments `0` and `-1`.
-- ROBLOX: unit struct -> пустая таблица (передаётся как ссылка).
export type PlayerOutputField1392 = {}

-- Required services called by the complete `0x82DB6CB0` wrapper.
export type PostOutputServices = {
	-- `0x82909510(Player+1392, 0, -1)`.
	finish_player_output_82909510: (self: any, player_field_1392: PlayerOutputField1392) -> (),
	-- `0x82BE2BA8(Player->Skeleton)`.
	finish_skeleton_output_82be2ba8: (self: any) -> (),
}

-- Runs the complete TU3 PostOutput phase.
function post_output.run_post_output(player_field_1392: PlayerOutputField1392, services: any)
	services:finish_player_output_82909510(player_field_1392)
	services:finish_skeleton_output_82be2ba8()
end

return post_output
