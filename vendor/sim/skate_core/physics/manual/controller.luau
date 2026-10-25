-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/manual/angle")
local v2 = import("skate_core/physics/manual/state")
local v3 = import("skate_core/point_graph")
local v4 = import("skate_core/trigonometry")
local ManualState = v2.ManualState
local PointGraph = v3.PointGraph
local t1 = {
    ManualInput = {},
    ManualAngleMeasurement = {},
    ManualError = {},
    ManualEffect = {}
}

function t1.ManualEffect.eq(p1, p2) -- line: 58
    for _, v5 in { "angular_displacement", "force_world", "force_point_body", "corrective_force_world", "corrective_point_body" } do
        if p1[v5][1] ~= p2[v5][1] or p1[v5][2] ~= p2[v5][2] or p1[v5][3] ~= p2[v5][3] or p1[v5][4] ~= p2[v5][4] then
            return false
        end
    end

    if p1.correction_active == p2.correction_active then
        return p1.opposing_motion_without_correction == p2.opposing_motion_without_correction
    end

    return false
end

local function norm(p3) -- line: 73
    -- upvalues: v1 (copy)
    local normalize = v1.normalize
    local ok, result = pcall(normalize, p3)

    if not ok then
        error({
            tag = "Angle",
            result
        }, 0)
    end

    return result
end

function t1.calculate(p4, p5, p6, p7, p8) -- line: 84
    -- upvalues: rt (copy), v1 (copy), v4 (copy), ManualState (copy), PointGraph (copy), t1 (copy)
    local t2 = {
        correction_active = false,
        opposing_motion_without_correction = false,
        angular_displacement = { 0, 0, 0, 0 },
        force_world = { 0, 0, 0, 0 },
        force_point_body = { 0, 0, 0, 0 },
        corrective_force_world = { 0, 0, 0, 0 },
        corrective_point_body = { 0, 0, 0, 0 }
    }
    local v6

    if p7.balance == 0 then
        v6 = 1
        ManualState.reset(p4)
    else
        local v7 = if p7.powersliding then rt.copy(p5.powerslide) else rt.copy(p5.manual)
        local v8 = p7.balance * p7.flipped_controls
        local v9 = if v8 > 0 then 1 else -1
        local v10 = (math.abs(v8) * 0.75 + 0.25) * v9
        local v11 = if p4.elapsed == 0 then 0 else 1
        local v12 = p5.maximum_tilt_degrees * v10 * 0.01745329238474369
        local normalize = v1.normalize
        local ok, result = pcall(normalize, v12)

        if not ok then
            error({
                tag = "Angle",
                result
            }, 0)
        end

        local result2

        if p7.braking then
            local v13 = p5.brake_tilt_degrees * v10 * 0.01745329238474369
            local normalize = v1.normalize
            local ok

            ok, result2 = pcall(normalize, v13)

            if not ok then
                error({
                    tag = "Angle",
                    result2
                }, 0)
            end
        else
            local v14 = p7.procedural_noise_time * p5.procedural_noise_frequency * 6.2831854820251465
            local v15 = v4.sin(v14) * p5.procedural_noise_scale
            local v16 = PointGraph.evaluate(p5.noise_vs_speed, p7.absolute_speed) * (p7.animation_noise * p5.animation_noise_scale * p7.flipped_controls + v15)
            local normalize = v1.normalize
            local ok, result3 = pcall(normalize, v16)

            if not ok then
                error({
                    tag = "Angle",
                    result3
                }, 0)
            end

            local v17 = result3 + result
            local normalize2 = v1.normalize
            local ok2

            ok2, result2 = pcall(normalize2, v17)

            if not ok2 then
                error({
                    tag = "Angle",
                    result2
                }, 0)
            end
        end

        if p4.elapsed == 0 then
            local v18 = p5.start_torque_scale * result2
            local normalize = v1.normalize
            local ok, result = pcall(normalize, v18)

            if not ok then
                error({
                    tag = "Angle",
                    result
                }, 0)
            end

            p4.angular_correction = result
        end

        p4.target_angle = result2

        local angle_between = p8.angle_between
        local v19 = rt.copy(p7.deck_z)
        local v20 = rt.copy(p7.reference_z)
        local copy = rt.copy
        local reference_x = p7.reference_x
        local ok2, result3 = pcall(angle_between, p8, v19, v20, copy(reference_x))

        if not ok2 then
            error({
                tag = "Measurement",
                result3
            }, 0)
        end

        local normalize2 = v1.normalize
        local ok3, result4 = pcall(normalize2, result3)

        if not ok3 then
            error({
                tag = "Angle",
                result4
            }, 0)
        end

        local v21 = result4 - p4.measured_angle

        p4.measured_angle = result4

        local clamp_symmetric = t1.clamp_symmetric
        local v22 = result2 - result4
        local normalize3 = v1.normalize
        local ok4, result5 = pcall(normalize3, v22)

        if not ok4 then
            error({
                tag = "Angle",
                result5
            }, 0)
        end

        local v23 = clamp_symmetric(result5, p5.maximum_angle_error)
        local v24 = v23 * 0.05000000074505806

        p4.filtered_angle_error = p4.filtered_angle_error * 0.949999988079071 + v24

        local v25 = t1.clamp_symmetric(v21 * v11 * v7.derivative, p5.derivative_limit)
        local v26 = if p7.positive_balance_contact == p7.negative_balance_contact then 1 else 0.5

        if not p7.positive_balance_contact and p7.balance > 0 or not p7.negative_balance_contact and p7.balance < 0 then
            p4.angular_correction = p5.torque_bleed_without_contact * p4.angular_correction * v26
            v6 = p5.torque_scale_without_contact * v26
        else
            v6 = 1
            p4.angular_correction = p4.angular_correction + v25 + p4.filtered_angle_error * v7.integral + v23 * v7.proportional
        end

        t1.apply_correction(t2, p7, p6, result2, result4)
        p4.elapsed = p7.timestep + p4.elapsed
    end

    local v27 = p4.angular_correction * v6

    t2.angular_displacement = {
        -p7.reference_x[1] * v27,
        -p7.reference_x[2] * v27,
        -p7.reference_x[3] * v27,
        -p7.reference_x[4] * v27
    }

    return t2
end

function t1.apply_correction(p9, p10, p11, p12, p13) -- line: 173
    -- upvalues: rt (copy)
    local v28 = rt.copy(p10.velocity_frame_z)
    local v29 = rt.copy(p10.angular_velocity_world)
    local v30 = v28[3] * v29[3] + (v28[2] * v29[2] + v28[1] * v29[1])

    if p10.braking and v30 * p10.balance < 0 then
        if p11.corrective_force_enabled then
            if math.abs(v30) > p11.correction_angular_speed_threshold and math.abs(p12 * 57.295780181884766 - p13 * 57.295780181884766) < 1 then
                if if p10.reversed_point_selection then p10.balance < 0 else p10.balance > 0 then
                    p9.corrective_point_body = rt.copy(p10.correction_point_7888)
                else
                    p9.corrective_point_body = rt.copy(p10.correction_point_7952)
                end

                p9.corrective_force_world = {
                    v29[1] * -1 * 400,
                    v29[2] * -1 * 400,
                    v29[3] * -1 * 400,
                    v29[4] * -1 * 400
                }
                p9.correction_active = true
            end
        else
            p9.opposing_motion_without_correction = true
        end
    end
end

function t1.clamp_symmetric(p14, p15) -- line: 212
    local v32 = -p15

    if not (v32 - p14 >= 0) then
        v32 = p14
    end

    if p15 - v32 >= 0 then
        return v32
    end

    return p15
end

return t1
