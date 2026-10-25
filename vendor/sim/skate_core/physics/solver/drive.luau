-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/solver/joint_data")
local ConstraintGeometry, ReactionState, project_correction, publish_reactions = v1.ConstraintGeometry, v1.ReactionState, v1.project_correction, v1.publish_reactions
local read_column, write_column, xyz = v1.read_column, v1.write_column, v1.xyz
local t1 = {}

function t1.solve_reference(p1, p2, p3) -- line: 25
    -- upvalues: rt (copy), ConstraintGeometry (copy), ReactionState (copy), project_correction (copy), publish_reactions (copy), read_column (copy), write_column (copy), xyz (copy), t1 (copy)
    local v2 = ConstraintGeometry.decode(p1)
    local v3 = ReactionState.decode(p2)
    local v4 = ReactionState.decode(p3)
    local v5, v6 = ConstraintGeometry.relative_corrections(v2, v3, v4)
    local v7 = read_column(p1, 32)
    local v8 = read_column(p1, 48)
    local v9 = project_correction(v2.linear_projection, v5, v7)
    local v10 = project_correction(v2.angular_projection, v6, v8)
    local v11 = read_column(p1, 160)
    local v12 = read_column(p1, 176)
    local t2 = {
        read_column(p1, 96)[4],
        read_column(p1, 112)[4],
        v11[4]
    }
    local t3 = {
        read_column(p1, 128)[4],
        read_column(p1, 144)[4],
        v12[4]
    }
    local v13 = rt.copy(v7)
    local v14 = rt.copy(v8)

    for i = 0, 2 do
        local v15 = v9[i + 1] * v7[4] + v11[i + 1]
        local v16 = v10[i + 1] * v8[4] + v12[i + 1]

        v13[i + 1] = t1.symmetric_impulse_limit(v15, t2[i + 1])
        v14[i + 1] = t1.symmetric_impulse_limit(v16, t3[i + 1])
    end

    local v17 = xyz({
        v13[1] - v7[1],
        v13[2] - v7[2],
        v13[3] - v7[3],
        v13[4] - v7[4]
    })
    local v18 = xyz({
        v14[1] - v8[1],
        v14[2] - v8[2],
        v14[3] - v8[3],
        v14[4] - v8[4]
    })

    write_column(p1, 32, v13)
    write_column(p1, 48, v14)
    ConstraintGeometry.apply_impulse_changes(v2, v3, v4, v17, v18)
    publish_reactions(v3, v4, p2, p3)
end

local v19 = buffer.create(8)

local function fb(p4) -- line: 79
    -- upvalues: v19 (copy)
    buffer.writeu32(v19, 0, p4)

    return (buffer.readf32(v19, 0))
end

local to_bits = rt.to_bits

local function to_bits2(p5) -- line: 84
    -- upvalues: v19 (copy), to_bits (copy)
    if p5 ~= 0 and p5 > -1.1754943508222875E-38 and p5 < 1.1754943508222875E-38 then
        return to_bits(p5)
    end

    buffer.writef32(v19, 0, p5)

    return (buffer.readu32(v19, 0))
end

local relative_corrections_packed, apply_impulse_changes_packed, mirror = v1.relative_corrections_packed, v1.apply_impulse_changes_packed, v1.mirror

local function contact_store() -- line: 98
    -- upvalues: import (copy)
    return import("skate_core/physics/solver/contact").store
end

local function put(_, p7, p8, p9) -- line: 106
    -- upvalues: v19 (copy), to_bits (copy)
    if p9 ~= 0 and p9 > -1.1754943508222875E-38 and p9 < 1.1754943508222875E-38 then
        buffer.writeu32(v19, 0, to_bits(p9))
    else
        buffer.writef32(v19, 0, p9)
    end

    p7[p8] = buffer.readf32(v19, 0)
end

local function impulse_limit(p10, p11) -- line: 115
    local v20 = if p10 < p11 then p10 else p11
    local v21 = 0 - p11

    if v21 < v20 then
        return v20
    end

    return v21
end

function t1.solve_mirrored(_, p13, p14, p15, p16, p17) -- line: 126
    -- upvalues: v19 (copy), to_bits (copy), relative_corrections_packed (copy), apply_impulse_changes_packed (copy)
    local v22, v23, v24, v25, v26, v27 = relative_corrections_packed(p13, p15, p17)
    local v28 = p13[9]
    local v29 = p13[10]
    local v30 = p13[11]
    local v31 = p13[12]
    local v32 = p13[13]
    local v33 = p13[14]
    local v34 = p13[15]
    local v35 = p13[16]
    local v36 = p13[33] * v24 + (p13[25] * v23 + (p13[17] * v22 + v28))
    local v37 = p13[34] * v24 + (p13[26] * v23 + (p13[18] * v22 + v29))
    local v38 = p13[35] * v24 + (p13[27] * v23 + (p13[19] * v22 + v30))
    local v39 = p13[37] * v27 + (p13[29] * v26 + (p13[21] * v25 + v32))
    local v40 = p13[38] * v27 + (p13[30] * v26 + (p13[22] * v25 + v33))
    local v41 = p13[39] * v27 + (p13[31] * v26 + (p13[23] * v25 + v34))
    local v42 = v36 * v31 + p13[41]
    local v43 = p13[28]

    if not (v42 < v43) then
        v42 = v43
    end

    local v44 = 0 - v43

    if not (v44 < v42) then
        v42 = v44
    end

    local v45 = v39 * v35 + p13[45]
    local v46 = p13[36]

    if not (v45 < v46) then
        v45 = v46
    end

    local v47 = 0 - v46

    if not (v47 < v45) then
        v45 = v47
    end

    local v48 = v37 * v31 + p13[42]
    local v49 = p13[32]

    if not (v48 < v49) then
        v48 = v49
    end

    local v50 = 0 - v49

    if not (v50 < v48) then
        v48 = v50
    end

    local v51 = v40 * v35 + p13[46]
    local v52 = p13[40]

    if not (v51 < v52) then
        v51 = v52
    end

    local v53 = 0 - v52

    if not (v53 < v51) then
        v51 = v53
    end

    local v54 = v38 * v31 + p13[43]
    local v55 = p13[44]

    if not (v54 < v55) then
        v54 = v55
    end

    local v56 = 0 - v55

    if not (v56 < v54) then
        v54 = v56
    end

    local v57 = v41 * v35 + p13[47]
    local v58 = p13[48]

    if not (v57 < v58) then
        v57 = v58
    end

    local v59 = 0 - v58

    if not (v59 < v57) then
        v57 = v59
    end

    local v60 = v42 - v28
    local v61 = v48 - v29
    local v62 = v54 - v30
    local v63 = v45 - v32
    local v64 = v51 - v33
    local v65 = v57 - v34

    if v42 ~= 0 and v42 > -1.1754943508222875E-38 and v42 < 1.1754943508222875E-38 then
        buffer.writeu32(v19, 0, to_bits(v42))
    else
        buffer.writef32(v19, 0, v42)
    end

    p13[9] = buffer.readf32(v19, 0)

    if v48 ~= 0 and v48 > -1.1754943508222875E-38 and v48 < 1.1754943508222875E-38 then
        buffer.writeu32(v19, 0, to_bits(v48))
    else
        buffer.writef32(v19, 0, v48)
    end

    p13[10] = buffer.readf32(v19, 0)

    if v54 ~= 0 and v54 > -1.1754943508222875E-38 and v54 < 1.1754943508222875E-38 then
        buffer.writeu32(v19, 0, to_bits(v54))
    else
        buffer.writef32(v19, 0, v54)
    end

    p13[11] = buffer.readf32(v19, 0)

    if v31 ~= 0 and v31 > -1.1754943508222875E-38 and v31 < 1.1754943508222875E-38 then
        buffer.writeu32(v19, 0, to_bits(v31))
    else
        buffer.writef32(v19, 0, v31)
    end

    p13[12] = buffer.readf32(v19, 0)

    if v45 ~= 0 and v45 > -1.1754943508222875E-38 and v45 < 1.1754943508222875E-38 then
        buffer.writeu32(v19, 0, to_bits(v45))
    else
        buffer.writef32(v19, 0, v45)
    end

    p13[13] = buffer.readf32(v19, 0)

    if v51 ~= 0 and v51 > -1.1754943508222875E-38 and v51 < 1.1754943508222875E-38 then
        buffer.writeu32(v19, 0, to_bits(v51))
    else
        buffer.writef32(v19, 0, v51)
    end

    p13[14] = buffer.readf32(v19, 0)

    if v57 ~= 0 and v57 > -1.1754943508222875E-38 and v57 < 1.1754943508222875E-38 then
        buffer.writeu32(v19, 0, to_bits(v57))
    else
        buffer.writef32(v19, 0, v57)
    end

    p13[15] = buffer.readf32(v19, 0)

    if v35 ~= 0 and v35 > -1.1754943508222875E-38 and v35 < 1.1754943508222875E-38 then
        buffer.writeu32(v19, 0, to_bits(v35))
    else
        buffer.writef32(v19, 0, v35)
    end

    p13[16] = buffer.readf32(v19, 0)
    apply_impulse_changes_packed(p13, p14, p15, p16, p17, v60, v61, v62, v63, v64, v65)
