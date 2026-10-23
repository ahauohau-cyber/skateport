--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/riding/grounded/state/mod.rs (коммит 2e16697)
--
-- Readable composition of the TU3 `PhysState_PhysicsGround` lifecycle.
--
-- This module owns native state order. Collision queries, skeleton writes and
-- other engine objects remain required interfaces; no branch has a no-op
-- implementation.
-- ROBLOX: ordinary в Rust приватный (mod ordinary) — здесь не экспортируется.

local data = require("@self/data")

return {
	board = require("@self/board"),
	board_types = require("@self/board_types"),
	contact_state = require("@self/contact_state"),
	corrections = require("@self/corrections"),
	data = data,
	lifecycle = require("@self/lifecycle"),
	motion = require("@self/motion"),
	output = require("@self/output"),
	post_physics = require("@self/post_physics"),
	update = require("@self/update"),
	GroundContactHistory = data.GroundContactHistory,
	PhysicsGroundState = data.PhysicsGroundState,
}
