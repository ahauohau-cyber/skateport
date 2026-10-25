-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

local t1 = {}
local band, bxor, bnot, rrotate = bit32.band, bit32.bxor, bit32.bnot, bit32.rrotate
local rshift, byteswap = bit32.rshift, bit32.byteswap
local t2 = {
    1116352408, 1899447441, 3049323471, 3921009573, 961987163, 1508970993, 2453635748, 2870763221,
    3624381080, 310598401, 607225278, 1426881987, 1925078388, 2162078206, 2614888103, 3248222580,
    3835390401, 4022224774, 264347078, 604807628, 770255983, 1249150122, 1555081692, 1996064986,
    2554220882, 2821834349, 2952996808, 3210313671, 3336571891, 3584528711, 113926993, 338241895,
    666307205, 773529912, 1294757372, 1396182291, 1695183700, 1986661051, 2177026350, 2456956037,
    2730485921, 2820302411, 3259730800, 3345764771, 3516065817, 3600352804, 4094571909, 275423344,
    430227734, 506948616, 659060556, 883997877, 958139571, 1322822218, 1537002063, 1747873779,
    1955562222, 2024104815, 2227730452, 2361852424, 2428436474, 2756734187, 3204031479, 3329325298
}
local v1 = table.create(64, 0)

local function compress(p1, p2, p3) -- line: 34
    -- upvalues: band (copy), bxor (copy), bnot (copy), rrotate (copy), rshift (copy), byteswap (copy), t2 (copy), v1 (copy)
    for i = 0, 15 do
        local v3 = buffer.readu32(p2, p3 + i * 4)

        v1[i + 1] = byteswap(v3)
    end

    for i = 16, 63 do
        local v4 = v1[i - 15 + 1]
        local v5 = v1[i - 2 + 1]
        local v9 = bxor(rrotate(v4, 7), rrotate(v4, 18), (rshift(v4, 3)))
        local v13 = bxor(rrotate(v5, 17), rrotate(v5, 19), (rshift(v5, 10)))

        v1[i + 1] = (v1[i - 16 + 1] + v9 + v1[i - 7 + 1] + v13) % 4294967296
    end

    local v14 = p1[1]
    local v15 = p1[2]
    local v16 = p1[3]
    local v17 = p1[4]
    local v18 = p1[5]
    local v19 = p1[6]
    local v20 = p1[7]
    local v21 = p1[8]

    for i = 0, 63 do
        local v25 = bxor(rrotate(v18, 6), rrotate(v18, 11), (rrotate(v18, 25)))
        local v29 = bxor(band(v18, v19), (band(bnot(v18), v20)))
        local v30 = (v21 + v25 + v29 + t2[i + 1] + v1[i + 1]) % 4294967296
        local v38 = (bxor(rrotate(v14, 2), rrotate(v14, 13), (rrotate(v14, 22))) + bxor(band(v14, v15), band(v14, v16), (band(v15, v16)))) % 4294967296
        local v39 = (v17 + v30) % 4294967296

        v14, v15, v16, v17, v18, v19, v20, v21 = (v30 + v38) % 4294967296, v14, v15, v16, v39, v18, v19, v20
    end

    p1[1] = (p1[1] + v14) % 4294967296
    p1[2] = (p1[2] + v15) % 4294967296
    p1[3] = (p1[3] + v16) % 4294967296
    p1[4] = (p1[4] + v17) % 4294967296
    p1[5] = (p1[5] + v18) % 4294967296
    p1[6] = (p1[6] + v19) % 4294967296
    p1[7] = (p1[7] + v20) % 4294967296
    p1[8] = (p1[8] + v21) % 4294967296
end

function t1.digest(p4) -- line: 73
    -- upvalues: rt (copy), byteswap (copy), compress (copy)
    local t3 = {
        1779033703, 3144134277, 1013904242, 2773480762, 1359893119, 2600822924, 528734635, 1541459225
    }
    local v40 = buffer.len(p4)
    local v41 = rt.idiv(v40, 64) * 64

    for i = 0, v41 - 64, 64 do
        compress(t3, p4, i)
    end

    local v42 = v40 - v41
    local v43 = buffer.create(128)

    buffer.copy(v43, 0, p4, v41, v42)
    buffer.writeu8(v43, v42, 128)

    local v44 = if v42 < 56 then 64 else 128
    local v45 = rt.idiv(v40, 536870912) % 4294967296
    local v46 = v40 % 536870912 * 8

    buffer.writeu32(v43, v44 - 8, (byteswap(v45)))
    buffer.writeu32(v43, v44 - 4, (byteswap(v46)))

    for i = 0, v44 - 64, 64 do
        compress(t3, v43, i)
    end

    local v51 = table.create(8)

    for i = 1, 8 do
        v51[i] = string.format("%08x", t3[i])
    end

    return table.concat(v51)
end

t1.compress = compress

return t1
