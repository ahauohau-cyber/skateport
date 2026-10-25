-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/skeleton_animation_record")
local v2 = import("skate_core/physics/skeleton_root")
local compose_affine = v1.compose_affine
local SkeletonRootFrames, orthonormalize = v2.SkeletonRootFrames, v2.orthonormalize

return {
    prepare = function(p1, p2, p3, p4, p5, p6, p7) -- prepare | line: 22
        -- upvalues: rt (copy), compose_affine (copy), SkeletonRootFrames (copy), orthonormalize (copy)
        local v3 = rt.copy(p2)

        p1.initialize_heading = true

        if bit32.band(p6, 4) ~= 0 then
            for _, v4 in { 0, 2 } do
                local v5 = v3[v4 + 1]

                v3[v4 + 1] = {
                    -v5[1],
                    -v5[2],
                    -v5[3],
                    -v5[4]
                }
            end
        end

        local v6 = table.create(4)

        for i = 0, 3 do
            local v7 = v3[1][i + 1] * p4[1]
            local v8 = v3[2][i + 1] * p4[2] + v7

            v6[i + 1] = p3[i + 1] - (v3[3][i + 1] * p4[3] + v8)
        end

        v3[4] = v6
        SkeletonRootFrames.reset_initial_alignment(p1, orthonormalize(v3))

        local v9 = bit32.bor(p7, 524288)

        return compose_affine(p1.animation_to_world, p5), v9
    end
}
