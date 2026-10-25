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
local BoardWorld = import("skate_core/physics/board_world").BoardWorld
local v1 = import("skate_core/physics/triangle_query")
local triangle_segment = v1.triangle_segment
local t1 = {
    IDENTITY = {
        { 1, 0, 0, 0 },
        { 0, 1, 0, 0 },
        { 0, 0, 1, 0 },
        { 0, 0, 0, 0 }
    }
}
local triangle_box, separated, dot, sub, cross, vec3, lanes

function t1.line_reference(p2, p3, p4, p5) -- line: 38
    -- upvalues: rt (copy), Vector3 (copy), BoardWorld (copy), triangle_segment (copy), t1 (copy), vec3 (ref), lanes (ref)
    local v2 = not (p5 == p5 and p5 ~= 1e999 and p5 ~= (-1e999)) or p5 < 0

    if not v2 then
        for i = 1, 4 do
            local v3 = p3[i]

            if v3 ~= v3 or v3 == 1e999 or v3 == (-1e999) then
                v2 = true
                break
            end
        end
    end

    if not v2 then
        for i = 1, 4 do
            local v4 = p4[i]

            if v4 ~= v4 or v4 == 1e999 or v4 == (-1e999) then
                v2 = true
                break
            end
        end
    end

    if v2 then
        error("Non-finite trajectory collision request or invalid radius", 0)
    end

    local v5 = vec3(p3)
    local v6 = Vector3.new(p4[1] - v5.x, p4[2] - v5.y, p4[3] - v5.z)
    local v7 = rt.F32_MAX
    local t2

    for _, v8 in BoardWorld.line_candidates(p2, v5, vec3(p4), p5) do
        local v9 = v8[1]
        local v10 = v8[2]
        local t3 = {
            fraction = 0,
            position = rt.copy(Vector3.ZERO),
            normal = rt.copy(Vector3.ZERO),
            volume_parameter = table.create(3, 0)
        }

        if triangle_segment(t3, v5, v6, v10.triangle.vertices, p5, 0) then
            local v11 = if -t3.fraction >= 0 then 0 else t3.fraction

            if not (1 - v11 >= 0) then
                v11 = 1
            end

            if v11 < v7 then
                if v9 > 4294967295 then
                    error("World geometry index overflow", 0)
                end

                v7 = v11
                t2 = {
                    position = lanes(t3.position),
                    normal = lanes(v10.triangle.feature.normal),
                    transform = rt.copy(t1.IDENTITY),
                    surface = v10.tag,
                    geometry = v9
                }
            end
        end
    end

    local v12 = BoardWorld.external_line(p2, v5, vec3(p4), p5)

    if v12 ~= nil then
        local geometry = v12.hit.geometry

        if rt.clamp(geometry.fraction, 0, 1) < v7 then
            t2 = {
                position = lanes(geometry.position),
                normal = lanes(geometry.normal),
                transform = rt.copy(v12.frame),
                surface = v12.hit.tag,
                geometry = v12.geometry_id
            }
        end
    end

    return t2
end

local thin_triangle, triangle_segment_transient = v1.thin_triangle, v1.triangle_segment_transient
local line_candidate_indices = BoardWorld.line_candidate_indices
local is_finite = rt.is_finite
local v13 = Vector3.new(0, 0, 0)
local v14 = Vector3.new(0, 0, 0)
local v15 = Vector3.new(0, 0, 0)
local v16 = Vector3.new(0, 0, 0)
local v17 = Vector3.new(0, 0, 0)
local t4 = {
    0, 0, 0
}
local t5 = {
    fraction = 0,
    position = v16,
    normal = v17,
    volume_parameter = t4
}
local v18 = table.create(256, 0)

