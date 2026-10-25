-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/camera")
local NumericCondition = import("skate_core/graph/conditions").NumericCondition
local v2 = import("skate_data/state_graph/attributes")
local Attributes, key_hash = v2.Attributes, v2.key_hash
local v3 = import("skate_game/graph_host")
local ShotManager, ManagerSubject = v1.ShotManager, v1.ManagerSubject
local t1 = {
    Condition = {},
    Boolean = {},
    Value = {}
}
local t2 = {
    IsInObserverMode = "Observer",
    IsWipingOut = "WipingOut",
    IsBrokenBoneSlowMo = "BrokenBone",
    IsOffboard = "Offboard",
    IsAirOffboard = "OffboardAir",
    IsInOnBoardAir = "OnboardAir",
    IsFixedInAir = "FixedInAir",
    IsPreparingToJump = "Preparing",
    IsInManual = "Manual",
    SkaterIsDroppingIn = "DroppingIn",
    SkaterIsMovingObject = "MovingObject",
    SkaterIsSkitching = "Skitching",
    SkaterIsPerformingFootPlant = "Footplant",
    SkaterIsPerformingHandPlant = "Handplant",
    SkaterIsPerformingBoneless = "Boneless",
    SkaterIsPerformingHippyJump = "HippyJump",
    SkaterIsPerformingHippyHurdle = "HippyHurdle",
    SkaterIsGrinding = "Grinding",
    SkaterWasGrinding = "WasGrinding",
    IsPlayerSkateboardOnGround = "OnGround",
    IsReentry = "Reentry",
    SkaterIsOnRoad = "Road",
    IsGrindLedgeLeft = "LedgeLeft",
    IsGrindLedgeRight = "LedgeRight",
    IsInWorldPainterRegion = "WorldPainter",
    SkaterIsUnderThreat = "Threat",
    IsCameraInBadCollision = "BadCollision"
}
local t3 = {
    CameraSubjectSpeed = "Speed",
    CameraSubjectSpeedY = "SpeedY",
    CameraSubjectAcceleration = "Acceleration",
    PredictedAirTime = "AirTime",
    PredictedLandingHeight = "LandingHeight",
    PredictedMaxHeight = "MaxHeight",
    PredictedHeightDistanceRatio = "HeightRatio",
    FrontsideAngle = "FrontsideAngle",
    TransferAngle = "TransferAngle",
    LaunchInclineAngle = "LaunchIncline",
    LandingInclineAngle = "LandingIncline",
    GrindInclineAngle = "GrindIncline",
    InclineAngle = "Incline",
    InclineAngleAbs = "AbsoluteIncline",
    TurningCentredTime = "CentredTime",
    TurningTime = "TurningTime",
    TimeSinceLastPlayerInput = "TimeSinceInput"
}

function t1.Condition.parse(p1) -- line: 102
    -- upvalues: Attributes (copy), key_hash (copy), v3 (copy), t1 (copy), t2 (copy), t3 (copy)
    local name = Attributes.text(p1, "name")

    if name == nil then
        error("Camera condition requires name", 0)
    end

    local v4 = t2[name]

    if v4 ~= nil then
        return {
            tag = "Boolean",
            v4
        }
    end

    local v5 = t3[name]

    if v5 ~= nil then
        return {
            tag = "Numeric",
            v5,
            (v3.parse_numeric_condition(p1))
        }
    end

    if name == "IsCameraTypeActive" then
        local type = Attributes.text(p1, "type")

        if type == nil then
            error("IsCameraTypeActive requires type", 0)
        end

        local v6 = if string.find(type, "^%+?%d+$") == nil then nil else tonumber(type)

        if v6 == nil or v6 > 4294967295 then
            error("Invalid normal camera type", 0)
        end

        return {
            tag = "Type",
            v6
        }
    end

    if name == "IsPreviousShot" then
        local t4 = {}

        for _, v7 in t1.shot_names(p1) do
            table.insert(t4, key_hash(v7))
        end

        return {
            tag = "Previous",
            t4
        }
    end

    if name == "IsInVolume" then
        local volume = Attributes.text(p1, "volume")

        if volume == nil then
            error("IsInVolume requires volume", 0)
        end

        return {
            tag = "Volume",
            volume
        }
    end

    if name == "IsWipeoutBodyTweak" then
        local tweak = Attributes.text(p1, "tweak")

        if tweak == nil then
            tweak = ""
        end

        return {
            tag = "Tweak",
            if tweak == "CannonBall" then 1
                elseif tweak == "JudoKick" then 2
                elseif tweak == "SwanDive" then 3
                elseif tweak == "Torpedo" then 4
                else 0
        }
    end

    error(("Unimplemented stock camera condition %*"):format(name), 0)
end

