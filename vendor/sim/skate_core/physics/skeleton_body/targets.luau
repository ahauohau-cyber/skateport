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
local v8 = import("skate_core/physics/board_pose")
local orthonormalize_rotation = v8.orthonormalize_rotation
local initialized_body = import("skate_core/physics/board_runtime").initialized_body
local retail_quaternion_from_basis = import("skate_core/physics/drive_frames").retail_quaternion_from_basis
local RetailDriveType = import("skate_core/physics/drive_parameters").RetailDriveType
local RetailQuaternion = import("skate_core/physics/rigid_body").RetailQuaternion
local IDENTITY = import("skate_core/physics/skeleton_animation_record").IDENTITY
local v9 = import("skate_core/physics/skeleton_body/target_update")
local t1 = {}
local to_bits, from_bits = rt.to_bits, rt.from_bits
local v10 = table.create(16)

for i = 0, 3 do
    local v11 = IDENTITY[i + 1]

    for j = 0, 3 do
        local v12 = i * 4 + j + 1
        local v13 = v11[j + 1]

        if v13 ~= 0 and v13 > -1.1754943508222875E-38 and v13 < 1.1754943508222875E-38 then
            local v14 = math.abs(v13) * 7.1362384635298E+44
            local v15 = math.floor(v14)
            local v16 = v14 - v15
            local v17 = if v16 > 0.5 or v16 == 0.5 and v15 % 2 == 1 then v15 + 1 else v15

            if v13 < 0 then
                v10[v12] = v17 + 2147483648
            else
                v10[v12] = v17
            end
        else
            buffer.writef32(v1, 0, v13)
            v10[v12] = buffer.readu32(v1, 0)
        end
    end
end

t1.TARGET_COUNT = 4
t1.TARGET_PARTS = { 23, 0, 24, 25 }
t1.HARD_VELOCITY = 599.9999389648438
t1.HARD_STRENGTH = 35999.99609375
t1.SkeletonTargets = {}

function t1.SkeletonTargets.new(p4) -- line: 76
    -- upvalues: rt (copy), Vector3 (copy), v8 (copy), initialized_body (copy), retail_quaternion_from_basis (copy), RetailQuaternion (copy), IDENTITY (copy), t1 (copy)
    local v18 = rt.from_fn(t1.TARGET_COUNT, function(_) -- line: 77
        -- upvalues: p4 (copy), v8 (copy), initialized_body (copy), IDENTITY (copy), t1 (copy)
        local t2 = {
            inertia = nil,
            transform = t1.words(IDENTITY),
            local_mass_frame = t1.words(IDENTITY),
            body = table.create(44, 0)
        }

        v8.set_part_transform(t2, t1.words(IDENTITY))

        return initialized_body(t2, t1.STATIC_INERTIA, p4, "Static")
    end)
    local t3 = {
        orientation = rt.copy(RetailQuaternion.IDENTITY),
        translation = rt.copy(Vector3.ZERO)
    }
    local t4 = {
        orientation = retail_quaternion_from_basis({
            columns = {
                { 0, 1, 0 },
                { 0, 0, 1 },
                { 1, 0, 0 }
            }
        }),
        translation = rt.copy(t3.translation)
    }
    local v19 = rt.from_fn(t1.TARGET_COUNT, function(p6) -- line: 101
        -- upvalues: t3 (copy), t4 (copy), rt (copy)
        return {
            body_a = if p6 >= 2 then rt.copy(t4) else rt.copy(t3),
            body_b = rt.copy(t3)
        }
    end)
    local v20 = t1.hard(t1.HARD_VELOCITY, t1.HARD_STRENGTH)
    local v21 = t1.hard(59.999996185302734, t1.HARD_STRENGTH)

    return {
        bodies = v18,
        frames = v19,
        dynamics = {
            {
                linear = rt.copy(v20),
                angular = rt.copy(v20)
            },
            {
                linear = rt.copy(v21),
                angular = rt.copy(v21)
            },
            {
                linear = t1.hard(0, 0),
                angular = rt.copy(v20)
            },
            {
                linear = t1.hard(0, 0),
                angular = rt.copy(v20)
            }
        }
    }
end

