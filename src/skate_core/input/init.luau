--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/input/mod.rs (коммит 2e16697)
--
-- Native input publication. Controller/graph producers remain separate stages.

return {
	angle = require("@self/angle"),
	gesture = require("@self/gesture"),
	anticipation_intentions = require("@self/anticipation_intentions"),
	animation_packet = require("@self/animation_packet"),
	controller = require("@self/controller"),
	gameplay_map = require("@self/gameplay_map"),
	tick = require("@self/tick"),
	graph_intents = require("@self/graph_intents"),
	grind_intentions = require("@self/grind_intentions"),
	history = require("@self/history"),
	pad = require("@self/pad"),
	power_sliding = require("@self/power_sliding"),
	riding_intentions = require("@self/riding_intentions"),
	manual_intentions = require("@self/manual_intentions"),
	trick_intentions = require("@self/trick_intentions"),
	set_turning = require("@self/set_turning"),
	steering_intentions = require("@self/steering_intentions"),
	turn_conditioner = require("@self/turn_conditioner"),
	turn_remap = require("@self/turn_remap"),
	xbox = require("@self/xbox"),
	body_flip_signal = require("@self/body_flip_signal"),
	wipeout_intentions = require("@self/wipeout_intentions"),
	offboard_intentions = require("@self/offboard_intentions"),
	gameplay_gestures = require("@self/gameplay_gestures"),
}
