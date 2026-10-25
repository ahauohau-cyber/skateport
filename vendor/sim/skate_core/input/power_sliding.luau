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
local v8 = import("skate_core/point_graph")
local v9 = import("skate_core/physics/native_arithmetic")
local v10 = import("skate_core/input/controller")
local v11 = import("skate_core/input/angle")
local PointGraph = v8.PointGraph
local t1 = {}

t1.State = {}
t1.Settings = {}
t1.Input = {}

function t1.bit(p4, p5, p6) -- line: 62
    return (bit32.bor(bit32.band(p4, (bit32.bnot(p5))), if p6 then p5 else 0))
end

function t1.alignment(p7) -- line: 70
    -- upvalues: rt (copy), v9 (copy), v10 (copy), v11 (copy)
    if p7 == nil then
        return 1
    end

    local v15 = p7[1]
    local v16 = p7[2]
    local v17 = p7[3]

    local function dot(p8, p9) -- line: 75
        -- upvalues: v9 (copy)
        return v9.dot3(p8, p9)
    end

    local v18 = v9.dot3(v15, v15)

    if not (v18 > 0.0010000000474974513) then
        return 1
    end

    local v19 = v10.magnitude(v18)
    local v20 = v11.reciprocal_estimate(v19)
    local v21 = v20 * (-v20 * v19 + 1) + v20
    local v22 = v21 * (-v21 * v19 + 1) + v21

    return dot(rt.map(v15, function(p10) -- line: 87
        -- upvalues: v22 (copy)
        return v22 * p10
    end), if v17 == 0 then rt.copy(v16) else rt.map(v16, function(p11) -- line: 91
        return -p11
    end))
end

function t1.update(p12, p13, p14, p15, p16) -- line: 103
    -- upvalues: v1 (copy), t1 (copy), PointGraph (copy)
    local v23 = if p14.right_slide == nil then 0 else p14.right_slide
    local v24 = if p14.left_slide == nil then 0 else p14.left_slide
    local v25 = p14.category == 1

    if v25 and bit32.band(p12.flags, 536870912) == 0 then
        p12.elapsed = 0
        p12.previous_right = v23
        p12.previous_left = v24
        p12.flags = bit32.band(p12.flags, 1073741823)
    end

    p12.flags = t1.bit(p12.flags, 536870912, v25)

    if not v25 then
        return
    end

    local v26 = p14.speed > p15.minimum_speed
    local right_query = v26

    if v26 then
        right_query = p14.right_query

        if right_query then
            right_query = bit32.band(p12.flags, 2147483648) == 0 and p12.previous_right < v23
        end
    end

    p13[4] = t1.bit(p13[4], 2147483648, right_query)
    p12.previous_right = v23
    p12.flags = t1.bit(p12.flags, 2147483648, p14.right_query)

    local left_query = v26

    if v26 then
        left_query = p14.left_query

        if left_query then
            left_query = bit32.band(p12.flags, 1073741824) == 0 and v24 < p12.previous_left
        end
    end

    p13[2] = t1.bit(p13[2], 2147483648, left_query)
    p12.previous_left = v24
    p12.flags = t1.bit(p12.flags, 1073741824, p14.left_query)

    local v27 = PointGraph.evaluate(p15.stop_time, p14.graph_scalar)

    if PointGraph.evaluate(p15.speed_response, p14.speed) * (1 - math.abs(p14.graph_scalar)) < PointGraph.evaluate(p15.angle_response, p14.graph_scalar) then
        p12.elapsed += p16()
    else
        p12.elapsed = 0
    end

    local v29 = v27 < p12.elapsed
    local v30 = p16()

    buffer.writeu32(v1, 0, p13[3])

    local v32 = v30 + buffer.readf32(v1, 0)
    local v33

    if v32 ~= 0 and v32 > -1.1754943508222875E-38 and v32 < 1.1754943508222875E-38 then
        local v34 = math.abs(v32) * 7.1362384635298E+44
        local v35 = math.floor(v34)
        local v36 = v34 - v35

        v33 = if v36 > 0.5 or v36 == 0.5 and v35 % 2 == 1 then v35 + 1 else v35

        if v32 < 0 then
            v33 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v32)
        v33 = buffer.readu32(v1, 0)
    end

    p13[3] = v33

    local v37 = p16()

    buffer.writeu32(v1, 0, p13[1])

    local v39 = v37 + buffer.readf32(v1, 0)
    local v40

    if v39 ~= 0 and v39 > -1.1754943508222875E-38 and v39 < 1.1754943508222875E-38 then
        local v41 = math.abs(v39) * 7.1362384635298E+44
        local v42 = math.floor(v41)
        local v43 = v41 - v42

        v40 = if v43 > 0.5 or v43 == 0.5 and v42 % 2 == 1 then v42 + 1 else v42

        if v39 < 0 then
            v40 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v39)
        v40 = buffer.readu32(v1, 0)
    end

    p13[1] = v40

    local v44 = p15.minimum_slide_time < v32 and (p14.right_slide == nil or not v26 or v29)
    local v45 = p15.minimum_slide_time < v39 and (p14.left_slide == nil or not v26 or v29)

    p13[4] = t1.bit(p13[4], 1073741824, v44)
    p13[2] = t1.bit(p13[2], 1073741824, v45)
end

return t1
