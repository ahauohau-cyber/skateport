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
local v8 = import("skate_core/player/offboard/contact_correction")
local clamp_length, inverse_length, magnitude = v8.clamp_length, v8.inverse_length, v8.magnitude
local dot3 = import("skate_core/physics/native_arithmetic").dot3
local PointGraph = import("skate_core/point_graph").PointGraph
local t1 = {
    SpecialMode = {}
}

function t1.SpecialMode.eq(p4, p5) -- line: 47
    if p4.enabled_714 == p5.enabled_714 then
        return p4.elapsed_788 == p5.elapsed_788
    end

    return false
end

function t1.SpecialMode.update(p6, p7, p8, p9) -- line: 51
    if p6.enabled_714 then
        p6.elapsed_788 += 0.01666666753590107

        if not (p7 >= 0.5 and (p6.elapsed_788 <= 0.5 or bit32.band(p8, 512) ~= 0)) then
            p6.enabled_714 = false
        end
    elseif p6.elapsed_788 <= 0 then
        if bit32.band(p8, 512) ~= 0 then
            p6.elapsed_788 = 0
            p6.enabled_714 = true
        end
    elseif p9 < 0.15000000596046448 then
        p6.elapsed_788 = 0
    end
end

t1.Sliding = {}

function t1.Sliding.eq(p10, p11) -- line: 74
    if p10.velocity_528[1] == p11.velocity_528[1] and p10.velocity_528[2] == p11.velocity_528[2] and p10.velocity_528[3] == p11.velocity_528[3] and p10.velocity_528[4] == p11.velocity_528[4] then
        return p10.active_710 == p11.active_710
    end

    return false
end

t1.Input = {}

