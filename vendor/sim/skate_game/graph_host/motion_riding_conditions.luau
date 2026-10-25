-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local NumericCondition = import("skate_core/graph/conditions").NumericCondition
local Vector3 = import("skate_core/math").Vector3
local v1 = import("skate_core/physics/board_motion_output")
local dot, length = v1.dot, v1.length
local v2 = import("skate_core/trigonometry")
local Attributes = import("skate_data/state_graph/attributes").Attributes
local v3

local function condition_nodes() -- line: 22
    -- upvalues: import (copy), v3 (ref)
    local v4 = v3

    if v4 == nil then
        v4 = import("skate_game/graph_host/condition_nodes")
        v3 = v4
    end

    return v4
end

local t1 = {
    RidingConditionInputs = {},
    VelocityAxis = {},
    MotionRidingCondition = {}
}

function t1.MotionRidingCondition.recognizes(p1) -- line: 53
    if p1 == "RandomCond" or p1 == "ComVelCompare" or p1 == "SkateSlope" then
        return true
    end

    return p1 == "SurfaceSlope"
end

function t1.MotionRidingCondition.parse(p2) -- line: 58
    -- upvalues: import (copy), Attributes (copy), v3 (ref)
    local name = Attributes.text(p2, "name")

    if name == nil then
        name = ""
    end

    if name == "RandomCond" then
        return {
            tag = "Random"
        }
    end

    if name == "ComVelCompare" then
        local axis = Attributes.text(p2, "axis")

        if axis == nil then
            axis = "0"
        end

        local v5 = string.byte(axis, 1)
        local t2 = {
            tag = "ComVelocity",
            axis = if v5 == 120 or v5 == 88 then "X"
                elseif v5 == 121 or v5 == 89 then "Y"
                elseif v5 == 122 or v5 == 90 then "Z"
                else "All"
        }
        local v6 = v3

        if v6 == nil then
            v6 = import("skate_game/graph_host/condition_nodes")
            v3 = v6
        end

        t2.numeric = v6.numeric(p2)

        return t2
    end

    if name == "SkateSlope" then
        local v7 = v3

        if v7 == nil then
            v7 = import("skate_game/graph_host/condition_nodes")
            v3 = v7
        end

        return {
            tag = "SkateSlope",
            (v7.numeric(p2))
        }
    end

    if name == "SurfaceSlope" then
        local v8 = v3

        if v8 == nil then
            v8 = import("skate_game/graph_host/condition_nodes")
            v3 = v8
        end

        return {
            tag = "SurfaceSlope",
            (v8.numeric(p2))
        }
    end

    error("Unknown riding condition " .. name, 0)
end

function t1.MotionRidingCondition.evaluate(p3, p4) -- line: 99
    -- upvalues: NumericCondition (copy), dot (copy), length (copy), t1 (copy)
    if p3.tag == "Random" then
        return bit32.band(t1.MotionRandom.next_u32(p4.condition_random), 1) == 0
    end

    local riding_conditions = p4.riding_conditions

    if riding_conditions == nil then
        error("MotionGraph requires the actual COM and slope publication", 0)
    end

    if p3.tag == "ComVelocity" then
        local axis, numeric = p3.axis, p3.numeric
        local v10 = t1.xyz(riding_conditions.com_velocity)
        local v11 = if axis == "X" then dot(v10, t1.xyz(riding_conditions.skeleton_x))
            elseif axis == "Y" then v10.y
            elseif axis == "Z" then dot(v10, t1.xyz(riding_conditions.skeleton_z))
            else length(v10)

        return NumericCondition.matches(numeric, v11)
    end

    if p3.tag == "SkateSlope" then
        return NumericCondition.matches(p3[1], t1.slope(riding_conditions.skate_up_y))
    end

    if p3.tag == "SurfaceSlope" then
        return NumericCondition.matches(p3[1], t1.slope(riding_conditions.surface_up_y))
    end

    error("internal error: entered unreachable code: Random condition evaluated above", 0)
end

function t1.xyz(p5) -- line: 135
    -- upvalues: Vector3 (copy)
    return Vector3.new(p5[1], p5[2], p5[3])
end

function t1.slope(p6) -- line: 140
    -- upvalues: v2 (copy)
    return 90 - v2.asin(p6) * 57.295780181884766
end

t1.MotionRandom = {}

function t1.MotionRandom.new() -- line: 152
    return { { 0, 0, 4063039062, 2284922601, 3324304687, 117621916, 2654289789, 1876900708 } }
end

function t1.MotionRandom.next_u32(p7) -- line: 170
    -- upvalues: rt (copy)
    local v12 = p7[1]
    local v13 = v12[8]
    local v14 = v12[7]
    local v15 = rt.wrapping_add_u32(v14, v13)
    local v16 = if v15 < v13 or v15 < v14 then 1 else 0

    v12[7] = v15

    for i = 5, 2, -1 do
        local v17 = v12[i + 1]

        v15 = rt.wrapping_add_u32(rt.wrapping_add_u32(v17, v15), v16)
        v16 = if v15 < v17 then 1 else 0
        v12[i + 1] = v15
    end

    v12[8] = rt.wrapping_add_u32(v13, 1)

    if v12[8] == 0 then
        for i = 6, 2, -1 do
            v12[i + 1] = rt.wrapping_add_u32(v12[i + 1], 1)

            if v12[i + 1] ~= 0 then
                break
            end
        end
    end

    v12[2] = rt.wrapping_add_u32(v12[2], 1)

    return v12[3]
end

return t1
