-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local v1 = buffer.create(8)

local function rtl_from_bits(p1) -- line: 7
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p1)

    return (buffer.readf32(v1, 0))
end

local function rtl_is_finite(p2) -- line: 11
    if p2 ~= p2 or p2 == 1e999 then
        return false
    end

    return p2 ~= (-1e999)
end

local v2 = require(sim.import)("skate_data/attrib_hash")
local t1 = {
    Field = {},
    Collection = {},
    Collections = {}
}
local self = setmetatable({}, {
    __mode = "k"
})
local self2 = setmetatable({}, {
    __mode = "k"
})

local function identity(p3, p4) -- line: 48
    return p3 .. "/" .. p4
end

local function collections_by_id(p5) -- line: 52
    -- upvalues: v2 (copy), self (copy)
    local v5 = self[p5]

    if v5 == nil then
        v5 = {}

        for _, v6 in p5.collections do
            local v7 = v2.numeric_name(v6.class_name) .. "/" .. v2.numeric_name(v6.key)

            if v5[v7] == nil then
                v5[v7] = v6
            end
        end

        self[p5] = v5
    end

    return v5
end

local function fields_by_id(p6) -- line: 67
    -- upvalues: v2 (copy), self2 (copy)
    local v8 = self2[p6]

    if v8 == nil then
        local t6 = {}

        for v9 in p6.fields do
            table.insert(t6, v9)
        end

        table.sort(t6)
        v8 = {}

        for _, v10 in t6 do
            local v11 = v2.numeric_name(v10)

            if v8[v11] == nil then
                v8[v11] = p6.fields[v10]
            end
        end

        self2[p6] = v8
    end

    return v8
end

local function strip_whitespace(p7) -- line: 88
    local v12 = string.gsub(p7, "%s", "")

    if string.find(v12, "[\194\225\226\227]") ~= nil then
        local v13 = string.gsub(v12, "\194[\133\160]", "")
        local v14 = string.gsub(v13, " ", "")
        local v15 = string.gsub(v14, "\226\128[\128-\138\168\169\175]", "")
        local v16 = string.gsub(v15, " ", "")

        v12 = string.gsub(v16, "　", "")
    end

    return v12
end

local function expect_string(p8, p9) -- line: 105
    if type(p8) ~= "string" then
        error(("missing field `%*`"):format(p9), 0)
    end

    return p8
end

