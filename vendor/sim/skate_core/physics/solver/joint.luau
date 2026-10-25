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
    -- upvalues: ConstraintGeometry (copy), ReactionState (copy), project_correction (copy), publish_reactions (copy), read_column (copy), write_column (copy), xyz (copy), t1 (copy)
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
        v11[4],
        v11[4]
    }
    local t3 = {
        read_column(p1, 128)[4],
        read_column(p1, 144)[4],
        v12[4],
        v12[4]
    }
    local t4 = {
        t1.joint_limit_correction(v10[1], t2[1], t3[1]),
        t1.joint_limit_correction(v10[2], t2[2], t3[2]),
        t1.joint_limit_correction(v10[3], t2[3], t3[3]),
        t1.joint_limit_correction(v10[4], t2[4], t3[4])
    }
    local t5 = {
        t1.joint_limit_correction(v9[1], v11[1], v12[1]),
        t1.joint_limit_correction(v9[2], v11[2], v12[2]),
        t1.joint_limit_correction(v9[3], v11[3], v12[3]),
        t1.joint_limit_correction(v9[4], v11[4], v12[4])
    }
    local v13 = xyz({
        t4[1] - v8[1],
        t4[2] - v8[2],
        t4[3] - v8[3],
        t4[4] - v8[4]
    })
    local v14 = xyz({
        t5[1] - v7[1],
        t5[2] - v7[2],
        t5[3] - v7[3],
        t5[4] - v7[4]
    })

    write_column(p1, 48, t4)
    write_column(p1, 32, t5)
    ConstraintGeometry.apply_impulse_changes(v2, v3, v4, v14, v13)
    publish_reactions(v3, v4, p2, p3)
end

local v15 = buffer.create(8)

local function fb(p4) -- line: 89
    -- upvalues: v15 (copy)
    buffer.writeu32(v15, 0, p4)

    return (buffer.readf32(v15, 0))
end

local to_bits = rt.to_bits

local function to_bits2(p5) -- line: 94
    -- upvalues: v15 (copy), to_bits (copy)
    if p5 ~= 0 and p5 > -1.1754943508222875E-38 and p5 < 1.1754943508222875E-38 then
        return to_bits(p5)
    end

    buffer.writef32(v15, 0, p5)

    return (buffer.readu32(v15, 0))
end

local relative_corrections_packed, apply_impulse_changes_packed, mirror = v1.relative_corrections_packed, v1.apply_impulse_changes_packed, v1.mirror

local function contact_store() -- line: 108
    -- upvalues: import (copy)
    return import("skate_core/physics/solver/contact").store
end

local function put(_, p7, p8, p9) -- line: 116
    -- upvalues: v15 (copy), to_bits (copy)
    if p9 ~= 0 and p9 > -1.1754943508222875E-38 and p9 < 1.1754943508222875E-38 then
        buffer.writeu32(v15, 0, to_bits(p9))
    else
        buffer.writef32(v15, 0, p9)
    end

    p7[p8] = buffer.readf32(v15, 0)
end

local function limit_correction(p10, p11, p12) -- line: 125
    local v16 = p12 + p10
    local v17 = p11 + p10

    if not (v16 < 0) then
        v16 = 0
    end

    if not (v17 > 0) then
        v17 = 0
    end

    return v17 + v16
end

function t1.solve_mirrored(_, p14, p15, p16, p17, p18) -- line: 134
    -- upvalues: v15 (copy), to_bits (copy), relative_corrections_packed (copy), apply_impulse_changes_packed (copy)
    local v18, v19, v20, v21, v22, v23 = relative_corrections_packed(p14, p16, p18)
    local v24 = p14[9]
    local v25 = p14[10]
    local v26 = p14[11]
    local v27 = p14[12]
    local v28 = p14[13]
    local v29 = p14[14]
    local v30 = p14[15]
    local v31 = p14[16]
    local v32 = p14[33] * v20 + (p14[25] * v19 + (p14[17] * v18 + v24))
    local v33 = p14[34] * v20 + (p14[26] * v19 + (p14[18] * v18 + v25))
    local v34 = p14[35] * v20 + (p14[27] * v19 + (p14[19] * v18 + v26))
    local v35 = p14[36] * v20 + (p14[28] * v19 + (p14[20] * v18 + v27))
    local v36 = p14[37] * v23 + (p14[29] * v22 + (p14[21] * v21 + v28))
    local v37 = p14[38] * v23 + (p14[30] * v22 + (p14[22] * v21 + v29))
    local v38 = p14[39] * v23 + (p14[31] * v22 + (p14[23] * v21 + v30))
    local v39 = p14[40] * v23 + (p14[32] * v22 + (p14[24] * v21 + v31))
    local v40 = p14[44]
    local v41 = p14[48]
    local v42 = p14[28]
    local v43 = p14[36] + v36
    local v44 = v42 + v36

    if not (v43 < 0) then
        v43 = 0
    end

    if not (v44 > 0) then
        v44 = 0
    end

    local v45 = v44 + v43
    local v46 = p14[32]
    local v47 = p14[40] + v37
    local v48 = v46 + v37

    if not (v47 < 0) then
        v47 = 0
    end

    if not (v48 > 0) then
        v48 = 0
    end

    local v49 = v48 + v47
    local v50 = v41 + v38
    local v51 = v40 + v38

    if not (v50 < 0) then
        v50 = 0
    end

    if not (v51 > 0) then
        v51 = 0
    end

    local v52 = v51 + v50
    local v53 = v41 + v39
    local v54 = v40 + v39

    if not (v53 < 0) then
        v53 = 0
    end

    if not (v54 > 0) then
        v54 = 0
    end

    local v55 = v54 + v53
    local v56 = p14[41]
    local v57 = p14[45] + v32
    local v58 = v56 + v32

    if not (v57 < 0) then
        v57 = 0
    end

    if not (v58 > 0) then
        v58 = 0
    end

    local v59 = v58 + v57
    local v60 = p14[42]
    local v61 = p14[46] + v33
    local v62 = v60 + v33

    if not (v61 < 0) then
        v61 = 0
    end

    if not (v62 > 0) then
        v62 = 0
    end

    local v63 = v62 + v61
    local v64 = p14[43]
    local v65 = p14[47] + v34
    local v66 = v64 + v34

    if not (v65 < 0) then
        v65 = 0
    end

    if not (v66 > 0) then
        v66 = 0
    end

    local v67 = v66 + v65
    local v68 = v41 + v35
    local v69 = v40 + v35

    if not (v68 < 0) then
        v68 = 0
    end

    if not (v69 > 0) then
        v69 = 0
    end

    local v70 = v69 + v68
    local v71 = v45 - v28
    local v72 = v49 - v29
    local v73 = v52 - v30
    local v74 = v59 - v24
    local v75 = v63 - v25
    local v76 = v67 - v26

    if v45 ~= 0 and v45 > -1.1754943508222875E-38 and v45 < 1.1754943508222875E-38 then
        buffer.writeu32(v15, 0, to_bits(v45))
    else
        buffer.writef32(v15, 0, v45)
    end

    p14[13] = buffer.readf32(v15, 0)

    if v49 ~= 0 and v49 > -1.1754943508222875E-38 and v49 < 1.1754943508222875E-38 then
        buffer.writeu32(v15, 0, to_bits(v49))
    else
        buffer.writef32(v15, 0, v49)
    end

    p14[14] = buffer.readf32(v15, 0)

    if v52 ~= 0 and v52 > -1.1754943508222875E-38 and v52 < 1.1754943508222875E-38 then
        buffer.writeu32(v15, 0, to_bits(v52))
    else
        buffer.writef32(v15, 0, v52)
    end

    p14[15] = buffer.readf32(v15, 0)

    if v55 ~= 0 and v55 > -1.1754943508222875E-38 and v55 < 1.1754943508222875E-38 then
        buffer.writeu32(v15, 0, to_bits(v55))
    else
        buffer.writef32(v15, 0, v55)
    end

    p14[16] = buffer.readf32(v15, 0)

    if v59 ~= 0 and v59 > -1.1754943508222875E-38 and v59 < 1.1754943508222875E-38 then
        buffer.writeu32(v15, 0, to_bits(v59))
    else
        buffer.writef32(v15, 0, v59)
    end

    p14[9] = buffer.readf32(v15, 0)

    if v63 ~= 0 and v63 > -1.1754943508222875E-38 and v63 < 1.1754943508222875E-38 then
        buffer.writeu32(v15, 0, to_bits(v63))
    else
        buffer.writef32(v15, 0, v63)
    end

    p14[10] = buffer.readf32(v15, 0)

    if v67 ~= 0 and v67 > -1.1754943508222875E-38 and v67 < 1.1754943508222875E-38 then
        buffer.writeu32(v15, 0, to_bits(v67))
    else
        buffer.writef32(v15, 0, v67)
    end

    p14[11] = buffer.readf32(v15, 0)

    if v70 ~= 0 and v70 > -1.1754943508222875E-38 and v70 < 1.1754943508222875E-38 then
        buffer.writeu32(v15, 0, to_bits(v70))
    else
        buffer.writef32(v15, 0, v70)
    end

    p14[12] = buffer.readf32(v15, 0)
    apply_impulse_changes_packed(p14, p15, p16, p17, p18, v74, v75, v76, v71, v72, v73)
