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
local BodyId = import("skate_core/physics/board").BodyId
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime
local v2 = import("skate_core/physics/skeleton_animation_record")
local SkeletonBoardFrames = import("skate_core/physics/skeleton_board_frames").SkeletonBoardFrames
local SkateboardOffset = import("skate_core/physics/skeleton_board_offset").SkateboardOffset
local LandingAdjustment = import("skate_core/physics/skeleton_landing").LandingAdjustment
local v3 = import("skate_core/physics/skeleton_landing_on_board")
local SkeletonMotion = import("skate_core/physics/skeleton_motion").SkeletonMotion
local SkeletonRootFrames = import("skate_core/physics/skeleton_root").SkeletonRootFrames
local Collections = import("skate_data/collections").Collections
local v4 = import("skate_data/physics_skeleton")
local IDENTITY, SkeletonAnimationMasses, SkeletonAnimationRecord, compose_affine = v2.IDENTITY, v2.SkeletonAnimationMasses, v2.SkeletonAnimationRecord, v2.compose_affine
local map_animation_parts, physics_bone_frame = v2.map_animation_parts, v2.physics_bone_frame
local PhysicsSkeleton, PhysicsBone = v4.PhysicsSkeleton, v4.PhysicsBone
local t1 = {}
local v5 = BoardRuntime.transform_scratch()
local v6

local function map_animation_parts_scratch(p2, p3, p4) -- line: 57
    -- upvalues: rt (copy), IDENTITY (copy), v6 (ref)
    local v7 = #p2

    for i = 1, 24 do
        if v7 <= p3[i] then
            error("physics skeleton bone index is outside the animation hierarchy", 0)
        end
    end

    local v8 = v6

    if v8 == nil then
        v8 = rt.filled(24, IDENTITY)
        v6 = v8
    end

    for i = 1, 24 do
        local v9 = p2[p3[i] + 1]
        local v10 = p4[i]
        local v11 = v9[1]
        local v12 = v9[2]
        local v13 = v9[3]
        local v14 = v9[4]
        local v15 = v11[1]
        local v16 = v11[2]
        local v17 = v11[3]
        local v18 = v11[4]
        local v19 = v12[1]
        local v20 = v12[2]
        local v21 = v12[3]
        local v22 = v12[4]
        local v23 = v13[1]
        local v24 = v13[2]
        local v25 = v13[3]
        local v26 = v13[4]
        local v27 = v8[i]
        local v28 = v10[1]
        local v29 = v28[1]
        local v30 = v28[2]
        local v31 = v28[3]
        local v32 = v27[1]
        local v33 = v31 * v23 + (v30 * v19 + v29 * v15)
        local v34 = v31 * v24 + (v30 * v20 + v29 * v16)
        local v35 = v31 * v25 + (v30 * v21 + v29 * v17)
        local v36 = v31 * v26 + (v30 * v22 + v29 * v18)

        v32[1] = v33
        v32[2] = v34
        v32[3] = v35
        v32[4] = v36

        local v37 = v10[2]
        local v38 = v37[1]
        local v39 = v37[2]
        local v40 = v37[3]
        local v41 = v27[2]
        local v42 = v40 * v23 + (v39 * v19 + v38 * v15)
        local v43 = v40 * v24 + (v39 * v20 + v38 * v16)
        local v44 = v40 * v25 + (v39 * v21 + v38 * v17)
        local v45 = v40 * v26 + (v39 * v22 + v38 * v18)

        v41[1] = v42
        v41[2] = v43
        v41[3] = v44
        v41[4] = v45

        local v46 = v10[3]
        local v47 = v46[1]
        local v48 = v46[2]
        local v49 = v46[3]
        local v50 = v27[3]
        local v51 = v49 * v23 + (v48 * v19 + v47 * v15)
        local v52 = v49 * v24 + (v48 * v20 + v47 * v16)
        local v53 = v49 * v25 + (v48 * v21 + v47 * v17)
        local v54 = v49 * v26 + (v48 * v22 + v47 * v18)

        v50[1] = v51
        v50[2] = v52
        v50[3] = v53
        v50[4] = v54

        local v55 = v10[4]
        local v56 = v55[1]
        local v57 = v55[2]
        local v58 = v55[3]
        local v59 = v27[4]
        local v60 = v23 * v58 + (v19 * v57 + (v15 * v56 + v14[1]))
        local v61 = v24 * v58 + (v20 * v57 + (v16 * v56 + v14[2]))
        local v62 = v25 * v58 + (v21 * v57 + (v17 * v56 + v14[3]))
        local v63 = v26 * v58 + (v22 * v57 + (v18 * v56 + v14[4]))

        v59[1] = v60
        v59[2] = v61
        v59[3] = v62
        v59[4] = v63
    end

    return v8
