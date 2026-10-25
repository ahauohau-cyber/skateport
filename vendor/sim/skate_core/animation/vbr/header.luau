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

require(sim.import)

local t1 = {
    Channel = {},
    Header = {}
}

function t1.Header.read(p2, p3, p4, p5) -- line: 31
    -- upvalues: rt (copy), v1 (copy), t1 (copy)
    local v2 = t1.u32_at(p2, p3)
    local v4 = bit32.band(bit32.rshift(v2, 6), 63) + 1
    local v5 = t1.offset(p3, p4)
    local v6 = t1.offset(v5, (bit32.rshift(v2, 12)))
    local v7 = t1.offset(p3, p5)
    local v8 = t1.offset(v7, t1.u32_at(p2, t1.offset(p3, 4)))

    if v6 < v5 then
        error("VBR header range", 0)
    end

    t1.take(p2, v5, v6 - v5)

    if v8 < v7 then
        error("VBR data range", 0)
    end

    t1.take(p2, v7, v8 - v7)

    local v9 = t1.u16_at(p2, v5 + 2)
    local v10 = t1.take(p2, v5 + 12, 2)
    local v11 = buffer.readu8(p2, v10)
    local v13 = buffer.readu8(p2, v10 + 1)

    if v11 ~= 3 or v9 == 0 then
        error("VBR SQT requires three channel types and a nonempty frame range", 0)
    end

    local v14 = v5 + 16
    local v15 = t1.offset(v14, v13 * 4)
    local v17 = math.ceil(v9 / 8)
    local v18 = t1.offset(t1.offset(v15, v17 * 2), 15)
    local v19 = v18 - rt.irem(v18, 16)

    if v6 < t1.offset(v19, 48) then
        error("VBR channel descriptions exceed compression header", 0)
    end

    local v20 = table.create(3)
    local t2 = {
        3, 4, 3
    }

    for i = 0, 2 do
        local v21 = t2[i + 1]
        local v22 = v19 + i * 16
        local v23 = t1.u16_at(p2, v22)
        local v24 = t1.u16_at(p2, v22 + 2)
        local v26 = buffer.readu8(p2, (t1.take(p2, v22 + 12, 1)))

        buffer.writeu32(v1, 0, (t1.u32_at(p2, v22 + 4)))

        local v28 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, (t1.u32_at(p2, v22 + 8)))

        local v30 = buffer.readf32(v1, 0)

        if v26 ~= v21 or v23 + v24 ~= v4 then
            error(("VBR channel %* does not match its SQT output descriptor"):format(i), 0)
        end

        table.insert(v20, {
            dynamic = v23,
            constant = v24,
            components = v26,
            min = v28,
            range = v30 - v28
        })
    end

    local t4 = {}

    for _, v31 in ipairs(v20) do
        for _ = 0, v31.constant * v31.components - 1 do
            local v33 = buffer.readu8(p2, (t1.take(p2, v7, 1)))

            v7 += 1

            if v13 <= v33 then
                error("VBR constant dictionary index out of bounds", 0)
            end

            buffer.writeu32(v1, 0, (t1.u32_at(p2, v14 + v33 * 4)))
            table.insert(t4, buffer.readf32(v1, 0) * v31.range + v31.min)
        end
    end

    local v36 = t1.u16_at(p2, v5)
    local v37 = table.create(v4 * 3)

    for i = 0, v36 - 1 do
        local v39 = buffer.readu8(p2, (t1.take(p2, v7, 1)))

        v7 += 1

        if #v37 + v39 > v4 * 3 then
            error("VBR constant-channel run exceeds channel count", 0)
        end

        local v40 = rt.irem(i, 2) == 1

        for _ = 1, v39 do
            table.insert(v37, v40)
        end
    end

    if v36 == 0 and #t4 == 0 then
        for i = #v37 + 1, v4 * 3 do
            v37[i] = false
        end
    end

    if #v37 ~= v4 * 3 then
        error("VBR constant-channel runs do not cover all channels", 0)
    end

    for v41, v42 in ipairs(v20) do
        local v43 = v41 - 1
        local v44 = v43 * v4
        local v45 = (v43 + 1) * v4 - 1
        local n1 = 0

        for j = v44, v45 do
            if v37[j + 1] then
                n1 += 1
            end
        end

        if n1 ~= v42.constant then
            error(("VBR channel %* constant count differs from its runs"):format(v43), 0)
        end
    end

    local n2 = 0

    for _, v46 in ipairs(v20) do
        n2 += v46.dynamic * v46.components
    end

    local v47 = table.create(n2)

    for _ = 0, n2 - 1 do
        table.insert(v47, t1.u32_at(p2, v7))
        v7 += 4
    end

    local v48 = table.create(v17)
    local v49 = v17 - 1
    local n3 = 0

    for i = 0, v49 do
        local v50 = t1.u16_at(p2, v15 + i * 2)
        local v51 = t1.offset(v7, n3)
        local v52 = t1.offset(v51, v50)

        if v8 < v52 or v52 < v51 or v50 < 3 then
            error(("VBR block %* exceeds compressed data"):format(i), 0)
        end

        table.insert(v48, {
            start = v51,
            ["end"] = v52
        })
        n3 = (n3 + v50) % 65536
    end

    buffer.writeu32(v1, 0, (t1.u32_at(p2, v5 + 4)))

    local v55 = math.abs((buffer.readf32(v1, 0)))

    buffer.writeu32(v1, 0, (t1.u32_at(p2, v5 + 8)))

    local v58 = math.abs((buffer.readf32(v1, 0)))

    return {
        frames = v9,
        bones = v4,
        dct_scale = rt.fmax(v55, v58),
        channels = v20,
        constants = t4,
        constant_flags = v37,
        widths = v47,
        blocks = v48
    }
end

function t1.offset(p6, p7) -- line: 169
    local v59 = p6 + p7

    if v59 > 18446744073709552000 then
        error("VBR offset overflow", 0)
    end

    return v59
end

function t1.take(p8, p9, p10) -- line: 180
    -- upvalues: t1 (copy)
    local v60 = t1.offset(p9, p10)

    if v60 < p9 or buffer.len(p8) < v60 then
        error(string.format("VBR read 0x%x+%d out of bounds", p9, p10), 0)
    end

    return p9
end

function t1.u16_at(p11, p12) -- line: 189
    -- upvalues: t1 (copy)
    local v61 = t1.take(p11, p12, 2)

    return buffer.readu8(p11, v61) * 256 + buffer.readu8(p11, v61 + 1)
end

function t1.u32_at(p13, p14) -- line: 195
    -- upvalues: t1 (copy)
    return (bit32.byteswap((buffer.readu32(p13, (t1.take(p13, p14, 4))))))
end

return t1
