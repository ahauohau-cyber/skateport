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

require(sim.import)("skate_core/physics/native_arithmetic")

return {
    vector = function(p2, p3) -- vector | line: 21
        -- upvalues: v1 (copy)
        buffer.writeu32(v1, 0, p2[p3 + 1])

        local v3 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, p2[p3 + 2])

        local v5 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, p2[p3 + 3])

        return {
            v3,
            v5,
            (buffer.readf32(v1, 0))
        }
    end,
    sub = function(p4, p5) -- sub | line: 29
        return {
            p4[1] - p5[1],
            p4[2] - p5[2],
            p4[3] - p5[3]
        }
    end,
    dot = function(p6, p7) -- dot | line: 33
        return p6[1] * p7[1] + p6[2] * p7[2] + p6[3] * p7[3]
    end,
    cross = function(p8, p9) -- cross | line: 37
        return {
            -p8[3] * p9[2] + p8[2] * p9[3],
            -p8[1] * p9[3] + p8[3] * p9[1],
            -p8[2] * p9[1] + p8[1] * p9[2]
        }
    end,
    scale = function(p10, p11) -- scale | line: 45
        return {
            p10[1] * p11,
            p10[2] * p11,
            p10[3] * p11
        }
    end
}
