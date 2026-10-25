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
local Vector3 = import("skate_core/math").Vector3
local RetailContactJacobian = import("skate_core/physics/contact_solver").RetailContactJacobian
local t1 = {}

function t1.contact(p4) -- line: 44
    -- upvalues: RetailContactJacobian (copy)
    return {
        words = table.clone(RetailContactJacobian.words(p4)),
        reaction_a = p4.reaction_index_a,
        reaction_b = p4.reaction_index_b
    }
end

function t1.contact_into(p5, p6) -- line: 56
    -- upvalues: RetailContactJacobian (copy)
    p5.words = table.clone(RetailContactJacobian.words(p6))
    p5.reaction_a = p6.reaction_index_a
    p5.reaction_b = p6.reaction_index_b

    return p5
end

function t1.drive_reference(p7) -- line: 65
    -- upvalues: v1 (copy), t1 (copy)
    local v8 = table.create(96, 0)

    t1.vector(v8, 0, p7.arm_a, 0)
    t1.vector(v8, 1, p7.arm_b, 0)
    t1.row(v8, 2, p7.accumulated_linear_impulse, p7.linear_softness)
    t1.row(v8, 3, p7.accumulated_angular_impulse, p7.angular_softness)

    for i = 0, 2 do
        t1.row(v8, i * 2 + 4, {
            t1.xyz(p7.linear_axes[1])[i + 1] * p7.linear_inverse_effective_mass[1],
            t1.xyz(p7.linear_axes[2])[i + 1] * p7.linear_inverse_effective_mass[2],
            t1.xyz(p7.linear_axes[3])[i + 1] * p7.linear_inverse_effective_mass[3]
        }, 0)
        t1.row(v8, i * 2 + 5, {
            t1.xyz(p7.angular_axes[1])[i + 1] * p7.angular_inverse_effective_mass[1],
            t1.xyz(p7.angular_axes[2])[i + 1] * p7.angular_inverse_effective_mass[2],
            t1.xyz(p7.angular_axes[3])[i + 1] * p7.angular_inverse_effective_mass[3]
        }, 0)
        t1.vector(v8, i + 12, p7.linear_axes[i + 1], 0)
        t1.vector(v8, i + 15, p7.angular_axes[i + 1], 0)
    end

    t1.row(v8, 10, p7.linear_target_impulse, p7.linear_maximum_impulse[3])
    t1.row(v8, 11, p7.angular_target_impulse, p7.angular_maximum_impulse[3])

    local v9 = p7.linear_maximum_impulse[1]
    local v10

    if v9 ~= 0 and v9 > -1.1754943508222875E-38 and v9 < 1.1754943508222875E-38 then
        local v11 = math.abs(v9) * 7.1362384635298E+44
        local v12 = math.floor(v11)
        local v13 = v11 - v12

        v10 = if v13 > 0.5 or v13 == 0.5 and v12 % 2 == 1 then v12 + 1 else v12

        if v9 < 0 then
            v10 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v9)
        v10 = buffer.readu32(v1, 0)
    end

    v8[28] = v10

    local v14 = p7.linear_maximum_impulse[2]
    local v15

    if v14 ~= 0 and v14 > -1.1754943508222875E-38 and v14 < 1.1754943508222875E-38 then
        local v16 = math.abs(v14) * 7.1362384635298E+44
        local v17 = math.floor(v16)
        local v18 = v16 - v17

        v15 = if v18 > 0.5 or v18 == 0.5 and v17 % 2 == 1 then v17 + 1 else v17

        if v14 < 0 then
            v15 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v14)
        v15 = buffer.readu32(v1, 0)
    end

    v8[32] = v15

    local v19 = p7.angular_maximum_impulse[1]
    local v20

    if v19 ~= 0 and v19 > -1.1754943508222875E-38 and v19 < 1.1754943508222875E-38 then
        local v21 = math.abs(v19) * 7.1362384635298E+44
        local v22 = math.floor(v21)
        local v23 = v21 - v22

        v20 = if v23 > 0.5 or v23 == 0.5 and v22 % 2 == 1 then v22 + 1 else v22

        if v19 < 0 then
            v20 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v19)
        v20 = buffer.readu32(v1, 0)
    end

    v8[36] = v20

    local v24 = p7.angular_maximum_impulse[2]
    local v25

    if v24 ~= 0 and v24 > -1.1754943508222875E-38 and v24 < 1.1754943508222875E-38 then
        local v26 = math.abs(v24) * 7.1362384635298E+44
        local v27 = math.floor(v26)
        local v28 = v26 - v27

        v25 = if v28 > 0.5 or v28 == 0.5 and v27 % 2 == 1 then v27 + 1 else v27

        if v24 < 0 then
            v25 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v24)
        v25 = buffer.readu32(v1, 0)
    end

    v8[40] = v25

    local t2 = {
        {
            18,
            p7.frame_a_body
        },
        {
            21,
            p7.frame_b_body
        }
    }

    for _, v29 in ipairs(t2) do
        local v30 = v29[1]
        local v31 = v29[2]

        if bit32.band(v31.state, 4) ~= 0 then
            local v32 = t1.inertia_columns(v31.world_inverse_inertia)

            for j = 0, 2 do
                local v33 = v32[j + 1]

                t1.vector(v8, v30 + j, v33, if j == 0 then v31.inverse_mass else 0)
            end
        end
    end

    return {
        words = v8,
        reaction_a = p7.frame_a_body.reaction_index,
        reaction_b = p7.frame_b_body.reaction_index
    }
end

local to_bits = rt.to_bits

buffer.writef32(v1, 0, 0)

local v34 = buffer.readu32(v1, 0)

local function drive_body_rows(p8, p9, p10) -- line: 128
    -- upvalues: to_bits (copy), v34 (copy)
    local v35 = p9 * 4

    if bit32.band(p10.state, 4) == 0 then
        local v36 = v35 + 1
        local v37 = v35 + 2
        local v38 = v35 + 3
        local v39 = v35 + 4

        p8[v36] = 0
        p8[v37] = 0
        p8[v38] = 0
        p8[v39] = 0

        local v40 = v35 + 5
        local v41 = v35 + 6
        local v42 = v35 + 7
        local v43 = v35 + 8

        p8[v40] = 0
        p8[v41] = 0
        p8[v42] = 0
        p8[v43] = 0

        local v44 = v35 + 9
        local v45 = v35 + 10
        local v46 = v35 + 11
        local v47 = v35 + 12

        p8[v44] = 0
        p8[v45] = 0
        p8[v46] = 0
        p8[v47] = 0
    else
        local world_inverse_inertia = p10.world_inverse_inertia
        local full, split = world_inverse_inertia.full, world_inverse_inertia.split
        local v48 = v35 + 1
        local v49 = v35 + 2
        local v50 = v35 + 3
        local v51 = v35 + 4
        local v52 = to_bits(full.x)
        local v53 = to_bits(full.y)
        local v54 = to_bits(full.z)
        local v55 = to_bits(p10.inverse_mass)

        p8[v48] = v52
        p8[v49] = v53
        p8[v50] = v54
        p8[v51] = v55

        local v56 = v35 + 5
        local v57 = v35 + 6
        local v58 = v35 + 7
        local v59 = v35 + 8
        local v60 = to_bits(full.y)
        local v61 = to_bits(split.y)
        local v62 = to_bits(split.z)

        p8[v56] = v60
        p8[v57] = v61
        p8[v58] = v62
        p8[v59] = v34

        local v63 = v35 + 9
        local v64 = v35 + 10
        local v65 = v35 + 11
        local v66 = v35 + 12
        local v67 = to_bits(full.z)
        local v68 = to_bits(split.z)
        local v69 = to_bits(split.x)

        p8[v63] = v67
        p8[v64] = v68
        p8[v65] = v69
        p8[v66] = v34
    end
end

local t3 = {}

function t1.register_drive_rows(p11) -- line: 171
    -- upvalues: t3 (copy)
    if t3[p11] == nil then
        t3[p11] = {
            reaction_a = 0,
            reaction_b = 0,
            words = table.create(96, 0)
        }
    end
end

function t1.unregister_drive_rows(p12) -- line: 178
    -- upvalues: t3 (copy)
    t3[p12] = nil
end

