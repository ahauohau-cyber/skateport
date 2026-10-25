-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/skeleton_animation_record")
local v2 = import("skate_core/physics/skeleton_board_frames")
local v3 = import("skate_core/physics/skeleton_root")
local compose_affine = v1.compose_affine
local SkeletonBoardFrames = v2.SkeletonBoardFrames
local SkeletonRootFrames = v3.SkeletonRootFrames
local t1 = {}

function t1.prepare(p1, p2, p3, p4, p5, p6, p7) -- line: 22
    -- upvalues: rt (copy), compose_affine (copy), SkeletonRootFrames (copy)
    local v4 = rt.copy(p2)

    if bit32.band(p5, 4) ~= 0 then
        for _, v5 in { 0, 2 } do
            local v6 = v4[v5 + 1]

            v6[1] *= -1
            v6[2] *= -1
            v6[3] *= -1
            v6[4] *= -1
        end
    end

    p1.initialize_heading = true
    SkeletonRootFrames.reset_initial_alignment(p1, rt.copy(v4))

    if bit32.band(p6, 1) == 0 then
        rt.assign(p4, p3)
    end

    local v7 = bit32.bor(p7, 524288)

    return compose_affine(v4, p4), v7
end

function t1.prepare_pose(p8, p9, p10, p11, p12, p13, p14, p15, p16) -- line: 46
    -- upvalues: rt (copy), compose_affine (copy), SkeletonBoardFrames (copy), t1 (copy)
    p9.skate_root = compose_affine(p8.animation_to_world, p10)
    SkeletonBoardFrames.update_com_lift(p9, p8.animation_to_world, rt.copy(p13.centre_of_mass_1056), 0.23999999463558197)

    local v8, v9 = t1.prepare(p8, p13.world_frame, p11, p12, p14, p15, p16)

    p9.animation_target = rt.copy(v8)

    return v8, v9
end

return t1
