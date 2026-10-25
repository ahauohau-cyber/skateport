-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_from_bits(p1) -- line: 7
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p1)

    return (buffer.readf32(v1, 0))
end

local Collections = require(sim.import)("skate_data/collections").Collections

return {
    settings = function(p2) -- settings | line: 23
        -- upvalues: rt (copy), v1 (copy), Collections (copy)
        local function f(p3) -- line: 24
            -- upvalues: p2 (copy), Collections (copy)
            return Collections.float(p2, "physics_reckoning", "default", p3)
        end

        local v2 = rt.map(Collections.words(p2, "physics_reckoning", "default", "DynamicSpeedMaxDeltaGraphZ", 16), function(p4) -- line: 29
            -- upvalues: v1 (copy)
            buffer.writeu32(v1, 0, p4)

            return (buffer.readf32(v1, 0))
        end)

        return {
            speed_damping = Collections.float(p2, "physics_reckoning", "default", "DynamicSpeedDamping"),
            up_vector_damping = Collections.float(p2, "physics_reckoning", "default", "DynamicUpVectorDamping"),
            maximum_delta = Collections.float(p2, "physics_reckoning", "default", "DynamicSpeedMaxDelta"),
            speed_scale = Collections.float(p2, "physics_reckoning", "default", "DynamicSpeedMaxDeltaXScale"),
            maximum_delta_vs_speed = {
                x = rt.slice(v2, 0, 8),
                y = rt.slice(v2, 8, 16)
            }
        }
    end
}
