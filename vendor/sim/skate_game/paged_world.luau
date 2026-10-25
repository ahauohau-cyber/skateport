-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_from_bits(p1) -- line: 7
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p1)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local packed = require(sim.packed)
local t1 = {}
local Vector3 = import("skate_core/math").Vector3
local v2 = import("skate_core/physics/board_world")
local v3 = import("skate_core/physics/board_world/query_index")
local v4 = import("skate_core/physics/board_world/query_metadata")
local v5 = import("skate_core/physics/board_world/broadphase")
local TriangleFeature = import("skate_core/physics/collision").TriangleFeature
local RetailAffineTransform = import("skate_core/physics/drive_frames").RetailAffineTransform
local v6 = import("skate_data/retail_collision")
local Bounds = v4.Bounds
local WorldTriangle = v2.WorldTriangle
local BLOCK, SUPER = v5.BLOCK, v5.SUPER
local v7 = table.create(256, 0)

for i = 1, 64 do
    v7[string.byte("ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/", i) + 1] = i - 1
end

local function decode_base64(p2, p3) -- line: 65
    -- upvalues: v7 (copy)
    local v8 = buffer.create(p3 + 3)
    local n1 = 0

    for i = 1, #p2, 4 do
        local v10, v11, v12, v13 = string.byte(p2, i, i + 3)
        local v14 = v7[v10 + 1] * 262144 + v7[v11 + 1] * 4096 + v7[v12 + 1] * 64 + v7[v13 + 1]

        buffer.writeu8(v8, n1, (bit32.rshift(v14, 16)))
        buffer.writeu8(v8, n1 + 1, (bit32.band(bit32.rshift(v14, 8), 255)))
        buffer.writeu8(v8, n1 + 2, (bit32.band(v14, 255)))
        n1 += 3
    end

    return v8
end

local function index_node(p4) -- line: 79
    -- upvalues: sim (copy)
    local sim_data = sim.Parent:FindFirstChild("sim_data")
    local maps = sim_data and sim_data:FindFirstChild("maps")
    local v21 = maps and maps:FindFirstChild(p4)

    if v21 == nil or v21:IsA("ModuleScript") then
        return v21
    end

    return v21:FindFirstChild("init") or v21:FindFirstChild("index")
end

function t1.data_index(p5) -- line: 90
    -- upvalues: index_node (copy)
    local v22 = index_node(p5)

    if v22 == nil then
        return nil
    end

    return require(v22)
end

function t1.is_paged(p6) -- line: 99
    -- upvalues: index_node (copy)
    local v23 = index_node(p6)

    if v23 == nil then
        return false
    end

    local v24 = require(v23)

    if v24.format == 2 then
        return v24.paged ~= nil
    end

    return false
end

local function lazy_array(p7) -- line: 109
    local t2 = {}

    return (setmetatable(t2, {
        __index = function(_, p9) -- __index | line: 112
            -- upvalues: p7 (copy), t2 (copy)
            if type(p9) ~= "number" then
                return nil
            end

            p7(t2, p9)

            return (rawget(t2, p9))
        end
    }))
end

