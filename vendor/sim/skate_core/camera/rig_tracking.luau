-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/camera/vector_tracker")
local v2 = import("skate_core/camera/angle_tracker")
local v3 = import("skate_core/point_graph")
local length, refined_reciprocal, VectorTracker = v1.length, v1.refined_reciprocal, v1.VectorTracker
local AngleTracker, normalize_angle = v2.AngleTracker, v2.normalize_angle
local PointGraph = v3.PointGraph
local t1 = {
    AngleTrackingSettings = {},
    AngularRigTracking = {}
}

function t1.AngularRigTracking.current_heading(p1) -- line: 37
    -- upvalues: t1 (copy)
    return t1.wrap_vmx(p1.heading[1].position + p1.heading_offset)
end

function t1.AngularRigTracking.reset_heading(p2, p3) -- line: 42
    -- upvalues: normalize_angle (copy)
    p2.heading[1].target = normalize_angle(p2.heading_target)
    p2.heading[1].position = normalize_angle(p2.heading_target)

    if p3 then
        p2.heading[1].velocity = 0
        p2.heading[1].acceleration = 0
    end
end

function t1.AngularRigTracking.reset_elevation(p4, p5) -- line: 52
    -- upvalues: normalize_angle (copy)
    p4.elevation[1].target = normalize_angle(p4.elevation_target)
    p4.elevation[1].position = normalize_angle(p4.elevation_target)

    if p5 then
        p4.elevation[1].velocity = 0
        p4.elevation[1].acceleration = 0
    end
end

function t1.AngularRigTracking.update_heading_reference(p6, p7, p8) -- line: 62
    -- upvalues: rt (copy), AngleTracker (copy), normalize_angle (copy), t1 (copy)
    if bit32.band(p6.flags_517, 32) == 0 and p6.heading_acceleration_state == 0 then
        return
    end

    local v5 = math.abs((t1.wrap_vmx(p6.heading_target - t1.AngularRigTracking.current_heading(p6))))
    local v6 = 1 - p6.heading_smoothing
    local v7 = if 0.800000011920929 - v6 >= 0 then v6 else 0.800000011920929

    if v5 < 0.7853981852531433 then
        v7 = (v7 - v6) * (v5 * 1.2732396125793457) + v6
    end

    if p6.reset_time > 0 then
        t1.AngularRigTracking.reset_heading(p6, true)
    end

    t1.bind_angle_settings(p6.heading_parameters, p8, v7)

    if p6.heading_acceleration_state > 0 then
        p6.heading_parameters.acceleration_clamp_min *= 2
        p6.heading_parameters.acceleration_clamp_max *= 2
    end

    p6.heading_parameters.overshoot_zeroes_velocity = false
    AngleTracker.update(p6.heading, p7, normalize_angle(p6.heading_target), rt.copy(p6.heading_parameters))
end

function t1.AngularRigTracking.update_elevation_reference(p9, p10, p11) -- line: 92
    -- upvalues: rt (copy), AngleTracker (copy), normalize_angle (copy), t1 (copy)
    if p9.reset_time > 0 then
        t1.AngularRigTracking.reset_elevation(p9, true)
    end

    t1.bind_angle_settings(p9.elevation_parameters, p11, 1 - p9.elevation_smoothing)
    AngleTracker.update(p9.elevation, p10, normalize_angle(p9.elevation_target), rt.copy(p9.elevation_parameters))
end

function t1.bind_angle_settings_reference(p12, p13, p14) -- line: 105
    p12.speed_clamp = p13.speed_clamp_degrees * 0.01745329238474369
    p12.acceleration_clamp_min = p13.acceleration_min_degrees * 0.01745329238474369
    p12.acceleration_clamp_max = p13.acceleration_max_degrees * 0.01745329238474369
    p12.delta_umbra = p13.delta_umbra_degrees * 0.01745329238474369
    p12.delta_penumbra = p13.delta_penumbra_degrees * 0.01745329238474369
    p12.smoothing_min = p14
    p12.smoothing_max = p14
end

local v8 = refined_reciprocal(6.2831854820251465)

function t1.wrap_vmx(p15) -- line: 122
    -- upvalues: v8 (copy)
    local v9 = v8 * p15
    local v10 = -(if v9 >= 0 then math.floor(v9) else math.ceil(v9)) * 6.2831854820251465 + p15
    local v11 = if v10 + 3.1415927410125732 >= 0 then v10 else v10 + 6.2831854820251465

    if v10 - 3.1415927410125732 >= 0 then
        return v10 - 6.2831854820251465
    end

    return v11
end

function t1.wrap_vmx_reference(p16) -- line: 139
    -- upvalues: rt (copy), refined_reciprocal (copy)
    local v12 = -rt.trunc(refined_reciprocal(6.2831854820251465) * p16) * 6.2831854820251465 + p16
    local v13 = if v12 + 3.1415927410125732 >= 0 then v12 else v12 + 6.2831854820251465

    if v12 - 3.1415927410125732 >= 0 then
        return v12 - 6.2831854820251465
    end

    return v13
