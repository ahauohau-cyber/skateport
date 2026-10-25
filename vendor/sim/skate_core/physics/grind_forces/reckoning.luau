-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/grind_forces")
local v2 = import("skate_core/air/body_spin")
local Vector3 = import("skate_core/math").Vector3
local inverse_length_squared = import("skate_core/physics/board_motion_output").inverse_length_squared
local dot3 = import("skate_core/physics/native_arithmetic").dot3
local GroundNormalFilter = import("skate_core/air/ground_normal").GroundNormalFilter
local ReckoningFrames = import("skate_core/riding/reckoning_frames").ReckoningFrames
local length = v1.length
local t1 = {
    Settings = {}
}
local xyz, lanes

function t1.update(p1, p2, p3, p4, p5, p6, p7, p8, p9, p10) -- line: 31
    -- upvalues: rt (copy), v2 (copy), Vector3 (copy), inverse_length_squared (copy), dot3 (copy), GroundNormalFilter (copy), ReckoningFrames (copy), length (copy), xyz (ref), lanes (ref)
    local v3 = lanes(p1.up)

    p1.dynamic_up = rt.copy(p1.up)
    p1.up_velocity = rt.copy(Vector3.ZERO)
    p2.target_lean_angle = 0
    p4.secondary_lean_angle = 0
    p1.ground_blend = 0

    local v4 = GroundNormalFilter.update(p1.ground_filter, p5.ground_normal_smoothing, p6)

    p1.ground_normal = xyz(v4)
    p2.heading = rt.copy(p7)

    local v5 = table.create(4)

    v5[1] = v3[1] * p8 + p6[1] * (1 - p8)
    v5[2] = v3[2] * p8 + p6[2] * (1 - p8)
    v5[3] = v3[3] * p8 + p6[3] * (1 - p8)
    v5[4] = v3[4] * p8 + p6[4] * (1 - p8)

    if length(v5) > 9.999999974752427E-07 then
        local v6 = inverse_length_squared(dot3(v5, v5), 2)

        v3 = {
            v5[1] * v6,
            v5[2] * v6,
            v5[3] * v6,
            v5[4] * v6
        }
    end

    p1.up = xyz(v3)
    p1.target = rt.copy(p1.up)
    GroundNormalFilter.filter(p1.slow_filter, v3)
    GroundNormalFilter.filter(p1.fast_filter, v3)
    GroundNormalFilter.publish_current(p1.slow_filter, v3)
    GroundNormalFilter.publish_current(p1.fast_filter, v3)
    ReckoningFrames.calculate_transform(p2, v3, v4)
    ReckoningFrames.calculate_tilt(p2, p9, p5.tilt_vs_rotation, p5.tilt_vs_slope)
    v2.update_ground(p3, p10)
end

function t1.xyz(p11) -- line: 79
    -- upvalues: Vector3 (copy)
    return Vector3.new(p11[1], p11[2], p11[3])
end

xyz = t1.xyz

function t1.lanes(p12) -- line: 84
    return {
        p12.x,
        p12.y,
        p12.z,
        0
    }
end

lanes = t1.lanes

return t1
