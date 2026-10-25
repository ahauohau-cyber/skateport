-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/player/offboard/board_possession/math")
local v2 = import("skate_core/trigonometry")
local v3 = import("skate_core/animation/foot_ik")
local v4 = import("skate_core/point_graph")

local function board_possession() -- line: 15
    -- upvalues: import (copy)
    return import("skate_core/player/offboard/board_possession")
end

local PointGraph = v4.PointGraph
local dot, sub, scale, madd = v1.dot, v1.sub, v1.scale, v1.madd
local cross, length, unit, transform_direction = v1.cross, v1.length, v1.unit, v1.transform_direction
local projected_angle, wrap = v1.projected_angle, v1.wrap
local t1 = {}

t1.DT = 0.01666666753590107
t1.RADIANS = 0.01745329238474369

local DT, RADIANS = t1.DT, t1.RADIANS

t1.State = {}

function t1.State.update_drive_frames(p1, p2) -- line: 46
    -- upvalues: rt (copy), import (copy), sub (copy), scale (copy), madd (copy), transform_direction (copy)
    local v5 = if p1.selected_hand_424 == 0 then 0 else 1
    local v6 = rt.copy(p2.animation_board_frame_12624)
    local v7 = rt.copy(p2.animation_hand_frames[v5 + 1])
    local v8 = rt.from_fn(4, function(p3) -- line: 50
        -- upvalues: v6 (copy)
        if p3 < 3 then
            return {
                v6[1][p3 + 1],
                v6[2][p3 + 1],
                v6[3][p3 + 1],
                0
            }
        end

        return { 0, 0, 0, 0 }
    end)
    local v9 = sub({ 0, 0, 0, 0 }, v6[4])
    local v10 = madd(v8[1], v9[1], madd(v8[2], v9[2], scale(v8[3], v9[3])))
    local v11 = rt.copy(import("skate_core/player/offboard/board_possession").IDENTITY)

    v11[1] = transform_direction(v8, v7[1])
    v11[2] = transform_direction(v8, v7[2])
    v11[3] = transform_direction(v8, v7[3])
    v11[4] = madd(v8[3], v7[4][3], madd(v8[2], v7[4][2], madd(v8[1], v7[4][1], v10)))
    p1.hands[p1.selected_hand_424 + 1].child = rt.copy(import("skate_core/player/offboard/board_possession").IDENTITY)
    p1.hands[p1.selected_hand_424 + 1].parent = v11
end

function t1.State.update(p4, p5, p6, p7, p8) -- line: 71
    -- upvalues: rt (copy), import (copy), v3 (copy), t1 (copy), PointGraph (copy), madd (copy), DT (copy)
    if p5.system_on_452 then
        import("skate_core/player/offboard/board_possession").State.update_state(p4, p5, p6, p7, p8)

        local state_448 = p5.state_448

        if state_448 == 1 then
            t1.State.update_drive_frames(p4, p6)
        elseif state_448 == 2 then
            if rt.to_i32(p5.word_444) > 0 then
                p5.word_444 = rt.wrapping_sub_u32(p5.word_444, 1)

                local v12 = t1.throw_torques(p6.processed, p7)

                p8.torque(p8, v12[1])
                p8.torque(p8, v12[2])
                p8.torque(p8, v12[3])
            end
        elseif state_448 == 3 then
            local retrieval = p4.retrieval

            retrieval.elapsed_192 += DT
            retrieval.progress_200 = 0.5
            retrieval.weight_204 = 0.5
            retrieval.target_64 = rt.copy(retrieval.initial_0)
            retrieval.target_64[4] = madd(p6.processed.hide_direction_464, p7.hide_offset, p6.processed.player_frame_192[4])
            retrieval.current_128 = rt.copy(retrieval.target_64)
            p8.hook_frame(p8, rt.copy(retrieval.current_128))
            p8.position(p8, rt.copy(retrieval.current_128[4]))
            p8.velocity(p8, { 0, 0, 0, 0 })
        elseif state_448 == 4 then
            local retrieval = p4.retrieval

            retrieval.elapsed_192 += DT

            local v13 = retrieval.elapsed_192 / retrieval.duration_196

            retrieval.progress_200 = if not (1 - v13 >= 0) then 1 else v13
            retrieval.weight_204 = PointGraph.evaluate(p7.retrieval_weight, retrieval.progress_200)
            retrieval.target_64 = rt.copy(p6.attachment_frame_0)
            retrieval.current_128 = v3.interpolate_affine(retrieval.initial_0, retrieval.target_64, retrieval.weight_204)
            p8.hook_frame(p8, rt.copy(retrieval.current_128))
            p8.target_position_velocity(p8, rt.copy(retrieval.current_128[4]))
        end
    end
end

function t1.throw_velocity(p9, p10) -- line: 113
    -- upvalues: v2 (copy), PointGraph (copy), scale (copy), length (copy), transform_direction (copy), RADIANS (copy)
    local v14, v15 = v2.sin_cos(0 * RADIANS)
    local t2 = {
        { v15, 0, -v14, v15 },
        { 0, 1, 0, 0 },
        { v14, 0, v15, v14 },
        { 0, 0, 0, 0 }
    }
    local v16, v17 = v2.sin_cos(-p10.throw_pitch * RADIANS)
    local v18 = transform_direction(t2, { 0, -v16, v17, 0 })
    local v19 = transform_direction(p9.player_frame_192, v18)
    local v20 = length(p9.velocity_912)

    return scale(v19, v20 + PointGraph.evaluate(p10.throw_velocity, v20))
end

function t1.throw_torques(p11, p12) -- line: 125
    -- upvalues: rt (copy), v2 (copy), dot (copy), scale (copy), cross (copy), unit (copy), transform_direction (copy), projected_angle (copy), wrap (copy), RADIANS (copy)
    local v21 = rt.copy(p11.board_frame_64[3])

    v21[2] = 0

    local v22 = rt.copy(p11.direction_400)

    v22[2] = 0

    local v23 = unit(v22, unit(v21, { 0, 0, 1, 0 }))
    local t3 = {
        0, 1, 0, 0
    }
    local t4 = {
        cross(t3, v23),
        t3,
        v23,
        { 0, 0, 0, 0 }
    }
    local v24, v25 = v2.sin_cos(-p12.throw_target_pitch * RADIANS)
    local v26 = transform_direction(t4, { 1, 0, 0, 1 })
    local v27 = transform_direction(t4, { 0, v25, v24, 0 })
    local v28 = transform_direction(t4, { 0, -v24, v25, 0 })
    local v29 = rt.copy(p11.board_frame_64[3])
    local v30 = rt.copy(p11.board_frame_64[1])

    if dot(v29, v28) < 0 then
        v29 = {
            -v29[1],
            -v29[2],
            -v29[3],
            -v29[4]
        }
        v30 = {
            -v30[1],
            -v30[2],
            -v30[3],
            -v30[4]
        }
    end

    return {
        scale(scale(v27, wrap(projected_angle(v29, v28, v27))), p12.throw_yaw_scalar),
        scale(scale(v26, wrap(projected_angle(v29, v28, v26))), p12.throw_pitch_scalar),
        (scale(scale(v28, wrap(projected_angle(v30, v26, v28))), p12.throw_roll_scalar))
    }
end

return t1
