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
local v9 = import("skate_core/physics/native_arithmetic")
local v10 = import("skate_core/physics/board_motion_output")
local PointGraph = import("skate_core/point_graph").PointGraph
local t1 = {
    dot3 = v9.dot3
}
local dot3 = t1.dot3
local sub, scale, length, reciprocal

function t1.lateral_pin(p3, p4, p5, p6, p7, p8, p9, p10, p11) -- line: 47
    -- upvalues: rt (copy), dot3 (copy), sub (ref), scale (ref), length (ref), reciprocal (ref)
    local v11 = if p10 then rt.copy(p3[3]) else scale(p3[3], -1)
    local v12 = table.create(4)

    for i = 0, 3 do
        v12[i + 1] = v11[i + 1] * p8 + p3[4][i + 1] - p3[2][i + 1] * p9
    end

    local v13 = scale(p5, dot3(sub(p4, v12), p5) * p7)
    local v14 = length(v13)

    if v14 > 0 then
        local v15 = scale(v13, reciprocal(v14))
        local v16 = scale(v15, p7 * 0.13300000131130219 * dot3(p6, v15))

        return scale(sub(v13, v16), p11)
    end

    return nil
end

function t1.friction(p12, p13, p14, p15, p16, p17, p18, p19) -- line: 75
    -- upvalues: rt (copy), v1 (copy), dot3 (copy), sub (ref), scale (ref), length (ref)
    local v17 = sub(p12, scale(p13, dot3(p12, p13)))
    local v18 = length(v17)
    local v19

    if v18 ~= 0 and v18 > -1.1754943508222875E-38 and v18 < 1.1754943508222875E-38 then
        local v20 = math.abs(v18) * 7.1362384635298E+44
        local v21 = math.floor(v20)
        local v22 = v20 - v21

        v19 = (if v22 > 0.5 or v22 == 0.5 and v21 % 2 == 1 then v21 + 1 else v21) * 1.401298464324817E-45

        if v18 < 0 then
            v19 = -v19
        end
    else
        buffer.writef32(v1, 0, v18)
        v19 = buffer.readf32(v1, 0)
    end

    buffer.writef32(v1, 0, 0.001)

    if v19 <= buffer.readf32(v1, 0) then
        return { 0, 0, 0, 0 }
    end

    local v23 = p19[(if p18 == 0 then 0 elseif p18 == 1 then 1 else 2) + 1]
    local v24 = rt.fmax(p14[2], 0)
    local v25 = if p16 then 1.9 else 1
    local v26 = v24 / v18 * p15 * v25 * p17 * v23 * -0.47999998927116394

    return scale(v17, v26)
end

function t1.sub(p20, p21) -- line: 112
    return {
        p20[1] - p21[1],
        p20[2] - p21[2],
        p20[3] - p21[3],
        p20[4] - p21[4]
    }
end

sub = t1.sub

function t1.scale(p22, p23) -- line: 117
    return {
        p22[1] * p23,
        p22[2] * p23,
        p22[3] * p23,
        p22[4] * p23
    }
end

scale = t1.scale

function t1.friction_applies(p24, p25) -- line: 123
    -- upvalues: v1 (copy), dot3 (copy), sub (ref), scale (ref), length (ref)
    local v27 = sub(p24, scale(p25, dot3(p24, p25)))
    local v28 = length(v27)
    local v29

    if v28 ~= 0 and v28 > -1.1754943508222875E-38 and v28 < 1.1754943508222875E-38 then
        local v30 = math.abs(v28) * 7.1362384635298E+44
        local v31 = math.floor(v30)
        local v32 = v30 - v31

        v29 = (if v32 > 0.5 or v32 == 0.5 and v31 % 2 == 1 then v31 + 1 else v31) * 1.401298464324817E-45

        if v28 < 0 then
            v29 = -v29
        end
    else
        buffer.writef32(v1, 0, v28)
        v29 = buffer.readf32(v1, 0)
    end

    buffer.writef32(v1, 0, 0.001)

    return buffer.readf32(v1, 0) < v29
end

function t1.length(p26) -- line: 131
    -- upvalues: v1 (copy), v10 (copy), dot3 (copy)
    local v33 = dot3(p26, p26)
    local v34 = false

    if v33 == 0 then
        v34 = true
    elseif v33 < 1E-44 then
        local v35

        if v33 == 0 then
            buffer.writef32(v1, 0, v33)
            v35 = buffer.readf32(v1, 0)
        elseif v33 > -1.1754943508222875E-38 and v33 < 1.1754943508222875E-38 then
            local v36 = math.abs(v33) * 7.1362384635298E+44
            local v37 = math.floor(v36)
            local v38 = v36 - v37

            if v38 > 0.5 or v38 == 0.5 and v37 % 2 == 1 then
                v37 += 1
            end

            v35 = v37 * 1.401298464324817E-45

            if v33 < 0 then
                v35 = -v35
            end
        else
            buffer.writef32(v1, 0, v33)
            v35 = buffer.readf32(v1, 0)
        end

        v34 = v35 == 0
    end

    if not v34 then
        return v33 * v10.inverse_length_squared(v33, 2)
    end

    return 0
end

length = t1.length

function t1.reciprocal(p27) -- line: 140
    local v39 = 1 / p27
    local v40 = v39 * (-v39 * p27 + 1) + v39

    return v40 * (-v40 * p27 + 1) + v40
end

reciprocal = t1.reciprocal

function t1.material_multiplier(p28) -- line: 151
    if p28 == 2 or p28 == 13 then
        return 1.7
    end

    if p28 == 3 then
        return 2.6
    end

    if p28 == 4 then
        return 0.6
    end

    if p28 == 5 then
        return 4
    end

    if p28 == 6 then
        return 5
    end

    return 1.3
end

function t1.pin_slope(p29, p30, p31, p32) -- line: 168
    -- upvalues: PointGraph (copy), dot3 (copy)
    if p31 > 0 then
        return 1
    end

    return PointGraph.evaluate(p32, dot3(p29, p30))
end

return t1
