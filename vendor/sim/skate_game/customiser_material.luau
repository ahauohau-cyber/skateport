-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)
require(sim.import)

local t1 = {
    SkinStamp = {}
}

function t1.SkinStamp.default() -- line: 20
    return {
        texture = nil,
        transform = { 0, 0, 0, 0 },
        rectangle = { 0, 0, 0, 0 },
        enabled = { 0, 0, 0, 0 }
    }
end

function t1.placement(p1, p2) -- line: 31
    local t2 = {
        p1[3],
        1 - p1[1]
    }
    local t3 = {
        p1[4],
        1 - p1[2]
    }
    local t4 = {
        p2[3],
        1 - p2[1]
    }
    local t5 = {
        p2[4],
        1 - p2[2]
    }
    local t6 = {
        (t5[1] - t4[1]) / (t3[1] - t2[1]),
        (t5[2] - t4[2]) / (t3[2] - t2[2])
    }
    local t7 = {
        t4[1] - t2[1] * t6[1],
        t4[2] - t2[2] * t6[2]
    }

    return {
        t6[1],
        t6[2],
        t7[1],
        t7[2]
    }, {
        t2[1],
        t2[2],
        t3[1],
        t3[2]
    }
end

return t1
