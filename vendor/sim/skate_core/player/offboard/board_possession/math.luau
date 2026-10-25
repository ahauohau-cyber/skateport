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

local function rtl_to_bits(p2) -- line: 16
    -- upvalues: v1 (copy)
    if p2 ~= 0 and p2 > -1.1754943508222875E-38 and p2 < 1.1754943508222875E-38 then
        local v6 = math.abs(p2) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        if p2 < 0 then
            return v5 + 2147483648
        end

        return v5
    end

    buffer.writef32(v1, 0, p2)

    return (buffer.readu32(v1, 0))
end

local function rtl_from_bits(p3) -- line: 24
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p3)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local v8 = import("skate_core/physics/reciprocal_sqrt")
local v9 = import("skate_core/physics/native_arithmetic")
local v10 = import("skate_core/input/angle")
local v11 = import("skate_core/trigonometry")
local t1 = {
    dot = function(p4, p5) -- dot | line: 41
        return p4[1] * p5[1] + p4[2] * p5[2] + p4[3] * p5[3]
    end
}
local dot = t1.dot

function t1.sub(p6, p7) -- line: 46
    return {
        p6[1] - p7[1],
        p6[2] - p7[2],
        p6[3] - p7[3],
        p6[4] - p7[4]
    }
end

local sub = t1.sub

function t1.scale(p8, p9) -- line: 51
    return {
        p8[1] * p9,
        p8[2] * p9,
        p8[3] * p9,
        p8[4] * p9
    }
end

local scale = t1.scale

function t1.madd(p10, p11, p12) -- line: 56
    return {
        p10[1] * p11 + p12[1],
        p10[2] * p11 + p12[2],
        p10[3] * p11 + p12[3],
        p10[4] * p11 + p12[4]
    }
end

local madd = t1.madd

function t1.cross(p13, p14) -- line: 61
    return {
        -p13[3] * p14[2] + p13[2] * p14[3],
        -p13[1] * p14[3] + p13[3] * p14[1],
        -p13[2] * p14[1] + p13[1] * p14[2],
        -p13[4] * p14[4] + p13[4] * p14[4]
    }
end

local cross = t1.cross

function t1.inverse_sqrt(p15) -- line: 72
    -- upvalues: v8 (copy)
    local v12 = v8.estimate(p15)
    local v13 = v12 * 0.5 * (-p15 * (v12 * v12) + 1) + v12

    return v13 * 0.5 * (-p15 * (v13 * v13) + 1) + v13
end

local inverse_sqrt = t1.inverse_sqrt

function t1.length(p16) -- line: 81
    -- upvalues: dot (copy), inverse_sqrt (copy)
    local v14 = dot(p16, p16)
    local v15 = v14 * inverse_sqrt(v14)

    if v14 == 0 then
        return 0
    end

    return v15
end

function t1.unit(p17, p18) -- line: 91
    -- upvalues: rt (copy), dot (copy), scale (copy), inverse_sqrt (copy)
    local v16 = dot(p17, p17)
    local v17 = inverse_sqrt(v16)

    if (if v16 == 0 then 0 else v16 * v17) > 9.999999974752427E-07 then
        return scale(p17, v17)
    end

    return rt.copy(p18)
end

function t1.reciprocal(p19, p20) -- line: 107
    -- upvalues: v9 (copy)
    local v18 = v9.reciprocal_estimate(p19)

    for _ = 0, p20 - 1 do
        v18 = v18 * (-v18 * p19 + 1) + v18
    end

    return v18
end

local reciprocal = t1.reciprocal

function t1.quadrant_angle(p21, p22) -- line: 117
    -- upvalues: v1 (copy), v10 (copy), reciprocal (copy)
    local v19 = v10.atan(p21 * reciprocal(p22, 1) + 0)
    local v20

    if p21 ~= 0 and p21 > -1.1754943508222875E-38 and p21 < 1.1754943508222875E-38 then
        local v21 = math.abs(p21) * 7.1362384635298E+44
        local v22 = math.floor(v21)
        local v23 = v21 - v22

        v20 = if v23 > 0.5 or v23 == 0.5 and v22 % 2 == 1 then v22 + 1 else v22

        if p21 < 0 then
            v20 += 2147483648
        end
    else
        buffer.writef32(v1, 0, p21)
        v20 = buffer.readu32(v1, 0)
    end

    local v24 = bit32.band(v20, 2147483648)

    if p22 < 0 then
        buffer.writeu32(v1, 0, (bit32.bor(1078530011, v24)))
        v19 = buffer.readf32(v1, 0) + v19
    end

    if p22 ~= 0 then
        return v19
    end

    buffer.writeu32(v1, 0, (bit32.bor(1070141403, v24)))

    return (buffer.readf32(v1, 0))
end

function t1.transform_direction(p23, p24) -- line: 133
    -- upvalues: scale (copy), madd (copy)
    return madd(p23[3], p24[3], madd(p23[2], p24[2], scale(p23[1], p24[1])))
end

function t1.projected_angle(p25, p26, p27) -- line: 137
    -- upvalues: rt (copy), v8 (copy), v11 (copy), dot (copy), sub (copy), scale (copy), cross (copy)
    if not (dot(p25, p25) * dot(p26, p26) > 1.52587890625E-05) then
        return 0
    end

    local v27 = sub(p25, scale(p27, dot(p27, p25)))
    local v28 = sub(p26, scale(p27, dot(p27, p26)))
    local v29 = dot(v27, v27)
    local v30 = dot(v28, v28)

    if not (v29 > 9.999999747378752E-05 and v30 > 9.999999747378752E-05) then
        return 0
    end

    local function one(p28) -- line: 149
        -- upvalues: v8 (copy)
        local v31 = v8.estimate(p28)

        return v31 * 0.5 * (-p28 * (v31 * v31) + 1) + v31
    end

    local v32 = v8.estimate(v29)
    local v33 = scale(v27, v32 * 0.5 * (-v29 * (v32 * v32) + 1) + v32)
    local v34 = v8.estimate(v30)
    local v35 = scale(v28, v34 * 0.5 * (-v30 * (v34 * v34) + 1) + v34)
    local v36 = v11.acos(rt.fmin(rt.fmax(dot(v33, v35), -1), 1))

    if dot(cross(v33, v35), p27) < 0 then
        return 6.2831854820251465 - v36
    end

    return v36
end

function t1.wrap(p29) -- line: 163
    local v37 = p29 * 0.15915493667125702
    local v38 = v37 - math.floor(v37)

    return (v38 - (if v38 > 0.5 then 1 else 0)) * 6.2831854820251465
end

return t1
