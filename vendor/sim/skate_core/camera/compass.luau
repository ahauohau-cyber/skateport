-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/camera/direction")
local v2 = import("skate_core/camera/manager_state")
local v3 = import("skate_core/camera/vector_tracker")
local v4 = import("skate_core/camera/rig_tracking")
local v5 = import("skate_core/camera/manager_incline")
local v6 = import("skate_core/camera/orientation_math")
local v7 = import("skate_core/camera/compass_movement")
local v8 = import("skate_core/camera/compass_orbit")
local direction_to_angles = v1.direction_to_angles
local clamp = v2.clamp
local length = v3.length
local t1 = {
    CompassSettings = {},
    CompassInputs = {},
    Compass = {}
}

function t1.Compass.new() -- line: 79
    return {
        movement_heading = 0,
        orbit_delta = 0,
        previous_reset = true,
        stopped_time = 0,
        deadzone_size = 0,
        headings = table.create(9, 0),
        velocity = { 0, 0, 0, 0 },
        damped_velocity = { 0, 0, 0, 0 },
        previous_position = { 0, 0, 0, 0 },
        orbit_position = { 0, 0, 0, 0 },
        deadzone_position = { 0, 0 },
        deadzone_velocity = { 0, 0 }
    }
end

function t1.Compass.update_reference(p1, p2, p3, p4) -- line: 97
    -- upvalues: rt (copy), direction_to_angles (copy), length (copy), t1 (copy)
    if p1.previous_reset then
        p1.previous_position = rt.copy(p3.transform[4])
        p1.stopped_time = 0
        p1.deadzone_size = 0
    end

    t1.Compass.update_movement(p1, p2, p3, p4)

    local v9 = t1.heading(p3.ground_normal)
    local v10 = t1.heading(p3.landing_normal)

    if math.abs(v9 - v10) > 3.1415927410125732 then
        if v10 <= v9 then
            v10 += 6.2831854820251465
        else
            v9 += 6.2831854820251465
        end
    end

    p1.headings[2] = t1.wrap((v10 - v9) * p3.trajectory_fraction + v9)
    p1.headings[1] = p1.movement_heading

    local v12 = t1.horizontal(t1.sub(p3.landing_position, p3.launch_position))

    if p3.trajectory_fraction > 0 and length(v12) > 1 then
        if p2 == 0 then
            p1.headings[5] = direction_to_angles(p3.skeleton_direction)[2]
        else
            p1.headings[5] = -direction_to_angles(p3.trajectory_direction)[2]
        end

        p1.headings[1] = t1.wrap(t1.blend(p1.headings[1], p1.headings[5], p3.trajectory_fraction))
    end

    p1.headings[4] = t1.heading(p3.transform[3])
    t1.Compass.update_orbit(p1, p2, p3)
    t1.Compass.update_follow(p1, p3)

    local v13 = t1.horizontal(t1.sub(p3.transform[4], p3.camera_position))
    local v14 = t1.heading(p3.transform[3])
    local v15 = t1.heading(v13)
    local v16 = t1.wrap_floor(v15 - v14)

    if math.abs(v16) <= 1.2217304706573486 then
        if v16 >= 0 then
            p1.headings[9] = v14 + 1.2217304706573486
        else
            p1.headings[9] = v14 - 1.2217304706573486
        end
    else
        p1.headings[9] = v15
    end

    p1.previous_reset = p2 == 0

    return rt.copy(p1.headings)
end

function t1.Compass.update_follow_reference(p5, p6) -- line: 145
    -- upvalues: clamp (copy), length (copy), t1 (copy)
    local v17 = t1.sub(p6.transform[4], p6.camera_position)

    if p6.selected_compass ~= 7 then
        p5.headings[8] = t1.heading(t1.horizontal(v17))

        return
    end

    if p6.air_flag_452 then
        p5.headings[8] = t1.heading(t1.horizontal(t1.sub(p6.look_target, p6.transform[4])))
    else
        local v18 = t1.horizontal(p5.velocity)
        local v19 = length(v18)

        if v19 > 0.7 then
            local v20 = clamp((v19 - 0.7) * 0.43478259444236755, 0, 1) * 0.6
            local v21 = t1.heading(v18)
            local v22 = t1.heading(v17)

            p5.headings[8] = clamp(t1.wrap_floor(v21 - v22) * 0.25, -v20, v20) + v22
        end
    end
