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
    load = function(p2) -- load | line: 23
        -- upvalues: v1 (copy), Collections (copy)
        local function graph(p3) -- line: 24
            -- upvalues: p2 (copy), v1 (copy), Collections (copy)
            local v2 = Collections.words(p2, "physics_animation", "default", p3, 8)
            local t2 = {}

            buffer.writeu32(v1, 0, v2[1])

            local v4 = buffer.readf32(v1, 0)

            buffer.writeu32(v1, 0, v2[2])

            local v6 = buffer.readf32(v1, 0)

            buffer.writeu32(v1, 0, v2[3])

            local v8 = buffer.readf32(v1, 0)

            buffer.writeu32(v1, 0, v2[4])
            t2.x = {
                v4,
                v6,
                v8,
                (buffer.readf32(v1, 0))
            }
            buffer.writeu32(v1, 0, v2[5])

            local v11 = buffer.readf32(v1, 0)

            buffer.writeu32(v1, 0, v2[6])

            local v13 = buffer.readf32(v1, 0)

            buffer.writeu32(v1, 0, v2[7])

            local v15 = buffer.readf32(v1, 0)

            buffer.writeu32(v1, 0, v2[8])
            t2.y = {
                v11,
                v13,
                v15,
                (buffer.readf32(v1, 0))
            }

            return t2
        end

        return {
            twist_spin = graph("LandingSketchyTwistSpin"),
            side_speed = graph("LandingSketchySideSpeed")
        }
    end
}
