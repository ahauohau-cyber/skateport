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
local v2 = import("skate_game/physics/landing_on_deck/publication")
local v3 = import("skate_game/physics/landing_on_deck/skeleton")
local compose_affine = import("skate_core/physics/skeleton_animation_record").compose_affine
local State = import("skate_core/player/offboard/landing_state").State
local Requests = import("skate_core/player/wipeout").Requests
local Trajectory = import("skate_core/air/trajectory").Trajectory
local Collections = import("skate_data/collections").Collections

local function skeleton_controller() -- line: 29
    -- upvalues: import (copy)
    return import("skate_game/physics/skeleton_controller")
end

local function foot_ik() -- line: 32
    -- upvalues: import (copy)
    return import("skate_game/physics/foot_ik")
end

local function board_manager_runtime() -- line: 35
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/board_manager/runtime")
end

local function board_possession() -- line: 38
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/board_possession")
end

local function skeleton_output() -- line: 41
    -- upvalues: import (copy)
    return import("skate_game/physics/skeleton_output")
end

local function contact_toolkit() -- line: 44
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/contact_toolkit")
end

local function landing_deck() -- line: 47
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/landing_deck")
end

local function wipeout() -- line: 50
    -- upvalues: import (copy)
    return import("skate_game/physics/wipeout")
end

local t1 = {
    fill = v2.fill
}

