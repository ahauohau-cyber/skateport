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

local estimate = require(sim.import)("skate_core/physics/reciprocal_sqrt").estimate
local t1 = {}

t1.ActionMap = {}
t1.RawControllerInput = {}

function t1.RawControllerInput.from_words(p5) -- line: 57
    -- upvalues: rt (copy)
    return {
        words = rt.copy(p5)
    }
end

function t1.RawControllerInput.words(p6) -- line: 61
    return p6.words
end

function t1.RawControllerInput.eq(p7, p8) -- line: 66
    for i = 1, 7 do
        if p7.words[i] ~= p8.words[i] then
            return false
        end
    end

    return true
end

local v13 = false

function t1.set_reference(p9) -- line: 77
    -- upvalues: v13 (ref)
    v13 = p9
end

local v14 = table.freeze({ 64, 65, 67, 68, 70, 71 })
local v15 = table.freeze({
    table.freeze({ 66, 31 }),
    table.freeze({ 69, 30 }),
    table.freeze({ 72, 29 }),
    table.freeze({ 73, 28 })
})
local v16 = table.freeze({
    table.freeze({ 14, 4 }),
    table.freeze({ 15, 5 })
})
local v17 = table.freeze({
    table.freeze({ 31, 16, 17 }),
    table.freeze({ 30, 18, 19 })
})
local v18 = table.freeze({
    table.freeze({ 20, 80 }),
    table.freeze({ 21, 81 }),
    table.freeze({ 22, 78 }),
    table.freeze({ 23, 79 })
})
local t2 = {
    words = table.create(7, 0)
}
local t3 = {
    words = table.create(7, 0)
}

function t1.RawControllerInput.update(p10, p11, p12, p13, p14) -- line: 99
    -- upvalues: v1 (copy), t1 (copy), v13 (ref), v14 (copy), v15 (copy)
    if v13 then
        return t1.RawControllerInput.update_reference(p10, p11, p12, p13, p14)
    end

    for i = 0, 5 do
        local v19 = v14[i + 1]
        local words = p10.words
        local v20 = i + 1
        local v21 = p12.value(p12, v19)

        if v21 ~= 0 and v21 > -1.1754943508222875E-38 and v21 < 1.1754943508222875E-38 then
            local v22 = math.abs(v21) * 7.1362384635298E+44
            local v23 = math.floor(v22)
            local v24 = v22 - v23
            local v25 = if v24 > 0.5 or v24 == 0.5 and v23 % 2 == 1 then v23 + 1 else v23

            if v21 < 0 then
                words[v20] = v25 + 2147483648
            else
                words[v20] = v25
            end
        else
            buffer.writef32(v1, 0, v21)
            words[v20] = buffer.readu32(v1, 0)
        end
    end

    for _, v26 in v15 do
        local v27 = v26[1]
        local v28 = v26[2]

        t1.RawControllerInput.set_bit(p10, v28, p12.state(p12, v27))
    end

    if bit32.band(p10.words[7], 805306368) == 805306368 then
        local v31 = bit32.band(p11.words[7], 805306368)

        if v31 ~= 536870912 and v31 ~= 268435456 or not p13 and not p14 then
            p10.words[7] = bit32.band(p10.words[7], 4026531839)
        else
            p10.words[7] = bit32.bor(bit32.band(p10.words[7], 3489660927), v31)
        end
    end

    for i = 74, 81 do
        t1.RawControllerInput.set_bit(p10, 101 - i, p12.state(p12, i))
    end
end

function t1.RawControllerInput.update_reference(p15, p16, p17, p18, p19) -- line: 128
    -- upvalues: v1 (copy), t1 (copy)
    local t4 = {
        64, 65, 67, 68, 70, 71
    }

    for i = 0, 5 do
        local v35 = t4[i + 1]
        local words = p15.words
        local v36 = i + 1
        local v37 = p17.value(p17, v35)

        if v37 ~= 0 and v37 > -1.1754943508222875E-38 and v37 < 1.1754943508222875E-38 then
            local v38 = math.abs(v37) * 7.1362384635298E+44
            local v39 = math.floor(v38)
            local v40 = v38 - v39
            local v41 = if v40 > 0.5 or v40 == 0.5 and v39 % 2 == 1 then v39 + 1 else v39

            if v37 < 0 then
                words[v36] = v41 + 2147483648
            else
                words[v36] = v41
            end
        else
            buffer.writef32(v1, 0, v37)
            words[v36] = buffer.readu32(v1, 0)
        end
    end

    for _, v42 in {
            { 66, 31 },
            { 69, 30 },
            { 72, 29 },
            { 73, 28 }
        } do
        local v43 = v42[1]
        local v44 = v42[2]

        t1.RawControllerInput.set_bit(p15, v44, p17.state(p17, v43))
    end

    if bit32.band(p15.words[7], 805306368) == 805306368 then
        local v47 = bit32.band(p16.words[7], 805306368)

        if v47 ~= 536870912 and v47 ~= 268435456 or not p18 and not p19 then
            p15.words[7] = bit32.band(p15.words[7], 4026531839)
        else
            p15.words[7] = bit32.bor(bit32.band(p15.words[7], 3489660927), v47)
        end
    end

    for i = 74, 81 do
        t1.RawControllerInput.set_bit(p15, 101 - i, p17.state(p17, i))
    end
