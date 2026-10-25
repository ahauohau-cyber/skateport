-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_from_bits(p1) -- line: 7
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p1)

    return (buffer.readf32(v1, 0))
end

local v2 = require(sim.import)("skate_core/physics/reciprocal_sqrt")
local t1 = {}

local function round_ties_even(p2) -- line: 22
    local v3 = math.floor(p2)
    local v4 = p2 - v3

    if v4 < 0.5 or not (v4 > 0.5) and v3 % 2 == 0 then
        return v3
    end

    return v3 + 1
end

function t1.sin_cos_reference(p3) -- line: 34
    local v5 = p3 * 0.15915493667125702
    local v6 = math.floor(v5)
    local v7 = v5 - v6

    if not (v7 < 0.5) and (v7 > 0.5 or v6 % 2 ~= 0) then
        v6 += 1
    end

    local v8 = v6 * -6.2831854820251465 + p3
    local v9 = v8 * v8
    local v10 = v9 * v8
    local v11 = v9 * v9
    local v12 = v10 * v9
    local v13 = v10 * v10
    local v14 = v11 * v10
    local v15 = v11 * v11
    local v16 = v12 * v11
    local v17 = v12 * v12
    local v18 = v13 * v12
    local v19 = v13 * v13
    local v20 = v14 * v13
    local v21 = v15 * v14
    local v22 = v14 * v14
    local v23 = v15 * v15
    local v24 = v16 * v15
    local v25 = v17 * v16
    local v26 = v16 * v16
    local v27 = v18 * v17
    local v28 = v17 * v17
    local v29 = v19 * v18
    local v30 = v18 * v18
    local v31 = v10 * -0.1666666716337204 + v8
    local v32 = v12 * 0.008333333767950535 + v31
    local v33 = v14 * -0.00019841270113829523 + v32
    local v34 = v16 * 2.7557318844628753E-06 + v33
    local v35 = v18 * -2.5052107943679403E-08 + v34
    local v36 = v20 * 1.6059044372074283E-10 + v35
    local v37 = v21 * -7.647163609812713E-13 + v36
    local v38 = v24 * 2.8114573589663704E-15 + v37
    local v39 = v25 * -8.220635078476521E-18 + v38
    local v40 = v27 * 1.9572941524685808E-20 + v39
    local v41 = v29 * -3.868170297964731E-23 + v40
    local v42 = v9 * -0.5 + 1
    local v43 = v11 * 0.0416666679084301 + v42
    local v44 = v13 * -0.0013888889225199819 + v43
    local v45 = v15 * 2.4801587642286904E-05 + v44
    local v46 = v17 * -2.755731998149713E-07 + v45
    local v47 = v19 * 2.08767581000302E-09 + v46
    local v48 = v22 * -1.147074536050896E-11 + v47
    local v49 = v23 * 4.7794772561329454E-14 + v48
    local v50 = v26 * -1.5619206814541513E-16 + v49
    local v51 = v28 * 4.110317590937049E-19 + v50

    return v41, v30 * -8.896790959566848E-22 + v51
end

function t1.cos_reference(p4) -- line: 89
    -- upvalues: v1 (copy)
    local v52 = p4 * 0.15915493667125702
    local v53 = math.floor(v52)
    local v54 = v52 - v53

    if not (v54 < 0.5) and (v54 > 0.5 or v53 % 2 ~= 0) then
        v53 += 1
    end

    local v55 = v53 * -6.2831854820251465 + p4
    local v56 = v55 * v55
    local v57 = v56 * v56
    local v58 = v57 * v56
    local v59 = v57 * v57
    local v60 = v58 * v57
    local v61 = v58 * v58
    local v62 = v59 * v58
    local v63 = v59 * v59
    local v64 = v60 * v59
    local v65 = v61 * v60
    local t2 = {
        v57,
        v58,
        v59,
        v60,
        v61,
        v62,
        v63,
        v64,
        v60 * v60,
        v65
    }
    local t3 = {
        1026206379, 3132492641, 936381697, 3029594750, 823097032, 2907294629, 693583775, 2771653571,
        552771933, 2626056651
    }
    local v66 = v56 * -0.5 + 1

    for i = 1, 10 do
        buffer.writeu32(v1, 0, t3[i])
        v66 = buffer.readf32(v1, 0) * t2[i] + v66
    end

    return v66
end

