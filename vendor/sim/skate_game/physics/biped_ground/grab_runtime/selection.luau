-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local best_spline = require(sim.import)("skate_core/player/offboard/grab_scene").best_spline

return {
    best = function(p1, p2) -- best | line: 14
        -- upvalues: best_spline (copy)
        return best_spline(p1, p2)
    end
}
