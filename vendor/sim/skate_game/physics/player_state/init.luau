-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/physics/player_state/post_input")
local v2 = import("skate_game/physics/player_state/pre_state")
local v3 = import("skate_game/physics/player_state/publication")
local v4 = import("skate_game/physics/player_state/registry")
local v5 = import("skate_game/physics/player_state/selection")
local v6 = import("skate_game/physics/player_state/transition")
local FilteredState = import("skate_core/physics/filtered_state").FilteredState
local PhysicalPlayerStateLifecycle = import("skate_core/player/lifecycle").PhysicalPlayerStateLifecycle
local StateSelector = import("skate_core/player/selector").StateSelector
local PhysicalStateId = import("skate_core/player/state").PhysicalStateId
local Collections = import("skate_data/collections").Collections

local function player_input() -- line: 30
    -- upvalues: import (copy)
    return import("skate_game/physics/player_input")
end

local function teleport_state() -- line: 33
    -- upvalues: import (copy)
    return import("skate_game/physics/teleport_state")
end

local function biped_ground() -- line: 36
    -- upvalues: import (copy)
    return import("skate_game/physics/biped_ground")
end

local function air_selector() -- line: 39
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/air_selector")
end

local function foot_ik_queries() -- line: 42
    -- upvalues: import (copy)
    return import("skate_game/physics/foot_ik_queries")
end

local function contact_toolkit() -- line: 45
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/contact_toolkit")
end

local t1 = {
    PlayerState = {}
}
local PlayerState = t1.PlayerState

function t1.PlayerState.load(p1, _) -- line: 72
    -- upvalues: v1 (copy), v4 (copy), FilteredState (copy), PhysicalPlayerStateLifecycle (copy), StateSelector (copy), PhysicalStateId (copy), Collections (copy)
    local function thresholds(p3) -- line: 73
        -- upvalues: p1 (copy), Collections (copy)
        return {
            field_856_primary = Collections.float(p1, p3, "default", "NaturalAirMaxDist"),
            field_856_secondary = Collections.float(p1, p3, "default", "NaturalAirMinDist"),
            field_7692 = Collections.float(p1, p3, "default", "NaturalAirTime")
        }
    end

    local v7 = v4.StateRegistry.new()
    local v8 = PhysicalPlayerStateLifecycle.new(PhysicalStateId.Sleeping)
    local v9 = StateSelector.default()
    local v10 = FilteredState.default()
    local v11 = v1.PostInputState.new()
    local physics_airstates = thresholds("physics_airstates")
    local physics_state_skitching = thresholds("physics_state_skitching")
    local MaxDeckZAxisYForAnimatedDeck = Collections.float(p1, "physics_animation", "default", "MaxDeckZAxisYForAnimatedDeck")

    return {
        filtered_output = nil,
        ground_output = nil,
        state_count = 0,
        update_count = 0,
        initialized = false,
        registry = v7,
        lifecycle = v8,
        selector = v9,
        requested_state = PhysicalStateId.Sleeping,
        filtered = v10,
        post = v11,
        state_flags = table.create(36, false),
        normal_off_ground = physics_airstates,
        skitching_off_ground = physics_state_skitching,
        animated_board_threshold = MaxDeckZAxisYForAnimatedDeck
    }
end

local v12 = false

function t1.PlayerState.set_current_reference(p4) -- line: 121
    -- upvalues: v12 (ref)
    v12 = p4
end

function t1.PlayerState.current(p5) -- line: 124
    -- upvalues: PhysicalPlayerStateLifecycle (copy), v12 (ref)
    if v12 then
        return PhysicalPlayerStateLifecycle.active(p5.lifecycle).state
    end

    return p5.lifecycle.active.state
end

function t1.PlayerState.current_reference(p6) -- line: 130
    -- upvalues: PhysicalPlayerStateLifecycle (copy)
    return PhysicalPlayerStateLifecycle.active(p6.lifecycle).state
end

