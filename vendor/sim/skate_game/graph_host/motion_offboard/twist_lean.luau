-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/animation/skeleton_input/name")
local v2 = import("skate_core/player/offboard/twist_lean")
local Attributes = import("skate_data/state_graph/attributes").Attributes
local encode = v1.encode
local State = v2.State
local t1 = {
    Operation = {}
}

function t1.Operation.eq(p1, p2) -- line: 22
    return p1.always == p2.always
end

function t1.Operation.parse(p3) -- line: 28
    -- upvalues: Attributes (copy)
    return {
        always = Attributes.text(p3, "update") == "always"
    }
end

function t1.Operation.execute(p4, p5, p6, p7, p8) -- line: 38
    -- upvalues: encode (copy), State (copy)
    if p8 == 0 then
        State.begin(p5, p6)
    elseif p8 == 1 and p7 ~= nil then
        local v3 = State.update(p5, p4.always, p6)
        local twist, lean = v3.twist, v3.lean

        p7.set_attribute(p7, {
            normalized = false,
            sequence_id = -1,
            name = encode("Twist"),
            value = twist
        })
        p7.set_attribute(p7, {
            normalized = false,
            sequence_id = -1,
            name = encode("Lean"),
            value = lean
        })
    end
end

return t1
