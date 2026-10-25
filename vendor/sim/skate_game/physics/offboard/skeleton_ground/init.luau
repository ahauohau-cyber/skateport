-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/physics/offboard/skeleton_ground/frames")
local v2 = import("skate_game/physics/offboard/skeleton_ground/state")
local SkeletonInputRuntime = import("skate_game/physics/skeleton_input_runtime").SkeletonInputRuntime

local function skeleton_air() -- line: 16
    -- upvalues: import (copy)
    return import("skate_game/physics/skeleton_air")
end

local function animated_skeleton() -- line: 19
    -- upvalues: import (copy)
    return import("skate_game/physics/animated_skeleton")
end

local t1 = {
    State = v2.State,
    Input = {},
    ReckoningUpdate = {},
    SkeletonInputRuntime = {}
}

function t1.SkeletonInputRuntime.update_biped_ground(p1, p2, p3, p4, p5, p6, p7, p8, p9, p10, p11) -- line: 50
    -- upvalues: rt (copy), import (copy), v1 (copy), SkeletonInputRuntime (copy)
    local animated = p7.animated
    local v3, v4 = v1.prepare_pose(animated.roots, animated.board_frames, animated.record.pose[1], p1.drive_frames[1], p5.retained_board, p4, p6.flags_2476, p6.flags_2484, p6.flags_2468)

    p6.flags_2468 = v4

    if not (bit32.band(p6.flags_2480, 32768) == 0 and bit32.band(p6.flags_2484, 1) == 0) then
        animated.board_frames.physical_board = import("skate_game/physics/skeleton_air").SkeletonAir.apply_board(p2, p3, v3, true)
    end

    SkeletonInputRuntime.general_update(p1, p6, p7, p8, p9, p10)
    import("skate_game/physics/animated_skeleton").AnimatedSkeleton.finish_ground(p7.animated)

    local v7 = rt.copy(p7.animated.roots.animation_to_world)

    p11({
        blend = 0.5,
        up = v7[2],
        forward = v7[3]
    })
    p7.animation_input.fields.flags2468 = p6.flags_2468

    return v3
end

return t1
