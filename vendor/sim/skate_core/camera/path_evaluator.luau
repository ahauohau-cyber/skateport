-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/camera/path_prediction")
local PERF = import("skate_core/camera/tracker").PERF
local t1 = {
    TrajectoryCollisionRequest = {},
    MovingObstacleProvider = {},
    PathEvaluator = {}
}

function t1.PathEvaluator.update_request(p1, p2, p3) -- line: 45
    -- upvalues: rt (copy), t1 (copy), PERF (copy)
    if p1.request_state == 0 then
        if p3.borrows_path ~= true or PERF.reference then
            p3.submit(p3, rt.copy(p1.path), p2, p1.acceleration_flag)
        else
            p3.submit(p3, p1.path, p2, p1.acceleration_flag)
        end

        p1.submitted_acceleration_flag = p1.acceleration_flag
        p1.request_state = 1
        p1.pending_polls = 0
    elseif p1.request_state == 1 then
        if p3.is_ready(p3) then
            local v2 = p3.collision_time(p3)

            if v2 < 0 then
                v2 = rt.F32_MAX
            end

            p1.found = 1
            p1.request_state = 0
            p1.result_acceleration_flag = p1.submitted_acceleration_flag
            p1.collision_time = t1.select_time(p1.collision_time, v2)
        else
            p1.pending_polls = rt.to_i32(rt.wrapping_add_u32(rt.to_u32(p1.pending_polls), rt.to_u32(1)))

            if p1.pending_polls > 3 then
                p1.request_state = 0
                p1.last_valid_time = rt.F32_MAX
            end
        end
    end
end

local v3 = table.create(50)
local v4 = table.create(50)
local v5 = table.create(50)
local v6 = table.create(50)

for i = 1, 50 do
    v5[i] = { 0, 0, 0, 0 }
    v6[i] = { 0, 0, 0, 0 }
    v4[i] = {
        radius = 0,
        position = v5[i],
        velocity = v6[i]
    }
    v3[i] = v4[i]
end

local function zeroed_obstacles() -- line: 95
    -- upvalues: v3 (copy), v4 (copy), v5 (copy), v6 (copy)
    for i = #v3, 51, -1 do
        v3[i] = nil
    end

    for i = 1, 50 do
        local v7 = v5[i]
        local v8 = v6[i]
        local v9 = v4[i]

        v7[1] = 0
        v7[2] = 0
        v7[3] = 0
        v7[4] = 0
        v8[1] = 0
        v8[2] = 0
        v8[3] = 0
        v8[4] = 0
        v9.position = v7
        v9.velocity = v8
        v9.radius = 0
        v3[i] = v9
    end

    return v3
end

function t1.PathEvaluator.update(p4, p5, p6, p7) -- line: 111
    -- upvalues: rt (copy), v1 (copy), t1 (copy), PERF (copy), zeroed_obstacles (copy)
    if PERF.reference then
        return t1.PathEvaluator.update_reference(p4, p5, p6, p7)
    end

    p4.found = 0
    p4.collision_time = rt.F32_MAX
    t1.PathEvaluator.update_request(p4, p5, p6)

    local path = p4.path
    local v10

    if p7.collects_nothing == true then
        v10 = rt.F32_MAX
    else
        local v11 = zeroed_obstacles()
        local v12 = p7.collect(p7, rt.copy(path.position), rt.copy(path.velocity), path.radius, v11)

        if not (v12 <= #v11) then
            error("native moving-sphere capacity exceeded", 0)
        end

        v10 = v1.candidate_collision_time(p4.path, rt.slice(v11, 0, v12))
    end

    if v10 < p4.path.horizon then
        p4.found = 1
        p4.collision_time = t1.select_time(p4.collision_time, v10)
    end

    if p4.found ~= 0 then
        p4.last_valid_time = p4.collision_time
    end
end

function t1.PathEvaluator.update_reference(p8, p9, p10, p11) -- line: 145
    -- upvalues: rt (copy), v1 (copy), t1 (copy)
    p8.found = 0
    p8.collision_time = rt.F32_MAX
    t1.PathEvaluator.update_request(p8, p9, p10)

    local v13 = rt.filled(50, {
        radius = 0,
        position = { 0, 0, 0, 0 },
        velocity = { 0, 0, 0, 0 }
    })
    local v14 = p11.collect(p11, rt.copy(p8.path.position), rt.copy(p8.path.velocity), p8.path.radius, v13)

    if not (v14 <= #v13) then
        error("native moving-sphere capacity exceeded", 0)
    end

    local v15 = v1.candidate_collision_time(p8.path, rt.slice(v13, 0, v14))

    if v15 < p8.path.horizon then
        p8.found = 1
        p8.collision_time = t1.select_time(p8.collision_time, v15)
    end

    if p8.found ~= 0 then
        p8.last_valid_time = p8.collision_time
    end
end

function t1.select_time(p12, p13) -- line: 177
    if p12 - p13 >= 0 then
        return p13
    end

    return p12
end

return t1
