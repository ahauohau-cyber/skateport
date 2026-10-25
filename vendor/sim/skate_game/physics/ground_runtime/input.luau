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
local RidingOutputs = import("skate_game/physics/riding_outputs").RidingOutputs
local BoardProbes = import("skate_game/physics/riding_outputs/probes").BoardProbes
local Vector3 = import("skate_core/math").Vector3
local BoardToolkit = import("skate_core/physics/board_toolkit").BoardToolkit
local dot_product = import("skate_core/riding/ground_correction_math").dot_product
local raw, xyz, v, push_target
local t1 = {}

t1.GroundInputObservations = {}
t1.GroundRuntime = {}

function t1.GroundRuntime.prepare_toolkit(p2, p3, p4) -- line: 51
    -- upvalues: rt (copy), BoardToolkit (copy), raw (ref)
    local v2 = BoardToolkit.from_board(p3, p4.flags_2468, p4.scalar_2612, raw(p4.vectors_464_480_496_512_528[1]), rt.copy(p2.retained_board_normal))

    p2.retained_board_normal = rt.copy(v2.filtered_normal)

    return v2
end

t1.GroundSettings = {}

local v3 = false

function t1.set_input_x2(p5) -- line: 106
    -- upvalues: v3 (ref)
    v3 = p5
end

local from_bits = rt.from_bits
local self = setmetatable({}, {
    __mode = "k"
})

local function new_pool(p6) -- line: 111
    -- upvalues: Vector3 (copy)
    return {
        out = p6,
        vectors = {
            local_normal = { 0, 0, 0, 0 },
            local_velocity = { 0, 0, 0, 0 },
            local_angular = { 0, 0, 0, 0 },
            local_axis544 = { 0, 0, 0, 0 },
            local_ground_normal = { 0, 0, 0, 0 },
            local_edge_delta = { 0, 0, 0, 0 },
            local_hang_axis = { 0, 0, 0, 0 },
            top_ground_vector_1216 = { 0, 0, 0, 0 },
            propulsion_push_direction = Vector3.new(0, 0, 0),
            propulsion_brake_direction = Vector3.new(0, 0, 0),
            ground_force_axis_384 = { 0, 0, 0, 0 },
            ground_force_velocity_400 = { 0, 0, 0, 0 },
            ground_force_axis_544 = { 0, 0, 0, 0 },
            speed_model_vector_160 = { 0, 0, 0, 0 },
            speed_model_vector_352 = { 0, 0, 0, 0 },
            speed_model_velocity_416 = { 0, 0, 0, 0 },
            speed_model_normal_464 = { 0, 0, 0, 0 },
            speed_model_effective_forward = { 0, 0, 0, 0 },
            slide_friction_normal = { 0, 0, 0, 0 },
            slide_friction_velocity = { 0, 0, 0, 0 },
            slide_friction_side_axis = { 0, 0, 0, 0 },
            pump_force_direction_432 = { 0, 0, 0, 0 },
            pump_force_normal_threshold = { 0, 0, 0, 0 },
            straighten_forward = { 0, 0, 0, 0 },
            straighten_velocity = { 0, 0, 0, 0 },
            straighten_normal = { 0, 0, 0, 0 },
            heading_velocity = { 0, 0, 0, 0 },
            heading_normal = { 0, 0, 0, 0 },
            heading_angular_velocity = { 0, 0, 0, 0 },
            heading_transform = {},
            heading_transform_rows = {
                { 0, 0, 0, 0 },
                { 0, 0, 0, 0 },
                { 0, 0, 0, 0 },
                { 0, 0, 0, 0 }
            },
            anti_flip_axis_96 = { 0, 0, 0, 0 },
            anti_flip_axis_64 = { 0, 0, 0, 0 },
            anti_flip_projection_axis_544 = { 0, 0, 0, 0 },
            manual_reference_x = { 0, 0, 0, 0 },
            manual_reference_z = { 0, 0, 0, 0 },
            manual_deck_z = { 0, 0, 0, 0 },
            manual_velocity_frame_z = { 0, 0, 0, 0 },
            manual_angular_velocity_world = { 0, 0, 0, 0 },
            manual_correction_point_7888 = { 0, 0, 0, 0 },
            manual_correction_point_7952 = { 0, 0, 0, 0 },
            anti_flip_nudge_deck_axis_96 = { 0, 0, 0, 0 }
        },
        propulsion = p6.propulsion,
        ground_force = p6.ground_force,
        speed_model = p6.speed_model,
        slide_friction = p6.slide_friction,
        pump_force = p6.pump_force,
        straighten = p6.straighten,
        heading = p6.heading,
        anti_flip = p6.anti_flip,
        manual = p6.manual,
        anti_flip_nudge = p6.anti_flip_nudge,
        steering = p6.steering,
        speed_wobble = p6.speed_wobble,
        ground_drag = p6.ground_drag,
        hang_up = p6.hang_up,
        halfpipe_wheel_catch = p6.halfpipe_wheel_catch,
        pinning = p6.pinning
    }
end

