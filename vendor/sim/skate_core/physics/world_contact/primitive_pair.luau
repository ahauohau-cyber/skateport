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
local v14 = import("skate_core/physics/world_contact/primitive_query")
local v15 = import("skate_core/physics/world_contact/box_box_sat")
local v16 = import("skate_core/physics/world_contact/triangle_box_sat")
local v17 = import("skate_core/physics/world_contact/primitive_geometry")
local v18 = import("skate_core/physics/world_contact/projection")
local v19 = import("skate_core/physics/world_contact/dispatch")
local v20 = import("skate_core/physics/world_contact/prism_math")
local Vector3 = v12.Vector3
local fix_up_triangle = v13.fix_up_triangle
local maximum = v14.maximum
local pack, xyz = v17.pack, v17.xyz
local best_separating_direction, project_direction = v18.best_separating_direction, v18.project_direction
local find_feature_intersection_prism = v19.find_feature_intersection_prism
local load, dot, sub, scale = v20.load, v20.dot, v20.sub, v20.scale
local inverse_length = v20.inverse_length

v20 = {
    PrimitivePairSettings = {}
}

function v20.PrimitivePairSettings.skater_self_collision() -- line: 87
    return {
        padding_a = 0.05000000074505806,
        padding_b = 0.05000000074505806,
        additional_padding = 0,
        edge_cos_bend_normal_threshold = 0.9990000128746033,
        convexity_epsilon = 0.009999999776482582
    }
end

local separating_direction

local function primitive_pair_contacts_reference(p5, p6, p7) -- line: 104
    -- upvalues: rt (copy), v1 (copy), Vector3 (copy), fix_up_triangle (copy), maximum (copy), pack (copy), xyz (copy), project_direction (copy), find_feature_intersection_prism (copy), load (copy), dot (copy), sub (copy), scale (copy), inverse_length (copy), separating_direction (ref)
    local v21, v22 = pack(p5)
    local v23, v24 = pack(p6)
    local v25, v26 = separating_direction(v21, v22, v23, v24)
    local v27 = p7.padding_b + p7.padding_a + p7.additional_padding

    buffer.writeu32(v1, 0, v21[33])

    local v29 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v23[33])

    local v31 = buffer.readf32(v1, 0)

    if v31 + v27 + v29 < v25 then
        return nil
    end

    local v32 = maximum(v21, v22, 1, v26)
    local v40 = maximum(v23, v24, 0, {
        bit32.bxor(v26[1], 2147483648),
        bit32.bxor(v26[2], 2147483648),
        bit32.bxor(v26[3], 2147483648),
        (bit32.bxor(v26[4], 2147483648))
    })
    local v41 = table.create(136, 0)

    if find_feature_intersection_prism(v41, v32, v40, v26) == 0 then
        return nil
    end

    local v42 = v41[133]

    buffer.writeu32(v1, 0, v26[1])

    local v44 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v26[2])

    local v46 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v26[3])

    local v48 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v26[4])

    local t1 = {
        v44,
        v46,
        v48,
        (buffer.readf32(v1, 0))
    }

    if v42 == 1 then
        local v50 = sub(load(v41, 64), load(v41, 0))
        local v51 = dot(v50, v50)
        local v52

        if v51 == 0 then
            buffer.writef32(v1, 0, v51)
            v52 = buffer.readf32(v1, 0)
        elseif v51 > -1.1754943508222875E-38 and v51 < 1.1754943508222875E-38 then
            local v53 = math.abs(v51) * 7.1362384635298E+44
            local v54 = math.floor(v53)
            local v55 = v53 - v54

            if v55 > 0.5 or v55 == 0.5 and v54 % 2 == 1 then
                v54 += 1
            end

            v52 = v54 * 1.401298464324817E-45

            if v51 < 0 then
                v52 = -v52
            end
        else
            buffer.writef32(v1, 0, v51)
            v52 = buffer.readf32(v1, 0)
        end

        local v56 = inverse_length(v52)

        if (if v52 == 0 then 0 else v52 * v56) > 1.1920928955078125E-07 then
            local v57 = scale(v50, v56)
            local v58 = v57[1]
            local v59

            if v58 == 0 then
                buffer.writef32(v1, 0, v58)
                v59 = buffer.readu32(v1, 0)
            elseif v58 > -1.1754943508222875E-38 and v58 < 1.1754943508222875E-38 then
                local v60 = math.abs(v58) * 7.1362384635298E+44

                v59 = math.floor(v60)

                local v61 = v60 - v59

                if v61 > 0.5 or v61 == 0.5 and v59 % 2 == 1 then
                    v59 += 1
                end

                if v58 < 0 then
                    v59 += 2147483648
                end
            else
                buffer.writef32(v1, 0, v58)
                v59 = buffer.readu32(v1, 0)
            end

            v41[129] = v59

            local v62 = v57[2]
            local v63

            if v62 ~= 0 and v62 > -1.1754943508222875E-38 and v62 < 1.1754943508222875E-38 then
                local v64 = math.abs(v62) * 7.1362384635298E+44
                local v65 = math.floor(v64)
                local v66 = v64 - v65

                v63 = if v66 > 0.5 or v66 == 0.5 and v65 % 2 == 1 then v65 + 1 else v65

                if v62 < 0 then
                    v63 += 2147483648
                end
            else
                buffer.writef32(v1, 0, v62)
                v63 = buffer.readu32(v1, 0)
            end

            v41[130] = v63

            local v67 = v57[3]
            local v68

            if v67 ~= 0 and v67 > -1.1754943508222875E-38 and v67 < 1.1754943508222875E-38 then
                local v69 = math.abs(v67) * 7.1362384635298E+44
                local v70 = math.floor(v69)
                local v71 = v69 - v70

                v68 = if v71 > 0.5 or v71 == 0.5 and v70 % 2 == 1 then v70 + 1 else v70

                if v67 < 0 then
                    v68 += 2147483648
                end
            else
                buffer.writef32(v1, 0, v67)
                v68 = buffer.readu32(v1, 0)
            end

            v41[131] = v68

            local v72 = v57[4]
            local v73

            if v72 ~= 0 and v72 > -1.1754943508222875E-38 and v72 < 1.1754943508222875E-38 then
                local v74 = math.abs(v72) * 7.1362384635298E+44
                local v75 = math.floor(v74)
                local v76 = v74 - v75

                v73 = if v76 > 0.5 or v76 == 0.5 and v75 % 2 == 1 then v75 + 1 else v75

                if v72 < 0 then
                    v73 += 2147483648
                end
            else
                buffer.writef32(v1, 0, v72)
                v73 = buffer.readu32(v1, 0)
            end

            v41[132] = v73
            v41[134] = 1
        end
    end

    if v41[134] ~= 0 then
        local v77 = rt.slice(v41, 128, 132)
        local v78 = table.create(12, 0)
        local v79 = table.create(12, 0)

        project_direction(v21, v22, v77, v78)
        project_direction(v23, v24, v77, v79)
        buffer.writeu32(v1, 0, v78[1])

        local v81 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v79[5])

        local v83 = v81 - buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v79[1])

        local v85 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v78[5])

        local v87 = v85 - buffer.readf32(v1, 0)
        local v88 = v87 < v83

        if not v88 then
            v83 = v87
        end

        if v25 <= v83 then
            for i = 1, 4 do
                buffer.writeu32(v1, 0, if v88 then bit32.bxor(v77[i], 2147483648) else v77[i])
                t1[i] = buffer.readf32(v1, 0)
            end
        end
    end

    local v91 = rt.filled(16, {
        a = rt.copy(Vector3.ZERO),
        b = rt.copy(Vector3.ZERO)
    })

    for i = 0, v42 - 1 do
        local v92 = v91[i + 1]

        v92.a = xyz(load(v41, i * 4))
        v92.b = xyz(load(v41, i * 4 + 64))
    end

    local v93 = xyz(t1)

    for _, v94 in {
            { p5, false },
            { p6, true }
        } do
        local v95 = v94[1]
        local v96 = v94[2]

        if v95.tag == "Triangle" then
            local v97 = v95[1]
            local v98 = table.create(v42)

            for j = 1, v42 do
                v98[j] = v91[j]
            end

            local v99 = fix_up_triangle(rt.copy(v97.feature), v93, v98, {
                is_object = false,
                reverse = v96,
                edge_cos_bend_normal_threshold = p7.edge_cos_bend_normal_threshold,
                convexity_epsilon = p7.convexity_epsilon
            })

            for k = 1, v42 do
                v91[k] = v98[k]
            end

            if not v99 then
                return nil
            end
        end
    end

    local t2 = {
        v93.x,
        v93.y,
        v93.z,
        t1[4]
    }
    local v100 = scale(t2, v29)
    local v101 = scale(t2, v31)

    for i = 1, v42 do
        local v102 = v91[i]

        v102.a = Vector3.new(v102.a.x + v100[1], v102.a.y + v100[2], v102.a.z + v100[3])
        v102.b = Vector3.new(v102.b.x - v101[1], v102.b.y - v101[2], v102.b.z - v101[3])
    end

    return {
        normal = Vector3.new(-v93.x, -v93.y, -v93.z),
        points = v91,
        count = v42
    }
end

function separating_direction(p8, p9, p10, p11) -- line: 223
    -- upvalues: rt (copy), v1 (copy), v15 (copy), v16 (copy), best_separating_direction (copy), load (copy), dot (copy), sub (copy), scale (copy), inverse_length (copy)
    local v103, v104

    if p9 == "Sphere" and p11 == "Sphere" then
        local v105 = sub(load(p10, 0), load(p8, 0))
        local v106 = dot(v105, v105)
        local v107

        if v106 == 0 then
            buffer.writef32(v1, 0, v106)
            v107 = buffer.readf32(v1, 0)
        elseif v106 > -1.1754943508222875E-38 and v106 < 1.1754943508222875E-38 then
            local v108 = math.abs(v106) * 7.1362384635298E+44
            local v109 = math.floor(v108)
            local v110 = v108 - v109

            if v110 > 0.5 or v110 == 0.5 and v109 % 2 == 1 then
                v109 += 1
            end

            v107 = v109 * 1.401298464324817E-45

            if v106 < 0 then
                v107 = -v107
            end
        else
            buffer.writef32(v1, 0, v106)
            v107 = buffer.readf32(v1, 0)
        end

        local v111 = inverse_length(v107)
        local v112 = if v107 == 0 then 0 else v107 * v111
        local filled = rt.filled
        local v113

        if v112 ~= 0 and v112 > -1.1754943508222875E-38 and v112 < 1.1754943508222875E-38 then
            local v114 = math.abs(v112) * 7.1362384635298E+44
            local v115 = math.floor(v114)
            local v116 = v114 - v115

            v113 = if v116 > 0.5 or v116 == 0.5 and v115 % 2 == 1 then v115 + 1 else v115

            if v112 < 0 then
                v113 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v112)
            v113 = buffer.readu32(v1, 0)
        end

        v103 = filled(4, v113)

        local v117 = scale(v105, v111)

        v104 = {}

        local v118 = v117[1]
        local v119

        if v118 ~= 0 and v118 > -1.1754943508222875E-38 and v118 < 1.1754943508222875E-38 then
            local v120 = math.abs(v118) * 7.1362384635298E+44
            local v121 = math.floor(v120)
            local v122 = v120 - v121

            v119 = if v122 > 0.5 or v122 == 0.5 and v121 % 2 == 1 then v121 + 1 else v121

            if v118 < 0 then
                v119 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v118)
            v119 = buffer.readu32(v1, 0)
        end

        local v123 = v117[2]
        local v124

        if v123 ~= 0 and v123 > -1.1754943508222875E-38 and v123 < 1.1754943508222875E-38 then
            local v125 = math.abs(v123) * 7.1362384635298E+44
            local v126 = math.floor(v125)
            local v127 = v125 - v126

            v124 = if v127 > 0.5 or v127 == 0.5 and v126 % 2 == 1 then v126 + 1 else v126

            if v123 < 0 then
                v124 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v123)
            v124 = buffer.readu32(v1, 0)
        end

        local v128 = v117[3]
        local v129

        if v128 ~= 0 and v128 > -1.1754943508222875E-38 and v128 < 1.1754943508222875E-38 then
            local v130 = math.abs(v128) * 7.1362384635298E+44
            local v131 = math.floor(v130)
            local v132 = v130 - v131

            v129 = if v132 > 0.5 or v132 == 0.5 and v131 % 2 == 1 then v131 + 1 else v131

            if v128 < 0 then
                v129 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v128)
            v129 = buffer.readu32(v1, 0)
        end

        local v133 = v117[4]
        local v134

        if v133 ~= 0 and v133 > -1.1754943508222875E-38 and v133 < 1.1754943508222875E-38 then
            local v135 = math.abs(v133) * 7.1362384635298E+44
            local v136 = math.floor(v135)
            local v137 = v135 - v136

            v134 = if v137 > 0.5 or v137 == 0.5 and v136 % 2 == 1 then v136 + 1 else v136

            if v133 < 0 then
                v134 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v133)
            v134 = buffer.readu32(v1, 0)
        end

        v104[1] = v119
        v104[2] = v124
        v104[3] = v129
        v104[4] = v134
    elseif p9 == "Box" and p11 == "Box" then
        v103, v104 = v15.box_box(p8, p10)
    elseif p9 == "Triangle" and p11 == "Box" then
        v103, v104 = v16.triangle_box(p8, p10)
    elseif p9 ~= "Box" or p11 ~= "Triangle" then
        v103, v104 = best_separating_direction(p8, p9, p10, p11)
    else
        local v138

        v103, v138 = v16.triangle_box(p10, p8)
        v104 = {
            bit32.bxor(v138[1], 2147483648),
            bit32.bxor(v138[2], 2147483648),
            bit32.bxor(v138[3], 2147483648),
            (bit32.bxor(v138[4], 2147483648))
        }
    end

    buffer.writeu32(v1, 0, v103[1])

    return buffer.readf32(v1, 0), v104
