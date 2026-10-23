--!strict
--!native
-- Порт из skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- Оригинал Rust-файла: crates/skate-core/src/animation/skeleton_input/extended_attributes.rs (коммит 2e16697)
--
-- Remaining scalar fields and flags 82BDB6A4..82BDC4B4. Values retain their
-- preceding ProcessData/reset state until the corresponding attribute writes.

local scalar_attributes = require("./scalar_attributes")

local extended_attributes = {}

export type ExtendedAttributes = {
	flags2480: number,
	-- Processed 2796..2820.
	grind_translation: number,
	grind_stability_nudge: number,
	grind_up_down: number,
	grind_grab_min_height: number,
	physical_body_spin: number,
	world_grab_y: number,
	world_grab_z: number,
	-- Processed 2680..2692, 2704..2708, 2784..2792.
	offboard_turn: number,
	offboard_magnitude: number,
	biped_world_x: number,
	biped_world_z: number,
	look_x: number,
	look_y: number,
	object_move_z: number,
	object_move_x: number,
	object_move_rotation: number,
	-- Processed 2824/2828, 2840/2844, 2916/2920, 2928/2932.
	wipeout_control: { number },
	offboard_jump: { number },
	wipeout_gesture: { number },
	body_adjust: { number },
	-- Processed 2936/2940/2944; AnimOut 24.
	biped_start_angle: number,
	biped_spin_angle: number,
	biped_animation_time: number,
	footstep_strength: number,
	-- Processed 2624/2628/2632/2744.
	jump_strength: number,
	jump_controls: { number },
	revert_direction: number,
}

local ExtendedAttributes = {}
extended_attributes.ExtendedAttributes = ExtendedAttributes

-- Reset 82BF9EF0 zeros every represented ProcessedPhysIn field here.
-- AnimOut 24 belongs to another owner and survives this reset.
function ExtendedAttributes.reset(footstep_strength: number): ExtendedAttributes
	return {
		flags2480 = 0,
		grind_translation = 0.0,
		grind_stability_nudge = 0.0,
		grind_up_down = 0.0,
		grind_grab_min_height = 0.0,
		physical_body_spin = 0.0,
		world_grab_y = 0.0,
		world_grab_z = 0.0,
		offboard_turn = 0.0,
		offboard_magnitude = 0.0,
		biped_world_x = 0.0,
		biped_world_z = 0.0,
		look_x = 0.0,
		look_y = 0.0,
		object_move_z = 0.0,
		object_move_x = 0.0,
		object_move_rotation = 0.0,
		wipeout_control = { 0.0, 0.0 },
		offboard_jump = { 0.0, 0.0 },
		wipeout_gesture = { 0.0, 0.0 },
		body_adjust = { 0.0, 0.0 },
		biped_start_angle = 0.0,
		biped_spin_angle = 0.0,
		biped_animation_time = 0.0,
		footstep_strength = footstep_strength,
		jump_strength = 0.0,
		jump_controls = { 0.0, 0.0 },
		revert_direction = 0.0,
	}
end

