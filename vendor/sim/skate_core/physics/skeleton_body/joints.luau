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

local import = require(sim.import)
local v8 = import("skate_core/trigonometry")
local compile_active = import("skate_core/physics/constraint_batch").compile_active
local retail_quaternion_from_basis = import("skate_core/physics/drive_frames").retail_quaternion_from_basis
local v9 = import("skate_core/physics/joint_builder")
local build_retail_joint_jacobian = v9.build_retail_joint_jacobian
local v10 = import("skate_core/physics/native_arithmetic")
local pack_world_inverse_inertia = import("skate_core/physics/rigid_body").pack_world_inverse_inertia
local v11 = import("skate_core/physics/skeleton_animation_record")
local compose_affine, physics_bone_frame = v11.compose_affine, v11.physics_bone_frame
local inverse_rigid = import("skate_core/physics/skeleton_root").inverse_rigid

local function skeleton_body() -- line: 44
    -- upvalues: import (copy)
    return import("skate_core/physics/skeleton_body")
end

local _ = v9.build_retail_joint_jacobian_bodies
local t1 = {
    JointBone = {},
    JointSettings = {},
    SkeletonJointSettings = {},
    SkeletonJoint = {},
    SkeletonJoints = {}
}

function t1.SkeletonJoints.new(p3, p4, p5, p6, p7) -- line: 78
    -- upvalues: rt (copy), v1 (copy), import (copy), v8 (copy), compose_affine (copy), physics_bone_frame (copy), inverse_rigid (copy), t1 (copy)
    local v12 = import("skate_core/physics/skeleton_body")
    local ANIMATION_PART_COUNT, JOINT_COUNT = v12.ANIMATION_PART_COUNT, v12.JOINT_COUNT
    local v13 = table.create(JOINT_COUNT)

    for i = 0, ANIMATION_PART_COUNT - 1 do
        local v14 = p4[i + 1]

        if v14 ~= nil then
            if ANIMATION_PART_COUNT <= v14 or v14 == i then
                error("Invalid physical skeleton joint parent", 0)
            end

            local v15 = p6[#v13 + 1]

            if v15 == nil then
                error("Too many physical skeleton joints", 0)
            end

            local v16 = rt.copy(v15)
            local v17 = rt.copy(p5[i + 1])
            local v18 = inverse_rigid(v17.volume_frame)
            local v19 = inverse_rigid(p5[v14 + 1].volume_frame)
            local v20 = physics_bone_frame(v17.parent_orientation, table.create(4, 0))
            local v21 = physics_bone_frame(v17.joint_orientation, table.create(4, 0))
            local v22 = compose_affine(v19, inverse_rigid(v20))
            local v24 = compose_affine(v19, (compose_affine(inverse_rigid(p3[v14 + 1]), p3[i + 1])))[4]
            local v25 = compose_affine(v18, v21)
            local v26 = compose_affine(v22, v21)
            local t2 = {
                words = table.create(20, 0)
            }
            local v27 = rt.slice(t2.words, 0, 8)

            t1.pack_frame(v27, v25, v18[4])
            t2.words[1] = v27[1]
            t2.words[2] = v27[2]
            t2.words[3] = v27[3]
            t2.words[4] = v27[4]
            t2.words[5] = v27[5]
            t2.words[6] = v27[6]
            t2.words[7] = v27[7]
            t2.words[8] = v27[8]

            local v28 = rt.slice(t2.words, 8, 16)

            t1.pack_frame(v28, v26, v24)
            t2.words[9] = v28[1]
            t2.words[10] = v28[2]
            t2.words[11] = v28[3]
            t2.words[12] = v28[4]
            t2.words[13] = v28[5]
            t2.words[14] = v28[6]
            t2.words[15] = v28[7]
            t2.words[16] = v28[8]

            local words = t2.words

            buffer.writef32(v1, 0, 1)
            words[20] = buffer.readu32(v1, 0)

            local t3 = {
                words = table.create(16, 0)
            }
            local v29 = t1.inverse_native_step()
            local words2 = t3.words
            local v30 = p7.displacement_limit[1] * v29

            if v30 ~= 0 and v30 > -1.1754943508222875E-38 and v30 < 1.1754943508222875E-38 then
                local v31 = math.abs(v30) * 7.1362384635298E+44
                local v32 = math.floor(v31)
                local v33 = v31 - v32
                local v34 = if v33 > 0.5 or v33 == 0.5 and v32 % 2 == 1 then v32 + 1 else v32

                if v30 < 0 then
                    words2[5] = v34 + 2147483648
                else
                    words2[5] = v34
                end
            else
                buffer.writef32(v1, 0, v30)
                words2[5] = buffer.readu32(v1, 0)
            end

            local words3 = t3.words
            local v35 = p7.displacement_limit[2] * v29

            if v35 ~= 0 and v35 > -1.1754943508222875E-38 and v35 < 1.1754943508222875E-38 then
                local v36 = math.abs(v35) * 7.1362384635298E+44
                local v37 = math.floor(v36)
                local v38 = v36 - v37
                local v39 = if v38 > 0.5 or v38 == 0.5 and v37 % 2 == 1 then v37 + 1 else v37

                if v35 < 0 then
                    words3[6] = v39 + 2147483648
                else
                    words3[6] = v39
                end
            else
                buffer.writef32(v1, 0, v35)
                words3[6] = buffer.readu32(v1, 0)
            end

            local words4 = t3.words
            local v40 = p7.displacement_limit[3] * v29

            if v40 ~= 0 and v40 > -1.1754943508222875E-38 and v40 < 1.1754943508222875E-38 then
                local v41 = math.abs(v40) * 7.1362384635298E+44
                local v42 = math.floor(v41)
                local v43 = v41 - v42
                local v44 = if v43 > 0.5 or v43 == 0.5 and v42 % 2 == 1 then v42 + 1 else v42

                if v40 < 0 then
                    words4[7] = v44 + 2147483648
                else
                    words4[7] = v44
                end
            else
                buffer.writef32(v1, 0, v40)
                words4[7] = buffer.readu32(v1, 0)
            end

            local words5 = t3.words
            local v45 = p7.displacement_limit[4] * v29

            if v45 ~= 0 and v45 > -1.1754943508222875E-38 and v45 < 1.1754943508222875E-38 then
                local v46 = math.abs(v45) * 7.1362384635298E+44
                local v47 = math.floor(v46)
                local v48 = v46 - v47
                local v49 = if v48 > 0.5 or v48 == 0.5 and v47 % 2 == 1 then v47 + 1 else v47

                if v45 < 0 then
                    words5[8] = v49 + 2147483648
                else
                    words5[8] = v49
                end
            else
                buffer.writef32(v1, 0, v45)
                words5[8] = buffer.readu32(v1, 0)
            end

            local words6 = t3.words
            local v50 = p7.twist_displacement_limit * 59.999996185302734

            if v50 ~= 0 and v50 > -1.1754943508222875E-38 and v50 < 1.1754943508222875E-38 then
                local v51 = math.abs(v50) * 7.1362384635298E+44
                local v52 = math.floor(v51)
                local v53 = v51 - v52
                local v54 = if v53 > 0.5 or v53 == 0.5 and v52 % 2 == 1 then v52 + 1 else v52

                if v50 < 0 then
                    words6[9] = v54 + 2147483648
                else
                    words6[9] = v54
                end
            else
                buffer.writef32(v1, 0, v50)
                words6[9] = buffer.readu32(v1, 0)
            end

            local words7 = t3.words
            local v55 = p7.swing_displacement_limit * 59.999996185302734

            if v55 ~= 0 and v55 > -1.1754943508222875E-38 and v55 < 1.1754943508222875E-38 then
                local v56 = math.abs(v55) * 7.1362384635298E+44
                local v57 = math.floor(v56)
                local v58 = v56 - v57
                local v59 = if v58 > 0.5 or v58 == 0.5 and v57 % 2 == 1 then v57 + 1 else v57

                if v55 < 0 then
                    words7[10] = v59 + 2147483648
                else
                    words7[10] = v59
                end
            else
                buffer.writef32(v1, 0, v55)
                words7[10] = buffer.readu32(v1, 0)
            end

            t3.words[15] = (v16.ball_joint or p7.enforce_swing_free) and 4 or 1
            t3.words[16] = (v16.ball_joint or p7.enforce_twist_free) and 2 or 1

            local v60 = t1.minimum_angle(v17.swing_limit * v16.swing_angle)
            local v61 = t1.minimum_angle(v17.twist_limit * v16.twist_angle)
            local v62 = v8.cos(v60)
            local v63 = v8.cos(v61)
            local words8 = t3.words

            if v60 ~= 0 and v60 > -1.1754943508222875E-38 and v60 < 1.1754943508222875E-38 then
                local v64 = math.abs(v60) * 7.1362384635298E+44
                local v65 = math.floor(v64)
                local v66 = v64 - v65
                local v67 = if v66 > 0.5 or v66 == 0.5 and v65 % 2 == 1 then v65 + 1 else v65

                if v60 < 0 then
                    words8[11] = v67 + 2147483648
                else
                    words8[11] = v67
                end
            else
                buffer.writef32(v1, 0, v60)
                words8[11] = buffer.readu32(v1, 0)
            end

            local words9 = t3.words

            if v61 ~= 0 and v61 > -1.1754943508222875E-38 and v61 < 1.1754943508222875E-38 then
                local v68 = math.abs(v61) * 7.1362384635298E+44
                local v69 = math.floor(v68)
                local v70 = v68 - v69
                local v71 = if v70 > 0.5 or v70 == 0.5 and v69 % 2 == 1 then v69 + 1 else v69

                if v61 < 0 then
                    words9[12] = v71 + 2147483648
                else
                    words9[12] = v71
                end
            else
                buffer.writef32(v1, 0, v61)
                words9[12] = buffer.readu32(v1, 0)
            end

            local words10 = t3.words

            if v62 ~= 0 and v62 > -1.1754943508222875E-38 and v62 < 1.1754943508222875E-38 then
                local v72 = math.abs(v62) * 7.1362384635298E+44
                local v73 = math.floor(v72)
                local v74 = v72 - v73
                local v75 = if v74 > 0.5 or v74 == 0.5 and v73 % 2 == 1 then v73 + 1 else v73

                if v62 < 0 then
                    words10[13] = v75 + 2147483648
                else
                    words10[13] = v75
                end
            else
                buffer.writef32(v1, 0, v62)
                words10[13] = buffer.readu32(v1, 0)
            end

            local words11 = t3.words

            if v63 ~= 0 and v63 > -1.1754943508222875E-38 and v63 < 1.1754943508222875E-38 then
                local v76 = math.abs(v63) * 7.1362384635298E+44
                local v77 = math.floor(v76)
                local v78 = v76 - v77
                local v79 = if v78 > 0.5 or v78 == 0.5 and v77 % 2 == 1 then v77 + 1 else v77

                if v63 < 0 then
                    words11[14] = v79 + 2147483648
                else
                    words11[14] = v79
                end
            else
                buffer.writef32(v1, 0, v63)
                words11[14] = buffer.readu32(v1, 0)
            end

            v13[#v13 + 1] = {
                parent = v14,
                child = i,
                parameters = t3,
                frames = t2
            }
        end
    end

    if #v13 ~= JOINT_COUNT then
        error("Physical skeleton requires22 joints", 0)
    end

    return {
        records = v13
    }
end

local function joint_body_view(p8) -- line: 158
    -- upvalues: pack_world_inverse_inertia (copy)
    local rates = p8.rates

    return {
        reaction_guest_address = 0,
        state = p8.state_flags,
        orientation = rates.orientation,
        center_of_mass = rates.position,
        basis = rates.basis,
        linear_velocity = rates.linear_velocity,
        angular_velocity = rates.angular_velocity,
        force_acceleration = rates.force_acceleration,
        torque_acceleration = rates.torque_acceleration,
        inverse_mass = p8.inertia.inverse_mass,
        world_inverse_inertia = pack_world_inverse_inertia(rates.world_inverse_inertia)
    }
end

function t1.SkeletonJoints.build_reference(p9, p10, p11, p12) -- line: 179
    -- upvalues: compile_active (copy), build_retail_joint_jacobian (copy), joint_body_view (copy)
    return compile_active(p9.records, function(p13) -- line: 180
        -- upvalues: p10 (copy)
        return {
            p10[p13.child + 1].state_flags,
            p10[p13.parent + 1].state_flags
        }
    end, function(p14) -- line: 182
        -- upvalues: p10 (copy), p11 (copy), p12 (copy), build_retail_joint_jacobian (copy), joint_body_view (copy)
        return {
            jacobian = build_retail_joint_jacobian({
                joint_guest_address = 0,
                parameters = p14.parameters,
                frames = p14.frames,
                body_a = joint_body_view(p10[p14.child + 1]),
                body_b = joint_body_view(p10[p14.parent + 1]),
                time_step = p12
            }),
            reaction_a = p11 + p14.child,
            reaction_b = p11 + p14.parent
        }
    end)
end

local v81
local t4 = {}
local build_retail_joint_jacobian_bodies_into = v9.build_retail_joint_jacobian_bodies_into
local v82 = true

function t1.set_prepared(p15) -- line: 254
    -- upvalues: v82 (ref)
    local v83 = v82

    v82 = p15

    return v83
end

local function solver_packing() -- line: 261
    -- upvalues: import (copy)
    return import("skate_core/physics/solver/packing")
end

local function abandon_pool() -- line: 265
    -- upvalues: import (copy), t4 (ref)
    if not (#t4 > 0) then
        return
    end

    local unregister_joint_jacobian = import("skate_core/physics/solver/packing").unregister_joint_jacobian

    for _, v84 in ipairs(t4) do
        unregister_joint_jacobian(v84.jacobian)
    end

    t4 = {}
end

function t1.SkeletonJoints.build(p16, p17, p18, p19) -- line: 275
    -- upvalues: import (copy), v81 (ref), t4 (ref), build_retail_joint_jacobian_bodies_into (copy), v82 (ref), abandon_pool (copy)
    if v81 ~= p17 then
        abandon_pool()
        v81 = p17
    end

    local t5 = {}
    local n1 = 0

    for _, v85 in ipairs(p16.records) do
        local v86 = p17[v85.child + 1]
        local v87 = p17[v85.parent + 1]

        if bit32.band(bit32.bor(v86.state_flags, v87.state_flags), 4) ~= 0 then
            n1 += 1

            local v89 = t4[n1]

            if v89 == nil then
                local v90 = table.create(96, 0)
                local t6 = {
                    words = v90
                }

                v89 = {
                    words = v90,
                    jacobian = t6,
                    row = {
                        reaction_a = 0,
                        reaction_b = 0,
                        jacobian = t6
                    }
                }

                local t7 = t4

                t7[n1] = v89
                v89.packed = import("skate_core/physics/solver/packing").register_joint_jacobian(t6)
            end

            local words, packed = v89.words, v89.packed

            if v82 then
                packed.prepared = false

                local _, v91 = build_retail_joint_jacobian_bodies_into(words, v85.parameters, v85.frames, v86, v87, p19, packed.floats)

                if v91 then
                    packed.prepared = words
                end
            else
                packed.prepared = false
                build_retail_joint_jacobian_bodies_into(words, v85.parameters, v85.frames, v86, v87, p19)
            end

            local row = v89.row

            v89.jacobian.words = words
            row.jacobian = v89.jacobian
            row.reaction_a = p18 + v85.child
            row.reaction_b = p18 + v85.parent
            t5[n1] = row
        end
    end

    return t5
end

function t1.inverse_native_step() -- line: 343
    -- upvalues: v10 (copy)
    local v92 = v10.reciprocal_estimate(0.01666666753590107)
    local v93 = v92 * (-v92 * 0.01666666753590107 + 1) + v92

    return v93 * (-v93 * 0.01666666753590107 + 1) + v93
end

function t1.minimum_angle(p20) -- line: 352
    if p20 - 0.009999999776482582 >= 0 then
        return p20
    end

    return 0.009999999776482582
end

function t1.pack_frame(p21, p22, p23) -- line: 358
    -- upvalues: v1 (copy), retail_quaternion_from_basis (copy)
    local v94 = retail_quaternion_from_basis({
        columns = {
            {
                p22[1][1],
                p22[1][2],
                p22[1][3]
            },
            {
                p22[2][1],
                p22[2][2],
                p22[2][3]
            },
            {
                p22[3][1],
                p22[3][2],
                p22[3][3]
            }
        }
    })
    local x = v94.x
    local v95

    if x ~= 0 and x > -1.1754943508222875E-38 and x < 1.1754943508222875E-38 then
        local v96 = math.abs(x) * 7.1362384635298E+44
        local v97 = math.floor(v96)
        local v98 = v96 - v97

        v95 = if v98 > 0.5 or v98 == 0.5 and v97 % 2 == 1 then v97 + 1 else v97

        if x < 0 then
            v95 += 2147483648
        end
    else
        buffer.writef32(v1, 0, x)
        v95 = buffer.readu32(v1, 0)
    end

    p21[1] = v95

    local y = v94.y
    local v99

    if y ~= 0 and y > -1.1754943508222875E-38 and y < 1.1754943508222875E-38 then
        local v100 = math.abs(y) * 7.1362384635298E+44
        local v101 = math.floor(v100)
        local v102 = v100 - v101

        v99 = if v102 > 0.5 or v102 == 0.5 and v101 % 2 == 1 then v101 + 1 else v101

        if y < 0 then
            v99 += 2147483648
        end
    else
        buffer.writef32(v1, 0, y)
        v99 = buffer.readu32(v1, 0)
    end

    p21[2] = v99

    local z = v94.z
    local v103

    if z ~= 0 and z > -1.1754943508222875E-38 and z < 1.1754943508222875E-38 then
        local v104 = math.abs(z) * 7.1362384635298E+44
        local v105 = math.floor(v104)
        local v106 = v104 - v105

        v103 = if v106 > 0.5 or v106 == 0.5 and v105 % 2 == 1 then v105 + 1 else v105

        if z < 0 then
            v103 += 2147483648
        end
    else
        buffer.writef32(v1, 0, z)
        v103 = buffer.readu32(v1, 0)
    end

    p21[3] = v103

    local w = v94.w
    local v107

    if w ~= 0 and w > -1.1754943508222875E-38 and w < 1.1754943508222875E-38 then
        local v108 = math.abs(w) * 7.1362384635298E+44
        local v109 = math.floor(v108)
        local v110 = v108 - v109

        v107 = if v110 > 0.5 or v110 == 0.5 and v109 % 2 == 1 then v109 + 1 else v109

        if w < 0 then
            v107 += 2147483648
        end
    else
        buffer.writef32(v1, 0, w)
        v107 = buffer.readu32(v1, 0)
    end

    p21[4] = v107

    local v111 = p23[1]
    local v112

    if v111 ~= 0 and v111 > -1.1754943508222875E-38 and v111 < 1.1754943508222875E-38 then
        local v113 = math.abs(v111) * 7.1362384635298E+44
        local v114 = math.floor(v113)
        local v115 = v113 - v114

        v112 = if v115 > 0.5 or v115 == 0.5 and v114 % 2 == 1 then v114 + 1 else v114

        if v111 < 0 then
            v112 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v111)
        v112 = buffer.readu32(v1, 0)
    end

    p21[5] = v112

    local v116 = p23[2]
    local v117

    if v116 ~= 0 and v116 > -1.1754943508222875E-38 and v116 < 1.1754943508222875E-38 then
        local v118 = math.abs(v116) * 7.1362384635298E+44
        local v119 = math.floor(v118)
        local v120 = v118 - v119

        v117 = if v120 > 0.5 or v120 == 0.5 and v119 % 2 == 1 then v119 + 1 else v119

        if v116 < 0 then
            v117 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v116)
        v117 = buffer.readu32(v1, 0)
    end

    p21[6] = v117

    local v121 = p23[3]
    local v122

    if v121 ~= 0 and v121 > -1.1754943508222875E-38 and v121 < 1.1754943508222875E-38 then
        local v123 = math.abs(v121) * 7.1362384635298E+44
        local v124 = math.floor(v123)
        local v125 = v123 - v124

        v122 = if v125 > 0.5 or v125 == 0.5 and v124 % 2 == 1 then v124 + 1 else v124

        if v121 < 0 then
            v122 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v121)
        v122 = buffer.readu32(v1, 0)
    end

    p21[7] = v122

    local v126 = p23[4]
    local v127

    if v126 ~= 0 and v126 > -1.1754943508222875E-38 and v126 < 1.1754943508222875E-38 then
        local v128 = math.abs(v126) * 7.1362384635298E+44
        local v129 = math.floor(v128)
        local v130 = v128 - v129

        v127 = if v130 > 0.5 or v130 == 0.5 and v129 % 2 == 1 then v129 + 1 else v129

        if v126 < 0 then
            v127 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v126)
        v127 = buffer.readu32(v1, 0)
    end

    p21[8] = v127
end

function t1.joint_body(p24) -- line: 376
    -- upvalues: rt (copy), pack_world_inverse_inertia (copy)
    local rates = p24.rates

    return {
        reaction_guest_address = 0,
        state = p24.state_flags,
        orientation = rt.copy(rates.orientation),
        center_of_mass = rt.copy(rates.position),
        basis = rt.copy(rates.basis),
        linear_velocity = rt.copy(rates.linear_velocity),
        angular_velocity = rt.copy(rates.angular_velocity),
        force_acceleration = rt.copy(rates.force_acceleration),
        torque_acceleration = rt.copy(rates.torque_acceleration),
        inverse_mass = p24.inertia.inverse_mass,
        world_inverse_inertia = pack_world_inverse_inertia(rates.world_inverse_inertia)
    }
end

return t1
