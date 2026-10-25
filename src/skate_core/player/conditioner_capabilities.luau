--!strict
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/player/conditioner_capabilities.rs (коммит 2e16697)
--
-- Conditioner capability publication from original Skate 3 TU3 0x8275F430.
--
-- World writes ExternalInput+2780, then 0x82DA7888 copies that word to
-- PhysOutScoring2+204. The word gates controller and camera behavior; it is
-- not a count or mask of currently broken bones.

local conditioner_capabilities = {}

-- Host settings needed by the original whole-word capability calculation.
-- There is deliberately no implicit default for these gameplay choices.
export type ConditionerCapabilityContext = {
	-- Original FEBackEnd state equals 2 (in front end). This is a menu gate.
	in_front_end: boolean,
	-- Original game settings +184 equals 1. UI option 29 is Hall of Meat mode.
	hall_of_meat_enabled: boolean,
	-- Original challenge subsystem +328 virtual method at vtable+12 is nonzero.
	-- Its precise challenge interface name remains unidentified. A host with
	-- no challenge system supplies false rather than inventing that system.
	challenge_query_active: boolean,
	-- Original challenge subsystem +512 points to a record whose byte 44 is
	-- nonzero. Only consulted when the challenge query above is active.
	challenge_configuration_enabled: boolean,
}

local ConditionerCapabilityContext = {}
conditioner_capabilities.ConditionerCapabilityContext = ConditionerCapabilityContext

-- Preserve all bits and branch priority from 0x8275F4D8..0x8275F558.
function ConditionerCapabilityContext.capabilities(self: ConditionerCapabilityContext): number
	if self.in_front_end then
		return 0
	elseif self.challenge_query_active and self.challenge_configuration_enabled then
		return 0xfffffff7
	elseif self.hall_of_meat_enabled and not self.challenge_query_active then
		return 0xfffff7f7
	else
		return 0x000001c0
	end
end

return conditioner_capabilities
