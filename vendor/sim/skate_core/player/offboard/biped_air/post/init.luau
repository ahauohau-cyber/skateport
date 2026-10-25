-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local dot = import("skate_core/player/offboard/biped_air/height").dot
local Requests = import("skate_core/player/wipeout").Requests
local v1 = import("skate_core/player/offboard/biped_air/post/checks")

local function recovered() -- line: 11
    -- upvalues: import (copy)
    return import("skate_core/player/offboard/biped_air/recovered")
end

local t1 = {
    Settings = v1.Settings,
    PostInput = {},
    State = {}
}

function t1.State.post_physics(p1, p2, p3, p4, p5, p6, p7) -- line: 37
    -- upvalues: import (copy), dot (copy), Requests (copy), v1 (copy)
    local DT = import("skate_core/player/offboard/biped_air/recovered").DT

    if bit32.band(p2.flags_2484, 2) ~= 0 then
        v1.skeleton_air(p7, p3, p5, p4)
    end

    if not p1.result.valid_404 and p2.state_timer_2664 > 1.899999976158142 then
        Requests.request(p7, 26, 0)
    end

    if p1.flags_544_550[4] then
        Requests.request(p7, 30, 0)
    end

    v1.offboard_air(p7, p3, p5, p4, p6)

    if bit32.band(p2.flags_2484, 1024) ~= 0 and DT < p1.time_remaining_444 then
        Requests.request(p7, 31, 0)
    end

    if p1.flags_544_550[6] and p1.result.velocity_288[2] < 0 then
        Requests.request(p7, 31, 0)
    end

    if p1.result.valid_404 and -dot(p1.result.normal_304, p1.result.contact_velocity_320) > 12.449999809265137 and p1.time_remaining_444 < 0.1599999964237213 then
        Requests.request(p7, 33, 0)
    end

    if p1.time_remaining_444 <= 0 and not p1.flags_544_550[7] then
        local v2 = dot(p2.forward_224, p1.result.contact_velocity_320)
        local v3 = dot(p2.side_192, p1.result.contact_velocity_320)

        if v2 > 20 or v3 > 4 or v2 < -2 then
            Requests.request(p7, 31, 0)
        end
    end

    if p1.time_remaining_444 < 0 and p1.flags_544_550[5] then
        Requests.request(p7, 31, 0)
    end

    if p1.time_remaining_444 > 4 and (math.abs(p2.input_2708) > 0.01 or math.abs(p2.input_2704) > 0.01) then
        Requests.request(p7, 26, 0)
    end
end

return t1
