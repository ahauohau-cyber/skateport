-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local Attributes = require(sim.import)("skate_data/state_graph/attributes").Attributes
local t1 = {
    Operation = {}
}

function t1.Operation.parse(p1) -- line: 19
    -- upvalues: Attributes (copy)
    local name = Attributes.text(p1, "name")

    if name ~= nil then
        if name == "ResetSkaterAnimation" then
            return "SkaterAnimation"
        end

        if name == "ResetToGivenStance" then
            return "GivenStance"
        end
    end

    return nil
end

function t1.Operation.begin(p2, p3) -- line: 38
    if p2 ~= "SkaterAnimation" then
        return p3.reset_to_given_stance(p3)
    end

    p3.clear_action_intents(p3)
    p3.reset_motion_graph_publications(p3)

    return p3.reset_skater_animation_playback(p3)
end

t1.ResetOwners = {}

return t1
