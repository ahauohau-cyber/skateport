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
local orthonormalize_part_basis = import("skate_core/physics/board_pose").orthonormalize_part_basis
local build_drive_rows = import("skate_core/physics/drive_solver").build_drive_rows
local pack_world_inverse_inertia = import("skate_core/physics/rigid_body").pack_world_inverse_inertia
local compose_affine = import("skate_core/physics/skeleton_animation_record").compose_affine
local inverse_rigid = import("skate_core/physics/skeleton_root").inverse_rigid
local v8 = import("skate_core/physics/skeleton_body/targets")
local SkeletonTargets, TARGET_COUNT, HARD_STRENGTH, HARD_VELOCITY = v8.SkeletonTargets, v8.TARGET_COUNT, v8.HARD_STRENGTH, v8.HARD_VELOCITY
local TARGET_PARTS, hard = v8.TARGET_PARTS, v8.hard
local BoneDriveDynamics = import("skate_core/physics/skeleton_body/drive_dynamics").BoneDriveDynamics
local v9 = import("skate_core/physics/skeleton_body/drive_frames")
local bone_drive_frames, prepare_bone_drive_frames = v9.bone_drive_frames, v9.prepare_bone_drive_frames

local function skeleton_body() -- line: 56
    -- upvalues: import (copy)
    return import("skate_core/physics/skeleton_body")
end

local t1 = {}
local build_drive_rows_into = import("skate_core/physics/drive_solver/builder").build_drive_rows_into
local bone_drive_frames_into, prepare_bone_drive_frames_in_place = v9.bone_drive_frames_into, v9.prepare_bone_drive_frames_in_place

local function solver_packing() -- line: 73
    -- upvalues: import (copy)
    return import("skate_core/physics/solver/packing")
end

local v10 = {}
local n1 = 0

local function inverse_rigid_scratch(p4, p5, p6) -- line: 86
    local v11 = p6[1]
    local v12 = p6[2]
    local v13 = p6[3]
    local v14 = p6[4]
    local v15 = v11[1]
    local v16 = v11[2]
    local v17 = v11[3]
    local v18 = v12[1]
    local v19 = v12[2]
    local v20 = v12[3]
    local v21 = v13[1]
    local v22 = v13[2]
    local v23 = v13[3]
    local v24 = 0 - v14[1]
    local v25 = 0 - v14[2]
    local v26 = 0 - v14[3]
    local v27 = p4[p5]

    if v27 == nil then
        v27 = {
            { 0, 0, 0, 0 },
            { 0, 0, 0, 0 },
            { 0, 0, 0, 0 },
            { 0, 0, 0, 0 }
        }
        p4[p5] = v27
    end

    local v28 = v27[1]

    v28[1] = v15
    v28[2] = v18
    v28[3] = v21
    v28[4] = 0

    local v29 = v27[2]

    v29[1] = v16
    v29[2] = v19
    v29[3] = v22
    v29[4] = 0

    local v30 = v27[3]

    v30[1] = v17
    v30[2] = v20
    v30[3] = v23
    v30[4] = 0

    local v31 = v27[4]
    local v32 = v24 * v15 + (v25 * v16 + v26 * v17)
    local v33 = v24 * v18 + (v25 * v19 + v26 * v20)
    local v34 = v24 * v21 + (v25 * v22 + v26 * v23)
    local v35 = v24 * 0 + (v25 * 0 + v26 * 0)

    v31[1] = v32
    v31[2] = v33
    v31[3] = v34
    v31[4] = v35
end

t1.SkeletonDriveSettings = {}
t1.BoneDrives = {}
t1.SkeletonDrives = {}
t1.SkeletonDriveIdentity = {}
t1.SkeletonDriveBatch = {}

