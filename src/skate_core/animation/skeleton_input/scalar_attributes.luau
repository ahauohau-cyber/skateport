--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/skeleton_input/scalar_attributes.rs (коммит 2e16697)
--
-- Complete contiguous scalar handlers 82BDACF0..82BDB694, plus the two
-- independently verified scalar PushContact/PushSpeed flag handlers.
-- Input order is the packet's MG-then-tree order; no timing/value threshold
-- filters are added. process_attributes.process supplies the complete ordered
-- dispatch, kind3 events, remaining scalar handlers and finalization.

local rt = require("../../../rt")
local catalog = require("./catalog")
local attributes_mod = require("../output/attributes")

local from_bits = rt.from_bits

local scalar_attributes = {}

-- These flag words are shared with other ProcessedPhysIn stages. They must
-- be seeded by the real preceding reset/consumer stages, not zeroed here.
export type ScalarAttributeInputs = {
	flags2468: number,
	flags2472: number,
	flags2476: number,
	flags2484: number,
	flags2488: number,
	-- Native+2492: left1, right2, up3, down4. Unknown prior enum values survive.
	board_adjust: number,
	-- Native 2720, 2672, 2640, 2728, 2676 respectively.
	balance: number,
	spin: number,
	body_spin: number,
	brake: number,
	turn: number,
	-- Native 2908/2912.
	turn_scale: number,
	magnitude_scale: number,
	-- Native 2880/2864; scalar handlers replace XYZ independently, preserving W.
	animation_end_com: { number },
	animation_translation: { number },
	-- Native 2896/2904/2900.
	animation_time: number,
	animation_physics_blend_seconds: number,
	cadence_end_percent: number,
	-- Native 2712/2716/2732.
	raw_turn: number,
	hard_turn: number,
	slide: number,
}

local ScalarAttributeInputs = {}
scalar_attributes.ScalarAttributeInputs = ScalarAttributeInputs

-- Represented ProcessedPhysIn fields written by Reset 82BF9EF0.
-- This is the reset stage, not an implicit reset in attribute dispatch.
function ScalarAttributeInputs.reset(previous_flags2468: number, previous_flags2488: number): ScalarAttributeInputs
	return {
		flags2468 = bit32.bor(bit32.band(previous_flags2468, 8), 0x2000),
		flags2472 = 0,
		flags2476 = 0,
		flags2484 = 0,
		flags2488 = bit32.band(previous_flags2488, 0x1fffff),
		board_adjust = 0,
		balance = 0.0,
		spin = 0.0,
		body_spin = 0.0,
		brake = 0.0,
		turn = 0.0,
		turn_scale = 1.0,
		magnitude_scale = 1.0,
		animation_end_com = { 0.0, 0.0, 0.0, 0.0 },
		animation_translation = { 0.0, 0.0, 0.0, 0.0 },
		animation_time = 0.0,
		animation_physics_blend_seconds = 0.0,
		cadence_end_percent = -1.0,
		raw_turn = 0.0,
		hard_turn = 0.0,
		slide = 0.0,
	}
end

export type AnimationControlOutput = {
	-- AnimOut+0..16: selected Slide/Grind name, copied as five exact words.
	grind_name: { number },
	flags: number,
}

-- ROBLOX: enum DispatchError -> { kind = "EventConsumerUnavailable", name }
-- | { kind = "KnownScalarUnavailable", attribute } | { kind = "UninitializedScalar", attribute }.
-- PacketDispatchError -> { attribute_index, cause }.

