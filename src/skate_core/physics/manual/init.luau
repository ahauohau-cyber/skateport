--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/manual.rs (коммит 2e16697)
--
-- Source-grounded manual-balance controller units (TU3 82C047F0).
-- Complete gameplay integration and numerical dependencies are tracked in
-- docs/agents/overnight/gameplay.md.
-- ROBLOX: в Rust файл только объявляет подмодули.

return {
	angle = require("@self/angle"),
	controller = require("@self/controller"),
	settings = require("@self/settings"),
	state = require("@self/state"),
}