end

function t1.solve_mirrored_xyz_r3(p19, p20, p21) -- line: 181
    -- upvalues: v15 (copy), to_bits (copy)
    local v77 = p20[9]
    local v78 = p20[10]
    local v79 = p20[11]
    local v80 = p21[9]
    local v81 = p21[10]
    local v82 = p21[11]
    local v83 = p19[1]
    local v84 = p19[2]
    local v85 = p19[3]
    local v86 = p19[5]
    local v87 = p19[6]
    local v88 = p19[7]
    local v89 = -v79 * v84 + (v78 * v85 + p20[1])
    local v90 = -v77 * v85 + (v79 * v83 + p20[2])

    v85 = -v78 * v83 + (v77 * v84 + p20[3])
    v84 = -v82 * v87 + (v81 * v88 + p21[1])
    v83 = -v80 * v88 + (v82 * v86 + p21[2])
    v88 = -v81 * v86 + (v80 * v87 + p21[3])

    local v91 = v84 - v89
    local v92 = v83 - v90
    local v93 = v88 - v85
    local v94 = v80 - v77
    local v95 = v81 - v78
    local v96 = v82 - v79
    local v97 = p19[9]
    local v98 = p19[10]
    local v99 = p19[11]
    local v100 = p19[12]
    local v101 = p19[13]
    local v102 = p19[14]
    local v103 = p19[15]
    local v104 = p19[16]

    v90 = p19[33] * v93 + (p19[25] * v92 + (p19[17] * v91 + v97))
    v89 = p19[34] * v93 + (p19[26] * v92 + (p19[18] * v91 + v98))
    v88 = p19[35] * v93 + (p19[27] * v92 + (p19[19] * v91 + v99))
    v87 = p19[36] * v93 + (p19[28] * v92 + (p19[20] * v91 + v100))
    v100 = p19[37] * v96 + (p19[29] * v95 + (p19[21] * v94 + v101))
    v93 = p19[38] * v96 + (p19[30] * v95 + (p19[22] * v94 + v102))
    v92 = p19[39] * v96 + (p19[31] * v95 + (p19[23] * v94 + v103))
    v91 = p19[40] * v96 + (p19[32] * v95 + (p19[24] * v94 + v104))
    v104 = p19[44]
    v96 = p19[48]

    local v105 = p19[28]

    v94 = p19[36] + v100
    v86 = v105 + v100

    if not (v94 < 0) then
        v94 = 0
    end

    if not (v86 > 0) then
        v86 = 0
    end

    v95 = v86 + v94
    v105 = p19[32]
    v84 = p19[40] + v93
    v83 = v105 + v93

    if not (v84 < 0) then
        v84 = 0
    end

    if not (v83 > 0) then
        v83 = 0
    end

    v100 = v83 + v84
    v81 = v96 + v92
    v80 = v104 + v92

    if not (v81 < 0) then
        v81 = 0
    end

    if not (v80 > 0) then
        v80 = 0
    end

    v93 = v80 + v81
    v78 = v96 + v91
    v77 = v104 + v91

    if not (v78 < 0) then
        v78 = 0
    end

    if not (v77 > 0) then
        v77 = 0
    end

    v92 = v77 + v78
    v105 = p19[41]

    local v106 = p19[45] + v90
    local v107 = v105 + v90

    if not (v106 < 0) then
        v106 = 0
    end

    if not (v107 > 0) then
        v107 = 0
    end

    v91 = v107 + v106
    v105 = p19[42]
    v106 = p19[46] + v89
    v107 = v105 + v89

    if not (v106 < 0) then
        v106 = 0
    end

    if not (v107 > 0) then
        v107 = 0
    end

    v90 = v107 + v106
    v105 = p19[43]
    v106 = p19[47] + v88
    v107 = v105 + v88

    if not (v106 < 0) then
        v106 = 0
    end

    if not (v107 > 0) then
        v107 = 0
    end

    v89 = v107 + v106
    v105 = v96 + v87

    local v108 = v104 + v87

    if not (v105 < 0) then
        v105 = 0
    end

    if not (v108 > 0) then
        v108 = 0
    end

    v88 = v108 + v105
    v105 = v95 - v101
    v108 = v100 - v102
    v106 = v93 - v103
    v107 = v91 - v97

    local v109 = v90 - v98
    local v110 = v89 - v99

    if v95 ~= 0 and v95 > -1.1754943508222875E-38 and v95 < 1.1754943508222875E-38 then
        buffer.writeu32(v15, 0, to_bits(v95))
    else
        buffer.writef32(v15, 0, v95)
    end

    p19[13] = buffer.readf32(v15, 0)

    if v100 ~= 0 and v100 > -1.1754943508222875E-38 and v100 < 1.1754943508222875E-38 then
        buffer.writeu32(v15, 0, to_bits(v100))
    else
        buffer.writef32(v15, 0, v100)
    end

    p19[14] = buffer.readf32(v15, 0)

    if v93 ~= 0 and v93 > -1.1754943508222875E-38 and v93 < 1.1754943508222875E-38 then
        buffer.writeu32(v15, 0, to_bits(v93))
    else
        buffer.writef32(v15, 0, v93)
    end

    p19[15] = buffer.readf32(v15, 0)

    if v92 ~= 0 and v92 > -1.1754943508222875E-38 and v92 < 1.1754943508222875E-38 then
        buffer.writeu32(v15, 0, to_bits(v92))
    else
        buffer.writef32(v15, 0, v92)
    end

    p19[16] = buffer.readf32(v15, 0)

    if v91 ~= 0 and v91 > -1.1754943508222875E-38 and v91 < 1.1754943508222875E-38 then
        buffer.writeu32(v15, 0, to_bits(v91))
    else
        buffer.writef32(v15, 0, v91)
    end

    p19[9] = buffer.readf32(v15, 0)

    if v90 ~= 0 and v90 > -1.1754943508222875E-38 and v90 < 1.1754943508222875E-38 then
        buffer.writeu32(v15, 0, to_bits(v90))
    else
        buffer.writef32(v15, 0, v90)
    end

    p19[10] = buffer.readf32(v15, 0)

    if v89 ~= 0 and v89 > -1.1754943508222875E-38 and v89 < 1.1754943508222875E-38 then
        buffer.writeu32(v15, 0, to_bits(v89))
    else
        buffer.writef32(v15, 0, v89)
    end

    p19[11] = buffer.readf32(v15, 0)

    if v88 ~= 0 and v88 > -1.1754943508222875E-38 and v88 < 1.1754943508222875E-38 then
        buffer.writeu32(v15, 0, to_bits(v88))
    else
        buffer.writef32(v15, 0, v88)
    end

    p19[12] = buffer.readf32(v15, 0)
    v104 = p19[57] * v110 + (p19[53] * v109 + (p19[49] * v107 + 0))
    v103 = p19[58] * v110 + (p19[54] * v109 + (p19[50] * v107 + 0))
    v102 = p19[59] * v110 + (p19[55] * v109 + (p19[51] * v107 + 0))
    v101 = p19[69] * v106 + (p19[65] * v108 + (p19[61] * v105 + 0))
    v100 = p19[70] * v106 + (p19[66] * v108 + (p19[62] * v105 + 0))
    v99 = p19[71] * v106 + (p19[67] * v108 + (p19[63] * v105 + 0))

    local v111 = p19[1]
    local v112 = p19[2]
    local v113 = p19[3]
    local v114 = p19[5]
    local v115 = p19[6]
    local v116 = p19[7]

    v98 = -v113 * v103 + (v112 * v102 + v101)
    v97 = -v111 * v102 + (v113 * v104 + v100)
    v113 = -v112 * v104 + (v111 * v103 + v99)
    v112 = -v116 * v103 + (v115 * v102 + v101)
    v111 = -v114 * v102 + (v116 * v104 + v100)
    v116 = -v115 * v104 + (v114 * v103 + v99)
    v115 = p19[76]
    v114 = p19[88]
    v101 = v104 * v115 + p20[1]
    v100 = -v104 * v114 + p21[1]
    v104 = v103 * v115 + p20[2]
    v99 = -v103 * v114 + p21[2]
    v103 = v102 * v115 + p20[3]
    v115 = -v102 * v114 + p21[3]
    v114 = p19[81] * v113 + (p19[77] * v97 + (p19[73] * v98 + p20[9]))
    v102 = p19[82] * v113 + (p19[78] * v97 + (p19[74] * v98 + p20[10]))
    v96 = p19[83] * v113 + (p19[79] * v97 + (p19[75] * v98 + p20[11]))
    v113 = -p19[93] * v116 + (-p19[89] * v111 + (-p19[85] * v112 + p21[9]))
    v98 = -p19[94] * v116 + (-p19[90] * v111 + (-p19[86] * v112 + p21[10]))
    v97 = -p19[95] * v116 + (-p19[91] * v111 + (-p19[87] * v112 + p21[11]))

    if v101 ~= 0 and v101 > -1.1754943508222875E-38 and v101 < 1.1754943508222875E-38 then
        buffer.writeu32(v15, 0, to_bits(v101))
    else
        buffer.writef32(v15, 0, v101)
    end

    p20[1] = buffer.readf32(v15, 0)

    if v104 ~= 0 and v104 > -1.1754943508222875E-38 and v104 < 1.1754943508222875E-38 then
        buffer.writeu32(v15, 0, to_bits(v104))
    else
        buffer.writef32(v15, 0, v104)
    end

    p20[2] = buffer.readf32(v15, 0)

    if v103 ~= 0 and v103 > -1.1754943508222875E-38 and v103 < 1.1754943508222875E-38 then
        buffer.writeu32(v15, 0, to_bits(v103))
    else
        buffer.writef32(v15, 0, v103)
    end

    p20[3] = buffer.readf32(v15, 0)

    if v100 ~= 0 and v100 > -1.1754943508222875E-38 and v100 < 1.1754943508222875E-38 then
        buffer.writeu32(v15, 0, to_bits(v100))
    else
        buffer.writef32(v15, 0, v100)
    end

    p21[1] = buffer.readf32(v15, 0)

    if v99 ~= 0 and v99 > -1.1754943508222875E-38 and v99 < 1.1754943508222875E-38 then
        buffer.writeu32(v15, 0, to_bits(v99))
    else
        buffer.writef32(v15, 0, v99)
    end

    p21[2] = buffer.readf32(v15, 0)

    if v115 ~= 0 and v115 > -1.1754943508222875E-38 and v115 < 1.1754943508222875E-38 then
        buffer.writeu32(v15, 0, to_bits(v115))
    else
        buffer.writef32(v15, 0, v115)
    end

    p21[3] = buffer.readf32(v15, 0)

    if v114 ~= 0 and v114 > -1.1754943508222875E-38 and v114 < 1.1754943508222875E-38 then
        buffer.writeu32(v15, 0, to_bits(v114))
    else
        buffer.writef32(v15, 0, v114)
    end

    p20[9] = buffer.readf32(v15, 0)

    if v102 ~= 0 and v102 > -1.1754943508222875E-38 and v102 < 1.1754943508222875E-38 then
        buffer.writeu32(v15, 0, to_bits(v102))
    else
        buffer.writef32(v15, 0, v102)
    end

    p20[10] = buffer.readf32(v15, 0)

    if v96 ~= 0 and v96 > -1.1754943508222875E-38 and v96 < 1.1754943508222875E-38 then
        buffer.writeu32(v15, 0, to_bits(v96))
    else
        buffer.writef32(v15, 0, v96)
    end

    p20[11] = buffer.readf32(v15, 0)

    if v113 ~= 0 and v113 > -1.1754943508222875E-38 and v113 < 1.1754943508222875E-38 then
        buffer.writeu32(v15, 0, to_bits(v113))
    else
        buffer.writef32(v15, 0, v113)
    end

    p21[9] = buffer.readf32(v15, 0)

    if v98 ~= 0 and v98 > -1.1754943508222875E-38 and v98 < 1.1754943508222875E-38 then
        buffer.writeu32(v15, 0, to_bits(v98))
    else
        buffer.writef32(v15, 0, v98)
    end

    p21[10] = buffer.readf32(v15, 0)

    if v97 ~= 0 and v97 > -1.1754943508222875E-38 and v97 < 1.1754943508222875E-38 then
        buffer.writeu32(v15, 0, to_bits(v97))
    else
        buffer.writef32(v15, 0, v97)
    end

    p21[11] = buffer.readf32(v15, 0)
