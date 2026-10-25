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

local estimate = v12.estimate
local t1 = {}

local function to_bits4(p5) -- line: 51
    -- upvalues: v1 (copy)
    local v13 = p5[1]
    local v14

    if v13 ~= 0 and v13 > -1.1754943508222875E-38 and v13 < 1.1754943508222875E-38 then
        local v15 = math.abs(v13) * 7.1362384635298E+44
        local v16 = math.floor(v15)
        local v17 = v15 - v16

        v14 = if v17 > 0.5 or v17 == 0.5 and v16 % 2 == 1 then v16 + 1 else v16

        if v13 < 0 then
            v14 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v13)
        v14 = buffer.readu32(v1, 0)
    end

    local v18 = p5[2]
    local v19

    if v18 ~= 0 and v18 > -1.1754943508222875E-38 and v18 < 1.1754943508222875E-38 then
        local v20 = math.abs(v18) * 7.1362384635298E+44
        local v21 = math.floor(v20)
        local v22 = v20 - v21

        v19 = if v22 > 0.5 or v22 == 0.5 and v21 % 2 == 1 then v21 + 1 else v21

        if v18 < 0 then
            v19 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v18)
        v19 = buffer.readu32(v1, 0)
    end

    local v23 = p5[3]
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

    local v28 = p5[4]
    local v29

    if v28 ~= 0 and v28 > -1.1754943508222875E-38 and v28 < 1.1754943508222875E-38 then
        local v30 = math.abs(v28) * 7.1362384635298E+44
        local v31 = math.floor(v30)
        local v32 = v30 - v31

        v29 = if v32 > 0.5 or v32 == 0.5 and v31 % 2 == 1 then v31 + 1 else v31

        if v28 < 0 then
            v29 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v28)
        v29 = buffer.readu32(v1, 0)
    end

    return {
        v14,
        v19,
        v24,
        v29
    }
end

local append, load, sub, cross, dot, normalized, length

function t1.separating_axis_candidates_reference(p6, p7, p8) -- line: 63
    -- upvalues: to_bits4 (copy), append (ref), load (ref), sub (ref), cross (ref), dot (ref), normalized (ref), length (ref)
    local n1 = 0

    for _, v33 in { p6, p7 } do
        local v35 = bit32.rshift(v33[36], 24)

        if v35 >= 1 and v35 <= 3 then
            for i = v35, 1, -1 do
                local v36 = p8[n1 + 1]

                v36[1] = v33[i * 4 + 0 + 1]
                v36[2] = v33[i * 4 + 1 + 1]
                v36[3] = v33[i * 4 + 2 + 1]
                v36[4] = v33[i * 4 + 3 + 1]
                n1 += 1
            end
        end
    end

    local v39 = bit32.band(bit32.rshift(p6[36], 16), 255)
    local v42 = bit32.band(bit32.rshift(p7[36], 16), 255)

    if not (v39 <= 3 and v42 <= 3) then
        error("native GP contains at most three edges", 0)
    end

    for i = 0, v39 - 1 do
        for j = 0, v42 - 1 do
            local v43 = cross(load(p6, i * 4 + 16), load(p7, j * 4 + 16))
            local v44 = dot(v43)

            p8[n1 + 1] = to_bits4(v43)

            if v44 > 0.0010000000474974513 then
                p8[n1 + 1] = to_bits4(normalized(v43, v44))
                n1 += 1
            end
        end
    end

    if v39 == 1 and v42 == 1 then
        local v45 = load(p6, 16)
        local v46 = load(p7, 16)
        local v47 = cross(v45, v46)

        if length(v47) > 1.1920928955078125E-07 then
            for _, v49 in { v45, v46 } do
                local v50 = cross(v49, v47)

                p8[n1 + 1] = to_bits4(normalized(v50, dot(v50)))
                n1 += 1
            end
        end
    end

    if n1 ~= 0 then
        return n1
    end

    local v51 = sub(load(p6, 0), load(p7, 0))

    if v39 == 1 and v42 == 1 then
        local v52 = load(p6, 16)

        n1 = append(cross(cross(v51, v52), v52), p8, n1)
    end

    if v39 + v42 == 1 then
        local v53 = if v39 == 0 then load(p7, 16) else load(p6, 16)

        n1 = append(cross(cross(v51, v53), v53), p8, n1)
    end

    if n1 == 0 then
        return (append(v51, p8, n1))
    end

    return n1
