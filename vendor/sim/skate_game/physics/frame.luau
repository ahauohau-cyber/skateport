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
local BodyId = import("skate_core/physics/board").BodyId
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime
local PhysicalStateId = import("skate_core/player/state").PhysicalStateId
local FilteredCategory = import("skate_core/physics/filtered_state").FilteredCategory
local CentreOfMassFilter = import("skate_core/physics/centre_of_mass_filter").CentreOfMassFilter
local SkeletonOutputFields = import("skate_core/player/input_phase").SkeletonOutputFields

local function physics_mod() -- line: 26
    -- upvalues: import (copy)
    return import("skate_game/physics")
end

local function clock() -- line: 29
    -- upvalues: import (copy)
    return import("skate_game/physics/clock")
end

local function player_state() -- line: 32
    -- upvalues: import (copy)
    return import("skate_game/physics/player_state")
end

local function climbing() -- line: 35
    -- upvalues: import (copy)
    return import("skate_game/physics/climbing")
end

local function climbing_approach() -- line: 38
    -- upvalues: import (copy)
    return import("skate_game/physics/climbing/approach")
end

local function biped_air() -- line: 41
    -- upvalues: import (copy)
    return import("skate_game/physics/biped_air")
end

local function biped_ground() -- line: 44
    -- upvalues: import (copy)
    return import("skate_game/physics/biped_ground")
end

local function riding_outputs() -- line: 47
    -- upvalues: import (copy)
    return import("skate_game/physics/riding_outputs")
end

local function foot_ik_queries() -- line: 50
    -- upvalues: import (copy)
    return import("skate_game/physics/foot_ik_queries")
end

local function animation_phase() -- line: 53
    -- upvalues: import (copy)
    return import("skate_game/physics/animation_phase")
end

local function animation_phase_packet() -- line: 56
    -- upvalues: import (copy)
    return import("skate_game/physics/animation_phase_packet")
end

local function controls_mod() -- line: 59
    -- upvalues: import (copy)
    return import("skate_game/physics/controls")
end

local function input_phase() -- line: 62
    -- upvalues: import (copy)
    return import("skate_game/physics/input_phase")
end

local function ground_phase() -- line: 65
    -- upvalues: import (copy)
    return import("skate_game/physics/ground_phase")
end

local function ground_runtime() -- line: 68
    -- upvalues: import (copy)
    return import("skate_game/physics/ground_runtime")
end

local function respawn() -- line: 71
    -- upvalues: import (copy)
    return import("skate_game/physics/respawn")
end

local function animation_feedback() -- line: 74
    -- upvalues: import (copy)
    return import("skate_game/physics/animation_feedback")
end

local function animation_input() -- line: 77
    -- upvalues: import (copy)
    return import("skate_game/physics/animation_input")
end

local function board_manager_runtime() -- line: 80
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/board_manager/runtime")
end

local function ragdoll() -- line: 83
    -- upvalues: import (copy)
    return import("skate_game/physics/wipeout_states/ragdoll")
end

local function grab_scene() -- line: 86
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/grab_scene")
end

local function grab_runtime() -- line: 89
    -- upvalues: import (copy)
    return import("skate_game/physics/biped_ground/grab_runtime")
end

local function offboard_contact_toolkit() -- line: 92
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/contact_toolkit")
end

local function revert_state() -- line: 95
    -- upvalues: import (copy)
    return import("skate_game/physics/revert_state")
end

local function handplant() -- line: 98
    -- upvalues: import (copy)
    return import("skate_game/physics/handplant")
end

local function footplant_ground() -- line: 101
    -- upvalues: import (copy)
    return import("skate_game/physics/footplant/ground")
end

local function boneless() -- line: 104
    -- upvalues: import (copy)
    return import("skate_game/physics/boneless")
end

local function grind_trick() -- line: 107
    -- upvalues: import (copy)
    return import("skate_game/physics/grind_trick")
end

local function air_phase() -- line: 110
    -- upvalues: import (copy)
    return import("skate_game/physics/air_phase")
end

local function known_air() -- line: 113
    -- upvalues: import (copy)
    return import("skate_game/physics/known_air")
end