function t1.GroundSettings.input(p7, p8, p9, p10, p11, p12, p13, p14, p15, p16) -- line: 178
    -- upvalues: rt (copy), RidingOutputs (copy), BoardProbes (copy), dot_product (copy), t1 (copy), push_target (ref), v3 (ref), from_bits (copy), self (copy), new_pool (copy)
    if v3 then
        return t1.GroundSettings.input_x2(p7, p8, p9, p10, p11, p12, p13, p14, p15, p16)
    end

    local fields = p10.fields
    local v5 = self[p7]

    if v5 == nil then
        v5 = new_pool(t1.GroundSettings.input_x2(p7, p8, p9, p10, p11, p12, p13, p14, p15, p16))
        self[p7] = v5
    end

    local vectors, out = v5.vectors, v5.out

    table.clear(out)

    local local_normal = vectors.local_normal
    local v6 = p9.vectors_464_480_496_512_528[1]
    local local_velocity = from_bits(v6[1])
    local local_angular = from_bits(v6[2])
    local local_axis544 = from_bits(v6[3])
    local local_ground_normal = from_bits(v6[4])

    local_normal[1] = local_velocity
    local_normal[2] = local_angular
    local_normal[3] = local_axis544
    local_normal[4] = local_ground_normal
    local_velocity = vectors.local_velocity
    v6 = p9.vectors_400_416[1]
    local_angular = from_bits(v6[1])
    local_axis544 = from_bits(v6[2])
    local_ground_normal = from_bits(v6[3])

    local ground = from_bits(v6[4])

    local_velocity[1] = local_angular
    local_velocity[2] = local_axis544
    local_velocity[3] = local_ground_normal
    local_velocity[4] = ground
    local_angular = vectors.local_angular
    v6 = p9.vectors_400_416[2]
    local_axis544 = from_bits(v6[1])
    local_ground_normal = from_bits(v6[2])
    ground = from_bits(v6[3])

    local local_edge_delta = from_bits(v6[4])

    local_angular[1] = local_axis544
    local_angular[2] = local_ground_normal
    local_angular[3] = ground
    local_angular[4] = local_edge_delta
    local_axis544 = vectors.local_axis544
    v6 = p9.vectors_544_560_592_608[1]
    local_ground_normal = from_bits(v6[1])
    ground = from_bits(v6[2])
    local_edge_delta = from_bits(v6[3])

    local local_hang_axis = from_bits(v6[4])

    local_axis544[1] = local_ground_normal
    local_axis544[2] = ground
    local_axis544[3] = local_edge_delta
    local_axis544[4] = local_hang_axis
    local_ground_normal = vectors.local_ground_normal
    v6 = p13.reckoning.ground_normal
    ground = v6.x
    local_edge_delta = v6.y
    local_hang_axis = v6.z
    local_ground_normal[1] = ground
    local_ground_normal[2] = local_edge_delta
    local_ground_normal[3] = local_hang_axis
    local_ground_normal[4] = 0
    ground = p13.reckoning_frames.ground
    local_edge_delta = vectors.local_edge_delta
    local_hang_axis = p8.deck[4][1] - p16.edge_point[1]

    local v7 = p8.deck[4][2] - p16.edge_point[2]
    local v8 = p8.deck[4][3] - p16.edge_point[3]
    local v9 = p8.deck[4][4] - p16.edge_point[4]

    local_edge_delta[1] = local_hang_axis
    local_edge_delta[2] = v7
    local_edge_delta[3] = v8
    local_edge_delta[4] = v9
    local_hang_axis = vectors.local_hang_axis
    v6 = p9.vectors_720_784_800_816_832_864[5]
    v7 = from_bits(v6[1])
    v8 = from_bits(v6[2])
    v9 = from_bits(v6[3])

    local v10 = from_bits(v6[4])

    local_hang_axis[1] = v7
    local_hang_axis[2] = v8
    local_hang_axis[3] = v9
    local_hang_axis[4] = v10

    local manual = v5.steering

    table.clear(manual)
    out.steering = manual
    manual.turn = fields.turn
    manual.hard_turn = fields.hard_turn
    manual.absolute_body_speed = p8.absolute_speed
    manual.flipped_controls_scalar = p8.control_sign
    manual.balance = fields.balance
    manual.truck_tightness = p9.truck_tightness_2760
    manual.pushing = bit32.band(p9.flags_2468, 134217728) ~= 0
    manual = v5.speed_wobble
    table.clear(manual)
    out.speed_wobble = manual
    manual.tilt = 0
    manual.speed = p9.scalar_2612
    manual.center_of_mass_height = 0
    manual.truck_tightness = p9.truck_tightness_2760
    manual.activation_threshold = p7.wobble_activation
    manual.amplitude_multiplier = p7.wobble_amplitude
    out.truck_flags_2468 = p9.flags_2468
    out.truck_flags_2472 = p9.flags_2472
    out.contact = BoardProbes.wall_contact_frame(p13.probes, p9.time_on_ground_2752, p9.signed_ground_time_2756)

    local top_ground_vector_1216 = vectors.top_ground_vector_1216

    table.clear(top_ground_vector_1216)
    out.ground_vector_1216 = top_ground_vector_1216
    v7 = local_ground_normal[1]
    v8 = local_ground_normal[2]
    v9 = local_ground_normal[3]
    v10 = local_ground_normal[4]
    top_ground_vector_1216[1] = v7
    top_ground_vector_1216[2] = v8
    top_ground_vector_1216[3] = v9
    top_ground_vector_1216[4] = v10
    manual = v5.propulsion
    table.clear(manual)
    out.propulsion = manual
    manual.flags_2468 = p9.flags_2468
    manual.flags_2472 = p9.flags_2472
    manual.target_speed = push_target(p10.contacts.push_speed, p9.scalar_2612, p7.push_target_multiplier)
    manual.signed_speed = p9.scalar_2612
    manual.absolute_body_speed = p8.absolute_speed
    manual.scalar_2660 = p8.total_mass
    manual.timestep = p9.timestep_2604
    manual.brake_input = fields.brake
    top_ground_vector_1216 = vectors.propulsion_push_direction
    v6 = p8.forward
    table.clear(top_ground_vector_1216)
    manual.push_direction = top_ground_vector_1216
    v7 = v6[1]
    v8 = v6[2]
    v9 = v6[3]
    top_ground_vector_1216.x = v7
    top_ground_vector_1216.y = v8
    top_ground_vector_1216.z = v9
    top_ground_vector_1216 = vectors.propulsion_brake_direction
    v6 = p8.horizontal_forward
    table.clear(top_ground_vector_1216)
    manual.brake_direction = top_ground_vector_1216
    v7 = v6[1]
    v8 = v6[2]
    v9 = v6[3]
    top_ground_vector_1216.x = v7
    top_ground_vector_1216.y = v8
    top_ground_vector_1216.z = v9
    manual.surface_braking_factor = p7.surface_braking_factor
    manual = v5.ground_force
    table.clear(manual)
    out.ground_force = manual
    manual.argument_1_2752 = p9.time_on_ground_2752
    manual.processed_2776 = p9.crouch_2776
    manual.processed_2780 = p9.crouch_delta_2780
    manual.previous_state_scalar_56 = p11.absorption
    manual.ground_scalar_1216 = p7.foot_force_offset
    manual.ground_scalar_1232 = p7.absorption_front
    manual.ground_scalar_1236 = p7.absorption_rear
    manual.ground_scalar_1240 = p7.foot_force_offset
    manual.balance_2720 = fields.balance
    manual.surface_speed_2656 = p9.scalar_2656
    top_ground_vector_1216 = vectors.ground_force_axis_384
    v6 = p8.transverse_up
    table.clear(top_ground_vector_1216)
    manual.axis_384 = top_ground_vector_1216
    v7 = v6[1]
    v8 = v6[2]
    v9 = v6[3]
    v10 = v6[4]
    top_ground_vector_1216[1] = v7
    top_ground_vector_1216[2] = v8
    top_ground_vector_1216[3] = v9
    top_ground_vector_1216[4] = v10
    top_ground_vector_1216 = vectors.ground_force_velocity_400
    table.clear(top_ground_vector_1216)
    manual.velocity_400 = top_ground_vector_1216
    v7 = local_velocity[1]
    v8 = local_velocity[2]
    v9 = local_velocity[3]
    v10 = local_velocity[4]
    top_ground_vector_1216[1] = v7
    top_ground_vector_1216[2] = v8
    top_ground_vector_1216[3] = v9
    top_ground_vector_1216[4] = v10
    top_ground_vector_1216 = vectors.ground_force_axis_544
    table.clear(top_ground_vector_1216)
    manual.axis_544 = top_ground_vector_1216
    v7 = local_axis544[1]
    v8 = local_axis544[2]
    v9 = local_axis544[3]
    v10 = local_axis544[4]
    top_ground_vector_1216[1] = v7
    top_ground_vector_1216[2] = v8
    top_ground_vector_1216[3] = v9
    top_ground_vector_1216[4] = v10
    manual = v5.speed_model
    table.clear(manual)
    out.speed_model = manual
    manual.flags_2468 = p9.flags_2468
    manual.flags_2476 = p9.flags_2476
    manual.wheel_contact_count = rt.to_i32(p9.wheel_count_2556)
    manual.frames_2580 = rt.to_i32(p9.spin_same_direction_frames_2580)
    manual.timestep = p9.timestep_2604
    manual.signed_speed = p9.scalar_2612
    manual.angle_2652 = p9.scalar_2652
    manual.surface_speed = p9.scalar_2656
    manual.turn_2672 = p9.spin_input_2672
    manual.balance = fields.balance
    manual.elapsed_without_input = p9.time_since_last_input_2748
    manual.manual_state_276 = 0
    top_ground_vector_1216 = vectors.speed_model_vector_160
    v6 = p8.effective[3]
    table.clear(top_ground_vector_1216)
    manual.vector_160 = top_ground_vector_1216
    v7 = v6[1]
    v8 = v6[2]
    v9 = v6[3]
    v10 = v6[4]
    top_ground_vector_1216[1] = v7
    top_ground_vector_1216[2] = v8
    top_ground_vector_1216[3] = v9
    top_ground_vector_1216[4] = v10
    top_ground_vector_1216 = vectors.speed_model_vector_352
    v6 = p8.forward
    table.clear(top_ground_vector_1216)
    manual.vector_352 = top_ground_vector_1216
    v7 = v6[1]
    v8 = v6[2]
    v9 = v6[3]
    v10 = v6[4]
    top_ground_vector_1216[1] = v7
    top_ground_vector_1216[2] = v8
    top_ground_vector_1216[3] = v9
    top_ground_vector_1216[4] = v10
    top_ground_vector_1216 = vectors.speed_model_velocity_416
    table.clear(top_ground_vector_1216)
    manual.velocity_416 = top_ground_vector_1216
    v7 = local_angular[1]
    v8 = local_angular[2]
    v9 = local_angular[3]
    v10 = local_angular[4]
    top_ground_vector_1216[1] = v7
    top_ground_vector_1216[2] = v8
    top_ground_vector_1216[3] = v9
    top_ground_vector_1216[4] = v10
    top_ground_vector_1216 = vectors.speed_model_normal_464
    table.clear(top_ground_vector_1216)
    manual.normal_464 = top_ground_vector_1216
    v7 = local_normal[1]
    v8 = local_normal[2]
    v9 = local_normal[3]
    v10 = local_normal[4]
    top_ground_vector_1216[1] = v7
    top_ground_vector_1216[2] = v8
    top_ground_vector_1216[3] = v9
    top_ground_vector_1216[4] = v10
    top_ground_vector_1216 = vectors.speed_model_effective_forward
    v6 = p8.effective[3]
    table.clear(top_ground_vector_1216)
    manual.effective_forward = top_ground_vector_1216
    v7 = v6[1]
    v8 = v6[2]
    v9 = v6[3]
    v10 = v6[4]
    top_ground_vector_1216[1] = v7
    top_ground_vector_1216[2] = v8
    top_ground_vector_1216[3] = v9
    top_ground_vector_1216[4] = v10
    manual.mass = p8.total_mass
    manual = v5.slide_friction
    table.clear(manual)
    out.slide_friction = manual
    manual.heading_time = 0
    top_ground_vector_1216 = vectors.slide_friction_normal
    table.clear(top_ground_vector_1216)
    manual.normal = top_ground_vector_1216
    v7 = local_normal[1]
    v8 = local_normal[2]
    v9 = local_normal[3]
    v10 = local_normal[4]
    top_ground_vector_1216[1] = v7
    top_ground_vector_1216[2] = v8
    top_ground_vector_1216[3] = v9
    top_ground_vector_1216[4] = v10
    top_ground_vector_1216 = vectors.slide_friction_velocity
    table.clear(top_ground_vector_1216)
    manual.velocity = top_ground_vector_1216
    v7 = local_velocity[1]
    v8 = local_velocity[2]
    v9 = local_velocity[3]
    v10 = local_velocity[4]
    top_ground_vector_1216[1] = v7
    top_ground_vector_1216[2] = v8
    top_ground_vector_1216[3] = v9
    top_ground_vector_1216[4] = v10
    top_ground_vector_1216 = vectors.slide_friction_side_axis
    v6 = p8.deck[1]
    table.clear(top_ground_vector_1216)
    manual.side_axis = top_ground_vector_1216
    v7 = v6[1]
    v8 = v6[2]
    v9 = v6[3]
    v10 = v6[4]
    top_ground_vector_1216[1] = v7
    top_ground_vector_1216[2] = v8
    top_ground_vector_1216[3] = v9
    top_ground_vector_1216[4] = v10
    manual.surface_speed = p9.scalar_2656
    manual.scalar_2764 = p9.scalar_2764
    manual = v5.pump_force
    table.clear(manual)
    out.pump_force = manual
    manual.flags_2476 = p9.flags_2476
    manual.mode_multiplier = p12
    manual.pumping_scalar = p11.pump_acceleration
    manual.input_scalar_2660 = p8.total_mass
    manual.timestep = p9.timestep_2604
    top_ground_vector_1216 = vectors.pump_force_direction_432
    v6 = p8.forward_velocity
    table.clear(top_ground_vector_1216)
    manual.direction_432 = top_ground_vector_1216
    v7 = v6[1]
    v8 = v6[2]
    v9 = v6[3]
    v10 = v6[4]
    top_ground_vector_1216[1] = v7
    top_ground_vector_1216[2] = v8
    top_ground_vector_1216[3] = v9
    top_ground_vector_1216[4] = v10
    top_ground_vector_1216 = vectors.pump_force_normal_threshold
    table.clear(top_ground_vector_1216)
    manual.normal_threshold = top_ground_vector_1216
    top_ground_vector_1216[1] = 9.999999974752427E-07
    top_ground_vector_1216[2] = 9.999999974752427E-07
    top_ground_vector_1216[3] = 9.999999974752427E-07
    top_ground_vector_1216[4] = 9.999999974752427E-07
    manual = v5.straighten
    table.clear(manual)
    out.straighten = manual
    manual.heading_time = 0
    manual.scalar_2764 = p9.scalar_2764
    manual.turn = fields.turn
    top_ground_vector_1216 = vectors.straighten_forward
    v6 = p8.forward
    table.clear(top_ground_vector_1216)
    manual.forward = top_ground_vector_1216
    v7 = v6[1]
    v8 = v6[2]
    v9 = v6[3]
    v10 = v6[4]
    top_ground_vector_1216[1] = v7
    top_ground_vector_1216[2] = v8
    top_ground_vector_1216[3] = v9
    top_ground_vector_1216[4] = v10
    top_ground_vector_1216 = vectors.straighten_velocity
    table.clear(top_ground_vector_1216)
    manual.velocity = top_ground_vector_1216
    v7 = local_velocity[1]
    v8 = local_velocity[2]
    v9 = local_velocity[3]
    v10 = local_velocity[4]
    top_ground_vector_1216[1] = v7
    top_ground_vector_1216[2] = v8
    top_ground_vector_1216[3] = v9
    top_ground_vector_1216[4] = v10
    top_ground_vector_1216 = vectors.straighten_normal
    table.clear(top_ground_vector_1216)
    manual.normal = top_ground_vector_1216
    v7 = local_normal[1]
    v8 = local_normal[2]
    v9 = local_normal[3]
    v10 = local_normal[4]
    top_ground_vector_1216[1] = v7
    top_ground_vector_1216[2] = v8
    top_ground_vector_1216[3] = v9
    top_ground_vector_1216[4] = v10
    manual = v5.heading
    table.clear(manual)
    out.heading = manual
    manual.balance = fields.balance
    manual.manual_turn = p9.spin_input_2672
    manual.flags_2472 = p9.flags_2472
    manual.timestep = p9.timestep_2604
    manual.signed_speed = p9.scalar_2612
    manual.manual_curve_input = p9.scalar_2652
    manual.turn_2712 = fields.raw_turn
    manual.scalar_2740 = RidingOutputs.heading_adjust_factor(p13)
    top_ground_vector_1216 = vectors.heading_velocity
    v6 = p8.forward_velocity
    table.clear(top_ground_vector_1216)
    manual.velocity = top_ground_vector_1216
    v7 = v6[1]
    v8 = v6[2]
    v9 = v6[3]
    v10 = v6[4]
    top_ground_vector_1216[1] = v7
    top_ground_vector_1216[2] = v8
    top_ground_vector_1216[3] = v9
    top_ground_vector_1216[4] = v10
    top_ground_vector_1216 = vectors.heading_normal
    table.clear(top_ground_vector_1216)
    manual.normal = top_ground_vector_1216
    v7 = local_normal[1]
    v8 = local_normal[2]
    v9 = local_normal[3]
    v10 = local_normal[4]
    top_ground_vector_1216[1] = v7
    top_ground_vector_1216[2] = v8
    top_ground_vector_1216[3] = v9
    top_ground_vector_1216[4] = v10
    top_ground_vector_1216 = vectors.heading_angular_velocity
    v6 = p9.vectors_720_784_800_816_832_864[1]
    table.clear(top_ground_vector_1216)
    manual.angular_velocity = top_ground_vector_1216
    v7 = from_bits(v6[1])
    v8 = from_bits(v6[2])
    v9 = from_bits(v6[3])
    v10 = from_bits(v6[4])
    top_ground_vector_1216[1] = v7
    top_ground_vector_1216[2] = v8
    top_ground_vector_1216[3] = v9
    top_ground_vector_1216[4] = v10

    local heading_transform = vectors.heading_transform

    table.clear(heading_transform)
    manual.transform = heading_transform

    for i = 1, 4 do
        top_ground_vector_1216 = vectors.heading_transform_rows[i]
        v6 = ground[i]
        table.clear(top_ground_vector_1216)
        heading_transform[i] = top_ground_vector_1216
        v10 = v6[1]

        local v11 = v6[2]
        local v12 = v6[3]
        local v13 = v6[4]

        top_ground_vector_1216[1] = v10
        top_ground_vector_1216[2] = v11
        top_ground_vector_1216[3] = v12
        top_ground_vector_1216[4] = v13
    end

    manual = v5.anti_flip
    table.clear(manual)
    out.anti_flip = manual
    manual.flags_2468 = p9.flags_2468
    manual.balance = fields.balance
    top_ground_vector_1216 = vectors.anti_flip_axis_96
    v6 = p8.deck[3]
    table.clear(top_ground_vector_1216)
    manual.axis_96 = top_ground_vector_1216
    v7 = v6[1]
    v8 = v6[2]
    v9 = v6[3]
    v10 = v6[4]
    top_ground_vector_1216[1] = v7
    top_ground_vector_1216[2] = v8
    top_ground_vector_1216[3] = v9
    top_ground_vector_1216[4] = v10
    top_ground_vector_1216 = vectors.anti_flip_axis_64
    v6 = p8.deck[1]
    table.clear(top_ground_vector_1216)
    manual.axis_64 = top_ground_vector_1216
    v7 = v6[1]
    v8 = v6[2]
    v9 = v6[3]
    v10 = v6[4]
    top_ground_vector_1216[1] = v7
    top_ground_vector_1216[2] = v8
    top_ground_vector_1216[3] = v9
    top_ground_vector_1216[4] = v10
    top_ground_vector_1216 = vectors.anti_flip_projection_axis_544
    table.clear(top_ground_vector_1216)
    manual.projection_axis_544 = top_ground_vector_1216
    v7 = local_axis544[1]
    v8 = local_axis544[2]
    v9 = local_axis544[3]
    v10 = local_axis544[4]
    top_ground_vector_1216[1] = v7
    top_ground_vector_1216[2] = v8
    top_ground_vector_1216[3] = v9
    top_ground_vector_1216[4] = v10
    manual = v5.manual
    table.clear(manual)
    out.manual = manual
    manual.balance = fields.balance
    manual.flipped_controls = p8.control_sign
    manual.procedural_noise_time = p9.state_timer_2664
    manual.absolute_speed = p8.absolute_speed
    manual.animation_noise = p14.board_at_y_delta
    manual.timestep = p9.timestep_2604
    manual.powersliding = false
    manual.braking = bit32.band(p9.flags_2468, 536870912) ~= 0
    manual.positive_balance_contact = bit32.band(p9.flags_2472, 134217728) ~= 0
    manual.negative_balance_contact = bit32.band(p9.flags_2472, 67108864) ~= 0
    manual.reversed_point_selection = bit32.band(p9.flags_2468, 1048576) ~= 0
    top_ground_vector_1216 = vectors.manual_reference_x
    v6 = ground[1]
    table.clear(top_ground_vector_1216)
    manual.reference_x = top_ground_vector_1216
    v7 = v6[1]
    v8 = v6[2]
    v9 = v6[3]
    v10 = v6[4]
    top_ground_vector_1216[1] = v7
    top_ground_vector_1216[2] = v8
    top_ground_vector_1216[3] = v9
    top_ground_vector_1216[4] = v10
    top_ground_vector_1216 = vectors.manual_reference_z
    v6 = ground[3]
    table.clear(top_ground_vector_1216)
    manual.reference_z = top_ground_vector_1216
    v7 = v6[1]
    v8 = v6[2]
    v9 = v6[3]
    v10 = v6[4]
    top_ground_vector_1216[1] = v7
    top_ground_vector_1216[2] = v8
    top_ground_vector_1216[3] = v9
    top_ground_vector_1216[4] = v10
    top_ground_vector_1216 = vectors.manual_deck_z
    v6 = p8.deck[3]
    table.clear(top_ground_vector_1216)
    manual.deck_z = top_ground_vector_1216
    v7 = v6[1]
    v8 = v6[2]
    v9 = v6[3]
    v10 = v6[4]
    top_ground_vector_1216[1] = v7
    top_ground_vector_1216[2] = v8
    top_ground_vector_1216[3] = v9
    top_ground_vector_1216[4] = v10
    top_ground_vector_1216 = vectors.manual_velocity_frame_z
    v6 = p9.effective_anim_transform_192[3]
    table.clear(top_ground_vector_1216)
    manual.velocity_frame_z = top_ground_vector_1216
    v7 = from_bits(v6[1])
    v8 = from_bits(v6[2])
    v9 = from_bits(v6[3])
    v10 = from_bits(v6[4])
    top_ground_vector_1216[1] = v7
    top_ground_vector_1216[2] = v8
    top_ground_vector_1216[3] = v9
    top_ground_vector_1216[4] = v10
    top_ground_vector_1216 = vectors.manual_angular_velocity_world
    table.clear(top_ground_vector_1216)
    manual.angular_velocity_world = top_ground_vector_1216
    v7 = local_angular[1]
    v8 = local_angular[2]
    v9 = local_angular[3]
    v10 = local_angular[4]
    top_ground_vector_1216[1] = v7
    top_ground_vector_1216[2] = v8
    top_ground_vector_1216[3] = v9
    top_ground_vector_1216[4] = v10
    top_ground_vector_1216 = vectors.manual_correction_point_7888
    v6 = p15[1].translation
    table.clear(top_ground_vector_1216)
    manual.correction_point_7888 = top_ground_vector_1216
    v7 = v6.x
    v8 = v6.y
    v9 = v6.z
    top_ground_vector_1216[1] = v7
    top_ground_vector_1216[2] = v8
    top_ground_vector_1216[3] = v9
    top_ground_vector_1216[4] = 0
    top_ground_vector_1216 = vectors.manual_correction_point_7952
    v6 = p15[2].translation
    table.clear(top_ground_vector_1216)
    manual.correction_point_7952 = top_ground_vector_1216
    v7 = v6.x
    v8 = v6.y
    v9 = v6.z
    top_ground_vector_1216[1] = v7
    top_ground_vector_1216[2] = v8
    top_ground_vector_1216[3] = v9
    top_ground_vector_1216[4] = 0
    manual = v5.ground_drag
    table.clear(manual)
    out.ground_drag = manual
    manual.flags_2468 = p9.flags_2468
    manual.absolute_body_speed_2616 = p8.absolute_speed
    manual.balance_2720 = fields.balance
    manual.scalar_2724 = p16.manual_drag_2724
    manual.ground_normal_y = local_ground_normal[2]
    out.contact_time_2756 = p9.signed_ground_time_2756
    out.trajectory_state_1776_bits = p16.trajectory_state_bits
    manual = v5.anti_flip_nudge
    table.clear(manual)
    out.anti_flip_nudge = manual
    manual.deck_speed_2652 = p9.scalar_2652
    top_ground_vector_1216 = vectors.anti_flip_nudge_deck_axis_96
    v6 = p8.deck[3]
    table.clear(top_ground_vector_1216)
    manual.deck_axis_96 = top_ground_vector_1216
    v7 = v6[1]
    v8 = v6[2]
    v9 = v6[3]
    v10 = v6[4]
    top_ground_vector_1216[1] = v7
    top_ground_vector_1216[2] = v8
    top_ground_vector_1216[3] = v9
    top_ground_vector_1216[4] = v10
    manual = v5.hang_up
    table.clear(manual)
    out.hang_up = manual
    manual.flags_1516 = p16.edge_flags
    manual.deck_speed_2652 = p9.scalar_2652
    manual.scalar_84 = p8.deck[2][2]
    manual.geometry_axis_dot_positive = dot_product(local_hang_axis, local_hang_axis) > 0
    manual = v5.halfpipe_wheel_catch
    table.clear(manual)
    out.halfpipe_wheel_catch = manual
    manual.flags_1516 = p16.edge_flags
    manual.deck_speed_2652 = p9.scalar_2652
    manual.deck_x_axis_y = p8.deck[1][2]
    manual.deck_y_axis_y = p8.deck[2][2]
    manual.signed_deck_distance = dot_product(p8.deck[2], local_edge_delta)
    manual = v5.pinning
    table.clear(manual)
    out.pinning = manual
    manual.flags_2488 = p9.flags_2488
    manual.frames_since_teleport_2584 = rt.to_i32(p9.frames_since_teleport_2584)
    manual.flags_2472 = p9.flags_2472

    return out