function t1.drive(p13) -- line: 182
    -- upvalues: to_bits (copy), v34 (copy), drive_body_rows (copy), t3 (copy)
    local v70 = t3[p13]
    local v71 = if v70 == nil then table.create(96, 0) else v70.words
    local arm_a, arm_b = p13.arm_a, p13.arm_b
    local v72 = to_bits(arm_a.x)
    local v73 = to_bits(arm_a.y)
    local v74 = to_bits(arm_a.z)

    v71[1] = v72
    v71[2] = v73
    v71[3] = v74
    v71[4] = v34

    local v75 = to_bits(arm_b.x)
    local v76 = to_bits(arm_b.y)
    local v77 = to_bits(arm_b.z)

    v71[5] = v75
    v71[6] = v76
    v71[7] = v77
    v71[8] = v34

    local accumulated_linear_impulse = p13.accumulated_linear_impulse
    local v78 = to_bits(accumulated_linear_impulse[1])
    local v79 = to_bits(accumulated_linear_impulse[2])
    local v80 = to_bits(accumulated_linear_impulse[3])
    local v81 = to_bits(p13.linear_softness)

    v71[9] = v78
    v71[10] = v79
    v71[11] = v80
    v71[12] = v81

    local accumulated_angular_impulse = p13.accumulated_angular_impulse
    local v82 = to_bits(accumulated_angular_impulse[1])
    local v83 = to_bits(accumulated_angular_impulse[2])
    local v84 = to_bits(accumulated_angular_impulse[3])
    local v85 = to_bits(p13.angular_softness)

    v71[13] = v82
    v71[14] = v83
    v71[15] = v84
    v71[16] = v85

    local v86 = p13.linear_axes[1]
    local v87 = p13.linear_axes[2]
    local v88 = p13.linear_axes[3]
    local v89 = p13.angular_axes[1]
    local v90 = p13.angular_axes[2]
    local v91 = p13.angular_axes[3]
    local linear_inverse_effective_mass, angular_inverse_effective_mass = p13.linear_inverse_effective_mass, p13.angular_inverse_effective_mass
    local v92 = linear_inverse_effective_mass[1]
    local v93 = linear_inverse_effective_mass[2]
    local v94 = linear_inverse_effective_mass[3]
    local v95 = angular_inverse_effective_mass[1]
    local v96 = angular_inverse_effective_mass[2]
    local v97 = angular_inverse_effective_mass[3]
    local v98 = to_bits(v86.x * v92)
    local v99 = to_bits(v87.x * v93)
    local v100 = to_bits(v88.x * v94)

    v71[17] = v98
    v71[18] = v99
    v71[19] = v100
    v71[20] = v34

    local v101 = to_bits(v86.y * v92)
    local v102 = to_bits(v87.y * v93)
    local v103 = to_bits(v88.y * v94)

    v71[25] = v101
    v71[26] = v102
    v71[27] = v103
    v71[28] = v34

    local v104 = to_bits(v86.z * v92)
    local v105 = to_bits(v87.z * v93)
    local v106 = to_bits(v88.z * v94)

    v71[33] = v104
    v71[34] = v105
    v71[35] = v106
    v71[36] = v34

    local v107 = to_bits(v89.x * v95)
    local v108 = to_bits(v90.x * v96)
    local v109 = to_bits(v91.x * v97)

    v71[21] = v107
    v71[22] = v108
    v71[23] = v109
    v71[24] = v34

    local v110 = to_bits(v89.y * v95)
    local v111 = to_bits(v90.y * v96)
    local v112 = to_bits(v91.y * v97)

    v71[29] = v110
    v71[30] = v111
    v71[31] = v112
    v71[32] = v34

    local v113 = to_bits(v89.z * v95)
    local v114 = to_bits(v90.z * v96)
    local v115 = to_bits(v91.z * v97)

    v71[37] = v113
    v71[38] = v114
    v71[39] = v115
    v71[40] = v34

    local v116 = to_bits(v86.x)
    local v117 = to_bits(v86.y)
    local v118 = to_bits(v86.z)

    v71[49] = v116
    v71[50] = v117
    v71[51] = v118
    v71[52] = v34

    local v119 = to_bits(v87.x)
    local v120 = to_bits(v87.y)
    local v121 = to_bits(v87.z)

    v71[53] = v119
    v71[54] = v120
    v71[55] = v121
    v71[56] = v34

    local v122 = to_bits(v88.x)
    local v123 = to_bits(v88.y)
    local v124 = to_bits(v88.z)

    v71[57] = v122
    v71[58] = v123
    v71[59] = v124
    v71[60] = v34

    local v125 = to_bits(v89.x)
    local v126 = to_bits(v89.y)
    local v127 = to_bits(v89.z)

    v71[61] = v125
    v71[62] = v126
    v71[63] = v127
    v71[64] = v34

    local v128 = to_bits(v90.x)
    local v129 = to_bits(v90.y)
    local v130 = to_bits(v90.z)

    v71[65] = v128
    v71[66] = v129
    v71[67] = v130
    v71[68] = v34

    local v131 = to_bits(v91.x)
    local v132 = to_bits(v91.y)
    local v133 = to_bits(v91.z)

    v71[69] = v131
    v71[70] = v132
    v71[71] = v133
    v71[72] = v34

    local linear_maximum_impulse, angular_maximum_impulse, linear_target_impulse = p13.linear_maximum_impulse, p13.angular_maximum_impulse, p13.linear_target_impulse
    local v134 = to_bits(linear_target_impulse[1])
    local v135 = to_bits(linear_target_impulse[2])
    local v136 = to_bits(linear_target_impulse[3])
    local v137 = to_bits(linear_maximum_impulse[3])

    v71[41] = v134
    v71[42] = v135
    v71[43] = v136
    v71[44] = v137

    local angular_target_impulse = p13.angular_target_impulse
    local v138 = to_bits(angular_target_impulse[1])
    local v139 = to_bits(angular_target_impulse[2])
    local v140 = to_bits(angular_target_impulse[3])
    local v141 = to_bits(angular_maximum_impulse[3])

    v71[45] = v138
    v71[46] = v139
    v71[47] = v140
    v71[48] = v141
    v71[28] = to_bits(linear_maximum_impulse[1])
    v71[32] = to_bits(linear_maximum_impulse[2])
    v71[36] = to_bits(angular_maximum_impulse[1])
    v71[40] = to_bits(angular_maximum_impulse[2])
    drive_body_rows(v71, 18, p13.frame_a_body)
    drive_body_rows(v71, 21, p13.frame_b_body)

    if v70 == nil then
        return {
            words = v71,
            reaction_a = p13.frame_a_body.reaction_index,
            reaction_b = p13.frame_b_body.reaction_index
        }
    end

    v70.reaction_a = p13.frame_a_body.reaction_index
    v70.reaction_b = p13.frame_b_body.reaction_index

    return v70
end

local create = vector.create
local v142 = buffer.create(8)

local function tiny(p14) -- line: 260
    -- upvalues: to_bits (copy), v142 (copy)
    buffer.writeu32(v142, 0, to_bits(p14))

    return (buffer.readf32(v142, 0))
end

