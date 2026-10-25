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

local function rtl_fround(p2) -- line: 16
    -- upvalues: v1 (copy)
    if p2 ~= 0 and p2 > -1.1754943508222875E-38 and p2 < 1.1754943508222875E-38 then
        local v6 = math.abs(p2) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        local v8 = v5 * 1.401298464324817E-45

        if p2 < 0 then
            return -v8
        end

        return v8
    end

    buffer.writef32(v1, 0, p2)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local v9 = import("skate_core/physics/collision/arithmetic")
local edge_cos_test = import("skate_core/physics/collision/edge").edge_cos_test
local dot, cross, scale, neg = v9.dot, v9.cross, v9.scale, v9.neg
local sub, madd, normalize, inverse_length_squared = v9.sub, v9.madd, v9.normalize, v9.inverse_length_squared
local t1 = {
    TriangleRegion = {},
    TriangleFeature = {}
}
local TriangleFeature = t1.TriangleFeature

TriangleFeature.ONE_SIDED = 16
TriangleFeature.USE_EDGE_COSINES = 256

function TriangleFeature.edge_convex(p3, p4) -- line: 56
    return bit32.band(p3.flags, (bit32.lshift(32, p4))) ~= 0
end

function TriangleFeature.vertex_disabled(p5, p6) -- line: 59
    return bit32.band(p5.flags, (bit32.lshift(512, p6))) ~= 0
end

function TriangleFeature.classify(p7, p8) -- line: 65
    -- upvalues: dot (copy)
    local v12 = dot(p8, p7.edges[1])
    local v13 = dot(p8, p7.edges[2])
    local v14 = dot(p8, p7.edges[3])

    if v12 > 0.05000000074505806 and v13 < -0.05000000074505806 then
        return "Vertex2"
    end

    if v13 > 0.05000000074505806 and v14 < -0.05000000074505806 then
        return "Vertex1"
    end

    if v14 > 0.05000000074505806 and v12 < -0.05000000074505806 then
        return "Vertex0"
    end

    if -v14 < v12 and v12 <= -v13 then
        return "Edge2"
    end

    if -v12 < v13 and v13 <= -v14 then
        return "Edge1"
    end

    if not (-v13 < v14 and v14 <= -v12) then
        return "Face"
    end

    return "Edge0"
end

t1.ContactPair = {}

function t1.ContactPair.eq(p9, p10) -- line: 89
    if p9.a.x == p10.a.x and p9.a.y == p10.a.y and p9.a.z == p10.a.z and p9.b.x == p10.b.x and p9.b.y == p10.b.y then
        return p9.b.z == p10.b.z
    end

    return false
end

t1.TriangleFixup = {}

local one_sided_edge, bend, bend_reaches

t1.BEND_REACH = nil
t1.DEFAULT_REACH = nil
t1.BEND_FACING = nil
t1.BEND_RIDER_ALL_FACES = false
t1.in_rider_query = false
t1.bend_refused = 0

function t1.set_bend_reach(p11) -- line: 141
    -- upvalues: t1 (copy)
    local BEND_REACH = t1.BEND_REACH

    t1.BEND_REACH = p11

    return BEND_REACH
end

