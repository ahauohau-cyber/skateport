-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local Trajectory, QueryResult = import("skate_core/air/trajectory").Trajectory, import("skate_core/air/trajectory").QueryResult

local function recovered() -- line: 10
    -- upvalues: import (copy)
    return import("skate_core/player/offboard/biped_air/recovered")
end

local t1 = {}

local function wrapping_neg_i32(p1) -- line: 21
    -- upvalues: rt (copy)
    return rt.to_i32(rt.wrapping_sub_u32(0, rt.to_u32(p1)))
end

t1.Candidate = {}

function t1.Candidate.reset() -- line: 39
    -- upvalues: t1 (copy)
    return {
        start_frame_112 = 0,
        landing_frame_116 = 0,
        valid_120 = false,
        special_121 = false,
        trajectory = t1.cleared_trajectory(),
        normal_64 = { 0, 0, 0, 0 },
        contact_velocity_80 = { 0, 0, 0, 0 },
        contact_position_96 = { 0, 0, 0, 0 }
    }
end

function t1.cleared_trajectory() -- line: 52
    return {
        duration = -1,
        position = { 0, 0, 0, 0 },
        velocity = { 0, 0, 0, 0 },
        acceleration = { 0, 0, 0, 0 }
    }
end

function t1.selected_index(p2) -- line: 64
    if #p2 == 0 then
        return nil
    end

    local v1 = #p2 - 1
    local n1 = -1E+08
    local n2 = 0

    for i = 0, v1 do
        local v2 = p2[i + 1]

        if n1 < v2 then
            n2 = i
            n1 = v2
        end
    end

    return n2
end

local function shift(p3, p4) -- line: 80
    -- upvalues: Trajectory (copy)
    local v3 = Trajectory.position_at(p3, p4)
    local v4 = Trajectory.velocity_at(p3, p4)

    p3.position = v3
    p3.velocity = v4
end

t1.SelectorState = {}

function t1.SelectorState.reset_sampling(p5) -- line: 92
    -- upvalues: t1 (copy)
    return {
        pending_8492 = false,
        restart_allowed_8493 = true,
        preinitialized_8494 = false,
        blend_8384 = 0,
        elapsed_8388 = 0,
        frame_8484 = 0,
        fallback_8208 = t1.cleared_trajectory(),
        selection = {
            valid_6200 = false,
            result_present_3888 = false,
            landing_frame_8480 = 1000,
            scalar_8392 = 0,
            word_8396 = 0,
            trajectory_8144 = t1.cleared_trajectory(),
            normal_6144 = { 0, 0, 0, 0 },
            velocity_6160 = { 0, 0, 0, 0 },
            position_6176 = { 0, 0, 0, 0 },
            candidate_scalar_100 = p5
        },
        adjustment_8336 = { 0, 0, 0, 0 }
    }
end

function t1.SelectorState.seed_fallback(p6, p7, p8, p9) -- line: 119
    -- upvalues: rt (copy)
    p6.fallback_8208 = {
        duration = 2,
        position = rt.copy(p7),
        velocity = rt.copy(p8),
        acceleration = rt.copy(p9)
    }
    p6.pending_8492 = true
end

function t1.SelectorState.commit(p10, p11, p12, p13) -- line: 132
    -- upvalues: rt (copy), import (copy), Trajectory (copy), QueryResult (copy)
    local DT = import("skate_core/player/offboard/biped_air/recovered").DT

    p10.pending_8492 = false

    local start_frame_112 = p11.start_frame_112
    local v5 = rt.to_i32(rt.wrapping_sub_u32(0, rt.to_u32(start_frame_112))) * DT

    if QueryResult.valid(p12.result) then
        p12.result.contact_frame = rt.to_i32(rt.wrapping_add_u32(rt.to_u32(p12.result.contact_frame), rt.to_u32(p11.start_frame_112)))
        p12.result.contact_time -= v5
    end

    local trajectory = p12.request.trajectory
    local v6 = Trajectory.position_at(trajectory, v5)
    local v7 = Trajectory.velocity_at(trajectory, v5)

    trajectory.position = v6
    trajectory.velocity = v7

    local v8 = rt.copy(p11.trajectory)
    local v9 = Trajectory.position_at(v8, v5)
    local v10 = Trajectory.velocity_at(v8, v5)

    v8.position = v9
    v8.velocity = v10
    v8.position = {
        v8.position[1] + -p13[1],
        v8.position[2] + -p13[2],
        v8.position[3] + -p13[3],
        v8.position[4] + -p13[4]
    }

    local scalar_8392, word_8396 = p10.selection.scalar_8392, p10.selection.word_8396
    local v11 = QueryResult.valid(p12.result)

    if v11 then
        scalar_8392 = p11.landing_frame_116 * DT
        word_8396 = if p11.special_121 then 2 else bit32.band(bit32.rshift(p12.result.surface, 7), 31)
    end

    p10.selection = {
        result_present_3888 = true,
        trajectory_8144 = v8,
        normal_6144 = rt.copy(p11.normal_64),
        velocity_6160 = rt.copy(p11.contact_velocity_80),
        position_6176 = rt.copy(p11.contact_position_96),
        valid_6200 = p11.valid_120,
        landing_frame_8480 = p11.landing_frame_116,
        scalar_8392 = scalar_8392,
        word_8396 = word_8396,
        candidate_scalar_100 = p11.contact_position_96[2]
    }
    p10.preinitialized_8494 = true

    return v11
end

return t1
