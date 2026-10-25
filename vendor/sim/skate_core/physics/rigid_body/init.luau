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
local v8 = import("skate_core/physics/point_force")
local Vector3 = import("skate_core/math").Vector3
local v9 = import("skate_core/physics/rigid_body/dynamic_update")
local t1 = {
    RetailForceAccumulator = v8.RetailForceAccumulator,
    accumulate_point_force = v8.accumulate_point_force,
    DynamicUpdateResult = v9.DynamicUpdateResult,
    dynamic_update_packed = v9.dynamic_update_packed
}
local dynamic_update_packed = v9.dynamic_update_packed

t1.tu3 = {
    BATCH_INTEGRATOR_BODY = 2192467344,
    APPLY_QUEUED_SKATEBOARD_FORCES = 2193635096
}
t1.RetailSimulationStep = {}

function t1.RetailSimulationStep.fixed_60_hz(p4, p5, p6) -- line: 69
    -- upvalues: rt (copy)
    return {
        time_step = 0.01666666753590107,
        frequency = 59.99999687075631,
        cool_down = p4,
        minimum_energy = p5,
        gravity_acceleration = rt.copy(p6)
    }
end

t1.RetailInertiaDynamics = {}
t1.RetailLocalMassFrame = {}
t1.RetailLocalMassFrame.IDENTITY = {
    basis = {
        columns = {
            { 1, 0, 0 },
            { 0, 1, 0 },
            { 0, 0, 1 }
        }
    },
    translation = rt.copy(Vector3.ZERO)
}
t1.RetailBodyMassProperties = {}
t1.RetailReactionCorrections = {}

function t1.RetailReactionCorrections.default() -- line: 116
    -- upvalues: Vector3 (copy)
    return {
        linear_displacement = Vector3.default(),
        position_displacement = Vector3.default(),
        angular_displacement = Vector3.default(),
        orientation_displacement = Vector3.default()
    }
end

t1.RetailBodyRates = {}
t1.RetailBodyRateStep = {}
t1.RetailPackedWorldInverseInertia = {}
t1.RetailQuaternion = {}
t1.RetailQuaternion.IDENTITY = {
    x = 0,
    y = 0,
    z = 0,
    w = 1
}

local t2 = {
    orientation = true,
    position = true,
    linear_velocity = true,
    angular_velocity = true,
    force_acceleration = true,
    torque_acceleration = true,
    basis = true,
    world_inverse_inertia = true
}

function t1.integrate_body_rates_reference(p7, p8, p9, p10) -- line: 190
    -- upvalues: rt (copy), v1 (copy), Vector3 (copy), t1 (copy), dynamic_update_packed (copy)
    local v10 = rt.copy(p7)
    local v11 = table.create(44, 0)
    local v12 = v10.orientation.x
    local v13, v14, v15, v16

    if v12 ~= 0 and v12 > -1.1754943508222875E-38 and v12 < 1.1754943508222875E-38 then
        v13 = math.abs(v12) * 7.1362384635298E+44
        v16 = math.floor(v13)
        v14 = v13 - v16
        v15 = if v14 > 0.5 or v14 == 0.5 and v16 % 2 == 1 then v16 + 1 else v16

        if v12 < 0 then
            v15 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v12)
        v15 = buffer.readu32(v1, 0)
    end

    v11[1] = v15
    v12 = v10.orientation.y

    local v17

    if v12 ~= 0 and v12 > -1.1754943508222875E-38 and v12 < 1.1754943508222875E-38 then
        v13 = math.abs(v12) * 7.1362384635298E+44
        v16 = math.floor(v13)
        v14 = v13 - v16
        v17 = if v14 > 0.5 or v14 == 0.5 and v16 % 2 == 1 then v16 + 1 else v16

        if v12 < 0 then
            v17 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v12)
        v17 = buffer.readu32(v1, 0)
    end

    v11[2] = v17
    v12 = v10.orientation.z

    local v18

    if v12 ~= 0 and v12 > -1.1754943508222875E-38 and v12 < 1.1754943508222875E-38 then
        v13 = math.abs(v12) * 7.1362384635298E+44
        v16 = math.floor(v13)
        v14 = v13 - v16
        v18 = if v14 > 0.5 or v14 == 0.5 and v16 % 2 == 1 then v16 + 1 else v16

        if v12 < 0 then
            v18 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v12)
        v18 = buffer.readu32(v1, 0)
    end

    v11[3] = v18
    v12 = v10.orientation.w

    local v19

    if v12 ~= 0 and v12 > -1.1754943508222875E-38 and v12 < 1.1754943508222875E-38 then
        v13 = math.abs(v12) * 7.1362384635298E+44
        v16 = math.floor(v13)
        v14 = v13 - v16
        v19 = if v14 > 0.5 or v14 == 0.5 and v16 % 2 == 1 then v16 + 1 else v16

        if v12 < 0 then
            v19 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v12)
        v19 = buffer.readu32(v1, 0)
    end

    v11[4] = v19
    v19 = {
        {
            4,
            v10.position
        },
        {
            8,
            v10.linear_velocity
        },
        {
            12,
            v10.angular_velocity
        },
        {
            36,
            v10.force_acceleration
        },
        {
            40,
            v10.torque_acceleration
        }
    }

    local v20, v21, v22, x, v23

    for _, v24 in ipairs(v19) do
        v20 = v24[1]
        v21 = v24[2]
        v22 = v20 + 1
        x = v21.x

        local v25, v26

        if x == 0 then
            buffer.writef32(v1, 0, x)
            v25 = buffer.readu32(v1, 0)
        elseif x > -1.1754943508222875E-38 and x < 1.1754943508222875E-38 then
            v23 = math.abs(x) * 7.1362384635298E+44
            v25 = math.floor(v23)
            v26 = v23 - v25

            if v26 > 0.5 or v26 == 0.5 and v25 % 2 == 1 then
                v25 += 1
            end

            if x < 0 then
                v25 += 2147483648
            end
        else
            buffer.writef32(v1, 0, x)
            v25 = buffer.readu32(v1, 0)
        end

        v11[v22] = v25
        v22 = v20 + 2
        x = v21.y

        if x == 0 then
            buffer.writef32(v1, 0, x)
            v25 = buffer.readu32(v1, 0)
        elseif x > -1.1754943508222875E-38 and x < 1.1754943508222875E-38 then
            v23 = math.abs(x) * 7.1362384635298E+44
            v25 = math.floor(v23)
            v26 = v23 - v25

            if v26 > 0.5 or v26 == 0.5 and v25 % 2 == 1 then
                v25 += 1
            end

            if x < 0 then
                v25 += 2147483648
            end
        else
            buffer.writef32(v1, 0, x)
            v25 = buffer.readu32(v1, 0)
        end

        v11[v22] = v25
        v22 = v20 + 3
        x = v21.z

        if x == 0 then
            buffer.writef32(v1, 0, x)
            v25 = buffer.readu32(v1, 0)
        elseif x > -1.1754943508222875E-38 and x < 1.1754943508222875E-38 then
            v23 = math.abs(x) * 7.1362384635298E+44
            v25 = math.floor(v23)
            v26 = v23 - v25

            if v26 > 0.5 or v26 == 0.5 and v25 % 2 == 1 then
                v25 += 1
            end

            if x < 0 then
                v25 += 2147483648
            end
        else
            buffer.writef32(v1, 0, x)
            v25 = buffer.readu32(v1, 0)
        end

        v11[v22] = v25
    end

    v12 = p8.inverse_mass

    local v27

    if v12 ~= 0 and v12 > -1.1754943508222875E-38 and v12 < 1.1754943508222875E-38 then
        v13 = math.abs(v12) * 7.1362384635298E+44
        v16 = math.floor(v13)
        v14 = v13 - v16
        v27 = if v14 > 0.5 or v14 == 0.5 and v16 % 2 == 1 then v16 + 1 else v16

        if v12 < 0 then
            v27 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v12)
        v27 = buffer.readu32(v1, 0)
    end

    v11[32] = v27
    v12 = v10.kinetic_energy

    local v28

    if v12 ~= 0 and v12 > -1.1754943508222875E-38 and v12 < 1.1754943508222875E-38 then
        v13 = math.abs(v12) * 7.1362384635298E+44
        v16 = math.floor(v13)
        v14 = v13 - v16
        v28 = if v14 > 0.5 or v14 == 0.5 and v16 % 2 == 1 then v16 + 1 else v16

        if v12 < 0 then
            v28 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v12)
        v28 = buffer.readu32(v1, 0)
    end

    v11[40] = v28
    v11[44] = v10.cool_down
    v28 = {
        p8.inverse_tensor.x,
        p8.inverse_tensor.y,
        p8.inverse_tensor.z,
        0,
        p8.inverse_mass,
        p8.spherical,
        p8.maximum_linear_velocity,
        p8.maximum_angular_velocity,
        p8.linear_drag,
        p8.angular_drag
    }

    local t3 = {}
    local writef32, v29

    for v30, v31 in ipairs(v28) do
        if v31 == 0 then
            buffer.writef32(v1, 0, v31)
            writef32 = buffer.readu32(v1, 0)
        elseif v31 > -1.1754943508222875E-38 and v31 < 1.1754943508222875E-38 then
            x = math.abs(v31) * 7.1362384635298E+44
            writef32 = math.floor(x)
            v29 = x - writef32

            if v29 > 0.5 or v29 == 0.5 and writef32 % 2 == 1 then
                writef32 += 1
            end

            if v31 < 0 then
                writef32 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v31)
            writef32 = buffer.readu32(v1, 0)
        end

        t3[v30] = writef32
    end

    local v32 = table.create(16, 0)
    local t4 = {
        p10.linear_displacement,
        p10.position_displacement,
        p10.angular_displacement,
        p10.orientation_displacement
    }
    local x2, v33, v34

    for i = 0, 3 do
        v20 = t4[i + 1]
        v21 = i * 4 + 1
        x2 = v20.x

        local v35, v36

        if x2 ~= 0 and x2 > -1.1754943508222875E-38 and x2 < 1.1754943508222875E-38 then
            v35 = math.abs(x2) * 7.1362384635298E+44
            v23 = math.floor(v35)
            v36 = v35 - v23
            v33 = if v36 > 0.5 or v36 == 0.5 and v23 % 2 == 1 then v23 + 1 else v23

            if x2 < 0 then
                v32[v21] = v33 + 2147483648
            else
                v32[v21] = v33
            end
        else
            buffer.writef32(v1, 0, x2)
            v32[v21] = buffer.readu32(v1, 0)
        end

        v21 = i * 4 + 2
        x2 = v20.y

        if x2 ~= 0 and x2 > -1.1754943508222875E-38 and x2 < 1.1754943508222875E-38 then
            v35 = math.abs(x2) * 7.1362384635298E+44
            v23 = math.floor(v35)
            v36 = v35 - v23
            v34 = if v36 > 0.5 or v36 == 0.5 and v23 % 2 == 1 then v23 + 1 else v23

            if x2 < 0 then
                v32[v21] = v34 + 2147483648
            else
                v32[v21] = v34
            end
        else
            buffer.writef32(v1, 0, x2)
            v32[v21] = buffer.readu32(v1, 0)
        end

        v21 = i * 4 + 3
        x2 = v20.z

        if x2 ~= 0 and x2 > -1.1754943508222875E-38 and x2 < 1.1754943508222875E-38 then
            v35 = math.abs(x2) * 7.1362384635298E+44
            v23 = math.floor(v35)
            v36 = v35 - v23

            local v37 = if v36 > 0.5 or v36 == 0.5 and v23 % 2 == 1 then v23 + 1 else v23

            if x2 < 0 then
                v32[v21] = v37 + 2147483648
            else
                v32[v21] = v37
            end
        else
            buffer.writef32(v1, 0, x2)
            v32[v21] = buffer.readu32(v1, 0)
        end
    end

    v32 = dynamic_update_packed(v11, t3, p9, v32)

    local function vector(p11) -- line: 250
        -- upvalues: v11 (copy), v1 (copy), Vector3 (copy)
        local new = Vector3.new

        buffer.writeu32(v1, 0, v11[p11 + 1])

        local v39 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v11[p11 + 1 + 1])

        local v41 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v11[p11 + 2 + 1])

        return new(v39, v41, (buffer.readf32(v1, 0)))
    end

    local v43 = {}

    buffer.writeu32(v1, 0, v11[1])
    v43.x = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, v11[2])
    v43.y = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, v11[3])
    v43.z = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, v11[4])
    v43.w = buffer.readf32(v1, 0)
    v10.orientation = v43
    v43 = Vector3.new
    buffer.writeu32(v1, 0, v11[5])
    v20 = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, v11[6])
    v21 = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, v11[7])
    v10.position = v43(v20, v21, (buffer.readf32(v1, 0)))
    v43 = Vector3.new
    buffer.writeu32(v1, 0, v11[9])
    v20 = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, v11[10])
    v21 = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, v11[11])
    v10.linear_velocity = v43(v20, v21, (buffer.readf32(v1, 0)))
    v43 = Vector3.new
    buffer.writeu32(v1, 0, v11[13])
    v20 = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, v11[14])
    v21 = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, v11[15])
    v10.angular_velocity = v43(v20, v21, (buffer.readf32(v1, 0)))
    v43 = Vector3.new
    buffer.writeu32(v1, 0, v11[37])
    v20 = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, v11[38])
    v21 = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, v11[39])
    v10.force_acceleration = v43(v20, v21, (buffer.readf32(v1, 0)))
    v43 = Vector3.new
    buffer.writeu32(v1, 0, v11[41])
    v20 = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, v11[42])
    v21 = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, v11[43])
    v10.torque_acceleration = v43(v20, v21, (buffer.readf32(v1, 0)))
    buffer.writeu32(v1, 0, v11[40])
    v10.kinetic_energy = buffer.readf32(v1, 0)
    v10.cool_down = v11[44]
    v43 = {}
    buffer.writeu32(v1, 0, v11[17])
    v22 = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, v11[18])
    x2 = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, v11[19])
    v16 = {
        v22,
        x2,
        (buffer.readf32(v1, 0))
    }
    buffer.writeu32(v1, 0, v11[21])
    x2 = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, v11[22])
    v33 = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, v11[23])
    v20 = {
        x2,
        v33,
        (buffer.readf32(v1, 0))
    }
    buffer.writeu32(v1, 0, v11[25])
    v33 = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, v11[26])
    writef32 = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, v11[27])
    v43.columns = {
        v16,
        v20,
        {
            v33,
            writef32,
            (buffer.readf32(v1, 0))
        }
    }
    v10.basis = v43
    v43 = t1.unpack_world_inverse_inertia
    v13 = Vector3.new
    buffer.writeu32(v1, 0, v11[29])
    v21 = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, v11[30])
    v22 = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, v11[31])
    v10.world_inverse_inertia = v43(v13(v21, v22, (buffer.readf32(v1, 0))), vector(32))

    return {
        state = v10,
        orientation_displacement = Vector3.new(v32.orientation_displacement[1], v32.orientation_displacement[2], v32.orientation_displacement[3]),
        linear_speed_squared = v32.linear_speed_squared,
        angular_speed_squared = v32.angular_speed_squared
    }
