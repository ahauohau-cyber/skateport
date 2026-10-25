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

local import = require(sim.import)
local v8 = import("skate_core/physics/reciprocal_sqrt")
local v9 = import("skate_core/physics/native_arithmetic")
local estimate = v8.estimate
local t1 = {
    GroundNormalFilter = {}
}

function t1.GroundNormalFilter.initialized(p4, p5) -- line: 47
    -- upvalues: v1 (copy)
    local v10 = table.create(24, 0)
    local v11 = p4[1]
    local v12

    if v11 ~= 0 and v11 > -1.1754943508222875E-38 and v11 < 1.1754943508222875E-38 then
        local v13 = math.abs(v11) * 7.1362384635298E+44
        local v14 = math.floor(v13)
        local v15 = v13 - v14

        v12 = if v15 > 0.5 or v15 == 0.5 and v14 % 2 == 1 then v14 + 1 else v14

        if v11 < 0 then
            v12 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v11)
        v12 = buffer.readu32(v1, 0)
    end

    v10[1] = v12

    local v16 = p4[2]
    local v17

    if v16 ~= 0 and v16 > -1.1754943508222875E-38 and v16 < 1.1754943508222875E-38 then
        local v18 = math.abs(v16) * 7.1362384635298E+44
        local v19 = math.floor(v18)
        local v20 = v18 - v19

        v17 = if v20 > 0.5 or v20 == 0.5 and v19 % 2 == 1 then v19 + 1 else v19

        if v16 < 0 then
            v17 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v16)
        v17 = buffer.readu32(v1, 0)
    end

    v10[2] = v17

    local v21 = p4[3]
    local v22

    if v21 ~= 0 and v21 > -1.1754943508222875E-38 and v21 < 1.1754943508222875E-38 then
        local v23 = math.abs(v21) * 7.1362384635298E+44
        local v24 = math.floor(v23)
        local v25 = v23 - v24

        v22 = if v25 > 0.5 or v25 == 0.5 and v24 % 2 == 1 then v24 + 1 else v24

        if v21 < 0 then
            v22 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v21)
        v22 = buffer.readu32(v1, 0)
    end

    v10[3] = v22

    local v26 = p4[4]
    local v27

    if v26 ~= 0 and v26 > -1.1754943508222875E-38 and v26 < 1.1754943508222875E-38 then
        local v28 = math.abs(v26) * 7.1362384635298E+44
        local v29 = math.floor(v28)
        local v30 = v28 - v29

        v27 = if v30 > 0.5 or v30 == 0.5 and v29 % 2 == 1 then v29 + 1 else v29

        if v26 < 0 then
            v27 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v26)
        v27 = buffer.readu32(v1, 0)
    end

    v10[4] = v27

    local v31 = p5[1]
    local v32

    if v31 ~= 0 and v31 > -1.1754943508222875E-38 and v31 < 1.1754943508222875E-38 then
        local v33 = math.abs(v31) * 7.1362384635298E+44
        local v34 = math.floor(v33)
        local v35 = v33 - v34

        v32 = if v35 > 0.5 or v35 == 0.5 and v34 % 2 == 1 then v34 + 1 else v34

        if v31 < 0 then
            v32 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v31)
        v32 = buffer.readu32(v1, 0)
    end

    v10[5] = v32

    local v36 = p5[2]
    local v37

    if v36 ~= 0 and v36 > -1.1754943508222875E-38 and v36 < 1.1754943508222875E-38 then
        local v38 = math.abs(v36) * 7.1362384635298E+44
        local v39 = math.floor(v38)
        local v40 = v38 - v39

        v37 = if v40 > 0.5 or v40 == 0.5 and v39 % 2 == 1 then v39 + 1 else v39

        if v36 < 0 then
            v37 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v36)
        v37 = buffer.readu32(v1, 0)
    end

    v10[6] = v37

    local v41 = p5[3]
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

    v10[7] = v42

    local v46 = p5[4]
    local v47

    if v46 ~= 0 and v46 > -1.1754943508222875E-38 and v46 < 1.1754943508222875E-38 then
        local v48 = math.abs(v46) * 7.1362384635298E+44
        local v49 = math.floor(v48)
        local v50 = v48 - v49

        v47 = if v50 > 0.5 or v50 == 0.5 and v49 % 2 == 1 then v49 + 1 else v49

        if v46 < 0 then
            v47 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v46)
        v47 = buffer.readu32(v1, 0)
    end

    v10[8] = v47

    local v51 = p5[1]
    local v52

    if v51 ~= 0 and v51 > -1.1754943508222875E-38 and v51 < 1.1754943508222875E-38 then
        local v53 = math.abs(v51) * 7.1362384635298E+44
        local v54 = math.floor(v53)
        local v55 = v53 - v54

        v52 = if v55 > 0.5 or v55 == 0.5 and v54 % 2 == 1 then v54 + 1 else v54

        if v51 < 0 then
            v52 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v51)
        v52 = buffer.readu32(v1, 0)
    end

    v10[9] = v52

    local v56 = p5[2]
    local v57

    if v56 ~= 0 and v56 > -1.1754943508222875E-38 and v56 < 1.1754943508222875E-38 then
        local v58 = math.abs(v56) * 7.1362384635298E+44
        local v59 = math.floor(v58)
        local v60 = v58 - v59

        v57 = if v60 > 0.5 or v60 == 0.5 and v59 % 2 == 1 then v59 + 1 else v59

        if v56 < 0 then
            v57 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v56)
        v57 = buffer.readu32(v1, 0)
    end

    v10[10] = v57

    local v61 = p5[3]
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

    v10[11] = v62

    local v66 = p5[4]
    local v67

    if v66 ~= 0 and v66 > -1.1754943508222875E-38 and v66 < 1.1754943508222875E-38 then
        local v68 = math.abs(v66) * 7.1362384635298E+44
        local v69 = math.floor(v68)
        local v70 = v68 - v69

        v67 = if v70 > 0.5 or v70 == 0.5 and v69 % 2 == 1 then v69 + 1 else v69

        if v66 < 0 then
            v67 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v66)
        v67 = buffer.readu32(v1, 0)
    end

    v10[12] = v67

    return {
        words = v10
    }
