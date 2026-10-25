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

local function rtl_is_finite(p4) -- line: 28
    if p4 ~= p4 or p4 == 1e999 then
        return false
    end

    return p4 ~= (-1e999)
end

local import = require(sim.import)
local v8 = import("skate_core/physics/constraint_frames")
local v9 = import("skate_core/physics/native_arithmetic")
local v10 = import("skate_core/physics/joint_builder/arithmetic")
local t1 = {}

local function struct_eq(p5, p6) -- line: 53
    -- upvalues: struct_eq (copy)
    if type(p5) ~= "table" or type(p6) ~= "table" then
        return p5 == p6
    end

    for v11, v12 in p5 do
        if not struct_eq(v12, p6[v11]) then
            return false
        end
    end

    for v13 in p6 do
        if p5[v13] == nil then
            return false
        end
    end

    return true
end

t1.tu3 = {
    JOINT_BATCH_BUILD = 2192456144,
    JOINT_JACOBIAN_BUILD = 2192456648,
    JACOBIAN_RQD_CREATE = 2192444848,
    ITERATIVE_CONSTRAINT_SOLVER = 2192451536,
    ACTIVE_BODY = 4,
    JACOBIAN_BYTES = 384,
    JACOBIAN_WORDS = 96,
    FINITE_INFINITY = 3.4028234663852886E+38,
    NEAR_PARALLEL = 0.9999899864196777
}

local tu3 = t1.tu3

t1.RetailJointBodyInput = {}
t1.RetailJointBodyInput.eq = struct_eq
t1.RetailJointBuildInput = {}
t1.RetailJointBuildInput.eq = struct_eq
t1.JointParameters = {}
t1.JointParameters.eq = struct_eq
t1.JointFrames = {}
t1.JointFrames.eq = struct_eq
t1.Rqd = {}

function t1.build_retail_joint_jacobian_reference(p7) -- line: 127
    -- upvalues: rt (copy), v1 (copy), v8 (copy), v9 (copy), v10 (copy), t1 (copy), tu3 (copy)
    local time_step = p7.time_step

    if not (time_step == time_step and time_step ~= 1e999 and time_step ~= (-1e999) and p7.time_step > 0) then
        error("assertion failed: input.time_step.is_finite() && input.time_step > 0.0", 0)
    end

    local v14 = v10.decode_parameters(p7.parameters)
    local v15 = v10.decode_frames(p7.frames)
    local v16 = bit32.band(p7.body_a.state, tu3.ACTIVE_BODY) ~= 0
    local v17 = bit32.band(p7.body_b.state, tu3.ACTIVE_BODY) ~= 0
    local v18 = v10.quaternion_multiply(p7.body_a.orientation, v15.orientation_a)
    local v19 = v10.quaternion_multiply(p7.body_b.orientation, v15.orientation_b)
    local v20 = v10.quaternion_multiply(p7.body_b.orientation, v15.linear_orientation_b)
    local v21 = v10.basis_from_quaternion_retail(v18)
    local v22 = v10.basis_from_quaternion_retail(v19)
    local v23 = v10.basis_from_quaternion_retail(v20)
    local v24 = v10.multiply_basis(p7.body_a.basis, v15.anchor_a)
    local v25 = v10.multiply_basis(p7.body_b.basis, v15.anchor_b)
    local v26 = v10.basis_columns(v23)
    local v27 = v10.relative_basis(v21, v22)
    local v28 = v10.create_rqd(v18, v19)
    local v29, v30, v31 = v10.angular_rows(v14, v21, v22, v27, v28)
    local v32 = if v16 then p7.body_a.inverse_mass else 0
    local v33 = if v17 then p7.body_b.inverse_mass else 0
    local v34 = if v16 then rt.copy(p7.body_a.world_inverse_inertia) else v10.zero_inertia()
    local v35 = if v17 then rt.copy(p7.body_b.world_inverse_inertia) else v10.zero_inertia()
    local v36 = rt.from_fn(3, function(p8) -- line: 182
        -- upvalues: v24 (copy), v25 (copy), v26 (copy), v32 (copy), v33 (copy), v34 (copy), v35 (copy), v8 (copy), v9 (copy), v10 (copy)
        local v37 = v10.cross(v24, v26[p8 + 1])
        local v38 = v10.cross(v25, v26[p8 + 1])
        local v39 = v8.multiply_inertia_from_zero(v34, v37)
        local v40 = v8.multiply_inertia_from_zero(v35, v38)
        local v41 = v38.x * v40.x + (v37.x * v39.x + 0)
        local v42 = v38.y * v40.y + (v37.y * v39.y + 0)
        local v43 = v38.z * v40.z + (v37.z * v39.z + 0) + v42 + (v41 + (v32 + v33))

        return v9.reciprocal_estimate(v43)
    end)
    local v44 = rt.from_fn(3, function(p9) -- line: 195
        -- upvalues: v29 (copy), v34 (copy), v35 (copy), v8 (copy), v9 (copy), v10 (copy)
        local v45 = v29[p9 + 1]
        local v46 = v10.add(v8.multiply_inertia_from_zero(v34, v45), v8.multiply_inertia_from_zero(v35, v45))
        local v47 = v45.x * v46.x + 0
        local v48 = v45.y * v46.y + 0
        local v49 = v45.z * v46.z + 0

        return 0.5 * v9.reciprocal_estimate(v49 + (v47 + v48))
    end)
    local v50 = v10.point_rate(p7.body_a.linear_velocity, p7.body_a.angular_velocity, v24)
    local v51 = v10.point_rate(p7.body_b.linear_velocity, p7.body_b.angular_velocity, v25)
    local v52 = v10.point_rate(p7.body_a.force_acceleration, p7.body_a.torque_acceleration, v24)
    local v53 = v10.point_rate(p7.body_b.force_acceleration, p7.body_b.torque_acceleration, v25)
    local v54 = v10.scale(v8.multiply_add(v52, p7.time_step, v50), p7.time_step)
    local v55 = v10.scale(v8.multiply_add(v53, p7.time_step, v51), p7.time_step)
    local v56 = v10.sub(v55, v54)
    local v57 = v10.sub(v10.add(v10.add(p7.body_b.center_of_mass, v25), v55), v10.add(v10.add(p7.body_a.center_of_mass, v24), v54))
    local v58 = v10.project(v56, v26)
    local v59 = v10.project(v57, v26)
    local v60 = table.create(3, 0)
    local v61 = table.create(3, 0)
    local v62 = v10.vector_to_array(v14.linear_position_allowance)
    local v63 = v10.vector_to_array(v14.linear_velocity_allowance)

    for i = 0, 2 do
        local v64 = v59[i + 1] - v62[i + 1]
        local v65 = v59[i + 1] + v62[i + 1]
        local v66 = v58[i + 1] - v63[i + 1] * p7.time_step
        local v67 = v58[i + 1] + v63[i + 1] * p7.time_step
        local v68 = v10.vmx_max(v64, v10.vmx_min(v66, v65))
        local v69 = v10.vmx_min(v65, v10.vmx_max(v67, v64))

        v60[i + 1] = v68 * v36[i + 1]
        v61[i + 1] = v69 * v36[i + 1]
    end

    local v70 = v10.sub(v8.multiply_add(p7.body_b.torque_acceleration, p7.time_step, v10.sub(p7.body_b.angular_velocity, p7.body_a.angular_velocity)), v10.scale(p7.body_a.torque_acceleration, p7.time_step))
    local v71 = v10.project(v10.scale(v70, p7.time_step), v29)
    local t2 = {
        v14.twist_velocity_allowance,
        v14.swing_velocity_allowance,
        v14.swing_velocity_allowance
    }
    local v72 = table.create(3, 0)
    local v73 = table.create(3, 0)

    for i = 0, 2 do
        local v74 = v30[i + 1] + v71[i + 1]
        local v75 = v31[i + 1] + v71[i + 1]
        local v76 = v71[i + 1] - t2[i + 1] * p7.time_step
        local v77 = t2[i + 1] * p7.time_step + v71[i + 1]
        local v78 = v10.vmx_max(v74, v10.vmx_min(v76, v75))
        local v79 = v10.vmx_min(v75, v10.vmx_max(v77, v74))

        v72[i + 1] = v78 * v44[i + 1]
        v73[i + 1] = v79 * v44[i + 1]
    end

    local v80 = v10.scaled_projection_columns(v26, v36)
    local v81 = v10.scaled_projection_columns(v29, v44)
    local v82 = v10.packed_inertia_columns(v34, v32)
    local v83 = v10.packed_inertia_columns(v35, v33)
    local t3 = {
        words = table.create(tu3.JACOBIAN_WORDS, 0)
    }
    local write_vector = t1.write_vector
    local x, y, z = v24.x, v24.y, v24.z

    buffer.writeu32(v1, 0, p7.body_a.reaction_guest_address)
    write_vector(t3, 0, {
        x,
        y,
        z,
        (buffer.readf32(v1, 0))
    })

    local write_vector2 = t1.write_vector
    local x2, y2, z2 = v25.x, v25.y, v25.z

    buffer.writeu32(v1, 0, p7.body_b.reaction_guest_address)
    write_vector2(t3, 1, {
        x2,
        y2,
        z2,
        (buffer.readf32(v1, 0))
    })
    t1.write_vector(t3, 4, {
        v80[1][1],
        v80[1][2],
        v80[1][3],
        0
    })
    t1.write_vector(t3, 5, {
        v81[1][1],
        v81[1][2],
        v81[1][3],
        0
    })
    t1.write_vector(t3, 6, {
        v80[2][1],
        v80[2][2],
        v80[2][3],
        v72[1]
    })
    t1.write_vector(t3, 7, {
        v81[2][1],
        v81[2][2],
        v81[2][3],
        v72[2]
    })
    t1.write_vector(t3, 8, {
        v80[3][1],
        v80[3][2],
        v80[3][3],
        v73[1]
    })
    t1.write_vector(t3, 9, {
        v81[3][1],
        v81[3][2],
        v81[3][3],
        v73[2]
    })
    t1.write_vector(t3, 10, {
        v60[1],
        v60[2],
        v60[3],
        v72[3]
    })
    t1.write_vector(t3, 11, {
        v61[1],
        v61[2],
        v61[3],
        v73[3]
    })

    local write_vector3 = t1.write_vector
    local x3, y3, z3 = v26[1].x, v26[1].y, v26[1].z

    buffer.writeu32(v1, 0, p7.joint_guest_address)
    write_vector3(t3, 12, {
        x3,
        y3,
        z3,
        (buffer.readf32(v1, 0))
    })
    t1.write_vector(t3, 13, {
        v26[2].x,
        v26[2].y,
        v26[2].z,
        v26[2].x
    })
    t1.write_vector(t3, 14, {
        v26[3].x,
        v26[3].y,
        v26[3].z,
        v26[1].y
    })

    for i = 0, 2 do
        t1.write_vector(t3, i + 15, {
            v29[i + 1].x,
            v29[i + 1].y,
            v29[i + 1].z,
            v29[i + 1].x
        })
    end

    for i = 0, 2 do
        t1.write_vector(t3, i + 18, v82[i + 1])
        t1.write_vector(t3, i + 21, v83[i + 1])
    end

    return t3
end

function t1.write_vector(p10, p11, p12) -- line: 337
    -- upvalues: v1 (copy)
    local v84 = p11 * 4

    for i = 0, 3 do
        local words = p10.words
        local v85 = v84 + i + 1
        local v86 = p12[i + 1]

        if v86 ~= 0 and v86 > -1.1754943508222875E-38 and v86 < 1.1754943508222875E-38 then
            local v87 = math.abs(v86) * 7.1362384635298E+44
            local v88 = math.floor(v87)
            local v89 = v87 - v88
            local v90 = if v89 > 0.5 or v89 == 0.5 and v88 % 2 == 1 then v88 + 1 else v88

            if v86 < 0 then
                words[v85] = v90 + 2147483648
            else
                words[v85] = v90
            end
        else
            buffer.writef32(v1, 0, v86)
            words[v85] = buffer.readu32(v1, 0)
        end
    end
end

local to_bits = rt.to_bits
local v91 = buffer.create(8)

local function from_bits(p13) -- line: 355
    -- upvalues: v91 (copy)
    buffer.writeu32(v91, 0, p13)

    return (buffer.readf32(v91, 0))
end

local function to_bits2(p14) -- line: 359
    -- upvalues: to_bits (copy), v91 (copy)
    if p14 ~= 0 and p14 > -1.1754943508222875E-38 and p14 < 1.1754943508222875E-38 then
        return to_bits(p14)
    end

    buffer.writef32(v91, 0, p14)

    return (buffer.readu32(v91, 0))
