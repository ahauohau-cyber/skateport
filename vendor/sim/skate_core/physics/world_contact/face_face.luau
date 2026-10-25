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

local function rtl_fround(p3) -- line: 24
    -- upvalues: v1 (copy)
    if p3 ~= 0 and p3 > -1.1754943508222875E-38 and p3 < 1.1754943508222875E-38 then
        local v9 = math.abs(p3) * 7.1362384635298E+44
        local v8 = math.floor(v9)
        local v10 = v9 - v8

        if v10 > 0.5 or v10 == 0.5 and v8 % 2 == 1 then
            v8 += 1
        end

        local v11 = v8 * 1.401298464324817E-45

        if p3 < 0 then
            return -v11
        end

        return v11
    end

    buffer.writef32(v1, 0, p3)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local v12 = import("skate_core/physics/world_contact/face_edge")
local v13 = import("skate_core/physics/world_contact/prism_math")
local intersect_feature_corner_edge = v12.intersect_feature_corner_edge
local load, dot, sub, scale = v13.load, v13.dot, v13.sub, v13.scale
local madd, inverse_length = v13.madd, v13.inverse_length
local t1 = {
    OUTSIDE_A = 1073741824,
    OUTSIDE_B = 536870912
}

local function vertex(p4, p5) -- line: 54
    -- upvalues: load (copy)
    return load(p4, 4 + p5 * 16)
end

t1.vertex = vertex

function t1.plane_distance(p6, p7, p8) -- line: 59
    -- upvalues: load (copy), dot (copy), sub (copy), vertex (copy)
    return dot(load(p6, 12 + p7 * 16), sub(p8, vertex(p6, p7)))
end

local function project_to_face(p9, p10) -- line: 64
    -- upvalues: load (copy), dot (copy), sub (copy), madd (copy)
    local v14 = load(p9, 132)

    return madd(v14, dot(v14, sub(load(p9, 4), p10)), p10)
end

t1.project_to_face = project_to_face

local function append(p11, p12, p13) -- line: 70
    -- upvalues: v1 (copy)
    local v15 = p11[133] * 4

    if not (v15 < 64) then
        error("feature prism point capacity exceeded", 0)
    end

    local v16 = v15 + 1
    local v17 = p12[1]
    local v18

    if v17 ~= 0 and v17 > -1.1754943508222875E-38 and v17 < 1.1754943508222875E-38 then
        local v19 = math.abs(v17) * 7.1362384635298E+44
        local v20 = math.floor(v19)
        local v21 = v19 - v20

        v18 = if v21 > 0.5 or v21 == 0.5 and v20 % 2 == 1 then v20 + 1 else v20

        if v17 < 0 then
            v18 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v17)
        v18 = buffer.readu32(v1, 0)
    end

    p11[v16] = v18

    local v22 = v15 + 2
    local v23 = p12[2]
    local v24

    if v23 ~= 0 and v23 > -1.1754943508222875E-38 and v23 < 1.1754943508222875E-38 then
        local v25 = math.abs(v23) * 7.1362384635298E+44
        local v26 = math.floor(v25)
        local v27 = v25 - v26

        v24 = if v27 > 0.5 or v27 == 0.5 and v26 % 2 == 1 then v26 + 1 else v26

        if v23 < 0 then
            v24 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v23)
        v24 = buffer.readu32(v1, 0)
    end

    p11[v22] = v24

    local v28 = v15 + 3
    local v29 = p12[3]
    local v30

    if v29 ~= 0 and v29 > -1.1754943508222875E-38 and v29 < 1.1754943508222875E-38 then
        local v31 = math.abs(v29) * 7.1362384635298E+44
        local v32 = math.floor(v31)
        local v33 = v31 - v32

        v30 = if v33 > 0.5 or v33 == 0.5 and v32 % 2 == 1 then v32 + 1 else v32

        if v29 < 0 then
            v30 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v29)
        v30 = buffer.readu32(v1, 0)
    end

    p11[v28] = v30

    local v34 = v15 + 4
    local v35 = p12[4]
    local v36

    if v35 ~= 0 and v35 > -1.1754943508222875E-38 and v35 < 1.1754943508222875E-38 then
        local v37 = math.abs(v35) * 7.1362384635298E+44
        local v38 = math.floor(v37)
        local v39 = v37 - v38

        v36 = if v39 > 0.5 or v39 == 0.5 and v38 % 2 == 1 then v38 + 1 else v38

        if v35 < 0 then
            v36 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v35)
        v36 = buffer.readu32(v1, 0)
    end

    p11[v34] = v36

    local v40 = 64 + v15 + 1
    local v41 = p13[1]
    local v42

    if v41 ~= 0 and v41 > -1.1754943508222875E-38 and v41 < 1.1754943508222875E-38 then
        local v43 = math.abs(v41) * 7.1362384635298E+44
        local v44 = math.floor(v43)
        local v45 = v43 - v44

        v42 = if v45 > 0.5 or v45 == 0.5 and v44 % 2 == 1 then v44 + 1 else v44

        if v41 < 0 then
            v42 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v41)
        v42 = buffer.readu32(v1, 0)
    end

    p11[v40] = v42

    local v46 = 64 + v15 + 2
    local v47 = p13[2]
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

    p11[v46] = v48

    local v52 = 64 + v15 + 3
    local v53 = p13[3]
    local v54

    if v53 ~= 0 and v53 > -1.1754943508222875E-38 and v53 < 1.1754943508222875E-38 then
        local v55 = math.abs(v53) * 7.1362384635298E+44
        local v56 = math.floor(v55)
        local v57 = v55 - v56

        v54 = if v57 > 0.5 or v57 == 0.5 and v56 % 2 == 1 then v56 + 1 else v56

        if v53 < 0 then
            v54 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v53)
        v54 = buffer.readu32(v1, 0)
    end

    p11[v52] = v54

    local v58 = 64 + v15 + 4
    local v59 = p13[4]
    local v60

    if v59 ~= 0 and v59 > -1.1754943508222875E-38 and v59 < 1.1754943508222875E-38 then
        local v61 = math.abs(v59) * 7.1362384635298E+44
        local v62 = math.floor(v61)
        local v63 = v61 - v62

        v60 = if v63 > 0.5 or v63 == 0.5 and v62 % 2 == 1 then v62 + 1 else v62

        if v59 < 0 then
            v60 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v59)
        v60 = buffer.readu32(v1, 0)
    end

    p11[v58] = v60
    p11[133] += 1
