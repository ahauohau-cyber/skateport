-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/player/input_phase/runtime")
local v2 = import("skate_core/player/input_phase/types")
local v3 = import("skate_core/player/input_phase/air_output")
local v4 = import("skate_core/player/input_phase/pose_output")
local v5 = import("skate_core/player/input_phase/requests")
local v6 = import("skate_core/player/input_phase/grind_input")
local v7 = import("skate_core/player/input_phase/grind_output")
local t1 = {
    InputContinuation = v1.InputContinuation,
    InputPhaseError = v1.InputPhaseError,
    InputPhaseServices = v1.InputPhaseServices,
    process_input = v1.process_input,
    start_input = v1.start_input,
    finish_input = v1.finish_input
}

for v8, v9 in v2 do
    t1[v8] = v9
end

t1.AirOutputFields = v3.AirOutputFields
t1.AnimationOutputFields = v4.AnimationOutputFields
t1.ScoringOutputFields = v4.ScoringOutputFields
t1.SkeletonOutputFields = v4.SkeletonOutputFields

for v10, v11 in v5 do
    t1[v10] = v11
end

t1.GrindInvestigationFields = v6.GrindInvestigationFields
t1.GrindOutputFields = v7.GrindOutputFields

return t1
