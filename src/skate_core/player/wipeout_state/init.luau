--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/wipeout_state/mod.rs (коммит 2e16697)
--
-- Original physical WipeoutGround300 and its internal air control.
-- ROBLOX: impl State из output.rs/recovery.rs -> функции в модулях output/recovery.

local data = require("@self/data")

return {
	State = data.State,
	drives = require("@self/drives"),
	skeleton = require("@self/skeleton"),
	body = require("@self/body"),
	contact_response = require("@self/contact_response"),
	control_air = require("@self/control_air"),
	control_ground = require("@self/control_ground"),
	control_profile_air = require("@self/control_profile_air"),
	math = require("@self/math"),
	orientation = require("@self/orientation"),
	output = require("@self/output"),
	profiles = require("@self/profiles"),
	recovery = require("@self/recovery"),
	response = require("@self/response"),
	torque = require("@self/torque"),
	weights = require("@self/weights"),
}