end

t1.PI = 3.1415927410125732
t1.TAU = 6.2831854820251465

function t1.horizontal(p7) -- line: 166
    return {
        p7[1],
        0,
        p7[3],
        p7[4]
    }
end

function t1.sub(p8, p9) -- line: 170
    return {
        p8[1] - p9[1],
        p8[2] - p9[2],
        p8[3] - p9[3],
        p8[4] - p9[4]
    }
end

function t1.wrap(p10) -- line: 174
    -- upvalues: v4 (copy)
    return v4.wrap_vmx(p10)
end

function t1.blend(p11, p12, p13) -- line: 178
    -- upvalues: t1 (copy)
    return t1.wrap(t1.wrap(p12 - p11) * p13 + p11)
end

function t1.wrap_floor(p14) -- line: 182
    return -(math.floor(p14 * 0.15915493667125702 + 0.5) * 6.2831854820251465 + -p14)
end

function t1.heading(p15) -- line: 188
    -- upvalues: v5 (copy)
    if p15[2] > 0.9998000264167786 then
        return 0
    end

    return v5.atan_ratio(-p15[1], p15[3])
end

t1.CompassPoseInputs = {}

function t1.CompassPoseInputs.bind(p16, p17, p18, p19) -- line: 201
    -- upvalues: rt (copy), v6 (copy), clamp (copy)
    local v24 = p17.rig.trajectory_valid ~= 0
    local v25 = if p17.rig.grinding ~= 0 then rt.copy(p17.direction_424) elseif v24 then rt.copy(p16.trajectory_direction) else v6.normalize(p16.board_velocity)
    local t2 = {
        ground_normal = rt.copy(p17.rig.last_valid_ground_up)
    }

    t2.landing_normal = if v24 then rt.copy(p17.landing_normal) else rt.copy(p17.ground_normal)
    t2.transform = rt.copy(p17.rig.transform)
    t2.trajectory_direction = v25

    if v24 then
        t2.launch_position = rt.copy(p17.launch_position)
        t2.landing_position = rt.copy(p17.landing_position)
    else
        t2.launch_position = { 0, 0, 0, 0 }
        t2.landing_position = { 0, 0, 0, 0 }
    end

    t2.grind_direction = rt.copy(p17.direction_424)
    t2.skeleton_direction = rt.copy(p16.skeleton_direction)
    t2.camera_position = rt.copy(p18)
    t2.look_target = rt.copy(p16.look_target)
    t2.look = rt.copy(p17.look)
    t2.trajectory_fraction = if v24 then clamp(p17.trajectory_time / p17.trajectory_duration, 0, 1) else 0
    t2.selected_compass = p19
    t2.no_trajectory = not v24
    t2.state_103 = p16.state_103
    t2.wiping_out = p17.rig.wiping_out ~= 0
    t2.grinding = p17.rig.grinding ~= 0
    t2.air_flag_452 = p17.rig.air_flag_452 ~= 0

    return t2
end

for v26, v27 in v7.Compass do
    t1.Compass[v26] = v27
end

for v28, v29 in v8.Compass do
    t1.Compass[v28] = v29
end

local PERF = import("skate_core/camera/tracker").PERF
local length3 = v3.length3
local direction_heading = v1.direction_heading
local atan_ratio = v5.atan_ratio
local wrap_vmx = v4.wrap_vmx
local v30 = table.freeze({ 0, 0, 0, 0 })

function t1.heading_lanes(p20, p21, p22) -- line: 272
    -- upvalues: atan_ratio (copy)
    if p21 > 0.9998000264167786 then
        return 0
    end

    return atan_ratio(-p20, p22)
end

