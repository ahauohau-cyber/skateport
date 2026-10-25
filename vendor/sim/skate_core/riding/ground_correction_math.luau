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

local function rtl_fround(p4) -- line: 28
    -- upvalues: v1 (copy)
    if p4 ~= 0 and p4 > -1.1754943508222875E-38 and p4 < 1.1754943508222875E-38 then
        local v9 = math.abs(p4) * 7.1362384635298E+44
        local v8 = math.floor(v9)
        local v10 = v9 - v8

        if v10 > 0.5 or v10 == 0.5 and v8 % 2 == 1 then
            v8 += 1
        end

        local v11 = v8 * 1.401298464324817E-45

        if p4 < 0 then
            return -v11
        end

        return v11
    end

    buffer.writef32(v1, 0, p4)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local v12 = import("skate_core/math")
local v13 = import("skate_core/physics/board_motion_output")
local v14 = import("skate_core/physics/native_arithmetic")
local Vector3 = v12.Vector3
local dot, inverse_length_squared, length = v13.dot, v13.inverse_length_squared, v13.length
local reciprocal_estimate = v14.reciprocal_estimate
local t1 = {}

function t1.center_of_mass_height(p5) -- line: 55
    -- upvalues: length (copy), t1 (copy)
    return length(t1.xyz(p5))
end

function t1.dot_product(p6, p7) -- line: 59
    -- upvalues: v14 (copy)
    return v14.dot3(p6, p7)
end

function t1.collision_force_projection(p8, p9) -- line: 66
    -- upvalues: v1 (copy), dot (copy), inverse_length_squared (copy), t1 (copy)
    local v15 = dot(t1.xyz(p8), t1.xyz(p8))
    local v16

    if v15 ~= 0 and v15 > -1.1754943508222875E-38 and v15 < 1.1754943508222875E-38 then
        local v17 = math.abs(v15) * 7.1362384635298E+44
        local v18 = math.floor(v17)
        local v19 = v17 - v18

        v16 = (if v19 > 0.5 or v19 == 0.5 and v18 % 2 == 1 then v18 + 1 else v18) * 1.401298464324817E-45

        if v15 < 0 then
            v16 = -v16
        end
    else
        buffer.writef32(v1, 0, v15)
        v16 = buffer.readf32(v1, 0)
    end

    local v20 = inverse_length_squared(v16, 2)
    local t2 = if (if v16 == 0 then 0 else v16 * v20) > 9.999999974752427E-07 then {
        p8[1] * v20,
        p8[2] * v20,
        p8[3] * v20,
        p8[4] * v20
    } else { 0, 0, 0, 0 }

    return dot(t1.xyz(t2), t1.xyz(p9))
end

function t1.edge_direction(p10, p11) -- line: 87
    -- upvalues: length (copy), t1 (copy)
    local v21 = t1.subtract(p11, p10)
    local v22 = t1.reciprocal_refined(length(t1.xyz(v21)))

    v21[1] *= v22
    v21[2] *= v22
    v21[3] *= v22
    v21[4] *= v22

    return v21
end

function t1.edge_up(p12) -- line: 98
    -- upvalues: length (copy), t1 (copy)
    local v23 = t1.cross({ 0, 1, 0, 0 }, p12)
    local v24 = t1.cross(v23, p12)
    local v25 = length(t1.xyz(v24))

    if v25 <= 0 then
        return { 1, 0, 0, 0 }
    end

    if v24[2] < 0 then
        v25 = -v25
    end

    local v26 = t1.reciprocal_refined(v25)

    v24[1] *= v26
    v24[2] *= v26
    v24[3] *= v26
    v24[4] *= v26

    return v24
end

