-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/player/wipeout_state/math")
local dot, madd, scale, sub = v1.dot, v1.madd, v1.scale, v1.sub

local function parent() -- line: 15
    -- upvalues: import (copy)
    return import("skate_core/player/wipeout_state/contact_response")
end

local t1 = {
    STEP = 0.01666666753590107
}
local STEP = t1.STEP

t1.PHASE_DURATION = 0.032999999821186066

local PHASE_DURATION = t1.PHASE_DURATION

t1.Response = {}

local Response = t1.Response

function t1.Response.new() -- line: 37
    return {
        time = 0,
        phase = 0,
        finished = false,
        previous_velocity = { 0, 0, 0, 0 },
        normal = { 0, 1, 0, 0 },
        target_velocity = { 0, 0, 0, 0 }
    }
end

function t1.Response.reset(p1) -- line: 48
    -- upvalues: rt (copy), Response (copy)
    rt.assign(p1, Response.new())
end

function t1.Response.update(p2, p3, p4, p5) -- line: 53
    -- upvalues: rt (copy), import (copy), dot (copy), madd (copy), scale (copy), sub (copy), STEP (copy), Response (copy)
    if p5 ~= nil then
        p2.normal = rt.copy(p5)
    end

    p2.finished = false
    Response.select(p2, p5 ~= nil)

    local phase = p2.phase

    if phase == 0 then
        local v2 = sub(p4, p2.previous_velocity)

        if not (p2.time > 0.014999999664723873 and dot(v2, v2) > 1) then
            p2.previous_velocity = rt.copy(p4)
        else
            p2.previous_velocity = madd(p4, 0.05000000074505806, scale(p2.previous_velocity, 0.949999988079071))
        end
    elseif phase == 1 then
        local v3 = import("skate_core/player/wipeout_state/contact_response")
        local v4 = v3.reject_positive(scale(p4, -0.5), p2.normal)

        v3.apply_velocity_delta(p3, madd(p2.normal, -1, v4))
    elseif phase == 2 then
        import("skate_core/player/wipeout_state/contact_response").apply_velocity_delta(p3, scale(sub(p2.target_velocity, p4), 1))
        p2.target_velocity = madd({ 0, -9.800000190734863, 0, 0 }, STEP, p2.target_velocity)
    end

    p2.time += STEP
end

function t1.Response.select(p6, p7) -- line: 84
    -- upvalues: dot (copy), scale (copy), sub (copy), PHASE_DURATION (copy)
    local phase = p6.phase

    if phase ~= 0 or not p7 then
        if phase == 1 and p6.time > PHASE_DURATION then
            local v5 = scale(p6.normal, 2)

            phase = 2
            p6.target_velocity = scale(sub(p6.previous_velocity, scale(v5, dot(p6.previous_velocity, p6.normal))), 0.8999999761581421)
        elseif phase ~= 2 or not (p6.time > PHASE_DURATION) then
            if phase == 3 and not p7 then
                phase = 0
            end
        else
            phase = 3
            p6.finished = true
        end
    else
        phase = if -dot(p6.previous_velocity, p6.normal) > 2 then 1 else 4
    end

    if phase ~= p6.phase then
        p6.phase = phase
        p6.time = 0
    end
end

return t1
