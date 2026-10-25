-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/graph_host/pushing_settings")
local IntentMap = import("skate_core/graph/intents").IntentMap
local v2 = import("skate_core/riding/push_behaviors")
local v3 = import("skate_core/riding/push_animation")
local Attributes = import("skate_data/state_graph/attributes").Attributes
local PushingSettings = v1.PushingSettings
local FirstPushStrength, PushCycle, PushFootFrame, PushState = v2.FirstPushStrength, v2.PushCycle, v2.PushFootFrame, v2.PushState
local PushAttributes = v2.PushAttributes
local PushAnimationCurves = v3.PushAnimationCurves
local t1 = {}

t1.PushOperation = {}

function t1.PushOperation.eq(p1, p2) -- line: 35
    if p1.tag == p2.tag and p1.regular_attributes == p2.regular_attributes and p1.on_first_update_only == p2.on_first_update_only and p1.new_push_name == p2.new_push_name then
        return p1.is_right_foot == p2.is_right_foot
    end

    return false
end

function t1.PushOperation.from_attributes(p3) -- line: 46
    -- upvalues: Attributes (copy)
    local name = Attributes.text(p3, "name")

    if name ~= nil then
        if name == "InitPush" then
            return {
                tag = "InitPush"
            }
        end

        if name == "ComputeFirstPushStrength" then
            return {
                tag = "ComputeFirstPushStrength"
            }
        end

        if name == "ComputeTargetCoefsFromSpeedAndStrength" then
            return {
                tag = "ComputeTargetCoefsFromSpeedAndStrength",
                regular_attributes = Attributes.boolean_byte(p3, "regularAttributes", 1) ~= 0
            }
        end

        if name == "ComputeRepushDeadline" then
            return {
                tag = "ComputeRepushDeadline",
                regular_attributes = Attributes.boolean_byte(p3, "regularAttributes", 1) ~= 0
            }
        end

        if name == "SetPushCoefs" then
            return {
                tag = "SetPushCoefs",
                on_first_update_only = Attributes.boolean_byte(p3, "onFirstUpdateOnly", 0) ~= 0
            }
        end

        if name == "PushCycle" then
            local newPushName = Attributes.text(p3, "newPushName")

            if newPushName == nil then
                newPushName = "LeftPush"
            end

            return {
                tag = "PushCycle",
                new_push_name = newPushName
            }
        end

        if name == "PushOut" then
            return {
                tag = "PushOut",
                is_right_foot = Attributes.boolean_byte(p3, "isRightFoot", 1) ~= 0
            }
        end
    end

    return nil
end

t1.SettableAttribute = {}

function t1.SettableAttribute.eq(p4, p5) -- line: 92
    if p4.name == p5.name and p4.value == p5.value and p4.normalized == p5.normalized then
        return p4.sequence_id == p5.sequence_id
    end

    return false
end

t1.PushAnimationSink = {}
t1.VecSettableAttribute = {}

function t1.VecSettableAttribute.set_attribute(p6, p7) -- line: 112
    -- upvalues: rt (copy)
    local v4

    for _, v5 in p6 do
        if v5.name == p7.name and v5.sequence_id == p7.sequence_id then
            v4 = v5
            break
        end
    end

    if v4 ~= nil then
        rt.assign(v4, p7)
    else
        table.insert(p6, rt.copy(p7))
    end
end

t1.PushContext = {}

function t1.PushContext.intents(p8, p9) -- line: 141
    -- upvalues: IntentMap (copy)
    return {
        pushing = IntentMap.get(p8.motion_intents, "Pushing"),
        new_push = IntentMap.contains_key(p8.motion_intents, "NewPush"),
        configured_foot = IntentMap.contains_key(p8.motion_intents, p9)
    }
end

t1.PushInstance = {}

function t1.PushInstance.new(p10) -- line: 157
    return {
        first_strength = nil,
        cycle = nil,
        first_update = false,
        operation = p10
    }
end

