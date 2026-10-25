-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/player/offboard/ground_motion/math")
local v2 = import("skate_core/trigonometry")
local ZERO, UP, IDENTITY, DT = v1.ZERO, v1.UP, v1.IDENTITY, v1.DT
local RATE, EPSILON, add, sub = v1.RATE, v1.EPSILON, v1.add, v1.sub
local scale, madd, dot, cross = v1.scale, v1.madd, v1.dot, v1.cross
local reciprocal, length, normalize_safe, select = v1.reciprocal, v1.length, v1.normalize_safe, v1.select
local clamp_signed, transform_vector, transform_point, compose = v1.clamp_signed, v1.transform_vector, v1.transform_point, v1.compose
local inverse_rigid = v1.inverse_rigid
local t1 = {}

function t1.filter(p1, p2) -- line: 38
    -- upvalues: scale (copy), madd (copy), length (copy), select (copy), transform_vector (copy)
    local reference_frame_128 = p2.reference_frame_128
    local t2 = {
        {
            reference_frame_128[1][1],
            reference_frame_128[2][1],
            reference_frame_128[3][1],
            0
        },
        {
            reference_frame_128[1][2],
            reference_frame_128[2][2],
            reference_frame_128[3][2],
            0
        },
        {
            reference_frame_128[1][3],
            reference_frame_128[2][3],
            reference_frame_128[3][3],
            0
        },
        { 0, 0, 0, 0 }
    }
    local v3 = transform_vector(p1.support_acceleration_304, t2)

    v3[2] = 0

    if p2.mirrored_292 then
        v3[1] *= -1
        v3[3] *= -1
    end

    local v4 = scale(v3, 0.02500000037252903)
    local v5 = length(v4)

    if not (v5 <= 1) then
        v4 = scale(v4, 1 / v5)
    end

    p1.filtered_local_acceleration_320 = madd(v4, 0.03999999910593033, scale(p1.filtered_local_acceleration_320, 0.9599999785423279))

    local v6 = length({
        p1.support_velocity_256[1],
        0,
        p1.support_velocity_256[3],
        p1.support_velocity_256[1]
    }) * 0.05000000074505806
    local v7 = select(-v6, 0, v6)

    p1.support_speed_348 = select(1 - v7, v7, 1)
end

local filter = t1.filter

function t1.update(p3, p4) -- line: 72
    -- upvalues: rt (copy), v2 (copy), ZERO (copy), UP (copy), IDENTITY (copy), DT (copy), RATE (copy), EPSILON (copy), add (copy), sub (copy), scale (copy), madd (copy), dot (copy), cross (copy), reciprocal (copy), length (copy), normalize_safe (copy), clamp_signed (copy), transform_vector (copy), transform_point (copy), compose (copy), inverse_rigid (copy), filter (copy)
    local v8 = rt.copy(IDENTITY)

    if bit32.band(p4.contact_flags_176, 1) == 0 then
        return v8
    end

    if p3.support_id_352 == p4.contact_id_180 then
        v8 = compose(inverse_rigid(p3.previous_support_frame_192), p4.contact_frame_32)

        local v10 = scale(sub(transform_point(p3.frame_0[4], v8), p3.frame_0[4]), reciprocal(DT))

        p3.support_acceleration_304 = scale(madd(sub(v10, p3.support_velocity_256), reciprocal(DT), p3.support_acceleration_304), 0.949999988079071)
        p3.support_velocity_256 = rt.copy(v10)
        p3.predicted_support_velocity_272 = add(v10, sub(v10, p3.previous_support_velocity_288))
        p3.previous_support_velocity_288 = rt.copy(v10)

        local v12 = transform_vector(p3.frame_0[3], v8)
        local v14 = normalize_safe(sub(v12, scale(UP, dot(v12, UP))), ZERO)
        local v15 = clamp_signed(dot(cross(p3.frame_0[3], v14), UP))
        local v16 = v2.asin(v15) * RATE

        p3.support_yaw_336 = v16
        p3.predicted_support_yaw_344 = v16 * 2 + -p3.previous_support_yaw_340
        p3.previous_support_yaw_340 = v16

        if dot(p3.predicted_support_velocity_272, p3.predicted_support_velocity_272) > EPSILON and not p3.support_velocity_removed_715 then
            p3.velocity_480 = add(p3.velocity_480, {
                -p3.predicted_support_velocity_272[1],
                -p3.predicted_support_velocity_272[2],
                -p3.predicted_support_velocity_272[3],
                -p3.predicted_support_velocity_272[4]
            })
            p3.support_velocity_removed_715 = true
            p3.speed_704 = length(p3.velocity_480)
        end
    else
        if p3.support_velocity_removed_715 then
            p3.velocity_480 = add(p3.velocity_480, p3.predicted_support_velocity_272)
            p3.speed_704 = length(p3.velocity_480)
        end

        p3.support_yaw_336 = 0
        p3.previous_support_yaw_340 = 0
        p3.predicted_support_yaw_344 = 0
        p3.support_acceleration_304 = rt.copy(ZERO)
        p3.predicted_support_velocity_272 = rt.copy(ZERO)
        p3.support_velocity_256 = rt.copy(ZERO)
        p3.support_id_352 = p4.contact_id_180
        p3.support_velocity_removed_715 = false
    end

    filter(p3, p4)
    p3.previous_support_frame_192 = rt.copy(p4.contact_frame_32)

    return v8
end

return t1
