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
local Bounds = import("skate_core/physics/board_world/query_metadata").Bounds
local v1 = import("skate_core/physics/triangle_query")
local triangle_segment = v1.triangle_segment
local v2 = false
local t1 = {}

function t1.set_reference(p2) -- line: 27
    -- upvalues: v2 (ref)
    local v3 = v2

    v2 = p2

    return v3
end

local function partition_point(p3, p4) -- line: 34
    -- upvalues: rt (copy)
    local v4 = 0
    local v5 = #p3

    while v4 < v5 do
        local v6 = v4 + rt.idiv(v5 - v4, 2)

        if p3[v6 + 1][1] < p4 then
            v4 = v6 + 1
        else
            v5 = v6
        end
    end

    return v4
end

function t1.surface_probe(p5, p6, p7, p8) -- line: 51
    -- upvalues: rt (copy), t1 (copy)
    if p7 >= 7 then
        error(string.format("Grind surface descriptor %d is outside native batch7", p7), 0)
    end

    return t1.line(p5, rt.to_i32(p6[2]), p8)
end

function t1.force_exit_line(p9, p10, p11) -- line: 60
    -- upvalues: rt (copy), t1 (copy)
    local v7 = t1.line(p9, rt.to_i32(p10[2]), {
        start = rt.copy(p11.start),
        ["end"] = rt.copy(p11["end"]),
        radius = 0
    })

    return if v7 ~= nil then {
        normal = rt.copy(v7.normal)
    } else nil
end

local function line_reference(p12, p13, p14) -- line: 74
    -- upvalues: rt (copy), Vector3 (copy), BoardWorld (copy), Bounds (copy), triangle_segment (copy), t1 (copy), partition_point (copy)
    local v8 = BoardWorld.query_metadata(p12)
    local radius = p14.radius

    if not (radius == radius and radius ~= 1e999 and radius ~= (-1e999)) or p14.radius < 0 then
        error("Invalid grind line radius", 0)
    end

    local v9 = t1.vector(p14.start)
    local v10 = t1.vector(p14["end"])
    local v11 = Bounds.from_points({ v9, v10 })

    if v11 == nil then
        error("Non-finite grind line endpoints", 0)
    end

    local v12 = Bounds.expanded(v11, p14.radius)

    for _, v13 in {
            v12.min.x,
            v12.min.y,
            v12.min.z,
            v12.max.x,
            v12.max.y,
            v12.max.z
        } do
        if v13 ~= v13 or v13 == 1e999 or v13 == (-1e999) then
            error("Grind line bounds overflow", 0)
        end
    end

    local v14 = t1.sub(v10, v9)

    if not (math.abs(v14.x) > 1.52587890625E-05) and not (math.abs(v14.y) > 1.52587890625E-05) and not (math.abs(v14.z) > 1.52587890625E-05) then
        return nil
    end

    local v15 = BoardWorld.candidate_mesh_indices(p12, v12)
    local v16 = BoardWorld.line_candidates(p12, v9, v10, p14.radius)
    local v17 = rt.F32_MAX
    local v18

    for _, v19 in { "Ground", "Island", "Conditional" } do
        if v19 ~= "Conditional" or v8.island_flags == 3 then
            local v30 = v17
            local v31 = v18

            for _, v32 in v15 do
                local v33 = v8.meshes[v32 + 1]

                if v33.pool == v19 and (p13 == -1 or v33.matching_group == -1 or p13 == v33.matching_group) and Bounds.overlaps(v12, v33.local_bounds) then
                    for j = partition_point(v16, v33.triangle_range.start), partition_point(v16, v33.triangle_range["end"]) - 1 do
                        local v34 = v16[j + 1]
                        local v35 = v34[1]
                        local v36 = v34[2]
                        local v37 = rt.copy(v36.triangle.vertices)
                        local v38 = Bounds.from_points(v37)

                        if v38 == nil then
                            error("Non-finite authored grind triangle", 0)
                        end

                        if Bounds.overlaps(v12, v38) then
                            local t3 = {
                                fraction = 0,
                                position = rt.copy(Vector3.ZERO),
                                normal = rt.copy(Vector3.ZERO),
                                volume_parameter = {
                                    0, 0, 0
                                }
                            }

                            if triangle_segment(t3, v9, v14, v37, p14.radius, 0) then
                                local v39 = t1.clamp_fraction(t3.fraction)

                                if v39 < v30 then
                                    v30 = v39
                                    v31 = {
                                        fraction = v39
                                    }
                                    v31.position = t1.packed(t3.position)
                                    v31.normal = t1.packed(t1.face(v37))
                                    v31.packed_surface = v8.packed_surfaces[v35 + 1]
                                end
                            end
                        end
                    end
                end

                v18 = v31
                v17 = v30
            end
        end
    end

    return v18
