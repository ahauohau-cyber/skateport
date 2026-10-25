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
local v12 = import("skate_core/animation/foot_ik/math")
local cross, inverse_affine, length, normalize = v12.cross, v12.inverse_affine, v12.length, v12.normalize
local reciprocal = v12.reciprocal
local v13 = import("skate_core/physics/native_arithmetic")
local dot3, vector_max, vector_min = v13.dot3, v13.vector_max, v13.vector_min
local transform_point = import("skate_core/physics/skeleton_animation_record").transform_point
local v14 = import("skate_core/physics/board_motion_output")
local v15 = import("skate_core/trigonometry")
local acos, cos, sin_cos = v15.acos, v15.cos, v15.sin_cos
local t1 = {
    SolveResult = {
        Solved = "Solved",
        Extended = "Extended",
        Invalid = "Invalid"
    },
    AngleLimits = {},
    EPSILON = 0.0005000000237487257,
    TO_DEGREES = 57.295780181884766,
    TO_RADIANS = 0.01745329238474369
}
local EPSILON, TO_DEGREES, TO_RADIANS = t1.EPSILON, t1.TO_DEGREES, t1.TO_RADIANS

local function clamp_native_cosine(p5) -- line: 77
    -- upvalues: vector_max (copy), vector_min (copy)
    return vector_min(1, vector_max(0, p5))
end

local function square_root(p6) -- line: 81
    -- upvalues: v1 (copy), v14 (copy)
    local v16

    if p6 ~= 0 and p6 > -1.1754943508222875E-38 and p6 < 1.1754943508222875E-38 then
        local v17 = math.abs(p6) * 7.1362384635298E+44
        local v18 = math.floor(v17)
        local v19 = v17 - v18

        v16 = (if v19 > 0.5 or v19 == 0.5 and v18 % 2 == 1 then v18 + 1 else v18) * 1.401298464324817E-45

        if p6 < 0 then
            v16 = -v16
        end
    else
        buffer.writef32(v1, 0, p6)
        v16 = buffer.readf32(v1, 0)
    end

    local v20 = v16 * v14.inverse_length_squared(v16, 2)

    if v16 == 0 then
        return 0
    end

    return v20
end

local function subtract(p7, p8) -- line: 92
    return {
        p7[1] - p8[1],
        p7[2] - p8[2],
        p7[3] - p8[3],
        p7[4] - p8[4]
    }
end

local function scaled_add(p9, p10, p11) -- line: 96
    return {
        p9[1] * p10 + p11[1],
        p9[2] * p10 + p11[2],
        p9[3] * p10 + p11[3],
        p9[4] * p10 + p11[4]
    }
end

local function candidate(p12, p13, p14, p15, p16) -- line: 100
    -- upvalues: normalize (copy), transform_point (copy), sin_cos (copy), scaled_add (copy)
    local v21, v22 = sin_cos(p13)

    return transform_point(p16, (scaled_add(normalize(transform_point({
        { v22, v21, 0, v22 },
        { -v21, v22, 0, -v21 },
        { 0, 0, 1, 0 },
        { 0, 0, 0, 0 }
    }, p12)), p14, p15)))
end

