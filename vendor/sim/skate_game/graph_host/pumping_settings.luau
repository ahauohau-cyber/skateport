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
    load = function(p2) -- load | line: 21
        -- upvalues: v1 (copy), Collections (copy)
        local function f(p3) -- line: 22
            -- upvalues: p2 (copy), Collections (copy)
            return Collections.float(p2, "anim_motion", "anim_pump", p3)
        end

        local v2 = Collections.words(p2, "anim_motion", "anim_pump", "pump_amplify", 16)
        local t2 = {}
        local t3 = {}

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
        t3.x = {
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
        t3.y = {
            v19,
            v21,
            v23,
            v25,
            v27,
            v29,
            v31,
            (buffer.readf32(v1, 0))
        }
        t2.amplify = t3
        t2.input_blend = Collections.float(p2, "anim_motion", "anim_pump", "pump_prop_blend")
        t2.maximum_physics_pump = Collections.float(p2, "anim_motion", "anim_pump", "max_phys_pump")
        t2.new_pump_threshold = Collections.float(p2, "anim_motion", "anim_pump", "new_pump_thresh")
        t2.blend_in = Collections.float(p2, "anim_motion", "anim_pump", "pump_blendin")
        t2.blend_out = Collections.float(p2, "anim_motion", "anim_pump", "pump_blendout")

        return t2
    end
}
