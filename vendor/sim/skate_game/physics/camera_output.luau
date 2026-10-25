-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1, v2, v3, v4, v5, v6

local function physics_mod() -- line: 14
    -- upvalues: import (copy), v1 (ref)
    if v1 == nil then
        v1 = import("skate_game/physics")
    end

    return v1
end

local function camera_mod() -- line: 20
    -- upvalues: import (copy), v2 (ref)
    if v2 == nil then
        v2 = import("skate_game/camera")
    end

    return v2
end

local function player_state() -- line: 26
    -- upvalues: import (copy), v3 (ref)
    if v3 == nil then
        v3 = import("skate_game/physics/player_state")
    end

    return v3
end

local function skater_animation() -- line: 32
    -- upvalues: import (copy), v4 (ref)
    if v4 == nil then
        v4 = import("skate_game/skater_animation")
    end

    return v4
end

local function camera_runtime() -- line: 38
    -- upvalues: import (copy), v5 (ref)
    if v5 == nil then
        v5 = import("skate_game/camera/runtime")
    end

    return v5
end

local function publication() -- line: 44
    -- upvalues: import (copy), v6 (ref)
    if v6 == nil then
        v6 = import("skate_game/camera/publication")
    end

    return v6
end

local PERF = import("skate_core/camera/tracker").PERF
local t1 = {}
local bit, offboard_output

local function map_bits(p1) -- line: 57
    -- upvalues: rt (copy)
    return rt.map(p1, rt.from_bits)
end

t1.StaticWorld = {}
t1.camera_type = 1

function t1.set_camera_type(p2) -- line: 71
    -- upvalues: t1 (copy)
    t1.camera_type = p2 == 0 and 0 or 1
end

function t1.StaticWorld.collect(_, _, _, _, _) -- line: 75
    return 0
end

function t1.advance_reference(p8, p9, p10, p11) -- line: 85
    -- upvalues: rt (copy), import (copy), v1 (ref), v2 (ref), v3 (ref), v4 (ref), t1 (copy)
    if v1 == nil then
        v1 = import("skate_game/physics")
    end

    local v7 = v1.SimulationExchange.output(p8.exchange)

    if v7 == nil then
        error("Camera requires the completed physical output snapshot", 0)
    end

    if p8.ticks < 1 then
        error("Camera received physical output before the first completed tick", 0)
    end

    local v8 = p8.ticks - 1

    if v3 == nil then
        v3 = import("skate_game/physics/player_state")
    end

    local PlayerState = v3.PlayerState

    if v7.tick ~= v8 or v7.state ~= PlayerState.current(p9.player_state) then
        error(string.format("Camera received stale physical output: output_tick=%d, completed_tick=%d, output_state=%s, selected_state=%s", v7.tick, v8, tostring(v7.state), (tostring(PlayerState.current(p9.player_state)))), 0)
    end

    if v4 == nil then
        v4 = import("skate_game/skater_animation")
    end

    local _, v10 = v4.SkaterAnimation.stance(p9.animation)
    local v11 = t1.publish(p9, v7, p10, rt.copy(p9.centre_of_mass_output), {
        shake_variant = 0,
        value_32 = 0,
        invert_look = table.create(2, false)
    }, if v10 then 1 else 0, 1, v7.tick)

    if v2 == nil then
        v2 = import("skate_game/camera")
    end

    local v12 = v2.publish_camera_subject(p8, p9, v11)
    local t2 = {
        on_road = false,
        ledge_left = false,
        ledge_right = false,
        camera_type = t1.camera_type,
        volumes = {}
    }
    local gravity_acceleration = p8.settings.step.simulation.gravity_acceleration
    local t3 = {}

    if v2 == nil then
        v2 = import("skate_game/camera")
    end

    local advance = v2.CameraRuntime.advance
    local time_step = p8.settings.step.simulation.time_step

    if v1 == nil then
        v1 = import("skate_game/physics")
    end

    advance(p11, time_step, v12, v1.GamePhysics.world(p8), {
        gravity_acceleration.x,
        gravity_acceleration.y,
        gravity_acceleration.z,
        0
    }, t2, {
        collect = function(_, p13, p14, p15, p16) -- collect | line: 147
            -- upvalues: t3 (copy), t1 (copy)
            return t1.StaticWorld.collect(t3, p13, p14, p15, p16)
        end
    })