local function ground_animation() -- line: 116
    -- upvalues: import (copy)
    return import("skate_game/physics/ground_animation")
end

local function landing_on_deck() -- line: 119
    -- upvalues: import (copy)
    return import("skate_game/physics/landing_on_deck")
end

local function slide_state() -- line: 122
    -- upvalues: import (copy)
    return import("skate_game/physics/slide_state")
end

local function wipeout_states() -- line: 125
    -- upvalues: import (copy)
    return import("skate_game/physics/wipeout_states")
end

local function teleport_state() -- line: 128
    -- upvalues: import (copy)
    return import("skate_game/physics/teleport_state")
end

local function grind() -- line: 131
    -- upvalues: import (copy)
    return import("skate_game/physics/grind")
end

local function solve() -- line: 134
    -- upvalues: import (copy)
    return import("skate_game/physics/solve")
end

local function player_input() -- line: 137
    -- upvalues: import (copy)
    return import("skate_game/physics/player_input")
end

local function output_reset() -- line: 140
    -- upvalues: import (copy)
    return import("skate_game/physics/player_input/output_reset")
end

local function grind_camera() -- line: 143
    -- upvalues: import (copy)
    return import("skate_game/physics/grind_camera")
end

local function camera_output() -- line: 146
    -- upvalues: import (copy)
    return import("skate_game/physics/camera_output")
end

local function scoring_runtime() -- line: 149
    -- upvalues: import (copy)
    return import("skate_game/scoring_runtime")
end

local function core_contact_toolkit() -- line: 152
    -- upvalues: import (copy)
    return import("skate_core/player/offboard/contact_toolkit")
end

local function offboard_controller() -- line: 155
    -- upvalues: import (copy)
    return import("skate_core/player/offboard/controller")
end

local function skeleton_body() -- line: 158
    -- upvalues: import (copy)
    return import("skate_core/physics/skeleton_body")
end

local t1 = {}

local function from_bits4(p2) -- line: 168
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p2[1])

    local v3 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p2[2])

    local v5 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p2[3])

    local v7 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p2[4])

    return {
        v3,
        v5,
        v7,
        (buffer.readf32(v1, 0))
    }
end

local from_bits = rt.from_bits

local function from_bits4_into(p3, p4) -- line: 177
    -- upvalues: from_bits (copy)
    local v9 = from_bits(p4[1])
    local v10 = from_bits(p4[2])
    local v11 = from_bits(p4[3])
    local v12 = from_bits(p4[4])

    p3[1] = v9
    p3[2] = v10
    p3[3] = v11
    p3[4] = v12

    return p3
end

local v13, SimulationActions
local t2 = {
    value = function(_, p6) -- value | line: 190
        -- upvalues: v13 (ref), SimulationActions (ref)
        return SimulationActions.value(v13, p6)
    end,
    state = function(_, p8) -- state | line: 193
        -- upvalues: v13 (ref), SimulationActions (ref)
        return SimulationActions.state(v13, p8)
    end
}

function t1.bind_simulation_actions_dyn(p9) -- line: 200
    -- upvalues: import (copy), v13 (ref), SimulationActions (ref), t2 (copy)
    v13 = p9
    SimulationActions = import("skate_game/physics/controls").SimulationActions

    return t2
end

function t1.simulation_actions_dyn_reference(p10) -- line: 206
    -- upvalues: import (copy)
    local SimulationActions = import("skate_game/physics/controls").SimulationActions

    return {
        value = function(_, p12) -- value | line: 209
            -- upvalues: p10 (copy), SimulationActions (copy)
            return SimulationActions.value(p10, p12)
        end,
        state = function(_, p14) -- state | line: 212
            -- upvalues: p10 (copy), SimulationActions (copy)
            return SimulationActions.state(p10, p14)
        end
    }
end

local t4 = {
    0, 0, 0, 0
}
local t5 = {
    0, 0, 0, 0
}
local self = setmetatable({}, {
    __mode = "k"
})

