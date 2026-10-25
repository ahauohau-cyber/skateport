-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local TABLES = import("skate_game/input/gesture_mapping_data").TABLES
local intent_key = import("skate_core/animation/playback_parameters").intent_key
local IntentMap = import("skate_core/graph/intents").IntentMap
local t1 = {
    select = function(p1, p2, p3) -- select | line: 16
        -- upvalues: rt (copy), TABLES (copy), intent_key (copy), IntentMap (copy)
        local v1 = TABLES[p1 + 1]
        local v2 = #v1
        local n1 = 18446744073709552000
        local v3

        for i = v2, 1, -1 do
            local v4 = v1[i]
            local n2 = 0

            for _, v5 in intent_key(v4[1]) do
                n2 = rt.wrapping_add_u32(n2, v5)
            end

            local v6 = rt.irem(n2, 43)

            if v6 < n1 and IntentMap.contains_key(p2, v4[1]) then
                n1 = v6
                v3 = v4
            end
        end

        if v3 == nil then
            return nil
        end

        local v7 = p3 and not IntentMap.contains_key(p2, "DontMirrorTrick")

        if IntentMap.contains_key(p2, "DarkCatch") and v3[4] ~= 0 then
            if not ((v3[4] ~= 2 or v7) and (v3[4] ~= 1 or not v7)) then
                return "Heelflip"
            end

            if not ((v3[4] ~= 3 or not v7) and (v3[4] ~= 4 or v7)) then
                return "N_Heelflip"
            end

            if (v3[4] ~= 3 or v7) and (v3[4] ~= 4 or not v7) then
                return "Kickflip"
            end

            return "N_Kickflip"
        end

        if v7 then
            return v3[3]
        end

        return v3[2]
    end,
    State = {}
}

function t1.State.default() -- line: 59
    return {
        first_update = true,
        selected = nil,
        successor = nil
    }
end

function t1.State.begin(p4, p5, p6, p7, p8, p9) -- line: 68
    -- upvalues: IntentMap (copy), t1 (copy)
    local v8 = t1.select(p5, p7, p9)

    if v8 == nil then
        return
    end

    if p6 ~= nil then
        v8 = p6
    end

    if IntentMap.contains_key(p7, "Underflip") then
        v8 = "U_" .. v8
    end

    if v8 == "Kickflip" then
        p4.successor = "KickflipHold"
    elseif v8 == "Heelflip" then
        p4.successor = "HeelflipHold"
    elseif v8 == "N_Kickflip" then
        p4.successor = "N_KickflipHold"
    elseif v8 == "N_Heelflip" then
        p4.successor = "N_HeelflipHold"
    else
        p4.successor = nil
    end

    p4.selected = v8
    IntentMap.insert(p8, v8, 0)
end

function t1.State.update(p10, p11) -- line: 94
    -- upvalues: IntentMap (copy)
    if not p10.first_update and p10.selected ~= nil and p10.successor ~= nil then
        local selected, successor = p10.selected, p10.successor

        IntentMap.remove(p11, selected)
        IntentMap.insert(p11, successor, 0)
    end

    p10.first_update = false
end

t1.State["end"] = function(p12, p13) -- line: 105
    -- upvalues: IntentMap (copy)
    IntentMap.remove(p13, "DarkCatch")

    if p12.selected == nil then
        return
    end

    local selected = p12.selected

    if p12.successor ~= nil then
        IntentMap.remove(p13, p12.successor)
    end

    IntentMap.remove(p13, selected)
end

return t1