end

t1.AnchorTrackingSubject = {}
t1.AnchorTrackingSettings = {}
t1.AnchorRigTracking = {}

function t1.AnchorRigTracking.latch_smoothing(p17, p18, p19, p20) -- line: 173
    -- upvalues: PointGraph (copy), t1 (copy)
    p17.latch_time = t1.floor_zero(p17.latch_time - p18)

    if p20.flag_584(p20) == 0 then
        p17.flags_516 = bit32.band(p17.flags_516, 251)
    elseif p20.flag_588(p20) ~= 0 then
        p17.flags_516 = bit32.bor(p17.flags_516, 4)
    end

    if bit32.band(p17.flags_516, 4) ~= 0 then
        p17.latch_time = 0.5
    end

    return t1.clamp_fraction(PointGraph.evaluate(p19.latch_curve, -p17.latch_time * 2 + 1)) * p19.latch_scale
end

function t1.AnchorRigTracking.input_smoothing(p21, p22, p23, p24) -- line: 187
    -- upvalues: PointGraph (copy), t1 (copy)
    p21.input_time = t1.floor_zero(p21.input_time - p22)

    if p24.value_476(p24) > p23.input_threshold then
        p21.input_time = 0.5
    end

    return t1.clamp_fraction(PointGraph.evaluate(p23.input_curve, -p21.input_time * 2 + 1)) * p23.input_scale
end

function t1.AnchorRigTracking.update_reference(p25, p26, p27, p28) -- line: 196
    -- upvalues: rt (copy), length (copy), VectorTracker (copy), t1 (copy)
    local v14 = t1.AnchorRigTracking.latch_smoothing(p25, p26, p27, p28)
    local v15 = t1.AnchorRigTracking.input_smoothing(p25, p26, p27, p28)
    local v16, v17

    if p28.flag_548(p28) == 0 then
        if bit32.band(p25.flags_517, 64) == 0 then
            v16 = if v14 - v15 >= 0 then v14 else v15
            v17 = false
        else
            v17 = true
        end
    else
        v17 = true
    end

    local v18 = if v17 then 0 else v16 * t1.clamp_fraction((length(p25.velocity) - 8) * -0.25)

    p25.parameters.speed_clamp = p27.speed_clamp
    p25.parameters.acceleration_clamp_min = p27.acceleration_clamp
    p25.parameters.acceleration_clamp_max = p27.acceleration_clamp
    p25.parameters.smoothing_min = v18
    p25.parameters.smoothing_max = v18

    local v19 = rt.copy(p25.anchor)

    v19[2] = p25.reference_height
    VectorTracker.update(p25.tracker, p26, v19, rt.copy(p25.parameters))
end

function t1.floor_zero(p29) -- line: 216
    if -p29 >= 0 then
        return 0
    end

    return p29
end

function t1.clamp_fraction(p30) -- line: 224
    -- upvalues: t1 (copy)
    local v20 = t1.floor_zero(p30)

    if 1 - v20 >= 0 then
        return v20
    end

    return 1
end

t1.ReferenceHeightSubject = {}
t1.ReferenceHeightTracking = {}

function t1.ReferenceHeightTracking.update(p31, p32, p33) -- line: 244
    -- upvalues: rt (copy), t1 (copy)
    local v21 = bit32.band(p31.flags_516, 64) ~= 0

    if v21 then
        p31.transition_duration = 0
    end

    local height = p31.height
    local v22 = not v21 and p31.transition_time < p31.transition_duration
    local v23

    if v22 then
        v23 = t1.clamp_fraction(p31.transition_time / p31.transition_duration) * (p31.transition_end - p31.transition_start) + p31.transition_start

        if bit32.band(p31.flags_517, 8) ~= 0 then
            local v24 = p31.transition_weight * p31.transition_weight

            v23 = (1 - v24) * v23 + p31.anchor_height * v24
        end
    elseif p31.mode == 0 or p31.mode == 2 then
        p31.previous_height = height
        v23 = p31.anchor_height
    else
        local v25 = if not v21 then p31.anchor_height < height else nil

        v23 = if v21 or v25 then p31.anchor_height else height
    end

    local v26 = (height == rt.F32_MAX or v22 or p31.mode == 2 or p33.flag_656(p33) == 0) and 1 or 0.009999999776482582

    p31.height = (v23 - p31.height) * v26 + p31.height

    if p33.flag_608(p33) == 0 then
        p31.height_offset = p31.height - p31.anchor_height
    else
        local v27 = p31.height - p31.anchor_height

        if math.abs(v27) > 9.999999747378752E-05 then
            p31.height_offset = v27

            if v27 > 0 then
                p31.height = p31.anchor_height
                p31.height_offset = 0
            end
        elseif math.abs(p31.height_offset) > 0.004999999888241291 then
            p31.height_offset *= 0.8999999761581421
            p31.height += p31.height_offset
        else
            p31.height_offset = 0
        end
    end

    p31.transition_time += p32