end

v20.separating_direction = separating_direction
v20.primitive_pair_contacts_reference = primitive_pair_contacts_reference

local v147 = buffer.create(8)

local function fb(p12) -- line: 263
    -- upvalues: v147 (copy)
    buffer.writeu32(v147, 0, p12)

    return (buffer.readf32(v147, 0))
end

local to_bits = rt.to_bits

local function tb(p13) -- line: 268
    -- upvalues: v147 (copy), to_bits (copy)
    if p13 ~= 0 and p13 > -1.1754943508222875E-38 and p13 < 1.1754943508222875E-38 then
        return to_bits(p13)
    end

    buffer.writef32(v147, 0, p13)

    return (buffer.readu32(v147, 0))
end

local best_separating_direction_into = v18.best_separating_direction_into
local maximum_into = v14.maximum_into

local function separating_direction_into(p14, p15, p16, p17, p18) -- line: 283
    -- upvalues: v1 (copy), v15 (copy), v16 (copy), inverse_length (copy), v147 (copy), to_bits (copy), best_separating_direction_into (copy)
    if p15 == "Sphere" and p17 == "Sphere" then
        buffer.writeu32(v147, 0, p16[1])

        local v149 = buffer.readf32(v147, 0)

        buffer.writeu32(v147, 0, p14[1])

        local v151 = v149 - buffer.readf32(v147, 0)

        buffer.writeu32(v147, 0, p16[2])

        local v153 = buffer.readf32(v147, 0)

        buffer.writeu32(v147, 0, p14[2])

        local v155 = v153 - buffer.readf32(v147, 0)

        buffer.writeu32(v147, 0, p16[3])

        local v157 = buffer.readf32(v147, 0)

        buffer.writeu32(v147, 0, p14[3])

        local v159 = v157 - buffer.readf32(v147, 0)

        buffer.writeu32(v147, 0, p16[4])

        local v161 = buffer.readf32(v147, 0)

        buffer.writeu32(v147, 0, p14[4])

        local v163 = v161 - buffer.readf32(v147, 0)
        local v164 = v151 * v151 + v155 * v155 + v159 * v159
        local v165

        if v164 == 0 then
            buffer.writef32(v1, 0, v164)
            v165 = buffer.readf32(v1, 0)
        elseif v164 > -1.1754943508222875E-38 and v164 < 1.1754943508222875E-38 then
            local v166 = math.abs(v164) * 7.1362384635298E+44
            local v167 = math.floor(v166)
            local v168 = v166 - v167

            if v168 > 0.5 or v168 == 0.5 and v167 % 2 == 1 then
                v167 += 1
            end

            v165 = v167 * 1.401298464324817E-45

            if v164 < 0 then
                v165 = -v165
            end
        else
            buffer.writef32(v1, 0, v164)
            v165 = buffer.readf32(v1, 0)
        end

        local v169 = inverse_length(v165)
        local v170 = if v165 == 0 then 0 else v165 * v169
        local v171

        if v170 ~= 0 and v170 > -1.1754943508222875E-38 and v170 < 1.1754943508222875E-38 then
            v171 = to_bits(v170)
        else
            buffer.writef32(v147, 0, v170)
            v171 = buffer.readu32(v147, 0)
        end

        local v172 = v151 * v169
        local v173

        if v172 ~= 0 and v172 > -1.1754943508222875E-38 and v172 < 1.1754943508222875E-38 then
            v173 = to_bits(v172)
        else
            buffer.writef32(v147, 0, v172)
            v173 = buffer.readu32(v147, 0)
        end

        local v174 = v155 * v169
        local v175

        if v174 ~= 0 and v174 > -1.1754943508222875E-38 and v174 < 1.1754943508222875E-38 then
            v175 = to_bits(v174)
        else
            buffer.writef32(v147, 0, v174)
            v175 = buffer.readu32(v147, 0)
        end

        local v176 = v159 * v169
        local v177

        if v176 ~= 0 and v176 > -1.1754943508222875E-38 and v176 < 1.1754943508222875E-38 then
            v177 = to_bits(v176)
        else
            buffer.writef32(v147, 0, v176)
            v177 = buffer.readu32(v147, 0)
        end

        local v178 = v163 * v169
        local v179

        if v178 ~= 0 and v178 > -1.1754943508222875E-38 and v178 < 1.1754943508222875E-38 then
            v179 = to_bits(v178)
        else
            buffer.writef32(v147, 0, v178)
            v179 = buffer.readu32(v147, 0)
        end

        p18[1] = v173
        p18[2] = v175
        p18[3] = v177
        p18[4] = v179
        buffer.writeu32(v147, 0, v171)

        return (buffer.readf32(v147, 0))
    end

    if p15 ~= "Box" or p17 ~= "Box" then
        if p15 ~= "Triangle" or p17 ~= "Box" then
            if p15 ~= "Box" or p17 ~= "Triangle" then
                buffer.writeu32(v147, 0, (best_separating_direction_into(p14, p15, p16, p17, p18)))

                return (buffer.readf32(v147, 0))
            end

            local v181 = v16.triangle_box_into(p16, p14, p18)

            p18[1] = bit32.bxor(p18[1], 2147483648)
            p18[2] = bit32.bxor(p18[2], 2147483648)
            p18[3] = bit32.bxor(p18[3], 2147483648)
            p18[4] = bit32.bxor(p18[4], 2147483648)
            buffer.writeu32(v147, 0, v181)

            return (buffer.readf32(v147, 0))
        end

        buffer.writeu32(v147, 0, (v16.triangle_box_into(p14, p16, p18)))

        return (buffer.readf32(v147, 0))
    end

    local v187, v188 = v15.box_box(p14, p16)
    local v189 = v188[1]
    local v190 = v188[2]
    local v191 = v188[3]
    local v192 = v188[4]

    p18[1] = v189
    p18[2] = v190
    p18[3] = v191
    p18[4] = v192
    buffer.writeu32(v147, 0, v187[1])

    return (buffer.readf32(v147, 0))
end

local v194 = true

function v20.set_pair_search(p19) -- line: 344
    -- upvalues: v194 (ref)
    local v195 = v194

    v194 = p19

    return v195
end

local fround = rt.fround

local function fr(p20) -- line: 350
    -- upvalues: v147 (copy), to_bits (copy)
    if p20 < 1.1754943508222875E-38 and p20 > -1.1754943508222875E-38 and p20 ~= 0 then
        buffer.writeu32(v147, 0, to_bits(p20))
    else
        buffer.writef32(v147, 0, p20)
    end

    return (buffer.readf32(v147, 0))
end

local function il(p21) -- line: 358
    local v196 = 1 / math.sqrt(p21)
    local v197 = v196 * 0.5 * (-p21 * (v196 * v196) + 1) + v196

    return v197 * 0.5 * (-p21 * (v197 * v197) + 1) + v197
end

buffer.writeu32(v147, 0, 981668463)

local v198 = buffer.readf32(v147, 0)

buffer.writeu32(v147, 0, 872415232)

local v199 = buffer.readf32(v147, 0)

local function appended(p22, p23, p24) -- line: 371
    -- upvalues: v147 (copy), to_bits (copy), fround (copy), v199 (copy)
    local v200 = fround(p22 * p22 + p23 * p23 + p24 * p24)
    local v201

    if v200 == 0 then
        v201 = 0
    else
        local v202 = 1 / math.sqrt(v200)
        local v203 = v202 * 0.5 * (-v200 * (v202 * v202) + 1) + v202

        v201 = v200 * (v203 * 0.5 * (-v200 * (v203 * v203) + 1) + v203)
    end

    if not (v199 < v201) then
        return nil, nil, nil
    end

    local v204 = p22 * p22 + p23 * p23 + p24 * p24
    local v205 = 1 / math.sqrt(v204)
    local v206 = v205 * 0.5 * (-v204 * (v205 * v205) + 1) + v205
    local v207 = v206 * 0.5 * (-v204 * (v206 * v206) + 1) + v206
    local v208 = p22 * v207

    if v208 < 1.1754943508222875E-38 and v208 > -1.1754943508222875E-38 and v208 ~= 0 then
        buffer.writeu32(v147, 0, to_bits(v208))
    else
        buffer.writef32(v147, 0, v208)
    end

    local v209 = buffer.readf32(v147, 0)
    local v210 = p23 * v207

    if v210 < 1.1754943508222875E-38 and v210 > -1.1754943508222875E-38 and v210 ~= 0 then
        buffer.writeu32(v147, 0, to_bits(v210))
    else
        buffer.writef32(v147, 0, v210)
    end

    local v211 = buffer.readf32(v147, 0)
    local v212 = p24 * v207

    if v212 < 1.1754943508222875E-38 and v212 > -1.1754943508222875E-38 and v212 ~= 0 then
        buffer.writeu32(v147, 0, to_bits(v212))
    else
        buffer.writef32(v147, 0, v212)
    end

    return v209, v211, (buffer.readf32(v147, 0))
end

local function fallback_candidate(p25, p26, p27, p28, p29, p30) -- line: 389
    -- upvalues: appended (copy)
    local v213 = -p27 * p29 + p26 * p30
    local v214 = -p25 * p30 + p27 * p28
    local v215 = -p26 * p28 + p25 * p29
    local v216, v217, v218 = appended(-v215 * p29 + v214 * p30, -v213 * p30 + v215 * p28, -v214 * p28 + v213 * p29)

    if v216 ~= nil then
        return v216, v217, v218
    end

    local v219, v220, v221 = appended(p25, p26, p27)

    if v219 == nil then
        return 0, 0, 1
    end

    return v219, v220, v221
end

local function finish(p31, p32, p33, p34, p35, p36) -- line: 405
    -- upvalues: v147 (copy), to_bits (copy)
    if p35 then
        local v222

        if p32 == 0 then
            buffer.writef32(v147, 0, p32)
            v222 = buffer.readu32(v147, 0)
        elseif p32 > -1.1754943508222875E-38 and p32 < 1.1754943508222875E-38 then
            v222 = to_bits(p32)
        else
            buffer.writef32(v147, 0, p32)
            v222 = buffer.readu32(v147, 0)
        end

        p31[1] = bit32.bxor(v222, 2147483648)

        local v223

        if p33 ~= 0 and p33 > -1.1754943508222875E-38 and p33 < 1.1754943508222875E-38 then
            v223 = to_bits(p33)
        else
            buffer.writef32(v147, 0, p33)
            v223 = buffer.readu32(v147, 0)
        end

        p31[2] = bit32.bxor(v223, 2147483648)

        local v224

        if p34 ~= 0 and p34 > -1.1754943508222875E-38 and p34 < 1.1754943508222875E-38 then
            v224 = to_bits(p34)
        else
            buffer.writef32(v147, 0, p34)
            v224 = buffer.readu32(v147, 0)
        end

        p31[3] = bit32.bxor(v224, 2147483648)
        p31[4] = 2147483648
    else
        local v225

        if p32 ~= 0 and p32 > -1.1754943508222875E-38 and p32 < 1.1754943508222875E-38 then
            v225 = to_bits(p32)
        else
            buffer.writef32(v147, 0, p32)
            v225 = buffer.readu32(v147, 0)
        end

        local v226

        if p33 ~= 0 and p33 > -1.1754943508222875E-38 and p33 < 1.1754943508222875E-38 then
            v226 = to_bits(p33)
        else
            buffer.writef32(v147, 0, p33)
            v226 = buffer.readu32(v147, 0)
        end

        local v227

        if p34 ~= 0 and p34 > -1.1754943508222875E-38 and p34 < 1.1754943508222875E-38 then
            v227 = to_bits(p34)
        else
            buffer.writef32(v147, 0, p34)
            v227 = buffer.readu32(v147, 0)
        end

        p31[1] = v225
        p31[2] = v226
        p31[3] = v227
        p31[4] = 0
    end

    if p36 < 1.1754943508222875E-38 and p36 > -1.1754943508222875E-38 and p36 ~= 0 then
        buffer.writeu32(v147, 0, to_bits(p36))
    else
        buffer.writef32(v147, 0, p36)
    end

    return (buffer.readf32(v147, 0))
end

