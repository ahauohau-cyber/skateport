-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/native_arithmetic")
local v2

local function toolkit() -- line: 11
    -- upvalues: import (copy), v2 (ref)
    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v2
end

local function dot(p1, p2) -- line: 17
    -- upvalues: import (copy), v2 (ref)
    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v2.dot(p1, p2)
end

local function length(p3) -- line: 20
    -- upvalues: import (copy), v2 (ref)
    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v2.length(p3)
end

local function scale(p4, p5) -- line: 23
    -- upvalues: import (copy), v2 (ref)
    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v2.scale(p4, p5)
end

local function sub(p6, p7) -- line: 26
    -- upvalues: import (copy), v2 (ref)
    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v2.sub(p6, p7)
end

local t1 = {
    ContactSample = {},
    Samples = {}
}

function t1.Samples.default() -- line: 46
    return {
        original_ground_count = 0,
        ground = {},
        other = {}
    }
end

local reciprocal
local v3 = false

function t1.set_reference(p8) -- line: 54
    -- upvalues: v3 (ref)
    v3 = p8
end

local reciprocal_estimate = import("skate_core/physics/native_arithmetic").reciprocal_estimate
local estimate = import("skate_core/physics/reciprocal_sqrt").estimate

local function length3(p9, p10, p11) -- line: 70
    -- upvalues: estimate (copy)
    local v4 = p9 * p9 + p10 * p10 + p11 * p11

    if v4 == 0 then
        return 0
    end

    local v5 = estimate(v4)
    local v6 = v5 * 0.5 * (-v4 * (v5 * v5) + 1) + v5

    return v4 * (v6 * 0.5 * (-v4 * (v6 * v6) + 1) + v6)
end

local function reciprocal2(p12) -- line: 80
    -- upvalues: reciprocal_estimate (copy)
    local v7 = reciprocal_estimate(p12)
    local v8 = v7 * (-v7 * p12 + 1) + v7

    return v8 * (-v8 * p12 + 1) + v8
end

function t1.Samples.insert(p13, p14, p15, p16, p17, p18, p19) -- line: 96
    -- upvalues: rt (copy), t1 (copy), v3 (ref), reciprocal_estimate (copy), estimate (copy)
    if v3 then
        return t1.Samples.insert_reference(p13, p14, p15, p16, p17, p18, p19)
    end

    local position, forward, up, right = p14.position, p14.forward, p14.up, p14.right
    local v9 = p15[1] - position[1]
    local v10 = p15[2] - position[2]
    local v11 = p15[3] - position[3]
    local v12 = forward[1] * v9 + forward[2] * v10 + forward[3] * v11
    local v13 = up[1] * v9 + up[2] * v10 + up[3] * v11
    local v14 = v13 >= 0.79000002 and v12 >= 0
    local v15 = right[1]
    local v16 = right[2]
    local v17 = right[3]
    local v18 = right[4]
    local v19 = p16[1]
    local v20 = p16[2]
    local v21 = p16[3]
    local v22 = p16[4]
    local v23 = v19 * v15 + v20 * v16 + v21 * v17
    local v24 = v19 - v15 * v23
    local v25 = v20 - v16 * v23
    local v26 = v21 - v17 * v23
    local v27 = v22 - v18 * v23
    local v28 = v24 * v24 + v25 * v25 + v26 * v26
    local v29

    if v28 == 0 then
        v29 = 0
    else
        local v30 = estimate(v28)
        local v31 = v30 * 0.5 * (-v28 * (v30 * v30) + 1) + v30

        v29 = v28 * (v31 * 0.5 * (-v28 * (v31 * v31) + 1) + v31)
    end

    local v32

    if v29 >= 0.001 then
        local v33 = reciprocal_estimate(v29)
        local v34 = v33 * (-v33 * v29 + 1) + v33
        local v35 = v34 * (-v34 * v29 + 1) + v34

        v32 = {
            v24 * v35,
            v25 * v35,
            v26 * v35,
            v27 * v35
        }
    elseif v13 < 0 then
        v32 = rt.copy(forward)
    else
        v32 = {
            forward[1] * -1,
            forward[2] * -1,
            forward[3] * -1,
            forward[4] * -1
        }
    end

    local v36 = p17 == 1 or v14

    if v36 and #p13.ground == 64 or not v36 and v12 < 0 then
        return false
    end

    local v37 = if p19 == 1 then 1 elseif p19 == 2 then 4 else 0

    if v14 then
        v37 = bit32.bor(v37, 8)
    end

    if p17 == 2 then
        v37 = bit32.bor(v37, 16)
    end

    local t2 = {
        position = rt.copy(p15),
        normal = v32,
        forward_distance = v12,
        height = v13,
        flags = v37,
        sort_distance = if p18 >= 0 then p18 else v12
    }

    if v36 then
        table.insert(p13.ground, t2)
        p13.original_ground_count = #p13.ground
    else
        table.insert(p13.other, t2)
    end

    return true
end

function t1.Samples.insert_reference(p20, p21, p22, p23, p24, p25, p26) -- line: 162
    -- upvalues: rt (copy), import (copy), v2 (ref), reciprocal (ref)
    local position = p21.position

    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v38 = v2.sub(p22, position)
    local forward = p21.forward

    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v39 = v2.dot(forward, v38)
    local up = p21.up

    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v40 = v2.dot(up, v38)
    local v41 = v40 >= 0.79000002 and v39 >= 0
    local right, right2 = p21.right, p21.right

    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v42 = v2.dot(p23, right2)

    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v43 = v2.scale(right, v42)

    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v44 = v2.sub(p23, v43)

    if v2 == nil then
        v2 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v45 = v2.length(v44)
    local v46

    if v45 >= 0.001 then
        local v47 = reciprocal(v45)

        if v2 == nil then
            v2 = import("skate_core/player/offboard/contact_toolkit")
        end

        v46 = v2.scale(v44, v47)
    elseif v40 < 0 then
        v46 = rt.copy(p21.forward)
    else
        local forward = p21.forward

        if v2 == nil then
            v2 = import("skate_core/player/offboard/contact_toolkit")
        end

        v46 = v2.scale(forward, -1)
    end

    local v48 = p24 == 1 or v41

    if v48 and #p20.ground == 64 or not v48 and v39 < 0 then
        return false
    end

    local v49 = if p26 == 1 then 1 elseif p26 == 2 then 4 else 0

    if v41 then
        v49 = bit32.bor(v49, 8)
    end

    if p24 == 2 then
        v49 = bit32.bor(v49, 16)
    end

    local t3 = {
        position = rt.copy(p22),
        normal = v46,
        forward_distance = v39,
        height = v40,
        flags = v49,
        sort_distance = if p25 >= 0 then p25 else v39
    }

    if v48 then
        table.insert(p20.ground, t3)
        p20.original_ground_count = #p20.ground
    else
        table.insert(p20.other, t3)
    end

    return true
end

function t1.reciprocal(p27) -- line: 220
    -- upvalues: v1 (copy)
    local v50 = v1.reciprocal_estimate(p27)
    local v51 = v50 * (-v50 * p27 + 1) + v50

    return v51 * (-v51 * p27 + 1) + v51
end

reciprocal = t1.reciprocal

return t1
