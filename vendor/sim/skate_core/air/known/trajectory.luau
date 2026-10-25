-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local PointGraph = require(sim.import)("skate_core/point_graph").PointGraph
local t1 = {
    FIXED_STEP = 0.01666666753590107,
    HALF = 0.5,
    ONE = 1,
    PERFECT_FLIP_NUMERATOR = -7.539823055267334,
    NEGATIVE_TWO_PI = -6.2831854820251465,
    HEADING_LENGTH_SQUARED_MIN = 0.10000000149011612
}
local FIXED_STEP, HALF, ONE, PERFECT_FLIP_NUMERATOR = t1.FIXED_STEP, t1.HALF, t1.ONE, t1.PERFECT_FLIP_NUMERATOR
local NEGATIVE_TWO_PI, HEADING_LENGTH_SQUARED_MIN = t1.NEGATIVE_TWO_PI, t1.HEADING_LENGTH_SQUARED_MIN

local function i32_wrapping_add(p1, p2) -- line: 28
    -- upvalues: rt (copy)
    return rt.to_i32(rt.wrapping_add_u32(rt.to_u32(p1), rt.to_u32(p2)))
end

local function i32_wrapping_sub(p3, p4) -- line: 31
    -- upvalues: rt (copy)
    return rt.to_i32(rt.wrapping_sub_u32(rt.to_u32(p3), rt.to_u32(p4)))
end

function t1.init_trajectory_info(p5, p6, p7, p8, p9) -- line: 36
    -- upvalues: rt (copy), t1 (copy), FIXED_STEP (copy), PERFECT_FLIP_NUMERATOR (copy), NEGATIVE_TWO_PI (copy), HEADING_LENGTH_SQUARED_MIN (copy)
    p5.landing_normal_64 = rt.copy(p6.selector_landing_normal_2656)

    local v1 = p9.selected_prediction(p9)
    local v2, v3 = p9.highest_trajectory_position(p9, v1.trajectory)

    p5.time_to_apex_200 = v3
    p5.trajectory_apex_96 = rt.copy(v2)
    p5.collision_position_112 = rt.copy(p9.selector_contact_position(p9))
    p5.collision_time_196 = v1.collision_time_48

    if p8.perfect_body_flips_28 then
        p5.body_flip_target_speed_204 = PERFECT_FLIP_NUMERATOR / p5.collision_time_196
    else
        p5.body_flip_target_speed_204 = p7.flip_scalar / p5.collision_time_196 * NEGATIVE_TWO_PI
    end

    p5.selector_vector_128 = rt.copy(p9.selector_vector_2848(p9))

    local v4 = {
        0, 0, 0, 0
    }

    p5.collision_normal_speed_176 = 0

    local v5

    if p5.collision_time_196 >= 0 then
        local collision_frame_128 = v1.collision_frame_128
        local v6 = rt.to_i32(rt.wrapping_sub_u32(rt.to_u32(collision_frame_128), rt.to_u32(2))) * FIXED_STEP
        local v7 = rt.to_i32(rt.wrapping_sub_u32(rt.to_u32(collision_frame_128), rt.to_u32(1))) * FIXED_STEP
        local v8 = t1.trajectory_position(v1.trajectory, v6)
        local v9 = t1.trajectory_position(v1.trajectory, v7)
        local v10 = t1.sub(v9, v8)
        local v11 = p9.divide_vector_by_scalar(p9, v10, FIXED_STEP)

        p5.collision_normal_speed_176 = p9.dot3(p9, p5.landing_normal_64, v11)

        local v12 = t1.mul_scalar(p5.landing_normal_64, p5.collision_normal_speed_176)
        local v13 = t1.sub(v11, v12)
        local v14, v15 = p9.normalize_safe_with_length(p9, v13)

        if v15 < p7.min_target_heading_velocity_420 then
            v5 = false
        else
            v5 = true
            v4 = rt.copy(v14)
        end
    else
        v5 = false
    end

    p5.landing_heading_80 = rt.copy(v4)
    p5.landing_heading_valid_209 = v5

    if p9.dot3(p9, v4, v4) < HEADING_LENGTH_SQUARED_MIN then
        p5.landing_heading_valid_209 = false
    end
end

