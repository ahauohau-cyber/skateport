-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/math")
local v2 = import("skate_core/physics/board_ground")
local v3 = import("skate_core/physics/board_motion_output")
local v4 = import("skate_core/physics/native_arithmetic")
local v5 = import("skate_core/point_graph")
local Vector3 = v1.Vector3
local angle_between = v2.angle_between
local dot, inverse_length_squared, length = v3.dot, v3.inverse_length_squared, v3.length
local reciprocal_estimate = v4.reciprocal_estimate
local PointGraph = v5.PointGraph
local t1 = {
    CollisionResponseSettings = {},
    CollisionResponsePhysical = {},
    CollisionResponse = {}
}

function t1.collision_response(p1, p2) -- line: 60
    -- upvalues: dot (copy), length (copy), PointGraph (copy), t1 (copy)
    if bit32.band(p2.flags_2472, 131072) == 0 then
        return nil
    end

    local v6 = dot(t1.xyz(p2.collision_displacement), t1.xyz(p2.ground_normal))
    local t2 = {
        p2.collision_displacement[1] - p2.ground_normal[1] * v6,
        p2.collision_displacement[2] - p2.ground_normal[2] * v6,
        p2.collision_displacement[3] - p2.ground_normal[3] * v6,
        p2.collision_displacement[4] - p2.ground_normal[4] * v6
    }
    local v7 = length(t1.xyz(t2))

    if v7 < 1.52587890625E-05 then
        return nil
    end

    local v8 = 1 / v7
    local t3 = {
        t2[1] * v8,
        t2[2] * v8,
        t2[3] * v8,
        t2[4] * v8
    }
    local v9 = dot(t1.xyz(p2.velocity), t1.xyz(t3))
    local t4 = {
        p2.velocity[1] - t3[1] * v9,
        p2.velocity[2] - t3[2] * v9,
        p2.velocity[3] - t3[3] * v9,
        p2.velocity[4] - t3[4] * v9
    }
    local t5 = {
        t3[1] * p1.target_displacement_velocity + t4[1],
        t3[2] * p1.target_displacement_velocity + t4[2],
        t3[3] * p1.target_displacement_velocity + t4[3],
        t3[4] * p1.target_displacement_velocity + t4[4]
    }
    local t6 = {
        (t5[1] - p2.velocity[1]) * p1.force_scalar,
        (t5[2] - p2.velocity[2]) * p1.force_scalar,
        (t5[3] - p2.velocity[3]) * p1.force_scalar,
        (t5[4] - p2.velocity[4]) * p1.force_scalar
    }

    if p1.target_displacement_velocity < v9 then
        t6 = { 0, 0, 0, 0 }
    end

    local v10 = length(t1.xyz(t6))
    local v11 = t1.reciprocal_refined(p2.time_step)
    local t7 = {
        t6[1] * p2.mass * v11,
        t6[2] * p2.mass * v11,
        t6[3] * p2.mass * v11,
        t6[4] * p2.mass * v11
    }
    local v12 = v10 >= 0.01

    if v12 then
        local v13 = if v10 <= p1.maximum_velocity_delta then 1 else p1.maximum_velocity_delta / v10

        t7[1] *= v13
        t7[2] *= v13
        t7[3] *= v13
        t7[4] *= v13
    else
        t7 = { 0, 0, 0, 0 }
    end

    local v14 = t1.wrap_angle(t1.signed_angle(t1.xyz(p2.forward), t1.xyz(t3), t1.xyz(p2.up)))
    local v15 = PointGraph.evaluate(p1.torque_vs_angle, math.abs(v14) * 0.31830987334251404)

    if not (v14 >= 0) then
        v15 = -v15
    end

    return {
        applied = v12,
        force = t7,
        point = {
            0,
            p1.force_y_offset,
            0, 0
        },
        angular_displacement = {
            p2.up[1] * v15,
            p2.up[2] * v15,
            p2.up[3] * v15,
            p2.up[4] * v15
        },
        target_velocity = t5
    }