local function pair_search(p37, p38, p39, p40, p41, p42) -- line: 417
    -- upvalues: v147 (copy), to_bits (copy), separating_direction_into (copy), fround (copy), v198 (copy), v199 (copy), fallback_candidate (copy), finish (copy)
    local v228 = p37[36]
    local v229 = p39[36]

    if p38 == "Triangle" then
        if v228 == 16973824 and (p40 == "Sphere" or p40 == "Capsule") then
            local v230 = p37[5]
            local v231 = p37[6]
            local v232 = p37[7]
            local v233 = p37[8]

            buffer.writeu32(v147, 0, v230)

            local v234 = buffer.readf32(v147, 0)

            buffer.writeu32(v147, 0, v231)

            local v235 = buffer.readf32(v147, 0)

            buffer.writeu32(v147, 0, v232)

            local v236 = buffer.readf32(v147, 0)

            buffer.writeu32(v147, 0, p37[1])

            local v238 = buffer.readf32(v147, 0)

            buffer.writeu32(v147, 0, p37[2])

            local v239 = buffer.readf32(v147, 0)

            buffer.writeu32(v147, 0, p37[3])

            local v240 = buffer.readf32(v147, 0)

            buffer.writeu32(v147, 0, p37[9])

            local v242 = buffer.readf32(v147, 0)

            buffer.writeu32(v147, 0, p37[10])

            local v243 = buffer.readf32(v147, 0)

            buffer.writeu32(v147, 0, p37[11])

            local v244 = buffer.readf32(v147, 0)

            buffer.writeu32(v147, 0, p37[13])

            local v246 = buffer.readf32(v147, 0)

            buffer.writeu32(v147, 0, p37[14])

            local v247 = buffer.readf32(v147, 0)

            buffer.writeu32(v147, 0, p37[15])

            local v248 = buffer.readf32(v147, 0)

            buffer.writeu32(v147, 0, p39[1])

            local v250 = buffer.readf32(v147, 0)

            buffer.writeu32(v147, 0, p39[2])

            local v251 = buffer.readf32(v147, 0)

            buffer.writeu32(v147, 0, p39[3])

            local v252 = buffer.readf32(v147, 0)
            local v249 = v238 * v234 + v239 * v235 + v240 * v236
            local v253 = v242 * v234 + v243 * v235 + v244 * v236
            local v254 = v246 * v234 + v247 * v235 + v248 * v236
            local v255 = if v249 < v253 then v249 else v253

            if not (v253 < v249) then
                v249 = v253
            end

            if not (v255 < v254) then
                v255 = v254
            end

            if v255 < 1.1754943508222875E-38 and v255 > -1.1754943508222875E-38 and v255 ~= 0 then
                buffer.writeu32(v147, 0, to_bits(v255))
            else
                buffer.writef32(v147, 0, v255)
            end

            local v256 = buffer.readf32(v147, 0)

            if not (v254 < v249) then
                v249 = v254
            end

            if v249 < 1.1754943508222875E-38 and v249 > -1.1754943508222875E-38 and v249 ~= 0 then
                buffer.writeu32(v147, 0, to_bits(v249))
            else
                buffer.writef32(v147, 0, v249)
            end

            local v257 = buffer.readf32(v147, 0)

            if p40 == "Sphere" then
                if v229 == 0 then
                    local v258 = v250 * v234 + v251 * v235 + v252 * v236

                    if not (v258 < 1.1754943508222875E-38) or not (v258 > -1.1754943508222875E-38) or v258 == 0 then
                        buffer.writef32(v147, 0, v258)
                    else
                        buffer.writeu32(v147, 0, to_bits(v258))
                    end

                    local v259 = buffer.readf32(v147, 0)

                    v258 = v256 - v259
                    v259 -= v257

                    if not (v259 < v258) then
                        p41[1] = v230
                        p41[2] = v231
                        p41[3] = v232
                        p41[4] = v233

                        if v259 < 1.1754943508222875E-38 and v259 > -1.1754943508222875E-38 and v259 ~= 0 then
                            buffer.writeu32(v147, 0, to_bits(v259))
                        else
                            buffer.writef32(v147, 0, v259)
                        end

                        return (buffer.readf32(v147, 0))
                    end

                    p41[1] = bit32.bxor(v230, 2147483648)
                    p41[2] = bit32.bxor(v231, 2147483648)
                    p41[3] = bit32.bxor(v232, 2147483648)
                    p41[4] = bit32.bxor(v233, 2147483648)

                    if not (v258 < 1.1754943508222875E-38) or not (v258 > -1.1754943508222875E-38) or v258 == 0 then
                        buffer.writef32(v147, 0, v258)
                    else
                        buffer.writeu32(v147, 0, to_bits(v258))
                    end

                    return (buffer.readf32(v147, 0))
                end
            elseif v229 == 65536 and p37[20] == 0 and p37[24] == 0 and p37[28] == 0 and p39[20] == 0 then
                buffer.writeu32(v147, 0, p39[17])

                local v261 = buffer.readf32(v147, 0)

                buffer.writeu32(v147, 0, p39[18])

                local v262 = buffer.readf32(v147, 0)

                buffer.writeu32(v147, 0, p39[19])

                local v263 = buffer.readf32(v147, 0)

                buffer.writeu32(v147, 0, p39[29])

                local v265 = buffer.readf32(v147, 0)
                local v264 = v250 * v234 + v251 * v235 + v252 * v236
                local v267 = math.abs(v261 * v234 + v262 * v235 + v263 * v236) * v265
                local v268 = v264 + v267

                if not (v268 < 1.1754943508222875E-38) or not (v268 > -1.1754943508222875E-38) or v268 == 0 then
                    buffer.writef32(v147, 0, v268)
                else
                    buffer.writeu32(v147, 0, to_bits(v268))
                end

                local v269 = v256 - buffer.readf32(v147, 0)
                local v270 = v264 - v267

                if v270 < 1.1754943508222875E-38 and v270 > -1.1754943508222875E-38 and v270 ~= 0 then
                    buffer.writeu32(v147, 0, to_bits(v270))
                else
                    buffer.writef32(v147, 0, v270)
                end

                local v266 = buffer.readf32(v147, 0) - v257

                v268 = v266 < v269

                if not v268 then
                    v269 = v266
                end

                if v269 == v269 then
                    if not (v269 < 1.1754943508222875E-38) or not (v269 > -1.1754943508222875E-38) or v269 == 0 then
                        buffer.writef32(v147, 0, v269)
                    else
                        buffer.writeu32(v147, 0, to_bits(v269))
                    end

                    if p42 < buffer.readf32(v147, 0) then
                        return nil
                    end

                    local v271 = false
                    local n1 = 0
                    local n2 = 0
                    local n3 = 0

                    for i = 17, 25, 4 do
                        buffer.writeu32(v147, 0, p37[i])

                        local v273 = buffer.readf32(v147, 0)

                        buffer.writeu32(v147, 0, p37[i + 1])

                        local v274 = buffer.readf32(v147, 0)

                        buffer.writeu32(v147, 0, p37[i + 2])

                        local v275 = buffer.readf32(v147, 0)
                        local v272 = -v275 * v262 + v274 * v263

                        v275 = -v273 * v263 + v275 * v261

                        local v276 = -v274 * v261 + v273 * v262
                        local v277 = v272 * v272 + v275 * v275 + v276 * v276
                        local v278, v279, v280, v281, v282, v283

                        if v198 < v277 then
                            local v284 = 1 / math.sqrt(v277)

                            v284 = v284 * 0.5 * (-v277 * (v284 * v284) + 1) + v284
                            v284 = v284 * 0.5 * (-v277 * (v284 * v284) + 1) + v284

                            local v285 = v272 * v284

                            if not (v285 < 1.1754943508222875E-38) or not (v285 > -1.1754943508222875E-38) or v285 == 0 then
                                buffer.writef32(v147, 0, v285)
                            else
                                buffer.writeu32(v147, 0, to_bits(v285))
                            end

                            local v286 = buffer.readf32(v147, 0)

                            v285 = v275 * v284

                            if v285 < 1.1754943508222875E-38 and v285 > -1.1754943508222875E-38 and v285 ~= 0 then
                                buffer.writeu32(v147, 0, to_bits(v285))
                            else
                                buffer.writef32(v147, 0, v285)
                            end

                            local v287 = buffer.readf32(v147, 0)

                            v285 = v276 * v284

                            if v285 < 1.1754943508222875E-38 and v285 > -1.1754943508222875E-38 and v285 ~= 0 then
                                buffer.writeu32(v147, 0, to_bits(v285))
                            else
                                buffer.writef32(v147, 0, v285)
                            end

                            local v288 = buffer.readf32(v147, 0)

                            v249 = v238 * v286 + v239 * v287 + v240 * v288
                            v253 = v242 * v286 + v243 * v287 + v244 * v288
                            v254 = v246 * v286 + v247 * v287 + v248 * v288

                            local v289 = if v249 < v253 then v249 else v253

                            if not (v253 < v249) then
                                v249 = v253
                            end

                            v264 = v250 * v286 + v251 * v287 + v252 * v288
                            v267 = math.abs(v261 * v286 + v262 * v287 + v263 * v288) * v265

                            if not (v289 < v254) then
                                v289 = v254
                            end

                            if v289 < 1.1754943508222875E-38 and v289 > -1.1754943508222875E-38 and v289 ~= 0 then
                                buffer.writeu32(v147, 0, to_bits(v289))
                            else
                                buffer.writef32(v147, 0, v289)
                            end

                            local v291 = buffer.readf32(v147, 0)
                            local v292 = v264 + v267

                            if v292 < 1.1754943508222875E-38 and v292 > -1.1754943508222875E-38 and v292 ~= 0 then
                                buffer.writeu32(v147, 0, to_bits(v292))
                            else
                                buffer.writef32(v147, 0, v292)
                            end

                            local v293 = v291 - buffer.readf32(v147, 0)

                            v289 = v264 - v267

                            if v289 < 1.1754943508222875E-38 and v289 > -1.1754943508222875E-38 and v289 ~= 0 then
                                buffer.writeu32(v147, 0, to_bits(v289))
                            else
                                buffer.writef32(v147, 0, v289)
                            end

                            v291 = buffer.readf32(v147, 0)

                            if not (v254 < v249) then
                                v249 = v254
                            end

                            if v249 < 1.1754943508222875E-38 and v249 > -1.1754943508222875E-38 and v249 ~= 0 then
                                buffer.writeu32(v147, 0, to_bits(v249))
                            else
                                buffer.writef32(v147, 0, v249)
                            end

                            v266 = v291 - buffer.readf32(v147, 0)

                            if v266 < v293 then
                                if v269 < v293 then
                                    if not (v293 < 1.1754943508222875E-38) or not (v293 > -1.1754943508222875E-38) or v293 == 0 then
                                        buffer.writef32(v147, 0, v293)
                                    else
                                        buffer.writeu32(v147, 0, to_bits(v293))
                                    end

                                    if p42 < buffer.readf32(v147, 0) then
                                        return nil
                                    end

                                    v283 = v288
                                    v278 = true
                                    v279 = v293
                                    v280 = true
                                    v281 = v286
                                    v282 = v287
                                else
                                    v283 = n3
                                    v278 = v268
                                    v279 = v269
                                    v280 = v271
                                    v281 = n1
                                    v282 = n2
                                end
                            elseif v269 < v266 then
                                if not (v266 < 1.1754943508222875E-38) or not (v266 > -1.1754943508222875E-38) or v266 == 0 then
                                    buffer.writef32(v147, 0, v266)
                                else
                                    buffer.writeu32(v147, 0, to_bits(v266))
                                end

                                if p42 < buffer.readf32(v147, 0) then
                                    return nil
                                end

                                v283 = v288
                                v278 = false
                                v279 = v266
                                v280 = true
                                v281 = v286
                                v282 = v287
                            else
                                v283 = n3
                                v278 = v268
                                v279 = v269
                                v280 = v271
                                v281 = n1
                                v282 = n2
                            end
                        else
                            v283 = n3
                            v278 = v268
                            v279 = v269
                            v280 = v271
                            v281 = n1
                            v282 = n2
                        end

                        n3 = v283
                        v268 = v278
                        v269 = v279
                        v271 = v280
                        n1 = v281
                        n2 = v282
                    end

                    if v271 then
                        return (finish(p41, n1, n2, n3, v268, v269))
                    end

                    if v268 then
                        p41[1] = bit32.bxor(v230, 2147483648)
                        p41[2] = bit32.bxor(v231, 2147483648)
                        p41[3] = bit32.bxor(v232, 2147483648)
                        p41[4] = bit32.bxor(v233, 2147483648)
                    else
                        p41[1] = v230
                        p41[2] = v231
                        p41[3] = v232
                        p41[4] = v233
                    end

                    if v269 < 1.1754943508222875E-38 and v269 > -1.1754943508222875E-38 and v269 ~= 0 then
                        buffer.writeu32(v147, 0, to_bits(v269))
                    else
                        buffer.writef32(v147, 0, v269)
                    end

                    return (buffer.readf32(v147, 0))
                end
            end
        end
    elseif p37[4] == 1065353216 and p39[4] == 1065353216 then
        if p38 == "Capsule" and v228 == 65536 and p37[20] == 0 then
            buffer.writeu32(v147, 0, p37[1])

            local v295 = buffer.readf32(v147, 0)

            buffer.writeu32(v147, 0, p37[2])

            local v296 = buffer.readf32(v147, 0)

            buffer.writeu32(v147, 0, p37[3])

            local v297 = buffer.readf32(v147, 0)

            buffer.writeu32(v147, 0, p37[17])

            local v299 = buffer.readf32(v147, 0)

            buffer.writeu32(v147, 0, p37[18])

            local v300 = buffer.readf32(v147, 0)

            buffer.writeu32(v147, 0, p37[19])

            local v301 = buffer.readf32(v147, 0)

            buffer.writeu32(v147, 0, p37[29])

            local v303 = buffer.readf32(v147, 0)

            buffer.writeu32(v147, 0, p39[1])

            local v305 = buffer.readf32(v147, 0)

            buffer.writeu32(v147, 0, p39[2])

            local v306 = buffer.readf32(v147, 0)

            buffer.writeu32(v147, 0, p39[3])

            local v307 = buffer.readf32(v147, 0)

            if p40 == "Sphere" then
                if v229 == 0 then
                    local v308, v309, v310 = fallback_candidate(v295 - v305, v296 - v306, v297 - v307, v299, v300, v301)
                    local v311 = v295 * v308 + v296 * v309 + v297 * v310
                    local v313 = math.abs(v299 * v308 + v300 * v309 + v301 * v310) * v303
                    local v312 = v305 * v308 + v306 * v309 + v307 * v310

                    if not (v312 < 1.1754943508222875E-38) or not (v312 > -1.1754943508222875E-38) or v312 == 0 then
                        buffer.writef32(v147, 0, v312)
                    else
                        buffer.writeu32(v147, 0, to_bits(v312))
                    end

                    local v314 = buffer.readf32(v147, 0)
                    local v315 = v311 - v313

                    if v315 < 1.1754943508222875E-38 and v315 > -1.1754943508222875E-38 and v315 ~= 0 then
                        buffer.writeu32(v147, 0, to_bits(v315))
                    else
                        buffer.writef32(v147, 0, v315)
                    end

                    v312 = buffer.readf32(v147, 0) - v314

                    local v316 = v311 + v313

                    if v316 < 1.1754943508222875E-38 and v316 > -1.1754943508222875E-38 and v316 ~= 0 then
                        buffer.writeu32(v147, 0, to_bits(v316))
                    else
                        buffer.writef32(v147, 0, v316)
                    end

                    v314 -= buffer.readf32(v147, 0)

                    local v317

                    if not (v314 < v312) then
                        if v308 ~= 0 and v308 > -1.1754943508222875E-38 and v308 < 1.1754943508222875E-38 then
                            v316 = to_bits(v308)
                        else
                            buffer.writef32(v147, 0, v308)
                            v316 = buffer.readu32(v147, 0)
                        end

                        if v309 ~= 0 and v309 > -1.1754943508222875E-38 and v309 < 1.1754943508222875E-38 then
                            v317 = to_bits(v309)
                        else
                            buffer.writef32(v147, 0, v309)
                            v317 = buffer.readu32(v147, 0)
                        end

                        local v318

                        if v310 ~= 0 and v310 > -1.1754943508222875E-38 and v310 < 1.1754943508222875E-38 then
                            v318 = to_bits(v310)
                        else
                            buffer.writef32(v147, 0, v310)
                            v318 = buffer.readu32(v147, 0)
                        end

                        p41[1] = v316
                        p41[2] = v317
                        p41[3] = v318
                        p41[4] = 0

                        if v314 < 1.1754943508222875E-38 and v314 > -1.1754943508222875E-38 and v314 ~= 0 then
                            buffer.writeu32(v147, 0, to_bits(v314))
                        else
                            buffer.writef32(v147, 0, v314)
                        end

                        return (buffer.readf32(v147, 0))
                    end

                    if v308 == 0 then
                        buffer.writef32(v147, 0, v308)
                        v317 = buffer.readu32(v147, 0)
                    elseif v308 > -1.1754943508222875E-38 and v308 < 1.1754943508222875E-38 then
                        v317 = to_bits(v308)
                    else
                        buffer.writef32(v147, 0, v308)
                        v317 = buffer.readu32(v147, 0)
                    end

                    p41[1] = bit32.bxor(v317, 2147483648)

                    if v309 ~= 0 and v309 > -1.1754943508222875E-38 and v309 < 1.1754943508222875E-38 then
                        v317 = to_bits(v309)
                    else
                        buffer.writef32(v147, 0, v309)
                        v317 = buffer.readu32(v147, 0)
                    end

                    p41[2] = bit32.bxor(v317, 2147483648)

                    if v310 ~= 0 and v310 > -1.1754943508222875E-38 and v310 < 1.1754943508222875E-38 then
                        v317 = to_bits(v310)
                    else
                        buffer.writef32(v147, 0, v310)
                        v317 = buffer.readu32(v147, 0)
                    end

                    p41[3] = bit32.bxor(v317, 2147483648)
                    p41[4] = 2147483648

                    if v312 < 1.1754943508222875E-38 and v312 > -1.1754943508222875E-38 and v312 ~= 0 then
                        buffer.writeu32(v147, 0, to_bits(v312))
                    else
                        buffer.writef32(v147, 0, v312)
                    end

                    return (buffer.readf32(v147, 0))
                end
            elseif p40 == "Capsule" and v229 == 65536 and p39[20] == 0 then
                buffer.writeu32(v147, 0, p39[17])

                local v320 = buffer.readf32(v147, 0)

                buffer.writeu32(v147, 0, p39[18])

                local v321 = buffer.readf32(v147, 0)

                buffer.writeu32(v147, 0, p39[19])

                local v322 = buffer.readf32(v147, 0)

                buffer.writeu32(v147, 0, p39[29])

                local v324 = buffer.readf32(v147, 0)
                local v323 = -v301 * v321 + v300 * v322
                local v325 = -v299 * v322 + v301 * v320
                local v326 = -v300 * v320 + v299 * v321
                local v327 = v323 * v323 + v325 * v325 + v326 * v326
                local v328 = fround(v323 * v323 + v325 * v325 + v326 * v326)
                local v329

                if v328 == 0 then
                    v329 = 0
                else
                    local v330 = 1 / math.sqrt(v328)

                    v330 = v330 * 0.5 * (-v328 * (v330 * v330) + 1) + v330
                    v329 = v328 * (v330 * 0.5 * (-v328 * (v330 * v330) + 1) + v330)
                end

                v328 = v199 < v329

                local n4 = 0
                local v331 = false
                local n5 = 0
                local n6 = 0
                local n7 = 0
                local n8 = 0
                local v332, v333, v334

                for i = 1, 3 do
                    local v335, v336, v337, v338, v339

                    if i == 1 then
                        if v198 < v327 then
                            local v340 = 1 / math.sqrt(v327)

                            v340 = v340 * 0.5 * (-v327 * (v340 * v340) + 1) + v340
                            v340 = v340 * 0.5 * (-v327 * (v340 * v340) + 1) + v340
                            v334 = v323 * v340

                            if not (v334 < 1.1754943508222875E-38) or not (v334 > -1.1754943508222875E-38) or v334 == 0 then
                                buffer.writef32(v147, 0, v334)
                            else
                                buffer.writeu32(v147, 0, to_bits(v334))
                            end

                            local v341 = buffer.readf32(v147, 0)

                            v334 = v325 * v340

                            if v334 < 1.1754943508222875E-38 and v334 > -1.1754943508222875E-38 and v334 ~= 0 then
                                buffer.writeu32(v147, 0, to_bits(v334))
                            else
                                buffer.writef32(v147, 0, v334)
                            end

                            local v342 = buffer.readf32(v147, 0)

                            v334 = v326 * v340

                            if v334 < 1.1754943508222875E-38 and v334 > -1.1754943508222875E-38 and v334 ~= 0 then
                                buffer.writeu32(v147, 0, to_bits(v334))
                            else
                                buffer.writef32(v147, 0, v334)
                            end

                            v332 = buffer.readf32(v147, 0)
                            v334 = v295 * v341 + v296 * v342 + v297 * v332

                            local v344 = math.abs(v299 * v341 + v300 * v342 + v301 * v332) * v303
                            local v345 = v305 * v341 + v306 * v342 + v307 * v332
                            local v343 = math.abs(v320 * v341 + v321 * v342 + v322 * v332) * v324
                            local v347 = v334 - v344

                            if v347 < 1.1754943508222875E-38 and v347 > -1.1754943508222875E-38 and v347 ~= 0 then
                                buffer.writeu32(v147, 0, to_bits(v347))
                            else
                                buffer.writef32(v147, 0, v347)
                            end

                            local v348 = buffer.readf32(v147, 0)
                            local v349 = v345 + v343

                            if v349 < 1.1754943508222875E-38 and v349 > -1.1754943508222875E-38 and v349 ~= 0 then
                                buffer.writeu32(v147, 0, to_bits(v349))
                            else
                                buffer.writef32(v147, 0, v349)
                            end

                            local v350 = v348 - buffer.readf32(v147, 0)

                            v348 = v345 - v343

                            if v348 < 1.1754943508222875E-38 and v348 > -1.1754943508222875E-38 and v348 ~= 0 then
                                buffer.writeu32(v147, 0, to_bits(v348))
                            else
                                buffer.writef32(v147, 0, v348)
                            end

                            local v351 = buffer.readf32(v147, 0)
                            local v352 = v334 + v344

                            if v352 < 1.1754943508222875E-38 and v352 > -1.1754943508222875E-38 and v352 ~= 0 then
                                buffer.writeu32(v147, 0, to_bits(v352))
                            else
                                buffer.writef32(v147, 0, v352)
                            end

                            local v346 = v351 - buffer.readf32(v147, 0)

                            v343 = v346 < v350

                            if not v343 then
                                v350 = v346
                            end

                            n8 += 1

                            if n8 == 1 then
                                if v350 ~= v350 then
                                    return (separating_direction_into(p37, p38, p39, p40, p41))
                                end

                                if not (v350 < 1.1754943508222875E-38) or not (v350 > -1.1754943508222875E-38) or v350 == 0 then
                                    buffer.writef32(v147, 0, v350)
                                else
                                    buffer.writeu32(v147, 0, to_bits(v350))
                                end

                                if p42 < buffer.readf32(v147, 0) then
                                    return nil
                                end

                                v339 = v332
                                v335 = v350
                                v336 = v343
                                v337 = v341
                                v338 = v342
                            elseif n4 < v350 then
                                if not (v350 < 1.1754943508222875E-38) or not (v350 > -1.1754943508222875E-38) or v350 == 0 then
                                    buffer.writef32(v147, 0, v350)
                                else
                                    buffer.writeu32(v147, 0, to_bits(v350))
                                end

                                if p42 < buffer.readf32(v147, 0) then
                                    return nil
                                end

                                v339 = v332
                                v335 = v350
                                v336 = v343
                                v337 = v341
                                v338 = v342
                            else
                                v339 = n7
                                v335 = n4
                                v336 = v331
                                v337 = n5
                                v338 = n6
                            end
                        else
                            v339 = n7
                            v335 = n4
                            v336 = v331
                            v337 = n5
                            v338 = n6
                        end
                    else
                        if not v328 then
                            break
                        end

                        local v353, v354, v355, v356, v357

                        if i == 2 then
                            v334 = -v301 * v325 + v300 * v326
                            v333 = -v299 * v326 + v301 * v323

                            local v358 = -v300 * v323 + v299 * v325

                            v357 = v334 * v334 + v333 * v333 + v358 * v358

                            local v359 = 1 / math.sqrt(v357)

                            v359 = v359 * 0.5 * (-v357 * (v359 * v359) + 1) + v359
                            v359 = v359 * 0.5 * (-v357 * (v359 * v359) + 1) + v359
                            v357 = v334 * v359

                            if not (v357 < 1.1754943508222875E-38) or not (v357 > -1.1754943508222875E-38) or v357 == 0 then
                                buffer.writef32(v147, 0, v357)
                            else
                                buffer.writeu32(v147, 0, to_bits(v357))
                            end

                            v354 = buffer.readf32(v147, 0)
                            v357 = v333 * v359

                            if v357 < 1.1754943508222875E-38 and v357 > -1.1754943508222875E-38 and v357 ~= 0 then
                                buffer.writeu32(v147, 0, to_bits(v357))
                            else
                                buffer.writef32(v147, 0, v357)
                            end

                            v355 = buffer.readf32(v147, 0)
                            v357 = v358 * v359
                        else
                            v334 = -v322 * v325 + v321 * v326
                            v355 = -v320 * v326 + v322 * v323
                            v353 = -v321 * v323 + v320 * v325
                            v357 = v334 * v334 + v355 * v355 + v353 * v353
                            v356 = 1 / math.sqrt(v357)
                            v356 = v356 * 0.5 * (-v357 * (v356 * v356) + 1) + v356
                            v356 = v356 * 0.5 * (-v357 * (v356 * v356) + 1) + v356
                            v357 = v334 * v356

                            if v357 < 1.1754943508222875E-38 and v357 > -1.1754943508222875E-38 and v357 ~= 0 then
                                buffer.writeu32(v147, 0, to_bits(v357))
                            else
                                buffer.writef32(v147, 0, v357)
                            end

                            v354 = buffer.readf32(v147, 0)
                            v357 = v355 * v356

                            if v357 < 1.1754943508222875E-38 and v357 > -1.1754943508222875E-38 and v357 ~= 0 then
                                buffer.writeu32(v147, 0, to_bits(v357))
                            else
                                buffer.writef32(v147, 0, v357)
                            end

                            v355 = buffer.readf32(v147, 0)
                            v357 = v353 * v356
                        end

                        if v357 < 1.1754943508222875E-38 and v357 > -1.1754943508222875E-38 and v357 ~= 0 then
                            buffer.writeu32(v147, 0, to_bits(v357))
                        else
                            buffer.writef32(v147, 0, v357)
                        end

                        v332 = buffer.readf32(v147, 0)
                        v334 = v295 * v354 + v296 * v355 + v297 * v332

                        local v360 = math.abs(v299 * v354 + v300 * v355 + v301 * v332) * v303

                        v353 = v305 * v354 + v306 * v355 + v307 * v332
                        v356 = math.abs(v320 * v354 + v321 * v355 + v322 * v332) * v324

                        local v362 = v334 - v360

                        if not (v362 < 1.1754943508222875E-38) or not (v362 > -1.1754943508222875E-38) or v362 == 0 then
                            buffer.writef32(v147, 0, v362)
                        else
                            buffer.writeu32(v147, 0, to_bits(v362))
                        end

                        local v363 = buffer.readf32(v147, 0)
                        local v364 = v353 + v356

                        if not (v364 < 1.1754943508222875E-38) or not (v364 > -1.1754943508222875E-38) or v364 == 0 then
                            buffer.writef32(v147, 0, v364)
                        else
                            buffer.writeu32(v147, 0, to_bits(v364))
                        end

                        v357 = v363 - buffer.readf32(v147, 0)
                        v363 = v353 - v356

                        if not (v363 < 1.1754943508222875E-38) or not (v363 > -1.1754943508222875E-38) or v363 == 0 then
                            buffer.writef32(v147, 0, v363)
                        else
                            buffer.writeu32(v147, 0, to_bits(v363))
                        end

                        local v365 = buffer.readf32(v147, 0)
                        local v366 = v334 + v360

                        if not (v366 < 1.1754943508222875E-38) or not (v366 > -1.1754943508222875E-38) or v366 == 0 then
                            buffer.writef32(v147, 0, v366)
                        else
                            buffer.writeu32(v147, 0, to_bits(v366))
                        end

                        local v361 = v365 - buffer.readf32(v147, 0)

                        v356 = v361 < v357

                        if not v356 then
                            v357 = v361
                        end

                        n8 += 1

                        if n8 == 1 then
                            if v357 ~= v357 then
                                return (separating_direction_into(p37, p38, p39, p40, p41))
                            end

                            if not (v357 < 1.1754943508222875E-38) or not (v357 > -1.1754943508222875E-38) or v357 == 0 then
                                buffer.writef32(v147, 0, v357)
                            else
                                buffer.writeu32(v147, 0, to_bits(v357))
                            end

                            if p42 < buffer.readf32(v147, 0) then
                                return nil
                            end

                            v339 = v332
                            v335 = v357
                            v336 = v356
                            v337 = v354
                            v338 = v355
                        elseif n4 < v357 then
                            if not (v357 < 1.1754943508222875E-38) or not (v357 > -1.1754943508222875E-38) or v357 == 0 then
                                buffer.writef32(v147, 0, v357)
                            else
                                buffer.writeu32(v147, 0, to_bits(v357))
                            end

                            if p42 < buffer.readf32(v147, 0) then
                                return nil
                            end

                            v339 = v332
                            v335 = v357
                            v336 = v356
                            v337 = v354
                            v338 = v355
                        else
                            v339 = n7
                            v335 = n4
                            v336 = v331
                            v337 = n5
                            v338 = n6
                        end
                    end

                    n7 = v339
                    n4 = v335
                    v331 = v336
                    n5 = v337
                    n6 = v338
                end

                if n8 ~= 0 then
                    return (finish(p41, n5, n6, n7, v331, n4))
                end

                local v367, v368, v369 = fallback_candidate(v295 - v305, v296 - v306, v297 - v307, v299, v300, v301)
                local v370 = v295 * v367 + v296 * v368 + v297 * v369
                local v372 = math.abs(v299 * v367 + v300 * v368 + v301 * v369) * v303
                local v373 = v305 * v367 + v306 * v368 + v307 * v369
                local v374 = math.abs(v320 * v367 + v321 * v368 + v322 * v369) * v324
                local v371 = v370 - v372

                if not (v371 < 1.1754943508222875E-38) or not (v371 > -1.1754943508222875E-38) or v371 == 0 then
                    buffer.writef32(v147, 0, v371)
                else
                    buffer.writeu32(v147, 0, to_bits(v371))
                end

                v332 = buffer.readf32(v147, 0)

                local v375 = v373 + v374

                if v375 < 1.1754943508222875E-38 and v375 > -1.1754943508222875E-38 and v375 ~= 0 then
                    buffer.writeu32(v147, 0, to_bits(v375))
                else
                    buffer.writef32(v147, 0, v375)
                end

                v320 = v332 - buffer.readf32(v147, 0)
                v332 = v373 - v374

                if v332 < 1.1754943508222875E-38 and v332 > -1.1754943508222875E-38 and v332 ~= 0 then
                    buffer.writeu32(v147, 0, to_bits(v332))
                else
                    buffer.writef32(v147, 0, v332)
                end

                v334 = buffer.readf32(v147, 0)

                local v376 = v370 + v372

                if v376 < 1.1754943508222875E-38 and v376 > -1.1754943508222875E-38 and v376 ~= 0 then
                    buffer.writeu32(v147, 0, to_bits(v376))
                else
                    buffer.writef32(v147, 0, v376)
                end

                local v377 = v334 - buffer.readf32(v147, 0)
                local v378

                if not (v377 < v320) then
                    if v367 ~= 0 and v367 > -1.1754943508222875E-38 and v367 < 1.1754943508222875E-38 then
                        v332 = to_bits(v367)
                    else
                        buffer.writef32(v147, 0, v367)
                        v332 = buffer.readu32(v147, 0)
                    end

                    if v368 ~= 0 and v368 > -1.1754943508222875E-38 and v368 < 1.1754943508222875E-38 then
                        v378 = to_bits(v368)
                    else
                        buffer.writef32(v147, 0, v368)
                        v378 = buffer.readu32(v147, 0)
                    end

                    if v369 ~= 0 and v369 > -1.1754943508222875E-38 and v369 < 1.1754943508222875E-38 then
                        v333 = to_bits(v369)
                    else
                        buffer.writef32(v147, 0, v369)
                        v333 = buffer.readu32(v147, 0)
                    end

                    p41[1] = v332
                    p41[2] = v378
                    p41[3] = v333
                    p41[4] = 0

                    if v377 < 1.1754943508222875E-38 and v377 > -1.1754943508222875E-38 and v377 ~= 0 then
                        buffer.writeu32(v147, 0, to_bits(v377))
                    else
                        buffer.writef32(v147, 0, v377)
                    end

                    return (buffer.readf32(v147, 0))
                end

                if v367 == 0 then
                    buffer.writef32(v147, 0, v367)
                    v378 = buffer.readu32(v147, 0)
                elseif v367 > -1.1754943508222875E-38 and v367 < 1.1754943508222875E-38 then
                    v378 = to_bits(v367)
                else
                    buffer.writef32(v147, 0, v367)
                    v378 = buffer.readu32(v147, 0)
                end

                p41[1] = bit32.bxor(v378, 2147483648)

                if v368 ~= 0 and v368 > -1.1754943508222875E-38 and v368 < 1.1754943508222875E-38 then
                    v378 = to_bits(v368)
                else
                    buffer.writef32(v147, 0, v368)
                    v378 = buffer.readu32(v147, 0)
                end

                p41[2] = bit32.bxor(v378, 2147483648)

                if v369 ~= 0 and v369 > -1.1754943508222875E-38 and v369 < 1.1754943508222875E-38 then
                    v378 = to_bits(v369)
                else
                    buffer.writef32(v147, 0, v369)
                    v378 = buffer.readu32(v147, 0)
                end

                p41[3] = bit32.bxor(v378, 2147483648)
                p41[4] = 2147483648

                if v320 < 1.1754943508222875E-38 and v320 > -1.1754943508222875E-38 and v320 ~= 0 then
                    buffer.writeu32(v147, 0, to_bits(v320))
                else
                    buffer.writef32(v147, 0, v320)
                end

                return (buffer.readf32(v147, 0))
            end
        elseif p38 == "Sphere" and v228 == 0 and p40 == "Capsule" and v229 == 65536 and p39[20] == 0 then
            buffer.writeu32(v147, 0, p37[1])

            local v380 = buffer.readf32(v147, 0)

            buffer.writeu32(v147, 0, p37[2])

            local v381 = buffer.readf32(v147, 0)

            buffer.writeu32(v147, 0, p37[3])

            local v382 = buffer.readf32(v147, 0)

            buffer.writeu32(v147, 0, p39[1])

            local v384 = buffer.readf32(v147, 0)

            buffer.writeu32(v147, 0, p39[2])

            local v385 = buffer.readf32(v147, 0)

            buffer.writeu32(v147, 0, p39[3])

            local v386 = buffer.readf32(v147, 0)

            buffer.writeu32(v147, 0, p39[17])

            local v388 = buffer.readf32(v147, 0)

            buffer.writeu32(v147, 0, p39[18])

            local v389 = buffer.readf32(v147, 0)
            local v387 = p39[19]

            buffer.writeu32(v147, 0, v387)

            local v390 = buffer.readf32(v147, 0)
            local v391, v392

            v387, v392, v391 = fallback_candidate(v380 - v384, v381 - v385, v382 - v386, v388, v389, v390)

            local v393 = v380 * v387 + v381 * v392 + v382 * v391

            if not (v393 < 1.1754943508222875E-38) or not (v393 > -1.1754943508222875E-38) or v393 == 0 then
                buffer.writef32(v147, 0, v393)
            else
                buffer.writeu32(v147, 0, to_bits(v393))
            end

            local v394 = buffer.readf32(v147, 0)
            local v395 = v384 * v387 + v385 * v392 + v386 * v391

            v393 = math.abs(v388 * v387 + v389 * v392 + v390 * v391)
            buffer.writeu32(v147, 0, p39[29])

            local v398 = v393 * buffer.readf32(v147, 0)
            local v396 = v395 + v398

            if v396 < 1.1754943508222875E-38 and v396 > -1.1754943508222875E-38 and v396 ~= 0 then
                buffer.writeu32(v147, 0, to_bits(v396))
            else
                buffer.writef32(v147, 0, v396)
            end

            local v399 = v394 - buffer.readf32(v147, 0)

            v396 = v395 - v398

            if v396 < 1.1754943508222875E-38 and v396 > -1.1754943508222875E-38 and v396 ~= 0 then
                buffer.writeu32(v147, 0, to_bits(v396))
            else
                buffer.writef32(v147, 0, v396)
            end

            v384 = buffer.readf32(v147, 0) - v394

            local v400

            if not (v384 < v399) then
                if v387 ~= 0 and v387 > -1.1754943508222875E-38 and v387 < 1.1754943508222875E-38 then
                    v394 = to_bits(v387)
                else
                    buffer.writef32(v147, 0, v387)
                    v394 = buffer.readu32(v147, 0)
                end

                if v392 ~= 0 and v392 > -1.1754943508222875E-38 and v392 < 1.1754943508222875E-38 then
                    v400 = to_bits(v392)
                else
                    buffer.writef32(v147, 0, v392)
                    v400 = buffer.readu32(v147, 0)
                end

                local v401

                if v391 ~= 0 and v391 > -1.1754943508222875E-38 and v391 < 1.1754943508222875E-38 then
                    v401 = to_bits(v391)
                else
                    buffer.writef32(v147, 0, v391)
                    v401 = buffer.readu32(v147, 0)
                end

                p41[1] = v394
                p41[2] = v400
                p41[3] = v401
                p41[4] = 0

                if v384 < 1.1754943508222875E-38 and v384 > -1.1754943508222875E-38 and v384 ~= 0 then
                    buffer.writeu32(v147, 0, to_bits(v384))
                else
                    buffer.writef32(v147, 0, v384)
                end

                return (buffer.readf32(v147, 0))
            end

            if v387 == 0 then
                buffer.writef32(v147, 0, v387)
                v400 = buffer.readu32(v147, 0)
            elseif v387 > -1.1754943508222875E-38 and v387 < 1.1754943508222875E-38 then
                v400 = to_bits(v387)
            else
                buffer.writef32(v147, 0, v387)
                v400 = buffer.readu32(v147, 0)
            end

            p41[1] = bit32.bxor(v400, 2147483648)

            if v392 ~= 0 and v392 > -1.1754943508222875E-38 and v392 < 1.1754943508222875E-38 then
                v400 = to_bits(v392)
            else
                buffer.writef32(v147, 0, v392)
                v400 = buffer.readu32(v147, 0)
            end

            p41[2] = bit32.bxor(v400, 2147483648)

            if v391 ~= 0 and v391 > -1.1754943508222875E-38 and v391 < 1.1754943508222875E-38 then
                v400 = to_bits(v391)
            else
                buffer.writef32(v147, 0, v391)
                v400 = buffer.readu32(v147, 0)
            end

            p41[3] = bit32.bxor(v400, 2147483648)
            p41[4] = 2147483648

            if v399 < 1.1754943508222875E-38 and v399 > -1.1754943508222875E-38 and v399 ~= 0 then
                buffer.writeu32(v147, 0, to_bits(v399))
            else
                buffer.writef32(v147, 0, v399)
            end

            return (buffer.readf32(v147, 0))
        end
    end

    return (separating_direction_into(p37, p38, p39, p40, p41))
