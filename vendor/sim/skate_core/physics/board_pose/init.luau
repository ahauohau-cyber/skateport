-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/physics/board_pose/arithmetic")
local matrix, words, compose, inverse_rigid = v1.matrix, v1.words, v1.compose, v1.inverse_rigid
local v2 = import("skate_core/physics/board_pose/normalization")
local v3 = import("skate_core/physics/board_pose/part")
local t1 = {
    orthonormalize_part_basis = v2.orthonormalize_part_basis,
    orthonormalize_rotation = v2.orthonormalize_rotation,
    PartPose = v3.PartPose,
    part_transform = v3.part_transform,
    set_part_transform = v3.set_part_transform,
    body_pose_lanes = v3.body_pose_lanes
}

function t1.set_board_transform(p1, p2, p3) -- line: 35
    -- upvalues: matrix (copy), words (copy), compose (copy), inverse_rigid (copy), t1 (copy)
    local v4 = matrix(t1.part_transform(p1[7]))
    local v5 = t1.orthonormalize_rotation(p3)
    local v6 = compose(matrix(v5), inverse_rigid(v4))

    t1.set_part_transform(p1[7], v5)

    for i = 0, 5 do
        local v7 = p1[i + 1]
        local v8 = compose(v6, matrix(t1.part_transform(v7)))

        t1.set_part_transform(v7, t1.orthonormalize_rotation(words(v8)))
    end

    t1.set_part_transform(p2, p3)
end

return t1
