--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/riding/grounded/mod.rs (коммит 2e16697)
--
-- Recovered grounded producer units; the complete ground state is not ported.
-- ROBLOX: в Rust файл только объявляет подмодули.

return {
	drag = require("@self/drag"),
	manual_entry = require("@self/manual_entry"),
	mode = require("@self/mode"),
	propulsion = require("@self/propulsion"),
	state = require("@self/state"),
}