end

v20.pair_search = pair_search
buffer.writeu32(v147, 0, 1064514355)

local v402 = buffer.readf32(v147, 0)
local fix_up_toward = v14.fix_up_toward
local v403 = table.create(49, 0)

local function plane_of(p43, p44, p45, p46, p47, p48) -- line: 673
    -- upvalues: v147 (copy), to_bits (copy), v199 (copy)
    local v404 = -p45 * p47 + p44 * p48
    local v405 = -p43 * p48 + p45 * p46
    local v406 = -p44 * p46 + p43 * p47
    local v407 = v404 * v404 + v405 * v405 + v406 * v406
    local v408 = 1 / math.sqrt(v407)
    local v409 = v408 * 0.5 * (-v407 * (v408 * v408) + 1) + v408

    if not (v199 < v407) then
        v409 = 0
    end

    local v410 = v404 * v409

    if v410 < 1.1754943508222875E-38 and v410 > -1.1754943508222875E-38 and v410 ~= 0 then
        buffer.writeu32(v147, 0, to_bits(v410))
    else
        buffer.writef32(v147, 0, v410)
    end

    local v411 = buffer.readf32(v147, 0)
    local v412 = v405 * v409

    if v412 < 1.1754943508222875E-38 and v412 > -1.1754943508222875E-38 and v412 ~= 0 then
        buffer.writeu32(v147, 0, to_bits(v412))
    else
        buffer.writef32(v147, 0, v412)
    end

    local v413 = buffer.readf32(v147, 0)
    local v414 = v406 * v409

    if v414 < 1.1754943508222875E-38 and v414 > -1.1754943508222875E-38 and v414 ~= 0 then
        buffer.writeu32(v147, 0, to_bits(v414))
    else
        buffer.writef32(v147, 0, v414)
    end

    return v411, v413, (buffer.readf32(v147, 0))