function t1.line(p6, p7, p8, p9) -- line: 143
    -- upvalues: rt (copy), t1 (copy), lanes (ref), thin_triangle (copy), triangle_segment_transient (copy), line_candidate_indices (copy), is_finite (copy), v13 (copy), v14 (copy), v15 (copy), v16 (copy), v17 (copy), t4 (copy), t5 (copy), v18 (copy)
    if p6.external ~= nil then
        return t1.line_reference(p6, p7, p8, p9)
    end

    local v19 = not is_finite(p9) or p9 < 0

    if not v19 then
        for i = 1, 4 do
            if not is_finite(p7[i]) then
                v19 = true
                break
            end
        end
    end

    if not v19 then
        for i = 1, 4 do
            if not is_finite(p8[i]) then
                v19 = true
                break
            end
        end
    end

    if v19 then
        error("Non-finite trajectory collision request or invalid radius", 0)
    end

    local v20 = p7[1]
    local v21 = p7[2]
    local v22 = p7[3]
    local v23 = p8[1]
    local v24 = p8[2]
    local v25 = p8[3]

    v13.x = v20
    v13.y = v21
    v13.z = v22
    v14.x = v23
    v14.y = v24
    v14.z = v25

    local v26 = v23 - v20
    local v27 = v24 - v21
    local v28 = v25 - v22

    v15.x = v26
    v15.y = v27
    v15.z = v28

    local v29 = rt.F32_MAX
    local v30 = p9 + 0 == 0
    local triangles = p6.triangles
    local n1 = 0
    local n2 = 0
    local n3 = 0
    local v32

    for i = 1, line_candidate_indices(p6, v13, v14, p9, v18) do
        local v33 = v18[i]
        local vertices = triangles[v33 + 1].triangle.vertices
        local v34

        if v30 then
            v34 = thin_triangle(v13, v15, vertices)
        else
            v34 = t5
            v16.x = 0
            v16.y = 0
            v16.z = 0
            v17.x = 0
            v17.y = 0
            v17.z = 0
            t4[1] = 0
            t4[2] = 0
            t4[3] = 0
            t5.position = v16
            t5.normal = v17
            t5.fraction = 0
            t5.volume_parameter = t4

            if not triangle_segment_transient(t5, v13, v15, vertices, p9, 0) then
                v34 = nil
            end
        end

        local v35 = v29
        local v36 = v32
        local v37 = n1
        local v38 = n2
        local v39 = n3

        if v34 ~= nil then
            local fraction = v34.fraction

            if -fraction >= 0 then
                fraction = 0
            end

            local v40 = if 1 - fraction >= 0 then fraction else 1

            if v40 < v29 then
                if v33 > 4294967295 then
                    error("World geometry index overflow", 0)
                end

                local position = v34.position

                v36 = v33
                v35 = v40
                v37 = position.x
                v38 = position.y
                v39 = position.z
            end
        end

        n3 = v39
        v32 = v36
        v29 = v35
        n1 = v37
        n2 = v38
    end

    if v32 == nil then
        return nil
    end

    local v41 = triangles[v32 + 1]

    return {
        position = { n1, n2, n3, 0 },
        normal = lanes(v41.triangle.feature.normal),
        transform = rt.copy(t1.IDENTITY),
        surface = v41.tag,
        geometry = v32
    }
end

local function separated_scalar(p10, p11, p12, p13, p14, p15, p16, p17, p18, p19, p20, p21, p22, p23, p24) -- line: 232
    -- upvalues: rt (copy)
    local v42 = p10 * p19 + p11 * p20 + p12 * p21
    local v43 = p13 * p19 + p14 * p20 + p15 * p21
    local v44 = p16 * p19 + p17 * p20 + p18 * p21
    local v45 = rt.fmin(rt.fmin(v42, v43), v44)
    local v46 = rt.fmax(rt.fmax(v42, v43), v44)
    local v47 = p22 * math.abs(p19) + p23 * math.abs(p20) + p24 * math.abs(p21)

    if v47 < v45 then
        return true
    end

    return v46 < -v47
end

local function cross_separated(p25, p26, p27, p28, p29, p30, p31, p32, p33, p34, p35, p36, p37, p38, p39, p40, p41, p42) -- line: 252
    -- upvalues: separated_scalar (copy)
    return (separated_scalar(p31, p32, p33, p34, p35, p36, p37, p38, p39, -p27 * p29 + p26 * p30, -p25 * p30 + p27 * p28, -p26 * p28 + p25 * p29, p40, p41, p42))
end