function t1.solve_reference(p17, p18, p19, p20, p21, p22, p23, p24) -- line: 113
    -- upvalues: rt (copy), v1 (copy), cross (copy), inverse_affine (copy), length (copy), normalize (copy), reciprocal (copy), dot3 (copy), vector_max (copy), vector_min (copy), transform_point (copy), v14 (copy), acos (copy), cos (copy), t1 (copy), EPSILON (copy), TO_DEGREES (copy), TO_RADIANS (copy), clamp_native_cosine (copy), scaled_add (copy), candidate (copy)
    if p24 == 0 then
        rt.assign(p21, p19)
    else
        local t3 = {
            p18[1] - p17[1],
            p18[2] - p17[2],
            p18[3] - p17[3],
            p18[4] - p17[4]
        }
        local t4 = {
            p19[1] - p18[1],
            p19[2] - p18[2],
            p19[3] - p18[3],
            p19[4] - p18[4]
        }
        local v24 = length(t3)
        local v25 = length(t4)

        if not (v24 < EPSILON or v25 < EPSILON) then
            local t5 = {
                p21[1] - p17[1],
                p21[2] - p17[2],
                p21[3] - p17[3],
                p21[4] - p17[4]
            }
            local v26 = normalize({
                p19[1] - p17[1],
                p19[2] - p17[2],
                p19[3] - p17[3],
                p19[4] - p17[4]
            })
            local v27 = normalize(cross(t3, t4))
            local t6 = {
                rt.copy(v26),
                cross(v26, v27),
                rt.copy(v27),
                rt.copy(p17)
            }
            local v28 = normalize(t5)
            local v29 = cross(v28, v27)
            local t7 = {
                v28,
                v29,
                cross(v29, v28),
                rt.copy(p17)
            }
            local v30 = inverse_affine(t6)
            local v31 = inverse_affine(t7)
            local v32 = transform_point(v30, p17)
            local v33 = transform_point(v30, p18)
            local v34 = transform_point(v30, p19)
            local v35 = transform_point(v31, p21)
            local t8 = {
                v35[1] - v32[1],
                v35[2] - v32[2],
                v35[3] - v32[3],
                v35[4] - v32[4]
            }
            local v36 = t8[1] * t8[1] + t8[2] * t8[2]
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

            local v41 = v37 * v14.inverse_length_squared(v37, 2)

            if v37 == 0 then
                v41 = 0
            end

            local v42 = v24 * v24
            local v43 = v25 * v25
            local v44 = 2 * v24
            local v45 = v44 * v25
            local v46 = v42 + v43
            local v47 = t4[1]
            local v48

            if v47 ~= 0 and v47 > -1.1754943508222875E-38 and v47 < 1.1754943508222875E-38 then
                local v49 = math.abs(v47) * 7.1362384635298E+44
                local v50 = math.floor(v49)
                local v51 = v49 - v50

                v48 = if v51 > 0.5 or v51 == 0.5 and v50 % 2 == 1 then v50 + 1 else v50

                if v47 < 0 then
                    v48 += 2147483648
                end
            else
                buffer.writef32(v1, 0, v47)
                v48 = buffer.readu32(v1, 0)
            end

            buffer.writeu32(v1, 0, (bit32.bxor(v48, 2147483648)))

            local v53 = buffer.readf32(v1, 0)
            local v54 = t4[2]
            local v55

            if v54 ~= 0 and v54 > -1.1754943508222875E-38 and v54 < 1.1754943508222875E-38 then
                local v56 = math.abs(v54) * 7.1362384635298E+44
                local v57 = math.floor(v56)
                local v58 = v56 - v57

                v55 = if v58 > 0.5 or v58 == 0.5 and v57 % 2 == 1 then v57 + 1 else v57

                if v54 < 0 then
                    v55 += 2147483648
                end
            else
                buffer.writef32(v1, 0, v54)
                v55 = buffer.readu32(v1, 0)
            end

            buffer.writeu32(v1, 0, (bit32.bxor(v55, 2147483648)))

            local v60 = buffer.readf32(v1, 0)
            local v61 = t4[3]
            local v62

            if v61 ~= 0 and v61 > -1.1754943508222875E-38 and v61 < 1.1754943508222875E-38 then
                local v63 = math.abs(v61) * 7.1362384635298E+44
                local v64 = math.floor(v63)
                local v65 = v63 - v64

                v62 = if v65 > 0.5 or v65 == 0.5 and v64 % 2 == 1 then v64 + 1 else v64

                if v61 < 0 then
                    v62 += 2147483648
                end
            else
                buffer.writef32(v1, 0, v61)
                v62 = buffer.readu32(v1, 0)
            end

            buffer.writeu32(v1, 0, (bit32.bxor(v62, 2147483648)))

            local v67 = buffer.readf32(v1, 0)
            local v68 = t4[4]
            local v69

            if v68 ~= 0 and v68 > -1.1754943508222875E-38 and v68 < 1.1754943508222875E-38 then
                local v70 = math.abs(v68) * 7.1362384635298E+44
                local v71 = math.floor(v70)
                local v72 = v70 - v71

                v69 = if v72 > 0.5 or v72 == 0.5 and v71 % 2 == 1 then v71 + 1 else v71

                if v68 < 0 then
                    v69 += 2147483648
                end
            else
                buffer.writef32(v1, 0, v68)
                v69 = buffer.readu32(v1, 0)
            end

            buffer.writeu32(v1, 0, (bit32.bxor(v69, 2147483648)))

            local t9 = {
                v53,
                v60,
                v67,
                (buffer.readf32(v1, 0))
            }
            local v75

            if v25 ~= 0 and v25 > -1.1754943508222875E-38 and v25 < 1.1754943508222875E-38 then
                local v76 = math.abs(v25) * 7.1362384635298E+44
                local v77 = math.floor(v76)
                local v78 = v76 - v77

                v75 = if v78 > 0.5 or v78 == 0.5 and v77 % 2 == 1 then v77 + 1 else v77

                if v25 < 0 then
                    v75 += 2147483648
                end
            else
                buffer.writef32(v1, 0, v25)
                v75 = buffer.readu32(v1, 0)
            end

            buffer.writeu32(v1, 0, (bit32.bxor(v75, 2147483648)))

            local v81 = acos(reciprocal(v24 * buffer.readf32(v1, 0), 2) * dot3(t3, t9)) * TO_DEGREES
            local maximum_degrees = p22.maximum_degrees

            if not (maximum_degrees < v81 and p23) then
                v81 = maximum_degrees
            end

            local v82 = v46 - v45 * cos(p22.minimum_degrees * TO_RADIANS)
            local v83

            if v82 ~= 0 and v82 > -1.1754943508222875E-38 and v82 < 1.1754943508222875E-38 then
                local v84 = math.abs(v82) * 7.1362384635298E+44
                local v85 = math.floor(v84)
                local v86 = v84 - v85

                v83 = (if v86 > 0.5 or v86 == 0.5 and v85 % 2 == 1 then v85 + 1 else v85) * 1.401298464324817E-45

                if v82 < 0 then
                    v83 = -v83
                end
            else
                buffer.writef32(v1, 0, v82)
                v83 = buffer.readf32(v1, 0)
            end

            local v87 = v83 * v14.inverse_length_squared(v83, 2)

            if v83 == 0 then
                v87 = 0
            end

            local v88 = v46 - v45 * cos(v81 * TO_RADIANS)
            local v89

            if v88 ~= 0 and v88 > -1.1754943508222875E-38 and v88 < 1.1754943508222875E-38 then
                local v90 = math.abs(v88) * 7.1362384635298E+44
                local v91 = math.floor(v90)
                local v92 = v90 - v91

                v89 = (if v92 > 0.5 or v92 == 0.5 and v91 % 2 == 1 then v91 + 1 else v91) * 1.401298464324817E-45

                if v88 < 0 then
                    v89 = -v89
                end
            else
                buffer.writef32(v1, 0, v88)
                v89 = buffer.readf32(v1, 0)
            end

            local v93 = v89 * v14.inverse_length_squared(v89, 2)

            if v89 == 0 then
                v93 = 0
            end

            if v41 < v87 or v93 < v41 then
                if not (v24 + v25 < v41) or v81 ~= 180 then
                    local v94 = if v93 < v41 then v93 - EPSILON else v87 + EPSILON

                    rt.assign(p21, (scaled_add(normalize(t5), v94, p17)))

                    return t1.solve_reference(p17, p18, p19, p20, p21, p22, p23, p24 - 1)
                end

                local v95 = normalize(t8)
                local v96 = scaled_add(v95, v24, v32)
                local v97 = scaled_add(v95, v25, v96)

                rt.assign(p20, transform_point(t7, v96))
                rt.assign(p21, transform_point(t7, v97))

                return "Extended"
            end

            if acos((vector_min(1, vector_max(0, reciprocal(v45, 2) * (v46 - v36))))) * TO_DEGREES <= p22.minimum_degrees then
                rt.assign(p21, (scaled_add(normalize(t5), v87 + EPSILON, p17)))

                return t1.solve_reference(p17, p18, p19, p20, p21, p22, p23, p24 - 1)
            end

            local v100 = acos(clamp_native_cosine(reciprocal(v41, 2) * t8[1]))

            if v33[2] < 0 and v35[2] > 0 or v33[2] > 0 and v35[2] < 0 then
                v100 *= -1
            end

            local v102 = acos(clamp_native_cosine(reciprocal(v44 * v41, 2) * (v42 + v36 - v43) + v100))
            local t10 = {
                v34[1] - v32[1],
                v34[2] - v32[2],
                v34[3] - v32[3],
                v34[4] - v32[4]
            }
            local v103 = candidate(t10, v102, v24, v32, t7)
            local v104 = candidate(t10, 6.2831854820251465 - v102, v24, v32, t7)

            if v34[2] > v33[2] then
                rt.assign(p20, v104)
            else
                rt.assign(p20, v103)
            end

            return "Solved"
        end
    end

    rt.assign(p20, p18)

    return "Invalid"