end

function t1.publish(p17, p18, p19, p20, p21, p22, p23, p24) -- line: 161
    -- upvalues: rt (copy), bit (ref), offboard_output (ref)
    local processed, physical = p17.player_input.processed, p17.player_input.physical
    local fields = p17.animation_input.fields
    local flags = p17.animation_input.output.flags
    local packet = p17.animation.packet
    local t6 = {
        ground_scalar_288 = 0,
        tick = p24
    }

    t6.state = {
        height_32 = physical.state.surface_height_32,
        physically_pushing_55 = bit(processed.flags_2468, 25),
        wiping_out_59 = bit(processed.flags_2468, 18),
        manual_60 = fields.balance == 0 and 0 or 1,
        reset_62 = bit(processed.flags_2472, 10),
        use_skeleton_root_75 = physical.state.category_12 == 500 and 1 or 0,
        flag_79 = processed.state_variant_index_2528 == 3 and 1 or 0,
        flag_81 = p17.player_state.state_flags[30] and 1 or 0
    }
    t6.animation = {
        conditioned_turn = rt.copy(p19.conditioned_turn),
        input_turn_64 = fields.turn,
        input_kickturn_68 = processed.spin_input_2672,
        time_since_input_128 = processed.time_since_last_input_2748,
        wipeout_tweak_148 = physical.animation.profile_148,
        stance_155 = packet.riding_fakie and 1 or 0,
        running_out_160 = bit(processed.flags_2480, 2),
        skater_animation_stance = p22
    }

    local trajectory_apex_0 = physical.air.trajectory_apex_0
    local t9 = {}

    t9.apex_0 = rt.map(trajectory_apex_0, rt.from_bits)

    local collision_position_16 = physical.air.collision_position_16

    t9.landing_position_16 = rt.map(collision_position_16, rt.from_bits)

    local landing_normal_32 = physical.air.landing_normal_32

    t9.landing_normal_32 = rt.map(landing_normal_32, rt.from_bits)

    local selector_vector_48 = physical.air.selector_vector_48

    t9.launch_position_48 = rt.map(selector_vector_48, rt.from_bits)

    local landing_heading_80 = physical.air.landing_heading_80

    t9.heading_80 = rt.map(landing_heading_80, rt.from_bits)
    t9.time_176 = physical.air.time_in_state_176
    t9.duration_180 = physical.air.collision_time_180
    t9.apex_time_196 = physical.air.time_to_apex_196
    t9.flag_440 = bit(processed.flags_2468, 22)
    t6.air = t9
    t6.offboard = offboard_output(physical.off_board)

    local direction_0 = physical.grinds.direction_0
    local t10 = {}

    t10.direction_0 = rt.map(direction_0, rt.from_bits)

    local camera_target_96 = physical.grinds.camera_target_96

    t10.camera_target_96 = rt.map(camera_target_96, rt.from_bits)
    t10.grinding_316 = physical.grinds.grinding_316
    t6.grinds = t10
    t6.events = {
        broken_bone_duration_200 = 0,
        intent_51 = bit(flags, 28),
        preparing_52 = bit(flags, 27),
        dropping_in_63 = bit(flags, 22),
        trick_125 = bit(processed.flags_2480, 11),
        hippy_jump_322 = physical.ground.hippy_jumping_322,
        capabilities_204 = physical.scoring.capabilities_204
    }
    t6.damped_com_80 = rt.copy(p20.position)
    t6.ground_up_80 = {
        p18.ground_normal.x,
        p18.ground_normal.y,
        p18.ground_normal.z,
        0
    }
    t6.look_552_556 = {
        p17.animation_input.extra.look_x,
        p17.animation_input.extra.look_y
    }
    t6.collision_look_target_64 = {
        p18.predicted_position.x,
        p18.predicted_position.y,
        p18.predicted_position.z,
        0
    }
    t6.preferences = p21
    t6.context = p23

    return t6
end

function bit(p25, p26) -- line: 255
    return (bit32.band(bit32.rshift(p25, p26), 1))
end

t1.bit = bit