-- Special jump/revert handlers and finalization are in attribute_finalization.
-- Return false only for a name outside this contiguous scalar region.
-- ROBLOX: scalar() возвращает число или вызывает rt.raise (Result<f32, String>).
function extended_attributes.dispatch(name: string, scalar: () -> number, input: scalar_attributes.ScalarAttributeInputs, extra: ExtendedAttributes, output: scalar_attributes.AnimationControlOutput): boolean
	if name == "Wipeout" then
		input.flags2468 = bit32.bor(input.flags2468, 0x40000)
	elseif name == "jump" then
		input.flags2468 = bit32.bor(input.flags2468, 0x400000)
	elseif name == "DangerZone" then
		input.flags2472 = bit32.bor(input.flags2472, 0x8000)
	elseif name == "LateTrick" then
		input.flags2472 = bit32.bor(input.flags2472, 0x20)
	elseif name == "NoDangerZone" then
		input.flags2472 = bit32.bor(input.flags2472, 0x10)
	elseif name == "ChristAir" then
		input.flags2472 = bit32.bor(input.flags2472, 0x40)
	elseif name == "PhysGrindTranslation" then
		extra.grind_translation = scalar()
	elseif name == "PhysGrindStabilityNudge" then
		extra.grind_stability_nudge = scalar()
	elseif name == "PhysGrindUpDown" then
		extra.grind_up_down = scalar()
	elseif name == "PhysGrindGrabMinHeight" then
		extra.grind_grab_min_height = scalar()
	elseif name == "PhysBodySpin" then
		extra.physical_body_spin = scalar()
	elseif name == "world_grab_y" then
		extra.world_grab_y = scalar()
	elseif name == "world_grab_z" then
		extra.world_grab_z = scalar()
	elseif name == "NewHandPlant" then
		extra.flags2480 = bit32.bor(extra.flags2480, 0x20000000)
	elseif name == "AnimCommittedHandPlant" then
		extra.flags2480 = bit32.bor(extra.flags2480, 0x10000000)
	elseif name == "DisableFeetTargetIK" then
		extra.flags2480 = bit32.bor(extra.flags2480, 0x08000000)
	elseif name == "OB_Jump" then
		input.flags2476 = bit32.bor(input.flags2476, 0x80000)
	elseif name == "OB_StandingJump" then
		input.flags2476 = bit32.bor(input.flags2476, 0x40000)
	elseif name == "OB_Sprint" then
		input.flags2484 = bit32.bor(input.flags2484, 0x20000)
	elseif name == "OB_Turn" then
		extra.offboard_turn = -scalar()
	elseif name == "OB_Mag" then
		extra.offboard_magnitude = scalar()
	elseif name == "OB_BipedWorldX" then
		extra.biped_world_x = scalar()
	elseif name == "OB_BipedWorldZ" then
		extra.biped_world_z = scalar()
	elseif name == "OB_LookAtX" then
		extra.look_x = scalar()
	elseif name == "OB_LookAtY" then
		extra.look_y = scalar()
	elseif name == "OB_ObjectMvZ" then
		extra.object_move_z = scalar()
	elseif name == "OB_ObjectMvX" then
		extra.object_move_x = scalar()
	elseif name == "OB_ObjectMvRot" then
		extra.object_move_rotation = scalar()
	elseif name == "OneFootAir" then
		extra.flags2480 = bit32.bor(extra.flags2480, 0x04000000)
	elseif name == "WipeoutControlX" then
		extra.wipeout_control[1] = scalar()
	elseif name == "WipeoutControlY" then
		extra.wipeout_control[2] = scalar()
	elseif name == "OB_Mounting" then
		extra.flags2480 = bit32.bor(extra.flags2480, 0x80000)
	elseif name == "OB_Unmounting" then
		extra.flags2480 = bit32.bor(extra.flags2480, 0x40000)
	elseif name == "OB_Dismount" then
		extra.flags2480 = bit32.bor(extra.flags2480, 0x20000)
	elseif name == "OB_HoldBoard" then
		input.flags2476 = bit32.bor(input.flags2476, 0x4000)
	elseif name == "OB_ReleaseBoard" then
		input.flags2476 = bit32.bor(bit32.band(input.flags2476, bit32.bnot(0x3000)), 0x2000)
	elseif name == "OB_ThrowBoard" then
		input.flags2476 = bit32.bor(input.flags2476, 0x3000)
	elseif name == "OB_RetrieveBoard" then
		input.flags2476 = bit32.bor(input.flags2476, 0x800)
	elseif name == "OB_RetrievingBoard" then
		input.flags2476 = bit32.bor(input.flags2476, 0x400)
	elseif name == "OB_DroppingBoard" then
		input.flags2476 = bit32.bor(input.flags2476, 0x200)
	elseif name == "BipedBoardOnGround" then
		input.flags2484 = bit32.bor(input.flags2484, 1)
	elseif name == "IsGroundMount" then
		input.flags2488 = bit32.bor(input.flags2488, 0x80000000)
	elseif name == "FootJump" then
		extra.flags2480 = bit32.bor(extra.flags2480, 0x2000)
	elseif name == "AnimSkateboard" then
		extra.flags2480 = bit32.bor(extra.flags2480, 0x4000)
	elseif name == "HippyJumping" then
		extra.flags2480 = bit32.bor(extra.flags2480, 0x1000)
	elseif name == "PushTricking" then
		extra.flags2480 = bit32.bor(extra.flags2480, 0x800)
	elseif name == "KickoutDismount" then
		extra.flags2480 = bit32.bor(extra.flags2480, 0x100)
	elseif name == "RunoutDismount" then
		extra.flags2480 = bit32.bor(extra.flags2480, 0x80)
	elseif name == "FixLeftFoot" then
		extra.flags2480 = bit32.bor(extra.flags2480, 0x40)
	elseif name == "FixRightFoot" then
		extra.flags2480 = bit32.bor(extra.flags2480, 0x20)
	elseif name == "DoLandOnBoard" then
		extra.flags2480 = bit32.bor(extra.flags2480, 0x10)
	elseif name == "TransitioningOnOffBoard" then
		extra.flags2480 = bit32.bor(extra.flags2480, 4)
	elseif name == "JumpAboutToTakeOff" then
		input.flags2484 = bit32.bor(input.flags2484, 0x40000000)
	elseif name == "JumpInProgress" then
		input.flags2484 = bit32.bor(input.flags2484, 0x20000000)
	elseif name == "OB_JumpX" then
		extra.offboard_jump[1] = -scalar()
	elseif name == "OB_JumpZ" then
		extra.offboard_jump[2] = scalar()
	elseif name == "SkaterOffBoard" then
		input.flags2484 = bit32.bor(input.flags2484, 0x08000000)
	elseif name == "IsDark" then
		input.flags2484 = bit32.bor(input.flags2484, 0x200000)
	elseif name == "GrindTrick" then
		input.flags2484 = bit32.bor(input.flags2484, 0x100000)
	elseif name == "Shoving" then
		input.flags2484 = bit32.bor(input.flags2484, 0x80000)
	elseif name == "ShoveDirection" then
		input.flags2484 = bit32.bor(input.flags2484, 0x40000)
	elseif name == "BipedStartAngle" then
		input.flags2484 = bit32.bor(input.flags2484, 0x4000)
		extra.biped_start_angle = scalar()
	elseif name == "BipedSpinAngle" then
		extra.biped_spin_angle = scalar()
	elseif name == "BipedAnimTime" then
		extra.biped_animation_time = scalar()
	elseif name == "InManualZone" then
		input.flags2484 = bit32.bor(input.flags2484, 0x2000)
	elseif name == "OB_Toggle" then
		input.flags2484 = bit32.bor(input.flags2484, 0x1000)
	elseif name == "TrickFromManual" then
		input.flags2484 = bit32.bor(input.flags2484, 0x800)
	elseif name == "WipeoutGestureStickX" then
		extra.wipeout_gesture[1] = scalar()
	elseif name == "WipeoutGestureStickY" then
		extra.wipeout_gesture[2] = scalar()
	elseif name == "StrongWipeoutArms" then
		input.flags2484 = bit32.bor(input.flags2484, 0x20)
	elseif name == "StrongWipeoutLegs" then
		input.flags2484 = bit32.bor(input.flags2484, 0x10)
	elseif name == "UnderflipBoardContact" then
		output.flags = bit32.bor(output.flags, 0x04000000)
	elseif name == "AudibleFootStepStrength" then
		extra.footstep_strength = scalar()
	elseif name == "IsTakeDownByBoard" then
		output.flags = bit32.bor(output.flags, 0x02000000)
	elseif name == "DropInLock" then
		output.flags = bit32.bor(output.flags, 0x01000000)
	elseif name == "DropInRelease" then
		output.flags = bit32.bor(output.flags, 0x00800000)
	elseif name == "OB_DropIn" then
		output.flags = bit32.bor(output.flags, 0x00400000)
		input.flags2488 = bit32.bor(input.flags2488, 0x10000000)
	elseif name == "BodyAdjustZ" then
		extra.body_adjust[2] = scalar()
	elseif name == "BodyAdjustX" then
		extra.body_adjust[1] = scalar()
	elseif name == "OneFootIntent" then
		input.flags2488 = bit32.bor(input.flags2488, 0x02000000)
	elseif name == "FootPlanting" then
		extra.flags2480 = bit32.bor(extra.flags2480, 0x00800000)
	else
		return false
	end
	return true
end

return extended_attributes
