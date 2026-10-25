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
local v2 = import("skate_game/physics/ground_runtime/corrections")
local v3 = import("skate_game/physics/ground_runtime/entry")
local v4 = import("skate_game/physics/ground_runtime/state")
local v5 = import("skate_game/physics/ground_runtime/update")
local v6 = import("skate_game/physics/ground_runtime/input")
local v7 = import("skate_game/physics/ground_runtime/pumping")
local v8 = import("skate_game/physics/ground_runtime/launch")
local v9 = import("skate_game/physics/ground_runtime/services")
local v10 = import("skate_game/physics/ground_runtime/settings")
local v11 = import("skate_game/physics/ground_runtime/surface")
local Vector3 = import("skate_core/math").Vector3
local BodyId = import("skate_core/physics/board").BodyId
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime
local v12 = import("skate_core/physics/deck_angular_correction")
local QueuedPointForce = import("skate_core/physics/force_queue").QueuedPointForce
local collision_response = import("skate_core/riding/collision_response").collision_response
local wall_ride_response = import("skate_core/riding/ground_contact_response").wall_ride_response
local Collections = import("skate_data/collections").Collections
local t1 = {
    GroundEntryTargets = v3.GroundEntryTargets,
    GroundState = v4.GroundState,
    GroundUpdateFrame = v5.GroundUpdateFrame,
    GroundUpdateTargets = v5.GroundUpdateTargets,
    GroundInputObservations = v6.GroundInputObservations,
    GroundPumping = v7.GroundPumping,
    GroundLaunchInfo = v8.GroundLaunchInfo,
    GroundLaunchPhysical = v8.GroundLaunchPhysical,
    GroundControllers = v9.GroundControllers,
    GroundPhysicalFrame = v9.GroundPhysicalFrame,
    GroundSettings = v10.GroundSettings,
    GroundProfiles = v10.GroundProfiles
}
local curve, xyz

t1.GroundRuntime = {}

function t1.GroundRuntime.reset_board_toolkit(p2) -- line: 82
    p2.retained_board_normal = { 0, 1, 0, 0 }
end

function t1.GroundRuntime.load(p3) -- line: 86
    -- upvalues: QueuedPointForce (copy), Collections (copy), curve (ref)
    local function feet(p4) -- line: 87
        -- upvalues: p3 (copy), Collections (copy)
        return Collections.float(p3, "physics_feet", "default", p4)
    end

    local function collision(p5) -- line: 90
        -- upvalues: p3 (copy), Collections (copy)
        return Collections.float(p3, "physics_collision", "default", p5)
    end

    local t2 = {
        retained_board_normal = { 0, 1, 0, 0 },
        launch_cone_x = Collections.float(p3, "physics_trajectory", "default", "ConeAngleX"),
        launch_cone_z = Collections.float(p3, "physics_trajectory", "default", "ConeAngleZ"),
        deck_center_to_truck = Collections.float(p3, "physics_grinds", "default", "DeckCenterToTruck"),
        wall_ride = {
            anti_gravity_vs_time = curve(p3, "physics_feet", "WallRideAntiGravityVsTime"),
            max_dot_floor_wall = Collections.float(p3, "physics_feet", "default", "WallRideMaxDotFloorWall"),
            foot_force_time = Collections.float(p3, "physics_feet", "default", "WallRideFootForceTime"),
            auto_jump_height = Collections.float(p3, "physics_feet", "default", "WallRideAutoJumpHeight"),
            max_time = Collections.float(p3, "physics_feet", "default", "WallRideMaxTime"),
            velocity_time_to_consider = Collections.float(p3, "physics_feet", "default", "WallRideVelTimeToConsider"),
            auto_jump_y_down_scalar = Collections.float(p3, "physics_feet", "default", "WallRideAutoJumpYDownScalar"),
            auto_jump_force = Collections.float(p3, "physics_feet", "default", "WallRideAutoJumpForce")
        },
        collision = {
            maximum_velocity_delta = Collections.float(p3, "physics_collision", "default", "MaxVelDelta"),
            force_y_offset = Collections.float(p3, "physics_collision", "default", "ForceYOffset"),
            force_scalar = Collections.float(p3, "physics_collision", "default", "CollisionForceScalar"),
            target_displacement_velocity = Collections.float(p3, "physics_collision", "default", "TargetDisplacementVel"),
            torque_vs_angle = curve(p3, "physics_collision", "CollisionTorqueVsAngle")
        }
    }
    local v13 = QueuedPointForce.default()

    v13.tag = 16
    t2.contact = {
        active_2731 = false,
        scalar_2704 = 0,
        animated_board_2708 = false,
        tag_16_force = v13,
        vector_2688 = { 0, 0, 0, 0 }
    }
    t2.collision_force = nil

    return t2
