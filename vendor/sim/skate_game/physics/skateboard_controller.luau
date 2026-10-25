-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local t1 = {
    SkateboardController = require(sim.import)("skate_core/physics/skateboard_controller").SkateboardController
}

function t1.partial_request(p1, p2) -- line: 17
    -- upvalues: t1 (copy)
    return t1.SkateboardController.request_partial_ragdoll(p1, p2.part_contact_count)
end

return t1
