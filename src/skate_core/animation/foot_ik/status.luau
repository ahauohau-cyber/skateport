--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/foot_ik/status.rs (коммит 2e16697)
--
-- Limb mode transitions82BEDCF8 and blend weights82BEEC00.
-- Named S2 UpdateStatus/UpdateBlendValues corroborate field identities;
-- TU3 flags and cached settings determine the implementation.

local rt = require("../../../rt")

local f32 = rt.f32

local status = {}

-- ROBLOX: enum Mode -> строки "Disabled" | "OnDeck" | "External" | "Local".
export type Mode = "Disabled" | "OnDeck" | "External" | "Local"

export type LimbStatus = {
	mode: Mode,
	-- SkeletonIK+468+4*limb.
	board_blend: number,
	-- SkeletonIK+484+4*limb.
	external_blend: number,
	target_blend: number,
	external_target_set: boolean,
	local_target_set: boolean,
	external_target_local_delta: { number },
	-- CalculateInitialPartTransforms retains the target in animation-deck space.
	part_position: { number },
}

local LimbStatus = {}
status.LimbStatus = LimbStatus

-- ROBLOX: impl Default.
function LimbStatus.default(): LimbStatus
	--82BED780 resets mode, both weights, target blend, target flags and
	--the complete local delta/part-position vectors to zero.
	return {
		mode = "Disabled",
		board_blend = 0.0,
		external_blend = 0.0,
		target_blend = 0.0,
		external_target_set = false,
		local_target_set = false,
		external_target_local_delta = { 0.0, 0.0, 0.0, 0.0 },
		part_position = { 0.0, 0.0, 0.0, 0.0 },
	}
end

-- /// All four limbs in native order: left foot, right foot, left hand, right hand.
-- /// Foot enable is SkeletonIK464; reset82BED780 initializes it to true.
function status.update_modes(limbs: { LimbStatus }, feet_enabled: boolean, flags_2472: number)
	local enabled = {
		feet_enabled,
		feet_enabled,
		bit32.band(flags_2472, 0x80) ~= 0,
		bit32.band(flags_2472, 0x100) ~= 0,
	}
	for i, limb in limbs do
		local fallback: Mode = if enabled[i] then "OnDeck" else "Disabled"
		local mode = limb.mode
		if mode == "Disabled" then
			limb.board_blend = 0.0
			if limb.external_target_set then
				limb.mode = "External"
				limb.external_blend = limb.target_blend
			elseif limb.local_target_set then
				limb.mode = "Local"
				limb.external_blend = limb.target_blend
				limb.external_target_local_delta = { 0.0, 0.0, 0.0, 0.0 }
			else
				limb.mode = fallback
				limb.external_blend = 0.0
			end
		elseif mode == "OnDeck" then
			if limb.external_target_set then
				limb.mode = "External"
				limb.external_blend = limb.target_blend
			elseif limb.local_target_set then
				limb.mode = "Local"
				limb.external_blend = limb.target_blend
				limb.external_target_local_delta = { 0.0, 0.0, 0.0, 0.0 }
			elseif limb.board_blend == 0.0 then
				limb.mode = fallback
				limb.external_blend = 0.0
			end
		elseif mode == "External" then
			if not limb.external_target_set then
				limb.mode = "Local"
			end
		elseif mode == "Local" then
			if limb.external_target_set then
				limb.mode = "External"
				limb.external_blend = limb.target_blend
			end
			-- This is a second independent test, even after switching to
			--External above. Preserve the native zero-target-blend case.
			if not limb.local_target_set and limb.external_blend == 0.0 then
				limb.mode = fallback
				limb.external_target_local_delta = { 0.0, 0.0, 0.0, 0.0 }
			end
		end
	end
end

export type BlendSettings = {
	-- physics_skeletonik cached layout16/32.
	hand_inner_padding: { number },
	hand_outer_padding: { number },
	-- Cached layout84 and88; native increments per update, without dt.
	external_blend_step: number,
	board_blend_step: number,
}

local function select(condition: number, nonnegative: number, negative: number): number
	return if condition >= 0.0 then nonnegative else negative
end

local function positive(value: number): number
	return select(-value, 0.0, value)
end

-- ROBLOX: value: &mut f32 -> возвращаем новое значение.
local function approach(value: number, target: number, step: number): number
	local delta = f32(target - value)
	delta = select(f32(-step - delta), -step, delta)
	return f32(select(f32(step - delta), delta, step) + value)
end

-- /// Board dimensions are the actual constructor-derived half width and total
-- /// half length, not the board's visual bounds or cached generic dimensions.
function status.update_blends(limbs: { LimbStatus }, deck_half_width: number, deck_total_half_length: number, flags_2480: number, settings: BlendSettings)
	local base = { deck_half_width, 0.0, deck_total_half_length, 0.0 }
	local inner = {}
	local outer = {}
	for i = 1, 4 do
		inner[i] = f32(base[i] + settings.hand_inner_padding[i])
		outer[i] = f32(inner[i] + settings.hand_outer_padding[i])
	end
	local step = settings.board_blend_step
	for index, limb in limbs do
		local mode = limb.mode
		if mode == "Disabled" then
			-- ничего
		elseif mode == "External" then
			limb.external_blend = limb.target_blend
			limb.board_blend = positive(f32(limb.board_blend - step))
		elseif mode == "Local" then
			limb.external_blend = if limb.local_target_set then 1.0 else positive(f32(limb.external_blend - settings.external_blend_step))
			limb.board_blend = positive(f32(limb.board_blend - step))
		elseif mode == "OnDeck" and index <= 2 then
			local target = if bit32.band(flags_2480, 0x0800_0000) ~= 0 then 0.0 else 1.0
			limb.board_blend = approach(limb.board_blend, target, step)
		else
			local pp = limb.part_position
			local p = { math.abs(pp[1]), math.abs(pp[2]), math.abs(pp[3]), math.abs(pp[4]) }
			if limb.board_blend > 0.0 or (p[1] < outer[1] and p[2] < outer[2] and p[3] < outer[3]) then
				local target = 1.0
				-- Native order X, Z, Y; fsel preserves equality and NaNs.
				for _, axis in { 0, 2, 1 } do
					local a = axis + 1
					if p[a] > inner[a] then
						local candidate = f32(1.0 - f32(f32(p[a] - inner[a]) / settings.hand_outer_padding[a]))
						if axis == 0 then
							target = candidate
						elseif axis == 2 then
							target = select(f32(target - candidate), candidate, target)
						else
							target = select(f32(candidate - target), target, candidate)
						end
					end
				end
				target = positive(target)
				target = select(f32(1.0 - target), target, 1.0)
				limb.board_blend = approach(limb.board_blend, target, step)
			end
		end
	end
end

return status
