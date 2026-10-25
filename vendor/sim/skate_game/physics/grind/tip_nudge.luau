-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local dot3 = import("skate_game/physics/grind/arithmetic").dot3
local apply_world_force = import("skate_game/physics/grind/board").apply_world_force
local v1 = import("skate_core/trigonometry")

return {
    apply = function(p1, p2, p3, p4) -- apply | line: 20
        -- upvalues: rt (copy), dot3 (copy), apply_world_force (copy), v1 (copy)
        local t2 = {
            p2[1] - p3[1],
            p2[2] - p3[2],
            p2[3] - p3[3],
            p2[4] - p3[4]
        }
        local v2 = rt.map(p4, function(p5) -- line: 27
            -- upvalues: p4 (copy), t2 (copy), dot3 (copy)
            if dot3(p4, t2) > 0 then
                return -p5
            end

            return p5
        end)
        local v3, v4 = v1.sin_cos(0.7853981573134661)
        local v5 = rt.map(v2, function(p6) -- line: 38
            -- upvalues: v4 (copy)
            return p6 * 100 * v4
        end)

        v5[2] -= v3
        apply_world_force(p1, v5, p2)
    end
}
