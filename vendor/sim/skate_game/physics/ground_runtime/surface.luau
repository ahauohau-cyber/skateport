-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime
local choose_surface = import("skate_core/physics/contact_feedback").choose_surface

return {
    active_surface = function(p1, p2) -- active_surface | line: 18
        -- upvalues: rt (copy), BoardRuntime (copy), choose_surface (copy)
        local t2 = {
            p1.ground.parts[1].in_contact,
            p1.ground.parts[2].in_contact,
            p1.ground.parts[3].in_contact,
            p1.ground.parts[4].in_contact
        }
        local v1 = BoardRuntime.contact_reports(p2)
        local v3 = false

        for i = 1, #v1 do
            if bit32.band(v1[i].other_surface, 3968) == 1536 then
                v3 = true
                break
            end
        end

        return choose_surface(rt.copy(p1.wheel_lines.physics_surfaces), t2, v3)
    end,
    surface_key = function(p3) -- surface_key | line: 40
        if p3 == 1 then
            return "smooth"
        end

        if p3 == 2 then
            return "rough"
        end

        if p3 == 3 then
            return "slow"
        end

        if p3 == 4 then
            return "slippery"
        end

        if p3 == 5 then
            return "veryslow"
        end

        error(string.format("Processed surface mode %d was not normalized by SurfacePhysics", p3), 0)
    end
}
