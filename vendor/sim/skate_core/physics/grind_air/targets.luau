-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/trigonometry")
local v2

local function parent() -- line: 10
    -- upvalues: import (copy), v2 (ref)
    if v2 == nil then
        v2 = import("skate_core/physics/grind_air")
    end

    return v2
end

local t1 = {
    CONTACTS = { 0, 1, 4, 0, 2, 2, 3 },
    DESIRED = { 90, 90, 90, 90, 0, 0, 0 },
    Settings = {},
    DeckDimensions = {}
}

function t1.DeckDimensions.contact_points(p1, p2) -- line: 35
    -- upvalues: import (copy), v1 (copy), v2 (ref)
    local v3 = p1.middle_length * 0.5
    local v4 = p1.front_end_size * p2
    local sin_cos = v1.sin_cos
    local front_end_angle_degrees = p1.front_end_angle_degrees

    if v2 == nil then
        v2 = import("skate_core/physics/grind_air")
    end

    local v5 = sin_cos(front_end_angle_degrees * v2.DEG) * v4
    local v6 = v3 + p1.truck_z_front

    return {
        { 0, 0, 0, 0 },
        {
            0,
            v5,
            v4 + v3,
            0
        },
        {
            0,
            p1.truck_y,
            v6,
            0
        },
        {
            0,
            p1.truck_y,
            -v6,
            0
        },
        {
            0,
            v5,
            -(v4 + v3),
            0
        }
    }
end

function t1.Settings.validate(p3) -- line: 51
    if not (p3.frames >= 2 and p3.frames <= 12) then
        error("Stock GrindAir NumFramesToTest exceeds native 2..12 storage", 0)
    end
end

return t1
