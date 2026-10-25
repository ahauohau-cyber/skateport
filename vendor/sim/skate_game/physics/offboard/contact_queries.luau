-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local Vector3 = import("skate_core/math").Vector3
local BoardWorld = import("skate_core/physics/board_world").BoardWorld
local RetailAffineTransform = import("skate_core/physics/drive_frames").RetailAffineTransform
local v1 = import("skate_core/physics/triangle_query")
local triangle_segment = v1.triangle_segment
local t1 = {}

local function partition_point(p1, p2) -- line: 21
    local v2 = 0
    local v3 = #p1

    while v2 < v3 do
        local v5 = v2 + math.floor((v3 - v2) / 2)

        if p1[v5 + 1] < p2 then
            v2 = v5 + 1
        else
            v3 = v5
        end
    end

    return v2
end

t1.Probe = {}
t1.Hit = {}

function t1.xyz(p3) -- line: 46
    -- upvalues: Vector3 (copy)
    return Vector3.new(p3[1], p3[2], p3[3])
end

function t1.query_reference(p4, p5, p6) -- line: 54
    -- upvalues: rt (copy), Vector3 (copy), BoardWorld (copy), RetailAffineTransform (copy), triangle_segment (copy), t1 (copy), partition_point (copy)
    local v6 = BoardWorld.query_metadata(p4)
    local v7 = t1.xyz(p5.start)
    local v8 = t1.xyz(p5["end"])
    local v9 = Vector3.new(v8.x - v7.x, v8.y - v7.y, v8.z - v7.z)
    local v10 = true

    for _, v11 in v6.meshes do
        if not RetailAffineTransform.eq(v11.local_to_world, RetailAffineTransform.IDENTITY) then
            v10 = false
            break
        end
    end

    local t2 = {}

    if v10 then
        for _, v12 in BoardWorld.line_candidates(p4, v7, v8, p5.radius) do
            table.insert(t2, v12[1])
        end
    else
        for i = 0, #BoardWorld.triangles(p4) - 1 do
            table.insert(t2, i)
        end
    end

    local v14

    for _, v15 in { "Ground", "Island", "Conditional" } do
        if v15 ~= "Conditional" or v6.island_flags == 3 then
            for n = 0, #v6.meshes - 1 do
                local v25 = v6.meshes[n + 1]
                local v26 = v14

                if v25.pool == v15 and (v25.matching_group == -1 or v25.matching_group == rt.to_i32(p6)) then
                    local v27 = partition_point(t2, v25.triangle_range.start)
                    local v28 = partition_point(t2, v25.triangle_range["end"]) - 1

                    v26 = v14

                    for n2 = v27, v28 do
                        local v29 = t2[n2 + 1]
                        local triangle = BoardWorld.triangles(p4)[v29 + 1].triangle
                        local v30 = rt.copy(v25.local_to_world)
                        local translation = v30.translation
                        local columns = v30.basis.columns
                        local t5 = {}

                        for v31, v32 in triangle.vertices do
                            t5[v31] = Vector3.new(columns[3][1] * v32.z + (columns[2][1] * v32.y + (columns[1][1] * v32.x + translation.x)), columns[3][2] * v32.z + (columns[2][2] * v32.y + (columns[1][2] * v32.x + translation.y)), columns[3][3] * v32.z + (columns[2][3] * v32.y + (columns[1][3] * v32.x + translation.z)))
                        end

                        local t6 = {
                            fraction = 0,
                            position = rt.copy(Vector3.ZERO),
                            normal = rt.copy(Vector3.ZERO),
                            volume_parameter = {
                                0, 0, 0
                            }
                        }
                        local v33 = v26

                        if triangle_segment(t6, v7, v9, t5, p5.radius, triangle.fatness) and (v26 == nil or t6.fraction < v26.geometry.fraction) then
                            v33 = {
                                geometry = t6
                            }
                            v33.packed_surface = v6.packed_surfaces[v29 + 1]
                            v33.mesh_index = n
                            v33.support_frame = v30
                        end

                        v26 = v33
                    end
                end

                v14 = v26
            end
        end
    end

    return v14
end

local self = setmetatable({}, {
    __mode = "k"
})
local eq, IDENTITY = RetailAffineTransform.eq, RetailAffineTransform.IDENTITY

