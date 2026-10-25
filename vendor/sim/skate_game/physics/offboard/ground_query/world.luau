-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

local function rtl_is_finite(p1) -- line: 6
    if p1 ~= p1 or p1 == 1e999 then
        return false
    end

    return p1 ~= (-1e999)
end

local import = require(sim.import)
local v1 = import("skate_core/math")
local v2 = import("skate_core/physics/board_world")
local Vector3 = v1.Vector3
local BoardWorld = v2.BoardWorld

local function ground_query() -- line: 22
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/ground_query")
end

local function lines() -- line: 25
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/ground_query/lines")
end

local t1 = {}

local function frame(p2) -- line: 32
    -- upvalues: rt (copy), Vector3 (copy)
    local function v(p3) -- line: 33
        -- upvalues: Vector3 (copy)
        return Vector3.new(p3[1], p3[2], p3[3])
    end

    local v3 = p2.basis.columns[1]
    local t2 = {}

    t2.right = Vector3.new(v3[1], v3[2], v3[3])

    local v4 = p2.basis.columns[2]

    t2.up = Vector3.new(v4[1], v4[2], v4[3])

    local v5 = p2.basis.columns[3]

    t2.forward = Vector3.new(v5[1], v5[2], v5[3])
    t2.position = rt.copy(p2.translation)

    return t2
end

local function borrow_range(p4, p5) -- line: 45
    local start, v6 = p5.start, p5["end"]

    return table.move(p4, start + 1, v6, 1, table.create(v6 - start))
end

t1.WorldScene = {}

function t1.WorldScene.edge_candidates(p6, p7) -- line: 57
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/ground_query").Scene.edge_candidates(p6.edges, p7)
end

function t1.WorldScene.query_lines(p8, p9) -- line: 62
    -- upvalues: rt (copy), import (copy), BoardWorld (copy), frame (copy)
    local v7 = BoardWorld.query_metadata(p8.world)
    local v8 = BoardWorld.triangles(p8.world)
    local t3 = {}

    for _, v9 in ipairs(p9.lines) do
        local radius = v9.radius

        if radius ~= radius or radius == 1e999 or radius == (-1e999) or v9.radius < 0 then
            error("Invalid Biped line radius", 0)
        end

        local v10 = BoardWorld.candidate_mesh_indices(p8.world, BoardWorld.line_candidate_bounds(p8.world, v9.start, v9["end"], v9.radius))

        for _, v11 in ipairs(v10) do
            table.insert(t3, v11)
        end
    end

    table.sort(t3)

    local t4 = {}

    for _, v12 in ipairs(t3) do
        if #t4 == 0 or t4[#t4] ~= v12 then
            table.insert(t4, v12)
        end
    end

    local t5 = {
        {},
        {},
        {}
    }

    for _, v13 in ipairs(t4) do
        local v14 = v7.meshes[v13 + 1]
        local v15 = t5[(if v14.pool == "Ground" then 0 elseif v14.pool == "Island" then 1 else 2) + 1]
        local t6 = {
            local_to_world = frame(v14.local_to_world),
            world_to_local = frame(v14.world_to_local),
            local_bounds = {
                min = rt.copy(v14.local_bounds.min),
                max = rt.copy(v14.local_bounds.max)
            },
            matching_group = v14.matching_group
        }
        local triangle_range = v14.triangle_range
        local start, v16 = triangle_range.start, triangle_range["end"]

        t6.triangles = table.move(v8, start + 1, v16, 1, table.create(v16 - start))

        local packed_surfaces = v7.packed_surfaces
        local triangle_range2 = v14.triangle_range
        local start2, v17 = triangle_range2.start, triangle_range2["end"]

        t6.surfaces = table.move(packed_surfaces, start2 + 1, v17, 1, table.create(v17 - start2))
        table.insert(v15, t6)
    end

    return import("skate_game/physics/offboard/ground_query/lines").query_pools({
        t5[1],
        t5[2],
        if v7.island_flags == 3 then t5[3] else {}
    }, p9)
end

function t1.with_world_scene(p10, p11, p12, p13) -- line: 121
    -- upvalues: rt (copy), BoardWorld (copy)
    local v21 = BoardWorld.query_metadata(p10)
    local v22 = table.create(#v21.static_edges)

    for _, v23 in ipairs(v21.static_edges) do
        table.insert(v22, {
            edge = {
                start = rt.copy(v23.start),
                ["end"] = rt.copy(v23["end"])
            },
            local_bounds = {
                min = rt.copy(v23.local_bounds.min),
                max = rt.copy(v23.local_bounds.max)
            }
        })
    end

    return p13({
        world = p10,
        edges = {
            ground_pool = {},
            island_pool = {},
            conditional_pool = {},
            island_flags = v21.island_flags,
            static_edges = v22,
            primary_edges = p11,
            indexed_edges = p12
        }
    })
end

t1.frame = frame

return t1