function t1.Compass.update_headings(p23, p24, p25, p26) -- line: 282
    -- upvalues: t1 (copy), length3 (copy), direction_heading (copy), atan_ratio (copy), wrap_vmx (copy)
    local transform = p25.transform
    local v31 = transform[3]
    local v32 = transform[4]

    if p23.previous_reset then
        local previous_position = p23.previous_position
        local v33 = v32[1]
        local v34 = v32[2]
        local v35 = v32[3]
        local v36 = v32[4]

        previous_position[1] = v33
        previous_position[2] = v34
        previous_position[3] = v35
        previous_position[4] = v36
        p23.stopped_time = 0
        p23.deadzone_size = 0
    end

    t1.Compass.update_movement(p23, p24, p25, p26)

    local ground_normal = p25.ground_normal
    local v37 = ground_normal[1]
    local v38 = ground_normal[2]
    local v39 = ground_normal[3]
    local v40 = if v38 > 0.9998000264167786 then 0 else atan_ratio(-v37, v39)
    local landing_normal = p25.landing_normal
    local v41 = landing_normal[1]
    local v42 = landing_normal[2]
    local v43 = landing_normal[3]
    local v44 = if v42 > 0.9998000264167786 then 0 else atan_ratio(-v41, v43)

    if math.abs(v40 - v44) > 3.1415927410125732 then
        if v44 <= v40 then
            v44 += 6.2831854820251465
        else
            v40 += 6.2831854820251465
        end
    end

    local headings = p23.headings
    local trajectory_fraction = p25.trajectory_fraction

    headings[2] = wrap_vmx((v44 - v40) * trajectory_fraction + v40)
    headings[1] = p23.movement_heading

    local landing_position, launch_position = p25.landing_position, p25.launch_position

    if trajectory_fraction > 0 and length3(landing_position[1] - launch_position[1], 0, landing_position[3] - launch_position[3]) > 1 then
        if p24 == 0 then
            local skeleton_direction = p25.skeleton_direction

            headings[5] = direction_heading(skeleton_direction[1], skeleton_direction[3])
        else
            local trajectory_direction = p25.trajectory_direction

            headings[5] = -direction_heading(trajectory_direction[1], trajectory_direction[3])
        end

        headings[1] = wrap_vmx(t1.blend(headings[1], headings[5], trajectory_fraction))
    end

    local v46 = v31[1]
    local v47 = v31[2]
    local v48 = v31[3]
    local v49 = if v47 > 0.9998000264167786 then 0 else atan_ratio(-v46, v48)

    headings[4] = v49
    t1.Compass.update_orbit(p23, p24, p25)
    t1.Compass.update_follow(p23, p25)

    local camera_position = p25.camera_position
    local v50 = v32[1] - camera_position[1]
    local v51 = v32[3] - camera_position[3]
    local v52 = atan_ratio(-v50, v51)
    local v53 = t1.wrap_floor(v52 - v49)

    if math.abs(v53) <= 1.2217304706573486 then
        if v53 >= 0 then
            headings[9] = v49 + 1.2217304706573486
        else
            headings[9] = v49 - 1.2217304706573486
        end
    else
        headings[9] = v52
    end

    p23.previous_reset = p24 == 0
end

function t1.Compass.update(p27, p28, p29, p30) -- line: 338
    -- upvalues: rt (copy), t1 (copy), PERF (copy)
    if PERF.reference then
        return t1.Compass.update_reference(p27, p28, p29, p30)
    end

    t1.Compass.update_headings(p27, p28, p29, p30)

    return rt.copy(p27.headings)
end