end

local v48 = buffer.create(8)
local to_bits = rt.to_bits

local function f32r(p12) -- line: 300
    -- upvalues: v48 (copy), to_bits (copy)
    if p12 ~= 0 and p12 > -1.1754943508222875E-38 and p12 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(p12))

        return (buffer.readf32(v48, 0))
    end

    buffer.writef32(v48, 0, p12)

    return (buffer.readf32(v48, 0))
end

local function refined_rsqrt(p13) -- line: 311
    local v49 = 1 / math.sqrt(p13)
    local v50 = v49 * v49
    local v51 = v49 * 0.5 * (-p13 * v50 + 1) + v49
    local v52 = v51 * v51

    return v51 * 0.5 * (-p13 * v52 + 1) + v51
end

local t5 = {
    orientation = true,
    position = true,
    linear_velocity = true,
    angular_velocity = true,
    force_acceleration = true,
    torque_acceleration = true,
    kinetic_energy = true,
    cool_down = true,
    basis = true,
    world_inverse_inertia = true
}

local function integrate_core_r3(p14, p15, p16, p17, p18) -- line: 340
    -- upvalues: rt (copy), Vector3 (copy), t2 (copy), v48 (copy), to_bits (copy), t5 (copy)
    local v53

    if p18 ~= nil then
        if p18.rates == p14 then
            return nil
        end

        v53 = p14

        for v56 in p14 do
            if not t5[v56] then
                return nil
            end

            v53 = p14
        end
    else
        v53 = table.clone(p14)

        for v54, v55 in v53 do
            if type(v55) == "table" and not t2[v54] then
                v53[v54] = rt.copy(v55)
            end
        end
    end

    local time_step = p16.time_step
    local v57 = p14.orientation
    local v58 = v57.x

    if v58 ~= 0 and v58 > -1.1754943508222875E-38 and v58 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v58))
    else
        buffer.writef32(v48, 0, v58)
    end

    local v59 = buffer.readf32(v48, 0)

    v58 = v57.y

    if v58 ~= 0 and v58 > -1.1754943508222875E-38 and v58 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v58))
    else
        buffer.writef32(v48, 0, v58)
    end

    local v60 = buffer.readf32(v48, 0)

    v58 = v57.z

    if v58 ~= 0 and v58 > -1.1754943508222875E-38 and v58 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v58))
    else
        buffer.writef32(v48, 0, v58)
    end

    local v61 = buffer.readf32(v48, 0)

    v58 = v57.w

    if v58 ~= 0 and v58 > -1.1754943508222875E-38 and v58 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v58))
    else
        buffer.writef32(v48, 0, v58)
    end

    local v62 = buffer.readf32(v48, 0)

    v57 = p14.position

    local v63 = v57.x

    if v63 ~= 0 and v63 > -1.1754943508222875E-38 and v63 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v63))
    else
        buffer.writef32(v48, 0, v63)
    end

    v58 = buffer.readf32(v48, 0)
    v63 = v57.y

    if v63 ~= 0 and v63 > -1.1754943508222875E-38 and v63 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v63))
    else
        buffer.writef32(v48, 0, v63)
    end

    local v64 = buffer.readf32(v48, 0)

    v63 = v57.z

    if v63 ~= 0 and v63 > -1.1754943508222875E-38 and v63 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v63))
    else
        buffer.writef32(v48, 0, v63)
    end

    local v65 = buffer.readf32(v48, 0)

    v57 = p14.linear_velocity

    local v66 = v57.x

    if v66 ~= 0 and v66 > -1.1754943508222875E-38 and v66 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v66))
    else
        buffer.writef32(v48, 0, v66)
    end

    v63 = buffer.readf32(v48, 0)
    v66 = v57.y

    if v66 ~= 0 and v66 > -1.1754943508222875E-38 and v66 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v66))
    else
        buffer.writef32(v48, 0, v66)
    end

    local v67 = buffer.readf32(v48, 0)

    v66 = v57.z

    if v66 ~= 0 and v66 > -1.1754943508222875E-38 and v66 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v66))
    else
        buffer.writef32(v48, 0, v66)
    end

    local v68 = buffer.readf32(v48, 0)

    v57 = p14.angular_velocity

    local v69 = v57.x

    if v69 ~= 0 and v69 > -1.1754943508222875E-38 and v69 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v69))
    else
        buffer.writef32(v48, 0, v69)
    end

    v66 = buffer.readf32(v48, 0)
    v69 = v57.y

    if v69 ~= 0 and v69 > -1.1754943508222875E-38 and v69 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v69))
    else
        buffer.writef32(v48, 0, v69)
    end

    local v70 = buffer.readf32(v48, 0)

    v69 = v57.z

    if v69 ~= 0 and v69 > -1.1754943508222875E-38 and v69 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v69))
    else
        buffer.writef32(v48, 0, v69)
    end

    local v71 = buffer.readf32(v48, 0)

    v57 = p14.force_acceleration

    local v72 = v57.x

    if v72 ~= 0 and v72 > -1.1754943508222875E-38 and v72 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v72))
    else
        buffer.writef32(v48, 0, v72)
    end

    v69 = buffer.readf32(v48, 0)
    v72 = v57.y

    if v72 ~= 0 and v72 > -1.1754943508222875E-38 and v72 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v72))
    else
        buffer.writef32(v48, 0, v72)
    end

    local v73 = buffer.readf32(v48, 0)

    v72 = v57.z

    if v72 ~= 0 and v72 > -1.1754943508222875E-38 and v72 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v72))
    else
        buffer.writef32(v48, 0, v72)
    end

    local v74 = buffer.readf32(v48, 0)

    v57 = p14.torque_acceleration

    local v75 = v57.x

    if v75 ~= 0 and v75 > -1.1754943508222875E-38 and v75 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v75))
    else
        buffer.writef32(v48, 0, v75)
    end

    v72 = buffer.readf32(v48, 0)
    v75 = v57.y

    if v75 ~= 0 and v75 > -1.1754943508222875E-38 and v75 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v75))
    else
        buffer.writef32(v48, 0, v75)
    end

    local v76 = buffer.readf32(v48, 0)

    v75 = v57.z

    if v75 ~= 0 and v75 > -1.1754943508222875E-38 and v75 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v75))
    else
        buffer.writef32(v48, 0, v75)
    end

    local v77 = buffer.readf32(v48, 0)
    local v78 = p15.inverse_mass

    if v78 ~= 0 and v78 > -1.1754943508222875E-38 and v78 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v78))
    else
        buffer.writef32(v48, 0, v78)
    end

    v75 = buffer.readf32(v48, 0)

    local cool_down = p14.kinetic_energy

    if cool_down ~= 0 and cool_down > -1.1754943508222875E-38 and cool_down < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(cool_down))
    else
        buffer.writef32(v48, 0, cool_down)
    end

    v78 = buffer.readf32(v48, 0)
    cool_down = p14.cool_down
    v57 = p15.inverse_tensor

    local v79 = v57.x

    if v79 ~= 0 and v79 > -1.1754943508222875E-38 and v79 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v79))
    else
        buffer.writef32(v48, 0, v79)
    end

    local v80 = buffer.readf32(v48, 0)

    v79 = v57.y

    if v79 ~= 0 and v79 > -1.1754943508222875E-38 and v79 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v79))
    else
        buffer.writef32(v48, 0, v79)
    end

    local v81 = buffer.readf32(v48, 0)

    v79 = v57.z

    if v79 ~= 0 and v79 > -1.1754943508222875E-38 and v79 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v79))
    else
        buffer.writef32(v48, 0, v79)
    end

    local v82 = buffer.readf32(v48, 0)

    v79 = p15.spherical

    if v79 ~= 0 and v79 > -1.1754943508222875E-38 and v79 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v79))
    else
        buffer.writef32(v48, 0, v79)
    end

    local v83 = buffer.readf32(v48, 0)
    local v84 = p15.maximum_linear_velocity

    if v84 ~= 0 and v84 > -1.1754943508222875E-38 and v84 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v84))
    else
        buffer.writef32(v48, 0, v84)
    end

    v79 = buffer.readf32(v48, 0)

    local v85 = p15.maximum_angular_velocity

    if v85 ~= 0 and v85 > -1.1754943508222875E-38 and v85 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v85))
    else
        buffer.writef32(v48, 0, v85)
    end

    v84 = buffer.readf32(v48, 0)

    local v86 = p15.linear_drag

    if v86 ~= 0 and v86 > -1.1754943508222875E-38 and v86 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v86))
    else
        buffer.writef32(v48, 0, v86)
    end

    v85 = buffer.readf32(v48, 0)

    local v87 = p15.angular_drag

    if v87 ~= 0 and v87 > -1.1754943508222875E-38 and v87 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v87))
    else
        buffer.writef32(v48, 0, v87)
    end

    v86 = buffer.readf32(v48, 0)
    v57 = p17.linear_displacement

    local v88 = v57.x

    if v88 ~= 0 and v88 > -1.1754943508222875E-38 and v88 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v88))
    else
        buffer.writef32(v48, 0, v88)
    end

    v87 = buffer.readf32(v48, 0)
    v88 = v57.y

    if v88 ~= 0 and v88 > -1.1754943508222875E-38 and v88 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v88))
    else
        buffer.writef32(v48, 0, v88)
    end

    local v89 = buffer.readf32(v48, 0)

    v88 = v57.z

    if v88 ~= 0 and v88 > -1.1754943508222875E-38 and v88 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v88))
    else
        buffer.writef32(v48, 0, v88)
    end

    local v90 = buffer.readf32(v48, 0)

    v57 = p17.position_displacement

    local v91 = v57.x

    if v91 ~= 0 and v91 > -1.1754943508222875E-38 and v91 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v91))
    else
        buffer.writef32(v48, 0, v91)
    end

    v88 = buffer.readf32(v48, 0)
    v91 = v57.y

    if v91 ~= 0 and v91 > -1.1754943508222875E-38 and v91 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v91))
    else
        buffer.writef32(v48, 0, v91)
    end

    local v92 = buffer.readf32(v48, 0)

    v91 = v57.z

    if v91 ~= 0 and v91 > -1.1754943508222875E-38 and v91 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v91))
    else
        buffer.writef32(v48, 0, v91)
    end

    local v93 = buffer.readf32(v48, 0)

    v57 = p17.angular_displacement

    local v94 = v57.x

    if v94 ~= 0 and v94 > -1.1754943508222875E-38 and v94 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v94))
    else
        buffer.writef32(v48, 0, v94)
    end

    v91 = buffer.readf32(v48, 0)
    v94 = v57.y

    if v94 ~= 0 and v94 > -1.1754943508222875E-38 and v94 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v94))
    else
        buffer.writef32(v48, 0, v94)
    end

    local v95 = buffer.readf32(v48, 0)

    v94 = v57.z

    if v94 ~= 0 and v94 > -1.1754943508222875E-38 and v94 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v94))
    else
        buffer.writef32(v48, 0, v94)
    end

    local v96 = buffer.readf32(v48, 0)

    v57 = p17.orientation_displacement

    local v97 = v57.x

    if v97 ~= 0 and v97 > -1.1754943508222875E-38 and v97 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v97))
    else
        buffer.writef32(v48, 0, v97)
    end

    v94 = buffer.readf32(v48, 0)
    v97 = v57.y

    if v97 ~= 0 and v97 > -1.1754943508222875E-38 and v97 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v97))
    else
        buffer.writef32(v48, 0, v97)
    end

    local v98 = buffer.readf32(v48, 0)

    v97 = v57.z

    if v97 ~= 0 and v97 > -1.1754943508222875E-38 and v97 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v97))
    else
        buffer.writef32(v48, 0, v97)
    end

    local v99 = buffer.readf32(v48, 0)

    v57 = (v69 * time_step + v63) * time_step + v87
    v87 = (v73 * time_step + v67) * time_step + v89
    v89 = (v74 * time_step + v68) * time_step + v90
    v90 = (v72 * time_step + v66) * time_step + v91
    v91 = (v76 * time_step + v70) * time_step + v95
    v95 = (v77 * time_step + v71) * time_step + v96
    v96 = v58 + v88 + v57
    v88 = v64 + v92 + v87
    v92 = v65 + v93 + v89
    v97 = v90 + v94

    local v100 = v91 + v98
    local v101 = v95 + v99

    v99 = -v101 * v60 + v100 * v61
    v98 = -v97 * v61 + v101 * v59
    v94 = -v100 * v59 + v97 * v60
    v93 = v59 + (v97 * v62 + v99) * 0.5
    v99 = v60 + (v100 * v62 + v98) * 0.5
    v98 = v61 + (v101 * v62 + v94) * 0.5
    v94 = v62 + (v97 * v59 + v100 * v60 + v101 * v61) * -0.5

    local v102 = v93 * v93 + v99 * v99 + v98 * v98 + v94 * v94

    v77 = 1 / math.sqrt(v102)
    v76 = v77 * v77
    v77 = v77 * 0.5 * (-v102 * v76 + 1) + v77
    v73 = v77 * v77
    v77 = v77 * 0.5 * (-v102 * v73 + 1) + v77

    local v103 = v93 * v77
    local v104 = v99 * v77
    local v105 = v98 * v77
    local v106 = v94 * v77
    local v107 = v103 * 1.4142135381698608
    local v108 = v104 * 1.4142135381698608
    local v109 = v105 * 1.4142135381698608
    local v110 = v106 * 1.4142135381698608

    v70 = -v107 * v107 + 0.5
    v66 = -v108 * v108 + 0.5
    v68 = -v109 * v109 + 0.5

    local v111 = v107 * v108
    local v112 = v108 * v109
    local v113 = v109 * v107
    local v114 = v110 * v109
    local v115 = v110 * v107
    local v116 = v110 * v108

    v102 = v66 + v68

    local v117 = v111 + v114
    local v118 = v113 - v116
    local v119 = v111 - v114
    local v120 = v68 + v70
    local v121 = v112 + v115
    local v122 = v113 + v116
    local v123 = v112 - v115
    local v124 = v70 + v66

    v113 = v102 * v80
    v114 = v117 * v80
    v115 = v118 * v80
    v116 = v119 * v81

    local v125 = v120 * v81
    local v126 = v121 * v81
    local v127 = v122 * v82
    local v128 = v123 * v82
    local v129 = v124 * v82

    v107 = v127 * v122 + (v113 * v102 + v116 * v119)
    v108 = v128 * v122 + (v114 * v102 + v125 * v119)
    v109 = v129 * v122 + (v115 * v102 + v126 * v119)
    v110 = v124 * v129 + (v118 * v115 + v121 * v126)
    v111 = v123 * v128 + (v117 * v114 + v120 * v125)
    v112 = v123 * v129 + (v117 * v115 + v120 * v126)
    v82 = p16.frequency
    v81 = v82 - v86

    if not (v81 > 0) then
        v81 = 0
    end

    v86 = v82 - v85

    if not (v86 > 0) then
        v86 = 0
    end

    v113 = v90 * v81
    v114 = v91 * v81
    v115 = v95 * v81
    v95 = v113 * v113 + v114 * v114 + v115 * v115
    v91 = v84 * v84

    if v91 < v95 then
        v90 = v91 / v95
        v116 = 1 / math.sqrt(v90)
        v82 = v116 * v116
        v116 = v116 * 0.5 * (-v90 * v82 + 1) + v116
        v67 = v116 * v116
        v85 = v90 * (v116 * 0.5 * (-v90 * v67 + 1) + v116)

        if v90 == 0 then
            v85 = 0
        end

        v113 *= v85
        v114 *= v85
        v115 *= v85
    else
        v91 = v95
    end

    v116 = v57 * v86
    v125 = v87 * v86
    v126 = v89 * v86
    v89 = v116 * v116 + v125 * v125 + v126 * v126
    v87 = v79 * v79

    if v87 < v89 then
        v86 = v87 / v89
        v127 = 1 / math.sqrt(v86)
        v58 = v127 * v127
        v127 = v127 * 0.5 * (-v86 * v58 + 1) + v127
        v60 = v127 * v127
        v84 = v86 * (v127 * 0.5 * (-v86 * v60 + 1) + v127)

        if v86 == 0 then
            v84 = 0
        end

        v116 *= v84
        v125 *= v84
        v126 *= v84
    else
        v87 = v89
    end

    v75 = v83 * v75 * v91 + v87

    local v130, v131

    if v75 < p16.minimum_energy then
        v130 = if v78 < v75 then cool_down else rt.wrapping_add_u32(cool_down, 1)
        v131 = p16.cool_down
        cool_down = math.min(v130, v131)
    else
        cool_down = 0
    end

    v79 = p16.gravity_acceleration

    local v132, v133, v134, v135

    if p18 ~= nil then
        v131 = v79.x

        if v131 ~= 0 and v131 > -1.1754943508222875E-38 and v131 < 1.1754943508222875E-38 then
            buffer.writeu32(v48, 0, to_bits(v131))
        else
            buffer.writef32(v48, 0, v131)
        end

        v130 = buffer.readf32(v48, 0)
        v131 = v79.y

        if v131 ~= 0 and v131 > -1.1754943508222875E-38 and v131 < 1.1754943508222875E-38 then
            buffer.writeu32(v48, 0, to_bits(v131))
        else
            buffer.writef32(v48, 0, v131)
        end

        v128 = buffer.readf32(v48, 0)
        v131 = v79.z

        if v131 ~= 0 and v131 > -1.1754943508222875E-38 and v131 < 1.1754943508222875E-38 then
            buffer.writeu32(v48, 0, to_bits(v131))
        else
            buffer.writef32(v48, 0, v131)
        end

        v129 = buffer.readf32(v48, 0)
        v78 = p18.rates
        v83 = p18.orientation

        if v103 ~= 0 and v103 > -1.1754943508222875E-38 and v103 < 1.1754943508222875E-38 then
            buffer.writeu32(v48, 0, to_bits(v103))
        else
            buffer.writef32(v48, 0, v103)
        end

        v131 = buffer.readf32(v48, 0)

        if v104 ~= 0 and v104 > -1.1754943508222875E-38 and v104 < 1.1754943508222875E-38 then
            buffer.writeu32(v48, 0, to_bits(v104))
        else
            buffer.writef32(v48, 0, v104)
        end

        v134 = buffer.readf32(v48, 0)

        if v105 ~= 0 and v105 > -1.1754943508222875E-38 and v105 < 1.1754943508222875E-38 then
            buffer.writeu32(v48, 0, to_bits(v105))
        else
            buffer.writef32(v48, 0, v105)
        end

        v135 = buffer.readf32(v48, 0)

        if v106 ~= 0 and v106 > -1.1754943508222875E-38 and v106 < 1.1754943508222875E-38 then
            buffer.writeu32(v48, 0, to_bits(v106))
        else
            buffer.writef32(v48, 0, v106)
        end

        v132 = buffer.readf32(v48, 0)
        v83.x = v131
        v83.y = v134
        v83.z = v135
        v83.w = v132
        v78.orientation = v83
        v83 = p18.position

        if v96 ~= 0 and v96 > -1.1754943508222875E-38 and v96 < 1.1754943508222875E-38 then
            buffer.writeu32(v48, 0, to_bits(v96))
        else
            buffer.writef32(v48, 0, v96)
        end

        v131 = buffer.readf32(v48, 0)

        if v88 ~= 0 and v88 > -1.1754943508222875E-38 and v88 < 1.1754943508222875E-38 then
            buffer.writeu32(v48, 0, to_bits(v88))
        else
            buffer.writef32(v48, 0, v88)
        end

        v134 = buffer.readf32(v48, 0)

        if v92 ~= 0 and v92 > -1.1754943508222875E-38 and v92 < 1.1754943508222875E-38 then
            buffer.writeu32(v48, 0, to_bits(v92))
        else
            buffer.writef32(v48, 0, v92)
        end

        v135 = buffer.readf32(v48, 0)
        v83.x = v131
        v83.y = v134
        v83.z = v135
        v78.position = v83
        v83 = p18.linear_velocity

        if v116 ~= 0 and v116 > -1.1754943508222875E-38 and v116 < 1.1754943508222875E-38 then
            buffer.writeu32(v48, 0, to_bits(v116))
        else
            buffer.writef32(v48, 0, v116)
        end

        v131 = buffer.readf32(v48, 0)

        if v125 ~= 0 and v125 > -1.1754943508222875E-38 and v125 < 1.1754943508222875E-38 then
            buffer.writeu32(v48, 0, to_bits(v125))
        else
            buffer.writef32(v48, 0, v125)
        end

        v134 = buffer.readf32(v48, 0)

        if v126 ~= 0 and v126 > -1.1754943508222875E-38 and v126 < 1.1754943508222875E-38 then
            buffer.writeu32(v48, 0, to_bits(v126))
        else
            buffer.writef32(v48, 0, v126)
        end

        v135 = buffer.readf32(v48, 0)
        v83.x = v131
        v83.y = v134
        v83.z = v135
        v78.linear_velocity = v83
        v83 = p18.angular_velocity

        if v113 ~= 0 and v113 > -1.1754943508222875E-38 and v113 < 1.1754943508222875E-38 then
            buffer.writeu32(v48, 0, to_bits(v113))
        else
            buffer.writef32(v48, 0, v113)
        end

        v131 = buffer.readf32(v48, 0)

        if v114 ~= 0 and v114 > -1.1754943508222875E-38 and v114 < 1.1754943508222875E-38 then
            buffer.writeu32(v48, 0, to_bits(v114))
        else
            buffer.writef32(v48, 0, v114)
        end

        v134 = buffer.readf32(v48, 0)

        if v115 ~= 0 and v115 > -1.1754943508222875E-38 and v115 < 1.1754943508222875E-38 then
            buffer.writeu32(v48, 0, to_bits(v115))
        else
            buffer.writef32(v48, 0, v115)
        end

        v135 = buffer.readf32(v48, 0)
        v83.x = v131
        v83.y = v134
        v83.z = v135
        v78.angular_velocity = v83
        v83 = p18.force_acceleration
        v83.x = v130
        v83.y = v128
        v83.z = v129
        v78.force_acceleration = v83
        v83 = p18.torque_acceleration
        v83.x = 0
        v83.y = 0
        v83.z = 0
        v78.torque_acceleration = v83

        if v75 ~= 0 and v75 > -1.1754943508222875E-38 and v75 < 1.1754943508222875E-38 then
            buffer.writeu32(v48, 0, to_bits(v75))
        else
            buffer.writef32(v48, 0, v75)
        end

        v78.kinetic_energy = buffer.readf32(v48, 0)
        v78.cool_down = cool_down
        v129 = p18.basis_columns
        v128 = p18.basis_1

        if v102 ~= 0 and v102 > -1.1754943508222875E-38 and v102 < 1.1754943508222875E-38 then
            buffer.writeu32(v48, 0, to_bits(v102))
        else
            buffer.writef32(v48, 0, v102)
        end

        v131 = buffer.readf32(v48, 0)

        if v117 ~= 0 and v117 > -1.1754943508222875E-38 and v117 < 1.1754943508222875E-38 then
            buffer.writeu32(v48, 0, to_bits(v117))
        else
            buffer.writef32(v48, 0, v117)
        end

        v134 = buffer.readf32(v48, 0)

        if v118 ~= 0 and v118 > -1.1754943508222875E-38 and v118 < 1.1754943508222875E-38 then
            buffer.writeu32(v48, 0, to_bits(v118))
        else
            buffer.writef32(v48, 0, v118)
        end

        v135 = buffer.readf32(v48, 0)
        v128[1] = v131
        v128[2] = v134
        v128[3] = v135
        v129[1] = v128
        v128 = p18.basis_2

        if v119 ~= 0 and v119 > -1.1754943508222875E-38 and v119 < 1.1754943508222875E-38 then
            buffer.writeu32(v48, 0, to_bits(v119))
        else
            buffer.writef32(v48, 0, v119)
        end

        v131 = buffer.readf32(v48, 0)

        if v120 ~= 0 and v120 > -1.1754943508222875E-38 and v120 < 1.1754943508222875E-38 then
            buffer.writeu32(v48, 0, to_bits(v120))
        else
            buffer.writef32(v48, 0, v120)
        end

        v134 = buffer.readf32(v48, 0)

        if v121 ~= 0 and v121 > -1.1754943508222875E-38 and v121 < 1.1754943508222875E-38 then
            buffer.writeu32(v48, 0, to_bits(v121))
        else
            buffer.writef32(v48, 0, v121)
        end

        v135 = buffer.readf32(v48, 0)
        v128[1] = v131
        v128[2] = v134
        v128[3] = v135
        v129[2] = v128
        v128 = p18.basis_3

        if v122 ~= 0 and v122 > -1.1754943508222875E-38 and v122 < 1.1754943508222875E-38 then
            buffer.writeu32(v48, 0, to_bits(v122))
        else
            buffer.writef32(v48, 0, v122)
        end

        v131 = buffer.readf32(v48, 0)

        if v123 ~= 0 and v123 > -1.1754943508222875E-38 and v123 < 1.1754943508222875E-38 then
            buffer.writeu32(v48, 0, to_bits(v123))
        else
            buffer.writef32(v48, 0, v123)
        end

        v134 = buffer.readf32(v48, 0)

        if v124 ~= 0 and v124 > -1.1754943508222875E-38 and v124 < 1.1754943508222875E-38 then
            buffer.writeu32(v48, 0, to_bits(v124))
        else
            buffer.writef32(v48, 0, v124)
        end

        v135 = buffer.readf32(v48, 0)
        v128[1] = v131
        v128[2] = v134
        v128[3] = v135
        v129[3] = v128
        v83 = p18.basis
        v83.columns = v129
        v78.basis = v83

        if v107 ~= 0 and v107 > -1.1754943508222875E-38 and v107 < 1.1754943508222875E-38 then
            buffer.writeu32(v48, 0, to_bits(v107))
        else
            buffer.writef32(v48, 0, v107)
        end

        v131 = buffer.readf32(v48, 0)

        if v108 ~= 0 and v108 > -1.1754943508222875E-38 and v108 < 1.1754943508222875E-38 then
            buffer.writeu32(v48, 0, to_bits(v108))
        else
            buffer.writef32(v48, 0, v108)
        end

        v134 = buffer.readf32(v48, 0)

        if v109 ~= 0 and v109 > -1.1754943508222875E-38 and v109 < 1.1754943508222875E-38 then
            buffer.writeu32(v48, 0, to_bits(v109))
        else
            buffer.writef32(v48, 0, v109)
        end

        v135 = buffer.readf32(v48, 0)

        if v110 ~= 0 and v110 > -1.1754943508222875E-38 and v110 < 1.1754943508222875E-38 then
            buffer.writeu32(v48, 0, to_bits(v110))
        else
            buffer.writef32(v48, 0, v110)
        end

        v132 = buffer.readf32(v48, 0)

        if v111 ~= 0 and v111 > -1.1754943508222875E-38 and v111 < 1.1754943508222875E-38 then
            buffer.writeu32(v48, 0, to_bits(v111))
        else
            buffer.writef32(v48, 0, v111)
        end

        v133 = buffer.readf32(v48, 0)

        if v112 ~= 0 and v112 > -1.1754943508222875E-38 and v112 < 1.1754943508222875E-38 then
            buffer.writeu32(v48, 0, to_bits(v112))
        else
            buffer.writef32(v48, 0, v112)
        end

        local v136 = buffer.readf32(v48, 0)

        v129 = p18.inertia_columns
        v128 = p18.inertia_1
        v128[1] = v131
        v128[2] = v134
        v128[3] = v135
        v129[1] = v128
        v128 = p18.inertia_2
        v128[1] = v134
        v128[2] = v133
        v128[3] = v136
        v129[2] = v128
        v128 = p18.inertia_3
        v128[1] = v135
        v128[2] = v136
        v128[3] = v132
        v129[3] = v128
        v83 = p18.world_inverse_inertia
        v83.columns = v129
        v78.world_inverse_inertia = v83

        return v78, v97, v100, v101, v87, v91
    end

    v130 = {}

    if v103 ~= 0 and v103 > -1.1754943508222875E-38 and v103 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v103))
    else
        buffer.writef32(v48, 0, v103)
    end

    v130.x = buffer.readf32(v48, 0)

    if v104 ~= 0 and v104 > -1.1754943508222875E-38 and v104 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v104))
    else
        buffer.writef32(v48, 0, v104)
    end

    v130.y = buffer.readf32(v48, 0)

    if v105 ~= 0 and v105 > -1.1754943508222875E-38 and v105 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v105))
    else
        buffer.writef32(v48, 0, v105)
    end

    v130.z = buffer.readf32(v48, 0)

    if v106 ~= 0 and v106 > -1.1754943508222875E-38 and v106 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v106))
    else
        buffer.writef32(v48, 0, v106)
    end

    v130.w = buffer.readf32(v48, 0)
    v53.orientation = v130
    v130 = Vector3.new

    if v96 ~= 0 and v96 > -1.1754943508222875E-38 and v96 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v96))
    else
        buffer.writef32(v48, 0, v96)
    end

    v128 = buffer.readf32(v48, 0)

    if v88 ~= 0 and v88 > -1.1754943508222875E-38 and v88 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v88))
    else
        buffer.writef32(v48, 0, v88)
    end

    v129 = buffer.readf32(v48, 0)

    if v92 ~= 0 and v92 > -1.1754943508222875E-38 and v92 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v92))
    else
        buffer.writef32(v48, 0, v92)
    end

    v53.position = v130(v128, v129, (buffer.readf32(v48, 0)))
    v130 = Vector3.new

    if v116 ~= 0 and v116 > -1.1754943508222875E-38 and v116 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v116))
    else
        buffer.writef32(v48, 0, v116)
    end

    v128 = buffer.readf32(v48, 0)

    if v125 ~= 0 and v125 > -1.1754943508222875E-38 and v125 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v125))
    else
        buffer.writef32(v48, 0, v125)
    end

    v129 = buffer.readf32(v48, 0)

    if v126 ~= 0 and v126 > -1.1754943508222875E-38 and v126 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v126))
    else
        buffer.writef32(v48, 0, v126)
    end

    v53.linear_velocity = v130(v128, v129, (buffer.readf32(v48, 0)))
    v130 = Vector3.new

    if v113 ~= 0 and v113 > -1.1754943508222875E-38 and v113 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v113))
    else
        buffer.writef32(v48, 0, v113)
    end

    v128 = buffer.readf32(v48, 0)

    if v114 ~= 0 and v114 > -1.1754943508222875E-38 and v114 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v114))
    else
        buffer.writef32(v48, 0, v114)
    end

    v129 = buffer.readf32(v48, 0)

    if v115 ~= 0 and v115 > -1.1754943508222875E-38 and v115 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v115))
    else
        buffer.writef32(v48, 0, v115)
    end

    v53.angular_velocity = v130(v128, v129, (buffer.readf32(v48, 0)))
    v130 = Vector3.new
    v129 = v79.x

    if v129 ~= 0 and v129 > -1.1754943508222875E-38 and v129 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v129))
    else
        buffer.writef32(v48, 0, v129)
    end

    v128 = buffer.readf32(v48, 0)
    v131 = v79.y

    if v131 ~= 0 and v131 > -1.1754943508222875E-38 and v131 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v131))
    else
        buffer.writef32(v48, 0, v131)
    end

    v129 = buffer.readf32(v48, 0)
    v134 = v79.z

    if v134 ~= 0 and v134 > -1.1754943508222875E-38 and v134 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v134))
    else
        buffer.writef32(v48, 0, v134)
    end

    v53.force_acceleration = v130(v128, v129, (buffer.readf32(v48, 0)))
    v53.torque_acceleration = Vector3.new(0, 0, 0)

    if v75 ~= 0 and v75 > -1.1754943508222875E-38 and v75 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v75))
    else
        buffer.writef32(v48, 0, v75)
    end

    v53.kinetic_energy = buffer.readf32(v48, 0)
    v53.cool_down = cool_down
    v130 = {}
    v128 = {}
    v129 = {}

    if v102 ~= 0 and v102 > -1.1754943508222875E-38 and v102 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v102))
    else
        buffer.writef32(v48, 0, v102)
    end

    v131 = buffer.readf32(v48, 0)

    if v117 ~= 0 and v117 > -1.1754943508222875E-38 and v117 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v117))
    else
        buffer.writef32(v48, 0, v117)
    end

    v134 = buffer.readf32(v48, 0)

    if v118 ~= 0 and v118 > -1.1754943508222875E-38 and v118 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v118))
    else
        buffer.writef32(v48, 0, v118)
    end

    v135 = buffer.readf32(v48, 0)
    v129[1] = v131
    v129[2] = v134
    v129[3] = v135
    v131 = {}

    if v119 ~= 0 and v119 > -1.1754943508222875E-38 and v119 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v119))
    else
        buffer.writef32(v48, 0, v119)
    end

    v134 = buffer.readf32(v48, 0)

    if v120 ~= 0 and v120 > -1.1754943508222875E-38 and v120 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v120))
    else
        buffer.writef32(v48, 0, v120)
    end

    v135 = buffer.readf32(v48, 0)

    if v121 ~= 0 and v121 > -1.1754943508222875E-38 and v121 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v121))
    else
        buffer.writef32(v48, 0, v121)
    end

    v132 = buffer.readf32(v48, 0)
    v131[1] = v134
    v131[2] = v135
    v131[3] = v132
    v134 = {}

    if v122 ~= 0 and v122 > -1.1754943508222875E-38 and v122 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v122))
    else
        buffer.writef32(v48, 0, v122)
    end

    v135 = buffer.readf32(v48, 0)

    if v123 ~= 0 and v123 > -1.1754943508222875E-38 and v123 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v123))
    else
        buffer.writef32(v48, 0, v123)
    end

    v132 = buffer.readf32(v48, 0)

    if v124 ~= 0 and v124 > -1.1754943508222875E-38 and v124 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v124))
    else
        buffer.writef32(v48, 0, v124)
    end

    v133 = buffer.readf32(v48, 0)
    v134[1] = v135
    v134[2] = v132
    v134[3] = v133
    v128[1] = v129
    v128[2] = v131
    v128[3] = v134
    v130.columns = v128
    v53.basis = v130

    if v107 ~= 0 and v107 > -1.1754943508222875E-38 and v107 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v107))
    else
        buffer.writef32(v48, 0, v107)
    end

    v130 = buffer.readf32(v48, 0)

    if v108 ~= 0 and v108 > -1.1754943508222875E-38 and v108 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v108))
    else
        buffer.writef32(v48, 0, v108)
    end

    v128 = buffer.readf32(v48, 0)

    if v109 ~= 0 and v109 > -1.1754943508222875E-38 and v109 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v109))
    else
        buffer.writef32(v48, 0, v109)
    end

    v129 = buffer.readf32(v48, 0)

    if v110 ~= 0 and v110 > -1.1754943508222875E-38 and v110 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v110))
    else
        buffer.writef32(v48, 0, v110)
    end

    v131 = buffer.readf32(v48, 0)

    if v111 ~= 0 and v111 > -1.1754943508222875E-38 and v111 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v111))
    else
        buffer.writef32(v48, 0, v111)
    end

    v134 = buffer.readf32(v48, 0)

    if v112 ~= 0 and v112 > -1.1754943508222875E-38 and v112 < 1.1754943508222875E-38 then
        buffer.writeu32(v48, 0, to_bits(v112))
    else
        buffer.writef32(v48, 0, v112)
    end

    v135 = buffer.readf32(v48, 0)
    v53.world_inverse_inertia = {
        columns = {
            { v130, v128, v129 },
            { v128, v134, v135 },
            { v129, v135, v131 }
        }
    }

    return v53, v97, v100, v101, v87, v91