end

function t1.RawControllerInput.set_bit(p20, p21, p22) -- line: 153
    p20.words[7] = bit32.bor(bit32.band(p20.words[7], (bit32.bnot((bit32.lshift(1, p21))))), (bit32.lshift(bit32.band(p22, 1), p21)))
end

t1.MagnitudeHeldSettings = {}
t1.DerivedControllerInput = {}

function t1.DerivedControllerInput.from_words(p23) -- line: 169
    -- upvalues: rt (copy)
    return {
        words = rt.copy(p23)
    }
end

function t1.DerivedControllerInput.words(p24) -- line: 173
    return p24.words
end

function t1.DerivedControllerInput.eq(p25, p26) -- line: 178
    for i = 1, 26 do
        if p25.words[i] ~= p26.words[i] then
            return false
        end
    end

    return true
end

function t1.DerivedControllerInput.initialize(p27) -- line: 192
    local v58 = bit32.band(p27.words[7], 1048575)
    local v60 = bit32.band(p27.words[14], 1048575)

    p27.words = table.create(26, 0)
    p27.words[7] = v58
    p27.words[14] = v60
    p27.words[17] = 2130706431
    p27.words[18] = 2130706431
    p27.words[19] = 2130706431
    p27.words[20] = 2130706431
end

function t1.DerivedControllerInput.update(p28, p29, p30, p31, p32, p33) -- line: 212
    -- upvalues: v1 (copy), t1 (copy), v13 (ref), v16 (copy), v17 (copy), v18 (copy), t2 (copy), t3 (copy)
    local words = p28.words

    if v13 or #words ~= 26 then
        return t1.DerivedControllerInput.update_reference(p28, p29, p30, p31, p32, p33)
    end

    local words2 = t2.words
    local words3 = t3.words
    local v61 = words[8]

    words2[1] = v61
    words3[1] = v61

    local v62 = words[9]

    words2[2] = v62
    words3[2] = v62

    local v63 = words[10]

    words2[3] = v63
    words3[3] = v63

    local v64 = words[11]

    words2[4] = v64
    words3[4] = v64

    local v65 = words[12]

    words2[5] = v65
    words3[5] = v65

    local v66 = words[13]

    words2[6] = v66
    words3[6] = v66

    local v67 = words[14]

    words2[7] = v67
    words3[7] = v67
    words[1] = words2[1]
    words[2] = words2[2]
    words[3] = words2[3]
    words[4] = words2[4]
    words[5] = words2[5]
    words[6] = words2[6]
    words[7] = words2[7]
    t1.RawControllerInput.update(t3, t2, p29, p31, p32)
    words[8] = words3[1]
    words[9] = words3[2]
    words[10] = words3[3]
    words[11] = words3[4]
    words[12] = words3[5]
    words[13] = words3[6]
    words[14] = words3[7]

    for _, v68 in v16 do
        local v69 = v68[1]
        local v70 = v68[2]
        local advance_or_reset = t1.DerivedControllerInput.advance_or_reset

        buffer.writeu32(v1, 0, words3[v70 + 1])
        advance_or_reset(p28, v69, buffer.readf32(v1, 0) == 1, p30)
    end

    local v72 = words2[7]
    local v73 = words3[7]

    for _, v74 in v17 do
        local v75 = v74[1]
        local v76 = v74[2]
        local v77 = v74[3]
        local v79 = bit32.band(v72, (bit32.lshift(1, v75))) ~= 0
        local v81 = bit32.band(v73, (bit32.lshift(1, v75))) ~= 0

        t1.DerivedControllerInput.advance_or_reset(p28, v76, not (not v79 and v81), p30)
        t1.DerivedControllerInput.advance_or_reset(p28, v77, not (v79 and not v81), p30)
    end

    for _, v82 in v18 do
        local v83 = v82[1]
        local v84 = v82[2]

        t1.DerivedControllerInput.advance_or_reset(p28, v83, p29.state(p29, v84) ~= 0, p30)
    end

    local v85 = p29.value(p29, 64)
    local v86 = p29.value(p29, 65)
    local v87 = p29.value(p29, 67)
    local v88 = p29.value(p29, 68)
    local v89 = t1.magnitude(v88 * v88 + v87 * v87)
    local v90 = t1.magnitude(v86 * v86 + v85 * v85)
    local v91 = if p33.attribute == nil then p33.missing_attribute_value else p33.attribute

    t1.DerivedControllerInput.advance_or_reset(p28, 24, not (v90 <= v91), p30)
    t1.DerivedControllerInput.advance_or_reset(p28, 25, not (v89 <= v91), p30)
end

