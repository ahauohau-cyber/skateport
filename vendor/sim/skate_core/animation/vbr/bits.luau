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

require(sim.import)

local t1 = {}

local function buffer_tail(p4, p5) -- line: 40
    local v8 = buffer.len(p4) - p5
    local v9 = buffer.create(v8)

    buffer.copy(v9, 0, p4, p5, v8)

    return v9
end

t1.Bits = {}

function t1.Bits.read(p6, p7) -- line: 51
    -- upvalues: rt (copy)
    local bytes = p6.bytes
    local v10 = buffer.len(bytes)
    local v11 = p7 - 1
    local n1 = 0

    for i = 0, v11 do
        local v12 = rt.idiv(p6.position, 8)

        if v10 <= v12 then
            error("VBR coefficient bit stream truncated", 0)
        end

        n1 = bit32.bor(n1, (bit32.lshift(bit32.band(bit32.rshift(buffer.readu8(bytes, v12), (rt.irem(p6.position, 8))), 1), i)))
        p6.position += 1
    end

    return n1
end

function t1.unpack_reference(p8, p9) -- line: 68
    -- upvalues: v1 (copy), t1 (copy)
    if #p9 == 0 then
        return {}
    end

    local v18 = buffer.len(p8)

    if v18 == 0 then
        error("VBR block has no selector length", 0)
    end

    local v19 = buffer.readu8(p8, 0)

    if v18 < 1 then
        error("VBR selector stream missing", 0)
    end

    local v20 = buffer.len(p8) - 1
    local v21 = buffer.create(v20)

    buffer.copy(v21, 0, p8, 1, v20)

    local v23 = math.ceil(v19 / 8) + 1

    if v18 < v23 then
        error("VBR selector length exceeds block", 0)
    end

    local v24 = buffer.len(p8) - v23
    local v25 = buffer.create(v24)

    buffer.copy(v25, 0, p8, v23, v24)

    local t2 = {
        position = 0,
        bytes = v21
    }
    local t3 = {
        position = 0,
        bytes = v25
    }
    local v26 = table.create(#p9)

    for _, v27 in ipairs(p9) do
        local t4 = {
            0, 0, 0, 0, 0, 0, 0, 0
        }

        for i = 0, 7 do
            local v29 = bit32.band(bit32.rshift(v27, i * 4), 15)

            if v29 ~= 0 and t1.Bits.read(t2, 1) ~= 0 then
                local v30 = t1.Bits.read(t3, 1) ~= 0
                local v31 = t1.Bits.read(t3, v29)
                local v32 = i + 1
                local v33

                if v31 ~= 0 and v31 > -1.1754943508222875E-38 and v31 < 1.1754943508222875E-38 then
                    local v34 = math.abs(v31) * 7.1362384635298E+44
                    local v35 = math.floor(v34)
                    local v36 = v34 - v35
                    local v37 = if v36 > 0.5 or v36 == 0.5 and v35 % 2 == 1 then v35 + 1 else v35

                    v33 = if v31 < 0 then v37 + 2147483648 else v37
                else
                    buffer.writef32(v1, 0, v31)
                    v33 = buffer.readu32(v1, 0)
                end

                buffer.writeu32(v1, 0, (bit32.bor(v33, if v30 then 0 else 2147483648)))
                t4[v32] = buffer.readf32(v1, 0)
            end
        end

        table.insert(v26, t4)
    end

    return v26
end

local to_bits, from_bits = rt.to_bits, rt.from_bits

local function unpack_range(p10, p11, p12, p13) -- line: 128
    -- upvalues: to_bits (copy), from_bits (copy)
    if #p13 == 0 then
        return {}
    end

    local v40 = p12 - p11

    if v40 == 0 then
        error("VBR block has no selector length", 0)
    end

    local v41 = buffer.readu8(p10, p11)

    if v40 < 1 then
        error("VBR selector stream missing", 0)
    end

    local v43 = math.ceil(v41 / 8) + 1

    if v40 < v43 then
        error("VBR selector length exceeds block", 0)
    end

    local v44 = p11 + 1
    local v45 = (v40 - 1) * 8
    local v46 = p11 + v43
    local v47 = (v40 - v43) * 8
    local v48 = table.create(#p13)
    local n2 = 0
    local n3 = 0

    for _, v49 in ipairs(p13) do
        local t5 = {
            0, 0, 0, 0, 0, 0, 0, 0
        }

        for i = 0, 7 do
            local v51 = bit32.band(bit32.rshift(v49, i * 4), 15)
            local v53
            local v52 = n2

            if v51 == 0 then
                v53 = n3
            else
                if v45 <= n3 then
                    error("VBR coefficient bit stream truncated", 0)
                end

                local v58 = bit32.band(bit32.rshift(buffer.readu8(p10, v44 + bit32.rshift(n3, 3)), (bit32.band(n3, 7))), 1)

                v53 = n3 + 1

                if v58 ~= 0 then
                    if v47 <= n2 then
                        error("VBR coefficient bit stream truncated", 0)
                    end

                    local v63 = bit32.band(bit32.rshift(buffer.readu8(p10, v46 + bit32.rshift(n2, 3)), (bit32.band(n2, 7))), 1) ~= 0
                    local v64 = n2 + 1

                    if v47 < v64 + v51 then
                        error("VBR coefficient bit stream truncated", 0)
                    end

                    local v65 = v46 + bit32.rshift(v64, 3)
                    local v66 = bit32.band(v64, 7)
                    local v67 = v66 + v51
                    local v68 = buffer.readu8(p10, v65)

                    if v67 > 8 then
                        v68 += buffer.readu8(p10, v65 + 1) * 256

                        if v67 > 16 then
                            v68 += buffer.readu8(p10, v65 + 2) * 65536
                        end
                    end

                    local v73 = bit32.band(bit32.rshift(v68, v66), bit32.lshift(1, v51) - 1)

                    v52 = v64 + v51

                    local v74 = to_bits(v73)
                    local v75 = v63 and 0 or 2147483648

                    t5[i + 1] = from_bits((bit32.bor(v74, v75)))
                end
            end

            n3 = v53
            n2 = v52
        end

        table.insert(v48, t5)
    end

    return v48
end

t1.unpack_range = unpack_range

function t1.unpack_range_flat(p14, p15, p16, p17, p18) -- line: 216
    local v76 = #p17

    if v76 == 0 then
        return 0
    end

    local v77 = p16 - p15

    if v77 == 0 then
        error("VBR block has no selector length", 0)
    end

    local v78 = buffer.readu8(p14, p15)

    if v77 < 1 then
        error("VBR selector stream missing", 0)
    end

    local v80 = math.ceil(v78 / 8) + 1

    if v77 < v80 then
        error("VBR selector length exceeds block", 0)
    end

    local v81 = p15 + 1
    local v82 = (v77 - 1) * 8
    local v83 = p15 + v80
    local v84 = (v77 - v80) * 8
    local n4 = 0
    local n5 = 0
    local n6 = 0

    for i = 1, v76 do
        local v85 = p17[i]
        local v86 = n4 + 1
        local v87 = n4 + 2
        local v88 = n4 + 3
        local v89 = n4 + 4

        p18[v86] = 0
        p18[v87] = 0
        p18[v88] = 0
        p18[v89] = 0

        local v90 = n4 + 5
        local v91 = n4 + 6
        local v92 = n4 + 7
        local v93 = n4 + 8

        p18[v90] = 0
        p18[v91] = 0
        p18[v92] = 0
        p18[v93] = 0

        if v85 ~= 0 then
            for j = 0, 7 do
                local v95 = bit32.band(bit32.rshift(v85, j * 4), 15)
                local v97
                local v96 = n5

                if v95 == 0 then
                    v97 = n6
                else
                    if v82 <= n6 then
                        error("VBR coefficient bit stream truncated", 0)
                    end

                    local v102 = bit32.band(bit32.rshift(buffer.readu8(p14, v81 + bit32.rshift(n6, 3)), (bit32.band(n6, 7))), 1)

                    v97 = n6 + 1

                    if v102 ~= 0 then
                        if v84 <= n5 then
                            error("VBR coefficient bit stream truncated", 0)
                        end

                        local v107 = bit32.band(bit32.rshift(buffer.readu8(p14, v83 + bit32.rshift(n5, 3)), (bit32.band(n5, 7))), 1) ~= 0
                        local v108 = n5 + 1

                        if v84 < v108 + v95 then
                            error("VBR coefficient bit stream truncated", 0)
                        end

                        local v109 = v83 + bit32.rshift(v108, 3)
                        local v110 = bit32.band(v108, 7)
                        local v111 = v110 + v95
                        local v112 = buffer.readu8(p14, v109)

                        if v111 > 8 then
                            v112 += buffer.readu8(p14, v109 + 1) * 256

                            if v111 > 16 then
                                v112 += buffer.readu8(p14, v109 + 2) * 65536
                            end
                        end

                        local v117 = bit32.band(bit32.rshift(v112, v110), bit32.lshift(1, v95) - 1)

                        v96 = v108 + v95

                        local v118 = n4 + j + 1

                        if not v107 then
                            v117 = -v117
                        end

                        p18[v118] = v117
                    end
                end

                n6 = v97
                n5 = v96
            end
        end

        n4 += 8
    end

    return v76
end

function t1.unpack(p19, p20) -- line: 305
    -- upvalues: unpack_range (copy)
    return (unpack_range(p19, 0, buffer.len(p19), p20))
end

return t1
