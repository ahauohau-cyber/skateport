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

local estimate = v8.estimate
local t1 = {}
local segment, load, store, dot, cross, build_feature_edge_planes_reference

local function triangle_maximum_feature_reference(p4, p5, p6, p7) -- line: 49
    -- upvalues: v1 (copy), segment (ref), load (ref), store (ref), dot (ref), build_feature_edge_planes_reference (ref)
    local v9 = load(p4, 4)

    buffer.writeu32(v1, 0, p6[1])

    local v11 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p6[2])

    local v13 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p6[3])

    local v15 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p6[4])

    local t2 = {
        v11,
        v13,
        v15,
        (buffer.readf32(v1, 0))
    }
    local v17 = dot(t2, v9)
    local t3 = {
        load(p4, 0),
        load(p4, 8),
        load(p4, 12)
    }
    local t4 = {
        load(p4, 16),
        load(p4, 20),
        load(p4, 24)
    }

    if math.abs(v17) > 0.949999988079071 then
        if (if v17 < 0 then 1 else 0) == p5 then
            local t5 = {
                0, 2, 1
            }

            segment(p7, 0, t3[t5[1] + 1], t4[1], p4[29])
            segment(p7, 1, t3[t5[2] + 1], t4[2], p4[30])
            segment(p7, 2, t3[t5[3] + 1], t4[3], p4[31])
            p7[1] = 8
        else
            local t6 = {
                0, 1, 2
            }

            for i = 0, 2 do
                local v18 = t6[i + 1]
                local v19 = t4[2 - i + 1]

                segment(p7, i, t3[v18 + 1], {
                    -v19[1],
                    -v19[2],
                    -v19[3],
                    -v19[4]
                }, p4[30 - i + 1])
            end

            p7[1] = 0
        end

        store(p7, 132, v9)
        p7[141] = 3
    else
        local t7 = {
            dot(t2, t3[1]),
            dot(t2, t3[2]),
            dot(t2, t3[3])
        }
        local t8 = {
            math.abs((dot(t2, t4[1]))),
            math.abs((dot(t2, t4[2]))),
            (math.abs((dot(t2, t4[3]))))
        }
        local v25, v26

        if t7[1] > t7[2] and t7[1] > t7[3] then
            if t8[1] < 0.05000000074505806 and t8[3] > t8[1] then
                v25 = 0
            elseif t8[3] < 0.05000000074505806 then
                v25 = 2
            end

            v26 = 0
        elseif t7[2] > t7[3] then
            if t8[2] < 0.05000000074505806 and t8[3] > t8[2] then
                v25 = 1
            elseif t8[3] < 0.05000000074505806 then
                v25 = 2
            end

            v26 = 1
        else
            if t8[1] < 0.05000000074505806 and t8[2] > t8[1] then
                v25 = 0
            elseif t8[2] < 0.05000000074505806 then
                v25 = 1
            end

            v26 = 2
        end

        if v25 ~= nil then
            local v27 = ({ 0, 2, 1 })[v25 + 1]

            segment(p7, 0, t3[v27 + 1], t4[v25 + 1], p4[28 + v25 + 1])
            p7[141] = 1
        else
            store(p7, 136, t3[v26 + 1])
            p7[141] = 0
        end
    end

    build_feature_edge_planes_reference(p7, p5, p6)
end

function build_feature_edge_planes_reference(p8, p9, p10) -- line: 132
    -- upvalues: rt (copy), v1 (copy), estimate (copy), load (ref), store (ref), dot (ref), cross (ref)
    local v28 = rt.to_i32(p8[141])

    if v28 <= 0 then
        return
    end

    if not (v28 <= 8) then
        error("native feature storage holds at most eight segments", 0)
    end

    buffer.writeu32(v1, 0, p10[1])

    local v30 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p10[2])

    local v32 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p10[3])

    local v34 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p10[4])

    local t9 = {
        v30,
        v32,
        v34,
        (buffer.readf32(v1, 0))
    }

    if p9 == 0 then
        t9 = {
            -t9[1],
            -t9[2],
            -t9[3],
            -t9[4]
        }
    end

    for i = 0, v28 - 1 do
        local v36 = i * 16 + 4
        local v37 = load(p8, v36 + 4)
        local v38 = cross(v37, t9)
        local v39 = dot(v38, v38)
        local v40 = estimate(v39)
        local v41 = v40 * 0.5 * (-v39 * (v40 * v40) + 1) + v40

        if not (v39 > 1.1920928955078125E-07) then
            v41 = 0
        end

        store(p8, v36 + 8, {
            v38[1] * v41,
            v38[2] * v41,
            v38[3] * v41,
            v38[4] * v41
        })
    end
