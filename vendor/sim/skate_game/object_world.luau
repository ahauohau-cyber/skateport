-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/board_world")
local BoardWorld, WorldTriangle = v1.BoardWorld, v1.WorldTriangle
local v2 = import("skate_core/physics/board_world/broadphase")
local Bounds = import("skate_core/physics/board_world/query_metadata").Bounds
local v3 = import("skate_core/physics/board_world/objects")
local RetailAffineTransform = import("skate_core/physics/drive_frames").RetailAffineTransform
local Vector3 = import("skate_core/math").Vector3
local TriangleFeature = import("skate_core/physics/collision").TriangleFeature
local v4 = import("skate_core/physics/collision/fixup")
local packed = require(sim.packed)

local function skate_world() -- line: 38
    -- upvalues: import (copy)
    return import("skate_game/skate_world")
end

local function grind() -- line: 41
    -- upvalues: import (copy)
    return import("skate_game/grind_world")
end

local function octree() -- line: 44
    -- upvalues: import (copy)
    return import("skate_game/grind_world/octree")
end

local t1 = {
    CAPS = {
        piece_triangles = 1024,
        piece_rails = 16,
        rail_points = 64,
        objects = 1000,
        total_triangles = 16000,
        area = 24,
        area_triangles = 4000,
        extent = 20000
    },
    CELL = 16,
    CELL_SCAN = 64,
    SKATER_PAD = 0.6,
    GRIND_STATES = { 400, 499 },
    DEFAULT_SURFACE = 8373
}
local fround = rt.fround
local t2 = {}

t1.templates = t2

local function freeze_deep(p1) -- line: 76
    -- upvalues: freeze_deep (copy)
    if type(p1) ~= "table" or table.isfrozen(p1) then
        return p1
    end

    for _, v5 in p1 do
        freeze_deep(v5)
    end

    table.freeze(p1)

    return p1
end