end

function t1.GroundRuntime.contact_response_with_previous(p6, p7, p8, p9) -- line: 138
    -- upvalues: wall_ride_response (copy)
    return wall_ride_response(p6.wall_ride, p8, p7, p9)
end

function t1.GroundRuntime.update_body_accumulator(_, p11) -- line: 144
    -- upvalues: BodyId (copy), BoardRuntime (copy), v12 (copy)
    v12.apply_ground_body_torque(BoardRuntime.bodies_mut(p11)[BodyId.index(BodyId.Deck) + 1].rates)
end

function t1.GroundRuntime.calculate_collision_force(p12, p13) -- line: 153
    -- upvalues: rt (copy), collision_response (copy)
    local v14 = collision_response(p12.collision, p13)

    if v14 == nil or not v14.applied then
        return nil
    end

    local t3 = {
        force_2528 = rt.copy(v14.force),
        point_2544 = rt.copy(v14.point),
        vector_2592 = rt.copy(v14.angular_displacement)
    }

    p12.collision_force = rt.copy(t3)

    return t3
end

function t1.GroundRuntime.apply_angular_target(_, p15, p16) -- line: 170
    -- upvalues: BodyId (copy), BoardRuntime (copy), v12 (copy), xyz (ref)
    v12.apply_limited_displacement(BoardRuntime.bodies_mut(p15)[BodyId.index(BodyId.Deck) + 1].rates, xyz(p16))
end

function t1.GroundRuntime.apply_angular_displacement(_, p18, p19) -- line: 177
    -- upvalues: BodyId (copy), BoardRuntime (copy), v12 (copy), xyz (ref)
    v12.apply_angular_displacement(BoardRuntime.bodies_mut(p18)[BodyId.index(BodyId.Deck) + 1].rates, xyz(p19))
end

function t1.GroundRuntime.set_animated_velocity(_, p21, p22) -- line: 186
    -- upvalues: BoardRuntime (copy), xyz (ref)
    local v15 = BoardRuntime.bodies_mut(p21)

    for i = 1, #v15 do
        v15[i].rates.linear_velocity = xyz(p22)
    end
end

function curve(p23, p24, p25) -- line: 194
    -- upvalues: v1 (copy), Collections (copy)
    local v16 = Collections.words(p23, p24, "default", p25, 20)
    local t4 = {}

    buffer.writeu32(v1, 0, v16[5])

    local v18 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v16[6])

    local v20 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v16[7])

    local v22 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v16[8])

    local v24 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v16[9])

    local v26 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v16[10])

    local v28 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v16[11])

    local v30 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v16[12])
    t4.x = {
        v18,
        v20,
        v22,
        v24,
        v26,
        v28,
        v30,
        (buffer.readf32(v1, 0))
    }
    buffer.writeu32(v1, 0, v16[13])

    local v33 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v16[14])

    local v35 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v16[15])

    local v37 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v16[16])

    local v39 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v16[17])

    local v41 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v16[18])

    local v43 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v16[19])

    local v45 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v16[20])
    t4.y = {
        v33,
        v35,
        v37,
        v39,
        v41,
        v43,
        v45,
        (buffer.readf32(v1, 0))
    }

    return t4
end

t1.curve = curve

function xyz(p26) -- line: 221
    -- upvalues: Vector3 (copy)
    return Vector3.new(p26[1], p26[2], p26[3])
end

t1.xyz = xyz

for v47, v48 in v2.GroundRuntime do
    t1.GroundRuntime[v47] = v48
end

for v49, v50 in v6.GroundRuntime do
    t1.GroundRuntime[v49] = v50
end

for v51, v52 in v9.GroundRuntime do
    t1.GroundRuntime[v51] = v52
end

t1.active_surface = v11.active_surface
t1.surface_key = v11.surface_key

return t1