function t1.sin_cos(p5) -- line: 133
    local v68 = p5 * 0.15915493667125702
    local v69 = math.floor(v68)
    local v70 = v68 - v69

    if not (v70 < 0.5) and (v70 > 0.5 or v69 % 2 ~= 0) then
        v69 += 1
    end

    local v71 = v69 * -6.2831854820251465 + p5
    local v72 = v71 * v71
    local v73 = v72 * v71
    local v74 = v72 * v72
    local v75 = v73 * v72
    local v76 = v73 * v73
    local v77 = v74 * v73
    local v78 = v74 * v74
    local v79 = v75 * v74
    local v80 = v75 * v75
    local v81 = v76 * v75
    local v82 = v76 * v76
    local v83 = v77 * v76
    local v84 = v78 * v77
    local v85 = v77 * v77
    local v86 = v78 * v78
    local v87 = v79 * v78
    local v88 = v80 * v79
    local v89 = v79 * v79
    local v90 = v81 * v80
    local v91 = v80 * v80
    local v92 = v82 * v81
    local v93 = v81 * v81
    local v94 = v73 * -0.1666666716337204 + v71
    local v95 = v75 * 0.008333333767950535 + v94
    local v96 = v77 * -0.00019841270113829523 + v95
    local v97 = v79 * 2.7557318844628753E-06 + v96
    local v98 = v81 * -2.5052107943679403E-08 + v97
    local v99 = v83 * 1.6059044372074283E-10 + v98
    local v100 = v84 * -7.647163609812713E-13 + v99
    local v101 = v87 * 2.8114573589663704E-15 + v100
    local v102 = v88 * -8.220635078476521E-18 + v101
    local v103 = v90 * 1.9572941524685808E-20 + v102
    local v104 = v92 * -3.868170297964731E-23 + v103
    local v105 = v72 * -0.5 + 1
    local v106 = v74 * 0.0416666679084301 + v105
    local v107 = v76 * -0.0013888889225199819 + v106
    local v108 = v78 * 2.4801587642286904E-05 + v107
    local v109 = v80 * -2.755731998149713E-07 + v108
    local v110 = v82 * 2.08767581000302E-09 + v109
    local v111 = v85 * -1.147074536050896E-11 + v110
    local v112 = v86 * 4.7794772561329454E-14 + v111
    local v113 = v89 * -1.5619206814541513E-16 + v112
    local v114 = v91 * 4.110317590937049E-19 + v113

    return v104, v93 * -8.896790959566848E-22 + v114
end

function t1.cos(p6) -- line: 188
    local v115 = p6 * 0.15915493667125702
    local v116 = math.floor(v115)
    local v117 = v115 - v116

    if not (v117 < 0.5) and (v117 > 0.5 or v116 % 2 ~= 0) then
        v116 += 1
    end

    local v118 = v116 * -6.2831854820251465 + p6
    local v119 = v118 * v118
    local v120 = v119 * v119
    local v121 = v120 * v119
    local v122 = v120 * v120
    local v123 = v121 * v120
    local v124 = v121 * v121
    local v125 = v122 * v121
    local v126 = v122 * v122
    local v127 = v123 * v122
    local v128 = v124 * v123
    local v129 = v123 * v123
    local v130 = v119 * -0.5 + 1
    local v131 = v120 * 0.0416666679084301 + v130
    local v132 = v121 * -0.0013888889225199819 + v131
    local v133 = v122 * 2.4801587642286904E-05 + v132
    local v134 = v123 * -2.755731998149713E-07 + v133
    local v135 = v124 * 2.08767581000302E-09 + v134
    local v136 = v125 * -1.147074536050896E-11 + v135
    local v137 = v126 * 4.7794772561329454E-14 + v136
    local v138 = v127 * -1.5619206814541513E-16 + v137
    local v139 = v129 * 4.110317590937049E-19 + v138

    return v128 * -8.896790959566848E-22 + v139
end

function t1.sin(p7) -- line: 221
    local v140 = p7 * 0.15915493667125702
    local v141 = math.floor(v140)
    local v142 = v140 - v141

    if not (v142 < 0.5) and (v142 > 0.5 or v141 % 2 ~= 0) then
        v141 += 1
    end

    local v143 = v141 * -6.2831854820251465 + p7
    local v144 = v143 * v143
    local v145 = v143 * v144
    local v146 = v145 * -0.1666666716337204 + v143
    local v147 = v145 * v144
    local v148 = v147 * 0.008333333767950535 + v146
    local v149 = v147 * v144
    local v150 = v149 * -0.00019841270113829523 + v148
    local v151 = v149 * v144
    local v152 = v151 * 2.7557318844628753E-06 + v150
    local v153 = v151 * v144
    local v154 = v153 * -2.5052107943679403E-08 + v152
    local v155 = v153 * v144
    local v156 = v155 * 1.6059044372074283E-10 + v154
    local v157 = v155 * v144
    local v158 = v157 * -7.647163609812713E-13 + v156
    local v159 = v157 * v144
    local v160 = v159 * 2.8114573589663704E-15 + v158
    local v161 = v159 * v144
    local v162 = v161 * -8.220635078476521E-18 + v160
    local v163 = v161 * v144
    local v164 = v163 * 1.9572941524685808E-20 + v162

    return v163 * v144 * -3.868170297964731E-23 + v164
