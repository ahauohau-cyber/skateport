-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local Trajectory = import("skate_core/air/trajectory").Trajectory
local v1 = import("skate_core/player/wipeout_state/math")
local add, dot, length, madd = v1.add, v1.dot, v1.length, v1.madd
local normalize_or, scale, sub = v1.normalize_or, v1.scale, v1.sub

local function parent() -- line: 17
    -- upvalues: import (copy)
    return import("skate_core/player/offboard/landing_deck")
end

local t1 = {
    UP = { 0, 1, 0, 0 },
    Manager = {}
}

function t1.Manager.assist(p1, p2, p3) -- line: 30
    -- upvalues: rt (copy), import (copy), length (copy), sub (copy)
    local Manager = import("skate_core/player/offboard/landing_deck").Manager

    p1.completed_queries_252 = 0
    p1.tested_259 = false

    local processed = p2.processed
    local force_257 = p1.force_257
    local v2 = if not force_257 then bit32.band(processed.flags_2480, 32768) == 0 else nil

    if (force_257 or v2) and processed.board_up_80[2] > p3.deck_min_uprightness then
        Manager.consider_board(p1, processed, p3, p2.position, p2.velocity)

        if p1.time_to_land_244 > 0.4 then
            local v3 = length(sub(p2.velocity, p1.proposed_96.velocity))

            p1.trajectory_32 = rt.copy(p1.proposed_96)
            p1.trajectory_valid_164 = true
            p1.time_to_land_244 = p1.proposed_time_248
            p1.can_land_256 = v3 < p2.maximum_velocity_change
        end

        if p1.can_land_256 and not p1.tested_259 then
            p1.tested_259 = true

            return Manager.prepare_query(p1, processed, p2.position, p1.proposed_time_248)
        end
    end

    return nil
end

function t1.Manager.update(p4, p5, p6) -- line: 58
    -- upvalues: rt (copy), import (copy), Trajectory (copy), length (copy), normalize_or (copy), t1 (copy)
    local v4 = import("skate_core/player/offboard/landing_deck")
    local Manager = v4.Manager

    p4.publish_moving_contact_261 = false
    p4.elapsed_160 += v4.STEP

    if p4.hippy_hurdling_260 then
        local _, v5 = Trajectory.highest_position(p4.trajectory_32)
        local v6 = p4.elapsed_160 - v5

        if v6 > 0.3 or v6 > 0 and p4.time_to_land_244 < 0.2 then
            p4.hippy_hurdling_260 = false
        end
    end

    local v7 = Trajectory.position_at(p4.trajectory_32, p4.elapsed_160)
    local v8 = Trajectory.velocity_at(p4.trajectory_32, p4.elapsed_160)

    p4.can_land_256 = not (p5.mode_2540 == 6 or p5.mode_2540 == 9 or p5.mode_2540 == 12)
    Manager.consider_board(p4, p5, p6, v7, v8)

    local v9 = if not p4.pending_262 and not p4.tested_259 and p4.can_land_256 then Manager.prepare_query(p4, p5, v7, p4.time_to_land_244) else nil
    local v10 = if p5.support_1776 < 0 then 0.55 else 0.5
    local v11, v12

    if length(p4.ik_offset_176) < v10 then
        if p4.force_257 or bit32.band(p5.flags_2480, 32768) == 0 then
            v12 = false
        else
            v11 = false
            v12 = true
        end
    else
        v11 = false
        v12 = true
    end

    p4.can_land_256 = if not v12 then p5.board_up_80[2] > p6.deck_min_uprightness else v11

    local v13 = p4.time_to_land_244 + p4.elapsed_160
    local v14 = Trajectory.velocity_at(p4.trajectory_32, v13)
    local v15, v16 = Trajectory.highest_position(p4.trajectory_32)

    return {
        can_land = p4.can_land_256 and not p4.blocked_258,
        trajectory_valid = p4.trajectory_valid_164,
        time_to_land = p4.time_to_land_244,
        elapsed = p4.elapsed_160,
        landing_time = v13,
        apex_time = v16,
        position = v7,
        landing_velocity = rt.copy(v14),
        launch_position = rt.copy(p4.trajectory_32.position),
        landing_position = Trajectory.position_at(p4.trajectory_32, v13),
        normal = rt.copy(t1.UP),
        apex_position = v15,
        direction = normalize_or(v14, t1.UP),
        up = rt.copy(t1.UP),
        query = v9
    }
end

function t1.Manager.calculate_accurate_ik_offset(p7, p8) -- line: 110
    -- upvalues: rt (copy), import (copy), Trajectory (copy), add (copy), dot (copy), madd (copy), scale (copy), sub (copy)
    local v17 = import("skate_core/player/offboard/landing_deck")
    local processed = p8.processed
    local v18 = p7.elapsed_160 + p8.time_to_land
    local v19 = p8.time_to_land + v17.STEP
    local v20 = sub(p8.mapped_position_12608, p8.animation_com_10960)
    local animation_root = p8.animation_root
    local v21 = madd(animation_root[3], v20[3], madd(animation_root[2], v20[2], scale(animation_root[1], v20[1])))

    p7.ik_offset_176 = sub(madd(sub(processed.board_velocity_400, scale(processed.up_544, dot(processed.up_544, processed.board_velocity_400))), v19, processed.board_position_112), add(Trajectory.position_at(p7.trajectory_32, v18), v21))
    p7.ik_offset_176[2] = 0

    return rt.copy(p7.ik_offset_176)
end

return t1