end

function t1.solve_mirrored_xyz_r3(p18, p19, p20) -- line: 168
    -- upvalues: v19 (copy), to_bits (copy)
    local v66 = p19[9]
    local v67 = p19[10]
    local v68 = p19[11]
    local v69 = p20[9]
    local v70 = p20[10]
    local v71 = p20[11]
    local v72 = p18[1]
    local v73 = p18[2]
    local v74 = p18[3]
    local v75 = p18[5]
    local v76 = p18[6]
    local v77 = p18[7]
    local v78 = -v68 * v73 + (v67 * v74 + p19[1])
    local v79 = -v66 * v74 + (v68 * v72 + p19[2])
    local v80 = -v67 * v72 + (v66 * v73 + p19[3])
    local v81 = -v71 * v76 + (v70 * v77 + p20[1])
    local v82 = -v69 * v77 + (v71 * v75 + p20[2])
    local v83 = -v70 * v75 + (v69 * v76 + p20[3])
    local v84 = v81 - v78
    local v85 = v82 - v79
    local v86 = v83 - v80
    local v87 = v69 - v66
    local v88 = v70 - v67
    local v89 = v71 - v68
    local v90 = p18[9]
    local v91 = p18[10]
    local v92 = p18[11]
    local v93 = p18[12]
    local v94 = p18[13]
    local v95 = p18[14]
    local v96 = p18[15]
    local v97 = p18[16]
    local v98 = p18[33] * v86 + (p18[25] * v85 + (p18[17] * v84 + v90))
    local v99 = p18[34] * v86 + (p18[26] * v85 + (p18[18] * v84 + v91))
    local v100 = p18[35] * v86 + (p18[27] * v85 + (p18[19] * v84 + v92))
    local v101 = p18[37] * v89 + (p18[29] * v88 + (p18[21] * v87 + v94))
    local v102 = p18[38] * v89 + (p18[30] * v88 + (p18[22] * v87 + v95))
    local v103 = p18[39] * v89 + (p18[31] * v88 + (p18[23] * v87 + v96))
    local v104 = v98 * v93 + p18[41]
    local v105 = p18[28]

    if not (v104 < v105) then
        v104 = v105
    end

    local v106 = 0 - v105

    if not (v106 < v104) then
        v104 = v106
    end

    local v107 = v101 * v97 + p18[45]
    local v108 = p18[36]

    if not (v107 < v108) then
        v107 = v108
    end

    local v109 = 0 - v108

    if not (v109 < v107) then
        v107 = v109
    end

    local v110 = v99 * v93 + p18[42]
    local v111 = p18[32]

    if not (v110 < v111) then
        v110 = v111
    end

    local v112 = 0 - v111

    if not (v112 < v110) then
        v110 = v112
    end

    local v113 = v102 * v97 + p18[46]
    local v114 = p18[40]

    if not (v113 < v114) then
        v113 = v114
    end

    local v115 = 0 - v114

    if not (v115 < v113) then
        v113 = v115
    end

    local v116 = v100 * v93 + p18[43]
    local v117 = p18[44]

    if not (v116 < v117) then
        v116 = v117
    end

    local v118 = 0 - v117

    if not (v118 < v116) then
        v116 = v118
    end

    local v119 = v103 * v97 + p18[47]
    local v120 = p18[48]

    if not (v119 < v120) then
        v119 = v120
    end

    local v121 = 0 - v120

    if not (v121 < v119) then
        v119 = v121
    end

    local v122 = v104 - v90
    local v123 = v110 - v91
    local v124 = v116 - v92
    local v125 = v107 - v94
    local v126 = v113 - v95
    local v127 = v119 - v96

    if v104 ~= 0 and v104 > -1.1754943508222875E-38 and v104 < 1.1754943508222875E-38 then
        buffer.writeu32(v19, 0, to_bits(v104))
    else
        buffer.writef32(v19, 0, v104)
    end

    p18[9] = buffer.readf32(v19, 0)

    if v110 ~= 0 and v110 > -1.1754943508222875E-38 and v110 < 1.1754943508222875E-38 then
        buffer.writeu32(v19, 0, to_bits(v110))
    else
        buffer.writef32(v19, 0, v110)
    end

    p18[10] = buffer.readf32(v19, 0)

    if v116 ~= 0 and v116 > -1.1754943508222875E-38 and v116 < 1.1754943508222875E-38 then
        buffer.writeu32(v19, 0, to_bits(v116))
    else
        buffer.writef32(v19, 0, v116)
    end

    p18[11] = buffer.readf32(v19, 0)

    if v93 ~= 0 and v93 > -1.1754943508222875E-38 and v93 < 1.1754943508222875E-38 then
        buffer.writeu32(v19, 0, to_bits(v93))
    else
        buffer.writef32(v19, 0, v93)
    end

    p18[12] = buffer.readf32(v19, 0)

    if v107 ~= 0 and v107 > -1.1754943508222875E-38 and v107 < 1.1754943508222875E-38 then
        buffer.writeu32(v19, 0, to_bits(v107))
    else
        buffer.writef32(v19, 0, v107)
    end

    p18[13] = buffer.readf32(v19, 0)

    if v113 ~= 0 and v113 > -1.1754943508222875E-38 and v113 < 1.1754943508222875E-38 then
        buffer.writeu32(v19, 0, to_bits(v113))
    else
        buffer.writef32(v19, 0, v113)
    end

    p18[14] = buffer.readf32(v19, 0)

    if v119 ~= 0 and v119 > -1.1754943508222875E-38 and v119 < 1.1754943508222875E-38 then
        buffer.writeu32(v19, 0, to_bits(v119))
    else
        buffer.writef32(v19, 0, v119)
    end

    p18[15] = buffer.readf32(v19, 0)

    if v97 ~= 0 and v97 > -1.1754943508222875E-38 and v97 < 1.1754943508222875E-38 then
        buffer.writeu32(v19, 0, to_bits(v97))
    else
        buffer.writef32(v19, 0, v97)
    end

    p18[16] = buffer.readf32(v19, 0)

    local v128 = p18[57] * v124 + (p18[53] * v123 + (p18[49] * v122 + 0))
    local v129 = p18[58] * v124 + (p18[54] * v123 + (p18[50] * v122 + 0))
    local v130 = p18[59] * v124 + (p18[55] * v123 + (p18[51] * v122 + 0))
    local v131 = p18[69] * v127 + (p18[65] * v126 + (p18[61] * v125 + 0))
    local v132 = p18[70] * v127 + (p18[66] * v126 + (p18[62] * v125 + 0))
    local v133 = p18[71] * v127 + (p18[67] * v126 + (p18[63] * v125 + 0))
    local v134 = p18[1]
    local v135 = p18[2]
    local v136 = p18[3]
    local v137 = p18[5]
    local v138 = p18[6]
    local v139 = p18[7]
    local v140 = -v136 * v129 + (v135 * v130 + v131)
    local v141 = -v134 * v130 + (v136 * v128 + v132)
    local v142 = -v135 * v128 + (v134 * v129 + v133)
    local v143 = -v139 * v129 + (v138 * v130 + v131)
    local v144 = -v137 * v130 + (v139 * v128 + v132)
    local v145 = -v138 * v128 + (v137 * v129 + v133)
    local v146 = p18[76]
    local v147 = p18[88]
    local v148 = v128 * v146 + p19[1]
    local v149 = -v128 * v147 + p20[1]
    local v150 = v129 * v146 + p19[2]
    local v151 = -v129 * v147 + p20[2]
    local v152 = v130 * v146 + p19[3]
    local v153 = -v130 * v147 + p20[3]
    local v154 = p18[81] * v142 + (p18[77] * v141 + (p18[73] * v140 + p19[9]))
    local v155 = p18[82] * v142 + (p18[78] * v141 + (p18[74] * v140 + p19[10]))
    local v156 = p18[83] * v142 + (p18[79] * v141 + (p18[75] * v140 + p19[11]))
    local v157 = -p18[93] * v145 + (-p18[89] * v144 + (-p18[85] * v143 + p20[9]))
    local v158 = -p18[94] * v145 + (-p18[90] * v144 + (-p18[86] * v143 + p20[10]))
    local v159 = -p18[95] * v145 + (-p18[91] * v144 + (-p18[87] * v143 + p20[11]))

    if v148 ~= 0 and v148 > -1.1754943508222875E-38 and v148 < 1.1754943508222875E-38 then
        buffer.writeu32(v19, 0, to_bits(v148))
    else
        buffer.writef32(v19, 0, v148)
    end

    p19[1] = buffer.readf32(v19, 0)

    if v150 ~= 0 and v150 > -1.1754943508222875E-38 and v150 < 1.1754943508222875E-38 then
        buffer.writeu32(v19, 0, to_bits(v150))
    else
        buffer.writef32(v19, 0, v150)
    end

    p19[2] = buffer.readf32(v19, 0)

    if v152 ~= 0 and v152 > -1.1754943508222875E-38 and v152 < 1.1754943508222875E-38 then
        buffer.writeu32(v19, 0, to_bits(v152))
    else
        buffer.writef32(v19, 0, v152)
    end

    p19[3] = buffer.readf32(v19, 0)

    if v149 ~= 0 and v149 > -1.1754943508222875E-38 and v149 < 1.1754943508222875E-38 then
        buffer.writeu32(v19, 0, to_bits(v149))
    else
        buffer.writef32(v19, 0, v149)
    end

    p20[1] = buffer.readf32(v19, 0)

    if v151 ~= 0 and v151 > -1.1754943508222875E-38 and v151 < 1.1754943508222875E-38 then
        buffer.writeu32(v19, 0, to_bits(v151))
    else
        buffer.writef32(v19, 0, v151)
    end

    p20[2] = buffer.readf32(v19, 0)

    if v153 ~= 0 and v153 > -1.1754943508222875E-38 and v153 < 1.1754943508222875E-38 then
        buffer.writeu32(v19, 0, to_bits(v153))
    else
        buffer.writef32(v19, 0, v153)
    end

    p20[3] = buffer.readf32(v19, 0)

    if v154 ~= 0 and v154 > -1.1754943508222875E-38 and v154 < 1.1754943508222875E-38 then
        buffer.writeu32(v19, 0, to_bits(v154))
    else
        buffer.writef32(v19, 0, v154)
    end

    p19[9] = buffer.readf32(v19, 0)

    if v155 ~= 0 and v155 > -1.1754943508222875E-38 and v155 < 1.1754943508222875E-38 then
        buffer.writeu32(v19, 0, to_bits(v155))
    else
        buffer.writef32(v19, 0, v155)
    end

    p19[10] = buffer.readf32(v19, 0)

    if v156 ~= 0 and v156 > -1.1754943508222875E-38 and v156 < 1.1754943508222875E-38 then
        buffer.writeu32(v19, 0, to_bits(v156))
    else
        buffer.writef32(v19, 0, v156)
    end

    p19[11] = buffer.readf32(v19, 0)

    if v157 ~= 0 and v157 > -1.1754943508222875E-38 and v157 < 1.1754943508222875E-38 then
        buffer.writeu32(v19, 0, to_bits(v157))
    else
        buffer.writef32(v19, 0, v157)
    end

    p20[9] = buffer.readf32(v19, 0)

    if v158 ~= 0 and v158 > -1.1754943508222875E-38 and v158 < 1.1754943508222875E-38 then
        buffer.writeu32(v19, 0, to_bits(v158))
    else
        buffer.writef32(v19, 0, v158)
    end

    p20[10] = buffer.readf32(v19, 0)

    if v159 ~= 0 and v159 > -1.1754943508222875E-38 and v159 < 1.1754943508222875E-38 then
        buffer.writeu32(v19, 0, to_bits(v159))
    else
        buffer.writef32(v19, 0, v159)
    end

    p20[11] = buffer.readf32(v19, 0)
