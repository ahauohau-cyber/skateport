-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local encode = import("skate_core/animation/skeleton_input/name").encode
local eq = import("skate_core/animation/output/attributes").AttributeName.eq
local t1 = {}

t1.ScalarAttribute = {}

function t1.ScalarAttribute.eq(p1, p2) -- line: 25
    -- upvalues: eq (copy)
    if p1.name == p2.name then
        return eq(p1.encoded_name, p2.encoded_name) and p1.comparison_site == p2.comparison_site
    end

    return false
end

function t1.entry(p3, p4) -- line: 31
    -- upvalues: encode (copy)
    return {
        name = p3,
        encoded_name = encode(p3),
        comparison_site = p4
    }
end

t1.SCALAR_ATTRIBUTES = {
    {
        name = "SlideBoard",
        comparison_site = 2193468664,
        encoded_name = encode("SlideBoard")
    },
    {
        name = "SlideNose",
        comparison_site = 2193468688,
        encoded_name = encode("SlideNose")
    },
    {
        name = "SlideTail",
        comparison_site = 2193468712,
        encoded_name = encode("SlideTail")
    },
    {
        name = "Grind5050",
        comparison_site = 2193468736,
        encoded_name = encode("Grind5050")
    },
    {
        name = "Grind5_O",
        comparison_site = 2193468760,
        encoded_name = encode("Grind5_O")
    },
    {
        name = "GrindNose",
        comparison_site = 2193468784,
        encoded_name = encode("GrindNose")
    },
    {
        name = "GrabWorld",
        comparison_site = 2193468808,
        encoded_name = encode("GrabWorld")
    },
    {
        name = "BoardAdjustLeft",
        comparison_site = 2193468848,
        encoded_name = encode("BoardAdjustLeft")
    },
    {
        name = "BoardAdjustRight",
        comparison_site = 2193468884,
        encoded_name = encode("BoardAdjustRight")
    },
    {
        name = "BoardAdjustUp",
        comparison_site = 2193468920,
        encoded_name = encode("BoardAdjustUp")
    },
    {
        name = "BoardAdjustDown",
        comparison_site = 2193468956,
        encoded_name = encode("BoardAdjustDown")
    },
    {
        name = "GrindFacingForwards",
        comparison_site = 2193468992,
        encoded_name = encode("GrindFacingForwards")
    },
    {
        name = "GrindFacingBackwards",
        comparison_site = 2193469036,
        encoded_name = encode("GrindFacingBackwards")
    },
    {
        name = "NoInput",
        comparison_site = 2193469080,
        encoded_name = encode("NoInput")
    },
    {
        name = "ExitGrind",
        comparison_site = 2193469136,
        encoded_name = encode("ExitGrind")
    },
    {
        name = "NewAutoPump",
        comparison_site = 2193469176,
        encoded_name = encode("NewAutoPump")
    },
    {
        name = "EnteringCoffin",
        comparison_site = 2193469220,
        encoded_name = encode("EnteringCoffin")
    },
    {
        name = "InCoffin",
        comparison_site = 2193469272,
        encoded_name = encode("InCoffin")
    },
    {
        name = "LeavingCoffin",
        comparison_site = 2193469324,
        encoded_name = encode("LeavingCoffin")
    },
    {
        name = "PlayingLanding",
        comparison_site = 2193469364,
        encoded_name = encode("PlayingLanding")
    },
    {
        name = "Balance",
        comparison_site = 2193469404,
        encoded_name = encode("Balance")
    },
    {
        name = "Spin",
        comparison_site = 2193469444,
        encoded_name = encode("Spin")
    },
    {
        name = "KickTurn",
        comparison_site = 2193469484,
        encoded_name = encode("KickTurn")
    },
    {
        name = "Anticipating",
        comparison_site = 2193469528,
        encoded_name = encode("Anticipating")
    },
    {
        name = "BodySpin",
        comparison_site = 2193469572,
        encoded_name = encode("BodySpin")
    },
    {
        name = "ManualBrake",
        comparison_site = 2193469612,
        encoded_name = encode("ManualBrake")
    },
    {
        name = "Brake",
        comparison_site = 2193469652,
        encoded_name = encode("Brake")
    },
    {
        name = "Turn",
        comparison_site = 2193469688,
        encoded_name = encode("Turn")
    },
    {
        name = "IsStumbling",
        comparison_site = 2193469728,
        encoded_name = encode("IsStumbling")
    },
    {
        name = "IsWipeoutPushOffImpulse",
        comparison_site = 2193469768,
        encoded_name = encode("IsWipeoutPushOffImpulse")
    },
    {
        name = "IsWipeoutPushOff",
        comparison_site = 2193469808,
        encoded_name = encode("IsWipeoutPushOff")
    },
    {
        name = "IsMuteRFoot",
        comparison_site = 2193469848,
        encoded_name = encode("IsMuteRFoot")
    },
    {
        name = "IsMuteLFoot",
        comparison_site = 2193469888,
        encoded_name = encode("IsMuteLFoot")
    },
    {
        name = "IsForceDownRFoot",
        comparison_site = 2193469928,
        encoded_name = encode("IsForceDownRFoot")
    },
    {
        name = "IsForceDownLFoot",
        comparison_site = 2193469968,
        encoded_name = encode("IsForceDownLFoot")
    },
    {
        name = "TurnScale",
        comparison_site = 2193470008,
        encoded_name = encode("TurnScale")
    },
    {
        name = "MagScale",
        comparison_site = 2193470044,
        encoded_name = encode("MagScale")
    },
    {
        name = "AnimEndCOMX",
        comparison_site = 2193470080,
        encoded_name = encode("AnimEndCOMX")
    },
    {
        name = "AnimEndCOMY",
        comparison_site = 2193470144,
        encoded_name = encode("AnimEndCOMY")
    },
    {
        name = "AnimEndCOMZ",
        comparison_site = 2193470208,
        encoded_name = encode("AnimEndCOMZ")
    },
    {
        name = "AnimTransX",
        comparison_site = 2193470272,
        encoded_name = encode("AnimTransX")
    },
    {
        name = "AnimTransY",
        comparison_site = 2193470336,
        encoded_name = encode("AnimTransY")
    },
    {
        name = "AnimTransZ",
        comparison_site = 2193470400,
        encoded_name = encode("AnimTransZ")
    },
    {
        name = "AnimTime",
        comparison_site = 2193470464,
        encoded_name = encode("AnimTime")
    },
    {
        name = "AnimPhysBlendSec",
        comparison_site = 2193470500,
        encoded_name = encode("AnimPhysBlendSec")
    },
    {
        name = "IsAnimInterpToEdge",
        comparison_site = 2193470536,
        encoded_name = encode("IsAnimInterpToEdge")
    },
    {
        name = "CadenceEndPercent",
        comparison_site = 2193470576,
        encoded_name = encode("CadenceEndPercent")
    },
    {
        name = "OB_Traj",
        comparison_site = 2193470612,
        encoded_name = encode("OB_Traj")
    },
    {
        name = "OB_Air",
        comparison_site = 2193470652,
        encoded_name = encode("OB_Air")
    },
    {
        name = "Carving",
        comparison_site = 2193470692,
        encoded_name = encode("Carving")
    },
    {
        name = "RawTurn",
        comparison_site = 2193470732,
        encoded_name = encode("RawTurn")
    },
    {
        name = "HardTurn",
        comparison_site = 2193470772,
        encoded_name = encode("HardTurn")
    },
    {
        name = "Slide",
        comparison_site = 2193470812,
        encoded_name = encode("Slide")
    },
    {
        name = "FrontFlip",
        comparison_site = 2193470852,
        encoded_name = encode("FrontFlip")
    },
    {
        name = "BackFlip",
        comparison_site = 2193470892,
        encoded_name = encode("BackFlip")
    },
    {
        name = "Grabbing",
        comparison_site = 2193470932,
        encoded_name = encode("Grabbing")
    },
    {
        name = "WantsLeftAirGrab",
        comparison_site = 2193470972,
        encoded_name = encode("WantsLeftAirGrab")
    },
    {
        name = "WantsRightAirGrab",
        comparison_site = 2193470996,
        encoded_name = encode("WantsRightAirGrab")
    },
    {
        name = "FlipTrick",
        comparison_site = 2193471020,
        encoded_name = encode("FlipTrick")
    },
    {
        name = "WipeOutRecover",
        comparison_site = 2193471060,
        encoded_name = encode("WipeOutRecover")
    },
    {
        name = "ControlledWipeout",
        comparison_site = 2193471100,
        encoded_name = encode("ControlledWipeout")
    },
    {
        name = "Revert",
        comparison_site = 2193471140,
        encoded_name = encode("Revert")
    },
    {
        name = "RevertDir",
        comparison_site = 2193471176,
        encoded_name = encode("RevertDir")
    },
    {
        name = "Wipeout",
        comparison_site = 2193471220,
        encoded_name = encode("Wipeout")
    },
    {
        name = "MinJump",
        comparison_site = 2193471260,
        encoded_name = encode("MinJump")
    },
    {
        name = "TrickHeight",
        comparison_site = 2193471292,
        encoded_name = encode("TrickHeight")
    },
    {
        name = "PrepareJump",
        comparison_site = 2193471332,
        encoded_name = encode("PrepareJump")
    },
    {
        name = "jump",
        comparison_site = 2193471464,
        encoded_name = encode("jump")
    },
    {
        name = "DangerZone",
        comparison_site = 2193471504,
        encoded_name = encode("DangerZone")
    },
    {
        name = "LateTrick",
        comparison_site = 2193471544,
        encoded_name = encode("LateTrick")
    },
    {
        name = "NoDangerZone",
        comparison_site = 2193471584,
        encoded_name = encode("NoDangerZone")
    },
    {
        name = "ChristAir",
        comparison_site = 2193471624,
        encoded_name = encode("ChristAir")
    },
    {
        name = "PhysGrindTranslation",
        comparison_site = 2193471712,
        encoded_name = encode("PhysGrindTranslation")
    },
    {
        name = "PhysGrindStabilityNudge",
        comparison_site = 2193471748,
        encoded_name = encode("PhysGrindStabilityNudge")
    },
    {
        name = "PhysGrindUpDown",
        comparison_site = 2193471784,
        encoded_name = encode("PhysGrindUpDown")
    },
    {
        name = "PhysGrindGrabMinHeight",
        comparison_site = 2193471820,
        encoded_name = encode("PhysGrindGrabMinHeight")
    },
    {
        name = "PhysBodySpin",
        comparison_site = 2193471856,
        encoded_name = encode("PhysBodySpin")
    },
    {
        name = "world_grab_y",
        comparison_site = 2193471892,
        encoded_name = encode("world_grab_y")
    },
    {
        name = "world_grab_z",
        comparison_site = 2193471928,
        encoded_name = encode("world_grab_z")
    },
    {
        name = "PushContact",
        comparison_site = 2193471964,
        encoded_name = encode("PushContact")
    },
    {
        name = "NewHandPlant",
        comparison_site = 2193472004,
        encoded_name = encode("NewHandPlant")
    },
    {
        name = "AnimCommittedHandPlant",
        comparison_site = 2193472040,
        encoded_name = encode("AnimCommittedHandPlant")
    },
    {
        name = "DisableFeetTargetIK",
        comparison_site = 2193472076,
        encoded_name = encode("DisableFeetTargetIK")
    },
    {
        name = "OB_Jump",
        comparison_site = 2193472112,
        encoded_name = encode("OB_Jump")
    },
    {
        name = "OB_StandingJump",
        comparison_site = 2193472152,
        encoded_name = encode("OB_StandingJump")
    },
    {
        name = "OB_Sprint",
        comparison_site = 2193472192,
        encoded_name = encode("OB_Sprint")
    },
    {
        name = "OB_Turn",
        comparison_site = 2193472232,
        encoded_name = encode("OB_Turn")
    },
    {
        name = "OB_Mag",
        comparison_site = 2193472272,
        encoded_name = encode("OB_Mag")
    },
    {
        name = "OB_BipedWorldX",
        comparison_site = 2193472308,
        encoded_name = encode("OB_BipedWorldX")
    },
    {
        name = "OB_BipedWorldZ",
        comparison_site = 2193472344,
        encoded_name = encode("OB_BipedWorldZ")
    },
    {
        name = "OB_LookAtX",
        comparison_site = 2193472380,
        encoded_name = encode("OB_LookAtX")
    },
    {
        name = "OB_LookAtY",
        comparison_site = 2193472416,
        encoded_name = encode("OB_LookAtY")
    },
    {
        name = "OB_ObjectMvZ",
        comparison_site = 2193472452,
        encoded_name = encode("OB_ObjectMvZ")
    },
    {
        name = "OB_ObjectMvX",
        comparison_site = 2193472488,
        encoded_name = encode("OB_ObjectMvX")
    },
    {
        name = "OB_ObjectMvRot",
        comparison_site = 2193472524,
        encoded_name = encode("OB_ObjectMvRot")
    },
    {
        name = "PlayerControlledPump",
        comparison_site = 2193472560,
        encoded_name = encode("PlayerControlledPump")
    },
    {
        name = "OneFootAir",
        comparison_site = 2193472600,
        encoded_name = encode("OneFootAir")
    },
    {
        name = "WipeoutControlX",
        comparison_site = 2193472636,
        encoded_name = encode("WipeoutControlX")
    },
    {
        name = "WipeoutControlY",
        comparison_site = 2193472672,
        encoded_name = encode("WipeoutControlY")
    },
    {
        name = "OB_Mounting",
        comparison_site = 2193472708,
        encoded_name = encode("OB_Mounting")
    },
    {
        name = "OB_Unmounting",
        comparison_site = 2193472744,
        encoded_name = encode("OB_Unmounting")
    },
    {
        name = "OB_Dismount",
        comparison_site = 2193472780,
        encoded_name = encode("OB_Dismount")
    },
    {
        name = "OB_HoldBoard",
        comparison_site = 2193472816,
        encoded_name = encode("OB_HoldBoard")
    },
    {
        name = "OB_ReleaseBoard",
        comparison_site = 2193472856,
        encoded_name = encode("OB_ReleaseBoard")
    },
    {
        name = "OB_ThrowBoard",
        comparison_site = 2193472900,
        encoded_name = encode("OB_ThrowBoard")
    },
    {
        name = "OB_RetrieveBoard",
        comparison_site = 2193472940,
        encoded_name = encode("OB_RetrieveBoard")
    },
    {
        name = "OB_RetrievingBoard",
        comparison_site = 2193472980,
        encoded_name = encode("OB_RetrievingBoard")
    },
    {
        name = "OB_DroppingBoard",
        comparison_site = 2193473020,
        encoded_name = encode("OB_DroppingBoard")
    },
    {
        name = "BipedBoardOnGround",
        comparison_site = 2193473060,
        encoded_name = encode("BipedBoardOnGround")
    },
    {
        name = "IsGroundMount",
        comparison_site = 2193473100,
        encoded_name = encode("IsGroundMount")
    },
    {
        name = "FootJump",
        comparison_site = 2193473140,
        encoded_name = encode("FootJump")
    },
    {
        name = "AnimSkateboard",
        comparison_site = 2193473176,
        encoded_name = encode("AnimSkateboard")
    },
    {
        name = "HippyJumping",
        comparison_site = 2193473212,
        encoded_name = encode("HippyJumping")
    },
    {
        name = "PushTricking",
        comparison_site = 2193473248,
        encoded_name = encode("PushTricking")
    },
    {
        name = "KickoutDismount",
        comparison_site = 2193473284,
        encoded_name = encode("KickoutDismount")
    },
    {
        name = "RunoutDismount",
        comparison_site = 2193473320,
        encoded_name = encode("RunoutDismount")
    },
    {
        name = "FixLeftFoot",
        comparison_site = 2193473356,
        encoded_name = encode("FixLeftFoot")
    },
    {
        name = "FixRightFoot",
        comparison_site = 2193473392,
        encoded_name = encode("FixRightFoot")
    },
    {
        name = "DoLandOnBoard",
        comparison_site = 2193473428,
        encoded_name = encode("DoLandOnBoard")
    },
    {
        name = "TransitioningOnOffBoard",
        comparison_site = 2193473464,
        encoded_name = encode("TransitioningOnOffBoard")
    },
    {
        name = "JumpAboutToTakeOff",
        comparison_site = 2193473500,
        encoded_name = encode("JumpAboutToTakeOff")
    },
    {
        name = "JumpInProgress",
        comparison_site = 2193473540,
        encoded_name = encode("JumpInProgress")
    },
    {
        name = "OB_JumpX",
        comparison_site = 2193473580,
        encoded_name = encode("OB_JumpX")
    },
    {
        name = "OB_JumpZ",
        comparison_site = 2193473620,
        encoded_name = encode("OB_JumpZ")
    },
    {
        name = "SkaterOffBoard",
        comparison_site = 2193473656,
        encoded_name = encode("SkaterOffBoard")
    },
    {
        name = "JumpHeightOverride",
        comparison_site = 2193473696,
        encoded_name = encode("JumpHeightOverride")
    },
    {
        name = "IsDark",
        comparison_site = 2193473744,
        encoded_name = encode("IsDark")
    },
    {
        name = "GrindTrick",
        comparison_site = 2193473784,
        encoded_name = encode("GrindTrick")
    },
    {
        name = "Shoving",
        comparison_site = 2193473824,
        encoded_name = encode("Shoving")
    },
    {
        name = "ShoveDirection",
        comparison_site = 2193473864,
        encoded_name = encode("ShoveDirection")
    },
    {
        name = "BipedStartAngle",
        comparison_site = 2193473904,
        encoded_name = encode("BipedStartAngle")
    },
    {
        name = "BipedSpinAngle",
        comparison_site = 2193473952,
        encoded_name = encode("BipedSpinAngle")
    },
    {
        name = "BipedAnimTime",
        comparison_site = 2193473988,
        encoded_name = encode("BipedAnimTime")
    },
    {
        name = "InManualZone",
        comparison_site = 2193474024,
        encoded_name = encode("InManualZone")
    },
    {
        name = "OB_Toggle",
        comparison_site = 2193474064,
        encoded_name = encode("OB_Toggle")
    },
    {
        name = "TrickFromManual",
        comparison_site = 2193474104,
        encoded_name = encode("TrickFromManual")
    },
    {
        name = "WipeoutGestureStickX",
        comparison_site = 2193474144,
        encoded_name = encode("WipeoutGestureStickX")
    },
    {
        name = "WipeoutGestureStickY",
        comparison_site = 2193474180,
        encoded_name = encode("WipeoutGestureStickY")
    },
    {
        name = "StrongWipeoutArms",
        comparison_site = 2193474216,
        encoded_name = encode("StrongWipeoutArms")
    },
    {
        name = "StrongWipeoutLegs",
        comparison_site = 2193474256,
        encoded_name = encode("StrongWipeoutLegs")
    },
    {
        name = "UnderflipBoardContact",
        comparison_site = 2193474296,
        encoded_name = encode("UnderflipBoardContact")
    },
    {
        name = "AudibleFootStepStrength",
        comparison_site = 2193474340,
        encoded_name = encode("AudibleFootStepStrength")
    },
    {
        name = "IsTakeDownByBoard",
        comparison_site = 2193474380,
        encoded_name = encode("IsTakeDownByBoard")
    },
    {
        name = "DropInLock",
        comparison_site = 2193474424,
        encoded_name = encode("DropInLock")
    },
    {
        name = "DropInRelease",
        comparison_site = 2193474468,
        encoded_name = encode("DropInRelease")
    },
    {
        name = "OB_DropIn",
        comparison_site = 2193474512,
        encoded_name = encode("OB_DropIn")
    },
    {
        name = "BodyAdjustZ",
        comparison_site = 2193474568,
        encoded_name = encode("BodyAdjustZ")
    },
    {
        name = "BodyAdjustX",
        comparison_site = 2193474604,
        encoded_name = encode("BodyAdjustX")
    },
    {
        name = "OneFootIntent",
        comparison_site = 2193474640,
        encoded_name = encode("OneFootIntent")
    },
    {
        name = "PushSpeed",
        comparison_site = 2193474680,
        encoded_name = encode("PushSpeed")
    },
    {
        name = "FootPlanting",
        comparison_site = 2193474720,
        encoded_name = encode("FootPlanting")
    }
}