end

local create = vector.create

local function tiny(p22) -- line: 289
    -- upvalues: v15 (copy), to_bits (copy)
    buffer.writeu32(v15, 0, to_bits(p22))

    return (buffer.readf32(v15, 0))
end

function t1.solve_mirrored_xyz(p23, p24, p25) -- line: 293
    -- upvalues: v15 (copy), to_bits (copy), create (copy)
    local v117 = p24[9]
    local v118 = p24[10]
    local v119 = p24[11]
    local v120 = p25[9]
    local v121 = p25[10]
    local v122 = p25[11]
    local v123 = p23[1]
    local v124 = p23[2]
    local v125 = p23[3]
    local v126 = p23[5]
    local v127 = p23[6]
    local v128 = p23[7]
    local v129 = -v119 * v124 + (v118 * v125 + p24[1])
    local v130 = -v117 * v125 + (v119 * v123 + p24[2])

    v125 = -v118 * v123 + (v117 * v124 + p24[3])
    v124 = -v122 * v127 + (v121 * v128 + p25[1])
    v123 = -v120 * v128 + (v122 * v126 + p25[2])
    v128 = -v121 * v126 + (v120 * v127 + p25[3])

    local v131 = v124 - v129
    local v132 = v123 - v130
    local v133 = v128 - v125
    local v134 = v120 - v117
    local v135 = v121 - v118
    local v136 = v122 - v119
    local v137 = p23[9]
    local v138 = p23[10]
    local v139 = p23[11]
    local v140 = p23[12]
    local v141 = p23[13]
    local v142 = p23[14]
    local v143 = p23[15]
    local v144 = p23[16]

    v130 = p23[33] * v133 + (p23[25] * v132 + (p23[17] * v131 + v137))
    v129 = p23[34] * v133 + (p23[26] * v132 + (p23[18] * v131 + v138))
    v128 = p23[35] * v133 + (p23[27] * v132 + (p23[19] * v131 + v139))
    v127 = p23[36] * v133 + (p23[28] * v132 + (p23[20] * v131 + v140))
    v140 = p23[37] * v136 + (p23[29] * v135 + (p23[21] * v134 + v141))
    v133 = p23[38] * v136 + (p23[30] * v135 + (p23[22] * v134 + v142))
    v132 = p23[39] * v136 + (p23[31] * v135 + (p23[23] * v134 + v143))
    v131 = p23[40] * v136 + (p23[32] * v135 + (p23[24] * v134 + v144))
    v144 = p23[44]
    v136 = p23[48]

    local v145 = p23[28]

    v134 = p23[36] + v140
    v126 = v145 + v140

    if not (v134 < 0) then
        v134 = 0
    end

    if not (v126 > 0) then
        v126 = 0
    end

    v135 = v126 + v134
    v145 = p23[32]
    v124 = p23[40] + v133
    v123 = v145 + v133

    if not (v124 < 0) then
        v124 = 0
    end

    if not (v123 > 0) then
        v123 = 0
    end

    v140 = v123 + v124
    v121 = v136 + v132
    v120 = v144 + v132

    if not (v121 < 0) then
        v121 = 0
    end

    if not (v120 > 0) then
        v120 = 0
    end

    v133 = v120 + v121
    v118 = v136 + v131
    v117 = v144 + v131

    if not (v118 < 0) then
        v118 = 0
    end

    if not (v117 > 0) then
        v117 = 0
    end

    v132 = v117 + v118
    v145 = p23[41]

    local v146 = p23[45] + v130
    local v147 = v145 + v130

    if not (v146 < 0) then
        v146 = 0
    end

    if not (v147 > 0) then
        v147 = 0
    end

    v131 = v147 + v146
    v145 = p23[42]
    v146 = p23[46] + v129
    v147 = v145 + v129

    if not (v146 < 0) then
        v146 = 0
    end

    if not (v147 > 0) then
        v147 = 0
    end

    v130 = v147 + v146
    v145 = p23[43]
    v146 = p23[47] + v128
    v147 = v145 + v128

    if not (v146 < 0) then
        v146 = 0
    end

    if not (v147 > 0) then
        v147 = 0
    end

    v129 = v147 + v146
    v145 = v136 + v127

    local v148 = v144 + v127

    if not (v145 < 0) then
        v145 = 0
    end

    if not (v148 > 0) then
        v148 = 0
    end

    v128 = v148 + v145
    v145 = v135 - v141
    v148 = v140 - v142
    v146 = v133 - v143
    v147 = v131 - v137

    local v149 = v130 - v138
    local v150 = v129 - v139
    local v151 = create(v135, v140, v133)
    local v152, v153, v154 = v151.x, v151.y, v151.z

    if v135 < 1.1754943508222875E-38 and v135 > -1.1754943508222875E-38 and v135 ~= 0 then
        buffer.writeu32(v15, 0, to_bits(v135))
        v152 = buffer.readf32(v15, 0)
    end

    if v140 < 1.1754943508222875E-38 and v140 > -1.1754943508222875E-38 and v140 ~= 0 then
        buffer.writeu32(v15, 0, to_bits(v140))
        v153 = buffer.readf32(v15, 0)
    end

    if v133 < 1.1754943508222875E-38 and v133 > -1.1754943508222875E-38 and v133 ~= 0 then
        buffer.writeu32(v15, 0, to_bits(v133))
        v154 = buffer.readf32(v15, 0)
    end

    p23[13] = v152
    p23[14] = v153
    p23[15] = v154
    v143 = create(v132, 0, 0).x

    if v132 < 1.1754943508222875E-38 and v132 > -1.1754943508222875E-38 and v132 ~= 0 then
        buffer.writeu32(v15, 0, to_bits(v132))
        v143 = buffer.readf32(v15, 0)
    end

    p23[16] = v143
    v151 = create(v131, v130, v129)
    v152 = v151.x
    v153 = v151.y
    v154 = v151.z

    if v131 < 1.1754943508222875E-38 and v131 > -1.1754943508222875E-38 and v131 ~= 0 then
        buffer.writeu32(v15, 0, to_bits(v131))
        v152 = buffer.readf32(v15, 0)
    end

    if v130 < 1.1754943508222875E-38 and v130 > -1.1754943508222875E-38 and v130 ~= 0 then
        buffer.writeu32(v15, 0, to_bits(v130))
        v153 = buffer.readf32(v15, 0)
    end

    if v129 < 1.1754943508222875E-38 and v129 > -1.1754943508222875E-38 and v129 ~= 0 then
        buffer.writeu32(v15, 0, to_bits(v129))
        v154 = buffer.readf32(v15, 0)
    end

    p23[9] = v152
    p23[10] = v153
    p23[11] = v154
    v141 = create(v128, 0, 0).x

    if v128 < 1.1754943508222875E-38 and v128 > -1.1754943508222875E-38 and v128 ~= 0 then
        buffer.writeu32(v15, 0, to_bits(v128))
        v141 = buffer.readf32(v15, 0)
    end

    p23[12] = v141
    v140 = p23[57] * v150 + (p23[53] * v149 + (p23[49] * v147 + 0))
    v139 = p23[58] * v150 + (p23[54] * v149 + (p23[50] * v147 + 0))
    v138 = p23[59] * v150 + (p23[55] * v149 + (p23[51] * v147 + 0))
    v137 = p23[69] * v146 + (p23[65] * v148 + (p23[61] * v145 + 0))
    v136 = p23[70] * v146 + (p23[66] * v148 + (p23[62] * v145 + 0))
    v135 = p23[71] * v146 + (p23[67] * v148 + (p23[63] * v145 + 0))
    v152 = p23[1]
    v153 = p23[2]
    v154 = p23[3]

    local v155 = p23[5]
    local v156 = p23[6]
    local v157 = p23[7]

    v133 = -v154 * v139 + (v153 * v138 + v137)
    v132 = -v152 * v138 + (v154 * v140 + v136)
    v154 = -v153 * v140 + (v152 * v139 + v135)
    v153 = -v157 * v139 + (v156 * v138 + v137)
    v152 = -v155 * v138 + (v157 * v140 + v136)
    v157 = -v156 * v140 + (v155 * v139 + v135)
    v156 = p23[76]
    v155 = p23[88]
    v137 = v140 * v156 + p24[1]
    v136 = -v140 * v155 + p25[1]
    v140 = v139 * v156 + p24[2]
    v135 = -v139 * v155 + p25[2]
    v139 = v138 * v156 + p24[3]
    v156 = -v138 * v155 + p25[3]
    v155 = p23[81] * v154 + (p23[77] * v132 + (p23[73] * v133 + p24[9]))
    v138 = p23[82] * v154 + (p23[78] * v132 + (p23[74] * v133 + p24[10]))
    v131 = p23[83] * v154 + (p23[79] * v132 + (p23[75] * v133 + p24[11]))
    v154 = -p23[93] * v157 + (-p23[89] * v152 + (-p23[85] * v153 + p25[9]))
    v133 = -p23[94] * v157 + (-p23[90] * v152 + (-p23[86] * v153 + p25[10]))
    v132 = -p23[95] * v157 + (-p23[91] * v152 + (-p23[87] * v153 + p25[11]))
    v157 = create(v137, v140, v139)

    local x, y, z = v157.x, v157.y, v157.z

    if v137 < 1.1754943508222875E-38 and v137 > -1.1754943508222875E-38 and v137 ~= 0 then
        buffer.writeu32(v15, 0, to_bits(v137))
        x = buffer.readf32(v15, 0)
    end

    if v140 < 1.1754943508222875E-38 and v140 > -1.1754943508222875E-38 and v140 ~= 0 then
        buffer.writeu32(v15, 0, to_bits(v140))
        y = buffer.readf32(v15, 0)
    end

    if v139 < 1.1754943508222875E-38 and v139 > -1.1754943508222875E-38 and v139 ~= 0 then
        buffer.writeu32(v15, 0, to_bits(v139))
        z = buffer.readf32(v15, 0)
    end

    p24[1] = x
    p24[2] = y
    p24[3] = z

    local v158 = create(v136, v135, v156)

    x = v158.x
    y = v158.y
    z = v158.z

    if v136 < 1.1754943508222875E-38 and v136 > -1.1754943508222875E-38 and v136 ~= 0 then
        buffer.writeu32(v15, 0, to_bits(v136))
        x = buffer.readf32(v15, 0)
    end

    if v135 < 1.1754943508222875E-38 and v135 > -1.1754943508222875E-38 and v135 ~= 0 then
        buffer.writeu32(v15, 0, to_bits(v135))
        y = buffer.readf32(v15, 0)
    end

    if v156 < 1.1754943508222875E-38 and v156 > -1.1754943508222875E-38 and v156 ~= 0 then
        buffer.writeu32(v15, 0, to_bits(v156))
        z = buffer.readf32(v15, 0)
    end

    p25[1] = x
    p25[2] = y
    p25[3] = z
    v158 = create(v155, v138, v131)
    x = v158.x
    y = v158.y
    z = v158.z

    if v155 < 1.1754943508222875E-38 and v155 > -1.1754943508222875E-38 and v155 ~= 0 then
        buffer.writeu32(v15, 0, to_bits(v155))
        x = buffer.readf32(v15, 0)
    end

    if v138 < 1.1754943508222875E-38 and v138 > -1.1754943508222875E-38 and v138 ~= 0 then
        buffer.writeu32(v15, 0, to_bits(v138))
        y = buffer.readf32(v15, 0)
    end

    if v131 < 1.1754943508222875E-38 and v131 > -1.1754943508222875E-38 and v131 ~= 0 then
        buffer.writeu32(v15, 0, to_bits(v131))
        z = buffer.readf32(v15, 0)
    end

    p24[9] = x
    p24[10] = y
    p24[11] = z
    v158 = create(v154, v133, v132)
    x = v158.x
    y = v158.y
    z = v158.z

    if v154 < 1.1754943508222875E-38 and v154 > -1.1754943508222875E-38 and v154 ~= 0 then
        buffer.writeu32(v15, 0, to_bits(v154))
        x = buffer.readf32(v15, 0)
    end

    if v133 < 1.1754943508222875E-38 and v133 > -1.1754943508222875E-38 and v133 ~= 0 then
        buffer.writeu32(v15, 0, to_bits(v133))
        y = buffer.readf32(v15, 0)
    end

    if v132 < 1.1754943508222875E-38 and v132 > -1.1754943508222875E-38 and v132 ~= 0 then
        buffer.writeu32(v15, 0, to_bits(v132))
        z = buffer.readf32(v15, 0)
    end

    p25[9] = x
    p25[10] = y
    p25[11] = z