function t1.drive_into(p15, p16) -- line: 264
    -- upvalues: to_bits (copy), create (copy), v142 (copy)
    local arm_a, arm_b = p16.arm_a, p16.arm_b
    local v143, v144, v145 = arm_a.x, arm_a.y, arm_a.z
    local v146 = create(v143, v144, v145)
    local v147, v148, z = v146.x, v146.y, v146.z

    if v143 < 1.1754943508222875E-38 and v143 > -1.1754943508222875E-38 and v143 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(v143))
        v147 = buffer.readf32(v142, 0)
    end

    if v144 < 1.1754943508222875E-38 and v144 > -1.1754943508222875E-38 and v144 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(v144))
        v148 = buffer.readf32(v142, 0)
    end

    if v145 < 1.1754943508222875E-38 and v145 > -1.1754943508222875E-38 and v145 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(v145))
        z = buffer.readf32(v142, 0)
    end

    p15[1] = v147
    p15[2] = v148
    p15[3] = z
    v143 = arm_b.x
    v144 = arm_b.y
    v145 = arm_b.z

    local v149 = create(v143, v144, v145)

    v146 = v149.x
    v147 = v149.y
    v148 = v149.z

    if v143 < 1.1754943508222875E-38 and v143 > -1.1754943508222875E-38 and v143 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(v143))
        v146 = buffer.readf32(v142, 0)
    end

    if v144 < 1.1754943508222875E-38 and v144 > -1.1754943508222875E-38 and v144 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(v144))
        v147 = buffer.readf32(v142, 0)
    end

    if v145 < 1.1754943508222875E-38 and v145 > -1.1754943508222875E-38 and v145 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(v145))
        v148 = buffer.readf32(v142, 0)
    end

    p15[5] = v146
    p15[6] = v147
    p15[7] = v148
    arm_b = p16.accumulated_linear_impulse
    v143 = arm_b[1]
    v144 = arm_b[2]
    v145 = arm_b[3]
    v146 = create(v143, v144, v145)
    v147 = v146.x
    v148 = v146.y
    z = v146.z

    if v143 < 1.1754943508222875E-38 and v143 > -1.1754943508222875E-38 and v143 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(v143))
        v147 = buffer.readf32(v142, 0)
    end

    if v144 < 1.1754943508222875E-38 and v144 > -1.1754943508222875E-38 and v144 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(v144))
        v148 = buffer.readf32(v142, 0)
    end

    if v145 < 1.1754943508222875E-38 and v145 > -1.1754943508222875E-38 and v145 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(v145))
        z = buffer.readf32(v142, 0)
    end

    p15[9] = v147
    p15[10] = v148
    p15[11] = z
    arm_b = p16.accumulated_angular_impulse
    v143 = arm_b[1]
    v144 = arm_b[2]
    v145 = arm_b[3]
    v146 = create(v143, v144, v145)
    v147 = v146.x
    v148 = v146.y
    z = v146.z

    if v143 < 1.1754943508222875E-38 and v143 > -1.1754943508222875E-38 and v143 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(v143))
        v147 = buffer.readf32(v142, 0)
    end

    if v144 < 1.1754943508222875E-38 and v144 > -1.1754943508222875E-38 and v144 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(v144))
        v148 = buffer.readf32(v142, 0)
    end

    if v145 < 1.1754943508222875E-38 and v145 > -1.1754943508222875E-38 and v145 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(v145))
        z = buffer.readf32(v142, 0)
    end

    p15[13] = v147
    p15[14] = v148
    p15[15] = z
    v143 = p16.linear_axes[1]
    v144 = p16.linear_axes[2]
    v145 = p16.linear_axes[3]
    v146 = p16.angular_axes[1]
    v147 = p16.angular_axes[2]
    v148 = p16.angular_axes[3]
    z = p16.linear_inverse_effective_mass

    local angular_inverse_effective_mass = p16.angular_inverse_effective_mass
    local v150 = z[1]
    local v151 = z[2]
    local v152 = z[3]
    local v153 = angular_inverse_effective_mass[1]
    local v154 = angular_inverse_effective_mass[2]
    local v155 = angular_inverse_effective_mass[3]
    local x, y, z2 = v143.x, v143.y, v143.z
    local x2, y2, z3 = v144.x, v144.y, v144.z
    local x3, y3, z4 = v145.x, v145.y, v145.z
    local x4, y4, z5 = v146.x, v146.y, v146.z
    local x5, y5, z6 = v147.x, v147.y, v147.z
    local x6, y6, z7 = v148.x, v148.y, v148.z
    local v156 = x * v150
    local v157 = x2 * v151
    local v158 = x3 * v152
    local v159 = create(v156, v157, v158)
    local x7, y7, z8 = v159.x, v159.y, v159.z

    if v156 < 1.1754943508222875E-38 and v156 > -1.1754943508222875E-38 and v156 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(v156))
        x7 = buffer.readf32(v142, 0)
    end

    if v157 < 1.1754943508222875E-38 and v157 > -1.1754943508222875E-38 and v157 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(v157))
        y7 = buffer.readf32(v142, 0)
    end

    if v158 < 1.1754943508222875E-38 and v158 > -1.1754943508222875E-38 and v158 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(v158))
        z8 = buffer.readf32(v142, 0)
    end

    p15[17] = x7
    p15[18] = y7
    p15[19] = z8
    v156 = y * v150
    v157 = y2 * v151
    v158 = y3 * v152
    v159 = create(v156, v157, v158)
    x7 = v159.x
    y7 = v159.y
    z8 = v159.z

    if v156 < 1.1754943508222875E-38 and v156 > -1.1754943508222875E-38 and v156 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(v156))
        x7 = buffer.readf32(v142, 0)
    end

    if v157 < 1.1754943508222875E-38 and v157 > -1.1754943508222875E-38 and v157 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(v157))
        y7 = buffer.readf32(v142, 0)
    end

    if v158 < 1.1754943508222875E-38 and v158 > -1.1754943508222875E-38 and v158 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(v158))
        z8 = buffer.readf32(v142, 0)
    end

    p15[25] = x7
    p15[26] = y7
    p15[27] = z8
    v156 = z2 * v150
    v157 = z3 * v151
    v158 = z4 * v152
    v159 = create(v156, v157, v158)
    x7 = v159.x
    y7 = v159.y
    z8 = v159.z

    if v156 < 1.1754943508222875E-38 and v156 > -1.1754943508222875E-38 and v156 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(v156))
        x7 = buffer.readf32(v142, 0)
    end

    if v157 < 1.1754943508222875E-38 and v157 > -1.1754943508222875E-38 and v157 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(v157))
        y7 = buffer.readf32(v142, 0)
    end

    if v158 < 1.1754943508222875E-38 and v158 > -1.1754943508222875E-38 and v158 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(v158))
        z8 = buffer.readf32(v142, 0)
    end

    p15[33] = x7
    p15[34] = y7
    p15[35] = z8
    v156 = x4 * v153
    v157 = x5 * v154
    v158 = x6 * v155
    v159 = create(v156, v157, v158)
    x7 = v159.x
    y7 = v159.y
    z8 = v159.z

    if v156 < 1.1754943508222875E-38 and v156 > -1.1754943508222875E-38 and v156 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(v156))
        x7 = buffer.readf32(v142, 0)
    end

    if v157 < 1.1754943508222875E-38 and v157 > -1.1754943508222875E-38 and v157 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(v157))
        y7 = buffer.readf32(v142, 0)
    end

    if v158 < 1.1754943508222875E-38 and v158 > -1.1754943508222875E-38 and v158 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(v158))
        z8 = buffer.readf32(v142, 0)
    end

    p15[21] = x7
    p15[22] = y7
    p15[23] = z8
    v156 = y4 * v153
    v157 = y5 * v154
    v158 = y6 * v155
    v159 = create(v156, v157, v158)
    x7 = v159.x
    y7 = v159.y
    z8 = v159.z

    if v156 < 1.1754943508222875E-38 and v156 > -1.1754943508222875E-38 and v156 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(v156))
        x7 = buffer.readf32(v142, 0)
    end

    if v157 < 1.1754943508222875E-38 and v157 > -1.1754943508222875E-38 and v157 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(v157))
        y7 = buffer.readf32(v142, 0)
    end

    if v158 < 1.1754943508222875E-38 and v158 > -1.1754943508222875E-38 and v158 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(v158))
        z8 = buffer.readf32(v142, 0)
    end

    p15[29] = x7
    p15[30] = y7
    p15[31] = z8
    v156 = z5 * v153
    v157 = z6 * v154
    v158 = z7 * v155
    v159 = create(v156, v157, v158)
    x7 = v159.x
    y7 = v159.y
    z8 = v159.z

    if v156 < 1.1754943508222875E-38 and v156 > -1.1754943508222875E-38 and v156 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(v156))
        x7 = buffer.readf32(v142, 0)
    end

    if v157 < 1.1754943508222875E-38 and v157 > -1.1754943508222875E-38 and v157 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(v157))
        y7 = buffer.readf32(v142, 0)
    end

    if v158 < 1.1754943508222875E-38 and v158 > -1.1754943508222875E-38 and v158 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(v158))
        z8 = buffer.readf32(v142, 0)
    end

    p15[37] = x7
    p15[38] = y7
    p15[39] = z8
    v159 = create(x, y, z2)
    x7 = v159.x
    y7 = v159.y
    z8 = v159.z

    if x < 1.1754943508222875E-38 and x > -1.1754943508222875E-38 and x ~= 0 then
        buffer.writeu32(v142, 0, to_bits(x))
        x7 = buffer.readf32(v142, 0)
    end

    if y < 1.1754943508222875E-38 and y > -1.1754943508222875E-38 and y ~= 0 then
        buffer.writeu32(v142, 0, to_bits(y))
        y7 = buffer.readf32(v142, 0)
    end

    if z2 < 1.1754943508222875E-38 and z2 > -1.1754943508222875E-38 and z2 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(z2))
        z8 = buffer.readf32(v142, 0)
    end

    p15[49] = x7
    p15[50] = y7
    p15[51] = z8
    v159 = create(x2, y2, z3)
    x7 = v159.x
    y7 = v159.y
    z8 = v159.z

    if x2 < 1.1754943508222875E-38 and x2 > -1.1754943508222875E-38 and x2 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(x2))
        x7 = buffer.readf32(v142, 0)
    end

    if y2 < 1.1754943508222875E-38 and y2 > -1.1754943508222875E-38 and y2 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(y2))
        y7 = buffer.readf32(v142, 0)
    end

    if z3 < 1.1754943508222875E-38 and z3 > -1.1754943508222875E-38 and z3 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(z3))
        z8 = buffer.readf32(v142, 0)
    end

    p15[53] = x7
    p15[54] = y7
    p15[55] = z8
    v159 = create(x3, y3, z4)
    x7 = v159.x
    y7 = v159.y
    z8 = v159.z

    if x3 < 1.1754943508222875E-38 and x3 > -1.1754943508222875E-38 and x3 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(x3))
        x7 = buffer.readf32(v142, 0)
    end

    if y3 < 1.1754943508222875E-38 and y3 > -1.1754943508222875E-38 and y3 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(y3))
        y7 = buffer.readf32(v142, 0)
    end

    if z4 < 1.1754943508222875E-38 and z4 > -1.1754943508222875E-38 and z4 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(z4))
        z8 = buffer.readf32(v142, 0)
    end

    p15[57] = x7
    p15[58] = y7
    p15[59] = z8
    v159 = create(x4, y4, z5)
    x7 = v159.x
    y7 = v159.y
    z8 = v159.z

    if x4 < 1.1754943508222875E-38 and x4 > -1.1754943508222875E-38 and x4 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(x4))
        x7 = buffer.readf32(v142, 0)
    end

    if y4 < 1.1754943508222875E-38 and y4 > -1.1754943508222875E-38 and y4 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(y4))
        y7 = buffer.readf32(v142, 0)
    end

    if z5 < 1.1754943508222875E-38 and z5 > -1.1754943508222875E-38 and z5 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(z5))
        z8 = buffer.readf32(v142, 0)
    end

    p15[61] = x7
    p15[62] = y7
    p15[63] = z8
    v159 = create(x5, y5, z6)
    x7 = v159.x
    y7 = v159.y
    z8 = v159.z

    if x5 < 1.1754943508222875E-38 and x5 > -1.1754943508222875E-38 and x5 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(x5))
        x7 = buffer.readf32(v142, 0)
    end

    if y5 < 1.1754943508222875E-38 and y5 > -1.1754943508222875E-38 and y5 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(y5))
        y7 = buffer.readf32(v142, 0)
    end

    if z6 < 1.1754943508222875E-38 and z6 > -1.1754943508222875E-38 and z6 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(z6))
        z8 = buffer.readf32(v142, 0)
    end

    p15[65] = x7
    p15[66] = y7
    p15[67] = z8
    v159 = create(x6, y6, z7)
    x7 = v159.x
    y7 = v159.y
    z8 = v159.z

    if x6 < 1.1754943508222875E-38 and x6 > -1.1754943508222875E-38 and x6 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(x6))
        x7 = buffer.readf32(v142, 0)
    end

    if y6 < 1.1754943508222875E-38 and y6 > -1.1754943508222875E-38 and y6 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(y6))
        y7 = buffer.readf32(v142, 0)
    end

    if z7 < 1.1754943508222875E-38 and z7 > -1.1754943508222875E-38 and z7 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(z7))
        z8 = buffer.readf32(v142, 0)
    end

    p15[69] = x7
    p15[70] = y7
    p15[71] = z8
    arm_b = p16.linear_target_impulse
    v156 = arm_b[1]
    v157 = arm_b[2]
    v158 = arm_b[3]
    v159 = create(v156, v157, v158)
    x7 = v159.x
    y7 = v159.y
    z8 = v159.z

    if v156 < 1.1754943508222875E-38 and v156 > -1.1754943508222875E-38 and v156 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(v156))
        x7 = buffer.readf32(v142, 0)
    end

    if v157 < 1.1754943508222875E-38 and v157 > -1.1754943508222875E-38 and v157 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(v157))
        y7 = buffer.readf32(v142, 0)
    end

    if v158 < 1.1754943508222875E-38 and v158 > -1.1754943508222875E-38 and v158 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(v158))
        z8 = buffer.readf32(v142, 0)
    end

    p15[41] = x7
    p15[42] = y7
    p15[43] = z8
    arm_b = p16.angular_target_impulse
    v156 = arm_b[1]
    v157 = arm_b[2]
    v158 = arm_b[3]
    v159 = create(v156, v157, v158)
    x7 = v159.x
    y7 = v159.y
    z8 = v159.z

    if v156 < 1.1754943508222875E-38 and v156 > -1.1754943508222875E-38 and v156 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(v156))
        x7 = buffer.readf32(v142, 0)
    end

    if v157 < 1.1754943508222875E-38 and v157 > -1.1754943508222875E-38 and v157 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(v157))
        y7 = buffer.readf32(v142, 0)
    end

    if v158 < 1.1754943508222875E-38 and v158 > -1.1754943508222875E-38 and v158 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(v158))
        z8 = buffer.readf32(v142, 0)
    end

    p15[45] = x7
    p15[46] = y7
    p15[47] = z8
    arm_b = p16.linear_maximum_impulse
    v156 = arm_b[1]
    v157 = arm_b[2]
    v158 = arm_b[3]
    v159 = create(v156, v157, v158)
    x7 = v159.x
    y7 = v159.y
    z8 = v159.z

    if v156 < 1.1754943508222875E-38 and v156 > -1.1754943508222875E-38 and v156 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(v156))
        x7 = buffer.readf32(v142, 0)
    end

    if v157 < 1.1754943508222875E-38 and v157 > -1.1754943508222875E-38 and v157 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(v157))
        y7 = buffer.readf32(v142, 0)
    end

    if v158 < 1.1754943508222875E-38 and v158 > -1.1754943508222875E-38 and v158 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(v158))
        z8 = buffer.readf32(v142, 0)
    end

    p15[28] = x7
    p15[32] = y7
    p15[44] = z8
    arm_b = p16.angular_maximum_impulse
    v156 = arm_b[1]
    v157 = arm_b[2]
    v158 = arm_b[3]
    v159 = create(v156, v157, v158)
    x7 = v159.x
    y7 = v159.y
    z8 = v159.z

    if v156 < 1.1754943508222875E-38 and v156 > -1.1754943508222875E-38 and v156 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(v156))
        x7 = buffer.readf32(v142, 0)
    end

    if v157 < 1.1754943508222875E-38 and v157 > -1.1754943508222875E-38 and v157 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(v157))
        y7 = buffer.readf32(v142, 0)
    end

    if v158 < 1.1754943508222875E-38 and v158 > -1.1754943508222875E-38 and v158 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(v158))
        z8 = buffer.readf32(v142, 0)
    end

    p15[36] = x7
    p15[40] = y7
    p15[48] = z8
    v156 = p16.linear_softness
    v157 = p16.angular_softness

    local v160 = create(v156, v157, 0)

    v158 = v160.x
    x7 = v160.y

    if v156 < 1.1754943508222875E-38 and v156 > -1.1754943508222875E-38 and v156 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(v156))
        v158 = buffer.readf32(v142, 0)
    end

    if v157 < 1.1754943508222875E-38 and v157 > -1.1754943508222875E-38 and v157 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(v157))
        x7 = buffer.readf32(v142, 0)
    end

    p15[12] = v158
    p15[16] = x7
    p15[4] = 0
    p15[8] = 0
    p15[20] = 0
    p15[24] = 0
    p15[52] = 0
    p15[56] = 0
    p15[60] = 0
    p15[64] = 0
    p15[68] = 0
    p15[72] = 0
    y4 = p16.frame_a_body

    local split, x8

    if bit32.band(y4.state, 4) == 0 then
        p15[73] = 0
        p15[74] = 0
        p15[75] = 0
        p15[76] = 0
        p15[77] = 0
        p15[78] = 0
        p15[79] = 0
        p15[80] = 0
        p15[81] = 0
        p15[82] = 0
        p15[83] = 0
    else
        x4 = y4.world_inverse_inertia
        v156 = x4.full
        split = x4.split
        v158 = v156.x

        local y, z = v156.y, v156.z

        z8 = create(v158, y, z)
        x8 = z8.x

        local y2, z2 = z8.y, z8.z

        if v158 < 1.1754943508222875E-38 and v158 > -1.1754943508222875E-38 and v158 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(v158))
            x8 = buffer.readf32(v142, 0)
        end

        if y < 1.1754943508222875E-38 and y > -1.1754943508222875E-38 and y ~= 0 then
            buffer.writeu32(v142, 0, to_bits(y))
            y2 = buffer.readf32(v142, 0)
        end

        if z < 1.1754943508222875E-38 and z > -1.1754943508222875E-38 and z ~= 0 then
            buffer.writeu32(v142, 0, to_bits(z))
            z2 = buffer.readf32(v142, 0)
        end

        p15[73] = x8
        p15[74] = y2
        p15[77] = y2
        p15[75] = z2
        p15[81] = z2
        v158 = split.y
        y = split.z
        z = split.x
        z8 = create(v158, y, z)
        x8 = z8.x
        y2 = z8.y
        z2 = z8.z

        if v158 < 1.1754943508222875E-38 and v158 > -1.1754943508222875E-38 and v158 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(v158))
            x8 = buffer.readf32(v142, 0)
        end

        if y < 1.1754943508222875E-38 and y > -1.1754943508222875E-38 and y ~= 0 then
            buffer.writeu32(v142, 0, to_bits(y))
            y2 = buffer.readf32(v142, 0)
        end

        if z < 1.1754943508222875E-38 and z > -1.1754943508222875E-38 and z ~= 0 then
            buffer.writeu32(v142, 0, to_bits(z))
            z2 = buffer.readf32(v142, 0)
        end

        p15[78] = x8
        p15[79] = y2
        p15[82] = y2
        p15[83] = z2
        split = y4.inverse_mass
        x3 = create(split, 0, 0).x

        if split < 1.1754943508222875E-38 and split > -1.1754943508222875E-38 and split ~= 0 then
            buffer.writeu32(v142, 0, to_bits(split))
            x3 = buffer.readf32(v142, 0)
        end

        p15[76] = x3
        p15[80] = 0
    end

    p15[84] = 0
    y2 = p16.frame_b_body

    local split2

    if bit32.band(y2.state, 4) == 0 then
        p15[85] = 0
        p15[86] = 0
        p15[87] = 0
        p15[88] = 0
        p15[89] = 0
        p15[90] = 0
        p15[91] = 0
        p15[92] = 0
        p15[93] = 0
        p15[94] = 0
        p15[95] = 0
    else
        x2 = y2.world_inverse_inertia
        v156 = x2.full
        split2 = x2.split
        v158 = v156.x

        local y, z = v156.y, v156.z

        x8 = create(v158, y, z)

        local x3, y3, z2 = x8.x, x8.y, x8.z

        if v158 < 1.1754943508222875E-38 and v158 > -1.1754943508222875E-38 and v158 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(v158))
            x3 = buffer.readf32(v142, 0)
        end

        if y < 1.1754943508222875E-38 and y > -1.1754943508222875E-38 and y ~= 0 then
            buffer.writeu32(v142, 0, to_bits(y))
            y3 = buffer.readf32(v142, 0)
        end

        if z < 1.1754943508222875E-38 and z > -1.1754943508222875E-38 and z ~= 0 then
            buffer.writeu32(v142, 0, to_bits(z))
            z2 = buffer.readf32(v142, 0)
        end

        p15[85] = x3
        p15[86] = y3
        p15[89] = y3
        p15[87] = z2
        p15[93] = z2
        v158 = split2.y
        y = split2.z
        z = split2.x
        x8 = create(v158, y, z)
        x3 = x8.x
        y3 = x8.y
        z2 = x8.z

        if v158 < 1.1754943508222875E-38 and v158 > -1.1754943508222875E-38 and v158 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(v158))
            x3 = buffer.readf32(v142, 0)
        end

        if y < 1.1754943508222875E-38 and y > -1.1754943508222875E-38 and y ~= 0 then
            buffer.writeu32(v142, 0, to_bits(y))
            y3 = buffer.readf32(v142, 0)
        end

        if z < 1.1754943508222875E-38 and z > -1.1754943508222875E-38 and z ~= 0 then
            buffer.writeu32(v142, 0, to_bits(z))
            z2 = buffer.readf32(v142, 0)
        end

        p15[90] = x3
        p15[91] = y3
        p15[94] = y3
        p15[95] = z2
        split2 = y2.inverse_mass
        x = create(split2, 0, 0).x

        if split2 < 1.1754943508222875E-38 and split2 > -1.1754943508222875E-38 and split2 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(split2))
            x = buffer.readf32(v142, 0)
        end

        p15[88] = x
        p15[92] = 0
    end

    p15[96] = 0
    v156 = -p15[85]
    split2 = -p15[86]
    v158 = -p15[87]
    p15[97] = v156
    p15[98] = split2
    p15[99] = v158
    v156 = -p15[89]
    split2 = -p15[90]
    v158 = -p15[91]
    p15[100] = v156
    p15[101] = split2
    p15[102] = v158
    v156 = -p15[93]
    split2 = -p15[94]
    v158 = -p15[95]
    p15[103] = v156
    p15[104] = split2
    p15[105] = v158

    return y4.reaction_index, y2.reaction_index
