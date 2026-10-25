-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/grind_forces")
local dot3 = import("skate_core/physics/native_arithmetic").dot3
local length, reciprocal, scale, sub = v1.length, v1.reciprocal, v1.scale, v1.sub
local t1 = {
    Input = {},
    Output = {}
}
local cross

function t1.launch(p1, p2) -- line: 38
    -- upvalues: rt (copy), dot3 (copy), length (copy), reciprocal (copy), scale (copy), sub (copy), cross (ref)
    local v2 = rt.copy(p1)
    local v3 = rt.copy(v2.geometry)
    local v4 = rt.copy(v3.normal)
    local v5

    if v2.family == 2 or v2.family == 4 then
        local v6 = cross(v4, v3.direction)

        if not (dot3(v6, sub(p2.position_112, v3.point)) > 0) then
            v6 = scale(v6, -1)
        end

        local v7 = if v2.family == 4 then -0.1093 else 0.291

        v5 = table.create(4)
        v5[1] = v4[1] + v6[1] * v7
        v5[2] = v4[2] + v6[2] * v7
        v5[3] = v4[3] + v6[3] * v7
        v5[4] = v4[4] + v6[4] * v7
    else
        v5 = table.create(4)
        v5[1] = v3.upmost[1] * 0.5 + v4[1] * 0.5
        v5[2] = v3.upmost[2] * 0.5 + v4[2] * 0.5
        v5[3] = v3.upmost[3] * 0.5 + v4[3] * 0.5
        v5[4] = v3.upmost[4] * 0.5 + v4[4] * 0.5
    end

    local v8 = length(v5)

    if v8 > 0.1 then
        v4 = scale(v5, reciprocal(v8))
    end

    local v9 = sub(p2.velocity_400, scale(v4, dot3(p2.velocity_400, v4)))
    local v10 = p2.vertical_jump * 1.03
    local v11 = table.create(4)

    v11[1] = v4[1] * v10 + v9[1]
    v11[2] = v4[2] * v10 + v9[2]
    v11[3] = v4[3] * v10 + v9[3]
    v11[4] = v4[4] * v10 + v9[4]

    local v12 = cross(v3.direction, v4)
    local balance_2800 = p2.balance_2800
    local v13 = v2.energy < 0.31

    if v13 then
        balance_2800 = if balance_2800 < 0 then if balance_2800 - -0.42 >= 0 then -0.42 else balance_2800
            elseif balance_2800 > 0 then if balance_2800 - 0.42 >= 0 then balance_2800 else 0.42
            elseif dot3(sub(p2.position_112, p2.current_point_1120), v12) > 0 then 0.42
            else -0.42
        v2.cooldown = 10
    end

    local v14 = if v3.geometry_kind == 0 then 0 else p2.geometry_side_jump
    local v15 = sub(scale(v12, balance_2800 * 1.8), scale(v3.high_side, v14))
    local v16 = length(v15)

    if v16 > 1.8 then
        v15 = scale(v15, 1.8 / v16)
    end

    local v17 = table.create(4)

    v17[1] = v11[1] + v15[1]
    v17[2] = v11[2] + v15[2]
    v17[3] = v11[3] + v15[3]
    v17[4] = v11[4] + v15[4]
    v2.launched = true

    local v18 = v2.energy - 0.6

    v2.energy = if -v18 >= 0 then 0 else v18

    return {
        velocity = v17,
        jumper = v2,
        flags_2476_to_or = v13 and 33554432 or 0
    }
end

function t1.cross(p3, p4) -- line: 102
    return {
        -p3[3] * p4[2] + p3[2] * p4[3],
        -p3[1] * p4[3] + p3[3] * p4[1],
        -p3[2] * p4[1] + p3[1] * p4[2],
        -p3[4] * p4[4] + p3[4] * p4[4]
    }
end

cross = t1.cross

return t1
