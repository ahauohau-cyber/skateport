-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/native_arithmetic")
local v2 = import("skate_core/physics/grind_contact/arithmetic")
local v3 = import("skate_core/trigonometry")
local t1 = {}

local function admission_mod() -- line: 16
    -- upvalues: import (copy)
    return import("skate_core/physics/grind_contact/admission")
end

local dot3 = v1.dot3

t1.dot3 = dot3

local v4, v5, v6, v7, v8

t1.Primitive = {}
t1.TruckContact = {}
t1.FiftyFiftyCandidate = {}

local v9 = false

function t1.set_reference(p1) -- line: 41
    -- upvalues: v9 (ref)
    local v10 = v9

    v9 = p1

    return v10
end

local v11, v12

local function deck_contact_reference(p2, p3, p4, p5, p6, p7) -- line: 53
    -- upvalues: dot3 (copy), v4 (ref), v5 (ref), v6 (ref), v11 (ref)
    if bit32.band(p3, 2097152) ~= 0 then
        return nil
    end

    local v13 = v5(p2[4], v6(p2[2], p4))
    local v14 = v6(p2[3], p6)
    local v15 = v6(p2[2], -(p4 + p5))
    local v16 = v5(v13, v14)
    local v17 = v4(v13, v14)
    local v18 = v5(v16, v15)
    local v19 = v5(v17, v15)
    local n1 = 1E+06
    local t2

    for i = 1, #p7 do
        local v21 = i - 1
        local v22 = p7[i]
        local v23 = v11(v22.start, v22["end"], { v16, v17, v18 })
        local v24 = v11(v22.start, v22["end"], { v19, v17, v18 })
        local v25 = v23 or v24

        if v25 ~= nil then
            local v26 = v4(v25, p2[4])
            local v27 = dot3(v26, v26)

            if v27 < n1 then
                n1 = v27
                t2 = {
                    position = v25,
                    primitive = v21
                }
            end
        end
    end

    return t2
end

t1.deck_contact_reference = deck_contact_reference

function t1.deck_contact(p8, p9, p10, p11, p12, p13) -- line: 107
    -- upvalues: v9 (ref), v12 (ref), deck_contact_reference (copy)
    if v9 then
        return (deck_contact_reference(p8, p9, p10, p11, p12, p13))
    end

    if bit32.band(p9, 2097152) ~= 0 then
        return nil
    end

    local v28 = p8[2]
    local v29 = p8[3]
    local v30 = p8[4]
    local v31 = v28[1]
    local v32 = v28[2]
    local v33 = v28[3]
    local v34 = v29[1]
    local v35 = v29[2]
    local v36 = v29[3]
    local v37 = v30[1]
    local v38 = v30[2]
    local v39 = v30[3]
    local v40 = v37 + v31 * p10
    local v41 = v38 + v32 * p10
    local v42 = v39 + v33 * p10
    local v43 = v34 * p12
    local v44 = v35 * p12
    local v45 = v36 * p12
    local v46 = -(p10 + p11)
    local v47 = v31 * v46
    local v48 = v32 * v46
    local v49 = v33 * v46
    local v50 = v40 + v43
    local v51 = v41 + v44
    local v52 = v42 + v45
    local v53 = v40 - v43
    local v54 = v41 - v44
    local v55 = v42 - v45
    local v56 = v50 + v47
    local v57 = v51 + v48
    local v58 = v52 + v49
    local v59 = v53 + v47
    local v60 = v54 + v48
    local v61 = v55 + v49
    local n2 = 1E+06
    local t3

    for i = 1, #p13 do
        local v63 = p13[i]
        local start, v64 = v63.start, v63["end"]
        local v65 = v12(start, v64, v50, v51, v52, v53, v54, v55, v56, v57, v58) or v12(start, v64, v59, v60, v61, v53, v54, v55, v56, v57, v58)

        if v65 ~= nil then
            local v66 = v65[1] - v37
            local v67 = v65[2] - v38
            local v68 = v65[3] - v39
            local v69 = v66 * v66 + v67 * v67 + v68 * v68

            if v69 < n2 then
                n2 = v69
                t3 = {
                    position = v65,
                    primitive = i - 1
                }
            end
        end
    end

    return t3
end

