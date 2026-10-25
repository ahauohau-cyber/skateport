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
local v1 = import("skate_core/physics/triangle_query")
local _, thin_triangle = v1.triangle_segment_transient, v1.thin_triangle
local PERF = import("skate_core/camera/tracker").PERF
local vector, lanes
local t1 = {}

function t1.line_reference(p2, p3, p4, p5) -- line: 31
    -- upvalues: rt (copy), Vector3 (copy), BoardWorld (copy), v1 (copy), t1 (copy), vector (ref), lanes (ref)
    if not (p5 == p5 and p5 ~= 1e999 and p5 ~= (-1e999)) or p5 < 0 then
        error("Invalid stock camera collision radius", 0)
    end

    local v2 = vector(p3)
    local v3 = Vector3.new(p4[1] - v2.x, p4[2] - v2.y, p4[3] - v2.z)
    local v4 = rt.F32_MAX
    local v5 = t1.no_hit()

    for _, v6 in BoardWorld.line_candidates(p2, v2, vector(p4), p5) do
        local v7 = v6[2]
        local t2 = {
            fraction = 0,
            position = rt.copy(Vector3.ZERO),
            normal = rt.copy(Vector3.ZERO),
            volume_parameter = { 0, 0, 0 }
        }

        if v1.triangle_segment_reference(t2, v2, v3, v7.triangle.vertices, p5, 0) then
            local v8 = if -t2.fraction >= 0 then 0 else t2.fraction

            if not (1 - v8 >= 0) then
                v8 = 1
            end

            if v8 < v4 then
                v4 = v8
                v5 = {
                    hit = 1,
                    position = lanes(t2.position),
                    normal = lanes(v7.triangle.feature.normal),
                    fraction = v8,
                    surface = v7.tag
                }
            end
        end
    end

    local v9 = BoardWorld.external_line(p2, v2, vector(p4), p5)

    if v9 ~= nil then
        local geometry = v9.hit.geometry
        local v10 = rt.clamp(geometry.fraction, 0, 1)

        if v10 < v4 then
            v5 = {
                hit = 1,
                position = lanes(geometry.position),
                normal = lanes(geometry.normal),
                fraction = v10,
                surface = v9.hit.tag
            }
        end
    end

    return v5
end

local v11 = Vector3.new(0, 0, 0)
local v12 = Vector3.new(0, 0, 0)
local t3 = {
    0, 0, 0
}
local t4 = {
    fraction = 0,
    position = v11,
    normal = v12,
    volume_parameter = t3
}
local v13 = Vector3.new(0, 0, 0)
local v14 = Vector3.new(0, 0, 0)
local v15 = Vector3.new(0, 0, 0)
local line_candidate_indices, line_vertices, line_vertices_fill = BoardWorld.line_candidate_indices, BoardWorld.line_vertices, BoardWorld.line_vertices_fill
local sweep_lazy_normal_scratch = import("skate_core/physics/triangle_sweep").sweep_lazy_normal_scratch
local v16 = table.create(256, 0)