end

local triangle_sphere_pair

buffer.writeu32(v147, 0, 1028443341)

local v415 = buffer.readf32(v147, 0)
local capsule_floats, closest_segment_xyz = v14.capsule_floats, v14.closest_segment_xyz
local v416 = table.create(15, 0)
local capsule_sphere_pair
local v417 = table.create(144, 0)
local v418 = table.create(144, 0)
local v419 = table.create(144, 0)
local v420 = table.create(136, 0)
local t3 = {
    0, 0, 0, 0
}
local t4 = {
    0, 0, 0, 0
}
local t5 = {
    0, 0, 0, 0
}
local v421 = table.create(12, 0)
local v422 = table.create(12, 0)
local v423 = table.create(96, 0)

v20.flat_points = v423

local v424 = table.create(16)
local v425 = table.create(16)
local v426 = table.create(16)
local v427 = table.create(17)

for i = 1, 16 do
    v424[i] = {
        x = 0,
        y = 0,
        z = 0
    }
    v425[i] = {
        x = 0,
        y = 0,
        z = 0
    }
    v426[i] = {
        a = v424[i],
        b = v425[i]
    }
end

for i = 0, 16 do
    local v428 = table.create(i)

    for j = 1, i do
        v428[j] = v426[j]
    end

    v427[i + 1] = v428
