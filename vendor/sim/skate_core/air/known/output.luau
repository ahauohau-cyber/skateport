-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = require(sim.import)("skate_core/air/known/trajectory")
local add, sub, trajectory_position, trajectory_velocity = v1.add, v1.sub, v1.trajectory_position, v1.trajectory_velocity
local t1 = {
    FIXED_STEP = 0.01666666753590107,
    MAX_FINITE = 3.4028234663852886E+38
}
local FIXED_STEP, MAX_FINITE = t1.FIXED_STEP, t1.MAX_FINITE

function t1.fill_physics_output(p1, p2, p3, p4) -- line: 23
    -- upvalues: rt (copy), add (copy), sub (copy), trajectory_position (copy), trajectory_velocity (copy), FIXED_STEP (copy), MAX_FINITE (copy)
    local v2 = p4.selected_prediction(p4)

    if bit32.band(p2.flags_2468, 8) ~= 0 then
        p3.locked_trajectory_velocity_valid_452 = true

        local v3 = p1.trajectory_index_216 * FIXED_STEP

        p3.locked_trajectory_velocity_160 = trajectory_velocity(v2.trajectory, v3)
    end

    p3.reached_apex_436 = p1.reached_apex_208
    p3.jump_height_200 = p1.max_y_188 - p1.start_y_184
    p3.trajectory_apex_0 = rt.copy(p1.trajectory_apex_96)
    p3.time_to_apex_196 = p1.time_to_apex_200
    p3.collision_position_16 = rt.copy(p1.collision_position_112)
    p3.landing_normal_32 = rt.copy(p1.landing_normal_64)
    p3.landing_normal_copy_144 = rt.copy(p1.landing_normal_64)

    if bit32.band(p2.flags_2468, 8) == 0 then
        p3.time_until_collision_184 = p1.collision_time_196 - p1.time_in_state_180
    else
        p3.time_until_collision_184 = MAX_FINITE
    end

    p3.time_in_state_176 = p1.time_in_state_180
    p3.selector_vector_48 = rt.copy(p1.selector_vector_128)

    local v4 = math.max(p1.trajectory_index_216, 1)

    p3.trajectory_position_64 = trajectory_position(v2.trajectory, v4 * FIXED_STEP)
    p3.landing_heading_80 = rt.copy(p1.landing_heading_80)
    p3.collision_normal_speed_188 = p1.collision_normal_speed_176
    p3.known_air_valid_437 = true
    p3.selected_trajectory_240 = rt.copy(v2.trajectory)
    p3.trajectory_index_220 = p1.trajectory_index_216

    local v5 = p4.selector_com_position_2784(p4)

    p3.selector_com_position_96 = rt.copy(v5)
    p3.collision_time_180 = p1.collision_time_196

    local v6 = p4.reckoning_com_transform_816(p4)
    local v7 = p4.transform_point_82d36880(p4, v6, v5)
    local v9 = math.max(rt.to_i32(rt.wrapping_sub_u32(rt.to_u32(p1.trajectory_index_216), rt.to_u32(1))), 0)

    for i = 0, #p3.trajectory_plane_samples_336 - 1 do
        local v10 = rt.to_i32(rt.wrapping_add_u32(rt.to_u32(v9), rt.to_u32(i)))
        local v12 = sub(add(trajectory_position(v2.trajectory, v10 * FIXED_STEP), v7), p1.collision_position_112)

        p3.trajectory_plane_samples_336[i + 1] = p4.dot3(p4, v12, p1.landing_normal_64)
    end
end

return t1
