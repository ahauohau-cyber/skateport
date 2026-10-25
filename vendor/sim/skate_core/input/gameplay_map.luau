-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_from_bits(p1) -- line: 7
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p1)

    return (buffer.readf32(v1, 0))
end

local Pad = require(sim.import)("skate_core/input/pad").Pad
local t1 = {}

t1.GameplayActions = {}

function t1.GameplayActions.from_values(p2) -- line: 27
    -- upvalues: rt (copy)
    return {
        values = rt.copy(p2)
    }
end

function t1.GameplayActions.values(p3) -- line: 31
    return p3.values
end

function t1.GameplayActions.eq(p4, p5) -- line: 36
    for i = 1, 18 do
        if p4.values[i] ~= p5.values[i] then
            return false
        end
    end

    return true
end

local v3 = false

function t1.set_reference(p6) -- line: 47
    -- upvalues: v3 (ref)
    v3 = p6
end

local t2 = {
    16, 17, 18, 19, 6, 20, 21, 22,
    23, 7, 10, 11, 8, 9, 0, 1,
    2, 3, 14, 15, 12, 13
}
local v4 = table.create(22, 0)

local function trim(p7) -- line: 56
    for v5 in p7 do
        if type(v5) ~= "number" or v5 < 1 or v5 > 18 or v5 % 1 ~= 0 then
            p7[v5] = nil
        end
    end
end

function t1.GameplayActions.from_pad_into(p8, p9) -- line: 70
    -- upvalues: rt (copy), Pad (copy), t2 (copy), v4 (copy), trim (copy)
    if Pad.count(p8) == 0 then
        v4[1] = 0
        v4[2] = 0
        v4[3] = 0
        v4[4] = 0
        v4[5] = 0
        v4[6] = 0
        v4[7] = 0
        v4[8] = 0
        v4[9] = 0
        v4[10] = 0
        v4[11] = 0
        v4[12] = 0
        v4[13] = 0
        v4[14] = 0
        v4[15] = 0
        v4[16] = 0
        v4[17] = 0
        v4[18] = 0
        v4[19] = 0
        v4[20] = 0
        v4[21] = 0
        v4[22] = 0
    else
        local v6 = Pad.records(p8)
        local from_bits = rt.from_bits

        for i = 1, 22 do
            local v7 = v6[t2[i] + 1]

            if v7 == nil then
                error("index out of bounds", 0)
            end

            v4[i] = from_bits(v7[1])
        end
    end

    p9[1] = v4[1] - v4[2]
    p9[2] = v4[3] - v4[4]
    p9[3] = v4[5]
    p9[4] = v4[6] - v4[7]
    p9[5] = v4[8] - v4[9]
    p9[6] = v4[10]
    p9[7] = v4[11]
    p9[8] = v4[12]
    p9[9] = v4[13]
    p9[10] = v4[14]
    p9[11] = v4[15]
    p9[12] = v4[16]
    p9[13] = v4[17]
    p9[14] = v4[18]
    p9[15] = v4[19]
    p9[16] = v4[20]
    p9[17] = v4[21]
    p9[18] = v4[22]
    trim(p9)

    return p9
end

function t1.GameplayActions.zeros_into(p10) -- line: 110
    -- upvalues: trim (copy)
    p10[1] = 0
    p10[2] = 0
    p10[3] = 0
    p10[4] = 0
    p10[5] = 0
    p10[6] = 0
    p10[7] = 0
    p10[8] = 0
    p10[9] = 0
    p10[10] = 0
    p10[11] = 0
    p10[12] = 0
    p10[13] = 0
    p10[14] = 0
    p10[15] = 0
    p10[16] = 0
    p10[17] = 0
    p10[18] = 0
    trim(p10)

    return p10
end

function t1.GameplayActions.from_pad(p11) -- line: 122
    -- upvalues: t1 (copy), v3 (ref)
    if v3 then
        return t1.GameplayActions.from_pad_reference(p11)
    end

    return {
        values = t1.GameplayActions.from_pad_into(p11, table.create(18))
    }
end

