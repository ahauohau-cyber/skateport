-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local BodyId = import("skate_core/physics/board").BodyId
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime
local v1 = import("skate_core/physics/skeleton_animation_record")
local IDENTITY, map_animation_parts = v1.IDENTITY, v1.map_animation_parts
local v2 = import("skate_core/physics/skeleton_body")
local SkeletonTargets, SkeletonPoseErrors = v2.SkeletonTargets, v2.SkeletonPoseErrors
local SkeletonRootFrames = import("skate_core/physics/skeleton_root").SkeletonRootFrames
local SkeletonBoardFrames = import("skate_core/physics/skeleton_board_frames").SkeletonBoardFrames
local CentreOfMassFilter = import("skate_core/physics/centre_of_mass_filter").CentreOfMassFilter
local SkateboardController = import("skate_core/physics/skateboard_controller").SkateboardController
local AnimationBanks = import("skate_data/animation_banks").AnimationBanks

local function landing_quality_core() -- line: 29
    -- upvalues: import (copy)
    return import("skate_core/animation/landing_quality")
end

local function air_state_core() -- line: 32
    -- upvalues: import (copy)
    return import("skate_core/air/state")
end

local function board_possession_manager_core() -- line: 35
    -- upvalues: import (copy)
    return import("skate_core/player/offboard/board_possession/manager")
end

local function skeleton_body() -- line: 40
    -- upvalues: import (copy)
    return import("skate_game/physics/skeleton_body")
end

local function animated_skeleton() -- line: 43
    -- upvalues: import (copy)
    return import("skate_game/physics/animated_skeleton")
end

local function animation_feedback() -- line: 46
    -- upvalues: import (copy)
    return import("skate_game/physics/animation_feedback")
end

local function animation_input() -- line: 49
    -- upvalues: import (copy)
    return import("skate_game/physics/animation_input")
end

local function animation_phase() -- line: 52
    -- upvalues: import (copy)
    return import("skate_game/physics/animation_phase")
end

local function foot_ik() -- line: 55
    -- upvalues: import (copy)
    return import("skate_game/physics/foot_ik")
end

local function foot_physical_output() -- line: 58
    -- upvalues: import (copy)
    return import("skate_game/physics/foot_physical_output")
end

local function ground_runtime() -- line: 61
    -- upvalues: import (copy)
    return import("skate_game/physics/ground_runtime")
end

local function ground_phase() -- line: 64
    -- upvalues: import (copy)
    return import("skate_game/physics/ground_phase")
end

local function ground_animation() -- line: 67
    -- upvalues: import (copy)
    return import("skate_game/physics/ground_animation")
end

local function player_input() -- line: 70
    -- upvalues: import (copy)
    return import("skate_game/physics/player_input")
end

local function player_state() -- line: 73
    -- upvalues: import (copy)
    return import("skate_game/physics/player_state")
end

local function skeleton_input_runtime() -- line: 76
    -- upvalues: import (copy)
    return import("skate_game/physics/skeleton_input_runtime")
end

local function skeleton_output() -- line: 79
    -- upvalues: import (copy)
    return import("skate_game/physics/skeleton_output")
end

local function skeleton_air() -- line: 82
    -- upvalues: import (copy)
    return import("skate_game/physics/skeleton_air")
end

local function air_reckoning() -- line: 85
    -- upvalues: import (copy)
    return import("skate_game/physics/air_reckoning")
end

local function air_phase() -- line: 88
    -- upvalues: import (copy)
    return import("skate_game/physics/air_phase")
end

local function air_trajectory() -- line: 91
    -- upvalues: import (copy)
    return import("skate_game/physics/air_trajectory")
end

local function known_air() -- line: 94
    -- upvalues: import (copy)
    return import("skate_game/physics/known_air")
end

local function biped_air() -- line: 97
    -- upvalues: import (copy)
    return import("skate_game/physics/biped_air")
end

local function biped_ground() -- line: 100
    -- upvalues: import (copy)
    return import("skate_game/physics/biped_ground")
end

