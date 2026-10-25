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

local DerivedControllerInput = require(sim.import)("skate_core/input/controller").DerivedControllerInput

return {
    produce = function(p2) -- produce | line: 23
        -- upvalues: v1 (copy), DerivedControllerInput (copy)
        local v3 = DerivedControllerInput.words(p2)

        buffer.writeu32(v1, 0, v3[8])

        local v5 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v3[10])

        local v7 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v3[11])

        local v9 = buffer.readf32(v1, 0)
        local v10 = v5 + v7

        if -1 - v10 >= 0 then
            v10 = -1
        end

        if not (1 - v10 >= 0) then
            v10 = 1
        end

        local t2 = {}

        for _, v11 in {
                { "GrindBalanceX", -v5 },
                { "PhysGrindTranslation", v10 },
                { "PhysGrindStabilityNudge", v5 },
                { "PhysGrindUpDown", v9 }
            } do
            local v12 = v11[1]
            local v13 = v11[2]

            if v13 ~= 0 then
                table.insert(t2, {
                    name = v12,
                    value = v13
                })
            end
        end

        return t2
    end
}
