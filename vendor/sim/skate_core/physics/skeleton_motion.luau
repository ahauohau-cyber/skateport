-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/native_arithmetic")
local v2 = import("skate_core/physics/skeleton_animation_record")
local reciprocal_estimate = v1.reciprocal_estimate
local IDENTITY, compose_affine = v2.IDENTITY, v2.compose_affine
local t1 = {
    SkeletonMotion = {}
}

function t1.SkeletonMotion.default() -- line: 25
    -- upvalues: rt (copy), IDENTITY (copy)
    return {
        previous_board_at_y = 0,
        trajectory = rt.copy(IDENTITY),
        inverse_trajectory = rt.copy(IDENTITY),
        next_trajectory = rt.copy(IDENTITY),
        velocity_world = { 0, 0, 0, 0 }
    }
end

function t1.SkeletonMotion.reset_board_orientation_history(p1) -- line: 37
    p1.previous_board_at_y = 0
end

function t1.SkeletonMotion.process_trajectory(p2, p3, p4, p5) -- line: 43
    -- upvalues: rt (copy), reciprocal_estimate (copy), compose_affine (copy)
    p2.trajectory = compose_affine(p3, p2.next_trajectory)
    p2.next_trajectory = rt.copy(p2.trajectory)

    local v3 = reciprocal_estimate(p5)
    local v4 = v3 * (-v3 * p5 + 1) + v3
    local v5 = v4 * (-v4 * p5 + 1) + v4
    local t2 = {
        p2.trajectory[4][1] * v5,
        p2.trajectory[4][2] * v5,
        p2.trajectory[4][3] * v5,
        p2.trajectory[4][4] * v5
    }
    local v6 = table.create(4)

    for i = 0, 3 do
        local v7 = p4[1][i + 1] * t2[1]
        local v8 = p4[2][i + 1] * t2[2] + v7

        v6[i + 1] = p4[3][i + 1] * t2[3] + v8
    end

    p2.velocity_world = v6

    local v9 = rt.copy(p2.trajectory)
    local v10 = table.create(4)

    for i = 0, 3 do
        if i < 3 then
            v10[i + 1] = {
                v9[1][i + 1],
                v9[2][i + 1],
                v9[3][i + 1],
                0
            }
        else
            v10[i + 1] = { 0, 0, 0, 0 }
        end
    end

    p2.inverse_trajectory = v10

    local v11 = table.create(4)

    for i = 0, 3 do
        local v12 = (0 - v9[4][3]) * p2.inverse_trajectory[3][i + 1]
        local v13 = (0 - v9[4][2]) * p2.inverse_trajectory[2][i + 1] + v12

        v11[i + 1] = (0 - v9[4][1]) * p2.inverse_trajectory[1][i + 1] + v13
    end

    p2.inverse_trajectory[4] = v11
end

function t1.SkeletonMotion.publish_unadjusted_board(p6, p7) -- line: 86
    if math.abs(p6[1][2]) > 0.7099999785423279 then
        return (bit32.bor(p7, 32768))
    end

    return p7
end

function t1.SkeletonMotion.publish_adjusted_board(p8, p9, p10) -- line: 96
    local v15 = p9[3][2]
    local v16 = v15 - p8.previous_board_at_y

    p8.previous_board_at_y = v15

    local v17 = v15 > 0

    return v16, (bit32.bor(bit32.band(p10, 4294961151), bit32.lshift(if v17 then 1 else 0, 12), (bit32.lshift(if v17 then 0 else 1, 11))))
end

return t1
