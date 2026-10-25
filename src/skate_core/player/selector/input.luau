--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/selector/input.rs (коммит 2e16697)
--
-- ROBLOX: методы has_XXXX(self, mask) -> функции ProcessedStateInput.has_XXXX(p, mask).

local conditions = require("./conditions")
local state = require("../state")

local S = state.PhysicalStateId

local input = {}

-- Values read by TU3 `PhysicalPlayerStateChanger::CalcSuggestedState`.
-- Offset-bearing names are retained where the producer's semantic name has
-- not yet been proved in Skate 3.
export type ProcessedStateInput = {
	grind_type_1248: number,
	grind_candidate_1488: boolean,
	field_1776: number,
	flags_2468: number,
	flags_2472: number,
	flags_2476: number,
	flags_2480: number,
	flags_2484: number,
	flags_2488: number,
	category_2512: number,
	wheel_contact_count_2556: number,
	field_2572: number,
	state_timer_2664: number,
	field_2732: number,
	field_2744: number,
	trajectory_collision_time_2772: number,
	grind_investigation_flags_1516: number,
}

local ProcessedStateInput = {}
input.ProcessedStateInput = ProcessedStateInput

function ProcessedStateInput.has_2468(self: ProcessedStateInput, mask: number): boolean
	return bit32.band(self.flags_2468, mask) ~= 0
end

function ProcessedStateInput.has_2472(self: ProcessedStateInput, mask: number): boolean
	return bit32.band(self.flags_2472, mask) ~= 0
end

function ProcessedStateInput.has_2476(self: ProcessedStateInput, mask: number): boolean
	return bit32.band(self.flags_2476, mask) ~= 0
end

function ProcessedStateInput.has_2480(self: ProcessedStateInput, mask: number): boolean
	return bit32.band(self.flags_2480, mask) ~= 0
end

function ProcessedStateInput.has_2484(self: ProcessedStateInput, mask: number): boolean
	return bit32.band(self.flags_2484, mask) ~= 0
end

function ProcessedStateInput.has_2488(self: ProcessedStateInput, mask: number): boolean
	return bit32.band(self.flags_2488, mask) ~= 0
end

function ProcessedStateInput.air_variant_from_2468(self: ProcessedStateInput): number
	if ProcessedStateInput.has_2468(self, 0x400) then
		return S.KnownAir
	else
		return S.PhysicsAir
	end
end

export type StateSelectionInput = {
	processed: ProcessedStateInput,
	-- Byte at `SkateboardBody + 869`.
	skateboard_contact_count_869: number,
	board_body: conditions.BoardBodyState,
	skeleton: conditions.SkeletonAnimationState,
	-- Three collection values consumed by TU3 `0x82D8BBB8`.
	skitching_off_ground: conditions.TwoStageThresholds,
	-- Three physics-mode values consumed by TU3 `0x82D8BD50`.
	normal_off_ground: conditions.TwoStageThresholds,
}

return input