function t1.restore_velocity(p10, p11, p12, p13) -- line: 85
    -- upvalues: rt (copy), PointGraph (copy), t1 (copy), FIXED_STEP (copy), ONE (copy)
    local v16 = p13.selected_prediction(p13)

    if p10.trajectory_index_216 == 0 then
        p10.trajectory_index_216 = 1
    end

    local v17 = p10.trajectory_index_216 * FIXED_STEP
    local v18 = t1.trajectory_velocity(v16.trajectory, v17)
    local v19 = p13.restore_velocity_geometry_82d35998(p13, v18, rt.copy(p11.ground_normal_464))
    local v20 = PointGraph.evaluate(p12.landing_speed_scalar_vs_ground_normal_y_240, v19.landing_speed_curve_input)
    local v21 = t1.select(-v19.landing_speed_blend_source, 0, v19.landing_speed_blend_source)
    local v22 = t1.select(ONE - v21, v21, ONE)
    local v23 = (v20 - ONE) * v22 + ONE
    local v24 = t1.mul_scalar(v19.tangential_velocity, v23)
    local v25 = p13.board_body_velocity(p13)
    local v26 = p13.dot3(p13, v25, p11.ground_normal_464)
    local t2 = {
        p11.ground_normal_464[1] * v26 + v24[1],
        p11.ground_normal_464[2] * v26 + v24[2],
        p11.ground_normal_464[3] * v26 + v24[3],
        p11.ground_normal_464[4] * v26 + v24[4]
    }

    p13.set_board_velocity(p13, rt.copy(t2))

    local v27 = p13.board_forward_axis(p13)

    p11.forward_speed_2612 = p13.dot3(p13, t2, v27)
end

function t1.update_trajectory_follow(p14, p15, p16, p17) -- line: 116
    -- upvalues: rt (copy), t1 (copy), FIXED_STEP (copy), ONE (copy)
    local trajectory_index_216 = p14.trajectory_index_216

    p14.trajectory_index_216 = rt.to_i32(rt.wrapping_add_u32(rt.to_u32(trajectory_index_216), rt.to_u32(1)))

    local v28 = (p16.trajectory_error_blend_away_time_384 - p14.time_in_state_180) / p16.trajectory_error_blend_away_time_384
    local v29 = t1.select(-v28, 0, v28)
    local v30 = t1.select(ONE - v29, v29, ONE)
    local v31 = p14.trajectory_index_216 * FIXED_STEP
    local v32 = p17.selector_trajectory_2704(p17)
    local v33 = t1.trajectory_position(v32, v31)

    p14.target_com_position_160 = {
        p14.trajectory_follow_offset_144[1] * v30 + v33[1],
        p14.trajectory_follow_offset_144[2] * v30 + v33[2],
        p14.trajectory_follow_offset_144[3] * v30 + v33[3],
        p14.trajectory_follow_offset_144[4] * v30 + v33[4]
    }

    if bit32.band(p15.flags_2468, 8) ~= 0 then
        local trajectory_index_216 = p14.trajectory_index_216

        p14.trajectory_index_216 = rt.to_i32(rt.wrapping_sub_u32(rt.to_u32(trajectory_index_216), rt.to_u32(1)))
    end
end

function t1.trajectory_position(p18, p19) -- line: 138
    -- upvalues: rt (copy), HALF (copy)
    local v34 = p19 * p19

    return rt.from_fn(4, function(p20) -- line: 140
        -- upvalues: p18 (copy), p19 (copy), v34 (copy), HALF (copy)
        local v35 = p18.velocity[p20 + 1] * p19 + p18.position[p20 + 1]

        return p18.acceleration[p20 + 1] * HALF * v34 + v35
    end)
end

function t1.trajectory_velocity(p21, p22) -- line: 147
    return {
        p21.acceleration[1] * p22 + p21.velocity[1],
        p21.acceleration[2] * p22 + p21.velocity[2],
        p21.acceleration[3] * p22 + p21.velocity[3],
        p21.acceleration[4] * p22 + p21.velocity[4]
    }
end

function t1.add(p23, p24) -- line: 156
    return {
        p23[1] + p24[1],
        p23[2] + p24[2],
        p23[3] + p24[3],
        p23[4] + p24[4]
    }
end

function t1.sub(p25, p26) -- line: 160
    return {
        p25[1] - p26[1],
        p25[2] - p26[2],
        p25[3] - p26[3],
        p25[4] - p26[4]
    }
end

function t1.mul_scalar(p27, p28) -- line: 164
    return {
        p27[1] * p28,
        p27[2] * p28,
        p27[3] * p28,
        p27[4] * p28
    }
end

function t1.select(p29, p30, p31) -- line: 168
    if p29 >= 0 then
        return p30
    end

    return p31
end

return t1
