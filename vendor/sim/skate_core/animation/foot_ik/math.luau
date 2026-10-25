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
local atan = import("skate_core/input/angle").atan
local inverse_length_squared = import("skate_core/physics/board_motion_output").inverse_length_squared
local v12 = import("skate_core/physics/native_arithmetic")
local dot3, reciprocal_estimate = v12.dot3, v12.reciprocal_estimate
local IDENTITY = import("skate_core/physics/skeleton_animation_record").IDENTITY
local sin_cos = import("skate_core/trigonometry").sin_cos
local t1 = {}

function t1.reciprocal(p5, p6) -- line: 56
    -- upvalues: reciprocal_estimate (copy)
    local v13 = reciprocal_estimate(p5)

    for _ = 0, p6 - 1 do
        v13 = v13 * (-v13 * p5 + 1) + v13
    end

    return v13
end

function t1.length(p7) -- line: 65
    -- upvalues: v1 (copy), inverse_length_squared (copy), dot3 (copy)
    local v14 = dot3(p7, p7)
    local v15

    if v14 ~= 0 and v14 > -1.1754943508222875E-38 and v14 < 1.1754943508222875E-38 then
        local v16 = math.abs(v14) * 7.1362384635298E+44
        local v17 = math.floor(v16)
        local v18 = v16 - v17

        v15 = (if v18 > 0.5 or v18 == 0.5 and v17 % 2 == 1 then v17 + 1 else v17) * 1.401298464324817E-45

        if v14 < 0 then
            v15 = -v15
        end
    else
        buffer.writef32(v1, 0, v14)
        v15 = buffer.readf32(v1, 0)
    end

    local v19 = v15 * inverse_length_squared(v15, 2)

    if v15 == 0 then
        return 0
    end

    return v19
end

function t1.normalize(p8) -- line: 75
    -- upvalues: inverse_length_squared (copy), dot3 (copy)
    local v20 = inverse_length_squared(dot3(p8, p8), 2)

    return {
        p8[1] * v20,
        p8[2] * v20,
        p8[3] * v20,
        p8[4] * v20
    }
end

function t1.cross(p9, p10) -- line: 80
    return {
        -p9[3] * p10[2] + p9[2] * p10[3],
        -p9[1] * p10[3] + p9[3] * p10[1],
        -p9[2] * p10[1] + p9[1] * p10[2],
        -p9[4] * p10[4] + p9[4] * p10[4]
    }
end

function t1.limit_length(p11, p12) -- line: 90
    -- upvalues: rt (copy), t1 (copy)
    local v21 = t1.length(p11)

    if v21 >= 1.52587890625E-05 then
        local v22 = if p12 - v21 >= 0 then v21 else p12
        local v23 = t1.reciprocal(v21, 2)

        return {
            p11[1] * v22 * v23,
            p11[2] * v22 * v23,
            p11[3] * v22 * v23,
            p11[4] * v22 * v23
        }
    end

    return rt.copy(p11)
end

local function half_turn_axis(p13) -- line: 114
    -- upvalues: t1 (copy)
    local v24 = if p13[1][1] > p13[2][2] then if p13[1][1] > p13[3][3] then 0 else 2 elseif p13[2][2] > p13[3][3] then 1 else 2
    local t2 = {
        0, 0, 0, 0
    }

    for i = 0, 2 do
        if i == v24 then
            local v25 = 1 + p13[v24 + 1][v24 + 1]

            t2[i + 1] = v25 * v25
        else
            t2[i + 1] = p13[v24 + 1][i + 1] + p13[i + 1][v24 + 1]
        end
    end

    t2[4] = t2[1]

    return t1.normalize(t2)
end

t1.half_turn_axis = half_turn_axis

function t1.rotation_axis_angle(p14) -- line: 143
    -- upvalues: rt (copy), v1 (copy), atan (copy), t1 (copy), half_turn_axis (copy)
    local t3 = {
        p14[2][3] - p14[3][2],
        p14[3][1] - p14[1][3],
        p14[1][2] - p14[2][1],
        0
    }
    local v26 = t1.length(t3)
    local v27 = p14[1][1] + p14[2][2] + p14[3][3] - 1
    local v28

    if v26 > 0 then
        local v29 = t1.reciprocal(v26, 2) * 1

        v28 = {
            t3[1] * v29,
            t3[2] * v29,
            t3[3] * v29,
            t3[4] * v29
        }
    else
        v28 = { 0, 0, 0, 0 }
    end

    local v31 = atan(v26 * t1.reciprocal(v27, 1) + 0)

    if v27 < 0 then
        v31 += rt.copysign(3.1415927410125732, v26)
    end

    if v27 == 0 then
        v31 = rt.copysign(1.5707963705062866, v26)
    end

    buffer.writeu32(v1, 0, 2097152)

    if v26 <= buffer.readf32(v1, 0) and v27 <= 0 then
        v28 = half_turn_axis(p14)
    end

    return v28, v31
