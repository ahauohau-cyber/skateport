-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local v1 = require(sim.import)("skate_core/physics/grind_forces")
local dot3, scale, sub = v1.dot3, v1.scale, v1.sub

return {
    Slide = {},
    Input = {},
    control = function(p1, p2) -- control | line: 31
        -- upvalues: dot3 (copy), scale (copy), sub (copy)
        local position, point, direction, across = p2.position, p2.point, p2.direction, p2.across
        local velocity, translation_2796, total_mass_2660, update_frequency = p2.velocity, p2.translation_2796, p2.total_mass_2660, p2.update_frequency
        local preparing_jump, geometry_kind = p2.preparing_jump, p2.geometry_kind
        local v2 = dot3(sub(position, point), across)
        local v4 = scale(across, if v2 > 0 then -1 else 1)

        if preparing_jump then
            if math.abs(v2) > 0.12 then
                return { scale(v4, 201) }
            end

            return {}
        end

        local v6 = scale(across, translation_2796 * (if p1 == "Boardslide" then 25 else (1 - math.abs(v2) * 6.25) * 40))

        if geometry_kind == 2 then
            return { v6 }
        end

        local v7 = sub(velocity, scale(direction, dot3(velocity, direction)))

        if math.abs(v2) > 0.16 then
            local t2 = { scale(v4, 10) }

            if dot3(v4, v7) < 0 then
                local v8 = scale(v7, -(total_mass_2660 * update_frequency))

                v8[2] = 0
                table.insert(t2, v8)
            end

            return t2
        end

        local v9 = scale(v7, -20)

        v9[2] = 0

        return { v6, v9 }
    end
}
