-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/camera/manager_subject")
local v2 = import("skate_core/camera/tracker")

local function manager_state() -- line: 12
    -- upvalues: import (copy)
    return import("skate_core/camera/manager_state")
end

local function shot_manager() -- line: 16
    -- upvalues: import (copy)
    return import("skate_core/camera/shot_manager")
end

local ManagerSubject = v1.ManagerSubject
local ScalarTracker = v2.ScalarTracker
local t1 = {
    ManagerState = {}
}

function t1.ManagerState.update_timing(p1, p2, p3) -- line: 30
    -- upvalues: import (copy), ManagerSubject (copy)
    local v3 = import("skate_core/camera/manager_state")
    local ManagerState, STEP = v3.ManagerState, v3.STEP

    if p2.rig.trajectory_valid == 0 then
        p1.time_without_trajectory += STEP
    else
        p1.time_without_trajectory = 0
    end

    if p2.reset ~= 0 or ManagerState.reset_requested(p1) then
        p1.options = bit32.bor(p1.options, 128)
        p1.flags = bit32.band(p1.flags, 4294967291)
        p1.trajectory_camera_distance = 0
        p1.centred_time = 0
        p1.steering_time = 0
        p1.collision_elevation = 0
        p1.instant_frames = 3
        p1.anchor_velocity = { 0, 0, 0, 0 }
    end

    if math.abs(p2.steering[1]) <= p3 then
        p1.steering_time = 0
    else
        p1.steering_time += STEP
    end

    if p3 <= math.abs((ManagerSubject.steering_for_turn(p2, ManagerState.mirrored(p1)))) then
        p1.centred_time = 0
    else
        p1.centred_time += STEP
    end

    p1.flags = bit32.bor(bit32.band(p1.flags, 4294967287), (bit32.lshift(if p2.stance_592 == p2.stance_560 then 0 else 1, 3)))
end

local v9, v10
local PERF = v2.PERF

function t1.ManagerState.update_mirrors(p4, p5, p6, p7, p8) -- line: 74
    -- upvalues: import (copy), ManagerSubject (copy), ScalarTracker (copy), t1 (copy), v9 (ref), v10 (ref), PERF (copy)
    if PERF.reference then
        return t1.ManagerState.update_mirrors_reference(p4, p5, p6, p7, p8)
    end

    local v11 = import("skate_core/camera/manager_state")
    local ManagerState = v11.ManagerState
    local ShotManager = import("skate_core/camera/shot_manager").ShotManager
    local v12 = ManagerState.reset_requested(p4)

    if not (v12 or ManagerSubject.is_ground_camera(p6, p7.fields.height_mode)) then
        return
    end

    local v13 = if (if v12 then ShotManager.first_leaf(p8).mirror_for_stance else ShotManager.current(p8).shot.mirror_for_stance) == 0 or not ManagerState.mirrored(p4) then 1 else -1

    if v12 then
        local heading_mirror = p4.heading_mirror

        heading_mirror.target = v13
        heading_mirror.position = v13
        heading_mirror.velocity = 0
        heading_mirror.acceleration = 0

        local framing_mirror = p4.framing_mirror

        framing_mirror.target = v13
        framing_mirror.position = v13
        framing_mirror.velocity = 0
        framing_mirror.acceleration = 0
    else
        if v9 == nil then
            v9 = table.freeze(v11.mirror_parameters(100, 500))
            v10 = table.freeze(v11.mirror_parameters(15, 50))
        end

        ScalarTracker.update(p4.heading_mirror, p5, v13, v9)
        ScalarTracker.update(p4.framing_mirror, p5, v13, v10)
    end
end

function t1.ManagerState.update_mirrors_reference(p9, p10, p11, p12, p13) -- line: 113
    -- upvalues: import (copy), ManagerSubject (copy), ScalarTracker (copy)
    local v14 = import("skate_core/camera/manager_state")
    local ManagerState, mirror_parameters = v14.ManagerState, v14.mirror_parameters
    local ShotManager = import("skate_core/camera/shot_manager").ShotManager

    if not (ManagerState.reset_requested(p9) or ManagerSubject.is_ground_camera(p11, p12.fields.height_mode)) then
        return
    end

    local v15 = if (if ManagerState.reset_requested(p9) then ShotManager.first_leaf(p13).mirror_for_stance else ShotManager.current(p13).shot.mirror_for_stance) == 0 or not ManagerState.mirrored(p9) then 1 else -1

    if not ManagerState.reset_requested(p9) then
        ScalarTracker.update(p9.heading_mirror, p10, v15, mirror_parameters(100, 500))
        ScalarTracker.update(p9.framing_mirror, p10, v15, mirror_parameters(15, 50))

        return
    end

    for _, v16 in ipairs({
            p9.heading_mirror,
            p9.framing_mirror
        }) do
        v16.target = v15
        v16.position = v15
        v16.velocity = 0
        v16.acceleration = 0
    end
end

return t1