end

local v54 = buffer.create(8)

local function fb(p9) -- line: 133
    -- upvalues: v54 (copy)
    buffer.writeu32(v54, 0, p9)

    return (buffer.readf32(v54, 0))
end

local to_bits = rt.to_bits

local function to_bits2(p10) -- line: 138
    -- upvalues: v54 (copy), to_bits (copy)
    if p10 ~= 0 and p10 > -1.1754943508222875E-38 and p10 < 1.1754943508222875E-38 then
        return to_bits(p10)
    end

    buffer.writef32(v54, 0, p10)

    return (buffer.readu32(v54, 0))
end

local function inverse_length_fast(p11) -- line: 149
    -- upvalues: estimate (copy)
    local v55 = estimate(p11)
    local v56 = v55 * 0.5 * (-p11 * (v55 * v55) + 1) + v55

    return v56 * 0.5 * (-p11 * (v56 * v56) + 1) + v56
end

local function face_normals(p12, p13, p14) -- line: 156
    local v58 = bit32.rshift(p12[36], 24)
    local v59

    if not (v58 >= 1) or not (v58 <= 3) then
        v59 = p14

        return v59
    end

    v59 = p14

    for i = v58, 1, -1 do
        local v60 = p13[v59 + 1]
        local v61 = i * 4
        local v62 = p12[v61 + 1]
        local v63 = p12[v61 + 2]
        local v64 = p12[v61 + 3]
        local v65 = p12[v61 + 4]

        v60[1] = v62
        v60[2] = v63
        v60[3] = v64
        v60[4] = v65
        v59 += 1
    end

    return v59
end

