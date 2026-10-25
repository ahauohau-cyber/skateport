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

local Collections = require(sim.import)("skate_data/collections").Collections

return {
    settings = function(p2) -- settings | line: 21
        -- upvalues: v1 (copy), Collections (copy)
        local v2 = Collections.words(p2, "anim_motion", "manual", "manual_balance", 16)
        local t2 = {}

        buffer.writeu32(v1, 0, v2[1])

        local v4 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v2[2])

        local v6 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v2[3])

        local v8 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v2[4])

        local v10 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v2[5])

        local v12 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v2[6])

        local v14 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v2[7])

        local v16 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v2[8])
        t2.x = {
            v4,
            v6,
            v8,
            v10,
            v12,
            v14,
            v16,
            (buffer.readf32(v1, 0))
        }
        buffer.writeu32(v1, 0, v2[9])

        local v19 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v2[10])

        local v21 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v2[11])

        local v23 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v2[12])

        local v25 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v2[13])

        local v27 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v2[14])

        local v29 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v2[15])

        local v31 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v2[16])
        t2.y = {
            v19,
            v21,
            v23,
            v25,
            v27,
            v29,
            v31,
            (buffer.readf32(v1, 0))
        }

        return {
            balance = t2,
            velocity_limit = Collections.float(p2, "anim_motion", "manual", "manual_clamp_vel"),
            acceleration_limit = Collections.float(p2, "anim_motion", "manual", "manual_clamp_acc")
        }
    end
}
