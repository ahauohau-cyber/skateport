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
local v1 = import("skate_game/physics/offboard/ground_query/transform")
local sub = v1.sub
local Vector3 = import("skate_core/math").Vector3
local triangle_segment = import("skate_core/physics/triangle_query").triangle_segment
local t1 = {}

function t1.query(p2, p3) -- line: 24
    -- upvalues: t1 (copy)
    local t2 = {
        p2.ground_pool,
        p2.island_pool,
        if p2.island_flags == 3 then p2.conditional_pool else {}
    }

    return t1.query_pools(t2, p3)
end

function t1.query_pools(p4, p5) -- line: 36
    -- upvalues: rt (copy), v1 (copy), sub (copy), Vector3 (copy), triangle_segment (copy)
    for _, v3 in p4 do
        for _, v4 in v3 do
            if #v4.triangles ~= #v4.surfaces then
                error("Biped query mesh lacks exact per-triangle packed surfaces", 0)
            end
        end
    end

    local t3 = {}

    for i = 0, #p5.lines - 1 do
        local v5 = p5.lines[i + 1]
        local radius = v5.radius

        if not (radius == radius and radius ~= 1e999 and radius ~= (-1e999)) or v5.radius < 0 then
            error("Invalid Biped line radius", 0)
        end

        local v6 = sub(v5["end"], v5.start)
        local x = v6.x

        if math.abs(x) > 1.52587890625E-05 or math.abs(v6.y) > 1.52587890625E-05 or math.abs(v6.z) > 1.52587890625E-05 then
            local function low(p6, p7) -- line: 55
                -- upvalues: v5 (copy), rt (copy)
                return rt.fmin(p6, p7) - v5.radius
            end

            local function high(p8, p9) -- line: 58
                -- upvalues: v5 (copy), rt (copy)
                return rt.fmax(p8, p9) + v5.radius
            end

            local new = Vector3.new
            local x = v5.start.x
            local x2 = v5["end"].x
            local v8 = rt.fmin(x, x2) - v5.radius
            local y = v5.start.y
            local y2 = v5["end"].y
            local v9 = rt.fmin(y, y2) - v5.radius
            local z = v5.start.z
            local z2 = v5["end"].z
            local t4 = {}

            t4.min = new(v8, v9, rt.fmin(z, z2) - v5.radius)

            local new2 = Vector3.new
            local x3 = v5.start.x
            local x4 = v5["end"].x
            local v10 = rt.fmax(x3, x4) + v5.radius
            local y3 = v5.start.y
            local y4 = v5["end"].y
            local v11 = rt.fmax(y3, y4) + v5.radius
            local z3 = v5.start.z
            local z4 = v5["end"].z

            t4.max = new2(v10, v11, rt.fmax(z3, z4) + v5.radius)

            local v12 = rt.F32_MAX

            for _, v13 in p4 do
                local v14 = v12

                for _, v15 in v13 do
                    if v1.matches(p5.context.matching_id_2952, v15.matching_group) and v1.overlaps(v1.bounds(v15.world_to_local, t4), v15.local_bounds) then
                        for j = 1, math.min(#v15.triangles, #v15.surfaces) do
                            local v18 = v15.triangles[j]
                            local v19 = v15.surfaces[j]
                            local vertices = v18.triangle.vertices
                            local t5 = {
                                v1.point(v15.local_to_world, vertices[1]),
                                v1.point(v15.local_to_world, vertices[2]),
                                v1.point(v15.local_to_world, vertices[3])
                            }
                            local t6 = {
                                fraction = 0,
                                position = rt.copy(Vector3.ZERO),
                                normal = rt.copy(Vector3.ZERO),
                                volume_parameter = { 0, 0, 0 }
                            }
                            local v20 = v14

                            if triangle_segment(t6, v5.start, v6, t5, v5.radius, 0) then
                                local v21 = if -t6.fraction >= 0 then 0 else t6.fraction

                                v20 = if 1 - v21 >= 0 then v21 else 1

                                if v20 < v14 then
                                    t3[i + 1] = {
                                        position = rt.copy(t6.position),
                                        face_normal = v1.face(t5),
                                        fraction = v20,
                                        packed_surface = v19
                                    }
                                else
                                    v20 = v14
                                end
                            end

                            v14 = v20
                        end
                    end

                    v12 = v14
                end
            end
        end
    end

    return t3
end

return t1