local function append_scalar(p15, p16, p17, p18, p19, p20) -- line: 175
    -- upvalues: v1 (copy), estimate (copy), v54 (copy), to_bits (copy)
    local v66 = p19[p20 + 1]
    local v67

    if p15 ~= 0 and p15 > -1.1754943508222875E-38 and p15 < 1.1754943508222875E-38 then
        v67 = to_bits(p15)
    else
        buffer.writef32(v54, 0, p15)
        v67 = buffer.readu32(v54, 0)
    end

    local v68

    if p16 ~= 0 and p16 > -1.1754943508222875E-38 and p16 < 1.1754943508222875E-38 then
        v68 = to_bits(p16)
    else
        buffer.writef32(v54, 0, p16)
        v68 = buffer.readu32(v54, 0)
    end

    local v69

    if p17 ~= 0 and p17 > -1.1754943508222875E-38 and p17 < 1.1754943508222875E-38 then
        v69 = to_bits(p17)
    else
        buffer.writef32(v54, 0, p17)
        v69 = buffer.readu32(v54, 0)
    end

    local v70

    if p18 ~= 0 and p18 > -1.1754943508222875E-38 and p18 < 1.1754943508222875E-38 then
        v70 = to_bits(p18)
    else
        buffer.writef32(v54, 0, p18)
        v70 = buffer.readu32(v54, 0)
    end

    v66[1] = v67
    v66[2] = v68
    v66[3] = v69
    v66[4] = v70

    local v71 = p15 * p15 + p16 * p16 + p17 * p17
    local v72

    if v71 ~= 0 and v71 > -1.1754943508222875E-38 and v71 < 1.1754943508222875E-38 then
        local v73 = math.abs(v71) * 7.1362384635298E+44
        local v74 = math.floor(v73)
        local v75 = v73 - v74

        v72 = (if v75 > 0.5 or v75 == 0.5 and v74 % 2 == 1 then v74 + 1 else v74) * 1.401298464324817E-45

        if v71 < 0 then
            v72 = -v72
        end
    else
        buffer.writef32(v1, 0, v71)
        v72 = buffer.readf32(v1, 0)
    end

    local v76

    if v72 == 0 then
        v76 = 0
    else
        local v77 = estimate(v72)
        local v78 = v77 * 0.5 * (-v72 * (v77 * v77) + 1) + v77

        v76 = v72 * (v78 * 0.5 * (-v72 * (v78 * v78) + 1) + v78)
    end

    if not (v76 > 1.1920928955078125E-07) then
        return p20
    end

    local v79 = p15 * p15 + p16 * p16 + p17 * p17
    local v80 = estimate(v79)
    local v81 = v80 * 0.5 * (-v79 * (v80 * v80) + 1) + v80
    local v82 = v81 * 0.5 * (-v79 * (v81 * v81) + 1) + v81
    local v83 = p15 * v82
    local v84

    if v83 == 0 then
        buffer.writef32(v54, 0, v83)
        v84 = buffer.readu32(v54, 0)
    elseif v83 > -1.1754943508222875E-38 and v83 < 1.1754943508222875E-38 then
        v84 = to_bits(v83)
    else
        buffer.writef32(v54, 0, v83)
        v84 = buffer.readu32(v54, 0)
    end

    local v85 = p16 * v82
    local v86

    if v85 ~= 0 and v85 > -1.1754943508222875E-38 and v85 < 1.1754943508222875E-38 then
        v86 = to_bits(v85)
    else
        buffer.writef32(v54, 0, v85)
        v86 = buffer.readu32(v54, 0)
    end

    local v87 = p17 * v82
    local v88

    if v87 ~= 0 and v87 > -1.1754943508222875E-38 and v87 < 1.1754943508222875E-38 then
        v88 = to_bits(v87)
    else
        buffer.writef32(v54, 0, v87)
        v88 = buffer.readu32(v54, 0)
    end

    local v89 = p18 * v82
    local v90

    if v89 ~= 0 and v89 > -1.1754943508222875E-38 and v89 < 1.1754943508222875E-38 then
        v90 = to_bits(v89)
    else
        buffer.writef32(v54, 0, v89)
        v90 = buffer.readu32(v54, 0)
    end

    v66[1] = v84
    v66[2] = v86
    v66[3] = v88
    v66[4] = v90

    return p20 + 1
end

