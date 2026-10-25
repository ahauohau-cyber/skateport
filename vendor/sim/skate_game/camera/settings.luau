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

local function rtl_is_finite(p2) -- line: 11
    if p2 ~= p2 or p2 == 1e999 then
        return false
    end

    return p2 ~= (-1e999)
end

local import = require(sim.import)
local ManualCamSettings = import("skate_core/camera").ManualCamSettings
local Collections = import("skate_data/collections").Collections
local t1 = {
    RigSettingsSource = {}
}

function t1.manager_settings(p3) -- line: 37
    -- upvalues: Collections (copy), t1 (copy)
    return {
        rig = t1.RigSettingsSource.bind(t1.RigSettingsSource.load(p3)),
        orientation = t1.orientation_settings(p3),
        framing = t1.frame_settings(p3),
        drop = t1.drop_settings(p3),
        look = t1.look_settings(p3),
        shake = t1.shake_settings(p3),
        steering_threshold = Collections.float(p3, "camera", "dynamics", "TurningCentredDeadzone")
    }
end

function t1.compass_settings(p4) -- line: 56
    -- upvalues: Collections (copy)
    local function f(p5) -- line: 57
        -- upvalues: p4 (copy), Collections (copy)
        return Collections.float(p4, "camera_compass", "default", p5)
    end

    return {
        heading_response = Collections.float(p4, "camera", "dynamics", "HeadingChangeResponseSpeed"),
        time_before_lineup = Collections.float(p4, "camera_compass", "default", "TimeBeforeAutoLineup"),
        lineup_speed = Collections.float(p4, "camera_compass", "default", "AutoLineupSpeed"),
        minimum_deadzone_speed = Collections.float(p4, "camera_compass", "default", "MinDeadzoneSpeed"),
        maximum_deadzone_speed = Collections.float(p4, "camera_compass", "default", "MaxDeadzoneSpeed"),
        maximum_deadzone_size = Collections.float(p4, "camera_compass", "default", "MaxDeadzoneSize"),
        deadzone_smoothing = Collections.float(p4, "camera_compass", "default", "DeadzoneSizeSmoothing")
    }
end

function t1.drop_settings(p6) -- line: 79
    -- upvalues: Collections (copy)
    return {
        minimum_test_distance = Collections.float(p6, "camera_droppredictor", "default", "MinTestDistance"),
        total_test_time = Collections.float(p6, "camera_droppredictor", "default", "TotalTestTime"),
        maximum_test_distance = Collections.float(p6, "camera_droppredictor", "default", "Hash_FB5A1024D47298A1"),
        maximum_drop_distance = Collections.float(p6, "camera_droppredictor", "default", "MaxDropDistance")
    }
end

function t1.manual_cam_settings(p7) -- line: 95
    -- upvalues: rt (copy), ManualCamSettings (copy), Collections (copy)
    local v2 = ManualCamSettings.default()
    local float = Collections.float
    local FreeCamHeadingSpeed, FreeCamHeadingSpeed2 = pcall(float, p7, "camera", "freecam", "FreeCamHeadingSpeed")

    if FreeCamHeadingSpeed then
        v2.move_speed = rt.fmax(FreeCamHeadingSpeed2, 1) * 4
    end

    local float2 = Collections.float
    local FreeCamElevationSpeed, FreeCamElevationSpeed2 = pcall(float2, p7, "camera", "freecam", "FreeCamElevationSpeed")

    if FreeCamElevationSpeed then
        v2.look_speed = rt.fmax(FreeCamElevationSpeed2, 0.1)
    end

    return v2
end

function t1.look_settings(p8) -- line: 109
    -- upvalues: Collections (copy)
    return {
        heading_offset_degrees = Collections.float(p8, "camera", "freecam", "FreeCamHeadingOffset"),
        heading_speed = Collections.float(p8, "camera", "freecam", "FreeCamHeadingSpeed"),
        elevation_offset_degrees = Collections.float(p8, "camera", "freecam", "FreeCamElevationOffset"),
        elevation_speed = Collections.float(p8, "camera", "freecam", "FreeCamElevationSpeed")
    }
end

