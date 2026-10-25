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
local Vector3 = import("skate_core/math").Vector3
local BoardWorld = import("skate_core/physics/board_world").BoardWorld
local triangle_segment = import("skate_core/physics/triangle_query").triangle_segment

local function grab_scene() -- line: 22
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/grab_scene")
end

local t1 = {}

local function partition_point(p2, p3) -- line: 29
    local v1 = 0
    local v2 = #p2

    while v1 < v2 do
        local v4 = v1 + math.floor((v2 - v1) / 2)

        if p2[v4 + 1] < p3 then
            v1 = v4 + 1
        else
            v2 = v4
        end
    end

    return v1
end

function t1.line(p4, p5) -- line: 44
    -- upvalues: rt (copy), import (copy), Vector3 (copy), BoardWorld (copy), triangle_segment (copy), t1 (copy), partition_point (copy)
    local v5

    if p5.radius < 0 then
        v5 = true
    else
        local radius = p5.radius

        v5 = not (radius == radius and radius ~= 1e999 and radius ~= (-1e999))
    end

    if not v5 then
        local v6 = v5

        for _, v7 in {
                p5.start,
                p5["end"]
            } do
            for _, v8 in v7 do
                if v8 ~= v8 or v8 == 1e999 or v8 == (-1e999) then
                    v6 = true
                    break
                end
            end

            if v6 then
                v5 = v6
                break
            end

            v5 = v6
        end
    end

    if v5 then
        error("Invalid grab validation swept line", 0)
    end

    local v9 = rt.from_fn(4, function(p6) -- line: 63
        -- upvalues: p5 (copy)
        return p5["end"][p6 + 1] - p5.start[p6 + 1]
    end)

    if not (math.abs(v9[1]) > 1.52587890625E-05) and not (math.abs(v9[2]) > 1.52587890625E-05) and not (math.abs(v9[3]) > 1.52587890625E-05) then
        return nil
    end

    local v13 = BoardWorld.query_metadata(p4.world)
    local v14 = BoardWorld.line_candidate_bounds(p4.world, t1.xyz(p5.start), t1.xyz(p5["end"]), p5.radius)
    local v15 = BoardWorld.candidate_mesh_indices(p4.world, v14)
    local t2 = {}

    for v16, v17 in BoardWorld.line_candidates(p4.world, t1.xyz(p5.start), t1.xyz(p5["end"]), p5.radius) do
        t2[v16] = v17[1]
    end

    local v18 = rt.F32_MAX
    local v19

    for _, v20 in {
            { 1, "Ground" },
            { 2, "Island" },
            { 4, "Conditional" }
        } do
        local v21 = v20[1]
        local v22 = v20[2]

        if bit32.band(p5.source_pool_mask, v21) ~= 0 and (v22 ~= "Conditional" or v13.island_flags == 3) then
            local v32 = v18
            local v33 = v19

            for _, v34 in v15 do
                local v35 = v13.meshes[v34 + 1]

                if v35.pool == v22 and bit32.band(v35.rejection_flags, p5.reject_flags) == 0 and (p5.group == -1 or v35.matching_group == -1 or p5.group == v35.matching_group) then
                    for j = partition_point(t2, v35.triangle_range.start), partition_point(t2, v35.triangle_range["end"]) - 1 do
                        local v36 = t2[j + 1]
                        local t4 = {
                            fraction = 0,
                            position = rt.copy(Vector3.ZERO),
                            normal = rt.copy(Vector3.ZERO),
                            volume_parameter = {
                                0, 0, 0
                            }
                        }
                        local v37 = rt.copy(BoardWorld.triangles(p4.world)[v36 + 1].triangle.vertices)
                        local v38 = t1.xyz(p5.start)
                        local v39 = v32
                        local v40 = v33

                        if triangle_segment(t4, v38, t1.xyz(v9), v37, p5.radius, 0) then
                            local fraction = if -t4.fraction >= 0 then 0 else t4.fraction

                            v39 = if 1 - fraction >= 0 then fraction else 1

                            if v39 < v32 then
                                v40 = {
                                    fraction = v39
                                }
                                v40.assembly = import("skate_game/physics/offboard/grab_scene").Registry.assembly(p4.registry, v35.geometry)
                            else
                                v39 = v32
                            end
                        end

                        v33 = v40
                        v32 = v39
                    end
                end

                v19 = v33
                v18 = v32
            end
        end
    end

    return v19
end

function t1.xyz(p7) -- line: 132
    -- upvalues: Vector3 (copy)
    return Vector3.new(p7[1], p7[2], p7[3])
end

return t1