function t1.boardslide_candidate(p14, p15, p16, p17, p18, p19, p20, p21, p22, p23) -- line: 158
    -- upvalues: rt (copy), import (copy), v2 (copy), dot3 (copy), v4 (ref), v6 (ref), v8 (ref)
    if bit32.band(p20, 1073741824) ~= 0 then
        return nil
    end

    local v70 = v4(p16["end"], p16.start)
    local v71 = v6(v70, v2.reciprocal(v2.square_root(dot3(v70, v70))))

    if not (dot3(v8(v71), p14[2]) <= 0.65) and import("skate_core/physics/grind_contact/admission").Admission.test(p23, 400, v71, false).allowed then
        local v72 = dot3(v4(p14[4], p15.position), p14[2])
        local v73 = v6(p14[2], v72)

        if not (dot3(v73, v73) >= 0.003599999938160181) then
            if p18 == 100 and math.abs((dot3(p17, v71))) <= 0.75 and p19 <= 10 then
                return nil
            end

            local v75 = v4(v70, v6(p14[2], dot3(v70, p14[2])))
            local v76 = v2.square_root(dot3(v75, v75))

            if v76 > 0 then
                local v79 = math.abs((dot3(v6(v75, v2.reciprocal(v76)), p14[3])))
                local v80 = v4(p15.position, p14[4])
                local v81 = v4(v80, v6(p14[2], dot3(v80, p14[2])))
                local v82 = p21 - v2.square_root(dot3(v81, v81))

                if p22 < (if v79 > 0 then v82 / v79 * v2.square_root(1 - v79 * v79) else 999) then
                    return {
                        direction = v71,
                        centre = rt.copy(p15.position),
                        front = rt.copy(p16["end"]),
                        rear = rt.copy(p16.start),
                        primitive = p15.primitive
                    }
                end
            end
        end
    end

    return nil
end

function t1.fifty_fifty_candidate(p24, p25, p26) -- line: 221
    -- upvalues: t1 (copy)
    return t1.fifty_fifty_candidate_on_splines(p24, p25, p26, {})
end

function t1.fifty_fifty_candidate_on_splines(p27, p28, p29, p30) -- line: 227
    -- upvalues: rt (copy), v2 (copy), dot3 (copy), v4 (ref), v5 (ref), v6 (ref), v7 (ref), v8 (ref)
    local v83 = p29[1]
    local v84 = p29[2]

    if v83 == nil or v84 == nil or rt.fmax(math.abs(p28[1]), (math.abs(p28[2]))) >= 0.9 then
        return nil
    end

    if v83.primitive ~= v84.primitive then
        local v88 = p30[v83.primitive + 1]

        if v88 == nil then
            return nil
        end

        local v89 = v4(v88["end"], v88.start)
        local v90 = v6(v89, v2.inverse_square_root(dot3(v89, v89)))
        local v91 = v7(v8(v90), v90)

        if dot3(v4(v83.position, v84.position), v91) > 0.1 then
            return nil
        end
    end

    local v92 = dot3(v4(p27[4], v83.position), p27[2])
    local v93 = dot3(v4(p27[4], v84.position), p27[2])

    if rt.fmax(v92, v93) >= 0.13 then
        return nil
    end

    local v94 = v4(v83.position, v84.position)

    return {
        direction = v6(v94, v2.inverse_square_root(dot3(v94, v94))),
        centre = v6(v5(v83.position, v84.position), 0.5),
        front = rt.copy(v83.position),
        rear = rt.copy(v84.position),
        primitive = v83.primitive
    }
end

v8 = function(p31) -- line: 264
    -- upvalues: v2 (copy), dot3 (copy), v6 (ref), v7 (ref)
    local v95 = v7({ 0, 1, 0, 0 }, p31)
    local v96 = v7(v95, p31)
    local v97 = v2.square_root(dot3(v96, v96))

    if v97 <= 0 then
        return { 1, 0, 0, 0 }
    end

    if v96[2] < 0 then
        v97 = -v97
    end

    return v6(v96, v2.reciprocal(v97))
end

t1.upright_normal = v8

function t1.within_approach_angle(p32, p33, p34) -- line: 280
    -- upvalues: v2 (copy), v3 (copy), dot3 (copy), v4 (ref), v6 (ref), v8 (ref)
    local v98 = v8(p32)
    local v99 = v4(p33, v6(v98, dot3(p33, v98)))
    local v100 = v2.square_root(dot3(v99, v99))

    if v100 <= 0.001 then
        return true
    end

    return math.abs((dot3(v6(v99, v2.reciprocal(v100)), p32))) > v3.cos(p34 * 0.01745329238474369)
end

