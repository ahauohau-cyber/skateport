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
local v1 = import("skate_core/air/trajectory")
local QueryResult, query_trajectory = v1.QueryResult, v1.query_trajectory
local Vector3 = import("skate_core/math").Vector3
local BoardWorld = import("skate_core/physics/board_world").BoardWorld
local v2 = import("skate_core/physics/triangle_query")
local triangle_segment = v2.triangle_segment
local v3 = import("skate_core/player/offboard/contact_toolkit")
local vector4, matches, vec3, lanes, sub, dot, cross, face
local v4 = false
local t1 = {}

function t1.set_reference(p2) -- line: 36
    -- upvalues: v4 (ref)
    local v5 = v4

    v4 = p2

    return v5
end

local v6 = false

function t1.set_b3_reference(p3) -- line: 46
    -- upvalues: v6 (ref)
    v6 = p3
end

local estimate = import("skate_core/physics/reciprocal_sqrt").estimate
local fmin, fmax = rt.fmin, rt.fmax

local function face_xyz(p4, p5, p6) -- line: 57
    -- upvalues: estimate (copy)
    local x, y, z = p4.x, p4.y, p4.z
    local v7 = p5.x - x
    local v8 = p5.y - y
    local v9 = p5.z - z
    local v10 = p6.x - x
    local v11 = p6.y - y
    local v12 = p6.z - z
    local v13 = -v9 * v11 + v8 * v12
    local v14 = -v7 * v12 + v9 * v10
    local v15 = -v8 * v10 + v7 * v11
    local v16 = v13 * v13 + v14 * v14 + v15 * v15
    local v17 = estimate(v16)
    local v18 = v17 * 0.5 * (-v16 * (v17 * v17) + 1) + v17
    local v19 = v18 * 0.5 * (-v16 * (v18 * v18) + 1) + v18

    return {
        v13 * v19,
        v14 * v19,
        v15 * v19,
        0 * v19
    }
end

t1.face_xyz = face_xyz

local self = setmetatable({}, {
    __mode = "k"
})

local function same_number(p7, p8) -- line: 85
    if p7 ~= p8 then
        return false
    end

    if p7 == 0 then
        return 1 / p7 == 1 / p8
    end

    return true
end

local function mesh_frame_of(p9) -- line: 88
    -- upvalues: self (copy)
    local local_to_world = p9.local_to_world
    local columns = local_to_world.basis.columns
    local v21 = columns[1]
    local v22 = columns[2]
    local v23 = columns[3]
    local translation = local_to_world.translation
    local v24 = self[p9]

    if v24 ~= nil then
        local v25 = v24[1]
        local v26 = v24[2]
        local v27 = v24[3]
        local v28 = v24[4]
        local v29 = v25[1]
        local v30 = v21[1]

        if v29 == v30 and (v29 ~= 0 or 1 / v29 == 1 / v30) then
            local v31 = v25[2]
            local v32 = v21[2]

            if v31 == v32 and (v31 ~= 0 or 1 / v31 == 1 / v32) then
                local v33 = v25[3]
                local v34 = v21[3]

                if v33 == v34 and (v33 ~= 0 or 1 / v33 == 1 / v34) then
                    local v35 = v26[1]
                    local v36 = v22[1]

                    if v35 == v36 and (v35 ~= 0 or 1 / v35 == 1 / v36) then
                        local v37 = v26[2]
                        local v38 = v22[2]

                        if v37 == v38 and (v37 ~= 0 or 1 / v37 == 1 / v38) then
                            local v39 = v26[3]
                            local v40 = v22[3]

                            if v39 == v40 and (v39 ~= 0 or 1 / v39 == 1 / v40) then
                                local v41 = v27[1]
                                local v42 = v23[1]

                                if v41 == v42 and (v41 ~= 0 or 1 / v41 == 1 / v42) then
                                    local v43 = v27[2]
                                    local v44 = v23[2]

                                    if v43 == v44 and (v43 ~= 0 or 1 / v43 == 1 / v44) then
                                        local v45 = v27[3]
                                        local v46 = v23[3]

                                        if v45 == v46 and (v45 ~= 0 or 1 / v45 == 1 / v46) then
                                            local v47 = v28[1]
                                            local x = translation.x

                                            if v47 == x and (v47 ~= 0 or 1 / v47 == 1 / x) then
                                                local v48 = v28[2]
                                                local y = translation.y

                                                if v48 == y and (v48 ~= 0 or 1 / v48 == 1 / y) then
                                                    local v49 = v28[3]
                                                    local z = translation.z

                                                    if v49 == z and (v49 ~= 0 or 1 / v49 == 1 / z) then
                                                        return v24
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
        end
    end

    local v50 = table.freeze({
        table.freeze({
            v21[1],
            v21[2],
            v21[3],
            0
        }),
        table.freeze({
            v22[1],
            v22[2],
            v22[3],
            0
        }),
        table.freeze({
            v23[1],
            v23[2],
            v23[3],
            0
        }),
        table.freeze({
            translation.x,
            translation.y,
            translation.z,
            0
        })
    })

    self[p9] = v50

    return v50
