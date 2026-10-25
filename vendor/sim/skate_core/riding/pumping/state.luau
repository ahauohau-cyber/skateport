-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

local t1 = {
    PumpingState = {}
}

function t1.PumpingState.reset(p1) -- line: 38
    -- upvalues: rt (copy), t1 (copy)
    rt.assign(p1, t1.PumpingState.reset_state())
end

function t1.PumpingState.reset_state() -- line: 43
    return {
        smoothed_height_change = 0,
        pumping_time = 0,
        previous_height = 0,
        pumping = 0,
        pump_acceleration = 0,
        angular_speed = 0,
        absorption = 0,
        ground_normal_absorption = 0,
        minimum_crouch = 0,
        deck_angle_absorption = 0,
        reset_only_scalar = 0,
        record_valid = false,
        intentional_pumping = 0,
        previous_position = { 0, 0, 0, 0 },
        previous_normal = { 0, 0, 0, 0 }
    }
end

function t1.PumpingState.physics_output(p2) -- line: 65
    return {
        compression = 0,
        absorption = p2.absorption,
        ground_normal_absorption = p2.ground_normal_absorption,
        minimum_crouch = p2.minimum_crouch,
        deck_angle_absorption = p2.deck_angle_absorption,
        pump_acceleration = p2.pump_acceleration,
        intentional_pumping = p2.intentional_pumping
    }
end

t1.PumpingOutput = {}

return t1
