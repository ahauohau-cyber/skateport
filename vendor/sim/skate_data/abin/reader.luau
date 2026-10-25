-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local t1 = {}

local function Error() -- line: 12
    -- upvalues: import (copy)
    return import("skate_data/abin").Error
end

t1.Reader = {}

local function check(p1, p2, p3) -- line: 24
    -- upvalues: import (copy)
    local v1 = p2 + p3

    if p2 < p1.begin or p1["end"] < v1 then
        error(import("skate_data/abin").Error.new(p2, string.format("read size%d exceeds record 0x%x..0x%x", p3, p1.begin, p1["end"])), 0)
    end
end

function t1.Reader.new(p4) -- line: 37
    return {
        bytes = p4,
        begin = 0,
        ["end"] = buffer.len(p4)
    }
end

function t1.Reader.bounded(p5, p6) -- line: 45
    -- upvalues: import (copy), check (copy)
    if p6["end"] - p6.start < 0 then
        error(import("skate_data/abin").Error.new(p6.start, "reversed record range"), 0)
    end

    check(p5, p6.start, p6["end"] - p6.start)

    return {
        bytes = p5.bytes,
        begin = p6.start,
        ["end"] = p6["end"]
    }
end

function t1.Reader.take(p7, p8, p9) -- line: 57
    -- upvalues: check (copy)
    check(p7, p8, p9)

    local v2 = buffer.create(p9)

    buffer.copy(v2, 0, p7.bytes, p8, p9)

    return v2
end

function t1.Reader.u8(p10, p11) -- line: 63
    -- upvalues: check (copy)
    check(p10, p11, 1)

    return (buffer.readu8(p10.bytes, p11))
end

function t1.Reader.u16(p12, p13) -- line: 67
    -- upvalues: check (copy)
    check(p12, p13, 2)

    local bytes = p12.bytes

    return buffer.readu8(bytes, p13) * 256 + buffer.readu8(bytes, p13 + 1)
end

function t1.Reader.u32(p14, p15) -- line: 72
    -- upvalues: check (copy)
    check(p14, p15, 4)

    return (bit32.byteswap((buffer.readu32(p14.bytes, p15))))
end

function t1.Reader.i32(p16, p17) -- line: 76
    -- upvalues: rt (copy), t1 (copy)
    return rt.to_i32(t1.Reader.u32(p16, p17))
end

function t1.Reader.words(p18, p19, p20) -- line: 80
    -- upvalues: check (copy)
    check(p18, p19, p20 * 4)

    local bytes = p18.bytes
    local v6 = table.create(p20)

    for i = 0, p20 - 1 do
        local v8 = buffer.readu32(bytes, p19 + i * 4)

        v6[i + 1] = bit32.byteswap(v8)
    end

    return v6
end

function t1.Reader.name(p21, p22, p23) -- line: 92
    -- upvalues: rt (copy), import (copy), check (copy)
    check(p21, p22, p23 * 4)

    local bytes = p21.bytes
    local t2 = {}

    for i = 0, p23 - 1 do
        local v11 = bit32.byteswap((buffer.readu32(bytes, p22 + i * 4)))
        local n1 = 79235168

        for _ = 0, 5 do
            local v12 = rt.idiv(v11, n1)

            v11 = rt.irem(v11, n1)

            if v12 == 0 then
                if v11 ~= 0 then
                    error(import("skate_data/abin").Error.new(p22, "invalid FastString padding"), 0)
                end

                break
            end

            if v12 - 1 >= 37 then
                error(import("skate_data/abin").Error.new(p22, "invalid FastString digit"), 0)
            end

            table.insert(t2, (string.sub("0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZ_", v12, v12)))
            n1 = rt.idiv(n1, 38)
        end
    end

    return table.concat(t2)
end

function t1.Reader.relative(p24, p25, p26, p27) -- line: 119
    -- upvalues: check (copy)
    local v14 = p25 + p26

    check(p24, v14, p27)

    return {
        start = v14,
        ["end"] = v14 + p27
    }
end

return t1