local function grab_runtime() -- line: 103
    -- upvalues: import (copy)
    return import("skate_game/physics/biped_ground/grab_runtime")
end

local function landing_on_deck() -- line: 106
    -- upvalues: import (copy)
    return import("skate_game/physics/landing_on_deck")
end

local function landing_quality() -- line: 109
    -- upvalues: import (copy)
    return import("skate_game/physics/landing_quality")
end

local function landing_deck() -- line: 112
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/landing_deck")
end

local function contact_toolkit() -- line: 115
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/contact_toolkit")
end

local function air_selector() -- line: 118
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/air_selector")
end

local function board_manager() -- line: 121
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/board_manager")
end

local function board_manager_runtime() -- line: 124
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/board_manager/runtime")
end

local function grind_trick() -- line: 127
    -- upvalues: import (copy)
    return import("skate_game/physics/grind_trick")
end

local function grind_camera() -- line: 130
    -- upvalues: import (copy)
    return import("skate_game/physics/grind_camera")
end

local function grind() -- line: 133
    -- upvalues: import (copy)
    return import("skate_game/physics/grind")
end

local function revert_state() -- line: 136
    -- upvalues: import (copy)
    return import("skate_game/physics/revert_state")
end

local function slide_state() -- line: 139
    -- upvalues: import (copy)
    return import("skate_game/physics/slide_state")
end

local function footplant() -- line: 142
    -- upvalues: import (copy)
    return import("skate_game/physics/footplant")
end

local function boneless() -- line: 145
    -- upvalues: import (copy)
    return import("skate_game/physics/boneless")
end

local function handplant() -- line: 148
    -- upvalues: import (copy)
    return import("skate_game/physics/handplant")
end

local function wipeout() -- line: 151
    -- upvalues: import (copy)
    return import("skate_game/physics/wipeout")
end

local function wipeout_states() -- line: 154
    -- upvalues: import (copy)
    return import("skate_game/physics/wipeout_states")
end

local function respawn() -- line: 157
    -- upvalues: import (copy)
    return import("skate_game/physics/respawn")
end

local function teleport_state() -- line: 160
    -- upvalues: import (copy)
    return import("skate_game/physics/teleport_state")
end

local function climbing() -- line: 163
    -- upvalues: import (copy)
    return import("skate_game/physics/climbing")
end

local function scoring_runtime() -- line: 166
    -- upvalues: import (copy)
    return import("skate_game/scoring_runtime")
end

local function skater_animation() -- line: 169
    -- upvalues: import (copy)
    return import("skate_game/skater_animation")
end

local function custom_difficulty() -- line: 172
    -- upvalues: import (copy)
    return import("skate_game/custom_difficulty")
end

local function player_physics_mod() -- line: 175
    -- upvalues: import (copy)
    return import("skate_game/modding/player_physics")
end

local function files() -- line: 179
    -- upvalues: import (copy)
    return import("skate_data/files")
end

local t1 = {
    SkaterRuntime = {}
}

function t1.SkaterRuntime.reload_difficulty(p1, p2) -- line: 260
    -- upvalues: rt (copy), import (copy)
    local GroundProfiles, GroundState = import("skate_game/physics/ground_runtime").GroundProfiles, import("skate_game/physics/ground_runtime").GroundState
    local AnimationInput = import("skate_game/physics/animation_input").AnimationInput
    local v3 = GroundProfiles.load(p2)
    local v4 = GroundProfiles.select(v3, p1.player_input.processed.state_variant_index_2528, (math.clamp(p1.player_input.processed.surface_mode_2540, 1, 5)))
    local v5 = GroundState.load(p2, "test", true)
    local v6 = import("skate_game/physics/air_phase").AirSettings.load(p2)
    local v7 = import("skate_game/physics/air_reckoning").AirReckoning.load(p2)
    local v8 = import("skate_game/physics/known_air").KnownAir.load(p2)
    local v9 = import("skate_game/physics/wipeout").Wipeout.load(p2)
    local v10 = import("skate_game/physics/grind").Runtime.load(p2)
    local v11 = import("skate_game/physics/ground_animation").GroundAnimationSettings.load(p2)
    local test = AnimationInput.load(p2, p1.animation.evaluator.frames, "test")
    local v12 = import("skate_game/physics/player_input").PlayerInputRuntime.load(p2)

    p1.ground_profiles = v3
    p1.ground_settings = v4
    GroundState.adopt_mode_settings(p1.ground, v5)
    p1.air_settings = v6
    import("skate_game/physics/air_reckoning").AirReckoning.adopt_mode_settings(p1.air_reckoning, v7)
    import("skate_game/physics/known_air").KnownAir.adopt_mode_settings(p1.known_air, v8)
    import("skate_game/physics/wipeout").Wipeout.adopt_mode_settings(p1.wipeout, v9)
    import("skate_game/physics/grind").Runtime.adopt_mode_settings(p1.grind, v10)
    p1.ground_animation_settings = v11
    AnimationInput.adopt_mode_settings(p1.animation_input, test)
    p1.player_input.player.state_variants_1408 = rt.copy(v12.player.state_variants_1408)
