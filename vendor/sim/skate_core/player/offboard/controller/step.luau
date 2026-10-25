-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/player/offboard/cadence")
local v2 = import("skate_core/player/offboard/contact_correction")
local v3 = import("skate_core/player/offboard/ground_branch")
local v4 = import("skate_core/player/offboard/ground_motion")
local v5 = import("skate_core/player/offboard/movement_intent")
local v6 = import("skate_core/player/offboard/movement_velocity")
local v7 = import("skate_core/player/offboard/position_output")
local v8 = import("skate_core/player/offboard/slide")
local v9 = import("skate_core/player/offboard/surface_frame")
local BipedCadence = v1.BipedCadence
local ContactCorrection = v2.ContactCorrection
local SpecialMode, Sliding = v8.SpecialMode, v8.Sliding
local FrameOutput = v7.FrameOutput
local t1 = {}

function t1.xyz(p1) -- line: 29
    return {
        p1[1],
        p1[2],
        p1[3]
    }
end

local xyz = t1.xyz
local velocity

function t1.update(p2, p3, p4) -- line: 37
    -- upvalues: rt (copy), v3 (copy), v4 (copy), v5 (copy), v7 (copy), v9 (copy), BipedCadence (copy), ContactCorrection (copy), SpecialMode (copy), Sliding (copy), FrameOutput (copy), xyz (copy), velocity (ref)
    p2.intent.speed = 0
    p2.intent.steering = 0
    SpecialMode.update(p2.special, p4.movement, p4.flags, p2.motion.frame_0[3][2])
    ContactCorrection.update(p2.contact, {
        collision_displacements = rt.copy(p4.collision_displacements),
        projection_axis_416 = rt.copy(p2.surface.spring_normal),
        up_axis_16 = rt.copy(p2.motion.frame_0[2])
    })
    Sliding.update(p2.sliding, {
        special_mode_714 = p2.special.enabled_714,
        surface_normal_560 = rt.copy(p2.surface.source_normal),
        movement_velocity_480 = rt.copy(p2.motion.velocity_480),
        contact_direction_400 = if p2.contact.active then rt.copy(p2.contact.direction) else nil
    }, p3.slide_vs_slope, p3.slide_vs_speed)
    v5.State.update(p2.intent, p3.movement_intent, {
        flags = p4.flags,
        suppress_minimum = p4.suppress_minimum,
        magnitude = p4.movement,
        steering = p4.steering,
        sprint_pressed = p4.sprint_pressed,
        edge_active = p4.edge_active,
        ignore_obstacle = p4.ignore_obstacle,
        direction = rt.copy(p4.desired_direction),
        edge_tangent = rt.copy(p4.target_frame[3]),
        edge_point = rt.copy(p4.target_frame[4]),
        right = rt.copy(p2.motion.frame_0[1]),
        up = rt.copy(p2.motion.frame_0[2]),
        forward = rt.copy(p2.motion.frame_0[3]),
        position = rt.copy(p2.motion.frame_0[4]),
        obstacle = p2.contact.active,
        obstacle_normal = rt.copy(p2.contact.direction),
        sliding = p2.sliding.active_710,
        slide_velocity = rt.copy(p2.sliding.velocity_528)
    })
    p2.alternate_709 = v3.select_alternate({
        movement_velocity_480 = rt.copy(p2.motion.velocity_480),
        output_velocity_512 = rt.copy(p2.frame_output.velocity),
        right_0 = rt.copy(p2.motion.frame_0[1]),
        position_48 = rt.copy(p2.motion.frame_0[4]),
        contact_point_96 = rt.copy(p4.target_position),
        contact_flags_176 = p4.flags,
        suppressed_317 = p4.suppress_lean
    })

    if p2.alternate_709 then
        local v10 = rt.copy(p2.motion.frame_0[3])

        p2.motion.speed_704 = v3.integrate_alternate(p2.motion.velocity_480, p2.motion.speed_704, p2.motion.frame_0[4], p2.frame_output, v10, rt.copy(p2.surface.final_up), rt.copy(p2.surface.spring_normal))
    else
        velocity(p2, p3, p4)
        v9.State.update_surface(p2.surface, {
            flags = p4.flags,
            normal = rt.copy(p4.contact_normal),
            origin = rt.copy(p4.contact_position),
            edge_point = rt.copy(p4.edge_position),
            edge_normal = rt.copy(p4.edge_normal)
        })
        v9.State.update_spring(p2.surface, {
            velocity = rt.copy(p2.motion.velocity_480),
            up = rt.copy(p2.motion.frame_0[2]),
            right = rt.copy(p2.motion.frame_0[1]),
            forward = rt.copy(p2.motion.frame_0[3]),
            spring_right = rt.copy(p2.frame_output.frame[1]),
            spring_forward = rt.copy(p2.frame_output.frame[3]),
            right_delta = p2.right_delta_696,
            forward_delta = p2.forward_delta_692,
            suppress_lean = p4.suppress_lean
        })
        v4.update(p2.motion, {
            contact_position_0 = rt.copy(p4.contact_position),
            contact_frame_32 = rt.copy(p4.support_frame),
            contact_target_96 = rt.copy(p4.target_position),
            contact_normal_112 = rt.copy(p4.target_normal),
            contact_flags_176 = p4.flags,
            contact_id_180 = p4.support_id,
            animation_motion_224 = rt.copy(p4.animation_motion),
            animation_motion_240 = rt.copy(p4.animation_velocity),
            requested_duration_288 = p4.requested_duration,
            mirrored_292 = p4.mirrored,
            animation_directed_304 = p4.animation_directed,
            target_frame_present_352 = p4.target_frame_present,
            target_frame_368 = rt.copy(p4.target_frame),
            reference_frame_128 = rt.copy(p2.frame_output.frame),
            contact_displacement_384 = rt.copy(p2.contact.displacement),
            velocity_addition_528 = rt.copy(p2.sliding.velocity_528),
            desired_up_544 = rt.copy(p2.surface.surface_normal),
            correction_target_592 = rt.copy(p2.correction_target_592),
            obstacle_target_672 = rt.copy(p2.intent.edge_target),
            obstacle_enabled_713 = p2.intent.edge_aligned
        })
        FrameOutput.update(p2.frame_output, rt.copy(p2.motion.frame_0[3]), rt.copy(p2.surface.final_up), rt.copy(p2.surface.spring_normal), rt.copy(p2.motion.frame_0[4]))
        v7.update_position(p2.position_368, {
            previous_origin_112 = rt.copy(p2.motion.published_frame_64[4]),
            override_origin_592 = rt.copy(p2.correction_target_592),
            use_override_711 = p2.motion.correction_enabled_711,
            projection_axis_416 = rt.copy(p2.surface.spring_normal),
            contact_flags_176 = p4.flags,
            contact_origin_0 = rt.copy(p4.contact_position),
            contact_origin_96 = rt.copy(p4.target_position),
            frame_position_176 = rt.copy(p2.frame_output.frame[4]),
            animation_position_272 = rt.copy(p4.animation_position)
        })
        BipedCadence.update(p2.cadence, {
            motion_512 = xyz(p2.frame_output.velocity),
            motion_reference_272 = xyz(p2.motion.predicted_support_velocity_272),
            reject_axis_400 = xyz(p2.contact.direction),
            reject_enabled_708 = p2.contact.active,
            up_144 = xyz(p2.frame_output.frame[2]),
            frame_rows_0_16_32 = {
                xyz(p2.motion.frame_0[1]),
                xyz(p2.motion.frame_0[2]),
                xyz(p2.motion.frame_0[3])
            },
            frame_position_48 = xyz(p2.motion.frame_0[4]),
            animation_motion_224 = xyz(p4.animation_motion),
            requested_duration_288 = p4.requested_duration,
            requested_phase_296 = p4.requested_phase,
            suppress_adjustment_353 = p4.edge_active,
            contact_flags_176 = p4.flags,
            contact_point_96 = xyz(p4.target_position)
        }, p2.thresholds)
    end