function t1.shake_settings(p9) -- line: 124
    -- upvalues: v1 (copy), Collections (copy)
    local function f(p10) -- line: 125
        -- upvalues: p9 (copy), Collections (copy)
        return Collections.float(p9, "camera_shake", "default", p10)
    end

    local function matrix(p11) -- line: 129
        -- upvalues: p9 (copy), v1 (copy), Collections (copy)
        local v3 = Collections.words(p9, "camera_shake", "default", p11, 16)

        buffer.writeu32(v1, 0, v3[1])

        local v5 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v3[2])

        local v7 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v3[3])

        local v9 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v3[4])

        local t2 = {
            v5,
            v7,
            v9,
            (buffer.readf32(v1, 0))
        }

        buffer.writeu32(v1, 0, v3[5])

        local v12 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v3[6])

        local v14 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v3[7])

        local v16 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v3[8])

        local t3 = {
            v12,
            v14,
            v16,
            (buffer.readf32(v1, 0))
        }

        buffer.writeu32(v1, 0, v3[9])

        local v19 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v3[10])

        local v21 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v3[11])

        local v23 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v3[12])

        local t4 = {
            v19,
            v21,
            v23,
            (buffer.readf32(v1, 0))
        }

        buffer.writeu32(v1, 0, v3[13])

        local v26 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v3[14])

        local v28 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v3[15])

        local v30 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v3[16])

        return {
            t2,
            t3,
            t4,
            {
                v26,
                v28,
                v30,
                (buffer.readf32(v1, 0))
            }
        }
    end

    return {
        amplitude_curve = matrix("AmplitudeCurve"),
        frequency_curve = matrix("FrequencyCurve"),
        impulse_magnitude = Collections.float(p9, "camera_shake", "default", "OneShotMagnitude"),
        impulse_minimum_velocity = Collections.float(p9, "camera_shake", "default", "OneShotMinVelocity"),
        impulse_maximum_velocity = Collections.float(p9, "camera_shake", "default", "OneShotMaxVelocity"),
        impulse_frequency = Collections.float(p9, "camera_shake", "default", "OneShotFrequency"),
        impulse_decay = Collections.float(p9, "camera_shake", "default", "OneShotDecay"),
        amplitude_minimum = Collections.float(p9, "camera_shake", "default", "AmplitudeMin"),
        amplitude_maximum = Collections.float(p9, "camera_shake", "default", "AmplitudeMax"),
        amplitude_top_speed = Collections.float(p9, "camera_shake", "default", "AmplitudeTopSkaterSpeed"),
        frequency_minimum = Collections.float(p9, "camera_shake", "default", "FrequencyMin"),
        frequency_maximum = Collections.float(p9, "camera_shake", "default", "FrequencyMax"),
        frequency_top_speed = Collections.float(p9, "camera_shake", "default", "FrequencyTopSkaterSpeed"),
        data_frames_per_second = Collections.float(p9, "camera_shake", "default", "DataFPS"),
        translation_multiplier = Collections.float(p9, "camera_shake", "default", "TranslationMultiplier"),
        rotation_multiplier = Collections.float(p9, "camera_shake", "default", "RotationMultiplier"),
        dutch_multiplier = Collections.float(p9, "camera_shake", "default", "DutchMultiplier")
    }
end

function t1.RigSettingsSource.load(p12) -- line: 162
    -- upvalues: Collections (copy), t1 (copy)
    local function f(p13, p14, p15) -- line: 163
        -- upvalues: p12 (copy), Collections (copy)
        return Collections.float(p12, p13, p14, p15)
    end

    local function angle(p16) -- line: 169
        -- upvalues: p12 (copy), Collections (copy)
        return {
            speed_clamp_degrees = Collections.float(p12, "camera_tracker", p16, "SpeedClamp"),
            acceleration_min_degrees = Collections.float(p12, "camera_tracker", p16, "AccelerationClampMin"),
            acceleration_max_degrees = Collections.float(p12, "camera_tracker", p16, "AccelerationClampMax"),
            delta_umbra_degrees = Collections.float(p12, "camera_tracker", p16, "DeltaUmbra"),
            delta_penumbra_degrees = Collections.float(p12, "camera_tracker", p16, "DeltaPenumbra")
        }
    end

    return {
        heading = angle("heading"),
        elevation = angle("elevation"),
        anchor = {
            latch_curve = t1.curve(p12, "camera_lag_profile", "push", "Curve"),
            input_curve = t1.curve(p12, "camera_lag_profile", "pump", "Curve"),
            speed_clamp = Collections.float(p12, "camera", "subject_tracker", "SubjectTrackerMaxSpeed"),
            acceleration_clamp = Collections.float(p12, "camera", "subject_tracker", "SubjectTrackerMaxAcceleration"),
            latch_scale = Collections.float(p12, "camera_lag_profile", "push", "MaxSmoothing"),
            input_threshold = Collections.float(p12, "camera", "dynamics", "PumpingMinAcceleration"),
            input_scale = Collections.float(p12, "camera_lag_profile", "pump", "MaxSmoothing")
        },
        avoidance = {
            horizon = Collections.float(p12, "camera", "dynamics", "AvoidanceLookahead"),
            heading_smoothing = Collections.float(p12, "camera", "dynamics", "AvoidanceHeadingSmoothing"),
            elevation_smoothing = Collections.float(p12, "camera", "dynamics", "AvoidanceElevationSmoothing"),
            ease_out_time = Collections.float(p12, "camera", "dynamics", "AvoidanceEaseOut"),
            radius_padding = Collections.float(p12, "camera_positioner", "default", "AvoidanceCollisionOffset")
        },
        positioning = {
            normal = {
                speed_clamp = Collections.float(p12, "camera_tracker", "distance", "SpeedClamp"),
                smoothing = Collections.float(p12, "camera_tracker", "distance", "SmoothingConstant"),
                acceleration_clamp = Collections.float(p12, "camera_tracker", "distance", "AccelerationClampMax")
            },
            alternate = {
                speed_clamp = Collections.float(p12, "camera_tracker", "distance", "FastSpeedClamp"),
                smoothing = Collections.float(p12, "camera_tracker", "distance", "Hash_E2D9D0FAAB8CB7F3"),
                acceleration_clamp = Collections.float(p12, "camera_tracker", "distance", "FastAccelerationClampMax")
            },
            minimum_distance = Collections.float(p12, "camera_positioner", "default", "MinDistance"),
            alternate_minimum_distance = Collections.float(p12, "camera_positioner", "default", "MinDistanceDuringWipeout")
        },
        collision_hold_duration = Collections.float(p12, "camera", "dynamics", "CollisionInterpolationDuration")
    }
