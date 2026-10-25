-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/camera/vector_tracker")
local v2 = import("skate_core/camera/rig_tracking")
local v3 = import("skate_core/camera/rig_framing")
local v4 = import("skate_core/camera/rig_positioning")
local v5 = import("skate_core/camera/avoidance")
local v6 = import("skate_core/physics/reciprocal_sqrt")
local v7 = import("skate_core/camera/rig_initialization")
local AngularRigTracking, AnchorRigTracking, ReferenceHeightTracking = v2.AngularRigTracking, v2.AnchorRigTracking, v2.ReferenceHeightTracking
local RigFraming, RigMode = v3.RigFraming, v3.RigMode
local RigPositioning = v4.RigPositioning
local RigAvoidance = v5.RigAvoidance
local PERF = import("skate_core/camera/tracker").PERF
local t1 = {}

t1.Breadcrumbs = {}

function t1.Breadcrumbs.last(p1) -- line: 35
    -- upvalues: rt (copy)
    return rt.copy(p1.positions[rt.irem(#p1.positions + p1.index - 1, #p1.positions) + 1])
end

function t1.Breadcrumbs.update(p2, p3) -- line: 39
    -- upvalues: rt (copy), v1 (copy)
    local t2 = {}

    t2[1] = p3[1] - p2.positions[p2.index + 1][1]
    t2[2] = p3[2] - p2.positions[p2.index + 1][2]
    t2[3] = p3[3] - p2.positions[p2.index + 1][3]
    t2[4] = p3[4] - p2.positions[p2.index + 1][4]

    if not (v1.dot(t2, t2) > p2.distance_squared_threshold) then
        return
    end

    p2.index += 1

    if p2.index >= #p2.positions then
        p2.index = 0
    end

    p2.positions[p2.index + 1] = rt.copy(p3)
end

t1.RigSettings = {}
t1.RigFields = {}
t1.Rig = {}

function t1.Rig.update_reference(p4, p5, p6, p7, p8, p9, p10) -- line: 78
    -- upvalues: rt (copy), v1 (copy), v6 (copy), AngularRigTracking (copy), AnchorRigTracking (copy), ReferenceHeightTracking (copy), RigFraming (copy), RigMode (copy), RigPositioning (copy), RigAvoidance (copy), t1 (copy)
    p4.fields.reset_time = t1.floor_zero(p4.fields.reset_time - p5)
    p4.fields.disable_avoidance_time = t1.floor_zero(p4.fields.disable_avoidance_time - p5)
    p4.fields.frame_counter = rt.wrapping_add_u32(p4.fields.frame_counter, 1)

    local t3 = {
        current = p4.fields.height_mode,
        previous = p4.fields.previous_height_mode,
        elapsed = p4.fields.mode_time
    }

    RigMode.update(t3, p7)
    p4.fields.height_mode = t3.current
    p4.fields.previous_height_mode = t3.previous
    p4.fields.mode_time = t3.elapsed

    local v8 = rt.copy(p4.fields)
    local t4 = {
        anchor = rt.copy(v8.anchor),
        velocity = rt.copy(v8.velocity),
        tracked_anchor = rt.copy(p4.anchor.position),
        heading_target = v8.heading_target,
        heading_reference = v8.heading_reference,
        elevation_target = v8.elevation_target,
        avoidance_heading = v8.avoidance_heading,
        avoidance_elevation = v8.avoidance_elevation,
        reset_time = v8.reset_time,
        disable_time = v8.disable_avoidance_time,
        height_transition_start = v8.height_transition_start,
        height_transition_end = v8.height_transition_end,
        height_transition_duration = v8.height_transition_duration,
        height_transition_time = v8.height_transition_time,
        reference_height = v8.reference_height,
        prediction_distance = v8.distance,
        heading_weight = v8.heading_weight,
        elevation_weight = v8.elevation_weight,
        avoidance_mode = v8.avoidance_mode,
        height_mode = v8.height_mode,
        flags_516 = v8.flags_516,
        paths = rt.copy(p4.paths)
    }

    RigAvoidance.update(t4, p5, rt.copy(p6.avoidance), p4.positioner, t1.Breadcrumbs.last(p4.breadcrumbs), p7, p8, p9)
    p4.paths = rt.copy(t4.paths)
    p4.fields.avoidance_heading = t4.avoidance_heading
    p4.fields.avoidance_elevation = t4.avoidance_elevation
    p4.fields.heading_weight = t4.heading_weight
    p4.fields.elevation_weight = t4.elevation_weight
    p4.fields.flags_516 = t4.flags_516

    local v9 = rt.copy(p4.fields)
    local t5 = {
        anchor_height = v9.anchor[2],
        transition_start = v9.height_transition_start,
        transition_end = v9.height_transition_end,
        transition_weight = v9.height_transition_weight,
        transition_duration = v9.height_transition_duration,
        transition_time = v9.height_transition_time,
        height = v9.reference_height,
        previous_height = v9.previous_height,
        height_offset = v9.height_offset,
        mode = v9.height_mode,
        flags_516 = v9.flags_516,
        flags_517 = v9.flags_517
    }

    ReferenceHeightTracking.update(t5, p5, p7)
    p4.fields.height_transition_duration = t5.transition_duration
    p4.fields.height_transition_time = t5.transition_time
    p4.fields.reference_height = t5.height
    p4.fields.previous_height = t5.previous_height
    p4.fields.height_offset = t5.height_offset

    local v10 = t1.Rig.angular(p4)

    AngularRigTracking.update_heading(v10, p5, p6.heading)
    AngularRigTracking.update_elevation(v10, p5, p6.elevation)
    t1.Rig.store_angular(p4, v10)

    local v11 = rt.copy(p4.fields)
    local v12 = v1.dot(v11.velocity, v11.velocity)
    local v13 = v6.estimate(v12)
    local v14 = v13 * 0.5 * (-v12 * (v13 * v13) + 1) + v13
    local v15 = v14 * 0.5 * (-v12 * (v14 * v14) + 1) + v14
    local v16 = if v12 == 0 then 0 else v12 * v15
    local t6 = {
        0, 0, 1, 0
    }
    local t7 = {}

    for i = 0, 3 do
        if p6.normalization_threshold[i + 1] < v16 then
            t7[i + 1] = v11.velocity[i + 1] * v15
        else
            t7[i + 1] = t6[i + 1]
        end
    end

    local v17 = v1.dot(v11.acceleration, t7)

    p4.fields.smoothed_acceleration = (v11.previous_acceleration + v17) * 0.5
    p4.fields.previous_acceleration = v17

    local t8 = {
        tracker = rt.copy(p4.anchor),
        parameters = rt.copy(p4.anchor_parameters),
        anchor = rt.copy(v11.anchor),
        velocity = rt.copy(v11.velocity),
        reference_height = v11.reference_height,
        latch_time = v11.latch_time,
        input_time = v11.input_time,
        flags_516 = v11.flags_516,
        flags_517 = v11.flags_517
    }

    AnchorRigTracking.update(t8, p5, p6.anchor, p7)
    p4.anchor = rt.copy(t8.tracker)
    p4.anchor_parameters = rt.copy(t8.parameters)
    p4.fields.latch_time = t8.latch_time
    p4.fields.input_time = t8.input_time
    p4.fields.flags_516 = t8.flags_516

    if bit32.band(p4.positioner.flags, 128) == 0 then
        p4.fields.collision_hold_time = t1.floor_zero(p4.fields.collision_hold_time - p5)
    else
        p4.fields.collision_hold_time = p6.collision_hold_duration
    end

    local v18 = rt.copy(p4.anchor.position)

    v18[2] = p4.fields.reference_height
    t1.Breadcrumbs.update(p4.breadcrumbs, v18)

    local v19 = t1.Rig.framing(p4)
    local v20 = t1.Rig.angular(p4)

    RigFraming.update(v19, p5, v20, rt.copy(p4.anchor.position), p4.positioner, rt.copy(p6.normalization_threshold))
    p4.fields.anchor = rt.copy(v19.anchor)
    p4.fields.distance = v19.distance

    local v21 = rt.copy(p4.fields)
    local t9 = {
        heading_reference = v21.heading_reference,
        elevation_reference = v21.elevation_reference,
        avoidance_heading = v21.avoidance_heading,
        avoidance_elevation = v21.avoidance_elevation,
        elevation_weight = v21.elevation_weight,
        collision_mode = v21.collision_mode,
        flags_516 = v21.flags_516
    }

    RigPositioning.update(t9, p5, p6.positioning, v20, v19, rt.copy(p4.anchor.position), p4.positioner, p4.breadcrumbs.positions, p7, p10)
    t1.Rig.store_angular(p4, v20)
    p4.fields.heading_reference = t9.heading_reference
    p4.fields.elevation_reference = t9.elevation_reference
    p4.fields.avoidance_heading = t9.avoidance_heading
    p4.fields.avoidance_elevation = t9.avoidance_elevation
    p4.fields.elevation_weight = t9.elevation_weight
    p4.fields.flags_516 = t9.flags_516
end

function t1.Breadcrumbs.update_lanes(p11, p12, p13, p14, p15) -- line: 261
    local positions = p11.positions
    local v22 = positions[p11.index + 1]
    local v23 = p12 - v22[1]
    local v24 = p13 - v22[2]
    local v25 = p14 - v22[3]

    if not (v23 * v23 + v24 * v24 + v25 * v25 > p11.distance_squared_threshold) then
        return
    end

    p11.index += 1

    if p11.index >= #positions then
        p11.index = 0
    end

    local v26 = positions[p11.index + 1]

    v26[1] = p12
    v26[2] = p13
    v26[3] = p14
    v26[4] = p15
end

local t10 = {
    current = 0,
    previous = 0,
    elapsed = 0
}
local t11 = {
    anchor = nil,
    velocity = nil,
    tracked_anchor = nil,
    heading_target = 0,
    heading_reference = 0,
    elevation_target = 0,
    avoidance_heading = 0,
    avoidance_elevation = 0,
    reset_time = 0,
    disable_time = 0,
    height_transition_start = 0,
    height_transition_end = 0,
    height_transition_duration = 0,
    height_transition_time = 0,
    reference_height = 0,
    prediction_distance = 0,
    heading_weight = 0,
    elevation_weight = 0,
    avoidance_mode = 0,
    height_mode = 0,
    flags_516 = 0,
    paths = nil
}
local t12 = {
    anchor_height = 0,
    transition_start = 0,
    transition_end = 0,
    transition_weight = 0,
    transition_duration = 0,
    transition_time = 0,
    height = 0,
    previous_height = 0,
    height_offset = 0,
    mode = 0,
    flags_516 = 0,
    flags_517 = 0
}
local t13 = {
    heading = nil,
    heading_parameters = nil,
    elevation = nil,
    elevation_parameters = nil,
    heading_target = 0,
    elevation_target = 0,
    heading_offset = 0,
    reset_time = 0,
    heading_smoothing = 0,
    elevation_smoothing = 0,
    heading_acceleration_state = 0,
    flags_517 = 0
}
local t14 = {
    tracker = nil,
    parameters = nil,
    anchor = nil,
    velocity = nil,
    reference_height = 0,
    latch_time = 0,
    input_time = 0,
    flags_516 = 0,
    flags_517 = 0
}
local t15 = {
    anchor = nil,
    offset = nil,
    elevation_offset = 0,
    additional_elevation = 0,
    reference_height = 0,
    distance = 0
}
local t16 = {
    heading_reference = 0,
    elevation_reference = 0,
    avoidance_heading = 0,
    avoidance_elevation = 0,
    elevation_weight = 0,
    collision_mode = 0,
    flags_516 = 0
}

local function bind_angular(p16, p17) -- line: 374
    -- upvalues: t13 (copy)
    t13.heading = p16.heading
    t13.heading_parameters = p16.heading_parameters
    t13.elevation = p16.elevation
    t13.elevation_parameters = p16.elevation_parameters
    t13.heading_target = p17.heading_target
    t13.elevation_target = p17.elevation_target
    t13.heading_offset = p17.heading_offset
    t13.reset_time = p17.reset_time
    t13.heading_smoothing = p17.heading_smoothing
    t13.elevation_smoothing = p17.elevation_smoothing
    t13.heading_acceleration_state = p17.heading_weight
    t13.flags_517 = p17.flags_517

    return t13
end

local function store_angular_scalars(p18, p19) -- line: 392
    p18.heading_target = p19.heading_target
    p18.elevation_target = p19.elevation_target
    p18.heading_weight = p19.heading_acceleration_state
    p18.flags_517 = p19.flags_517
end

function t1.Rig.update(p20, p21, p22, p23, p24, p25, p26) -- line: 402
    -- upvalues: rt (copy), AngularRigTracking (copy), AnchorRigTracking (copy), ReferenceHeightTracking (copy), RigFraming (copy), RigMode (copy), RigPositioning (copy), RigAvoidance (copy), t1 (copy), PERF (copy), t10 (copy), t11 (copy), t12 (copy), t13 (copy), t14 (copy), t15 (copy), t16 (copy)
    if PERF.reference then
        return t1.Rig.update_reference(p20, p21, p22, p23, p24, p25, p26)
    end

    local fields = p20.fields

    fields.reset_time = t1.floor_zero(fields.reset_time - p21)
    fields.disable_avoidance_time = t1.floor_zero(fields.disable_avoidance_time - p21)
    fields.frame_counter = rt.wrapping_add_u32(fields.frame_counter, 1)
    t10.current = fields.height_mode
    t10.previous = fields.previous_height_mode
    t10.elapsed = fields.mode_time
    RigMode.update(t10, p23)
    fields.height_mode = t10.current
    fields.previous_height_mode = t10.previous
    fields.mode_time = t10.elapsed
    t11.anchor = fields.anchor
    t11.velocity = fields.velocity
    t11.tracked_anchor = p20.anchor.position
    t11.heading_target = fields.heading_target
    t11.heading_reference = fields.heading_reference
    t11.elevation_target = fields.elevation_target
    t11.avoidance_heading = fields.avoidance_heading
    t11.avoidance_elevation = fields.avoidance_elevation
    t11.reset_time = fields.reset_time
    t11.disable_time = fields.disable_avoidance_time
    t11.height_transition_start = fields.height_transition_start
    t11.height_transition_end = fields.height_transition_end
    t11.height_transition_duration = fields.height_transition_duration
    t11.height_transition_time = fields.height_transition_time
    t11.reference_height = fields.reference_height
    t11.prediction_distance = fields.distance
    t11.heading_weight = fields.heading_weight
    t11.elevation_weight = fields.elevation_weight
    t11.avoidance_mode = fields.avoidance_mode
    t11.height_mode = fields.height_mode
    t11.flags_516 = fields.flags_516
    t11.paths = p20.paths

    local breadcrumbs = p20.breadcrumbs
    local positions = breadcrumbs.positions

    RigAvoidance.update(t11, p21, p22.avoidance, p20.positioner, positions[rt.irem(#positions + breadcrumbs.index - 1, #positions) + 1], p23, p24, p25)
    fields.avoidance_heading = t11.avoidance_heading
    fields.avoidance_elevation = t11.avoidance_elevation
    fields.heading_weight = t11.heading_weight
    fields.elevation_weight = t11.elevation_weight
    fields.flags_516 = t11.flags_516
    t11.anchor = nil
    t11.velocity = nil
    t11.tracked_anchor = nil
    t11.paths = nil
    t12.anchor_height = fields.anchor[2]
    t12.transition_start = fields.height_transition_start
    t12.transition_end = fields.height_transition_end
    t12.transition_weight = fields.height_transition_weight
    t12.transition_duration = fields.height_transition_duration
    t12.transition_time = fields.height_transition_time
    t12.height = fields.reference_height
    t12.previous_height = fields.previous_height
    t12.height_offset = fields.height_offset
    t12.mode = fields.height_mode
    t12.flags_516 = fields.flags_516
    t12.flags_517 = fields.flags_517
    ReferenceHeightTracking.update(t12, p21, p23)
    fields.height_transition_duration = t12.transition_duration
    fields.height_transition_time = t12.transition_time
    fields.reference_height = t12.height
    fields.previous_height = t12.previous_height
    fields.height_offset = t12.height_offset
    t13.heading = p20.heading
    t13.heading_parameters = p20.heading_parameters
    t13.elevation = p20.elevation
    t13.elevation_parameters = p20.elevation_parameters
    t13.heading_target = fields.heading_target
    t13.elevation_target = fields.elevation_target
    t13.heading_offset = fields.heading_offset
    t13.reset_time = fields.reset_time
    t13.heading_smoothing = fields.heading_smoothing
    t13.elevation_smoothing = fields.elevation_smoothing
    t13.heading_acceleration_state = fields.heading_weight
    t13.flags_517 = fields.flags_517
    AngularRigTracking.update_heading(t13, p21, p22.heading)
    AngularRigTracking.update_elevation(t13, p21, p22.elevation)
    fields.heading_target = t13.heading_target
    fields.elevation_target = t13.elevation_target
    fields.heading_weight = t13.heading_acceleration_state
    fields.flags_517 = t13.flags_517

    local velocity, acceleration = fields.velocity, fields.acceleration
    local normalization_threshold = p22.normalization_threshold
    local v27 = velocity[1]
    local v28 = velocity[2]
    local v29 = velocity[3]
    local v30 = v27 * v27 + v28 * v28 + v29 * v29
    local v31 = 1 / math.sqrt(v30)
    local v32 = v31 * 0.5 * (-v30 * (v31 * v31) + 1) + v31
    local v33 = v32 * 0.5 * (-v30 * (v32 * v32) + 1) + v32
    local v34 = if v30 == 0 then 0 else v30 * v33
    local v35 = if normalization_threshold[1] < v34 then v27 * v33 else 0
    local v36 = if normalization_threshold[2] < v34 then v28 * v33 else 0
    local v37 = if normalization_threshold[3] < v34 then v29 * v33 else 1
    local v38 = acceleration[1] * v35 + acceleration[2] * v36 + acceleration[3] * v37

    fields.smoothed_acceleration = (fields.previous_acceleration + v38) * 0.5
    fields.previous_acceleration = v38
    t14.tracker = p20.anchor
    t14.parameters = p20.anchor_parameters
    t14.anchor = fields.anchor
    t14.velocity = fields.velocity
    t14.reference_height = fields.reference_height
    t14.latch_time = fields.latch_time
    t14.input_time = fields.input_time
    t14.flags_516 = fields.flags_516
    t14.flags_517 = fields.flags_517
    AnchorRigTracking.update(t14, p21, p22.anchor, p23)
    fields.latch_time = t14.latch_time
    fields.input_time = t14.input_time
    fields.flags_516 = t14.flags_516
    t14.tracker = nil
    t14.parameters = nil
    t14.anchor = nil
    t14.velocity = nil

    local positioner = p20.positioner

    if bit32.band(positioner.flags, 128) == 0 then
        fields.collision_hold_time = t1.floor_zero(fields.collision_hold_time - p21)
    else
        fields.collision_hold_time = p22.collision_hold_duration
    end

    local position = p20.anchor.position

    t1.Breadcrumbs.update_lanes(p20.breadcrumbs, position[1], fields.reference_height, position[3], position[4])
    t15.anchor = fields.anchor
    t15.offset = fields.offset
    t15.elevation_offset = fields.elevation_offset
    t15.additional_elevation = fields.additional_elevation
    t15.reference_height = fields.reference_height
    t15.distance = fields.distance
    t13.heading = p20.heading
    t13.heading_parameters = p20.heading_parameters
    t13.elevation = p20.elevation
    t13.elevation_parameters = p20.elevation_parameters
    t13.heading_target = fields.heading_target
    t13.elevation_target = fields.elevation_target
    t13.heading_offset = fields.heading_offset
    t13.reset_time = fields.reset_time
    t13.heading_smoothing = fields.heading_smoothing
    t13.elevation_smoothing = fields.elevation_smoothing
    t13.heading_acceleration_state = fields.heading_weight
    t13.flags_517 = fields.flags_517
    RigFraming.update(t15, p21, t13, position, positioner, p22.normalization_threshold)
    fields.distance = t15.distance
    t16.heading_reference = fields.heading_reference
    t16.elevation_reference = fields.elevation_reference
    t16.avoidance_heading = fields.avoidance_heading
    t16.avoidance_elevation = fields.avoidance_elevation
    t16.elevation_weight = fields.elevation_weight
    t16.collision_mode = fields.collision_mode
    t16.flags_516 = fields.flags_516
    RigPositioning.update(t16, p21, p22.positioning, t13, t15, position, positioner, p20.breadcrumbs.positions, p23, p26)
    fields.heading_target = t13.heading_target
    fields.elevation_target = t13.elevation_target
    fields.heading_weight = t13.heading_acceleration_state
    fields.flags_517 = t13.flags_517
    fields.heading_reference = t16.heading_reference
    fields.elevation_reference = t16.elevation_reference
    fields.avoidance_heading = t16.avoidance_heading
    fields.avoidance_elevation = t16.avoidance_elevation
    fields.elevation_weight = t16.elevation_weight
    fields.flags_516 = t16.flags_516
    t15.anchor = nil
    t15.offset = nil
    t13.heading = nil
    t13.heading_parameters = nil
    t13.elevation = nil
    t13.elevation_parameters = nil
end

function t1.Rig.angular(p27) -- line: 576
    -- upvalues: rt (copy)
    local fields = p27.fields

    return {
        heading = rt.copy(p27.heading),
        heading_parameters = rt.copy(p27.heading_parameters),
        elevation = rt.copy(p27.elevation),
        elevation_parameters = rt.copy(p27.elevation_parameters),
        heading_target = fields.heading_target,
        elevation_target = fields.elevation_target,
        heading_offset = fields.heading_offset,
        reset_time = fields.reset_time,
        heading_smoothing = fields.heading_smoothing,
        elevation_smoothing = fields.elevation_smoothing,
        heading_acceleration_state = fields.heading_weight,
        flags_517 = fields.flags_517
    }
end

function t1.Rig.store_angular(p28, p29) -- line: 594
    -- upvalues: rt (copy)
    p28.heading = rt.copy(p29.heading)
    p28.heading_parameters = rt.copy(p29.heading_parameters)
    p28.elevation = rt.copy(p29.elevation)
    p28.elevation_parameters = rt.copy(p29.elevation_parameters)
    p28.fields.heading_target = p29.heading_target
    p28.fields.elevation_target = p29.elevation_target
    p28.fields.heading_weight = p29.heading_acceleration_state
    p28.fields.flags_517 = p29.flags_517
end

function t1.Rig.framing(p30) -- line: 605
    -- upvalues: rt (copy)
    local fields = p30.fields

    return {
        anchor = rt.copy(fields.anchor),
        offset = rt.copy(fields.offset),
        elevation_offset = fields.elevation_offset,
        additional_elevation = fields.additional_elevation,
        reference_height = fields.reference_height,
        distance = fields.distance
    }
end

function t1.floor_zero(p31) -- line: 617
    if -p31 >= 0 then
        return 0
    end

    return p31
end

for v39, v40 in v7.Rig do
    t1.Rig[v39] = v40
end

return t1
