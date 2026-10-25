-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)
require(sim.import)

return {
    compile_active = function(p1, p2, p3) -- compile_active | line: 18
        local t1 = {}

        for _, v1 in ipairs(p1) do
            local v2 = p2(v1)

            if bit32.band(bit32.bor(v2[1], v2[2]), 4) ~= 0 then
                t1[#t1 + 1] = p3(v1)
            end
        end

        return t1
    end
}
