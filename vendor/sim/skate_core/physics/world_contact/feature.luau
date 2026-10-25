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
local v12 = import("skate_core/physics/reciprocal_sqrt")

import("skate_core/physics/world_contact/arithmetic")

local v13 = import("skate_core/physics/world_contact/prism_math")
local estimate = v12.estimate
local t1 = {}

function t1.load(p5, p6) -- line: 50
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p5[p6 + 1])

    local v15 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p5[p6 + 2])

    local v17 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p5[p6 + 3])

    local v19 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p5[p6 + 4])

    return {
        v15,
        v17,
        v19,
        (buffer.readf32(v1, 0))
    }
end

function t1.initialize_feature_segment(p7, p8, p9) -- line: 63
    -- upvalues: v1 (copy), v13 (copy), estimate (copy)
    p7[1] = p8[1]
    p7[2] = p8[2]
    p7[3] = p8[3]
    p7[4] = p8[4]
    buffer.writeu32(v1, 0, p8[1])

    local v22 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p8[2])

    local v24 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p8[3])

    local v26 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p8[4])

    local t2 = {
        v22,
        v24,
        v26,
        (buffer.readf32(v1, 0))
    }

    buffer.writeu32(v1, 0, p9[1])

    local v29 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p9[2])

    local v31 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p9[3])

    local v33 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p9[4])

    local t3 = {
        v29,
        v31,
        v33,
        (buffer.readf32(v1, 0))
    }
    local t4 = {
        t3[1] - t2[1],
        t3[2] - t2[2],
        t3[3] - t2[3],
        t3[4] - t2[4]
    }
    local v35 = t4[1] * t4[1] + t4[2] * t4[2] + t4[3] * t4[3]
    local v36

    if v35 ~= 0 and v35 > -1.1754943508222875E-38 and v35 < 1.1754943508222875E-38 then
        local v37 = math.abs(v35) * 7.1362384635298E+44
        local v38 = math.floor(v37)
        local v39 = v37 - v38

        v36 = (if v39 > 0.5 or v39 == 0.5 and v38 % 2 == 1 then v38 + 1 else v38) * 1.401298464324817E-45

        if v35 < 0 then
            v36 = -v36
        end
    else
        buffer.writef32(v1, 0, v35)
        v36 = buffer.readf32(v1, 0)
    end

    local v40 = estimate(v36)
    local v41 = v40 * 0.5 * (-v36 * (v40 * v40) + 1) + v40
    local v42 = if not (v36 > 1.1920928955078125E-07) then 0 elseif v36 == 0 then 0 else v36 * v41
    local v43

    if v42 ~= 0 and v42 > -1.1754943508222875E-38 and v42 < 1.1754943508222875E-38 then
        local v44 = math.abs(v42) * 7.1362384635298E+44
        local v45 = math.floor(v44)
        local v46 = v44 - v45

        v43 = if v46 > 0.5 or v46 == 0.5 and v45 % 2 == 1 then v45 + 1 else v45

        if v42 < 0 then
            v43 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v42)
        v43 = buffer.readu32(v1, 0)
    end

    p7[13] = v43
    p7[14] = v43
    p7[15] = v43
    p7[16] = v43

    local v47 = v13.reciprocal_estimate(v42)
    local v48 = v47 * (-v47 * v42 + 1) + v47
    local t5 = if v36 > 1.1920928955078125E-07 then {
        t4[1] * v48,
        t4[2] * v48,
        t4[3] * v48,
        t4[4] * v48
    } else { 0, 0, 0, 0 }
    local v49 = t5[1]
    local v50

    if v49 ~= 0 and v49 > -1.1754943508222875E-38 and v49 < 1.1754943508222875E-38 then
        local v51 = math.abs(v49) * 7.1362384635298E+44
        local v52 = math.floor(v51)
        local v53 = v51 - v52

        v50 = if v53 > 0.5 or v53 == 0.5 and v52 % 2 == 1 then v52 + 1 else v52

        if v49 < 0 then
            v50 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v49)
        v50 = buffer.readu32(v1, 0)
    end

    p7[5] = v50

    local v54 = t5[2]
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

    p7[6] = v55

    local v59 = t5[3]
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

    p7[7] = v60

    local v64 = t5[4]
    local v65

    if v64 ~= 0 and v64 > -1.1754943508222875E-38 and v64 < 1.1754943508222875E-38 then
        local v66 = math.abs(v64) * 7.1362384635298E+44
        local v67 = math.floor(v66)
        local v68 = v66 - v67

        v65 = if v68 > 0.5 or v68 == 0.5 and v67 % 2 == 1 then v67 + 1 else v67

        if v64 < 0 then
            v65 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v64)
        v65 = buffer.readu32(v1, 0)
    end

    p7[8] = v65
