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

local function rtl_fround(p2) -- line: 16
    -- upvalues: v1 (copy)
    if p2 ~= 0 and p2 > -1.1754943508222875E-38 and p2 < 1.1754943508222875E-38 then
        local v6 = math.abs(p2) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        local v8 = v5 * 1.401298464324817E-45

        if p2 < 0 then
            return -v8
        end

        return v8
    end

    buffer.writef32(v1, 0, p2)

    return (buffer.readf32(v1, 0))
end

local function rtl_is_finite(p3) -- line: 24
    if p3 ~= p3 or p3 == 1e999 then
        return false
    end

    return p3 ~= (-1e999)
end

local import = require(sim.import)
local v9 = import("skate_core/physics/constraint_frames")
local v10 = import("skate_core/physics/native_arithmetic")
local v11 = import("skate_core/physics/drive_parameters")
local v12 = import("skate_core/math")

local function drive_solver() -- line: 36
    -- upvalues: import (copy)
    return import("skate_core/physics/drive_solver")
end

local RetailDriveType = v11.RetailDriveType
local Vector3 = v12.Vector3
local t1 = {}
local is_finite, fround = rt.is_finite, rt.fround

local function fmin(p4, p5) -- line: 51
    if p4 == p4 and (p5 ~= p5 or p4 < p5) then
        return p4
    end

    return p5
end

local function fmax(p6, p7) -- line: 60
    if p6 == p6 and (p7 ~= p7 or p7 < p6) then
        return p6
    end

    return p7
end

local function reciprocal(p8) -- line: 73
    local v13 = 1 / p8
    local v14 = v13 * (-v13 * p8 + 1) + v13

    return v14 * (-v14 * p8 + 1) + v14
end

local function reciprocal_sqrt(p9) -- line: 81
    local v15 = 1 / math.sqrt(p9)
    local v16 = v15 * v15
    local v17 = v15 * 0.5 * (-p9 * v16 + 1) + v15
    local v18 = v17 * v17

    return v17 * 0.5 * (-p9 * v18 + 1) + v17
end

local SoftDrive, HardDrive = RetailDriveType.SoftDrive, RetailDriveType.HardDrive

function t1.build_drive_rows_reference(p10, p11, p12, p13, p14) -- line: 105
    -- upvalues: rt (copy), v1 (copy), import (copy), v9 (copy), v10 (copy), Vector3 (copy), t1 (copy)
    local v19 = import("skate_core/physics/drive_solver")

    if not (p14 == p14 and p14 ~= 1e999 and p14 ~= (-1e999) and p14 > 0) then
        error("assertion failed: time_step.is_finite() && time_step > 0.0", 0)
    end

    local v20 = t1.world_frame(p10, p12.body_a)
    local v21 = t1.world_frame(p11, p12.body_b)
    local v22 = rt.copy(v20.arm)
    local v23 = rt.copy(v21.arm)
    local v24 = v19.basis_columns(v9.basis(v21.orientation))
    local v25 = v9.quaternion_rows(v20.orientation, v21.orientation)
    local t2 = {
        v25.relative.x,
        v25.relative.y,
        v25.relative.z
    }
    local v26 = table.create(3)

    for i = 1, 3 do
        local v27 = t2[i]
        local vector_min, vector_max = v10.vector_min, v10.vector_max
        local v28 = v27 * v27
        local v29

        if v28 ~= 0 and v28 > -1.1754943508222875E-38 and v28 < 1.1754943508222875E-38 then
            local v30 = math.abs(v28) * 7.1362384635298E+44
            local v31 = math.floor(v30)
            local v32 = v30 - v31

            v29 = (if v32 > 0.5 or v32 == 0.5 and v31 % 2 == 1 then v31 + 1 else v31) * 1.401298464324817E-45

            if v28 < 0 then
                v29 = -v29
            end
        else
            buffer.writef32(v1, 0, v28)
            v29 = buffer.readf32(v1, 0)
        end

        v26[i] = vector_min(vector_max(v29, 0), 1)
    end

    local v33 = v26[1] == 1 or v26[2] == 1 or v26[3] == 1
    local v34

    if v33 then
        v34 = table.create(3, 1)
    else
        v34 = table.create(3)
        v34[1] = v9.reciprocal_sqrt(1 - v26[1])
        v34[2] = v9.reciprocal_sqrt(1 - v26[2])
        v34[3] = v9.reciprocal_sqrt(1 - v26[3])
    end

    local t3 = {
        v19.scale(if v33 then v24[1] else v25.axes[1], v34[1]),
        v19.scale(if v33 then v24[2] else v25.axes[2], v34[2]),
        v19.scale(if v33 then v24[3] else v25.axes[3], v34[3])
    }
    local t4 = {
        t2[1] * v34[1] * 2,
        t2[2] * v34[2] * 2,
        t2[3] * v34[3] * 2
    }
    local v35 = v19.sub(v21.position, v20.position)
    local v36 = v19.sub(v19.scale(v19.point_rate(p11.linear_velocity, p11.angular_velocity, v23), p14), v19.scale(v19.point_rate(p10.linear_velocity, p10.angular_velocity, v22), p14))
    local v37 = v19.sub(v19.scale(v19.scale(v19.point_rate(p11.force_acceleration, p11.torque_acceleration, v23), p14), p14), v19.scale(v19.scale(v19.point_rate(p10.force_acceleration, p10.torque_acceleration, v22), p14), p14))
    local v38 = v19.scale(v19.sub(p11.angular_velocity, p10.angular_velocity), p14)
    local v39 = v19.scale(v19.scale(v19.sub(p11.torque_acceleration, p10.torque_acceleration), p14), p14)
    local t5 = {
        v9.reciprocal(t1.linear_effective_mass(p10, p11, v22, v23, v24[1])),
        v9.reciprocal(t1.linear_effective_mass(p10, p11, v22, v23, v24[2])),
        v9.reciprocal(t1.linear_effective_mass(p10, p11, v22, v23, v24[3]))
    }
    local t6 = {
        v9.reciprocal(t1.angular_effective_mass(p10, p11, t3[1])),
        v9.reciprocal(t1.angular_effective_mass(p10, p11, t3[2])),
        v9.reciprocal(t1.angular_effective_mass(p10, p11, t3[3]))
    }
    local v40 = t1.build_coefficients(p13.linear, t1.components_of(v35), t1.components_of(v36), t1.components_of(v37), p14)
    local target_displacement = v40.target_displacement
    local v41 = v19.project(Vector3.new(target_displacement[1], target_displacement[2], target_displacement[3]), v24)
    local v42 = t1.build_coefficients(p13.angular, t4, v19.project(v38, t3), v19.project(v39, t3), p14)
    local v43 = table.create(3)
    local v44 = table.create(3)

    v43[1] = t5[1] * v40.maximum_strength
    v43[2] = t5[2] * v40.maximum_strength
    v43[3] = t5[3] * v40.maximum_strength
    v44[1] = t6[1] * v42.maximum_strength
    v44[2] = t6[2] * v42.maximum_strength
    v44[3] = t6[3] * v42.maximum_strength

    return {
        frame_a_body = p10,
        frame_b_body = p11,
        arm_a = v22,
        arm_b = v23,
        linear_axes = v24,
        angular_axes = t3,
        linear_inverse_effective_mass = t5,
        angular_inverse_effective_mass = t6,
        linear_softness = v40.softness,
        angular_softness = v42.softness,
        linear_target_impulse = {
            v41[1] * t5[1],
            v41[2] * t5[2],
            v41[3] * t5[3]
        },
        angular_target_impulse = {
            v42.target_displacement[1] * t6[1],
            v42.target_displacement[2] * t6[2],
            v42.target_displacement[3] * t6[3]
        },
        linear_maximum_impulse = v43,
        angular_maximum_impulse = v44,
        accumulated_linear_impulse = table.create(3, 0),
        accumulated_angular_impulse = table.create(3, 0)
    }
