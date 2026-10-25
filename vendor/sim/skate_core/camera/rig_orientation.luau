-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/camera/angle_tracker")
local v2 = import("skate_core/camera/direction")
local v3 = import("skate_core/camera/rig_tracking")
local v4 = import("skate_core/camera/orientation_math")
local v5 = import("skate_core/physics/rigid_body")
local v6 = import("skate_core/point_graph")
local AngleTracker, normalize_angle = v1.AngleTracker, v1.normalize_angle
local direction_to_angles = v2.direction_to_angles
local basis_from_quaternion = v5.basis_from_quaternion
local PointGraph = v6.PointGraph
local t1 = {
    OrientationTrackerSettings = {},
    OrientationSettings = {},
    RigOrientation = {}
}

function t1.RigOrientation.new() -- line: 40
    -- upvalues: rt (copy)
    local t2 = {
        {
            target = 0,
            position = 0,
            velocity = 0,
            acceleration = 0,
            acceleration_clamp = 0,
            smoothing = 0
        }
    }
    local t3 = {
        delta_umbra = 0,
        delta_penumbra = 0,
        speed_clamp = 0,
        acceleration_clamp_min = 0,
        acceleration_clamp_max = 0,
        smoothing_min = 0,
        smoothing_max = 0,
        overshoot_zeroes_velocity = true
    }

    return {
        pan_smoothing = 0,
        tilt_smoothing = 0,
        roll = 0,
        framing_mirror = 1,
        target = { 0, 0, 0, 0 },
        basis = {
            columns = {
                { 1, 0, 0 },
                { 0, 1, 0 },
                { 0, 0, 1 }
            }
        },
        pitch = rt.copy(t2),
        yaw = rt.copy(t2),
        pitch_parameters = rt.copy(t3),
        yaw_parameters = rt.copy(t3)
    }
end

function t1.RigOrientation.update_reference(p1, p2, p3, p4, p5, p6) -- line: 79
    -- upvalues: rt (copy), v3 (copy), v4 (copy), AngleTracker (copy), normalize_angle (copy), direction_to_angles (copy), basis_from_quaternion (copy), PointGraph (copy), t1 (copy)
    local v11 = basis_from_quaternion({
        x = p1.target[1],
        y = p1.target[2],
        z = p1.target[3],
        w = p1.target[4]
    }).columns[3]
    local v12 = direction_to_angles({
        v11[1],
        v11[2],
        v11[3],
        0
    })
    local v13 = -v12[1]
    local v14 = v12[2]
    local v15 = normalize_angle(normalize_angle(v14) - p1.yaw[1].position)

    if v15 < normalize_angle(0) then
        v15 = normalize_angle(normalize_angle(-v15))
    end

    local v16 = p3.pan_umbra_degrees * 0.01745329238474369
    local v17 = p3.pan_penumbra_degrees * 0.01745329238474369
    local v18 = if v15 < v16 then 1 elseif v15 < v17 then 1 - v3.wrap_vmx(v15 - v16) / v3.wrap_vmx(v17 - v16) else 0
    local v19 = PointGraph.evaluate(p3.pan_smoothing_curve, v18)
    local v20 = 1 - p3.pan_minimum_smoothing
    local v21 = -(v20 * v20 - 1)
    local v22 = if v21 <= p1.pan_smoothing then (p1.pan_smoothing - v21) * v19 + v21 else p1.pan_smoothing
    local v23 = t1.cap_smoothing(v22)

    p1.tilt_smoothing = t1.cap_smoothing(p1.tilt_smoothing)

    local v24 = p5

    if bit32.band(p5, 8) ~= 0 or p4 > 0 then
        t1.reset(p1.pitch, v13)
        t1.reset(p1.yaw, v14)
        v24 = bit32.band(p5, 247)
    end

    if bit32.band(v24, 64) ~= 0 then
        t1.bind(p1.pitch_parameters, p3.tilt, p1.tilt_smoothing, bit32.band(p6, 16) ~= 0)
        AngleTracker.update(p1.pitch, p2, normalize_angle(v13), rt.copy(p1.pitch_parameters))
    end

    t1.bind(p1.yaw_parameters, p3.pan, v23, true)
    AngleTracker.update(p1.yaw, p2, normalize_angle(v14), rt.copy(p1.yaw_parameters))

    local v25 = v4.basis_from_angles(p1.pitch[1].position, p1.yaw[1].position, 0)

    p1.basis = v4.rotate_about_axis(v25, v25.columns[3], p1.roll * p1.framing_mirror)

    return v24