function t1.PushInstance.begin(p11, p12, p13) -- line: 167
    -- upvalues: t1 (copy), FirstPushStrength (copy), PushCycle (copy), PushFootFrame (copy), PushState (copy)
    local operation = p11.operation
    local tag = operation.tag

    if tag == "InitPush" then
        PushState.initialize_push(p12.shared)
    elseif tag == "ComputeFirstPushStrength" then
        p11.first_strength = FirstPushStrength.begin(p12.time_since_teleport, p12.settings.teleport_window)
    elseif tag == "SetPushCoefs" then
        p11.first_update = true
    elseif tag == "PushCycle" then
        local v6 = t1.PushContext.intents(p12, operation.new_push_name)

        p11.cycle = PushCycle.begin(p12.shared, p12.settings.curves, v6)
    elseif tag == "PushOut" then
        local v7, v8

        if p12.foot_frame ~= nil then
            local v9 = PushFootFrame.out_distance(p12.foot_frame, operation.is_right_foot)

            v7 = v9[1]
            v8 = v9[2]
        else
            v7 = 0
            v8 = 0
        end

        t1.publish(p13, "OutDistanceX", v7, false)
        t1.publish(p13, "OutDistanceY", v8, false)
    end
end

function t1.PushInstance.update(p14, p15, p16) -- line: 193
    -- upvalues: rt (copy), IntentMap (copy), t1 (copy), PushingSettings (copy), FirstPushStrength (copy), PushCycle (copy), PushAttributes (copy), PushAnimationCurves (copy)
    local operation = p14.operation
    local tag = operation.tag

    if tag == "ComputeFirstPushStrength" then
        if p14.first_strength == nil then
            error("ComputeFirstPushStrength updated before Begin", 0)
        end

        FirstPushStrength.update(p14.first_strength, p15.shared, p15.settings.curves, IntentMap.get(p15.motion_intents, "Pushing"), p15.forward_speed, p15.delta_seconds)
    elseif tag == "ComputeTargetCoefsFromSpeedAndStrength" then
        p15.shared.target = PushAttributes.target(PushingSettings.attributes(p15.settings, operation.regular_attributes, p15.is_switch), p15.forward_speed, p15.shared.current_push_dv)
    elseif tag == "SetPushCoefs" then
        if not operation.on_first_update_only or p14.first_update then
            p15.shared.current = PushAnimationCurves.update_blend(p15.settings.curves, rt.copy(p15.shared.current), rt.copy(p15.shared.target), p15.forward_speed, p15.delta_seconds)

            local v10 = rt.copy(p15.shared.current)

            t1.publish(p16, "HStr_Vel_B", v10.hstr_vel_b, true)
            t1.publish(p16, "LStr_Vel_B", v10.lstr_vel_b, true)
            t1.publish(p16, "Vel_E", v10.vel_e, true)
        end

        p14.first_update = false
    elseif tag == "PushCycle" then
        local v11 = t1.PushContext.intents(p15, operation.new_push_name)

        if p14.cycle == nil then
            error("PushCycle updated before Begin", 0)
        end

        PushCycle.update(p14.cycle, p15.shared, p15.settings.curves, v11, p15.forward_speed, p15.settings.maximum_holding_acceleration)
    end
end

t1.PushInstance["end"] = function(p17, p18) -- line: 246
    -- upvalues: PushingSettings (copy), PushAttributes (copy)
    local operation = p17.operation

    if operation.tag == "ComputeRepushDeadline" then
        p18.shared.out_factor = PushAttributes.out_factor(PushingSettings.attributes(p18.settings, operation.regular_attributes, p18.is_switch), p18.forward_speed, p18.shared.current_push_dv, p18.settings.out_speed_weight, p18.settings.maximum_out_factor)
    end
end

function t1.publish(p19, p20, p21, p22) -- line: 260
    p19.set_attribute(p19, {
        sequence_id = -1,
        name = p20,
        value = p21,
        normalized = p22
    })
end

return t1
