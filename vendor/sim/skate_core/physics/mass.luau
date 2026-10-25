-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/native_arithmetic")
local RetailLocalMassFrame = import("skate_core/physics/rigid_body").RetailLocalMassFrame
local Vector3 = import("skate_core/math").Vector3
local v2 = import("skate_core/physics/construction/primitive_mass")
local v3 = import("skate_core/physics/construction/board_parts")
local v4 = import("skate_core/physics/construction/mass_moments")
local v5 = import("skate_core/physics/construction/deck_geometry")
local t1 = {
    MassShape = v2.MassShape,
    PrimitiveMass = v2.PrimitiveMass,
    primitive_mass = v2.primitive_mass,
    ForwardMassProperties = v3.ForwardMassProperties,
    PartMassInput = v3.PartMassInput,
    TruckMassSettings = v3.TruckMassSettings,
    WheelMassSettings = v3.WheelMassSettings,
    forward_mass_properties = v3.forward_mass_properties,
    truck_mass_input = v3.truck_mass_input,
    wheel_mass_input = v3.wheel_mass_input,
    AggregateMassProperties = v4.AggregateMassProperties,
    MassMoments = v4.MassMoments,
    DeckChild = v5.DeckChild,
    DeckGeometry = v5.DeckGeometry,
    DeckGeometrySettings = v5.DeckGeometrySettings,
    DeckShape = v5.DeckShape
}

function t1.primitive_mass_properties(p1, p2, p3) -- line: 57
    -- upvalues: rt (copy), RetailLocalMassFrame (copy), Vector3 (copy), t1 (copy)
    local v6 = t1.primitive_mass(p1.shape)

    if v6 == nil then
        return nil
    end

    local v7 = if p1.requested_mass < rt.F32_MIN_POSITIVE then v6.volume else p1.requested_mass
    local moments_per_unit_mass = v6.moments_per_unit_mass

    return t1.finalize_principal_mass(rt.copy(RetailLocalMassFrame.IDENTITY), v7, Vector3.new(moments_per_unit_mass.x * v7, moments_per_unit_mass.y * v7, moments_per_unit_mass.z * v7), p2, p3)
end

function t1.aggregate_mass_properties(p4, p5, p6, p7) -- line: 81
    -- upvalues: rt (copy), Vector3 (copy), t1 (copy)
    local v8 = rt.copy(p4)
    local v9 = t1.MassMoments.principal_properties(v8)
    local v10 = if p5 < rt.F32_MIN_POSITIVE then v9.volume else p5
    local moments_per_unit_mass = v9.moments_per_unit_mass

    return t1.finalize_principal_mass(t1.inverse_mass_frame(v9.local_mass_frame, moments_per_unit_mass), v10, Vector3.new(moments_per_unit_mass.x * v10, moments_per_unit_mass.y * v10, moments_per_unit_mass.z * v10), p6, p7)
end

function t1.inverse_mass_frame(p8, p9) -- line: 109
    -- upvalues: rt (copy), RetailLocalMassFrame (copy), Vector3 (copy)
    local translation = p8.translation
    local v11 = not (translation.x * translation.x + translation.y * translation.y + translation.z * translation.z < (p9.y + p9.z + p9.x) * 1.0000001111620804E-06)
    local v12 = false

    for i = 0, 2 do
        local v13 = p8.basis.columns[i + 1]

        for j = 0, 2 do
            if math.abs(v13[j + 1] - (if i == j then 1 else 0)) > 0.0010000000474974513 then
                v12 = true
                break
            end
        end

        if v12 then
            break
        end
    end

    if v11 or v12 then
        local t2 = {
            {
                p8.basis.columns[1][1],
                p8.basis.columns[2][1],
                p8.basis.columns[3][1]
            },
            {
                p8.basis.columns[1][2],
                p8.basis.columns[2][2],
                p8.basis.columns[3][2]
            },
            {
                p8.basis.columns[1][3],
                p8.basis.columns[2][3],
                p8.basis.columns[3][3]
            }
        }
        local t3 = {
            0 - translation.x,
            0 - translation.y,
            0 - translation.z
        }
        local t4 = {
            t3[1] * t2[1][1] + (t3[2] * t2[2][1] + t3[3] * t2[3][1]),
            t3[1] * t2[1][2] + (t3[2] * t2[2][2] + t3[3] * t2[3][2]),
            t3[1] * t2[1][3] + (t3[2] * t2[2][3] + t3[3] * t2[3][3])
        }

        return {
            basis = {
                columns = t2
            },
            translation = Vector3.new(t4[1], t4[2], t4[3])
        }
    end

    return rt.copy(RetailLocalMassFrame.IDENTITY)
