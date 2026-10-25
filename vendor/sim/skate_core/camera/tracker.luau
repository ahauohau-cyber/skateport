-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)
require(sim.import)

local t1 = {
    PERF = {
        reference = false
    },
    ScalarTracker = {},
    ScalarTrackerParameters = {}
}

function t1.ScalarTracker.update(p1, p2, p3, p4) -- line: 33
    -- upvalues: t1 (copy)
    local position = p1.position
    local v1 = p3 - position

    p1.target = p3

    if p4.overshoot_zeroes_velocity and p1.velocity * v1 < 0 then
        p1.velocity *= 0
    end

    local velocity = p1.velocity
    local v2 = 1 / p2

    p1.acceleration = (v2 * v1 + -velocity) * v2

    local v3 = math.abs(v1)
    local v4 = if v3 < p4.delta_umbra then 1 elseif v3 < p4.delta_penumbra then 1 - (v3 - p4.delta_umbra) / (p4.delta_penumbra - p4.delta_umbra) else 0

    if p1.acceleration * v1 > 0 then
        local v5 = t1.interpolate(p4.acceleration_clamp_min, p4.acceleration_clamp_max, v4)

        p1.acceleration_clamp = v5

        local v6 = math.abs(p1.acceleration)

        if v5 < v6 then
            p1.acceleration = p1.acceleration / v6 * v5
        end
    end

    p1.velocity = p1.acceleration * p2 + velocity

    local v7 = math.abs(p1.velocity)

    if p4.speed_clamp < v7 then
        p1.velocity = p1.velocity / v7 * p4.speed_clamp
    end

    local v8 = p1.velocity * p2 + position

    p1.smoothing = t1.interpolate(p4.smoothing_min, p4.smoothing_max, v4)
    p1.position = (v8 - position) * (1 - p1.smoothing) + position
end

function t1.interpolate(p5, p6, p7) -- line: 77
    if p5 == p6 then
        return p6
    end

    return (p6 - p5) * p7 + p5
end

return t1
