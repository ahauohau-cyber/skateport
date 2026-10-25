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
local inverse_length_squared = import("skate_core/physics/board_motion_output").inverse_length_squared
local v9 = import("skate_core/physics/native_arithmetic")
local t1 = {
    add = function(p3, p4) -- add | line: 36
        return {
            p3[1] + p4[1],
            p3[2] + p4[2],
            p3[3] + p4[3],
            p3[4] + p4[4]
        }
    end,
    sub = function(p5, p6) -- sub | line: 40
        return {
            p5[1] - p6[1],
            p5[2] - p6[2],
            p5[3] - p6[3],
            p5[4] - p6[4]
        }
    end,
    scale = function(p7, p8) -- scale | line: 44
        return {
            p7[1] * p8,
            p7[2] * p8,
            p7[3] * p8,
            p7[4] * p8
        }
    end,
    madd = function(p9, p10, p11) -- madd | line: 48
        return {
            p9[1] * p10 + p11[1],
            p9[2] * p10 + p11[2],
            p9[3] * p10 + p11[3],
            p9[4] * p10 + p11[4]
        }
    end
}

function t1.dot(p12, p13) -- line: 52
    -- upvalues: v9 (copy)
    return v9.dot3(p12, p13)
end

function t1.cross(p14, p15) -- line: 56
    return {
        -p14[3] * p15[2] + p14[2] * p15[3],
        -p14[1] * p15[3] + p14[3] * p15[1],
        -p14[2] * p15[1] + p14[1] * p15[2],
        -p14[4] * p15[4] + p14[4] * p15[4]
    }
end

function t1.length(p16) -- line: 75
    -- upvalues: v1 (copy), inverse_length_squared (copy), t1 (copy)
    local v10 = t1.dot(p16, p16)
    local v11 = false

    if v10 == 0 then
        v11 = true
    elseif v10 < 1E-44 then
        local v12

        if v10 == 0 then
            buffer.writef32(v1, 0, v10)
            v12 = buffer.readf32(v1, 0)
        elseif v10 > -1.1754943508222875E-38 and v10 < 1.1754943508222875E-38 then
            local v13 = math.abs(v10) * 7.1362384635298E+44
            local v14 = math.floor(v13)
            local v15 = v13 - v14

            if v15 > 0.5 or v15 == 0.5 and v14 % 2 == 1 then
                v14 += 1
            end

            v12 = v14 * 1.401298464324817E-45

            if v10 < 0 then
                v12 = -v12
            end
        else
            buffer.writef32(v1, 0, v10)
            v12 = buffer.readf32(v1, 0)
        end

        v11 = v12 == 0
    end

    if not v11 then
        return v10 * inverse_length_squared(v10, 2)
    end

    return 0
end

function t1.normalize(p17) -- line: 84
    -- upvalues: inverse_length_squared (copy), t1 (copy)
    return t1.scale(p17, inverse_length_squared(t1.dot(p17, p17), 2))
end

function t1.normalize_or(p18, p19) -- line: 90
    -- upvalues: rt (copy), t1 (copy)
    if t1.length(p18) > 9.999999974752427E-07 then
        return t1.normalize(p18)
    end

    return rt.copy(p19)
end

function t1.reciprocal(p20) -- line: 98
    -- upvalues: v9 (copy)
    local v16 = v9.reciprocal_estimate(p20)
    local v17 = v16 * (-v16 * p20 + 1) + v16

    return v17 * (-v17 * p20 + 1) + v17
end

function t1.clamp(p21, p22, p23) -- line: 106
    local v18 = if p22 - p21 >= 0 then p22 else p21

    if p23 - v18 >= 0 then
        return v18
    end

    return p23
end

function t1.limit_length(p24, p25) -- line: 119
    -- upvalues: rt (copy), t1 (copy)
    local v19 = t1.length(p24)

    if v19 >= 1.52587890625E-05 then
        local v20 = if p25 - v19 >= 0 then v19 else p25

        return t1.scale(t1.scale(p24, v20), t1.reciprocal(v19))
    end

    return rt.copy(p24)
end

function t1.wrap_angle(p26) -- line: 128
    local v21 = p26 * 0.15915493667125702
    local v22 = v21 - math.floor(v21)

    if v22 > 0.5 then
        v22 -= 1
    end

    return v22 * 6.2831854820251465
end

return t1
