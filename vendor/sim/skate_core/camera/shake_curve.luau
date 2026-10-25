-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local t1 = {}
local PERF = import("skate_core/camera/tracker").PERF

function t1.sample_reference(p1, p2) -- line: 14
    local t2 = {
        { -1, 3, -3, 1 },
        { 3, -6, 3, 0 },
        { -3, 3, 0, 0 },
        { 1, 0, 0, 0 }
    }
    local t3 = {}

    for i = 1, 4 do
        local v1 = t2[i]
        local t4 = {}

        for j = 0, 3 do
            t4[j + 1] = p1[4][j + 1] * v1[4] + (p1[3][j + 1] * v1[3] + (p1[2][j + 1] * v1[2] + p1[1][j + 1] * v1[1]))
        end

        t3[i] = t4
    end

    local function evaluate(p3, p4) -- line: 31
        -- upvalues: t3 (copy)
        return t3[4][p4 + 1] * p3[4] + (t3[3][p4 + 1] * p3[3] + (t3[2][p4 + 1] * p3[2] + t3[1][p4 + 1] * p3[1]))
    end

    local n1 = 0.5

    for i = 0, 9 do
        local v2 = n1 * n1
        local t5 = {
            v2 * n1,
            v2,
            n1,
            1
        }
        local v3 = t3[4][1] * t5[4] + (t3[3][1] * t5[3] + (t3[2][1] * t5[2] + t3[1][1] * t5[1]))
        local t6 = {
            v2 * n1,
            v2,
            n1,
            1
        }
        local v4 = t3[4][2] * t6[4] + (t3[3][2] * t6[3] + (t3[2][2] * t6[2] + t3[1][2] * t6[1]))
        local t7 = {
            v2 * 3,
            n1 * 2,
            1, 0
        }
        local v5 = t3[4][1] * t7[4] + (t3[3][1] * t7[3] + (t3[2][1] * t7[2] + t3[1][1] * t7[1]))
        local v6 = p2 - v3

        if i == 9 or not (math.abs(v6) > 0.009999999776482582) or not (math.abs(v5) > 1.1920928955078125E-07) then
            return v4
        end

        n1 = v6 / v5 + n1
    end

    error("internal error: entered unreachable code", 0)
end

function t1.sample(p5, p6) -- line: 70
    -- upvalues: t1 (copy), PERF (copy)
    if PERF.reference then
        return t1.sample_reference(p5, p6)
    end

    local v7 = p5[1]
    local v8 = p5[2]
    local v9 = p5[3]
    local v10 = p5[4]

    if type(v7[3]) == "number" and type(v7[4]) == "number" and type(v8[3]) == "number" and type(v8[4]) == "number" and type(v9[3]) == "number" and type(v9[4]) == "number" and type(v10[3]) == "number" and type(v10[4]) == "number" then
        local v19 = v7[1]
        local v20 = v8[1]
        local v21 = v9[1]
        local v22 = v10[1]
        local v23 = v7[2]
        local v24 = v8[2]
        local v25 = v9[2]
        local v26 = v10[2]
        local v27 = v22 * 1 + (v21 * -3 + (v20 * 3 + v19 * -1))
        local v28 = v22 * 0 + (v21 * 3 + (v20 * -6 + v19 * 3))
        local v29 = v22 * 0 + (v21 * 0 + (v20 * 3 + v19 * -3))
        local v30 = v22 * 0 + (v21 * 0 + (v20 * 0 + v19 * 1))
        local v31 = v26 * 1 + (v25 * -3 + (v24 * 3 + v23 * -1))
        local v32 = v26 * 0 + (v25 * 3 + (v24 * -6 + v23 * 3))
        local v33 = v26 * 0 + (v25 * 0 + (v24 * 3 + v23 * -3))
        local v34 = v26 * 0 + (v25 * 0 + (v24 * 0 + v23 * 1))
        local n2 = 0.5

        for i = 0, 9 do
            local v35 = n2 * n2
            local v36 = v35 * n2
            local v37 = v30 * 1 + (v29 * n2 + (v28 * v35 + v27 * v36))
            local v38 = v34 * 1 + (v33 * n2 + (v32 * v35 + v31 * v36))
            local v39 = v30 * 0 + (v29 * 1 + (v28 * (n2 * 2) + v27 * (v35 * 3)))
            local v40 = p6 - v37

            if i == 9 or not (math.abs(v40) > 0.009999999776482582) or not (math.abs(v39) > 1.1920928955078125E-07) then
                return v38
            end

            n2 = v40 / v39 + n2
        end

        error("internal error: entered unreachable code", 0)

        return
    end

    return t1.sample_reference(p5, p6)
end

return t1
