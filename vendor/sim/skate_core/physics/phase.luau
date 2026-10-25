-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)
require(sim.import)

local t1 = {
    PhysicsBody = {},
    PhysicsCommand = {},
    PhysicsCommandBuffer = {}
}

function t1.PhysicsCommandBuffer.new(p1) -- line: 30
    return {
        tick = p1,
        commands = {}
    }
end

function t1.PhysicsCommandBuffer.tick(p2) -- line: 34
    return p2.tick
end

function t1.PhysicsCommandBuffer.commands(p3) -- line: 38
    return p3.commands
end

function t1.PhysicsCommandBuffer.is_empty(p4) -- line: 42
    return #p4.commands == 0
end

function t1.PhysicsCommandBuffer.push(p5, p6, p7) -- line: 47
    if p6 ~= p5.tick then
        error(("Physics command belongs to tick %*, buffer owns tick %*"):format(p6, p5.tick), 0)
    end

    p5.commands[#p5.commands + 1] = p7
end

function t1.PhysicsCommandBuffer.clear(p8, p9) -- line: 55
    if p9 ~= p8.tick then
        error(("Cannot clear physics commands for tick %*; buffer owns tick %*"):format(p9, p8.tick), 0)
    end

    table.clear(p8.commands)
end

t1.PhysicsEvent = {}
t1.PhysicsEventBuffer = {}

function t1.PhysicsEventBuffer.new(p10) -- line: 72
    return {
        tick = p10,
        events = {}
    }
end

function t1.PhysicsEventBuffer.tick(p11) -- line: 76
    return p11.tick
end

function t1.PhysicsEventBuffer.events(p12) -- line: 80
    return p12.events
end

function t1.PhysicsEventBuffer.emit(p13, p14, p15) -- line: 85
    if p14 ~= p13.tick then
        error(("Physics event belongs to tick %*, buffer owns tick %*"):format(p14, p13.tick), 0)
    end

    p13.events[#p13.events + 1] = p15
end

t1.PhysicalOutputSnapshot = {}

return t1
