-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

local t1 = {
    reciprocal_estimate = function(p1) -- reciprocal_estimate | line: 14
        return 1 / p1
    end,
    reciprocal_square_root_estimate = function(p2) -- reciprocal_square_root_estimate | line: 18
        return 1 / math.sqrt(p2)
    end,
    dot3 = function(p3, p4) -- dot3 | line: 22
        return p3[1] * p4[1] + p3[2] * p4[2] + p3[3] * p4[3]
    end
}

function t1.dot4(p5, p6) -- line: 26
    -- upvalues: t1 (copy)
    return t1.dot3(p5, p6) + p5[4] * p6[4]
end

function t1.vector_min(p7, p8) -- line: 30
    -- upvalues: rt (copy)
    return rt.fmin(p7, p8)
end

function t1.vector_max(p9, p10) -- line: 34
    -- upvalues: rt (copy)
    return rt.fmax(p9, p10)
end

return t1
