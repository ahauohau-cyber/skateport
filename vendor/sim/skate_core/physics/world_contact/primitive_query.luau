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

local function rtl_from_bits(p3) -- line: 24
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p3)

    return (buffer.readf32(v1, 0))
end

local function rtl_fround(p4) -- line: 28
    -- upvalues: v1 (copy)
    if p4 ~= 0 and p4 > -1.1754943508222875E-38 and p4 < 1.1754943508222875E-38 then
        local v9 = math.abs(p4) * 7.1362384635298E+44
        local v8 = math.floor(v9)
        local v10 = v9 - v8

        if v10 > 0.5 or v10 == 0.5 and v8 % 2 == 1 then
            v8 += 1
        end

        local v11 = v8 * 1.401298464324817E-45

        if p4 < 0 then
            return -v11
        end

        return v11
    end

    buffer.writef32(v1, 0, p4)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local v12 = import("skate_core/math")
local v13 = import("skate_core/physics/collision")
local v14 = import("skate_core/physics/world_contact/primitive_geometry")
local v15 = import("skate_core/physics/world_contact/triangle_box_sat")
local v16 = import("skate_core/physics/world_contact/projection")
local v17 = import("skate_core/physics/world_contact/box_feature")
local v18 = import("skate_core/physics/world_contact/feature")
local v19 = import("skate_core/physics/world_contact/dispatch")
local v20 = import("skate_core/physics/world_contact/triangle_feature")
local v21 = import("skate_core/physics/world_contact/prism_math")

import = v12.Vector3

local fix_up_triangle, world_separation_limit = v13.fix_up_triangle, v13.world_separation_limit
local best_separating_direction, best_separating_direction_into, project_direction = v16.best_separating_direction, v16.best_separating_direction_into, v16.project_direction
local box_maximum_feature = v17.box_maximum_feature
local capsule_maximum_feature = v18.capsule_maximum_feature
local find_feature_intersection_prism = v19.find_feature_intersection_prism
local triangle_maximum_feature = v20.triangle_maximum_feature
local load, dot, sub, scale = v21.load, v21.dot, v21.sub, v21.scale
local inverse_length = v21.inverse_length
local lanes, pack, xyz = v14.lanes, v14.pack, v14.xyz
local t1 = {}
local v22 = buffer.create(8)

local function fb(p5) -- line: 82
    -- upvalues: v22 (copy)
    buffer.writeu32(v22, 0, p5)

    return (buffer.readf32(v22, 0))
end

local to_bits = rt.to_bits

local function tb(p6) -- line: 87
    -- upvalues: v22 (copy), to_bits (copy)
    if p6 ~= 0 and p6 > -1.1754943508222875E-38 and p6 < 1.1754943508222875E-38 then
        return to_bits(p6)
    end

    buffer.writef32(v22, 0, p6)

    return (buffer.readu32(v22, 0))
end

t1.ContactPrimitive = v14.ContactPrimitive
t1.transform_triangle_volume = v14.transform_triangle_volume
t1.triangle_from_volume = v14.triangle_from_volume
t1.PrimitiveContactManifold = {}

local contact_points, contact_points_reference, contact_points_flat

function t1.primitive_triangle_world_contacts(p7, p8, p9, p10) -- line: 115
    -- upvalues: rt (copy), world_separation_limit (copy), pack (copy), t1 (copy)
    local v23 = world_separation_limit(rt.copy(p9), rt.copy(p8.feature.normal), p10.volume_padding, p10.maximum_separating_distance)
    local v24, v25 = pack(p7)
    local v26, v27 = pack({
        tag = "Triangle",
        p8
    })

    return t1.primitive_triangle_world_contacts_packed(v24, v25, v26, v27, p8, v23, p10)
end

t1.pack_primitive = pack
t1.pack_primitive_into = v14.pack_into

function t1.primitive_triangle_world_contacts_packed_reference(p11, p12, p13, p14, p15, p16, p17) -- line: 133
    -- upvalues: v1 (copy), v15 (copy), best_separating_direction (copy), contact_points_reference (ref)
    local v28, v29

    if p12 == "Box" then
        v28, v29 = v15.triangle_box(p13, p11)
        v29[1] = bit32.bxor(v29[1], 2147483648)
        v29[2] = bit32.bxor(v29[2], 2147483648)
        v29[3] = bit32.bxor(v29[3], 2147483648)
        v29[4] = bit32.bxor(v29[4], 2147483648)
    else
        v28, v29 = best_separating_direction(p11, p12, p13, p14)
    end

    local contact_points_reference2 = contact_points_reference

    buffer.writeu32(v1, 0, v28[1])

    return contact_points_reference2(p11, p12, p13, p14, p15, buffer.readf32(v1, 0), v29, p16, p17)
end

function t1.primitive_triangle_world_contacts_packed(p18, p19, p20, p21, p22, p23, p24) -- line: 149
    -- upvalues: v1 (copy), v15 (copy), best_separating_direction (copy), contact_points (ref)
    local v35, v36

    if p19 == "Box" then
        v35, v36 = v15.triangle_box(p20, p18)
        v36[1] = bit32.bxor(v36[1], 2147483648)
        v36[2] = bit32.bxor(v36[2], 2147483648)
        v36[3] = bit32.bxor(v36[3], 2147483648)
        v36[4] = bit32.bxor(v36[4], 2147483648)
    else
        v35, v36 = best_separating_direction(p18, p19, p20, p21)
    end

    local contact_points2 = contact_points

    buffer.writeu32(v1, 0, v35[1])

    return contact_points2(p18, p19, p20, p21, p22, buffer.readf32(v1, 0), v36, p23, p24)
end

local t2 = {
    0, 0, 0, 0
}
local v42 = table.create(96, 0)

t1.flat_points = v42

local face_axis_rejects, sphere_triangle_separation_into = v16.face_axis_rejects, v16.sphere_triangle_separation_into
local v43 = true

function t1.set_face_pretest(p25) -- line: 181
    -- upvalues: v43 (ref)
    local v44 = v43

    v43 = p25

    return v44
end

function t1.primitive_triangle_world_contacts_flat(p26, p27, p28, p29, p30, p31, p32, p33) -- line: 189
    -- upvalues: v15 (copy), best_separating_direction_into (copy), v22 (copy), contact_points_flat (ref), t2 (copy), face_axis_rejects (copy), sphere_triangle_separation_into (copy), v43 (ref)
    if v43 and not p33 and (p27 == "Triangle" or p27 == "Capsule") then
        buffer.writeu32(v22, 0, p28[33])

        local v46 = buffer.readf32(v22, 0) + p31

        buffer.writeu32(v22, 0, p26[33])

        if face_axis_rejects(p26, p27, p28, p29, v46 + buffer.readf32(v22, 0)) then
            return nil
        end
    end

    local v48

    if p27 == "Box" then
        buffer.writeu32(v22, 0, (v15.triangle_box_into(p28, p26, t2)))
        v48 = buffer.readf32(v22, 0)
        t2[1] = bit32.bxor(t2[1], 2147483648)
        t2[2] = bit32.bxor(t2[2], 2147483648)
        t2[3] = bit32.bxor(t2[3], 2147483648)
        t2[4] = bit32.bxor(t2[4], 2147483648)
    else
        local v54 = if v43 and p27 == "Sphere" and p29 == "Triangle" then sphere_triangle_separation_into(p26, p28, t2) else nil

        if v54 == nil then
            v54 = best_separating_direction_into(p26, p27, p28, p29, t2)
        end

        buffer.writeu32(v22, 0, v54)
        v48 = buffer.readf32(v22, 0)
    end

    return contact_points_flat(p26, p27, p28, p29, p30, v48, t2, p31, p32)
end

local v55 = table.create(144, 0)
local v56 = table.create(144, 0)
local v57 = table.create(144, 0)
local v58 = table.create(136, 0)
local maximum_into, maximum_into_reference

function contact_points_reference(p34, p35, p36, p37, p38, p39, p40, p41, p42) -- line: 252
    -- upvalues: rt (copy), v1 (copy), fix_up_triangle (copy), project_direction (copy), find_feature_intersection_prism (copy), load (copy), dot (copy), sub (copy), scale (copy), inverse_length (copy), lanes (copy), xyz (copy), v55 (copy), v56 (copy), v57 (copy), v58 (copy), maximum_into_reference (ref)
    buffer.writeu32(v1, 0, p34[33])

    local v60 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p36[33])

    local v62 = buffer.readf32(v1, 0)

    if v62 + p41 + v60 < p39 then
        return nil
    end

    table.move(v55, 1, 144, 1, v56)
    table.move(v55, 1, 144, 1, v57)
    table.move(v55, 1, 136, 1, v58)
    maximum_into_reference(v56, p34, p35, 1, p40)
    maximum_into_reference(v57, p36, p37, 0, {
        bit32.bxor(p40[1], 2147483648),
        bit32.bxor(p40[2], 2147483648),
        bit32.bxor(p40[3], 2147483648),
        (bit32.bxor(p40[4], 2147483648))
    })

    if find_feature_intersection_prism(v58, v56, v57, p40) == 0 then
        return nil
    end

    local v70 = v58[133]

    buffer.writeu32(v1, 0, p40[1])

    local v72 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p40[2])

    local v74 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p40[3])

    local v76 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p40[4])

    local t3 = {
        v72,
        v74,
        v76,
        (buffer.readf32(v1, 0))
    }

    if v70 == 1 then
        local v78 = sub(load(v58, 64), load(v58, 0))
        local v79 = dot(v78, v78)
        local v80

        if v79 == 0 then
            buffer.writef32(v1, 0, v79)
            v80 = buffer.readf32(v1, 0)
        elseif v79 > -1.1754943508222875E-38 and v79 < 1.1754943508222875E-38 then
            local v81 = math.abs(v79) * 7.1362384635298E+44
            local v82 = math.floor(v81)
            local v83 = v81 - v82

            if v83 > 0.5 or v83 == 0.5 and v82 % 2 == 1 then
                v82 += 1
            end

            v80 = v82 * 1.401298464324817E-45

            if v79 < 0 then
                v80 = -v80
            end
        else
            buffer.writef32(v1, 0, v79)
            v80 = buffer.readf32(v1, 0)
        end

        local v84 = inverse_length(v80)

        if (if v80 == 0 then 0 else v80 * v84) > 1.1920928955078125E-07 then
            local v85 = scale(v78, v84)
            local v86 = v85[1]
            local v87

            if v86 == 0 then
                buffer.writef32(v1, 0, v86)
                v87 = buffer.readu32(v1, 0)
            elseif v86 > -1.1754943508222875E-38 and v86 < 1.1754943508222875E-38 then
                local v88 = math.abs(v86) * 7.1362384635298E+44

                v87 = math.floor(v88)

                local v89 = v88 - v87

                if v89 > 0.5 or v89 == 0.5 and v87 % 2 == 1 then
                    v87 += 1
                end

                if v86 < 0 then
                    v87 += 2147483648
                end
            else
                buffer.writef32(v1, 0, v86)
                v87 = buffer.readu32(v1, 0)
            end

            v58[129] = v87

            local v90 = v85[2]
            local v91

            if v90 ~= 0 and v90 > -1.1754943508222875E-38 and v90 < 1.1754943508222875E-38 then
                local v92 = math.abs(v90) * 7.1362384635298E+44
                local v93 = math.floor(v92)
                local v94 = v92 - v93

                v91 = if v94 > 0.5 or v94 == 0.5 and v93 % 2 == 1 then v93 + 1 else v93

                if v90 < 0 then
                    v91 += 2147483648
                end
            else
                buffer.writef32(v1, 0, v90)
                v91 = buffer.readu32(v1, 0)
            end

            v58[130] = v91

            local v95 = v85[3]
            local v96

            if v95 ~= 0 and v95 > -1.1754943508222875E-38 and v95 < 1.1754943508222875E-38 then
                local v97 = math.abs(v95) * 7.1362384635298E+44
                local v98 = math.floor(v97)
                local v99 = v97 - v98

                v96 = if v99 > 0.5 or v99 == 0.5 and v98 % 2 == 1 then v98 + 1 else v98

                if v95 < 0 then
                    v96 += 2147483648
                end
            else
                buffer.writef32(v1, 0, v95)
                v96 = buffer.readu32(v1, 0)
            end

            v58[131] = v96

            local v100 = v85[4]
            local v101

            if v100 ~= 0 and v100 > -1.1754943508222875E-38 and v100 < 1.1754943508222875E-38 then
                local v102 = math.abs(v100) * 7.1362384635298E+44
                local v103 = math.floor(v102)
                local v104 = v102 - v103

                v101 = if v104 > 0.5 or v104 == 0.5 and v103 % 2 == 1 then v103 + 1 else v103

                if v100 < 0 then
                    v101 += 2147483648
                end
            else
                buffer.writef32(v1, 0, v100)
                v101 = buffer.readu32(v1, 0)
            end

            v58[132] = v101
            v58[134] = 1
        end
    end

    if v58[134] ~= 0 then
        local v105 = rt.slice(v58, 128, 132)
        local v106 = table.create(12, 0)
        local v107 = table.create(12, 0)

        project_direction(p34, p35, v105, v106)
        project_direction(p36, p37, v105, v107)
        buffer.writeu32(v1, 0, v106[1])

        local v109 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v107[5])

        local v111 = v109 - buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v107[1])

        local v113 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v106[5])

        local v115 = v113 - buffer.readf32(v1, 0)
        local v116 = v115 < v111

        if not v116 then
            v111 = v115
        end

        if p39 <= v111 then
            for i = 1, 4 do
                buffer.writeu32(v1, 0, if v116 then bit32.bxor(v105[i], 2147483648) else v105[i])
                t3[i] = buffer.readf32(v1, 0)
            end
        end
    end

    local v119 = table.create(16)

    for i = 1, 16 do
        v119[i] = {
            a = {
                x = 0,
                y = 0,
                z = 0
            },
            b = {
                x = 0,
                y = 0,
                z = 0
            }
        }
    end

    for i = 0, v70 - 1 do
        local v120 = v119[i + 1]

        v120.a = xyz(load(v58, i * 4))
        v120.b = xyz(load(v58, i * 4 + 64))
    end

    local v121 = xyz(t3)
    local v122 = table.create(v70)

    for i = 1, v70 do
        v122[i] = v119[i]
    end

    local v123 = fix_up_triangle(rt.copy(p38.feature), v121, v122, {
        reverse = true,
        edge_cos_bend_normal_threshold = p42.edge_cos_bend_normal_threshold,
        convexity_epsilon = p42.convexity_epsilon,
        is_object = p42.is_object
    })

    for i = 1, v70 do
        v119[i] = v122[i]
    end

    if not v123 then
        return nil
    end

    local v124 = lanes(v121, 0)
    local v125 = scale(v124, v60)
    local v126 = scale(v124, v62)

    for i = 1, v70 do
        local v127 = v119[i]
        local v128 = lanes(v127.a, 1)

        v127.a = xyz({
            v128[1] + v125[1],
            v128[2] + v125[2],
            v128[3] + v125[3],
            v128[4] + v125[4]
        })
        v127.b = xyz(sub(lanes(v127.b, 1), v126))
    end

    return {
        normal = xyz({
            -v124[1],
            -v124[2],
            -v124[3],
            -v124[4]
        }),
        points = v119,
        count = v70
    }
end

t1.contact_points_reference = contact_points_reference

local t4 = {
    0, 0, 0, 0
}
local t5 = {
    0, 0, 0, 0
}
local v129 = table.create(12, 0)
local v130 = table.create(12, 0)
local v131 = table.create(16)
local v132 = table.create(16)
local v133 = table.create(16)
local v134 = table.create(17)

for i = 1, 16 do
    v131[i] = {
        x = 0,
        y = 0,
        z = 0
    }
    v132[i] = {
        x = 0,
        y = 0,
        z = 0
    }
    v133[i] = {
        a = v131[i],
        b = v132[i]
    }
end

for i = 0, 16 do
    local v135 = table.create(i)

    for j = 1, i do
        v135[j] = v133[j]
    end

    v134[i + 1] = v135
end

local t6 = {
    x = 0,
    y = 0,
    z = 0
}
local t7 = {
    reverse = true,
    edge_cos_bend_normal_threshold = 0,
    convexity_epsilon = 0,
    is_object = false
}

function contact_points_flat(p43, p44, p45, p46, p47, p48, p49, p50, p51) -- line: 426
    -- upvalues: v1 (copy), fix_up_triangle (copy), project_direction (copy), find_feature_intersection_prism (copy), inverse_length (copy), v22 (copy), to_bits (copy), v42 (copy), v55 (copy), v56 (copy), v57 (copy), v58 (copy), maximum_into (ref), t4 (copy), t5 (copy), v129 (copy), v130 (copy), v131 (copy), v132 (copy), v133 (copy), v134 (copy), t6 (copy), t7 (copy)
    buffer.writeu32(v22, 0, p43[33])

    local v137 = buffer.readf32(v22, 0)

    buffer.writeu32(v22, 0, p45[33])

    local v139 = buffer.readf32(v22, 0)

    if v139 + p50 + v137 < p48 then
        return nil
    end

    table.move(v55, 1, 144, 1, v56)
    table.move(v55, 1, 144, 1, v57)
    table.move(v55, 1, 136, 1, v58)
    maximum_into(v56, p43, p44, 1, p49)
    t4[1] = bit32.bxor(p49[1], 2147483648)
    t4[2] = bit32.bxor(p49[2], 2147483648)
    t4[3] = bit32.bxor(p49[3], 2147483648)
    t4[4] = bit32.bxor(p49[4], 2147483648)
    maximum_into(v57, p45, p46, 0, t4)

    if find_feature_intersection_prism(v58, v56, v57, p49) == 0 then
        return nil
    end

    local v141 = v58[133]

    if v141 > 16 then
        error("attempt to index nil with 'a'", 0)
    end

    buffer.writeu32(v22, 0, p49[1])

    local v143 = buffer.readf32(v22, 0)

    buffer.writeu32(v22, 0, p49[2])

    local v144 = buffer.readf32(v22, 0)

    buffer.writeu32(v22, 0, p49[3])

    local v145 = buffer.readf32(v22, 0)
    local v146, v147, v148, v149, v150, v151, v152

    if v141 == 1 then
        v147 = v58[65]
        buffer.writeu32(v22, 0, v147)

        local v153 = buffer.readf32(v22, 0)

        buffer.writeu32(v22, 0, v58[1])

        local v155 = v153 - buffer.readf32(v22, 0)

        v147 = v58[66]
        buffer.writeu32(v22, 0, v147)
        v153 = buffer.readf32(v22, 0)
        buffer.writeu32(v22, 0, v58[2])

        local v156 = v153 - buffer.readf32(v22, 0)

        buffer.writeu32(v22, 0, v58[67])

        local v157 = buffer.readf32(v22, 0)

        buffer.writeu32(v22, 0, v58[3])

        local v159 = v157 - buffer.readf32(v22, 0)

        buffer.writeu32(v22, 0, v58[68])

        local v160 = buffer.readf32(v22, 0)

        buffer.writeu32(v22, 0, v58[4])
        v147 = v160 - buffer.readf32(v22, 0)
        v157 = v155 * v155 + v156 * v156 + v159 * v159

        if v157 == 0 then
            buffer.writef32(v1, 0, v157)
            v160 = buffer.readf32(v1, 0)
        elseif v157 > -1.1754943508222875E-38 and v157 < 1.1754943508222875E-38 then
            v148 = math.abs(v157) * 7.1362384635298E+44
            v149 = math.floor(v148)
            v150 = v148 - v149

            if v150 > 0.5 or v150 == 0.5 and v149 % 2 == 1 then
                v149 += 1
            end

            v160 = v149 * 1.401298464324817E-45

            if v157 < 0 then
                v160 = -v160
            end
        else
            buffer.writef32(v1, 0, v157)
            v160 = buffer.readf32(v1, 0)
        end

        v157 = inverse_length(v160)

        if v160 == 0 then
            v160 = 0
        else
            v160 *= v157
        end

        buffer.writeu32(v22, 0, 872415232)

        if buffer.readf32(v22, 0) < v160 then
            v146 = v155 * v157

            if v146 == 0 then
                buffer.writef32(v22, 0, v146)
                v151 = buffer.readu32(v22, 0)
            elseif v146 > -1.1754943508222875E-38 and v146 < 1.1754943508222875E-38 then
                v151 = to_bits(v146)
            else
                buffer.writef32(v22, 0, v146)
                v151 = buffer.readu32(v22, 0)
            end

            v58[129] = v151
            v146 = v156 * v157

            if v146 ~= 0 and v146 > -1.1754943508222875E-38 and v146 < 1.1754943508222875E-38 then
                v152 = to_bits(v146)
            else
                buffer.writef32(v22, 0, v146)
                v152 = buffer.readu32(v22, 0)
            end

            v58[130] = v152
            v146 = v159 * v157

            if v146 ~= 0 and v146 > -1.1754943508222875E-38 and v146 < 1.1754943508222875E-38 then
                v152 = to_bits(v146)
            else
                buffer.writef32(v22, 0, v146)
                v152 = buffer.readu32(v22, 0)
            end

            v58[131] = v152
            v146 = v147 * v157

            if v146 ~= 0 and v146 > -1.1754943508222875E-38 and v146 < 1.1754943508222875E-38 then
                v152 = to_bits(v146)
            else
                buffer.writef32(v22, 0, v146)
                v152 = buffer.readu32(v22, 0)
            end

            v58[132] = v152
            v58[134] = 1
        end
    end

    local v162, v163, v164
    local v165 = v143
    local v166 = v144
    local v167 = v145

    if v58[134] ~= 0 then
        v147 = v58[129]
        v164 = v58[130]
        v162 = v58[131]
        v163 = v58[132]
        t5[1] = v147
        t5[2] = v164
        t5[3] = v162
        t5[4] = v163
        project_direction(p43, p44, t5, v129)
        project_direction(p45, p46, t5, v130)
        v152 = v129[1]
        buffer.writeu32(v22, 0, v152)
        v146 = buffer.readf32(v22, 0)
        buffer.writeu32(v22, 0, v130[5])
        v162 = v146 - buffer.readf32(v22, 0)
        v146 = v130[1]
        buffer.writeu32(v22, 0, v146)
        v151 = buffer.readf32(v22, 0)
        v148 = v129[5]
        buffer.writeu32(v22, 0, v148)
        v163 = v151 - buffer.readf32(v22, 0)
        v164 = v163 < v162

        if not v164 then
            v162 = v163
        end

        if p48 <= v162 then
            if v164 then
                v165 = t5[1]
                v152 = bit32.bxor(v165, 2147483648)
                buffer.writeu32(v22, 0, v152)
                v165 = buffer.readf32(v22, 0)
                v166 = t5[2]
                v152 = bit32.bxor(v166, 2147483648)
                buffer.writeu32(v22, 0, v152)
                v166 = buffer.readf32(v22, 0)
                v146 = t5[3]
                v152 = bit32.bxor(v146, 2147483648)
            else
                v152 = t5[1]
                buffer.writeu32(v22, 0, v152)
                v165 = buffer.readf32(v22, 0)
                v152 = t5[2]
                buffer.writeu32(v22, 0, v152)
                v166 = buffer.readf32(v22, 0)
                v152 = t5[3]
            end

            buffer.writeu32(v22, 0, v152)
            v167 = buffer.readf32(v22, 0)
        end
    end

    local v170

    for i = 0, v141 - 1 do
        v162 = v133[i + 1]
        v163 = v131[i + 1]
        v152 = v132[i + 1]
        v151 = v58[i * 4 + 1]
        buffer.writeu32(v22, 0, v151)
        v149 = buffer.readf32(v22, 0)
        v150 = v58[i * 4 + 2]
        buffer.writeu32(v22, 0, v150)
        v170 = buffer.readf32(v22, 0)
        buffer.writeu32(v22, 0, v58[i * 4 + 3])

        local v172 = buffer.readf32(v22, 0)

        v163.x = v149
        v163.y = v170
        v163.z = v172
        v151 = v58[i * 4 + 64 + 1]
        buffer.writeu32(v22, 0, v151)
        v149 = buffer.readf32(v22, 0)
        v150 = v58[i * 4 + 64 + 2]
        buffer.writeu32(v22, 0, v150)
        v170 = buffer.readf32(v22, 0)
        buffer.writeu32(v22, 0, v58[i * 4 + 64 + 3])
        v172 = buffer.readf32(v22, 0)
        v152.x = v149
        v152.y = v170
        v152.z = v172
        v162.a = v163
        v162.b = v152
    end

    t6.x = v165
    t6.y = v166
    t6.z = v167
    t7.edge_cos_bend_normal_threshold = p51.edge_cos_bend_normal_threshold
    t7.convexity_epsilon = p51.convexity_epsilon
    t7.is_object = p51.is_object

    if not fix_up_triangle(p47.feature, t6, v134[v141 + 1], t7) then
        return nil
    end

    local v169 = t6.x

    v143 = t6.y
    v164 = t6.z
    v162 = v169 * v137
    v163 = v143 * v137
    v152 = v164 * v137
    v165 = v169 * v139
    v151 = v143 * v139
    v149 = v164 * v139

    for i = 0, v141 - 1 do
        v167 = v133[i + 1]

        local a, b = v167.a, v167.b

        v167 = i * 6
        v42[v167 + 1] = a.x + v162
        v42[v167 + 2] = a.y + v163
        v42[v167 + 3] = a.z + v152
        v42[v167 + 4] = b.x - v165
        v42[v167 + 5] = b.y - v151
        v42[v167 + 6] = b.z - v149
    end

    return v141, -v169, -v143, -v164
end

function t1.fr(p52) -- line: 545
    -- upvalues: v22 (copy), to_bits (copy)
    if p52 < 1.1754943508222875E-38 and p52 > -1.1754943508222875E-38 and p52 ~= 0 then
        buffer.writeu32(v22, 0, to_bits(p52))
    else
        buffer.writef32(v22, 0, p52)
    end

    return (buffer.readf32(v22, 0))
end

