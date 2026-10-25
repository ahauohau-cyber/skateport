-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

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

require(sim.import)

local t1 = {}

function t1.encode(p3) -- line: 32
    -- upvalues: v1 (copy), t1 (copy)
    local v8 = table.create(64, 0)
    local v9 = t1.lanes(p3.position_on_a, p3.body_a_id)
    local v10 = t1.lanes(p3.position_on_b, p3.body_b_id)
    local lanes = t1.lanes
    local normal, restitution = p3.normal, p3.restitution
    local v11

    if restitution ~= 0 and restitution > -1.1754943508222875E-38 and restitution < 1.1754943508222875E-38 then
        local v12 = math.abs(restitution) * 7.1362384635298E+44
        local v13 = math.floor(v12)
        local v14 = v12 - v13

        v11 = if v14 > 0.5 or v14 == 0.5 and v13 % 2 == 1 then v13 + 1 else v13

        if restitution < 0 then
            v11 += 2147483648
        end
    else
        buffer.writef32(v1, 0, restitution)
        v11 = buffer.readu32(v1, 0)
    end

    local v15 = lanes(normal, v11)
    local lanes2 = t1.lanes
    local tangent_0, static_friction = p3.tangent_0, p3.static_friction
    local v16

    if static_friction ~= 0 and static_friction > -1.1754943508222875E-38 and static_friction < 1.1754943508222875E-38 then
        local v17 = math.abs(static_friction) * 7.1362384635298E+44
        local v18 = math.floor(v17)
        local v19 = v17 - v18

        v16 = if v19 > 0.5 or v19 == 0.5 and v18 % 2 == 1 then v18 + 1 else v18

        if static_friction < 0 then
            v16 += 2147483648
        end
    else
        buffer.writef32(v1, 0, static_friction)
        v16 = buffer.readu32(v1, 0)
    end

    local v20 = lanes2(tangent_0, v16)
    local lanes3 = t1.lanes
    local tangent_1, dynamic_friction = p3.tangent_1, p3.dynamic_friction
    local v21

    if dynamic_friction ~= 0 and dynamic_friction > -1.1754943508222875E-38 and dynamic_friction < 1.1754943508222875E-38 then
        local v22 = math.abs(dynamic_friction) * 7.1362384635298E+44
        local v23 = math.floor(v22)
        local v24 = v22 - v23

        v21 = if v24 > 0.5 or v24 == 0.5 and v23 % 2 == 1 then v23 + 1 else v23

        if dynamic_friction < 0 then
            v21 += 2147483648
        end
    else
        buffer.writef32(v1, 0, dynamic_friction)
        v21 = buffer.readu32(v1, 0)
    end

    local t2 = {
        v9,
        v10,
        v15,
        v20,
        lanes3(tangent_1, v21),
        t1.lanes(p3.relative_velocity, p3.tag)
    }

    for i = 0, #t2 - 1 do
        local v25 = t2[i + 1]

        v8[i * 4 + 0 + 1] = v25[1]
        v8[i * 4 + 1 + 1] = v25[2]
        v8[i * 4 + 2 + 1] = v25[3]
        v8[i * 4 + 3 + 1] = v25[4]
    end

    local v26 = t1.workspace(p3.body_a_workspace)
    local v27 = t1.workspace(p3.body_b_workspace)

    for i = 0, 4 do
        local v28 = v26[i + 1]
        local v29 = v27[i + 1]

        v8[i * 8 + 24 + 0 + 1] = v28[1]
        v8[i * 8 + 24 + 1 + 1] = v28[2]
        v8[i * 8 + 24 + 2 + 1] = v28[3]
        v8[i * 8 + 24 + 3 + 1] = v28[4]
        v8[i * 8 + 28 + 0 + 1] = v29[1]
        v8[i * 8 + 28 + 1 + 1] = v29[2]
        v8[i * 8 + 28 + 2 + 1] = v29[3]
        v8[i * 8 + 28 + 3 + 1] = v29[4]
    end

    return v8
end

