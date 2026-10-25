-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)

local function state_mod() -- line: 9
    -- upvalues: import (copy)
    return import("skate_core/player/offboard/controller/state")
end

local t1 = {
    PlacementInput = {}
}
local dot, sub, length

t1.State = {}

function t1.State.place(p1, p2) -- line: 33
    -- upvalues: rt (copy), import (copy), t1 (copy), dot (ref), sub (ref), length (ref)
    if p2.current_state == 500 then
        import("skate_core/player/offboard/controller/state").State.reset(p1)

        local v1 = sub(p1.correction_target_592, p2.previous_frame[4])
        local v2

        if p2.previous_state ~= 501 or dot(p2.frame[3], v1) <= 0 then
            v2 = false
        else
            local dot2 = dot

            v2 = not (dot2(p2.frame[3], p2.previous_frame[3]) <= 0.8999999761581421)
        end

        if v2 then
            local v3 = sub(p2.previous_frame[4], p1.correction_target_592)
            local v4 = dot(p2.previous_frame[3], v3)
            local v5 = p2.previous_frame[3]

            p1.motion.correction_576 = {
                v5[1] * v4,
                v5[2] * v4,
                v5[3] * v4,
                v5[4] * v4
            }
            p1.motion.correction_enabled_711 = true
        else
            t1.State.clear_entry_correction(p1)
        end
    elseif p2.current_state == 501 then
        t1.State.clear_entry_correction(p1)
    end

    p1.motion.frame_0 = rt.copy(p2.frame)
    p1.motion.published_frame_64 = rt.copy(p2.frame)
    p1.frame_output.frame = rt.copy(p2.frame)
    p1.position_368 = rt.copy(p2.body_position)
    p1.motion.velocity_480 = rt.copy(p2.velocity)
    p1.motion.speed_704 = length(p2.velocity)
    p1.surface.spring_normal = rt.copy(p2.frame[2])
    p1.surface.spring_delta = rt.copy(import("skate_core/player/offboard/controller/state").ZERO)
end

function t1.State.clear_entry_correction(p3) -- line: 63
    -- upvalues: rt (copy), import (copy)
    local ZERO = import("skate_core/player/offboard/controller/state").ZERO

    p3.motion.correction_576 = rt.copy(ZERO)
    p3.correction_target_592 = rt.copy(ZERO)
    p3.motion.correction_enabled_711 = false
end

function t1.dot(p4, p5) -- line: 70
    return p4[1] * p5[1] + p4[2] * p5[2] + p4[3] * p5[3]
end

dot = t1.dot

function t1.sub(p6, p7) -- line: 75
    return {
        p6[1] - p7[1],
        p6[2] - p7[2],
        p6[3] - p7[3],
        p6[4] - p7[4]
    }
end

sub = t1.sub

function t1.length(p8) -- line: 80
    -- upvalues: dot (ref)
    local v6 = dot(p8, p8)
    local v7 = 1 / math.sqrt(v6)
    local v8 = v7 * 0.5 * (-v6 * (v7 * v7) + 1) + v7
    local v9 = v6 * (v8 * 0.5 * (-v6 * (v8 * v8) + 1) + v8)

    if v6 == 0 then
        return 0
    end

    return v9
end

length = t1.length

return t1
