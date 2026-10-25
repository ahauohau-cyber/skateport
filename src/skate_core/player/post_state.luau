--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/post_state.rs (коммит 2e16697)
--
-- TU3 `PhysicalPlayerHiLOD::PostState` thunk (`0x82DB62F8`).
--
-- Raw instructions load Player+1796 and tail-call the current physical
-- state's vtable slot `+12`. The function has no other side effects.
-- ROBLOX: trait PostStateServices -> таблица с методом (services:method()).

local post_state = {}

-- Mandatory current-state dispatch performed by `0x82DB62F8`.
export type PostStateServices = {
	update_current_state_vtable_12: (self: any) -> (),
}

-- Runs the complete PhysicalPlayer PostState phase.
function post_state.run_post_state(services: any)
	services:update_current_state_vtable_12()
end

return post_state
