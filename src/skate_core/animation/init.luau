--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/mod.rs (коммит 2e16697)
--
-- Animation timing and event semantics recovered from Skate 3 TU3.

return {
	foot_ik = require("@self/foot_ik"),
	clip_clock = require("@self/clip_clock"),
	commands = require("@self/commands"),
	output = require("@self/output"),
	skeleton_input = require("@self/skeleton_input"),
	playback = require("@self/playback"),
	playback_parameters = require("@self/playback_parameters"),
	playback_clip = require("@self/playback_clip"),
	playback_attributes = require("@self/playback_attributes"),
	playback_tree = require("@self/playback_tree"),
	phase_blend = require("@self/phase_blend"),
	pose_blend = require("@self/pose_blend"),
	playback_transition = require("@self/playback_transition"),
	crouching = require("@self/crouching"),
	grind_control = require("@self/grind_control"),
	pose_sample = require("@self/pose_sample"),
	pose_trajectory = require("@self/pose_trajectory"),
	pose_add = require("@self/pose_add"),
	pose_mirror = require("@self/pose_mirror"),
	body_tilt = require("@self/body_tilt"),
	air_leg_extension = require("@self/air_leg_extension"),
	landing_quality = require("@self/landing_quality"),
	riding_fakie = require("@self/riding_fakie"),
	channel_playback = require("@self/channel_playback"),
	pumping_channel = require("@self/pumping_channel"),
	physical_feedback = require("@self/physical_feedback"),
	ground_acceleration = require("@self/ground_acceleration"),
	vbr = require("@self/vbr"),
	kickturn = require("@self/kickturn"),
	manual = require("@self/manual"),
	intent_filter = require("@self/intent_filter"),
	posture = require("@self/posture"),
	bump = require("@self/bump"),
}
