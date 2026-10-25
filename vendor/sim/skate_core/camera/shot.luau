-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/camera/shot_orientation")
local v2 = import("skate_core/camera/rig_tracking")
local v3 = import("skate_core/camera/orientation_math")
local v4 = import("skate_core/camera/vector_tracker")
local v5 = import("skate_core/trigonometry")
local interpolate_orientation = v1.interpolate_orientation
local PERF = import("skate_core/camera/tracker").PERF
local t1 = {}

t1.Shot = {}

function t1.Shot.new() -- line: 35
    -- upvalues: rt (copy)
    return {
        distance = 2,
        lens_length = 12,
        board_offset = 0,
        position_heading = 3.1415927410125732,
        position_elevation = 0,
        follow_subject_in_air = 1,
        mirror_for_stance = 1,
        snap_to_reference_point = 0,
        use_previous_shot = 0,
        use_drop_predictor = 0,
        use_free_camera_stick = 0,
        avoidance_override = 0,
        blur = 1,
        transition_blur = 1,
        subject_opacity = 1,
        collision_hint = 0,
        anchor = 0,
        compass_north = 0,
        world_heading = 0,
        smoothing = rt.filled(4, 0.800000011920929),
        reference_weights = {
            0, 0, 0, 0, 1, 0, 0, 0,
            0, 0
        },
        framing = { 0, 0, 0 },
        arm_orientation = { 0, 0, 0, 1 },
        camera_orientation = { 0, 0, 0, 1 }
    }
end

function t1.Shot.update_normal_reference(p1, p2, p3) -- line: 67
    -- upvalues: v2 (copy), v3 (copy)
    if p1.use_previous_shot ~= 0 then
        return
    end

    local position_heading = p1.position_heading
    local v6 = v2.wrap_vmx(-p1.position_heading - position_heading)
    local v7 = v2.wrap_vmx(v6 * ((1 - p3) * 0.5) + position_heading)
    local v8 = v2.wrap_vmx(v7 + p2)

    p1.arm_orientation = v3.quaternion_from_angles(p1.position_elevation, v8, 0)
end

function t1.Shot.reference_point_reference(p4, p5, p6, p7) -- line: 81
    -- upvalues: rt (copy), v4 (copy)
    local t2 = {
        p6[1] * p4.board_offset,
        p6[2] * p4.board_offset,
        p6[3] * p4.board_offset,
        p6[4] * p4.board_offset
    }
    local t3 = { 0, 0, 0, 0 }
    local n1 = 0

    for i = 0, 9 do
        local v9 = p5[i + 1]
        local v10 = p4.reference_weights[i + 1]

        n1 = v10 + n1

        local t4 = {}

        t4[1] = (v9[1] + t2[1]) * v10 + t3[1]
        t4[2] = (v9[2] + t2[2]) * v10 + t3[2]
        t4[3] = (v9[3] + t2[3]) * v10 + t3[3]
        t4[4] = (v9[4] + t2[4]) * v10 + t3[4]
        t3 = t4
    end

    if math.abs(n1) < 9.999999747378752E-05 then
        return rt.copy(p7)
    end

    local v11 = v4.refined_reciprocal(n1)

    return {
        v11 * t3[1],
        v11 * t3[2],
        v11 * t3[3],
        v11 * t3[4]
    }
end

function t1.Shot.interpolate_from(p8, p9, p10, p11) -- line: 125
    -- upvalues: v1 (copy), t1 (copy), PERF (copy)
    if PERF.reference then
        return t1.Shot.interpolate_from_reference(p8, p9, p10, p11)
    end

    local v12 = t1.sine_blend_fast(p11)
    local distance = p9.distance

    p8.distance = (p10.distance - distance) * v12 + distance

    local lens_length = p9.lens_length

    p8.lens_length = (p10.lens_length - lens_length) * v12 + lens_length

    local smoothing = p9.smoothing
    local smoothing2 = p10.smoothing
    local smoothing3 = p8.smoothing
    local v13 = smoothing[1]

    smoothing3[1] = (smoothing2[1] - v13) * v12 + v13

    local v14 = smoothing[2]

    smoothing3[2] = (smoothing2[2] - v14) * v12 + v14

    local v15 = smoothing[3]

    smoothing3[3] = (smoothing2[3] - v15) * v12 + v15

    local v16 = smoothing[4]

    smoothing3[4] = (smoothing2[4] - v16) * v12 + v16

    local reference_weights = p9.reference_weights
    local reference_weights2 = p10.reference_weights
    local reference_weights3 = p8.reference_weights

    for i = 1, 10 do
        local v17 = reference_weights[i]

        reference_weights3[i] = (reference_weights2[i] - v17) * v12 + v17
    end

    local board_offset = p9.board_offset

    p8.board_offset = (p10.board_offset - board_offset) * v12 + board_offset

    local position_elevation = p9.position_elevation

    p8.position_elevation = (p10.position_elevation - position_elevation) * v12 + position_elevation

    local framing = p9.framing
    local framing2 = p10.framing
    local framing3 = p8.framing
    local v18 = framing[1]

    framing3[1] = (framing2[1] - v18) * v12 + v18

    local v19 = framing[2]

    framing3[2] = (framing2[2] - v19) * v12 + v19

    local v20 = framing[3]

    framing3[3] = (framing2[3] - v20) * v12 + v20
    p8.follow_subject_in_air = p10.follow_subject_in_air
    p8.mirror_for_stance = p10.mirror_for_stance
    p8.snap_to_reference_point = p10.snap_to_reference_point
    p8.use_previous_shot = p10.use_previous_shot
    p8.use_drop_predictor = p10.use_drop_predictor
    p8.use_free_camera_stick = p10.use_free_camera_stick
    p8.avoidance_override = p10.avoidance_override

    local blur = p9.blur

    p8.blur = (p10.blur - blur) * v12 + blur
    p8.transition_blur = p10.transition_blur

    local subject_opacity = p9.subject_opacity

    p8.subject_opacity = (p10.subject_opacity - subject_opacity) * v12 + subject_opacity
    p8.collision_hint = p10.collision_hint
    p8.anchor = p10.anchor
    p8.compass_north = p10.compass_north

    local world_heading = p9.world_heading

    p8.world_heading = (p10.world_heading - world_heading) * v12 + world_heading
    v1.slerp_into(p8.arm_orientation, p9.arm_orientation, p10.arm_orientation, v12)
    v1.slerp_into(p8.camera_orientation, p9.camera_orientation, p10.camera_orientation, v12)
