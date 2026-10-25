-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)
require(sim.import)

local t1 = {
    PostOutputServices = {},
    PlayerOutputField1392 = {}
}

function t1.PlayerOutputField1392.default() -- line: 24
    return {}
end

function t1.run_post_output(p1, p2) -- line: 29
    p2.finish_player_output_82909510(p2, p1)
    p2.finish_skeleton_output_82be2ba8(p2)
end

return t1