function t1.lookup_reference(p5) -- line: 197
    -- upvalues: t1 (copy), eq (copy)
    for _, v1 in t1.SCALAR_ATTRIBUTES do
        if eq(v1.encoded_name, p5) then
            return v1
        end
    end

    return nil
end

local SCALAR_ATTRIBUTES
local n1 = -1
local t2 = nil

local function build_index() -- line: 219
    -- upvalues: t1 (copy), SCALAR_ATTRIBUTES (ref), n1 (ref), t2 (ref)
    local t3 = {}
    local SCALAR_ATTRIBUTES2 = t1.SCALAR_ATTRIBUTES

    for _, v2 in SCALAR_ATTRIBUTES2 do
        local v3 = v2.encoded_name[1]
        local v4 = t3

        for i = 1, 4 do
            local v5 = v4[v3[i]]

            if v5 ~= nil then
                v4 = v5
            else
                local t4 = {}

                v4[v3[i]] = t4
                v4 = t4
            end
        end

        if v4[v3[5]] == nil then
            v4[v3[5]] = v2
        end
    end

    local v6 = #SCALAR_ATTRIBUTES2

    SCALAR_ATTRIBUTES = SCALAR_ATTRIBUTES2
    n1 = v6
    t2 = t3
end

function t1.lookup(p6) -- line: 240
    -- upvalues: t1 (copy), SCALAR_ATTRIBUTES (ref), n1 (ref), t2 (ref), build_index (copy)
    local SCALAR_ATTRIBUTES2 = t1.SCALAR_ATTRIBUTES
    local v7 = SCALAR_ATTRIBUTES == SCALAR_ATTRIBUTES2

    v7 = v7 and n1 == #SCALAR_ATTRIBUTES2

    if not v7 then
        build_index()
    end

    local v9 = p6[1]
    local v10 = t2[v9[1]]

    if v10 == nil then
        return nil
    end

    local v11 = v10[v9[2]]

    if v11 == nil then
        return nil
    end

    local v12 = v11[v9[3]]

    if v12 == nil then
        return nil
    end

    local v13 = v12[v9[4]]

    return if v13 ~= nil then v13[v9[5]] else nil
end

t1.EVENT_COMPARISONS = {
    {
        name = "push_contact",
        comparison_site = 2193468168,
        encoded_name = encode("push_contact")
    },
    {
        name = "brake_contact",
        comparison_site = 2193468480,
        encoded_name = encode("brake_contact")
    },
    {
        name = "right_hand_grab",
        comparison_site = 2193468568,
        encoded_name = encode("right_hand_grab")
    },
    {
        name = "left_hand_grab",
        comparison_site = 2193468592,
        encoded_name = encode("left_hand_grab")
    },
    {
        name = "righthand",
        comparison_site = 2193468616,
        encoded_name = encode("righthand")
    }
}

return t1
