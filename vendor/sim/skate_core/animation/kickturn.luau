-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local PointGraph = require(sim.import)("skate_core/point_graph").PointGraph
local t1 = {
    Settings = {},
    Parameters = {}
}

function t1.Parameters.eq(p1, p2) -- line: 21
    if p1.max_height == p2.max_height then
        return p1.spin_scale == p2.spin_scale
    end

    return false
end

t1.State = {}
t1.Output = {}

function t1.Output.eq(p3, p4) -- line: 37
    if p3.balance == p4.balance then
        return p3.spin == p4.spin
    end

    return false
end

local bound

function t1.State.new() -- line: 43
    return {
        animation_length = 0,
        elapsed = 0,
        first_update = true,
        previous_height = 0,
        last_nonzero_intent = 0
    }
end

function t1.State.begin(p5, p6) -- line: 54
    -- upvalues: rt (copy), PointGraph (copy), t1 (copy)
    rt.assign(p5, t1.State.new())
    p5.previous_height = PointGraph.evaluate(p6.height, 0)
end

function t1.State.needs_animation_length(p7) -- line: 60
    return p7.first_update
end

function t1.State.capture_animation_length(p8, p9) -- line: 66
    p8.animation_length = p9
end

function t1.State.update(p10, p11, p12, p13, p14) -- line: 71
    -- upvalues: PointGraph (copy), bound (ref)
    if not p10.first_update then
        p10.elapsed += p11
    end

    local v1 = bound(p10.elapsed / p10.animation_length, 1)
    local v2 = PointGraph.evaluate(p14.spin, v1)
    local v3 = PointGraph.evaluate(p14.height, v1) * p13.max_height + p10.previous_height
    local v4 = bound(v3 * 0.5, p13.max_height)

    p10.previous_height = v4

    if p12 ~= 0 then
        p10.last_nonzero_intent = p12
    end

    local v5 = if p10.last_nonzero_intent >= 0 then 1 else -1
    local t2 = {
        balance = -v4,
        spin = p13.spin_scale * v5 * v2
    }

    p10.first_update = false

    return t2
end

function t1.bound(p15, p16) -- line: 102
    local v6 = if -p15 >= 0 then 0 else p15

    if p16 - v6 >= 0 then
        return v6
    end

    return p16
end

bound = t1.bound

return t1
