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
local v12 = import("skate_core/physics/world_contact/point_feature")
local v13 = import("skate_core/physics/world_contact/prism_math")
local closest_feature_segment = v12.closest_feature_segment
local load, dot, sub, scale = v13.load, v13.dot, v13.sub, v13.scale
local cross, normalized = v13.cross, v13.normalized
local t1 = {}

local function clamp_point_to_feature_reference(p5, p6, p7) -- line: 55
    -- upvalues: rt (copy), v1 (copy), closest_feature_segment (copy), load (copy), dot (copy), sub (copy), scale (copy), cross (copy), normalized (copy)
    buffer.writeu32(v1, 0, p6[1])

    local v15 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p6[2])

    local v17 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p6[3])

    local v19 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p6[4])

    local t2 = {
        v15,
        v17,
        v19,
        (buffer.readf32(v1, 0))
    }

    buffer.writeu32(v1, 0, p7[1])

    local v22 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p7[2])

    local v24 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p7[3])

    local v26 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p7[4])

    local t3 = {
        v22,
        v24,
        v26,
        (buffer.readf32(v1, 0))
    }
    local v29 = math.max(rt.to_i32(p5[141]), 0)

    if not (v29 <= 8) then
        error("native maximum-feature storage exceeded", 0)
    end

    local v30 = {
        0, 0, 0, 0
    }
    local v31 = v29 - 1
    local n1 = 0
    local n2 = 0

    for i = 0, v31 do
        local v32 = cross(t2, load(p5, i * 16 + 8))

        if dot(v32, v32) > 1.1920928955078125E-07 then
            v32 = normalized(v32)
        end

        local v33 = dot(v32, sub(t3, load(p5, i * 16 + 4)))

        if i == 0 or v33 < n2 then
            v30 = v32
            n1 = i
            n2 = v33
        end
    end

    if not (n2 < 0) then
        return 0
    end

    local v34 = sub(t3, scale(v30, n2))
    local v35 = v34[1]
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

    p7[1] = v36

    local v40 = v34[2]
    local v41

    if v40 ~= 0 and v40 > -1.1754943508222875E-38 and v40 < 1.1754943508222875E-38 then
        local v42 = math.abs(v40) * 7.1362384635298E+44
        local v43 = math.floor(v42)
        local v44 = v42 - v43

        v41 = if v44 > 0.5 or v44 == 0.5 and v43 % 2 == 1 then v43 + 1 else v43

        if v40 < 0 then
            v41 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v40)
        v41 = buffer.readu32(v1, 0)
    end

    p7[2] = v41

    local v45 = v34[3]
    local v46

    if v45 ~= 0 and v45 > -1.1754943508222875E-38 and v45 < 1.1754943508222875E-38 then
        local v47 = math.abs(v45) * 7.1362384635298E+44
        local v48 = math.floor(v47)
        local v49 = v47 - v48

        v46 = if v49 > 0.5 or v49 == 0.5 and v48 % 2 == 1 then v48 + 1 else v48

        if v45 < 0 then
            v46 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v45)
        v46 = buffer.readu32(v1, 0)
    end

    p7[3] = v46

    local v50 = v34[4]
    local v51

    if v50 ~= 0 and v50 > -1.1754943508222875E-38 and v50 < 1.1754943508222875E-38 then
        local v52 = math.abs(v50) * 7.1362384635298E+44
        local v53 = math.floor(v52)
        local v54 = v52 - v53

        v51 = if v54 > 0.5 or v54 == 0.5 and v53 % 2 == 1 then v53 + 1 else v53

        if v50 < 0 then
            v51 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v50)
        v51 = buffer.readu32(v1, 0)
    end

    p7[4] = v51

    return closest_feature_segment(rt.slice(p5, n1 * 16 + 4, n1 * 16 + 20), p7) + n1 * 2
end

