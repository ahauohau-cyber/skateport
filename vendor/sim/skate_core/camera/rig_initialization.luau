-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/camera/rig_tracking")
local AngularRigTracking = v1.AngularRigTracking

local function rig_module() -- line: 13
    -- upvalues: import (copy)
    return import("skate_core/camera/rig")
end

local t1 = {
    Rig = {}
}

function t1.Rig.new(p1) -- line: 24
    -- upvalues: rt (copy), t1 (copy)
    local v2 = t1.tracker_parameters()
    local t2 = {
        fields = t1.fields(p1),
        heading = { t1.scalar(0) },
        heading_parameters = rt.copy(v2),
        elevation = { t1.scalar(0) },
        elevation_parameters = rt.copy(v2),
        anchor = {
            acceleration_clamp = 0,
            smoothing = 0,
            target = { 0, 0, 0, 0 },
            position = { 0, 0, 0, 0 },
            velocity = { 0, 0, 0, 0 },
            acceleration = { 0, 0, 0, 0 }
        },
        anchor_parameters = rt.copy(v2),
        positioner = {
            distance = 0,
            heading = 0,
            elevation = 0,
            radius = 0.12999999523162842,
            available_distance = 0,
            flags = 0,
            distance_tracker = t1.scalar(1),
            tracker_parameters = rt.copy(v2),
            offset = { 0, 0, 0, 0 },
            previous_valid_position = { 0, 0, 0, 0 },
            reference_position = { 0, 0, 0, 0 },
            collision_clear_time = rt.F32_MAX,
            config = {
                reference_heading = 0,
                reference_elevation = 0,
                heading = 0,
                elevation = 0,
                distance = 0,
                minimum_distance = 0,
                collision_enabled = 0,
                bypass_distance_tracker = 0,
                clamp_height = 0,
                floor_height = 0,
                speed_clamp = 0,
                acceleration_clamp = 0,
                smoothing = 0,
                anchor = { 0, 0, 0, 0 },
                offset = { 0, 0, 0, 0 },
                query_starts = rt.filled(3, { 0, 0, 0, 0 })
            },
            position = { 0, 0, 0, 0 },
            velocity = { 0, 0, 0, 0 }
        },
        paths = rt.filled(3, {
            prediction_flag = 0,
            evaluator = {
                request_state = 0,
                acceleration_flag = 0,
                found = 0,
                result_acceleration_flag = 0,
                submitted_acceleration_flag = 0,
                pending_polls = 0,
                path = {
                    radius = 0,
                    horizon = 0,
                    position = { 0, 0, 0, 0 },
                    velocity = { 0, 0, 0, 0 }
                },
                collision_time = rt.F32_MAX,
                last_valid_time = rt.F32_MAX
            }
        }),
        breadcrumbs = {
            index = 0,
            distance_squared_threshold = 1,
            positions = rt.filled(2, { 0, 0, 0, 0 })
        }
    }

    t1.Rig.reset_angles(t2)

    return t2
end

function t1.Rig.reset(p2) -- line: 107
    -- upvalues: rt (copy), t1 (copy)
    local v3 = rt.copy(p2.fields)

    p2.fields = t1.fields(v3.avoidance_mode)
    p2.fields.height_transition_weight = v3.height_transition_weight
    p2.fields.flags_517 = bit32.bor(bit32.band(v3.flags_517, 15), 48)
    p2.breadcrumbs.distance_squared_threshold = 1
    t1.Rig.reset_angles(p2)
end