end

function t1.capsule_maximum_feature_reference(p10, p11, p12, p13) -- line: 122
    -- upvalues: v1 (copy), t1 (copy)
    buffer.writeu32(v1, 0, p10[17])

    local v70 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p10[18])

    local v72 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p10[19])

    local v74 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p10[20])

    local t6 = {
        v70,
        v72,
        v74,
        (buffer.readf32(v1, 0))
    }

    buffer.writeu32(v1, 0, p11[1])

    local v77 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p11[2])

    local v79 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p11[3])

    local v81 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p11[4])

    local t7 = {
        v77,
        v79,
        v81,
        (buffer.readf32(v1, 0))
    }
    local v83 = t6[1] * t7[1] + t6[2] * t7[2] + t6[3] * t7[3]

    buffer.writeu32(v1, 0, p10[29])

    local v85 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p10[1])

    local v87 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p10[2])

    local v89 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p10[3])

    local v91 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p10[4])

    local t8 = {
        v87,
        v89,
        v91,
        (buffer.readf32(v1, 0))
    }

    if math.abs(v83) < 0.05000000074505806 then
        local t9 = {
            t6[1] * v85,
            t6[2] * v85,
            t6[3] * v85,
            t6[4] * v85
        }
        local v93 = t8[1] + t9[1]
        local v94

        if v93 == 0 then
            buffer.writef32(v1, 0, v93)
            v94 = buffer.readu32(v1, 0)
        elseif v93 > -1.1754943508222875E-38 and v93 < 1.1754943508222875E-38 then
            local v95 = math.abs(v93) * 7.1362384635298E+44

            v94 = math.floor(v95)

            local v96 = v95 - v94

            if v96 > 0.5 or v96 == 0.5 and v94 % 2 == 1 then
                v94 += 1
            end

            if v93 < 0 then
                v94 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v93)
            v94 = buffer.readu32(v1, 0)
        end

        local v97 = t8[2] + t9[2]
        local v98

        if v97 ~= 0 and v97 > -1.1754943508222875E-38 and v97 < 1.1754943508222875E-38 then
            local v99 = math.abs(v97) * 7.1362384635298E+44
            local v100 = math.floor(v99)
            local v101 = v99 - v100

            v98 = if v101 > 0.5 or v101 == 0.5 and v100 % 2 == 1 then v100 + 1 else v100

            if v97 < 0 then
                v98 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v97)
            v98 = buffer.readu32(v1, 0)
        end

        local v102 = t8[3] + t9[3]
        local v103

        if v102 ~= 0 and v102 > -1.1754943508222875E-38 and v102 < 1.1754943508222875E-38 then
            local v104 = math.abs(v102) * 7.1362384635298E+44
            local v105 = math.floor(v104)
            local v106 = v104 - v105

            v103 = if v106 > 0.5 or v106 == 0.5 and v105 % 2 == 1 then v105 + 1 else v105

            if v102 < 0 then
                v103 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v102)
            v103 = buffer.readu32(v1, 0)
        end

        local v107 = t8[4] + t9[4]
        local v108

        if v107 ~= 0 and v107 > -1.1754943508222875E-38 and v107 < 1.1754943508222875E-38 then
            local v109 = math.abs(v107) * 7.1362384635298E+44
            local v110 = math.floor(v109)
            local v111 = v109 - v110

            v108 = if v111 > 0.5 or v111 == 0.5 and v110 % 2 == 1 then v110 + 1 else v110

            if v107 < 0 then
                v108 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v107)
            v108 = buffer.readu32(v1, 0)
        end

        local t10 = {
            v94,
            v98,
            v103,
            v108
        }
        local v112 = t8[1] - t9[1]
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

        local v117 = t8[2] - t9[2]
        local v118

        if v117 ~= 0 and v117 > -1.1754943508222875E-38 and v117 < 1.1754943508222875E-38 then
            local v119 = math.abs(v117) * 7.1362384635298E+44
            local v120 = math.floor(v119)
            local v121 = v119 - v120

            v118 = if v121 > 0.5 or v121 == 0.5 and v120 % 2 == 1 then v120 + 1 else v120

            if v117 < 0 then
                v118 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v117)
            v118 = buffer.readu32(v1, 0)
        end

        local v122 = t8[3] - t9[3]
        local v123

        if v122 ~= 0 and v122 > -1.1754943508222875E-38 and v122 < 1.1754943508222875E-38 then
            local v124 = math.abs(v122) * 7.1362384635298E+44
            local v125 = math.floor(v124)
            local v126 = v124 - v125

            v123 = if v126 > 0.5 or v126 == 0.5 and v125 % 2 == 1 then v125 + 1 else v125

            if v122 < 0 then
                v123 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v122)
            v123 = buffer.readu32(v1, 0)
        end

        local v127 = t8[4] - t9[4]
        local v128

        if v127 ~= 0 and v127 > -1.1754943508222875E-38 and v127 < 1.1754943508222875E-38 then
            local v129 = math.abs(v127) * 7.1362384635298E+44
            local v130 = math.floor(v129)
            local v131 = v129 - v130

            v128 = if v131 > 0.5 or v131 == 0.5 and v130 % 2 == 1 then v130 + 1 else v130

            if v127 < 0 then
                v128 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v127)
            v128 = buffer.readu32(v1, 0)
        end

        local t11 = {
            v113,
            v118,
            v123,
            v128
        }

        t1.initialize_feature_segment(p13, t10, t11)
        p12[5] = p13[1]
        p12[6] = p13[2]
        p12[7] = p13[3]
        p12[8] = p13[4]
        p12[9] = p13[5]
        p12[10] = p13[6]
        p12[11] = p13[7]
        p12[12] = p13[8]
        p12[13] = p13[9]
        p12[14] = p13[10]
        p12[15] = p13[11]
        p12[16] = p13[12]
        p12[17] = p13[13]
        p12[18] = p13[14]
        p12[19] = p13[15]
        p12[20] = p13[16]
        p12[141] = 1
    else
        local t12 = if v83 > 0 then {
            t6[1] * v85 + t8[1],
            t6[2] * v85 + t8[2],
            t6[3] * v85 + t8[3],
            t6[4] * v85 + t8[4]
        } else {
            t8[1] - t6[1] * v85,
            t8[2] - t6[2] * v85,
            t8[3] - t6[3] * v85,
            t8[4] - t6[4] * v85
        }
        local v132 = t12[1]
        local v133

        if v132 ~= 0 and v132 > -1.1754943508222875E-38 and v132 < 1.1754943508222875E-38 then
            local v134 = math.abs(v132) * 7.1362384635298E+44
            local v135 = math.floor(v134)
            local v136 = v134 - v135

            v133 = if v136 > 0.5 or v136 == 0.5 and v135 % 2 == 1 then v135 + 1 else v135

            if v132 < 0 then
                v133 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v132)
            v133 = buffer.readu32(v1, 0)
        end

        p12[137] = v133

        local v137 = t12[2]
        local v138

        if v137 ~= 0 and v137 > -1.1754943508222875E-38 and v137 < 1.1754943508222875E-38 then
            local v139 = math.abs(v137) * 7.1362384635298E+44
            local v140 = math.floor(v139)
            local v141 = v139 - v140

            v138 = if v141 > 0.5 or v141 == 0.5 and v140 % 2 == 1 then v140 + 1 else v140

            if v137 < 0 then
                v138 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v137)
            v138 = buffer.readu32(v1, 0)
        end

        p12[138] = v138

        local v142 = t12[3]
        local v143

        if v142 ~= 0 and v142 > -1.1754943508222875E-38 and v142 < 1.1754943508222875E-38 then
            local v144 = math.abs(v142) * 7.1362384635298E+44
            local v145 = math.floor(v144)
            local v146 = v144 - v145

            v143 = if v146 > 0.5 or v146 == 0.5 and v145 % 2 == 1 then v145 + 1 else v145

            if v142 < 0 then
                v143 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v142)
            v143 = buffer.readu32(v1, 0)
        end

        p12[139] = v143

        local v147 = t12[4]
        local v148

        if v147 ~= 0 and v147 > -1.1754943508222875E-38 and v147 < 1.1754943508222875E-38 then
            local v149 = math.abs(v147) * 7.1362384635298E+44
            local v150 = math.floor(v149)
            local v151 = v149 - v150

            v148 = if v151 > 0.5 or v151 == 0.5 and v150 % 2 == 1 then v150 + 1 else v150

            if v147 < 0 then
                v148 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v147)
            v148 = buffer.readu32(v1, 0)
        end

        p12[140] = v148
        p12[141] = 0
    end

    p12[1] = 0
