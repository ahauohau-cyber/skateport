-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

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

local AttributeName = require(sim.import)("skate_core/animation/output/attributes").AttributeName
local t1 = {}

local function words_eq(p4, p5) -- line: 39
    if p4[1] == p5[1] and p4[2] == p5[2] and p4[3] == p5[3] and p4[4] == p5[4] then
        return p4[5] == p5[5]
    end

    return false
end

local function words_lt(p6, p7) -- line: 49
    for i = 1, 5 do
        if p6[i] < p7[i] then
            return true
        end

        if p6[i] > p7[i] then
            return false
        end
    end

    return false
end

local t2 = {
    0
}
local t3 = {
    0, 1, 2, 3
}
local t4 = {
    5
}
local t5 = {}

t1.AttributeMirror = {}

function t1.AttributeMirror.apply(p8, p9) -- line: 72
    local kind = p9.kind

    if kind == 1 then
        local v8 = p9.payload[1][1]

        if v8 == nil then
            error("Uninitialized mirrored vector attribute", 0)
        end

        p9.payload[1][1] = bit32.bxor(v8, 2147483648)
    elseif kind == 3 then
        local t6 = {
            0, 0, 0, 0, 0
        }

        for i = 0, 4 do
            local v9 = p9.payload[1][i + 1]

            if v9 == nil then
                error("Uninitialized mirrored bone reference", 0)
            end

            t6[i + 1] = v9
        end

        local v10

        for _, v11 in p8[1] do
            local v12 = v11[1][1]

            if v12[1] == t6[1] and v12[2] == t6[2] and v12[3] == t6[3] and v12[4] == t6[4] and v12[5] == t6[5] then
                v10 = v11[2]
                break
            end

            v10 = nil
        end

        if v10 == nil then
            error("Animation event bone is absent from its hierarchy", 0)
        end

        p9.payload[1][1] = v10[1][1]
        p9.payload[1][2] = v10[1][2]
        p9.payload[1][3] = v10[1][3]
        p9.payload[1][4] = v10[1][4]
        p9.payload[1][5] = v10[1][5]
    end
end

local numeric_lanes

function t1.blend(p10, p11, p12) -- line: 109
    -- upvalues: v1 (copy), t2 (copy), t3 (copy), t4 (copy), t5 (copy)
    local v13 = 1 - p12

    if bit32.band(p10.status, 2) == 0 then
        p10.begin_time = p11.begin_time * p12 + p10.begin_time * v13
        p10.end_time = p11.end_time * p12 + p10.end_time * v13
    else
        p10.begin_time = -1
        p10.end_time = -1
    end

    local v14 = if p10.kind == 0 or p10.kind == 2 then t2
        elseif p10.kind == 1 then t3
        elseif p10.kind == 3 then t4
        else t5

    for _, v15 in v14 do
        local v16 = p10.payload[1][v15 + 1]

        if v16 == nil then
            error("Uninitialized blended attribute payload", 0)
        end

        buffer.writeu32(v1, 0, v16)

        local v17 = buffer.readf32(v1, 0)
        local v18 = p11.payload[1][v15 + 1]

        if v18 == nil then
            error("Uninitialized blended attribute payload", 0)
        end

        buffer.writeu32(v1, 0, v18)

        local v19 = buffer.readf32(v1, 0)
        local v20 = p10.payload[1]
        local v21 = v15 + 1
        local v22 = v19 * p12 + v17 * v13
        local v23

        if v22 == 0 then
            buffer.writef32(v1, 0, v22)
            v23 = buffer.readu32(v1, 0)
        elseif v22 > -1.1754943508222875E-38 and v22 < 1.1754943508222875E-38 then
            local v24 = math.abs(v22) * 7.1362384635298E+44

            v23 = math.floor(v24)

            local v25 = v24 - v23

            if v25 > 0.5 or v25 == 0.5 and v23 % 2 == 1 then
                v23 += 1
            end

            if v22 < 0 then
                v23 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v22)
            v23 = buffer.readu32(v1, 0)
        end

        v20[v21] = v23
    end
end

function t1.scale(p13, p14) -- line: 145
    -- upvalues: v1 (copy), numeric_lanes (ref)
    if bit32.band(p13.status, 2) == 0 then
        p13.begin_time *= p14
        p13.end_time *= p14
    else
        p13.begin_time = -1
        p13.end_time = -1
    end

    for _, v26 in numeric_lanes(p13.kind) do
        local v27 = p13.payload[1][v26 + 1]

        if v27 == nil then
            error("Uninitialized weighted attribute", 0)
        end

        buffer.writeu32(v1, 0, v27)

        local v28 = buffer.readf32(v1, 0)
        local v29 = p13.payload[1]
        local v30 = v26 + 1
        local v31 = v28 * p14
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

        v29[v30] = v32
    end
end

function t1.add_weighted(p15, p16, p17) -- line: 164
    -- upvalues: v1 (copy), numeric_lanes (ref)
    if bit32.band(p15.status, 2) == 0 then
        p15.begin_time += p16.begin_time * p17
        p15.end_time += p16.end_time * p17
    end

    for _, v35 in numeric_lanes(p15.kind) do
        local v36 = p15.payload[1][v35 + 1]

        if v36 == nil then
            error("Uninitialized weighted attribute", 0)
        end

        buffer.writeu32(v1, 0, v36)

        local v37 = buffer.readf32(v1, 0)
        local v38 = p16.payload[1][v35 + 1]

        if v38 == nil then
            error("Uninitialized weighted attribute", 0)
        end

        buffer.writeu32(v1, 0, v38)

        local v39 = buffer.readf32(v1, 0) * p17 + v37
        local v40 = p15.payload[1]
        local v41 = v35 + 1
        local v42

        if v39 == 0 then
            buffer.writef32(v1, 0, v39)
            v42 = buffer.readu32(v1, 0)
        elseif v39 > -1.1754943508222875E-38 and v39 < 1.1754943508222875E-38 then
            local v43 = math.abs(v39) * 7.1362384635298E+44

            v42 = math.floor(v43)

            local v44 = v43 - v42

            if v44 > 0.5 or v44 == 0.5 and v42 % 2 == 1 then
                v42 += 1
            end

            if v39 < 0 then
                v42 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v39)
            v42 = buffer.readu32(v1, 0)
        end

        v40[v41] = v42
    end
end

function t1.numeric_lanes(p18) -- line: 186
    -- upvalues: t2 (copy), t3 (copy), t4 (copy), t5 (copy)
    if p18 == 0 or p18 == 2 then
        return t2
    end

    if p18 == 1 then
        return t3
    end

    if p18 == 3 then
        return t4
    end

    return t5
end

numeric_lanes = t1.numeric_lanes

function t1.intersection(p19, p20, p21) -- line: 202
    -- upvalues: AttributeName (copy), t1 (copy), words_lt (copy)
    local t7 = {}
    local n1 = 0

    for _, v45 in p19 do
        while true do
            if n1 < #p20 and words_lt(p20[n1 + 1].name[1], v45.name[1]) then
                n1 += 1
                continue
            end

            local v46 = p20[n1 + 1]

            if v46 == nil then
                return t7
            end

            if AttributeName.eq(v46.name, v45.name) then
                t1.blend(v45, v46, p21)
                table.insert(t7, v45)
            end

            break
        end
    end

    return t7
end

return t1