end

function t1.drive_into_b3(p17, p18) -- line: 710
    -- upvalues: to_bits (copy), create (copy), v142 (copy)
    local arm_a, arm_b = p18.arm_a, p18.arm_b
    local x, y, z = arm_a.x, arm_a.y, arm_a.z
    local v161 = create(x, y, z)
    local x2, y2, z2 = v161.x, v161.y, v161.z
    local v162 = x2
    local v163 = y2
    local v164 = z2

    if x2 == 0 or y2 == 0 or z2 == 0 then
        if x < 1.1754943508222875E-38 and x > -1.1754943508222875E-38 and x ~= 0 then
            buffer.writeu32(v142, 0, to_bits(x))
            v162 = buffer.readf32(v142, 0)
        end

        if y < 1.1754943508222875E-38 and y > -1.1754943508222875E-38 and y ~= 0 then
            buffer.writeu32(v142, 0, to_bits(y))
            v163 = buffer.readf32(v142, 0)
        end

        if z < 1.1754943508222875E-38 and z > -1.1754943508222875E-38 and z ~= 0 then
            buffer.writeu32(v142, 0, to_bits(z))
            v164 = buffer.readf32(v142, 0)
        end
    end

    p17[1] = v162
    p17[2] = v163
    p17[3] = v164
    x = arm_b.x
    y = arm_b.y
    z = arm_b.z

    local v165 = create(x, y, z)

    v161 = v165.x
    v162 = v165.y
    v163 = v165.z

    local v166 = v161
    local v167 = v162
    local v168 = v163

    if v161 == 0 or v162 == 0 or v163 == 0 then
        if x < 1.1754943508222875E-38 and x > -1.1754943508222875E-38 and x ~= 0 then
            buffer.writeu32(v142, 0, to_bits(x))
            v166 = buffer.readf32(v142, 0)
        end

        if y < 1.1754943508222875E-38 and y > -1.1754943508222875E-38 and y ~= 0 then
            buffer.writeu32(v142, 0, to_bits(y))
            v167 = buffer.readf32(v142, 0)
        end

        if z < 1.1754943508222875E-38 and z > -1.1754943508222875E-38 and z ~= 0 then
            buffer.writeu32(v142, 0, to_bits(z))
            v168 = buffer.readf32(v142, 0)
        end
    end

    p17[5] = v166
    p17[6] = v167
    p17[7] = v168
    arm_b = p18.accumulated_linear_impulse
    x = arm_b[1]
    y = arm_b[2]
    z = arm_b[3]
    v166 = create(x, y, z)
    v167 = v166.x
    v168 = v166.y
    z2 = v166.z

    local v169 = v167
    local v170 = v168
    local v171 = z2

    if v167 == 0 or v168 == 0 or z2 == 0 then
        if x < 1.1754943508222875E-38 and x > -1.1754943508222875E-38 and x ~= 0 then
            buffer.writeu32(v142, 0, to_bits(x))
            v169 = buffer.readf32(v142, 0)
        end

        if y < 1.1754943508222875E-38 and y > -1.1754943508222875E-38 and y ~= 0 then
            buffer.writeu32(v142, 0, to_bits(y))
            v170 = buffer.readf32(v142, 0)
        end

        if z < 1.1754943508222875E-38 and z > -1.1754943508222875E-38 and z ~= 0 then
            buffer.writeu32(v142, 0, to_bits(z))
            v171 = buffer.readf32(v142, 0)
        end
    end

    p17[9] = v169
    p17[10] = v170
    p17[11] = v171
    arm_b = p18.accumulated_angular_impulse
    x = arm_b[1]
    y = arm_b[2]
    z = arm_b[3]
    v166 = create(x, y, z)
    v169 = v166.x
    v170 = v166.y
    v171 = v166.z

    local v172 = v169
    local v173 = v170
    local v174 = v171

    if v169 == 0 or v170 == 0 or v171 == 0 then
        if x < 1.1754943508222875E-38 and x > -1.1754943508222875E-38 and x ~= 0 then
            buffer.writeu32(v142, 0, to_bits(x))
            v172 = buffer.readf32(v142, 0)
        end

        if y < 1.1754943508222875E-38 and y > -1.1754943508222875E-38 and y ~= 0 then
            buffer.writeu32(v142, 0, to_bits(y))
            v173 = buffer.readf32(v142, 0)
        end

        if z < 1.1754943508222875E-38 and z > -1.1754943508222875E-38 and z ~= 0 then
            buffer.writeu32(v142, 0, to_bits(z))
            v174 = buffer.readf32(v142, 0)
        end
    end

    p17[13] = v172
    p17[14] = v173
    p17[15] = v174
    x = p18.linear_axes[1]
    y = p18.linear_axes[2]
    z = p18.linear_axes[3]
    v166 = p18.angular_axes[1]
    v172 = p18.angular_axes[2]
    v173 = p18.angular_axes[3]
    v174 = p18.linear_inverse_effective_mass

    local angular_inverse_effective_mass = p18.angular_inverse_effective_mass
    local v175 = v174[1]
    local v176 = v174[2]
    local v177 = v174[3]
    local v178 = angular_inverse_effective_mass[1]
    local v179 = angular_inverse_effective_mass[2]
    local v180 = angular_inverse_effective_mass[3]
    local x3, y3, z3 = x.x, x.y, x.z
    local x4, y4, z4 = y.x, y.y, y.z
    local x5, y5, z5 = z.x, z.y, z.z
    local x6, y6, z6 = v166.x, v166.y, v166.z
    local x7, y7, z7 = v172.x, v172.y, v172.z
    local x8, y8, z8 = v173.x, v173.y, v173.z
    local v181 = x3 * v175
    local v182 = x4 * v176
    local v183 = x5 * v177
    local v184 = create(v181, v182, v183)
    local x9, y9, z9 = v184.x, v184.y, v184.z
    local v185 = x9
    local v186 = y9
    local v187 = z9

    if x9 == 0 or y9 == 0 or z9 == 0 then
        if v181 < 1.1754943508222875E-38 and v181 > -1.1754943508222875E-38 and v181 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(v181))
            v185 = buffer.readf32(v142, 0)
        end

        if v182 < 1.1754943508222875E-38 and v182 > -1.1754943508222875E-38 and v182 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(v182))
            v186 = buffer.readf32(v142, 0)
        end

        if v183 < 1.1754943508222875E-38 and v183 > -1.1754943508222875E-38 and v183 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(v183))
            v187 = buffer.readf32(v142, 0)
        end
    end

    p17[17] = v185
    p17[18] = v186
    p17[19] = v187
    v181 = y3 * v175
    v182 = y4 * v176
    v183 = y5 * v177
    x9 = create(v181, v182, v183)
    v185 = x9.x
    v186 = x9.y
    v187 = x9.z

    local v188 = v185
    local v189 = v186
    local v190 = v187

    if v185 == 0 or v186 == 0 or v187 == 0 then
        if v181 < 1.1754943508222875E-38 and v181 > -1.1754943508222875E-38 and v181 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(v181))
            v188 = buffer.readf32(v142, 0)
        end

        if v182 < 1.1754943508222875E-38 and v182 > -1.1754943508222875E-38 and v182 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(v182))
            v189 = buffer.readf32(v142, 0)
        end

        if v183 < 1.1754943508222875E-38 and v183 > -1.1754943508222875E-38 and v183 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(v183))
            v190 = buffer.readf32(v142, 0)
        end
    end

    p17[25] = v188
    p17[26] = v189
    p17[27] = v190
    v181 = z3 * v175
    v182 = z4 * v176
    v183 = z5 * v177
    v185 = create(v181, v182, v183)
    v188 = v185.x
    v189 = v185.y
    v190 = v185.z

    local v191 = v188
    local v192 = v189
    local v193 = v190

    if v188 == 0 or v189 == 0 or v190 == 0 then
        if v181 < 1.1754943508222875E-38 and v181 > -1.1754943508222875E-38 and v181 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(v181))
            v191 = buffer.readf32(v142, 0)
        end

        if v182 < 1.1754943508222875E-38 and v182 > -1.1754943508222875E-38 and v182 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(v182))
            v192 = buffer.readf32(v142, 0)
        end

        if v183 < 1.1754943508222875E-38 and v183 > -1.1754943508222875E-38 and v183 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(v183))
            v193 = buffer.readf32(v142, 0)
        end
    end

    p17[33] = v191
    p17[34] = v192
    p17[35] = v193
    v181 = x6 * v178
    v182 = x7 * v179
    v183 = x8 * v180
    v188 = create(v181, v182, v183)
    v191 = v188.x
    v192 = v188.y
    v193 = v188.z

    local v194 = v191
    local v195 = v192
    local v196 = v193

    if v191 == 0 or v192 == 0 or v193 == 0 then
        if v181 < 1.1754943508222875E-38 and v181 > -1.1754943508222875E-38 and v181 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(v181))
            v194 = buffer.readf32(v142, 0)
        end

        if v182 < 1.1754943508222875E-38 and v182 > -1.1754943508222875E-38 and v182 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(v182))
            v195 = buffer.readf32(v142, 0)
        end

        if v183 < 1.1754943508222875E-38 and v183 > -1.1754943508222875E-38 and v183 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(v183))
            v196 = buffer.readf32(v142, 0)
        end
    end

    p17[21] = v194
    p17[22] = v195
    p17[23] = v196
    v181 = y6 * v178
    v182 = y7 * v179
    v183 = y8 * v180
    v191 = create(v181, v182, v183)
    v194 = v191.x
    v195 = v191.y
    v196 = v191.z

    local v197 = v194
    local v198 = v195
    local v199 = v196

    if v194 == 0 or v195 == 0 or v196 == 0 then
        if v181 < 1.1754943508222875E-38 and v181 > -1.1754943508222875E-38 and v181 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(v181))
            v197 = buffer.readf32(v142, 0)
        end

        if v182 < 1.1754943508222875E-38 and v182 > -1.1754943508222875E-38 and v182 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(v182))
            v198 = buffer.readf32(v142, 0)
        end

        if v183 < 1.1754943508222875E-38 and v183 > -1.1754943508222875E-38 and v183 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(v183))
            v199 = buffer.readf32(v142, 0)
        end
    end

    p17[29] = v197
    p17[30] = v198
    p17[31] = v199
    v181 = z6 * v178
    v182 = z7 * v179
    v183 = z8 * v180
    v194 = create(v181, v182, v183)
    v197 = v194.x
    v198 = v194.y
    v199 = v194.z

    local v200 = v197
    local v201 = v198
    local v202 = v199

    if v197 == 0 or v198 == 0 or v199 == 0 then
        if v181 < 1.1754943508222875E-38 and v181 > -1.1754943508222875E-38 and v181 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(v181))
            v200 = buffer.readf32(v142, 0)
        end

        if v182 < 1.1754943508222875E-38 and v182 > -1.1754943508222875E-38 and v182 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(v182))
            v201 = buffer.readf32(v142, 0)
        end

        if v183 < 1.1754943508222875E-38 and v183 > -1.1754943508222875E-38 and v183 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(v183))
            v202 = buffer.readf32(v142, 0)
        end
    end

    p17[37] = v200
    p17[38] = v201
    p17[39] = v202
    v197 = create(x3, y3, z3)
    v200 = v197.x
    v201 = v197.y
    v202 = v197.z

    local v203 = v200
    local v204 = v201
    local v205 = v202

    if v200 == 0 or v201 == 0 or v202 == 0 then
        if x3 < 1.1754943508222875E-38 and x3 > -1.1754943508222875E-38 and x3 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(x3))
            v203 = buffer.readf32(v142, 0)
        end

        if y3 < 1.1754943508222875E-38 and y3 > -1.1754943508222875E-38 and y3 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(y3))
            v204 = buffer.readf32(v142, 0)
        end

        if z3 < 1.1754943508222875E-38 and z3 > -1.1754943508222875E-38 and z3 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(z3))
            v205 = buffer.readf32(v142, 0)
        end
    end

    p17[49] = v203
    p17[50] = v204
    p17[51] = v205
    v200 = create(x4, y4, z4)
    v203 = v200.x
    v204 = v200.y
    v205 = v200.z

    local v206 = v203
    local v207 = v204
    local v208 = v205

    if v203 == 0 or v204 == 0 or v205 == 0 then
        if x4 < 1.1754943508222875E-38 and x4 > -1.1754943508222875E-38 and x4 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(x4))
            v206 = buffer.readf32(v142, 0)
        end

        if y4 < 1.1754943508222875E-38 and y4 > -1.1754943508222875E-38 and y4 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(y4))
            v207 = buffer.readf32(v142, 0)
        end

        if z4 < 1.1754943508222875E-38 and z4 > -1.1754943508222875E-38 and z4 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(z4))
            v208 = buffer.readf32(v142, 0)
        end
    end

    p17[53] = v206
    p17[54] = v207
    p17[55] = v208
    v203 = create(x5, y5, z5)
    v206 = v203.x
    v207 = v203.y
    v208 = v203.z

    local v209 = v206
    local v210 = v207
    local v211 = v208

    if v206 == 0 or v207 == 0 or v208 == 0 then
        if x5 < 1.1754943508222875E-38 and x5 > -1.1754943508222875E-38 and x5 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(x5))
            v209 = buffer.readf32(v142, 0)
        end

        if y5 < 1.1754943508222875E-38 and y5 > -1.1754943508222875E-38 and y5 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(y5))
            v210 = buffer.readf32(v142, 0)
        end

        if z5 < 1.1754943508222875E-38 and z5 > -1.1754943508222875E-38 and z5 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(z5))
            v211 = buffer.readf32(v142, 0)
        end
    end

    p17[57] = v209
    p17[58] = v210
    p17[59] = v211
    v206 = create(x6, y6, z6)
    v209 = v206.x
    v210 = v206.y
    v211 = v206.z

    local v212 = v209
    local v213 = v210
    local v214 = v211

    if v209 == 0 or v210 == 0 or v211 == 0 then
        if x6 < 1.1754943508222875E-38 and x6 > -1.1754943508222875E-38 and x6 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(x6))
            v212 = buffer.readf32(v142, 0)
        end

        if y6 < 1.1754943508222875E-38 and y6 > -1.1754943508222875E-38 and y6 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(y6))
            v213 = buffer.readf32(v142, 0)
        end

        if z6 < 1.1754943508222875E-38 and z6 > -1.1754943508222875E-38 and z6 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(z6))
            v214 = buffer.readf32(v142, 0)
        end
    end

    p17[61] = v212
    p17[62] = v213
    p17[63] = v214
    v209 = create(x7, y7, z7)
    v212 = v209.x
    v213 = v209.y
    v214 = v209.z

    local v215 = v212
    local v216 = v213
    local v217 = v214

    if v212 == 0 or v213 == 0 or v214 == 0 then
        if x7 < 1.1754943508222875E-38 and x7 > -1.1754943508222875E-38 and x7 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(x7))
            v215 = buffer.readf32(v142, 0)
        end

        if y7 < 1.1754943508222875E-38 and y7 > -1.1754943508222875E-38 and y7 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(y7))
            v216 = buffer.readf32(v142, 0)
        end

        if z7 < 1.1754943508222875E-38 and z7 > -1.1754943508222875E-38 and z7 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(z7))
            v217 = buffer.readf32(v142, 0)
        end
    end

    p17[65] = v215
    p17[66] = v216
    p17[67] = v217
    v212 = create(x8, y8, z8)
    v215 = v212.x
    v216 = v212.y
    v217 = v212.z

    local v218 = v215
    local v219 = v216
    local v220 = v217

    if v215 == 0 or v216 == 0 or v217 == 0 then
        if x8 < 1.1754943508222875E-38 and x8 > -1.1754943508222875E-38 and x8 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(x8))
            v218 = buffer.readf32(v142, 0)
        end

        if y8 < 1.1754943508222875E-38 and y8 > -1.1754943508222875E-38 and y8 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(y8))
            v219 = buffer.readf32(v142, 0)
        end

        if z8 < 1.1754943508222875E-38 and z8 > -1.1754943508222875E-38 and z8 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(z8))
            v220 = buffer.readf32(v142, 0)
        end
    end

    p17[69] = v218
    p17[70] = v219
    p17[71] = v220
    arm_b = p18.linear_target_impulse
    v181 = arm_b[1]
    v182 = arm_b[2]
    v183 = arm_b[3]
    v215 = create(v181, v182, v183)
    v218 = v215.x
    v219 = v215.y
    v220 = v215.z

    local v221 = v218
    local v222 = v219
    local v223 = v220

    if v218 == 0 or v219 == 0 or v220 == 0 then
        if v181 < 1.1754943508222875E-38 and v181 > -1.1754943508222875E-38 and v181 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(v181))
            v221 = buffer.readf32(v142, 0)
        end

        if v182 < 1.1754943508222875E-38 and v182 > -1.1754943508222875E-38 and v182 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(v182))
            v222 = buffer.readf32(v142, 0)
        end

        if v183 < 1.1754943508222875E-38 and v183 > -1.1754943508222875E-38 and v183 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(v183))
            v223 = buffer.readf32(v142, 0)
        end
    end

    p17[41] = v221
    p17[42] = v222
    p17[43] = v223
    arm_b = p18.angular_target_impulse
    v181 = arm_b[1]
    v182 = arm_b[2]
    v183 = arm_b[3]
    v218 = create(v181, v182, v183)
    v221 = v218.x
    v222 = v218.y
    v223 = v218.z

    local v224 = v221
    local v225 = v222
    local v226 = v223

    if v221 == 0 or v222 == 0 or v223 == 0 then
        if v181 < 1.1754943508222875E-38 and v181 > -1.1754943508222875E-38 and v181 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(v181))
            v224 = buffer.readf32(v142, 0)
        end

        if v182 < 1.1754943508222875E-38 and v182 > -1.1754943508222875E-38 and v182 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(v182))
            v225 = buffer.readf32(v142, 0)
        end

        if v183 < 1.1754943508222875E-38 and v183 > -1.1754943508222875E-38 and v183 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(v183))
            v226 = buffer.readf32(v142, 0)
        end
    end

    p17[45] = v224
    p17[46] = v225
    p17[47] = v226
    arm_b = p18.linear_maximum_impulse
    v181 = arm_b[1]
    v182 = arm_b[2]
    v183 = arm_b[3]
    v221 = create(v181, v182, v183)
    v224 = v221.x
    v225 = v221.y
    v226 = v221.z

    local v227 = v224
    local v228 = v225
    local v229 = v226

    if v224 == 0 or v225 == 0 or v226 == 0 then
        if v181 < 1.1754943508222875E-38 and v181 > -1.1754943508222875E-38 and v181 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(v181))
            v227 = buffer.readf32(v142, 0)
        end

        if v182 < 1.1754943508222875E-38 and v182 > -1.1754943508222875E-38 and v182 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(v182))
            v228 = buffer.readf32(v142, 0)
        end

        if v183 < 1.1754943508222875E-38 and v183 > -1.1754943508222875E-38 and v183 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(v183))
            v229 = buffer.readf32(v142, 0)
        end
    end

    p17[28] = v227
    p17[32] = v228
    p17[44] = v229
    arm_b = p18.angular_maximum_impulse
    v181 = arm_b[1]
    v182 = arm_b[2]
    v183 = arm_b[3]
    v224 = create(v181, v182, v183)
    v227 = v224.x
    v228 = v224.y
    v229 = v224.z

    local v230 = v227
    local v231 = v228
    local v232 = v229

    if v227 == 0 or v228 == 0 or v229 == 0 then
        if v181 < 1.1754943508222875E-38 and v181 > -1.1754943508222875E-38 and v181 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(v181))
            v230 = buffer.readf32(v142, 0)
        end

        if v182 < 1.1754943508222875E-38 and v182 > -1.1754943508222875E-38 and v182 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(v182))
            v231 = buffer.readf32(v142, 0)
        end

        if v183 < 1.1754943508222875E-38 and v183 > -1.1754943508222875E-38 and v183 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(v183))
            v232 = buffer.readf32(v142, 0)
        end
    end

    p17[36] = v230
    p17[40] = v231
    p17[48] = v232
    v181 = p18.linear_softness
    v182 = p18.angular_softness

    local v233 = create(v181, v182, 0)

    v183 = v233.x
    v230 = v233.y

    if v181 < 1.1754943508222875E-38 and v181 > -1.1754943508222875E-38 and v181 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(v181))
        v183 = buffer.readf32(v142, 0)
    end

    if v182 < 1.1754943508222875E-38 and v182 > -1.1754943508222875E-38 and v182 ~= 0 then
        buffer.writeu32(v142, 0, to_bits(v182))
        v230 = buffer.readf32(v142, 0)
    end

    p17[12] = v183
    p17[16] = v230
    p17[4] = 0
    p17[8] = 0
    p17[20] = 0
    p17[24] = 0
    p17[52] = 0
    p17[56] = 0
    p17[60] = 0
    p17[64] = 0
    p17[68] = 0
    p17[72] = 0
    y6 = p18.frame_a_body
    v182 = y6.state

    local v234 = false
    local v235 = false
    local v236 = false
    local v237 = false

    if bit32.band(v182, 4) == 0 then
        v237 = true
    else
        v234 = true
    end

    local split, x10, y10, z10, x11, y11, z11

    if v234 then
        x6 = y6.world_inverse_inertia
        v181 = x6.full
        split = x6.split
        x10 = v181.x
        y10 = v181.y
        z10 = v181.z
        v232 = create(x10, y10, z10)
        x11 = v232.x
        y11 = v232.y
        z11 = v232.z

        if x11 == 0 then
            v236 = true
        else
            v235 = true
        end
    end

    v234 = false

    if v235 then
        if y11 == 0 then
            v236 = true
        else
            v234 = true
        end
    end

    v235 = false

    local v238, v239, v240

    if v234 then
        if z11 == 0 then
            v236 = true
        else
            v238 = x11
            v239 = y11
            v240 = z11
            v237 = false
        end
    end

    v234 = false

    local v241

    if v236 then
        if x10 < 1.1754943508222875E-38 then
            v234 = true
        else
            v241 = x11
            v235 = true
        end
    end

    v236 = false

    if v234 then
        if x10 > -1.1754943508222875E-38 then
            v236 = true
        else
            v241 = x11
            v235 = true
        end
    end

    v234 = false

    if v236 then
        if x10 == 0 then
            v241 = x11
            v235 = true
        else
            v234 = true
        end
    end

    v236 = false

    if v234 then
        buffer.writeu32(v142, 0, to_bits(x10))
        v241 = buffer.readf32(v142, 0)
        v235 = true
    end

    v234 = false

    local v242

    if v235 then
        if y10 < 1.1754943508222875E-38 then
            v234 = true
        else
            v242 = y11
            v236 = true
        end
    end

    v235 = false

    if v234 then
        if y10 > -1.1754943508222875E-38 then
            v235 = true
        else
            v242 = y11
            v236 = true
        end
    end

    v234 = false

    if v235 then
        if y10 == 0 then
            v242 = y11
            v236 = true
        else
            v234 = true
        end
    end

    if v234 then
        buffer.writeu32(v142, 0, to_bits(y10))
        v242 = buffer.readf32(v142, 0)
        v236 = true
    end

    v234 = false

    if v236 then
        if z10 < 1.1754943508222875E-38 then
            v234 = true
        else
            v238 = v241
            v239 = v242
            v240 = z11
            v237 = false
        end
    end

    v236 = false

    if v234 then
        if z10 > -1.1754943508222875E-38 then
            v236 = true
        else
            v238 = v241
            v239 = v242
            v240 = z11
            v237 = false
        end
    end

    v234 = false

    if v236 then
        if z10 == 0 then
            v238 = v241
            v239 = v242
            v240 = z11
            v237 = false
        else
            v234 = true
        end
    end

    if v234 then
        buffer.writeu32(v142, 0, to_bits(z10))
        v238 = v241
        v239 = v242
        v240 = buffer.readf32(v142, 0)
        v237 = false
    end

    local v243

    if v237 then
        p17[73] = 0
        p17[74] = 0
        p17[75] = 0
        p17[76] = 0
        p17[77] = 0
        p17[78] = 0
        p17[79] = 0
        p17[80] = 0
        p17[81] = 0
        p17[82] = 0
        p17[83] = 0
    else
        p17[73] = v238
        p17[74] = v239
        p17[77] = v239
        p17[75] = v240
        p17[81] = v240
        x10 = split.y
        y10 = split.z
        z10 = split.x
        v241 = create(x10, y10, z10)
        v238 = v241.x
        v239 = v241.y
        v240 = v241.z
        v243 = v238

        local v244 = v239
        local v245 = v240

        if v238 == 0 or v239 == 0 or v240 == 0 then
            if x10 < 1.1754943508222875E-38 and x10 > -1.1754943508222875E-38 and x10 ~= 0 then
                buffer.writeu32(v142, 0, to_bits(x10))
                v243 = buffer.readf32(v142, 0)
            end

            if y10 < 1.1754943508222875E-38 and y10 > -1.1754943508222875E-38 and y10 ~= 0 then
                buffer.writeu32(v142, 0, to_bits(y10))
                v244 = buffer.readf32(v142, 0)
            end

            if z10 < 1.1754943508222875E-38 and z10 > -1.1754943508222875E-38 and z10 ~= 0 then
                buffer.writeu32(v142, 0, to_bits(z10))
                v245 = buffer.readf32(v142, 0)
            end
        end

        p17[78] = v243
        p17[79] = v244
        p17[82] = v244
        p17[83] = v245
        split = y6.inverse_mass
        x5 = create(split, 0, 0).x

        if split < 1.1754943508222875E-38 and split > -1.1754943508222875E-38 and split ~= 0 then
            buffer.writeu32(v142, 0, to_bits(split))
            x5 = buffer.readf32(v142, 0)
        end

        p17[76] = x5
        p17[80] = 0
    end

    p17[84] = 0
    y4 = p18.frame_b_body
    split = y4.state

    local v246 = false
    local v247 = false
    local v248 = false
    local v249 = false

    if bit32.band(split, 4) == 0 then
        v249 = true
    else
        v246 = true
    end

    local split2, x12, y12, z12, x13, y13, z13

    if v246 then
        x4 = y4.world_inverse_inertia
        v181 = x4.full
        split2 = x4.split
        x12 = v181.x
        y12 = v181.y
        z12 = v181.z
        v243 = create(x12, y12, z12)
        x13 = v243.x
        y13 = v243.y
        z13 = v243.z

        if x13 == 0 then
            v248 = true
        else
            v247 = true
        end
    end

    v246 = false

    if v247 then
        if y13 == 0 then
            v248 = true
        else
            v246 = true
        end
    end

    v247 = false

    local v250, v251, v252

    if v246 then
        if z13 == 0 then
            v248 = true
        else
            v250 = x13
            v251 = y13
            v252 = z13
            v249 = false
        end
    end

    v246 = false

    local v253

    if v248 then
        if x12 < 1.1754943508222875E-38 then
            v246 = true
        else
            v253 = x13
            v247 = true
        end
    end

    v248 = false

    if v246 then
        if x12 > -1.1754943508222875E-38 then
            v248 = true
        else
            v253 = x13
            v247 = true
        end
    end

    v246 = false

    if v248 then
        if x12 == 0 then
            v253 = x13
            v247 = true
        else
            v246 = true
        end
    end

    v248 = false

    if v246 then
        buffer.writeu32(v142, 0, to_bits(x12))
        v253 = buffer.readf32(v142, 0)
        v247 = true
    end

    v246 = false

    local v254

    if v247 then
        if y12 < 1.1754943508222875E-38 then
            v246 = true
        else
            v254 = y13
            v248 = true
        end
    end

    v247 = false

    if v246 then
        if y12 > -1.1754943508222875E-38 then
            v247 = true
        else
            v254 = y13
            v248 = true
        end
    end

    v246 = false

    if v247 then
        if y12 == 0 then
            v254 = y13
            v248 = true
        else
            v246 = true
        end
    end

    if v246 then
        buffer.writeu32(v142, 0, to_bits(y12))
        v254 = buffer.readf32(v142, 0)
        v248 = true
    end

    v246 = false

    if v248 then
        if z12 < 1.1754943508222875E-38 then
            v246 = true
        else
            v250 = v253
            v251 = v254
            v252 = z13
            v249 = false
        end
    end

    v248 = false

    if v246 then
        if z12 > -1.1754943508222875E-38 then
            v248 = true
        else
            v250 = v253
            v251 = v254
            v252 = z13
            v249 = false
        end
    end

    v246 = false

    if v248 then
        if z12 == 0 then
            v250 = v253
            v251 = v254
            v252 = z13
            v249 = false
        else
            v246 = true
        end
    end

    if v246 then
        buffer.writeu32(v142, 0, to_bits(z12))
        v250 = v253
        v251 = v254
        v252 = buffer.readf32(v142, 0)
        v249 = false
    end

    if v249 then
        p17[85] = 0
        p17[86] = 0
        p17[87] = 0
        p17[88] = 0
        p17[89] = 0
        p17[90] = 0
        p17[91] = 0
        p17[92] = 0
        p17[93] = 0
        p17[94] = 0
        p17[95] = 0
    else
        p17[85] = v250
        p17[86] = v251
        p17[89] = v251
        p17[87] = v252
        p17[93] = v252
        x12 = split2.y
        y12 = split2.z
        z12 = split2.x
        v253 = create(x12, y12, z12)
        v250 = v253.x
        v251 = v253.y
        v252 = v253.z

        local v255 = v250
        local v256 = v251
        local v257 = v252

        if v250 == 0 or v251 == 0 or v252 == 0 then
            if x12 < 1.1754943508222875E-38 and x12 > -1.1754943508222875E-38 and x12 ~= 0 then
                buffer.writeu32(v142, 0, to_bits(x12))
                v255 = buffer.readf32(v142, 0)
            end

            if y12 < 1.1754943508222875E-38 and y12 > -1.1754943508222875E-38 and y12 ~= 0 then
                buffer.writeu32(v142, 0, to_bits(y12))
                v256 = buffer.readf32(v142, 0)
            end

            if z12 < 1.1754943508222875E-38 and z12 > -1.1754943508222875E-38 and z12 ~= 0 then
                buffer.writeu32(v142, 0, to_bits(z12))
                v257 = buffer.readf32(v142, 0)
            end
        end

        p17[90] = v255
        p17[91] = v256
        p17[94] = v256
        p17[95] = v257
        split2 = y4.inverse_mass
        x3 = create(split2, 0, 0).x

        if split2 < 1.1754943508222875E-38 and split2 > -1.1754943508222875E-38 and split2 ~= 0 then
            buffer.writeu32(v142, 0, to_bits(split2))
            x3 = buffer.readf32(v142, 0)
        end

        p17[88] = x3
        p17[92] = 0
    end

    p17[96] = 0
    v181 = -p17[85]
    split2 = -p17[86]
    x12 = -p17[87]
    p17[97] = v181
    p17[98] = split2
    p17[99] = x12
    v181 = -p17[89]
    split2 = -p17[90]
    x12 = -p17[91]
    p17[100] = v181
    p17[101] = split2
    p17[102] = x12
    v181 = -p17[93]
    split2 = -p17[94]
    x12 = -p17[95]
    p17[103] = v181
    p17[104] = split2
    p17[105] = x12

    return y6.reaction_index, y4.reaction_index
