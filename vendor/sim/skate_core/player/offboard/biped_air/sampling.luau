-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local Trajectory = import("skate_core/air/trajectory").Trajectory
local PointGraph = import("skate_core/point_graph").PointGraph
local v1 = import("skate_core/player/offboard/biped_air/selection")

local function recovered() -- line: 11
    -- upvalues: import (copy)
    return import("skate_core/player/offboard/biped_air/recovered")
end

local t1 = {
    Selection = {},
    SelectorState = {}
}

for v2, v3 in v1.SelectorState do
    t1.SelectorState[v2] = v3
end

function t1.SelectorState.sample(p1, p2, p3, p4, p5) -- line: 56
    -- upvalues: rt (copy), import (copy), Trajectory (copy), PointGraph (copy)
    local DT = import("skate_core/player/offboard/biped_air/recovered").DT

    p1.frame_8484 = p2

    local v4 = p2 * DT
    local v5 = rt.copy(p1.selection)

    if p1.pending_8492 then
        p5.position_272 = Trajectory.position_at(p1.fallback_8208, v4)
        p5.velocity_288 = Trajectory.velocity_at(p1.fallback_8208, v4)
        p5.valid_404 = false
        p5.contact_position_336 = { 0, 0, 0, 0 }
        p5.normal_304 = { 0, 1, 0, 0 }
        p5.contact_velocity_320 = { 0, 0, 0, 0 }
    else
        p1.elapsed_8388 += p3
        p1.blend_8384 = PointGraph.evaluate(p4, p1.elapsed_8388)

        local v6 = Trajectory.position_at(v5.trajectory_8144, v4)
        local v7 = Trajectory.position_at(p1.fallback_8208, v4)
        local blend_8384 = p1.blend_8384

        p5.position_272 = {
            v7[1] * (1 - blend_8384) + v6[1] * blend_8384,
            v7[2] * (1 - blend_8384) + v6[2] * blend_8384,
            v7[3] * (1 - blend_8384) + v6[3] * blend_8384,
            v7[4] * (1 - blend_8384) + v6[4] * blend_8384
        }
        p5.velocity_288 = Trajectory.velocity_at(v5.trajectory_8144, v4)
        p5.valid_404 = v5.valid_6200
        p5.contact_position_336 = rt.copy(v5.position_6176)
        p5.normal_304 = rt.copy(v5.normal_6144)
        p5.contact_velocity_320 = rt.copy(v5.velocity_6160)
    end

    if v5.result_present_3888 then
        p5.time_remaining_384 = rt.to_i32(rt.wrapping_sub_u32(rt.to_u32(v5.landing_frame_8480), rt.to_u32(p2))) * DT
    else
        p5.time_remaining_384 = 0
    end

    p5.duration_388 = v5.scalar_8392
    p5.frame_400 = p2
    p5.adjustment_352 = rt.copy(p1.adjustment_8336)

    local v8, v9 = Trajectory.highest_position(v5.trajectory_8144)

    p5.apex_368 = v8
    p5.apex_time_396 = v9
    p5.word_408 = v5.word_8396
    p5.scalar_392 = v5.candidate_scalar_100
end

return t1