end

function t1.axis_rotation(p15, p16) -- line: 177
    -- upvalues: sin_cos (copy)
    local v32, v33 = sin_cos(p16)
    local v34 = 1 - v33
    local v35 = p15[1]
    local v36 = p15[2]
    local v37 = p15[3]
    local v38 = v32 * v35
    local v39 = v32 * v36
    local v40 = v32 * v37
    local v41 = v34 * v35
    local v42 = v34 * v36
    local v43 = v34 * v37
    local v44 = v41 * v35 + v33
    local v45 = v42 * v36 + v33
    local v46 = v43 * v37 + v33
    local v47 = v41 * v36 + v40
    local v48 = v42 * v35 - v40
    local v49 = v43 * v35 + v39
    local v50 = v41 * v37 - v39
    local v51 = v42 * v37 + v38
    local v52 = v43 * v36 - v38

    return {
        { v44, v47, v50, v44 },
        { v48, v45, v51, v48 },
        { v49, v52, v46, v49 },
        { 0, 0, 0, 0 }
    }
end

function t1.interpolate(p17, p18, p19) -- line: 220
    -- upvalues: rt (copy), v1 (copy), atan (copy), inverse_length_squared (copy), sin_cos (copy), t1 (copy)
    if p19 >= 1 then
        return rt.copy(p18), 0
    end

    local v53 = p17[1]
    local v54 = p17[2]
    local v55 = p17[3]
    local v56 = p17[4]
    local v57 = p18[1]
    local v58 = p18[2]
    local v59 = p18[3]
    local v60 = p18[4]
    local v61 = v53[1]
    local v62 = v53[2]
    local v63 = v53[3]
    local v64 = v54[1]
    local v65 = v54[2]
    local v66 = v54[3]
    local v67 = v55[1]
    local v68 = v55[2]
    local v69 = v55[3]
    local v70 = v57[1]
    local v71 = v57[2]
    local v72 = v57[3]
    local v73 = v58[1]
    local v74 = v58[2]
    local v75 = v58[3]
    local v76 = v59[1]
    local v77 = v59[2]
    local v78 = v59[3]
    local v79 = v67 * v76 + (v64 * v73 + v61 * v70)
    local v80 = v67 * v77 + (v64 * v74 + v61 * v71)
    local v81 = v67 * v78 + (v64 * v75 + v61 * v72)
    local v82 = v68 * v76 + (v65 * v73 + v62 * v70)
    local v83 = v68 * v77 + (v65 * v74 + v62 * v71)
    local v84 = v68 * v78 + (v65 * v75 + v62 * v72)
    local v85 = v69 * v76 + (v66 * v73 + v63 * v70)
    local v86 = v69 * v77 + (v66 * v74 + v63 * v71)
    local v87 = v69 * v78 + (v66 * v75 + v63 * v72)
    local v88 = v84 - v86
    local v89 = v85 - v81
    local v90 = v80 - v82
    local v91 = v88 * v88 + v89 * v89 + v90 * v90
    local v92

    if v91 ~= 0 and v91 > -1.1754943508222875E-38 and v91 < 1.1754943508222875E-38 then
        local v93 = math.abs(v91) * 7.1362384635298E+44
        local v94 = math.floor(v93)
        local v95 = v93 - v94

        v92 = (if v95 > 0.5 or v95 == 0.5 and v94 % 2 == 1 then v94 + 1 else v94) * 1.401298464324817E-45

        if v91 < 0 then
            v92 = -v92
        end
    else
        buffer.writef32(v1, 0, v91)
        v92 = buffer.readf32(v1, 0)
    end

    local v96 = v92 * inverse_length_squared(v92, 2)

    if v92 == 0 then
        v96 = 0
    end

    local v97 = v79 + v83 + v87 - 1
    local v98, v99, v100

    if v96 > 0 then
        local v101 = t1.reciprocal(v96, 2) * 1

        v98 = v88 * v101
        v99 = v89 * v101
        v100 = v90 * v101
    else
        v98 = 0
        v99 = 0
        v100 = 0
    end

    local v103 = atan(v96 * t1.reciprocal(v97, 1) + 0)

    if v97 < 0 then
        v103 += rt.copysign(3.1415927410125732, v96)
    end

    if v97 == 0 then
        v103 = rt.copysign(1.5707963705062866, v96)
    end

    buffer.writeu32(v1, 0, 2097152)

    local v104, v105, v106

    if v96 <= buffer.readf32(v1, 0) and v97 <= 0 then
        local v107, v108, v109

        if v83 < v79 then
            if v87 < v79 then
                local v110 = 1 + v79

                v107 = v110 * v110
                v108 = v80 + v82
                v109 = v81 + v85
            else
                local v111 = 1 + v87

                v107 = v85 + v81
                v108 = v86 + v84
                v109 = v111 * v111
            end
        elseif v87 < v83 then
            local v112 = 1 + v83

            v107 = v82 + v80
            v108 = v112 * v112
            v109 = v84 + v86
        else
            local v113 = 1 + v87

            v107 = v85 + v81
            v108 = v86 + v84
            v109 = v113 * v113
        end

        local v114 = inverse_length_squared(v107 * v107 + v108 * v108 + v109 * v109, 2)

        v104 = v107 * v114
        v105 = v108 * v114
        v106 = v109 * v114
    else
        v106 = v100
        v104 = v98
        v105 = v99
    end

    if p19 <= 0 then
        return rt.copy(p17), v103
    end

    local v115 = v53[4]
    local v116 = v54[4]
    local v117 = v55[4]
    local t4, t5, t6

    if v103 < 0.03490658476948738 then
        local v118 = (v70 - v61) * p19 + v61
        local v119 = (v71 - v62) * p19 + v62
        local v120 = (v72 - v63) * p19 + v63
        local v121 = (v57[4] - v115) * p19 + v115
        local v122 = inverse_length_squared(v118 * v118 + v119 * v119 + v120 * v120, 2)

        t4 = {
            v118 * v122,
            v119 * v122,
            v120 * v122,
            v121 * v122
        }

        local v123 = (v73 - v64) * p19 + v64
        local v124 = (v74 - v65) * p19 + v65
        local v125 = (v75 - v66) * p19 + v66
        local v126 = (v58[4] - v116) * p19 + v116
        local v127 = inverse_length_squared(v123 * v123 + v124 * v124 + v125 * v125, 2)

        t5 = {
            v123 * v127,
            v124 * v127,
            v125 * v127,
            v126 * v127
        }

        local v128 = (v76 - v67) * p19 + v67
        local v129 = (v77 - v68) * p19 + v68
        local v130 = (v78 - v69) * p19 + v69
        local v131 = (v59[4] - v117) * p19 + v117
        local v132 = inverse_length_squared(v128 * v128 + v129 * v129 + v130 * v130, 2)

        t6 = {
            v128 * v132,
            v129 * v132,
            v130 * v132,
            v131 * v132
        }
    else
        local v133, v134 = sin_cos(v103 * p19)
        local v135 = 1 - v134
        local v136 = v133 * v104
        local v137 = v133 * v105
        local v138 = v133 * v106
        local v139 = v135 * v104
        local v140 = v135 * v105
        local v141 = v135 * v106
        local v142 = v139 * v104 + v134
        local v143 = v140 * v105 + v134
        local v144 = v141 * v106 + v134
        local v145 = v139 * v105 + v138
        local v146 = v140 * v104 - v138
        local v147 = v141 * v104 + v137
        local v148 = v139 * v106 - v137
        local v149 = v140 * v106 + v136
        local v150 = v141 * v105 - v136

        t4 = {
            v63 * v147 + (v62 * v146 + v61 * v142),
            v63 * v150 + (v62 * v143 + v61 * v145),
            v63 * v144 + (v62 * v149 + v61 * v148),
            v63 * v147 + (v62 * v146 + v61 * v142)
        }
        t5 = {
            v66 * v147 + (v65 * v146 + v64 * v142),
            v66 * v150 + (v65 * v143 + v64 * v145),
            v66 * v144 + (v65 * v149 + v64 * v148),
            v66 * v147 + (v65 * v146 + v64 * v142)
        }
        t6 = {
            v69 * v147 + (v68 * v146 + v67 * v142),
            v69 * v150 + (v68 * v143 + v67 * v145),
            v69 * v144 + (v68 * v149 + v67 * v148),
            v69 * v147 + (v68 * v146 + v67 * v142)
        }
    end

    local v151 = v56[1]
    local v152 = v56[2]
    local v153 = v56[3]
    local v154 = v56[4]

    return {
        t4,
        t5,
        t6,
        {
            (v60[1] - v151) * p19 + v151,
            (v60[2] - v152) * p19 + v152,
            (v60[3] - v153) * p19 + v153,
            (v60[4] - v154) * p19 + v154
        }
    }, v103 - v103 * p19
