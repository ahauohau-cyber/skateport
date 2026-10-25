-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/grind_air/targets")
local v2

local function parent() -- line: 10
    -- upvalues: import (copy), v2 (ref)
    if v2 == nil then
        v2 = import("skate_core/physics/grind_air")
    end

    return v2
end

return {
    update = function(p1, p2, p3, p4, p5, p6, p7, p8, p9) -- update | line: 21
        -- upvalues: rt (copy), import (copy), v1 (copy), v2 (ref)
        if v2 == nil then
            v2 = import("skate_core/physics/grind_air")
        end

        local v3 = v2
        local RAD, DEG, PI, sub = v3.RAD, v3.DEG, v3.PI, v3.sub
        local scale, dot, unit, add = v3.scale, v3.dot, v3.unit, v3.add
        local signed_angle = v3.signed_angle
        local v4 = p1.headings[p8 + 1]
        local v5 = if v4 > 0 then v1.DESIRED[p8 + 1] else -v1.DESIRED[p8 + 1]
        local v6 = rt.fmin(rt.fmax((v5 - v4) / p9 * p3.yaw_assist[p8 + 1], -p3.max_angle), p3.max_angle)

        p1.angle_delta[2] = rt.fmin(rt.fmax(p1.angle_delta[2] * RAD + v6, -p3.max_angle), p3.max_angle) * DEG

        local v7 = rt.copy(p5[rt.f_to_usize(p9 + 0.5) + 1])
        local v8 = sub(v7[2], v7[5])
        local v9 = unit(sub(v8, scale(p6, dot(p6, v8))))
        local orientation = p4.orientation
        local v10

        if p8 == 0 or p8 == 3 then
            v10 = signed_angle(v9, orientation.boardslide_dir, p6)

            if PI * 0.5 < v10 then
                v10 -= PI
            elseif v10 < -PI * 0.5 then
                v10 += PI
            end
        elseif p8 == 1 or p8 == 2 then
            local v11 = if p8 == 1 then scale(v9, -1) else v9

            v10 = signed_angle(v11, orientation.tipslide_dir, p6)

            local v12 = signed_angle(v11, orientation.backslash_dir, p6)

            if not (math.abs(v10) < math.abs(v12)) then
                v10 = v12
            end
        else
            v10 = 0
        end

        local v13 = p3.max_angle * DEG

        p1.angle_delta[1] = rt.fmin(rt.fmax(p1.angle_delta[1] + v10 / p9, -v13), v13)

        local v14 = p2.board[1]
        local v15 = unit({
            v14[1] - dot(v14, p7),
            v14[2] - dot(v14, p7),
            v14[3] - dot(v14, p7),
            v14[4] - dot(v14, p7)
        })
        local v16 = if dot(v15, v15) > 0.9 then signed_angle(p2.board[1], v15, p2.board[3]) * 0.9 else 0
        local angle_delta = p1.angle_delta

        if p8 < 4 then
            angle_delta[3] = v16 / p9
        else
            angle_delta[3] = 0
        end

        p1.angles = add(p1.angles, p1.angle_delta)
    end
}
