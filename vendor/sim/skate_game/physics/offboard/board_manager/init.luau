-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_game/physics/offboard/board_possession")
local v2 = import("skate_game/physics/offboard/board_possession/drives")
local v3 = import("skate_game/physics/offboard/board_possession/settings")
local v4 = import("skate_core/player/offboard/board_possession")
local t1 = {}

local function effects_trait(p1) -- line: 28
    -- upvalues: v1 (copy)
    local Effects = v1.Effects

    return {
        enable_animation_soft = function(_) -- enable_animation_soft | line: 31
            -- upvalues: p1 (copy), Effects (copy)
            return Effects.enable_animation_soft(p1)
        end,
        enable_animation_angular_only = function(_) -- enable_animation_angular_only | line: 34
            -- upvalues: p1 (copy), Effects (copy)
            return Effects.enable_animation_angular_only(p1)
        end,
        disable_animation = function(_) -- disable_animation | line: 37
            -- upvalues: p1 (copy), Effects (copy)
            return Effects.disable_animation(p1)
        end,
        disable_linear_drive = function(_) -- disable_linear_drive | line: 40
            -- upvalues: p1 (copy), Effects (copy)
            return Effects.disable_linear_drive(p1)
        end,
        standard_board = function(_) -- standard_board | line: 43
            -- upvalues: p1 (copy), Effects (copy)
            return Effects.standard_board(p1)
        end,
        released_board = function(_) -- released_board | line: 46
            -- upvalues: p1 (copy), Effects (copy)
            return Effects.released_board(p1)
        end,
        collision_volumes = function(_, p9) -- collision_volumes | line: 49
            -- upvalues: p1 (copy), Effects (copy)
            return Effects.collision_volumes(p1, p9)
        end,
        clear_alignment = function(_) -- clear_alignment | line: 52
            -- upvalues: p1 (copy), Effects (copy)
            return Effects.clear_alignment(p1)
        end,
        alignment = function(_, p12) -- alignment | line: 55
            -- upvalues: p1 (copy), Effects (copy)
            return Effects.alignment(p1, p12)
        end,
        velocity = function(_, p14) -- velocity | line: 58
            -- upvalues: p1 (copy), Effects (copy)
            return Effects.velocity(p1, p14)
        end,
        position = function(_, p16) -- position | line: 61
            -- upvalues: p1 (copy), Effects (copy)
            return Effects.position(p1, p16)
        end,
        hook_frame = function(_, p18) -- hook_frame | line: 64
            -- upvalues: p1 (copy), Effects (copy)
            return Effects.hook_frame(p1, p18)
        end,
        target_position_velocity = function(_, p20) -- target_position_velocity | line: 67
            -- upvalues: p1 (copy), Effects (copy)
            return Effects.target_position_velocity(p1, p20)
        end,
        torque = function(_, p22) -- torque | line: 70
            -- upvalues: p1 (copy), Effects (copy)
            return Effects.torque(p1, p22)
        end
    }
end

t1.Owner = {}

function t1.Owner.load(p23) -- line: 80
    -- upvalues: v3 (copy), v4 (copy)
    return {
        state = v4.State.default(),
        settings = v3.load(p23)
    }
end

function t1.Owner.update(p24, p25, p26, p27) -- line: 89
    -- upvalues: v4 (copy), effects_trait (copy)
    v4.State.update(p24.state, p25, p26, p24.settings, (effects_trait(p27)))
end

function t1.Owner.hold(p28, p29, p30, p31) -- line: 93
    -- upvalues: v4 (copy), effects_trait (copy)
    v4.State.hold(p28.state, p29, p30, (effects_trait(p31)))
end

function t1.Owner.let_go(p32, p33, p34, p35) -- line: 99
    -- upvalues: v4 (copy), effects_trait (copy)
    v4.State.let_go(p32.state, p33, p34, p32.settings, (effects_trait(p35)))
end

function t1.Owner.stop(p36, p37, p38, p39) -- line: 103
    -- upvalues: v4 (copy), effects_trait (copy)
    v4.State.stop(p36.state, p37, p38, p36.settings, (effects_trait(p39)))
end

function t1.Owner.reset_for_teleport(p40, p41, p42, p43) -- line: 109
    -- upvalues: v4 (copy), t1 (copy)
    p41.word_444 = 0
    t1.Owner.stop(p40, p41, p42, p43)
    p40.state.retrieval = v4.Retrieval.default()
end

function t1.Owner.append_drives(p44, p45, p46, p47, p48, p49, p50) -- line: 119
    -- upvalues: v2 (copy)
    v2.append(p44.state, p45, p46, p47, p48, p49, p50)
end

function t1.Owner.fill(p51, p52, p53, p54) -- line: 125
    -- upvalues: v4 (copy)
    return v4.fill(p52, p51.state, p53, p54)
end

t1.Transition = {}

function t1.Transition.new(p55, p56, p57, p58) -- line: 143
    return {
        changed = false,
        owner = p55,
        observation = p56,
        effects = p57,
        previous = p58
    }
end

function t1.Transition.finish(p59, p60) -- line: 156
    if p59.changed then
        p60.word_444 = p59.previous.word_444
    end
end

function t1.Transition.hold_skateboard(p61) -- line: 163
    -- upvalues: t1 (copy)
    p61.previous.word_444 = 0
    t1.Owner.hold(p61.owner, p61.previous, p61.observation, p61.effects)
    p61.changed = true
end

function t1.Transition.let_go_of_skateboard(p62) -- line: 169
    -- upvalues: t1 (copy)
    p62.previous.word_444 = 0
    t1.Owner.let_go(p62.owner, p62.previous, p62.observation, p62.effects)
    p62.changed = true
end

return t1