end

local function world_frame_scalar(p15, p16) -- line: 257
    local columns = p15.basis.columns
    local v45 = columns[1]
    local v46 = columns[2]
    local v47 = columns[3]
    local translation = p16.translation
    local x, y, z = translation.x, translation.y, translation.z
    local v48 = v47[1] * z + (v46[1] * y + v45[1] * x)
    local v49 = v47[2] * z + (v46[2] * y + v45[2] * x)
    local v50 = v47[3] * z + (v46[3] * y + v45[3] * x)
    local orientation = p15.orientation
    local orientation2 = p16.orientation
    local x2, y2, z2, w = orientation.x, orientation.y, orientation.z, orientation.w
    local x3, y3, z3, w2 = orientation2.x, orientation2.y, orientation2.z, orientation2.w
    local v51 = -z2 * y3 + y2 * z3
    local v52 = -x2 * z3 + z2 * x3
    local v53 = -y2 * x3 + x2 * y3
    local center_of_mass = p15.center_of_mass

    return x2 * w2 + (x3 * w + v51), y2 * w2 + (y3 * w + v52), z2 * w2 + (z3 * w + v53), w * w2 - (x2 * x3 + y2 * y3 + z2 * z3), v48, v49, v50, center_of_mass.x + v48, center_of_mass.y + v49, center_of_mass.z + v50
end

local function linear_mass(p17, p18, p19, p20, p21, p22, p23, p24, p25, p26, p27, p28, p29) -- line: 289
    local v54 = 0

    if p17 then
        local v55 = -p23 * p28 + p22 * p29
        local v56 = -p21 * p29 + p23 * p27
        local v57 = -p22 * p27 + p21 * p28
        local world_inverse_inertia = p19.world_inverse_inertia
        local full, split = world_inverse_inertia.full, world_inverse_inertia.split
        local v58 = full.z * v57 + (full.y * v56 + full.x * v55)
        local v59 = split.z * v57 + (split.y * v56 + full.y * v55)
        local v60 = split.x * v57 + (split.z * v56 + full.z * v55)

        v54 = 0 + (p19.inverse_mass + (v55 * v58 + v56 * v59 + v57 * v60))
    end

    if p18 then
        local v61 = -p26 * p28 + p25 * p29
        local v62 = -p24 * p29 + p26 * p27
        local v63 = -p25 * p27 + p24 * p28
        local world_inverse_inertia = p20.world_inverse_inertia
        local full, split = world_inverse_inertia.full, world_inverse_inertia.split
        local v64 = full.z * v63 + (full.y * v62 + full.x * v61)
        local v65 = split.z * v63 + (split.y * v62 + full.y * v61)
        local v66 = split.x * v63 + (split.z * v62 + full.z * v61)

        v54 += p20.inverse_mass + (v61 * v64 + v62 * v65 + v63 * v66)
    end

    return v54
end

local function angular_mass(p30, p31, p32, p33, p34, p35, p36) -- line: 317
    local v67 = 0

    if p30 then
        local world_inverse_inertia = p32.world_inverse_inertia
        local full, split = world_inverse_inertia.full, world_inverse_inertia.split
        local v68 = full.z * p36 + (full.y * p35 + full.x * p34)
        local v69 = split.z * p36 + (split.y * p35 + full.y * p34)
        local v70 = split.x * p36 + (split.z * p35 + full.z * p34)

        v67 = 0 + (p34 * v68 + p35 * v69 + p36 * v70)
    end

    if p31 then
        local world_inverse_inertia = p33.world_inverse_inertia
        local full, split = world_inverse_inertia.full, world_inverse_inertia.split
        local v71 = full.z * p36 + (full.y * p35 + full.x * p34)
        local v72 = split.z * p36 + (split.y * p35 + full.y * p34)
        local v73 = split.x * p36 + (split.z * p35 + full.z * p34)

        v67 += p34 * v71 + p35 * v72 + p36 * v73
    end

    return v67
end

local function coefficients(p37, p38, p39, p40, p41, p42, p43, p44, p45, p46, p47) -- line: 340
    -- upvalues: SoftDrive (copy), HardDrive (copy)
    local v74 = p38 * p37.damping
    local drive_type = p37.drive_type
    local v75, v76, v77

    if drive_type == SoftDrive then
        local v78 = p38 * p37.spring_or_max_velocity * p38
        local v79 = 1 + v78 + v74
        local v80 = 1 / v79
        local v81 = v80 * (-v80 * v79 + 1) + v80
        local v82 = v81 * (-v81 * v79 + 1) + v81

        v75 = v82 * v78
        v76 = v82 * v74
        v77 = v82 * (v78 + v74)
    else
        local v83 = 1 + v74
        local v84 = 1 / v83
        local v85 = v84 * (-v84 * v83 + 1) + v84

        v75 = (v85 * (-v85 * v83 + 1) + v85) * 1
        v76 = 1
        v77 = 1
    end

    local v86 = p39
    local v87 = p40
    local v88 = p41

    if drive_type == HardDrive then
        local v89 = p39 * p39 + p40 * p40 + p41 * p41
        local v90 = p38 * p37.spring_or_max_velocity

        if v90 * v90 < v89 then
            local v91 = 1 / math.sqrt(v89)
            local v92 = v91 * v91
            local v93 = v91 * 0.5 * (-v89 * v92 + 1) + v91
            local v94 = v93 * v93
            local v95 = v90 * (v93 * 0.5 * (-v89 * v94 + 1) + v93)

            v86 = p39 * v95
            v87 = p40 * v95
            v88 = p41 * v95
        end
    end

    return v77, p45 * v77 + (v86 * v75 + p42 * v76), p46 * v77 + (v87 * v75 + p43 * v76), p47 * v77 + (v88 * v75 + p44 * v76), p38 * p37.max_strength * p38