function t1.SkeletonTargets.reset(p7, p8, p9) -- line: 135
    -- upvalues: orthonormalize_rotation (copy), t1 (copy)
    local t6 = {
        p8,
        p9
    }

    for i = 0, 1 do
        local v22 = t6[i + 1]

        t1.SkeletonTargets.set_transform(p7, i, t1.floats(orthonormalize_rotation(t1.words(v22))))
    end
end

local v23 = table.create(16, 0)
local v24 = table.create(44, 0)
local t7 = {
    inertia = nil,
    transform = v23,
    local_mass_frame = v10,
    body = v24
}

function t1.SkeletonTargets.set_transform(p10, p11, p12) -- line: 182
    -- upvalues: v8 (copy), to_bits (copy), from_bits (copy), v23 (copy), v24 (copy), t7 (copy)
    local v25 = p10.bodies[p11 + 1]
    local v26 = p12[1]
    local v27 = p12[2]
    local v28 = p12[3]
    local v29 = p12[4]
    local v30 = to_bits(v26[1])
    local v31 = to_bits(v26[2])
    local v32 = to_bits(v26[3])
    local v33 = to_bits(v26[4])

    v23[1] = v30
    v23[2] = v31
    v23[3] = v32
    v23[4] = v33

    local v34 = to_bits(v27[1])
    local v35 = to_bits(v27[2])
    local v36 = to_bits(v27[3])
    local v37 = to_bits(v27[4])

    v23[5] = v34
    v23[6] = v35
    v23[7] = v36
    v23[8] = v37

    local v38 = to_bits(v28[1])
    local v39 = to_bits(v28[2])
    local v40 = to_bits(v28[3])
    local v41 = to_bits(v28[4])

    v23[9] = v38
    v23[10] = v39
    v23[11] = v40
    v23[12] = v41

    local v42 = to_bits(v29[1])
    local v43 = to_bits(v29[2])
    local v44 = to_bits(v29[3])
    local v45 = to_bits(v29[4])

    v23[13] = v42
    v23[14] = v43
    v23[15] = v44
    v23[16] = v45
    t7.transform = v23
    t7.body = v24
    v8.set_part_transform(t7, v23)
    t7.transform = v23

    local body = t7.body

    if body == nil then
        error("Target has an actual rigid body", 0)
    end

    local rates = v25.rates

    rates.orientation = {
        x = from_bits(body[1]),
        y = from_bits(body[2]),
        z = from_bits(body[3]),
        w = from_bits(body[4])
    }
    rates.position = {
        x = from_bits(body[5]),
        y = from_bits(body[6]),
        z = from_bits(body[7])
    }
    rates.basis = {
        columns = {
            {
                from_bits(body[17]),
                from_bits(body[18]),
                from_bits(body[19])
            },
            {
                from_bits(body[21]),
                from_bits(body[22]),
                from_bits(body[23])
            },
            {
                from_bits(body[25]),
                from_bits(body[26]),
                from_bits(body[27])
            }
        }
    }
end

function t1.SkeletonTargets.set_transform_reference(p13, p14, p15) -- line: 221
    -- upvalues: v1 (copy), Vector3 (copy), v8 (copy), IDENTITY (copy), t1 (copy)
    local v46 = p13.bodies[p14 + 1]
    local t8 = {
        inertia = nil,
        transform = t1.words(p15),
        local_mass_frame = t1.words(IDENTITY),
        body = table.create(44, 0)
    }

    v8.set_part_transform(t8, t1.words(p15))

    local body = t8.body

    if body == nil then
        error("Target has an actual rigid body", 0)
    end

    local function f(p16) -- line: 234
        -- upvalues: body (copy), v1 (copy)
        buffer.writeu32(v1, 0, body[p16 + 1])

        return (buffer.readf32(v1, 0))
    end

    local rates = v46.rates
    local t9 = {}

    buffer.writeu32(v1, 0, body[1])
    t9.x = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, body[2])
    t9.y = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, body[3])
    t9.z = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, body[4])
    t9.w = buffer.readf32(v1, 0)
    rates.orientation = t9

    local rates2 = v46.rates
    local new = Vector3.new

    buffer.writeu32(v1, 0, body[5])

    local v53 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, body[6])

    local v55 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, body[7])
    rates2.position = new(v53, v55, (buffer.readf32(v1, 0)))

    local rates3 = v46.rates
    local t10 = {}

    buffer.writeu32(v1, 0, body[17])

    local v58 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, body[18])

    local v60 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, body[19])

    local t11 = {
        v58,
        v60,
        (buffer.readf32(v1, 0))
    }

    buffer.writeu32(v1, 0, body[21])

    local v63 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, body[22])

    local v65 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, body[23])

    local t12 = {
        v63,
        v65,
        (buffer.readf32(v1, 0))
    }

    buffer.writeu32(v1, 0, body[25])

    local v68 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, body[26])

    local v70 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, body[27])
    t10.columns = {
        t11,
        t12,
        {
            v68,
            v70,
            (buffer.readf32(v1, 0))
        }
    }
    rates3.basis = t10
