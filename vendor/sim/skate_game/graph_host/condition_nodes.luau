-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local v1 = buffer.create(8)

local function rtl_from_bits(p1) -- line: 7
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p1)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local v2 = import("skate_core/graph/conditions")
local v3 = import("skate_core/animation/output/attributes")
local Attributes = import("skate_data/state_graph/attributes").Attributes
local Binding = import("skate_data/state_graph/binding").Binding
local NumericCondition = v2.NumericCondition
local AttributeName = v3.AttributeName
local t1 = {}

function t1.animation_attribute(p2, p3, p4, p5) -- line: 38
    -- upvalues: v1 (copy), NumericCondition (copy), AttributeName (copy)
    local v4

    for _, v5 in p2 do
        if AttributeName.eq(v5.name, p3) then
            v4 = v5
            break
        end
    end

    if v4 == nil or p4 ~= -1 and p4 ~= v4.sequence_id then
        return false
    end

    if p5.comparison == "None" or v4.kind ~= 0 and v4.kind ~= 2 then
        return true
    end

    local v6 = v4.payload[1][1]

    if v6 == nil then
        return false
    end

    local matches = NumericCondition.matches

    buffer.writeu32(v1, 0, v6)

    return (matches(p5, (buffer.readf32(v1, 0))))
end

function t1.state_time(p6, p7, p8) -- line: 64
    -- upvalues: NumericCondition (copy)
    if p7 == nil then
        return false
    end

    local v7 = p6.state_times[p7 + 1]

    return v7 ~= nil and not (v7 < 0) and NumericCondition.matches(p8, v7)
end

local function text_or(p9, p10, p11) -- line: 75
    -- upvalues: Attributes (copy)
    local v8 = Attributes.text(p9, p10)

    if v8 == nil then
        return p11
    end

    return v8
end

function t1.parse(p12) -- line: 84
    -- upvalues: Attributes (copy), t1 (copy)
    local name = Attributes.text(p12, "name")

    if name == nil then
        name = ""
    end

    if name == "HasAGIntent" then
        local t2 = {
            tag = "HasIntent"
        }
        local intent = Attributes.text(p12, "intent")

        t2.name = if intent == nil then "" else intent
        t2.numeric = t1.numeric(p12)

        return t2
    end

    if name == "TimeSinceLastInput" then
        return {
            tag = "TimeSinceLastInput",
            (t1.numeric(p12))
        }
    end

    if name == "PhysicsSpeedCompare" then
        return {
            tag = "Speed",
            along_skate_z = Attributes.boolean_byte(p12, "alongSkateZ", 0) ~= 0,
            numeric = t1.numeric(p12)
        }
    end

    if name == "PhysicsSpeedAndSlopeCompare" then
        return {
            tag = "SpeedAndSlope",
            (t1.numeric(p12))
        }
    end

    if name == "PhysFilteredState" then
        local state = Attributes.text(p12, "state")

        if state == nil then
            state = ""
        end

        local v9

        if state == "invalid" then
            v9 = 0
        elseif state == "ground" then
            v9 = 1
        elseif state == "air" then
            v9 = 2
        elseif state == "grind" then
            v9 = 3
        elseif state == "wipeout" then
            v9 = 4
        elseif state == "teleport" then
            v9 = 5
        elseif state == "offboard" then
            v9 = 6
        elseif state == "offboardair" then
            v9 = 7
        else
            error(string.format("PhysFilteredState has undefined state `%s`", state), 0)
        end

        return {
            tag = "FilteredState",
            v9
        }
    end

    if name == "IsGrinding" then
        return {
            tag = "Grinding",
            name = Attributes.text(p12, "grindName")
        }
    end

    if name == "IsMirrored" then
        return {
            tag = "Mirrored"
        }
    end

    if name == "IsRidingFakie" then
        return {
            tag = "RidingFakie"
        }
    end

    if name == "DisablePushBrake" then
        return {
            tag = "DisablePushBrake"
        }
    end

    if name ~= "CurrentState" then
        return nil
    end

    local t3 = {
        tag = "CurrentState",
        target = nil
    }
    local state = Attributes.text(p12, "state")

    t3.name = if state == nil then "" else state

    return t3