end

t1.triangle_maximum_feature_reference = triangle_maximum_feature_reference
t1.build_feature_edge_planes_reference = build_feature_edge_planes_reference

local v42 = buffer.create(8)

local function fb(p11) -- line: 166
    -- upvalues: v42 (copy)
    buffer.writeu32(v42, 0, p11)

    return (buffer.readf32(v42, 0))
end

local to_bits = rt.to_bits

local function tb(p12) -- line: 171
    -- upvalues: v42 (copy), to_bits (copy)
    if p12 ~= 0 and p12 > -1.1754943508222875E-38 and p12 < 1.1754943508222875E-38 then
        return to_bits(p12)
    end

    buffer.writef32(v42, 0, p12)

    return (buffer.readu32(v42, 0))
end

local function build_feature_edge_planes(p13, p14, p15) -- line: 182
    -- upvalues: rt (copy), estimate (copy), v42 (copy), to_bits (copy)
    local v43 = rt.to_i32(p13[141])

    if v43 <= 0 then
        return
    end

    if not (v43 <= 8) then
        error("native feature storage holds at most eight segments", 0)
    end

    buffer.writeu32(v42, 0, p15[1])

    local v45 = buffer.readf32(v42, 0)

    buffer.writeu32(v42, 0, p15[2])

    local v47 = buffer.readf32(v42, 0)

    buffer.writeu32(v42, 0, p15[3])

    local v49 = buffer.readf32(v42, 0)

    buffer.writeu32(v42, 0, p15[4])

    local v51 = buffer.readf32(v42, 0)

    if p14 == 0 then
        v45 = -v45
        v47 = -v47
        v49 = -v49
        v51 = -v51
    end

    buffer.writeu32(v42, 0, 872415232)

    local v52 = buffer.readf32(v42, 0)

    for i = 0, v43 - 1 do
        local v53 = i * 16 + 4

        buffer.writeu32(v42, 0, p13[v53 + 5])

        local v55 = buffer.readf32(v42, 0)

        buffer.writeu32(v42, 0, p13[v53 + 6])

        local v57 = buffer.readf32(v42, 0)

        buffer.writeu32(v42, 0, p13[v53 + 7])

        local v59 = buffer.readf32(v42, 0)

        buffer.writeu32(v42, 0, p13[v53 + 8])

        local v61 = buffer.readf32(v42, 0)
        local v62 = -v59 * v47 + v57 * v49
        local v63 = -v55 * v49 + v59 * v45
        local v64 = -v57 * v45 + v55 * v47
        local v65 = -v61 * v51 + v61 * v51
        local v66 = v62 * v62 + v63 * v63 + v64 * v64
        local v67 = estimate(v66)
        local v68 = v67 * 0.5 * (-v66 * (v67 * v67) + 1) + v67

        if not (v52 < v66) then
            v68 = 0
        end

        local v69 = v53 + 9
        local v70 = v62 * v68

        if v70 ~= 0 and v70 > -1.1754943508222875E-38 and v70 < 1.1754943508222875E-38 then
            p13[v69] = to_bits(v70)
        else
            buffer.writef32(v42, 0, v70)
            p13[v69] = buffer.readu32(v42, 0)
        end

        local v71 = v53 + 10
        local v72 = v63 * v68

        if v72 ~= 0 and v72 > -1.1754943508222875E-38 and v72 < 1.1754943508222875E-38 then
            p13[v71] = to_bits(v72)
        else
            buffer.writef32(v42, 0, v72)
            p13[v71] = buffer.readu32(v42, 0)
        end

        local v73 = v53 + 11
        local v74 = v64 * v68

        if v74 ~= 0 and v74 > -1.1754943508222875E-38 and v74 < 1.1754943508222875E-38 then
            p13[v73] = to_bits(v74)
        else
            buffer.writef32(v42, 0, v74)
            p13[v73] = buffer.readu32(v42, 0)
        end

        local v75 = v53 + 12
        local v76 = v65 * v68

        if v76 ~= 0 and v76 > -1.1754943508222875E-38 and v76 < 1.1754943508222875E-38 then
            p13[v75] = to_bits(v76)
        else
            buffer.writef32(v42, 0, v76)
            p13[v75] = buffer.readu32(v42, 0)
        end
    end