end

local create = vector.create

local function tiny(p21) -- line: 271
    -- upvalues: v19 (copy), to_bits (copy)
    buffer.writeu32(v19, 0, to_bits(p21))

    return (buffer.readf32(v19, 0))
end

function t1.solve_mirrored_xyz(p22, p23, p24) -- line: 275
    -- upvalues: v19 (copy), to_bits (copy), create (copy)
    local v160 = p23[9]
    local v161 = p23[10]
    local v162 = p23[11]
    local v163 = p24[9]
    local v164 = p24[10]
    local v165 = p24[11]
    local v166 = p22[1]
    local v167 = p22[2]
    local v168 = p22[3]
    local v169 = p22[5]
    local v170 = p22[6]
    local v171 = p22[7]
    local v172 = -v162 * v167 + (v161 * v168 + p23[1])
    local v173 = -v160 * v168 + (v162 * v166 + p23[2])
    local v174 = -v161 * v166 + (v160 * v167 + p23[3])
    local v175 = -v165 * v170 + (v164 * v171 + p24[1])
    local v176 = -v163 * v171 + (v165 * v169 + p24[2])
    local v177 = -v164 * v169 + (v163 * v170 + p24[3])
    local v178 = v175 - v172
    local v179 = v176 - v173
    local v180 = v177 - v174
    local v181 = v163 - v160
    local v182 = v164 - v161
    local v183 = v165 - v162
    local v184 = p22[9]
    local v185 = p22[10]
    local v186 = p22[11]
    local v187 = p22[12]
    local v188 = p22[13]
    local v189 = p22[14]
    local v190 = p22[15]
    local v191 = p22[16]
    local v192 = p22[33] * v180 + (p22[25] * v179 + (p22[17] * v178 + v184))
    local v193 = p22[34] * v180 + (p22[26] * v179 + (p22[18] * v178 + v185))
    local v194 = p22[35] * v180 + (p22[27] * v179 + (p22[19] * v178 + v186))
    local v195 = p22[37] * v183 + (p22[29] * v182 + (p22[21] * v181 + v188))
    local v196 = p22[38] * v183 + (p22[30] * v182 + (p22[22] * v181 + v189))
    local v197 = p22[39] * v183 + (p22[31] * v182 + (p22[23] * v181 + v190))
    local v198 = v192 * v187 + p22[41]
    local v199 = p22[28]

    if not (v198 < v199) then
        v198 = v199
    end

    local v200 = 0 - v199

    if not (v200 < v198) then
        v198 = v200
    end

    local v201 = v195 * v191 + p22[45]
    local v202 = p22[36]

    if not (v201 < v202) then
        v201 = v202
    end

    local v203 = 0 - v202

    if not (v203 < v201) then
        v201 = v203
    end

    local v204 = v193 * v187 + p22[42]
    local v205 = p22[32]

    if not (v204 < v205) then
        v204 = v205
    end

    local v206 = 0 - v205

    if not (v206 < v204) then
        v204 = v206
    end

    local v207 = v196 * v191 + p22[46]
    local v208 = p22[40]

    if not (v207 < v208) then
        v207 = v208
    end

    local v209 = 0 - v208

    if not (v209 < v207) then
        v207 = v209
    end

    local v210 = v194 * v187 + p22[43]
    local v211 = p22[44]

    if not (v210 < v211) then
        v210 = v211
    end

    local v212 = 0 - v211

    if not (v212 < v210) then
        v210 = v212
    end

    local v213 = v197 * v191 + p22[47]
    local v214 = p22[48]

    if not (v213 < v214) then
        v213 = v214
    end

    local v215 = 0 - v214

    if not (v215 < v213) then
        v213 = v215
    end

    local v216 = v198 - v184
    local v217 = v204 - v185
    local v218 = v210 - v186
    local v219 = v201 - v188
    local v220 = v207 - v189
    local v221 = v213 - v190
    local v222 = create(v198, v204, v210)
    local x, y, z = v222.x, v222.y, v222.z

    if v198 < 1.1754943508222875E-38 and v198 > -1.1754943508222875E-38 and v198 ~= 0 then
        buffer.writeu32(v19, 0, to_bits(v198))
        x = buffer.readf32(v19, 0)
    end

    if v204 < 1.1754943508222875E-38 and v204 > -1.1754943508222875E-38 and v204 ~= 0 then
        buffer.writeu32(v19, 0, to_bits(v204))
        y = buffer.readf32(v19, 0)
    end

    if v210 < 1.1754943508222875E-38 and v210 > -1.1754943508222875E-38 and v210 ~= 0 then
        buffer.writeu32(v19, 0, to_bits(v210))
        z = buffer.readf32(v19, 0)
    end

    p22[9] = x
    p22[10] = y
    p22[11] = z

    local v223 = create(v201, v207, v213)
    local x2, y2, z2 = v223.x, v223.y, v223.z

    if v201 < 1.1754943508222875E-38 and v201 > -1.1754943508222875E-38 and v201 ~= 0 then
        buffer.writeu32(v19, 0, to_bits(v201))
        x2 = buffer.readf32(v19, 0)
    end

    if v207 < 1.1754943508222875E-38 and v207 > -1.1754943508222875E-38 and v207 ~= 0 then
        buffer.writeu32(v19, 0, to_bits(v207))
        y2 = buffer.readf32(v19, 0)
    end

    if v213 < 1.1754943508222875E-38 and v213 > -1.1754943508222875E-38 and v213 ~= 0 then
        buffer.writeu32(v19, 0, to_bits(v213))
        z2 = buffer.readf32(v19, 0)
    end

    p22[13] = x2
    p22[14] = y2
    p22[15] = z2

    local v224 = p22[57] * v218 + (p22[53] * v217 + (p22[49] * v216 + 0))
    local v225 = p22[58] * v218 + (p22[54] * v217 + (p22[50] * v216 + 0))
    local v226 = p22[59] * v218 + (p22[55] * v217 + (p22[51] * v216 + 0))
    local v227 = p22[69] * v221 + (p22[65] * v220 + (p22[61] * v219 + 0))
    local v228 = p22[70] * v221 + (p22[66] * v220 + (p22[62] * v219 + 0))
    local v229 = p22[71] * v221 + (p22[67] * v220 + (p22[63] * v219 + 0))
    local v230 = p22[1]
    local v231 = p22[2]
    local v232 = p22[3]
    local v233 = p22[5]
    local v234 = p22[6]
    local v235 = p22[7]
    local v236 = -v232 * v225 + (v231 * v226 + v227)
    local v237 = -v230 * v226 + (v232 * v224 + v228)
    local v238 = -v231 * v224 + (v230 * v225 + v229)
    local v239 = -v235 * v225 + (v234 * v226 + v227)
    local v240 = -v233 * v226 + (v235 * v224 + v228)
    local v241 = -v234 * v224 + (v233 * v225 + v229)
    local v242 = p22[76]
    local v243 = p22[88]
    local v244 = v224 * v242 + p23[1]
    local v245 = -v224 * v243 + p24[1]
    local v246 = v225 * v242 + p23[2]
    local v247 = -v225 * v243 + p24[2]
    local v248 = v226 * v242 + p23[3]
    local v249 = -v226 * v243 + p24[3]
    local v250 = p22[81] * v238 + (p22[77] * v237 + (p22[73] * v236 + p23[9]))
    local v251 = p22[82] * v238 + (p22[78] * v237 + (p22[74] * v236 + p23[10]))
    local v252 = p22[83] * v238 + (p22[79] * v237 + (p22[75] * v236 + p23[11]))
    local v253 = -p22[93] * v241 + (-p22[89] * v240 + (-p22[85] * v239 + p24[9]))
    local v254 = -p22[94] * v241 + (-p22[90] * v240 + (-p22[86] * v239 + p24[10]))
    local v255 = -p22[95] * v241 + (-p22[91] * v240 + (-p22[87] * v239 + p24[11]))
    local v256 = create(v244, v246, v248)
    local x3, y3, z3 = v256.x, v256.y, v256.z

    if v244 < 1.1754943508222875E-38 and v244 > -1.1754943508222875E-38 and v244 ~= 0 then
        buffer.writeu32(v19, 0, to_bits(v244))
        x3 = buffer.readf32(v19, 0)
    end

    if v246 < 1.1754943508222875E-38 and v246 > -1.1754943508222875E-38 and v246 ~= 0 then
        buffer.writeu32(v19, 0, to_bits(v246))
        y3 = buffer.readf32(v19, 0)
    end

    if v248 < 1.1754943508222875E-38 and v248 > -1.1754943508222875E-38 and v248 ~= 0 then
        buffer.writeu32(v19, 0, to_bits(v248))
        z3 = buffer.readf32(v19, 0)
    end

    p23[1] = x3
    p23[2] = y3
    p23[3] = z3

    local v257 = create(v245, v247, v249)
    local x4, y4, z4 = v257.x, v257.y, v257.z

    if v245 < 1.1754943508222875E-38 and v245 > -1.1754943508222875E-38 and v245 ~= 0 then
        buffer.writeu32(v19, 0, to_bits(v245))
        x4 = buffer.readf32(v19, 0)
    end

    if v247 < 1.1754943508222875E-38 and v247 > -1.1754943508222875E-38 and v247 ~= 0 then
        buffer.writeu32(v19, 0, to_bits(v247))
        y4 = buffer.readf32(v19, 0)
    end

    if v249 < 1.1754943508222875E-38 and v249 > -1.1754943508222875E-38 and v249 ~= 0 then
        buffer.writeu32(v19, 0, to_bits(v249))
        z4 = buffer.readf32(v19, 0)
    end

    p24[1] = x4
    p24[2] = y4
    p24[3] = z4

    local v258 = create(v250, v251, v252)
    local x5, y5, z5 = v258.x, v258.y, v258.z

    if v250 < 1.1754943508222875E-38 and v250 > -1.1754943508222875E-38 and v250 ~= 0 then
        buffer.writeu32(v19, 0, to_bits(v250))
        x5 = buffer.readf32(v19, 0)
    end

    if v251 < 1.1754943508222875E-38 and v251 > -1.1754943508222875E-38 and v251 ~= 0 then
        buffer.writeu32(v19, 0, to_bits(v251))
        y5 = buffer.readf32(v19, 0)
    end

    if v252 < 1.1754943508222875E-38 and v252 > -1.1754943508222875E-38 and v252 ~= 0 then
        buffer.writeu32(v19, 0, to_bits(v252))
        z5 = buffer.readf32(v19, 0)
    end

    p23[9] = x5
    p23[10] = y5
    p23[11] = z5

    local v259 = create(v253, v254, v255)
    local x6, y6, z6 = v259.x, v259.y, v259.z

    if v253 < 1.1754943508222875E-38 and v253 > -1.1754943508222875E-38 and v253 ~= 0 then
        buffer.writeu32(v19, 0, to_bits(v253))
        x6 = buffer.readf32(v19, 0)
    end

    if v254 < 1.1754943508222875E-38 and v254 > -1.1754943508222875E-38 and v254 ~= 0 then
        buffer.writeu32(v19, 0, to_bits(v254))
        y6 = buffer.readf32(v19, 0)
    end

    if v255 < 1.1754943508222875E-38 and v255 > -1.1754943508222875E-38 and v255 ~= 0 then
        buffer.writeu32(v19, 0, to_bits(v255))
        z6 = buffer.readf32(v19, 0)
    end

    p24[9] = x6
    p24[10] = y6
    p24[11] = z6
