-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)

local function mass() -- line: 14
    -- upvalues: import (copy)
    return import("skate_core/physics/mass")
end

local t1 = {}

function t1.diagonalize(p1) -- line: 23
    -- upvalues: t1 (copy)
    local t2 = {
        { 1, 0, 0 },
        { 0, 1, 0 },
        { 0, 0, 1 }
    }
    local n1 = 10

    while true do
        local t3 = {
            p1[1][1] * p1[1][1],
            p1[2][2] * p1[2][2],
            p1[3][3] * p1[3][3]
        }
        local v1 = if t3[2] > t3[1] then if t3[3] > t3[1] then t3[1] else t3[3] elseif t3[3] > t3[2] then t3[2] else t3[3]

        if p1[3][2] * p1[3][2] + (p1[2][1] * p1[2][1] + p1[3][1] * p1[3][1]) > v1 * 1E-24 then
            if n1 == 0 then
                break
            end

            for i = 1, 2 do
                for j = 0, i - 1 do
                    local v2, v3 = t1.rotation(p1, i, j)

                    t1.rotate_columns(t2, i, j, v2, v3)
                    t1.rotate_columns(p1, i, j, v2, v3)
                    t1.rotate_rows(p1, i, j, v2, v3)
                end
            end

            n1 -= 1
            continue
        end

        break
    end

    return t2
end

function t1.rotation(p2, p3, p4) -- line: 66
    -- upvalues: import (copy)
    local v4 = p2[p3 + 1][p4 + 1]

    if v4 == 0 then
        return 0, 1
    end

    local v5 = p2[p4 + 1][p4 + 1] - p2[p3 + 1][p3 + 1]
    local v6 = import("skate_core/physics/mass").refined_reciprocal(v4) * (v5 * 0.5)
    local v8 = math.sqrt(v6 * v6 + 1)
    local v9 = if v6 > 0 then 1 / (v8 + v6) else -1 / (v8 - v6)
    local v11 = 1 / math.sqrt(v9 * v9 + 1)

    return v11 * v9, v11
end

function t1.rotate_columns(p5, p6, p7, p8, p9) -- line: 86
    for i = 1, #p5 do
        local v12 = p5[i]
        local v13 = v12[p6 + 1]
        local v14 = v12[p7 + 1]

        v12[p6 + 1] = v13 * p9 - v14 * p8
        v12[p7 + 1] = v13 * p8 + v14 * p9
    end
end

function t1.rotate_rows(p10, p11, p12, p13, p14) -- line: 97
    -- upvalues: rt (copy)
    local v15 = rt.copy(p10[p11 + 1])
    local v16 = rt.copy(p10[p12 + 1])

    for i = 0, 2 do
        p10[p11 + 1][i + 1] = v15[i + 1] * p14 - v16[i + 1] * p13
        p10[p12 + 1][i + 1] = v15[i + 1] * p13 + v16[i + 1] * p14
    end
end

return t1