local function output_snapshot_of(p15) -- line: 234
    -- upvalues: Vector3 (copy), self (copy)
    if type(p15) ~= "table" then
        return nil
    end

    local v15 = self[p15]

    if v15 == nil then
        v15 = {
            tick = 0,
            state = 0,
            contact_count = 0,
            grounded = false,
            wiping_out = false,
            landed = false,
            board_position = Vector3.new(0, 0, 0),
            board_linear_velocity = Vector3.new(0, 0, 0),
            rider_root_position = Vector3.new(0, 0, 0),
            rider_linear_velocity = Vector3.new(0, 0, 0),
            ground_normal = Vector3.new(0, 0, 0),
            predicted_position = Vector3.new(0, 0, 0),
            events = {}
        }
        self[p15] = v15
    end

    return v15
end

local v16
local t8 = {
    position = { 0, 0, 0 },
    velocity = { 0, 0, 0 },
    forward = { 0, 0, 0 },
    player_basis = {
        { 0, 0, 0 },
        { 0, 0, 0 },
        { 0, 0, 0 }
    },
    board_basis = {
        { 0, 0, 0 },
        { 0, 0, 0 },
        { 0, 0, 0 }
    },
    reckoning_up = { 0, 0, 0 }
}

function t1.scoring_frame_reference(p16, p17, p18, p19, p20, p21, p22) -- line: 277
    -- upvalues: rt (copy), v1 (copy), import (copy), BodyId (copy), BoardRuntime (copy), FilteredCategory (copy)
    local PlayerState = import("skate_game/physics/player_state").PlayerState
    local simulation = p16.settings.step.simulation
    local score_packet = p17.animation.motion.score_packet
    local v17 = rt.copy(BoardRuntime.part_transforms(p16.board)[BodyId.index(BodyId.Deck) + 1])
    local velocity = p17.centre_of_mass_output.velocity
    local filtered_output = p17.player_state.filtered_output
    local first = score_packet.trick_names.first

    if first == nil and score_packet.grab ~= nil then
        first = score_packet.grab[1]
    end

    local animation_to_world = p17.animated_skeleton.roots.animation_to_world
    local v18 = table.create(3)

    for i = 1, 3 do
        v18[i] = {
            animation_to_world[i][1],
            animation_to_world[i][2],
            animation_to_world[i][3]
        }
    end

    local vector_96 = p17.player_input.physical.reckoning.vector_96
    local air = p17.player_input.physical.air
    local t9 = {
        tick = rt.to_u32(p18),
        dt = simulation.time_step
    }

    t9.category = if filtered_output == nil then FilteredCategory.default() else filtered_output.category
    t9.state = PlayerState.current(p17.player_state)
    t9.descriptor = rt.copy(first)
    t9.grind_id = if filtered_output == nil then -1 else filtered_output.grind.scorable_id
    t9.flags = score_packet.flags
    t9.position = { p20, p21, p22 }
    t9.velocity = {
        velocity[1],
        velocity[2],
        velocity[3]
    }
    t9.forward = rt.copy(v17.basis.columns[3])
    t9.switch = p17.animation.packet.riding_switch
    t9.fakie = p17.animation.packet.riding_fakie
    t9.regular = p17.animation.packet.regular_stance
    t9.player_basis = v18
    t9.board_basis = rt.copy(v17.basis.columns)
    buffer.writeu32(v1, 0, vector_96[1])

    local v20 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, vector_96[2])

    local v22 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, vector_96[3])
    t9.reckoning_up = {
        v20,
        v22,
        (buffer.readf32(v1, 0))
    }
    t9.body_flip = air.flag_441 ~= 0
    t9.front_flip = air.flag_445 ~= 0
    t9.suspend_air = air.use_air_reckoning_452 ~= 0
    t9.landing = rt.copy(p17.landing_quality)
    t9.teleported = p19
    t9.reverting = p17.player_input.physical.state.flag_66 ~= 0

    return t9
end

