-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local Attributes = require(sim.import)("skate_data/state_graph/attributes").Attributes
local t1 = {
    Condition = {}
}

function t1.Condition.eq(_, _) -- line: 18
    return true
end

function t1.Condition.parse(p3) -- line: 23
    -- upvalues: Attributes (copy)
    return if Attributes.text(p3, "name") == "DisableDismount" then {} else nil
end

function t1.Condition.evaluate(_, p5) -- line: 33
    if p5 == nil then
        error("DisableDismount requires actual Ground80 and Skeleton598", 0)
    end

    if p5.ground_axis_y < 0.6399999856948853 then
        return true
    end

    return p5.skeleton_disables_push_brake
end

return t1
