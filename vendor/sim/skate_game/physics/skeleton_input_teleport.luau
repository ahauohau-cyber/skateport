-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/animation/foot_ik/state")
local v2 = import("skate_core/physics/board")
local v3 = import("skate_core/physics/board_runtime")
local v4 = import("skate_core/physics/skeleton_animation_record")
local v5 = import("skate_core/physics/skeleton_board_frames")
local v6 = import("skate_core/physics/skeleton_board_offset")
local v7 = import("skate_core/physics/skeleton_body")
local v8 = import("skate_core/physics/skeleton_motion")
local v9 = import("skate_core/physics/skeleton_root")
local FootIkState = v1.FootIkState
local BodyId = v2.BodyId
local BoardRuntime = v3.BoardRuntime
local IDENTITY = v4.IDENTITY
local SkeletonBoardFrames = v5.SkeletonBoardFrames
local SkateboardOffset = v6.SkateboardOffset
local SkeletonCollisionMode = v7.SkeletonCollisionMode
local SkeletonMotion = v8.SkeletonMotion
local SkeletonRootFrames = v9.SkeletonRootFrames

local function skeleton_input_runtime() -- line: 36
    -- upvalues: import (copy)
    return import("skate_game/physics/skeleton_input_runtime")
end

local function animated_skeleton() -- line: 40
    -- upvalues: import (copy)
    return import("skate_game/physics/animated_skeleton")
end

local t1 = {
    SkeletonInputRuntime = {}
}

function t1.SkeletonInputRuntime.reset_for_teleport(p1, p2, p3, p4, p5, _) -- line: 53
    -- upvalues: rt (copy), FootIkState (copy), IDENTITY (copy), SkateboardOffset (copy), SkeletonCollisionMode (copy), SkeletonMotion (copy)
    SkeletonMotion.reset_board_orientation_history(p2.animated.motion)
    p1.reenable_requested = true
    p1.invalid_target_reset = false
    SkeletonCollisionMode.reset_body_state(p3, p4)
    p1.force_mode = 0
    p1.head_tracking_history = rt.filled(8, { 0, 0, 0, 0 })
    p1.head_tracking_active = false
    p2.ik.state = FootIkState.default()
    p5.time = 0
    p5.amplitude = 0
    p5.direction = 1
    p5.active = false
    p5.landing = false
    p2.animated.board_frames.animation_target = rt.copy(IDENTITY)
    p2.animated.board_offset = SkateboardOffset.default()
    p2.animated.board_frames.lift_height = 0

    return true
end

function t1.SkeletonInputRuntime.update_teleport(p7, p8, p9, p10, p11, p12, p13, p14) -- line: 80
    -- upvalues: rt (copy), import (copy), BodyId (copy), BoardRuntime (copy), SkeletonBoardFrames (copy), SkeletonRootFrames (copy)
    p7.teleporting = true

    local v10 = BoardRuntime.part_transforms(p8)[BodyId.index(BodyId.Deck) + 1]
    local v11 = rt.filled(4, table.create(4, 0))

    for i = 0, 2 do
        local v12 = v10.basis.columns[i + 1]

        v11[i + 1][1] = v12[1]
        v11[i + 1][2] = v12[2]
        v11[i + 1][3] = v12[3]
    end

    v11[4] = {
        v10.translation.x,
        v10.translation.y,
        v10.translation.z,
        0
    }

    local animated = p11.animated

    SkeletonRootFrames.update_teleport(animated.roots, rt.copy(v11), animated.animation_board, p9)

    local v13, v14 = SkeletonBoardFrames.prepare_teleport(animated.board_frames, animated.roots, p7.drive_frames[1], rt.copy(v11), p10.flags_2468)

    p10.flags_2468 = v14

    local general_update = import("skate_game/physics/skeleton_input_runtime").SkeletonInputRuntime.general_update
    local ok, result = pcall(general_update, p7, p10, p11, p12, p13, p14)

    p7.teleporting = false

    if not ok then
        error(result, 0)
    end

    import("skate_game/physics/animated_skeleton").AnimatedSkeleton.finish_ground(p11.animated)
    p11.animation_input.fields.flags2468 = p10.flags_2468

    return v13
end

return t1
