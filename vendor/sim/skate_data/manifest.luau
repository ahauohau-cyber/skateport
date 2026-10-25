-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)
require(sim.import)

local t1 = {
    GameAssets = {},
    AssetError = {}
}

function t1.AssetError.fmt(p1) -- line: 26
    return p1
end

local t2 = { "version", "character_scene", "initial_animation", "action_graph", "motion_graph" }

local function from_json(p2) -- line: 38
    -- upvalues: t2 (copy)
    local function v1() -- line: 39
        -- upvalues: p2 (copy)
        return game:GetService("HttpService"):JSONDecode(p2)
    end

    local ok, result = pcall(v1)

    if not ok then
        error(tostring(result), 0)
    end

    if type(result) ~= "table" or result[1] ~= nil then
        error("invalid type, expected struct GameAssets", 0)
    end

    for v2 in result do
        if table.find(t2, v2) == nil then
            error(string.format("unknown field `%s`, expected one of `version`, `character_scene`, `initial_animation`, `action_graph`, `motion_graph`", (tostring(v2))), 0)
        end
    end

    for _, v3 in t2 do
        if result[v3] == nil then
            error(string.format("missing field `%s`", v3), 0)
        end
    end

    local version = result.version

    if type(version) ~= "number" or version ~= math.floor(version) or version < 0 or version > 4294967295 then
        error("invalid value for `version`, expected u32", 0)
    end

    for i = 2, #t2 do
        if type(result[t2[i]]) ~= "string" then
            error(string.format("invalid type for `%s`, expected a string", t2[i]), 0)
        end
    end

    return {
        version = version,
        character_scene = result.character_scene,
        initial_animation = result.initial_animation,
        action_graph = result.action_graph,
        motion_graph = result.motion_graph
    }
end

local function trim_is_empty(p3) -- line: 83
    local v5 = string.gsub(p3, "%s", "")

    if string.find(v5, "[\194\225\226\227]") ~= nil then
        local v6 = string.gsub(v5, "\194[\133\160]", "")
        local v7 = string.gsub(v6, " ", "")
        local v8 = string.gsub(v7, "\226\128[\128-\138\168\169\175]", "")
        local v9 = string.gsub(v8, " ", "")

        v5 = string.gsub(v9, "　", "")
    end

    return #v5 == 0
end

local function join(p4, p5) -- line: 96
    if p4 == nil or tostring(p4) == "" then
        return p5
    end

    local v10 = tostring(p4)
    local v11 = string.sub(v10, -1)

    if v11 == "/" or v11 == "\\" then
        return v10 .. p5
    end

    return v10 .. "/" .. p5
end

local function graphs_index() -- line: 108
    -- upvalues: sim (copy)
    local sim_data = sim.Parent:FindFirstChild("sim_data")
    local graphs = sim_data and sim_data:FindFirstChild("graphs")
    local index = graphs and graphs:FindFirstChild("index")

    if index then
        return require(index)
    end

    return nil
end

function t1.GameAssets.load(p6) -- line: 123
    -- upvalues: sim (copy), t1 (copy)
    local v12

    if p6 == nil or tostring(p6) == "" then
        v12 = "private/game.json"
    else
        local v13 = tostring(p6)
        local v14 = string.sub(v13, -1)

        v12 = if v14 == "/" or v14 == "\\" then v13 .. "private/game.json" else v13 .. "/" .. "private/game.json"
    end

    local sim_data = sim.Parent:FindFirstChild("sim_data")
    local graphs = sim_data and sim_data:FindFirstChild("graphs")
    local index = graphs and graphs:FindFirstChild("index")
    local v15 = if index then require(index) else nil

    if v15 == nil or v15.manifest == nil then
        error(string.format("Cannot read %s: %s. Run pipeline/Prepare-Assets.ps1 or select the correct --assets directory.", v12, "ReplicatedStorage.Skate3.sim_data.graphs.index is not installed"), 0)
    end

    local source = v15.manifest.source
    local v16 = t1.GameAssets.parse(source)

    for _, v17 in {
            {
                "Character scene",
                v16.character_scene
            },
            {
                "ActionGraph",
                v16.action_graph
            },
            {
                "MotionGraph",
                v16.motion_graph
            }
        } do
        local v18 = v17[1]
        local v19 = v17[2]
        local v20

        if p6 == nil or tostring(p6) == "" then
            v20 = v19
        else
            local v21 = tostring(p6)
            local v22 = string.sub(v21, -1)

            v20 = if v22 == "/" or v22 == "\\" then v21 .. v19 else v21 .. "/" .. v19
        end

        local v23 = v15.present ~= nil and v15.present[v19] == true

        if not v23 then
            for _, v24 in v15.graphs do
                if v24.path == v19 then
                    v23 = true
                    break
                end
            end
        end

        if not v23 then
            error(string.format("%s missing: %s", v18, v20), 0)
        end
    end

    return v16
end

function t1.GameAssets.parse(p7) -- line: 164
    -- upvalues: t1 (copy), from_json (copy), trim_is_empty (copy)
    local ok, result = pcall(from_json, p7)

    if not ok then
        error(string.format("Invalid game asset manifest: %s", (tostring(result))), 0)
    end

    if result.version ~= 1 then
        error(string.format("Unsupported asset manifest version %d", result.version), 0)
    end

    t1.validate_path(result.character_scene, "character_scene", "glb")
    t1.validate_path(result.action_graph, "action_graph", "stategraph")
    t1.validate_path(result.motion_graph, "motion_graph", "stategraph")

    if trim_is_empty(result.initial_animation) then
        error("initial_animation must name a stock animation", 0)
    end

    return result
end

function t1.validate_path(p8, p9, p10) -- line: 190
    local v25 = string.sub(p8, 1, 1) ~= "/"
    local v26 = true
    local match

    for match2 in string.gmatch(p8, "[^/]*") do
        if match2 ~= "" then
            if match2 == "." then
                if v26 then
                    v25 = false
                end
            elseif match2 == ".." then
                v25 = false
                match = nil
            else
                match = match2
            end
        end

        v26 = false
    end

    if #p8 == 0 or not v25 or string.find(p8, ":", 1, true) ~= nil or string.find(p8, "\\", 1, true) ~= nil or string.find(p8, "#", 1, true) ~= nil then
        error(string.format("%s must be a relative asset path using forward slashes", p9), 0)
    end

    local v27

    if match ~= nil then
        local v28 = #match
        local v29

        for i = v28, 1, -1 do
            if string.sub(match, i, i) == "." then
                v29 = i
                break
            end
        end

        v27 = if v29 == nil then nil elseif v29 > 1 then string.sub(match, v29 + 1) else nil
    end

    if v27 ~= p10 then
        error(string.format("%s must name a .%s file", p9, p10), 0)
    end
end

return t1
