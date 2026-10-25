-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_subnormal_mantissa(p1) -- line: 7
    local v2 = p1 * 7.1362384635298E+44
    local v3 = math.floor(v2)
    local v4 = v2 - v3

    if v4 > 0.5 or v4 == 0.5 and v3 % 2 == 1 then
        return v3 + 1
    end

    return v3
end

local function rtl_to_bits(p2) -- line: 16
    -- upvalues: v1 (copy)
    if p2 ~= 0 and p2 > -1.1754943508222875E-38 and p2 < 1.1754943508222875E-38 then
        local v6 = math.abs(p2) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        if p2 < 0 then
            return v5 + 2147483648
        end

        return v5
    end

    buffer.writef32(v1, 0, p2)

    return (buffer.readu32(v1, 0))
end

local function rtl_fround(p3) -- line: 24
    -- upvalues: v1 (copy)
    if p3 ~= 0 and p3 > -1.1754943508222875E-38 and p3 < 1.1754943508222875E-38 then
        local v9 = math.abs(p3) * 7.1362384635298E+44
        local v8 = math.floor(v9)
        local v10 = v9 - v8

        if v10 > 0.5 or v10 == 0.5 and v8 % 2 == 1 then
            v8 += 1
        end

        local v11 = v8 * 1.401298464324817E-45

        if p3 < 0 then
            return -v11
        end

        return v11
    end

    buffer.writef32(v1, 0, p3)

    return (buffer.readf32(v1, 0))
end

local function rtl_is_finite(p4) -- line: 32
    if p4 ~= p4 or p4 == 1e999 then
        return false
    end

    return p4 ~= (-1e999)
end

local import = require(sim.import)
local Vector3 = import("skate_core/math").Vector3
local v12 = import("skate_core/physics/board_world")
local BoardWorld, WorldTriangle = v12.BoardWorld, v12.WorldTriangle
local Bounds = import("skate_core/physics/board_world/query_metadata").Bounds
local TriangleFeature = import("skate_core/physics/collision").TriangleFeature
local RetailAffineTransform = import("skate_core/physics/drive_frames").RetailAffineTransform
local v13 = import("skate_data/skate_map")
local v14 = import("skate_data/retail_collision")
local t1 = {}

local function glam_vec3(p5, p6, p7) -- line: 61
    return {
        x = p5,
        y = p6,
        z = p7
    }
end

local function glam_from_array(p8) -- line: 64
    return {
        x = p8[1],
        y = p8[2],
        z = p8[3]
    }
end

local function glam_sub(p9, p10) -- line: 67
    return {
        x = p9.x - p10.x,
        y = p9.y - p10.y,
        z = p9.z - p10.z
    }
end

local function glam_dot(p11, p12) -- line: 70
    return p11.x * p12.x + p11.y * p12.y + p11.z * p12.z
end

local function glam_cross(p13, p14) -- line: 73
    return {
        x = p13.y * p14.z - p14.y * p13.z,
        y = p13.z * p14.x - p14.z * p13.x,
        z = p13.x * p14.y - p14.x * p13.y
    }
end

local function glam_scale(p15, p16) -- line: 80
    return {
        x = p15.x * p16,
        y = p15.y * p16,
        z = p15.z * p16
    }
end

local function glam_min(p17, p18) -- line: 83
    -- upvalues: rt (copy)
    return {
        x = rt.fmin(p17.x, p18.x),
        y = rt.fmin(p17.y, p18.y),
        z = rt.fmin(p17.z, p18.z)
    }
end

local function glam_max(p19, p20) -- line: 86
    -- upvalues: rt (copy)
    return {
        x = rt.fmax(p19.x, p20.x),
        y = rt.fmax(p19.y, p20.y),
        z = rt.fmax(p19.z, p20.z)
    }
end

local function glam_try_normalize(p21) -- line: 90
    local v16 = 1 / math.sqrt(p21.x * p21.x + p21.y * p21.y + p21.z * p21.z)

    return if v16 == v16 and v16 ~= 1e999 and v16 ~= (-1e999) and v16 > 0 then {
        x = p21.x * v16,
        y = p21.y * v16,
        z = p21.z * v16
    } else nil