end

local fround = rt.fround

local function fmin(p15, p16) -- line: 369
    if p15 == p15 and (p16 ~= p16 or p15 < p16) then
        return p15
    end

    return p16
end

local function fmax(p17, p18) -- line: 378
    if p17 == p17 and (p18 ~= p18 or p18 < p17) then
        return p17
    end

    return p18
end

local is_finite = rt.is_finite

local function compose(p19, p20, p21, p22, p23) -- line: 391
    local x, y, z, w = p19.x, p19.y, p19.z, p19.w

    return x * p23 + (p20 * w + (-z * p21 + y * p22)), y * p23 + (p21 * w + (-x * p22 + z * p20)), z * p23 + (p22 * w + (-y * p20 + x * p21)), w * p23 - (x * p20 + y * p21 + z * p22)
end

local function basis(p24, p25, p26, p27) -- line: 400
    local v92 = p24 * 1.4142135381698608
    local v93 = p25 * 1.4142135381698608
    local v94 = p26 * 1.4142135381698608
    local v95 = p27 * 1.4142135381698608
    local v96 = -v92 * v92 + 0.5
    local v97 = -v93 * v93 + 0.5
    local v98 = -v94 * v94 + 0.5
    local v99 = v92 * v93
    local v100 = v93 * v94
    local v101 = v94 * v92
    local v102 = v95 * v94
    local v103 = v95 * v92
    local v104 = v95 * v93

    return v97 + v98, v99 + v102, v101 - v104, v99 - v102, v98 + v96, v100 + v103, v101 + v104, v100 - v103, v96 + v97
end

local function inertia_from_zero(p28, p29, p30, p31, p32, p33, p34, p35, p36) -- line: 418
    return p30 * p36 + (p29 * p35 + (p28 * p34 + 0)), p33 * p36 + (p32 * p35 + (p29 * p34 + 0)), p31 * p36 + (p33 * p35 + (p30 * p34 + 0))
end

local function linear_inverse_mass(p37, p38, p39, p40, p41, p42, p43, p44, p45, p46, p47, p48, p49, p50, p51, p52, p53, p54, p55, p56, p57, p58, p59) -- line: 425
    local v105 = -p39 * p44 + p38 * p45
    local v106 = -p37 * p45 + p39 * p43
    local v107 = -p38 * p43 + p37 * p44
    local v108 = -p42 * p44 + p41 * p45
    local v109 = -p40 * p45 + p42 * p43
    local v110 = -p41 * p43 + p40 * p44
    local v111 = p48 * v107 + (p47 * v106 + (p46 * v105 + 0))
    local v112 = p51 * v107 + (p50 * v106 + (p47 * v105 + 0))
    local v113 = p49 * v107 + (p51 * v106 + (p48 * v105 + 0))
    local v114 = p54 * v110 + (p53 * v109 + (p52 * v108 + 0))
    local v115 = p57 * v110 + (p56 * v109 + (p53 * v108 + 0))
    local v116 = p55 * v110 + (p57 * v109 + (p54 * v108 + 0))
    local v117 = v108 * v114 + (v105 * v111 + 0)
    local v118 = v109 * v115 + (v106 * v112 + 0)

    return 1 / (v110 * v116 + (v107 * v113 + 0) + v118 + (v117 + (p58 + p59)))
end

local function angular_inverse_mass(p60, p61, p62, p63, p64, p65, p66, p67, p68, p69, p70, p71, p72, p73, p74) -- line: 447
    local v119 = p65 * p62 + (p64 * p61 + (p63 * p60 + 0))
    local v120 = p68 * p62 + (p67 * p61 + (p64 * p60 + 0))
    local v121 = p66 * p62 + (p68 * p61 + (p65 * p60 + 0))
    local v122 = p71 * p62 + (p70 * p61 + (p69 * p60 + 0))
    local v123 = p74 * p62 + (p73 * p61 + (p70 * p60 + 0))
    local v124 = p72 * p62 + (p74 * p61 + (p71 * p60 + 0))
    local v125 = p60 * (v119 + v122) + 0
    local v126 = p61 * (v120 + v123) + 0

    return 0.5 * (1 / (p62 * (v121 + v124) + 0 + (v125 + v126)))
end

local function linear_limit(p75, p76, p77, p78, p79, p80) -- line: 458
    local v127 = p75 - p76
    local v128 = p75 + p76
    local v129 = p77 - p78 * p79
    local v130 = p77 + p78 * p79

    if v129 ~= v129 or v128 == v128 and not (v129 < v128) then
        v129 = v128
    end

    if v127 == v127 and (v129 ~= v129 or v129 < v127) then
        v129 = v127
    end

    if v130 ~= v130 or v127 == v127 and not (v127 < v130) then
        v130 = v127
    end

    if v128 ~= v128 or v130 == v130 and not (v128 < v130) then
        v128 = v130
    end

    return v129 * p80, v128 * p80
end

local function angular_limit(p81, p82, p83, p84, p85, p86) -- line: 469
    local v131 = p81 + p83
    local v132 = p82 + p83
    local v133 = p83 - p84 * p85
    local v134 = p84 * p85 + p83

    if v133 ~= v133 or v132 == v132 and not (v133 < v132) then
        v133 = v132
    end

    if v131 == v131 and (v133 ~= v133 or v133 < v131) then
        v133 = v131
    end

    if v134 ~= v134 or v131 == v131 and not (v131 < v134) then
        v134 = v131
    end

    if v132 ~= v132 or v134 == v134 and not (v132 < v134) then
        v132 = v134
    end

    return v133 * p86, v132 * p86
end

local function angular_rows(p87, p88, p89, p90, p91, p92, p93, p94, p95, p96, p97, p98, p99, p100, p101, p102, p103, p104, p105, p106, p107, p108, p109, p110, p111, p112, p113, p114, p115, p116) -- line: 485
    -- upvalues: v8 (copy), tu3 (copy), fround (copy)
    local FINITE_INFINITY = tu3.FINITE_INFINITY
    local v135 = -FINITE_INFINITY
    local v136 = -FINITE_INFINITY
    local v137 = -FINITE_INFINITY
    local v138 = p109 * p113
    local v139 = p109 * p114
    local v140 = p109 * p115
    local v141 = p109 * p116
    local v142 = p110 * p113
    local v143 = p110 * p114
    local v144 = p110 * p115
    local v145 = p110 * p116
    local v146 = p111 * p113
    local v147 = p111 * p114
    local v148 = p111 * p115
    local v149 = p111 * p116
    local v150 = p112 * p113
    local v151 = p112 * p114
    local v152 = p112 * p115
    local v153 = p112 * p116
    local v154 = p91 * p100 + p92 * p101 + p93 * p102
    local v155 = p91 * p103 + p92 * p104 + p93 * p105
    local v156 = p91 * p106 + p92 * p107 + p93 * p108
    local v157, v158, v159, v160, v161, v162, v163, v164, v165, v166

    if p87 == 0 then
        v158 = v142 + v139 - v152 - v149
        v159 = v153 + v143 - v148 - v138
        v160 = v144 + v147 + v150 + v141
        v161 = v140 + v146 + v145 + v151
        v162 = v147 + v144 - v150 - v141
        v163 = v153 + v148 - v138 - v143
        v164 = 2 * (v151 - v145 + v140 - v146)
        v165 = 2 * (v152 - v149 + v142 - v139)
        v166 = v165
        v157 = v164
    else
        v157 = FINITE_INFINITY
        v158 = p103
        v159 = p104
        v160 = p105
        v161 = p106
        v162 = p107
        v163 = p108
        v164 = v136
        v165 = v137
        v166 = FINITE_INFINITY

        if p87 == 1 then
            if not (tu3.NEAR_PARALLEL <= v154) then
                local v167 = fround(v155 * v155 + v156 * v156)
                local v168 = v167 * v8.reciprocal_sqrt(v167)

                if v167 == 0 then
                    v168 = 0
                end

                local v169 = v8.reciprocal(v168) * 1

                v158 = (-p93 * p101 + p92 * p102) * v169
                v159 = (-p91 * p102 + p93 * p100) * v169
                v160 = (-p92 * p100 + p91 * p101) * v169
                v161 = -v160 * p92 + v159 * p93
                v162 = -v158 * p93 + v160 * p91
                v163 = -v159 * p91 + v158 * p92
                v164 = (p89 - v154) * v169
            end
        elseif p87 == 2 or p87 == 3 then
            local v170, v171, v172, v173

            if p88 == 0 then
                v170 = v140 + v146 + v145 + v151
                v171 = v147 + v144 - v150 - v141
                v172 = v153 + v148 - v138 - v143
                v173 = 2 * (v152 - v149 + v142 - v139)
            else
                v170 = -p93 * p104 + p92 * p105
                v171 = -p91 * p105 + p93 * p103
                v172 = -p92 * p103 + p91 * p104
                v173 = -v155
            end

            v166 = v173

            if p87 == 2 and v156 ~= 0 then
                v157 = v8.reciprocal(v156) * (p89 - v154)

                if not (v156 < 0) then
                    v164 = v157
                    v157 = FINITE_INFINITY
                end
            end

            v161 = v170
            v162 = v171
            v163 = v172
            v165 = v173
        end
    end

    if p88 == 0 then
        local v174 = v153 + v138 - v143 - v148
        local v175 = v142 + v139 + v152 + v149
        local v176 = v140 + v146 - v151 - v145
        local v177 = 2 * (v150 - v141 + v147 - v144)

        return v174, v175, v176, v158, v159, v160, v161, v162, v163, v177, v164, v165, v177, v157, v166
    end

    local v178, v179, v180

    if p88 == 1 then
        local v181 = p97 * p103 + p98 * p104 + p99 * p105 - (p94 * p106 + p95 * p107 + p96 * p108)

        if v181 ~= 0 then
            local v182 = (1 + v154) * p90 - (p94 * p103 + p95 * p104 + p96 * p105 + (p97 * p106 + p98 * p107 + p99 * p108))
            local v183 = v8.reciprocal(v181) * v182

            if v181 < 0 then
                return p91, p92, p93, v158, v159, v160, v161, v162, v163, v135, v164, v165, v183, v157, v166
            end

            v135 = v183
        end

        v178 = p91
        v179 = p92
        v180 = p93
    else
        v178 = p100
        v179 = p101
        v180 = p102
    end

    return v178, v179, v180, v158, v159, v160, v161, v162, v163, v135, v164, v165, FINITE_INFINITY, v157, v166
end

