-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

local function rtl_is_finite(p1) -- line: 6
    if p1 ~= p1 or p1 == 1e999 then
        return false
    end

    return p1 ~= (-1e999)
end

local import = require(sim.import)
local Vector3 = import("skate_core/math").Vector3
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime
local BoardWorld = import("skate_core/physics/board_world").BoardWorld
local RetailAffineTransform = import("skate_core/physics/drive_frames").RetailAffineTransform
local v1 = import("skate_core/physics/phase")
local PhysicalStateId = import("skate_core/player/state").PhysicalStateId
local TickInput = import("skate_core/input/tick").TickInput
local GameplayActions = import("skate_core/input/gameplay_map").GameplayActions
local v2 = import("skate_game/physics/ground")
local v3 = import("skate_game/physics/frame")
local v4 = import("skate_game/physics/input_phase")

local function network() -- line: 98
    -- upvalues: import (copy)
    return import("skate_game/physics/network")
end

local function clock() -- line: 101
    -- upvalues: import (copy)
    return import("skate_game/physics/clock")
end

local function riding_outputs() -- line: 104
    -- upvalues: import (copy)
    return import("skate_game/physics/riding_outputs")
end

local function settings_mod() -- line: 107
    -- upvalues: import (copy)
    return import("skate_game/physics/settings")
end

local function animation_phase() -- line: 110
    -- upvalues: import (copy)
    return import("skate_game/physics/animation_phase")
end

local function grind_materials() -- line: 113
    -- upvalues: import (copy)
    return import("skate_game/physics/grind_materials")
end

local function grab_scene() -- line: 116
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/grab_scene")
end

local function offboard_post_physics() -- line: 119
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/post_physics")
end

local function probes() -- line: 122
    -- upvalues: import (copy)
    return import("skate_game/physics/riding_outputs/probes")
end

local function skateboard_controller() -- line: 125
    -- upvalues: import (copy)
    return import("skate_game/physics/skateboard_controller")
end

local function skeleton_feedback() -- line: 128
    -- upvalues: import (copy)
    return import("skate_game/physics/skeleton_feedback")
end

local function skeleton_output() -- line: 131
    -- upvalues: import (copy)
    return import("skate_game/physics/skeleton_output")
end

local function wipeout_states() -- line: 134
    -- upvalues: import (copy)
    return import("skate_game/physics/wipeout_states")
end

local function air_phase() -- line: 137
    -- upvalues: import (copy)
    return import("skate_game/physics/air_phase")
end

local function known_air() -- line: 140
    -- upvalues: import (copy)
    return import("skate_game/physics/known_air")
end

local function grind() -- line: 143
    -- upvalues: import (copy)
    return import("skate_game/physics/grind")
end

local function wipeout() -- line: 146
    -- upvalues: import (copy)
    return import("skate_game/physics/wipeout")
end

local function grind_trick() -- line: 149
    -- upvalues: import (copy)
    return import("skate_game/physics/grind_trick")
end

local function render_pose() -- line: 152
    -- upvalues: import (copy)
    return import("skate_game/physics/render_pose")
end

local function player_state() -- line: 155
    -- upvalues: import (copy)
    return import("skate_game/physics/player_state")
end

local function skeleton_body() -- line: 158
    -- upvalues: import (copy)
    return import("skate_core/physics/skeleton_body")
end

local function custom_difficulty() -- line: 161
    -- upvalues: import (copy)
    return import("skate_game/custom_difficulty")
end

local function difficulty_mod() -- line: 164
    -- upvalues: import (copy)
    return import("skate_game/difficulty")
end

local function skate_world() -- line: 167
    -- upvalues: import (copy)
    return import("skate_game/skate_world")
end

local function grind_world() -- line: 170
    -- upvalues: import (copy)
    return import("skate_game/grind_world")
end

local function modding() -- line: 173
    -- upvalues: import (copy)
    return import("skate_game/modding")
end

local function presentation() -- line: 176
    -- upvalues: import (copy)
    return import("skate_game/presentation")
end

