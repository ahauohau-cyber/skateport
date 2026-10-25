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

local PointGraph = require(sim.import)("skate_core/point_graph").PointGraph
local t1 = {
    BodySpinState = {}
}

function t1.BodySpinState.new() -- line: 53
    return {
        words = table.create(44, 0)
    }
end

function t1.BodySpinState.from_words(p5) -- line: 57
    -- upvalues: rt (copy)
    if not (p5[43] < 30) then
        error("native derivative history index must be 0..30", 0)
    end

    return {
        words = rt.copy(p5)
    }
end

function t1.BodySpinState.words(p6) -- line: 65
    return p6.words
end

function t1.BodySpinState.speed(p7) -- line: 70
    -- upvalues: t1 (copy)
    return t1.BodySpinState.get(p7, 140)
end

function t1.BodySpinState.get(p8, p9) -- line: 74
    -- upvalues: rt (copy), v1 (copy)
    buffer.writeu32(v1, 0, p8.words[rt.idiv(p9, 4) + 1])

    return (buffer.readf32(v1, 0))
end

function t1.BodySpinState.set(p10, p11, p12) -- line: 78
    -- upvalues: rt (copy), v1 (copy)
    local words = p10.words
    local v13 = rt.idiv(p11, 4) + 1
    local v14

    if p12 ~= 0 and p12 > -1.1754943508222875E-38 and p12 < 1.1754943508222875E-38 then
        local v15 = math.abs(p12) * 7.1362384635298E+44
        local v16 = math.floor(v15)
        local v17 = v15 - v16

        v14 = if v17 > 0.5 or v17 == 0.5 and v16 % 2 == 1 then v16 + 1 else v16

        if p12 < 0 then
            v14 += 2147483648
        end
    else
        buffer.writef32(v1, 0, p12)
        v14 = buffer.readu32(v1, 0)
    end

    words[v13] = v14
end

local get2, set2 = t1.BodySpinState.get, t1.BodySpinState.set

t1.BodySpinSettings = {}
t1.STEP = 0.01666666753590107

local STEP = t1.STEP

function t1.update(p13, p14, p15, p16, p17, p18) -- line: 99
    -- upvalues: t1 (copy)
    t1.update_input(p13, p15, p16, p18)

    if p17 then
        t1.update_air(p13, p14, p15, p16, p18)
    else
        t1.finish_ground(p13, p15)
    end
end

function t1.update_ground(p19, p20) -- line: 111
    -- upvalues: t1 (copy)
    t1.update_input(p19, p20, 0, 0)
    t1.finish_ground(p19, p20)
end

function t1.update_input(p21, p22, p23, p24) -- line: 116
    -- upvalues: rt (copy), v1 (copy), t1 (copy), get2 (copy), set2 (copy)
    local v18 = (p22 - get2(p21, 120)) * 1.5 + get2(p21, 124) * 0
    local v19

    if v18 ~= 0 and v18 > -1.1754943508222875E-38 and v18 < 1.1754943508222875E-38 then
        local v20 = math.abs(v18) * 7.1362384635298E+44
        local v21 = math.floor(v20)
        local v22 = v20 - v21

        v19 = (if v22 > 0.5 or v22 == 0.5 and v21 % 2 == 1 then v21 + 1 else v21) * 1.401298464324817E-45

        if v18 < 0 then
            v19 = -v19
        end
    else
        buffer.writef32(v1, 0, v18)
        v19 = buffer.readf32(v1, 0)
    end

    set2(p21, 164, p23)
    set2(p21, 120, p22)
    p21.words[44] = bit32.bor(bit32.band(p21.words[44], 16777215), (bit32.lshift(p24, 24)))
    set2(p21, 124, v19)

    local v26 = v19 * p22
    local v27

    if v26 ~= 0 and v26 > -1.1754943508222875E-38 and v26 < 1.1754943508222875E-38 then
        local v28 = math.abs(v26) * 7.1362384635298E+44
        local v29 = math.floor(v28)
        local v30 = v28 - v29

        v27 = (if v30 > 0.5 or v30 == 0.5 and v29 % 2 == 1 then v29 + 1 else v29) * 1.401298464324817E-45

        if v26 < 0 then
            v27 = -v27
        end
    else
        buffer.writef32(v1, 0, v26)
        v27 = buffer.readf32(v1, 0)
    end

    buffer.writef32(v1, 0, 0.1)

    if not (buffer.readf32(v1, 0) < v27) then
        v19 = 0
    end

    local v31 = t1.native_clamp(v19, -1, 1)

    set2(p21, 128, v31)

    local v32 = p21.words[43]

    set2(p21, v32 * 4, v31)
    p21.words[43] = rt.irem(v32 + 1, 30)
