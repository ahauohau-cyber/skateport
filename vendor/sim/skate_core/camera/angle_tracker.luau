-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

local function rtl_is_finite(p1) -- line: 6
    if p1 ~= p1 or p1 == 1e999 then
        return false
    end

    return p1 ~= (-1e999)
end

local v1 = require(sim.import)("skate_core/camera/tracker")
local t1 = {
    AngleTracker = {}
}

function t1.AngleTracker.update(p2, p3, p4, p5) -- line: 23
    -- upvalues: v1 (copy), t1 (copy)
    local v2 = p2[1]
    local position = v2.position

    v2.target = p4

    local v3 = t1.normalize_angle(p4 - position)

    if p5.overshoot_zeroes_velocity and v2.velocity * v3 < 0 then
        v2.velocity *= 0
    end

    local velocity = v2.velocity
    local v4 = 1 / p3

    v2.acceleration = (v4 * v3 + -velocity) * v4

    local v5 = math.abs(v3)
    local v6 = if v5 < p5.delta_umbra then 1 elseif v5 < p5.delta_penumbra then 1 - (v5 - p5.delta_umbra) / (p5.delta_penumbra - p5.delta_umbra) else 0

    if v2.acceleration * v3 > 0 then
        v2.acceleration_clamp = v1.interpolate(p5.acceleration_clamp_min, p5.acceleration_clamp_max, v6)

        local v7 = math.abs(v2.acceleration)

        if v2.acceleration_clamp < v7 then
            v2.acceleration = v2.acceleration / v7 * v2.acceleration_clamp
        end
    end

    v2.velocity = v2.acceleration * p3 + velocity

    local v8 = math.abs(v2.velocity)

    if p5.speed_clamp < v8 then
        v2.velocity = v2.velocity / v8 * p5.speed_clamp
    end

    local v9 = t1.normalize_angle(t1.normalize_angle(v2.velocity * p3) + position)

    v2.smoothing = v1.interpolate(p5.smoothing_min, p5.smoothing_max, v6)

    local v10 = t1.normalize_angle(v9 - position)
    local v11 = t1.normalize_angle(v10 * (1 - v2.smoothing))

    v2.position = t1.normalize_angle(v11 + position)
end

function t1.normalize_angle(p6) -- line: 73
    -- upvalues: rt (copy)
    if p6 >= -3.1415927410125732 and p6 < 3.1415927410125732 then
        return p6
    end

    local v12 = p6 * 0.15915493667125702

    if v12 ~= v12 or v12 == 1e999 or v12 == (-1e999) or v12 < -2147483648 or v12 > 2147483647 then
        error("Skate 3 exceptional angle integer conversion is unavailable: independent implementation required", 0)
    end

    local v13 = -(rt.f_to_i32(v12) * 6.2831854820251465 + -p6)

    if v13 >= 3.1415927410125732 then
        return v13 - 6.2831854820251465
    end

    if v13 < -3.1415927410125732 then
        return v13 + 6.2831854820251465
    end

    return v13
end

return t1