local function build_core_r3(p117, p118, p119, p120, p121, p122, p123, p124, p125, p126, p127, p128, p129, p130, p131, p132, p133, p134, p135, p136, p137, p138, p139, p140, p141, p142, p143, p144, p145, p146, p147, p148, p149, p150, p151, p152, p153) -- line: 615
    -- upvalues: tu3 (copy), to_bits (copy), v91 (copy), is_finite (copy), compose (copy), basis (copy), linear_inverse_mass (copy), angular_inverse_mass (copy), angular_rows (copy)
    if not (is_finite(p120) and p120 > 0) then
        error("assertion failed: input.time_step.is_finite() && input.time_step > 0.0", 0)
    end

    local words = p118.words
    local words2 = p119.words
    local v184 = tu3.ACTIVE_BODY
    local v185 = bit32.band(p122, v184) ~= 0
    local v186 = tu3.ACTIVE_BODY
    local v187 = bit32.band(p138, v186) ~= 0
    local v188 = words2[17]

    buffer.writeu32(v91, 0, v188)

    local v189 = buffer.readf32(v91, 0)

    buffer.writeu32(v91, 0, words2[18])

    local v191 = buffer.readf32(v91, 0)

    buffer.writeu32(v91, 0, words2[19])

    local v193 = buffer.readf32(v91, 0)

    buffer.writeu32(v91, 0, words2[20])

    local v195, v196, v197

    v195, v184, v186, v196, v188, v189, v191, v193, v197 = basis(compose(p140, v189, v191, v193, (buffer.readf32(v91, 0))))
    buffer.writeu32(v91, 0, words2[5])

    local v198 = buffer.readf32(v91, 0)

    buffer.writeu32(v91, 0, words2[6])

    local v199 = buffer.readf32(v91, 0)

    buffer.writeu32(v91, 0, words2[7])

    local v200 = buffer.readf32(v91, 0)
    local columns = p126.columns
    local v201 = columns[1]
    local v202 = columns[2]
    local v203 = columns[3]
    local v204 = v203[1] * v200 + (v202[1] * v199 + v201[1] * v198)
    local v205 = v203[2] * v200 + (v202[2] * v199 + v201[2] * v198)
    local v206 = v203[3] * v200 + (v202[3] * v199 + v201[3] * v198)

    buffer.writeu32(v91, 0, words2[13])

    local v207 = buffer.readf32(v91, 0)

    buffer.writeu32(v91, 0, words2[14])

    local v208 = buffer.readf32(v91, 0)

    buffer.writeu32(v91, 0, words2[15])

    local v209 = buffer.readf32(v91, 0)

    v203 = p142.columns

    local v210 = v203[1]
    local v211 = v203[2]
    local v212 = v203[3]
    local v213 = v212[1] * v209 + (v211[1] * v208 + v210[1] * v207)
    local v214 = v212[2] * v209 + (v211[2] * v208 + v210[2] * v207)
    local v215 = v212[3] * v209 + (v211[3] * v208 + v210[3] * v207)
    local v216 = words2[1]

    buffer.writeu32(v91, 0, v216)

    local v217 = buffer.readf32(v91, 0)

    buffer.writeu32(v91, 0, words2[2])

    local v219 = buffer.readf32(v91, 0)

    buffer.writeu32(v91, 0, words2[3])

    local v221 = buffer.readf32(v91, 0)

    buffer.writeu32(v91, 0, words2[4])

    local v223, v224, v225

    v223, v224, v225, v216 = compose(p124, v217, v219, v221, (buffer.readf32(v91, 0)))

    local v226 = words2[9]

    buffer.writeu32(v91, 0, v226)

    local v227 = buffer.readf32(v91, 0)

    buffer.writeu32(v91, 0, words2[10])

    local v229 = buffer.readf32(v91, 0)

    buffer.writeu32(v91, 0, words2[11])

    local v231 = buffer.readf32(v91, 0)

    buffer.writeu32(v91, 0, words2[12])
    v217, v219, v221, v226 = compose(p140, v227, v229, v231, (buffer.readf32(v91, 0)))

    local v233, v234, v235, v236, v237, v238

    v227, v229, v231, v235, v236, v237, v238, v233, v234 = basis(v223, v224, v225, v216)

    local v239, v240, v241, v242, v243, v244, v245, v246, v247 = basis(v217, v219, v221, v226)
    local v248 = words[15]
    local v249 = words[16]
    local v250 = words[13]

    buffer.writeu32(v91, 0, v250)

    local v251 = buffer.readf32(v91, 0)

    buffer.writeu32(v91, 0, words[14])

    local v253, v254, v255, v256, v257, v258, v259, v260, v261, v262, v263

    v253, v248, v249, v254, v250, v251, v255, v256, v257, v258, v259, v260, v261, v262, v263 = angular_rows(v248, v249, v251, buffer.readf32(v91, 0), v227, v229, v231, v235, v236, v237, v238, v233, v234, v239, v240, v241, v242, v243, v244, v245, v246, v247, v223, v224, v225, v216, v217, v219, v221, v226)

    local v264 = if v185 then p131 else 0
    local v265 = if v185 then p132 else 0
    local v266 = if v185 then p133 else 0
    local v267 = if v185 then p134 else 0
    local v268 = if v185 then p135 else 0
    local v269 = if v185 then p136 else 0
    local v270 = if v185 then p137 else 0
    local v277 = if v187 then p147 else 0
    local v271 = if v187 then p148 else 0
    local v272 = if v187 then p149 else 0
    local v273 = if v187 then p150 else 0
    local v274 = if v187 then p151 else 0
    local v275 = if v187 then p152 else 0
    local v276 = if v187 then p153 else 0
    local v278 = linear_inverse_mass(v204, v205, v206, v213, v214, v215, v195, v184, v186, v265, v266, v267, v268, v269, v270, v271, v272, v273, v274, v275, v276, v264, v277)
    local v279 = linear_inverse_mass(v204, v205, v206, v213, v214, v215, v196, v188, v189, v265, v266, v267, v268, v269, v270, v271, v272, v273, v274, v275, v276, v264, v277)
    local v280 = linear_inverse_mass(v204, v205, v206, v213, v214, v215, v191, v193, v197, v265, v266, v267, v268, v269, v270, v271, v272, v273, v274, v275, v276, v264, v277)

    v223 = angular_inverse_mass(v253, v248, v249, v265, v266, v267, v268, v269, v270, v271, v272, v273, v274, v275, v276)
    v224 = angular_inverse_mass(v254, v250, v251, v265, v266, v267, v268, v269, v270, v271, v272, v273, v274, v275, v276)
    v225 = angular_inverse_mass(v255, v256, v257, v265, v266, v267, v268, v269, v270, v271, v272, v273, v274, v275, v276)
    v229 = v206 * p128.y + (-v205 * p128.z + p127.x)
    v231 = v204 * p128.z + (-v206 * p128.x + p127.y)
    v235 = v205 * p128.x + (-v204 * p128.y + p127.z)
    v236 = v215 * p144.y + (-v214 * p144.z + p143.x)
    v237 = v213 * p144.z + (-v215 * p144.x + p143.y)
    v238 = v214 * p144.x + (-v213 * p144.y + p143.z)
    v233 = v206 * p130.y + (-v205 * p130.z + p129.x)
    v234 = v204 * p130.z + (-v206 * p130.x + p129.y)
    v239 = v205 * p130.x + (-v204 * p130.y + p129.z)
    v240 = v215 * p146.y + (-v214 * p146.z + p145.x)
    v241 = v213 * p146.z + (-v215 * p146.x + p145.y)
    v242 = v214 * p146.x + (-v213 * p146.y + p145.z)
    v243 = (v233 * p120 + v229) * p120
    v233 = (v234 * p120 + v231) * p120
    v234 = (v239 * p120 + v235) * p120
    v239 = (v240 * p120 + v236) * p120
    v240 = (v241 * p120 + v237) * p120
    v241 = (v242 * p120 + v238) * p120
    v242 = v239 - v243
    v238 = v240 - v233
    v237 = v241 - v234
    v236 = p141.x + v213 + v239 - (p125.x + v204 + v243)
    v243 = p141.y + v214 + v240 - (p125.y + v205 + v233)
    v240 = p141.z + v215 + v241 - (p125.z + v206 + v234)
    v216 = v242 * v195 + v238 * v184 + v237 * v186
    v217 = v242 * v196 + v238 * v188 + v237 * v189
    v219 = v242 * v191 + v238 * v193 + v237 * v197
    v221 = v236 * v195 + v243 * v184 + v240 * v186
    v226 = v236 * v196 + v243 * v188 + v240 * v189
    v227 = v236 * v191 + v243 * v193 + v240 * v197
    buffer.writeu32(v91, 0, words[1])
    v238 = buffer.readf32(v91, 0)
    buffer.writeu32(v91, 0, words[5])
    v234 = buffer.readf32(v91, 0)
    v233 = v221 - v238

    local v281 = v221 + v238

    v239 = v216 - v234 * p120
    v240 = v216 + v234 * p120

    if v239 ~= v239 or v281 == v281 and not (v239 < v281) then
        v239 = v281
    end

    if v233 == v233 and (v239 ~= v239 or v239 < v233) then
        v239 = v233
    end

    if v240 ~= v240 or v233 == v233 and not (v233 < v240) then
        v240 = v233
    end

    if v281 ~= v281 or v240 == v240 and not (v281 < v240) then
        v281 = v240
    end

    v229 = v239 * v278
    v231 = v281 * v278
    buffer.writeu32(v91, 0, words[2])
    v234 = buffer.readf32(v91, 0)
    buffer.writeu32(v91, 0, words[6])
    v240 = buffer.readf32(v91, 0)
    v221 = v226 - v234
    v216 = v226 + v234
    v239 = v217 - v240 * p120
    v240 = v217 + v240 * p120

    if v239 ~= v239 or v216 == v216 and not (v239 < v216) then
        v239 = v216
    end

    if v221 == v221 and (v239 ~= v239 or v239 < v221) then
        v239 = v221
    end

    if v240 ~= v240 or v221 == v221 and not (v221 < v240) then
        v240 = v221
    end

    if v216 ~= v216 or v240 == v240 and not (v216 < v240) then
        v216 = v240
    end

    v235 = v239 * v279
    v236 = v216 * v279
    buffer.writeu32(v91, 0, words[3])
    v240 = buffer.readf32(v91, 0)
    buffer.writeu32(v91, 0, words[7])
    v242 = buffer.readf32(v91, 0)
    v226 = v227 - v240
    v217 = v227 + v240
    v241 = v219 - v242 * p120
    v242 = v219 + v242 * p120

    if v241 ~= v241 or v217 == v217 and not (v241 < v217) then
        v241 = v217
    end

    if v226 == v226 and (v241 ~= v241 or v241 < v226) then
        v241 = v226
    end

    if v242 ~= v242 or v226 == v226 and not (v226 < v242) then
        v242 = v226
    end

    if v217 ~= v217 or v242 == v242 and not (v217 < v242) then
        v217 = v242
    end

    v237 = v241 * v280
    v238 = v217 * v280
    v227 = (p146.x * p120 + (p144.x - p128.x) - p130.x * p120) * p120
    v219 = (p146.y * p120 + (p144.y - p128.y) - p130.y * p120) * p120
    v243 = (p146.z * p120 + (p144.z - p128.z) - p130.z * p120) * p120
    buffer.writeu32(v91, 0, words[9])
    v246 = buffer.readf32(v91, 0)
    buffer.writeu32(v91, 0, words[10])
    v247 = buffer.readf32(v91, 0)

    local v283 = v227 * v253 + v219 * v248 + v243 * v249
    local v284 = v258 + v283
    local v285 = v261 + v283
    local v252 = v283 - v246 * p120
    local v286 = v246 * p120 + v283

    if v252 ~= v252 or v285 == v285 and not (v252 < v285) then
        v252 = v285
    end

    if v284 == v284 and (v252 ~= v252 or v252 < v284) then
        v252 = v284
    end

    if v286 ~= v286 or v284 == v284 and not (v284 < v286) then
        v286 = v284
    end

    if v285 ~= v285 or v286 == v286 and not (v285 < v286) then
        v285 = v286
    end

    local v287 = v252 * v223
    local v288 = v285 * v223

    v283 = v227 * v254 + v219 * v250 + v243 * v251
    v244 = v259 + v283
    v284 = v262 + v283
    v285 = v283 - v247 * p120
    v252 = v247 * p120 + v283

    if v285 ~= v285 or v284 == v284 and not (v285 < v284) then
        v285 = v284
    end

    if v244 == v244 and (v285 ~= v285 or v285 < v244) then
        v285 = v244
    end

    if v252 ~= v252 or v244 == v244 and not (v244 < v252) then
        v252 = v244
    end

    if v284 ~= v284 or v252 == v252 and not (v284 < v252) then
        v284 = v252
    end

    local v282 = v285 * v224
    local v289 = v284 * v224

    v283 = v227 * v255 + v219 * v256 + v243 * v257
    v284 = v260 + v283
    v285 = v263 + v283
    v252 = v283 - v247 * p120
    v286 = v247 * p120 + v283

    if v252 ~= v252 or v285 == v285 and not (v252 < v285) then
        v252 = v285
    end

    if v284 == v284 and (v252 ~= v252 or v252 < v284) then
        v252 = v284
    end

    if v286 ~= v286 or v284 == v284 and not (v284 < v286) then
        v286 = v284
    end

    if v285 ~= v285 or v286 == v286 and not (v285 < v286) then
        v285 = v286
    end

    v246 = v252 * v225
    v247 = v285 * v225

    if v204 ~= 0 and v204 > -1.1754943508222875E-38 and v204 < 1.1754943508222875E-38 then
        p117[1] = to_bits(v204)
    else
        buffer.writef32(v91, 0, v204)
        p117[1] = buffer.readu32(v91, 0)
    end

    if v205 ~= 0 and v205 > -1.1754943508222875E-38 and v205 < 1.1754943508222875E-38 then
        p117[2] = to_bits(v205)
    else
        buffer.writef32(v91, 0, v205)
        p117[2] = buffer.readu32(v91, 0)
    end

    if v206 ~= 0 and v206 > -1.1754943508222875E-38 and v206 < 1.1754943508222875E-38 then
        p117[3] = to_bits(v206)
    else
        buffer.writef32(v91, 0, v206)
        p117[3] = buffer.readu32(v91, 0)
    end

    buffer.writeu32(v91, 0, p123)
    v244 = buffer.readf32(v91, 0)

    if v244 ~= 0 and v244 > -1.1754943508222875E-38 and v244 < 1.1754943508222875E-38 then
        p117[4] = to_bits(v244)
    else
        buffer.writef32(v91, 0, v244)
        p117[4] = buffer.readu32(v91, 0)
    end

    if v213 ~= 0 and v213 > -1.1754943508222875E-38 and v213 < 1.1754943508222875E-38 then
        p117[5] = to_bits(v213)
    else
        buffer.writef32(v91, 0, v213)
        p117[5] = buffer.readu32(v91, 0)
    end

    if v214 ~= 0 and v214 > -1.1754943508222875E-38 and v214 < 1.1754943508222875E-38 then
        p117[6] = to_bits(v214)
    else
        buffer.writef32(v91, 0, v214)
        p117[6] = buffer.readu32(v91, 0)
    end

    if v215 ~= 0 and v215 > -1.1754943508222875E-38 and v215 < 1.1754943508222875E-38 then
        p117[7] = to_bits(v215)
    else
        buffer.writef32(v91, 0, v215)
        p117[7] = buffer.readu32(v91, 0)
    end

    buffer.writeu32(v91, 0, p139)
    v244 = buffer.readf32(v91, 0)

    if v244 ~= 0 and v244 > -1.1754943508222875E-38 and v244 < 1.1754943508222875E-38 then
        p117[8] = to_bits(v244)
    else
        buffer.writef32(v91, 0, v244)
        p117[8] = buffer.readu32(v91, 0)
    end

    p117[9] = 0
    p117[10] = 0
    p117[11] = 0
    p117[12] = 0
    p117[13] = 0
    p117[14] = 0
    p117[15] = 0
    p117[16] = 0
    v244 = v195 * v278

    if v244 ~= 0 and v244 > -1.1754943508222875E-38 and v244 < 1.1754943508222875E-38 then
        p117[17] = to_bits(v244)
    else
        buffer.writef32(v91, 0, v244)
        p117[17] = buffer.readu32(v91, 0)
    end

    v244 = v196 * v279

    if v244 ~= 0 and v244 > -1.1754943508222875E-38 and v244 < 1.1754943508222875E-38 then
        p117[18] = to_bits(v244)
    else
        buffer.writef32(v91, 0, v244)
        p117[18] = buffer.readu32(v91, 0)
    end

    v244 = v191 * v280

    if v244 ~= 0 and v244 > -1.1754943508222875E-38 and v244 < 1.1754943508222875E-38 then
        p117[19] = to_bits(v244)
    else
        buffer.writef32(v91, 0, v244)
        p117[19] = buffer.readu32(v91, 0)
    end

    p117[20] = 0
    v244 = v253 * v223

    if v244 ~= 0 and v244 > -1.1754943508222875E-38 and v244 < 1.1754943508222875E-38 then
        p117[21] = to_bits(v244)
    else
        buffer.writef32(v91, 0, v244)
        p117[21] = buffer.readu32(v91, 0)
    end

    v244 = v254 * v224

    if v244 ~= 0 and v244 > -1.1754943508222875E-38 and v244 < 1.1754943508222875E-38 then
        p117[22] = to_bits(v244)
    else
        buffer.writef32(v91, 0, v244)
        p117[22] = buffer.readu32(v91, 0)
    end

    v244 = v255 * v225

    if v244 ~= 0 and v244 > -1.1754943508222875E-38 and v244 < 1.1754943508222875E-38 then
        p117[23] = to_bits(v244)
    else
        buffer.writef32(v91, 0, v244)
        p117[23] = buffer.readu32(v91, 0)
    end

    p117[24] = 0
    v244 = v184 * v278

    if v244 ~= 0 and v244 > -1.1754943508222875E-38 and v244 < 1.1754943508222875E-38 then
        p117[25] = to_bits(v244)
    else
        buffer.writef32(v91, 0, v244)
        p117[25] = buffer.readu32(v91, 0)
    end

    v244 = v188 * v279

    if v244 ~= 0 and v244 > -1.1754943508222875E-38 and v244 < 1.1754943508222875E-38 then
        p117[26] = to_bits(v244)
    else
        buffer.writef32(v91, 0, v244)
        p117[26] = buffer.readu32(v91, 0)
    end

    v244 = v193 * v280

    if v244 ~= 0 and v244 > -1.1754943508222875E-38 and v244 < 1.1754943508222875E-38 then
        p117[27] = to_bits(v244)
    else
        buffer.writef32(v91, 0, v244)
        p117[27] = buffer.readu32(v91, 0)
    end

    if v287 ~= 0 and v287 > -1.1754943508222875E-38 and v287 < 1.1754943508222875E-38 then
        p117[28] = to_bits(v287)
    else
        buffer.writef32(v91, 0, v287)
        p117[28] = buffer.readu32(v91, 0)
    end

    v244 = v248 * v223

    if v244 ~= 0 and v244 > -1.1754943508222875E-38 and v244 < 1.1754943508222875E-38 then
        p117[29] = to_bits(v244)
    else
        buffer.writef32(v91, 0, v244)
        p117[29] = buffer.readu32(v91, 0)
    end

    v244 = v250 * v224

    if v244 ~= 0 and v244 > -1.1754943508222875E-38 and v244 < 1.1754943508222875E-38 then
        p117[30] = to_bits(v244)
    else
        buffer.writef32(v91, 0, v244)
        p117[30] = buffer.readu32(v91, 0)
    end

    v244 = v256 * v225

    if v244 ~= 0 and v244 > -1.1754943508222875E-38 and v244 < 1.1754943508222875E-38 then
        p117[31] = to_bits(v244)
    else
        buffer.writef32(v91, 0, v244)
        p117[31] = buffer.readu32(v91, 0)
    end

    if v282 ~= 0 and v282 > -1.1754943508222875E-38 and v282 < 1.1754943508222875E-38 then
        p117[32] = to_bits(v282)
    else
        buffer.writef32(v91, 0, v282)
        p117[32] = buffer.readu32(v91, 0)
    end

    v244 = v186 * v278

    if v244 ~= 0 and v244 > -1.1754943508222875E-38 and v244 < 1.1754943508222875E-38 then
        p117[33] = to_bits(v244)
    else
        buffer.writef32(v91, 0, v244)
        p117[33] = buffer.readu32(v91, 0)
    end

    v244 = v189 * v279

    if v244 ~= 0 and v244 > -1.1754943508222875E-38 and v244 < 1.1754943508222875E-38 then
        p117[34] = to_bits(v244)
    else
        buffer.writef32(v91, 0, v244)
        p117[34] = buffer.readu32(v91, 0)
    end

    v244 = v197 * v280

    if v244 ~= 0 and v244 > -1.1754943508222875E-38 and v244 < 1.1754943508222875E-38 then
        p117[35] = to_bits(v244)
    else
        buffer.writef32(v91, 0, v244)
        p117[35] = buffer.readu32(v91, 0)
    end

    if v288 ~= 0 and v288 > -1.1754943508222875E-38 and v288 < 1.1754943508222875E-38 then
        p117[36] = to_bits(v288)
    else
        buffer.writef32(v91, 0, v288)
        p117[36] = buffer.readu32(v91, 0)
    end

    v244 = v249 * v223

    if v244 ~= 0 and v244 > -1.1754943508222875E-38 and v244 < 1.1754943508222875E-38 then
        p117[37] = to_bits(v244)
    else
        buffer.writef32(v91, 0, v244)
        p117[37] = buffer.readu32(v91, 0)
    end

    v244 = v251 * v224

    if v244 ~= 0 and v244 > -1.1754943508222875E-38 and v244 < 1.1754943508222875E-38 then
        p117[38] = to_bits(v244)
    else
        buffer.writef32(v91, 0, v244)
        p117[38] = buffer.readu32(v91, 0)
    end

    v244 = v257 * v225

    if v244 ~= 0 and v244 > -1.1754943508222875E-38 and v244 < 1.1754943508222875E-38 then
        p117[39] = to_bits(v244)
    else
        buffer.writef32(v91, 0, v244)
        p117[39] = buffer.readu32(v91, 0)
    end

    if v289 ~= 0 and v289 > -1.1754943508222875E-38 and v289 < 1.1754943508222875E-38 then
        p117[40] = to_bits(v289)
    else
        buffer.writef32(v91, 0, v289)
        p117[40] = buffer.readu32(v91, 0)
    end

    if v229 ~= 0 and v229 > -1.1754943508222875E-38 and v229 < 1.1754943508222875E-38 then
        p117[41] = to_bits(v229)
    else
        buffer.writef32(v91, 0, v229)
        p117[41] = buffer.readu32(v91, 0)
    end

    if v235 ~= 0 and v235 > -1.1754943508222875E-38 and v235 < 1.1754943508222875E-38 then
        p117[42] = to_bits(v235)
    else
        buffer.writef32(v91, 0, v235)
        p117[42] = buffer.readu32(v91, 0)
    end

    if v237 ~= 0 and v237 > -1.1754943508222875E-38 and v237 < 1.1754943508222875E-38 then
        p117[43] = to_bits(v237)
    else
        buffer.writef32(v91, 0, v237)
        p117[43] = buffer.readu32(v91, 0)
    end

    if v246 ~= 0 and v246 > -1.1754943508222875E-38 and v246 < 1.1754943508222875E-38 then
        p117[44] = to_bits(v246)
    else
        buffer.writef32(v91, 0, v246)
        p117[44] = buffer.readu32(v91, 0)
    end

    if v231 ~= 0 and v231 > -1.1754943508222875E-38 and v231 < 1.1754943508222875E-38 then
        p117[45] = to_bits(v231)
    else
        buffer.writef32(v91, 0, v231)
        p117[45] = buffer.readu32(v91, 0)
    end

    if v236 ~= 0 and v236 > -1.1754943508222875E-38 and v236 < 1.1754943508222875E-38 then
        p117[46] = to_bits(v236)
    else
        buffer.writef32(v91, 0, v236)
        p117[46] = buffer.readu32(v91, 0)
    end

    if v238 ~= 0 and v238 > -1.1754943508222875E-38 and v238 < 1.1754943508222875E-38 then
        p117[47] = to_bits(v238)
    else
        buffer.writef32(v91, 0, v238)
        p117[47] = buffer.readu32(v91, 0)
    end

    if v247 ~= 0 and v247 > -1.1754943508222875E-38 and v247 < 1.1754943508222875E-38 then
        p117[48] = to_bits(v247)
    else
        buffer.writef32(v91, 0, v247)
        p117[48] = buffer.readu32(v91, 0)
    end

    if v184 ~= 0 and v184 > -1.1754943508222875E-38 and v184 < 1.1754943508222875E-38 then
        v242 = to_bits(v184)
    else
        buffer.writef32(v91, 0, v184)
        v242 = buffer.readu32(v91, 0)
    end

    if v195 ~= 0 and v195 > -1.1754943508222875E-38 and v195 < 1.1754943508222875E-38 then
        p117[49] = to_bits(v195)
    else
        buffer.writef32(v91, 0, v195)
        p117[49] = buffer.readu32(v91, 0)
    end

    p117[50] = v242

    if v186 ~= 0 and v186 > -1.1754943508222875E-38 and v186 < 1.1754943508222875E-38 then
        p117[51] = to_bits(v186)
    else
        buffer.writef32(v91, 0, v186)
        p117[51] = buffer.readu32(v91, 0)
    end

    buffer.writeu32(v91, 0, p121)
    v244 = buffer.readf32(v91, 0)

    if v244 ~= 0 and v244 > -1.1754943508222875E-38 and v244 < 1.1754943508222875E-38 then
        p117[52] = to_bits(v244)
    else
        buffer.writef32(v91, 0, v244)
        p117[52] = buffer.readu32(v91, 0)
    end

    p117[60] = v242

    if v196 ~= 0 and v196 > -1.1754943508222875E-38 and v196 < 1.1754943508222875E-38 then
        v242 = to_bits(v196)
    else
        buffer.writef32(v91, 0, v196)
        v242 = buffer.readu32(v91, 0)
    end

    p117[53] = v242

    if v188 ~= 0 and v188 > -1.1754943508222875E-38 and v188 < 1.1754943508222875E-38 then
        p117[54] = to_bits(v188)
    else
        buffer.writef32(v91, 0, v188)
        p117[54] = buffer.readu32(v91, 0)
    end

    if v189 ~= 0 and v189 > -1.1754943508222875E-38 and v189 < 1.1754943508222875E-38 then
        p117[55] = to_bits(v189)
    else
        buffer.writef32(v91, 0, v189)
        p117[55] = buffer.readu32(v91, 0)
    end

    p117[56] = v242

    if v191 ~= 0 and v191 > -1.1754943508222875E-38 and v191 < 1.1754943508222875E-38 then
        p117[57] = to_bits(v191)
    else
        buffer.writef32(v91, 0, v191)
        p117[57] = buffer.readu32(v91, 0)
    end

    if v193 ~= 0 and v193 > -1.1754943508222875E-38 and v193 < 1.1754943508222875E-38 then
        p117[58] = to_bits(v193)
    else
        buffer.writef32(v91, 0, v193)
        p117[58] = buffer.readu32(v91, 0)
    end

    if v197 ~= 0 and v197 > -1.1754943508222875E-38 and v197 < 1.1754943508222875E-38 then
        p117[59] = to_bits(v197)
    else
        buffer.writef32(v91, 0, v197)
        p117[59] = buffer.readu32(v91, 0)
    end

    if v253 ~= 0 and v253 > -1.1754943508222875E-38 and v253 < 1.1754943508222875E-38 then
        v242 = to_bits(v253)
    else
        buffer.writef32(v91, 0, v253)
        v242 = buffer.readu32(v91, 0)
    end

    p117[61] = v242

    if v248 ~= 0 and v248 > -1.1754943508222875E-38 and v248 < 1.1754943508222875E-38 then
        p117[62] = to_bits(v248)
    else
        buffer.writef32(v91, 0, v248)
        p117[62] = buffer.readu32(v91, 0)
    end

    if v249 ~= 0 and v249 > -1.1754943508222875E-38 and v249 < 1.1754943508222875E-38 then
        p117[63] = to_bits(v249)
    else
        buffer.writef32(v91, 0, v249)
        p117[63] = buffer.readu32(v91, 0)
    end

    p117[64] = v242

    if v254 ~= 0 and v254 > -1.1754943508222875E-38 and v254 < 1.1754943508222875E-38 then
        v242 = to_bits(v254)
    else
        buffer.writef32(v91, 0, v254)
        v242 = buffer.readu32(v91, 0)
    end

    p117[65] = v242

    if v250 ~= 0 and v250 > -1.1754943508222875E-38 and v250 < 1.1754943508222875E-38 then
        p117[66] = to_bits(v250)
    else
        buffer.writef32(v91, 0, v250)
        p117[66] = buffer.readu32(v91, 0)
    end

    if v251 ~= 0 and v251 > -1.1754943508222875E-38 and v251 < 1.1754943508222875E-38 then
        p117[67] = to_bits(v251)
    else
        buffer.writef32(v91, 0, v251)
        p117[67] = buffer.readu32(v91, 0)
    end

    p117[68] = v242

    if v255 ~= 0 and v255 > -1.1754943508222875E-38 and v255 < 1.1754943508222875E-38 then
        v242 = to_bits(v255)
    else
        buffer.writef32(v91, 0, v255)
        v242 = buffer.readu32(v91, 0)
    end

    p117[69] = v242

    if v256 ~= 0 and v256 > -1.1754943508222875E-38 and v256 < 1.1754943508222875E-38 then
        p117[70] = to_bits(v256)
    else
        buffer.writef32(v91, 0, v256)
        p117[70] = buffer.readu32(v91, 0)
    end

    if v257 ~= 0 and v257 > -1.1754943508222875E-38 and v257 < 1.1754943508222875E-38 then
        p117[71] = to_bits(v257)
    else
        buffer.writef32(v91, 0, v257)
        p117[71] = buffer.readu32(v91, 0)
    end

    p117[72] = v242

    if v265 ~= 0 and v265 > -1.1754943508222875E-38 and v265 < 1.1754943508222875E-38 then
        p117[73] = to_bits(v265)
    else
        buffer.writef32(v91, 0, v265)
        p117[73] = buffer.readu32(v91, 0)
    end

    if v266 ~= 0 and v266 > -1.1754943508222875E-38 and v266 < 1.1754943508222875E-38 then
        v242 = to_bits(v266)
    else
        buffer.writef32(v91, 0, v266)
        v242 = buffer.readu32(v91, 0)
    end

    p117[74] = v242
    p117[77] = v242

    if v267 ~= 0 and v267 > -1.1754943508222875E-38 and v267 < 1.1754943508222875E-38 then
        v242 = to_bits(v267)
    else
        buffer.writef32(v91, 0, v267)
        v242 = buffer.readu32(v91, 0)
    end

    p117[75] = v242
    p117[81] = v242

    if v264 ~= 0 and v264 > -1.1754943508222875E-38 and v264 < 1.1754943508222875E-38 then
        v242 = to_bits(v264)
    else
        buffer.writef32(v91, 0, v264)
        v242 = buffer.readu32(v91, 0)
    end

    p117[76] = v242
    p117[80] = v242
    p117[84] = v242

    if v269 ~= 0 and v269 > -1.1754943508222875E-38 and v269 < 1.1754943508222875E-38 then
        p117[78] = to_bits(v269)
    else
        buffer.writef32(v91, 0, v269)
        p117[78] = buffer.readu32(v91, 0)
    end

    if v270 ~= 0 and v270 > -1.1754943508222875E-38 and v270 < 1.1754943508222875E-38 then
        v242 = to_bits(v270)
    else
        buffer.writef32(v91, 0, v270)
        v242 = buffer.readu32(v91, 0)
    end

    p117[79] = v242
    p117[82] = v242

    if v268 ~= 0 and v268 > -1.1754943508222875E-38 and v268 < 1.1754943508222875E-38 then
        p117[83] = to_bits(v268)
    else
        buffer.writef32(v91, 0, v268)
        p117[83] = buffer.readu32(v91, 0)
    end

    if v271 ~= 0 and v271 > -1.1754943508222875E-38 and v271 < 1.1754943508222875E-38 then
        p117[85] = to_bits(v271)
    else
        buffer.writef32(v91, 0, v271)
        p117[85] = buffer.readu32(v91, 0)
    end

    if v272 ~= 0 and v272 > -1.1754943508222875E-38 and v272 < 1.1754943508222875E-38 then
        v242 = to_bits(v272)
    else
        buffer.writef32(v91, 0, v272)
        v242 = buffer.readu32(v91, 0)
    end

    p117[86] = v242
    p117[89] = v242

    if v273 ~= 0 and v273 > -1.1754943508222875E-38 and v273 < 1.1754943508222875E-38 then
        v242 = to_bits(v273)
    else
        buffer.writef32(v91, 0, v273)
        v242 = buffer.readu32(v91, 0)
    end

    p117[87] = v242
    p117[93] = v242

    if v277 ~= 0 and v277 > -1.1754943508222875E-38 and v277 < 1.1754943508222875E-38 then
        v242 = to_bits(v277)
    else
        buffer.writef32(v91, 0, v277)
        v242 = buffer.readu32(v91, 0)
    end

    p117[88] = v242
    p117[92] = v242
    p117[96] = v242

    if v275 ~= 0 and v275 > -1.1754943508222875E-38 and v275 < 1.1754943508222875E-38 then
        p117[90] = to_bits(v275)
    else
        buffer.writef32(v91, 0, v275)
        p117[90] = buffer.readu32(v91, 0)
    end

    if v276 ~= 0 and v276 > -1.1754943508222875E-38 and v276 < 1.1754943508222875E-38 then
        v242 = to_bits(v276)
    else
        buffer.writef32(v91, 0, v276)
        v242 = buffer.readu32(v91, 0)
    end

    p117[91] = v242
    p117[94] = v242

    if v274 ~= 0 and v274 > -1.1754943508222875E-38 and v274 < 1.1754943508222875E-38 then
        p117[95] = to_bits(v274)
    else
        buffer.writef32(v91, 0, v274)
        p117[95] = buffer.readu32(v91, 0)
    end
