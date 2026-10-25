-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_subnormal_mantissa(p1) -- line: 7
    local v2 = p1 * 7.1362384635298E+44
    local v3 = math.floor(v2)
    local v4 = v2 - v3

    if v4 > 0.5 or v4 == 0.5 and v3 % 2 == 1 then
        return v3 + 1
    end

    return v3
end

local function rtl_to_bits(p2) -- line: 16
    -- upvalues: v1 (copy)
    if p2 ~= 0 and p2 > -1.1754943508222875E-38 and p2 < 1.1754943508222875E-38 then
        local v6 = math.abs(p2) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        if p2 < 0 then
            return v5 + 2147483648
        end

        return v5
    end

    buffer.writef32(v1, 0, p2)

    return (buffer.readu32(v1, 0))
end

local function rtl_from_bits(p3) -- line: 24
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p3)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local Vector3 = import("skate_core/math").Vector3
local orthonormalize_rotation = import("skate_core/physics/board_pose").orthonormalize_rotation
local dot3 = import("skate_core/physics/native_arithmetic").dot3
local compose_affine = import("skate_core/physics/skeleton_animation_record").compose_affine
local clamp_length = import("skate_core/riding/ground_orientation").clamp_length

local function skeleton_body() -- line: 43
    -- upvalues: import (copy)
    return import("skate_core/physics/skeleton_body")
end

local t1 = {
    SkeletonTargetInput = {},
    ExtraTargetPositions = {},
    SkeletonTargetUpdate = {},
    SkeletonTargets = {}
}

function t1.SkeletonTargets.update_hook_positions(p4, p5) -- line: 83
    -- upvalues: import (copy), compose_affine (copy), t1 (copy)
    local SkeletonTargets = import("skate_core/physics/skeleton_body").SkeletonTargets
    local v8 = compose_affine(p5.animation_to_world, p5.animation_hips)
    local v9 = compose_affine(p5.animation_to_world, p5.animation_board)
    local v10 = compose_affine(p5.inverse_board, v9)

    SkeletonTargets.set_transform(p4, 0, t1.orthonormalize(v8))
    SkeletonTargets.set_transform(p4, 1, t1.orthonormalize(p5.skate_root))

    return v10
end

function t1.SkeletonTargets.update_positions(p6, p7, p8) -- line: 93
    -- upvalues: import (copy), dot3 (copy)
    local SkeletonTargets = import("skate_core/physics/skeleton_body").SkeletonTargets
    local v11 = SkeletonTargets.transform(p6, 0)[4]
    local v12 = SkeletonTargets.update_hook_positions(p6, p7)
    local v13 = SkeletonTargets.transform(p6, 0)[4]
    local t2 = {
        v11[1] - v13[1],
        v11[2] - v13[2],
        v11[3] - v13[3],
        v11[4] - v13[4]
    }

    return {
        animation_board_to_physics = v12,
        positions = SkeletonTargets.update_extra_targets(p6, p8, p7.com_frame, p7.lifted_com_frame),
        continuous = not p7.teleporting and not (dot3(t2, t2) > 1)
    }
end

function t1.SkeletonTargets.update_extra_targets(p9, p10, p11, p12) -- line: 125
    -- upvalues: rt (copy), import (copy), Vector3 (copy), clamp_length (copy)
    local v14 = import("skate_core/physics/skeleton_body")
    local SkeletonTargets, SkeletonBody = v14.SkeletonTargets, v14.SkeletonBody

    SkeletonTargets.set_transform(p9, 2, p12)
    SkeletonTargets.set_transform(p9, 3, p11)

    local t3 = {
        com = rt.copy(p11[4]),
        lifted_com = rt.copy(p12[4]),
        following_com = rt.copy(p11[4])
    }
    local v15 = SkeletonBody.part_translation(p10, 24)
    local v16 = SkeletonBody.part_translation(p10, 25)
    local v17 = p12[4]
    local v18 = Vector3.new((v17[1] - v15[1]) * 60, (v17[2] - v15[2]) * 60, (v17[3] - v15[3]) * 60)

    SkeletonBody.bodies_mut(p10)[25].rates.linear_velocity = clamp_length(v18, 40)

    local v19 = p11[4]
    local v20 = Vector3.new((v19[1] - v16[1]) * 60, (v19[2] - v16[2]) * 60, (v19[3] - v16[3]) * 60)

    SkeletonBody.bodies_mut(p10)[26].rates.linear_velocity = clamp_length(v20, 40)

    return t3
end

function t1.SkeletonTargets.update_extra_targets_reference(p13, p14, p15, p16) -- line: 162
    -- upvalues: rt (copy), import (copy), Vector3 (copy), clamp_length (copy)
    local v21 = import("skate_core/physics/skeleton_body")
    local SkeletonTargets, SkeletonBody = v21.SkeletonTargets, v21.SkeletonBody

    SkeletonTargets.set_transform(p13, 2, p16)
    SkeletonTargets.set_transform(p13, 3, p15)

    local t4 = {
        com = rt.copy(p15[4]),
        lifted_com = rt.copy(p16[4]),
        following_com = rt.copy(p15[4])
    }
    local v22 = SkeletonBody.part_transforms(p14)

    for _, v23 in {
            {
                24,
                p16[4]
            },
            {
                25,
                p15[4]
            }
        } do
        local v24 = v23[1]
        local v25 = v23[2]
        local v26 = v22[v24 + 1][4]
        local v27 = Vector3.new((v25[1] - v26[1]) * 60, (v25[2] - v26[2]) * 60, (v25[3] - v26[3]) * 60)

        SkeletonBody.bodies_mut(p14)[v24 + 1].rates.linear_velocity = clamp_length(v27, 40)
    end

    return t4
end

function t1.orthonormalize(p17) -- line: 189
    -- upvalues: v1 (copy), orthonormalize_rotation (copy)
    local v28 = table.create(16)

    for i = 0, 3 do
        local v29 = p17[i + 1]

        for j = 0, 3 do
            local v30 = i * 4 + j + 1
            local v31 = v29[j + 1]

            if v31 ~= 0 and v31 > -1.1754943508222875E-38 and v31 < 1.1754943508222875E-38 then
                local v32 = math.abs(v31) * 7.1362384635298E+44
                local v33 = math.floor(v32)
                local v34 = v32 - v33
                local v35 = if v34 > 0.5 or v34 == 0.5 and v33 % 2 == 1 then v33 + 1 else v33

                if v31 < 0 then
                    v28[v30] = v35 + 2147483648
                else
                    v28[v30] = v35
                end
            else
                buffer.writef32(v1, 0, v31)
                v28[v30] = buffer.readu32(v1, 0)
            end
        end
    end

    local v36 = orthonormalize_rotation(v28)
    local v37 = table.create(4)

    for i = 0, 3 do
        local v38 = table.create(4)

        for j = 0, 3 do
            local v39 = j + 1

            buffer.writeu32(v1, 0, v36[i * 4 + j + 1])
            v38[v39] = buffer.readf32(v1, 0)
        end

        v37[i + 1] = v38
    end

    return v37
end

return t1
