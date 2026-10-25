-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)
require(sim.import)

local t1 = {
    ExtendedAttributes = {}
}
local t2 = {
    "wipeout_control",
    "offboard_jump",
    "wipeout_gesture",
    "body_adjust",
    "jump_controls"
}
local t3 = {
    "grind_translation",
    "grind_stability_nudge",
    "grind_up_down",
    "grind_grab_min_height",
    "physical_body_spin",
    "world_grab_y",
    "world_grab_z",
    "offboard_turn",
    "offboard_magnitude",
    "biped_world_x",
    "biped_world_z",
    "look_x",
    "look_y",
    "object_move_z",
    "object_move_x",
    "object_move_rotation",
    "biped_start_angle",
    "biped_spin_angle",
    "biped_animation_time",
    "footstep_strength",
    "jump_strength",
    "revert_direction"
}

function t1.ExtendedAttributes.eq(p1, p2) -- line: 39
    -- upvalues: t2 (copy), t3 (copy)
    if p1.flags2480 ~= p2.flags2480 then
        return false
    end

    for _, v1 in t3 do
        if p1[v1] ~= p2[v1] then
            return false
        end
    end

    for _, v2 in t2 do
        if p1[v2][1] ~= p2[v2][1] or p1[v2][2] ~= p2[v2][2] then
            return false
        end
    end

    return true
end

function t1.ExtendedAttributes.reset(p3) -- line: 58
    return {
        flags2480 = 0,
        grind_translation = 0,
        grind_stability_nudge = 0,
        grind_up_down = 0,
        grind_grab_min_height = 0,
        physical_body_spin = 0,
        world_grab_y = 0,
        world_grab_z = 0,
        offboard_turn = 0,
        offboard_magnitude = 0,
        biped_world_x = 0,
        biped_world_z = 0,
        look_x = 0,
        look_y = 0,
        object_move_z = 0,
        object_move_x = 0,
        object_move_rotation = 0,
        biped_start_angle = 0,
        biped_spin_angle = 0,
        biped_animation_time = 0,
        jump_strength = 0,
        revert_direction = 0,
        wipeout_control = { 0, 0 },
        offboard_jump = { 0, 0 },
        wipeout_gesture = { 0, 0 },
        body_adjust = { 0, 0 },
        footstep_strength = p3,
        jump_controls = { 0, 0 }
    }
end

