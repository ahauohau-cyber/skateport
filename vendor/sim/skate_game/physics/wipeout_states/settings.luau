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

local Collections = require(sim.import)("skate_data/collections").Collections
local t1 = {
    Settings = {}
}

function t1.Settings.load(p2) -- line: 35
    -- upvalues: Collections (copy), t1 (copy)
    local function f(p3) -- line: 36
        -- upvalues: p2 (copy), Collections (copy)
        return Collections.float(p2, "physics_wipeout", "default", p3)
    end

    return {
        recovery = {
            minimum_time = Collections.float(p2, "physics_wipeout", "default", "TeleportMinTimeForAutoReset"),
            minimum_settled = Collections.float(p2, "physics_wipeout", "default", "TeleportMinTimeAfterSettlingForAutoReset"),
            maximum_time = Collections.float(p2, "physics_wipeout", "default", "TeleportMaxTime"),
            fade_time = Collections.float(p2, "physics_wipeout", "default", "TeleportAutoResetFadeOutTime"),
            over_speed = Collections.float(p2, "physics_wipeout", "default", "WipeoutOverSpeed"),
            over_minimum_time = Collections.float(p2, "physics_wipeout", "default", "WipeoutOverMinTime")
        },
        remove_target_time = Collections.float(p2, "physics_wipeout", "default", "TimeToRemoveHook"),
        remove_drives_time = Collections.float(p2, "physics_wipeout", "default", "TimeToRemoveDrives"),
        controlled_weight_step = Collections.float(p2, "physics_wipeout", "default", "DynamicDriveWeightVelControlled"),
        collision_weight_step = Collections.float(p2, "physics_wipeout", "default", "DynamicDriveWeightVelCollision"),
        board_restitution = Collections.float(p2, "physics_wipeout", "default", "SkateboardRestitution"),
        board_friction = Collections.float(p2, "physics_wipeout", "default", "SkateboardFriction"),
        deck_angular_drag = Collections.float(p2, "physicsdeck", "default", "DeckAngularDrag") * 59.999996185302734,
        push_force = Collections.float(p2, "physics_wipeout", "default", "LivingWorldPushForce"),
        standard_materials = {
            t1.material(p2, "physicswheels", "Wheel"),
            t1.material(p2, "physicstrucks", "Truck"),
            (t1.material(p2, "physicsdeck", "Deck"))
        }
    }
end

function t1.material(p4, p5, p6) -- line: 73
    -- upvalues: Collections (copy)
    return {
        static_friction = Collections.float(p4, p5, "default", string.format("%sStaticFriction", p6)),
        dynamic_friction = Collections.float(p4, p5, "default", string.format("%sDynamicFriction", p6)),
        restitution = Collections.float(p4, p5, "default", string.format("%sRestitution", p6))
    }
end

function t1.load_profile(p7, p8) -- line: 87
    -- upvalues: rt (copy), v1 (copy), Collections (copy)
    local function f(p9) -- line: 89
        -- upvalues: p7 (copy), p8 (copy), Collections (copy)
        return Collections.float(p7, "physics_wipeout_control", p8, p9)
    end

    local function b(p10) -- line: 92
        -- upvalues: p7 (copy), p8 (copy), Collections (copy)
        return Collections.boolean(p7, "physics_wipeout_control", p8, p10)
    end

    local function v(p11) -- line: 95
        -- upvalues: p7 (copy), p8 (copy), rt (copy), Collections (copy)
        return rt.map(Collections.words(p7, "physics_wipeout_control", p8, p11, 4), rt.from_bits)
    end

    local v2 = Collections.words(p7, "physics_wipeout_control", p8, "SpinVsTime", 20)
    local t2 = {
        roll_axis = rt.map(Collections.words(p7, "physics_wipeout_control", p8, "RollOnGroundAxis", 4), rt.from_bits),
        horizontal_axis = rt.map(Collections.words(p7, "physics_wipeout_control", p8, "HorizAlignAxis", 4), rt.from_bits),
        align_euler = rt.map(Collections.words(p7, "physics_wipeout_control", p8, "AlignAxisEuler", 4), rt.from_bits)
    }
    local t3 = {}

    buffer.writeu32(v1, 0, v2[5])

    local v4 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[6])

    local v6 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[7])

    local v8 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[8])

    local v10 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[9])

    local v12 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[10])

    local v14 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[11])

    local v16 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[12])
    t3.x = {
        v4,
        v6,
        v8,
        v10,
        v12,
        v14,
        v16,
        (buffer.readf32(v1, 0))
    }
    buffer.writeu32(v1, 0, v2[13])

    local v19 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[14])

    local v21 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[15])

    local v23 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[16])

    local v25 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[17])

    local v27 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[18])

    local v29 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[19])

    local v31 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v2[20])
    t3.y = {
        v19,
        v21,
        v23,
        v25,
        v27,
        v29,
        v31,
        (buffer.readf32(v1, 0))
    }
    t2.spin_vs_time = t3
    t2.direction_follow = Collections.float(p7, "physics_wipeout_control", p8, "Hash_1BC908CDB3520A8E")
    t2.torque_velocity = Collections.float(p7, "physics_wipeout_control", p8, "TorqueVelScalar")
    t2.torque_distance = Collections.float(p7, "physics_wipeout_control", p8, "TorqueDistScalar")
    t2.spin_inertia = Collections.float(p7, "physics_wipeout_control", p8, "SpinInertia")
    t2.roll_on_ground = Collections.boolean(p7, "physics_wipeout_control", p8, "RollOnGround")
    t2.ground_roll_torque = Collections.float(p7, "physics_wipeout_control", p8, "RollingOnGroundTorqueVelScalar")
    t2.sideways_spin = Collections.float(p7, "physics_wipeout_control", p8, "Hash_40B2B3C1A87A4D76")
    t2.forward_spin = Collections.float(p7, "physics_wipeout_control", p8, "Hash_9047531918285FC3")
    t2.horizontal_directed = Collections.boolean(p7, "physics_wipeout_control", p8, "Hash_6009FD75F9EDC436")
    t2.drift_maximum_speed = Collections.float(p7, "physics_wipeout_control", p8, "DriftMaxSpeed")
    t2.drift_forward = Collections.float(p7, "physics_wipeout_control", p8, "DriftFactorZ")
    t2.drift_sideways = Collections.float(p7, "physics_wipeout_control", p8, "DriftFactorX")
    t2.align_with_velocity = Collections.boolean(p7, "physics_wipeout_control", p8, "AlignWithVel")
    t2.align_ground_with_velocity = Collections.boolean(p7, "physics_wipeout_control", p8, "Hash_9626703A9939FE36")
    t2.ground_align_torque = Collections.float(p7, "physics_wipeout_control", p8, "AlignOnGroundTorqueVelScalar")
    t2.tilt_degrees = Collections.float(p7, "physics_wipeout_control", p8, "Hash_B65276A8CC7FB760")
    t2.drift_drag = Collections.float(p7, "physics_wipeout_control", p8, "Hash_7E6B3A99C0A33ABC")

    return t2
end

return t1
