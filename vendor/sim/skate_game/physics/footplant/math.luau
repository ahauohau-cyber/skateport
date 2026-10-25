-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

local t1 = {
    STEP = 0.01666666753590107,
    dot = function(p1, p2) -- dot | line: 15
        return p1[1] * p2[1] + p1[2] * p2[2] + p1[3] * p2[3]
    end
}
local dot = t1.dot

function t1.cross(p3, p4) -- line: 20
    return {
        p3[2] * p4[3] + -p3[3] * p4[2],
        p3[3] * p4[1] + -p3[1] * p4[3],
        p3[1] * p4[2] + -p3[2] * p4[1],
        0
    }
end

function t1.add(p5, p6) -- line: 29
    return {
        p5[1] + p6[1],
        p5[2] + p6[2],
        p5[3] + p6[3],
        p5[4] + p6[4]
    }
end

function t1.sub(p7, p8) -- line: 33
    return {
        p7[1] - p8[1],
        p7[2] - p8[2],
        p7[3] - p8[3],
        p7[4] - p8[4]
    }
end

function t1.scale(p9, p10) -- line: 37
    return {
        p9[1] * p10,
        p9[2] * p10,
        p9[3] * p10,
        p9[4] * p10
    }
end

local scale = t1.scale

function t1.madd(p11, p12, p13) -- line: 42
    return {
        p11[1] * p12 + p13[1],
        p11[2] * p12 + p13[2],
        p11[3] * p12 + p13[3],
        p11[4] * p12 + p13[4]
    }
end

function t1.reciprocal(p14) -- line: 46
    local v1 = 1 / p14
    local v2 = (-p14 * v1 + 1) * v1 + v1

    return (-p14 * v2 + 1) * v2 + v2
end

local reciprocal = t1.reciprocal

function t1.rsqrt(p15) -- line: 56
    local v3 = 1 / math.sqrt(p15)
    local v4 = v3 * 0.5 * (-p15 * (v3 * v3) + 1) + v3

    return v4 * 0.5 * (-p15 * (v4 * v4) + 1) + v4
end

local rsqrt = t1.rsqrt

function t1.length(p16) -- line: 65
    -- upvalues: dot (copy), rsqrt (copy)
    local v5 = dot(p16, p16)
    local v6 = v5 * rsqrt(v5)

    if v5 == 0 then
        return 0
    end

    return v6
end

local length = t1.length

function t1.normalize(p17) -- line: 76
    -- upvalues: dot (copy), scale (copy), rsqrt (copy)
    local v7 = dot(p17, p17)
    local v8 = rsqrt(v7)

    if (if v7 == 0 then 0 else v7 * v8) > 9.999999974752427E-07 then
        return scale(p17, v8)
    end

    return { 0, 0, 0, 0 }
end

function t1.point(p18, p19) -- line: 88
    local v9 = table.create(4)

    for i = 0, 3 do
        local v10 = p18[1][i + 1] * p19[1] + p18[4][i + 1]
        local v11 = p18[2][i + 1] * p19[2] + v10

        v9[i + 1] = p18[3][i + 1] * p19[3] + v11
    end

    return v9
end

function t1.rotate(p20, p21) -- line: 99
    local v12 = table.create(4)

    for i = 0, 3 do
        local v13 = p20[1][i + 1] * p21[1]
        local v14 = p20[2][i + 1] * p21[2] + v13

        v12[i + 1] = p20[3][i + 1] * p21[3] + v14
    end

    return v12
end

function t1.clamp_length(p22, p23) -- line: 109
    -- upvalues: rt (copy), scale (copy), reciprocal (copy), length (copy)
    local v15 = length(p22)

    if not (v15 >= 1.52587890625E-05) then
        return rt.copy(p22)
    end

    return scale(scale(p22, if p23 - v15 >= 0 then v15 else p23), reciprocal(v15))
end

function t1.clamp01(p24) -- line: 118
    local v17 = if -p24 >= 0 then 0 else p24

    if 1 - v17 >= 0 then
        return v17
    end

    return 1
end

return t1
