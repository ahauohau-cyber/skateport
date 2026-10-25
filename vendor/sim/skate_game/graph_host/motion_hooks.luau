-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local Attributes = import("skate_data/state_graph/attributes").Attributes
local v1

local function motion_nodes() -- line: 16
    -- upvalues: import (copy), v1 (ref)
    local v2 = v1

    if v2 == nil then
        v2 = import("skate_game/graph_host/motion_nodes")
        v1 = v2
    end

    return v2
end

local t1 = {
    MotionHook = {}
}

function t1.MotionHook.parse(p1) -- line: 37
    -- upvalues: import (copy), Attributes (copy), v1 (ref)
    local name = Attributes.text(p1, "name")

    if name == nil then
        return nil
    end

    if name == "GrabSlide" then
        return {
            tag = "GrabSlide",
            right = Attributes.boolean_byte(p1, "right", 1) ~= 0
        }
    end

    if name == "OverideNextAnimTransitionHook" then
        local v3 = v1

        if v3 == nil then
            v3 = import("skate_game/graph_host/motion_nodes")
            v1 = v3
        end

        return {
            tag = "Override",
            (v3.transition(p1))
        }
    end

    if name ~= "MongoPushToAntic" then
        return nil
    end

    local anim = Attributes.text(p1, "anim")

    if anim == nil then
        anim = ""
    end

    return {
        tag = "MongoPushToAntic",
        animation = anim
    }
end

return t1
