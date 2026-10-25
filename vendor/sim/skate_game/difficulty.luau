-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)
require(sim.import)

local HttpService = game:GetService("HttpService")
local t1 = {
    NATIVE_MODES = { "easy", "normal", "hardcore", "motorized", "test" },
    Difficulty = {
        Easy = 0,
        Normal = 1,
        Hardcore = 2,
        Motorized = 3,
        Custom = 4
    }
}
local Difficulty = t1.Difficulty

function t1.Difficulty.default() -- line: 31
    -- upvalues: Difficulty (copy)
    return Difficulty.Easy
end

t1.Difficulty.ALL = {
    Difficulty.Easy,
    Difficulty.Normal,
    Difficulty.Hardcore,
    Difficulty.Motorized,
    Difficulty.Custom
}

local t2 = {
    "easy",
    "normal",
    "hardcore",
    "motorized",
    "custom"
}

local function debug_str(p1) -- line: 41
    local v1 = string.gsub(p1, "[\\\"]", function(p2) -- line: 42
        return "\\" .. p2
    end)
    local v2 = string.gsub(v1, "\n", "\\n")
    local v3 = string.gsub(v2, "\r", "\\r")

    return "\"" .. string.gsub(v3, "\t", "\\t") .. "\""
end

local function path_parent(p3) -- line: 52
    while #p3 > 1 and (string.sub(p3, -1) == "/" or string.sub(p3, -1) == "\\") do
        p3 = string.sub(p3, 1, -2)
    end

    if p3 == "" or p3 == "/" or p3 == "\\" or string.match(p3, "^%a:[/\\]?$") then
        return nil
    end

    local v5 = #p3
    local v6

    for i = v5, 1, -1 do
        local v7 = string.sub(p3, i, i)

        if v7 == "/" or v7 == "\\" then
            v6 = i
            break
        end

        v6 = nil
    end

    if v6 == nil then
        return ""
    end

    if v6 == 1 then
        return (string.sub(p3, 1, 1))
    end

    local v9 = string.sub(p3, 1, v6 - 1)

    if string.match(v9, "^%a:$") then
        return (string.sub(p3, 1, v6))
    end

    return v9
end

local function path_join(p4, p5) -- line: 82
    if p4 == "" then
        return p5
    end

    local v10 = string.sub(p4, -1)

    if v10 == "/" or v10 == "\\" then
        return p4 .. p5
    end

    return p4 .. "/" .. p5
end

function t1.Difficulty.key(p6) -- line: 93
    -- upvalues: Difficulty (copy)
    if p6 == Difficulty.Custom then
        return "custom"
    end

    return Difficulty.profile_key(p6)
end

function t1.Difficulty.profile_key(p7) -- line: 102
    -- upvalues: t1 (copy)
    return t1.NATIVE_MODES[p7 + 1]
end

function t1.Difficulty.label(p8) -- line: 106
    -- upvalues: Difficulty (copy)
    if p8 == Difficulty.Easy then
        return "Easy"
    end

    if p8 == Difficulty.Normal then
        return "Normal"
    end

    if p8 == Difficulty.Hardcore then
        return "Hardcore"
    end

    if p8 == Difficulty.Motorized then
        return "Motorized"
    end

    return "Custom"
end

function t1.Difficulty.parse(p9) -- line: 121
    -- upvalues: Difficulty (copy), debug_str (copy)
    for _, v11 in ipairs(Difficulty.ALL) do
        if string.lower(Difficulty.key(v11)) == string.lower(p9) then
            return v11
        end
    end

    error("Unknown difficulty " .. debug_str(p9) .. "; expected easy, normal, hardcore, motorized or custom", 0)
end

function t1.Difficulty.path(p10) -- line: 138
    -- upvalues: path_parent (copy)
    local v12 = p10 or ""
    local v13 = path_parent(v12)

    if v13 ~= nil then
        v12 = v13
    end

    if v12 == "" then
        return "settings/gameplay.json"
    end

    local v14 = string.sub(v12, -1)

    if v14 == "/" or v14 == "\\" then
        return v12 .. "settings/gameplay.json"
    end

    return v12 .. "/" .. "settings/gameplay.json"
end

t1.Saved = {}

function t1.Saved.from_json(p11) -- line: 151
    -- upvalues: HttpService (copy), t2 (copy)
    local function v15() -- line: 152
        -- upvalues: p11 (copy), HttpService (copy)
        return HttpService:JSONDecode(p11)
    end

    local ok, result = pcall(v15)

    if not ok then
        error(tostring(result), 0)
    end

    if type(result) ~= "table" then
        error("invalid type: expected struct Saved", 0)
    end

    local difficulty = result.difficulty

    if difficulty == nil then
        error("missing field `difficulty`", 0)
    end

    if type(difficulty) ~= "string" then
        error("invalid type: expected a Difficulty variant name", 0)
    end

    for v16, v17 in ipairs(t2) do
        if v17 == difficulty then
            return {
                difficulty = v16 - 1
            }
        end
    end

    error("unknown variant `" .. difficulty .. "`, expected one of `easy`, `normal`, `hardcore`, `motorized`, `custom`", 0)
end

function t1.Saved.to_json(p12) -- line: 182
    -- upvalues: t2 (copy)
    return "{\"difficulty\":\"" .. t2[p12.difficulty + 1] .. "\"}"
end

function t1.Saved.to_json_pretty(p13) -- line: 187
    -- upvalues: t2 (copy)
    return "{\n  \"difficulty\": \"" .. t2[p13.difficulty + 1] .. "\"\n}"
end

function t1.Difficulty.load(_, p15) -- line: 194
    -- upvalues: t1 (copy), Difficulty (copy)
    if p15 == nil then
        return Difficulty.default()
    end

    local from_json = t1.Saved.from_json
    local ok, result = pcall(from_json, p15)

    if not ok then
        error("Invalid saved gameplay settings: " .. tostring(result), 0)
    end

    return result.difficulty
end

function t1.Difficulty.save(p16, p17) -- line: 209
    -- upvalues: t1 (copy), Difficulty (copy)
    return Difficulty.path(p17), t1.Saved.to_json_pretty({
        difficulty = p16
    })
end

return t1