function t1.Compass.update_follow(p31, p32) -- line: 346
    -- upvalues: clamp (copy), t1 (copy), PERF (copy), length3 (copy), atan_ratio (copy)
    if PERF.reference then
        return t1.Compass.update_follow_reference(p31, p32)
    end

    local v54 = p32.transform[4]
    local camera_position = p32.camera_position
    local v55 = v54[1] - camera_position[1]
    local v56 = v54[2] - camera_position[2]
    local v57 = v54[3] - camera_position[3]
    local headings = p31.headings

    if p32.selected_compass ~= 7 then
        headings[8] = atan_ratio(-v55, v57)

        return
    end

    if p32.air_flag_452 then
        local look_target = p32.look_target
        local v58 = look_target[1] - v54[1]
        local v59 = look_target[3] - v54[3]

        headings[8] = atan_ratio(-v58, v59)
    else
        local velocity = p31.velocity
        local v60 = velocity[1]
        local v61 = velocity[3]
        local v62 = length3(v60, 0, v61)

        if v62 > 0.7 then
            local v63 = clamp((v62 - 0.7) * 0.43478259444236755, 0, 1) * 0.6
            local v64 = atan_ratio(-v60, v61)
            local v65 = if v56 > 0.9998000264167786 then 0 else atan_ratio(-v55, v57)

            headings[8] = clamp(t1.wrap_floor(v64 - v65) * 0.25, -v63, v63) + v65
        end
    end
end

function t1.CompassPoseInputs.bind_into(p33, p34, p35, p36, p37) -- line: 376
    -- upvalues: clamp (copy), v30 (copy)
    local rig = p35.rig
    local v66 = rig.trajectory_valid ~= 0
    local v67 = rig.grinding ~= 0

    if v67 then
        p33.trajectory_direction = p35.direction_424
    elseif v66 then
        p33.trajectory_direction = p34.trajectory_direction
    else
        local board_velocity = p34.board_velocity
        local trajectory_scratch = p33.trajectory_scratch
        local v68 = board_velocity[1]
        local v69 = board_velocity[2]
        local v70 = board_velocity[3]
        local v71 = board_velocity[4]
        local v72 = v68 * v68 + v69 * v69 + v70 * v70
        local v73 = 1 / math.sqrt(v72)
        local v74 = v73 * 0.5 * (-v72 * (v73 * v73) + 1) + v73
        local v75 = v74 * 0.5 * (-v72 * (v74 * v74) + 1) + v74
        local v76 = v68 * v75
        local v77 = v69 * v75
        local v78 = v70 * v75
        local v79 = v71 * v75

        trajectory_scratch[1] = v76
        trajectory_scratch[2] = v77
        trajectory_scratch[3] = v78
        trajectory_scratch[4] = v79
        p33.trajectory_direction = trajectory_scratch
    end

    p33.ground_normal = rig.last_valid_ground_up

    if v66 then
        p33.landing_normal = p35.landing_normal
    else
        p33.landing_normal = p35.ground_normal
    end

    p33.transform = rig.transform

    if v66 then
        p33.launch_position = p35.launch_position
        p33.landing_position = p35.landing_position
    else
        p33.launch_position = v30
        p33.landing_position = v30
    end

    p33.grind_direction = p35.direction_424
    p33.skeleton_direction = p34.skeleton_direction
    p33.camera_position = p36
    p33.look_target = p34.look_target
    p33.look = p35.look

    if v66 then
        p33.trajectory_fraction = clamp(p35.trajectory_time / p35.trajectory_duration, 0, 1)
    else
        p33.trajectory_fraction = 0
    end

    p33.selected_compass = p37
    p33.no_trajectory = not v66
    p33.state_103 = p34.state_103
    p33.wiping_out = rig.wiping_out ~= 0
    p33.grinding = v67
    p33.air_flag_452 = rig.air_flag_452 ~= 0

    return p33
end

function t1.CompassPoseInputs.bind_record() -- line: 420
    -- upvalues: v30 (copy)
    return {
        transform = false,
        trajectory_fraction = 0,
        selected_compass = 0,
        no_trajectory = true,
        state_103 = false,
        wiping_out = false,
        grinding = false,
        air_flag_452 = false,
        ground_normal = v30,
        landing_normal = v30,
        trajectory_direction = v30,
        launch_position = v30,
        landing_position = v30,
        grind_direction = v30,
        skeleton_direction = v30,
        camera_position = v30,
        look_target = v30,
        look = v30,
        trajectory_scratch = { 0, 0, 0, 0 }
    }
end

return t1
