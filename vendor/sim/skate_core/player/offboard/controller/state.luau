-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/player/offboard/cadence")
local v2 = import("skate_core/player/offboard/movement_intent")
local v3 = import("skate_core/player/offboard/surface_frame")
local v4 = import("skate_core/player/offboard/controller/placement")
local BipedCadence, CadenceThresholds = v1.BipedCadence, v1.CadenceThresholds
local t1 = {}

t1.ZERO = { 0, 0, 0, 0 }
t1.UP = { 0, 1, 0, 0 }
t1.IDENTITY = {
    { 1, 0, 0, 0 },
    { 0, 1, 0, 0 },
    { 0, 0, 1, 0 },
    { 0, 0, 0, 0 }
}

local ZERO, IDENTITY = t1.ZERO, t1.IDENTITY

t1.ClipMetric = {}

function t1.ClipMetric.speed(p1) -- line: 32
    return -1 / p1.end_time * p1.translation_z
end

t1.State = {}

local reset_motion

function t1.State.new(p2) -- line: 50
    -- upvalues: rt (copy), v2 (copy), v3 (copy), t1 (copy), BipedCadence (copy), CadenceThresholds (copy), ZERO (copy), IDENTITY (copy), reset_motion (ref)
    local v5 = table.create(3)

    for i = 1, 3 do
        local v6 = p2[i]

        if v6 ~= nil then
            v5[i] = t1.ClipMetric.speed(v6)
        else
            v5[i] = 0
        end
    end

    return {
        forward_delta_692 = 0,
        right_delta_696 = 0,
        velocity_override_remaining_772 = -1,
        alternate_709 = false,
        motion = reset_motion(ZERO),
        intent = v2.State.default(),
        surface = v3.State.default(),
        contact = {
            active = false,
            direction = rt.copy(ZERO),
            displacement = rt.copy(ZERO)
        },
        special = {
            enabled_714 = false,
            elapsed_788 = 0
        },
        sliding = {
            active_710 = false,
            velocity_528 = rt.copy(ZERO)
        },
        frame_output = {
            frame = rt.copy(IDENTITY),
            velocity = rt.copy(ZERO)
        },
        cadence = BipedCadence.default(),
        thresholds = CadenceThresholds.from_clip_speeds(v5[1], v5[2], v5[3]),
        position_368 = rt.copy(ZERO),
        correction_target_592 = rt.copy(ZERO)
    }
end

function t1.State.reset(p3) -- line: 93
    -- upvalues: rt (copy), v2 (copy), v3 (copy), ZERO (copy), IDENTITY (copy), reset_motion (ref)
    p3.motion = reset_motion(p3.motion.correction_576)
    p3.intent = v2.State.default()
    p3.surface = v3.State.default()
    p3.contact = {
        active = false,
        direction = rt.copy(ZERO),
        displacement = rt.copy(ZERO)
    }
    p3.special = {
        enabled_714 = false,
        elapsed_788 = 0
    }
    p3.sliding = {
        active_710 = false,
        velocity_528 = rt.copy(ZERO)
    }
    p3.frame_output = {
        frame = rt.copy(IDENTITY),
        velocity = rt.copy(ZERO)
    }
    p3.position_368 = rt.copy(ZERO)
    p3.forward_delta_692 = 0
    p3.right_delta_696 = 0
    p3.velocity_override_remaining_772 = -1
    p3.alternate_709 = false
end

function t1.reset_motion(p4) -- line: 122
    -- upvalues: rt (copy), ZERO (copy), IDENTITY (copy)
    return {
        support_yaw_336 = 0,
        previous_support_yaw_340 = 0,
        predicted_support_yaw_344 = 0,
        support_speed_348 = 0,
        support_id_352 = 0,
        angular_velocity_688 = 0,
        speed_704 = 0,
        correction_enabled_711 = false,
        support_velocity_removed_715 = false,
        target_scale_784 = -1,
        frame_0 = rt.copy(IDENTITY),
        published_frame_64 = rt.copy(IDENTITY),
        previous_support_frame_192 = rt.copy(IDENTITY),
        support_velocity_256 = rt.copy(ZERO),
        predicted_support_velocity_272 = rt.copy(ZERO),
        previous_support_velocity_288 = rt.copy(ZERO),
        support_acceleration_304 = rt.copy(ZERO),
        filtered_local_acceleration_320 = rt.copy(ZERO),
        velocity_480 = rt.copy(ZERO),
        correction_576 = rt.copy(p4),
        target_frame_608 = rt.copy(IDENTITY)
    }
end

reset_motion = t1.reset_motion

for v7, v8 in v4.State do
    t1.State[v7] = v8
end

return t1