end

local function glam_index(p22, p23) -- line: 98
    if p23 == 0 then
        return p22.x
    end

    if p23 == 1 then
        return p22.y
    end

    return p22.z
end

local function total_less(p24, p25) -- line: 108
    -- upvalues: v1 (copy)
    if p24 < p25 then
        return true
    end

    if p25 < p24 then
        return false
    end

    local function key(p26) -- line: 115
        -- upvalues: v1 (copy)
        local v17

        if p26 ~= 0 and p26 > -1.1754943508222875E-38 and p26 < 1.1754943508222875E-38 then
            local v18 = math.abs(p26) * 7.1362384635298E+44
            local v19 = math.floor(v18)
            local v20 = v18 - v19

            v17 = if v20 > 0.5 or v20 == 0.5 and v19 % 2 == 1 then v19 + 1 else v19

            if p26 < 0 then
                v17 += 2147483648
            end
        else
            buffer.writef32(v1, 0, p26)
            v17 = buffer.readu32(v1, 0)
        end

        if v17 >= 2147483648 then
            return -(v17 - 2147483648) - 1
        end

        return v17
    end

    local v21

    if p24 ~= 0 and p24 > -1.1754943508222875E-38 and p24 < 1.1754943508222875E-38 then
        local v22 = math.abs(p24) * 7.1362384635298E+44
        local v23 = math.floor(v22)
        local v24 = v22 - v23

        v21 = if v24 > 0.5 or v24 == 0.5 and v23 % 2 == 1 then v23 + 1 else v23

        if p24 < 0 then
            v21 += 2147483648
        end
    else
        buffer.writef32(v1, 0, p24)
        v21 = buffer.readu32(v1, 0)
    end

    if v21 >= 2147483648 then
        v21 = -(v21 - 2147483648) - 1
    end

    local v25

    if p25 ~= 0 and p25 > -1.1754943508222875E-38 and p25 < 1.1754943508222875E-38 then
        local v26 = math.abs(p25) * 7.1362384635298E+44
        local v27 = math.floor(v26)
        local v28 = v26 - v27

        v25 = if v28 > 0.5 or v28 == 0.5 and v27 % 2 == 1 then v27 + 1 else v27

        if p25 < 0 then
            v25 += 2147483648
        end
    else
        buffer.writef32(v1, 0, p25)
        v25 = buffer.readu32(v1, 0)
    end

    if v25 >= 2147483648 then
        v25 = -(v25 - 2147483648) - 1
    end

    return v21 < v25
end

t1.LEAF_TRIANGLE_BUDGET = 16384

local LEAF_TRIANGLE_BUDGET = t1.LEAF_TRIANGLE_BUDGET

t1.SceneStats = {}

function t1.SceneStats.default() -- line: 133
    return {
        leaves = 0,
        draws = 0,
        triangles = 0,
        slabs = 0
    }
end

t1.Triangle = {}