local function triangle_box_scalar(p43, p44, p45, p46, p47, p48, p49, p50, p51) -- line: 271
    -- upvalues: separated_scalar (copy), cross_separated (copy)
    local v51 = (p46 + p49) * 0.5
    local v52 = (p47 + p50) * 0.5
    local v53 = (p48 + p51) * 0.5
    local v54 = (p49 - p46) * 0.5
    local v55 = (p50 - p47) * 0.5
    local v56 = (p51 - p48) * 0.5
    local v57 = p43.x - v51
    local v58 = p43.y - v52
    local v59 = p43.z - v53
    local v60 = p44.x - v51
    local v61 = p44.y - v52
    local v62 = p44.z - v53
    local v63 = p45.x - v51
    local v64 = p45.y - v52
    local v65 = p45.z - v53
    local v66 = v60 - v57
    local v67 = v61 - v58
    local v68 = v62 - v59
    local v69 = v63 - v60
    local v70 = v64 - v61
    local v71 = v65 - v62
    local v72 = v57 - v63
    local v73 = v58 - v64
    local v74 = v59 - v65

    if cross_separated(v66, v67, v68, 1, 0, 0, v57, v58, v59, v60, v61, v62, v63, v64, v65, v54, v55, v56)
        or cross_separated(v66, v67, v68, 0, 1, 0, v57, v58, v59, v60, v61, v62, v63, v64, v65, v54, v55, v56)
        or cross_separated(v66, v67, v68, 0, 0, 1, v57, v58, v59, v60, v61, v62, v63, v64, v65, v54, v55, v56)
        or cross_separated(v69, v70, v71, 1, 0, 0, v57, v58, v59, v60, v61, v62, v63, v64, v65, v54, v55, v56)
        or cross_separated(v69, v70, v71, 0, 1, 0, v57, v58, v59, v60, v61, v62, v63, v64, v65, v54, v55, v56)
        or cross_separated(v69, v70, v71, 0, 0, 1, v57, v58, v59, v60, v61, v62, v63, v64, v65, v54, v55, v56)
        or cross_separated(v72, v73, v74, 1, 0, 0, v57, v58, v59, v60, v61, v62, v63, v64, v65, v54, v55, v56)
        or cross_separated(v72, v73, v74, 0, 1, 0, v57, v58, v59, v60, v61, v62, v63, v64, v65, v54, v55, v56)
        or cross_separated(v72, v73, v74, 0, 0, 1, v57, v58, v59, v60, v61, v62, v63, v64, v65, v54, v55, v56) then
        return false
    end

    if not separated_scalar(v57, v58, v59, v60, v61, v62, v63, v64, v65, 1, 0, 0, v54, v55, v56) and not separated_scalar(v57, v58, v59, v60, v61, v62, v63, v64, v65, 0, 1, 0, v54, v55, v56) and not separated_scalar(v57, v58, v59, v60, v61, v62, v63, v64, v65, 0, 0, 1, v54, v55, v56) then
        return not cross_separated(v66, v67, v68, v69, v70, v71, v57, v58, v59, v60, v61, v62, v63, v64, v65, v54, v55, v56)
    end

    return false
end

t1.triangle_box_scalar = triangle_box_scalar

function t1.nearby(p52, p53, p54) -- line: 315
    -- upvalues: BoardWorld (copy), vec3 (ref), lanes (ref), line_candidate_indices (copy), v13 (copy), v18 (copy), triangle_box_scalar (copy)
    if not (p54 == p54 and p54 ~= 1e999 and p54 ~= (-1e999)) or p54 < 0 then
        error("Invalid nearby-trajectory triangle radius", 0)
    end

    local v75 = p53[1] - p54
    local v76 = p53[2] - p54
    local v77 = p53[3] - p54
    local v78 = p53[1] + p54
    local v79 = p53[2] + p54
    local v80 = p53[3] + p54
    local t6 = {}
    local v81 = p53[1]
    local v82 = p53[2]
    local v83 = p53[3]

    v13.x = v81
    v13.y = v82
    v13.z = v83

    local triangles = p52.triangles

    for i = 1, line_candidate_indices(p52, v13, v13, p54, v18) do
        local vertices = triangles[v18[i] + 1].triangle.vertices
        local v84 = vertices[1]
        local v85 = vertices[2]
        local v86 = vertices[3]

        if triangle_box_scalar(v84, v85, v86, v75, v76, v77, v78, v79, v80) then
            table.insert(t6, {
                lanes(v84),
                lanes(v85),
                lanes(v86)
            })

            if #t6 == 64 then
                break
            end
        end
    end

    if #t6 < 64 then
        for _, v87 in BoardWorld.external_nearby(p52, vec3(p53), p54) do
            local v88 = v87[1]
            local v89 = v87[2]
            local v90 = v87[3]

            if triangle_box_scalar(v88, v89, v90, v75, v76, v77, v78, v79, v80) then
                table.insert(t6, {
                    lanes(v88),
                    lanes(v89),
                    lanes(v90)
                })

                if #t6 == 64 then
                    break
                end
            end
        end
    end

    return t6
end