function t1.Rig.teleport(p3) -- line: 117
    -- upvalues: rt (copy), t1 (copy)
    p3.fields.avoidance_heading = 0
    p3.fields.avoidance_elevation = 0
    p3.fields.heading_weight = 0
    p3.fields.elevation_weight = 0
    p3.fields.flags_516 = bit32.band(p3.fields.flags_516, 254)
    t1.Rig.reset_angles(p3)
    p3.anchor.target = rt.copy(p3.fields.anchor)
    p3.anchor.position = rt.copy(p3.fields.anchor)
    p3.anchor.velocity = { 0, 0, 0, 0 }
    p3.anchor.acceleration = { 0, 0, 0, 0 }
    p3.fields.reference_height = p3.fields.anchor[2]
    p3.fields.height_offset = 0
    p3.fields.offset = { 0, 0, 0, 0 }
    p3.positioner.distance_tracker.target = p3.fields.distance
    p3.positioner.distance_tracker.position = p3.fields.distance
    p3.positioner.distance_tracker.velocity = 0
    p3.positioner.distance_tracker.acceleration = 0
    p3.fields.reset_time = 0.10000000149011612
    p3.fields.disable_avoidance_time = 2
    p3.fields.collision_hold_time = 5
    p3.fields.height_transition_duration = 0
    p3.fields.flags_517 = bit32.band(p3.fields.flags_517, 191)
    p3.fields.previous_acceleration = 0
    p3.fields.flags_516 = bit32.bor(bit32.band(p3.fields.flags_516, 179), 8)
    p3.fields.input_time = 0
    p3.fields.latch_time = 0
end

function t1.Rig.set_elevation(p4, p5, p6) -- line: 148
    -- upvalues: v1 (copy)
    p4.fields.elevation_target = p5
    p4.fields.elevation_reference = p5

    if not p6 then
        return
    end

    p4.fields.flags_516 = bit32.bor(p4.fields.flags_516, bit32.band(p4.positioner.flags, 16) == 0 and 0 or 1)

    if bit32.band(p4.fields.flags_516, 1) ~= 0 then
        local v7 = v1.wrap_vmx(p4.fields.avoidance_elevation - p5)

        p4.fields.elevation_target = v1.wrap_vmx(v1.wrap_vmx(v7 * p4.fields.elevation_weight + p5))
    end
end

function t1.Rig.reset_angles(p7) -- line: 165
    -- upvalues: import (copy), AngularRigTracking (copy)
    local Rig = import("skate_core/camera/rig").Rig
    local v8 = Rig.angular(p7)

    AngularRigTracking.reset_heading(v8, true)
    AngularRigTracking.reset_elevation(v8, true)
    Rig.store_angular(p7, v8)
end

function t1.scalar(p8) -- line: 173
    return {
        velocity = 0,
        acceleration = 0,
        acceleration_clamp = 0,
        smoothing = 0,
        target = p8,
        position = p8
    }
end

function t1.tracker_parameters() -- line: 184
    return {
        delta_umbra = 0,
        delta_penumbra = 0,
        speed_clamp = 0,
        acceleration_clamp_min = 0,
        acceleration_clamp_max = 0,
        smoothing_min = 0,
        smoothing_max = 0,
        overshoot_zeroes_velocity = true
    }
end

function t1.fields(p9) -- line: 197
    -- upvalues: rt (copy)
    return {
        anchor = { 0, 0, 0, 0 },
        velocity = { 0, 0, 0, 0 },
        acceleration = { 0, 0, 0, 0 },
        offset = { 0, 0, 0, 0 },
        heading_target = 3.1415927410125732,
        heading_reference = 3.1415927410125732,
        elevation_reference = 0,
        elevation_target = 0,
        elevation_offset = 0,
        additional_elevation = 0,
        heading_offset = 0,
        avoidance_heading = 0,
        avoidance_elevation = 0,
        smoothed_acceleration = 0,
        previous_acceleration = 0,
        collision_hold_time = 5,
        reset_time = 2,
        disable_avoidance_time = 0,
        height_transition_start = 0,
        height_transition_end = 0,
        height_transition_weight = 0,
        height_transition_duration = 0,
        height_transition_time = 0,
        reference_height = 1000,
        previous_height = rt.F32_MAX,
        height_offset = 0,
        latch_time = 0,
        input_time = 0,
        distance = 1,
        heading_smoothing = 1,
        elevation_smoothing = 1,
        heading_weight = 0,
        elevation_weight = 0,
        mode_time = 0,
        frame_counter = 0,
        collision_mode = 0,
        avoidance_mode = p9,
        height_mode = 0,
        previous_height_mode = 0,
        flags_516 = 136,
        flags_517 = 48
    }
end

return t1