end

function t1.GroundSettings.input_x2(p17, p18, p19, p20, p21, p22, p23, p24, p25, p26) -- line: 519
    -- upvalues: rt (copy), RidingOutputs (copy), BoardProbes (copy), dot_product (copy), raw (ref), xyz (ref), v (ref), push_target (ref)
    local fields = p20.fields
    local v14 = raw(p19.vectors_464_480_496_512_528[1])
    local v15 = raw(p19.vectors_400_416[1])
    local v16 = raw(p19.vectors_400_416[2])
    local v17 = raw(p19.vectors_544_560_592_608[1])
    local v18 = v(p23.reckoning.ground_normal)
    local v19 = rt.copy(p23.reckoning_frames.ground)
    local t4 = {
        p18.deck[4][1] - p26.edge_point[1],
        p18.deck[4][2] - p26.edge_point[2],
        p18.deck[4][3] - p26.edge_point[3],
        p18.deck[4][4] - p26.edge_point[4]
    }
    local v20 = raw(p19.vectors_720_784_800_816_832_864[5])

    return {
        steering = {
            turn = fields.turn,
            hard_turn = fields.hard_turn,
            absolute_body_speed = p18.absolute_speed,
            flipped_controls_scalar = p18.control_sign,
            balance = fields.balance,
            truck_tightness = p19.truck_tightness_2760,
            pushing = bit32.band(p19.flags_2468, 134217728) ~= 0
        },
        speed_wobble = {
            tilt = 0,
            center_of_mass_height = 0,
            speed = p19.scalar_2612,
            truck_tightness = p19.truck_tightness_2760,
            activation_threshold = p17.wobble_activation,
            amplitude_multiplier = p17.wobble_amplitude
        },
        truck_flags_2468 = p19.flags_2468,
        truck_flags_2472 = p19.flags_2472,
        contact = BoardProbes.wall_contact_frame(p23.probes, p19.time_on_ground_2752, p19.signed_ground_time_2756),
        ground_vector_1216 = v18,
        propulsion = {
            flags_2468 = p19.flags_2468,
            flags_2472 = p19.flags_2472,
            target_speed = push_target(p20.contacts.push_speed, p19.scalar_2612, p17.push_target_multiplier),
            signed_speed = p19.scalar_2612,
            absolute_body_speed = p18.absolute_speed,
            scalar_2660 = p18.total_mass,
            timestep = p19.timestep_2604,
            brake_input = fields.brake,
            push_direction = xyz(p18.forward),
            brake_direction = xyz(p18.horizontal_forward),
            surface_braking_factor = p17.surface_braking_factor
        },
        ground_force = {
            argument_1_2752 = p19.time_on_ground_2752,
            processed_2776 = p19.crouch_2776,
            processed_2780 = p19.crouch_delta_2780,
            previous_state_scalar_56 = p21.absorption,
            ground_scalar_1216 = p17.foot_force_offset,
            ground_scalar_1232 = p17.absorption_front,
            ground_scalar_1236 = p17.absorption_rear,
            ground_scalar_1240 = p17.foot_force_offset,
            balance_2720 = fields.balance,
            surface_speed_2656 = p19.scalar_2656,
            axis_384 = rt.copy(p18.transverse_up),
            velocity_400 = rt.copy(v15),
            axis_544 = rt.copy(v17)
        },
        speed_model = {
            manual_state_276 = 0,
            flags_2468 = p19.flags_2468,
            flags_2476 = p19.flags_2476,
            wheel_contact_count = rt.to_i32(p19.wheel_count_2556),
            frames_2580 = rt.to_i32(p19.spin_same_direction_frames_2580),
            timestep = p19.timestep_2604,
            signed_speed = p19.scalar_2612,
            angle_2652 = p19.scalar_2652,
            surface_speed = p19.scalar_2656,
            turn_2672 = p19.spin_input_2672,
            balance = fields.balance,
            elapsed_without_input = p19.time_since_last_input_2748,
            vector_160 = rt.copy(p18.effective[3]),
            vector_352 = rt.copy(p18.forward),
            velocity_416 = rt.copy(v16),
            normal_464 = rt.copy(v14),
            effective_forward = rt.copy(p18.effective[3]),
            mass = p18.total_mass
        },
        slide_friction = {
            heading_time = 0,
            normal = rt.copy(v14),
            velocity = rt.copy(v15),
            side_axis = rt.copy(p18.deck[1]),
            surface_speed = p19.scalar_2656,
            scalar_2764 = p19.scalar_2764
        },
        pump_force = {
            flags_2476 = p19.flags_2476,
            mode_multiplier = p22,
            pumping_scalar = p21.pump_acceleration,
            input_scalar_2660 = p18.total_mass,
            timestep = p19.timestep_2604,
            direction_432 = rt.copy(p18.forward_velocity),
            normal_threshold = rt.filled(4, 9.999999974752427E-07)
        },
        straighten = {
            heading_time = 0,
            scalar_2764 = p19.scalar_2764,
            turn = fields.turn,
            forward = rt.copy(p18.forward),
            velocity = v15,
            normal = rt.copy(v14)
        },
        heading = {
            balance = fields.balance,
            manual_turn = p19.spin_input_2672,
            flags_2472 = p19.flags_2472,
            timestep = p19.timestep_2604,
            signed_speed = p19.scalar_2612,
            manual_curve_input = p19.scalar_2652,
            turn_2712 = fields.raw_turn,
            scalar_2740 = RidingOutputs.heading_adjust_factor(p23),
            velocity = rt.copy(p18.forward_velocity),
            normal = v14,
            angular_velocity = raw(p19.vectors_720_784_800_816_832_864[1]),
            transform = v19
        },
        anti_flip = {
            flags_2468 = p19.flags_2468,
            balance = fields.balance,
            axis_96 = rt.copy(p18.deck[3]),
            axis_64 = rt.copy(p18.deck[1]),
            projection_axis_544 = v17
        },
        manual = {
            powersliding = false,
            balance = fields.balance,
            flipped_controls = p18.control_sign,
            procedural_noise_time = p19.state_timer_2664,
            absolute_speed = p18.absolute_speed,
            animation_noise = p24.board_at_y_delta,
            timestep = p19.timestep_2604,
            braking = bit32.band(p19.flags_2468, 536870912) ~= 0,
            positive_balance_contact = bit32.band(p19.flags_2472, 134217728) ~= 0,
            negative_balance_contact = bit32.band(p19.flags_2472, 67108864) ~= 0,
            reversed_point_selection = bit32.band(p19.flags_2468, 1048576) ~= 0,
            reference_x = rt.copy(v19[1]),
            reference_z = rt.copy(v19[3]),
            deck_z = rt.copy(p18.deck[3]),
            velocity_frame_z = raw(p19.effective_anim_transform_192[3]),
            angular_velocity_world = v16,
            correction_point_7888 = v(p25[1].translation),
            correction_point_7952 = v(p25[2].translation)
        },
        ground_drag = {
            flags_2468 = p19.flags_2468,
            absolute_body_speed_2616 = p18.absolute_speed,
            balance_2720 = fields.balance,
            scalar_2724 = p26.manual_drag_2724,
            ground_normal_y = v18[2]
        },
        contact_time_2756 = p19.signed_ground_time_2756,
        trajectory_state_1776_bits = p26.trajectory_state_bits,
        anti_flip_nudge = {
            deck_speed_2652 = p19.scalar_2652,
            deck_axis_96 = rt.copy(p18.deck[3])
        },
        hang_up = {
            flags_1516 = p26.edge_flags,
            deck_speed_2652 = p19.scalar_2652,
            scalar_84 = p18.deck[2][2],
            geometry_axis_dot_positive = dot_product(v20, v20) > 0
        },
        halfpipe_wheel_catch = {
            flags_1516 = p26.edge_flags,
            deck_speed_2652 = p19.scalar_2652,
            deck_x_axis_y = p18.deck[1][2],
            deck_y_axis_y = p18.deck[2][2],
            signed_deck_distance = dot_product(p18.deck[2], t4)
        },
        pinning = {
            flags_2488 = p19.flags_2488,
            frames_since_teleport_2584 = rt.to_i32(p19.frames_since_teleport_2584),
            flags_2472 = p19.flags_2472
        }
    }