function t1.edge_codes(p2, p3, p4) -- line: 91
    -- upvalues: import (copy), v4 (copy), t1 (copy)
    local v6 = table.create(#p2)
    local t3 = {}
    local t4 = {}

    for v7, v8 in p2 do
        local v9 = if type(p3) == "table" then p3[v7] else p3 or t1.DEFAULT_SURFACE
        local v10 = t4[v9]

        if v10 == nil then
            table.insert(t3, {
                audio = bit32.band(v9, 127),
                physics = bit32.band(bit32.rshift(v9, 7), 31),
                pattern = bit32.rshift(v9, 12)
            })
            v10 = #t3
            t4[v9] = v10
        end

        v6[v7] = {
            points = {
                v8[1],
                v8[2],
                v8[3]
            },
            material = v10,
            surface = v9,
            native_edges = if p4 == nil then nil else p4[v7]
        }
    end

    local t7 = {
        extensions = {},
        geometry = {
            collision = v6
        },
        materials = t3
    }
    local BEND_REACH = v4.BEND_REACH
    local collision_world = import("skate_game/skate_world").collision_world
    local t8 = {
        restitution = 0,
        static_friction = 0,
        dynamic_friction = 0
    }
    local ok, result = pcall(collision_world, t7, t8)

    v4.BEND_REACH = BEND_REACH

    if not ok then
        error("object template edges: " .. tostring(result), 0)
    end

    local v12 = table.create(#p2)
    local v13 = table.create(#p2)

    for i = 1, #p2 do
        local feature = result.triangles[i].triangle.feature

        v12[i] = feature.flags
        v13[i] = table.clone(feature.edge_cosines)
    end

    return v12, v13
end

local function without_base(p5) -- line: 141
    local n1 = 1e999

    for _, v14 in p5 do
        n1 = math.min(math.min(math.min(n1, v14[1][2]), v14[2][2]), v14[3][2])
    end

    local t9 = {}
    local t10 = {}

    for v20, v21 in p5 do
        local v22 = v21[1]
        local v23 = v21[2]
        local v24 = v21[3]
        local v25 = v22[2] <= n1 + 0.001 and v23[2] <= n1 + 0.001 and v24[2] <= n1 + 0.001
        local v26 = v23[1] - v22[1]
        local v27 = v23[2] - v22[2]
        local v28 = v23[3] - v22[3]
        local v29 = v24[1] - v22[1]
        local v30 = v24[2] - v22[2]
        local v31 = v24[3] - v22[3]
        local v32 = v27 * v31 - v28 * v30
        local v33 = v28 * v29 - v26 * v31
        local v34 = v26 * v30 - v27 * v29
        local v36 = math.sqrt(v32 * v32 + v33 * v33 + v34 * v34)

        if v25 and v36 > 0 and v33 / v36 < -0.99 then
            table.insert(t10, v20)
        else
            table.insert(t9, v20)
        end
    end

    return t9, t10
end

t1.without_base = without_base

local function compile(p6, p7) -- line: 167
    -- upvalues: rt (copy), import (copy), WorldTriangle (copy), Vector3 (copy), TriangleFeature (copy), t1 (copy), fround (copy), freeze_deep (copy), without_base (copy)
    local triangles = p7.triangles

    if type(triangles) ~= "table" or #triangles == 0 then
        error(("template %*: no triangles"):format(p6), 0)
    end

    local v37 = p7

    if not p7.keep_base then
        local v38 = without_base(triangles)

        if #v38 < #triangles then
            local function pick(p8) -- line: 176
                -- upvalues: v38 (copy)
                if type(p8) ~= "table" then
                    return p8
                end

                local v39 = table.create(#v38)

                for v40, v41 in v38 do
                    v39[v40] = p8[v41]
                end

                return v39
            end

            v37 = table.clone(p7)

            local v42 = triangles

            if type(triangles) == "table" then
                v42 = table.create(#v38)

                for v43, v44 in v38 do
                    v42[v43] = triangles[v44]
                end
            end

            v37.triangles = v42

            local surfaces = v37.surfaces
            local v45 = surfaces

            if type(surfaces) == "table" then
                v45 = table.create(#v38)

                for v46, v47 in v38 do
                    v45[v46] = surfaces[v47]
                end
            end

            v37.surfaces = v45

            local edges = v37.edges
            local v48 = edges

            if type(edges) == "table" then
                v48 = table.create(#v38)

                for v49, v50 in v38 do
                    v48[v49] = edges[v50]
                end
            end

            v37.edges = v48

            local native_edges = v37.native_edges
            local v51 = native_edges

            if type(native_edges) == "table" then
                v51 = table.create(#v38)

                for v52, v53 in v38 do
                    v51[v52] = native_edges[v53]
                end
            end

            v37.native_edges = v51

            local one_sided = v37.one_sided
            local v54 = one_sided

            if type(one_sided) == "table" then
                v54 = table.create(#v38)

                for v55, v56 in v38 do
                    v54[v55] = one_sided[v56]
                end
            end

            v37.one_sided = v54
            triangles = v37.triangles

            if #triangles == 0 then
                error(("template %*: only base faces"):format(p6), 0)
            end
        end
    end

    if #triangles > t1.CAPS.piece_triangles then
        error(("template %*: %* triangles (cap %*)"):format(p6, #triangles, t1.CAPS.piece_triangles), 0)
    end

    local v57 = #triangles
    local v58 = table.create(v57 * 9)
    local v59 = table.create(v57)
    local v60 = table.create(v57)
    local n2 = 0

    for v61, v62 in triangles do
        local v63 = table.create(3)

        for i = 1, 3 do
            local v64 = v62[i]
            local v65 = fround(v64[1])
            local v66 = fround(v64[2])
            local v67 = fround(v64[3])

            if not (rt.is_finite(v65) and rt.is_finite(v66) and rt.is_finite(v67)) then
                error(("template %*: triangle %* is not finite"):format(p6, v61), 0)
            end

            local v68 = 9 * (v61 - 1) + (i - 1) * 3
            local v69 = v68 + 1
            local v70 = v68 + 2
            local v71 = v68 + 3

            v58[v69] = v65
            v58[v70] = v66
            v58[v71] = v67
            v63[i] = { v65, v66, v67 }
            n2 = math.max(n2, v65 * v65 + v66 * v66 + v67 * v67)
        end

        v59[v61] = v63

        local v73 = if v37.surfaces == nil then v37.surface or t1.DEFAULT_SURFACE else v37.surfaces[v61]

        if type(v73) ~= "number" or v73 < 0 or v73 > 65535 or v73 % 1 ~= 0 then
            error(("template %*: bad surface of triangle %*"):format(p6, v61), 0)
        end

        v60[v61] = v73
    end

    local v74, v75

    if v37.edges ~= nil then
        v74 = table.create(v57)
        v75 = table.create(v57)

        for i = 1, v57 do
            local v80 = v37.edges[i]
            local v81 = v80[1]
            local t11 = {
                v80[2],
                v80[3],
                v80[4]
            }

            v74[i] = v81
            v75[i] = t11
        end
    elseif v37.native_edges ~= nil then
        v74 = table.create(v57)
        v75 = table.create(v57)

        for i = 1, v57 do
            local v76, v77 = import("skate_game/skate_world").decode_native_edges(v37.native_edges[i])
            local v79 = bit32.band(v76, (bit32.bnot(TriangleFeature.ONE_SIDED)))

            if v37.one_sided == nil or v37.one_sided[i] then
                v79 = bit32.bor(v79, TriangleFeature.ONE_SIDED)
            end

            v74[i] = v79
            v75[i] = v77
        end
    else
        v74, v75 = t1.edge_codes(v59, v60)
    end

    for i = 1, v57 do
        local v82 = v59[i]

        if WorldTriangle.from_vertices({
            Vector3.new(v82[1][1], v82[1][2], v82[1][3]),
            Vector3.new(v82[2][1], v82[2][2], v82[2][3]),
            Vector3.new(v82[3][1], v82[3][2], v82[3][3])
        }, {
            restitution = 0,
            static_friction = 0,
            dynamic_friction = 0
        }, v60[i], v74[i], v75[i], 0) == nil then
            error(("template %*: triangle %* is degenerate"):format(p6, i), 0)
        end
    end

    local t12 = {}
    local v83

    if v37.rails ~= nil then
        if #v37.rails > t1.CAPS.piece_rails then
            error(("template %*: %* rails (cap %*)"):format(p6, #v37.rails, t1.CAPS.piece_rails), 0)
        end

        v83 = n2

        for v84, v85 in v37.rails do
            if v85.native ~= nil then
                local native = v85.native
                local v90 = #native

                if v90 < 148 or (v90 - 28) % 120 ~= 0 then
                    error(("template %*: rail %* has a bad native payload (%* bytes)"):format(p6, v84, v90), 0)
                end

                local v91 = (v90 - 28) // 120

                if t1.CAPS.rail_points < v91 then
                    error(("template %*: rail %* has %* segments (cap %*)"):format(p6, v84, v91, t1.CAPS.rail_points), 0)
                end

                local v92 = table.create(v90)
                local v93 = buffer.create(v90)

                for j = 1, v90 do
                    local v94 = native[j]

                    v92[j] = v94
                    buffer.writeu8(v93, j - 1, v94)
                end

                if buffer.readu32(v93, 24) ~= v91 then
                    error(("template %*: rail %* segment count"):format(p6, v84), 0)
                end

                for k = 0, v91 - 1 do
                    for n = 0, 1 do
                        local v95 = k * 120 + 28 + (if n == 0 then 80 else 96)
                        local v96 = buffer.readf32(v93, v95)
                        local v98 = buffer.readf32(v93, v95 + 4)
                        local v100 = buffer.readf32(v93, v95 + 8)

                        n2 = math.max(n2, v96 * v96 + v98 * v98 + v100 * v100)
                    end
                end

                t12[v84] = {
                    native = v92,
                    closed = v85.closed == true
                }
            else
                local points = v85.points

                if type(points) ~= "table" or #points < 2 or #points > t1.CAPS.rail_points then
                    error(("template %*: rail %* needs 2 .. %* points"):format(p6, v84, t1.CAPS.rail_points), 0)
                end

                local v86 = table.create(#points)

                for v87, v88 in points do
                    v86[v87] = {
                        fround(v88[1]),
                        fround(v88[2]),
                        fround(v88[3])
                    }
                    n2 = math.max(n2, v86[v87][1] ^ 2 + v86[v87][2] ^ 2 + v86[v87][3] ^ 2)
                end

                t12[v84] = {
                    points = v86,
                    closed = v85.closed == true
                }
            end

            v83 = n2
        end
    else
        v83 = n2
    end

    return (freeze_deep({
        kind = p6,
        count = v57,
        points = v58,
        surfaces = v60,
        flags = v74,
        cosines = v75,
        rails = t12,
        radius = math.sqrt(v83)
    }))
end

t1.compile = compile

function t1.templates_from_build_items(p9, p10) -- line: 326
    -- upvalues: import (copy), TriangleFeature (copy), t1 (copy)
    local v102 = (p10 or {}).max_triangles or t1.CAPS.piece_triangles
    local items = p9.records("items")
    local vertices = p9.stream("vertices")
    local corners = p9.stream("corners")
    local edges = p9.stream("edges")
    local surface = p9.stream("surface")
    local one_sided = p9.stream("one_sided")
    local rail_native = p9.stream("rail_native")
    local decode_native_edges = import("skate_game/skate_world").decode_native_edges
    local t13 = {}
    local t14 = {}

    for _, v103 in items do
        local v104 = v103.triangles[1] - 1
        local v105 = v103.triangles[2]
        local v106 = v103.vertices[1] - 1

        if v102 < v105 or #(v103.rails or {}) > t1.CAPS.piece_rails then
            table.insert(t14, {
                n = v103.n,
                name = v103.name,
                triangles = v105,
                rails = #(v103.rails or {})
            })
        else
            local v107 = table.create(v105)
            local v108 = table.create(v105)
            local v109 = table.create(v105)

            for i = v104, v104 + v105 - 1 do
                local v110 = table.create(3)

                for j = 0, 2 do
                    local v111 = (v106 + buffer.readu16(corners, (i * 3 + j) * 2)) * 12
                    local v112 = buffer.readf32(vertices, v111)
                    local v114 = buffer.readf32(vertices, v111 + 4)
                    local v115 = v111 + 8

                    v110[j + 1] = {
                        v112,
                        v114,
                        (buffer.readf32(vertices, v115))
                    }
                end

                local v116, v117

                if buffer.readu8(edges, i * 4 + 3) == 0 then
                    v117 = 481
                    v116 = { -1, -1, -1 }
                else
                    local v118 = buffer.readu8(edges, i * 4)
                    local v119 = buffer.readu8(edges, i * 4 + 1)
                    local v120

                    v120, v116 = decode_native_edges({
                        v118,
                        v119,
                        (buffer.readu8(edges, i * 4 + 2))
                    })
                    v117 = bit32.band(v120, (bit32.bnot(TriangleFeature.ONE_SIDED)))

                    if buffer.readu8(one_sided, i) ~= 0 then
                        v117 = bit32.bor(v117, TriangleFeature.ONE_SIDED)
                    end
                end

                local v122 = i - v104 + 1

                v107[v122] = v110
                v108[v122] = {
                    v117,
                    v116[1],
                    v116[2],
                    v116[3]
                }
                v109[v122] = buffer.readu16(surface, i * 2)
            end

            local t16 = {}

            for v123, v124 in v103.rails or {} do
                local v125 = table.create(v124.native)

                for k = 0, v124.native - 1 do
                    local v126 = v124.at + k

                    v125[k + 1] = buffer.readu8(rail_native, v126)
                end

                t16[v123] = {
                    native = v125,
                    closed = v124.closed
                }
            end

            t13[v103.n] = {
                keep_base = true,
                triangles = v107,
                edges = v108,
                surfaces = v109,
                rails = t16,
                name = v103.name,
                bounds = v103.bounds
            }
        end
    end

    return t13, t14
end

function t1.set_templates(p11) -- line: 382
    -- upvalues: t2 (copy), compile (copy)
    local t17 = {}

    for v127, v128 in p11 do
        t17[v127] = compile(v127, v128)
    end

    table.clear(t2)

    for v129, v130 in t17 do
        t2[v129] = v130
    end
end

local function snap(p12) -- line: 397
    if math.abs(p12) < 1E-12 then
        return 0
    end

    if math.abs(p12 - 1) < 1E-12 then
        return 1
    end

    if math.abs(p12 + 1) < 1E-12 then
        return -1
    end

    return p12
end

local function frame_of(p13) -- line: 407
    -- upvalues: rt (copy), t1 (copy)
    if type(p13) ~= "table" then
        return nil, "transform"
    end

    local v133, v134, v135, t18, t19, t20

    if p13.position ~= nil then
        local position, basis = p13.position, p13.basis

        if type(position) ~= "table" or type(basis) ~= "table" then
            return nil, "transform"
        end

        v133 = position[1]
        v134 = position[2]
        v135 = position[3]

        local v139 = basis[1]
        local v140 = basis[2]
        local v141 = basis[3]

        if type(v139) ~= "table" or type(v140) ~= "table" or type(v141) ~= "table" then
            return nil, "transform"
        end

        t18 = {
            v139[1],
            v139[2],
            v139[3]
        }
        t19 = {
            v140[1],
            v140[2],
            v140[3]
        }
        t20 = {
            v141[1],
            v141[2],
            v141[3]
        }
    else
        v133 = p13[1]
        v134 = p13[2]
        v135 = p13[3]

        local v136 = p13[4] or 0

        if type(v136) ~= "number" or not rt.is_finite(v136) then
            return nil, "transform"
        end

        local v137 = math.sin(v136)
        local v138 = math.cos(v136)

        t18 = { v138, 0, -v137 }
        t19 = { 0, 1, 0 }
        t20 = { v137, 0, v138 }
    end

    for _, v142 in { v133, v134, v135 } do
        if type(v142) ~= "number" or not rt.is_finite(v142) or math.abs(v142) > t1.CAPS.extent then
            return nil, "position"
        end
    end

    for _, v143 in { t18, t19, t20 } do
        for i = 1, 3 do
            if type(v143[i]) ~= "number" or not rt.is_finite(v143[i]) then
                return nil, "transform"
            end

            local v145 = v143[i]

            if math.abs(v145) < 1E-12 then
                v145 = 0
            elseif math.abs(v145 - 1) < 1E-12 then
                v145 = 1
            elseif math.abs(v145 + 1) < 1E-12 then
                v145 = -1
            end

            v143[i] = v145
        end
    end

    local function dot(p14, p15) -- line: 446
        return p14[1] * p15[1] + p14[2] * p15[2] + p14[3] * p15[3]
    end

    local v148 = t18[1] * (t19[2] * t20[3] - t19[3] * t20[2]) - t18[2] * (t19[1] * t20[3] - t19[3] * t20[1]) + t18[3] * (t19[1] * t20[2] - t19[2] * t20[1])

    if not (math.abs(dot(t18, t18) - 1) > 1E-04) and not (math.abs(dot(t19, t19) - 1) > 1E-04) and not (math.abs(dot(t20, t20) - 1) > 1E-04) and not (math.abs((dot(t18, t19))) > 1E-04) and not (math.abs((dot(t18, t20))) > 1E-04) and not (math.abs((dot(t19, t20))) > 1E-04) and not (math.abs(v148 - 1) > 1E-04) then
        return {
            t18[1],
            t18[2],
            t18[3],
            t19[1],
            t19[2],
            t19[3],
            t20[1],
            t20[2],
            t20[3],
            v133,
            v134,
            v135
        }
    end

    return nil, "not_rigid"
end

local function bake_native(p16, p17) -- line: 468
    -- upvalues: fround (copy)
    local v156 = #p16
    local v157 = buffer.create(v156)

    for i = 1, v156 do
        local v158 = p16[i]

        buffer.writeu8(v157, i - 1, v158)
    end

    local v159 = (v156 - 28) // 120

    local function turn(p18, p19, p20) -- line: 475
        -- upvalues: p17 (copy), fround (copy)
        return fround(p17[7] * p20 + (p17[4] * p19 + p17[1] * p18)), fround(p17[8] * p20 + (p17[5] * p19 + p17[2] * p18)), fround(p17[9] * p20 + (p17[6] * p19 + p17[3] * p18))
    end

    for i = 0, v159 - 1 do
        local v160 = i * 120 + 28

        for j = 0, 3 do
            local v161 = v160 + j * 16
            local v162 = buffer.readf32(v157, v161)
            local v163 = buffer.readf32(v157, v161 + 4)
            local v164 = buffer.readf32(v157, v161 + 8)
            local v165, v166, v167

            if j == 3 then
                v165 = fround(p17[7] * v164 + (p17[4] * v163 + (p17[1] * v162 + p17[10])))
                v166 = fround(p17[8] * v164 + (p17[5] * v163 + (p17[2] * v162 + p17[11])))
                v167 = fround(p17[9] * v164 + (p17[6] * v163 + (p17[3] * v162 + p17[12])))
            else
                v165, v166, v167 = turn(v162, v163, v164)
            end

            buffer.writef32(v157, v161, v165)
            buffer.writef32(v157, v161 + 4, v166)
            buffer.writef32(v157, v161 + 8, v167)
        end

        local t21 = {
            buffer.readf32(v157, v160 + 80),
            buffer.readf32(v157, v160 + 84),
            (buffer.readf32(v157, v160 + 88))
        }
        local t22 = {
            buffer.readf32(v157, v160 + 96),
            buffer.readf32(v157, v160 + 100),
            (buffer.readf32(v157, v160 + 104))
        }
        local n3 = 1e999
        local n4 = 1e999
        local n5 = 1e999
        local n6 = (-1e999)
        local n7 = (-1e999)
        local n8 = (-1e999)

        for k = 0, 7 do
            local v172 = if k % 2 == 0 then t21[1] else t22[1]
            local v173 = if k // 2 % 2 == 0 then t21[2] else t22[2]
            local v174 = if k // 4 == 0 then t21[3] else t22[3]
            local v175 = p17[7] * v174 + (p17[4] * v173 + (p17[1] * v172 + p17[10]))
            local v176 = p17[8] * v174 + (p17[5] * v173 + (p17[2] * v172 + p17[11]))
            local v177 = p17[9] * v174 + (p17[6] * v173 + (p17[3] * v172 + p17[12]))

            n3 = math.min(n3, v175)
            n4 = math.min(n4, v176)
            n5 = math.min(n5, v177)
            n6 = math.max(n6, v175)
            n7 = math.max(n7, v176)
            n8 = math.max(n8, v177)
        end

        local function down(p21) -- line: 510
            -- upvalues: fround (copy)
            local v178 = fround(p21)

            if not (p21 < v178) then
                return v178
            end

            return v178 - math.max(math.abs(v178) * 1.1920928955078125E-07, 1E-38)
        end

        local function up(p22) -- line: 514
            -- upvalues: fround (copy)
            local v180 = fround(p22)

            if not (v180 < p22) then
                return v180
            end

            return v180 + math.max(math.abs(v180) * 1.1920928955078125E-07, 1E-38)
        end

        local v182 = v160 + 80
        local v183 = fround(n3)

        if n3 < v183 then
            v183 -= math.max(math.abs(v183) * 1.1920928955078125E-07, 1E-38)
        end

        buffer.writef32(v157, v182, v183)

        local v185 = v160 + 84
        local v186 = fround(n4)

        if n4 < v186 then
            v186 -= math.max(math.abs(v186) * 1.1920928955078125E-07, 1E-38)
        end

        buffer.writef32(v157, v185, v186)

        local v188 = v160 + 88
        local v189 = fround(n5)

        if n5 < v189 then
            v189 -= math.max(math.abs(v189) * 1.1920928955078125E-07, 1E-38)
        end

        buffer.writef32(v157, v188, v189)

        local v191 = v160 + 96
        local v192 = fround(n6)

        if v192 < n6 then
            v192 += math.max(math.abs(v192) * 1.1920928955078125E-07, 1E-38)
        end

        buffer.writef32(v157, v191, v192)

        local v194 = v160 + 100
        local v195 = fround(n7)

        if v195 < n7 then
            v195 += math.max(math.abs(v195) * 1.1920928955078125E-07, 1E-38)
        end

        buffer.writef32(v157, v194, v195)

        local v197 = v160 + 104
        local v198 = fround(n8)

        if v198 < n8 then
            v198 += math.max(math.abs(v198) * 1.1920928955078125E-07, 1E-38)
        end

        buffer.writef32(v157, v197, v198)
    end

    local v200 = table.create(v156)

    for i = 1, v156 do
        v200[i] = buffer.readu8(v157, i - 1)
    end

    return v200
end

local function unique_header(p23, p24) -- line: 534
    local n9 = 342167472
    local n10 = 1939669891

    for i = 1, #p24 do
        local v202 = bit32.bxor(n10, string.byte(p24, i))
        local v203 = v202 * 435
        local v205 = math.floor(v203 / 4294967296)

        n10 = v203 % 4294967296
        n9 = (n9 * 435 + v205 + v202 * 256) % 4294967296
    end

    local v206 = table.clone(p23)

    for i = 0, 3 do
        local v207 = bit32.rshift(n10, i * 8)

        v206[i + 1] = bit32.band(v207, 255)

        local v208 = bit32.rshift(n9, i * 8)

        v206[i + 5] = bit32.band(v208, 255)
    end

    return v206
end

t1.unique_header = unique_header

local v209 = 2 * v2.THIN_MARGIN

local function bake(p25, p26, p27) -- line: 555
    -- upvalues: rt (copy), WorldTriangle (copy), Bounds (copy), Vector3 (copy), fround (copy), freeze_deep (copy), bake_native (copy), v209 (copy)
    local count, points = p26.count, p26.points
    local v210 = table.create(count)
    local v211 = table.create(count)
    local v212 = table.create(6 * count)
    local material, margin = p25.material, p25.margin
    local n11 = 1e999
    local n12 = 1e999
    local n13 = 1e999
    local n14 = (-1e999)
    local n15 = (-1e999)
    local n16 = (-1e999)

    for i = 1, count do
        local v213 = table.create(3)

        for j = 1, 3 do
            local v214 = (i - 1) * 9 + (j - 1) * 3
            local v215 = points[v214 + 1]
            local v216 = points[v214 + 2]
            local v217 = points[v214 + 3]

            v213[j] = Vector3.new(fround(p27[7] * v217 + (p27[4] * v216 + (p27[1] * v215 + p27[10]))), fround(p27[8] * v217 + (p27[5] * v216 + (p27[2] * v215 + p27[11]))), fround(p27[9] * v217 + (p27[6] * v216 + (p27[3] * v215 + p27[12]))))
        end

        local v218 = WorldTriangle.from_vertices(v213, material, p26.surfaces[i], p26.flags[i], rt.copy(p26.cosines[i]), 0)

        if v218 == nil then
            return nil, "degenerate"
        end

        local v219 = Bounds.from_points(v218.triangle.vertices)

        if margin < rt.fmax(rt.fmax(v219.max.x - v219.min.x, v219.max.y - v219.min.y), v219.max.z - v219.min.z) * v209 then
            return nil, "triangle_too_large"
        end

        freeze_deep(v218)
        freeze_deep(v219)
        v210[i] = v218
        v211[i] = v219

        local v220 = (i - 1) * 6
        local v221 = v220 + 2
        local v222 = v220 + 3
        local x, y, z = v219.min.x, v219.min.y, v219.min.z

        v212[v220 + 1] = x
        v212[v221] = y
        v212[v222] = z

        local v223 = v220 + 5
        local v224 = v220 + 6
        local x2, y2, z2 = v219.max.x, v219.max.y, v219.max.z

        v212[v220 + 4] = x2
        v212[v223] = y2
        v212[v224] = z2
        n11 = math.min(n11, v219.min.x)
        n12 = math.min(n12, v219.min.y)
        n13 = math.min(n13, v219.min.z)
        n14 = math.max(n14, v219.max.x)
        n15 = math.max(n15, v219.max.y)
        n16 = math.max(n16, v219.max.z)
    end

    local v225 = table.create(3 * count)

    for i = 1, count do
        for _, v226 in v210[i].triangle.vertices do
            table.insert(v225, v226)
        end
    end

    local v227

    if #p26.rails > 0 then
        v227 = table.create(#p26.rails)

        for v228, v229 in p26.rails do
            if v229.native ~= nil then
                v227[v228] = {
                    native = bake_native(v229.native, p27),
                    closed = v229.closed
                }
            else
                local v230 = table.create(#v229.points)

                for v231, v232 in v229.points do
                    local v233 = v232[1]
                    local v234 = v232[2]
                    local v235 = v232[3]

                    v230[v231] = {
                        fround(p27[7] * v235 + (p27[4] * v234 + (p27[1] * v233 + p27[10]))),
                        fround(p27[8] * v235 + (p27[5] * v234 + (p27[2] * v233 + p27[11]))),
                        fround(p27[9] * v235 + (p27[6] * v234 + (p27[3] * v233 + p27[12])))
                    }
                end

                v227[v228] = {
                    points = v230,
                    closed = v229.closed
                }
            end
        end
    end

    return {
        triangles = v210,
        bounds = v211,
        flat = v212,
        mesh_bounds = Bounds.from_points(v225),
        box = { n11, n12, n13, n14, n15, n16 },
        rails = v227
    }
end

local t23 = {}

t23.__index = t23

local function refs(p28) -- line: 638
    return p28.refs.engine, p28.refs.world, p28.refs.provider
end

local function cell_key(p29, p30) -- line: 642
    return (p29 + 2097152) * 4194304 + (p30 + 2097152)
end

local function cells_of(p31, p32) -- line: 647
    local t24 = {}

    for i = math.floor(p31[1] / p32), math.floor(p31[4] / p32) do
        for j = math.floor(p31[3] / p32), math.floor(p31[6] / p32) do
            table.insert(t24, (i + 2097152) * 4194304 + (j + 2097152))
        end
    end

    return t24
end

local function box_union(p33, p34) -- line: 657
    if p34 == nil then
        return p33
    end

    return {
        math.min(p33[1], p34[1]),
        math.min(p33[2], p34[2]),
        math.min(p33[3], p34[3]),
        math.max(p33[4], p34[4]),
        math.max(p33[5], p34[5]),
        (math.max(p33[6], p34[6]))
    }
end

local n17 = 0

local function candidates(p35, p36, _, p38, p39, _, p41, p42, p43) -- line: 669
    -- upvalues: t1 (copy), n17 (ref)
    local CELL = t1.CELL
    local v260 = math.floor(p36 / CELL)
    local v262 = math.floor(p39 / CELL)
    local v264 = math.floor(p38 / CELL)
    local v266 = math.floor(p41 / CELL)

    if v262 - v260 < t1.CELL_SCAN and v266 - v264 < t1.CELL_SCAN and (v262 - v260 + 1) * (v266 - v264 + 1) <= t1.CELL_SCAN then
        n17 += 1

        local v267 = n17
        local grid = p35.grid
        local n18 = 0

        for i = v260, v262 do
            for j = v264, v266 do
                local v268 = grid[(i + 2097152) * 4194304 + (j + 2097152)]

                if v268 ~= nil then
                    local v269 = n18

                    for _, v270 in v268 do
                        if v270.stamp ~= v267 and v270[p43] ~= nil then
                            v270.stamp = v267

                            local seq = v270.seq
                            local v271 = v269

                            while v271 >= 1 and seq < p42[v271].seq do
                                p42[v271 + 1] = p42[v271]
                                v271 -= 1
                            end

                            p42[v271 + 1] = v270
                            v269 += 1
                        end

                        n18 = v269
                    end
                end
            end
        end

        return n18
    end

    local n19 = 0

    for _, v272 in p35.live do
        if v272[p43] ~= nil then
            n19 += 1
            p42[n19] = v272
        end
    end

    return n19
end

local t25 = {}

local function meshes_into(p44, p45, p46, p47, p48, p49, p50, p51, p52) -- line: 713
    -- upvalues: candidates (copy), t25 (copy)
    if p44.live_count == 0 then
        return p52
    end

    local mesh = candidates(p44, p45, p46, p47, p48, p49, p50, t25, "mesh")
    local v273 = p52

    for i = 1, mesh do
        local v274 = t25[i]
        local box = v274.box

        if not (box[4] < p45
            or p48 < box[1]
            or box[5] < p46
            or p49 < box[2]
            or box[6] < p47
            or p50 < box[3]) then
            v273 += 1
            p51[v273] = v274.position
        end

        t25[i] = nil
    end

    return v273
end

local function pages_into(p53, p54, p55, p56, p57) -- line: 732
    local map_mesh_count = p53.map_mesh_count
    local v275 = p55

    while v275 > 0 and map_mesh_count <= p54[v275] do
        v275 -= 1
    end

    if v275 < p55 then
        local pages = p53.pages

        for i = v275 + 1, p55 do
            p56[i] = pages[p54[i]]
        end
    end

    if p57 then
        for i = 1, v275 do
            p56[i] = nil
        end
    end

    return v275
end

local function rails_into(p58, p59, p60) -- line: 753
    -- upvalues: import (copy), candidates (copy), t25 (copy)
    if p58.rail_objects == 0 then
        return
    end

    local Octree, Bounds = import("skate_game/grind_world/octree").Octree, import("skate_game/grind_world/octree").Bounds

    for i = 1, candidates(p58, p59.min[1], p59.min[2], p59.min[3], p59.max[1], p59.max[2], p59.max[3], t25, "rail") do
        local v276 = t25[i]

        t25[i] = nil

        if #p60 < 40 then
            local asset = v276.rail.asset

            if Bounds.overlaps(asset.bounds, p59) then
                for _, v277 in Octree.query(asset.tree, p59, 40 - #p60) do
                    table.insert(p60, asset.indices[v277 + 1])
                end
            end
        end
    end
end

local function plain_meta(p61, p62) -- line: 776
    -- upvalues: packed (copy)
    if not packed.is_view(p61) and getmetatable(p61) == nil and not table.isfrozen(p61) then
        setmetatable(p61, {
            __len = function() -- __len | line: 781
                -- upvalues: p62 (copy)
                return p62
            end,
            __iter = function(p63) -- __iter | line: 784
                -- upvalues: p62 (copy)
                local n20 = 0

                return function() -- line: 786
                    -- upvalues: p63 (copy), n20 (ref), p62 (copy)
                    n20 += 1

                    if n20 <= p62 then
                        local v279 = n20

                        return v279, (rawget(p63, n20))
                    end

                    return nil
                end
            end
        })
    end
end

local function write_object(p64, p65, p66) -- line: 797
    local _, world, _ = p64.refs.engine, p64.refs.world, p64.refs.provider
    local triangles, triangle_bounds = world.triangles, world.triangle_bounds
    local packed_surfaces = world.query_metadata.packed_surfaces
    local triangle_bounds_flat = world.triangle_bounds_flat
    local first, data = p65.first, p65.data

    for i = 1, p65.count do
        local v281 = first + i

        if p66 then
            rawset(triangles, v281, data.triangles[i])
            rawset(triangle_bounds, v281, data.bounds[i])
            rawset(packed_surfaces, v281, p65.surfaces[i])

            local v285 = 6 * (v281 - 1)
            local flat = data.flat
            local v286 = (i - 1) * 6

            rawset(triangle_bounds_flat, v285 + 1, flat[v286 + 1])
            rawset(triangle_bounds_flat, v285 + 2, flat[v286 + 2])
            rawset(triangle_bounds_flat, v285 + 3, flat[v286 + 3])
            rawset(triangle_bounds_flat, v285 + 4, flat[v286 + 4])
            rawset(triangle_bounds_flat, v285 + 5, flat[v286 + 5])
            rawset(triangle_bounds_flat, v285 + 6, flat[v286 + 6])
        else
            rawset(triangles, v281, nil)
            rawset(triangle_bounds, v281, nil)
            rawset(packed_surfaces, v281, nil)

            local v299 = 6 * (v281 - 1)

            rawset(triangle_bounds_flat, v299 + 1, nil)
            rawset(triangle_bounds_flat, v299 + 2, nil)
            rawset(triangle_bounds_flat, v299 + 3, nil)
            rawset(triangle_bounds_flat, v299 + 4, nil)
            rawset(triangle_bounds_flat, v299 + 5, nil)
            rawset(triangle_bounds_flat, v299 + 6, nil)

            local triangle_gp = rawget(world, "triangle_gp")
            local triangle_fp = rawget(world, "triangle_fp")
            local triangle_fp_old = rawget(world, "triangle_fp_old")

            if triangle_gp ~= nil then
                triangle_gp[v281] = nil
            end

            if triangle_fp ~= nil then
                triangle_fp[v281] = nil
            end

            if triangle_fp_old ~= nil then
                triangle_fp_old[v281] = nil
            end
        end
    end
end

local function prepare_world(p67) -- line: 838
    -- upvalues: v2 (copy), plain_meta (copy)
    if p67.prepared then
        return
    end

    local _, world, _ = p67.refs.engine, p67.refs.world, p67.refs.provider

    v2.triangle_super_bounds(world)

    local map_triangles = p67.map_triangles

    plain_meta(world.triangles, map_triangles)
    plain_meta(world.triangle_bounds, map_triangles)
    plain_meta(world.query_metadata.packed_surfaces, map_triangles)
    plain_meta(world.triangle_bounds_flat, 6 * map_triangles)
    p67.prepared = true
end

local function remount(p68) -- line: 854
    -- upvalues: write_object (copy), prepare_world (copy)
    if p68.live_count == 0 then
        return
    end

    p68.prepared = false
    prepare_world(p68)

    for _, v306 in p68.live do
        write_object(p68, v306, true)
    end
end

local IDENTITY = RetailAffineTransform.IDENTITY

local function rebuild_meshes(p69) -- line: 867
    local _, world, _ = p69.refs.engine, p69.refs.world, p69.refs.provider
    local map_meshes = p69.map_meshes
    local v307 = #map_meshes

    if p69.live_count == 0 then
        p69.pages = {}
        world.query_metadata.meshes = map_meshes
    else
        local v308 = table.create(v307 + p69.live_count)

        table.move(map_meshes, 1, v307, 1, v308)

        local t27 = {}

        for v309, v310 in p69.live do
            v308[v307 + v309] = v310.mesh
            v310.position = v307 + v309 - 1
            t27[v307 + v309 - 1] = v310.page
        end

        p69.pages = t27
        world.query_metadata.meshes = v308
    end
end

local function rebuild_rails(p70) -- line: 889
    local _, _, provider = p70.refs.engine, p70.refs.world, p70.refs.provider
    local rail_base = p70.rail_base
    local primitives, metadata, source_for_primitive, source_rail_indices = provider.primitives, provider.metadata, provider.source_for_primitive, provider.source_rail_indices

    for i = #primitives, rail_base + 1, -1 do
        primitives[i] = nil
        metadata[i] = nil

        if source_for_primitive ~= nil then
            source_for_primitive[i] = nil
        end

        if source_rail_indices ~= nil then
            source_rail_indices[i] = nil
        end
    end

    local n21 = 0

    for _, v311 in p70.live do
        local rail = v311.rail

        if rail ~= nil then
            n21 += 1

            local v312 = #primitives

            for v313, v314 in rail.primitives do
                primitives[v312 + v313] = v314
                metadata[v312 + v313] = rail.metadata[v313]

                if source_for_primitive ~= nil then
                    source_for_primitive[v312 + v313] = -1
                end

                if source_rail_indices ~= nil then
                    source_rail_indices[v312 + v313] = v314.owner - 1
                end
            end

            local indices = rail.asset.indices

            for j = 1, #rail.primitives do
                indices[j] = v312 + j - 1
            end
        end
    end

    p70.rail_objects = n21
end

local function grid_add(p71, p72) -- line: 929
    for _, v315 in p72.cells do
        local v316 = p71.grid[v315]

        if v316 == nil then
            v316 = {}
            p71.grid[v315] = v316
        end

        table.insert(v316, p72)
    end
end

local function grid_remove(p73, p74) -- line: 939
    for _, v317 in p74.cells do
        local v318 = p73.grid[v317]

        if v318 ~= nil then
            local v319 = table.find(v318, p74)

            if v319 ~= nil then
                table.remove(v318, v319)
            end

            if #v318 == 0 then
                p73.grid[v317] = nil
            end
        end
    end
end

local function skater_box(p75) -- line: 955
    -- upvalues: t1 (copy)
    local n22 = 1e999
    local n23 = 1e999
    local n24 = 1e999
    local n25 = (-1e999)
    local n26 = (-1e999)
    local n27 = (-1e999)

    local function add(p76) -- line: 958
        -- upvalues: n22 (ref), n23 (ref), n24 (ref), n25 (ref), n26 (ref), n27 (ref)
        if p76 == nil then
            return
        end

        for _, v320 in p76 do
            local v321 = v320.rates and v320.rates.position

            if v321 ~= nil then
                local v322 = n22
                local v323 = math.min(v322, v321.x)
                local v324 = n23
                local v325 = math.min(v324, v321.y)
                local v326 = n24
                local v327 = math.min(v326, v321.z)

                n22 = v323
                n23 = v325
                n24 = v327

                local v328 = n25
                local v329 = math.max(v328, v321.x)
                local v330 = n26
                local v331 = math.max(v330, v321.y)
                local v332 = n27
                local v333 = math.max(v332, v321.z)

                n25 = v329
                n26 = v331
                n27 = v333
            end
        end
    end

    add(p75.physics and p75.physics.board and p75.physics.board.bodies)
    add(p75.skater and p75.skater.skeleton and p75.skater.skeleton.bodies)

    local SKATER_PAD = t1.SKATER_PAD

    return {
        n22 - SKATER_PAD,
        n23 - SKATER_PAD,
        n24 - SKATER_PAD,
        n25 + SKATER_PAD,
        n26 + SKATER_PAD,
        n27 + SKATER_PAD
    }
end

local function boxes_overlap(p77, p78) -- line: 975
    return not (p77[4] < p78[1]
        or p77[1] > p78[4]
        or p77[5] < p78[2]
        or p77[2] > p78[5]
        or p77[6] < p78[3]
        or p77[3] > p78[6])
end

local function grinding_on(p79, p80) -- line: 978
    -- upvalues: t1 (copy)
    if p80.rail == nil then
        return false
    end

    local state_16 = p79.skater.player_input.physical.state.state_16

    if not (state_16 < t1.GRIND_STATES[1] or t1.GRIND_STATES[2] < state_16) then
        local bounds = p80.rail.asset.bounds

        for _, v334 in p79.physics.board.bodies do
            local position = v334.rates.position

            if position.x >= bounds.min[1] and position.x <= bounds.max[1] and position.y >= bounds.min[2] and position.y <= bounds.max[2] and position.z >= bounds.min[3] and position.z <= bounds.max[3] then
                return true
            end
        end
    end

    return false
end

local function insert(p81, p82, p83, p84) -- line: 997
    -- upvalues: rt (copy), import (copy), v2 (copy), t1 (copy), freeze_deep (copy), unique_header (copy), cells_of (copy), box_union (copy), write_object (copy), prepare_world (copy), IDENTITY (copy), grid_add (copy)
    local _, _, provider = p81.refs.engine, p81.refs.world, p81.refs.provider
    local v335 = #p84.triangles
    local next_triangle = p81.next_triangle

    p81.next_triangle = next_triangle + v335
    p81.seq += 1

    local template = p83.template
    local t28 = {
        stamp = 0,
        id = p82,
        kind = p83.kind,
        tint = p83.tint,
        seq = p81.seq,
        first = next_triangle,
        count = v335,
        data = p84,
        surfaces = template.surfaces,
        box = p84.box,
        mesh = freeze_deep({
            geometry = 0,
            rejection_flags = 0,
            matching_group = -1,
            pool = "Ground",
            triangle_range = {
                start = next_triangle,
                ["end"] = next_triangle + v335
            },
            local_to_world = rt.copy(IDENTITY),
            world_to_local = rt.copy(IDENTITY),
            local_bounds = p84.mesh_bounds
        })
    }
    local t29 = {
        triangle_bounds = p84.bounds
    }

    t28.page = {
        first = next_triangle,
        count = v335,
        flat = v2.flat_triangle_bounds(t29),
        blocks = v2.triangle_block_bounds(t29),
        supers = v2.triangle_super_bounds(t29)
    }

    local box = p84.box

    if p84.rails ~= nil and provider ~= nil then
        local v336 = table.create(#p84.rails)

        for v337, v338 in p84.rails do
            local v339 = ("object:%*:%*:%*"):format(p82, p81.seq, v337)

            v336[v337] = {
                name = v339,
                points = v338.points,
                closed = v338.closed,
                native = if v338.native == nil then nil else unique_header(v338.native, v339)
            }
        end

        local v340 = import("skate_game/grind_world").StaticProvider.authored(v336)
        local v341 = #provider.rail_guids

        for _, v342 in v340.rail_guids do
            table.insert(provider.rail_guids, v342)
        end

        local v343 = table.create(#v340.primitives)

        for v344, v345 in v340.primitives do
            local v346 = rt.copy(v345)

            v346.owner = v345.owner + v341
            v343[v344] = v346
        end

        local v347 = v340.assets[1]

        t28.rail = {
            primitives = v343,
            metadata = v340.metadata,
            asset = {
                source = v347.source,
                bounds = v347.bounds,
                indices = table.clone(v347.indices),
                tree = v347.tree
            }
        }

        local bounds = v347.bounds

        box = box_union(box, {
            bounds.min[1],
            bounds.min[2],
            bounds.min[3],
            bounds.max[1],
            bounds.max[2],
            bounds.max[3]
        })
    end

    t28.cells = cells_of(box, t1.CELL)
    prepare_world(p81)
    write_object(p81, t28, true)
    grid_add(p81, t28)
    table.insert(p81.live, t28)
    p81.live_count += 1
    p81.objects[p82] = t28
    p81.live_triangles += v335

    return t28
end

local function delete(p85, p86) -- line: 1078
    -- upvalues: write_object (copy), grid_remove (copy)
    write_object(p85, p86, false)
    grid_remove(p85, p86)

    local v348 = table.find(p85.live, p86)

    if v348 ~= nil then
        table.remove(p85.live, v348)
    end

    p85.live_count -= 1
    p85.live_triangles -= p86.count
    p85.objects[p86.id] = nil
end

function t1.attach(p87) -- line: 1094
    -- upvalues: rt (copy), BoardWorld (copy), v3 (copy), freeze_deep (copy), t23 (copy), meshes_into (copy), pages_into (copy), rails_into (copy), remount (copy)
    local physics = p87.physics
    local world = physics.world
    local v349 = v3.by_world[world]

    if v349 == nil then
        local grind_world = physics.grind_world
        local v350 = BoardWorld.query_metadata(world)
        local v351 = physics.settings and physics.settings.floor_material

        if v351 == nil then
            v351 = world.triangles[1].material
        end

        local v352 = setmetatable({
            rail_objects = 0,
            seq = 0,
            live_count = 0,
            live_triangles = 0,
            planned_count = 0,
            planned_triangles = 0,
            prepared = false,
            refs = setmetatable({
                engine = p87,
                world = world,
                provider = grind_world
            }, {
                __mode = "v"
            }),
            material = freeze_deep(rt.copy(v351)),
            margin = world.maximum_triangle_margin,
            map_triangles = #world.triangles,
            map_meshes = v350.meshes,
            map_mesh_count = #v350.meshes,
            next_triangle = #world.triangles,
            rail_base = if grind_world == nil then 0 else #grind_world.primitives,
            live = {},
            objects = {},
            pages = {},
            grid = {},
            planned = {},
            area = {},
            queue = {},
            stats = {
                flushes = 0,
                applied = 0,
                deferred = 0,
                refused = 0,
                last_flush_ms = 0,
                worst_flush_ms = 0
            },
            meshes_into = meshes_into,
            pages_into = pages_into,
            rails_into = rails_into,
            remount = remount
        }, t23)

        v3.by_world[world] = v352
        v3.by_index[world.query_index] = v352

        if grind_world ~= nil then
            v3.by_provider[grind_world] = v352
        end

        p87.objects = v352

        return v352
    end

    p87.objects = v349

    return v349
end

function t1.detach(p88) -- line: 1147
    -- upvalues: v3 (copy), rebuild_meshes (copy), rebuild_rails (copy), delete (copy)
    local engine, world, provider = p88.refs.engine, p88.refs.world, p88.refs.provider

    if world ~= nil and p88.live_count > 0 then
        for i = #p88.live, 1, -1 do
            delete(p88, p88.live[i])
        end

        rebuild_meshes(p88)

        if provider ~= nil then
            rebuild_rails(p88)
        end

        world.query_metadata.meshes = p88.map_meshes
    end

    if world ~= nil then
        v3.by_world[world] = nil
        v3.by_index[world.query_index] = nil
    end

    if provider ~= nil then
        v3.by_provider[provider] = nil
    end

    if engine ~= nil and engine.objects == p88 then
        engine.objects = nil
    end

    table.clear(p88.queue)
    table.clear(p88.planned)
    p88.detached = true
end

local function area_cells(p89) -- line: 1174
    -- upvalues: t1 (copy), cells_of (copy)
    return (cells_of(p89, t1.CAPS.area))
end

local function plan_box(p90, p91) -- line: 1177
    local v353 = p90.radius + 0.01

    return {
        p91[10] - v353,
        p91[11] - v353,
        p91[12] - v353,
        p91[10] + v353,
        p91[11] + v353,
        p91[12] + v353
    }
end

local function reserve(p92, p93, p94, p95) -- line: 1182
    for _, v354 in p93 do
        p92.area[v354] = (p92.area[v354] or 0) + p95 * p94

        if p92.area[v354] == 0 then
            p92.area[v354] = nil
        end
    end
end

local function fits(p96, p97, p98, p99) -- line: 1190
    -- upvalues: t1 (copy)
    for _, v355 in p97 do
        local v356 = p96.area[v355] or 0

        if p99 ~= nil and table.find(p99.cells, v355) then
            v356 -= p99.count
        end

        if v356 + p98 > t1.CAPS.area_triangles then
            return false
        end
    end

    return true
end

function t1.place(p100, p101, p102, p103, p104, p105) -- line: 1207
    -- upvalues: t1 (copy), t2 (copy), frame_of (copy), bake (copy), cells_of (copy), plan_box (copy), reserve (copy)
    if p100.detached then
        return false, "detached"
    end

    if p101 == nil then
        return false, "id"
    end

    if p100.planned[p101] ~= nil then
        return false, "exists"
    end

    local v357 = t2[p102]

    if v357 == nil then
        return false, "kind"
    end

    local v358, v359 = frame_of(p103)

    if v358 == nil then
        return false, v359
    end

    if p100.planned_count + 1 > t1.CAPS.objects then
        return false, "cap_objects"
    end

    if p100.planned_triangles + v357.count > t1.CAPS.total_triangles then
        return false, "cap_triangles"
    end

    local v361 = cells_of(plan_box(v357, v358), t1.CAPS.area)
    local count = v357.count
    local v362 = false
    local v363

    for _, v364 in v361 do
        if (p100.area[v364] or 0) + count > t1.CAPS.area_triangles then
            v363 = false
            v362 = true
            break
        end
    end

    if not v362 then
        v363 = true
    end

    if not v363 then
        return false, "cap_area"
    end

    local v365, v366 = bake(p100, v357, v358)

    if v365 == nil then
        return false, v366
    end

    local t34 = {
        kind = p102,
        template = v357,
        frame = v358,
        tint = p104,
        cells = v361,
        count = v357.count
    }

    p100.planned[p101] = t34
    p100.planned_count += 1
    p100.planned_triangles += v357.count
    reserve(p100, v361, v357.count, 1)
    table.insert(p100.queue, {
        op = "place",
        id = p101,
        plan = t34,
        data = v365,
        force = p105 and p105.force
    })

    return true
end

local function drop_queued(p106, p107) -- line: 1249
    local queue = p106.queue

    for i = #queue, 1, -1 do
        if queue[i].id == p107 then
            table.remove(queue, i)
        end
    end
end

function t1.remove(p108, p109) -- line: 1260
    -- upvalues: reserve (copy), drop_queued (copy)
    local v367 = p108.planned[p109]

    if v367 == nil then
        return false, "unknown"
    end

    p108.planned[p109] = nil
    p108.planned_count -= 1
    p108.planned_triangles -= v367.count
    reserve(p108, v367.cells, v367.count, -1)
    drop_queued(p108, p109)

    if p108.objects[p109] ~= nil then
        table.insert(p108.queue, {
            op = "remove",
            id = p109
        })
    end

    return true
end

function t1.move(p110, p111, p112, p113) -- line: 1277
    -- upvalues: t1 (copy), frame_of (copy), bake (copy), cells_of (copy), plan_box (copy), reserve (copy), fits (copy), drop_queued (copy)
    local v368 = p110.planned[p111]

    if v368 == nil then
        return false, "unknown"
    end

    local v369, v370 = frame_of(p112)

    if v369 == nil then
        return false, v370
    end

    local v372 = cells_of(plan_box(v368.template, v369), t1.CAPS.area)

    if not fits(p110, v372, v368.count, v368) then
        return false, "cap_area"
    end

    local v373, v374 = bake(p110, v368.template, v369)

    if v373 == nil then
        return false, v374
    end

    reserve(p110, v368.cells, v368.count, -1)
    reserve(p110, v372, v368.count, 1)

    local t37 = {
        kind = v368.kind,
        template = v368.template,
        frame = v369,
        tint = v368.tint,
        cells = v372,
        count = v368.count
    }

    p110.planned[p111] = t37
    drop_queued(p110, p111)

    local v375 = if p110.objects[p111] == nil then "place" else "move"

    table.insert(p110.queue, {
        op = v375,
        id = p111,
        plan = t37,
        data = v373,
        force = p113 and p113.force
    })

    return true
end

function t1.clear(p114) -- line: 1306
    -- upvalues: t1 (copy)
    local t39 = {}

    for v376 in p114.planned do
        table.insert(t39, v376)
    end

    for _, v377 in t39 do
        t1.remove(p114, v377)
    end

    return #t39
end

function t1.flush(p115) -- line: 1318
    -- upvalues: rebuild_meshes (copy), rebuild_rails (copy), skater_box (copy), grinding_on (copy), insert (copy), delete (copy)
    if p115.detached or #p115.queue == 0 then
        return 0, 0
    end

    local elapsed = os.clock()
    local engine, world, provider = p115.refs.engine, p115.refs.world, p115.refs.provider

    if world ~= nil and engine ~= nil and engine.physics.world == world then
        local t40 = {}
        local t41 = {}
        local n28 = 0
        local n29 = 0
        local v379 = false
        local v380 = false
        local v378

        for _, v381 in p115.queue do
            local id = v381.id

            if t40[id] then
                table.insert(t41, v381)
                n29 += 1
            else
                local v382 = p115.objects[id]

                if v381.op ~= "remove" and v381.op ~= "move" or v382 == nil then
                    if v381.op ~= "place" and v381.op ~= "move" or v381.force then
                        if v382 ~= nil and (v381.op == "remove" or v381.op == "move") then
                            if v382.rail ~= nil then
                                v380 = true
                            end

                            v379 = true
                            delete(p115, v382)
                        end

                        if (v381.op == "place" or v381.op == "move") and p115.objects[id] == nil then
                            if insert(p115, id, v381.plan, v381.data).rail ~= nil then
                                v380 = true
                            end

                            v379 = true
                        end

                        n28 += 1
                    else
                        v378 = v378 or skater_box(engine)

                        local box = v381.data.box

                        if not (v378[4] < box[1]
                            or v378[1] > box[4]
                            or v378[5] < box[2]
                            or v378[2] > box[5]
                            or v378[6] < box[3]
                            or v378[3] > box[6]) then
                            t40[id] = true
                            table.insert(t41, v381)
                            n29 += 1
                        else
                            if v382 ~= nil and (v381.op == "remove" or v381.op == "move") then
                                if v382.rail ~= nil then
                                    v380 = true
                                end

                                v379 = true
                                delete(p115, v382)
                            end

                            if (v381.op == "place" or v381.op == "move") and p115.objects[id] == nil then
                                if insert(p115, id, v381.plan, v381.data).rail ~= nil then
                                    v380 = true
                                end

                                v379 = true
                            end

                            n28 += 1
                        end
                    end
                elseif grinding_on(engine, v382) then
                    t40[id] = true
                    table.insert(t41, v381)
                    n29 += 1
                elseif v381.op ~= "place" and v381.op ~= "move" or v381.force then
                    if v382 ~= nil and (v381.op == "remove" or v381.op == "move") then
                        if v382.rail ~= nil then
                            v380 = true
                        end

                        v379 = true
                        delete(p115, v382)
                    end

                    if (v381.op == "place" or v381.op == "move") and p115.objects[id] == nil then
                        if insert(p115, id, v381.plan, v381.data).rail ~= nil then
                            v380 = true
                        end

                        v379 = true
                    end

                    n28 += 1
                else
                    v378 = v378 or skater_box(engine)

                    local box = v381.data.box

                    if not (v378[4] < box[1]
                        or v378[1] > box[4]
                        or v378[5] < box[2]
                        or v378[2] > box[5]
                        or v378[6] < box[3]
                        or v378[3] > box[6]) then
                        t40[id] = true
                        table.insert(t41, v381)
                        n29 += 1
                    else
                        if v382 ~= nil and (v381.op == "remove" or v381.op == "move") then
                            if v382.rail ~= nil then
                                v380 = true
                            end

                            v379 = true
                            delete(p115, v382)
                        end

                        if (v381.op == "place" or v381.op == "move") and p115.objects[id] == nil then
                            if insert(p115, id, v381.plan, v381.data).rail ~= nil then
                                v380 = true
                            end

                            v379 = true
                        end

                        n28 += 1
                    end
                end
            end
        end

        p115.queue = t41

        if v379 then
            rebuild_meshes(p115)
        end

        if v380 and provider ~= nil then
            rebuild_rails(p115)
        end

        local stats = p115.stats

        stats.flushes += 1
        stats.applied += n28
        stats.deferred = n29

        local v383 = (os.clock() - elapsed) * 1000

        stats.last_flush_ms = v383
        stats.worst_flush_ms = math.max(stats.worst_flush_ms, v383)

        return n28, n29
    end

    p115.stats.stale = true

    return 0, #p115.queue
end

function t1.before_frame(p116) -- line: 1395
    -- upvalues: t1 (copy)
    local objects = p116.objects

    if objects == nil then
        return 0, 0
    end

    return t1.flush(objects)
end

function t1.status(p117) -- line: 1403
    local n30 = 0

    for _, v384 in p117.live do
        if v384.rail ~= nil then
            n30 += #v384.rail.primitives
        end
    end

    return {
        objects = p117.live_count,
        triangles = p117.live_triangles,
        rail_primitives = n30,
        planned = p117.planned_count,
        planned_triangles = p117.planned_triangles,
        queued = #p117.queue,
        deferred = p117.stats.deferred,
        next_triangle = p117.next_triangle,
        map_triangles = p117.map_triangles,
        map_meshes = p117.map_mesh_count,
        flushes = p117.stats.flushes,
        last_flush_ms = p117.stats.last_flush_ms,
        worst_flush_ms = p117.stats.worst_flush_ms,
        detached = p117.detached == true
    }
end

function t1.object(p118, p119) -- line: 1429
    return p118.objects[p119]
end

t23.place = t1.place
t23.remove = t1.remove
t23.move = t1.move
t23.clear = t1.clear
t23.flush = t1.flush
t23.status = t1.status
t23.detach = t1.detach
t23.object = t1.object

function t1.baked(p120, p121, p122) -- line: 1445
    -- upvalues: t2 (copy), frame_of (copy), bake (copy)
    local v385 = t2[p121]
    local v387 = assert(bake(p120, v385, (assert(frame_of(p122)))))

    return v387.triangles, v385.surfaces, v387.rails, v387.mesh_bounds
end

return t1
