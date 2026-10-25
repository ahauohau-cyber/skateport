-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local t1 = {}

local function reserve(p1, p2) -- line: 36
    local v1 = p1.len + p2
    local v2 = buffer.len(p1.buf)

    if not (v2 < v1) then
        return
    end

    while v2 < v1 do
        v2 *= 2
    end

    local v3 = buffer.create(v2)

    buffer.copy(v3, 0, p1.buf, 0, p1.len)
    p1.buf = v3
end

local v4

v4 = function(p3, p4, p5) -- line: 50
    -- upvalues: v4 (ref), reserve (copy)
    local v5 = type(p4)

    if v5 == "number" then
        if not (p4 >= 0) or not (p4 <= 4294967295) or p4 % 1 ~= 0 or p4 == 0 and 1 / p4 < 0 then
            reserve(p3, 9)
            buffer.writeu8(p3.buf, p3.len, 3)
            buffer.writef64(p3.buf, p3.len + 1, p4)
            p3.len += 9
        elseif p4 <= 255 then
            reserve(p3, 2)
            buffer.writeu8(p3.buf, p3.len, 4)
            buffer.writeu8(p3.buf, p3.len + 1, p4)
            p3.len += 2
        else
            reserve(p3, 5)
            buffer.writeu8(p3.buf, p3.len, 5)
            buffer.writeu32(p3.buf, p3.len + 1, p4)
            p3.len += 5
        end
    elseif v5 == "string" then
        local v9 = p3.string_index[p4]

        if v9 == nil then
            v9 = #p3.strings + 1
            p3.strings[v9] = p4
            p3.string_index[p4] = v9
        end

        reserve(p3, 5)
        buffer.writeu8(p3.buf, p3.len, 6)
        buffer.writeu32(p3.buf, p3.len + 1, v9)
        p3.len += 5
    elseif v5 == "boolean" then
        reserve(p3, 1)
        buffer.writeu8(p3.buf, p3.len, p4 and 2 or 1)
        p3.len += 1
    elseif v5 == "table" then
        if getmetatable(p4) ~= nil then
            error("metatable", 0)
        end

        if p5 > 48 then
            error("too deep (cycle?)", 0)
        end

        local t2 = {}
        local t3 = {}
        local n1 = 0

        for v12, v13 in next, p4 do
            n1 += 1
            t2[n1] = v12
            t3[n1] = v13
        end

        local n2 = 0

        while n2 < n1 and t2[n2 + 1] == n2 + 1 do
            n2 += 1
        end

        if n2 == n1 then
            reserve(p3, 5)
            buffer.writeu8(p3.buf, p3.len, 7)
            buffer.writeu32(p3.buf, p3.len + 1, n1)
        else
            local v15 = table.create(n1)

            for i = 1, n1 do
                local v16 = t2[i]
                local v17 = type(v16)

                if v17 == "string" then
                    v15[i] = "s" .. #v16 .. ":" .. v16
                elseif v17 == "number" then
                    v15[i] = string.format("n%.17g", v16)
                elseif v17 == "boolean" then
                    v15[i] = v16 and "bT" or "bF"
                else
                    error("key type " .. v17, 0)
                end
            end

            local v18 = table.concat(v15, ",")
            local v19 = p3.shape_index[v18]

            if v19 == nil then
                v19 = #p3.shapes + 1

                if v19 > 4096 then
                    error("too many table shapes", 0)
                end

                local v21 = table.clone(p4)

                for i = 1, n1 do
                    v21[t2[i]] = false
                end

                p3.shapes[v19] = {
                    keys = t2,
                    template = v21
                }
                p3.shape_index[v18] = v19
            end

            reserve(p3, 5)
            buffer.writeu8(p3.buf, p3.len, 8)
            buffer.writeu32(p3.buf, p3.len + 1, v19)
        end

        p3.len += 5

        for i = 1, n1 do
            v4(p3, t3[i], p5 + 1)
        end
    else
        error("value type " .. v5, 0)
    end
end

local n3 = 0
local v23