local function clip_segment_to_feature_reference(p8, p9, p10, p11, p12) -- line: 92
    -- upvalues: rt (copy), v1 (copy), v13 (copy), load (copy), dot (copy), sub (copy), cross (copy), normalized (copy)
    p11[1] = 0
    buffer.writeu32(v1, 0, p9[17])

    local v56 = buffer.readf32(v1, 0)

    if v56 == v56 then
        p11[2] = p9[17]
    else
        p11[2] = bit32.bor(p9[17], 4194304)
    end

    buffer.writeu32(v1, 0, p10[1])

    local v59 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p10[2])

    local v61 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p10[3])

    local v63 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p10[4])

    local t4 = {
        v59,
        v61,
        v63,
        (buffer.readf32(v1, 0))
    }
    local v66 = math.max(rt.to_i32(p8[141]), 0)

    if not (v66 <= 8) then
        error("native maximum-feature storage exceeded", 0)
    end

    local v67 = v66 - 1
    local v68 = false

    for i = 0, v67 do
        local v69 = cross(t4, load(p8, i * 16 + 8))
        local v70 = dot(v69, v69)
        local v71

        if v70 ~= 0 and v70 > -1.1754943508222875E-38 and v70 < 1.1754943508222875E-38 then
            local v72 = math.abs(v70) * 7.1362384635298E+44
            local v73 = math.floor(v72)
            local v74 = v72 - v73

            v71 = (if v74 > 0.5 or v74 == 0.5 and v73 % 2 == 1 then v73 + 1 else v73) * 1.401298464324817E-45

            if v70 < 0 then
                v71 = -v71
            end
        else
            buffer.writef32(v1, 0, v70)
            v71 = buffer.readf32(v1, 0)
        end

        if not ((if v71 == 0 then 0 else v71 * v13.inverse_length(v71)) < 0.0010000000474974513) then
            local v75 = normalized(v69)
            local v76 = load(p8, i * 16 + 4)
            local v77 = dot(load(p9, 8), v75)
            local v78 = dot(sub(v76, load(p9, 4)), v75)

            if math.abs(v77) < 0.05000000074505806 then
                if v78 > 0 then
                    p12[1] = p8[i * 16 + 4 + 1]
                    p12[2] = p8[i * 16 + 4 + 2]
                    p12[3] = p8[i * 16 + 4 + 3]
                    p12[4] = p8[i * 16 + 4 + 4]

                    local v79 = v75[1]
                    local v80

                    if v79 == 0 then
                        buffer.writef32(v1, 0, v79)
                        v80 = buffer.readu32(v1, 0)
                    elseif v79 > -1.1754943508222875E-38 and v79 < 1.1754943508222875E-38 then
                        local v81 = math.abs(v79) * 7.1362384635298E+44

                        v80 = math.floor(v81)

                        local v82 = v81 - v80

                        if v82 > 0.5 or v82 == 0.5 and v80 % 2 == 1 then
                            v80 += 1
                        end

                        if v79 < 0 then
                            v80 += 2147483648
                        end
                    else
                        buffer.writef32(v1, 0, v79)
                        v80 = buffer.readu32(v1, 0)
                    end

                    p12[5] = v80

                    local v83 = v75[2]

                    if v83 ~= 0 and v83 > -1.1754943508222875E-38 and v83 < 1.1754943508222875E-38 then
                        local v84 = math.abs(v83) * 7.1362384635298E+44
                        local v85 = math.floor(v84)
                        local v86 = v84 - v85
                        local v87 = if v86 > 0.5 or v86 == 0.5 and v85 % 2 == 1 then v85 + 1 else v85

                        if v83 < 0 then
                            p12[6] = v87 + 2147483648
                        else
                            p12[6] = v87
                        end
                    else
                        buffer.writef32(v1, 0, v83)
                        p12[6] = buffer.readu32(v1, 0)
                    end

                    local v88 = v75[3]

                    if v88 ~= 0 and v88 > -1.1754943508222875E-38 and v88 < 1.1754943508222875E-38 then
                        local v89 = math.abs(v88) * 7.1362384635298E+44
                        local v90 = math.floor(v89)
                        local v91 = v89 - v90
                        local v92 = if v91 > 0.5 or v91 == 0.5 and v90 % 2 == 1 then v90 + 1 else v90

                        if v88 < 0 then
                            p12[7] = v92 + 2147483648
                        else
                            p12[7] = v92
                        end
                    else
                        buffer.writef32(v1, 0, v88)
                        p12[7] = buffer.readu32(v1, 0)
                    end

                    local v93 = v75[4]

                    if v93 ~= 0 and v93 > -1.1754943508222875E-38 and v93 < 1.1754943508222875E-38 then
                        local v94 = math.abs(v93) * 7.1362384635298E+44
                        local v95 = math.floor(v94)
                        local v96 = v94 - v95
                        local v97 = if v96 > 0.5 or v96 == 0.5 and v95 % 2 == 1 then v95 + 1 else v95

                        if v93 < 0 then
                            p12[8] = v97 + 2147483648
                        else
                            p12[8] = v97
                        end
                    else
                        buffer.writef32(v1, 0, v93)
                        p12[8] = buffer.readu32(v1, 0)
                    end

                    v68 = true
                end
            else
                local v98 = v78 / v77

                if v77 > 0 then
                    buffer.writeu32(v1, 0, p11[1])

                    if buffer.readf32(v1, 0) < v98 then
                        local v100

                        if v98 == 0 then
                            buffer.writef32(v1, 0, v98)
                            v100 = buffer.readu32(v1, 0)
                        elseif v98 > -1.1754943508222875E-38 and v98 < 1.1754943508222875E-38 then
                            local v101 = math.abs(v98) * 7.1362384635298E+44

                            v100 = math.floor(v101)

                            local v102 = v101 - v100

                            if v102 > 0.5 or v102 == 0.5 and v100 % 2 == 1 then
                                v100 += 1
                            end

                            if v98 < 0 then
                                v100 += 2147483648
                            end
                        else
                            buffer.writef32(v1, 0, v98)
                            v100 = buffer.readu32(v1, 0)
                        end

                        p11[1] = v100
                    end

                    buffer.writeu32(v1, 0, p11[1])

                    local v104 = buffer.readf32(v1, 0)

                    buffer.writeu32(v1, 0, p11[2])

                    if buffer.readf32(v1, 0) < v104 then
                        p11[1] = p11[2]

                        return 0
                    end
                else
                    buffer.writeu32(v1, 0, p11[2])

                    if v98 < buffer.readf32(v1, 0) then
                        local v107

                        if v98 == 0 then
                            buffer.writef32(v1, 0, v98)
                            v107 = buffer.readu32(v1, 0)
                        elseif v98 > -1.1754943508222875E-38 and v98 < 1.1754943508222875E-38 then
                            local v108 = math.abs(v98) * 7.1362384635298E+44

                            v107 = math.floor(v108)

                            local v109 = v108 - v107

                            if v109 > 0.5 or v109 == 0.5 and v107 % 2 == 1 then
                                v107 += 1
                            end

                            if v98 < 0 then
                                v107 += 2147483648
                            end
                        else
                            buffer.writef32(v1, 0, v98)
                            v107 = buffer.readu32(v1, 0)
                        end

                        p11[2] = v107
                    end

                    buffer.writeu32(v1, 0, p11[2])

                    local v111 = buffer.readf32(v1, 0)

                    buffer.writeu32(v1, 0, p11[1])

                    if v111 < buffer.readf32(v1, 0) then
                        p11[2] = p11[1]

                        return 0
                    end
                end
            end
        end
    end

    if v68 then
        return 0
    end

    return 1