end

local function fill_drive_rows_r3(p48, p49, p50, p51, p52, p53) -- line: 389
    -- upvalues: is_finite (copy), fround (copy), world_frame_scalar (copy), linear_mass (copy), angular_mass (copy), coefficients (copy)
    if not (is_finite(p53) and p53 > 0) then
        error("assertion failed: time_step.is_finite() && time_step > 0.0", 0)
    end

    local v96, v97, v98, v99, v100, v101, v102, v103, v104, v105 = world_frame_scalar(p49, p51.body_a)
    local v106, v107, v108, v109, v110, v111, v112, v113, v114, v115 = world_frame_scalar(p50, p51.body_b)
    local v116 = v106 * 1.4142135381698608
    local v117 = v107 * 1.4142135381698608
    local v118 = v108 * 1.4142135381698608
    local v119 = v109 * 1.4142135381698608
    local v120 = -v116 * v116 + 0.5
    local v121 = -v117 * v117 + 0.5
    local v122 = -v118 * v118 + 0.5
    local v123 = v116 * v117
    local v124 = v117 * v118
    local v125 = v118 * v116
    local v126 = v119 * v118

    v118 = v119 * v116
    v116 = v119 * v117

    local v127 = v121 + v122
    local v128 = v123 + v126
    local v129 = v125 - v116
    local v130 = v123 - v126
    local v131 = v122 + v120
    local v132 = v124 + v118
    local v133 = v125 + v116
    local v134 = v124 - v118
    local v135 = v120 + v121
    local v136 = v96 * v106
    local v137 = v96 * v107
    local v138 = v96 * v108
    local v139 = v96 * v109
    local v140 = v97 * v106
    local v141 = v97 * v107
    local v142 = v97 * v108
    local v143 = v97 * v109
    local v144 = v98 * v106
    local v145 = v98 * v107
    local v146 = v98 * v108
    local v147 = v98 * v109
    local v148 = v99 * v106
    local v149 = v99 * v107
    local v150 = v99 * v108
    local v151 = v99 * v109

    v116 = v151 + v136 - v141 - v146
    v117 = v140 + v137 + v150 + v147
    v118 = v138 + v144 - v149 - v143
    v119 = v140 + v137 - v150 - v147
    v120 = v151 + v141 - v146 - v136
    v121 = v142 + v145 + v148 + v139
    v122 = v138 + v144 + v143 + v149
    v123 = v145 + v142 - v148 - v139
    v124 = v151 + v146 - v136 - v141
    v125 = v148 - v139 + v145 - v142
    v126 = v149 - v143 + v138 - v144

    local v152 = v150 - v147 + v140 - v137
    local v153 = fround(v125 * v125)

    if v153 ~= v153 or not (v153 > 0) then
        v153 = 0
    end

    if v153 ~= v153 or not (v153 < 1) then
        v153 = 1
    end

    v137 = fround(v126 * v126)

    if v137 ~= v137 or not (v137 > 0) then
        v137 = 0
    end

    if v137 ~= v137 or not (v137 < 1) then
        v137 = 1
    end

    local v154 = fround(v152 * v152)

    if v154 ~= v154 or not (v154 > 0) then
        v154 = 0
    end

    if v154 ~= v154 or not (v154 < 1) then
        v154 = 1
    end

    if v153 == 1 or v137 == 1 or v154 == 1 then
        v136 = 1
        v137 = 1
        v138 = 1
        v139 = v127 * 1
        v140 = v128 * 1
        v141 = v129 * 1
        v142 = v130 * 1
        v143 = v131 * 1
        v144 = v132 * 1
        v145 = v133 * 1
        v146 = v134 * 1
        v147 = v135 * 1
    else
        v148 = 1 - v153
        v136 = 1 / math.sqrt(v148)
        v99 = v136 * v136
        v136 = v136 * 0.5 * (-v148 * v99 + 1) + v136
        v99 = v136 * v136
        v136 = v136 * 0.5 * (-v148 * v99 + 1) + v136
        v148 = 1 - v137
        v137 = 1 / math.sqrt(v148)
        v96 = v137 * v137
        v137 = v137 * 0.5 * (-v148 * v96 + 1) + v137
        v96 = v137 * v137
        v137 = v137 * 0.5 * (-v148 * v96 + 1) + v137
        v148 = 1 - v154
        v138 = 1 / math.sqrt(v148)
        v149 = v138 * v138
        v138 = v138 * 0.5 * (-v148 * v149 + 1) + v138
        v149 = v138 * v138
        v138 = v138 * 0.5 * (-v148 * v149 + 1) + v138
        v139 = v116 * v136
        v140 = v117 * v136
        v141 = v118 * v136
        v142 = v119 * v137
        v143 = v120 * v137
        v144 = v121 * v137
        v145 = v122 * v138
        v146 = v123 * v138
        v147 = v124 * v138
    end

    v124 = v125 * v136 * 2
    v136 = v126 * v137 * 2
    v137 = v152 * v138 * 2

    local v155 = p49.angular_velocity
    local state = p50.angular_velocity
    local x, y, v156 = v155.x, v155.y, v155.z
    local v157, v158, v159 = state.x, state.y, state.z
    local v160 = p49.linear_velocity
    local v161 = p50.linear_velocity

    v148 = (v112 * v158 + (-v111 * v159 + v161.x)) * p53 - (v102 * y + (-v101 * v156 + v160.x)) * p53
    v149 = (v110 * v159 + (-v112 * v157 + v161.y)) * p53 - (v100 * v156 + (-v102 * x + v160.y)) * p53
    v150 = (v111 * v157 + (-v110 * v158 + v161.z)) * p53 - (v101 * x + (-v100 * y + v160.z)) * p53

    local v162 = (v157 - x) * p53
    local v163 = (v158 - y) * p53
    local v164 = (v159 - v156) * p53
    local torque_acceleration = p49.torque_acceleration
    local torque_acceleration2 = p50.torque_acceleration
    local x2, y2, z = torque_acceleration.x, torque_acceleration.y, torque_acceleration.z
    local x3, y3, z2 = torque_acceleration2.x, torque_acceleration2.y, torque_acceleration2.z
    local force_acceleration = p49.force_acceleration
    local force_acceleration2 = p50.force_acceleration

    v151 = (v112 * y3 + (-v111 * z2 + force_acceleration2.x)) * p53 * p53 - (v102 * y2 + (-v101 * z + force_acceleration.x)) * p53 * p53

    local v165 = (v110 * z2 + (-v112 * x3 + force_acceleration2.y)) * p53 * p53 - (v100 * z + (-v102 * x2 + force_acceleration.y)) * p53 * p53
    local v166 = (v111 * x3 + (-v110 * y3 + force_acceleration2.z)) * p53 * p53 - (v101 * x2 + (-v100 * y2 + force_acceleration.z)) * p53 * p53
    local v167 = (x3 - x2) * p53 * p53
    local v168 = (y3 - y2) * p53 * p53
    local v169 = (z2 - z) * p53 * p53

    v138 = bit32.band(p49.state, 4) == 4
    state = p50.state
    v152 = bit32.band(state, 4) == 4
    v155 = linear_mass(v138, v152, p49, p50, v100, v101, v102, v110, v111, v112, v127, v128, v129)
    v126 = 1 / v155
    v126 = v126 * (-v126 * v155 + 1) + v126
    v126 = v126 * (-v126 * v155 + 1) + v126
    v155 = linear_mass(v138, v152, p49, p50, v100, v101, v102, v110, v111, v112, v130, v131, v132)
    v123 = 1 / v155
    v123 = v123 * (-v123 * v155 + 1) + v123
    v123 = v123 * (-v123 * v155 + 1) + v123
    v155 = linear_mass(v138, v152, p49, p50, v100, v101, v102, v110, v111, v112, v133, v134, v135)
    v121 = 1 / v155
    v121 = v121 * (-v121 * v155 + 1) + v121
    v121 = v121 * (-v121 * v155 + 1) + v121
    v155 = angular_mass(v138, v152, p49, p50, v139, v140, v141)
    v119 = 1 / v155
    v119 = v119 * (-v119 * v155 + 1) + v119
    v119 = v119 * (-v119 * v155 + 1) + v119
    v155 = angular_mass(v138, v152, p49, p50, v142, v143, v144)
    v117 = 1 / v155
    v117 = v117 * (-v117 * v155 + 1) + v117
    v117 = v117 * (-v117 * v155 + 1) + v117
    v155 = angular_mass(v138, v152, p49, p50, v145, v146, v147)
    v109 = 1 / v155
    v109 = v109 * (-v109 * v155 + 1) + v109
    v109 = v109 * (-v109 * v155 + 1) + v109
    v155, state, x, y, v156 = coefficients(p52.linear, p53, v113 - v103, v114 - v104, v115 - v105, v148, v149, v150, v151, v165, v166)
    v166 = state * v127 + x * v128 + y * v129
    v165 = state * v130 + x * v131 + y * v132
    v151 = state * v133 + x * v134 + y * v135
    v157, v158, v159, v160, v161 = coefficients(p52.angular, p53, v124, v136, v137, v162 * v139 + v163 * v140 + v164 * v141, v162 * v142 + v163 * v143 + v164 * v144, v162 * v145 + v163 * v146 + v164 * v147, v167 * v139 + v168 * v140 + v169 * v141, v167 * v142 + v168 * v143 + v169 * v144, v167 * v145 + v168 * v146 + v169 * v147)
    p48.frame_a_body = p49
    p48.frame_b_body = p50
    y = p48.arm_a
    y.x = v100
    y.y = v101
    y.z = v102
    y = p48.arm_b
    y.x = v110
    y.y = v111
    y.z = v112
    x = p48.linear_axes
    y = x[1]
    y.x = v127
    y.y = v128
    y.z = v129
    y = x[2]
    y.x = v130
    y.y = v131
    y.z = v132
    y = x[3]
    y.x = v133
    y.y = v134
    y.z = v135
    x = p48.angular_axes
    y = x[1]
    y.x = v139
    y.y = v140
    y.z = v141
    y = x[2]
    y.x = v142
    y.y = v143
    y.z = v144
    y = x[3]
    y.x = v145
    y.y = v146
    y.z = v147
    y = p48.linear_inverse_effective_mass
    y[1] = v126
    y[2] = v123
    y[3] = v121
    y = p48.angular_inverse_effective_mass
    y[1] = v119
    y[2] = v117
    y[3] = v109
    p48.linear_softness = v155
    p48.angular_softness = v157
    y = p48.linear_target_impulse
    torque_acceleration = v166 * v126
    torque_acceleration2 = v165 * v123
    x2 = v151 * v121
    y[1] = torque_acceleration
    y[2] = torque_acceleration2
    y[3] = x2
    y = p48.angular_target_impulse
    torque_acceleration = v158 * v119
    torque_acceleration2 = v159 * v117
    x2 = v160 * v109
    y[1] = torque_acceleration
    y[2] = torque_acceleration2
    y[3] = x2
    y = p48.linear_maximum_impulse
    torque_acceleration = v126 * v156
    torque_acceleration2 = v123 * v156
    x2 = v121 * v156
    y[1] = torque_acceleration
    y[2] = torque_acceleration2
    y[3] = x2
    y = p48.angular_maximum_impulse
    torque_acceleration = v119 * v161
    torque_acceleration2 = v117 * v161
    x2 = v109 * v161
    y[1] = torque_acceleration
    y[2] = torque_acceleration2
    y[3] = x2
    y = p48.accumulated_linear_impulse
    y[1] = 0
    y[2] = 0
    y[3] = 0
    y = p48.accumulated_angular_impulse
    y[1] = 0
    y[2] = 0
    y[3] = 0

    return p48