v23 = function(p6, p7, p8, p9) -- line: 156
    -- upvalues: v23 (ref), n3 (ref)
    local v24 = n3
    local v25 = buffer.readu8(p6, v24)

    if v25 == 8 then
        local v27 = p8[buffer.readu32(p6, v24 + 1)]

        n3 = v24 + 5

        local v28 = table.clone(v27.template)
        local keys = v27.keys

        for i = 1, #keys do
            v28[keys[i]] = v23(p6, p7, p8, p9)
        end

        if p9 then
            table.freeze(v28)
        end

        return v28
    end

    if v25 == 4 then
        n3 = v24 + 2

        return (buffer.readu8(p6, v24 + 1))
    end

    if v25 == 3 then
        n3 = v24 + 9

        return (buffer.readf64(p6, v24 + 1))
    end

    if v25 == 5 then
        n3 = v24 + 5

        return (buffer.readu32(p6, v24 + 1))
    end

    if v25 == 6 then
        n3 = v24 + 5

        return p7[buffer.readu32(p6, v24 + 1)]
    end

    if v25 == 7 then
        local v34 = buffer.readu32(p6, v24 + 1)

        n3 = v24 + 5

        local v35 = table.create(v34)

        for i = 1, v34 do
            v35[i] = v23(p6, p7, p8, p9)
        end

        if p9 then
            table.freeze(v35)
        end

        return v35
    end

    if v25 == 2 then
        n3 = v24 + 1

        return true
    end

    if v25 == 1 then
        n3 = v24 + 1

        return false
    end

    error("Packed: bad tag " .. v25 .. " at " .. v24, 0)
end

local v36 = buffer.create(8)
local v37 = buffer.create(8)
local v38

v38 = function(p10, p11) -- line: 207
    -- upvalues: v38 (ref), v36 (copy), v37 (copy)
    local v39 = type(p10)

    if v39 == type(p11) then
        if v39 == "number" then
            buffer.writef64(v36, 0, p10)
            buffer.writef64(v37, 0, p11)

            if buffer.readu32(v36, 0) == buffer.readu32(v37, 0) then
                return buffer.readu32(v36, 4) == buffer.readu32(v37, 4)
            end

            return false
        end

        if v39 ~= "table" then
            return p10 == p11
        end

        if #p10 == #p11 then
            local v40, v41 = next(p10)
            local v42, v43 = next(p11)

            while true do
                if v40 == nil then
                    return v42 == nil
                end

                if rawequal(v40, v42) and v38(v41, v43) then
                    v40, v41 = next(p10, v40)
                    v42, v43 = next(p11, v42)
                    continue
                end

                break
            end
        end
    end

    return false
end

t1.same = v38

local v44

v44 = function(p12, p13) -- line: 244
    -- upvalues: v38 (ref), v44 (ref)
    local v45 = type(p12)

    if v45 ~= type(p13) then
        return false
    end

    if v45 ~= "table" then
        return v38(p12, p13)
    end

    if #p12 ~= #p13 then
        return false
    end

    local n4 = 0

    for v46, v47 in next, p12 do
        n4 += 1

        if not v44(v47, (rawget(p13, v46))) then
            return false
        end
    end

    for _ in next, p13 do
        n4 -= 1
    end

    return n4 == 0
end

t1.same_values = v44
t1.slice = nil

function t1.pack(p14, p15) -- line: 279
    -- upvalues: v4 (ref), v23 (ref), v38 (ref), t1 (copy), n3 (ref)
    p15 = p15 or {}

    local v49 = p15.freeze ~= false
    local v50 = #p14
    local t4 = {
        len = 0,
        buf = buffer.create(65536),
        strings = {},
        string_index = {},
        shapes = {},
        shape_index = {}
    }
    local v51 = buffer.create((v50 + 1) * 4)
    local t5 = {}
    local t6 = {}
    local n5 = 0

    for i = 1, v50 do
        local slice = t1.slice

        if slice ~= nil then
            slice()
        end

        local len = t4.len

        buffer.writeu32(v51, (i - 1) * 4, len)

        local v52 = v4
        local v53 = p14[i]
        local ok, result = pcall(v52, t4, v53, 0)
        local v54 = ok
        local v55 = result

        if ok and p15.verify ~= false then
            n3 = len

            local v57 = v23(t4.buf, t4.strings, t4.shapes, false)

            if n3 ~= t4.len or not v38(p14[i], v57) then
                v54 = false
                v55 = "decoded element differs"
            end
        end

        if not v54 then
            t4.len = len
            t5[i] = p14[i]
            n5 += 1
            t6[tostring(v55)] = (t6[tostring(v55)] or 0) + 1
        end
    end

    buffer.writeu32(v51, v50 * 4, t4.len)

    local v60 = buffer.create(t4.len)

    buffer.copy(v60, 0, t4.buf, 0, t4.len)

    return {
        cached = 0,
        data = v60,
        offsets = v51,
        strings = t4.strings,
        shapes = t4.shapes,
        count = v50,
        exceptions = t5,
        exception_count = n5,
        exception_reasons = t6,
        cache = {},
        cache_limit = p15.cache or 512,
        freeze = v49,
        bytes = t4.len + (v50 + 1) * 4
    }