local v5
local t2 = {
    value = function(_, p3) -- value | line: 191
        -- upvalues: GameplayActions (copy), v5 (ref)
        return GameplayActions.value(v5, p3)
    end,
    state = function(_, p5) -- state | line: 194
        -- upvalues: GameplayActions (copy), v5 (ref)
        return GameplayActions.state(v5, p5)
    end
}
local t1 = {}

function t1.bind_actions_dyn(p6) -- line: 201
    -- upvalues: v5 (ref), t2 (copy)
    v5 = p6

    return t2
end

function t1.actions_dyn_reference(p7) -- line: 206
    -- upvalues: GameplayActions (copy)
    return {
        value = function(_, p9) -- value | line: 208
            -- upvalues: p7 (copy), GameplayActions (copy)
            return GameplayActions.value(p7, p9)
        end,
        state = function(_, p11) -- state | line: 211
            -- upvalues: p7 (copy), GameplayActions (copy)
            return GameplayActions.state(p7, p11)
        end
    }
end

t1.PHYSICS_MODE = "easy"
t1.SkaterRuntime = import("skate_game/physics/skater").SkaterRuntime
t1.PlayerControls = import("skate_game/physics/controls").PlayerControls
t1.facing_from_visual = v4.facing_from_visual
t1.GamePhysics = {}
t1.SimulationExchange = {}

function t1.SimulationExchange.new(p12) -- line: 263
    -- upvalues: v1 (copy)
    return {
        physical_output = nil,
        commands = v1.PhysicsCommandBuffer.new(p12),
        events = v1.PhysicsEventBuffer.new(p12)
    }
end

function t1.SimulationExchange.reset(p13, p14) -- line: 286
    if type(p13) ~= "table" then
        return false
    end

    local commands, events = p13.commands, p13.events

    if type(commands) ~= "table" or type(events) ~= "table" then
        return false
    end

    local commands2 = commands.commands
    local events2 = events.events

    if type(commands2) ~= "table" or type(events2) ~= "table" or commands2 == events2 then
        return false
    end

    commands.tick = p14
    table.clear(commands2)
    events.tick = p14
    table.clear(events2)
    p13.physical_output = nil

    return true
end

function t1.SimulationExchange.emit_event(p15, p16, p17) -- line: 307
    -- upvalues: v1 (copy)
    return v1.PhysicsEventBuffer.emit(p15.events, p16, p17)
end

function t1.SimulationExchange.publish_output(p18, p19) -- line: 311
    p18.physical_output = p19
end

function t1.SimulationExchange.output(p20) -- line: 316
    return p20.physical_output
end

function t1.SimulationExchange.events(p21) -- line: 320
    -- upvalues: v1 (copy)
    return v1.PhysicsEventBuffer.events(p21.events)
end

function t1.SimulationExchange.request_state(p22, p23) -- line: 325
    -- upvalues: v1 (copy)
    local v6 = v1.PhysicsCommandBuffer.tick(p22.commands)

    return v1.PhysicsCommandBuffer.push(p22.commands, v6, {
        tag = "RequestState",
        p23
    })
end

function t1.GamePhysics.set_gesture_preferences(p24, p25) -- line: 331
    -- upvalues: rt (copy)
    local v7

    if p25 ~= nil then
        local v8 = true

        for _, v9 in p25 do
            if not (v9 < 37) then
                v8 = false
                break
            end
        end

        v7 = if v8 then rt.copy(p25) else nil
    end

    p24.animation_profile.gesture_selections = if v7 == nil then { 0, 1, 2, 3 } else v7
end

function t1.GamePhysics.set_equipment_preferences(p26, p27, p28) -- line: 348
    -- upvalues: rt (copy)
    if p27 == p27 and p27 ~= 1e999 and p27 ~= (-1e999) and p28 == p28 and p28 ~= 1e999 and p28 ~= (-1e999) then
        p26.animation_profile.truck_tightness = rt.clamp(p27, 0, 1)
        p26.animation_profile.wheel_hardness = rt.clamp(p28, 0, 1)
    end
end

function t1.GamePhysics.set_difficulty(p29, p30) -- line: 356
    p29.animation_profile.physics_mode = p30
end

function t1.GamePhysics.period(p31) -- line: 363
    -- upvalues: import (copy)
    return import("skate_game/physics/clock").SimulationClock.period(p31.clock)
end