end

local v152 = buffer.create(8)

local function fb(p14) -- line: 181
    -- upvalues: v152 (copy)
    buffer.writeu32(v152, 0, p14)

    return (buffer.readf32(v152, 0))
end

local to_bits = rt.to_bits

local function tb(p15) -- line: 186
    -- upvalues: v152 (copy), to_bits (copy)
    if p15 ~= 0 and p15 > -1.1754943508222875E-38 and p15 < 1.1754943508222875E-38 then
        return to_bits(p15)
    end

    buffer.writef32(v152, 0, p15)

    return (buffer.readu32(v152, 0))
end

function t1.capsule_maximum_feature(p16, p17, p18, p19) -- line: 199
    -- upvalues: v1 (copy), v13 (copy), estimate (copy), v152 (copy), to_bits (copy)
    buffer.writeu32(v152, 0, p16[17])

    local v154 = buffer.readf32(v152, 0)

    buffer.writeu32(v152, 0, p16[18])

    local v155 = buffer.readf32(v152, 0)

    buffer.writeu32(v152, 0, p16[19])

    local v156 = buffer.readf32(v152, 0)

    buffer.writeu32(v152, 0, p16[20])

    local v157 = buffer.readf32(v152, 0)

    buffer.writeu32(v152, 0, p17[1])

    local v159 = v154 * buffer.readf32(v152, 0)

    buffer.writeu32(v152, 0, p17[2])

    local v161 = v159 + v155 * buffer.readf32(v152, 0)

    buffer.writeu32(v152, 0, p17[3])

    local v153 = v161 + v156 * buffer.readf32(v152, 0)

    buffer.writeu32(v152, 0, p16[29])

    local v162 = buffer.readf32(v152, 0)

    buffer.writeu32(v152, 0, p16[1])

    local v164 = buffer.readf32(v152, 0)

    buffer.writeu32(v152, 0, p16[2])

    local v165 = buffer.readf32(v152, 0)

    buffer.writeu32(v152, 0, p16[3])

    local v166 = buffer.readf32(v152, 0)

    buffer.writeu32(v152, 0, p16[4])

    local v167 = buffer.readf32(v152, 0)
    local v163 = math.abs(v153)

    buffer.writeu32(v152, 0, 1028443341)

    if v163 < buffer.readf32(v152, 0) then
        local v168 = v154 * v162
        local v169 = v155 * v162
        local v170 = v156 * v162
        local v171 = v157 * v162
        local v172 = v164 + v168
        local v173

        if v172 == 0 then
            buffer.writef32(v152, 0, v172)
            v173 = buffer.readu32(v152, 0)
        elseif v172 > -1.1754943508222875E-38 and v172 < 1.1754943508222875E-38 then
            v173 = to_bits(v172)
        else
            buffer.writef32(v152, 0, v172)
            v173 = buffer.readu32(v152, 0)
        end

        v172 = v165 + v169

        local v174

        if v172 ~= 0 and v172 > -1.1754943508222875E-38 and v172 < 1.1754943508222875E-38 then
            v174 = to_bits(v172)
        else
            buffer.writef32(v152, 0, v172)
            v174 = buffer.readu32(v152, 0)
        end

        v172 = v166 + v170

        local v175

        if v172 ~= 0 and v172 > -1.1754943508222875E-38 and v172 < 1.1754943508222875E-38 then
            v175 = to_bits(v172)
        else
            buffer.writef32(v152, 0, v172)
            v175 = buffer.readu32(v152, 0)
        end

        v172 = v167 + v171

        local v176

        if v172 ~= 0 and v172 > -1.1754943508222875E-38 and v172 < 1.1754943508222875E-38 then
            v176 = to_bits(v172)
        else
            buffer.writef32(v152, 0, v172)
            v176 = buffer.readu32(v152, 0)
        end

        local v177 = v164 - v168

        if v177 ~= 0 and v177 > -1.1754943508222875E-38 and v177 < 1.1754943508222875E-38 then
            v172 = to_bits(v177)
        else
            buffer.writef32(v152, 0, v177)
            v172 = buffer.readu32(v152, 0)
        end

        v177 = v165 - v169

        local v178

        if v177 ~= 0 and v177 > -1.1754943508222875E-38 and v177 < 1.1754943508222875E-38 then
            v178 = to_bits(v177)
        else
            buffer.writef32(v152, 0, v177)
            v178 = buffer.readu32(v152, 0)
        end

        v177 = v166 - v170

        local v179

        if v177 ~= 0 and v177 > -1.1754943508222875E-38 and v177 < 1.1754943508222875E-38 then
            v179 = to_bits(v177)
        else
            buffer.writef32(v152, 0, v177)
            v179 = buffer.readu32(v152, 0)
        end

        v177 = v167 - v171

        local v180

        if v177 ~= 0 and v177 > -1.1754943508222875E-38 and v177 < 1.1754943508222875E-38 then
            v180 = to_bits(v177)
        else
            buffer.writef32(v152, 0, v177)
            v180 = buffer.readu32(v152, 0)
        end

        p19[1] = v173
        p19[2] = v174
        p19[3] = v175
        p19[4] = v176
        buffer.writeu32(v152, 0, v172)
        v177 = buffer.readf32(v152, 0)
        buffer.writeu32(v152, 0, v173)
        v171 = v177 - buffer.readf32(v152, 0)
        buffer.writeu32(v152, 0, v178)
        v177 = buffer.readf32(v152, 0)
        buffer.writeu32(v152, 0, v174)
        v172 = v177 - buffer.readf32(v152, 0)
        buffer.writeu32(v152, 0, v179)
        v177 = buffer.readf32(v152, 0)
        buffer.writeu32(v152, 0, v175)
        v173 = v177 - buffer.readf32(v152, 0)
        buffer.writeu32(v152, 0, v180)
        v177 = buffer.readf32(v152, 0)
        buffer.writeu32(v152, 0, v176)
        v179 = v177 - buffer.readf32(v152, 0)
        v177 = v171 * v171 + v172 * v172 + v173 * v173

        local v181, v182

        if v177 ~= 0 and v177 > -1.1754943508222875E-38 and v177 < 1.1754943508222875E-38 then
            v175 = math.abs(v177) * 7.1362384635298E+44
            v181 = math.floor(v175)
            v174 = v175 - v181
            v182 = if v174 > 0.5 or v174 == 0.5 and v181 % 2 == 1 then v181 + 1 else v181
            v176 = v182 * 1.401298464324817E-45

            if v177 < 0 then
                v176 = -v176
            end
        else
            buffer.writef32(v1, 0, v177)
            v176 = buffer.readf32(v1, 0)
        end

        v177 = estimate(v176)

        local v183 = v177 * 0.5 * (-v176 * (v177 * v177) + 1) + v177

        buffer.writeu32(v152, 0, 872415232)
        v177 = buffer.readf32(v152, 0)

        local v184 = if not (v177 < v176) then 0 elseif v176 == 0 then 0 else v176 * v183

        if v184 ~= 0 and v184 > -1.1754943508222875E-38 and v184 < 1.1754943508222875E-38 then
            v183 = to_bits(v184)
        else
            buffer.writef32(v152, 0, v184)
            v183 = buffer.readu32(v152, 0)
        end

        p19[13] = v183
        p19[14] = v183
        p19[15] = v183
        p19[16] = v183
        v182 = v13.reciprocal_estimate(v184)
        v183 = v182 * (-v182 * v184 + 1) + v182

        if v177 < v176 then
            local v185 = v171 * v183
            local v186

            if v185 == 0 then
                buffer.writef32(v152, 0, v185)
                v186 = buffer.readu32(v152, 0)
            elseif v185 > -1.1754943508222875E-38 and v185 < 1.1754943508222875E-38 then
                v186 = to_bits(v185)
            else
                buffer.writef32(v152, 0, v185)
                v186 = buffer.readu32(v152, 0)
            end

            v181 = v172 * v183

            if v181 ~= 0 and v181 > -1.1754943508222875E-38 and v181 < 1.1754943508222875E-38 then
                v185 = to_bits(v181)
            else
                buffer.writef32(v152, 0, v181)
                v185 = buffer.readu32(v152, 0)
            end

            local v187 = v173 * v183

            if v187 ~= 0 and v187 > -1.1754943508222875E-38 and v187 < 1.1754943508222875E-38 then
                v181 = to_bits(v187)
            else
                buffer.writef32(v152, 0, v187)
                v181 = buffer.readu32(v152, 0)
            end

            local v188 = v179 * v183

            if v188 ~= 0 and v188 > -1.1754943508222875E-38 and v188 < 1.1754943508222875E-38 then
                v187 = to_bits(v188)
            else
                buffer.writef32(v152, 0, v188)
                v187 = buffer.readu32(v152, 0)
            end

            p19[5] = v186
            p19[6] = v185
            p19[7] = v181
            p19[8] = v187
        else
            buffer.writef32(v152, 0, 0)
            v177 = buffer.readu32(v152, 0)
            p19[5] = v177
            p19[6] = v177
            p19[7] = v177
            p19[8] = v177
        end

        p18[5] = p19[1]
        p18[6] = p19[2]
        p18[7] = p19[3]
        p18[8] = p19[4]
        p18[9] = p19[5]
        p18[10] = p19[6]
        p18[11] = p19[7]
        p18[12] = p19[8]
        p18[13] = p19[9]
        p18[14] = p19[10]
        p18[15] = p19[11]
        p18[16] = p19[12]
        p18[17] = p19[13]
        p18[18] = p19[14]
        p18[19] = p19[15]
        p18[20] = p19[16]
        p18[141] = 1
    else
        local v189, v190, v191

        if v153 > 0 then
            v189 = v154 * v162 + v164

            local v192

            if v189 == 0 then
                buffer.writef32(v152, 0, v189)
                v192 = buffer.readu32(v152, 0)
            elseif v189 > -1.1754943508222875E-38 and v189 < 1.1754943508222875E-38 then
                v192 = to_bits(v189)
            else
                buffer.writef32(v152, 0, v189)
                v192 = buffer.readu32(v152, 0)
            end

            v190 = v155 * v162 + v165

            if v190 ~= 0 and v190 > -1.1754943508222875E-38 and v190 < 1.1754943508222875E-38 then
                v189 = to_bits(v190)
            else
                buffer.writef32(v152, 0, v190)
                v189 = buffer.readu32(v152, 0)
            end

            v191 = v156 * v162 + v166

            if v191 ~= 0 and v191 > -1.1754943508222875E-38 and v191 < 1.1754943508222875E-38 then
                v190 = to_bits(v191)
            else
                buffer.writef32(v152, 0, v191)
                v190 = buffer.readu32(v152, 0)
            end

            local v193 = v157 * v162 + v167

            if v193 ~= 0 and v193 > -1.1754943508222875E-38 and v193 < 1.1754943508222875E-38 then
                v191 = to_bits(v193)
            else
                buffer.writef32(v152, 0, v193)
                v191 = buffer.readu32(v152, 0)
            end

            p18[137] = v192
        else
            v189 = v164 - v154 * v162

            local v194

            if v189 ~= 0 and v189 > -1.1754943508222875E-38 and v189 < 1.1754943508222875E-38 then
                v194 = to_bits(v189)
            else
                buffer.writef32(v152, 0, v189)
                v194 = buffer.readu32(v152, 0)
            end

            v190 = v165 - v155 * v162

            if v190 ~= 0 and v190 > -1.1754943508222875E-38 and v190 < 1.1754943508222875E-38 then
                v189 = to_bits(v190)
            else
                buffer.writef32(v152, 0, v190)
                v189 = buffer.readu32(v152, 0)
            end

            v191 = v166 - v156 * v162

            if v191 ~= 0 and v191 > -1.1754943508222875E-38 and v191 < 1.1754943508222875E-38 then
                v190 = to_bits(v191)
            else
                buffer.writef32(v152, 0, v191)
                v190 = buffer.readu32(v152, 0)
            end

            local v195 = v167 - v157 * v162

            if v195 ~= 0 and v195 > -1.1754943508222875E-38 and v195 < 1.1754943508222875E-38 then
                v191 = to_bits(v195)
            else
                buffer.writef32(v152, 0, v195)
                v191 = buffer.readu32(v152, 0)
            end

            p18[137] = v194
        end

        p18[138] = v189
        p18[139] = v190
        p18[140] = v191
        p18[141] = 0
    end

    p18[1] = 0
end

return t1
