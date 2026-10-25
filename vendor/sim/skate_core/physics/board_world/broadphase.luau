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
local Bounds = import("skate_core/physics/board_world/query_metadata").Bounds
local QueryIndex = import("skate_core/physics/board_world/query_index").QueryIndex
local by_world = import("skate_core/physics/board_world/objects").by_world

local function board_world() -- line: 18
    -- upvalues: import (copy)
    return import("skate_core/physics/board_world")
end

local t1 = {
    THIN_MARGIN = 9.999999747378752E-06,
    BoardWorld = {}
}

local function candidate_ranges_reference(p2, p3) -- line: 39
    -- upvalues: rt (copy), Bounds (copy), QueryIndex (copy)
    local query_metadata = p2.query_metadata

    if query_metadata == nil or p3 == nil or not Bounds.valid(p3) then
        return {
            {
                start = 0,
                ["end"] = #p2.triangles
            }
        }
    end

    local n1 = 1

    for _, v1 in {
            p3.min.x,
            p3.min.y,
            p3.min.z,
            p3.max.x,
            p3.max.y,
            p3.max.z
        } do
        n1 = rt.fmax(n1, (math.abs(v1)))
    end

    local v2 = Bounds.expanded(p3, p2.maximum_fatness + p2.maximum_triangle_margin + n1 * (8 * rt.F32_EPSILON))
    local t2 = {}

    for _, v3 in QueryIndex.query_reference(p2.query_index, v2, query_metadata.meshes) do
        table.insert(t2, rt.copy(query_metadata.meshes[v3 + 1].triangle_range))
    end

    return t2
end

local function line_candidates_reference(p4, p5, p6, p7) -- line: 61
    -- upvalues: t1 (copy), candidate_ranges_reference (copy)
    local v4 = t1.BoardWorld.line_candidate_bounds(p4, p5, p6, p7)
    local t3 = {}
    local v5 = p4.query_metadata == nil or v4 == nil
    local triangles, triangle_bounds = p4.triangles, p4.triangle_bounds
    local x, x2, y, y2, z, z2

    if not v5 then
        x = v4.min.x
        y = v4.min.y
        z = v4.min.z
        x2 = v4.max.x
        y2 = v4.max.y
        z2 = v4.max.z
    end

    for _, v6 in candidate_ranges_reference(p4, v4) do
        for i = v6.start, v6["end"] - 1 do
            if v5 then
                table.insert(t3, {
                    i,
                    triangles[i + 1]
                })
            else
                local v7 = triangle_bounds[i + 1]
                local min, max = v7.min, v7.max

                if not (max.x < x) and not (x2 < min.x) and not (max.y < y) and not (y2 < min.y) and not (max.z < z) and not (z2 < min.z) then
                    table.insert(t3, {
                        i,
                        triangles[i + 1]
                    })
                end
            end
        end
    end

    return t3
end

function t1.BoardWorld.line_candidate_bounds(p8, p9, p10, p11) -- line: 101
    -- upvalues: rt (copy), Bounds (copy), t1 (copy)
    if not (p11 == p11 and p11 ~= 1e999 and p11 ~= (-1e999)) or p11 < 0 then
        return nil
    end

    local v13 = rt.fmax(rt.fmax(math.abs(p10.x - p9.x), (math.abs(p10.y - p9.y))), (math.abs(p10.z - p9.z)))
    local v14 = Bounds.from_points({ p9, p10 })

    if v14 == nil then
        return nil
    end

    return t1.conservative_bounds(v14, p11 + p8.maximum_fatness + p8.maximum_triangle_margin + v13 * t1.THIN_MARGIN)
end

function t1.BoardWorld.candidate_mesh_indices(p12, p13) -- line: 120
    -- upvalues: rt (copy), import (copy), Bounds (copy), QueryIndex (copy), by_world (copy), t1 (copy)
    local v15 = import("skate_core/physics/board_world").BoardWorld.query_metadata(p12)

    if p13 ~= nil and Bounds.valid(p13) then
        return QueryIndex.query(p12.query_index, t1.conservative_bounds(p13, p12.maximum_fatness + p12.maximum_triangle_margin), v15.meshes)
    end

    local v16 = by_world[p12]

    return rt.from_fn(if v16 == nil then #v15.meshes else v16.map_mesh_count, function(p14) -- line: 125
        return p14
    end)
end

t1.BoardWorld.candidate_ranges_reference = candidate_ranges_reference
t1.BoardWorld.line_candidates_reference = line_candidates_reference

