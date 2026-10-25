-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/physics/skeleton_input_runtime")
local v2 = import("skate_core/physics/skeleton_animation_record")
local v3 = import("skate_core/physics/skeleton_board_frames")
local v4 = import("skate_core/physics/skeleton_biped_air")
local SkeletonInputRuntime = v1.SkeletonInputRuntime
local compose_affine = v2.compose_affine
local SkeletonBoardFrames = v3.SkeletonBoardFrames

local function skeleton_air() -- line: 21
    -- upvalues: import (copy)
    return import("skate_game/physics/skeleton_air")
end

local function animated_skeleton() -- line: 24
    -- upvalues: import (copy)
    return import("skate_game/physics/animated_skeleton")
end

local t1 = {
    Input = {},
    SkeletonInputRuntime = {}
}

function t1.SkeletonInputRuntime.update_biped_air(p1, p2, p3, p4, p5, p6, p7, p8, p9, p10) -- line: 51
    -- upvalues: rt (copy), import (copy), v4 (copy), SkeletonInputRuntime (copy), compose_affine (copy), SkeletonBoardFrames (copy)
    local animated = p6.animated

    animated.board_frames.skate_root = compose_affine(animated.roots.animation_to_world, animated.record.pose[1])
    SkeletonBoardFrames.update_com_lift(animated.board_frames, animated.roots.animation_to_world, rt.copy(p4.body_target_416), p4.lift_436)

    local v5, v6 = v4.prepare(animated.roots, p4.frame_208, rt.copy(p4.trajectory_position_272), rt.copy(animated.record.centre_of_mass), p1.drive_frames[1], p5.flags_2476, p5.flags_2468)

    p5.flags_2468 = v6
    animated.board_frames.animation_target = rt.copy(v5)

    if bit32.band(p5.flags_2480, 32768) ~= 0 then
        animated.board_frames.physical_board = import("skate_game/physics/skeleton_air").SkeletonAir.apply_board(p2, p3, v5, true)
    end

    SkeletonInputRuntime.general_update(p1, p5, p6, p7, p8, p9)
    p10({
        blend = 0.5,
        up = rt.copy(p6.animated.roots.animation_to_world[2]),
        forward = rt.copy(p4.board_forward_96)
    }, p5, p6.animation_input.extra.physical_body_spin)
    import("skate_game/physics/animated_skeleton").AnimatedSkeleton.finish_ground(p6.animated)
    p6.animation_input.fields.flags2468 = p5.flags_2468

    return v5
end

return t1
