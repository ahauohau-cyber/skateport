-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/camera/manager_subject")
local v2 = import("skate_core/camera/direction")
local v3 = import("skate_core/camera/angle_tracker")
local v4 = import("skate_core/camera/vector_tracker")
local v5 = import("skate_core/trigonometry")

local function manager_state() -- line: 15
    -- upvalues: import (copy)
    return import("skate_core/camera/manager_state")
end

local ManagerSubject = v1.ManagerSubject
local direction_to_angles = v2.direction_to_angles
local normalize_angle = v3.normalize_angle
local dot, length = v4.dot, v4.length
local t1 = {
    ManagerState = {}
}

function t1.ManagerState.update_air_reference(p1, p2, p3) -- line: 35
    -- upvalues: rt (copy), import (copy), v5 (copy), ManagerSubject (copy), dot (copy), length (copy), t1 (copy)
    local clamp = import("skate_core/camera/manager_state").clamp
    local landing_height_delta = p1.landing_height_delta

    p1.landing_height_delta = p2.landing_position[2] - p2.launch_position[2]
    p1.apex_height = p2.apex_position[2] - p2.launch_position[2]
    p1.apex_time = p2.apex_time
    p1.launch_position = rt.copy(p2.launch_position)

    if p1.trajectory_camera_distance == 0 then
        p1.apex_height_ratio = 0
    else
        p1.apex_height_ratio = p1.apex_height / p1.trajectory_camera_distance
    end

    p1.landing_normal = rt.copy(p2.landing_normal)
    p1.launch_incline = v5.acos(clamp(p2.launch_normal[2], -1, 1))
    p1.flags = bit32.band(p1.flags, 4294967279)

    local v6 = ManagerSubject.is_ground_camera(p2, p3.fields.height_mode)

    if v6 or p2.rig.trajectory_valid == 0 then
        p1.flags = bit32.band(p1.flags, 4294967291)
    else
        if bit32.band(p1.flags, 4) == 0 then
            local position = p2.anchors[p1.selected_anchor + 1].position

            p1.trajectory_camera_distance = length({
                p3.positioner.position[1] - position[1],
                p3.positioner.position[2] - position[2],
                p3.positioner.position[3] - position[3],
                p3.positioner.position[4] - position[4]
            })
            p3.fields.flags_517 = bit32.band(p3.fields.flags_517, 4294967287)
        elseif math.abs(p1.landing_height_delta - landing_height_delta) > 0.0010000000474974513 then
            p3.fields.flags_517 = bit32.bor(p3.fields.flags_517, 8)
        end

        p1.flags = bit32.bor(p1.flags, 4)
        p1.landing_incline = v5.acos(clamp(p1.landing_normal[2], -1, 1))
        p1.signed_landing_incline = p1.landing_incline

        if dot(p2.rig.transform[3], p1.landing_normal) > 0 then
            p1.signed_landing_incline = -p1.landing_incline
        end

        if p1.launch_incline > 1.2217304706573486 and p1.landing_incline > 0.5235987901687622 then
            p1.flags = bit32.bor(p1.flags, 16)
        end

        t1.ManagerState.update_slope_relation(p1, p2)
    end

    if v6 or p2.rig.trajectory_valid == 0 then
        p3.fields.height_transition_weight = 0
    else
        p3.fields.height_transition_weight = clamp(p2.trajectory_time / p2.trajectory_duration, 0, 1)
    end

    local t2

    if v6 then
        local flags = p1.flags

        if bit32.band(flags, 64) == 0 and bit32.band(p3.positioner.flags, 128) == 0 then
            t2 = if dot(p1.previous_velocity, p1.ground_normal) < -0 then {
                rt.copy(p1.ground_normal),
                rt.copy(p1.previous_velocity)
            } else nil
            p1.landing_height_delta = 0
        end
    elseif p3.fields.height_transition_time >= p3.fields.height_transition_duration and p2.rig.trajectory_valid ~= 0 and p1.landing_height_delta > -3 and p2.flag_684 == 0 then
        if bit32.band(p1.flags, 2) ~= 0 or p2.rig.air_flag_452 ~= 0 then
            p3.fields.flags_516 = bit32.bor(p3.fields.flags_516, 64)
        elseif p3.fields.previous_height ~= rt.F32_MAX and p3.fields.reference_height ~= rt.F32_MAX then
            p3.fields.height_transition_start = p3.fields.reference_height
            p3.fields.height_transition_end = p1.landing_height_delta + p3.fields.reference_height
            p3.fields.height_transition_duration = p2.trajectory_duration - p2.trajectory_time
            p3.fields.height_transition_time = 0
        end
    end

    p1.flags = bit32.bor(bit32.band(p1.flags, 4294967231), (bit32.lshift(if v6 then 1 else 0, 6)))
    p1.previous_velocity = rt.copy(p3.fields.velocity)

    return t2
end

function t1.ManagerState.update_slope_relation_reference(p4, p5) -- line: 112
    -- upvalues: direction_to_angles (copy), normalize_angle (copy)
    p4.launch_landing_heading_delta = 3.1415927410125732

    if p5.launch_normal[2] < 0.9900000095367432 and p5.landing_normal[2] < 0.9900000095367432 then
        local v11 = normalize_angle(direction_to_angles(p5.launch_normal)[2])

        p4.launch_landing_heading_delta = math.abs((normalize_angle(normalize_angle(direction_to_angles(p5.landing_normal)[2]) - v11)))
    end
end

local PERF = import("skate_core/camera/tracker").PERF
local length3 = v4.length3
local direction_heading = v2.direction_heading