end

function t1.Shot.interpolate_from_reference(p12, p13, p14, p15) -- line: 177
    -- upvalues: interpolate_orientation (copy), t1 (copy)
    local function blend(p16, p17) -- line: 178
        -- upvalues: p15 (copy), t1 (copy)
        return t1.interpolate_float(p16, p17, 0, p15)
    end

    local distance = p13.distance
    local distance2 = p14.distance

    p12.distance = t1.interpolate_float(distance, distance2, 0, p15)

    local lens_length = p13.lens_length
    local lens_length2 = p14.lens_length

    p12.lens_length = t1.interpolate_float(lens_length, lens_length2, 0, p15)

    local v21 = p13.smoothing[1]
    local v22 = p14.smoothing[1]
    local t5 = {}

    t5[1] = t1.interpolate_float(v21, v22, 0, p15)

    local v23 = p13.smoothing[2]
    local v24 = p14.smoothing[2]

    t5[2] = t1.interpolate_float(v23, v24, 0, p15)

    local v25 = p13.smoothing[3]
    local v26 = p14.smoothing[3]

    t5[3] = t1.interpolate_float(v25, v26, 0, p15)

    local v27 = p13.smoothing[4]
    local v28 = p14.smoothing[4]

    t5[4] = t1.interpolate_float(v27, v28, 0, p15)
    p12.smoothing = t5

    local t6 = {}

    for i = 0, 9 do
        local v29 = p13.reference_weights[i + 1]
        local v30 = p14.reference_weights[i + 1]

        t6[i + 1] = t1.interpolate_float(v29, v30, 0, p15)
    end

    p12.reference_weights = t6

    local board_offset = p13.board_offset
    local board_offset2 = p14.board_offset

    p12.board_offset = t1.interpolate_float(board_offset, board_offset2, 0, p15)

    local position_elevation = p13.position_elevation
    local position_elevation2 = p14.position_elevation

    p12.position_elevation = t1.interpolate_float(position_elevation, position_elevation2, 0, p15)

    local v31 = p13.framing[1]
    local v32 = p14.framing[1]
    local t7 = {}

    t7[1] = t1.interpolate_float(v31, v32, 0, p15)

    local v33 = p13.framing[2]
    local v34 = p14.framing[2]

    t7[2] = t1.interpolate_float(v33, v34, 0, p15)

    local v35 = p13.framing[3]
    local v36 = p14.framing[3]

    t7[3] = t1.interpolate_float(v35, v36, 0, p15)
    p12.framing = t7
    p12.follow_subject_in_air = p14.follow_subject_in_air
    p12.mirror_for_stance = p14.mirror_for_stance
    p12.snap_to_reference_point = p14.snap_to_reference_point
    p12.use_previous_shot = p14.use_previous_shot
    p12.use_drop_predictor = p14.use_drop_predictor
    p12.use_free_camera_stick = p14.use_free_camera_stick
    p12.avoidance_override = p14.avoidance_override

    local blur = p13.blur
    local blur2 = p14.blur

    p12.blur = t1.interpolate_float(blur, blur2, 0, p15)
    p12.transition_blur = p14.transition_blur

    local subject_opacity = p13.subject_opacity
    local subject_opacity2 = p14.subject_opacity

    p12.subject_opacity = t1.interpolate_float(subject_opacity, subject_opacity2, 0, p15)
    p12.collision_hint = p14.collision_hint
    p12.anchor = p14.anchor
    p12.compass_north = p14.compass_north

    local world_heading = p13.world_heading
    local world_heading2 = p14.world_heading

    p12.world_heading = t1.interpolate_float(world_heading, world_heading2, 0, p15)
    p12.arm_orientation = interpolate_orientation(p13.arm_orientation, p14.arm_orientation, p15)
    p12.camera_orientation = interpolate_orientation(p13.camera_orientation, p14.camera_orientation, p15)
