-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local PointGraph = import("skate_core/point_graph").PointGraph
local compose_affine = import("skate_core/physics/skeleton_animation_record").compose_affine
local sin_cos = import("skate_core/trigonometry").sin_cos
local t1 = {
    Settings = {},
    Wobble = {}
}

function t1.Wobble.default() -- line: 26
    return {
        active = false,
        landing = false,
        time = 0,
        amplitude = 0,
        direction = 1,
        selected_landing_curves = true
    }
end

t1.Output = {}

function t1.Output.default() -- line: 44
    return {
        sampled = false,
        tilt = 0,
        squish = 0,
        remains_active = false
    }
end

function t1.Wobble.trigger(p1, p2, p3) -- line: 53
    p1.selected_landing_curves = p2
    p1.landing = p2
    p1.active = true
    p1.time = 0
    p1.amplitude = 1
    p1.direction = p3 and -1 or 1
end

function t1.Wobble.update(p4, p5) -- line: 63
    -- upvalues: PointGraph (copy), t1 (copy)
    if not p4.active then
        return t1.Output.default()
    end

    local v1, v2

    if p4.selected_landing_curves then
        v2 = p5.landing_tilt
        v1 = p5.landing_squish
    else
        v2 = p5.takeoff_tilt
        v1 = p5.takeoff_squish
    end

    local v3 = PointGraph.evaluate(v1, p4.time) * p4.amplitude
    local v4 = PointGraph.evaluate(v2, p4.time) * p4.direction * p4.amplitude

    p4.time += 0.01666666753590107

    if p4.time > p5.maximum_time then
        p4.active = false
        p4.time = 0
    end

    return {
        sampled = true,
        tilt = v4,
        squish = v3,
        remains_active = p4.active
    }
end

function t1.apply(p6, p7) -- line: 91
    -- upvalues: rt (copy), compose_affine (copy), sin_cos (copy)
    if p6.sampled then
        local v5, v6 = sin_cos(p6.tilt)
        local t2 = {
            { v6, v5, 0, v6 },
            { -v5, v6, 0, -v5 },
            { 0, 0, 1, 0 },
            table.create(4, 0)
        }

        rt.assign(p7, compose_affine(p7, t2))
        p7[4][1] = p7[2][1] * p6.squish + p7[4][1]
        p7[4][2] = p7[2][2] * p6.squish + p7[4][2]
        p7[4][3] = p7[2][3] * p6.squish + p7[4][3]
        p7[4][4] = p7[2][4] * p6.squish + p7[4][4]
    end
end

return t1