function t1.Collections.from_value(p10) -- line: 112
    if not (type(p10) == "table" and type(p10.version) == "number") then
        error("missing field `version`", 0)
    end

    if type(p10.collections) ~= "table" then
        error("missing field `collections`", 0)
    end

    local v19 = table.create(#p10.collections)

    for v20, v21 in p10.collections do
        if type(v21.fields) ~= "table" then
            error("missing field `fields`", 0)
        end

        local t7 = {}

        for v22, v23 in v21.fields do
            local _type = v23.type

            if type(_type) ~= "string" then
                error("missing field `type`", 0)
            end

            local t8 = {}

            t8.type_name = _type

            local data = v23.data

            if type(data) ~= "string" then
                error("missing field `data`", 0)
            end

            t8.data = data
            t8.array = v23.array
            t7[v22] = t8
        end

        local class = v21.class

        if type(class) ~= "string" then
            error("missing field `class`", 0)
        end

        local t9 = {}

        t9.class_name = class

        local key = v21.key

        if type(key) ~= "string" then
            error("missing field `key`", 0)
        end

        t9.key = key

        local parent = v21.parent

        if type(parent) ~= "string" then
            error("missing field `parent`", 0)
        end

        t9.parent = parent
        t9.fields = t7

        local source = v21.source

        if type(source) ~= "string" then
            error("missing field `source`", 0)
        end

        t9.source = source

        local sha256 = v21.sha256

        if type(sha256) ~= "string" then
            error("missing field `sha256`", 0)
        end

        t9.sha256 = sha256
        v19[v20] = t9
    end

    return {
        version = p10.version,
        collections = v19
    }
end

function t1.Collections.from_json(p11) -- line: 145
    -- upvalues: t1 (copy)
    local function v24() -- line: 146
        -- upvalues: p11 (copy)
        return game:GetService("HttpService"):JSONDecode(p11)
    end

    local ok, result = pcall(v24)

    if not ok then
        error(tostring(result), 0)
    end

    return t1.Collections.from_value(result)
end

function t1.Collections.override_profile(p12, p13, p14, p15, p16) -- line: 160
    -- upvalues: v2 (copy), self (copy)
    local v25 = v2.numeric_name(p13)
    local v26 = v2.numeric_name(p15)
    local v27 = false

    for _, v28 in p12.collections do
        if v2.numeric_name(v28.class_name) == v25 and v2.numeric_name(v28.key) == v26 then
            v27 = true
            break
        end
    end

    if not v27 then
        error("Missing base profile", 0)
    end

    local v29 = v2.numeric_name(p14)
    local v30 = table.create(#p12.collections)

    for _, v31 in p12.collections do
        if v2.numeric_name(v31.class_name) ~= v25 or v2.numeric_name(v31.key) ~= v29 then
            table.insert(v30, v31)
        end
    end

    table.insert(v30, {
        source = "host custom profile",
        sha256 = "",
        class_name = p13,
        key = p14,
        parent = p15,
        fields = p16
    })
    p12.collections = v30
    self[p12] = nil
end

function t1.Collections.entries(p17) -- line: 194
    return p17.collections
end

local t11

local function load_stock() -- line: 201
    -- upvalues: sim (copy), t11 (ref)
    local sim_data = sim.Parent:FindFirstChild("sim_data")
    local index = sim_data and sim_data:FindFirstChild("index")

    if not index then
        error("private/stock/skater-collections.json: ReplicatedStorage.Skate3.sim_data.index is not installed", 0)
    end

    local v32 = require(index)

    if v32.format ~= 1 then
        error(("private/stock/skater-collections.json: unsupported sim_data format %*"):format(v32.format), 0)
    end

    local classes, types, sources, sha256s = v32.classes, v32.types, v32.sources, v32.sha256s
    local v33 = table.create(v32.collection_count)

    for _, v34 in v32.parts do
        local v35 = sim_data:FindFirstChild(v34)

        if not v35 then
            error(("private/stock/skater-collections.json: sim_data.%* is not installed"):format(v34), 0)
        end

        local v36 = require(v35)

        for _, v37 in v36 do
            local t12 = {}

            for _, v38 in v37[6] do
                t12[v38[1]] = {
                    type_name = types[v38[2]],
                    data = v38[3],
                    array = v38[4]
                }
            end

            table.insert(v33, {
                class_name = classes[v37[1]],
                key = v37[2],
                parent = v37[3],
                fields = t12,
                source = sources[v37[4]],
                sha256 = sha256s[v37[5]]
            })
        end

        table.clear(v36)
    end

    if #v33 ~= v32.collection_count then
        error(("private/stock/skater-collections.json: %* collections, index says %*"):format(#v33, v32.collection_count), 0)
    end

    t11 = {
        version = v32.version,
        collections = v33
    }
end

function t1.Collections.load(_) -- line: 246
    -- upvalues: v2 (copy), self (copy), t11 (ref), load_stock (copy)
    if t11 == nil then
        load_stock()
    end

    local t14 = {
        version = t11.version,
        collections = table.clone(t11.collections)
    }

    if t14.version ~= 1 then
        error(string.format("Unsupported skater collections version %d", t14.version), 0)
    end

    local index = t11.index

    if index == nil then
        index = {}

        for _, v39 in t14.collections do
            local v40 = v2.numeric_name(v39.class_name) .. "/" .. v2.numeric_name(v39.key)

            if index[v40] ~= nil then
                error(string.format("Duplicate collection %s/%s", v39.class_name, v39.key), 0)
            end

            index[v40] = v39
        end

        t11.index = index
    end

    self[t14] = table.clone(index)

    return t14
end

function t1.Collections.field(p19, p20, p21, p22) -- line: 272
    -- upvalues: v2 (copy), collections_by_id (copy), fields_by_id (copy)
    local v41 = v2.numeric_name(p20)
    local v42 = v2.numeric_name(p22)
    local v43 = collections_by_id(p19)
    local v44 = #p19.collections
    local v45 = p21

    for _ = 0, v44 do
        local v46 = v43[v41 .. "/" .. v2.numeric_name(v45)]

        if v46 == nil then
            error(string.format("Missing stock collection %s/%s", p20, v45), 0)
        end

        local v47 = v46.fields[p22]

        if v47 == nil then
            v47 = fields_by_id(v46)[v42]
        end

        if v47 ~= nil then
            return v47
        end

        if #v46.parent == 0 then
            error(string.format("Missing stock field %s/%s/%s", p20, p21, p22), 0)
        end

        v45 = v46.parent
    end

    error(string.format("Cyclic stock collection inheritance %s/%s", p20, p21), 0)
end

function t1.Collections.float(p23, p24, p25, p26) -- line: 302
    -- upvalues: v1 (copy), t1 (copy)
    local v48 = t1.Collections.field(p23, p24, p25, p26)

    if v48.type_name ~= "EA::Reflection::Float" then
        error(string.format("Expected float at %s/%s/%s", p24, p25, p26), 0)
    end

    buffer.writeu32(v1, 0, t1.decode_words(v48.data, 1)[1])

    local v50 = buffer.readf32(v1, 0)

    if v50 ~= v50 or v50 == 1e999 or v50 == (-1e999) then
        error(string.format("Non-finite stock float %s/%s/%s", p24, p25, p26), 0)
    end

    return v50
end

function t1.Collections.integer(p27, p28, p29, p30) -- line: 316
    -- upvalues: t1 (copy)
    local v51 = t1.Collections.field(p27, p28, p29, p30)

    if v51.type_name ~= "EA::Reflection::Int32" and v51.type_name ~= "EA::Reflection::UInt32" then
        error(string.format("Expected integer at %s/%s/%s", p28, p29, p30), 0)
    end

    return t1.decode_words(v51.data, 1)[1]
end

function t1.Collections.boolean(p31, p32, p33, p34) -- line: 325
    -- upvalues: t1 (copy)
    local v52 = t1.Collections.field(p31, p32, p33, p34)

    if v52.type_name ~= "EA::Reflection::Bool" then
        error(string.format("Expected boolean at %s/%s/%s", p32, p33, p34), 0)
    end

    local v53 = string.sub(v52.data, 1, 2)

    if v53 == "00" then
        return false
    end

    if v53 == "01" then
        return true
    end

    error(string.format("Invalid stock boolean %s/%s/%s", p32, p33, p34), 0)
end

function t1.Collections.words(p35, p36, p37, p38, p39) -- line: 344
    -- upvalues: t1 (copy)
    local v54, v55, v56, v57

    if type(p36) == "number" then
        v54 = p36
        v55 = p37
        v56 = p38
        v57 = p39
    else
        v54 = p39
        v55 = p36
        v56 = p37
        v57 = p38
    end

    if type(v54) ~= "number" then
        error("Collections.words: the word count N is required", 0)
    end

    return t1.decode_words(t1.Collections.field(p35, v55, v56, v57).data, v54)
end

function t1.decode_words(p40, p41) -- line: 358
    -- upvalues: strip_whitespace (copy)
    local v58 = strip_whitespace(p40)

    if #v58 ~= p41 * 8 or string.find(v58, "[\128-\255]") ~= nil then
        error(string.format("Expected %d big-endian words, found %d bytes of hex", p41, #v58), 0)
    end

    local v59 = table.create(p41, 0)

    for i = 0, p41 - 1 do
        local v60 = string.sub(v58, i * 8 + 1, i * 8 + 8)

        if string.sub(v60, 1, 1) == "+" then
            v60 = string.sub(v60, 2)
        end

        if string.find(v60, "^%x+$") == nil then
            error("Invalid collection payload: invalid digit found in string", 0)
        end

        v59[i + 1] = tonumber(v60, 16)
    end

    return v59
end

return t1