end

local t6 = {
    x = 0,
    y = 0,
    z = 0
}
local t7 = {
    reverse = false,
    edge_cos_bend_normal_threshold = 0,
    convexity_epsilon = 0,
    is_object = false
}

local function primitive_pair_contacts_flat(p49, p50, p51, p52, p53, p54, p55) -- line: 756
    -- upvalues: v1 (copy), fix_up_triangle (copy), project_direction (copy), find_feature_intersection_prism (copy), inverse_length (copy), v147 (copy), to_bits (copy), maximum_into (copy), separating_direction_into (copy), v194 (ref), pair_search (copy), triangle_sphere_pair (ref), capsule_sphere_pair (ref), v417 (copy), v418 (copy), v419 (copy), v420 (copy), t3 (copy), t4 (copy), t5 (copy), v421 (copy), v422 (copy), v423 (copy), v424 (copy), v425 (copy), v426 (copy), v427 (copy), t6 (copy), t7 (copy)
    local v429 = p55.padding_b + p55.padding_a + p55.additional_padding

    buffer.writeu32(v147, 0, p49[33])

    local v431 = buffer.readf32(v147, 0)

    buffer.writeu32(v147, 0, p51[33])

    local v433 = buffer.readf32(v147, 0)
    local v432 = v433 + v429 + v431
    local v434 = v194
    local v435, v436, v437

    if v434 then
        v435 = pair_search(p49, p50, p51, p52, t3, v432)
        v436 = v435 == nil
    else
        v437 = separating_direction_into(p49, p50, p51, p52, t3)
    end

    if (not v434 or v436) and v434 then
        return nil
    end

    if not v434 then
        v435 = v437
    end

    if v432 < v435 then
        return nil
    end

    local v438, v439, v440

    if v194 then
        if p50 == "Triangle" then
            if p52 == "Sphere" and p49[36] == 16973824 and p51[36] == 0 then
                v437, v440, v438, v439 = triangle_sphere_pair(p49, p51, p53, p55, v435, t3, v431, v433)

                if v437 ~= -1 then
                    return v437, v440, v438, v439
                end
            end
        elseif p50 == "Capsule" then
            if p52 == "Sphere" and p49[36] == 65536 and p51[36] == 0 then
                return capsule_sphere_pair(p49, p51, true, v435, t3, v431, v433)
            end
        elseif p50 == "Sphere" and p52 == "Capsule" and p49[36] == 0 and p51[36] == 65536 then
            return capsule_sphere_pair(p51, p49, false, v435, t3, v431, v433)
        end
    end

    table.move(v417, 1, 144, 1, v418)
    maximum_into(v418, p49, p50, 1, t3)
    t4[1] = bit32.bxor(t3[1], 2147483648)
    t4[2] = bit32.bxor(t3[2], 2147483648)
    t4[3] = bit32.bxor(t3[3], 2147483648)
    t4[4] = bit32.bxor(t3[4], 2147483648)
    table.move(v417, 1, 144, 1, v419)
    maximum_into(v419, p51, p52, 0, t4)
    table.move(v417, 1, 136, 1, v420)

    if find_feature_intersection_prism(v420, v418, v419, t3) == 0 then
        return nil
    end

    v440 = v420[133]

    if v440 > 16 then
        error("attempt to index nil with 'a'", 0)
    end

    buffer.writeu32(v147, 0, t3[1])

    local v442 = buffer.readf32(v147, 0)

    buffer.writeu32(v147, 0, t3[2])

    local v443 = buffer.readf32(v147, 0)

    buffer.writeu32(v147, 0, t3[3])

    local v444 = buffer.readf32(v147, 0)
    local v445, v446, v447, v448, v449, v450

    if v440 == 1 then
        v450 = v420[65]
        buffer.writeu32(v147, 0, v450)

        local v451 = buffer.readf32(v147, 0)

        buffer.writeu32(v147, 0, v420[1])

        local v453 = v451 - buffer.readf32(v147, 0)

        v450 = v420[66]
        buffer.writeu32(v147, 0, v450)
        v451 = buffer.readf32(v147, 0)
        buffer.writeu32(v147, 0, v420[2])

        local v454 = v451 - buffer.readf32(v147, 0)

        v450 = v420[67]
        buffer.writeu32(v147, 0, v450)
        v451 = buffer.readf32(v147, 0)
        buffer.writeu32(v147, 0, v420[3])

        local v455 = v451 - buffer.readf32(v147, 0)

        buffer.writeu32(v147, 0, v420[68])

        local v456 = buffer.readf32(v147, 0)

        buffer.writeu32(v147, 0, v420[4])

        local v458 = v456 - buffer.readf32(v147, 0)

        v451 = v453 * v453 + v454 * v454 + v455 * v455

        if v451 == 0 then
            buffer.writef32(v1, 0, v451)
            v456 = buffer.readf32(v1, 0)
        elseif v451 > -1.1754943508222875E-38 and v451 < 1.1754943508222875E-38 then
            v446 = math.abs(v451) * 7.1362384635298E+44
            v447 = math.floor(v446)
            v448 = v446 - v447

            if v448 > 0.5 or v448 == 0.5 and v447 % 2 == 1 then
                v447 += 1
            end

            v456 = v447 * 1.401298464324817E-45

            if v451 < 0 then
                v456 = -v456
            end
        else
            buffer.writef32(v1, 0, v451)
            v456 = buffer.readf32(v1, 0)
        end

        v451 = inverse_length(v456)

        if v456 == 0 then
            v456 = 0
        else
            v456 *= v451
        end

        buffer.writeu32(v147, 0, 872415232)

        if buffer.readf32(v147, 0) < v456 then
            v445 = v453 * v451

            if v445 == 0 then
                buffer.writef32(v147, 0, v445)
                v449 = buffer.readu32(v147, 0)
            elseif v445 > -1.1754943508222875E-38 and v445 < 1.1754943508222875E-38 then
                v449 = to_bits(v445)
            else
                buffer.writef32(v147, 0, v445)
                v449 = buffer.readu32(v147, 0)
            end

            v420[129] = v449
            v445 = v454 * v451

            local v459

            if v445 ~= 0 and v445 > -1.1754943508222875E-38 and v445 < 1.1754943508222875E-38 then
                v459 = to_bits(v445)
            else
                buffer.writef32(v147, 0, v445)
                v459 = buffer.readu32(v147, 0)
            end

            v420[130] = v459
            v445 = v455 * v451

            if v445 ~= 0 and v445 > -1.1754943508222875E-38 and v445 < 1.1754943508222875E-38 then
                v459 = to_bits(v445)
            else
                buffer.writef32(v147, 0, v445)
                v459 = buffer.readu32(v147, 0)
            end

            v420[131] = v459
            v445 = v458 * v451

            if v445 ~= 0 and v445 > -1.1754943508222875E-38 and v445 < 1.1754943508222875E-38 then
                v459 = to_bits(v445)
            else
                buffer.writef32(v147, 0, v445)
                v459 = buffer.readu32(v147, 0)
            end

            v420[132] = v459
            v420[134] = 1
        end
    end

    local v460, v461, v462
    local v463 = v442
    local v464 = v443
    local v465 = v444

    if v420[134] ~= 0 then
        v450 = v420[129]
        v462 = v420[130]
        v460 = v420[131]
        v461 = v420[132]
        t5[1] = v450
        t5[2] = v462
        t5[3] = v460
        t5[4] = v461
        project_direction(p49, p50, t5, v421)
        project_direction(p51, p52, t5, v422)
        v445 = v421[1]
        buffer.writeu32(v147, 0, v445)
        v449 = buffer.readf32(v147, 0)
        v446 = v422[5]
        buffer.writeu32(v147, 0, v446)
        v460 = v449 - buffer.readf32(v147, 0)
        v449 = v422[1]
        buffer.writeu32(v147, 0, v449)
        v447 = buffer.readf32(v147, 0)
        v448 = v421[5]
        buffer.writeu32(v147, 0, v448)
        v461 = v447 - buffer.readf32(v147, 0)
        v462 = v461 < v460

        if not v462 then
            v460 = v461
        end

        if v435 <= v460 then
            if v462 then
                v463 = t5[1]
                v445 = bit32.bxor(v463, 2147483648)
                buffer.writeu32(v147, 0, v445)
                v463 = buffer.readf32(v147, 0)
                v464 = t5[2]
                v445 = bit32.bxor(v464, 2147483648)
                buffer.writeu32(v147, 0, v445)
                v464 = buffer.readf32(v147, 0)
                v449 = t5[3]
                v445 = bit32.bxor(v449, 2147483648)
            else
                v445 = t5[1]
                buffer.writeu32(v147, 0, v445)
                v463 = buffer.readf32(v147, 0)
                v445 = t5[2]
                buffer.writeu32(v147, 0, v445)
                v464 = buffer.readf32(v147, 0)
                v445 = t5[3]
            end

            buffer.writeu32(v147, 0, v445)
            v465 = buffer.readf32(v147, 0)
        end
    end

    local v466 = v440 - 1
    local v467, v468

    for i = 0, v466 do
        local v469 = v426[i + 1]

        v460 = v424[i + 1]
        v461 = v425[i + 1]
        v449 = v420[i * 4 + 1]
        buffer.writeu32(v147, 0, v449)
        v447 = buffer.readf32(v147, 0)
        v448 = v420[i * 4 + 2]
        buffer.writeu32(v147, 0, v448)
        v467 = buffer.readf32(v147, 0)
        buffer.writeu32(v147, 0, v420[i * 4 + 3])
        v468 = buffer.readf32(v147, 0)
        v460.x = v447
        v460.y = v467
        v460.z = v468
        v449 = v420[i * 4 + 64 + 1]
        buffer.writeu32(v147, 0, v449)
        v447 = buffer.readf32(v147, 0)
        v448 = v420[i * 4 + 64 + 2]
        buffer.writeu32(v147, 0, v448)
        v467 = buffer.readf32(v147, 0)
        buffer.writeu32(v147, 0, v420[i * 4 + 64 + 3])
        v468 = buffer.readf32(v147, 0)
        v461.x = v447
        v461.y = v467
        v461.z = v468
        v469.a = v460
        v469.b = v461
    end

    t6.x = v463
    t6.y = v464
    t6.z = v465

    local v471 = p53.tag == "Triangle"
    local v472

    if v471 then
        t7.reverse = false
        t7.edge_cos_bend_normal_threshold = p55.edge_cos_bend_normal_threshold
        t7.convexity_epsilon = p55.convexity_epsilon
        t7.is_object = false
        v472 = fix_up_triangle(p53[1].feature, t6, v427[v440 + 1], t7)
    end

    if v471 and not v472 then
        return nil
    end

    local v473 = p54.tag == "Triangle"
    local v474

    if v473 then
        t7.reverse = true
        t7.edge_cos_bend_normal_threshold = p55.edge_cos_bend_normal_threshold
        t7.convexity_epsilon = p55.convexity_epsilon
        t7.is_object = false
        v474 = fix_up_triangle(p54[1].feature, t6, v427[v440 + 1], t7)
    end

    if v473 and not v474 then
        return nil
    end

    v472 = t6.x
    v442 = t6.y
    v462 = t6.z
    v460 = v472 * v431
    v461 = v442 * v431
    v445 = v462 * v431
    v463 = v472 * v433
    v447 = v442 * v433
    v467 = v462 * v433

    for i = 0, v440 - 1 do
        v438 = v426[i + 1]

        local a, b = v438.a, v438.b

        v438 = i * 6
        v423[v438 + 1] = a.x + v460
        v423[v438 + 2] = a.y + v461
        v423[v438 + 3] = a.z + v445
        v423[v438 + 4] = b.x - v463
        v423[v438 + 5] = b.y - v447
        v423[v438 + 6] = b.z - v467
    end

    return v440, -v472, -v442, -v462