end

local create = vector.create

local function fill_drive_rows(p54, p55, p56, p57, p58, p59) -- line: 625
    -- upvalues: is_finite (copy), fround (copy), SoftDrive (copy), HardDrive (copy), create (copy)
    if not (is_finite(p59) and p59 > 0) then
        error("assertion failed: time_step.is_finite() && time_step > 0.0", 0)
    end

    local v170 = p57.body_a
    local v171 = p55.basis.columns
    local v172 = v171[1]
    local v173 = v171[2]
    local v174 = v171[3]

    v171 = v170.translation

    local v175, v176, v177 = v171.x, v171.y, v171.z
    local v178 = v174[1] * v177 + (v173[1] * v176 + v172[1] * v175)
    local v179 = v174[2] * v177 + (v173[2] * v176 + v172[2] * v175)
    local v180 = v174[3] * v177 + (v173[3] * v176 + v172[3] * v175)

    v177 = p55.orientation
    v176 = v170.orientation

    local v181, v182, v183, v184 = v177.x, v177.y, v177.z, v177.w
    local v185, v186, v187, v188 = v176.x, v176.y, v176.z, v176.w

    v177 = -v183 * v186 + v182 * v187
    v176 = -v181 * v187 + v183 * v185
    v175 = -v182 * v185 + v181 * v186
    v174 = p55.center_of_mass

    local v189 = v181 * v188 + (v185 * v184 + v177)
    local v190 = v182 * v188 + (v186 * v184 + v176)
    local v191 = v183 * v188 + (v187 * v184 + v175)
    local v192 = v184 * v188 - (v181 * v185 + v182 * v186 + v183 * v187)
    local v193 = v174.x + v178
    local v194 = v174.y + v179
    local v195 = v174.z + v180

    v183 = p57.body_b
    v184 = p56.basis.columns
    v185 = v184[1]
    v186 = v184[2]
    v187 = v184[3]
    v184 = v183.translation
    v188 = v184.x

    local v196, v197 = v184.y, v184.z

    v174 = v187[1] * v197 + (v186[1] * v196 + v185[1] * v188)
    v175 = v187[2] * v197 + (v186[2] * v196 + v185[2] * v188)
    v176 = v187[3] * v197 + (v186[3] * v196 + v185[3] * v188)
    v197 = p56.orientation
    v196 = v183.orientation

    local v198, v199, v200, v201 = v197.x, v197.y, v197.z, v197.w
    local v202, v203, v204, v205 = v196.x, v196.y, v196.z, v196.w

    v197 = -v200 * v203 + v199 * v204
    v196 = -v198 * v204 + v200 * v202
    v188 = -v199 * v202 + v198 * v203
    v187 = p56.center_of_mass
    v170 = v198 * v205 + (v202 * v201 + v197)
    v171 = v199 * v205 + (v203 * v201 + v196)
    v172 = v200 * v205 + (v204 * v201 + v188)
    v173 = v201 * v205 - (v198 * v202 + v199 * v203 + v200 * v204)
    v177 = v187.x + v174
    v181 = v187.y + v175
    v182 = v187.z + v176
    v199 = v170 * 1.4142135381698608
    v200 = v171 * 1.4142135381698608
    v201 = v172 * 1.4142135381698608
    v202 = v173 * 1.4142135381698608
    v203 = -v199 * v199 + 0.5
    v204 = -v200 * v200 + 0.5
    v205 = -v201 * v201 + 0.5

    local v206 = v199 * v200
    local v207 = v200 * v201
    local v208 = v201 * v199
    local v209 = v202 * v201

    v201 = v202 * v199
    v199 = v202 * v200
    v183 = v204 + v205
    v184 = v206 + v209
    v185 = v208 - v199
    v186 = v206 - v209
    v187 = v205 + v203
    v188 = v207 + v201
    v196 = v208 + v199
    v197 = v207 - v201
    v198 = v203 + v204

    local v210 = v189 * v170
    local v211 = v189 * v171
    local v212 = v189 * v172
    local v213 = v189 * v173
    local v214 = v190 * v170
    local v215 = v190 * v171
    local v216 = v190 * v172
    local v217 = v190 * v173
    local v218 = v191 * v170
    local v219 = v191 * v171
    local v220 = v191 * v172
    local v221 = v191 * v173
    local v222 = v192 * v170
    local v223 = v192 * v171
    local v224 = v192 * v172
    local v225 = v192 * v173

    v199 = v225 + v210 - v215 - v220
    v200 = v214 + v211 + v224 + v221
    v201 = v212 + v218 - v223 - v217
    v202 = v214 + v211 - v224 - v221
    v203 = v225 + v215 - v220 - v210
    v204 = v216 + v219 + v222 + v213
    v205 = v212 + v218 + v217 + v223
    v206 = v219 + v216 - v222 - v213
    v207 = v225 + v220 - v210 - v215
    v208 = v222 - v213 + v219 - v216
    v209 = v223 - v217 + v212 - v218

    local v226 = v224 - v221 + v214 - v211

    v213 = v208 * v208
    v214 = v209 * v209
    v215 = v226 * v226

    local v227 = create(v213, v214, v215)

    v216 = v227.x
    v217 = v227.y
    v218 = v227.z

    if v213 < 1.1754943508222875E-38 and v213 > -1.1754943508222875E-38 and v213 ~= 0 then
        v216 = fround(v213)
    end

    if v214 < 1.1754943508222875E-38 and v214 > -1.1754943508222875E-38 and v214 ~= 0 then
        v217 = fround(v214)
    end

    if v215 < 1.1754943508222875E-38 and v215 > -1.1754943508222875E-38 and v215 ~= 0 then
        v218 = fround(v215)
    end

    if v216 ~= v216 or not (v216 > 0) then
        v216 = 0
    end

    if v216 ~= v216 or not (v216 < 1) then
        v216 = 1
    end

    if v217 ~= v217 or not (v217 > 0) then
        v217 = 0
    end

    if v217 ~= v217 or not (v217 < 1) then
        v217 = 1
    end

    if v218 ~= v218 or not (v218 > 0) then
        v218 = 0
    end

    if v218 ~= v218 or not (v218 < 1) then
        v218 = 1
    end

    local v228

    if v216 == 1 or v217 == 1 or v218 == 1 then
        v213 = 1
        v214 = 1
        v215 = 1
        v216 = v183 * 1
        v217 = v184 * 1
        v218 = v185 * 1
        v219 = v186 * 1
        v220 = v187 * 1
        v221 = v188 * 1
        v222 = v196 * 1
        v223 = v197 * 1
        v224 = v198 * 1
    else
        v225 = 1 - v216
        v213 = 1 / math.sqrt(v225)
        v171 = v213 * v213
        v213 = v213 * 0.5 * (-v225 * v171 + 1) + v213
        v171 = v213 * v213
        v213 = v213 * 0.5 * (-v225 * v171 + 1) + v213
        v225 = 1 - v217
        v214 = 1 / math.sqrt(v225)
        v191 = v214 * v214
        v214 = v214 * 0.5 * (-v225 * v191 + 1) + v214
        v191 = v214 * v214
        v214 = v214 * 0.5 * (-v225 * v191 + 1) + v214
        v225 = 1 - v218
        v215 = 1 / math.sqrt(v225)
        v228 = v215 * v215
        v215 = v215 * 0.5 * (-v225 * v228 + 1) + v215
        v228 = v215 * v215
        v215 = v215 * 0.5 * (-v225 * v228 + 1) + v215
        v216 = v199 * v213
        v217 = v200 * v213
        v218 = v201 * v213
        v219 = v202 * v214
        v220 = v203 * v214
        v221 = v204 * v214
        v222 = v205 * v215
        v223 = v206 * v215
        v224 = v207 * v215
    end

    v212 = v208 * v213 * 2
    v213 = v209 * v214 * 2
    v214 = v226 * v215 * 2

    local v229 = p55.angular_velocity
    local v230 = p56.angular_velocity
    local v231, v232, v233 = v229.x, v229.y, v229.z
    local v234, v235, inverse_mass = v230.x, v230.y, v230.z
    local z = p55.linear_velocity
    local y = p56.linear_velocity

    v225 = (v176 * v235 + (-v175 * inverse_mass + y.x)) * p59 - (v180 * v232 + (-v179 * v233 + z.x)) * p59
    v228 = (v174 * inverse_mass + (-v176 * v234 + y.y)) * p59 - (v178 * v233 + (-v180 * v231 + z.y)) * p59

    local v236 = (v175 * v234 + (-v174 * v235 + y.z)) * p59 - (v179 * v231 + (-v178 * v232 + z.z)) * p59
    local v237 = (v234 - v231) * p59
    local v238 = (v235 - v232) * p59
    local v239 = (inverse_mass - v233) * p59
    local v240 = p55.torque_acceleration
    local z2 = p56.torque_acceleration
    local y2, x, v241 = v240.x, v240.y, v240.z
    local v242, v243, v244 = z2.x, z2.y, z2.z
    local v245 = p55.force_acceleration
    local v246 = p56.force_acceleration
    local v247 = (v176 * v243 + (-v175 * v244 + v246.x)) * p59 * p59 - (v180 * x + (-v179 * v241 + v245.x)) * p59 * p59
    local v248 = (v174 * v244 + (-v176 * v242 + v246.y)) * p59 * p59 - (v178 * v241 + (-v180 * y2 + v245.y)) * p59 * p59
    local v249 = (v175 * v242 + (-v174 * v243 + v246.z)) * p59 * p59 - (v179 * y2 + (-v178 * x + v245.z)) * p59 * p59
    local v250 = (v242 - y2) * p59 * p59
    local v251 = (v243 - x) * p59 * p59
    local v252 = (v244 - v241) * p59 * p59

    v215 = bit32.band(p55.state, 4) == 4
    v211 = bit32.band(p56.state, 4) == 4

    if v215 then
        v210 = p55.world_inverse_inertia
        v235 = v210.full
        inverse_mass = v210.split
        z = v235.z
        y = v235.y
        v240 = v235.x
        z2 = inverse_mass.z
        y2 = inverse_mass.y
        x = inverse_mass.x
        inverse_mass = p55.inverse_mass
        v235 = -v180 * v184 + v179 * v185
        v210 = -v178 * v185 + v180 * v183
        v226 = -v179 * v183 + v178 * v184
        v209 = z * v226 + (y * v210 + v240 * v235)
        v208 = z2 * v226 + (y2 * v210 + y * v235)
        v207 = x * v226 + (z2 * v210 + z * v235)
        v229 = 0 + (inverse_mass + (v235 * v209 + v210 * v208 + v226 * v207))
        v206 = -v180 * v187 + v179 * v188
        v205 = -v178 * v188 + v180 * v186
        v204 = -v179 * v186 + v178 * v187
        v203 = z * v204 + (y * v205 + v240 * v206)
        v202 = z2 * v204 + (y2 * v205 + y * v206)
        v201 = x * v204 + (z2 * v205 + z * v206)
        v230 = 0 + (inverse_mass + (v206 * v203 + v205 * v202 + v204 * v201))
        v200 = -v180 * v197 + v179 * v198
        v199 = -v178 * v198 + v180 * v196
        v172 = -v179 * v196 + v178 * v197
        v241 = z * v172 + (y * v199 + v240 * v200)
        v242 = z2 * v172 + (y2 * v199 + y * v200)
        v243 = x * v172 + (z2 * v199 + z * v200)
        v231 = 0 + (inverse_mass + (v200 * v241 + v199 * v242 + v172 * v243))
        inverse_mass = z * v218 + (y * v217 + v240 * v216)
        v241 = z2 * v218 + (y2 * v217 + y * v216)
        v242 = x * v218 + (z2 * v217 + z * v216)
        v232 = 0 + (v216 * inverse_mass + v217 * v241 + v218 * v242)
        v241 = z * v221 + (y * v220 + v240 * v219)
        v242 = z2 * v221 + (y2 * v220 + y * v219)
        v243 = x * v221 + (z2 * v220 + z * v219)
        v233 = 0 + (v219 * v241 + v220 * v242 + v221 * v243)
        v241 = z * v224 + (y * v223 + v240 * v222)
        v242 = z2 * v224 + (y2 * v223 + y * v222)
        v243 = x * v224 + (z2 * v223 + z * v222)
        v234 = 0 + (v222 * v241 + v223 * v242 + v224 * v243)
    else
        v229 = 0
        v230 = 0
        v231 = 0
        v232 = 0
        v233 = 0
        v234 = 0
    end

    if v211 then
        v215 = p56.world_inverse_inertia
        v235 = v215.full
        inverse_mass = v215.split
        z = v235.z
        y = v235.y
        v240 = v235.x
        z2 = inverse_mass.z
        y2 = inverse_mass.y
        x = inverse_mass.x
        inverse_mass = p56.inverse_mass
        v235 = -v176 * v184 + v175 * v185
        v215 = -v174 * v185 + v176 * v183
        v241 = -v175 * v183 + v174 * v184
        v242 = z * v241 + (y * v215 + v240 * v235)
        v243 = z2 * v241 + (y2 * v215 + y * v235)
        v244 = x * v241 + (z2 * v215 + z * v235)
        v229 += inverse_mass + (v235 * v242 + v215 * v243 + v241 * v244)
        v241 = -v176 * v187 + v175 * v188
        v242 = -v174 * v188 + v176 * v186
        v243 = -v175 * v186 + v174 * v187
        v244 = z * v243 + (y * v242 + v240 * v241)
        v245 = z2 * v243 + (y2 * v242 + y * v241)
        v246 = x * v243 + (z2 * v242 + z * v241)
        v230 += inverse_mass + (v241 * v244 + v242 * v245 + v243 * v246)
        v241 = -v176 * v197 + v175 * v198
        v242 = -v174 * v198 + v176 * v196
        v243 = -v175 * v196 + v174 * v197
        v244 = z * v243 + (y * v242 + v240 * v241)
        v245 = z2 * v243 + (y2 * v242 + y * v241)
        v246 = x * v243 + (z2 * v242 + z * v241)
        v231 += inverse_mass + (v241 * v244 + v242 * v245 + v243 * v246)
        inverse_mass = z * v218 + (y * v217 + v240 * v216)
        v241 = z2 * v218 + (y2 * v217 + y * v216)
        v242 = x * v218 + (z2 * v217 + z * v216)
        v232 += v216 * inverse_mass + v217 * v241 + v218 * v242
        v241 = z * v221 + (y * v220 + v240 * v219)
        v242 = z2 * v221 + (y2 * v220 + y * v219)
        v243 = x * v221 + (z2 * v220 + z * v219)
        v233 += v219 * v241 + v220 * v242 + v221 * v243
        v241 = z * v224 + (y * v223 + v240 * v222)
        v242 = z2 * v224 + (y2 * v223 + y * v222)
        v243 = x * v224 + (z2 * v223 + z * v222)
        v234 += v222 * v241 + v223 * v242 + v224 * v243
    end

    v211 = 1 / v229
    v211 = v211 * (-v211 * v229 + 1) + v211
    v211 = v211 * (-v211 * v229 + 1) + v211
    v229 = 1 / v230
    v229 = v229 * (-v229 * v230 + 1) + v229
    v229 = v229 * (-v229 * v230 + 1) + v229
    v230 = 1 / v231
    v230 = v230 * (-v230 * v231 + 1) + v230
    v230 = v230 * (-v230 * v231 + 1) + v230
    v231 = 1 / v232
    v231 = v231 * (-v231 * v232 + 1) + v231
    v231 = v231 * (-v231 * v232 + 1) + v231
    v232 = 1 / v233
    v232 = v232 * (-v232 * v233 + 1) + v232
    v232 = v232 * (-v232 * v233 + 1) + v232
    v233 = 1 / v234
    v233 = v233 * (-v233 * v234 + 1) + v233
    v233 = v233 * (-v233 * v234 + 1) + v233
    v234 = p58.linear
    z2 = v177 - v193
    y2 = v181 - v194
    x = v182 - v195
    v241 = p59 * v234.damping
    v242 = v234.drive_type

    local v253, v254

    if v242 == SoftDrive then
        v246 = p59 * v234.spring_or_max_velocity * p59
        v254 = 1 + v246 + v241
        v253 = 1 / v254
        v253 = v253 * (-v253 * v254 + 1) + v253
        v253 = v253 * (-v253 * v254 + 1) + v253
        v243 = v253 * v246
        v244 = v253 * v241
        v245 = v253 * (v246 + v241)
    else
        v253 = 1 + v241
        v246 = 1 / v253
        v246 = v246 * (-v246 * v253 + 1) + v246
        v243 = (v246 * (-v246 * v253 + 1) + v246) * 1
        v244 = 1
        v245 = 1
    end

    local v255

    if v242 == HardDrive then
        v241 = z2 * z2 + y2 * y2 + x * x
        v246 = p59 * v234.spring_or_max_velocity

        if v246 * v246 < v241 then
            v254 = 1 / math.sqrt(v241)
            v255 = v254 * v254
            v254 = v254 * 0.5 * (-v241 * v255 + 1) + v254
            v255 = v254 * v254
            v253 = v246 * (v254 * 0.5 * (-v241 * v255 + 1) + v254)
            z2 *= v253
            y2 *= v253
            x *= v253
        end
    end

    inverse_mass = v247 * v245 + (z2 * v243 + v225 * v244)
    z = v248 * v245 + (y2 * v243 + v228 * v244)
    y = v249 * v245 + (x * v243 + v236 * v244)
    v240 = p59 * v234.max_strength * p59
    v249 = inverse_mass * v183 + z * v184 + y * v185
    v248 = inverse_mass * v186 + z * v187 + y * v188
    v247 = inverse_mass * v196 + z * v197 + y * v198
    y = p58.angular
    z = v237 * v216 + v238 * v217 + v239 * v218
    inverse_mass = v237 * v219 + v238 * v220 + v239 * v221
    v236 = v237 * v222 + v238 * v223 + v239 * v224
    v228 = v250 * v216 + v251 * v217 + v252 * v218
    v225 = v250 * v219 + v251 * v220 + v252 * v221
    v182 = v250 * v222 + v251 * v223 + v252 * v224
    v181 = p59 * y.damping
    v177 = y.drive_type

    local v256

    if v177 == SoftDrive then
        v195 = p59 * y.spring_or_max_velocity * p59
        v255 = 1 + v195 + v181
        v194 = 1 / v255
        v194 = v194 * (-v194 * v255 + 1) + v194
        v194 = v194 * (-v194 * v255 + 1) + v194
        v246 = v194 * v195
        v253 = v194 * v181
        v254 = v194 * (v195 + v181)
    else
        v256 = 1 + v181
        v255 = 1 / v256
        v255 = v255 * (-v255 * v256 + 1) + v255
        v246 = (v255 * (-v255 * v256 + 1) + v255) * 1
        v253 = 1
        v254 = 1
    end

    if v177 == HardDrive then
        v181 = v212 * v212 + v213 * v213 + v214 * v214
        v255 = p59 * y.spring_or_max_velocity

        if v255 * v255 < v181 then
            local v257 = 1 / math.sqrt(v181)
            local v258 = v257 * v257

            v257 = v257 * 0.5 * (-v181 * v258 + 1) + v257
            v258 = v257 * v257
            v256 = v255 * (v257 * 0.5 * (-v181 * v258 + 1) + v257)
            v212 *= v256
            v213 *= v256
            v214 *= v256
        end
    end

    y2 = v228 * v254 + (v212 * v246 + z * v253)
    x = v225 * v254 + (v213 * v246 + inverse_mass * v253)
    v241 = v182 * v254 + (v214 * v246 + v236 * v253)
    v242 = p59 * y.max_strength * p59
    p54.frame_a_body = p55
    p54.frame_b_body = p56
    v252 = p54.arm_a
    v252.x = v178
    v252.y = v179
    v252.z = v180
    v252 = p54.arm_b
    v252.x = v174
    v252.y = v175
    v252.z = v176
    v251 = p54.linear_axes
    v252 = v251[1]
    v252.x = v183
    v252.y = v184
    v252.z = v185
    v252 = v251[2]
    v252.x = v186
    v252.y = v187
    v252.z = v188
    v252 = v251[3]
    v252.x = v196
    v252.y = v197
    v252.z = v198
    v251 = p54.angular_axes
    v252 = v251[1]
    v252.x = v216
    v252.y = v217
    v252.z = v218
    v252 = v251[2]
    v252.x = v219
    v252.y = v220
    v252.z = v221
    v252 = v251[3]
    v252.x = v222
    v252.y = v223
    v252.z = v224
    v252 = p54.linear_inverse_effective_mass
    v252[1] = v211
    v252[2] = v229
    v252[3] = v230
    v252 = p54.angular_inverse_effective_mass
    v252[1] = v231
    v252[2] = v232
    v252[3] = v233
    p54.linear_softness = v245
    p54.angular_softness = v254
    v252 = p54.linear_target_impulse
    v243 = v249 * v211
    v244 = v248 * v229
    v245 = v247 * v230
    v252[1] = v243
    v252[2] = v244
    v252[3] = v245
    v252 = p54.angular_target_impulse
    v243 = y2 * v231
    v244 = x * v232
    v245 = v241 * v233
    v252[1] = v243
    v252[2] = v244
    v252[3] = v245
    v252 = p54.linear_maximum_impulse
    v243 = v211 * v240
    v244 = v229 * v240
    v245 = v230 * v240
    v252[1] = v243
    v252[2] = v244
    v252[3] = v245
    v252 = p54.angular_maximum_impulse
    v243 = v231 * v242
    v244 = v232 * v242
    v245 = v233 * v242
    v252[1] = v243
    v252[2] = v244
    v252[3] = v245
    v252 = p54.accumulated_linear_impulse
    v252[1] = 0
    v252[2] = 0
    v252[3] = 0
    v252 = p54.accumulated_angular_impulse
    v252[1] = 0
    v252[2] = 0
    v252[3] = 0

    return p54
