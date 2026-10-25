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
local v2 = import("skate_core/physics/reciprocal_sqrt")
local v3 = import("skate_core/physics/native_arithmetic")

import("skate_core/physics/world_contact/arithmetic")

local estimate = v2.estimate
local t1 = {}

function t1.load(p2, p3) -- line: 25
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p2[p3 + 1])

    local v5 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p2[p3 + 2])

    local v7 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p2[p3 + 3])

    local v9 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p2[p3 + 4])

    return {
        v5,
        v7,
        v9,
        (buffer.readf32(v1, 0))
    }
end

function t1.dot(p4, p5) -- line: 34
    return p4[1] * p5[1] + p4[2] * p5[2] + p4[3] * p5[3]
end

function t1.sub(p6, p7) -- line: 38
    return {
        p6[1] - p7[1],
        p6[2] - p7[2],
        p6[3] - p7[3],
        p6[4] - p7[4]
    }
end

function t1.scale(p8, p9) -- line: 42
    return {
        p8[1] * p9,
        p8[2] * p9,
        p8[3] * p9,
        p8[4] * p9
    }
end

function t1.madd(p10, p11, p12) -- line: 46
    return {
        p10[1] * p11 + p12[1],
        p10[2] * p11 + p12[2],
        p10[3] * p11 + p12[3],
        p10[4] * p11 + p12[4]
    }
end

function t1.cross(p13, p14) -- line: 50
    return {
        -p13[3] * p14[2] + p13[2] * p14[3],
        -p13[1] * p14[3] + p13[3] * p14[1],
        -p13[2] * p14[1] + p13[1] * p14[2],
        -p13[4] * p14[4] + p13[4] * p14[4]
    }
end

function t1.normalized(p15) -- line: 59
    -- upvalues: t1 (copy)
    local v11 = t1.dot(p15, p15)

    return t1.scale(p15, t1.inverse_length(v11))
end

function t1.inverse_length(p16) -- line: 64
    -- upvalues: estimate (copy)
    local v12 = estimate(p16)
    local v13 = v12 * 0.5 * (-p16 * (v12 * v12) + 1) + v12

    return v13 * 0.5 * (-p16 * (v13 * v13) + 1) + v13
end

function t1.reciprocal(p17) -- line: 72
    -- upvalues: t1 (copy)
    local v14 = t1.reciprocal_estimate(p17)
    local v15 = v14 * (-v14 * p17 + 1) + v14

    return v15 * (-v15 * p17 + 1) + v15
end

function t1.reciprocal_estimate(p18) -- line: 80
    -- upvalues: v3 (copy)
    return v3.reciprocal_estimate(p18)
end

return t1
