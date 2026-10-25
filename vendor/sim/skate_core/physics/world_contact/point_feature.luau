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

local dot = require(sim.import)("skate_core/physics/world_contact/arithmetic").dot
local t1 = {}

local function load(p4, p5) -- line: 40
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p4[p5 + 1])

    local v9 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p4[p5 + 2])

    local v11 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p4[p5 + 3])

    local v13 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p4[p5 + 4])

    return {
        v9,
        v11,
        v13,
        (buffer.readf32(v1, 0))
    }
end

t1.load = load

local function dot3(p6, p7) -- line: 50
    -- upvalues: dot (copy)
    return dot({
        p6[1],
        p6[2],
        p6[3]
    }, {
        p7[1],
        p7[2],
        p7[3]
    })
end

t1.dot3 = dot3

local function closest_feature_segment_reference(p8, p9) -- line: 58
    -- upvalues: v1 (copy), dot3 (copy)
    buffer.writeu32(v1, 0, p8[1])

    local v16 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p8[2])

    local v18 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p8[3])

    local v20 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p8[4])

    local t2 = {
        v16,
        v18,
        v20,
        (buffer.readf32(v1, 0))
    }

    buffer.writeu32(v1, 0, p8[5])

    local v23 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p8[6])

    local v25 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p8[7])

    local v27 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p8[8])

    local t3 = {
        v23,
        v25,
        v27,
        (buffer.readf32(v1, 0))
    }

    buffer.writeu32(v1, 0, p9[1])

    local v30 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p9[2])

    local v32 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p9[3])

    local v34 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p9[4])

    local t4 = {
        v30,
        v32,
        v34,
        (buffer.readf32(v1, 0))
    }
    local v36 = dot3({
        t4[1] - t2[1],
        t4[2] - t2[2],
        t4[3] - t2[3],
        t4[4] - t2[4]
    }, t3)

    if v36 < 0 then
        p9[1] = p8[1]
        p9[2] = p8[2]
        p9[3] = p8[3]
        p9[4] = p8[4]

        return 1
    end

    buffer.writeu32(v1, 0, p8[13])

    local v38 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p8[14])

    local v40 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p8[15])

    local v42 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p8[16])

    local t5 = {
        v38,
        v40,
        v42,
        (buffer.readf32(v1, 0))
    }
    local v44 = t5[1] < v36 and t5[2] < v36 and t5[3] < v36 and t5[4] < v36

    for i = 1, 4 do
        local v45 = t3[i] * (if v44 then t5[i] else v36) + t2[i]

        if v45 ~= 0 and v45 > -1.1754943508222875E-38 and v45 < 1.1754943508222875E-38 then
            local v46 = math.abs(v45) * 7.1362384635298E+44
            local v47 = math.floor(v46)
            local v48 = v46 - v47
            local v49 = if v48 > 0.5 or v48 == 0.5 and v47 % 2 == 1 then v47 + 1 else v47

            if v45 < 0 then
                p9[i] = v49 + 2147483648
            else
                p9[i] = v49
            end
        else
            buffer.writef32(v1, 0, v45)
            p9[i] = buffer.readu32(v1, 0)
        end
    end

    if v44 then
        return 3
    end

    return 2
end

t1.closest_feature_segment_reference = closest_feature_segment_reference

local v50 = buffer.create(8)

local function fb(p10) -- line: 92
    -- upvalues: v50 (copy)
    buffer.writeu32(v50, 0, p10)

    return (buffer.readf32(v50, 0))
end

local to_bits = rt.to_bits

local function tb(p11) -- line: 97
    -- upvalues: v50 (copy), to_bits (copy)
    if p11 ~= 0 and p11 > -1.1754943508222875E-38 and p11 < 1.1754943508222875E-38 then
        return to_bits(p11)
    end

    buffer.writef32(v50, 0, p11)

    return (buffer.readu32(v50, 0))
end

