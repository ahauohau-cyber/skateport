-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = require(sim.import)("skate_core/physics/board_pose/arithmetic")
local matrix, words, sub, mul = v1.matrix, v1.words, v1.sub, v1.mul
local dot, rsqrt, normalize, cross = v1.dot, v1.rsqrt, v1.normalize, v1.cross
local t1 = {}
local to_bits, from_bits = rt.to_bits, rt.from_bits
local v2 = buffer.create(4)

local function word_f32(p1) -- line: 27
    -- upvalues: v2 (copy)
    buffer.writeu32(v2, 0, p1)

    return (buffer.readf32(v2, 0))
end

local function f32_word(p2) -- line: 31
    -- upvalues: to_bits (copy), v2 (copy)
    if p2 < 1.1754943508222875E-38 and p2 > -1.1754943508222875E-38 and p2 ~= 0 then
        return to_bits(p2)
    end

    buffer.writef32(v2, 0, p2)

    return (buffer.readu32(v2, 0))
end

local function rsqrt_x(p3) -- line: 40
    local v3 = 1 / math.sqrt(p3)
    local v4 = v3 * v3
    local v5 = v3 * 0.5 * (-p3 * v4 + 1) + v3
    local v6 = v5 * v5

    return v5 * 0.5 * (-p3 * v6 + 1) + v5
end

