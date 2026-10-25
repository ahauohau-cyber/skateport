-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)
require(sim.import)

local t1 = {
    ManualState = {}
}

function t1.ManualState.eq(p1, p2) -- line: 20
    if p1.filtered_angle_error == p2.filtered_angle_error and p1.target_angle == p2.target_angle and p1.measured_angle == p2.measured_angle and p1.angular_correction == p2.angular_correction then
        return p1.elapsed == p2.elapsed
    end

    return false
end

function t1.ManualState.reset(p3) -- line: 30
    p3.filtered_angle_error = 0
    p3.target_angle = 0
    p3.measured_angle = 0
    p3.elapsed = 0
    p3.angular_correction = 0
end

function t1.ManualState.enter_ground(p4, p5, p6) -- line: 42
    if p5 == 100 then
        p4.angular_correction *= p6
        p4.filtered_angle_error *= p6

        return "Continue"
    end

    p4.filtered_angle_error = 0
    p4.target_angle = 0
    p4.measured_angle = 0
    p4.angular_correction = 0
    p4.elapsed = 0

    return "RemoveVelocityIntoGround"
end

t1.ManualEntryContinuation = {}

return t1