local function truck_contacts_reference(p35, p36, p37, p38, p39) -- line: 297
    -- upvalues: dot3 (copy), v4 (ref), v5 (ref), v6 (ref), v11 (ref)
    if bit32.band(p36, 2097152) ~= 0 then
        return { nil, nil }
    end

    local v102 = p35[1]
    local v103 = p35[2]
    local v104 = p35[3]
    local v105 = p35[4]
    local t4 = {
        v103[1] * -0.02 + v105[1],
        v103[2] * -0.02 + v105[2],
        v103[3] * -0.02 + v105[3],
        v103[4] * -0.02 + v105[4]
    }
    local v106 = v6(v102, p37)
    local v107 = v6(v104, p38)
    local v108 = v6(v103, -0.2)
    local t5 = {
        v5(t4, v107),
        v4(t4, v107)
    }
    local t6 = {
        nil,
        nil
    }
    local t7 = {
        1E+06, 1E+06
    }

    for i = 1, #p39 do
        local v109 = i - 1
        local v110 = p39[i]

        for j = 0, 1 do
            local v111 = v5(t5[j + 1], v106)
            local v112 = v4(t5[j + 1], v106)
            local v113 = v5(v112, v108)
            local v114 = v5(v111, v108)
            local v115 = v11(v110.start, v110["end"], { v111, v112, v113 })
            local v116 = v11(v110.start, v110["end"], { v111, v114, v113 })
            local v117 = v115 or v116

            if v117 ~= nil then
                local v118 = v4(v117, t5[j + 1])
                local v119 = dot3(v118, v118)

                if v119 < t7[j + 1] then
                    t7[j + 1] = v119
                    t6[j + 1] = {
                        position = v117,
                        primitive = v109
                    }
                end
            end
        end
    end

    return t6
end

t1.truck_contacts_reference = truck_contacts_reference

function t1.truck_contacts(p40, p41, p42, p43, p44) -- line: 364
    -- upvalues: v9 (ref), v12 (ref), truck_contacts_reference (copy)
    if v9 then
        return (truck_contacts_reference(p40, p41, p42, p43, p44))
    end

    if bit32.band(p41, 2097152) ~= 0 then
        return { nil, nil }
    end

    local v120 = p40[1]
    local v121 = p40[2]
    local v122 = p40[3]
    local v123 = p40[4]
    local v124 = v121[1]
    local v125 = v121[2]
    local v126 = v121[3]
    local v127 = v124 * -0.02 + v123[1]
    local v128 = v125 * -0.02 + v123[2]
    local v129 = v126 * -0.02 + v123[3]
    local v130 = v120[1] * p42
    local v131 = v120[2] * p42
    local v132 = v120[3] * p42
    local v133 = v122[1] * p43
    local v134 = v122[2] * p43
    local v135 = v122[3] * p43
    local v136 = v124 * -0.2
    local v137 = v125 * -0.2
    local v138 = v126 * -0.2
    local v139 = v127 + v133
    local v140 = v128 + v134
    local v141 = v129 + v135
    local v142 = v139 + v130
    local v143 = v140 + v131
    local v144 = v141 + v132
    local v145 = v139 - v130
    local v146 = v140 - v131
    local v147 = v141 - v132
    local v148 = v145 + v136
    local v149 = v146 + v137
    local v150 = v147 + v138
    local v151 = v142 + v136
    local v152 = v143 + v137
    local v153 = v144 + v138
    local v154 = v127 - v133
    local v155 = v128 - v134
    local v156 = v129 - v135
    local v157 = v154 + v130
    local v158 = v155 + v131
    local v159 = v156 + v132
    local v160 = v154 - v130
    local v161 = v155 - v131
    local v162 = v156 - v132
    local v163 = v160 + v136
    local v164 = v161 + v137
    local v165 = v162 + v138
    local v166 = v157 + v136
    local v167 = v158 + v137
    local v168 = v159 + v138
    local t8 = {
        nil,
        nil
    }
    local n3 = 1E+06
    local n4 = 1E+06

    for i = 1, #p44 do
        local v170 = p44[i]
        local start, v171 = v170.start, v170["end"]
        local v172 = v12(start, v171, v142, v143, v144, v145, v146, v147, v148, v149, v150) or v12(start, v171, v142, v143, v144, v151, v152, v153, v148, v149, v150)

        if v172 ~= nil then
            local v173 = v172[1] - v139
            local v174 = v172[2] - v140
            local v175 = v172[3] - v141
            local v176 = v173 * v173 + v174 * v174 + v175 * v175

            if v176 < n3 then
                n3 = v176
                t8[1] = {
                    position = v172,
                    primitive = i - 1
                }
            end
        end

        local v177 = v12(start, v171, v157, v158, v159, v160, v161, v162, v163, v164, v165) or v12(start, v171, v157, v158, v159, v166, v167, v168, v163, v164, v165)

        if v177 ~= nil then
            local v178 = v177[1] - v154
            local v179 = v177[2] - v155
            local v180 = v177[3] - v156
            local v181 = v178 * v178 + v179 * v179 + v180 * v180

            if v181 < n4 then
                n4 = v181
                t8[2] = {
                    position = v177,
                    primitive = i - 1
                }
            end
        end
    end

    return t8
