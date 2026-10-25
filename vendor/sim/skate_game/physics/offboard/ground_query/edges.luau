-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/physics/offboard/ground_query/transform")
local Frame = import("skate_core/player/offboard/ground_query").Frame
local t1 = {}

function t1.append(p1, p2, p3, p4) -- line: 16
    -- upvalues: v1 (copy)
    for _, v2 in p2 do
        if #p1 == 40 then
            break
        end

        if v1.overlaps(v1.bounds(p3, v2.local_bounds), p4) then
            table.insert(p1, {
                start = v1.point(p3, v2.edge.start),
                ["end"] = v1.point(p3, v2.edge["end"])
            })
        end
    end
end

function t1.body(p5, p6, p7) -- line: 31
    -- upvalues: v1 (copy), t1 (copy)
    if v1.overlaps(v1.bounds(p6.local_to_world, p6.local_bounds), p7) then
        t1.append(p5, p6.segments, p6.local_to_world, p7)
    end
end

function t1.candidates(p8, p9) -- line: 38
    -- upvalues: rt (copy), v1 (copy), Frame (copy), t1 (copy)
    local t3 = {
        min = rt.copy(p9.min),
        max = rt.copy(p9.max)
    }
    local t4 = {}

    t1.append(t4, p8.static_edges, Frame.IDENTITY, t3)

    local primary_edges = p8.primary_edges

    if primary_edges.tag == "Normal" then
        local v3 = v1.scale(v1.add(t3.min, t3.max), 0.5)

        for _, v4 in {
                primary_edges.dynamic,
                primary_edges.vehicles
            } do
            for _, v5 in v4 do
                local v6 = v1.sub(v5.local_to_world.position, v3)

                if not (v6.z * v6.z + (v6.y * v6.y + v6.x * v6.x) >= 225) then
                    t1.append(t4, v5.segments, v5.local_to_world, t3)

                    if #t4 == 40 then
                        break
                    end
                end
            end
        end
    else
        for _, v7 in primary_edges[1] do
            if v7.enabled then
                local v8 = if bit32.band(p9.context.selection_flags_2948, 2) == 0 then 0 else 1
                local v9 = v7.choices[v8 + 1]

                if v9 ~= nil then
                    local v10 = v9[1]
                    local v11 = v9[2]

                    if v1.matches(p9.context.matching_id_2952, v11) then
                        t1.body(t4, v10, t3)
                    end
                end
            end
        end
    end

    local t5 = {}

    for v12, v13 in p8.indexed_edges do
        t5[v12] = v13
    end

    for i = 2, #t5 do
        local v14 = t5[i]
        local v15 = i - 1

        while v15 >= 1 and t5[v15].id > v14.id do
            t5[v15 + 1] = t5[v15]
            v15 -= 1
        end

        t5[v15 + 1] = v14
    end

    for _, v16 in t5 do
        if not v16.disabled then
            t1.body(t4, v16.body, t3)
        end
    end

    return t4
end

return t1
