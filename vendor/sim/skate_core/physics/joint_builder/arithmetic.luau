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

local function rtl_from_bits(p2) -- line: 16
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p2)

    return (buffer.readf32(v1, 0))
end

local function rtl_fround(p3) -- line: 20
    -- upvalues: v1 (copy)
    if p3 ~= 0 and p3 > -1.1754943508222875E-38 and p3 < 1.1754943508222875E-38 then
        local v6 = math.abs(p3) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        local v8 = v5 * 1.401298464324817E-45

        if p3 < 0 then
            return -v8
        end

        return v8
    end

    buffer.writef32(v1, 0, p3)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local v9 = import("skate_core/physics/constraint_frames")
local v10 = import("skate_core/physics/native_arithmetic")
local v11 = import("skate_core/math")

local function joint_builder() -- line: 36
    -- upvalues: import (copy)
    return import("skate_core/physics/joint_builder")
end

local Vector3 = v11.Vector3
local t1 = {}

function t1.decode_parameters(p4) -- line: 44
    -- upvalues: v1 (copy), t1 (copy)
    local t2 = {
        linear_position_allowance = t1.vector_from_words(p4.words, 0),
        linear_velocity_allowance = t1.vector_from_words(p4.words, 4)
    }

    buffer.writeu32(v1, 0, p4.words[9])
    t2.twist_velocity_allowance = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, p4.words[10])
    t2.swing_velocity_allowance = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, p4.words[13])
    t2.swing_threshold = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, p4.words[14])
    t2.twist_threshold = buffer.readf32(v1, 0)
    t2.swing_mode = p4.words[15]
    t2.twist_mode = p4.words[16]

    return t2
end

function t1.decode_frames(p5) -- line: 57
    -- upvalues: t1 (copy)
    return {
        orientation_a = t1.quaternion_from_words(p5.words, 0),
        anchor_a = t1.vector_from_words(p5.words, 4),
        orientation_b = t1.quaternion_from_words(p5.words, 8),
        anchor_b = t1.vector_from_words(p5.words, 12),
        linear_orientation_b = t1.quaternion_from_words(p5.words, 16)
    }
end