local function is_identity(p7) -- line: 157
    -- upvalues: self (copy), eq (copy), IDENTITY (copy)
    local basis, translation = p7.basis, p7.translation
    local v35 = type(basis) == "table" and basis.columns

    if type(v35) ~= "table" or type(translation) ~= "table" then
        return eq(p7, IDENTITY)
    end

    local v36 = v35[1]
    local v37 = v35[2]
    local v38 = v35[3]

    if type(v36) ~= "table" or type(v37) ~= "table" or type(v38) ~= "table" then
        return eq(p7, IDENTITY)
    end

    if v36[1] ~= 1
        or v36[2] ~= 0
        or v36[3] ~= 0
        or v37[1] ~= 0
        or v37[2] ~= 1
        or v37[3] ~= 0
        or v38[1] ~= 0
        or v38[2] ~= 0
        or v38[3] ~= 1
        or translation.x ~= 0
        or translation.y ~= 0
        or translation.z ~= 0 then
        return false
    end

    if self[p7] then
        return true
    end

    local v39 = eq(p7, IDENTITY)

    if not v39 then
        return v39
    end

    self[p7] = true

    return v39
end

local t9 = {
    "Ground",
    "Island",
    "Conditional"
}
local t10 = {}
local triangle_segment_transient = v1.triangle_segment_transient
local line_candidate_indices_by_mesh = BoardWorld.line_candidate_indices_by_mesh
local self2 = setmetatable({}, {
    __mode = "k"
})
local self3 = setmetatable({}, {
    __mode = "k"
})
local v42 = table.freeze({
    x = 0,
    y = 0,
    z = 0
})
local v43 = table.freeze({
    x = 0,
    y = 0,
    z = 0
})
local v44 = table.freeze({ 0, 0, 0 })
local v45 = Vector3.new(0, 0, 0)
local v46 = Vector3.new(0, 0, 0)
local v47 = Vector3.new(0, 0, 0)
local t15 = {
    Vector3.new(0, 0, 0),
    Vector3.new(0, 0, 0),
    Vector3.new(0, 0, 0)
}
local v48 = table.create(256, 0)
local v49 = table.create(64, 0)
local v50 = table.create(65, 0)
local v51 = false

function t1.set_guardrail(p8) -- line: 244
    -- upvalues: v51 (ref)
    local v52 = v51

    v51 = p8

    return v52
end