local function closest_feature_segment_at(p12, p13, p14) -- line: 110
    -- upvalues: v50 (copy), to_bits (copy)
    buffer.writeu32(v50, 0, p12[p13 + 1])

    local v52 = buffer.readf32(v50, 0)

    buffer.writeu32(v50, 0, p12[p13 + 2])

    local v54 = buffer.readf32(v50, 0)

    buffer.writeu32(v50, 0, p12[p13 + 3])

    local v56 = buffer.readf32(v50, 0)

    buffer.writeu32(v50, 0, p12[p13 + 4])

    local v58 = buffer.readf32(v50, 0)

    buffer.writeu32(v50, 0, p12[p13 + 5])

    local v60 = buffer.readf32(v50, 0)

    buffer.writeu32(v50, 0, p12[p13 + 6])

    local v62 = buffer.readf32(v50, 0)

    buffer.writeu32(v50, 0, p12[p13 + 7])

    local v64 = buffer.readf32(v50, 0)

    buffer.writeu32(v50, 0, p12[p13 + 8])

    local v66 = buffer.readf32(v50, 0)

    buffer.writeu32(v50, 0, p14[1])

    local v68 = buffer.readf32(v50, 0)

    buffer.writeu32(v50, 0, p14[2])

    local v70 = buffer.readf32(v50, 0)

    buffer.writeu32(v50, 0, p14[3])

    local v72 = buffer.readf32(v50, 0)
    local v73 = (v68 - v52) * v60 + (v70 - v54) * v62 + (v72 - v56) * v64

    if v73 < 0 then
        local v74 = p12[p13 + 1]
        local v75 = p12[p13 + 2]
        local v76 = p12[p13 + 3]
        local v77 = p12[p13 + 4]

        p14[1] = v74
        p14[2] = v75
        p14[3] = v76
        p14[4] = v77

        return 1
    end

    buffer.writeu32(v50, 0, p12[p13 + 13])

    local v79 = buffer.readf32(v50, 0)

    buffer.writeu32(v50, 0, p12[p13 + 14])

    local v81 = buffer.readf32(v50, 0)

    buffer.writeu32(v50, 0, p12[p13 + 15])

    local v83 = buffer.readf32(v50, 0)

    buffer.writeu32(v50, 0, p12[p13 + 16])

    local v85 = buffer.readf32(v50, 0)

    if v79 < v73 and v81 < v73 and v83 < v73 and v85 < v73 then
        local v86 = v60 * v79 + v52
        local v87

        if v86 == 0 then
            buffer.writef32(v50, 0, v86)
            v87 = buffer.readu32(v50, 0)
        elseif v86 > -1.1754943508222875E-38 and v86 < 1.1754943508222875E-38 then
            v87 = to_bits(v86)
        else
            buffer.writef32(v50, 0, v86)
            v87 = buffer.readu32(v50, 0)
        end

        local v88 = v62 * v81 + v54
        local v89

        if v88 ~= 0 and v88 > -1.1754943508222875E-38 and v88 < 1.1754943508222875E-38 then
            v89 = to_bits(v88)
        else
            buffer.writef32(v50, 0, v88)
            v89 = buffer.readu32(v50, 0)
        end

        local v90 = v64 * v83 + v56
        local v91

        if v90 ~= 0 and v90 > -1.1754943508222875E-38 and v90 < 1.1754943508222875E-38 then
            v91 = to_bits(v90)
        else
            buffer.writef32(v50, 0, v90)
            v91 = buffer.readu32(v50, 0)
        end

        local v92 = v66 * v85 + v58
        local v93

        if v92 ~= 0 and v92 > -1.1754943508222875E-38 and v92 < 1.1754943508222875E-38 then
            v93 = to_bits(v92)
        else
            buffer.writef32(v50, 0, v92)
            v93 = buffer.readu32(v50, 0)
        end

        p14[1] = v87
        p14[2] = v89
        p14[3] = v91
        p14[4] = v93

        return 3
    end

    local v94 = v60 * v73 + v52
    local v95

    if v94 ~= 0 and v94 > -1.1754943508222875E-38 and v94 < 1.1754943508222875E-38 then
        v95 = to_bits(v94)
    else
        buffer.writef32(v50, 0, v94)
        v95 = buffer.readu32(v50, 0)
    end

    local v96 = v62 * v73 + v54
    local v97

    if v96 ~= 0 and v96 > -1.1754943508222875E-38 and v96 < 1.1754943508222875E-38 then
        v97 = to_bits(v96)
    else
        buffer.writef32(v50, 0, v96)
        v97 = buffer.readu32(v50, 0)
    end

    local v98 = v64 * v73 + v56
    local v99

    if v98 ~= 0 and v98 > -1.1754943508222875E-38 and v98 < 1.1754943508222875E-38 then
        v99 = to_bits(v98)
    else
        buffer.writef32(v50, 0, v98)
        v99 = buffer.readu32(v50, 0)
    end

    local v100 = v66 * v73 + v58
    local v101

    if v100 ~= 0 and v100 > -1.1754943508222875E-38 and v100 < 1.1754943508222875E-38 then
        v101 = to_bits(v100)
    else
        buffer.writef32(v50, 0, v100)
        v101 = buffer.readu32(v50, 0)
    end

    p14[1] = v95
    p14[2] = v97
    p14[3] = v99
    p14[4] = v101

    return 2
