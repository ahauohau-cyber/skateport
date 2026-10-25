-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/physics/board_motion_output")
local v2 = import("skate_core/physics/native_arithmetic")
local inverse_length_squared = v1.inverse_length_squared
local t1 = {
    Vector = {},
    UP = { 0, 1, 0, 0 }
}

function t1.dot(p1, p2) -- line: 20
    -- upvalues: v2 (copy)
    return v2.dot3(p1, p2)
end

function t1.add(p3, p4) -- line: 24
    return {
        p3[1] + p4[1],
        p3[2] + p4[2],
        p3[3] + p4[3],
        p3[4] + p4[4]
    }
end

function t1.sub(p5, p6) -- line: 28
    return {
        p5[1] - p6[1],
        p5[2] - p6[2],
        p5[3] - p6[3],
        p5[4] - p6[4]
    }
end

function t1.scale(p7, p8) -- line: 32
    return {
        p7[1] * p8,
        p7[2] * p8,
        p7[3] * p8,
        p7[4] * p8
    }
end

function t1.madd(p9, p10, p11) -- line: 36
    return {
        p9[1] * p10 + p11[1],
        p9[2] * p10 + p11[2],
        p9[3] * p10 + p11[3],
        p9[4] * p10 + p11[4]
    }
end

function t1.planar(p12, p13) -- line: 40
    -- upvalues: t1 (copy)
    return t1.sub(p12, t1.scale(p13, t1.dot(p12, p13)))
end

function t1.maximum(p14, p15) -- line: 44
    if p14 - p15 >= -0 then
        return p14
    end

    return p15
end

function t1.clamp(p16, p17, p18) -- line: 48
    local v3 = if p17 - p16 >= -0 then p17 else p16

    if p18 - v3 >= -0 then
        return v3
    end

    return p18
end

function t1.vector_clamp(p19, p20, p21) -- line: 53
    -- upvalues: v2 (copy)
    return v2.vector_min(p21, v2.vector_max(p20, p19))
end

function t1.reciprocal(p22) -- line: 57
    -- upvalues: v2 (copy)
    local v4 = v2.reciprocal_estimate(p22)
    local v5 = v4 * (-v4 * p22 + 1) + v4

    return v5 * (-v5 * p22 + 1) + v5
end

function t1.square_root(p23) -- line: 65
    -- upvalues: inverse_length_squared (copy)
    local v6 = p23 * inverse_length_squared(p23, 2)

    if p23 == 0 then
        return 0
    end

    return v6
end

function t1.length(p24) -- line: 70
    -- upvalues: t1 (copy)
    return t1.square_root(t1.dot(p24, p24))
end

function t1.normalize(p25) -- line: 74
    -- upvalues: inverse_length_squared (copy), t1 (copy)
    local v7 = t1.dot(p25, p25)
    local v8 = inverse_length_squared(v7, 2)

    if (if v7 == 0 then 0 else v7 * v8) > 9.999999974752427E-07 then
        return t1.scale(p25, v8)
    end

    return { 0, 0, 0, 0 }
end

function t1.cross(p26, p27) -- line: 86
    return {
        -p26[3] * p27[2] + p26[2] * p27[3],
        -p26[1] * p27[3] + p26[3] * p27[1],
        -p26[2] * p27[1] + p26[1] * p27[2],
        0
    }
end

return t1
