-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/skeleton_animation_record")
local v2 = import("skate_core/physics/skeleton_board_frames")
local v3 = import("skate_core/physics/skeleton_body")
local v4 = import("skate_core/player/wipeout_state/drives")
local v5 = import("skate_core/player/wipeout_state/skeleton")
local IDENTITY = v1.IDENTITY
local SkeletonBoardFrames = v2.SkeletonBoardFrames
local SkeletonBody, SkeletonPoseErrors, SkeletonTargets = v3.SkeletonBody, v3.SkeletonPoseErrors, v3.SkeletonTargets

local function foot_ik() -- line: 22
    -- upvalues: import (copy)
    return import("skate_game/physics/foot_ik")
end

local t1 = {}

local function i32_as_usize(p1) -- line: 29
    if p1 < 0 then
        return p1 + 18446744073709552000
    end

    return p1
end

function t1.update(p2, p3, p4, p5, p6, p7, p8, p9, p10, p11) -- line: 38
    -- upvalues: rt (copy), import (copy), v4 (copy), v5 (copy), IDENTITY (copy), SkeletonBoardFrames (copy), SkeletonBody (copy), SkeletonPoseErrors (copy), SkeletonTargets (copy)
    local animated = p3.animated

    animated.roots.initialize_heading = false
    v5.update_roots(animated.roots, animated.animation_hips, p3.body.record.pose[24], rt.copy(p3.body.record.velocities[24]), rt.copy(animated.board_frames.centre_of_mass), rt.map(p4.vectors_544_560_592_608[4], rt.from_bits), p4.state_timer_2664)

    local t2 = {
        animation_hips = animated.animation_hips,
        animation_board = animated.animation_board,
        animation_to_world = animated.roots.animation_to_world,
        inverse_board = animated.roots.inverse_board,
        skate_root = animated.board_frames.skate_root,
        com_frame = animated.board_frames.com_frame,
        lifted_com_frame = animated.board_frames.lifted_com_frame,
        teleporting = p2.teleporting
    }

    if not p11 then
        p2.animation_board_to_physics = SkeletonTargets.update_hook_positions(p3.drives.targets, t2)

        local v6 = SkeletonTargets.update_extra_targets(p3.drives.targets, p3.body, t2.com_frame, t2.lifted_com_frame)

        p2.extra_target_positions = {
            rt.copy(v6.com),
            rt.copy(v6.lifted_com),
            rt.copy(v6.following_com)
        }
        SkeletonPoseErrors.set_targets(p3.pose_errors, v6)
    end

    animated.board_frames.skate_root = rt.copy(animated.roots.animation_to_world)
    SkeletonBoardFrames.update_com_lift(animated.board_frames, animated.roots.animation_to_world, rt.copy(animated.board_frames.centre_of_mass), 0)

    if p4.state_timer_2664 == 0 then
        local v7 = table.create(2)
        local v8 = p4.line_tests_960_1008_1056[1]

        if v8.valid == 0 then
            v7[1] = nil
        else
            v7[1] = rt.map(v8.position, rt.from_bits)
        end

        local v9 = p4.line_tests_960_1008_1056[2]

        if v9.valid == 0 then
            v7[2] = nil
        else
            v7[2] = rt.map(v9.position, rt.from_bits)
        end

        local update = import("skate_game/physics/foot_ik").FootIk.update
        local ik = p3.ik
        local t3 = {
            state_id = p4.state_2508,
            flags_2468 = p4.flags_2468,
            flags_2472 = p4.flags_2472,
            flags_2480 = p4.flags_2480
        }
        local bone = p3.animation_input.contacts.bone

        if bone < 0 then
            bone += 18446744073709552000
        end

        t3.contact_bone = bone
        t3.physical_board = animated.board_frames.physical_board
        t3.hips_world_position = rt.copy(SkeletonBody.part_transforms(p3.body)[24][4])
        t3.current_contacts = v7

        local v10 = update(ik, animated, p5, t3)

        p2.drive_frames = rt.copy(v10.frames)
    end

    local v11 = v4.update(p3.drives, p2.drive_frames, p6, {
        start = p7,
        ["end"] = p8,
        controlled = p9,
        upper_extra = if bit32.band(p4.flags_2484, 32) == 0 then 0 else p10,
        lower_extra = if bit32.band(p4.flags_2484, 16) == 0 then 0 else p10
    })

    animated.motion.next_trajectory = rt.copy(IDENTITY)

    return v11
end

return t1
