-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local Vector3 = import("skate_core/math").Vector3
local signed_angle = import("skate_core/riding/collision_response").signed_angle
local t1 = {
    dot = function(p1, p2) -- dot | line: 18
        return p1[1] * p2[1] + p1[2] * p2[2] + p1[3] * p2[3]
    end
}
local dot = t1.dot

function t1.sub(p3, p4) -- line: 23
    return {
        p3[1] - p4[1],
        p3[2] - p4[2],
        p3[3] - p4[3],
        p3[4] - p4[4]
    }
end

local sub = t1.sub

function t1.scale(p5, p6) -- line: 28
    return {
        p5[1] * p6,
        p5[2] * p6,
        p5[3] * p6,
        p5[4] * p6
    }
end

local scale = t1.scale

function t1.cross(p7, p8) -- line: 33
    return {
        -p7[3] * p8[2] + p7[2] * p8[3],
        -p7[1] * p8[3] + p7[3] * p8[1],
        -p7[2] * p8[1] + p7[1] * p8[2],
        -p7[4] * p8[4] + p7[4] * p8[4]
    }
end

local cross = t1.cross

function t1.normalized(p9) -- line: 44
    -- upvalues: dot (copy), scale (copy)
    local v1 = dot(p9, p9)
    local v2 = 1 / math.sqrt(v1)
    local v3 = v2 * 0.5 * (-v1 * (v2 * v2) + 1) + v2
    local v4 = v3 * 0.5 * (-v1 * (v3 * v3) + 1) + v3
    local v5 = if v1 == 0 then 0 else v1 * v4

    if v5 > 9.999999974752427E-07 then
        return scale(p9, v4), v5
    end

    return { 0, 0, 0, 0 }, v5
end

local normalized = t1.normalized

function t1.rotate(p10, p11) -- line: 59
    local v6 = table.create(4)

    for i = 1, 4 do
        local v7 = p10[1][i] * p11[1]
        local v8 = p10[2][i] * p11[2] + v7

        v6[i] = p10[3][i] * p11[3] + v8
    end

    return v6
end

function t1.point(p12, p13) -- line: 70
    local v9 = table.create(4)

    for i = 1, 4 do
        local v10 = p12[1][i] * p13[1] + p12[4][i]
        local v11 = p12[2][i] * p13[2] + v10

        v9[i] = p12[3][i] * p13[3] + v11
    end

    return v9
end

local point = t1.point

function t1.xyz(p14) -- line: 81
    -- upvalues: Vector3 (copy)
    return Vector3.new(p14[1], p14[2], p14[3])
end

local xyz = t1.xyz

t1.Runtime = {}

function t1.Runtime.dot3(_, p16, p17) -- line: 90
    -- upvalues: dot (copy)
    return dot(p16, p17)
end

function t1.Runtime.divide_vector_by_scalar(_, p19, p20) -- line: 94
    -- upvalues: scale (copy)
    local v12 = 1 / p20
    local v13 = (-p20 * v12 + 1) * v12 + v12

    return scale(p19, (-p20 * v13 + 1) * v13 + v13)
end

function t1.Runtime.normalize_safe_with_length(_, p22) -- line: 103
    -- upvalues: normalized (copy)
    return normalized(p22)
end

function t1.Runtime.signed_angle_about_axis(_, p24, p25, p26) -- line: 107
    -- upvalues: signed_angle (copy), dot (copy), sub (copy), scale (copy), xyz (copy)
    if dot(p24, p24) * dot(p25, p25) > 1.52587890625E-05 then
        local v15 = sub(p24, scale(p26, dot(p26, p24)))
        local v16 = sub(p25, scale(p26, dot(p26, p25)))

        return signed_angle(xyz(v15), xyz(v16), xyz(p26))
    end

    return 0
end

function t1.Runtime.wrap_angle_8258db98(_, p28) -- line: 116
    -- upvalues: rt (copy)
    local v17

    if not (p28 < -3.1415927410125732) and p28 < 3.1415927410125732 then
        v17 = p28

        return v17
    end

    v17 = -rt.f_to_i32(p28 * 0.15915493667125702) * 6.2831854820251465 + p28

    if v17 < 3.1415927410125732 then
        if v17 < -3.1415927410125732 then
            v17 += 6.2831854820251465
        end

        return v17
    end

    return v17 - 6.2831854820251465
end

function t1.Runtime.restore_velocity_geometry_82d35998(_, p30, p31) -- line: 132
    -- upvalues: dot (copy), sub (copy), scale (copy), cross (copy), normalized (copy)
    local v18 = sub(p30, scale(p31, dot(p31, p30)))
    local v19 = cross(p31, cross(p31, { 0, 1, 0, 0 }))

    return {
        tangential_velocity = v18,
        landing_speed_curve_input = p31[2],
        landing_speed_blend_source = dot(normalized(v19), (normalized(v18)))
    }
end

function t1.Runtime.transform_point_82d36880(_, p33, p34) -- line: 143
    -- upvalues: point (copy)
    return point(p33.vectors, p34)
end

return t1
