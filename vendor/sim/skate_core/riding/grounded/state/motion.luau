-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local Vector3 = import("skate_core/math").Vector3
local BoardForceQueue = import("skate_core/physics/force_queue").BoardForceQueue
local reciprocal_estimate = import("skate_core/physics/native_arithmetic").reciprocal_estimate
local dot_product = import("skate_core/riding/ground_correction_math").dot_product
local t1 = {}

local function xyz(p1) -- line: 21
    -- upvalues: Vector3 (copy)
    return Vector3.new(p1[1], p1[2], p1[3])
end

t1.xyz = xyz

function t1.words(p2) -- line: 26
    return {
        p2.x,
        p2.y,
        p2.z,
        0
    }
end

function t1.reciprocal(p3) -- line: 31
    -- upvalues: reciprocal_estimate (copy)
    local v1 = reciprocal_estimate(p3)
    local v2 = v1 * (-p3 * v1 + 1) + v1

    return v2 * (-p3 * v2 + 1) + v2
end

function t1.entry_angular_velocity(p4, p5) -- line: 41
    -- upvalues: dot_product (copy), xyz (copy)
    local v3 = dot_product(p4, p5)
    local v4 = table.create(4)

    v4[1] = p4[1] * v3
    v4[2] = p4[2] * v3
    v4[3] = p4[3] * v3
    v4[4] = p4[4] * v3

    return xyz(v4)
end

function t1.entry_target_speed(p6, p7, p8) -- line: 52
    -- upvalues: dot_product (copy)
    local t2 = {
        p6.x,
        p6.y,
        p6.z,
        0
    }
    local v5 = dot_product(t2, p7)
    local t3 = {
        t2[1] - p7[1] * v5,
        t2[2] - p7[2] * v5,
        t2[3] - p7[3] * v5,
        t2[4] - p7[4] * v5
    }
    local v7 = math.abs((dot_product(t2, p8)))
    local v9 = math.abs((dot_product(t3, p8)))

    if v7 - v9 >= 0 then
        return v9
    end

    return v7
end

function t1.landing_on_deck_force(p9, p10, p11, p12, p13, p14) -- line: 71
    -- upvalues: Vector3 (copy), reciprocal_estimate (copy), dot_product (copy)
    local t4 = {
        p10[1] - p9[1],
        p10[2] - p9[2],
        p10[3] - p9[3],
        p10[4] - p9[4]
    }
    local v10 = dot_product(t4, p11)
    local v11 = reciprocal_estimate(0.01666666753590107)
    local v12 = v11 * (-0.01666666753590107 * v11 + 1) + v11
    local v13 = v12 * (-0.01666666753590107 * v12 + 1) + v12
    local t5 = {
        (t4[1] - p11[1] * v10) * p13 * p12 * v13,
        (t4[2] - p11[2] * v10) * p13 * p12 * v13,
        (t4[3] - p11[3] * v10) * p13 * p12 * v13,
        (t4[4] - p11[4] * v10) * p13 * p12 * v13
    }

    return {
        tag = 19,
        force_world = Vector3.new(t5[1], t5[2], t5[3]),
        point_body = Vector3.new(0, p14, 0)
    }
end

function t1.future_deck_displacement(p15, p16, p17, p18, p19, p20) -- line: 107
    -- upvalues: Vector3 (copy), reciprocal_estimate (copy)
    if p19 or p20 then
        return nil
    end

    local entries, count = p15.entries, p15.count
    local n1 = 0
    local n2 = 0
    local n3 = 0

    for i = 1, count do
        local force_world = entries[i].force_world

        n1 += force_world.x
        n2 += force_world.y
        n3 += force_world.z
    end

    local v14 = reciprocal_estimate(p16)
    local v15 = v14 * (-p16 * v14 + 1) + v14
    local v16 = (v15 * (-p16 * v15 + 1) + v15) * p17
    local v17 = n1 * v16
    local v18 = n2 * v16
    local v19 = n3 * v16
    local v20 = p18[1]
    local v21 = p18[2]
    local v22 = p18[3]
    local v23 = v17 * v20 + v18 * v21 + v19 * v22

    return Vector3.new((v17 - v20 * v23) * p17, (v18 - v21 * v23) * p17, (v19 - v22 * v23) * p17)
end

function t1.future_deck_displacement_reference(p21, p22, p23, p24, p25, p26) -- line: 129
    -- upvalues: BoardForceQueue (copy), reciprocal_estimate (copy), dot_product (copy), xyz (copy)
    if p25 or p26 then
        return nil
    end

    local v24 = table.create(4, 0)
    local v25 = BoardForceQueue.entries(p21)

    for i = 1, #v25 do
        local force_world = v25[i].force_world
        local t6 = {
            force_world.x,
            force_world.y,
            force_world.z,
            0
        }

        v24[1] += t6[1]
        v24[2] += t6[2]
        v24[3] += t6[3]
        v24[4] += t6[4]
    end

    local v26 = reciprocal_estimate(p22)
    local v27 = v26 * (-p22 * v26 + 1) + v26
    local v28 = (v27 * (-p22 * v27 + 1) + v27) * p23
    local v29 = table.create(4)

    v29[1] = v24[1] * v28
    v29[2] = v24[2] * v28
    v29[3] = v24[3] * v28
    v29[4] = v24[4] * v28

    local v30 = dot_product(v29, p24)

    return xyz({
        (v29[1] - p24[1] * v30) * p23,
        (v29[2] - p24[2] * v30) * p23,
        (v29[3] - p24[3] * v30) * p23,
        (v29[4] - p24[4] * v30) * p23
    })
end

return t1
