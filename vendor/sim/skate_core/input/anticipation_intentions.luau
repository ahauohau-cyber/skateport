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

local import = require(sim.import)
local v2 = import("skate_core/input/angle")
local v3 = import("skate_core/input/controller")
local left_stick_angle = v2.left_stick_angle
local DerivedControllerInput, magnitude = v3.DerivedControllerInput, v3.magnitude

return {
    produce = function(p2) -- produce | line: 26
        -- upvalues: v1 (copy), left_stick_angle (copy), DerivedControllerInput (copy), magnitude (copy)
        local v4 = DerivedControllerInput.words(p2)

        buffer.writeu32(v1, 0, v4[10])

        local v6 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v4[11])

        local v8 = buffer.readf32(v1, 0)

        if v6 ~= 0 or v8 ~= 0 then
            return {
                {
                    name = "AnticMag",
                    value = magnitude(v6 * v6 + v8 * v8)
                },
                {
                    name = "AnticAngle",
                    value = left_stick_angle(v6, v8)
                }
            }
        end

        return {}
    end
}