end

local inverse_length_squared = v14.inverse_length_squared

local function inverse_rows(p25, p26, p27, p28, p29, p30, p31, p32, p33, p34, p35, p36) -- line: 257
    -- upvalues: v1 (copy), reciprocal (copy)
    local v105 = -p30 * p32 + p29 * p33
    local v106 = -p28 * p33 + p30 * p31
    local v107 = -p29 * p31 + p28 * p32
    local v108 = -p33 * p26 + p32 * p27
    local v109 = -p31 * p27 + p33 * p25
    local v110 = -p32 * p25 + p31 * p26
    local v111 = -p27 * p29 + p26 * p30
    local v112 = -p25 * p30 + p27 * p28
    local v113 = -p26 * p28 + p25 * p29
    local v114 = reciprocal(p25 * v105 + p26 * v106 + p27 * v107, 2)
    local v115 = v105 * v114
    local v116 = v108 * v114
    local v117 = v111 * v114
    local v118 = v106 * v114
    local v119 = v109 * v114
    local v120 = v112 * v114
    local v121 = v107 * v114
    local v122 = v110 * v114
    local v123 = v113 * v114
    local v124

    if p34 ~= 0 and p34 > -1.1754943508222875E-38 and p34 < 1.1754943508222875E-38 then
        local v125 = math.abs(p34) * 7.1362384635298E+44
        local v126 = math.floor(v125)
        local v127 = v125 - v126

        v124 = if v127 > 0.5 or v127 == 0.5 and v126 % 2 == 1 then v126 + 1 else v126

        if p34 < 0 then
            v124 += 2147483648
        end
    else
        buffer.writef32(v1, 0, p34)
        v124 = buffer.readu32(v1, 0)
    end

    buffer.writeu32(v1, 0, (bit32.bxor(v124, 2147483648)))

    local v129 = buffer.readf32(v1, 0)
    local v130

    if p35 ~= 0 and p35 > -1.1754943508222875E-38 and p35 < 1.1754943508222875E-38 then
        local v131 = math.abs(p35) * 7.1362384635298E+44
        local v132 = math.floor(v131)
        local v133 = v131 - v132

        v130 = if v133 > 0.5 or v133 == 0.5 and v132 % 2 == 1 then v132 + 1 else v132

        if p35 < 0 then
            v130 += 2147483648
        end
    else
        buffer.writef32(v1, 0, p35)
        v130 = buffer.readu32(v1, 0)
    end

    buffer.writeu32(v1, 0, (bit32.bxor(v130, 2147483648)))

    local v135 = buffer.readf32(v1, 0)
    local v136

    if p36 ~= 0 and p36 > -1.1754943508222875E-38 and p36 < 1.1754943508222875E-38 then
        local v137 = math.abs(p36) * 7.1362384635298E+44
        local v138 = math.floor(v137)
        local v139 = v137 - v138

        v136 = if v139 > 0.5 or v139 == 0.5 and v138 % 2 == 1 then v138 + 1 else v138

        if p36 < 0 then
            v136 += 2147483648
        end
    else
        buffer.writef32(v1, 0, p36)
        v136 = buffer.readu32(v1, 0)
    end

    buffer.writeu32(v1, 0, (bit32.bxor(v136, 2147483648)))

    local v141 = buffer.readf32(v1, 0)

    return v115, v116, v117, v118, v119, v120, v121, v122, v123, v141 * v121 + (v135 * v118 + v129 * v115), v141 * v122 + (v135 * v119 + v129 * v116), v141 * v123 + (v135 * v120 + v129 * v117)