end

t1.clamp_point_to_feature_reference = clamp_point_to_feature_reference
t1.clip_segment_to_feature_reference = clip_segment_to_feature_reference

local estimate = import("skate_core/physics/reciprocal_sqrt").estimate
local closest_feature_segment_at = v12.closest_feature_segment_at
local v113 = buffer.create(8)

local function fb(p13) -- line: 178
    -- upvalues: v113 (copy)
    buffer.writeu32(v113, 0, p13)

    return (buffer.readf32(v113, 0))
end

local to_bits = rt.to_bits

local function tb(p14) -- line: 183
    -- upvalues: v113 (copy), to_bits (copy)
    if p14 ~= 0 and p14 > -1.1754943508222875E-38 and p14 < 1.1754943508222875E-38 then
        return to_bits(p14)
    end

    buffer.writef32(v113, 0, p14)

    return (buffer.readu32(v113, 0))
end

local function inverse_length_fast(p15) -- line: 190
    -- upvalues: estimate (copy)
    local v114 = estimate(p15)
    local v115 = v114 * 0.5 * (-p15 * (v114 * v114) + 1) + v114

    return v115 * 0.5 * (-p15 * (v115 * v115) + 1) + v115
end

function t1.clamp_point_to_feature(p16, p17, p18) -- line: 200
    -- upvalues: rt (copy), estimate (copy), closest_feature_segment_at (copy), v113 (copy), to_bits (copy)
    buffer.writeu32(v113, 0, p17[1])

    local v117 = buffer.readf32(v113, 0)

    buffer.writeu32(v113, 0, p17[2])

    local v119 = buffer.readf32(v113, 0)

    buffer.writeu32(v113, 0, p17[3])

    local v121 = buffer.readf32(v113, 0)

    buffer.writeu32(v113, 0, p17[4])

    local v123 = buffer.readf32(v113, 0)

    buffer.writeu32(v113, 0, p18[1])

    local v125 = buffer.readf32(v113, 0)

    buffer.writeu32(v113, 0, p18[2])

    local v127 = buffer.readf32(v113, 0)

    buffer.writeu32(v113, 0, p18[3])

    local v129 = buffer.readf32(v113, 0)

    buffer.writeu32(v113, 0, p18[4])

    local v131 = buffer.readf32(v113, 0)
    local v133 = math.max(rt.to_i32(p16[141]), 0)

    if not (v133 <= 8) then
        error("native maximum-feature storage exceeded", 0)
    end

    local v134 = v133 - 1
    local n3 = 0
    local n4 = 0
    local n5 = 0
    local n6 = 0
    local n7 = 0
    local n8 = 0

    for i = 0, v134 do
        local v135 = i * 16 + 8

        buffer.writeu32(v113, 0, p16[v135 + 1])

        local v137 = buffer.readf32(v113, 0)

        buffer.writeu32(v113, 0, p16[v135 + 2])

        local v139 = buffer.readf32(v113, 0)

        buffer.writeu32(v113, 0, p16[v135 + 3])

        local v141 = buffer.readf32(v113, 0)

        buffer.writeu32(v113, 0, p16[v135 + 4])

        local v143 = buffer.readf32(v113, 0)
        local v144 = -v121 * v139 + v119 * v141
        local v145 = -v117 * v141 + v121 * v137
        local v146 = -v119 * v137 + v117 * v139
        local v147 = -v123 * v143 + v123 * v143
        local v148 = v144 * v144 + v145 * v145 + v146 * v146

        if v148 > 1.1920928955078125E-07 then
            local v149 = estimate(v148)
            local v150 = v149 * 0.5 * (-v148 * (v149 * v149) + 1) + v149
            local v151 = v150 * 0.5 * (-v148 * (v150 * v150) + 1) + v150

            v144 *= v151
            v145 *= v151
            v146 *= v151
            v147 *= v151
        end

        local v152 = i * 16 + 4

        buffer.writeu32(v113, 0, p16[v152 + 1])

        local v154 = v144 * (v125 - buffer.readf32(v113, 0))

        buffer.writeu32(v113, 0, p16[v152 + 2])

        local v156 = v154 + v145 * (v127 - buffer.readf32(v113, 0))

        buffer.writeu32(v113, 0, p16[v152 + 3])

        local v158 = v156 + v146 * (v129 - buffer.readf32(v113, 0))

        if i == 0 or v158 < n4 then
            n8 = v147
            n3 = i
            n4 = v158
            n5 = v144
            n6 = v145
            n7 = v146
        end
    end

    if not (n4 < 0) then
        return 0
    end

    local v159 = v125 - n5 * n4
    local v160

    if v159 ~= 0 and v159 > -1.1754943508222875E-38 and v159 < 1.1754943508222875E-38 then
        v160 = to_bits(v159)
    else
        buffer.writef32(v113, 0, v159)
        v160 = buffer.readu32(v113, 0)
    end

    local v161 = v127 - n6 * n4
    local v162

    if v161 ~= 0 and v161 > -1.1754943508222875E-38 and v161 < 1.1754943508222875E-38 then
        v162 = to_bits(v161)
    else
        buffer.writef32(v113, 0, v161)
        v162 = buffer.readu32(v113, 0)
    end

    local v163 = v129 - n7 * n4
    local v164

    if v163 ~= 0 and v163 > -1.1754943508222875E-38 and v163 < 1.1754943508222875E-38 then
        v164 = to_bits(v163)
    else
        buffer.writef32(v113, 0, v163)
        v164 = buffer.readu32(v113, 0)
    end

    local v165 = v131 - n8 * n4
    local v166

    if v165 ~= 0 and v165 > -1.1754943508222875E-38 and v165 < 1.1754943508222875E-38 then
        v166 = to_bits(v165)
    else
        buffer.writef32(v113, 0, v165)
        v166 = buffer.readu32(v113, 0)
    end

    p18[1] = v160
    p18[2] = v162
    p18[3] = v164
    p18[4] = v166

    return closest_feature_segment_at(p16, n3 * 16 + 4, p18) + n3 * 2
