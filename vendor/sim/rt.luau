-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local t1 = {
    F32_EPSILON = 1.1920928955078125E-07,
    F32_MAX = 3.4028234663852886E+38,
    F32_MIN_POSITIVE = 1.1754943508222875E-38,
    PI = 3.141592653589793
}
local v1 = buffer.create(8)

local function subnormal_mantissa(p1) -- line: 17
    local v2 = p1 * 7.1362384635298E+44
    local v3 = math.floor(v2)
    local v4 = v2 - v3

    if v4 > 0.5 or v4 == 0.5 and v3 % 2 == 1 then
        return v3 + 1
    end

    return v3
end

function t1.to_bits(p2) -- line: 26
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

function t1.from_bits(p3) -- line: 34
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p3)

    return (buffer.readf32(v1, 0))
end

function t1.fround(p4) -- line: 39
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

local function copy(p5) -- line: 49
    -- upvalues: copy (copy)
    if type(p5) ~= "table" then
        return p5
    end

    local v12 = table.clone(p5)

    for v13, v14 in v12 do
        if type(v14) == "table" then
            v12[v13] = copy(v14)
        end
    end

    return v12
end

t1.copy = copy

function t1.assign(p6, p7) -- line: 64
    -- upvalues: copy (copy)
    for v15 in p6 do
        if p7[v15] == nil then
            p6[v15] = nil
        end
    end

    for v16, v17 in p7 do
        if type(v17) == "table" then
            p6[v16] = copy(v17)
        else
            p6[v16] = v17
        end
    end
end

function t1.filled(p8, p9) -- line: 76
    -- upvalues: copy (copy)
    local v18 = table.create(p8)

    for i = 1, p8 do
        v18[i] = copy(p9)
    end

    return v18
end

function t1.from_fn(p10, p11) -- line: 83
    local v19 = table.create(p10)

    for i = 1, p10 do
        v19[i] = p11(i - 1)
    end

    return v19
end

function t1.slice(p12, p13, p14) -- line: 91
    -- upvalues: copy (copy)
    p14 = p14 or #p12

    local v21 = table.create(p14 - p13)

    for i = p13 + 1, p14 do
        v21[i - p13] = copy(p12[i])
    end

    return v21
end

function t1.map(p15, p16) -- line: 99
    local v22 = table.create(#p15)

    for v23, v24 in p15 do
        v22[v23] = p16(v24)
    end

    return v22
end

function t1.wrapping_add_u32(p17, p18) -- line: 108
    return (p17 + p18) % 4294967296
end

function t1.wrapping_sub_u32(p19, p20) -- line: 111
    return (p19 - p20) % 4294967296
end

function t1.wrapping_mul_u32(p21, p22) -- line: 114
    local v25 = p21 % 65536 * p22

    return (math.floor(p21 / 65536) * p22 % 65536 * 65536 + v25) % 4294967296
end

function t1.to_i32(p23) -- line: 119
    local v27 = p23 % 4294967296

    if v27 >= 2147483648 then
        return v27 - 4294967296
    end

    return v27
end

function t1.to_u32(p24) -- line: 123
    return p24 % 4294967296
end

function t1.idiv(p25, p26) -- line: 126
    local v28 = p25 / p26

    if v28 >= 0 then
        return (math.floor(v28))
    end

    return (math.ceil(v28))
end

function t1.irem(p27, p28) -- line: 130
    -- upvalues: t1 (copy)
    return p27 - p28 * t1.idiv(p27, p28)
end

function t1.f_to_int(p29, p30, p31) -- line: 134
    if p29 ~= p29 then
        return 0
    end

    return (math.clamp(if p29 >= 0 then math.floor(p29) else math.ceil(p29), p30, p31))
end

function t1.f_to_i32(p32) -- line: 141
    -- upvalues: t1 (copy)
    return t1.f_to_int(p32, -2147483648, 2147483647)
end

function t1.f_to_u32(p33) -- line: 144
    -- upvalues: t1 (copy)
    return t1.f_to_int(p33, 0, 4294967295)
end

function t1.f_to_usize(p34) -- line: 147
    -- upvalues: t1 (copy)
    return t1.f_to_int(p34, 0, 9007199254740991)
end

function t1.signum(p35) -- line: 152
    if p35 ~= p35 then
        return p35
    end

    if not (p35 > 0 or p35 == 0 and 1 / p35 > 0) then
        return -1
    end

    return 1
end

function t1.copysign(p36, p37) -- line: 158
    local v30 = math.abs(p36)

    if not (p37 < 0 or p37 == 0 and 1 / p37 < 0) then
        return v30
    end

    return -v30
end

function t1.trunc(p38) -- line: 162
    if p38 >= 0 then
        return (math.floor(p38))
    end

    return (math.ceil(p38))
end

function t1.round(p39) -- line: 165
    if p39 >= 0 then
        return (math.floor(p39 + 0.5))
    end

    return (math.ceil(p39 - 0.5))
end

function t1.fract(p40) -- line: 168
    -- upvalues: t1 (copy)
    return p40 - t1.trunc(p40)
end

function t1.rem_euclid(p41, p42) -- line: 171
    local v33 = math.fmod(p41, p42)

    if v33 < 0 then
        return v33 + math.abs(p42)
    end

    return v33
end

function t1.fmin(p43, p44) -- line: 175
    if p43 == p43 and (p44 ~= p44 or p43 < p44) then
        return p43
    end

    return p44
end

function t1.fmax(p45, p46) -- line: 180
    if p45 == p45 and (p46 ~= p46 or p46 < p45) then
        return p45
    end

    return p46
end

function t1.clamp(p47, p48, p49) -- line: 185
    if p47 < p48 then
        return p48
    end

    if p49 < p47 then
        return p49
    end

    return p47
end

function t1.is_finite(p50) -- line: 190
    if p50 ~= p50 or p50 == 1e999 then
        return false
    end

    return p50 ~= (-1e999)
end

function t1.hypot(p51, p52) -- line: 193
    return (math.sqrt(p51 * p51 + p52 * p52))
end

function t1.assert_eq(p53, p54, p55) -- line: 198
    -- upvalues: t1 (copy)
    if type(p53) ~= "table" or type(p54) ~= "table" then
        if p53 ~= p54 and (p53 == p53 or p54 == p54) then
            error(("%*: %* ~= %*"):format(p55 or "assert_eq", tostring(p53), (tostring(p54))), 2)
        end
    else
        for v35, v36 in p53 do
            t1.assert_eq(v36, p54[v35], (p55 or "") .. "[" .. tostring(v35) .. "]")
        end

        for v37 in p54 do
            if p53[v37] == nil then
                error(("%*[%*]: left is nil"):format(p55 or "value", v37), 2)
            end
        end
    end
end

function t1.assert_near(p56, p57, p58, p59) -- line: 214
    if not (math.abs(p56 - p57) <= p58) then
        error(("%*: %* vs %* (tolerance %*)"):format(p59 or "assert_near", p56, p57, p58), 2)
    end
end

function t1.assert(p60, p61) -- line: 219
    if not p60 then
        error(p61 or "assertion failed", 2)
    end
end

return t1
