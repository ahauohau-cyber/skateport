-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/player/wipeout_state/math")
local SkeletonBody = import("skate_core/physics/skeleton_body").SkeletonBody

return {
    angular_velocity = function(p1, p2) -- angular_velocity | line: 17
        -- upvalues: v1 (copy)
        local v2 = { 0, 0, 0, 0 }

        for i = 1, 23 do
            local v3 = v1.sub(p1.positions[i + 1], p1.centre_of_mass)
            local v4 = v1.sub(p1.velocities[i + 1], p1.centre_of_mass_velocity)
            local v5 = v1.dot(v3, v3)

            if v5 > 9.999999747378752E-05 then
                local v6 = v1.scale(v1.cross(v3, v4), v1.reciprocal(v5))

                v2 = v1.madd(v6, p2[i + 1], v2)
            end
        end

        return v2
    end,
    apply = function(p3, p4, p5) -- apply | line: 33
        -- upvalues: v1 (copy), SkeletonBody (copy)
        local v7 = v1.length(p5)

        for i = 1, 23 do
            local v8 = v1.sub(p3.record.pose[i + 1][4], p4)

            if v1.dot(v8, v8) > 0.001 then
                local v9 = v1.normalize_or(v1.cross(p5, v8), { 0, 0, 0, 0 })

                SkeletonBody.apply_part_displacement(p3, i, v1.scale(v9, v7))
            end
        end
    end
}
