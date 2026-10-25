-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local IntentMap = import("skate_core/graph/intents").IntentMap
local v1 = import("skate_core/trigonometry")
local v2 = import("skate_core/animation/skeleton_input/name")
local AttributeName = import("skate_core/animation/output/attributes").AttributeName
local t1 = {
    Comparison = {},
    NumericCondition = {}
}
local NumericCondition = t1.NumericCondition

function t1.NumericCondition.eq(p1, p2) -- line: 27
    if p1.comparison == p2.comparison and p1.threshold == p2.threshold then
        return p1.absolute == p2.absolute
    end

    return false
end

function t1.NumericCondition.matches(p3, p4) -- line: 33
    local v3 = if p3.absolute then math.abs(p4) else p4
    local comparison = p3.comparison

    if comparison == "None" then
        return false
    end

    if comparison == "Equal" then
        return v3 == p3.threshold
    end

    if comparison == "NotEqual" then
        return v3 ~= p3.threshold
    end

    if comparison == "Greater" then
        return p3.threshold < v3
    end

    if comparison == "Less" then
        return v3 < p3.threshold
    end

    if comparison == "GreaterEqual" then
        return not (v3 < p3.threshold)
    end

    if comparison == "LessEqual" then
        return not (p3.threshold < v3)
    end

    return math.abs(v3) > p3.threshold
end

t1.SpeedInputs = {}

function t1.SpeedInputs.eq(p5, p6) -- line: 63
    if p5.speed == p6.speed and p5.forward_speed == p6.forward_speed then
        return p5.speed_and_slope == p6.speed_and_slope
    end

    return false
end

t1.PhysicalStateInputs = {}

function t1.PhysicalStateInputs.eq(p7, p8) -- line: 73
    if p7.category == p8.category and p7.grinding == p8.grinding then
        return p7.grind_name == p8.grind_name
    end

    return false
end

t1.PushBrakeInputs = {}

local PushBrakeInputs = t1.PushBrakeInputs

function t1.PushBrakeInputs.eq(p9, p10) -- line: 87
    if p9.ground_axis_y == p10.ground_axis_y and p9.skeleton_disables_push_brake == p10.skeleton_disables_push_brake then
        return p9.maximum_ground_angle_degrees == p10.maximum_ground_angle_degrees
    end

    return false
end

function t1.PushBrakeInputs.disabled(p11) -- line: 95
    -- upvalues: v1 (copy)
    if 90 - v1.asin(p11.ground_axis_y) * 57.295780181884766 > p11.maximum_ground_angle_degrees then
        return true
    end

    return p11.skeleton_disables_push_brake
end

t1.ConditionInputs = {}

function t1.ConditionInputs.default() -- line: 111
    return {
        speeds = nil,
        physical_state = nil,
        time_since_last_input = nil,
        mirrored = nil,
        riding_fakie = nil,
        push_brake = nil
    }
end

t1.ActionCondition = {}

function t1.ActionCondition.evaluate(p12, p13, p14, p15, p16) -- line: 137
    -- upvalues: IntentMap (copy), v2 (copy), AttributeName (copy), NumericCondition (copy), PushBrakeInputs (copy)
    local tag = p12.tag

    if tag == "HasIntent" then
        local v4 = IntentMap.get(p14, p12.name)

        if v4 == nil then
            return false
        end

        if p12.numeric.comparison == "None" then
            return true
        end

        return (NumericCondition.matches(p12.numeric, v4))
    end

    if tag == "TimeSinceLastInput" then
        local time_since_last_input = p13.time_since_last_input

        if time_since_last_input == nil then
            error("TimeSinceLastInput needs PhysOut miscellaneous+128", 0)
        end

        return NumericCondition.matches(p12[1], time_since_last_input)
    end

    if tag == "Speed" then
        local speeds = p13.speeds

        if speeds == nil then
            error("PhysicsSpeedCompare needs skateboard output", 0)
        end

        return NumericCondition.matches(p12.numeric, if p12.along_skate_z then speeds.forward_speed else speeds.speed)
    end

    if tag == "SpeedAndSlope" then
        local speeds = p13.speeds

        if speeds == nil then
            error("PhysicsSpeedAndSlopeCompare needs skateboard output+192", 0)
        end

        return NumericCondition.matches(p12[1], speeds.speed_and_slope)
    end

    if tag == "FilteredState" then
        local physical_state = p13.physical_state

        if physical_state == nil then
            error("PhysFilteredState needs filtered physical state", 0)
        end

        return physical_state.category == p12[1]
    end

    if tag == "Grinding" then
        local physical_state = p13.physical_state

        if physical_state == nil then
            error("IsGrinding needs filtered physical state", 0)
        end

        if not physical_state.grinding then
            return false
        end

        local name = p12.name

        if name == nil then
            return true
        end

        return AttributeName.eq(v2.encode(name), v2.encode(physical_state.grind_name))
    end

    if tag == "Mirrored" then
        local mirrored = p13.mirrored

        if mirrored == nil then
            error("IsMirrored needs the motion-graph stance owner", 0)
        end

        return mirrored
    end

    if tag == "RidingFakie" then
        local riding_fakie = p13.riding_fakie

        if riding_fakie == nil then
            error("IsRidingFakie needs the motion-graph stance owner", 0)
        end

        return riding_fakie
    end

    if tag == "DisablePushBrake" then
        local push_brake = p13.push_brake

        if push_brake == nil then
            error("DisablePushBrake needs ground/skeleton outputs and stock angle", 0)
        end

        return PushBrakeInputs.disabled(push_brake)
    end

    local target = p12.target

    if target == nil then
        return false
    end

    local v5 = p15

    while true do
        if v5 == nil then
            return false
        end

        if v5 == target then
            break
        end

        v5 = p16[v5 + 1]
    end

    return true
end

return t1
