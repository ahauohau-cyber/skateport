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
local v2 = import("skate_game/physics/animation_grind")
local v3 = import("skate_game/physics/animation_phase_packet")
local v4 = import("skate_core/animation/landing_quality")
local IntentMap = import("skate_core/graph/intents").IntentMap
local v5 = import("skate_core/input/grind_intentions")
local v6 = import("skate_core/input/offboard_intentions")
local Vector3 = import("skate_core/math").Vector3
local BodyId = import("skate_core/physics/board").BodyId
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime
local ConditionerCapabilityContext = import("skate_core/player/conditioner_capabilities").ConditionerCapabilityContext
local AnimationPhaseOutput = v3.AnimationPhaseOutput
local v7

local function skater_animation() -- line: 37
    -- upvalues: import (copy), v7 (ref)
    local v8 = v7

    if v8 == nil then
        v8 = import("skate_game/skater_animation")
        v7 = v8
    end

    return v8
end

local v9

local function foot_ik() -- line: 46
    -- upvalues: import (copy), v9 (ref)
    local v10 = v9

    if v10 == nil then
        v10 = import("skate_game/physics/foot_ik")
        v9 = v10
    end

    return v10
end

local v11

local function handplant() -- line: 55
    -- upvalues: import (copy), v11 (ref)
    local v12 = v11

    if v12 == nil then
        v12 = import("skate_game/physics/handplant")
        v11 = v12
    end

    return v12
end

local v13

local function riding_outputs() -- line: 64
    -- upvalues: import (copy), v13 (ref)
    local v14 = v13

    if v14 == nil then
        v14 = import("skate_game/physics/riding_outputs")
        v13 = v14
    end

    return v14
end

local v15

local function teleport_state() -- line: 73
    -- upvalues: import (copy), v15 (ref)
    local v16 = v15

    if v16 == nil then
        v16 = import("skate_game/physics/teleport_state")
        v15 = v16
    end

    return v16
end

local v17

local function animation_feedback() -- line: 82
    -- upvalues: import (copy), v17 (ref)
    local v18 = v17

    if v18 == nil then
        v18 = import("skate_game/physics/animation_feedback")
        v17 = v18
    end

    return v18
end

local v19

local function solve() -- line: 91
    -- upvalues: import (copy), v19 (ref)
    local v20 = v19

    if v20 == nil then
        v20 = import("skate_game/physics/solve")
        v19 = v20
    end

    return v20
end

local v21

local function motion_native() -- line: 100
    -- upvalues: import (copy), v21 (ref)
    local v22 = v21

    if v22 == nil then
        v22 = import("skate_game/graph_host/motion_native")
        v21 = v22
    end

    return v22
end

local t1 = {}
local v23 = BoardRuntime.transform_scratch()

local function deck_transform(p2) -- line: 120
    -- upvalues: BodyId (copy), BoardRuntime (copy), v23 (copy)
    return BoardRuntime.part_transform_into(p2, BodyId.index(BodyId.Deck), v23)
end

t1.AnimationPhaseOutput = v3.AnimationPhaseOutput
t1.AnimationProfile = v3.AnimationProfile

local vec3, vec4, axis

local function map_bits(p3) -- line: 133
    -- upvalues: rt (copy)
    return rt.map(p3, rt.from_bits)
end