end

t1.map_animation_parts_scratch = map_animation_parts_scratch

local load_landing_settings

t1.AnimatedSkeleton = {}

function t1.AnimatedSkeleton.reparented_hand_indices(p5) -- line: 118
    return {
        p5.target_bones[3],
        p5.target_bones[4]
    }
end

function t1.AnimatedSkeleton.load(p6, p7, p8, p9) -- line: 124
    -- upvalues: rt (copy), v1 (copy), Vector3 (copy), SkeletonBoardFrames (copy), SkateboardOffset (copy), LandingAdjustment (copy), SkeletonMotion (copy), SkeletonRootFrames (copy), Collections (copy), IDENTITY (copy), SkeletonAnimationMasses (copy), SkeletonAnimationRecord (copy), physics_bone_frame (copy), PhysicsSkeleton (copy), PhysicsBone (copy), load_landing_settings (ref)
    local v64 = if type(p6) == "string" then p6 .. "/private/stock/physics-skeletons.json" else p6
    local PHYS_TPOSE = PhysicsSkeleton.load(v64, p8.source_sha256, "PHYS_TPOSE")

    if #PHYS_TPOSE.bones ~= 24 then
        error("Stock skater physics skeleton must contain24 parts", 0)
    end

    local function lookup(p10) -- line: 133
        -- upvalues: p8 (copy)
        local v65 = string.lower(p10)

        for v66, v67 in p8.bone_names do
            if string.lower(v67) == v65 then
                return v66 - 1
            end
        end

        error(string.format("Stock physics bone %s is absent from the animation hierarchy", p10), 0)
    end

    local v68 = table.create(24, 0)
    local v69 = rt.filled(24, IDENTITY)
    local v70 = rt.filled(24, Vector3.ZERO)
    local v71 = table.create(24, 0)

    for v72, v73 in PHYS_TPOSE.bones do
        local v74 = v72 - 1

        v68[v74 + 1] = lookup(v73.name)
        buffer.writeu32(v1, 0, v73.words[17])

        local v76 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v73.words[18])

        local v78 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v73.words[19])

        local v80 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v73.words[20])

        local t2 = {
            v76,
            v78,
            v80,
            (buffer.readf32(v1, 0))
        }

        v69[v74 + 1] = physics_bone_frame(PhysicsBone.rotation(v73), t2)

        local v82 = PhysicsBone.size(v73)

        v70[v74 + 1] = Vector3.new(v82[1], v82[2], v82[3])
        v71[v74 + 1] = Collections.words(p7, 6, "physics_skeleton_bones", "default", "PART_" .. v73.name)[4]
    end

    local v83 = table.create(4, 0)

    for v84, v85 in { "LeftToeBase_Reparented", "RightToeBase_Reparented", "LeftHand_Reparented", "RightHand_Reparented" } do
        v83[v84] = lookup(v85)
    end

    local t3 = {
        record = SkeletonAnimationRecord.default(),
        roots = SkeletonRootFrames.default(),
        board_frames = SkeletonBoardFrames.default(),
        board_offset = SkateboardOffset.default(),
        landing = LandingAdjustment.default(),
        targets = rt.filled(4, IDENTITY),
        masses = SkeletonAnimationMasses.from_bone_data(v70, v71, p9),
        bone_indices = v68,
        physics_frames = v69,
        animation_board = rt.copy(IDENTITY),
        unadjusted_board = rt.copy(IDENTITY)
    }
    local v86 = rt.map(Collections.words(p7, 20, "physics_animation", "default", "LandingOnDeckBLendVsTime"), rt.from_bits)

    t3.landing_on_board_blend = {
        x = rt.slice(v86, 4, 12),
        y = rt.slice(v86, 12, 20)
    }
    t3.animation_hips = rt.copy(IDENTITY)
    t3.motion = SkeletonMotion.default()
    t3.board_at_y_delta = 0
    t3.target_bones = v83
    t3.landing_settings = load_landing_settings(p7)

    return t3
end

