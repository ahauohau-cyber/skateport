-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_subnormal_mantissa(p1) -- line: 7
    local v2 = p1 * 7.1362384635298E+44
    local v3 = math.floor(v2)
    local v4 = v2 - v3

    if v4 > 0.5 or v4 == 0.5 and v3 % 2 == 1 then
        return v3 + 1
    end

    return v3
end

local function rtl_to_bits(p2) -- line: 16
    -- upvalues: v1 (copy)
    if p2 ~= 0 and p2 > -1.1754943508222875E-38 and p2 < 1.1754943508222875E-38 then
        local v6 = math.abs(p2) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        if p2 < 0 then
            return v5 + 2147483648
        end

        return v5
    end

    buffer.writef32(v1, 0, p2)

    return (buffer.readu32(v1, 0))
end

local function rtl_from_bits(p3) -- line: 24
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p3)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local encode = import("skate_core/animation/skeleton_input/name").encode
local NumericCondition = import("skate_core/graph/conditions").NumericCondition
local IntentMap = import("skate_core/graph/intents").IntentMap
local Attributes = import("skate_data/state_graph/attributes").Attributes
local Group = import("skate_game/input/gesture_catalog").Group
local v8 = import("skate_game/graph_host/condition_nodes")
local v9

local function motion_gameplay_conditions() -- line: 43
    -- upvalues: import (copy), v9 (ref)
    local v10 = v9

    if v10 == nil then
        v10 = import("skate_game/graph_host/motion_gameplay_conditions")
        v9 = v10
    end

    return v10
end

local v11

local function motion_dismount() -- line: 53
    -- upvalues: import (copy), v11 (ref)
    local v12 = v11

    if v12 == nil then
        v12 = import("skate_game/graph_host/motion_offboard/dismount")
        v11 = v12
    end

    return v12
end

local t1 = {
    ActionCondition = {}
}

local function text_or(p4, p5, p6) -- line: 77
    -- upvalues: Attributes (copy)
    local v13 = Attributes.text(p4, p5)

    if v13 == nil then
        return p6
    end

    return v13
end

function t1.ActionCondition.parse(p7) -- line: 86
    -- upvalues: rt (copy), v1 (copy), import (copy), encode (copy), Attributes (copy), Group (copy), v8 (copy), v9 (ref)
    local name = Attributes.text(p7, "name")

    if name == nil then
        name = ""
    end

    if name == "HasGestureIntent" then
        local parse = Group.parse
        local group = Attributes.text(p7, "group")

        if group == nil then
            group = ""
        end

        return {
            tag = "Gesture",
            (parse(group))
        }
    end

    if name == "HasAnimAttribute" then
        local t3 = {
            tag = "AnimationAttribute"
        }
        local attribute = Attributes.text(p7, "attribute")

        if attribute == nil then
            attribute = ""
        end

        t3.name = encode(attribute)

        local f_to_i32 = rt.f_to_i32
        local float_bits = Attributes.float_bits

        buffer.writef32(v1, 0, -1)
        buffer.writeu32(v1, 0, (float_bits(p7, "sequenceid", (buffer.readu32(v1, 0)))))
        t3.sequence_id = f_to_i32((buffer.readf32(v1, 0)))
        t3.numeric = v8.numeric(p7)

        return t3
    end

    if name == "InParentStateForTime" then
        return {
            tag = "ParentTime",
            target = nil,
            numeric = v8.numeric(p7)
        }
    end

    if name ~= "IsGrabbingObject" and name ~= "IsHandPlanting" and name ~= "IsFootPlanting" then
        if name == "IsDroppingIn" then
            return {
                tag = "DroppingIn"
            }
        end

        if name == "IsTricking" then
            return {
                tag = "Tricking"
            }
        end

        if name == "IsInLocomotion" then
            return {
                tag = "InLocomotion"
            }
        end

        if name == "DisableDismount" then
            return {
                tag = "DisableDismount"
            }
        end

        return if name == "TimeToLand" then {
            tag = "TimeToLand",
            (v8.numeric(p7))
        } else nil
    end

    local v15 = v9

    if v15 == nil then
        v15 = import("skate_game/graph_host/motion_gameplay_conditions")
        v9 = v15
    end

    return {
        tag = "Physical",
        (v15.GameplayCondition.parse(p7))
    }
end

function t1.ActionCondition.evaluate(p8, p9, p10) -- line: 121
    -- upvalues: rt (copy), import (copy), NumericCondition (copy), IntentMap (copy), Group (copy), v8 (copy), v9 (ref), v11 (ref)
    local tag = p8.tag

    if tag == "Gesture" then
        return Group.has_intent(p8[1], function(p11) -- line: 124
            -- upvalues: p9 (copy), IntentMap (copy)
            return IntentMap.contains_key(p9.action_intents, p11)
        end)
    end

    if tag == "AnimationAttribute" then
        return v8.animation_attribute(p9.animation_attributes, rt.copy(p8.name), p8.sequence_id, rt.copy(p8.numeric))
    end

    if tag == "ParentTime" then
        return v8.state_time(p10, p8.target, rt.copy(p8.numeric))
    end

    if tag == "Physical" then
        local gameplay_conditions = p9.gameplay_conditions

        if gameplay_conditions == nil then
            error("ActionGraph requires actual physical condition outputs", 0)
        end

        local v16 = v9

        if v16 == nil then
            v16 = import("skate_game/graph_host/motion_gameplay_conditions")
            v9 = v16
        end

        local v17 = v16.GameplayCondition.evaluate_physical(p8[1], gameplay_conditions)

        if v17 == nil then
            error("Condition is not a physical-only original leaf", 0)
        end

        return v17
    end

    if tag == "DroppingIn" then
        if p9.dropping_in == nil then
            error("IsDroppingIn requires completed grind output", 0)
        end

        return p9.dropping_in
    end

    if tag == "Tricking" then
        if p9.is_tricking == nil then
            error("IsTricking requires actual MotionGraph flag27", 0)
        end

        return p9.is_tricking
    end

    if tag == "InLocomotion" then
        return false
    end

    if tag == "DisableDismount" then
        local v18 = v11

        if v18 == nil then
            v18 = import("skate_game/graph_host/motion_offboard/dismount")
            v11 = v18
        end

        return v18.Condition.evaluate({}, p9.condition_inputs.push_brake)
    end

    local v19 = p8[1]
    local gameplay_conditions = p9.gameplay_conditions

    if gameplay_conditions == nil then
        error("ActionGraph TimeToLand requires actual physical condition outputs", 0)
    end

    return gameplay_conditions.time_to_land_valid and NumericCondition.matches(v19, gameplay_conditions.time_to_land)
end

return t1