end

local t4 = {}
local v258 = true

function t1.set_prepared_joints(p19) -- line: 1256
    -- upvalues: v258 (ref)
    local v259 = v258

    v258 = p19

    return v259
end

function t1.register_joint_jacobian(p20) -- line: 1264
    -- upvalues: t4 (copy)
    local v260 = t4[p20]

    if v260 == nil then
        v260 = {
            reaction_a = 0,
            reaction_b = 0,
            epoch = -1,
            prepared = false,
            words = table.create(96, 0),
            floats = table.create(106, 0)
        }
        t4[p20] = v260
    end

    return v260
end

function t1.unregister_joint_jacobian(p21) -- line: 1281
    -- upvalues: t4 (copy)
    t4[p21] = nil
end

function t1.joint(p22, p23) -- line: 1288
    -- upvalues: t4 (copy), v258 (ref)
    local jacobian = p22.jacobian
    local words = jacobian.words
    local v261 = t4[jacobian]

    if v261 ~= nil and v261.epoch ~= p23 and v261.words ~= words and #words == 96 then
        v261.epoch = p23
        table.move(words, 1, 96, 1, v261.words)
        v261.reaction_a = p22.reaction_a
        v261.reaction_b = p22.reaction_b

        local prepared = v261.prepared

        v261.prepared = false

        if prepared ~= words or not v258 then
            return v261, nil
        end

        return v261, v261.floats
    end

    if v261 ~= nil then
        v261.prepared = false
    end

    return {
        words = table.clone(words),
        reaction_a = p22.reaction_a,
        reaction_b = p22.reaction_b
    }
