-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/trigonometry")
local v2 = import("skate_core/physics/skeleton_animation_record")
local v3 = import("skate_core/physics/grind_air/pose")
local v4

local function parent() -- line: 12
    -- upvalues: import (copy), v4 (ref)
    if v4 == nil then
        v4 = import("skate_core/physics/grind_air")
    end

    return v4
end

return {
    project = function(p1, p2, p3, p4, p5) -- project | line: 26
        -- upvalues: rt (copy), import (copy), v1 (copy), v2 (copy), v3 (copy), v4 (ref)
        if v4 == nil then
            v4 = import("skate_core/physics/grind_air")
        end

        local v5 = v4
        local RAD, length, scale, madd = v5.RAD, v5.length, v5.scale, v5.madd
        local sub, unit, dot, cross = v5.sub, v5.unit, v5.dot, v5.cross
        local add = v5.add
        local v6 = rt.filled(12, rt.filled(5, v5.ZERO))
        local v7 = rt.copy(p1.board)
        local v8 = rt.copy(p1.velocity)
        local v9 = length(p1.angular_velocity)
        local v10 = if v9 < 1.52587890625E-05 then rt.copy(v2.IDENTITY) else v3.axis_rotation(scale(p1.angular_velocity, 1 / v9), v9 * p1.timestep)
        local v11 = madd(p1.up, p2.stomp * p1.timestep, {
            0,
            p1.timestep * -9.800000190734863,
            0, 0
        })

        for i = 0, p2.frames - 1 do
            local v12 = table.create(5)

            for j = 1, 5 do
                local v13 = p2.points[j]

                v12[j] = madd(v7[3], v13[3], madd(v7[2], v13[2], madd(v7[1], v13[1], v7[4])))
            end

            v6[i + 1] = v12

            local v14 = sub(v6[i + 1][2], v6[i + 1][5])
            local v15 = unit(sub(v14, scale(p4, dot(p4, v14))))

            if dot(v15, p3) < 0 then
                v15 = scale(v15, -1)
            end

            local v17 = math.abs((v1.acos(rt.fmin(rt.fmax(dot(v15, p3), -1), 1))))

            if v17 > 90 then
                v17 = 180 - v17
            end

            local v18 = dot(p4, cross(v15, p3)) < 0 and -1 or 1

            p5[i + 1] = -(v18 * v17 * RAD)
            v7[1] = v3.direction(v10, v7[1])
            v7[2] = v3.direction(v10, v7[2])
            v7[3] = v3.direction(v10, v7[3])
            v8 = add(v8, v11)
            v7[4] = madd(v8, p1.timestep, v7[4])
        end

        return v6
    end
}