end

t1.append = append

local function intersect_reference(p14, p15, p16) -- line: 90
    -- upvalues: rt (copy), v1 (copy), intersect_feature_corner_edge (copy), load (copy), dot (copy), sub (copy), scale (copy), madd (copy), inverse_length (copy), vertex (copy), project_to_face (copy), append (copy)
    local v64 = p15[141]
    local v65 = p16[141]
    local v66 = table.create(8, 0)
    local v67 = -rt.F32_MAX

    p14[133] = 0

    local v68 = v64 - 1
    local n1 = 0
    local n2 = 0
    local v69 = false

    for i = 0, v68 do
        local v70 = v65 - 1
        local v71 = load(p16, 4 + v70 * 16)
        local v72 = dot(load(p15, 12 + i * 16), sub(v71, vertex(p15, i)))
        local v73 = v65 - 1
        local v74 = v72
        local v75 = v70

        for j = 0, v73 do
            local v76 = load(p16, 4 + j * 16)
            local v77 = dot(load(p15, 12 + i * 16), sub(v76, vertex(p15, i)))

            if v77 < v74 then
                v75 = j
                v74 = v77
            end

            if v77 > 0 then
                local v78 = v66[j + 1]

                v66[j + 1] = bit32.bor(v78, 536870912)
            end

            if not (v77 * v72 > 0) then
                v66[v70 + 1] = bit32.bor(v66[v70 + 1], (bit32.lshift(1, i)))
            end

            v72 = v77
            v70 = j
        end

        if v67 < v74 then
            v67 = v74
            n1 = v75
            n2 = i
            v69 = true
        end
    end

    for i = 0, v65 - 1 do
        if bit32.band(v66[i + 1], 536870912) == 0 then
            local v83 = load(p16, 4 + i * 16)
            local v84 = load(p15, 132)

            append(p14, madd(v84, dot(v84, sub(load(p15, 4), v83)), v83), v83)
        end
    end

    if p14[133] ~= v65 then
        for i = 0, v65 - 1 do
            local v85 = v64 - 1
            local v86 = load(p15, 4 + v85 * 16)
            local v87 = dot(load(p16, 12 + i * 16), sub(v86, vertex(p16, i)))
            local v88 = v64 - 1
            local v89 = v87
            local v90 = v85

            for j = 0, v88 do
                local v91 = load(p15, 4 + j * 16)
                local v92 = dot(load(p16, 12 + i * 16), sub(v91, vertex(p16, i)))

                if v92 < v89 then
                    v90 = j
                    v89 = v92
                end

                if v92 > 0 then
                    local v93 = v66[j + 1]

                    v66[j + 1] = bit32.bor(v93, 1073741824)
                end

                local v94 = v87 - v92

                if not (v92 * v87 > 0) and bit32.band(v66[i + 1], (bit32.lshift(1, v85))) ~= 0 and math.abs(v94) > rt.F32_MIN_POSITIVE then
                    local v97 = 1 / v94
                    local v98 = load(p15, 4 + v85 * 16)
                    local v99 = load(p15, 8 + v85 * 16)
                    local v100 = load(p15, 16 + v85 * 16)
                    local t2 = {
                        0, 0, 0, 0
                    }
                    local v101 = v97 * (v100[1] * v87)

                    t2[1] = v99[1] * v101 + v98[1]

                    local v102 = v97 * (v100[2] * v87)

                    t2[2] = v99[2] * v102 + v98[2]

                    local v103 = v97 * (v100[3] * v87)

                    t2[3] = v99[3] * v103 + v98[3]

                    local v104 = v97 * (v100[4] * v87)

                    t2[4] = v99[4] * v104 + v98[4]
                    append(p14, t2, project_to_face(p16, t2))
                end

                v87 = v92
                v85 = j
            end

            if v67 < v89 then
                v67 = v89
                n1 = v90
                n2 = i
                v69 = false
            end
        end

        for i = 0, v64 - 1 do
            if bit32.band(v66[i + 1], 1073741824) == 0 then
                local v106 = load(p15, 4 + i * 16)

                append(p14, v106, project_to_face(p16, v106))
            end
        end

        if p14[133] == 0 then
            if v69 then
                p14[133] = intersect_feature_corner_edge(p14, p16, p15, n1, n2, false)
            else
                p14[133] = intersect_feature_corner_edge(p14, p15, p16, n1, n2, true)
            end

            local v107 = sub(load(p14, 64), load(p14, 0))
            local v108 = dot(v107, v107)
            local v109

            if v108 ~= 0 and v108 > -1.1754943508222875E-38 and v108 < 1.1754943508222875E-38 then
                local v110 = math.abs(v108) * 7.1362384635298E+44
                local v111 = math.floor(v110)
                local v112 = v110 - v111

                v109 = (if v112 > 0.5 or v112 == 0.5 and v111 % 2 == 1 then v111 + 1 else v111) * 1.401298464324817E-45

                if v108 < 0 then
                    v109 = -v109
                end
            else
                buffer.writef32(v1, 0, v108)
                v109 = buffer.readf32(v1, 0)
            end

            local v113 = if v109 == 0 then 0 else v109 * inverse_length(v109)

            if rt.F32_MIN_POSITIVE < v113 then
                local v114 = scale(v107, 1 / v113)
                local v115 = v114[1]
                local v116

                if v115 == 0 then
                    buffer.writef32(v1, 0, v115)
                    v116 = buffer.readu32(v1, 0)
                elseif v115 > -1.1754943508222875E-38 and v115 < 1.1754943508222875E-38 then
                    local v117 = math.abs(v115) * 7.1362384635298E+44

                    v116 = math.floor(v117)

                    local v118 = v117 - v116

                    if v118 > 0.5 or v118 == 0.5 and v116 % 2 == 1 then
                        v116 += 1
                    end

                    if v115 < 0 then
                        v116 += 2147483648
                    end
                else
                    buffer.writef32(v1, 0, v115)
                    v116 = buffer.readu32(v1, 0)
                end

                p14[129] = v116

                local v119 = v114[2]
                local v120

                if v119 ~= 0 and v119 > -1.1754943508222875E-38 and v119 < 1.1754943508222875E-38 then
                    local v121 = math.abs(v119) * 7.1362384635298E+44
                    local v122 = math.floor(v121)
                    local v123 = v121 - v122

                    v120 = if v123 > 0.5 or v123 == 0.5 and v122 % 2 == 1 then v122 + 1 else v122

                    if v119 < 0 then
                        v120 += 2147483648
                    end
                else
                    buffer.writef32(v1, 0, v119)
                    v120 = buffer.readu32(v1, 0)
                end

                p14[130] = v120

                local v124 = v114[3]
                local v125

                if v124 ~= 0 and v124 > -1.1754943508222875E-38 and v124 < 1.1754943508222875E-38 then
                    local v126 = math.abs(v124) * 7.1362384635298E+44
                    local v127 = math.floor(v126)
                    local v128 = v126 - v127

                    v125 = if v128 > 0.5 or v128 == 0.5 and v127 % 2 == 1 then v127 + 1 else v127

                    if v124 < 0 then
                        v125 += 2147483648
                    end
                else
                    buffer.writef32(v1, 0, v124)
                    v125 = buffer.readu32(v1, 0)
                end

                p14[131] = v125

                local v129 = v114[4]
                local v130

                if v129 ~= 0 and v129 > -1.1754943508222875E-38 and v129 < 1.1754943508222875E-38 then
                    local v131 = math.abs(v129) * 7.1362384635298E+44
                    local v132 = math.floor(v131)
                    local v133 = v131 - v132

                    v130 = if v133 > 0.5 or v133 == 0.5 and v132 % 2 == 1 then v132 + 1 else v132

                    if v129 < 0 then
                        v130 += 2147483648
                    end
                else
                    buffer.writef32(v1, 0, v129)
                    v130 = buffer.readu32(v1, 0)
                end

                p14[132] = v130
                p14[134] = 1
            end
        end
    end

    return 1