end

function t1.reaction(p24) -- line: 1316
    -- upvalues: t1 (copy)
    local v262 = table.create(16, 0)
    local t5 = {
        p24.linear_displacement,
        p24.position_displacement,
        p24.angular_displacement,
        p24.orientation_displacement
    }

    for i = 0, 3 do
        local v263 = t5[i + 1]

        t1.vector(v262, i, v263, 0)
    end

    return v262
end

function t1.unpack_reaction(p25) -- line: 1332
    -- upvalues: Vector3 (copy), t1 (copy)
    local function v(p26) -- line: 1333
        -- upvalues: p25 (copy), Vector3 (copy), t1 (copy)
        local v264 = t1.read_xyz(p25, p26)

        return Vector3.new(v264[1], v264[2], v264[3])
    end

    local v265 = t1.read_xyz(p25, 0)
    local t6 = {}

    t6.linear_displacement = Vector3.new(v265[1], v265[2], v265[3])

    local v266 = t1.read_xyz(p25, 1)

    t6.position_displacement = Vector3.new(v266[1], v266[2], v266[3])

    local v267 = t1.read_xyz(p25, 2)

    t6.angular_displacement = Vector3.new(v267[1], v267[2], v267[3])

    local v268 = t1.read_xyz(p25, 3)

    t6.orientation_displacement = Vector3.new(v268[1], v268[2], v268[3])

    return t6