end

t1.build_feature_edge_planes = build_feature_edge_planes

local function put_segment(p16, p17, p18, p19, p20, p21) -- line: 221
    -- upvalues: v42 (copy), to_bits (copy)
    buffer.writeu32(v42, 0, p18[p19 + 1])

    local v78 = buffer.readf32(v42, 0)

    buffer.writeu32(v42, 0, p18[p19 + 2])

    local v80 = buffer.readf32(v42, 0)

    buffer.writeu32(v42, 0, p18[p19 + 3])

    local v82 = buffer.readf32(v42, 0)

    buffer.writeu32(v42, 0, p18[p19 + 4])

    local v84 = buffer.readf32(v42, 0)

    buffer.writeu32(v42, 0, p18[p20 + 1])

    local v86 = buffer.readf32(v42, 0)

    buffer.writeu32(v42, 0, p18[p20 + 2])

    local v88 = buffer.readf32(v42, 0)

    buffer.writeu32(v42, 0, p18[p20 + 3])

    local v90 = buffer.readf32(v42, 0)

    buffer.writeu32(v42, 0, p18[p20 + 4])

    local v92 = buffer.readf32(v42, 0)
    local v93 = p17 + 1
    local v94 = p17 + 2
    local v95 = p17 + 3
    local v96 = p17 + 4
    local v97

    if v78 ~= 0 and v78 > -1.1754943508222875E-38 and v78 < 1.1754943508222875E-38 then
        v97 = to_bits(v78)
    else
        buffer.writef32(v42, 0, v78)
        v97 = buffer.readu32(v42, 0)
    end

    local v98

    if v80 ~= 0 and v80 > -1.1754943508222875E-38 and v80 < 1.1754943508222875E-38 then
        v98 = to_bits(v80)
    else
        buffer.writef32(v42, 0, v80)
        v98 = buffer.readu32(v42, 0)
    end

    local v99

    if v82 ~= 0 and v82 > -1.1754943508222875E-38 and v82 < 1.1754943508222875E-38 then
        v99 = to_bits(v82)
    else
        buffer.writef32(v42, 0, v82)
        v99 = buffer.readu32(v42, 0)
    end

    local v100

    if v84 ~= 0 and v84 > -1.1754943508222875E-38 and v84 < 1.1754943508222875E-38 then
        v100 = to_bits(v84)
    else
        buffer.writef32(v42, 0, v84)
        v100 = buffer.readu32(v42, 0)
    end

    p16[v93] = v97
    p16[v94] = v98
    p16[v95] = v99
    p16[v96] = v100

    local v101 = p17 + 5
    local v102 = p17 + 6
    local v103 = p17 + 7
    local v104 = p17 + 8
    local v105

    if v86 ~= 0 and v86 > -1.1754943508222875E-38 and v86 < 1.1754943508222875E-38 then
        v105 = to_bits(v86)
    else
        buffer.writef32(v42, 0, v86)
        v105 = buffer.readu32(v42, 0)
    end

    local v106

    if v88 ~= 0 and v88 > -1.1754943508222875E-38 and v88 < 1.1754943508222875E-38 then
        v106 = to_bits(v88)
    else
        buffer.writef32(v42, 0, v88)
        v106 = buffer.readu32(v42, 0)
    end

    local v107

    if v90 ~= 0 and v90 > -1.1754943508222875E-38 and v90 < 1.1754943508222875E-38 then
        v107 = to_bits(v90)
    else
        buffer.writef32(v42, 0, v90)
        v107 = buffer.readu32(v42, 0)
    end

    local v108

    if v92 ~= 0 and v92 > -1.1754943508222875E-38 and v92 < 1.1754943508222875E-38 then
        v108 = to_bits(v92)
    else
        buffer.writef32(v42, 0, v92)
        v108 = buffer.readu32(v42, 0)
    end

    p16[v101] = v105
    p16[v102] = v106
    p16[v103] = v107
    p16[v104] = v108

    local v109 = p17 + 13
    local v110 = p17 + 14
    local v111 = p17 + 15
    local v112 = p17 + 16

    p16[v109] = p21
    p16[v110] = p21
    p16[v111] = p21
    p16[v112] = p21