end

t1.line_reference = line_reference

local thin_triangle, triangle_segment_transient = v1.thin_triangle, v1.triangle_segment_transient
local line_candidate_indices, candidate_mesh_indices_into = BoardWorld.line_candidate_indices, BoardWorld.candidate_mesh_indices_into
local is_finite = rt.is_finite
local t4 = {
    "Ground",
    "Island",
    "Conditional"
}
local v40 = Vector3.new(0, 0, 0)
local v41 = Vector3.new(0, 0, 0)
local v42 = Vector3.new(0, 0, 0)
local v43 = Vector3.new(0, 0, 0)
local v44 = Vector3.new(0, 0, 0)
local t5 = {
    0, 0, 0
}
local t6 = {
    fraction = 0,
    position = v43,
    normal = v44,
    volume_parameter = t5
}
local v45 = table.create(256, 0)
local v46 = table.create(64, 0)

local function partition_count(p15, p16, p17) -- line: 214
    local n1 = 0
    local v47 = p16

    while n1 < v47 do
        local v48 = n1 + (v47 - n1) // 2

        if p15[v48 + 1] < p17 then
            n1 = v48 + 1
        else
            v47 = v48
        end
    end

    return n1
end

function t1.line(p18, p19, p20) -- line: 227
    -- upvalues: rt (copy), BoardWorld (copy), t1 (copy), v2 (ref), line_reference (copy), thin_triangle (copy), triangle_segment_transient (copy), line_candidate_indices (copy), candidate_mesh_indices_into (copy), is_finite (copy), t4 (copy), v40 (copy), v41 (copy), v42 (copy), v43 (copy), v44 (copy), t5 (copy), t6 (copy), v45 (copy), v46 (copy), partition_count (copy)
    local v49, radius, v50

    if v2 then
        v50 = true
    elseif p18.external ~= nil then
        v50 = true
    else
        v49 = BoardWorld.query_metadata(p18)
        radius = p20.radius

        if not is_finite(radius) or radius < 0 then
            error("Invalid grind line radius", 0)
        end

        v50 = false
    end

    if v50 then
        return (line_reference(p18, p19, p20))
    end

    local v51, v52 = p20.start, p20["end"]
    local v53 = v51[1]
    local vertices = v51[2]
    local v54 = v51[3]
    local v55 = v52[1]
    local v56 = v52[2]
    local v57 = v52[3]

    if not (is_finite(v53) and is_finite(vertices) and is_finite(v54) and is_finite(v55) and is_finite(v56) and is_finite(v57)) then
        error("Non-finite grind line endpoints", 0)
    end

    v52 = (if v53 < v55 then v53 else v55) - radius

    local v58 = if vertices < v56 then vertices else v56

    v51 = v58 - radius
    v58 = (if v54 < v57 then v54 else v57) - radius

    local v59 = (if v55 < v53 then v53 else v55) + radius
    local v60 = (if v56 < vertices then vertices else v56) + radius
    local v61 = (if v57 < v54 then v54 else v57) + radius

    if not (is_finite(v52) and is_finite(v51) and is_finite(v58) and is_finite(v59) and is_finite(v60) and is_finite(v61)) then
        error("Grind line bounds overflow", 0)
    end

    local v62 = v55 - v53
    local v63 = v56 - vertices
    local v64 = v57 - v54

    if not (math.abs(v62) > 1.52587890625E-05) and not (math.abs(v63) > 1.52587890625E-05) and not (math.abs(v64) > 1.52587890625E-05) then
        return nil
    end

    local v65 = candidate_mesh_indices_into(p18, v52, v51, v58, v59, v60, v61, v46)

    if v65 < 0 then
        return (line_reference(p18, p19, p20))
    end

    v40.x = v53
    v40.y = vertices
    v40.z = v54
    v41.x = v55
    v41.y = v56
    v41.z = v57
    v42.x = v62
    v42.y = v63
    v42.z = v64

    local v66 = line_candidate_indices(p18, v40, v41, radius, v45)
    local meshes = v49.meshes
    local triangles = p18.triangles
    local v67 = radius + 0 == 0

    v55 = nil
    v56 = rt.F32_MAX

    local v68 = 0
    local v69 = 0
    local v70 = 0

    for _, v71 in t4 do
        if v71 == "Conditional" then
            if v49.island_flags == 3 then
                for i = 1, v65 do
                    v54 = meshes[v46[i] + 1]

                    local v72 = v56
                    local v73 = v55
                    local v74 = v68
                    local v75 = v69
                    local v76 = v70

                    if v54.pool == v71 and (p19 == -1 or v54.matching_group == -1 or p19 == v54.matching_group) then
                        vertices = v54.local_bounds

                        local min, v77 = vertices.min, vertices.max
                        local v78 = min.x

                        if not (v59 < v78) then
                            v78 = v77.x

                            if not (v78 < v52) then
                                v78 = min.y

                                if not (v60 < v78) then
                                    v78 = v77.y

                                    if not (v78 < v51) then
                                        v78 = min.z

                                        if not (v61 < v78) then
                                            v78 = v77.z

                                            if not (v78 < v58) then
                                                v77 = v54.triangle_range

                                                local v79 = partition_count(v45, v66, v77.start)

                                                v78 = partition_count(v45, v66, v77["end"])

                                                for j = v79 + 1, v78 do
                                                    v77 = v45[j]
                                                    vertices = triangles[v77 + 1].triangle.vertices

                                                    local v81 = vertices[1]
                                                    local v82 = vertices[2]
                                                    local v83 = vertices[3]
                                                    local x, y, z = v81.x, v81.y, v81.z
                                                    local x2, y2, z2 = v82.x, v82.y, v82.z
                                                    local x3, y3, z3 = v83.x, v83.y, v83.z

                                                    if not (is_finite(x) and is_finite(y) and is_finite(z) and is_finite(x2) and is_finite(y2) and is_finite(z2) and is_finite(x3) and is_finite(y3) and is_finite(z3)) then
                                                        error("Non-finite authored grind triangle", 0)
                                                    end

                                                    local v84 = if x < x2 then x else x2
                                                    local v85 = if y < y2 then y else y2
                                                    local v86 = if z < z2 then z else z2

                                                    if not (x2 < x) then
                                                        x = x2
                                                    end

                                                    if not (y2 < y) then
                                                        y = y2
                                                    end

                                                    if not (z2 < z) then
                                                        z = z2
                                                    end

                                                    if not (v84 < x3) then
                                                        v84 = x3
                                                    end

                                                    if not (v85 < y3) then
                                                        v85 = y3
                                                    end

                                                    if not (v86 < z3) then
                                                        v86 = z3
                                                    end

                                                    if not (x3 < x) then
                                                        x = x3
                                                    end

                                                    if not (y3 < y) then
                                                        y = y3
                                                    end

                                                    if not (z3 < z) then
                                                        z = z3
                                                    end

                                                    local v87 = v72
                                                    local x4 = v74
                                                    local y4 = v75
                                                    local z4 = v76
                                                    local v88 = v73

                                                    if not (v59 < v84) and not (x < v52) and not (v60 < v85) and not (y < v51) and not (v61 < v86) and not (z < v58) then
                                                        local v89

                                                        if v67 then
                                                            v89 = thin_triangle(v40, v42, vertices)
                                                        else
                                                            v89 = t6
                                                            v43.x = 0
                                                            v43.y = 0
                                                            v43.z = 0
                                                            v44.x = 0
                                                            v44.y = 0
                                                            v44.z = 0
                                                            t5[1] = 0
                                                            t5[2] = 0
                                                            t5[3] = 0
                                                            t6.position = v43
                                                            t6.normal = v44
                                                            t6.fraction = 0
                                                            t6.volume_parameter = t5

                                                            if not triangle_segment_transient(t6, v40, v42, vertices, radius, 0) then
                                                                v89 = nil
                                                            end
                                                        end

                                                        if v89 ~= nil then
                                                            local fraction = v89.fraction

                                                            if -fraction >= 0 then
                                                                fraction = 0
                                                            end

                                                            v87 = if 1 - fraction >= 0 then fraction else 1

                                                            if v87 < v72 then
                                                                v88 = v77

                                                                local position = v89.position

                                                                x4 = position.x
                                                                y4 = position.y
                                                                z4 = position.z
                                                            else
                                                                v87 = v72
                                                            end
                                                        end
                                                    end

                                                    v76 = z4
                                                    v73 = v88
                                                    v72 = v87
                                                    v74 = x4
                                                    v75 = y4
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end

                    v70 = v76
                    v55 = v73
                    v56 = v72
                    v68 = v74
                    v69 = v75
                end
            end
        else
            for k = 1, v65 do
                v54 = meshes[v46[k] + 1]

                local min = v54.pool
                local v90 = v56
                local v91 = v55
                local v92 = v68
                local v93 = v69
                local v94 = v70

                if min == v71 then
                    if p19 == -1 then
                        vertices = v54.local_bounds
                        min = vertices.min

                        local v95 = vertices.max
                        local v96 = min.x

                        if not (v59 < v96) then
                            v96 = v95.x

                            if not (v96 < v52) then
                                v96 = min.y

                                if not (v60 < v96) then
                                    v96 = v95.y

                                    if not (v96 < v51) then
                                        v96 = min.z

                                        if not (v61 < v96) then
                                            v96 = v95.z

                                            if not (v96 < v58) then
                                                v95 = v54.triangle_range

                                                local v97 = partition_count(v45, v66, v95.start)

                                                v96 = partition_count(v45, v66, v95["end"])

                                                for n = v97 + 1, v96 do
                                                    v95 = v45[n]
                                                    vertices = triangles[v95 + 1].triangle.vertices

                                                    local v99 = vertices[1]
                                                    local v100 = vertices[2]
                                                    local v101 = vertices[3]
                                                    local x, y, z = v99.x, v99.y, v99.z
                                                    local x2, y2, z2 = v100.x, v100.y, v100.z
                                                    local x3, y3, z3 = v101.x, v101.y, v101.z

                                                    if not is_finite(x)
                                                        or not is_finite(y)
                                                        or not is_finite(z)
                                                        or not is_finite(x2)
                                                        or not is_finite(y2)
                                                        or not is_finite(z2)
                                                        or not is_finite(x3)
                                                        or not is_finite(y3)
                                                        or not is_finite(z3) then
                                                        error("Non-finite authored grind triangle", 0)
                                                    end

                                                    local v102 = if x < x2 then x else x2
                                                    local v103 = if y < y2 then y else y2
                                                    local v104 = if z < z2 then z else z2

                                                    if not (x2 < x) then
                                                        x = x2
                                                    end

                                                    if not (y2 < y) then
                                                        y = y2
                                                    end

                                                    if not (z2 < z) then
                                                        z = z2
                                                    end

                                                    if not (v102 < x3) then
                                                        v102 = x3
                                                    end

                                                    if not (v103 < y3) then
                                                        v103 = y3
                                                    end

                                                    if not (v104 < z3) then
                                                        v104 = z3
                                                    end

                                                    if not (x3 < x) then
                                                        x = x3
                                                    end

                                                    if not (y3 < y) then
                                                        y = y3
                                                    end

                                                    if not (z3 < z) then
                                                        z = z3
                                                    end

                                                    local v105 = v90
                                                    local x4 = v92
                                                    local y4 = v93
                                                    local z4 = v94
                                                    local v106 = v91

                                                    if not (v59 < v102) and not (x < v52) and not (v60 < v103) and not (y < v51) and not (v61 < v104) and not (z < v58) then
                                                        local v107

                                                        if v67 then
                                                            v107 = thin_triangle(v40, v42, vertices)
                                                        else
                                                            v107 = t6
                                                            v43.x = 0
                                                            v43.y = 0
                                                            v43.z = 0
                                                            v44.x = 0
                                                            v44.y = 0
                                                            v44.z = 0
                                                            t5[1] = 0
                                                            t5[2] = 0
                                                            t5[3] = 0
                                                            t6.position = v43
                                                            t6.normal = v44
                                                            t6.fraction = 0
                                                            t6.volume_parameter = t5

                                                            if not triangle_segment_transient(t6, v40, v42, vertices, radius, 0) then
                                                                v107 = nil
                                                            end
                                                        end

                                                        if v107 ~= nil then
                                                            local fraction = v107.fraction

                                                            if -fraction >= 0 then
                                                                fraction = 0
                                                            end

                                                            v105 = if 1 - fraction >= 0 then fraction else 1

                                                            if v105 < v90 then
                                                                v106 = v95

                                                                local position = v107.position

                                                                x4 = position.x
                                                                y4 = position.y
                                                                z4 = position.z
                                                            else
                                                                v105 = v90
                                                            end
                                                        end
                                                    end

                                                    v94 = z4
                                                    v91 = v106
                                                    v90 = v105
                                                    v92 = x4
                                                    v93 = y4
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    else
                        min = v54.matching_group

                        if min == -1 then
                            vertices = v54.local_bounds
                            min = vertices.min

                            local v108 = vertices.max
                            local v109 = min.x

                            if not (v59 < v109) then
                                v109 = v108.x

                                if not (v109 < v52) then
                                    v109 = min.y

                                    if not (v60 < v109) then
                                        v109 = v108.y

                                        if not (v109 < v51) then
                                            v109 = min.z

                                            if not (v61 < v109) then
                                                v109 = v108.z

                                                if not (v109 < v58) then
                                                    v108 = v54.triangle_range

                                                    local v110 = partition_count(v45, v66, v108.start)

                                                    v109 = partition_count(v45, v66, v108["end"])

                                                    for n2 = v110 + 1, v109 do
                                                        v108 = v45[n2]
                                                        vertices = triangles[v108 + 1].triangle.vertices

                                                        local v112 = vertices[1]
                                                        local v113 = vertices[2]
                                                        local v114 = vertices[3]
                                                        local x, y, z = v112.x, v112.y, v112.z
                                                        local x2, y2, z2 = v113.x, v113.y, v113.z
                                                        local x3, y3, z3 = v114.x, v114.y, v114.z

                                                        if not is_finite(x)
                                                            or not is_finite(y)
                                                            or not is_finite(z)
                                                            or not is_finite(x2)
                                                            or not is_finite(y2)
                                                            or not is_finite(z2)
                                                            or not is_finite(x3)
                                                            or not is_finite(y3)
                                                            or not is_finite(z3) then
                                                            error("Non-finite authored grind triangle", 0)
                                                        end

                                                        local v115 = if x < x2 then x else x2
                                                        local v116 = if y < y2 then y else y2
                                                        local v117 = if z < z2 then z else z2

                                                        if not (x2 < x) then
                                                            x = x2
                                                        end

                                                        if not (y2 < y) then
                                                            y = y2
                                                        end

                                                        if not (z2 < z) then
                                                            z = z2
                                                        end

                                                        if not (v115 < x3) then
                                                            v115 = x3
                                                        end

                                                        if not (v116 < y3) then
                                                            v116 = y3
                                                        end

                                                        if not (v117 < z3) then
                                                            v117 = z3
                                                        end

                                                        if not (x3 < x) then
                                                            x = x3
                                                        end

                                                        if not (y3 < y) then
                                                            y = y3
                                                        end

                                                        if not (z3 < z) then
                                                            z = z3
                                                        end

                                                        local v118 = v90
                                                        local x4 = v92
                                                        local y4 = v93
                                                        local z4 = v94
                                                        local v119 = v91

                                                        if not (v59 < v115) and not (x < v52) and not (v60 < v116) and not (y < v51) and not (v61 < v117) and not (z < v58) then
                                                            local v120

                                                            if v67 then
                                                                v120 = thin_triangle(v40, v42, vertices)
                                                            else
                                                                v120 = t6
                                                                v43.x = 0
                                                                v43.y = 0
                                                                v43.z = 0
                                                                v44.x = 0
                                                                v44.y = 0
                                                                v44.z = 0
                                                                t5[1] = 0
                                                                t5[2] = 0
                                                                t5[3] = 0
                                                                t6.position = v43
                                                                t6.normal = v44
                                                                t6.fraction = 0
                                                                t6.volume_parameter = t5

                                                                if not triangle_segment_transient(t6, v40, v42, vertices, radius, 0) then
                                                                    v120 = nil
                                                                end
                                                            end

                                                            if v120 ~= nil then
                                                                local fraction = v120.fraction

                                                                if -fraction >= 0 then
                                                                    fraction = 0
                                                                end

                                                                v118 = if 1 - fraction >= 0 then fraction else 1

                                                                if v118 < v90 then
                                                                    v119 = v108

                                                                    local position = v120.position

                                                                    x4 = position.x
                                                                    y4 = position.y
                                                                    z4 = position.z
                                                                else
                                                                    v118 = v90
                                                                end
                                                            end
                                                        end

                                                        v94 = z4
                                                        v91 = v119
                                                        v90 = v118
                                                        v92 = x4
                                                        v93 = y4
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        else
                            min = v54.matching_group

                            if p19 == min then
                                vertices = v54.local_bounds
                                min = vertices.min

                                local v121 = vertices.max
                                local v122 = min.x

                                if not (v59 < v122) then
                                    v122 = v121.x

                                    if not (v122 < v52) then
                                        v122 = min.y

                                        if not (v60 < v122) then
                                            v122 = v121.y

                                            if not (v122 < v51) then
                                                v122 = min.z

                                                if not (v61 < v122) then
                                                    v122 = v121.z

                                                    if not (v122 < v58) then
                                                        v121 = v54.triangle_range

                                                        local v123 = partition_count(v45, v66, v121.start)

                                                        v122 = partition_count(v45, v66, v121["end"])

                                                        for n3 = v123 + 1, v122 do
                                                            v121 = v45[n3]
                                                            vertices = triangles[v121 + 1].triangle.vertices

                                                            local v125 = vertices[1]
                                                            local v126 = vertices[2]
                                                            local v127 = vertices[3]
                                                            local x, y, z = v125.x, v125.y, v125.z
                                                            local x2, y2, z2 = v126.x, v126.y, v126.z
                                                            local x3, y3, z3 = v127.x, v127.y, v127.z

                                                            if not is_finite(x)
                                                                or not is_finite(y)
                                                                or not is_finite(z)
                                                                or not is_finite(x2)
                                                                or not is_finite(y2)
                                                                or not is_finite(z2)
                                                                or not is_finite(x3)
                                                                or not is_finite(y3)
                                                                or not is_finite(z3) then
                                                                error("Non-finite authored grind triangle", 0)
                                                            end

                                                            local v128 = if x < x2 then x else x2
                                                            local v129 = if y < y2 then y else y2
                                                            local v130 = if z < z2 then z else z2

                                                            if not (x2 < x) then
                                                                x = x2
                                                            end

                                                            if not (y2 < y) then
                                                                y = y2
                                                            end

                                                            if not (z2 < z) then
                                                                z = z2
                                                            end

                                                            if not (v128 < x3) then
                                                                v128 = x3
                                                            end

                                                            if not (v129 < y3) then
                                                                v129 = y3
                                                            end

                                                            if not (v130 < z3) then
                                                                v130 = z3
                                                            end

                                                            if not (x3 < x) then
                                                                x = x3
                                                            end

                                                            if not (y3 < y) then
                                                                y = y3
                                                            end

                                                            if not (z3 < z) then
                                                                z = z3
                                                            end

                                                            local v131 = v90
                                                            local x4 = v92
                                                            local y4 = v93
                                                            local z4 = v94
                                                            local v132 = v91

                                                            if not (v59 < v128) and not (x < v52) and not (v60 < v129) and not (y < v51) and not (v61 < v130) and not (z < v58) then
                                                                local v133

                                                                if v67 then
                                                                    v133 = thin_triangle(v40, v42, vertices)
                                                                else
                                                                    v133 = t6
                                                                    v43.x = 0
                                                                    v43.y = 0
                                                                    v43.z = 0
                                                                    v44.x = 0
                                                                    v44.y = 0
                                                                    v44.z = 0
                                                                    t5[1] = 0
                                                                    t5[2] = 0
                                                                    t5[3] = 0
                                                                    t6.position = v43
                                                                    t6.normal = v44
                                                                    t6.fraction = 0
                                                                    t6.volume_parameter = t5

                                                                    if not triangle_segment_transient(t6, v40, v42, vertices, radius, 0) then
                                                                        v133 = nil
                                                                    end
                                                                end

                                                                if v133 ~= nil then
                                                                    local fraction = v133.fraction

                                                                    if -fraction >= 0 then
                                                                        fraction = 0
                                                                    end

                                                                    v131 = if 1 - fraction >= 0 then fraction else 1

                                                                    if v131 < v90 then
                                                                        v132 = v121

                                                                        local position = v133.position

                                                                        x4 = position.x
                                                                        y4 = position.y
                                                                        z4 = position.z
                                                                    else
                                                                        v131 = v90
                                                                    end
                                                                end
                                                            end

                                                            v94 = z4
                                                            v91 = v132
                                                            v90 = v131
                                                            v92 = x4
                                                            v93 = y4
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    end
                end

                v70 = v94
                v55 = v91
                v56 = v90
                v68 = v92
                v69 = v93
            end
        end
    end

    return if v55 ~= nil then {
        fraction = v56,
        position = { v68, v69, v70, 0 },
        normal = t1.packed(t1.face(triangles[v55 + 1].triangle.vertices)),
        packed_surface = v49.packed_surfaces[v55 + 1]
    } else nil