function t1.triangle_floats(p53, p54) -- line: 568
    -- upvalues: v22 (copy), to_bits (copy)
    local normal = p54.feature.normal

    buffer.writeu32(v22, 0, p53[5])

    local v174 = buffer.readf32(v22, 0)

    buffer.writeu32(v22, 0, p53[6])

    local v176 = buffer.readf32(v22, 0)

    buffer.writeu32(v22, 0, p53[7])

    local v178 = buffer.readf32(v22, 0)

    buffer.writeu32(v22, 0, p53[1])

    local v180 = buffer.readf32(v22, 0)

    buffer.writeu32(v22, 0, p53[2])

    local v182 = buffer.readf32(v22, 0)

    buffer.writeu32(v22, 0, p53[3])

    local v184 = buffer.readf32(v22, 0)

    buffer.writeu32(v22, 0, p53[9])

    local v186 = buffer.readf32(v22, 0)

    buffer.writeu32(v22, 0, p53[10])

    local v188 = buffer.readf32(v22, 0)

    buffer.writeu32(v22, 0, p53[11])

    local v190 = buffer.readf32(v22, 0)

    buffer.writeu32(v22, 0, p53[13])

    local v192 = buffer.readf32(v22, 0)

    buffer.writeu32(v22, 0, p53[14])

    local v194 = buffer.readf32(v22, 0)

    buffer.writeu32(v22, 0, p53[15])

    local v196 = buffer.readf32(v22, 0)
    local v197 = v180 * v174 + v182 * v176 + v184 * v178
    local v198 = v186 * v174 + v188 * v176 + v190 * v178
    local v199 = v192 * v174 + v194 * v176 + v196 * v178
    local v200 = if v197 < v198 then v197 else v198
    local v201 = if v198 < v197 then v197 else v198

    if not (v200 < v199) then
        v200 = v199
    end

    if v200 < 1.1754943508222875E-38 and v200 > -1.1754943508222875E-38 and v200 ~= 0 then
        buffer.writeu32(v22, 0, to_bits(v200))
    else
        buffer.writef32(v22, 0, v200)
    end

    local v202 = buffer.readf32(v22, 0)

    if not (v199 < v201) then
        v201 = v199
    end

    if v201 < 1.1754943508222875E-38 and v201 > -1.1754943508222875E-38 and v201 ~= 0 then
        buffer.writeu32(v22, 0, to_bits(v201))
    else
        buffer.writef32(v22, 0, v201)
    end

    local v203 = buffer.readf32(v22, 0)
    local v204 = if v198 < v199 then v198 else v199

    if v197 < v204 then
        v204 = v197
    end

    if not (v199 < v198) then
        v198 = v199
    end

    if not (v198 < v197) then
        v197 = v198
    end

    buffer.writeu32(v22, 0, p53[17])

    local v206 = buffer.readf32(v22, 0)

    buffer.writeu32(v22, 0, p53[18])

    local v208 = buffer.readf32(v22, 0)

    buffer.writeu32(v22, 0, p53[19])

    local v210 = buffer.readf32(v22, 0)

    buffer.writeu32(v22, 0, p53[21])

    local v212 = buffer.readf32(v22, 0)

    buffer.writeu32(v22, 0, p53[22])

    local v214 = buffer.readf32(v22, 0)

    buffer.writeu32(v22, 0, p53[23])

    local v216 = buffer.readf32(v22, 0)

    buffer.writeu32(v22, 0, p53[25])

    local v218 = buffer.readf32(v22, 0)

    buffer.writeu32(v22, 0, p53[26])

    local v220 = buffer.readf32(v22, 0)

    buffer.writeu32(v22, 0, p53[27])

    local v222 = buffer.readf32(v22, 0)

    buffer.writeu32(v22, 0, p53[33])

    local v224 = buffer.readf32(v22, 0)
    local v225 = 0

    if p53[36] == 16973824 and p53[8] == 0 and p53[20] == 0 and p53[24] == 0 and p53[28] == 0 then
        local v226 = v174 + v176 + v178 + v180 + v182 + v184 + v186 + v188 + v190 + v192 + v194 + v196 + v206 + v208 + v210 + v212 + v214 + v216 + v218 + v220 + v222 + v224 + v202 + v203 + v204 + v197

        v225 = if v226 - v226 == 0 then 1 else 0
    end

    local feature = p54.feature
    local edges = feature.edges
    local v227 = edges[1]
    local v228 = edges[2]
    local v229 = edges[3]
    local edge_cosines = feature.edge_cosines

    return {
        -normal.x,
        -normal.y,
        -normal.z,
        v174,
        v176,
        v178,
        v180,
        v182,
        v184,
        v186,
        v188,
        v190,
        v192,
        v194,
        v196,
        v224,
        v202,
        v203,
        if p53[36] == 16973824 then 1 else 0,
        v204,
        v197,
        false,
        false,
        v206,
        v208,
        v210,
        v212,
        v214,
        v216,
        v218,
        v220,
        v222,
        v225,
        normal.x,
        normal.y,
        normal.z,
        v227.x,
        v227.y,
        v227.z,
        v228.x,
        v228.y,
        v228.z,
        v229.x,
        v229.y,
        v229.z,
        edge_cosines[1],
        edge_cosines[2],
        edge_cosines[3],
        feature.flags
    }
end

local function face_memo(p55, p56) -- line: 647
    -- upvalues: triangle_maximum_feature (copy), v22 (copy)
    local t9 = if p56 then {
        p55[5],
        p55[6],
        p55[7],
        p55[8]
    } else {
        bit32.bxor(p55[5], 2147483648),
        bit32.bxor(p55[6], 2147483648),
        bit32.bxor(p55[7], 2147483648),
        (bit32.bxor(p55[8], 2147483648))
    }
    local v241 = table.create(144, 0)

    triangle_maximum_feature(p55, 0, t9, v241)

    local v242 = v241[141]
    local v243 = table.create(32, 0)

    v243[32] = nil
    v243[31] = v242

    if v242 == 0 then
        buffer.writeu32(v22, 0, v241[137])

        local v245 = buffer.readf32(v22, 0)

        buffer.writeu32(v22, 0, v241[138])

        local v247 = buffer.readf32(v22, 0)

        buffer.writeu32(v22, 0, v241[139])

        local v249 = buffer.readf32(v22, 0)

        v243[1] = v245
        v243[2] = v247
        v243[3] = v249
    else
        if v242 ~= 3 and v242 ~= 1 then
            return 0
        end

        for i = 0, v242 - 1 do
            local v250 = i * 16 + 4
            local v251 = v241[v250 + 13]

            if v241[v250 + 14] ~= v251 or v241[v250 + 15] ~= v251 or v241[v250 + 16] ~= v251 then
                return 0
            end

            local v252 = i * 10
            local v253 = v252 + 1
            local v254 = v252 + 2
            local v255 = v252 + 3

            buffer.writeu32(v22, 0, v241[v250 + 1])

            local v257 = buffer.readf32(v22, 0)

            buffer.writeu32(v22, 0, v241[v250 + 2])

            local v259 = buffer.readf32(v22, 0)

            buffer.writeu32(v22, 0, v241[v250 + 3])

            local v261 = buffer.readf32(v22, 0)

            v243[v253] = v257
            v243[v254] = v259
            v243[v255] = v261

            local v262 = v252 + 4
            local v263 = v252 + 5
            local v264 = v252 + 6

            buffer.writeu32(v22, 0, v241[v250 + 5])

            local v266 = buffer.readf32(v22, 0)

            buffer.writeu32(v22, 0, v241[v250 + 6])

            local v268 = buffer.readf32(v22, 0)

            buffer.writeu32(v22, 0, v241[v250 + 7])

            local v270 = buffer.readf32(v22, 0)

            v243[v262] = v266
            v243[v263] = v268
            v243[v264] = v270

            local v271 = v252 + 7
            local v272 = v252 + 8
            local v273 = v252 + 9

            buffer.writeu32(v22, 0, v241[v250 + 9])

            local v275 = buffer.readf32(v22, 0)

            buffer.writeu32(v22, 0, v241[v250 + 10])

            local v277 = buffer.readf32(v22, 0)

            buffer.writeu32(v22, 0, v241[v250 + 11])

            local v279 = buffer.readf32(v22, 0)

            v243[v271] = v275
            v243[v272] = v277
            v243[v273] = v279

            local v280 = v252 + 10

            buffer.writeu32(v22, 0, v251)
            v243[v280] = buffer.readf32(v22, 0)
        end
    end

    return v243
end

t1.face_memo = face_memo
buffer.writeu32(v22, 0, 872415232)

local v281 = buffer.readf32(v22, 0)
local fround = rt.fround

function t1.sphere_triangle_contacts_flat(p57, p58, p59, p60, p61, p62, p63, p64, p65, p66) -- line: 713
    -- upvalues: fix_up_triangle (copy), inverse_length (copy), v22 (copy), to_bits (copy), v42 (copy), v131 (copy), v132 (copy), v133 (copy), v134 (copy), t6 (copy), t7 (copy), face_memo (copy), v281 (copy), fround (copy)
    local v282 = if p59 then 22 else 23
    local v283 = p57[v282]

    if v283 == false then
        v283 = face_memo(p58, p59)
        p57[v282] = v283
    end

    if v283 == 0 then
        return -1
    end

    local v284 = p57[4]
    local v285 = p57[5]
    local v286 = p57[6]

    if p59 then
        v284 = -v284
        v285 = -v285
        v286 = -v286
    end

    v282 = v283[31]

    local v287, v288, v289, v290, v291, v292, v293, v294, v295, v296, v297, v298, v299, v300

    if v282 == 3 then
        v300 = v284 * (v283[1] - p61) + v285 * (v283[2] - p62) + v286 * (v283[3] - p63)
        v287 = v284 * v300 + p61
        v288 = v285 * v300 + p62
        v289 = v286 * v300 + p63
        v295 = v283[7] * (v287 - v283[1]) + v283[8] * (v288 - v283[2]) + v283[9] * (v289 - v283[3])

        local v301 = v283[17] * (v287 - v283[11]) + v283[18] * (v288 - v283[12]) + v283[19] * (v289 - v283[13])

        if v295 < v301 then
            v300 = 10
        else
            v301 = v295
            v300 = 0
        end

        v296 = v283[27] * (v287 - v283[21]) + v283[28] * (v288 - v283[22]) + v283[29] * (v289 - v283[23])

        if v301 < v296 then
            v300 = 20
        else
            v296 = v301
        end

        if v296 > 0 then
            v297 = v287 - v283[v300 + 7] * v296

            if not (v297 < 1.1754943508222875E-38) or not (v297 > -1.1754943508222875E-38) or v297 == 0 then
                buffer.writef32(v22, 0, v297)
            else
                buffer.writeu32(v22, 0, to_bits(v297))
            end

            v298 = buffer.readf32(v22, 0)
            v299 = v288 - v283[v300 + 8] * v296

            if v299 < 1.1754943508222875E-38 and v299 > -1.1754943508222875E-38 and v299 ~= 0 then
                buffer.writeu32(v22, 0, to_bits(v299))
            else
                buffer.writef32(v22, 0, v299)
            end

            v290 = buffer.readf32(v22, 0)
            v291 = v289 - v283[v300 + 9] * v296

            if v291 < 1.1754943508222875E-38 and v291 > -1.1754943508222875E-38 and v291 ~= 0 then
                buffer.writeu32(v22, 0, to_bits(v291))
            else
                buffer.writef32(v22, 0, v291)
            end

            local v302 = buffer.readf32(v22, 0)

            v291 = v283[v300 + 1]
            v292 = v283[v300 + 2]
            v293 = v283[v300 + 3]

            local v303 = v283[v300 + 4]

            v294 = v283[v300 + 5]

            local v304 = v283[v300 + 6]
            local v305 = (v298 - v291) * v303 + (v290 - v292) * v294 + (v302 - v293) * v304

            if not (v305 < 0) then
                v298 = v283[v300 + 10]

                local v306

                if v298 < v305 then
                    v306 = v303 * v298 + v291

                    if not (v306 < 1.1754943508222875E-38) or not (v306 > -1.1754943508222875E-38) or v306 == 0 then
                        buffer.writef32(v22, 0, v306)
                    else
                        buffer.writeu32(v22, 0, to_bits(v306))
                    end

                    v291 = buffer.readf32(v22, 0)
                    v306 = v294 * v298 + v292

                    if v306 < 1.1754943508222875E-38 and v306 > -1.1754943508222875E-38 and v306 ~= 0 then
                        buffer.writeu32(v22, 0, to_bits(v306))
                    else
                        buffer.writef32(v22, 0, v306)
                    end

                    v292 = buffer.readf32(v22, 0)
                    v306 = v304 * v298 + v293
                else
                    v306 = v303 * v305 + v291

                    if v306 < 1.1754943508222875E-38 and v306 > -1.1754943508222875E-38 and v306 ~= 0 then
                        buffer.writeu32(v22, 0, to_bits(v306))
                    else
                        buffer.writef32(v22, 0, v306)
                    end

                    v291 = buffer.readf32(v22, 0)
                    v306 = v294 * v305 + v292

                    if v306 < 1.1754943508222875E-38 and v306 > -1.1754943508222875E-38 and v306 ~= 0 then
                        buffer.writeu32(v22, 0, to_bits(v306))
                    else
                        buffer.writef32(v22, 0, v306)
                    end

                    v292 = buffer.readf32(v22, 0)
                    v306 = v304 * v305 + v293
                end

                if v306 < 1.1754943508222875E-38 and v306 > -1.1754943508222875E-38 and v306 ~= 0 then
                    buffer.writeu32(v22, 0, to_bits(v306))
                else
                    buffer.writef32(v22, 0, v306)
                end

                v293 = buffer.readf32(v22, 0)
            end
        else
            if v287 < 1.1754943508222875E-38 and v287 > -1.1754943508222875E-38 and v287 ~= 0 then
                buffer.writeu32(v22, 0, to_bits(v287))
            else
                buffer.writef32(v22, 0, v287)
            end

            v291 = buffer.readf32(v22, 0)

            if v288 < 1.1754943508222875E-38 and v288 > -1.1754943508222875E-38 and v288 ~= 0 then
                buffer.writeu32(v22, 0, to_bits(v288))
            else
                buffer.writef32(v22, 0, v288)
            end

            v292 = buffer.readf32(v22, 0)

            if v289 < 1.1754943508222875E-38 and v289 > -1.1754943508222875E-38 and v289 ~= 0 then
                buffer.writeu32(v22, 0, to_bits(v289))
            else
                buffer.writef32(v22, 0, v289)
            end

            v293 = buffer.readf32(v22, 0)
        end
    elseif v282 == 1 then
        v291 = v283[1]
        v292 = v283[2]
        v293 = v283[3]
        v289 = v283[4]
        v295 = v283[5]
        v296 = v283[6]

        local v307 = (p61 - v291) * v289 + (p62 - v292) * v295 + (p63 - v293) * v296

        if not (v307 < 0) then
            v297 = v283[10]

            if v297 < v307 then
                v298 = v289 * v297 + v291

                if not (v298 < 1.1754943508222875E-38) or not (v298 > -1.1754943508222875E-38) or v298 == 0 then
                    buffer.writef32(v22, 0, v298)
                else
                    buffer.writeu32(v22, 0, to_bits(v298))
                end

                v291 = buffer.readf32(v22, 0)
                v298 = v295 * v297 + v292

                if v298 < 1.1754943508222875E-38 and v298 > -1.1754943508222875E-38 and v298 ~= 0 then
                    buffer.writeu32(v22, 0, to_bits(v298))
                else
                    buffer.writef32(v22, 0, v298)
                end

                v292 = buffer.readf32(v22, 0)
                v298 = v296 * v297 + v293
            else
                v298 = v289 * v307 + v291

                if v298 < 1.1754943508222875E-38 and v298 > -1.1754943508222875E-38 and v298 ~= 0 then
                    buffer.writeu32(v22, 0, to_bits(v298))
                else
                    buffer.writef32(v22, 0, v298)
                end

                v291 = buffer.readf32(v22, 0)
                v298 = v295 * v307 + v292

                if v298 < 1.1754943508222875E-38 and v298 > -1.1754943508222875E-38 and v298 ~= 0 then
                    buffer.writeu32(v22, 0, to_bits(v298))
                else
                    buffer.writef32(v22, 0, v298)
                end

                v292 = buffer.readf32(v22, 0)
                v298 = v296 * v307 + v293
            end

            if v298 < 1.1754943508222875E-38 and v298 > -1.1754943508222875E-38 and v298 ~= 0 then
                buffer.writeu32(v22, 0, to_bits(v298))
            else
                buffer.writef32(v22, 0, v298)
            end

            v293 = buffer.readf32(v22, 0)
        end
    else
        v291 = v283[1]
        v292 = v283[2]
        v293 = v283[3]
    end

    v283 = v291 - p61
    v282 = v292 - p62
    v300 = v293 - p63
    v287 = fround(v283 * v283 + v282 * v282 + v300 * v300)
    v288 = inverse_length(v287)
    v289 = if v287 == 0 then 0 else v287 * v288

    if v281 < v289 then
        v297 = v283 * v288

        if v297 < 1.1754943508222875E-38 and v297 > -1.1754943508222875E-38 and v297 ~= 0 then
            buffer.writeu32(v22, 0, to_bits(v297))
        else
            buffer.writef32(v22, 0, v297)
        end

        v298 = buffer.readf32(v22, 0)
        v297 = v282 * v288

        if v297 < 1.1754943508222875E-38 and v297 > -1.1754943508222875E-38 and v297 ~= 0 then
            buffer.writeu32(v22, 0, to_bits(v297))
        else
            buffer.writef32(v22, 0, v297)
        end

        v299 = buffer.readf32(v22, 0)
        v297 = v300 * v288

        if v297 < 1.1754943508222875E-38 and v297 > -1.1754943508222875E-38 and v297 ~= 0 then
            buffer.writeu32(v22, 0, to_bits(v297))
        else
            buffer.writef32(v22, 0, v297)
        end

        local v308 = buffer.readf32(v22, 0)

        v287 = p61 * v298 + p62 * v299 + p63 * v308

        if v287 < 1.1754943508222875E-38 and v287 > -1.1754943508222875E-38 and v287 ~= 0 then
            buffer.writeu32(v22, 0, to_bits(v287))
        else
            buffer.writef32(v22, 0, v287)
        end

        v297 = buffer.readf32(v22, 0)
        v287 = p57[7] * v298 + p57[8] * v299 + p57[9] * v308

        local v309 = p57[10] * v298 + p57[11] * v299 + p57[12] * v308

        v290 = p57[13] * v298 + p57[14] * v299 + p57[15] * v308
        v294 = if v287 < v309 then v287 else v309

        if not (v309 < v287) then
            v287 = v309
        end

        if not (v290 < v287) then
            v287 = v290
        end

        if v287 < 1.1754943508222875E-38 and v287 > -1.1754943508222875E-38 and v287 ~= 0 then
            buffer.writeu32(v22, 0, to_bits(v287))
        else
            buffer.writef32(v22, 0, v287)
        end

        v309 = v297 - buffer.readf32(v22, 0)

        if not (v294 < v290) then
            v294 = v290
        end

        if v294 < 1.1754943508222875E-38 and v294 > -1.1754943508222875E-38 and v294 ~= 0 then
            buffer.writeu32(v22, 0, to_bits(v294))
        else
            buffer.writef32(v22, 0, v294)
        end

        local v310 = buffer.readf32(v22, 0) - v297

        if v310 < v309 then
            if p60 <= v309 then
                v284 = -v298
                v285 = -v299
                v286 = -v308
            end
        elseif p60 <= v310 then
            v286 = v308
            v284 = v298
            v285 = v299
        end
    end

    v300 = v133[1]
    v287 = v131[1]
    v288 = v132[1]
    v287.x = p61
    v287.y = p62
    v287.z = p63
    v288.x = v291
    v288.y = v292
    v288.z = v293
    v300.a = v287
    v300.b = v288
    t6.x = v284
    t6.y = v285
    t6.z = v286
    t7.edge_cos_bend_normal_threshold = p66.edge_cos_bend_normal_threshold
    t7.convexity_epsilon = p66.convexity_epsilon
    t7.is_object = p66.is_object

    if not fix_up_triangle(p65.feature, t6, v134[2], t7) then
        return nil
    end

    v289 = t6.x
    v295 = t6.y
    v296 = t6.z

    local v311 = p57[16]

    v287 = v300.a
    v288 = v300.b
    v42[1] = v287.x + v289 * p64
    v42[2] = v287.y + v295 * p64
    v42[3] = v287.z + v296 * p64
    v42[4] = v288.x - v289 * v311
    v42[5] = v288.y - v295 * v311
    v42[6] = v288.z - v296 * v311

    return 1, -v289, -v295, -v296
end

buffer.writeu32(v22, 0, 981668463)

local v312 = buffer.readf32(v22, 0)

buffer.writeu32(v22, 0, 1028443341)

local v313 = buffer.readf32(v22, 0)

buffer.writeu32(v22, 0, 1064514355)

local v314 = buffer.readf32(v22, 0)

buffer.writeu32(v22, 0, 872415232)

local v315 = buffer.readf32(v22, 0)

buffer.writeu32(v22, 0, 981668463)

local v316 = buffer.readf32(v22, 0)

buffer.writeu32(v22, 0, 1028443341)

local v317 = buffer.readf32(v22, 0)

buffer.writeu32(v22, 0, 981668463)

local v318 = buffer.readf32(v22, 0)
local F32_MIN_POSITIVE = rt.F32_MIN_POSITIVE

local function il(p67) -- line: 899
    local v319 = 1 / math.sqrt(p67)
    local v320 = v319 * 0.5 * (-p67 * (v319 * v319) + 1) + v319

    return v320 * 0.5 * (-p67 * (v320 * v320) + 1) + v320
end

local function closest_segment_xyz(p68, p69, p70, p71, p72, p73, p74, p75, p76, p77) -- line: 908
    -- upvalues: v22 (copy), to_bits (copy)
    local v321 = (p68 - p71) * p74 + (p69 - p72) * p75 + (p70 - p73) * p76

    if v321 < 0 then
        return p71, p72, p73
    end

    if p77 < v321 then
        local v322 = p74 * p77 + p71

        if v322 < 1.1754943508222875E-38 and v322 > -1.1754943508222875E-38 and v322 ~= 0 then
            buffer.writeu32(v22, 0, to_bits(v322))
        else
            buffer.writef32(v22, 0, v322)
        end

        local v323 = buffer.readf32(v22, 0)
        local v324 = p75 * p77 + p72

        if v324 < 1.1754943508222875E-38 and v324 > -1.1754943508222875E-38 and v324 ~= 0 then
            buffer.writeu32(v22, 0, to_bits(v324))
        else
            buffer.writef32(v22, 0, v324)
        end

        local v325 = buffer.readf32(v22, 0)
        local v326 = p76 * p77 + p73

        if v326 < 1.1754943508222875E-38 and v326 > -1.1754943508222875E-38 and v326 ~= 0 then
            buffer.writeu32(v22, 0, to_bits(v326))
        else
            buffer.writef32(v22, 0, v326)
        end

        return v323, v325, (buffer.readf32(v22, 0))
    end

    local v327 = p74 * v321 + p71

    if v327 < 1.1754943508222875E-38 and v327 > -1.1754943508222875E-38 and v327 ~= 0 then
        buffer.writeu32(v22, 0, to_bits(v327))
    else
        buffer.writef32(v22, 0, v327)
    end

    local v328 = buffer.readf32(v22, 0)
    local v329 = p75 * v321 + p72

    if v329 < 1.1754943508222875E-38 and v329 > -1.1754943508222875E-38 and v329 ~= 0 then
        buffer.writeu32(v22, 0, to_bits(v329))
    else
        buffer.writef32(v22, 0, v329)
    end

    local v330 = buffer.readf32(v22, 0)
    local v331 = p76 * v321 + p73

    if v331 < 1.1754943508222875E-38 and v331 > -1.1754943508222875E-38 and v331 ~= 0 then
        buffer.writeu32(v22, 0, to_bits(v331))
    else
        buffer.writef32(v22, 0, v331)
    end

    return v328, v330, (buffer.readf32(v22, 0))
end

t1.closest_segment_xyz = closest_segment_xyz

local t10 = {
    0, 0, 0
}
local t11 = {
    0, 0, 0
}
local t12 = {
    0, 0, 0
}
local t13 = {
    false,
    false,
    false
}
local fround2 = rt.fround

local function edge_plane(p78, p79, p80, p81, p82, p83, p84) -- line: 937
    -- upvalues: v315 (copy), v316 (copy), t10 (copy), t11 (copy), t12 (copy), t13 (copy), fround2 (copy)
    local v332 = -p81 * p83 + p80 * p84
    local v333 = -p79 * p84 + p81 * p82
    local v334 = -p80 * p82 + p79 * p83
    local v335 = v332 * v332 + v333 * v333 + v334 * v334

    if v335 > 1E-04 then
        local v336 = 1 / math.sqrt(v335)
        local v337 = v336 * 0.5 * (-v335 * (v336 * v336) + 1) + v336
        local v338 = v337 * 0.5 * (-v335 * (v337 * v337) + 1) + v337
        local v339 = v332 * v338
        local v340 = v333 * v338
        local v341 = v334 * v338

        t10[p78] = v339
        t11[p78] = v340
        t12[p78] = v341
        t13[p78] = true
    else
        local v342 = fround2(v335)
        local v343

        if v342 == 0 then
            v343 = 0
        else
            local v344 = 1 / math.sqrt(v342)
            local v345 = v344 * 0.5 * (-v342 * (v344 * v344) + 1) + v344

            v343 = v342 * (v345 * 0.5 * (-v342 * (v345 * v345) + 1) + v345)
        end

        t13[p78] = not (v343 < v316)

        if v315 < v335 then
            local v346 = 1 / math.sqrt(v335)
            local v347 = v346 * 0.5 * (-v335 * (v346 * v346) + 1) + v346
            local v348 = v347 * 0.5 * (-v335 * (v347 * v347) + 1) + v347
            local v349 = v332 * v348
            local v350 = v333 * v348
            local v351 = v334 * v348

            t10[p78] = v349
            t11[p78] = v350
            t12[p78] = v351
        else
            t10[p78] = v332
            t11[p78] = v333
            t12[p78] = v334
        end
    end
end