end

local function put_segment_negated(p22, p23, p24, p25, p26, p27) -- line: 229
    -- upvalues: v42 (copy), to_bits (copy)
    buffer.writeu32(v42, 0, p24[p25 + 1])

    local v114 = buffer.readf32(v42, 0)

    buffer.writeu32(v42, 0, p24[p25 + 2])

    local v116 = buffer.readf32(v42, 0)

    buffer.writeu32(v42, 0, p24[p25 + 3])

    local v118 = buffer.readf32(v42, 0)

    buffer.writeu32(v42, 0, p24[p25 + 4])

    local v120 = buffer.readf32(v42, 0)

    buffer.writeu32(v42, 0, p24[p26 + 1])

    local v122 = buffer.readf32(v42, 0)

    buffer.writeu32(v42, 0, p24[p26 + 2])

    local v124 = buffer.readf32(v42, 0)

    buffer.writeu32(v42, 0, p24[p26 + 3])

    local v126 = buffer.readf32(v42, 0)

    buffer.writeu32(v42, 0, p24[p26 + 4])

    local v128 = buffer.readf32(v42, 0)
    local v129 = p23 + 1
    local v130 = p23 + 2
    local v131 = p23 + 3
    local v132 = p23 + 4
    local v133

    if v114 ~= 0 and v114 > -1.1754943508222875E-38 and v114 < 1.1754943508222875E-38 then
        v133 = to_bits(v114)
    else
        buffer.writef32(v42, 0, v114)
        v133 = buffer.readu32(v42, 0)
    end

    local v134

    if v116 ~= 0 and v116 > -1.1754943508222875E-38 and v116 < 1.1754943508222875E-38 then
        v134 = to_bits(v116)
    else
        buffer.writef32(v42, 0, v116)
        v134 = buffer.readu32(v42, 0)
    end

    local v135

    if v118 ~= 0 and v118 > -1.1754943508222875E-38 and v118 < 1.1754943508222875E-38 then
        v135 = to_bits(v118)
    else
        buffer.writef32(v42, 0, v118)
        v135 = buffer.readu32(v42, 0)
    end

    local v136

    if v120 ~= 0 and v120 > -1.1754943508222875E-38 and v120 < 1.1754943508222875E-38 then
        v136 = to_bits(v120)
    else
        buffer.writef32(v42, 0, v120)
        v136 = buffer.readu32(v42, 0)
    end

    p22[v129] = v133
    p22[v130] = v134
    p22[v131] = v135
    p22[v132] = v136

    local v137 = p23 + 5
    local v138 = p23 + 6
    local v139 = p23 + 7
    local v140 = p23 + 8
    local v141 = -v122
    local v142

    if v141 ~= 0 and v141 > -1.1754943508222875E-38 and v141 < 1.1754943508222875E-38 then
        v142 = to_bits(v141)
    else
        buffer.writef32(v42, 0, v141)
        v142 = buffer.readu32(v42, 0)
    end

    local v143 = -v124
    local v144

    if v143 ~= 0 and v143 > -1.1754943508222875E-38 and v143 < 1.1754943508222875E-38 then
        v144 = to_bits(v143)
    else
        buffer.writef32(v42, 0, v143)
        v144 = buffer.readu32(v42, 0)
    end

    local v145 = -v126
    local v146

    if v145 ~= 0 and v145 > -1.1754943508222875E-38 and v145 < 1.1754943508222875E-38 then
        v146 = to_bits(v145)
    else
        buffer.writef32(v42, 0, v145)
        v146 = buffer.readu32(v42, 0)
    end

    local v147 = -v128
    local v148

    if v147 ~= 0 and v147 > -1.1754943508222875E-38 and v147 < 1.1754943508222875E-38 then
        v148 = to_bits(v147)
    else
        buffer.writef32(v42, 0, v147)
        v148 = buffer.readu32(v42, 0)
    end

    p22[v137] = v142
    p22[v138] = v144
    p22[v139] = v146
    p22[v140] = v148

    local v149 = p23 + 13
    local v150 = p23 + 14
    local v151 = p23 + 15
    local v152 = p23 + 16

    p22[v149] = p27
    p22[v150] = p27
    p22[v151] = p27
    p22[v152] = p27