end

v11 = function(p45, p46, p47) -- line: 437
    -- upvalues: dot3 (copy), v4 (ref), v7 (ref)
    local v182 = p47[1]
    local v183 = p47[2]
    local v184 = p47[3]
    local v185 = v4(v184, v182)
    local v186 = v4(v183, v182)
    local v187 = v4(p46, p45)
    local v188 = v7(v186, v185)
    local v189 = -dot3(v187, v188)

    if v189 ~= 0 then
        local v190 = v4(p45, v182)
        local v191 = 1 / v189
        local v192 = v191 * dot3(v190, v188)

        if not (v192 < 0 or v192 > 1) then
            local v193 = v7(v190, v187)
            local v194 = v191 * dot3(v185, v193)
            local v195 = 1 / -v189 * dot3(v186, v193)

            if not (v194 + v195 > 1) and not (v194 < 0) and not (v195 < 0) then
                return {
                    v187[1] * v192 + p45[1],
                    v187[2] * v192 + p45[2],
                    v187[3] * v192 + p45[3],
                    v187[4] * v192 + p45[4]
                }
            end
        end
    end

    return nil
end

t1.segment_triangle_reference = v11

v12 = function(p48, p49, p50, p51, p52, p53, p54, p55, p56, p57, p58) -- line: 478
    local v196 = p56 - p50
    local v197 = p57 - p51
    local v198 = p58 - p52
    local v199 = p53 - p50
    local v200 = p54 - p51
    local v201 = p55 - p52
    local v202 = p48[1]
    local v203 = p48[2]
    local v204 = p48[3]
    local v205 = p49[1] - v202
    local v206 = p49[2] - v203
    local v207 = p49[3] - v204
    local v208 = -v201 * v197 + v200 * v198
    local v209 = -v199 * v198 + v201 * v196
    local v210 = -v200 * v196 + v199 * v197
    local v211 = -(v205 * v208 + v206 * v209 + v207 * v210)

    if v211 ~= 0 then
        local v212 = v202 - p50
        local v213 = v203 - p51
        local v214 = v204 - p52
        local v215 = 1 / v211
        local v216 = v215 * (v212 * v208 + v213 * v209 + v214 * v210)

        if not (v216 < 0 or v216 > 1) then
            local v217 = -v214 * v206 + v213 * v207
            local v218 = -v212 * v207 + v214 * v205
            local v219 = -v213 * v205 + v212 * v206
            local v220 = v215 * (v196 * v217 + v197 * v218 + v198 * v219)
            local v221 = 1 / -v211 * (v199 * v217 + v200 * v218 + v201 * v219)

            if not (v220 + v221 > 1) and not (v220 < 0) and not (v221 < 0) then
                local v222 = p48[4]

                return {
                    v205 * v216 + v202,
                    v206 * v216 + v203,
                    v207 * v216 + v204,
                    (p49[4] - v222) * v216 + v222
                }
            end
        end
    end

    return nil
end

t1.segment_triangle_xyz = v12

t1.segment_triangle = function(p59, p60, p61) -- line: 521
    -- upvalues: v9 (ref), v11 (ref), v12 (ref)
    if v9 then
        return v11(p59, p60, p61)
    end

    local v223 = p61[1]
    local v224 = p61[2]
    local v225 = p61[3]

    return v12(p59, p60, v223[1], v223[2], v223[3], v224[1], v224[2], v224[3], v225[1], v225[2], v225[3])
end

v4 = function(p62, p63) -- line: 530
    return {
        p62[1] - p63[1],
        p62[2] - p63[2],
        p62[3] - p63[3],
        p62[4] - p63[4]
    }
end

t1.sub = v4

v5 = function(p64, p65) -- line: 535
    return {
        p64[1] + p65[1],
        p64[2] + p65[2],
        p64[3] + p65[3],
        p64[4] + p65[4]
    }
end

t1.add = v5

v6 = function(p66, p67) -- line: 540
    return {
        p66[1] * p67,
        p66[2] * p67,
        p66[3] * p67,
        p66[4] * p67
    }
end

t1.scale = v6

v7 = function(p68, p69) -- line: 545
    return {
        -p68[3] * p69[2] + p68[2] * p69[3],
        -p68[1] * p69[3] + p68[3] * p69[1],
        -p68[2] * p69[1] + p68[1] * p69[2],
        0
    }
end

t1.cross = v7

return t1
