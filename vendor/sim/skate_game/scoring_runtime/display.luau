-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local ScoringData = require(sim.import)("skate_data/scoring").ScoringData
local t1 = {
    nollie = function(p1) -- nollie | line: 14
        if p1.metadata.score_type ~= 1 and p1.metadata.score_type ~= 2 then
            return false
        end

        return string.sub(p1.identifier, 1, 1) == "n"
    end
}
local nollie = t1.nollie

function t1.compose(p2, p3, p4, p5, p6, p7, p8) -- line: 22
    -- upvalues: ScoringData (copy), nollie (copy)
    local v1 = if p3 == nil then nil else ScoringData.by_id(p2, p3)
    local t2 = {
        p6,
        p7,
        true,
        v1 ~= nil and nollie(v1)
    }
    local v3 = true

    if v1 ~= nil then
        local trick_type = v1.trick_type

        v3 = trick_type == 1
            or trick_type == 2
            or trick_type == 3
            or trick_type == 7
            or trick_type == 10
            or trick_type == 12
            or trick_type == 13
            or trick_type == 4 and v1.metadata.id ~= 60
    end

    if v1 ~= nil and nollie(v1) and v1.variant >= 0 and p6 ~= p7 then
        local v4 = ScoringData.by_id(p2, v1.variant)

        if v4 ~= nil then
            v1 = v4
            t2[1] = p7
            t2[2] = p6
        end
    end

    local v5, v6

    if v3 then
        if p7 then
            local v7 = not p6

            if v7 then
                v5 = v1 ~= nil and nollie(v1)
                v6 = not v5 and p4 ~= 0
            else
                v6 = v7
            end
        else
            v6 = p7
        end
    else
        v6 = v3
    end

    local v8 = if math.abs(p4) == 1 then if p4 > 0 then "ID_TRICK_AUTHENTIC_FS_HALFCAB" else "ID_TRICK_AUTHENTIC_BS_HALFCAB" elseif p4 > 0 then "ID_TRICK_AUTHENTIC_FS_CAB" else "ID_TRICK_AUTHENTIC_BS_CAB"
    local v9 = if v1 ~= nil then v1.label
        elseif v6 then v8
        elseif p4 == 0 then "ID_TRICK_AIR"
        elseif p4 < 0 ~= p6 == not p8 then "ID_TRICK_AIR_BS_SPIN"
        else "ID_TRICK_AIR_FS_SPIN"
    local v10 = p3 == 252 and p5 ~= 0

    if v10 then
        v9 = "ID_TRICK_GRAB_MIRACLE_WHIP"
    end

    if v6 then
        if v1 ~= nil then
            v9 = (v9 .. " ") .. v8
        end

        t2[2] = false
    end

    local v11 = if not v3 or p4 == 0 or v6 and math.abs(p4) == 1 then v9 else v9 .. string.format(" %d", math.abs(p4) * 180)

    if p5 ~= 0 and not v10 then
        v11 = (v11 .. " ") .. (if p5 > 0 then "ID_TRICK_AIR_METRICS_FRONTFLIP" else "ID_TRICK_AIR_METRICS_BACKFLIP")
    end

    return v11, t2
end

return t1
