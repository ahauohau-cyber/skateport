-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/trigonometry")
local v2 = import("skate_core/physics/skeleton_root")
local t1 = {
    ZERO = { 0, 0, 0, 0 }
}
local ZERO = t1.ZERO

t1.UP = { 0, 1, 0, 0 }
t1.IDENTITY = {
    { 1, 0, 0, 0 },
    { 0, 1, 0, 0 },
    { 0, 0, 1, 0 },
    { 0, 0, 0, 0 }
}
t1.DT = 0.01666666753590107
t1.RATE = 59.999996185302734
t1.EPSILON = 0.0010000000474974513
t1.NORMAL_EPSILON = 9.999999974752427E-07

local NORMAL_EPSILON = t1.NORMAL_EPSILON

function t1.add(p1, p2) -- line: 28
    return {
        p1[1] + p2[1],
        p1[2] + p2[2],
        p1[3] + p2[3],
        p1[4] + p2[4]
    }
end

function t1.sub(p3, p4) -- line: 32
    return {
        p3[1] - p4[1],
        p3[2] - p4[2],
        p3[3] - p4[3],
        p3[4] - p4[4]
    }
end

function t1.scale(p5, p6) -- line: 36
    return {
        p5[1] * p6,
        p5[2] * p6,
        p5[3] * p6,
        p5[4] * p6
    }
end

local scale = t1.scale

function t1.madd(p7, p8, p9) -- line: 41
    return {
        p7[1] * p8 + p9[1],
        p7[2] * p8 + p9[2],
        p7[3] * p8 + p9[3],
        p7[4] * p8 + p9[4]
    }
end

local madd = t1.madd

function t1.dot(p10, p11) -- line: 46
    return p10[1] * p11[1] + p10[2] * p11[2] + p10[3] * p11[3]
end

local dot = t1.dot

function t1.cross(p12, p13) -- line: 51
    return {
        -p12[3] * p13[2] + p12[2] * p13[3],
        -p12[1] * p13[3] + p12[3] * p13[1],
        -p12[2] * p13[1] + p12[1] * p13[2],
        -p12[4] * p13[4] + p12[4] * p13[4]
    }
end

local cross = t1.cross

function t1.inverse_sqrt(p14) -- line: 62
    local v3 = 1 / math.sqrt(p14)
    local v4 = v3 * v3
    local v5 = v3 * 0.5 * (-p14 * v4 + 1) + v3
    local v6 = v5 * v5

    return v5 * 0.5 * (-p14 * v6 + 1) + v5
end

local inverse_sqrt = t1.inverse_sqrt

function t1.reciprocal(p15) -- line: 73
    local v7 = 1 / p15
    local v8 = v7 * (-p15 * v7 + 1) + v7

    return v8 * (-p15 * v8 + 1) + v8
end

function t1.length(p16) -- line: 81
    -- upvalues: dot (copy), inverse_sqrt (copy)
    local v9 = dot(p16, p16)
    local v10 = v9 * inverse_sqrt(v9)

    if v9 == 0 then
        return 0
    end

    return v10
end

local length = t1.length

function t1.normalize(p17) -- line: 92
    -- upvalues: scale (copy), dot (copy), inverse_sqrt (copy)
    return scale(p17, inverse_sqrt(dot(p17, p17)))
end

local normalize = t1.normalize

function t1.normalize_safe(p18, p19) -- line: 98
    -- upvalues: rt (copy), NORMAL_EPSILON (copy), scale (copy), dot (copy), inverse_sqrt (copy)
    local v11 = dot(p18, p18)
    local v12 = inverse_sqrt(v11)
    local v13 = scale(p18, v12)

    if (if v11 == 0 then 0 else v11 * v12) > NORMAL_EPSILON then
        return v13
    end

    return rt.copy(p19)
end

local normalize_safe = t1.normalize_safe

function t1.select(p20, p21, p22) -- line: 111
    if p20 >= 0 then
        return p21
    end

    return p22
end

local select = t1.select

function t1.clamp_signed(p23) -- line: 120
    -- upvalues: select (copy)
    local v14 = select(-1 - p23, -1, p23)

    return select(1 - v14, v14, 1)
end

function t1.transform_vector(p24, p25) -- line: 125
    -- upvalues: scale (copy), madd (copy)
    return madd(p25[3], p24[3], madd(p25[2], p24[2], scale(p25[1], p24[1])))
end

local transform_vector = t1.transform_vector

function t1.transform_point(p26, p27) -- line: 130
    -- upvalues: madd (copy)
    return madd(p27[3], p26[3], madd(p27[2], p26[2], madd(p27[1], p26[1], p27[4])))
end

local transform_point = t1.transform_point

function t1.compose(p28, p29) -- line: 135
    -- upvalues: transform_vector (copy), transform_point (copy)
    return {
        transform_vector(p28[1], p29),
        transform_vector(p28[2], p29),
        transform_vector(p28[3], p29),
        transform_point(p28[4], p29)
    }
end

function t1.inverse_rigid(p30) -- line: 144
    -- upvalues: v2 (copy)
    return v2.inverse_rigid(p30)
end

function t1.rotate(p31, p32, p33) -- line: 150
    -- upvalues: v1 (copy), ZERO (copy), transform_vector (copy)
    local v15 = p32[1]
    local v16 = p32[2]
    local v17 = p32[3]
    local v18, v19 = v1.sin_cos(p33)
    local v20 = 1 - v19
    local v21 = v20 * v15
    local v22 = v20 * v16
    local v23 = v20 * v17
    local v24 = v18 * v15
    local v25 = v18 * v16
    local v26 = v18 * v17
    local v27 = v21 * v15 + v19
    local v28 = v22 * v15 - v26
    local v29 = v23 * v15 + v25
    local t2 = {
        {
            v27,
            v21 * v16 + v26,
            v21 * v17 - v25,
            0
        },
        {
            v28,
            v22 * v16 + v19,
            v22 * v17 + v24,
            0
        },
        {
            v29,
            v23 * v16 - v24,
            v23 * v17 + v19,
            0
        }
    }

    return transform_vector(p31, {
        t2[1],
        t2[2],
        t2[3],
        ZERO
    })
end

function t1.limit_angle(p34, p35, p36) -- line: 168
    -- upvalues: rt (copy), v1 (copy), ZERO (copy), scale (copy), madd (copy), dot (copy), cross (copy), length (copy), normalize (copy), normalize_safe (copy)
    local v30 = normalize_safe(p34, ZERO)
    local v31 = normalize_safe(p35, ZERO)
    local v32 = cross(v30, v31)
    local v33 = rt.fmin(rt.fmax(dot(v30, v31), -1), 1)
    local v34 = v1.acos(v33)

    if math.abs(-math.floor(v34 * 0.15915493667125702 + 0.5) * 6.2831854820251465 + v34) < p36 or dot(v32, v32) < 1.52587890625E-05 then
        return rt.copy(p34)
    end

    local v37 = normalize(v32)
    local v38, v39 = v1.sin_cos(-p36 * 0.5)
    local v40 = scale(v37, v38)

    v40[4] = v39

    return scale(madd(cross(v40, (madd(p35, v39, (cross(v40, p35))))), 2, p35), length(p34))
end

return t1
