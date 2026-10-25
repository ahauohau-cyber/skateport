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

local BoardRuntime = require(sim.import)("skate_core/physics/board_runtime").BoardRuntime
local t1 = {}

function t1.ground_position(p3, p4) -- line: 36
    -- upvalues: rt (copy), v1 (copy), BoardRuntime (copy), t1 (copy)
    local v8 = rt.from_fn(4, function(p5) -- line: 37
        -- upvalues: p3 (copy), BoardRuntime (copy)
        local position = BoardRuntime.bodies(p3)[p5 + 1].rates.position

        return {
            position.x,
            position.y,
            position.z,
            0
        }
    end)
    local v9 = t1.wheel_ground_position(v8, p4)
    local v10 = v9[1]
    local v11

    if v10 ~= 0 and v10 > -1.1754943508222875E-38 and v10 < 1.1754943508222875E-38 then
        local v12 = math.abs(v10) * 7.1362384635298E+44
        local v13 = math.floor(v12)
        local v14 = v12 - v13

        v11 = if v14 > 0.5 or v14 == 0.5 and v13 % 2 == 1 then v13 + 1 else v13

        if v10 < 0 then
            v11 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v10)
        v11 = buffer.readu32(v1, 0)
    end

    local v15 = v9[2]
    local v16

    if v15 ~= 0 and v15 > -1.1754943508222875E-38 and v15 < 1.1754943508222875E-38 then
        local v17 = math.abs(v15) * 7.1362384635298E+44
        local v18 = math.floor(v17)
        local v19 = v17 - v18

        v16 = if v19 > 0.5 or v19 == 0.5 and v18 % 2 == 1 then v18 + 1 else v18

        if v15 < 0 then
            v16 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v15)
        v16 = buffer.readu32(v1, 0)
    end

    local v20 = v9[3]
    local v21

    if v20 ~= 0 and v20 > -1.1754943508222875E-38 and v20 < 1.1754943508222875E-38 then
        local v22 = math.abs(v20) * 7.1362384635298E+44
        local v23 = math.floor(v22)
        local v24 = v22 - v23

        v21 = if v24 > 0.5 or v24 == 0.5 and v23 % 2 == 1 then v23 + 1 else v23

        if v20 < 0 then
            v21 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v20)
        v21 = buffer.readu32(v1, 0)
    end

    local v25 = v9[4]
    local v26

    if v25 ~= 0 and v25 > -1.1754943508222875E-38 and v25 < 1.1754943508222875E-38 then
        local v27 = math.abs(v25) * 7.1362384635298E+44
        local v28 = math.floor(v27)
        local v29 = v27 - v28

        v26 = if v29 > 0.5 or v29 == 0.5 and v28 % 2 == 1 then v28 + 1 else v28

        if v25 < 0 then
            v26 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v25)
        v26 = buffer.readu32(v1, 0)
    end

    return {
        v11,
        v16,
        v21,
        v26
    }
end

function t1.ground_position_into(p6, p7, p8) -- line: 58
    -- upvalues: rt (copy), BoardRuntime (copy)
    local v30 = BoardRuntime.bodies(p6)
    local v31 = p7[1]
    local v32 = p7[2]
    local v33 = p7[3]
    local v34 = v31[1]
    local v35 = v31[2]
    local v36 = v31[3]
    local v37 = v32[1]
    local v38 = v32[2]
    local v39 = v32[3]
    local v40 = v33[1]
    local v41 = v33[2]
    local v42 = v33[3]
    local position = v30[1].rates.position
    local x, y, z = position.x, position.y, position.z
    local v43 = v36 * z + (v35 * y + v34 * x)
    local v44 = v39 * z + (v38 * y + v37 * x)
    local v45 = v42 * z + (v41 * y + v40 * x)
    local position2 = v30[2].rates.position
    local x2, y2, z2 = position2.x, position2.y, position2.z
    local v46 = v36 * z2 + (v35 * y2 + v34 * x2)
    local v47 = v39 * z2 + (v38 * y2 + v37 * x2)
    local v48 = v42 * z2 + (v41 * y2 + v40 * x2)
    local position3 = v30[3].rates.position
    local x3, y3, z3 = position3.x, position3.y, position3.z
    local v49 = v36 * z3 + (v35 * y3 + v34 * x3)
    local v50 = v39 * z3 + (v38 * y3 + v37 * x3)
    local v51 = v42 * z3 + (v41 * y3 + v40 * x3)
    local position4 = v30[4].rates.position
    local x4, y4, z4 = position4.x, position4.y, position4.z
    local v52 = v36 * z4 + (v35 * y4 + v34 * x4)
    local v53 = v39 * z4 + (v38 * y4 + v37 * x4)
    local v54 = v42 * z4 + (v41 * y4 + v40 * x4)
    local v55 = (v43 + v46 + v49 + v52) * 0.25
    local v56 = (v45 + v48 + v51 + v54) * 0.25

    if not (v44 < v47) then
        v44 = v47
    end

    if not (v50 - v44 >= 0) then
        v44 = v50
    end

    if not (v53 - v44 >= 0) then
        v44 = v53
    end

    local to_bits = rt.to_bits
    local v57 = to_bits(v40 * v56 + (v37 * v44 + v34 * v55))
    local v58 = to_bits(v41 * v56 + (v38 * v44 + v35 * v55))
    local v59 = to_bits(v42 * v56 + (v39 * v44 + v36 * v55))
    local v60 = to_bits(v33[4] * v56 + (v32[4] * v44 + v31[4] * v55))

    p8[1] = v57
    p8[2] = v58
    p8[3] = v59
    p8[4] = v60

    return p8
end

function t1.wheel_ground_position(p9, p10) -- line: 115
    -- upvalues: t1 (copy)
    local t3 = {
        {
            p10[1][1],
            p10[2][1],
            p10[3][1],
            0
        },
        {
            p10[1][2],
            p10[2][2],
            p10[3][2],
            0
        },
        {
            p10[1][3],
            p10[2][3],
            p10[3][3],
            0
        }
    }
    local t4 = {
        t1.rotate(t3, p9[1]),
        t1.rotate(t3, p9[2]),
        t1.rotate(t3, p9[3]),
        t1.rotate(t3, p9[4])
    }
    local t5 = {
        (t4[1][1] + t4[2][1] + t4[3][1] + t4[4][1]) * 0.25,
        (t4[1][2] + t4[2][2] + t4[3][2] + t4[4][2]) * 0.25,
        (t4[1][3] + t4[2][3] + t4[3][3] + t4[4][3]) * 0.25,
        (t4[1][4] + t4[2][4] + t4[3][4] + t4[4][4]) * 0.25
    }
    local v61 = if t4[2][2] > t4[1][2] then t4[1][2] else t4[2][2]

    if not (t4[3][2] - v61 >= 0) then
        v61 = t4[3][2]
    end

    t5[2] = if t4[4][2] - v61 >= 0 then v61 else t4[4][2]

    return t1.rotate({
        p10[1],
        p10[2],
        p10[3]
    }, t5)
end

function t1.rotate(p11, p12) -- line: 157
    -- upvalues: rt (copy)
    return rt.from_fn(4, function(p13) -- line: 158
        -- upvalues: p11 (copy), p12 (copy)
        local v62 = p11[1][p13 + 1] * p12[1]
        local v63 = p11[2][p13 + 1] * p12[2] + v62

        return p11[3][p13 + 1] * p12[3] + v63
    end)
end

return t1