function t1.angular_rows(p6, p7, p8, p9, p10) -- line: 68
    -- upvalues: rt (copy), v1 (copy), import (copy), v9 (copy), t1 (copy)
    local tu3 = import("skate_core/physics/joint_builder").tu3
    local FINITE_INFINITY = tu3.FINITE_INFINITY
    local v16 = t1.basis_columns(p8)
    local v17 = rt.filled(3, -FINITE_INFINITY)
    local v18 = rt.filled(3, FINITE_INFINITY)

    if p6.swing_mode == 0 then
        v16[2] = rt.copy(p10.axes[2])
        v16[3] = rt.copy(p10.axes[3])
        v17[2] = 2 * p10.relative.y
        v18[2] = v17[2]
        v17[3] = 2 * p10.relative.z
        v18[3] = v17[3]
    elseif p6.swing_mode == 1 then
        if not (p9[1][1] >= tu3.NEAR_PARALLEL) then
            local v19 = t1.basis_column(p7, 0)
            local v20 = t1.basis_column(p8, 0)
            local v21 = p9[1][3]
            local v22 = p9[1][2]
            local v23 = v22 * v22 + v21 * v21
            local v24

            if v23 == 0 then
                buffer.writef32(v1, 0, v23)
                v24 = buffer.readf32(v1, 0)
            elseif v23 > -1.1754943508222875E-38 and v23 < 1.1754943508222875E-38 then
                local v25 = math.abs(v23) * 7.1362384635298E+44
                local v26 = math.floor(v25)
                local v27 = v25 - v26

                if v27 > 0.5 or v27 == 0.5 and v26 % 2 == 1 then
                    v26 += 1
                end

                v24 = v26 * 1.401298464324817E-45

                if v23 < 0 then
                    v24 = -v24
                end
            else
                buffer.writef32(v1, 0, v23)
                v24 = buffer.readf32(v1, 0)
            end

            local v28 = v24 * v9.reciprocal_sqrt(v24)

            if v24 == 0 then
                v28 = 0
            end

            local v29 = v9.reciprocal(v28) * 1

            v16[2] = t1.scale(t1.cross(v19, v20), v29)
            v16[3] = t1.cross(v16[2], v19)
            v17[2] = (p6.swing_threshold - p9[1][1]) * v29
        end
    elseif p6.swing_mode == 2 or p6.swing_mode == 3 then
        v16[2] = t1.basis_column(p8, 1)

        if p6.twist_mode == 0 then
            v16[3] = rt.copy(p10.axes[3])
            v17[3] = 2 * p10.relative.z
        else
            v16[3] = t1.cross(t1.basis_column(p7, 0), v16[2])
            v17[3] = -p9[1][2]
        end

        v18[3] = v17[3]

        if p6.swing_mode == 2 then
            local v30 = p9[1][3]

            if v30 ~= 0 then
                local v31 = v9.reciprocal(v30) * (p6.swing_threshold - p9[1][1])

                if v30 < 0 then
                    v18[2] = v31
                else
                    v17[2] = v31
                end
            end
        end
    else
        v16[2] = t1.basis_column(p8, 1)
        v16[3] = t1.basis_column(p8, 2)
    end

    if p6.twist_mode == 0 then
        v16[1] = rt.copy(p10.axes[1])
        v17[1] = 2 * p10.relative.x
        v18[1] = v17[1]
    else
        local v32 = p6.twist_mode == 1
        local v33, v34

        if v32 then
            v16[1] = t1.basis_column(p7, 0)
            v33 = p9[3][2] - p9[2][3]
            v34 = v33 == 0
        else
            v16[1] = t1.basis_column(p8, 0)
        end

        if not (v32 and v34 or not v32) then
            local v35 = (1 + p9[1][1]) * p6.twist_threshold - (p9[2][2] + p9[3][3])
            local v36 = v9.reciprocal(v33) * v35

            if v33 < 0 then
                v18[1] = v36
            else
                v17[1] = v36
            end
        end
    end

    return v16, v17, v18
end

function t1.create_rqd(p11, p12) -- line: 158
    -- upvalues: v9 (copy)
    local v37 = v9.quaternion_rows(p11, p12)

    return {
        relative = v37.relative,
        axes = v37.axes
    }
end

function t1.relative_basis(p13, p14) -- line: 166
    -- upvalues: t1 (copy)
    return {
        {
            t1.dot3(t1.basis_column(p13, 0), t1.basis_column(p14, 0)),
            t1.dot3(t1.basis_column(p13, 0), t1.basis_column(p14, 1)),
            t1.dot3(t1.basis_column(p13, 0), t1.basis_column(p14, 2))
        },
        {
            t1.dot3(t1.basis_column(p13, 1), t1.basis_column(p14, 0)),
            t1.dot3(t1.basis_column(p13, 1), t1.basis_column(p14, 1)),
            t1.dot3(t1.basis_column(p13, 1), t1.basis_column(p14, 2))
        },
        {
            t1.dot3(t1.basis_column(p13, 2), t1.basis_column(p14, 0)),
            t1.dot3(t1.basis_column(p13, 2), t1.basis_column(p14, 1)),
            t1.dot3(t1.basis_column(p13, 2), t1.basis_column(p14, 2))
        }
    }
end

function t1.scaled_projection_columns(p15, p16) -- line: 174
    -- upvalues: t1 (copy)
    return {
        {
            t1.vector_to_array(p15[1])[1] * p16[1],
            t1.vector_to_array(p15[2])[1] * p16[2],
            t1.vector_to_array(p15[3])[1] * p16[3]
        },
        {
            t1.vector_to_array(p15[1])[2] * p16[1],
            t1.vector_to_array(p15[2])[2] * p16[2],
            t1.vector_to_array(p15[3])[2] * p16[3]
        },
        {
            t1.vector_to_array(p15[1])[3] * p16[1],
            t1.vector_to_array(p15[2])[3] * p16[2],
            t1.vector_to_array(p15[3])[3] * p16[3]
        }
    }
end