local function map_from_bits(p2) -- line: 59
    -- upvalues: v1 (copy)
    local v4 = table.create(#p2)

    for i = 1, #p2 do
        buffer.writeu32(v1, 0, p2[i])
        v4[i] = buffer.readf32(v1, 0)
    end

    return v4
end

t1.Runtime = {}

function t1.Runtime.load(p3) -- line: 71
    -- upvalues: State (copy), Collections (copy)
    local function get(p4) -- line: 72
        -- upvalues: p3 (copy), Collections (copy)
        return Collections.float(p3, "physics_landingondeck", "default", p4)
    end

    local v6 = State.default()
    local MinAngleToAutoTurn = Collections.float(p3, "physics_landingondeck", "default", "MinAngleToAutoTurn")
    local BodySpinSpeedAuto = Collections.float(p3, "physics_landingondeck", "default", "BodySpinSpeedAuto")
    local BodySpinSpeed = Collections.float(p3, "physics_landingondeck", "default", "BodySpinSpeed")
    local BodySpinDeltaInput = Collections.float(p3, "physics_landingondeck", "default", "BodySpinDeltaInput")
    local BodySpinDeltaAuto = Collections.float(p3, "physics_landingondeck", "default", "BodySpinDeltaAuto")
    local MaxSpeedLandingOnBoard = Collections.float(p3, "physics_wipeout", "default", "MaxSpeedLandingOnBoard")
    local SkateRootYOffset = Collections.float(p3, "physics_skeleton", "default", "SkateRootYOffset")
    local SkateRootCapsuleRadius = Collections.float(p3, "physics_skeleton", "default", "SkateRootCapsuleRadius")
    local SkateRootCapsuleLength = Collections.float(p3, "physics_skeleton", "default", "SkateRootCapsuleLength")

    return {
        state = v6,
        settings = {
            minimum_auto_angle = MinAngleToAutoTurn,
            automatic_speed = BodySpinSpeedAuto,
            input_speed = BodySpinSpeed,
            input_delta = BodySpinDeltaInput,
            automatic_delta = BodySpinDeltaAuto,
            maximum_landing_speed = MaxSpeedLandingOnBoard
        },
        root_settings = {
            root_y_offset = SkateRootYOffset,
            capsule_radius = SkateRootCapsuleRadius,
            capsule_length = SkateRootCapsuleLength
        }
    }
end

function t1.clear_ik(p5) -- line: 104
    -- upvalues: import (copy)
    for _, v7 in p5.foot_ik.state.limbs do
        v7.board_blend = 0
        v7.external_blend = 0
        v7.mode = "Disabled"
    end

    import("skate_game/physics/foot_ik").FootIk.enable_feet(p5.foot_ik, false)
end

function t1.enter(p6, p7) -- line: 114
    -- upvalues: rt (copy), v1 (copy), import (copy), compose_affine (copy), State (copy), t1 (copy)
    import("skate_game/physics/skeleton_controller").SkeletonControllerState.request(p7.ground_lifecycle.skeleton_controller, 6, p7.skeleton_collision)

    local v8 = rt.copy(p7.player_input.processed)
    local toolkit = p7.player_input.toolkit

    if toolkit == nil then
        error("Landing entry requires the completed board toolkit", 0)
    end

    local v9 = rt.copy(toolkit.deck)
    local v10 = compose_affine(p7.animated_skeleton.roots.animation_to_world, p7.animated_skeleton.record.pose[24])
    local enter = State.enter
    local state = p7.landing_on_deck.state
    local manager = p7.landing_deck.manager
    local t2 = {
        previous_category = v8.category_2516
    }

    t2.hippy = bit32.band(v8.flags_2480, 4096) ~= 0
    t2.strength = p7.animation_input.extra.jump_strength
    t2.board_position = rt.copy(v9[4])

    local v11 = v8.vectors_544_560_592_608[3]
    local v12 = table.create(#v11)

    for i = 1, #v11 do
        buffer.writeu32(v1, 0, v11[i])
        v12[i] = buffer.readf32(v1, 0)
    end

    t2.com_position = v12

    local v14 = v8.vectors_544_560_592_608[4]
    local v15 = table.create(#v14)

    for i = 1, #v14 do
        buffer.writeu32(v1, 0, v14[i])
        v15[i] = buffer.readf32(v1, 0)
    end

    t2.com_velocity = v15

    local v17 = v8.vectors_400_416[1]
    local v18 = table.create(#v17)

    for i = 1, #v17 do
        buffer.writeu32(v1, 0, v17[i])
        v18[i] = buffer.readf32(v1, 0)
    end

    t2.board_velocity = v18

    local v20 = v8.vectors_544_560_592_608[1]
    local v21 = table.create(#v20)

    for i = 1, #v20 do
        buffer.writeu32(v1, 0, v20[i])
        v21[i] = buffer.readf32(v1, 0)
    end

    t2.up = v21
    t2.hips_up = rt.copy(v10[2])

    local v23 = v8.effective_anim_transform_192[1]
    local v24 = table.create(#v23)

    for i = 1, #v23 do
        buffer.writeu32(v1, 0, v23[i])
        v24[i] = buffer.readf32(v1, 0)
    end

    t2.animation_right = v24
    t2.reversed = bit32.band(v8.flags_2476, 4) ~= 0
    enter(state, manager, t2)
    t1.clear_ik(p7)

    local v26 = import("skate_game/physics/offboard/board_manager/runtime").LiveState.effects(p7.board_possession_live, p6, p7.ground_lifecycle.board_animated_290, v8.timestep_2604)
    local Effects = import("skate_game/physics/offboard/board_possession").Effects

    Effects.disable_animation(v26)
    Effects.standard_board(v26)
    p7.ground_lifecycle.board_animated_290 = v26.animated_290
    p6.board_wiping_out = v26.wiping_out
    p7.board_possession_live.alignment_active = v26.alignment_active
    import("skate_game/physics/offboard/board_manager/runtime").LiveState.publish_volumes(p7.board_possession_live, p6)

    if p7.landing_on_deck.state.hippy then
        import("skate_game/physics/skeleton_output").SkeletonOutput.trigger_wobble(p7.skeleton_output, false, bit32.band(bit32.bxor(bit32.rshift(v8.flags_2468, 20), (bit32.rshift(v8.flags_2476, 2))), 1) ~= 0)
    end
end

function t1.advance(p8, p9) -- line: 170
    -- upvalues: rt (copy), v1 (copy), import (copy), v3 (copy), State (copy), Trajectory (copy), t1 (copy)
    local v30 = rt.copy(p9.player_input.processed)
    local toolkit = p9.player_input.toolkit

    if toolkit == nil then
        error("Landing update requires the completed board toolkit", 0)
    end

    local v31 = rt.copy(toolkit.deck)
    local v32 = rt.copy(toolkit.effective[3])
    local v33 = import("skate_game/physics/offboard/contact_toolkit").StaticScene.new(p8.world)
    local v34 = import("skate_game/physics/offboard/landing_deck").Owner.update(p9.landing_deck, v33, p9.player_input)
    local align = State.align
    local state, settings = p9.landing_on_deck.state, p9.landing_on_deck.settings
    local v35 = v30.effective_anim_transform_192[3]
    local v36 = table.create(#v35)

    for i = 1, #v35 do
        buffer.writeu32(v1, 0, v35[i])
        v36[i] = buffer.readf32(v1, 0)
    end

    local state_timer_2664 = v30.state_timer_2664

    buffer.writeu32(v1, 0, v30.vectors_544_560_592_608[4][2])
    align(state, settings, v32, v36, state_timer_2664, buffer.readf32(v1, 0), p9.animation_input.extra.physical_body_spin)
    v3.update(p8, p9, rt.copy(v34.position))
    State.advance_spin(p9.landing_on_deck.state, v34)

    local manager = p9.landing_deck.manager

    if Trajectory.velocity_at(manager.trajectory_32, manager.elapsed_160)[2] < 0 then
        local accurate_time = State.accurate_time
        local v39 = v31[4][2]

        buffer.writeu32(v1, 0, v30.vectors_400_416[1][2])

        local v41 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v30.vectors_544_560_592_608[4][2])

        local v43 = accurate_time(v39, v41, buffer.readf32(v1, 0), {
            p9.skeleton.record.pose[16][4][2],
            p9.skeleton.record.pose[20][4][2]
        }, v30.wheel_count_2556)

        p9.landing_on_deck.state.time_to_land = v43
        p9.landing_on_deck.state.near_deck = v43 < 0.016000001
        import("skate_game/physics/offboard/landing_deck").Owner.calculate_accurate_ik_offset(p9.landing_deck, p9.player_input, p9.animated_skeleton, rt.copy(p9.animated_skeleton.unadjusted_board[4]), v43)

        if p9.landing_on_deck.state.near_deck then
            import("skate_game/physics/skeleton_output").SkeletonOutput.trigger_wobble(p9.skeleton_output, true, bit32.band(bit32.bxor(bit32.rshift(v30.flags_2468, 20), (bit32.rshift(v30.flags_2476, 2))), 1) ~= 0)
        end
    end

    if math.abs(p9.animated_skeleton.unadjusted_board[3][3]) >= 0.97000003 then
        if bit32.band(v30.flags_2484, 2) == 0 and p9.landing_on_deck.state.time_to_land < 0.2 then
            import("skate_game/physics/foot_ik").FootIk.enable_feet(p9.foot_ik, true)
        end
    else
        t1.clear_ik(p9)
    end

    local finish = State.finish
    local state2, settings2 = p9.landing_on_deck.state, p9.landing_on_deck.settings

    buffer.writeu32(v1, 0, v30.vectors_544_560_592_608[4][2])
    finish(state2, settings2, (buffer.readf32(v1, 0)))
end

function t1.post(p10, p11) -- line: 236
    -- upvalues: import (copy), Requests (copy)
    import("skate_game/physics/offboard/landing_deck").Owner.post_physics(p10.landing_deck, p10.player_input)

    if not import("skate_game/physics/offboard/landing_deck").Owner.fill(p10.landing_deck).can_land_316 then
        Requests.request(p10.wipeout.state, 24, 0)
    end

    if p10.landing_on_deck.state.dangerous then
        Requests.request(p10.wipeout.state, 27, 0)
    end

    return import("skate_game/physics/wipeout").Wipeout.check_air_collision(p10.wipeout, p10.player_input.processed, p11)
end

function t1.exit(_, p13) -- line: 249
    -- upvalues: import (copy)
    import("skate_game/physics/offboard/landing_deck").Owner.reset(p13.landing_deck)
end

return t1
