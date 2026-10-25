-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local dot3 = require(sim.import)("skate_core/physics/native_arithmetic").dot3
local t1 = {
    DT = 0.01666666753590107
}
local DT = t1.DT

t1.Settings = {}
t1.State = {}

local State = t1.State

function t1.State.response_strength(p1) -- line: 31
    -- upvalues: rt (copy)
    local v1 = p1.maximum_speed * 0.1
    local v2 = (rt.to_i32(rt.wrapping_sub_u32(4, p1.response_count)) + 1) * 0.5

    if not (v1 - v2 >= 0) then
        v1 = v2
    end

    if not (p1.slow_time > 1) and not (v1 <= 0.2) and not p1.special_surface and not p1.below_surface then
        return v1
    end

    return 0
end

function t1.State.manage_recovery(p2, p3, p4, p5, p6, p7) -- line: 43
    -- upvalues: DT (copy), State (copy)
    p2.prevent_manual = p2.prevent_manual or bit32.band(p3, 1) ~= 0
    p2.ignore_reset = p2.ignore_reset or bit32.band(p4, 2147483648) ~= 0
    p2.reset_ever = p2.reset_ever or bit32.band(p4, 1048576) ~= 0
    p2.ever_settled = p2.ever_settled or p2.over
    p2.recovery_eligible = p2.recovery_eligible or p2.ever_settled or p2.time > 1.6

    if p2.over then
        p2.settled_time += DT
    else
        p2.settled_time = 0
    end

    if p2.teleport_countdown < 0 and State.should_teleport(p2, p4, p5, p6, p7) then
        p2.teleport_countdown = 2
    end

    if p2.teleport_countdown == 0 then
        p2.request_teleport = true
    elseif p2.teleport_countdown > 0 then
        p2.teleport_countdown -= 1
    end
end

function t1.State.should_teleport(p8, p9, p10, p11, p12) -- line: 71
    -- upvalues: DT (copy)
    if p8.ever_impaled then
        p8.impaled_time += DT
    end

    if bit32.band(p10, 4194304) ~= 0 then
        p8.ever_impaled = true

        if p8.impaled_time > 0.5 then
            return true
        end
    end

    if not p8.prevent_manual then
        if p8.recovery_eligible and p8.reset_ever and not p8.ignore_reset then
            return true
        end

        if p8.teleport_pending then
            p8.time_until_teleport -= p11

            return p8.time_until_teleport <= 0
        end

        if if bit32.band(p9, 268435456) == 0 then p8.time > p12.maximum_time and p8.response_time > p12.maximum_time or p8.time > p12.minimum_time and p8.settled_time > p12.minimum_settled and p8.response_time > p12.minimum_settled else p8.time > 8 then
            p8.teleport_pending = true
            p8.time_until_teleport = p12.fade_time
        end
    end

    return false
end

function t1.State.post_physics(p13, p14, p15, p16, p17) -- line: 109
    -- upvalues: dot3 (copy), DT (copy), State (copy)
    local v3 = p13.extra_weight_zero_time > 0.5
    local v4 = if v3 then p17.over_speed * 2 else p17.over_speed
    local v5 = p13.time > p17.over_minimum_time
    local v6 = dot3(p14, p14)
    local v7 = dot3(p15, p15)
    local v8 = v6 < v4 * v4 and (if v7 < v4 * v4 or v3 then v5 and State.response_strength(p13) == 0 else v3)

    p13.over = v8
    p13.slow = v6 < 1 and v5

    if p16 then
        p13.no_support_time = 0
    else
        p13.no_support_time += DT
    end
end

return t1
