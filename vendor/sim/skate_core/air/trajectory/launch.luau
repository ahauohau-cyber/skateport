-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/air/trajectory/math")
local v2 = import("skate_core/trigonometry")
local PointGraph = import("skate_core/point_graph").PointGraph
local UP, STEP, dot, add = v1.UP, v1.STEP, v1.dot, v1.add
local sub, scale, madd, cross = v1.sub, v1.scale, v1.madd, v1.cross
local inverse_length, reciprocal, length, normalize = v1.inverse_length, v1.reciprocal, v1.length, v1.normalize
local transform = v1.transform
local t1 = {}

function t1.adjust_velocity(p1, p2, p3) -- line: 19
    -- upvalues: rt (copy), UP (copy), dot (copy), add (copy), sub (copy), scale (copy), length (copy), normalize (copy)
    local v3 = rt.copy(p2.ground_normal)
    local v4 = rt.copy(p1.start_velocity)
    local v5 = scale(v3, dot(v4, v3))

    v5[2] = 0

    local v6 = add({
        0,
        v4[2],
        0, 0
    }, v5)
    local v7 = sub(v4, v6)
    local v9 = normalize(sub(UP, scale(v3, rt.fmin(rt.fmax(p2.directional_input - 0.25, -1), 1) * p3.vert_jump_align_max_angle)))

    if not (v3[2] >= p3.vert_jump_align_max_ground_normal_y) then
        if normalize(v6)[2] > p3.vert_jump_align_min_direction_y then
            p1.start_velocity = scale(normalize(add(scale(add(scale(v9, length(v6)), v7), p3.vert_jump_align_factor), (scale(normalize(v4), 1 - p3.vert_jump_align_factor)))), length(v4))

            return true
        end

        if not p1.player_jumped and p2.previous_physics_state ~= 200 then
            local v12 = scale(v3, dot(v4, v3))

            p1.start_velocity = add(scale(v12, p3.natural_air_off_verts_scalar), sub(v4, v12))
        end
    end

    return false
end

function t1.candidate_velocities(p4, p5) -- line: 46
    -- upvalues: rt (copy), v2 (copy), PointGraph (copy), UP (copy), scale (copy), madd (copy), cross (copy), length (copy), normalize (copy)
    local v13 = math.min(p4.trajectory_count, 7)
    local v14 = table.create(v13)

    if v13 ~= 0 then
        local v15 = rt.copy(p4.start_velocity)

        table.insert(v14, rt.copy(v15))

        local v16 = normalize(cross(UP, v15))
        local v17 = normalize(cross(v16, UP))
        local v18 = length(v15)
        local v19 = if p4.player_jumped then length(p4.com_velocity) else v18
        local v20 = p4.cone_angle_x * 0.01745329238474369
        local v21 = PointGraph.evaluate(p5.cone_angle_z_vs_speed, v19 * 0.05) * p4.cone_angle_z * 0.01745329238474369
        local v22 = rt.fmin(rt.fmax(v19, p5.speed_factor_min), p5.speed_factor_max)
        local v23 = scale(v16, v2.sin(v20) * v22)
        local v24 = scale(v17, v2.sin(v21) * v22)

        if v13 > 1 then
            local v25 = 6.2831854820251465 / (v13 - 1)
            local v26 = v13 - 1
            local n1 = 0

            for _ = 1, v26 do
                local v27 = madd(v24, v2.cos(n1), madd(v23, v2.sin(n1), v15))

                table.insert(v14, scale(normalize(v27), rt.fmin(length(v27), v18)))
                n1 += v25
            end
        end
    end

    return v14
end

t1.LaunchBatch = {}

function t1.batch(p6, p7, p8) -- line: 87
    -- upvalues: rt (copy), PointGraph (copy), dot (copy), sub (copy), scale (copy), madd (copy), transform (copy), t1 (copy)
    local v30 = t1.candidate_velocities(p6, p8)
    local v32 = PointGraph.evaluate(p8.displacement_vs_ground_normal, (math.abs(p7.ground_normal[2])))
    local v33 = PointGraph.evaluate(p8.displacement_vs_speed, p7.board_vertical_velocity * 0.1)
    local v34 = rt.fmax(v33, v32)
    local v35 = dot(sub(p6.animation_com_position, p7.contact_position), p6.reckoning_transform[2]) - p8.trajectory_radius
    local v36 = rt.fmin(v35, p8.trajectory_displacement) * (1 - v34) + p8.trajectory_displacement * v34
    local v37 = sub(p6.animation_com_position, scale(p6.reckoning_transform[2], v36))
    local v38 = rt.copy(p6.board_position)

    if p6.use_position_override then
        v37 = rt.copy(p6.start_position_override)
        v38 = rt.copy(p6.board_position_override)
    end

    local v39 = sub(p6.animation_com_position, v37)
    local v40 = t1.max_time(p6.start_velocity, p8)
    local v41 = table.create(#v30)

    for i = 1, #v30 do
        local v42 = v30[i]

        v41[i] = {
            trajectory = {
                position = madd(v42, p6.timestep, v37),
                velocity = rt.copy(v42),
                acceleration = rt.copy(p7.gravity),
                duration = v40
            },
            radius = p8.trajectory_radius,
            start_error = p8.trajectory_error_start,
            end_error = p8.trajectory_error_end
        }
    end

    return {
        requests = v41,
        velocities = v30,
        origin = v37,
        board_position = v38,
        com_displacement = v39,
        local_board_position = transform(p6.reckoning_inverse, sub(p6.board_position, v37)),
        local_com_position = transform(p6.reckoning_inverse, v39)
    }
end

function t1.max_time(p9, p10) -- line: 130
    -- upvalues: rt (copy), inverse_length (copy)
    local v43 = p9[2] * p9[2] + -(p10.trajectory_max_drop * -19.600000381469727)
    local v44 = if v43 == 0 then 0 else v43 * inverse_length(v43)

    return rt.fmin((-p9[2] - v44) * -0.10204081237316132, p10.trajectory_max_time)
end

function t1.adjust_trajectory(p11, p12, p13, p14) -- line: 138
    -- upvalues: STEP (copy), dot (copy), scale (copy), madd (copy), reciprocal (copy), length (copy)
    if p12 <= 0 then
        return
    end

    local v45 = scale(p13, reciprocal(p12 * STEP))

    p11.velocity = madd(v45, if dot(v45, v45) > p14 * p14 then p14 / length(v45) else 1, p11.velocity)
end

return t1