end

function t1.get(p16, p17) -- line: 332
    -- upvalues: v23 (ref), n3 (ref)
    local v61 = p16.cache[p17]

    if v61 ~= nil then
        return v61
    end

    if p17 < 1 or p16.count < p17 or p17 % 1 ~= 0 then
        return nil
    end

    local v62 = p16.exceptions[p17]

    if v62 ~= nil then
        return v62
    end

    local v63 = n3

    n3 = buffer.readu32(p16.offsets, (p17 - 1) * 4)

    local v65 = v23(p16.data, p16.strings, p16.shapes, p16.freeze)

    n3 = v63

    if p16.cached >= p16.cache_limit then
        table.clear(p16.cache)
        p16.cached = 0
    end

    p16.cache[p17] = v65
    p16.cached += 1

    return v65
end

local get = t1.get

function t1.get_copy(p18, p19) -- line: 359
    -- upvalues: v23 (ref), n3 (ref)
    if p19 < 1 or p18.count < p19 or p19 % 1 ~= 0 then
        return nil
    end

    local v66 = p18.exceptions[p19]

    if v66 == nil then
        local v67 = n3

        n3 = buffer.readu32(p18.offsets, (p19 - 1) * 4)

        local v69 = v23(p18.data, p18.strings, p18.shapes, false)

        n3 = v67

        return v69
    end

    local function copy(p20) -- line: 366
        -- upvalues: copy (copy)
        if type(p20) ~= "table" then
            return p20
        end

        local v70 = table.clone(p20)

        for v71, v72 in next, v70 do
            if type(v72) == "table" then
                v70[v71] = copy(v72)
            end
        end

        return v70
    end

    return (copy(v66))
end

function t1.view(p21) -- line: 389
    -- upvalues: get (copy)
    local count = p21.count

    return (setmetatable({}, {
        __index = function(_, p23) -- __index | line: 392
            -- upvalues: p21 (copy), get (copy)
            if type(p23) == "number" then
                return get(p21, p23)
            end

            return nil
        end,
        __len = function() -- __len | line: 398
            -- upvalues: count (copy)
            return count
        end,
        __newindex = function() -- __newindex | line: 401
            error("Packed: this array is read-only (it replaces immutable load-time data)", 0)
        end,
        __iter = function() -- __iter | line: 404
            -- upvalues: p21 (copy), count (copy), get (copy)
            local n6 = 0

            return function() -- line: 406
                -- upvalues: n6 (ref), p21 (copy), count (copy), get (copy)
                n6 += 1

                if n6 <= count then
                    return n6, get(p21, n6)
                end

                return nil
            end
        end,
        store = p21
    }))
end

function t1.array(p24, p25) -- line: 418
    -- upvalues: t1 (copy)
    return t1.view(t1.pack(p24, p25))
end

function t1.store(p26) -- line: 423
    local mt = getmetatable(p26)

    return if type(mt) == "table" then mt.store else nil
end

function t1.is_view(p27) -- line: 428
    -- upvalues: t1 (copy)
    return t1.store(p27) ~= nil
end

function t1.to_table(p28) -- line: 433
    -- upvalues: t1 (copy)
    local v73 = t1.store(p28)

    if v73 == nil then
        return p28
    end

    local v74 = table.create(v73.count)

    for i = 1, v73.count do
        v74[i] = t1.get_copy(v73, i)
    end

    return v74
end

return t1
