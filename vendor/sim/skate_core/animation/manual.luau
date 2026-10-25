-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local PointGraph = require(sim.import)("skate_core/point_graph").PointGraph
local t1 = {
    Settings = {}
}

function t1.Settings.eq(p1, p2) -- line: 21
    -- upvalues: PointGraph (copy)
    return PointGraph.eq(p1.balance, p2.balance) and p1.velocity_limit == p2.velocity_limit and p1.acceleration_limit == p2.acceleration_limit
end

t1.State = {}

function t1.State.default() -- line: 30
    return {
        angle = 0,
        velocity = 0
    }
end

function t1.State.eq(p3, p4) -- line: 35
    if p3.angle == p4.angle then
        return p3.velocity == p4.velocity
    end

    return false
end

local clamp

function t1.State.begin(p5) -- line: 41
    -- upvalues: rt (copy), t1 (copy)
    rt.assign(p5, t1.State.default())
end

function t1.State.update(p6, p7, p8) -- line: 46
    -- upvalues: PointGraph (copy), clamp (ref)
    local v1 = if p7 == nil then 0 else p7
    local v2 = PointGraph.evaluate(p8.balance, (math.abs(v1)))

    if not (v1 >= -0) then
        v2 = -v2
    end

    local v3 = clamp(v2 - p6.angle, p8.velocity_limit)
    local v4 = clamp(v3 - p6.velocity, p8.acceleration_limit)

    p6.velocity += v4
    p6.angle += p6.velocity

    return p6.angle
end

function t1.clamp(p9, p10) -- line: 58
    local v5 = if -p10 - p9 >= -0 then -p10 else p9

    if p10 - v5 >= -0 then
        return v5
    end

    return p10
end

clamp = t1.clamp

return t1
