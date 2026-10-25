-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/physics/biped_ground/entry")
local v2 = import("skate_game/physics/biped_ground/grab_runtime")
local v3 = import("skate_game/physics/biped_ground/ground_board")
local v4 = import("skate_game/physics/biped_ground/lifecycle")
local v5 = import("skate_game/physics/biped_ground/services")
local v6 = import("skate_game/physics/biped_ground/sync")
local v7 = import("skate_core/player/offboard/contact_toolkit")
local v8 = import("skate_core/player/offboard/ground_entry")
local v9 = import("skate_core/player/offboard/ground_job")
local v10 = import("skate_core/player/offboard/ground_input")
local v11 = import("skate_core/player/offboard/controller")
local TruckSteeringState = import("skate_core/riding/steering").TruckSteeringState
local Controller = v11.Controller
local ContactPrefix = v7.ContactPrefix

local function skeleton_ground() -- line: 31
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/skeleton_ground")
end

local function ground_geometry() -- line: 34
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/ground_geometry")
end

local function offboard_settings() -- line: 37
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/settings")
end

local function solid_contacts() -- line: 40
    -- upvalues: import (copy)
    return import("skate_game/physics/solid_contacts")
end

local function input_phase() -- line: 43
    -- upvalues: import (copy)
    return import("skate_game/physics/input_phase")
end

local function skeleton_input_runtime() -- line: 46
    -- upvalues: import (copy)
    return import("skate_game/physics/skeleton_input_runtime")
end

local function skeleton_controller() -- line: 49
    -- upvalues: import (copy)
    return import("skate_game/physics/skeleton_controller")
end

local t1 = {
    fill = v4.fill,
    post = v4.post,
    publish_fields = v4.publish_fields
}

local function map_from_bits(p1) -- line: 60
    -- upvalues: rt (copy)
    return rt.map(p1, rt.from_bits)
end

t1.Owner = {}

local Owner = t1.Owner

function t1.Owner.finish_reckoning(p2, p3, p4, p5, p6, p7) -- line: 87
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/skeleton_ground").State.finish_reckoning(p2.skeleton_state, p3, p4, p5, p6, p7)
end

function t1.Owner.air_settings(p8) -- line: 100
    -- upvalues: rt (copy), Owner (copy)
    return Owner.turn_vs_speed(p8), rt.copy(p8.air_launch)
end

function t1.Owner.turn_vs_speed(p9) -- line: 105
    -- upvalues: rt (copy)
    return rt.copy(p9.controller.settings.movement_velocity.turn_vs_speed)
end

function t1.Owner.load(p10, p11) -- line: 110
    -- upvalues: rt (copy), import (copy), v4 (copy), v8 (copy), Controller (copy), ContactPrefix (copy)
    local Settings = import("skate_game/physics/offboard/settings").Settings
    local v12 = Settings.load(p10, p11)
    local v13 = rt.copy(v12.board)
    local v14, v15, v16, v17, v18 = Settings.into_controller_parts(v12)

    return {
        result = nil,
        geometry_adjustment = nil,
        controller = Controller.new(v14, v15),
        ground = v8.State.default(),
        contact = ContactPrefix.reset(),
        skeleton_state = import("skate_game/physics/offboard/skeleton_ground").State.load(p10),
        geometry = import("skate_game/physics/offboard/ground_geometry").State.load(p10),
        movement_vs_stick_angle = v16,
        turn_vs_stick_angle = v17,
        air_launch = v18,
        collision_settings = v4.load_collision_settings(p10),
        grab_settings = v13
    }
end

function t1.Owner.reset(p12, p13) -- line: 133
    -- upvalues: rt (copy), v7 (copy), v8 (copy), ContactPrefix (copy)
    p12.result = nil
    p12.ground.flags_144_to_150 = table.create(7, false)
    p12.ground.counter_152 = 0
    p12.ground.counter_156 = 0
    p12.ground.elapsed_160 = 0
    v7.Owner.reset_history(p13)
    rt.assign(p12.ground, v8.State.default())
    rt.assign(p12.contact, ContactPrefix.reset())
    p12.geometry_adjustment = nil
