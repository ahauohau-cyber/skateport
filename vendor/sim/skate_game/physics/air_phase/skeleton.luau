-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)

local function input_phase() -- line: 9
    -- upvalues: import (copy)
    return import("skate_game/physics/input_phase")
end

local function skeleton_input_runtime() -- line: 12
    -- upvalues: import (copy)
    return import("skate_game/physics/skeleton_input_runtime")
end

return {
    advance = function(p1, p2, p3) -- advance | line: 19
        -- upvalues: rt (copy), import (copy)
        local v1 = import("skate_game/physics/input_phase").collision(p2)
        local t2 = {
            animated = p2.animated_skeleton,
            body = p2.skeleton,
            drives = p2.skeleton_drives,
            ik = p2.foot_ik,
            animation_input = p2.animation_input,
            correction = p2.skeleton_output.correction,
            pose_errors = p2.pose_errors
        }
        local packet = p2.animation.packet
        local SkeletonInputRuntime = import("skate_game/physics/skeleton_input_runtime").SkeletonInputRuntime

        if p3 ~= nil then
            SkeletonInputRuntime.update_known_air(p2.skeleton_input, p2.skeleton_air, p1.board, p1.riding.reckoning_frames.system, p3, packet, p2.player_input.processed, t2, packet.hierarchy, v1, rt.copy(p1.settings.step.simulation))
        else
            SkeletonInputRuntime.update_animated(p2.skeleton_input, p2.skeleton_air, p1.board, p1.riding.reckoning_frames.system, p2.player_input.processed, t2, packet.hierarchy, v1, rt.copy(p1.settings.step.simulation), false)
        end
    end
}
