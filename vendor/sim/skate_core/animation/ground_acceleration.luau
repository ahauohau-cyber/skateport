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

local function rtl_fround(p2) -- line: 16
    -- upvalues: v1 (copy)
    if p2 ~= 0 and p2 > -1.1754943508222875E-38 and p2 < 1.1754943508222875E-38 then
        local v6 = math.abs(p2) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        local v8 = v5 * 1.401298464324817E-45

        if p2 < 0 then
            return -v8
        end

        return v8
    end

    buffer.writef32(v1, 0, p2)

    return (buffer.readf32(v1, 0))
end

local v9 = require(sim.import)("skate_core/physics/native_arithmetic")
local t1 = {
    Input = {},
    Settings = {},
    Output = {}
}
local inverse_rotate, rotate

function t1.publish(p3, p4) -- line: 55
    -- upvalues: t1 (copy)
    local v10 = t1.condition(p3)

    return {
        acceleration = v10,
        bumped = t1.is_bumped(v10, p4)
    }
end

function t1.condition(p5) -- line: 66
    -- upvalues: inverse_rotate (ref), rotate (ref)
    local v11 = inverse_rotate(p5.deck, p5.world_acceleration)

    v11[2] = 0

    local v12 = rotate(p5.deck, v11)
    local v13 = inverse_rotate(p5.ground, v12)

    v13[2] = 0

    return v13
end

function t1.is_bumped(p6, p7) -- line: 78
    -- upvalues: rt (copy), v1 (copy), v9 (copy)
    local v14 = rt.copy(p6)

    v14[1] *= p7.scale_x_acc

    local v15 = v9.dot3(v14, v14)
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

    local v20 = v9.reciprocal_square_root_estimate(v16)
    local v21 = v20 * v20
    local v22 = v20 * 0.5 * (-v16 * v21 + 1) + v20
    local v23 = v22 * v22
    local v24 = v22 * 0.5 * (-v16 * v23 + 1) + v22
    local v25

    if v16 == 0 then
        v25 = 0
    else
        local v26 = v16 * v24

        if v26 ~= 0 and v26 > -1.1754943508222875E-38 and v26 < 1.1754943508222875E-38 then
            local v27 = math.abs(v26) * 7.1362384635298E+44
            local v28 = math.floor(v27)
            local v29 = v27 - v28

            v25 = (if v29 > 0.5 or v29 == 0.5 and v28 % 2 == 1 then v28 + 1 else v28) * 1.401298464324817E-45

            if v26 < 0 then
                v25 = -v25
            end
        else
            buffer.writef32(v1, 0, v26)
            v25 = buffer.readf32(v1, 0)
        end
    end

    return p7.min_bump_mag < v25
end

function t1.inverse_rotate(p8, p9) -- line: 101
    local v30 = table.create(4)

    for i = 0, 3 do
        v30[i + 1] = p8[i + 1][3] * p9[3] + (p8[i + 1][2] * p9[2] + p8[i + 1][1] * p9[1])
    end

    return v30
end

inverse_rotate = t1.inverse_rotate

function t1.rotate(p10, p11) -- line: 111
    local v31 = table.create(4)

    for i = 0, 3 do
        v31[i + 1] = p10[3][i + 1] * p11[3] + (p10[2][i + 1] * p11[2] + p10[1][i + 1] * p11[1])
    end

    return v31
end

rotate = t1.rotate

return t1
