-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/camera/vector_tracker")
local v2 = import("skate_core/camera/path_evaluator")
local v3 = import("skate_core/camera/positioner")
local v4 = import("skate_core/camera/direction")
local v5 = import("skate_core/camera/rig_tracking")
local dot, length, refined_reciprocal = v1.dot, v1.length, v1.refined_reciprocal
local PathEvaluator = v2.PathEvaluator
local direction_to_angles = v4.direction_to_angles
local position_from_angles = v3.position_from_angles
local t1 = {
    AvoidanceSubject = {},
    AvoidancePath = {},
    AvoidanceSettings = {},
    RigAvoidance = {}
}

function t1.RigAvoidance.update_reference(p1, p2, p3, p4, p5, p6, p7, p8) -- line: 54
    -- upvalues: rt (copy), v5 (copy), length (copy), refined_reciprocal (copy), PathEvaluator (copy), direction_to_angles (copy), position_from_angles (copy), t1 (copy)
    if p1.avoidance_mode == 1 and t1.RigAvoidance.subject_speed(p1, p6) < 0.5 then
        return
    end

    if bit32.band(p1.flags_516, 2) ~= 0 or p1.disable_time > 0 or p1.avoidance_mode == 0 then
        p1.heading_weight = 0
        p1.elevation_weight = 0

        return
    end

    if p1.avoidance_mode == 1 then
        local v6 = rt.copy(p1.tracked_anchor)

        v6[2] = p1.reference_height

        local t2 = {
            p5[1] - v6[1],
            p5[2] - v6[2],
            p5[3] - v6[3],
            p5[4] - v6[4]
        }
        local v7 = length(t2)

        if v7 < 9.999999747378752E-05 then
            return
        end

        local v8 = refined_reciprocal(v7)
        local v9 = direction_to_angles({
            v8 * t2[1],
            v8 * t2[2],
            v8 * t2[3],
            v8 * t2[4]
        })

        p1.avoidance_heading = -v9[2]
        p1.avoidance_elevation = v9[1]
    elseif p1.avoidance_mode == 2 then
        local v10 = direction_to_angles(p6.vector_452(p6))

        p1.avoidance_heading = -v10[2]
        p1.avoidance_elevation = v10[1]
    elseif p1.avoidance_mode == 3 then
        p1.avoidance_heading = p1.heading_reference
        p1.avoidance_elevation = 1.483529806137085
    elseif p1.avoidance_mode == 4 then
        p1.avoidance_heading = v5.wrap_vmx(p1.heading_target + 3.1415927410125732)

        if 0.1745329201221466 - p1.elevation_target >= 0 then
            p1.avoidance_elevation = 0.1745329201221466
        else
            p1.avoidance_elevation = p1.elevation_target
        end
    end

    if p1.avoidance_elevation == p1.avoidance_elevation then
        local v11 = position_from_angles(p1.anchor, { 0, 0, 0, 0 }, p1.avoidance_elevation, p1.avoidance_heading, p1.prediction_distance, p4.config.clamp_height, p4.radius + p4.config.floor_height)
        local v12 = p1.height_transition_time < p1.height_transition_duration
        local v13 = rt.copy(p1.velocity)

        if v12 then
            v13[2] = (p1.height_transition_end - p1.height_transition_start) / p1.height_transition_duration
        end

        local v14 = if p1.height_mode ~= 1 or v12 then 0 else 1

        t1.AvoidancePath.set(p1.paths[1], {
            position = rt.copy(p4.position),
            velocity = rt.copy(v13),
            radius = p3.radius_padding + p4.radius,
            horizon = p3.horizon
        }, v14)

        local v15 = p6.context_532(p6)

        PathEvaluator.update(p1.paths[1].evaluator, v15, p7[1], p8)

        local last_valid_time = p1.paths[1].evaluator.last_valid_time

        if p1.height_mode ~= 1 then
            v11 = {
                p1.anchor[1],
                p4.position[2],
                p1.anchor[3],
                p1.anchor[1]
            }
        end

        t1.AvoidancePath.set(p1.paths[2], {
            radius = 0.019999999552965164,
            position = v11,
            velocity = rt.copy(v13),
            horizon = p3.horizon
        }, v14)

        local v16 = p6.context_532(p6)

        PathEvaluator.update(p1.paths[2].evaluator, v16, p7[2], p8)

        local v17 = p6.vector_444(p6)

        t1.AvoidancePath.set(p1.paths[3], {
            radius = 0.019999999552965164,
            position = rt.copy(v17),
            velocity = rt.copy(v13),
            horizon = p3.horizon
        }, v14)

        local v18 = p6.context_532(p6)

        PathEvaluator.update(p1.paths[3].evaluator, v18, p7[3], p8)

        local last_valid_time2 = p1.paths[2].evaluator.last_valid_time
        local last_valid_time3 = p1.paths[3].evaluator.last_valid_time
        local v19 = p1.paths[2].evaluator.result_acceleration_flag ~= 0 or p1.paths[3].evaluator.result_acceleration_flag ~= 0
        local v20 = if last_valid_time2 - last_valid_time3 >= 0 then last_valid_time2 else last_valid_time3

        if last_valid_time2 <= last_valid_time3 then
            p1.flags_516 = bit32.bor(p1.flags_516, 1)
        end

        local v21 = p6.flag_608(p6)
        local v22 = if v19 then last_valid_time < v20 * 0.5 else last_valid_time < v20
        local v23 = v21 == 0
        local v24 = if v23 then bit32.band(p4.flags, 32) == 0 else nil

        if not v23 or v24 then
            if v21 == 0 and p1.height_mode ~= 1 and v22 then
                local v25 = t1.clamp(1 - last_valid_time / p3.horizon)
                local v26 = if p1.heading_weight - v25 >= 0 then p1.heading_weight else v25

                if p1.elevation_weight - v25 >= 0 then
                    v25 = p1.elevation_weight
                end

                p1.heading_weight = (1 - p3.heading_smoothing) * (v26 - p1.heading_weight) + p1.heading_weight
                p1.elevation_weight = (1 - p3.elevation_smoothing) * (v25 - p1.elevation_weight) + p1.elevation_weight
            elseif t1.RigAvoidance.subject_speed(p1, p6) > 0.15000000596046448 and p1.reset_time <= 0 or p6.flag_548(p6) ~= 0 then
                p1.heading_weight = t1.floor_zero(p1.heading_weight - p2 / p3.ease_out_time)
                p1.elevation_weight = t1.floor_zero(p1.elevation_weight - p2 / p3.ease_out_time)
                p1.flags_516 = bit32.band(p1.flags_516, 254)
            end
        else
            p1.heading_weight = p2 * 0.5 + p1.heading_weight
            p1.elevation_weight = p2 * 0.5 + p1.elevation_weight
        end

        p1.heading_weight = t1.clamp(p1.heading_weight)
        p1.elevation_weight = t1.clamp(p1.elevation_weight)
    end