end

local PERF = import("skate_core/camera/tracker").PERF
local length3 = v1.length3

function t1.bind_angle_settings(p34, p35, p36) -- line: 307
    -- upvalues: t1 (copy), PERF (copy)
    if PERF.reference then
        return t1.bind_angle_settings_reference(p34, p35, p36)
    end

    p34.speed_clamp = p35.speed_clamp_degrees * 0.01745329238474369
    p34.acceleration_clamp_min = p35.acceleration_min_degrees * 0.01745329238474369
    p34.acceleration_clamp_max = p35.acceleration_max_degrees * 0.01745329238474369
    p34.delta_umbra = p35.delta_umbra_degrees * 0.01745329238474369
    p34.delta_penumbra = p35.delta_penumbra_degrees * 0.01745329238474369
    p34.smoothing_min = p36
    p34.smoothing_max = p36
end

function t1.AngularRigTracking.update_heading(p37, p38, p39) -- line: 321
    -- upvalues: AngleTracker (copy), normalize_angle (copy), t1 (copy), PERF (copy)
    if PERF.reference then
        return t1.AngularRigTracking.update_heading_reference(p37, p38, p39)
    end

    if bit32.band(p37.flags_517, 32) == 0 and p37.heading_acceleration_state == 0 then
        return
    end

    local v29 = math.abs((t1.wrap_vmx(p37.heading_target - t1.AngularRigTracking.current_heading(p37))))
    local v30 = 1 - p37.heading_smoothing
    local v31 = if 0.800000011920929 - v30 >= 0 then v30 else 0.800000011920929

    if v29 < 0.7853981852531433 then
        v31 = (v31 - v30) * (v29 * 1.2732396125793457) + v30
    end

    if p37.reset_time > 0 then
        t1.AngularRigTracking.reset_heading(p37, true)
    end

    local heading_parameters = p37.heading_parameters

    t1.bind_angle_settings(heading_parameters, p39, v31)

    if p37.heading_acceleration_state > 0 then
        heading_parameters.acceleration_clamp_min *= 2
        heading_parameters.acceleration_clamp_max *= 2
    end

    heading_parameters.overshoot_zeroes_velocity = false
    AngleTracker.update(p37.heading, p38, normalize_angle(p37.heading_target), heading_parameters)
end

function t1.AngularRigTracking.update_elevation(p40, p41, p42) -- line: 355
    -- upvalues: AngleTracker (copy), normalize_angle (copy), t1 (copy), PERF (copy)
    if PERF.reference then
        return t1.AngularRigTracking.update_elevation_reference(p40, p41, p42)
    end

    if p40.reset_time > 0 then
        t1.AngularRigTracking.reset_elevation(p40, true)
    end

    local elevation_parameters = p40.elevation_parameters

    t1.bind_angle_settings(elevation_parameters, p42, 1 - p40.elevation_smoothing)
    AngleTracker.update(p40.elevation, p41, normalize_angle(p40.elevation_target), elevation_parameters)
end

function t1.AnchorRigTracking.update(p43, p44, p45, p46) -- line: 368
    -- upvalues: VectorTracker (copy), t1 (copy), PERF (copy), length3 (copy)
    if PERF.reference then
        return t1.AnchorRigTracking.update_reference(p43, p44, p45, p46)
    end

    local v32 = t1.AnchorRigTracking.latch_smoothing(p43, p44, p45, p46)
    local v33 = t1.AnchorRigTracking.input_smoothing(p43, p44, p45, p46)
    local v34, v35

    if p46.flag_548(p46) == 0 then
        if bit32.band(p43.flags_517, 64) == 0 then
            v34 = if v32 - v33 >= 0 then v32 else v33
            v35 = false
        else
            v35 = true
        end
    else
        v35 = true
    end

    local v36

    if v35 then
        v36 = 0
    else
        local velocity = p43.velocity

        v36 = v34 * t1.clamp_fraction((length3(velocity[1], velocity[2], velocity[3]) - 8) * -0.25)
    end

    local parameters = p43.parameters

    parameters.speed_clamp = p45.speed_clamp
    parameters.acceleration_clamp_min = p45.acceleration_clamp
    parameters.acceleration_clamp_max = p45.acceleration_clamp
    parameters.smoothing_min = v36
    parameters.smoothing_max = v36

    local anchor = p43.anchor

    VectorTracker.update_lanes(p43.tracker, p44, anchor[1], p43.reference_height, anchor[3], anchor[4], parameters)
end

return t1