end

function t1.SkeletonTargets.transform(p17, p18) -- line: 257
    local rates = p17.bodies[p18 + 1].rates
    local columns = rates.basis.columns
    local v72 = columns[1]
    local v73 = columns[2]
    local v74 = columns[3]
    local position = rates.position

    return {
        {
            v72[1],
            v72[2],
            v72[3],
            0
        },
        {
            v73[1],
            v73[2],
            v73[3],
            0
        },
        {
            v74[1],
            v74[2],
            v74[3],
            0
        },
        {
            position.x,
            position.y,
            position.z,
            0
        }
    }
end

function t1.SkeletonTargets.transform_reference(p19, p20) -- line: 273
    -- upvalues: rt (copy), IDENTITY (copy)
    local v75 = rt.copy(p19.bodies[p20 + 1])
    local v76 = rt.copy(IDENTITY)

    for i = 0, 2 do
        local v77 = v75.rates.basis.columns[i + 1]

        v76[i + 1][1] = v77[1]
        v76[i + 1][2] = v77[2]
        v76[i + 1][3] = v77[3]
    end

    local position = v75.rates.position

    v76[4] = {
        position.x,
        position.y,
        position.z,
        0
    }

    return v76
end

function t1.SkeletonTargets.apply_future_deck_displacement(p21, p22) -- line: 288
    -- upvalues: t1 (copy)
    local v78 = t1.SkeletonTargets.transform(p21, 0)

    v78[4][1] += p22.x
    v78[4][2] += p22.y
    v78[4][3] += p22.z
    t1.SkeletonTargets.set_transform(p21, 0, v78)
end

t1.STATIC_INERTIA = {
    inverse_mass = 0,
    spherical = 0,
    maximum_linear_velocity = 0,
    maximum_angular_velocity = 0,
    linear_drag = 0,
    angular_drag = 0,
    inverse_tensor = rt.copy(Vector3.ZERO)
}

function t1.hard(p23, p24) -- line: 307
    -- upvalues: RetailDriveType (copy)
    return {
        damping = 0,
        spring_or_max_velocity = p23,
        max_strength = p24,
        drive_type = RetailDriveType.HardDrive
    }
end

function t1.words(p25) -- line: 317
    -- upvalues: v1 (copy)
    local v79 = table.create(16)

    for i = 0, 3 do
        local v80 = p25[i + 1]

        for j = 0, 3 do
            local v81 = i * 4 + j + 1
            local v82 = v80[j + 1]

            if v82 ~= 0 and v82 > -1.1754943508222875E-38 and v82 < 1.1754943508222875E-38 then
                local v83 = math.abs(v82) * 7.1362384635298E+44
                local v84 = math.floor(v83)
                local v85 = v83 - v84
                local v86 = if v85 > 0.5 or v85 == 0.5 and v84 % 2 == 1 then v84 + 1 else v84

                if v82 < 0 then
                    v79[v81] = v86 + 2147483648
                else
                    v79[v81] = v86
                end
            else
                buffer.writef32(v1, 0, v82)
                v79[v81] = buffer.readu32(v1, 0)
            end
        end
    end

    return v79
end

function t1.floats(p26) -- line: 329
    -- upvalues: v1 (copy)
    local v87 = table.create(4)

    for i = 0, 3 do
        local v88 = table.create(4)

        for j = 0, 3 do
            local v89 = j + 1

            buffer.writeu32(v1, 0, p26[i * 4 + j + 1])
            v88[v89] = buffer.readf32(v1, 0)
        end

        v87[i + 1] = v88
    end

    return v87
end

for v91, v92 in v9.SkeletonTargets do
    t1.SkeletonTargets[v91] = v92
end

return t1
