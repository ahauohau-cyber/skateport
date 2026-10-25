-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)
require(sim.import)

local t1 = {
    dot = function(p1, p2) -- dot | line: 11
        return p1[1] * p2[1] + p1[2] * p2[2] + p1[3] * p2[3]
    end
}
local dot = t1.dot

function t1.sub(p3, p4) -- line: 16
    return {
        p3[1] - p4[1],
        p3[2] - p4[2],
        p3[3] - p4[3],
        p3[4] - p4[4]
    }
end

local sub = t1.sub

function t1.madd(p5, p6, p7) -- line: 21
    return {
        p5[1] * p6 + p7[1],
        p5[2] * p6 + p7[2],
        p5[3] * p6 + p7[3],
        p5[4] * p6 + p7[4]
    }
end

local madd = t1.madd

function t1.length(p8) -- line: 26
    -- upvalues: dot (copy)
    local v1 = dot(p8, p8)
    local v2 = 1 / math.sqrt(v1)
    local v3 = v2 * 0.5 * (-v1 * (v2 * v2) + 1) + v2
    local v4 = v3 * 0.5 * (-v1 * (v3 * v3) + 1) + v3

    if v1 == 0 then
        return 0
    end

    return v1 * v4
end

function t1.reciprocal(p9) -- line: 39
    local v5 = 1 / p9
    local v6 = v5 * (-v5 * p9 + 1) + v5

    return v6 * (-v6 * p9 + 1) + v6
end

function t1.point(p10, p11) -- line: 47
    -- upvalues: madd (copy)
    return madd(p10[3], p11[3], madd(p10[2], p11[2], madd(p10[1], p11[1], p10[4])))
end

function t1.direction(p12, p13) -- line: 51
    -- upvalues: madd (copy)
    local v7 = p12[1]

    return madd(p12[3], p13[3], madd(p12[2], p13[2], {
        v7[1] * p13[1],
        v7[2] * p13[1],
        v7[3] * p13[1],
        v7[4] * p13[1]
    }))
end

function t1.sphere_segment(p14, p15, p16, p17) -- line: 57
    -- upvalues: dot (copy), sub (copy)
    local v8 = sub(p14, p16)
    local v9 = p15 * p15

    if dot(v8, v8) < v9 then
        return true
    end

    local v10 = sub(p17, p16)
    local v11 = dot(v8, v10)

    if not (v11 > 0) then
        return false
    end

    local v12 = dot(v10, v10)
    local t2 = {
        -v8[3] * v10[2] + v8[2] * v10[3],
        -v8[1] * v10[3] + v8[3] * v10[1],
        -v8[2] * v10[1] + v8[1] * v10[2],
        0
    }
    local v13 = v12 * v9 - dot(t2, t2)
    local v14 = v11 - v12

    return not (v13 < 0 or v14 > 0 and v13 < v14 * v14)
end

return t1
