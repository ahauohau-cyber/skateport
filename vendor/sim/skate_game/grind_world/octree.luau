-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

local fround = rt.fround
local t1 = {
    Bounds = {}
}
local Bounds = t1.Bounds

function Bounds.eq(p1, p2) -- line: 25
    for i = 1, 3 do
        if p1.min[i] ~= p2.min[i] or p1.max[i] ~= p2.max[i] then
            return false
        end
    end

    return true
end

function Bounds.identity_transformed(p3) -- line: 35
    -- upvalues: fround (copy)
    local t2 = {
        fround(fround(p3.max[1] + p3.min[1]) * 0.5),
        fround(fround(p3.max[2] + p3.min[2]) * 0.5),
        fround(fround(p3.max[3] + p3.min[3]) * 0.5)
    }
    local t3 = {
        fround(fround(p3.max[1] - p3.min[1]) * 0.5),
        fround(fround(p3.max[2] - p3.min[2]) * 0.5),
        fround(fround(p3.max[3] - p3.min[3]) * 0.5)
    }

    return {
        min = {
            fround(t2[1] - t3[1]),
            fround(t2[2] - t3[2]),
            fround(t2[3] - t3[3])
        },
        max = {
            fround(t2[1] + t3[1]),
            fround(t2[2] + t3[2]),
            fround(t2[3] + t3[3])
        }
    }
end

function Bounds.overlaps(p4, p5) -- line: 59
    for i = 1, 3 do
        if not (p4.min[i] <= p5.max[i] and p5.min[i] <= p4.max[i]) then
            return false
        end
    end

    return true
end

function Bounds.union(p6, p7) -- line: 67
    -- upvalues: rt (copy)
    return {
        min = {
            rt.fmin(p6.min[1], p7.min[1]),
            rt.fmin(p6.min[2], p7.min[2]),
            rt.fmin(p6.min[3], p7.min[3])
        },
        max = {
            rt.fmax(p6.max[1], p7.max[1]),
            rt.fmax(p6.max[2], p7.max[2]),
            rt.fmax(p6.max[3], p7.max[3])
        }
    }
end

function Bounds.padded(p8) -- line: 81
    -- upvalues: fround (copy)
    return {
        min = {
            fround(p8.min[1] - 1),
            fround(p8.min[2] - 1),
            fround(p8.min[3] - 1)
        },
        max = {
            fround(p8.max[1] + 1),
            fround(p8.max[2] + 1),
            fround(p8.max[3] + 1)
        }
    }
end

function Bounds.cube(p9) -- line: 87
    -- upvalues: rt (copy), fround (copy)
    local t4 = {
        fround(fround(p9.max[1] - p9.min[1]) * 0.5),
        fround(fround(p9.max[2] - p9.min[2]) * 0.5),
        fround(fround(p9.max[3] - p9.min[3]) * 0.5)
    }
    local v1 = rt.fmax(rt.fmax(t4[1], t4[2]), t4[3])
    local t5 = {
        fround(fround(p9.max[1] + p9.min[1]) * 0.5),
        fround(fround(p9.max[2] + p9.min[2]) * 0.5),
        fround(fround(p9.max[3] + p9.min[3]) * 0.5)
    }

    return {
        min = {
            fround(t5[1] - v1),
            fround(t5[2] - v1),
            fround(t5[3] - v1)
        },
        max = {
            fround(t5[1] + v1),
            fround(t5[2] + v1),
            fround(t5[3] + v1)
        }
    }
end

function Bounds.inner(p10) -- line: 105
    -- upvalues: fround (copy)
    local t6 = {
        fround(fround(p10.max[1] - p10.min[1]) * -0.4000000059604645),
        fround(fround(p10.max[2] - p10.min[2]) * -0.4000000059604645),
        fround(fround(p10.max[3] - p10.min[3]) * -0.4000000059604645)
    }

    return {
        min = {
            fround(p10.min[1] - t6[1]),
            fround(p10.min[2] - t6[2]),
            fround(p10.min[3] - t6[3])
        },
        max = {
            fround(p10.max[1] + t6[1]),
            fround(p10.max[2] + t6[2]),
            fround(p10.max[3] + t6[3])
        }
    }
end

function Bounds.child(p11, p12) -- line: 124
    -- upvalues: Bounds (copy)
    local v2 = Bounds.inner(p11)

    return {
        min = {
            if bit32.band(p12, 1) == 0 then p11.min[1] else v2.min[1],
            if bit32.band(p12, 2) == 0 then p11.min[2] else v2.min[2],
            if bit32.band(p12, 4) == 0 then p11.min[3] else v2.min[3]
        },
        max = {
            if bit32.band(p12, 1) == 0 then v2.max[1] else p11.max[1],
            if bit32.band(p12, 2) == 0 then v2.max[2] else p11.max[2],
            if bit32.band(p12, 4) == 0 then v2.max[3] else p11.max[3]
        }
    }