local function clamp_to_face(p85, p86, p87, p88) -- line: 968
    -- upvalues: v22 (copy), to_bits (copy), closest_segment_xyz (copy), t10 (copy), t11 (copy), t12 (copy)
    local v352 = t10[1] * (p85 - p88[1]) + t11[1] * (p86 - p88[2]) + t12[1] * (p87 - p88[3])
    local v353 = t10[2] * (p85 - p88[11]) + t11[2] * (p86 - p88[12]) + t12[2] * (p87 - p88[13])
    local n1 = 1

    if v353 < v352 then
        n1 = 2
    else
        v353 = v352
    end

    local v354 = t10[3] * (p85 - p88[21]) + t11[3] * (p86 - p88[22]) + t12[3] * (p87 - p88[23])

    if v354 < v353 then
        n1 = 3
    else
        v354 = v353
    end

    if not (v354 < 0) then
        return p85, p86, p87
    end

    local v355 = (n1 - 1) * 10
    local v356 = p85 - t10[n1] * v354

    if v356 < 1.1754943508222875E-38 and v356 > -1.1754943508222875E-38 and v356 ~= 0 then
        buffer.writeu32(v22, 0, to_bits(v356))
    else
        buffer.writef32(v22, 0, v356)
    end

    local v357 = buffer.readf32(v22, 0)
    local v358 = p86 - t11[n1] * v354

    if v358 < 1.1754943508222875E-38 and v358 > -1.1754943508222875E-38 and v358 ~= 0 then
        buffer.writeu32(v22, 0, to_bits(v358))
    else
        buffer.writef32(v22, 0, v358)
    end

    local v359 = buffer.readf32(v22, 0)
    local v360 = p87 - t12[n1] * v354

    if v360 < 1.1754943508222875E-38 and v360 > -1.1754943508222875E-38 and v360 ~= 0 then
        buffer.writeu32(v22, 0, to_bits(v360))
    else
        buffer.writef32(v22, 0, v360)
    end

    return closest_segment_xyz(v357, v359, buffer.readf32(v22, 0), p88[v355 + 1], p88[v355 + 2], p88[v355 + 3], p88[v355 + 4], p88[v355 + 5], p88[v355 + 6], p88[v355 + 10])
end

local v361 = false

function t1.set_vector_rounding(p89) -- line: 1009
    -- upvalues: v361 (ref)
    local v362 = not v361

    v361 = not p89

    return v362
end

local create = vector.create

local function round3(p90, p91, p92) -- line: 1016
    -- upvalues: v22 (copy), to_bits (copy), create (copy)
    local v363 = create(p90, p91, p92)
    local x, y, z = v363.x, v363.y, v363.z
    local v364

    if not (p90 < 1.1754943508222875E-38) or not (p90 > -1.1754943508222875E-38) or p90 == 0 then
        v364 = x
    else
        if not (p90 < 1.1754943508222875E-38) or not (p90 > -1.1754943508222875E-38) or p90 == 0 then
            buffer.writef32(v22, 0, p90)
        else
            buffer.writeu32(v22, 0, to_bits(p90))
        end

        v364 = buffer.readf32(v22, 0)
    end

    local v365

    if not (p91 < 1.1754943508222875E-38) or not (p91 > -1.1754943508222875E-38) or p91 == 0 then
        v365 = y
    else
        if not (p91 < 1.1754943508222875E-38) or not (p91 > -1.1754943508222875E-38) or p91 == 0 then
            buffer.writef32(v22, 0, p91)
        else
            buffer.writeu32(v22, 0, to_bits(p91))
        end

        v365 = buffer.readf32(v22, 0)
    end

    local v366

    if not (p92 < 1.1754943508222875E-38) or not (p92 > -1.1754943508222875E-38) or p92 == 0 then
        v366 = z
    else
        if not (p92 < 1.1754943508222875E-38) or not (p92 > -1.1754943508222875E-38) or p92 == 0 then
            buffer.writef32(v22, 0, p92)
        else
            buffer.writeu32(v22, 0, to_bits(p92))
        end

        v366 = buffer.readf32(v22, 0)
    end

    return v364, v365, v366
end

t1.round3 = round3

function t1.fround(p93) -- line: 1032
    -- upvalues: v22 (copy), fround2 (copy)
    if p93 ~= 0 and p93 > -1.1754943508222875E-38 and p93 < 1.1754943508222875E-38 then
        return fround2(p93)
    end

    buffer.writef32(v22, 0, p93)

    return (buffer.readf32(v22, 0))
end

local function closest_segment_v(p94, p95, p96, p97, p98, p99, p100, p101, p102, p103) -- line: 1040
    -- upvalues: round3 (copy)
    local v367 = (p94 - p97) * p100 + (p95 - p98) * p101 + (p96 - p99) * p102

    if v367 < 0 then
        return p97, p98, p99
    end

    if p103 < v367 then
        return round3(p100 * p103 + p97, p101 * p103 + p98, p102 * p103 + p99)
    end

    return round3(p100 * v367 + p97, p101 * v367 + p98, p102 * v367 + p99)
end

local function clamp_to_face_v(p104, p105, p106, p107, p108) -- line: 1055
    -- upvalues: t10 (copy), t11 (copy), t12 (copy), round3 (copy), closest_segment_v (copy)
    local v368 = t10[1] * (p104 - p107[p108 + 1]) + t11[1] * (p105 - p107[p108 + 2]) + t12[1] * (p106 - p107[p108 + 3])
    local v369 = t10[2] * (p104 - p107[p108 + 11]) + t11[2] * (p105 - p107[p108 + 12]) + t12[2] * (p106 - p107[p108 + 13])
    local n2 = 1

    if v369 < v368 then
        n2 = 2
    else
        v369 = v368
    end

    local v370 = t10[3] * (p104 - p107[p108 + 21]) + t11[3] * (p105 - p107[p108 + 22]) + t12[3] * (p106 - p107[p108 + 23])

    if v370 < v369 then
        n2 = 3
    else
        v370 = v369
    end

    if v370 < 0 then
        local v371 = p108 + (n2 - 1) * 10
        local v372, v373, v374 = round3(p104 - t10[n2] * v370, p105 - t11[n2] * v370, p106 - t12[n2] * v370)

        return closest_segment_v(v372, v373, v374, p107[v371 + 1], p107[v371 + 2], p107[v371 + 3], p107[v371 + 4], p107[v371 + 5], p107[v371 + 6], p107[v371 + 10])
    end

    return p104, p105, p106
end

local function segment_face_xyz(p109, p110, p111, p112, p113, p114, p115, p116, p117, p118, p119, p120, p121, p122, p123) -- line: 1098
    -- upvalues: v22 (copy), to_bits (copy), v317 (copy), v318 (copy), F32_MIN_POSITIVE (copy), t10 (copy), t11 (copy), t12 (copy), t13 (copy), fround2 (copy), edge_plane (copy), round3 (copy), closest_segment_v (copy), clamp_to_face_v (copy)
    edge_plane(1, p111, p112, p113, p109[p110 + 4], p109[p110 + 5], p109[p110 + 6])
    edge_plane(2, p111, p112, p113, p109[p110 + 14], p109[p110 + 15], p109[p110 + 16])
    edge_plane(3, p111, p112, p113, p109[p110 + 24], p109[p110 + 25], p109[p110 + 26])

    local n3 = 0
    local v375 = p123
    local v376 = false
    local n4 = 0
    local n5 = 0
    local n6 = 0
    local n7 = 0
    local n8 = 0
    local n9 = 0
    local v377 = false

    for i = 1, 3 do
        if t13[i] then
            local v378 = t10[i]
            local v379 = t11[i]
            local v380 = t12[i]
            local v381 = p110 + (i - 1) * 10
            local v382 = p120 * v378 + p121 * v379 + p122 * v380
            local v383 = (p109[v381 + 1] - p117) * v378 + (p109[v381 + 2] - p118) * v379 + (p109[v381 + 3] - p119) * v380

            if math.abs(v382) < v317 then
                if v383 > 0 then
                    n4 = p109[v381 + 1]
                    n5 = p109[v381 + 2]
                    n6 = p109[v381 + 3]
                    n7, n8, n9 = round3(v378, v379, v380)
                    v376 = true
                end
            else
                local v384 = v383 / v382

                if v382 > 0 then
                    if n3 < v384 then
                        if not (v384 < 1.1754943508222875E-38) or not (v384 > -1.1754943508222875E-38) or v384 == 0 then
                            buffer.writef32(v22, 0, v384)
                        else
                            buffer.writeu32(v22, 0, to_bits(v384))
                        end

                        n3 = buffer.readf32(v22, 0)
                    end

                    if v375 < n3 then
                        n3 = v375
                        v377 = true
                        break
                    end
                else
                    if v384 < v375 then
                        if not (v384 < 1.1754943508222875E-38) or not (v384 > -1.1754943508222875E-38) or v384 == 0 then
                            buffer.writef32(v22, 0, v384)
                        else
                            buffer.writeu32(v22, 0, to_bits(v384))
                        end

                        v375 = buffer.readf32(v22, 0)
                    end

                    if v375 < n3 then
                        v375 = n3
                        v377 = true
                        break
                    end
                end
            end
        end
    end

    local v385 = p109[p110 + 1]
    local v386 = p109[p110 + 2]
    local v387 = p109[p110 + 3]

    if v377 or v376 then
        local v388 = v375 - n3

        if v318 < v388 then
            local v389 = p111 * (v385 - p117) + p112 * (v386 - p118) + p113 * (v387 - p119)
            local v390 = p111 * v389 + p117
            local v391 = p112 * v389 + p118
            local v392 = p113 * v389 + p119
            local v393 = n7 * (n4 - v390) + n8 * (n5 - v391) + n9 * (n6 - v392)
            local v394 = n7 * v393 + v390
            local v395 = n8 * v393 + v391
            local v396 = n9 * v393 + v392
            local v397 = p120 * n3 + v394
            local v398 = p121 * n3 + v395
            local v399 = p122 * n3 + v396
            local v400, v401, v402 = round3(v397, v398, v399)
            local v403, v404, v405 = clamp_to_face_v(v400, v401, v402, p109, p110)
            local v406, v407, v408 = round3(p120 * v388 + v397, p121 * v388 + v398, p122 * v388 + v399)
            local v409, v410, v411 = clamp_to_face_v(v406, v407, v408, p109, p110)
            local v412, v413, v414 = closest_segment_v(v403, v404, v405, p117, p118, p119, p120, p121, p122, p123)
            local v415, v416, v417 = closest_segment_v(v409, v410, v411, p117, p118, p119, p120, p121, p122, p123)
            local v418 = v403 - v412
            local v419 = v404 - v413
            local v420 = v405 - v414
            local v421 = v418 * v418 + v419 * v419 + v420 * v420
            local v422

            if v421 ~= 0 and v421 > -1.1754943508222875E-38 and v421 < 1.1754943508222875E-38 then
                v422 = fround2(v421)
            else
                buffer.writef32(v22, 0, v421)
                v422 = buffer.readf32(v22, 0)
            end

            local v423

            if v422 == 0 then
                v423 = 0
            else
                local v424 = 1 / math.sqrt(v422)
                local v425 = v424 * 0.5 * (-v422 * (v424 * v424) + 1) + v424

                v423 = v422 * (v425 * 0.5 * (-v422 * (v425 * v425) + 1) + v425)
            end

            if not (F32_MIN_POSITIVE < v423) then
                return 2, false, 0, 0, 0, v403, v404, v405, v412, v413, v414, v409, v410, v411, v415, v416, v417
            end

            local v426 = -v420 * p121 + v419 * p122
            local v427 = -v418 * p122 + v420 * p120
            local v428 = -v419 * p120 + v418 * p121
            local v429 = -p122 * v427 + p121 * v428
            local v430 = -p120 * v428 + p122 * v426
            local v431 = -p121 * v426 + p120 * v427
            local v432 = v429 * v429 + v430 * v430 + v431 * v431
            local v433 = 1 / math.sqrt(v432)
            local v434 = v433 * 0.5 * (-v432 * (v433 * v433) + 1) + v433
            local v435 = v434 * 0.5 * (-v432 * (v434 * v434) + 1) + v434
            local v436, v437, v438 = round3(v429 * v435, v430 * v435, v431 * v435)

            return 2, true, v436, v437, v438, v403, v404, v405, v412, v413, v414, v409, v410, v411, v415, v416, v417
        end

        local v439 = p120 * n3 + p117
        local v440 = p121 * n3 + p118
        local v441 = p122 * n3 + p119
        local v442 = p111 * (v385 - v439) + p112 * (v386 - v440) + p113 * (v387 - v441)
        local v443, v444, v445 = round3(p111 * v442 + v439, p112 * v442 + v440, p113 * v442 + v441)
        local v446, v447, v448 = clamp_to_face_v(v443, v444, v445, p109, p110)
        local v449, v450, v451 = closest_segment_v(v446, v447, v448, p117, p118, p119, p120, p121, p122, p123)

        return 1, false, 0, 0, 0, v446, v447, v448, v449, v450, v451, 0, 0, 0, 0, 0, 0
    end

    local v452 = p111 * p114 + p112 * p115 + p113 * p116
    local v453 = p120 * n3 + p117
    local v454 = p121 * n3 + p118
    local v455 = p122 * n3 + p119
    local v456, v457, v458 = round3(v453, v454, v455)
    local v459 = ((v385 - v453) * p114 + (v386 - v454) * p115 + (v387 - v455) * p116) / v452
    local v460, v461, v462 = round3(p111 * v459 + v453, p112 * v459 + v454, p113 * v459 + v455)
    local v463 = p120 * v375 + p117
    local v464 = p121 * v375 + p118
    local v465 = p122 * v375 + p119
    local v466, v467, v468 = round3(v463, v464, v465)
    local v469 = ((v385 - v463) * p114 + (v386 - v464) * p115 + (v387 - v465) * p116) / v452
    local v470, v471, v472 = round3(p111 * v469 + v463, p112 * v469 + v464, p113 * v469 + v465)

    return 2, false, 0, 0, 0, v460, v461, v462, v456, v457, v458, v470, v471, v472, v466, v467, v468
end

t1.segment_face_xyz = segment_face_xyz

function t1.triangle_gp_record(p124, p125, p126) -- line: 1211
    -- upvalues: pack (copy)
    local v473 = p124[p125 + 1]

    if v473 == nil then
        v473 = pack({
            tag = "Triangle",
            p126
        })
        p124[p125 + 1] = v473
    end

    return v473
end

buffer.writeu32(v22, 0, 1065350699)

local v474 = buffer.readf32(v22, 0)

buffer.writeu32(v22, 0, 1028443341)

local v475 = buffer.readf32(v22, 0)

buffer.writeu32(v22, 0, 981668463)

local v476 = buffer.readf32(v22, 0)

buffer.writeu32(v22, 0, 1064849900)

local v477 = buffer.readf32(v22, 0)

local function edge_cos(p127, p128, p129, p130, p131, p132, p133) -- line: 1246
    local v478 = 43 - p128 * 3
    local v479 = -p127[v478]
    local v480 = -p127[v478 + 1]
    local v481 = -p127[v478 + 2]
    local v482 = p127[34]
    local v483 = p127[35]
    local v484 = p127[36]

    if p129 * (-v481 * v483 + v480 * v484) + p130 * (-v479 * v484 + v481 * v482) + p131 * (-v480 * v482 + v479 * v483) < 0 then
        return true
    end

    if not (p132 or p133) then
        return false
    end

    local v485 = p129 * v479 + p130 * v480 + p131 * v481
    local v486 = p129 - v479 * v485
    local v487 = p130 - v480 * v485
    local v488 = p131 - v481 * v485
    local v489 = v486 * v486 + v487 * v487 + v488 * v488
    local v490 = 1 / math.sqrt(v489)
    local v491 = v490 * 0.5 * (-v489 * (v490 * v490) + 1) + v490
    local v492 = v491 * 0.5 * (-v489 * (v491 * v491) + 1) + v491
    local v493 = v486 * v492
    local v494 = v487 * v492
    local v495 = v488 * v492

    if p132 then
        return v493 * v482 + v494 * v483 + v495 * v484 >= p127[p128 + 46]
    end

    return v493 * -v482 + v494 * -v483 + v495 * -v484 >= p127[p128 + 46]
end

local function fix_up_toward(p134, p135, p136, p137, p138) -- line: 1271
    -- upvalues: fround2 (copy), v474 (copy), v475 (copy), v476 (copy), v477 (copy), edge_cos (copy)
    local v496 = p134[34]
    local v497 = p134[35]
    local v498 = p134[36]
    local v499 = p135 * v496 + p136 * v497 + p137 * v498
    local v500 = p134[49]
    local v501 = bit32.band(v500, 16) ~= 0

    if math.abs(v499) < v474 then
        local v502 = p135 - v496 * v499
        local v503 = p136 - v497 * v499
        local v504 = p137 - v498 * v499
        local v505 = v502 * v502 + v503 * v503 + v504 * v504
        local v506 = 1 / math.sqrt(v505)
        local v507 = v506 * 0.5 * (-v505 * (v506 * v506) + 1) + v506
        local v508 = v507 * 0.5 * (-v505 * (v507 * v507) + 1) + v507
        local v509 = v502 * v508
        local v510 = v503 * v508
        local v511 = v504 * v508
        local v512 = v509 * p134[37] + v510 * p134[38] + v511 * p134[39]
        local v513 = v509 * p134[40] + v510 * p134[41] + v511 * p134[42]
        local v514 = v509 * p134[43] + v510 * p134[44] + v511 * p134[45]
        local n10 = 2

        if v475 < v512 and v513 < -v475 then
            n10 = 6
        elseif v475 < v513 and v514 < -v475 then
            n10 = 5
        elseif v475 < v514 and v512 < -v475 then
            n10 = 4
        elseif -v514 < v512 and v512 <= -v513 then
            n10 = 3
        elseif not (-v512 < v513 and v513 <= -v514) then
            if not (-v513 < v514 and v514 <= -v512) then
                local v515 = if v501 then v499 > 0 else nil

                if not v501 or v515 then
                    return 1
                end

                return 0
            end

            n10 = 1
        end

        if n10 >= 4 then
            local v516 = n10 - 4
            local v518 = bit32.band(v500, (bit32.lshift(512, v516))) ~= 0

            if bit32.band(v500, 256) == 0 then
                local v519, v520

                if v501 then
                    if v474 < v499 then
                        return 1
                    end

                    v519 = v499 < 0
                else
                    v520 = math.abs(v499) > v474
                end

                if v501 and not v519 or not v501 and not v520 then
                    if v518 then
                        return 0
                    end
                elseif v501 then
                    return 0
                end

                return 1
            end

            local v521 = (v516 + 2) % 3
            local v523 = bit32.band(v500, (bit32.lshift(32, v521))) ~= 0
            local v525 = bit32.band(v500, (bit32.lshift(32, v516))) ~= 0

            if v501 then
                local v526 = v518 and not p138.is_object

                if v499 > 0 and v526 then
                    if not v523 or v525 then
                        if v523 or not v525 then
                            return 0
                        end
                    else
                        v521 = v516
                    end

                    local v527 = p134[46 + v521]

                    if not (v527 <= v477 and v476 < v527) then
                        return 0
                    end

                    return -1
                end

                if not v526 and edge_cos(p134, v521, p135, p136, p137, v523, false) and edge_cos(p134, v516, p135, p136, p137, v525, false) then
                    return 1
                end
            elseif not v518 and edge_cos(p134, v521, p135, p136, p137, v523, true) and edge_cos(p134, v516, p135, p136, p137, v525, true) then
                return 1
            end
        else
            local v530 = bit32.band(v500, (bit32.lshift(32, n10 - 1))) ~= 0

            if bit32.band(v500, 256) == 0 then
                local v531, v532

                if v501 then
                    if v474 < v499 then
                        return 1
                    end

                    v531 = v499 < 0
                else
                    v532 = math.abs(v499) > v474
                end

                if v501 and not v531 or not v501 and not v532 then
                    if v530 then
                        return 1
                    end

                    return 0
                end

                if v501 then
                    return 0
                end

                return 1
            end

            local v533 = p134[45 + n10]

            if v501 then
                if not v530 and (not p138.is_object or not (math.abs(v533 - 1) < 1E-05)) then
                    if p138.edge_cos_bend_normal_threshold < v533 or v533 <= v476 then
                        return 0
                    end

                    local v536 = fround2(1 - v533 * v533)
                    local v537

                    if v536 == 0 then
                        v537 = 0
                    else
                        local v538 = 1 / math.sqrt(v536)
                        local v539 = v538 * 0.5 * (-v536 * (v538 * v538) + 1) + v538

                        v537 = v536 * (v539 * 0.5 * (-v536 * (v539 * v539) + 1) + v539)
                    end

                    if v537 < v499 then
                        return -1
                    end

                    return 0
                end

                if v533 <= v499 + p138.convexity_epsilon then
                    return 1
                end
            else
                if not v530 then
                    v499 = -v499
                end

                if v533 <= v499 then
                    return 1
                end
            end
        end
    else
        local v540 = if v501 then v499 > 0 else nil

        if not v501 or v540 then
            return 1
        end
    end

    return 0
end

t1.fix_up_toward = fix_up_toward

function t1.fix_up_xyz(p139, p140, p141, p142, p143) -- line: 1398
    -- upvalues: fix_up_toward (copy)
    return (fix_up_toward(p139, -p140, -p141, -p142, p143))
end

local v541 = true
local v542

function t1.set_tail_filter(p144) -- line: 1482
    -- upvalues: v541 (ref)
    local v543 = v541

    v541 = p144

    return v543
end

function t1.set_tail_stats(p145) -- line: 1489
    -- upvalues: v542 (ref)
    v542 = p145
end

local function tail_class(p146, p147) -- line: 1504
    -- upvalues: round3 (copy)
    local v544 = table.create(45, 0)
    local v545 = p146[34]
    local v546 = p146[35]
    local v547 = p146[36]
    local v548 = v545 * v545 + v546 * v546 + v547 * v547
    local n11 = 0

    for i = 37, 43, 3 do
        local v549 = p146[i] * p146[i] + p146[i + 1] * p146[i + 1] + p146[i + 2] * p146[i + 2]

        if not (v549 <= n11) then
            n11 = v549
        end
    end

    local v550 = p146[49]
    local v551 = p147[31]
    local v552 = if v551 == 3 then 2 else 0
    local n12 = 0
    local n13 = 0

    for i = 0, v552 do
        local v553 = i * 10
        local v554 = p147[v553 + 1]
        local v555 = p147[v553 + 2]
        local v556 = p147[v553 + 3]
        local v557, v558, v559

        if v551 == 0 then
            v559 = v556
            v557 = v554
            v558 = v555
        else
            local v560 = p147[v553 + 4]
            local v561 = p147[v553 + 5]
            local v562 = p147[v553 + 6]
            local v563 = p147[v553 + 10]

            v557 = v560 * v563 + v554
            v558 = v561 * v563 + v555
            v559 = v562 * v563 + v556

            local v564 = i * 3 + 38
            local v565 = i * 3 + 39
            local v566, v567, v568 = round3(v557, v558, v559)

            v544[i * 3 + 37] = v566
            v544[v564] = v567
            v544[v565] = v568
        end

        local v575 = math.max(math.abs(v554), math.abs(v555), math.abs(v556), math.abs(v557), math.abs(v558), (math.abs(v559)))

        if not (v575 <= n13) then
            n13 = v575
        end

        for j = 7, 13, 3 do
            local v576 = p146[j]
            local v577 = p146[j + 1]
            local v578 = p146[j + 2]
            local v579 = (v576 - v554) * (v576 - v554) + (v577 - v555) * (v577 - v555) + (v578 - v556) * (v578 - v556)

            if not (v579 <= n12) then
                n12 = v579
            end

            local v580 = (v576 - v557) * (v576 - v557) + (v577 - v558) * (v577 - v558) + (v578 - v559) * (v578 - v559)

            if not (v580 <= n12) then
                n12 = v580
            end
        end
    end

    for i = 7, 15 do
        local v582 = math.abs(p146[i])

        if not (v582 <= n13) then
            n13 = v582
        end
    end

    if p146[33] == 1 and v548 <= 1.002 and n11 <= 1.002 and n12 < 1E+12 and n13 < 1E+12 and type(v550) == "number" and v550 >= 0 and v550 <= 4294967295 and v550 % 1 == 0 and (v551 == 3 or v551 == 1 or v551 == 0) then
        local v583 = math.sqrt(n12) * 1.001 + 1E-06

        v544[1] = 1
        v544[2] = v583
        v544[3] = n13
        v544[4] = math.sqrt(v548) * 1.000000001 * 1.05E-07 + 1E-13
        v544[5] = (n13 + 5) * 3.5E-07 + 1.3E-06 + (v583 + 5) * 1E-07
    else
        v544[1] = 0
    end

    v544[6] = (0/0)
    v544[21] = (0/0)
    v544[36] = 0
    p147[32] = v544

    return v544
end

local function tail_rules(p148, p149, p150, p151, p152) -- line: 1602
    -- upvalues: fround2 (copy), v476 (copy), v477 (copy)
    local v584 = 5 + 15 * p148[36]

    p148[36] = 1 - p148[36]

    local v585 = v584 + 1
    local v586 = v584 + 2
    local v587 = v584 + 3

    p148[v585] = p150
    p148[v586] = p151
    p148[v587] = p152

    local v588 = p149[49]
    local v589 = bit32.band(v588, 16) ~= 0
    local v590 = bit32.band(v588, 256) ~= 0

    for i = 1, 3 do
        local v592 = bit32.band(v588, (bit32.lshift(32, i - 1))) ~= 0
        local v593 = p149[i + 45]
        local v594

        if v590 then
            if v593 == v593 then
                if v589 then
                    if not v592 and (p152 ~= 1 or not (math.abs(v593 - 1) < 1E-05)) then
                        if p150 < v593 or v593 <= v476 then
                            v594 = (-1e999)
                            v593 = 1e999
                        else
                            local v597 = fround2(1 - v593 * v593)

                            if v597 == 0 then
                                v594 = (-1e999)
                                v593 = 0
                            else
                                local v598 = 1 / math.sqrt(v597)
                                local v599 = v598 * 0.5 * (-v597 * (v598 * v598) + 1) + v598

                                v594 = (-1e999)
                                v593 = v597 * (v599 * 0.5 * (-v597 * (v599 * v599) + 1) + v599)
                            end
                        end
                    elseif math.abs(p151) < 1E+06 then
                        v594 = (-1e999)
                        v593 = v593 - p151 - 1E-09
                    else
                        v594 = 1e999
                        v593 = (-1e999)
                    end
                elseif v592 then
                    v594 = (-1e999)
                else
                    v594 = -v593
                    v593 = 1e999
                end
            else
                v594 = 1e999
                v593 = (-1e999)
            end
        elseif v592 then
            if v589 then
                v594 = (-1e999)
                v593 = 0
            else
                v594 = 1e999
                v593 = (-1e999)
            end
        else
            v594 = (-1e999)
            v593 = 1e999
        end

        local v600 = v584 + 3 + i
        local v601 = v584 + 9 + i

        p148[v600] = v594
        p148[v601] = v593
    end

    for i = 0, 2 do
        local v603 = bit32.band(v588, (bit32.lshift(512, i))) ~= 0
        local v604, v605

        if v590 then
            if v589 then
                if v603 and p152 == 0 then
                    local v606 = (i + 2) % 3
                    local v608 = bit32.band(v588, (bit32.lshift(32, v606))) ~= 0

                    if v608 == (bit32.band(v588, (bit32.lshift(32, i))) ~= 0) then
                        v604 = (-1e999)
                        v605 = 1e999
                    else
                        local v610 = p149[(if v608 then i else v606) + 46]

                        if v610 == v610 then
                            v605 = if v610 <= v477 and v476 < v610 then 0 else 1e999
                            v604 = (-1e999)
                        else
                            v604 = 1e999
                            v605 = (-1e999)
                        end
                    end
                else
                    v604 = 1e999
                    v605 = (-1e999)
                end
            elseif v603 then
                v604 = (-1e999)
                v605 = 1e999
            else
                v604 = 1e999
                v605 = (-1e999)
            end
        elseif v603 then
            v604 = (-1e999)
            v605 = 1e999
        elseif v589 then
            v604 = (-1e999)
            v605 = 0
        else
            v604 = 1e999
            v605 = (-1e999)
        end

        local v611 = v584 + 7 + i
        local v612 = v584 + 13 + i

        p148[v611] = v604
        p148[v612] = v605
    end

    return v584