function t1.packed_inertia_columns(p17, p18) -- line: 182
    return {
        {
            p17.full.x,
            p17.full.y,
            p17.full.z,
            p18
        },
        {
            p17.full.y,
            p17.split.y,
            p17.split.z,
            p18
        },
        {
            p17.full.z,
            p17.split.z,
            p17.split.x,
            p18
        }
    }
end

function t1.zero_inertia() -- line: 190
    -- upvalues: rt (copy), Vector3 (copy)
    return {
        full = rt.copy(Vector3.ZERO),
        split = rt.copy(Vector3.ZERO)
    }
end

function t1.basis_from_quaternion_retail(p19) -- line: 197
    -- upvalues: v9 (copy)
    return v9.basis(p19)
end

function t1.quaternion_multiply(p20, p21) -- line: 201
    -- upvalues: v9 (copy)
    return v9.compose(p20, p21)
end

function t1.point_rate(p22, p23, p24) -- line: 205
    -- upvalues: v9 (copy)
    return v9.point_rate(p22, p23, p24)
end

function t1.project(p25, p26) -- line: 209
    -- upvalues: t1 (copy)
    local v38 = table.create(3)

    v38[1] = t1.dot3(p25, p26[1])
    v38[2] = t1.dot3(p25, p26[2])
    v38[3] = t1.dot3(p25, p26[3])

    return v38
end

function t1.multiply_basis(p27, p28) -- line: 217
    -- upvalues: v9 (copy)
    return v9.transform_direction(p27, p28)
end

function t1.basis_columns(p29) -- line: 221
    -- upvalues: t1 (copy)
    return {
        t1.basis_column(p29, 0),
        t1.basis_column(p29, 1),
        t1.basis_column(p29, 2)
    }
end

function t1.basis_column(p30, p31) -- line: 225
    -- upvalues: Vector3 (copy)
    return Vector3.new(p30.columns[p31 + 1][1], p30.columns[p31 + 1][2], p30.columns[p31 + 1][3])
end

function t1.vector_from_words(p32, p33) -- line: 229
    -- upvalues: v1 (copy), Vector3 (copy)
    local new = Vector3.new

    buffer.writeu32(v1, 0, p32[p33 + 1])

    local v40 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p32[p33 + 1 + 1])

    local v42 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p32[p33 + 2 + 1])

    return new(v40, v42, (buffer.readf32(v1, 0)))
end

function t1.quaternion_from_words(p34, p35) -- line: 237
    -- upvalues: v1 (copy)
    local t3 = {}

    buffer.writeu32(v1, 0, p34[p35 + 1])
    t3.x = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, p34[p35 + 1 + 1])
    t3.y = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, p34[p35 + 2 + 1])
    t3.z = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, p34[p35 + 3 + 1])
    t3.w = buffer.readf32(v1, 0)

    return t3
end

function t1.vector_to_array(p36) -- line: 246
    return {
        p36.x,
        p36.y,
        p36.z
    }
end

function t1.cross(p37, p38) -- line: 250
    -- upvalues: v9 (copy)
    return v9.cross(p37, p38)
end

function t1.dot3(p39, p40) -- line: 254
    return p39.x * p40.x + p39.y * p40.y + p39.z * p40.z
end

function t1.add(p41, p42) -- line: 258
    -- upvalues: Vector3 (copy)
    return Vector3.new(p41.x + p42.x, p41.y + p42.y, p41.z + p42.z)
end

function t1.sub(p43, p44) -- line: 262
    -- upvalues: Vector3 (copy)
    return Vector3.new(p43.x - p44.x, p43.y - p44.y, p43.z - p44.z)
end

function t1.scale(p45, p46) -- line: 266
    -- upvalues: Vector3 (copy)
    return Vector3.new(p45.x * p46, p45.y * p46, p45.z * p46)
end

function t1.vmx_min(p47, p48) -- line: 270
    -- upvalues: v10 (copy)
    return v10.vector_min(p47, p48)
end

function t1.vmx_max(p49, p50) -- line: 274
    -- upvalues: v10 (copy)
    return v10.vector_max(p49, p50)
end

return t1
