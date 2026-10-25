-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local v1 = require(sim.import)("skate_core/physics/native_arithmetic")

return {
    estimate_reference = function(p1) -- estimate_reference | line: 17
        -- upvalues: v1 (copy)
        return v1.reciprocal_square_root_estimate(p1)
    end,
    estimate = function(p2) -- estimate | line: 25
        return 1 / math.sqrt(p2)
    end
}
