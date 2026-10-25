-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local Attributes = require(sim.import)("skate_data/state_graph/attributes").Attributes
local t1 = {
    IsPushOffEnabled = {}
}

function t1.IsPushOffEnabled.eq(_, _) -- line: 22
    return true
end

function t1.IsPushOffEnabled.parse(p3) -- line: 27
    -- upvalues: Attributes (copy)
    return if Attributes.text(p3, "name") == "IsPushOffEnabled" then {} else nil
end

function t1.IsPushOffEnabled.evaluate(_) -- line: 35
    return true
end

return t1