end

local function solve_w3(p25, p26, p27) -- line: 461
    -- upvalues: v19 (copy), to_bits (copy), create (copy)
    local v260 = p26[1]
    local v261 = p26[2]
    local v262 = p26[3]
    local v263 = p26[9]
    local v264 = p26[10]
    local v265 = p26[11]
    local v266 = p27[1]
    local v267 = p27[2]
    local v268 = p27[3]
    local v269 = p27[9]
    local v270 = p27[10]
    local v271 = p27[11]
    local v272 = p25[1]
    local v273 = p25[2]
    local v274 = p25[3]
    local v275 = p25[5]
    local v276 = p25[6]
    local v277 = p25[7]
    local v278 = -v265 * v273 + (v264 * v274 + v260)
    local v279 = -v263 * v274 + (v265 * v272 + v261)
    local v280 = -v264 * v272 + (v263 * v273 + v262)
    local v281 = -v271 * v276 + (v270 * v277 + v266)
    local v282 = -v269 * v277 + (v271 * v275 + v267)
    local v283 = -v270 * v275 + (v269 * v276 + v268)
    local v284 = v281 - v278
    local v285 = v282 - v279
    local v286 = v283 - v280
    local v287 = v269 - v263
    local v288 = v270 - v264
    local v289 = v271 - v265
    local v290 = p25[9]
    local v291 = p25[10]
    local v292 = p25[11]
    local v293 = p25[12]
    local v294 = p25[13]
    local v295 = p25[14]
    local v296 = p25[15]
    local v297 = p25[16]
    local v298 = p25[33] * v286 + (p25[25] * v285 + (p25[17] * v284 + v290))
    local v299 = p25[34] * v286 + (p25[26] * v285 + (p25[18] * v284 + v291))
    local v300 = p25[35] * v286 + (p25[27] * v285 + (p25[19] * v284 + v292))
    local v301 = p25[37] * v289 + (p25[29] * v288 + (p25[21] * v287 + v294))
    local v302 = p25[38] * v289 + (p25[30] * v288 + (p25[22] * v287 + v295))
    local v303 = p25[39] * v289 + (p25[31] * v288 + (p25[23] * v287 + v296))
    local v304 = v298 * v293 + p25[41]
    local v305 = p25[28]

    if not (v304 < v305) then
        v304 = v305
    end

    local v306 = 0 - v305

    if not (v306 < v304) then
        v304 = v306
    end

    local v307 = v301 * v297 + p25[45]
    local v308 = p25[36]

    if not (v307 < v308) then
        v307 = v308
    end

    local v309 = 0 - v308

    if not (v309 < v307) then
        v307 = v309
    end

    local v310 = v299 * v293 + p25[42]
    local v311 = p25[32]

    if not (v310 < v311) then
        v310 = v311
    end

    local v312 = 0 - v311

    if not (v312 < v310) then
        v310 = v312
    end

    local v313 = v302 * v297 + p25[46]
    local v314 = p25[40]

    if not (v313 < v314) then
        v313 = v314
    end

    local v315 = 0 - v314

    if not (v315 < v313) then
        v313 = v315
    end

    local v316 = v300 * v293 + p25[43]
    local v317 = p25[44]

    if not (v316 < v317) then
        v316 = v317
    end

    local v318 = 0 - v317

    if not (v318 < v316) then
        v316 = v318
    end

    local v319 = v303 * v297 + p25[47]
    local v320 = p25[48]

    if not (v319 < v320) then
        v319 = v320
    end

    local v321 = 0 - v320

    if not (v321 < v319) then
        v319 = v321
    end

    local v322 = v304 - v290
    local v323 = v310 - v291
    local v324 = v316 - v292
    local v325 = v307 - v294
    local v326 = v313 - v295
    local v327 = v319 - v296
    local v328 = create(v304, v310, v316)
    local x, y, z = v328.x, v328.y, v328.z

    if v304 < 1.1754943508222875E-38 and v304 > -1.1754943508222875E-38 and v304 ~= 0 then
        buffer.writeu32(v19, 0, to_bits(v304))
        x = buffer.readf32(v19, 0)
    end

    if v310 < 1.1754943508222875E-38 and v310 > -1.1754943508222875E-38 and v310 ~= 0 then
        buffer.writeu32(v19, 0, to_bits(v310))
        y = buffer.readf32(v19, 0)
    end

    if v316 < 1.1754943508222875E-38 and v316 > -1.1754943508222875E-38 and v316 ~= 0 then
        buffer.writeu32(v19, 0, to_bits(v316))
        z = buffer.readf32(v19, 0)
    end

    p25[9] = x
    p25[10] = y
    p25[11] = z

    local v329 = create(v307, v313, v319)
    local x2, y2, z2 = v329.x, v329.y, v329.z

    if v307 < 1.1754943508222875E-38 and v307 > -1.1754943508222875E-38 and v307 ~= 0 then
        buffer.writeu32(v19, 0, to_bits(v307))
        x2 = buffer.readf32(v19, 0)
    end

    if v313 < 1.1754943508222875E-38 and v313 > -1.1754943508222875E-38 and v313 ~= 0 then
        buffer.writeu32(v19, 0, to_bits(v313))
        y2 = buffer.readf32(v19, 0)
    end

    if v319 < 1.1754943508222875E-38 and v319 > -1.1754943508222875E-38 and v319 ~= 0 then
        buffer.writeu32(v19, 0, to_bits(v319))
        z2 = buffer.readf32(v19, 0)
    end

    p25[13] = x2
    p25[14] = y2
    p25[15] = z2

    local v330 = p25[57] * v324 + (p25[53] * v323 + (p25[49] * v322 + 0))
    local v331 = p25[58] * v324 + (p25[54] * v323 + (p25[50] * v322 + 0))
    local v332 = p25[59] * v324 + (p25[55] * v323 + (p25[51] * v322 + 0))
    local v333 = p25[69] * v327 + (p25[65] * v326 + (p25[61] * v325 + 0))
    local v334 = p25[70] * v327 + (p25[66] * v326 + (p25[62] * v325 + 0))
    local v335 = p25[71] * v327 + (p25[67] * v326 + (p25[63] * v325 + 0))
    local v336 = -v274 * v331 + (v273 * v332 + v333)
    local v337 = -v272 * v332 + (v274 * v330 + v334)
    local v338 = -v273 * v330 + (v272 * v331 + v335)
    local v339 = -v277 * v331 + (v276 * v332 + v333)
    local v340 = -v275 * v332 + (v277 * v330 + v334)
    local v341 = -v276 * v330 + (v275 * v331 + v335)
    local v342 = p25[76]
    local v343 = p25[88]
    local v344 = v330 * v342 + v260
    local v345 = -v330 * v343 + v266
    local v346 = v331 * v342 + v261
    local v347 = -v331 * v343 + v267
    local v348 = v332 * v342 + v262
    local v349 = -v332 * v343 + v268
    local v350 = p25[81] * v338 + (p25[77] * v337 + (p25[73] * v336 + v263))
    local v351 = p25[82] * v338 + (p25[78] * v337 + (p25[74] * v336 + v264))
    local v352 = p25[83] * v338 + (p25[79] * v337 + (p25[75] * v336 + v265))
    local v353 = p25[103] * v341 + (p25[100] * v340 + (p25[97] * v339 + v269))
    local v354 = p25[104] * v341 + (p25[101] * v340 + (p25[98] * v339 + v270))
    local v355 = p25[105] * v341 + (p25[102] * v340 + (p25[99] * v339 + v271))
    local v356 = create(v344, v346, v348)
    local x3, y3, z3 = v356.x, v356.y, v356.z

    if v344 < 1.1754943508222875E-38 and v344 > -1.1754943508222875E-38 and v344 ~= 0 then
        buffer.writeu32(v19, 0, to_bits(v344))
        x3 = buffer.readf32(v19, 0)
    end

    if v346 < 1.1754943508222875E-38 and v346 > -1.1754943508222875E-38 and v346 ~= 0 then
        buffer.writeu32(v19, 0, to_bits(v346))
        y3 = buffer.readf32(v19, 0)
    end

    if v348 < 1.1754943508222875E-38 and v348 > -1.1754943508222875E-38 and v348 ~= 0 then
        buffer.writeu32(v19, 0, to_bits(v348))
        z3 = buffer.readf32(v19, 0)
    end

    p26[1] = x3
    p26[2] = y3
    p26[3] = z3

    local v357 = create(v345, v347, v349)
    local x4, y4, z4 = v357.x, v357.y, v357.z

    if v345 < 1.1754943508222875E-38 and v345 > -1.1754943508222875E-38 and v345 ~= 0 then
        buffer.writeu32(v19, 0, to_bits(v345))
        x4 = buffer.readf32(v19, 0)
    end

    if v347 < 1.1754943508222875E-38 and v347 > -1.1754943508222875E-38 and v347 ~= 0 then
        buffer.writeu32(v19, 0, to_bits(v347))
        y4 = buffer.readf32(v19, 0)
    end

    if v349 < 1.1754943508222875E-38 and v349 > -1.1754943508222875E-38 and v349 ~= 0 then
        buffer.writeu32(v19, 0, to_bits(v349))
        z4 = buffer.readf32(v19, 0)
    end

    p27[1] = x4
    p27[2] = y4
    p27[3] = z4

    local v358 = create(v350, v351, v352)
    local x5, y5, z5 = v358.x, v358.y, v358.z

    if v350 < 1.1754943508222875E-38 and v350 > -1.1754943508222875E-38 and v350 ~= 0 then
        buffer.writeu32(v19, 0, to_bits(v350))
        x5 = buffer.readf32(v19, 0)
    end

    if v351 < 1.1754943508222875E-38 and v351 > -1.1754943508222875E-38 and v351 ~= 0 then
        buffer.writeu32(v19, 0, to_bits(v351))
        y5 = buffer.readf32(v19, 0)
    end

    if v352 < 1.1754943508222875E-38 and v352 > -1.1754943508222875E-38 and v352 ~= 0 then
        buffer.writeu32(v19, 0, to_bits(v352))
        z5 = buffer.readf32(v19, 0)
    end

    p26[9] = x5
    p26[10] = y5
    p26[11] = z5

    local v359 = create(v353, v354, v355)
    local x6, y6, z6 = v359.x, v359.y, v359.z

    if v353 < 1.1754943508222875E-38 and v353 > -1.1754943508222875E-38 and v353 ~= 0 then
        buffer.writeu32(v19, 0, to_bits(v353))
        x6 = buffer.readf32(v19, 0)
    end

    if v354 < 1.1754943508222875E-38 and v354 > -1.1754943508222875E-38 and v354 ~= 0 then
        buffer.writeu32(v19, 0, to_bits(v354))
        y6 = buffer.readf32(v19, 0)
    end

    if v355 < 1.1754943508222875E-38 and v355 > -1.1754943508222875E-38 and v355 ~= 0 then
        buffer.writeu32(v19, 0, to_bits(v355))
        z6 = buffer.readf32(v19, 0)
    end

    p27[9] = x6
    p27[10] = y6
    p27[11] = z6
