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
    select = function(p3, p4, p5) -- select | line: 35
        if p3 >= 0 then
            return p4
        end

        return p5
    end
}

function t1.clamp(p6, p7, p8) -- line: 43
    -- upvalues: t1 (copy)
    local v10 = t1.select(p7 - p6, p7, p6)

    return t1.select(p8 - v10, v10, p8)
end

function t1.dot(p9, p10) -- line: 48
    return p9[1] * p10[1] + p9[2] * p10[2] + p9[3] * p10[3]
end

function t1.scale(p11, p12) -- line: 52
    return {
        p11[1] * p12,
        p11[2] * p12,
        p11[3] * p12,
        p11[4] * p12
    }
end

function t1.sub(p13, p14) -- line: 56
    return {
        p13[1] - p14[1],
        p13[2] - p14[2],
        p13[3] - p14[3],
        p13[4] - p14[4]
    }
end

function t1.madd(p15, p16, p17) -- line: 60
    return {
        p15[1] * p16 + p17[1],
        p15[2] * p16 + p17[2],
        p15[3] * p16 + p17[3],
        p15[4] * p16 + p17[4]
    }
end

function t1.inverse_squared(p18) -- line: 64
    -- upvalues: rt (copy), v9 (copy)
    local v11, v12

    if not (p18 > 0 and p18 < rt.F32_MIN_POSITIVE) then
        v11 = p18
        v12 = 1
    else
        v11 = p18 * 16777216
        v12 = 4096
    end

    local v13 = v9.estimate(v11)
    local v14 = -v11 * (v13 * v13) + 1
    local v15 = v13 * 0.5 * v14 + v13
    local v16 = -v11 * (v15 * v15) + 1

    return (v15 * 0.5 * v16 + v15) * v12
end

function t1.length(p19) -- line: 85
    -- upvalues: v1 (copy), t1 (copy)
    local v17 = t1.dot(p19, p19)
    local v18

    if v17 ~= 0 and v17 > -1.1754943508222875E-38 and v17 < 1.1754943508222875E-38 then
        local v19 = math.abs(v17) * 7.1362384635298E+44
        local v20 = math.floor(v19)
        local v21 = v19 - v20

        v18 = (if v21 > 0.5 or v21 == 0.5 and v20 % 2 == 1 then v20 + 1 else v20) * 1.401298464324817E-45

        if v17 < 0 then
            v18 = -v18
        end
    else
        buffer.writef32(v1, 0, v17)
        v18 = buffer.readf32(v1, 0)
    end

    local v22 = v18 * t1.inverse_squared(v18)

    if v18 == 0 then
        return 0
    end

    return v22
end

function t1.normalize_or(p20, p21) -- line: 96
    -- upvalues: rt (copy), v1 (copy), t1 (copy)
    local v23 = t1.dot(p20, p20)
    local v24

    if v23 ~= 0 and v23 > -1.1754943508222875E-38 and v23 < 1.1754943508222875E-38 then
        local v25 = math.abs(v23) * 7.1362384635298E+44
        local v26 = math.floor(v25)
        local v27 = v25 - v26

        v24 = (if v27 > 0.5 or v27 == 0.5 and v26 % 2 == 1 then v26 + 1 else v26) * 1.401298464324817E-45

        if v23 < 0 then
            v24 = -v24
        end
    else
        buffer.writef32(v1, 0, v23)
        v24 = buffer.readf32(v1, 0)
    end

    local v28 = t1.inverse_squared(v24)

    if (if v24 == 0 then 0 else v24 * v28) > 9.999999974752427E-07 then
        return t1.scale(p20, v28)
    end

    return rt.copy(p21)
end

function t1.limit_delta(p22, p23, p24) -- line: 108
    -- upvalues: rt (copy), t1 (copy)
    local v29 = t1.sub(p22, p23)
    local v30 = t1.length(v29)

    if v30 <= p24 then
        return rt.copy(p22)
    end

    return t1.madd(v29, p24 / v30, p23)
end

function t1.remove_positive(p25, p26) -- line: 119
    -- upvalues: rt (copy), t1 (copy)
    local v31 = t1.dot(p25, t1.normalize_or(p26, { 0, 0, 0, 0 }))

    if v31 > 0 then
        return t1.sub(p25, t1.scale(p26, v31))
    end

    return rt.copy(p25)
end

return t1
