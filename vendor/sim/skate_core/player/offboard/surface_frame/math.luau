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
    select = function(p3, p4, p5) -- select | line: 36
        if p3 >= 0 then
            return p4
        end

        return p5
    end
}

function t1.clamp(p6, p7, p8) -- line: 44
    -- upvalues: t1 (copy)
    local v11 = t1.select(p7 - p6, p7, p6)

    return t1.select(p8 - v11, v11, p8)
end

function t1.dot(p9, p10) -- line: 49
    return p9[1] * p10[1] + p9[2] * p10[2] + p9[3] * p10[3]
end

function t1.scale(p11, p12) -- line: 53
    return {
        p11[1] * p12,
        p11[2] * p12,
        p11[3] * p12,
        p11[4] * p12
    }
end

function t1.add(p13, p14) -- line: 57
    return {
        p13[1] + p14[1],
        p13[2] + p14[2],
        p13[3] + p14[3],
        p13[4] + p14[4]
    }
end

function t1.sub(p15, p16) -- line: 61
    return {
        p15[1] - p16[1],
        p15[2] - p16[2],
        p15[3] - p16[3],
        p15[4] - p16[4]
    }
end

function t1.madd(p17, p18, p19) -- line: 65
    return {
        p17[1] * p18 + p19[1],
        p17[2] * p18 + p19[2],
        p17[3] * p18 + p19[3],
        p17[4] * p18 + p19[4]
    }
end

function t1.cross(p20, p21) -- line: 69
    return {
        -p20[3] * p21[2] + p20[2] * p21[3],
        -p20[1] * p21[3] + p20[3] * p21[1],
        -p20[2] * p21[1] + p20[1] * p21[2],
        -p20[4] * p21[4] + p20[4] * p21[4]
    }
end

function t1.inverse(p22, p23) -- line: 79
    -- upvalues: v9 (copy)
    local v12 = v9.estimate(p22)

    for _ = 0, p23 - 1 do
        local v13 = -p22 * (v12 * v12) + 1

        v12 = v12 * 0.5 * v13 + v12
    end

    return v12
end

function t1.square_root(p24) -- line: 89
    -- upvalues: t1 (copy)
    local v14 = p24 * t1.inverse(p24, 2)

    if p24 == 0 then
        return 0
    end

    return v14
end

function t1.length(p25) -- line: 98
    -- upvalues: t1 (copy)
    return t1.square_root(t1.dot(p25, p25))
end

function t1.normalize_or(p26, p27) -- line: 103
    -- upvalues: rt (copy), v1 (copy), t1 (copy)
    local v15 = t1.dot(p26, p26)
    local v16

    if v15 ~= 0 and v15 > -1.1754943508222875E-38 and v15 < 1.1754943508222875E-38 then
        local v17 = math.abs(v15) * 7.1362384635298E+44
        local v18 = math.floor(v17)
        local v19 = v17 - v18

        v16 = (if v19 > 0.5 or v19 == 0.5 and v18 % 2 == 1 then v18 + 1 else v18) * 1.401298464324817E-45

        if v15 < 0 then
            v16 = -v16
        end
    else
        buffer.writef32(v1, 0, v15)
        v16 = buffer.readf32(v1, 0)
    end

    local v20 = t1.inverse(v16, 2)

    if (if v16 == 0 then 0 else v16 * v20) > 9.999999974752427E-07 then
        return t1.scale(p26, v20)
    end

    return rt.copy(p27)
end

function t1.unsigned_angle(p28, p29) -- line: 114
    -- upvalues: rt (copy), v10 (copy), t1 (copy)
    local v21 = t1.dot(p28, p28)
    local v22 = t1.dot(p29, p29)

    if not (v21 > 9.999999747378752E-05 and v22 > 9.999999747378752E-05) then
        return 0
    end

    return v10.acos(rt.fmin(rt.fmax(t1.dot(t1.scale(p28, t1.inverse(v21, 1)), t1.scale(p29, t1.inverse(v22, 1))), -1), 1))
end

function t1.wrap_angle(p30) -- line: 126
    local v23 = p30 * 0.15915493667125702
    local v24 = v23 - math.floor(v23)

    return (v24 - (if v24 > 0.5 then 1 else 0)) * 6.2831854820251465
end

function t1.clamp_axis(p31, p32, p33, p34) -- line: 132
    -- upvalues: t1 (copy)
    local v25 = t1.dot(p31, p32)

    return t1.madd(p32, t1.clamp(v25, p33, p34), t1.sub(p31, t1.scale(p32, v25)))
end

function t1.clamp_angle(p35, p36, p37) -- line: 139
    -- upvalues: rt (copy), v10 (copy), t1 (copy)
    local v26 = t1.normalize_or(p35, { 0, 0, 0, 0 })
    local v27 = t1.normalize_or(p36, { 0, 0, 0, 0 })
    local v28 = t1.cross(v26, v27)
    local v29 = v10.acos(rt.fmin(rt.fmax(t1.dot(v26, v27), -1), 1))

    if math.abs(-math.floor(v29 * 0.15915493667125702 + 0.5) * 6.2831854820251465 + v29) < p37 or t1.dot(v28, v28) < 1.52587890625E-05 then
        return rt.copy(p35)
    end

    local v32 = t1.scale(v28, t1.inverse(t1.dot(v28, v28), 2))
    local v33, v34 = v10.sin_cos(-p37 * 0.5)
    local v35 = t1.scale(v32, v33)

    v35[4] = v34

    local v36 = t1.cross(v35, p36)
    local v37 = t1.madd(p36, v34, v36)
    local v38 = t1.madd(t1.cross(v35, v37), 2, p36)

    return t1.scale(v38, t1.length(p35))
end

return t1