end

t1.mesh_frame_of = mesh_frame_of

local function separated_xyz(p10, p11, p12, p13, p14, p15, p16, p17, p18, p19, p20, p21, p22) -- line: 119
    -- upvalues: fmin (copy), fmax (copy)
    local v51 = p10 * p19 + p11 * p20 + p12 * p21
    local v52 = p13 * p19 + p14 * p20 + p15 * p21
    local v53 = p16 * p19 + p17 * p20 + p18 * p21
    local v54 = math.abs(p21) * p22 + (math.abs(p20) * p22 + math.abs(p19) * p22)

    if v54 < fmin(fmin(v51, v52), v53) then
        return true
    end

    return fmax(fmax(v51, v52), v53) < -v54
end

local function box_xyz(p23, p24, p25, p26, p27, p28, p29, p30, p31, p32) -- line: 138
    -- upvalues: separated_xyz (copy)
    local v55 = p26 - p23
    local v56 = p27 - p24
    local v57 = p28 - p25
    local v58 = p29 - p26
    local v59 = p30 - p27
    local v60 = p31 - p28
    local v61 = p23 - p29
    local v62 = p24 - p30
    local v63 = p25 - p31

    for i = 1, 3 do
        local v64, v65, v66

        if i == 1 then
            v64 = v57
            v66 = v55
            v65 = v56
        elseif i == 2 then
            v64 = v60
            v66 = v58
            v65 = v59
        else
            v64 = v63
            v66 = v61
            v65 = v62
        end

        if separated_xyz(p23, p24, p25, p26, p27, p28, p29, p30, p31, -v64 * 0 + v65 * 0, -v66 * 0 + v64 * 1, -v65 * 1 + v66 * 0, p32) or separated_xyz(p23, p24, p25, p26, p27, p28, p29, p30, p31, -v64 * 1 + v65 * 0, -v66 * 0 + v64 * 0, -v65 * 0 + v66 * 1, p32) or separated_xyz(p23, p24, p25, p26, p27, p28, p29, p30, p31, -v64 * 0 + v65 * 1, -v66 * 1 + v64 * 0, -v65 * 0 + v66 * 0, p32) then
            return false
        end
    end

    if separated_xyz(p23, p24, p25, p26, p27, p28, p29, p30, p31, 1, 0, 0, p32) or separated_xyz(p23, p24, p25, p26, p27, p28, p29, p30, p31, 0, 1, 0, p32) or separated_xyz(p23, p24, p25, p26, p27, p28, p29, p30, p31, 0, 0, 1, p32) then
        return false
    end

    return not separated_xyz(p23, p24, p25, p26, p27, p28, p29, p30, p31, -v57 * v59 + v56 * v60, -v55 * v60 + v57 * v58, -v56 * v58 + v55 * v59, p32)
end

local function partition_point(p33, p34) -- line: 187
    local v67 = 0
    local v68 = #p33

    while v67 < v68 do
        local v70 = v67 + math.floor((v68 - v67) / 2)

        if p33[v70 + 1] < p34 then
            v67 = v70 + 1
        else
            v68 = v70
        end
    end

    return v67
end

local function candidate_indices(p35, p36, p37, p38) -- line: 201
    -- upvalues: BoardWorld (copy)
    local t4 = {}

    for v71, v72 in BoardWorld.line_candidates(p35, p36, p37, p38) do
        t4[v71] = v72[1]
    end

    return t4
end

t1.StaticScene = {}

function t1.StaticScene.lines(p39, p40, p41) -- line: 217
    -- upvalues: t1 (copy), vec3 (ref), lanes (ref)
    local t5 = {
        n = #p40
    }

    for _, v73 in t1.StaticScene.pools(p39) do
        for i = 1, #p40 do
            local v74 = p40[i]
            local t6 = {
                start = lanes(v74.start),
                ["end"] = lanes(v74["end"]),
                radius = v74.radius
            }
            local v75 = t1.StaticScene.line(p39, v73, t6, p41, 0)

            if v75 ~= nil then
                local v76 = t5[i]

                if v76 == nil or v75.fraction < v76.fraction then
                    t5[i] = {
                        position = vec3(v75.position),
                        face_normal = vec3(v75.normal),
                        fraction = v75.fraction,
                        packed_surface = v75.surface
                    }
                end
            end
        end
    end

    return t5
end

