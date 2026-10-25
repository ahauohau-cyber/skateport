-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

local t1 = {}

function t1.key_hash(p1) -- line: 16
    -- upvalues: t1 (copy)
    if #p1 == 0 then
        return 0
    end

    return t1.byte_hash(p1)
end

function t1.byte_hash(p2) -- line: 26
    -- upvalues: rt (copy), t1 (copy)
    local v1 = #p2
    local v2 = rt.idiv(v1, 12) * 12
    local v3 = v2 - 1
    local n1 = 2654435769
    local n2 = 2654435769
    local n3 = 2882400000

    for i = 0, v3, 12 do
        local v4, v5, v6 = string.unpack("<I4I4I4", p2, i + 1)
        local v7 = rt.wrapping_add_u32(n1, v4)
        local v8 = rt.wrapping_add_u32(n2, v5)
        local v9 = rt.wrapping_add_u32(n3, v6)

        n1, n2, n3 = t1.mix(v7, v8, v9)
    end

    local v10 = rt.wrapping_add_u32(n3, v1 % 4294967296)

    for i = 0, v1 - v2 - 1 do
        local v12 = string.byte(p2, v2 + i + 1)

        if i <= 3 then
            n1 = rt.wrapping_add_u32(n1, (bit32.lshift(v12, i * 8)))
        elseif i <= 7 then
            n2 = rt.wrapping_add_u32(n2, (bit32.lshift(v12, (i - 4) * 8)))
        else
            v10 = rt.wrapping_add_u32(v10, (bit32.lshift(v12, (i - 7) * 8)))
        end
    end

    local _, _, v13 = t1.mix(n1, n2, v10)

    return v13
end

function t1.mix(p3, p4, p5) -- line: 58
    -- upvalues: rt (copy)
    local v16 = bit32.bxor(rt.wrapping_sub_u32(rt.wrapping_sub_u32(p3, p4), p5), (bit32.rshift(p5, 13)))
    local v19 = bit32.bxor(rt.wrapping_sub_u32(rt.wrapping_sub_u32(p4, p5), v16), (bit32.lshift(v16, 8)))
    local v22 = bit32.bxor(rt.wrapping_sub_u32(rt.wrapping_sub_u32(p5, v16), v19), (bit32.rshift(v19, 13)))
    local v25 = bit32.bxor(rt.wrapping_sub_u32(rt.wrapping_sub_u32(v16, v19), v22), (bit32.rshift(v22, 12)))
    local v28 = bit32.bxor(rt.wrapping_sub_u32(rt.wrapping_sub_u32(v19, v22), v25), (bit32.lshift(v25, 16)))
    local v31 = bit32.bxor(rt.wrapping_sub_u32(rt.wrapping_sub_u32(v22, v25), v28), (bit32.rshift(v28, 5)))
    local v34 = bit32.bxor(rt.wrapping_sub_u32(rt.wrapping_sub_u32(v25, v28), v31), (bit32.rshift(v31, 3)))
    local v37 = bit32.bxor(rt.wrapping_sub_u32(rt.wrapping_sub_u32(v28, v31), v34), (bit32.lshift(v34, 10)))

    return v34, v37, (bit32.bxor(rt.wrapping_sub_u32(rt.wrapping_sub_u32(v31, v34), v37), (bit32.rshift(v37, 15))))
end

t1.Attributes = {}

function t1.Attributes.new(p6) -- line: 79
    -- upvalues: t1 (copy)
    local t2 = {}

    for _, v40 in p6 do
        local v41 = t1.key_hash(v40.name)

        if t2[v41] == nil then
            t2[v41] = v40
        end
    end

    return {
        entries = t2
    }
end

function t1.Attributes.get(p7, p8) -- line: 92
    -- upvalues: t1 (copy)
    return p7.entries[t1.key_hash(p8)]
end

function t1.Attributes.text(p9, p10) -- line: 98
    -- upvalues: t1 (copy)
    local v42 = t1.Attributes.get(p9, p10)

    return if v42 ~= nil then v42.text else nil
end

function t1.Attributes.boolean_byte(p11, p12, p13) -- line: 108
    -- upvalues: t1 (copy)
    local v43 = t1.Attributes.get(p11, p12)

    if v43 == nil then
        return p13
    end

    return v43.boolean_byte
end

function t1.Attributes.float_bits(p14, p15, p16) -- line: 118
    -- upvalues: t1 (copy)
    local v44 = t1.Attributes.get(p14, p15)

    if v44 == nil then
        return p16
    end

    return v44.float_bits
end

return t1