function t1.SkeletonDrives.new(p7, p8, p9, p10, p11, p12, p13) -- line: 139
    -- upvalues: rt (copy), v1 (copy), import (copy), orthonormalize_part_basis (copy), compose_affine (copy), inverse_rigid (copy), SkeletonTargets (copy), BoneDriveDynamics (copy), bone_drive_frames (copy)
    local ANIMATION_PART_COUNT = import("skate_core/physics/skeleton_body").ANIMATION_PART_COUNT
    local v36 = false

    for i = 1, ANIMATION_PART_COUNT do
        local v37 = p9[i]

        if v37 ~= nil and ANIMATION_PART_COUNT <= v37 then
            v36 = true
            break
        end
    end

    local v38 = v36 or p9[1] ~= nil or p9[24] ~= nil

    if not v38 then
        for i = 1, 22 do
            if p9[i + 1] == nil then
                v38 = true
                break
            end
        end
    end

    if v38 then
        error("Skeleton drives require22 bone pairs and two roots", 0)
    end

    local v39 = table.create(ANIMATION_PART_COUNT)

    for i = 1, ANIMATION_PART_COUNT do
        v39[i] = inverse_rigid(p7[i])
    end

    local v40 = table.create(ANIMATION_PART_COUNT)

    for i = 0, ANIMATION_PART_COUNT - 1 do
        local v41 = p9[i + 1]

        if v41 ~= nil then
            local t2 = {
                bone_drive_frames(p7[i + 1], v39[i + 1], v39[v41 + 1]),
                bone_drive_frames(p7[i + 1], v39[i + 1], v39[24])
            }
            local v42 = BoneDriveDynamics.default()

            v42.mode = 2
            BoneDriveDynamics.enable(v42, 0, 1, p13.bone)
            v42.mode = 0
            BoneDriveDynamics.enable(v42, 1, 1, p13.bone)
            v40[i + 1] = {
                parent = { v41, 23 },
                active = { true, true },
                frames = t2,
                dynamics = v42
            }
        else
            v40[i + 1] = nil
        end
    end

    local v43 = SkeletonTargets.new(p12)
    local v44 = p8[24]
    local v45 = table.create(16)

    for i = 0, 3 do
        for j = 0, 3 do
            local v46 = i * 4 + j + 1
            local v47 = v44[i + 1][j + 1]

            if v47 ~= 0 and v47 > -1.1754943508222875E-38 and v47 < 1.1754943508222875E-38 then
                local v48 = math.abs(v47) * 7.1362384635298E+44
                local v49 = math.floor(v48)
                local v50 = v48 - v49
                local v51 = if v50 > 0.5 or v50 == 0.5 and v49 % 2 == 1 then v49 + 1 else v49

                if v47 < 0 then
                    v45[v46] = v51 + 2147483648
                else
                    v45[v46] = v51
                end
            else
                buffer.writef32(v1, 0, v47)
                v45[v46] = buffer.readu32(v1, 0)
            end
        end
    end

    local v52 = orthonormalize_part_basis(v45)

    buffer.writeu32(v1, 0, v52[1])

    local v54 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v52[2])

    local v56 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v52[3])

    local v58 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v52[4])

    local t3 = {
        v54,
        v56,
        v58,
        (buffer.readf32(v1, 0))
    }

    buffer.writeu32(v1, 0, v52[5])

    local v61 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v52[6])

    local v63 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v52[7])

    local v65 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v52[8])

    local t4 = {
        v61,
        v63,
        v65,
        (buffer.readf32(v1, 0))
    }

    buffer.writeu32(v1, 0, v52[9])

    local v68 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v52[10])

    local v70 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v52[11])

    local v72 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v52[12])

    local t5 = {
        v68,
        v70,
        v72,
        (buffer.readf32(v1, 0))
    }

    buffer.writeu32(v1, 0, v52[13])

    local v75 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v52[14])

    local v77 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v52[15])

    local v79 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v52[16])

    local t6 = {
        t3,
        t4,
        t5,
        {
            v75,
            v77,
            v79,
            (buffer.readf32(v1, 0))
        }
    }

    SkeletonTargets.reset(v43, compose_affine(p10, t6), p11)

    return {
        targets = v43,
        bones = v40,
        settings = rt.copy(p13)
    }
