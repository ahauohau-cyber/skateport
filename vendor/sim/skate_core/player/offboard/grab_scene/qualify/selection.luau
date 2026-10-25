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

local function grab_scene() -- line: 30
    -- upvalues: import (copy)
    return import("skate_core/player/offboard/grab_scene")
end

local t1 = {
    dot = function(p3, p4) -- dot | line: 41
        return p3[1] * p4[1] + p3[2] * p4[2] + p3[3] * p4[3]
    end
}
local dot = t1.dot

function t1.sub(p5, p6) -- line: 47
    return {
        p5[1] - p6[1],
        p5[2] - p6[2],
        p5[3] - p6[3],
        p5[4] - p6[4]
    }
end

local sub = t1.sub

function t1.scale(p7, p8) -- line: 53
    return {
        p7[1] * p8,
        p7[2] * p8,
        p7[3] * p8,
        p7[4] * p8
    }
end

local scale = t1.scale

function t1.inverse_length(p9) -- line: 59
    -- upvalues: v9 (copy)
    local v10 = v9.estimate(p9)
    local v11 = v10 * 0.5 * (-p9 * (v10 * v10) + 1) + v10

    return v11 * 0.5 * (-p9 * (v11 * v11) + 1) + v11
end

local inverse_length = t1.inverse_length

function t1.horizontal(p10) -- line: 69
    -- upvalues: v1 (copy), dot (copy), scale (copy), inverse_length (copy)
    local t2 = {
        p10[1],
        0,
        p10[3],
        p10[4]
    }
    local v12 = dot(t2, t2)
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

    local v17 = inverse_length(v13)

    if (if v13 == 0 then 0 else v13 * v17) > 9.999999974752427E-07 then
        return scale(t2, v17)
    end

    return { 0, 0, 0, 0 }
end

local horizontal = t1.horizontal

function t1.best_spline(p11, p12) -- line: 86
    -- upvalues: rt (copy), import (copy), dot (copy), sub (copy), horizontal (copy)
    local v18 = import("skate_core/player/offboard/grab_scene")
    local Record, closest_point = v18.Record, v18.closest_point
    local n1 = 99999.8984375
    local t3

    for _, v19 in p11 do
        local v20 = Record.endpoints(v19)
        local v21 = sub(closest_point(p12, v20), p12)
        local v22 = horizontal(sub(v20[1], v20[2]))
        local v23 = horizontal(v21)
        local v24 = v21[2] > -0.6000000238418579 and v21[2] < 0.6000000238418579 and math.abs((dot(v22, v23))) < 0.800000011920929
        local v26 = dot(v21, v21)

        if not (n1 <= v26) then
            n1 = v26

            if v24 then
                t3 = {
                    rt.copy(v19[1]),
                    v19[2]
                }
            else
                t3 = nil
            end
        end
    end

    return t3
end

return t1
