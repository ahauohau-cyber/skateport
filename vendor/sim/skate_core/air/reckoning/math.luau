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
local v9 = import("skate_core/math")
local v10 = import("skate_core/physics/board_ground")
local v11 = import("skate_core/physics/board_motion_output")
local v12 = import("skate_core/physics/native_arithmetic")
local v13 = import("skate_core/trigonometry")
local Vector3 = v9.Vector3
local angle_between = v10.angle_between
local inverse_length_squared = v11.inverse_length_squared
local dot3, vector_max, vector_min = v12.dot3, v12.vector_max, v12.vector_min
local t1 = {
    V = {},
    EPSILON = 9.999999974752427E-07,
    TAU = 6.2831854820251465,
    INV_TAU = 0.15915493667125702
}
local EPSILON, TAU, INV_TAU = t1.EPSILON, t1.TAU, t1.INV_TAU

function t1.angle(p3, p4) -- line: 55
    -- upvalues: Vector3 (copy), angle_between (copy)
    return angle_between(Vector3.new(p3[1], p3[2], p3[3]), Vector3.new(p4[1], p4[2], p4[3]))
end

function t1.wrap(p5) -- line: 59
    -- upvalues: TAU (copy), INV_TAU (copy)
    local v14 = p5 * INV_TAU
    local v15 = v14 - math.floor(v14)

    return (v15 - (if v15 > 0.5 then 1 else 0)) * TAU
end

function t1.length(p6) -- line: 65
    -- upvalues: v1 (copy), inverse_length_squared (copy), dot3 (copy)
    local v16 = dot3(p6, p6)
    local v17

    if v16 ~= 0 and v16 > -1.1754943508222875E-38 and v16 < 1.1754943508222875E-38 then
        local v18 = math.abs(v16) * 7.1362384635298E+44
        local v19 = math.floor(v18)
        local v20 = v18 - v19

        v17 = (if v20 > 0.5 or v20 == 0.5 and v19 % 2 == 1 then v19 + 1 else v19) * 1.401298464324817E-45

        if v16 < 0 then
            v17 = -v17
        end
    else
        buffer.writef32(v1, 0, v16)
        v17 = buffer.readf32(v1, 0)
    end

    local v21 = inverse_length_squared(v17, 2)

    if v17 == 0 then
        return 0
    end

    return v17 * v21
end

function t1.normalize(p7) -- line: 71
    -- upvalues: inverse_length_squared (copy), dot3 (copy)
    local v22 = inverse_length_squared(dot3(p7, p7), 2)

    return {
        p7[1] * v22,
        p7[2] * v22,
        p7[3] * v22,
        p7[4] * v22
    }
end

function t1.normalize_safe(p8, p9) -- line: 76
    -- upvalues: v1 (copy), inverse_length_squared (copy), dot3 (copy), EPSILON (copy)
    local v23 = dot3(p8, p8)
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

    local v28 = inverse_length_squared(v24, 2)

    if (if v24 == 0 then 0 else v24 * v28) > EPSILON then
        return {
            p8[1] * v28,
            p8[2] * v28,
            p8[3] * v28,
            p8[4] * v28
        }
    end

    return p9
end

function t1.cross(p10, p11) -- line: 87
    return {
        -p10[3] * p11[2] + p10[2] * p11[3],
        -p10[1] * p11[3] + p10[3] * p11[1],
        -p10[2] * p11[1] + p10[1] * p11[2],
        -p10[4] * p11[4] + p10[4] * p11[4]
    }
end

function t1.limit_angle(p12, p13, p14) -- line: 98
    -- upvalues: v13 (copy), dot3 (copy), vector_max (copy), vector_min (copy), t1 (copy), TAU (copy), INV_TAU (copy)
    local v29 = t1.normalize_safe(p13, { 0, 0, 0, 0 })
    local v30 = t1.normalize_safe(p12, { 0, 0, 0, 0 })
    local v31 = t1.cross(v30, v29)
    local v32 = vector_min(vector_max(dot3(v30, v29), -1), 1)
    local v33 = v13.acos(v32)

    if math.abs(-math.floor(v33 * INV_TAU + 0.5) * TAU + v33) < p14 or dot3(v31, v31) < 1.52587890625E-05 then
        return p12
    end

    local v36 = t1.normalize(v31)
    local v37, v38 = v13.sin_cos(-p14 * 0.5)
    local t2 = {
        v36[1] * v37,
        v36[2] * v37,
        v36[3] * v37,
        v36[4] * v37
    }
    local v39 = t1.cross(t2, p13)
    local t3 = {
        v38 * p13[1] + v39[1],
        v38 * p13[2] + v39[2],
        v38 * p13[3] + v39[3],
        v38 * p13[4] + v39[4]
    }
    local v40 = t1.cross(t2, t3)
    local t4 = {
        v40[1] * 2 + p13[1],
        v40[2] * 2 + p13[2],
        v40[3] * 2 + p13[3],
        v40[4] * 2 + p13[4]
    }
    local v41 = t1.length(p12)

    return {
        t4[1] * v41,
        t4[2] * v41,
        t4[3] * v41,
        t4[4] * v41
    }
end

function t1.rotate_heading(p15, p16, p17) -- line: 133
    -- upvalues: rt (copy), v13 (copy)
    local v42 = p16[1]
    local v43 = p16[2]
    local v44 = p16[3]
    local v45, v46 = v13.sin_cos(p17)
    local v47 = 1 - v46
    local v48 = v47 * v42
    local v49 = v47 * v43
    local v50 = v47 * v44
    local v51 = v45 * v42
    local v52 = v45 * v43
    local v53 = v45 * v44
    local v54 = v48 * v42 + v46
    local v55 = v49 * v42 - v53
    local v56 = v50 * v42 + v52
    local t5 = {
        {
            v54,
            v48 * v43 + v53,
            v48 * v44 - v52,
            v54
        },
        {
            v55,
            v49 * v43 + v46,
            v49 * v44 + v51,
            v55
        },
        {
            v56,
            v50 * v43 - v51,
            v50 * v44 + v46,
            v56
        }
    }

    return rt.from_fn(4, function(p18) -- line: 147
        -- upvalues: p15 (copy), t5 (copy)
        local v57 = t5[1][p18 + 1] * p15[1]
        local v58 = t5[2][p18 + 1] * p15[2] + v57

        return t5[3][p18 + 1] * p15[3] + v58
    end)
end

return t1
