--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/startup/mod.rs (коммит 2e16697)
--
-- Recovered TU3 board reset operations. Caller-owned spawn selection, state
-- transitions and activation are separate from resetting these native records.

local reset = require("@self/reset")
local skateboard = require("@self/skateboard")

return {
	reset_board_body = reset.reset_board_body,
	reset_collision_info = reset.reset_collision_info,
	reset_skateboard = skateboard.reset_skateboard,
}