end

function t1.solve_w3(p26, p27, p28) -- line: 483
    -- upvalues: v15 (copy), to_bits (copy), create (copy)
    local v159 = p27[1]
    local v160 = p27[2]
    local v161 = p27[3]
    local v162 = p27[9]
    local v163 = p27[10]
    local v164 = p27[11]
    local v165 = p28[1]
    local v166 = p28[2]
    local v167 = p28[3]
    local v168 = p28[9]
    local v169 = p28[10]
    local v170 = p28[11]
    local v171 = p26[1]
    local v172 = p26[2]
    local v173 = p26[3]
    local v174 = p26[5]
    local v175 = p26[6]
    local v176 = p26[7]
    local v177 = -v164 * v172 + (v163 * v173 + v159)
    local v178 = -v162 * v173 + (v164 * v171 + v160)
    local v179 = -v163 * v171 + (v162 * v172 + v161)
    local v180 = -v170 * v175 + (v169 * v176 + v165)
    local v181 = -v168 * v176 + (v170 * v174 + v166)
    local v182 = -v169 * v174 + (v168 * v175 + v167)
    local v183 = v180 - v177
    local v184 = v181 - v178
    local v185 = v182 - v179
    local v186 = v168 - v162
    local v187 = v169 - v163
    local v188 = v170 - v164
    local v189 = p26[9]
    local v190 = p26[10]
    local v191 = p26[11]
    local v192 = p26[12]
    local v193 = p26[13]
    local v194 = p26[14]
    local v195 = p26[15]
    local v196 = p26[16]

    v182 = p26[33] * v185 + (p26[25] * v184 + (p26[17] * v183 + v189))
    v181 = p26[34] * v185 + (p26[26] * v184 + (p26[18] * v183 + v190))
    v180 = p26[35] * v185 + (p26[27] * v184 + (p26[19] * v183 + v191))
    v179 = p26[36] * v185 + (p26[28] * v184 + (p26[20] * v183 + v192))
    v192 = p26[37] * v188 + (p26[29] * v187 + (p26[21] * v186 + v193))
    v185 = p26[38] * v188 + (p26[30] * v187 + (p26[22] * v186 + v194))
    v184 = p26[39] * v188 + (p26[31] * v187 + (p26[23] * v186 + v195))
    v183 = p26[40] * v188 + (p26[32] * v187 + (p26[24] * v186 + v196))
    v196 = p26[44]
    v188 = p26[48]

    local v197 = p26[28]

    v186 = p26[36] + v192
    v178 = v197 + v192

    if not (v186 < 0) then
        v186 = 0
    end

    if not (v178 > 0) then
        v178 = 0
    end

    v187 = v178 + v186
    v197 = p26[32]

    local v198 = p26[40] + v185
    local v199 = v197 + v185

    if not (v198 < 0) then
        v198 = 0
    end

    if not (v199 > 0) then
        v199 = 0
    end

    v192 = v199 + v198
    v197 = v188 + v184

    local v200 = v196 + v184

    if not (v197 < 0) then
        v197 = 0
    end

    if not (v200 > 0) then
        v200 = 0
    end

    v185 = v200 + v197
    v197 = v188 + v183
    v200 = v196 + v183

    if not (v197 < 0) then
        v197 = 0
    end

    if not (v200 > 0) then
        v200 = 0
    end

    v184 = v200 + v197
    v197 = p26[41]
    v198 = p26[45] + v182
    v199 = v197 + v182

    if not (v198 < 0) then
        v198 = 0
    end

    if not (v199 > 0) then
        v199 = 0
    end

    v183 = v199 + v198
    v197 = p26[42]
    v198 = p26[46] + v181
    v199 = v197 + v181

    if not (v198 < 0) then
        v198 = 0
    end

    if not (v199 > 0) then
        v199 = 0
    end

    v182 = v199 + v198
    v197 = p26[43]
    v198 = p26[47] + v180
    v199 = v197 + v180

    if not (v198 < 0) then
        v198 = 0
    end

    if not (v199 > 0) then
        v199 = 0
    end

    v181 = v199 + v198
    v197 = v188 + v179
    v200 = v196 + v179

    if not (v197 < 0) then
        v197 = 0
    end

    if not (v200 > 0) then
        v200 = 0
    end

    v180 = v200 + v197
    v197 = v187 - v193
    v200 = v192 - v194
    v198 = v185 - v195
    v199 = v183 - v189

    local v201 = v182 - v190
    local v202 = v181 - v191
    local v203, x, y, z, v204, v205, v206

    if v197 == 0 and v200 == 0 and v198 == 0 then
        p26[13] = v187
        p26[14] = v192
        p26[15] = v185

        if p26[106] == 1 then
            v204 = 0
            v205 = 0
            v206 = 0
        else
            v204 = p26[69] * v198 + (p26[65] * v200 + (p26[61] * v197 + 0))
            v205 = p26[70] * v198 + (p26[66] * v200 + (p26[62] * v197 + 0))
            v206 = p26[71] * v198 + (p26[67] * v200 + (p26[63] * v197 + 0))
        end
    else
        v203 = create(v187, v192, v185)
        x = v203.x
        y = v203.y
        z = v203.z

        if v187 < 1.1754943508222875E-38 and v187 > -1.1754943508222875E-38 and v187 ~= 0 then
            buffer.writeu32(v15, 0, to_bits(v187))
            x = buffer.readf32(v15, 0)
        end

        if v192 < 1.1754943508222875E-38 and v192 > -1.1754943508222875E-38 and v192 ~= 0 then
            buffer.writeu32(v15, 0, to_bits(v192))
            y = buffer.readf32(v15, 0)
        end

        if v185 < 1.1754943508222875E-38 and v185 > -1.1754943508222875E-38 and v185 ~= 0 then
            buffer.writeu32(v15, 0, to_bits(v185))
            z = buffer.readf32(v15, 0)
        end

        p26[13] = x
        p26[14] = y
        p26[15] = z
        v204 = p26[69] * v198 + (p26[65] * v200 + (p26[61] * v197 + 0))
        v205 = p26[70] * v198 + (p26[66] * v200 + (p26[62] * v197 + 0))
        v206 = p26[71] * v198 + (p26[67] * v200 + (p26[63] * v197 + 0))
    end

    v198 = create(v184, 0, 0).x

    if v184 < 1.1754943508222875E-38 and v184 > -1.1754943508222875E-38 and v184 ~= 0 then
        buffer.writeu32(v15, 0, to_bits(v184))
        v198 = buffer.readf32(v15, 0)
    end

    p26[16] = v198
    v203 = create(v183, v182, v181)
    x = v203.x
    y = v203.y
    z = v203.z

    if v183 < 1.1754943508222875E-38 and v183 > -1.1754943508222875E-38 and v183 ~= 0 then
        buffer.writeu32(v15, 0, to_bits(v183))
        x = buffer.readf32(v15, 0)
    end

    if v182 < 1.1754943508222875E-38 and v182 > -1.1754943508222875E-38 and v182 ~= 0 then
        buffer.writeu32(v15, 0, to_bits(v182))
        y = buffer.readf32(v15, 0)
    end

    if v181 < 1.1754943508222875E-38 and v181 > -1.1754943508222875E-38 and v181 ~= 0 then
        buffer.writeu32(v15, 0, to_bits(v181))
        z = buffer.readf32(v15, 0)
    end

    p26[9] = x
    p26[10] = y
    p26[11] = z
    v197 = create(v180, 0, 0).x

    if v180 < 1.1754943508222875E-38 and v180 > -1.1754943508222875E-38 and v180 ~= 0 then
        buffer.writeu32(v15, 0, to_bits(v180))
        v197 = buffer.readf32(v15, 0)
    end

    p26[12] = v197
    v195 = p26[57] * v202 + (p26[53] * v201 + (p26[49] * v199 + 0))
    v194 = p26[58] * v202 + (p26[54] * v201 + (p26[50] * v199 + 0))
    v193 = p26[59] * v202 + (p26[55] * v201 + (p26[51] * v199 + 0))
    v202 = -v173 * v194 + (v172 * v193 + v204)
    v201 = -v171 * v193 + (v173 * v195 + v205)
    v199 = -v172 * v195 + (v171 * v194 + v206)
    v192 = -v176 * v194 + (v175 * v193 + v204)
    v204 = -v174 * v193 + (v176 * v195 + v205)
    v205 = -v175 * v195 + (v174 * v194 + v206)
    v206 = p26[76]
    v191 = p26[88]
    v190 = v195 * v206 + v159
    v189 = -v195 * v191 + v165
    v195 = v194 * v206 + v160
    v188 = -v194 * v191 + v166
    v194 = v193 * v206 + v161
    v206 = -v193 * v191 + v167
    v193 = p26[81] * v199 + (p26[77] * v201 + (p26[73] * v202 + v162))
    v191 = p26[82] * v199 + (p26[78] * v201 + (p26[74] * v202 + v163))
    v187 = p26[83] * v199 + (p26[79] * v201 + (p26[75] * v202 + v164))
    v202 = p26[103] * v205 + (p26[100] * v204 + (p26[97] * v192 + v168))
    v201 = p26[104] * v205 + (p26[101] * v204 + (p26[98] * v192 + v169))
    v199 = p26[105] * v205 + (p26[102] * v204 + (p26[99] * v192 + v170))
    v203 = create(v190, v195, v194)
    x = v203.x
    y = v203.y
    z = v203.z

    if v190 < 1.1754943508222875E-38 and v190 > -1.1754943508222875E-38 and v190 ~= 0 then
        buffer.writeu32(v15, 0, to_bits(v190))
        x = buffer.readf32(v15, 0)
    end

    if v195 < 1.1754943508222875E-38 and v195 > -1.1754943508222875E-38 and v195 ~= 0 then
        buffer.writeu32(v15, 0, to_bits(v195))
        y = buffer.readf32(v15, 0)
    end

    if v194 < 1.1754943508222875E-38 and v194 > -1.1754943508222875E-38 and v194 ~= 0 then
        buffer.writeu32(v15, 0, to_bits(v194))
        z = buffer.readf32(v15, 0)
    end

    p27[1] = x
    p27[2] = y
    p27[3] = z
    v203 = create(v189, v188, v206)
    x = v203.x
    y = v203.y
    z = v203.z

    if v189 < 1.1754943508222875E-38 and v189 > -1.1754943508222875E-38 and v189 ~= 0 then
        buffer.writeu32(v15, 0, to_bits(v189))
        x = buffer.readf32(v15, 0)
    end

    if v188 < 1.1754943508222875E-38 and v188 > -1.1754943508222875E-38 and v188 ~= 0 then
        buffer.writeu32(v15, 0, to_bits(v188))
        y = buffer.readf32(v15, 0)
    end

    if v206 < 1.1754943508222875E-38 and v206 > -1.1754943508222875E-38 and v206 ~= 0 then
        buffer.writeu32(v15, 0, to_bits(v206))
        z = buffer.readf32(v15, 0)
    end

    p28[1] = x
    p28[2] = y
    p28[3] = z
    v206 = create(v193, v191, v187)
    x = v206.x
    y = v206.y
    z = v206.z

    if v193 < 1.1754943508222875E-38 and v193 > -1.1754943508222875E-38 and v193 ~= 0 then
        buffer.writeu32(v15, 0, to_bits(v193))
        x = buffer.readf32(v15, 0)
    end

    if v191 < 1.1754943508222875E-38 and v191 > -1.1754943508222875E-38 and v191 ~= 0 then
        buffer.writeu32(v15, 0, to_bits(v191))
        y = buffer.readf32(v15, 0)
    end

    if v187 < 1.1754943508222875E-38 and v187 > -1.1754943508222875E-38 and v187 ~= 0 then
        buffer.writeu32(v15, 0, to_bits(v187))
        z = buffer.readf32(v15, 0)
    end

    p27[9] = x
    p27[10] = y
    p27[11] = z
    v203 = create(v202, v201, v199)
    x = v203.x
    y = v203.y
    z = v203.z

    if v202 < 1.1754943508222875E-38 and v202 > -1.1754943508222875E-38 and v202 ~= 0 then
        buffer.writeu32(v15, 0, to_bits(v202))
        x = buffer.readf32(v15, 0)
    end

    if v201 < 1.1754943508222875E-38 and v201 > -1.1754943508222875E-38 and v201 ~= 0 then
        buffer.writeu32(v15, 0, to_bits(v201))
        y = buffer.readf32(v15, 0)
    end

    if v199 < 1.1754943508222875E-38 and v199 > -1.1754943508222875E-38 and v199 ~= 0 then
        buffer.writeu32(v15, 0, to_bits(v199))
        z = buffer.readf32(v15, 0)
    end

    p28[9] = x
    p28[10] = y
    p28[11] = z