function t1.GamePhysics.difficulty_index(p32) -- line: 367
    return p32.animation_profile.physics_mode
end

function t1.GamePhysics.world_triangles(p33) -- line: 371
    -- upvalues: BoardWorld (copy)
    return BoardWorld.triangles(p33.world)
end

function t1.GamePhysics.set_external_queries(p34, p35) -- line: 376
    -- upvalues: BoardWorld (copy)
    BoardWorld.set_external_queries(p34.world, p35)
end

function t1.GamePhysics.world(p36) -- line: 380
    return p36.world
end

function t1.GamePhysics.load(p37) -- line: 387
    -- upvalues: t1 (copy)
    return t1.GamePhysics.load_with_terrain(p37, "Flat")
end

function t1.GamePhysics.load_with_terrain(p38, p39) -- line: 393
    -- upvalues: t1 (copy)
    return t1.GamePhysics.load_with_world(p38, p39, nil)
end

function t1.GamePhysics.load_with_world(p40, p41, p42) -- line: 400
    -- upvalues: import (copy), t1 (copy)
    return t1.GamePhysics.load_world_difficulty(p40, p41, p42, import("skate_game/difficulty").Difficulty.Easy)
end

function t1.GamePhysics.load_with_difficulty(p43, p44, p45) -- line: 405
    -- upvalues: t1 (copy)
    return t1.GamePhysics.load_world_difficulty(p43, "Course", p44, p45)
end

local function glam_mat3_from_rotation_y_cols(p46) -- line: 410
    local v10 = math.sin(p46)
    local v11 = math.cos(p46)

    return {
        { v11, 0, -v10 },
        { 0, 1, 0 },
        { v10, 0, v11 }
    }
end

function t1.GamePhysics.load_world_difficulty(p47, p48, p49, p50) -- line: 420
    -- upvalues: rt (copy), import (copy), Vector3 (copy), BoardRuntime (copy), RetailAffineTransform (copy), v2 (copy), t1 (copy), glam_mat3_from_rotation_y_cols (copy)
    local Difficulty = import("skate_game/difficulty").Difficulty
    local StaticProvider = import("skate_game/grind_world").StaticProvider
    local v12 = import("skate_game/custom_difficulty").load_collections(p47, import("skate_data/files").read("../settings/custom-difficulty.json"))
    local v13 = import("skate_game/physics/settings").PhysicsSettings.load(v12)
    local v14 = import("skate_game/physics/animation_phase").AnimationProfile.load(v12, Difficulty.profile_key(p50))
    local v15 = rt.copy(RetailAffineTransform.IDENTITY)

    v15.translation = Vector3.new(0, v2.HEIGHT + v13.wheel_radius - v13.authored[1].translation.y, 0)

    if p49 ~= nil then
        v15.translation = Vector3.new(p49.spawn[1], p49.spawn[2] + v13.wheel_radius - v13.authored[1].translation.y, p49.spawn[3])
        v15.basis = {
            columns = glam_mat3_from_rotation_y_cols(p49.heading)
        }
    end

    local Active = BoardRuntime.new(rt.copy(v13.masses), rt.copy(v13.authored), v15, rt.copy(v13.step.simulation), "Active")
    local v16 = if p49 == nil then v2.Terrain.world(p48, rt.copy(v13.floor_material)) else import("skate_game/skate_world").collision_world(p49, rt.copy(v13.floor_material))
    local v17 = if p49 ~= nil or p48 ~= "Course" then StaticProvider.new(p49) else StaticProvider.authored(import("skate_game/grind_world").test_rails())
    local v18 = import("skate_game/physics/grind_materials").GrindMaterials.new(v13)
    local v19 = import("skate_game/physics/offboard/grab_scene").Registry.new(v16, {}, {})
    local v20 = import("skate_game/physics/riding_outputs").RidingOutputs.load(v12, Active, 8192)
    local v21, v22 = v2.query_settings()

    return {
        network_active = false,
        network_contacts = 0,
        ticks = 0,
        contact_count = 0,
        failed = false,
        processed_flags_2468 = 8192,
        board_wiping_out = false,
        network_proxies = import("skate_game/physics/network").Proxies.default(),
        clock = import("skate_game/physics/clock").SimulationClock.default(),
        board = Active,
        riding = v20,
        world = v16,
        grind_world = v17,
        grind_materials = v18,
        offboard_grab_scene = v19,
        settings = v13,
        animation_profile = v14,
        query = v21,
        retention = v22,
        exchange = t1.SimulationExchange.new(0)
    }