end

function t1.SkeletonDrives.update(p14, p15, p16, p17) -- line: 240
    -- upvalues: HARD_STRENGTH (copy), HARD_VELOCITY (copy), hard (copy), BoneDriveDynamics (copy), bone_drive_frames (copy), bone_drive_frames_into (copy), v10 (ref), n1 (ref), inverse_rigid_scratch (copy)
    local v81 = #p15

    if v81 ~= n1 then
        v10 = table.create(v81)
        n1 = v81
    end

    local v82 = v10

    for i = 1, v81 do
        inverse_rigid_scratch(v82, i, p15[i])
    end

    local settings = p14.settings
    local strength, bone = settings.strength, settings.bone
    local v83, v84

    if settings.enabled then
        v83 = strength[1]
        v84 = strength[2]
    else
        v83 = 0
        v84 = 0
    end

    p14.targets.dynamics[1].linear = hard(HARD_VELOCITY, HARD_STRENGTH)

    for i = 1, 22 do
        local v85 = p14.bones[i + 1]

        if v85 ~= nil then
            local v86 = not p16

            if not v86 then
                v86 = i >= 1 and i <= 5 or i >= 7 and i <= 9
            end

            local dynamics = v85.dynamics
            local v87, v88

            if p17 >= 1 or not v86 then
                v88 = v84
                dynamics.mode = 0
                v87 = v83
            else
                dynamics.mode = 3

                local v89 = settings.collision_strength[i + 1]
                local v90 = v89[1]

                v87 = ((1 - v90) * p17 + v90) * strength[1]

                local v91 = v89[2]

                v88 = ((1 - v91) * p17 + v91) * strength[2]
            end

            local strengths = dynamics.strengths

            if type(strengths) == "table" and strengths ~= strength and #strengths == 2 then
                strengths[1] = v87
                strengths[2] = v88
            else
                dynamics.strengths = { v87, v88 }
            end

            local active, frames = v85.active, v85.frames

            if active[1] then
                local v92 = frames[1]

                if v92 == nil or v92 == frames[2] then
                    frames[1] = bone_drive_frames(p15[i + 1], v82[i + 1], v82[v85.parent[1] + 1])
                else
                    bone_drive_frames_into(v92, p15[i + 1], v82[i + 1], v82[v85.parent[1] + 1])
                end

                BoneDriveDynamics.enable(dynamics, 0, v87, bone)
            end

            if active[2] then
                local v93 = frames[2]

                if v93 == nil or v93 == frames[1] then
                    frames[2] = bone_drive_frames(p15[i + 1], v82[i + 1], v82[v85.parent[2] + 1])
                else
                    bone_drive_frames_into(v93, p15[i + 1], v82[i + 1], v82[v85.parent[2] + 1])
                end

                BoneDriveDynamics.enable(dynamics, 1, v88, bone)
            end
        end
    end
end