end

function t1.triangle_maximum_feature(p28, p29, p30, p31) -- line: 242
    -- upvalues: v42 (copy), to_bits (copy), build_feature_edge_planes (copy), put_segment (copy), put_segment_negated (copy)
    buffer.writeu32(v42, 0, p30[1])

    local v154 = buffer.readf32(v42, 0)

    buffer.writeu32(v42, 0, p30[2])

    local v155 = buffer.readf32(v42, 0)

    buffer.writeu32(v42, 0, p30[3])

    local v156 = buffer.readf32(v42, 0)

    buffer.writeu32(v42, 0, p28[5])

    local v158 = v154 * buffer.readf32(v42, 0)
    local v159 = p28[6]

    buffer.writeu32(v42, 0, v159)

    local v160 = v158 + v155 * buffer.readf32(v42, 0)
    local v157 = p28[7]

    buffer.writeu32(v42, 0, v157)

    local v153 = v160 + v156 * buffer.readf32(v42, 0)

    v160 = math.abs(v153)
    buffer.writeu32(v42, 0, 1064514355)

    if buffer.readf32(v42, 0) < v160 then
        if (if v153 < 0 then 1 else 0) == p29 then
            put_segment(p31, 4, p28, 0, 16, p28[29])
            put_segment(p31, 20, p28, 12, 20, p28[30])
            put_segment(p31, 36, p28, 8, 24, p28[31])
            p31[1] = 8
        else
            put_segment_negated(p31, 4, p28, 0, 24, p28[31])
            put_segment_negated(p31, 20, p28, 8, 20, p28[30])
            put_segment_negated(p31, 36, p28, 12, 16, p28[29])
            p31[1] = 0
        end

        buffer.writeu32(v42, 0, p28[5])
        v157 = buffer.readf32(v42, 0)

        if v157 ~= 0 and v157 > -1.1754943508222875E-38 and v157 < 1.1754943508222875E-38 then
            v156 = to_bits(v157)
        else
            buffer.writef32(v42, 0, v157)
            v156 = buffer.readu32(v42, 0)
        end

        v157 = p28[6]
        buffer.writeu32(v42, 0, v157)
        v159 = buffer.readf32(v42, 0)

        if v159 ~= 0 and v159 > -1.1754943508222875E-38 and v159 < 1.1754943508222875E-38 then
            v158 = to_bits(v159)
        else
            buffer.writef32(v42, 0, v159)
            v158 = buffer.readu32(v42, 0)
        end

        v159 = p28[7]
        buffer.writeu32(v42, 0, v159)

        local v162 = buffer.readf32(v42, 0)
        local v161

        if v162 ~= 0 and v162 > -1.1754943508222875E-38 and v162 < 1.1754943508222875E-38 then
            v161 = to_bits(v162)
        else
            buffer.writef32(v42, 0, v162)
            v161 = buffer.readu32(v42, 0)
        end

        buffer.writeu32(v42, 0, p28[8])

        local v163 = buffer.readf32(v42, 0)

        if v163 ~= 0 and v163 > -1.1754943508222875E-38 and v163 < 1.1754943508222875E-38 then
            v157 = to_bits(v163)
        else
            buffer.writef32(v42, 0, v163)
            v157 = buffer.readu32(v42, 0)
        end

        p31[133] = v156
        p31[134] = v158
        p31[135] = v161
        p31[136] = v157
        p31[141] = 3
    else
        v159 = p28[1]
        buffer.writeu32(v42, 0, v159)

        local v164 = v154 * buffer.readf32(v42, 0)

        buffer.writeu32(v42, 0, p28[2])
        v158 = v164 + v155 * buffer.readf32(v42, 0)
        v159 = p28[3]
        buffer.writeu32(v42, 0, v159)

        local v166 = v158 + v156 * buffer.readf32(v42, 0)

        buffer.writeu32(v42, 0, p28[9])
        v157 = v154 * buffer.readf32(v42, 0)
        buffer.writeu32(v42, 0, p28[10])
        v164 = v157 + v155 * buffer.readf32(v42, 0)
        buffer.writeu32(v42, 0, p28[11])
        v158 = v164 + v156 * buffer.readf32(v42, 0)
        buffer.writeu32(v42, 0, p28[13])
        v159 = v154 * buffer.readf32(v42, 0)
        buffer.writeu32(v42, 0, p28[14])
        v157 = v159 + v155 * buffer.readf32(v42, 0)
        buffer.writeu32(v42, 0, p28[15])
        v164 = v157 + v156 * buffer.readf32(v42, 0)
        buffer.writeu32(v42, 0, p28[17])

        local v167 = v154 * buffer.readf32(v42, 0)

        buffer.writeu32(v42, 0, p28[18])

        local v165 = v167 + v155 * buffer.readf32(v42, 0)

        buffer.writeu32(v42, 0, p28[19])
        v159 = v165 + v156 * buffer.readf32(v42, 0)
        v157 = math.abs(v159)
        buffer.writeu32(v42, 0, p28[21])

        local v168 = v154 * buffer.readf32(v42, 0)

        buffer.writeu32(v42, 0, p28[22])
        v167 = v168 + v155 * buffer.readf32(v42, 0)

        local v170 = p28[23]

        buffer.writeu32(v42, 0, v170)
        v159 = math.abs(v167 + v156 * buffer.readf32(v42, 0))
        buffer.writeu32(v42, 0, p28[25])

        local v169 = v154 * buffer.readf32(v42, 0)
        local v172 = p28[26]

        buffer.writeu32(v42, 0, v172)
        v168 = v169 + v155 * buffer.readf32(v42, 0)

        local v171 = p28[27]

        buffer.writeu32(v42, 0, v171)
        v165 = math.abs(v168 + v156 * buffer.readf32(v42, 0))
        buffer.writeu32(v42, 0, 1028443341)
        v167 = buffer.readf32(v42, 0)

        if v158 < v166 and v164 < v166 then
            v169 = if v157 < v167 and v157 < v165 then 0 elseif v165 < v167 then 2 else nil
            v168 = 0
        elseif v164 < v158 then
            v169 = if v159 < v167 and v159 < v165 then 1 elseif v165 < v167 then 2 else nil
            v168 = 1
        else
            v169 = if v157 < v167 and v157 < v159 then 0 elseif v159 < v167 then 1 else nil
            v168 = 2
        end

        if v169 ~= nil then
            put_segment(p31, 4, p28, if v169 == 0 then 0 elseif v169 == 1 then 12 else 8, 16 + v169 * 4, p28[28 + v169 + 1])
            p31[141] = 1
        else
            v165 = if v168 == 0 then 0 elseif v168 == 1 then 8 else 12
            v172 = p28[v165 + 1]
            buffer.writeu32(v42, 0, v172)

            local v173 = buffer.readf32(v42, 0)

            if v173 ~= 0 and v173 > -1.1754943508222875E-38 and v173 < 1.1754943508222875E-38 then
                v170 = to_bits(v173)
            else
                buffer.writef32(v42, 0, v173)
                v170 = buffer.readu32(v42, 0)
            end

            buffer.writeu32(v42, 0, p28[v165 + 2])

            local v174 = buffer.readf32(v42, 0)

            if v174 ~= 0 and v174 > -1.1754943508222875E-38 and v174 < 1.1754943508222875E-38 then
                v171 = to_bits(v174)
            else
                buffer.writef32(v42, 0, v174)
                v171 = buffer.readu32(v42, 0)
            end

            buffer.writeu32(v42, 0, p28[v165 + 3])

            local v175 = buffer.readf32(v42, 0)

            if v175 ~= 0 and v175 > -1.1754943508222875E-38 and v175 < 1.1754943508222875E-38 then
                v172 = to_bits(v175)
            else
                buffer.writef32(v42, 0, v175)
                v172 = buffer.readu32(v42, 0)
            end

            buffer.writeu32(v42, 0, p28[v165 + 4])

            local v176 = buffer.readf32(v42, 0)

            if v176 ~= 0 and v176 > -1.1754943508222875E-38 and v176 < 1.1754943508222875E-38 then
                v173 = to_bits(v176)
            else
                buffer.writef32(v42, 0, v176)
                v173 = buffer.readu32(v42, 0)
            end

            p31[137] = v170
            p31[138] = v171
            p31[139] = v172
            p31[140] = v173
            p31[141] = 0
        end
    end

    build_feature_edge_planes(p31, p29, p30)
