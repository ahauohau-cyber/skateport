-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local encode = import("skate_core/animation/skeleton_input/name").encode
local Attributes = import("skate_data/state_graph/attributes").Attributes
local t1 = {
    Operation = {}
}

function t1.Operation.parse(p1) -- line: 20
    -- upvalues: encode (copy), Attributes (copy)
    local trick = Attributes.text(p1, "trick")

    if trick == nil then
        error("ScoringTrick requires authored trick", 0)
    end

    return {
        trick = encode(trick)
    }
end

function t1.Operation.execute(p2, p3, p4, p5) -- line: 31
    -- upvalues: rt (copy)
    if p5 ~= 1 then
        return p4
    end

    local v1 = bit32.bor(p4, 16777216)

    p3.first = rt.copy(p2.trick)
    p3.second = rt.copy(p2.trick)

    return v1
end

t1.Names = {}

function t1.Names.default() -- line: 49
    return {
        first = nil,
        second = nil
    }
end

return t1
