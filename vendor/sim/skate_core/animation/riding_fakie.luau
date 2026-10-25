-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local v1 = require(sim.import)("skate_core/physics/native_arithmetic")
local t1 = {
    Settings = {}
}

function t1.Settings.eq(p1, p2) -- line: 19
    if p1.high_speed == p2.high_speed and p1.low_speed == p2.low_speed and p1.slowly_backwards_seconds == p2.slowly_backwards_seconds then
        return p1.after_teleport_seconds == p2.after_teleport_seconds
    end

    return false
end

t1.Physical = {}
t1.State = {}

function t1.State.default() -- line: 38
    return {
        slowly_backwards = 0,
        after_teleport = 0
    }
end

function t1.State.update(p3, p4, p5, p6) -- line: 44
    -- upvalues: v1 (copy)
    local v2

    if p4.category == 5 then
        v2 = false
        p3.after_teleport = 0
    else
        v2 = p3.after_teleport > p6.after_teleport_seconds
        p3.after_teleport += p5
    end

    if not v2 then
        p3.slowly_backwards = 0

        return false
    end

    if (p4.category == 1 or p4.category == 2 or p4.category == 6 and p4.grind_state == 503) and not p4.doing_trick then
        local v3 = if p4.category == 1 then p4.deck_velocity else p4.external_velocity
        local v4 = v1.dot3(v3, p4.board_axis)

        if not (p4.ground_projected_speed > p6.high_speed and v4 < -0.5) then
            if p4.ground_projected_speed > p6.low_speed and v4 < -0.5 then
                p3.slowly_backwards = p5 + p3.slowly_backwards

                return p3.slowly_backwards > p6.slowly_backwards_seconds
            end

            p3.slowly_backwards = 0

            return false
        end

        p3.slowly_backwards = 0

        return true
    end

    p3.slowly_backwards = 0

    return if p4.category ~= 1 and p4.category ~= 2 then false else nil
end

return t1