function t1.orthonormalize_rotation(p4) -- line: 62
    -- upvalues: to_bits (copy), v2 (copy), f32_word (copy)
    buffer.writeu32(v2, 0, p4[1])

    local v8 = buffer.readf32(v2, 0)

    buffer.writeu32(v2, 0, p4[2])

    local v10 = buffer.readf32(v2, 0)

    buffer.writeu32(v2, 0, p4[3])

    local v12 = buffer.readf32(v2, 0)

    buffer.writeu32(v2, 0, p4[4])

    local v14 = buffer.readf32(v2, 0)

    buffer.writeu32(v2, 0, p4[5])

    local v16 = buffer.readf32(v2, 0)

    buffer.writeu32(v2, 0, p4[6])

    local v18 = buffer.readf32(v2, 0)

    buffer.writeu32(v2, 0, p4[7])

    local v20 = buffer.readf32(v2, 0)

    buffer.writeu32(v2, 0, p4[8])

    local v22 = buffer.readf32(v2, 0)

    buffer.writeu32(v2, 0, p4[9])

    local v24 = buffer.readf32(v2, 0)

    buffer.writeu32(v2, 0, p4[10])

    local v26 = buffer.readf32(v2, 0)

    buffer.writeu32(v2, 0, p4[11])

    local v28 = buffer.readf32(v2, 0)

    buffer.writeu32(v2, 0, p4[12])

    local v30 = buffer.readf32(v2, 0)
    local v31 = v24 * v24 + v26 * v26 + v28 * v28
    local v32 = 1 / math.sqrt(v31)
    local v33 = v32 * v32
    local v34 = v32 * 0.5 * (-v31 * v33 + 1) + v32
    local v35 = v34 * v34
    local v36 = v34 * 0.5 * (-v31 * v35 + 1) + v34
    local v37 = v24 * v36
    local v38 = v26 * v36
    local v39 = v28 * v36
    local v40 = v30 * v36
    local v41 = v37 * v16 + v38 * v18 + v39 * v20
    local v42 = v16 - v37 * v41
    local v43 = v18 - v38 * v41
    local v44 = v20 - v39 * v41
    local v45 = v22 - v40 * v41
    local v46 = v42 * v42 + v43 * v43 + v44 * v44
    local v47 = 1 / math.sqrt(v46)
    local v48 = v47 * v47
    local v49 = v47 * 0.5 * (-v46 * v48 + 1) + v47
    local v50 = v49 * v49
    local v51 = v49 * 0.5 * (-v46 * v50 + 1) + v49
    local v52 = v42 * v51
    local v53 = v43 * v51
    local v54 = v44 * v51
    local v55 = v45 * v51
    local v56 = v37 * v8 + v38 * v10 + v39 * v12
    local v57 = v8 - v37 * v56
    local v58 = v10 - v38 * v56
    local v59 = v12 - v39 * v56
    local v60 = v14 - v40 * v56
    local v61 = v52 * v8 + v53 * v10 + v54 * v12
    local v62 = v57 - v52 * v61
    local v63 = v58 - v53 * v61
    local v64 = v59 - v54 * v61
    local v65 = v60 - v55 * v61
    local v66 = v62 * v62 + v63 * v63 + v64 * v64
    local v67 = 1 / math.sqrt(v66)
    local v68 = v67 * v67
    local v69 = v67 * 0.5 * (-v66 * v68 + 1) + v67
    local v70 = v69 * v69
    local v71 = v69 * 0.5 * (-v66 * v70 + 1) + v69
    local v72 = v62 * v71
    local v73 = v63 * v71
    local v74 = v64 * v71
    local v75 = v65 * v71
    local v76

    if v72 < 1.1754943508222875E-38 and v72 > -1.1754943508222875E-38 and v72 ~= 0 then
        v76 = to_bits(v72)
    else
        buffer.writef32(v2, 0, v72)
        v76 = buffer.readu32(v2, 0)
    end

    local v77

    if v73 < 1.1754943508222875E-38 and v73 > -1.1754943508222875E-38 and v73 ~= 0 then
        v77 = to_bits(v73)
    else
        buffer.writef32(v2, 0, v73)
        v77 = buffer.readu32(v2, 0)
    end

    local v78

    if v74 < 1.1754943508222875E-38 and v74 > -1.1754943508222875E-38 and v74 ~= 0 then
        v78 = to_bits(v74)
    else
        buffer.writef32(v2, 0, v74)
        v78 = buffer.readu32(v2, 0)
    end

    local v79

    if v75 < 1.1754943508222875E-38 and v75 > -1.1754943508222875E-38 and v75 ~= 0 then
        v79 = to_bits(v75)
    else
        buffer.writef32(v2, 0, v75)
        v79 = buffer.readu32(v2, 0)
    end

    local v80

    if v52 < 1.1754943508222875E-38 and v52 > -1.1754943508222875E-38 and v52 ~= 0 then
        v80 = to_bits(v52)
    else
        buffer.writef32(v2, 0, v52)
        v80 = buffer.readu32(v2, 0)
    end

    local v81

    if v53 < 1.1754943508222875E-38 and v53 > -1.1754943508222875E-38 and v53 ~= 0 then
        v81 = to_bits(v53)
    else
        buffer.writef32(v2, 0, v53)
        v81 = buffer.readu32(v2, 0)
    end

    local v82

    if v54 < 1.1754943508222875E-38 and v54 > -1.1754943508222875E-38 and v54 ~= 0 then
        v82 = to_bits(v54)
    else
        buffer.writef32(v2, 0, v54)
        v82 = buffer.readu32(v2, 0)
    end

    local v83

    if v55 < 1.1754943508222875E-38 and v55 > -1.1754943508222875E-38 and v55 ~= 0 then
        v83 = to_bits(v55)
    else
        buffer.writef32(v2, 0, v55)
        v83 = buffer.readu32(v2, 0)
    end

    local v84

    if v37 < 1.1754943508222875E-38 and v37 > -1.1754943508222875E-38 and v37 ~= 0 then
        v84 = to_bits(v37)
    else
        buffer.writef32(v2, 0, v37)
        v84 = buffer.readu32(v2, 0)
    end

    local v85

    if v38 < 1.1754943508222875E-38 and v38 > -1.1754943508222875E-38 and v38 ~= 0 then
        v85 = to_bits(v38)
    else
        buffer.writef32(v2, 0, v38)
        v85 = buffer.readu32(v2, 0)
    end

    local v86

    if v39 < 1.1754943508222875E-38 and v39 > -1.1754943508222875E-38 and v39 ~= 0 then
        v86 = to_bits(v39)
    else
        buffer.writef32(v2, 0, v39)
        v86 = buffer.readu32(v2, 0)
    end

    local v87

    if v40 < 1.1754943508222875E-38 and v40 > -1.1754943508222875E-38 and v40 ~= 0 then
        v87 = to_bits(v40)
    else
        buffer.writef32(v2, 0, v40)
        v87 = buffer.readu32(v2, 0)
    end

    buffer.writeu32(v2, 0, p4[13])

    local v89 = buffer.readf32(v2, 0)
    local v90

    if v89 < 1.1754943508222875E-38 and v89 > -1.1754943508222875E-38 and v89 ~= 0 then
        v90 = to_bits(v89)
    else
        buffer.writef32(v2, 0, v89)
        v90 = buffer.readu32(v2, 0)
    end

    buffer.writeu32(v2, 0, p4[14])

    local v92 = buffer.readf32(v2, 0)
    local v93

    if v92 < 1.1754943508222875E-38 and v92 > -1.1754943508222875E-38 and v92 ~= 0 then
        v93 = to_bits(v92)
    else
        buffer.writef32(v2, 0, v92)
        v93 = buffer.readu32(v2, 0)
    end

    buffer.writeu32(v2, 0, p4[15])

    local v95 = buffer.readf32(v2, 0)
    local v96

    if v95 < 1.1754943508222875E-38 and v95 > -1.1754943508222875E-38 and v95 ~= 0 then
        v96 = to_bits(v95)
    else
        buffer.writef32(v2, 0, v95)
        v96 = buffer.readu32(v2, 0)
    end

    buffer.writeu32(v2, 0, p4[16])

    return {
        v76,
        v77,
        v78,
        v79,
        v80,
        v81,
        v82,
        v83,
        v84,
        v85,
        v86,
        v87,
        v90,
        v93,
        v96,
        f32_word((buffer.readf32(v2, 0)))
    }