end

function t1.solve_b3(p29, p30, p31) -- line: 671
    -- upvalues: v15 (copy), to_bits (copy), create (copy)
    local v207 = p30[1]
    local v208 = p30[2]
    local v209 = p30[3]
    local v210 = p30[9]
    local v211 = p30[10]
    local v212 = p30[11]
    local v213 = p31[1]
    local v214 = p31[2]
    local v215 = p31[3]
    local v216 = p31[9]
    local v217 = p31[10]
    local v218 = p31[11]
    local v219 = p29[1]
    local v220 = p29[2]
    local v221 = p29[3]
    local v222 = p29[5]
    local v223 = p29[6]
    local v224 = p29[7]
    local v225 = -v212 * v220 + (v211 * v221 + v207)
    local v226 = -v210 * v221 + (v212 * v219 + v208)
    local v227 = -v211 * v219 + (v210 * v220 + v209)
    local v228 = -v218 * v223 + (v217 * v224 + v213)
    local v229 = -v216 * v224 + (v218 * v222 + v214)
    local v230 = -v217 * v222 + (v216 * v223 + v215)
    local v231 = v228 - v225
    local v232 = v229 - v226
    local v233 = v230 - v227
    local v234 = v216 - v210
    local v235 = v217 - v211
    local v236 = v218 - v212
    local v237 = p29[9]
    local v238 = p29[10]
    local v239 = p29[11]
    local v240 = p29[12]
    local v241 = p29[13]
    local v242 = p29[14]
    local v243 = p29[15]
    local v244 = p29[16]

    v230 = p29[33] * v233 + (p29[25] * v232 + (p29[17] * v231 + v237))
    v229 = p29[34] * v233 + (p29[26] * v232 + (p29[18] * v231 + v238))
    v228 = p29[35] * v233 + (p29[27] * v232 + (p29[19] * v231 + v239))
    v227 = p29[36] * v233 + (p29[28] * v232 + (p29[20] * v231 + v240))
    v240 = p29[37] * v236 + (p29[29] * v235 + (p29[21] * v234 + v241))
    v233 = p29[38] * v236 + (p29[30] * v235 + (p29[22] * v234 + v242))
    v232 = p29[39] * v236 + (p29[31] * v235 + (p29[23] * v234 + v243))
    v231 = p29[40] * v236 + (p29[32] * v235 + (p29[24] * v234 + v244))
    v244 = p29[44]
    v236 = p29[48]

    local v245 = p29[28]

    v234 = p29[36] + v240
    v226 = v245 + v240

    if not (v234 < 0) then
        v234 = 0
    end

    if not (v226 > 0) then
        v226 = 0
    end

    v235 = v226 + v234
    v245 = p29[32]

    local v246 = p29[40] + v233
    local v247 = v245 + v233

    if not (v246 < 0) then
        v246 = 0
    end

    if not (v247 > 0) then
        v247 = 0
    end

    v240 = v247 + v246
    v245 = v236 + v232

    local v248 = v244 + v232

    if not (v245 < 0) then
        v245 = 0
    end

    if not (v248 > 0) then
        v248 = 0
    end

    v233 = v248 + v245
    v245 = v236 + v231
    v248 = v244 + v231

    if not (v245 < 0) then
        v245 = 0
    end

    if not (v248 > 0) then
        v248 = 0
    end

    v232 = v248 + v245
    v245 = p29[41]
    v246 = p29[45] + v230
    v247 = v245 + v230

    if not (v246 < 0) then
        v246 = 0
    end

    if not (v247 > 0) then
        v247 = 0
    end

    v231 = v247 + v246
    v245 = p29[42]
    v246 = p29[46] + v229
    v247 = v245 + v229

    if not (v246 < 0) then
        v246 = 0
    end

    if not (v247 > 0) then
        v247 = 0
    end

    v230 = v247 + v246
    v245 = p29[43]
    v246 = p29[47] + v228
    v247 = v245 + v228

    if not (v246 < 0) then
        v246 = 0
    end

    if not (v247 > 0) then
        v247 = 0
    end

    v229 = v247 + v246
    v245 = v236 + v227
    v248 = v244 + v227

    if not (v245 < 0) then
        v245 = 0
    end

    if not (v248 > 0) then
        v248 = 0
    end

    v228 = v248 + v245
    v245 = v235 - v241
    v248 = v240 - v242
    v246 = v233 - v243
    v247 = v231 - v237

    local v249 = v230 - v238
    local v250 = v229 - v239
    local x, v251, v252, v253, v254, v255, v256

    if v245 == 0 and v248 == 0 and v246 == 0 then
        p29[13] = v235
        p29[14] = v240
        p29[15] = v233

        if p29[106] == 1 then
            v254 = 0
            v255 = 0
            v256 = 0
        else
            v254 = p29[69] * v246 + (p29[65] * v248 + (p29[61] * v245 + 0))
            v255 = p29[70] * v246 + (p29[66] * v248 + (p29[62] * v245 + 0))
            v256 = p29[71] * v246 + (p29[67] * v248 + (p29[63] * v245 + 0))
        end
    else
        local v257 = create(v235, v240, v233)

        x = v257.x

        local y, z = v257.y, v257.z

        v251 = x
        v252 = y
        v253 = z

        if x == 0 or y == 0 or z == 0 then
            if v235 < 1.1754943508222875E-38 and v235 > -1.1754943508222875E-38 and v235 ~= 0 then
                buffer.writeu32(v15, 0, to_bits(v235))
                v251 = buffer.readf32(v15, 0)
            end

            if v240 < 1.1754943508222875E-38 and v240 > -1.1754943508222875E-38 and v240 ~= 0 then
                buffer.writeu32(v15, 0, to_bits(v240))
                v252 = buffer.readf32(v15, 0)
            end

            if v233 < 1.1754943508222875E-38 and v233 > -1.1754943508222875E-38 and v233 ~= 0 then
                buffer.writeu32(v15, 0, to_bits(v233))
                v253 = buffer.readf32(v15, 0)
            end
        end

        p29[13] = v251
        p29[14] = v252
        p29[15] = v253
        v254 = p29[69] * v246 + (p29[65] * v248 + (p29[61] * v245 + 0))
        v255 = p29[70] * v246 + (p29[66] * v248 + (p29[62] * v245 + 0))
        v256 = p29[71] * v246 + (p29[67] * v248 + (p29[63] * v245 + 0))
    end

    v246 = create(v232, 0, 0).x

    if v246 == 0 and v232 < 1.1754943508222875E-38 and v232 > -1.1754943508222875E-38 and v232 ~= 0 then
        buffer.writeu32(v15, 0, to_bits(v232))
        v246 = buffer.readf32(v15, 0)
    end

    p29[16] = v246
    x = create(v231, v230, v229)
    v251 = x.x
    v252 = x.y
    v253 = x.z

    local v258 = v251
    local v259 = v252
    local v260 = v253

    if v251 == 0 or v252 == 0 or v253 == 0 then
        if v231 < 1.1754943508222875E-38 and v231 > -1.1754943508222875E-38 and v231 ~= 0 then
            buffer.writeu32(v15, 0, to_bits(v231))
            v258 = buffer.readf32(v15, 0)
        end

        if v230 < 1.1754943508222875E-38 and v230 > -1.1754943508222875E-38 and v230 ~= 0 then
            buffer.writeu32(v15, 0, to_bits(v230))
            v259 = buffer.readf32(v15, 0)
        end

        if v229 < 1.1754943508222875E-38 and v229 > -1.1754943508222875E-38 and v229 ~= 0 then
            buffer.writeu32(v15, 0, to_bits(v229))
            v260 = buffer.readf32(v15, 0)
        end
    end

    p29[9] = v258
    p29[10] = v259
    p29[11] = v260
    v245 = create(v228, 0, 0).x

    if v245 == 0 and v228 < 1.1754943508222875E-38 and v228 > -1.1754943508222875E-38 and v228 ~= 0 then
        buffer.writeu32(v15, 0, to_bits(v228))
        v245 = buffer.readf32(v15, 0)
    end

    p29[12] = v245
    v243 = p29[57] * v250 + (p29[53] * v249 + (p29[49] * v247 + 0))
    v242 = p29[58] * v250 + (p29[54] * v249 + (p29[50] * v247 + 0))
    v241 = p29[59] * v250 + (p29[55] * v249 + (p29[51] * v247 + 0))
    v250 = -v221 * v242 + (v220 * v241 + v254)
    v249 = -v219 * v241 + (v221 * v243 + v255)
    v247 = -v220 * v243 + (v219 * v242 + v256)
    v240 = -v224 * v242 + (v223 * v241 + v254)
    v254 = -v222 * v241 + (v224 * v243 + v255)
    v255 = -v223 * v243 + (v222 * v242 + v256)
    v256 = p29[76]
    v239 = p29[88]
    v238 = v243 * v256 + v207
    v237 = -v243 * v239 + v213
    v243 = v242 * v256 + v208
    v236 = -v242 * v239 + v214
    v242 = v241 * v256 + v209
    v256 = -v241 * v239 + v215
    v241 = p29[81] * v247 + (p29[77] * v249 + (p29[73] * v250 + v210))
    v239 = p29[82] * v247 + (p29[78] * v249 + (p29[74] * v250 + v211))
    v235 = p29[83] * v247 + (p29[79] * v249 + (p29[75] * v250 + v212))
    v250 = p29[103] * v255 + (p29[100] * v254 + (p29[97] * v240 + v216))
    v249 = p29[104] * v255 + (p29[101] * v254 + (p29[98] * v240 + v217))
    v247 = p29[105] * v255 + (p29[102] * v254 + (p29[99] * v240 + v218))
    v251 = create(v238, v243, v242)
    v258 = v251.x
    v259 = v251.y
    v260 = v251.z

    local v261 = v258
    local v262 = v259
    local v263 = v260

    if v258 == 0 or v259 == 0 or v260 == 0 then
        if v238 < 1.1754943508222875E-38 and v238 > -1.1754943508222875E-38 and v238 ~= 0 then
            buffer.writeu32(v15, 0, to_bits(v238))
            v261 = buffer.readf32(v15, 0)
        end

        if v243 < 1.1754943508222875E-38 and v243 > -1.1754943508222875E-38 and v243 ~= 0 then
            buffer.writeu32(v15, 0, to_bits(v243))
            v262 = buffer.readf32(v15, 0)
        end

        if v242 < 1.1754943508222875E-38 and v242 > -1.1754943508222875E-38 and v242 ~= 0 then
            buffer.writeu32(v15, 0, to_bits(v242))
            v263 = buffer.readf32(v15, 0)
        end
    end

    p30[1] = v261
    p30[2] = v262
    p30[3] = v263
    v258 = create(v237, v236, v256)
    v261 = v258.x
    v262 = v258.y
    v263 = v258.z

    local v264 = v261
    local v265 = v262
    local v266 = v263

    if v261 == 0 or v262 == 0 or v263 == 0 then
        if v237 < 1.1754943508222875E-38 and v237 > -1.1754943508222875E-38 and v237 ~= 0 then
            buffer.writeu32(v15, 0, to_bits(v237))
            v264 = buffer.readf32(v15, 0)
        end

        if v236 < 1.1754943508222875E-38 and v236 > -1.1754943508222875E-38 and v236 ~= 0 then
            buffer.writeu32(v15, 0, to_bits(v236))
            v265 = buffer.readf32(v15, 0)
        end

        if v256 < 1.1754943508222875E-38 and v256 > -1.1754943508222875E-38 and v256 ~= 0 then
            buffer.writeu32(v15, 0, to_bits(v256))
            v266 = buffer.readf32(v15, 0)
        end
    end

    p31[1] = v264
    p31[2] = v265
    p31[3] = v266
    v256 = create(v241, v239, v235)
    v264 = v256.x
    v265 = v256.y
    v266 = v256.z

    local v267 = v264
    local v268 = v265
    local v269 = v266

    if v264 == 0 or v265 == 0 or v266 == 0 then
        if v241 < 1.1754943508222875E-38 and v241 > -1.1754943508222875E-38 and v241 ~= 0 then
            buffer.writeu32(v15, 0, to_bits(v241))
            v267 = buffer.readf32(v15, 0)
        end

        if v239 < 1.1754943508222875E-38 and v239 > -1.1754943508222875E-38 and v239 ~= 0 then
            buffer.writeu32(v15, 0, to_bits(v239))
            v268 = buffer.readf32(v15, 0)
        end

        if v235 < 1.1754943508222875E-38 and v235 > -1.1754943508222875E-38 and v235 ~= 0 then
            buffer.writeu32(v15, 0, to_bits(v235))
            v269 = buffer.readf32(v15, 0)
        end
    end

    p30[9] = v267
    p30[10] = v268
    p30[11] = v269
    v264 = create(v250, v249, v247)
    v267 = v264.x
    v268 = v264.y
    v269 = v264.z

    local v270 = v267
    local v271 = v268
    local v272 = v269

    if v267 == 0 or v268 == 0 or v269 == 0 then
        if v250 < 1.1754943508222875E-38 and v250 > -1.1754943508222875E-38 and v250 ~= 0 then
            buffer.writeu32(v15, 0, to_bits(v250))
            v270 = buffer.readf32(v15, 0)
        end

        if v249 < 1.1754943508222875E-38 and v249 > -1.1754943508222875E-38 and v249 ~= 0 then
            buffer.writeu32(v15, 0, to_bits(v249))
            v271 = buffer.readf32(v15, 0)
        end

        if v247 < 1.1754943508222875E-38 and v247 > -1.1754943508222875E-38 and v247 ~= 0 then
            buffer.writeu32(v15, 0, to_bits(v247))
            v272 = buffer.readf32(v15, 0)
        end
    end

    p31[9] = v270
    p31[10] = v271
    p31[11] = v272
