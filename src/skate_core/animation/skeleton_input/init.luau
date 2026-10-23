--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/skeleton_input/mod.rs (коммит 2e16697)
--
-- Concrete Skeleton animation-attribute consumers. These do not replace the
-- remaining ProcessInput and ProcessData pose/IK stages.

return {
	catalog = require("@self/catalog"),
	name = require("@self/name"),
	scalar_attributes = require("@self/scalar_attributes"),
	contact_events = require("@self/contact_events"),
	extended_attributes = require("@self/extended_attributes"),
	attribute_finalization = require("@self/attribute_finalization"),
	process_attributes = require("@self/process_attributes"),
}
