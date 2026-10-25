-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local Attributes = import("skate_data/state_graph/attributes").Attributes
local v1

local function motion_channels() -- line: 19
    -- upvalues: import (copy), v1 (ref)
    local v2 = v1

    if v2 == nil then
        v2 = import("skate_game/graph_host/motion_channels")
        v1 = v2
    end

    return v2
end

local t1 = {
    Operation = {},
    Hand = {}
}

function t1.Operation.eq(p1, p2) -- line: 38
    if p1.tag == p2.tag then
        return p1[1] == p2[1]
    end

    return false
end

function t1.Operation.parse(p3) -- line: 43
    -- upvalues: Attributes (copy), t1 (copy)
    local name = Attributes.text(p3, "name")

    if name ~= nil then
        if name == "HandBusy" then
            local hand = Attributes.text(p3, "hand")

            if hand == nil then
                hand = "bs"
            end

            return {
                tag = "HandBusy",
                (t1.Hand.from_name(hand))
            }
        end

        if name == "MaintainShove" then
            return {
                tag = "MaintainShove"
            }
        end
    end

    return nil
end

function t1.Hand.from_name(p4) -- line: 61
    if p4 == "bs" then
        return "Backside"
    end

    return "Frontside"
end

function t1.Hand.index(p5) -- line: 71
    if p5 == "Backside" then
        return 0
    end

    return 1
end

t1.HandServices = {}

function t1.HandServices.default() -- line: 83
    return {
        keep_shove_channels = false,
        busy_hands = { 0, 0 }
    }
end

function t1.HandServices.execute(p6, p7, p8, p9) -- line: 88
    -- upvalues: import (copy), v1 (ref), t1 (copy)
    local v3 = v1

    if v3 == nil then
        v3 = import("skate_game/graph_host/motion_channels")
        v1 = v3
    end

    local MotionChannels = v3.MotionChannels

    if t1.HandServices.apply(p6, p7, p8) and MotionChannels.has(p9.channels, "SkitchAntic") then
        MotionChannels["end"](p9.channels, "SkitchAntic")
    end
end

function t1.HandServices.apply(p10, p11, p12) -- line: 98
    -- upvalues: rt (copy), t1 (copy)
    if p11.tag == "HandBusy" then
        if p12 == 0 then
            local v4 = t1.Hand.index(p11[1])

            p10.busy_hands[v4 + 1] = rt.wrapping_add_u32(p10.busy_hands[v4 + 1], 1)
        elseif p12 ~= 1 then
            local v5 = t1.Hand.index(p11[1])

            p10.busy_hands[v5 + 1] = rt.wrapping_sub_u32(p10.busy_hands[v5 + 1], 1)
        end
    elseif p12 ~= 0 then
        if p12 ~= 1 then
            p10.keep_shove_channels = false

            return true
        end

        p10.keep_shove_channels = true
    end

    return false
end

return t1