function t1.separating_axis_candidates(p21, p22, p23) -- line: 194
    -- upvalues: v1 (copy), estimate (copy), v54 (copy), to_bits (copy), face_normals (copy), append_scalar (copy)
    local v92 = face_normals(p22, p23, (face_normals(p21, p23, 0)))
    local v95 = bit32.band(bit32.rshift(p21[36], 16), 255)
    local v94 = bit32.band(bit32.rshift(p22[36], 16), 255)

    if not (v95 <= 3 and v94 <= 3) then
        error("native GP contains at most three edges", 0)
    end

    local v97, v98, v99, v100, v101, v102, v103, v104, v105

    for i = 0, v95 - 1 do
        v103 = i * 4 + 16
        buffer.writeu32(v54, 0, p21[v103 + 1])

        local v107 = buffer.readf32(v54, 0)

        buffer.writeu32(v54, 0, p21[v103 + 2])

        local v108 = buffer.readf32(v54, 0)

        buffer.writeu32(v54, 0, p21[v103 + 3])

        local v109 = buffer.readf32(v54, 0)

        buffer.writeu32(v54, 0, p21[v103 + 4])

        local v110 = buffer.readf32(v54, 0)

        for j = 0, v94 - 1 do
            v103 = j * 4 + 16
            buffer.writeu32(v54, 0, p22[v103 + 1])

            local v112 = buffer.readf32(v54, 0)

            buffer.writeu32(v54, 0, p22[v103 + 2])

            local v113 = buffer.readf32(v54, 0)

            buffer.writeu32(v54, 0, p22[v103 + 3])

            local v114 = buffer.readf32(v54, 0)

            buffer.writeu32(v54, 0, p22[v103 + 4])

            local v115 = buffer.readf32(v54, 0)

            v103 = -v109 * v113 + v108 * v114

            local v111 = -v107 * v114 + v109 * v112

            v97 = -v108 * v112 + v107 * v113
            v98 = -v110 * v115 + v110 * v115
            v99 = v103 * v103 + v111 * v111 + v97 * v97

            local v116 = p23[v92 + 1]

            if v99 > 0.0010000000474974513 then
                local v117 = estimate(v99)

                v117 = v117 * 0.5 * (-v99 * (v117 * v117) + 1) + v117
                v117 = v117 * 0.5 * (-v99 * (v117 * v117) + 1) + v117
                v104 = v103 * v117

                if v104 == 0 then
                    buffer.writef32(v54, 0, v104)
                    v101 = buffer.readu32(v54, 0)
                elseif v104 > -1.1754943508222875E-38 and v104 < 1.1754943508222875E-38 then
                    v101 = to_bits(v104)
                else
                    buffer.writef32(v54, 0, v104)
                    v101 = buffer.readu32(v54, 0)
                end

                local v118 = v111 * v117

                if v118 ~= 0 and v118 > -1.1754943508222875E-38 and v118 < 1.1754943508222875E-38 then
                    v104 = to_bits(v118)
                else
                    buffer.writef32(v54, 0, v118)
                    v104 = buffer.readu32(v54, 0)
                end

                v100 = v97 * v117

                if v100 ~= 0 and v100 > -1.1754943508222875E-38 and v100 < 1.1754943508222875E-38 then
                    v118 = to_bits(v100)
                else
                    buffer.writef32(v54, 0, v100)
                    v118 = buffer.readu32(v54, 0)
                end

                v102 = v98 * v117

                if v102 ~= 0 and v102 > -1.1754943508222875E-38 and v102 < 1.1754943508222875E-38 then
                    v100 = to_bits(v102)
                else
                    buffer.writef32(v54, 0, v102)
                    v100 = buffer.readu32(v54, 0)
                end

                v116[1] = v101
                v116[2] = v104
                v116[3] = v118
                v116[4] = v100
                v92 += 1
            else
                if v103 ~= 0 and v103 > -1.1754943508222875E-38 and v103 < 1.1754943508222875E-38 then
                    v112 = to_bits(v103)
                else
                    buffer.writef32(v54, 0, v103)
                    v112 = buffer.readu32(v54, 0)
                end

                if v111 ~= 0 and v111 > -1.1754943508222875E-38 and v111 < 1.1754943508222875E-38 then
                    v105 = to_bits(v111)
                else
                    buffer.writef32(v54, 0, v111)
                    v105 = buffer.readu32(v54, 0)
                end

                if v97 ~= 0 and v97 > -1.1754943508222875E-38 and v97 < 1.1754943508222875E-38 then
                    v104 = to_bits(v97)
                else
                    buffer.writef32(v54, 0, v97)
                    v104 = buffer.readu32(v54, 0)
                end

                local v119

                if v98 ~= 0 and v98 > -1.1754943508222875E-38 and v98 < 1.1754943508222875E-38 then
                    v119 = to_bits(v98)
                else
                    buffer.writef32(v54, 0, v98)
                    v119 = buffer.readu32(v54, 0)
                end

                v116[1] = v112
                v116[2] = v105
                v116[3] = v104
                v116[4] = v119
            end
        end
    end

    local v120, v121, v122, v123, v124, v125, v126, v127, v128
    local v129 = v92

    if v95 == 1 and v94 == 1 then
        buffer.writeu32(v54, 0, p21[17])
        v120 = buffer.readf32(v54, 0)
        buffer.writeu32(v54, 0, p21[18])

        local v131 = buffer.readf32(v54, 0)

        buffer.writeu32(v54, 0, p21[19])

        local v132 = buffer.readf32(v54, 0)

        buffer.writeu32(v54, 0, p21[20])

        local v133 = buffer.readf32(v54, 0)

        v125 = p22[17]
        buffer.writeu32(v54, 0, v125)
        v121 = buffer.readf32(v54, 0)
        v125 = p22[18]
        buffer.writeu32(v54, 0, v125)
        v122 = buffer.readf32(v54, 0)
        v125 = p22[19]
        buffer.writeu32(v54, 0, v125)
        v123 = buffer.readf32(v54, 0)
        v125 = p22[20]
        buffer.writeu32(v54, 0, v125)
        v124 = buffer.readf32(v54, 0)
        v125 = -v132 * v122 + v131 * v123
        v126 = -v120 * v123 + v132 * v121
        v127 = -v131 * v121 + v120 * v122
        v128 = -v133 * v124 + v133 * v124
        v97 = v125 * v125 + v126 * v126 + v127 * v127

        local v134

        if v97 == 0 then
            buffer.writef32(v1, 0, v97)
            v134 = buffer.readf32(v1, 0)
        elseif v97 > -1.1754943508222875E-38 and v97 < 1.1754943508222875E-38 then
            v105 = math.abs(v97) * 7.1362384635298E+44
            v104 = math.floor(v105)

            local v135 = v105 - v104

            if v135 > 0.5 or v135 == 0.5 and v104 % 2 == 1 then
                v104 += 1
            end

            v134 = v104 * 1.401298464324817E-45

            if v97 < 0 then
                v134 = -v134
            end
        else
            buffer.writef32(v1, 0, v97)
            v134 = buffer.readf32(v1, 0)
        end

        if v134 == 0 then
            v97 = 0
        else
            v99 = estimate(v134)
            v99 = v99 * 0.5 * (-v134 * (v99 * v99) + 1) + v99
            v97 = v134 * (v99 * 0.5 * (-v134 * (v99 * v99) + 1) + v99)
        end

        if v97 > 1.1920928955078125E-07 then
            v98 = -v132 * v126 + v131 * v127

            local v136 = -v120 * v127 + v132 * v125
            local v137 = -v131 * v125 + v120 * v126
            local v138 = -v133 * v128 + v133 * v128
            local v139 = v98 * v98 + v136 * v136 + v137 * v137

            v101 = estimate(v139)

            local v140 = v101 * 0.5 * (-v139 * (v101 * v101) + 1) + v101

            v140 = v140 * 0.5 * (-v139 * (v140 * v140) + 1) + v140
            v139 = p23[v92 + 1]
            v100 = v98 * v140

            local v141

            if v100 == 0 then
                buffer.writef32(v54, 0, v100)
                v141 = buffer.readu32(v54, 0)
            elseif v100 > -1.1754943508222875E-38 and v100 < 1.1754943508222875E-38 then
                v141 = to_bits(v100)
            else
                buffer.writef32(v54, 0, v100)
                v141 = buffer.readu32(v54, 0)
            end

            v102 = v136 * v140

            if v102 ~= 0 and v102 > -1.1754943508222875E-38 and v102 < 1.1754943508222875E-38 then
                v100 = to_bits(v102)
            else
                buffer.writef32(v54, 0, v102)
                v100 = buffer.readu32(v54, 0)
            end

            local v142 = v137 * v140

            if v142 ~= 0 and v142 > -1.1754943508222875E-38 and v142 < 1.1754943508222875E-38 then
                v102 = to_bits(v142)
            else
                buffer.writef32(v54, 0, v142)
                v102 = buffer.readu32(v54, 0)
            end

            local v143 = v138 * v140

            if v143 ~= 0 and v143 > -1.1754943508222875E-38 and v143 < 1.1754943508222875E-38 then
                v142 = to_bits(v143)
            else
                buffer.writef32(v54, 0, v143)
                v142 = buffer.readu32(v54, 0)
            end

            v139[1] = v141
            v139[2] = v100
            v139[3] = v102
            v139[4] = v142
            v129 = v92 + 1
            v136 = -v123 * v126 + v122 * v127
            v137 = -v121 * v127 + v123 * v125
            v138 = -v122 * v125 + v121 * v126
            v140 = -v124 * v128 + v124 * v128
            v101 = v136 * v136 + v137 * v137 + v138 * v138
            v100 = estimate(v101)
            v139 = v100 * 0.5 * (-v101 * (v100 * v100) + 1) + v100
            v139 = v139 * 0.5 * (-v101 * (v139 * v139) + 1) + v139
            v101 = p23[v129 + 1]
            v141 = v136 * v139

            if v141 ~= 0 and v141 > -1.1754943508222875E-38 and v141 < 1.1754943508222875E-38 then
                v100 = to_bits(v141)
            else
                buffer.writef32(v54, 0, v141)
                v100 = buffer.readu32(v54, 0)
            end

            v142 = v137 * v139

            if v142 ~= 0 and v142 > -1.1754943508222875E-38 and v142 < 1.1754943508222875E-38 then
                v141 = to_bits(v142)
            else
                buffer.writef32(v54, 0, v142)
                v141 = buffer.readu32(v54, 0)
            end

            v143 = v138 * v139

            if v143 ~= 0 and v143 > -1.1754943508222875E-38 and v143 < 1.1754943508222875E-38 then
                v142 = to_bits(v143)
            else
                buffer.writef32(v54, 0, v143)
                v142 = buffer.readu32(v54, 0)
            end

            local v144 = v140 * v139

            if v144 ~= 0 and v144 > -1.1754943508222875E-38 and v144 < 1.1754943508222875E-38 then
                v143 = to_bits(v144)
            else
                buffer.writef32(v54, 0, v144)
                v143 = buffer.readu32(v54, 0)
            end

            v101[1] = v100
            v101[2] = v141
            v101[3] = v142
            v101[4] = v143
            v129 += 1
        end
    end

    if v129 ~= 0 then
        return v129
    end

    buffer.writeu32(v54, 0, p21[1])

    local v145 = buffer.readf32(v54, 0)

    buffer.writeu32(v54, 0, p22[1])

    local v93 = v145 - buffer.readf32(v54, 0)

    buffer.writeu32(v54, 0, p21[2])
    v145 = buffer.readf32(v54, 0)
    buffer.writeu32(v54, 0, p22[2])

    local v96 = v145 - buffer.readf32(v54, 0)

    buffer.writeu32(v54, 0, p21[3])
    v145 = buffer.readf32(v54, 0)
    buffer.writeu32(v54, 0, p22[3])

    local v147 = v145 - buffer.readf32(v54, 0)

    buffer.writeu32(v54, 0, p21[4])
    v145 = buffer.readf32(v54, 0)
    buffer.writeu32(v54, 0, p22[4])
    v103 = v145 - buffer.readf32(v54, 0)

    if v95 == 1 and v94 == 1 then
        v125 = p21[17]
        buffer.writeu32(v54, 0, v125)
        v121 = buffer.readf32(v54, 0)
        v125 = p21[18]
        buffer.writeu32(v54, 0, v125)
        v122 = buffer.readf32(v54, 0)
        v125 = p21[19]
        buffer.writeu32(v54, 0, v125)
        v123 = buffer.readf32(v54, 0)
        v125 = p21[20]
        buffer.writeu32(v54, 0, v125)
        v124 = buffer.readf32(v54, 0)
        v125 = -v147 * v122 + v96 * v123
        v126 = -v93 * v123 + v147 * v121
        v127 = -v96 * v121 + v93 * v122
        v128 = -v103 * v124 + v103 * v124
        v129 = append_scalar(-v127 * v122 + v126 * v123, -v125 * v123 + v127 * v121, -v126 * v121 + v125 * v122, -v128 * v124 + v128 * v124, p23, v129)
    end

    if v95 + v94 == 1 then
        local v148, v149, v150

        if v95 == 0 then
            v125 = p22[17]
            buffer.writeu32(v54, 0, v125)
            v148 = buffer.readf32(v54, 0)
            v125 = p22[18]
            buffer.writeu32(v54, 0, v125)
            v149 = buffer.readf32(v54, 0)
            v125 = p22[19]
            buffer.writeu32(v54, 0, v125)
            v150 = buffer.readf32(v54, 0)
            v125 = p22[20]
        else
            v125 = p21[17]
            buffer.writeu32(v54, 0, v125)
            v148 = buffer.readf32(v54, 0)
            v125 = p21[18]
            buffer.writeu32(v54, 0, v125)
            v149 = buffer.readf32(v54, 0)
            v125 = p21[19]
            buffer.writeu32(v54, 0, v125)
            v150 = buffer.readf32(v54, 0)
            v125 = p21[20]
        end

        buffer.writeu32(v54, 0, v125)

        local v151 = buffer.readf32(v54, 0)

        v125 = -v147 * v149 + v96 * v150
        v121 = -v93 * v150 + v147 * v148
        v127 = -v96 * v148 + v93 * v149
        v128 = -v103 * v151 + v103 * v151
        v129 = append_scalar(-v127 * v149 + v121 * v150, -v125 * v150 + v127 * v148, -v121 * v148 + v125 * v149, -v128 * v151 + v128 * v151, p23, v129)
    end

    if v129 == 0 then
        return (append_scalar(v93, v96, v147, v103, p23, v129))
    end

    return v129
