-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/air/body_flip")
local v2 = import("skate_core/air/body_spin")
local v3 = import("skate_core/air/ground_normal")
local v4 = import("skate_core/math")
local v5 = import("skate_core/point_graph")
local v6 = import("skate_core/riding/reckoning_frames")
local v7 = import("skate_core/air/reckoning/data")
local v8 = import("skate_core/air/reckoning/math")
local BodySpinState = v2.BodySpinState
local GroundNormalFilter = v3.GroundNormalFilter
local Vector3 = v4.Vector3
local PointGraph = v5.PointGraph
local ReckoningFrames = v6.ReckoningFrames
local angle, length, limit_angle, normalize = v8.angle, v8.length, v8.limit_angle, v8.normalize
local normalize_safe, rotate_heading, wrap = v8.normalize_safe, v8.rotate_heading, v8.wrap
local t1 = {
    AirState = v7.AirState,
    Input = v7.Input,
    Settings = v7.Settings,
    clamp_vector_within_max_angle = v8.limit_angle
}

function t1.update(p1, p2, p3, p4, p5, p6) -- line: 43
    -- upvalues: rt (copy), v1 (copy), v2 (copy), BodySpinState (copy), GroundNormalFilter (copy), PointGraph (copy), ReckoningFrames (copy), angle (copy), length (copy), limit_angle (copy), normalize (copy), normalize_safe (copy), rotate_heading (copy), wrap (copy), t1 (copy)
    local v9 = t1.lanes(p1.up)

    p1.dynamic_up = rt.copy(p1.up)
    p2.target_lean_angle = 0
    p4.secondary_lean_angle = 0

    local v10 = GroundNormalFilter.update(p1.ground_filter, p5.ground_normal_smoothing, p6.landing_normal)

    p1.ground_normal = t1.vector(v10)

    if p6.additive_spin then
        p4.spin_speed = p6.grind_adjusted_body_spin + p6.target_spin
    elseif p6.direct_spin then
        p4.spin_speed = p6.target_spin
    else
        v2.update(p3, p5.body_spin, p6.physical_body_spin, p6.target_spin, true, p6.easy_body_spins and 1 or 0)
        p4.spin_speed = BodySpinState.speed(p3)
    end

    p4.spin_angle = p4.spin_speed * 0.01666666753590107 + p4.spin_angle

    if p4.flip_active then
        local t2 = {
            angle = p4.flip_angle,
            speed = p4.flip_speed,
            requested_speed = p4.flip_requested_speed,
            spin_transform = rt.copy(p4.spin_transform),
            combined_transform = rt.copy(p2.body_flip)
        }

        v1.update(t2, p5.body_flip, {
            requested_speed = p6.flip_request,
            spin_angle = p4.spin_angle,
            normal = rt.copy(v9),
            flip_axis = rt.copy(p4.flip_axis),
            timestep = p6.timestep,
            perfect_body_flips = p6.perfect_body_flips
        })
        p4.flip_angle = t2.angle
        p4.flip_speed = t2.speed
        p4.flip_requested_speed = t2.requested_speed
        p4.spin_transform = t2.spin_transform
        p2.body_flip = t2.combined_transform
    end

    local v11 = wrap(angle(v9, v10))
    local v12 = v11 * p6.normal_blend
    local v13 = if not (math.abs(v11) >= 6.280043601989746) then v10 elseif math.abs(v9[2]) < 0.9900000095367432 then { 0, 1, 0, 0 } else { 1, 0, 0, 0 }
    local v15 = normalize(limit_angle(v13, v9, v12))
    local v16 = PointGraph.evaluate(p5.max_up_angle_delta, length(p6.com_to_deck))

    if v16 < math.abs((wrap(angle(v15, v9)))) then
        v15 = limit_angle(v15, v9, v16)
    end

    local v18 = normalize_safe(v15, v9)

    p1.up_velocity = t1.vector({
        v18[1] - v9[1],
        v18[2] - v9[2],
        v18[3] - v9[3],
        v18[4] - v9[4]
    })
    p1.up = t1.vector(v18)
    p1.target = rt.copy(p1.up)

    if not p4.flip_active then
        p2.heading = rotate_heading(p2.heading, v18, p6.timestep * p4.spin_speed)
    end

    GroundNormalFilter.filter(p1.slow_filter, v18)
    GroundNormalFilter.filter(p1.fast_filter, v18)
    GroundNormalFilter.publish_current(p1.slow_filter, v18)
    GroundNormalFilter.publish_current(p1.fast_filter, v18)
    ReckoningFrames.calculate_transform(p2, v18, v10)
    ReckoningFrames.calculate_tilt(p2, p6.reverse_stance, p5.tilt_vs_rotation, p5.tilt_vs_slope)
end

function t1.lanes(p7) -- line: 130
    return {
        p7.x,
        p7.y,
        p7.z,
        0
    }
end

function t1.vector(p8) -- line: 134
    -- upvalues: Vector3 (copy)
    return Vector3.new(p8[1], p8[2], p8[3])
end

function t1.update_plant(p9, p10, p11, p12, p13, p14, p15, p16) -- line: 139
    -- upvalues: rt (copy), v2 (copy), GroundNormalFilter (copy), ReckoningFrames (copy), limit_angle (copy), normalize (copy), normalize_safe (copy), t1 (copy)
    p10.heading = rt.copy(p15)
    v2.update(p11, p13.body_spin, 0, 0, true, 0)

    local v19 = t1.lanes(p9.up)

    p9.dynamic_up = rt.copy(p9.up)
    p10.target_lean_angle = 0
    p12.secondary_lean_angle = 0

    local v20 = normalize(GroundNormalFilter.update(p9.ground_filter, p13.ground_normal_smoothing, p14))

    p9.ground_normal = t1.vector(v20)

    local v21 = normalize_safe(limit_angle(v20, v19, 1), v19)

    p9.up_velocity = t1.vector({
        v21[1] - v19[1],
        v21[2] - v19[2],
        v21[3] - v19[3],
        v21[4] - v19[4]
    })
    p9.up = t1.vector(v21)
    p9.target = rt.copy(p9.up)
    GroundNormalFilter.filter(p9.slow_filter, v21)
    GroundNormalFilter.filter(p9.fast_filter, v21)
    GroundNormalFilter.publish_current(p9.slow_filter, v21)
    GroundNormalFilter.publish_current(p9.fast_filter, v21)
    ReckoningFrames.calculate_transform(p10, v21, v20)
    ReckoningFrames.calculate_tilt(p10, p16, p13.tilt_vs_rotation, p13.tilt_vs_slope)
end

return t1
