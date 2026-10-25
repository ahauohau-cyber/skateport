-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local PointGraph = import("skate_core/point_graph").PointGraph
local v1 = import("skate_core/player/offboard/movement_intent/math")
local HALF_PI, select, clamp, dot = v1.HALF_PI, v1.select, v1.clamp, v1.dot
local scale, sub, madd, _ = v1.scale, v1.sub, v1.madd, v1.length
local normalize_or, horizontal, wrap_angle, signed_angle = v1.normalize_or, v1.horizontal, v1.wrap_angle, v1.signed_angle
local projected_angle = v1.projected_angle
local t1 = {
    Settings = {},
    State = {}
}

function t1.State.default() -- line: 45
    return {
        speed = 0,
        steering = 0,
        sprint_time = 0,
        sprint_grace = 0,
        secondary_speed = 0,
        original_steering = 0,
        obstacle_centered = false,
        edge_aligned = false,
        edge_target = { 0, 0, 0, 0 }
    }
end

function t1.State.eq(p1, p2) -- line: 60
    if p1.speed ~= p2.speed
        or p1.steering ~= p2.steering
        or p1.sprint_time ~= p2.sprint_time
        or p1.sprint_grace ~= p2.sprint_grace
        or p1.secondary_speed ~= p2.secondary_speed
        or p1.original_steering ~= p2.original_steering
        or p1.obstacle_centered ~= p2.obstacle_centered
        or p1.edge_aligned ~= p2.edge_aligned then
        return false
    end

    if p1.edge_target[1] == p2.edge_target[1] and p1.edge_target[2] == p2.edge_target[2] and p1.edge_target[3] == p2.edge_target[3] then
        return p1.edge_target[4] == p2.edge_target[4]
    end

    return false
end

t1.Input = {}

function t1.State.update(p3, p4, p5) -- line: 104
    -- upvalues: rt (copy), PointGraph (copy), HALF_PI (copy), select (copy), clamp (copy), dot (copy), scale (copy), sub (copy), madd (copy), normalize_or (copy), horizontal (copy), wrap_angle (copy), signed_angle (copy), t1 (copy)
    local suppress_minimum = p5.suppress_minimum
    local v2 = if not suppress_minimum then bit32.band(p5.flags, 8) == 0 else nil
    local v3 = if suppress_minimum or v2 then 0 else 0.5
    local v4 = select(v3 - p5.magnitude, v3, p5.magnitude)

    if p5.sprint_pressed then
        p3.sprint_grace = 0.30000001192092896
    else
        p3.sprint_grace -= 0.01666666753590107
    end

    local v5 = p3.sprint_grace > 0
    local sprint_pressed = if not v5 then p5.sprint_pressed else nil

    if v5 or sprint_pressed then
        sprint_pressed = not p5.edge_active
    end

    p3.sprint_time = clamp(p3.sprint_time + (sprint_pressed and 0.01666666753590107 or -0.01666666753590107), 0, p4.sprint_time_cap)

    local v6 = PointGraph.evaluate(p4.sprint_speed, v4)
    local v7 = PointGraph.evaluate(p4.normal_speed, v4)
    local v8 = if sprint_pressed then PointGraph.evaluate(p4.sprint_blend, p3.sprint_time) else 0

    p3.speed = (1 - v8) * v7 + v8 * v6
    p3.secondary_speed = 0
    p3.steering = p5.steering
    p3.original_steering = p5.steering
    p3.edge_aligned = false

    local v9, v10, v11

    if not p5.obstacle or p5.ignore_obstacle or p3.speed <= 0 then
        p3.obstacle_centered = false

        if p5.sliding then
            t1.State.apply_slide(p3, p4, p5)
        elseif p5.edge_active and not (p3.speed <= 0) then
            local v15 = if p5.magnitude == 0 then rt.copy(p5.forward) else rt.copy(p5.direction)

            p3.edge_target = madd(if dot(p5.edge_tangent, v15) >= 0 then rt.copy(p5.edge_tangent) else scale(p5.edge_tangent, -1), 0.5, p5.edge_point)

            local v17 = sub(p3.edge_target, p5.position)

            if not (dot(horizontal(v15), horizontal(v17)) <= 0.8999999761581421) then
                p3.edge_aligned = true
                p3.steering = clamp(dot(normalize_or(v17, p5.forward), p5.right) * 0.5, -1, 1)
            end
        end
    else
        v9 = scale(p5.obstacle_normal, -1)
        v10 = wrap_angle(signed_angle(v9, p5.direction, { 0, 1, 0, 0 }))
        v11 = if p3.obstacle_centered then 55 else 25
        p3.obstacle_centered = v11 * 0.01745329238474369 > math.abs(v10)

        local v13 = wrap_angle(signed_angle(v9, p5.forward, { 0, 1, 0, 0 }))

        if not (math.abs(v13) >= HALF_PI) then
            local v14 = if p3.obstacle_centered then v13 * -0.6366197466850281 * 0.5 else (-v13 * 0.6366197466850281 + (if v10 <= 0 then -1 else 1)) * 0.5

            t1.State.merge_steering(p3, clamp(v14, -1, 1))

            if p3.obstacle_centered then
                p3.speed = 0
            end
        end
    end
end

function t1.State.merge_steering(p6, p7) -- line: 161
    -- upvalues: select (copy)
    if not (p6.steering * p7 >= 0) then
        p6.steering = p7

        return
    end

    local v19 = if p7 <= 0 then -1 else 1
    local v20 = p6.steering * v19
    local v21 = p7 * v19

    p6.steering = select(v20 - v21, v20, v21) * v19
end

function t1.State.apply_slide(p8, p9, p10) -- line: 172
    -- upvalues: PointGraph (copy), v1 (copy), HALF_PI (copy), select (copy), clamp (copy), wrap_angle (copy), projected_angle (copy)
    local v22 = wrap_angle(projected_angle(p10.slide_velocity, p10.forward, p10.up))
    local steering = p8.steering

    p8.speed = (1 - math.abs(steering)) * p8.speed

    local v23 = select(v22, 1, -1)

    if not (steering * v23 <= 0) then
        p8.steering = clamp((-v22 * v23 + 0.7853981573134661) / 0.7853981573134661, 0, 1) * steering
    end

    p8.steering = clamp(-PointGraph.evaluate(p9.slide_steering, v23 * (v22 * 0.31830987334251404)) * v23 + p8.steering, -1, 1)

    if not (math.abs(v22) >= HALF_PI) then
        p8.speed += v1.length(p10.slide_velocity)
    end
end

return t1