end

t1.RETAIL_UNBOUNDED_VELOCITY = 3.4028234663852886E+38
t1.RETAIL_WHEEL_MAXIMUM_ANGULAR_VELOCITY = 59999.99609375

function t1.retail_wheel_mass_properties() -- line: 155
    -- upvalues: rt (copy), t1 (copy)
    return t1.wheel_mass_properties(rt.copy(t1.WheelMassSettings.STOCK))
end

function t1.wheel_mass_properties(p10) -- line: 159
    -- upvalues: rt (copy), RetailLocalMassFrame (copy), t1 (copy)
    local v15 = t1.forward_mass_properties(t1.wheel_mass_input(p10))

    if v15 == nil then
        error("the stock wheel is a supported sphere", 0)
    end

    return t1.finalize_principal_mass(rt.copy(RetailLocalMassFrame.IDENTITY), v15.mass, v15.principal_moments, t1.RETAIL_WHEEL_MAXIMUM_ANGULAR_VELOCITY, 0)
end

function t1.retail_truck_mass_properties() -- line: 174
    -- upvalues: rt (copy), t1 (copy)
    return t1.truck_mass_properties(rt.copy(t1.TruckMassSettings.STOCK))
end

function t1.truck_mass_properties(p11) -- line: 178
    -- upvalues: rt (copy), RetailLocalMassFrame (copy), t1 (copy)
    local v16 = t1.forward_mass_properties(t1.truck_mass_input(p11))

    if v16 == nil then
        error("the stock truck is a supported capsule", 0)
    end

    return t1.finalize_principal_mass(rt.copy(RetailLocalMassFrame.IDENTITY), v16.mass, v16.principal_moments, t1.RETAIL_UNBOUNDED_VELOCITY, 0)
end

function t1.deck_mass_properties(p12, p13, p14) -- line: 195
    -- upvalues: rt (copy), RetailLocalMassFrame (copy), t1 (copy)
    local v17 = t1.aggregate_mass_properties(t1.DeckGeometry.mass_moments(p12), p13, t1.RETAIL_UNBOUNDED_VELOCITY, p14)

    v17.local_mass_frame = rt.copy(RetailLocalMassFrame.IDENTITY)

    return v17
end

function t1.retail_deck_mass_properties() -- line: 209
    -- upvalues: rt (copy), t1 (copy)
    local v18 = t1.DeckGeometry.new(rt.copy(t1.DeckGeometrySettings.STOCK))

    return t1.deck_mass_properties(v18, 6, 26.99999756813054)
end

function t1.default_skateboard_mass_properties() -- line: 217
    -- upvalues: t1 (copy)
    return {
        t1.retail_wheel_mass_properties(),
        t1.retail_wheel_mass_properties(),
        t1.retail_wheel_mass_properties(),
        t1.retail_wheel_mass_properties(),
        t1.retail_truck_mass_properties(),
        t1.retail_truck_mass_properties(),
        t1.retail_deck_mass_properties()
    }
end

function t1.finalize_principal_mass(p15, p16, p17, p18, p19) -- line: 233
    -- upvalues: Vector3 (copy), t1 (copy)
    local v19 = Vector3.new(t1.refined_reciprocal(p17.x), t1.refined_reciprocal(p17.y), t1.refined_reciprocal(p17.z))
    local v20 = if v19.x < v19.y then v19.x else v19.y

    if not (v20 < v19.z) then
        v20 = v19.z
    end

    return {
        local_mass_frame = p15,
        dynamics = {
            linear_drag = 0,
            inverse_tensor = v19,
            inverse_mass = 1 / p16,
            spherical = 1 / v20,
            maximum_linear_velocity = t1.RETAIL_UNBOUNDED_VELOCITY,
            maximum_angular_velocity = p18,
            angular_drag = p19
        }
    }
end

function t1.refined_reciprocal(p20) -- line: 273
    -- upvalues: v1 (copy)
    local v21 = v1.reciprocal_estimate(p20)
    local v22 = v21 * (-v21 * p20 + 1) + v21

    return v22 * (-v22 * p20 + 1) + v22
end

return t1