end

t1.solve_w3 = solve_w3

local function solve_b3(p28, p29, p30) -- line: 617
    -- upvalues: v19 (copy), to_bits (copy), create (copy)
    local v360 = p29[1]
    local v361 = p29[2]
    local v362 = p29[3]
    local v363 = p29[9]
    local v364 = p29[10]
    local v365 = p29[11]
    local v366 = p30[1]
    local v367 = p30[2]
    local v368 = p30[3]
    local v369 = p30[9]
    local v370 = p30[10]
    local v371 = p30[11]
    local v372 = p28[1]
    local v373 = p28[2]
    local v374 = p28[3]
    local v375 = p28[5]
    local v376 = p28[6]
    local v377 = p28[7]
    local v378 = -v365 * v373 + (v364 * v374 + v360)
    local v379 = -v363 * v374 + (v365 * v372 + v361)
    local v380 = -v364 * v372 + (v363 * v373 + v362)
    local v381 = -v371 * v376 + (v370 * v377 + v366)
    local v382 = -v369 * v377 + (v371 * v375 + v367)
    local v383 = -v370 * v375 + (v369 * v376 + v368)
    local v384 = v381 - v378
    local v385 = v382 - v379
    local v386 = v383 - v380
    local v387 = v369 - v363
    local v388 = v370 - v364
    local v389 = v371 - v365
    local v390 = p28[9]
    local v391 = p28[10]
    local v392 = p28[11]
    local v393 = p28[12]
    local v394 = p28[13]
    local v395 = p28[14]
    local v396 = p28[15]
    local v397 = p28[16]

    v383 = p28[33] * v386 + (p28[25] * v385 + (p28[17] * v384 + v390))
    v382 = p28[34] * v386 + (p28[26] * v385 + (p28[18] * v384 + v391))
    v381 = p28[35] * v386 + (p28[27] * v385 + (p28[19] * v384 + v392))
    v386 = p28[37] * v389 + (p28[29] * v388 + (p28[21] * v387 + v394))
    v385 = p28[38] * v389 + (p28[30] * v388 + (p28[22] * v387 + v395))
    v384 = p28[39] * v389 + (p28[31] * v388 + (p28[23] * v387 + v396))

    local v398 = v383 * v393 + p28[41]
    local v399 = p28[28]

    if not (v398 < v399) then
        v398 = v399
    end

    v387 = 0 - v399

    if not (v387 < v398) then
        v398 = v387
    end

    local v400 = v386 * v397 + p28[45]

    v399 = p28[36]

    if not (v400 < v399) then
        v400 = v399
    end

    v379 = 0 - v399

    if not (v379 < v400) then
        v400 = v379
    end

    local v401 = v382 * v393 + p28[42]

    v399 = p28[32]

    if not (v401 < v399) then
        v401 = v399
    end

    local v402 = 0 - v399

    if not (v402 < v401) then
        v401 = v402
    end

    local v403 = v385 * v397 + p28[46]

    v399 = p28[40]

    if not (v403 < v399) then
        v403 = v399
    end

    local v404 = 0 - v399

    if not (v404 < v403) then
        v403 = v404
    end

    local v405 = v381 * v393 + p28[43]

    v399 = p28[44]

    if not (v405 < v399) then
        v405 = v399
    end

    v404 = 0 - v399

    if not (v404 < v405) then
        v405 = v404
    end

    local v406 = v384 * v397 + p28[47]

    v399 = p28[48]

    if not (v406 < v399) then
        v406 = v399
    end

    v402 = 0 - v399

    if not (v402 < v406) then
        v406 = v402
    end

    local v407 = v398 - v390

    v399 = v401 - v391
    v402 = v405 - v392
    v404 = v400 - v394

    local v408 = v403 - v395
    local v409 = v406 - v396
    local v410 = create(v398, v401, v405)
    local x, y, z = v410.x, v410.y, v410.z
    local v411 = x
    local v412 = y
    local v413 = z

    if x == 0 or y == 0 or z == 0 then
        if v398 < 1.1754943508222875E-38 and v398 > -1.1754943508222875E-38 and v398 ~= 0 then
            buffer.writeu32(v19, 0, to_bits(v398))
            v411 = buffer.readf32(v19, 0)
        end

        if v401 < 1.1754943508222875E-38 and v401 > -1.1754943508222875E-38 and v401 ~= 0 then
            buffer.writeu32(v19, 0, to_bits(v401))
            v412 = buffer.readf32(v19, 0)
        end

        if v405 < 1.1754943508222875E-38 and v405 > -1.1754943508222875E-38 and v405 ~= 0 then
            buffer.writeu32(v19, 0, to_bits(v405))
            v413 = buffer.readf32(v19, 0)
        end
    end

    p28[9] = v411
    p28[10] = v412
    p28[11] = v413
    x = create(v400, v403, v406)
    v411 = x.x
    v412 = x.y
    v413 = x.z

    local v414 = v411
    local v415 = v412
    local v416 = v413

    if v411 == 0 or v412 == 0 or v413 == 0 then
        if v400 < 1.1754943508222875E-38 and v400 > -1.1754943508222875E-38 and v400 ~= 0 then
            buffer.writeu32(v19, 0, to_bits(v400))
            v414 = buffer.readf32(v19, 0)
        end

        if v403 < 1.1754943508222875E-38 and v403 > -1.1754943508222875E-38 and v403 ~= 0 then
            buffer.writeu32(v19, 0, to_bits(v403))
            v415 = buffer.readf32(v19, 0)
        end

        if v406 < 1.1754943508222875E-38 and v406 > -1.1754943508222875E-38 and v406 ~= 0 then
            buffer.writeu32(v19, 0, to_bits(v406))
            v416 = buffer.readf32(v19, 0)
        end
    end

    p28[13] = v414
    p28[14] = v415
    p28[15] = v416
    v395 = p28[57] * v402 + (p28[53] * v399 + (p28[49] * v407 + 0))
    v394 = p28[58] * v402 + (p28[54] * v399 + (p28[50] * v407 + 0))
    v393 = p28[59] * v402 + (p28[55] * v399 + (p28[51] * v407 + 0))
    v402 = p28[69] * v409 + (p28[65] * v408 + (p28[61] * v404 + 0))
    v399 = p28[70] * v409 + (p28[66] * v408 + (p28[62] * v404 + 0))
    v400 = p28[71] * v409 + (p28[67] * v408 + (p28[63] * v404 + 0))
    v409 = -v374 * v394 + (v373 * v393 + v402)
    v408 = -v372 * v393 + (v374 * v395 + v399)
    v404 = -v373 * v395 + (v372 * v394 + v400)
    v392 = -v377 * v394 + (v376 * v393 + v402)
    v402 = -v375 * v393 + (v377 * v395 + v399)
    v399 = -v376 * v395 + (v375 * v394 + v400)
    v400 = p28[76]
    v391 = p28[88]
    v390 = v395 * v400 + v360
    v389 = -v395 * v391 + v366
    v395 = v394 * v400 + v361
    v386 = -v394 * v391 + v367
    v394 = v393 * v400 + v362
    v400 = -v393 * v391 + v368
    v393 = p28[81] * v404 + (p28[77] * v408 + (p28[73] * v409 + v363))
    v391 = p28[82] * v404 + (p28[78] * v408 + (p28[74] * v409 + v364))
    v385 = p28[83] * v404 + (p28[79] * v408 + (p28[75] * v409 + v365))
    v409 = p28[103] * v399 + (p28[100] * v402 + (p28[97] * v392 + v369))
    v408 = p28[104] * v399 + (p28[101] * v402 + (p28[98] * v392 + v370))
    v404 = p28[105] * v399 + (p28[102] * v402 + (p28[99] * v392 + v371))
    v411 = create(v390, v395, v394)
    v414 = v411.x
    v415 = v411.y
    v416 = v411.z

    local v417 = v414
    local v418 = v415
    local v419 = v416

    if v414 == 0 or v415 == 0 or v416 == 0 then
        if v390 < 1.1754943508222875E-38 and v390 > -1.1754943508222875E-38 and v390 ~= 0 then
            buffer.writeu32(v19, 0, to_bits(v390))
            v417 = buffer.readf32(v19, 0)
        end

        if v395 < 1.1754943508222875E-38 and v395 > -1.1754943508222875E-38 and v395 ~= 0 then
            buffer.writeu32(v19, 0, to_bits(v395))
            v418 = buffer.readf32(v19, 0)
        end

        if v394 < 1.1754943508222875E-38 and v394 > -1.1754943508222875E-38 and v394 ~= 0 then
            buffer.writeu32(v19, 0, to_bits(v394))
            v419 = buffer.readf32(v19, 0)
        end
    end

    p29[1] = v417
    p29[2] = v418
    p29[3] = v419
    v414 = create(v389, v386, v400)
    v417 = v414.x
    v418 = v414.y
    v419 = v414.z

    local v420 = v417
    local v421 = v418
    local v422 = v419

    if v417 == 0 or v418 == 0 or v419 == 0 then
        if v389 < 1.1754943508222875E-38 and v389 > -1.1754943508222875E-38 and v389 ~= 0 then
            buffer.writeu32(v19, 0, to_bits(v389))
            v420 = buffer.readf32(v19, 0)
        end

        if v386 < 1.1754943508222875E-38 and v386 > -1.1754943508222875E-38 and v386 ~= 0 then
            buffer.writeu32(v19, 0, to_bits(v386))
            v421 = buffer.readf32(v19, 0)
        end

        if v400 < 1.1754943508222875E-38 and v400 > -1.1754943508222875E-38 and v400 ~= 0 then
            buffer.writeu32(v19, 0, to_bits(v400))
            v422 = buffer.readf32(v19, 0)
        end
    end

    p30[1] = v420
    p30[2] = v421
    p30[3] = v422
    v417 = create(v393, v391, v385)
    v420 = v417.x
    v421 = v417.y
    v422 = v417.z

    local v423 = v420
    local v424 = v421
    local v425 = v422

    if v420 == 0 or v421 == 0 or v422 == 0 then
        if v393 < 1.1754943508222875E-38 and v393 > -1.1754943508222875E-38 and v393 ~= 0 then
            buffer.writeu32(v19, 0, to_bits(v393))
            v423 = buffer.readf32(v19, 0)
        end

        if v391 < 1.1754943508222875E-38 and v391 > -1.1754943508222875E-38 and v391 ~= 0 then
            buffer.writeu32(v19, 0, to_bits(v391))
            v424 = buffer.readf32(v19, 0)
        end

        if v385 < 1.1754943508222875E-38 and v385 > -1.1754943508222875E-38 and v385 ~= 0 then
            buffer.writeu32(v19, 0, to_bits(v385))
            v425 = buffer.readf32(v19, 0)
        end
    end

    p29[9] = v423
    p29[10] = v424
    p29[11] = v425
    v420 = create(v409, v408, v404)
    v423 = v420.x
    v424 = v420.y
    v425 = v420.z

    local v426 = v423
    local v427 = v424
    local v428 = v425

    if v423 == 0 or v424 == 0 or v425 == 0 then
        if v409 < 1.1754943508222875E-38 and v409 > -1.1754943508222875E-38 and v409 ~= 0 then
            buffer.writeu32(v19, 0, to_bits(v409))
            v426 = buffer.readf32(v19, 0)
        end

        if v408 < 1.1754943508222875E-38 and v408 > -1.1754943508222875E-38 and v408 ~= 0 then
            buffer.writeu32(v19, 0, to_bits(v408))
            v427 = buffer.readf32(v19, 0)
        end

        if v404 < 1.1754943508222875E-38 and v404 > -1.1754943508222875E-38 and v404 ~= 0 then
            buffer.writeu32(v19, 0, to_bits(v404))
            v428 = buffer.readf32(v19, 0)
        end
    end

    p30[9] = v426
    p30[10] = v427
    p30[11] = v428