end

function t1.read_xyz(p27, p28) -- line: 1345
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p27[p28 * 4 + 0 + 1])

    local v270 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p27[p28 * 4 + 1 + 1])

    local v272 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p27[p28 * 4 + 2 + 1])

    return {
        v270,
        v272,
        (buffer.readf32(v1, 0))
    }
end

function t1.row(p29, p30, p31, p32) -- line: 1353
    -- upvalues: v1 (copy)
    local v274 = p30 * 4 + 1
    local v275 = p31[1]
    local v276

    if v275 ~= 0 and v275 > -1.1754943508222875E-38 and v275 < 1.1754943508222875E-38 then
        local v277 = math.abs(v275) * 7.1362384635298E+44
        local v278 = math.floor(v277)
        local v279 = v277 - v278

        v276 = if v279 > 0.5 or v279 == 0.5 and v278 % 2 == 1 then v278 + 1 else v278

        if v275 < 0 then
            v276 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v275)
        v276 = buffer.readu32(v1, 0)
    end

    p29[v274] = v276

    local v280 = p30 * 4 + 2
    local v281 = p31[2]
    local v282

    if v281 ~= 0 and v281 > -1.1754943508222875E-38 and v281 < 1.1754943508222875E-38 then
        local v283 = math.abs(v281) * 7.1362384635298E+44
        local v284 = math.floor(v283)
        local v285 = v283 - v284

        v282 = if v285 > 0.5 or v285 == 0.5 and v284 % 2 == 1 then v284 + 1 else v284

        if v281 < 0 then
            v282 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v281)
        v282 = buffer.readu32(v1, 0)
    end

    p29[v280] = v282

    local v286 = p30 * 4 + 3
    local v287 = p31[3]
    local v288

    if v287 ~= 0 and v287 > -1.1754943508222875E-38 and v287 < 1.1754943508222875E-38 then
        local v289 = math.abs(v287) * 7.1362384635298E+44
        local v290 = math.floor(v289)
        local v291 = v289 - v290

        v288 = if v291 > 0.5 or v291 == 0.5 and v290 % 2 == 1 then v290 + 1 else v290

        if v287 < 0 then
            v288 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v287)
        v288 = buffer.readu32(v1, 0)
    end

    p29[v286] = v288

    local v292 = p30 * 4 + 4
    local v293

    if p32 ~= 0 and p32 > -1.1754943508222875E-38 and p32 < 1.1754943508222875E-38 then
        local v294 = math.abs(p32) * 7.1362384635298E+44
        local v295 = math.floor(v294)
        local v296 = v294 - v295

        v293 = if v296 > 0.5 or v296 == 0.5 and v295 % 2 == 1 then v295 + 1 else v295

        if p32 < 0 then
            v293 += 2147483648
        end
    else
        buffer.writef32(v1, 0, p32)
        v293 = buffer.readu32(v1, 0)
    end

    p29[v292] = v293
end

function t1.vector(p33, p34, p35, p36) -- line: 1361
    -- upvalues: t1 (copy)
    t1.row(p33, p34, t1.xyz(p35), p36)
end

function t1.xyz(p37) -- line: 1365
    return {
        p37.x,
        p37.y,
        p37.z
    }
end

function t1.inertia_columns(p38) -- line: 1370
    -- upvalues: Vector3 (copy)
    return {
        Vector3.new(p38.full.x, p38.full.y, p38.full.z),
        Vector3.new(p38.full.y, p38.split.y, p38.split.z),
        Vector3.new(p38.full.z, p38.split.z, p38.split.x)
    }
end

return t1
