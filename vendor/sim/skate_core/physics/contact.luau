-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_subnormal_mantissa(p1) -- line: 7
    local v2 = p1 * 7.1362384635298E+44
    local v3 = math.floor(v2)
    local v4 = v2 - v3

    if v4 > 0.5 or v4 == 0.5 and v3 % 2 == 1 then
        return v3 + 1
    end

    return v3
end

local function rtl_to_bits(p2) -- line: 16
    -- upvalues: v1 (copy)
    if p2 ~= 0 and p2 > -1.1754943508222875E-38 and p2 < 1.1754943508222875E-38 then
        local v6 = math.abs(p2) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        if p2 < 0 then
            return v5 + 2147483648
        end

        return v5
    end

    buffer.writef32(v1, 0, p2)

    return (buffer.readu32(v1, 0))
end

local function rtl_from_bits(p3) -- line: 24
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p3)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local Vector3 = import("skate_core/math").Vector3
local v8 = import("skate_core/physics/reciprocal_sqrt")
local t1 = {
    tu3 = {
        COMBINE_PHYSICAL_MATERIALS = 2188783736,
        GENERATE_CONTACT_A = 2188879912,
        GENERATE_CONTACT_A_END = 2188880520,
        GENERATE_CONTACT_B = 2188885932,
        GENERATE_CONTACT_B_END = 2188886556,
        CONTACT_BATCH_BUILD = 2192445640
    },
    CONTACT_TANGENT_MINIMUM_SQUARED = 1.1754943508222875E-38,
    CONTACT_FALLBACK_HALF = 0.5,
    RetailContactBodyState = {},
    RetailContactInput = {},
    RetailContactMaterial = {}
}

function t1.combine_contact_materials(p4, p5) -- line: 92
    -- upvalues: t1 (copy)
    local static_friction = if p4.static_friction > p5.static_friction then p4.static_friction else p5.static_friction
    local dynamic_friction = if p4.dynamic_friction > p5.dynamic_friction then p4.dynamic_friction else p5.dynamic_friction
    local restitution = if p4.restitution < p5.restitution then p4.restitution else p5.restitution

    return {
        static_friction = t1.material_scalar_store(static_friction),
        dynamic_friction = t1.material_scalar_store(dynamic_friction),
        restitution = t1.material_scalar_store(restitution)
    }
end

function t1.material_scalar_store(p6) -- line: 118
    -- upvalues: v1 (copy)
    if p6 == p6 then
        return p6
    end

    local v9

    if p6 ~= 0 and p6 > -1.1754943508222875E-38 and p6 < 1.1754943508222875E-38 then
        local v10 = math.abs(p6) * 7.1362384635298E+44
        local v11 = math.floor(v10)
        local v12 = v10 - v11

        v9 = if v12 > 0.5 or v12 == 0.5 and v11 % 2 == 1 then v11 + 1 else v11

        if p6 < 0 then
            v9 += 2147483648
        end
    else
        buffer.writef32(v1, 0, p6)
        v9 = buffer.readu32(v1, 0)
    end

    buffer.writeu32(v1, 0, (bit32.bor(v9, 4194304)))

    return (buffer.readf32(v1, 0))
end

t1.RetailContact = {}
t1.RetailContactWorkspace = {}

function t1.RetailContactWorkspace.from(p7) -- line: 141
    -- upvalues: rt (copy)
    return {
        center_of_mass = rt.copy(p7.center_of_mass),
        reaction_id = p7.reaction_id,
        inverse_inertia_full = rt.copy(p7.inverse_inertia_full),
        inverse_mass = p7.inverse_mass,
        inverse_inertia_split = rt.copy(p7.inverse_inertia_split),
        state = p7.state,
        force_acceleration = rt.copy(p7.force_acceleration),
        kinetic_energy = p7.kinetic_energy,
        torque_acceleration = rt.copy(p7.torque_acceleration),
        cool_down = p7.cool_down
    }