end

function Bounds.containing_child(p13, p14) -- line: 141
    -- upvalues: fround (copy), Bounds (copy)
    local v9 = Bounds.inner(p13)
    local n1 = 0

    for i = 0, 2 do
        local v10 = fround(p14.min[i + 1] - v9.min[i + 1])
        local v11 = fround(v9.max[i + 1] - p14.max[i + 1])

        if v10 <= 0 and v11 <= 0 then
            return nil, nil
        end

        if v11 < v10 then
            n1 = bit32.bor(n1, (bit32.lshift(1, i)))
        end
    end

    return n1, Bounds.child(p13, n1)
end

function Bounds.movable(p15, p16) -- line: 157
    -- upvalues: Bounds (copy)
    local v13 = Bounds.inner(p15)

    for i = 1, 3 do
        if not (v13.max[i] > p16.max[i]) and not (p16.min[i] > v13.min[i]) then
            return false
        end
    end

    return true
end

t1.Bucket = {}

function t1.Bucket.default() -- line: 169
    return {
        child = nil,
        entries = {}
    }
end

t1.Node = {}

local Node = t1.Node

function Node.new(p17) -- line: 175
    -- upvalues: t1 (copy)
    return {
        bounds = p17,
        resident = {},
        buckets = {
            t1.Bucket.default(),
            t1.Bucket.default(),
            t1.Bucket.default(),
            t1.Bucket.default(),
            t1.Bucket.default(),
            t1.Bucket.default(),
            t1.Bucket.default(),
            t1.Bucket.default()
        }
    }
end

t1.Octree = {}

local Octree = t1.Octree

