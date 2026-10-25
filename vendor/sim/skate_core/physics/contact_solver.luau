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

local function rtl_is_finite(p2) -- line: 11
    if p2 ~= p2 or p2 == 1e999 then
        return false
    end

    return p2 ~= (-1e999)
end

local import = require(sim.import)
local Vector3 = import("skate_core/math").Vector3
local v2 = import("skate_core/physics/contact_layout")

local function solver() -- line: 23
    -- upvalues: import (copy)
    return import("skate_core/physics/solver")
end

local t1 = {
    tu3 = {
        CONTACT_BATCH_BUILD = 2192445640,
        ITERATIVE_CONSTRAINT_SOLVER = 2192451536
    },
    ACTIVE_BODY = 4,
    RetailContactJacobian = {}
}

function t1.RetailContactJacobian.words(p3) -- line: 45
    return p3.words
end

function t1.RetailContactJacobian.accumulated_impulse(p4) -- line: 49
    -- upvalues: t1 (copy)
    return t1.RetailContactJacobian.lanes(p4, 5)
end

function t1.RetailContactJacobian.target_impulse(p5) -- line: 54
    -- upvalues: t1 (copy)
    return t1.RetailContactJacobian.lanes(p5, 6)
end

function t1.RetailContactJacobian.static_friction(p6) -- line: 58
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p6.words[16])

    return (buffer.readf32(v1, 0))
end

function t1.RetailContactJacobian.dynamic_friction(p7) -- line: 62
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p7.words[20])

    return (buffer.readf32(v1, 0))
end

function t1.RetailContactJacobian.angular_response_a(p8) -- line: 66
    -- upvalues: t1 (copy)
    return {
        t1.RetailContactJacobian.xyz(p8, 8),
        t1.RetailContactJacobian.xyz(p8, 11),
        t1.RetailContactJacobian.xyz(p8, 14)
    }
end

function t1.RetailContactJacobian.angular_response_b(p9) -- line: 74
    -- upvalues: t1 (copy)
    return {
        t1.RetailContactJacobian.xyz(p9, 9),
        t1.RetailContactJacobian.xyz(p9, 12),
        t1.RetailContactJacobian.xyz(p9, 15)
    }
end

function t1.RetailContactJacobian.lanes(p10, p11) -- line: 82
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p10.words[p11 * 4 + 0 + 1])

    local v6 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p10.words[p11 * 4 + 1 + 1])

    local v8 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p10.words[p11 * 4 + 2 + 1])

    local v10 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p10.words[p11 * 4 + 3 + 1])

    return {
        v6,
        v8,
        v10,
        (buffer.readf32(v1, 0))
    }
end

function t1.RetailContactJacobian.xyz(p12, p13) -- line: 91
    -- upvalues: Vector3 (copy), t1 (copy)
    local v12 = t1.RetailContactJacobian.lanes(p12, p13)

    return Vector3.new(v12[1], v12[2], v12[3])
end

function t1.build_contact_jacobian(p14, p15) -- line: 100
    -- upvalues: import (copy), v2 (copy)
    if not (p15 == p15 and p15 ~= 1e999 and p15 ~= (-1e999) and p15 > 0) then
        error("assertion failed: time_step.is_finite() && time_step > 0.0", 0)
    end

    local v13 = v2.encode(p14)

    import("skate_core/physics/solver").compile_contact(v13, p15)

    return {
        words = v13,
        reaction_index_a = p14.body_a_workspace.reaction_id,
        reaction_index_b = p14.body_b_workspace.reaction_id
    }
end

function t1.solve_contact_jacobians(p16, p17, p18) -- line: 116
    -- upvalues: import (copy)
    import("skate_core/physics/solver").solve_constraints(p16, {}, {}, p17, p18)
end

function t1.solve_contact_jacobian_iteration(p19, p20) -- line: 120
    -- upvalues: t1 (copy)
    t1.solve_contact_jacobians(p19, p20, 1)
end

return t1
