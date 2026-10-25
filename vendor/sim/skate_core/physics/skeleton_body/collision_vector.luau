-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/native_arithmetic")
local dot3 = v1.dot3
local estimate = import("skate_core/physics/reciprocal_sqrt").estimate
local t1 = {}

function t1.dot(p1, p2) -- line: 17
    -- upvalues: dot3 (copy)
    return dot3(p1, p2)
end

function t1.scale(p3, p4) -- line: 21
    return {
        p3[1] * p4,
        p3[2] * p4,
        p3[3] * p4,
        p3[4] * p4
    }
end

function t1.sub(p5, p6) -- line: 25
    return {
        p5[1] - p6[1],
        p5[2] - p6[2],
        p5[3] - p6[3],
        p5[4] - p6[4]
    }
end

function t1.add(p7, p8) -- line: 29
    return {
        p7[1] + p8[1],
        p7[2] + p8[2],
        p7[3] + p8[3],
        p7[4] + p8[4]
    }
end

function t1.inverse_length(p9) -- line: 33
    -- upvalues: estimate (copy)
    local v2 = estimate(p9)
    local v3 = v2 * 0.5 * (-p9 * (v2 * v2) + 1) + v2

    return v3 * 0.5 * (-p9 * (v3 * v3) + 1) + v3
end

function t1.length(p10) -- line: 41
    -- upvalues: t1 (copy)
    local v4 = t1.dot(p10, p10)
    local v5 = v4 * t1.inverse_length(v4)

    if v4 == 0 then
        return 0
    end

    return v5
end

function t1.normalize(p11) -- line: 47
    -- upvalues: t1 (copy)
    local v6 = t1.dot(p11, p11)
    local v7 = t1.inverse_length(v6)

    if (if v6 == 0 then 0 else v6 * v7) > 1E-06 then
        return t1.scale(p11, v7)
    end

    return table.create(4, 0)
end

function t1.clamp_length(p12, p13) -- line: 59
    -- upvalues: rt (copy), v1 (copy), t1 (copy)
    local v8 = t1.length(p12)

    if v8 < 1.52587890625E-05 then
        return rt.copy(p12)
    end

    local v9 = if p13 - v8 >= 0 then v8 else p13
    local v10 = v1.reciprocal_estimate(v8)
    local v11 = v10 * (-v10 * v8 + 1) + v10
    local v12 = v11 * (-v11 * v8 + 1) + v11

    return t1.scale(t1.scale(p12, v9), v12)
end

function t1.transform(p14, p15) -- line: 72
    local v13 = p14[1]
    local v14 = p14[2]
    local v15 = p14[3]
    local v16 = p14[4]
    local v17 = table.create(4)

    for i = 1, 4 do
        v17[i] = v15[i] * p15[3] + (v14[i] * p15[2] + (v13[i] * p15[1] + v16[i]))
    end

    return v17
end

function t1.cross(p16, p17) -- line: 81
    return {
        -p16[3] * p17[2] + p16[2] * p17[3],
        -p16[1] * p17[3] + p16[3] * p17[1],
        -p16[2] * p17[1] + p16[1] * p17[2],
        -p16[4] * p17[4] + p16[4] * p17[4]
    }
end

return t1
