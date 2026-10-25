-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local State = import("skate_core/player/offboard/biped_air/recovered").State

local function landing_deck() -- line: 14
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/landing_deck")
end

local function wipeout() -- line: 17
    -- upvalues: import (copy)
    return import("skate_game/physics/wipeout")
end

local t1 = {}

local function map_from_bits(p1) -- line: 23
    -- upvalues: rt (copy)
    return rt.map(p1, rt.from_bits)
end

function t1.post(p2, p3) -- line: 28
    -- upvalues: rt (copy), import (copy), State (copy)
    import("skate_game/physics/offboard/landing_deck").Owner.post_physics(p2.landing_deck, p2.player_input)

    local processed = p2.player_input.processed
    local v1 = import("skate_game/physics/wipeout").Wipeout.mode(p2.wipeout, processed)
    local post_physics = State.post_physics
    local state = p2.biped_air.state
    local t2 = {
        flags_2484 = processed.flags_2484,
        state_timer_2664 = processed.state_timer_2664
    }
    local v2 = processed.effective_anim_transform_192[3]

    t2.forward_224 = rt.map(v2, rt.from_bits)

    local v3 = processed.effective_anim_transform_192[1]

    t2.side_192 = rt.map(v3, rt.from_bits)
    t2.input_2708 = p2.animation_input.extra.look_y
    t2.input_2704 = p2.animation_input.extra.look_x
    post_physics(state, t2, p2.biped_air.checks, p3, v1, rt.copy(p2.skeleton_input.root_velocity), p2.wipeout.state)
end

return t1