end

local v259 = true

function t1.set_b3(p60) -- line: 1046
    -- upvalues: v259 (ref)
    local v260 = v259

    v259 = p60

    return v260
end

local function empty_drive_rows() -- line: 1054
    return {
        frame_a_body = false,
        frame_b_body = false,
        linear_softness = 0,
        angular_softness = 0,
        arm_a = {
            x = 0,
            y = 0,
            z = 0
        },
        arm_b = {
            x = 0,
            y = 0,
            z = 0
        },
        linear_axes = {
            {
                x = 0,
                y = 0,
                z = 0
            },
            {
                x = 0,
                y = 0,
                z = 0
            },
            {
                x = 0,
                y = 0,
                z = 0
            }
        },
        angular_axes = {
            {
                x = 0,
                y = 0,
                z = 0
            },
            {
                x = 0,
                y = 0,
                z = 0
            },
            {
                x = 0,
                y = 0,
                z = 0
            }
        },
        linear_inverse_effective_mass = { 0, 0, 0 },
        angular_inverse_effective_mass = { 0, 0, 0 },
        linear_target_impulse = { 0, 0, 0 },
        angular_target_impulse = { 0, 0, 0 },
        linear_maximum_impulse = { 0, 0, 0 },
        angular_maximum_impulse = { 0, 0, 0 },
        accumulated_linear_impulse = { 0, 0, 0 },
        accumulated_angular_impulse = { 0, 0, 0 }
    }