end

function t1.GroundNormalFilter.publish_current(p6, p7) -- line: 63
    -- upvalues: v1 (copy)
    local words = p6.words
    local v71 = p7[1]
    local v72

    if v71 ~= 0 and v71 > -1.1754943508222875E-38 and v71 < 1.1754943508222875E-38 then
        local v73 = math.abs(v71) * 7.1362384635298E+44
        local v74 = math.floor(v73)
        local v75 = v73 - v74

        v72 = if v75 > 0.5 or v75 == 0.5 and v74 % 2 == 1 then v74 + 1 else v74

        if v71 < 0 then
            v72 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v71)
        v72 = buffer.readu32(v1, 0)
    end

    words[5] = v72

    local words2 = p6.words
    local v76 = p7[2]
    local v77

    if v76 ~= 0 and v76 > -1.1754943508222875E-38 and v76 < 1.1754943508222875E-38 then
        local v78 = math.abs(v76) * 7.1362384635298E+44
        local v79 = math.floor(v78)
        local v80 = v78 - v79

        v77 = if v80 > 0.5 or v80 == 0.5 and v79 % 2 == 1 then v79 + 1 else v79

        if v76 < 0 then
            v77 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v76)
        v77 = buffer.readu32(v1, 0)
    end

    words2[6] = v77

    local words3 = p6.words
    local v81 = p7[3]
    local v82

    if v81 ~= 0 and v81 > -1.1754943508222875E-38 and v81 < 1.1754943508222875E-38 then
        local v83 = math.abs(v81) * 7.1362384635298E+44
        local v84 = math.floor(v83)
        local v85 = v83 - v84

        v82 = if v85 > 0.5 or v85 == 0.5 and v84 % 2 == 1 then v84 + 1 else v84

        if v81 < 0 then
            v82 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v81)
        v82 = buffer.readu32(v1, 0)
    end

    words3[7] = v82

    local words4 = p6.words
    local v86 = p7[4]
    local v87

    if v86 ~= 0 and v86 > -1.1754943508222875E-38 and v86 < 1.1754943508222875E-38 then
        local v88 = math.abs(v86) * 7.1362384635298E+44
        local v89 = math.floor(v88)
        local v90 = v88 - v89

        v87 = if v90 > 0.5 or v90 == 0.5 and v89 % 2 == 1 then v89 + 1 else v89

        if v86 < 0 then
            v87 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v86)
        v87 = buffer.readu32(v1, 0)
    end

    words4[8] = v87
