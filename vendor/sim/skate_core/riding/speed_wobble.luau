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
local v8 = import("skate_core/point_graph")
local v9 = import("skate_core/trigonometry")
local PointGraph = v8.PointGraph
local sin = v9.sin
local t1 = {
    SpeedWobbleSettings = {},
    SpeedWobbleState = {}
}

function t1.SpeedWobbleState.reset(p4) -- line: 67
    for _, v10 in { 0, 2, 3, 4, 5, 6 } do
        p4[1][v10 + 1] = 0
    end

    p4[1][8] = bit32.band(p4[1][8], 16777215)
end

function t1.SpeedWobbleState.active(p5) -- line: 74
    return bit32.rshift(p5[1][8], 24) ~= 0
end

t1.SpeedWobbleInput = {}

function t1.calculate(p6, p7, p8) -- line: 89
    -- upvalues: v1 (copy), PointGraph (copy), sin (copy), t1 (copy)
    local SpeedWobbleState = t1.SpeedWobbleState
    local v14 = (p8.center_of_mass_height - p7.height_min) / (p7.height_max - p7.height_min)
    local v15 = t1.unit(1 - v14) * p7.crouch_threshold + p7.tightness_threshold * p8.truck_tightness + p8.activation_threshold

    if not SpeedWobbleState.active(p6) and v15 < p8.speed then
        SpeedWobbleState.reset(p6)
        p6[1][8] = bit32.bor(p6[1][8], 16777216)
    end

    if not SpeedWobbleState.active(p6) then
        return p8.tilt
    end

    buffer.writeu32(v1, 0, p6[1][1])

    local v19 = buffer.readf32(v1, 0)
    local v20 = t1.unit(v19 / p7.time_range)
    local v21 = t1.unit((p8.speed - v15) / p7.speed_range)
    local v22 = PointGraph.evaluate(p7.frequency_time, v20) * PointGraph.evaluate(p7.frequency_speed, v21) * p7.frequency_scale
    local v23 = PointGraph.evaluate(p7.amplitude_speed, v21) * PointGraph.evaluate(p7.amplitude_time, v20)
    local v24 = v22 * 0.10471976548433304

    buffer.writeu32(v1, 0, p6[1][5])

    local v26 = v24 + buffer.readf32(v1, 0)
    local v27 = p7.amplitude_scale * v23 * p8.amplitude_multiplier
    local v28 = sin(v26) * v27
    local v29 = p6[1]
    local v30 = v19 + 0.01666666753590107
    local v31

    if v30 ~= 0 and v30 > -1.1754943508222875E-38 and v30 < 1.1754943508222875E-38 then
        local v32 = math.abs(v30) * 7.1362384635298E+44
        local v33 = math.floor(v32)
        local v34 = v32 - v33

        v31 = if v34 > 0.5 or v34 == 0.5 and v33 % 2 == 1 then v33 + 1 else v33

        if v30 < 0 then
            v31 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v30)
        v31 = buffer.readu32(v1, 0)
    end

    v29[1] = v31

    local v35 = p6[1]
    local v36

    if v26 ~= 0 and v26 > -1.1754943508222875E-38 and v26 < 1.1754943508222875E-38 then
        local v37 = math.abs(v26) * 7.1362384635298E+44
        local v38 = math.floor(v37)
        local v39 = v37 - v38

        v36 = if v39 > 0.5 or v39 == 0.5 and v38 % 2 == 1 then v38 + 1 else v38

        if v26 < 0 then
            v36 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v26)
        v36 = buffer.readu32(v1, 0)
    end

    v35[5] = v36

    local v40 = p6[1]
    local v41

    if v23 ~= 0 and v23 > -1.1754943508222875E-38 and v23 < 1.1754943508222875E-38 then
        local v42 = math.abs(v23) * 7.1362384635298E+44
        local v43 = math.floor(v42)
        local v44 = v42 - v43

        v41 = if v44 > 0.5 or v44 == 0.5 and v43 % 2 == 1 then v43 + 1 else v43

        if v23 < 0 then
            v41 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v23)
        v41 = buffer.readu32(v1, 0)
    end

    v40[6] = v41

    local v45 = p6[1]
    local v46

    if v28 ~= 0 and v28 > -1.1754943508222875E-38 and v28 < 1.1754943508222875E-38 then
        local v47 = math.abs(v28) * 7.1362384635298E+44
        local v48 = math.floor(v47)
        local v49 = v47 - v48

        v46 = if v49 > 0.5 or v49 == 0.5 and v48 % 2 == 1 then v48 + 1 else v48

        if v28 < 0 then
            v46 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v28)
        v46 = buffer.readu32(v1, 0)
    end

    v45[7] = v46

    local v50 = (v28 + p8.tilt) * 0.5

    if p8.speed < v15 then
        SpeedWobbleState.reset(p6)
    end

    return v50
end

function t1.unit(p9) -- line: 127
    local v51 = if -p9 >= 0 then 0 else p9

    if 1 - v51 >= 0 then
        return v51
    end

    return 1
end

return t1