function t1.dispatch(p4, p5, p6, p7, p8) -- line: 95
    if p4 == "Wipeout" then
        p6.flags2468 = bit32.bor(p6.flags2468, 262144)

        return true
    end

    if p4 == "jump" then
        p6.flags2468 = bit32.bor(p6.flags2468, 4194304)

        return true
    end

    if p4 == "DangerZone" then
        p6.flags2472 = bit32.bor(p6.flags2472, 32768)

        return true
    end

    if p4 == "LateTrick" then
        p6.flags2472 = bit32.bor(p6.flags2472, 32)

        return true
    end

    if p4 == "NoDangerZone" then
        p6.flags2472 = bit32.bor(p6.flags2472, 16)

        return true
    end

    if p4 == "ChristAir" then
        p6.flags2472 = bit32.bor(p6.flags2472, 64)

        return true
    end

    if p4 == "PhysGrindTranslation" then
        p7.grind_translation = p5()

        return true
    end

    if p4 == "PhysGrindStabilityNudge" then
        p7.grind_stability_nudge = p5()

        return true
    end

    if p4 == "PhysGrindUpDown" then
        p7.grind_up_down = p5()

        return true
    end

    if p4 == "PhysGrindGrabMinHeight" then
        p7.grind_grab_min_height = p5()

        return true
    end

    if p4 == "PhysBodySpin" then
        p7.physical_body_spin = p5()

        return true
    end

    if p4 == "world_grab_y" then
        p7.world_grab_y = p5()

        return true
    end

    if p4 == "world_grab_z" then
        p7.world_grab_z = p5()

        return true
    end

    if p4 == "NewHandPlant" then
        p7.flags2480 = bit32.bor(p7.flags2480, 536870912)

        return true
    end

    if p4 == "AnimCommittedHandPlant" then
        p7.flags2480 = bit32.bor(p7.flags2480, 268435456)

        return true
    end

    if p4 == "DisableFeetTargetIK" then
        p7.flags2480 = bit32.bor(p7.flags2480, 134217728)

        return true
    end

    if p4 == "OB_Jump" then
        p6.flags2476 = bit32.bor(p6.flags2476, 524288)

        return true
    end

    if p4 == "OB_StandingJump" then
        p6.flags2476 = bit32.bor(p6.flags2476, 262144)

        return true
    end

    if p4 == "OB_Sprint" then
        p6.flags2484 = bit32.bor(p6.flags2484, 131072)

        return true
    end

    if p4 == "OB_Turn" then
        p7.offboard_turn = -p5()

        return true
    end

    if p4 == "OB_Mag" then
        p7.offboard_magnitude = p5()

        return true
    end

    if p4 == "OB_BipedWorldX" then
        p7.biped_world_x = p5()

        return true
    end

    if p4 == "OB_BipedWorldZ" then
        p7.biped_world_z = p5()

        return true
    end

    if p4 == "OB_LookAtX" then
        p7.look_x = p5()

        return true
    end

    if p4 == "OB_LookAtY" then
        p7.look_y = p5()

        return true
    end

    if p4 == "OB_ObjectMvZ" then
        p7.object_move_z = p5()

        return true
    end

    if p4 == "OB_ObjectMvX" then
        p7.object_move_x = p5()

        return true
    end

    if p4 == "OB_ObjectMvRot" then
        p7.object_move_rotation = p5()

        return true
    end

    if p4 == "OneFootAir" then
        p7.flags2480 = bit32.bor(p7.flags2480, 67108864)

        return true
    end

    if p4 == "WipeoutControlX" then
        p7.wipeout_control[1] = p5()

        return true
    end

    if p4 == "WipeoutControlY" then
        p7.wipeout_control[2] = p5()

        return true
    end

    if p4 == "OB_Mounting" then
        p7.flags2480 = bit32.bor(p7.flags2480, 524288)

        return true
    end

    if p4 == "OB_Unmounting" then
        p7.flags2480 = bit32.bor(p7.flags2480, 262144)

        return true
    end

    if p4 == "OB_Dismount" then
        p7.flags2480 = bit32.bor(p7.flags2480, 131072)

        return true
    end

    if p4 == "OB_HoldBoard" then
        p6.flags2476 = bit32.bor(p6.flags2476, 16384)

        return true
    end

    if p4 == "OB_ReleaseBoard" then
        p6.flags2476 = bit32.bor(bit32.band(p6.flags2476, 4294955007), 8192)

        return true
    end

    if p4 == "OB_ThrowBoard" then
        p6.flags2476 = bit32.bor(p6.flags2476, 12288)

        return true
    end

    if p4 == "OB_RetrieveBoard" then
        p6.flags2476 = bit32.bor(p6.flags2476, 2048)

        return true
    end

    if p4 == "OB_RetrievingBoard" then
        p6.flags2476 = bit32.bor(p6.flags2476, 1024)

        return true
    end

    if p4 == "OB_DroppingBoard" then
        p6.flags2476 = bit32.bor(p6.flags2476, 512)

        return true
    end

    if p4 == "BipedBoardOnGround" then
        p6.flags2484 = bit32.bor(p6.flags2484, 1)

        return true
    end

    if p4 == "IsGroundMount" then
        p6.flags2488 = bit32.bor(p6.flags2488, 2147483648)

        return true
    end

    if p4 == "FootJump" then
        p7.flags2480 = bit32.bor(p7.flags2480, 8192)

        return true
    end

    if p4 == "AnimSkateboard" then
        p7.flags2480 = bit32.bor(p7.flags2480, 16384)

        return true
    end

    if p4 == "HippyJumping" then
        p7.flags2480 = bit32.bor(p7.flags2480, 4096)

        return true
    end

    if p4 == "PushTricking" then
        p7.flags2480 = bit32.bor(p7.flags2480, 2048)

        return true
    end

    if p4 == "KickoutDismount" then
        p7.flags2480 = bit32.bor(p7.flags2480, 256)

        return true
    end

    if p4 == "RunoutDismount" then
        p7.flags2480 = bit32.bor(p7.flags2480, 128)

        return true
    end

    if p4 == "FixLeftFoot" then
        p7.flags2480 = bit32.bor(p7.flags2480, 64)

        return true
    end

    if p4 == "FixRightFoot" then
        p7.flags2480 = bit32.bor(p7.flags2480, 32)

        return true
    end

    if p4 == "DoLandOnBoard" then
        p7.flags2480 = bit32.bor(p7.flags2480, 16)

        return true
    end

    if p4 == "TransitioningOnOffBoard" then
        p7.flags2480 = bit32.bor(p7.flags2480, 4)

        return true
    end

    if p4 == "JumpAboutToTakeOff" then
        p6.flags2484 = bit32.bor(p6.flags2484, 1073741824)

        return true
    end

    if p4 == "JumpInProgress" then
        p6.flags2484 = bit32.bor(p6.flags2484, 536870912)

        return true
    end

    if p4 == "OB_JumpX" then
        p7.offboard_jump[1] = -p5()

        return true
    end

    if p4 == "OB_JumpZ" then
        p7.offboard_jump[2] = p5()

        return true
    end

    if p4 == "SkaterOffBoard" then
        p6.flags2484 = bit32.bor(p6.flags2484, 134217728)

        return true
    end

    if p4 == "IsDark" then
        p6.flags2484 = bit32.bor(p6.flags2484, 2097152)

        return true
    end

    if p4 == "GrindTrick" then
        p6.flags2484 = bit32.bor(p6.flags2484, 1048576)

        return true
    end

    if p4 == "Shoving" then
        p6.flags2484 = bit32.bor(p6.flags2484, 524288)

        return true
    end

    if p4 == "ShoveDirection" then
        p6.flags2484 = bit32.bor(p6.flags2484, 262144)

        return true
    end

    if p4 == "BipedStartAngle" then
        p6.flags2484 = bit32.bor(p6.flags2484, 16384)
        p7.biped_start_angle = p5()

        return true
    end

    if p4 == "BipedSpinAngle" then
        p7.biped_spin_angle = p5()

        return true
    end

    if p4 == "BipedAnimTime" then
        p7.biped_animation_time = p5()

        return true
    end

    if p4 == "InManualZone" then
        p6.flags2484 = bit32.bor(p6.flags2484, 8192)

        return true
    end

    if p4 == "OB_Toggle" then
        p6.flags2484 = bit32.bor(p6.flags2484, 4096)

        return true
    end

    if p4 == "TrickFromManual" then
        p6.flags2484 = bit32.bor(p6.flags2484, 2048)

        return true
    end

    if p4 == "WipeoutGestureStickX" then
        p7.wipeout_gesture[1] = p5()

        return true
    end

    if p4 == "WipeoutGestureStickY" then
        p7.wipeout_gesture[2] = p5()

        return true
    end

    if p4 == "StrongWipeoutArms" then
        p6.flags2484 = bit32.bor(p6.flags2484, 32)

        return true
    end

    if p4 == "StrongWipeoutLegs" then
        p6.flags2484 = bit32.bor(p6.flags2484, 16)

        return true
    end

    if p4 == "UnderflipBoardContact" then
        p8.flags = bit32.bor(p8.flags, 67108864)

        return true
    end

    if p4 == "AudibleFootStepStrength" then
        p7.footstep_strength = p5()

        return true
    end

    if p4 == "IsTakeDownByBoard" then
        p8.flags = bit32.bor(p8.flags, 33554432)

        return true
    end

    if p4 == "DropInLock" then
        p8.flags = bit32.bor(p8.flags, 16777216)

        return true
    end

    if p4 == "DropInRelease" then
        p8.flags = bit32.bor(p8.flags, 8388608)

        return true
    end

    if p4 == "OB_DropIn" then
        p8.flags = bit32.bor(p8.flags, 4194304)
        p6.flags2488 = bit32.bor(p6.flags2488, 268435456)

        return true
    end

    if p4 == "BodyAdjustZ" then
        p7.body_adjust[2] = p5()

        return true
    end

    if p4 == "BodyAdjustX" then
        p7.body_adjust[1] = p5()

        return true
    end

    if p4 == "OneFootIntent" then
        p6.flags2488 = bit32.bor(p6.flags2488, 33554432)

        return true
    end

    if p4 ~= "FootPlanting" then
        return false
    end

    p7.flags2480 = bit32.bor(p7.flags2480, 8388608)

    return true
end

return t1