end

function t1.sin_reference(p8) -- line: 254
    -- upvalues: v1 (copy)
    local v165 = p8 * 0.15915493667125702
    local v166 = math.floor(v165)
    local v167 = v165 - v166

    if not (v167 < 0.5) and (v167 > 0.5 or v166 % 2 ~= 0) then
        v166 += 1
    end

    local v168 = v166 * -6.2831854820251465 + p8
    local v169 = v168 * v168
    local v170 = v168 * v169

    for _, v171 in {
            3190467243, 1007192201, 3109031169, 909700893, 3000447531, 791712305, 2874621855, 659199548,
            2736235738, 515431544, 2587561377
        } do
        buffer.writeu32(v1, 0, v171)
        v168 = buffer.readf32(v1, 0) * v170 + v168
        v170 *= v169
    end

    return v168
end

function t1.acos_reference(p9) -- line: 282
    -- upvalues: t1 (copy)
    return 1.5707963705062866 - t1.asin_reference(p9)
end

function t1.acos(p10) -- line: 301
    local v172 = math.abs(p10)
    local v173 = p10 * p10 * v172
    local v174 = v172 * 2.173372507095337 + -6.537848472595215
    local v175 = v172 * 0.22480115294456482 + -1.1894282102584839
    local v176 = v172 * -0.41861972212791443 + 4.2969651222229
    local v177 = v172 * -0.058063674718141556 + 0.6165727376937866
    local v178 = v174 * v172 + 5.481792449951172
    local v179 = v175 * v172 + 1.4181066751480103
    local v180 = v176 * v172 + -4.48179292678833
    local v181 = v177 * v172 + -1.3692655563354492
    local v182 = v179 * v173 + v178
    local v183 = v181 * v173 + v180
    local v184 = 1.0000001192092896 - v172
    local v185 = 1 / math.sqrt(v184)
    local v186 = v185 * (-(v184 * 0.5) * (v185 * v185) + 0.5) + v185

    return 1.5707963705062866 - ((-v172 * p10 + p10) * v183 * v186 + p10 * v182)
end

function t1.asin(p11) -- line: 328
    local v187 = math.abs(p11)
    local v188 = p11 * p11 * v187
    local v189 = v187 * 2.173372507095337 + -6.537848472595215
    local v190 = v187 * 0.22480115294456482 + -1.1894282102584839
    local v191 = v187 * -0.41861972212791443 + 4.2969651222229
    local v192 = v187 * -0.058063674718141556 + 0.6165727376937866
    local v193 = v189 * v187 + 5.481792449951172
    local v194 = v190 * v187 + 1.4181066751480103
    local v195 = v191 * v187 + -4.48179292678833
    local v196 = v192 * v187 + -1.3692655563354492
    local v197 = v194 * v188 + v193
    local v198 = v196 * v188 + v195
    local v199 = 1.0000001192092896 - v187
    local v200 = 1 / math.sqrt(v199)
    local v201 = v200 * (-(v199 * 0.5) * (v200 * v200) + 0.5) + v200

    return (-v187 * p11 + p11) * v198 * v201 + p11 * v197
end

function t1.asin_reference(p12) -- line: 352
    -- upvalues: rt (copy), v2 (copy)
    local v202 = math.abs(p12)
    local v203 = p12 * p12 * v202
    local from_bits = rt.from_bits
    local v204 = from_bits(1074469001) * v202 + from_bits(3234936334)
    local v205 = from_bits(1046884934) * v202 + from_bits(3214425903)
    local v206 = from_bits(3201717587) * v202 + from_bits(1082753213)
    local v207 = from_bits(3178091565) * v202 + from_bits(1058920374)
    local v208 = v204 * v202 + from_bits(1085237976)
    local v209 = v205 * v202 + from_bits(1068860549)
    local v210 = v206 * v202 + from_bits(3230624473)
    local v211 = v207 * v202 + from_bits(3215934488)
    local v212 = v209 * v203 + v208
    local v213 = v211 * v203 + v210
    local v214 = from_bits(1065353217) - v202
    local v215 = v2.estimate(v214)
    local v216 = v215 * (-(v214 * 0.5) * (v215 * v215) + 0.5) + v215

    return (-v202 * p12 + p12) * v213 * v216 + p12 * v212
end

return t1
