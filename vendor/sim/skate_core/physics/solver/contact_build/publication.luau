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

local Vector3 = require(sim.import)("skate_core/math").Vector3
local t1 = {}

function t1.vector_row(p3, p4, p5, p6) -- line: 35
    -- upvalues: v1 (copy)
    local v8 = p4 * 4 + 1
    local x = p5.x
    local v9

    if x ~= 0 and x > -1.1754943508222875E-38 and x < 1.1754943508222875E-38 then
        local v10 = math.abs(x) * 7.1362384635298E+44
        local v11 = math.floor(v10)
        local v12 = v10 - v11

        v9 = if v12 > 0.5 or v12 == 0.5 and v11 % 2 == 1 then v11 + 1 else v11

        if x < 0 then
            v9 += 2147483648
        end
    else
        buffer.writef32(v1, 0, x)
        v9 = buffer.readu32(v1, 0)
    end

    p3[v8] = v9

    local v13 = p4 * 4 + 2
    local y = p5.y
    local v14

    if y ~= 0 and y > -1.1754943508222875E-38 and y < 1.1754943508222875E-38 then
        local v15 = math.abs(y) * 7.1362384635298E+44
        local v16 = math.floor(v15)
        local v17 = v15 - v16

        v14 = if v17 > 0.5 or v17 == 0.5 and v16 % 2 == 1 then v16 + 1 else v16

        if y < 0 then
            v14 += 2147483648
        end
    else
        buffer.writef32(v1, 0, y)
        v14 = buffer.readu32(v1, 0)
    end

    p3[v13] = v14

    local v18 = p4 * 4 + 3
    local z = p5.z
    local v19

    if z ~= 0 and z > -1.1754943508222875E-38 and z < 1.1754943508222875E-38 then
        local v20 = math.abs(z) * 7.1362384635298E+44
        local v21 = math.floor(v20)
        local v22 = v20 - v21

        v19 = if v22 > 0.5 or v22 == 0.5 and v21 % 2 == 1 then v21 + 1 else v21

        if z < 0 then
            v19 += 2147483648
        end
    else
        buffer.writef32(v1, 0, z)
        v19 = buffer.readu32(v1, 0)
    end

    p3[v18] = v19
    p3[p4 * 4 + 4] = p6
end

function t1.float_row(p7, p8, p9) -- line: 43
    -- upvalues: v1 (copy)
    for i = 0, 3 do
        local v23 = p8 * 4 + i + 1
        local v24 = p9[i + 1]

        if v24 ~= 0 and v24 > -1.1754943508222875E-38 and v24 < 1.1754943508222875E-38 then
            local v25 = math.abs(v24) * 7.1362384635298E+44
            local v26 = math.floor(v25)
            local v27 = v25 - v26
            local v28 = if v27 > 0.5 or v27 == 0.5 and v26 % 2 == 1 then v26 + 1 else v26

            if v24 < 0 then
                p7[v23] = v28 + 2147483648
            else
                p7[v23] = v28
            end
        else
            buffer.writef32(v1, 0, v24)
            p7[v23] = buffer.readu32(v1, 0)
        end
    end
end

function t1.compile(p10, p11) -- line: 51
    -- upvalues: rt (copy), Vector3 (copy), t1 (copy)
    local v29 = table.create(64, 0)

    t1.vector_row(v29, 0, p10.arms[1], p10.reaction_ids[1])
    t1.vector_row(v29, 1, p10.arms[2], p10.reaction_ids[2])

    local t2 = {}

    for v30, v31 in ipairs(p10.axes) do
        t2[v30] = {
            v31.x,
            v31.y,
            v31.z
        }
    end

    local t3 = {
        p10.combined_state_bit_8,
        p10.static_friction_bits,
        p10.dynamic_friction_bits
    }

    for i = 0, 2 do
        local t4 = {
            t2[1][i + 1] * p11[1] + 0,
            t2[2][i + 1] * p11[2] + 0,
            t2[3][i + 1] * p11[3] + 0
        }

        t1.vector_row(v29, i + 2, Vector3.new(t4[1], t4[2], t4[3]), t3[i + 1])
    end

    local v32 = p10.separation_projection[1] * p11[1] + 0
    local v33 = p10.restitution_projection[1] * p11[1] + 0
    local t5 = {
        p10.predicted_separation_projection[1] * p11[1] + 0,
        p10.predicted_separation_projection[2] * p11[2] + 0,
        p10.predicted_separation_projection[3] * p11[3] + 0
    }
    local v34 = if v33 >= 0 then 0 else v32 + v33

    if not (v32 >= 0) then
        v33 = v34
    end

    if t5[1] <= 0 then
        v33 = 0
    end

    t1.float_row(v29, 6, {
        t5[1] - v33,
        t5[2] - 0,
        t5[3] - 0,
        v32
    })

    local t6 = {
        p10.body_ids[1],
        p10.body_ids[2],
        p10.contact_tag
    }

    for i = 0, 2 do
        t1.vector_row(v29, i * 3 + 7, p10.axes[i + 1], t6[i + 1])

        local v35 = rt.copy(p10.angular_response_a[i + 1])
        local v36 = rt.copy(p10.angular_response_b[i + 1])

        if i == 0 then
            v35[4] = p10.inverse_mass[1]
            v36[4] = p10.inverse_mass[2]
        end

        t1.float_row(v29, i * 3 + 8, v35)
        t1.float_row(v29, i * 3 + 9, v36)
    end

    return v29
end

return t1