end

local create = vector.create

local function tiny(p19) -- line: 595
    -- upvalues: v48 (copy), to_bits (copy)
    buffer.writeu32(v48, 0, to_bits(p19))

    return (buffer.readf32(v48, 0))
end

local function integrate_core(p20, p21, p22, p23, p24) -- line: 600
    -- upvalues: rt (copy), Vector3 (copy), t2 (copy), v48 (copy), to_bits (copy), t5 (copy), create (copy)
    local v137

    if p24 ~= nil then
        if p24.rates == p20 then
            return nil
        end

        v137 = p20

        for v140 in p20 do
            if not t5[v140] then
                return nil
            end

            v137 = p20
        end
    else
        v137 = table.clone(p20)

        for v138, v139 in v137 do
            if type(v139) == "table" and not t2[v138] then
                v137[v138] = rt.copy(v139)
            end
        end
    end

    local time_step = p22.time_step
    local orientation_displacement = p20.orientation
    local x, y, z = orientation_displacement.x, orientation_displacement.y, orientation_displacement.z
    local v141 = create(x, y, z)
    local x2, y2, z2 = v141.x, v141.y, v141.z

    if x < 1.1754943508222875E-38 and x > -1.1754943508222875E-38 and x ~= 0 then
        buffer.writeu32(v48, 0, to_bits(x))
        x2 = buffer.readf32(v48, 0)
    end

    if y < 1.1754943508222875E-38 and y > -1.1754943508222875E-38 and y ~= 0 then
        buffer.writeu32(v48, 0, to_bits(y))
        y2 = buffer.readf32(v48, 0)
    end

    if z < 1.1754943508222875E-38 and z > -1.1754943508222875E-38 and z ~= 0 then
        buffer.writeu32(v48, 0, to_bits(z))
        z2 = buffer.readf32(v48, 0)
    end

    x = orientation_displacement.w
    y = p21.inverse_mass
    z = p20.kinetic_energy

    local v142 = create(x, y, z)
    local x3, y3, z3 = v142.x, v142.y, v142.z

    if x < 1.1754943508222875E-38 and x > -1.1754943508222875E-38 and x ~= 0 then
        buffer.writeu32(v48, 0, to_bits(x))
        x3 = buffer.readf32(v48, 0)
    end

    if y < 1.1754943508222875E-38 and y > -1.1754943508222875E-38 and y ~= 0 then
        buffer.writeu32(v48, 0, to_bits(y))
        y3 = buffer.readf32(v48, 0)
    end

    if z < 1.1754943508222875E-38 and z > -1.1754943508222875E-38 and z ~= 0 then
        buffer.writeu32(v48, 0, to_bits(z))
        z3 = buffer.readf32(v48, 0)
    end

    orientation_displacement = p20.position
    x = orientation_displacement.x
    y = orientation_displacement.y
    z = orientation_displacement.z

    local v143 = create(x, y, z)
    local x4, y4, z4 = v143.x, v143.y, v143.z

    if x < 1.1754943508222875E-38 and x > -1.1754943508222875E-38 and x ~= 0 then
        buffer.writeu32(v48, 0, to_bits(x))
        x4 = buffer.readf32(v48, 0)
    end

    if y < 1.1754943508222875E-38 and y > -1.1754943508222875E-38 and y ~= 0 then
        buffer.writeu32(v48, 0, to_bits(y))
        y4 = buffer.readf32(v48, 0)
    end

    if z < 1.1754943508222875E-38 and z > -1.1754943508222875E-38 and z ~= 0 then
        buffer.writeu32(v48, 0, to_bits(z))
        z4 = buffer.readf32(v48, 0)
    end

    orientation_displacement = p20.linear_velocity
    x = orientation_displacement.x
    y = orientation_displacement.y
    z = orientation_displacement.z

    local v144 = create(x, y, z)
    local x5, y5, z5 = v144.x, v144.y, v144.z

    if x < 1.1754943508222875E-38 and x > -1.1754943508222875E-38 and x ~= 0 then
        buffer.writeu32(v48, 0, to_bits(x))
        x5 = buffer.readf32(v48, 0)
    end

    if y < 1.1754943508222875E-38 and y > -1.1754943508222875E-38 and y ~= 0 then
        buffer.writeu32(v48, 0, to_bits(y))
        y5 = buffer.readf32(v48, 0)
    end

    if z < 1.1754943508222875E-38 and z > -1.1754943508222875E-38 and z ~= 0 then
        buffer.writeu32(v48, 0, to_bits(z))
        z5 = buffer.readf32(v48, 0)
    end

    orientation_displacement = p20.angular_velocity
    x = orientation_displacement.x
    y = orientation_displacement.y
    z = orientation_displacement.z

    local v145 = create(x, y, z)
    local x6, y6, z6 = v145.x, v145.y, v145.z

    if x < 1.1754943508222875E-38 and x > -1.1754943508222875E-38 and x ~= 0 then
        buffer.writeu32(v48, 0, to_bits(x))
        x6 = buffer.readf32(v48, 0)
    end

    if y < 1.1754943508222875E-38 and y > -1.1754943508222875E-38 and y ~= 0 then
        buffer.writeu32(v48, 0, to_bits(y))
        y6 = buffer.readf32(v48, 0)
    end

    if z < 1.1754943508222875E-38 and z > -1.1754943508222875E-38 and z ~= 0 then
        buffer.writeu32(v48, 0, to_bits(z))
        z6 = buffer.readf32(v48, 0)
    end

    orientation_displacement = p20.force_acceleration
    x = orientation_displacement.x
    y = orientation_displacement.y
    z = orientation_displacement.z

    local v146 = create(x, y, z)
    local x7, y7, z7 = v146.x, v146.y, v146.z

    if x < 1.1754943508222875E-38 and x > -1.1754943508222875E-38 and x ~= 0 then
        buffer.writeu32(v48, 0, to_bits(x))
        x7 = buffer.readf32(v48, 0)
    end

    if y < 1.1754943508222875E-38 and y > -1.1754943508222875E-38 and y ~= 0 then
        buffer.writeu32(v48, 0, to_bits(y))
        y7 = buffer.readf32(v48, 0)
    end

    if z < 1.1754943508222875E-38 and z > -1.1754943508222875E-38 and z ~= 0 then
        buffer.writeu32(v48, 0, to_bits(z))
        z7 = buffer.readf32(v48, 0)
    end

    orientation_displacement = p20.torque_acceleration
    x = orientation_displacement.x
    y = orientation_displacement.y
    z = orientation_displacement.z

    local v147 = create(x, y, z)
    local x8, y8, z8 = v147.x, v147.y, v147.z

    if x < 1.1754943508222875E-38 and x > -1.1754943508222875E-38 and x ~= 0 then
        buffer.writeu32(v48, 0, to_bits(x))
        x8 = buffer.readf32(v48, 0)
    end

    if y < 1.1754943508222875E-38 and y > -1.1754943508222875E-38 and y ~= 0 then
        buffer.writeu32(v48, 0, to_bits(y))
        y8 = buffer.readf32(v48, 0)
    end

    if z < 1.1754943508222875E-38 and z > -1.1754943508222875E-38 and z ~= 0 then
        buffer.writeu32(v48, 0, to_bits(z))
        z8 = buffer.readf32(v48, 0)
    end

    local cool_down = p20.cool_down

    orientation_displacement = p21.inverse_tensor
    x = orientation_displacement.x
    y = orientation_displacement.y
    z = orientation_displacement.z

    local v148 = create(x, y, z)
    local x9, y9, z9 = v148.x, v148.y, v148.z

    if x < 1.1754943508222875E-38 and x > -1.1754943508222875E-38 and x ~= 0 then
        buffer.writeu32(v48, 0, to_bits(x))
        x9 = buffer.readf32(v48, 0)
    end

    if y < 1.1754943508222875E-38 and y > -1.1754943508222875E-38 and y ~= 0 then
        buffer.writeu32(v48, 0, to_bits(y))
        y9 = buffer.readf32(v48, 0)
    end

    if z < 1.1754943508222875E-38 and z > -1.1754943508222875E-38 and z ~= 0 then
        buffer.writeu32(v48, 0, to_bits(z))
        z9 = buffer.readf32(v48, 0)
    end

    x = p21.spherical
    y = p21.maximum_linear_velocity
    z = p21.maximum_angular_velocity

    local v149 = create(x, y, z)
    local x10, y10, z10 = v149.x, v149.y, v149.z

    if x < 1.1754943508222875E-38 and x > -1.1754943508222875E-38 and x ~= 0 then
        buffer.writeu32(v48, 0, to_bits(x))
        x10 = buffer.readf32(v48, 0)
    end

    if y < 1.1754943508222875E-38 and y > -1.1754943508222875E-38 and y ~= 0 then
        buffer.writeu32(v48, 0, to_bits(y))
        y10 = buffer.readf32(v48, 0)
    end

    if z < 1.1754943508222875E-38 and z > -1.1754943508222875E-38 and z ~= 0 then
        buffer.writeu32(v48, 0, to_bits(z))
        z10 = buffer.readf32(v48, 0)
    end

    x = p21.linear_drag
    y = p21.angular_drag

    local v150 = create(x, y, 0)
    local x11, y11 = v150.x, v150.y

    if x < 1.1754943508222875E-38 and x > -1.1754943508222875E-38 and x ~= 0 then
        buffer.writeu32(v48, 0, to_bits(x))
        x11 = buffer.readf32(v48, 0)
    end

    if y < 1.1754943508222875E-38 and y > -1.1754943508222875E-38 and y ~= 0 then
        buffer.writeu32(v48, 0, to_bits(y))
        y11 = buffer.readf32(v48, 0)
    end

    orientation_displacement = p23.linear_displacement
    x = orientation_displacement.x
    y = orientation_displacement.y
    z = orientation_displacement.z

    local v151 = create(x, y, z)
    local v152, v153, v154 = v151.x, v151.y, v151.z

    if x < 1.1754943508222875E-38 and x > -1.1754943508222875E-38 and x ~= 0 then
        buffer.writeu32(v48, 0, to_bits(x))
        v152 = buffer.readf32(v48, 0)
    end

    if y < 1.1754943508222875E-38 and y > -1.1754943508222875E-38 and y ~= 0 then
        buffer.writeu32(v48, 0, to_bits(y))
        v153 = buffer.readf32(v48, 0)
    end

    if z < 1.1754943508222875E-38 and z > -1.1754943508222875E-38 and z ~= 0 then
        buffer.writeu32(v48, 0, to_bits(z))
        v154 = buffer.readf32(v48, 0)
    end

    orientation_displacement = p23.position_displacement
    x = orientation_displacement.x
    y = orientation_displacement.y
    z = orientation_displacement.z

    local v155 = create(x, y, z)
    local v156, v157, z11 = v155.x, v155.y, v155.z

    if x < 1.1754943508222875E-38 and x > -1.1754943508222875E-38 and x ~= 0 then
        buffer.writeu32(v48, 0, to_bits(x))
        v156 = buffer.readf32(v48, 0)
    end

    if y < 1.1754943508222875E-38 and y > -1.1754943508222875E-38 and y ~= 0 then
        buffer.writeu32(v48, 0, to_bits(y))
        v157 = buffer.readf32(v48, 0)
    end

    if z < 1.1754943508222875E-38 and z > -1.1754943508222875E-38 and z ~= 0 then
        buffer.writeu32(v48, 0, to_bits(z))
        z11 = buffer.readf32(v48, 0)
    end

    orientation_displacement = p23.angular_displacement
    x = orientation_displacement.x
    y = orientation_displacement.y
    z = orientation_displacement.z

    local v158 = create(x, y, z)
    local v159, v160, v161 = v158.x, v158.y, v158.z

    if x < 1.1754943508222875E-38 and x > -1.1754943508222875E-38 and x ~= 0 then
        buffer.writeu32(v48, 0, to_bits(x))
        v159 = buffer.readf32(v48, 0)
    end

    if y < 1.1754943508222875E-38 and y > -1.1754943508222875E-38 and y ~= 0 then
        buffer.writeu32(v48, 0, to_bits(y))
        v160 = buffer.readf32(v48, 0)
    end

    if z < 1.1754943508222875E-38 and z > -1.1754943508222875E-38 and z ~= 0 then
        buffer.writeu32(v48, 0, to_bits(z))
        v161 = buffer.readf32(v48, 0)
    end

    orientation_displacement = p23.orientation_displacement
    x = orientation_displacement.x
    y = orientation_displacement.y
    z = orientation_displacement.z

    local v162 = create(x, y, z)
    local x12, y12, z12 = v162.x, v162.y, v162.z

    if x < 1.1754943508222875E-38 and x > -1.1754943508222875E-38 and x ~= 0 then
        buffer.writeu32(v48, 0, to_bits(x))
        x12 = buffer.readf32(v48, 0)
    end

    if y < 1.1754943508222875E-38 and y > -1.1754943508222875E-38 and y ~= 0 then
        buffer.writeu32(v48, 0, to_bits(y))
        y12 = buffer.readf32(v48, 0)
    end

    if z < 1.1754943508222875E-38 and z > -1.1754943508222875E-38 and z ~= 0 then
        buffer.writeu32(v48, 0, to_bits(z))
        z12 = buffer.readf32(v48, 0)
    end

    local v163 = (x7 * time_step + x5) * time_step + v152

    v152 = (y7 * time_step + y5) * time_step + v153
    v153 = (z7 * time_step + z5) * time_step + v154
    v154 = (x8 * time_step + x6) * time_step + v159
    v159 = (y8 * time_step + y6) * time_step + v160
    v160 = (z8 * time_step + z6) * time_step + v161
    v161 = x4 + v156 + v163
    v156 = y4 + v157 + v152
    v157 = z4 + z11 + v153

    local v164 = v154 + x12
    local v165 = v159 + y12
    local v166 = v160 + z12

    z12 = -v166 * y2 + v165 * z2
    y12 = -v164 * z2 + v166 * x2
    x12 = -v165 * x2 + v164 * y2
    z11 = x2 + (v164 * x3 + z12) * 0.5
    z12 = y2 + (v165 * x3 + y12) * 0.5
    y12 = z2 + (v166 * x3 + x12) * 0.5
    x12 = x3 + (v164 * x2 + v165 * y2 + v166 * z2) * -0.5

    local v167 = z11 * z11 + z12 * z12 + y12 * y12 + x12 * x12

    z8 = 1 / math.sqrt(v167)
    y8 = z8 * z8
    z8 = z8 * 0.5 * (-v167 * y8 + 1) + z8
    y7 = z8 * z8
    z8 = z8 * 0.5 * (-v167 * y7 + 1) + z8

    local v168 = z11 * z8
    local v169 = z12 * z8
    local v170 = y12 * z8
    local v171 = x12 * z8
    local v172 = v168 * 1.4142135381698608
    local v173 = v169 * 1.4142135381698608
    local v174 = v170 * 1.4142135381698608
    local v175 = v171 * 1.4142135381698608

    y6 = -v172 * v172 + 0.5
    x6 = -v173 * v173 + 0.5
    z5 = -v174 * v174 + 0.5

    local v176 = v172 * v173
    local v177 = v173 * v174
    local v178 = v174 * v172
    local v179 = v175 * v174
    local v180 = v175 * v172
    local v181 = v175 * v173

    v167 = x6 + z5

    local v182 = v176 + v179
    local v183 = v178 - v181
    local v184 = v176 - v179
    local v185 = z5 + y6
    local v186 = v177 + v180
    local v187 = v178 + v181
    local v188 = v177 - v180
    local v189 = y6 + x6

    v178 = v167 * x9
    v179 = v182 * x9
    v180 = v183 * x9
    v181 = v184 * y9

    local v190 = v185 * y9
    local v191 = v186 * y9
    local v192 = v187 * z9
    local y13 = v188 * z9
    local z13 = v189 * z9

    v172 = v192 * v187 + (v178 * v167 + v181 * v184)
    v173 = y13 * v187 + (v179 * v167 + v190 * v184)
    v174 = z13 * v187 + (v180 * v167 + v191 * v184)
    v175 = v189 * z13 + (v183 * v180 + v186 * v191)
    v176 = v188 * y13 + (v182 * v179 + v185 * v190)
    v177 = v188 * z13 + (v182 * v180 + v185 * v191)
    z9 = p22.frequency
    y9 = z9 - y11

    if not (y9 > 0) then
        y9 = 0
    end

    y11 = z9 - x11

    if not (y11 > 0) then
        y11 = 0
    end

    v178 = v154 * y9
    v179 = v159 * y9
    v180 = v160 * y9
    v160 = v178 * v178 + v179 * v179 + v180 * v180
    v159 = z10 * z10

    if v159 < v160 then
        v154 = v159 / v160
        v181 = 1 / math.sqrt(v154)
        z9 = v181 * v181
        v181 = v181 * 0.5 * (-v154 * z9 + 1) + v181
        y5 = v181 * v181
        x11 = v154 * (v181 * 0.5 * (-v154 * y5 + 1) + v181)

        if v154 == 0 then
            x11 = 0
        end

        v178 *= x11
        v179 *= x11
        v180 *= x11
    else
        v159 = v160
    end

    v181 = v163 * y11
    v190 = v152 * y11
    v191 = v153 * y11
    v153 = v181 * v181 + v190 * v190 + v191 * v191
    v152 = y10 * y10

    if v152 < v153 then
        y11 = v152 / v153
        v192 = 1 / math.sqrt(y11)
        x4 = v192 * v192
        v192 = v192 * 0.5 * (-y11 * x4 + 1) + v192
        y2 = v192 * v192
        z10 = y11 * (v192 * 0.5 * (-y11 * y2 + 1) + v192)

        if y11 == 0 then
            z10 = 0
        end

        v181 *= z10
        v190 *= z10
        v191 *= z10
    else
        v152 = v153
    end

    x10 = x10 * y3 * v159 + v152

    local v193, x13

    if x10 < p22.minimum_energy then
        v193 = if z3 < x10 then cool_down else rt.wrapping_add_u32(cool_down, 1)
        x13 = p22.cool_down
        cool_down = math.min(v193, x13)
    else
        cool_down = 0
    end

    v192 = create(v168, v169, v170)
    v193 = v192.x
    y13 = v192.y
    z13 = v192.z

    if v168 < 1.1754943508222875E-38 and v168 > -1.1754943508222875E-38 and v168 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v168))
        v193 = buffer.readf32(v48, 0)
    end

    if v169 < 1.1754943508222875E-38 and v169 > -1.1754943508222875E-38 and v169 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v169))
        y13 = buffer.readf32(v48, 0)
    end

    if v170 < 1.1754943508222875E-38 and v170 > -1.1754943508222875E-38 and v170 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v170))
        z13 = buffer.readf32(v48, 0)
    end

    local v194 = create(v171, x10, 0)

    x13 = v194.x

    local y14 = v194.y

    if v171 < 1.1754943508222875E-38 and v171 > -1.1754943508222875E-38 and v171 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v171))
        x13 = buffer.readf32(v48, 0)
    end

    if x10 < 1.1754943508222875E-38 and x10 > -1.1754943508222875E-38 and x10 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(x10))
        y14 = buffer.readf32(v48, 0)
    end

    local v195 = create(v161, v156, v157)
    local x14, y15, z14 = v195.x, v195.y, v195.z

    if v161 < 1.1754943508222875E-38 and v161 > -1.1754943508222875E-38 and v161 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v161))
        x14 = buffer.readf32(v48, 0)
    end

    if v156 < 1.1754943508222875E-38 and v156 > -1.1754943508222875E-38 and v156 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v156))
        y15 = buffer.readf32(v48, 0)
    end

    if v157 < 1.1754943508222875E-38 and v157 > -1.1754943508222875E-38 and v157 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v157))
        z14 = buffer.readf32(v48, 0)
    end

    local v196 = create(v181, v190, v191)
    local x15, y16, z15 = v196.x, v196.y, v196.z

    if v181 < 1.1754943508222875E-38 and v181 > -1.1754943508222875E-38 and v181 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v181))
        x15 = buffer.readf32(v48, 0)
    end

    if v190 < 1.1754943508222875E-38 and v190 > -1.1754943508222875E-38 and v190 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v190))
        y16 = buffer.readf32(v48, 0)
    end

    if v191 < 1.1754943508222875E-38 and v191 > -1.1754943508222875E-38 and v191 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v191))
        z15 = buffer.readf32(v48, 0)
    end

    local v197 = create(v178, v179, v180)
    local x16, y17, z16 = v197.x, v197.y, v197.z

    if v178 < 1.1754943508222875E-38 and v178 > -1.1754943508222875E-38 and v178 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v178))
        x16 = buffer.readf32(v48, 0)
    end

    if v179 < 1.1754943508222875E-38 and v179 > -1.1754943508222875E-38 and v179 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v179))
        y17 = buffer.readf32(v48, 0)
    end

    if v180 < 1.1754943508222875E-38 and v180 > -1.1754943508222875E-38 and v180 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v180))
        z16 = buffer.readf32(v48, 0)
    end

    orientation_displacement = p22.gravity_acceleration
    x = orientation_displacement.x
    y = orientation_displacement.y
    z = orientation_displacement.z

    local v198 = create(x, y, z)
    local x17, y18, z17 = v198.x, v198.y, v198.z

    if x < 1.1754943508222875E-38 and x > -1.1754943508222875E-38 and x ~= 0 then
        buffer.writeu32(v48, 0, to_bits(x))
        x17 = buffer.readf32(v48, 0)
    end

    if y < 1.1754943508222875E-38 and y > -1.1754943508222875E-38 and y ~= 0 then
        buffer.writeu32(v48, 0, to_bits(y))
        y18 = buffer.readf32(v48, 0)
    end

    if z < 1.1754943508222875E-38 and z > -1.1754943508222875E-38 and z ~= 0 then
        buffer.writeu32(v48, 0, to_bits(z))
        z17 = buffer.readf32(v48, 0)
    end

    local v199 = create(v167, v182, v183)
    local x18, y19, z18 = v199.x, v199.y, v199.z

    if v167 < 1.1754943508222875E-38 and v167 > -1.1754943508222875E-38 and v167 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v167))
        x18 = buffer.readf32(v48, 0)
    end

    if v182 < 1.1754943508222875E-38 and v182 > -1.1754943508222875E-38 and v182 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v182))
        y19 = buffer.readf32(v48, 0)
    end

    if v183 < 1.1754943508222875E-38 and v183 > -1.1754943508222875E-38 and v183 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v183))
        z18 = buffer.readf32(v48, 0)
    end

    local v200 = create(v184, v185, v186)
    local x19, y20, z19 = v200.x, v200.y, v200.z

    if v184 < 1.1754943508222875E-38 and v184 > -1.1754943508222875E-38 and v184 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v184))
        x19 = buffer.readf32(v48, 0)
    end

    if v185 < 1.1754943508222875E-38 and v185 > -1.1754943508222875E-38 and v185 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v185))
        y20 = buffer.readf32(v48, 0)
    end

    if v186 < 1.1754943508222875E-38 and v186 > -1.1754943508222875E-38 and v186 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v186))
        z19 = buffer.readf32(v48, 0)
    end

    local v201 = create(v187, v188, v189)
    local x20, y21, z20 = v201.x, v201.y, v201.z

    if v187 < 1.1754943508222875E-38 and v187 > -1.1754943508222875E-38 and v187 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v187))
        x20 = buffer.readf32(v48, 0)
    end

    if v188 < 1.1754943508222875E-38 and v188 > -1.1754943508222875E-38 and v188 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v188))
        y21 = buffer.readf32(v48, 0)
    end

    if v189 < 1.1754943508222875E-38 and v189 > -1.1754943508222875E-38 and v189 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v189))
        z20 = buffer.readf32(v48, 0)
    end

    local v202 = create(v172, v173, v174)
    local x21, y22, z21 = v202.x, v202.y, v202.z

    if v172 < 1.1754943508222875E-38 and v172 > -1.1754943508222875E-38 and v172 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v172))
        x21 = buffer.readf32(v48, 0)
    end

    if v173 < 1.1754943508222875E-38 and v173 > -1.1754943508222875E-38 and v173 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v173))
        y22 = buffer.readf32(v48, 0)
    end

    if v174 < 1.1754943508222875E-38 and v174 > -1.1754943508222875E-38 and v174 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v174))
        z21 = buffer.readf32(v48, 0)
    end

    local v203 = create(v175, v176, v177)
    local x22, y23, z22 = v203.x, v203.y, v203.z

    if v175 < 1.1754943508222875E-38 and v175 > -1.1754943508222875E-38 and v175 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v175))
        x22 = buffer.readf32(v48, 0)
    end

    if v176 < 1.1754943508222875E-38 and v176 > -1.1754943508222875E-38 and v176 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v176))
        y23 = buffer.readf32(v48, 0)
    end

    if v177 < 1.1754943508222875E-38 and v177 > -1.1754943508222875E-38 and v177 ~= 0 then
        buffer.writeu32(v48, 0, to_bits(v177))
        z22 = buffer.readf32(v48, 0)
    end

    if p24 ~= nil then
        v191 = p24.rates
        v190 = p24.orientation
        v190.x = v193
        v190.y = y13
        v190.z = z13
        v190.w = x13
        v191.orientation = v190
        v190 = p24.position
        v190.x = x14
        v190.y = y15
        v190.z = z14
        v191.position = v190
        v190 = p24.linear_velocity
        v190.x = x15
        v190.y = y16
        v190.z = z15
        v191.linear_velocity = v190
        v190 = p24.angular_velocity
        v190.x = x16
        v190.y = y17
        v190.z = z16
        v191.angular_velocity = v190
        v190 = p24.force_acceleration
        v190.x = x17
        v190.y = y18
        v190.z = z17
        v191.force_acceleration = v190
        v190 = p24.torque_acceleration
        v190.x = 0
        v190.y = 0
        v190.z = 0
        v191.torque_acceleration = v190
        v191.kinetic_energy = y14
        v191.cool_down = cool_down
        v181 = p24.basis_columns
        v180 = p24.basis_1
        v180[1] = x18
        v180[2] = y19
        v180[3] = z18
        v181[1] = v180
        v180 = p24.basis_2
        v180[1] = x19
        v180[2] = y20
        v180[3] = z19
        v181[2] = v180
        v180 = p24.basis_3
        v180[1] = x20
        v180[2] = y21
        v180[3] = z20
        v181[3] = v180
        v190 = p24.basis
        v190.columns = v181
        v191.basis = v190
        v181 = p24.inertia_columns
        v180 = p24.inertia_1
        v180[1] = x21
        v180[2] = y22
        v180[3] = z21
        v181[1] = v180
        v180 = p24.inertia_2
        v180[1] = y22
        v180[2] = y23
        v180[3] = z22
        v181[2] = v180
        v180 = p24.inertia_3
        v180[1] = z21
        v180[2] = z22
        v180[3] = x22
        v181[3] = v180
        v190 = p24.world_inverse_inertia
        v190.columns = v181
        v191.world_inverse_inertia = v190

        return v191, v164, v165, v166, v152, v159
    end

    v137.orientation = {
        x = v193,
        y = y13,
        z = z13,
        w = x13
    }
    v137.position = Vector3.new(x14, y15, z14)
    v137.linear_velocity = Vector3.new(x15, y16, z15)
    v137.angular_velocity = Vector3.new(x16, y17, z16)
    v137.force_acceleration = Vector3.new(x17, y18, z17)
    v137.torque_acceleration = Vector3.new(0, 0, 0)
    v137.kinetic_energy = y14
    v137.cool_down = cool_down
    v137.basis = {
        columns = {
            { x18, y19, z18 },
            { x19, y20, z19 },
            { x20, y21, z20 }
        }
    }
    v137.world_inverse_inertia = {
        columns = {
            { x21, y22, z21 },
            { y22, y23, z22 },
            { z21, z22, x22 }
        }
    }

    return v137, v164, v165, v166, v152, v159
