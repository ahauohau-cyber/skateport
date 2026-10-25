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

require(sim.import)

local t1 = {
    ClipClock = {},
    AdvanceResult = {}
}

function t1.AdvanceResult.default() -- line: 32
    return {
        crossed_end = false,
        overshoot = 0,
        remaining_before_wrap = 0
    }
end

function t1.AdvanceResult.eq(p2, p3) -- line: 37
    if p2.crossed_end == p3.crossed_end and p2.overshoot == p3.overshoot then
        return p2.remaining_before_wrap == p3.remaining_before_wrap
    end

    return false
end

function t1.ClipClock.set_time(p4, p5) -- line: 43
    p4.time = p5
    p4.previous_time = p5
    p4.loops_since_evaluation = 0
end

function t1.ClipClock.set_speed(p6, p7) -- line: 51
    local v1 = p6.base_speed * p7
    local v2 = p6.speed * p6.base_speed
    local v3 = p6.fps * p6.base_speed
    local v4 = 1 / v1

    p6.time = p6.time * v2 * v4
    p6.previous_time = p6.previous_time * v2 * v4
    p6.length = (p6.frames - 1) / (v3 * p7)
    p6.speed = p7
end

function t1.ClipClock.sample_time(p8) -- line: 62
    if p8.length - p8.time >= 0 then
        return p8.time
    end

    return p8.length
end

function t1.ClipClock.advance(p9, p10, p11, p12) -- line: 71
    -- upvalues: rt (copy)
    if p9.phase_controlled then
        p9.previous_time = p9.time

        local v5 = if -p11 >= 0 then 0 else p11

        if not (1 - v5 >= 0) then
            v5 = 1
        end

        p9.time = p9.length * v5
        p9.loops_since_evaluation = p9.time < p9.previous_time and 1 or 0
    else
        p9.time += p10
        p12.remaining_before_wrap = p9.length - p9.time

        if p9.time > p9.length then
            if p9.looping then
                local v6 = false

                if p9.length > 0 then
                    local time = p9.time

                    v6 = time == time and time ~= 1e999 and time ~= (-1e999)
                end

                if not v6 then
                    error("invalid looping clip clock", 0)
                end

                while p9.time > p9.length do
                    p12.crossed_end = true
                    p12.overshoot = p9.time - p9.length

                    local v7 = p9.time - p9.length

                    if not (v7 < p9.time) then
                        error("clip clock cannot advance at this precision", 0)
                    end

                    p9.time = v7
                    p9.loops_since_evaluation = rt.wrapping_add_u32(p9.loops_since_evaluation, 1)
                end
            else
                p12.crossed_end = true
                p12.overshoot = p9.time - p9.length
            end
        else
            p12.crossed_end = false
        end
    end
end

function t1.ClipClock.commit_evaluation(p13) -- line: 110
    p13.previous_time = p13.time
    p13.loops_since_evaluation = 0
end

function t1.ClipClock.attribute_status(p14, p15, p16) -- line: 117
    if p15 == -1 then
        return 6
    end

    local v8 = p14.length * p15
    local v9 = p14.length * p16

    if not (if p14.loops_since_evaluation == 0 then p14.previous_time < v9 and v8 <= p14.time else p14.previous_time < v9 or v8 <= p14.time) then
        return 17
    end

    if p14.time < v8 or v9 < p14.time then
        return 9
    end

    return 5
end

return t1
