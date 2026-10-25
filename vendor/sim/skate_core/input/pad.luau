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

require(sim.import)

local t1 = {
    Pad = {}
}

function t1.Pad.new() -- line: 37
    return {
        count = 0,
        records = {}
    }
end

function t1.Pad.from_records(p3) -- line: 45
    return {
        count = #p3,
        records = p3
    }
end

function t1.Pad.from_storage(p4, p5) -- line: 52
    if not (p5 <= #p4) then
        error("assertion failed: count <= records.len()", 0)
    end

    return {
        records = p4,
        count = p5
    }
end

function t1.Pad.count(p6) -- line: 59
    return p6.count
end

function t1.Pad.records(p7) -- line: 63
    return p7.records
end

function t1.Pad.eq(p8, p9) -- line: 68
    if p8.count ~= p9.count or #p8.records ~= #p9.records then
        return false
    end

    for i = 1, #p8.records do
        for j = 1, 4 do
            if p8.records[i][j] ~= p9.records[i][j] then
                return false
            end
        end
    end

    return true
end

function t1.Pad.update(p10, p11) -- line: 85
    -- upvalues: rt (copy), v1 (copy)
    if #p11 > p10.count then
        if #p11 > #p10.records then
            for i = #p10.records + 1, #p11 do
                p10.records[i] = { 0, 0, 0, 0 }
            end
        end

        for i = p10.count, #p11 - 1 do
            p10.records[i + 1] = { 0, 0, 0, 0 }
        end
    end

    p10.count = #p11

    for i = 1, math.min(#p10.records, #p11) do
        local v10 = p10.records[i]
        local v11 = p11[i]

        if v11 ~= 0 and v11 > -1.1754943508222875E-38 and v11 < 1.1754943508222875E-38 then
            local v12 = math.abs(v11) * 7.1362384635298E+44
            local v13 = math.floor(v12)
            local v14 = v12 - v13
            local v15 = if v14 > 0.5 or v14 == 0.5 and v13 % 2 == 1 then v13 + 1 else v13

            if v11 < 0 then
                v10[1] = v15 + 2147483648
            else
                v10[1] = v15
            end
        else
            buffer.writef32(v1, 0, v11)
            v10[1] = buffer.readu32(v1, 0)
        end

        local v16 = if v11 > 0.5 then 1 else 0
        local v19 = bit32.band(bit32.rshift(v10[2], 8), 255)

        if rt.to_i32(v10[4]) < 3 then
            v10[4] = rt.wrapping_add_u32(v10[4], 1)
            v10[2] = bit32.band(v10[2], 65535)
        elseif v16 == v19 then
            v10[2] = bit32.band(v10[2], 65535)
        else
            v10[2] = bit32.bor(bit32.band(v10[2], 255), bit32.lshift(v16, 8), v16 == 0 and 65536 or 16777216)
            v10[4] = 0
        end

        if bit32.band(v10[2], 65280) == 0 then
            v10[3] = 0
            v10[2] = bit32.band(v10[2], 4294967040)
        elseif v10[3] == 0 then
            v10[2] = bit32.bor(bit32.band(v10[2], 4294967040), 1)
            v10[3] = 24
        else
            v10[3] = rt.wrapping_sub_u32(v10[3], 1)

            if v10[3] == 0 then
                v10[2] = bit32.bor(bit32.band(v10[2], 4294967040), 1)
                v10[3] = 12
            else
                v10[2] = bit32.band(v10[2], 4294967040)
            end
        end
    end
end

return t1
