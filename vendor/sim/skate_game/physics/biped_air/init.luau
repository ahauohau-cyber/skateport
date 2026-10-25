-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/physics/biped_air/input")
local v2 = import("skate_game/physics/biped_air/post")
local v3 = import("skate_game/physics/biped_air/publication")
local v4 = import("skate_game/physics/biped_air/settings")
local v5 = import("skate_game/physics/biped_air/update")
local State = import("skate_core/player/offboard/biped_air/recovered").State
local Controller = import("skate_core/player/offboard/controller").Controller
local State2 = import("skate_core/player/offboard/board_possession/manager").State

local function air_feet() -- line: 22
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/air_feet")
end

local function air_selector() -- line: 25
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/air_selector")
end

local function landing_deck() -- line: 28
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/landing_deck")
end

local function skeleton_controller() -- line: 31
    -- upvalues: import (copy)
    return import("skate_game/physics/skeleton_controller")
end

local t1 = {
    post = v2.post,
    update = v5.update
}

local function map_from_bits(p1) -- line: 42
    -- upvalues: rt (copy)
    return rt.map(p1, rt.from_bits)
end

t1.BipedAir = {}

function t1.BipedAir.load(p2) -- line: 53
    -- upvalues: v4 (copy), State (copy)
    return {
        state = State.default(),
        checks = v4.load(p2)
    }
end

function t1.consume_selector(p3, p4) -- line: 64
    -- upvalues: import (copy), v1 (copy)
    local v6 = v1.context(p4)
    local deck_center_to_truck = p4.offboard_air_selector.settings.deck_center_to_truck

    import("skate_game/physics/offboard/air_selector").AirSelector.consume(p4.offboard_air_selector, p3.world, p3.network_proxies.solids, v6, deck_center_to_truck)
end

function t1.enter(p5, p6) -- line: 78
    -- upvalues: rt (copy), import (copy), v1 (copy), State (copy), Controller (copy), State2 (copy), map_from_bits (copy)
    State.reset(p6.biped_air.state)
    import("skate_game/physics/offboard/landing_deck").Owner.reset(p6.landing_deck)

    local v7 = v1.enter(p6)

    State.begin_enter_after_reset(p6.biped_air.state, rt.copy(v7))

    local offboard_feet = p6.offboard_feet

    p6.offboard_feet = State2.default()
    import("skate_game/physics/offboard/air_feet").enter(p6, offboard_feet)
    p6.offboard_feet = offboard_feet
    import("skate_game/physics/skeleton_controller").SkeletonControllerState.request(p6.ground_lifecycle.skeleton_controller, 4, p6.skeleton_collision)

    if not p6.offboard_air_selector.core.sampling.preinitialized_8494 then
        local v8 = v1.launch_packet(p6)

        v1.submit(p5, p6, v8)
    end

    local processed = p6.player_input.processed
    local place = Controller.place
    local controller = p6.biped_ground.controller
    local t2 = {
        frame = rt.copy(v7.animation_frame)
    }
    local v9 = processed.vectors_544_560_592_608[4]

    t2.velocity = rt.map(v9, rt.from_bits)
    t2.body_position = rt.copy(v7.body_position_15872)
    t2.current_state = processed.state_2508
    t2.previous_state = processed.state_2504
    t2.previous_frame = rt.map(processed.effective_anim_transform_192, map_from_bits)
    place(controller, t2)
    State.finish_enter(p6.biped_air.state, v1.enter(p6))
end

function t1.exit(p7) -- line: 112
    -- upvalues: State (copy)
    State.exit(p7.biped_air.state, p7.offboard_air_selector.core.sampling)
end

function t1.fill(p8) -- line: 117
    -- upvalues: import (copy), v3 (copy), State (copy)
    local physical = p8.player_input.physical

    v3.publish(State.output(p8.biped_air.state), physical.off_board)
    import("skate_game/physics/offboard/air_feet").publish(p8.offboard_feet, physical.off_board)

    local t3 = {
        off_board = physical.off_board,
        skeleton_position_48 = physical.collision.vector_48,
        skeleton_flag_3482 = physical.collision.flag_3482
    }

    import("skate_game/physics/offboard/landing_deck").Owner.publish(p8.landing_deck, t3)
    physical.collision.flag_3482 = t3.skeleton_flag_3482
end

return t1
