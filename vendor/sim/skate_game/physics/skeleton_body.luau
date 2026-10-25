-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_from_bits(p1) -- line: 7
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p1)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local Vector3 = import("skate_core/math").Vector3
local physics_bone_frame = import("skate_core/physics/skeleton_animation_record").physics_bone_frame
local v2 = import("skate_core/physics/skeleton_body")
local HatGeometry, SkeletonBody, SkeletonBodyDefinition, SkeletonCollisionMode = v2.HatGeometry, v2.SkeletonBody, v2.SkeletonBodyDefinition, v2.SkeletonCollisionMode
local SkeletonCollisionFeedback, SkeletonDrives, SkeletonJoints = v2.SkeletonCollisionFeedback, v2.SkeletonDrives, v2.SkeletonJoints
local Collections = import("skate_data/collections").Collections
local v3 = import("skate_data/physics_skeleton")
local PhysicsSkeleton, PhysicsBone = v3.PhysicsSkeleton, v3.PhysicsBone
local v4 = import("skate_game/physics/skeleton_body_collision_settings")
local v5 = import("skate_game/physics/skeleton_body_drive_settings")
local t1 = {}

local function path_join(p2, p3) -- line: 43
    if p2 == nil then
        return p3
    end

    return tostring(p2) .. "/" .. p3
end