end

function t1.GroundNormalFilter.filter_raw(p8, p9, p10) -- line: 69
    -- upvalues: v1 (copy), t1 (copy)
    local words = p8.words
    local v91 = p9[1]
    local v92

    if v91 ~= 0 and v91 > -1.1754943508222875E-38 and v91 < 1.1754943508222875E-38 then
        local v93 = math.abs(v91) * 7.1362384635298E+44
        local v94 = math.floor(v93)
        local v95 = v93 - v94

        v92 = if v95 > 0.5 or v95 == 0.5 and v94 % 2 == 1 then v94 + 1 else v94

        if v91 < 0 then
            v92 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v91)
        v92 = buffer.readu32(v1, 0)
    end

    words[1] = v92

    local words2 = p8.words
    local v96 = p9[2]
    local v97

    if v96 ~= 0 and v96 > -1.1754943508222875E-38 and v96 < 1.1754943508222875E-38 then
        local v98 = math.abs(v96) * 7.1362384635298E+44
        local v99 = math.floor(v98)
        local v100 = v98 - v99

        v97 = if v100 > 0.5 or v100 == 0.5 and v99 % 2 == 1 then v99 + 1 else v99

        if v96 < 0 then
            v97 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v96)
        v97 = buffer.readu32(v1, 0)
    end

    words2[2] = v97

    local words3 = p8.words
    local v101 = p9[3]
    local v102

    if v101 ~= 0 and v101 > -1.1754943508222875E-38 and v101 < 1.1754943508222875E-38 then
        local v103 = math.abs(v101) * 7.1362384635298E+44
        local v104 = math.floor(v103)
        local v105 = v103 - v104

        v102 = if v105 > 0.5 or v105 == 0.5 and v104 % 2 == 1 then v104 + 1 else v104

        if v101 < 0 then
            v102 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v101)
        v102 = buffer.readu32(v1, 0)
    end

    words3[3] = v102

    local words4 = p8.words
    local v106 = p9[4]
    local v107

    if v106 ~= 0 and v106 > -1.1754943508222875E-38 and v106 < 1.1754943508222875E-38 then
        local v108 = math.abs(v106) * 7.1362384635298E+44
        local v109 = math.floor(v108)
        local v110 = v108 - v109

        v107 = if v110 > 0.5 or v110 == 0.5 and v109 % 2 == 1 then v109 + 1 else v109

        if v106 < 0 then
            v107 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v106)
        v107 = buffer.readu32(v1, 0)
    end

    words4[4] = v107

    return t1.GroundNormalFilter.filter(p8, p10)
end

function t1.GroundNormalFilter.from_words(p11) -- line: 76
    -- upvalues: rt (copy)
    return {
        words = rt.copy(p11)
    }
end

function t1.GroundNormalFilter.words(p12) -- line: 81
    return p12.words
end