end

function t1.GroundSettings.input_reference(p27, p28, p29, p30, p31, p32, p33, p34, p35, p36) -- line: 707
    -- upvalues: rt (copy), RidingOutputs (copy), BoardProbes (copy), dot_product (copy), raw (ref), xyz (ref), v (ref), push_target (ref)
    local fields = p30.fields
    local v21 = raw(p29.vectors_464_480_496_512_528[1])
    local v22 = raw(p29.vectors_400_416[1])
    local v23 = raw(p29.vectors_400_416[2])
    local v24 = raw(p29.vectors_544_560_592_608[1])
    local v25 = v(p33.reckoning.ground_normal)
    local v26 = rt.copy(p33.reckoning_frames.ground)
    local t8 = {
        p28.deck[4][1] - p36.edge_point[1],
        p28.deck[4][2] - p36.edge_point[2],
        p28.deck[4][3] - p36.edge_point[3],
        p28.deck[4][4] - p36.edge_point[4]
    }
    local v27 = raw(p29.vectors_720_784_800_816_832_864[5])

    return {
        steering = {
            turn = fields.turn,
            hard_turn = fields.hard_turn,
            absolute_body_speed = p28.absolute_speed,
            flipped_controls_scalar = p28.control_sign,
            balance = fields.balance,
            truck_tightness = p29.truck_tightness_2760,
            pushing = bit32.band(p29.flags_2468, 134217728) ~= 0
        },
        speed_wobble = {
            tilt = 0,
            center_of_mass_height = 0,
            speed = p29.scalar_2612,
            truck_tightness = p29.truck_tightness_2760,
            activation_threshold = p27.wobble_activation,
            amplitude_multiplier = p27.wobble_amplitude
        },
        truck_flags_2468 = p29.flags_2468,
        truck_flags_2472 = p29.flags_2472,
        contact = BoardProbes.wall_contact_frame(p33.probes, p29.time_on_ground_2752, p29.signed_ground_time_2756),
        ground_vector_1216 = rt.copy(v25),
        propulsion = {
            flags_2468 = p29.flags_2468,
            flags_2472 = p29.flags_2472,
            target_speed = push_target(p30.contacts.push_speed, p29.scalar_2612, p27.push_target_multiplier),
            signed_speed = p29.scalar_2612,
            absolute_body_speed = p28.absolute_speed,
            scalar_2660 = p28.total_mass,
            timestep = p29.timestep_2604,
            brake_input = fields.brake,
            push_direction = xyz(p28.forward),
            brake_direction = xyz(p28.horizontal_forward),
            surface_braking_factor = p27.surface_braking_factor
        },
        ground_force = {
            argument_1_2752 = p29.time_on_ground_2752,
            processed_2776 = p29.crouch_2776,
            processed_2780 = p29.crouch_delta_2780,
            previous_state_scalar_56 = p31.absorption,
            ground_scalar_1216 = p27.foot_force_offset,
            ground_scalar_1232 = p27.absorption_front,
            ground_scalar_1236 = p27.absorption_rear,
            ground_scalar_1240 = p27.foot_force_offset,
            balance_2720 = fields.balance,
            surface_speed_2656 = p29.scalar_2656,
            axis_384 = rt.copy(p28.transverse_up),
            velocity_400 = rt.copy(v22),
            axis_544 = rt.copy(v24)
        },
        speed_model = {
            manual_state_276 = 0,
            flags_2468 = p29.flags_2468,
            flags_2476 = p29.flags_2476,
            wheel_contact_count = rt.to_i32(p29.wheel_count_2556),
            frames_2580 = rt.to_i32(p29.spin_same_direction_frames_2580),
            timestep = p29.timestep_2604,
            signed_speed = p29.scalar_2612,
            angle_2652 = p29.scalar_2652,
            surface_speed = p29.scalar_2656,
            turn_2672 = p29.spin_input_2672,
            balance = fields.balance,
            elapsed_without_input = p29.time_since_last_input_2748,
            vector_160 = rt.copy(p28.effective[3]),
            vector_352 = rt.copy(p28.forward),
            velocity_416 = rt.copy(v23),
            normal_464 = rt.copy(v21),
            effective_forward = rt.copy(p28.effective[3]),
            mass = p28.total_mass
        },
        slide_friction = {
            heading_time = 0,
            normal = rt.copy(v21),
            velocity = rt.copy(v22),
            side_axis = rt.copy(p28.deck[1]),
            surface_speed = p29.scalar_2656,
            scalar_2764 = p29.scalar_2764
        },
        pump_force = {
            flags_2476 = p29.flags_2476,
            mode_multiplier = p32,
            pumping_scalar = p31.pump_acceleration,
            input_scalar_2660 = p28.total_mass,
            timestep = p29.timestep_2604,
            direction_432 = rt.copy(p28.forward_velocity),
            normal_threshold = rt.filled(4, 9.999999974752427E-07)
        },
        straighten = {
            heading_time = 0,
            scalar_2764 = p29.scalar_2764,
            turn = fields.turn,
            forward = rt.copy(p28.forward),
            velocity = rt.copy(v22),
            normal = rt.copy(v21)
        },
        heading = {
            balance = fields.balance,
            manual_turn = p29.spin_input_2672,
            flags_2472 = p29.flags_2472,
            timestep = p29.timestep_2604,
            signed_speed = p29.scalar_2612,
            manual_curve_input = p29.scalar_2652,
            turn_2712 = fields.raw_turn,
            scalar_2740 = RidingOutputs.heading_adjust_factor(p33),
            velocity = rt.copy(p28.forward_velocity),
            normal = rt.copy(v21),
            angular_velocity = raw(p29.vectors_720_784_800_816_832_864[1]),
            transform = rt.copy(v26)
        },
        anti_flip = {
            flags_2468 = p29.flags_2468,
            balance = fields.balance,
            axis_96 = rt.copy(p28.deck[3]),
            axis_64 = rt.copy(p28.deck[1]),
            projection_axis_544 = rt.copy(v24)
        },
        manual = {
            powersliding = false,
            balance = fields.balance,
            flipped_controls = p28.control_sign,
            procedural_noise_time = p29.state_timer_2664,
            absolute_speed = p28.absolute_speed,
            animation_noise = p34.board_at_y_delta,
            timestep = p29.timestep_2604,
            braking = bit32.band(p29.flags_2468, 536870912) ~= 0,
            positive_balance_contact = bit32.band(p29.flags_2472, 134217728) ~= 0,
            negative_balance_contact = bit32.band(p29.flags_2472, 67108864) ~= 0,
            reversed_point_selection = bit32.band(p29.flags_2468, 1048576) ~= 0,
            reference_x = rt.copy(v26[1]),
            reference_z = rt.copy(v26[3]),
            deck_z = rt.copy(p28.deck[3]),
            velocity_frame_z = raw(p29.effective_anim_transform_192[3]),
            angular_velocity_world = rt.copy(v23),
            correction_point_7888 = v(p35[1].translation),
            correction_point_7952 = v(p35[2].translation)
        },
        ground_drag = {
            flags_2468 = p29.flags_2468,
            absolute_body_speed_2616 = p28.absolute_speed,
            balance_2720 = fields.balance,
            scalar_2724 = p36.manual_drag_2724,
            ground_normal_y = v25[2]
        },
        contact_time_2756 = p29.signed_ground_time_2756,
        trajectory_state_1776_bits = p36.trajectory_state_bits,
        anti_flip_nudge = {
            deck_speed_2652 = p29.scalar_2652,
            deck_axis_96 = rt.copy(p28.deck[3])
        },
        hang_up = {
            flags_1516 = p36.edge_flags,
            deck_speed_2652 = p29.scalar_2652,
            scalar_84 = p28.deck[2][2],
            geometry_axis_dot_positive = dot_product(v27, v27) > 0
        },
        halfpipe_wheel_catch = {
            flags_1516 = p36.edge_flags,
            deck_speed_2652 = p29.scalar_2652,
            deck_x_axis_y = p28.deck[1][2],
            deck_y_axis_y = p28.deck[2][2],
            signed_deck_distance = dot_product(p28.deck[2], t8)
        },
        pinning = {
            flags_2488 = p29.flags_2488,
            frames_since_teleport_2584 = rt.to_i32(p29.frames_since_teleport_2584),
            flags_2472 = p29.flags_2472
        }
    }
end

function raw(p37) -- line: 895
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p37[1])

    local v29 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p37[2])

    local v31 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p37[3])

    local v33 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p37[4])

    return {
        v29,
        v31,
        v33,
        (buffer.readf32(v1, 0))
    }
end

t1.raw = raw

function xyz(p38) -- line: 901
    -- upvalues: Vector3 (copy)
    return Vector3.new(p38[1], p38[2], p38[3])
end

t1.xyz = xyz

function v(p39) -- line: 907
    return {
        p39.x,
        p39.y,
        p39.z,
        0
    }
end

t1.v = v

function push_target(p40, p41, p42) -- line: 914
    -- upvalues: rt (copy)
    if p42 == 1 then
        return p40
    end

    return p41 + rt.fmax(p40 - p41, 0) * p42
end

t1.push_target = push_target

return t1
