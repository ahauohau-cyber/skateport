-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)
require(sim.import)

local t1 = {
    ConditionerCapabilityContext = {}
}

function t1.ConditionerCapabilityContext.capabilities(p1) -- line: 27
    if p1.in_front_end then
        return 0
    end

    if p1.challenge_query_active and p1.challenge_configuration_enabled then
        return 4294967287
    end

    if not p1.hall_of_meat_enabled or p1.challenge_query_active then
        return 448
    end

    return 4294965239
end

return t1