end

local function tail_refused(p153, p154, p155, p156, p157, p158, p159, p160, p161, p162, p163) -- line: 1681
    -- upvalues: v474 (copy), v475 (copy), tail_rules (copy)
    if p154[1] ~= 1 or not (p162 > 1E-08) or not (p162 < 16) or not (p163 <= 4) then
        return false
    end

    local v613, v614 = p155.edge_cos_bend_normal_threshold, p155.convexity_epsilon
    local v615 = if p155.is_object then 1 else 0
    local v616, v617, v618, v619, v620, v621, v622, v623, v624, v625, v626, v627, v628, v629, v630, v631

    if p154[6] == v613 and p154[7] == v614 and p154[8] == v615 then
        v631 = 5
        v616 = math.sqrt(p162)
        v626 = if p163 > 0 then p163 else 0
        v614 = (v626 + p154[5]) * v616 * 1.000000001

        if not (v614 + p154[2] * v616 * 1.000000001 <= p162) then
            v613 = (p153[7] - p156) * p159 + (p153[8] - p157) * p160 + (p153[9] - p158) * p161
            v618 = (p153[10] - p156) * p159 + (p153[11] - p157) * p160 + (p153[12] - p158) * p161

            if not (v618 < v613) then
                v618 = v613
            end

            v617 = (p153[13] - p156) * p159 + (p153[14] - p157) * p160 + (p153[15] - p158) * p161

            if not (v617 < v618) then
                v617 = v618
            end

            if not (v614 <= v617) then
                return false
            end
        end

        v618 = p153[34]
        v619 = p153[35]
        v626 = p153[36]
        v614 = p159 * v618 + p160 * v619 + p161 * v626
        v620 = p154[4]

        if not (math.abs(v614) < (v474 - v620) * v616 * 0.999999999) then
            return false
        end

        v622 = v618 * v614 - p159
        v623 = v619 * v614 - p160
        v624 = v626 * v614 - p161
        v626 = v622 * v622 + v623 * v623 + v624 * v624

        if not (p162 * 0.00010001 <= v626) then
            return false
        end

        v625 = math.sqrt(v626)
        v626 = v622 * p153[37] + v623 * p153[38] + v624 * p153[39]
        v618 = v622 * p153[40] + v623 * p153[41] + v624 * p153[42]
        v629 = v622 * p153[43] + v623 * p153[44] + v624 * p153[45]
        v624 = v625 * 2.5E-05
        v623 = v475 * v625 + v624
        v622 = v475 * v625 - v624

        if not (v623 < v626 and v618 < -v623) then
            if not (v626 < v622 or -v622 < v618) then
                return false
            end

            if not (v623 < v618 and v629 < -v623) then
                if not (v618 < v622 or -v622 < v629) then
                    return false
                end

                if not (v623 < v629 and v626 < -v623) then
                    if not (v629 < v622 or -v622 < v626) then
                        return false
                    end

                    v624 += v624
                    v630 = v626 + v629
                    v627 = v626 + v618
                    v628 = v618 + v629

                    if not (v624 < v630 and v627 < -v624) then
                        if not (v630 < -v624 or v624 < v627) then
                            return false
                        end

                        if not (v624 < v627 and v628 < -v624) then
                            if not (v627 < -v624 or v624 < v628) or not (v624 < v628) or not (v630 < -v624) then
                                return false
                            end

                            v621 = 1
                        else
                            v621 = 2
                        end
                    else
                        v621 = 3
                    end
                else
                    v621 = 4
                end
            else
                v621 = 5
            end
        else
            v621 = 6
        end

        v625 = -v614 / v616

        if v625 + v620 < p154[v631 + 9 + v621] then
            return v625 - v620 > p154[v631 + 3 + v621]
        end

        return false
    end

    if p154[21] == v613 and p154[22] == v614 and p154[23] == v615 then
        v631 = 20
        v616 = math.sqrt(p162)
        v626 = if p163 > 0 then p163 else 0
        v614 = (v626 + p154[5]) * v616 * 1.000000001
        v617 = v614 + p154[2] * v616 * 1.000000001

        if not (v617 <= p162) then
            v613 = (p153[7] - p156) * p159 + (p153[8] - p157) * p160 + (p153[9] - p158) * p161
            v618 = (p153[10] - p156) * p159 + (p153[11] - p157) * p160 + (p153[12] - p158) * p161

            if not (v618 < v613) then
                v618 = v613
            end

            v617 = (p153[13] - p156) * p159 + (p153[14] - p157) * p160 + (p153[15] - p158) * p161

            if not (v617 < v618) then
                v617 = v618
            end

            if not (v614 <= v617) then
                return false
            end
        end

        v618 = p153[34]
        v619 = p153[35]
        v626 = p153[36]
        v614 = p159 * v618 + p160 * v619 + p161 * v626
        v620 = p154[4]
        v622 = math.abs(v614)
        v623 = (v474 - v620) * v616 * 0.999999999

        if v622 < v623 then
            v622 = v618 * v614 - p159
            v623 = v619 * v614 - p160
            v624 = v626 * v614 - p161
            v626 = v622 * v622 + v623 * v623 + v624 * v624
            v625 = p162 * 0.00010001

            if v625 <= v626 then
                v625 = math.sqrt(v626)
                v626 = v622 * p153[37] + v623 * p153[38] + v624 * p153[39]
                v618 = v622 * p153[40] + v623 * p153[41] + v624 * p153[42]
                v629 = v622 * p153[43] + v623 * p153[44] + v624 * p153[45]
                v624 = v625 * 2.5E-05
                v623 = v475 * v625 + v624
                v622 = v475 * v625 - v624

                if v623 < v626 and v618 < -v623 then
                    v621 = 6
                    v625 = -v614 / v616

                    if v625 + v620 < p154[v631 + 9 + v621] then
                        return v625 - v620 > p154[v631 + 3 + v621]
                    end

                    return false
                end

                if not (v626 < v622) and not (-v622 < v618) then
                    return false
                end

                if v623 < v618 and v629 < -v623 then
                    v621 = 5
                    v625 = -v614 / v616

                    if v625 + v620 < p154[v631 + 9 + v621] then
                        return v625 - v620 > p154[v631 + 3 + v621]
                    end

                    return false
                end

                if not (v618 < v622) and not (-v622 < v629) then
                    return false
                end

                if v623 < v629 and v626 < -v623 then
                    v621 = 4
                    v625 = -v614 / v616

                    if v625 + v620 < p154[v631 + 9 + v621] then
                        return v625 - v620 > p154[v631 + 3 + v621]
                    end

                    return false
                end

                if not (v629 < v622) and not (-v622 < v626) then
                    return false
                end

                v624 += v624
                v630 = v626 + v629
                v627 = v626 + v618
                v628 = v618 + v629

                if v624 < v630 and v627 < -v624 then
                    v621 = 3
                    v625 = -v614 / v616

                    if v625 + v620 < p154[v631 + 9 + v621] then
                        return v625 - v620 > p154[v631 + 3 + v621]
                    end

                    return false
                end

                if not (v630 < -v624) and not (v624 < v627) then
                    return false
                end

                if v624 < v627 and v628 < -v624 then
                    v621 = 2
                    v625 = -v614 / v616

                    if v625 + v620 < p154[v631 + 9 + v621] then
                        return v625 - v620 > p154[v631 + 3 + v621]
                    end

                    return false
                end

                if not (v627 < -v624) and not (v624 < v628) then
                    return false
                end

                if v624 < v628 and v630 < -v624 then
                    v621 = 1
                    v625 = -v614 / v616

                    if v625 + v620 < p154[v631 + 9 + v621] then
                        return v625 - v620 > p154[v631 + 3 + v621]
                    end

                    return false
                end
            end
        end

        return false
    end

    if v613 == v613 and v614 == v614 then
        v631 = tail_rules(p154, p153, v613, v614, v615)
        v616 = math.sqrt(p162)
        v626 = if p163 > 0 then p163 else 0
        v614 = (v626 + p154[5]) * v616 * 1.000000001
        v617 = v614 + p154[2] * v616 * 1.000000001

        if not (v617 <= p162) then
            v613 = (p153[7] - p156) * p159 + (p153[8] - p157) * p160 + (p153[9] - p158) * p161
            v618 = (p153[10] - p156) * p159 + (p153[11] - p157) * p160 + (p153[12] - p158) * p161

            if not (v618 < v613) then
                v618 = v613
            end

            v617 = (p153[13] - p156) * p159 + (p153[14] - p157) * p160 + (p153[15] - p158) * p161

            if not (v617 < v618) then
                v617 = v618
            end

            if not (v614 <= v617) then
                return false
            end
        end

        v618 = p153[34]
        v619 = p153[35]
        v626 = p153[36]
        v614 = p159 * v618 + p160 * v619 + p161 * v626
        v620 = p154[4]
        v622 = math.abs(v614)
        v623 = (v474 - v620) * v616 * 0.999999999

        if v622 < v623 then
            v622 = v618 * v614 - p159
            v623 = v619 * v614 - p160
            v624 = v626 * v614 - p161
            v626 = v622 * v622 + v623 * v623 + v624 * v624
            v625 = p162 * 0.00010001

            if v625 <= v626 then
                v625 = math.sqrt(v626)
                v626 = v622 * p153[37] + v623 * p153[38] + v624 * p153[39]
                v618 = v622 * p153[40] + v623 * p153[41] + v624 * p153[42]
                v629 = v622 * p153[43] + v623 * p153[44] + v624 * p153[45]
                v624 = v625 * 2.5E-05
                v623 = v475 * v625 + v624
                v622 = v475 * v625 - v624

                if v623 < v626 and v618 < -v623 then
                    v621 = 6
                    v625 = -v614 / v616

                    if v625 + v620 < p154[v631 + 9 + v621] then
                        return v625 - v620 > p154[v631 + 3 + v621]
                    end

                    return false
                end

                if not (v626 < v622) and not (-v622 < v618) then
                    return false
                end

                if v623 < v618 and v629 < -v623 then
                    v621 = 5
                    v625 = -v614 / v616

                    if v625 + v620 < p154[v631 + 9 + v621] then
                        return v625 - v620 > p154[v631 + 3 + v621]
                    end

                    return false
                end

                if not (v618 < v622) and not (-v622 < v629) then
                    return false
                end

                if v623 < v629 and v626 < -v623 then
                    v621 = 4
                    v625 = -v614 / v616

                    if v625 + v620 < p154[v631 + 9 + v621] then
                        return v625 - v620 > p154[v631 + 3 + v621]
                    end

                    return false
                end

                if not (v629 < v622) and not (-v622 < v626) then
                    return false
                end

                v624 += v624
                v630 = v626 + v629
                v627 = v626 + v618
                v628 = v618 + v629

                if v624 < v630 and v627 < -v624 then
                    v621 = 3
                    v625 = -v614 / v616

                    if v625 + v620 < p154[v631 + 9 + v621] then
                        return v625 - v620 > p154[v631 + 3 + v621]
                    end

                    return false
                end

                if not (v630 < -v624) and not (v624 < v627) then
                    return false
                end

                if v624 < v627 and v628 < -v624 then
                    v621 = 2
                    v625 = -v614 / v616

                    if v625 + v620 < p154[v631 + 9 + v621] then
                        return v625 - v620 > p154[v631 + 3 + v621]
                    end

                    return false
                end

                if not (v627 < -v624) and not (v624 < v628) then
                    return false
                end

                if v624 < v628 and v630 < -v624 then
                    v621 = 1
                    v625 = -v614 / v616

                    if v625 + v620 < p154[v631 + 9 + v621] then
                        return v625 - v620 > p154[v631 + 3 + v621]
                    end

                    return false
                end
            end
        end
    end

    return false
end

t1.tail_class = tail_class
t1.tail_rules = tail_rules
t1.tail_refused = tail_refused

local function sphere_triangle_contacts_dense_w1(p164, p165, p166, p167, p168, p169, p170, p171, p172, p173, p174) -- line: 1785
    -- upvalues: fix_up_triangle (copy), pack (copy), v22 (copy), to_bits (copy), v42 (copy), v131 (copy), v132 (copy), v133 (copy), v134 (copy), t6 (copy), t7 (copy), face_memo (copy), v281 (copy), fround2 (copy), fix_up_toward (copy)
    local v632 = if p168 then 22 else 23
    local v633 = p164[v632]
    local v634, v635

    if v633 == false then
        v635 = p166[p167 + 1].triangle
        v634 = p165[p167 + 1]

        if v634 == nil then
            v634 = pack({
                tag = "Triangle",
                v635
            })
            p165[p167 + 1] = v634
        end

        v633 = face_memo(v634, p168)
        p164[v632] = v633
    end

    if v633 == 0 then
        return -1
    end

    local v636 = p164[4]

    v634 = p164[5]
    v635 = p164[6]

    if p168 then
        v636 = -v636
        v634 = -v634
        v635 = -v635
    end

    v632 = v633[31]

    local v637, v638, v639, v640, v641, v642, v643, v644, v645, v646, v647, v648, v649, v650

    if v632 == 3 then
        v647 = v633[1]
        v649 = v633[2]
        v640 = v633[3]
        v650 = v636 * (v647 - p170) + v634 * (v649 - p171) + v635 * (v640 - p172)
        v637 = v636 * v650 + p170
        v638 = v634 * v650 + p171
        v639 = v635 * v650 + p172
        v646 = v633[7] * (v637 - v647) + v633[8] * (v638 - v649) + v633[9] * (v639 - v640)

        local v651 = v633[17] * (v637 - v633[11]) + v633[18] * (v638 - v633[12]) + v633[19] * (v639 - v633[13])

        if v646 < v651 then
            v650 = 10
        else
            v651 = v646
            v650 = 0
        end

        v640 = v633[27] * (v637 - v633[21]) + v633[28] * (v638 - v633[22]) + v633[29] * (v639 - v633[23])

        if v651 < v640 then
            v650 = 20
        else
            v640 = v651
        end

        if v640 > 0 then
            v648 = v637 - v633[v650 + 7] * v640

            if not (v648 < 1.1754943508222875E-38) or not (v648 > -1.1754943508222875E-38) or v648 == 0 then
                buffer.writef32(v22, 0, v648)
            else
                buffer.writeu32(v22, 0, to_bits(v648))
            end

            v641 = buffer.readf32(v22, 0)
            v648 = v638 - v633[v650 + 8] * v640

            if v648 < 1.1754943508222875E-38 and v648 > -1.1754943508222875E-38 and v648 ~= 0 then
                buffer.writeu32(v22, 0, to_bits(v648))
            else
                buffer.writef32(v22, 0, v648)
            end

            local v652 = buffer.readf32(v22, 0)

            v642 = v639 - v633[v650 + 9] * v640

            if v642 < 1.1754943508222875E-38 and v642 > -1.1754943508222875E-38 and v642 ~= 0 then
                buffer.writeu32(v22, 0, to_bits(v642))
            else
                buffer.writef32(v22, 0, v642)
            end

            local v653 = buffer.readf32(v22, 0)

            v642 = v633[v650 + 1]
            v643 = v633[v650 + 2]
            v644 = v633[v650 + 3]

            local v654 = v633[v650 + 4]

            v645 = v633[v650 + 5]

            local v655 = v633[v650 + 6]
            local v656 = (v641 - v642) * v654 + (v652 - v643) * v645 + (v653 - v644) * v655

            if not (v656 < 0) then
                v648 = v633[v650 + 10]

                local v657

                if v648 < v656 then
                    v657 = v654 * v648 + v642

                    if not (v657 < 1.1754943508222875E-38) or not (v657 > -1.1754943508222875E-38) or v657 == 0 then
                        buffer.writef32(v22, 0, v657)
                    else
                        buffer.writeu32(v22, 0, to_bits(v657))
                    end

                    v642 = buffer.readf32(v22, 0)
                    v657 = v645 * v648 + v643

                    if v657 < 1.1754943508222875E-38 and v657 > -1.1754943508222875E-38 and v657 ~= 0 then
                        buffer.writeu32(v22, 0, to_bits(v657))
                    else
                        buffer.writef32(v22, 0, v657)
                    end

                    v643 = buffer.readf32(v22, 0)
                    v657 = v655 * v648 + v644
                else
                    v657 = v654 * v656 + v642

                    if v657 < 1.1754943508222875E-38 and v657 > -1.1754943508222875E-38 and v657 ~= 0 then
                        buffer.writeu32(v22, 0, to_bits(v657))
                    else
                        buffer.writef32(v22, 0, v657)
                    end

                    v642 = buffer.readf32(v22, 0)
                    v657 = v645 * v656 + v643

                    if v657 < 1.1754943508222875E-38 and v657 > -1.1754943508222875E-38 and v657 ~= 0 then
                        buffer.writeu32(v22, 0, to_bits(v657))
                    else
                        buffer.writef32(v22, 0, v657)
                    end

                    v643 = buffer.readf32(v22, 0)
                    v657 = v655 * v656 + v644
                end

                if v657 < 1.1754943508222875E-38 and v657 > -1.1754943508222875E-38 and v657 ~= 0 then
                    buffer.writeu32(v22, 0, to_bits(v657))
                else
                    buffer.writef32(v22, 0, v657)
                end

                v644 = buffer.readf32(v22, 0)
            end
        else
            if v637 < 1.1754943508222875E-38 and v637 > -1.1754943508222875E-38 and v637 ~= 0 then
                buffer.writeu32(v22, 0, to_bits(v637))
            else
                buffer.writef32(v22, 0, v637)
            end

            v642 = buffer.readf32(v22, 0)

            if v638 < 1.1754943508222875E-38 and v638 > -1.1754943508222875E-38 and v638 ~= 0 then
                buffer.writeu32(v22, 0, to_bits(v638))
            else
                buffer.writef32(v22, 0, v638)
            end

            v643 = buffer.readf32(v22, 0)

            if v639 < 1.1754943508222875E-38 and v639 > -1.1754943508222875E-38 and v639 ~= 0 then
                buffer.writeu32(v22, 0, to_bits(v639))
            else
                buffer.writef32(v22, 0, v639)
            end

            v644 = buffer.readf32(v22, 0)
        end
    elseif v632 == 1 then
        v642 = v633[1]
        v643 = v633[2]
        v644 = v633[3]
        v650 = v633[4]
        v637 = v633[5]
        v638 = v633[6]
        v639 = (p170 - v642) * v650 + (p171 - v643) * v637 + (p172 - v644) * v638

        if not (v639 < 0) then
            v646 = v633[10]

            if v646 < v639 then
                v648 = v650 * v646 + v642

                if not (v648 < 1.1754943508222875E-38) or not (v648 > -1.1754943508222875E-38) or v648 == 0 then
                    buffer.writef32(v22, 0, v648)
                else
                    buffer.writeu32(v22, 0, to_bits(v648))
                end

                v642 = buffer.readf32(v22, 0)
                v648 = v637 * v646 + v643

                if v648 < 1.1754943508222875E-38 and v648 > -1.1754943508222875E-38 and v648 ~= 0 then
                    buffer.writeu32(v22, 0, to_bits(v648))
                else
                    buffer.writef32(v22, 0, v648)
                end

                v643 = buffer.readf32(v22, 0)
                v648 = v638 * v646 + v644
            else
                v648 = v650 * v639 + v642

                if v648 < 1.1754943508222875E-38 and v648 > -1.1754943508222875E-38 and v648 ~= 0 then
                    buffer.writeu32(v22, 0, to_bits(v648))
                else
                    buffer.writef32(v22, 0, v648)
                end

                v642 = buffer.readf32(v22, 0)
                v648 = v637 * v639 + v643

                if v648 < 1.1754943508222875E-38 and v648 > -1.1754943508222875E-38 and v648 ~= 0 then
                    buffer.writeu32(v22, 0, to_bits(v648))
                else
                    buffer.writef32(v22, 0, v648)
                end

                v643 = buffer.readf32(v22, 0)
                v648 = v638 * v639 + v644
            end

            if v648 < 1.1754943508222875E-38 and v648 > -1.1754943508222875E-38 and v648 ~= 0 then
                buffer.writeu32(v22, 0, to_bits(v648))
            else
                buffer.writef32(v22, 0, v648)
            end

            v644 = buffer.readf32(v22, 0)
        end
    else
        v642 = v633[1]
        v643 = v633[2]
        v644 = v633[3]
    end

    v633 = v642 - p170
    v632 = v643 - p171
    v647 = v644 - p172
    v649 = fround2(v633 * v633 + v632 * v632 + v647 * v647)
    v640 = 1 / math.sqrt(v649)
    v640 = v640 * 0.5 * (-v649 * (v640 * v640) + 1) + v640
    v640 = v640 * 0.5 * (-v649 * (v640 * v640) + 1) + v640
    v650 = if v649 == 0 then 0 else v649 * v640

    if v281 < v650 then
        v646 = v633 * v640

        if v646 < 1.1754943508222875E-38 and v646 > -1.1754943508222875E-38 and v646 ~= 0 then
            buffer.writeu32(v22, 0, to_bits(v646))
        else
            buffer.writef32(v22, 0, v646)
        end

        v648 = buffer.readf32(v22, 0)
        v646 = v632 * v640

        if v646 < 1.1754943508222875E-38 and v646 > -1.1754943508222875E-38 and v646 ~= 0 then
            buffer.writeu32(v22, 0, to_bits(v646))
        else
            buffer.writef32(v22, 0, v646)
        end

        local v658 = buffer.readf32(v22, 0)

        v646 = v647 * v640

        if v646 < 1.1754943508222875E-38 and v646 > -1.1754943508222875E-38 and v646 ~= 0 then
            buffer.writeu32(v22, 0, to_bits(v646))
        else
            buffer.writef32(v22, 0, v646)
        end

        local v659 = buffer.readf32(v22, 0)

        v646 = p170 * v648 + p171 * v658 + p172 * v659

        if v646 < 1.1754943508222875E-38 and v646 > -1.1754943508222875E-38 and v646 ~= 0 then
            buffer.writeu32(v22, 0, to_bits(v646))
        else
            buffer.writef32(v22, 0, v646)
        end

        local v660 = buffer.readf32(v22, 0)

        v646 = p164[7] * v648 + p164[8] * v658 + p164[9] * v659

        local v661 = p164[10] * v648 + p164[11] * v658 + p164[12] * v659

        v641 = p164[13] * v648 + p164[14] * v658 + p164[15] * v659
        v645 = if v646 < v661 then v646 else v661

        if not (v661 < v646) then
            v646 = v661
        end

        if not (v641 < v646) then
            v646 = v641
        end

        if v646 < 1.1754943508222875E-38 and v646 > -1.1754943508222875E-38 and v646 ~= 0 then
            buffer.writeu32(v22, 0, to_bits(v646))
        else
            buffer.writef32(v22, 0, v646)
        end

        v661 = v660 - buffer.readf32(v22, 0)

        if not (v645 < v641) then
            v645 = v641
        end

        if v645 < 1.1754943508222875E-38 and v645 > -1.1754943508222875E-38 and v645 ~= 0 then
            buffer.writeu32(v22, 0, to_bits(v645))
        else
            buffer.writef32(v22, 0, v645)
        end

        local v662 = buffer.readf32(v22, 0) - v660

        if v662 < v661 then
            if p169 <= v661 then
                v636 = -v648
                v634 = -v658
                v635 = -v659
            end
        elseif p169 <= v662 then
            v635 = v659
            v636 = v648
            v634 = v658
        end
    end

    v647 = fix_up_toward(p164, -v636, -v634, -v635, p174)

    if v647 == 0 then
        return nil
    end

    v649 = p164[16]

    if v647 == 1 then
        v42[1] = p170 + v636 * p173
        v42[2] = p171 + v634 * p173
        v42[3] = p172 + v635 * p173
        v42[4] = v642 - v636 * v649
        v42[5] = v643 - v634 * v649
        v42[6] = v644 - v635 * v649

        return 1, -v636, -v634, -v635
    end

    v647 = v133[1]
    v640 = v131[1]
    v650 = v132[1]
    v640.x = p170
    v640.y = p171
    v640.z = p172
    v650.x = v642
    v650.y = v643
    v650.z = v644
    v647.a = v640
    v647.b = v650
    t6.x = v636
    t6.y = v634
    t6.z = v635
    t7.edge_cos_bend_normal_threshold = p174.edge_cos_bend_normal_threshold
    t7.convexity_epsilon = p174.convexity_epsilon
    t7.is_object = p174.is_object

    if not fix_up_triangle(p166[p167 + 1].triangle.feature, t6, v134[2], t7) then
        return nil
    end

    v637 = t6.x
    v638 = t6.y
    v639 = t6.z
    v640 = v647.a
    v650 = v647.b
    v42[1] = v640.x + v637 * p173
    v42[2] = v640.y + v638 * p173
    v42[3] = v640.z + v639 * p173
    v42[4] = v650.x - v637 * v649
    v42[5] = v650.y - v638 * v649
    v42[6] = v650.z - v639 * v649

    return 1, -v637, -v638, -v639
end

t1.sphere_triangle_contacts_dense_w1 = sphere_triangle_contacts_dense_w1