end

function t1.build_drive_rows(p61, p62, p63, p64, p65) -- line: 1083
    -- upvalues: fill_drive_rows_r3 (copy), fill_drive_rows (copy), v259 (ref), empty_drive_rows (copy)
    if v259 then
        return (fill_drive_rows(empty_drive_rows(), p61, p62, p63, p64, p65))
    end

    return (fill_drive_rows_r3(empty_drive_rows(), p61, p62, p63, p64, p65))
end

function t1.build_drive_rows_into(p66, p67, p68, p69, p70, p71) -- line: 1105
    -- upvalues: fill_drive_rows_r3 (copy), fill_drive_rows (copy), v259 (ref)
    if v259 then
        return (fill_drive_rows(p66, p67, p68, p69, p70, p71))
    end

    return (fill_drive_rows_r3(p66, p67, p68, p69, p70, p71))
end

t1.WorldFrame = {}

function t1.world_frame(p72, p73) -- line: 1123
    -- upvalues: import (copy), v9 (copy)
    local v261 = import("skate_core/physics/drive_solver")
    local v262 = v9.transform_direction(p72.basis, p73.translation)

    return {
        orientation = v9.compose(p72.orientation, p73.orientation),
        arm = v262,
        position = v261.add(p72.center_of_mass, v262)
    }