end

function t1.interpolate_reference(p20, p21, p22) -- line: 369
    -- upvalues: rt (copy), IDENTITY (copy), t1 (copy)
    if p22 >= 1 then
        return rt.copy(p21), 0
    end

    local v155 = rt.copy(IDENTITY)

    for i = 0, 2 do
        local v156 = table.create(4)

        for j = 0, 3 do
            local v157 = p20[1][i + 1] * p21[1][j + 1]
            local v158 = p20[2][i + 1] * p21[2][j + 1] + v157

            v156[j + 1] = p20[3][i + 1] * p21[3][j + 1] + v158
        end

        v155[i + 1] = v156
    end

    local v159, v160 = t1.rotation_axis_angle(v155)

    if p22 <= 0 then
        return rt.copy(p20), v160
    end

    local v161 = rt.copy(IDENTITY)

    if v160 < 0.03490658476948738 then
        for i = 0, 2 do
            local v162 = table.create(4)

            for j = 0, 3 do
                v162[j + 1] = (p21[i + 1][j + 1] - p20[i + 1][j + 1]) * p22 + p20[i + 1][j + 1]
            end

            v161[i + 1] = t1.normalize(v162)
        end
    else
        local v163 = t1.axis_rotation(v159, v160 * p22)

        for i = 0, 2 do
            local v164 = table.create(4)

            for j = 0, 3 do
                local v165 = p20[i + 1][1] * v163[1][j + 1]
                local v166 = p20[i + 1][2] * v163[2][j + 1] + v165

                v164[j + 1] = p20[i + 1][3] * v163[3][j + 1] + v166
            end

            v161[i + 1] = v164
        end
    end

    local v167 = table.create(4)

    for i = 0, 3 do
        v167[i + 1] = (p21[4][i + 1] - p20[4][i + 1]) * p22 + p20[4][i + 1]
    end

    v161[4] = v167

    return v161, v160 - v160 * p22