end

function t1.orthonormalize_rotation_reference(p5) -- line: 94
    -- upvalues: rt (copy), matrix (copy), words (copy), sub (copy), mul (copy), dot (copy), normalize (copy)
    local v98 = matrix(p5)
    local v99 = rt.copy(v98)

    for i = 2, 0, -1 do
        local v100 = rt.copy(v98[i + 1])

        for j = 2, i + 1, -1 do
            v100 = sub(v100, mul(v99[j + 1], rt.filled(4, dot(v99[j + 1], v98[i + 1], false))))
        end

        v99[i + 1] = normalize(v100, false)
    end

    return words(v99)
end

function t1.orthonormalize_part_basis_reference(p6) -- line: 109
    -- upvalues: rt (copy), matrix (copy), words (copy), mul (copy), dot (copy), rsqrt (copy), normalize (copy), cross (copy)
    local v101 = matrix(p6)
    local t2 = {
        dot(v101[1], v101[1], false),
        dot(v101[2], v101[2], false),
        dot(v101[3], v101[3], false)
    }
    local v102 = rt.map(t2, function(p7) -- line: 112
        -- upvalues: rsqrt (copy)
        local v103 = p7 * rsqrt(p7)

        if p7 == 0 then
            return 0
        end

        return v103
    end)

    for i = 0, 2 do
        v101[i + 1] = mul(v101[i + 1], rt.filled(4, rsqrt(t2[i + 1])))
    end

    local v104, v105, v106

    if v102[1] > 0 then
        if v102[2] > 0 then
            if v102[3] > 0 then
                local v108 = math.abs((dot(v101[3], v101[1], false)))
                local v110 = math.abs((dot(v101[2], v101[3], false)))
                local v112 = math.abs((dot(v101[1], v101[2], false)))

                if v110 < v108 then
                    if v110 < v112 then
                        v105 = 1
                        v106 = 2
                        v104 = 0
                    else
                        v105 = 0
                        v106 = 1
                        v104 = 2
                    end
                elseif v108 < v112 then
                    v105 = 2
                    v106 = 0
                    v104 = 1
                else
                    v105 = 0
                    v106 = 1
                    v104 = 2
                end
            else
                v105 = 0
                v106 = 1
                v104 = 2
            end
        else
            v105 = 2
            v106 = 0
            v104 = 1
        end
    else
        v105 = 1
        v106 = 2
        v104 = 0
    end

    v101[v104 + 1] = normalize(cross(v101[v105 + 1], v101[v106 + 1]), false)
    v101[v106 + 1] = normalize(cross(v101[v104 + 1], v101[v105 + 1]), false)

    return words(v101)
end

local function rsqrt_s(p8) -- line: 148
    local v113 = 1 / math.sqrt(p8)
    local v114 = v113 * v113
    local v115 = v113 * 0.5 * (-p8 * v114 + 1) + v113
    local v116 = v115 * v115

    return v115 * 0.5 * (-p8 * v116 + 1) + v115
end

