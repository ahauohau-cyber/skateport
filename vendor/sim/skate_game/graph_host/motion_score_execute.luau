-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1

local function motion_animation() -- line: 19
    -- upvalues: import (copy), v1 (ref)
    local v2 = v1

    if v2 == nil then
        v2 = import("skate_game/graph_host/motion_animation")
        v1 = v2
    end

    return v2
end

local v3

local function motion_scoring_trick() -- line: 28
    -- upvalues: import (copy), v3 (ref)
    local v4 = v3

    if v4 == nil then
        v4 = import("skate_game/graph_host/motion_scoring_trick")
        v3 = v4
    end

    return v4
end

local v5

local function motion_bump() -- line: 37
    -- upvalues: import (copy), v5 (ref)
    local v6 = v5

    if v6 == nil then
        v6 = import("skate_game/graph_host/motion_bump")
        v5 = v6
    end

    return v6
end

local t1 = {
    MotionHost = {}
}

function t1.MotionHost.execute_score_or_bump(p1, p2, p3) -- line: 51
    -- upvalues: rt (copy), import (copy), v1 (ref), v3 (ref), v5 (ref)
    if p2.tag == "ScoringTrick" then
        local score_packet = p1.score_packet
        local v7 = v3

        if v7 == nil then
            v7 = import("skate_game/graph_host/motion_scoring_trick")
            v3 = v7
        end

        score_packet.flags = v7.Operation.execute(p2[1], p1.score_packet.trick_names, p1.score_packet.flags, p3)
    else
        if p2.tag ~= "SetBumpCoefficients" then
            return false
        end

        local x, y = p2.x, p2.y

        if p3 == 0 then
            local bump_acceleration = p1.bump_acceleration

            if bump_acceleration == nil then
                error("SetBumpCoefficients requires completed acceleration", 0)
            end

            local skater_animation_flags = p1.animation.skater_animation_flags

            if skater_animation_flags == nil then
                error("SetBumpCoefficients requires actual stance", 0)
            end

            local v8 = v5

            if v8 == nil then
                v8 = import("skate_game/graph_host/motion_bump")
                v5 = v8
            end

            local v9 = v8.Settings.coefficients(p1.bump_settings, rt.copy(bump_acceleration), bit32.band(skater_animation_flags, 1073741824) ~= 0)
            local t2 = {
                rt.copy(x),
                rt.copy(y)
            }

            for i = 1, 2 do
                local v10 = v1

                if v10 == nil then
                    v10 = import("skate_game/graph_host/motion_animation")
                    v1 = v10
                end

                v10.MotionAnimation.set_attribute(p1.animation, {
                    normalized = false,
                    sequence_id = -1,
                    name = t2[i],
                    value = v9[i]
                })
            end
        end
    end

    return true
end

return t1
