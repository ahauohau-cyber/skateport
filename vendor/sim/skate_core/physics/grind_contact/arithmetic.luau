-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local v1 = require(sim.import)("skate_core/physics/native_arithmetic")
local t1 = {}

function t1.reciprocal(p1) -- line: 13
    -- upvalues: v1 (copy)
    local v2 = v1.reciprocal_estimate(p1)
    local v3 = v2 * (-v2 * p1 + 1) + v2

    return v3 * (-v3 * p1 + 1) + v3
end

function t1.inverse_square_root(p2) -- line: 22
    -- upvalues: v1 (copy)
    local v4 = v1.reciprocal_square_root_estimate(p2)
    local v5 = v4 * v4
    local v6 = v4 * 0.5 * (-p2 * v5 + 1) + v4
    local v7 = v6 * v6

    return v6 * 0.5 * (-p2 * v7 + 1) + v6
end

function t1.square_root(p3) -- line: 33
    -- upvalues: t1 (copy)
    local v8 = p3 * t1.inverse_square_root(p3)

    if p3 == 0 then
        return 0
    end

    return v8
end

return t1