local function reference_world(p10, p11) -- line: 124
    -- upvalues: sim (copy), rt (copy), v1 (copy), import (copy), packed (copy), Vector3 (copy), v3 (copy), v5 (copy), TriangleFeature (copy), RetailAffineTransform (copy), v6 (copy), Bounds (copy), WorldTriangle (copy), BLOCK (copy), SUPER (copy), decode_base64 (copy), index_node (copy), lazy_array (copy)
    local v25 = index_node(p10)
    local v26 = require(v25)
    local paged = v26.paged
    local pages = v25:FindFirstChild("pages") or v25.Parent and v25.Parent:FindFirstChild("pages")

    if pages == nil then
        error(("sim_data %*: paged data without a \"pages\" folder"):format(p10), 0)
    end

    local function page_module(p12) -- line: 132
        -- upvalues: p10 (copy), pages (copy)
        local v27 = pages:FindFirstChild(p12)

        if v27 == nil then
            error(("sim_data %*: missing page module \"%*\""):format(p10, p12), 0)
        end

        return require(v27)
    end

    if v26.no_twin then
        error(("sim_data %*: the reference twin's data was left out (tools/compress_map_data.py --drop-twin)"):format(p10), 0)
    end

    local v28 = decode_base64

    if v26.compressed == "zstd" then
        local zdata = require(sim.zdata)

        v28 = function(p13, p14) -- line: 146
            -- upvalues: zdata (copy)
            return zdata.unpack(p13, p14, 3)
        end
    end

    local triangle_count = v26.triangle_count
    local cluster_count = paged.cluster_count
    local paged_clusters = v26.stream("paged_clusters")
    local paged_cluster_bounds = v26.stream("paged_cluster_bounds")
    local paged_masks = v26.stream("paged_masks")
    local paged_meshes = v26.records("paged_meshes")
    local paged_supers = v26.stream("paged_supers")
    local v29 = table.create(cluster_count)
    local v30 = table.create(cluster_count)

    for i = 0, cluster_count - 1 do
        local v31 = buffer.readu32(paged_clusters, i * 32 + 16)
        local v32 = buffer.readu32(paged_clusters, i * 32 + 20)
        local v33 = i * 24

        v30[i + 1] = v31
        v29[i + 1] = {
            geometry = 0,
            rejection_flags = 0,
            pool = "Ground",
            triangle_range = {
                start = v31,
                ["end"] = v31 + v32
            },
            local_to_world = rt.copy(RetailAffineTransform.IDENTITY),
            world_to_local = rt.copy(RetailAffineTransform.IDENTITY),
            local_bounds = {
                min = Vector3.new(buffer.readf32(paged_cluster_bounds, v33), buffer.readf32(paged_cluster_bounds, v33 + 4), (buffer.readf32(paged_cluster_bounds, v33 + 8))),
                max = Vector3.new(buffer.readf32(paged_cluster_bounds, v33 + 12), buffer.readf32(paged_cluster_bounds, v33 + 16), (buffer.readf32(paged_cluster_bounds, v33 + 20)))
            },
            matching_group = buffer.readu32(paged_clusters, i * 32 + 28)
        }
    end

    local t6 = {
        built = 0,
        stamp = 0,
        in_tick = false,
        map = p10,
        pages = {},
        cap = paged.cap or 60000,
        bundles = {},
        stats = {
            loads = 0,
            evictions = 0,
            load_seconds = 0,
            loads_in_tick = 0,
            bundle_loads = 0
        },
        cluster_count = cluster_count,
        meshes = v29
    }

    local function cluster_of(p15) -- line: 195
        -- upvalues: cluster_count (copy), v30 (copy)
        local n2 = 1
        local v39 = cluster_count

        while n2 < v39 do
            local v40 = (n2 + v39 + 1) // 2

            if v30[v40] <= p15 then
                n2 = v40
            else
                v39 = v40 - 1
            end
        end

        return n2
    end

    local v41, v42
    local n3 = 0
    local n4 = 0

    local function evict() -- line: 211
        -- upvalues: v30 (copy), t6 (copy), v41 (ref), v42 (ref), n3 (ref), n4 (ref)
        while true do
            if t6.built > t6.cap then
                local n5 = 1e999
                local n6 = 0
                local v43

                for v44, v45 in t6.pages do
                    n6 += 1

                    if v45.stamp < n5 then
                        v43 = v44
                        n5 = v45.stamp
                    end
                end

                if v43 == nil or n6 <= 1 then
                    break
                end

                local v46 = t6.pages[v43]

                t6.pages[v43] = nil

                if v46 == v42 then
                    v42 = nil
                    n3 = 0
                    n4 = 0
                end

                t6.built -= v46.count
                t6.stats.evictions += 1

                local v47 = v30[v43]

                for i = 6 * v47 + 1, 6 * (v47 + v46.count) do
                    rawset(v41, i, nil)
                end

                continue
            end

            return
        end
    end

    local decode_native_edges = import("skate_game/skate_world").decode_native_edges

    local function load_page(p16) -- line: 239
        -- upvalues: p10 (copy), p11 (copy), paged (copy), pages (copy), v28 (ref), paged_clusters (copy), paged_masks (copy), paged_meshes (copy), v30 (copy), t6 (copy), v41 (ref), evict (copy), decode_native_edges (copy), rt (copy), v1 (copy), packed (copy), Vector3 (copy), TriangleFeature (copy), v6 (copy), Bounds (copy), WorldTriangle (copy)
        local elapsed = os.clock()
        local v49 = (p16 - 1) * 32
        local v50 = buffer.readu32(paged_clusters, v49)
        local v52 = buffer.readu32(paged_clusters, v49 + 4)
        local v54 = buffer.readu32(paged_clusters, v49 + 8)
        local v56 = buffer.readu32(paged_clusters, v49 + 12)
        local v58 = buffer.readu32(paged_clusters, v49 + 20)
        local v60 = buffer.readu32(paged_clusters, v49 + 24)
        local v61 = t6.bundles[v52]
        local v62

        if v61 ~= nil then
            v62 = v61
        else
            local v63 = v28
            local v64 = string.format("bundle_%04d", v52)
            local v65 = pages:FindFirstChild(v64)

            if v65 == nil then
                error(("sim_data %*: missing page module \"%*\""):format(p10, v64), 0)
            end

            v62 = v63(require(v65), paged.bundle_bytes[v52])
            t6.bundles[v52] = v62
            t6.stats.bundle_loads += 1
        end

        local v66 = table.create(v56)

        for i = 1, v56 do
            v66[i] = buffer.readu8(v62, v54 + i - 1)
        end

        local v68 = paged_meshes[v50 + 1]
        local decode_cluster = v6.decode_cluster

        buffer.writeu32(v1, 0, v68.granularity_bits)

        local v69 = decode_cluster(v66, buffer.readf32(v1, 0), v68.group_width, v68.surface_width, v68.one_sided)
        local v70 = table.create(v58)
        local v71 = table.create(v58)
        local v72 = table.create(v58)
        local n7 = 0

        for v73, v74 in v69 do
            if v60 == 4294967295 then
                local v75, v76

                if v74.edges ~= nil then
                    local v77

                    v77, v75 = decode_native_edges(v74.edges)
                    v76 = bit32.band(v77, (bit32.bnot(TriangleFeature.ONE_SIDED)))

                    if v74.one_sided then
                        v76 = bit32.bor(v76, TriangleFeature.ONE_SIDED)
                    end
                else
                    v75 = {
                        -1, -1, -1
                    }
                    v76 = 481
                end

                local points = v74.points
                local v79 = WorldTriangle.from_vertices({
                    Vector3.new(points[1][1], points[1][2], points[1][3]),
                    Vector3.new(points[2][1], points[2][2], points[2][3]),
                    Vector3.new(points[3][1], points[3][2], points[3][3])
                }, rt.copy(p11), v74.surface, v76, v75, 0)

                if v79 == nil then
                    error("Invalid RWCM collision triangle", 0)
                end

                n7 += 1
                v70[n7] = v79
                v72[n7] = v74.surface

                local v80 = Bounds.from_points(v79.triangle.vertices)

                if v80 == nil then
                    v80 = {}
                    v80.min = Vector3.new((-1e999), (-1e999), (-1e999))
                    v80.max = Vector3.new(1e999, 1e999, 1e999)
                end

                v71[n7] = v80
            else
                local v81 = v73 - 1

                if bit32.band(buffer.readu8(paged_masks, v60 + v81 // 8), (bit32.lshift(1, v81 % 8))) ~= 0 then
                    local v86, v87

                    if v74.edges ~= nil then
                        local v88

                        v88, v86 = decode_native_edges(v74.edges)
                        v87 = bit32.band(v88, (bit32.bnot(TriangleFeature.ONE_SIDED)))

                        if v74.one_sided then
                            v87 = bit32.bor(v87, TriangleFeature.ONE_SIDED)
                        end
                    else
                        v86 = {
                            -1, -1, -1
                        }
                        v87 = 481
                    end

                    local points = v74.points
                    local v90 = WorldTriangle.from_vertices({
                        Vector3.new(points[1][1], points[1][2], points[1][3]),
                        Vector3.new(points[2][1], points[2][2], points[2][3]),
                        Vector3.new(points[3][1], points[3][2], points[3][3])
                    }, rt.copy(p11), v74.surface, v87, v86, 0)

                    if v90 == nil then
                        error("Invalid RWCM collision triangle", 0)
                    end

                    n7 += 1
                    v70[n7] = v90
                    v72[n7] = v74.surface

                    local v91 = Bounds.from_points(v90.triangle.vertices)

                    if v91 == nil then
                        v91 = {}
                        v91.min = Vector3.new((-1e999), (-1e999), (-1e999))
                        v91.max = Vector3.new(1e999, 1e999, 1e999)
                    end

                    v71[n7] = v91
                end
            end
        end

        if n7 ~= v58 then
            error(("sim_data %*: cluster %* decoded %* triangles, the index says %*"):format(p10, p16, n7, v58), 0)
        end

        local v92 = v30[p16]

        for i = 1, v58 do
            local v93 = v71[i]
            local min, max = v93.min, v93.max
            local v94 = 6 * (v92 + i - 1)
            local v95 = v41

            rawset(v95, v94 + 1, min.x)
            rawset(v95, v94 + 2, min.y)
            rawset(v95, v94 + 3, min.z)
            rawset(v95, v94 + 4, max.x)
            rawset(v95, v94 + 5, max.y)
            rawset(v95, v94 + 6, max.z)
        end

        t6.stamp += 1

        local t7 = {
            triangles = packed.pack(v70, {
                cache = 256
            }),
            bounds = packed.pack(v71, {
                cache = 64
            }),
            surfaces = v72,
            count = v58,
            stamp = t6.stamp
        }

        t6.pages[p16] = t7
        t6.built += v58
        t6.stats.loads += 1

        if t6.in_tick then
            t6.stats.loads_in_tick += 1
        end

        t6.stats.load_seconds += os.clock() - elapsed

        if t6.built > t6.cap then
            evict()
        end

        return t7
    end

    local function page_of(p17) -- line: 342
        -- upvalues: v29 (copy), v30 (copy), t6 (copy), cluster_of (copy), v42 (ref), n3 (ref), n4 (ref), load_page (copy)
        if n3 <= p17 and p17 < n4 then
            return v42, p17 - n3 + 1
        end

        local v102 = cluster_of(p17)
        local v103 = t6.pages[v102]
        local v104 = v103 == nil
        local v105, v106

        if v104 then
            v105 = load_page(v102)
            v106 = t6.pages[v102] == nil
        else
            t6.stamp += 1
            v103.stamp = t6.stamp
        end

        if (not v104 or v106) and v104 then
            return v105, p17 - v30[v102] + 1
        end

        if not v104 then
            v105 = v103
        end

        local v107 = v30[v102]
        local v108 = v29[v102].triangle_range["end"]

        v42 = v105
        n3 = v107
        n4 = v108

        return v105, p17 - n3 + 1
    end

    v41 = lazy_array(function(_, p19) -- line: 361
        -- upvalues: page_of (copy)
        page_of((p19 - 1) // 6)
    end)

    local blocks_per_module = paged.blocks_per_module
    local v109 = (triangle_count + BLOCK - 1) // BLOCK
    local v110 = lazy_array(function(p20, p21) -- line: 368
        -- upvalues: p10 (copy), pages (copy), v28 (ref), blocks_per_module (copy), v109 (copy)
        local v111 = (p21 - 1) // 6 // blocks_per_module
        local v112 = v111 * blocks_per_module
        local v114 = math.min(blocks_per_module, v109 - v112)
        local v115 = v28
        local v116 = string.format("blocks_%04d", v111 + 1)
        local v117 = pages:FindFirstChild(v116)

        if v117 == nil then
            error(("sim_data %*: missing page module \"%*\""):format(p10, v116), 0)
        end

        local v118 = v115(require(v117), v114 * 24)

        for i = 0, v114 * 6 - 1 do
            rawset(p20, v112 * 6 + i + 1, (buffer.readf32(v118, i * 4)))
        end
    end)
    local v121 = (v109 + SUPER // BLOCK - 1) // (SUPER // BLOCK)
    local v122 = table.create(6 * v121, 0)

    for i = 0, 6 * v121 - 1 do
        v122[i + 1] = buffer.readf32(paged_supers, i * 4)
    end

    local t8 = {
        paged = t6,
        count = triangle_count
    }

    local function view(p22) -- line: 384
        -- upvalues: triangle_count (copy), page_of (copy), t8 (copy)
        return (setmetatable({}, {
            __index = function(_, p24) -- __index | line: 386
                -- upvalues: p22 (copy), triangle_count (copy), page_of (copy)
                if type(p24) ~= "number" or p24 < 1 or triangle_count < p24 or p24 % 1 ~= 0 then
                    return nil
                end

                local v123, v124 = page_of(p24 - 1)

                return p22(v123, v124)
            end,
            __len = function() -- __len | line: 393
                -- upvalues: triangle_count (copy)
                return triangle_count
            end,
            __newindex = function() -- __newindex | line: 396
                error("paged_world: this array is read-only", 0)
            end,
            __iter = function() -- __iter | line: 399
                -- upvalues: p22 (copy), triangle_count (copy), page_of (copy)
                local n8 = 0

                return function() -- line: 401
                    -- upvalues: n8 (ref), p22 (copy), triangle_count (copy), page_of (copy)
                    n8 += 1

                    if n8 <= triangle_count then
                        local v125, v126 = page_of(n8 - 1)

                        return n8, p22(v125, v126)
                    end

                    return nil
                end
            end,
            store = t8
        }))
    end

    local t11 = {
        external = nil,
        maximum_fatness = 0,
        triangles = view(function(p25, p26) -- line: 413
            -- upvalues: packed (copy)
            return packed.get(p25.triangles, p26)
        end),
        triangle_bounds = view(function(p27, p28) -- line: 416
            -- upvalues: packed (copy)
            return packed.get(p27.bounds, p28)
        end),
        query_metadata = {
            island_flags = 0,
            packed_surfaces = view(function(p29, p30) -- line: 419
                return p29.surfaces[p30]
            end),
            meshes = v29,
            static_edges = {}
        },
        query_index = v3.QueryIndex.new(v29),
        maximum_triangle_margin = rt.fmax(0, paged.max_span * (2 * v5.THIN_MARGIN)),
        contacts = {},
        buffer = {
            count = 0,
            flushed = 0,
            capacity = 0,
            dropped = 0,
            distance_squared_threshold = 0,
            allow_flush = 1,
            deferred_reduction = 0,
            full = 0,
            records = rt.filled(50, table.create(64, 0))
        },
        triangle_bounds_flat = v41,
        triangle_block_bounds = v110,
        triangle_super_bounds = v122,
        paged = t6
    }

    function t6.prefetch(p31, p32, p33, p34, p35) -- line: 461
        -- upvalues: cluster_count (copy), v29 (copy), t6 (copy), load_page (copy)
        local elapsed = os.clock()
        local t12 = {}

        for i = 1, cluster_count do
            if t6.pages[i] == nil then
                local local_bounds = v29[i].local_bounds
                local v129 = math.max(local_bounds.min.x - p31, 0, p31 - local_bounds.max.x)
                local v132 = math.max(local_bounds.min.y - p32, 0, p32 - local_bounds.max.y)
                local v135 = math.max(local_bounds.min.z - p33, 0, p33 - local_bounds.max.z)
                local v136 = v129 * v129 + v132 * v132 + v135 * v135

                if v136 <= p34 * p34 then
                    table.insert(t12, {
                        i,
                        v136
                    })
                end
            end
        end

        table.sort(t12, function(p36, p37) -- line: 476
            return p36[2] < p37[2]
        end)

        local v137 = #t12

        for _, v138 in t12 do
            if p35 ~= nil and p35 <= os.clock() - elapsed and v137 < #t12 then
                break
            end

            load_page(v138[1])
            v137 -= 1
        end

        return v137
    end

    function t6.loaded() -- line: 489
        -- upvalues: t6 (copy)
        local n9 = 0

        for _ in t6.pages do
            n9 += 1
        end

        return n9, t6.built
    end

    return t11
end

local readu8, readu16, readu32, writeu16 = buffer.readu8, buffer.readu16, buffer.readu32, buffer.writeu16
local writeu32, _, readf32, band = buffer.writeu32, buffer.writef32, buffer.readf32, bit32.band
local byteswap = bit32.byteswap

buffer.create(8)

local fround, from_bits, to_i32 = rt.fround, rt.from_bits, rt.to_i32
local ONE_SIDED = TriangleFeature.ONE_SIDED
local v139 = SUPER // BLOCK

local function decode_slice(p38, p39, p40) -- line: 539
    -- upvalues: v7 (copy), writeu32 (copy), byteswap (copy)
    local v140 = p39 // 3
    local v141 = (p39 + p40 + 2) // 3
    local v142 = p39 - v140 * 3
    local v143 = buffer.create((v141 - v140) * 3 + 8)
    local v144 = v140 * 4 + 1
    local v145 = v141 * 4
    local n10 = 0

    while v144 + 15 <= v145 do
        local v147, v148, v149, v150, v151, v152, v153, v154, v155, v156, v157, v158, v159, v160, v161, v162 = string.byte(p38, v144, v144 + 15)

        writeu32(v143, n10, (byteswap((v7[v147 + 1] * 262144 + v7[v148 + 1] * 4096 + v7[v149 + 1] * 64 + v7[v150 + 1]) * 256)))
        writeu32(v143, n10 + 3, (byteswap((v7[v151 + 1] * 262144 + v7[v152 + 1] * 4096 + v7[v153 + 1] * 64 + v7[v154 + 1]) * 256)))
        writeu32(v143, n10 + 6, (byteswap((v7[v155 + 1] * 262144 + v7[v156 + 1] * 4096 + v7[v157 + 1] * 64 + v7[v158 + 1]) * 256)))
        writeu32(v143, n10 + 9, (byteswap((v7[v159 + 1] * 262144 + v7[v160 + 1] * 4096 + v7[v161 + 1] * 64 + v7[v162 + 1]) * 256)))
        n10 += 12
        v144 += 16
    end

    while v144 <= v145 do
        local v175, v176, v177, v178 = string.byte(p38, v144, v144 + 3)

        writeu32(v143, n10, (byteswap((v7[v175 + 1] * 262144 + v7[v176 + 1] * 4096 + v7[v177 + 1] * 64 + v7[v178 + 1]) * 256)))
        n10 += 3
        v144 += 4
    end

    if v142 == 0 then
        return v143
    end

    local v181 = buffer.create(p40 + 8)

    buffer.copy(v181, 0, v143, v142, p40)

    return v181
end

t1.decode_slice = decode_slice

local function cut_slice(p41, p42, p43, p44) -- line: 578
    local v182 = p43 // 3
    local v183 = (p43 + p44 + 2) // 3

    if p43 - v182 * 3 == 0 then
        local v184 = buffer.create((v183 - v182) * 3 + 8)

        buffer.copy(v184, 0, p41, p43, math.min(v183 * 3, p42) - p43)

        return v184
    end

    local v186 = buffer.create(p44 + 8)

    buffer.copy(v186, 0, p41, p43, p44)

    return v186
end

t1.cut_slice = cut_slice
t1.BUNDLE_CACHE = 48

local function freeze_deep(p45) -- line: 595
    -- upvalues: freeze_deep (copy)
    if table.isfrozen(p45) then
        return p45
    end

    for _, v187 in p45 do
        if type(v187) == "table" then
            freeze_deep(v187)
        end
    end

    table.freeze(p45)

    return p45
end

t1.CAP_TRIANGLES = 250000
t1.HARD = 1.5
t1.TRIANGLE_CACHE = 4096
t1.REFERENCE = false

local function paged_world(p46, p47) -- line: 614
    -- upvalues: sim (copy), rt (copy), import (copy), t1 (copy), Vector3 (copy), v3 (copy), v5 (copy), RetailAffineTransform (copy), WorldTriangle (copy), BLOCK (copy), SUPER (copy), index_node (copy), readu8 (copy), readu16 (copy), readu32 (copy), writeu16 (copy), readf32 (copy), band (copy), byteswap (copy), fround (copy), from_bits (copy), to_i32 (copy), ONE_SIDED (copy), v139 (copy), decode_slice (copy), cut_slice (copy), freeze_deep (copy)
    local v188 = index_node(p46)
    local v189 = require(v188)
    local paged = v189.paged
    local pages = v188:FindFirstChild("pages") or v188.Parent and v188.Parent:FindFirstChild("pages")

    if pages == nil then
        error(("sim_data %*: paged data without a \"pages\" folder"):format(p46), 0)
    end

    local triangle_count = v189.triangle_count
    local cluster_count = paged.cluster_count
    local paged_clusters = v189.stream("paged_clusters")
    local paged_cluster_bounds = v189.stream("paged_cluster_bounds")
    local paged_masks = v189.stream("paged_masks")
    local paged_meshes = v189.records("paged_meshes")
    local v190 = table.create(cluster_count)
    local v191 = table.create(cluster_count + 1)
    local v192 = table.create(cluster_count)
    local v193 = table.create(cluster_count * 6)
    local v194 = cluster_count - 1
    local v195

    for i = 0, v194 do
        local v197 = readu32(paged_clusters, i * 32 + 16)
        local v199 = readu32(paged_clusters, i * 32 + 20)
        local v196 = i * 24

        v191[i + 1] = v197
        v192[i + 1] = v199

        local new

        for j = 0, 5 do
            new = i * 6 + j + 1
            v195 = v196 + j * 4
            v193[new] = readf32(paged_cluster_bounds, v195)
        end

        local v198 = i + 1
        local t14 = {
            geometry = 0,
            rejection_flags = 0,
            pool = "Ground",
            triangle_range = {
                start = v197,
                ["end"] = v197 + v199
            },
            local_to_world = rt.copy(RetailAffineTransform.IDENTITY),
            world_to_local = rt.copy(RetailAffineTransform.IDENTITY)
        }
        local t15 = {}

        t15.min = Vector3.new(readf32(paged_cluster_bounds, v196), readf32(paged_cluster_bounds, v196 + 4), (readf32(paged_cluster_bounds, v196 + 8)))
        new = Vector3.new
        v195 = v196 + 12
        t15.max = new(readf32(paged_cluster_bounds, v195), readf32(paged_cluster_bounds, v196 + 16), (readf32(paged_cluster_bounds, v196 + 20)))
        t14.local_bounds = t15
        t14.matching_group = readu32(paged_clusters, i * 32 + 28)
        v190[v198] = t14
    end

    v191[cluster_count + 1] = triangle_count

    local t16 = {
        version = 2,
        built = 0,
        held = 0,
        stamp = 0,
        in_tick = false,
        generation = 0,
        map = p46,
        pages = {},
        cap = paged.cap or t1.CAP_TRIANGLES,
        hard = paged.cap ~= nil,
        stats = {
            loads = 0,
            evictions = 0,
            load_seconds = 0,
            loads_in_tick = 0,
            bundle_loads = 0,
            worst_load = 0,
            records = 0
        },
        cluster_count = cluster_count,
        triangle_count = triangle_count,
        meshes = v190,
        starts = v191,
        counts = v192,
        box = v193
    }
    local t17 = {}

    local function bundle_text(p48) -- line: 681
        -- upvalues: p46 (copy), pages (copy), t16 (copy), t17 (copy)
        local v204 = t17[p48]
        local v205

        if v204 ~= nil then
            v205 = v204

            return v205
        end

        local v206 = string.format("bundle_%04d", p48)
        local v207 = pages:FindFirstChild(v206)

        if v207 == nil then
            error(("sim_data %*: missing page module \"%*\""):format(p46, v206), 0)
        end

        v205 = require(v207)
        t17[p48] = v205
        t16.stats.bundle_loads += 1

        return v205
    end

    local function v208(p49, p50, p51) -- line: 696
        -- upvalues: bundle_text (copy), decode_slice (copy)
        return (decode_slice(bundle_text(p49), p50, p51))
    end

    if v189.compressed == "zstd" then
        local zdata = require(sim.zdata)
        local bundle_bytes = paged.bundle_bytes
        local t18 = {}
        local t19 = {}
        local n11 = 0
        local n12 = 0

        t16.stats.bundle_unpacks = 0

        v208 = function(p52, p53, p54) -- line: 706
            -- upvalues: t16 (copy), bundle_text (copy), zdata (copy), bundle_bytes (copy), t18 (copy), t19 (copy), n11 (ref), n12 (ref), t1 (copy), cut_slice (copy)
            local v209 = t18[p52]

            n12 += 1

            if v209 == nil then
                local BUNDLE_CACHE = t1.BUNDLE_CACHE

                while BUNDLE_CACHE <= n11 do
                    local n13 = 1e999
                    local v210

                    for v211, v212 in t19 do
                        if v212 < n13 then
                            n13 = v212
                            v210 = v211
                        end
                    end

                    t18[v210] = nil
                    t19[v210] = nil
                    n11 -= 1
                end

                v209 = zdata.unpack(bundle_text(p52), bundle_bytes[p52])
                t18[p52] = v209
                n11 += 1
                t16.stats.bundle_unpacks += 1
            end

            t19[p52] = n12

            return (cut_slice(v209, bundle_bytes[p52], p53, p54))
        end
    end

    local function cluster_of(p55) -- line: 732
        -- upvalues: cluster_count (copy), v191 (copy)
        local n14 = 1
        local v213 = cluster_count

        while n14 < v213 do
            local v214 = (n14 + v213 + 1) // 2

            if v191[v214] <= p55 then
                n14 = v214
            else
                v213 = v214 - 1
            end
        end

        return n14
    end

    t16.cluster_of = cluster_of

    local t20 = {}
    local n15 = 0
    local v215
    local n16 = 0
    local n17 = 0

    function t16.drop(p56) -- line: 750
        -- upvalues: t16 (copy), v215 (ref), n16 (ref), n17 (ref)
        local v216 = t16.pages[p56]

        if v216 == nil then
            return
        end

        t16.pages[p56] = nil

        if v216 == v215 then
            v215 = nil
            n16 = 0
            n17 = 0
        end

        t16.built -= v216.count
        t16.held -= 1
        t16.stats.evictions += 1
        t16.generation += 1
    end

    local function evict(p57) -- line: 767
        -- upvalues: t16 (copy), v215 (ref), n16 (ref), n17 (ref), t1 (copy)
        local v217 = if t16.hard then t16.cap else t16.cap * t1.HARD

        while true do
            if v217 < t16.built and t16.held > 1 then
                local n18 = 1e999
                local v218

                for v219, v220 in t16.pages do
                    if v219 ~= p57 and not v220.pinned and v220.stamp < n18 then
                        v218 = v219
                        n18 = v220.stamp
                    end
                end

                if v218 == nil then
                    break
                end

                local v221 = t16.pages[v218]

                if v221 ~= nil then
                    t16.pages[v218] = nil

                    if v221 == v215 then
                        v215 = nil
                        n16 = 0
                        n17 = 0
                    end

                    t16.built -= v221.count
                    t16.held -= 1
                    t16.stats.evictions += 1
                    t16.generation += 1
                end

                continue
            end

            return
        end
    end

    local function build_page(p58) -- line: 783
        -- upvalues: p46 (copy), paged_clusters (copy), paged_masks (copy), paged_meshes (copy), v191 (copy), t16 (copy), v208 (ref), evict (copy), BLOCK (copy), readu8 (copy), readu32 (copy), writeu16 (copy), band (copy), byteswap (copy), fround (copy), from_bits (copy), to_i32 (copy), v139 (copy)
        local elapsed = os.clock()
        local v222 = (p58 - 1) * 32
        local v223 = readu32(paged_clusters, v222)
        local v225 = readu32(paged_clusters, v222 + 4)
        local v227 = readu32(paged_clusters, v222 + 8)
        local v224 = readu32(paged_clusters, v222 + 12)
        local v226 = readu32(paged_clusters, v222 + 20)
        local v228 = readu32(paged_clusters, v222 + 24)
        local v229 = v208(v225, v227, v224)

        v227 = paged_meshes[v223 + 1]

        local v230 = from_bits(v227.granularity_bits)
        local group_width = v227.group_width
        local surface_width = v227.surface_width

        if v224 < 16 then
            error("Truncated RWCM at 0 (need 16)", 0)
        end

        v223 = readu8(v229, 0) * 256 + readu8(v229, 1)

        local v231 = readu8(v229, 2) * 256 + readu8(v229, 3)
        local v232 = (readu8(v229, 4) * 256 + readu8(v229, 5) + 1) * 16
        local v233 = readu8(v229, 10)
        local v234 = readu8(v229, 12)

        if v224 < v232 + v231 then
            error(("Truncated RWCM at %* (need %*)"):format(v232, v231), 0)
        end

        local v235 = table.create(v233)
        local v236 = table.create(v233)
        local v237 = table.create(v233)
        local v238, v239, v240, v241, v242, v243, v244, v245, v246, v247, v248

        if v234 == 0 then
            if v232 < v233 * 16 + 16 then
                error("Truncated RWCM vertices", 0)
            end

            v242 = v233 - 1

            for i = 0, v242 do
                v224 = i * 16 + 16
                v247 = i + 1
                v235[v247] = from_bits((byteswap((readu32(v229, v224)))))
                v247 = i + 1
                v240 = v224 + 4
                v236[v247] = from_bits((byteswap((readu32(v229, v240)))))
                v247 = i + 1
                v240 = v224 + 8
                v237[v247] = from_bits((byteswap((readu32(v229, v240)))))
            end
        elseif v234 == 1 then
            if v232 < v233 * 6 + 28 then
                error("Truncated RWCM vertices", 0)
            end

            v243 = readu32(v229, 16)
            v242 = to_i32((byteswap(v243)))
            v247 = readu32(v229, 20)
            v248 = to_i32((byteswap(v247)))
            v246 = readu32(v229, 24)
            v243 = to_i32((byteswap(v246)))
            v247 = v233 - 1

            for i = 0, v247 do
                local v250 = i * 6 + 28

                v239 = i + 1
                v245 = readu8(v229, v250) * 256
                v238 = v250 + 1
                v244 = v242 + (v245 + readu8(v229, v238))
                v235[v239] = fround(fround((math.clamp(v244, -2147483648, 2147483647))) * v230)
                v239 = i + 1
                v238 = v250 + 2
                v245 = readu8(v229, v238) * 256
                v238 = v250 + 3
                v244 = v248 + (v245 + readu8(v229, v238))
                v236[v239] = fround(fround((math.clamp(v244, -2147483648, 2147483647))) * v230)
                v239 = i + 1
                v238 = v250 + 4
                v245 = readu8(v229, v238) * 256
                v238 = v250 + 5
                v244 = v243 + (v245 + readu8(v229, v238))
                v237[v239] = fround(fround((math.clamp(v244, -2147483648, 2147483647))) * v230)
            end
        elseif v234 == 2 then
            if v232 < v233 * 12 + 16 then
                error("Truncated RWCM vertices", 0)
            end

            v242 = v233 - 1

            for i = 0, v242 do
                v247 = i * 12 + 16
                v246 = i + 1
                v241 = readu32(v229, v247)
                v235[v246] = fround(fround(to_i32((byteswap(v241)))) * v230)
                v246 = i + 1
                v244 = v247 + 4
                v241 = readu32(v229, v244)
                v236[v246] = fround(fround(to_i32((byteswap(v241)))) * v230)
                v246 = i + 1
                v244 = v247 + 8
                v241 = readu32(v229, v244)
                v237[v246] = fround(fround(to_i32((byteswap(v241)))) * v230)
            end
        else
            error(("Unsupported RWCM vertex compression %*"):format(v234), 0)
        end

        for i = 1, v233 do
            v234 = v235[i] + v236[i] + v237[i]

            if v234 - v234 ~= 0 then
                error("Non-finite RWCM vertex", 0)
            end
        end

        v242 = table.create(v226 * 6, 0)

        local v251 = buffer.create(v226 * 2 + 2)

        v247 = v228 ~= 4294967295
        v246 = v223 - 1
        v248 = 0
        v243 = v232

        local v252, v253, v254, v255, v256, v257, v258, v259, v260, v261

        for i = 0, v246 do
            v239 = readu8(v229, v243)

            if band(v239, 15) ~= 1 then
                error(("Unsupported RWCM unit type %*; triangle units are required"):format((band(v239, 15))), 0)
            end

            local v262 = v243 + 4

            if band(v239, 32) ~= 0 then
                v262 += 3
            end

            if band(v239, 64) == 0 then
                v260 = v262
            else
                if group_width ~= 1 and group_width ~= 2 then
                    error(("Unsupported RWCM ID width %*"):format(group_width), 0)
                end

                v260 = v262 + group_width
            end

            if band(v239, 128) ~= 0 then
                if surface_width ~= 1 and surface_width ~= 2 then
                    error(("Unsupported RWCM ID width %*"):format(surface_width), 0)
                end

                v260 += surface_width
            end

            local v263 = false

            if v247 then
                v244 = v228 + i // 8
                v241 = readu8(paged_masks, v244)
                v255 = i % 8

                if band(v241, (bit32.lshift(1, v255))) == 0 then
                    v261 = v248
                    v263 = true
                else
                    v245 = v243 + 1
                    v252 = readu8(v229, v245) + 1
                    v245 = v243 + 2
                    v253 = readu8(v229, v245) + 1
                    v245 = v243 + 3
                    v254 = readu8(v229, v245) + 1

                    if v233 < v252 or v233 < v253 or v233 < v254 then
                        error("RWCM missing vertex", 0)
                    end
                end
            else
                v245 = v243 + 1
                v252 = readu8(v229, v245) + 1
                v245 = v243 + 2
                v253 = readu8(v229, v245) + 1
                v245 = v243 + 3
                v254 = readu8(v229, v245) + 1

                if v233 < v252 or v233 < v253 or v233 < v254 then
                    error("RWCM missing vertex", 0)
                end
            end

            if not v263 then
                v244 = v235[v252]
                v255 = v236[v252]
                v245 = v237[v252]
                v256 = v235[v253]
                v257 = v236[v253]
                v258 = v237[v253]

                local v265 = if v244 < v256 then v244 else v256
                local v266 = if v255 < v257 then v255 else v257
                local v267 = if v245 < v258 then v245 else v258

                if not (v256 < v244) then
                    v244 = v256
                end

                if not (v257 < v255) then
                    v255 = v257
                end

                if not (v258 < v245) then
                    v245 = v258
                end

                v256 = v235[v254]
                v257 = v236[v254]
                v258 = v237[v254]

                if not (v265 < v256) then
                    v265 = v256
                end

                if not (v266 < v257) then
                    v266 = v257
                end

                if not (v267 < v258) then
                    v267 = v258
                end

                if not (v256 < v244) then
                    v244 = v256
                end

                if not (v257 < v255) then
                    v255 = v257
                end

                if not (v258 < v245) then
                    v245 = v258
                end

                v258 = v248 * 6
                v259 = v258 + 1

                local v268 = v258 + 2
                local v269 = v258 + 3

                v242[v259] = v265
                v242[v268] = v266
                v242[v269] = v267
                v259 = v258 + 4
                v268 = v258 + 5
                v269 = v258 + 6
                v242[v259] = v244
                v242[v268] = v255
                v242[v269] = v245
                writeu16(v251, v248 * 2, v243)
                v261 = v248 + 1
            end

            v243 = v260
            v248 = v261
        end

        if v243 ~= v232 + v231 then
            error("RWCM unit stream has trailing bytes", 0)
        end

        if v248 ~= v226 then
            error(("sim_data %*: cluster %* decoded %* triangles, the index says %*"):format(p46, p58, v248, v226), 0)
        end

        v247 = (v226 + BLOCK - 1) // BLOCK
        v246 = table.create(6 * v247, 0)

        local v271, v272

        for i = 0, v247 - 1 do
            v261 = i * 6 * BLOCK
            v239 = v242[v261 + 1]
            v240 = v242[v261 + 2]
            v252 = v242[v261 + 3]
            v253 = v242[v261 + 4]
            v254 = v242[v261 + 5]
            v244 = v242[v261 + 6]
            v271 = i * BLOCK + 1
            v256 = (i + 1) * BLOCK
            v255 = math.min(v226, v256) - 1

            for j = v271, v255 do
                v261 = j * 6
                v272 = v242[v261 + 1]
                v238 = v242[v261 + 2]
                v256 = v242[v261 + 3]
                v257 = v242[v261 + 4]
                v258 = v242[v261 + 5]
                v259 = v242[v261 + 6]

                if v272 < v239 then
                    v239 = v272
                end

                if v238 < v240 then
                    v240 = v238
                end

                if v256 < v252 then
                    v252 = v256
                end

                if v253 < v257 then
                    v253 = v257
                end

                if v254 < v258 then
                    v254 = v258
                end

                if v244 < v259 then
                    v244 = v259
                end
            end

            v261 = i * 6
            v255 = v261 + 1
            v245 = v261 + 2
            v271 = v261 + 3
            v246[v255] = v239
            v246[v245] = v240
            v246[v271] = v252
            v255 = v261 + 4
            v245 = v261 + 5
            v271 = v261 + 6
            v246[v255] = v253
            v246[v245] = v254
            v246[v271] = v244
        end

        v233 = (v247 + v139 - 1) // v139

        local v270 = table.create(6 * v233, 0)

        for i = 0, v233 - 1 do
            v231 = i * 6 * v139
            v239 = v246[v231 + 1]
            v240 = v246[v231 + 2]
            v252 = v246[v231 + 3]
            v253 = v246[v231 + 4]
            v254 = v246[v231 + 5]
            v244 = v246[v231 + 6]
            v271 = i * v139 + 1
            v256 = (i + 1) * v139
            v255 = math.min(v247, v256) - 1

            for j = v271, v255 do
                v231 = j * 6
                v272 = v246[v231 + 1]
                v238 = v246[v231 + 2]
                v256 = v246[v231 + 3]
                v257 = v246[v231 + 4]
                v258 = v246[v231 + 5]
                v259 = v246[v231 + 6]

                if v272 < v239 then
                    v239 = v272
                end

                if v238 < v240 then
                    v240 = v238
                end

                if v256 < v252 then
                    v252 = v256
                end

                if v253 < v257 then
                    v253 = v257
                end

                if v254 < v258 then
                    v254 = v258
                end

                if v244 < v259 then
                    v244 = v259
                end
            end

            v231 = i * 6
            v255 = v231 + 1
            v245 = v231 + 2
            v271 = v231 + 3
            v270[v255] = v239
            v270[v245] = v240
            v270[v271] = v252
            v255 = v231 + 4
            v245 = v231 + 5
            v271 = v231 + 6
            v270[v255] = v253
            v270[v245] = v254
            v270[v271] = v244
        end

        t16.stamp += 1
        v247 = {
            pinned = false,
            cluster = p58,
            first = v191[p58],
            count = v226,
            flat = v242,
            blocks = v246,
            supers = v270,
            bytes = v229,
            unit_at = v251,
            vx = v235,
            vy = v236,
            vz = v237,
            one_sided = v227.one_sided,
            group_width = group_width,
            surface_width = surface_width,
            stamp = t16.stamp
        }
        t16.pages[p58] = v247
        t16.built += v226
        t16.held += 1
        t16.generation += 1
        v260 = t16.stats
        v260.loads += 1

        if t16.in_tick then
            v260.loads_in_tick += 1
        end

        v235 = os.clock() - elapsed
        v260.load_seconds += v235

        if v260.worst_load < v235 then
            v260.worst_load = v235
        end

        if t16.built > t16.cap then
            evict(p58)
        end

        return v247
    end

    t16.build = build_page

    function t16.page(p59) -- line: 1050
        -- upvalues: t16 (copy), build_page (copy)
        local v273 = t16.pages[p59]

        if v273 == nil then
            v273 = build_page(p59)
        end

        return v273
    end

    local pages2 = t16.pages

    function t16.pages_into(p60, p61, p62) -- line: 1062
        -- upvalues: t16 (copy), build_page (copy), pages2 (copy)
        local v274 = t16.stamp + 1

        t16.stamp = v274

        for i = 1, p61 do
            local v275 = p60[i] + 1
            local v276 = pages2[v275]

            if v276 == nil then
                v276 = build_page(v275)
            end

            v276.stamp = v274
            p62[i] = v276
        end
    end

    v195 = v191[1] == 0

    for i = 1, cluster_count do
        if v191[i] + v192[i] ~= v191[i + 1] then
            v195 = false
        end
    end

    if v195 then
        function t16.all_into(p63, p64, p65) -- line: 1087
            -- upvalues: cluster_count (copy), v191 (copy), t16 (copy), build_page (copy), pages2 (copy)
            local v277 = t16.stamp + 1

            t16.stamp = v277

            for i = 1, cluster_count do
                local v278 = pages2[i]

                if v278 == nil then
                    v278 = build_page(i)
                end

                v278.stamp = v277

                local v279 = v191[i]
                local v280 = v191[i + 1]

                p63[i] = v279
                p64[i] = v280
                p65[i] = v278
            end

            return cluster_count
        end
    end

    local function page_of(p66) -- line: 1103
        -- upvalues: v191 (copy), t16 (copy), cluster_of (copy), v215 (ref), n16 (ref), n17 (ref), build_page (copy), pages2 (copy)
        if n16 <= p66 and p66 < n17 then
            return v215, p66 - n16
        end

        local v281 = cluster_of(p66)
        local v282 = pages2[v281]

        if v282 ~= nil then
            t16.stamp += 1
            v282.stamp = t16.stamp
        else
            v282 = build_page(v281)
        end

        local v283 = v191[v281]
        local v284 = v191[v281] + v282.count

        v215 = v282
        n16 = v283
        n17 = v284

        return v282, p66 - n16
    end

    local decode_native_edges = import("skate_game/skate_world").decode_native_edges

    local function surface_of(p67, p68) -- line: 1120
        -- upvalues: readu8 (copy), readu16 (copy), band (copy)
        local bytes = p67.bytes
        local v286 = readu16(p67.unit_at, p68 * 2)
        local v287 = readu8(bytes, v286)

        if band(v287, 128) == 0 then
            return 0
        end

        local v288 = v286 + 4

        if band(v287, 32) ~= 0 then
            v288 += 3
        end

        if band(v287, 64) ~= 0 then
            v288 += p67.group_width
        end

        if p67.surface_width == 1 then
            return (readu8(bytes, v288))
        end

        return (readu16(bytes, v288))
    end

    local function record(p69) -- line: 1138
        -- upvalues: p47 (copy), t16 (copy), t20 (copy), n15 (ref), page_of (copy), decode_native_edges (copy), surface_of (copy), rt (copy), t1 (copy), Vector3 (copy), WorldTriangle (copy), readu8 (copy), readu16 (copy), band (copy), ONE_SIDED (copy), freeze_deep (copy)
        local v289, v290 = page_of(p69)
        local bytes = v289.bytes
        local v292 = readu16(v289.unit_at, 2 * v290)
        local v293 = readu8(bytes, v292)
        local v295 = readu8(bytes, v292 + 1) + 1
        local v297 = readu8(bytes, v292 + 2) + 1
        local v299 = readu8(bytes, v292 + 3) + 1
        local v300, v301

        if band(v293, 32) == 0 then
            v301 = 481
            v300 = { -1, -1, -1 }
        else
            local v303 = readu8(bytes, v292 + 4)
            local v305 = readu8(bytes, v292 + 5)
            local v306 = v292 + 6
            local v307

            v307, v300 = decode_native_edges({
                v303,
                v305,
                (readu8(bytes, v306))
            })
            v301 = band(v307, (bit32.bnot(ONE_SIDED)))

            if v289.one_sided then
                v301 = bit32.bor(v301, ONE_SIDED)
            end
        end

        local vx, vy, vz = v289.vx, v289.vy, v289.vz
        local v309 = WorldTriangle.from_vertices({
            Vector3.new(vx[v295], vy[v295], vz[v295]),
            Vector3.new(vx[v297], vy[v297], vz[v297]),
            Vector3.new(vx[v299], vy[v299], vz[v299])
        }, rt.copy(p47), surface_of(v289, v290), v301, v300, 0)

        if v309 == nil then
            error("Invalid RWCM collision triangle", 0)
        end

        freeze_deep(v309)

        local v310 = n15

        if v310 >= t1.TRIANGLE_CACHE then
            table.clear(t20)
            n15 = 0
        end

        t20[p69 + 1] = v309
        n15 += 1
        t16.stats.records += 1

        return v309
    end

    local t21 = {
        paged = t16,
        count = triangle_count
    }

    local function view(p70) -- line: 1175
        -- upvalues: triangle_count (copy), t21 (copy)
        return (setmetatable({}, {
            __index = function(_, p72) -- __index | line: 1177
                -- upvalues: p70 (copy), triangle_count (copy)
                if type(p72) == "number" and not (p72 < 1) and not (triangle_count < p72) and p72 % 1 == 0 then
                    return p70(p72)
                end

                return nil
            end,
            __len = function() -- __len | line: 1183
                -- upvalues: triangle_count (copy)
                return triangle_count
            end,
            __newindex = function() -- __newindex | line: 1186
                error("paged_world: this array is read-only", 0)
            end,
            __iter = function() -- __iter | line: 1189
                -- upvalues: p70 (copy), triangle_count (copy)
                local n19 = 0

                return function() -- line: 1191
                    -- upvalues: n19 (ref), p70 (copy), triangle_count (copy)
                    n19 += 1

                    if n19 <= triangle_count then
                        return n19, p70(n19)
                    end

                    return nil
                end
            end,
            store = t21
        }))
    end

    local self = setmetatable({}, {
        __index = function(_, p74) -- __index | line: 1205
            -- upvalues: triangle_count (copy), t20 (copy), record (copy)
            local v311 = t20[p74]

            if v311 ~= nil then
                return v311
            end

            return if type(p74) == "number" and not (p74 < 1) and not (triangle_count < p74) and p74 % 1 == 0 then record(p74 - 1) else nil
        end,
        __len = function() -- __len | line: 1215
            -- upvalues: triangle_count (copy)
            return triangle_count
        end,
        __newindex = function() -- __newindex | line: 1218
            error("paged_world: this array is read-only", 0)
        end,
        __iter = function() -- __iter | line: 1221
            -- upvalues: triangle_count (copy), t20 (copy), record (copy)
            local n20 = 0

            return function() -- line: 1223
                -- upvalues: n20 (ref), triangle_count (copy), t20 (copy), record (copy)
                n20 += 1

                if n20 <= triangle_count then
                    local v312 = n20

                    return v312, t20[n20] or record(n20 - 1)
                end

                return nil
            end
        end,
        store = t21
    })
    local t26 = {}
    local n21 = 0
    local v314 = view(function(p75) -- line: 1235
        -- upvalues: page_of (copy), t26 (copy), n21 (ref), Vector3 (copy), freeze_deep (copy)
        local v315 = t26[p75]

        if v315 ~= nil then
            return v315
        end

        local v316, v317 = page_of(p75 - 1)
        local flat = v316.flat
        local v318 = 6 * v317
        local t27 = {
            min = Vector3.new(flat[v318 + 1], flat[v318 + 2], flat[v318 + 3]),
            max = Vector3.new(flat[v318 + 4], flat[v318 + 5], flat[v318 + 6])
        }

        freeze_deep(t27)

        if n21 >= 256 then
            table.clear(t26)
            n21 = 0
        end

        t26[p75] = t27
        n21 += 1

        return t27
    end)
    local v319 = view(function(p76) -- line: 1259
        -- upvalues: page_of (copy), surface_of (copy)
        return (surface_of(page_of(p76 - 1)))
    end)

    local function computed(p77, p78, p79) -- line: 1266
        local t28 = if p79 then {} else nil

        return (setmetatable({}, {
            __index = function(_, p81) -- __index | line: 1269
                -- upvalues: p77 (copy), p78 (copy), t28 (copy)
                local v320 = t28 == nil
                local v321, v322

                if not v320 then
                    v321 = t28[p81]
                    v322 = v321 == nil
                end

                if v320 or v322 then
                    if type(p81) == "number" and not (p81 < 1) and not (p77 < p81) and p81 % 1 == 0 then
                        local v323 = p78(p81 - 1)

                        if t28 ~= nil then
                            t28[p81] = v323
                        end

                        return v323
                    end

                    return nil
                end

                return v321
            end,
            __len = function() -- __len | line: 1285
                -- upvalues: p77 (copy)
                return p77
            end,
            __newindex = function() -- __newindex | line: 1288
                error("paged_world: this array is read-only", 0)
            end
        }))
    end

    local v324 = computed(triangle_count * 6, function(p82) -- line: 1293
        -- upvalues: page_of (copy)
        local v325, v326 = page_of(p82 // 6)

        return v325.flat[6 * v326 + p82 % 6 + 1]
    end)

    local function union(p83, p84, p85) -- line: 1297
        -- upvalues: page_of (copy)
        local v327 = if p85 < 3 then 1e999 else (-1e999)

        for i = p83, p84 - 1 do
            local v328, v329 = page_of(i)
            local v330 = v328.flat[6 * v329 + p85 + 1]

            if p85 < 3 then
                if v330 < v327 then
                    v327 = v330
                end
            elseif v327 < v330 then
                v327 = v330
            end
        end

        return v327
    end

    local v331 = (triangle_count + BLOCK - 1) // BLOCK
    local v332 = computed(6 * v331, function(p86) -- line: 1314
        -- upvalues: triangle_count (copy), union (copy), BLOCK (copy)
        local v333 = p86 // 6

        return (union(v333 * BLOCK, math.min(triangle_count, (v333 + 1) * BLOCK), p86 % 6))
    end, true)
    local v336 = computed(6 * ((v331 + v139 - 1) // v139), function(p87) -- line: 1319
        -- upvalues: triangle_count (copy), union (copy), SUPER (copy)
        local v337 = p87 // 6

        return (union(v337 * SUPER, math.min(triangle_count, (v337 + 1) * SUPER), p87 % 6))
    end, true)
    local t31 = {
        external = nil,
        maximum_fatness = 0,
        triangles = self,
        triangle_bounds = v314,
        query_metadata = {
            island_flags = 0,
            packed_surfaces = v319,
            meshes = v190,
            static_edges = {}
        },
        query_index = v3.QueryIndex.new(v190),
        maximum_triangle_margin = rt.fmax(0, paged.max_span * (2 * v5.THIN_MARGIN)),
        contacts = {},
        buffer = {
            count = 0,
            flushed = 0,
            capacity = 0,
            dropped = 0,
            distance_squared_threshold = 0,
            allow_flush = 1,
            deferred_reduction = 0,
            full = 0,
            records = rt.filled(50, table.create(64, 0))
        },
        triangle_bounds_flat = v324,
        triangle_block_bounds = v332,
        triangle_super_bounds = v336,
        paged = t16
    }

    local function distance2(p88, p89, p90, p91) -- line: 1360
        -- upvalues: v193 (copy)
        local v340 = (p88 - 1) * 6
        local v343 = math.max(v193[v340 + 1] - p89, 0, p89 - v193[v340 + 4])
        local v346 = math.max(v193[v340 + 2] - p90, 0, p90 - v193[v340 + 5])
        local v349 = math.max(v193[v340 + 3] - p91, 0, p91 - v193[v340 + 6])

        return v343 * v343 + v346 * v346 + v349 * v349
    end

    t16.distance2 = distance2

    function t16.prefetch(p92, p93, p94, p95, p96) -- line: 1370
        -- upvalues: cluster_count (copy), build_page (copy), pages2 (copy), distance2 (copy)
        local elapsed = os.clock()
        local t32 = {}
        local v350 = p95 * p95

        for i = 1, cluster_count do
            if pages2[i] == nil then
                local v351 = distance2(i, p92, p93, p94)

                if v351 <= v350 then
                    table.insert(t32, {
                        i,
                        v351
                    })
                end
            end
        end

        table.sort(t32, function(p97, p98) -- line: 1382
            return p97[2] < p98[2]
        end)

        local v352 = #t32

        for _, v353 in t32 do
            if p96 ~= nil and p96 <= os.clock() - elapsed and v352 < #t32 then
                break
            end

            build_page(v353[1])
            v352 -= 1
        end

        return v352
    end

    function t16.loaded() -- line: 1395
        -- upvalues: t16 (copy)
        return t16.held, t16.built
    end

    return t31
end

function t1.world(p99, p100) -- line: 1401
    -- upvalues: t1 (copy), reference_world (copy), paged_world (copy)
    if t1.REFERENCE then
        return (reference_world(p99, p100))
    end

    return (paged_world(p99, p100))
end

t1.reference_world = reference_world

function t1.state(p101) -- line: 1411
    return if p101 ~= nil then rawget(p101, "paged") else nil
end

return t1