function t1.DerivedControllerInput.update_reference(p34, p35, p36, p37, p38, p39) -- line: 274
    -- upvalues: rt (copy), v1 (copy), t1 (copy)
    local v92 = t1.RawControllerInput.from_words(rt.slice(p34.words, 7, 14))
    local v93 = t1.RawControllerInput.words(v92)

    p34.words[1] = v93[1]
    p34.words[2] = v93[2]
    p34.words[3] = v93[3]
    p34.words[4] = v93[4]
    p34.words[5] = v93[5]
    p34.words[6] = v93[6]
    p34.words[7] = v93[7]

    local v94 = rt.copy(v92)

    t1.RawControllerInput.update(v94, v92, p35, p37, p38)

    local v95 = t1.RawControllerInput.words(v94)

    p34.words[8] = v95[1]
    p34.words[9] = v95[2]
    p34.words[10] = v95[3]
    p34.words[11] = v95[4]
    p34.words[12] = v95[5]
    p34.words[13] = v95[6]
    p34.words[14] = v95[7]

    for _, v96 in {
            { 14, 4 },
            { 15, 5 }
        } do
        local v97 = v96[1]
        local v98 = v96[2]
        local advance_or_reset = t1.DerivedControllerInput.advance_or_reset

        buffer.writeu32(v1, 0, v94.words[v98 + 1])
        advance_or_reset(p34, v97, buffer.readf32(v1, 0) == 1, p36)
    end

    local v100 = v92.words[7]
    local v101 = v94.words[7]

    for _, v102 in {
            { 31, 16, 17 },
            { 30, 18, 19 }
        } do
        local v103 = v102[1]
        local v104 = v102[2]
        local v105 = v102[3]
        local v107 = bit32.band(v100, (bit32.lshift(1, v103))) ~= 0
        local v109 = bit32.band(v101, (bit32.lshift(1, v103))) ~= 0

        t1.DerivedControllerInput.advance_or_reset(p34, v104, not (not v107 and v109), p36)
        t1.DerivedControllerInput.advance_or_reset(p34, v105, not (v107 and not v109), p36)
    end

    for _, v110 in {
            { 20, 80 },
            { 21, 81 },
            { 22, 78 },
            { 23, 79 }
        } do
        local v111 = v110[1]
        local v112 = v110[2]

        t1.DerivedControllerInput.advance_or_reset(p34, v111, p35.state(p35, v112) ~= 0, p36)
    end

    local v113 = p35.value(p35, 64)
    local v114 = p35.value(p35, 65)
    local v115 = p35.value(p35, 67)
    local v116 = p35.value(p35, 68)
    local v117 = t1.magnitude(v116 * v116 + v115 * v115)
    local v118 = t1.magnitude(v114 * v114 + v113 * v113)
    local v119 = if p39.attribute == nil then p39.missing_attribute_value else p39.attribute

    t1.DerivedControllerInput.advance_or_reset(p34, 24, not (v118 <= v119), p36)
    t1.DerivedControllerInput.advance_or_reset(p34, 25, not (v117 <= v119), p36)
end

function t1.DerivedControllerInput.advance_or_reset(p40, p41, p42, p43) -- line: 332
    -- upvalues: v1 (copy)
    if not p42 then
        p40.words[p41 + 1] = 0

        return
    end

    local words = p40.words
    local v120 = p41 + 1

    buffer.writeu32(v1, 0, p40.words[p41 + 1])

    local v122 = buffer.readf32(v1, 0) + p43
    local v123

    if v122 ~= 0 and v122 > -1.1754943508222875E-38 and v122 < 1.1754943508222875E-38 then
        local v124 = math.abs(v122) * 7.1362384635298E+44
        local v125 = math.floor(v124)
        local v126 = v124 - v125

        v123 = if v126 > 0.5 or v126 == 0.5 and v125 % 2 == 1 then v125 + 1 else v125

        if v122 < 0 then
            v123 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v122)
        v123 = buffer.readu32(v1, 0)
    end

    words[v120] = v123
end

function t1.magnitude(p44) -- line: 342
    -- upvalues: v1 (copy), estimate (copy)
    local v127

    if p44 ~= 0 and p44 > -1.1754943508222875E-38 and p44 < 1.1754943508222875E-38 then
        local v128 = math.abs(p44) * 7.1362384635298E+44
        local v129 = math.floor(v128)
        local v130 = v128 - v129

        v127 = (if v130 > 0.5 or v130 == 0.5 and v129 % 2 == 1 then v129 + 1 else v129) * 1.401298464324817E-45

        if p44 < 0 then
            v127 = -v127
        end
    else
        buffer.writef32(v1, 0, p44)
        v127 = buffer.readf32(v1, 0)
    end

    local v131 = estimate(v127)
    local v132 = -v127 * (v131 * v131) + 1
    local v133 = v131 * 0.5 * v132 + v131
    local v134 = -v127 * (v133 * v133) + 1
    local v135 = v133 * 0.5 * v134 + v133

    if v127 == 0 then
        return 0
    end

    return v127 * v135
end

return t1