function t1.sphere_triangle_contacts_dense(p175, p176, p177, p178, p179, p180, p181, p182, p183, p184, p185) -- line: 1935
    -- upvalues: fix_up_triangle (copy), pack (copy), v22 (copy), v42 (copy), v131 (copy), v132 (copy), v133 (copy), v134 (copy), t6 (copy), t7 (copy), face_memo (copy), v281 (copy), fround2 (copy), v361 (ref), round3 (copy), fix_up_toward (copy), v541 (ref), v542 (ref), tail_class (copy), tail_refused (copy), sphere_triangle_contacts_dense_w1 (copy)
    if v361 then
        return sphere_triangle_contacts_dense_w1(p175, p176, p177, p178, p179, p180, p181, p182, p183, p184, p185)
    end

    local v663 = if p179 then 22 else 23
    local v664 = p175[v663]
    local v665

    if v664 == false then
        local triangle = p177[p178 + 1].triangle
        local v666 = p176[p178 + 1]

        if v666 == nil then
            v666 = pack({
                tag = "Triangle",
                triangle
            })
            p176[p178 + 1] = v666
        end

        v665 = face_memo(v666, p179)
        p175[v663] = v665
    else
        v665 = v664
    end

    if v665 == 0 then
        return -1
    end

    local v667 = p175[4]
    local v668 = p175[5]
    local v669 = p175[6]

    if p179 then
        v667 = -v667
        v668 = -v668
        v669 = -v669
    end

    local v670

    if v541 then
        v670 = v665[32]

        if v670 == nil then
            v670 = tail_class(p175, v665)
        end
    end

    local v671 = v670 ~= nil
    local v672 = v665[31]
    local v673, v674, v675

    if v672 == 3 then
        local v676 = v665[1]
        local v677 = v665[2]
        local v678 = v665[3]
        local v679 = v667 * (v676 - p181) + v668 * (v677 - p182) + v669 * (v678 - p183)
        local v680 = v667 * v679 + p181
        local v681 = v668 * v679 + p182
        local v682 = v669 * v679 + p183
        local v683 = v665[7] * (v680 - v676) + v665[8] * (v681 - v677) + v665[9] * (v682 - v678)
        local v684 = v665[17] * (v680 - v665[11]) + v665[18] * (v681 - v665[12]) + v665[19] * (v682 - v665[13])
        local n14 = 0

        if v683 < v684 then
            n14 = 10
        else
            v684 = v683
        end

        local v685 = v665[27] * (v680 - v665[21]) + v665[28] * (v681 - v665[22]) + v665[29] * (v682 - v665[23])

        if v684 < v685 then
            n14 = 20
        else
            v685 = v684
        end

        if v685 > 0 then
            local v686, v687, v688 = round3(v680 - v665[n14 + 7] * v685, v681 - v665[n14 + 8] * v685, v682 - v665[n14 + 9] * v685)

            v673 = v665[n14 + 1]
            v674 = v665[n14 + 2]
            v675 = v665[n14 + 3]

            local v689 = v665[n14 + 4]
            local v690 = v665[n14 + 5]
            local v691 = v665[n14 + 6]
            local v692 = (v686 - v673) * v689 + (v687 - v674) * v690 + (v688 - v675) * v691

            if not (v692 < 0) then
                local v693 = v665[n14 + 10]

                if v693 < v692 then
                    if v670 ~= nil then
                        local v694 = n14 * 0.3 + 37

                        v673 = v670[v694]
                        v674 = v670[v694 + 1]
                        v675 = v670[v694 + 2]
                    else
                        v673, v674, v675 = round3(v689 * v693 + v673, v690 * v693 + v674, v691 * v693 + v675)
                    end
                else
                    v673, v674, v675 = round3(v689 * v692 + v673, v690 * v692 + v674, v691 * v692 + v675)
                end
            end
        else
            v673, v674, v675 = round3(v680, v681, v682)
            v671 = false
        end
    elseif v672 == 1 then
        v673 = v665[1]
        v674 = v665[2]
        v675 = v665[3]

        local v695 = v665[4]
        local v696 = v665[5]
        local v697 = v665[6]
        local v698 = (p181 - v673) * v695 + (p182 - v674) * v696 + (p183 - v675) * v697

        if not (v698 < 0) then
            local v699 = v665[10]

            if v699 < v698 then
                if v670 ~= nil then
                    v673 = v670[37]
                    v674 = v670[38]
                    v675 = v670[39]
                else
                    v673, v674, v675 = round3(v695 * v699 + v673, v696 * v699 + v674, v697 * v699 + v675)
                end
            else
                v673, v674, v675 = round3(v695 * v698 + v673, v696 * v698 + v674, v697 * v698 + v675)
            end
        end
    else
        v673 = v665[1]
        v674 = v665[2]
        v675 = v665[3]
    end

    local v700 = v673 - p181
    local v701 = v674 - p182
    local v702 = v675 - p183
    local v703 = v700 * v700 + v701 * v701 + v702 * v702

    if v671 then
        if tail_refused(p175, v670, p185, p181, p182, p183, v700, v701, v702, v703, p180) then
            if v542 then
                v542.refused = (v542.refused or 0) + 1
            end

            return nil
        end

        if v542 then
            v542.passed = (v542.passed or 0) + 1
        end
    end

    local v706

    if v703 ~= 0 and v703 > -1.1754943508222875E-38 and v703 < 1.1754943508222875E-38 then
        v706 = fround2(v703)
    else
        buffer.writef32(v22, 0, v703)
        v706 = buffer.readf32(v22, 0)
    end

    local v707 = 1 / math.sqrt(v706)
    local v708 = v707 * 0.5 * (-v706 * (v707 * v707) + 1) + v707
    local v709 = v708 * 0.5 * (-v706 * (v708 * v708) + 1) + v708
    local v710 = if v706 == 0 then 0 else v706 * v709
    local v711 = v667
    local v712 = v668
    local v713 = v669

    if v281 < v710 then
        local v714, v715, v716 = round3(v700 * v709, v701 * v709, v702 * v709)
        local v717 = p175[7] * v714 + p175[8] * v715 + p175[9] * v716
        local v718 = p175[10] * v714 + p175[11] * v715 + p175[12] * v716
        local v719 = p175[13] * v714 + p175[14] * v715 + p175[15] * v716
        local v720 = if v717 < v718 then v717 else v718

        if not (v718 < v717) then
            v717 = v718
        end

        local v721 = p181 * v714 + p182 * v715 + p183 * v716

        if not (v719 < v717) then
            v717 = v719
        end

        if not (v720 < v719) then
            v720 = v719
        end

        local v722, v723, v724 = round3(v721, v717, v720)
        local v725 = v722 - v723
        local v726 = v724 - v722

        if v726 < v725 then
            if p180 <= v725 then
                v711 = -v714
                v712 = -v715
                v713 = -v716
            end
        elseif p180 <= v726 then
            v713 = v716
            v711 = v714
            v712 = v715
        end
    end

    local v727 = fix_up_toward(p175, -v711, -v712, -v713, p185)

    if v727 == 0 then
        return nil
    end

    local v728 = p175[16]

    if v727 == 1 then
        v42[1] = p181 + v711 * p184
        v42[2] = p182 + v712 * p184
        v42[3] = p183 + v713 * p184
        v42[4] = v673 - v711 * v728
        v42[5] = v674 - v712 * v728
        v42[6] = v675 - v713 * v728

        return 1, -v711, -v712, -v713
    end

    local v729 = v133[1]
    local v730 = v131[1]
    local v731 = v132[1]

    v730.x = p181
    v730.y = p182
    v730.z = p183
    v731.x = v673
    v731.y = v674
    v731.z = v675
    v729.a = v730
    v729.b = v731
    t6.x = v711
    t6.y = v712
    t6.z = v713
    t7.edge_cos_bend_normal_threshold = p185.edge_cos_bend_normal_threshold
    t7.convexity_epsilon = p185.convexity_epsilon
    t7.is_object = p185.is_object

    if not fix_up_triangle(p177[p178 + 1].triangle.feature, t6, v134[2], t7) then
        return nil
    end

    local x, y, z = t6.x, t6.y, t6.z
    local a, b = v729.a, v729.b

    v42[1] = a.x + x * p184
    v42[2] = a.y + y * p184
    v42[3] = a.z + z * p184
    v42[4] = b.x - x * v728
    v42[5] = b.y - y * v728
    v42[6] = b.z - z * v728

    return 1, -x, -y, -z
end

local function capsule_floats(p186, p187, p188, p189) -- line: 2128
    -- upvalues: v22 (copy), to_bits (copy), v315 (copy), fround2 (copy)
    local v732 = p186[4]
    local v733 = p186[1] * v732
    local v734 = p186[2] * v732
    local v735 = p186[3] * v732
    local v736 = p187 + v733

    if v736 < 1.1754943508222875E-38 and v736 > -1.1754943508222875E-38 and v736 ~= 0 then
        buffer.writeu32(v22, 0, to_bits(v736))
    else
        buffer.writef32(v22, 0, v736)
    end

    local v737 = buffer.readf32(v22, 0)
    local v738 = p188 + v734

    if v738 < 1.1754943508222875E-38 and v738 > -1.1754943508222875E-38 and v738 ~= 0 then
        buffer.writeu32(v22, 0, to_bits(v738))
    else
        buffer.writef32(v22, 0, v738)
    end

    local v739 = buffer.readf32(v22, 0)
    local v740 = p189 + v735

    if v740 < 1.1754943508222875E-38 and v740 > -1.1754943508222875E-38 and v740 ~= 0 then
        buffer.writeu32(v22, 0, to_bits(v740))
    else
        buffer.writef32(v22, 0, v740)
    end

    local v741 = buffer.readf32(v22, 0)
    local v742 = p187 - v733

    if v742 < 1.1754943508222875E-38 and v742 > -1.1754943508222875E-38 and v742 ~= 0 then
        buffer.writeu32(v22, 0, to_bits(v742))
    else
        buffer.writef32(v22, 0, v742)
    end

    local v743 = buffer.readf32(v22, 0)
    local v744 = p188 - v734

    if v744 < 1.1754943508222875E-38 and v744 > -1.1754943508222875E-38 and v744 ~= 0 then
        buffer.writeu32(v22, 0, to_bits(v744))
    else
        buffer.writef32(v22, 0, v744)
    end

    local v745 = buffer.readf32(v22, 0)
    local v746 = p189 - v735

    if v746 < 1.1754943508222875E-38 and v746 > -1.1754943508222875E-38 and v746 ~= 0 then
        buffer.writeu32(v22, 0, to_bits(v746))
    else
        buffer.writef32(v22, 0, v746)
    end

    local v747 = buffer.readf32(v22, 0)
    local v748 = v743 - v737
    local v749 = v745 - v739
    local v750 = v747 - v741
    local v751 = fround2(v748 * v748 + v749 * v749 + v750 * v750)
    local v752 = 1 / math.sqrt(v751)
    local v753 = v752 * 0.5 * (-v751 * (v752 * v752) + 1) + v752
    local v754 = if not (v315 < v751) then 0 elseif v751 == 0 then 0 else v751 * v753
    local v755 = 1 / v754
    local v756 = v755 * (-v755 * v754 + 1) + v755

    if v315 < v751 then
        local v757 = v748 * v756

        if not (v757 < 1.1754943508222875E-38) or not (v757 > -1.1754943508222875E-38) or v757 == 0 then
            buffer.writef32(v22, 0, v757)
        else
            buffer.writeu32(v22, 0, to_bits(v757))
        end

        local v758 = buffer.readf32(v22, 0)
        local v759 = v749 * v756

        if v759 < 1.1754943508222875E-38 and v759 > -1.1754943508222875E-38 and v759 ~= 0 then
            buffer.writeu32(v22, 0, to_bits(v759))
        else
            buffer.writef32(v22, 0, v759)
        end

        local v760 = buffer.readf32(v22, 0)
        local v761 = v750 * v756

        if v761 < 1.1754943508222875E-38 and v761 > -1.1754943508222875E-38 and v761 ~= 0 then
            buffer.writeu32(v22, 0, to_bits(v761))
        else
            buffer.writef32(v22, 0, v761)
        end

        local v762 = buffer.readf32(v22, 0)

        p186[8] = v758
        p186[9] = v760
        p186[10] = v762
    else
        p186[8] = 0
        p186[9] = 0
        p186[10] = 0
    end

    p186[5] = v737
    p186[6] = v739
    p186[7] = v741

    if v754 < 1.1754943508222875E-38 and v754 > -1.1754943508222875E-38 and v754 ~= 0 then
        buffer.writeu32(v22, 0, to_bits(v754))
    else
        buffer.writef32(v22, 0, v754)
    end

    p186[11] = buffer.readf32(v22, 0)
    p186[13] = v743
    p186[14] = v745
    p186[15] = v747
    p186[12] = 1
end

t1.capsule_floats = capsule_floats

local function direction_words(p190, p191, p192, p193, p194, p195, p196) -- line: 2166
    -- upvalues: v22 (copy), to_bits (copy), t2 (copy)
    if p190 == 0 then
        if p191 then
            t2[1] = bit32.bxor(p192[p193 + 1], 2147483648)
            t2[2] = bit32.bxor(p192[p193 + 2], 2147483648)
            t2[3] = bit32.bxor(p192[p193 + 3], 2147483648)
            t2[4] = bit32.bxor(p192[p193 + 4], 2147483648)
        else
            local v767 = p192[p193 + 1]
            local v768 = p192[p193 + 2]
            local v769 = p192[p193 + 3]
            local v770 = p192[p193 + 4]

            t2[1] = v767
            t2[2] = v768
            t2[3] = v769
            t2[4] = v770
        end
    elseif p191 then
        local v771

        if p194 ~= 0 and p194 > -1.1754943508222875E-38 and p194 < 1.1754943508222875E-38 then
            v771 = to_bits(p194)
        else
            buffer.writef32(v22, 0, p194)
            v771 = buffer.readu32(v22, 0)
        end

        t2[1] = bit32.bxor(v771, 2147483648)

        local v772

        if p195 ~= 0 and p195 > -1.1754943508222875E-38 and p195 < 1.1754943508222875E-38 then
            v772 = to_bits(p195)
        else
            buffer.writef32(v22, 0, p195)
            v772 = buffer.readu32(v22, 0)
        end

        t2[2] = bit32.bxor(v772, 2147483648)

        local v773

        if p196 ~= 0 and p196 > -1.1754943508222875E-38 and p196 < 1.1754943508222875E-38 then
            v773 = to_bits(p196)
        else
            buffer.writef32(v22, 0, p196)
            v773 = buffer.readu32(v22, 0)
        end

        t2[3] = bit32.bxor(v773, 2147483648)
        t2[4] = 2147483648
    else
        local v774

        if p194 ~= 0 and p194 > -1.1754943508222875E-38 and p194 < 1.1754943508222875E-38 then
            v774 = to_bits(p194)
        else
            buffer.writef32(v22, 0, p194)
            v774 = buffer.readu32(v22, 0)
        end

        local v775

        if p195 ~= 0 and p195 > -1.1754943508222875E-38 and p195 < 1.1754943508222875E-38 then
            v775 = to_bits(p195)
        else
            buffer.writef32(v22, 0, p195)
            v775 = buffer.readu32(v22, 0)
        end

        local v776

        if p196 ~= 0 and p196 > -1.1754943508222875E-38 and p196 < 1.1754943508222875E-38 then
            v776 = to_bits(p196)
        else
            buffer.writef32(v22, 0, p196)
            v776 = buffer.readu32(v22, 0)
        end

        t2[1] = v774
        t2[2] = v775
        t2[3] = v776
        t2[4] = 0
    end

    return t2
end

local v777 = true

function t1.set_capsule_edges(p197) -- line: 2221
    -- upvalues: v777 (ref)
    local v778 = v777

    v777 = p197

    return v778
end

buffer.writeu32(v22, 0, 1028443341)

local v779 = buffer.readf32(v22, 0)

local function capsule_edge_pair(p198, p199, p200, p201, p202, p203, p204, p205) -- line: 2227
    -- upvalues: pack (copy), v22 (copy), v315 (copy), round3 (copy), closest_segment_v (copy), v779 (copy)
    local v780 = p203 * p198[7] + p204 * p198[8] + p205 * p198[9]
    local v781 = p203 * p198[10] + p204 * p198[11] + p205 * p198[12]
    local v782 = p203 * p198[13] + p204 * p198[14] + p205 * p198[15]
    local v784 = math.abs(p203 * p198[24] + p204 * p198[25] + p205 * p198[26])
    local v786 = math.abs(p203 * p198[27] + p204 * p198[28] + p205 * p198[29])
    local v788 = math.abs(p203 * p198[30] + p204 * p198[31] + p205 * p198[32])
    local v789, v790

    if v781 < v780 and v782 < v780 then
        v789 = if v784 < v779 and v784 < v788 then 0 elseif v788 < v779 then 2 else -1
        v790 = 0
    elseif v782 < v781 then
        v789 = if v786 < v779 and v786 < v788 then 1 elseif v788 < v779 then 2 else -1
        v790 = 1
    else
        v789 = if v784 < v779 and v784 < v786 then 0 elseif v786 < v779 then 1 else -1
        v790 = 2
    end

    local v791 = p202[5]
    local v792 = p202[6]
    local v793 = p202[7]
    local v794 = p202[8]
    local v795 = p202[9]
    local v796 = p202[10]
    local v797 = p202[11]

    if v789 < 0 then
        local v798 = if v790 == 0 then 7 elseif v790 == 1 then 10 else 13
        local v799 = p198[v798]
        local v800 = p198[v798 + 1]
        local v801 = p198[v798 + 2]
        local v802, v803, v804 = closest_segment_v(v799, v800, v801, v791, v792, v793, v794, v795, v796, v797)

        return true, v802, v803, v804, v799, v800, v801
    end

    local v805 = if v789 == 0 then 7 elseif v789 == 1 then 13 else 10
    local v806 = p198[v805]
    local v807 = p198[v805 + 1]
    local v808 = p198[v805 + 2]
    local v809 = 24 + 3 * v789
    local v810 = p198[v809]
    local v811 = p198[v809 + 1]
    local v812 = p198[v809 + 2]
    local v813 = -v796 * v811 + v795 * v812
    local v814 = -v794 * v812 + v796 * v810
    local v815 = -v795 * v810 + v794 * v811
    local v816 = v813 * v813 + v814 * v814 + v815 * v815

    if not (v315 < v816) then
        return false, 0, 0, 0, 0, 0, 0
    end

    local v817 = 1 / math.sqrt(v816)
    local v818 = v817 * 0.5 * (-v816 * (v817 * v817) + 1) + v817
    local v819 = v818 * 0.5 * (-v816 * (v818 * v818) + 1) + v818
    local v820 = v813 * v819
    local v821 = v814 * v819
    local v822 = v815 * v819
    local v823 = -v822 * v811 + v821 * v812
    local v824 = -v820 * v812 + v822 * v810
    local v825 = -v821 * v810 + v820 * v811
    local v826 = ((v806 - v791) * v823 + (v807 - v792) * v824 + (v808 - v793) * v825) / (v794 * v823 + v795 * v824 + v796 * v825)

    if v826 < 0 then
        v826 = 0
    end

    if v797 < v826 then
        v826 = v797
    end

    local v827, v828, v829 = round3(v794 * v826 + v791, v795 * v826 + v792, v796 * v826 + v793)
    local triangle = p200[p201 + 1].triangle
    local v830 = p199[p201 + 1]

    if v830 == nil then
        v830 = pack({
            tag = "Triangle",
            triangle
        })
        p199[p201 + 1] = v830
    end

    buffer.writeu32(v22, 0, v830[29 + v789])

    local v833, v834, v835 = closest_segment_v(v827, v828, v829, v806, v807, v808, v810, v811, v812, (buffer.readf32(v22, 0)))
    local v836, v837, v838 = closest_segment_v(v833, v834, v835, v791, v792, v793, v794, v795, v796, v797)

    return true, v836, v837, v838, v833, v834, v835
end

