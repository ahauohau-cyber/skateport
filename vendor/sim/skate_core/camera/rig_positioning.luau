-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/camera/rig_tracking")
local v2 = import("skate_core/camera/positioner")
local AngularRigTracking = v1.AngularRigTracking
local Positioner = v2.Positioner
local t1 = {
    RigPositioningSubject = {},
    DistanceTrackingSettings = {},
    RigPositioningSettings = {},
    RigPositioning = {}
}

function t1.RigPositioning.update_reference(p1, p2, p3, p4, p5, p6, p7, p8, p9, p10) -- line: 35
    -- upvalues: rt (copy), AngularRigTracking (copy), Positioner (copy), t1 (copy)
    local v3 = p9.flag_668(p9) ~= 0
    local v4 = rt.copy(p6)

    v4[2] = p5.reference_height

    local v5 = AngularRigTracking.current_heading(p4)
    local v6 = t1.clamp_elevation(p5.elevation_offset + p4.elevation[1].position)
    local v7 = AngularRigTracking.current_heading(p4)
    local v8 = t1.clamp_elevation(p5.additional_elevation + p5.elevation_offset + p4.elevation[1].position)
    local v9 = if p5.distance == p5.distance then p5.distance else 1
    local v10 = if p9.flag_548(p9) == 0 then p3.minimum_distance else p3.alternate_minimum_distance
    local v11 = p9.flag_660(p9)
    local v12 = p9.value_524(p9)
    local v13 = if v3 then rt.copy(p3.alternate) else rt.copy(p3.normal)
    local v14 = rt.copy(p9.transform_384(p9)[2])
    local v15 = p9.position_360(p9, 3)
    local v16 = p9.position_360(p9, 0)
    local v17 = p9.position_360(p9, 7)
    local t2 = {}

    t2[1] = v14[1] * 0.15000000596046448 + v17[1]
    t2[2] = v14[2] * 0.15000000596046448 + v17[2]
    t2[3] = v14[3] * 0.15000000596046448 + v17[3]
    t2[4] = v14[4] * 0.15000000596046448 + v17[4]

    local t3 = {
        anchor = v4,
        offset = rt.copy(p5.offset),
        reference_heading = v5,
        reference_elevation = v6,
        heading = v7,
        elevation = v8,
        distance = v9,
        minimum_distance = v10,
        collision_enabled = p1.collision_mode == 2 and 0 or 1,
        bypass_distance_tracker = bit32.band(p4.flags_517, 64) == 0 and 0 or 1,
        clamp_height = v11,
        floor_height = v12,
        speed_clamp = v13.speed_clamp,
        acceleration_clamp = v13.acceleration_clamp,
        smoothing = v13.smoothing,
        query_starts = {
            rt.copy(v15),
            rt.copy(v16),
            t2
        }
    }

    if not (p4.reset_time <= 0) then
        p7.distance_tracker.target = v9
        p7.distance_tracker.position = v9
        p7.distance_tracker.velocity = 0
        p7.distance_tracker.acceleration = 0
    end

    p4.flags_517 = bit32.band(p4.flags_517, 191)

    local v18 = p9.context_532(p9)

    Positioner.update(p7, p2, v18, t3, p10)

    if bit32.band(p7.flags, 4) ~= 0 then
        return
    end

    p4.heading_acceleration_state = 1
    p1.elevation_weight = 1
    p1.avoidance_heading = p7.heading
    p1.avoidance_elevation = p7.elevation

    for i = 1, #p8 do
        p8[i] = rt.copy(p7.position)
    end

    p1.heading_reference = p7.heading
    p4.heading_target = t1.blend_angle(p1.avoidance_heading, p1.heading_reference, 1 - p4.heading_acceleration_state)
    t1.RigPositioning.set_elevation(p1, p7.elevation, true, p4, p7.flags)
    AngularRigTracking.reset_heading(p4, true)
    AngularRigTracking.reset_elevation(p4, true)
    p1.flags_516 = bit32.bor(p1.flags_516, 8)
end

function t1.RigPositioning.set_elevation(p11, p12, p13, p14, p15) -- line: 134
    -- upvalues: v1 (copy), t1 (copy)
    p14.elevation_target = p12
    p11.elevation_reference = p12

    if p13 then
        p11.flags_516 = bit32.bor(p11.flags_516, (bit32.band(bit32.rshift(p15, 4), 1)))

        if bit32.band(p11.flags_516, 1) ~= 0 then
            p14.elevation_target = t1.blend_angle(p14.elevation_target, p11.avoidance_elevation, p11.elevation_weight)
        end
    end

    p14.elevation_target = v1.wrap_vmx(p14.elevation_target)
end

function t1.blend_angle(p16, p17, p18) -- line: 151
    -- upvalues: v1 (copy)
    return v1.wrap_vmx(p18 * v1.wrap_vmx(p17 - p16) + p16)
end

function t1.clamp_elevation_reference(p19) -- line: 155
    local v21 = if -1.3962633609771729 - p19 >= 0 then -1.3962633609771729 else p19

    if 1.3962633609771729 - v21 >= 0 then
        return v21
    end

    return 1.3962633609771729
end

local PERF = import("skate_core/camera/tracker").PERF