end

function t1.clip_segment_to_feature(p19, p20, p21, p22, p23) -- line: 248
    -- upvalues: rt (copy), v1 (copy), estimate (copy), v113 (copy), to_bits (copy)
    p22[1] = 0
    buffer.writeu32(v113, 0, p20[17])

    local v168 = buffer.readf32(v113, 0)

    if v168 == v168 then
        p22[2] = p20[17]
    else
        p22[2] = bit32.bor(p20[17], 4194304)
    end

    buffer.writeu32(v113, 0, p21[1])

    local v171 = buffer.readf32(v113, 0)

    buffer.writeu32(v113, 0, p21[2])

    local v173 = buffer.readf32(v113, 0)

    buffer.writeu32(v113, 0, p21[3])

    local v175 = buffer.readf32(v113, 0)

    buffer.writeu32(v113, 0, p21[4])

    local v177 = buffer.readf32(v113, 0)
    local v179 = math.max(rt.to_i32(p19[141]), 0)

    if not (v179 <= 8) then
        error("native maximum-feature storage exceeded", 0)
    end

    buffer.writeu32(v113, 0, p20[5])

    local v181 = buffer.readf32(v113, 0)

    buffer.writeu32(v113, 0, p20[6])

    local v183 = buffer.readf32(v113, 0)

    buffer.writeu32(v113, 0, p20[7])

    local v185 = buffer.readf32(v113, 0)

    buffer.writeu32(v113, 0, p20[9])

    local v187 = buffer.readf32(v113, 0)

    buffer.writeu32(v113, 0, p20[10])

    local v189 = buffer.readf32(v113, 0)

    buffer.writeu32(v113, 0, p20[11])

    local v191 = buffer.readf32(v113, 0)
    local v192 = v179 - 1
    local v193 = false

    for i = 0, v192 do
        local v194 = i * 16 + 8

        buffer.writeu32(v113, 0, p19[v194 + 1])

        local v196 = buffer.readf32(v113, 0)

        buffer.writeu32(v113, 0, p19[v194 + 2])

        local v198 = buffer.readf32(v113, 0)

        buffer.writeu32(v113, 0, p19[v194 + 3])

        local v200 = buffer.readf32(v113, 0)

        buffer.writeu32(v113, 0, p19[v194 + 4])

        local v202 = buffer.readf32(v113, 0)
        local v203 = -v175 * v198 + v173 * v200
        local v204 = -v171 * v200 + v175 * v196
        local v205 = -v173 * v196 + v171 * v198
        local v206 = -v177 * v202 + v177 * v202
        local v207 = v203 * v203 + v204 * v204 + v205 * v205
        local v208

        if v207 ~= 0 and v207 > -1.1754943508222875E-38 and v207 < 1.1754943508222875E-38 then
            local v209 = math.abs(v207) * 7.1362384635298E+44
            local v210 = math.floor(v209)
            local v211 = v209 - v210

            v208 = (if v211 > 0.5 or v211 == 0.5 and v210 % 2 == 1 then v210 + 1 else v210) * 1.401298464324817E-45

            if v207 < 0 then
                v208 = -v208
            end
        else
            buffer.writef32(v1, 0, v207)
            v208 = buffer.readf32(v1, 0)
        end

        local v212

        if v208 == 0 then
            v212 = 0
        else
            local v213 = estimate(v208)
            local v214 = v213 * 0.5 * (-v208 * (v213 * v213) + 1) + v213

            v212 = v208 * (v214 * 0.5 * (-v208 * (v214 * v214) + 1) + v214)
        end

        if not (v212 < 0.0010000000474974513) then
            local v215 = v203 * v203 + v204 * v204 + v205 * v205
            local v216 = estimate(v215)
            local v217 = v216 * 0.5 * (-v215 * (v216 * v216) + 1) + v216
            local v218 = v217 * 0.5 * (-v215 * (v217 * v217) + 1) + v217
            local v219 = v203 * v218
            local v220 = v204 * v218
            local v221 = v205 * v218
            local v222 = v206 * v218
            local v223 = i * 16 + 4
            local v224 = v187 * v219 + v189 * v220 + v191 * v221

            buffer.writeu32(v113, 0, p19[v223 + 1])

            local v226 = (buffer.readf32(v113, 0) - v181) * v219

            buffer.writeu32(v113, 0, p19[v223 + 2])

            local v228 = v226 + (buffer.readf32(v113, 0) - v183) * v220

            buffer.writeu32(v113, 0, p19[v223 + 3])

            local v230 = v228 + (buffer.readf32(v113, 0) - v185) * v221

            if math.abs(v224) < 0.05000000074505806 then
                if v230 > 0 then
                    local v231 = p19[v223 + 1]
                    local v232 = p19[v223 + 2]
                    local v233 = p19[v223 + 3]
                    local v234 = p19[v223 + 4]

                    p23[1] = v231
                    p23[2] = v232
                    p23[3] = v233
                    p23[4] = v234

                    local v235

                    if v219 == 0 then
                        buffer.writef32(v113, 0, v219)
                        v235 = buffer.readu32(v113, 0)
                    elseif v219 > -1.1754943508222875E-38 and v219 < 1.1754943508222875E-38 then
                        v235 = to_bits(v219)
                    else
                        buffer.writef32(v113, 0, v219)
                        v235 = buffer.readu32(v113, 0)
                    end

                    local v236

                    if v220 ~= 0 and v220 > -1.1754943508222875E-38 and v220 < 1.1754943508222875E-38 then
                        v236 = to_bits(v220)
                    else
                        buffer.writef32(v113, 0, v220)
                        v236 = buffer.readu32(v113, 0)
                    end

                    local v237

                    if v221 ~= 0 and v221 > -1.1754943508222875E-38 and v221 < 1.1754943508222875E-38 then
                        v237 = to_bits(v221)
                    else
                        buffer.writef32(v113, 0, v221)
                        v237 = buffer.readu32(v113, 0)
                    end

                    local v238

                    if v222 ~= 0 and v222 > -1.1754943508222875E-38 and v222 < 1.1754943508222875E-38 then
                        v238 = to_bits(v222)
                    else
                        buffer.writef32(v113, 0, v222)
                        v238 = buffer.readu32(v113, 0)
                    end

                    p23[5] = v235
                    p23[6] = v236
                    p23[7] = v237
                    v193 = true
                    p23[8] = v238
                end
            else
                local v239 = v230 / v224

                if v224 > 0 then
                    buffer.writeu32(v113, 0, p22[1])

                    if buffer.readf32(v113, 0) < v239 then
                        if v239 == 0 then
                            buffer.writef32(v113, 0, v239)
                            p22[1] = buffer.readu32(v113, 0)
                        elseif v239 > -1.1754943508222875E-38 and v239 < 1.1754943508222875E-38 then
                            p22[1] = to_bits(v239)
                        else
                            buffer.writef32(v113, 0, v239)
                            p22[1] = buffer.readu32(v113, 0)
                        end
                    end

                    buffer.writeu32(v113, 0, p22[1])

                    local v242 = buffer.readf32(v113, 0)

                    buffer.writeu32(v113, 0, p22[2])

                    if buffer.readf32(v113, 0) < v242 then
                        p22[1] = p22[2]

                        return 0
                    end
                else
                    buffer.writeu32(v113, 0, p22[2])

                    if v239 < buffer.readf32(v113, 0) then
                        if v239 == 0 then
                            buffer.writef32(v113, 0, v239)
                            p22[2] = buffer.readu32(v113, 0)
                        elseif v239 > -1.1754943508222875E-38 and v239 < 1.1754943508222875E-38 then
                            p22[2] = to_bits(v239)
                        else
                            buffer.writef32(v113, 0, v239)
                            p22[2] = buffer.readu32(v113, 0)
                        end
                    end

                    buffer.writeu32(v113, 0, p22[2])

                    local v246 = buffer.readf32(v113, 0)

                    buffer.writeu32(v113, 0, p22[1])

                    if v246 < buffer.readf32(v113, 0) then
                        p22[2] = p22[1]

                        return 0
                    end
                end
            end
        end
    end

    if v193 then
        return 0
    end

    return 1
end

return t1