local function map_from_bits(p4) -- line: 50
    -- upvalues: v1 (copy)
    local v6 = table.create(#p4)

    for i = 1, #p4 do
        buffer.writeu32(v1, 0, p4[i])
        v6[i] = buffer.readf32(v1, 0)
    end

    return v6
end

function t1.load_collision(p5, p6, p7, p8) -- line: 60
    -- upvalues: SkeletonCollisionMode (copy), v4 (copy)
    return SkeletonCollisionMode.new_normal(v4.load(p5, p6, p7), p8)
end

function t1.load_feedback(p9, p10) -- line: 66
    -- upvalues: rt (copy), SkeletonCollisionFeedback (copy), v4 (copy)
    return SkeletonCollisionFeedback.new(v4.feedback(p9, rt.copy(p10)))
end

function t1.load_drives(p11, p12, p13, p14, p15, p16, p17, p18, p19, p20) -- line: 77
    -- upvalues: rt (copy), v1 (copy), SkeletonDrives (copy), Collections (copy), PhysicsSkeleton (copy), v5 (copy)
    for _, v8 in p15 do
        if #p14 <= v8 then
            error("Skeleton drive initial hierarchy has missing bones", 0)
        end
    end

    local PHYS_TPOSE = PhysicsSkeleton.load(if p11 == nil then "private/stock/physics-skeletons.json" else tostring(p11) .. "/" .. "private/stock/physics-skeletons.json", p13, "PHYS_TPOSE")

    if #PHYS_TPOSE.bones ~= 24 then
        error("Skeleton drives require24 bone records", 0)
    end

    local t2 = {}

    for _, v9 in p17.records do
        t2[v9.child + 1] = v9.parent
    end

    local v10 = rt.from_fn(24, function(p21) -- line: 107
        -- upvalues: p14 (copy), p15 (copy), rt (copy)
        return rt.copy(p14[p15[p21 + 1] + 1])
    end)
    local v11 = rt.filled(24, { 0, 0 })
    local CollisionDriveScalar = Collections.float(p12, "physics_skeleton_drives", "default", "CollisionDriveScalar")

    for i = 1, 23 do
        local v12 = string.format("PART_%s", PHYS_TPOSE.bones[i + 1].name)
        local v13 = Collections.words(p12, "physics_skeleton_drives", "default", v12, 9)
        local v14 = i + 1

        buffer.writeu32(v1, 0, v13[6])

        local v16 = buffer.readf32(v1, 0) * CollisionDriveScalar

        buffer.writeu32(v1, 0, v13[7])
        v11[v14] = {
            v16,
            buffer.readf32(v1, 0) * CollisionDriveScalar
        }
    end

    local t3 = {
        bone = v5.load(p12),
        enabled = Collections.boolean(p12, "animation", "default", "Use_Drives"),
        strength = {
            Collections.float(p12, "animation", "default", "DriveStrengthLocal"),
            (Collections.float(p12, "animation", "default", "DriveStrengthRootLocal"))
        },
        collision_strength = v11
    }

    return SkeletonDrives.new(v10, p16, t2, rt.copy(p18), rt.copy(p19), rt.copy(p20), t3)
end

function t1.load_joints(p22, p23, p24, p25, p26, p27) -- line: 147
    -- upvalues: rt (copy), v1 (copy), physics_bone_frame (copy), SkeletonJoints (copy), Collections (copy), PhysicsSkeleton (copy), PhysicsBone (copy), t1 (copy)
    local v18 = false

    for _, v19 in p27 do
        if #p25 <= v19 then
            v18 = true
            break
        end
    end

    if #p26 ~= #p25 or v18 then
        error("Physical joint hierarchy differs from initial rig pose", 0)
    end

    local PHYS_TPOSE = PhysicsSkeleton.load(if p22 == nil then "private/stock/physics-skeletons.json" else tostring(p22) .. "/" .. "private/stock/physics-skeletons.json", p24, "PHYS_TPOSE")

    if #PHYS_TPOSE.bones ~= 24 then
        error("Physical joints require24 bone records", 0)
    end

    local v20 = rt.from_fn(24, function(p28) -- line: 173
        -- upvalues: p25 (copy), p27 (copy), rt (copy)
        return rt.copy(p25[p27[p28 + 1] + 1])
    end)
    local t4 = {}

    for i = 0, 23 do
        local v21 = p26[p27[i + 1] + 1]
        local n1 = 0

        while v21 ~= -1 do
            if v21 < 0 then
                error("Invalid animation parent index", 0)
            end

            if #p26 <= v21 or #p26 <= n1 then
                error("Invalid or cyclic animation hierarchy", 0)
            end

            local v22 = #p27 - 1
            local v23

            for j = 0, v22 do
                if p27[j + 1] == v21 then
                    v23 = j
                    break
                end
            end

            if v23 == nil then
                v21 = p26[v21 + 1]
                n1 += 1
                continue
            end

            t4[i + 1] = v23
            break
        end
    end

    local v24 = rt.from_fn(24, function(p29) -- line: 206
        -- upvalues: PHYS_TPOSE (copy), v1 (copy), physics_bone_frame (copy), PhysicsBone (copy)
        local v25 = PHYS_TPOSE.bones[p29 + 1]
        local v26 = PhysicsBone.translation(v25)
        local v27 = v26[1]
        local v28 = v26[2]
        local v29 = v26[3]
        local t5 = {}

        buffer.writeu32(v1, 0, v25.words[1])

        local v31 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v25.words[2])

        local v33 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v25.words[3])

        local v35 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v25.words[4])
        t5.parent_orientation = {
            v31,
            v33,
            v35,
            (buffer.readf32(v1, 0))
        }
        buffer.writeu32(v1, 0, v25.words[5])

        local v38 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v25.words[6])

        local v40 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v25.words[7])

        local v42 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v25.words[8])
        t5.joint_orientation = {
            v38,
            v40,
            v42,
            (buffer.readf32(v1, 0))
        }
        t5.volume_frame = physics_bone_frame(PhysicsBone.rotation(v25), { v27, v28, v29, 0 })
        buffer.writeu32(v1, 0, v25.words[22])
        t5.swing_limit = buffer.readf32(v1, 0)
        buffer.writeu32(v1, 0, v25.words[21])
        t5.twist_limit = buffer.readf32(v1, 0)

        return t5
    end)
    local JOINT_NAMES = t1.JOINT_NAMES
    local v46 = table.create(22)

    for _, v47 in JOINT_NAMES do
        local v48 = Collections.words(p23, "physics_skeleton_joints", "default", v47, 5)
        local t6 = {}

        t6.ball_joint = bit32.rshift(v48[1], 24) ~= 0
        buffer.writeu32(v1, 0, v48[2])
        t6.swing_angle = buffer.readf32(v1, 0)
        buffer.writeu32(v1, 0, v48[3])
        t6.twist_angle = buffer.readf32(v1, 0)
        buffer.writeu32(v1, 0, v48[4])
        t6.swing_ragdoll = buffer.readf32(v1, 0)
        buffer.writeu32(v1, 0, v48[5])
        t6.twist_ragdoll = buffer.readf32(v1, 0)
        table.insert(v46, t6)
    end

    local v54 = Collections.words(p23, "physics_skeleton", "default", "DisplacementLimit", 4)
    local v55 = table.create(#v54)

    for i = 1, #v54 do
        buffer.writeu32(v1, 0, v54[i])
        v55[i] = buffer.readf32(v1, 0)
    end

    local t7 = {
        displacement_limit = v55,
        twist_displacement_limit = Collections.float(p23, "physics_skeleton", "default", "TwistDisplacementLimit"),
        swing_displacement_limit = Collections.float(p23, "physics_skeleton", "default", "SwingDisplacementLimit"),
        enforce_swing_free = Collections.boolean(p23, "physics_skeleton_joints", "default", "EnforceSwingFree"),
        enforce_twist_free = Collections.boolean(p23, "physics_skeleton_joints", "default", "EnforceTwistFree")
    }

    if #v46 ~= 22 then
        error("Physical joint setting count", 0)
    end

    return SkeletonJoints.new(v20, t4, v24, v46, t7)
end

function t1.load(p30, p31, p32, p33, p34, p35, p36) -- line: 264
    -- upvalues: rt (copy), v1 (copy), Vector3 (copy), HatGeometry (copy), SkeletonBody (copy), SkeletonBodyDefinition (copy), Collections (copy), PhysicsSkeleton (copy), PhysicsBone (copy)
    local PHYS_TPOSE = PhysicsSkeleton.load(if p30 == nil then "private/stock/physics-skeletons.json" else tostring(p30) .. "/" .. "private/stock/physics-skeletons.json", p32, "PHYS_TPOSE")

    if #PHYS_TPOSE.bones ~= 24 then
        error("Physical skeleton requires24 bone records", 0)
    end

    local v57 = rt.filled(24, Vector3.ZERO)
    local v58 = table.create(24)

    for i = 0, #PHYS_TPOSE.bones - 1 do
        local v59 = PHYS_TPOSE.bones[i + 1]
        local v60 = PhysicsBone.size(v59)
        local v61 = v60[1]
        local v62 = v60[2]
        local v63 = v60[3]

        v57[i + 1] = Vector3.new(v61, v62, v63)

        local v64 = Collections.words(p31, "physics_skeleton_bones", "default", string.format("PART_%s", v59.name), 6)
        local t8 = {}

        buffer.writeu32(v1, 0, v64[1])
        t8.mass_factor = buffer.readf32(v1, 0)
        buffer.writeu32(v1, 0, v64[2])
        t8.ragdoll_mass_factor = buffer.readf32(v1, 0)
        t8.has_collision = bit32.rshift(v64[3], 24) ~= 0
        t8.use_root_drive = bit32.band(bit32.rshift(v64[3], 16), 255) ~= 0
        t8.volume_type = v64[4]
        buffer.writeu32(v1, 0, v64[5])
        t8.volume_scalar = buffer.readf32(v1, 0)
        t8.num_parents = v64[6]
        table.insert(v58, t8)
    end

    local function value(p37) -- line: 305
        -- upvalues: p31 (copy), Collections (copy)
        return Collections.float(p31, "physics_skeleton", "default", p37)
    end

    local t9 = {
        density = Collections.float(p31, "physics_skeleton", "default", "MassOfSkeleton"),
        root_radius = Collections.float(p31, "physics_skeleton", "default", "SkateRootCapsuleRadius"),
        root_half_length = Collections.float(p31, "physics_skeleton", "default", "SkateRootCapsuleLength"),
        capsule_radius_scalar = Collections.float(p31, "physics_skeleton_bones", "default", "CapsuleRadiusScalar"),
        capsule_length_scalar = Collections.float(p31, "physics_skeleton", "default", "CapsuleLengthScalar"),
        ragdoll_inverse_mass_factor = Collections.float(p31, "physics_wipeout", "default", "RagdollInvMassFactor"),
        inertia_multiply_type = Collections.integer(p31, "animation", "default", "InertiaMultiplyType"),
        inertia_factor = Collections.float(p31, "animation", "default", "InertiaMultFactor")
    }
    local v71

    if p36 ~= nil then
        local function vector(p38) -- line: 334
            -- upvalues: p31 (copy), p36 (copy), v1 (copy), Vector3 (copy), Collections (copy)
            local v72 = Collections.words(p31, "physics_hat", p36, p38, 4)
            local v73 = table.create(#v72)

            for i = 1, #v72 do
                buffer.writeu32(v1, 0, v72[i])
                v73[i] = buffer.readf32(v1, 0)
            end

            return Vector3.new(v73[1], v73[2], v73[3])
        end

        local Hash_372DF5DB27AF1C79 = Collections.float(p31, "physics_hat", p36, "Hash_372DF5DB27AF1C79")
        local Thickness = Collections.float(p31, "physics_hat", p36, "Thickness")
        local v75 = Collections.words(p31, "physics_hat", p36, "OrientationOffset", 4)
        local v76 = table.create(#v75)

        for i = 1, #v75 do
            buffer.writeu32(v1, 0, v75[i])
            v76[i] = buffer.readf32(v1, 0)
        end

        local v78 = Vector3.new(v76[1], v76[2], v76[3])
        local v79 = Collections.words(p31, "physics_hat", p36, "PosOffset", 4)
        local v80 = table.create(#v79)

        for i = 1, #v79 do
            buffer.writeu32(v1, 0, v79[i])
            v80[i] = buffer.readf32(v1, 0)
        end

        local v82 = Vector3.new(v80[1], v80[2], v80[3])

        v71 = HatGeometry.from_offsets(Hash_372DF5DB27AF1C79, Thickness, v78, v82)
    end

    if #v58 ~= 24 then
        error("Skeleton bone count", 0)
    end

    local v83 = SkeletonBodyDefinition.new(v57, v58, t9, v71)

    return SkeletonBody.new(v83, p33, rt.copy(p34), rt.copy(p35))
end

t1.JOINT_NAMES = {
    "JOINT_NECK_NECK1",
    "JOINT_SPINE3_NECK",
    "JOINT_LEFT_FOREARM_HAND",
    "JOINT_LEFT_ARM_FOREARM",
    "JOINT_LEFT_SHOULDER_ARM",
    "JOINT_SPINE3_LEFT_SHOULDER",
    "JOINT_RIGHT_FOREARM_HAND",
    "JOINT_RIGHT_ARM_FOREARM",
    "JOINT_RIGHT_SHOULDER_ARM",
    "JOINT_SPINE3_RIGHT_SHOULDER",
    "JOINT_SPINE2_SPINE3",
    "JOINT_SPINE1_SPINE2",
    "JOINT_SPINE_SPINE1",
    "JOINT_HIPS_SPINE",
    "JOINT_LEFT_FOOT_TOE_BASE",
    "JOINT_LEFT_LEG_FOOT",
    "JOINT_LEFT_UPLEG_LEG",
    "JOINT_HIPS_LEFT_LEG",
    "JOINT_RIGHT_FOOT_TOE_BASE",
    "JOINT_RIGHT_LEG_FOOT",
    "JOINT_RIGHT_UPLEG_LEG",
    "JOINT_HIPS_RIGHT_LEG"
}

return t1
