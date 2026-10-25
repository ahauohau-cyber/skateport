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
local Collections = import("skate_data/collections").Collections
local PhysicsSkeleton = import("skate_data/physics_skeleton").PhysicsSkeleton
local t1 = {}

local function path_join(p2, p3) -- line: 22
    if p2 == nil then
        return p3
    end

    return tostring(p2) .. "/" .. p3
end

function t1.load(p4, p5, p6) -- line: 30
    -- upvalues: v1 (copy), Collections (copy), PhysicsSkeleton (copy)
    local PHYS_TPOSE = PhysicsSkeleton.load(if p4 == nil then "private/stock/physics-skeletons.json" else tostring(p4) .. "/" .. "private/stock/physics-skeletons.json", p6, "PHYS_TPOSE")

    if #PHYS_TPOSE.bones ~= 24 then
        error("Skeleton collision requires24 bone records", 0)
    end

    local v2 = table.create(24, false)
    local v3 = table.create(24, 0)

    v2[1] = true

    for i = 1, 23 do
        local v4 = Collections.words(p5, "physics_skeleton_drives", "default", string.format("PART_%s", PHYS_TPOSE.bones[i + 1].name), 9)
        local v5 = v4[8]

        v2[i + 1] = bit32.rshift(v5, 24) ~= 0

        local v6 = i + 1

        buffer.writeu32(v1, 0, v4[9])
        v3[v6] = buffer.readf32(v1, 0)
    end

    local FrictionNormal = Collections.float(p5, "physics_skeleton", "default", "FrictionNormal")

    return {
        enabled = Collections.boolean(p5, "physics_skeleton", "default", "EnableCollision"),
        normal_material = {
            static_friction = FrictionNormal,
            dynamic_friction = FrictionNormal,
            restitution = Collections.float(p5, "physics_skeleton", "default", "RestitutionNormal")
        },
        compliant = v2,
        priority = v3,
        effect_time = Collections.float(p5, "physics_skeleton", "default", "CollisionEffectTime")
    }
end

function t1.feedback(p7, p8) -- line: 72
    -- upvalues: rt (copy), Collections (copy)
    local function value(p9) -- line: 73
        -- upvalues: p7 (copy), Collections (copy)
        return Collections.float(p7, "physics_collision", "default", p9)
    end

    local function vector(p10) -- line: 76
        -- upvalues: p7 (copy), rt (copy), Collections (copy)
        return rt.map(Collections.words(p7, "physics_collision", "default", p10, 4), rt.from_bits)
    end

    return {
        body = p8,
        small_object_mass = Collections.float(p7, "physics_skeleton", "default", "SmallObjectMassThreshold"),
        ground_plane_max_distance = Collections.float(p7, "physics_collision", "default", "GroundPlaneMaxDist"),
        ground_plane_max_angle = Collections.float(p7, "physics_collision", "default", "GroundPlaneMaxAngle"),
        skater_scalar = Collections.float(p7, "physics_collision", "default", "SkaterSkeletonScalar"),
        ai_scalar = Collections.float(p7, "physics_collision", "default", "AISkeletonScalar"),
        groin_offset = rt.map(Collections.words(p7, "physics_collision", "default", "GroinLocalOffset", 4), rt.from_bits),
        face_offset = rt.map(Collections.words(p7, "physics_collision", "default", "FaceLocalOffset", 4), rt.from_bits),
        groin_radius = Collections.float(p7, "physics_collision", "default", "GroinRadius"),
        face_radius = Collections.float(p7, "physics_collision", "default", "FaceRadius")
    }
end

return t1
