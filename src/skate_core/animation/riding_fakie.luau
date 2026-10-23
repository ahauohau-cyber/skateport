--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/riding_fakie.rs (коммит 2e16697)
--
-- UpdateRidingFakie 82BB2330. The two persistent clocks belong to the graph
-- instance, so re-entering another leaf does not restart them.

local rt = require("../../rt")
local native_arithmetic = require("../physics/native_arithmetic")

local f32 = rt.f32

local riding_fakie = {}

export type Settings = { high_speed: number, low_speed: number, slowly_backwards_seconds: number, after_teleport_seconds: number }

export type Physical = {
	category: number,
	grind_state: number,
	doing_trick: boolean,
	-- PhysOutSkeleton+0, as produced by Skeleton::GetData.
	board_axis: { number },
	deck_velocity: { number },
	-- PhysOut bundle+36, used outside filtered Ground category.
	external_velocity: { number },
	ground_projected_speed: number,
}

export type State = { slowly_backwards: number, after_teleport: number }

local State = {}
riding_fakie.State = State

function State.default(): State
	return { slowly_backwards = 0.0, after_teleport = 0.0 }
end

-- None preserves the existing fakie flag during grounded/air trick execution.
function State.update(self: State, physical: Physical, dt: number, settings: Settings): boolean?
	local eligible
	if physical.category == 5 then
		self.after_teleport = 0.0
		eligible = false
	else
		eligible = self.after_teleport > settings.after_teleport_seconds
		self.after_teleport = f32(self.after_teleport + dt)
	end
	if not eligible then
		self.slowly_backwards = 0.0
		return false
	end
	local cat = physical.category
	local allowed = (cat == 1 or cat == 2 or (cat == 6 and physical.grind_state == 503)) and not physical.doing_trick
	if not allowed then
		self.slowly_backwards = 0.0
		if cat == 1 or cat == 2 then
			return nil
		end
		return false
	end
	local velocity = if cat == 1 then physical.deck_velocity else physical.external_velocity
	local projection = native_arithmetic.dot3(velocity, physical.board_axis)
	if physical.ground_projected_speed > settings.high_speed and projection < -0.5 then
		self.slowly_backwards = 0.0
		return true
	elseif physical.ground_projected_speed > settings.low_speed and projection < -0.5 then
		self.slowly_backwards = f32(dt + self.slowly_backwards)
		return self.slowly_backwards > settings.slowly_backwards_seconds
	end
	self.slowly_backwards = 0.0
	return false
end

return riding_fakie
