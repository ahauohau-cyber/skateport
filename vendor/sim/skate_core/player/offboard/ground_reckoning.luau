-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/air/body_spin")
local GroundNormalFilter = import("skate_core/air/ground_normal").GroundNormalFilter
local Vector3 = import("skate_core/math").Vector3
local _ = import("skate_core/point_graph").PointGraph
local ReckoningFrames = import("skate_core/riding/reckoning_frames").ReckoningFrames
local v2 = import("skate_core/physics/native_arithmetic")
local v3 = import("skate_core/player/offboard/contact_correction")
local t1 = {
    Settings = {},
    Input = {},
    Output = {}
}

function t1.update(p1, p2, p3, p4, p5, p6) -- line: 51
    -- upvalues: rt (copy), v1 (copy), GroundNormalFilter (copy), Vector3 (copy), ReckoningFrames (copy), v2 (copy), v3 (copy), t1 (copy)
    p1.dynamic_up = t1.xyz(p6.previous_up)
    p2.target_lean_angle = 0
    p4.secondary_lean_angle = 0
    p1.up_velocity = rt.copy(Vector3.ZERO)

    local v4 = GroundNormalFilter.update(p1.ground_filter, p5.ground_normal_smoothing, p6.requested_up)

    p1.ground_normal = t1.xyz(v4)
    p2.heading = rt.copy(p6.requested_forward)

    local v5 = 1 - p6.blend
    local t2 = {
        p6.previous_up[1] * p6.blend + p6.requested_up[1] * v5,
        p6.previous_up[2] * p6.blend + p6.requested_up[2] * v5,
        p6.previous_up[3] * p6.blend + p6.requested_up[3] * v5,
        p6.previous_up[4] * p6.blend + p6.requested_up[4] * v5
    }
    local v6 = v2.dot3(t2, t2)
    local v7 = v3.inverse_length(v6)
    local v8 = if (if v6 == 0 then 0 else v6 * v7) > 9.999999974752427E-07 then {
        t2[1] * v7,
        t2[2] * v7,
        t2[3] * v7,
        t2[4] * v7
    } else rt.copy(p6.previous_up)

    p1.up = t1.xyz(v8)
    p1.target = t1.xyz(v8)
    GroundNormalFilter.filter(p1.slow_filter, v8)
    GroundNormalFilter.filter(p1.fast_filter, v8)
    GroundNormalFilter.publish_current(p1.slow_filter, v8)
    GroundNormalFilter.publish_current(p1.fast_filter, v8)
    ReckoningFrames.calculate_transform(p2, v8, v4)
    ReckoningFrames.calculate_tilt(p2, p6.reverse_stance, p5.tilt_vs_rotation, p5.tilt_vs_slope)
    v1.update_ground(p3, if p6.enable_body_spin_input then p6.physical_body_spin_2812 else 0)

    return {
        dynamic_up_1136 = rt.copy(p6.previous_up),
        up_1152 = rt.copy(v8),
        target_1168 = rt.copy(v8),
        velocity_1184 = table.create(4, 0),
        ground_normal_1216 = rt.copy(v4)
    }
end

function t1.xyz(p7) -- line: 94
    -- upvalues: Vector3 (copy)
    return Vector3.new(p7[1], p7[2], p7[3])
end

return t1
