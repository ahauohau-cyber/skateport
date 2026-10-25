-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

local t1 = {
    Sample = {}
}

function t1.Sample.raw_state(p1) -- line: 25
    -- upvalues: rt (copy)
    return {
        buttons = p1.buttons,
        triggers = rt.copy(p1.triggers),
        left = rt.copy(p1.left),
        right = rt.copy(p1.right)
    }
end

local t2 = {
    "schema",
    "t_us",
    "sample",
    "connected",
    "packet",
    "buttons",
    "triggers",
    "left",
    "right"
}

local function integer(p2, p3, p4, p5) -- line: 41
    if type(p2) ~= "number" or p2 ~= math.floor(p2) or p2 < p4 or p5 < p2 then
        error(string.format("invalid value for `%s`", p3), 0)
    end

    return p2
end

local function pair(p6, p7, p8, p9) -- line: 48
    if type(p6) ~= "table" then
        error(string.format("invalid type for `%s`, expected an array of length 2", p7), 0)
    end

    local n1 = 0

    for _ in p6 do
        n1 += 1
    end

    if n1 ~= 2 or p6[1] == nil or p6[2] == nil then
        error(string.format("invalid length for `%s`, expected an array of length 2", p7), 0)
    end

    local v1 = p6[1]

    if type(v1) ~= "number" or v1 ~= math.floor(v1) or v1 < p8 or p9 < v1 then
        error(string.format("invalid value for `%s`", p7), 0)
    end

    local v2 = p6[2]

    if type(v2) ~= "number" or v2 ~= math.floor(v2) or v2 < p8 or p9 < v2 then
        error(string.format("invalid value for `%s`", p7), 0)
    end

    return {
        v1,
        v2
    }
end

local function sample_from_json(p10) -- line: 62
    -- upvalues: t2 (copy), pair (copy)
    local function v3() -- line: 63
        -- upvalues: p10 (copy)
        return game:GetService("HttpService"):JSONDecode(p10)
    end

    local ok, result = pcall(v3)

    if not ok then
        error(tostring(result), 0)
    end

    if type(result) ~= "table" or result[1] ~= nil then
        error("invalid type, expected struct Sample", 0)
    end

    for v4 in result do
        if table.find(t2, v4) == nil then
            error(string.format("unknown field `%s`", (tostring(v4))), 0)
        end
    end

    for _, v5 in t2 do
        if result[v5] == nil and v5 ~= "packet" then
            error(string.format("missing field `%s`", v5), 0)
        end
    end

    if type(result.connected) ~= "boolean" then
        error("invalid type for `connected`, expected a boolean", 0)
    end

    local packet, packet2

    if result.packet ~= nil then
        packet = result.packet
        packet2 = packet

        if type(packet) ~= "number" or packet ~= math.floor(packet) or packet < 0 or packet > 4294967295 then
            error(string.format("invalid value for `%s`", "packet"), 0)
        end
    end

    local schema = result.schema

    if type(schema) ~= "number" or schema ~= math.floor(schema) or schema < 0 or schema > 4294967295 then
        error(string.format("invalid value for `%s`", "schema"), 0)
    end

    local t4 = {}

    t4.schema = schema

    local t_us = result.t_us

    if type(t_us) ~= "number" or t_us ~= math.floor(t_us) or t_us < 0 or t_us > 18446744073709552000 then
        error(string.format("invalid value for `%s`", "t_us"), 0)
    end

    t4.t_us = t_us

    local sample = result.sample

    if type(sample) ~= "number" or sample ~= math.floor(sample) or sample < 0 or sample > 18446744073709552000 then
        error(string.format("invalid value for `%s`", "sample"), 0)
    end

    t4.sample = sample
    t4.connected = result.connected
    t4.packet = packet2

    local buttons = result.buttons

    if type(buttons) ~= "number" or buttons ~= math.floor(buttons) or buttons < 0 or buttons > 65535 then
        error(string.format("invalid value for `%s`", "buttons"), 0)
    end

    t4.buttons = buttons
    t4.triggers = pair(result.triggers, "triggers", 0, 255)
    t4.left = pair(result.left, "left", -32768, 32767)
    t4.right = pair(result.right, "right", -32768, 32767)

    return t4
