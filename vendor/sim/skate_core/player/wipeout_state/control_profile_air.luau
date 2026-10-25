-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/player/wipeout_state/math")
local v2 = import("skate_core/player/wipeout_state/orientation")
local v3 = import("skate_core/player/wipeout_state/torque")
local sin_cos = import("skate_core/trigonometry").sin_cos
local PointGraph = import("skate_core/point_graph").PointGraph
local t1 = {
    UP = { 0, 1, 0, 0 }
}
local UP = t1.UP

function t1.update(p1, p2, p3, p4, p5, p6) -- line: 21
    -- upvalues: v1 (copy), v2 (copy), v3 (copy), sin_cos (copy), PointGraph (copy), t1 (copy), UP (copy)
    local t2 = {
        0, 0, 0, 0
    }

    p1.angular_velocity = v3.angular_velocity(p2.record, p2.definition.animation_masses.fractional)

    local t3 = {
        p5[2] * p6.tilt_degrees * 0.01745329238474369,
        0,
        p5[1] * p6.tilt_degrees * -0.01745329238474369,
        0
    }

    p1.retained_tilt = v1.madd(t3, 0.05, v1.scale(p1.retained_tilt, 0.95))

    local v4 = v1.length(p1.retained_tilt)
    local v5 = {
        0, 0, 0, 1
    }

    if v4 > 0.01 then
        local v6, v7 = sin_cos(v4 * 0.5)

        v5 = v1.scale(v1.scale(p1.retained_tilt, v1.reciprocal(v4)), v6)
        v5[4] = v7
    end

    local v8 = t1.transform(p4, v2.alignment_up(p6.align_euler[1], p6.align_euler[2]))
    local v9 = v1.normalize_or(p1.right, t2)
    local v10 = v1.sub(p1.velocity, v1.scale(v9, v1.dot(p1.velocity, v9)))
    local v11 = if v1.dot(p1.forward, v10) <= 0 then v1.normalize(v1.add(v8, { 0, -100, 0, 0 })) else v1.normalize_or(v10, v8)
    local v12 = v2.rotate(v5, v11)
    local v13 = v1.normalize_or(v1.cross(v12, v8), v8)
    local v14 = v1.wrap_angle(v2.signed_angle(v12, v8, v13))
    local v15 = if p6.align_with_velocity then v1.scale(v1.scale(v13, v14), p6.torque_distance) else { 0, 0, 0, 0 }
    local v16 = v2.rotate(v5, v8)
    local v17 = v2.rotate(v5, v1.normalize_or(v1.cross(v11, UP), t2))

    p1.retained_sideways_input = t1.retain_input(p1.sideways_input, p1.retained_sideways_input, p6.spin_inertia)
    p1.retained_forward_input = t1.retain_input(p1.forward_input, p1.retained_forward_input, p6.spin_inertia)

    local v18 = p6.sideways_spin * p1.retained_sideways_input
    local v19 = p6.forward_spin * p1.retained_forward_input
    local v20 = v1.madd(v17, v19, v1.madd(v16, v18, t2))

    if v1.dot(v20, p1.angular_velocity) <= 0 then
        p1.control_time = 0
    end

    local v21 = v1.scale(v20, PointGraph.evaluate(p6.spin_vs_time, p1.control_time))
    local v22 = if math.abs(v18) <= 0.1 then t1.horizontal_alignment(p6, p4, v11, v5) else { 0, 0, 0, 0 }
    local v23 = v1.add(v1.madd(v1.sub(v21, p1.angular_velocity), p6.torque_velocity, v15), v22)

    v3.apply(p2, p3, v23)
end

function t1.retain_input(p7, p8, p9) -- line: 87
    if math.abs(p7) >= math.abs(p8) then
        return p7
    end

    return (1 - p9) * p7 + p8 * p9
end

function t1.horizontal_alignment(p10, p11, p12, p13) -- line: 95
    -- upvalues: v1 (copy), v2 (copy), t1 (copy), UP (copy)
    local t4 = {
        0, 0, 0, 0
    }
    local v24 = v1.normalize_or(p10.horizontal_axis, { 1, 0, 0, 0 })
    local v25 = t1.transform(p11, v24)
    local v26 = v2.rotate(p13, v1.normalize_or(v1.cross(p12, UP), t4))

    if not p10.horizontal_directed then
        v26 = v1.scale(v26, if v1.dot(v25, v26) > 0 then 1 else -1)
    end

    local v27 = v1.normalize_or(v1.cross(v24, v26), t4)

    if v1.dot(v27, v27) > 0.9 then
        local v28 = v1.wrap_angle(v2.projected_angle(v25, v26, v27))

        return v1.scale(v27, v1.clamp(v28, -0.7853981852531433, 0.7853981852531433) * 0.8)
    end

    return { 0, 0, 0, 0 }
end

function t1.transform(p14, p15) -- line: 114
    -- upvalues: v1 (copy)
    return v1.madd(p14[3], p15[3], v1.madd(p14[2], p15[2], v1.scale(p14[1], p15[1])))
end

return t1