end

function t1.finish_ground(p25, p26) -- line: 137
    -- upvalues: get2 (copy), set2 (copy)
    set2(p25, 152, 0)
    set2(p25, 144, 0)
    set2(p25, 140, 0)
    set2(p25, 132, get2(p25, 132) * 0.8 + p26 * 0.2)
end

function t1.update_air(p27, p28, p29, p30, p31) -- line: 144
    -- upvalues: PointGraph (copy), t1 (copy), get2 (copy), set2 (copy), STEP (copy)
    local v33 = if p31 == 0 then 1 else 0

    if get2(p27, 152) == 0 then
        t1.calculate_history_derivative(p27, p28.curves[v33 + 3 + 1])
    end

    local v34 = get2(p27, 152)
    local v35 = PointGraph.evaluate(p28.curves[v33 + 1], v34)
    local v36 = PointGraph.evaluate(p28.curves[3], v34)
    local v37 = PointGraph.evaluate(p28.curves[v33 + 3 + 1], v34) * get2(p27, 128)

    if math.abs(v37) > math.abs((get2(p27, 148))) then
        set2(p27, 148, v37)
        set2(p27, 156, v34)
    end

    local v40 = v34 + STEP

    set2(p27, 152, v40)

    local v41 = true

    for _, v42 in p28.input_fade_threshold do
        if not (math.abs((get2(p27, 120))) < v42) then
            v41 = false
            break
        end
    end

    if v41 then
        local v44 = get2(p27, 132) * 0.96

        set2(p27, 132, v44)
        set2(p27, 120, v44)
    else
        set2(p27, 132, get2(p27, 132) * 0.8 + p29 * 0.2)
    end

    local v45 = PointGraph.evaluate(p28.curves[v33 + 5 + 1], v40) * get2(p27, 120)

    set2(p27, 144, v45)

    if v45 * get2(p27, 148) < 0 then
        set2(p27, 148, 0)
    end

    local v47 = -((math.abs((get2(p27, 148))) * (1 - p28.derivative_floor) + p28.derivative_floor) * v45)
    local v48 = get2(p27, 140)
    local v49, v50

    if math.abs(p30) > 1.52587890625E-05 and (v48 * p30 > 0 or math.abs(v48) < 0.02) then
        v49 = v36
        v50 = t1.native_clamp(p30, -2, 2)
    else
        v49 = v35
        v50 = v47
    end

    local v51 = t1.select(p28.acceleration_limit - v49, v49, p28.acceleration_limit)
    local v52

    if v48 > 0 then
        v52 = -v51
    else
        v52 = -v49
        v49 = v51
    end

    local v53 = t1.native_clamp(v50 - v48, v52, v49)
    local v54 = v48 + v53

    set2(p27, 140, v54)
    set2(p27, 160, v50 - v54 - v53)
end

function t1.calculate_history_derivative(p32, p33) -- line: 207
    -- upvalues: rt (copy), PointGraph (copy), get2 (copy), set2 (copy), STEP (copy)
    local v55 = p32.words[43]
    local v56 = rt.irem(v55 + 29, 30)

    set2(p32, 148, 0)
    set2(p32, 156, 0)

    local n1 = 0
    local n2 = 0

    while v56 ~= v55 do
        n1 -= STEP

        local v57 = PointGraph.evaluate(p33, n1) * get2(p32, v56 * 4)

        if math.abs(v57) > math.abs(n2) then
            n2 = v57
            set2(p32, 156, n1)
        end

        v56 = rt.irem(v56 + 29, 30)
    end

    set2(p32, 148, n2)
end

function t1.select(p34, p35, p36) -- line: 226
    if p34 >= 0 then
        return p35
    end

    return p36
end

function t1.native_clamp(p37, p38, p39) -- line: 230
    -- upvalues: t1 (copy)
    local v58 = t1.select(p38 - p37, p38, p37)

    return t1.select(p39 - v58, v58, p39)
end

return t1
