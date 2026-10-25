--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/selector/conditions.rs (коммит 2e16697)
--
-- Small predicates called by TU3 `CalcSuggestedState` (`0x82D8ADE8`).

local rt = require("../../../rt")

local conditions = {}

export type BoardBodyState = {
	-- `SkateboardBody + 856`.
	field_856: number,
	-- `SkateboardBody + 7692`.
	field_7692: number,
}

export type TwoStageThresholds = {
	field_856_primary: number,
	field_856_secondary: number,
	field_7692: number,
}

-- TU3 `0x82D8BBB8`. All comparisons are strict, matching `fcmpu`/`bgt`.
function conditions.condition_is_off_ground_skitching(body: BoardBodyState, thresholds: TwoStageThresholds): boolean
	return body.field_856 > thresholds.field_856_primary
		or (body.field_856 > thresholds.field_856_secondary and body.field_7692 > thresholds.field_7692)
end

-- TU3 `0x82D8BD50`. The separate settings source is intentional: the native
-- function reads these three values from the live physics-mode collection.
function conditions.condition_is_off_ground(body: BoardBodyState, thresholds: TwoStageThresholds): boolean
	return body.field_856 > thresholds.field_856_primary
		or (body.field_856 > thresholds.field_856_secondary and body.field_7692 > thresholds.field_7692)
end

export type SkeletonAnimationState = {
	-- `Skeleton + 16420`.
	mode_16420: number,
	-- Lane one of the vector at `Skeleton + 12624 + 32`.
	back_chain_lane_12656: number,
	-- `*(Skeleton + 24) + 800`.
	threshold_800: number,
}

-- TU3 `0x82BDC6C8`. The native absolute value clears the scalar sign bit.
function conditions.is_skateboard_animated(input: SkeletonAnimationState): boolean
	if input.mode_16420 == 2 then
		return true
	end
	local magnitude = rt.from_bits(bit32.band(rt.to_bits(input.back_chain_lane_12656), 0x7fffffff))
	if magnitude <= input.threshold_800 then
		return false
	else
		return input.mode_16420 ~= 1
	end
end

return conditions
