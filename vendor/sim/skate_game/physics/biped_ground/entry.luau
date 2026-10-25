-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

return {
    effective_root = function(p1, p2) -- effective_root | line: 16
        -- upvalues: rt (copy)
        if bit32.band(p2, 4) == 0 then
            return p1
        end

        for _, v1 in ipairs({ 0, 2 }) do
            p1[v1 + 1] = rt.map(p1[v1 + 1], function(p3) -- line: 19
                return p3 * -1
            end)
        end

        return p1
    end
}
