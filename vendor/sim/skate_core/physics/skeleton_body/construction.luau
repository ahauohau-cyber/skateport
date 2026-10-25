-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_from_bits(p1) -- line: 7
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p1)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local Vector3 = import("skate_core/math").Vector3
local v2 = import("skate_core/physics/mass")
local MassMoments, RETAIL_UNBOUNDED_VELOCITY, aggregate_mass_properties, primitive_mass = v2.MassMoments, v2.RETAIL_UNBOUNDED_VELOCITY, v2.aggregate_mass_properties, v2.primitive_mass
local primitive_mass_properties = v2.primitive_mass_properties
local v3 = import("skate_core/physics/native_arithmetic")
local RetailLocalMassFrame = import("skate_core/physics/rigid_body").RetailLocalMassFrame
local SkeletonAnimationMasses = import("skate_core/physics/skeleton_animation_record").SkeletonAnimationMasses
local v4 = import("skate_core/trigonometry")

local function skeleton_body() -- line: 29
    -- upvalues: import (copy)
    return import("skate_core/physics/skeleton_body")
end

local t1 = {
    BoneSettings = {},
    SkeletonBodySettings = {},
    HatGeometry = {}
}

function t1.HatGeometry.from_offsets(p2, p3, p4, p5) -- line: 53
    -- upvalues: rt (copy), v4 (copy)
    local v5, v6 = v4.sin_cos(p4.x)
    local v7, v8 = v4.sin_cos(p4.y)
    local v9, v10 = v4.sin_cos(p4.z)
    local v11 = v6 * v9
    local v12 = v5 * v9
    local v13 = v5 * v10
    local v14 = v6 * v10

    return {
        radius = p2,
        half_length = p3 * 0.5,
        translation = rt.copy(p5),
        basis = {
            columns = {
                {
                    v8 * v10,
                    v8 * v9,
                    -v7
                },
                {
                    v7 * v13 - v11,
                    v7 * v12 + v14,
                    v8 * v5
                },
                {
                    v7 * v14 + v12,
                    v7 * v11 - v13,
                    v8 * v6
                }
            }
        }
    }
end

t1.SkeletonPart = {}
t1.SkeletonBodyDefinition = {}

function t1.SkeletonBodyDefinition.new(p6, p7, p8, p9) -- line: 87
    -- upvalues: rt (copy), v1 (copy), import (copy), Vector3 (copy), SkeletonAnimationMasses (copy), t1 (copy)
    local v15 = import("skate_core/physics/skeleton_body")
    local ANIMATION_PART_COUNT, PART_COUNT = v15.ANIMATION_PART_COUNT, v15.PART_COUNT
    local v16 = table.create(PART_COUNT)

    for i = 0, ANIMATION_PART_COUNT - 1 do
        local v17 = rt.copy(p7[i + 1])
        local v18 = rt.copy(p6[i + 1])
        local t2

        if i == 0 then
            t2 = {
                tag = "Capsule",
                radius = p8.root_radius,
                half_length = p8.root_half_length
            }
        elseif (i ~= 1 or p9 == nil) and v17.volume_type ~= 1 then
            if v17.volume_type == 0 then
                local v19 = v17.volume_scalar * 0.5

                t2 = {
                    tag = "RoundedBox",
                    radius = 0,
                    half_extents = Vector3.new(v18.x * v19, v18.y * v19, v18.z * v19)
                }
            elseif v17.volume_type == 2 then
                local v20 = v18.x * p8.capsule_radius_scalar * 0.5
                local v21 = v18.z * 0.5 - v20

                t2 = {
                    tag = "Capsule",
                    radius = v17.volume_scalar * v20
                }

                if -v21 >= 0 then
                    v21 = 0
                end

                t2.half_length = v21 * p8.capsule_length_scalar * v17.volume_scalar
            else
                error("Unresolved non-root skeleton volume type", 0)
            end
        else
            local v22 = v18.x * 0.5
            local v23 = v18.y * 0.5

            t2 = {
                tag = "Sphere"
            }

            if not (v22 - v23 >= 0) then
                v22 = v23
            end

            t2.radius = v22 * v17.volume_scalar
        end

        local v24 = if i == 0 then 0.0010000000474974513 else p8.density * (v18.x * v18.y * v18.z)
        local v25 = if i == 1 then rt.copy(p9) else nil
        local v26 = v17.mass_factor * v24
        local v27 = v17.ragdoll_mass_factor * v24
        local v28 = t1.mass_properties(t2, v25, v26)
        local v29 = t1.mass_properties(t2, v25, v27)

        t1.adjust_inertia(v28, p8.inertia_multiply_type, p8.inertia_factor)
        v16[#v16 + 1] = {
            shape = rt.copy(t2),
            hat = rt.copy(v25),
            animated = v28,
            ragdoll = v29,
            inverse_mass_animated = 1 / v26,
            inverse_mass_ragdoll = p8.ragdoll_inverse_mass_factor / v27
        }
    end

    for _, v30 in {
            { 1047233823, 1036831949, 1036831949 },
            { 1052266988, 1048911544, 1008981770 }
        } do
        local v31 = v30[1]
        local v32 = v30[2]

        buffer.writeu32(v1, 0, v30[3])

        local v34 = buffer.readf32(v1, 0)
        local t4 = {
            tag = "Capsule"
        }

        buffer.writeu32(v1, 0, v31)
        t4.radius = buffer.readf32(v1, 0)
        buffer.writeu32(v1, 0, v32)
        t4.half_length = buffer.readf32(v1, 0)

        local v35 = t1.mass_properties(t4, nil, v34)

        v35.dynamics.maximum_linear_velocity = 29.999998092651367
        v35.dynamics.maximum_angular_velocity = 29.999998092651367
        t1.adjust_inertia(v35, 1, 5)
        v16[#v16 + 1] = {
            hat = nil,
            shape = t4,
            animated = rt.copy(v35),
            ragdoll = rt.copy(v35),
            inverse_mass_animated = 1 / v34,
            inverse_mass_ragdoll = 1 / v34
        }
    end

    if #v16 ~= PART_COUNT then
        error("Skeleton part count", 0)
    end

    local v36 = table.create(ANIMATION_PART_COUNT)

    for i = 1, ANIMATION_PART_COUNT do
        v36[i] = p7[i].volume_type
    end

    return {
        parts = v16,
        animation_masses = SkeletonAnimationMasses.from_bone_data(rt.copy(p6), v36, p9 ~= nil),
        bones = rt.copy(p7)
    }
