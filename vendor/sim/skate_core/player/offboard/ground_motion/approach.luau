-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/player/offboard/ground_motion/math")
local v2 = import("skate_core/trigonometry")
local ZERO, UP, DT, RATE = v1.ZERO, v1.UP, v1.DT, v1.RATE
local EPSILON, sub, scale, madd = v1.EPSILON, v1.sub, v1.scale, v1.madd
local dot, cross, reciprocal, length = v1.dot, v1.cross, v1.reciprocal, v1.length
local normalize_safe, clamp_signed, compose, limit_angle = v1.normalize_safe, v1.clamp_signed, v1.compose, v1.limit_angle
local t1 = {}

function t1.refresh_target(p1, p2) -- line: 33
    -- upvalues: rt (copy), madd (copy)
    if p2.target_frame_present_352 then
        p1.target_frame_608 = rt.copy(p2.target_frame_368)
        p1.target_frame_608[4] = madd(p2.target_frame_368[1], 0.20000000298023224, p2.target_frame_368[4])
    end
end

local refresh_target = t1.refresh_target

function t1.height_adjustment(p3, p4, p5) -- line: 42
    -- upvalues: sub (copy), scale (copy), dot (copy)
    return scale(p3.frame_0[2], dot(sub(p4.contact_position_0, p5), p3.frame_0[2]) * 0.05000000074505806)
end

local height_adjustment = t1.height_adjustment

function t1.calculate(p6, p7, p8, p9) -- line: 50
    -- upvalues: rt (copy), v2 (copy), ZERO (copy), UP (copy), DT (copy), RATE (copy), EPSILON (copy), sub (copy), scale (copy), madd (copy), dot (copy), cross (copy), reciprocal (copy), length (copy), normalize_safe (copy), clamp_signed (copy), compose (copy), limit_angle (copy), refresh_target (copy), height_adjustment (copy)
    local v3 = scale(p6.velocity_480, DT)
    local v4 = rt.copy(ZERO)

    if p7.animation_directed_304 then
        local v5 = length(p7.animation_motion_224)
        local v6 = v5 < EPSILON
        local v7 = sub(p6.target_frame_608[4], p8)
        local v8 = length(v7)
        local v9, v10

        if p6.target_scale_784 >= 0 then
            v9 = v8
            v10 = v7
        else
            refresh_target(p6, p7)

            local v11 = sub(p6.target_frame_608[4], p8)

            v9 = length(v11)
            p6.target_scale_784 = v9 / (if v6 then p7.requested_duration_288 else v5)
            v10 = v11
        end

        local v13 = rt.copy(ZERO)

        if not (v9 <= EPSILON) then
            local v14 = p6.target_scale_784 * DT

            if not v6 then
                v14 = length(p7.animation_motion_240) * v14
            end

            v13 = scale(scale(v10, reciprocal(v9)), v14)
        end

        local v15 = clamp_signed(dot(cross(p6.target_frame_608[1], p6.frame_0[3]), p6.frame_0[2]))
        local v16 = v2.asin(v15)
        local v17 = if v6 then p7.requested_duration_288 * p6.target_scale_784 else p6.target_scale_784 * v5

        p6.angular_velocity_688 = 0

        if not (v17 <= EPSILON) then
            p6.angular_velocity_688 = (1 - v9 / v17) * v16 * RATE
        end

        p6.target_frame_608 = compose(p6.target_frame_608, p9)

        return v13, v4
    end

    p6.target_scale_784 = -1
    refresh_target(p6, p7)

    local contact_flags_176 = p7.contact_flags_176

    if bit32.band(contact_flags_176, 2) == 0 and not p7.obstacle_enabled_713 then
        local v18 = if bit32.band(p7.contact_flags_176, 1) == 0 then v4 else height_adjustment(p6, p7, p8)

        return v3, v18
    end

    local v19

    if p7.obstacle_enabled_713 then
        v19 = rt.copy(p7.obstacle_target_672)
    else
        local v20 = normalize_safe(cross(UP, p6.frame_0[3]), p6.frame_0[1])
        local v21 = if p6.correction_enabled_711 then p7.correction_target_592 else p7.contact_target_96

        v19 = sub(v21, scale(v20, dot(sub(v21, p8), v20)))
    end

    local v22 = sub(v19, p8)

    if dot(v22, v22) < 1.52587890625E-05 or not (dot(v22, p6.velocity_480) >= -0.5) then
        local v23 = madd(scale(p6.velocity_480, DT), 2, p8)

        v19 = {
            v23[1],
            v19[2],
            v23[3],
            v23[4]
        }
    end

    local v24 = sub(v19, p8)
    local v25 = length(v3)
    local v26 = length(v24)
    local v27

    if v26 <= v25 then
        local v30 = normalize_safe(limit_angle(if p7.obstacle_enabled_713 then p7.target_frame_368[2] else p7.contact_normal_112, p7.reference_frame_128[2], 0.7853981573134661), ZERO)

        v27 = madd(normalize_safe(sub(p6.velocity_480, scale(v30, dot(p6.velocity_480, v30))), ZERO), v25 - v26, v24)
    else
        v27 = scale(normalize_safe(v24, ZERO), v25)
    end

    if not (v25 >= 0.009999999776482582) then
        v4 = height_adjustment(p6, p7, p8)
    end

    return v27, v4
end

return t1
