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

local import = require(sim.import)
local v9 = import("skate_core/physics/reciprocal_sqrt")
local v10 = import("skate_core/trigonometry")
local t1 = {
    HALF_PI = 1.5707963705062866,
    EPSILON = 9.999999974752427E-07,
    select = function(p3, p4, p5) -- select | line: 39
        if p3 >= 0 then
            return p4
        end

        return p5
    end
}

function t1.clamp(p6, p7, p8) -- line: 47
    -- upvalues: t1 (copy)
    local v11 = t1.select(p7 - p6, p7, p6)

    return t1.select(p8 - v11, v11, p8)
end

function t1.dot(p9, p10) -- line: 52
    return p9[1] * p10[1] + p9[2] * p10[2] + p9[3] * p10[3]
end

function t1.scale(p11, p12) -- line: 56
    return {
        p11[1] * p12,
        p11[2] * p12,
        p11[3] * p12,
        p11[4] * p12
    }
end

function t1.sub(p13, p14) -- line: 60
    return {
        p13[1] - p14[1],
        p13[2] - p14[2],
        p13[3] - p14[3],
        p13[4] - p14[4]
    }
end

function t1.madd(p15, p16, p17) -- line: 64
    return {
        p15[1] * p16 + p17[1],
        p15[2] * p16 + p17[2],
        p15[3] * p16 + p17[3],
        p15[4] * p16 + p17[4]
    }
end

function t1.inverse_squared(p18, p19) -- line: 68
    -- upvalues: v9 (copy)
    local v12 = v9.estimate(p18)

    for _ = 0, p19 - 1 do
        local v13 = -p18 * (v12 * v12) + 1

        v12 = v12 * 0.5 * v13 + v12
    end

    return v12
end

function t1.length(p20) -- line: 77
    -- upvalues: v1 (copy), t1 (copy)
    local v14 = t1.dot(p20, p20)
    local v15

    if v14 ~= 0 and v14 > -1.1754943508222875E-38 and v14 < 1.1754943508222875E-38 then
        local v16 = math.abs(v14) * 7.1362384635298E+44
        local v17 = math.floor(v16)
        local v18 = v16 - v17

        v15 = (if v18 > 0.5 or v18 == 0.5 and v17 % 2 == 1 then v17 + 1 else v17) * 1.401298464324817E-45

        if v14 < 0 then
            v15 = -v15
        end
    else
        buffer.writef32(v1, 0, v14)
        v15 = buffer.readf32(v1, 0)
    end

    local v19 = v15 * t1.inverse_squared(v15, 2)

    if v15 == 0 then
        return 0
    end

    return v19
end

function t1.normalize_or(p21, p22) -- line: 88
    -- upvalues: rt (copy), v1 (copy), t1 (copy)
    local v20 = t1.dot(p21, p21)
    local v21

    if v20 ~= 0 and v20 > -1.1754943508222875E-38 and v20 < 1.1754943508222875E-38 then
        local v22 = math.abs(v20) * 7.1362384635298E+44
        local v23 = math.floor(v22)
        local v24 = v22 - v23

        v21 = (if v24 > 0.5 or v24 == 0.5 and v23 % 2 == 1 then v23 + 1 else v23) * 1.401298464324817E-45

        if v20 < 0 then
            v21 = -v21
        end
    else
        buffer.writef32(v1, 0, v20)
        v21 = buffer.readf32(v1, 0)
    end

    local v25 = t1.inverse_squared(v21, 2)

    if (if v21 == 0 then 0 else v21 * v25) > t1.EPSILON then
        return t1.scale(p21, v25)
    end

    return rt.copy(p22)
end

function t1.horizontal(p23) -- line: 101
    -- upvalues: t1 (copy)
    return t1.normalize_or({
        p23[1],
        0,
        p23[3],
        p23[1]
    }, { 0, 0, 0, 0 })
end

function t1.wrap_angle(p24) -- line: 105
    local v26 = p24 * 0.15915493667125702
    local v27 = v26 - math.floor(v26)

    return (v27 - (if v27 > 0.5 then 1 else 0)) * 6.2831854820251465
end

function t1.signed_angle(p25, p26, p27) -- line: 111
    -- upvalues: rt (copy), v10 (copy), t1 (copy)
    local v28 = t1.dot(p25, p25)
    local v29 = t1.dot(p26, p26)

    if not (v28 > 9.999999747378752E-05 and v29 > 9.999999747378752E-05) then
        return 0
    end

    local v30 = t1.scale(p25, t1.inverse_squared(v28, 1))
    local v31 = t1.scale(p26, t1.inverse_squared(v29, 1))
    local v32 = v10.acos(rt.fmin(rt.fmax(t1.dot(v30, v31), -1), 1))
    local t2 = {
        -v30[3] * v31[2] + v30[2] * v31[3],
        -v30[1] * v31[3] + v30[3] * v31[1],
        -v30[2] * v31[1] + v30[1] * v31[2],
        -v30[4] * v31[4] + v30[4] * v31[4]
    }

    if t1.dot(t2, p27) < 0 then
        return 6.2831854820251465 - v32
    end

    return v32
end

function t1.projected_angle(p28, p29, p30) -- line: 134
    -- upvalues: t1 (copy)
    if t1.dot(p28, p28) * t1.dot(p29, p29) > 1.52587890625E-05 then
        return t1.signed_angle(t1.sub(p28, t1.scale(p30, t1.dot(p30, p28))), t1.sub(p29, t1.scale(p30, t1.dot(p30, p29))), p30)
    end

    return 0
end

return t1
