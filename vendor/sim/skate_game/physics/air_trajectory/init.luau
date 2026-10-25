-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/physics/air_trajectory/grind")
local v2 = import("skate_game/physics/air_trajectory/settings")
local v3 = import("skate_game/physics/air_trajectory/world")
local v4 = import("skate_core/air/trajectory")
local TrajectorySelector, query_trajectory = v4.TrajectorySelector, v4.query_trajectory
local t1 = {
    GrindContext = v1.GrindContext,
    AirTrajectoryRuntime = {}
}

function t1.AirTrajectoryRuntime.query(p1, p2) -- line: 30
    -- upvalues: v3 (copy), query_trajectory (copy)
    return query_trajectory(p2, function(p3, p4, p5) -- line: 31
        -- upvalues: p1 (copy), v3 (copy)
        return v3.line(p1, p3, p4, p5)
    end, function(p6, p7) -- line: 33
        -- upvalues: p1 (copy), v3 (copy)
        return v3.nearby(p1, p6, p7)
    end)
end

function t1.AirTrajectoryRuntime.load(p8) -- line: 39
    -- upvalues: v1 (copy), v2 (copy), TrajectorySelector (copy)
    return {
        pending_results = nil,
        grind_world = nil,
        selector = TrajectorySelector.new(),
        settings = v2.load(p8),
        grind_settings = v1.Settings.load(p8),
        nearby_grinds = {}
    }
end

function t1.AirTrajectoryRuntime.launch(p9, p10, p11, p12) -- line: 54
    -- upvalues: TrajectorySelector (copy), t1 (copy)
    local v6 = TrajectorySelector.launch(p9.selector, p10, p11, p9.settings)

    if v6 then
        t1.AirTrajectoryRuntime.submit(p9, p12)
    end

    return v6
end

function t1.AirTrajectoryRuntime.bind_grind_world(p13, p14) -- line: 62
    p13.grind_world = p14
    table.clear(p13.nearby_grinds)
end

function t1.AirTrajectoryRuntime.update(p15, p16, p17, p18) -- line: 68
    -- upvalues: rt (copy), v1 (copy), v3 (copy), TrajectorySelector (copy), t1 (copy)
    local pending_results = p15.pending_results

    p15.pending_results = nil

    if pending_results == nil then
        return TrajectorySelector.update_without_completion(p15.selector)
    end

    local grind_world = p15.grind_world

    if grind_world == nil then
        error("Trajectory static grind provider was not registered", 0)
    end

    local v8 = TrajectorySelector.complete_batch(p15.selector, pending_results, p16, p15.settings, function(p19, p20) -- line: 79
        -- upvalues: p15 (copy), p16 (copy), p17 (copy), p18 (copy), grind_world (copy), rt (copy), v1 (copy)
        return v1.Settings.evaluate(p15.grind_settings, p19, p20, p17, grind_world, p15.nearby_grinds, p16.grind_lock_distance, rt.copy(p18))
    end, function(p21, p22, p23) -- line: 90
        -- upvalues: p17 (copy), v3 (copy)
        return v3.line(p17, p21, p22, p23)
    end)

    if TrajectorySelector.pending(p15.selector) then
        t1.AirTrajectoryRuntime.submit(p15, p17)
    end

    return v8
end

function t1.AirTrajectoryRuntime.submit(p24, p25) -- line: 100
    -- upvalues: rt (copy), TrajectorySelector (copy), t1 (copy)
    local t2 = {}

    for _, v9 in TrajectorySelector.requests(p24.selector) do
        table.insert(t2, t1.AirTrajectoryRuntime.query(p25, rt.copy(v9)))
    end

    p24.pending_results = t2
end

return t1