end

function append(p24, p25, p26) -- line: 322
    -- upvalues: to_bits4 (copy), dot (ref), normalized (ref), length (ref)
    p25[p26 + 1] = to_bits4(p24)

    if length(p24) > 1.1920928955078125E-07 then
        p25[p26 + 1] = to_bits4(normalized(p24, dot(p24)))

        return p26 + 1
    end

    return p26
end

function load(p27, p28) -- line: 331
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p27[p28 + 1])

    local v153 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p27[p28 + 2])

    local v155 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p27[p28 + 3])

    local v157 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p27[p28 + 4])

    return {
        v153,
        v155,
        v157,
        (buffer.readf32(v1, 0))
    }
end

function sub(p29, p30) -- line: 340
    return {
        p29[1] - p30[1],
        p29[2] - p30[2],
        p29[3] - p30[3],
        p29[4] - p30[4]
    }
end

function cross(p31, p32) -- line: 344
    return {
        -p31[3] * p32[2] + p31[2] * p32[3],
        -p31[1] * p32[3] + p31[3] * p32[1],
        -p31[2] * p32[1] + p31[1] * p32[2],
        -p31[4] * p32[4] + p31[4] * p32[4]
    }
end

function dot(p33) -- line: 353
    return p33[1] * p33[1] + p33[2] * p33[2] + p33[3] * p33[3]
