-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/drive_parameters")
local v2 = import("skate_core/physics/skeleton_body")
local v3 = import("skate_core/physics/skeleton_general")
local RetailDriveType = v1.RetailDriveType
local SkeletonBody, SkeletonDrives, SkeletonPoseErrors, SkeletonTargets = v2.SkeletonBody, v2.SkeletonDrives, v2.SkeletonPoseErrors, v2.SkeletonTargets

local function animated_skeleton() -- line: 25
    -- upvalues: import (copy)
    return import("skate_game/physics/animated_skeleton")
end

local function foot_ik() -- line: 28
    -- upvalues: import (copy)
    return import("skate_game/physics/foot_ik")
end

local t1 = {
    SkeletonInputRuntime = {}
}
local SkeletonInputRuntime = t1.SkeletonInputRuntime

local function i32_as_usize(p1) -- line: 40
    if p1 < 0 then
        return p1 + 18446744073709552000
    end

    return p1
end

function t1.SkeletonInputRuntime.update_ground(p2, p3, p4, p5, p6, p7, p8, p9) -- line: 49
    -- upvalues: import (copy), SkeletonInputRuntime (copy)
    local v4, v5 = import("skate_game/physics/animated_skeleton").AnimatedSkeleton.prepare_ground(p6.animated, p3, p4, p5.timestep_2604, p5.flags_2468)

    p5.flags_2468 = v5
    SkeletonInputRuntime.general_update(p2, p5, p6, p7, p8, p9)
    import("skate_game/physics/animated_skeleton").AnimatedSkeleton.finish_ground(p6.animated)
    p6.animation_input.fields.flags2468 = p5.flags_2468

    return v4
end

function t1.SkeletonInputRuntime.general_update(p10, p11, p12, p13, p14, p15) -- line: 70
    -- upvalues: rt (copy), import (copy), v3 (copy), SkeletonBody (copy), SkeletonDrives (copy), SkeletonPoseErrors (copy), SkeletonTargets (copy), SkeletonInputRuntime (copy)
    p10.root_velocity = v3.root_velocity(p10.previous_root_position, rt.copy(p12.animated.roots.animation_to_world[4]), p11.timestep_2604)

    local animated = p12.animated
    local v6 = SkeletonTargets.update_positions(p12.drives.targets, {
        animation_hips = animated.animation_hips,
        animation_board = animated.animation_board,
        animation_to_world = animated.roots.animation_to_world,
        inverse_board = animated.roots.inverse_board,
        skate_root = animated.board_frames.skate_root,
        com_frame = animated.board_frames.com_frame,
        lifted_com_frame = animated.board_frames.lifted_com_frame,
        teleporting = p10.teleporting
    }, p12.body)

    p10.animation_board_to_physics = rt.copy(v6.animation_board_to_physics)
    p10.extra_target_positions = {
        rt.copy(v6.positions.com),
        rt.copy(v6.positions.lifted_com),
        rt.copy(v6.positions.following_com)
    }
    SkeletonPoseErrors.set_targets(p12.pose_errors, rt.copy(v6.positions))

    if not v6.continuous then
        SkeletonInputRuntime.reset_physical_pose(p10, p12, p15)

        if p11.state_2508 ~= 0 and p11.state_2508 ~= 702 then
            p10.invalid_target_reset = true
        end
    end

    local v7 = table.create(2)
    local v8 = p11.line_tests_960_1008_1056[1]

    if v8.valid == 0 then
        v7[1] = nil
    else
        v7[1] = rt.map(v8.position, rt.from_bits)
    end

    local v9 = p11.line_tests_960_1008_1056[2]

    if v9.valid == 0 then
        v7[2] = nil
    else
        v7[2] = rt.map(v9.position, rt.from_bits)
    end

    local v10 = SkeletonBody.part_translation(p12.body, 23)
    local update = import("skate_game/physics/foot_ik").FootIk.update
    local ik, animated2 = p12.ik, p12.animated
    local t2 = {
        state_id = p11.state_2508,
        flags_2468 = p11.flags_2468,
        flags_2472 = p11.flags_2472,
        flags_2480 = p11.flags_2480
    }
    local bone = p12.animation_input.contacts.bone

    if bone < 0 then
        bone += 18446744073709552000
    end

    t2.contact_bone = bone
    t2.physical_board = p12.animated.board_frames.physical_board
    t2.hips_world_position = v10
    t2.current_contacts = v7

    local v11 = update(ik, animated2, p13, t2)

    p10.drive_frames = v11.frames
    SkeletonDrives.update(p12.drives, v11.frames, p14.partial_ragdoll, p14.drive_weight_4028)
    v3.apply_gravity_displacement(p12.body, p11.gravity_2648)

    return v11
end

function t1.SkeletonInputRuntime.reset_physical_pose(p16, p17, p18) -- line: 156
    -- upvalues: rt (copy), v3 (copy), SkeletonPoseErrors (copy)
    p17.correction.pending = false

    local animated = p17.animated
    local v12 = v3.reset_to_animation(p17.body, animated.record, p16.drive_frames, animated.roots.animation_to_world, rt.copy(animated.board_frames.com_frame), p18)

    animated.board_frames.centre_of_mass = rt.copy(v12.world_hips)
    animated.board_frames.previous_centre_of_mass = rt.copy(v12.world_hips)
    animated.board_frames.com_velocity = { 0, 0, 0, 0 }
    p16.reset_local_hips = rt.copy(v12.local_hips)
    SkeletonPoseErrors.reset_history(p17.pose_errors)
end

function t1.restore_board_target_drives(p19) -- line: 177
    -- upvalues: rt (copy), RetailDriveType (copy)
    local t3 = {
        spring_or_max_velocity = 599.9999389648438,
        damping = 0,
        max_strength = 35999.99609375,
        drive_type = RetailDriveType.HardDrive
    }

    p19.targets.dynamics[1].linear = rt.copy(t3)
    p19.targets.dynamics[1].angular = rt.copy(t3)
end

return t1
