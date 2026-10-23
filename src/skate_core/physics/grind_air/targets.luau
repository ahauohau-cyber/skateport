--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/physics/grind_air/targets.rs (коммит 2e16697)
--
-- ROBLOX: массивы-константы с нулевой индексацией -> таблицы, элемент k в [k + 1].

local rt = require("../../../rt")
local trigonometry = require("../../trigonometry")

local f32 = rt.f32
local from_bits = rt.from_bits

type V = { number }

local targets = {}
targets.parent = (nil :: any)

targets.CONTACTS = table.freeze({ 0, 1, 4, 0, 2, 2, 3 })
targets.DESIRED = table.freeze({ 90.0, 90.0, 90.0, 90.0, 0.0, 0.0, 0.0 })

export type Settings = {
	frames: number,
	stomp: number,
	points: { V }, -- [V; 5]
	ranges: { number }, -- [f32; 7]
	distances: { number }, -- [f32; 7]
	yaw_assist: { number }, -- [f32; 7]
	max_offset: number,
	max_delta: number,
	max_angle: number,
}

export type DeckDimensions = {
	middle_length: number,
	front_end_size: number,
	front_end_angle_degrees: number,
	truck_z_front: number,
	truck_y: number,
}

local DeckDimensions = {}
targets.DeckDimensions = DeckDimensions

-- 82D72B40 uses sine for tip height but adds the unprojected tip length to Z.
function DeckDimensions.contact_points(self: DeckDimensions, tip_fraction: number): { V }
	local half = f32(self.middle_length * 0.5)
	local tip = f32(self.front_end_size * tip_fraction)
	local sin = trigonometry.sin_cos(f32(self.front_end_angle_degrees * from_bits(0x3c8e_fa35)))
	local y = f32(sin * tip)
	local z = f32(half + self.truck_z_front)
	return {
		{ 0.0, 0.0, 0.0, 0.0 },
		{ 0.0, y, f32(tip + half), 0.0 },
		{ 0.0, self.truck_y, z, 0.0 },
		{ 0.0, self.truck_y, -z, 0.0 },
		{ 0.0, y, -f32(tip + half), 0.0 },
	}
end

local SettingsImpl = {}
targets.Settings = SettingsImpl

-- ROBLOX: Result<(), String> -> rt.raise(строка).
function SettingsImpl.validate(self: Settings)
	-- Host data validation, not a gameplay clamp or a fabricated setting.
	if not (self.frames >= 2 and self.frames <= 12) then
		rt.raise("Stock GrindAir NumFramesToTest exceeds native 2..12 storage")
	end
end

return targets
