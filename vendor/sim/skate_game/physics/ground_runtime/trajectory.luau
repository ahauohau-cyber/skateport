-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)
require(sim.import)

local t1 = {
    GroundTrajectoryState = {}
}

function t1.GroundTrajectoryState.cancel(p1) -- line: 27
    p1.pending_request = nil
    p1.result_valid_9840 = false
    p1.primary_valid_288 = false
    p1.secondary_valid_592 = false
    p1.flags_12836 = bit32.band(p1.flags_12836, 63)
end

return t1
