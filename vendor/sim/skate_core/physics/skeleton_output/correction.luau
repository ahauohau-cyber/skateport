-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/native_arithmetic")
local dot3, vector_min = v1.dot3, v1.vector_min
local SkeletonBody = import("skate_core/physics/skeleton_body").SkeletonBody
local t1 = {
    CorrectionState = {}
}

function t1.CorrectionState.default() -- line: 22
    return {
        pending = false,
        board_prediction_error = table.create(4, 0)
    }
end

function t1.CorrectionState.observe_board(p1, p2, p3) -- line: 31
    p1.board_prediction_error = {
        p2[1] - p3[1],
        p2[2] - p3[2],
        p2[3] - p3[3],
        p2[4] - p3[4]
    }
end

function t1.CorrectionState.apply(p4, p5, p6, p7, p8, p9) -- line: 40
    -- upvalues: rt (copy), t1 (copy)
    p4.pending = t1.apply(p5, p4.pending, rt.copy(p4.board_prediction_error), p6, p7, p8, p9)
end

function t1.apply(p10, p11, p12, p13, p14, p15, p16) -- line: 56
    -- upvalues: rt (copy), dot3 (copy), vector_min (copy), SkeletonBody (copy)
    if not p14 or bit32.band(p16, 1073741824) == 0 then
        if p14 or bit32.band(p15, 262144) ~= 0 or not p11 then
            return p11
        end

        local v2 = dot3(p12, p13)
        local v3 = vector_min(0, v2)
        local v4 = rt.from_fn(4, function(p17) -- line: 80
            -- upvalues: p12 (copy), p13 (copy), v2 (copy), v3 (copy)
            local v5 = p12[p17 + 1] - p13[p17 + 1] * v2

            return p13[p17 + 1] * v3 + v5
        end)

        for i = 1, 23 do
            local v6 = p10.record.pose[i + 1][4]

            v6[1] += v4[1]
            v6[2] += v4[2]
            v6[3] += v4[3]
            v6[4] += v4[4]
        end

        return false
    end

    if dot3(p12, p12) < 1 then
        for i = 0, 23 do
            local v7 = rt.copy(p10.record.pose[i + 1])

            v7[4][1] += p12[1]
            v7[4][2] += p12[2]
            v7[4][3] += p12[3]
            v7[4][4] += p12[4]
            SkeletonBody.set_part_transform(p10, i, v7)
        end
    end

    return false
end

return t1