local function candidate_ranges_scalar(p15, p16, p17, p18, p19, p20, p21) -- line: 142
    -- upvalues: rt (copy), QueryIndex (copy)
    local query_metadata = p15.query_metadata

    if query_metadata ~= nil and p16 ~= nil and p16 == p16 and p16 ~= 1e999 and p16 ~= (-1e999) and p17 == p17 and p17 ~= 1e999 and p17 ~= (-1e999) and p18 == p18 and p18 ~= 1e999 and p18 ~= (-1e999) and p19 == p19 and p19 ~= 1e999 and p19 ~= (-1e999) and p20 == p20 and p20 ~= 1e999 and p20 ~= (-1e999) and p21 == p21 and p21 ~= 1e999 and p21 ~= (-1e999) and p16 <= p19 and p17 <= p20 and p18 <= p21 then
        local v17 = rt.fmax(1, (math.abs(p16)))
        local v18 = rt.fmax(v17, (math.abs(p17)))
        local v19 = rt.fmax(v18, (math.abs(p18)))
        local v20 = rt.fmax(v19, (math.abs(p19)))
        local v21 = rt.fmax(v20, (math.abs(p20)))
        local v22 = rt.fmax(v21, (math.abs(p21)))
        local v23 = p15.maximum_fatness + p15.maximum_triangle_margin + v22 * (8 * rt.F32_EPSILON)
        local meshes = query_metadata.meshes
        local v24 = QueryIndex.query_scalar(p15.query_index, p16 - v23, p17 - v23, p18 - v23, p19 + v23, p20 + v23, p21 + v23, meshes)
        local v25 = table.create(#v24)

        for v26, v27 in v24 do
            local triangle_range = meshes[v27 + 1].triangle_range

            v25[v26] = {
                start = triangle_range.start,
                ["end"] = triangle_range["end"]
            }
        end

        return v25
    end

    return {
        {
            start = 0,
            ["end"] = #p15.triangles
        }
    }
end

local v28 = table.create(64, 0)

function t1.candidate_ranges_into(p22, p23, p24, p25, p26, p27, p28, p29, p30, p31) -- line: 198
    -- upvalues: rt (copy), QueryIndex (copy), by_world (copy), v28 (copy)
    local query_metadata = p22.query_metadata

    if query_metadata ~= nil and p23 ~= nil and p23 == p23 and p23 ~= 1e999 and p23 ~= (-1e999) and p24 == p24 and p24 ~= 1e999 and p24 ~= (-1e999) and p25 == p25 and p25 ~= 1e999 and p25 ~= (-1e999) and p26 == p26 and p26 ~= 1e999 and p26 ~= (-1e999) and p27 == p27 and p27 ~= 1e999 and p27 ~= (-1e999) and p28 == p28 and p28 ~= 1e999 and p28 ~= (-1e999) and p23 <= p26 and p24 <= p27 and p25 <= p28 then
        local v29 = rt.fmax(1, (math.abs(p23)))
        local v30 = rt.fmax(v29, (math.abs(p24)))
        local v31 = rt.fmax(v30, (math.abs(p25)))
        local v32 = rt.fmax(v31, (math.abs(p26)))
        local v33 = rt.fmax(v32, (math.abs(p27)))
        local v34 = rt.fmax(v33, (math.abs(p28)))
        local v35 = p22.maximum_fatness + p22.maximum_triangle_margin + v34 * (8 * rt.F32_EPSILON)
        local meshes = query_metadata.meshes
        local v36 = QueryIndex.query_scalar_into(p22.query_index, p23 - v35, p24 - v35, p25 - v35, p26 + v35, p27 + v35, p28 + v35, meshes, v28)

        for i = 1, v36 do
            local triangle_range = meshes[v28[i] + 1].triangle_range
            local start, v37 = triangle_range.start, triangle_range["end"]

            p29[i] = start
            p30[i] = v37
        end

        if p31 ~= nil then
            local paged = p22.paged
            local v38 = by_world[p22]
            local v39 = if v38 == nil then v36 else v38.pages_into(v38, v28, v36, p31, paged == nil)

            if paged ~= nil then
                local pages_into = paged.pages_into

                if pages_into ~= nil then
                    pages_into(v28, v39, p31)

                    return v36
                end

                for i = 1, v39 do
                    p31[i] = nil
                end
            end
        end

        return v36
    end

    if p31 ~= nil then
        local paged = p22.paged
        local all_into = if paged == nil then nil else paged.all_into

        if all_into ~= nil then
            return all_into(p29, p30, p31)
        end

        p31[1] = nil
    end

    local v40 = #p22.triangles

    p29[1] = 0
    p30[1] = v40

    return 1
end

local candidate_ranges_into = t1.candidate_ranges_into
local v41 = table.create(16, 0)
local v42 = table.create(16, 0)
local t6 = {}

function t1.BoardWorld.candidate_ranges(p32, p33) -- line: 289
    -- upvalues: candidate_ranges_scalar (copy)
    if p33 == nil then
        return (candidate_ranges_scalar(p32, nil))
    end

    local min, max = p33.min, p33.max

    return (candidate_ranges_scalar(p32, min.x, min.y, min.z, max.x, max.y, max.z))
end

local function line_candidate_bounds_scalar(p34, p35, p36, p37) -- line: 303
    -- upvalues: rt (copy), t1 (copy)
    local x, y, z, x2, y2, z2, v43, v44

    if p37 ~= p37 or p37 == 1e999 or p37 == (-1e999) or p37 < 0 then
        return nil
    else
        x = p35.x
        y = p35.y
        z = p35.z
        x2 = p36.x
        y2 = p36.y
        z2 = p36.z
        v43 = rt.fmax(rt.fmax(math.abs(x2 - x), (math.abs(y2 - y))), (math.abs(z2 - z)))
        v44 = x == x and x ~= 1e999 and x ~= (-1e999)
    end

    if not v44
        or y ~= y
        or y == 1e999
        or y == (-1e999)
        or z ~= z
        or z == 1e999
        or z == (-1e999)
        or x2 ~= x2
        or x2 == 1e999
        or x2 == (-1e999)
        or y2 ~= y2
        or y2 == 1e999
        or y2 == (-1e999)
        or z2 ~= z2
        or z2 == 1e999
        or z2 == (-1e999) then
        return nil
    end

    local v51 = rt.fmin(x, x2)
    local v52 = rt.fmin(y, y2)
    local v53 = rt.fmin(z, z2)
    local v54 = rt.fmax(x, x2)
    local v55 = rt.fmax(y, y2)
    local v56 = rt.fmax(z, z2)
    local v57 = p37 + p34.maximum_fatness + p34.maximum_triangle_margin + v43 * t1.THIN_MARGIN
    local v58 = rt.fmax(1, (math.abs(v51)))
    local v59 = rt.fmax(v58, (math.abs(v52)))
    local v60 = rt.fmax(v59, (math.abs(v53)))
    local v61 = rt.fmax(v60, (math.abs(v54)))
    local v62 = rt.fmax(v61, (math.abs(v55)))
    local v63 = v57 + rt.fmax(v62, (math.abs(v56))) * (8 * rt.F32_EPSILON)

    return v51 - v63, v52 - v63, v53 - v63, v54 + v63, v55 + v63, v56 + v63
end

function t1.flat_triangle_bounds(p38) -- line: 336
    local triangle_bounds_flat = p38.triangle_bounds_flat

    if triangle_bounds_flat == nil then
        local triangle_bounds = p38.triangle_bounds
        local v64 = #triangle_bounds

        triangle_bounds_flat = table.create(v64 * 6)

        for i = 1, v64 do
            local v65 = triangle_bounds[i]
            local min, max = v65.min, v65.max
            local v66 = (i - 1) * 6
            local v67 = v66 + 2
            local v68 = v66 + 3
            local x, y, z = min.x, min.y, min.z

            triangle_bounds_flat[v66 + 1] = x
            triangle_bounds_flat[v67] = y
            triangle_bounds_flat[v68] = z

            local v69 = v66 + 5
            local v70 = v66 + 6
            local x2, y2, z2 = max.x, max.y, max.z

            triangle_bounds_flat[v66 + 4] = x2
            triangle_bounds_flat[v69] = y2
            triangle_bounds_flat[v70] = z2
        end

        p38.triangle_bounds_flat = triangle_bounds_flat
    end

    return triangle_bounds_flat
end

local flat_triangle_bounds2 = t1.flat_triangle_bounds

t1.BLOCK = 8

function t1.triangle_block_bounds(p39) -- line: 370
    -- upvalues: flat_triangle_bounds2 (copy)
    local triangle_block_bounds = p39.triangle_block_bounds

    if triangle_block_bounds == nil then
        local v71 = flat_triangle_bounds2(p39)
        local v72 = #v71 // 6
        local v73 = (v72 + 8 - 1) // 8

        triangle_block_bounds = table.create(v73 * 6, 0)

        for i = 0, v73 - 1 do
            local v74 = math.min(v72, (i + 1) * 8) - 1
            local n2 = 1e999
            local n3 = 1e999
            local n4 = 1e999
            local n5 = (-1e999)
            local n6 = (-1e999)
            local n7 = (-1e999)
            local v75 = false

            for j = i * 8, v74 do
                local v76 = j * 6
                local v77 = v71[v76 + 1]
                local v78 = v71[v76 + 2]
                local v79 = v71[v76 + 3]
                local v80 = v71[v76 + 4]
                local v81 = v71[v76 + 5]
                local v82 = v71[v76 + 6]

                v75 = v77 ~= v77
                    or v78 ~= v78
                    or v79 ~= v79
                    or v80 ~= v80
                    or v81 ~= v81
                    or v82 ~= v82
                    or v75

                if v77 < n2 then
                    n2 = v77
                end

                if v78 < n3 then
                    n3 = v78
                end

                if v79 < n4 then
                    n4 = v79
                end

                if n5 < v80 then
                    n5 = v80
                end

                if n6 < v81 then
                    n6 = v81
                end

                if n7 < v82 then
                    n7 = v82
                end
            end

            if v75 then
                n2 = (-1e999)
                n3 = (-1e999)
                n4 = (-1e999)
                n5 = 1e999
                n6 = 1e999
                n7 = 1e999
            end

            local v83 = i * 6
            local v84 = v83 + 2
            local v85 = v83 + 3

            triangle_block_bounds[v83 + 1] = n2
            triangle_block_bounds[v84] = n3
            triangle_block_bounds[v85] = n4

            local v86 = v83 + 5
            local v87 = v83 + 6

            triangle_block_bounds[v83 + 4] = n5
            triangle_block_bounds[v86] = n6
            triangle_block_bounds[v87] = n7
        end

        p39.triangle_block_bounds = triangle_block_bounds
    end

    return triangle_block_bounds
end

local triangle_block_bounds = t1.triangle_block_bounds

t1.SUPER = 64

function t1.triangle_super_bounds(p40) -- line: 426
    -- upvalues: triangle_block_bounds (copy)
    local triangle_super_bounds = p40.triangle_super_bounds

    if triangle_super_bounds == nil then
        local v88 = triangle_block_bounds(p40)
        local v89 = #v88 // 6
        local v90 = (v89 + 8 - 1) // 8

        triangle_super_bounds = table.create(v90 * 6, 0)

        for i = 0, v90 - 1 do
            local v91 = math.min(v89, (i + 1) * 8) - 1
            local n8 = 1e999
            local n9 = 1e999
            local n10 = 1e999
            local n11 = (-1e999)
            local n12 = (-1e999)
            local n13 = (-1e999)

            for j = i * 8, v91 do
                local v92 = j * 6
                local v93 = v88[v92 + 1]
                local v94 = v88[v92 + 2]
                local v95 = v88[v92 + 3]
                local v96 = v88[v92 + 4]
                local v97 = v88[v92 + 5]
                local v98 = v88[v92 + 6]

                if v93 < n8 then
                    n8 = v93
                end

                if v94 < n9 then
                    n9 = v94
                end

                if v95 < n10 then
                    n10 = v95
                end

                if n11 < v96 then
                    n11 = v96
                end

                if n12 < v97 then
                    n12 = v97
                end

                if n13 < v98 then
                    n13 = v98
                end
            end

            local v99 = i * 6
            local v100 = v99 + 2
            local v101 = v99 + 3

            triangle_super_bounds[v99 + 1] = n8
            triangle_super_bounds[v100] = n9
            triangle_super_bounds[v101] = n10

            local v102 = v99 + 5
            local v103 = v99 + 6

            triangle_super_bounds[v99 + 4] = n11
            triangle_super_bounds[v102] = n12
            triangle_super_bounds[v103] = n13
        end

        p40.triangle_super_bounds = triangle_super_bounds
    end

    return triangle_super_bounds
end

local triangle_super_bounds = t1.triangle_super_bounds
local v104 = true

function t1.set_line_blocks(p41) -- line: 472
    -- upvalues: v104 (ref)
    local v105 = v104

    v104 = p41

    return v105
end

function t1.BoardWorld.line_candidates(p42, p43, p44, p45) -- line: 481
    -- upvalues: by_world (copy), candidate_ranges_scalar (copy), candidate_ranges_into (copy), v41 (copy), v42 (copy), t6 (copy), line_candidate_bounds_scalar (copy), flat_triangle_bounds2 (copy), triangle_block_bounds (copy), triangle_super_bounds (copy), v104 (ref)
    local v106, v107, v108, v109, v110, v111 = line_candidate_bounds_scalar(p42, p43, p44, p45)
    local t7 = {}
    local v112 = p42.query_metadata == nil or v106 == nil
    local triangles = p42.triangles

    if v112 then
        for _, v113 in candidate_ranges_scalar(p42, v106, v107, v108, v109, v110, v111) do
            for i = v113.start, v113["end"] - 1 do
                table.insert(t7, {
                    i,
                    triangles[i + 1]
                })
            end
        end
    else
        local v114 = flat_triangle_bounds2(p42)

        if v104 then
            local v115 = triangle_block_bounds(p42)
            local v116 = triangle_super_bounds(p42)
            local v117 = p42.paged ~= nil or by_world[p42] ~= nil
            local v118 = candidate_ranges_into(p42, v106, v107, v108, v109, v110, v111, v41, v42, t6)
            local v119 = v114
            local v120 = v115
            local v121 = v116
            local n14 = 0

            for i = 1, v118 do
                local v122 = v41[i]
                local v123 = v42[i]
                local v124

                if v117 then
                    local v125 = t6[i]

                    if v125 ~= nil then
                        v119 = v125.flat
                        v120 = v125.blocks
                        v121 = v125.supers
                        v124 = v125.first
                        v122 -= v124
                        v123 -= v124
                    else
                        v119 = v114
                        v120 = v115
                        v121 = v116
                        v124 = 0
                    end
                else
                    v124 = 0
                end

                while v122 < v123 do
                    local v126 = v122 // 64
                    local v127 = (v126 + 1) * 64

                    if v123 < v127 then
                        v127 = v123
                    end

                    local v128 = 6 * v126

                    if not (v121[v128 + 4] < v106
                        or v109 < v121[v128 + 1]
                        or v121[v128 + 5] < v107
                        or v110 < v121[v128 + 2]
                        or v121[v128 + 6] < v108
                        or v111 < v121[v128 + 3]) then
                        while v122 < v127 do
                            local v129 = v122 // 8
                            local v130 = (v129 + 1) * 8

                            if v127 < v130 then
                                v130 = v127
                            end

                            local v131 = 6 * v129

                            if not (v120[v131 + 4] < v106
                                or v109 < v120[v131 + 1]
                                or v120[v131 + 5] < v107
                                or v110 < v120[v131 + 2]
                                or v120[v131 + 6] < v108
                                or v111 < v120[v131 + 3]) then
                                for j = v122, v130 - 1 do
                                    local v132 = j * 6

                                    if not (v119[v132 + 4] < v106
                                        or v109 < v119[v132 + 1]
                                        or v119[v132 + 5] < v107
                                        or v110 < v119[v132 + 2]
                                        or v119[v132 + 6] < v108
                                        or v111 < v119[v132 + 3]) then
                                        n14 += 1
                                        t7[n14] = {
                                            j + v124,
                                            triangles[j + v124 + 1]
                                        }
                                    end
                                end
                            end

                            v122 = v130
                        end
                    end

                    v122 = v127
                end
            end
        else
            for _, v133 in candidate_ranges_scalar(p42, v106, v107, v108, v109, v110, v111) do
                for k = v133.start, v133["end"] - 1 do
                    local v134 = k * 6

                    if not (v114[v134 + 4] < v106) and not (v109 < v114[v134 + 1]) and not (v114[v134 + 5] < v107) and not (v110 < v114[v134 + 2]) and not (v114[v134 + 6] < v108) and not (v111 < v114[v134 + 3]) then
                        table.insert(t7, {
                            k,
                            triangles[k + 1]
                        })
                    end
                end
            end
        end
    end

    return t7
end

function t1.BoardWorld.line_candidate_indices(p46, p47, p48, p49, p50) -- line: 609
    -- upvalues: by_world (copy), candidate_ranges_into (copy), v41 (copy), v42 (copy), t6 (copy), line_candidate_bounds_scalar (copy), flat_triangle_bounds2 (copy), triangle_block_bounds (copy), triangle_super_bounds (copy)
    local v135, v136, v137, v138, v139, v140 = line_candidate_bounds_scalar(p46, p47, p48, p49)
    local v141 = candidate_ranges_into(p46, v135, v136, v137, v138, v139, v140, v41, v42, t6)

    if p46.query_metadata ~= nil and v135 ~= nil then
        local v142 = flat_triangle_bounds2(p46)
        local v143 = triangle_block_bounds(p46)
        local v144 = triangle_super_bounds(p46)
        local v145 = p46.paged ~= nil or by_world[p46] ~= nil
        local n15 = 0
        local v146 = v142
        local v147 = v143
        local v148 = v144

        for i = 1, v141 do
            local v149 = v41[i]
            local v150 = v42[i]
            local v151

            if v145 then
                local v152 = t6[i]

                if v152 ~= nil then
                    v146 = v152.flat
                    v147 = v152.blocks
                    v148 = v152.supers
                    v151 = v152.first
                    v149 -= v151
                    v150 -= v151
                else
                    v146 = v142
                    v147 = v143
                    v148 = v144
                    v151 = 0
                end
            else
                v151 = 0
            end

            while v149 < v150 do
                local v153 = v149 // 64
                local v154 = (v153 + 1) * 64

                if v150 < v154 then
                    v154 = v150
                end

                local v155 = 6 * v153

                if not (v148[v155 + 4] < v135
                    or v138 < v148[v155 + 1]
                    or v148[v155 + 5] < v136
                    or v139 < v148[v155 + 2]
                    or v148[v155 + 6] < v137
                    or v140 < v148[v155 + 3]) then
                    while v149 < v154 do
                        local v156 = v149 // 8
                        local v157 = (v156 + 1) * 8

                        if v154 < v157 then
                            v157 = v154
                        end

                        local v158 = 6 * v156

                        if not (v147[v158 + 4] < v135
                            or v138 < v147[v158 + 1]
                            or v147[v158 + 5] < v136
                            or v139 < v147[v158 + 2]
                            or v147[v158 + 6] < v137
                            or v140 < v147[v158 + 3]) then
                            for j = v149, v157 - 1 do
                                local v159 = j * 6

                                if not (v146[v159 + 4] < v135
                                    or v138 < v146[v159 + 1]
                                    or v146[v159 + 5] < v136
                                    or v139 < v146[v159 + 2]
                                    or v146[v159 + 6] < v137
                                    or v140 < v146[v159 + 3]) then
                                    n15 += 1
                                    p50[n15] = j + v151
                                end
                            end
                        end

                        v149 = v157
                    end
                end

                v149 = v154
            end
        end

        return n15
    end

    local n16 = 0

    for i = 1, v141 do
        for j = v41[i], v42[i] - 1 do
            n16 += 1
            p50[n16] = j
        end
    end

    return n16
end

function t1.BoardWorld.line_candidate_indices_by_mesh(p51, p52, p53, p54, p55, p56, p57) -- line: 732
    -- upvalues: by_world (copy), v28 (copy), candidate_ranges_into (copy), v41 (copy), v42 (copy), t6 (copy), line_candidate_bounds_scalar (copy), flat_triangle_bounds2 (copy), triangle_block_bounds (copy), triangle_super_bounds (copy)
    local v161, v162, v163, v164, v165, v166 = line_candidate_bounds_scalar(p51, p52, p53, p54)

    if p51.query_metadata ~= nil and v161 ~= nil and v161 == v161 and v161 ~= 1e999 and v161 ~= (-1e999) and v162 == v162 and v162 ~= 1e999 and v162 ~= (-1e999) and v163 == v163 and v163 ~= 1e999 and v163 ~= (-1e999) and v164 == v164 and v164 ~= 1e999 and v164 ~= (-1e999) and v165 == v165 and v165 ~= 1e999 and v165 ~= (-1e999) and v166 == v166 and v166 ~= 1e999 and v166 ~= (-1e999) and v161 <= v164 and v162 <= v165 and v163 <= v166 then
        local v167 = candidate_ranges_into(p51, v161, v162, v163, v164, v165, v166, v41, v42, t6)
        local n17 = 0

        for i = 1, v167 do
            local v168 = v41[i]

            if v168 < n17 or v42[i] < v168 then
                return 0, -1
            end

            n17 = v42[i]
            p56[i] = v28[i]
        end

        local v169 = flat_triangle_bounds2(p51)
        local v170 = triangle_block_bounds(p51)
        local v171 = triangle_super_bounds(p51)
        local v172 = p51.paged ~= nil or by_world[p51] ~= nil
        local v173 = v170
        local v174 = v169
        local v175 = v171
        local n18 = 0

        for i = 1, v167 do
            p57[i] = n18

            local v176 = v41[i]
            local v177 = v42[i]
            local v178

            if v172 then
                local v179 = t6[i]

                if v179 ~= nil then
                    v174 = v179.flat
                    v173 = v179.blocks
                    v175 = v179.supers
                    v178 = v179.first
                    v176 -= v178
                    v177 -= v178
                else
                    v173 = v170
                    v174 = v169
                    v175 = v171
                    v178 = 0
                end
            else
                v178 = 0
            end

            while v176 < v177 do
                local v180 = v176 // 64
                local v181 = (v180 + 1) * 64

                if v177 < v181 then
                    v181 = v177
                end

                local v182 = 6 * v180

                if not (v175[v182 + 4] < v161
                    or v164 < v175[v182 + 1]
                    or v175[v182 + 5] < v162
                    or v165 < v175[v182 + 2]
                    or v175[v182 + 6] < v163
                    or v166 < v175[v182 + 3]) then
                    while v176 < v181 do
                        local v183 = v176 // 8
                        local v184 = (v183 + 1) * 8

                        if v181 < v184 then
                            v184 = v181
                        end

                        local v185 = 6 * v183

                        if not (v173[v185 + 4] < v161
                            or v164 < v173[v185 + 1]
                            or v173[v185 + 5] < v162
                            or v165 < v173[v185 + 2]
                            or v173[v185 + 6] < v163
                            or v166 < v173[v185 + 3]) then
                            for j = v176, v184 - 1 do
                                local v186 = j * 6

                                if not (v174[v186 + 4] < v161
                                    or v164 < v174[v186 + 1]
                                    or v174[v186 + 5] < v162
                                    or v165 < v174[v186 + 2]
                                    or v174[v186 + 6] < v163
                                    or v166 < v174[v186 + 3]) then
                                    n18 += 1
                                    p55[n18] = j + v178
                                end
                            end
                        end

                        v176 = v184
                    end
                end

                v176 = v181
            end
        end

        p57[v167 + 1] = n18

        return n18, v167
    end

    return 0, -1
end

local packed = require(sim.packed)
local self = setmetatable({}, {
    __mode = "k"
})

function t1.BoardWorld.line_vertices(p58) -- line: 872
    -- upvalues: packed (copy), self (copy)
    local triangles = p58.triangles
    local v188 = self[p58]

    if v188 == nil or v188.source ~= triangles then
        if not packed.is_view(triangles) then
            return nil
        end

        v188 = {
            held = 0,
            source = triangles
        }
        self[p58] = v188
    end

    return v188
end

function t1.BoardWorld.line_vertices_fill(p59, p60) -- line: 884
    local source = p59.source
    local vertices = source[p60 + 1].triangle.vertices

    if p59.held >= 4096 then
        table.clear(p59)
        p59.source = source
        p59.held = 0
    end

    p59.held += 1
    p59[p60] = vertices

    return vertices
end

function t1.BoardWorld.candidate_mesh_indices_into(p61, p62, p63, p64, p65, p66, p67, p68) -- line: 905
    -- upvalues: rt (copy), QueryIndex (copy)
    local query_metadata = p61.query_metadata

    if query_metadata ~= nil and p62 == p62 and p62 ~= 1e999 and p62 ~= (-1e999) and p63 == p63 and p63 ~= 1e999 and p63 ~= (-1e999) and p64 == p64 and p64 ~= 1e999 and p64 ~= (-1e999) and p65 == p65 and p65 ~= 1e999 and p65 ~= (-1e999) and p66 == p66 and p66 ~= 1e999 and p66 ~= (-1e999) and p67 == p67 and p67 ~= 1e999 and p67 ~= (-1e999) and p62 <= p65 and p63 <= p66 and p64 <= p67 then
        local v189 = p61.maximum_fatness + p61.maximum_triangle_margin
        local v190 = math.abs(p62)

        if not (v190 > 1) then
            v190 = 1
        end

        local v191 = math.abs(p63)

        if not (v190 < v191) then
            v191 = v190
        end

        local v192 = math.abs(p64)

        if not (v191 < v192) then
            v192 = v191
        end

        local v193 = math.abs(p65)

        if not (v192 < v193) then
            v193 = v192
        end

        local v194 = math.abs(p66)

        if not (v193 < v194) then
            v194 = v193
        end

        local v195 = math.abs(p67)

        if not (v194 < v195) then
            v195 = v194
        end

        local v196 = v189 + v195 * (8 * rt.F32_EPSILON)

        return QueryIndex.query_scalar_into(p61.query_index, p62 - v196, p63 - v196, p64 - v196, p65 + v196, p66 + v196, p67 + v196, query_metadata.meshes, p68)
    end

    return -1
end

function t1.primitive_bounds(p69) -- line: 973
    -- upvalues: rt (copy), Vector3 (copy), Bounds (copy)
    local radius, center

    if p69.tag == "Sphere" then
        local v197 = p69[1]

        center = v197.center
        radius = v197.radius
    else
        if p69.tag == "Capsule" then
            local center, axis, half_length, radius = p69.center, p69.axis, p69.half_length, p69.radius

            if radius ~= radius or radius == 1e999 or radius == (-1e999) then
                return nil
            end

            local v198 = Vector3.new(axis.x * half_length, axis.y * half_length, axis.z * half_length)
            local v199 = Bounds.from_points({
                Vector3.new(center.x - v198.x, center.y - v198.y, center.z - v198.z),
                Vector3.new(center.x + v198.x, center.y + v198.y, center.z + v198.z)
            })

            if v199 == nil then
                return nil
            end

            return Bounds.expanded(v199, (math.abs(radius)))
        end

        if p69.tag == "RoundedBox" then
            local center, basis, half_extents, radius = p69.center, p69.basis, p69.half_extents, p69.radius

            if radius ~= radius or radius == 1e999 or radius == (-1e999) then
                return nil
            end

            local t12 = {
                half_extents.x,
                half_extents.y,
                half_extents.z
            }
            local v200 = rt.from_fn(3, function(p70) -- line: 1004
                -- upvalues: basis (copy), radius (copy), t12 (copy)
                local n19 = 0

                for i = 1, 3 do
                    local v201 = basis.columns[i]

                    n19 += math.abs(t12[i]) * math.abs(v201[p70 + 1])
                end

                return math.abs(radius) + n19
            end)

            return Bounds.from_points({
                Vector3.new(center.x - v200[1], center.y - v200[2], center.z - v200[3]),
                Vector3.new(center.x + v200[1], center.y + v200[2], center.z + v200[3])
            })
        end

        if p69.tag == "Triangle" then
            local v205 = p69[1]
            local fatness = v205.fatness

            if fatness ~= fatness or fatness == 1e999 or fatness == (-1e999) then
                return nil
            end

            local v206 = Bounds.from_points(v205.vertices)

            if v206 == nil then
                return nil
            end

            return Bounds.expanded(v206, (math.abs(v205.fatness)))
        end

        local _error = error
        local tag = p69.tag

        center = nil
        radius = nil
        _error("unreachable: ContactPrimitive " .. tostring(tag), 0)
    end

    if radius ~= radius or radius == 1e999 or radius == (-1e999) then
        return nil
    end

    local v207 = Bounds.from_points({ center })

    if v207 == nil then
        return nil
    end

    return Bounds.expanded(v207, (math.abs(radius)))
end

function t1.conservative_bounds(p71, p72) -- line: 1040
    -- upvalues: rt (copy), Bounds (copy)
    local n20 = 1

    for _, v208 in {
            p71.min.x,
            p71.min.y,
            p71.min.z,
            p71.max.x,
            p71.max.y,
            p71.max.z
        } do
        n20 = rt.fmax(n20, (math.abs(v208)))
    end

    return Bounds.expanded(p71, p72 + n20 * (8 * rt.F32_EPSILON))
end

local is_finite, fmin, fmax = rt.is_finite, rt.fmin, rt.fmax

function t1.primitive_conservative_bounds_scalar(p73, p74) -- line: 1054
    -- upvalues: rt (copy), is_finite (copy), fmin (copy), fmax (copy)
    local tag = p73.tag
    local v209, v210, v211, v212, v213, v214

    if tag == "Sphere" then
        local v215 = p73[1]
        local center, radius = v215.center, v215.radius

        if not is_finite(radius) then
            return nil
        end

        local x, y, z = center.x, center.y, center.z

        if not (is_finite(x) and is_finite(y) and is_finite(z)) then
            return nil
        end

        local v216 = math.abs(radius)

        v209 = x - v216
        v210 = y - v216
        v211 = z - v216
        v212 = x + v216
        v213 = y + v216
        v214 = z + v216
    elseif tag == "Capsule" then
        local center, axis, half_length, radius = p73.center, p73.axis, p73.half_length, p73.radius

        if not is_finite(radius) then
            return nil
        end

        local v217 = axis.x * half_length
        local v218 = axis.y * half_length
        local v219 = axis.z * half_length
        local v220 = center.x - v217
        local v221 = center.y - v218
        local v222 = center.z - v219
        local v223 = center.x + v217
        local v224 = center.y + v218
        local v225 = center.z + v219

        if not (is_finite(v220) and is_finite(v221) and is_finite(v222)) or not (is_finite(v223) and is_finite(v224) and is_finite(v225)) then
            return nil
        end

        local v226 = math.abs(radius)

        v209 = fmin(v220, v223) - v226
        v210 = fmin(v221, v224) - v226
        v211 = fmin(v222, v225) - v226
        v212 = fmax(v220, v223) + v226
        v213 = fmax(v221, v224) + v226
        v214 = fmax(v222, v225) + v226
    elseif tag == "RoundedBox" then
        local center, basis, half_extents, radius = p73.center, p73.basis, p73.half_extents, p73.radius

        if not is_finite(radius) then
            return nil
        end

        local v227 = math.abs(half_extents.x)
        local v228 = math.abs(half_extents.y)
        local v229 = math.abs(half_extents.z)
        local columns = basis.columns
        local v230 = columns[1]
        local v231 = columns[2]
        local v232 = columns[3]
        local v239 = math.abs(radius) + (v227 * math.abs(v230[1]) + 0 + v228 * math.abs(v231[1]) + v229 * math.abs(v232[1]))
        local v246 = math.abs(radius) + (v227 * math.abs(v230[2]) + 0 + v228 * math.abs(v231[2]) + v229 * math.abs(v232[2]))
        local v253 = math.abs(radius) + (v227 * math.abs(v230[3]) + 0 + v228 * math.abs(v231[3]) + v229 * math.abs(v232[3]))
        local v254 = center.x - v239
        local v255 = center.y - v246
        local v256 = center.z - v253
        local v257 = center.x + v239
        local v258 = center.y + v246
        local v259 = center.z + v253

        if not (is_finite(v254) and is_finite(v255) and is_finite(v256)) or not (is_finite(v257) and is_finite(v258) and is_finite(v259)) then
            return nil
        end

        v209 = fmin(v254, v257)
        v210 = fmin(v255, v258)
        v211 = fmin(v256, v259)
        v212 = fmax(v254, v257)
        v213 = fmax(v255, v258)
        v214 = fmax(v256, v259)
    elseif tag == "Triangle" then
        local v260 = p73[1]

        if not is_finite(v260.fatness) then
            return nil
        end

        local vertices = v260.vertices
        local v261 = vertices[1]

        if v261 == nil then
            return nil
        end

        local x, y, z = v261.x, v261.y, v261.z

        if not (is_finite(x) and is_finite(y) and is_finite(z)) then
            return nil
        end

        local v262 = #vertices
        local v263 = x
        local v264 = y
        local v265 = z

        for i = 2, v262 do
            local v266 = vertices[i]
            local x2, y2, z2 = v266.x, v266.y, v266.z

            if not (is_finite(x2) and is_finite(y2) and is_finite(z2)) then
                return nil
            end

            x = fmin(x, x2)
            y = fmin(y, y2)
            z = fmin(z, z2)
            v263 = fmax(v263, x2)
            v264 = fmax(v264, y2)
            v265 = fmax(v265, z2)
        end

        local v267 = math.abs(v260.fatness)

        v209 = x - v267
        v210 = y - v267
        v211 = z - v267
        v212 = v263 + v267
        v213 = v264 + v267
        v214 = v265 + v267
    else
        error("unreachable: ContactPrimitive " .. tostring(tag), 0)
    end

    local v273 = p74 + fmax(fmax(fmax(fmax(fmax(fmax(1, (math.abs(v209))), (math.abs(v210))), (math.abs(v211))), (math.abs(v212))), (math.abs(v213))), (math.abs(v214))) * (8 * rt.F32_EPSILON)

    return v209 - v273, v210 - v273, v211 - v273, v212 + v273, v213 + v273, v214 + v273
end

return t1
