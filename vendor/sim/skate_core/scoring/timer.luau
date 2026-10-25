-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

local t1 = {
    PointTimer = {}
}
local PointTimer = t1.PointTimer

function t1.PointTimer.default() -- line: 15
    return {
        points = 0,
        expired = false
    }
end

function t1.PointTimer.eq(p1, p2) -- line: 20
    if p1.points == p2.points then
        return p1.expired == p2.expired
    end

    return false
end

function t1.PointTimer.advance(p3, p4, p5, p6, p7) -- line: 25
    p3.expired = false

    if p3.points > 0 then
        local points = p3.points

        p3.points = -(p5 * p4 * p6 - p3.points)

        if p7 and p3.points < 1.001 and points > 1.000001 then
            p3.points = points

            return true
        end

        if p3.points <= 0 then
            p3.points = 0
            p3.expired = true
        end
    end

    return false
end

function t1.PointTimer.credit(p8, p9, p10) -- line: 42
    -- upvalues: rt (copy)
    p8.points = rt.fmin(p8.points + p9, p10)
end

function t1.PointTimer.seconds(p11, p12) -- line: 46
    return p11.points / p12
end

t1.ComboTimer = {}

function t1.ComboTimer.default() -- line: 53
    -- upvalues: PointTimer (copy)
    return {
        multiplier = 1,
        timer = PointTimer.default()
    }
end

function t1.ComboTimer.eq(p13, p14) -- line: 61
    -- upvalues: PointTimer (copy)
    return PointTimer.eq(p13.timer, p14.timer) and p13.multiplier == p14.multiplier
end

function t1.ComboTimer.credit(p15, p16, p17, p18, p19) -- line: 68
    -- upvalues: PointTimer (copy)
    PointTimer.credit(p15.timer, p16, p17)

    local n1 = 1

    for i = 1, #p18 do
        local v2 = p18[i][1]
        local v3 = p18[i][2]

        if v2 <= p15.timer.points then
            n1 = v3
        end
    end

    if p15.multiplier < n1 or p19 < p16 then
        p15.multiplier = n1
    end
end

return t1