function t1.orthonormalize_part_basis(p9) -- line: 164
    -- upvalues: to_bits (copy), from_bits (copy)
    local v117 = from_bits(p9[1])
    local v118 = from_bits(p9[2])
    local v119 = from_bits(p9[3])
    local v120 = from_bits(p9[4])
    local v121 = from_bits(p9[5])
    local v122 = from_bits(p9[6])
    local v123 = from_bits(p9[7])
    local v124 = from_bits(p9[8])
    local v125 = from_bits(p9[9])
    local v126 = from_bits(p9[10])
    local v127 = from_bits(p9[11])
    local v128 = from_bits(p9[12])
    local v129 = v117 * v117 + v118 * v118 + v119 * v119
    local v130 = v121 * v121 + v122 * v122 + v123 * v123
    local v131 = v125 * v125 + v126 * v126 + v127 * v127
    local v132 = 1 / math.sqrt(v129)
    local v133 = v132 * v132
    local v134 = v132 * 0.5 * (-v129 * v133 + 1) + v132
    local v135 = v134 * v134
    local v136 = v134 * 0.5 * (-v129 * v135 + 1) + v134
    local v137 = 1 / math.sqrt(v130)
    local v138 = v137 * v137
    local v139 = v137 * 0.5 * (-v130 * v138 + 1) + v137
    local v140 = v139 * v139
    local v141 = v139 * 0.5 * (-v130 * v140 + 1) + v139
    local v142 = 1 / math.sqrt(v131)
    local v143 = v142 * v142
    local v144 = v142 * 0.5 * (-v131 * v143 + 1) + v142
    local v145 = v144 * v144
    local v146 = v144 * 0.5 * (-v131 * v145 + 1) + v144
    local v147 = v129 * v136
    local v148 = v130 * v141
    local v149 = v131 * v146

    if v129 == 0 then
        v147 = 0
    end

    if v130 == 0 then
        v148 = 0
    end

    if v131 == 0 then
        v149 = 0
    end

    local v150 = v117 * v136
    local v151 = v118 * v136
    local v152 = v119 * v136
    local v153 = v120 * v136
    local v154 = v121 * v141
    local v155 = v122 * v141
    local v156 = v123 * v141
    local v157 = v124 * v141
    local v158 = v125 * v146
    local v159 = v126 * v146
    local v160 = v127 * v146
    local v161 = v128 * v146
    local n1 = 1

    if v147 > 0 then
        if v148 > 0 then
            if v149 > 0 then
                local v163 = math.abs(v158 * v150 + v159 * v151 + v160 * v152)
                local v165 = math.abs(v154 * v158 + v155 * v159 + v156 * v160)
                local v167 = math.abs(v150 * v154 + v151 * v155 + v152 * v156)

                n1 = if v165 < v163 then if v165 < v167 then 1 else 0 elseif v163 < v167 then 2 else 0
            else
                n1 = 0
            end
        else
            n1 = 2
        end
    end

    local v168, v169, v170, v171, v172, v173, v174, v175

    if n1 == 0 then
        v175 = v157
        v172 = v150
        v170 = v151
        v168 = v152
        v174 = v153
        v173 = v154
        v169 = v155
        v171 = v156
    elseif n1 == 1 then
        v175 = v161
        v172 = v154
        v170 = v155
        v168 = v156
        v174 = v157
        v173 = v158
        v169 = v159
        v171 = v160
    else
        v175 = v153
        v172 = v158
        v170 = v159
        v168 = v160
        v174 = v161
        v173 = v150
        v169 = v151
        v171 = v152
    end

    local v176 = -v168 * v169 + v170 * v171
    local v177 = -v172 * v171 + v168 * v173
    local v178 = -v170 * v173 + v172 * v169
    local v179 = -v174 * v175 + v174 * v175
    local v180 = v176 * v176 + v177 * v177 + v178 * v178
    local v181 = 1 / math.sqrt(v180)
    local v182 = v181 * v181
    local v183 = v181 * 0.5 * (-v180 * v182 + 1) + v181
    local v184 = v183 * v183
    local v185 = v183 * 0.5 * (-v180 * v184 + 1) + v183
    local v186 = v176 * v185
    local v187 = v177 * v185
    local v188 = v178 * v185
    local v189 = v179 * v185
    local v190 = -v188 * v170 + v187 * v168
    local v191 = -v186 * v168 + v188 * v172
    local v192 = -v187 * v172 + v186 * v170
    local v193 = -v189 * v174 + v189 * v174
    local v194 = v190 * v190 + v191 * v191 + v192 * v192
    local v195 = 1 / math.sqrt(v194)
    local v196 = v195 * v195
    local v197 = v195 * 0.5 * (-v194 * v196 + 1) + v195
    local v198 = v197 * v197
    local v199 = v197 * 0.5 * (-v194 * v198 + 1) + v197
    local v200 = v190 * v199
    local v201 = v191 * v199
    local v202 = v192 * v199
    local v203 = v193 * v199

    if n1 ~= 0 then
        if n1 == 1 then
            v150, v151, v152, v153, v200, v201, v202, v203, v186, v187, v188, v189 = v186, v187, v188, v189, v154, v155, v156, v157, v200, v201, v202, v203
        else
            v150 = v200
            v151 = v201
            v152 = v202
            v153 = v203
            v200 = v186
            v201 = v187
            v202 = v188
            v203 = v189
            v189 = v161
            v186 = v158
            v187 = v159
            v188 = v160
        end
    end

    return {
        to_bits(v150),
        to_bits(v151),
        to_bits(v152),
        to_bits(v153),
        to_bits(v200),
        to_bits(v201),
        to_bits(v202),
        to_bits(v203),
        to_bits(v186),
        to_bits(v187),
        to_bits(v188),
        to_bits(v189),
        to_bits(from_bits(p9[13])),
        to_bits(from_bits(p9[14])),
        to_bits(from_bits(p9[15])),
        to_bits(from_bits(p9[16]))
    }
end

return t1