function offboard_output(p27) -- line: 264
    -- upvalues: rt (copy)
    local t11 = {
        duration_92 = p27.scalar_92,
        time_152 = p27.scalar_152,
        apex_time_156 = p27.scalar_156
    }
    local vector_160 = p27.vector_160

    t11.launch_normal_160 = rt.map(vector_160, rt.from_bits)

    local vector_176 = p27.vector_176

    t11.launch_position_176 = rt.map(vector_176, rt.from_bits)

    local vector_192 = p27.vector_192

    t11.landing_normal_192 = rt.map(vector_192, rt.from_bits)

    local vector_208 = p27.vector_208

    t11.landing_position_208 = rt.map(vector_208, rt.from_bits)

    local vector_224 = p27.vector_224

    t11.heading_224 = rt.map(vector_224, rt.from_bits)

    local vector_240 = p27.vector_240

    t11.apex_240 = rt.map(vector_240, rt.from_bits)
    t11.object_held_304 = p27.flag_308
    t11.hurdle_317 = p27.hippy_hurdling_317
    t11.use_trajectory_331 = p27.trajectory_valid_331
    t11.dropping_in_334 = p27.flag_334

    return t11
end

t1.offboard_output = offboard_output

local v15 = buffer.create(4)

local function from_bits(p28) -- line: 307
    -- upvalues: v15 (copy)
    buffer.writeu32(v15, 0, p28)

    return (buffer.readf32(v15, 0))
end

local function bits4(p29, p30) -- line: 312
    -- upvalues: v15 (copy)
    buffer.writeu32(v15, 0, p30[1])

    local v17 = buffer.readf32(v15, 0)

    buffer.writeu32(v15, 0, p30[2])

    local v19 = buffer.readf32(v15, 0)

    buffer.writeu32(v15, 0, p30[3])

    local v21 = buffer.readf32(v15, 0)

    buffer.writeu32(v15, 0, p30[4])

    local v23 = buffer.readf32(v15, 0)

    p29[1] = v17
    p29[2] = v19
    p29[3] = v21
    p29[4] = v23
end

local function zero4() -- line: 316
    return { 0, 0, 0, 0 }
end

local v24 = table.freeze({
    shake_variant = 0,
    value_32 = 0,
    invert_look = table.freeze({ false, false })
})

local function environment_of(p31) -- line: 326
    return table.freeze({
        on_road = false,
        ledge_left = false,
        ledge_right = false,
        camera_type = p31,
        volumes = table.freeze({})
    })
end

local v25 = table.freeze({
    [0] = environment_of(0),
    [1] = environment_of(1)
})
local t12 = {
    0, 0, 0, 0
}
local t13 = {}
local v26 = table.freeze({
    collects_nothing = true,
    collect = function(_, p33, p34, p35, p36) -- collect | line: 340
        -- upvalues: t1 (copy), t13 (copy)
        return t1.StaticWorld.collect(t13, p33, p34, p35, p36)
    end
})
local t15 = {
    tick = 0,
    damped_com_80 = false,
    ground_scalar_288 = 0,
    context = 0,
    state = {
        height_32 = 0,
        physically_pushing_55 = 0,
        wiping_out_59 = 0,
        manual_60 = 0,
        reset_62 = 0,
        use_skeleton_root_75 = 0,
        flag_79 = 0,
        flag_81 = 0
    },
    animation = {
        conditioned_turn = false,
        input_turn_64 = 0,
        input_kickturn_68 = 0,
        time_since_input_128 = 0,
        wipeout_tweak_148 = 0,
        stance_155 = 0,
        running_out_160 = 0,
        skater_animation_stance = 0
    },
    air = {
        time_176 = 0,
        duration_180 = 0,
        apex_time_196 = 0,
        flag_440 = 0,
        apex_0 = { 0, 0, 0, 0 },
        landing_position_16 = { 0, 0, 0, 0 },
        landing_normal_32 = { 0, 0, 0, 0 },
        launch_position_48 = { 0, 0, 0, 0 },
        heading_80 = { 0, 0, 0, 0 }
    },
    offboard = {
        duration_92 = 0,
        time_152 = 0,
        apex_time_156 = 0,
        object_held_304 = 0,
        hurdle_317 = 0,
        use_trajectory_331 = 0,
        dropping_in_334 = 0,
        launch_normal_160 = { 0, 0, 0, 0 },
        launch_position_176 = { 0, 0, 0, 0 },
        landing_normal_192 = { 0, 0, 0, 0 },
        landing_position_208 = { 0, 0, 0, 0 },
        heading_224 = { 0, 0, 0, 0 },
        apex_240 = { 0, 0, 0, 0 }
    },
    grinds = {
        grinding_316 = 0,
        direction_0 = { 0, 0, 0, 0 },
        camera_target_96 = { 0, 0, 0, 0 }
    },
    events = {
        intent_51 = 0,
        preparing_52 = 0,
        dropping_in_63 = 0,
        trick_125 = 0,
        hippy_jump_322 = 0,
        broken_bone_duration_200 = 0,
        capabilities_204 = 0
    },
    ground_up_80 = { 0, 0, 0, 0 },
    look_552_556 = { 0, 0 },
    collision_look_target_64 = { 0, 0, 0, 0 },
    preferences = v24
}