end

t1.integrate_core = integrate_core
t1.integrate_core_r3 = integrate_core_r3

function t1.integrate_body_rates(p25, p26, p27, p28) -- line: 1111
    -- upvalues: Vector3 (copy), integrate_core (copy)
    local v204, v205, v206, v207, v208, v209 = integrate_core(p25, p26, p27, p28, nil)

    return {
        state = v204,
        orientation_displacement = Vector3.new(v205, v206, v207),
        linear_speed_squared = v208,
        angular_speed_squared = v209
    }
end

function t1.rates_buffer() -- line: 1129
    -- upvalues: Vector3 (copy)
    local v210 = table.create(3)
    local v211 = table.create(3)

    return {
        rates = {},
        orientation = {
            x = 0,
            y = 0,
            z = 0,
            w = 1
        },
        position = Vector3.new(0, 0, 0),
        linear_velocity = Vector3.new(0, 0, 0),
        angular_velocity = Vector3.new(0, 0, 0),
        force_acceleration = Vector3.new(0, 0, 0),
        torque_acceleration = Vector3.new(0, 0, 0),
        basis = {
            columns = v210
        },
        basis_columns = v210,
        basis_1 = { 0, 0, 0 },
        basis_2 = { 0, 0, 0 },
        basis_3 = { 0, 0, 0 },
        world_inverse_inertia = {
            columns = v211
        },
        inertia_columns = v211,
        inertia_1 = { 0, 0, 0 },
        inertia_2 = { 0, 0, 0 },
        inertia_3 = { 0, 0, 0 }
    }