function t1.StaticScene.trajectory(p42, p43, p44, p45) -- line: 249
    -- upvalues: rt (copy), QueryResult (copy), query_trajectory (copy), t1 (copy)
    local v77 = rt.copy(p43.trajectory)
    local duration = v77.duration
    local v78 = not (duration == duration and duration ~= 1e999 and duration ~= (-1e999))
    local v79, v80

    if v78 then
        v80 = v78
    elseif v77.duration <= 0 then
        v80 = true
    else
        local radius = p43.radius

        v79 = radius == radius and radius ~= 1e999 and radius ~= (-1e999)

        local v81 = not v79

        if v81 then
            v80 = v81
        else
            local v82

            if p43.radius <= 0 then
                v80 = true
            else
                local start_error = p43.start_error

                v82 = start_error == start_error and start_error ~= 1e999 and start_error ~= (-1e999)

                local v83 = not v82

                if v83 then
                    v80 = v83
                else
                    local v84

                    if p43.start_error <= 0 then
                        v80 = true
                    else
                        local end_error = p43.end_error

                        v84 = end_error == end_error and end_error ~= 1e999 and end_error ~= (-1e999)
                        v80 = not v84 or p43.end_error <= 0
                    end
                end
            end
        end
    end

    if not v80 then
        local v85 = v80

        for _, v86 in {
                v77.position,
                v77.velocity,
                v77.acceleration
            } do
            for _, v87 in v86 do
                if v87 ~= v87 or v87 == 1e999 or v87 == (-1e999) then
                    v85 = true
                    break
                end
            end

            if v85 then
                v80 = v85
                break
            end

            v80 = v85
        end
    end

    if v80 then
        error("Invalid offboard accelerated-trajectory request", 0)
    end

    local v88 = QueryResult.miss()

    for _, v89 in t1.StaticScene.pools(p42) do
        local v93 = query_trajectory(rt.copy(p43), function(p46, p47, p48) -- line: 278
            -- upvalues: p42 (copy), p44 (copy), p45 (copy), v89 (copy), t1 (copy)
            local v92 = t1.StaticScene.line(p42, v89, {
                start = p46,
                ["end"] = p47,
                radius = p48
            }, p44, p45)

            return if v92 ~= nil then {
                position = v92.position,
                normal = v92.normal,
                transform = v92.mesh_frame,
                surface = v92.surface,
                geometry = v92.geometry
            } else nil
        end, function(p49, p50) -- line: 296
            -- upvalues: p42 (copy), p44 (copy), v89 (copy), t1 (copy)
            return t1.StaticScene.nearby(p42, v89, p49, p50, p44)
        end)

        if QueryResult.valid(v93) and (not QueryResult.valid(v88) or v93.contact_time < v88.contact_time) then
            v88 = v93
        end
    end

    return v88
end

function t1.StaticScene.new(p51) -- line: 310
    -- upvalues: BoardWorld (copy)
    return {
        world = p51,
        metadata = BoardWorld.query_metadata(p51)
    }
end

function t1.StaticScene.pools(p52) -- line: 316
    local t7 = {
        "Ground",
        "Island"
    }

    if p52.metadata.island_flags == 3 then
        table.insert(t7, "Conditional")
    end

    return t7
end

