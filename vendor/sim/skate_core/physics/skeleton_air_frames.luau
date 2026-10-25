-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/skeleton_animation_record")
local v2 = import("skate_core/physics/skeleton_board_frames")
local v3 = import("skate_core/physics/skeleton_root")
local v4 = import("skate_core/trigonometry")
local IDENTITY, compose_affine = v1.IDENTITY, v1.compose_affine
local SkeletonBoardFrames = v2.SkeletonBoardFrames
local inverse_rigid, orthonormalize = v3.inverse_rigid, v3.orthonormalize

return {
    AirDismountRevert = {},
    prepare_animated = function(p1, p2, p3, p4) -- prepare_animated | line: 31
        -- upvalues: rt (copy), IDENTITY (copy), compose_affine (copy), SkeletonBoardFrames (copy)
        local v5 = compose_affine(p1.animation_to_board, p3)
        local v6 = rt.copy(IDENTITY)

        v6[4] = rt.copy(p1.predicted_board_position)

        local v7 = compose_affine(v6, v5)
        local v8 = bit32.bor(p4, 524288)

        p2.animation_target = rt.copy(v7)
        p2.skate_root = rt.copy(v7)
        SkeletonBoardFrames.update_com_lift(p2, p1.animation_to_world, rt.copy(p2.centre_of_mass), 0)

        return v7, v8
    end,
    update_known_air_roots = function(p5, p6, p7, p8, p9) -- update_known_air_roots | line: 46
        -- upvalues: v4 (copy), compose_affine (copy), inverse_rigid (copy), orthonormalize (copy)
        if p5.initialize_heading then
            p5.heading_alignment = compose_affine(inverse_rigid(p6), p5.animation_to_world)
            p5.heading_alignment[4] = { 0, 0, 0, 0 }
            p5.initialize_heading = false
        end

        if p9.requested then
            local v9 = 3.1415927410125732 / p9.frames

            if not p9.goofy then
                v9 = -v9
            end

            local v10, v11 = v4.sin_cos(v9)
            local t2 = {
                { v11, 0, -v10, 0 },
                { 0, 1, 0, 0 },
                { v10, 0, v11, 0 },
                { 0, 0, 0, 0 }
            }

            p5.heading_alignment = orthonormalize(compose_affine(p5.heading_alignment, t2))
        end

        local v12 = compose_affine(p6, p5.heading_alignment)
        local v13 = table.create(4)

        for i = 0, 3 do
            local v14 = v12[1][i + 1] * p8[1]
            local v15 = v12[2][i + 1] * p8[2] + v14

            v13[i + 1] = p7[i + 1] - (v12[3][i + 1] * p8[3] + v15)
        end

        v12[4] = v13
        p5.animation_to_world = orthonormalize(v12)
        p5.world_to_animation = inverse_rigid(p5.animation_to_world)
    end,
    prepare_known_air = function(p10, p11, p12, p13) -- prepare_known_air | line: 82
        -- upvalues: rt (copy), compose_affine (copy)
        local v16 = compose_affine(p10.animation_to_world, p12)
        local v17 = bit32.bor(p13, 524288)

        p11.animation_target = rt.copy(v16)

        return v16, v17
    end,
    finish_known_air = function(p14, p15, p16) -- finish_known_air | line: 90
        -- upvalues: rt (copy), SkeletonBoardFrames (copy)
        p15.physical_board = rt.copy(p16)
        p15.skate_root = rt.copy(p16)
        SkeletonBoardFrames.update_com_lift(p15, p14.animation_to_world, rt.copy(p15.centre_of_mass), 0)
        p14.predicted_board_position = rt.copy(p16[4])
        p14.supplied_prediction = rt.copy(p16[4])
    end,
    update_plant_roots = function(p17, p18, p19, p20) -- update_plant_roots | line: 100
        -- upvalues: compose_affine (copy), inverse_rigid (copy), orthonormalize (copy)
        local v18 = compose_affine(p18, p17.heading_alignment)
        local v19 = table.create(4)

        for i = 0, 3 do
            local v20 = v18[1][i + 1] * p20[1]
            local v21 = v18[2][i + 1] * p20[2] + v20

            v19[i + 1] = p19[i + 1] - (v18[3][i + 1] * p20[3] + v21)
        end

        v18[4] = v19
        p17.animation_to_world = orthonormalize(v18)
        p17.world_to_animation = inverse_rigid(p17.animation_to_world)
    end
}