end

local v290 = table.create(96, 0)

local function build_core(p154, p155, p156, p157, p158, p159, p160, p161, p162, p163, p164, p165, p166, p167, p168, p169, p170, p171, p172, p173, p174, p175, p176, p177, p178, p179, p180, p181, p182, p183, p184, p185, p186, p187, p188, p189, p190, p191) -- line: 923
    -- upvalues: tu3 (copy), to_bits (copy), v91 (copy), is_finite (copy), compose (copy), basis (copy), angular_rows (copy), v290 (copy)
    if not (is_finite(p158) and p158 > 0) then
        error("assertion failed: input.time_step.is_finite() && input.time_step > 0.0", 0)
    end

    local v291 = if p155 == nil then v290 else p155
    local words = p156.words
    local words2 = p157.words
    local v292 = tu3.ACTIVE_BODY
    local v293 = bit32.band(p160, v292) ~= 0
    local v294 = tu3.ACTIVE_BODY
    local v295 = bit32.band(p176, v294) ~= 0
    local v296 = words2[17]

    buffer.writeu32(v91, 0, v296)

    local v297 = buffer.readf32(v91, 0)

    buffer.writeu32(v91, 0, words2[18])

    local v299 = buffer.readf32(v91, 0)

    buffer.writeu32(v91, 0, words2[19])

    local v301 = buffer.readf32(v91, 0)

    buffer.writeu32(v91, 0, words2[20])

    local v303, v304, v305

    v303, v292, v294, v304, v296, v297, v299, v301, v305 = basis(compose(p178, v297, v299, v301, (buffer.readf32(v91, 0))))
    buffer.writeu32(v91, 0, words2[5])

    local v306 = buffer.readf32(v91, 0)

    buffer.writeu32(v91, 0, words2[6])

    local v307 = buffer.readf32(v91, 0)

    buffer.writeu32(v91, 0, words2[7])

    local v308 = buffer.readf32(v91, 0)
    local columns = p164.columns
    local v309 = columns[1]
    local v310 = columns[2]
    local v311 = columns[3]
    local v312 = v311[1] * v308 + (v310[1] * v307 + v309[1] * v306)
    local v313 = v311[2] * v308 + (v310[2] * v307 + v309[2] * v306)
    local v314 = v311[3] * v308 + (v310[3] * v307 + v309[3] * v306)

    buffer.writeu32(v91, 0, words2[13])

    local v315 = buffer.readf32(v91, 0)

    buffer.writeu32(v91, 0, words2[14])

    local v316 = buffer.readf32(v91, 0)

    buffer.writeu32(v91, 0, words2[15])

    local v317 = buffer.readf32(v91, 0)

    v311 = p180.columns

    local v318 = v311[1]
    local v319 = v311[2]
    local v320 = v311[3]
    local v321 = v320[1] * v317 + (v319[1] * v316 + v318[1] * v315)
    local v322 = v320[2] * v317 + (v319[2] * v316 + v318[2] * v315)
    local v323 = v320[3] * v317 + (v319[3] * v316 + v318[3] * v315)
    local v324 = words2[1]

    buffer.writeu32(v91, 0, v324)

    local v325 = buffer.readf32(v91, 0)

    buffer.writeu32(v91, 0, words2[2])

    local v327 = buffer.readf32(v91, 0)

    buffer.writeu32(v91, 0, words2[3])

    local y = buffer.readf32(v91, 0)

    buffer.writeu32(v91, 0, words2[4])

    local v330, v331, v332

    v330, v331, v332, v324 = compose(p162, v325, v327, y, (buffer.readf32(v91, 0)))

    local z = words2[9]

    buffer.writeu32(v91, 0, z)

    local x = buffer.readf32(v91, 0)

    buffer.writeu32(v91, 0, words2[10])

    local y2 = buffer.readf32(v91, 0)

    buffer.writeu32(v91, 0, words2[11])

    local z2 = buffer.readf32(v91, 0)

    buffer.writeu32(v91, 0, words2[12])
    v325, v327, y, z = compose(p178, x, y2, z2, (buffer.readf32(v91, 0)))

    local x2, y3, z3, x3, y4, z4

    x, y2, z2, x2, y3, z3, x3, y4, z4 = basis(v330, v331, v332, v324)

    local v336, v337, v338, v339, v340, v341, v342, v343, v344 = basis(v325, v327, y, z)
    local v345 = words[15]
    local v346 = words[16]
    local v347 = words[13]

    buffer.writeu32(v91, 0, v347)

    local v348 = buffer.readf32(v91, 0)

    buffer.writeu32(v91, 0, words[14])

    local v350, v351, v352, v353, v354, v355, v356, v357, v358, v359, v360

    v350, v345, v346, v351, v347, v348, v352, v353, v354, v355, v356, v357, v358, v359, v360 = angular_rows(v345, v346, v348, buffer.readf32(v91, 0), x, y2, z2, x2, y3, z3, x3, y4, z4, v336, v337, v338, v339, v340, v341, v342, v343, v344, v330, v331, v332, v324, v325, v327, y, z)

    local v361, v362, v363, v364, v365, v366, v367

    if v293 then
        v361 = p169
        v362 = p170
        v363 = p171
        v364 = p172
        v365 = p173
        v366 = p174
        v367 = p175
    else
        v361 = 0
        v362 = 0
        v363 = 0
        v364 = 0
        v365 = 0
        v366 = 0
        v367 = 0
    end

    local v368, v369, v370, v371, v372, v373, v374

    if v295 then
        v374 = p185
        v370 = p186
        v369 = p187
        v368 = p188
        v373 = p189
        v372 = p190
        v371 = p191
    else
        v374 = 0
        v370 = 0
        v369 = 0
        v368 = 0
        v373 = 0
        v372 = 0
        v371 = 0
    end

    v295 = -v314 * v292 + v313 * v294
    v293 = -v312 * v294 + v314 * v303
    words2 = -v313 * v303 + v312 * v292
    v331 = -v323 * v292 + v322 * v294
    v332 = -v321 * v294 + v323 * v303
    v324 = -v322 * v303 + v321 * v292
    v325 = v364 * words2 + (v363 * v293 + (v362 * v295 + 0))
    v327 = v367 * words2 + (v366 * v293 + (v363 * v295 + 0))
    y = v365 * words2 + (v367 * v293 + (v364 * v295 + 0))
    z = v368 * v324 + (v369 * v332 + (v370 * v331 + 0))
    x = v371 * v324 + (v372 * v332 + (v369 * v331 + 0))
    y2 = v373 * v324 + (v371 * v332 + (v368 * v331 + 0))
    z2 = v331 * z + (v295 * v325 + 0)
    z = v332 * x + (v293 * v327 + 0)
    v330 = 1 / (v324 * y2 + (words2 * y + 0) + z + (z2 + (v361 + v374)))
    v332 = -v314 * v296 + v313 * v297
    v324 = -v312 * v297 + v314 * v304
    v325 = -v313 * v304 + v312 * v296
    v327 = -v323 * v296 + v322 * v297
    y = -v321 * v297 + v323 * v304
    z = -v322 * v304 + v321 * v296
    x = v364 * v325 + (v363 * v324 + (v362 * v332 + 0))
    y2 = v367 * v325 + (v366 * v324 + (v363 * v332 + 0))
    z2 = v365 * v325 + (v367 * v324 + (v364 * v332 + 0))
    x2 = v368 * z + (v369 * y + (v370 * v327 + 0))
    y3 = v371 * z + (v372 * y + (v369 * v327 + 0))
    z3 = v373 * z + (v371 * y + (v368 * v327 + 0))
    x3 = v327 * x2 + (v332 * x + 0)
    x2 = y * y3 + (v324 * y2 + 0)
    v331 = 1 / (z * z3 + (v325 * z2 + 0) + x2 + (x3 + (v361 + v374)))
    v324 = -v314 * v301 + v313 * v305
    v325 = -v312 * v305 + v314 * v299
    v327 = -v313 * v299 + v312 * v301
    y = -v323 * v301 + v322 * v305
    z = -v321 * v305 + v323 * v299
    x = -v322 * v299 + v321 * v301
    y2 = v364 * v327 + (v363 * v325 + (v362 * v324 + 0))
    z2 = v367 * v327 + (v366 * v325 + (v363 * v324 + 0))
    x2 = v365 * v327 + (v367 * v325 + (v364 * v324 + 0))
    y3 = v368 * x + (v369 * z + (v370 * y + 0))
    z3 = v371 * x + (v372 * z + (v369 * y + 0))
    x3 = v373 * x + (v371 * z + (v368 * y + 0))
    y4 = y * y3 + (v324 * y2 + 0)
    y3 = z * z3 + (v325 * z2 + 0)
    v332 = 1 / (x * x3 + (v327 * x2 + 0) + y3 + (y4 + (v361 + v374)))
    v325 = v364 * v346 + (v363 * v345 + (v362 * v350 + 0))
    v327 = v367 * v346 + (v366 * v345 + (v363 * v350 + 0))
    y = v365 * v346 + (v367 * v345 + (v364 * v350 + 0))
    z = v368 * v346 + (v369 * v345 + (v370 * v350 + 0))
    x = v371 * v346 + (v372 * v345 + (v369 * v350 + 0))
    y2 = v373 * v346 + (v371 * v345 + (v368 * v350 + 0))
    z2 = v350 * (v325 + z) + 0
    z = v345 * (v327 + x) + 0
    v324 = 0.5 * (1 / (v346 * (y + y2) + 0 + (z2 + z)))
    v327 = v364 * v348 + (v363 * v347 + (v362 * v351 + 0))
    y = v367 * v348 + (v366 * v347 + (v363 * v351 + 0))
    z = v365 * v348 + (v367 * v347 + (v364 * v351 + 0))
    x = v368 * v348 + (v369 * v347 + (v370 * v351 + 0))
    y2 = v371 * v348 + (v372 * v347 + (v369 * v351 + 0))
    z2 = v373 * v348 + (v371 * v347 + (v368 * v351 + 0))
    x2 = v351 * (v327 + x) + 0
    x = v347 * (y + y2) + 0
    v325 = 0.5 * (1 / (v348 * (z + z2) + 0 + (x2 + x)))
    y = v364 * v354 + (v363 * v353 + (v362 * v352 + 0))
    z = v367 * v354 + (v366 * v353 + (v363 * v352 + 0))
    x = v365 * v354 + (v367 * v353 + (v364 * v352 + 0))
    y2 = v368 * v354 + (v369 * v353 + (v370 * v352 + 0))
    z2 = v371 * v354 + (v372 * v353 + (v369 * v352 + 0))
    x2 = v373 * v354 + (v371 * v353 + (v368 * v352 + 0))
    y3 = v352 * (y + y2) + 0
    y2 = v353 * (z + z2) + 0
    v327 = 0.5 * (1 / (v354 * (x + x2) + 0 + (y3 + y2)))
    y = p166.y
    z = p166.z
    x = p166.x
    y2 = p182.y
    z2 = p182.z
    x2 = p182.x
    y3 = p168.y
    z3 = p168.z
    x3 = p168.x
    y4 = p184.y
    z4 = p184.z
    v336 = p184.x
    v343 = v314 * y + (-v313 * z + p165.x)
    v344 = v312 * z + (-v314 * x + p165.y)

    local v375 = v313 * x + (-v312 * y + p165.z)
    local v376 = v323 * y2 + (-v322 * z2 + p181.x)
    local v377 = v321 * z2 + (-v323 * x2 + p181.y)
    local v378 = v322 * x2 + (-v321 * y2 + p181.z)
    local v379 = v314 * y3 + (-v313 * z3 + p167.x)
    local v349 = v312 * z3 + (-v314 * x3 + p167.y)
    local v380 = v313 * x3 + (-v312 * y3 + p167.z)
    local v381 = v323 * y4 + (-v322 * z4 + p183.x)
    local v382 = v321 * z4 + (-v323 * v336 + p183.y)
    local v383 = v322 * v336 + (-v321 * y4 + p183.z)
    local v384 = (v379 * p158 + v343) * p158

    v379 = (v349 * p158 + v344) * p158
    v349 = (v380 * p158 + v375) * p158
    v380 = (v381 * p158 + v376) * p158
    v381 = (v382 * p158 + v377) * p158
    v382 = (v383 * p158 + v378) * p158
    v383 = v380 - v384
    v378 = v381 - v379
    v377 = v382 - v349
    v376 = p179.x + v321 + v380 - (p163.x + v312 + v384)
    v384 = p179.y + v322 + v381 - (p163.y + v313 + v379)
    v381 = p179.z + v323 + v382 - (p163.z + v314 + v349)
    v337 = v383 * v303 + v378 * v292 + v377 * v294
    v338 = v383 * v304 + v378 * v296 + v377 * v297
    v339 = v383 * v299 + v378 * v301 + v377 * v305
    v340 = v376 * v303 + v384 * v292 + v381 * v294
    v341 = v376 * v304 + v384 * v296 + v381 * v297
    v342 = v376 * v299 + v384 * v301 + v381 * v305
    buffer.writeu32(v91, 0, words[1])
    v377 = buffer.readf32(v91, 0)
    buffer.writeu32(v91, 0, words[5])
    v378 = buffer.readf32(v91, 0)

    local v385 = v340 - v377
    local v386 = v340 + v377

    v375 = v337 - v378 * p158
    v379 = v337 + v378 * p158

    if v375 ~= v375 or v386 == v386 and not (v375 < v386) then
        v375 = v386
    end

    if v385 == v385 and (v375 ~= v375 or v375 < v385) then
        v375 = v385
    end

    if v379 ~= v379 or v385 == v385 and not (v385 < v379) then
        v379 = v385
    end

    if v386 ~= v386 or v379 == v379 and not (v386 < v379) then
        v386 = v379
    end

    v343 = v375 * v330
    v344 = v386 * v330
    buffer.writeu32(v91, 0, words[2])
    v378 = buffer.readf32(v91, 0)
    buffer.writeu32(v91, 0, words[6])
    v386 = buffer.readf32(v91, 0)
    v377 = v341 - v378
    v378 = v341 + v378
    v340 = v338 - v386 * p158
    v379 = v338 + v386 * p158

    if v340 ~= v340 or v378 == v378 and not (v340 < v378) then
        v340 = v378
    end

    if v377 == v377 and (v340 ~= v340 or v340 < v377) then
        v340 = v377
    end

    if v379 ~= v379 or v377 == v377 and not (v377 < v379) then
        v379 = v377
    end

    if v378 ~= v378 or v379 == v379 and not (v378 < v379) then
        v378 = v379
    end

    v375 = v340 * v331
    v376 = v378 * v331
    buffer.writeu32(v91, 0, words[3])
    v349 = buffer.readf32(v91, 0)
    buffer.writeu32(v91, 0, words[7])

    local v387 = buffer.readf32(v91, 0)

    v379 = v342 - v349
    v349 = v342 + v349
    v341 = v339 - v387 * p158
    v380 = v339 + v387 * p158

    if v341 ~= v341 or v349 == v349 and not (v341 < v349) then
        v341 = v349
    end

    if v379 == v379 and (v341 ~= v341 or v341 < v379) then
        v341 = v379
    end

    if v380 ~= v380 or v379 == v379 and not (v379 < v380) then
        v380 = v379
    end

    if v349 ~= v349 or v380 == v380 and not (v349 < v380) then
        v349 = v380
    end

    v377 = v341 * v332
    v378 = v349 * v332
    v342 = (v336 * p158 + (x2 - x) - x3 * p158) * p158
    v339 = (y4 * p158 + (y2 - y) - y3 * p158) * p158
    v384 = (z4 * p158 + (z2 - z) - z3 * p158) * p158
    buffer.writeu32(v91, 0, words[9])

    local v389 = buffer.readf32(v91, 0)

    buffer.writeu32(v91, 0, words[10])

    local v391 = buffer.readf32(v91, 0)
    local v390 = v342 * v350 + v339 * v345 + v384 * v346
    local v392 = v355 + v390
    local v393 = v358 + v390
    local v394 = v390 - v389 * p158
    local v395 = v389 * p158 + v390

    if v394 ~= v394 or v393 == v393 and not (v394 < v393) then
        v394 = v393
    end

    if v392 == v392 and (v394 ~= v394 or v394 < v392) then
        v394 = v392
    end

    if v395 ~= v395 or v392 == v392 and not (v392 < v395) then
        v395 = v392
    end

    if v393 ~= v393 or v395 == v395 and not (v393 < v395) then
        v393 = v395
    end

    v379 = v394 * v324
    v349 = v393 * v324

    local v396 = v342 * v351 + v339 * v347 + v384 * v348

    v389 = v356 + v396
    v392 = v359 + v396
    v393 = v396 - v391 * p158
    v394 = v391 * p158 + v396

    if v393 ~= v393 or v392 == v392 and not (v393 < v392) then
        v393 = v392
    end

    if v389 == v389 and (v393 ~= v393 or v393 < v389) then
        v393 = v389
    end

    if v394 ~= v394 or v389 == v389 and not (v389 < v394) then
        v394 = v389
    end

    if v392 ~= v392 or v394 == v394 and not (v392 < v394) then
        v392 = v394
    end

    v380 = v393 * v325
    v381 = v392 * v325
    v359 = v342 * v352 + v339 * v353 + v384 * v354
    v392 = v357 + v359
    v393 = v360 + v359
    v394 = v359 - v391 * p158
    v395 = v391 * p158 + v359

    if v394 ~= v394 or v393 == v393 and not (v394 < v393) then
        v394 = v393
    end

    if v392 == v392 and (v394 ~= v394 or v394 < v392) then
        v394 = v392
    end

    if v395 ~= v395 or v392 == v392 and not (v392 < v395) then
        v395 = v392
    end

    if v393 ~= v393 or v395 == v395 and not (v393 < v395) then
        v393 = v395
    end

    v382 = v394 * v327
    v355 = v393 * v327

    if v312 < 1.1754943508222875E-38 and v312 > -1.1754943508222875E-38 and v312 ~= 0 then
        v359 = to_bits(v312)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v312)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[1] = v359
    v291[1] = v389

    if v313 < 1.1754943508222875E-38 and v313 > -1.1754943508222875E-38 and v313 ~= 0 then
        v359 = to_bits(v313)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v313)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[2] = v359
    v291[2] = v389

    if v314 < 1.1754943508222875E-38 and v314 > -1.1754943508222875E-38 and v314 ~= 0 then
        v359 = to_bits(v314)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v314)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[3] = v359
    v291[3] = v389
    buffer.writeu32(v91, 0, p161)
    v359 = buffer.readf32(v91, 0)

    if v359 < 1.1754943508222875E-38 and v359 > -1.1754943508222875E-38 and v359 ~= 0 then
        v359 = to_bits(v359)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v359)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[4] = v359
    v291[4] = v389

    if v321 < 1.1754943508222875E-38 and v321 > -1.1754943508222875E-38 and v321 ~= 0 then
        v359 = to_bits(v321)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v321)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[5] = v359
    v291[5] = v389

    if v322 < 1.1754943508222875E-38 and v322 > -1.1754943508222875E-38 and v322 ~= 0 then
        v359 = to_bits(v322)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v322)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[6] = v359
    v291[6] = v389

    if v323 < 1.1754943508222875E-38 and v323 > -1.1754943508222875E-38 and v323 ~= 0 then
        v359 = to_bits(v323)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v323)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[7] = v359
    v291[7] = v389
    buffer.writeu32(v91, 0, p177)
    v359 = buffer.readf32(v91, 0)

    if v359 < 1.1754943508222875E-38 and v359 > -1.1754943508222875E-38 and v359 ~= 0 then
        v359 = to_bits(v359)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v359)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[8] = v359
    v291[8] = v389
    p154[9] = 0
    p154[10] = 0
    p154[11] = 0
    p154[12] = 0
    p154[13] = 0
    p154[14] = 0
    p154[15] = 0
    p154[16] = 0
    v291[9] = 0
    v291[10] = 0
    v291[11] = 0
    v291[12] = 0
    v291[13] = 0
    v291[14] = 0
    v291[15] = 0
    v291[16] = 0
    v356 = v303 * v330

    if v356 < 1.1754943508222875E-38 and v356 > -1.1754943508222875E-38 and v356 ~= 0 then
        v359 = to_bits(v356)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v356)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[17] = v359
    v291[17] = v389
    v356 = v304 * v331

    if v356 < 1.1754943508222875E-38 and v356 > -1.1754943508222875E-38 and v356 ~= 0 then
        v359 = to_bits(v356)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v356)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[18] = v359
    v291[18] = v389
    v356 = v299 * v332

    if v356 < 1.1754943508222875E-38 and v356 > -1.1754943508222875E-38 and v356 ~= 0 then
        v359 = to_bits(v356)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v356)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[19] = v359
    v291[19] = v389
    p154[20] = 0
    v291[20] = 0
    v356 = v350 * v324

    if v356 < 1.1754943508222875E-38 and v356 > -1.1754943508222875E-38 and v356 ~= 0 then
        v359 = to_bits(v356)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v356)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[21] = v359
    v291[21] = v389
    v356 = v351 * v325

    if v356 < 1.1754943508222875E-38 and v356 > -1.1754943508222875E-38 and v356 ~= 0 then
        v359 = to_bits(v356)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v356)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[22] = v359
    v291[22] = v389
    v356 = v352 * v327

    if v356 < 1.1754943508222875E-38 and v356 > -1.1754943508222875E-38 and v356 ~= 0 then
        v359 = to_bits(v356)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v356)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[23] = v359
    v291[23] = v389
    p154[24] = 0
    v291[24] = 0
    v356 = v292 * v330

    if v356 < 1.1754943508222875E-38 and v356 > -1.1754943508222875E-38 and v356 ~= 0 then
        v359 = to_bits(v356)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v356)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[25] = v359
    v291[25] = v389
    v356 = v296 * v331

    if v356 < 1.1754943508222875E-38 and v356 > -1.1754943508222875E-38 and v356 ~= 0 then
        v359 = to_bits(v356)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v356)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[26] = v359
    v291[26] = v389
    v356 = v301 * v332

    if v356 < 1.1754943508222875E-38 and v356 > -1.1754943508222875E-38 and v356 ~= 0 then
        v359 = to_bits(v356)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v356)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[27] = v359
    v291[27] = v389

    if v379 < 1.1754943508222875E-38 and v379 > -1.1754943508222875E-38 and v379 ~= 0 then
        v359 = to_bits(v379)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v379)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[28] = v359
    v291[28] = v389
    v356 = v345 * v324

    if v356 < 1.1754943508222875E-38 and v356 > -1.1754943508222875E-38 and v356 ~= 0 then
        v359 = to_bits(v356)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v356)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[29] = v359
    v291[29] = v389
    v356 = v347 * v325

    if v356 < 1.1754943508222875E-38 and v356 > -1.1754943508222875E-38 and v356 ~= 0 then
        v359 = to_bits(v356)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v356)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[30] = v359
    v291[30] = v389
    v356 = v353 * v327

    if v356 < 1.1754943508222875E-38 and v356 > -1.1754943508222875E-38 and v356 ~= 0 then
        v359 = to_bits(v356)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v356)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[31] = v359
    v291[31] = v389

    if v380 < 1.1754943508222875E-38 and v380 > -1.1754943508222875E-38 and v380 ~= 0 then
        v359 = to_bits(v380)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v380)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[32] = v359
    v291[32] = v389
    v356 = v294 * v330

    if v356 < 1.1754943508222875E-38 and v356 > -1.1754943508222875E-38 and v356 ~= 0 then
        v359 = to_bits(v356)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v356)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[33] = v359
    v291[33] = v389
    v356 = v297 * v331

    if v356 < 1.1754943508222875E-38 and v356 > -1.1754943508222875E-38 and v356 ~= 0 then
        v359 = to_bits(v356)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v356)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[34] = v359
    v291[34] = v389
    v356 = v305 * v332

    if v356 < 1.1754943508222875E-38 and v356 > -1.1754943508222875E-38 and v356 ~= 0 then
        v359 = to_bits(v356)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v356)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[35] = v359
    v291[35] = v389

    if v349 < 1.1754943508222875E-38 and v349 > -1.1754943508222875E-38 and v349 ~= 0 then
        v359 = to_bits(v349)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v349)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[36] = v359
    v291[36] = v389
    v356 = v346 * v324

    if v356 < 1.1754943508222875E-38 and v356 > -1.1754943508222875E-38 and v356 ~= 0 then
        v359 = to_bits(v356)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v356)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[37] = v359
    v291[37] = v389
    v356 = v348 * v325

    if v356 < 1.1754943508222875E-38 and v356 > -1.1754943508222875E-38 and v356 ~= 0 then
        v359 = to_bits(v356)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v356)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[38] = v359
    v291[38] = v389
    v356 = v354 * v327

    if v356 < 1.1754943508222875E-38 and v356 > -1.1754943508222875E-38 and v356 ~= 0 then
        v359 = to_bits(v356)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v356)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[39] = v359
    v291[39] = v389

    if v381 < 1.1754943508222875E-38 and v381 > -1.1754943508222875E-38 and v381 ~= 0 then
        v359 = to_bits(v381)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v381)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[40] = v359
    v291[40] = v389

    if v343 < 1.1754943508222875E-38 and v343 > -1.1754943508222875E-38 and v343 ~= 0 then
        v359 = to_bits(v343)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v343)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[41] = v359
    v291[41] = v389

    if v375 < 1.1754943508222875E-38 and v375 > -1.1754943508222875E-38 and v375 ~= 0 then
        v359 = to_bits(v375)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v375)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[42] = v359
    v291[42] = v389

    if v377 < 1.1754943508222875E-38 and v377 > -1.1754943508222875E-38 and v377 ~= 0 then
        v359 = to_bits(v377)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v377)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[43] = v359
    v291[43] = v389

    if v382 < 1.1754943508222875E-38 and v382 > -1.1754943508222875E-38 and v382 ~= 0 then
        v359 = to_bits(v382)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v382)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[44] = v359
    v291[44] = v389

    if v344 < 1.1754943508222875E-38 and v344 > -1.1754943508222875E-38 and v344 ~= 0 then
        v359 = to_bits(v344)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v344)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[45] = v359
    v291[45] = v389

    if v376 < 1.1754943508222875E-38 and v376 > -1.1754943508222875E-38 and v376 ~= 0 then
        v359 = to_bits(v376)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v376)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[46] = v359
    v291[46] = v389

    if v378 < 1.1754943508222875E-38 and v378 > -1.1754943508222875E-38 and v378 ~= 0 then
        v359 = to_bits(v378)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v378)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[47] = v359
    v291[47] = v389

    if v355 < 1.1754943508222875E-38 and v355 > -1.1754943508222875E-38 and v355 ~= 0 then
        v359 = to_bits(v355)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v355)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[48] = v359
    v291[48] = v389

    if v303 < 1.1754943508222875E-38 and v303 > -1.1754943508222875E-38 and v303 ~= 0 then
        v359 = to_bits(v303)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v303)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[49] = v359
    v291[49] = v389

    if v292 < 1.1754943508222875E-38 and v292 > -1.1754943508222875E-38 and v292 ~= 0 then
        v359 = to_bits(v292)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v292)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[50] = v359
    p154[60] = v359
    v291[50] = v389
    v291[60] = v389

    if v294 < 1.1754943508222875E-38 and v294 > -1.1754943508222875E-38 and v294 ~= 0 then
        v359 = to_bits(v294)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v294)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[51] = v359
    v291[51] = v389
    buffer.writeu32(v91, 0, p159)
    v359 = buffer.readf32(v91, 0)

    if v359 < 1.1754943508222875E-38 and v359 > -1.1754943508222875E-38 and v359 ~= 0 then
        v359 = to_bits(v359)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v359)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[52] = v359
    v291[52] = v389

    if v304 < 1.1754943508222875E-38 and v304 > -1.1754943508222875E-38 and v304 ~= 0 then
        v359 = to_bits(v304)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v304)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[53] = v359
    p154[56] = v359
    v291[53] = v389
    v291[56] = v389

    if v296 < 1.1754943508222875E-38 and v296 > -1.1754943508222875E-38 and v296 ~= 0 then
        v359 = to_bits(v296)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v296)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[54] = v359
    v291[54] = v389

    if v297 < 1.1754943508222875E-38 and v297 > -1.1754943508222875E-38 and v297 ~= 0 then
        v359 = to_bits(v297)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v297)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[55] = v359
    v291[55] = v389

    if v299 < 1.1754943508222875E-38 and v299 > -1.1754943508222875E-38 and v299 ~= 0 then
        v359 = to_bits(v299)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v299)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[57] = v359
    v291[57] = v389

    if v301 < 1.1754943508222875E-38 and v301 > -1.1754943508222875E-38 and v301 ~= 0 then
        v359 = to_bits(v301)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v301)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[58] = v359
    v291[58] = v389

    if v305 < 1.1754943508222875E-38 and v305 > -1.1754943508222875E-38 and v305 ~= 0 then
        v359 = to_bits(v305)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v305)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[59] = v359
    v291[59] = v389

    if v350 < 1.1754943508222875E-38 and v350 > -1.1754943508222875E-38 and v350 ~= 0 then
        v359 = to_bits(v350)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v350)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[61] = v359
    p154[64] = v359
    v291[61] = v389
    v291[64] = v389

    if v345 < 1.1754943508222875E-38 and v345 > -1.1754943508222875E-38 and v345 ~= 0 then
        v359 = to_bits(v345)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v345)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[62] = v359
    v291[62] = v389

    if v346 < 1.1754943508222875E-38 and v346 > -1.1754943508222875E-38 and v346 ~= 0 then
        v359 = to_bits(v346)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v346)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[63] = v359
    v291[63] = v389

    if v351 < 1.1754943508222875E-38 and v351 > -1.1754943508222875E-38 and v351 ~= 0 then
        v359 = to_bits(v351)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v351)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[65] = v359
    p154[68] = v359
    v291[65] = v389
    v291[68] = v389

    if v347 < 1.1754943508222875E-38 and v347 > -1.1754943508222875E-38 and v347 ~= 0 then
        v359 = to_bits(v347)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v347)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[66] = v359
    v291[66] = v389

    if v348 < 1.1754943508222875E-38 and v348 > -1.1754943508222875E-38 and v348 ~= 0 then
        v359 = to_bits(v348)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v348)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[67] = v359
    v291[67] = v389

    if v352 < 1.1754943508222875E-38 and v352 > -1.1754943508222875E-38 and v352 ~= 0 then
        v359 = to_bits(v352)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v352)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[69] = v359
    p154[72] = v359
    v291[69] = v389
    v291[72] = v389

    if v353 < 1.1754943508222875E-38 and v353 > -1.1754943508222875E-38 and v353 ~= 0 then
        v359 = to_bits(v353)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v353)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[70] = v359
    v291[70] = v389

    if v354 < 1.1754943508222875E-38 and v354 > -1.1754943508222875E-38 and v354 ~= 0 then
        v359 = to_bits(v354)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v354)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[71] = v359
    v291[71] = v389

    if v362 < 1.1754943508222875E-38 and v362 > -1.1754943508222875E-38 and v362 ~= 0 then
        v359 = to_bits(v362)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v362)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[73] = v359
    v291[73] = v389

    if v363 < 1.1754943508222875E-38 and v363 > -1.1754943508222875E-38 and v363 ~= 0 then
        v359 = to_bits(v363)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v363)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[74] = v359
    p154[77] = v359
    v291[74] = v389
    v291[77] = v389

    if v364 < 1.1754943508222875E-38 and v364 > -1.1754943508222875E-38 and v364 ~= 0 then
        v359 = to_bits(v364)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v364)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[75] = v359
    p154[81] = v359
    v291[75] = v389
    v291[81] = v389

    if v361 < 1.1754943508222875E-38 and v361 > -1.1754943508222875E-38 and v361 ~= 0 then
        v359 = to_bits(v361)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v361)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[76] = v359
    p154[80] = v359
    p154[84] = v359
    v291[76] = v389
    v291[80] = v389
    v291[84] = v389

    if v366 < 1.1754943508222875E-38 and v366 > -1.1754943508222875E-38 and v366 ~= 0 then
        v359 = to_bits(v366)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v366)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[78] = v359
    v291[78] = v389

    if v367 < 1.1754943508222875E-38 and v367 > -1.1754943508222875E-38 and v367 ~= 0 then
        v359 = to_bits(v367)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v367)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[79] = v359
    p154[82] = v359
    v291[79] = v389
    v291[82] = v389

    if v365 < 1.1754943508222875E-38 and v365 > -1.1754943508222875E-38 and v365 ~= 0 then
        v359 = to_bits(v365)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v365)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[83] = v359
    v291[83] = v389

    if v370 < 1.1754943508222875E-38 and v370 > -1.1754943508222875E-38 and v370 ~= 0 then
        v359 = to_bits(v370)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v370)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[85] = v359
    v291[85] = v389

    if v369 < 1.1754943508222875E-38 and v369 > -1.1754943508222875E-38 and v369 ~= 0 then
        v359 = to_bits(v369)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v369)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[86] = v359
    p154[89] = v359
    v291[86] = v389
    v291[89] = v389

    if v368 < 1.1754943508222875E-38 and v368 > -1.1754943508222875E-38 and v368 ~= 0 then
        v359 = to_bits(v368)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v368)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[87] = v359
    p154[93] = v359
    v291[87] = v389
    v291[93] = v389

    if v374 < 1.1754943508222875E-38 and v374 > -1.1754943508222875E-38 and v374 ~= 0 then
        v359 = to_bits(v374)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v374)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[88] = v359
    p154[92] = v359
    p154[96] = v359
    v291[88] = v389
    v291[92] = v389
    v291[96] = v389

    if v372 < 1.1754943508222875E-38 and v372 > -1.1754943508222875E-38 and v372 ~= 0 then
        v359 = to_bits(v372)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v372)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[90] = v359
    v291[90] = v389

    if v371 < 1.1754943508222875E-38 and v371 > -1.1754943508222875E-38 and v371 ~= 0 then
        v359 = to_bits(v371)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v371)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[91] = v359
    p154[94] = v359
    v291[91] = v389
    v291[94] = v389

    if v373 < 1.1754943508222875E-38 and v373 > -1.1754943508222875E-38 and v373 ~= 0 then
        v359 = to_bits(v373)
        buffer.writeu32(v91, 0, v359)
    else
        buffer.writef32(v91, 0, v373)
        v359 = buffer.readu32(v91, 0)
    end

    v389 = buffer.readf32(v91, 0)
    p154[95] = v359
    v291[95] = v389