local function capsule_triangle_contacts_flat_w1(p206, p207, p208, p209, p210, p211, p212, p213, p214, p215, p216, p217, p218, p219, p220) -- line: 2334
    -- upvalues: fix_up_triangle (copy), pack (copy), v22 (copy), to_bits (copy), contact_points_flat (ref), v42 (copy), v131 (copy), v132 (copy), v133 (copy), v134 (copy), t6 (copy), t7 (copy), face_memo (copy), v281 (copy), v312 (copy), v313 (copy), v314 (copy), v317 (copy), v318 (copy), F32_MIN_POSITIVE (copy), closest_segment_xyz (copy), t10 (copy), t11 (copy), t12 (copy), t13 (copy), fround2 (copy), edge_plane (copy), clamp_to_face (copy), fix_up_toward (copy), capsule_floats (copy), direction_words (copy)
    local v839 = p211[1]
    local v840 = p211[2]
    local v841 = p211[3]
    local v842 = p211[4]
    local v843 = p206[4]
    local v844 = p206[5]
    local v845 = p206[6]
    local v846 = p212
    local n15 = 0
    local v847 = p213
    local v848 = v843
    local v849 = v844
    local v850 = v845
    local v851, v852, v853, v854, v855, v856, v857, v858, v859

    for i = 24, 30, 3 do
        local v860 = p206[i]

        v852 = p206[i + 1]
        v855 = p206[i + 2]

        local v861 = -v841 * v852 + v840 * v855

        v851 = -v839 * v855 + v841 * v860
        v855 = -v840 * v860 + v839 * v852
        v852 = v861 * v861 + v851 * v851 + v855 * v855

        local v862, v863

        if v312 < v852 then
            v853 = 1 / math.sqrt(v852)
            v853 = v853 * 0.5 * (-v852 * (v853 * v853) + 1) + v853
            v853 = v853 * 0.5 * (-v852 * (v853 * v853) + 1) + v853
            v854 = v861 * v853

            if not (v854 < 1.1754943508222875E-38) or not (v854 > -1.1754943508222875E-38) or v854 == 0 then
                buffer.writef32(v22, 0, v854)
            else
                buffer.writeu32(v22, 0, to_bits(v854))
            end

            local v864 = buffer.readf32(v22, 0)

            v854 = v851 * v853

            if v854 < 1.1754943508222875E-38 and v854 > -1.1754943508222875E-38 and v854 ~= 0 then
                buffer.writeu32(v22, 0, to_bits(v854))
            else
                buffer.writef32(v22, 0, v854)
            end

            local v865 = buffer.readf32(v22, 0)

            v854 = v855 * v853

            if v854 < 1.1754943508222875E-38 and v854 > -1.1754943508222875E-38 and v854 ~= 0 then
                buffer.writeu32(v22, 0, to_bits(v854))
            else
                buffer.writef32(v22, 0, v854)
            end

            local v866 = buffer.readf32(v22, 0)

            v860 = p214 * v864 + p215 * v865 + p216 * v866
            v854 = math.abs(v839 * v864 + v840 * v865 + v841 * v866) * v842

            local v868 = p206[7] * v864 + p206[8] * v865 + p206[9] * v866
            local v867 = p206[10] * v864 + p206[11] * v865 + p206[12] * v866
            local v869 = p206[13] * v864 + p206[14] * v865 + p206[15] * v866
            local v870 = if v868 < v867 then v868 else v867

            if not (v867 < v868) then
                v868 = v867
            end

            local v871 = v860 - v854

            if v871 < 1.1754943508222875E-38 and v871 > -1.1754943508222875E-38 and v871 ~= 0 then
                buffer.writeu32(v22, 0, to_bits(v871))
            else
                buffer.writef32(v22, 0, v871)
            end

            local v872 = buffer.readf32(v22, 0)

            if not (v869 < v868) then
                v868 = v869
            end

            if v868 < 1.1754943508222875E-38 and v868 > -1.1754943508222875E-38 and v868 ~= 0 then
                buffer.writeu32(v22, 0, to_bits(v868))
            else
                buffer.writef32(v22, 0, v868)
            end

            v867 = v872 - buffer.readf32(v22, 0)

            if not (v870 < v869) then
                v870 = v869
            end

            if v870 < 1.1754943508222875E-38 and v870 > -1.1754943508222875E-38 and v870 ~= 0 then
                buffer.writeu32(v22, 0, to_bits(v870))
            else
                buffer.writef32(v22, 0, v870)
            end

            v872 = buffer.readf32(v22, 0)

            local v873 = v860 + v854

            if v873 < 1.1754943508222875E-38 and v873 > -1.1754943508222875E-38 and v873 ~= 0 then
                buffer.writeu32(v22, 0, to_bits(v873))
            else
                buffer.writef32(v22, 0, v873)
            end

            local v874 = v872 - buffer.readf32(v22, 0)

            if v874 < v867 then
                if v846 < v867 then
                    if not (v867 < 1.1754943508222875E-38) or not (v867 > -1.1754943508222875E-38) or v867 == 0 then
                        buffer.writef32(v22, 0, v867)
                    else
                        buffer.writeu32(v22, 0, to_bits(v867))
                    end

                    if p218 < buffer.readf32(v22, 0) then
                        return nil
                    end

                    v858 = v866
                    v859 = v867
                    v863 = i
                    v862 = true
                    v856 = v864
                    v857 = v865
                else
                    v858 = v850
                    v859 = v846
                    v863 = n15
                    v862 = v847
                    v856 = v848
                    v857 = v849
                end
            elseif v846 < v874 then
                if not (v874 < 1.1754943508222875E-38) or not (v874 > -1.1754943508222875E-38) or v874 == 0 then
                    buffer.writef32(v22, 0, v874)
                else
                    buffer.writeu32(v22, 0, to_bits(v874))
                end

                if p218 < buffer.readf32(v22, 0) then
                    return nil
                end

                v858 = v866
                v859 = v874
                v863 = i
                v862 = false
                v856 = v864
                v857 = v865
            else
                v858 = v850
                v859 = v846
                v863 = n15
                v862 = v847
                v856 = v848
                v857 = v849
            end
        else
            v858 = v850
            v859 = v846
            v863 = n15
            v862 = v847
            v856 = v848
            v857 = v849
        end

        v850 = v858
        v846 = v859
        n15 = v863
        v847 = v862
        v848 = v856
        v849 = v857
    end

    if v847 then
        v856 = -v848
        v857 = -v849
        v858 = -v850
    else
        v858 = v850
        v856 = v848
        v857 = v849
    end

    if v846 < 1.1754943508222875E-38 and v846 > -1.1754943508222875E-38 and v846 ~= 0 then
        buffer.writeu32(v22, 0, to_bits(v846))
    else
        buffer.writef32(v22, 0, v846)
    end

    v855 = buffer.readf32(v22, 0)
    v859 = v839 * v856 + v840 * v857 + v841 * v858
    v852 = -v856 * v843 + -v857 * v844 + -v858 * v845

    local v875 = math.abs(v859) < v313
    local v876, v877

    if math.abs(v852) > v314 and (v875 or n15 == 0) then
        v851 = not (v852 < 0)
        v876 = if v851 then 22 else 23
        v877 = p206[v876]

        local v878

        if v877 == false then
            v854 = p208[p209 + 1].triangle

            local v879 = p207[p209 + 1]

            if v879 == nil then
                v879 = pack({
                    tag = "Triangle",
                    v854
                })
                p207[p209 + 1] = v879
            end

            v878 = face_memo(v879, v851)
            p206[v876] = v878
        else
            v878 = v877
        end

        v877 = if v878 == 0 or v878[31] ~= 3 then nil else v878
    end

    if v877 == nil then
        v852 = p208[p209 + 1].triangle
        v851 = p207[p209 + 1]

        if v851 == nil then
            v851 = pack({
                tag = "Triangle",
                v852
            })
            p207[p209 + 1] = v851
        end

        return contact_points_flat(p210, "Capsule", v851, "Triangle", v852, v855, direction_words(n15, v847, v851, 4, v848, v849, v850), p219, p220)
    end

    if p211[12] ~= 1 then
        capsule_floats(p211, p214, p215, p216)
    end

    local v880, v881, v882, v883, v884, v885, v886, v887, v888, v889, v890, v891, v892, v893, v894, v895, v896, v897, v898, v899, v900, v901, v902, v903, v904, v905, v906, v907, v908

    if v875 then
        v880 = p211[5]
        v881 = p211[6]
        v882 = p211[7]
        v883 = p211[8]
        v884 = p211[9]
        v885 = p211[10]
        edge_plane(1, v856, v857, v858, v877[4], v877[5], v877[6])
        edge_plane(2, v856, v857, v858, v877[14], v877[15], v877[16])
        edge_plane(3, v856, v857, v858, v877[24], v877[25], v877[26])

        local v909 = false
        local v910 = 0
        local v911 = p211[11]
        local v912 = 0
        local v913 = 0
        local v914 = 0
        local v915 = 0
        local v916 = 0
        local v917 = 0

        v847 = false

        local v918

        for i = 1, 3 do
            local v919, v920, v921, v922, v923, v924, v925

            if t13[i] then
                local v926 = t10[i]
                local v927 = t11[i]
                local v928 = t12[i]

                n15 = (i - 1) * 10

                local v929 = v883 * v926 + v884 * v927 + v885 * v928

                v918 = (v877[n15 + 1] - v880) * v926 + (v877[n15 + 2] - v881) * v927 + (v877[n15 + 3] - v882) * v928

                if math.abs(v929) < v317 then
                    v921 = v910
                    v904 = v911

                    if v918 > 0 then
                        v886 = v877[n15 + 1]
                        v887 = v877[n15 + 2]

                        local v930 = v877[n15 + 3]

                        if not (v926 < 1.1754943508222875E-38) or not (v926 > -1.1754943508222875E-38) or v926 == 0 then
                            buffer.writef32(v22, 0, v926)
                        else
                            buffer.writeu32(v22, 0, to_bits(v926))
                        end

                        v919 = buffer.readf32(v22, 0)

                        if v927 < 1.1754943508222875E-38 and v927 > -1.1754943508222875E-38 and v927 ~= 0 then
                            buffer.writeu32(v22, 0, to_bits(v927))
                        else
                            buffer.writef32(v22, 0, v927)
                        end

                        v920 = buffer.readf32(v22, 0)

                        if v928 < 1.1754943508222875E-38 and v928 > -1.1754943508222875E-38 and v928 ~= 0 then
                            buffer.writeu32(v22, 0, to_bits(v928))
                        else
                            buffer.writef32(v22, 0, v928)
                        end

                        v922 = true
                        v905 = v886
                        v923 = v887
                        v924 = v930
                        v925 = buffer.readf32(v22, 0)
                    else
                        v925 = v917
                        v922 = v909
                        v905 = v912
                        v923 = v913
                        v924 = v914
                        v919 = v915
                        v920 = v916
                    end
                else
                    v919 = v918 / v929

                    if v929 > 0 then
                        if v910 < v919 then
                            if not (v919 < 1.1754943508222875E-38) or not (v919 > -1.1754943508222875E-38) or v919 == 0 then
                                buffer.writef32(v22, 0, v919)
                            else
                                buffer.writeu32(v22, 0, to_bits(v919))
                            end

                            v888 = buffer.readf32(v22, 0)
                        else
                            v888 = v910
                        end

                        if v911 < v888 then
                            v847 = true
                            v910 = v911
                            break
                        end

                        v904 = v911
                        v921 = v888
                    else
                        if v919 < v911 then
                            if not (v919 < 1.1754943508222875E-38) or not (v919 > -1.1754943508222875E-38) or v919 == 0 then
                                buffer.writef32(v22, 0, v919)
                            else
                                buffer.writeu32(v22, 0, to_bits(v919))
                            end

                            v889 = buffer.readf32(v22, 0)
                        else
                            v889 = v911
                        end

                        if v889 < v910 then
                            v847 = true
                            v911 = v910
                            break
                        end

                        v904 = v889
                        v921 = v910
                    end

                    v925 = v917
                    v922 = v909
                    v905 = v912
                    v923 = v913
                    v924 = v914
                    v919 = v915
                    v920 = v916
                end
            else
                v925 = v917
                v922 = v909
                v921 = v910
                v904 = v911
                v905 = v912
                v923 = v913
                v924 = v914
                v919 = v915
                v920 = v916
            end

            v909 = v922
            v910 = v921
            v911 = v904
            v912 = v905
            v913 = v923
            v914 = v924
            v915 = v919
            v916 = v920
            v917 = v925
            v847 = false
        end

        local v931 = v877[1]
        local v932 = v877[2]
        local v933 = v877[3]

        if v847 or v909 then
            local v934 = v911 - v910

            if v318 < v934 then
                local v935 = v856 * (v931 - v880) + v857 * (v932 - v881) + v858 * (v933 - v882)
                local v936 = v856 * v935 + v880
                local v937 = v857 * v935 + v881

                v918 = v858 * v935 + v882
                v935 = v915 * (v912 - v936) + v916 * (v913 - v937) + v917 * (v914 - v918)
                v936 = v915 * v935 + v936
                v937 = v916 * v935 + v937
                v918 = v917 * v935 + v918

                local v938 = v883 * v910 + v936
                local v939 = v884 * v910 + v937
                local v940 = v885 * v910 + v918

                if not (v938 < 1.1754943508222875E-38) or not (v938 > -1.1754943508222875E-38) or v938 == 0 then
                    buffer.writef32(v22, 0, v938)
                else
                    buffer.writeu32(v22, 0, to_bits(v938))
                end

                local v941 = buffer.readf32(v22, 0)

                if v939 < 1.1754943508222875E-38 and v939 > -1.1754943508222875E-38 and v939 ~= 0 then
                    buffer.writeu32(v22, 0, to_bits(v939))
                else
                    buffer.writef32(v22, 0, v939)
                end

                local v942 = buffer.readf32(v22, 0)

                if v940 < 1.1754943508222875E-38 and v940 > -1.1754943508222875E-38 and v940 ~= 0 then
                    buffer.writeu32(v22, 0, to_bits(v940))
                else
                    buffer.writef32(v22, 0, v940)
                end

                local v943

                v943, v941, v942 = clamp_to_face(v941, v942, buffer.readf32(v22, 0), v877)

                local v944 = v883 * v934 + v938

                if v944 < 1.1754943508222875E-38 and v944 > -1.1754943508222875E-38 and v944 ~= 0 then
                    buffer.writeu32(v22, 0, to_bits(v944))
                else
                    buffer.writef32(v22, 0, v944)
                end

                local v945 = buffer.readf32(v22, 0)
                local v946 = v884 * v934 + v939

                if v946 < 1.1754943508222875E-38 and v946 > -1.1754943508222875E-38 and v946 ~= 0 then
                    buffer.writeu32(v22, 0, to_bits(v946))
                else
                    buffer.writef32(v22, 0, v946)
                end

                local v947 = buffer.readf32(v22, 0)
                local v948 = v885 * v934 + v940

                if v948 < 1.1754943508222875E-38 and v948 > -1.1754943508222875E-38 and v948 ~= 0 then
                    buffer.writeu32(v22, 0, to_bits(v948))
                else
                    buffer.writef32(v22, 0, v948)
                end

                local v949, v950

                v949, v950, v944 = clamp_to_face(v945, v947, buffer.readf32(v22, 0), v877)

                local v951, v952, v953 = closest_segment_xyz(v943, v941, v942, v880, v881, v882, v883, v884, v885, p211[11])
                local v954, v955, v956 = closest_segment_xyz(v949, v950, v944, v880, v881, v882, v883, v884, v885, p211[11])

                v940 = v943 - v951
                v939 = v941 - v952
                v938 = v942 - v953

                local v957 = fround2(v940 * v940 + v939 * v939 + v938 * v938)

                if v957 == 0 then
                    v957 = 0
                else
                    local v958 = 1 / math.sqrt(v957)

                    v958 = v958 * 0.5 * (-v957 * (v958 * v958) + 1) + v958
                    v957 *= v958 * 0.5 * (-v957 * (v958 * v958) + 1) + v958
                end

                v890 = v951
                v891 = v952
                v892 = v953
                v893 = v943
                v894 = v941
                v895 = v942
                v896 = v954
                v897 = v955
                v898 = v956
                v899 = v949
                v900 = v950
                v908 = v944

                if F32_MIN_POSITIVE < v957 then
                    local v959 = -v938 * v884 + v939 * v885

                    v937 = -v940 * v885 + v938 * v883

                    local v960 = -v939 * v883 + v940 * v884

                    v935 = -v885 * v937 + v884 * v960

                    local v961 = -v883 * v960 + v885 * v959

                    v960 = -v884 * v959 + v883 * v937

                    local v962 = v935 * v935 + v961 * v961 + v960 * v960

                    v959 = 1 / math.sqrt(v962)
                    v959 = v959 * 0.5 * (-v962 * (v959 * v959) + 1) + v959
                    v959 = v959 * 0.5 * (-v962 * (v959 * v959) + 1) + v959
                    v962 = v935 * v959

                    if not (v962 < 1.1754943508222875E-38) or not (v962 > -1.1754943508222875E-38) or v962 == 0 then
                        buffer.writef32(v22, 0, v962)
                    else
                        buffer.writeu32(v22, 0, to_bits(v962))
                    end

                    v901 = buffer.readf32(v22, 0)
                    v962 = v961 * v959

                    if v962 < 1.1754943508222875E-38 and v962 > -1.1754943508222875E-38 and v962 ~= 0 then
                        buffer.writeu32(v22, 0, to_bits(v962))
                    else
                        buffer.writef32(v22, 0, v962)
                    end

                    v902 = buffer.readf32(v22, 0)
                    v962 = v960 * v959

                    if v962 < 1.1754943508222875E-38 and v962 > -1.1754943508222875E-38 and v962 ~= 0 then
                        buffer.writeu32(v22, 0, to_bits(v962))
                    else
                        buffer.writef32(v22, 0, v962)
                    end

                    v906 = true
                    v903 = 2
                    v907 = buffer.readf32(v22, 0)
                else
                    v906 = false
                    v903 = 2
                    v901 = 0
                    v902 = 0
                    v907 = 0
                end
            else
                local v963 = v883 * v910 + v880
                local v964 = v884 * v910 + v881
                local v965 = v885 * v910 + v882
                local v966 = v856 * (v931 - v963) + v857 * (v932 - v964) + v858 * (v933 - v965)
                local v967 = v856 * v966 + v963

                if v967 < 1.1754943508222875E-38 and v967 > -1.1754943508222875E-38 and v967 ~= 0 then
                    buffer.writeu32(v22, 0, to_bits(v967))
                else
                    buffer.writef32(v22, 0, v967)
                end

                local v968 = buffer.readf32(v22, 0)
                local v969 = v857 * v966 + v964

                if v969 < 1.1754943508222875E-38 and v969 > -1.1754943508222875E-38 and v969 ~= 0 then
                    buffer.writeu32(v22, 0, to_bits(v969))
                else
                    buffer.writef32(v22, 0, v969)
                end

                local v970 = buffer.readf32(v22, 0)
                local v971 = v858 * v966 + v965

                if v971 < 1.1754943508222875E-38 and v971 > -1.1754943508222875E-38 and v971 ~= 0 then
                    buffer.writeu32(v22, 0, to_bits(v971))
                else
                    buffer.writef32(v22, 0, v971)
                end

                v893, v894, v895 = clamp_to_face(v968, v970, buffer.readf32(v22, 0), v877)
                v890, v891, v892 = closest_segment_xyz(v893, v894, v895, v880, v881, v882, v883, v884, v885, p211[11])
                v906 = false
                v903 = 1
                v901 = 0
                v902 = 0
                v907 = 0
                v896 = nil
                v897 = nil
                v898 = nil
                v899 = nil
                v900 = nil
                v908 = nil
            end
        else
            local v972 = v856 * v843 + v857 * v844 + v858 * v845
            local v973 = v883 * v910 + v880
            local v974 = v884 * v910 + v881
            local v975 = v885 * v910 + v882

            if not (v973 < 1.1754943508222875E-38) or not (v973 > -1.1754943508222875E-38) or v973 == 0 then
                buffer.writef32(v22, 0, v973)
            else
                buffer.writeu32(v22, 0, to_bits(v973))
            end

            v890 = buffer.readf32(v22, 0)

            if v974 < 1.1754943508222875E-38 and v974 > -1.1754943508222875E-38 and v974 ~= 0 then
                buffer.writeu32(v22, 0, to_bits(v974))
            else
                buffer.writef32(v22, 0, v974)
            end

            v891 = buffer.readf32(v22, 0)

            if v975 < 1.1754943508222875E-38 and v975 > -1.1754943508222875E-38 and v975 ~= 0 then
                buffer.writeu32(v22, 0, to_bits(v975))
            else
                buffer.writef32(v22, 0, v975)
            end

            v892 = buffer.readf32(v22, 0)

            local v976 = ((v931 - v973) * v843 + (v932 - v974) * v844 + (v933 - v975) * v845) / v972
            local v977 = v856 * v976 + v973

            if v977 < 1.1754943508222875E-38 and v977 > -1.1754943508222875E-38 and v977 ~= 0 then
                buffer.writeu32(v22, 0, to_bits(v977))
            else
                buffer.writef32(v22, 0, v977)
            end

            v893 = buffer.readf32(v22, 0)
            v977 = v857 * v976 + v974

            if v977 < 1.1754943508222875E-38 and v977 > -1.1754943508222875E-38 and v977 ~= 0 then
                buffer.writeu32(v22, 0, to_bits(v977))
            else
                buffer.writef32(v22, 0, v977)
            end

            v894 = buffer.readf32(v22, 0)
            v977 = v858 * v976 + v975

            if v977 < 1.1754943508222875E-38 and v977 > -1.1754943508222875E-38 and v977 ~= 0 then
                buffer.writeu32(v22, 0, to_bits(v977))
            else
                buffer.writef32(v22, 0, v977)
            end

            v895 = buffer.readf32(v22, 0)
            v973 = v883 * v911 + v880

            local v978 = v884 * v911 + v881

            v975 = v885 * v911 + v882

            if v973 < 1.1754943508222875E-38 and v973 > -1.1754943508222875E-38 and v973 ~= 0 then
                buffer.writeu32(v22, 0, to_bits(v973))
            else
                buffer.writef32(v22, 0, v973)
            end

            v896 = buffer.readf32(v22, 0)

            if v978 < 1.1754943508222875E-38 and v978 > -1.1754943508222875E-38 and v978 ~= 0 then
                buffer.writeu32(v22, 0, to_bits(v978))
            else
                buffer.writef32(v22, 0, v978)
            end

            v897 = buffer.readf32(v22, 0)

            if v975 < 1.1754943508222875E-38 and v975 > -1.1754943508222875E-38 and v975 ~= 0 then
                buffer.writeu32(v22, 0, to_bits(v975))
            else
                buffer.writef32(v22, 0, v975)
            end

            v898 = buffer.readf32(v22, 0)
            v976 = ((v931 - v973) * v843 + (v932 - v978) * v844 + (v933 - v975) * v845) / v972
            v977 = v856 * v976 + v973

            if v977 < 1.1754943508222875E-38 and v977 > -1.1754943508222875E-38 and v977 ~= 0 then
                buffer.writeu32(v22, 0, to_bits(v977))
            else
                buffer.writef32(v22, 0, v977)
            end

            v899 = buffer.readf32(v22, 0)
            v977 = v857 * v976 + v978

            if v977 < 1.1754943508222875E-38 and v977 > -1.1754943508222875E-38 and v977 ~= 0 then
                buffer.writeu32(v22, 0, to_bits(v977))
            else
                buffer.writef32(v22, 0, v977)
            end

            v900 = buffer.readf32(v22, 0)
            v977 = v858 * v976 + v975

            if v977 < 1.1754943508222875E-38 and v977 > -1.1754943508222875E-38 and v977 ~= 0 then
                buffer.writeu32(v22, 0, to_bits(v977))
            else
                buffer.writef32(v22, 0, v977)
            end

            v906 = false
            v903 = 2
            v901 = 0
            v902 = 0
            v907 = 0
            v908 = buffer.readf32(v22, 0)
        end
    else
        local v979, v980, v981

        if v859 > 0 then
            v979 = p211[5]
            v980 = p211[6]
            v981 = p211[7]
        else
            v979 = p211[13]
            v980 = p211[14]
            v981 = p211[15]
        end

        v880 = v856 * (v877[1] - v979) + v857 * (v877[2] - v980) + v858 * (v877[3] - v981)
        v881 = v856 * v880 + v979
        v882 = v857 * v880 + v980
        v883 = v858 * v880 + v981
        v884 = v877[7] * (v881 - v877[1]) + v877[8] * (v882 - v877[2]) + v877[9] * (v883 - v877[3])

        local v982 = v877[17] * (v881 - v877[11]) + v877[18] * (v882 - v877[12]) + v877[19] * (v883 - v877[13])

        if v884 < v982 then
            v880 = 10
        else
            v982 = v884
            v880 = 0
        end

        v885 = v877[27] * (v881 - v877[21]) + v877[28] * (v882 - v877[22]) + v877[29] * (v883 - v877[23])

        if v982 < v885 then
            v880 = 20
        else
            v885 = v982
        end

        v890 = v979
        v891 = v980
        v892 = v981

        if v885 > 0 then
            v886 = v881 - v877[v880 + 7] * v885

            if not (v886 < 1.1754943508222875E-38) or not (v886 > -1.1754943508222875E-38) or v886 == 0 then
                buffer.writef32(v22, 0, v886)
            else
                buffer.writeu32(v22, 0, to_bits(v886))
            end

            v887 = buffer.readf32(v22, 0)

            local v983 = v882 - v877[v880 + 8] * v885

            if v983 < 1.1754943508222875E-38 and v983 > -1.1754943508222875E-38 and v983 ~= 0 then
                buffer.writeu32(v22, 0, to_bits(v983))
            else
                buffer.writef32(v22, 0, v983)
            end

            local v984 = buffer.readf32(v22, 0)
            local v985 = v883 - v877[v880 + 9] * v885

            if v985 < 1.1754943508222875E-38 and v985 > -1.1754943508222875E-38 and v985 ~= 0 then
                buffer.writeu32(v22, 0, to_bits(v985))
            else
                buffer.writef32(v22, 0, v985)
            end

            v893, v894, v895 = closest_segment_xyz(v887, v984, buffer.readf32(v22, 0), v877[v880 + 1], v877[v880 + 2], v877[v880 + 3], v877[v880 + 4], v877[v880 + 5], v877[v880 + 6], v877[v880 + 10])
            v906 = false
            v903 = 1
            v901 = 0
            v902 = 0
            v907 = 0
        else
            if v881 < 1.1754943508222875E-38 and v881 > -1.1754943508222875E-38 and v881 ~= 0 then
                buffer.writeu32(v22, 0, to_bits(v881))
            else
                buffer.writef32(v22, 0, v881)
            end

            v893 = buffer.readf32(v22, 0)

            if v882 < 1.1754943508222875E-38 and v882 > -1.1754943508222875E-38 and v882 ~= 0 then
                buffer.writeu32(v22, 0, to_bits(v882))
            else
                buffer.writef32(v22, 0, v882)
            end

            v894 = buffer.readf32(v22, 0)

            if v883 < 1.1754943508222875E-38 and v883 > -1.1754943508222875E-38 and v883 ~= 0 then
                buffer.writeu32(v22, 0, to_bits(v883))
            else
                buffer.writef32(v22, 0, v883)
            end

            v906 = false
            v903 = 1
            v901 = 0
            v902 = 0
            v907 = 0
            v895 = buffer.readf32(v22, 0)
            v896 = nil
            v897 = nil
            v898 = nil
            v899 = nil
            v900 = nil
            v908 = nil
        end
    end

    local v986 = v901
    local v987 = v902
    local v988 = v906
    local v989 = v907

    if v903 == 1 then
        v877 = v893 - v890
        v875 = v894 - v891
        v859 = v895 - v892
        v880 = fround2(v877 * v877 + v875 * v875 + v859 * v859)
        v844 = 1 / math.sqrt(v880)
        v844 = v844 * 0.5 * (-v880 * (v844 * v844) + 1) + v844
        v844 = v844 * 0.5 * (-v880 * (v844 * v844) + 1) + v844

        if v880 == 0 then
            v880 = 0
        else
            v880 *= v844
        end

        if v281 < v880 then
            v881 = v877 * v844

            if not (v881 < 1.1754943508222875E-38) or not (v881 > -1.1754943508222875E-38) or v881 == 0 then
                buffer.writef32(v22, 0, v881)
            else
                buffer.writeu32(v22, 0, to_bits(v881))
            end

            v986 = buffer.readf32(v22, 0)
            v881 = v875 * v844

            if v881 < 1.1754943508222875E-38 and v881 > -1.1754943508222875E-38 and v881 ~= 0 then
                buffer.writeu32(v22, 0, to_bits(v881))
            else
                buffer.writef32(v22, 0, v881)
            end

            v987 = buffer.readf32(v22, 0)
            v881 = v859 * v844

            if v881 < 1.1754943508222875E-38 and v881 > -1.1754943508222875E-38 and v881 ~= 0 then
                buffer.writeu32(v22, 0, to_bits(v881))
            else
                buffer.writef32(v22, 0, v881)
            end

            v988 = true
            v989 = buffer.readf32(v22, 0)
        end
    end

    if v988 then
        v843 = p214 * v986 + p215 * v987 + p216 * v989
        v882 = v839 * v986 + v840 * v987 + v841 * v989
        v880 = math.abs(v882) * v842
        v881 = p206[7] * v986 + p206[8] * v987 + p206[9] * v989
        v882 = p206[10] * v986 + p206[11] * v987 + p206[12] * v989
        v883 = p206[13] * v986 + p206[14] * v987 + p206[15] * v989
        v889 = if v881 < v882 then v881 else v882

        if not (v882 < v881) then
            v881 = v882
        end

        v904 = v843 - v880

        if v904 < 1.1754943508222875E-38 and v904 > -1.1754943508222875E-38 and v904 ~= 0 then
            buffer.writeu32(v22, 0, to_bits(v904))
        else
            buffer.writef32(v22, 0, v904)
        end

        v886 = buffer.readf32(v22, 0)

        if not (v883 < v881) then
            v881 = v883
        end

        if v881 < 1.1754943508222875E-38 and v881 > -1.1754943508222875E-38 and v881 ~= 0 then
            buffer.writeu32(v22, 0, to_bits(v881))
        else
            buffer.writef32(v22, 0, v881)
        end

        v882 = v886 - buffer.readf32(v22, 0)

        if not (v889 < v883) then
            v889 = v883
        end

        if v889 < 1.1754943508222875E-38 and v889 > -1.1754943508222875E-38 and v889 ~= 0 then
            buffer.writeu32(v22, 0, to_bits(v889))
        else
            buffer.writef32(v22, 0, v889)
        end

        v886 = buffer.readf32(v22, 0)
        v905 = v843 + v880

        if v905 < 1.1754943508222875E-38 and v905 > -1.1754943508222875E-38 and v905 ~= 0 then
            buffer.writeu32(v22, 0, to_bits(v905))
        else
            buffer.writef32(v22, 0, v905)
        end

        v885 = v886 - buffer.readf32(v22, 0)

        if v885 < v882 then
            if v855 <= v882 then
                v856 = -v986
                v857 = -v987
                v858 = -v989
            end
        elseif v855 <= v885 then
            v858 = v989
            v856 = v986
            v857 = v987
        end
    end

    v880 = fix_up_toward(p206, -v856, -v857, -v858, p220)

    if v880 == 0 then
        return nil
    end

    v876 = p206[16]

    if v880 == 1 then
        v880 = v856 * p217
        v881 = v857 * p217
        v986 = v858 * p217
        v883 = v856 * v876
        v884 = v857 * v876
        v885 = v858 * v876
        v42[1] = v890 + v880
        v42[2] = v891 + v881
        v42[3] = v892 + v986
        v42[4] = v893 - v883
        v42[5] = v894 - v884
        v42[6] = v895 - v885

        if v903 == 2 then
            v42[7] = v896 + v880
            v42[8] = v897 + v881
            v42[9] = v898 + v986
            v42[10] = v899 - v883
            v42[11] = v900 - v884
            v42[12] = v908 - v885
        end

        return v903, -v856, -v857, -v858
    end

    v989 = v133[1]
    v851 = v131[1]
    v853 = v132[1]
    v851.x = v890
    v851.y = v891
    v851.z = v892
    v853.x = v893
    v853.y = v894
    v853.z = v895
    v989.a = v851
    v989.b = v853

    if v903 == 2 then
        v989 = v133[2]
        v851 = v131[2]
        v853 = v132[2]
        v851.x = v896
        v851.y = v897
        v851.z = v898
        v853.x = v899
        v853.y = v900
        v853.z = v908
        v989.a = v851
        v989.b = v853
    end

    t6.x = v856
    t6.y = v857
    t6.z = v858
    t7.edge_cos_bend_normal_threshold = p220.edge_cos_bend_normal_threshold
    t7.convexity_epsilon = p220.convexity_epsilon
    t7.is_object = p220.is_object

    if not fix_up_triangle(p208[p209 + 1].triangle.feature, t6, v134[v903 + 1], t7) then
        return nil
    end

    v880 = t6.x
    v881 = t6.y
    v986 = t6.z
    v883 = v880 * p217
    v884 = v881 * p217
    v885 = v986 * p217
    v888 = v880 * v876
    v889 = v881 * v876
    v886 = v986 * v876

    for i = 0, v903 - 1 do
        v989 = v133[i + 1]
        v851 = v989.a
        v853 = v989.b
        v908 = i * 6
        v42[v908 + 1] = v851.x + v883
        v42[v908 + 2] = v851.y + v884
        v42[v908 + 3] = v851.z + v885
        v42[v908 + 4] = v853.x - v888
        v42[v908 + 5] = v853.y - v889
        v42[v908 + 6] = v853.z - v886
    end

    return v903, -v880, -v881, -v986