function t1.clamp_elevation(p20) -- line: 186
    local v22 = if -1.3962633609771729 - p20 >= 0 then -1.3962633609771729 else p20

    if 1.3962633609771729 - v22 >= 0 then
        return v22
    end

    return 1.3962633609771729
end

function t1.RigPositioning.update(p21, p22, p23, p24, p25, p26, p27, p28, p29, p30) -- line: 197
    -- upvalues: AngularRigTracking (copy), Positioner (copy), t1 (copy), PERF (copy)
    if PERF.reference then
        return t1.RigPositioning.update_reference(p21, p22, p23, p24, p25, p26, p27, p28, p29, p30)
    end

    local v23 = p29.flag_668(p29) ~= 0
    local v24 = p26[1]
    local v25 = p26[3]
    local v26 = p26[4]
    local reference_height = p25.reference_height
    local position = p24.elevation[1].position
    local v27 = AngularRigTracking.current_heading(p24)
    local v28 = t1.clamp_elevation(p25.elevation_offset + position)
    local v29 = AngularRigTracking.current_heading(p24)
    local v30 = t1.clamp_elevation(p25.additional_elevation + p25.elevation_offset + position)
    local v31 = if p25.distance == p25.distance then p25.distance else 1
    local v32 = if p29.flag_548(p29) == 0 then p23.minimum_distance else p23.alternate_minimum_distance
    local v33 = p29.flag_660(p29)
    local v34 = p29.value_524(p29)
    local v35 = if v23 then p23.alternate else p23.normal
    local v36 = p29.transform_384(p29)[2]
    local v37 = v36[1]
    local v38 = v36[2]
    local v39 = v36[3]
    local v40 = v36[4]
    local v41 = p29.position_360(p29, 3)
    local v42 = v41[1]
    local v43 = v41[2]
    local v44 = v41[3]
    local v45 = v41[4]
    local v46 = p29.position_360(p29, 0)
    local v47 = v46[1]
    local v48 = v46[2]
    local v49 = v46[3]
    local v50 = v46[4]
    local v51 = p29.position_360(p29, 7)
    local v52 = v37 * 0.15000000596046448 + v51[1]
    local v53 = v38 * 0.15000000596046448 + v51[2]
    local v54 = v39 * 0.15000000596046448 + v51[3]
    local v55 = v40 * 0.15000000596046448 + v51[4]
    local offset = p25.offset
    local v56 = offset[1]
    local v57 = offset[2]
    local v58 = offset[3]
    local v59 = offset[4]
    local config = p27.config
    local anchor = config.anchor

    anchor[1] = v24
    anchor[2] = reference_height
    anchor[3] = v25
    anchor[4] = v26

    local offset2 = config.offset

    offset2[1] = v56
    offset2[2] = v57
    offset2[3] = v58
    offset2[4] = v59
    config.reference_heading = v27
    config.reference_elevation = v28
    config.heading = v29
    config.elevation = v30
    config.distance = v31
    config.minimum_distance = v32
    config.collision_enabled = p21.collision_mode == 2 and 0 or 1
    config.bypass_distance_tracker = bit32.band(p24.flags_517, 64) == 0 and 0 or 1
    config.clamp_height = v33
    config.floor_height = v34
    config.speed_clamp = v35.speed_clamp
    config.acceleration_clamp = v35.acceleration_clamp
    config.smoothing = v35.smoothing

    local query_starts = config.query_starts
    local v60 = query_starts[1]

    v60[1] = v42
    v60[2] = v43
    v60[3] = v44
    v60[4] = v45

    local v61 = query_starts[2]

    v61[1] = v47
    v61[2] = v48
    v61[3] = v49
    v61[4] = v50

    local v62 = query_starts[3]

    v62[1] = v52
    v62[2] = v53
    v62[3] = v54
    v62[4] = v55

    if not (p24.reset_time <= 0) then
        local distance_tracker = p27.distance_tracker

        distance_tracker.target = v31
        distance_tracker.position = v31
        distance_tracker.velocity = 0
        distance_tracker.acceleration = 0
    end

    p24.flags_517 = bit32.band(p24.flags_517, 191)

    local v63 = p29.context_532(p29)

    Positioner.update(p27, p22, v63, config, p30)

    if bit32.band(p27.flags, 4) ~= 0 then
        return
    end

    p24.heading_acceleration_state = 1
    p21.elevation_weight = 1
    p21.avoidance_heading = p27.heading
    p21.avoidance_elevation = p27.elevation

    local position2 = p27.position
    local v64 = position2[1]
    local v65 = position2[2]
    local v66 = position2[3]
    local v67 = position2[4]

    for i = 1, #p28 do
        local v68 = p28[i]

        v68[1] = v64
        v68[2] = v65
        v68[3] = v66
        v68[4] = v67
    end

    p21.heading_reference = p27.heading
    p24.heading_target = t1.blend_angle(p21.avoidance_heading, p21.heading_reference, 1 - p24.heading_acceleration_state)
    t1.RigPositioning.set_elevation(p21, p27.elevation, true, p24, p27.flags)
    AngularRigTracking.reset_heading(p24, true)
    AngularRigTracking.reset_elevation(p24, true)
    p21.flags_516 = bit32.bor(p21.flags_516, 8)
end

return t1
