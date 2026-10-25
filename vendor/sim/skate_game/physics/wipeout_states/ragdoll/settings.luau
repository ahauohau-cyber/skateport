-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_subnormal_mantissa(p1) -- line: 7
    local v2 = p1 * 7.1362384635298E+44
    local v3 = math.floor(v2)
    local v4 = v2 - v3

    if v4 > 0.5 or v4 == 0.5 and v3 % 2 == 1 then
        return v3 + 1
    end

    return v3
end

local function rtl_to_bits(p2) -- line: 16
    -- upvalues: v1 (copy)
    if p2 ~= 0 and p2 > -1.1754943508222875E-38 and p2 < 1.1754943508222875E-38 then
        local v6 = math.abs(p2) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        if p2 < 0 then
            return v5 + 2147483648
        end

        return v5
    end

    buffer.writef32(v1, 0, p2)

    return (buffer.readu32(v1, 0))
end

local function rtl_from_bits(p3) -- line: 24
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p3)

    return (buffer.readf32(v1, 0))
end

local function rtl_fround(p4) -- line: 28
    -- upvalues: v1 (copy)
    if p4 ~= 0 and p4 > -1.1754943508222875E-38 and p4 < 1.1754943508222875E-38 then
        local v9 = math.abs(p4) * 7.1362384635298E+44
        local v8 = math.floor(v9)
        local v10 = v9 - v8

        if v10 > 0.5 or v10 == 0.5 and v8 % 2 == 1 then
            v8 += 1
        end

        local v11 = v8 * 1.401298464324817E-45

        if p4 < 0 then
            return -v11
        end

        return v11
    end

    buffer.writef32(v1, 0, p4)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local v12 = import("skate_core/trigonometry")
local Collections = import("skate_data/collections").Collections
local PhysicsSkeleton = import("skate_data/physics_skeleton").PhysicsSkeleton
local t1 = {}
local limits

local function path_join(p5, p6) -- line: 50
    if p5 == nil then
        return p6
    end

    return tostring(p5) .. "/" .. p6
end

t1.Settings = {}

function t1.Settings.load(p7, p8, p9) -- line: 68
    -- upvalues: rt (copy), v1 (copy), Collections (copy), PhysicsSkeleton (copy), limits (ref)
    local PHYS_TPOSE = PhysicsSkeleton.load(if p8 == nil then "private/stock/physics-skeletons.json" else tostring(p8) .. "/" .. "private/stock/physics-skeletons.json", p9, "PHYS_TPOSE")

    if #PHYS_TPOSE.bones ~= 24 then
        error("Ragdoll requires24 physical bones", 0)
    end

    local t2 = {
        "JOINT_NECK_NECK1",
        "JOINT_SPINE3_NECK",
        "JOINT_LEFT_FOREARM_HAND",
        "JOINT_LEFT_ARM_FOREARM",
        "JOINT_LEFT_SHOULDER_ARM",
        "JOINT_SPINE3_LEFT_SHOULDER",
        "JOINT_RIGHT_FOREARM_HAND",
        "JOINT_RIGHT_ARM_FOREARM",
        "JOINT_RIGHT_SHOULDER_ARM",
        "JOINT_SPINE3_RIGHT_SHOULDER",
        "JOINT_SPINE2_SPINE3",
        "JOINT_SPINE1_SPINE2",
        "JOINT_SPINE_SPINE1",
        "JOINT_HIPS_SPINE",
        "JOINT_LEFT_FOOT_TOE_BASE",
        "JOINT_LEFT_LEG_FOOT",
        "JOINT_LEFT_UPLEG_LEG",
        "JOINT_HIPS_LEFT_LEG",
        "JOINT_RIGHT_FOOT_TOE_BASE",
        "JOINT_RIGHT_LEG_FOOT",
        "JOINT_RIGHT_UPLEG_LEG",
        "JOINT_HIPS_RIGHT_LEG"
    }
    local SwingRagdollScalar = Collections.float(p7, "physics_skeleton_joints", "default", "SwingRagdollScalar")
    local TwistRagdollScalar = Collections.float(p7, "physics_skeleton_joints", "default", "TwistRagdollScalar")
    local v13 = rt.filled(22, { 0, 0, 0, 0 })
    local v14 = rt.filled(22, { 0, 0, 0, 0 })

    for i = 0, #t2 - 1 do
        local v15 = t2[i + 1]
        local v16 = rt.map(Collections.words(p7, "physics_skeleton_joints", "default", v15, 5), rt.from_bits)
        local v17 = PHYS_TPOSE.bones[i + 1 + 1]

        buffer.writeu32(v1, 0, v17.words[22])

        local v19 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v17.words[21])

        local v21 = buffer.readf32(v1, 0)

        v13[i + 1] = limits(v19 * v16[2], v21 * v16[3])
        v14[i + 1] = limits(v19 * v16[4] * SwingRagdollScalar, v21 * v16[5] * TwistRagdollScalar)
    end

    local function material(p10, p11) -- line: 112
        -- upvalues: p7 (copy), Collections (copy)
        local v22 = Collections.float(p7, "physics_skeleton", "default", p10)

        return {
            static_friction = v22,
            dynamic_friction = v22,
            restitution = Collections.float(p7, "physics_skeleton", "default", p11)
        }
    end

    local DoInverseMass = Collections.boolean(p7, "physics_wipeout", "default", "DoInverseMass")
    local DoInverseInertia = Collections.boolean(p7, "physics_wipeout", "default", "DoInverseInertia")
    local v23 = Collections.float(p7, "physics_wipeout", "default", "LinearDrag") * 59.999996185302734
    local v24 = Collections.float(p7, "physics_wipeout", "default", "AngularDrag") * 59.999996185302734
    local RestitutionRagdoll = material("FrictionRagdoll", "RestitutionRagdoll")
    local RestitutionRagdollHead = material("FrictionRagdollHead", "RestitutionRagdollHead")

    return {
        normal_limits = v13,
        ragdoll_limits = v14,
        inverse_mass = DoInverseMass,
        inverse_inertia = DoInverseInertia,
        drag = { v23, v24 },
        materials = { RestitutionRagdoll, RestitutionRagdollHead }
    }