end

t1.capsule_triangle_contacts_flat_w1 = capsule_triangle_contacts_flat_w1

function t1.capsule_triangle_contacts_flat(p221, p222, p223, p224, p225, p226, p227, p228, p229, p230, p231, p232, p233, p234, p235) -- line: 2686
    -- upvalues: fix_up_triangle (copy), pack (copy), v22 (copy), to_bits (copy), contact_points_flat (ref), v42 (copy), v131 (copy), v132 (copy), v133 (copy), v134 (copy), t6 (copy), t7 (copy), face_memo (copy), v281 (copy), v312 (copy), v313 (copy), v314 (copy), fround2 (copy), v361 (ref), round3 (copy), closest_segment_v (copy), segment_face_xyz (copy), fix_up_toward (copy), v542 (ref), capsule_floats (copy), direction_words (copy), v777 (ref), capsule_edge_pair (copy), capsule_triangle_contacts_flat_w1 (copy)
    if v361 then
        return capsule_triangle_contacts_flat_w1(p221, p222, p223, p224, p225, p226, p227, p228, p229, p230, p231, p232, p233, p234, p235)
    end

    local v990 = p226[1]
    local v991 = p226[2]
    local v992 = p226[3]
    local v993 = p226[4]
    local v994 = p221[4]
    local v995 = p221[5]
    local v996 = p221[6]
    local v997 = p227
    local n16 = 0
    local v998 = p228
    local v999 = v994
    local v1000 = v995
    local v1001 = v996
    local v1002, v1003, v1004, v1005, v1006, v1007, v1008, v1009

    for i = 24, 30, 3 do
        local v1010 = p221[i]

        v1003 = p221[i + 1]
        v1005 = p221[i + 2]

        local v1011 = -v992 * v1003 + v991 * v1005

        v1002 = -v990 * v1005 + v992 * v1010
        v1005 = -v991 * v1010 + v990 * v1003
        v1003 = v1011 * v1011 + v1002 * v1002 + v1005 * v1005

        local v1012, v1013

        if v312 < v1003 then
            local v1014 = 1 / math.sqrt(v1003)

            v1014 = v1014 * 0.5 * (-v1003 * (v1014 * v1014) + 1) + v1014
            v1014 = v1014 * 0.5 * (-v1003 * (v1014 * v1014) + 1) + v1014

            local v1015, v1016, v1017 = round3(v1011 * v1014, v1002 * v1014, v1005 * v1014)

            v1014 = p229 * v1015 + p230 * v1016 + p231 * v1017
            v1004 = math.abs(v990 * v1015 + v991 * v1016 + v992 * v1017) * v993

            local v1019 = p221[7] * v1015 + p221[8] * v1016 + p221[9] * v1017
            local v1018 = p221[10] * v1015 + p221[11] * v1016 + p221[12] * v1017
            local v1020 = p221[13] * v1015 + p221[14] * v1016 + p221[15] * v1017
            local v1021 = if v1019 < v1018 then v1019 else v1018
            local v1022 = if v1018 < v1019 then v1019 else v1018
            local v1023 = v1014 - v1004

            if not (v1020 < v1022) then
                v1022 = v1020
            end

            local v1024 = if v1021 < v1020 then v1021 else v1020
            local v1025, v1026

            v1025, v1023, v1026 = round3(v1023, v1022, v1024)
            v1022 = v1025 - v1023

            local v1027 = v1014 + v1004

            if v1027 < 1.1754943508222875E-38 and v1027 > -1.1754943508222875E-38 and v1027 ~= 0 then
                buffer.writeu32(v22, 0, to_bits(v1027))
            else
                buffer.writef32(v22, 0, v1027)
            end

            v1023 = v1026 - buffer.readf32(v22, 0)

            if v1023 < v1022 then
                if v997 < v1022 then
                    if not (v1022 < 1.1754943508222875E-38) or not (v1022 > -1.1754943508222875E-38) or v1022 == 0 then
                        buffer.writef32(v22, 0, v1022)
                    else
                        buffer.writeu32(v22, 0, to_bits(v1022))
                    end

                    if p233 < buffer.readf32(v22, 0) then
                        return nil
                    end

                    v1008 = v1017
                    v1009 = v1022
                    v1013 = i
                    v1012 = true
                    v1006 = v1015
                    v1007 = v1016
                else
                    v1008 = v1001
                    v1009 = v997
                    v1013 = n16
                    v1012 = v998
                    v1006 = v999
                    v1007 = v1000
                end
            elseif v997 < v1023 then
                if not (v1023 < 1.1754943508222875E-38) or not (v1023 > -1.1754943508222875E-38) or v1023 == 0 then
                    buffer.writef32(v22, 0, v1023)
                else
                    buffer.writeu32(v22, 0, to_bits(v1023))
                end

                if p233 < buffer.readf32(v22, 0) then
                    return nil
                end

                v1008 = v1017
                v1009 = v1023
                v1013 = i
                v1012 = false
                v1006 = v1015
                v1007 = v1016
            else
                v1008 = v1001
                v1009 = v997
                v1013 = n16
                v1012 = v998
                v1006 = v999
                v1007 = v1000
            end
        else
            v1008 = v1001
            v1009 = v997
            v1013 = n16
            v1012 = v998
            v1006 = v999
            v1007 = v1000
        end

        v1001 = v1008
        v997 = v1009
        n16 = v1013
        v998 = v1012
        v999 = v1006
        v1000 = v1007
    end

    if v998 then
        v1006 = -v999
        v1007 = -v1000
        v1008 = -v1001
    else
        v1008 = v1001
        v1006 = v999
        v1007 = v1000
    end

    if v997 < 1.1754943508222875E-38 and v997 > -1.1754943508222875E-38 and v997 ~= 0 then
        buffer.writeu32(v22, 0, to_bits(v997))
    else
        buffer.writef32(v22, 0, v997)
    end

    v1005 = buffer.readf32(v22, 0)
    v1009 = v990 * v1006 + v991 * v1007 + v992 * v1008
    v1003 = -v1006 * v994 + -v1007 * v995 + -v1008 * v996

    local v1028 = math.abs(v1009) < v313
    local v1029, v1030, v1031, v1032

    if math.abs(v1003) > v314 and (v1028 or n16 == 0) then
        v1002 = not (v1003 < 0)
        v1029 = if v1002 then 22 else 23
        v1032 = p221[v1029]

        if v1032 == false then
            v1004 = p223[p224 + 1].triangle
            v1030 = p222[p224 + 1]

            if v1030 == nil then
                v1030 = pack({
                    tag = "Triangle",
                    v1004
                })
                p222[p224 + 1] = v1030
            end

            v1031 = face_memo(v1030, v1002)
            p221[v1029] = v1031
        else
            v1031 = v1032
        end

        v1032 = if v1031 == 0 or v1031[31] ~= 3 then nil else v1031
    end

    local v1033, v1034, v1035, v1036, v1037, v1038, v1039, v1040, v1041, v1042, v1043, v1044, v1045, v1046, v1047, v1048, v1049, v1050, v1051, v1052, v1053

    if v1032 ~= nil then
        if p226[12] ~= 1 then
            capsule_floats(p226, p229, p230, p231)
        end

        if v1028 then
            v1037, v1038, v1039, v1040, v1041, v1042, v1043, v1044, v1045, v1046, v1047, v1048, v1049, v1050, v1051, v1052, v1053 = segment_face_xyz(v1032, 0, v1006, v1007, v1008, v994, v995, v996, p226[5], p226[6], p226[7], p226[8], p226[9], p226[10], p226[11])
        else
            if v1009 > 0 then
                v1045 = p226[5]
                v1046 = p226[6]
                v1047 = p226[7]
            else
                v1045 = p226[13]
                v1046 = p226[14]
                v1047 = p226[15]
            end

            v1037 = v1006 * (v1032[1] - v1045) + v1007 * (v1032[2] - v1046) + v1008 * (v1032[3] - v1047)
            v1038 = v1006 * v1037 + v1045
            v1039 = v1007 * v1037 + v1046
            v1040 = v1008 * v1037 + v1047
            v1041 = v1032[7] * (v1038 - v1032[1]) + v1032[8] * (v1039 - v1032[2]) + v1032[9] * (v1040 - v1032[3])
            v1042 = v1032[17] * (v1038 - v1032[11]) + v1032[18] * (v1039 - v1032[12]) + v1032[19] * (v1040 - v1032[13])

            if v1041 < v1042 then
                v1037 = 10
            else
                v1042 = v1041
                v1037 = 0
            end

            v1036 = v1032[27] * (v1038 - v1032[21]) + v1032[28] * (v1039 - v1032[22]) + v1032[29] * (v1040 - v1032[23])

            if v1042 < v1036 then
                v1037 = 20
            else
                v1036 = v1042
            end

            if v1036 > 0 then
                local v1060

                v1043, v1044, v1060 = round3(v1038 - v1032[v1037 + 7] * v1036, v1039 - v1032[v1037 + 8] * v1036, v1040 - v1032[v1037 + 9] * v1036)
                v1042, v1043, v1044 = closest_segment_v(v1043, v1044, v1060, v1032[v1037 + 1], v1032[v1037 + 2], v1032[v1037 + 3], v1032[v1037 + 4], v1032[v1037 + 5], v1032[v1037 + 6], v1032[v1037 + 10])
            else
                v1042, v1043, v1044 = round3(v1038, v1039, v1040)
            end

            v1037 = 1
            v1038 = false
            v1039 = 0
            v1040 = 0
            v1041 = 0
        end
    else
        local v1054, v1055, v1056

        if not v777 or not v1028 or math.abs(v1003) > v314 then
            v1054 = false
        else
            if p226[12] ~= 1 then
                capsule_floats(p226, p229, p230, p231)
            end

            v1054, v1033, v1034, v1035, v1036, v1055, v1056 = capsule_edge_pair(p221, p222, p223, p224, p226, -v1006, -v1007, -v1008)

            local v1057 = v542

            if v1057 and v1054 then
                v1057 = v542
                v1057.edges = (v542.edges or 0) + 1
            end
        end

        if not v1054 then
            local triangle = p223[p224 + 1].triangle
            local v1059 = p222[p224 + 1]

            if v1059 == nil then
                v1059 = pack({
                    tag = "Triangle",
                    triangle
                })
                p222[p224 + 1] = v1059
            end

            return contact_points_flat(p225, "Capsule", v1059, "Triangle", triangle, v1005, direction_words(n16, v998, v1059, 4, v999, v1000, v1001), p234, p235)
        end

        v1037 = 1
        v1038 = false
        v1039 = 0
        v1040 = 0
        v1041 = 0
        v1045 = v1033
        v1046 = v1034
        v1047 = v1035
        v1042 = v1036
        v1043 = v1055
        v1044 = v1056
        v1051 = nil
        v1052 = nil
        v1053 = nil
        v1048 = nil
        v1049 = nil
        v1050 = nil
    end

    local v1061

    if v1037 == 1 then
        v1032 = v1042 - v1045
        v1028 = v1043 - v1046
        v1003 = v1044 - v1047
        v1061 = v1032 * v1032 + v1028 * v1028 + v1003 * v1003

        local v1062

        if v1061 ~= 0 and v1061 > -1.1754943508222875E-38 and v1061 < 1.1754943508222875E-38 then
            v1062 = fround2(v1061)
        else
            buffer.writef32(v22, 0, v1061)
            v1062 = buffer.readf32(v22, 0)
        end

        local v1063 = 1 / math.sqrt(v1062)

        v1063 = v1063 * 0.5 * (-v1062 * (v1063 * v1063) + 1) + v1063
        v1063 = v1063 * 0.5 * (-v1062 * (v1063 * v1063) + 1) + v1063
        v1061 = if v1062 == 0 then 0 else v1062 * v1063

        if v281 < v1061 then
            v1039, v1040, v1041 = round3(v1032 * v1063, v1028 * v1063, v1003 * v1063)
            v1038 = true
        end
    end

    if v1038 then
        local v1064 = p229 * v1039 + p230 * v1040 + p231 * v1041

        v1038 = v990 * v1039 + v991 * v1040 + v992 * v1041
        v998 = math.abs(v1038) * v993
        n16 = p221[7] * v1039 + p221[8] * v1040 + p221[9] * v1041
        v1009 = p221[10] * v1039 + p221[11] * v1040 + p221[12] * v1041
        v996 = p221[13] * v1039 + p221[14] * v1040 + p221[15] * v1041
        v1034 = if n16 < v1009 then n16 else v1009

        if not (v1009 < n16) then
            n16 = v1009
        end

        v1038 = v1064 - v998

        if not (v996 < n16) then
            n16 = v996
        end

        if not (v1034 < v996) then
            v1034 = v996
        end

        v1061, v1038, v1033 = round3(v1038, n16, v1034)
        n16 = v1061 - v1038
        v1035 = v1064 + v998

        if v1035 < 1.1754943508222875E-38 and v1035 > -1.1754943508222875E-38 and v1035 ~= 0 then
            buffer.writeu32(v22, 0, to_bits(v1035))
        else
            buffer.writef32(v22, 0, v1035)
        end

        v1038 = v1033 - buffer.readf32(v22, 0)

        if v1038 < n16 then
            if v1005 <= n16 then
                v1006 = -v1039
                v1007 = -v1040
                v1008 = -v1041
            end
        elseif v1005 <= v1038 then
            v1008 = v1041
            v1006 = v1039
            v1007 = v1040
        end
    end

    v1061 = fix_up_toward(p221, -v1006, -v1007, -v1008, p235)

    if v1061 == 0 then
        return nil
    end

    v1030 = p221[16]

    if v1061 == 1 then
        v1061 = v1006 * p232
        v1038 = v1007 * p232
        v1039 = v1008 * p232
        v1040 = v1006 * v1030
        v1041 = v1007 * v1030
        v1036 = v1008 * v1030
        v42[1] = v1045 + v1061
        v42[2] = v1046 + v1038
        v42[3] = v1047 + v1039
        v42[4] = v1042 - v1040
        v42[5] = v1043 - v1041
        v42[6] = v1044 - v1036

        if v1037 == 2 then
            v42[7] = v1051 + v1061
            v42[8] = v1052 + v1038
            v42[9] = v1053 + v1039
            v42[10] = v1048 - v1040
            v42[11] = v1049 - v1041
            v42[12] = v1050 - v1036
        end

        return v1037, -v1006, -v1007, -v1008
    end

    v1004 = v133[1]
    v1031 = v131[1]
    v1029 = v132[1]
    v1031.x = v1045
    v1031.y = v1046
    v1031.z = v1047
    v1029.x = v1042
    v1029.y = v1043
    v1029.z = v1044
    v1004.a = v1031
    v1004.b = v1029

    if v1037 == 2 then
        v1004 = v133[2]
        v1031 = v131[2]
        v1029 = v132[2]
        v1031.x = v1051
        v1031.y = v1052
        v1031.z = v1053
        v1029.x = v1048
        v1029.y = v1049
        v1029.z = v1050
        v1004.a = v1031
        v1004.b = v1029
    end

    t6.x = v1006
    t6.y = v1007
    t6.z = v1008
    t7.edge_cos_bend_normal_threshold = p235.edge_cos_bend_normal_threshold
    t7.convexity_epsilon = p235.convexity_epsilon
    t7.is_object = p235.is_object

    if not fix_up_triangle(p223[p224 + 1].triangle.feature, t6, v134[v1037 + 1], t7) then
        return nil
    end

    v1061 = t6.x
    v1038 = t6.y
    v1039 = t6.z
    v1040 = v1061 * p232
    v1041 = v1038 * p232
    v1042 = v1039 * p232
    v1043 = v1061 * v1030
    v1044 = v1038 * v1030
    v1045 = v1039 * v1030

    for i = 0, v1037 - 1 do
        v1004 = v133[i + 1]
        v1031 = v1004.a
        v1029 = v1004.b

        local v1065 = i * 6

        v42[v1065 + 1] = v1031.x + v1040
        v42[v1065 + 2] = v1031.y + v1041
        v42[v1065 + 3] = v1031.z + v1042
        v42[v1065 + 4] = v1029.x - v1043
        v42[v1065 + 5] = v1029.y - v1044
        v42[v1065 + 6] = v1029.z - v1045
    end

    return v1037, -v1061, -v1038, -v1039
end

local v1066 = true

function t1.set_triangle_features(p236) -- line: 2987
    -- upvalues: v1066 (ref)
    local v1067 = v1066

    v1066 = p236

    return v1067
end

local function triangle_face_pair(p237, p238, p239, p240, p241, p242, p243, p244, p245, p246) -- line: 2992
    -- upvalues: v22 (copy), v315 (copy), round3 (copy), closest_segment_v (copy), segment_face_xyz (copy), v779 (copy)
    local v1068 = p240[6]
    local v1069 = p240[7]
    local v1070 = p240[8]
    local v1071 = p240[9]
    local v1072 = p240[10]
    local v1073 = p240[11]
    local v1074 = p244 * p241 + p245 * p242 + p246 * p243
    local v1075 = p244 * v1068 + p245 * v1069 + p246 * v1070
    local v1076 = p244 * v1071 + p245 * v1072 + p246 * v1073
    local v1078 = math.abs(p244 * p240[12] + p245 * p240[13] + p246 * p240[14])
    local v1080 = math.abs(p244 * p240[15] + p245 * p240[16] + p246 * p240[17])
    local v1082 = math.abs(p244 * p240[18] + p245 * p240[19] + p246 * p240[20])
    local v1083, v1084

    if v1075 < v1074 and v1076 < v1074 then
        v1083 = if v1078 < v779 and v1078 < v1082 then 0 elseif v1082 < v779 then 2 else -1
        v1084 = 0
    elseif v1076 < v1075 then
        v1083 = if v1080 < v779 and v1080 < v1082 then 1 elseif v1082 < v779 then 2 else -1
        v1084 = 1
    else
        v1083 = if v1078 < v779 and v1078 < v1080 then 0 elseif v1080 < v779 then 1 else -1
        v1084 = 2
    end

    if v1083 >= 0 then
        if v1083 == 0 then
            v1071 = p241
            v1072 = p242
            v1073 = p243
        elseif v1083 ~= 1 then
            v1073 = v1070
            v1071 = v1068
            v1072 = v1069
        end

        local v1085 = 12 + 3 * v1083
        local v1086 = p237[4]
        local v1087 = p237[5]
        local v1088 = p237[6]
        local v1089 = p240[v1085]
        local v1090 = p240[v1085 + 1]
        local v1091 = p240[v1085 + 2]

        buffer.writeu32(v22, 0, p239[29 + v1083])

        return segment_face_xyz(p238, 0, p244, p245, p246, v1086, v1087, v1088, v1071, v1072, v1073, v1089, v1090, v1091, (buffer.readf32(v22, 0)))
    end

    if v1084 == 0 then
        v1068 = p241
        v1069 = p242
        v1070 = p243
    elseif v1084 ~= 1 then
        v1070 = v1073
        v1068 = v1071
        v1069 = v1072
    end

    local v1093 = p238[1]
    local v1094 = p238[2]
    local v1095 = p238[3]
    local v1096 = p244 * (v1093 - v1068) + p245 * (v1094 - v1069) + p246 * (v1095 - v1070)
    local v1097 = p244 * v1096 + v1068
    local v1098 = p245 * v1096 + v1069
    local v1099 = p246 * v1096 + v1070
    local n17 = 0
    local n18 = 0
    local n19 = 0
    local n20 = 0
    local n21 = 0

    for i = 0, 20, 10 do
        local v1100 = p238[i + 4]
        local v1101 = p238[i + 5]
        local v1102 = p238[i + 6]
        local v1103 = -v1102 * p245 + v1101 * p246
        local v1104 = -v1100 * p246 + v1102 * p244
        local v1105 = -v1101 * p244 + v1100 * p245
        local v1106 = v1103 * v1103 + v1104 * v1104 + v1105 * v1105
        local v1107 = 1 / math.sqrt(v1106)
        local v1108 = v1107 * 0.5 * (-v1106 * (v1107 * v1107) + 1) + v1107

        if not (v315 < v1106) then
            v1108 = 0
        end

        local v1109, v1110, v1111 = round3(v1103 * v1108, v1104 * v1108, v1105 * v1108)
        local v1112 = v1109 * (v1097 - p238[i + 1]) + v1110 * (v1098 - p238[i + 2]) + v1111 * (v1099 - p238[i + 3])

        if i == 0 or n17 < v1112 then
            n21 = v1111
            n17 = v1112
            n18 = i
            n19 = v1109
            n20 = v1110
        end
    end

    local v1113, v1114, v1115

    if n17 > 0 then
        local v1116, v1117, v1118 = round3(v1097 - n19 * n17, v1098 - n20 * n17, v1099 - n21 * n17)

        v1113, v1114, v1115 = closest_segment_v(v1116, v1117, v1118, p238[n18 + 1], p238[n18 + 2], p238[n18 + 3], p238[n18 + 4], p238[n18 + 5], p238[n18 + 6], p238[n18 + 10])
    else
        v1113, v1114, v1115 = round3(v1097, v1098, v1099)
    end

    return 1, false, 0, 0, 0, v1113, v1114, v1115, v1068, v1069, v1070, 0, 0, 0, 0, 0, 0
end

local function triangle_triangle_contacts_flat_w1(p247, p248, p249, p250, p251, p252, p253, p254, p255, p256, p257, p258, p259, p260, p261, p262) -- line: 3102
    -- upvalues: pack (copy), v22 (copy), to_bits (copy), contact_points_flat (ref), v312 (copy), direction_words (copy)
    local v1119, v1120, v1121

    if p253 < p255 then
        v1119 = p255
        v1120 = true
        v1121 = p256
    else
        v1119 = p253
        v1120 = false
        v1121 = p254
    end

    local v1122 = p252[6]
    local v1123 = p252[7]
    local v1124 = p252[8]
    local v1125 = p252[9]
    local v1126 = p252[10]
    local v1127 = p252[11]
    local v1128 = p247[7]
    local v1129 = p247[8]
    local v1130 = p247[9]
    local v1131 = p247[10]
    local v1132 = p247[11]
    local v1133 = p247[12]
    local v1134 = p247[13]
    local v1135 = p247[14]
    local v1136 = p247[15]
    local n22 = 0
    local n23 = 0
    local n24 = 0
    local n25 = 0

    for i = 12, 18, 3 do
        local v1137 = p252[i]
        local v1138 = p252[i + 1]
        local v1139 = p252[i + 2]

        for j = 24, 30, 3 do
            local v1140 = p247[j]
            local v1141 = p247[j + 1]
            local v1142 = p247[j + 2]
            local v1143 = -v1139 * v1141 + v1138 * v1142
            local v1144 = -v1137 * v1142 + v1139 * v1140
            local v1145 = -v1138 * v1140 + v1137 * v1141
            local v1146 = v1143 * v1143 + v1144 * v1144 + v1145 * v1145
            local v1147, v1148, v1149, v1150, v1151, v1152

            if v312 < v1146 then
                local v1153 = 1 / math.sqrt(v1146)
                local v1154 = v1153 * 0.5 * (-v1146 * (v1153 * v1153) + 1) + v1153
                local v1155 = v1154 * 0.5 * (-v1146 * (v1154 * v1154) + 1) + v1154
                local v1156 = v1143 * v1155

                if not (v1156 < 1.1754943508222875E-38) or not (v1156 > -1.1754943508222875E-38) or v1156 == 0 then
                    buffer.writef32(v22, 0, v1156)
                else
                    buffer.writeu32(v22, 0, to_bits(v1156))
                end

                local v1157 = buffer.readf32(v22, 0)
                local v1158 = v1144 * v1155

                if v1158 < 1.1754943508222875E-38 and v1158 > -1.1754943508222875E-38 and v1158 ~= 0 then
                    buffer.writeu32(v22, 0, to_bits(v1158))
                else
                    buffer.writef32(v22, 0, v1158)
                end

                local v1159 = buffer.readf32(v22, 0)
                local v1160 = v1145 * v1155

                if v1160 < 1.1754943508222875E-38 and v1160 > -1.1754943508222875E-38 and v1160 ~= 0 then
                    buffer.writeu32(v22, 0, to_bits(v1160))
                else
                    buffer.writef32(v22, 0, v1160)
                end

                local v1161 = buffer.readf32(v22, 0)
                local v1162 = p257 * v1157 + p258 * v1159 + p259 * v1161
                local v1163 = v1122 * v1157 + v1123 * v1159 + v1124 * v1161
                local v1164 = v1125 * v1157 + v1126 * v1159 + v1127 * v1161
                local v1165 = if v1162 < v1163 then v1162 else v1163

                if not (v1163 < v1162) then
                    v1162 = v1163
                end

                if not (v1165 < v1164) then
                    v1165 = v1164
                end

                if v1165 < 1.1754943508222875E-38 and v1165 > -1.1754943508222875E-38 and v1165 ~= 0 then
                    buffer.writeu32(v22, 0, to_bits(v1165))
                else
                    buffer.writef32(v22, 0, v1165)
                end

                local v1166 = buffer.readf32(v22, 0)

                if not (v1164 < v1162) then
                    v1162 = v1164
                end

                if v1162 < 1.1754943508222875E-38 and v1162 > -1.1754943508222875E-38 and v1162 ~= 0 then
                    buffer.writeu32(v22, 0, to_bits(v1162))
                else
                    buffer.writef32(v22, 0, v1162)
                end

                local v1167 = buffer.readf32(v22, 0)
                local v1168 = v1128 * v1157 + v1129 * v1159 + v1130 * v1161
                local v1169 = v1131 * v1157 + v1132 * v1159 + v1133 * v1161
                local v1170 = v1134 * v1157 + v1135 * v1159 + v1136 * v1161
                local v1171 = if v1168 < v1169 then v1168 else v1169

                if not (v1169 < v1168) then
                    v1168 = v1169
                end

                if not (v1170 < v1168) then
                    v1168 = v1170
                end

                if v1168 < 1.1754943508222875E-38 and v1168 > -1.1754943508222875E-38 and v1168 ~= 0 then
                    buffer.writeu32(v22, 0, to_bits(v1168))
                else
                    buffer.writef32(v22, 0, v1168)
                end

                local v1172 = v1166 - buffer.readf32(v22, 0)

                if not (v1171 < v1170) then
                    v1171 = v1170
                end

                if v1171 < 1.1754943508222875E-38 and v1171 > -1.1754943508222875E-38 and v1171 ~= 0 then
                    buffer.writeu32(v22, 0, to_bits(v1171))
                else
                    buffer.writef32(v22, 0, v1171)
                end

                local v1173 = buffer.readf32(v22, 0) - v1167

                if v1173 < v1172 then
                    if v1119 < v1172 then
                        if not (v1172 < 1.1754943508222875E-38) or not (v1172 > -1.1754943508222875E-38) or v1172 == 0 then
                            buffer.writef32(v22, 0, v1172)
                        else
                            buffer.writeu32(v22, 0, to_bits(v1172))
                        end

                        if p260 < buffer.readf32(v22, 0) then
                            return nil
                        end

                        v1152 = v1161
                        v1147 = v1172
                        v1148 = 1
                        v1149 = true
                        v1150 = v1157
                        v1151 = v1159
                    else
                        v1152 = n25
                        v1147 = v1119
                        v1148 = n22
                        v1149 = v1121
                        v1150 = n23
                        v1151 = n24
                    end
                elseif v1119 < v1173 then
                    if not (v1173 < 1.1754943508222875E-38) or not (v1173 > -1.1754943508222875E-38) or v1173 == 0 then
                        buffer.writef32(v22, 0, v1173)
                    else
                        buffer.writeu32(v22, 0, to_bits(v1173))
                    end

                    if p260 < buffer.readf32(v22, 0) then
                        return nil
                    end

                    v1152 = v1161
                    v1147 = v1173
                    v1148 = 1
                    v1149 = false
                    v1150 = v1157
                    v1151 = v1159
                else
                    v1152 = n25
                    v1147 = v1119
                    v1148 = n22
                    v1149 = v1121
                    v1150 = n23
                    v1151 = n24
                end
            else
                v1152 = n25
                v1147 = v1119
                v1148 = n22
                v1149 = v1121
                v1150 = n23
                v1151 = n24
            end

            n25 = v1152
            v1119 = v1147
            n22 = v1148
            v1121 = v1149
            n23 = v1150
            n24 = v1151
        end
    end

    local triangle = p249[p250 + 1].triangle
    local v1174 = p248[p250 + 1]

    if v1174 == nil then
        v1174 = pack({
            tag = "Triangle",
            triangle
        })
        p248[p250 + 1] = v1174
    end

    local contact_points_flat2 = contact_points_flat

    if v1119 < 1.1754943508222875E-38 and v1119 > -1.1754943508222875E-38 and v1119 ~= 0 then
        buffer.writeu32(v22, 0, to_bits(v1119))
    else
        buffer.writef32(v22, 0, v1119)
    end

    return contact_points_flat2(p251, "Triangle", v1174, "Triangle", triangle, buffer.readf32(v22, 0), direction_words(n22, v1121, if v1120 then v1174 else p251, 4, n23, n24, n25), p261, p262)
