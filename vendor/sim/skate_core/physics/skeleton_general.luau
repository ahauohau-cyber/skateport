-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/native_arithmetic")
local v2 = import("skate_core/physics/skeleton_animation_record")
local v3 = import("skate_core/physics/skeleton_body")
local v4 = import("skate_core/math")
local reciprocal_estimate = v1.reciprocal_estimate
local SkeletonAnimationRecord, compose_affine, transform_point = v2.SkeletonAnimationRecord, v2.compose_affine, v2.transform_point
local SkeletonBody, SkeletonPhysicalRecord = v3.SkeletonBody, v3.SkeletonPhysicalRecord
local Vector3 = v4.Vector3
local t1 = {}

function t1.root_velocity(p1, p2, p3) -- line: 30
    -- upvalues: rt (copy), reciprocal_estimate (copy)
    local t2 = {
        p2[1] - p1[1],
        p2[2] - p1[2],
        p2[3] - p1[3],
        p2[4] - p1[4]
    }
    local v5 = reciprocal_estimate(p3)
    local v6 = v5 * (-v5 * p3 + 1) + v5
    local v7 = v6 * (-v6 * p3 + 1) + v6
    local t3 = {
        t2[1] * v7,
        t2[2] * v7,
        t2[3] * v7,
        t2[4] * v7
    }

    rt.assign(p1, p2)

    return t3
end

function t1.apply_gravity_displacement(p4, p5) -- line: 65
    local v8 = -p5 * 0.5 * 0.01666666753590107 * 0.01666666753590107
    local v9 = 59.99999687075631 * (-59.99999687075631 * 0.01666666753590107 + 1) + 59.99999687075631
    local v10 = v9 * (-v9 * 0.01666666753590107 + 1) + v9
    local v11 = v10 * 0
    local v12 = v8 * v10
    local v13 = v10 * 0
    local bodies = p4.bodies

    for i = 0, 23 do
        local v14 = bodies[i + 1]
        local inverse_mass = v14.inertia.inverse_mass
        local rates = v14.rates
        local force_acceleration = rates.force_acceleration

        force_acceleration.x += v11 * inverse_mass
        force_acceleration.y += v12 * inverse_mass
        force_acceleration.z += v13 * inverse_mass
        rates.cool_down = 0
    end
end

function t1.apply_gravity_displacement_reference(p6, p7) -- line: 92
    -- upvalues: rt (copy), SkeletonBody (copy)
    local t4 = {
        0,
        -p7,
        0, 0
    }
    local v15 = table.create(4)

    v15[1] = t4[1] * 0.5 * 0.01666666753590107 * 0.01666666753590107
    v15[2] = t4[2] * 0.5 * 0.01666666753590107 * 0.01666666753590107
    v15[3] = t4[3] * 0.5 * 0.01666666753590107 * 0.01666666753590107
    v15[4] = t4[4] * 0.5 * 0.01666666753590107 * 0.01666666753590107

    for i = 0, 23 do
        SkeletonBody.apply_part_displacement(p6, i, rt.copy(v15))
    end
end

t1.ResetObservation = {}

function t1.reset_to_animation(p8, p9, p10, p11, p12, p13) -- line: 112
    -- upvalues: rt (copy), SkeletonAnimationRecord (copy), compose_affine (copy), transform_point (copy), SkeletonBody (copy), SkeletonPhysicalRecord (copy), t1 (copy)
    for i = 0, 23 do
        local v16 = compose_affine(p11, p10[i + 1])

        SkeletonBody.set_part_transform(p8, i, v16)
        t1.reset_rates(p8, i, p13)
    end

    for _, v17 in { 24, 25 } do
        SkeletonBody.set_part_transform(p8, v17, rt.copy(p12))
        t1.reset_rates(p8, v17, p13)
    end

    local v18 = rt.copy(p10[24][4])
    local v19 = transform_point(p11, v18)
    local v20 = SkeletonBody.part_transforms(p8)

    SkeletonPhysicalRecord.reset(p8.record, v20)
    SkeletonAnimationRecord.reset_history(p9)

    return {
        local_hips = v18,
        world_hips = v19
    }
end

function t1.reset_rates(p14, p15, p16) -- line: 135
    -- upvalues: rt (copy), SkeletonBody (copy), Vector3 (copy)
    local rates = SkeletonBody.bodies_mut(p14)[p15 + 1].rates

    rates.linear_velocity = rt.copy(Vector3.ZERO)
    rates.angular_velocity = rt.copy(Vector3.ZERO)
    rates.force_acceleration = rt.copy(p16.gravity_acceleration)
    rates.torque_acceleration = rt.copy(Vector3.ZERO)
end

return t1
