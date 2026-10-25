-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local v1 = buffer.create(8)

local function rtl_from_bits(p1) -- line: 7
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p1)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local v2 = import("skate_core/player/wipeout_state/math")
local v3 = import("skate_core/player/wipeout_state/torque")
local compose_affine = import("skate_core/physics/skeleton_animation_record").compose_affine
local v4 = import("skate_core/trigonometry")

return {
    update = function(p2, p3, p4, p5, p6, p7, p8, p9) -- update | line: 25
        -- upvalues: v1 (copy), v2 (copy), v3 (copy), compose_affine (copy), v4 (copy)
        local t2 = {
            0, 0, 0, 0
        }
        local v5 = p6.vectors_464_480_496_512_528[1]

        buffer.writeu32(v1, 0, v5[1])

        local v7 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v5[2])

        local v9 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v5[3])

        local v11 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v5[4])

        local t3 = {
            v7,
            v9,
            v11,
            (buffer.readf32(v1, 0))
        }

        p2.angular_velocity = v3.angular_velocity(p3.record, p3.definition.animation_masses.fractional)

        local v13 = v2.length(p2.velocity)
        local v14 = table.create(4)

        for i = 0, 3 do
            local v15 = p5[1][i + 1] * p7.roll_axis[1]
            local v16 = p5[2][i + 1] * p7.roll_axis[2] + v15

            v14[i + 1] = p5[3][i + 1] * p7.roll_axis[3] + v16
        end

        local v17 = v2.normalize_or(v14, t2)
        local t4 = {
            compose_affine(p8, p9[4]),
            compose_affine(p8, p9[8])
        }
        local v18 = v2.length(v2.sub(t4[1][4], t4[2][4])) <= 0.6
        local t5 = {
            0, 0, 0, 0
        }
        local v19
        local v20 = t5

        if p7.align_ground_with_velocity then
            local v21 = v2.normalize_or(v2.cross(t3, p2.velocity), t2)
            local v22 = if v2.dot(v17, v21) < 0 then v2.scale(v17, -1) else v17
            local v23 = v2.cross(v22, v21)
            local v24 = v2.clamp(v2.length(v23), -0.9999, 0.9999)
            local v25 = v2.wrap_angle(v4.asin(v24))
            local v26 = v2.clamp(v25 * 1.2, 0, 1)

            v19 = v22

            if v13 > 2 then
                local v27 = v2.normalize_or(v23, t2)
                local v28 = v2.normalize_or(p2.angular_velocity, t2)

                v20 = v2.scale(v2.sub(v2.scale(v27, v26), v2.scale(v27, v2.dot(v28, v27))), p7.ground_align_torque)
            end
        else
            v19 = v17
        end

        local v29 = {
            0, 0, 0, 0
        }

        if v18 and p7.roll_on_ground and v13 > 2 then
            local v30 = v2.normalize_or(p2.angular_velocity, t2)

            v29 = v2.scale(v2.sub(v2.scale(v2.scale(v19, 1.5), p2.forward_input), v2.scale(v19, v2.dot(v30, v19))), p7.ground_roll_torque)
        end

        v3.apply(p3, p4, v2.add(v20, v29))
    end
}
