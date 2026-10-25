-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local Attributes = require(sim.import)("skate_data/state_graph/attributes").Attributes
local t1 = {
    GroundSlopeType = {}
}

function t1.GroundSlopeType.eq(p1, p2) -- line: 17
    return p1[1] == p2[1]
end

function t1.GroundSlopeType.parse(p3) -- line: 22
    -- upvalues: Attributes (copy)
    local slopetype = Attributes.text(p3, "slopetype")

    if slopetype == nil then
        error("GroundSlopeType requires slopetype", 0)
    end

    local v1

    if slopetype == "Flat" then
        v1 = 0
    elseif slopetype == "StairUpShallow" then
        v1 = 1
    elseif slopetype == "StairUpSteep" then
        v1 = 2
    elseif slopetype == "StairDnShallow" then
        v1 = 3
    elseif slopetype == "StairDnSteep" then
        v1 = 4
    elseif slopetype == "RampUpShallow" then
        v1 = 5
    elseif slopetype == "RampUpSteep" then
        v1 = 6
    elseif slopetype == "RampDnShallow" then
        v1 = 7
    elseif slopetype == "RampDnSteep" then
        v1 = 8
    else
        error("Unknown GroundSlopeType slopetype " .. slopetype, 0)
    end

    return { v1 }
end

function t1.GroundSlopeType.matches(p4, p5) -- line: 56
    return p5 == p4[1]
end

return t1