end

v20.primitive_pair_contacts_flat = primitive_pair_contacts_flat

function capsule_sphere_pair(p56, p57, p58, p59, p60, p61, p62) -- line: 929
    -- upvalues: v147 (copy), to_bits (copy), fround (copy), v199 (copy), v415 (copy), capsule_floats (copy), closest_segment_xyz (copy), v416 (copy), v423 (copy)
    buffer.writeu32(v147, 0, p60[1])

    local v476 = buffer.readf32(v147, 0)

    buffer.writeu32(v147, 0, p60[2])

    local v478 = buffer.readf32(v147, 0)

    buffer.writeu32(v147, 0, p60[3])

    local v480 = buffer.readf32(v147, 0)

    buffer.writeu32(v147, 0, p56[1])

    local v482 = buffer.readf32(v147, 0)

    buffer.writeu32(v147, 0, p56[2])

    local v484 = buffer.readf32(v147, 0)

    buffer.writeu32(v147, 0, p56[3])

    local v486 = buffer.readf32(v147, 0)

    buffer.writeu32(v147, 0, p56[17])

    local v488 = buffer.readf32(v147, 0)

    buffer.writeu32(v147, 0, p56[18])

    local v490 = buffer.readf32(v147, 0)

    buffer.writeu32(v147, 0, p56[19])

    local v492 = buffer.readf32(v147, 0)

    buffer.writeu32(v147, 0, p56[29])

    local v494 = buffer.readf32(v147, 0)

    buffer.writeu32(v147, 0, p57[1])

    local v496 = buffer.readf32(v147, 0)

    buffer.writeu32(v147, 0, p57[2])

    local v498 = buffer.readf32(v147, 0)

    buffer.writeu32(v147, 0, p57[3])

    local v500 = buffer.readf32(v147, 0)
    local v501 = if p58 then v488 * v476 + v490 * v478 + v492 * v480 else v488 * -v476 + v490 * -v478 + v492 * -v480
    local v502, v503, v504

    if math.abs(v501) < v415 then
        v416[1] = v488
        v416[2] = v490
        v416[3] = v492
        v416[4] = v494
        capsule_floats(v416, v482, v484, v486)
        v502, v503, v504 = closest_segment_xyz(v496, v498, v500, v416[5], v416[6], v416[7], v416[8], v416[9], v416[10], v416[11])
    else
        if v501 > 0 then
            local v505 = v488 * v494 + v482

            if not (v505 < 1.1754943508222875E-38) or not (v505 > -1.1754943508222875E-38) or v505 == 0 then
                buffer.writef32(v147, 0, v505)
            else
                buffer.writeu32(v147, 0, to_bits(v505))
            end

            v502 = buffer.readf32(v147, 0)

            local v506 = v490 * v494 + v484

            if v506 < 1.1754943508222875E-38 and v506 > -1.1754943508222875E-38 and v506 ~= 0 then
                buffer.writeu32(v147, 0, to_bits(v506))
            else
                buffer.writef32(v147, 0, v506)
            end

            v503 = buffer.readf32(v147, 0)

            local v507 = v492 * v494 + v486

            if v507 < 1.1754943508222875E-38 and v507 > -1.1754943508222875E-38 and v507 ~= 0 then
                buffer.writeu32(v147, 0, to_bits(v507))
            else
                buffer.writef32(v147, 0, v507)
            end
        else
            local v508 = v482 - v488 * v494

            if v508 < 1.1754943508222875E-38 and v508 > -1.1754943508222875E-38 and v508 ~= 0 then
                buffer.writeu32(v147, 0, to_bits(v508))
            else
                buffer.writef32(v147, 0, v508)
            end

            v502 = buffer.readf32(v147, 0)

            local v509 = v484 - v490 * v494

            if v509 < 1.1754943508222875E-38 and v509 > -1.1754943508222875E-38 and v509 ~= 0 then
                buffer.writeu32(v147, 0, to_bits(v509))
            else
                buffer.writef32(v147, 0, v509)
            end

            v503 = buffer.readf32(v147, 0)

            local v510 = v486 - v492 * v494

            if v510 < 1.1754943508222875E-38 and v510 > -1.1754943508222875E-38 and v510 ~= 0 then
                buffer.writeu32(v147, 0, to_bits(v510))
            else
                buffer.writef32(v147, 0, v510)
            end
        end

        v504 = buffer.readf32(v147, 0)
    end

    local v511, v512, v513

    if p58 then
        v513 = v500
        v511 = v496
        v512 = v498
    else
        v502, v503, v504, v511, v512, v513 = v496, v498, v500, v502, v503, v504
    end

    local v514 = v511 - v502
    local v515 = v512 - v503
    local v516 = v513 - v504
    local v517 = fround(v514 * v514 + v515 * v515 + v516 * v516)
    local v518 = 1 / math.sqrt(v517)
    local v519 = v518 * 0.5 * (-v517 * (v518 * v518) + 1) + v518
    local v520 = v519 * 0.5 * (-v517 * (v519 * v519) + 1) + v519
    local v521 = if v517 == 0 then 0 else v517 * v520
    local v522 = v476
    local v523 = v478
    local v524 = v480

    if v199 < v521 then
        local v525 = v514 * v520

        if not (v525 < 1.1754943508222875E-38) or not (v525 > -1.1754943508222875E-38) or v525 == 0 then
            buffer.writef32(v147, 0, v525)
        else
            buffer.writeu32(v147, 0, to_bits(v525))
        end

        v522 = buffer.readf32(v147, 0)

        local v526 = v515 * v520

        if v526 < 1.1754943508222875E-38 and v526 > -1.1754943508222875E-38 and v526 ~= 0 then
            buffer.writeu32(v147, 0, to_bits(v526))
        else
            buffer.writef32(v147, 0, v526)
        end

        v523 = buffer.readf32(v147, 0)

        local v527 = v516 * v520

        if v527 < 1.1754943508222875E-38 and v527 > -1.1754943508222875E-38 and v527 ~= 0 then
            buffer.writeu32(v147, 0, to_bits(v527))
        else
            buffer.writef32(v147, 0, v527)
        end

        v524 = buffer.readf32(v147, 0)

        local v528 = v482 * v522 + v484 * v523 + v486 * v524
        local v530 = math.abs(v488 * v522 + v490 * v523 + v492 * v524) * v494
        local v531 = v496 * v522 + v498 * v523 + v500 * v524

        if v531 < 1.1754943508222875E-38 and v531 > -1.1754943508222875E-38 and v531 ~= 0 then
            buffer.writeu32(v147, 0, to_bits(v531))
        else
            buffer.writef32(v147, 0, v531)
        end

        local v532 = buffer.readf32(v147, 0)
        local v533, v534

        if p58 then
            local v535 = v528 - v530

            if not (v535 < 1.1754943508222875E-38) or not (v535 > -1.1754943508222875E-38) or v535 == 0 then
                buffer.writef32(v147, 0, v535)
            else
                buffer.writeu32(v147, 0, to_bits(v535))
            end

            v533 = buffer.readf32(v147, 0) - v532

            local v536 = v528 + v530

            if v536 < 1.1754943508222875E-38 and v536 > -1.1754943508222875E-38 and v536 ~= 0 then
                buffer.writeu32(v147, 0, to_bits(v536))
            else
                buffer.writef32(v147, 0, v536)
            end

            v534 = v532 - buffer.readf32(v147, 0)
        else
            local v537 = v528 + v530

            if v537 < 1.1754943508222875E-38 and v537 > -1.1754943508222875E-38 and v537 ~= 0 then
                buffer.writeu32(v147, 0, to_bits(v537))
            else
                buffer.writef32(v147, 0, v537)
            end

            v533 = v532 - buffer.readf32(v147, 0)

            local v538 = v528 - v530

            if v538 < 1.1754943508222875E-38 and v538 > -1.1754943508222875E-38 and v538 ~= 0 then
                buffer.writeu32(v147, 0, to_bits(v538))
            else
                buffer.writef32(v147, 0, v538)
            end

            v534 = buffer.readf32(v147, 0) - v532
        end

        if v534 < v533 then
            if p59 <= v533 then
                v522 = -v522
                v523 = -v523
                v524 = -v524
            else
                v524 = v480
                v522 = v476
                v523 = v478
            end
        elseif not (p59 <= v534) then
            v524 = v480
            v522 = v476
            v523 = v478
        end
    end

    v423[1] = v502 + v522 * p61
    v423[2] = v503 + v523 * p61
    v423[3] = v504 + v524 * p61
    v423[4] = v511 - v522 * p62
    v423[5] = v512 - v523 * p62
    v423[6] = v513 - v524 * p62

    return 1, -v522, -v523, -v524
end

