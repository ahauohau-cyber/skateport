-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_core/physics/grind_forces/post")

local function wipeout() -- line: 11
    -- upvalues: import (copy)
    return import("skate_game/physics/wipeout")
end

return {
    check = function(p1, p2, p3) -- check | line: 20
        -- upvalues: import (copy), v1 (copy)
        v1.check(p1, p2, import("skate_game/physics/wipeout").Observations.frame(p3))
    end
}