end

function t1.generate_contact(p8, p9, p10) -- line: 168
    -- upvalues: rt (copy), Vector3 (copy), v8 (copy), t1 (copy)
    local v14 = t1.sub(p8.position_on_a, p9.center_of_mass)
    local v15 = t1.sub(p8.position_on_b, p10.center_of_mass)
    local v16 = t1.point_velocity(p9.linear_velocity, p9.angular_velocity, v14)
    local v17 = t1.point_velocity(p10.linear_velocity, p10.angular_velocity, v15)
    local v18 = t1.sub(v17, v16)
    local v19 = t1.cross(v18, p8.normal)
    local v20 = t1.length_squared(v19)

    if not (t1.CONTACT_TANGENT_MINIMUM_SQUARED <= v20) then
        v19, v20 = t1.fallback_tangent(p8.normal)
    end

    local v21 = v8.estimate(v20)
    local v22 = t1.scale(v19, v21)
    local v23 = rt.copy(p8.normal)
    local v24 = rt.copy(v19)
    local v25 = t1.scale(Vector3.new(-v24.y * v23.z + (v24.z * v23.y + 0), -v24.z * v23.x + (v24.x * v23.z + 0), -v24.x * v23.y + (v24.y * v23.x + 0)), v21)

    return {
        position_on_a = rt.copy(p8.position_on_a),
        body_a_id = p9.contact_body_id,
        position_on_b = rt.copy(p8.position_on_b),
        body_b_id = p10.contact_body_id,
        normal = rt.copy(p8.normal),
        restitution = p8.restitution,
        tangent_0 = v22,
        static_friction = p8.static_friction,
        tangent_1 = v25,
        dynamic_friction = p8.dynamic_friction,
        relative_velocity = v18,
        tag = p8.tag,
        body_a_workspace = t1.RetailContactWorkspace.from(p9),
        body_b_workspace = t1.RetailContactWorkspace.from(p10)
    }
end

function t1.fallback_tangent(p11) -- line: 221
    -- upvalues: Vector3 (copy), t1 (copy)
    local v26 = Vector3.new(-p11.x * p11.x + 1, -p11.y * p11.x + 0, -p11.z * p11.x + 0)
    local v27 = Vector3.new(-p11.x * p11.z + 0, -p11.y * p11.z + 0, -p11.z * p11.z + 1)

    if -p11.x * p11.x + t1.CONTACT_FALLBACK_HALF >= -0 then
        return v26, v26.x
    end

    return Vector3.new(-v27.x, -v27.y, -v27.z), v27.z
end

function t1.point_velocity(p12, p13, p14) -- line: 239
    -- upvalues: Vector3 (copy)
    return Vector3.new(p14.z * p13.y + (-p14.y * p13.z + p12.x), p14.x * p13.z + (-p14.z * p13.x + p12.y), p14.y * p13.x + (-p14.x * p13.y + p12.z))
end

function t1.sub(p15, p16) -- line: 248
    -- upvalues: Vector3 (copy)
    return Vector3.new(p15.x - p16.x, p15.y - p16.y, p15.z - p16.z)
end

function t1.scale(p17, p18) -- line: 252
    -- upvalues: Vector3 (copy)
    return Vector3.new(p17.x * p18 + 0, p17.y * p18 + 0, p17.z * p18 + 0)
end

function t1.cross(p19, p20) -- line: 256
    -- upvalues: Vector3 (copy)
    return Vector3.new(p19.y * p20.z + (-p19.z * p20.y + 0), p19.z * p20.x + (-p19.x * p20.z + 0), p19.x * p20.y + (-p19.y * p20.x + 0))
end

function t1.dot(p21, p22) -- line: 264
    return p21.z * p22.z + (p21.y * p22.y + (p21.x * p22.x + 0))
end

function t1.length_squared(p23) -- line: 268
    -- upvalues: t1 (copy)
    return t1.dot(p23, p23)
end

return t1