local function line_reference(p53, p54, p55, p56, p57) -- line: 327
    -- upvalues: rt (copy), Vector3 (copy), BoardWorld (copy), triangle_segment (copy), vector4 (ref), matches (ref), vec3 (ref), lanes (ref), sub (ref), face (ref), partition_point (copy)
    local radius = p55.radius
    local v94 = not (radius == radius and radius ~= 1e999 and radius ~= (-1e999)) or p55.radius < 0
    local v95 = v94

    if not v94 then
        local v96 = p55.start[1]

        if v96 == v96 and v96 ~= 1e999 and v96 ~= (-1e999) then
            local v97 = p55.start[2]

            if v97 == v97 and v97 ~= 1e999 and v97 ~= (-1e999) then
                local v98 = p55.start[3]

                if v98 ~= v98 or v98 == 1e999 or v98 == (-1e999) then
                    v95 = true
                end
            else
                v95 = true
            end
        else
            v95 = true
        end
    end

    local v99 = v95

    if not v95 then
        local v100 = p55["end"][1]

        if v100 == v100 and v100 ~= 1e999 and v100 ~= (-1e999) then
            local v101 = p55["end"][2]

            if v101 == v101 and v101 ~= 1e999 and v101 ~= (-1e999) then
                local v102 = p55["end"][3]

                if v102 ~= v102 or v102 == 1e999 or v102 == (-1e999) then
                    v99 = true
                end
            else
                v99 = true
            end
        else
            v99 = true
        end
    end

    if v99 then
        error("Invalid offboard swept-line request", 0)
    end

    local v103 = sub(p55["end"], p55.start)

    if not (math.abs(v103[1]) > 1.52587890625E-05) and not (math.abs(v103[2]) > 1.52587890625E-05) and not (math.abs(v103[3]) > 1.52587890625E-05) then
        return nil
    end

    local v107 = vec3(p55.start)
    local v108 = vec3(v103)
    local F32_MAX = rt.F32_MAX
    local v109 = BoardWorld.line_candidate_bounds(p53.world, v107, vec3(p55["end"]), p55.radius)
    local world = p53.world
    local v110 = vec3(p55["end"])
    local radius2 = p55.radius
    local t8 = {}

    for v111, v112 in BoardWorld.line_candidates(world, v107, v110, radius2) do
        t8[v111] = v112[1]
    end

    local v113

    for _, v114 in BoardWorld.candidate_mesh_indices(p53.world, v109) do
        local v115 = p53.metadata.meshes[v114 + 1]

        if v115.pool == p54 and matches(p56, v115.matching_group) and bit32.band(v115.rejection_flags, p57) == 0 then
            for i = partition_point(t8, v115.triangle_range.start), partition_point(t8, v115.triangle_range["end"]) - 1 do
                local v116 = t8[i + 1]
                local v117 = rt.copy(BoardWorld.triangles(p53.world)[v116 + 1].triangle.vertices)
                local t9 = {
                    fraction = 0,
                    position = rt.copy(Vector3.ZERO),
                    normal = rt.copy(Vector3.ZERO),
                    volume_parameter = { 0, 0, 0 }
                }
                local v118 = F32_MAX
                local v119 = v113

                if triangle_segment(t9, v107, v108, v117, p55.radius, 0) then
                    local v120 = if -t9.fraction >= 0 then 0 else t9.fraction

                    v118 = if 1 - v120 >= 0 then v120 else 1

                    if v118 < F32_MAX then
                        local v121 = rt.copy(v115.local_to_world)

                        v119 = {
                            position = lanes(t9.position),
                            normal = face({
                                lanes(v117[1]),
                                lanes(v117[2]),
                                lanes(v117[3])
                            }),
                            fraction = v118,
                            surface = p53.metadata.packed_surfaces[v116 + 1],
                            geometry = v115.geometry,
                            mesh_frame = {
                                vector4(v121.basis.columns[1]),
                                vector4(v121.basis.columns[2]),
                                vector4(v121.basis.columns[3]),
                                lanes(v121.translation)
                            }
                        }
                    else
                        v118 = F32_MAX
                    end
                end

                v113 = v119
                F32_MAX = v118
            end
        end
    end

    if p54 == "Ground" then
        local v122 = BoardWorld.external_line(p53.world, v107, vec3(p55["end"]), p55.radius)

        if v122 ~= nil and v122.hit.geometry.fraction < F32_MAX then
            v113 = {
                position = lanes(v122.hit.geometry.position),
                normal = lanes(v122.hit.geometry.normal),
                fraction = v122.hit.geometry.fraction,
                surface = v122.surface,
                geometry = v122.geometry_id,
                mesh_frame = rt.copy(v122.frame)
            }
        end
    end

    return v113
end