end

t1.triangle_triangle_contacts_flat_w1 = triangle_triangle_contacts_flat_w1

function t1.triangle_triangle_contacts_flat(p263, p264, p265, p266, p267, p268, p269, p270, p271, p272, p273, p274, p275, p276, p277, p278) -- line: 3199
    -- upvalues: fix_up_triangle (copy), pack (copy), v22 (copy), to_bits (copy), contact_points_flat (ref), v42 (copy), v131 (copy), v132 (copy), v133 (copy), v134 (copy), t6 (copy), t7 (copy), face_memo (copy), v281 (copy), v312 (copy), v314 (copy), fround2 (copy), v361 (ref), round3 (copy), fix_up_toward (copy), v542 (ref), direction_words (copy), v1066 (ref), triangle_face_pair (copy), triangle_triangle_contacts_flat_w1 (copy)
    if v361 then
        return triangle_triangle_contacts_flat_w1(p263, p264, p265, p266, p267, p268, p269, p270, p271, p272, p273, p274, p275, p276, p277, p278)
    end

    local v1177, v1178, v1179

    if p269 < p271 then
        v1177 = p271
        v1178 = true
        v1179 = p272
    else
        v1177 = p269
        v1178 = false
        v1179 = p270
    end

    local v1180 = p268[6]
    local v1181 = p268[7]
    local v1182 = p268[8]
    local v1183 = p268[9]
    local v1184 = p268[10]
    local v1185 = p268[11]
    local v1186 = p263[7]
    local v1187 = p263[8]
    local v1188 = p263[9]
    local v1189 = p263[10]
    local v1190 = p263[11]
    local v1191 = p263[12]
    local v1192 = p263[13]
    local v1193 = p263[14]
    local v1194 = p263[15]
    local n26 = 0
    local n27 = 0
    local n28 = 0
    local n29 = 0
    local v1195, v1196, v1197, v1198, v1199, v1200

    for i = 12, 18, 3 do
        v1195 = p268[i]
        v1196 = p268[i + 1]
        v1197 = p268[i + 2]

        for j = 24, 30, 3 do
            local v1201 = p263[j]
            local v1202 = p263[j + 1]
            local v1203 = p263[j + 2]
            local v1204 = -v1197 * v1202 + v1196 * v1203
            local v1205 = -v1195 * v1203 + v1197 * v1201

            v1203 = -v1196 * v1201 + v1195 * v1202
            v1202 = v1204 * v1204 + v1205 * v1205 + v1203 * v1203

            local v1206, v1207, v1208, v1209, v1210, v1211

            if v312 < v1202 then
                v1198 = 1 / math.sqrt(v1202)
                v1198 = v1198 * 0.5 * (-v1202 * (v1198 * v1198) + 1) + v1198
                v1198 = v1198 * 0.5 * (-v1202 * (v1198 * v1198) + 1) + v1198

                local v1212, v1213, v1214 = round3(v1204 * v1198, v1205 * v1198, v1203 * v1198)

                v1198 = p273 * v1212 + p274 * v1213 + p275 * v1214

                local v1215 = v1180 * v1212 + v1181 * v1213 + v1182 * v1214
                local v1216 = v1183 * v1212 + v1184 * v1213 + v1185 * v1214
                local v1217 = if v1198 < v1215 then v1198 else v1215
                local v1218 = if v1215 < v1198 then v1198 else v1215
                local v1219 = if v1217 < v1216 then v1217 else v1216

                if not (v1216 < v1218) then
                    v1218 = v1216
                end

                v1201 = v1186 * v1212 + v1187 * v1213 + v1188 * v1214

                local v1220 = v1189 * v1212 + v1190 * v1213 + v1191 * v1214
                local v1221 = v1192 * v1212 + v1193 * v1213 + v1194 * v1214

                v1200 = if v1201 < v1220 then v1201 else v1220

                if not (v1220 < v1201) then
                    v1201 = v1220
                end

                if not (v1221 < v1201) then
                    v1201 = v1221
                end

                local v1222, v1223

                v1222, v1199, v1223 = round3(v1219, v1218, v1201)

                local v1224 = v1222 - v1223

                if not (v1200 < v1221) then
                    v1200 = v1221
                end

                if v1200 < 1.1754943508222875E-38 and v1200 > -1.1754943508222875E-38 and v1200 ~= 0 then
                    buffer.writeu32(v22, 0, to_bits(v1200))
                else
                    buffer.writef32(v22, 0, v1200)
                end

                v1223 = buffer.readf32(v22, 0) - v1199

                if v1223 < v1224 then
                    if v1177 < v1224 then
                        if not (v1224 < 1.1754943508222875E-38) or not (v1224 > -1.1754943508222875E-38) or v1224 == 0 then
                            buffer.writef32(v22, 0, v1224)
                        else
                            buffer.writeu32(v22, 0, to_bits(v1224))
                        end

                        if p276 < buffer.readf32(v22, 0) then
                            return nil
                        end

                        v1210 = v1214
                        v1206 = v1224
                        v1207 = 1
                        v1211 = true
                        v1208 = v1212
                        v1209 = v1213
                    else
                        v1210 = n29
                        v1206 = v1177
                        v1207 = n26
                        v1211 = v1179
                        v1208 = n27
                        v1209 = n28
                    end
                elseif v1177 < v1223 then
                    if not (v1223 < 1.1754943508222875E-38) or not (v1223 > -1.1754943508222875E-38) or v1223 == 0 then
                        buffer.writef32(v22, 0, v1223)
                    else
                        buffer.writeu32(v22, 0, to_bits(v1223))
                    end

                    if p276 < buffer.readf32(v22, 0) then
                        return nil
                    end

                    v1210 = v1214
                    v1206 = v1223
                    v1207 = 1
                    v1211 = false
                    v1208 = v1212
                    v1209 = v1213
                else
                    v1210 = n29
                    v1206 = v1177
                    v1207 = n26
                    v1211 = v1179
                    v1208 = n27
                    v1209 = n28
                end
            else
                v1210 = n29
                v1206 = v1177
                v1207 = n26
                v1211 = v1179
                v1208 = n27
                v1209 = n28
            end

            n29 = v1210
            v1177 = v1206
            n26 = v1207
            v1179 = v1211
            n27 = v1208
            n28 = v1209
        end
    end

    local v1225, v1226, v1227

    if v1066 then
        local v1228, v1229, v1230

        if n26 == 0 then
            if v1178 then
                v1228 = p263[4]
                v1229 = p263[5]
                v1230 = p263[6]
            else
                v1228 = p268[1]
                v1229 = p268[2]
                v1230 = p268[3]
            end
        else
            v1230 = n29
            v1228 = n27
            v1229 = n28
        end

        if v1179 then
            v1228 = -v1228
            v1229 = -v1229
            v1230 = -v1230
        end

        v1195 = p263[4]
        v1196 = p263[5]
        v1197 = p263[6]

        local v1231 = -v1228 * v1195 + -v1229 * v1196 + -v1230 * v1197

        if math.abs(v1231) > v314 and not (math.abs(v1228 * p268[1] + v1229 * p268[2] + v1230 * p268[3]) > v314) then
            local v1232 = v1231 < 0

            v1197 = not v1232
            v1196 = if v1197 then 22 else 23
            v1195 = p263[v1196]

            local v1234, v1235

            if v1195 == false then
                v1198 = p265[p266 + 1].triangle
                v1234 = p264[p266 + 1]

                if v1234 == nil then
                    v1234 = pack({
                        tag = "Triangle",
                        v1198
                    })
                    p264[p266 + 1] = v1234
                end

                v1235 = face_memo(v1234, v1197)
                p263[v1196] = v1235
            else
                v1235 = v1195
            end

            if v1235 ~= 0 and v1235[31] == 3 then
                if not (v1177 < 1.1754943508222875E-38) or not (v1177 > -1.1754943508222875E-38) or v1177 == 0 then
                    buffer.writef32(v22, 0, v1177)
                else
                    buffer.writeu32(v22, 0, to_bits(v1177))
                end

                v1234 = buffer.readf32(v22, 0)

                if p276 < v1234 then
                    return nil
                end

                local v1236, v1237, v1238, v1239, v1240, v1241, v1242, v1243, v1244, v1245, v1246, v1247, v1248, v1249, v1250

                v1236, v1225, v1237, v1226, v1238, v1239, v1240, v1241, v1242, v1243, v1244, v1245, v1246, v1247, v1248, v1249, v1250 = triangle_face_pair(p263, v1235, p267, p268, p273, p274, p275, v1228, v1229, v1230)

                if v542 then
                    v1199 = v542
                    v1199.triangles = (v542.triangles or 0) + 1
                end

                local v1251, v1252, v1253
                local v1254 = v1237
                local v1255 = v1226
                local v1256 = v1238
                local v1257 = v1225

                if v1236 == 1 then
                    local v1258 = v1239 - v1242

                    v1251 = v1240 - v1243
                    v1252 = v1241 - v1244
                    v1200 = v1258 * v1258 + v1251 * v1251 + v1252 * v1252

                    if v1200 == 0 then
                        buffer.writef32(v22, 0, v1200)
                        v1253 = buffer.readf32(v22, 0)
                    elseif v1200 > -1.1754943508222875E-38 and v1200 < 1.1754943508222875E-38 then
                        v1253 = fround2(v1200)
                    else
                        buffer.writef32(v22, 0, v1200)
                        v1253 = buffer.readf32(v22, 0)
                    end

                    v1200 = 1 / math.sqrt(v1253)
                    v1200 = v1200 * 0.5 * (-v1253 * (v1200 * v1200) + 1) + v1200
                    v1200 = v1200 * 0.5 * (-v1253 * (v1200 * v1200) + 1) + v1200

                    if v1253 == 0 then
                        v1253 = 0
                    else
                        v1253 *= v1200
                    end

                    if v281 < v1253 then
                        v1254, v1255, v1256 = round3(v1258 * v1200, v1251 * v1200, v1252 * v1200)
                        v1257 = true
                    end
                end

                local v1259, v1260, v1261, v1262, v1263, v1266

                v1227 = v1228

                local v1264 = v1229
                local v1265 = v1230

                if v1257 then
                    v1259 = p273 * v1254 + p274 * v1255 + p275 * v1256
                    v1260 = v1180 * v1254 + v1181 * v1255 + v1182 * v1256
                    v1261 = v1183 * v1254 + v1184 * v1255 + v1185 * v1256
                    v1266 = if v1259 < v1260 then v1259 else v1260

                    if not (v1260 < v1259) then
                        v1259 = v1260
                    end

                    if not (v1266 < v1261) then
                        v1266 = v1261
                    end

                    if not (v1261 < v1259) then
                        v1259 = v1261
                    end

                    v1251 = v1186 * v1254 + v1187 * v1255 + v1188 * v1256
                    v1252 = v1189 * v1254 + v1190 * v1255 + v1191 * v1256
                    v1261 = v1192 * v1254 + v1193 * v1255 + v1194 * v1256

                    local v1267 = if v1251 < v1252 then v1251 else v1252

                    if not (v1252 < v1251) then
                        v1251 = v1252
                    end

                    if not (v1261 < v1251) then
                        v1251 = v1261
                    end

                    local v1268

                    v1268, v1262, v1263 = round3(v1266, v1259, v1251)

                    local v1269 = v1268 - v1263

                    if not (v1267 < v1261) then
                        v1267 = v1261
                    end

                    if v1267 < 1.1754943508222875E-38 and v1267 > -1.1754943508222875E-38 and v1267 ~= 0 then
                        buffer.writeu32(v22, 0, to_bits(v1267))
                    else
                        buffer.writef32(v22, 0, v1267)
                    end

                    v1263 = buffer.readf32(v22, 0) - v1262

                    if v1263 < v1269 then
                        if v1234 <= v1269 then
                            v1227 = -v1254
                            v1264 = -v1255
                            v1265 = -v1256
                        end
                    elseif v1234 <= v1263 then
                        v1265 = v1256
                        v1227 = v1254
                        v1264 = v1255
                    end
                end

                buffer.writeu32(v22, 0, p267[33])
                v1252 = buffer.readf32(v22, 0)
                v1226 = p263[16]
                v1259 = fix_up_toward(p263, -v1227, -v1264, -v1265, p278)

                if v1259 == 0 then
                    return nil
                end

                if v1259 == 1 then
                    v1259 = v1227 * v1252
                    v1260 = v1264 * v1252
                    v1261 = v1265 * v1252
                    v1266 = v1227 * v1226
                    v1253 = v1264 * v1226
                    v1254 = v1265 * v1226
                    v42[1] = v1242 + v1259
                    v42[2] = v1243 + v1260
                    v42[3] = v1244 + v1261
                    v42[4] = v1239 - v1266
                    v42[5] = v1240 - v1253
                    v42[6] = v1241 - v1254

                    if v1236 == 2 then
                        v42[7] = v1248 + v1259
                        v42[8] = v1249 + v1260
                        v42[9] = v1250 + v1261
                        v42[10] = v1245 - v1266
                        v42[11] = v1246 - v1253
                        v42[12] = v1247 - v1254
                    end

                    return v1236, -v1227, -v1264, -v1265
                end

                v1237 = v133[1]
                v1225 = v131[1]
                v1197 = v132[1]
                v1225.x = v1242
                v1225.y = v1243
                v1225.z = v1244
                v1197.x = v1239
                v1197.y = v1240
                v1197.z = v1241
                v1237.a = v1225
                v1237.b = v1197

                if v1236 == 2 then
                    v1237 = v133[2]
                    v1225 = v131[2]
                    v1197 = v132[2]
                    v1225.x = v1248
                    v1225.y = v1249
                    v1225.z = v1250
                    v1197.x = v1245
                    v1197.y = v1246
                    v1197.z = v1247
                    v1237.a = v1225
                    v1237.b = v1197
                end

                t6.x = v1227
                t6.y = v1264
                t6.z = v1265
                t7.edge_cos_bend_normal_threshold = p278.edge_cos_bend_normal_threshold
                t7.convexity_epsilon = p278.convexity_epsilon
                t7.is_object = p278.is_object

                if not fix_up_triangle(p265[p266 + 1].triangle.feature, t6, v134[v1236 + 1], t7) then
                    return nil
                end

                v1259 = t6.x
                v1260 = t6.y
                v1261 = t6.z
                v1266 = v1259 * v1252
                v1253 = v1260 * v1252
                v1254 = v1261 * v1252
                v1255 = v1259 * v1226
                v1256 = v1260 * v1226
                v1262 = v1261 * v1226

                for i = 0, v1236 - 1 do
                    v1237 = v133[i + 1]
                    v1225 = v1237.a
                    v1197 = v1237.b
                    v1250 = i * 6
                    v42[v1250 + 1] = v1225.x + v1266
                    v42[v1250 + 2] = v1225.y + v1253
                    v42[v1250 + 3] = v1225.z + v1254
                    v42[v1250 + 4] = v1197.x - v1255
                    v42[v1250 + 5] = v1197.y - v1256
                    v42[v1250 + 6] = v1197.z - v1262
                end

                return v1236, -v1259, -v1260, -v1261
            end
        end
    end

    v1194 = p265[p266 + 1].triangle
    v1193 = p264[p266 + 1]

    if v1193 == nil then
        v1193 = pack({
            tag = "Triangle",
            v1194
        })
        p264[p266 + 1] = v1193
    end

    v1227 = contact_points_flat

    if v1177 < 1.1754943508222875E-38 and v1177 > -1.1754943508222875E-38 and v1177 ~= 0 then
        buffer.writeu32(v22, 0, to_bits(v1177))
    else
        buffer.writef32(v22, 0, v1177)
    end

    v1225 = buffer.readf32(v22, 0)
    v1226 = if v1178 then v1193 else p267

    return v1227(p267, "Triangle", v1193, "Triangle", v1194, v1225, direction_words(n26, v1179, v1226, 4, n27, n28, n29), p277, p278)
end

function t1.box_triangle_rejects(p279, p280, p281, p282, p283, p284, p285) -- line: 3460
    -- upvalues: v22 (copy), to_bits (copy)
    local v1270 = p279[7]
    local v1271 = p279[8]
    local v1272 = p279[9]
    local v1273 = p279[10]
    local v1274 = p279[11]
    local v1275 = p279[12]
    local v1276 = p279[13]
    local v1277 = p279[14]
    local v1278 = p279[15]
    local v1279 = p280[1]
    local v1280 = p280[2]
    local v1281 = p280[3]
    local v1282 = p280[4]
    local v1283 = p280[5]
    local v1284 = p280[6]
    local v1285 = p280[7]
    local v1286 = p280[8]
    local v1287 = p280[9]
    local v1288 = p284

    for i = 1, 12 do
        local v1289, v1290, v1291

        if i <= 3 then
            local v1292 = 28 - i * 3

            v1289 = p280[v1292]
            v1290 = p280[v1292 + 1]
            v1291 = p280[v1292 + 2]
        else
            local v1293 = (i - 4) // 3
            local v1294 = (i - 4) % 3
            local v1295 = v1293 * 3 + 24
            local v1296 = p279[v1295]
            local v1297 = p279[v1295 + 1]
            local v1298 = p279[v1295 + 2]
            local v1299 = v1294 * 3 + 10
            local v1300 = p280[v1299]
            local v1301 = p280[v1299 + 1]
            local v1302 = p280[v1299 + 2]
            local v1303 = -v1298 * v1301 + v1297 * v1302
            local v1304 = -v1296 * v1302 + v1298 * v1300
            local v1305 = -v1297 * v1300 + v1296 * v1301
            local v1306 = v1303 * v1303 + v1304 * v1304 + v1305 * v1305
            local v1307 = 1 / math.sqrt(v1306)
            local v1308 = v1307 * 0.5 * (-v1306 * (v1307 * v1307) + 1) + v1307

            v1289 = v1303 * v1308
            v1290 = v1304 * v1308
            v1291 = v1305 * v1308
        end

        local v1309 = v1270 * v1289 + v1271 * v1290 + v1272 * v1291
        local v1310 = v1273 * v1289 + v1274 * v1290 + v1275 * v1291
        local v1311 = v1276 * v1289 + v1277 * v1290 + v1278 * v1291
        local v1312 = if v1310 < v1311 then v1310 else v1311

        if v1309 < v1312 then
            v1312 = v1309
        end

        if not (v1311 < v1310) then
            v1310 = v1311
        end

        if not (v1310 < v1309) then
            v1309 = v1310
        end

        local v1313 = p281 * v1289 + p282 * v1290 + p283 * v1291
        local v1319 = math.abs(v1279 * v1289 + v1280 * v1290 + v1281 * v1291) + math.abs(v1282 * v1289 + v1283 * v1290 + v1284 * v1291) + math.abs(v1285 * v1289 + v1286 * v1290 + v1287 * v1291)
        local v1320 = v1312 - (v1313 + v1319)
        local v1321 = v1313 - v1319 - v1309

        if not (v1321 < v1320) then
            v1320 = v1321
        end

        if v1288 < v1320 then
            if not (v1320 < 1.1754943508222875E-38) or not (v1320 > -1.1754943508222875E-38) or v1320 == 0 then
                buffer.writef32(v22, 0, v1320)
            else
                buffer.writeu32(v22, 0, to_bits(v1320))
            end

            if p285 < buffer.readf32(v22, 0) then
                return true
            end

            v1288 = v1320
        end
    end

    return false
end

function contact_points(p286, p287, p288, p289, p290, p291, p292, p293, p294) -- line: 3512
    -- upvalues: contact_points_flat (ref), v42 (copy)
    local v1322, v1323, v1324, v1325 = contact_points_flat(p286, p287, p288, p289, p290, p291, p292, p293, p294)

    if v1322 == nil then
        return nil
    end

    local v1326 = table.create(16)

    for i = 1, 16 do
        if i <= v1322 then
            local v1327 = (i - 1) * 6

            v1326[i] = {
                a = {
                    x = v42[v1327 + 1],
                    y = v42[v1327 + 2],
                    z = v42[v1327 + 3]
                },
                b = {
                    x = v42[v1327 + 4],
                    y = v42[v1327 + 5],
                    z = v42[v1327 + 6]
                }
            }
        else
            v1326[i] = {
                a = {
                    x = 0,
                    y = 0,
                    z = 0
                },
                b = {
                    x = 0,
                    y = 0,
                    z = 0
                }
            }
        end
    end

    return {
        normal = {
            x = v1323,
            y = v1324,
            z = v1325
        },
        points = v1326,
        count = v1322
    }
end

t1.contact_points = contact_points

function t1.maximum(p295, p296, p297, p298) -- line: 3542
    -- upvalues: maximum_into_reference (ref)
    local v1328 = table.create(144, 0)

    maximum_into_reference(v1328, p295, p296, p297, p298)

    return v1328
end

function maximum_into_reference(p299, p300, p301, p302, p303) -- line: 3549
    -- upvalues: box_maximum_feature (copy), capsule_maximum_feature (copy), triangle_maximum_feature (copy)
    if p301 == "Sphere" then
        p299[137] = p300[1]
        p299[138] = p300[2]
        p299[139] = p300[3]
        p299[140] = p300[4]
        p299[141] = 0
        p299[1] = 0
    elseif p301 == "Capsule" then
        capsule_maximum_feature(p300, p303, p299, table.create(16, 0))
    elseif p301 == "Triangle" then
        triangle_maximum_feature(p300, p302, p303, p299)
    elseif p301 == "Box" then
        box_maximum_feature(p300, p302, p303, p299, { 0, 0, 0, 0 })
    else
        error("unreachable: PrimitiveKind " .. tostring(p301), 0)
    end

    return p299
end

t1.maximum_into_reference = maximum_into_reference

local v1329 = table.create(16, 0)
local v1330 = table.create(16, 0)
local v1331 = table.freeze({ 0, 0, 0, 0 })

function maximum_into(p304, p305, p306, p307, p308) -- line: 3577
    -- upvalues: box_maximum_feature (copy), capsule_maximum_feature (copy), triangle_maximum_feature (copy), v1329 (copy), v1330 (copy), v1331 (copy)
    if p306 == "Sphere" then
        local v1332 = p305[1]
        local v1333 = p305[2]
        local v1334 = p305[3]
        local v1335 = p305[4]

        p304[137] = v1332
        p304[138] = v1333
        p304[139] = v1334
        p304[140] = v1335
        p304[141] = 0
        p304[1] = 0
    elseif p306 == "Capsule" then
        table.move(v1329, 1, 16, 1, v1330)
        capsule_maximum_feature(p305, p308, p304, v1330)
    elseif p306 == "Triangle" then
        triangle_maximum_feature(p305, p307, p308, p304)
    elseif p306 == "Box" then
        box_maximum_feature(p305, p307, p308, p304, v1331)
    else
        error("unreachable: PrimitiveKind " .. tostring(p306), 0)
    end

    return p304
end

t1.maximum_into = maximum_into

return t1
