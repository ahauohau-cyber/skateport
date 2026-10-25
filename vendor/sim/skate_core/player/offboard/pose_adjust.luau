-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

return {
    selected_hand = function(p1) -- selected_hand | line: 14
        if bit32.band(p1, 4) == 0 then
            return 1
        end

        return 0
    end,
    adjustment = function(p2, p3) -- adjustment | line: 20
        -- upvalues: rt (copy)
        local t2 = {
            {
                p3[1][1],
                p3[2][1],
                p3[3][1],
                0
            },
            {
                p3[1][2],
                p3[2][2],
                p3[3][2],
                0
            },
            {
                p3[1][3],
                p3[2][3],
                p3[3][3],
                0
            }
        }
        local v1 = rt.from_fn(4, function(p4) -- line: 28
            -- upvalues: p3 (copy), t2 (copy)
            local v2 = (0 - p3[4][3]) * t2[3][p4 + 1]
            local v3 = (0 - p3[4][2]) * t2[2][p4 + 1] + v2

            return (0 - p3[4][1]) * t2[1][p4 + 1] + v3
        end)

        return rt.from_fn(4, function(p5) -- line: 33
            -- upvalues: p2 (copy), t2 (copy), v1 (copy), rt (copy)
            return rt.from_fn(4, function(p6) -- line: 34
                -- upvalues: p5 (copy), p2 (copy), t2 (copy), v1 (copy)
                if p5 < 3 then
                    local v4 = t2[p5 + 1][1] * p2[1][p6 + 1]
                    local v5 = t2[p5 + 1][2] * p2[2][p6 + 1] + v4

                    return t2[p5 + 1][3] * p2[3][p6 + 1] + v5
                end

                local v6 = v1[1] * p2[1][p6 + 1] + p2[4][p6 + 1]
                local v7 = v1[2] * p2[2][p6 + 1] + v6

                return v1[3] * p2[3][p6 + 1] + v7
            end)
        end)
    end
}