local function publish_inputs(p37, p38, p39, p40, p41, p42, p43) -- line: 417
    -- upvalues: bit (ref), v15 (copy), t15 (copy)
    local animation_input = p37.player_input
    local air, physical = animation_input.processed, animation_input.physical

    animation_input = p37.animation_input

    local v27 = animation_input.fields
    local flags = animation_input.output.flags
    local flags_2468, flags_2480 = air.flags_2468, air.flags_2480

    t15.tick = p43

    local off_board = t15.state

    off_board.height_32 = physical.state.surface_height_32
    off_board.physically_pushing_55 = bit(flags_2468, 25)
    off_board.wiping_out_59 = bit(flags_2468, 18)
    off_board.manual_60 = v27.balance == 0 and 0 or 1
    off_board.reset_62 = bit(air.flags_2472, 10)
    off_board.use_skeleton_root_75 = physical.state.category_12 == 500 and 1 or 0
    off_board.flag_79 = air.state_variant_index_2528 == 3 and 1 or 0
    off_board.flag_81 = p37.player_state.state_flags[30] and 1 or 0
    off_board = t15.animation
    off_board.conditioned_turn = p39.conditioned_turn
    off_board.input_turn_64 = v27.turn
    off_board.input_kickturn_68 = air.spin_input_2672
    off_board.time_since_input_128 = air.time_since_last_input_2748
    off_board.wipeout_tweak_148 = physical.animation.profile_148
    off_board.stance_155 = p37.animation.packet.riding_fakie and 1 or 0
    off_board.running_out_160 = bit(flags_2480, 2)
    off_board.skater_animation_stance = p41
    off_board = physical.off_board
    v27 = off_board.trajectory_valid_331 ~= 0
    air = physical.air

    local offboard = t15.air
    local apex_0, trajectory_apex_0, v28, v29, v30, v31, v32, v33, v34, v35

    if not v27 then
        apex_0 = offboard.apex_0
        trajectory_apex_0 = air.trajectory_apex_0
        v28 = trajectory_apex_0[1]
        buffer.writeu32(v15, 0, v28)
        v29 = buffer.readf32(v15, 0)
        v30 = trajectory_apex_0[2]
        buffer.writeu32(v15, 0, v30)
        v31 = buffer.readf32(v15, 0)
        v32 = trajectory_apex_0[3]
        buffer.writeu32(v15, 0, v32)
        v34 = buffer.readf32(v15, 0)
        v35 = trajectory_apex_0[4]
        buffer.writeu32(v15, 0, v35)
        v33 = buffer.readf32(v15, 0)
        apex_0[1] = v29
        apex_0[2] = v31
        apex_0[3] = v34
        apex_0[4] = v33
        apex_0 = offboard.landing_position_16
        trajectory_apex_0 = air.collision_position_16
        v28 = trajectory_apex_0[1]
        buffer.writeu32(v15, 0, v28)
        v29 = buffer.readf32(v15, 0)
        v30 = trajectory_apex_0[2]
        buffer.writeu32(v15, 0, v30)
        v31 = buffer.readf32(v15, 0)
        v32 = trajectory_apex_0[3]
        buffer.writeu32(v15, 0, v32)
        v34 = buffer.readf32(v15, 0)
        v35 = trajectory_apex_0[4]
        buffer.writeu32(v15, 0, v35)
        v33 = buffer.readf32(v15, 0)
        apex_0[1] = v29
        apex_0[2] = v31
        apex_0[3] = v34
        apex_0[4] = v33
        apex_0 = offboard.landing_normal_32
        trajectory_apex_0 = air.landing_normal_32
        v28 = trajectory_apex_0[1]
        buffer.writeu32(v15, 0, v28)
        v29 = buffer.readf32(v15, 0)
        v30 = trajectory_apex_0[2]
        buffer.writeu32(v15, 0, v30)
        v31 = buffer.readf32(v15, 0)
        v32 = trajectory_apex_0[3]
        buffer.writeu32(v15, 0, v32)
        v34 = buffer.readf32(v15, 0)
        v35 = trajectory_apex_0[4]
        buffer.writeu32(v15, 0, v35)
        v33 = buffer.readf32(v15, 0)
        apex_0[1] = v29
        apex_0[2] = v31
        apex_0[3] = v34
        apex_0[4] = v33
        apex_0 = offboard.launch_position_48
        trajectory_apex_0 = air.selector_vector_48
        v28 = trajectory_apex_0[1]
        buffer.writeu32(v15, 0, v28)
        v29 = buffer.readf32(v15, 0)
        v30 = trajectory_apex_0[2]
        buffer.writeu32(v15, 0, v30)
        v31 = buffer.readf32(v15, 0)
        v32 = trajectory_apex_0[3]
        buffer.writeu32(v15, 0, v32)
        v34 = buffer.readf32(v15, 0)
        v35 = trajectory_apex_0[4]
        buffer.writeu32(v15, 0, v35)
        v33 = buffer.readf32(v15, 0)
        apex_0[1] = v29
        apex_0[2] = v31
        apex_0[3] = v34
        apex_0[4] = v33
        apex_0 = offboard.heading_80
        trajectory_apex_0 = air.landing_heading_80
        v28 = trajectory_apex_0[1]
        buffer.writeu32(v15, 0, v28)
        v29 = buffer.readf32(v15, 0)
        v30 = trajectory_apex_0[2]
        buffer.writeu32(v15, 0, v30)
        v31 = buffer.readf32(v15, 0)
        v32 = trajectory_apex_0[3]
        buffer.writeu32(v15, 0, v32)
        v34 = buffer.readf32(v15, 0)
        v35 = trajectory_apex_0[4]
        buffer.writeu32(v15, 0, v35)
        v33 = buffer.readf32(v15, 0)
        apex_0[1] = v29
        apex_0[2] = v31
        apex_0[3] = v34
        apex_0[4] = v33
    end

    offboard.time_176 = air.time_in_state_176
    offboard.duration_180 = air.collision_time_180
    offboard.apex_time_196 = air.time_to_apex_196
    offboard.flag_440 = bit(flags_2468, 22)
    offboard = t15.offboard
    offboard.duration_92 = off_board.scalar_92
    offboard.time_152 = off_board.scalar_152
    offboard.apex_time_156 = off_board.scalar_156

    if v27 then
        apex_0 = offboard.launch_normal_160
        trajectory_apex_0 = off_board.vector_160
        v28 = trajectory_apex_0[1]
        buffer.writeu32(v15, 0, v28)
        v29 = buffer.readf32(v15, 0)
        v30 = trajectory_apex_0[2]
        buffer.writeu32(v15, 0, v30)
        v31 = buffer.readf32(v15, 0)
        v32 = trajectory_apex_0[3]
        buffer.writeu32(v15, 0, v32)
        v34 = buffer.readf32(v15, 0)
        v35 = trajectory_apex_0[4]
        buffer.writeu32(v15, 0, v35)
        v33 = buffer.readf32(v15, 0)
        apex_0[1] = v29
        apex_0[2] = v31
        apex_0[3] = v34
        apex_0[4] = v33
        apex_0 = offboard.launch_position_176
        trajectory_apex_0 = off_board.vector_176
        v28 = trajectory_apex_0[1]
        buffer.writeu32(v15, 0, v28)
        v29 = buffer.readf32(v15, 0)
        v30 = trajectory_apex_0[2]
        buffer.writeu32(v15, 0, v30)
        v31 = buffer.readf32(v15, 0)
        v32 = trajectory_apex_0[3]
        buffer.writeu32(v15, 0, v32)
        v34 = buffer.readf32(v15, 0)
        v35 = trajectory_apex_0[4]
        buffer.writeu32(v15, 0, v35)
        v33 = buffer.readf32(v15, 0)
        apex_0[1] = v29
        apex_0[2] = v31
        apex_0[3] = v34
        apex_0[4] = v33
        apex_0 = offboard.landing_normal_192
        trajectory_apex_0 = off_board.vector_192
        v28 = trajectory_apex_0[1]
        buffer.writeu32(v15, 0, v28)
        v29 = buffer.readf32(v15, 0)
        v30 = trajectory_apex_0[2]
        buffer.writeu32(v15, 0, v30)
        v31 = buffer.readf32(v15, 0)
        v32 = trajectory_apex_0[3]
        buffer.writeu32(v15, 0, v32)
        v34 = buffer.readf32(v15, 0)
        v35 = trajectory_apex_0[4]
        buffer.writeu32(v15, 0, v35)
        v33 = buffer.readf32(v15, 0)
        apex_0[1] = v29
        apex_0[2] = v31
        apex_0[3] = v34
        apex_0[4] = v33
        apex_0 = offboard.landing_position_208
        trajectory_apex_0 = off_board.vector_208
        v28 = trajectory_apex_0[1]
        buffer.writeu32(v15, 0, v28)
        v29 = buffer.readf32(v15, 0)
        v30 = trajectory_apex_0[2]
        buffer.writeu32(v15, 0, v30)
        v31 = buffer.readf32(v15, 0)
        v32 = trajectory_apex_0[3]
        buffer.writeu32(v15, 0, v32)
        v34 = buffer.readf32(v15, 0)
        v35 = trajectory_apex_0[4]
        buffer.writeu32(v15, 0, v35)
        v33 = buffer.readf32(v15, 0)
        apex_0[1] = v29
        apex_0[2] = v31
        apex_0[3] = v34
        apex_0[4] = v33
        apex_0 = offboard.heading_224
        trajectory_apex_0 = off_board.vector_224
        v28 = trajectory_apex_0[1]
        buffer.writeu32(v15, 0, v28)
        v29 = buffer.readf32(v15, 0)
        v30 = trajectory_apex_0[2]
        buffer.writeu32(v15, 0, v30)
        v31 = buffer.readf32(v15, 0)
        v32 = trajectory_apex_0[3]
        buffer.writeu32(v15, 0, v32)
        v34 = buffer.readf32(v15, 0)
        v35 = trajectory_apex_0[4]
        buffer.writeu32(v15, 0, v35)
        v33 = buffer.readf32(v15, 0)
        apex_0[1] = v29
        apex_0[2] = v31
        apex_0[3] = v34
        apex_0[4] = v33
        apex_0 = offboard.apex_240
        trajectory_apex_0 = off_board.vector_240
        v28 = trajectory_apex_0[1]
        buffer.writeu32(v15, 0, v28)
        v29 = buffer.readf32(v15, 0)
        v30 = trajectory_apex_0[2]
        buffer.writeu32(v15, 0, v30)
        v31 = buffer.readf32(v15, 0)
        v32 = trajectory_apex_0[3]
        buffer.writeu32(v15, 0, v32)
        v34 = buffer.readf32(v15, 0)
        v35 = trajectory_apex_0[4]
        buffer.writeu32(v15, 0, v35)
        v33 = buffer.readf32(v15, 0)
        apex_0[1] = v29
        apex_0[2] = v31
        apex_0[3] = v34
        apex_0[4] = v33
    end

    offboard.object_held_304 = off_board.flag_308
    offboard.hurdle_317 = off_board.hippy_hurdling_317
    offboard.use_trajectory_331 = off_board.trajectory_valid_331
    offboard.dropping_in_334 = off_board.flag_334
    offboard = physical.grinds
    off_board = t15.grinds
    apex_0 = off_board.direction_0
    trajectory_apex_0 = offboard.direction_0
    buffer.writeu32(v15, 0, trajectory_apex_0[1])
    v29 = buffer.readf32(v15, 0)
    buffer.writeu32(v15, 0, trajectory_apex_0[2])
    v31 = buffer.readf32(v15, 0)
    buffer.writeu32(v15, 0, trajectory_apex_0[3])
    v34 = buffer.readf32(v15, 0)
    buffer.writeu32(v15, 0, trajectory_apex_0[4])
    v33 = buffer.readf32(v15, 0)
    apex_0[1] = v29
    apex_0[2] = v31
    apex_0[3] = v34
    apex_0[4] = v33
    apex_0 = off_board.camera_target_96
    trajectory_apex_0 = offboard.camera_target_96
    buffer.writeu32(v15, 0, trajectory_apex_0[1])
    v29 = buffer.readf32(v15, 0)
    buffer.writeu32(v15, 0, trajectory_apex_0[2])
    v31 = buffer.readf32(v15, 0)
    buffer.writeu32(v15, 0, trajectory_apex_0[3])
    v34 = buffer.readf32(v15, 0)
    buffer.writeu32(v15, 0, trajectory_apex_0[4])
    v33 = buffer.readf32(v15, 0)
    apex_0[1] = v29
    apex_0[2] = v31
    apex_0[3] = v34
    apex_0[4] = v33
    off_board.grinding_316 = offboard.grinding_316
    offboard = t15.events
    offboard.intent_51 = bit(flags, 28)
    offboard.preparing_52 = bit(flags, 27)
    offboard.dropping_in_63 = bit(flags, 22)
    offboard.trick_125 = bit(flags_2480, 11)
    offboard.hippy_jump_322 = physical.ground.hippy_jumping_322
    offboard.broken_bone_duration_200 = 0
    offboard.capabilities_204 = physical.scoring.capabilities_204
    t15.damped_com_80 = p40.position
    apex_0 = p38.ground_normal
    trajectory_apex_0 = t15.ground_up_80

    local x = apex_0.x

    v28 = apex_0.y
    v29 = apex_0.z
    trajectory_apex_0[1] = x
    trajectory_apex_0[2] = v28
    trajectory_apex_0[3] = v29
    trajectory_apex_0[4] = 0
    t15.ground_scalar_288 = 0
    x = animation_input.extra
    v28 = t15.look_552_556
    v29 = x.look_x
    v31 = x.look_y
    v28[1] = v29
    v28[2] = v31
    v29 = p38.predicted_position
    v31 = t15.collision_look_target_64
    v34 = v29.x
    v33 = v29.y

    local z = v29.z

    v31[1] = v34
    v31[2] = v33
    v31[3] = z
    v31[4] = 0
    t15.context = p42

    return t15
