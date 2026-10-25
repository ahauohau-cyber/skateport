-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local PointGraph = require(sim.import)("skate_core/point_graph").PointGraph
local t1 = {
    SlowMotionSettings = {},
    SimulationRateRequest = {},
    SlowMotionController = {}
}

function t1.SlowMotionController.begin(p1) -- line: 26
    -- upvalues: t1 (copy)
    return {
        elapsed = 0,
        air_duration = 0,
        time_before_prediction = 0,
        latched_prediction = false
    }, t1.SlowMotionSettings.request(p1, 0)
end

function t1.SlowMotionController.update(p2, p3, p4, p5) -- line: 36
    -- upvalues: t1 (copy)
    p2.elapsed += p3

    local v1 = 0.10000000149011612

    if p4 > 0 then
        if not p2.latched_prediction then
            p2.air_duration = p4
            p2.latched_prediction = true
        end

        v1 = p2.elapsed / (p2.time_before_prediction + p2.air_duration)
    elseif not p2.latched_prediction then
        p2.time_before_prediction += p3
    end

    return t1.SlowMotionSettings.request(p5, v1)
end

t1.SlowMotionController["end"] = function() -- line: 55
    return {
        timestep = 0.01666666753590107,
        ticks = 0
    }
end

function t1.SlowMotionSettings.request(p6, p7) -- line: 62
    -- upvalues: PointGraph (copy)
    return {
        ticks = 1,
        timestep = 1 / (PointGraph.evaluate(p6.timescale, p7) * (p6.fps_at_scale_one - 60) + 60)
    }
end

return t1