end

local acos = import("skate_core/trigonometry").acos
local fmin, fmax = rt.fmin, rt.fmax

function t1.signed_angle_xyz(p3, p4, p5, p6, p7, p8, p9, p10, p11) -- line: 166
    -- upvalues: inverse_length_squared (copy), acos (copy), fmin (copy), fmax (copy)
    local v16 = p3 * p3 + p4 * p4 + p5 * p5
    local v17 = p6 * p6 + p7 * p7 + p8 * p8

    if not (v16 > 1E-04 and v17 > 1E-04) then
        return 0
    end

    local v18 = inverse_length_squared(v16, 1)
    local v19 = inverse_length_squared(v17, 1)
    local v20 = p3 * v18
    local v21 = p4 * v18
    local v22 = p5 * v18
    local v23 = p6 * v19
    local v24 = p7 * v19
    local v25 = p8 * v19
    local v26 = if v16 > 9.999999747378752E-05 and v17 > 9.999999747378752E-05 then acos(fmin(fmax(v20 * v23 + v21 * v24 + v22 * v25, -1), 1)) else 0
    local v27 = -v22 * v24 + v21 * v25
    local v28 = -v20 * v25 + v22 * v23
    local v29 = -v21 * v23 + v20 * v24

    if v27 * p9 + v28 * p10 + v29 * p11 < 0 then
        return 6.2831854820251465 - v26
    end

    return v26
end

local signed_angle_xyz = t1.signed_angle_xyz

function t1.signed_angle(p12, p13, p14) -- line: 202
    -- upvalues: signed_angle_xyz (copy)
    return signed_angle_xyz(p12.x, p12.y, p12.z, p13.x, p13.y, p13.z, p14.x, p14.y, p14.z)
end

function t1.signed_angle_reference(p15, p16, p17) -- line: 210
    -- upvalues: Vector3 (copy), angle_between (copy), dot (copy), inverse_length_squared (copy), t1 (copy)
    local v30 = dot(p15, p15)
    local v31 = dot(p16, p16)

    if not (v30 > 1E-04 and v31 > 1E-04) then
        return 0
    end

    local v32 = angle_between(p15, p16)
    local v33 = t1.scale(p15, inverse_length_squared(v30, 1))
    local v34 = t1.scale(p16, inverse_length_squared(v31, 1))

    if dot(Vector3.new(-v33.z * v34.y + v33.y * v34.z, -v33.x * v34.z + v33.z * v34.x, -v33.y * v34.x + v33.x * v34.y), p17) < 0 then
        return 6.2831854820251465 - v32
    end

    return v32
end

function t1.wrap_angle(p18) -- line: 232
    -- upvalues: rt (copy)
    local v36

    if not (p18 < -3.1415927410125732) and p18 < 3.1415927410125732 then
        v36 = p18

        return v36
    end

    v36 = -rt.f_to_i32(p18 * 0.15915493667125702) * 6.2831854820251465 + p18

    if v36 < 3.1415927410125732 then
        if v36 < -3.1415927410125732 then
            v36 += 6.2831854820251465
        end

        return v36
    end

    return v36 - 6.2831854820251465
end

function t1.reciprocal_refined(p19) -- line: 247
    -- upvalues: reciprocal_estimate (copy)
    local v37 = reciprocal_estimate(p19)
    local v38 = v37 * (-v37 * p19 + 1) + v37

    return v38 * (-v38 * p19 + 1) + v38
end

function t1.scale(p20, p21) -- line: 253
    -- upvalues: Vector3 (copy)
    return Vector3.new(p20.x * p21, p20.y * p21, p20.z * p21)
end

function t1.xyz(p22) -- line: 257
    -- upvalues: Vector3 (copy)
    return Vector3.new(p22[1], p22[2], p22[3])
end

return t1
