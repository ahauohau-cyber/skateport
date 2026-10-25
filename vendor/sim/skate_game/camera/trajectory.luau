-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local TrajectoryQuery = import("skate_core/camera").TrajectoryQuery
local v1 = import("skate_game/camera/world_query")
local PERF = import("skate_core/camera/tracker").PERF
local world_line
local t1 = {}

t1.TrajectoryResult = {}

function t1.TrajectoryResult.new() -- line: 22
    return {
        ready = false,
        time = -1,
        error = nil
    }
end

t1.CameraTrajectory = {}

function t1.CameraTrajectory.submit_reference(p1, p2, _, p4) -- line: 36
    -- upvalues: rt (copy), TrajectoryQuery (copy), world_line (ref)
    p1.result.ready = false
    p1.result.error = nil

    local t2 = {
        start_error = 1,
        end_error = 1,
        position = rt.copy(p2.position),
        velocity = rt.copy(p2.velocity),
        gravity = if p4 == 0 then { 0, 0, 0, 0 } else rt.copy(p1.gravity),
        duration = p2.horizon,
        radius = p2.radius
    }
    local collision_time = TrajectoryQuery.collision_time

    local function v2(p5, p6, p7) -- line: 49
        -- upvalues: p1 (copy), world_line (ref)
        return world_line(p1.world, p5, p6, p7)
    end

    local ok, result = pcall(collision_time, t2, v2)

    if ok then
        p1.result.time = result
        p1.result.ready = true
    else
        p1.result.error = result
    end
end

local v3 = table.freeze({ 0, 0, 0, 0 })
local world
local t3 = {
    fraction = 0,
    hit = 0,
    surface = 0,
    position = { 0, 0, 0, 0 },
    normal = { 0, 0, 0, 0 }
}
local t4 = {
    duration = 0,
    radius = 0,
    start_error = 1,
    end_error = 1,
    position = v3,
    velocity = v3,
    gravity = v3
}

local function scratch_line(p8, p9, p10) -- line: 87
    -- upvalues: v1 (copy), world (ref), t3 (copy)
    local v4 = v1.line_into(t3, world, p8, p9, p10)

    return if v4.hit ~= 0 then v4.position else nil
end

function t1.CameraTrajectory.submit(p11, p12, p13, p14) -- line: 95
    -- upvalues: TrajectoryQuery (copy), PERF (copy), t1 (copy), v3 (copy), world (ref), t4 (copy), scratch_line (copy)
    if PERF.reference then
        return t1.CameraTrajectory.submit_reference(p11, p12, p13, p14)
    end

    local result = p11.result

    result.ready = false
    result.error = nil
    t4.position = p12.position
    t4.velocity = p12.velocity
    t4.gravity = if p14 == 0 then v3 else p11.gravity
    t4.duration = p12.horizon
    t4.radius = p12.radius
    world = p11.world

    local collision_time_transient = TrajectoryQuery.collision_time_transient
    local ok, result2 = pcall(collision_time_transient, t4, scratch_line)

    world = nil
    t4.position = v3
    t4.velocity = v3
    t4.gravity = v3

    if ok then
        result.time = result2
        result.ready = true
    else
        result.error = result2
    end
end

function t1.CameraTrajectory.is_ready(p15) -- line: 121
    return p15.result.ready
end

function t1.CameraTrajectory.collision_time(p16) -- line: 126
    return p16.result.time
end

function t1.world_line(p17, p18, p19, p20) -- line: 132
    -- upvalues: v1 (copy)
    local v6 = v1.line(p17, p18, p19, p20)

    return if v6.hit ~= 0 then v6.position else nil
end

world_line = t1.world_line

return t1
