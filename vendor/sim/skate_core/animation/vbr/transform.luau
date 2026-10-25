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
local v8 = import("skate_core/trigonometry")
local v9 = import("skate_core/physics/native_arithmetic")
local t1 = {
    Tables = {}
}
local t2

function t1.tables() -- line: 47
    -- upvalues: rt (copy), v1 (copy), v8 (copy), t1 (copy), t2 (ref)
    if t2 ~= nil then
        return t2
    end

    local t3 = {
        t1.logarithm_for_frequency(2) * 3.0517578125E-05,
        t1.logarithm_for_frequency(3) * 3.0517578125E-05,
        t1.logarithm_for_frequency(4) * 3.0517578125E-05,
        t1.logarithm_for_frequency(5) * 3.0517578125E-05,
        t1.logarithm_for_frequency(6) * 3.0517578125E-05,
        t1.logarithm_for_frequency(7) * 3.0517578125E-05,
        t1.logarithm_for_frequency(8) * 3.0517578125E-05,
        t1.logarithm_for_frequency(9) * 3.0517578125E-05
    }
    local n1 = 1
    local v10 = rt.from_fn(256, function(_) -- line: 60
        -- upvalues: t3 (copy), n1 (ref)
        local v11 = table.create(8)

        v11[1] = t3[1] * n1
        v11[2] = t3[2] * n1
        v11[3] = t3[3] * n1
        v11[4] = t3[4] * n1
        v11[5] = t3[5] * n1
        v11[6] = t3[6] * n1
        v11[7] = t3[7] * n1
        v11[8] = t3[8] * n1
        n1 += 0.20000000298023224

        return v11
    end)
    local t4 = {
        0, 1053364187, 1061752795, 1066847204, 1070141403, 1073435602, 1075235812, 1076882912
    }

    t2 = {
        quantization = v10,
        inverse_dct = rt.from_fn(8, function(p5) -- line: 79
            -- upvalues: t4 (copy), v1 (copy), v8 (copy)
            local v12 = p5 + 0.5
            local v13 = table.create(8)

            for i = 1, 8 do
                local cos = v8.cos

                buffer.writeu32(v1, 0, t4[i])
                v13[i] = cos(v12 * buffer.readf32(v1, 0)) * 0.25
            end

            v13[1] *= 0.5

            return v13
        end)
    }

    return t2
end

function t1.logarithm_for_frequency(p6) -- line: 99
    -- upvalues: v1 (copy)
    local v15

    if p6 ~= 0 and p6 > -1.1754943508222875E-38 and p6 < 1.1754943508222875E-38 then
        local v16 = math.abs(p6) * 7.1362384635298E+44
        local v17 = math.floor(v16)
        local v18 = v16 - v17

        v15 = if v18 > 0.5 or v18 == 0.5 and v17 % 2 == 1 then v17 + 1 else v17

        if p6 < 0 then
            v15 += 2147483648
        end
    else
        buffer.writef32(v1, 0, p6)
        v15 = buffer.readu32(v1, 0)
    end

    local v20 = bit32.band(bit32.rshift(v15, 23), 255) - 127
    local v21

    if p6 ~= 0 and p6 > -1.1754943508222875E-38 and p6 < 1.1754943508222875E-38 then
        local v22 = math.abs(p6) * 7.1362384635298E+44
        local v23 = math.floor(v22)
        local v24 = v22 - v23

        v21 = if v24 > 0.5 or v24 == 0.5 and v23 % 2 == 1 then v23 + 1 else v23

        if p6 < 0 then
            v21 += 2147483648
        end
    else
        buffer.writef32(v1, 0, p6)
        v21 = buffer.readu32(v1, 0)
    end

    buffer.writeu32(v1, 0, (bit32.bor(bit32.band(v21, 8388607), 1065353216)))

    local v27 = buffer.readf32(v1, 0) - 1
    local v28 = v27 * v27
    local v29 = v27 * v28
    local v30 = v28 * v28
    local t5 = {
        1.4426896572113037, -0.7211657762527466, 0.47868481278419495, -0.34730541706085205, 0.24187369644641876, -0.13753120601177216, 0.0520646795630455, -0.009310494177043438
    }
    local v31 = v27 * t5[2] + t5[1]
    local v32 = v27 * t5[6] + t5[5]
    local v33 = v28 * t5[3] + v31
    local v34 = v28 * t5[7] + v32
    local v35 = v29 * t5[4] + v33

    return (v27 * (v30 * (v29 * t5[8] + v34) + v35) + v20) * 0.6931471824645996
end

function t1.decode_reference(p7, p8, p9, p10, p11, p12) -- line: 129
    -- upvalues: v9 (copy), t1 (copy)
    local v36 = t1.tables()
    local v37 = p9 * p9
    local v38 = p9 * 3.0517578125E-05
    local v39 = v36.quantization[p8 + 1]
    local v40 = v36.inverse_dct[p7 + 1]
    local v41 = table.create(8)

    for i = 1, 8 do
        v41[i] = (v39[i] * v37 + v38) * v40[i]
    end

    return (v9.dot4({
        p10[1],
        p10[2],
        p10[3],
        p10[4]
    }, {
        v41[1],
        v41[2],
        v41[3],
        v41[4]
    }) + v9.dot4({
        p10[5],
        p10[6],
        p10[7],
        p10[8]
    }, {
        v41[5],
        v41[6],
        v41[7],
        v41[8]
    }) + 0.5) * p12 + p11
end

function t1.decode(p13, p14, p15, p16, p17, p18) -- line: 163
    -- upvalues: t1 (copy)
    local v42 = t1.tables()
    local v43 = p15 * p15
    local v44 = p15 * 3.0517578125E-05
    local v45 = v42.quantization[p14 + 1]
    local v46 = v42.inverse_dct[p13 + 1]

    return (p16[1] * ((v45[1] * v43 + v44) * v46[1]) + p16[2] * ((v45[2] * v43 + v44) * v46[2]) + p16[3] * ((v45[3] * v43 + v44) * v46[3]) + p16[4] * ((v45[4] * v43 + v44) * v46[4]) + (p16[5] * ((v45[5] * v43 + v44) * v46[5]) + p16[6] * ((v45[6] * v43 + v44) * v46[6]) + p16[7] * ((v45[7] * v43 + v44) * v46[7]) + p16[8] * ((v45[8] * v43 + v44) * v46[8])) + 0.5) * p18 + p17
end

return t1
