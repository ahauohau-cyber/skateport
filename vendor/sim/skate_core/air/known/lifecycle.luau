-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = require(sim.import)("skate_core/air/known/trajectory")
local init_trajectory_info, restore_velocity = v1.init_trajectory_info, v1.restore_velocity
local t1 = {
    ZERO_VECTOR = { 0, 0, 0, 0 }
}
local ZERO_VECTOR = t1.ZERO_VECTOR

function t1.enter(p1, p2, p3, p4, p5) -- line: 19
    -- upvalues: rt (copy), init_trajectory_info (copy), ZERO_VECTOR (copy)
    p5.enable_board_angular_drive_only(p5)
    p5.set_air_collision_update_enabled(p5, true)
    p5.set_skeleton_collision_state(p5, 7)
    p5.set_skeleton_physics_truck_tilt_enabled(p5, false)
    p5.set_skeleton_inverse_kinematics_enabled(p5, true)
    p1.body_flipping_211 = false
    p1.grind_air_adjust_activated_212 = false
    p1.targeting_grind_213 = false
    p5.reset_reckoning_flipping(p5)
    p5.set_footplant_flag_240(p5, false)
    p5.reset_footplants(p5)
    p1.reached_apex_208 = false
    p1.time_in_state_180 = 0
    p1.start_y_184 = p2.start_height_484
    p1.max_y_188 = p5.board_transform_height(p5)
    p1.com_max_y_192 = p5.skeleton_com_position(p5)[2]
    init_trajectory_info(p1, p2, p3, p4, p5)

    if p5.selector_targeting_grind(p5) then
        p5.start_grind_air_adjust_from_selector(p5)
        p1.targeting_grind_213 = true
    end

    local v2 = p5.skeleton_com_position(p5)
    local v3, v4 = p5.selector_closest_trajectory_point(p5, v2, rt.copy(ZERO_VECTOR))

    p1.trajectory_index_216 = v3
    p1.trajectory_follow_offset_144 = rt.copy(v4)
    p1.start_flipped_210 = p5.dot3(p5, p2.velocity_400, p2.start_flip_reference_96) < 0
end

function t1.exit(p6, p7, p8, p9, p10) -- line: 55
    -- upvalues: restore_velocity (copy)
    p10.reset_reckoning_flipping(p10)

    if p7.next_physics_state_2500 == 100 then
        restore_velocity(p6, p7, p8, p10)
    end

    p10.reset_trajectory_selector(p10)
    p9.body_spin_speed_1572 = 0
    p9.body_spin_angle_1568 = 0
    p10.set_grind_air_adjust_started(p10, false)
    p10.set_grind_air_adjust_activated(p10, false)
end

return t1
