-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local Vector3 = import("skate_core/math").Vector3
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime
local v1 = import("skate_core/physics/grind_forces/launch")

return {
    apply = function(p1, p2, p3, p4) -- apply | line: 18
        -- upvalues: rt (copy), Vector3 (copy), BoardRuntime (copy), v1 (copy)
        local v2 = v1.launch(rt.copy(p2), p4)
        local velocity = v2.velocity
        local v3 = BoardRuntime.bodies_mut(p1)

        for i = 1, #v3 do
            v3[i].rates.linear_velocity = Vector3.new(velocity[1], velocity[2], velocity[3])
        end

        rt.assign(p2, v2.jumper)

        return velocity, (bit32.bor(p3, v2.flags_2476_to_or))
    end
}