end

t1.solve_b3 = solve_b3

function t1.solve_w3_angular(p31, p32, p33) -- line: 786
    -- upvalues: v19 (copy), to_bits (copy), create (copy)
    local v429 = p32[9]
    local v430 = p32[10]
    local v431 = p32[11]
    local v432 = p33[9]
    local v433 = p33[10]
    local v434 = p33[11]
    local v435 = v432 - v429
    local v436 = v433 - v430
    local v437 = v434 - v431
    local v438 = p31[13]
    local v439 = p31[14]
    local v440 = p31[15]
    local v441 = p31[16]
    local v442 = p31[37] * v437 + (p31[29] * v436 + (p31[21] * v435 + v438))
    local v443 = p31[38] * v437 + (p31[30] * v436 + (p31[22] * v435 + v439))
    local v444 = p31[39] * v437 + (p31[31] * v436 + (p31[23] * v435 + v440))
    local v445 = v442 * v441 + p31[45]
    local v446 = p31[36]

    if not (v445 < v446) then
        v445 = v446
    end

    local v447 = 0 - v446

    if not (v447 < v445) then
        v445 = v447
    end

    local v448 = v443 * v441 + p31[46]
    local v449 = p31[40]

    if not (v448 < v449) then
        v448 = v449
    end

    local v450 = 0 - v449

    if not (v450 < v448) then
        v448 = v450
    end

    local v451 = v444 * v441 + p31[47]
    local v452 = p31[48]

    if not (v451 < v452) then
        v451 = v452
    end

    local v453 = 0 - v452

    if not (v453 < v451) then
        v451 = v453
    end

    local v454 = v445 - v438
    local v455 = v448 - v439
    local v456 = v451 - v440
    local v457 = create(v445, v448, v451)
    local x, y, z = v457.x, v457.y, v457.z

    if v445 < 1.1754943508222875E-38 and v445 > -1.1754943508222875E-38 and v445 ~= 0 then
        buffer.writeu32(v19, 0, to_bits(v445))
        x = buffer.readf32(v19, 0)
    end

    if v448 < 1.1754943508222875E-38 and v448 > -1.1754943508222875E-38 and v448 ~= 0 then
        buffer.writeu32(v19, 0, to_bits(v448))
        y = buffer.readf32(v19, 0)
    end

    if v451 < 1.1754943508222875E-38 and v451 > -1.1754943508222875E-38 and v451 ~= 0 then
        buffer.writeu32(v19, 0, to_bits(v451))
        z = buffer.readf32(v19, 0)
    end

    p31[13] = x
    p31[14] = y
    p31[15] = z

    local v458 = p31[69] * v456 + (p31[65] * v455 + (p31[61] * v454 + 0))
    local v459 = p31[70] * v456 + (p31[66] * v455 + (p31[62] * v454 + 0))
    local v460 = p31[71] * v456 + (p31[67] * v455 + (p31[63] * v454 + 0))
    local v461 = v458

    if v458 == 0 then
        v458, v461 = -p31[3] * 0 + (p31[2] * 0 + v458), -p31[7] * 0 + (p31[6] * 0 + v458)
    end

    local v462 = v459

    if v459 == 0 then
        v459, v462 = -p31[1] * 0 + (p31[3] * 0 + v459), -p31[5] * 0 + (p31[7] * 0 + v459)
    end

    local v463 = v460

    if v460 == 0 then
        v460, v463 = -p31[2] * 0 + (p31[1] * 0 + v460), -p31[6] * 0 + (p31[5] * 0 + v460)
    end

    local v464 = p32[1]

    if v464 == 0 then
        p32[1] = p31[76] * 0 + v464
    end

    local v465 = p32[2]

    if v465 == 0 then
        p32[2] = p31[76] * 0 + v465
    end

    local v466 = p32[3]

    if v466 == 0 then
        p32[3] = p31[76] * 0 + v466
    end

    local v467 = p33[1]

    if v467 == 0 then
        p33[1] = p31[88] * -0 + v467
    end

    local v468 = p33[2]

    if v468 == 0 then
        p33[2] = p31[88] * -0 + v468
    end

    local v469 = p33[3]

    if v469 == 0 then
        p33[3] = p31[88] * -0 + v469
    end

    local v470 = p31[81] * v460 + (p31[77] * v459 + (p31[73] * v458 + v429))
    local v471 = p31[82] * v460 + (p31[78] * v459 + (p31[74] * v458 + v430))
    local v472 = p31[83] * v460 + (p31[79] * v459 + (p31[75] * v458 + v431))
    local v473 = p31[103] * v463 + (p31[100] * v462 + (p31[97] * v461 + v432))
    local v474 = p31[104] * v463 + (p31[101] * v462 + (p31[98] * v461 + v433))
    local v475 = p31[105] * v463 + (p31[102] * v462 + (p31[99] * v461 + v434))
    local v476 = create(v470, v471, v472)
    local x2, y2, z2 = v476.x, v476.y, v476.z

    if v470 < 1.1754943508222875E-38 and v470 > -1.1754943508222875E-38 and v470 ~= 0 then
        buffer.writeu32(v19, 0, to_bits(v470))
        x2 = buffer.readf32(v19, 0)
    end

    if v471 < 1.1754943508222875E-38 and v471 > -1.1754943508222875E-38 and v471 ~= 0 then
        buffer.writeu32(v19, 0, to_bits(v471))
        y2 = buffer.readf32(v19, 0)
    end

    if v472 < 1.1754943508222875E-38 and v472 > -1.1754943508222875E-38 and v472 ~= 0 then
        buffer.writeu32(v19, 0, to_bits(v472))
        z2 = buffer.readf32(v19, 0)
    end

    p32[9] = x2
    p32[10] = y2
    p32[11] = z2

    local v477 = create(v473, v474, v475)
    local x3, y3, z3 = v477.x, v477.y, v477.z

    if v473 < 1.1754943508222875E-38 and v473 > -1.1754943508222875E-38 and v473 ~= 0 then
        buffer.writeu32(v19, 0, to_bits(v473))
        x3 = buffer.readf32(v19, 0)
    end

    if v474 < 1.1754943508222875E-38 and v474 > -1.1754943508222875E-38 and v474 ~= 0 then
        buffer.writeu32(v19, 0, to_bits(v474))
        y3 = buffer.readf32(v19, 0)
    end

    if v475 < 1.1754943508222875E-38 and v475 > -1.1754943508222875E-38 and v475 ~= 0 then
        buffer.writeu32(v19, 0, to_bits(v475))
        z3 = buffer.readf32(v19, 0)
    end

    p33[9] = x3
    p33[10] = y3
    p33[11] = z3