end

function t1.integrate_body_rates_into(p29, p30, p31, p32, p33) -- line: 1160
    -- upvalues: integrate_core (copy)
    return (integrate_core(p30, p31, p32, p33, p29))
end

function t1.integrate_body_rates_state(p34, p35, p36, p37) -- line: 1171
    -- upvalues: integrate_core (copy)
    return (integrate_core(p34, p35, p36, p37, nil))
end

function t1.integrate_orientation(p38, p39) -- line: 1189
    -- upvalues: v9 (copy)
    local v212 = v9.orientation({
        p38.x,
        p38.y,
        p38.z,
        p38.w
    }, {
        p39.x,
        p39.y,
        p39.z,
        0
    })

    return {
        x = v212[1],
        y = v212[2],
        z = v212[3],
        w = v212[4]
    }
end

function t1.basis_from_quaternion_reference(p40) -- line: 1204
    -- upvalues: v9 (copy)
    local v213 = v9.quaternion_basis({
        p40.x,
        p40.y,
        p40.z,
        p40.w
    })
    local t6 = {}

    for v214, v215 in ipairs(v213) do
        t6[v214] = {
            v215[1],
            v215[2],
            v215[3]
        }
    end

    return {
        columns = t6
    }
end

function t1.basis_from_quaternion_xyzw(p41, p42, p43, p44) -- line: 1224
    local v216 = p41 * 1.4142135381698608
    local v217 = p42 * 1.4142135381698608
    local v218 = p43 * 1.4142135381698608
    local v219 = p44 * 1.4142135381698608
    local v220 = -v216 * v216 + 0.5
    local v221 = -v217 * v217 + 0.5
    local v222 = -v218 * v218 + 0.5
    local v223 = v216 * v217
    local v224 = v217 * v218
    local v225 = v218 * v216
    local v226 = v219 * v218
    local v227 = v219 * v216
    local v228 = v219 * v217

    return v221 + v222, v223 + v226, v225 - v228, v223 - v226, v222 + v220, v224 + v227, v225 + v228, v224 - v227, v220 + v221