end

function t1.reset(p7, p8) -- line: 130
    -- upvalues: normalize_angle (copy)
    p7[1].target = normalize_angle(p8)
    p7[1].position = normalize_angle(p8)
    p7[1].velocity = 0
    p7[1].acceleration = 0
end

function t1.cap_smoothing(p9) -- line: 137
    if p9 >= 1 then
        return 1
    end

    if 0.8999999761581421 - p9 >= 0 then
        return p9
    end

    return 0.8999999761581421
end

function t1.bind_reference(p10, p11, p12, p13) -- line: 147
    -- upvalues: rt (copy)
    p10.speed_clamp = rt.F32_MAX

    if p13 then
        p10.acceleration_clamp_min = p11.acceleration_min_degrees * 0.01745329238474369
        p10.acceleration_clamp_max = p11.acceleration_max_degrees * 0.01745329238474369
    else
        p10.acceleration_clamp_min = rt.F32_MAX
        p10.acceleration_clamp_max = rt.F32_MAX
    end

    if p12 < 1 then
        if p11.smoothing_min - p12 >= 0 then
            p10.smoothing_min = p12
        else
            p10.smoothing_min = p11.smoothing_min
        end
    else
        p10.smoothing_min = 1
    end

    if p12 < 1 then
        p10.smoothing_max = p12
    else
        p10.smoothing_max = 1
    end

    p10.delta_umbra = p11.delta_umbra_degrees * 0.01745329238474369
    p10.delta_penumbra = p11.delta_penumbra_degrees * 0.01745329238474369
end

local PERF = import("skate_core/camera/tracker").PERF
local direction_to_angles_lanes = v2.direction_to_angles_lanes
local basis_from_angles_lanes = v4.basis_from_angles_lanes
local v26 = import("skate_core/trigonometry")
local quaternion_at_lanes = v4.quaternion_at_lanes

function t1.bind(p14, p15, p16, p17) -- line: 197
    -- upvalues: rt (copy), t1 (copy), PERF (copy)
    if PERF.reference then
        return t1.bind_reference(p14, p15, p16, p17)
    end

    p14.speed_clamp = rt.F32_MAX

    if p17 then
        p14.acceleration_clamp_min = p15.acceleration_min_degrees * 0.01745329238474369
        p14.acceleration_clamp_max = p15.acceleration_max_degrees * 0.01745329238474369
    else
        p14.acceleration_clamp_min = rt.F32_MAX
        p14.acceleration_clamp_max = rt.F32_MAX
    end

    if p16 < 1 then
        if p15.smoothing_min - p16 >= 0 then
            p14.smoothing_min = p16
        else
            p14.smoothing_min = p15.smoothing_min
        end
    else
        p14.smoothing_min = 1
    end

    if p16 < 1 then
        p14.smoothing_max = p16
    else
        p14.smoothing_max = 1
    end

    p14.delta_umbra = p15.delta_umbra_degrees * 0.01745329238474369
    p14.delta_penumbra = p15.delta_penumbra_degrees * 0.01745329238474369
end

local function cap_smoothing2(p18) -- line: 223
    if p18 >= 1 then
        return 1
    end

    if 0.8999999761581421 - p18 >= 0 then
        return p18
    end

    return 0.8999999761581421
end