end

function t1.solve_b3_angular(p34, p35, p36) -- line: 895
    -- upvalues: v19 (copy), to_bits (copy), create (copy)
    local v478 = p35[9]
    local v479 = p35[10]
    local v480 = p35[11]
    local v481 = p36[9]
    local v482 = p36[10]
    local v483 = p36[11]
    local v484 = v481 - v478
    local v485 = v482 - v479
    local v486 = v483 - v480
    local v487 = p34[13]
    local v488 = p34[14]
    local v489 = p34[15]
    local v490 = p34[16]
    local v491 = p34[37] * v486 + (p34[29] * v485 + (p34[21] * v484 + v487))
    local v492 = p34[38] * v486 + (p34[30] * v485 + (p34[22] * v484 + v488))
    local v493 = p34[39] * v486 + (p34[31] * v485 + (p34[23] * v484 + v489))
    local v494 = v491 * v490 + p34[45]
    local v495 = p34[36]

    if not (v494 < v495) then
        v494 = v495
    end

    local v496 = 0 - v495

    if not (v496 < v494) then
        v494 = v496
    end

    local v497 = v492 * v490 + p34[46]
    local v498 = p34[40]

    if not (v497 < v498) then
        v497 = v498
    end

    local v499 = 0 - v498

    if not (v499 < v497) then
        v497 = v499
    end

    local v500 = v493 * v490 + p34[47]
    local v501 = p34[48]

    if not (v500 < v501) then
        v500 = v501
    end

    local v502 = 0 - v501

    if not (v502 < v500) then
        v500 = v502
    end

    local v503 = v494 - v487
    local v504 = v497 - v488
    local v505 = v500 - v489
    local v506 = create(v494, v497, v500)
    local x, y, z = v506.x, v506.y, v506.z
    local v507 = x
    local v508 = y
    local v509 = z

    if x == 0 or y == 0 or z == 0 then
        if v494 < 1.1754943508222875E-38 and v494 > -1.1754943508222875E-38 and v494 ~= 0 then
            buffer.writeu32(v19, 0, to_bits(v494))
            v507 = buffer.readf32(v19, 0)
        end

        if v497 < 1.1754943508222875E-38 and v497 > -1.1754943508222875E-38 and v497 ~= 0 then
            buffer.writeu32(v19, 0, to_bits(v497))
            v508 = buffer.readf32(v19, 0)
        end

        if v500 < 1.1754943508222875E-38 and v500 > -1.1754943508222875E-38 and v500 ~= 0 then
            buffer.writeu32(v19, 0, to_bits(v500))
            v509 = buffer.readf32(v19, 0)
        end
    end

    p34[13] = v507
    p34[14] = v508
    p34[15] = v509

    local v510 = p34[69] * v505 + (p34[65] * v504 + (p34[61] * v503 + 0))
    local v511 = p34[70] * v505 + (p34[66] * v504 + (p34[62] * v503 + 0))
    local v512 = p34[71] * v505 + (p34[67] * v504 + (p34[63] * v503 + 0))
    local v513 = v510

    if v510 == 0 then
        v510, v513 = -p34[3] * 0 + (p34[2] * 0 + v510), -p34[7] * 0 + (p34[6] * 0 + v510)
    end

    local v514 = v511

    if v511 == 0 then
        v511, v514 = -p34[1] * 0 + (p34[3] * 0 + v511), -p34[5] * 0 + (p34[7] * 0 + v511)
    end

    local v515 = v512

    if v512 == 0 then
        v512, v515 = -p34[2] * 0 + (p34[1] * 0 + v512), -p34[6] * 0 + (p34[5] * 0 + v512)
    end

    local v516 = p35[1]

    if v516 == 0 then
        p35[1] = p34[76] * 0 + v516
    end

    local v517 = p35[2]

    if v517 == 0 then
        p35[2] = p34[76] * 0 + v517
    end

    local v518 = p35[3]

    if v518 == 0 then
        p35[3] = p34[76] * 0 + v518
    end

    local v519 = p36[1]

    if v519 == 0 then
        p36[1] = p34[88] * -0 + v519
    end

    local v520 = p36[2]

    if v520 == 0 then
        p36[2] = p34[88] * -0 + v520
    end

    local v521 = p36[3]

    if v521 == 0 then
        p36[3] = p34[88] * -0 + v521
    end

    local v522 = p34[81] * v512 + (p34[77] * v511 + (p34[73] * v510 + v478))
    local v523 = p34[82] * v512 + (p34[78] * v511 + (p34[74] * v510 + v479))
    local v524 = p34[83] * v512 + (p34[79] * v511 + (p34[75] * v510 + v480))
    local v525 = p34[103] * v515 + (p34[100] * v514 + (p34[97] * v513 + v481))
    local v526 = p34[104] * v515 + (p34[101] * v514 + (p34[98] * v513 + v482))
    local v527 = p34[105] * v515 + (p34[102] * v514 + (p34[99] * v513 + v483))
    local v528 = create(v522, v523, v524)
    local x2, y2, z2 = v528.x, v528.y, v528.z
    local v529 = x2
    local v530 = y2
    local v531 = z2

    if x2 == 0 or y2 == 0 or z2 == 0 then
        if v522 < 1.1754943508222875E-38 and v522 > -1.1754943508222875E-38 and v522 ~= 0 then
            buffer.writeu32(v19, 0, to_bits(v522))
            v529 = buffer.readf32(v19, 0)
        end

        if v523 < 1.1754943508222875E-38 and v523 > -1.1754943508222875E-38 and v523 ~= 0 then
            buffer.writeu32(v19, 0, to_bits(v523))
            v530 = buffer.readf32(v19, 0)
        end

        if v524 < 1.1754943508222875E-38 and v524 > -1.1754943508222875E-38 and v524 ~= 0 then
            buffer.writeu32(v19, 0, to_bits(v524))
            v531 = buffer.readf32(v19, 0)
        end
    end

    p35[9] = v529
    p35[10] = v530
    p35[11] = v531

    local v532 = create(v525, v526, v527)
    local x3, y3, z3 = v532.x, v532.y, v532.z
    local v533 = x3
    local v534 = y3
    local v535 = z3

    if x3 == 0 or y3 == 0 or z3 == 0 then
        if v525 < 1.1754943508222875E-38 and v525 > -1.1754943508222875E-38 and v525 ~= 0 then
            buffer.writeu32(v19, 0, to_bits(v525))
            v533 = buffer.readf32(v19, 0)
        end

        if v526 < 1.1754943508222875E-38 and v526 > -1.1754943508222875E-38 and v526 ~= 0 then
            buffer.writeu32(v19, 0, to_bits(v526))
            v534 = buffer.readf32(v19, 0)
        end

        if v527 < 1.1754943508222875E-38 and v527 > -1.1754943508222875E-38 and v527 ~= 0 then
            buffer.writeu32(v19, 0, to_bits(v527))
            v535 = buffer.readf32(v19, 0)
        end
    end

    p36[9] = v533
    p36[10] = v534
    p36[11] = v535
