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
    dot = function(p3, p4) -- dot | line: 35
        return p3[1] * p4[1] + p3[2] * p4[2] + p3[3] * p4[3]
    end,
    sub = function(p5, p6) -- sub | line: 39
        return {
            p5[1] - p6[1],
            p5[2] - p6[2],
            p5[3] - p6[3],
            p5[4] - p6[4]
        }
    end,
    flatten = function(p7) -- flatten | line: 44
        return {
            p7[1],
            0,
            p7[3],
            p7[4]
        }
    end,
    cross = function(p8, p9) -- cross | line: 48
        return {
            -p8[3] * p9[2] + p8[2] * p9[3],
            -p8[1] * p9[3] + p8[3] * p9[1],
            -p8[2] * p9[1] + p8[1] * p9[2],
            -p8[4] * p9[4] + p8[4] * p9[4]
        }
    end
}

function t1.inv_sqrt(p10, p11) -- line: 58
    -- upvalues: v9 (copy)
    local v11 = v9.estimate(p10)

    for _ = 0, p11 - 1 do
        v11 = v11 * 0.5 * (-p10 * (v11 * v11) + 1) + v11
    end

    return v11
end

local inv_sqrt = t1.inv_sqrt

function t1.reciprocal(p12) -- line: 67
    local v12 = 1 / p12
    local v13 = v12 * (-p12 * v12 + 1) + v12

    return v13 * (-p12 * v13 + 1) + v13
end

function t1.length(p13) -- line: 75
    -- upvalues: v1 (copy), t1 (copy), inv_sqrt (copy)
    local v14 = t1.dot(p13, p13)
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

    local v19 = v15 * inv_sqrt(v15, 2)

    if v15 == 0 then
        return 0
    end

    return v19
end

function t1.normalize(p14) -- line: 85
    -- upvalues: v1 (copy), t1 (copy), inv_sqrt (copy)
    local v20 = t1.dot(p14, p14)
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

    local v25 = inv_sqrt(v21, 2)

    if (if v21 == 0 then 0 else v21 * v25) > 9.999999974752427E-07 then
        return {
            p14[1] * v25,
            p14[2] * v25,
            p14[3] * v25,
            p14[4] * v25
        }
    end

    return { 0, 0, 0, 0 }
end

function t1.angle(p15, p16) -- line: 97
    -- upvalues: rt (copy), v10 (copy), t1 (copy), inv_sqrt (copy)
    local v26 = t1.dot(p15, p15)
    local v27 = t1.dot(p16, p16)

    if not (v26 > 9.999999747378752E-05 and v27 > 9.999999747378752E-05) then
        return 0
    end

    local v28 = inv_sqrt(v26, 1)
    local t2 = {
        p15[1] * v28,
        p15[2] * v28,
        p15[3] * v28,
        p15[4] * v28
    }
    local v29 = inv_sqrt(v27, 1)
    local t3 = {
        p16[1] * v29,
        p16[2] * v29,
        p16[3] * v29,
        p16[4] * v29
    }

    return v10.acos(rt.fmin(rt.fmax(t1.dot(t2, t3), -1), 1))
end

function t1.closest_point(p17, p18) -- line: 112
    -- upvalues: rt (copy), t1 (copy)
    local v30 = p18[1]
    local v31 = p18[2]
    local v32 = t1.sub(v31, v30)
    local v33 = t1.length(v32)

    if v33 > 1.52587890625E-05 then
        local v34 = t1.reciprocal(v33)

        v32 = {
            v32[1] * v34,
            v32[2] * v34,
            v32[3] * v34,
            v32[4] * v34
        }
    end

    local v35 = rt.fmax(rt.fmin(t1.dot(v32, t1.sub(p17, v30)), v33), 0)

    return {
        v32[1] * v35 + v30[1],
        v32[2] * v35 + v30[2],
        v32[3] * v35 + v30[3],
        v32[4] * v35 + v30[4]
    }
end

function t1.transform(p19, p20) -- line: 131
    local v36 = table.create(4)

    for i = 0, 3 do
        v36[i + 1] = p19[3][i + 1] * p20[3] + (p19[2][i + 1] * p20[2] + (p19[1][i + 1] * p20[1] + p19[4][i + 1]))
    end

    return v36
end

function t1.inverse_point(p21, p22) -- line: 140
    local t4 = {
        0, 0, 0, 0
    }

    for i = 0, 2 do
        local v37 = p21[i + 1][1] * -p21[4][1] + (p21[i + 1][2] * -p21[4][2] + p21[i + 1][3] * -p21[4][3])

        t4[i + 1] = p21[i + 1][3] * p22[3] + (p21[i + 1][2] * p22[2] + (p21[i + 1][1] * p22[1] + v37))
    end

    return t4
end

return t1
