-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/air/trajectory/math")
local v2 = import("skate_core/air/trajectory/launch")
local v3 = import("skate_core/trigonometry")
local Trajectory = import("skate_core/air/trajectory/prediction").Trajectory
local UP, STEP, dot, sub = v1.UP, v1.STEP, v1.dot, v1.sub
local scale, madd, cross, reciprocal = v1.scale, v1.madd, v1.cross, v1.reciprocal
local angle_between, length, normalize = v1.angle_between, v1.length, v1.normalize
local t1 = {}

function t1.apply_admitted_target(p1, p2, p3, p4, p5, p6, p7, p8) -- line: 21
    -- upvalues: v2 (copy), STEP (copy), t1 (copy)
    v2.adjust_trajectory(p1.request.trajectory, p2.frame, p3, p6)
    p1.result.contact_frame = p2.frame
    p1.result.contact_time = p2.frame * STEP
    p1.result.contact_normal = t1.landing_normal(p2.direction, p5, p4, p7, p8)
end

function t1.landing_normal(p9, p10, p11, p12, p13) -- line: 45
    -- upvalues: UP (copy), dot (copy), sub (copy), scale (copy), madd (copy), normalize (copy), t1 (copy)
    local v5 = madd(sub(p10, scale(p9, dot(p9, p10))), -p12, UP)
    local v6 = t1.clamp_angle(v5, p11, p13 * 0.01745329238474369)
    local v7 = dot(v6, normalize(p9))

    if v7 > 0 then
        v6 = sub(v6, scale(p9, v7))
    end

    return normalize(v6)
end

function t1.clamp_angle(p14, p15, p16) -- line: 56
    -- upvalues: rt (copy), v3 (copy), dot (copy), scale (copy), madd (copy), cross (copy), length (copy), normalize (copy)
    local v8 = normalize(p14)
    local v9 = normalize(p15)
    local v10 = cross(v8, v9)
    local v11 = v3.acos(rt.clamp(dot(v8, v9), -1, 1))

    if math.abs(-math.floor(v11 * 0.15915493667125702 + 0.5) * 6.2831854820251465 + v11) < p16 or dot(v10, v10) < 1.52587890625E-05 then
        return rt.copy(p14)
    end

    local v14 = normalize(v10)
    local v15, v16 = v3.sin_cos(-p16 * 0.5)
    local v17 = scale(v14, v15)

    return scale(madd(cross(v17, madd(p15, v16, cross(v17, p15))), 2, p15), length(p14))
end

function t1.admitted_displacement(p17, p18, p19, p20, p21, p22, p23, p24) -- line: 77
    -- upvalues: rt (copy), Trajectory (copy), dot (copy), sub (copy), scale (copy), madd (copy), reciprocal (copy), angle_between (copy), length (copy), normalize (copy)
    local v18 = Trajectory.position_at(p17.request.trajectory, p17.result.contact_time)

    if p18.point[2] - v18[2] < -0.4000000059604645 or p18.direction[2] > 0.9 then
        return nil, p24
    end

    local v19 = normalize(sub(p19["end"], p19.start))
    local v20 = sub(p20, scale(v19, dot(v19, p20)))

    if math.abs(v20[2] * (1 - math.abs(v19[2]))) > p23.max_downward_speed or p22.kind == 3 then
        return nil, p24
    end

    local v24 = rt.copy(v20)

    v24[2] = 0

    if (if p22.kind == 2 then p23.max_speed_squared_ledge else p23.max_speed_squared_rail) < dot(v24, v24) then
        return nil, p24
    end

    local v25 = sub(p18.trajectory_point, p18.point)
    local v26

    if p22.kind == 2 then
        local v27 = dot(v25, p22.side) > 0
        local v28 = dot(sub(p21, p19.start), p22.side) > 0

        v26 = p23.lock_distance * p23.ledge_scalars[(if v27 then 0 else 2) + (if v28 then 0 else 1) + 1]
    else
        v26 = p23.lock_distance
    end

    local v29 = rt.fmax(v26, 0.1)

    if v29 <= p18.distance then
        return nil, v29
    end

    local v30 = sub(p18.trajectory_point, p19.start)
    local v31 = scale(sub(v30, scale(p18.direction, dot(p18.direction, v30))), -1)
    local v32 = length(v31)

    if p23.lock_distance <= v32 then
        local v33 = p23.deck_dimensions[2] * 0.5 + p23.deck_dimensions[1] * 0.5

        v31 = scale(v31, (-p23.tip_scalar * v33 + v32) / v32)
    end

    local v34 = rt.copy(p17.request.trajectory.velocity)
    local v35 = madd(v31, reciprocal(p18.time), v34)

    if (if dot(v34, v34) * dot(v35, v35) > 9.999999747378752E-05 then angle_between(v34, v35) else 0) > p23.maximum_adjust_angle * 0.01745329238474369 then
        return nil, v29
    end

    return v31, v29
end

return t1