function t1.PlayerState.reset_for_teleport(p7) -- line: 136
    -- upvalues: FilteredState (copy)
    FilteredState.reset(p7.filtered)
    p7.filtered_output = nil
    p7.ground_output = nil
    p7.selector.nonspecific_collision_free_frames = 0
    p7.selector.nonspecific_collision_frames = 0
    p7.selector.something_colliding_frames = 0
    p7.selector.two_wheel_counter = 0
    p7.selector.three_wheel_counter = 0
    p7.selector.post_grind_jump_counter = 0
    p7.selector.air_frames = 0
    p7.selector.teleport_countdown = 10
    p7.selector.skitch_exit_countdown = 0
    p7.post.trajectory_available = false
end

function t1.initialize(p8, p9) -- line: 157
    -- upvalues: v6 (copy), PhysicalStateId (copy)
    if not p9.player_state.initialized then
        v6.set(p8, p9, PhysicalStateId.PhysicsGround)
        p9.player_state.initialized = true
    end
end

function t1.post_input_and_select(p10, p11) -- line: 167
    -- upvalues: import (copy), v5 (copy), t1 (copy)
    t1.complete_post_input(p10, p11)

    local v13 = import("skate_game/physics/player_input").PlayerInputRuntime.processed_snapshot(p11.player_input, p10.ticks)

    return v5.advance(p10, p11, v13)
end

function t1.complete_post_input(p12, p13) -- line: 177
    -- upvalues: v1 (copy)
    return v1.advance(p12, p13)
end

function t1.publish(p14, p15) -- line: 183
    -- upvalues: v3 (copy)
    return v3.publish(p14, p15)
end

function t1.enter_after_teleport(p16, p17) -- line: 189
    -- upvalues: import (copy), v6 (copy), PhysicalStateId (copy)
    local v14 = if import("skate_game/physics/teleport_state").Runtime.take_manual_on_board(p17.teleport_state) == false then PhysicalStateId.BipedGround else PhysicalStateId.PhysicsGround

    return v6.set(p16, p17, v14)
end

function t1.pre_state(p18, p19) -- line: 202
    -- upvalues: v2 (copy)
    return v2.advance(p18, p19)
end

function t1.resume_after_climb(p20, p21) -- line: 208
    -- upvalues: rt (copy), import (copy), v6 (copy), PhysicalStateId (copy), PlayerState (copy)
    import("skate_game/physics/biped_ground").exit(p21)
    import("skate_game/physics/offboard/air_selector").AirSelector.reset(p21.offboard_air_selector)
    p21.collision_extra_errors = {
        { 0, 0, 0, 0 },
        { 0, 0, 0, 0 }
    }
    p21.animated_skeleton.motion.velocity_world = { 0, 0, 0, 0 }
    p21.player_input.processed.vectors_544_560_592_608[4] = { 0, 0, 0, 0 }

    if PlayerState.current(p21.player_state) == PhysicalStateId.BipedGround then
        import("skate_game/physics/biped_ground").enter(p20, p21)
    else
        v6.set(p20, p21, PhysicalStateId.BipedGround)
    end

    local v15 = import("skate_game/physics/foot_ik_queries").query(p20.world, p21.skeleton)

    import("skate_game/physics/foot_ik_queries").SkeletonLineTests.publish(v15, p21.player_input.player)

    local v16 = rt.copy(p21.biped_ground.ground.frame_80)
    local t2 = {
        position = rt.copy(v16[4]),
        right = rt.copy(v16[1]),
        up = rt.copy(v16[2]),
        forward = rt.copy(v16[3]),
        animation_right = rt.copy(v16[1]),
        animation_up = rt.copy(v16[2]),
        velocity = { 0, 0, 0, 0 }
    }
    local v17 = rt.to_i32(p21.player_input.processed.actor_query_2952)
    local v18 = import("skate_game/physics/offboard/contact_toolkit").StaticScene.new(p20.world)

    import("skate_game/physics/offboard/contact_toolkit").Owner.submit(p21.offboard_contact, t2, v17, v18)
end

return t1
