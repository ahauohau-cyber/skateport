-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local GameplayActions = require(sim.import)("skate_core/input/gameplay_map").GameplayActions
local t1 = {
    TickInput = {}
}

function t1.TickInput.new(p1, p2, p3) -- line: 22
    -- upvalues: rt (copy)
    return {
        tick = p1,
        actions = rt.copy(p2),
        controller_available = p3
    }
end

function t1.TickInput.eq(p4, p5) -- line: 31
    -- upvalues: GameplayActions (copy)
    if p4.tick == p5.tick then
        return GameplayActions.eq(p4.actions, p5.actions) and p4.controller_available == p5.controller_available
    end

    return false
end

function t1.TickInput.tick(p6) -- line: 37
    return p6.tick
end

function t1.TickInput.actions(p7) -- line: 41
    -- upvalues: rt (copy)
    return rt.copy(p7.actions)
end

function t1.TickInput.actions_borrowed(p8) -- line: 47
    return p8.actions
end

function t1.TickInput.controller_available(p9) -- line: 51
    return p9.controller_available
end

return t1
