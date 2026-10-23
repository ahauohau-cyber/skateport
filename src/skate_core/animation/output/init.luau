--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/output/mod.rs (коммит 2e16697)
--
-- Native TU3 pose-output kernels. These do not evaluate clips or choose graphs.
-- ROBLOX: NativeMatrix — [[f32; 4]; 4] (тип в ./sqt). PoseBufferError —
-- { kind = "NonFiniteWeight" | "InvalidQuaternion" | "CountOverflow" | "ShortInput"
-- | "ShortOutput" | "ShortParents" | "InvalidCacheOffset" | "InvalidParent", bone?, parent? }.

local sqt = require("@self/sqt")
local hierarchy = require("@self/hierarchy")

export type NativeMatrix = sqt.NativeMatrix
export type Sqt = sqt.Sqt

return {
	actor_packet = require("@self/actor_packet"),
	attributes = require("@self/attributes"),
	intents = require("@self/intents"),
	motion_graph_packet = require("@self/motion_graph_packet"),
	packet_reset = require("@self/packet_reset"),
	physics_packet = require("@self/physics_packet"),
	setup_physics = require("@self/setup_physics"),
	-- pub use hierarchy::{compose_hierarchy, compose_hierarchy_in_place};
	compose_hierarchy = hierarchy.compose_hierarchy,
	compose_hierarchy_in_place = hierarchy.compose_hierarchy_in_place,
	-- pub use sqt::{Sqt, sqt_to_local, sqt_to_matrix};
	sqt_to_local = sqt.sqt_to_local,
	sqt_to_matrix = sqt.sqt_to_matrix,
}
