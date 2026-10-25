-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = require(sim.import)("skate_core/trigonometry")
local t1 = {}

function t1.angles(p1, p2, p3) -- line: 15
    -- upvalues: rt (copy)
    local v2 = rt.fmin(p1 * 0.5, 1) * p2 * 0.06
    local v3 = v2 * 2
    local v4 = table.create(3)

    for i = 1, 3 do
        v4[i] = rt.irem(p3[i], 1E+05) * 1E-05 * v3 + -v2
    end

    return v4
end

function t1.apply(p4, p5, p6, p7) -- line: 27
    -- upvalues: rt (copy), v1 (copy), t1 (copy)
    local v5 = t1.angles(p5, p6, p7)
    local v6 = v5[1]
    local v7 = v5[2]
    local v8 = v5[3]
    local v9, v10 = v1.sin_cos(v6)
    local v11, v12 = v1.sin_cos(v7)
    local v13, v14 = v1.sin_cos(v8)
    local v15 = v9 * v14
    local v16 = v10 * v13
    local v17 = v10 * v14
    local v18 = v9 * v13
    local t2 = {
        {
            v12 * v14,
            v12 * v13,
            -v11
        },
        {
            v11 * v15 - v16,
            v11 * v18 + v17,
            v12 * v9
        },
        {
            v11 * v17 + v18,
            v11 * v16 - v15,
            v12 * v10
        }
    }
    local v19 = rt.copy(p4)

    for i = 0, 2 do
        local v20 = t2[i + 1]
        local v21 = table.create(4)

        for j = 0, 3 do
            v21[j + 1] = v20[3] * p4[3][j + 1] + (v20[2] * p4[2][j + 1] + v20[1] * p4[1][j + 1])
        end

        v19[i + 1] = v21
    end

    return v19
end

return t1