end

function t1.solve_w3_inert(p37, p38, p39) -- line: 1010
    -- upvalues: solve_w3 (copy)
    local v536 = p38[1]
    local v537 = p38[2]
    local v538 = p38[3]
    local v539 = p38[9]
    local v540 = p38[10]
    local v541 = p38[11]
    local v542 = p39[1]
    local v543 = p39[2]
    local v544 = p39[3]
    local v545 = p39[9]
    local v546 = p39[10]
    local v547 = p39[11]

    if (v536 ~= 0 or 1 / v536 > 0) and (v537 ~= 0 or 1 / v537 > 0) and (v538 ~= 0 or 1 / v538 > 0) and (v539 ~= 0 or 1 / v539 > 0) and (v540 ~= 0 or 1 / v540 > 0) and (v541 ~= 0 or 1 / v541 > 0) and (v542 ~= 0 or 1 / v542 > 0) and (v543 ~= 0 or 1 / v543 > 0) and (v544 ~= 0 or 1 / v544 > 0) and (v545 ~= 0 or 1 / v545 > 0) and (v546 ~= 0 or 1 / v546 > 0) and (v547 ~= 0 or 1 / v547 > 0) then
        return
    end

    return solve_w3(p37, p38, p39)
end

function t1.solve_b3_inert(p40, p41, p42) -- line: 1034
    -- upvalues: solve_b3 (copy)
    local v548 = p41[1]
    local v549 = p41[2]
    local v550 = p41[3]
    local v551 = p41[9]
    local v552 = p41[10]
    local v553 = p41[11]
    local v554 = p42[1]
    local v555 = p42[2]
    local v556 = p42[3]
    local v557 = p42[9]
    local v558 = p42[10]
    local v559 = p42[11]

    if (v548 ~= 0 or 1 / v548 > 0) and (v549 ~= 0 or 1 / v549 > 0) and (v550 ~= 0 or 1 / v550 > 0) and (v551 ~= 0 or 1 / v551 > 0) and (v552 ~= 0 or 1 / v552 > 0) and (v553 ~= 0 or 1 / v553 > 0) and (v554 ~= 0 or 1 / v554 > 0) and (v555 ~= 0 or 1 / v555 > 0) and (v556 ~= 0 or 1 / v556 > 0) and (v557 ~= 0 or 1 / v557 > 0) and (v558 ~= 0 or 1 / v558 > 0) and (v559 ~= 0 or 1 / v559 > 0) then
        return
    end

    return solve_b3(p40, p41, p42)
end

function t1.solve(p43, p44, p45) -- line: 1058
    -- upvalues: import (copy), t1 (copy), mirror (copy)
    if #p43 ~= 96 then
        error("assertion `left == right` failed\n  left: " .. #p43 .. "\n right: 96", 0)
    end

    if #p44 ~= 16 then
        error("assertion `left == right` failed\n  left: " .. #p44 .. "\n right: 16", 0)
    end

    if #p45 ~= 16 then
        error("assertion `left == right` failed\n  left: " .. #p45 .. "\n right: 16", 0)
    end

    local v560 = mirror(p43)
    local v561 = mirror(p44)
    local v562 = mirror(p45)

    t1.solve_mirrored(p43, v560, p44, v561, p45, v562)

    local store = import("skate_core/physics/solver/contact").store

    store(p43, v560, 9, 16)
    store(p44, v561, 1, 4)
    store(p44, v561, 9, 12)
    store(p45, v562, 1, 4)
    store(p45, v562, 9, 12)
end

function t1.symmetric_impulse_limit(p46, p47) -- line: 1079
    local v563 = if p46 < p47 then p46 else p47
    local v564 = 0 - p47

    if v564 < v563 then
        return v563
    end

    return v564
end

return t1
