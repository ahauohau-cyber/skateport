-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = require(sim.import)("skate_core/physics/grind_forces")
local dot3, scale, sub = v1.dot3, v1.scale, v1.sub

return {
    Input = {},
    force = function(p1) -- force | line: 24
        -- upvalues: rt (copy), dot3 (copy), scale (copy), sub (copy)
        local v2 = if p1.force_across or p1.geometry_kind == 0 then scale(p1.across, if dot3(p1.across, sub(p1.position, p1.point)) > 0 then 1 else -1) else scale(p1.high_side, -1)

        if not (dot3(p1.velocity, v2) < p1.speed_limit) then
            return nil
        end

        local v4 = scale(v2, p1.strength)

        if not p1.enable_lift then
            return v4
        end

        local v5 = rt.fmax(p1.normal[2], 0) * p1.lift
        local v6 = table.create(4)

        v6[1] = p1.normal[1] * v5 + v4[1]
        v6[2] = p1.normal[2] * v5 + v4[2]
        v6[3] = p1.normal[3] * v5 + v4[3]
        v6[4] = p1.normal[4] * v5 + v4[4]

        return v6
    end
}
