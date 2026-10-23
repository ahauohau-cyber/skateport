--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/wipeout_state/contact_response.rs (коммит 2e16697)
--
-- Wipeout82D3EC08's two persistent material responses, 82D91708..82D92440.
-- Each correction writes the actual 23 skater bodies' linear velocities.
-- ROBLOX: приватные fn reject/reject_positive/apply_velocity_delta (super::) —
-- продублированы в material10/material11, иначе круговой require.

local material10 = require("@self/material10")
local material11 = require("@self/material11")

local contact_response = {}

export type ContactResponseInput = {
	-- Original Processed608 snapshot, reused by both helpers before physics.
	com_velocity_608: { number },
	-- SkeletonCollision4079/1168; absence preserves the retained normal.
	material10_normal: { number }?,
	-- SkeletonCollision4080/1184; the helper owns its separate contact latch.
	material11_normal: { number }?,
	-- Original Processed224 (effective animation transform's third axis).
	effective_axis_224: { number },
	-- Original Processed2824/2828, the stock Wipeout control attributes.
	wipeout_control_2824_2828: { number },
}

export type ContactResponseOutput = {
	material10_phase: number,
	-- One-update pulse at first helper2->3, copied to Wipeout572.
	material10_finished_77: boolean,
	-- Second helper's retained byte73; selects caller's collision mode9.
	material11_active_73: boolean,
}

export type ContactResponse = {
	material10: material10.Response,
	material11: material11.Response,
}

local ContactResponse = {}
contact_response.ContactResponse = ContactResponse

function ContactResponse.new(): ContactResponse
	return { material10 = material10.Response.new(), material11 = material11.Response.new() }
end

-- Wipeout Reset82D3B3A8 invokes both resets; byte73 survives the second.
function ContactResponse.reset(self: ContactResponse)
	material10.Response.reset(self.material10)
	material11.Response.reset(self.material11)
end

function ContactResponse.update(self: ContactResponse, body: any, input: ContactResponseInput): ContactResponseOutput
	-- 82D3EC58..5C: state selection precedes the first response's update.
	material10.Response.update(self.material10, body, input.com_velocity_608, input.material10_normal)
	material11.Response.update(self.material11, body, input)
	return {
		material10_phase = self.material10.phase,
		material10_finished_77 = self.material10.finished,
		material11_active_73 = self.material11.active,
	}
end

return contact_response
