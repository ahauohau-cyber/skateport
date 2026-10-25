-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/animation/skeleton_input/name")
local Attributes = import("skate_data/state_graph/attributes").Attributes
local encode = v1.encode
local t1 = {
    Operation = {}
}

function t1.Operation.parse(p1) -- line: 24
    -- upvalues: Attributes (copy)
    local name = Attributes.text(p1, "name")

    if name == "BipedCadence" then
        return "BipedCadence"
    end

    return if name == "MatchCadence" then "MatchCadence" else nil
end

function t1.biped_cadence(p2, p3, p4) -- line: 40
    if p4 ~= 1 or p2 == nil or p3 == nil then
        return p3
    end

    return p2
end

t1.MatchCadence = {}

function t1.MatchCadence.default() -- line: 54
    return {
        captured_phase = 0,
        pending = false
    }
end

function t1.MatchCadence.eq(p5, p6) -- line: 59
    if p5.captured_phase == p6.captured_phase then
        return p5.pending == p6.pending
    end

    return false
end

function t1.MatchCadence.begin(p7, p8, p9) -- line: 65
    if p8 ~= nil and p9 == true then
        p7.pending = true
        p7.captured_phase = p8
    end
end

function t1.MatchCadence.update(p10, p11) -- line: 75
    -- upvalues: encode (copy)
    if p11 ~= nil then
        p11.set_attribute(p11, {
            normalized = false,
            sequence_id = -1,
            name = encode("CadenceStartPercent"),
            value = p10.captured_phase
        })
        p10.pending = false
    end
end

t1.MatchCadence["end"] = function(_) -- line: 88
end

t1.LocoState = {}

function t1.LocoState.eq(p13, p14) -- line: 94
    return p13.expected == p14.expected
end

function t1.LocoState.parse(p15) -- line: 101
    -- upvalues: Attributes (copy)
    local locostate = Attributes.text(p15, "locostate")
    local v2

    if locostate == "Stand" then
        v2 = 0
    elseif locostate == "Walk" then
        v2 = 1
    elseif locostate == "Run" then
        v2 = 2
    elseif locostate == "Sprint" then
        v2 = 3
    else
        local v3 = if locostate == nil then "None" else "Some(\"" .. locostate .. "\")"

        error("Invalid stock LocoState locostate " .. v3, 0)
    end

    return {
        expected = v2
    }
end

function t1.LocoState.evaluate(p16, p17) -- line: 122
    return p17 == p16.expected
end

return t1
