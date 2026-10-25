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

import("skate_core/physics/world_contact/arithmetic")

local v9 = import("skate_core/physics/world_contact/feature")
local estimate = v8.estimate
local initialize_feature_segment = v9.initialize_feature_segment
local t2 = {
    { 1, 2 },
    { 0, 2 },
    { 0, 1 }
}
local t3 = {
    { 1, 1 },
    { 1, -1 },
    { -1, -1 },
    { -1, 1 }
}
local t1 = {}

t1.OTHER = t2
t1.SIGNS = t3

local function to_bits4(p4) -- line: 48
    -- upvalues: v1 (copy)
    local v10 = p4[1]
    local v11

    if v10 ~= 0 and v10 > -1.1754943508222875E-38 and v10 < 1.1754943508222875E-38 then
        local v12 = math.abs(v10) * 7.1362384635298E+44
        local v13 = math.floor(v12)
        local v14 = v12 - v13

        v11 = if v14 > 0.5 or v14 == 0.5 and v13 % 2 == 1 then v13 + 1 else v13

        if v10 < 0 then
            v11 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v10)
        v11 = buffer.readu32(v1, 0)
    end

    local v15 = p4[2]
    local v16

    if v15 ~= 0 and v15 > -1.1754943508222875E-38 and v15 < 1.1754943508222875E-38 then
        local v17 = math.abs(v15) * 7.1362384635298E+44
        local v18 = math.floor(v17)
        local v19 = v17 - v18

        v16 = if v19 > 0.5 or v19 == 0.5 and v18 % 2 == 1 then v18 + 1 else v18

        if v15 < 0 then
            v16 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v15)
        v16 = buffer.readu32(v1, 0)
    end

    local v20 = p4[3]
    local v21

    if v20 ~= 0 and v20 > -1.1754943508222875E-38 and v20 < 1.1754943508222875E-38 then
        local v22 = math.abs(v20) * 7.1362384635298E+44
        local v23 = math.floor(v22)
        local v24 = v22 - v23

        v21 = if v24 > 0.5 or v24 == 0.5 and v23 % 2 == 1 then v23 + 1 else v23

        if v20 < 0 then
            v21 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v20)
        v21 = buffer.readu32(v1, 0)
    end

    local v25 = p4[4]
    local v26

    if v25 ~= 0 and v25 > -1.1754943508222875E-38 and v25 < 1.1754943508222875E-38 then
        local v27 = math.abs(v25) * 7.1362384635298E+44
        local v28 = math.floor(v27)
        local v29 = v27 - v28

        v26 = if v29 > 0.5 or v29 == 0.5 and v28 % 2 == 1 then v28 + 1 else v28

        if v25 < 0 then
            v26 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v25)
        v26 = buffer.readu32(v1, 0)
    end

    return {
        v11,
        v16,
        v21,
        v26
    }
end

local face, plane, load, store, dot, scale, sub, add, madd, neg, cross
local v30 = false

local function box_maximum_feature_reference(p5, p6, p7, p8, p9) -- line: 60
    -- upvalues: rt (copy), v1 (copy), initialize_feature_segment (copy), t2 (copy), t3 (copy), to_bits4 (copy), face (ref), load (ref), store (ref), dot (ref), scale (ref), sub (ref), madd (ref)
    local v31 = load(p5, 0)
    local t5 = {
        load(p5, 4),
        load(p5, 8),
        load(p5, 12)
    }

    buffer.writeu32(v1, 0, p5[29])

    local v33 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p5[30])

    local v35 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p5[31])

    local t6 = {
        v33,
        v35,
        (buffer.readf32(v1, 0))
    }

    buffer.writeu32(v1, 0, p7[1])

    local v38 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p7[2])

    local v40 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p7[3])

    local v42 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p7[4])

    local t7 = {
        v38,
        v40,
        v42,
        (buffer.readf32(v1, 0))
    }
    local n1 = 0
    local n2 = 0
    local n3 = 0

    for i = 0, 2 do
        if math.abs((dot(t7, t5[i + 1]))) < 0.20000000298023224 then
            n2 = i
            n1 += 1
        else
            n3 = i
        end
    end

    if n1 == 2 then
        face(v31, t5, t6, n3, p6, t7, p8)
    elseif n1 == 1 then
        local v45 = t2[n2 + 1][1]
        local v46 = t2[n2 + 1][2]
        local v47 = { 0, 0, 0, 0 }
        local n4 = 0

        for i = 0, 3 do
            local v48 = t3[i + 1]
            local v49 = madd(t5[v46 + 1], t6[v46 + 1] * v48[2], madd(t5[v45 + 1], t6[v45 + 1] * v48[1], v31))
            local v50 = dot(v49, t7)

            if i == 0 or n4 < v50 then
                n4 = v50
                v47 = v49
            end
        end

        local v51 = sub(v47, scale(t5[n2 + 1], t6[n2 + 1]))
        local v52 = madd(t5[n2 + 1], t6[n2 + 1], v47)
        local v53 = table.create(16, 0)

        v53[9] = p9[1]
        v53[10] = p9[2]
        v53[11] = p9[3]
        v53[12] = p9[4]
        initialize_feature_segment(v53, to_bits4(v51), (to_bits4(v52)))
        p8[5] = v53[1]
        p8[6] = v53[2]
        p8[7] = v53[3]
        p8[8] = v53[4]
        p8[9] = v53[5]
        p8[10] = v53[6]
        p8[11] = v53[7]
        p8[12] = v53[8]
        p8[13] = v53[9]
        p8[14] = v53[10]
        p8[15] = v53[11]
        p8[16] = v53[12]
        p8[17] = v53[13]
        p8[18] = v53[14]
        p8[19] = v53[15]
        p8[20] = v53[16]
        p8[141] = 1
    else
        local v54 = { 0, 0, 0, 0 }
        local n5 = 0

        for i = 0, 7 do
            local v55 = if i > 3 then 1 else -1
            local v56 = t3[rt.irem(i, 4) + 1]
            local v57 = madd(t5[3], t6[3] * v56[2], madd(t5[2], t6[2] * v56[1], madd(t5[1], t6[1] * v55, v31)))
            local v58 = dot(v57, t7)

            if i == 0 or n5 < v58 then
                n5 = v58
                v54 = v57
            end
        end

        store(p8, 136, v54)
        p8[141] = 0
    end

    p8[1] = 0
end