end

t1.closest_feature_segment_at = closest_feature_segment_at

function t1.closest_feature_segment(p15, p16) -- line: 133
    -- upvalues: closest_feature_segment_at (copy)
    return (closest_feature_segment_at(p15, 0, p16))
end

function t1.intersect_point_face_reference(p17, p18, p19, p20, p21) -- line: 140
    -- upvalues: rt (copy), v1 (copy), load (copy), dot3 (copy), closest_feature_segment_reference (copy)
    p17[133] = 1
    buffer.writeu32(v1, 0, p19[137])

    local v103 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p19[138])

    local v105 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p19[139])

    local v107 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p19[140])

    local t6 = {
        v103,
        v105,
        v107,
        (buffer.readf32(v1, 0))
    }

    buffer.writeu32(v1, 0, p20[1])

    local v110 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p20[2])

    local v112 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p20[3])

    local v114 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p20[4])

    local t7 = {
        v110,
        v112,
        v114,
        (buffer.readf32(v1, 0))
    }

    buffer.writeu32(v1, 0, p18[5])

    local v117 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p18[6])

    local v119 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p18[7])

    local v121 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p18[8])

    local t8 = {
        v117,
        v119,
        v121,
        (buffer.readf32(v1, 0))
    }
    local v123 = dot3(t7, {
        t8[1] - t6[1],
        t8[2] - t6[2],
        t8[3] - t6[3],
        t8[4] - t6[4]
    })
    local t9 = {
        t7[1] * v123 + t6[1],
        t7[2] * v123 + t6[2],
        t7[3] * v123 + t6[3],
        t7[4] * v123 + t6[4]
    }
    local t10 = t9

    if rt.to_i32(p18[141]) > 0 then
        local v124 = p18[141]

        if not (v124 <= 8) then
            error("native maximum-feature storage exceeded", 0)
        end

        local v125 = v124 - 1
        local n1 = 0
        local n2 = 0

        for i = 0, v125 do
            local v126 = load(p18, i * 16 + 4)
            local v128 = dot3(load(p18, i * 16 + 12), {
                t9[1] - v126[1],
                t9[2] - v126[2],
                t9[3] - v126[3],
                t9[4] - v126[4]
            })

            if i == 0 or n2 < v128 then
                n2 = v128
                n1 = i
            end
        end

        if n2 > 0 then
            local v129 = load(p18, n1 * 16 + 12)
            local v130 = t9[1] - v129[1] * n2
            local v131

            if v130 == 0 then
                buffer.writef32(v1, 0, v130)
                v131 = buffer.readu32(v1, 0)
            elseif v130 > -1.1754943508222875E-38 and v130 < 1.1754943508222875E-38 then
                local v132 = math.abs(v130) * 7.1362384635298E+44

                v131 = math.floor(v132)

                local v133 = v132 - v131

                if v133 > 0.5 or v133 == 0.5 and v131 % 2 == 1 then
                    v131 += 1
                end

                if v130 < 0 then
                    v131 += 2147483648
                end
            else
                buffer.writef32(v1, 0, v130)
                v131 = buffer.readu32(v1, 0)
            end

            local v134 = t9[2] - v129[2] * n2
            local v135

            if v134 ~= 0 and v134 > -1.1754943508222875E-38 and v134 < 1.1754943508222875E-38 then
                local v136 = math.abs(v134) * 7.1362384635298E+44
                local v137 = math.floor(v136)
                local v138 = v136 - v137

                v135 = if v138 > 0.5 or v138 == 0.5 and v137 % 2 == 1 then v137 + 1 else v137

                if v134 < 0 then
                    v135 += 2147483648
                end
            else
                buffer.writef32(v1, 0, v134)
                v135 = buffer.readu32(v1, 0)
            end

            local v139 = t9[3] - v129[3] * n2
            local v140

            if v139 ~= 0 and v139 > -1.1754943508222875E-38 and v139 < 1.1754943508222875E-38 then
                local v141 = math.abs(v139) * 7.1362384635298E+44
                local v142 = math.floor(v141)
                local v143 = v141 - v142

                v140 = if v143 > 0.5 or v143 == 0.5 and v142 % 2 == 1 then v142 + 1 else v142

                if v139 < 0 then
                    v140 += 2147483648
                end
            else
                buffer.writef32(v1, 0, v139)
                v140 = buffer.readu32(v1, 0)
            end

            local v144 = t9[4] - v129[4] * n2
            local v145

            if v144 ~= 0 and v144 > -1.1754943508222875E-38 and v144 < 1.1754943508222875E-38 then
                local v146 = math.abs(v144) * 7.1362384635298E+44
                local v147 = math.floor(v146)
                local v148 = v146 - v147

                v145 = if v148 > 0.5 or v148 == 0.5 and v147 % 2 == 1 then v147 + 1 else v147

                if v144 < 0 then
                    v145 += 2147483648
                end
            else
                buffer.writef32(v1, 0, v144)
                v145 = buffer.readu32(v1, 0)
            end

            local t11 = {
                v131,
                v135,
                v140,
                v145
            }
            local v150 = closest_feature_segment_reference(rt.slice(p18, n1 * 16 + 4, n1 * 16 + 20), t11)

            p18[1] = rt.wrapping_add_u32(p18[1], n1 * 2 + v150)
            buffer.writeu32(v1, 0, t11[1])

            local v152 = buffer.readf32(v1, 0)

            buffer.writeu32(v1, 0, t11[2])

            local v154 = buffer.readf32(v1, 0)

            buffer.writeu32(v1, 0, t11[3])

            local v156 = buffer.readf32(v1, 0)

            buffer.writeu32(v1, 0, t11[4])
            t10 = {
                v152,
                v154,
                v156,
                (buffer.readf32(v1, 0))
            }
        else
            t10 = t9
        end
    end

    local v158 = if p21 then 0 else 64
    local v159 = if p21 then 64 else 0
    local v160 = v158 + 1
    local v161 = t10[1]
    local v162

    if v161 ~= 0 and v161 > -1.1754943508222875E-38 and v161 < 1.1754943508222875E-38 then
        local v163 = math.abs(v161) * 7.1362384635298E+44
        local v164 = math.floor(v163)
        local v165 = v163 - v164

        v162 = if v165 > 0.5 or v165 == 0.5 and v164 % 2 == 1 then v164 + 1 else v164

        if v161 < 0 then
            v162 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v161)
        v162 = buffer.readu32(v1, 0)
    end

    p17[v160] = v162

    local v166 = v158 + 2
    local v167 = t10[2]
    local v168

    if v167 ~= 0 and v167 > -1.1754943508222875E-38 and v167 < 1.1754943508222875E-38 then
        local v169 = math.abs(v167) * 7.1362384635298E+44
        local v170 = math.floor(v169)
        local v171 = v169 - v170

        v168 = if v171 > 0.5 or v171 == 0.5 and v170 % 2 == 1 then v170 + 1 else v170

        if v167 < 0 then
            v168 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v167)
        v168 = buffer.readu32(v1, 0)
    end

    p17[v166] = v168

    local v172 = v158 + 3
    local v173 = t10[3]
    local v174

    if v173 ~= 0 and v173 > -1.1754943508222875E-38 and v173 < 1.1754943508222875E-38 then
        local v175 = math.abs(v173) * 7.1362384635298E+44
        local v176 = math.floor(v175)
        local v177 = v175 - v176

        v174 = if v177 > 0.5 or v177 == 0.5 and v176 % 2 == 1 then v176 + 1 else v176

        if v173 < 0 then
            v174 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v173)
        v174 = buffer.readu32(v1, 0)
    end

    p17[v172] = v174

    local v178 = v158 + 4
    local v179 = t10[4]
    local v180

    if v179 ~= 0 and v179 > -1.1754943508222875E-38 and v179 < 1.1754943508222875E-38 then
        local v181 = math.abs(v179) * 7.1362384635298E+44
        local v182 = math.floor(v181)
        local v183 = v181 - v182

        v180 = if v183 > 0.5 or v183 == 0.5 and v182 % 2 == 1 then v182 + 1 else v182

        if v179 < 0 then
            v180 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v179)
        v180 = buffer.readu32(v1, 0)
    end

    p17[v178] = v180
    p17[v159 + 1] = p19[137]
    p17[v159 + 2] = p19[138]
    p17[v159 + 3] = p19[139]
    p17[v159 + 4] = p19[140]

    return 1
