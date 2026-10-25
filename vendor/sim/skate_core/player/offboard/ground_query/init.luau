-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local Vector3 = import("skate_core/math").Vector3
local v1 = import("skate_core/player/offboard/ground_query/consume")
local v2 = import("skate_core/player/offboard/ground_query/geometry")
local v3 = import("skate_core/player/offboard/ground_query/packet")
local t1 = {
    consume_geometry = v1.consume_geometry,
    interpret_hits = v1.interpret_hits,
    closest_point = v2.closest_point,
    edge_search = v2.edge_search,
    select_edge = v2.select_edge,
    prepare_packet = v3.prepare_packet,
    Frame = {}
}

t1.Frame.IDENTITY = {
    right = Vector3.new(1, 0, 0),
    up = Vector3.new(0, 1, 0),
    forward = Vector3.new(0, 0, 1),
    position = rt.copy(Vector3.ZERO)
}
t1.QueryContext = {}
t1.Edge = {}
t1.EdgeSearch = {}
t1.EdgeSelection = {}
t1.Line = {}
t1.GroundQueryPacket = {}
t1.GroundQueryPacket.SOURCE_POOL_MASK = 7
t1.GroundQueryPacket.FACING_FLAGS = 3
t1.GroundQueryPacket.MESH_EXCLUSION_MASK = 0
t1.GroundQueryPacket.MATERIAL_EXCLUSION_MASK = { 0, 0, 0, 0 }
t1.LineHit = {}
t1.GroundGeometry = {}
t1.ConsumeInput = {}
t1.GroundAdjustment = {}
t1.GroundQueryScene = {}

return t1
