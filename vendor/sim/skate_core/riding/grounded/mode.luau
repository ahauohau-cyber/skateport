-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

local t1 = {
    ProcessedMode = {}
}

function t1.ProcessedMode.update(p1, p2, p3) -- line: 21
    -- upvalues: rt (copy)
    if p2 <= 4 then
        p1.selected_attributes = rt.copy(p3[p2 + 1])
    end

    p1.requested_mode = p2
end

return t1
