-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local t1 = {
    LookSettings = {},
    LookInput = {}
}

function t1.LookInput.new() -- line: 19
    return {
        elevation = 0,
        heading = 0
    }
end

local PERF = import("skate_core/camera/tracker").PERF

function t1.LookInput.update(p1, p2, p3) -- line: 29
    -- upvalues: t1 (copy), PERF (copy)
    if PERF.reference then
        return t1.LookInput.update_reference(p1, p2, p3)
    end

    local v1 = p2[1] * p3.heading_offset_degrees * 0.01745329238474369

    if -1.4835299085825682 - v1 >= 0 then
        v1 = -1.4835299085825682
    end

    if not (1.4835299085825682 - v1 >= 0) then
        v1 = 1.4835299085825682
    end

    p1.heading = (v1 - p1.heading) * (p3.heading_speed * 0.01666666753590107) + p1.heading

    local v2 = p2[2] * p3.elevation_offset_degrees * 0.01745329238474369

    if -1.4835299085825682 - v2 >= 0 then
        v2 = -1.4835299085825682
    end

    if not (1.4835299085825682 - v2 >= 0) then
        v2 = 1.4835299085825682
    end

    p1.elevation = (v2 - p1.elevation) * (p3.elevation_speed * 0.01666666753590107) + p1.elevation
end

function t1.LookInput.update_reference(p4, p5, p6) -- line: 43
    local function clamp(p7) -- line: 46
        local v3 = if -1.4835299085825682 - p7 >= 0 then -1.4835299085825682 else p7

        if 1.4835299085825682 - v3 >= 0 then
            return v3
        end

        return 1.4835299085825682
    end

    local v4 = p5[1] * p6.heading_offset_degrees * 0.01745329238474369

    if -1.4835299085825682 - v4 >= 0 then
        v4 = -1.4835299085825682
    end

    if not (1.4835299085825682 - v4 >= 0) then
        v4 = 1.4835299085825682
    end

    p4.heading = (v4 - p4.heading) * (p6.heading_speed * 0.01666666753590107) + p4.heading

    local v5 = p5[2] * p6.elevation_offset_degrees * 0.01745329238474369

    if -1.4835299085825682 - v5 >= 0 then
        v5 = -1.4835299085825682
    end

    if not (1.4835299085825682 - v5 >= 0) then
        v5 = 1.4835299085825682
    end

    p4.elevation = (v5 - p4.elevation) * (p6.elevation_speed * 0.01666666753590107) + p4.elevation
end

return t1