end

t1.DriveCoefficients = {}

function t1.components_of(p74) -- line: 1136
    return {
        p74.x,
        p74.y,
        p74.z
    }
end

function t1.build_coefficients(p75, p76, p77, p78, p79) -- line: 1143
    -- upvalues: rt (copy), v9 (copy), RetailDriveType (copy)
    local v263 = p76
    local v264 = p79 * p75.damping
    local v265, v266, v267, v268

    if p75.drive_type == RetailDriveType.SoftDrive then
        local v269 = p79 * p75.spring_or_max_velocity * p79
        local v270 = v9.reciprocal(1 + v269 + v264)

        v265 = v270 * v269
        v266 = v270 * v264
        v268 = v270 * (v269 + v264)
        v267 = v268
    else
        v265 = v9.reciprocal(1 + v264) * 1
        v266 = 1
        v267 = 1
        v268 = 1
    end

    if p75.drive_type == RetailDriveType.HardDrive then
        local v272 = p76[1] * p76[1] + p76[2] * p76[2] + p76[3] * p76[3]
        local v273 = p79 * p75.spring_or_max_velocity

        if v273 * v273 < v272 then
            local v274 = v273 * v9.reciprocal_sqrt(v272)

            v263 = {
                p76[1] * v274,
                p76[2] * v274,
                p76[3] * v274
            }
        end
    end

    return {
        softness = v268,
        target_displacement = rt.from_fn(3, function(p80) -- line: 1168
            -- upvalues: v263 (ref), p77 (copy), p78 (copy), v265 (ref), v266 (ref), v267 (ref)
            local v275 = p77[p80 + 1] * v266
            local v276 = v263[p80 + 1] * v265 + v275

            return p78[p80 + 1] * v267 + v276
        end),
        maximum_strength = p79 * p75.max_strength * p79
    }
end

function t1.linear_effective_mass(p81, p82, p83, p84, p85) -- line: 1179
    -- upvalues: import (copy), v9 (copy)
    local v277 = import("skate_core/physics/drive_solver")
    local v278 = 0

    if v277.is_active(p81) then
        local v279 = v277.cross(p83, p85)

        v278 = 0 + (p81.inverse_mass + v277.dot(v279, v9.multiply_inertia(p81.world_inverse_inertia, v279)))
    end

    if v277.is_active(p82) then
        local v280 = v277.cross(p84, p85)

        v278 += p82.inverse_mass + v277.dot(v280, v9.multiply_inertia(p82.world_inverse_inertia, v280))
    end

    return v278
end

function t1.angular_effective_mass(p86, p87, p88) -- line: 1195
    -- upvalues: import (copy), v9 (copy)
    local v281 = import("skate_core/physics/drive_solver")
    local v282 = if v281.is_active(p86) then 0 + v281.dot(p88, v9.multiply_inertia(p86.world_inverse_inertia, p88)) else 0

    if v281.is_active(p87) then
        v282 += v281.dot(p88, v9.multiply_inertia(p87.world_inverse_inertia, p88))
    end

    return v282
end

return t1