function t1.SkeletonDrives.update_reference(p18, p19, p20, p21) -- line: 314
    -- upvalues: rt (copy), inverse_rigid (copy), HARD_STRENGTH (copy), HARD_VELOCITY (copy), hard (copy), BoneDriveDynamics (copy), bone_drive_frames (copy)
    local v94 = table.create(#p19)

    for i = 1, #p19 do
        v94[i] = inverse_rigid(p19[i])
    end

    local v95 = rt.copy(p18.settings)
    local v96 = if v95.enabled then rt.copy(v95.strength) else table.create(2, 0)

    p18.targets.dynamics[1].linear = hard(HARD_VELOCITY, HARD_STRENGTH)

    for i = 1, 22 do
        local v97 = p18.bones[i + 1]

        if v97 ~= nil then
            local v98 = not p20

            if not v98 then
                v98 = i >= 1 and i <= 5 or i >= 7 and i <= 9
            end

            local v99

            if p21 >= 1 or not v98 then
                v97.dynamics.mode = 0
                v99 = rt.copy(v96)
            else
                v97.dynamics.mode = 3
                v99 = table.create(2)

                local v100 = v95.collision_strength[i + 1][1]

                v99[1] = ((1 - v100) * p21 + v100) * v95.strength[1]

                local v101 = v95.collision_strength[i + 1][2]

                v99[2] = ((1 - v101) * p21 + v101) * v95.strength[2]
            end

            v97.dynamics.strengths = rt.copy(v99)

            for j = 0, 1 do
                if v97.active[j + 1] then
                    v97.frames[j + 1] = bone_drive_frames(p19[i + 1], v94[i + 1], v94[v97.parent[j + 1] + 1])
                    BoneDriveDynamics.enable(v97.dynamics, j, v99[j + 1], v95.bone)
                end
            end
        end
    end
end

local v102
local t7 = {}

t1.SHARED_BODY_STATES = true

local t8 = {}
local t9 = {}
local t10 = {}
local t11 = {}
local n2 = 0

local function abandon_pool() -- line: 439
    -- upvalues: import (copy), t7 (ref), t8 (ref), t9 (ref), t10 (ref), t11 (ref)
    if #t7 > 0 then
        local unregister_drive_rows = import("skate_core/physics/solver/packing").unregister_drive_rows

        for _, v103 in ipairs(t7) do
            unregister_drive_rows(v103.row)
        end

        t7 = {}
    end

    local t12 = {}
    local t13 = {}
    local t14 = {}

    t8 = {}
    t9 = t12
    t10 = t13
    t11 = t14
end

local function drive_body_into(p22, p23, p24) -- line: 459
    -- upvalues: rt (copy)
    local rates = p23.rates

    p22.reaction_index = p24
    p22.state = p23.state_flags

    local orientation = rates.orientation
    local orientation2 = p22.orientation
    local x, y, z, w = orientation.x, orientation.y, orientation.z, orientation.w

    orientation2.x = x
    orientation2.y = y
    orientation2.z = z
    orientation2.w = w

    local basis = rates.basis
    local columns = basis.columns

    if #columns == 3 then
        local columns2 = p22.basis.columns
        local v104 = columns[1]
        local v105 = columns[2]
        local v106 = columns[3]

        if #columns2 == 3 and #v104 == 3 and #v105 == 3 and #v106 == 3 and #columns2[1] == 3 and #columns2[2] == 3 and #columns2[3] == 3 then
            local v107 = columns2[1]
            local v108 = v104[1]
            local v109 = v104[2]
            local v110 = v104[3]

            v107[1] = v108
            v107[2] = v109
            v107[3] = v110

            local v111 = columns2[2]
            local v112 = v105[1]
            local v113 = v105[2]
            local v114 = v105[3]

            v111[1] = v112
            v111[2] = v113
            v111[3] = v114

            local v115 = columns2[3]
            local v116 = v106[1]
            local v117 = v106[2]
            local v118 = v106[3]

            v115[1] = v116
            v115[2] = v117
            v115[3] = v118
        else
            p22.basis = {
                columns = {
                    table.clone(v104),
                    table.clone(v105),
                    table.clone(v106)
                }
            }
        end
    else
        p22.basis = rt.copy(basis)
    end

    local position = rates.position
    local center_of_mass = p22.center_of_mass
    local x2, y2, z2 = position.x, position.y, position.z

    center_of_mass.x = x2
    center_of_mass.y = y2
    center_of_mass.z = z2

    local linear_velocity = rates.linear_velocity
    local linear_velocity2 = p22.linear_velocity
    local x3, y3, z3 = linear_velocity.x, linear_velocity.y, linear_velocity.z

    linear_velocity2.x = x3
    linear_velocity2.y = y3
    linear_velocity2.z = z3

    local angular_velocity = rates.angular_velocity
    local angular_velocity2 = p22.angular_velocity
    local x4, y4, z4 = angular_velocity.x, angular_velocity.y, angular_velocity.z

    angular_velocity2.x = x4
    angular_velocity2.y = y4
    angular_velocity2.z = z4

    local force_acceleration = rates.force_acceleration
    local force_acceleration2 = p22.force_acceleration
    local x5, y5, z5 = force_acceleration.x, force_acceleration.y, force_acceleration.z

    force_acceleration2.x = x5
    force_acceleration2.y = y5
    force_acceleration2.z = z5

    local torque_acceleration = rates.torque_acceleration
    local torque_acceleration2 = p22.torque_acceleration
    local x6, y6, z6 = torque_acceleration.x, torque_acceleration.y, torque_acceleration.z

    torque_acceleration2.x = x6
    torque_acceleration2.y = y6
    torque_acceleration2.z = z6
    p22.inverse_mass = p23.inertia.inverse_mass

    local columns2 = rates.world_inverse_inertia.columns
    local v119 = columns2[1]
    local v120 = columns2[2]
    local v121 = columns2[3]
    local world_inverse_inertia = p22.world_inverse_inertia
    local full = world_inverse_inertia.full
    local v122 = v119[1]
    local v123 = v120[1]
    local v124 = v121[1]

    full.x = v122
    full.y = v123
    full.z = v124

    local split = world_inverse_inertia.split
    local v125 = v121[3]
    local v126 = v120[2]
    local v127 = v121[2]

    split.x = v125
    split.y = v126
    split.z = v127

    return p22
end

t1.drive_body_into = drive_body_into

local function shared_state(p25, p26, p27, p28, p29, p30) -- line: 515
    -- upvalues: t1 (copy), drive_body_into (copy)
    local v128 = p25[p27]

    if v128 == nil then
        local v129 = t1.drive_body(p28, p29)

        p25[p27] = v129
        p26[p27] = p30

        return v129
    end

    if p26[p27] ~= p30 then
        drive_body_into(v128, p28, p29)
        p26[p27] = p30
    end

    return v128
end

local function pooled_drive_rows(p31, p32, p33, p34, p35, p36) -- line: 529
    -- upvalues: import (copy), build_drive_rows (copy), build_drive_rows_into (copy), t7 (ref)
    local v130 = t7[p31]

    if v130 == nil then
        local v131 = build_drive_rows(p32, p33, p34, p35, p36)
        local t15 = {
            target_identity = false,
            bone_identity = false,
            row = v131
        }
        local t16 = t7

        t16[p31] = t15
        import("skate_core/physics/solver/packing").register_drive_rows(v131)

        return t15
    end

    build_drive_rows_into(v130.row, p32, p33, p34, p35, p36)

    return v130
end

function t1.SkeletonDrives.build(p37, p38, p39, p40, p41) -- line: 543
    -- upvalues: TARGET_COUNT (copy), TARGET_PARTS (copy), prepare_bone_drive_frames (copy), t1 (copy), prepare_bone_drive_frames_in_place (copy), v102 (ref), t8 (ref), t9 (ref), t10 (ref), t11 (ref), n2 (ref), abandon_pool (copy), drive_body_into (copy), pooled_drive_rows (copy)
    if v102 ~= p37 then
        abandon_pool()
        v102 = p37
    end

    n2 += 1

    local v132 = n2
    local v133 = table.create(48)
    local v134 = table.create(48)
    local v135 = table.create(48)
    local targets = p37.targets
    local frames = targets.frames
    local v136 = TARGET_COUNT - 1
    local n3 = 0

    for i = 0, v136 do
        local v137 = prepare_bone_drive_frames(frames[i + 1])

        frames[i + 1] = v137

        local v138 = TARGET_PARTS[i + 1]
        local v139 = p38[v138 + 1]
        local v140 = targets.bodies[i + 1]

        if bit32.band(bit32.bor(v139.state_flags, v140.state_flags), 4) ~= 0 then
            n3 += 1

            local t17 = t8
            local t18 = t9
            local v143 = v138 + 1
            local v144 = p39 + v138
            local v145 = t17[v143]

            if v145 ~= nil then
                if t18[v143] ~= v132 then
                    drive_body_into(v145, v139, v144)
                    t18[v143] = v132
                end
            else
                v145 = t1.drive_body(v139, v144)
                t17[v143] = v145
                t18[v143] = v132
            end

            local t19 = t10
            local t20 = t11
            local v146 = i + 1
            local v147 = p40 + i
            local v148 = t19[v146]

            if v148 ~= nil then
                if t20[v146] ~= v132 then
                    drive_body_into(v148, v140, v147)
                    t20[v146] = v132
                end
            else
                v148 = t1.drive_body(v140, v147)
                t19[v146] = v148
                t20[v146] = v132
            end

            local v149 = pooled_drive_rows(n3, v145, v148, v137, targets.dynamics[i + 1], p41)

            v133[n3] = v149.row

            local target_identity = v149.target_identity

            if target_identity then
                target_identity[1] = i
            else
                target_identity = {
                    tag = "Target",
                    i
                }
                v149.target_identity = target_identity
            end

            v134[n3] = target_identity
            v135[n3] = i >= 2
        end
    end

    for i = 1, 22 do
        local v150 = p37.bones[i + 1]

        if v150 ~= nil then
            for j = 0, 1 do
                if v150.active[j + 1] then
                    local v151 = v150.frames[j + 1]

                    if v151 == v150.frames[2 - j] then
                        v151 = prepare_bone_drive_frames(v151)
                        v150.frames[j + 1] = v151
                    else
                        prepare_bone_drive_frames_in_place(v151)
                    end

                    local v152 = v150.parent[j + 1]
                    local v153 = p38[i + 1]
                    local v154 = p38[v152 + 1]

                    if bit32.band(bit32.bor(v153.state_flags, v154.state_flags), 4) ~= 0 then
                        n3 += 1

                        local t21 = t8
                        local t22 = t9
                        local v157 = i + 1
                        local v158 = p39 + i
                        local v159 = t21[v157]

                        if v159 ~= nil then
                            if t22[v157] ~= v132 then
                                drive_body_into(v159, v153, v158)
                                t22[v157] = v132
                            end
                        else
                            v159 = t1.drive_body(v153, v158)
                            t21[v157] = v159
                            t22[v157] = v132
                        end

                        local t23 = t8
                        local t24 = t9
                        local v160 = v152 + 1
                        local v161 = p39 + v152
                        local v162 = t23[v160]

                        if v162 ~= nil then
                            if t24[v160] ~= v132 then
                                drive_body_into(v162, v154, v161)
                                t24[v160] = v132
                            end
                        else
                            v162 = t1.drive_body(v154, v161)
                            t23[v160] = v162
                            t24[v160] = v132
                        end

                        local v163 = pooled_drive_rows(n3, v159, v162, v151, v150.dynamics.channels[j + 1], p41)

                        v133[n3] = v163.row

                        local bone_identity = v163.bone_identity

                        if bone_identity then
                            bone_identity.part = i
                            bone_identity.channel = j
                        else
                            bone_identity = {
                                tag = "Bone",
                                part = i,
                                channel = j
                            }
                            v163.bone_identity = bone_identity
                        end

                        v134[n3] = bone_identity
                        v135[n3] = true
                    end
                end
            end
        end
    end

    return {
        rows = v133,
        identities = v134,
        spy = v135
    }
end

function t1.SkeletonDrives.build_reference(p42, p43, p44, p45, p46) -- line: 633
    -- upvalues: rt (copy), build_drive_rows (copy), TARGET_COUNT (copy), TARGET_PARTS (copy), prepare_bone_drive_frames (copy), t1 (copy)
    local t25 = {
        rows = table.create(48),
        identities = table.create(48),
        spy = table.create(48)
    }

    for i = 0, TARGET_COUNT - 1 do
        p42.targets.frames[i + 1] = prepare_bone_drive_frames(p42.targets.frames[i + 1])

        local v164 = TARGET_PARTS[i + 1]
        local v165 = p43[v164 + 1]
        local v166 = p42.targets.bodies[i + 1]

        if bit32.band(bit32.bor(v165.state_flags, v166.state_flags), 4) ~= 0 then
            table.insert(t25.rows, build_drive_rows(t1.drive_body(v165, p44 + v164), t1.drive_body(v166, p45 + i), rt.copy(p42.targets.frames[i + 1]), rt.copy(p42.targets.dynamics[i + 1]), p46))
            table.insert(t25.identities, {
                tag = "Target",
                i
            })
            table.insert(t25.spy, i >= 2)
        end
    end

    for i = 1, 22 do
        local v173 = p42.bones[i + 1]

        if v173 ~= nil then
            for j = 0, 1 do
                if v173.active[j + 1] then
                    v173.frames[j + 1] = prepare_bone_drive_frames(v173.frames[j + 1])

                    local v174 = v173.parent[j + 1]
                    local v175 = p43[i + 1]
                    local v176 = p43[v174 + 1]

                    if bit32.band(bit32.bor(v175.state_flags, v176.state_flags), 4) ~= 0 then
                        table.insert(t25.rows, build_drive_rows(t1.drive_body(v175, p44 + i), t1.drive_body(v176, p44 + v174), rt.copy(v173.frames[j + 1]), rt.copy(v173.dynamics.channels[j + 1]), p46))
                        table.insert(t25.identities, {
                            tag = "Bone",
                            part = i,
                            channel = j
                        })
                        table.insert(t25.spy, true)
                    end
                end
            end
        end
    end

    return t25
end

function t1.drive_body(p47, p48) -- line: 699
    -- upvalues: rt (copy)
    local rates = p47.rates
    local basis = rates.basis
    local columns = basis.columns
    local v182 = if #columns == 3 then {
        columns = {
            table.clone(columns[1]),
            table.clone(columns[2]),
            table.clone(columns[3])
        }
    } else rt.copy(basis)
    local columns2 = rates.world_inverse_inertia.columns
    local v183 = columns2[1]
    local v184 = columns2[2]
    local v185 = columns2[3]

    return {
        reaction_index = p48,
        state = p47.state_flags,
        orientation = table.clone(rates.orientation),
        basis = v182,
        center_of_mass = table.clone(rates.position),
        linear_velocity = table.clone(rates.linear_velocity),
        angular_velocity = table.clone(rates.angular_velocity),
        force_acceleration = table.clone(rates.force_acceleration),
        torque_acceleration = table.clone(rates.torque_acceleration),
        inverse_mass = p47.inertia.inverse_mass,
        world_inverse_inertia = {
            full = {
                x = v183[1],
                y = v184[1],
                z = v185[1]
            },
            split = {
                x = v185[3],
                y = v184[2],
                z = v185[2]
            }
        }
    }
end

function t1.drive_body_reference(p49, p50) -- line: 734
    -- upvalues: rt (copy), pack_world_inverse_inertia (copy)
    local rates = p49.rates

    return {
        reaction_index = p50,
        state = p49.state_flags,
        orientation = rt.copy(rates.orientation),
        basis = rt.copy(rates.basis),
        center_of_mass = rt.copy(rates.position),
        linear_velocity = rt.copy(rates.linear_velocity),
        angular_velocity = rt.copy(rates.angular_velocity),
        force_acceleration = rt.copy(rates.force_acceleration),
        torque_acceleration = rt.copy(rates.torque_acceleration),
        inverse_mass = p49.inertia.inverse_mass,
        world_inverse_inertia = pack_world_inverse_inertia(rates.world_inverse_inertia)
    }
end

return t1
