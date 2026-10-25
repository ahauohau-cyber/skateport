-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local DerivedControllerInput = require(sim.import)("skate_core/input/controller").DerivedControllerInput

return {
    produce = function(p1) -- produce | line: 16
        -- upvalues: DerivedControllerInput (copy)
        local v2 = DerivedControllerInput.words(p1)
        local v3 = v2[7]
        local v4 = v2[14]

        if bit32.band(v4, 805306368) ~= 0 then
            return {}
        end

        local t2 = {
            { 26, "GestureDownStart", "GestureDownHeld" },
            { 25, "GestureLeftStart", "GestureLeftHeld" },
            { 24, "GestureRightStart", "GestureRightHeld" },
            { 27, "GestureUpStart", "GestureUpHeld" }
        }
        local t3 = {}

        for _, v5 in t2 do
            local v6 = v5[1]
            local v7 = v5[2]

            if bit32.band(v4, (bit32.lshift(1, v6))) ~= 0 and bit32.band(v3, (bit32.lshift(1, v6))) == 0 then
                table.insert(t3, {
                    value = 1,
                    name = v7
                })
            end
        end

        for _, v10 in t2 do
            local v11 = v10[1]
            local v12 = v10[3]

            if bit32.band(v4, (bit32.lshift(1, v11))) ~= 0 then
                table.insert(t3, {
                    value = 1,
                    name = v12
                })
            end
        end

        return t3
    end
}