end

function t1.RigAvoidance.subject_speed(p9, p10) -- line: 212
    -- upvalues: dot (copy)
    return dot(p9.velocity, p10.transform_376(p10)[3])
end

function t1.AvoidancePath.set_reference(p11, p12, p13) -- line: 216
    p11.evaluator.path = p12
    p11.prediction_flag = 0
    p11.evaluator.acceleration_flag = p13
end

function t1.floor_zero(p14) -- line: 222
    if p14 >= 0 then
        return p14
    end

    return 0
end

function t1.clamp(p15) -- line: 226
    local v27 = if -p15 >= 0 then 0 else p15

    if 1 - v27 >= 0 then
        return v27
    end

    return 1
end

local PERF = import("skate_core/camera/tracker").PERF
local length3 = v1.length3
local direction_to_angles_lanes = v4.direction_to_angles_lanes
local position_from_angles_lanes = v3.position_from_angles_lanes
local wrap_vmx = v5.wrap_vmx

local function set_path(p16, p17, p18, p19, p20, p21, p22, p23, p24, p25, p26, p27) -- line: 260
    local evaluator = p16.evaluator
    local path = evaluator.path
    local position, velocity = path.position, path.velocity

    position[1] = p17
    position[2] = p18
    position[3] = p19
    position[4] = p20
    velocity[1] = p21
    velocity[2] = p22
    velocity[3] = p23
    velocity[4] = p24
    path.radius = p25
    path.horizon = p26
    p16.prediction_flag = 0
    evaluator.acceleration_flag = p27
end