function t1.partition(p27, p28) -- line: 156
    -- upvalues: rt (copy), v1 (copy), glam_min (copy), glam_max (copy), LEAF_TRIANGLE_BUDGET (copy)
    local v29 = table.clone(p27)

    table.clear(p27)

    local t2 = {
        v29
    }
    local t3 = {}

    while #t2 > 0 do
        local v30 = table.remove(t2)

        if #v30 <= LEAF_TRIANGLE_BUDGET then
            table.insert(t3, v30)
        else
            local v31 = {
                x = 1e999,
                y = 1e999,
                z = 1e999
            }
            local v32 = {
                x = (-1e999),
                y = (-1e999),
                z = (-1e999)
            }

            for _, v33 in v30 do
                v31 = glam_min(v31, p28[v33 + 1].centroid)
                v32 = glam_max(v32, p28[v33 + 1].centroid)
            end

            local t4 = {
                x = v32.x - v31.x,
                y = v32.y - v31.y,
                z = v32.z - v31.z
            }
            local v34 = if t4.x >= t4.y and t4.x >= t4.z then 0 elseif t4.y >= t4.z then 1 else 2
            local v35 = #v30
            local v36 = 1
            local v37 = table.create(v35)

            while v36 < v35 do
                local n1 = 1

                while n1 <= v35 do
                    local v40 = math.min(n1 + v36, v35 + 1)
                    local v43 = math.min(n1 + v36 * 2, v35 + 1)
                    local v44 = n1
                    local v45 = v40
                    local v46 = n1
                    local v47, v48

                    while true do
                        if v44 < v40 then
                            if not (v45 < v43) then
                                v47 = v44
                                v48 = v46
                                break
                            end

                            local centroid = p28[v30[v45] + 1].centroid
                            local v49 = if v34 == 0 then centroid.x elseif v34 == 1 then centroid.y else centroid.z
                            local centroid2 = p28[v30[v44] + 1].centroid
                            local v50 = if v34 == 0 then centroid2.x elseif v34 == 1 then centroid2.y else centroid2.z
                            local v51

                            if v49 < v50 then
                                v51 = true
                            elseif v50 < v49 then
                                v51 = false
                            else
                                local function key(p29) -- line: 115
                                    -- upvalues: v1 (copy)
                                    local v52

                                    if p29 ~= 0 and p29 > -1.1754943508222875E-38 and p29 < 1.1754943508222875E-38 then
                                        local v53 = math.abs(p29) * 7.1362384635298E+44
                                        local v54 = math.floor(v53)
                                        local v55 = v53 - v54

                                        v52 = if v55 > 0.5 or v55 == 0.5 and v54 % 2 == 1 then v54 + 1 else v54

                                        if p29 < 0 then
                                            v52 += 2147483648
                                        end
                                    else
                                        buffer.writef32(v1, 0, p29)
                                        v52 = buffer.readu32(v1, 0)
                                    end

                                    if v52 >= 2147483648 then
                                        return -(v52 - 2147483648) - 1
                                    end

                                    return v52
                                end

                                local v56

                                if v49 == 0 then
                                    buffer.writef32(v1, 0, v49)
                                    v56 = buffer.readu32(v1, 0)
                                elseif v49 > -1.1754943508222875E-38 and v49 < 1.1754943508222875E-38 then
                                    local v57 = math.abs(v49) * 7.1362384635298E+44

                                    v56 = math.floor(v57)

                                    local v58 = v57 - v56

                                    if v58 > 0.5 or v58 == 0.5 and v56 % 2 == 1 then
                                        v56 += 1
                                    end

                                    if v49 < 0 then
                                        v56 += 2147483648
                                    end
                                else
                                    buffer.writef32(v1, 0, v49)
                                    v56 = buffer.readu32(v1, 0)
                                end

                                local v59 = if v56 >= 2147483648 then -(v56 - 2147483648) - 1 else v56
                                local v60

                                if v50 ~= 0 and v50 > -1.1754943508222875E-38 and v50 < 1.1754943508222875E-38 then
                                    local v61 = math.abs(v50) * 7.1362384635298E+44
                                    local v62 = math.floor(v61)
                                    local v63 = v61 - v62
                                    local v64 = if v63 > 0.5 or v63 == 0.5 and v62 % 2 == 1 then v62 + 1 else v62

                                    v60 = if v50 < 0 then v64 + 2147483648 else v64
                                else
                                    buffer.writef32(v1, 0, v50)
                                    v60 = buffer.readu32(v1, 0)
                                end

                                if v60 >= 2147483648 then
                                    v60 = -(v60 - 2147483648) - 1
                                end

                                v51 = v59 < v60
                            end

                            if v51 then
                                v37[v46] = v30[v45]
                                v45 += 1
                            else
                                v37[v46] = v30[v44]
                                v44 += 1
                            end

                            v46 += 1
                            continue
                        end

                        v47 = v44
                        v48 = v46
                        break
                    end

                    local v65

                    while true do
                        if v47 < v40 then
                            v37[v48] = v30[v47]
                            v47 += 1
                            v48 += 1
                            continue
                        end

                        v65 = v48
                        break
                    end

                    while v45 < v43 do
                        v37[v65] = v30[v45]
                        v45 += 1
                        v65 += 1
                    end

                    n1 += v36 * 2
                end

                v30, v36, v37 = v37, v36 * 2, v30
            end

            local v66 = rt.idiv(#v30, 2)
            local v67 = table.create(v66)
            local v68 = table.create(#v30 - v66)

            table.move(v30, 1, v66, 1, v67)
            table.move(v30, v66 + 1, #v30, 1, v68)
            table.insert(t2, v67)
            table.insert(t2, v68)
        end
    end

    return t3
end

function t1.tangent(p30) -- line: 249
    -- upvalues: rt (copy), glam_cross (copy)
    if p30.tangent_frame == nil then
        return { 0, 0, 0, 0 }
    end

    local v69 = table.create(4)

    for i = 1, 4 do
        local v70 = p30.tangent_frame[i]

        if v70 >= 128 then
            v70 -= 256
        end

        v69[i] = rt.fmax(v70 / 127, -1)
    end

    local t5 = {
        x = v69[1],
        y = v69[2],
        z = v69[3]
    }
    local normal = p30.normal
    local v71 = glam_cross(t5, {
        x = normal[1],
        y = normal[2],
        z = normal[3]
    })
    local v72 = v69[4]
    local t6 = {
        x = v71.x * v72,
        y = v71.y * v72,
        z = v71.z * v72
    }

    return {
        t6.x,
        t6.y,
        t6.z,
        v69[4]
    }
end

local decode_native_edges, retail_archive

function t1.validate_runtime(p31) -- line: 278
    -- upvalues: v13 (copy), decode_native_edges (ref), retail_archive (ref)
    local v73 = retail_archive(p31)

    if #p31.geometry.collision == 0 and v73 == nil then
        error("SKATE map has no collision geometry", 0)
    end

    if v73 == nil then
        for _, v74 in p31.geometry.collision do
            if v74.native_edges ~= nil then
                decode_native_edges(v74.native_edges)
            end
        end
    end

    if #p31.doors ~= 0 then
        error(("Map '%*' contains %* hinged doors. This imported game has no door body/controller adapter yet; refusing to drop their geometry or turn them into static walls."):format(p31.name, #p31.doors), 0)
    end

    for _, v75 in p31.extensions do
        local v80 = string.char(v75.tag[1], v75.tag[2], v75.tag[3], v75.tag[4])

        if not v13.tag_is(v75.tag, "RWCM") then
            if v13.tag_is(v75.tag, "MOBJ") then
                v13.validate_static_objects(p31, v75)
            elseif (not v13.tag_is(v75.tag, "SKYB") or v75.schema ~= 1) and not v13.tag_is(v75.tag, "WMET") and not v13.tag_is(v75.tag, "WCFG") and not v13.tag_is(v75.tag, "BMAT") then
                error(("SKATE extension %* schema %* is decoded but its runtime adapter is not implemented. Refusing to silently omit potentially required world geometry."):format(v80, v75.schema), 0)
            end
        end
    end

    for _, v81 in p31.textures do
        if v81.width == 0 then
            error("SKATE contains external texture placeholders; supply a package with embedded textures", 0)
        end
    end
end

function decode_native_edges(p32) -- line: 335
    -- upvalues: TriangleFeature (copy)
    local ONE_SIDED, USE_EDGE_COSINES = TriangleFeature.ONE_SIDED, TriangleFeature.USE_EDGE_COSINES
    local t7 = {
        0, 0, 0
    }
    local v82 = bit32.bor(1, ONE_SIDED, USE_EDGE_COSINES)

    for i = 0, 2 do
        local v83 = p32[i + 1]
        local v84 = bit32.band(v83, 31)

        if v84 >= 28 then
            error(("Invalid SKATE native edge angle code %* at corner %*"):format(v84, i), 0)
        end

        t7[i + 1] = 1 - 9.86960506439209 / bit32.lshift(8, v84)
        v82 = bit32.bor(bit32.bor(v82, (bit32.lshift(bit32.band(v83, 32), i))), (bit32.lshift(bit32.band(v83, 64), i + 3)))
    end

    return v82, t7
end

t1.decode_native_edges = decode_native_edges

function retail_archive(p33) -- line: 355
    -- upvalues: v13 (copy)
    local t8 = {}

    for _, v90 in p33.extensions do
        if v13.tag_is(v90.tag, "RWCM") then
            table.insert(t8, v90)
        end
    end

    local v91 = t8[1]

    if v91 == nil then
        return nil
    end

    if v91.schema ~= 1 or t8[2] ~= nil then
        error("SKATE requires one RWCM extension with schema 1", 0)
    end

    return v91.payload
end

t1.retail_archive = retail_archive

local function retail_collision_world(p34, p35) -- line: 373
    -- upvalues: rt (copy), Vector3 (copy), BoardWorld (copy), WorldTriangle (copy), Bounds (copy), TriangleFeature (copy), RetailAffineTransform (copy), v14 (copy), decode_native_edges (ref)
    local t9 = {}
    local t10 = {}
    local t11 = {}

    v14.visit_clusters(p34, function(_, p37) -- line: 377
        -- upvalues: p35 (copy), t9 (copy), t10 (copy), t11 (copy), rt (copy), Vector3 (copy), WorldTriangle (copy), Bounds (copy), TriangleFeature (copy), RetailAffineTransform (copy), decode_native_edges (ref)
        local n2 = 0

        while n2 < #p37 do
            local group = p37[n2 + 1].group
            local v92 = #t9

            while n2 < #p37 and p37[n2 + 1].group == group do
                local v93 = p37[n2 + 1]
                local v94, v95

                if v93.edges ~= nil then
                    local v96

                    v96, v94 = decode_native_edges(v93.edges)
                    v95 = bit32.band(v96, (bit32.bnot(TriangleFeature.ONE_SIDED)))

                    if v93.one_sided then
                        v95 = bit32.bor(v95, TriangleFeature.ONE_SIDED)
                    end
                else
                    v95 = 481
                    v94 = { -1, -1, -1 }
                end

                local points = v93.points
                local v98 = WorldTriangle.from_vertices({
                    Vector3.new(points[1][1], points[1][2], points[1][3]),
                    Vector3.new(points[2][1], points[2][2], points[2][3]),
                    Vector3.new(points[3][1], points[3][2], points[3][3])
                }, rt.copy(p35), v93.surface, v95, v94, 0)

                if v98 == nil then
                    error("Invalid RWCM collision triangle", 0)
                end

                table.insert(t9, v98)
                table.insert(t10, v93.surface)
                n2 += 1
            end

            local t12 = {
                start = v92,
                ["end"] = #t9
            }
            local v99 = table.create((t12["end"] - t12.start) * 3)

            for i = t12.start, t12["end"] - 1 do
                for _, v100 in t9[i + 1].triangle.vertices do
                    table.insert(v99, v100)
                end
            end

            local v101 = Bounds.from_points(v99)

            if v101 == nil then
                error("Invalid RWCM cluster bounds", 0)
            end

            table.insert(t11, {
                geometry = 0,
                rejection_flags = 0,
                pool = "Ground",
                triangle_range = t12,
                local_to_world = rt.copy(RetailAffineTransform.IDENTITY),
                world_to_local = rt.copy(RetailAffineTransform.IDENTITY),
                local_bounds = v101,
                matching_group = group
            })
        end
    end)

    return BoardWorld.with_query_metadata(t9, {
        island_flags = 0,
        packed_surfaces = t10,
        meshes = t11,
        static_edges = {}
    })
end

t1.retail_collision_world = retail_collision_world

function t1.collision_world(p38, p39) -- line: 443
    -- upvalues: rt (copy), v1 (copy), import (copy), Vector3 (copy), BoardWorld (copy), WorldTriangle (copy), Bounds (copy), TriangleFeature (copy), RetailAffineTransform (copy), glam_cross (copy), decode_native_edges (ref), retail_archive (ref), retail_collision_world (copy)
    local v102 = retail_archive(p38)
    local v103 = import("skate_core/physics/collision/fixup")
    local DEFAULT_REACH = v103.DEFAULT_REACH
    local sim_data_map = if v102 == nil then nil else v102.sim_data_map

    if sim_data_map ~= nil then
        local v104 = import("skate_game/paged_world").data_index(sim_data_map)
        local v105 = v104 == nil
        local v106 = if not v105 then type(v104.bend_reach) == "number" else nil

        if v105 or not v106 then
            if v104 ~= nil and v104.bend_reach == false then
                DEFAULT_REACH = nil
            end
        else
            DEFAULT_REACH = v104.bend_reach
        end
    end

    v103.set_bend_reach(DEFAULT_REACH)

    if v102 == nil then
        local t14 = {}
        local t15 = {}
        local t16 = {}
        local t17 = {}

        for _, v107 in p38.geometry.collision do
            local v108 = table.create(3)

            for i = 1, 3 do
                local v109 = v107.points[i]

                buffer.writef32(v1, 0, 0.001)

                local v110 = 1 / buffer.readf32(v1, 0)
                local v111 = `{ rt.f_to_int(rt.round(v109[1] * v110), -9223372036854776000, 9223372036854776000) + 0 },{ rt.f_to_int(rt.round(v109[2] * v110), -9223372036854776000, 9223372036854776000) + 0 },{ rt.f_to_int(rt.round(v109[3] * v110), -9223372036854776000, 9223372036854776000) + 0 }`
                local v112 = t14[v111]

                if v112 == nil then
                    v112 = #t15
                    table.insert(t15, {
                        x = v109[1],
                        y = v109[2],
                        z = v109[3]
                    })
                    t14[v111] = v112
                end

                v108[i] = v112
            end

            local v113 = v107.points[1]
            local t19 = {
                x = v113[1],
                y = v113[2],
                z = v113[3]
            }
            local v114 = v107.points[2]
            local t20 = {
                x = v114[1],
                y = v114[2],
                z = v114[3]
            }
            local v115 = v107.points[3]
            local t21 = {
                x = v115[1],
                y = v115[2],
                z = v115[3]
            }
            local v116 = glam_cross({
                x = t20.x - t19.x,
                y = t20.y - t19.y,
                z = t20.z - t19.z
            }, {
                x = t21.x - t19.x,
                y = t21.y - t19.y,
                z = t21.z - t19.z
            })
            local v118 = 1 / math.sqrt(v116.x * v116.x + v116.y * v116.y + v116.z * v116.z)
            local t22 = if v118 == v118 and v118 ~= 1e999 and v118 ~= (-1e999) and v118 > 0 then {
                x = v116.x * v118,
                y = v116.y * v118,
                z = v116.z * v118
            } else nil

            if t22 == nil then
                error("Invalid SKATE collision triangle normal", 0)
            end

            table.insert(t16, v108)
            table.insert(t17, t22)
        end

        local v119 = rt.filled(#t16, { 1, 1, 1 })
        local v121 = rt.filled(#t16, (bit32.bor(TriangleFeature.ONE_SIDED, TriangleFeature.USE_EDGE_COSINES, 224)))
        local v122 = false

        for _, v123 in p38.geometry.collision do
            if v123.native_edges == nil then
                v122 = true
                break
            end
        end

        if v122 then
            local t23 = {}

            for i = 0, #t16 - 1 do
                local v124 = t16[i + 1]

                for j = 0, 2 do
                    local v125 = v124[j + 1]
                    local v126 = v124[rt.irem(j + 1, 3) + 1]
                    local v127 = ("%*,%*"):format(v126, v125)
                    local v128 = t23[v127]

                    if v128 ~= nil then
                        t23[v127] = nil

                        local v130 = v128[1]
                        local v131 = v128[2]
                        local clamp = rt.clamp
                        local v132 = t17[i + 1]
                        local v133 = t17[v130 + 1]
                        local v134 = clamp(v132.x * v133.x + v132.y * v133.y + v132.z * v133.z, -1, 1)
                        local v135 = t15[v126 + 1]
                        local v136 = t15[v125 + 1]
                        local t24 = {
                            x = v135.x - v136.x,
                            y = v135.y - v136.y,
                            z = v135.z - v136.z
                        }
                        local v137 = glam_cross(t17[i + 1], t17[v130 + 1])
                        local v138 = t24.x * v137.x + t24.y * v137.y + t24.z * v137.z

                        for _, v139 in {
                                { i, j },
                                { v130, v131 }
                            } do
                            local v140 = v139[1]
                            local v141 = v139[2]

                            v119[v140 + 1][v141 + 1] = v134

                            if v138 <= -1E-06 or v134 >= 1 then
                                v121[v140 + 1] = bit32.band(v121[v140 + 1], (bit32.bnot((bit32.lshift(32, v141)))))
                            end
                        end
                    else
                        local v129 = ("%*,%*"):format(v125, v126)

                        if t23[v129] == nil then
                            t23[v129] = { i, j }
                        end
                    end
                end
            end

            local v146 = table.create(#t15)

            for i = 1, #t15 do
                v146[i] = {}
            end

            for i = 0, #t16 - 1 do
                for _, v147 in t16[i + 1] do
                    table.insert(v146[v147 + 1], i)
                end
            end

            for i = 0, #v146 - 1 do
                local v149 = v146[i + 1]
                local v150 = t17[v149[1] + 1]
                local v151 = true

                for _, v152 in v149 do
                    local v153 = t17[v152 + 1]

                    if not (math.abs(v150.x * v153.x + v150.y * v153.y + v150.z * v153.z - 1) <= 0.01) then
                        v151 = false
                        break
                    end
                end

                if v151 then
                    for _, v155 in v149 do
                        for j = 0, 2 do
                            if t16[v155 + 1][j + 1] == i then
                                v121[v155 + 1] = bit32.bor(v121[v155 + 1], (bit32.lshift(512, j)))
                            end
                        end
                    end
                end
            end
        end

        local v159 = table.create(#t16)
        local v160 = table.create(#t16)

        for i = 0, #p38.geometry.collision - 1 do
            local v161 = p38.geometry.collision[i + 1]

            if v161.native_edges ~= nil then
                local v162 = i + 1
                local v163, v164 = decode_native_edges(v161.native_edges)

                v121[i + 1] = v163
                v119[v162] = v164
            end

            local v165 = p38.materials[v161.material - 1 + 1]

            table.insert(v160, (bit32.band(bit32.bor(v165.audio, bit32.lshift(v165.physics, 7), (bit32.lshift(v165.pattern, 12))), 65535)))

            local v170 = table.create(3)

            for j = 1, 3 do
                local v171 = t15[t16[i + 1][j] + 1]

                v170[j] = Vector3.new(v171.x, v171.y, v171.z)
            end

            local v172 = WorldTriangle.from_vertices(v170, rt.copy(p39), v161.surface, v121[i + 1], rt.copy(v119[i + 1]), 0)

            if v172 == nil then
                error("Invalid SKATE collision volume", 0)
            end

            table.insert(v159, v172)
        end

        local t25 = {}

        for i = 0, #v159 - 1, 64 do
            local v173 = #v159
            local v174 = math.min(i + 64, v173)
            local v175 = table.create((v174 - i) * 3)

            for j = i, v174 - 1 do
                for _, v176 in v159[j + 1].triangle.vertices do
                    table.insert(v175, v176)
                end
            end

            local v177 = Bounds.from_points(v175)

            if v177 == nil then
                error("SKATE collision bounds empty", 0)
            end

            table.insert(t25, {
                geometry = 0,
                rejection_flags = 0,
                matching_group = -1,
                pool = "Ground",
                triangle_range = {
                    start = i,
                    ["end"] = v174
                },
                local_to_world = rt.copy(RetailAffineTransform.IDENTITY),
                world_to_local = rt.copy(RetailAffineTransform.IDENTITY),
                local_bounds = v177
            })
        end

        local t27 = {
            island_flags = 0,
            packed_surfaces = v160,
            meshes = t25,
            static_edges = {}
        }

        return BoardWorld.with_query_metadata(v159, t27)
    end

    local v178 = v102.sim_data_map == nil
    local v179, v180

    if not v178 then
        v179 = import("skate_game/paged_world")
        v180 = v179.is_paged(v102.sim_data_map)
    end

    if v178 or not v180 then
        return retail_collision_world(v102, p39)
    end

    return v179.world(v102.sim_data_map, p39)
end

function t1.load(p40, p41) -- line: 651
    -- upvalues: v13 (copy), t1 (copy)
    local v181 = v13.SkateMap.load(p40)

    return t1.collision_world(v181, p41), v181
end

return t1
