--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/selector/air.rs (коммит 2e16697)
--
-- ROBLOX: impl StateSelector -> функции модуля (self — StateSelector).

local rt = require("../../../rt")
local input_mod = require("./input")
local state = require("../state")

local S = state.PhysicalStateId
local P = input_mod.ProcessedStateInput

local air = {}

local STATE_SETTLE_SECONDS = rt.from_bits(0x3DA3D70A)
local KNOWN_AIR_COLLISION_GRACE_SECONDS = rt.from_bits(0x3D23D70A)
local TRAJECTORY_WIPEOUT_SECONDS = rt.from_bits(0x3D4CCCCD)
local TRAJECTORY_EXPIRED_SECONDS = rt.from_bits(0xBE4CCCCD)

function air.select_physics_air(self: any, current: number, input: input_mod.StateSelectionInput, facts: any): number
	local p = input.processed
	if facts.wipeout then
		return S.WipeoutGround
	end
	if P.has_2476(p, 0x8000) then
		return S.BipedGround
	end
	-- 82D8B490 lbz2484 reads the high byte of the big-endian flag word.
	if P.has_2476(p, 0x80) and not P.has_2484(p, 0x01000000) then
		return S.BipedAir
	end
	if facts.force_known_air then
		if facts.colliding or P.has_2468(p, 0x8000) then
			return S.WipeoutGround
		end
		return if P.has_2468(p, 0x400) then S.KnownAir else current
	end
	if p.state_timer_2664 > STATE_SETTLE_SECONDS then
		if facts.colliding then
			if P.has_2472(p, 4) then
				return S.PhysicsAir
			end
			return if facts.skateboard_animated then S.GroundAnimation else S.PhysicsGround
		end
		if self.post_grind_jump_counter > 10 then
			if facts.grind ~= nil then
				return facts.grind
			end
		end
	end
	if P.has_2468(p, 0x400) then
		return S.KnownAir
	else
		return current
	end
end

function air.select_known_air(self: any, current: number, input: input_mod.StateSelectionInput, facts: any): number
	local p = input.processed
	if P.has_2480(p, 0x2000000) then
		return S.FootPlant
	end
	if p.trajectory_collision_time_2772 < TRAJECTORY_WIPEOUT_SECONDS and (P.has_2476(p, 0x80) or P.has_2476(p, 0x8000)) then
		return S.WipeoutGround
	end
	-- 82D8B5F0 uses the same byte load for the offboard dismount gate.
	if P.has_2476(p, 0x80) and not P.has_2484(p, 0x01000000) then
		return S.BipedAir
	end
	if P.has_2476(p, 0x8000) then
		return S.BipedGround
	end
	if facts.wipeout then
		return S.WipeoutGround
	end
	if facts.force_known_air then
		return if facts.colliding or P.has_2468(p, 0x8000) then S.WipeoutGround else current
	end
	if p.state_timer_2664 > STATE_SETTLE_SECONDS and self.post_grind_jump_counter > 10 then
		if facts.grind ~= nil then
			return facts.grind
		end
	end
	if not facts.colliding or p.state_timer_2664 < KNOWN_AIR_COLLISION_GRACE_SECONDS then
		if p.trajectory_collision_time_2772 < TRAJECTORY_EXPIRED_SECONDS then
			return if P.has_2476(p, 0x4000000) then S.KnownAir else S.PhysicsAir
		end
		if P.has_2468(p, 0x8000) then
			return if P.has_2476(p, 0x4000000) then S.WipeoutGround else S.PhysicsAir
		end
		return current
	end
	if P.has_2472(p, 4) then
		return S.PhysicsAir
	end
	if P.has_2480(p, 0x40000) or P.has_2480(p, 0x20000) or P.has_2480(p, 0x10000) then
		return S.WipeoutGround
	end
	if not P.has_2472(p, 0x8000) and not P.has_2472(p, 0x4000) then
		return S.PhysicsGround
	else
		return S.GroundAnimation
	end
end

function air.select_grind(self: any, _current: number, input: input_mod.StateSelectionInput, facts: any): number
	local p = input.processed
	if facts.wipeout then
		return S.WipeoutGround
	end
	if P.has_2484(p, 0x100000) then
		return S.PhysicsAirSecondary
	end
	if P.has_2476(p, 0x80) then
		return S.BipedAir
	end
	if P.has_2476(p, 0x8000) then
		return S.BipedGround
	end
	if P.has_2468(p, 0x100) then
		return P.air_variant_from_2468(p)
	end
	-- ROBLOX: facts.grind.unwrap_or(Nonspecific).
	return if facts.grind ~= nil then facts.grind else S.Nonspecific
end

return air
