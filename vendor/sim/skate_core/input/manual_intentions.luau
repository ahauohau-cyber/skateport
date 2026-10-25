-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local v1 = buffer.create(8)

local function rtl_from_bits(p1) -- line: 7
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p1)

    return (buffer.readf32(v1, 0))
end

local v2 = require(sim.import)("skate_core/input/controller")
local DerivedControllerInput, magnitude = v2.DerivedControllerInput, v2.magnitude

return {
    produce = function(p2, p3) -- produce | line: 25
        -- upvalues: v1 (copy), DerivedControllerInput (copy), magnitude (copy)
        local t2 = {}

        if bit32.band(p3, 512) == 0 then
            local v3 = DerivedControllerInput.words(p2)

            buffer.writeu32(v1, 0, v3[10])

            local v5 = buffer.readf32(v1, 0)

            buffer.writeu32(v1, 0, v3[11])

            local v7 = buffer.readf32(v1, 0)
            local v8 = magnitude(v5 * v5 + v7 * v7)

            if v7 ~= 0 then
                table.insert(t2, {
                    name = "Manual",
                    value = if v7 > 0 then v8 else -v8
                })
            end

            if v8 > 0.8999999761581421 then
                local v9 = (v8 - 0.8999999761581421) * 9.999998092651367

                table.insert(t2, {
                    name = "ManualBrake",
                    value = if v7 > 0 then v9 else -v9
                })
            end
        end

        return t2
    end
}
