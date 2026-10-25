-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)
require(sim.import)

local t1 = {
    Settings = {},
    State = {}
}

function t1.State.default() -- line: 21
    return {
        gesture_time = 0,
        takeoff_time = 0,
        selected = nil
    }
end

function t1.State.begin(p1, p2) -- line: 25
    p1.gesture_time = p2.gesture_window
    p1.takeoff_time = p2.takeoff_window
end

function t1.State.update(p3, p4, p5, p6, p7) -- line: 33
    -- upvalues: t1 (copy)
    local v1 = #p4 - 1
    local v2

    for i = 0, v1 do
        if p4[i + 1] then
            v2 = i
            break
        end
    end

    if v2 ~= nil then
        p3.gesture_time = 0
        p3.selected = v2
    else
        p3.gesture_time = t1.cap(p3.gesture_time + p6, p7.gesture_window)
    end

    local v3 = p3.gesture_time < p7.gesture_window

    if p5 == 2 then
        p3.takeoff_time = t1.cap(p3.takeoff_time + p6, p7.takeoff_window)
    else
        p3.takeoff_time = 0
    end

    local v4 = not (p3.takeoff_time <= 0) and p3.takeoff_time < p7.takeoff_window

    return if v3 and v4 then p3.selected else nil
end

function t1.cap(p8, p9) -- line: 61
    if p8 - p9 >= 0 then
        return p9
    end

    return p8
end

return t1
