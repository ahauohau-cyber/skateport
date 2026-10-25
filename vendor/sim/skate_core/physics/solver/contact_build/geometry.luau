-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local Vector3 = require(sim.import)("skate_core/math").Vector3
local t1 = {
    components = function(p1) -- components | line: 16
        return {
            p1.x,
            p1.y,
            p1.z
        }
    end
}

function t1.difference(p2, p3) -- line: 20
    -- upvalues: Vector3 (copy)
    return Vector3.new(p2.x - p3.x, p2.y - p3.y, p2.z - p3.z)
end

function t1.cross(p4, p5) -- line: 24
    return {
        -p4.z * p5.y + (p4.y * p5.z + 0),
        -p4.x * p5.z + (p4.z * p5.x + 0),
        -p4.y * p5.x + (p4.x * p5.y + 0)
    }
end

function t1.inertia_response(p6, p7, p8, p9) -- line: 32
    -- upvalues: rt (copy)
    local t2 = {
        {
            p6.x,
            p6.y,
            p6.z,
            p8
        },
        {
            p6.y,
            p7.y,
            p7.z,
            p8
        },
        {
            p6.z,
            p7.z,
            p7.x,
            p8
        }
    }

    return rt.from_fn(4, function(p10) -- line: 38
        -- upvalues: p9 (copy), t2 (copy)
        local v1 = t2[1][p10 + 1] * p9[1] + 0
        local v2 = t2[2][p10 + 1] * p9[2] + v1

        return t2[3][p10 + 1] * p9[3] + v2
    end)
end

function t1.project(p11, p12) -- line: 45
    local t3 = {}

    for v3, v4 in ipairs(p11) do
        local v5 = v4.x * p12.x + 0
        local v6 = v4.y * p12.y + v5

        t3[v3] = v4.z * p12.z + v6
    end

    return t3
end

function t1.prepare(p13, p14) -- line: 56
    -- upvalues: rt (copy), Vector3 (copy), t1 (copy)
    local t4 = {
        t1.difference(p13.positions[1], p13.bodies[1].center),
        t1.difference(p13.positions[2], p13.bodies[2].center)
    }
    local t5 = {}

    for v7, v8 in ipairs(p13.bodies) do
        t5[v7] = bit32.band(v8.state, 4) == 4
    end

    local v9 = rt.from_fn(2, function(p15) -- line: 65
        -- upvalues: p13 (copy), t5 (copy)
        if t5[p15 + 1] then
            return p13.bodies[p15 + 1].inverse_mass
        end

        return 0
    end)
    local t6 = {}

    for v10, v11 in ipairs(t4) do
        local t7 = {}

        for v12, v13 in ipairs(p13.axes) do
            t7[v12] = t1.cross(v11, v13)
        end

        t6[v10] = t7
    end

    local v14 = rt.from_fn(2, function(p16) -- line: 82
        -- upvalues: p13 (copy), t5 (copy), v9 (copy), t6 (copy), rt (copy), Vector3 (copy), t1 (copy)
        local v15, v16

        if t5[p16 + 1] then
            v15 = p13.bodies[p16 + 1].inverse_inertia_full
            v16 = p13.bodies[p16 + 1].inverse_inertia_split
        else
            v15 = rt.copy(Vector3.ZERO)
            v16 = rt.copy(Vector3.ZERO)
        end

        local t8 = {}

        for v17, v18 in ipairs(t6[p16 + 1]) do
            t8[v17] = t1.inertia_response(v15, v16, v9[p16 + 1], v18)
        end

        return t8
    end)
    local v19 = rt.from_fn(3, function(p17) -- line: 96
        -- upvalues: v9 (copy), t6 (copy), v14 (copy), rt (copy)
        local v20 = rt.from_fn(3, function(p18) -- line: 97
            -- upvalues: p17 (copy), t6 (copy), v14 (copy)
            local v21 = t6[1][p17 + 1][p18 + 1] * v14[1][p17 + 1][p18 + 1] + 0

            return t6[2][p17 + 1][p18 + 1] * v14[2][p17 + 1][p18 + 1] + v21
        end)

        return v20[3] + (v20[1] + v9[1]) + (v20[2] + v9[2])
    end)
    local v22 = rt.from_fn(2, function(p19) -- line: 103
        -- upvalues: p13 (copy), t4 (copy), t5 (copy), rt (copy), Vector3 (copy)
        if not t5[p19 + 1] then
            return rt.copy(Vector3.ZERO)
        end

        local v23 = t4[p19 + 1]
        local force_acceleration, torque_acceleration = p13.bodies[p19 + 1].force_acceleration, p13.bodies[p19 + 1].torque_acceleration

        return Vector3.new(v23.z * torque_acceleration.y + (-v23.y * torque_acceleration.z + force_acceleration.x), v23.x * torque_acceleration.z + (-v23.z * torque_acceleration.x + force_acceleration.y), v23.y * torque_acceleration.x + (-v23.x * torque_acceleration.y + force_acceleration.z))
    end)
    local v24 = t1.difference(p13.positions[2], p13.positions[1])
    local v25 = t1.difference(v22[2], v22[1])
    local t9 = {}

    for v26, v27 in ipairs(t1.components(p13.relative_velocity)) do
        t9[v26] = p14 * v27 + 0
    end

    local t10 = {}

    for v28, v29 in ipairs(t1.components(v25)) do
        t10[v28] = v29 * (p14 * p14) + 0
    end

    local t11 = {
        t9[1] + (t1.components(v24)[1] + t10[1]),
        t9[2] + (t1.components(v24)[2] + t10[2]),
        t9[3] + (t1.components(v24)[3] + t10[3])
    }
    local t12 = {}

    for v30, v31 in ipairs(t9) do
        t12[v30] = -v31 * p13.restitution + 0
    end

    local t13 = {}

    for v32, v33 in ipairs(p13.bodies) do
        t13[v32] = v33.reaction_id
    end

    return {
        arms = t4,
        axes = rt.copy(p13.axes),
        active = t5,
        inverse_mass = v9,
        point_acceleration = v22,
        angular_response_a = rt.copy(v14[1]),
        angular_response_b = rt.copy(v14[2]),
        effective_mass = v19,
        separation_projection = t1.project(p13.axes, v24),
        restitution_projection = t1.project(p13.axes, Vector3.new(t12[1], t12[2], t12[3])),
        predicted_separation_projection = t1.project(p13.axes, Vector3.new(t11[1], t11[2], t11[3])),
        reaction_ids = t13,
        body_ids = rt.copy(p13.body_ids),
        static_friction_bits = p13.static_friction_bits,
        dynamic_friction_bits = p13.dynamic_friction_bits,
        contact_tag = p13.contact_tag,
        combined_state_bit_8 = bit32.band(bit32.bor(p13.bodies[1].state, p13.bodies[2].state), 8)
    }
end

return t1
