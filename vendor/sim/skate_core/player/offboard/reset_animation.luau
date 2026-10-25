-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

return {
    given_stance = function(p1, p2, p3, _) -- given_stance | line: 15
        local v1, v2

        if p1 == 1 and p2 == 0 or p1 == 0 and p2 == 1 then
            v1 = bit32.band(p3, 1073741823)
            v2 = p1 ~= 1
        else
            v1 = bit32.bor(p3, 3221225472)
            v2 = p1 ~= 0
        end

        return 0, v1, v2
    end,
    skater_flags = function(p5, _, _) -- skater_flags | line: 30
        return bit32.band(p5, 267911167), false, 0
    end,
    motion_output = function(p8, _, p10) -- motion_output | line: 41
        for _, v3 in {
                0, 1, 2, 3, 4, 5, 6, 7,
                8, 9, 10, 12, 14, 17
            } do
            p8[v3 + 1] = 0
        end

        p8[12] = bit32.band(p8[12], 2147483647)
        p8[14] = bit32.band(p8[14], 536870911)
        p8[16] = bit32.band(p8[16], 536870911)
        p8[17] = bit32.band(p8[17], 1073741823)
        p8[21] = bit32.bor(bit32.band(p8[21], 33292287), 33554432)
        p10[1] = 0
        p10[2] = 0

        return 37
    end,
    motion_request = function(p11, _) -- motion_request | line: 61
        -- upvalues: rt (copy)
        rt.assign(p11, { 0, 1045220557, 0, 0 })

        return false
    end
}
