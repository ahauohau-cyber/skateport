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
local LaunchInfo = import("skate_core/air/trajectory").LaunchInfo
local t1 = {
    AirSettings = {}
}

function t1.AirSettings.load(p2) -- line: 24
    -- upvalues: rt (copy), Collections (copy)
    local v2 = rt.map(Collections.words(p2, 16, "physics_airstates", "default", "BodySpinInputFilter"), rt.from_bits)

    local function f(p3) -- line: 27
        -- upvalues: p2 (copy), Collections (copy)
        return Collections.float(p2, "physics_airstates", "default", p3)
    end

    local v3 = table.create(5, 0)

    for v4, v5 in { "easy", "normal", "hardcore", "motorized", "test" } do
        v3[v4] = Collections.float(p2, "physics_mode", v5, "GrindLockDist")
    end

    local t2 = {
        body_spin_over_time_320 = {
            x = rt.slice(v2, 0, 8),
            y = rt.slice(v2, 8)
        }
    }

    t2.landing_normal_blend_388 = Collections.float(p2, "physics_airstates", "default", "SpeedToAlignToGround_PhysAir")
    t2.body_spin_scale_428 = Collections.float(p2, "physics_airstates", "default", "MaxSpinSpeed")
    t2.landing_normal_angle_limit_444 = Collections.float(p2, "physics_airstates", "default", "DontAlignAnglePhysicsAir")

    return {
        state = t2,
        steering_blend = Collections.float(p2, "physics_steering", "default", "SteeringTiltBlending"),
        grind_lock_distance = v3
    }
end

function t1.frame(p4) -- line: 52
    -- upvalues: rt (copy), v1 (copy)
    local processed = p4.player_input.processed
    local t3 = {
        current_velocity_400 = rt.map(processed.vectors_400_416[1], rt.from_bits)
    }

    buffer.writeu32(v1, 0, processed.vectors_464_480_496_512_528[3][2])
    t3.ground_position_y_500 = buffer.readf32(v1, 0)
    t3.trajectory_position_592 = rt.map(processed.vectors_544_560_592_608[3], rt.from_bits)
    t3.trajectory_velocity_608 = rt.map(processed.vectors_544_560_592_608[4], rt.from_bits)
    t3.jump_velocity_848 = rt.map(p4.player_state.post.jump_reference, rt.from_bits)
    t3.flags_2468 = processed.flags_2468
    t3.previous_physics_state_2504 = rt.to_i32(processed.state_2504)
    t3.previous_physics_category_2516 = rt.to_i32(processed.category_2516)
    t3.frames_since_jump_correction_2576 = rt.to_i32(p4.player_state.post.jump_fix_frames)
    t3.delta_time_2604 = processed.timestep_2604
    t3.body_spin_input_2640 = p4.animation_input.fields.body_spin
    t3.gravity_y_2648 = processed.gravity_2648
    t3.state_timer_2664 = processed.state_timer_2664

    return t3
end

function t1.selector_input(p5, p6) -- line: 72
    -- upvalues: rt (copy), v1 (copy)
    local processed = p6.player_input.processed
    local gravity_acceleration = p5.settings.step.simulation.gravity_acceleration
    local t4 = {
        gravity = {
            gravity_acceleration.x,
            gravity_acceleration.y,
            gravity_acceleration.z,
            0
        },
        ground_normal = rt.map(processed.vectors_464_480_496_512_528[1], rt.from_bits),
        contact_position = rt.map(processed.vectors_464_480_496_512_528[3], rt.from_bits),
        heading_direction = rt.map(processed.vectors_464_480_496_512_528[4], rt.from_bits),
        reference_up = rt.map(processed.vectors_544_560_592_608[1], rt.from_bits)
    }

    buffer.writeu32(v1, 0, processed.vectors_400_416[1][2])
    t4.board_vertical_velocity = buffer.readf32(v1, 0)
    t4.directional_input = processed.transition_2636
    t4.previous_physics_state = processed.state_2504
    t4.flags_2472 = processed.flags_2472
    t4.flags_2476 = processed.flags_2476
    t4.offboard_flags_1776 = processed.external_physics_1616.flags

    local v8 = p6.air_settings.grind_lock_distance[processed.state_variant_index_2528 + 1]

    if v8 == nil then
        error(string.format("Invalid trajectory physics mode %d", processed.state_variant_index_2528), 0)
    end

    t4.grind_lock_distance = v8

    return t4
end

function t1.launch_info(p7, p8) -- line: 97
    -- upvalues: rt (copy), LaunchInfo (copy)
    local processed, toolkit = p8.player_input.processed, p8.player_input.toolkit

    if toolkit == nil then
        error("Air launch requires current BoardToolkit", 0)
    end

    local v9 = LaunchInfo.default()

    v9.reckoning_transform = rt.copy(p7.riding.reckoning_frames.system)
    v9.reckoning_inverse = rt.copy(p7.riding.reckoning_frames.inverse_system)
    v9.start_velocity = rt.map(processed.vectors_400_416[1], rt.from_bits)
    v9.com_velocity = rt.map(processed.prepared_jump_704, rt.from_bits)
    v9.skeleton_vector_160 = rt.copy(p8.animated_skeleton.board_frames.local_centre_of_mass)
    v9.skeleton_vector_176 = rt.copy(p8.animated_skeleton.board_frames.local_board_position)
    v9.board_position = rt.copy(toolkit.deck[4])
    v9.animation_com_position = rt.map(processed.vectors_544_560_592_608[3], rt.from_bits)
    v9.cone_angle_x = p8.trajectory.settings.cone_x
    v9.cone_angle_z = p8.trajectory.settings.cone_z
    v9.timestep = processed.timestep_2604
    v9.trajectory_count = bit32.band(processed.flags_2468, 8192) == 0 and 1 or 7

    return v9
end

return t1
