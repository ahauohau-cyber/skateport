-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/camera/manager_subject")
local v2 = import("skate_core/camera/direction")
local v3 = import("skate_core/camera/vector_tracker")
local v4 = import("skate_core/camera/rig_tracking")
local v5 = import("skate_core/trigonometry")
local v6 = import("skate_core/physics/rigid_body")

local function manager_state() -- line: 16
    -- upvalues: import (copy)
    return import("skate_core/camera/manager_state")
end

local function rig_mod() -- line: 21
    -- upvalues: import (copy)
    return import("skate_core/camera/rig")
end

local ManagerSubject = v1.ManagerSubject
local length = v3.length
local t1 = {
    ManagerState = {}
}

function t1.ManagerState.bind_shot_reference(p1, p2, p3, p4, p5, p6, p7, p8, p9) -- line: 35
    -- upvalues: import (copy), v2 (copy), v4 (copy), v5 (copy), v6 (copy), ManagerSubject (copy), length (copy)
    local v7 = import("skate_core/camera/manager_state")
    local clamp = v7.clamp
    local v8 = v7.ManagerState.reset_requested(p1)

    p4.fields.avoidance_mode = bit32.band(p1.options, 32) == 0 and 0 or 1
    p4.fields.flags_516 = bit32.bor(bit32.band(p4.fields.flags_516, 4294967197), bit32.lshift(if p9 then 1 else 0, 5), bit32.band(bit32.lshift(p2.follow_subject_in_air, 6), 64), (bit32.band(bit32.lshift(p2.avoidance_override, 1), 2)))
    p4.fields.flags_517 = bit32.bor(bit32.band(p4.fields.flags_517, 127), (bit32.band(bit32.lshift(p3.stance_560, 7), 255)))

    local v19 = p2.arm_orientation[1]
    local v20 = p2.arm_orientation[2]
    local v21 = p2.arm_orientation[3]
    local v22 = p2.arm_orientation[4]
    local v23 = v6.basis_from_quaternion({
        x = v19,
        y = v20,
        z = v21,
        w = v22
    }).columns[3]
    local v24 = v2.direction_to_angles({
        v23[1],
        v23[2],
        v23[3],
        0
    })
    local v25 = -v24[1]
    local v26 = v24[2]
    local distance = p2.distance

    if p3.special_effect ~= 0 then
        v25 += 0.3490658402442932

        local v27 = p1.frames * 0.10471975803375244
        local v28 = v5.sin(v27 * 0.043478261679410934)

        v26 = v5.sin(v27 * 0.009999999776482582) * 2.6179938316345215 + v26
        distance = v28 + distance + 1
    end

    local options2 = p1.options
    local v29, v30

    if bit32.band(options2, 64) == 0 then
        v29 = distance
        v30 = 0
    else
        local v31 = length(p1.anchor_velocity)
        local options = p1.options
        local v32, v33

        if bit32.band(options, 16) == 0 then
            v33 = 0.9
            v32 = 1
        else
            v33 = 0.7
            v32 = 0.8
        end

        local v34 = clamp(-((v31 - 4) * 0.025000005960464478 + -v32), v33, v32)

        v30 = p6.elevation * v34
        v29 = p6.distance_offset + distance
    end

    local v35

    if v8 then
        v35 = 0
    else
        local v36 = if v29 - 2.5 >= 0 then 2.5 else v29
        local v37 = clamp((v36 - p4.positioner.available_distance) / v36, 0, 1)
        local v38 = (if p3.rig.off_board == 0 then 50 else 60) * 0.01745329238474369
        local v39 = v38 * v37 + -v30

        if not (v39 >= 0) then
            v39 = 0
        end

        if ManagerSubject.is_ground_camera(p3, p4.fields.height_mode) and p3.ground_normal[2] < -0.2 then
            v39 *= -1
        end

        local v40 = v38 * (if v39 > 0 and p1.collision_elevation < v39 or v39 < 0 and v39 < p1.collision_elevation then 0.06666667014360428 else 0.009999999776482582)

        if v40 < math.abs(v39 - p1.collision_elevation) then
            if p1.collision_elevation <= v39 then
                p1.collision_elevation += v40
            else
                p1.collision_elevation -= v40
            end
        else
            p1.collision_elevation = v39
        end

        v35 = clamp(p1.collision_elevation, -1.3962633609771729, 1.3962633609771729)
    end

    p4.fields.distance = v29

    local v43 = -(math.floor(v26 * 0.15915493667125702 + 0.5) * 6.2831854820251465 + -v26)

    p4.fields.heading_reference = v43

    if v8 then
        p4.fields.heading_target = v43
    else
        local avoidance_heading = p4.fields.avoidance_heading
        local v44 = v4.wrap_vmx(v43 - avoidance_heading)

        p4.fields.heading_target = v4.wrap_vmx(v44 * (1 - p4.fields.heading_weight) + avoidance_heading)
    end

    import("skate_core/camera/rig").Rig.set_elevation(p4, v25, not v8)
    p4.fields.elevation_offset = v30 + p7.elevation
    p4.fields.additional_elevation = v35
    p4.fields.flags_517 = bit32.bor(bit32.band(p4.fields.flags_517, 4294967263), (bit32.lshift(if p2.compass_north == 5 then 0 else 1, 5)))

    if v8 then
        p1.blur = 0
    elseif p9 then
        p1.blur = p2.transition_blur
    else
        p1.blur = p2.blur
    end

    local v48 = if p2.compass_north == 2 then 1 else p1.heading_mirror.position

    if p2.compass_north == 2 then
        p5.framing_mirror = 1
    else
        p5.framing_mirror = p1.framing_mirror.position
    end

    p4.fields.collision_mode = p2.collision_hint

    local v49 = 1 - p2.smoothing[1]
    local v50 = 1 - p2.smoothing[2]
    local v51 = 1 - p2.smoothing[3]
    local v52 = 1 - p2.smoothing[4]

    p4.fields.heading_smoothing = 1 - -(v49 * v49 + -1)
    p4.fields.elevation_smoothing = 1 - -(v50 * v50 + -1)
    p5.pan_smoothing = -(v51 * v51 + -1)
    p5.tilt_smoothing = -(v52 * v52 + -1)
    p5.roll = p8

    return v48
