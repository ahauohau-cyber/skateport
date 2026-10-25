-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/physics/offboard/ground_query")
local v2 = import("skate_game/physics/offboard/ground_query/world")
local v3 = import("skate_game/physics/offboard/mod_solid_ground")
local BoardWorld = import("skate_core/physics/board_world").BoardWorld
local VehicleEdgeCache = v3.VehicleEdgeCache
local WorldScene = v2.WorldScene
local t1 = {
    SceneService = {}
}

function t1.SceneService.edge_candidates(p1, p2) -- line: 34
    -- upvalues: v1 (copy), VehicleEdgeCache (copy), WorldScene (copy)
    local v4 = VehicleEdgeCache.build(p1.vehicles)
    local v5 = VehicleEdgeCache.vehicles(v4)

    return v1.with_world_scene(p1.world, VehicleEdgeCache.primary_edges(v4, v5), {}, function(p3) -- line: 41
        -- upvalues: p2 (copy), WorldScene (copy)
        return WorldScene.edge_candidates(p3, p2)
    end)
end

function t1.SceneService.query_lines(p4, p5) -- line: 49
    -- upvalues: rt (copy), v1 (copy), BoardWorld (copy), VehicleEdgeCache (copy), WorldScene (copy)
    local v6 = VehicleEdgeCache.build(p4.vehicles)
    local v7 = VehicleEdgeCache.vehicles(v6)
    local v8 = v1.with_world_scene(p4.world, VehicleEdgeCache.primary_edges(v6, v7), {}, function(p6) -- line: 56
        -- upvalues: p5 (copy), WorldScene (copy)
        return WorldScene.query_lines(p6, p5)
    end)

    for i = 0, math.min(#p5.lines, 7) - 1 do
        local v10 = p5.lines[i + 1]
        local v11 = BoardWorld.external_line(p4.world, v10.start, v10["end"], v10.radius)

        if v11 ~= nil then
            local v12 = v8[i + 1]

            if v12 == nil or v11.hit.geometry.fraction < v12.fraction then
                v8[i + 1] = {
                    position = rt.copy(v11.hit.geometry.position),
                    face_normal = rt.copy(v11.hit.geometry.normal),
                    fraction = v11.hit.geometry.fraction,
                    packed_surface = v11.surface
                }
            end
        end
    end

    return v8
end

return t1