end

local function inverse_length(p34) -- line: 357
    -- upvalues: estimate (copy)
    local v159 = estimate(p34)
    local v160 = v159 * 0.5 * (-p34 * (v159 * v159) + 1) + v159

    return v160 * 0.5 * (-p34 * (v160 * v160) + 1) + v160
end

function normalized(p35, p36) -- line: 365
    -- upvalues: inverse_length (copy)
    local v161 = inverse_length(p36)

    return {
        p35[1] * v161,
        p35[2] * v161,
        p35[3] * v161,
        p35[4] * v161
    }
end

function length(p37) -- line: 370
    -- upvalues: v1 (copy), dot (ref), inverse_length (copy)
    local v162 = dot(p37)
    local v163

    if v162 ~= 0 and v162 > -1.1754943508222875E-38 and v162 < 1.1754943508222875E-38 then
        local v164 = math.abs(v162) * 7.1362384635298E+44
        local v165 = math.floor(v164)
        local v166 = v164 - v165

        v163 = (if v166 > 0.5 or v166 == 0.5 and v165 % 2 == 1 then v165 + 1 else v165) * 1.401298464324817E-45

        if v162 < 0 then
            v163 = -v163
        end
    else
        buffer.writef32(v1, 0, v162)
        v163 = buffer.readf32(v1, 0)
    end

    if v163 == 0 then
        return 0
    end

    return v163 * inverse_length(v163)
end

t1.append = append
t1.load = load
t1.sub = sub
t1.cross = cross
t1.dot = dot
t1.inverse_length = inverse_length
t1.normalized = normalized
t1.length = length

return t1
