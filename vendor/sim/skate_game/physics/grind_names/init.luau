-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/physics/grind_names/table0")
local v2 = import("skate_game/physics/grind_names/table1")
local v3 = import("skate_game/physics/grind_names/table2")
local v4 = import("skate_game/physics/grind_names/table3")
local v5 = import("skate_game/physics/grind_names/table4")
local v6 = import("skate_game/physics/grind_names/table5")
local v7 = import("skate_game/physics/grind_names/table6")
local v8 = import("skate_game/physics/grind_names/table7")
local t1 = {
    Name = {}
}

function t1.Name.eq(p1, p2) -- line: 27
    if p1.skating_id == p2.skating_id and p1.attribute == p2.attribute and p1.display == p2.display then
        return p1.scorable_id == p2.scorable_id
    end

    return false
end

local t2 = { 2, 2, 2, 2, 4, 6 }

function t1.lookup(p3) -- line: 39
    -- upvalues: rt (copy), v1 (copy), v2 (copy), v3 (copy), v4 (copy), v5 (copy), v6 (copy), v7 (copy), v8 (copy), t2 (copy)
    if p3[1] >= t2[1]
        or p3[2] >= t2[2]
        or p3[3] >= t2[3]
        or p3[4] >= t2[4]
        or p3[5] >= t2[5]
        or p3[6] >= t2[6] then
        return nil
    end

    local v9 = ((((p3[1] * 2 + p3[2]) * 2 + p3[3]) * 2 + p3[4]) * 4 + p3[5]) * 6 + p3[6]
    local v10 = rt.idiv(v9, 48)
    local TABLE = if v10 == 0 then v1.TABLE
        elseif v10 == 1 then v2.TABLE
        elseif v10 == 2 then v3.TABLE
        elseif v10 == 3 then v4.TABLE
        elseif v10 == 4 then v5.TABLE
        elseif v10 == 5 then v6.TABLE
        elseif v10 == 6 then v7.TABLE
        else v8.TABLE

    return rt.copy(TABLE[rt.irem(v9, 48) + 1])
end

return t1
