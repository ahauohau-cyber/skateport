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
local v9 = import("skate_core/physics/grind_contact")
local v10 = import("skate_core/physics/grind_contact/arithmetic")
local v11 = import("skate_core/point_graph")
local dot3, scale, sub, within_approach_angle = v9.dot3, v9.scale, v9.sub, v9.within_approach_angle
local PointGraph = v11.PointGraph
local t1 = {}

t1.EntryKind = {
    RideFromAbove = 0,
    RideFromBelow = 1,
    RideIntoCoping = 2,
    StayInGrind = 3,
    ChangeGrind = 4,
    AirToGrind = 5,
    DropIn = 6
}

local EntryKind = t1.EntryKind

t1.Decision = {}
t1.Admission = {}

function t1.Admission.test(p3, p4, p5, p6) -- line: 65
    -- upvalues: v10 (copy), t1 (copy), dot3 (copy), scale (copy), sub (copy), within_approach_angle (copy), PointGraph (copy), EntryKind (copy)
    local v12

    if p3.category == 400 or p3.state == 701 then
        v12 = if p3.state ~= p4 and (p4 ~= 402 or p3.state ~= 404) then EntryKind.ChangeGrind else EntryKind.StayInGrind
    elseif p3.category == 100 then
        if not (p6 and p3.speed < 1.45) then
            local v13 = t1.approach_slope_sine(p5, p3.velocity)

            v12 = if v13 > 0.96 then EntryKind.RideIntoCoping elseif v13 > 0.25 then EntryKind.RideFromBelow else EntryKind.RideFromAbove
        else
            v12 = EntryKind.DropIn
        end
    else
        v12 = EntryKind.AirToGrind
    end

    local v14

    if v12 == EntryKind.RideFromAbove then
        v14 = within_approach_angle(p5, p3.velocity, 17)
    elseif v12 == EntryKind.StayInGrind then
        v14 = within_approach_angle(p5, p3.velocity, 90)
    elseif v12 == EntryKind.ChangeGrind then
        v14 = within_approach_angle(p5, p3.velocity, 24)
    elseif v12 == EntryKind.AirToGrind or v12 == EntryKind.DropIn then
        v14 = true
    else
        local v15 = dot3(p3.velocity, p3.velocity)
        local v16 = sub(scale(p5, dot3(p3.velocity, p5)), p3.velocity)
        local v17 = dot3(v16, v16)
        local v18 = if v15 <= 0.002 then 1 else v10.square_root(v17 / v15)
        local v19 = t1.approach_slope_sine(p5, p3.velocity)
        local v20 = PointGraph.evaluate(p3.threshold_vs_slope, v19)
        local v21 = ((1 - v18) * 2.4 + 2.8) * v20

        v14 = v17 < v21 * v21
    end

    return {
        kind = v12,
        allowed = v14
    }
end

function t1.approach_slope_sine(p7, p8) -- line: 119
    -- upvalues: t1 (copy)
    return t1.slope_sine(p7, p8, 0.01)
end

function t1.engagement_slope_sine(p9, p10) -- line: 124
    -- upvalues: t1 (copy)
    return t1.slope_sine(p9, p10, 0.001)
end

function t1.slope_sine(p11, p12, p13) -- line: 128
    -- upvalues: v1 (copy), v10 (copy), dot3 (copy), scale (copy), sub (copy)
    local v22 = sub(p12, scale(p11, dot3(p12, p11)))
    local v23 = v10.square_root(dot3(v22, v22))
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

    local v28

    if p13 ~= 0 and p13 > -1.1754943508222875E-38 and p13 < 1.1754943508222875E-38 then
        local v29 = math.abs(p13) * 7.1362384635298E+44
        local v30 = math.floor(v29)
        local v31 = v29 - v30

        v28 = (if v31 > 0.5 or v31 == 0.5 and v30 % 2 == 1 then v30 + 1 else v30) * 1.401298464324817E-45

        if p13 < 0 then
            v28 = -v28
        end
    else
        buffer.writef32(v1, 0, p13)
        v28 = buffer.readf32(v1, 0)
    end

    if v24 <= v28 then
        return 0
    end

    return v10.reciprocal(v23) * v22[2]
end

return t1
