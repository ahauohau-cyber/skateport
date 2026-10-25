-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local TrajectorySelector = import("skate_core/air/trajectory").TrajectorySelector
local SkeletonOutputFields = import("skate_core/player/input_phase").SkeletonOutputFields
local t1 = {
    PlayerInputRuntime = {}
}

function t1.PlayerInputRuntime.publish_grind_graph_outputs(p1, p2, p3, p4) -- line: 23
    -- upvalues: rt (copy), TrajectorySelector (copy), SkeletonOutputFields (copy)
    local toolkit = p1.toolkit

    if toolkit == nil then
        error("Grind output requires the completed physical input toolkit", 0)
    end

    p1.physical.air.flag_443 = TrajectorySelector.grind_locked_to_middle(p4) and 1 or 0
    SkeletonOutputFields.publish_twist(p1.physical.skeleton, p2, rt.copy(toolkit.forward), p3)
end

return t1