function t1.GameplayActions.from_pad_reference(p12) -- line: 130
    -- upvalues: v1 (copy), Pad (copy)
    local function value(p13) -- line: 131
        -- upvalues: p12 (copy), v1 (copy), Pad (copy)
        if Pad.count(p12) == 0 then
            return 0
        end

        local v8 = Pad.records(p12)[p13 + 1]

        if v8 == nil then
            error("index out of bounds", 0)
        end

        buffer.writeu32(v1, 0, v8[1])

        return (buffer.readf32(v1, 0))
    end

    local t3 = {}
    local v10

    if Pad.count(p12) == 0 then
        v10 = 0
    else
        local v11 = Pad.records(p12)[17]

        if v11 == nil then
            error("index out of bounds", 0)
        end

        buffer.writeu32(v1, 0, v11[1])
        v10 = buffer.readf32(v1, 0)
    end

    local v13

    if Pad.count(p12) == 0 then
        v13 = 0
    else
        local v14 = Pad.records(p12)[18]

        if v14 == nil then
            error("index out of bounds", 0)
        end

        buffer.writeu32(v1, 0, v14[1])
        v13 = buffer.readf32(v1, 0)
    end

    local v16 = v10 - v13
    local v17

    if Pad.count(p12) == 0 then
        v17 = 0
    else
        local v18 = Pad.records(p12)[19]

        if v18 == nil then
            error("index out of bounds", 0)
        end

        buffer.writeu32(v1, 0, v18[1])
        v17 = buffer.readf32(v1, 0)
    end

    local v20

    if Pad.count(p12) == 0 then
        v20 = 0
    else
        local v21 = Pad.records(p12)[20]

        if v21 == nil then
            error("index out of bounds", 0)
        end

        buffer.writeu32(v1, 0, v21[1])
        v20 = buffer.readf32(v1, 0)
    end

    local v23 = v17 - v20
    local v24

    if Pad.count(p12) == 0 then
        v24 = 0
    else
        local v25 = Pad.records(p12)[7]

        if v25 == nil then
            error("index out of bounds", 0)
        end

        buffer.writeu32(v1, 0, v25[1])
        v24 = buffer.readf32(v1, 0)
    end

    local v27

    if Pad.count(p12) == 0 then
        v27 = 0
    else
        local v28 = Pad.records(p12)[21]

        if v28 == nil then
            error("index out of bounds", 0)
        end

        buffer.writeu32(v1, 0, v28[1])
        v27 = buffer.readf32(v1, 0)
    end

    local v30

    if Pad.count(p12) == 0 then
        v30 = 0
    else
        local v31 = Pad.records(p12)[22]

        if v31 == nil then
            error("index out of bounds", 0)
        end

        buffer.writeu32(v1, 0, v31[1])
        v30 = buffer.readf32(v1, 0)
    end

    local v33 = v27 - v30
    local v34

    if Pad.count(p12) == 0 then
        v34 = 0
    else
        local v35 = Pad.records(p12)[23]

        if v35 == nil then
            error("index out of bounds", 0)
        end

        buffer.writeu32(v1, 0, v35[1])
        v34 = buffer.readf32(v1, 0)
    end

    local v37

    if Pad.count(p12) == 0 then
        v37 = 0
    else
        local v38 = Pad.records(p12)[24]

        if v38 == nil then
            error("index out of bounds", 0)
        end

        buffer.writeu32(v1, 0, v38[1])
        v37 = buffer.readf32(v1, 0)
    end

    local v40 = v34 - v37
    local v41

    if Pad.count(p12) == 0 then
        v41 = 0
    else
        local v42 = Pad.records(p12)[8]

        if v42 == nil then
            error("index out of bounds", 0)
        end

        buffer.writeu32(v1, 0, v42[1])
        v41 = buffer.readf32(v1, 0)
    end

    local v44

    if Pad.count(p12) == 0 then
        v44 = 0
    else
        local v45 = Pad.records(p12)[11]

        if v45 == nil then
            error("index out of bounds", 0)
        end

        buffer.writeu32(v1, 0, v45[1])
        v44 = buffer.readf32(v1, 0)
    end

    local v47

    if Pad.count(p12) == 0 then
        v47 = 0
    else
        local v48 = Pad.records(p12)[12]

        if v48 == nil then
            error("index out of bounds", 0)
        end

        buffer.writeu32(v1, 0, v48[1])
        v47 = buffer.readf32(v1, 0)
    end

    local v50

    if Pad.count(p12) == 0 then
        v50 = 0
    else
        local v51 = Pad.records(p12)[9]

        if v51 == nil then
            error("index out of bounds", 0)
        end

        buffer.writeu32(v1, 0, v51[1])
        v50 = buffer.readf32(v1, 0)
    end

    local v53

    if Pad.count(p12) == 0 then
        v53 = 0
    else
        local v54 = Pad.records(p12)[10]

        if v54 == nil then
            error("index out of bounds", 0)
        end

        buffer.writeu32(v1, 0, v54[1])
        v53 = buffer.readf32(v1, 0)
    end

    local v56

    if Pad.count(p12) == 0 then
        v56 = 0
    else
        local v57 = Pad.records(p12)[1]

        if v57 == nil then
            error("index out of bounds", 0)
        end

        buffer.writeu32(v1, 0, v57[1])
        v56 = buffer.readf32(v1, 0)
    end

    local v59

    if Pad.count(p12) == 0 then
        v59 = 0
    else
        local v60 = Pad.records(p12)[2]

        if v60 == nil then
            error("index out of bounds", 0)
        end

        buffer.writeu32(v1, 0, v60[1])
        v59 = buffer.readf32(v1, 0)
    end

    local v62

    if Pad.count(p12) == 0 then
        v62 = 0
    else
        local v63 = Pad.records(p12)[3]

        if v63 == nil then
            error("index out of bounds", 0)
        end

        buffer.writeu32(v1, 0, v63[1])
        v62 = buffer.readf32(v1, 0)
    end

    local v65

    if Pad.count(p12) == 0 then
        v65 = 0
    else
        local v66 = Pad.records(p12)[4]

        if v66 == nil then
            error("index out of bounds", 0)
        end

        buffer.writeu32(v1, 0, v66[1])
        v65 = buffer.readf32(v1, 0)
    end

    local v68

    if Pad.count(p12) == 0 then
        v68 = 0
    else
        local v69 = Pad.records(p12)[15]

        if v69 == nil then
            error("index out of bounds", 0)
        end

        buffer.writeu32(v1, 0, v69[1])
        v68 = buffer.readf32(v1, 0)
    end

    local v71

    if Pad.count(p12) == 0 then
        v71 = 0
    else
        local v72 = Pad.records(p12)[16]

        if v72 == nil then
            error("index out of bounds", 0)
        end

        buffer.writeu32(v1, 0, v72[1])
        v71 = buffer.readf32(v1, 0)
    end

    local t4 = {}

    t4[1] = v16
    t4[2] = v23
    t4[3] = v24
    t4[4] = v33
    t4[5] = v40
    t4[6] = v41
    t4[7] = v44
    t4[8] = v47
    t4[9] = v50
    t4[10] = v53
    t4[11] = v56
    t4[12] = v59
    t4[13] = v62
    t4[14] = v65
    t4[15] = v68
    t4[16] = v71

    local v74

    if Pad.count(p12) == 0 then
        v74 = 0
    else
        local v75 = Pad.records(p12)[13]

        if v75 == nil then
            error("index out of bounds", 0)
        end

        buffer.writeu32(v1, 0, v75[1])
        v74 = buffer.readf32(v1, 0)
    end

    local v77

    if Pad.count(p12) == 0 then
        v77 = 0
    else
        local v78 = Pad.records(p12)[14]

        if v78 == nil then
            error("index out of bounds", 0)
        end

        buffer.writeu32(v1, 0, v78[1])
        v77 = buffer.readf32(v1, 0)
    end

    t4[17] = v74
    t4[18] = v77
    t3.values = t4

    return t3
end

function t1.GameplayActions.value(p14, p15) -- line: 167
    if p15 < 64 then
        error("gameplay action below 64", 0)
    end

    local v80 = p14.values[p15 - 64 + 1]

    if v80 == nil then
        error("index out of bounds", 0)
    end

    return v80
end

function t1.GameplayActions.state(p16, p17) -- line: 178
    -- upvalues: t1 (copy)
    if t1.GameplayActions.value(p16, p17) == 0 then
        return 0
    end

    return 1
end

return t1
