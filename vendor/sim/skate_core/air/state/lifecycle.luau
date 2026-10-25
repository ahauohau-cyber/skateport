-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local calculate_velocity_from_jump = require(sim.import)("skate_core/air/state/jump_velocity").calculate_velocity_from_jump
local t1 = {
    TRAJECTORY_UNBOUNDED = -1,
    OFFBOARD_VERTICAL_SCALE = 0.6499999761581421,
    OFFBOARD_VERTICAL_LIMIT = 3,
    OUTPUT_SCALAR_184 = 4
}
local TRAJECTORY_UNBOUNDED, OFFBOARD_VERTICAL_SCALE, OFFBOARD_VERTICAL_LIMIT, OUTPUT_SCALAR_184 = t1.TRAJECTORY_UNBOUNDED, t1.OFFBOARD_VERTICAL_SCALE, t1.OFFBOARD_VERTICAL_LIMIT, t1.OUTPUT_SCALAR_184

function t1.enter(p1, p2, p3, p4) -- line: 24
    -- upvalues: rt (copy), calculate_velocity_from_jump (copy), t1 (copy), TRAJECTORY_UNBOUNDED (copy), OFFBOARD_VERTICAL_SCALE (copy), OFFBOARD_VERTICAL_LIMIT (copy)
    p4.set_air_collision_update_enabled(p4, true)
    p4.set_skeleton_collision_state(p4, 7)
    p4.set_skeleton_inverse_kinematics_enabled(p4, true)
    p4.set_skeleton_collision_state(p4, 6)
    p4.enable_board_angular_drive_only(p4)
    p4.set_footplant_flag_240(p4, false)
    p4.reset_footplants(p4)
    p1.selector_latch_174 = false
    p1.reached_apex = false
    p1.trajectory_query_countdown = 0
    p1.landing_normal = { 0, 1, 0, 0 }
    p1.time_in_state = 0
    p1.max_y = p4.board_transform_height(p4)
    p1.start_y = p2.ground_position_y_500

    local v1, v2 = t1.initial_centre_of_mass_mode(p2)

    p1.use_centre_of_mass_velocity = v1

    if v1 then
        local v3 = rt.copy(p2.trajectory_velocity_608)

        if p2.previous_physics_state_2504 == 500 then
            local v4 = v3[2] * OFFBOARD_VERTICAL_SCALE

            v3[2] = p4.minimum_vminfp(p4, v4, OFFBOARD_VERTICAL_LIMIT)
        end

        if p2.frames_since_jump_correction_2576 < 12 then
            v3 = calculate_velocity_from_jump(p2, p2.frames_since_jump_correction_2576, p4)
        end

        p1.centre_of_mass_trajectory = {
            position = rt.copy(p2.trajectory_position_592),
            velocity = v3,
            acceleration = rt.copy(p3),
            scalar_48 = TRAJECTORY_UNBOUNDED
        }
    end

    if v2 then
        p4.request_skeleton_heading_update(p4)
    end
end

function t1.exit(p5, p6) -- line: 69
    p5.use_centre_of_mass_velocity = false
    p6.body_spin_speed_1572 = 0
    p6.body_spin_angle_1568 = 0
end

function t1.fill_physics_output(p7) -- line: 76
    -- upvalues: rt (copy), OUTPUT_SCALAR_184 (copy)
    return {
        is_at_apex = p7.reached_apex,
        jump_height = p7.max_y - p7.start_y,
        landing_normal = rt.copy(p7.landing_normal),
        scalar_184_write = if p7.selector_latch_174 then OUTPUT_SCALAR_184 else nil
    }
end

function t1.initial_centre_of_mass_mode(p8) -- line: 86
    if p8.previous_physics_category_2516 ~= 400 and p8.previous_physics_state_2504 ~= 701 then
        local previous_physics_state_2504 = p8.previous_physics_state_2504
        local v5 = not (previous_physics_state_2504 == 100 or previous_physics_state_2504 == 103 or previous_physics_state_2504 == 201)

        return v5, v5
    end

    return bit32.band(p8.flags_2468, 16384) == 0, false
end

return t1