function t1.AvoidancePath.set(p28, p29, p30) -- line: 285
    -- upvalues: t1 (copy), PERF (copy)
    if PERF.reference then
        return t1.AvoidancePath.set_reference(p28, p29, p30)
    end

    local position, velocity = p29.position, p29.velocity
    local v28 = position[1]
    local v29 = position[2]
    local v30 = position[3]
    local v31 = position[4]
    local v32 = velocity[1]
    local v33 = velocity[2]
    local v34 = velocity[3]
    local v35 = velocity[4]
    local radius, horizon = p29.radius, p29.horizon
    local evaluator = p28.evaluator
    local path = evaluator.path
    local position2, velocity2 = path.position, path.velocity

    position2[1] = v28
    position2[2] = v29
    position2[3] = v30
    position2[4] = v31
    velocity2[1] = v32
    velocity2[2] = v33
    velocity2[3] = v34
    velocity2[4] = v35
    path.radius = radius
    path.horizon = horizon
    p28.prediction_flag = 0
    evaluator.acceleration_flag = p30
end

function t1.RigAvoidance.update(p31, p32, p33, p34, p35, p36, p37, p38) -- line: 306
    -- upvalues: refined_reciprocal (copy), PathEvaluator (copy), t1 (copy), PERF (copy), length3 (copy), direction_to_angles_lanes (copy), position_from_angles_lanes (copy), wrap_vmx (copy)
    if PERF.reference then
        return t1.RigAvoidance.update_reference(p31, p32, p33, p34, p35, p36, p37, p38)
    end

    local avoidance_mode = p31.avoidance_mode

    if avoidance_mode == 1 and t1.RigAvoidance.subject_speed(p31, p36) < 0.5 then
        return
    end

    if bit32.band(p31.flags_516, 2) ~= 0 or p31.disable_time > 0 or avoidance_mode == 0 then
        p31.heading_weight = 0
        p31.elevation_weight = 0

        return
    end

    if avoidance_mode == 1 then
        local tracked_anchor = p31.tracked_anchor
        local v36 = p35[1] - tracked_anchor[1]
        local v37 = p35[2] - p31.reference_height
        local v38 = p35[3] - tracked_anchor[3]
        local v39 = length3(v36, v37, v38)

        if v39 < 9.999999747378752E-05 then
            return
        end

        local v40 = refined_reciprocal(v39)
        local v41, v42 = direction_to_angles_lanes(v40 * v36, v40 * v37, v40 * v38)

        p31.avoidance_heading = -v42
        p31.avoidance_elevation = v41
    elseif avoidance_mode == 2 then
        local v43 = p36.vector_452(p36)
        local v44, v45 = direction_to_angles_lanes(v43[1], v43[2], v43[3])

        p31.avoidance_heading = -v45
        p31.avoidance_elevation = v44
    elseif avoidance_mode == 3 then
        p31.avoidance_heading = p31.heading_reference
        p31.avoidance_elevation = 1.483529806137085
    elseif avoidance_mode == 4 then
        p31.avoidance_heading = wrap_vmx(p31.heading_target + 3.1415927410125732)

        if 0.1745329201221466 - p31.elevation_target >= 0 then
            p31.avoidance_elevation = 0.1745329201221466
        else
            p31.avoidance_elevation = p31.elevation_target
        end
    end

    if p31.avoidance_elevation == p31.avoidance_elevation then
        local anchor = p31.anchor
        local v46 = anchor[1]
        local v47 = anchor[2]
        local v48 = anchor[3]
        local v49 = anchor[4]
        local height_mode = p31.height_mode
        local v50 = p31.height_transition_time < p31.height_transition_duration
        local velocity = p31.velocity
        local v51 = velocity[1]
        local v52 = velocity[2]
        local v53 = velocity[3]
        local v54 = velocity[4]

        if v50 then
            v52 = (p31.height_transition_end - p31.height_transition_start) / p31.height_transition_duration
        end

        local v55 = if height_mode ~= 1 or v50 then 0 else 1
        local paths = p31.paths
        local horizon = p33.horizon
        local position = p34.position
        local v56 = position[2]
        local v57 = paths[1]
        local v58 = position[1]
        local v59 = position[3]
        local v60 = position[4]
        local v61 = p33.radius_padding + p34.radius
        local evaluator = v57.evaluator
        local path = evaluator.path
        local position2, velocity2 = path.position, path.velocity

        position2[1] = v58
        position2[2] = v56
        position2[3] = v59
        position2[4] = v60
        velocity2[1] = v51
        velocity2[2] = v52
        velocity2[3] = v53
        velocity2[4] = v54
        path.radius = v61
        path.horizon = horizon
        v57.prediction_flag = 0
        evaluator.acceleration_flag = v55

        local v62 = p36.context_532(p36)

        PathEvaluator.update(paths[1].evaluator, v62, p37[1], p38)

        local last_valid_time = paths[1].evaluator.last_valid_time

        if height_mode == 1 then
            local config = p34.config
            local v63, v64, v65, v66 = position_from_angles_lanes(v46, v47, v48, v49, 0, 0, 0, 0, p31.avoidance_elevation, p31.avoidance_heading, p31.prediction_distance, config.clamp_height, p34.radius + config.floor_height)
            local v67 = paths[2]
            local evaluator = v67.evaluator
            local path = evaluator.path
            local position, velocity = path.position, path.velocity

            position[1] = v63
            position[2] = v64
            position[3] = v65
            position[4] = v66
            velocity[1] = v51
            velocity[2] = v52
            velocity[3] = v53
            velocity[4] = v54
            path.radius = 0.019999999552965164
            path.horizon = horizon
            v67.prediction_flag = 0
            evaluator.acceleration_flag = v55
        else
            local v68 = paths[2]
            local evaluator = v68.evaluator
            local path = evaluator.path
            local position, velocity = path.position, path.velocity

            position[1] = v46
            position[2] = v56
            position[3] = v48
            position[4] = v46
            velocity[1] = v51
            velocity[2] = v52
            velocity[3] = v53
            velocity[4] = v54
            path.radius = 0.019999999552965164
            path.horizon = horizon
            v68.prediction_flag = 0
            evaluator.acceleration_flag = v55
        end

        local v69 = p36.context_532(p36)

        PathEvaluator.update(paths[2].evaluator, v69, p37[2], p38)

        local v70 = p36.vector_444(p36)
        local v71 = paths[3]
        local v72 = v70[1]
        local v73 = v70[2]
        local v74 = v70[3]
        local v75 = v70[4]
        local evaluator2 = v71.evaluator
        local path2 = evaluator2.path
        local position3, velocity3 = path2.position, path2.velocity

        position3[1] = v72
        position3[2] = v73
        position3[3] = v74
        position3[4] = v75
        velocity3[1] = v51
        velocity3[2] = v52
        velocity3[3] = v53
        velocity3[4] = v54
        path2.radius = 0.019999999552965164
        path2.horizon = horizon
        v71.prediction_flag = 0
        evaluator2.acceleration_flag = v55

        local v76 = p36.context_532(p36)

        PathEvaluator.update(paths[3].evaluator, v76, p37[3], p38)

        local last_valid_time2 = paths[2].evaluator.last_valid_time
        local last_valid_time3 = paths[3].evaluator.last_valid_time
        local v77 = paths[2].evaluator.result_acceleration_flag ~= 0 or paths[3].evaluator.result_acceleration_flag ~= 0
        local v78 = if last_valid_time2 - last_valid_time3 >= 0 then last_valid_time2 else last_valid_time3

        if last_valid_time2 <= last_valid_time3 then
            p31.flags_516 = bit32.bor(p31.flags_516, 1)
        end

        local v79 = p36.flag_608(p36)
        local v80 = if v77 then last_valid_time < v78 * 0.5 else last_valid_time < v78
        local v81 = v79 == 0
        local v82 = if v81 then bit32.band(p34.flags, 32) == 0 else nil

        if not v81 or v82 then
            if v79 == 0 and height_mode ~= 1 and v80 then
                local v83 = t1.clamp(1 - last_valid_time / horizon)
                local v84 = if p31.heading_weight - v83 >= 0 then p31.heading_weight else v83

                if p31.elevation_weight - v83 >= 0 then
                    v83 = p31.elevation_weight
                end

                p31.heading_weight = (1 - p33.heading_smoothing) * (v84 - p31.heading_weight) + p31.heading_weight
                p31.elevation_weight = (1 - p33.elevation_smoothing) * (v83 - p31.elevation_weight) + p31.elevation_weight
            elseif t1.RigAvoidance.subject_speed(p31, p36) > 0.15000000596046448 and p31.reset_time <= 0 or p36.flag_548(p36) ~= 0 then
                p31.heading_weight = t1.floor_zero(p31.heading_weight - p32 / p33.ease_out_time)
                p31.elevation_weight = t1.floor_zero(p31.elevation_weight - p32 / p33.ease_out_time)
                p31.flags_516 = bit32.band(p31.flags_516, 254)
            end
        else
            p31.heading_weight = p32 * 0.5 + p31.heading_weight
            p31.elevation_weight = p32 * 0.5 + p31.elevation_weight
        end

        p31.heading_weight = t1.clamp(p31.heading_weight)
        p31.elevation_weight = t1.clamp(p31.elevation_weight)
    end
end

return t1
