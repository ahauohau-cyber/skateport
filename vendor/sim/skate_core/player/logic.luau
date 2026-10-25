-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/player/lifecycle")
local v2 = import("skate_core/player/selector")
local PhysicalPlayerStateLifecycle = v1.PhysicalPlayerStateLifecycle
local StateSelector = v2.StateSelector
local t1 = {
    PhysicsOutputStaging = {}
}
local PhysicsOutputStaging = t1.PhysicsOutputStaging

function t1.PhysicsOutputStaging.clear_like_82db6000(p1) -- line: 23
    p1.word_200 = 0

    for i = 1, #p1.bytes_20_through_53 do
        p1.bytes_20_through_53[i] = 0
    end

    for i = 1, #p1.scalars_56_through_188 do
        p1.scalars_56_through_188[i] = 0
    end
end

t1.LogicResult = {}
t1.PhysicalPlayerLogic = {}

function t1.PhysicalPlayerLogic.new(p2) -- line: 42
    -- upvalues: PhysicalPlayerStateLifecycle (copy), StateSelector (copy)
    return {
        frames_since_jump_1304 = 0,
        selector = StateSelector.default(),
        lifecycle = PhysicalPlayerStateLifecycle.new(p2)
    }
end

function t1.PhysicalPlayerLogic.run(p3, p4, p5, p6, p7, p8) -- line: 53
    -- upvalues: rt (copy), PhysicalPlayerStateLifecycle (copy), StateSelector (copy), PhysicsOutputStaging (copy)
    local v3 = PhysicalPlayerStateLifecycle.active(p3.lifecycle)
    local v4 = p7.get_type(p7, rt.copy(v3))
    local v5 = StateSelector.calculate(p3.selector, v4, p4)
    local v6 = v5 ~= v4
    local v7

    if v6 then
        p3.frames_since_jump_1304 = 100
        v7 = PhysicalPlayerStateLifecycle.set_physics_state(p3.lifecycle, v5, p5, p7, p8)
    else
        v7 = rt.copy(v3)
    end

    PhysicsOutputStaging.clear_like_82db6000(p6)

    return {
        previous = v3,
        selected = v7,
        changed = v6
    }
end

return t1
