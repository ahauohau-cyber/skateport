-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/player/offboard/controller/output")
local v2 = import("skate_core/player/offboard/controller/placement")
local v3 = import("skate_core/player/offboard/controller/state")
local v4 = import("skate_core/player/offboard/controller/step")
local t1 = {
    build_frame = v1.build_frame,
    PlacementInput = v2.PlacementInput,
    GroundResult = v1.GroundResult,
    ClipMetric = v3.ClipMetric,
    State = v3.State
}
local State = t1.State

t1.Settings = {}
t1.GroundJob = {}
t1.Controller = {}

function t1.Controller.new(p1, p2) -- line: 81
    -- upvalues: State (copy)
    return {
        state = State.new(p2),
        settings = p1
    }
end

function t1.Controller.reset(p3) -- line: 90
    -- upvalues: State (copy)
    State.reset(p3.state)
end

function t1.Controller.place(p4, p5) -- line: 94
    -- upvalues: State (copy)
    State.place(p4.state, p5)
end

function t1.Controller.step_ground(p6, p7) -- line: 98
    -- upvalues: t1 (copy)
    return t1.step_ground(p6.state, p6.settings, p7)
end

function t1.step_ground(p8, p9, p10) -- line: 105
    -- upvalues: v1 (copy), v4 (copy)
    v4.update(p8, p9, p10)

    return v1.export(p8)
end

return t1