end

local basis_from_quaternion_xyzw2 = t1.basis_from_quaternion_xyzw

function t1.basis_from_quaternion_into(p45, p46, p47, p48, p49, p50, p51) -- line: 1236
    -- upvalues: basis_from_quaternion_xyzw2 (copy)
    local v229, v230, v231, v232, v233, v234, v235, v236, v237 = basis_from_quaternion_xyzw2(p48, p49, p50, p51)

    p45[1] = v229
    p45[2] = v230
    p45[3] = v231
    p46[1] = v232
    p46[2] = v233
    p46[3] = v234
    p47[1] = v235
    p47[2] = v236
    p47[3] = v237
end

function t1.basis_from_quaternion(p52) -- line: 1240
    -- upvalues: basis_from_quaternion_xyzw2 (copy)
    local v238, v239, v240, v241, v242, v243, v244, v245, v246 = basis_from_quaternion_xyzw2(p52.x, p52.y, p52.z, p52.w)

    return {
        columns = {
            { v238, v239, v240 },
            { v241, v242, v243 },
            { v244, v245, v246 }
        }
    }
end

function t1.world_inverse_inertia(p53, p54) -- line: 1251
    -- upvalues: v1 (copy), Vector3 (copy), v9 (copy), t1 (copy)
    local t7 = {}

    for v247, v248 in ipairs(p53.columns) do
        t7[v247] = {
            v248[1],
            v248[2],
            v248[3],
            0
        }
    end

    local x = p54.x
    local v249

    if x ~= 0 and x > -1.1754943508222875E-38 and x < 1.1754943508222875E-38 then
        local v250 = math.abs(x) * 7.1362384635298E+44
        local v251 = math.floor(v250)
        local v252 = v250 - v251

        v249 = if v252 > 0.5 or v252 == 0.5 and v251 % 2 == 1 then v251 + 1 else v251

        if x < 0 then
            v249 += 2147483648
        end
    else
        buffer.writef32(v1, 0, x)
        v249 = buffer.readu32(v1, 0)
    end

    local y = p54.y
    local v253

    if y ~= 0 and y > -1.1754943508222875E-38 and y < 1.1754943508222875E-38 then
        local v254 = math.abs(y) * 7.1362384635298E+44
        local v255 = math.floor(v254)
        local v256 = v254 - v255

        v253 = if v256 > 0.5 or v256 == 0.5 and v255 % 2 == 1 then v255 + 1 else v255

        if y < 0 then
            v253 += 2147483648
        end
    else
        buffer.writef32(v1, 0, y)
        v253 = buffer.readu32(v1, 0)
    end

    local z = p54.z
    local v257

    if z ~= 0 and z > -1.1754943508222875E-38 and z < 1.1754943508222875E-38 then
        local v258 = math.abs(z) * 7.1362384635298E+44
        local v259 = math.floor(v258)
        local v260 = v258 - v259

        v257 = if v260 > 0.5 or v260 == 0.5 and v259 % 2 == 1 then v259 + 1 else v259

        if z < 0 then
            v257 += 2147483648
        end
    else
        buffer.writef32(v1, 0, z)
        v257 = buffer.readu32(v1, 0)
    end

    local t8 = {
        v249,
        v253,
        v257
    }
    local v261, v262 = v9.inverse_inertia(t7, t8)

    return t1.unpack_world_inverse_inertia(Vector3.new(v261[1], v261[2], v261[3]), Vector3.new(v262[1], v262[2], v262[3]))
end

function t1.unpack_world_inverse_inertia(p55, p56) -- line: 1268
    return {
        columns = {
            {
                p55.x,
                p55.y,
                p55.z
            },
            {
                p55.y,
                p56.y,
                p56.z
            },
            {
                p55.z,
                p56.z,
                p56.x
            }
        }
    }
end

function t1.pack_world_inverse_inertia(p57) -- line: 1280
    -- upvalues: Vector3 (copy)
    return {
        full = Vector3.new(p57.columns[1][1], p57.columns[2][1], p57.columns[3][1]),
        split = Vector3.new(p57.columns[3][3], p57.columns[2][2], p57.columns[3][2])
    }
end

function t1.multiply_packed_world_inverse_inertia(p58, p59) -- line: 1289
    -- upvalues: Vector3 (copy)
    return Vector3.new(p58.full.x * p59.x + p58.full.y * p59.y + p58.full.z * p59.z, p58.full.y * p59.x + p58.split.y * p59.y + p58.split.z * p59.z, p58.full.z * p59.x + p58.split.z * p59.y + p58.split.x * p59.z)
end

return t1