function t1.scoring_frame(p23, p24, p25, p26, p27, p28, p29) -- line: 332
    -- upvalues: rt (copy), import (copy), FilteredCategory (copy), from_bits (copy), v16 (ref), t8 (copy)
    local score_packet = p24.animation.motion.score_packet
    local v24 = import("skate_game/physics/solve").deck_frame_into(p23.board, v16)

    v16 = v24

    local velocity = p24.centre_of_mass_output.velocity
    local filtered_output = p24.player_state.filtered_output
    local first = score_packet.trick_names.first

    if first == nil and score_packet.grab ~= nil then
        first = score_packet.grab[1]
    end

    local animation_to_world = p24.animated_skeleton.roots.animation_to_world
    local vector_96 = p24.player_input.physical.reckoning.vector_96
    local air = p24.player_input.physical.air
    local packet = p24.animation.packet

    t8.tick = rt.to_u32(p25)
    t8.dt = p23.settings.step.simulation.time_step
    t8.category = if filtered_output == nil then FilteredCategory.default() else filtered_output.category
    t8.state = import("skate_game/physics/player_state").PlayerState.current(p24.player_state)
    t8.descriptor = first
    t8.grind_id = if filtered_output == nil then -1 else filtered_output.grind.scorable_id
    t8.flags = score_packet.flags

    local position = t8.position

    position[1] = p27
    position[2] = p28
    position[3] = p29

    local velocity2 = t8.velocity
    local v27 = velocity[1]
    local v28 = velocity[2]
    local v29 = velocity[3]

    velocity2[1] = v27
    velocity2[2] = v28
    velocity2[3] = v29

    local v30 = v24[1]
    local v31 = v24[2]
    local v32 = v24[3]
    local forward = t8.forward
    local v33 = v32[1]
    local v34 = v32[2]
    local v35 = v32[3]

    forward[1] = v33
    forward[2] = v34
    forward[3] = v35
    t8.switch = packet.riding_switch
    t8.fakie = packet.riding_fakie
    t8.regular = packet.regular_stance

    local player_basis = t8.player_basis
    local v36 = animation_to_world[1]
    local v37 = player_basis[1]
    local v38 = v36[1]
    local v39 = v36[2]
    local v40 = v36[3]

    v37[1] = v38
    v37[2] = v39
    v37[3] = v40

    local v41 = animation_to_world[2]
    local v42 = player_basis[2]
    local v43 = v41[1]
    local v44 = v41[2]
    local v45 = v41[3]

    v42[1] = v43
    v42[2] = v44
    v42[3] = v45

    local v46 = animation_to_world[3]
    local v47 = player_basis[3]
    local v48 = v46[1]
    local v49 = v46[2]
    local v50 = v46[3]

    v47[1] = v48
    v47[2] = v49
    v47[3] = v50

    local board_basis = t8.board_basis
    local v51 = board_basis[1]
    local v52 = v30[1]
    local v53 = v30[2]
    local v54 = v30[3]

    v51[1] = v52
    v51[2] = v53
    v51[3] = v54

    local v55 = board_basis[2]
    local v56 = v31[1]
    local v57 = v31[2]
    local v58 = v31[3]

    v55[1] = v56
    v55[2] = v57
    v55[3] = v58

    local v59 = board_basis[3]
    local v60 = v32[1]
    local v61 = v32[2]
    local v62 = v32[3]

    v59[1] = v60
    v59[2] = v61
    v59[3] = v62

    local reckoning_up = t8.reckoning_up
    local v63 = from_bits(vector_96[1])
    local v64 = from_bits(vector_96[2])
    local v65 = from_bits(vector_96[3])

    reckoning_up[1] = v63
    reckoning_up[2] = v64
    reckoning_up[3] = v65
    t8.body_flip = air.flag_441 ~= 0
    t8.front_flip = air.flag_445 ~= 0
    t8.suspend_air = air.use_air_reckoning_452 ~= 0
    t8.landing = p24.landing_quality
    t8.teleported = p26
    t8.reverting = p24.player_input.physical.state.flag_66 ~= 0

    return t8
end

