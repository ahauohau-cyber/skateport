-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)
require(sim.import)

return {
    player_suspended = function(p1) -- player_suspended | line: 16
        return next(p1.suspended_by) ~= nil
    end,
    peer_suspended = function(p2, p3) -- peer_suspended | line: 21
        local v1 = p2.skater_remote[p3]

        return v1 ~= nil and v1.suspended == true
    end,
    clear = function(p4) -- clear | line: 28
        table.clear(p4.suspended_by)
        p4.hidden_players = {}
    end
}