end

function t1.solve(p32, p33, p34) -- line: 875
    -- upvalues: import (copy), t1 (copy), mirror (copy)
    if #p32 ~= 96 then
        error("assertion `left == right` failed\n  left: " .. #p32 .. "\n right: 96", 0)
    end

    if #p33 ~= 16 then
        error("assertion `left == right` failed\n  left: " .. #p33 .. "\n right: 16", 0)
    end

    if #p34 ~= 16 then
        error("assertion `left == right` failed\n  left: " .. #p34 .. "\n right: 16", 0)
    end

    local v273 = mirror(p32)
    local v274 = mirror(p33)
    local v275 = mirror(p34)

    t1.solve_mirrored(p32, v273, p33, v274, p34, v275)

    local store = import("skate_core/physics/solver/contact").store

    store(p32, v273, 9, 16)
    store(p33, v274, 1, 4)
    store(p33, v274, 9, 12)
    store(p34, v275, 1, 4)
    store(p34, v275, 9, 12)
end

function t1.joint_limit_correction(p35, p36, p37) -- line: 899
    local v276 = p37 + p35
    local v277 = p36 + p35

    if not (v276 < 0) then
        v276 = 0
    end

    if not (v277 > 0) then
        v277 = 0
    end

    return v277 + v276
end

return t1