end

function t1.RigSettingsSource.bind(p17) -- line: 224
    -- upvalues: rt (copy)
    return {
        heading = rt.copy(p17.heading),
        elevation = rt.copy(p17.elevation),
        anchor = rt.copy(p17.anchor),
        avoidance = rt.copy(p17.avoidance),
        positioning = rt.copy(p17.positioning),
        collision_hold_duration = p17.collision_hold_duration,
        normalization_threshold = rt.filled(4, 9.999999974752427E-07)
    }
end

function t1.orientation_settings(p18) -- line: 239
    -- upvalues: Collections (copy), t1 (copy)
    local function f(p19, p20, p21) -- line: 240
        -- upvalues: p18 (copy), Collections (copy)
        return Collections.float(p18, p19, p20, p21)
    end

    local function tracker(p22) -- line: 244
        -- upvalues: p18 (copy), Collections (copy)
        return {
            acceleration_min_degrees = Collections.float(p18, "camera_tracker", p22, "AccelerationClampMin"),
            acceleration_max_degrees = Collections.float(p18, "camera_tracker", p22, "AccelerationClampMax"),
            smoothing_min = Collections.float(p18, "camera_tracker", p22, "SmoothingMin"),
            delta_umbra_degrees = Collections.float(p18, "camera_tracker", p22, "DeltaUmbra"),
            delta_penumbra_degrees = Collections.float(p18, "camera_tracker", p22, "DeltaPenumbra")
        }
    end

    return {
        pan_umbra_degrees = Collections.float(p18, "camera", "rotation", "PanUmbra"),
        pan_penumbra_degrees = Collections.float(p18, "camera", "rotation", "PanPenumbra"),
        pan_smoothing_curve = t1.curve(p18, "camera", "rotation", "PanSmoothingCurve"),
        pan_minimum_smoothing = Collections.float(p18, "camera", "rotation", "PanMinSmoothing"),
        pan = tracker("pan"),
        tilt = tracker("tilt")
    }
end

function t1.frame_settings(p23) -- line: 265
    -- upvalues: Collections (copy)
    return {
        maximum_pitch_degrees = Collections.float(p23, "camera", "dynamics", "MaxPitch"),
        roll_response = Collections.float(p23, "camera", "dynamics", "DutchInterpolationSpeed")
    }
end

function t1.curve(p24, p25, p26, p27) -- line: 277
    -- upvalues: v1 (copy), Collections (copy)
    local v32 = Collections.words(p24, p25, p26, p27, 16)
    local v33 = table.create(16)

    for i = 1, 16 do
        buffer.writeu32(v1, 0, v32[i])
        v33[i] = buffer.readf32(v1, 0)
    end

    for _, v35 in v33 do
        if v35 ~= v35 or v35 == 1e999 or v35 == (-1e999) then
            error(("Non-finite camera curve %*/%*/%*"):format(p25, p26, p27), 0)
        end
    end

    return {
        x = {
            v33[1],
            v33[2],
            v33[3],
            v33[4],
            v33[5],
            v33[6],
            v33[7],
            v33[8]
        },
        y = {
            v33[9],
            v33[10],
            v33[11],
            v33[12],
            v33[13],
            v33[14],
            v33[15],
            v33[16]
        }
    }
end

return t1
