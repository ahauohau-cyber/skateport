-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/trigonometry")
local v2 = import("skate_core/physics/skeleton_animation_record")
local v3

local function parent() -- line: 11
    -- upvalues: import (copy), v3 (ref)
    if v3 == nil then
        v3 = import("skate_core/physics/grind_air")
    end

    return v3
end

local t1 = {
    PoseInput = {}
}

function t1.axis_rotation(p1, p2) -- line: 30
    -- upvalues: v1 (copy)
    local v4, v5 = v1.sin_cos(p2)
    local v6 = p1[1]
    local v7 = p1[2]
    local v8 = p1[3]
    local v9 = 1 - v5

    return {
        {
            v9 * v6 * v6 + v5,
            v9 * v6 * v7 + v4 * v8,
            v9 * v6 * v8 + -v4 * v7,
            0
        },
        {
            v9 * v7 * v6 + -v4 * v8,
            v9 * v7 * v7 + v5,
            v9 * v7 * v8 + v4 * v6,
            0
        },
        {
            v9 * v8 * v6 + v4 * v7,
            v9 * v8 * v7 + -v4 * v6,
            v9 * v8 * v8 + v5,
            0
        },
        { 0, 0, 0, 0 }
    }
end

local axis_rotation = t1.axis_rotation

function t1.direction(p3, p4) -- line: 58
    -- upvalues: import (copy), v3 (ref)
    if v3 == nil then
        v3 = import("skate_core/physics/grind_air")
    end

    local madd = v3.madd

    if v3 == nil then
        v3 = import("skate_core/physics/grind_air")
    end

    local scale = v3.scale

    return madd(p3[3], p4[3], madd(p3[2], p4[2], scale(p3[1], p4[1])))
end

local direction = t1.direction

t1.Adjustment = {}

function t1.Adjustment.local_transform(p5, p6) -- line: 69
    -- upvalues: rt (copy), import (copy), v2 (copy), v3 (ref), axis_rotation (copy), direction (copy)
    if v3 == nil then
        v3 = import("skate_core/physics/grind_air")
    end

    local v10 = v3
    local cross, scale, inverse_length, dot = v10.cross, v10.scale, v10.inverse_length, v10.dot
    local sub, add = v10.sub, v10.add
    local v11 = cross(v10.UP, p5.axis)
    local v12 = scale(v11, inverse_length(dot(v11, v11)))
    local v13 = cross(p5.axis, v12)
    local v15 = axis_rotation(scale(v13, inverse_length(dot(v13, v13))), p5.angles[2])
    local v16 = axis_rotation(p5.axis, p5.angles[1])
    local v17 = axis_rotation(p6.physical_forward, p5.angles[3])
    local v18 = rt.copy(v2.IDENTITY)

    for i = 0, 2 do
        v18[i + 1] = direction(p6.world_to_animation, direction(v15, direction(v16, direction(v17, p6.animation_to_world[i + 1]))))
    end

    local v19 = rt.copy(p6.animation_board_position)

    v18[4] = sub(add(direction(p6.world_to_animation, p5.offset), v19), direction(v18, v19))

    return v18
end

return t1
