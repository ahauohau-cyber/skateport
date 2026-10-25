-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

local t1 = {
    GrindInputState = {}
}

function t1.GrindInputState.permission(p1, p2, p3) -- line: 18
    -- upvalues: rt (copy), t1 (copy)
    local state_2508 = p2.state_2508

    if state_2508 ~= p1.previous_state then
        local v1 = if state_2508 == 400 or state_2508 == 402 or state_2508 == 404 then 50 elseif state_2508 == 403 then 20 else 0

        p1.engagement_counter = rt.wrapping_add_u32(p1.engagement_counter, v1)
        p1.previous_state = state_2508
    end

    p1.engagement_counter = t1.decrement(p1.engagement_counter)
    p1.suppressed = p1.engagement_counter > 151

    if p1.suppressed then
        p1.cooldown = 90
    else
        p1.cooldown = t1.decrement(p1.cooldown)
    end

    local flags_2468 = p2.flags_2468
    local v2 = bit32.band(flags_2468, 402653184) ~= 0
        or bit32.band(p2.flags_2472, 32776) ~= 0
        or bit32.band(p2.flags_2476, 4194304) ~= 0
        or p1.cooldown > 0
        or p2.category_2512 == 200 and (p2.state_timer_2664 <= 0.07999999821186066 or p3 <= 10)
        or p2.category_2512 == 500
        or bit32.band(p2.flags_2472, 4) ~= 0 and p2.category_2512 ~= 400

    p1.disabled = v2

    if p2.category_2512 == 400 or state_2508 == 701 then
        p1.elapsed += p2.timestep_2604
    else
        p1.elapsed = 0
    end
end

function t1.GrindInputState.advance_history(p4, p5) -- line: 55
    -- upvalues: rt (copy), t1 (copy)
    if p4.previous_proximity and p5.state_2508 == 100 and rt.to_i32(p5.wheel_count_2556) < 2 and p5.scalar_2652 < 0.8 then
        p4.low_wheel_frames = rt.wrapping_add_u32(p4.low_wheel_frames, 1)
    else
        p4.low_wheel_frames = 0
    end

    if p5.grind_words_2532_2536[2] == 2 then
        p4.grind_history = 70
    else
        p4.grind_history = t1.decrement(p4.grind_history)
    end

    p4.secondary_history = t1.decrement(p4.secondary_history)

    if p5.category_2512 == 100 then
        p4.grounded_frames = rt.wrapping_add_u32(p4.grounded_frames, 1)
    else
        p4.grounded_frames = 0
    end

    if p5.category_2512 == 100 then
        p4.air_frames = 0
    else
        p4.air_frames = rt.wrapping_add_u32(p4.air_frames, 1)
    end
end

function t1.GrindInputState.material_mode(p6, p7, p8, p9) -- line: 86
    if p7.state_2508 == 300 or p7.category_2512 == 500 then
        return "Unchanged"
    end

    local previous_air_target = if p8 then p7.state_2508 == 200 or p7.state_2508 == 201 or p7.category_2512 == 400 or p7.state_2508 == 701 or p7.category_2512 == 100 and p6.previous_air_target else p7.category_2512 == 400 or p7.state_2508 == 701 or p7.category_2512 == 100 and p6.previous_air_target

    if p7.state_2508 == 201 then
        p6.previous_air_target = p9
    else
        p6.previous_air_target = false
    end

    if previous_air_target then
        return "Grind"
    end

    return "Standard"
end

function t1.decrement(p10) -- line: 102
    -- upvalues: rt (copy)
    local v3 = rt.wrapping_sub_u32(p10, 1)

    if bit32.band(v3, 2147483648) == 0 then
        return v3
    end

    return 0
end

return t1
