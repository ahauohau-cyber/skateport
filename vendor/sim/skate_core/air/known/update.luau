-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/air/known/body")
local v2 = import("skate_core/air/known/footplant")
local v3 = import("skate_core/air/known/trajectory")
local calculate_body_flip_speed, calculate_body_spin_speed = v1.calculate_body_flip_speed, v1.calculate_body_spin_speed
local update_footplant = v2.update_footplant
local init_trajectory_info, select, update_trajectory_follow = v3.init_trajectory_info, v3.select, v3.update_trajectory_follow
local t1 = {
    ALIGNMENT_LEAD_FRAMES = 3,
    MIN_ALIGNMENT_FRAMES = 2,
    ONE = 1,
    BOARD_ERROR_WINDOW = 0.05999999865889549,
    ZERO = 0
}
local ALIGNMENT_LEAD_FRAMES, MIN_ALIGNMENT_FRAMES, ONE, BOARD_ERROR_WINDOW = t1.ALIGNMENT_LEAD_FRAMES, t1.MIN_ALIGNMENT_FRAMES, t1.ONE, t1.BOARD_ERROR_WINDOW
local ZERO = t1.ZERO

t1.GRIND_FOOT_BODIES = { "Body3152", "Body3156", "Body3160", "Body3168", "Body3172", "Body3176" }

local GRIND_FOOT_BODIES = t1.GRIND_FOOT_BODIES

function t1.update(p1, p2, p3, p4, p5, p6) -- line: 44
    -- upvalues: rt (copy), calculate_body_flip_speed (copy), calculate_body_spin_speed (copy), update_footplant (copy), init_trajectory_info (copy), select (copy), update_trajectory_follow (copy), ALIGNMENT_LEAD_FRAMES (copy), MIN_ALIGNMENT_FRAMES (copy), ONE (copy), BOARD_ERROR_WINDOW (copy), ZERO (copy), GRIND_FOOT_BODIES (copy)
    update_footplant(p1, p2, p6)

    if p6.selector_has_just_changed(p6) then
        init_trajectory_info(p1, p2, p3, p4, p6)
    end

    p6.update_air_collision(p6)

    local v4 = calculate_body_flip_speed(p1, p2, p3, p4, p5, p6)
    local v5 = calculate_body_spin_speed(p1, p2, p3, p4, p5, p6)
    local v6 = (p1.collision_time_196 - p1.time_in_state_180) / p2.delta_time_2604 - ALIGNMENT_LEAD_FRAMES
    local v7 = select(v6 - MIN_ALIGNMENT_FRAMES, v6, MIN_ALIGNMENT_FRAMES)

    if not p1.grind_air_adjust_activated_212 and (p1.reached_apex_208 or v7 < p3.frames_for_grind_air_assist_436) then
        local v8 = p6.grind_air_adjust_started(p6)

        p6.set_grind_air_adjust_activated(p6, v8)
        p1.grind_air_adjust_activated_212 = true
    end

    if p1.targeting_grind_213 and p1.grind_air_adjust_activated_212 and p6.grind_air_adjust_adjusting(p6) then
        for _, v9 in GRIND_FOOT_BODIES do
            p6.disable_grind_foot_collision(p6, v9)
        end
    end

    p6.update_reckoning_air_states(p6, rt.copy(p1.landing_normal_64), ONE / v7, v5, v4)
    update_trajectory_follow(p1, p2, p3, p6)
    p6.update_known_air_skeleton(p6, rt.copy(p1.target_com_position_160))

    if p1.time_in_state_180 < BOARD_ERROR_WINDOW then
        p6.set_skeleton_add_skateboard_error(p6, true)
    end

    local v10 = if bit32.band(p2.flags_2472, 4194304) == 0 then rt.copy(p1.collision_position_112) else rt.copy(p2.alternate_head_target_112)

    p6.set_head_tracking_target(p6, v10, true)
    p6.update_board_steering_tilt(p6, ZERO)

    local v11 = p6.board_transform_height(p6)

    if not (v11 < p1.max_y_188) then
        p1.max_y_188 = v11
    end

    if bit32.band(p2.flags_2468, 8) == 0 then
        p1.time_in_state_180 += p2.delta_time_2604
    end

    local v12 = p6.skeleton_com_position(p6)[2]

    p1.com_max_y_192 = select(p1.com_max_y_192 - v12, p1.com_max_y_192, v12)
end

return t1
