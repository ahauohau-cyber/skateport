-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/player/wipeout_state/math")
local v2 = import("skate_core/trigonometry")
local sin_cos = v2.sin_cos
local inverse_length_squared = import("skate_core/physics/board_motion_output").inverse_length_squared
local t1 = {}

function t1.alignment_up(p1, p2) -- line: 16
    -- upvalues: sin_cos (copy), t1 (copy)
    local v3, v4 = sin_cos(p1 * 0.01745329238474369 * 0.5)
    local v5, v6 = sin_cos(p2 * 0.01745329238474369 * 0.5)
    local v7, v8 = sin_cos(0)
    local v9 = v4 * v8
    local v10 = v3 * v8
    local v11 = v3 * v7
    local v12 = v4 * v7
    local v13 = v6 * v11 + v5 * v9
    local v14 = v6 * v9 + v5 * v11
    local v15 = v6 * v12 - v5 * v10
    local v16 = v6 * v10 - v5 * v12

    return t1.rotate({ v16, v13, v15, v14 }, { 0, 1, 0, 0 })
end

function t1.rotate(p3, p4) -- line: 35
    -- upvalues: v1 (copy)
    local v17 = v1.cross(p3, p4)
    local v18 = v1.madd(p4, p3[4], v17)

    return v1.madd(v1.cross(p3, v18), 2, p4)
end

function t1.signed_angle(p5, p6, p7) -- line: 43
    -- upvalues: v1 (copy), v2 (copy), inverse_length_squared (copy)
    local v19 = v1.dot(p5, p5)
    local v20 = v1.dot(p6, p6)

    if not (v19 > 9.999999747378752E-05 and v20 > 9.999999747378752E-05) then
        return 0
    end

    local v21 = v1.scale(p5, inverse_length_squared(v19, 1))
    local v22 = v1.scale(p6, inverse_length_squared(v20, 1))
    local v23 = v2.acos(v1.clamp(v1.dot(v21, v22), -1, 1))

    if v1.dot(v1.cross(v21, v22), p7) < 0 then
        return 6.2831854820251465 - v23
    end

    return v23
end

function t1.projected_angle(p8, p9, p10) -- line: 60
    -- upvalues: v1 (copy), t1 (copy)
    if v1.dot(p8, p8) * v1.dot(p9, p9) > 1.52587890625E-05 then
        return t1.signed_angle(v1.sub(p8, v1.scale(p10, v1.dot(p10, p8))), v1.sub(p9, v1.scale(p10, v1.dot(p10, p9))), p10)
    end

    return 0
end

return t1
