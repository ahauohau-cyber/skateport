-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/camera/manager_state")
local v2 = import("skate_core/camera/manager_subject")
local v3 = import("skate_core/camera/vector_tracker")
local ManagerState = v1.ManagerState
local ManagerSubject = v2.ManagerSubject
local DEGREES, clamp = v1.DEGREES, v1.clamp
local dot = v3.dot
local t1 = {
    BlendEnvironment = {}
}

function t1.BlendEnvironment.heading_mirror(p1) -- line: 32
    return p1.heading_multiplier
end

function t1.BlendEnvironment.compass_north(p2, p3) -- line: 36
    return p2.subject.compass[p3 + 1]
end

function t1.BlendEnvironment.special_camera_flag(p4) -- line: 40
    return bit32.band(p4.state.flags, 16) ~= 0
end

function t1.BlendEnvironment.raw_blend_value(p5, p6, p7, p8) -- line: 44
    -- upvalues: rt (copy), ManagerState (copy), ManagerSubject (copy), DEGREES (copy), dot (copy), t1 (copy)
    local subject, state = p5.subject, p5.state

    if p6 == 0 then
        return p7
    end

    if p6 == 1 then
        return (math.abs((dot(p5.rig.fields.velocity, subject.rig.transform[3]))))
    end

    if p6 == 2 then
        return dot(p5.rig.fields.acceleration, p5.rig_forward)
    end

    if p6 == 3 then
        return p5.heading_multiplier * -p5.angular_velocity[2]
    end

    if p6 == 4 then
        return state.apex_height
    end

    if p6 == 5 then
        return t1.BlendEnvironment.air_progress(p5)
    end

    if p6 == 6 then
        return state.velocity_incline * DEGREES
    end

    if p6 == 7 then
        return p5.previous_distance
    end

    if p6 == 8 then
        return t1.BlendEnvironment.apex_progress(p5)
    end

    if p6 == 9 then
        return state.absolute_velocity_incline * DEGREES
    end

    if p6 == 10 then
        return state.landing_incline * DEGREES
    end

    if p6 == 11 then
        if ManagerState.mirrored(state) then
            return -subject.steering[2]
        end

        return subject.steering[2]
    end

    if p6 == 12 then
        return ManagerSubject.steering_for_blend(subject, ManagerState.mirrored(state))
    end

    if p6 == 13 then
        if p8 == 0 then
            return 0
        end

        return ManagerSubject.steering_for_turn(subject, ManagerState.mirrored(state))
    end

    if p6 == 14 then
        if p8 == 0 then
            return 0
        end

        return rt.F32_MAX
    end

    if p6 == 15 then
        return state.frontside_angle
    end

    if p6 == 16 then
        return ManagerSubject.valid_trajectory_duration(subject)
    end

    if p6 == 17 then
        return subject.look[1]
    end

    if p6 == 18 then
        return subject.look[2]
    end

    if p6 == 19 then
        return ManagerSubject.look_heading(subject)
    end

    if p6 == 20 then
        return state.direction_incline * DEGREES
    end

    if p6 == 21 then
        return subject.value_512
    end

    if p6 == 22 then
        return -subject.value_516
    end

    if p6 == 23 then
        return state.effect_weight
    end

    return 0.5
end

function t1.BlendEnvironment.air_progress(p9) -- line: 112
    -- upvalues: ManagerSubject (copy), clamp (copy)
    local subject = p9.subject

    if ManagerSubject.is_ground_camera(subject, p9.rig.fields.height_mode) then
        return 1
    end

    if p9.state.apex_height <= 0 then
        return 0
    end

    local v5 = subject.trajectory_duration - subject.trajectory_time

    return clamp(if subject.trajectory_duration <= 0 then 1 else (subject.trajectory_duration - v5) / subject.trajectory_duration, 0, 1)
end

function t1.BlendEnvironment.apex_progress(p10) -- line: 130
    -- upvalues: ManagerSubject (copy), clamp (copy)
    local subject, state = p10.subject, p10.state

    if ManagerSubject.is_ground_camera(subject, p10.rig.fields.height_mode) then
        if bit32.band(state.flags, 64) == 0 then
            return 1
        end

        return 0
    end

    if state.apex_height <= 0 or ManagerSubject.valid_trajectory_duration(subject) < state.apex_time then
        return 0
    end

    local v7 = state.apex_time * 2
    local v8 = ManagerSubject.valid_trajectory_duration(subject) - v7

    if v7 < subject.trajectory_time then
        return clamp((subject.trajectory_time - v7) / v8 + 1, 1, 2)
    end

    return subject.trajectory_time / v7
end

return t1
