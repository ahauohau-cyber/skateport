-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/native_arithmetic")
local v2 = import("skate_core/physics/reciprocal_sqrt")
local v3 = import("skate_core/trigonometry")
local t1 = {
    TAU = 6.2831854820251465
}
local TAU = t1.TAU

t1.IDENTITY = {
    { 1, 0, 0, 0 },
    { 0, 1, 0, 0 },
    { 0, 0, 1, 0 },
    { 0, 0, 0, 0 }
}

function t1.dot(p1, p2) -- line: 22
    -- upvalues: v1 (copy)
    return v1.dot3(p1, p2)
end

local dot = t1.dot

function t1.scale(p3, p4) -- line: 28
    return {
        p3[1] * p4,
        p3[2] * p4,
        p3[3] * p4,
        p3[4] * p4
    }
end

local scale = t1.scale

function t1.sub(p5, p6) -- line: 34
    return {
        p5[1] - p6[1],
        p5[2] - p6[2],
        p5[3] - p6[3],
        p5[4] - p6[4]
    }
end

function t1.cross(p7, p8) -- line: 39
    return {
        -p7[3] * p8[2] + p7[2] * p8[3],
        -p7[1] * p8[3] + p7[3] * p8[1],
        -p7[2] * p8[1] + p7[1] * p8[2],
        -p7[4] * p8[4] + p7[4] * p8[4]
    }
end

local cross = t1.cross

function t1.inverse_length(p9, p10) -- line: 50
    -- upvalues: v2 (copy)
    local v4 = v2.estimate(p9)

    for _ = 0, p10 - 1 do
        v4 = v4 * 0.5 * (-p9 * (v4 * v4) + 1) + v4
    end

    return v4
end

local inverse_length = t1.inverse_length

function t1.length(p11) -- line: 60
    -- upvalues: dot (copy), inverse_length (copy)
    local v5 = dot(p11, p11)
    local v6 = v5 * inverse_length(v5, 2)

    if v5 == 0 then
        return 0
    end

    return v6
end

function t1.wrap(p12) -- line: 71
    -- upvalues: TAU (copy)
    local v7 = p12 * 0.15915493667125702
    local v8 = v7 - math.floor(v7)

    return (v8 - (if v8 > 0.5 then 1 else 0)) * TAU
end

function t1.signed_angle(p13, p14, p15) -- line: 78
    -- upvalues: rt (copy), v3 (copy), TAU (copy), dot (copy), scale (copy), cross (copy), inverse_length (copy)
    local v9 = dot(p13, p13)
    local v10 = dot(p14, p14)

    if not (v9 > 9.999999747378752E-05 and v10 > 9.999999747378752E-05) then
        return 0
    end

    local v11 = scale(p13, inverse_length(v9, 1))
    local v12 = scale(p14, inverse_length(v10, 1))
    local v13 = rt.fmin(rt.fmax(dot(v11, v12), -1), 1)
    local v14 = v3.acos(v13)

    if dot(cross(v11, v12), p15) < 0 then
        return TAU - v14
    end

    return v14
end

function t1.rotate(p16, p17, p18) -- line: 96
    -- upvalues: v3 (copy), scale (copy), cross (copy)
    local v15, v16 = v3.sin_cos(p18 * 0.5)
    local v17 = scale(p17, v15)

    v17[4] = v16

    local v18 = cross(v17, p16)
    local v19 = cross(v17, {
        p16[1] * v16 + v18[1],
        p16[2] * v16 + v18[2],
        p16[3] * v16 + v18[3],
        p16[4] * v16 + v18[4]
    })

    return {
        v19[1] * 2 + p16[1],
        v19[2] * 2 + p16[2],
        v19[3] * 2 + p16[3],
        v19[4] * 2 + p16[4]
    }
end

return t1