function t1.Sliding.update(p12, p13, p14, p15) -- line: 92
    -- upvalues: rt (copy), v1 (copy), clamp_length (copy), dot3 (copy), PointGraph (copy), t1 (copy)
    if p13.special_mode_714 then
        return
    end

    local t2 = {
        0, -1, 0, 0
    }
    local v9 = rt.copy(p13.surface_normal_560)
    local v10 = dot3(v9, t2)
    local t3 = {
        t2[1] - v9[1] * v10,
        t2[2] - v9[2] * v10,
        t2[3] - v9[3] * v10,
        t2[4] - v9[4] * v10
    }
    local v11 = -t3[2]
    local v12 = t1.select(-v11, 0, v11)
    local v13 = t1.select(1 - v12, v12, 1)
    local v14 = t1.safe_unit(t3)
    local v15 = v14[1]
    local v16

    if v15 ~= 0 and v15 > -1.1754943508222875E-38 and v15 < 1.1754943508222875E-38 then
        local v17 = math.abs(v15) * 7.1362384635298E+44
        local v18 = math.floor(v17)
        local v19 = v17 - v18

        v16 = if v19 > 0.5 or v19 == 0.5 and v18 % 2 == 1 then v18 + 1 else v18

        if v15 < 0 then
            v16 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v15)
        v16 = buffer.readu32(v1, 0)
    end

    buffer.writeu32(v1, 0, (bit32.bxor(v16, 2147483648)))

    local v21 = buffer.readf32(v1, 0)
    local v22 = v14[2]
    local v23

    if v22 ~= 0 and v22 > -1.1754943508222875E-38 and v22 < 1.1754943508222875E-38 then
        local v24 = math.abs(v22) * 7.1362384635298E+44
        local v25 = math.floor(v24)
        local v26 = v24 - v25

        v23 = if v26 > 0.5 or v26 == 0.5 and v25 % 2 == 1 then v25 + 1 else v25

        if v22 < 0 then
            v23 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v22)
        v23 = buffer.readu32(v1, 0)
    end

    buffer.writeu32(v1, 0, (bit32.bxor(v23, 2147483648)))

    local v28 = buffer.readf32(v1, 0)
    local v29 = v14[3]
    local v30

    if v29 ~= 0 and v29 > -1.1754943508222875E-38 and v29 < 1.1754943508222875E-38 then
        local v31 = math.abs(v29) * 7.1362384635298E+44
        local v32 = math.floor(v31)
        local v33 = v31 - v32

        v30 = if v33 > 0.5 or v33 == 0.5 and v32 % 2 == 1 then v32 + 1 else v32

        if v29 < 0 then
            v30 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v29)
        v30 = buffer.readu32(v1, 0)
    end

    buffer.writeu32(v1, 0, (bit32.bxor(v30, 2147483648)))

    local v35 = buffer.readf32(v1, 0)
    local v36 = v14[4]
    local v37

    if v36 ~= 0 and v36 > -1.1754943508222875E-38 and v36 < 1.1754943508222875E-38 then
        local v38 = math.abs(v36) * 7.1362384635298E+44
        local v39 = math.floor(v38)
        local v40 = v38 - v39

        v37 = if v40 > 0.5 or v40 == 0.5 and v39 % 2 == 1 then v39 + 1 else v39

        if v36 < 0 then
            v37 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v36)
        v37 = buffer.readu32(v1, 0)
    end

    buffer.writeu32(v1, 0, (bit32.bxor(v37, 2147483648)))

    local t4 = {
        v21,
        v28,
        v35,
        (buffer.readf32(v1, 0))
    }
    local v43 = dot3(p13.movement_velocity_480, t4)
    local v44 = -(PointGraph.evaluate(p14, v13) * PointGraph.evaluate(p15, v43))
    local v45 = clamp_length({
        t3[1] * (-9.800000190734863 * v44),
        t3[2] * (-9.800000190734863 * v44),
        t3[3] * (-9.800000190734863 * v44),
        t3[4] * (-9.800000190734863 * v44)
    }, 5)

    p12.velocity_528 = {
        v45[1] * 0.05000000074505806 + p12.velocity_528[1] * 0.95,
        v45[2] * 0.05000000074505806 + p12.velocity_528[2] * 0.95,
        v45[3] * 0.05000000074505806 + p12.velocity_528[3] * 0.95,
        v45[4] * 0.05000000074505806 + p12.velocity_528[4] * 0.95
    }

    if dot3(v45, v45) < 0.010000000707805157 then
        p12.velocity_528 = {
            p12.velocity_528[1] * 0.9,
            p12.velocity_528[2] * 0.9,
            p12.velocity_528[3] * 0.9,
            p12.velocity_528[4] * 0.9
        }
    end

    local contact_direction_400 = p13.contact_direction_400

    if contact_direction_400 ~= nil then
        p12.velocity_528 = t1.reject_positive(p12.velocity_528, {
            -contact_direction_400[1],
            -contact_direction_400[2],
            -contact_direction_400[3],
            -contact_direction_400[4]
        })
    end

    p12.active_710 = dot3(p12.velocity_528, p12.velocity_528) > 0.010000000707805157
end

function t1.select(p16, p17, p18) -- line: 151
    if p16 >= 0 then
        return p17
    end

    return p18
end

function t1.safe_unit(p19) -- line: 159
    -- upvalues: inverse_length (copy), magnitude (copy), dot3 (copy)
    local v46 = dot3(p19, p19)
    local v47 = inverse_length(v46)

    if magnitude(v46) > 9.999999974752427E-07 then
        return {
            p19[1] * v47,
            p19[2] * v47,
            p19[3] * v47,
            p19[4] * v47
        }
    end

    return { 0, 0, 0, 0 }
end

function t1.reject_positive(p20, p21) -- line: 171
    -- upvalues: rt (copy), dot3 (copy), t1 (copy)
    local v48 = dot3(p20, t1.safe_unit(p21))

    if v48 > 0 then
        return {
            p20[1] - p21[1] * v48,
            p20[2] - p21[2] * v48,
            p20[3] - p21[3] * v48,
            p20[4] - p21[4] * v48
        }
    end

    return rt.copy(p20)
end

return t1