local function query_fast(p9, p10, p11, p12) -- line: 250
    -- upvalues: rt (copy), is_identity (copy), t9 (copy), triangle_segment_transient (copy), line_candidate_indices_by_mesh (copy), self2 (copy), self3 (copy), v42 (copy), v43 (copy), v44 (copy), v45 (copy), v46 (copy), v47 (copy), t15 (copy), v48 (copy), v49 (copy), v50 (copy)
    local meshes = p10.meshes
    local triangle = #meshes

    if self2[meshes] ~= triangle then
        for i = 1, triangle do
            if not is_identity(meshes[i].local_to_world) then
                return false, nil
            end
        end

        self2[meshes] = triangle
    end

    local v53, v54, v55

    if self3[meshes] ~= triangle then
        v54 = (-1e999)

        for i = 1, triangle do
            local triangle_range = meshes[i].triangle_range

            v53 = triangle_range.start
            v55 = triangle_range["end"]

            if not (v54 <= v53 and v53 <= v55) then
                return false, nil
            end

            v54 = v55
        end

        self3[meshes] = triangle
    end

    v54 = p11.start

    local local_to_world = p11["end"]

    v53 = v54[1]
    v55 = v54[2]

    local v56 = v54[3]
    local v57 = local_to_world[1]
    local v58 = local_to_world[2]
    local radius = local_to_world[3]

    v45.x = v53
    v45.y = v55
    v45.z = v56
    v46.x = v57
    v46.y = v58
    v46.z = radius

    local v59 = v57 - v53
    local v60 = v58 - v55
    local v61 = radius - v56

    v47.x = v59
    v47.y = v60
    v47.z = v61
    radius = p11.radius

    local triangles, v62 = line_candidate_indices_by_mesh(p9, v45, v46, radius, v48, v49, v50)

    if v62 < 0 then
        return false, nil
    end

    if triangles == 0 then
        return true, nil
    end

    triangles = p9.triangles

    local v63 = t15[1]
    local v64 = t15[2]
    local v65 = t15[3]
    local v66 = rt.to_i32(p12)

    v55 = nil
    v56 = nil

    for _, v67 in t9 do
        if v67 == "Conditional" then
            if p10.island_flags == 3 then
                for j = 1, v62 do
                    local v68 = v50[j] + 1
                    local v69 = v50[j + 1]
                    local v70, v71
                    local v72 = v55
                    local v73 = v56

                    if not (v69 < v68) then
                        v70 = v49[j]
                        v71 = meshes[v70 + 1]

                        if v71.pool == v67 and (v71.matching_group == -1 or v71.matching_group == v66) then
                            local_to_world = v71.local_to_world

                            local translation = local_to_world.translation

                            v54 = local_to_world.basis.columns

                            local v74 = v54[1]
                            local v75 = v54[2]
                            local v76 = v54[3]

                            for k = v68, v69 do
                                v54 = v48[k]
                                triangle = triangles[v54 + 1].triangle

                                local vertices = triangle.vertices
                                local v77 = vertices[1]

                                v63.x = v76[1] * v77.z + (v75[1] * v77.y + (v74[1] * v77.x + translation.x))
                                v63.y = v76[2] * v77.z + (v75[2] * v77.y + (v74[2] * v77.x + translation.y))
                                v63.z = v76[3] * v77.z + (v75[3] * v77.y + (v74[3] * v77.x + translation.z))
                                v77 = vertices[2]
                                v64.x = v76[1] * v77.z + (v75[1] * v77.y + (v74[1] * v77.x + translation.x))
                                v64.y = v76[2] * v77.z + (v75[2] * v77.y + (v74[2] * v77.x + translation.y))
                                v64.z = v76[3] * v77.z + (v75[3] * v77.y + (v74[3] * v77.x + translation.z))
                                v77 = vertices[3]
                                v65.x = v76[1] * v77.z + (v75[1] * v77.y + (v74[1] * v77.x + translation.x))
                                v65.y = v76[2] * v77.z + (v75[2] * v77.y + (v74[2] * v77.x + translation.y))
                                v65.z = v76[3] * v77.z + (v75[3] * v77.y + (v74[3] * v77.x + translation.z))

                                if v72 == nil then
                                    v72 = {
                                        fraction = 0,
                                        position = v42,
                                        normal = v43,
                                        volume_parameter = v44
                                    }
                                end

                                if triangle_segment_transient(v72, v45, v47, t15, radius, triangle.fatness) and (v73 == nil or v72.fraction < v73.geometry.fraction) then
                                    if v72.position == v42 then
                                        v72.position = {
                                            x = 0,
                                            y = 0,
                                            z = 0
                                        }
                                    end

                                    if v72.normal == v43 then
                                        v72.normal = {
                                            x = 0,
                                            y = 0,
                                            z = 0
                                        }
                                    end

                                    if v72.volume_parameter == v44 then
                                        v72.volume_parameter = {
                                            0, 0, 0
                                        }
                                    end

                                    v73 = {
                                        geometry = v72
                                    }
                                    v73.packed_surface = p10.packed_surfaces[v54 + 1]
                                    v73.mesh_index = v70
                                    v72 = nil
                                    v73.support_frame = rt.copy(local_to_world)
                                else
                                    v72.position = v42
                                    v72.normal = v43
                                    v72.fraction = 0
                                    v72.volume_parameter = v44
                                end
                            end
                        end
                    end

                    v56 = v73
                    v55 = v72
                end
            end
        else
            for n = 1, v62 do
                local v78 = v50[n] + 1
                local v79 = v50[n + 1]
                local v80 = v55
                local v81 = v56

                if not (v79 < v78) then
                    local v82 = v49[n]
                    local v83 = meshes[v82 + 1]
                    local v84 = v83.pool

                    if v84 == v67 then
                        v84 = v83.matching_group

                        if v84 == -1 then
                            local_to_world = v83.local_to_world

                            local translation = local_to_world.translation

                            v54 = local_to_world.basis.columns
                            v84 = v54[1]

                            local v85 = v54[2]
                            local v86 = v54[3]

                            for n2 = v78, v79 do
                                v54 = v48[n2]
                                triangle = triangles[v54 + 1].triangle

                                local vertices = triangle.vertices
                                local v87 = vertices[1]

                                v63.x = v86[1] * v87.z + (v85[1] * v87.y + (v84[1] * v87.x + translation.x))
                                v63.y = v86[2] * v87.z + (v85[2] * v87.y + (v84[2] * v87.x + translation.y))
                                v63.z = v86[3] * v87.z + (v85[3] * v87.y + (v84[3] * v87.x + translation.z))
                                v87 = vertices[2]
                                v64.x = v86[1] * v87.z + (v85[1] * v87.y + (v84[1] * v87.x + translation.x))
                                v64.y = v86[2] * v87.z + (v85[2] * v87.y + (v84[2] * v87.x + translation.y))
                                v64.z = v86[3] * v87.z + (v85[3] * v87.y + (v84[3] * v87.x + translation.z))
                                v87 = vertices[3]
                                v65.x = v86[1] * v87.z + (v85[1] * v87.y + (v84[1] * v87.x + translation.x))
                                v65.y = v86[2] * v87.z + (v85[2] * v87.y + (v84[2] * v87.x + translation.y))
                                v65.z = v86[3] * v87.z + (v85[3] * v87.y + (v84[3] * v87.x + translation.z))

                                if v80 == nil then
                                    v80 = {
                                        fraction = 0,
                                        position = v42,
                                        normal = v43,
                                        volume_parameter = v44
                                    }
                                end

                                if triangle_segment_transient(v80, v45, v47, t15, radius, triangle.fatness) and (v81 == nil or v80.fraction < v81.geometry.fraction) then
                                    if v80.position == v42 then
                                        v80.position = {
                                            x = 0,
                                            y = 0,
                                            z = 0
                                        }
                                    end

                                    if v80.normal == v43 then
                                        v80.normal = {
                                            x = 0,
                                            y = 0,
                                            z = 0
                                        }
                                    end

                                    if v80.volume_parameter == v44 then
                                        v80.volume_parameter = {
                                            0, 0, 0
                                        }
                                    end

                                    v81 = {
                                        geometry = v80
                                    }
                                    v81.packed_surface = p10.packed_surfaces[v54 + 1]
                                    v81.mesh_index = v82
                                    v80 = nil
                                    v81.support_frame = rt.copy(local_to_world)
                                else
                                    v80.position = v42
                                    v80.normal = v43
                                    v80.fraction = 0
                                    v80.volume_parameter = v44
                                end
                            end
                        else
                            v84 = v83.matching_group

                            if v84 == v66 then
                                local_to_world = v83.local_to_world

                                local translation = local_to_world.translation

                                v54 = local_to_world.basis.columns
                                v84 = v54[1]

                                local v88 = v54[2]
                                local v89 = v54[3]

                                for n3 = v78, v79 do
                                    v54 = v48[n3]
                                    triangle = triangles[v54 + 1].triangle

                                    local vertices = triangle.vertices
                                    local v90 = vertices[1]

                                    v63.x = v89[1] * v90.z + (v88[1] * v90.y + (v84[1] * v90.x + translation.x))
                                    v63.y = v89[2] * v90.z + (v88[2] * v90.y + (v84[2] * v90.x + translation.y))
                                    v63.z = v89[3] * v90.z + (v88[3] * v90.y + (v84[3] * v90.x + translation.z))
                                    v90 = vertices[2]
                                    v64.x = v89[1] * v90.z + (v88[1] * v90.y + (v84[1] * v90.x + translation.x))
                                    v64.y = v89[2] * v90.z + (v88[2] * v90.y + (v84[2] * v90.x + translation.y))
                                    v64.z = v89[3] * v90.z + (v88[3] * v90.y + (v84[3] * v90.x + translation.z))
                                    v90 = vertices[3]
                                    v65.x = v89[1] * v90.z + (v88[1] * v90.y + (v84[1] * v90.x + translation.x))
                                    v65.y = v89[2] * v90.z + (v88[2] * v90.y + (v84[2] * v90.x + translation.y))
                                    v65.z = v89[3] * v90.z + (v88[3] * v90.y + (v84[3] * v90.x + translation.z))

                                    if v80 == nil then
                                        v80 = {
                                            fraction = 0,
                                            position = v42,
                                            normal = v43,
                                            volume_parameter = v44
                                        }
                                    end

                                    if triangle_segment_transient(v80, v45, v47, t15, radius, triangle.fatness) and (v81 == nil or v80.fraction < v81.geometry.fraction) then
                                        if v80.position == v42 then
                                            v80.position = {
                                                x = 0,
                                                y = 0,
                                                z = 0
                                            }
                                        end

                                        if v80.normal == v43 then
                                            v80.normal = {
                                                x = 0,
                                                y = 0,
                                                z = 0
                                            }
                                        end

                                        if v80.volume_parameter == v44 then
                                            v80.volume_parameter = {
                                                0, 0, 0
                                            }
                                        end

                                        v81 = {
                                            geometry = v80
                                        }
                                        v81.packed_surface = p10.packed_surfaces[v54 + 1]
                                        v81.mesh_index = v82
                                        v80 = nil
                                        v81.support_frame = rt.copy(local_to_world)
                                    else
                                        v80.position = v42
                                        v80.normal = v43
                                        v80.fraction = 0
                                        v80.volume_parameter = v44
                                    end
                                end
                            end
                        end
                    end
                end

                v56 = v81
                v55 = v80
            end
        end
    end

    return true, v56