end

local v397 = true

function t1.set_b3(p192) -- line: 2017
    -- upvalues: v397 (ref)
    local v398 = v397

    v397 = p192

    return v398
end

function t1.build_retail_joint_jacobian(p193) -- line: 2029
    -- upvalues: tu3 (copy), is_finite (copy), build_core_r3 (copy), build_core (copy), v397 (ref)
    local time_step = p193.time_step

    if not (is_finite(time_step) and time_step > 0) then
        error("assertion failed: input.time_step.is_finite() && input.time_step > 0.0", 0)
    end

    local body_a, body_b = p193.body_a, p193.body_b
    local state = body_a.state
    local state2 = body_b.state
    local ACTIVE_BODY = tu3.ACTIVE_BODY
    local v399, v400, v401, v402, v403, v404

    if bit32.band(state, ACTIVE_BODY) == 0 then
        v399 = 0
        v400 = 0
        v401 = 0
        v402 = 0
        v403 = 0
        v404 = 0
    else
        local world_inverse_inertia = body_a.world_inverse_inertia
        local full, split = world_inverse_inertia.full, world_inverse_inertia.split

        v399 = full.x
        v400 = full.y
        v401 = full.z
        v402 = split.x
        v403 = split.y
        v404 = split.z
    end

    local ACTIVE_BODY2 = tu3.ACTIVE_BODY
    local v405, v406, v407, v408, v409, v410

    if bit32.band(state2, ACTIVE_BODY2) == 0 then
        v405 = 0
        v406 = 0
        v407 = 0
        v408 = 0
        v409 = 0
        v410 = 0
    else
        local world_inverse_inertia = body_b.world_inverse_inertia
        local full, split = world_inverse_inertia.full, world_inverse_inertia.split

        v405 = full.x
        v406 = full.y
        v407 = full.z
        v408 = split.x
        v409 = split.y
        v410 = split.z
    end

    local v411 = table.create(tu3.JACOBIAN_WORDS, 0)

    if v397 then
        build_core(v411, nil, p193.parameters, p193.frames, time_step, p193.joint_guest_address, state, body_a.reaction_guest_address, body_a.orientation, body_a.center_of_mass, body_a.basis, body_a.linear_velocity, body_a.angular_velocity, body_a.force_acceleration, body_a.torque_acceleration, body_a.inverse_mass, v399, v400, v401, v402, v403, v404, state2, body_b.reaction_guest_address, body_b.orientation, body_b.center_of_mass, body_b.basis, body_b.linear_velocity, body_b.angular_velocity, body_b.force_acceleration, body_b.torque_acceleration, body_b.inverse_mass, v405, v406, v407, v408, v409, v410)
    else
        build_core_r3(v411, p193.parameters, p193.frames, time_step, p193.joint_guest_address, state, body_a.reaction_guest_address, body_a.orientation, body_a.center_of_mass, body_a.basis, body_a.linear_velocity, body_a.angular_velocity, body_a.force_acceleration, body_a.torque_acceleration, body_a.inverse_mass, v399, v400, v401, v402, v403, v404, state2, body_b.reaction_guest_address, body_b.orientation, body_b.center_of_mass, body_b.basis, body_b.linear_velocity, body_b.angular_velocity, body_b.force_acceleration, body_b.torque_acceleration, body_b.inverse_mass, v405, v406, v407, v408, v409, v410)
    end

    return {
        words = v411
    }