function t1.ManagerState.update_slope_relation(p6, p7) -- line: 141
    -- upvalues: normalize_angle (copy), t1 (copy), PERF (copy), direction_heading (copy)
    if PERF.reference then
        return t1.ManagerState.update_slope_relation_reference(p6, p7)
    end

    p6.launch_landing_heading_delta = 3.1415927410125732

    local launch_normal, landing_normal = p7.launch_normal, p7.landing_normal

    if launch_normal[2] < 0.9900000095367432 and landing_normal[2] < 0.9900000095367432 then
        local v14 = normalize_angle(direction_heading(launch_normal[1], launch_normal[3]))

        p6.launch_landing_heading_delta = math.abs((normalize_angle(normalize_angle(direction_heading(landing_normal[1], landing_normal[3])) - v14)))
    end
end

function t1.ManagerState.update_air(p8, p9, p10) -- line: 154
    -- upvalues: rt (copy), import (copy), v5 (copy), ManagerSubject (copy), t1 (copy), PERF (copy), length3 (copy)
    if PERF.reference then
        return t1.ManagerState.update_air_reference(p8, p9, p10)
    end

    local clamp = import("skate_core/camera/manager_state").clamp
    local fields = p10.fields
    local rig, launch_position, landing_normal = p9.rig, p9.launch_position, p9.landing_normal
    local landing_height_delta = p8.landing_height_delta

    p8.landing_height_delta = p9.landing_position[2] - launch_position[2]
    p8.apex_height = p9.apex_position[2] - launch_position[2]
    p8.apex_time = p9.apex_time

    local launch_position2 = p8.launch_position
    local v17 = launch_position[1]
    local v18 = launch_position[2]
    local v19 = launch_position[3]
    local v20 = launch_position[4]

    launch_position2[1] = v17
    launch_position2[2] = v18
    launch_position2[3] = v19
    launch_position2[4] = v20

    if p8.trajectory_camera_distance == 0 then
        p8.apex_height_ratio = 0
    else
        p8.apex_height_ratio = p8.apex_height / p8.trajectory_camera_distance
    end

    local landing_normal2 = p8.landing_normal
    local v21 = landing_normal[1]
    local v22 = landing_normal[2]
    local v23 = landing_normal[3]
    local v24 = landing_normal[4]

    landing_normal2[1] = v21
    landing_normal2[2] = v22
    landing_normal2[3] = v23
    landing_normal2[4] = v24
    p8.launch_incline = v5.acos(clamp(p9.launch_normal[2], -1, 1))
    p8.flags = bit32.band(p8.flags, 4294967279)

    local v25 = ManagerSubject.is_ground_camera(p9, fields.height_mode)

    if v25 or rig.trajectory_valid == 0 then
        p8.flags = bit32.band(p8.flags, 4294967291)
    else
        if bit32.band(p8.flags, 4) == 0 then
            local position = p9.anchors[p8.selected_anchor + 1].position
            local position2 = p10.positioner.position

            p8.trajectory_camera_distance = length3(position2[1] - position[1], position2[2] - position[2], position2[3] - position[3])
            fields.flags_517 = bit32.band(fields.flags_517, 4294967287)
        elseif math.abs(p8.landing_height_delta - landing_height_delta) > 0.0010000000474974513 then
            fields.flags_517 = bit32.bor(fields.flags_517, 8)
        end

        p8.flags = bit32.bor(p8.flags, 4)
        p8.landing_incline = v5.acos(clamp(v22, -1, 1))
        p8.signed_landing_incline = p8.landing_incline

        local v27 = rig.transform[3]

        if v27[1] * v21 + v27[2] * v22 + v27[3] * v23 > 0 then
            p8.signed_landing_incline = -p8.landing_incline
        end

        if p8.launch_incline > 1.2217304706573486 and p8.landing_incline > 0.5235987901687622 then
            p8.flags = bit32.bor(p8.flags, 16)
        end

        t1.ManagerState.update_slope_relation(p8, p9)
    end

    if v25 or rig.trajectory_valid == 0 then
        fields.height_transition_weight = 0
    else
        fields.height_transition_weight = clamp(p9.trajectory_time / p9.trajectory_duration, 0, 1)
    end

    local previous_velocity = p8.previous_velocity
    local t4

    if v25 then
        local flags = p8.flags

        if bit32.band(flags, 64) == 0 and bit32.band(p10.positioner.flags, 128) == 0 then
            local ground_normal = p8.ground_normal

            t4 = if previous_velocity[1] * ground_normal[1] + previous_velocity[2] * ground_normal[2] + previous_velocity[3] * ground_normal[3] < -0 then {
                rt.copy(ground_normal),
                rt.copy(previous_velocity)
            } else nil
            p8.landing_height_delta = 0
        end
    elseif fields.height_transition_time >= fields.height_transition_duration and rig.trajectory_valid ~= 0 and p8.landing_height_delta > -3 and p9.flag_684 == 0 then
        if bit32.band(p8.flags, 2) ~= 0 or rig.air_flag_452 ~= 0 then
            fields.flags_516 = bit32.bor(fields.flags_516, 64)
        elseif fields.previous_height ~= rt.F32_MAX and fields.reference_height ~= rt.F32_MAX then
            fields.height_transition_start = fields.reference_height
            fields.height_transition_end = p8.landing_height_delta + fields.reference_height
            fields.height_transition_duration = p9.trajectory_duration - p9.trajectory_time
            fields.height_transition_time = 0
        end
    end

    p8.flags = bit32.bor(bit32.band(p8.flags, 4294967231), (bit32.lshift(if v25 then 1 else 0, 6)))

    local velocity = fields.velocity
    local v31 = velocity[1]
    local v32 = velocity[2]
    local v33 = velocity[3]
    local v34 = velocity[4]

    previous_velocity[1] = v31
    previous_velocity[2] = v32
    previous_velocity[3] = v33
    previous_velocity[4] = v34

    return t4
end

return t1