function t1.GroundNormalFilter.update(p13, p14, p15) -- line: 88
    -- upvalues: v1 (copy), estimate (copy), t1 (copy)
    local words = p13.words
    local v111 = p14[1]
    local v112

    if v111 ~= 0 and v111 > -1.1754943508222875E-38 and v111 < 1.1754943508222875E-38 then
        local v113 = math.abs(v111) * 7.1362384635298E+44
        local v114 = math.floor(v113)
        local v115 = v113 - v114

        v112 = if v115 > 0.5 or v115 == 0.5 and v114 % 2 == 1 then v114 + 1 else v114

        if v111 < 0 then
            v112 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v111)
        v112 = buffer.readu32(v1, 0)
    end

    words[1] = v112

    local words2 = p13.words
    local v116 = p14[2]
    local v117

    if v116 ~= 0 and v116 > -1.1754943508222875E-38 and v116 < 1.1754943508222875E-38 then
        local v118 = math.abs(v116) * 7.1362384635298E+44
        local v119 = math.floor(v118)
        local v120 = v118 - v119

        v117 = if v120 > 0.5 or v120 == 0.5 and v119 % 2 == 1 then v119 + 1 else v119

        if v116 < 0 then
            v117 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v116)
        v117 = buffer.readu32(v1, 0)
    end

    words2[2] = v117

    local words3 = p13.words
    local v121 = p14[3]
    local v122

    if v121 ~= 0 and v121 > -1.1754943508222875E-38 and v121 < 1.1754943508222875E-38 then
        local v123 = math.abs(v121) * 7.1362384635298E+44
        local v124 = math.floor(v123)
        local v125 = v123 - v124

        v122 = if v125 > 0.5 or v125 == 0.5 and v124 % 2 == 1 then v124 + 1 else v124

        if v121 < 0 then
            v122 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v121)
        v122 = buffer.readu32(v1, 0)
    end

    words3[3] = v122

    local words4 = p13.words
    local v126 = p14[4]
    local v127

    if v126 ~= 0 and v126 > -1.1754943508222875E-38 and v126 < 1.1754943508222875E-38 then
        local v128 = math.abs(v126) * 7.1362384635298E+44
        local v129 = math.floor(v128)
        local v130 = v128 - v129

        v127 = if v130 > 0.5 or v130 == 0.5 and v129 % 2 == 1 then v129 + 1 else v129

        if v126 < 0 then
            v127 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v126)
        v127 = buffer.readu32(v1, 0)
    end

    words4[4] = v127

    local v131 = t1.GroundNormalFilter.filter(p13, p15)
    local v132 = t1.dot3(v131)
    local v133 = estimate(v132)
    local v134 = -v132 * (v133 * v133) + 1
    local v135 = v133 * 0.5 * v134 + v133
    local v136 = -v132 * (v135 * v135) + 1
    local v137 = v135 * 0.5 * v136 + v135
    local t2 = {
        v131[1] * v137,
        v131[2] * v137,
        v131[3] * v137,
        v131[4] * v137
    }
    local words5 = p13.words
    local v138 = t2[1]
    local v139

    if v138 ~= 0 and v138 > -1.1754943508222875E-38 and v138 < 1.1754943508222875E-38 then
        local v140 = math.abs(v138) * 7.1362384635298E+44
        local v141 = math.floor(v140)
        local v142 = v140 - v141

        v139 = if v142 > 0.5 or v142 == 0.5 and v141 % 2 == 1 then v141 + 1 else v141

        if v138 < 0 then
            v139 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v138)
        v139 = buffer.readu32(v1, 0)
    end

    words5[5] = v139

    local words6 = p13.words
    local v143 = t2[2]
    local v144

    if v143 ~= 0 and v143 > -1.1754943508222875E-38 and v143 < 1.1754943508222875E-38 then
        local v145 = math.abs(v143) * 7.1362384635298E+44
        local v146 = math.floor(v145)
        local v147 = v145 - v146

        v144 = if v147 > 0.5 or v147 == 0.5 and v146 % 2 == 1 then v146 + 1 else v146

        if v143 < 0 then
            v144 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v143)
        v144 = buffer.readu32(v1, 0)
    end

    words6[6] = v144

    local words7 = p13.words
    local v148 = t2[3]
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

    words7[7] = v149

    local words8 = p13.words
    local v153 = t2[4]
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

    words8[8] = v154

    return t2
end

