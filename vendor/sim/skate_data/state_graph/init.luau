-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local t1 = {
    GraphAttribute = {}
}

function t1.GraphAttribute.eq(p1, p2) -- line: 25
    if p1.name == p2.name and p1.text == p2.text and p1.float_bits == p2.float_bits then
        return p1.boolean_byte == p2.boolean_byte
    end

    return false
end

t1.GraphElement = {}

function t1.GraphElement.eq(p3, p4) -- line: 39
    -- upvalues: t1 (copy)
    if p3.source_offset ~= p4.source_offset or p3.tag ~= p4.tag or #p3.attributes ~= #p4.attributes or #p3.children ~= #p4.children then
        return false
    end

    for i = 1, #p3.attributes do
        if not t1.GraphAttribute.eq(p3.attributes[i], p4.attributes[i]) then
            return false
        end
    end

    for i = 1, #p3.children do
        if p3.children[i] ~= p4.children[i] then
            return false
        end
    end

    return true
end

t1.StateGraph = {}

function t1.StateGraph.eq(p5, p6) -- line: 63
    -- upvalues: t1 (copy)
    if #p5.elements ~= #p6.elements then
        return false
    end

    for i = 1, #p5.elements do
        if not t1.GraphElement.eq(p5.elements[i], p6.elements[i]) then
            return false
        end
    end

    return true
end

t1.Reader = {}

local t2 = {}

local function graphs_index() -- line: 87
    -- upvalues: sim (copy)
    local sim_data = sim.Parent:FindFirstChild("sim_data")
    local graphs = sim_data and sim_data:FindFirstChild("graphs")
    local index = graphs and graphs:FindFirstChild("index")

    if not index then
        error("ReplicatedStorage.Skate3.sim_data.graphs.index is not installed", 0)
    end

    local v1 = require(index)

    if v1.format ~= 1 then
        error(("unsupported sim_data.graphs format %*"):format(v1.format), 0)
    end

    return v1, graphs
end