end

function t1.query(p13, p14, p15) -- line: 369
    -- upvalues: rt (copy), Vector3 (copy), BoardWorld (copy), triangle_segment (copy), t1 (copy), partition_point (copy), is_identity (copy), t9 (copy), t10 (copy), v51 (ref), query_fast (copy)
    local v91 = v51
    local v92, v93

    if not v91 then
        v92, v93 = query_fast(p13, BoardWorld.query_metadata(p13), p14, p15)
    end

    if not v91 and v92 then
        return v93
    end

    local v94 = BoardWorld.query_metadata(p13)
    local v95 = t1.xyz(p14.start)
    local v96 = t1.xyz(p14["end"])
    local v97 = Vector3.new(v96.x - v95.x, v96.y - v95.y, v96.z - v95.z)
    local meshes = v94.meshes
    local v98 = #meshes
    local v99 = true

    for i = 1, v98 do
        if not is_identity(meshes[i].local_to_world) then
            v99 = false
            break
        end
    end

    local t16 = {}
    local v100 = BoardWorld.triangles(p13)
    local v101

    if v99 then
        v101 = BoardWorld.line_candidates(p13, v95, v96, p14.radius)

        for v102, v103 in v101 do
            t16[v102] = v103[1]
        end
    else
        for i = 0, #v100 - 1 do
            v101 = nil
            table.insert(t16, i)
        end
    end

    local v104 = #t16

    if v104 == 0 then
        return nil
    end

    local v105 = t16[1]
    local v106 = t16[v104]
    local v107 = v98 - 1
    local n1 = 0

    for i = 0, v107 do
        local triangle_range = meshes[i + 1].triangle_range

        if not (triangle_range["end"] <= v105 or v106 < triangle_range.start) then
            n1 += 1
            t10[n1] = i
        end
    end

    local radius = p14.radius
    local v108

    for _, v109 in t9 do
        if v109 ~= "Conditional" or v94.island_flags == 3 then
            for n = 1, n1 do
                local v123 = t10[n]
                local v124 = meshes[v123 + 1]
                local v125 = v108

                if v124.pool == v109 and (v124.matching_group == -1 or v124.matching_group == rt.to_i32(p15)) then
                    local v126 = partition_point(t16, v124.triangle_range.start)
                    local v127 = partition_point(t16, v124.triangle_range["end"])

                    if not (v127 <= v126) then
                        local local_to_world = v124.local_to_world
                        local translation = local_to_world.translation
                        local columns = local_to_world.basis.columns
                        local v128 = columns[1]
                        local v129 = columns[2]
                        local v130 = columns[3]

                        for n2 = v126, v127 - 1 do
                            local v132 = t16[n2 + 1]
                            local triangle = if v101 == nil then v100[v132 + 1].triangle else v101[n2 + 1][2].triangle
                            local t19 = {}

                            for v133, v134 in triangle.vertices do
                                t19[v133] = Vector3.new(v130[1] * v134.z + (v129[1] * v134.y + (v128[1] * v134.x + translation.x)), v130[2] * v134.z + (v129[2] * v134.y + (v128[2] * v134.x + translation.y)), v130[3] * v134.z + (v129[3] * v134.y + (v128[3] * v134.x + translation.z)))
                            end

                            local t20 = {
                                fraction = 0,
                                position = rt.copy(Vector3.ZERO),
                                normal = rt.copy(Vector3.ZERO),
                                volume_parameter = {
                                    0, 0, 0
                                }
                            }
                            local v135 = v125

                            if triangle_segment(t20, v95, v97, t19, radius, triangle.fatness) and (v125 == nil or t20.fraction < v125.geometry.fraction) then
                                v135 = {
                                    geometry = t20
                                }
                                v135.packed_surface = v94.packed_surfaces[v132 + 1]
                                v135.mesh_index = v123
                                v135.support_frame = rt.copy(local_to_world)
                            end

                            v125 = v135
                        end
                    end
                end

                v108 = v125
            end
        end
    end

    return v108
end

return t1