end

function t1.GamePhysics.advance_board(p51) -- line: 504
    -- upvalues: rt (copy), import (copy), BoardRuntime (copy), BoardWorld (copy)
    local RidingOutputs = import("skate_game/physics/riding_outputs").RidingOutputs

    BoardRuntime.clear_forces(p51.board)
    RidingOutputs.start_wheel_queries(p51.riding, p51.board, p51.world)
    RidingOutputs.finish_wheel_queries(p51.riding)

    local v23 = import("skate_game/physics/colliders").world_volumes(p51.board, p51.settings)
    local v24 = BoardWorld.query_primitives(p51.world, v23, p51.query, p51.retention)

    p51.contact_count = #v24
    BoardRuntime.advance(p51.board, v24, { 0, 0 }, rt.copy(p51.settings.step))
    RidingOutputs.finish_post_physics(p51.riding, p51.board, p51.board_wiping_out, p51.processed_flags_2468, p51.settings.step.simulation.time_step)
    p51.ticks += 1

    for _, v25 in BoardRuntime.bodies(p51.board) do
        local position = v25.rates.position
        local x = position.x

        if x == x and x ~= 1e999 and x ~= (-1e999) then
            local y = position.y

            if y == y and y ~= 1e999 and y ~= (-1e999) then
                local z = position.z

                if z ~= z or z == 1e999 or z == (-1e999) then
                    p51.failed = true
                    error(("Board solver produced a non-finite pose on tick %*"):format(p51.ticks), 0)
                end
            else
                p51.failed = true
                error(("Board solver produced a non-finite pose on tick %*"):format(p51.ticks), 0)
            end
        else
            p51.failed = true
            error(("Board solver produced a non-finite pose on tick %*"):format(p51.ticks), 0)
        end
    end
end

t1.PhysicsPlugin = {}

function t1.PhysicsPlugin.build(p52, p53) -- line: 542
    -- upvalues: import (copy), t1 (copy)
    local v26 = import("skate_game/physics/clock").SimulationClock.period(p52.clock)
    local load = t1.PlayerControls.load
    local ok, result = pcall(load, p53)

    if not ok then
        error(("Cannot initialize trick gesture recognizers: %*"):format(result), 0)
    end

    return v26, result
end

function t1.advance(p54, p55, p56, p57, p58, p59, p60) -- line: 561
    -- upvalues: import (copy), TickInput (copy), v3 (copy), v5 (ref), t2 (copy)
    if p54.failed or p60 ~= nil and (import("skate_game/modding").player_attached(p60) or import("skate_game/modding").player_suspended(p60)) then
        return nil
    end

    local actions = p58[1].actions
    local v27 = TickInput.controller_available(p58[1])
    local v28 = v5

    v5 = actions

    local advance = v3.advance
    local ok, result = pcall(advance, p54, p55, p56, p57, t2, v27, p59)

    v5 = v28

    if ok then
        return nil
    end

    p54.failed = true

    return (tostring(result))
end

local function non_finite_reference(p61) -- line: 604
    local position, linear_velocity, angular_velocity = p61.rates.position, p61.rates.linear_velocity, p61.rates.angular_velocity

    for _, v29 in {
            position.x,
            position.y,
            position.z,
            linear_velocity.x,
            linear_velocity.y,
            linear_velocity.z,
            angular_velocity.x,
            angular_velocity.y,
            angular_velocity.z
        } do
        if v29 ~= v29 or v29 == 1e999 or v29 == (-1e999) then
            return true
        end
    end

    return false
end