end

function t1.mass_properties(p10, p11, p12) -- line: 183
    -- upvalues: rt (copy), MassMoments (copy), RETAIL_UNBOUNDED_VELOCITY (copy), aggregate_mass_properties (copy), primitive_mass (copy), primitive_mass_properties (copy), RetailLocalMassFrame (copy)
    if p11 == nil then
        local v37 = primitive_mass_properties({
            shape = rt.copy(p10),
            requested_mass = p12
        }, RETAIL_UNBOUNDED_VELOCITY, 0)

        if v37 == nil then
            error("Invalid skeleton primitive", 0)
        end

        return v37
    end

    local v38 = primitive_mass({
        tag = "Cylinder",
        padding = 0,
        radius = p11.radius,
        half_length = p11.half_length
    })

    if v38 == nil then
        error("Invalid skeleton hat primitive", 0)
    end

    local v39 = MassMoments.from_primitive(v38)

    MassMoments.transform(v39, p11.basis, p11.translation)

    local v40 = primitive_mass(p10)

    if v40 == nil then
        error("Invalid head primitive", 0)
    end

    MassMoments.add(v39, MassMoments.from_primitive(v40))

    local v41 = aggregate_mass_properties(v39, p12, RETAIL_UNBOUNDED_VELOCITY, 0)

    v41.local_mass_frame = rt.copy(RetailLocalMassFrame.IDENTITY)

    return v41
end

function t1.adjust_inertia(p13, p14, p15) -- line: 220
    -- upvalues: Vector3 (copy), v3 (copy)
    local dynamics = p13.dynamics

    if p14 == 1 then
        local v42 = v3.reciprocal_estimate(p15)
        local v43 = v42 * (-v42 * p15 + 1) + v42
        local v44 = v43 * (-v43 * p15 + 1) + v43

        dynamics.inverse_tensor = Vector3.new(dynamics.inverse_tensor.x * v44, dynamics.inverse_tensor.y * v44, dynamics.inverse_tensor.z * v44)

        local v45 = if dynamics.inverse_tensor.x < dynamics.inverse_tensor.y then dynamics.inverse_tensor.x else dynamics.inverse_tensor.y

        if not (v45 < dynamics.inverse_tensor.z) then
            v45 = dynamics.inverse_tensor.z
        end

        dynamics.spherical = 1 / v45
    elseif p14 == 2 then
        local v46 = 1 / (p15 * 3)
        local v47 = (dynamics.inverse_tensor.x + dynamics.inverse_tensor.y + dynamics.inverse_tensor.z) * v46

        dynamics.inverse_tensor = Vector3.new(v47, v47, v47)
        dynamics.spherical = 1 / v47
    end
end

return t1