function Octree.new(p18, p19) -- line: 196
    -- upvalues: rt (copy), Bounds (copy), Node (copy), Octree (copy)
    if #p19 > 65535 then
        error("Native grind octree exceeds uint16 entry capacity", 0)
    end

    local t10 = {
        node_capacity = rt.idiv(#p19, 2) + 1,
        nodes = { Node.new(Bounds.cube(p18)) },
        bounds = p19
    }

    for i = 0, #t10.bounds - 1 do
        Octree.insert(t10, i)
    end

    return t10
end

function Octree.insert(p20, p21) -- line: 211
    -- upvalues: Bounds (copy), Octree (copy)
    local n2 = 0

    while true do
        local bounds = p20.nodes[n2 + 1].bounds
        local v14 = p20.bounds[p21 + 1]
        local v15 = true

        for i = 1, 3 do
            if not (v14.min[i] >= bounds.min[i] and v14.max[i] <= bounds.max[i]) then
                v15 = false
                break
            end
        end

        local v16, v17

        if v15 then
            v16, v17 = Bounds.containing_child(bounds, v14)
        end

        if v16 == nil then
            break
        end

        local child = p20.nodes[n2 + 1].buckets[v16 + 1].child

        if child == nil then
            local v18 = Bounds.movable(v17, v14)
            local v19 = p20.nodes[n2 + 1].buckets[v16 + 1]

            table.insert(v19.entries, {
                p21,
                v18
            })

            local n3 = 0

            for _, v20 in v19.entries do
                if v20[2] then
                    n3 += 1
                end
            end

            if n3 > 3 and #p20.nodes < p20.node_capacity then
                Octree.split(p20, n2, v16, v17)
            end

            return
        end

        n2 = child
    end

    table.insert(p20.nodes[n2 + 1].resident, p21)
end

function Octree.split(p22, p23, p24, p25) -- line: 253
    -- upvalues: rt (copy), Bounds (copy), Node (copy)
    local entries = p22.nodes[p23 + 1].buckets[p24 + 1].entries

    p22.nodes[p23 + 1].buckets[p24 + 1].entries = {}

    local v21 = #p22.nodes

    p22.nodes[p23 + 1].buckets[p24 + 1].child = v21

    local v22 = Node.new(rt.copy(p25))

    for i = #entries, 1, -1 do
        local v23 = entries[i][1]

        if entries[i][2] then
            local v24, v25 = Bounds.containing_child(p25, p22.bounds[v23 + 1])

            if v24 == nil then
                error("native movable predicate guarantees a containing child", 0)
            end

            table.insert(v22.buckets[v24 + 1].entries, {
                v23,
                Bounds.movable(v25, p22.bounds[v23 + 1])
            })
        else
            table.insert(v22.resident, v23)
        end
    end

    table.insert(p22.nodes, v22)
end

local v26 = table.create(8, 0)

function Octree.query(p26, p27, p28) -- line: 284
    -- upvalues: fround (copy), v26 (copy)
    local t13 = {}

    if p28 == 0 then
        return t13
    end

    local nodes = p26.nodes
    local t14 = {
        0
    }
    local n4 = 0
    local n5 = 1

    while true do
        if not (n5 > 0) then
            return t13
        end

        local v27 = t14[n5]

        t14[n5] = nil
        n5 -= 1

        local v28 = nodes[v27 + 1]
        local buckets, bounds = v28.buckets, v28.bounds
        local min, max = bounds.min, bounds.max
        local v29 = min[1]
        local v30 = min[2]
        local v31 = min[3]
        local v32 = max[1]
        local v33 = max[2]
        local v34 = max[3]
        local v35 = fround(fround(v32 - v29) * -0.4000000059604645)
        local v36 = fround(fround(v33 - v30) * -0.4000000059604645)
        local v37 = fround(fround(v34 - v31) * -0.4000000059604645)
        local v38 = fround(v29 - v35)
        local v39 = fround(v30 - v36)
        local v40 = fround(v31 - v37)
        local v41 = fround(v32 + v35)
        local v42 = fround(v33 + v36)
        local v43 = fround(v34 + v37)
        local n6 = 0

        for i = 0, 7 do
            local v44, v45

            if bit32.band(i, 1) == 0 then
                v45 = v41
                v44 = v29
            else
                v45 = v32
                v44 = v38
            end

            local v46, v47

            if bit32.band(i, 2) == 0 then
                v47 = v42
                v46 = v30
            else
                v47 = v33
                v46 = v39
            end

            local v48, v49

            if bit32.band(i, 4) == 0 then
                v49 = v43
                v48 = v31
            else
                v49 = v34
                v48 = v40
            end

            local min, max = p27.min, p27.max

            if v44 <= max[1] and min[1] <= v45 and v46 <= max[2] and min[2] <= v47 and v48 <= max[3] and min[3] <= v49 then
                local child = buckets[i + 1].child

                if child ~= nil then
                    n5 += 1
                    t14[n5] = child
                else
                    n6 += 1
                    v26[n6] = i
                end
            end
        end

        local bounds2 = p26.bounds
        local min2, max2 = p27.min, p27.max

        for i = n6, 1, -1 do
            local entries = buckets[v26[i] + 1].entries

            for j = #entries, 1, -1 do
                local v50 = entries[j][1]
                local v51 = bounds2[v50 + 1]
                local min, max = v51.min, v51.max

                if min[1] <= max2[1] and min2[1] <= max[1] and min[2] <= max2[2] and min2[2] <= max[2] and min[3] <= max2[3] and min2[3] <= max[3] then
                    n4 += 1
                    t13[n4] = v50

                    if n4 == p28 then
                        return t13
                    end
                end
            end
        end

        local resident = v28.resident

        for i = #resident, 1, -1 do
            local v52 = resident[i]
            local v53 = bounds2[v52 + 1]
            local min, max = v53.min, v53.max

            if min[1] <= max2[1] and min2[1] <= max[1] and min[2] <= max2[2] and min2[2] <= max[2] and min[3] <= max2[3] and min2[3] <= max[3] then
                n4 += 1
                t13[n4] = v52

                if n4 == p28 then
                    return t13
                end
            end
        end
    end
end

function Octree.query_reference(p29, p30, p31) -- line: 402
    -- upvalues: Bounds (copy)
    local t15 = {}

    if p31 == 0 then
        return t15
    end

    local t16 = {
        0
    }

    while true do
        if not (#t16 > 0) then
            return t15
        end

        local v54 = table.remove(t16)
        local v55 = p29.nodes[v54 + 1]
        local t17 = {}

        for i = 0, 7 do
            if Bounds.overlaps(Bounds.child(v55.bounds, i), p30) then
                local child = v55.buckets[i + 1].child

                if child ~= nil then
                    table.insert(t16, child)
                else
                    table.insert(t17, i)
                end
            end
        end

        for i = #t17, 1, -1 do
            local v56 = t17[i]
            local entries = v55.buckets[v56 + 1].entries

            for j = #entries, 1, -1 do
                local v57 = entries[j][1]

                if Bounds.overlaps(p29.bounds[v57 + 1], p30) then
                    table.insert(t15, v57)

                    if #t15 == p31 then
                        return t15
                    end
                end
            end
        end

        for i = #v55.resident, 1, -1 do
            local v58 = v55.resident[i]

            if Bounds.overlaps(p29.bounds[v58 + 1], p30) then
                table.insert(t15, v58)

                if #t15 == p31 then
                    return t15
                end
            end
        end
    end
end

return t1
