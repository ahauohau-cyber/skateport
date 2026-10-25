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

local Vector3 = require(sim.import)("skate_core/math").Vector3
local t1 = {
    BodyInput = {},
    ContactInput = {},
    vector = function(p2, p3) -- vector | line: 30
        -- upvalues: v1 (copy), Vector3 (copy)
        local new = Vector3.new

        buffer.writeu32(v1, 0, p2[p3 * 4 + 1])

        local v3 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, p2[p3 * 4 + 1 + 1])

        local v5 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, p2[p3 * 4 + 2 + 1])

        return new(v3, v5, (buffer.readf32(v1, 0)))
    end
}

function t1.ContactInput.decode(p4) -- line: 38
    -- upvalues: v1 (copy), t1 (copy)
    local t2 = {
        positions = {
            t1.vector(p4, 0),
            t1.vector(p4, 1)
        },
        axes = {
            t1.vector(p4, 2),
            t1.vector(p4, 3),
            t1.vector(p4, 4)
        },
        relative_velocity = t1.vector(p4, 5)
    }

    buffer.writeu32(v1, 0, p4[12])
    t2.restitution = buffer.readf32(v1, 0)

    local t3 = {
        center = t1.vector(p4, 6),
        inverse_inertia_full = t1.vector(p4, 8),
        inverse_inertia_split = t1.vector(p4, 10)
    }

    buffer.writeu32(v1, 0, p4[36])
    t3.inverse_mass = buffer.readf32(v1, 0)
    t3.state = p4[44]
    t3.force_acceleration = t1.vector(p4, 12)
    t3.torque_acceleration = t1.vector(p4, 14)
    t3.reaction_id = p4[28]

    local t4 = {
        center = t1.vector(p4, 7),
        inverse_inertia_full = t1.vector(p4, 9),
        inverse_inertia_split = t1.vector(p4, 11)
    }

    buffer.writeu32(v1, 0, p4[40])
    t4.inverse_mass = buffer.readf32(v1, 0)
    t4.state = p4[48]
    t4.force_acceleration = t1.vector(p4, 13)
    t4.torque_acceleration = t1.vector(p4, 15)
    t4.reaction_id = p4[32]
    t2.bodies = { t3, t4 }
    t2.body_ids = {
        p4[4],
        p4[8]
    }
    t2.static_friction_bits = p4[16]
    t2.dynamic_friction_bits = p4[20]
    t2.contact_tag = p4[24]

    return t2
end

return t1