function t1.Condition.evaluate(p2, p3, p4, p5, p6) -- line: 165
    -- upvalues: NumericCondition (copy), key_hash (copy), ShotManager (copy), ManagerSubject (copy)
    local fields = p3.rig.fields
    local state = p3.state
    local tag = p2.tag

    if tag == "Type" then
        return p2[1] == p6.camera_type
    end

    if tag == "Previous" then
        local v8 = key_hash(ShotManager.current(p3.shots).name)

        for _, v9 in p2[1] do
            if v9 == v8 then
                return true
            end
        end

        return false
    end

    if tag == "Tweak" then
        return p2[1] == p5.wipeout_tweak
    end

    if tag == "Volume" then
        local v10 = p2[1]

        for _, v11 in p6.volumes do
            if string.sub(v11, 1, #v10) == v10 then
                return true
            end
        end

        return false
    end

    if tag == "Boolean" then
        local v13 = p2[1]

        if v13 == "Observer" then
            return p4.special_effect ~= 0
        end

        if v13 == "WipingOut" then
            return p4.rig.wiping_out ~= 0
        end

        if v13 == "BrokenBone" then
            return p4.rig.broken_bone_slowmo ~= 0
        end

        if v13 == "Offboard" then
            if p4.rig.off_board == 0 then
                return p5.running_out
            end

            return true
        end

        if v13 == "OffboardAir" then
            return p5.offboard_air
        end

        if v13 == "OnboardAir" then
            return p5.onboard_air
        end

        if v13 == "FixedInAir" then
            return p4.rig.air_flag_452 ~= 0
        end

        if v13 == "Preparing" then
            return p5.preparing_to_jump
        end

        if v13 == "Manual" then
            return p5.manual
        end

        if v13 == "DroppingIn" then
            return p5.dropping_in
        end

        if v13 == "MovingObject" then
            return p5.moving_object
        end

        if v13 == "Skitching" then
            return p5.skitching
        end

        if v13 == "Footplant" then
            return p5.footplant
        end

        if v13 == "Handplant" then
            return p5.handplant
        end

        if v13 == "Boneless" then
            return p5.boneless
        end

        if v13 == "HippyJump" then
            return p5.hippy_jump
        end

        if v13 == "HippyHurdle" then
            return p5.hippy_hurdle
        end

        if v13 == "Grinding" then
            return fields.height_mode == 2
        end

        if v13 == "WasGrinding" then
            return fields.previous_height_mode == 2
        end

        if v13 == "OnGround" then
            return fields.height_mode == 0
        end

        if v13 == "Reentry" then
            return bit32.band(state.flags, 16) ~= 0
        end

        if v13 == "Road" then
            return p6.on_road
        end

        if v13 == "LedgeLeft" then
            return p6.ledge_left
        end

        if v13 == "LedgeRight" then
            return p6.ledge_right
        end

        if v13 == "WorldPainter" or v13 == "Threat" or bit32.band(p3.rig.positioner.flags, 128) == 0 then
            return false
        end

        return p3.rig.positioner.distance < fields.distance * 0.75
    end

    local v14 = p2[1]
    local v15 = p2[2]
    local v16

    if v14 == "Speed" then
        local v17 = p4.rig.transform[3]
        local velocity = fields.velocity

        v16 = velocity[1] * v17[1] + velocity[2] * v17[2] + velocity[3] * v17[3]
    else
        v16 = if v14 == "SpeedY" then fields.velocity[2]
            elseif v14 == "Acceleration" then fields.smoothed_acceleration
            elseif v14 == "AirTime" then ManagerSubject.valid_trajectory_duration(p4)
            elseif v14 == "LandingHeight" then state.landing_height_delta
            elseif v14 == "MaxHeight" then state.apex_height
            elseif v14 == "HeightRatio" then state.apex_height_ratio
            elseif v14 == "FrontsideAngle" then state.frontside_angle
            elseif v14 == "TransferAngle" then state.launch_landing_heading_delta * 57.295780181884766
            elseif v14 == "LaunchIncline" then state.launch_incline * 57.295780181884766
            elseif v14 == "LandingIncline" then state.landing_incline * 57.295780181884766
            elseif v14 == "GrindIncline" then state.direction_incline * 57.295780181884766
            elseif v14 == "Incline" then state.velocity_incline * 57.295780181884766
            elseif v14 == "AbsoluteIncline" then math.abs(state.absolute_velocity_incline * 57.295780181884766)
            elseif v14 == "CentredTime" then state.centred_time
            elseif v14 == "TurningTime" then state.steering_time
            else p5.time_since_player_input
    end

    return NumericCondition.matches(v15, v16)
end

function t1.shot_names(p7) -- line: 293
    -- upvalues: Attributes (copy)
    local t5 = {}
    local n1 = 1

    while true do
        local v19 = Attributes.text(p7, (("shot%*"):format(n1)))

        if v19 == nil then
            break
        end

        table.insert(t5, v19)
        n1 += 1
    end

    return t5
end

return t1
