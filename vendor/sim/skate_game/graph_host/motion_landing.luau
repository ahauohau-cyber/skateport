-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_from_bits(p1) -- line: 7
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p1)

    return (buffer.readf32(v1, 0))
end

local Attributes = require(sim.import)("skate_data/state_graph/attributes").Attributes
local t1 = {
    Operation = {}
}

function t1.Operation.parse(p2) -- line: 27
    -- upvalues: rt (copy), v1 (copy), Attributes (copy)
    local name = Attributes.text(p2, "name")

    if name == nil then
        return nil
    end

    if name == "IsAnticipating" then
        return {
            tag = "IsAnticipating"
        }
    end

    if name == "IsLanding" then
        return {
            tag = "IsLanding"
        }
    end

    if name == "IsManualing" then
        return {
            tag = "IsManualing"
        }
    end

    if name == "IsDoingTrick" then
        return {
            tag = "IsDoingTrick"
        }
    end

    if name == "SetLandingData" then
        return {
            tag = "SetLandingData"
        }
    end

    if name == "DisableTricks" then
        local length = Attributes.get(p2, "length")
        local t2 = {
            tag = "DisableTricks"
        }

        if length ~= nil then
            buffer.writeu32(v1, 0, length.float_bits)
            t2.length = buffer.readf32(v1, 0)
        else
            t2.length = 0.5
        end

        return t2
    end

    if name ~= "ChooseRandomLanding" then
        return nil
    end

    local numlandings = Attributes.get(p2, "numlandings")
    local t3 = {
        tag = "ChooseRandomLanding"
    }
    local f_to_i32 = rt.f_to_i32
    local v2 = 1

    if numlandings ~= nil then
        buffer.writeu32(v1, 0, numlandings.float_bits)
        v2 = buffer.readf32(v1, 0)
    end

    t3.count = f_to_i32(v2)

    return t3
end

t1.Condition = {}

function t1.Condition.eq(p3, p4) -- line: 63
    if p3.tag == p4.tag then
        return p3[1] == p4[1]
    end

    return false
end

function t1.Condition.parse(p5) -- line: 68
    -- upvalues: Attributes (copy)
    local name = Attributes.text(p5, "name")

    if name ~= nil then
        if name == "HasLandingType" then
            local landingType = Attributes.text(p5, "landingType")

            if landingType == nil then
                landingType = "straight"
            end

            return {
                tag = "HasLandingType",
                if landingType == "spin" then 2 elseif landingType == "sketchy" then 1 else 0
            }
        end

        if name == "HasTiltToLargeForPreland" then
            return {
                tag = "HasTiltToLargeForPreland"
            }
        end

        if name == "AllowedToTrick" then
            return {
                tag = "AllowedToTrick"
            }
        end
    end

    return nil
end

function t1.Condition.evaluate(p6, p7, p8, p9) -- line: 97
    if p6.tag == "HasLandingType" then
        if p7 == nil then
            error("HasLandingType requires Animation96", 0)
        end

        return p7.kind == p6[1]
    end

    if p6.tag ~= "HasTiltToLargeForPreland" then
        return p8.tricks_allowed
    end

    if p9 == nil then
        error("HasTiltToLargeForPreland requires original prelanding output", 0)
    end

    return p9
end

t1.Flags = {}

function t1.Flags.default() -- line: 118
    return {
        anticipating = false,
        landing = false,
        manualing = false,
        doing_trick = false,
        tricks_allowed = true
    }
end

t1.Physical = {}
t1.State = {}

function t1.State.default() -- line: 137
    return {
        value = 0,
        complete = false
    }
end

return t1