end

local t12 = {
    0, 0, 0, 0
}

function t1.intersect_point_face(p22, p23, p24, p25, p26) -- line: 215
    -- upvalues: rt (copy), v50 (copy), to_bits (copy), closest_feature_segment_at (copy), t12 (copy)
    p22[133] = 1
    buffer.writeu32(v50, 0, p24[137])

    local v185 = buffer.readf32(v50, 0)

    buffer.writeu32(v50, 0, p24[138])

    local v187 = buffer.readf32(v50, 0)

    buffer.writeu32(v50, 0, p24[139])

    local v189 = buffer.readf32(v50, 0)

    buffer.writeu32(v50, 0, p24[140])

    local v191 = buffer.readf32(v50, 0)

    buffer.writeu32(v50, 0, p25[1])

    local v193 = buffer.readf32(v50, 0)

    buffer.writeu32(v50, 0, p25[2])

    local v195 = buffer.readf32(v50, 0)

    buffer.writeu32(v50, 0, p25[3])

    local v197 = buffer.readf32(v50, 0)

    buffer.writeu32(v50, 0, p25[4])

    local v199 = buffer.readf32(v50, 0)

    buffer.writeu32(v50, 0, p23[5])

    local v201 = v193 * (buffer.readf32(v50, 0) - v185)

    buffer.writeu32(v50, 0, p23[6])

    local v203 = v201 + v195 * (buffer.readf32(v50, 0) - v187)

    buffer.writeu32(v50, 0, p23[7])

    local v205 = v203 + v197 * (buffer.readf32(v50, 0) - v189)
    local v206 = v193 * v205 + v185
    local v207 = v195 * v205 + v187
    local v208 = v197 * v205 + v189
    local v209 = v199 * v205 + v191
    local v210 = v206
    local v211 = v207
    local v212 = v208
    local v213 = v209

    if rt.to_i32(p23[141]) > 0 then
        local v214 = p23[141]

        if not (v214 <= 8) then
            error("native maximum-feature storage exceeded", 0)
        end

        local v215 = v214 - 1
        local n3 = 0
        local n4 = 0

        for i = 0, v215 do
            local v216 = i * 16 + 4

            buffer.writeu32(v50, 0, p23[v216 + 9])

            local v218 = buffer.readf32(v50, 0)

            buffer.writeu32(v50, 0, p23[v216 + 1])

            local v220 = v218 * (v206 - buffer.readf32(v50, 0))

            buffer.writeu32(v50, 0, p23[v216 + 10])

            local v222 = buffer.readf32(v50, 0)

            buffer.writeu32(v50, 0, p23[v216 + 2])

            local v224 = v220 + v222 * (v207 - buffer.readf32(v50, 0))

            buffer.writeu32(v50, 0, p23[v216 + 11])

            local v226 = buffer.readf32(v50, 0)

            buffer.writeu32(v50, 0, p23[v216 + 3])

            local v228 = v224 + v226 * (v208 - buffer.readf32(v50, 0))

            if i == 0 or n3 < v228 then
                n4 = i
                n3 = v228
            end
        end

        if n3 > 0 then
            local v229 = n4 * 16 + 4

            buffer.writeu32(v50, 0, p23[v229 + 9])

            local v231 = v206 - buffer.readf32(v50, 0) * n3
            local v232

            if v231 == 0 then
                buffer.writef32(v50, 0, v231)
                v232 = buffer.readu32(v50, 0)
            elseif v231 > -1.1754943508222875E-38 and v231 < 1.1754943508222875E-38 then
                v232 = to_bits(v231)
            else
                buffer.writef32(v50, 0, v231)
                v232 = buffer.readu32(v50, 0)
            end

            t12[1] = v232
            buffer.writeu32(v50, 0, p23[v229 + 10])

            local v234 = v207 - buffer.readf32(v50, 0) * n3
            local v235

            if v234 ~= 0 and v234 > -1.1754943508222875E-38 and v234 < 1.1754943508222875E-38 then
                v235 = to_bits(v234)
            else
                buffer.writef32(v50, 0, v234)
                v235 = buffer.readu32(v50, 0)
            end

            t12[2] = v235
            buffer.writeu32(v50, 0, p23[v229 + 11])

            local v237 = v208 - buffer.readf32(v50, 0) * n3
            local v238

            if v237 ~= 0 and v237 > -1.1754943508222875E-38 and v237 < 1.1754943508222875E-38 then
                v238 = to_bits(v237)
            else
                buffer.writef32(v50, 0, v237)
                v238 = buffer.readu32(v50, 0)
            end

            t12[3] = v238
            buffer.writeu32(v50, 0, p23[v229 + 12])

            local v240 = v209 - buffer.readf32(v50, 0) * n3
            local v241

            if v240 ~= 0 and v240 > -1.1754943508222875E-38 and v240 < 1.1754943508222875E-38 then
                v241 = to_bits(v240)
            else
                buffer.writef32(v50, 0, v240)
                v241 = buffer.readu32(v50, 0)
            end

            t12[4] = v241

            local v242 = closest_feature_segment_at(p23, v229, t12)

            p23[1] = rt.wrapping_add_u32(p23[1], n4 * 2 + v242)
            buffer.writeu32(v50, 0, t12[1])
            v210 = buffer.readf32(v50, 0)
            buffer.writeu32(v50, 0, t12[2])
            v211 = buffer.readf32(v50, 0)
            buffer.writeu32(v50, 0, t12[3])
            v212 = buffer.readf32(v50, 0)
            buffer.writeu32(v50, 0, t12[4])
            v213 = buffer.readf32(v50, 0)
        else
            v210 = v206
            v211 = v207
            v212 = v208
            v213 = v209
        end
    end

    local v247 = if p26 then 0 else 64
    local v248 = if p26 then 64 else 0
    local v249 = v247 + 1
    local v250 = v247 + 2
    local v251 = v247 + 3
    local v252 = v247 + 4
    local v253

    if v210 ~= 0 and v210 > -1.1754943508222875E-38 and v210 < 1.1754943508222875E-38 then
        v253 = to_bits(v210)
    else
        buffer.writef32(v50, 0, v210)
        v253 = buffer.readu32(v50, 0)
    end

    local v254

    if v211 ~= 0 and v211 > -1.1754943508222875E-38 and v211 < 1.1754943508222875E-38 then
        v254 = to_bits(v211)
    else
        buffer.writef32(v50, 0, v211)
        v254 = buffer.readu32(v50, 0)
    end

    local v255

    if v212 ~= 0 and v212 > -1.1754943508222875E-38 and v212 < 1.1754943508222875E-38 then
        v255 = to_bits(v212)
    else
        buffer.writef32(v50, 0, v212)
        v255 = buffer.readu32(v50, 0)
    end

    local v256

    if v213 ~= 0 and v213 > -1.1754943508222875E-38 and v213 < 1.1754943508222875E-38 then
        v256 = to_bits(v213)
    else
        buffer.writef32(v50, 0, v213)
        v256 = buffer.readu32(v50, 0)
    end

    p22[v249] = v253
    p22[v250] = v254
    p22[v251] = v255
    p22[v252] = v256

    local v257 = v248 + 1
    local v258 = v248 + 2
    local v259 = v248 + 3
    local v260 = v248 + 4
    local v261 = p24[137]
    local v262 = p24[138]
    local v263 = p24[139]
    local v264 = p24[140]

    p22[v257] = v261
    p22[v258] = v262
    p22[v259] = v263
    p22[v260] = v264

    return 1
end

return t1