function triangle_sphere_pair(p63, p64, p65, p66, p67, p68, p69, p70) -- line: 1000
    -- upvalues: fix_up_triangle (copy), v147 (copy), to_bits (copy), fround (copy), v199 (copy), v402 (copy), fix_up_toward (copy), v403 (copy), plane_of (copy), v423 (copy), v424 (copy), v425 (copy), v426 (copy), v427 (copy), t6 (copy), t7 (copy)
    buffer.writeu32(v147, 0, p68[1])

    local v540 = buffer.readf32(v147, 0)

    buffer.writeu32(v147, 0, p68[2])

    local v541 = buffer.readf32(v147, 0)

    buffer.writeu32(v147, 0, p68[3])

    local v542 = buffer.readf32(v147, 0)

    buffer.writeu32(v147, 0, p63[5])

    local v544 = v540 * buffer.readf32(v147, 0)

    buffer.writeu32(v147, 0, p63[6])

    local v546 = v544 + v541 * buffer.readf32(v147, 0)

    buffer.writeu32(v147, 0, p63[7])

    local v539 = v546 + v542 * buffer.readf32(v147, 0)

    if not (math.abs(v539) > v402) then
        return -1
    end

    buffer.writeu32(v147, 0, p63[1])

    local v545 = buffer.readf32(v147, 0)

    buffer.writeu32(v147, 0, p63[2])

    local v547 = buffer.readf32(v147, 0)

    buffer.writeu32(v147, 0, p63[3])

    local v548 = buffer.readf32(v147, 0)

    buffer.writeu32(v147, 0, p63[9])

    local v550 = buffer.readf32(v147, 0)

    buffer.writeu32(v147, 0, p63[10])

    local v551 = buffer.readf32(v147, 0)

    buffer.writeu32(v147, 0, p63[11])

    local v552 = buffer.readf32(v147, 0)

    buffer.writeu32(v147, 0, p63[13])

    local v554 = buffer.readf32(v147, 0)

    buffer.writeu32(v147, 0, p63[14])

    local v555 = buffer.readf32(v147, 0)

    buffer.writeu32(v147, 0, p63[15])

    local v556 = buffer.readf32(v147, 0)

    buffer.writeu32(v147, 0, p64[1])

    local v558 = buffer.readf32(v147, 0)

    buffer.writeu32(v147, 0, p64[2])

    local v559 = buffer.readf32(v147, 0)

    buffer.writeu32(v147, 0, p64[3])

    local v560 = buffer.readf32(v147, 0)
    local v561, v562, v563, v564, v565, v566, v567, v568, v569, v570, v571, v572, v573, v574, v575, v576, v577, v578

    if v539 < 0 then
        v572 = p63[17]
        buffer.writeu32(v147, 0, v572)
        v561 = buffer.readf32(v147, 0)
        v572 = p63[18]
        buffer.writeu32(v147, 0, v572)
        v562 = buffer.readf32(v147, 0)
        v572 = p63[19]
        buffer.writeu32(v147, 0, v572)
        v563 = buffer.readf32(v147, 0)
        v572 = p63[29]
        buffer.writeu32(v147, 0, v572)
        v564 = buffer.readf32(v147, 0)
        v572 = p63[21]
        buffer.writeu32(v147, 0, v572)
        v565 = buffer.readf32(v147, 0)
        v572 = p63[22]
        buffer.writeu32(v147, 0, v572)
        v566 = buffer.readf32(v147, 0)
        v572 = p63[23]
        buffer.writeu32(v147, 0, v572)
        v567 = buffer.readf32(v147, 0)
        v572 = p63[30]
        buffer.writeu32(v147, 0, v572)
        v568 = buffer.readf32(v147, 0)
        v572 = p63[25]
        buffer.writeu32(v147, 0, v572)
        v569 = buffer.readf32(v147, 0)
        v572 = p63[26]
        buffer.writeu32(v147, 0, v572)
        v570 = buffer.readf32(v147, 0)
        v572 = p63[27]
        buffer.writeu32(v147, 0, v572)
        v571 = buffer.readf32(v147, 0)
        v572 = p63[31]
        buffer.writeu32(v147, 0, v572)
        v573 = v554
        v574 = v555
        v575 = v556
        v576 = v550
        v577 = v551
        v578 = v552
    else
        v563 = p63[25]
        buffer.writeu32(v147, 0, v563)
        v561 = -buffer.readf32(v147, 0)
        v563 = p63[26]
        buffer.writeu32(v147, 0, v563)
        v562 = -buffer.readf32(v147, 0)
        v563 = p63[27]
        buffer.writeu32(v147, 0, v563)
        v563 = -buffer.readf32(v147, 0)
        v572 = p63[31]
        buffer.writeu32(v147, 0, v572)
        v564 = buffer.readf32(v147, 0)
        v565 = p63[21]
        buffer.writeu32(v147, 0, v565)
        v565 = -buffer.readf32(v147, 0)
        v566 = p63[22]
        buffer.writeu32(v147, 0, v566)
        v566 = -buffer.readf32(v147, 0)
        v567 = p63[23]
        buffer.writeu32(v147, 0, v567)
        v567 = -buffer.readf32(v147, 0)
        v572 = p63[30]
        buffer.writeu32(v147, 0, v572)
        v568 = buffer.readf32(v147, 0)
        v569 = p63[17]
        buffer.writeu32(v147, 0, v569)
        v569 = -buffer.readf32(v147, 0)
        v570 = p63[18]
        buffer.writeu32(v147, 0, v570)
        v570 = -buffer.readf32(v147, 0)
        v571 = p63[19]
        buffer.writeu32(v147, 0, v571)
        v571 = -buffer.readf32(v147, 0)
        v572 = p63[29]
        buffer.writeu32(v147, 0, v572)
        v573 = v550
        v574 = v551
        v575 = v552
        v576 = v554
        v577 = v555
        v578 = v556
    end

    local v579 = buffer.readf32(v147, 0)

    v539 = v540 * (v545 - v558) + v541 * (v547 - v559) + v542 * (v548 - v560)
    v572 = v540 * v539 + v558

    local v580 = v541 * v539 + v559
    local v581 = v542 * v539 + v560
    local v582, v583, v584 = plane_of(v561, v562, v563, v540, v541, v542)
    local v585 = v582 * (v572 - v545) + v583 * (v580 - v547) + v584 * (v581 - v548)
    local v586, v587, v588 = plane_of(v565, v566, v567, v540, v541, v542)
    local v589 = v586 * (v572 - v573) + v587 * (v580 - v574) + v588 * (v581 - v575)

    if v585 < v589 then
        v539 = 2
    else
        v589 = v585
        v539 = 1
        v586 = v582
        v587 = v583
        v588 = v584
    end

    local v590, v591, v592 = plane_of(v569, v570, v571, v540, v541, v542)
    local v593 = v590 * (v572 - v576) + v591 * (v580 - v577) + v592 * (v581 - v578)

    if v589 < v593 then
        v539 = 3
    else
        v593 = v589
        v590 = v586
        v591 = v587
        v592 = v588
    end

    local v594

    if v593 > 0 then
        v590 = v572 - v590 * v593

        if not (v590 < 1.1754943508222875E-38) or not (v590 > -1.1754943508222875E-38) or v590 == 0 then
            buffer.writef32(v147, 0, v590)
        else
            buffer.writeu32(v147, 0, to_bits(v590))
        end

        local v595 = buffer.readf32(v147, 0)

        v591 = v580 - v591 * v593

        if v591 < 1.1754943508222875E-38 and v591 > -1.1754943508222875E-38 and v591 ~= 0 then
            buffer.writeu32(v147, 0, to_bits(v591))
        else
            buffer.writef32(v147, 0, v591)
        end

        local v596 = buffer.readf32(v147, 0)

        v592 = v581 - v592 * v593

        if v592 < 1.1754943508222875E-38 and v592 > -1.1754943508222875E-38 and v592 ~= 0 then
            buffer.writeu32(v147, 0, to_bits(v592))
        else
            buffer.writef32(v147, 0, v592)
        end

        v594 = buffer.readf32(v147, 0)

        if v539 == 1 then
            v575 = v548
            v573 = v545
            v574 = v547
        elseif v539 == 2 then
            v564 = v568
            v561 = v565
            v562 = v566
            v563 = v567
        else
            v564 = v579
            v573 = v576
            v574 = v577
            v575 = v578
            v561 = v569
            v562 = v570
            v563 = v571
        end

        local v597 = (v595 - v573) * v561 + (v596 - v574) * v562 + (v594 - v575) * v563

        if not (v597 < 0) then
            local v598

            if v564 < v597 then
                v598 = v561 * v564 + v573

                if not (v598 < 1.1754943508222875E-38) or not (v598 > -1.1754943508222875E-38) or v598 == 0 then
                    buffer.writef32(v147, 0, v598)
                else
                    buffer.writeu32(v147, 0, to_bits(v598))
                end

                v573 = buffer.readf32(v147, 0)
                v598 = v562 * v564 + v574

                if v598 < 1.1754943508222875E-38 and v598 > -1.1754943508222875E-38 and v598 ~= 0 then
                    buffer.writeu32(v147, 0, to_bits(v598))
                else
                    buffer.writef32(v147, 0, v598)
                end

                v574 = buffer.readf32(v147, 0)
                v598 = v563 * v564 + v575
            else
                v598 = v561 * v597 + v573

                if v598 < 1.1754943508222875E-38 and v598 > -1.1754943508222875E-38 and v598 ~= 0 then
                    buffer.writeu32(v147, 0, to_bits(v598))
                else
                    buffer.writef32(v147, 0, v598)
                end

                v573 = buffer.readf32(v147, 0)
                v598 = v562 * v597 + v574

                if v598 < 1.1754943508222875E-38 and v598 > -1.1754943508222875E-38 and v598 ~= 0 then
                    buffer.writeu32(v147, 0, to_bits(v598))
                else
                    buffer.writef32(v147, 0, v598)
                end

                v574 = buffer.readf32(v147, 0)
                v598 = v563 * v597 + v575
            end

            if v598 < 1.1754943508222875E-38 and v598 > -1.1754943508222875E-38 and v598 ~= 0 then
                buffer.writeu32(v147, 0, to_bits(v598))
            else
                buffer.writef32(v147, 0, v598)
            end

            v575 = buffer.readf32(v147, 0)
        end
    else
        if v572 < 1.1754943508222875E-38 and v572 > -1.1754943508222875E-38 and v572 ~= 0 then
            buffer.writeu32(v147, 0, to_bits(v572))
        else
            buffer.writef32(v147, 0, v572)
        end

        v573 = buffer.readf32(v147, 0)

        if v580 < 1.1754943508222875E-38 and v580 > -1.1754943508222875E-38 and v580 ~= 0 then
            buffer.writeu32(v147, 0, to_bits(v580))
        else
            buffer.writef32(v147, 0, v580)
        end

        v574 = buffer.readf32(v147, 0)

        if v581 < 1.1754943508222875E-38 and v581 > -1.1754943508222875E-38 and v581 ~= 0 then
            buffer.writeu32(v147, 0, to_bits(v581))
        else
            buffer.writef32(v147, 0, v581)
        end

        v575 = buffer.readf32(v147, 0)
    end

    v585 = v558 - v573
    v584 = v559 - v574
    v583 = v560 - v575
    v593 = fround(v585 * v585 + v584 * v584 + v583 * v583)
    v581 = 1 / math.sqrt(v593)
    v581 = v581 * 0.5 * (-v593 * (v581 * v581) + 1) + v581
    v581 = v581 * 0.5 * (-v593 * (v581 * v581) + 1) + v581

    if v593 == 0 then
        v593 = 0
    else
        v593 *= v581
    end

    if v199 < v593 then
        v594 = v585 * v581

        if v594 < 1.1754943508222875E-38 and v594 > -1.1754943508222875E-38 and v594 ~= 0 then
            buffer.writeu32(v147, 0, to_bits(v594))
        else
            buffer.writef32(v147, 0, v594)
        end

        local v599 = buffer.readf32(v147, 0)

        v594 = v584 * v581

        if v594 < 1.1754943508222875E-38 and v594 > -1.1754943508222875E-38 and v594 ~= 0 then
            buffer.writeu32(v147, 0, to_bits(v594))
        else
            buffer.writef32(v147, 0, v594)
        end

        local v600 = buffer.readf32(v147, 0)

        v594 = v583 * v581

        if v594 < 1.1754943508222875E-38 and v594 > -1.1754943508222875E-38 and v594 ~= 0 then
            buffer.writeu32(v147, 0, to_bits(v594))
        else
            buffer.writef32(v147, 0, v594)
        end

        local v601 = buffer.readf32(v147, 0)

        v582 = v545 * v599 + v547 * v600 + v548 * v601
        v563 = v550 * v599 + v551 * v600 + v552 * v601
        v572 = v554 * v599 + v555 * v600 + v556 * v601

        local v602 = if v582 < v563 then v582 else v563

        if not (v563 < v582) then
            v582 = v563
        end

        v594 = v558 * v599 + v559 * v600 + v560 * v601

        if v594 < 1.1754943508222875E-38 and v594 > -1.1754943508222875E-38 and v594 ~= 0 then
            buffer.writeu32(v147, 0, to_bits(v594))
        else
            buffer.writef32(v147, 0, v594)
        end

        local v603 = buffer.readf32(v147, 0)

        if not (v602 < v572) then
            v602 = v572
        end

        if v602 < 1.1754943508222875E-38 and v602 > -1.1754943508222875E-38 and v602 ~= 0 then
            buffer.writeu32(v147, 0, to_bits(v602))
        else
            buffer.writef32(v147, 0, v602)
        end

        v563 = buffer.readf32(v147, 0) - v603

        if not (v572 < v582) then
            v582 = v572
        end

        if v582 < 1.1754943508222875E-38 and v582 > -1.1754943508222875E-38 and v582 ~= 0 then
            buffer.writeu32(v147, 0, to_bits(v582))
        else
            buffer.writef32(v147, 0, v582)
        end

        v579 = v603 - buffer.readf32(v147, 0)

        if v579 < v563 then
            if p67 <= v563 then
                v540 = -v599
                v541 = -v600
                v542 = -v601
            end
        elseif p67 <= v579 then
            v542 = v601
            v540 = v599
            v541 = v600
        end
    end

    local feature = p65[1].feature

    v578 = feature.normal
    v590 = v578.x
    v591 = v578.y
    v592 = v578.z
    v403[34] = v590
    v403[35] = v591
    v403[36] = v592
    v577 = feature.edges
    v578 = v577[1]
    v590 = v578.x
    v591 = v578.y
    v592 = v578.z
    v403[37] = v590
    v403[38] = v591
    v403[39] = v592
    v578 = v577[2]
    v590 = v578.x
    v591 = v578.y
    v592 = v578.z
    v403[40] = v590
    v403[41] = v591
    v403[42] = v592
    v578 = v577[3]
    v590 = v578.x
    v591 = v578.y
    v592 = v578.z
    v403[43] = v590
    v403[44] = v591
    v403[45] = v592
    v578 = feature.edge_cosines
    v590 = v578[1]
    v591 = v578[2]
    v592 = v578[3]
    v403[46] = v590
    v403[47] = v591
    v403[48] = v592
    v403[49] = feature.flags
    v590 = fix_up_toward(v403, v540, v541, v542, p66)

    if v590 == 0 then
        return nil
    end

    if v590 == 1 then
        v423[1] = v573 + v540 * p69
        v423[2] = v574 + v541 * p69
        v423[3] = v575 + v542 * p69
        v423[4] = v558 - v540 * p70
        v423[5] = v559 - v541 * p70
        v423[6] = v560 - v542 * p70

        return 1, -v540, -v541, -v542
    end

    v593 = v426[1]
    v576 = v424[1]

    local v604 = v425[1]

    v576.x = v573
    v576.y = v574
    v576.z = v575
    v604.x = v558
    v604.y = v559
    v604.z = v560
    v593.a = v576
    v593.b = v604
    t6.x = v540
    t6.y = v541
    t6.z = v542
    t7.reverse = false
    t7.edge_cos_bend_normal_threshold = p66.edge_cos_bend_normal_threshold
    t7.convexity_epsilon = p66.convexity_epsilon
    t7.is_object = false

    if not fix_up_triangle(feature, t6, v427[2], t7) then
        return nil
    end

    v590 = t6.x
    v591 = t6.y
    v592 = t6.z
    v576 = v593.a
    v604 = v593.b
    v423[1] = v576.x + v590 * p69
    v423[2] = v576.y + v591 * p69
    v423[3] = v576.z + v592 * p69
    v423[4] = v604.x - v590 * p70
    v423[5] = v604.y - v591 * p70
    v423[6] = v604.z - v592 * p70

    return 1, -v590, -v591, -v592
end

function v20.primitive_pair_contacts(p71, p72, p73) -- line: 1168
    -- upvalues: pack (copy), v423 (copy), primitive_pair_contacts_flat (copy)
    local v605, v606 = pack(p71)
    local v607, v608 = pack(p72)
    local v609, v610, v611, v612 = primitive_pair_contacts_flat(v605, v606, v607, v608, p71, p72, p73)

    if v609 == nil then
        return nil
    end

    local v613 = table.create(16)

    for i = 1, 16 do
        if i <= v609 then
            local v614 = (i - 1) * 6

            v613[i] = {
                a = {
                    x = v423[v614 + 1],
                    y = v423[v614 + 2],
                    z = v423[v614 + 3]
                },
                b = {
                    x = v423[v614 + 4],
                    y = v423[v614 + 5],
                    z = v423[v614 + 6]
                }
            }
        else
            v613[i] = {
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
            x = v610,
            y = v611,
            z = v612
        },
        points = v613,
        count = v609
    }
end

return v20