end

t1.intersect_reference = intersect_reference

local from_bits, to_bits = rt.from_bits, rt.to_bits
local v134 = table.create(8, 0)

local function append_lanes(p17, p18, p19, p20, p21, p22, p23, p24, p25) -- line: 235
    -- upvalues: to_bits (copy)
    local v135 = p17[133] * 4

    if not (v135 < 64) then
        error("feature prism point capacity exceeded", 0)
    end

    p17[v135 + 1] = to_bits(p18)
    p17[v135 + 2] = to_bits(p19)
    p17[v135 + 3] = to_bits(p20)
    p17[v135 + 4] = to_bits(p21)
    p17[64 + v135 + 1] = to_bits(p22)
    p17[64 + v135 + 2] = to_bits(p23)
    p17[64 + v135 + 3] = to_bits(p24)
    p17[64 + v135 + 4] = to_bits(p25)
    p17[133] += 1
end

local function empty_prism(p26, p27, p28, p29, p30, p31) -- line: 252
    -- upvalues: rt (copy), v1 (copy), intersect_feature_corner_edge (copy), load (copy), dot (copy), sub (copy), scale (copy), inverse_length (copy)
    if p31 then
        p26[133] = intersect_feature_corner_edge(p26, p28, p27, p29, p30, false)
    else
        p26[133] = intersect_feature_corner_edge(p26, p27, p28, p29, p30, true)
    end

    local v136 = sub(load(p26, 64), load(p26, 0))
    local v137 = dot(v136, v136)
    local v138

    if v137 ~= 0 and v137 > -1.1754943508222875E-38 and v137 < 1.1754943508222875E-38 then
        local v139 = math.abs(v137) * 7.1362384635298E+44
        local v140 = math.floor(v139)
        local v141 = v139 - v140

        v138 = (if v141 > 0.5 or v141 == 0.5 and v140 % 2 == 1 then v140 + 1 else v140) * 1.401298464324817E-45

        if v137 < 0 then
            v138 = -v138
        end
    else
        buffer.writef32(v1, 0, v137)
        v138 = buffer.readf32(v1, 0)
    end

    local v142 = if v138 == 0 then 0 else v138 * inverse_length(v138)

    if not (rt.F32_MIN_POSITIVE < v142) then
        return
    end

    local v143 = scale(v136, 1 / v142)
    local v144 = v143[1]
    local v145

    if v144 == 0 then
        buffer.writef32(v1, 0, v144)
        v145 = buffer.readu32(v1, 0)
    elseif v144 > -1.1754943508222875E-38 and v144 < 1.1754943508222875E-38 then
        local v146 = math.abs(v144) * 7.1362384635298E+44

        v145 = math.floor(v146)

        local v147 = v146 - v145

        if v147 > 0.5 or v147 == 0.5 and v145 % 2 == 1 then
            v145 += 1
        end

        if v144 < 0 then
            v145 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v144)
        v145 = buffer.readu32(v1, 0)
    end

    p26[129] = v145

    local v148 = v143[2]
    local v149

    if v148 ~= 0 and v148 > -1.1754943508222875E-38 and v148 < 1.1754943508222875E-38 then
        local v150 = math.abs(v148) * 7.1362384635298E+44
        local v151 = math.floor(v150)
        local v152 = v150 - v151

        v149 = if v152 > 0.5 or v152 == 0.5 and v151 % 2 == 1 then v151 + 1 else v151

        if v148 < 0 then
            v149 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v148)
        v149 = buffer.readu32(v1, 0)
    end

    p26[130] = v149

    local v153 = v143[3]
    local v154

    if v153 ~= 0 and v153 > -1.1754943508222875E-38 and v153 < 1.1754943508222875E-38 then
        local v155 = math.abs(v153) * 7.1362384635298E+44
        local v156 = math.floor(v155)
        local v157 = v155 - v156

        v154 = if v157 > 0.5 or v157 == 0.5 and v156 % 2 == 1 then v156 + 1 else v156

        if v153 < 0 then
            v154 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v153)
        v154 = buffer.readu32(v1, 0)
    end

    p26[131] = v154

    local v158 = v143[4]
    local v159

    if v158 ~= 0 and v158 > -1.1754943508222875E-38 and v158 < 1.1754943508222875E-38 then
        local v160 = math.abs(v158) * 7.1362384635298E+44
        local v161 = math.floor(v160)
        local v162 = v160 - v161

        v159 = if v162 > 0.5 or v162 == 0.5 and v161 % 2 == 1 then v161 + 1 else v161

        if v158 < 0 then
            v159 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v158)
        v159 = buffer.readu32(v1, 0)
    end

    p26[132] = v159
    p26[134] = 1
