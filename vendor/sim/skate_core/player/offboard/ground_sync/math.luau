-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_subnormal_mantissa(p1) -- line: 7
    local v2 = p1 * 7.1362384635298E+44
    local v3 = math.floor(v2)
    local v4 = v2 - v3

    if v4 > 0.5 or v4 == 0.5 and v3 % 2 == 1 then
        return v3 + 1
    end

    return v3
end

local function rtl_fround(p2) -- line: 16
    -- upvalues: v1 (copy)
    if p2 ~= 0 and p2 > -1.1754943508222875E-38 and p2 < 1.1754943508222875E-38 then
        local v6 = math.abs(p2) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        local v8 = v5 * 1.401298464324817E-45

        if p2 < 0 then
            return -v8
        end

        return v8
    end

    buffer.writef32(v1, 0, p2)

    return (buffer.readf32(v1, 0))
end

local v9 = require(sim.import)("skate_core/physics/reciprocal_sqrt")
local t1 = {
    dot = function(p3, p4) -- dot | line: 34
        return p3[1] * p4[1] + p3[2] * p4[2] + p3[3] * p4[3]
    end,
    scale = function(p5, p6) -- scale | line: 38
        return {
            p5[1] * p6,
            p5[2] * p6,
            p5[3] * p6,
            p5[4] * p6
        }
    end,
    sub = function(p7, p8) -- sub | line: 42
        return {
            p7[1] - p8[1],
            p7[2] - p8[2],
            p7[3] - p8[3],
            p7[4] - p8[4]
        }
    end,
    madd = function(p9, p10, p11) -- madd | line: 46
        return {
            p9[1] * p10 + p11[1],
            p9[2] * p10 + p11[2],
            p9[3] * p10 + p11[3],
            p9[4] * p10 + p11[4]
        }
    end,
    cross = function(p12, p13) -- cross | line: 50
        return {
            -p12[3] * p13[2] + p12[2] * p13[3],
            -p12[1] * p13[3] + p12[3] * p13[1],
            -p12[2] * p13[1] + p12[1] * p13[2],
            -p12[4] * p13[4] + p12[4] * p13[4]
        }
    end,
    inverse = function(p14) -- inverse | line: 59
        -- upvalues: v9 (copy)
        local v10 = v9.estimate(p14)
        local v11 = v10 * 0.5 * (-p14 * (v10 * v10) + 1) + v10

        return v11 * 0.5 * (-p14 * (v11 * v11) + 1) + v11
    end
}

function t1.normalize_unchecked(p15) -- line: 68
    -- upvalues: t1 (copy)
    return t1.scale(p15, t1.inverse(t1.dot(p15, p15)))
end

function t1.normalize_or(p16, p17) -- line: 73
    -- upvalues: rt (copy), v1 (copy), t1 (copy)
    local v12 = t1.dot(p16, p16)
    local v13

    if v12 ~= 0 and v12 > -1.1754943508222875E-38 and v12 < 1.1754943508222875E-38 then
        local v14 = math.abs(v12) * 7.1362384635298E+44
        local v15 = math.floor(v14)
        local v16 = v14 - v15

        v13 = (if v16 > 0.5 or v16 == 0.5 and v15 % 2 == 1 then v15 + 1 else v15) * 1.401298464324817E-45

        if v12 < 0 then
            v13 = -v13
        end
    else
        buffer.writef32(v1, 0, v12)
        v13 = buffer.readf32(v1, 0)
    end

    local v17 = t1.inverse(v13)

    if (if v13 == 0 then 0 else v13 * v17) > 9.999999974752427E-07 then
        return t1.scale(p16, v17)
    end

    return rt.copy(p17)
end

return t1