function t1.advance(p4, p5, p6, p7, p8) -- line: 141
    -- upvalues: rt (copy), v1 (copy), import (copy), v2 (copy), IntentMap (copy), v5 (copy), v6 (copy), BodyId (copy), BoardRuntime (copy), AnimationPhaseOutput (copy), v7 (ref), v9 (ref), v11 (ref), v13 (ref), v15 (ref), v21 (ref), v23 (copy), vec4 (ref), axis (ref)
    local motion, action = p5.animation.motion, p5.animation.action
    local v24 = v21

    if v24 == nil then
        v24 = import("skate_game/graph_host/motion_native")
        v21 = v24
    end

    motion.score_packet = v24.ScorePacket.default()

    local processed, physical = p5.player_input.processed, p5.player_input.physical

    motion.manual_exit = physical.animation.manual_opposition_168 ~= 0
    motion.deck_yaw_pitch = {
        physical.skeleton.deck_yaw_536,
        physical.skeleton.deck_pitch_540
    }
    motion.offboard_cadence_phase = physical.off_board.cadence_phase_80
    motion.offboard_locomotion_state = physical.off_board.locomotion_state_84
    motion.ground_slope_type = physical.off_board.kind_88
    motion.biped_ground_thin = physical.off_board.flag_330 ~= 0
    action.dropping_in = physical.grinds.dropping_in_324 ~= 0

    local board = p4.board
    local v25 = BoardRuntime.part_transform_into(board, BodyId.index(BodyId.Deck), v23)
    local v26 = v7

    if v26 == nil then
        v26 = import("skate_game/skater_animation")
        v7 = v26
    end

    local v27, v28 = v26.SkaterAnimation.stance(p5.animation)

    motion.toggle_board_physical = {
        grabbing_object = physical.off_board.flag_304 ~= 0,
        holding_board = physical.off_board.flag_311 ~= 0,
        free_board = physical.off_board.free_board_312 ~= 0,
        retrieval_blocked = p5.player_state.state_flags[36],
        retrieval_active = physical.off_board.returning_board_313 ~= 0,
        yaw_radians = physical.off_board.angle_36,
        pitch_radians = physical.off_board.angle_40
    }

    local t2 = {
        offboard_flag_331 = physical.off_board.trajectory_valid_331 ~= 0
    }
    local vector_64 = physical.off_board.vector_64

    t2.offboard_velocity_128 = rt.map(vector_64, rt.from_bits)

    local vector_16 = physical.reckoning.vector_16

    t2.reckoning_velocity_16 = rt.map(vector_16, rt.from_bits)

    local vector_96 = physical.reckoning.vector_96

    t2.reckoning_up_96 = rt.map(vector_96, rt.from_bits)
    t2.skeleton_vector_0 = rt.copy(p5.skeleton_input.drive_frames[1][1])
    t2.animation_mirrored = v28
    motion.runout_physical = t2

    local v29 = rt.copy(p5.physical_feedback)

    motion.wipeout_physical = {
        over_599 = physical.skeleton.over_599 ~= 0,
        collision_time_144 = physical.animation.collision_time_144,
        no_support_time_548 = physical.skeleton.no_support_time_548,
        profile_148 = physical.animation.profile_148,
        below_surface_82 = p5.player_state.state_flags[31],
        orientation_y = p5.skeleton.record.pose[24][2][2],
        hips_right_angle_496 = physical.skeleton.hips_right_angle_496,
        hips_up_angle_500 = physical.skeleton.hips_up_angle_500
    }
    motion.landing_physical = {
        height = v29.crouching.animation_height_72,
        spin = p5.landing_quality.spin_92,
        kind = p5.landing_quality.landing_type_96,
        last_good_landing_velocity = motion.riding.last_good_landing_velocity
    }

    local t3 = {
        air_444 = physical.air.flag_444 ~= 0
    }

    buffer.writeu32(v1, 0, physical.air.landing_normal_144[2])
    t3.air_normal_144_y = buffer.readf32(v1, 0)
    t3.animation_16_x = p5.animation_feedback.published_previous_lateral_tilt[1]
    buffer.writeu32(v1, 0, physical.reckoning.vector_16[2])
    t3.com_velocity_y = buffer.readf32(v1, 0)
    t3.offboard_316 = physical.off_board.flag_316 ~= 0
    t3.offboard_319 = physical.off_board.flag_319 ~= 0
    t3.offboard_time_32 = physical.off_board.scalar_32
    t3.air_437 = physical.air.known_air_valid_437 ~= 0
    buffer.writeu32(v1, 0, physical.air.landing_normal_32[2])
    t3.air_normal_36 = buffer.readf32(v1, 0)
    t3.air_remaining_184 = physical.air.scalar_184
    t3.animation_height_72 = v29.crouching.animation_height_72
    motion.prelanding_physical = t3

    local v33 = v9

    if v33 == nil then
        v33 = import("skate_game/physics/foot_ik")
        v9 = v33
    end

    local v34 = v33.FootIk.physical_toe_positions(p5.foot_ik, p5.skeleton.record)
    local v35 = v34[1]
    local v36 = v34[2]
    local vector_16_2 = physical.reckoning.vector_16
    local t4 = {}

    t4.com_velocity = rt.map(vector_16_2, rt.from_bits)

    local vector_64_2 = physical.reckoning.vector_64

    t4.com_position = rt.map(vector_64_2, rt.from_bits)

    local vector_96_2 = physical.reckoning.vector_96

    t4.system_up = rt.map(vector_96_2, rt.from_bits)
    t4.right_toe = v35
    t4.left_toe = v36
    t4.animation_height = v29.crouching.animation_height_72
    t4.offboard_316 = physical.off_board.flag_316 ~= 0
    t4.remaining_air_time = physical.air.scalar_184
    motion.air_leg_physical = t4
    action.physical_conditions = {
        requests_dismount = p5.player_state.state_flags[26],
        state = physical.state.state_16
    }

    local v37 = false

    for _, v38 in physical.collision.wheel_contact_3296_3299 do
        if v38 ~= 0 then
            v37 = true
            break
        end
    end

    local t5 = {
        state = physical.state.state_16,
        wants_runout = p5.player_state.state_flags[27],
        physics_wiping = p5.player_state.state_flags[8],
        body_flipping = physical.air.flag_441 ~= 0,
        bumped = v29.bumped
    }

    t5.wants_wipeout = p5.player_state.state_flags[12] or p5.player_state.state_flags[14]
    t5.grabbing_object = physical.off_board.flag_304 ~= 0
    t5.retrieving_board = physical.off_board.retrieving_board_323 ~= 0
    t5.dropping_board = physical.off_board.dropping_board_322 ~= 0
    t5.in_biped_air = physical.off_board.flag_328 ~= 0
    t5.hippy_hurdling = physical.off_board.hippy_hurdling_317 ~= 0
    t5.handplant_flags = physical.air.handplant_flags_324
    t5.handplant_time = physical.air.handplant_time_320

    local copy = rt.copy
    local v39 = v11

    if v39 == nil then
        v39 = import("skate_game/physics/handplant")
        v11 = v39
    end

    t5.handplant_thresholds = copy(v39.Handplant.animation_thresholds(p5.handplant))
    t5.footplant_active = physical.air.flag_448 ~= 0
    t5.footplant_duration = physical.air.footplant_duration_212
    t5.footplant_contact_time = physical.air.footplant_contact_time_208
    t5.time_to_skitch = physical.ground.scalar_276
    t5.skitch_transition_time = p8.skitch_transition_time
    t5.time_to_land = physical.air.scalar_184
    t5.time_to_land_valid = physical.air.known_air_valid_437 ~= 0
    t5.offboard_trajectory_time = physical.off_board.trajectory_time_120
    t5.offboard_trajectory_valid = physical.off_board.trajectory_valid_331 ~= 0
    t5.trucks_or_deck_contact = physical.collision.flag_3472 ~= 0 or physical.collision.flag_3475 ~= 0
    t5.offboard_time_to_land = physical.off_board.scalar_32
    t5.offboard_air_scalar_92 = physical.off_board.scalar_92

    local vector_96_3 = physical.off_board.vector_96

    t5.offboard_air_translation = rt.map(vector_96_3, rt.from_bits)

    local vector_192 = physical.off_board.vector_192

    t5.offboard_landing_normal = rt.map(vector_192, rt.from_bits)
    t5.offboard_committed_to_motion = physical.off_board.flag_329 ~= 0
    t5.offboard_obstacle_distance = physical.off_board.scalar_112
    t5.offboard_edge_distance = physical.off_board.distance_116
    buffer.writeu32(v1, 0, physical.reckoning.vector_16[2])
    t5.reached_apex = buffer.readf32(v1, 0) < 0
    t5.can_land_on_board = physical.off_board.flag_316 ~= 0
    t5.landing_turning = physical.off_board.flag_318 ~= 0
    t5.grind_contact = physical.grinds.flag_318 ~= 0 or physical.grinds.flag_322 ~= 0
    t5.wheel_contact = v37
    t5.tricks_blocked_on_stairs = false
    t5.moving_object = physical.state.state_16 == 502
    motion.gameplay_conditions = t5
    action.gameplay_conditions = rt.copy(motion.gameplay_conditions)
    motion.native_physical = {
        centre_of_mass_velocity = rt.copy(p5.animated_skeleton.board_frames.com_velocity),
        system_up = vec4(p4.riding.reckoning.up),
        board_reckoning_z = rt.copy(p4.riding.reckoning_frames.ground[3]),
        board_reckoning = rt.copy(p4.riding.reckoning_frames.ground)
    }
    motion.bump_acceleration = rt.copy(v29.ground_acceleration)
    motion.gesture_physical = {
        ground321 = bit32.band(processed.flags_2480, 4096) ~= 0,
        state_offboard75 = physical.state.category_12 == 500,
        selections = rt.copy(p8.gesture_selections),
        suppress_up = p8.suppress_up_gesture,
        force_brake_bypass = p8.gesture_force_brake_bypass
    }

    local v41 = (processed.category_2512 == 100 or processed.category_2512 == 500) and processed.probe_1792.bytes_72_73[1] ~= 0 and bit32.band(processed.flags_2476, 4194304) ~= 0
    local v42

    if v41 then
        local v43 = if bit32.band(processed.flags_2484, 262144) == 0 then 1 else 0
        local v44 = processed.probe_1792.vectors_16_32_48[v43 + 1]
        local v45 = rt.map(v44, rt.from_bits)
        local v46 = rt.copy(p5.animated_skeleton.roots.world_to_animation)

        v42 = {
            v46[3][1] * v45[3] + (v46[2][1] * v45[2] + (v46[1][1] * v45[1] + v46[4][1])),
            v46[3][2] * v45[3] + (v46[2][2] * v45[2] + (v46[1][2] * v45[1] + v46[4][2])),
            v46[3][3] * v45[3] + (v46[2][3] * v45[2] + (v46[1][3] * v45[1] + v46[4][3])),
            v46[3][4] * v45[3] + (v46[2][4] * v45[2] + (v46[1][4] * v45[1] + v46[4][4]))
        }
    else
        v42 = table.create(4, 0)
    end

    motion.shove_physical = {
        interaction_trigger = v41,
        direction = v42,
        in_biped_category = physical.state.category_12 == 500,
        board_on_ground = physical.off_board.flag_311 ~= 0,
        animation_height = v29.crouching.animation_height_72
    }

    local v47 = v2.publish(motion, physical, p5.player_state.filtered_output, v29.crouching.animation_height_72, v28, rt.copy(p4.riding.motion.effective_basis.columns[3]))
    local v48 = v13

    if v48 == nil then
        v48 = import("skate_game/physics/riding_outputs")
        v13 = v48
    end

    local t7 = {
        speeds = v48.RidingOutputs.graph_speeds(p4.riding),
        physical_state = v47,
        time_since_last_input = processed.time_since_last_input_2748,
        mirrored = v28,
        riding_fakie = v27,
        push_brake = {
            ground_axis_y = p4.riding.ground.wheel_normal.y,
            skeleton_disables_push_brake = p5.foot_ik.state.contacts.support_failed_this_update,
            maximum_ground_angle_degrees = p8.maximum_ground_angle_degrees
        }
    }
    local v49 = rt.copy(p5.animated_skeleton.roots.animation_to_world[3])

    if bit32.band(processed.flags_2476, 4) ~= 0 then
        v49 = rt.map(v49, function(p9) -- line: 355
            return -p9
        end)
    end

    local v50 = rt.copy(p5.animated_skeleton.roots.animation_to_world[1])

    if bit32.band(processed.flags_2476, 4) ~= 0 then
        v50 = rt.map(v50, function(p10) -- line: 361
            return -p10
        end)
    end

    local vector_16_3 = physical.reckoning.vector_16

    motion.riding_conditions = {
        com_velocity = rt.map(vector_16_3, rt.from_bits),
        skeleton_x = rt.copy(v50),
        skeleton_z = rt.copy(v49),
        skate_up_y = v25.basis.columns[2][2],
        surface_up_y = p4.riding.ground.wheel_normal.y
    }

    local t9 = {
        conditions = t7,
        feedback = v29,
        body_tilt = {
            lateral_tilt = p4.riding.reckoning_frames.lateral_tilt[1],
            body_spin_speed = p5.air_reckoning.state.spin_speed,
            filtered_category = physical.filtered_state_0
        },
        fakie = {
            category = physical.filtered_state_0,
            grind_state = physical.state.state_16,
            doing_trick = motion.flags.doing_trick,
            board_axis = rt.copy(v49),
            deck_velocity = vec4(p4.riding.motion.linear_velocity),
            external_velocity = rt.copy(p5.centre_of_mass_output.velocity),
            ground_projected_speed = p4.riding.motion.ground_speed
        },
        physical_stance = {
            p5.animation.packet.regular_stance,
            p5.animation.packet.riding_switch
        },
        foot_frame = {
            left_foot = rt.copy(p5.skeleton.record.pose[16][4]),
            right_foot = rt.copy(p5.skeleton.record.pose[20][4]),
            deck_position = vec4(BoardRuntime.bodies(p4.board)[BodyId.index(BodyId.Deck) + 1].rates.position),
            deck_y = axis(v25.basis.columns[2]),
            deck_z = axis(v25.basis.columns[3]),
            skateboard_flipped = bit32.band(processed.flags_2468, 1048576) ~= 0
        },
        board_present = physical.off_board.flag_311 ~= 0,
        physical_28_byte75 = physical.state.category_12 == 500,
        time_since_teleport = motion.riding.time_since_teleport
    }
    local v51 = rt.copy(p6.action_intents)

    for _, v52 in v5.produce(p6.controller) do
        IntentMap.insert(v51, v52.name, v52.value)
    end

    local contact = p5.biped_ground.controller.state.contact
    local produce_analog = v6.produce_analog
    local controller = p6.controller
    local t11 = {
        effective_skeleton_z = rt.copy(v49),
        biped_correction = if contact.active then rt.copy(contact.direction) else nil
    }

    for _, v53 in produce_analog(controller, t11) do
        IntentMap.insert(v51, v53.name, v53.value)
    end

    for _, v54 in v6.produce_discrete(p6.controller, p6.actor_flags, physical.air.use_air_reckoning_452 ~= 0) do
        IntentMap.insert(v51, v54.name, v54.value)
    end

    local v55 = AnimationPhaseOutput.new()
    local v56 = v7

    if v56 == nil then
        v56 = import("skate_game/skater_animation")
        v7 = v56
    end

    v56.SkaterAnimation.advance(p5.animation, p7, p4.settings.step.simulation.time_step, v51, t9, v55.reset)
    AnimationPhaseOutput.publish(v55, p5.animation.packet, p8, p6.actor_flags)

    local v57 = v15

    if v57 == nil then
        v57 = import("skate_game/physics/teleport_state")
        v15 = v57
    end

    local v58 = v57.Runtime.take_reply(p5.teleport_state)

    if v58 ~= nil then
        AnimationPhaseOutput.publish_external_reset(v55, v58)
    end

    return v55
