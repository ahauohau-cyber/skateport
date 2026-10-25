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

local function rtl_fround(p2) -- line: 16
    -- upvalues: v1 (copy)
    if p2 ~= 0 and p2 > -1.1754943508222875E-38 and p2 < 1.1754943508222875E-38 then
        local v6 = math.abs(p2) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        local v8 = v5 * 1.401298464324817E-45

        if p2 < 0 then
            return -v8
        end

        return v8
    end

    buffer.writef32(v1, 0, p2)

    return (buffer.readf32(v1, 0))
end

require(sim.import)

local t1 = {
    Noise = {}
}
local Noise = t1.Noise

function t1.Noise.default() -- line: 37
    return {
        words = { 4063039062, 2284922601, 3324304687, 117621916, 2654289789, 1876900708 },
        phases = { 0, 0 },
        scroll = { 0, 0, 0, 0 }
    }
end

function t1.Noise.next(p3) -- line: 48
    -- upvalues: rt (copy)
    local words = p3.words
    local n1 = 0

    for i = 4, 0, -1 do
        local v9 = words[i + 1] + words[i + 2] + n1

        words[i + 1] = v9 % 4294967296
        n1 = math.floor(v9 / 4294967296)
    end

    for i = 5, 0, -1 do
        words[i + 1] = rt.wrapping_add_u32(words[i + 1], 1)

        if words[i + 1] ~= 0 then
            break
        end
    end

    return words[1]
end

function t1.Noise.texture(p4) -- line: 67
    -- upvalues: Noise (copy)
    local v11 = buffer.create(16384)

    for i = 0, 16383 do
        if bit32.band(bit32.rshift(Noise.next(p4), 8), 255) > 128 then
            buffer.writeu8(v11, i, 255)
        else
            buffer.writeu8(v11, i, 0)
        end
    end

    return v11
end

function t1.Noise.advance(p5) -- line: 82
    -- upvalues: v1 (copy), Noise (copy)
    buffer.writef32(v1, 0, 0.045)

    local v14 = buffer.readf32(v1, 0)

    buffer.writef32(v1, 0, 0.06)

    local t2 = {
        v14,
        (buffer.readf32(v1, 0))
    }

    for i = 1, 2 do
        local v15 = p5.phases[i] + t2[i]
        local v16

        if v15 ~= 0 and v15 > -1.1754943508222875E-38 and v15 < 1.1754943508222875E-38 then
            local v17 = math.abs(v15) * 7.1362384635298E+44
            local v18 = math.floor(v17)
            local v19 = v17 - v18

            v16 = (if v19 > 0.5 or v19 == 0.5 and v18 % 2 == 1 then v18 + 1 else v18) * 1.401298464324817E-45

            if v15 < 0 then
                v16 = -v16
            end
        else
            buffer.writef32(v1, 0, v15)
            v16 = buffer.readf32(v1, 0)
        end

        if v16 >= 4 then
            local v20 = v16 - 4

            if v20 ~= 0 and v20 > -1.1754943508222875E-38 and v20 < 1.1754943508222875E-38 then
                local v21 = math.abs(v20) * 7.1362384635298E+44
                local v22 = math.floor(v21)
                local v23 = v21 - v22

                v16 = (if v23 > 0.5 or v23 == 0.5 and v22 % 2 == 1 then v22 + 1 else v22) * 1.401298464324817E-45

                if v20 < 0 then
                    v16 = -v16
                end
            else
                buffer.writef32(v1, 0, v20)
                v16 = buffer.readf32(v1, 0)
            end
        end

        p5.phases[i] = v16
    end

    local t3 = {
        bit32.band(Noise.next(p5), 65535) / 65536,
        bit32.band(Noise.next(p5), 65535) / 65536,
        bit32.band(Noise.next(p5), 65535) / 65536,
        bit32.band(Noise.next(p5), 65535) / 65536
    }

    p5.scroll = {
        t3[4],
        t3[3],
        t3[2],
        t3[1]
    }
end

function t1.Noise.weights(p6) -- line: 103
    -- upvalues: rt (copy)
    local t4 = {
        0, 0, 0, 0
    }
    local v31 = rt.f_to_usize(p6)

    t4[v31 % 4 + 1] = 1 - rt.fract(p6)
    t4[(v31 + 1) % 4 + 1] = rt.fract(p6)

    return t4
end

return t1