end

local t4 = {
    { "Equal", "equal" },
    { "NotEqual", "notEqual" },
    { "Greater", "greater" },
    { "GreaterAbsolute", "greaterThanAbs" },
    { "Less", "less" },
    { "GreaterEqual", "greaterEqual" },
    { "LessEqual", "lessEqual" }
}

function t1.numeric(p13) -- line: 155
    -- upvalues: v1 (copy), Attributes (copy), t4 (copy)
    local comparison = Attributes.text(p13, "comparison")
    local v10, v11

    if comparison ~= nil then
        v10 = if comparison == "NotEqual" then "NotEqual"
            elseif comparison == "GreaterThan" then "Greater"
            elseif comparison == "LessThan" then "Less"
            elseif comparison == "GreaterEqual" then "GreaterEqual"
            elseif comparison == "LessEqual" then "LessEqual"
            else "Equal"
        v11 = "value"
    else
        v10 = "None"
        v11 = ""

        for _, v12 in t4 do
            if Attributes.get(p13, v12[2]) ~= nil then
                v10 = v12[1]
                v11 = v12[2]
                break
            end

            v10 = "None"
            v11 = ""
        end
    end

    local t5 = {
        comparison = v10
    }

    buffer.writeu32(v1, 0, (Attributes.float_bits(p13, v11, 0)))
    t5.threshold = buffer.readf32(v1, 0)
    t5.absolute = Attributes.boolean_byte(p13, "abs", 0) ~= 0

    return t5
end

local function state_for_element(p14, p15) -- line: 193
    for v14, v15 in p14.binding.states do
        if v15.element == p15 then
            return v14 - 1
        end
    end

    return nil
end

function t1.bind_current_states(p16, p17) -- line: 203
    -- upvalues: Binding (copy)
    local t6 = {}

    for v16, v17 in p16.source.elements do
        local v18 = v16 - 1

        for _, v19 in v17.children do
            t6[v19 + 1] = v18
        end
    end

    for _, v20 in p16.runtime.operations.conditions do
        local operation = p17.operations[v20 + 1].operation

        if operation.tag == "ExtraCondition" then
            if operation[1].tag == "ParentTime" then
                local v21 = operation[1]
                local v22 = t6[p16.binding.operations[v20 + 1].element + 1]

                while v22 ~= nil do
                    local v23 = false
                    local v24

                    for v25, v26 in p16.binding.states do
                        if v26.element == v22 then
                            v24 = v25 - 1
                            v23 = true
                            break
                        end
                    end

                    if not v23 then
                        v24 = nil
                    end

                    if v24 == nil then
                        v22 = t6[v22 + 1]
                        continue
                    end

                    v21.target = v24
                    break
                end
            elseif operation.tag == "Condition" and operation[1].tag == "CurrentState" then
                local v27 = operation[1]
                local v28 = t6[p16.binding.operations[v20 + 1].element + 1]

                while true do
                    if v28 ~= nil then
                        local v29 = false
                        local v30

                        for v31, v32 in p16.binding.states do
                            if v32.element == v28 then
                                v30 = v31 - 1
                                v29 = true
                                break
                            end
                        end

                        if not v29 then
                            v30 = nil
                        end

                        if v30 == nil then
                            v28 = t6[v28 + 1]
                            continue
                        end

                        v27.target = Binding.find_state(p16.binding, v30, v27.name, true)
                    end

                    break
                end
            end
        elseif operation.tag == "Condition" and operation[1].tag == "CurrentState" then
            local v33 = operation[1]
            local v34 = t6[p16.binding.operations[v20 + 1].element + 1]

            while true do
                if v34 ~= nil then
                    local v35 = false
                    local v36

                    for v37, v38 in p16.binding.states do
                        if v38.element == v34 then
                            v36 = v37 - 1
                            v35 = true
                            break
                        end
                    end

                    if not v35 then
                        v36 = nil
                    end

                    if v36 == nil then
                        v34 = t6[v34 + 1]
                        continue
                    end

                    v33.target = Binding.find_state(p16.binding, v36, v33.name, true)
                end

                break
            end
        end
    end
end

return t1
