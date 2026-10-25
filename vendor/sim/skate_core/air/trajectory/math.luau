-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/native_arithmetic")
local v2 = import("skate_core/trigonometry")
local t1 = {
    ZERO = { 0, 0, 0, 0 },
    UP = { 0, 1, 0, 0 },
    STEP = 0.01666666753590107,
    IDENTITY = {
        { 1, 0, 0, 0 },
        { 0, 1, 0, 0 },
        { 0, 0, 1, 0 },
        { 0, 0, 0, 0 }
    }
}

function t1.dot(p1, p2) -- line: 20
    -- upvalues: v1 (copy)
    return v1.dot3(p1, p2)
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

function t1.cross(p12, p13) -- line: 40
    return {
        -p12[3] * p13[2] + p12[2] * p13[3],
        -p12[1] * p13[3] + p12[3] * p13[1],
        -p12[2] * p13[1] + p12[1] * p13[2],
        0
    }
end

function t1.inverse_length(p14) -- line: 49
    -- upvalues: v1 (copy)
    local v3 = v1.reciprocal_square_root_estimate(p14)
    local v4 = v3 * 0.5 * (-p14 * (v3 * v3) + 1) + v3

    return v4 * 0.5 * (-p14 * (v4 * v4) + 1) + v4
end

function t1.reciprocal(p15) -- line: 57
    -- upvalues: v1 (copy)
    local v5 = v1.reciprocal_estimate(p15)
    local v6 = v5 * (-v5 * p15 + 1) + v5

    return v6 * (-v6 * p15 + 1) + v6
end

function t1.angle_between(p16, p17) -- line: 66
    -- upvalues: rt (copy), v1 (copy), v2 (copy), t1 (copy)
    local v7 = t1.dot(p16, p16)
    local v8 = t1.dot(p17, p17)

    if not (v7 > 9.999999747378752E-05 and v8 > 9.999999747378752E-05) then
        return 0
    end

    local function unit(p18, p19) -- line: 72
        -- upvalues: v1 (copy), t1 (copy)
        local v9 = v1.reciprocal_square_root_estimate(p19)

        return t1.scale(p18, v9 * 0.5 * (-p19 * (v9 * v9) + 1) + v9)
    end

    local acos = v2.acos
    local fmin, fmax = rt.fmin, rt.fmax
    local dot = t1.dot
    local v10 = v1.reciprocal_square_root_estimate(v7)

    return acos(fmin(fmax(dot(t1.scale(p16, v10 * 0.5 * (-v7 * (v10 * v10) + 1) + v10), unit(p17, v8)), -1), 1))
end

function t1.length(p20) -- line: 79
    -- upvalues: t1 (copy)
    local v11 = t1.dot(p20, p20)

    if v11 == 0 then
        return 0
    end

    return v11 * t1.inverse_length(v11)
end

function t1.normalize(p21) -- line: 88
    -- upvalues: rt (copy), t1 (copy)
    local v12 = t1.dot(p21, p21)
    local v13 = t1.inverse_length(v12)

    if (if v12 == 0 then 0 else v12 * v13) > 9.999999974752427E-07 then
        return t1.scale(p21, v13)
    end

    return rt.copy(t1.ZERO)
end

function t1.transform(p22, p23) -- line: 100
    -- upvalues: t1 (copy)
    return t1.madd(p22[3], p23[3], t1.madd(p22[2], p23[2], t1.madd(p22[1], p23[1], p22[4])))
end

return t1
