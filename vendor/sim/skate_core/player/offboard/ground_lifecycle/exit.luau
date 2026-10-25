-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)
require(sim.import)

return {
    ExitServices = {},
    exit = function(p1) -- exit | line: 24
        p1.refresh_toolkit_contacts(p1)
        p1.clear_toolkit_exit_fields(p1)

        if p1.ground_geometry_active(p1) then
            p1.release_ground_geometry(p1)
            p1.clear_ground_geometry_active(p1)
        end
    end
}
