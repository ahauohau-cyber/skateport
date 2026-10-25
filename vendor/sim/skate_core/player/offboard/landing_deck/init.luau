-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/player/offboard/landing_deck/query")
local v2 = import("skate_core/player/offboard/landing_deck/trajectory")
local v3 = import("skate_core/player/offboard/landing_deck/types")
local v4 = import("skate_core/player/offboard/landing_deck/update")
local v5 = import("skate_core/air/trajectory")
local v6 = import("skate_core/player/wipeout_state/math")
local add, sub = v6.add, v6.sub
local adjust, frames = v2.adjust, v2.frames
local t1 = {
    QueryRequest = v5.QueryRequest,
    QueryResult = v5.QueryResult,
    Trajectory = v5.Trajectory
}
local Trajectory = t1.Trajectory

for v7, v8 in v3 do
    t1[v7] = v8
end

t1.STEP = 0.01666666753590107
t1.GRAVITY = { 0, -9.800000190734863, 0, 0 }
t1.EMPTY = {
    duration = -1,
    position = { 0, 0, 0, 0 },
    velocity = { 0, 0, 0, 0 },
    acceleration = { 0, 0, 0, 0 }
}
t1.Manager = {}

function t1.Manager.default() -- line: 62
    -- upvalues: rt (copy), t1 (copy)
    return {
        elapsed_160 = 0,
        trajectory_valid_164 = false,
        obstruction_height_240 = 0,
        time_to_land_244 = 0,
        proposed_time_248 = 0,
        completed_queries_252 = 0,
        can_land_256 = false,
        force_257 = false,
        blocked_258 = false,
        tested_259 = false,
        hippy_hurdling_260 = false,
        publish_moving_contact_261 = false,
        pending_262 = false,
        trajectory_32 = rt.copy(t1.EMPTY),
        proposed_96 = rt.copy(t1.EMPTY),
        ik_offset_176 = { 0, 0, 0, 0 },
        vector_192 = { 0, 0, 0, 0 },
        moving_contact_208 = { 0, 0, 0, 0 },
        vector_224 = { 0, 0, 0, 0 }
    }
end

function t1.Manager.reset(p1) -- line: 87
    -- upvalues: rt (copy), t1 (copy)
    p1.trajectory_32 = rt.copy(t1.EMPTY)
    p1.elapsed_160 = 0
    p1.trajectory_valid_164 = false
    p1.ik_offset_176 = { 0, 0, 0, 0 }
    p1.vector_192 = { 0, 0, 0, 0 }
    p1.moving_contact_208 = { 0, 0, 0, 0 }
    p1.vector_224 = { 0, 0, 0, 0 }
    p1.obstruction_height_240 = 0
    p1.time_to_land_244 = 0
    p1.proposed_time_248 = 0
    p1.completed_queries_252 = 0
    p1.can_land_256 = false
    p1.force_257 = false
    p1.blocked_258 = false
    p1.tested_259 = false
    p1.hippy_hurdling_260 = false
    p1.publish_moving_contact_261 = false
end

function t1.Manager.correct_trajectory(p2, p3) -- line: 108
    -- upvalues: add (copy), sub (copy), adjust (copy), frames (copy), Trajectory (copy)
    local v9 = sub(Trajectory.position_at(p2.trajectory_32, p2.elapsed_160), p3)
    local v10 = frames(p2.time_to_land_244)

    if v10 > 0 then
        p2.trajectory_32.position = add(p2.trajectory_32.position, v9)
        adjust(p2.trajectory_32, v10, {
            -v9[1],
            -v9[2],
            -v9[3],
            -v9[4]
        }, 0.5)
    end
end

function t1.Manager.fill(p4) -- line: 118
    -- upvalues: rt (copy)
    return {
        can_land_316 = p4.can_land_256 and not p4.blocked_258,
        hippy_hurdling_317 = p4.hippy_hurdling_260 and not p4.blocked_258,
        moving_contact = if p4.publish_moving_contact_261 then rt.copy(p4.moving_contact_208) else nil
    }
end

for v11, v12 in v1.Manager do
    t1.Manager[v11] = v12
end

for v13, v14 in v2.Manager do
    t1.Manager[v13] = v14
end

for v15, v16 in v4.Manager do
    t1.Manager[v15] = v16
end

return t1
