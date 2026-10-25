-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/air/trajectory/math")
local v2 = import("skate_core/air/trajectory/grind_surface/classify")
local v3 = import("skate_core/air/trajectory/grind_surface/orientation")
local v4 = import("skate_core/air/trajectory/grind_surface/landing")
local UP, dot, add, sub = v1.UP, v1.dot, v1.add, v1.sub
local scale, madd, cross, inverse_length = v1.scale, v1.madd, v1.cross, v1.inverse_length
local length = v1.length
local t1 = {
    LandingOrientation = v4.LandingOrientation,
    update_landing_orientation = v4.update_landing_orientation,
    InvestigationInput = {},
    Probe = {}
}

function t1.Probe.eq(p1, p2) -- line: 39
    for i = 1, 4 do
        if p1.start[i] ~= p2.start[i] or p1["end"][i] ~= p2["end"][i] then
            return false
        end
    end

    return p1.radius == p2.radius
end

t1.ProbeHit = {}
t1.Investigation = {}
t1.GeometryType = {
    ThinRail = 0,
    FatRail = 1,
    Ledge = 2,
    Impossible = 3
}
t1.GrindSurface = {}
t1.GrindSurface.INVALID = 2147483648
t1.GrindSurface.CURB = 1073741824
t1.GrindSurface.BLOCKED_CROSS_SECTION = 536870912
t1.GrindSurface.STAIR = 268435456
t1.GrindSurface.OPTIONAL_NORMAL_TEST = 134217728
t1.GrindSurface.OPTIONAL_DROP_TEST = 67108864

function t1.GrindSurface.not_submitted(p3) -- line: 89
    -- upvalues: rt (copy), v3 (copy), sub (copy), scale (copy), madd (copy), t1 (copy)
    local deck_center_to_truck = p3.deck_center_to_truck
    local t2 = {
        1, 0, 0, 0
    }
    local t3 = {
        0, 0, 1, 0
    }

    return {
        audio_surface = 3,
        physics_surface = 1,
        center = rt.copy(p3.reference),
        far_points = {
            madd(t2, deck_center_to_truck, p3.reference),
            sub(p3.reference, scale(t2, deck_center_to_truck))
        },
        upmost_normal = rt.copy(t3),
        direction = rt.copy(t3),
        high_side = rt.copy(t3),
        normal_limits = { 0, 0 },
        kind = t1.GeometryType.Impossible,
        flags = t1.GrindSurface.INVALID,
        tilted_upmost_normal = v3.tilted_normal(t3, t3, { 0, 0 })
    }
end

function t1.prepare(p4) -- line: 110
    -- upvalues: rt (copy), UP (copy), dot (copy), add (copy), sub (copy), scale (copy), madd (copy), cross (copy), inverse_length (copy), length (copy)
    local v5 = sub(p4["end"], p4.start)
    local v6 = cross(v5, cross(UP, v5))
    local v7 = length(v6)

    local function retain_normalized(p5) -- line: 114
        -- upvalues: rt (copy), dot (copy), scale (copy), inverse_length (copy)
        local v8 = dot(p5, p5)
        local v9 = inverse_length(v8)

        if (if v8 == 0 then 0 else v8 * v9) > 9.999999974752427E-07 then
            return scale(p5, v9)
        end

        return rt.copy(p5)
    end

    local v10 = dot(v6, v6)
    local v11 = inverse_length(v10)
    local v12 = if (if v10 == 0 then 0 else v10 * v11) > 9.999999974752427E-07 then scale(v6, v11) else rt.copy(v6)
    local v13 = dot(v5, v5)
    local v14 = inverse_length(v13)
    local v15 = if (if v13 == 0 then 0 else v13 * v14) > 9.999999974752427E-07 then scale(v5, v14) else rt.copy(v5)

    if v7 < 9.999999747378752E-06 then
        return nil
    end

    local v16 = madd(v15, dot(sub(p4.reference, p4.start), v15), p4.start)
    local v17 = sub(p4.reference, sub(p4.reference, v16))
    local v18 = cross(v12, v15)
    local v19 = scale(v12, 0.03999999910593033)
    local v20 = scale(v18, 0.09000000357627869)
    local v21 = scale(v18, p4.deck_center_to_truck)
    local v22 = scale(v12, p4.deck_center_to_truck * 1.059999942779541)
    local v23 = scale(v12, 0.09000000357627869)

    local function line(p6, p7, p8) -- line: 137
        -- upvalues: add (copy), sub (copy)
        return {
            start = add(p6, p7),
            ["end"] = sub(p6, p7),
            radius = p8
        }
    end

    local v24 = add(v17, v20)
    local t4 = {
        start = add(v24, v19),
        ["end"] = sub(v24, v19),
        radius = 0
    }
    local v25 = sub(v17, v20)
    local t5 = {
        start = add(v25, v19),
        ["end"] = sub(v25, v19),
        radius = 0
    }
    local v26 = add(v17, v21)
    local t6 = {
        start = add(v26, v22),
        ["end"] = sub(v26, v22),
        radius = 0
    }
    local v27 = sub(v17, v21)
    local t7 = {
        start = add(v27, v22),
        ["end"] = sub(v27, v22),
        radius = 0
    }
    local t8 = {
        start = add(v17, v19),
        ["end"] = sub(v17, v19),
        radius = 0
    }
    local v28 = add(v17, v23)
    local t9 = {
        t4,
        t5,
        t6,
        t7,
        t8,
        {
            start = add(v28, v20),
            ["end"] = sub(v28, v20),
            radius = 0.0010000000474974513
        }
    }

    if p4.optional_probe ~= nil then
        local v29 = rt.copy(p4.optional_probe)

        table.insert(t9, {
            start = v29,
            ["end"] = add(v29, { 0, -6, 0, 0 }),
            radius = 0
        })
    end

    return {
        center = v17,
        upmost_normal = v12,
        direction = v15,
        probes = t9
    }
end

function t1.investigate(p9, p10) -- line: 159
    -- upvalues: rt (copy), v2 (copy), t1 (copy)
    local v30 = t1.prepare(p9)

    if v30 == nil then
        return t1.GrindSurface.not_submitted(p9)
    end

    local t11 = {}

    for i = 0, #v30.probes - 1 do
        t11[i + 1] = p10(i, rt.copy(v30.probes[i + 1]))
    end

    return v2.resolve(v30, t11, 0)
end

function t1.resolve(p11, p12, p13) -- line: 175
    -- upvalues: v2 (copy)
    return v2.resolve(p11, p12, p13)
end

return t1