end

local t11 = {
    0, 0, 0, 0
}

function t1.solve(p37, p38, p39, p40, p41, p42, p43, p44) -- line: 306
    -- upvalues: rt (copy), v1 (copy), reciprocal (copy), vector_max (copy), vector_min (copy), v14 (copy), acos (copy), cos (copy), sin_cos (copy), EPSILON (copy), TO_DEGREES (copy), TO_RADIANS (copy), clamp_native_cosine (copy), inverse_length_squared (copy), inverse_rows (copy), t11 (copy)
    while p44 ~= 0 do
        local v143 = p37[1]
        local v144 = p37[2]
        local v145 = p37[3]
        local v146 = p37[4]
        local v147 = p38[1]
        local v148 = p38[2]
        local v149 = p38[3]
        local v150 = p38[4]
        local v151 = p39[1]
        local v152 = p39[2]
        local v153 = p39[3]
        local v154 = p39[4]
        local v155 = v147 - v143
        local v156 = v148 - v144
        local v157 = v149 - v145
        local v158 = v150 - v146
        local v159 = v151 - v147
        local v160 = v152 - v148
        local v161 = v153 - v149
        local v162 = v154 - v150
        local v163 = v155 * v155 + v156 * v156 + v157 * v157
        local v164, v165

        if v163 ~= 0 and v163 > -1.1754943508222875E-38 and v163 < 1.1754943508222875E-38 then
            v164 = math.abs(v163) * 7.1362384635298E+44
            v165 = math.floor(v164)

            local v166 = v164 - v165

            v150 = (if v166 > 0.5 or v166 == 0.5 and v165 % 2 == 1 then v165 + 1 else v165) * 1.401298464324817E-45

            if v163 < 0 then
                v150 = -v150
            end
        else
            buffer.writef32(v1, 0, v163)
            v150 = buffer.readf32(v1, 0)
        end

        v163 = v150 * inverse_length_squared(v150, 2)

        if v150 == 0 then
            v163 = 0
        end

        local v167 = v159 * v159 + v160 * v160 + v161 * v161
        local v168, v169, v170

        if v167 ~= 0 and v167 > -1.1754943508222875E-38 and v167 < 1.1754943508222875E-38 then
            v170 = math.abs(v167) * 7.1362384635298E+44
            v168 = math.floor(v170)

            local v171 = v170 - v168

            v169 = (if v171 > 0.5 or v171 == 0.5 and v168 % 2 == 1 then v168 + 1 else v168) * 1.401298464324817E-45

            if v167 < 0 then
                v169 = -v169
            end
        else
            buffer.writef32(v1, 0, v167)
            v169 = buffer.readf32(v1, 0)
        end

        local v172 = v169 * inverse_length_squared(v169, 2)

        if v169 == 0 then
            v172 = 0
        end

        if v163 < EPSILON or v172 < EPSILON then
            rt.assign(p40, p38)

            return "Invalid"
        end

        local v173 = p41[1] - v143

        v167 = p41[2] - v144
        v169 = p41[3] - v145
        v164 = p41[4] - v146

        local v174 = v151 - v143
        local v175 = v152 - v144
        local v176 = v153 - v145
        local v177 = inverse_length_squared(v174 * v174 + v175 * v175 + v176 * v176, 2)

        v165 = v174 * v177
        v170 = v175 * v177
        v168 = v176 * v177
        v176 = -v157 * v160 + v156 * v161
        v175 = -v155 * v161 + v157 * v159
        v174 = -v156 * v159 + v155 * v160

        local v178 = -v158 * v162 + v158 * v162
        local v179 = inverse_length_squared(v176 * v176 + v175 * v175 + v174 * v174, 2)
        local v180 = v176 * v179
        local v181 = v175 * v179
        local v182 = v174 * v179
        local v183 = v178 * v179

        v178 = inverse_length_squared(v173 * v173 + v167 * v167 + v169 * v169, 2)
        v174 = v173 * v178
        v175 = v167 * v178
        v176 = v169 * v178
        v177 = v164 * v178
        v164 = -v176 * v181 + v175 * v182
        v169 = -v174 * v182 + v176 * v180
        v167 = -v175 * v180 + v174 * v181
        v173 = -v177 * v183 + v177 * v183
        v183 = -v167 * v175 + v169 * v176
        v158 = -v164 * v176 + v167 * v174
        v178 = -v169 * v174 + v164 * v175
        v179 = -v173 * v177 + v173 * v177

        local v184, v185, v186, v187, v188, v189, v190, v191, v192, v193, v194, v195 = inverse_rows(v165, v170, v168, -v168 * v181 + v170 * v182, -v165 * v182 + v168 * v180, -v170 * v180 + v165 * v181, v180, v181, v182, v143, v144, v145)
        local v196 = v190 * v145 + (v187 * v144 + (v184 * v143 + v193))
        local v197 = v191 * v145 + (v188 * v144 + (v185 * v143 + v194))
        local v198 = v192 * v145 + (v189 * v144 + (v186 * v143 + v195))
        local v199 = v191 * v149 + (v188 * v148 + (v185 * v147 + v194))
        local v200 = v190 * v153 + (v187 * v152 + (v184 * v151 + v193))
        local v201 = v191 * v153 + (v188 * v152 + (v185 * v151 + v194))
        local v202 = v192 * v153 + (v189 * v152 + (v186 * v151 + v195))
        local v203, v204, v205, v206, v207, v208, v209, v210, v211, v212, v213, v214 = inverse_rows(v174, v175, v176, v164, v169, v167, v183, v158, v178, v143, v144, v145)
        local v215 = p41[1]
        local v216 = p41[2]
        local v217 = p41[3]
        local v218 = v209 * v217 + (v206 * v216 + (v203 * v215 + v212))
        local v219 = v210 * v217 + (v207 * v216 + (v204 * v215 + v213))
        local v220 = v211 * v217 + (v208 * v216 + (v205 * v215 + v214))

        v184 = v218 - v196
        v185 = v219 - v197
        v186 = v220 - v198
        v220 = v184 * v184 + v185 * v185

        local v221

        if v220 ~= 0 and v220 > -1.1754943508222875E-38 and v220 < 1.1754943508222875E-38 then
            v181 = math.abs(v220) * 7.1362384635298E+44
            v191 = math.floor(v181)
            v180 = v181 - v191
            v221 = if v180 > 0.5 or v180 == 0.5 and v191 % 2 == 1 then v191 + 1 else v191
            v182 = v221 * 1.401298464324817E-45

            if v220 < 0 then
                v182 = -v182
            end
        else
            buffer.writef32(v1, 0, v220)
            v182 = buffer.readf32(v1, 0)
        end

        v170 = v182 * v14.inverse_length_squared(v182, 2)

        if v182 == 0 then
            v170 = 0
        end

        v165 = v163 * v163
        v153 = v172 * v172
        v152 = 2 * v163
        v151 = v152 * v172
        v149 = v165 + v153

        if v172 ~= 0 and v172 > -1.1754943508222875E-38 and v172 < 1.1754943508222875E-38 then
            v191 = math.abs(v172) * 7.1362384635298E+44
            v192 = math.floor(v191)

            local v222 = v191 - v192
            local v223 = if v222 > 0.5 or v222 == 0.5 and v192 % 2 == 1 then v192 + 1 else v192

            v188 = if v172 < 0 then v223 + 2147483648 else v223
        else
            buffer.writef32(v1, 0, v172)
            v188 = buffer.readu32(v1, 0)
        end

        buffer.writeu32(v1, 0, (bit32.bxor(v188, 2147483648)))
        v190 = reciprocal(v163 * buffer.readf32(v1, 0), 2)

        local v225, v226

        if v159 ~= 0 and v159 > -1.1754943508222875E-38 and v159 < 1.1754943508222875E-38 then
            v206 = math.abs(v159) * 7.1362384635298E+44
            v207 = math.floor(v206)
            v225 = v206 - v207
            v226 = if v225 > 0.5 or v225 == 0.5 and v207 % 2 == 1 then v207 + 1 else v207
            v215 = if v159 < 0 then v226 + 2147483648 else v226
        else
            buffer.writef32(v1, 0, v159)
            v215 = buffer.readu32(v1, 0)
        end

        buffer.writeu32(v1, 0, (bit32.bxor(v215, 2147483648)))
        v193 = v155 * buffer.readf32(v1, 0)

        local v227

        if v160 ~= 0 and v160 > -1.1754943508222875E-38 and v160 < 1.1754943508222875E-38 then
            v207 = math.abs(v160) * 7.1362384635298E+44
            v208 = math.floor(v207)

            local v228 = v207 - v208

            v227 = if v228 > 0.5 or v228 == 0.5 and v208 % 2 == 1 then v208 + 1 else v208
            v216 = if v160 < 0 then v227 + 2147483648 else v227
        else
            buffer.writef32(v1, 0, v160)
            v216 = buffer.readu32(v1, 0)
        end

        buffer.writeu32(v1, 0, (bit32.bxor(v216, 2147483648)))
        v192 = v193 + v156 * buffer.readf32(v1, 0)

        if v161 ~= 0 and v161 > -1.1754943508222875E-38 and v161 < 1.1754943508222875E-38 then
            v206 = math.abs(v161) * 7.1362384635298E+44
            v207 = math.floor(v206)
            v225 = v206 - v207

            local v229 = if v225 > 0.5 or v225 == 0.5 and v207 % 2 == 1 then v207 + 1 else v207

            v215 = if v161 < 0 then v229 + 2147483648 else v229
        else
            buffer.writef32(v1, 0, v161)
            v215 = buffer.readu32(v1, 0)
        end

        v195 = bit32.bxor(v215, 2147483648)
        buffer.writeu32(v1, 0, v195)
        v187 = acos(v190 * (v192 + v157 * buffer.readf32(v1, 0))) * TO_DEGREES
        v161 = p42.maximum_degrees

        if not (v161 < v187 and p43) then
            v187 = v161
        end

        v188 = v149 - v151 * cos(p42.minimum_degrees * TO_RADIANS)

        local v230

        if v188 ~= 0 and v188 > -1.1754943508222875E-38 and v188 < 1.1754943508222875E-38 then
            v159 = math.abs(v188) * 7.1362384635298E+44
            v192 = math.floor(v159)
            v157 = v159 - v192
            v230 = if v157 > 0.5 or v157 == 0.5 and v192 % 2 == 1 then v192 + 1 else v192
            v160 = v230 * 1.401298464324817E-45

            if v188 < 0 then
                v160 = -v160
            end
        else
            buffer.writef32(v1, 0, v188)
            v160 = buffer.readf32(v1, 0)
        end

        v155 = v160 * v14.inverse_length_squared(v160, 2)

        if v160 == 0 then
            v155 = 0
        end

        v188 = v149 - v151 * cos(v187 * TO_RADIANS)

        local v231, v232

        if v188 ~= 0 and v188 > -1.1754943508222875E-38 and v188 < 1.1754943508222875E-38 then
            v193 = math.abs(v188) * 7.1362384635298E+44
            v194 = math.floor(v193)

            local v233 = v193 - v194

            v231 = if v233 > 0.5 or v233 == 0.5 and v194 % 2 == 1 then v194 + 1 else v194
            v232 = v231 * 1.401298464324817E-45

            if v188 < 0 then
                v232 = -v232
            end
        else
            buffer.writef32(v1, 0, v188)
            v232 = buffer.readf32(v1, 0)
        end

        v190 = v232 * v14.inverse_length_squared(v232, 2)

        if v232 == 0 then
            v190 = 0
        end

        if v170 < v155 or v190 < v170 then
            if v163 + v172 < v170 and v187 == 180 then
                v221 = inverse_length_squared(v184 * v184 + v185 * v185 + v186 * v186, 2)
                v230 = v184 * v221
                v231 = v185 * v221
                v192 = v186 * v221
                v193 = v230 * v163 + v196
                v194 = v231 * v163 + v197
                v195 = v192 * v163 + v198
                v215 = v230 * v172 + v193
                v226 = v231 * v172 + v194
                v227 = v192 * v172 + v195
                v192 = v183 * v195 + (v164 * v194 + (v174 * v193 + v143))
                v231 = v158 * v195 + (v169 * v194 + (v175 * v193 + v144))
                v230 = v178 * v195 + (v167 * v194 + (v176 * v193 + v145))
                v221 = v179 * v195 + (v173 * v194 + (v177 * v193 + v146))
                v195 = v183 * v227 + (v164 * v226 + (v174 * v215 + v143))
                v194 = v158 * v227 + (v169 * v226 + (v175 * v215 + v144))
                v193 = v178 * v227 + (v167 * v226 + (v176 * v215 + v145))
                v206 = v179 * v227 + (v173 * v226 + (v177 * v215 + v146))
                t11[1] = v192
                t11[2] = v231
                t11[3] = v230
                t11[4] = v221
                rt.assign(p40, t11)
                t11[1] = v195
                t11[2] = v194
                t11[3] = v193
                t11[4] = v206
                rt.assign(p41, t11)

                return "Extended"
            end

            v188 = if v190 < v170 then v190 - EPSILON else v155 + EPSILON
        else
            v190 = reciprocal(v151, 2) * (v149 - v220)
            v191 = vector_min(1, vector_max(0, v190))
            v188 = if acos(v191) * TO_DEGREES <= p42.minimum_degrees then v155 + EPSILON else nil
        end

        if v188 ~= nil then
            v193 = v174 * v188 + v143
            v194 = v175 * v188 + v144
            v195 = v176 * v188 + v145
            v215 = v177 * v188 + v146
            t11[1] = v193
            t11[2] = v194
            t11[3] = v195
            t11[4] = v215
            rt.assign(p41, t11)
            p44 -= 1
            continue
        end

        local v234 = acos(clamp_native_cosine(reciprocal(v170, 2) * v184))

        if v199 < 0 and v219 > 0 or v199 > 0 and v219 < 0 then
            v234 *= -1
        end

        v234 = acos(clamp_native_cosine(reciprocal(v152 * v170, 2) * (v165 + v220 - v153) + v234))

        if v199 < v201 then
            v234 = 6.2831854820251465 - v234
        end

        v221 = v200 - v196
        v230 = v201 - v197
        v231 = v202 - v198
        v192, v193 = sin_cos(v234)
        v234 = 0 * v231 + (-v192 * v230 + (v193 * v221 + 0))
        v187 = 0 * v231 + (v193 * v230 + (v192 * v221 + 0))
        v193 = 1 * v231 + (0 * v230 + (0 * v221 + 0))
        v194 = inverse_length_squared(v234 * v234 + v187 * v187 + v193 * v193, 2)
        v234 = v234 * v194 * v163 + v196
        v187 = v187 * v194 * v163 + v197
        v193 = v193 * v194 * v163 + v198
        v227 = v183 * v193 + (v164 * v187 + (v174 * v234 + v143))
        v206 = v158 * v193 + (v169 * v187 + (v175 * v234 + v144))
        v207 = v178 * v193 + (v167 * v187 + (v176 * v234 + v145))
        v208 = v179 * v193 + (v173 * v187 + (v177 * v234 + v146))
        t11[1] = v227
        t11[2] = v206
        t11[3] = v207
        t11[4] = v208
        rt.assign(p40, t11)

        return "Solved"
    end

    rt.assign(p41, p39)
    rt.assign(p40, p38)

    return "Invalid"
end

t1.clamp_native_cosine = clamp_native_cosine
t1.square_root = square_root
t1.subtract = subtract
t1.scaled_add = scaled_add
t1.candidate = candidate

return t1
