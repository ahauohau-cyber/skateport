-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/camera/manager_controls")
local v2 = import("skate_core/camera/manager_incline")
local v3 = import("skate_core/camera/manager_air")
local v4 = import("skate_core/camera/manager_rig")
local t1 = {
    STEP = 0.01666666753590107,
    HALF_PI = 1.5707963705062866,
    DEGREES = 57.295780181884766,
    UP = { 0, 1, 0, 0 },
    ManagerState = {}
}

function t1.ManagerState.new() -- line: 64
    -- upvalues: rt (copy), t1 (copy)
    return {
        anchor = { 0, 0, 0, 0 },
        anchor_velocity = { 0, 0, 0, 0 },
        landing_normal = rt.copy(t1.UP),
        launch_position = { 0, 0, 0, 0 },
        ground_normal = rt.copy(t1.UP),
        previous_velocity = { 0, 0, 0, 0 },
        incline_normal = { 0, 0, 0, 0 },
        selected_anchor = 0,
        frontside_angle = 0,
        ground_heading = 0,
        velocity_incline = 0,
        absolute_velocity_incline = 0,
        launch_incline = 0,
        signed_landing_incline = 0,
        landing_incline = 0,
        direction_incline = 0,
        field_of_view = 0,
        apex_height = 0,
        apex_time = 0,
        time_without_trajectory = rt.F32_MAX,
        landing_height_delta = 0,
        apex_height_ratio = 0,
        launch_landing_heading_delta = 0,
        trajectory_camera_distance = 0,
        steering_time = 0,
        centred_time = 0,
        opacity = 1,
        aspect_ratio = 1.7777777910232544,
        blur = 1,
        effect_weight = 1,
        collision_elevation = 0,
        frames = 0,
        slowmo_frames = 0,
        instant_frames = 3,
        flags = 2,
        options = 96,
        heading_mirror = t1.mirror_tracker(),
        framing_mirror = t1.mirror_tracker()
    }
end

function t1.ManagerState.reset_requested(p1) -- line: 107
    return bit32.band(p1.options, 128) ~= 0
end

function t1.ManagerState.request_reset(p2) -- line: 111
    p2.options = bit32.bor(p2.options, 128)
end

function t1.ManagerState.mirrored(p3) -- line: 115
    return bit32.band(p3.flags, 8) ~= 0
end

function t1.clamp(p4, p5, p6) -- line: 119
    local v5 = if p5 - p4 >= 0 then p5 else p4

    if p6 - v5 >= 0 then
        return v5
    end

    return p6
end

function t1.mirror_tracker() -- line: 124
    return {
        target = 1,
        position = 1,
        velocity = 0,
        acceleration = 0,
        acceleration_clamp = 0,
        smoothing = 0
    }
end

function t1.mirror_parameters(p7, p8) -- line: 135
    return {
        delta_umbra = 0,
        delta_penumbra = 0,
        smoothing_min = 0.85,
        smoothing_max = 0.85,
        overshoot_zeroes_velocity = true,
        speed_clamp = p7,
        acceleration_clamp_min = p8,
        acceleration_clamp_max = p8
    }
end

for v6, v7 in v1.ManagerState do
    t1.ManagerState[v6] = v7
end

for v8, v9 in v2.ManagerState do
    t1.ManagerState[v8] = v9
end

for v10, v11 in v3.ManagerState do
    t1.ManagerState[v10] = v11
end

for v12, v13 in v4.ManagerState do
    t1.ManagerState[v12] = v13
end

return t1
