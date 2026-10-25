-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local SceneService = import("skate_game/physics/offboard/ground_sync").SceneService
local Vector3 = import("skate_core/math").Vector3
local v1 = import("skate_core/player/offboard/ground_query")
local Collections = import("skate_data/collections").Collections
local t1 = {
    State = {}
}

function t1.State.load(p1) -- line: 25
    -- upvalues: Collections (copy)
    return {
        pending = nil,
        collision_offset = Collections.float(p1, "physics_grinds", "default", "DeckCenterToTruck")
    }
end

function t1.State.reset(p2) -- line: 34
    p2.pending = nil
end

function t1.State.consume(p3, p4) -- line: 39
    -- upvalues: v1 (copy)
    local pending = p3.pending

    p3.pending = nil

    local v2 = if pending == nil then nil else v1.interpret_hits(pending[1], pending[2])

    return v1.consume_geometry(p4, v2)
end

function t1.State.submit(p5, p6, p7, p8, p9, p10, p11) -- line: 53
    -- upvalues: SceneService (copy), v1 (copy), t1 (copy)
    local v3 = t1.query_frame(p8)
    local v4 = v1.edge_search(v3, p10, t1.xyz(p9), p11)
    local t2 = {
        world = p6,
        vehicles = p7
    }
    local v5 = SceneService.edge_candidates(t2, v4)
    local v6 = v1.select_edge(v4, v5)
    local v7 = if v6 == nil then nil else v1.prepare_packet(v3, p10, v6, p5.collision_offset)

    if v7 ~= nil then
        p5.pending = {
            v7,
            (SceneService.query_lines(t2, v7))
        }
    end
end

function t1.query_frame(p12) -- line: 74
    -- upvalues: t1 (copy)
    return {
        right = t1.xyz(p12[1]),
        up = t1.xyz(p12[2]),
        forward = t1.xyz(p12[3]),
        position = t1.xyz(p12[4])
    }
end

function t1.xyz(p13) -- line: 84
    -- upvalues: Vector3 (copy)
    return Vector3.new(p13[1], p13[2], p13[3])
end

function t1.lanes(p14) -- line: 89
    return {
        p14.x,
        p14.y,
        p14.z,
        0
    }
end

function t1.native_frame(p15) -- line: 94
    -- upvalues: t1 (copy)
    return {
        t1.lanes(p15.right),
        t1.lanes(p15.up),
        t1.lanes(p15.forward),
        t1.lanes(p15.position)
    }
end

return t1
