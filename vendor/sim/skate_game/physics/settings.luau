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
local v2 = import("skate_core/physics/drive_frames")
local authored_body_transforms, calculate_truck_transforms = v2.authored_body_transforms, v2.calculate_truck_transforms
local retail_truck_drive_dynamics = import("skate_core/physics/drive_parameters").retail_truck_drive_dynamics
local v3 = import("skate_core/physics/mass")
local DeckGeometry, deck_mass_properties, truck_mass_input, truck_mass_properties = v3.DeckGeometry, v3.deck_mass_properties, v3.truck_mass_input, v3.truck_mass_properties
local wheel_mass_properties = v3.wheel_mass_properties
local RetailSimulationStep = import("skate_core/physics/rigid_body").RetailSimulationStep
local Collections = import("skate_data/collections").Collections
local t1 = {
    PhysicsSettings = {}
}

function t1.PhysicsSettings.load(p2) -- line: 55
    -- upvalues: rt (copy), v1 (copy), Vector3 (copy), authored_body_transforms (copy), calculate_truck_transforms (copy), retail_truck_drive_dynamics (copy), DeckGeometry (copy), deck_mass_properties (copy), truck_mass_input (copy), truck_mass_properties (copy), wheel_mass_properties (copy), RetailSimulationStep (copy), Collections (copy)
    local function f(p3, p4) -- line: 56
        -- upvalues: p2 (copy), Collections (copy)
        return Collections.float(p2, p3, "default", p4)
    end

    local function b(p5, p6) -- line: 59
        -- upvalues: p2 (copy), Collections (copy)
        return Collections.boolean(p2, p5, "default", p6)
    end

    local SkateboardMassFactor = Collections.float(p2, "physics_world", "default", "SkateboardMassFactor")
    local WheelRadius = Collections.float(p2, "physicswheels", "default", "WheelRadius")
    local WheelXDist = Collections.float(p2, "physicswheels", "default", "WheelXDist")
    local t2 = {
        deck_mid_length = Collections.float(p2, "physicsdeck", "default", "DeckMidLength"),
        wheel_x_distance = WheelXDist,
        truck_z_position_front = Collections.float(p2, "physicstrucks", "default", "TruckZPosFront"),
        truck_z_position_back = Collections.float(p2, "physicstrucks", "default", "TruckZPosBack"),
        truck_y_position = Collections.float(p2, "physicstrucks", "default", "TruckYPos")
    }
    local v4 = wheel_mass_properties({
        radius = WheelRadius,
        mass = Collections.float(p2, "physicswheels", "default", "WheelMass"),
        mass_factor = SkateboardMassFactor
    })
    local t3 = {
        wheel_radius = WheelRadius,
        wheel_x_distance = WheelXDist,
        mass_factor = SkateboardMassFactor,
        radius_scalar = Collections.float(p2, "physicstrucks", "default", "RadiusScalar"),
        half_height_scalar = Collections.float(p2, "physicstrucks", "default", "HalfHeightScalar"),
        mass = Collections.float(p2, "physicstrucks", "default", "TruckMass")
    }
    local v5 = truck_mass_properties(rt.copy(t3))
    local v6 = Collections.words(p2, "physics", "default", "WorldGravity", 4)

    buffer.writeu32(v1, 0, v6[1])

    local v8 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v6[2])

    local v10 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v6[3])

    local v12 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v6[4])

    local t4 = {
        v8,
        v10,
        v12,
        (buffer.readf32(v1, 0))
    }
    local v14 = RetailSimulationStep.fixed_60_hz(0, Collections.float(p2, "physics", "default", "FreezingEnergy"), Vector3.new(t4[1], t4[2], t4[3]))
    local DeckWidth = Collections.float(p2, "physicsdeck", "default", "DeckWidth")
    local DeckThickness = Collections.float(p2, "physicsdeck", "default", "DeckThickness")
    local DeckBackEndSize = Collections.float(p2, "physicsdeck", "default", "DeckBackEndSize")
    local DeckFrontEndAngle = Collections.float(p2, "physicsdeck", "default", "DeckFrontEndAngle")
    local DeckBackEndAngle = Collections.float(p2, "physicsdeck", "default", "DeckBackEndAngle")
    local v15 = rt.to_i32(Collections.integer(p2, "physicsdeck", "default", "DeckEndCapsules"))
    local DeckEnableDeckVolumeCollisions = Collections.boolean(p2, "physicsdeck", "default", "DeckEnableDeckVolumeCollisions")
    local DeckEnableEndVolumeCollisions = Collections.boolean(p2, "physicsdeck", "default", "DeckEnableEndVolumeCollisions")
    local v16 = DeckGeometry.new({
        width = DeckWidth,
        mid_length = t2.deck_mid_length,
        thickness = DeckThickness,
        back_end_size = DeckBackEndSize,
        front_end_angle_degrees = DeckFrontEndAngle,
        back_end_angle_degrees = DeckBackEndAngle,
        end_capsule_count = v15,
        enable_deck_volume_collisions = DeckEnableDeckVolumeCollisions,
        enable_end_volume_collisions = DeckEnableEndVolumeCollisions
    })
    local v19 = deck_mass_properties(v16, Collections.float(p2, "physicsdeck", "default", "DeckMass") * SkateboardMassFactor, Collections.float(p2, "physicsdeck", "default", "DeckAngularDrag") * v14.frequency)
    local RWMaxIterations = Collections.integer(p2, "physics", "default", "RWMaxIterations")
    local v20 = calculate_truck_transforms({
        deck_mid_length = t2.deck_mid_length,
        truck_z_position_front = t2.truck_z_position_front,
        truck_z_position_back = t2.truck_z_position_back,
        truck_y_position = t2.truck_y_position,
        truck_rotation_axis_angle_degrees = Collections.float(p2, "physicstrucks", "default", "TruckRotationAxisAngle")
    })
    local v21 = retail_truck_drive_dynamics({
        use_linear_drives = Collections.boolean(p2, "physicstrucks", "default", "UseTruckDrives"),
        use_hard_linear_drives = Collections.boolean(p2, "physicsdeck", "default", "UseHardDrives"),
        angular_displacement = Collections.float(p2, "physicstrucks_drives", "default", "Angular_Hard_Displacement"),
        angular_damping = Collections.float(p2, "physicstrucks_drives", "default", "Angular_Hard_Damping"),
        angular_strength = Collections.float(p2, "physicstrucks_drives", "default", "Angular_Hard_Strength")
    })
    local DeckForceYOffset = Collections.float(p2, "physicsdeck", "default", "DeckForceYOffset")
    local t5 = {
        simulation = rt.copy(v14),
        iterations = RWMaxIterations,
        base_truck_transforms = v20,
        truck_dynamics = v21,
        force_point_y_offset = DeckForceYOffset
    }

    if WheelRadius <= 0 or SkateboardMassFactor <= 0 or t5.iterations == 0 then
        error("Invalid stock board radius, mass factor or solver iterations", 0)
    end

    return {
        step = t5,
        masses = {
            rt.copy(v4),
            rt.copy(v4),
            rt.copy(v4),
            rt.copy(v4),
            rt.copy(v5),
            rt.copy(v5),
            rt.copy(v19)
        },
        authored = authored_body_transforms(rt.copy(t2)),
        deck_geometry = v16,
        truck_shape = rt.copy(truck_mass_input(rt.copy(t3)).shape),
        truck_collisions = Collections.boolean(p2, "physicstrucks", "default", "TruckEnableVolumeCollisions"),
        truck_material = {
            static_friction = Collections.float(p2, "physicstrucks", "default", "TruckStaticFriction"),
            dynamic_friction = Collections.float(p2, "physicstrucks", "default", "TruckDynamicFriction"),
            restitution = Collections.float(p2, "physicstrucks", "default", "TruckRestitution")
        },
        deck_material = {
            static_friction = Collections.float(p2, "physicsdeck", "default", "DeckStaticFriction"),
            dynamic_friction = Collections.float(p2, "physicsdeck", "default", "DeckDynamicFriction"),
            restitution = Collections.float(p2, "physicsdeck", "default", "DeckRestitution")
        },
        wheel_radius = WheelRadius,
        wheel_material = {
            static_friction = Collections.float(p2, "physicswheels", "default", "WheelStaticFriction"),
            dynamic_friction = Collections.float(p2, "physicswheels", "default", "WheelDynamicFriction"),
            restitution = Collections.float(p2, "physicswheels", "default", "WheelRestitution")
        },
        standard_wheel_material = {
            static_friction = Collections.float(p2, "physicswheels", "default", "WheelStaticFriction"),
            dynamic_friction = Collections.float(p2, "physicswheels", "default", "WheelDynamicFriction"),
            restitution = Collections.float(p2, "physicswheels", "default", "WheelRestitution")
        },
        floor_material = {
            static_friction = 0,
            dynamic_friction = 0,
            restitution = 1
        },
        input_magnitude_threshold = Collections.float(p2, "inputlistener", "default", "StickMagnitudeMinToCountHeld")
    }
end

return t1
