-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local EncodingService = game:GetService("EncodingService")
local Zstd = Enum.CompressionAlgorithm.Zstd
local t1 = {}

t1.stats = {
    unpacks = 0,
    bytes = 0,
    seconds = 0,
    text_seconds = 0
}

local v1 = table.create(256, 0)
local n1 = 0

for i = 35, 120 do
    if i ~= 92 then
        v1[i + 1] = n1
        n1 += 1
    end
end

assert(n1 == 85)

local function b85_decode(p1) -- line: 35
    -- upvalues: v1 (copy)
    local v3 = #p1
    local v4 = string.byte(p1, 2) - 48
    local v5 = (v3 - 2) // 5

    if v5 * 5 + 2 ~= v3 or v4 < 0 or v4 > 3 then
        error("[zstd] malformed base-85 text", 0)
    end

    local v6 = buffer.create(v5 * 4)
    local writeu32, byteswap, byte = buffer.writeu32, bit32.byteswap, string.byte
    local n2 = 0
    local n3 = 3

    for _ = 1, v5 do
        local v7, v8, v9, v10, v11 = byte(p1, n3, n3 + 4)

        writeu32(v6, n2, (byteswap((((v1[v7 + 1] * 85 + v1[v8 + 1]) * 85 + v1[v9 + 1]) * 85 + v1[v10 + 1]) * 85 + v1[v11 + 1])))
        n2 += 4
        n3 += 5
    end

    if v4 == 0 then
        return v6
    end

    local v12 = buffer.create(v5 * 4 - v4)

    buffer.copy(v12, 0, v6, 0, v5 * 4 - v4)

    return v12
end

t1.b85_decode = b85_decode

local t2 = {}

for _, v13 in { 0, 1, 10, 13, 34, 92 } do
    t2[string.char(v13 + 64)] = string.char(v13)
end

function t1.raw_decode(p2) -- line: 68
    -- upvalues: t2 (copy)
    local v15 = string.sub(p2, 2)

    if string.find(v15, "\001", 1, true) then
        v15 = string.gsub(v15, "\001(.)", t2)
    end

    return buffer.fromstring(v15)
end

function t1.unpack(p3, p4, p5) -- line: 78
    -- upvalues: t1 (copy), EncodingService (copy), Zstd (copy), b85_decode (copy), t2 (copy)
    local elapsed = os.clock()
    local v16 = string.byte(p3, 1)
    local v17

    if v16 == 126 then
        v17 = b85_decode(p3)
    elseif v16 == 33 then
        local v18 = string.sub(p3, 2)

        if string.find(v18, "\001", 1, true) then
            v18 = string.gsub(v18, "\001(.)", t2)
        end

        v17 = buffer.fromstring(v18)
    else
        v17 = EncodingService:Base64Decode(buffer.fromstring(p3))
    end

    local elapsed2 = os.clock()
    local v19 = EncodingService:DecompressBuffer(v17, Zstd)
    local v20 = buffer.len(v19)

    if v20 ~= p4 then
        error(("[zstd] unpacked %* bytes, expected %*"):format(v20, p4), 0)
    end

    if p5 ~= nil and p5 > 0 then
        local v21 = buffer.create(p4 + p5)

        buffer.copy(v21, 0, v19, 0, p4)
        v19 = v21
    end

    local stats = t1.stats

    stats.unpacks += 1
    stats.bytes += p4
    stats.text_seconds += elapsed2 - elapsed
    stats.seconds += os.clock() - elapsed

    return v19
end

function t1.unpack_chunks(p6, p7, p8) -- line: 102
    -- upvalues: t1 (copy)
    return t1.unpack(if #p6 == 1 then p6[1] else table.concat(p6), p7, p8)
end

return t1