function t1.output_snapshot_reference(p30, p31, p32) -- line: 398
    -- upvalues: rt (copy), v1 (copy), import (copy), Vector3 (copy), BodyId (copy), BoardRuntime (copy), PhysicalStateId (copy)
    local SimulationExchange = import("skate_game/physics").SimulationExchange
    local PlayerState = import("skate_game/physics/player_state").PlayerState
    local v66 = rt.copy(BoardRuntime.bodies(p30.board)[BodyId.index(BodyId.Deck) + 1])
    local v67 = import("skate_core/physics/skeleton_body").SkeletonBody.bodies(p31.skeleton)[1]

    if v67 == nil then
        error("Physical output requires the constructed rider body", 0)
    end

    local v68 = rt.copy(p30.riding.ground.wheel_normal)
    local predicted_position_64 = p31.player_input.physical.collision.predicted_position_64
    local new = Vector3.new

    buffer.writeu32(v1, 0, predicted_position_64[1])

    local v70 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, predicted_position_64[2])

    local v72 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, predicted_position_64[3])

    local v74 = new(v70, v72, (buffer.readf32(v1, 0)))
    local v75 = rt.copy(SimulationExchange.events(p30.exchange))
    local v76 = false

    for _, v77 in v75 do
        if v77.tag == "Landing" then
            v76 = true
            break
        end
    end

    return {
        tick = p32,
        state = PlayerState.current(p31.player_state),
        board_position = rt.copy(v66.rates.position),
        board_linear_velocity = rt.copy(v66.rates.linear_velocity),
        rider_root_position = rt.copy(v67.rates.position),
        rider_linear_velocity = rt.copy(v67.rates.linear_velocity),
        ground_normal = v68,
        contact_count = p30.riding.ground.part_contact_count,
        predicted_position = v74,
        grounded = PlayerState.current(p31.player_state) == PhysicalStateId.PhysicsGround,
        wiping_out = p31.skeleton_collision.is_ragdoll,
        landed = v76,
        events = v75
    }
end