end

function t1.Owner.run(p14, p15) -- line: 148
    -- upvalues: rt (copy), Controller (copy)
    local v19 = Controller.step_ground(p14.controller, p15)

    p14.result = rt.copy(v19)

    return v19
end

function t1.Owner.enter(p16, p17, p18, p19, p20) -- line: 156
    -- upvalues: rt (copy), import (copy), v8 (copy), Controller (copy), Owner (copy)
    Owner.reset(p16, p20)
    import("skate_game/physics/offboard/ground_geometry").State.reset(p16.geometry)

    local v20 = v8.State.enter(p16.ground, p17)

    Controller.place(p16.controller, {
        frame = rt.copy(v20.frame),
        velocity = rt.copy(v20.planar_velocity),
        body_position = rt.copy(v20.body_position),
        current_state = p18,
        previous_state = p17.previous_state_2504,
        previous_frame = p19
    })
end

for v21, v22 in v6.Owner do
    t1.Owner[v21] = v22
end

function t1.enter(_, p22) -- line: 176
    -- upvalues: rt (copy), import (copy), v1 (copy), v2 (copy), v5 (copy), map_from_bits (copy), Owner (copy)
    local processed = p22.player_input.processed
    local v23 = v1.effective_root(rt.copy(p22.animated_skeleton.roots.animation_to_world), processed.flags_2476)
    local v24 = rt.map(processed.effective_anim_transform_192, map_from_bits)
    local enter = Owner.enter
    local biped_ground = p22.biped_ground
    local t2 = {
        animation_frame = v23
    }
    local v25 = processed.vectors_544_560_592_608[4]

    t2.processed_velocity_608 = rt.map(v25, rt.from_bits)
    t2.processed_flags_2484 = processed.flags_2484
    t2.processed_flags_2476 = processed.flags_2476
    t2.requested_angle_2936 = p22.animation_input.extra.biped_start_angle
    t2.requested_duration_2896 = p22.animation_input.fields.animation_time
    t2.previous_state_2504 = processed.state_2504
    t2.previous_frame_up_208 = rt.copy(v24[2])
    t2.body_position_15872 = rt.copy(p22.animated_skeleton.board_frames.com_frame[4])
    enter(biped_ground, t2, processed.state_2508, v24, p22.offboard_contact)
    v5.enter_feet(p22)
    import("skate_game/physics/skeleton_controller").SkeletonControllerState.request(p22.ground_lifecycle.skeleton_controller, 4, p22.skeleton_collision)
    v2.Owner.enter_reset(p22.offboard_grab)
end

function t1.exit(p23) -- line: 212
    -- upvalues: import (copy), v7 (copy)
    v7.Owner.reset_history(p23.offboard_contact)
    import("skate_game/physics/offboard/ground_geometry").State.reset(p23.biped_ground.geometry)
end

local v26 = false

function t1.set_reference(p24) -- line: 237
    -- upvalues: v26 (ref)
    v26 = p24
end