end

function segment(p32, p33, p34, p35, p36) -- line: 318
    -- upvalues: store (ref)
    local v178 = 4 + p33 * 16

    store(p32, v178, p34)
    store(p32, v178 + 4, p35)

    for i = v178 + 12, v178 + 15 do
        p32[i + 1] = p36
    end
end

function load(p37, p38) -- line: 326
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p37[p38 + 1])

    local v180 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p37[p38 + 2])

    local v182 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p37[p38 + 3])

    local v184 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p37[p38 + 4])

    return {
        v180,
        v182,
        v184,
        (buffer.readf32(v1, 0))
    }
end

function store(p39, p40, p41) -- line: 334
    -- upvalues: v1 (copy)
    local v186 = p40 + 1
    local v187 = p41[1]
    local v188

    if v187 ~= 0 and v187 > -1.1754943508222875E-38 and v187 < 1.1754943508222875E-38 then
        local v189 = math.abs(v187) * 7.1362384635298E+44
        local v190 = math.floor(v189)
        local v191 = v189 - v190

        v188 = if v191 > 0.5 or v191 == 0.5 and v190 % 2 == 1 then v190 + 1 else v190

        if v187 < 0 then
            v188 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v187)
        v188 = buffer.readu32(v1, 0)
    end

    p39[v186] = v188

    local v192 = p40 + 2
    local v193 = p41[2]
    local v194

    if v193 ~= 0 and v193 > -1.1754943508222875E-38 and v193 < 1.1754943508222875E-38 then
        local v195 = math.abs(v193) * 7.1362384635298E+44
        local v196 = math.floor(v195)
        local v197 = v195 - v196

        v194 = if v197 > 0.5 or v197 == 0.5 and v196 % 2 == 1 then v196 + 1 else v196

        if v193 < 0 then
            v194 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v193)
        v194 = buffer.readu32(v1, 0)
    end

    p39[v192] = v194

    local v198 = p40 + 3
    local v199 = p41[3]
    local v200

    if v199 ~= 0 and v199 > -1.1754943508222875E-38 and v199 < 1.1754943508222875E-38 then
        local v201 = math.abs(v199) * 7.1362384635298E+44
        local v202 = math.floor(v201)
        local v203 = v201 - v202

        v200 = if v203 > 0.5 or v203 == 0.5 and v202 % 2 == 1 then v202 + 1 else v202

        if v199 < 0 then
            v200 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v199)
        v200 = buffer.readu32(v1, 0)
    end

    p39[v198] = v200

    local v204 = p40 + 4
    local v205 = p41[4]
    local v206

    if v205 ~= 0 and v205 > -1.1754943508222875E-38 and v205 < 1.1754943508222875E-38 then
        local v207 = math.abs(v205) * 7.1362384635298E+44
        local v208 = math.floor(v207)
        local v209 = v207 - v208

        v206 = if v209 > 0.5 or v209 == 0.5 and v208 % 2 == 1 then v208 + 1 else v208

        if v205 < 0 then
            v206 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v205)
        v206 = buffer.readu32(v1, 0)
    end

    p39[v204] = v206
end

function dot(p42, p43) -- line: 340
    return p42[1] * p43[1] + p42[2] * p43[2] + p42[3] * p43[3]
end

function cross(p44, p45) -- line: 343
    return {
        -p44[3] * p45[2] + p44[2] * p45[3],
        -p44[1] * p45[3] + p44[3] * p45[1],
        -p44[2] * p45[1] + p44[1] * p45[2],
        -p44[4] * p45[4] + p44[4] * p45[4]
    }
end

t1.segment = segment
t1.load = load
t1.store = store
t1.dot = dot
t1.cross = cross

return t1