end

function t1.publish_feedback(p11, p12) -- line: 457
    -- upvalues: rt (copy), import (copy), v4 (copy), BodyId (copy), BoardRuntime (copy), ConditionerCapabilityContext (copy), v17 (ref), v19 (ref), v23 (copy), vec3 (ref), vec4 (ref), axis (ref)
    p12.player_input.physical.scoring.capabilities_204 = ConditionerCapabilityContext.capabilities({
        in_front_end = false,
        hall_of_meat_enabled = false,
        challenge_query_active = false,
        challenge_configuration_enabled = false
    })

    local processed = p12.player_input.processed
    local board = p11.board
    local v59 = BoardRuntime.part_transform_into(board, BodyId.index(BodyId.Deck), v23)

    p12.landing_quality = v4.Output.default()

    local filtered_output = p12.player_state.filtered_output

    if filtered_output ~= nil then
        v4.Output.update(p12.landing_quality, {
            previous_filtered_state = filtered_output.previous_category,
            filtered_state = filtered_output.category,
            ground_normal = vec4(p11.riding.ground.overall_normal),
            deck_velocity = vec4(p11.riding.motion.linear_velocity),
            flipped = bit32.band(processed.flags_2468, 1048576) ~= 0,
            reckoning_forward = axis(v59.basis.columns[3]),
            air_spin = p12.air_reckoning.state.spin_speed
        }, p12.landing_quality_settings)
    end

    local v60 = v17

    if v60 == nil then
        v60 = import("skate_game/physics/animation_feedback")
        v17 = v60
    end

    local update = v60.AnimationFeedback.update
    local animation_feedback = p12.animation_feedback
    local motion = p11.riding.motion
    local pumping, wobble = p12.ground.pumping, p12.ground.wobble
    local t13 = {
        system_position = vec3(p12.animated_skeleton.board_frames.centre_of_mass),
        system_up = rt.copy(p11.riding.reckoning.up),
        board_position = rt.copy(v59.translation),
        target_lean_angle = p11.riding.reckoning_frames.target_lean_angle
    }
    local t14 = {
        processed_flags = processed.flags_2468,
        turn = p12.animation_input.fields.turn,
        animation_mirrored = p12.animation.packet.mirrored
    }
    local v61 = v19

    if v61 == nil then
        v61 = import("skate_game/physics/solve")
        v19 = v61
    end

    local v62 = update(animation_feedback, motion, pumping, wobble, t13, t14, {
        deck = v61.deck_frame(p11.board),
        ground = rt.copy(p11.riding.reckoning_frames.ground),
        world_acceleration = vec4(p11.riding.ground.accelerations[BodyId.index(BodyId.Deck) + 1])
    }, rt.copy(p11.riding.reckoning_frames.lateral_tilt))

    p12.physical_feedback = rt.copy(v62)

    return v62
end

function t1.initial_feedback() -- line: 517
    return {
        pumping_acceleration = 0,
        bumped = false,
        turning = {
            field_32 = 0,
            field_36 = 0,
            field_52 = 0,
            field_56 = 0,
            field_60 = 0,
            body_168 = 0
        },
        crouching = {
            body_84 = 0,
            body_164 = 0,
            body_188 = 0,
            force_516 = 0,
            ground_force_520 = 0,
            minimum_crouch_528 = 0,
            deck_angle_532 = 0,
            animation_height_72 = 0
        },
        ground_acceleration = table.create(4, 0),
        conditioned_turn = table.create(8, 0)
    }
end

function vec3(p13) -- line: 545
    -- upvalues: Vector3 (copy)
    return Vector3.new(p13[1], p13[2], p13[3])
end

t1.vec3 = vec3

function vec4(p14) -- line: 550
    return {
        p14.x,
        p14.y,
        p14.z,
        0
    }
end

t1.vec4 = vec4

function axis(p15) -- line: 555
    return {
        p15[1],
        p15[2],
        p15[3],
        0
    }
end

t1.axis = axis

return t1
