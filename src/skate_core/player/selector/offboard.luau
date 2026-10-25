--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/selector/offboard.rs (коммит 2e16697)
--
-- ROBLOX: impl StateSelector -> функция модуля (self — StateSelector).

local rt = require("../../../rt")
local input_mod = require("./input")
local state = require("../state")

local S = state.PhysicalStateId
local P = input_mod.ProcessedStateInput

local offboard = {}

local HANDPLANT_GROUND_DELAY_SECONDS = rt.from_bits(0x3E4CCCCD)

function offboard.select_biped_or_plant(self: any, current: number, input: input_mod.StateSelectionInput, facts: any): number
	local p = input.processed
	if current == S.BipedGround then
		if facts.wipeout then
			return S.WipeoutGround
		end
		if P.has_2484(p, 0x10000) then
			return S.BipedAir
		end
		if P.has_2476(p, 0x200000) then
			return S.OffBoardPushing
		end
		if P.has_2476(p, 0x8000) or P.has_2480(p, 0x40000) then
			return current
		end
		if not P.has_2484(p, 1) and not P.has_2488(p, 0x10000000) and not P.has_2488(p, 0x80000000) then
			return S.PhysicsAir
		end
		return S.PhysicsGround
	elseif current == S.BipedAir then
		if facts.wipeout then
			return S.WipeoutGround
		end
		if not P.has_2480(p, 0x10) then
			-- 82D8B8D4 loads a BIG-ENDIAN halfword at2484, then
			-- B8D8 tests its low bit: bit16 of the stored u32.
			-- This is OffBoard328, not BipedBoardOnGround bit0.
			if P.has_2484(p, 0x10000) then
				if P.has_2476(p, 0x8000) or P.has_2476(p, 0x80) then
					return current
				else
					return S.PhysicsAir
				end
			else
				return S.BipedGround
			end
		else
			return S.LandingOnDeck
		end
	elseif current == S.OffBoardPushing then
		if facts.wipeout then
			return S.WipeoutGround
		elseif not P.has_2476(p, 0x200000) then
			return S.BipedGround
		else
			return current
		end
	elseif current == S.LandingOnDeck then
		if facts.wipeout then
			return S.WipeoutGround
		elseif P.has_2476(p, 0x10000) then
			return S.PhysicsGround
		elseif P.has_2476(p, 0x80) then
			return S.BipedAir
		else
			return current
		end
	elseif current == S.HandPlant then
		if facts.wipeout then
			return S.WipeoutGround
		elseif (facts.colliding and p.state_timer_2664 > HANDPLANT_GROUND_DELAY_SECONDS) or rt.to_i32(p.flags_2480) >= 0 then
			return S.PhysicsGround
		else
			return current
		end
	elseif current == S.FootPlant then
		if facts.wipeout then
			return S.WipeoutGround
		-- 82D8B970 loads the first byte of the big-endian word,
		-- then tests its low bit: full-word bit24 is Air448.
		elseif not P.has_2480(p, 0x01000000) then
			return P.air_variant_from_2468(p)
		else
			return current
		end
	elseif current == S.Boneless then
		if facts.wipeout then
			return S.WipeoutGround
		end
		if P.has_2468(p, 0x400) then
			return S.KnownAir
		end
		if P.has_2476(p, 0x80) then
			return S.BipedAir
		end
		if not P.has_2480(p, 0x4000) and not P.has_2480(p, 0x2000) then
			return S.PhysicsAir
		else
			return current
		end
	end
	error("off-board/plant dispatch received another state")
end

return offboard