function t1.hang_force(p13, p14, p15) -- line: 120
    -- upvalues: dot (copy), t1 (copy)
    local v27 = t1.edge_direction(p13, p14)
    local v28 = t1.edge_up(v27)
    local v29 = t1.cross(v28, v27)

    if dot(t1.xyz(t1.subtract(p15, p13)), t1.xyz(v29)) < 0 then
        v29[1] *= -1
        v29[2] *= -1
        v29[3] *= -1
        v29[4] *= -1
    end

    local t3 = {
        0, 160, 0, 0
    }

    return {
        v29[1] * 50 + t3[1],
        v29[2] * 50 + t3[2],
        v29[3] * 50 + t3[3],
        v29[4] * 50 + t3[4]
    }
end

function t1.wheel_catch_displacement(p16, p17) -- line: 140
    -- upvalues: v1 (copy), t1 (copy)
    local v30

    if p17[2] > 0 then
        v30 = p17
    else
        v30 = {}

        local v31 = p17[1]
        local v32

        if v31 == 0 then
            buffer.writef32(v1, 0, v31)
            v32 = buffer.readu32(v1, 0)
        elseif v31 > -1.1754943508222875E-38 and v31 < 1.1754943508222875E-38 then
            local v33 = math.abs(v31) * 7.1362384635298E+44

            v32 = math.floor(v33)

            local v34 = v33 - v32

            if v34 > 0.5 or v34 == 0.5 and v32 % 2 == 1 then
                v32 += 1
            end

            if v31 < 0 then
                v32 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v31)
            v32 = buffer.readu32(v1, 0)
        end

        buffer.writeu32(v1, 0, (bit32.bxor(v32, 2147483648)))

        local v36 = buffer.readf32(v1, 0)
        local v37 = p17[2]
        local v38

        if v37 ~= 0 and v37 > -1.1754943508222875E-38 and v37 < 1.1754943508222875E-38 then
            local v39 = math.abs(v37) * 7.1362384635298E+44
            local v40 = math.floor(v39)
            local v41 = v39 - v40

            v38 = if v41 > 0.5 or v41 == 0.5 and v40 % 2 == 1 then v40 + 1 else v40

            if v37 < 0 then
                v38 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v37)
            v38 = buffer.readu32(v1, 0)
        end

        buffer.writeu32(v1, 0, (bit32.bxor(v38, 2147483648)))

        local v43 = buffer.readf32(v1, 0)
        local v44 = p17[3]
        local v45

        if v44 ~= 0 and v44 > -1.1754943508222875E-38 and v44 < 1.1754943508222875E-38 then
            local v46 = math.abs(v44) * 7.1362384635298E+44
            local v47 = math.floor(v46)
            local v48 = v46 - v47

            v45 = if v48 > 0.5 or v48 == 0.5 and v47 % 2 == 1 then v47 + 1 else v47

            if v44 < 0 then
                v45 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v44)
            v45 = buffer.readu32(v1, 0)
        end

        buffer.writeu32(v1, 0, (bit32.bxor(v45, 2147483648)))

        local v50 = buffer.readf32(v1, 0)
        local v51 = p17[4]
        local v52

        if v51 ~= 0 and v51 > -1.1754943508222875E-38 and v51 < 1.1754943508222875E-38 then
            local v53 = math.abs(v51) * 7.1362384635298E+44
            local v54 = math.floor(v53)
            local v55 = v53 - v54

            v52 = if v55 > 0.5 or v55 == 0.5 and v54 % 2 == 1 then v54 + 1 else v54

            if v51 < 0 then
                v52 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v51)
            v52 = buffer.readu32(v1, 0)
        end

        buffer.writeu32(v1, 0, (bit32.bxor(v52, 2147483648)))

        local v57 = buffer.readf32(v1, 0)

        v30[1] = v36
        v30[2] = v43
        v30[3] = v50
        v30[4] = v57
    end

    local v58 = t1.cross(v30, p16)

    v58[1] *= 0.007000000216066837
    v58[2] *= 0.007000000216066837
    v58[3] *= 0.007000000216066837
    v58[4] *= 0.007000000216066837

    return v58
end