function t1.AnimatedSkeleton.process_pose_reference(p11, p12, p13, p14, p15, p16, p17) -- line: 212
    -- upvalues: rt (copy), SkateboardOffset (copy), LandingAdjustment (copy), v3 (copy), SkeletonMotion (copy), SkeletonAnimationRecord (copy), compose_affine (copy), map_animation_parts (copy)
    local v87 = p12[1]

    if v87 == nil then
        error("Animation has no trajectory bone", 0)
    end

    SkeletonMotion.process_trajectory(p11.motion, v87, p11.roots.animation_to_world, p14)

    local v88 = map_animation_parts(p12, p11.bone_indices, p11.physics_frames)

    p11.unadjusted_board = rt.copy(v88[1])

    local v89 = SkeletonMotion.publish_unadjusted_board(v88[1], p16)

    for v90, v91 in { 15, 19, 3, 7 } do
        local v92 = v90 - 1
        local v93 = p12[p11.target_bones[v92 + 1] + 1]

        if v93 == nil then
            error("Missing animation IK target bone", 0)
        end

        p11.targets[v92 + 1] = compose_affine(v93, p11.physics_frames[v91 + 1])
    end

    p13.animation_com_height = p11.record.centre_of_mass[2] - v88[1][4][2]

    if p17 ~= nil then
        local v94 = p17[1]
        local v95 = p17[2]
        local v96 = p17[3]
        local v97 = p17[4]
        local v98 = v3.pose_adjustment(p11.roots.world_to_animation, v94, v88[1], v95, p11.board_frames.com_velocity[2], v96, v97, p11.landing_on_board_blend)

        if v98 ~= nil then
            SkateboardOffset.refresh_transform(p11.board_offset, v98)
        end
    end

    LandingAdjustment.update(p11.landing, p13, p11.landing_settings, p11.board_offset)
    SkateboardOffset.update(p11.board_offset, v88[1], p11.targets)
    SkeletonAnimationRecord.update(p11.record, v88, p11.roots.animation_to_board, p11.masses)
    p11.animation_board = rt.copy(v88[1])
    p11.animation_hips = rt.copy(v88[24])

    local v99, v100 = SkeletonMotion.publish_adjusted_board(p11.motion, v88[1], p15)

    p11.board_at_y_delta = v99

    return v100, v89
end

function t1.AnimatedSkeleton.process_pose(p18, p19, p20, p21, p22, p23, p24) -- line: 277
    -- upvalues: rt (copy), SkateboardOffset (copy), LandingAdjustment (copy), v3 (copy), SkeletonMotion (copy), SkeletonAnimationRecord (copy), compose_affine (copy), map_animation_parts_scratch (copy)
    local v101 = p19[1]

    if v101 == nil then
        error("Animation has no trajectory bone", 0)
    end

    SkeletonMotion.process_trajectory(p18.motion, v101, p18.roots.animation_to_world, p21)

    local v102 = map_animation_parts_scratch(p19, p18.bone_indices, p18.physics_frames)

    p18.unadjusted_board = rt.copy(v102[1])

    local v103 = SkeletonMotion.publish_unadjusted_board(v102[1], p23)

    for v104, v105 in { 15, 19, 3, 7 } do
        local v106 = v104 - 1
        local v107 = p19[p18.target_bones[v106 + 1] + 1]

        if v107 == nil then
            error("Missing animation IK target bone", 0)
        end

        p18.targets[v106 + 1] = compose_affine(v107, p18.physics_frames[v105 + 1])
    end

    p20.animation_com_height = p18.record.centre_of_mass[2] - v102[1][4][2]

    if p24 ~= nil then
        local v108 = p24[1]
        local v109 = p24[2]
        local v110 = p24[3]
        local v111 = p24[4]
        local v112 = v3.pose_adjustment(p18.roots.world_to_animation, v108, v102[1], v109, p18.board_frames.com_velocity[2], v110, v111, p18.landing_on_board_blend)

        if v112 ~= nil then
            SkateboardOffset.refresh_transform(p18.board_offset, v112)
        end
    end

    LandingAdjustment.update(p18.landing, p20, p18.landing_settings, p18.board_offset)
    SkateboardOffset.update(p18.board_offset, v102[1], p18.targets)
    SkeletonAnimationRecord.update(p18.record, v102, p18.roots.animation_to_board, p18.masses)
    p18.animation_board = rt.copy(v102[1])
    p18.animation_hips = rt.copy(v102[24])

    local v113, v114 = SkeletonMotion.publish_adjusted_board(p18.motion, v102[1], p22)

    p18.board_at_y_delta = v113

    return v114, v103
end

