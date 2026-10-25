-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)

local function grind() -- line: 10
    -- upvalues: import (copy)
    return import("skate_game/physics/grind")
end

local t1 = {
    State = {}
}

function t1.State.new() -- line: 24
    return {
        already_jumped = false,
        updates = 0,
        leaving_updates = 0,
        preparing_jump = false,
        output = {
            crouch = 0,
            leaving = false,
            substate = 0,
            classification_104 = 0,
            just_jumped = false,
            slide_wipeout = false,
            direction = { 0, 1, 0, 0 },
            normal = { 0, 1, 0, 0 },
            across = { 0, 1, 0, 0 },
            jump_velocity = { 0, 0, 0, 0 },
            slide_impulse = { 0, 0, 0, 0 },
            tipslide_97_98_99 = { false, false, false }
        },
        frame = {
            { 1, 0, 0, 0 },
            { 0, 1, 0, 0 },
            { 0, 0, 1, 0 },
            { 0, 0, 0, 0 }
        }
    }
end

function t1.State.enter(p1, p2, p3) -- line: 54
    -- upvalues: rt (copy), import (copy)
    local Family = import("skate_game/physics/grind").Family

    p1.output.substate = 1
    p1.output.leaving = false
    p1.already_jumped = false
    p1.output.just_jumped = false
    p1.output.tipslide_97_98_99 = { false, false, false }
    p1.frame = rt.copy(p3)
    p1.updates = 0
    p1.output.crouch = 0
    p1.leaving_updates = 0
    p1.output.jump_velocity = { 0, 0, 0, 0 }

    if p2 == Family.Boardslide or p2 == Family.Darkslide then
        p1.output.slide_wipeout = false
        p1.preparing_jump = false
    end
end

return t1