function t1.RigOrientation.update(p19, p20, p21, p22, p23, p24) -- line: 235
    -- upvalues: v3 (copy), AngleTracker (copy), normalize_angle (copy), PointGraph (copy), t1 (copy), PERF (copy), direction_to_angles_lanes (copy), basis_from_angles_lanes (copy), v26 (copy), quaternion_at_lanes (copy)
    if PERF.reference then
        return t1.RigOrientation.update_reference(p19, p20, p21, p22, p23, p24)
    end

    local target = p19.target
    local v27, v28 = direction_to_angles_lanes(quaternion_at_lanes(target[1], target[2], target[3], target[4]))
    local v29 = -v27
    local yaw, pitch = p19.yaw, p19.pitch
    local v30 = normalize_angle(normalize_angle(v28) - yaw[1].position)

    if v30 < normalize_angle(0) then
        v30 = normalize_angle(normalize_angle(-v30))
    end

    local v31 = p21.pan_umbra_degrees * 0.01745329238474369
    local v32 = p21.pan_penumbra_degrees * 0.01745329238474369
    local v33 = if v30 < v31 then 1 elseif v30 < v32 then 1 - v3.wrap_vmx(v30 - v31) / v3.wrap_vmx(v32 - v31) else 0
    local v34 = PointGraph.evaluate(p21.pan_smoothing_curve, v33)
    local v35 = 1 - p21.pan_minimum_smoothing
    local v36 = -(v35 * v35 - 1)
    local v37 = if v36 <= p19.pan_smoothing then (p19.pan_smoothing - v36) * v34 + v36 else p19.pan_smoothing

    if v37 >= 1 then
        v37 = 1
    elseif not (0.8999999761581421 - v37 >= 0) then
        v37 = 0.8999999761581421
    end

    local tilt_smoothing = p19.tilt_smoothing

    if tilt_smoothing >= 1 then
        tilt_smoothing = 1
    elseif not (0.8999999761581421 - tilt_smoothing >= 0) then
        tilt_smoothing = 0.8999999761581421
    end

    p19.tilt_smoothing = tilt_smoothing

    local v38 = p23

    if bit32.band(p23, 8) ~= 0 or p22 > 0 then
        t1.reset(pitch, v29)
        t1.reset(yaw, v28)
        v38 = bit32.band(p23, 247)
    end

    if bit32.band(v38, 64) ~= 0 then
        local pitch_parameters = p19.pitch_parameters

        t1.bind(pitch_parameters, p21.tilt, p19.tilt_smoothing, bit32.band(p24, 16) ~= 0)
        AngleTracker.update(pitch, p20, normalize_angle(v29), pitch_parameters)
    end

    local yaw_parameters = p19.yaw_parameters

    t1.bind(yaw_parameters, p21.pan, v37, true)
    AngleTracker.update(yaw, p20, normalize_angle(v28), yaw_parameters)

    local v39, v40, v41, v42, v43, v44, v45, v46, v47 = basis_from_angles_lanes(pitch[1].position, yaw[1].position, 0)
    local v48 = p19.roll * p19.framing_mirror
    local v49 = v26.cos(v48)
    local v50 = v26.sin(v48)
    local v51 = v50 * v45
    local v52 = v50 * v46
    local v53 = v50 * v47
    local v54 = 1 - v49
    local v55 = v54 * v45
    local v56 = v54 * v46
    local v57 = v54 * v47
    local v58 = v45 * v55 + v49
    local v59 = v55 * v46 + v53
    local v60 = v55 * v47 - v52
    local v61 = v56 * v45 - v53
    local v62 = v56 * v46 + v49
    local v63 = v56 * v47 + v51
    local v64 = v57 * v45 + v52
    local v65 = v57 * v46 - v51
    local v66 = v47 * v57 + v49
    local columns = p19.basis.columns
    local v67 = columns[1]

    v67[1] = v64 * v41 + (v61 * v40 + v58 * v39)
    v67[2] = v65 * v41 + (v62 * v40 + v59 * v39)
    v67[3] = v66 * v41 + (v63 * v40 + v60 * v39)

    local v68 = columns[2]

    v68[1] = v64 * v44 + (v61 * v43 + v58 * v42)
    v68[2] = v65 * v44 + (v62 * v43 + v59 * v42)
    v68[3] = v66 * v44 + (v63 * v43 + v60 * v42)

    local v69 = columns[3]

    v69[1] = v64 * v47 + (v61 * v46 + v58 * v45)
    v69[2] = v65 * v47 + (v62 * v46 + v59 * v45)
    v69[3] = v66 * v47 + (v63 * v46 + v60 * v45)

    return v38
end

return t1
