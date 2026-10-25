-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)
require(sim.import)

return {
    update_post_physics = function(p1, p2) -- update_post_physics | line: 13
        if not p1.reached_apex and p2.board_body_velocity(p2)[2] < 0 then
            p1.reached_apex = true
        end

        p2.check_for_air_wipeout(p2, false)
    end
}