end

function t1.vector(p21) -- line: 397
    -- upvalues: Vector3 (copy)
    return Vector3.new(p21[1], p21[2], p21[3])
end

function t1.packed(p22) -- line: 401
    return {
        p22.x,
        p22.y,
        p22.z,
        0
    }
end

function t1.sub(p23, p24) -- line: 404
    -- upvalues: Vector3 (copy)
    return Vector3.new(p23.x - p24.x, p23.y - p24.y, p23.z - p24.z)
end

function t1.clamp_fraction(p25) -- line: 409
    local v134 = if -p25 >= 0 then 0 else p25

    if 1 - v134 >= 0 then
        return v134
    end

    return 1
end

function t1.face(p26) -- line: 418
    -- upvalues: Vector3 (copy), t1 (copy)
    local v135 = p26[1]
    local v136 = p26[2]
    local v137 = p26[3]
    local v138 = t1.sub(v136, v135)
    local v139 = t1.sub(v137, v135)
    local v140 = Vector3.new(-v138.z * v139.y + v138.y * v139.z, -v138.x * v139.z + v138.z * v139.x, -v138.y * v139.x + v138.x * v139.y)
    local v141 = v140.z * v140.z + (v140.y * v140.y + v140.x * v140.x)
    local v142 = 1 / math.sqrt(v141)
    local v143 = v142 * 0.5 * (-v141 * (v142 * v142) + 1) + v142
    local v144 = v143 * 0.5 * (-v141 * (v143 * v143) + 1) + v143

    return Vector3.new(v140.x * v144, v140.y * v144, v140.z * v144)
end

return t1
