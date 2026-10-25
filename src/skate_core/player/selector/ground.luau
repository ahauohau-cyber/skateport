--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/selector/ground.rs (коммит 2e16697)
--
-- ROBLOX: impl StateSelector { fn select_ground_family } -> функция модуля,
-- self — таблица StateSelector; facts — FrameFacts (поле grind: число или nil).

local input_mod = require("./input")
local state = require("../state")

local S = state.PhysicalStateId
local P = input_mod.ProcessedStateInput

local ground = {}

function ground.select_ground_family(self: any, current: number, input: input_mod.StateSelectionInput, facts: any): number
	local p = input.processed
	if current == S.PhysicsGround then
		if P.has_2480(p, 0x1000) and (not P.has_2480(p, 0x400) or not P.has_2480(p, 0x200)) then
			-- TU3 calls `sk83_na_f_01a4` at 0x82D8B23C here. The
			-- target is 0x82B61BB8 and consists solely of `blr`.
			return S.LandingOnDeck
		end
		local handplant_contact = P.has_2480(p, 0x40000000) and input.skateboard_contact_count_869 <= 2
		if P.has_2476(p, 1) and (handplant_contact or input.skateboard_contact_count_869 == 0) then
			return S.HandPlant
		end
		if P.has_2476(p, 0x8000) then
			return S.BipedGround
		end
		if P.has_2476(p, 0x80) then
			return S.BipedAir
		end
		if facts.wipeout then
			return S.WipeoutGround
		end
		if p.field_2572 == 1 then
			return P.air_variant_from_2468(p)
		end
		if p.field_2744 ~= 0.0 then
			return S.RevertGround
		end
		if facts.grind ~= nil then
			return facts.grind
		end
		if not facts.colliding and facts.off_ground and self.teleport_countdown == 0 then
			return S.PhysicsAir
		end
		if facts.skateboard_animated and self.teleport_countdown == 0 then
			return S.GroundAnimation
		end
		if P.has_2476(p, 0x200000) and P.has_2480(p, 0x400000) and self.skitch_exit_countdown == 0 then
			return S.Skitching
		end
		if p.field_2732 ~= 0.0 then
			return S.SlideGround
		else
			return current
		end
	elseif current == S.SlideGround then
		if facts.wipeout then
			return S.WipeoutGround
		end
		if p.field_2744 ~= 0.0 then
			return S.RevertGround
		end
		if facts.grind ~= nil then
			return facts.grind
		end
		if not facts.colliding and facts.off_ground then
			return S.PhysicsAir
		end
		if p.field_2732 == 0.0 then
			return S.PhysicsGround
		else
			return current
		end
	elseif current == S.RevertGround then
		if not facts.colliding and facts.off_ground then
			return S.PhysicsAir
		end
		if P.has_2468(p, 0x10000) or P.has_2472(p, 0x20000) then
			return S.PhysicsGround
		end
		if not P.has_2472(p, 0x200000) then
			self.revert_exited_normally = true
			return S.PhysicsGround
		end
		if facts.wipeout then
			return S.WipeoutGround
		else
			return current
		end
	elseif current == S.GroundAnimation then
		if facts.wipeout then
			return S.WipeoutGround
		end
		if P.has_2480(p, 0x4000) then
			return S.Boneless
		end
		if P.has_2476(p, 0x8000) then
			return S.BipedGround
		end
		if P.has_2476(p, 0x80) then
			return S.BipedAir
		end
		if p.field_2572 == 1 then
			return P.air_variant_from_2468(p)
		end
		if not facts.colliding and facts.off_ground then
			return S.PhysicsAir
		end
		if facts.skateboard_animated then
			return current
		else
			return S.PhysicsGround
		end
	elseif current == S.Skitching then
		if not P.has_2476(p, 0x200000) then
			return S.PhysicsGround
		end
		if facts.wipeout then
			return S.WipeoutGround
		end
		if facts.off_ground_skitching and self.teleport_countdown == 0 then
			return S.PhysicsGround
		else
			return current
		end
	elseif current == S.FollowPath then
		-- ROBLOX: field_1776 as u32 -> по модулю 2^32.
		if bit32.band(p.field_1776 % 0x100000000, 0x2000000) ~= 0 then
			return S.PhysicsGround
		else
			return current
		end
	end
	error("ground-family dispatch accepts only states 100..105")
end

return ground