end

function t1.intersect(p32, p33, p34) -- line: 275
    -- upvalues: rt (copy), intersect_reference (copy), from_bits (copy), v134 (copy), append_lanes (copy), empty_prism (copy)
    local v163 = p33[141]
    local v164 = p34[141]

    if not (v163 >= 1)
        or not (v163 <= 8)
        or not (v164 >= 1)
        or not (v164 <= 8)
        or v163 % 1 ~= 0
        or v164 % 1 ~= 0 then
        return (intersect_reference(p32, p33, p34))
    end

    v134[1] = 0
    v134[2] = 0
    v134[3] = 0
    v134[4] = 0
    v134[5] = 0
    v134[6] = 0
    v134[7] = 0
    v134[8] = 0

    local v165 = -rt.F32_MAX

    p32[133] = 0

    local v166 = v163 - 1
    local n3 = 0
    local n4 = 0
    local v167 = false

    for i = 0, v166 do
        local v168 = i * 16
        local v169 = from_bits(p33[v168 + 13])
        local v170 = from_bits(p33[v168 + 14])
        local v171 = from_bits(p33[v168 + 15])
        local v172 = from_bits(p33[v168 + 5])
        local v173 = from_bits(p33[v168 + 6])
        local v174 = from_bits(p33[v168 + 7])
        local v175 = v164 - 1
        local v176 = v175 * 16
        local v177 = v169 * (from_bits(p34[5 + v176]) - v172) + v170 * (from_bits(p34[6 + v176]) - v173) + v171 * (from_bits(p34[7 + v176]) - v174)
        local v178 = v164 - 1
        local v179 = v177
        local v180 = v175

        for j = 0, v178 do
            local v181 = j * 16
            local v182 = v169 * (from_bits(p34[v181 + 5]) - v172) + v170 * (from_bits(p34[v181 + 6]) - v173) + v171 * (from_bits(p34[v181 + 7]) - v174)

            if v182 < v177 then
                v180 = j
                v177 = v182
            end

            if v182 > 0 then
                local v183 = v134[j + 1]

                v134[j + 1] = bit32.bor(v183, 536870912)
            end

            if not (v182 * v179 > 0) then
                v134[v175 + 1] = bit32.bor(v134[v175 + 1], (bit32.lshift(1, i)))
            end

            v179 = v182
            v175 = j
        end

        if v165 < v177 then
            v165 = v177
            n3 = v180
            n4 = i
            v167 = true
        end
    end

    for i = 0, v164 - 1 do
        if bit32.band(v134[i + 1], 536870912) == 0 then
            local v188 = i * 16
            local v189 = from_bits(p34[v188 + 5])
            local v190 = from_bits(p34[v188 + 6])
            local v191 = from_bits(p34[v188 + 7])
            local v192 = from_bits(p34[v188 + 8])
            local v193 = from_bits(p33[133])
            local v194 = from_bits(p33[134])
            local v195 = from_bits(p33[135])
            local v196 = from_bits(p33[136])
            local v197 = v193 * (from_bits(p33[5]) - v189) + v194 * (from_bits(p33[6]) - v190) + v195 * (from_bits(p33[7]) - v191)

            append_lanes(p32, v193 * v197 + v189, v194 * v197 + v190, v195 * v197 + v191, v196 * v197 + v192, v189, v190, v191, v192)
        end
    end

    if p32[133] ~= v164 then
        for i = 0, v164 - 1 do
            local v198 = i * 16
            local v199 = from_bits(p34[v198 + 13])
            local v200 = from_bits(p34[v198 + 14])
            local v201 = from_bits(p34[v198 + 15])
            local v202 = from_bits(p34[v198 + 5])
            local v203 = from_bits(p34[v198 + 6])
            local v204 = from_bits(p34[v198 + 7])
            local v205 = v163 - 1
            local v206 = v205 * 16
            local v207 = v199 * (from_bits(p33[5 + v206]) - v202) + v200 * (from_bits(p33[6 + v206]) - v203) + v201 * (from_bits(p33[7 + v206]) - v204)
            local v208 = v163 - 1
            local v209 = v207
            local v210 = v205

            for j = 0, v208 do
                local v211 = j * 16
                local v212 = v199 * (from_bits(p33[v211 + 5]) - v202) + v200 * (from_bits(p33[v211 + 6]) - v203) + v201 * (from_bits(p33[v211 + 7]) - v204)

                if v212 < v209 then
                    v210 = j
                    v209 = v212
                end

                if v212 > 0 then
                    local v213 = v134[j + 1]

                    v134[j + 1] = bit32.bor(v213, 1073741824)
                end

                local v214 = v207 - v212

                if not (v212 * v207 > 0) and bit32.band(v134[i + 1], (bit32.lshift(1, v205))) ~= 0 and math.abs(v214) > rt.F32_MIN_POSITIVE then
                    local v217 = 1 / v214
                    local v218 = v205 * 16
                    local v219 = from_bits(p33[9 + v218]) * (v217 * (from_bits(p33[17 + v218]) * v207)) + from_bits(p33[5 + v218])
                    local v220 = from_bits(p33[10 + v218]) * (v217 * (from_bits(p33[18 + v218]) * v207)) + from_bits(p33[6 + v218])
                    local v221 = from_bits(p33[11 + v218]) * (v217 * (from_bits(p33[19 + v218]) * v207)) + from_bits(p33[7 + v218])
                    local v222 = from_bits(p33[12 + v218]) * (v217 * (from_bits(p33[20 + v218]) * v207)) + from_bits(p33[8 + v218])
                    local v223 = from_bits(p34[133])
                    local v224 = from_bits(p34[134])
                    local v225 = from_bits(p34[135])
                    local v226 = from_bits(p34[136])
                    local v227 = v223 * (from_bits(p34[5]) - v219) + v224 * (from_bits(p34[6]) - v220) + v225 * (from_bits(p34[7]) - v221)

                    append_lanes(p32, v219, v220, v221, v222, v223 * v227 + v219, v224 * v227 + v220, v225 * v227 + v221, v226 * v227 + v222)
                end

                v207 = v212
                v205 = j
            end

            if v165 < v209 then
                v165 = v209
                n3 = v210
                n4 = i
                v167 = false
            end
        end

        for i = 0, v163 - 1 do
            if bit32.band(v134[i + 1], 1073741824) == 0 then
                local v229 = i * 16
                local v230 = from_bits(p33[v229 + 5])
                local v231 = from_bits(p33[v229 + 6])
                local v232 = from_bits(p33[v229 + 7])
                local v233 = from_bits(p33[v229 + 8])
                local v234 = from_bits(p34[133])
                local v235 = from_bits(p34[134])
                local v236 = from_bits(p34[135])
                local v237 = from_bits(p34[136])
                local v238 = v234 * (from_bits(p34[5]) - v230) + v235 * (from_bits(p34[6]) - v231) + v236 * (from_bits(p34[7]) - v232)

                append_lanes(p32, v230, v231, v232, v233, v234 * v238 + v230, v235 * v238 + v231, v236 * v238 + v232, v237 * v238 + v233)
            end
        end

        if p32[133] == 0 then
            empty_prism(p32, p33, p34, n3, n4, v167)
        end
    end

    return 1
end

return t1
