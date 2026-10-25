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

local import = require(sim.import)
local Bounds = import("skate_core/physics/board_world/query_metadata").Bounds
local by_index = import("skate_core/physics/board_world/objects").by_index
local t1 = {}

local function total_cmp(p3, p4) -- line: 40
    -- upvalues: v1 (copy)
    if p3 < p4 then
        return -1
    end

    if p4 < p3 then
        return 1
    end

    local v8 = p3 ~= p3
    local v9 = p4 ~= p4

    if v8 or v9 then
        local function key(p5, p6) -- line: 61
            -- upvalues: v1 (copy)
            if not p6 then
                return 0
            end

            local v10

            if p5 ~= 0 and p5 > -1.1754943508222875E-38 and p5 < 1.1754943508222875E-38 then
                local v11 = math.abs(p5) * 7.1362384635298E+44
                local v12 = math.floor(v11)
                local v13 = v11 - v12

                v10 = if v13 > 0.5 or v13 == 0.5 and v12 % 2 == 1 then v12 + 1 else v12

                if p5 < 0 then
                    v10 += 2147483648
                end
            else
                buffer.writef32(v1, 0, p5)
                v10 = buffer.readu32(v1, 0)
            end

            if v10 >= 2147483648 then
                return -1
            end

            return 1
        end

        local v14 = 0

        if v8 then
            local v15

            if p3 == 0 then
                buffer.writef32(v1, 0, p3)
                v15 = buffer.readu32(v1, 0)
            elseif p3 > -1.1754943508222875E-38 and p3 < 1.1754943508222875E-38 then
                local v16 = math.abs(p3) * 7.1362384635298E+44

                v15 = math.floor(v16)

                local v17 = v16 - v15

                if v17 > 0.5 or v17 == 0.5 and v15 % 2 == 1 then
                    v15 += 1
                end

                if p3 < 0 then
                    v15 += 2147483648
                end
            else
                buffer.writef32(v1, 0, p3)
                v15 = buffer.readu32(v1, 0)
            end

            v14 = if v15 >= 2147483648 then -1 else 1
        end

        local v18 = 0

        if v9 then
            local v19

            if p4 == 0 then
                buffer.writef32(v1, 0, p4)
                v19 = buffer.readu32(v1, 0)
            elseif p4 > -1.1754943508222875E-38 and p4 < 1.1754943508222875E-38 then
                local v20 = math.abs(p4) * 7.1362384635298E+44

                v19 = math.floor(v20)

                local v21 = v20 - v19

                if v21 > 0.5 or v21 == 0.5 and v19 % 2 == 1 then
                    v19 += 1
                end

                if p4 < 0 then
                    v19 += 2147483648
                end
            else
                buffer.writef32(v1, 0, p4)
                v19 = buffer.readu32(v1, 0)
            end

            v18 = if v19 >= 2147483648 then -1 else 1
        end

        if v14 < v18 then
            return -1
        end

        if v18 < v14 then
            return 1
        end
    elseif p3 == 0 then
        local v22 = 1 / p3 < 0
        local v23 = 1 / p4 < 0

        if v22 and not v23 then
            return -1
        end

        if v23 and not v22 then
            return 1
        end
    end

    return 0
end

t1.QueryIndex = {}

function t1.QueryIndex.default() -- line: 80
    return {
        nodes = {},
        order = {}
    }
end

t1.Node = {}

function t1.QueryIndex.new(p7) -- line: 87
    -- upvalues: rt (copy), t1 (copy)
    local t2 = {
        nodes = {},
        order = rt.from_fn(#p7, function(p8) -- line: 90
            return p8
        end)
    }

    if #p7 ~= 0 then
        t1.QueryIndex.build(t2, p7, {
            start = 0,
            ["end"] = #p7
        })
    end

    return t2
end