end

local function lines(p11) -- line: 103
    local t5 = {}
    local n2 = 1

    while true do
        if not (n2 <= #p11) then
            return t5
        end

        local v7 = string.find(p11, "\n", n2, true)

        if v7 == nil then
            break
        end

        local v9 = string.sub(p11, n2, v7 - 1)

        if string.sub(v9, -1) == "\r" then
            v9 = string.sub(v9, 1, -2)
        end

        table.insert(t5, v9)
        n2 = v7 + 1
    end

    table.insert(t5, (string.sub(p11, n2)))

    return t5
end

local function trim_is_empty(p12) -- line: 123
    local v11 = string.gsub(p12, "%s", "")

    if string.find(v11, "[\194\225\226\227]") ~= nil then
        local v12 = string.gsub(v11, "\194[\133\160]", "")
        local v13 = string.gsub(v12, " ", "")
        local v14 = string.gsub(v13, "\226\128[\128-\138\168\169\175]", "")
        local v15 = string.gsub(v14, " ", "")

        v11 = string.gsub(v15, "　", "")
    end

    return #v11 == 0
end

t1.Recording = {}

function t1.Recording.load(p13) -- line: 139
    -- upvalues: sim (copy), t1 (copy)
    local sim_data = sim.Parent:FindFirstChild("sim_data")
    local recordings = sim_data and sim_data:FindFirstChild("recordings")
    local v16 = if recordings then require(recordings)[tostring(p13)] else nil

    if type(v16) ~= "string" then
        error(string.format("Input recording %s: %s", tostring(p13), "not found in ReplicatedStorage.Skate3.sim_data.recordings"), 0)
    end

    return t1.Recording.read(v16)
end

function t1.Recording.read(p14) -- line: 162
    -- upvalues: sample_from_json (copy), lines (copy), trim_is_empty (copy)
    local t6 = {}
    local v17 = lines(p14)

    for i = 0, #v17 - 1 do
        local v18 = v17[i + 1]

        if utf8.len(v18) == nil then
            error(string.format("Input recording line %d: %s", i + 1, "stream did not contain valid UTF-8"), 0)
        end

        if not trim_is_empty(v18) then
            local ok, result = pcall(sample_from_json, v18)

            if not ok then
                error(string.format("Input recording line %d: %s", i + 1, (tostring(result))), 0)
            end

            if result.schema ~= 1 or result.sample ~= #t6 then
                error(string.format("Input recording line %d: unsupported schema or missing/out-of-order sample", i + 1), 0)
            end

            local v19 = t6[#t6]

            if v19 ~= nil and result.t_us <= v19.t_us then
                error(string.format("Input recording line %d: timestamps must increase", i + 1), 0)
            end

            if result.connected ~= (result.packet ~= nil) then
                error(string.format("Input recording line %d: connection and packet disagree", i + 1), 0)
            end

            table.insert(t6, result)
        end
    end

    if #t6 == 0 then
        error("Input recording is empty", 0)
    end

    return {
        samples = t6
    }
end

function t1.Recording.samples(p15) -- line: 206
    return p15.samples
end

function t1.Recording.duration_us(p16) -- line: 211
    return p16.samples[#p16.samples].t_us - p16.samples[1].t_us
end

function t1.Recording.at_elapsed_us(p17, p18) -- line: 218
    -- upvalues: rt (copy)
    local v21 = math.min(p17.samples[1].t_us + p18, 18446744073709552000)
    local v22 = 0
    local v23 = #p17.samples

    while v22 < v23 do
        local v24 = v22 + rt.idiv(v23 - v22, 2)

        if p17.samples[v24 + 1].t_us <= v21 then
            v22 = v24 + 1
        else
            v23 = v24
        end
    end

    if v22 - 1 < 0 then
        error("attempt to subtract with overflow", 0)
    end

    return p17.samples[v22 - 1 + 1]
end

return t1