function t1.lanes(p4, p5) -- line: 66
    -- upvalues: v1 (copy)
    local x = p4.x
    local v30

    if x ~= 0 and x > -1.1754943508222875E-38 and x < 1.1754943508222875E-38 then
        local v31 = math.abs(x) * 7.1362384635298E+44
        local v32 = math.floor(v31)
        local v33 = v31 - v32

        v30 = if v33 > 0.5 or v33 == 0.5 and v32 % 2 == 1 then v32 + 1 else v32

        if x < 0 then
            v30 += 2147483648
        end
    else
        buffer.writef32(v1, 0, x)
        v30 = buffer.readu32(v1, 0)
    end

    local y = p4.y
    local v34

    if y ~= 0 and y > -1.1754943508222875E-38 and y < 1.1754943508222875E-38 then
        local v35 = math.abs(y) * 7.1362384635298E+44
        local v36 = math.floor(v35)
        local v37 = v35 - v36

        v34 = if v37 > 0.5 or v37 == 0.5 and v36 % 2 == 1 then v36 + 1 else v36

        if y < 0 then
            v34 += 2147483648
        end
    else
        buffer.writef32(v1, 0, y)
        v34 = buffer.readu32(v1, 0)
    end

    local z = p4.z
    local v38

    if z ~= 0 and z > -1.1754943508222875E-38 and z < 1.1754943508222875E-38 then
        local v39 = math.abs(z) * 7.1362384635298E+44
        local v40 = math.floor(v39)
        local v41 = v39 - v40

        v38 = if v41 > 0.5 or v41 == 0.5 and v40 % 2 == 1 then v40 + 1 else v40

        if z < 0 then
            v38 += 2147483648
        end
    else
        buffer.writef32(v1, 0, z)
        v38 = buffer.readu32(v1, 0)
    end

    return {
        v30,
        v34,
        v38,
        p5
    }
end

function t1.workspace(p6) -- line: 71
    -- upvalues: v1 (copy), t1 (copy)
    local v42 = t1.lanes(p6.center_of_mass, p6.reaction_id)
    local lanes = t1.lanes
    local inverse_inertia_full, inverse_mass = p6.inverse_inertia_full, p6.inverse_mass
    local v43

    if inverse_mass ~= 0 and inverse_mass > -1.1754943508222875E-38 and inverse_mass < 1.1754943508222875E-38 then
        local v44 = math.abs(inverse_mass) * 7.1362384635298E+44
        local v45 = math.floor(v44)
        local v46 = v44 - v45

        v43 = if v46 > 0.5 or v46 == 0.5 and v45 % 2 == 1 then v45 + 1 else v45

        if inverse_mass < 0 then
            v43 += 2147483648
        end
    else
        buffer.writef32(v1, 0, inverse_mass)
        v43 = buffer.readu32(v1, 0)
    end

    local v47 = lanes(inverse_inertia_full, v43)
    local v48 = t1.lanes(p6.inverse_inertia_split, p6.state)
    local lanes2 = t1.lanes
    local force_acceleration, kinetic_energy = p6.force_acceleration, p6.kinetic_energy
    local v49

    if kinetic_energy == 0 or not (kinetic_energy > -1.1754943508222875E-38) or not (kinetic_energy < 1.1754943508222875E-38) then
        buffer.writef32(v1, 0, kinetic_energy)
        v49 = buffer.readu32(v1, 0)

        return {
            v42,
            v47,
            v48,
            lanes2(force_acceleration, v49),
            t1.lanes(p6.torque_acceleration, p6.cool_down)
        }
    end

    local v50 = math.abs(kinetic_energy) * 7.1362384635298E+44
    local v51 = math.floor(v50)
    local v52 = v50 - v51

    v49 = if v52 > 0.5 or v52 == 0.5 and v51 % 2 == 1 then v51 + 1 else v51

    if kinetic_energy < 0 then
        v49 += 2147483648
    end

    return {
        v42,
        v47,
        v48,
        lanes2(force_acceleration, v49),
        t1.lanes(p6.torque_acceleration, p6.cool_down)
    }
end

return t1
