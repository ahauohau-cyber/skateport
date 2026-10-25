-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local PointGraph = require(sim.import)("skate_core/point_graph").PointGraph
local t1 = {}

t1.Settings = {}
t1.State = {}

function t1.State.reset_history(p1) -- line: 31
    for i = 1, #p1.history do
        p1.history[i] = 0
    end

    for _, v2 in p1.filters do
        for j = 4, #v2 - 1 do
            v2[j + 1] = 0
        end
    end
end

t1.Input = {}
t1.Output = {}

function t1.clamp(p2, p3, p4) -- line: 52
    local v3 = if p3 - p2 >= 0 then p3 else p2

    if p4 - v3 >= 0 then
        return v3
    end

    return p4
end

function t1.filter(p5, p6, p7) -- line: 62
    p5[1] = p6[1]
    p5[2] = p6[2]
    p5[3] = p6[3]
    p5[4] = p6[4]

    local v4 = p7 - p5[5]
    local v5 = p7 - p5[6]
    local v6 = 1 - p5[4]

    p5[6] = p7
    p5[9] = v5 * p5[4] + p5[9] * v6
    p5[7] = v4 * p5[4] + v6 * p5[7]

    local v7 = (p5[9] - p5[8]) * p5[3] + p5[2] * p5[7]
    local v8 = v4 * p5[1] + v7 + p5[5]

    p5[8] = v8 - p5[5]
    p5[5] = v8

    return v8
end

function t1.update(p8, p9, p10) -- line: 81
    -- upvalues: rt (copy), t1 (copy), PointGraph (copy)
    local v9 = rt.copy(p10.parameters)
    local v10 = if p9.animation_156 == 0 then 1 else -1
    local v11 = p9.bundle_32_field_264 * v10
    local v12 = t1.clamp(p9.body_160 / v9[12], 0, 1)
    local v13 = t1.clamp(p9.bundle_36_field_160 / v9[11] * v10, -1, 1)
    local v14 = PointGraph.evaluate(p10.input_curve, v12) * v11
    local v15 = (-(1 - v9[9]) * p9.body_176 + 1) * v13 * v9[10] + (1 - v9[10]) * v14
    local v16 = t1.filter(p8.filters[1], rt.copy(p10.filter_coefficients[1]), v15)

    if not (math.abs(v16) > 0.009999999776482582) then
        v16 = 0
    end

    local v17 = t1.filter(p8.filters[2], rt.copy(p10.filter_coefficients[2]), v15)

    if not (math.abs(v17) > 0.009999999776482582) then
        v17 = 0
    end

    local v18 = t1.filter(p8.filters[3], rt.copy(p10.filter_coefficients[3]), (v15 - v17) / v9[13])

    if p9.animation_152 == 0 then
        v11 = 0
    end

    local v19 = v11 - p8.history[1]

    p8.history[1] = v11
    p8.history[3] = math.abs(v19) * v9[3] + (1 - v9[3]) * p8.history[3]

    local v20 = p8.history[3] / v9[2]
    local v21 = v20 * v20

    if v21 - 1 >= 0 then
        v21 = 1
    end

    p8.history[4] = t1.clamp(v21, p8.history[4] - v9[1], p8.history[4] + v9[1])

    local v22 = PointGraph.evaluate(p10.quickness_curve, p8.history[4])
    local v23 = t1.clamp(v22, 0, 1)
    local v24 = PointGraph.evaluate(p10.speed_curve, p9.body_160) * v23

    if p9.animation_152 == 0 then
        v17 = 0
    end

    local v25 = v17 - p8.history[2]

    p8.history[2] = v17
    p8.history[6] = math.abs(v25) * v9[6] + (1 - v9[6]) * p8.history[6]

    local v26 = if p8.history[6] < v9[4] then 1 else 0
    local v27 = (1 - v26) * v9[8] + v9[7] * v26
    local v28 = (1 - v27) * p8.history[5] + v27 * v26 - p8.history[5]

    p8.history[7] = t1.clamp(v28, p8.history[7] - v9[5], p8.history[7] + v9[5])
    p8.history[5] = t1.clamp(p8.history[5] + p8.history[7], 0, 1)

    local v29 = PointGraph.evaluate(p10.smoothing_curve, p9.body_176)

    p8.history[8] = (1 - v29) * p8.history[8] + v29 * v16

    local v30 = t1.clamp(p8.history[8], -1, 1)

    return {
        v30,
        t1.clamp(v15, -1, 1),
        v14,
        v30 * v10,
        v14 * v10,
        v24,
        t1.clamp(v18, -1, 1),
        t1.clamp(p8.history[5], 0, 1)
    }
end

return t1