end

function t1.advance(p44, p45, p46, p47) -- line: 501
    -- upvalues: import (copy), v1 (ref), v3 (ref), v4 (ref), v5 (ref), v6 (ref), PERF (copy), t1 (copy), v25 (copy), t12 (copy), v26 (copy), publish_inputs (copy)
    if PERF.reference then
        return t1.advance_reference(p44, p45, p46, p47)
    end

    if v1 == nil then
        v1 = import("skate_game/physics")
    end

    local v36 = v1.SimulationExchange.output(p44.exchange)

    if v36 == nil then
        error("Camera requires the completed physical output snapshot", 0)
    end

    if p44.ticks < 1 then
        error("Camera received physical output before the first completed tick", 0)
    end

    local v37 = p44.ticks - 1

    if v3 == nil then
        v3 = import("skate_game/physics/player_state")
    end

    local PlayerState = v3.PlayerState

    if v36.tick ~= v37 or v36.state ~= PlayerState.current(p45.player_state) then
        error(string.format("Camera received stale physical output: output_tick=%d, completed_tick=%d, output_state=%s, selected_state=%s", v36.tick, v37, tostring(v36.state), (tostring(PlayerState.current(p45.player_state)))), 0)
    end

    if v4 == nil then
        v4 = import("skate_game/skater_animation")
    end

    local _, v39 = v4.SkaterAnimation.stance(p45.animation)
    local v41 = publish_inputs(p45, v36, p46, p45.centre_of_mass_output, if v39 then 1 else 0, 1, v36.tick)

    if v6 == nil then
        v6 = import("skate_game/camera/publication")
    end

    local v42 = v6.snapshot_into(p44, p45, v41, p47.latest_subject)
    local simulation = p44.settings.step.simulation
    local gravity_acceleration = simulation.gravity_acceleration
    local x, y, z = gravity_acceleration.x, gravity_acceleration.y, gravity_acceleration.z

    t12[1] = x
    t12[2] = y
    t12[3] = z
    t12[4] = 0

    if v5 == nil then
        v5 = import("skate_game/camera/runtime")
    end

    local advance_in_place = v5.CameraRuntime.advance_in_place
    local time_step = simulation.time_step

    if v1 == nil then
        v1 = import("skate_game/physics")
    end

    advance_in_place(p47, time_step, v42, v1.GamePhysics.world(p44), t12, v25[t1.camera_type], v26)
end

return t1
