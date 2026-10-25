-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)

local function input_phase() -- line: 11
    -- upvalues: import (copy)
    return import("skate_game/physics/input_phase")
end

local function skeleton_input_runtime() -- line: 14
    -- upvalues: import (copy)
    return import("skate_game/physics/skeleton_input_runtime")
end

local t1 = {}

function t1.animated(p1, p2) -- line: 23
    -- upvalues: t1 (copy)
    t1.animated_target(p1, p2)
end

function t1.animated_target(p3, p4) -- line: 28
    -- upvalues: rt (copy), import (copy)
    local v1 = import("skate_game/physics/input_phase").collision(p4)
    local t2 = {
        animated = p4.animated_skeleton,
        body = p4.skeleton,
        drives = p4.skeleton_drives,
        ik = p4.foot_ik,
        animation_input = p4.animation_input,
        correction = p4.skeleton_output.correction,
        pose_errors = p4.pose_errors
    }

    return import("skate_game/physics/skeleton_input_runtime").SkeletonInputRuntime.update_animated(p4.skeleton_input, p4.skeleton_air, p3.board, p3.riding.reckoning_frames.system, p4.player_input.processed, t2, p4.animation.packet.hierarchy, v1, rt.copy(p3.settings.step.simulation), false)
end

function t1.ground_target(p5, p6) -- line: 56
    -- upvalues: rt (copy), import (copy)
    local v2 = import("skate_game/physics/input_phase").collision(p6)
    local t3 = {
        animated = p6.animated_skeleton,
        body = p6.skeleton,
        drives = p6.skeleton_drives,
        ik = p6.foot_ik,
        animation_input = p6.animation_input,
        correction = p6.skeleton_output.correction,
        pose_errors = p6.pose_errors
    }

    return import("skate_game/physics/skeleton_input_runtime").SkeletonInputRuntime.update_ground(p6.skeleton_input, p5.board, p5.riding.reckoning_frames.system, p6.player_input.processed, t3, p6.animation.packet.hierarchy, v2, rt.copy(p5.settings.step.simulation))
end

return t1
