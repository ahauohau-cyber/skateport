-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local PhysicalStateId = require(sim.import)("skate_core/player/state").PhysicalStateId
local t1 = {
    StateBinding = {}
}
local StateBinding = t1.StateBinding

function t1.StateBinding.new(p1) -- line: 22
    -- upvalues: PhysicalStateId (copy)
    return {
        state = p1,
        owner_offset = PhysicalStateId.native_owner_offset(p1)
    }
end

t1.PlayerStateChangeFields = {}
t1.ProcessedStateChangeFields = {}
t1.SkateboardControllerFields = {}
t1.StateChangeData = {}
t1.SkateboardControllerActions = {}
t1.StateCall = {}
t1.PhysicalStateCalls = {}
t1.PhysicalPlayerStateLifecycle = {}

function t1.PhysicalPlayerStateLifecycle.new(p2) -- line: 76
    -- upvalues: StateBinding (copy)
    return {
        active = StateBinding.new(p2)
    }
end

function t1.PhysicalPlayerStateLifecycle.active(p3) -- line: 82
    -- upvalues: rt (copy)
    return rt.copy(p3.active)
end

function t1.PhysicalPlayerStateLifecycle.set_physics_state(p4, p5, p6, p7, p8) -- line: 95
    -- upvalues: rt (copy), PhysicalStateId (copy), t1 (copy), StateBinding (copy)
    local v1 = PhysicalStateId.try_from(p5)

    t1.prepare_skateboard_controller(v1, p6.skateboard_controller, p6.processed.flags_2480, p8)
    p6.player.word_1312 = 0
    p6.player.scalar_1344 = 0
    p6.processed.scalar_2664 = 0
    p6.processed.word_2564 = 0

    local v2 = p7.get_type(p7, rt.copy(p4.active))
    local v3 = PhysicalStateId.category(v2)
    local v4 = PhysicalStateId.category(v1)

    p6.processed.previous_state_2504 = v2
    p6.processed.previous_category_2516 = v3
    p6.processed.requested_state_2500 = v1
    p6.processed.current_state_2508 = v1
    p6.processed.current_category_2512 = v4

    if v4 ~= v3 then
        p6.player.previous_category_latch_1336 = v3
    end

    p6.processed.previous_category_latch_2520 = p6.player.previous_category_latch_1336
    p7.exit(p7, {
        state = rt.copy(p4.active),
        active = rt.copy(p4.active)
    })
    p4.active = StateBinding.new(v1)
    p7.enter(p7, {
        state = rt.copy(p4.active),
        active = rt.copy(p4.active)
    })

    return rt.copy(p4.active)
end

function t1.prepare_skateboard_controller(p9, p10, p11, p12) -- line: 135
    -- upvalues: PhysicalStateId (copy), t1 (copy)
    if p9 ~= PhysicalStateId.BipedGround and p9 ~= PhysicalStateId.BipedAir and p9 ~= PhysicalStateId.OffBoardPushing then
        t1.stop_skateboard_controller(p10, p12)
    else
        if p10.system_on_452 then
            return
        end

        p10.word_444 = 0

        if bit32.band(p11, 384) == 0 then
            if p10.state_448 ~= 1 then
                p12.hold_skateboard(p12)
                p10.state_448 = 1
            end
        elseif p10.state_448 ~= 2 then
            p12.let_go_of_skateboard(p12)
            p10.state_448 = 2
        end

        p10.system_on_452 = true
    end
end

function t1.stop_skateboard_controller(p13, p14) -- line: 166
    if p13.system_on_452 then
        local state_448 = p13.state_448

        p13.word_444 = 0

        if state_448 ~= 0 then
            p14.let_go_of_skateboard(p14)
            p13.state_448 = 0
        end

        p13.system_on_452 = false
    end
end

return t1