function t1.nearby_reference(p55, p56, p57) -- line: 358
    -- upvalues: BoardWorld (copy), triangle_box (ref), vec3 (ref), lanes (ref)
    if not (p57 == p57 and p57 ~= 1e999 and p57 ~= (-1e999)) or p57 < 0 then
        error("Invalid nearby-trajectory triangle radius", 0)
    end

    local t9 = {
        p56[1] - p57,
        p56[2] - p57,
        p56[3] - p57,
        p56[4] - p57
    }
    local t10 = {
        p56[1] + p57,
        p56[2] + p57,
        p56[3] + p57,
        p56[4] + p57
    }
    local t11 = {}

    for _, v91 in BoardWorld.line_candidates(p55, vec3(p56), vec3(p56), p57) do
        local vertices = v91[2].triangle.vertices
        local t12 = {
            lanes(vertices[1]),
            lanes(vertices[2]),
            lanes(vertices[3])
        }

        if triangle_box(t12, t9, t10) then
            table.insert(t11, t12)

            if #t11 == 64 then
                break
            end
        end
    end

    if #t11 < 64 then
        for _, v92 in BoardWorld.external_nearby(p55, vec3(p56), p57) do
            local t13 = {
                lanes(v92[1]),
                lanes(v92[2]),
                lanes(v92[3])
            }

            if triangle_box(t13, t9, t10) then
                table.insert(t11, t13)

                if #t11 == 64 then
                    break
                end
            end
        end
    end

    return t11
end

function triangle_box(p58, p59, p60) -- line: 392
    -- upvalues: separated (ref), sub (ref), cross (ref)
    local t14 = {
        (p59[1] + p60[1]) * 0.5,
        (p59[2] + p60[2]) * 0.5,
        (p59[3] + p60[3]) * 0.5,
        (p59[4] + p60[4]) * 0.5
    }
    local t15 = {
        (p60[1] - p59[1]) * 0.5,
        (p60[2] - p59[2]) * 0.5,
        (p60[3] - p59[3]) * 0.5,
        (p60[4] - p59[4]) * 0.5
    }
    local t16 = {
        sub(p58[1], t14),
        sub(p58[2], t14),
        sub(p58[3], t14)
    }
    local t17 = {
        sub(t16[2], t16[1]),
        sub(t16[3], t16[2]),
        sub(t16[1], t16[3])
    }
    local t18 = {
        { 1, 0, 0, 0 },
        { 0, 1, 0, 0 },
        { 0, 0, 1, 0 }
    }

    for _, v93 in t17 do
        for _, v94 in t18 do
            if separated(t16, cross(v93, v94), t15) then
                return false
            end
        end
    end

    for _, v95 in t18 do
        if separated(t16, v95, t15) then
            return false
        end
    end

    return not separated(t16, cross(t17[1], t17[2]), t15)
end

t1.triangle_box = triangle_box

function separated(p61, p62, p63) -- line: 428
    -- upvalues: rt (copy), dot (ref)
    local t19 = {
        dot(p61[1], p62),
        dot(p61[2], p62),
        dot(p61[3], p62)
    }
    local v96 = rt.fmin(rt.fmin(t19[1], t19[2]), t19[3])
    local v97 = rt.fmax(rt.fmax(t19[1], t19[2]), t19[3])
    local v106 = p63[1] * math.abs(p62[1]) + p63[2] * math.abs(p62[2]) + p63[3] * math.abs(p62[3])

    if v106 < v96 then
        return true
    end

    return v97 < -v106
end

t1.separated = separated

function dot(p64, p65) -- line: 437
    return p64[1] * p65[1] + p64[2] * p65[2] + p64[3] * p65[3]
end

t1.dot = dot

function sub(p66, p67) -- line: 442
    return {
        p66[1] - p67[1],
        p66[2] - p67[2],
        p66[3] - p67[3],
        p66[4] - p67[4]
    }
end

t1.sub = sub

function cross(p68, p69) -- line: 447
    return {
        -p68[3] * p69[2] + p68[2] * p69[3],
        -p68[1] * p69[3] + p68[3] * p69[1],
        -p68[2] * p69[1] + p68[1] * p69[2],
        0
    }
end

t1.cross = cross

function vec3(p70) -- line: 457
    -- upvalues: Vector3 (copy)
    return Vector3.new(p70[1], p70[2], p70[3])
end

t1.vec3 = vec3

function lanes(p71) -- line: 462
    return {
        p71.x,
        p71.y,
        p71.z,
        0
    }
end

t1.lanes = lanes

return t1