end

function t1.interpolate_float(p18, p19, p20, p21) -- line: 220
    -- upvalues: t1 (copy)
    if p20 == 0 then
        return (p19 - p18) * t1.sine_blend(p21) + p18
    end

    if p20 == 1 then
        return p19
    end

    return p18
end

function t1.sine_blend(p22) -- line: 230
    -- upvalues: v5 (copy)
    local v37 = p22 * 3.1415927410125732 + -1.5707963705062866

    return v5.sin(v37) * 0.5 + 0.5
end

function t1.filter_blend_value(p23, p24, p25, p26, p27) -- line: 237
    local v38 = 1 - p25
    local v39 = v38 * v38 * (p24 - p23) + p23

    if p26 - v39 >= 0 then
        v39 = p26
    end

    if p27 - v39 >= 0 then
        return v39
    end

    return p27
end

function t1.blend_interval(p28, p29, p30) -- line: 251
    local v40

    if p29[1] then
        v40 = 0 + 1

        if p29[2] then
            v40 += 1

            if p29[3] then
                v40 += 1
            end
        end
    else
        v40 = 0
    end

    if v40 == 0 then
        return nil
    end

    for i = 0, v40 - 1 do
        if p30 < p28[i + 1] then
            if i == 0 then
                return { 0, 0, 1 }
            end

            return {
                i - 1,
                i,
                (p30 - p28[i]) / (p28[i + 1] - p28[i])
            }
        end
    end

    return {
        math.max(v40 - 2, 0),
        v40 - 1,
        1
    }
end

function t1.sine_blend_fast(p31) -- line: 286
    -- upvalues: v5 (copy)
    local v42 = p31 * 3.1415927410125732 + -1.5707963705062866

    return v5.sin(v42) * 0.5 + 0.5
end

function t1.Shot.update_normal(p32, p33, p34) -- line: 293
    -- upvalues: v2 (copy), v3 (copy), t1 (copy), PERF (copy)
    if PERF.reference then
        return t1.Shot.update_normal_reference(p32, p33, p34)
    end

    if p32.use_previous_shot ~= 0 then
        return
    end

    local position_heading = p32.position_heading
    local v43 = v2.wrap_vmx(-p32.position_heading - position_heading)
    local v44 = v2.wrap_vmx(v43 * ((1 - p34) * 0.5) + position_heading)
    local v45 = v2.wrap_vmx(v44 + p33)
    local v46, v47, v48, v49 = v3.quaternion_from_angles_lanes(p32.position_elevation, v45, 0)
    local arm_orientation = p32.arm_orientation

    arm_orientation[1] = v46
    arm_orientation[2] = v47
    arm_orientation[3] = v48
    arm_orientation[4] = v49
end

function t1.Shot.reference_point_lanes(p35, p36, p37, p38) -- line: 311
    -- upvalues: v4 (copy)
    local board_offset = p35.board_offset
    local v50 = p37[1] * board_offset
    local v51 = p37[2] * board_offset
    local v52 = p37[3] * board_offset
    local v53 = p37[4] * board_offset
    local reference_weights = p35.reference_weights
    local n2 = 0
    local n3 = 0
    local n4 = 0
    local n5 = 0
    local n6 = 0

    for i = 1, 10 do
        local v54 = p36[i]
        local v55 = reference_weights[i]

        n6 = v55 + n6
        n2 = (v54[1] + v50) * v55 + n2
        n3 = (v54[2] + v51) * v55 + n3
        n4 = (v54[3] + v52) * v55 + n4
        n5 = (v54[4] + v53) * v55 + n5
    end

    if math.abs(n6) < 9.999999747378752E-05 then
        return p38[1], p38[2], p38[3], p38[4]
    end

    local v56 = v4.refined_reciprocal(n6)

    return v56 * n2, v56 * n3, v56 * n4, v56 * n5
end

function t1.Shot.reference_point(p39, p40, p41, p42) -- line: 342
    -- upvalues: t1 (copy), PERF (copy)
    if PERF.reference then
        return t1.Shot.reference_point_reference(p39, p40, p41, p42)
    end

    local v57, v58, v59, v60 = t1.Shot.reference_point_lanes(p39, p40, p41, p42)

    return { v57, v58, v59, v60 }
end

function t1.blend_interval_lanes(p43, p44, p45) -- line: 353
    local v61 = if p44 > 3 then 3 else p44

    if v61 == 0 then
        return nil, nil, nil
    end

    for i = 0, v61 - 1 do
        if p45 < p43[i + 1] then
            if i == 0 then
                return 0, 0, 1
            end

            return i - 1, i, (p45 - p43[i]) / (p43[i + 1] - p43[i])
        end
    end

    return math.max(v61 - 2, 0), v61 - 1, 1
end

return t1
