--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/commands/mod.rs (коммит 2e16697)
--
-- Typed animation-command storage and recovered workers.

return {
	batch = require("@self/batch"),
	buffers = require("@self/buffers"),
	set_data = require("@self/set_data"),
}
