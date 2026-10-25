-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/physics/input_phase")
local SkeletonInputRuntime = import("skate_game/physics/skeleton_input_runtime").SkeletonInputRuntime

return {
    advance = function(p1, p2) -- advance | line: 17
        -- upvalues: rt (copy), v1 (copy), SkeletonInputRuntime (copy)
        local v2 = v1.collision(p2)
        local t2 = {
            animated = p2.animated_skeleton,
            body = p2.skeleton,
            drives = p2.skeleton_drives,
            ik = p2.foot_ik,
            animation_input = p2.animation_input,
            correction = p2.skeleton_output.correction,
            pose_errors = p2.pose_errors
        }

        SkeletonInputRuntime.update_animated(p2.skeleton_input, p2.skeleton_air, p1.board, p1.riding.reckoning_frames.system, p2.player_input.processed, t2, p2.animation.packet.hierarchy, v2, rt.copy(p1.settings.step.simulation), true)
    end
}