function t1.GroundNormalFilter.filter(p16, p17) -- line: 107
    -- upvalues: v1 (copy)
    local v158 = table.create(24)

    for i = 1, 24 do
        buffer.writeu32(v1, 0, p16.words[i])
        v158[i] = buffer.readf32(v1, 0)
    end

    local v160 = v158[4]
    local v161 = 1 - v160
    local t3 = {
        0, 0, 0, 0
    }

    for i = 0, 3 do
        local v162 = p17[i + 1] - v158[i + 4 + 1]
        local v163 = v158[i + 12 + 1] * v161 + v162 * v160
        local v164 = p17[i + 1] - v158[i + 8 + 1]
        local v165 = v158[i + 20 + 1] * v161 + v164 * v160
        local v166 = v163 * v158[2] + v158[i + 4 + 1]
        local v167 = v162 * v158[1] + v166

        t3[i + 1] = (v165 - v158[i + 16 + 1]) * v158[3] + v167

        local words = p16.words
        local v168 = i + 12 + 1

        if v163 ~= 0 and v163 > -1.1754943508222875E-38 and v163 < 1.1754943508222875E-38 then
            local v169 = math.abs(v163) * 7.1362384635298E+44
            local v170 = math.floor(v169)
            local v171 = v169 - v170
            local v172 = if v171 > 0.5 or v171 == 0.5 and v170 % 2 == 1 then v170 + 1 else v170

            if v163 < 0 then
                words[v168] = v172 + 2147483648
            else
                words[v168] = v172
            end
        else
            buffer.writef32(v1, 0, v163)
            words[v168] = buffer.readu32(v1, 0)
        end

        local words2 = p16.words
        local v173 = i + 20 + 1

        if v165 ~= 0 and v165 > -1.1754943508222875E-38 and v165 < 1.1754943508222875E-38 then
            local v174 = math.abs(v165) * 7.1362384635298E+44
            local v175 = math.floor(v174)
            local v176 = v174 - v175
            local v177 = if v176 > 0.5 or v176 == 0.5 and v175 % 2 == 1 then v175 + 1 else v175

            if v165 < 0 then
                words2[v173] = v177 + 2147483648
            else
                words2[v173] = v177
            end
        else
            buffer.writef32(v1, 0, v165)
            words2[v173] = buffer.readu32(v1, 0)
        end

        local words3 = p16.words
        local v178 = i + 16 + 1
        local v179 = t3[i + 1] - v158[i + 4 + 1]

        if v179 ~= 0 and v179 > -1.1754943508222875E-38 and v179 < 1.1754943508222875E-38 then
            local v180 = math.abs(v179) * 7.1362384635298E+44
            local v181 = math.floor(v180)
            local v182 = v180 - v181
            local v183 = if v182 > 0.5 or v182 == 0.5 and v181 % 2 == 1 then v181 + 1 else v181

            if v179 < 0 then
                words3[v178] = v183 + 2147483648
            else
                words3[v178] = v183
            end
        else
            buffer.writef32(v1, 0, v179)
            words3[v178] = buffer.readu32(v1, 0)
        end

        local words4 = p16.words
        local v184 = i + 4 + 1
        local v185 = t3[i + 1]

        if v185 ~= 0 and v185 > -1.1754943508222875E-38 and v185 < 1.1754943508222875E-38 then
            local v186 = math.abs(v185) * 7.1362384635298E+44
            local v187 = math.floor(v186)
            local v188 = v186 - v187
            local v189 = if v188 > 0.5 or v188 == 0.5 and v187 % 2 == 1 then v187 + 1 else v187

            if v185 < 0 then
                words4[v184] = v189 + 2147483648
            else
                words4[v184] = v189
            end
        else
            buffer.writef32(v1, 0, v185)
            words4[v184] = buffer.readu32(v1, 0)
        end

        local words5 = p16.words
        local v190 = i + 8 + 1
        local v191 = p17[i + 1]

        if v191 ~= 0 and v191 > -1.1754943508222875E-38 and v191 < 1.1754943508222875E-38 then
            local v192 = math.abs(v191) * 7.1362384635298E+44
            local v193 = math.floor(v192)
            local v194 = v192 - v193
            local v195 = if v194 > 0.5 or v194 == 0.5 and v193 % 2 == 1 then v193 + 1 else v193

            if v191 < 0 then
                words5[v190] = v195 + 2147483648
            else
                words5[v190] = v195
            end
        else
            buffer.writef32(v1, 0, v191)
            words5[v190] = buffer.readu32(v1, 0)
        end
    end

    return t3
end

function t1.dot3(p18) -- line: 132
    -- upvalues: v9 (copy)
    return v9.dot3(p18, p18)
end

return t1
