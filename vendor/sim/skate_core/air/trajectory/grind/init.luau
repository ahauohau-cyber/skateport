-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/air/trajectory/grind/admission")
local v2 = import("skate_core/air/trajectory/grind/candidate")
local t1 = {
    admitted_displacement = v1.admitted_displacement,
    apply_admitted_target = v1.apply_admitted_target,
    descending_plane_time = v2.descending_plane_time,
    consider_grind_primitive = v2.consider_grind_primitive,
    take_best_grind = v2.take_best_grind,
    trajectory_box_filter = v2.trajectory_box_filter,
    GrindTrajectoryCandidate = {},
    GrindSurfaceEvidence = {},
    GrindAssistLimits = {},
    GrindTarget = {}
}

function t1.GrindTarget.air_target(p1) -- line: 61
    -- upvalues: rt (copy)
    return {
        edge = rt.copy(p1.edge),
        primitive_flags = p1.primitive_flags,
        orientation = rt.copy(p1.orientation)
    }
end

t1.GrindEvaluation = {}

function t1.GrindEvaluation.penalty_input(p2) -- line: 78
    local effective_lock_distance = p2.effective_lock_distance
    local v3 = effective_lock_distance == nil
    local v4, v5

    if not v3 then
        v4 = effective_lock_distance + 0.15000000596046448
        v5 = v4 < p2.penalty_domain
    end

    if v3 or not v5 then
        return p2.distance
    end

    return p2.penalty_domain / v4 * p2.distance
end

return t1
