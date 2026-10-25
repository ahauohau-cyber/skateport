-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local State = import("skate_core/player/wipeout_state/data").State
local v1 = import("skate_core/player/wipeout_state/body")
local v2 = import("skate_core/player/wipeout_state/drives")
local v3 = import("skate_core/player/wipeout_state/math")
local t1 = {}

function t1.response_normal(p1, p2) -- line: 18
    -- upvalues: rt (copy)
    if p1 ~= nil and p1[2] > 0 then
        return rt.copy(p1)
    end

    if p2 == nil or not (p2[2] > 0) then
        return { 0, 1, 0, 0 }
    end

    return rt.copy(p2)
end

function t1.trigger(p3, p4, p5, p6) -- line: 29
    -- upvalues: rt (copy), State (copy), v1 (copy), v3 (copy)
    p3.response_frames = 0
    p3.response_start_speed = v3.length(p3.velocity)

    local v4 = State.response_strength(p3)

    if p3.maximum_speed * 0.1 < 1 then
        p3.response_count = rt.wrapping_add_u32(p3.response_count, 1)
    else
        p3.response_count = 0
    end

    p3.maximum_speed = 0
    p3.extra_weight = 0
    p3.response_scalar = 0

    if v4 == 0 then
        return
    end

    p3.response_time = 0

    if v4 - 1 >= 0 then
        v4 = 1
    end

    p3.response_scalar = v4
    p3.extra_weight = v4

    local v5 = {
        p6[1],
        0,
        p6[2],
        0
    }
    local v6 = v3.dot(p5, v5)

    if v6 < 0 then
        v5 = v3.sub(v5, v3.scale(p5, v6))
    end

    local v7 = v3.scale(v3.madd(p5, 0, v3.scale(v5, 1.25)), v4)

    v1.add_velocity(p4, v7)
end

function t1.update_counter(p7, p8) -- line: 58
    -- upvalues: rt (copy), v3 (copy)
    p7.response_finished = false

    if p7.response_frames < 0 then
        return
    end

    p7.response_frames = rt.to_i32(rt.wrapping_add_u32(rt.to_u32(p7.response_frames), rt.to_u32(1)))

    if p7.response_frames == 3 then
        local v8 = if p7.response_start_speed < 1 then 1 - p7.response_start_speed else p7.response_start_speed * 0.2

        p7.response_change = (v3.length(p7.velocity) - p7.response_start_speed) * (v8 + 1)
    end

    if p7.response_frames ~= 8 then
        return
    end

    p7.response_frames = -1
    p7.response_finished = true

    if not p8 then
        p7.response_change = math.abs(p7.response_change) * 2
    end

    p7.response_change = v3.clamp((p7.response_change - 0.1) * 0.2, 0, 1)
end

function t1.retained_velocity(p9, p10, p11, p12, p13, p14, p15) -- line: 85
    -- upvalues: rt (copy), v2 (copy), t1 (copy)
    local v9 = bit32.band(p14, 8) ~= 0

    if p9.retained_velocity_active or v9 then
        if p13 then
            p9.allow_retained_velocity = false
            t1.release(p9, p10, p11, p12)
        elseif v9 then
            if not p9.retained_velocity_active and p9.allow_retained_velocity and p15[2] < 2 then
                v2.set_linear_root(p11, p12, 1)
                p9.retained_velocity_active = true
                p9.retained_velocity = rt.copy(p9.velocity)
            end
        else
            t1.release(p9, p10, p11, p12)
        end
    end

    if p9.retained_velocity_active then
        p9.velocity = rt.copy(p9.retained_velocity)
        p9.time -= 0.01666666753590107
    end
end

function t1.release(p16, p17, p18, p19) -- line: 105
    -- upvalues: v1 (copy), v2 (copy)
    if p16.retained_velocity_active then
        v2.set_linear_root(p18, p19, 0)
        v1.set_velocity(p17, p16.retained_velocity)
        p16.retained_velocity_active = false
        p16.velocity = { 0, 0, 0, 0 }
    end
end

return t1
