--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/foot_ik/mod.rs (коммит 2e16697)
--
-- Native skeleton IK, TU3 GeneralUpdate82BDCA38 and its six update stages.
-- ROBLOX: `pub use math::{...}` -> поля таблицы модуля; math и physical_solve
-- в Rust приватные, здесь доступны как обычные подмодули.

local m = require("@self/math")

return {
	blend = require("@self/blend"),
	contact = require("@self/contact"),
	drive = require("@self/drive"),
	external = require("@self/external"),
	physical_solve = require("@self/physical_solve"),
	post_contact = require("@self/post_contact"),
	post_physics = require("@self/post_physics"),
	math = m,
	interpolate_affine = m.interpolate_affine,
	inverse_affine = m.inverse_affine,
	interpolate_native = m.interpolate,
	settings = require("@self/settings"),
	state = require("@self/state"),
	status = require("@self/status"),
	transforms = require("@self/transforms"),
	two_bone = require("@self/two_bone"),
}
