-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local PointGraph = import("skate_core/point_graph").PointGraph
local v1 = import("skate_core/trigonometry")
local v2 = import("skate_core/player/offboard/movement_velocity/math")
local select, clamp, dot, scale = v2.select, v2.clamp, v2.dot, v2.scale
local sub, madd, length, normalize_or = v2.sub, v2.madd, v2.length, v2.normalize_or
local limit_delta, remove_positive = v2.limit_delta, v2.remove_positive
local t1 = {
    Settings = {},
    State = {}
}

function t1.State.default() -- line: 40
    return {
        turn = 0,
        forward_delta = 0,
        right_delta = 0,
        speed = 0,
        override_remaining = -1,
        velocity = { 0, 0, 0, 0 }
    }
end

function t1.State.eq(p1, p2) -- line: 52
    if p1.velocity[1] ~= p2.velocity[1] or p1.velocity[2] ~= p2.velocity[2] or p1.velocity[3] ~= p2.velocity[3] or p1.velocity[4] ~= p2.velocity[4] then
        return false
    end

    if p1.turn == p2.turn and p1.forward_delta == p2.forward_delta and p1.right_delta == p2.right_delta and p1.speed == p2.speed then
        return p1.override_remaining == p2.override_remaining
    end

    return false
end

t1.Input = {}

function t1.State.update(p3, p4, p5) -- line: 81
    -- upvalues: rt (copy), PointGraph (copy), v1 (copy), select (copy), clamp (copy), dot (copy), scale (copy), sub (copy), madd (copy), length (copy), normalize_or (copy), limit_delta (copy), remove_positive (copy)
    local v4 = normalize_or(sub(p5.forward, scale(p5.plane_normal, dot(p5.forward, p5.plane_normal))), p5.forward)
    local v5 = v1.asin(v4[2]) * 57.295780181884766
    local v6

    if p5.slope_mode then
        v6 = PointGraph.evaluate(p4.slope_mode_speed, (math.abs(v5)))
    else
        v6 = PointGraph.evaluate(p4.slope_speed_scalar, v5) * p5.desired_speed

        if not (p5.desired_speed <= 0.5) and not (p3.speed <= v6) then
            local v7 = if p3.velocity[2] > 0 then -0.16333334503074504 * select(-v4[2], 0, v4[2]) else 0
            local v8 = v6 - p3.speed
            local v9 = select(v8 - -2, v8, -2) * 0.01666666753590107

            v6 = p3.speed + select(v7 - v9, v9, v7)
        end
    end

    local v10 = rt.copy(p3.velocity)
    local v11 = madd(v10, 0, scale(v4, v6))
    local v12 = PointGraph.evaluate(p4.turn_vs_speed, p3.speed) * p5.steering * 0.01745329238474369 + -p3.turn
    local v13 = if p5.slope_mode then 0.5 else 0.20000000298023224

    if p5.override_gate < 0 or p5.slope_mode then
        p3.override_remaining = -1
    else
        local v14 = p3.override_remaining < 0

        if v14 then
            p3.override_remaining = p5.override_duration
        end

        local v15 = (if p5.override_duration < 0.0010000000474974513 then 0 else p3.override_remaining / p5.override_duration) * 1.25
        local v16 = select(1 - v15, v15, 1)

        if not (v14 or length(p5.override_velocity) <= length(v10) * 1.100000023841858) then
            v16 = select(v16 - 0.5, 0.5, v16)
        end

        v11 = madd(v10, v16, scale(p5.override_velocity, 1 - v16))

        if bit32.band(p5.flags, 8) ~= 0 then
            local v17 = length(v11)

            if v17 >= 0.009999999776482582 then
                if not (v17 >= 1) then
                    v11 = scale(v11, 1 / v17)
                end
            else
                v11 = scale(v4, 1)
            end
        end

        local v18 = p3.override_remaining - 0.01666666753590107

        v13 = 100
        p3.override_remaining = select(-v18, 0, v18)
    end

    local v19 = PointGraph.evaluate(p4.turn_delta_vs_speed, p3.speed) * 0.01745329238474369
    local v20 = limit_delta(v11, v10, v13)

    p3.turn += clamp(v12, -v19, v19)

    if p5.obstacle then
        local v21 = scale(p5.obstacle_normal, -1)

        v11 = remove_positive(v11, v21)
        v20 = remove_positive(v20, v21)
    end

    p3.right_delta = dot(sub(v20, v10), p5.right)
    p3.forward_delta = dot(sub(v11, v10), p5.forward)
    p3.velocity = v20
    p3.speed = length(v20)
end

return t1
