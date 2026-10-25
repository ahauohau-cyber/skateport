-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local reciprocal_estimate = require(sim.import)("skate_core/physics/native_arithmetic").reciprocal_estimate
local t1 = {
    FootPhysicalSettings = {},
    FootPhysicalState = {}
}

function t1.FootPhysicalState.default() -- line: 26
    return {
        previous_local_toes = {
            { 0, 0, 0, 0 },
            { 0, 0, 0, 0 }
        }
    }
end

t1.FootPhysicalOutput = {}

function t1.FootPhysicalOutput.default() -- line: 38
    return {
        local_velocity = {
            { 0, 0, 0, 0 },
            { 0, 0, 0, 0 }
        },
        world_velocity = {
            { 0, 0, 0, 0 },
            { 0, 0, 0, 0 }
        },
        within_deck_box = { false, false }
    }
end

function t1.FootPhysicalState.reset(p1) -- line: 46
    -- upvalues: rt (copy), t1 (copy)
    rt.assign(p1, t1.FootPhysicalState.default())
end

function t1.FootPhysicalState.update(p2, p3, p4, p5) -- line: 50
    -- upvalues: rt (copy), reciprocal_estimate (copy), t1 (copy)
    local v1 = t1.inverse_physical_board(p3.pose[1])
    local t2 = {
        t1.transform_point(v1, p3.pose[16][4]),
        t1.transform_point(v1, p3.pose[20][4])
    }
    local v2 = reciprocal_estimate(p4)
    local v3 = v2 * (-v2 * p4 + 1) + v2
    local v4 = v3 * (-v3 * p4 + 1) + v3
    local v5 = table.create(2)

    for i = 0, 1 do
        local v6 = table.create(4)

        for j = 0, 3 do
            v6[j + 1] = (t2[i + 1][j + 1] - p2.previous_local_toes[i + 1][j + 1]) * v4
        end

        v5[i + 1] = v6
    end

    p2.previous_local_toes = rt.copy(t2)

    local t3 = {
        p5.deck_half_width,
        0,
        p5.deck_total_half_length,
        0
    }
    local v7 = table.create(4)

    v7[1] = t3[1] + p5.padding[1]
    v7[2] = t3[2] + p5.padding[2]
    v7[3] = t3[3] + p5.padding[3]
    v7[4] = t3[4] + p5.padding[4]

    local v8 = table.create(2)

    for i = 1, 2 do
        local v9 = t2[i]

        if math.abs(v9[1]) < v7[1] then
            if math.abs(v9[2]) < v7[2] then
                v8[i] = math.abs(v9[3]) < v7[3]
            else
                v8[i] = false
            end
        else
            v8[i] = false
        end
    end

    return {
        local_velocity = v5,
        world_velocity = {
            rt.copy(p3.velocities[16]),
            rt.copy(p3.velocities[20])
        },
        within_deck_box = v8
    }
end

function t1.inverse_physical_board(p6) -- line: 92
    local t4 = {
        { 0, 0, 0, 0 },
        { 0, 0, 0, 0 },
        { 0, 0, 0, 0 },
        { 0, 0, 0, 0 }
    }

    for i = 0, 2 do
        t4[i + 1][1] = p6[1][i + 1]
        t4[i + 1][2] = p6[2][i + 1]
        t4[i + 1][3] = p6[3][i + 1]
    end

    for i = 0, 3 do
        local v13 = -p6[4][3] * t4[3][i + 1]
        local v14 = -p6[4][2] * t4[2][i + 1] + v13

        t4[4][i + 1] = -p6[4][1] * t4[1][i + 1] + v14
    end

    return t4
end

function t1.transform_point(p7, p8) -- line: 113
    local v15 = table.create(4)

    for i = 0, 3 do
        local v16 = p7[1][i + 1] * p8[1] + p7[4][i + 1]
        local v17 = p7[2][i + 1] * p8[2] + v16

        v15[i + 1] = p7[3][i + 1] * p8[3] + v17
    end

    return v15
end

return t1