local function non_finite(p62) -- line: 619
    local rates = p62.rates
    local position, linear_velocity, angular_velocity = rates.position, rates.linear_velocity, rates.angular_velocity
    local x, y, z = position.x, position.y, position.z
    local x2, y2, z2 = linear_velocity.x, linear_velocity.y, linear_velocity.z
    local x3, y3, z3 = angular_velocity.x, angular_velocity.y, angular_velocity.z
    local v30 = x == x and x ~= 1e999 and x ~= (-1e999) and y == y and y ~= 1e999 and y ~= (-1e999) and z == z and z ~= 1e999 and z ~= (-1e999) and x2 == x2 and x2 ~= 1e999 and x2 ~= (-1e999) and y2 == y2 and y2 ~= 1e999 and y2 ~= (-1e999) and z2 == z2 and z2 ~= 1e999 and z2 ~= (-1e999) and x3 == x3 and x3 ~= 1e999 and x3 ~= (-1e999) and y3 == y3 and y3 ~= 1e999 and y3 ~= (-1e999) and z3 == z3 and z3 ~= 1e999 and z3 ~= (-1e999)

    return not v30
end

t1.finish_skater_non_finite = non_finite
t1.finish_skater_non_finite_reference = non_finite_reference

function t1.GamePhysics.finish_skater(p63, p64) -- line: 650
    -- upvalues: import (copy), BoardRuntime (copy), PhysicalStateId (copy), non_finite (copy)
    local toolkit = p64.player_input.toolkit

    if toolkit == nil then
        error("Postphysics wall probe requires the current board toolkit", 0)
    end

    import("skate_game/physics/riding_outputs/probes").BoardProbes.prepare_wall(p63.riding.probes, p64.player_input.processed, toolkit)
    import("skate_game/physics/riding_outputs").RidingOutputs.finish_post_physics(p63.riding, p63.board, p63.board_wiping_out, p63.processed_flags_2468, p63.settings.step.simulation.time_step)

    local v31 = import("skate_game/physics/skateboard_controller").partial_request(p64.skateboard_controller, p63.riding.ground)

    import("skate_game/physics/skeleton_feedback").publish(p63, p64, v31)

    local PlayerState = import("skate_game/physics/player_state").PlayerState

    if PlayerState.current(p64.player_state) == PhysicalStateId.WipeoutGround then
        import("skate_game/physics/wipeout_states").post_physics(p64)
    end

    if PlayerState.current(p64.player_state) == PhysicalStateId.PhysicsAir then
        import("skate_game/physics/air_phase").update_apex(p63, p64.air_state)
    end

    if PlayerState.current(p64.player_state) == PhysicalStateId.KnownAir then
        import("skate_game/physics/known_air").post_physics(p63, p64)
    end

    if PhysicalStateId.is_grind(PlayerState.current(p64.player_state)) or PlayerState.current(p64.player_state) == PhysicalStateId.Nonspecific then
        import("skate_game/physics/grind").post(p63, p64)
    end

    import("skate_game/physics/wipeout").check_after_physics(p63, p64)

    if PlayerState.current(p64.player_state) == PhysicalStateId.PhysicsAirSecondary then
        import("skate_game/physics/grind_trick").post_velocity(p63, p64)
    end

    import("skate_game/physics/offboard/post_physics").advance(p63, p64)

    local v32 = import("skate_game/physics/skeleton_output").SkeletonOutput.average_compressions(p64.skeleton_output, p63.board)

    import("skate_game/physics/render_pose").publish(p63, p64, v32)
    p63.ticks += 1

    local v33

    for v34, v35 in BoardRuntime.bodies(p63.board) do
        if non_finite(v35) then
            v33 = v34 - 1
            break
        end
    end

    local v36

    for v37, v38 in import("skate_core/physics/skeleton_body").SkeletonBody.bodies(p64.skeleton) do
        if non_finite(v38) then
            v36 = v37 - 1
            break
        end
    end

    if v33 == nil and v36 == nil then
        return
    end

    p63.failed = true

    local v39 = tostring(v33)
    local v40 = tostring(v36)

    error(("Shared skater solver produced non-finite rates on tick%*; board=%*; skeleton=%*"):format(p63.ticks, v39, v40), 0)
end

function t1.present(p65, p66, p67, p68) -- line: 724
    -- upvalues: import (copy)
    if p65.failed then
        return nil
    end

    local v41, v42, v43 = import("skate_game/presentation").Presentation.view(p66, p67, p68)

    if v41 == nil then
        return nil
    end

    return import("skate_game/presentation").blend(v41.root, v42.root, v43)
end

return t1
