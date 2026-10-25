-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local v1 = require(sim.import)("skate_core/riding/vector")
local clamp, dot3, normalize = v1.clamp, v1.dot3, v1.normalize

return {
    GroundForceSettings = {},
    GroundForceInput = {},
    calculate = function(p1, p2) -- calculate | line: 40
        -- upvalues: clamp (copy), dot3 (copy), normalize (copy)
        local v2 = clamp(p2.argument_1 / p1.range_1220, 0, 1)
        local v3 = if p2.argument_1 ~= 0 or p2.balance ~= 0 then 1 else 0
        local v4 = p2.surface_speed * 0.125 * p1.speed_scale_1224
        local v5 = (1 - v2) * p1.scale_1228 * v3
        local v6 = -((v4 * v2 + v5) * p2.argument_4)
        local t2 = {
            p2.axis_544[1] * v6 + -p2.axis_384[1] * p2.argument_3,
            p2.axis_544[2] * v6 + -p2.axis_384[2] * p2.argument_3,
            p2.axis_544[3] * v6 + -p2.axis_384[3] * p2.argument_3,
            p2.axis_544[4] * v6 + -p2.axis_384[4] * p2.argument_3
        }
        local v7 = normalize(p2.velocity_400, p1.normal_threshold)
        local v8 = dot3(v7, t2)
        local v9 = table.create(8, 0)

        v9[1] = t2[1] - v7[1] * v8
        v9[2] = t2[2] - v7[2] * v8
        v9[3] = t2[3] - v7[3] * v8
        v9[4] = t2[4] - v7[4] * v8
        v9[7] = p2.application_z

        return v9
    end
}
