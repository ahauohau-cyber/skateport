-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)
require(sim.import)

local t1 = {
    GroundJump = {}
}

function t1.GroundJump.default() -- line: 18
    return {
        scalar_16 = 0,
        active = false,
        velocity = { 0, 0, 0, 0 }
    }
end

t1.GroundJumpMode = {}
t1.GroundJumpSettings = {}
t1.GroundJumpInput = {}

return t1