function t1.advance(p33, p34, p35, p36, p37, p38, p39) -- line: 437
    -- upvalues: rt (copy), import (copy), Vector3 (copy), BodyId (copy), BoardRuntime (copy), PhysicalStateId (copy), CentreOfMassFilter (copy), SkeletonOutputFields (copy), t1 (copy), from_bits (copy), v13 (ref), SimulationActions (ref), t2 (copy), t4 (copy), t5 (copy), output_snapshot_of (copy)
    local SimulationExchange = import("skate_game/physics").SimulationExchange
    local SimulationClock = import("skate_game/physics/clock").SimulationClock
    local PlayerState = import("skate_game/physics/player_state").PlayerState
    local RidingOutputs = import("skate_game/physics/riding_outputs").RidingOutputs
    local ticks = p33.ticks

    if not SimulationExchange.reset(p33.exchange, ticks) then
        p33.exchange = SimulationExchange.new(ticks)
    end

    local simulation_rate_requests = p39.simulation_rate_requests

    if next(simulation_rate_requests) ~= nil then
        p39.simulation_rate_requests = {}
    end

    for _, v78 in simulation_rate_requests do
        if not p33.network_active then
            SimulationClock.apply(p33.clock, v78)
        end
    end

    if p33.network_active then
        p33.clock = SimulationClock.default()
    end

    if p33.ticks == 0 then
        import("skate_game/physics/player_state").initialize(p33, p34)
    end

    if import("skate_game/physics/climbing").advance(p33, p34, p35, p39) then
        return
    end

    import("skate_game/physics/biped_air").consume_selector(p33, p34)
    BoardRuntime.clear_forces(p33.board)
    RidingOutputs.start_wheel_queries(p33.riding, p33.board, p33.world)

    local v79 = import("skate_game/physics/foot_ik_queries").query(p33.world, p34.skeleton)
    local advance = import("skate_game/physics/animation_phase").advance
    local animation_profile = p33.animation_profile
    local ok, result = pcall(advance, p33, p34, p35, p36, animation_profile)

    if not ok then
        error(("Animation tick%*: %*"):format(p33.ticks, result), 0)
    end

    local riding = p34.animation.motion.riding
    local force_mode = riding.force_mode

    riding.force_mode = nil

    if force_mode ~= nil then
        p34.skeleton_input.force_mode = import("skate_game/graph_host/motion_riding").ForceMode.native_value(force_mode)
    end

    local v80 = import("skate_game/physics/controls").PlayerControls.simulation_actions(p35, p37)
    local v81 = v13

    v13 = v80
    SimulationActions = import("skate_game/physics/controls").SimulationActions

    local v82 = import("skate_game/physics/input_phase").advance(p33, p34, import("skate_game/physics/animation_phase_packet").AnimationPhaseOutput.packet_view(result), t2, p38)

    v13 = v81
    p34.ground_settings = import("skate_game/physics/ground_runtime").GroundProfiles.select(p34.ground_profiles, p34.player_input.processed.state_variant_index_2528, p34.player_input.processed.surface_mode_2540)

    if v82 then
        import("skate_game/physics/respawn").Runtime.reset_measurements(p34.respawn)
        import("skate_core/player/offboard/contact_toolkit").Owner.reset_history(p34.offboard_contact)
        import("skate_core/player/offboard/controller").Controller.reset(p34.biped_ground.controller)
        PlayerState.reset_for_teleport(p34.player_state)
        CentreOfMassFilter.reset(p34.centre_of_mass_filter)
        import("skate_game/physics/animation_feedback").AnimationFeedback.reset(p34.animation_feedback)
        import("skate_game/physics/player_state").enter_after_teleport(p33, p34)
        import("skate_game/physics/offboard/board_manager/runtime").finish_teleport(p33, p34)
        import("skate_game/physics/wipeout_states/ragdoll").RagdollSetup.restore_normal(p34.wipeout_state.ragdoll, p34.skeleton, p34.skeleton_joints, p34.skeleton_collision, p34.collision_feedback)
    end

    RidingOutputs.finish_wheel_queries(p33.riding)

    local v83 = import("skate_game/physics/offboard/grab_scene").Scene.new(p33.world, p33.offboard_grab_scene)

    import("skate_game/physics/biped_ground/grab_runtime").Owner.execute_queries(p34.offboard_grab, v83)

    local v84 = PlayerState.current(p34.player_state)

    import("skate_game/physics/player_state").post_input_and_select(p33, p34)

    local v85 = PlayerState.current(p34.player_state)

    if v84 ~= v85 then
        SimulationExchange.emit_event(p33.exchange, ticks, {
            tag = "StateChanged",
            from = v84,
            to = v85
        })
    end

    import("skate_game/physics/player_state").pre_state(p33, p34)

    local v86 = PlayerState.current(p34.player_state)

    if v86 == PhysicalStateId.RevertGround then
        import("skate_game/physics/revert_state").update(p33, p34)
    elseif v86 == PhysicalStateId.HandPlant then
        import("skate_game/physics/handplant").update(p33, p34)
    elseif v86 == PhysicalStateId.FootPlant then
        import("skate_game/physics/footplant/ground").update(p33, p34)
    elseif v86 == PhysicalStateId.Boneless then
        import("skate_game/physics/boneless").update(p33, p34)
    elseif v86 == PhysicalStateId.PhysicsGround then
        local processed = p34.player_input.processed
        local animation_com_to_deck_752 = processed.animation_com_to_deck_752
        local v87 = from_bits(animation_com_to_deck_752[1])
        local v88 = from_bits(animation_com_to_deck_752[2])
        local v89 = from_bits(animation_com_to_deck_752[3])

        RidingOutputs.update_ground_reckoning(p33.riding, p33.board, {
            com_to_deck = Vector3.new(v87, v88, v89),
            body_spin = p34.animation_input.extra.physical_body_spin
        }, processed.flags_2468, p34.animation_input.fields.balance, bit32.band(processed.flags_2476, 1073741824) ~= 0, processed)
        p34.ground.state.push_suppressed_2730 = false
        import("skate_game/physics/ground_phase").advance(p33, p34)
        import("skate_game/physics/handplant").ground_update(p33, p34)
        import("skate_game/physics/input_phase").update_ground(p33, p34)
    elseif v86 == PhysicalStateId.PhysicsAirSecondary then
        import("skate_game/physics/grind_trick").advance(p33, p34)
    elseif v86 == PhysicalStateId.PhysicsAir then
        import("skate_game/physics/air_phase").advance(p33, p34)
    elseif v86 == PhysicalStateId.KnownAir then
        import("skate_game/physics/known_air").update(p33, p34)
    elseif v86 == PhysicalStateId.BipedAir then
        import("skate_game/physics/biped_air").update(p33, p34, p35)
    elseif v86 == PhysicalStateId.BipedGround or v86 == PhysicalStateId.OffBoardPushing then
        local Owner = import("skate_core/player/offboard/contact_toolkit").Owner
        local t11 = {
            readiness = rt.to_i32(Owner.readiness(p34.offboard_contact)),
            prefix = Owner.prefix(p34.offboard_contact)
        }
        local v90 = import("skate_game/physics/biped_ground").update(p33, p34, p35, t11)
        local StaticScene = import("skate_game/physics/offboard/contact_toolkit").StaticScene
        local v91 = rt.to_i32(p34.player_input.processed.actor_query_2952)
        local v92 = StaticScene.new(p33.world)

        Owner.submit(p34.offboard_contact, v90, v91, {
            execute = function(_, p41) -- execute | line: 652
                -- upvalues: StaticScene (copy), v92 (copy)
                return StaticScene.execute(v92, p41)
            end
        })
        import("skate_game/physics/biped_ground").submit_geometry(p33, p34)
    elseif v86 == PhysicalStateId.GroundAnimation then
        import("skate_game/physics/ground_animation").advance(p33, p34)
    elseif v86 == PhysicalStateId.LandingOnDeck then
        import("skate_game/physics/landing_on_deck").advance(p33, p34)
    elseif v86 == PhysicalStateId.SlideGround then
        import("skate_game/physics/slide_state").update(p33, p34)
    elseif v86 == PhysicalStateId.WipeoutGround then
        import("skate_game/physics/wipeout_states").advance(p33, p34)
    elseif v86 == PhysicalStateId.Teleporting then
        if import("skate_game/physics/teleport_state").Runtime.update(p34.teleport_state, p34.player_input.processed) then
            import("skate_game/physics/respawn").request(p33, p34)
        end
    elseif PhysicalStateId.is_grind(v86) or v86 == PhysicalStateId.Nonspecific then
        import("skate_game/physics/grind").advance(p33, p34)
    else
        error(("Selected %* requires its physical update"):format(v86), 0)
    end

    p34.player_input.player.state_timer_1344 += p34.player_input.processed.timestep_2604
    import("skate_game/physics/offboard/board_manager/runtime").update(p33, p34)
    p33.processed_flags_2468 = p34.player_input.processed.flags_2468
    import("skate_game/physics/foot_ik_queries").SkeletonLineTests.publish(v79, p34.player_input.player)
    import("skate_game/physics/solve").advance(p33, p34, rt.copy(p34.ground.steering.targets))
    import("skate_game/physics/player_input/output_reset").reset_outputs_in_place(p34.player_input.physical)
    import("skate_game/physics").GamePhysics.finish_skater(p33, p34)

    local PlayerInputRuntime = import("skate_game/physics/player_input").PlayerInputRuntime
    local simulation = p33.settings.step.simulation

    PlayerInputRuntime.update_dynamic_normal(p34.player_input, p33.riding, simulation.gravity_acceleration)
    PlayerInputRuntime.publish_board(p34.player_input, p33.riding)
    SkeletonOutputFields.publish_deck_angles(p34.player_input.physical.skeleton, rt.copy(p34.animated_skeleton.record.pose[1][3]), p34.animation.packet.board_flipped)

    local up = p33.riding.reckoning.up

    PlayerInputRuntime.publish_grind_graph_outputs(p34.player_input, p34.skeleton.record, {
        up.x,
        up.y,
        up.z,
        0
    }, p34.trajectory.selector)
    import("skate_game/physics/player_state").publish(p33, p34)
    import("skate_game/physics/grind_camera").GrindCamera.condition_fields(p34.grind_camera, p34.player_input.physical.grinds)

    local physical = p34.player_input.physical
    local vector_64 = physical.reckoning.vector_64
    local v93 = from_bits(vector_64[1])
    local v94 = from_bits(vector_64[2])
    local v95 = from_bits(vector_64[3])
    local v96 = from_bits(vector_64[4])

    t4[1] = v93
    t4[2] = v94
    t4[3] = v95
    t4[4] = v96

    local vector_16 = physical.reckoning.vector_16
    local v97 = from_bits(vector_16[1])
    local v98 = from_bits(vector_16[2])
    local v99 = from_bits(vector_16[3])
    local v100 = from_bits(vector_16[4])

    t5[1] = v97
    t5[2] = v98
    t5[3] = v99
    t5[4] = v100
    p34.centre_of_mass_output = CentreOfMassFilter.update(p34.centre_of_mass_filter, t4, t5)

    local v101 = import("skate_game/physics/animation_phase").publish_feedback(p33, p34)

    import("skate_game/physics/respawn").observe(p33, p34)

    local v102 = output_snapshot_of(p33.exchange)
    local x, y, z

    if v102 ~= nil then
        local rates = BoardRuntime.bodies(p33.board)[BodyId.index(BodyId.Deck) + 1].rates
        local position = rates.position
        local board_position = v102.board_position
        local x2, y2, z2 = position.x, position.y, position.z

        board_position.x = x2
        board_position.y = y2
        board_position.z = z2
        x = board_position.x
        y = board_position.y
        z = board_position.z

        local linear_velocity = rates.linear_velocity
        local board_linear_velocity = v102.board_linear_velocity
        local x3, y3, z3 = linear_velocity.x, linear_velocity.y, linear_velocity.z

        board_linear_velocity.x = x3
        board_linear_velocity.y = y3
        board_linear_velocity.z = z3

        local v104 = import("skate_core/physics/skeleton_body").SkeletonBody.bodies(p34.skeleton)[1]

        if v104 == nil then
            error("Physical output requires the constructed rider body", 0)
        end

        local wheel_normal = p33.riding.ground.wheel_normal
        local ground_normal = v102.ground_normal
        local x4, y4, z4 = wheel_normal.x, wheel_normal.y, wheel_normal.z

        ground_normal.x = x4
        ground_normal.y = y4
        ground_normal.z = z4

        local predicted_position_64 = p34.player_input.physical.collision.predicted_position_64
        local predicted_position = v102.predicted_position
        local v105 = from_bits(predicted_position_64[1])
        local v106 = from_bits(predicted_position_64[2])
        local v107 = from_bits(predicted_position_64[3])

        predicted_position.x = v105
        predicted_position.y = v106
        predicted_position.z = v107

        local events = v102.events

        table.clear(events)

        for v108, v109 in SimulationExchange.events(p33.exchange) do
            events[v108] = rt.copy(v109)
        end

        local v110 = false

        for _, v111 in events do
            if v111.tag == "Landing" then
                v110 = true
                break
            end
        end

        v102.tick = ticks
        v102.state = PlayerState.current(p34.player_state)

        local position2 = v104.rates.position
        local rider_root_position = v102.rider_root_position
        local x5, y5, z5 = position2.x, position2.y, position2.z

        rider_root_position.x = x5
        rider_root_position.y = y5
        rider_root_position.z = z5

        local linear_velocity2 = v104.rates.linear_velocity
        local rider_linear_velocity = v102.rider_linear_velocity
        local x6, y6, z6 = linear_velocity2.x, linear_velocity2.y, linear_velocity2.z

        rider_linear_velocity.x = x6
        rider_linear_velocity.y = y6
        rider_linear_velocity.z = z6
        v102.contact_count = p33.riding.ground.part_contact_count
        v102.grounded = PlayerState.current(p34.player_state) == PhysicalStateId.PhysicsGround
        v102.wiping_out = p34.skeleton_collision.is_ragdoll
        v102.landed = v110
        SimulationExchange.publish_output(p33.exchange, v102)
    else
        local v103 = t1.output_snapshot_reference(p33, p34, ticks)

        x = v103.board_position.x
        y = v103.board_position.y
        z = v103.board_position.z
        SimulationExchange.publish_output(p33.exchange, v103)
    end

    import("skate_game/physics/camera_output").advance(p33, p34, v101, p39)
    import("skate_game/scoring_runtime").Runtime.advance(p34.scoring, t1.scoring_frame(p33, p34, ticks, v82, x, y, z))
    import("skate_game/physics/climbing/approach").advance(p33, p34, p35)
    import("skate_game/physics/animation_input").AnimationInput.finish_output_publication(p34.animation_input)
    p34.player_input.player.update_count_1316 = rt.wrapping_add_u32(p34.player_input.player.update_count_1316, 1)
    SimulationClock.finish_tick(p33.clock)
end

return t1