function t1.pinning_velocity(p18, p19, p20, p21) -- line: 161
    -- upvalues: t1 (copy)
    local t4 = {
        p19,
        p18[2],
        p20,
        0
    }
    local v59 = t1.reciprocal_refined(p21)
    local v60 = t1.subtract(t4, p18)

    v60[1] *= v59
    v60[2] *= v59
    v60[3] *= v59
    v60[4] *= v59

    return v60
end

function t1.scale_to_magnitude(p22, p23, p24) -- line: 171
    -- upvalues: v1 (copy), inverse_length_squared (copy)
    local v61

    if p23 ~= 0 and p23 > -1.1754943508222875E-38 and p23 < 1.1754943508222875E-38 then
        local v62 = math.abs(p23) * 7.1362384635298E+44
        local v63 = math.floor(v62)
        local v64 = v62 - v63

        v61 = (if v64 > 0.5 or v64 == 0.5 and v63 % 2 == 1 then v63 + 1 else v63) * 1.401298464324817E-45

        if p23 < 0 then
            v61 = -v61
        end
    else
        buffer.writef32(v1, 0, p23)
        v61 = buffer.readf32(v1, 0)
    end

    local v65 = inverse_length_squared(v61, 2)
    local v66 = p24 / (if v61 == 0 then 0 else v61 * v65)

    return {
        p22[1] * v66,
        p22[2] * v66,
        p22[3] * v66,
        p22[4] * v66
    }
end

function t1.reciprocal_refined(p25) -- line: 185
    -- upvalues: reciprocal_estimate (copy)
    local v67 = reciprocal_estimate(p25)
    local v68 = v67 * (-v67 * p25 + 1) + v67

    return v68 * (-v68 * p25 + 1) + v68
end

function t1.cross(p26, p27) -- line: 191
    return {
        -p26[3] * p27[2] + p26[2] * p27[3],
        -p26[1] * p27[3] + p26[3] * p27[1],
        -p26[2] * p27[1] + p26[1] * p27[2],
        -p26[4] * p27[4] + p26[4] * p27[4]
    }
end

function t1.subtract(p28, p29) -- line: 200
    return {
        p28[1] - p29[1],
        p28[2] - p29[2],
        p28[3] - p29[3],
        p28[4] - p29[4]
    }
end

function t1.xyz(p30) -- line: 204
    -- upvalues: Vector3 (copy)
    return Vector3.new(p30[1], p30[2], p30[3])
end

function t1.apply_world_force(p31, p32, p33, p34) -- line: 211
    -- upvalues: rt (copy), Vector3 (copy), t1 (copy)
    local v69 = Vector3.new(p34.x - p32.x, p34.y - p32.y, p34.z - p32.z)
    local v70 = t1.cross({
        v69.x,
        v69.y,
        v69.z,
        0
    }, {
        p33.x,
        p33.y,
        p33.z,
        0
    })
    local inverse_mass = p31.inertia.inverse_mass

    p31.rates.force_acceleration.x += p33.x * inverse_mass
    p31.rates.force_acceleration.y += p33.y * inverse_mass
    p31.rates.force_acceleration.z += p33.z * inverse_mass

    local v71 = rt.copy(p31.rates.world_inverse_inertia.columns)

    local function angular(p35) -- line: 223
        -- upvalues: v70 (copy), v71 (copy)
        return v71[3][p35 + 1] * v70[3] + (v71[2][p35 + 1] * v70[2] + v71[1][p35 + 1] * v70[1])
    end

    p31.rates.torque_acceleration.x += v71[3][1] * v70[3] + (v71[2][1] * v70[2] + v71[1][1] * v70[1])
    p31.rates.torque_acceleration.y += v71[3][2] * v70[3] + (v71[2][2] * v70[2] + v71[1][2] * v70[1])
    p31.rates.torque_acceleration.z += v71[3][3] * v70[3] + (v71[2][3] * v70[2] + v71[1][3] * v70[1])
    p31.rates.cool_down = 0
end

return t1