-- ROBLOX: Result<(), DispatchError> -> rt.raise(DispatchError).
function scalar_attributes.dispatch_attribute(attribute: any, input: ScalarAttributeInputs, output: AnimationControlOutput)
	if attribute.kind ~= 0 then
		if attribute.kind == 3 and bit32.band(attribute.status, 12) ~= 0 then
			rt.raise({ kind = "EventConsumerUnavailable", name = attribute.name })
		end
		return
	end
	local entry = catalog.lookup(attribute.name)
	if entry == nil then
		return
	end
	local function scalar(): number
		local w = attribute.payload[1]
		if w == false or w == nil then
			rt.raise({ kind = "UninitializedScalar", attribute = entry })
		end
		return from_bits(w)
	end
	local n = entry.name
	if n == "SlideBoard" or n == "SlideNose" or n == "SlideTail" or n == "Grind5050" or n == "Grind5_O" or n == "GrindNose" then
		output.grind_name = table.clone(attribute.name)
	elseif n == "GrabWorld" then
		input.flags2476 = bit32.bor(input.flags2476, bit32.lshift(1, 22))
	elseif n == "BoardAdjustLeft" then
		input.board_adjust = 1
	elseif n == "BoardAdjustRight" then
		input.board_adjust = 2
	elseif n == "BoardAdjustUp" then
		input.board_adjust = 3
	elseif n == "BoardAdjustDown" then
		input.board_adjust = 4
	elseif n == "GrindFacingForwards" then
		output.flags = bit32.bor(output.flags, bit32.lshift(1, 31))
	elseif n == "GrindFacingBackwards" then
		output.flags = bit32.band(output.flags, bit32.bnot(bit32.lshift(1, 31)))
	elseif n == "NoInput" then
		output.flags = bit32.bor(output.flags, bit32.lshift(1, 30))
		input.flags2472 = bit32.bor(input.flags2472, bit32.lshift(1, 23))
	elseif n == "ExitGrind" then
		input.flags2476 = bit32.bor(input.flags2476, bit32.lshift(1, 29))
	elseif n == "NewAutoPump" then
		output.flags = bit32.bor(output.flags, bit32.lshift(1, 29))
	elseif n == "PlayerControlledPump" then
		input.flags2476 = bit32.bor(input.flags2476, 2)
	elseif n == "EnteringCoffin" then
		input.flags2472 = bit32.bor(input.flags2472, 2)
		input.flags2476 = bit32.bor(input.flags2476, bit32.lshift(1, 30))
	elseif n == "InCoffin" then
		input.flags2472 = bit32.bor(input.flags2472, 1)
		input.flags2476 = bit32.bor(input.flags2476, bit32.lshift(1, 30))
	elseif n == "LeavingCoffin" then
		input.flags2476 = bit32.bor(input.flags2476, 0xc000_0000)
	elseif n == "PlayingLanding" then
		input.flags2476 = bit32.bor(input.flags2476, bit32.lshift(1, 28))
	elseif n == "Balance" then
		input.balance = -scalar()
	elseif n == "Spin" then
		input.spin = -scalar()
	elseif n == "KickTurn" then
		output.flags = bit32.bor(output.flags, bit32.lshift(1, 28))
	elseif n == "Anticipating" then
		output.flags = bit32.bor(output.flags, bit32.lshift(1, 27))
	elseif n == "BodySpin" then
		input.body_spin = -scalar()
	elseif n == "ManualBrake" then
		input.flags2468 = bit32.bor(input.flags2468, bit32.lshift(1, 29))
	elseif n == "Brake" then
		input.brake = scalar()
	elseif n == "Turn" then
		input.turn = -scalar()
	elseif n == "IsStumbling" then
		input.flags2484 = bit32.bor(input.flags2484, bit32.lshift(1, 10))
	elseif n == "IsWipeoutPushOffImpulse" then
		input.flags2484 = bit32.bor(input.flags2484, bit32.lshift(1, 8))
	elseif n == "IsWipeoutPushOff" then
		input.flags2484 = bit32.bor(input.flags2484, bit32.lshift(1, 9))
	elseif n == "IsMuteRFoot" then
		input.flags2484 = bit32.bor(input.flags2484, bit32.lshift(1, 7))
	elseif n == "IsMuteLFoot" then
		input.flags2484 = bit32.bor(input.flags2484, bit32.lshift(1, 6))
	elseif n == "IsForceDownRFoot" then
		input.flags2484 = bit32.bor(input.flags2484, bit32.lshift(1, 3))
	elseif n == "IsForceDownLFoot" then
		input.flags2484 = bit32.bor(input.flags2484, bit32.lshift(1, 2))
	elseif n == "TurnScale" then
		input.turn_scale = scalar()
	elseif n == "MagScale" then
		input.magnitude_scale = scalar()
	elseif n == "AnimEndCOMX" then
		input.animation_end_com[1] = scalar()
	elseif n == "AnimEndCOMY" then
		input.animation_end_com[2] = scalar()
	elseif n == "AnimEndCOMZ" then
		input.animation_end_com[3] = scalar()
	elseif n == "AnimTransX" then
		input.animation_translation[1] = scalar()
	elseif n == "AnimTransY" then
		input.animation_translation[2] = scalar()
	elseif n == "AnimTransZ" then
		input.animation_translation[3] = scalar()
	elseif n == "AnimTime" then
		input.animation_time = scalar()
	elseif n == "AnimPhysBlendSec" then
		input.animation_physics_blend_seconds = scalar()
	elseif n == "IsAnimInterpToEdge" then
		input.flags2488 = bit32.bor(input.flags2488, bit32.lshift(1, 27))
	elseif n == "CadenceEndPercent" then
		input.cadence_end_percent = scalar()
	elseif n == "OB_Traj" then
		input.flags2476 = bit32.bor(input.flags2476, bit32.lshift(1, 15))
	elseif n == "OB_Air" then
		input.flags2476 = bit32.bor(input.flags2476, bit32.lshift(1, 7))
	elseif n == "Carving" then
		input.flags2468 = bit32.bor(input.flags2468, bit32.lshift(1, 31))
	elseif n == "RawTurn" then
		input.raw_turn = -scalar()
	elseif n == "HardTurn" then
		input.hard_turn = -scalar()
	elseif n == "Slide" then
		input.slide = -scalar()
	elseif n == "FrontFlip" then
		input.flags2468 = bit32.bor(input.flags2468, bit32.lshift(1, 7))
	elseif n == "BackFlip" then
		input.flags2468 = bit32.bor(input.flags2468, bit32.lshift(1, 6))
	elseif n == "Grabbing" then
		input.flags2468 = bit32.bor(input.flags2468, bit32.lshift(1, 5))
	elseif n == "WantsLeftAirGrab" or n == "WantsRightAirGrab" then
		input.flags2468 = bit32.bor(input.flags2468, bit32.lshift(1, 4))
	elseif n == "FlipTrick" then
		input.flags2472 = bit32.bor(input.flags2472, bit32.lshift(1, 22))
	elseif n == "WipeOutRecover" then
		input.flags2472 = bit32.bor(input.flags2472, bit32.lshift(1, 20))
	elseif n == "ControlledWipeout" then
		input.flags2472 = bit32.bor(input.flags2472, bit32.lshift(1, 19))
	elseif n == "PushContact" then
		input.flags2488 = bit32.bor(input.flags2488, bit32.lshift(1, 29))
	elseif n == "PushSpeed" then
		input.flags2488 = bit32.bor(input.flags2488, bit32.lshift(1, 23))
	else
		rt.raise({ kind = "KnownScalarUnavailable", attribute = entry })
	end
end

-- Dispatch actual packet attributes into their physical consumer fields.
-- On failure earlier attribute effects remain; the failed handler performs no
-- writes here. Success means these supported handlers ran, not that native
-- attribute finalization or Skeleton::ProcessData has completed.
function scalar_attributes.dispatch_supported_packet(binding: any, input: ScalarAttributeInputs, output: AnimationControlOutput)
	for i, attribute in attributes_mod.PacketAttributes.entries(binding.packet.attributes) do
		local _, cause = rt.catch(scalar_attributes.dispatch_attribute, attribute, input, output)
		if cause ~= nil then
			rt.raise({ attribute_index = i - 1, cause = cause })
		end
	end
end

return scalar_attributes
