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
local BoardToolkit = import("skate_core/physics/board_toolkit").BoardToolkit
local PhysicalPlayerStateLifecycle = import("skate_core/player/lifecycle").PhysicalPlayerStateLifecycle
local PhysicalStateId = import("skate_core/player/state").PhysicalStateId

local function parent() -- line: 24
    -- upvalues: import (copy)
    return import("skate_game/physics/player_state")
end

local function physics_mod() -- line: 28
    -- upvalues: import (copy)
    return import("skate_game/physics")
end

local function board_manager() -- line: 32
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/board_manager")
end

local function board_manager_runtime() -- line: 35
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/board_manager/runtime")
end

local function registry() -- line: 38
    -- upvalues: import (copy)
    return import("skate_game/physics/player_state/registry")
end

local function handplant() -- line: 41
    -- upvalues: import (copy)
    return import("skate_game/physics/handplant")
end

local function footplant() -- line: 44
    -- upvalues: import (copy)
    return import("skate_game/physics/footplant")
end

local function footplant_ground() -- line: 47
    -- upvalues: import (copy)
    return import("skate_game/physics/footplant/ground")
end

local function boneless() -- line: 50
    -- upvalues: import (copy)
    return import("skate_game/physics/boneless")
end

local function ground_exit() -- line: 53
    -- upvalues: import (copy)
    return import("skate_game/physics/ground_exit")
end

local function ground_phase() -- line: 56
    -- upvalues: import (copy)
    return import("skate_game/physics/ground_phase")
end

local function grind_trick() -- line: 59
    -- upvalues: import (copy)
    return import("skate_game/physics/grind_trick")
end

local function air_phase() -- line: 62
    -- upvalues: import (copy)
    return import("skate_game/physics/air_phase")
end

local function known_air() -- line: 65
    -- upvalues: import (copy)
    return import("skate_game/physics/known_air")
end

local function biped_air() -- line: 68
    -- upvalues: import (copy)
    return import("skate_game/physics/biped_air")
end

local function biped_ground() -- line: 71
    -- upvalues: import (copy)
    return import("skate_game/physics/biped_ground")
end

local function ground_animation() -- line: 74
    -- upvalues: import (copy)
    return import("skate_game/physics/ground_animation")
end

local function landing_on_deck() -- line: 77
    -- upvalues: import (copy)
    return import("skate_game/physics/landing_on_deck")
end

local function slide_state() -- line: 80
    -- upvalues: import (copy)
    return import("skate_game/physics/slide_state")
end

local function wipeout_states() -- line: 83
    -- upvalues: import (copy)
    return import("skate_game/physics/wipeout_states")
end

local function revert_state() -- line: 86
    -- upvalues: import (copy)
    return import("skate_game/physics/revert_state")
end

local function grind() -- line: 89
    -- upvalues: import (copy)
    return import("skate_game/physics/grind")
end

local function teleport_state() -- line: 92
    -- upvalues: import (copy)
    return import("skate_game/physics/teleport_state")
end

local t1 = {}