function t1.line_into(p6, p7, p8, p9, p10) -- line: 170
    -- upvalues: rt (copy), thin_triangle (copy), t1 (copy), PERF (copy), v11 (copy), v12 (copy), t3 (copy), t4 (copy), v13 (copy), v14 (copy), v15 (copy), line_candidate_indices (copy), line_vertices (copy), line_vertices_fill (copy), sweep_lazy_normal_scratch (copy), v16 (copy)
    if not PERF.reference and p7.external == nil then
        local v17 = p10 == p10 and p10 ~= 1e999 and p10 ~= (-1e999)

        if not v17 or p10 < 0 then
            error("Invalid stock camera collision radius", 0)
        end

        local v18 = p8[1]
        local v19 = p8[2]
        local v20 = p8[3]
        local v21 = p9[1]
        local v22 = p9[2]
        local v23 = p9[3]

        v13.x = v18
        v13.y = v19
        v13.z = v20
        v14.x = v21
        v14.y = v22
        v14.z = v23

        local v24 = v21 - v18
        local v25 = v22 - v19
        local v26 = v23 - v20

        v15.x = v24
        v15.y = v25
        v15.z = v26

        local v27 = rt.F32_MAX
        local v28 = p10 + 0 == 0
        local triangles = p7.triangles
        local v29 = line_vertices(p7)
        local v30 = v21 - v18
        local v31 = v22 - v19
        local v32 = v23 - v20
        local v33 = p10 + 0
        local n1 = -1
        local n2 = 0
        local n3 = 0
        local n4 = 0

        for i = 1, line_candidate_indices(p7, v13, v14, p10, v16) do
            local v35 = v16[i]
            local v36 = if v29 == nil then triangles[v35 + 1].triangle.vertices else v29[v35] or line_vertices_fill(v29, v35)
            local v37, v38, v39, v40, v41

            if v28 then
                local v42 = thin_triangle(v13, v15, v36)

                if v42 ~= nil then
                    local fraction = v42.fraction

                    if -fraction >= 0 then
                        fraction = 0
                    end

                    if not (1 - fraction >= 0) then
                        fraction = 1
                    end

                    if fraction < v27 then
                        local position = v42.position
                        local x, y, z = position.x, position.y, position.z

                        if fraction == 0 then
                            v27 = fraction
                            n1 = v35
                            n2 = x
                            n3 = y
                            n4 = z
                            break
                        end

                        v41 = z
                        v37 = fraction
                        v38 = v35
                        v39 = x
                        v40 = y
                    else
                        v41 = n4
                        v37 = v27
                        v38 = n1
                        v39 = n2
                        v40 = n3
                    end
                else
                    v41 = n4
                    v37 = v27
                    v38 = n1
                    v39 = n2
                    v40 = n3
                end
            else
                local v43 = v36[1]
                local v44 = v36[2]
                local v45 = v36[3]
                local x, y, z = v43.x, v43.y, v43.z
                local v46 = v44.x - x
                local v47 = v44.y - y
                local v48 = v44.z - z
                local v49 = v45.x - x
                local v50 = v45.y - y
                local v51 = v45.z - z
                local v52 = v18 - x
                local v53 = v19 - y
                local v54 = v20 - z
                local v55 = -v32 * v50 + v31 * v51
                local v56 = -v30 * v51 + v32 * v49
                local v57 = -v31 * v49 + v30 * v50
                local v58 = v46 * v55 + v47 * v56 + v48 * v57
                local n5 = 1

                if v58 < 0 then
                    n5 = -1
                    v58 = -v58
                end

                local v59 = (v52 * v55 + v53 * v56 + v54 * v57) * n5
                local v60 = (math.abs(v56) + math.abs(v57) + math.abs(v55)) * v33

                if v59 < -v60 or v60 + v58 < v59 then
                    v41 = n4
                    v37 = v27
                    v38 = n1
                    v39 = n2
                    v40 = n3
                else
                    local v61 = -v48 * v31 + v47 * v32
                    local v62 = -v46 * v32 + v48 * v30
                    local v63 = -v47 * v30 + v46 * v31
                    local v64 = (v52 * v61 + v53 * v62 + v54 * v63) * n5
                    local v65 = (math.abs(v62) + math.abs(v63) + math.abs(v61)) * v33

                    if v64 < -v65 or v65 + v58 < v64 or v64 + v59 > v60 + v65 + v58 then
                        v41 = n4
                        v37 = v27
                        v38 = n1
                        v39 = n2
                        v40 = n3
                    else
                        v11.x = 0
                        v11.y = 0
                        v11.z = 0
                        v12.x = 0
                        v12.y = 0
                        v12.z = 0
                        t3[1] = 0
                        t3[2] = 0
                        t3[3] = 0
                        t4.position = v11
                        t4.normal = v12
                        t4.fraction = 0
                        t4.volume_parameter = t3

                        if sweep_lazy_normal_scratch(t4, v13, v15, v36, v33) then
                            local fraction = t4.fraction

                            if -fraction >= 0 then
                                fraction = 0
                            end

                            if not (1 - fraction >= 0) then
                                fraction = 1
                            end

                            if fraction < v27 then
                                local position, normal = t4.position, t4.normal
                                local x = position.x - normal.x * p10
                                local y = position.y - normal.y * p10
                                local z = position.z - normal.z * p10

                                if fraction == 0 then
                                    v27 = fraction
                                    n1 = v35
                                    n2 = x
                                    n3 = y
                                    n4 = z
                                    break
                                end

                                v41 = z
                                v37 = fraction
                                v38 = v35
                                v39 = x
                                v40 = y
                            else
                                v41 = n4
                                v37 = v27
                                v38 = n1
                                v39 = n2
                                v40 = n3
                            end
                        else
                            v41 = n4
                            v37 = v27
                            v38 = n1
                            v39 = n2
                            v40 = n3
                        end
                    end
                end
            end

            n4 = v41
            v27 = v37
            n1 = v38
            n2 = v39
            n3 = v40
        end

        local v66 = n1 >= 0
        local v67, v68, v69, v70

        if v66 then
            local v71 = triangles[n1 + 1]
            local normal = v71.triangle.feature.normal

            v67 = normal.x
            v68 = normal.y
            v69 = normal.z
            v70 = v71.tag
        else
            v67 = 0
            v68 = 0
            v69 = 0
            v70 = 0
        end

        local position, normal = p6.position, p6.normal

        if v66 then
            position[1] = n2
            position[2] = n3
            position[3] = n4
            position[4] = 0
            normal[1] = v67
            normal[2] = v68
            normal[3] = v69
            normal[4] = 0
            p6.fraction = v27
            p6.hit = 1
            p6.surface = v70
        else
            position[1] = 0
            position[2] = 0
            position[3] = 0
            position[4] = 0
            normal[1] = 0
            normal[2] = 0
            normal[3] = 0
            normal[4] = 0
            p6.fraction = 0
            p6.hit = 0
            p6.surface = 0
        end

        return p6
    end

    local v72 = t1.line_reference(p7, p8, p9, p10)
    local position, normal = p6.position, p6.normal
    local position2, normal2 = v72.position, v72.normal
    local v73 = position2[1]
    local v74 = position2[2]
    local v75 = position2[3]
    local v76 = position2[4]

    position[1] = v73
    position[2] = v74
    position[3] = v75
    position[4] = v76

    local v77 = normal2[1]
    local v78 = normal2[2]
    local v79 = normal2[3]
    local v80 = normal2[4]

    normal[1] = v77
    normal[2] = v78
    normal[3] = v79
    normal[4] = v80
    p6.fraction = v72.fraction
    p6.hit = v72.hit
    p6.surface = v72.surface

    return p6
end

function t1.line(p11, p12, p13, p14) -- line: 304
    -- upvalues: t1 (copy), PERF (copy)
    if PERF.reference then
        return t1.line_reference(p11, p12, p13, p14)
    end

    return t1.line_into({
        fraction = 0,
        hit = 0,
        surface = 0,
        position = { 0, 0, 0, 0 },
        normal = { 0, 0, 0, 0 }
    }, p11, p12, p13, p14)
end

function t1.no_hit() -- line: 318
    return {
        fraction = 0,
        hit = 0,
        surface = 0,
        position = { 0, 0, 0, 0 },
        normal = { 0, 0, 0, 0 }
    }
end

function t1.vector(p15) -- line: 329
    -- upvalues: Vector3 (copy)
    return Vector3.new(p15[1], p15[2], p15[3])
end

vector = t1.vector

function t1.lanes(p16) -- line: 335
    return {
        p16.x,
        p16.y,
        p16.z,
        0
    }
end

lanes = t1.lanes

return t1
