--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/graph/mod.rs (коммит 2e16697)
--
-- Recovered generic graph operations. Stock topology is supplied as data.

return {
	activation = require("@self/activation"),
	conditions = require("@self/conditions"),
	controller = require("@self/controller"),
	expression = require("@self/expression"),
	intent_handlers = require("@self/intent_handlers"),
	intents = require("@self/intents"),
	selection = require("@self/selection"),
}
