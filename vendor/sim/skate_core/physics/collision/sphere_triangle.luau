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
local fix_up_triangle = import("skate_core/physics/collision/fixup").fix_up_triangle
local dot, cross, scale, neg = v9.dot, v9.cross, v9.scale, v9.neg
local sub, madd, inverse_length_squared = v9.sub, v9.madd, v9.inverse_length_squared
local t1 = {
    Sphere = {},
    Triangle = {},
    SphereTrianglePair = {},
    SphereTrianglePrism = {}
}
local build_prism, interval_gaps, min, max, point_face

function t1.intersect_sphere_triangle(p3, p4, p5, p6) -- line: 74
    -- upvalues: rt (copy), fix_up_triangle (copy), dot (copy), scale (copy), sub (copy), madd (copy), build_prism (ref)
    local v10 = build_prism(p3, p4, p5, p6, false)

    if v10 ~= nil then
        local separating_direction, separating_distance, normal, raw_points = v10.separating_direction, v10.separating_distance, v10.normal, v10.raw_points
        local triangle_region = v10.triangle_region
        local v11 = if p6 then p4.fatness else p3.radius
        local v12 = if p6 then p3.radius else p4.fatness
        local t2 = {
            a = madd(normal, v11, raw_points.a),
            b = sub(raw_points.b, scale(normal, v12))
        }
        local v13 = dot(sub(t2.b, t2.a), normal)
        local t3 = {
            edge_cos_bend_normal_threshold = -1,
            convexity_epsilon = 0,
            is_object = false,
            reverse = not p6
        }

        if fix_up_triangle(p4.feature, normal, { rt.copy(raw_points) }, t3) then
            return {
                separating_direction = separating_direction,
                separating_distance = separating_distance,
                normal = normal,
                points = t2,
                distance = v13,
                triangle_region = triangle_region
            }
        end
    end

    return nil
end

function build_prism(p7, p8, p9, p10, p11) -- line: 120
    -- upvalues: rt (copy), v1 (copy), dot (copy), scale (copy), neg (copy), sub (copy), inverse_length_squared (copy), interval_gaps (ref), point_face (ref)
    local normal = p8.feature.normal
    local v14, v15 = interval_gaps(p7, p8, normal, p10)
    local v16

    if v15 < v14 then
        v16 = neg(normal)
    else
        v14 = v15
        v16 = rt.copy(normal)
    end

    local v18 = if p10 then p8.fatness else p7.radius
    local v17 = if p10 then p7.radius else p8.fatness

    if v17 + p9 + v18 < v14 then
        return nil
    end

    local v19, v20 = point_face(p7.center, p8, v16, p10)
    local t4 = if p10 then {
        a = v19,
        b = rt.copy(p7.center)
    } else {
        a = rt.copy(p7.center),
        b = v19
    }
    local v21 = sub(t4.b, t4.a)
    local v22 = dot(v21, v21)
    local v23

    if v22 ~= 0 and v22 > -1.1754943508222875E-38 and v22 < 1.1754943508222875E-38 then
        local v24 = math.abs(v22) * 7.1362384635298E+44
        local v25 = math.floor(v24)
        local v26 = v24 - v25

        v23 = (if v26 > 0.5 or v26 == 0.5 and v25 % 2 == 1 then v25 + 1 else v25) * 1.401298464324817E-45

        if v22 < 0 then
            v23 = -v23
        end
    else
        buffer.writef32(v1, 0, v22)
        v23 = buffer.readf32(v1, 0)
    end

    local v27 = inverse_length_squared(v23, 2)

    if p11 then
        if v23 == 0 then
            v23 = 0
        else
            v23 *= v27
        end
    end

    local v28 = rt.copy(v16)
    local v29

    if not (v23 > 1.1920928955078125E-07) then
        v29 = v28

        return {
            separating_direction = v16,
            separating_distance = v14,
            normal = v29,
            raw_points = t4,
            triangle_region = v20
        }
    end

    local v30 = scale(v21, v27)
    local v31, v32 = interval_gaps(p7, p8, v30, p10)

    v29 = if not (v14 <= (if v32 < v31 then v31 else v32)) then v28 elseif v32 < v31 then neg(v30) else v30

    return {
        separating_direction = v16,
        separating_distance = v14,
        normal = v29,
        raw_points = t4,
        triangle_region = v20
    }
end

t1.build_prism = build_prism

function interval_gaps(p12, p13, p14, p15) -- line: 181
    -- upvalues: dot (copy), min (ref), max (ref)
    local v33 = dot(p14, p12.center)
    local t5 = {
        dot(p14, p13.vertices[1]),
        dot(p14, p13.vertices[2]),
        dot(p14, p13.vertices[3])
    }
    local v34 = min(min(t5[1], t5[2]), t5[3])
    local v35 = max(max(t5[1], t5[2]), t5[3])

    if p15 then
        return v34 - v33, v33 - v35
    end

    return v33 - v35, v34 - v33
end

t1.interval_gaps = interval_gaps

function min(p16, p17) -- line: 199
    if p16 < p17 then
        return p16
    end

    return p17
end

t1.min = min

function max(p18, p19) -- line: 207
    if p19 < p18 then
        return p18
    end

    return p19
end

t1.max = max

function point_face(p20, p21, p22, p23) -- line: 217
    -- upvalues: rt (copy), dot (copy), cross (copy), scale (copy), neg (copy), sub (copy), madd (copy), inverse_length_squared (copy)
    local v37 = dot(if p23 then p22 else neg(p22), p21.feature.normal) < 0 == p23
    local t6 = if v37 then { 0, 1, 2 } else { 2, 1, 0 }
    local t7 = if v37 then { 0, 2, 1 } else { 0, 1, 2 }
    local v38 = if v37 then 8 else 0
    local v39 = madd(p22, dot(p22, sub(p21.vertices[1], p20)), p20)
    local v40 = table.create(3)

    for i = 1, 3 do
        local v41 = t6[i]
        local v43 = cross(if v37 then p21.feature.edges[v41 + 1] else neg(p21.feature.edges[v41 + 1]), p22)
        local v44 = dot(v43, v43)

        v40[i] = scale(v43, if v44 > 1.1920928955078125E-07 then inverse_length_squared(v44, 1) else 0)
    end

    local n1 = 0
    local n2 = 0

    for i = 0, 2 do
        local v46 = dot(v40[i + 1], sub(v39, p21.vertices[t7[i + 1] + 1]))

        if i == 0 or n2 < v46 then
            n2 = v46
            n1 = i
        end
    end

    local v47, v48

    if not (n2 > 0) then
        v47 = v39
        v48 = v38

        return v47, v48
    end

    local v49 = sub(v39, scale(v40[n1 + 1], n2))
    local v50 = t6[n1 + 1]
    local v51 = p21.vertices[t7[n1 + 1] + 1]
    local v52 = if v37 then p21.feature.edges[v50 + 1] else neg(p21.feature.edges[v50 + 1])
    local v53 = dot(sub(v49, v51), v52)
    local n3 = 2

    if v53 < 0 then
        v47 = rt.copy(v51)
        n3 = 1
    elseif p21.edge_lengths[v50 + 1] < v53 then
        v47 = madd(v52, p21.edge_lengths[v50 + 1], v51)
        n3 = 3
    else
        v47 = madd(v52, v53, v51)
    end

    return v47, v38 + (n1 * 2 + n3)
end

t1.point_face = point_face

return t1