end

function t1.interpolate_affine(p23, p24, p25) -- line: 418
    -- upvalues: t1 (copy)
    local v168 = table.create(4)

    v168[1] = p23[4][1] * (1 - p25) + p24[4][1] * p25
    v168[2] = p23[4][2] * (1 - p25) + p24[4][2] * p25
    v168[3] = p23[4][3] * (1 - p25) + p24[4][3] * p25
    v168[4] = p23[4][4] * (1 - p25) + p24[4][4] * p25

    local v169 = t1.interpolate(p23, p24, p25)

    v169[4] = v168

    return v169
end

function t1.inverse_affine(p26) -- line: 430
    -- upvalues: v1 (copy), dot3 (copy), t1 (copy)
    local t7 = {
        t1.cross(p26[2], p26[3]),
        t1.cross(p26[3], p26[1]),
        t1.cross(p26[1], p26[2])
    }
    local v170 = t1.reciprocal(dot3(p26[1], t7[1]), 2)
    local v171 = table.create(4)

    for i = 0, 3 do
        if i == 3 then
            v171[i + 1] = { 0, 0, 0, 0 }
        else
            v171[i + 1] = {
                t7[1][i + 1] * v170,
                t7[2][i + 1] * v170,
                t7[3][i + 1] * v170,
                t7[2][i + 1] * v170
            }
        end
    end

    local v172 = table.create(4)

    for i = 0, 3 do
        local v173 = i + 1
        local v174 = p26[4][i + 1]
        local v175

        if v174 ~= 0 and v174 > -1.1754943508222875E-38 and v174 < 1.1754943508222875E-38 then
            local v176 = math.abs(v174) * 7.1362384635298E+44
            local v177 = math.floor(v176)
            local v178 = v176 - v177
            local v179 = if v178 > 0.5 or v178 == 0.5 and v177 % 2 == 1 then v177 + 1 else v177

            v175 = if v174 < 0 then v179 + 2147483648 else v179
        else
            buffer.writef32(v1, 0, v174)
            v175 = buffer.readu32(v1, 0)
        end

        buffer.writeu32(v1, 0, (bit32.bxor(v175, 2147483648)))
        v172[v173] = buffer.readf32(v1, 0)
    end

    local v181 = table.create(4)

    for i = 0, 3 do
        local v182 = v172[1] * v171[1][i + 1]
        local v183 = v172[2] * v171[2][i + 1] + v182

        v181[i + 1] = v172[3] * v171[3][i + 1] + v183
    end

    v171[4] = v181

    return v171
end

return t1