function t1.QueryIndex.build(p9, p10, p11) -- line: 100
    -- upvalues: rt (copy), Bounds (copy), t1 (copy), total_cmp (copy)
    local t3 = {}

    for i = p11.start, p11["end"] - 1 do
        local v24 = p9.order[i + 1]

        table.insert(t3, p10[v24 + 1].local_bounds.min)
        table.insert(t3, p10[v24 + 1].local_bounds.max)
    end

    local v25 = Bounds.from_points(t3)

    if v25 == nil then
        error("called `Option::unwrap()` on a `None` value", 0)
    end

    local v26 = #p9.nodes

    table.insert(p9.nodes, {
        children = nil,
        bounds = v25,
        range = rt.copy(p11)
    })

    local v27 = p11["end"] - p11.start

    if v27 > 8 then
        local t5 = {
            v25.max.x - v25.min.x,
            v25.max.y - v25.min.y,
            v25.max.z - v25.min.z
        }
        local n1 = 0
        local n2 = 0

        if total_cmp(t5[0 + 1], t5[2]) <= 0 then
            n1 = 1
            n2 = 1
        end

        if total_cmp(t5[n2 + 1], t5[3]) <= 0 then
            n1 = 2
        end

        local function center(p12) -- line: 131
            -- upvalues: p10 (copy), n1 (ref)
            local local_bounds = p10[p12 + 1].local_bounds
            local v28 = ({
                local_bounds.min.x,
                local_bounds.min.y,
                local_bounds.min.z
            })[n1 + 1]
            local v29 = ({
                local_bounds.max.x,
                local_bounds.max.y,
                local_bounds.max.z
            })[n1 + 1]

            return v28 * 0.5 + v29 * 0.5
        end

        local v30 = p11.start + rt.idiv(v27, 2)

        local function cmp(p13, p14) -- line: 143
            -- upvalues: center (copy), total_cmp (copy)
            local v31 = total_cmp(center(p13), (center(p14)))

            if v31 ~= 0 then
                return v31
            end

            if p13 < p14 then
                return -1
            end

            if p14 < p13 then
                return 1
            end

            return 0
        end

        local v32 = table.create(v27)

        for i = p11.start, p11["end"] - 1 do
            v32[i - p11.start + 1] = p9.order[i + 1]
        end

        table.sort(v32, function(p15, p16) -- line: 154
            -- upvalues: center (copy), total_cmp (copy)
            local v33 = total_cmp(center(p15), (center(p16)))

            if v33 == 0 then
                v33 = if p15 < p16 then -1 elseif p16 < p15 then 1 else 0
            end

            return v33 < 0
        end)

        for i = p11.start, p11["end"] - 1 do
            p9.order[i + 1] = v32[i - p11.start + 1]
        end

        local v34 = t1.QueryIndex.build(p9, p10, {
            start = p11.start,
            ["end"] = v30
        })
        local v35 = t1.QueryIndex.build(p9, p10, {
            start = v30,
            ["end"] = p11["end"]
        })

        p9.nodes[v26 + 1].children = { v34, v35 }
    end

    return v26
end

