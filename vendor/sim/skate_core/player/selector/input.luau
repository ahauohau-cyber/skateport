-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local PhysicalStateId = require(sim.import)("skate_core/player/state").PhysicalStateId
local t1 = {
    ProcessedStateInput = {}
}
local ProcessedStateInput = t1.ProcessedStateInput
local v1 = false

function t1.set_reference(p1) -- line: 37
    -- upvalues: v1 (ref)
    v1 = p1
end

function t1.ProcessedStateInput.read(p2) -- line: 47
    -- upvalues: rt (copy), v1 (ref)
    if v1 then
        return rt.copy(p2)
    end

    return p2
end

function t1.ProcessedStateInput.has_2468(p3, p4) -- line: 54
    return bit32.band(p3.flags_2468, p4) ~= 0
end

function t1.ProcessedStateInput.has_2472(p5, p6) -- line: 58
    return bit32.band(p5.flags_2472, p6) ~= 0
end

function t1.ProcessedStateInput.has_2476(p7, p8) -- line: 62
    return bit32.band(p7.flags_2476, p8) ~= 0
end

function t1.ProcessedStateInput.has_2480(p9, p10) -- line: 66
    return bit32.band(p9.flags_2480, p10) ~= 0
end

function t1.ProcessedStateInput.has_2484(p11, p12) -- line: 70
    return bit32.band(p11.flags_2484, p12) ~= 0
end

function t1.ProcessedStateInput.has_2488(p13, p14) -- line: 74
    return bit32.band(p13.flags_2488, p14) ~= 0
end

function t1.ProcessedStateInput.air_variant_from_2468(p15) -- line: 78
    -- upvalues: PhysicalStateId (copy), ProcessedStateInput (copy)
    if ProcessedStateInput.has_2468(p15, 1024) then
        return PhysicalStateId.KnownAir
    end

    return PhysicalStateId.PhysicsAir
end

t1.StateSelectionInput = {}

return t1
