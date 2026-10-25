-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_game/physics/offboard/ground_query/edges")
local v2 = import("skate_game/physics/offboard/ground_query/lines")
local t1 = {
    with_world_scene = import("skate_game/physics/offboard/ground_query/world").with_world_scene,
    Bounds = {},
    Mesh = {},
    Segment = {},
    EdgeBody = {},
    AlternateRecord = {},
    PrimaryEdges = {},
    IndexedEdgeBody = {},
    Scene = {}
}

function t1.Scene.edge_candidates(p1, p2) -- line: 73
    -- upvalues: v1 (copy)
    return v1.candidates(p1, p2)
end

function t1.Scene.query_lines(p3, p4) -- line: 79
    -- upvalues: v2 (copy)
    return v2.query(p3, p4)
end

return t1