end

function limits(p12, p13) -- line: 138
    -- upvalues: v1 (copy), v12 (copy)
    local v25

    if p12 ~= 0 and p12 > -1.1754943508222875E-38 and p12 < 1.1754943508222875E-38 then
        local v26 = math.abs(p12) * 7.1362384635298E+44
        local v27 = math.floor(v26)
        local v28 = v26 - v27

        v25 = (if v28 > 0.5 or v28 == 0.5 and v27 % 2 == 1 then v27 + 1 else v27) * 1.401298464324817E-45

        if p12 < 0 then
            v25 = -v25
        end
    else
        buffer.writef32(v1, 0, p12)
        v25 = buffer.readf32(v1, 0)
    end

    local v29

    if p13 ~= 0 and p13 > -1.1754943508222875E-38 and p13 < 1.1754943508222875E-38 then
        local v30 = math.abs(p13) * 7.1362384635298E+44
        local v31 = math.floor(v30)
        local v32 = v30 - v31

        v29 = (if v32 > 0.5 or v32 == 0.5 and v31 % 2 == 1 then v31 + 1 else v31) * 1.401298464324817E-45

        if p13 < 0 then
            v29 = -v29
        end
    else
        buffer.writef32(v1, 0, p13)
        v29 = buffer.readf32(v1, 0)
    end

    if not (v25 - 0.01 >= 0) then
        v25 = 0.01
    end

    if not (v29 - 0.01 >= 0) then
        v29 = 0.01
    end

    local v33

    if v25 ~= 0 and v25 > -1.1754943508222875E-38 and v25 < 1.1754943508222875E-38 then
        local v34 = math.abs(v25) * 7.1362384635298E+44
        local v35 = math.floor(v34)
        local v36 = v34 - v35

        v33 = if v36 > 0.5 or v36 == 0.5 and v35 % 2 == 1 then v35 + 1 else v35

        if v25 < 0 then
            v33 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v25)
        v33 = buffer.readu32(v1, 0)
    end

    local v37

    if v29 ~= 0 and v29 > -1.1754943508222875E-38 and v29 < 1.1754943508222875E-38 then
        local v38 = math.abs(v29) * 7.1362384635298E+44
        local v39 = math.floor(v38)
        local v40 = v38 - v39

        v37 = if v40 > 0.5 or v40 == 0.5 and v39 % 2 == 1 then v39 + 1 else v39

        if v29 < 0 then
            v37 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v29)
        v37 = buffer.readu32(v1, 0)
    end

    local v41 = v12.cos(v25)
    local v42

    if v41 ~= 0 and v41 > -1.1754943508222875E-38 and v41 < 1.1754943508222875E-38 then
        local v43 = math.abs(v41) * 7.1362384635298E+44
        local v44 = math.floor(v43)
        local v45 = v43 - v44

        v42 = if v45 > 0.5 or v45 == 0.5 and v44 % 2 == 1 then v44 + 1 else v44

        if v41 < 0 then
            v42 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v41)
        v42 = buffer.readu32(v1, 0)
    end

    local v46 = v12.cos(v29)
    local v47

    if v46 ~= 0 and v46 > -1.1754943508222875E-38 and v46 < 1.1754943508222875E-38 then
        local v48 = math.abs(v46) * 7.1362384635298E+44
        local v49 = math.floor(v48)
        local v50 = v48 - v49

        v47 = if v50 > 0.5 or v50 == 0.5 and v49 % 2 == 1 then v49 + 1 else v49

        if v46 < 0 then
            v47 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v46)
        v47 = buffer.readu32(v1, 0)
    end

    return {
        v33,
        v37,
        v42,
        v47
    }
end

t1.limits = limits

return t1
