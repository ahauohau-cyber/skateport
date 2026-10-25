-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local IDENTITY = require(sim.import)("skate_core/physics/skeleton_animation_record").IDENTITY
local t1 = {
    AirState = {}
}

function t1.AirState.new() -- line: 26
    -- upvalues: rt (copy), IDENTITY (copy)
    return {
        spin_angle = 0,
        spin_speed = 0,
        secondary_lean_angle = 0,
        flip_angle = 0,
        flip_speed = 0,
        flip_requested_speed = 0,
        flip_active = false,
        flip_side = false,
        spin_transform = rt.copy(IDENTITY),
        flip_axis = { 1, 0, 0, 0 }
    }
end

function t1.AirState.reset_spin(p1) -- line: 42
    p1.spin_angle = 0
    p1.spin_speed = 0
end

t1.Settings = {}
t1.Input = {}

return t1