function face(p10, p11, p12, p13, p14, p15, p16) -- line: 132
    -- upvalues: rt (copy), v1 (copy), t2 (copy), plane (ref), store (ref), dot (ref), scale (ref), add (ref), madd (ref), neg (ref)
    local v59 = if dot(p11[p13 + 1], p15) > 0 then 1 else -1
    local v60 = madd(p11[p13 + 1], p12[p13 + 1] * v59, p10)

    if p13 == 1 then
        v59 = -v59
    end

    local v61 = t2[p13 + 1][1]
    local v62 = t2[p13 + 1][2]
    local v63 = scale(p11[v61 + 1], p12[v61 + 1])
    local v64 = scale(p11[v61 + 1], -p12[v61 + 1])
    local v65 = scale(p11[v62 + 1], p12[v62 + 1])
    local v66 = scale(p11[v62 + 1], -p12[v62 + 1])
    local v67 = plane(p11[v62 + 1], p15, p14)
    local v68 = plane(p11[v61 + 1], p15, p14)
    local v69 = p12[v61 + 1] * 2
    local v70 = p12[v62 + 1] * 2
    local t8 = {
        add(add(v60, v63), v65),
        add(add(v60, v63), v66),
        add(add(v60, v64), v66),
        add(add(v60, v64), v65)
    }
    local v71 = neg(p11[v61 + 1])
    local v72 = neg(p11[v62 + 1])
    local v73 = if v59 < 0 then 1 else 0
    local t9, t10, t11, t12

    if v73 == p14 then
        t9 = { 0, 1, 2, 3 }
        t10 = {
            v72,
            v71,
            rt.copy(p11[v62 + 1]),
            rt.copy(p11[v61 + 1])
        }
        t11 = {
            neg(v67),
            neg(v68),
            rt.copy(v67),
            rt.copy(v68)
        }
        t12 = { v70, v69, v70, v69 }
    else
        t9 = { 0, 3, 2, 1 }
        t10 = {
            v71,
            v72,
            rt.copy(p11[v61 + 1]),
            rt.copy(p11[v62 + 1])
        }
        t11 = {
            neg(v68),
            neg(v67),
            rt.copy(v68),
            rt.copy(v67)
        }
        t12 = { v69, v70, v69, v70 }
    end

    for i = 0, 3 do
        local v74 = i * 16 + 4

        store(p16, v74, t8[t9[i + 1] + 1])
        store(p16, v74 + 4, t10[i + 1])
        store(p16, v74 + 8, t11[i + 1])

        local v75 = t12[i + 1]
        local v76

        if v75 ~= 0 and v75 > -1.1754943508222875E-38 and v75 < 1.1754943508222875E-38 then
            local v77 = math.abs(v75) * 7.1362384635298E+44
            local v78 = math.floor(v77)
            local v79 = v77 - v78
            local v80 = if v79 > 0.5 or v79 == 0.5 and v78 % 2 == 1 then v78 + 1 else v78

            v76 = if v75 < 0 then v80 + 2147483648 else v80
        else
            buffer.writef32(v1, 0, v75)
            v76 = buffer.readu32(v1, 0)
        end

        for j = v74 + 12, v74 + 15 do
            p16[j + 1] = v76
        end
    end

    store(p16, 132, scale(p11[p13 + 1], -v59))
    p16[141] = 4
end

function plane(p17, p18, p19) -- line: 179
    -- upvalues: estimate (copy), dot (ref), scale (ref), cross (ref)
    local v81 = if p19 == 0 then cross(p18, p17) else cross(p17, p18)
    local v82 = dot(v81, v81)

    if v82 > 1.1920928955078125E-07 then
        local v83 = estimate(v82)
        local v84 = v83 * 0.5 * (-v82 * (v83 * v83) + 1) + v83
        local v85 = v84 * 0.5 * (-v82 * (v84 * v84) + 1) + v84

        v81 = scale(v81, v85)
    end

    return v81
end

function load(p20, p21) -- line: 191
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p20[p21 + 1])

    local v87 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p20[p21 + 2])

    local v89 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p20[p21 + 3])

    local v91 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p20[p21 + 4])

    return {
        v87,
        v89,
        v91,
        (buffer.readf32(v1, 0))
    }
end

function store(p22, p23, p24) -- line: 199
    -- upvalues: v1 (copy)
    local v93 = p23 + 1
    local v94 = p24[1]
    local v95

    if v94 ~= 0 and v94 > -1.1754943508222875E-38 and v94 < 1.1754943508222875E-38 then
        local v96 = math.abs(v94) * 7.1362384635298E+44
        local v97 = math.floor(v96)
        local v98 = v96 - v97

        v95 = if v98 > 0.5 or v98 == 0.5 and v97 % 2 == 1 then v97 + 1 else v97

        if v94 < 0 then
            v95 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v94)
        v95 = buffer.readu32(v1, 0)
    end

    p22[v93] = v95

    local v99 = p23 + 2
    local v100 = p24[2]
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

    p22[v99] = v101

    local v105 = p23 + 3
    local v106 = p24[3]
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

    p22[v105] = v107

    local v111 = p23 + 4
    local v112 = p24[4]
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

    p22[v111] = v113
end

function dot(p25, p26) -- line: 205
    return p25[1] * p26[1] + p25[2] * p26[2] + p25[3] * p26[3]
end

function scale(p27, p28) -- line: 208
    return {
        p27[1] * p28,
        p27[2] * p28,
        p27[3] * p28,
        p27[4] * p28
    }
end

function sub(p29, p30) -- line: 211
    return {
        p29[1] - p30[1],
        p29[2] - p30[2],
        p29[3] - p30[3],
        p29[4] - p30[4]
    }
end

function add(p31, p32) -- line: 214
    return {
        p31[1] + p32[1],
        p31[2] + p32[2],
        p31[3] + p32[3],
        p31[4] + p32[4]
    }
end

function madd(p33, p34, p35) -- line: 217
    return {
        p33[1] * p34 + p35[1],
        p33[2] * p34 + p35[2],
        p33[3] * p34 + p35[3],
        p33[4] * p34 + p35[4]
    }
end

function neg(p36) -- line: 220
    return {
        -p36[1],
        -p36[2],
        -p36[3],
        -p36[4]
    }
end

function cross(p37, p38) -- line: 223
    return {
        -p37[3] * p38[2] + p37[2] * p38[3],
        -p37[1] * p38[3] + p37[3] * p38[1],
        -p37[2] * p38[1] + p37[1] * p38[2],
        -p37[4] * p38[4] + p37[4] * p38[4]
    }
end

t1.box_maximum_feature_reference = box_maximum_feature_reference

function t1.set_reference(p39) -- line: 234
    -- upvalues: v30 (ref)
    local v117 = v30

    v30 = p39

    return v117
end

local v118 = buffer.create(8)

local function fb(p40) -- line: 257
    -- upvalues: v118 (copy)
    buffer.writeu32(v118, 0, p40)

    return (buffer.readf32(v118, 0))
end

local to_bits = rt.to_bits

