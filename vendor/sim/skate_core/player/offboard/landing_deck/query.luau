-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/player/offboard/landing_deck/trajectory")
local frames, shift = v1.frames, v1.shift
local v2 = import("skate_core/air/trajectory")
local Trajectory, QueryResult = v2.Trajectory, v2.QueryResult
local v3 = import("skate_core/player/wipeout_state/math")
local add, dot, madd, reciprocal = v3.add, v3.dot, v3.madd, v3.reciprocal
local scale, sub = v3.scale, v3.sub

local function parent() -- line: 19
    -- upvalues: import (copy)
    return import("skate_core/player/offboard/landing_deck")
end

local t1 = {
    Manager = {}
}

function t1.Manager.prepare_query(p1, p2, p3, p4) -- line: 31
    -- upvalues: rt (copy), import (copy), add (copy), madd (copy), reciprocal (copy), scale (copy), sub (copy)
    local GRAVITY = import("skate_core/player/offboard/landing_deck").GRAVITY
    local v4 = add(madd(p2.board_velocity_400, p4, p2.board_position_112), { 0, 0.20000001788139343, 0, 0 })

    p1.blocked_258 = false
    p1.obstruction_height_240 = v4[2] + -0.1

    return {
        radius = 0.3,
        start_error = 0.5,
        end_error = 0.5,
        trajectory = {
            position = rt.copy(p3),
            velocity = sub(scale(sub(v4, p3), reciprocal(p4)), scale(scale(GRAVITY, 0.5), p4)),
            acceleration = rt.copy(GRAVITY),
            duration = p4
        }
    }
end

function t1.Manager.query_submitted(p5) -- line: 52
    p5.pending_262 = true
end

function t1.Manager.sync(p6, p7, p8, p9) -- line: 62
    -- upvalues: rt (copy), QueryResult (copy), t1 (copy)
    local v5 = rt.copy(p6)
    local v6 = if p7 == nil or QueryResult.valid(p7) then p7 else nil

    t1.Manager.sync_completed(v5, v6, p8, p9)
    rt.assign(p6, v5)
end

function t1.Manager.sync_completed(p10, p11, p12, p13) -- line: 72
    -- upvalues: rt (copy), frames (copy), shift (copy), Trajectory (copy), dot (copy), madd (copy), scale (copy), sub (copy)
    if p11 == nil or p11.contact_position[2] < p10.obstruction_height_240 then
        p10.blocked_258 = false
        p10.tested_259 = true
    elseif p10.tested_259 then
        p10.blocked_258 = true
    elseif p10.completed_queries_252 == 0 then
        p10.moving_contact_208 = rt.copy(p11.contact_transform[4])
        p10.publish_moving_contact_261 = true
    else
        local v7 = rt.copy(p11.contact_transform[4])
        local v8 = scale(sub(v7, p10.moving_contact_208), 60)

        if dot(v8, v8) > 0.4899999797344208 then
            p10.hippy_hurdling_260 = true

            if p10.completed_queries_252 == 1 then
                if bit32.band(p12.flags_2488, 67108864) ~= 0 then
                    local v9 = Trajectory.velocity_at(p10.trajectory_32, p10.elapsed_160)
                    local v10 = p13(p10)

                    if v10[2] > v9[2] then
                        local v11 = frames(p10.elapsed_160)

                        shift(p10.trajectory_32, v11)
                        p10.trajectory_32.velocity = rt.copy(v10)
                        shift(p10.trajectory_32, rt.to_i32(rt.wrapping_sub_u32(0, rt.to_u32(v11))))
                    end
                end
            else
                local v12 = p10.time_to_land_244 + p10.elapsed_160
                local v13 = madd(v8, p10.time_to_land_244, v7)
                local v14 = sub(Trajectory.position_at(p10.trajectory_32, v12), v13)

                v14[2] = 0

                local v15 = dot(v14, v14)

                if Trajectory.velocity_at(p10.trajectory_32, p10.elapsed_160)[2] < 0 then
                    if p12.position_592[2] - p11.contact_position[2] < 0.7 then
                        p10.blocked_258 = true
                        p10.tested_259 = true
                    end
                elseif v15 < 1 then
                    p10.blocked_258 = true
                    p10.tested_259 = true
                elseif v15 > 6.25 then
                    p10.blocked_258 = false
                    p10.tested_259 = true
                end
            end
        else
            p10.hippy_hurdling_260 = false
            p10.blocked_258 = true
            p10.tested_259 = true
        end

        p10.moving_contact_208 = v7
    end

    p10.pending_262 = false
    p10.completed_queries_252 = rt.wrapping_add_u32(p10.completed_queries_252, 1)
end

return t1