function t1.update(p25, p26, p27, p28) -- line: 240
    -- upvalues: rt (copy), import (copy), v3 (copy), v5 (copy), v9 (copy), v10 (copy), TruckSteeringState (copy), t1 (copy), Owner (copy), v26 (ref)
    if v26 then
        return t1.update_reference(p25, p26, p27, p28)
    end

    local processed = p26.player_input.processed
    local fields, extra = p26.animation_input.fields, p26.animation_input.extra
    local flags_2468, flags_2472, flags_2476, flags_2480 = processed.flags_2468, processed.flags_2472, processed.flags_2476, processed.flags_2480
    local flags_2484, flags_2488, state_2504, frames_since_teleport_2584 = processed.flags_2484, processed.flags_2488, processed.state_2504, processed.frames_since_teleport_2584
    local v27 = processed.line_tests_960_1008_1056[3]
    local v28

    if v27.valid ~= 0 then
        local position = v27.position

        v28 = rt.map(position, rt.from_bits)
    end

    local v29 = processed.vectors_544_560_592_608[3]
    local v30 = rt.map(v29, rt.from_bits)
    local v31 = processed.vectors_544_560_592_608[4]
    local v32 = rt.map(v31, rt.from_bits)
    local offboard_magnitude, offboard_turn, biped_world_x, biped_world_z = extra.offboard_magnitude, extra.offboard_turn, extra.biped_world_x, extra.biped_world_z
    local magnitude_scale, turn_scale = fields.magnitude_scale, fields.turn_scale
    local v33 = rt.copy(fields.animation_translation)
    local animation_time, cadence_end_percent, animation_physics_blend_seconds = fields.animation_time, fields.cadence_end_percent, fields.animation_physics_blend_seconds
    local v34 = rt.copy(p26.biped_ground.ground.frame_80)
    local t3 = {
        processed_flags_2472 = flags_2472,
        processed_direct_2684 = offboard_magnitude,
        processed_direct_2680 = offboard_turn,
        processed_stick_2692 = biped_world_x,
        processed_stick_2688 = biped_world_z,
        processed_scale_2912 = magnitude_scale,
        processed_scale_2908 = turn_scale,
        frame_forward_112 = {
            v34[3][1],
            v34[3][2],
            v34[3][3]
        }
    }
    local v35 = v10.calculate(t3, p26.biped_ground.movement_vs_stick_angle, p26.biped_ground.turn_vs_stick_angle)
    local biped_ground = p26.biped_ground
    local biped_ground2 = biped_ground
    local v36, v37 = v9.prepare(biped_ground.contact, biped_ground.ground.distance_164, {
        contact = p28,
        frame = v34,
        previous_state = state_2504,
        third_line_position = v28,
        frames_since_teleport = frames_since_teleport_2584,
        processed_position = v30,
        processed_velocity = v32,
        controls = v35,
        collision_displacements = rt.copy(p26.collision_extra_errors),
        animation_motion = v33,
        animation_velocity = rt.copy(p26.animated_skeleton.motion.velocity_world),
        requested_duration = animation_time,
        requested_phase = cadence_end_percent,
        override_duration = animation_physics_blend_seconds,
        flags_2472 = flags_2472,
        flags_2476 = flags_2476,
        flags_2480 = flags_2480,
        flags_2484 = flags_2484,
        flags_2488 = flags_2488
    }, function(p29) -- line: 315
        -- upvalues: biped_ground2 (ref), import (copy)
        return import("skate_game/physics/offboard/ground_geometry").State.consume(biped_ground2.geometry, p29)
    end)

    biped_ground2.ground.distance_164 = v37

    local v38 = rt.copy(v36.geometry)

    biped_ground2.geometry_adjustment = v38

    local v39 = rt.copy(biped_ground2.controller.state.position_368)
    local v40 = Owner.run(biped_ground2, v36.job)

    import("skate_game/physics/solid_contacts").constrain_ground(biped_ground2, v40, v39, p25.network_proxies.solids)
    v5.update_feet(p26)
    TruckSteeringState.update(p26.ground.steering, 0, p26.air_settings.steering_blend, flags_2468, flags_2472)
    v3.update_possession(p25, p26)

    local v41 = v5.launch_input(p26, nil)
    local v42 = Owner.prepare_air(p26.biped_ground, v41)

    if v42 ~= nil then
        v5.submit_air(p25, p26, v42)
    end

    biped_ground2 = p26.biped_ground
    biped_ground2.ground.flags_144_to_150[1] = false

    local v43 = v9.sync_frames(biped_ground2.ground, rt.copy(biped_ground2.contact), rt.copy(v40))
    local v44 = import("skate_game/physics/input_phase").collision(p26)
    local v45 = rt.copy(v40.position)
    local physical_body_spin = p26.animation_input.extra.physical_body_spin
    local v46 = rt.copy(p25.settings.step.simulation)
    local t4 = {
        animated = p26.animated_skeleton,
        body = p26.skeleton,
        drives = p26.skeleton_drives,
        ik = p26.foot_ik,
        animation_input = p26.animation_input,
        correction = p26.skeleton_output.correction,
        pose_errors = p26.pose_errors
    }
    local v47

    import("skate_game/physics/skeleton_input_runtime").SkeletonInputRuntime.update_biped_ground(p26.skeleton_input, p26.skeleton_air, p25.board, {
        world_frame = v43,
        centre_of_mass_1056 = v45
    }, p26.biped_ground.skeleton_state, p26.player_input.processed, t4, p26.animation.packet.hierarchy, v44, v46, function(p30) -- line: 386
        -- upvalues: v47 (ref)
        v47 = p30
    end)

    if v47 ~= nil then
        import("skate_game/physics/offboard/skeleton_ground").State.finish_reckoning(p26.biped_ground.skeleton_state, v47, p25.riding, p26.air_reckoning, p26.player_input.processed, physical_body_spin)
    end

    v5.sync_grab(p26)

    return {
        position = rt.copy(p26.biped_ground.ground.frame_80[4]),
        forward = rt.copy(v40.surface_frame[3]),
        up = rt.copy(v40.surface_frame[2]),
        right = rt.copy(v40.surface_frame[1]),
        velocity = rt.copy(v40.velocity),
        animation_up = rt.copy(v43[2]),
        animation_right = rt.copy(v43[1])
    }
