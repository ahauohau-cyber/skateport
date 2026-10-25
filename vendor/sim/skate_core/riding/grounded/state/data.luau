-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

local t1 = {
    PhysicsGroundState = {}
}

function t1.PhysicsGroundState.before_first_enter(p1) -- line: 60
    return {
        collision_force_2528 = table.create(4, 0),
        collision_point_2544 = table.create(4, 0),
        word_2560 = 0,
        word_2564 = 0,
        vector_2592 = table.create(4, 0),
        vector_2608 = table.create(4, 0),
        anti_flip_torque_2624 = table.create(4, 0),
        steering_push_scalar_2640 = 0,
        steering_damped_turn_2644 = 0,
        elapsed_2648 = 0,
        collision_countdown_2652 = 0,
        captured_position_x_2656 = 0,
        captured_position_z_2660 = 0,
        scalar_2664 = 0,
        scalar_2668 = 0,
        straighten_scale_2672 = 0,
        vector_2688 = table.create(4, 0),
        scalar_2704 = 0,
        flag_2708 = false,
        flag_2720 = false,
        flag_2721 = false,
        flag_2722 = false,
        anti_flip_nudge_applied_2723 = false,
        human_player_2724 = p1,
        controls_latched_2725 = false,
        captured_position_valid_2726 = false,
        pinning_2727 = false,
        was_pinning_2728 = false,
        flag_2729 = false,
        push_suppressed_2730 = false,
        flag_2731 = false,
        manual_correction_2732 = false,
        manual_opposition_2733 = false,
        hang_detection_frames_2740 = 0,
        hang_force_frames_2744 = 0,
        hung_wipeout_frames_2748 = 0,
        anti_flip_nudge_frames_2752 = 0
    }
end

function t1.PhysicsGroundState.begin_entry(p2) -- line: 103
    p2.word_2560 = 0
    p2.word_2564 = 0
    p2.flag_2708 = false
    p2.controls_latched_2725 = false
    p2.captured_position_valid_2726 = false
    p2.was_pinning_2728 = false
    p2.flag_2731 = false
    p2.manual_correction_2732 = false
    p2.manual_opposition_2733 = false
end

function t1.PhysicsGroundState.finish_entry(p3, p4) -- line: 116
    if p4 == 101 then
        p3.straighten_scale_2672 = 0.1599999964237213
    else
        p3.straighten_scale_2672 = 1
    end

    p3.steering_push_scalar_2640 = 1
    p3.steering_damped_turn_2644 = 0
    p3.elapsed_2648 = 0
    p3.collision_countdown_2652 = 0
    p3.vector_2592 = table.create(4, 0)
    p3.vector_2608 = table.create(4, 0)
    p3.anti_flip_torque_2624 = table.create(4, 0)
    p3.hang_detection_frames_2740 = 0
    p3.hang_force_frames_2744 = 0
    p3.hung_wipeout_frames_2748 = 0
    p3.anti_flip_nudge_frames_2752 = 0
    p3.flag_2721 = false
    p3.anti_flip_nudge_applied_2723 = false
    p3.push_suppressed_2730 = false
end

function t1.PhysicsGroundState.begin_update(p5, p6) -- line: 139
    -- upvalues: rt (copy), t1 (copy)
    return t1.PhysicsGroundState.begin_update_at(p5, p6.wheel_contact_count_2556, rt.copy(p6.position_112))
end

function t1.PhysicsGroundState.begin_update_at(p7, p8, p9) -- line: 143
    if not p7.captured_position_valid_2726 and p8 > 0 then
        p7.captured_position_x_2656 = p9[1]
        p7.captured_position_z_2660 = p9[3]
        p7.captured_position_valid_2726 = true
    end

    p7.anti_flip_torque_2624 = table.create(4, 0)
    p7.flag_2722 = false
    p7.anti_flip_nudge_applied_2723 = false
    p7.pinning_2727 = false
    p7.scalar_2664 = -1
    p7.flag_2729 = false

    return {
        set_skeleton_flag_16505 = p7.elapsed_2648 > 0.05000000074505806
    }
end

function t1.PhysicsGroundState.finish_update(p10, p11) -- line: 161
    p10.elapsed_2648 += p11
end

t1.GroundUpdateInput = {}
t1.GroundUpdateSignals = {}
t1.GroundContactHistory = {}

function t1.GroundContactHistory.empty() -- line: 185
    return {
        differing_contact_frames_2756 = 0,
        tracked_contact_2760 = nil
    }
end

return t1
