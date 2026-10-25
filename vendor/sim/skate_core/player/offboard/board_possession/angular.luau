-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = require(sim.import)("skate_core/player/offboard/board_possession/math")
local cross, dot, reciprocal, scale = v1.cross, v1.dot, v1.reciprocal, v1.scale
local sub, transform_direction, unit = v1.sub, v1.transform_direction, v1.unit

return {
    acceleration_delta = function(p1, p2, p3) -- acceleration_delta | line: 17
        -- upvalues: rt (copy), cross (copy), dot (copy), reciprocal (copy), scale (copy), sub (copy), transform_direction (copy), unit (copy)
        local v2 = rt.copy(p3[1])
        local v3 = rt.copy(p3[2])
        local v4 = rt.copy(p3[3])
        local t2 = {
            cross(v3, v4),
            cross(v4, v2),
            cross(v2, v3)
        }
        local v6 = reciprocal(dot(v2, t2[1]), 2)
        local v7 = table.create(3)

        for i = 0, 2 do
            v7[i + 1] = {
                t2[1][i + 1] * v6,
                t2[2][i + 1] * v6,
                t2[3][i + 1] * v6,
                0
            }
        end

        local v8 = unit(p1, { 0, 0, 0, 0 })
        local v9 = sub(p1, scale(v8, dot(v8, scale(p2, 0.01666666753590107))))
        local v10 = transform_direction({
            v7[1],
            v7[2],
            v7[3],
            { 0, 0, 0, 0 }
        }, scale(v9, reciprocal(0.01666666753590107, 2)))

        return transform_direction({
            v2,
            v3,
            v4,
            { 0, 0, 0, 0 }
        }, scale(v10, reciprocal(0.01666666753590107, 2)))
    end
}