end

local function bodies_reference(p194, p195, p196, p197, p198) -- line: 2087
    -- upvalues: t1 (copy)
    local rates = p196.rates
    local rates2 = p197.rates
    local columns = rates.world_inverse_inertia.columns
    local columns2 = rates2.world_inverse_inertia.columns
    local v412 = columns[1]
    local v413 = columns[2]
    local v414 = columns[3]
    local v415 = columns2[1]
    local v416 = columns2[2]
    local v417 = columns2[3]

    return t1.build_retail_joint_jacobian_reference({
        joint_guest_address = 0,
        parameters = p194,
        frames = p195,
        body_a = {
            reaction_guest_address = 0,
            state = p196.state_flags,
            orientation = rates.orientation,
            center_of_mass = rates.position,
            basis = rates.basis,
            linear_velocity = rates.linear_velocity,
            angular_velocity = rates.angular_velocity,
            force_acceleration = rates.force_acceleration,
            torque_acceleration = rates.torque_acceleration,
            inverse_mass = p196.inertia.inverse_mass,
            world_inverse_inertia = {
                full = {
                    x = v412[1],
                    y = v413[1],
                    z = v414[1]
                },
                split = {
                    x = v414[3],
                    y = v413[2],
                    z = v414[2]
                }
            }
        },
        body_b = {
            reaction_guest_address = 0,
            state = p197.state_flags,
            orientation = rates2.orientation,
            center_of_mass = rates2.position,
            basis = rates2.basis,
            linear_velocity = rates2.linear_velocity,
            angular_velocity = rates2.angular_velocity,
            force_acceleration = rates2.force_acceleration,
            torque_acceleration = rates2.torque_acceleration,
            inverse_mass = p197.inertia.inverse_mass,
            world_inverse_inertia = {
                full = {
                    x = v415[1],
                    y = v416[1],
                    z = v417[1]
                },
                split = {
                    x = v417[3],
                    y = v416[2],
                    z = v417[2]
                }
            }
        },
        time_step = p198
    })
