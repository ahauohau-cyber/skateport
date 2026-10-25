-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/point_graph")
local v2 = import("skate_core/air/state/board")
local v3 = import("skate_core/air/state/jump_velocity")
local PointGraph = v1.PointGraph
local update_skateboard = v2.update_skateboard
local calculate_velocity_from_jump = v3.calculate_velocity_from_jump
local t1 = {
    FIXED_STEP = 0.01666666753590107,
    HALF = 0.5,
    ONE = 1,
    TRAJECTORY_UNBOUNDED = -1,
    TWO = 2,
    DEGREES_TO_RADIANS = 0.01745329238474369,
    TWO_PI = 6.2831854820251465,
    RECIPROCAL_TWO_PI = 0.15915493667125702,
    HALF_TURN = 0.5,
    COM_START_Y_OFFSET = -0.6499999761581421,
    BOARD_START_Y_OFFSET = -0.800000011920929,
    CONE_SCALE = 0.4000000059604645
}
local FIXED_STEP, HALF, ONE, TRAJECTORY_UNBOUNDED = t1.FIXED_STEP, t1.HALF, t1.ONE, t1.TRAJECTORY_UNBOUNDED
local TWO, DEGREES_TO_RADIANS, TWO_PI, RECIPROCAL_TWO_PI = t1.TWO, t1.DEGREES_TO_RADIANS, t1.TWO_PI, t1.RECIPROCAL_TWO_PI
local HALF_TURN, COM_START_Y_OFFSET, BOARD_START_Y_OFFSET, CONE_SCALE = t1.HALF_TURN, t1.COM_START_Y_OFFSET, t1.BOARD_START_Y_OFFSET, t1.CONE_SCALE

function t1.update(p1, p2, p3, p4, p5, p6) -- line: 45
    -- upvalues: rt (copy), update_skateboard (copy), t1 (copy), TRAJECTORY_UNBOUNDED (copy), TWO (copy), DEGREES_TO_RADIANS (copy)
    p6.update_air_collision(p6)
    p1.trajectory_query_countdown = rt.to_i32(rt.wrapping_sub_u32(rt.to_u32(p1.trajectory_query_countdown), rt.to_u32(1)))

    if p1.trajectory_query_countdown <= 0 and bit32.band(p2.flags_2468, 32768) == 0 and p2.previous_physics_state_2504 ~= 0 and not p6.trajectory_query_just_started(p6) then
        t1.launch_trajectory(p1, p2, p5, p6)
        p1.trajectory_query_countdown = 7
    end

    p6.update_trajectory_selector(p6)

    local v4 = rt.copy(p4.current_landing_normal_1152)
    local v5 = p6.selector_landing_normal(p6)

    if v5 == nil then
        v5 = v4
    end

    p1.landing_normal = rt.copy(v5)

    local v6 = p6.angle_between_vectors(p6, v5, v4)
    local v7 = if t1.wrap_signed_angle(v6) <= p3.landing_normal_angle_limit_444 then p3.landing_normal_blend_388 else 0

    if not p1.use_centre_of_mass_velocity then
        if not p1.selector_latch_174 then
            p1.selector_latch_174 = p6.selector_centre_of_mass_trajectory_ready(p6)
        end

        if p1.selector_latch_174 then
            p1.use_centre_of_mass_velocity = true
            p1.centre_of_mass_trajectory = {
                position = rt.copy(p2.trajectory_position_592),
                velocity = rt.copy(p2.trajectory_velocity_608),
                acceleration = rt.copy(p5),
                scalar_48 = TRAJECTORY_UNBOUNDED
            }
        end
    end

    if p2.state_timer_2664 <= 0 then
        v7 = 0
    elseif bit32.band(p2.flags_2468, 16384) ~= 0 then
        p1.use_centre_of_mass_velocity = false
    end

    local v8 = p2.body_spin_input_2640 * p3.body_spin_scale_428 * DEGREES_TO_RADIANS
    local v9 = t1.evaluate_spin_curve(p3.body_spin_over_time_320, p1.time_in_state * TWO) * v8

    rt.assign(p4, p6.update_reckoning_air_states(p6, rt.copy(v5), v7, v9, 0))

    if p1.use_centre_of_mass_velocity then
        t1.integrate_trajectory_fixed_step(p1.centre_of_mass_trajectory)
        p6.update_known_air_skeleton(p6, rt.copy(p1.centre_of_mass_trajectory.position))
    else
        p6.update_animated_skateboard_skeleton(p6, false)
    end

    update_skateboard(p1, p2, p4, p6)
    p6.enable_skateboard_error_on_skeleton(p6)

    local v10 = p6.board_transform_height(p6)

    if not (v10 < p1.max_y) then
        p1.max_y = v10
    end

    p1.time_in_state += p2.delta_time_2604
