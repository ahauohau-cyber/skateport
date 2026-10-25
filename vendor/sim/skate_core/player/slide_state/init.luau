-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local v1 = require(sim.import)("skate_core/player/slide_state/forces")
local t1 = {
    SlideInput = v1.SlideInput,
    SlideSettings = v1.SlideSettings,
    SlideSurface = v1.SlideSurface,
    angular_correction = v1.angular_correction,
    sliding_force = v1.sliding_force,
    SlideState = {}
}
local SlideState = t1.SlideState

function t1.SlideState.new() -- line: 25
    return {
        start_speed = 0,
        steering_push = 1,
        damped_turn = 0,
        flag48 = false,
        wall_riding = false
    }
end

function t1.SlideState.enter(p1, p2) -- line: 35
    -- upvalues: SlideState (copy)
    p1.start_speed = p2
    SlideState.exit(p1)
end

function t1.SlideState.exit(p3) -- line: 40
    p3.flag48 = false
    p3.wall_riding = false
    p3.steering_push = 1
    p3.damped_turn = 0
end

return t1
