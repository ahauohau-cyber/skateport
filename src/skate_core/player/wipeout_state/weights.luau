--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/wipeout_state/weights.rs (коммит 2e16697)
--
-- Wipeout Update82D3BE04..82D3BFE8, after the selected physical control.

local rt = require("../../../rt")
local m = require("./math")
local data = require("./data")

local f32 = rt.f32

local weights = {}

export type Settings = {
	remove_target_time: number,
	remove_drives_time: number,
	-- Native352 is a per-update increment, not a per-second velocity.
	collision_step: number,
	-- Native348 is also a per-update increment.
	controlled_step: number,
}

export type Output = {
	target_weight: number,
	start: number,
	["end"]: number,
	controlled: number,
	extra: number,
}

local function fade(duration: number, time: number): number
	local divisor = if duration == 0.0 then f32(0.01) else duration
	return m.clamp(f32(f32(duration - time) / divisor), 0.0, 1.0)
end

function weights.update(state: data.State, settings: Settings, contact: boolean, control_applied: boolean, flags_2472: number, gesture: { number }): Output
	local target_weight = fade(settings.remove_target_time, state.time)
	if state.special_surface or (math.abs(gesture[1]) < f32(0.2) and math.abs(gesture[2]) < f32(0.2)) then
		local step = if contact then settings.collision_step else -settings.collision_step
		state.collision_weight = m.clamp(f32(state.collision_weight + step), 0.0, 1.0)
	else
		state.collision_weight = 0.0
	end
	local drive_fade = fade(settings.remove_drives_time, state.time)
	local drive_fade_squared = f32(drive_fade * drive_fade)
	local enabled = (control_applied or bit32.btest(flags_2472, 0x0008_0000)) and not state.special_surface
	local step = if enabled then settings.controlled_step else -settings.controlled_step
	state.controlled_weight = m.clamp(f32(state.controlled_weight + step), 0.0, 1.0)
	local available = f32(1.0 - state.collision_weight)
	local start = f32(available * drive_fade_squared)
	return {
		target_weight = target_weight,
		start = start,
		["end"] = state.collision_weight,
		controlled = f32(f32(available - start) * state.controlled_weight),
		extra = f32(state.extra_weight * f32(0.03)),
	}
end

return weights