function t1.QueryIndex.query_reference(p17, p18, p19) -- line: 168
    -- upvalues: Bounds (copy), by_index (copy)
    local t6 = {}

    if #p17.nodes == 0 then
        local v36 = by_index[p17]

        if v36 ~= nil then
            local min, max = p18.min, p18.max

            v36.meshes_into(v36, min.x, min.y, min.z, max.x, max.y, max.z, t6, 0)
        end
    else
        local t7 = {
            0
        }

        while #t7 > 0 do
            local v37 = table.remove(t7)
            local v38 = p17.nodes[v37 + 1]

            if Bounds.overlaps(v38.bounds, p18) then
                local children = v38.children

                if children ~= nil then
                    local v40 = children[1]

                    table.insert(t7, children[2])
                    table.insert(t7, v40)
                else
                    for i = v38.range.start, v38.range["end"] - 1 do
                        local v39 = p17.order[i + 1]

                        if Bounds.overlaps(p19[v39 + 1].local_bounds, p18) then
                            table.insert(t6, v39)
                        end
                    end
                end
            end
        end

        table.sort(t6)

        local v42 = by_index[p17]

        if v42 ~= nil then
            local min, max = p18.min, p18.max

            v42.meshes_into(v42, min.x, min.y, min.z, max.x, max.y, max.z, t6, #t6)
        end
    end

    return t6
end

local function query_scalar_tables(p20, p21, p22, p23, p24, p25, p26, p27) -- line: 214
    -- upvalues: by_index (copy)
    local t8 = {}
    local nodes = p20.nodes

    if #nodes == 0 then
        local v43 = by_index[p20]

        if v43 ~= nil then
            v43.meshes_into(v43, p21, p22, p23, p24, p25, p26, t8, 0)
        end
    else
        local order = p20.order
        local t9 = {
            0
        }

        while #t9 > 0 do
            local v44 = nodes[table.remove(t9) + 1]
            local bounds = v44.bounds
            local min, max = bounds.min, bounds.max

            if not (max.x < p21) and not (p24 < min.x) and not (max.y < p22) and not (p25 < min.y) and not (max.z < p23) and not (p26 < min.z) then
                local children = v44.children

                if children ~= nil then
                    local v46 = children[1]

                    table.insert(t9, children[2])
                    table.insert(t9, v46)
                else
                    for i = v44.range.start, v44.range["end"] - 1 do
                        local v45 = order[i + 1]
                        local local_bounds = p27[v45 + 1].local_bounds
                        local min, max = local_bounds.min, local_bounds.max

                        if not (max.x < p21) and not (p24 < min.x) and not (max.y < p22) and not (p25 < min.y) and not (max.z < p23) and not (p26 < min.z) then
                            table.insert(t8, v45)
                        end
                    end
                end
            end
        end

        table.sort(t8)

        local v48 = by_index[p20]

        if v48 ~= nil then
            v48.meshes_into(v48, p21, p22, p23, p24, p25, p26, t8, #t8)
        end
    end

    return t8
end

t1.QueryIndex.query_scalar_tables = query_scalar_tables

local v49 = true

function t1.set_query_flat(p28) -- line: 296
    -- upvalues: v49 (ref)
    local v50 = v49

    v49 = p28

    return v50
end

local v51 = table.create(64, 0)

local function flatten(p29) -- line: 302
    local nodes = p29.nodes
    local v52 = #nodes
    local v53 = table.create(v52 * 6, 0)
    local v54 = table.create(v52, -1)
    local v55 = table.create(v52, -1)
    local v56 = table.create(v52, 0)
    local v57 = table.create(v52, 0)

    for i = 1, v52 do
        local v58 = nodes[i]
        local min, max = v58.bounds.min, v58.bounds.max
        local v59 = (i - 1) * 6
        local v60 = v59 + 2
        local v61 = v59 + 3
        local x, y, z = min.x, min.y, min.z

        v53[v59 + 1] = x
        v53[v60] = y
        v53[v61] = z

        local v62 = v59 + 5
        local v63 = v59 + 6
        local x2, y2, z2 = max.x, max.y, max.z

        v53[v59 + 4] = x2
        v53[v62] = y2
        v53[v63] = z2

        local children = v58.children

        if children ~= nil then
            local v64 = children[1]
            local v65 = children[2]

            v54[i] = v64
            v55[i] = v65
        else
            v54[i] = -1
            v55[i] = -1
        end

        local start, v66 = v58.range.start, v58.range["end"]

        v56[i] = start
        v57[i] = v66
    end

    local t10 = {
        bounds = v53,
        left = v54,
        right = v55,
        first = v56,
        last = v57,
        count = v52
    }

    p29.flat = t10

    return t10
end

local function flatten_meshes(p30, p31) -- line: 328
    local v67 = #p31
    local v68 = table.create(v67 * 6, 0)

    for i = 1, v67 do
        local local_bounds = p31[i].local_bounds
        local min, max = local_bounds.min, local_bounds.max
        local v69 = (i - 1) * 6
        local v70 = v69 + 2
        local v71 = v69 + 3
        local x, y, z = min.x, min.y, min.z

        v68[v69 + 1] = x
        v68[v70] = y
        v68[v71] = z

        local v72 = v69 + 5
        local v73 = v69 + 6
        local x2, y2, z2 = max.x, max.y, max.z

        v68[v69 + 4] = x2
        v68[v72] = y2
        v68[v73] = z2
    end

    p30.flat_meshes = v68
    p30.flat_meshes_source = p31
    p30.flat_meshes_count = v67

    return v68
end

function t1.QueryIndex.query_scalar(p32, p33, p34, p35, p36, p37, p38, p39) -- line: 343
    -- upvalues: by_index (copy), query_scalar_tables (copy), v49 (ref), v51 (copy), flatten (copy), flatten_meshes (copy)
    if not v49 then
        return (query_scalar_tables(p32, p33, p34, p35, p36, p37, p38, p39))
    end

    local nodes = p32.nodes

    if #nodes == 0 then
        local v74 = by_index[p32]

        if v74 == nil then
            return {}
        end

        local t11 = {}

        v74.meshes_into(v74, p33, p34, p35, p36, p37, p38, t11, 0)

        return t11
    end

    local flat = p32.flat

    if flat == nil or flat.count ~= #nodes then
        flat = flatten(p32)
    end

    local flat_meshes = p32.flat_meshes
    local v75, v76

    if flat_meshes ~= nil then
        if p32.flat_meshes_source == p39 and p32.flat_meshes_count == #p39 then
            v75 = flat_meshes
            v76 = true
        else
            v76 = false
        end
    else
        v76 = false
    end

    if not v76 then
        v75 = flatten_meshes(p32, p39)
    end

    local t12 = {}
    local bounds, left, right, first = flat.bounds, flat.left, flat.right, flat.first
    local last = flat.last
    local order = p32.order

    v51[1] = 0

    local n3 = 0
    local n4 = 1

    while n4 > 0 do
        local v77 = v51[n4]

        n4 -= 1

        local v78 = 6 * v77

        if not (bounds[v78 + 4] < p33
            or p36 < bounds[v78 + 1]
            or bounds[v78 + 5] < p34
            or p37 < bounds[v78 + 2]
            or bounds[v78 + 6] < p35
            or p38 < bounds[v78 + 3]) then
            local v79 = left[v77 + 1]

            if v79 >= 0 then
                v51[n4 + 1] = right[v77 + 1]
                v51[n4 + 2] = v79
                n4 += 2
            else
                for i = first[v77 + 1], last[v77 + 1] - 1 do
                    local v80 = order[i + 1]
                    local v81 = 6 * v80

                    if not (v75[v81 + 4] < p33
                        or p36 < v75[v81 + 1]
                        or v75[v81 + 5] < p34
                        or p37 < v75[v81 + 2]
                        or v75[v81 + 6] < p35
                        or p38 < v75[v81 + 3]) then
                        n3 += 1
                        t12[n3] = v80
                    end
                end
            end
        end
    end

    if n3 > 1 then
        table.sort(t12)
    end

    local v82 = by_index[p32]

    if v82 ~= nil then
        v82.meshes_into(v82, p33, p34, p35, p36, p37, p38, t12, n3)
    end

    return t12
end

function t1.QueryIndex.query_scalar_into(p40, p41, p42, p43, p44, p45, p46, p47, p48) -- line: 434
    -- upvalues: by_index (copy), query_scalar_tables (copy), v49 (ref), v51 (copy), flatten (copy), flatten_meshes (copy)
    local nodes = p40.nodes

    if #nodes == 0 then
        local v83 = by_index[p40]

        if v83 == nil then
            return 0
        end

        return v83.meshes_into(v83, p41, p42, p43, p44, p45, p46, p48, 0)
    end

    if v49 then
        local flat = p40.flat

        if flat == nil or flat.count ~= #nodes then
            flat = flatten(p40)
        end

        local flat_meshes = p40.flat_meshes
        local v84, v85

        if flat_meshes ~= nil then
            if p40.flat_meshes_source == p47 and p40.flat_meshes_count == #p47 then
                v84 = flat_meshes
                v85 = true
            else
                v85 = false
            end
        else
            v85 = false
        end

        if not v85 then
            v84 = flatten_meshes(p40, p47)
        end

        local bounds, left, right, first = flat.bounds, flat.left, flat.right, flat.first
        local last = flat.last
        local order = p40.order

        v51[1] = 0

        local n5 = 0
        local n6 = 1

        while n6 > 0 do
            local v86 = v51[n6]

            n6 -= 1

            local v87 = 6 * v86

            if not (bounds[v87 + 4] < p41
                or p44 < bounds[v87 + 1]
                or bounds[v87 + 5] < p42
                or p45 < bounds[v87 + 2]
                or bounds[v87 + 6] < p43
                or p46 < bounds[v87 + 3]) then
                local v88 = left[v86 + 1]

                if v88 >= 0 then
                    v51[n6 + 1] = right[v86 + 1]
                    v51[n6 + 2] = v88
                    n6 += 2
                else
                    for i = first[v86 + 1], last[v86 + 1] - 1 do
                        local v89 = order[i + 1]
                        local v90 = 6 * v89

                        if not (v84[v90 + 4] < p41
                            or p44 < v84[v90 + 1]
                            or v84[v90 + 5] < p42
                            or p45 < v84[v90 + 2]
                            or v84[v90 + 6] < p43
                            or p46 < v84[v90 + 3]) then
                            local v91 = n5

                            while v91 >= 1 and v89 < p48[v91] do
                                p48[v91 + 1] = p48[v91]
                                v91 -= 1
                            end

                            p48[v91 + 1] = v89
                            n5 += 1
                        end
                    end
                end
            end
        end

        local v92 = by_index[p40]

        if v92 == nil then
            return n5
        end

        return v92.meshes_into(v92, p41, p42, p43, p44, p45, p46, p48, n5)
    end

    local v93 = query_scalar_tables(p40, p41, p42, p43, p44, p45, p46, p47)

    for i = 1, #v93 do
        p48[i] = v93[i]
    end

    return #v93
end

function t1.QueryIndex.query(p49, p50, p51) -- line: 528
    -- upvalues: t1 (copy)
    if #p49.nodes == 0 then
        return {}
    end

    local min, max = p50.min, p50.max

    return t1.QueryIndex.query_scalar(p49, min.x, min.y, min.z, max.x, max.y, max.z, p51)
end

return t1
