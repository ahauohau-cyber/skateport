-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/player/wipeout_state/math")
local Vector3 = import("skate_core/math").Vector3
local SkeletonBody = import("skate_core/physics/skeleton_body").SkeletonBody
local t1 = {
    set_velocity = function(p1, p2) -- set_velocity | line: 15
        -- upvalues: Vector3 (copy), SkeletonBody (copy)
        local v2 = SkeletonBody.bodies_mut(p1)

        for i = 1, 23 do
            v2[i + 1].rates.linear_velocity = Vector3.new(p2[1], p2[2], p2[3])
        end
    end,
    add_velocity = function(p3, p4) -- add_velocity | line: 23
        -- upvalues: SkeletonBody (copy)
        local v3 = SkeletonBody.bodies_mut(p3)

        for i = 1, 23 do
            local v4 = v3[i + 1]

            v4.rates.linear_velocity.x += p4[1]
            v4.rates.linear_velocity.y += p4[2]
            v4.rates.linear_velocity.z += p4[3]
        end
    end,
    remove_normal_velocity = function(p5, p6) -- remove_normal_velocity | line: 34
        -- upvalues: v1 (copy), Vector3 (copy), SkeletonBody (copy)
        for i = 1, 23 do
            local linear_velocity = SkeletonBody.bodies(p5)[i + 1].rates.linear_velocity
            local t2 = {
                linear_velocity.x,
                linear_velocity.y,
                linear_velocity.z,
                0
            }
            local v5 = v1.scale(p6, v1.dot(p6, t2))
            local v6 = v1.madd(v5, if i < 15 then 0.1 else 0, v1.sub(t2, v5))

            SkeletonBody.bodies_mut(p5)[i + 1].rates.linear_velocity = Vector3.new(v6[1], v6[2], v6[3])
        end
    end,
    blend_velocity = function(p7, p8) -- blend_velocity | line: 45
        -- upvalues: v1 (copy), Vector3 (copy), SkeletonBody (copy)
        local v7 = SkeletonBody.bodies_mut(p7)

        for i = 1, 23 do
            local v8 = v7[i + 1]
            local linear_velocity = v8.rates.linear_velocity
            local v9 = v1.madd(p8, 0.5, {
                linear_velocity.x * 0.5,
                linear_velocity.y * 0.5,
                linear_velocity.z * 0.5,
                0
            })
            local v10 = v1.sub(v9, p8)
            local v11 = v1.length(v10)

            if not (v11 <= 2) then
                v9 = v1.madd(v10, 2 / v11, p8)
            end

            v8.rates.linear_velocity = Vector3.new(v9[1], v9[2], v9[3])
        end
    end,
    limit_velocity = function(p9, p10) -- limit_velocity | line: 59
        -- upvalues: v1 (copy), Vector3 (copy), SkeletonBody (copy)
        local v12 = SkeletonBody.bodies_mut(p9)

        for i = 1, 23 do
            local v13 = v12[i + 1]
            local linear_velocity = v13.rates.linear_velocity
            local t3 = {
                linear_velocity.x,
                linear_velocity.y,
                linear_velocity.z,
                0
            }

            if v1.dot(t3, t3) > p10 * p10 then
                local v14 = v1.scale(t3, v1.reciprocal(v1.length(t3)) * p10)

                v13.rates.linear_velocity = Vector3.new(v14[1], v14[2], v14[3])
            end
        end
    end,
    set_drag = function(p11, p12, p13) -- set_drag | line: 73
        -- upvalues: SkeletonBody (copy)
        for _, v15 in ipairs(SkeletonBody.bodies_mut(p11)) do
            v15.inertia.linear_drag = p12 * 59.999996185302734
            v15.inertia.angular_drag = p13 * 59.999996185302734
        end
    end
}

function t1.set_wipeout_drag(p14, p15) -- line: 81
    -- upvalues: v1 (copy), t1 (copy)
    t1.set_drag(p14, v1.clamp(p15, 0, 1), v1.clamp((p15 + 1) * 0.5, 0, 1))
end

local t4 = {
    1.7, 1.5, 1.2, 1, 1, 1, 1.2, 1,
    1, 1, 1.2, 1, 1, 1, 0.5, 0.5,
    0.5, 0.6, 0.5, 0.5, 0.5, 0.6, 1
}

function t1.special_surface(p16, p17) -- line: 92
    -- upvalues: SkeletonBody (copy), t4 (copy)
    for i = 1, 23 do
        local v16 = p17 + 0.1 - p16.record.pose[i + 1][4][2]
        local v17

        if v16 > 0 then
            v17 = 0.1
            SkeletonBody.apply_part_displacement(p16, i, {
                0,
                (v16 * 0.6 + 0.1) * t4[i],
                0, 0
            })
        else
            v17 = 0.005
        end

        SkeletonBody.bodies_mut(p16)[i + 1].inertia.angular_drag = v17 * 59.999996185302734
        SkeletonBody.bodies_mut(p16)[i + 1].inertia.linear_drag = v17 * 59.999996185302734
    end
end

return t1
