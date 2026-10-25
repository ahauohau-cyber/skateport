-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local sin_cos = require(sim.import)("skate_core/trigonometry").sin_cos
local t1 = {
    Matrix = {},
    BodyFlipState = {},
    BodyFlipSettings = {},
    BodyFlipInput = {}
}

function t1.update(p1, p2, p3) -- line: 43
    -- upvalues: rt (copy), t1 (copy)
    local missing_attribute_value = p2.missing_attribute_value
    local v1 = if p2.smoothing == nil then missing_attribute_value else p2.smoothing
    local v2 = if p2.maximum_speed == nil then missing_attribute_value else p2.maximum_speed

    if p2.spin_scale ~= nil then
        missing_attribute_value = p2.spin_scale
    end

    p1.requested_speed = p3.requested_speed

    local v3 = (p3.requested_speed - p1.speed) * v1 + p1.speed

    if p3.perfect_body_flips then
        local v4 = (6.2831854820251465 - math.abs(p1.angle)) * 12
        local v5 = if v3 > 0 then 1 else -1

        if not (math.abs(v3) < v4) then
            v3 = v5 * v4
        end

        p1.angle = t1.clamp(v3 * 0.01666666753590107 + p1.angle, -6.2831854820251465, 6.2831854820251465)
    else
        v3 = t1.clamp(v3, -v2, v2)
        p1.angle = p3.timestep * v3 + p1.angle
    end

    p1.speed = v3
    p1.spin_transform = t1.rotation(p3.normal, p3.spin_angle * missing_attribute_value)

    if p1.angle == 0 then
        return
    end

    local v6 = t1.rotation(p3.flip_axis, p1.angle)
    local v7 = rt.copy(p1.spin_transform)

    for i = 0, 3 do
        for j = 0, 3 do
            local v8 = if i == 3 then v7[i + 1][1] * v6[1][j + 1] + v6[4][j + 1] else v7[i + 1][1] * v6[1][j + 1]
            local v9 = v7[i + 1][2] * v6[2][j + 1] + v8

            p1.combined_transform[i + 1][j + 1] = v7[i + 1][3] * v6[3][j + 1] + v9
        end
    end
end

function t1.clamp(p4, p5, p6) -- line: 83
    local v10 = if p5 - p4 >= 0 then p5 else p4

    if p6 - v10 >= 0 then
        return v10
    end

    return p6
end

function t1.rotation(p7, p8) -- line: 88
    -- upvalues: sin_cos (copy)
    local v11 = p7[1]
    local v12 = p7[2]
    local v13 = p7[3]
    local v14, v15 = sin_cos(p8)
    local v16 = 1 - v15
    local v17 = v16 * v11
    local v18 = v16 * v12
    local v19 = v16 * v13
    local v20 = v14 * v11
    local v21 = v14 * v12
    local v22 = v14 * v13
    local v23 = v17 * v11 + v15
    local v24 = v18 * v11 - v22
    local v25 = v19 * v11 + v21

    return {
        {
            v23,
            v17 * v12 + v22,
            v17 * v13 - v21,
            v23
        },
        {
            v24,
            v18 * v12 + v15,
            v18 * v13 + v20,
            v24
        },
        {
            v25,
            v19 * v12 - v20,
            v19 * v13 + v15,
            v25
        },
        { 0, 0, 0, 0 }
    }
end

return t1
