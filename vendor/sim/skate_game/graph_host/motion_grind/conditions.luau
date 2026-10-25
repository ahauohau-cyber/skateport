-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local encode = import("skate_core/animation/skeleton_input/name").encode
local eq = import("skate_core/animation/output/attributes").AttributeName.eq
local Attributes = import("skate_data/state_graph/attributes").Attributes
local t1 = {
    Condition = {}
}

function t1.Condition.eq(p1, p2) -- line: 25
    if p1.tag == p2.tag and p1.forwards == p2.forwards then
        return p1.value == p2.value
    end

    return false
end

function t1.Condition.parse(p3) -- line: 30
    -- upvalues: encode (copy), eq (copy), Attributes (copy)
    local name = Attributes.text(p3, "name")

    if name == "IsGrindBluntingBackslash" then
        return {
            tag = "BluntingBackslash"
        }
    end

    if name == "IsGrindApproach" then
        local Facing = Attributes.text(p3, "Facing")

        if Facing == nil then
            Facing = "F"
        end

        return {
            tag = "Approach",
            forwards = eq(encode(Facing), encode("F"))
        }
    end

    if name == "GrindTrickOutTypeAllowed" then
        local type = Attributes.text(p3, "type")
        local v1

        if type == "normal" then
            v1 = 0
        elseif type == "left" then
            v1 = 1
        elseif type == "right" then
            v1 = 2
        else
            local v2 = if type == nil then "None" else ("Some(%*)"):format((string.format("%q", type)))

            error(("Invalid GrindTrickOutTypeAllowed type: %*"):format(v2), 0)
        end

        return {
            tag = "TrickOutType",
            value = v1
        }
    end

    if name == "IsLandingIntoGrind" then
        return {
            tag = "LandingIntoGrind"
        }
    end

    return if name == "IsDroppingIn" then {
        tag = "DroppingIn"
    } else nil
end

function t1.Condition.evaluate(p4, p5) -- line: 65
    if p4.tag == "BluntingBackslash" then
        return p5.blunting_136 == 4
    end

    if p4.tag == "Approach" then
        local filtered_grinding_80 = p5.filtered_grinding_80

        if not filtered_grinding_80 then
            return filtered_grinding_80
        end

        return p5.approach_268 == (if p4.forwards then 1 else 0)
    end

    if p4.tag == "TrickOutType" then
        return p5.trick_out_240 == p4.value
    end

    if p4.tag ~= "LandingIntoGrind" then
        return p5.dropping_in_324
    end

    return p5.air_grind_443 and p5.air_time_184 < 0.2
end

t1.Physical = {}

return t1
