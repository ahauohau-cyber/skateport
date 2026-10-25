-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local normalize = require(sim.import)("skate_core/riding/vector").normalize

return {
    PumpForceInput = {},
    calculate = function(p1) -- calculate | line: 28
        -- upvalues: normalize (copy)
        local v1 = if bit32.band(p1.flags_2476, 2) == 0 then p1.mode_multiplier * p1.pumping_scalar else p1.pumping_scalar
        local v2 = p1.input_scalar_2660 * v1 / p1.timestep
        local v3 = normalize(p1.direction_432, p1.normal_threshold)
        local v4 = table.create(8, 0)

        v4[1] = v3[1] * v2
        v4[2] = v3[2] * v2
        v4[3] = v3[3] * v2
        v4[4] = v3[4] * v2

        return v4
    end
}