local function map_from_bits(p2) -- line: 98
    -- upvalues: v1 (copy)
    local v2 = table.create(#p2)

    for i = 1, #p2 do
        buffer.writeu32(v1, 0, p2[i])
        v2[i] = buffer.readf32(v1, 0)
    end

    return v2
end

local function state_debug(p3) -- line: 107
    -- upvalues: PhysicalStateId (copy)
    for v4, v5 in PhysicalStateId do
        if type(v5) == "number" and v5 == p3 then
            return v4
        end
    end

    return (tostring(p3))
end

local function is_connected_state(p4) -- line: 117
    -- upvalues: PhysicalStateId (copy)
    if p4 == PhysicalStateId.PhysicsGround
        or p4 == PhysicalStateId.PhysicsAir
        or p4 == PhysicalStateId.PhysicsAirSecondary
        or p4 == PhysicalStateId.FootPlant
        or p4 == PhysicalStateId.Boneless
        or p4 == PhysicalStateId.HandPlant
        or p4 == PhysicalStateId.RevertGround
        or p4 == PhysicalStateId.KnownAir
        or p4 == PhysicalStateId.BipedAir
        or p4 == PhysicalStateId.BipedGround
        or p4 == PhysicalStateId.OffBoardPushing
        or p4 == PhysicalStateId.GroundAnimation
        or p4 == PhysicalStateId.SlideGround
        or p4 == PhysicalStateId.WipeoutGround
        or p4 == PhysicalStateId.Teleporting then
        return true
    end

    return p4 == PhysicalStateId.LandingOnDeck
end

t1.Calls = {}

function t1.Calls.get_type(_, p6) -- line: 139
    return p6.state
end

function t1.Calls.exit(_, p8) -- line: 145
    -- upvalues: PhysicalStateId (copy), is_connected_state (copy)
    local state = p8.state.state

    if not PhysicalStateId.is_grind(state) and state ~= PhysicalStateId.Nonspecific and state ~= PhysicalStateId.Sleeping and not is_connected_state(state) then
        error("assertion failed: Exit called for a state without a connected owner", 0)
    end
end

function t1.Calls.enter(_, p10) -- line: 159
    -- upvalues: PhysicalStateId (copy), is_connected_state (copy)
    local state = p10.state.state

    if not PhysicalStateId.is_grind(state) and state ~= PhysicalStateId.Nonspecific and not is_connected_state(state) then
        error("assertion failed: Enter called for a state without a connected owner", 0)
    end
end

function t1.set(p11, p12, p13) -- line: 168
    -- upvalues: rt (copy), v1 (copy), import (copy), BoardToolkit (copy), PhysicalPlayerStateLifecycle (copy), PhysicalStateId (copy), t1 (copy)
    local PlayerState = import("skate_game/physics/player_state").PlayerState

    p12.player_state.requested_state = p13

    local v6 = PlayerState.current(p12.player_state)

    if v6 == p13 then
        return
    end

    local v7 = import("skate_game/physics/offboard/board_manager/runtime").observe(p11, p12)
    local processed = p12.player_input.processed

    if not import("skate_game/physics/player_state/registry").StateRegistry.can_transition(p12.player_state.registry, v6, p13) then
        local _error = error
        local format = string.format
        local v8 = "Physical state transition %s -> %s requires its native Enter/Exit production adapter"
        local v9 = false
        local v10

        for v11, v12 in PhysicalStateId do
            if type(v12) == "number" and v12 == v6 then
                v10 = v11
                v9 = true
                break
            end
        end

        if not v9 then
            v10 = tostring(v6)
        end

        local v13 = false
        local v14

        for v15, v16 in PhysicalStateId do
            if type(v16) == "number" and v16 == p13 then
                v14 = v15
                v13 = true
                break
            end
        end

        if not v13 then
            v14 = tostring(p13)
        end

        _error(format(v8, v10, v14), 0)
    end

    local player = p12.player_input.player
    local t2 = {
        player = {
            word_1312 = player.state_count_1312,
            previous_category_latch_1336 = player.state_value_1336,
            scalar_1344 = player.state_timer_1344
        },
        processed = {
            flags_2480 = processed.flags_2480,
            requested_state_2500 = p13,
            previous_state_2504 = processed.state_2504,
            current_state_2508 = processed.state_2508,
            current_category_2512 = processed.category_2512,
            previous_category_2516 = processed.category_2516,
            previous_category_latch_2520 = processed.player_state_value_2520,
            word_2564 = processed.state_count_2564,
            scalar_2664 = processed.state_timer_2664
        },
        skateboard_controller = rt.copy(p12.skateboard_controller.fields)
    }
    local v17 = import("skate_game/physics/offboard/board_manager/runtime").LiveState.effects(p12.board_possession_live, p11, p12.ground_lifecycle.board_animated_290, processed.timestep_2604)
    local Transition = import("skate_game/physics/offboard/board_manager").Transition
    local v18 = Transition.new(p12.board_possession, v7, v17, rt.copy(t2.skateboard_controller))
    local t3 = {}
    local t4 = {
        get_type = function(_, p15) -- get_type | line: 230
            -- upvalues: t3 (copy), t1 (copy)
            return t1.Calls.get_type(t3, p15)
        end,
        exit = function(_, p17) -- exit | line: 233
            -- upvalues: t3 (copy), t1 (copy)
            return t1.Calls.exit(t3, p17)
        end,
        enter = function(_, p19) -- enter | line: 236
            -- upvalues: t3 (copy), t1 (copy)
            return t1.Calls.enter(t3, p19)
        end
    }
    local t5 = {
        hold_skateboard = function(_) -- hold_skateboard | line: 241
            -- upvalues: Transition (copy), v18 (copy)
            return Transition.hold_skateboard(v18)
        end,
        let_go_of_skateboard = function(_) -- let_go_of_skateboard | line: 244
            -- upvalues: Transition (copy), v18 (copy)
            return Transition.let_go_of_skateboard(v18)
        end
    }
    local set_physics_state = PhysicalPlayerStateLifecycle.set_physics_state
    local lifecycle = p12.player_state.lifecycle
    local ok, result = pcall(set_physics_state, lifecycle, p13, t2, t4, t5)

    if not ok then
        p12.ground_lifecycle.board_animated_290 = v17.animated_290
        p11.board_wiping_out = v17.wiping_out
        p12.board_possession_live.alignment_active = v17.alignment_active

        if type(result) == "table" then
            error(string.format("Unknown physical state %s", (tostring(result[1]))), 0)
        end

        error(result, 0)
    end

    Transition.finish(v18, t2.skateboard_controller)
    p12.ground_lifecycle.board_animated_290 = v17.animated_290
    p11.board_wiping_out = v17.wiping_out
    p12.board_possession_live.alignment_active = v17.alignment_active
    import("skate_game/physics/offboard/board_manager/runtime").LiveState.publish_volumes(p12.board_possession_live, p11)
    player.state_count_1312 = t2.player.word_1312
    player.state_value_1336 = t2.player.previous_category_latch_1336
    player.state_timer_1344 = t2.player.scalar_1344
    processed.flags_2480 = t2.processed.flags_2480
    processed.state_2504 = t2.processed.previous_state_2504
    processed.state_2508 = t2.processed.current_state_2508
    processed.category_2512 = t2.processed.current_category_2512
    processed.category_2516 = t2.processed.previous_category_2516
    processed.player_state_value_2520 = t2.processed.previous_category_latch_2520
    processed.state_count_2564 = t2.processed.word_2564
    processed.state_timer_2664 = t2.processed.scalar_2664
    p12.skateboard_controller.fields = rt.copy(t2.skateboard_controller)

    if p12.player_input.toolkit == nil then
        local player_input = p12.player_input
        local from_board = BoardToolkit.from_board
        local board = p11.board
        local flags_2468, scalar_2612 = processed.flags_2468, processed.scalar_2612
        local v20 = processed.vectors_464_480_496_512_528[1]
        local v21 = table.create(#v20)

        for i = 1, #v20 do
            buffer.writeu32(v1, 0, v20[i])
            v21[i] = buffer.readf32(v1, 0)
        end

        player_input.toolkit = from_board(board, flags_2468, scalar_2612, v21, { 0, 1, 0, 0 })
    end

    if v6 ~= PhysicalStateId.RevertGround then
        if v6 == PhysicalStateId.HandPlant then
            import("skate_game/physics/handplant").Handplant.reset(p12.handplant)
        elseif v6 == PhysicalStateId.FootPlant then
            import("skate_game/physics/footplant").Footplant.reset(p12.footplant)
        elseif v6 ~= PhysicalStateId.Boneless then
            if v6 == PhysicalStateId.PhysicsGround then
                import("skate_game/physics/ground_exit").exit(p11, p12)
            elseif v6 == PhysicalStateId.PhysicsAirSecondary then
                import("skate_game/physics/grind_trick").exit(p11)
            elseif v6 == PhysicalStateId.PhysicsAir then
                import("skate_game/physics/air_phase").exit(p12)
            elseif v6 == PhysicalStateId.KnownAir then
                import("skate_game/physics/known_air").exit(p11, p12, p13)
            elseif v6 == PhysicalStateId.BipedAir then
                import("skate_game/physics/biped_air").exit(p12)
            elseif v6 == PhysicalStateId.BipedGround or v6 == PhysicalStateId.OffBoardPushing then
                import("skate_game/physics/biped_ground").exit(p12)
            elseif v6 == PhysicalStateId.GroundAnimation then
                import("skate_game/physics/ground_animation").exit(p11, p12)
            elseif v6 == PhysicalStateId.LandingOnDeck then
                import("skate_game/physics/landing_on_deck").exit(p11, p12)
            elseif v6 == PhysicalStateId.SlideGround then
                import("skate_game/physics/slide_state").exit(p11, p12)
            elseif v6 == PhysicalStateId.WipeoutGround then
                import("skate_game/physics/wipeout_states").exit(p11, p12)
            elseif v6 ~= PhysicalStateId.Sleeping and v6 ~= PhysicalStateId.Teleporting then
                if PhysicalStateId.is_grind(v6) or v6 == PhysicalStateId.Nonspecific then
                    import("skate_game/physics/grind").exit(p11, p12)
                else
                    error("internal error: entered unreachable code: state support checked before publication", 0)
                end
            end
        end
    end

    if p13 == PhysicalStateId.RevertGround then
        import("skate_game/physics/revert_state").enter(p11, p12)
    elseif p13 == PhysicalStateId.HandPlant then
        import("skate_game/physics/handplant").enter(p11, p12)
    elseif p13 == PhysicalStateId.FootPlant then
        import("skate_game/physics/footplant/ground").enter(p11, p12)
    elseif p13 == PhysicalStateId.Boneless then
        import("skate_game/physics/boneless").enter(p11, p12)
    elseif p13 == PhysicalStateId.PhysicsGround then
        import("skate_game/physics/ground_phase").enter(p11, p12)
    elseif p13 == PhysicalStateId.PhysicsAirSecondary then
        import("skate_game/physics/grind_trick").enter(p11, p12)
    elseif p13 == PhysicalStateId.PhysicsAir then
        import("skate_game/physics/air_phase").enter(p11, p12)
    elseif p13 == PhysicalStateId.KnownAir then
        import("skate_game/physics/known_air").enter(p11, p12)
    elseif p13 == PhysicalStateId.BipedAir then
        import("skate_game/physics/biped_air").enter(p11, p12)
    elseif p13 == PhysicalStateId.BipedGround or p13 == PhysicalStateId.OffBoardPushing then
        import("skate_game/physics/biped_ground").enter(p11, p12)
    elseif p13 == PhysicalStateId.GroundAnimation then
        import("skate_game/physics/ground_animation").enter(p11, p12)
    elseif p13 == PhysicalStateId.LandingOnDeck then
        import("skate_game/physics/landing_on_deck").enter(p11, p12)
    elseif p13 == PhysicalStateId.SlideGround then
        import("skate_game/physics/slide_state").enter(p11, p12)
    elseif p13 == PhysicalStateId.WipeoutGround then
        import("skate_game/physics/wipeout_states").enter(p11, p12)
    elseif p13 == PhysicalStateId.Teleporting then
        import("skate_game/physics/teleport_state").Runtime.enter(p12.teleport_state)
    elseif PhysicalStateId.is_grind(p13) or p13 == PhysicalStateId.Nonspecific then
        import("skate_game/physics/grind").enter(p11, p12)
    else
        error("internal error: entered unreachable code: state support checked before publication", 0)
    end

    import("skate_game/physics").SimulationExchange.request_state(p11.exchange, p13)
end

return t1