end

function t1.velocity(p5, p6, p7) -- line: 177
    -- upvalues: rt (copy), v6 (copy)
    local t3 = {
        velocity = rt.copy(p5.motion.velocity_480),
        turn = p5.motion.angular_velocity_688,
        forward_delta = p5.forward_delta_692,
        right_delta = p5.right_delta_696,
        speed = p5.motion.speed_704,
        override_remaining = p5.velocity_override_remaining_772
    }

    v6.State.update(t3, p6.movement_velocity, {
        forward = rt.copy(p5.motion.frame_0[3]),
        right = rt.copy(p5.motion.frame_0[1]),
        plane_normal = rt.copy(p5.surface.surface_normal),
        desired_speed = p5.intent.speed,
        steering = p5.intent.steering,
        slope_mode = p5.special.enabled_714,
        obstacle = p5.contact.active,
        obstacle_normal = rt.copy(p5.contact.direction),
        override_gate = p7.requested_phase,
        override_duration = p7.override_duration,
        override_velocity = rt.copy(p7.animation_velocity),
        flags = p7.flags
    })
    p5.motion.velocity_480 = rt.copy(t3.velocity)
    p5.motion.angular_velocity_688 = t3.turn
    p5.motion.speed_704 = t3.speed
    p5.forward_delta_692 = t3.forward_delta
    p5.right_delta_696 = t3.right_delta
    p5.velocity_override_remaining_772 = t3.override_remaining
end

velocity = t1.velocity

return t1