local function tb(p41) -- line: 262
    -- upvalues: v118 (copy), to_bits (copy)
    if p41 ~= 0 and p41 > -1.1754943508222875E-38 and p41 < 1.1754943508222875E-38 then
        return to_bits(p41)
    end

    buffer.writef32(v118, 0, p41)

    return (buffer.readu32(v118, 0))
end

buffer.writeu32(v118, 0, 1045220557)

local v119 = buffer.readf32(v118, 0)

buffer.writeu32(v118, 0, 872415232)

local v120 = buffer.readf32(v118, 0)
local v121 = table.create(12, 0)
local v122 = table.create(8, 0)

local function plane_into(p42, p43, p44, p45, p46, p47, p48, p49, p50, p51) -- line: 274
    -- upvalues: estimate (copy), v120 (copy), v122 (copy)
    local v123, v124, v125, v126

    if p51 == 0 then
        v123 = -p49 * p44 + p48 * p45
        v124 = -p47 * p45 + p49 * p43
        v125 = -p48 * p43 + p47 * p44
        v126 = -p50 * p46 + p50 * p46
    else
        v123 = -p45 * p48 + p44 * p49
        v124 = -p43 * p49 + p45 * p47
        v125 = -p44 * p47 + p43 * p48
        v126 = -p46 * p50 + p46 * p50
    end

    local v127 = v123 * v123 + v124 * v124 + v125 * v125

    if v120 < v127 then
        local v128 = estimate(v127)
        local v129 = v128 * 0.5 * (-v127 * (v128 * v128) + 1) + v128
        local v130 = v129 * 0.5 * (-v127 * (v129 * v129) + 1) + v129

        v123 *= v130
        v124 *= v130
        v125 *= v130
        v126 *= v130
    end

    local v131 = p42 + 1
    local v132 = p42 + 2
    local v133 = p42 + 3
    local v134 = p42 + 4

    v122[v131] = v123
    v122[v132] = v124
    v122[v133] = v125
    v122[v134] = v126
end