end

function t1.update_reference(p31, p32, _, p34) -- line: 416
    -- upvalues: rt (copy), import (copy), v3 (copy), v5 (copy), v9 (copy), v10 (copy), TruckSteeringState (copy), Owner (copy)
    local v48 = rt.copy(p32.player_input.processed)
    local v49 = rt.copy(p32.animation_input.fields)
    local v50 = rt.copy(p32.animation_input.extra)
    local v51 = rt.copy(p32.biped_ground.ground.frame_80)
    local t5 = {
        processed_flags_2472 = v48.flags_2472,
        processed_direct_2684 = v50.offboard_magnitude,
        processed_direct_2680 = v50.offboard_turn,
        processed_stick_2692 = v50.biped_world_x,
        processed_stick_2688 = v50.biped_world_z,
        processed_scale_2912 = v49.magnitude_scale,
        processed_scale_2908 = v49.turn_scale,
        frame_forward_112 = {
            v51[3][1],
            v51[3][2],
            v51[3][3]
        }
    }
    local v52 = v10.calculate(t5, p32.biped_ground.movement_vs_stick_angle, p32.biped_ground.turn_vs_stick_angle)
    local v53 = v48.line_tests_960_1008_1056[3]
    local biped_ground = p32.biped_ground
    local biped_ground2 = biped_ground
    local prepare = v9.prepare
    local contact = biped_ground.contact
    local distance_164 = biped_ground.ground.distance_164
    local t6 = {
        contact = p34,
        frame = v51,
        previous_state = v48.state_2504
    }

    if v53.valid == 0 then
        t6.third_line_position = nil
    else
        local position = v53.position

        t6.third_line_position = rt.map(position, rt.from_bits)
    end

    t6.frames_since_teleport = v48.frames_since_teleport_2584

    local v54 = v48.vectors_544_560_592_608[3]

    t6.processed_position = rt.map(v54, rt.from_bits)

    local v55 = v48.vectors_544_560_592_608[4]

    t6.processed_velocity = rt.map(v55, rt.from_bits)
    t6.controls = v52
    t6.collision_displacements = rt.copy(p32.collision_extra_errors)
    t6.animation_motion = rt.copy(v49.animation_translation)
    t6.animation_velocity = rt.copy(p32.animated_skeleton.motion.velocity_world)
    t6.requested_duration = v49.animation_time
    t6.requested_phase = v49.cadence_end_percent
    t6.override_duration = v49.animation_physics_blend_seconds
    t6.flags_2472 = v48.flags_2472
    t6.flags_2476 = v48.flags_2476
    t6.flags_2480 = v48.flags_2480
    t6.flags_2484 = v48.flags_2484
    t6.flags_2488 = v48.flags_2488

    local v56, v57 = prepare(contact, distance_164, t6, function(p35) -- line: 475
        -- upvalues: biped_ground2 (ref), import (copy)
        return import("skate_game/physics/offboard/ground_geometry").State.consume(biped_ground2.geometry, p35)
    end)

    biped_ground2.ground.distance_164 = v57

    local v58 = rt.copy(v56.geometry)

    biped_ground2.geometry_adjustment = v58

    local v59 = rt.copy(biped_ground2.controller.state.position_368)
    local v60 = Owner.run(biped_ground2, v56.job)

    import("skate_game/physics/solid_contacts").constrain_ground(biped_ground2, v60, v59, p31.network_proxies.solids)
    v5.update_feet(p32)
    TruckSteeringState.update(p32.ground.steering, 0, p32.air_settings.steering_blend, v48.flags_2468, v48.flags_2472)
    v3.update_possession(p31, p32)

    local v61 = v5.launch_input(p32, nil)
    local v62 = Owner.prepare_air(p32.biped_ground, v61)

    if v62 ~= nil then
        v5.submit_air(p31, p32, v62)
    end

    biped_ground2 = p32.biped_ground
    biped_ground2.ground.flags_144_to_150[1] = false

    local v63 = v9.sync_frames(biped_ground2.ground, rt.copy(biped_ground2.contact), rt.copy(v60))
    local v64 = import("skate_game/physics/input_phase").collision(p32)
    local v65 = rt.copy(v60.position)
    local physical_body_spin = p32.animation_input.extra.physical_body_spin
    local v66 = rt.copy(p31.settings.step.simulation)
    local t7 = {
        animated = p32.animated_skeleton,
        body = p32.skeleton,
        drives = p32.skeleton_drives,
        ik = p32.foot_ik,
        animation_input = p32.animation_input,
        correction = p32.skeleton_output.correction,
        pose_errors = p32.pose_errors
    }
    local v67

    import("skate_game/physics/skeleton_input_runtime").SkeletonInputRuntime.update_biped_ground(p32.skeleton_input, p32.skeleton_air, p31.board, {
        world_frame = v63,
        centre_of_mass_1056 = v65
    }, p32.biped_ground.skeleton_state, p32.player_input.processed, t7, p32.animation.packet.hierarchy, v64, v66, function(p36) -- line: 546
        -- upvalues: v67 (ref)
        v67 = p36
    end)

    if v67 ~= nil then
        import("skate_game/physics/offboard/skeleton_ground").State.finish_reckoning(p32.biped_ground.skeleton_state, v67, p31.riding, p32.air_reckoning, p32.player_input.processed, physical_body_spin)
    end

    v5.sync_grab(p32)

    return {
        position = rt.copy(p32.biped_ground.ground.frame_80[4]),
        forward = rt.copy(v60.surface_frame[3]),
        up = rt.copy(v60.surface_frame[2]),
        right = rt.copy(v60.surface_frame[1]),
        velocity = rt.copy(v60.velocity),
        animation_up = rt.copy(v63[2]),
        animation_right = rt.copy(v63[1])
    }
end

function t1.submit_geometry(p37, p38) -- line: 577
    -- upvalues: rt (copy), import (copy)
    local processed = p38.player_input.processed
    local biped_ground = p38.biped_ground
    local result = biped_ground.result

    if result == nil then
        error("Ground geometry submission requires completed motion", 0)
    end

    return import("skate_game/physics/offboard/ground_geometry").State.submit(biped_ground.geometry, p37.world, p37.network_proxies.solids, rt.copy(biped_ground.ground.frame_80), rt.copy(result.velocity), {
        selection_flags_2948 = processed.actor_query_2948,
        matching_id_2952 = rt.to_i32(processed.actor_query_2952)
    }, processed.flags_2488)
end

return t1