end

function t1.SkaterRuntime.travel_to(p3, p4) -- line: 293
    -- upvalues: t1 (copy)
    return t1.SkaterRuntime.travel(p3, p4, nil)
end

function t1.SkaterRuntime.travel(p5, p6, p7) -- line: 298
    -- upvalues: rt (copy), import (copy)
    import("skate_game/physics/player_input").PlayerInputRuntime.request_teleport_ex(p5.player_input, rt.copy(p6), rt.copy(p7))
    import("skate_game/physics/teleport_state").Runtime.request_manual(p5.teleport_state, rt.copy(p6), true)
end

function t1.SkaterRuntime.load(p8, p9, p10, p11) -- line: 304
    -- upvalues: t1 (copy)
    return t1.SkaterRuntime.load_for_world(p8, p9, p10, p11, nil)
end

function t1.SkaterRuntime.load_for_world(p12, p13, p14, p15, p16) -- line: 310
    -- upvalues: rt (copy), import (copy), BodyId (copy), BoardRuntime (copy), IDENTITY (copy), map_animation_parts (copy), SkeletonTargets (copy), SkeletonPoseErrors (copy), SkeletonRootFrames (copy), SkeletonBoardFrames (copy), CentreOfMassFilter (copy), SkateboardController (copy), AnimationBanks (copy)
    local SkaterAnimation = import("skate_game/skater_animation").SkaterAnimation
    local AnimatedSkeleton = import("skate_game/physics/animated_skeleton").AnimatedSkeleton
    local AnimationInput = import("skate_game/physics/animation_input").AnimationInput
    local v13 = import("skate_game/custom_difficulty").load_collections(p12, import("skate_data/files").read("../settings/custom-difficulty.json"))
    local v14 = AnimationBanks.load(p12)
    local v15 = AnimationBanks.metadata(v14)
    local v16 = if p16 == nil then SkaterAnimation.load(p12, v13, p13, "", import("skate_data/files").read("private/custom/crouch-treflip.json")) else SkaterAnimation.from_source(v13, p13, "", p16)
    local v17 = SkaterAnimation.evaluate_initial_pose(v16)
    local v18 = AnimatedSkeleton.load(p12, v13, v16.evaluator.frames, false)
    local v19 = map_animation_parts(v17, v18.bone_indices, v18.physics_frames)
    local v20 = BoardRuntime.part_transforms(p14.board)[BodyId.index(BodyId.Deck) + 1]
    local v21 = rt.copy(IDENTITY)

    for i = 0, #v20.basis.columns - 1 do
        local v22 = v20.basis.columns[i + 1]

        v21[i + 1][1] = v22[1]
        v21[i + 1][2] = v22[2]
        v21[i + 1][3] = v22[3]
    end

    v21[4] = {
        v20.translation.x,
        v20.translation.y,
        v20.translation.z,
        0
    }

    local v23 = import("skate_game/physics/skeleton_body").load(p12, v13, v16.evaluator.frames.source_sha256, v19, rt.copy(v21), rt.copy(p14.settings.step.simulation), nil)

    SkeletonRootFrames.reset_initial_alignment(v18.roots, rt.copy(v23.animation_to_world))
    SkeletonBoardFrames.reset(v18.board_frames, rt.copy(v21))

    for _ = 0, 1 do
        SkeletonBoardFrames.publish_centre_of_mass(v18.board_frames, rt.copy(v23.record.centre_of_mass), p14.settings.step.simulation.time_step, 0)
    end

    SkeletonBoardFrames.publish_local_observations(v18.board_frames, v18.roots, v21)

    local v24 = AnimationInput.load(v13, v16.evaluator.frames, p15)
    local v25 = import("skate_game/physics/skeleton_body").load_joints(p12, v13, v16.evaluator.frames.source_sha256, v17, v16.evaluator.frames.parents, v18.bone_indices)
    local v26 = import("skate_game/physics/skeleton_body").load_drives(p12, v13, v16.evaluator.frames.source_sha256, v17, v18.bone_indices, v19, v25, rt.copy(v23.animation_to_world), rt.copy(v21), rt.copy(p14.settings.step.simulation))
    local v27 = SkeletonTargets.update_extra_targets(v26.targets, v23, v18.board_frames.com_frame, v18.board_frames.lifted_com_frame)
    local v28 = import("skate_game/physics/foot_ik").FootIk.load(v13, v16.evaluator.frames, v18)
    local v29 = import("skate_game/physics/skeleton_output").SkeletonOutput.load(v13, v16.evaluator.frames, v18)
    local v30 = import("skate_game/physics/skeleton_body").load_collision(p12, v13, v16.evaluator.frames.source_sha256, false)
    local v31 = import("skate_game/physics/wipeout_states").WipeoutState.load(v13, p12, v16.evaluator.frames.source_sha256)
    local v32 = import("skate_game/physics/respawn").Runtime.load(v13, rt.copy(v21), SkaterAnimation.checkpoint_stance(v16))
    local v33 = import("skate_game/physics/air_trajectory").AirTrajectoryRuntime.load(v13)

    import("skate_game/physics/air_trajectory").AirTrajectoryRuntime.bind_grind_world(v33, p14.grind_world)

    local v34 = import("skate_game/physics/skeleton_input_runtime").SkeletonInputRuntime.load(v13)

    v34.drive_frames = v19
    v34.extra_target_positions = {
        rt.copy(v27.com),
        rt.copy(v27.lifted_com),
        rt.copy(v27.following_com)
    }

    local t2 = {
        respawn = v32,
        scoring = import("skate_game/scoring_runtime").Runtime.load(v13),
        climbing = import("skate_game/physics/climbing").Runtime.load(p12, v16.evaluator.frames.bone_names, import("skate_data/files").read("private/custom/climbing.json")),
        render_pose = v17,
        pose_generation = 0,
        centre_of_mass_filter = CentreOfMassFilter.default(),
        centre_of_mass_output = {
            velocity = { 0, 0, 0, 0 },
            acceleration = { 0, 0, 0, 0 },
            position = { 0, 0, 0, 0 }
        },
        animation = v16,
        landing_quality = import("skate_core/animation/landing_quality").Output.default(),
        landing_quality_settings = import("skate_game/physics/landing_quality").load(v13),
        animated_skeleton = v18,
        skeleton_air = import("skate_game/physics/skeleton_air").SkeletonAir.load(v13),
        air_reckoning = import("skate_game/physics/air_reckoning").AirReckoning.load(v13),
        air_state = import("skate_core/air/state").PhysicsAirState.default(),
        air_settings = import("skate_game/physics/air_phase").AirSettings.load(v13),
        known_air = import("skate_game/physics/known_air").KnownAir.load(v13),
        biped_air = import("skate_game/physics/biped_air").BipedAir.load(v13),
        landing_on_deck = import("skate_game/physics/landing_on_deck").Runtime.load(v13),
        landing_deck = import("skate_game/physics/offboard/landing_deck").Owner.load(v13),
        grind_trick = import("skate_game/physics/grind_trick").GrindTrick.default(),
        ground_animation = import("skate_game/physics/ground_animation").GroundAnimationRuntime.default(),
        ground_animation_settings = import("skate_game/physics/ground_animation").GroundAnimationSettings.load(v13),
        revert_state = import("skate_game/physics/revert_state").RevertState.load(v13),
        slide_state = import("skate_game/physics/slide_state").SlideState.load(v13),
        trajectory = v33,
        grind_camera = import("skate_game/physics/grind_camera").GrindCamera.default(),
        grind = import("skate_game/physics/grind").Runtime.load(v13),
        footplant = import("skate_game/physics/footplant").Footplant.load(v13),
        boneless = import("skate_game/physics/boneless").Boneless.load(v13),
        handplant = import("skate_game/physics/handplant").Handplant.load(v13),
        wipeout = import("skate_game/physics/wipeout").Wipeout.load(v13),
        wipeout_state = v31,
        teleport_state = import("skate_game/physics/teleport_state").Runtime.new({
            on_board = true,
            transform = rt.copy(v21)
        }),
        skeleton = v23,
        skeleton_joints = v25,
        mod_joint_overrides = {},
        mod_contact_frame = import("skate_game/modding/player_physics").ContactFrame.default(),
        mod_part_overrides = {},
        skeleton_drives = v26,
        collision_feedback = import("skate_game/physics/skeleton_body").load_feedback(v13, rt.copy(v30.settings)),
        skeleton_collision = v30
    }
    local v35 = SkeletonPoseErrors.default()

    v35.targets = {
        rt.copy(v27.com),
        rt.copy(v27.lifted_com),
        rt.copy(v27.following_com)
    }
    t2.pose_errors = v35
    t2.collision_pose_error = { 0, 0, 0, 0 }
    t2.collision_extra_errors = {
        { 0, 0, 0, 0 },
        { 0, 0, 0, 0 }
    }
    t2.collision_maximum_error = nil
    t2.solved_drives = nil
    t2.foot_ik = v28
    t2.foot_physical = import("skate_game/physics/foot_physical_output").FootPhysicalOutputs.load(v13)
    t2.player_input = import("skate_game/physics/player_input").PlayerInputRuntime.load(v13)
    t2.player_state = import("skate_game/physics/player_state").PlayerState.load(v13, p15)
    t2.skeleton_input = v34
    t2.ground = import("skate_game/physics/ground_runtime").GroundState.load(v13, p15, true)
    t2.ground_runtime = import("skate_game/physics/ground_runtime").GroundRuntime.load(v13)
    t2.ground_profiles = import("skate_game/physics/ground_runtime").GroundProfiles.load(v13)
    t2.ground_settings = import("skate_game/physics/ground_runtime").GroundSettings.load(v13, p15, "smooth")
    t2.ground_lifecycle = import("skate_game/physics/ground_phase").GroundLifecycle.new()
    t2.biped_ground = import("skate_game/physics/biped_ground").Owner.load(v13, v15)
    t2.offboard_contact = import("skate_game/physics/offboard/contact_toolkit").Owner.default()
    t2.offboard_air_selector = import("skate_game/physics/offboard/air_selector").AirSelector.new(import("skate_game/physics/offboard/air_selector").Settings.load(v13))
    t2.offboard_feet = import("skate_core/player/offboard/board_possession/manager").State.default()
    t2.offboard_grab = import("skate_game/physics/biped_ground/grab_runtime").Owner.default()
    t2.animation_input = v24
    t2.animation_feedback = import("skate_game/physics/animation_feedback").AnimationFeedback.load(v13)
    t2.physical_feedback = import("skate_game/physics/animation_phase").initial_feedback()
    t2.skeleton_output = v29
    t2.skateboard_controller = SkateboardController.new()
    t2.board_possession = import("skate_game/physics/offboard/board_manager").Owner.load(v13)
    t2.board_possession_live = import("skate_game/physics/offboard/board_manager/runtime").LiveState.load(v13, p14)

    return t2
end

return t1