local function fix_up_triangle_reference(p12, p13, p14, p15) -- line: 152
    -- upvalues: rt (copy), edge_cos_test (copy), dot (copy), cross (copy), scale (copy), neg (copy), sub (copy), normalize (copy), t1 (copy), TriangleFeature (copy), one_sided_edge (ref), bend (ref), bend_reaches (ref)
    if not (#p14 <= 16) then
        error("assertion failed: contacts.len() <= 16", 0)
    end

    local v15 = if p15.reverse then neg(p13) else rt.copy(p13)
    local v16 = dot(v15, p12.normal)
    local v17 = if math.abs(v16) < 0.9998499751091003 then TriangleFeature.classify(p12, normalize(sub(v15, scale(p12.normal, v16)), 2)) else "Face"
    local v18 = bit32.band(p12.flags, TriangleFeature.ONE_SIDED) ~= 0
    local v19 = if v17 == "Edge0" then 0
        elseif v17 == "Edge1" then 1
        elseif v17 == "Edge2" then 2
        else nil
    local v20 = if v17 == "Vertex0" then 0
        elseif v17 == "Vertex1" then 1
        elseif v17 == "Vertex2" then 2
        else nil

    if bit32.band(p12.flags, TriangleFeature.USE_EDGE_COSINES) == 0 then
        if v17 == "Face" then
            return not v18 or v16 > 0
        end

        local v21, v22

        if v18 then
            if v16 > 0.9998499751091003 then
                return true
            end

            v21 = v16 < 0
        else
            v22 = math.abs(v16) > 0.9998499751091003
        end

        if (not v18 or v21) and (v18 or v22) then
            return not v18
        end

        if v19 ~= nil then
            return TriangleFeature.edge_convex(p12, v19)
        end

        if v20 == nil then
            error("called `Option::unwrap()` on a `None` value", 0)
        end

        return not TriangleFeature.vertex_disabled(p12, v20)
    end

    if v17 == "Face" then
        return not v18 or v16 > 0
    end

    if v19 == nil then
        if v20 == nil then
            error("called `Option::unwrap()` on a `None` value", 0)
        end

        local v23 = rt.irem(v20 + 2, 3)

        if v18 then
            local v24 = TriangleFeature.vertex_disabled(p12, v20) and not p15.is_object

            if v16 > 0 and v24 then
                local v25 = TriangleFeature.edge_convex(p12, v23)
                local v26 = TriangleFeature.edge_convex(p12, v20)
                local v27

                if not v25 or v26 then
                    if v25 or not v26 then
                        return false
                    end

                    v27 = v23
                else
                    v27 = v20
                end

                local v28 = p12.edge_cosines[v27 + 1]

                if not (v28 <= 0.9700000286102295 and v28 > 0.0010000000474974513) then
                    return false
                end

                local v29 = p12.edges[2 - (if v27 == v20 then v23 else v20) + 1]
                local v30 = normalize(cross(cross(v29, v15), v29), 1)

                if t1.BEND_REACH ~= nil and not bend_reaches(p14, v30) then
                    return false
                end

                bend(p13, p14, v30, p15.reverse)

                return true
            end

            if v24 then
                return false
            end

            for _, v31 in { v23, v20 } do
                if not edge_cos_test(neg(p12.edges[2 - v31 + 1]), p12.normal, v15, p12.edge_cosines[v31 + 1], TriangleFeature.edge_convex(p12, v31), false) then
                    return false
                end
            end
        else
            if TriangleFeature.vertex_disabled(p12, v20) then
                return false
            end

            for _, v32 in { v23, v20 } do
                if not edge_cos_test(neg(p12.edges[2 - v32 + 1]), p12.normal, v15, p12.edge_cosines[v32 + 1], TriangleFeature.edge_convex(p12, v32), true) then
                    return false
                end
            end
        end

        return true
    end

    if v18 then
        return one_sided_edge(p12, v19, v16, p13, p14, p15)
    end

    if not TriangleFeature.edge_convex(p12, v19) then
        v16 = -v16
    end

    return p12.edge_cosines[v19 + 1] <= v16
end

function one_sided_edge(p16, p17, p18, p19, p20, p21) -- line: 287
    -- upvalues: v1 (copy), inverse_length_squared (copy), t1 (copy), TriangleFeature (copy), bend (ref), bend_reaches (ref)
    local v33 = p16.edge_cosines[p17 + 1]

    if TriangleFeature.edge_convex(p16, p17) or p21.is_object and math.abs(v33 - 1) < 1E-05 then
        return v33 <= p18 + p21.convexity_epsilon
    end

    if p21.edge_cos_bend_normal_threshold < v33 or v33 <= 0.0010000000474974513 then
        return false
    end

    local v36 = 1 - v33 * v33
    local v37

    if v36 == 0 then
        buffer.writef32(v1, 0, v36)
        v37 = buffer.readf32(v1, 0)
    elseif v36 > -1.1754943508222875E-38 and v36 < 1.1754943508222875E-38 then
        local v38 = math.abs(v36) * 7.1362384635298E+44
        local v39 = math.floor(v38)
        local v40 = v38 - v39

        if v40 > 0.5 or v40 == 0.5 and v39 % 2 == 1 then
            v39 += 1
        end

        v37 = v39 * 1.401298464324817E-45

        if v36 < 0 then
            v37 = -v37
        end
    else
        buffer.writef32(v1, 0, v36)
        v37 = buffer.readf32(v1, 0)
    end

    if (if v37 == 0 then 0 else v37 * inverse_length_squared(v37, 2)) < p18 then
        if t1.BEND_REACH ~= nil and not bend_reaches(p20, p16.normal) then
            return false
        end

        bend(p19, p20, p16.normal, p21.reverse)

        return true
    end

    return false
end

t1.one_sided_edge = one_sided_edge

function bend(p22, p23, p24, p25) -- line: 311
    -- upvalues: rt (copy), dot (copy), neg (copy), sub (copy), madd (copy)
    local v41 = rt.copy(p24)

    rt.assign(p22, if p25 then neg(v41) else v41)

    for _, v42 in p23 do
        if p25 then
            v42.b = madd(v41, dot(sub(v42.b, v42.a), v41), v42.a)
        else
            v42.a = madd(v41, dot(sub(v42.a, v42.b), v41), v42.b)
        end
    end
end

t1.bend = bend

function bend_reaches(p26, p27) -- line: 327
    -- upvalues: t1 (copy)
    local BEND_REACH = t1.BEND_REACH
    local x, y, z = p27.x, p27.y, p27.z

    if t1.BEND_FACING ~= nil and t1.BEND_FACING < y and (not t1.in_rider_query or not t1.BEND_RIDER_ALL_FACES) then
        return true
    end

    for _, v43 in p26 do
        local a, b = v43.a, v43.b
        local v44 = a.x - b.x
        local v45 = a.y - b.y
        local v46 = a.z - b.z
        local v47 = v44 * x + v45 * y + v46 * z
        local v48 = v44 - x * v47
        local v49 = v45 - y * v47
        local v50 = v46 - z * v47

        if v48 * v48 + v49 * v49 + v50 * v50 > BEND_REACH * BEND_REACH then
            t1.bend_refused += 1

            if t1.on_refuse ~= nil then
                t1.on_refuse(p27, a, b, (math.sqrt(v48 * v48 + v49 * v49 + v50 * v50)))
            end

            return false
        end
    end

    return true
end

t1.bend_reaches = bend_reaches
t1.fix_up_triangle_reference = fix_up_triangle_reference

local edge_cos_test_xyz = import("skate_core/physics/collision/edge").edge_cos_test_xyz

function t1.fix_up_triangle(p28, p29, p30, p31) -- line: 392
    -- upvalues: t1 (copy), one_sided_edge (ref), bend (ref), bend_reaches (ref), edge_cos_test_xyz (copy)
    if not (#p30 <= 16) then
        error("assertion failed: contacts.len() <= 16", 0)
    end

    local v52, v53, v54

    if p31.reverse then
        v52 = -p29.x
        v53 = -p29.y
        v54 = -p29.z
    else
        v52 = p29.x
        v53 = p29.y
        v54 = p29.z
    end

    local normal = p28.normal
    local x, y, z = normal.x, normal.y, normal.z
    local v55 = v52 * x + v53 * y + v54 * z
    local v56 = 0

    if math.abs(v55) < 0.9998499751091003 then
        local v57 = v52 - x * v55
        local v58 = v53 - y * v55
        local v59 = v54 - z * v55
        local v60 = v57 * v57 + v58 * v58 + v59 * v59
        local v61 = 1 / math.sqrt(v60)
        local v62 = v61 * 0.5 * (-v60 * (v61 * v61) + 1) + v61
        local v63 = v62 * 0.5 * (-v60 * (v62 * v62) + 1) + v62
        local v64 = v57 * v63
        local v65 = v58 * v63
        local v66 = v59 * v63
        local edges = p28.edges
        local v67 = edges[1]
        local v68 = edges[2]
        local v69 = edges[3]
        local v70 = v64 * v67.x + v65 * v67.y + v66 * v67.z
        local v71 = v64 * v68.x + v65 * v68.y + v66 * v68.z
        local v72 = v64 * v69.x + v65 * v69.y + v66 * v69.z

        v56 = if v70 > 0.05000000074505806 and v71 < -0.05000000074505806 then 6
            elseif v71 > 0.05000000074505806 and v72 < -0.05000000074505806 then 5
            elseif v72 > 0.05000000074505806 and v70 < -0.05000000074505806 then 4
            elseif -v72 < v70 and v70 <= -v71 then 3
            elseif -v70 < v71 and v71 <= -v72 then 2
            elseif -v71 < v72 and v72 <= -v70 then 1
            else 0
    end

    local flags = p28.flags
    local v73 = bit32.band(flags, 16) ~= 0

    if bit32.band(flags, 256) == 0 then
        if v56 == 0 then
            return not v73 or v55 > 0
        end

        local v74, v75

        if v73 then
            if v55 > 0.9998499751091003 then
                return true
            end

            v74 = v55 < 0
        else
            v75 = math.abs(v55) > 0.9998499751091003
        end

        if (not v73 or v74) and (v73 or v75) then
            return not v73
        end

        if v56 <= 3 then
            return bit32.band(flags, (bit32.lshift(32, v56 - 1))) ~= 0
        end

        return bit32.band(flags, (bit32.lshift(512, v56 - 4))) == 0
    end

    if v56 == 0 then
        return not v73 or v55 > 0
    end

    if v56 <= 3 then
        local v80 = v56 - 1

        if v73 then
            return one_sided_edge(p28, v80, v55, p29, p30, p31)
        end

        if bit32.band(flags, (bit32.lshift(32, v80))) == 0 then
            v55 = -v55
        end

        return p28.edge_cosines[v80 + 1] <= v55
    end

    local v82 = v56 - 4
    local v83 = (v82 + 2) % 3
    local v85 = bit32.band(flags, (bit32.lshift(512, v82))) ~= 0

    if v73 then
        local v86 = v85 and not p31.is_object

        if v55 > 0 and v86 then
            local v88 = bit32.band(flags, (bit32.lshift(32, v83))) ~= 0
            local v90 = bit32.band(flags, (bit32.lshift(32, v82))) ~= 0
            local v91

            if not v88 or v90 then
                if v88 or not v90 then
                    return false
                end

                v91 = v83
            else
                v91 = v82
            end

            local v92 = p28.edge_cosines[v91 + 1]

            if not (v92 <= 0.9700000286102295 and v92 > 0.0010000000474974513) then
                return false
            end

            local v93 = p28.edges[2 - (if v91 == v82 then v83 else v82) + 1]
            local x, y, z = v93.x, v93.y, v93.z
            local v94 = -z * v53 + y * v54
            local v95 = -x * v54 + z * v52
            local v96 = -y * v52 + x * v53
            local v97 = -v96 * y + v95 * z
            local v98 = -v94 * z + v96 * x
            local v99 = -v95 * x + v94 * y
            local v100 = v97 * v97 + v98 * v98 + v99 * v99
            local v101 = 1 / math.sqrt(v100)
            local v102 = v101 * 0.5 * (-v100 * (v101 * v101) + 1) + v101
            local t2 = {
                x = v97 * v102,
                y = v98 * v102,
                z = v99 * v102
            }

            if t1.BEND_REACH ~= nil and not bend_reaches(p30, t2) then
                return false
            end

            bend(p29, p30, t2, p31.reverse)

            return true
        end

        if v86 then
            return false
        end

        local edges, edge_cosines = p28.edges, p28.edge_cosines
        local v103 = edges[2 - v83 + 1]

        if not edge_cos_test_xyz(-v103.x, -v103.y, -v103.z, x, y, z, v52, v53, v54, edge_cosines[v83 + 1], bit32.band(flags, (bit32.lshift(32, v83))) ~= 0, false) then
            return false
        end

        local v109 = edges[2 - v82 + 1]

        return edge_cos_test_xyz(-v109.x, -v109.y, -v109.z, x, y, z, v52, v53, v54, edge_cosines[v82 + 1], bit32.band(flags, (bit32.lshift(32, v82))) ~= 0, false)
    end

    if v85 then
        return false
    end

    local edges, edge_cosines = p28.edges, p28.edge_cosines
    local v115 = edges[2 - v83 + 1]

    if not edge_cos_test_xyz(-v115.x, -v115.y, -v115.z, x, y, z, v52, v53, v54, edge_cosines[v83 + 1], bit32.band(flags, (bit32.lshift(32, v83))) ~= 0, true) then
        return false
    end

    local v121 = edges[2 - v82 + 1]

    return edge_cos_test_xyz(-v121.x, -v121.y, -v121.z, x, y, z, v52, v53, v54, edge_cosines[v82 + 1], bit32.band(flags, (bit32.lshift(32, v82))) ~= 0, true)
end

return t1