function t1.box_maximum_feature(p52, p53, p54, p55, p56) -- line: 296
    -- upvalues: v30 (ref), box_maximum_feature_reference (copy), v118 (copy), to_bits (copy), v119 (copy), v121 (copy), v122 (copy), plane_into (copy)
    if v30 then
        return box_maximum_feature_reference(p52, p53, p54, p55, p56)
    end

    buffer.writeu32(v118, 0, p54[1])

    local v136 = buffer.readf32(v118, 0)

    buffer.writeu32(v118, 0, p54[2])

    local v137 = buffer.readf32(v118, 0)

    buffer.writeu32(v118, 0, p54[3])

    local v138 = buffer.readf32(v118, 0)

    buffer.writeu32(v118, 0, p54[4])

    local v139 = buffer.readf32(v118, 0)
    local n6 = 0
    local n7 = 0
    local v140, v141, v142, v143, v144, v145

    for i = 0, 2 do
        local v146 = i * 4

        v141 = p52[v146 + 5]
        buffer.writeu32(v118, 0, v141)
        v140 = buffer.readf32(v118, 0)
        v141 = p52[v146 + 6]
        buffer.writeu32(v118, 0, v141)

        local v147 = buffer.readf32(v118, 0)

        v141 = p52[v146 + 7]
        buffer.writeu32(v118, 0, v141)

        local v148 = buffer.readf32(v118, 0)

        v141 = v146 + 1

        local v149 = v146 + 2

        v142 = v146 + 3
        v143 = v146 + 4
        v144 = p52[v146 + 8]
        buffer.writeu32(v118, 0, v144)
        v145 = buffer.readf32(v118, 0)
        v121[v141] = v140
        v121[v149] = v147
        v121[v142] = v148
        v121[v143] = v145
        v140 = v136 * v140 + v137 * v147 + v138 * v148

        if math.abs(v140) < v119 then
            n6 += 1
        else
            n7 = i
        end
    end

    if n6 ~= 2 then
        return box_maximum_feature_reference(p52, p53, p54, p55, p56)
    end

    buffer.writeu32(v118, 0, p52[1])

    local v151 = buffer.readf32(v118, 0)

    buffer.writeu32(v118, 0, p52[2])

    local v152 = buffer.readf32(v118, 0)

    buffer.writeu32(v118, 0, p52[3])

    local v153 = buffer.readf32(v118, 0)

    buffer.writeu32(v118, 0, p52[4])

    local v154 = buffer.readf32(v118, 0)
    local v155 = n7 * 4
    local v150 = v121[v155 + 1]
    local v156 = v121[v155 + 2]
    local v157 = v121[v155 + 3]

    v141 = v121[v155 + 4]
    v155 = if v150 * v136 + v156 * v137 + v157 * v138 > 0 then 1 else -1
    buffer.writeu32(v118, 0, p52[n7 + 29])
    v140 = buffer.readf32(v118, 0) * v155
    v142 = v150 * v140 + v151
    v143 = v156 * v140 + v152

    local v158 = v157 * v140 + v153

    v144 = v141 * v140 + v154

    if n7 == 1 then
        v155 = -v155
    end

    local v159

    if n7 == 0 then
        v145 = 1
        v159 = 2
    else
        v159 = if n7 == 1 then 2 else 1
        v145 = 0
    end

    local v160 = 4 * v145
    local v161 = 4 * v159
    local v162 = v121[v160 + 1]
    local v163 = v121[v160 + 2]
    local v164 = v121[v160 + 3]
    local v165 = v121[v160 + 4]
    local v166 = v121[v161 + 1]
    local v167 = v121[v161 + 2]
    local v168 = v121[v161 + 3]
    local v169 = v121[v161 + 4]

    buffer.writeu32(v118, 0, p52[29 + v145])

    local v171 = buffer.readf32(v118, 0)

    buffer.writeu32(v118, 0, p52[29 + v159])

    local v172 = buffer.readf32(v118, 0)
    local v170 = -v171
    local v173 = -v172
    local v174 = v142 + v162 * v171
    local v175 = v143 + v163 * v171
    local v176 = v158 + v164 * v171
    local v177 = v144 + v165 * v171
    local v178 = v142 + v162 * v170
    local v179 = v143 + v163 * v170
    local v180 = v158 + v164 * v170
    local v181 = v144 + v165 * v170
    local v182 = v166 * v172
    local v183 = v167 * v172
    local v184 = v168 * v172
    local v185 = v169 * v172
    local v186 = v166 * v173
    local v187 = v167 * v173
    local v188 = v168 * v173
    local v189 = v169 * v173

    plane_into(0, v166, v167, v168, v169, v136, v137, v138, v139, p53)
    plane_into(4, v162, v163, v164, v165, v136, v137, v138, v139, p53)

    local v190 = v122[1]
    local v191 = v122[2]
    local v192 = v122[3]
    local v193 = v122[4]
    local v194 = v122[5]
    local v195 = v122[6]
    local v196 = v122[7]
    local v197 = v122[8]
    local v198 = v171 * 2

    if v198 ~= 0 and v198 > -1.1754943508222875E-38 and v198 < 1.1754943508222875E-38 then
        v171 = to_bits(v198)
    else
        buffer.writef32(v118, 0, v198)
        v171 = buffer.readu32(v118, 0)
    end

    v198 = v172 * 2

    if v198 ~= 0 and v198 > -1.1754943508222875E-38 and v198 < 1.1754943508222875E-38 then
        v170 = to_bits(v198)
    else
        buffer.writef32(v118, 0, v198)
        v170 = buffer.readu32(v118, 0)
    end

    v198 = if v155 < 0 then 1 else 0

    local v199, v200, v201, v202

    if v198 == p53 then
        v202 = v174 + v182

        if v202 == 0 then
            buffer.writef32(v118, 0, v202)
            v199 = buffer.readu32(v118, 0)
        elseif v202 > -1.1754943508222875E-38 and v202 < 1.1754943508222875E-38 then
            v199 = to_bits(v202)
        else
            buffer.writef32(v118, 0, v202)
            v199 = buffer.readu32(v118, 0)
        end

        local v203 = v175 + v183

        if v203 ~= 0 and v203 > -1.1754943508222875E-38 and v203 < 1.1754943508222875E-38 then
            v202 = to_bits(v203)
        else
            buffer.writef32(v118, 0, v203)
            v202 = buffer.readu32(v118, 0)
        end

        v200 = v176 + v184

        if v200 ~= 0 and v200 > -1.1754943508222875E-38 and v200 < 1.1754943508222875E-38 then
            v203 = to_bits(v200)
        else
            buffer.writef32(v118, 0, v200)
            v203 = buffer.readu32(v118, 0)
        end

        v201 = v177 + v185

        if v201 ~= 0 and v201 > -1.1754943508222875E-38 and v201 < 1.1754943508222875E-38 then
            v200 = to_bits(v201)
        else
            buffer.writef32(v118, 0, v201)
            v200 = buffer.readu32(v118, 0)
        end

        p55[5] = v199
        p55[6] = v202
        p55[7] = v203
        p55[8] = v200
        v202 = -v166

        if v202 ~= 0 and v202 > -1.1754943508222875E-38 and v202 < 1.1754943508222875E-38 then
            v198 = to_bits(v202)
        else
            buffer.writef32(v118, 0, v202)
            v198 = buffer.readu32(v118, 0)
        end

        v199 = -v167

        if v199 ~= 0 and v199 > -1.1754943508222875E-38 and v199 < 1.1754943508222875E-38 then
            v202 = to_bits(v199)
        else
            buffer.writef32(v118, 0, v199)
            v202 = buffer.readu32(v118, 0)
        end

        v200 = -v168

        if v200 ~= 0 and v200 > -1.1754943508222875E-38 and v200 < 1.1754943508222875E-38 then
            v199 = to_bits(v200)
        else
            buffer.writef32(v118, 0, v200)
            v199 = buffer.readu32(v118, 0)
        end

        v201 = -v169

        if v201 ~= 0 and v201 > -1.1754943508222875E-38 and v201 < 1.1754943508222875E-38 then
            v200 = to_bits(v201)
        else
            buffer.writef32(v118, 0, v201)
            v200 = buffer.readu32(v118, 0)
        end

        p55[9] = v198
        p55[10] = v202
        p55[11] = v199
        p55[12] = v200
        v202 = -v190

        if v202 ~= 0 and v202 > -1.1754943508222875E-38 and v202 < 1.1754943508222875E-38 then
            v198 = to_bits(v202)
        else
            buffer.writef32(v118, 0, v202)
            v198 = buffer.readu32(v118, 0)
        end

        v199 = -v191

        if v199 ~= 0 and v199 > -1.1754943508222875E-38 and v199 < 1.1754943508222875E-38 then
            v202 = to_bits(v199)
        else
            buffer.writef32(v118, 0, v199)
            v202 = buffer.readu32(v118, 0)
        end

        v200 = -v192

        if v200 ~= 0 and v200 > -1.1754943508222875E-38 and v200 < 1.1754943508222875E-38 then
            v199 = to_bits(v200)
        else
            buffer.writef32(v118, 0, v200)
            v199 = buffer.readu32(v118, 0)
        end

        v201 = -v193

        if v201 ~= 0 and v201 > -1.1754943508222875E-38 and v201 < 1.1754943508222875E-38 then
            v200 = to_bits(v201)
        else
            buffer.writef32(v118, 0, v201)
            v200 = buffer.readu32(v118, 0)
        end

        p55[13] = v198
        p55[14] = v202
        p55[15] = v199
        p55[16] = v200
        p55[17] = v170
        p55[18] = v170
        p55[19] = v170
        p55[20] = v170
        v202 = v174 + v186

        if v202 ~= 0 and v202 > -1.1754943508222875E-38 and v202 < 1.1754943508222875E-38 then
            v198 = to_bits(v202)
        else
            buffer.writef32(v118, 0, v202)
            v198 = buffer.readu32(v118, 0)
        end

        v199 = v175 + v187

        if v199 ~= 0 and v199 > -1.1754943508222875E-38 and v199 < 1.1754943508222875E-38 then
            v202 = to_bits(v199)
        else
            buffer.writef32(v118, 0, v199)
            v202 = buffer.readu32(v118, 0)
        end

        v200 = v176 + v188

        if v200 ~= 0 and v200 > -1.1754943508222875E-38 and v200 < 1.1754943508222875E-38 then
            v199 = to_bits(v200)
        else
            buffer.writef32(v118, 0, v200)
            v199 = buffer.readu32(v118, 0)
        end

        v201 = v177 + v189

        if v201 ~= 0 and v201 > -1.1754943508222875E-38 and v201 < 1.1754943508222875E-38 then
            v200 = to_bits(v201)
        else
            buffer.writef32(v118, 0, v201)
            v200 = buffer.readu32(v118, 0)
        end

        p55[21] = v198
        p55[22] = v202
        p55[23] = v199
        p55[24] = v200
        v202 = -v162

        if v202 ~= 0 and v202 > -1.1754943508222875E-38 and v202 < 1.1754943508222875E-38 then
            v198 = to_bits(v202)
        else
            buffer.writef32(v118, 0, v202)
            v198 = buffer.readu32(v118, 0)
        end

        v199 = -v163

        if v199 ~= 0 and v199 > -1.1754943508222875E-38 and v199 < 1.1754943508222875E-38 then
            v202 = to_bits(v199)
        else
            buffer.writef32(v118, 0, v199)
            v202 = buffer.readu32(v118, 0)
        end

        v200 = -v164

        if v200 ~= 0 and v200 > -1.1754943508222875E-38 and v200 < 1.1754943508222875E-38 then
            v199 = to_bits(v200)
        else
            buffer.writef32(v118, 0, v200)
            v199 = buffer.readu32(v118, 0)
        end

        v201 = -v165

        if v201 ~= 0 and v201 > -1.1754943508222875E-38 and v201 < 1.1754943508222875E-38 then
            v200 = to_bits(v201)
        else
            buffer.writef32(v118, 0, v201)
            v200 = buffer.readu32(v118, 0)
        end

        p55[25] = v198
        p55[26] = v202
        p55[27] = v199
        p55[28] = v200
        v202 = -v194

        if v202 ~= 0 and v202 > -1.1754943508222875E-38 and v202 < 1.1754943508222875E-38 then
            v198 = to_bits(v202)
        else
            buffer.writef32(v118, 0, v202)
            v198 = buffer.readu32(v118, 0)
        end

        v199 = -v195

        if v199 ~= 0 and v199 > -1.1754943508222875E-38 and v199 < 1.1754943508222875E-38 then
            v202 = to_bits(v199)
        else
            buffer.writef32(v118, 0, v199)
            v202 = buffer.readu32(v118, 0)
        end

        v200 = -v196

        if v200 ~= 0 and v200 > -1.1754943508222875E-38 and v200 < 1.1754943508222875E-38 then
            v199 = to_bits(v200)
        else
            buffer.writef32(v118, 0, v200)
            v199 = buffer.readu32(v118, 0)
        end

        v201 = -v197

        if v201 ~= 0 and v201 > -1.1754943508222875E-38 and v201 < 1.1754943508222875E-38 then
            v200 = to_bits(v201)
        else
            buffer.writef32(v118, 0, v201)
            v200 = buffer.readu32(v118, 0)
        end

        p55[29] = v198
        p55[30] = v202
        p55[31] = v199
        p55[32] = v200
        p55[33] = v171
        p55[34] = v171
        p55[35] = v171
        p55[36] = v171
        v202 = v178 + v186

        if v202 ~= 0 and v202 > -1.1754943508222875E-38 and v202 < 1.1754943508222875E-38 then
            v198 = to_bits(v202)
        else
            buffer.writef32(v118, 0, v202)
            v198 = buffer.readu32(v118, 0)
        end

        v199 = v179 + v187

        if v199 ~= 0 and v199 > -1.1754943508222875E-38 and v199 < 1.1754943508222875E-38 then
            v202 = to_bits(v199)
        else
            buffer.writef32(v118, 0, v199)
            v202 = buffer.readu32(v118, 0)
        end

        v200 = v180 + v188

        if v200 ~= 0 and v200 > -1.1754943508222875E-38 and v200 < 1.1754943508222875E-38 then
            v199 = to_bits(v200)
        else
            buffer.writef32(v118, 0, v200)
            v199 = buffer.readu32(v118, 0)
        end

        v201 = v181 + v189

        if v201 ~= 0 and v201 > -1.1754943508222875E-38 and v201 < 1.1754943508222875E-38 then
            v200 = to_bits(v201)
        else
            buffer.writef32(v118, 0, v201)
            v200 = buffer.readu32(v118, 0)
        end

        p55[37] = v198
        p55[38] = v202
        p55[39] = v199
        p55[40] = v200

        if v166 ~= 0 and v166 > -1.1754943508222875E-38 and v166 < 1.1754943508222875E-38 then
            v198 = to_bits(v166)
        else
            buffer.writef32(v118, 0, v166)
            v198 = buffer.readu32(v118, 0)
        end

        if v167 ~= 0 and v167 > -1.1754943508222875E-38 and v167 < 1.1754943508222875E-38 then
            v202 = to_bits(v167)
        else
            buffer.writef32(v118, 0, v167)
            v202 = buffer.readu32(v118, 0)
        end

        if v168 ~= 0 and v168 > -1.1754943508222875E-38 and v168 < 1.1754943508222875E-38 then
            v199 = to_bits(v168)
        else
            buffer.writef32(v118, 0, v168)
            v199 = buffer.readu32(v118, 0)
        end

        if v169 ~= 0 and v169 > -1.1754943508222875E-38 and v169 < 1.1754943508222875E-38 then
            v200 = to_bits(v169)
        else
            buffer.writef32(v118, 0, v169)
            v200 = buffer.readu32(v118, 0)
        end

        p55[41] = v198
        p55[42] = v202
        p55[43] = v199
        p55[44] = v200

        if v190 ~= 0 and v190 > -1.1754943508222875E-38 and v190 < 1.1754943508222875E-38 then
            v198 = to_bits(v190)
        else
            buffer.writef32(v118, 0, v190)
            v198 = buffer.readu32(v118, 0)
        end

        if v191 ~= 0 and v191 > -1.1754943508222875E-38 and v191 < 1.1754943508222875E-38 then
            v202 = to_bits(v191)
        else
            buffer.writef32(v118, 0, v191)
            v202 = buffer.readu32(v118, 0)
        end

        if v192 ~= 0 and v192 > -1.1754943508222875E-38 and v192 < 1.1754943508222875E-38 then
            v199 = to_bits(v192)
        else
            buffer.writef32(v118, 0, v192)
            v199 = buffer.readu32(v118, 0)
        end

        if v193 ~= 0 and v193 > -1.1754943508222875E-38 and v193 < 1.1754943508222875E-38 then
            v200 = to_bits(v193)
        else
            buffer.writef32(v118, 0, v193)
            v200 = buffer.readu32(v118, 0)
        end

        p55[45] = v198
        p55[46] = v202
        p55[47] = v199
        p55[48] = v200
        p55[49] = v170
        p55[50] = v170
        p55[51] = v170
        p55[52] = v170
        v202 = v178 + v182

        if v202 ~= 0 and v202 > -1.1754943508222875E-38 and v202 < 1.1754943508222875E-38 then
            v198 = to_bits(v202)
        else
            buffer.writef32(v118, 0, v202)
            v198 = buffer.readu32(v118, 0)
        end

        v199 = v179 + v183

        if v199 ~= 0 and v199 > -1.1754943508222875E-38 and v199 < 1.1754943508222875E-38 then
            v202 = to_bits(v199)
        else
            buffer.writef32(v118, 0, v199)
            v202 = buffer.readu32(v118, 0)
        end

        v200 = v180 + v184

        if v200 ~= 0 and v200 > -1.1754943508222875E-38 and v200 < 1.1754943508222875E-38 then
            v199 = to_bits(v200)
        else
            buffer.writef32(v118, 0, v200)
            v199 = buffer.readu32(v118, 0)
        end

        v201 = v181 + v185

        if v201 ~= 0 and v201 > -1.1754943508222875E-38 and v201 < 1.1754943508222875E-38 then
            v200 = to_bits(v201)
        else
            buffer.writef32(v118, 0, v201)
            v200 = buffer.readu32(v118, 0)
        end

        p55[53] = v198
        p55[54] = v202
        p55[55] = v199
        p55[56] = v200

        if v162 ~= 0 and v162 > -1.1754943508222875E-38 and v162 < 1.1754943508222875E-38 then
            v198 = to_bits(v162)
        else
            buffer.writef32(v118, 0, v162)
            v198 = buffer.readu32(v118, 0)
        end

        if v163 ~= 0 and v163 > -1.1754943508222875E-38 and v163 < 1.1754943508222875E-38 then
            v202 = to_bits(v163)
        else
            buffer.writef32(v118, 0, v163)
            v202 = buffer.readu32(v118, 0)
        end

        if v164 ~= 0 and v164 > -1.1754943508222875E-38 and v164 < 1.1754943508222875E-38 then
            v199 = to_bits(v164)
        else
            buffer.writef32(v118, 0, v164)
            v199 = buffer.readu32(v118, 0)
        end

        if v165 ~= 0 and v165 > -1.1754943508222875E-38 and v165 < 1.1754943508222875E-38 then
            v200 = to_bits(v165)
        else
            buffer.writef32(v118, 0, v165)
            v200 = buffer.readu32(v118, 0)
        end

        p55[57] = v198
        p55[58] = v202
        p55[59] = v199
        p55[60] = v200

        if v194 ~= 0 and v194 > -1.1754943508222875E-38 and v194 < 1.1754943508222875E-38 then
            v198 = to_bits(v194)
        else
            buffer.writef32(v118, 0, v194)
            v198 = buffer.readu32(v118, 0)
        end

        if v195 ~= 0 and v195 > -1.1754943508222875E-38 and v195 < 1.1754943508222875E-38 then
            v202 = to_bits(v195)
        else
            buffer.writef32(v118, 0, v195)
            v202 = buffer.readu32(v118, 0)
        end

        if v196 ~= 0 and v196 > -1.1754943508222875E-38 and v196 < 1.1754943508222875E-38 then
            v199 = to_bits(v196)
        else
            buffer.writef32(v118, 0, v196)
            v199 = buffer.readu32(v118, 0)
        end

        if v197 ~= 0 and v197 > -1.1754943508222875E-38 and v197 < 1.1754943508222875E-38 then
            v200 = to_bits(v197)
        else
            buffer.writef32(v118, 0, v197)
            v200 = buffer.readu32(v118, 0)
        end

        p55[61] = v198
        p55[62] = v202
        p55[63] = v199
        p55[64] = v200
        p55[65] = v171
        p55[66] = v171
        p55[67] = v171
        p55[68] = v171
    else
        v202 = v174 + v182

        if v202 ~= 0 and v202 > -1.1754943508222875E-38 and v202 < 1.1754943508222875E-38 then
            v198 = to_bits(v202)
        else
            buffer.writef32(v118, 0, v202)
            v198 = buffer.readu32(v118, 0)
        end

        v199 = v175 + v183

        if v199 ~= 0 and v199 > -1.1754943508222875E-38 and v199 < 1.1754943508222875E-38 then
            v202 = to_bits(v199)
        else
            buffer.writef32(v118, 0, v199)
            v202 = buffer.readu32(v118, 0)
        end

        v200 = v176 + v184

        if v200 ~= 0 and v200 > -1.1754943508222875E-38 and v200 < 1.1754943508222875E-38 then
            v199 = to_bits(v200)
        else
            buffer.writef32(v118, 0, v200)
            v199 = buffer.readu32(v118, 0)
        end

        v201 = v177 + v185

        if v201 ~= 0 and v201 > -1.1754943508222875E-38 and v201 < 1.1754943508222875E-38 then
            v200 = to_bits(v201)
        else
            buffer.writef32(v118, 0, v201)
            v200 = buffer.readu32(v118, 0)
        end

        p55[5] = v198
        p55[6] = v202
        p55[7] = v199
        p55[8] = v200
        v202 = -v162

        if v202 ~= 0 and v202 > -1.1754943508222875E-38 and v202 < 1.1754943508222875E-38 then
            v198 = to_bits(v202)
        else
            buffer.writef32(v118, 0, v202)
            v198 = buffer.readu32(v118, 0)
        end

        v199 = -v163

        if v199 ~= 0 and v199 > -1.1754943508222875E-38 and v199 < 1.1754943508222875E-38 then
            v202 = to_bits(v199)
        else
            buffer.writef32(v118, 0, v199)
            v202 = buffer.readu32(v118, 0)
        end

        v200 = -v164

        if v200 ~= 0 and v200 > -1.1754943508222875E-38 and v200 < 1.1754943508222875E-38 then
            v199 = to_bits(v200)
        else
            buffer.writef32(v118, 0, v200)
            v199 = buffer.readu32(v118, 0)
        end

        v201 = -v165

        if v201 ~= 0 and v201 > -1.1754943508222875E-38 and v201 < 1.1754943508222875E-38 then
            v200 = to_bits(v201)
        else
            buffer.writef32(v118, 0, v201)
            v200 = buffer.readu32(v118, 0)
        end

        p55[9] = v198
        p55[10] = v202
        p55[11] = v199
        p55[12] = v200
        v202 = -v194

        if v202 ~= 0 and v202 > -1.1754943508222875E-38 and v202 < 1.1754943508222875E-38 then
            v198 = to_bits(v202)
        else
            buffer.writef32(v118, 0, v202)
            v198 = buffer.readu32(v118, 0)
        end

        v199 = -v195

        if v199 ~= 0 and v199 > -1.1754943508222875E-38 and v199 < 1.1754943508222875E-38 then
            v202 = to_bits(v199)
        else
            buffer.writef32(v118, 0, v199)
            v202 = buffer.readu32(v118, 0)
        end

        v200 = -v196

        if v200 ~= 0 and v200 > -1.1754943508222875E-38 and v200 < 1.1754943508222875E-38 then
            v199 = to_bits(v200)
        else
            buffer.writef32(v118, 0, v200)
            v199 = buffer.readu32(v118, 0)
        end

        v201 = -v197

        if v201 ~= 0 and v201 > -1.1754943508222875E-38 and v201 < 1.1754943508222875E-38 then
            v200 = to_bits(v201)
        else
            buffer.writef32(v118, 0, v201)
            v200 = buffer.readu32(v118, 0)
        end

        p55[13] = v198
        p55[14] = v202
        p55[15] = v199
        p55[16] = v200
        p55[17] = v171
        p55[18] = v171
        p55[19] = v171
        p55[20] = v171
        v202 = v178 + v182

        if v202 ~= 0 and v202 > -1.1754943508222875E-38 and v202 < 1.1754943508222875E-38 then
            v198 = to_bits(v202)
        else
            buffer.writef32(v118, 0, v202)
            v198 = buffer.readu32(v118, 0)
        end

        v199 = v179 + v183

        if v199 ~= 0 and v199 > -1.1754943508222875E-38 and v199 < 1.1754943508222875E-38 then
            v202 = to_bits(v199)
        else
            buffer.writef32(v118, 0, v199)
            v202 = buffer.readu32(v118, 0)
        end

        v200 = v180 + v184

        if v200 ~= 0 and v200 > -1.1754943508222875E-38 and v200 < 1.1754943508222875E-38 then
            v199 = to_bits(v200)
        else
            buffer.writef32(v118, 0, v200)
            v199 = buffer.readu32(v118, 0)
        end

        v201 = v181 + v185

        if v201 ~= 0 and v201 > -1.1754943508222875E-38 and v201 < 1.1754943508222875E-38 then
            v200 = to_bits(v201)
        else
            buffer.writef32(v118, 0, v201)
            v200 = buffer.readu32(v118, 0)
        end

        p55[21] = v198
        p55[22] = v202
        p55[23] = v199
        p55[24] = v200
        v202 = -v166

        if v202 ~= 0 and v202 > -1.1754943508222875E-38 and v202 < 1.1754943508222875E-38 then
            v198 = to_bits(v202)
        else
            buffer.writef32(v118, 0, v202)
            v198 = buffer.readu32(v118, 0)
        end

        v199 = -v167

        if v199 ~= 0 and v199 > -1.1754943508222875E-38 and v199 < 1.1754943508222875E-38 then
            v202 = to_bits(v199)
        else
            buffer.writef32(v118, 0, v199)
            v202 = buffer.readu32(v118, 0)
        end

        v200 = -v168

        if v200 ~= 0 and v200 > -1.1754943508222875E-38 and v200 < 1.1754943508222875E-38 then
            v199 = to_bits(v200)
        else
            buffer.writef32(v118, 0, v200)
            v199 = buffer.readu32(v118, 0)
        end

        v201 = -v169

        if v201 ~= 0 and v201 > -1.1754943508222875E-38 and v201 < 1.1754943508222875E-38 then
            v200 = to_bits(v201)
        else
            buffer.writef32(v118, 0, v201)
            v200 = buffer.readu32(v118, 0)
        end

        p55[25] = v198
        p55[26] = v202
        p55[27] = v199
        p55[28] = v200
        v202 = -v190

        if v202 ~= 0 and v202 > -1.1754943508222875E-38 and v202 < 1.1754943508222875E-38 then
            v198 = to_bits(v202)
        else
            buffer.writef32(v118, 0, v202)
            v198 = buffer.readu32(v118, 0)
        end

        v199 = -v191

        if v199 ~= 0 and v199 > -1.1754943508222875E-38 and v199 < 1.1754943508222875E-38 then
            v202 = to_bits(v199)
        else
            buffer.writef32(v118, 0, v199)
            v202 = buffer.readu32(v118, 0)
        end

        v200 = -v192

        if v200 ~= 0 and v200 > -1.1754943508222875E-38 and v200 < 1.1754943508222875E-38 then
            v199 = to_bits(v200)
        else
            buffer.writef32(v118, 0, v200)
            v199 = buffer.readu32(v118, 0)
        end

        v201 = -v193

        if v201 ~= 0 and v201 > -1.1754943508222875E-38 and v201 < 1.1754943508222875E-38 then
            v200 = to_bits(v201)
        else
            buffer.writef32(v118, 0, v201)
            v200 = buffer.readu32(v118, 0)
        end

        p55[29] = v198
        p55[30] = v202
        p55[31] = v199
        p55[32] = v200
        p55[33] = v170
        p55[34] = v170
        p55[35] = v170
        p55[36] = v170
        v202 = v178 + v186

        if v202 ~= 0 and v202 > -1.1754943508222875E-38 and v202 < 1.1754943508222875E-38 then
            v198 = to_bits(v202)
        else
            buffer.writef32(v118, 0, v202)
            v198 = buffer.readu32(v118, 0)
        end

        v199 = v179 + v187

        if v199 ~= 0 and v199 > -1.1754943508222875E-38 and v199 < 1.1754943508222875E-38 then
            v202 = to_bits(v199)
        else
            buffer.writef32(v118, 0, v199)
            v202 = buffer.readu32(v118, 0)
        end

        v200 = v180 + v188

        if v200 ~= 0 and v200 > -1.1754943508222875E-38 and v200 < 1.1754943508222875E-38 then
            v199 = to_bits(v200)
        else
            buffer.writef32(v118, 0, v200)
            v199 = buffer.readu32(v118, 0)
        end

        v201 = v181 + v189

        if v201 ~= 0 and v201 > -1.1754943508222875E-38 and v201 < 1.1754943508222875E-38 then
            v200 = to_bits(v201)
        else
            buffer.writef32(v118, 0, v201)
            v200 = buffer.readu32(v118, 0)
        end

        p55[37] = v198
        p55[38] = v202
        p55[39] = v199
        p55[40] = v200

        if v162 ~= 0 and v162 > -1.1754943508222875E-38 and v162 < 1.1754943508222875E-38 then
            v198 = to_bits(v162)
        else
            buffer.writef32(v118, 0, v162)
            v198 = buffer.readu32(v118, 0)
        end

        if v163 ~= 0 and v163 > -1.1754943508222875E-38 and v163 < 1.1754943508222875E-38 then
            v202 = to_bits(v163)
        else
            buffer.writef32(v118, 0, v163)
            v202 = buffer.readu32(v118, 0)
        end

        if v164 ~= 0 and v164 > -1.1754943508222875E-38 and v164 < 1.1754943508222875E-38 then
            v199 = to_bits(v164)
        else
            buffer.writef32(v118, 0, v164)
            v199 = buffer.readu32(v118, 0)
        end

        if v165 ~= 0 and v165 > -1.1754943508222875E-38 and v165 < 1.1754943508222875E-38 then
            v200 = to_bits(v165)
        else
            buffer.writef32(v118, 0, v165)
            v200 = buffer.readu32(v118, 0)
        end

        p55[41] = v198
        p55[42] = v202
        p55[43] = v199
        p55[44] = v200

        if v194 ~= 0 and v194 > -1.1754943508222875E-38 and v194 < 1.1754943508222875E-38 then
            v198 = to_bits(v194)
        else
            buffer.writef32(v118, 0, v194)
            v198 = buffer.readu32(v118, 0)
        end

        if v195 ~= 0 and v195 > -1.1754943508222875E-38 and v195 < 1.1754943508222875E-38 then
            v202 = to_bits(v195)
        else
            buffer.writef32(v118, 0, v195)
            v202 = buffer.readu32(v118, 0)
        end

        if v196 ~= 0 and v196 > -1.1754943508222875E-38 and v196 < 1.1754943508222875E-38 then
            v199 = to_bits(v196)
        else
            buffer.writef32(v118, 0, v196)
            v199 = buffer.readu32(v118, 0)
        end

        if v197 ~= 0 and v197 > -1.1754943508222875E-38 and v197 < 1.1754943508222875E-38 then
            v200 = to_bits(v197)
        else
            buffer.writef32(v118, 0, v197)
            v200 = buffer.readu32(v118, 0)
        end

        p55[45] = v198
        p55[46] = v202
        p55[47] = v199
        p55[48] = v200
        p55[49] = v171
        p55[50] = v171
        p55[51] = v171
        p55[52] = v171
        v202 = v174 + v186

        if v202 ~= 0 and v202 > -1.1754943508222875E-38 and v202 < 1.1754943508222875E-38 then
            v198 = to_bits(v202)
        else
            buffer.writef32(v118, 0, v202)
            v198 = buffer.readu32(v118, 0)
        end

        v199 = v175 + v187

        if v199 ~= 0 and v199 > -1.1754943508222875E-38 and v199 < 1.1754943508222875E-38 then
            v202 = to_bits(v199)
        else
            buffer.writef32(v118, 0, v199)
            v202 = buffer.readu32(v118, 0)
        end

        v200 = v176 + v188

        if v200 ~= 0 and v200 > -1.1754943508222875E-38 and v200 < 1.1754943508222875E-38 then
            v199 = to_bits(v200)
        else
            buffer.writef32(v118, 0, v200)
            v199 = buffer.readu32(v118, 0)
        end

        v201 = v177 + v189

        if v201 ~= 0 and v201 > -1.1754943508222875E-38 and v201 < 1.1754943508222875E-38 then
            v200 = to_bits(v201)
        else
            buffer.writef32(v118, 0, v201)
            v200 = buffer.readu32(v118, 0)
        end

        p55[53] = v198
        p55[54] = v202
        p55[55] = v199
        p55[56] = v200

        if v166 ~= 0 and v166 > -1.1754943508222875E-38 and v166 < 1.1754943508222875E-38 then
            v198 = to_bits(v166)
        else
            buffer.writef32(v118, 0, v166)
            v198 = buffer.readu32(v118, 0)
        end

        if v167 ~= 0 and v167 > -1.1754943508222875E-38 and v167 < 1.1754943508222875E-38 then
            v202 = to_bits(v167)
        else
            buffer.writef32(v118, 0, v167)
            v202 = buffer.readu32(v118, 0)
        end

        if v168 ~= 0 and v168 > -1.1754943508222875E-38 and v168 < 1.1754943508222875E-38 then
            v199 = to_bits(v168)
        else
            buffer.writef32(v118, 0, v168)
            v199 = buffer.readu32(v118, 0)
        end

        if v169 ~= 0 and v169 > -1.1754943508222875E-38 and v169 < 1.1754943508222875E-38 then
            v200 = to_bits(v169)
        else
            buffer.writef32(v118, 0, v169)
            v200 = buffer.readu32(v118, 0)
        end

        p55[57] = v198
        p55[58] = v202
        p55[59] = v199
        p55[60] = v200

        if v190 ~= 0 and v190 > -1.1754943508222875E-38 and v190 < 1.1754943508222875E-38 then
            v198 = to_bits(v190)
        else
            buffer.writef32(v118, 0, v190)
            v198 = buffer.readu32(v118, 0)
        end

        if v191 ~= 0 and v191 > -1.1754943508222875E-38 and v191 < 1.1754943508222875E-38 then
            v202 = to_bits(v191)
        else
            buffer.writef32(v118, 0, v191)
            v202 = buffer.readu32(v118, 0)
        end

        if v192 ~= 0 and v192 > -1.1754943508222875E-38 and v192 < 1.1754943508222875E-38 then
            v199 = to_bits(v192)
        else
            buffer.writef32(v118, 0, v192)
            v199 = buffer.readu32(v118, 0)
        end

        if v193 ~= 0 and v193 > -1.1754943508222875E-38 and v193 < 1.1754943508222875E-38 then
            v200 = to_bits(v193)
        else
            buffer.writef32(v118, 0, v193)
            v200 = buffer.readu32(v118, 0)
        end

        p55[61] = v198
        p55[62] = v202
        p55[63] = v199
        p55[64] = v200
        p55[65] = v170
        p55[66] = v170
        p55[67] = v170
        p55[68] = v170
    end

    v197 = -v155
    v202 = v150 * v197

    if v202 ~= 0 and v202 > -1.1754943508222875E-38 and v202 < 1.1754943508222875E-38 then
        v198 = to_bits(v202)
    else
        buffer.writef32(v118, 0, v202)
        v198 = buffer.readu32(v118, 0)
    end

    v199 = v156 * v197

    if v199 ~= 0 and v199 > -1.1754943508222875E-38 and v199 < 1.1754943508222875E-38 then
        v202 = to_bits(v199)
    else
        buffer.writef32(v118, 0, v199)
        v202 = buffer.readu32(v118, 0)
    end

    v200 = v157 * v197

    if v200 ~= 0 and v200 > -1.1754943508222875E-38 and v200 < 1.1754943508222875E-38 then
        v199 = to_bits(v200)
    else
        buffer.writef32(v118, 0, v200)
        v199 = buffer.readu32(v118, 0)
    end

    v201 = v141 * v197

    if v201 ~= 0 and v201 > -1.1754943508222875E-38 and v201 < 1.1754943508222875E-38 then
        v200 = to_bits(v201)
    else
        buffer.writef32(v118, 0, v201)
        v200 = buffer.readu32(v118, 0)
    end

    p55[133] = v198
    p55[134] = v202
    p55[135] = v199
    p55[136] = v200
    p55[141] = 4
    p55[1] = 0
end

t1.face = face
t1.plane = plane
t1.load = load
t1.store = store
t1.dot = dot
t1.scale = scale
t1.sub = sub
t1.add = add
t1.madd = madd
t1.neg = neg
t1.cross = cross

return t1