end

local PERF = import("skate_core/camera/tracker").PERF
local length3 = v3.length3
local direction_to_angles_lanes = v2.direction_to_angles_lanes
local wrap_vmx = v4.wrap_vmx
local quaternion_at_lanes = import("skate_core/camera/orientation_math").quaternion_at_lanes

function t1.ManagerState.bind_shot(p10, p11, p12, p13, p14, p15, p16, p17, p18) -- line: 178
    -- upvalues: import (copy), v5 (copy), ManagerSubject (copy), t1 (copy), PERF (copy), length3 (copy), direction_to_angles_lanes (copy), wrap_vmx (copy), quaternion_at_lanes (copy)
    if PERF.reference then
        return t1.ManagerState.bind_shot_reference(p10, p11, p12, p13, p14, p15, p16, p17, p18)
    end

    local v53 = import("skate_core/camera/manager_state")
    local clamp = v53.clamp
    local v54 = v53.ManagerState.reset_requested(p10)
    local fields = p13.fields

    fields.avoidance_mode = bit32.band(p10.options, 32) == 0 and 0 or 1
    fields.flags_516 = bit32.bor(bit32.band(fields.flags_516, 4294967197), bit32.lshift(if p18 then 1 else 0, 5), bit32.band(bit32.lshift(p11.follow_subject_in_air, 6), 64), (bit32.band(bit32.lshift(p11.avoidance_override, 1), 2)))
    fields.flags_517 = bit32.bor(bit32.band(fields.flags_517, 127), (bit32.band(bit32.lshift(p12.stance_560, 7), 255)))

    local arm_orientation = p11.arm_orientation
    local v65, v66 = direction_to_angles_lanes(quaternion_at_lanes(arm_orientation[1], arm_orientation[2], arm_orientation[3], arm_orientation[4]))
    local v67 = -v65
    local distance = p11.distance

    if p12.special_effect ~= 0 then
        v67 += 0.3490658402442932

        local v68 = p10.frames * 0.10471975803375244
        local v69 = v5.sin(v68 * 0.043478261679410934)

        v66 = v5.sin(v68 * 0.009999999776482582) * 2.6179938316345215 + v66
        distance = v69 + distance + 1
    end

    local options2 = p10.options
    local v70, v71

    if bit32.band(options2, 64) == 0 then
        v70 = distance
        v71 = 0
    else
        local anchor_velocity = p10.anchor_velocity
        local v72 = length3(anchor_velocity[1], anchor_velocity[2], anchor_velocity[3])
        local options = p10.options
        local v73, v74

        if bit32.band(options, 16) == 0 then
            v74 = 0.9
            v73 = 1
        else
            v74 = 0.7
            v73 = 0.8
        end

        local v75 = clamp(-((v72 - 4) * 0.025000005960464478 + -v73), v74, v73)

        v71 = p15.elevation * v75
        v70 = p15.distance_offset + distance
    end

    local v76

    if v54 then
        v76 = 0
    else
        local v77 = if v70 - 2.5 >= 0 then 2.5 else v70
        local v78 = clamp((v77 - p13.positioner.available_distance) / v77, 0, 1)
        local v79 = (if p12.rig.off_board == 0 then 50 else 60) * 0.01745329238474369
        local v80 = v79 * v78 + -v71

        if not (v80 >= 0) then
            v80 = 0
        end

        if ManagerSubject.is_ground_camera(p12, fields.height_mode) and p12.ground_normal[2] < -0.2 then
            v80 *= -1
        end

        local v81 = v79 * (if v80 > 0 and p10.collision_elevation < v80 or v80 < 0 and v80 < p10.collision_elevation then 0.06666667014360428 else 0.009999999776482582)

        if v81 < math.abs(v80 - p10.collision_elevation) then
            if p10.collision_elevation <= v80 then
                p10.collision_elevation += v81
            else
                p10.collision_elevation -= v81
            end
        else
            p10.collision_elevation = v80
        end

        v76 = clamp(p10.collision_elevation, -1.3962633609771729, 1.3962633609771729)
    end

    fields.distance = v70

    local v84 = -(math.floor(v66 * 0.15915493667125702 + 0.5) * 6.2831854820251465 + -v66)

    fields.heading_reference = v84

    if v54 then
        fields.heading_target = v84
    else
        local avoidance_heading = fields.avoidance_heading

        fields.heading_target = wrap_vmx(wrap_vmx(v84 - avoidance_heading) * (1 - fields.heading_weight) + avoidance_heading)
    end

    import("skate_core/camera/rig").Rig.set_elevation(p13, v67, not v54)
    fields.elevation_offset = v71 + p16.elevation
    fields.additional_elevation = v76
    fields.flags_517 = bit32.bor(bit32.band(fields.flags_517, 4294967263), (bit32.lshift(if p11.compass_north == 5 then 0 else 1, 5)))

    if v54 then
        p10.blur = 0
    elseif p18 then
        p10.blur = p11.transition_blur
    else
        p10.blur = p11.blur
    end

    local v89

    if p11.compass_north == 2 then
        v89 = 1
        p14.framing_mirror = 1
    else
        v89 = p10.heading_mirror.position
        p14.framing_mirror = p10.framing_mirror.position
    end

    fields.collision_mode = p11.collision_hint

    local smoothing = p11.smoothing
    local v90 = 1 - smoothing[1]
    local v91 = 1 - smoothing[2]
    local v92 = 1 - smoothing[3]
    local v93 = 1 - smoothing[4]

    fields.heading_smoothing = 1 - -(v90 * v90 + -1)
    fields.elevation_smoothing = 1 - -(v91 * v91 + -1)
    p14.pan_smoothing = -(v92 * v92 + -1)
    p14.tilt_smoothing = -(v93 * v93 + -1)
    p14.roll = p17

    return v89
end

return t1
