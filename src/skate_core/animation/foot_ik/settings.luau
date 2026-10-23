--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/foot_ik/settings.rs (коммит 2e16697)
--
-- Authored IK parameters, resolved against the stock class layout.

local status = require("./status")
local two_bone = require("./two_bone")

local settings = {}

export type Settings = {
	-- physics_animation/default layout876/880, consumed by82BF0FA8.
	angle_limits: two_bone.AngleLimits,
	blend: status.BlendSettings,
	-- physics_skeletonik layout0/48/64/80.
	post_ik_padding: { number },
	contact_bounds: { number },
	foot_on_deck_padding: { number },
	wipeout_feet_offset: number,
	--82BED418 retrieves physicsdeck hashes EE1FD008/1DCB828B/932190E7.
	deck_half_width: number,
	deck_half_length: number,
	deck_total_half_length: number,
	-- physicsdeck.DeckFrontEndAngle, hashF9B732CA; retained authored degrees.
	deck_front_angle_degrees: number,
}

return settings