end

function t1.wrap_signed_angle(p7) -- line: 126
    -- upvalues: ONE (copy), TWO_PI (copy), RECIPROCAL_TWO_PI (copy), HALF_TURN (copy)
    local v11 = p7 * RECIPROCAL_TWO_PI
    local v12 = v11 - math.floor(v11)

    if HALF_TURN < v12 then
        v12 -= ONE
    end

    return v12 * TWO_PI
end

function t1.integrate_trajectory_fixed_step(p8) -- line: 139
    -- upvalues: FIXED_STEP (copy), HALF (copy), ONE (copy)
    local v13 = FIXED_STEP * FIXED_STEP
    local t2 = {
        p8.velocity[1] * FIXED_STEP + p8.position[1],
        p8.velocity[2] * FIXED_STEP + p8.position[2],
        p8.velocity[3] * FIXED_STEP + p8.position[3],
        p8.velocity[4] * FIXED_STEP + p8.position[4]
    }
    local t3 = {
        p8.acceleration[1] * FIXED_STEP + p8.velocity[1],
        p8.acceleration[2] * FIXED_STEP + p8.velocity[2],
        p8.acceleration[3] * FIXED_STEP + p8.velocity[3],
        p8.acceleration[4] * FIXED_STEP + p8.velocity[4]
    }
    local v14 = ONE * HALF
    local t4 = {
        p8.acceleration[1] * v14,
        p8.acceleration[2] * v14,
        p8.acceleration[3] * v14,
        p8.acceleration[4] * v14
    }

    p8.position = {
        t4[1] * v13 + t2[1],
        t4[2] * v13 + t2[2],
        t4[3] * v13 + t2[3],
        t4[4] * v13 + t2[4]
    }
    p8.velocity = t3
end

function t1.launch_trajectory(p9, p10, p11, p12) -- line: 170
    -- upvalues: calculate_velocity_from_jump (copy), t1 (copy)
    local v15 = p12.construct_trajectory_launch_info(p12)

    p12.fill_skeleton_launch_info(p12, v15)

    if p10.frames_since_jump_correction_2576 < 12 then
        local v16 = calculate_velocity_from_jump(p10, p10.frames_since_jump_correction_2576, p12)

        v15.set_start_velocity(v15, v16)
    elseif p9.use_centre_of_mass_velocity then
        t1.adjust_centre_of_mass_launch_info(p9, p11, p12, v15)
    end

    v15.set_player_jumped(v15, false)
    p12.launch_trajectory(p12, v15)
end

function t1.adjust_centre_of_mass_launch_info(p13, p14, p15, p16) -- line: 185
    -- upvalues: FIXED_STEP (copy), COM_START_Y_OFFSET (copy), BOARD_START_Y_OFFSET (copy), CONE_SCALE (copy)
    p15.fill_skeleton_launch_info(p15, p16)

    local t5 = {
        p14[1] * FIXED_STEP + p13.centre_of_mass_trajectory.velocity[1],
        p14[2] * FIXED_STEP + p13.centre_of_mass_trajectory.velocity[2],
        p14[3] * FIXED_STEP + p13.centre_of_mass_trajectory.velocity[3],
        p14[4] * FIXED_STEP + p13.centre_of_mass_trajectory.velocity[4]
    }

    p16.set_start_velocity(p16, t5)
    p16.set_player_jumped(p16, true)

    local v17 = p16.centre_of_mass_animation_position(p16)
    local t6 = {
        0,
        COM_START_Y_OFFSET,
        0, 0
    }
    local t7 = {
        0,
        BOARD_START_Y_OFFSET,
        0, 0
    }

    p16.set_trajectory_start_position_override(p16, {
        v17[1] + t6[1],
        v17[2] + t6[2],
        v17[3] + t6[3],
        v17[4] + t6[4]
    })
    p16.set_board_position_override(p16, {
        v17[1] + t7[1],
        v17[2] + t7[2],
        v17[3] + t7[3],
        v17[4] + t7[4]
    })
    p16.set_use_trajectory_start_position_override(p16, true)
    p16.set_trajectory_count(p16, 5)

    local v18 = p16.cone_angles(p16)

    p16.set_cone_angles(p16, {
        v18[1] * CONE_SCALE,
        v18[2] * CONE_SCALE
    })
end

function t1.evaluate_spin_curve(p17, p18) -- line: 225
    -- upvalues: PointGraph (copy)
    return PointGraph.evaluate(p17, p18)
end

return t1