local function ends_with_path(p7, p8) -- line: 101
    if p7 == p8 then
        return true
    end

    local v2 = "/" .. p8

    if not (#p7 >= #v2) then
        return false
    end

    return string.sub(p7, -#v2) == v2
end

local function find_entry(p9, p10) -- line: 109
    local v4 = string.gsub(p10, "\\", "/")

    for _, v5 in p9.graphs do
        local path = v5.path
        local v6

        if v4 == path then
            v6 = true
        else
            local v7 = "/" .. path

            v6 = #v4 >= #v7 and string.sub(v4, -#v7) == v7
        end

        if v6 then
            return v5
        end
    end

    local v9 = string.lower(v4)

    for _, v10 in p9.graphs do
        local v11 = string.lower(v10.path)
        local v12

        if v9 == v11 then
            v12 = true
        else
            local v13 = "/" .. v11

            v12 = #v9 >= #v13 and string.sub(v9, -#v13) == v13
        end

        if v12 then
            return v10
        end
    end

    return nil
end

local function read_stock(p11) -- line: 126
    -- upvalues: t2 (copy), graphs_index (copy), find_entry (copy)
    local v15, v16 = graphs_index()
    local v17 = find_entry(v15, p11)

    if v17 == nil then
        error("The system cannot find the file specified. (not in sim_data.graphs.index)", 0)
    end

    local v18 = t2[v17.path]

    if v18 ~= nil then
        return v18
    end

    local t3 = {}

    for _, v19 in v17.parts do
        local v20 = v16:FindFirstChild(v19)

        if not v20 then
            error(("sim_data.graphs.%* is not installed"):format(v19), 0)
        end

        for _, v21 in require(v20) do
            table.insert(t3, v21)
        end
    end

    local v22 = buffer.fromstring(table.concat(t3))

    if buffer.len(v22) ~= v17.bytes then
        error(("sim_data.graphs: %* bytes, index says %*"):format(buffer.len(v22), v17.bytes), 0)
    end

    t2[v17.path] = v22

    return v22
end

function t1.stock_paths() -- line: 155
    -- upvalues: graphs_index (copy)
    local t4 = {}

    for _, v23 in graphs_index().graphs do
        table.insert(t4, v23.path)
    end

    return t4
end

function t1.StateGraph.load(p12) -- line: 169
    -- upvalues: t1 (copy), read_stock (copy)
    local ok, result = pcall(read_stock, p12)

    if not ok then
        error(string.format("Cannot read graph %s: %s", tostring(p12), (tostring(result))), 0)
    end

    local decode = t1.StateGraph.decode
    local ok2, result2 = pcall(decode, result)

    if not ok2 then
        error(string.format("Invalid graph %s: %s", tostring(p12), (tostring(result2))), 0)
    end

    return result2
end

function t1.StateGraph.decode(p13) -- line: 183
    -- upvalues: t1 (copy)
    local v24 = if type(p13) == "string" then buffer.fromstring(p13) else p13
    local t5 = {
        offset = 0,
        bytes = v24
    }
    local v25, v26 = t1.Reader.element(t5)
    local t6 = {
        v25
    }
    local t7 = {
        { 0, v26 }
    }

    while #t7 > 0 do
        local v27 = t7[#t7]

        if v27[2] == 0 then
            table.remove(t7)
        else
            v27[2] -= 1

            local v28, v29 = t1.Reader.element(t5)
            local v30 = #t6

            table.insert(t6[v27[1] + 1].children, v30)
            table.insert(t6, v28)
            table.insert(t7, {
                v30,
                v29
            })
        end
    end

    if t5.offset ~= buffer.len(v24) then
        error(t1.Reader.error(t5, "trailing bytes after the root element"), 0)
    end

    return {
        elements = t6
    }
end

function t1.StateGraph.pack(p14) -- line: 219
    -- upvalues: import (copy)
    local packed = import("packed")

    if packed.is_view(p14.elements) then
        return nil
    end

    local v31 = packed.pack(p14.elements, {
        cache = 256
    })

    p14.elements = packed.view(v31)

    return v31
end

function t1.Reader.error(p15, p16) -- line: 233
    return string.format("stategraph byte 0x%X: %s", p15.offset, p16)
end

function t1.Reader.take(p17, p18) -- line: 239
    -- upvalues: t1 (copy)
    if buffer.len(p17.bytes) - p17.offset < p18 then
        error(t1.Reader.error(p17, "truncated record"), 0)
    end

    local offset = p17.offset

    p17.offset += p18

    return buffer.readstring(p17.bytes, offset, p18)
end

function t1.Reader.word(p19) -- line: 249
    -- upvalues: t1 (copy)
    return (string.unpack(">I4", t1.Reader.take(p19, 4)))
end

function t1.Reader.string(p20) -- line: 254
    -- upvalues: t1 (copy)
    local bytes = p20.bytes
    local v32 = buffer.len(bytes)
    local offset = p20.offset
    local v33 = v32 - 1
    local v34

    for i = offset, v33 do
        if buffer.readu8(bytes, i) == 0 then
            v34 = i - p20.offset
            break
        end
    end

    if v34 == nil then
        error(t1.Reader.error(p20, "unterminated string"), 0)
    end

    local offset2 = p20.offset
    local v36 = string.sub(t1.Reader.take(p20, v34 + 1), 1, v34)

    if utf8.len(v36) == nil then
        error(string.format("stategraph byte 0x%X: non-UTF-8 string", offset2), 0)
    end

    return v36
end

function t1.Reader.element(p21) -- line: 281
    -- upvalues: rt (copy), t1 (copy)
    local offset = p21.offset
    local v37 = t1.Reader.string(p21)
    local v38 = t1.Reader.word(p21)

    if rt.idiv(buffer.len(p21.bytes) - p21.offset, 7) < v38 then
        error(t1.Reader.error(p21, "attribute count exceeds remaining data"), 0)
    end

    local v39 = table.create(v38)

    for _ = 0, v38 - 1 do
        table.insert(v39, {
            name = t1.Reader.string(p21),
            text = t1.Reader.string(p21),
            float_bits = t1.Reader.word(p21),
            boolean_byte = string.byte(t1.Reader.take(p21, 1), 1)
        })
    end

    local v44 = t1.Reader.word(p21)

    if rt.idiv(buffer.len(p21.bytes) - p21.offset, 9) < v44 then
        error(t1.Reader.error(p21, "child count exceeds remaining data"), 0)
    end

    return {
        source_offset = offset,
        tag = v37,
        attributes = v39,
        children = {}
    }, v44
end

return t1
