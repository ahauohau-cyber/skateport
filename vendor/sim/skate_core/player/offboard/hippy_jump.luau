-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

local t1 = {
    Input = {}
}

function t1.calculate(p1) -- line: 25
    -- upvalues: rt (copy), t1 (copy)
    local v1 = rt.copy(p1.reference_up)
    local v2 = t1.sub(p1.centre_of_mass_position, p1.board_position)
    local v3 = t1.dot3(v1, v2)
    local v4 = t1.dot3(v1, p1.current_velocity)
    local v5 = t1.sub(p1.current_velocity, t1.scale(v1, v4))
    local v7 = math.sqrt((p1.desired_height - v3) * 19.6)

    return t1.add(v5, t1.scale(v1, v7))
end

function t1.dot3(p2, p3) -- line: 35
    return p2[1] * p3[1] + (p2[2] * p3[2] + p2[3] * p3[3])
end

function t1.add(p4, p5) -- line: 39
    return {
        p4[1] + p5[1],
        p4[2] + p5[2],
        p4[3] + p5[3],
        p4[4] + p5[4]
    }
end

function t1.sub(p6, p7) -- line: 43
    return {
        p6[1] - p7[1],
        p6[2] - p7[2],
        p6[3] - p7[3],
        p6[4] - p7[4]
    }
end

function t1.scale(p8, p9) -- line: 47
    return {
        p8[1] * p9,
        p8[2] * p9,
        p8[3] * p9,
        p8[4] * p9
    }
end

return t1
