-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

return {
    publish = function(p1) -- publish | line: 15
        -- upvalues: rt (copy)
        local pending_wipeout_impulse = p1.grind.pending_wipeout_impulse

        p1.grind.pending_wipeout_impulse = nil

        if pending_wipeout_impulse == nil then
            return
        end

        local physics = p1.player_input.physical.physics

        physics.vector_16 = rt.map(pending_wipeout_impulse, rt.to_bits)
        physics.flag_32 = 1
    end
}