local function nearby_reference(p58, p59, p60, p61, p62) -- line: 437
    -- upvalues: BoardWorld (copy), t1 (copy), matches (ref), vec3 (ref), lanes (ref), partition_point (copy)
    local t10 = {}

    if p59 == "Ground" then
        local v123 = BoardWorld.external_nearby(p58.world, vec3(p60), p61)

        for i = 1, math.min(#v123, 64) do
            local v125 = v123[i]

            t10[i] = {
                lanes(v125[1]),
                lanes(v125[2]),
                lanes(v125[3])
            }
        end
    end

    if not (#t10 >= 64) then
        local v126 = BoardWorld.line_candidate_bounds(p58.world, vec3(p60), vec3(p60), p61)
        local world = p58.world
        local v127 = vec3(p60)
        local v128 = vec3(p60)
        local t11 = {}

        for v129, v130 in BoardWorld.line_candidates(world, v127, v128, p61) do
            t11[v129] = v130[1]
        end

        for _, v131 in BoardWorld.candidate_mesh_indices(p58.world, v126) do
            local v132 = p58.metadata.meshes[v131 + 1]

            if v132.pool == p59 and matches(p62, v132.matching_group) then
                for j = partition_point(t11, v132.triangle_range.start), partition_point(t11, v132.triangle_range["end"]) - 1 do
                    local v133 = t11[j + 1]
                    local vertices = BoardWorld.triangles(p58.world)[v133 + 1].triangle.vertices
                    local t12 = {
                        lanes(vertices[1]),
                        lanes(vertices[2]),
                        lanes(vertices[3])
                    }

                    if t1.triangle_box(t12, p60, p61) then
                        table.insert(t10, t12)

                        if #t10 == 64 then
                            return t10
                        end
                    end
                end
            end
        end
    end

    return t10
end

t1.StaticScene.line_reference = line_reference
t1.StaticScene.nearby_reference = nearby_reference

local thin_triangle, triangle_segment_transient = v2.thin_triangle, v2.triangle_segment_transient
local line_candidate_indices_by_mesh = BoardWorld.line_candidate_indices_by_mesh
local is_finite, F32_MAX = rt.is_finite, rt.F32_MAX
local v134 = Vector3.new(0, 0, 0)
local v135 = Vector3.new(0, 0, 0)
local v136 = Vector3.new(0, 0, 0)
local v137 = Vector3.new(0, 0, 0)
local v138 = Vector3.new(0, 0, 0)
local t13 = {
    0, 0, 0
}
local t14 = {
    fraction = 0,
    position = v137,
    normal = v138,
    volume_parameter = t13
}
local v139 = table.create(256, 0)
local v140 = table.create(64, 0)
local v141 = table.create(65, 0)

local function line_fast(p63, p64, p65, p66, p67) -- line: 539
    -- upvalues: matches (ref), lanes (ref), face (ref), v6 (ref), face_xyz (copy), mesh_frame_of (copy), thin_triangle (copy), triangle_segment_transient (copy), line_candidate_indices_by_mesh (copy), is_finite (copy), F32_MAX (copy), v134 (copy), v135 (copy), v136 (copy), v137 (copy), v138 (copy), t13 (copy), t14 (copy), v139 (copy), v140 (copy), v141 (copy)
    local radius, start, v142 = p65.radius, p65.start, p65["end"]
    local v143 = not is_finite(radius) or radius < 0

    if not (v143 or is_finite(start[1]) and is_finite(start[2]) and is_finite(start[3])) then
        v143 = true
    end

    if not (v143 or is_finite(v142[1]) and is_finite(v142[2]) and is_finite(v142[3])) then
        v143 = true
    end

    if v143 then
        error("Invalid offboard swept-line request", 0)
    end

    local v144 = start[1]
    local v145 = start[2]
    local v146 = start[3]
    local v147 = v142[1]
    local v148 = v142[2]
    local v149 = v142[3]
    local v150 = v147 - v144
    local v151 = v148 - v145
    local v152 = v149 - v146

    if not (math.abs(v150) > 1.52587890625E-05) and not (math.abs(v151) > 1.52587890625E-05) and not (math.abs(v152) > 1.52587890625E-05) then
        return true, nil
    end

    v134.x = v144
    v134.y = v145
    v134.z = v146
    v135.x = v147
    v135.y = v148
    v135.z = v149
    v136.x = v150
    v136.y = v151
    v136.z = v152

    local world = p63.world
    local _, v153 = line_candidate_indices_by_mesh(world, v134, v135, radius, v139, v140, v141)

    if v153 < 0 then
        return false, nil
    end

    local metadata = p63.metadata
    local meshes = metadata.meshes
    local triangles = world.triangles
    local v154 = metadata.island_flags == 3
    local v155 = radius + 0 == 0
    local v156 = F32_MAX
    local n1 = 0
    local v157, v158
    local n2 = 0
    local n3 = 0
    local n4 = 0

    for i = 1, v153 do
        local v159 = v141[i] + 1
        local v160 = v141[i + 1]
        local v161, v162, v163, v164, v165, v166, v167, v168, v169, v170

        if v160 < v159 then
            v162 = v156
            v163 = n1
            v165 = v157
            v166 = v158
            v167 = n2
            v168 = n3
            v169 = n4
            v170 = true
        else
            v161 = meshes[v140[i] + 1]

            local pool = v161.pool

            if p64 ~= nil then
                if pool == p64 then
                    v164 = 1
                    v170 = false
                else
                    v162 = v156
                    v163 = n1
                    v165 = v157
                    v166 = v158
                    v167 = n2
                    v168 = n3
                    v169 = n4
                    v170 = true
                end
            elseif pool == "Ground" then
                v164 = 1
                v170 = false
            elseif pool == "Island" then
                v164 = 2
                v170 = false
            elseif pool == "Conditional" and v154 then
                v164 = 3
                v170 = false
            else
                v162 = v156
                v163 = n1
                v165 = v157
                v166 = v158
                v167 = n2
                v168 = n3
                v169 = n4
                v170 = true
            end
        end

        if not v170 then
            v162 = v156
            v163 = n1
            v165 = v157
            v166 = v158
            v167 = n2
            v168 = n3
            v169 = n4

            if matches(p66, v161.matching_group) and bit32.band(v161.rejection_flags, p67) == 0 then
                for j = v159, v160 do
                    local v171 = v139[j]
                    local vertices = triangles[v171 + 1].triangle.vertices
                    local v172

                    if v155 then
                        v172 = thin_triangle(v134, v136, vertices)
                    else
                        v172 = t14
                        v137.x = 0
                        v137.y = 0
                        v137.z = 0
                        v138.x = 0
                        v138.y = 0
                        v138.z = 0
                        t13[1] = 0
                        t13[2] = 0
                        t13[3] = 0
                        t14.position = v137
                        t14.normal = v138
                        t14.fraction = 0
                        t14.volume_parameter = t13

                        if not triangle_segment_transient(t14, v134, v136, vertices, radius, 0) then
                            v172 = nil
                        end
                    end

                    local v173 = v162
                    local v174 = v163
                    local v175 = v165
                    local v176 = v166
                    local v177 = v167
                    local v178 = v168
                    local v179 = v169

                    if v172 ~= nil then
                        local fraction = v172.fraction

                        if -fraction >= 0 then
                            fraction = 0
                        end

                        local v180 = if 1 - fraction >= 0 then fraction else 1

                        if v180 < v162 or v180 == v162 and v164 < v163 then
                            local position = v172.position

                            v173 = v180
                            v174 = v164
                            v175 = v171
                            v176 = v161
                            v177 = position.x
                            v178 = position.y
                            v179 = position.z
                        end
                    end

                    v169 = v179
                    v162 = v173
                    v163 = v174
                    v165 = v175
                    v166 = v176
                    v167 = v177
                    v168 = v178
                end
            end
        end

        n4 = v169
        v156 = v162
        n1 = v163
        v157 = v165
        v158 = v166
        n2 = v167
        n3 = v168
    end

    if v157 == nil then
        return true, nil
    end

    local vertices = triangles[v157 + 1].triangle.vertices
    local local_to_world = v158.local_to_world
    local columns = local_to_world.basis.columns
    local v181 = columns[1]
    local v182 = columns[2]
    local v183 = columns[3]
    local translation = local_to_world.translation

    return true, {
        position = { n2, n3, n4, 0 },
        normal = if v6 then face({
            lanes(vertices[1]),
            lanes(vertices[2]),
            lanes(vertices[3])
        }) else face_xyz(vertices[1], vertices[2], vertices[3]),
        fraction = v156,
        surface = metadata.packed_surfaces[v157 + 1],
        geometry = v158.geometry,
        mesh_frame = if v6 then {
            {
                v181[1],
                v181[2],
                v181[3],
                0
            },
            {
                v182[1],
                v182[2],
                v182[3],
                0
            },
            {
                v183[1],
                v183[2],
                v183[3],
                0
            },
            {
                translation.x,
                translation.y,
                translation.z,
                0
            }
        } else mesh_frame_of(v158)
    }
end

function t1.StaticScene.line(p68, p69, p70, p71, p72) -- line: 673
    -- upvalues: v4 (ref), line_reference (copy), line_fast (copy)
    local v184 = v4

    if not v184 and p68.world.external == nil then
        local v185, v186 = line_fast(p68, p69, p70, p71, p72)

        if v185 then
            return v186
        end
    end

    return (line_reference(p68, p69, p70, p71, p72))
end

function t1.StaticScene.nearby(p73, p74, p75, p76, p77) -- line: 689
    -- upvalues: t1 (copy), matches (ref), lanes (ref), v4 (ref), v6 (ref), box_xyz (copy), nearby_reference (copy), line_candidate_indices_by_mesh (copy), v134 (copy), v139 (copy), v140 (copy), v141 (copy)
    local world = p73.world

    if v4 or world.external ~= nil then
        return (nearby_reference(p73, p74, p75, p76, p77))
    end

    local v187 = p75[1]
    local v188 = p75[2]
    local v189 = p75[3]

    v134.x = v187
    v134.y = v188
    v134.z = v189

    local _, v190 = line_candidate_indices_by_mesh(world, v134, v134, p76, v139, v140, v141)

    if v190 < 0 then
        return (nearby_reference(p73, p74, p75, p76, p77))
    end

    local t16 = {}
    local meshes = p73.metadata.meshes
    local triangles = world.triangles
    local n5 = 0

    for i = 1, v190 do
        local v191 = meshes[v140[i] + 1]

        if v191.pool == p74 and matches(p77, v191.matching_group) then
            for j = v141[i] + 1, v141[i + 1] do
                local vertices = triangles[v139[j] + 1].triangle.vertices

                if v6 then
                    local t17 = {
                        lanes(vertices[1]),
                        lanes(vertices[2]),
                        lanes(vertices[3])
                    }

                    if t1.triangle_box(t17, p75, p76) then
                        n5 += 1
                        t16[n5] = t17

                        if n5 == 64 then
                            return t16
                        end
                    end
                else
                    local v194 = vertices[1]
                    local v195 = vertices[2]
                    local v196 = vertices[3]
                    local v197 = p75[1]
                    local v198 = p75[2]
                    local v199 = p75[3]

                    if box_xyz(v194.x - v197, v194.y - v198, v194.z - v199, v195.x - v197, v195.y - v198, v195.z - v199, v196.x - v197, v196.y - v198, v196.z - v199, p76) then
                        n5 += 1
                        t16[n5] = {
                            lanes(v194),
                            lanes(v195),
                            lanes(v196)
                        }

                        if n5 == 64 then
                            return t16
                        end
                    end
                end
            end
        end
    end

    return t16
end

local function execute_reference(p78, p79) -- line: 749
    -- upvalues: rt (copy), QueryResult (copy), v3 (copy), t1 (copy)
    local t18 = {
        QueryResult.miss(),
        QueryResult.miss(),
        QueryResult.miss()
    }
    local t19 = {}

    for _, v200 in t1.StaticScene.pools(p78) do
        for i = 1, math.min(#p79.trajectories, 3) do
            local v202 = p79.trajectories[i]
            local v203 = rt.copy(v202.trajectory.position)
            local t20 = {
                v203[1] + v202.trajectory.velocity[1],
                v203[2] + v202.trajectory.velocity[2],
                v203[3] + v202.trajectory.velocity[3],
                v203[4] + v202.trajectory.velocity[4]
            }
            local v204 = v3.query_sweep({
                start = v203,
                ["end"] = t20,
                radius = v202.radius
            }, function(p80) -- line: 768
                -- upvalues: p78 (copy), p79 (copy), v200 (copy), t1 (copy)
                return t1.StaticScene.line(p78, v200, p80, p79.matching_group, p79.mesh_reject_mask)
            end, function(p81, p82) -- line: 770
                -- upvalues: p78 (copy), p79 (copy), v200 (copy), t1 (copy)
                return t1.StaticScene.nearby(p78, v200, p81, p82, p79.matching_group)
            end)
            local v205 = t18[i]

            if QueryResult.valid(v204) and (not QueryResult.valid(v205) or v204.contact_time < v205.contact_time) then
                t18[i] = v204
            end
        end

        for j = 1, #p79.lines do
            local v206 = p79.lines[j]
            local v207 = t1.StaticScene.line(p78, v200, rt.copy(v206), p79.matching_group, p79.mesh_reject_mask)

            if v207 ~= nil then
                local v208 = t19[j]

                if v208 == nil or v207.fraction < v208.fraction then
                    t19[j] = v207
                end
            end
        end
    end

    return {
        trajectories = t18,
        lines = t19,
        edges = t1.StaticScene.edges(p78, p79)
    }
end

t1.StaticScene.execute_reference = execute_reference

function t1.StaticScene.execute(p83, p84) -- line: 812
    -- upvalues: rt (copy), QueryResult (copy), v3 (copy), t1 (copy), v4 (ref), line_reference (copy), line_fast (copy), execute_reference (copy)
    if v4 or p83.world.external ~= nil then
        return (execute_reference(p83, p84))
    end

    local t22 = {
        QueryResult.miss(),
        QueryResult.miss(),
        QueryResult.miss()
    }
    local t23 = {}
    local v209 = t1.StaticScene.pools(p83)
    local matching_group, mesh_reject_mask = p84.matching_group, p84.mesh_reject_mask

    for v210, v211 in v209 do
        for i = 1, math.min(#p84.trajectories, 3) do
            local v213 = p84.trajectories[i]
            local v214 = rt.copy(v213.trajectory.position)
            local t24 = {
                v214[1] + v213.trajectory.velocity[1],
                v214[2] + v213.trajectory.velocity[2],
                v214[3] + v213.trajectory.velocity[3],
                v214[4] + v213.trajectory.velocity[4]
            }
            local v215 = v3.query_sweep({
                start = v214,
                ["end"] = t24,
                radius = v213.radius
            }, function(p85) -- line: 836
                -- upvalues: p83 (copy), matching_group (copy), mesh_reject_mask (copy), v211 (copy), t1 (copy)
                return t1.StaticScene.line(p83, v211, p85, matching_group, mesh_reject_mask)
            end, function(p86, p87) -- line: 838
                -- upvalues: p83 (copy), matching_group (copy), v211 (copy), t1 (copy)
                return t1.StaticScene.nearby(p83, v211, p86, p87, matching_group)
            end)
            local v216 = t22[i]

            if QueryResult.valid(v215) and (not QueryResult.valid(v216) or v215.contact_time < v216.contact_time) then
                t22[i] = v215
            end
        end

        if v210 == 1 then
            local lines = p84.lines

            for j = 1, #lines do
                local v217 = lines[j]
                local v218, v219 = line_fast(p83, nil, v217, matching_group, mesh_reject_mask)

                if not v218 then
                    v219 = nil

                    local v220

                    for _, v221 in v209 do
                        local v222 = line_reference(p83, v221, rt.copy(v217), matching_group, mesh_reject_mask)

                        if v222 ~= nil and (v220 == nil or v222.fraction < v220.fraction) then
                            v220 = v222
                        end

                        v219 = v220
                    end
                end

                if v219 ~= nil then
                    t23[j] = v219
                end
            end
        end
    end

    return {
        trajectories = t22,
        lines = t23,
        edges = t1.StaticScene.edges(p83, p84)
    }
end

function t1.StaticScene.edges(p88, p89) -- line: 878
    -- upvalues: lanes (ref)
    local input = p89.input
    local t26 = {
        input.up[1] * 0.29999998 + (input.forward[1] * 0.89999998 + input.position[1]),
        input.up[2] * 0.29999998 + (input.forward[2] * 0.89999998 + input.position[2]),
        input.up[3] * 0.29999998 + (input.forward[3] * 0.89999998 + input.position[3]),
        input.up[4] * 0.29999998 + (input.forward[4] * 0.89999998 + input.position[4])
    }
    local t27 = {
        math.abs(input.forward[1]) * 0.89999998 + (math.abs(input.up[1]) * 1.1 + math.abs(input.right[1]) * 0.037500001),
        math.abs(input.forward[2]) * 0.89999998 + (math.abs(input.up[2]) * 1.1 + math.abs(input.right[2]) * 0.037500001),
        math.abs(input.forward[3]) * 0.89999998 + (math.abs(input.up[3]) * 1.1 + math.abs(input.right[3]) * 0.037500001),
        math.abs(input.forward[4]) * 0.89999998 + (math.abs(input.up[4]) * 1.1 + math.abs(input.right[4]) * 0.037500001)
    }
    local t28 = {}

    for _, v246 in p88.metadata.static_edges do
        local v247 = lanes(v246.local_bounds.min)
        local v248 = lanes(v246.local_bounds.max)
        local v249 = true

        for i = 1, 3 do
            if not (t26[i] - t27[i] <= v248[i] and v247[i] <= t26[i] + t27[i]) then
                v249 = false
                break
            end
        end

        if v249 then
            table.insert(t28, {
                lanes(v246.start),
                lanes(v246["end"])
            })

            if #t28 == 40 then
                break
            end
        end
    end

    return t28
end

function t1.vector4(p90) -- line: 915
    return {
        p90[1],
        p90[2],
        p90[3],
        0
    }
end

function t1.matches(p91, p92) -- line: 920
    if p91 == -1 or p92 == -1 then
        return true
    end

    return p91 == p92
end

function t1.vec3(p93) -- line: 925
    -- upvalues: Vector3 (copy)
    return Vector3.new(p93[1], p93[2], p93[3])
end

function t1.lanes(p94) -- line: 930
    return {
        p94.x,
        p94.y,
        p94.z,
        0
    }
end

function t1.sub(p95, p96) -- line: 935
    return {
        p95[1] - p96[1],
        p95[2] - p96[2],
        p95[3] - p96[3],
        p95[4] - p96[4]
    }
end

function t1.dot(p97, p98) -- line: 940
    return p97[1] * p98[1] + p97[2] * p98[2] + p97[3] * p98[3]
end

function t1.cross(p99, p100) -- line: 945
    return {
        -p99[3] * p100[2] + p99[2] * p100[3],
        -p99[1] * p100[3] + p99[3] * p100[1],
        -p99[2] * p100[1] + p99[1] * p100[2],
        0
    }
end

function t1.face(p101) -- line: 955
    -- upvalues: v3 (copy)
    local v250 = p101[1]
    local v251 = p101[2]
    local v252 = p101[3]

    return v3.triangle_normal({ v250, v251, v252 })
end

function t1.triangle_box(p102, p103, p104) -- line: 964
    -- upvalues: t1 (copy), v6 (ref), box_xyz (copy)
    if v6 then
        return t1.triangle_box_reference(p102, p103, p104)
    end

    local v253 = p102[1]
    local v254 = p102[2]
    local v255 = p102[3]
    local v256 = p103[1]
    local v257 = p103[2]
    local v258 = p103[3]

    return (box_xyz(v253[1] - v256, v253[2] - v257, v253[3] - v258, v254[1] - v256, v254[2] - v257, v254[3] - v258, v255[1] - v256, v255[2] - v257, v255[3] - v258, p104))
end

function t1.triangle_box_reference(p105, p106, p107) -- line: 978
    -- upvalues: rt (copy), sub (ref), dot (ref), cross (ref)
    local t30 = {
        sub(p105[1], p106),
        sub(p105[2], p106),
        sub(p105[3], p106)
    }
    local t31 = {
        sub(t30[2], t30[1]),
        sub(t30[3], t30[2]),
        sub(t30[1], t30[3])
    }
    local t32 = {
        { 1, 0, 0, 0 },
        { 0, 1, 0, 0 },
        { 0, 0, 1, 0 }
    }

    local function separated(p108) -- line: 982
        -- upvalues: p107 (copy), t30 (copy), rt (copy), dot (ref)
        local t33 = {
            dot(t30[1], p108),
            dot(t30[2], p108),
            dot(t30[3], p108)
        }
        local v264 = math.abs(p108[3]) * p107 + (math.abs(p108[2]) * p107 + math.abs(p108[1]) * p107)

        if v264 < rt.fmin(rt.fmin(t33[1], t33[2]), t33[3]) then
            return true
        end

        return rt.fmax(rt.fmax(t33[1], t33[2]), t33[3]) < -v264
    end

    for _, v265 in t31 do
        for _, v266 in t32 do
            if separated(cross(v265, v266)) then
                return false
            end
        end
    end

    for _, v267 in t32 do
        if separated(v267) then
            return false
        end
    end

    return not separated(cross(t31[1], t31[2]))
end

vector4 = t1.vector4
matches = t1.matches
vec3 = t1.vec3
lanes = t1.lanes
sub = t1.sub
dot = t1.dot
cross = t1.cross
face = t1.face

return t1