end

function t1.build_retail_joint_jacobian_bodies_into(p199, p200, p201, p202, p203, p204, p205) -- line: 2143
    -- upvalues: build_core_r3 (copy), build_core (copy), v397 (ref)
    local rates = p202.rates
    local rates2 = p203.rates
    local columns = rates.world_inverse_inertia.columns
    local columns2 = rates2.world_inverse_inertia.columns
    local v418 = columns[1]
    local v419 = columns[2]
    local v420 = columns[3]
    local v421 = columns2[1]
    local v422 = columns2[2]
    local v423 = columns2[3]

    if v397 then
        build_core(p199, p205, p200, p201, p204, 0, p202.state_flags, 0, rates.orientation, rates.position, rates.basis, rates.linear_velocity, rates.angular_velocity, rates.force_acceleration, rates.torque_acceleration, p202.inertia.inverse_mass, v418[1], v419[1], v420[1], v420[3], v419[2], v420[2], p203.state_flags, 0, rates2.orientation, rates2.position, rates2.basis, rates2.linear_velocity, rates2.angular_velocity, rates2.force_acceleration, rates2.torque_acceleration, p203.inertia.inverse_mass, v421[1], v422[1], v423[1], v423[3], v422[2], v423[2])

        return p199, p205 ~= nil
    end

    build_core_r3(p199, p200, p201, p204, 0, p202.state_flags, 0, rates.orientation, rates.position, rates.basis, rates.linear_velocity, rates.angular_velocity, rates.force_acceleration, rates.torque_acceleration, p202.inertia.inverse_mass, v418[1], v419[1], v420[1], v420[3], v419[2], v420[2], p203.state_flags, 0, rates2.orientation, rates2.position, rates2.basis, rates2.linear_velocity, rates2.angular_velocity, rates2.force_acceleration, rates2.torque_acceleration, p203.inertia.inverse_mass, v421[1], v422[1], v423[1], v423[3], v422[2], v423[2])

    return p199, false
end

function t1.build_retail_joint_jacobian_bodies(p206, p207, p208, p209, p210) -- line: 2186
    -- upvalues: t1 (copy), tu3 (copy)
    return {
        words = t1.build_retail_joint_jacobian_bodies_into(table.create(tu3.JACOBIAN_WORDS, 0), p206, p207, p208, p209, p210)
    }
end

return t1
