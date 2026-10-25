-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

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
local v9 = import("skate_core/physics/board_motion_output")
local v10 = import("skate_core/physics/native_arithmetic")
local v11 = import("skate_core/trigonometry")
local inverse_length_squared = v9.inverse_length_squared
local dot3, reciprocal_estimate = v10.dot3, v10.reciprocal_estimate
local t1 = {
    NativePumpingGeometry = {}
}

function t1.NativePumpingGeometry.height(_, p4, p5) -- line: 46
    -- upvalues: dot3 (copy)
    return dot3(p4, p5)
end

function t1.NativePumpingGeometry.speed(_, p7, p8, p9) -- line: 50
    -- upvalues: v1 (copy), inverse_length_squared (copy), dot3 (copy), t1 (copy)
    local v12 = t1.reciprocal(p9)
    local t2 = {
        (p8[1] - p7[1]) * v12,
        (p8[2] - p7[2]) * v12,
        (p8[3] - p7[3]) * v12,
        (p8[4] - p7[4]) * v12
    }
    local v13 = dot3(t2, t2)
    local v14

    if v13 ~= 0 and v13 > -1.1754943508222875E-38 and v13 < 1.1754943508222875E-38 then
        local v15 = math.abs(v13) * 7.1362384635298E+44
        local v16 = math.floor(v15)
        local v17 = v15 - v16

        v14 = (if v17 > 0.5 or v17 == 0.5 and v16 % 2 == 1 then v16 + 1 else v16) * 1.401298464324817E-45

        if v13 < 0 then
            v14 = -v14
        end
    else
        buffer.writef32(v1, 0, v13)
        v14 = buffer.readf32(v1, 0)
    end

    local v18 = v14 * inverse_length_squared(v14, 2)

    if v14 == 0 then
        return 0
    end

    return v18
end

function t1.NativePumpingGeometry.angular_speed(_, p11, p12, p13, p14) -- line: 67
    -- upvalues: v1 (copy), inverse_length_squared (copy), dot3 (copy), t1 (copy)
    local t3 = {
        p13.position[1] - p11[1],
        p13.position[2] - p11[2],
        p13.position[3] - p11[3],
        p13.position[4] - p11[4]
    }
    local v19 = t1.cross(t3, p13.normal)
    local v20 = dot3(v19, v19)
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

    local v25 = inverse_length_squared(v21, 2)

    if (if v21 == 0 then 0 else v21 * v25) > 9.999999974752427E-07 then
        v19[1] *= v25
        v19[2] *= v25
        v19[3] *= v25
        v19[4] *= v25
    else
        v19 = { 0, 0, 0, 0 }
    end

    local v26 = t1.reciprocal(p14)
    local v27 = t1.cross(p12, p13.normal)

    v27[1] *= v26
    v27[2] *= v26
    v27[3] *= v26
    v27[4] *= v26

    return dot3(v27, v19)
end

function t1.NativePumpingGeometry.inclination_radians(_, p16) -- line: 98
    -- upvalues: v11 (copy)
    return v11.acos(p16)
end

function t1.reciprocal(p17) -- line: 102
    -- upvalues: reciprocal_estimate (copy)
    local v28 = reciprocal_estimate(p17)
    local v29 = v28 * (-v28 * p17 + 1) + v28

    return v29 * (-v29 * p17 + 1) + v29
end

function t1.cross(p18, p19) -- line: 111
    local t4 = {
        1, 2, 0, 3
    }
    local t5 = {
        -p18[t4[1] + 1] * p19[1] + p18[1] * p19[t4[1] + 1],
        -p18[t4[2] + 1] * p19[2] + p18[2] * p19[t4[2] + 1],
        -p18[t4[3] + 1] * p19[3] + p18[3] * p19[t4[3] + 1],
        -p18[t4[4] + 1] * p19[4] + p18[4] * p19[t4[4] + 1]
    }

    return {
        t5[t4[1] + 1],
        t5[t4[2] + 1],
        t5[t4[3] + 1],
        t5[t4[4] + 1]
    }
end

return t1