function t1.AnimatedSkeleton.update_roots(p25, p26, p27, p28) -- line: 337
    -- upvalues: rt (copy), BodyId (copy), BoardRuntime (copy), SkeletonRootFrames (copy), IDENTITY (copy), v5 (copy)
    local v115 = BoardRuntime.part_transform_into(p26, BodyId.index(BodyId.Deck), v5)
    local linear_velocity = BoardRuntime.bodies(p26)[BodyId.index(BodyId.Deck) + 1].rates.linear_velocity
    local v116 = rt.copy(IDENTITY)

    for v117, v118 in v115.basis.columns do
        local v119 = v117 - 1

        v116[v119 + 1][1] = v118[1]
        v116[v119 + 1][2] = v118[2]
        v116[v119 + 1][3] = v118[3]
    end

    v116[4] = {
        v115.translation.x,
        v115.translation.y,
        v115.translation.z,
        0
    }
    SkeletonRootFrames.update(p25.roots, v116, {
        linear_velocity.x,
        linear_velocity.y,
        linear_velocity.z,
        0
    }, p28, p25.animation_board, p27)
end

function t1.AnimatedSkeleton.prepare_ground(p29, p30, p31, p32, p33) -- line: 374
    -- upvalues: rt (copy), SkeletonBoardFrames (copy), t1 (copy)
    p29.roots.initialize_heading = true
    t1.AnimatedSkeleton.update_roots(p29, p30, p31, p32)

    local v120, v121 = SkeletonBoardFrames.prepare_ground(p29.board_frames, p29.roots, p29.record.pose[1], rt.copy(p29.roots.board), p33)

    return v120, v121
end

function t1.AnimatedSkeleton.finish_ground(p34) -- line: 389
    -- upvalues: rt (copy), IDENTITY (copy)
    p34.motion.next_trajectory = rt.copy(IDENTITY)
end

function load_landing_settings(p35) -- line: 394
    -- upvalues: rt (copy), Collections (copy)
    local function value(p36) -- line: 395
        -- upvalues: p35 (copy), Collections (copy)
        return Collections.float(p35, "physics_animation", "default", p36)
    end

    local function graph(p37) -- line: 398
        -- upvalues: p35 (copy), rt (copy), Collections (copy)
        local v122 = rt.map(Collections.words(p35, 12, "physics_animation", "default", p37), rt.from_bits)

        return {
            x = rt.slice(v122, 4, 8),
            y = rt.slice(v122, 8, 12)
        }
    end

    return {
        manual_blend = graph("LandingAdjustManualBlend"),
        grind_blend = graph("LandingAdjustGrindBlend"),
        coffin_height = graph("LandingAdjustCoffinBounceHeight"),
        minimum_height = Collections.float(p35, "physics_animation", "default", "LandingAdjustMinYPos"),
        maximum_velocity = Collections.float(p35, "physics_animation", "default", "LandingAdjustMaxVel"),
        manual_damping = Collections.float(p35, "physics_animation", "default", "LandingAdjustManualK2"),
        manual_spring = Collections.float(p35, "physics_animation", "default", "LandingAdjustManualK1"),
        ground_minimum_compression_time = Collections.float(p35, "physics_animation", "default", "LandingAdjustGroundMinCompressionTime"),
        ground_damping = Collections.float(p35, "physics_animation", "default", "LandingAdjustGroundK2"),
        ground_spring = Collections.float(p35, "physics_animation", "default", "LandingAdjustGroundK1"),
        grind_animation_target_time = Collections.float(p35, "physics_animation", "default", "LandingAdjustGrindStartUsingAnimTargetAfterTime"),
        grind_damping = Collections.float(p35, "physics_animation", "default", "LandingAdjustGrindK2"),
        grind_spring = Collections.float(p35, "physics_animation", "default", "LandingAdjustGrindK1"),
        grind_target_delta = Collections.float(p35, "physics_animation", "default", "LandingAdjustGrindBlendTowardsAnimTargetSpeed"),
        desired_com_height = Collections.float(p35, "physics_animation", "default", "LandingAdjustDesiredCom"),
        coffin_time = Collections.float(p35, "physics_animation", "default", "LandingAdjustCoffinBounceTime"),
        coffin_maximum_velocity = Collections.float(p35, "physics_animation", "default", "LandingAdjustCoffinBounceMaxVel"),
        coffin_blend_frames = Collections.float(p35, "physics_animation", "default", "LandingAdjustCoffinBounceFramesToBlendAway"),
        coffin_base_height = Collections.float(p35, "physics_animation", "default", "LandingAdjustCoffinBounceBaseHeight")
    }
end

t1.load_landing_settings = load_landing_settings

return t1
