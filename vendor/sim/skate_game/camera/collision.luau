-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/camera/world_query")
local PERF = import("skate_core/camera/tracker").PERF
local no_hit
local t1 = {}

t1.CameraCollision = {}

function t1.CameraCollision.query_reference(p1, p2, _) -- line: 31
    -- upvalues: rt (copy), v1 (copy), no_hit (ref)
    local v2 = rt.filled(10, no_hit())

    for i = 0, 9 do
        local v3 = p2[i + 1]

        v2[i + 1] = v1.line(p1.world, v3.start, v3["end"], v3.radius)
    end

    return v2
end

function t1.CameraCollision.query(p4, p5, p6) -- line: 42
    -- upvalues: v1 (copy), PERF (copy), t1 (copy)
    if PERF.reference then
        return t1.CameraCollision.query_reference(p4, p5, p6)
    end

    local v4 = table.create(10)
    local world = p4.world

    for i = 1, 10 do
        local v5 = p5[i]

        v4[i] = v1.line(world, v5.start, v5["end"], v5.radius)
    end

    return v4
end

function t1.CameraCollision.query_into(p7, p8, _, p10) -- line: 59
    -- upvalues: v1 (copy)
    local world = p7.world

    for i = 1, 10 do
        local v6 = p8[i]

        v1.line_into(p10[i], world, v6.start, v6["end"], v6.radius)
    end

    return p10
end

function t1.CameraCollision.new(p11) -- line: 69
    -- upvalues: rt (copy), no_hit (ref)
    return {
        error = nil,
        world = p11,
        results = rt.filled(6, no_hit())
    }
end

function t1.CameraCollision.submit_reference(p12, p13, _) -- line: 79
    -- upvalues: rt (copy), v1 (copy), no_hit (ref)
    p12.results = rt.filled(6, no_hit())

    for i = 0, 5 do
        local v7 = p13[i + 1]
        local line = v1.line
        local world = p12.world
        local start, v8, radius = v7.start, v7["end"], v7.radius
        local ok, result = pcall(line, world, start, v8, radius)

        if ok then
            p12.results[i + 1] = result
        else
            p12.error = result
        end
    end
end

function t1.CameraCollision.submit(p15, p16, p17) -- line: 101
    -- upvalues: v1 (copy), PERF (copy), t1 (copy)
    if PERF.reference then
        return t1.CameraCollision.submit_reference(p15, p16, p17)
    end

    local results, world = p15.results, p15.world

    for i = 1, 6 do
        local v9 = p16[i]
        local v10 = results[i]
        local position, normal = v10.position, v10.normal

        position[1] = 0
        position[2] = 0
        position[3] = 0
        position[4] = 0
        normal[1] = 0
        normal[2] = 0
        normal[3] = 0
        normal[4] = 0
        v10.fraction = 0
        v10.hit = 0
        v10.surface = 0

        local line_into = v1.line_into
        local start, v11, radius = v9.start, v9["end"], v9.radius
        local ok, result = pcall(line_into, v10, world, start, v11, radius)

        if not ok then
            p15.error = result
        end
    end
end

function t1.CameraCollision.results(p18) -- line: 123
    -- upvalues: rt (copy)
    return rt.copy(p18.results)
end

function t1.no_hit() -- line: 129
    return {
        fraction = 0,
        hit = 0,
        surface = 0,
        position = { 0, 0, 0, 0 },
        normal = { 0, 0, 0, 0 }
    }
end

no_hit = t1.no_hit

return t1
