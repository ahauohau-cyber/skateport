-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_from_bits(p1) -- line: 7
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p1)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local v2 = import("skate_core/physics/grind_forces")
local dot3 = import("skate_core/physics/native_arithmetic").dot3
local inverse_length_squared = import("skate_core/physics/board_motion_output").inverse_length_squared
local v3 = import("skate_core/trigonometry")
local v4 = import("skate_core/animation/foot_ik")
local length, reciprocal, scale, sub = v2.length, v2.reciprocal, v2.scale, v2.sub
local t1 = {
    Input = {},
    Target = {}
}
local truck, orthonormal, rotate, signed, cross

function t1.target(p2, p3) -- line: 41
    -- upvalues: rt (copy), v1 (copy), dot3 (copy), scale (copy), sub (copy), truck (ref), rotate (ref), signed (ref), cross (ref)
    local signed2, direction, v5, v6

    if p2 == 0 then
        if math.abs(p3.pitch_1508) <= 0.12 then
            signed2 = signed
            direction = p3.direction
            v5 = dot3(p3.direction, p3.board[3]) > 0
            v6 = false
        else
            v6 = true
        end
    else
        v6 = true
    end

    local v7

    if v6 then
        if p2 == 0 or p2 == 3 then
            v7 = truck(p3)
        elseif p2 == 1 or p2 == 5 then
            local v8 = signed(p3.direction, dot3(p3.direction, p3.board[1]) > 0)
            local v9 = if p2 == 5 then scale(p3.normal, -1) else rt.copy(p3.normal)

            v7 = {
                v8,
                v9,
                cross(v8, v9),
                rt.copy(p3.board[4])
            }
        elseif p2 == 2 or p2 == 4 then
            local v10 = cross(p3.direction, p3.normal)
            local v11 = signed(p3.direction, not (dot3(v10, sub(p3.board[4], p3.point)) > 0))

            buffer.writeu32(v1, 0, p2 == 4 and 1060874342 or 1051900099)

            local v13 = buffer.readf32(v1, 0)
            local v14 = rotate(v11, p3.normal, v13)
            local v15 = signed(p3.direction, dot3(p3.direction, p3.board[1]) > 0)

            v7 = {
                v15,
                v14,
                cross(v15, v14),
                rt.copy(p3.board[4])
            }
        else
            error("Unknown physical grind family", 0)
        end
    else
        local v16 = signed2(direction, v5)

        v7 = {
            cross(p3.normal, v16),
            rt.copy(p3.normal),
            v16,
            rt.copy(p3.board[4])
        }
    end

    return {
        frame = v7,
        noise_amount = p2 == 0 and 0 or 0.09
    }
end

function t1.truck(p4) -- line: 68
    -- upvalues: rt (copy), length (copy), reciprocal (copy), scale (copy), rotate (ref), cross (ref)
    local v17 = p4.yaw_1504 * -0.68
    local v18 = rt.copy(p4.board[3])

    if math.abs(v17) > 0 then
        v18 = rotate(p4.normal, v18, v17)
    end

    local v19 = cross(p4.normal, v18)
    local v20 = length(v19)

    if v20 <= 0.001 then
        return rt.copy(p4.board)
    end

    local v21 = scale(v19, reciprocal(v20))
    local v22 = cross(v18, v21)
    local v23 = (if not p4.switched then p4.pitch_1508 else -p4.pitch_1508) * 0.68

    if math.abs(v23) > 0 then
        v18 = rotate(v21, v18, v23)
        v22 = cross(v18, v21)
    end

    return {
        v21,
        v22,
        v18,
        rt.copy(p4.board[4])
    }
end

truck = t1.truck

function t1.blend(p5, p6) -- line: 93
    -- upvalues: v4 (copy), orthonormal (ref)
    return (v4.interpolate_native(orthonormal(p5), orthonormal(p6), 0.1))
end

function t1.orthonormal(p7) -- line: 99
    -- upvalues: rt (copy), dot3 (copy), inverse_length_squared (copy), scale (copy), sub (copy)
    local v24 = rt.filled(4, { 0, 0, 0, 0 })

    for i = 2, 0, -1 do
        local v25 = rt.copy(p7[i + 1])

        for j = 2, i + 1, -1 do
            v25 = sub(v25, scale(v24[j + 1], dot3(v24[j + 1], p7[i + 1])))
        end

        v24[i + 1] = scale(v25, inverse_length_squared(dot3(v25, v25), 2))
    end

    return v24
end

orthonormal = t1.orthonormal

function t1.rotate(p8, p9, p10) -- line: 112
    -- upvalues: v3 (copy), scale (copy), cross (ref)
    local v26, v27 = v3.sin_cos(p10 * 0.5)
    local v28 = scale(p8, v26)
    local v29 = cross(v28, p9)
    local t3 = {
        v27 * p9[1] + v29[1],
        v27 * p9[2] + v29[2],
        v27 * p9[3] + v29[3],
        v27 * p9[4] + v29[4]
    }
    local v30 = cross(v28, t3)

    return {
        2 * v30[1] + p9[1],
        2 * v30[2] + p9[2],
        2 * v30[3] + p9[3],
        2 * v30[4] + p9[4]
    }
end

rotate = t1.rotate

function t1.signed(p11, p12) -- line: 132
    -- upvalues: rt (copy), scale (copy)
    if p12 then
        return rt.copy(p11)
    end

    return scale(p11, -1)
end

signed = t1.signed

function t1.cross(p13, p14) -- line: 141
    return {
        -p13[3] * p14[2] + p13[2] * p14[3],
        -p13[1] * p14[3] + p13[3] * p14[1],
        -p13[2] * p14[1] + p13[1] * p14[2],
        -p13[4] * p14[4] + p13[4] * p14[4]
    }
end

cross = t1.cross

return t1
