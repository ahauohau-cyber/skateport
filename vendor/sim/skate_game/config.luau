-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)
local v1 = import("skate_game/setup")
local Difficulty = import("skate_game/difficulty").Difficulty
local SkateMap = import("skate_data/skate_map").SkateMap
local v2 = import("skate_data/files")

local function map_library() -- line: 17
    -- upvalues: import (copy)
    return import("skate_game/map_library")
end

local function teleport_menu() -- line: 20
    -- upvalues: import (copy)
    return import("skate_game/teleport_menu")
end

local t1 = {
    Config = {}
}

local function debug_str(p1) -- line: 36
    return "\"" .. string.gsub(p1, "[\\\"]", function(p2) -- line: 37
        return "\\" .. p2
    end) .. "\""
end

function t1.Config.from_env(p3, p4) -- line: 55
    -- upvalues: import (copy), v1 (copy), Difficulty (copy), SkateMap (copy), v2 (copy), t1 (copy)
    local v3 = p3 or {}

    p4 = p4 or {}

    local t2 = {
        verification_capture = nil,
        map = nil,
        map_path = nil,
        check_assets = false,
        start_paused = false,
        multiplayer = nil,
        map_fingerprint = "0x0000000000000000",
        teleport = nil,
        asset_root = v1.asset_root(v3, p4.skate3_assets),
        difficulty = Difficulty.default()
    }
    local n1 = 0

    local function next_arg() -- line: 74
        -- upvalues: n1 (ref), v3 (copy)
        n1 += 1

        return v3[n1]
    end

    local v6 = false
    local v5

    while true do
        n1 += 1

        local v7 = v3[n1]

        if v7 == nil then
            break
        end

        if v7 ~= "--trace" and v7 ~= "--trace-seconds" and v7 ~= "--trace-delay" and v7 ~= "--trace-min-us" then
            if v7 ~= "--trace-wait" and v7 ~= "--trace-gpu" then
                if v7 ~= "--net-host" and v7 ~= "--net-local" and v7 ~= "--net-session" and v7 ~= "--spawn-offset" and v7 ~= "--player-title" and v7 ~= "--appearance" and v7 ~= "--controller" then
                    if v7 == "--assets" then
                        n1 += 1

                        local v8 = v3[n1]

                        if v8 == nil then
                            error("--assets requires a directory", 0)
                        end

                        t2.asset_root = v8
                    elseif v7 == "--map" then
                        n1 += 1

                        local v9 = v3[n1]

                        if v9 == nil then
                            error("--map requires a .skate file", 0)
                        end

                        t2.map = SkateMap.load(v9)
                        v6 = true
                        t2.map_path = v9
                    elseif v7 == "--test-world" then
                        t2.map = nil
                        v6 = true
                        t2.map_path = nil
                    elseif v7 == "--check-assets" then
                        t2.check_assets = true
                    elseif v7 == "--start-paused" then
                        t2.start_paused = true
                    elseif v7 == "--teleport" then
                        n1 += 1

                        local v10 = v3[n1]

                        if v10 == nil then
                            error("--teleport requires a destination ID", 0)
                        end

                        t2.teleport = v10
                    elseif v7 == "--difficulty" then
                        local v11 = n1 + 1

                        n1 = v11

                        local v12 = v3[n1]

                        if v12 == nil then
                            error("--difficulty requires easy, normal, hardcore, motorized or custom", 0)
                        end

                        v5 = Difficulty.parse(v12), v11
                    elseif v7 == "--verify" then
                        n1 += 1

                        local v13 = v3[n1]

                        if v13 == nil then
                            error("--verify requires an output PNG path", 0)
                        end

                        t2.verification_capture = v13
                    else
                        error("Unknown argument " .. ("\"" .. string.gsub(v7, "[\\\"]", function(p5) -- line: 37
                            return "\\" .. p5
                        end) .. "\"") .. ". Usage: skate3rust [--assets DIRECTORY] [--map MAP.skate | --test-world] [--difficulty easy|normal|hardcore|motorized|custom] [--verify CAPTURE.png] [--check-assets] [--start-paused]", 0)
                    end
                else
                    error("Multiplayer option " .. v7 .. " is not translated", 0)
                end
            end
        else
            n1 += 1

            if v3[n1] == nil then
                error("Trace option requires a value", 0)
            end
        end
    end

    if v5 ~= nil then
        t2.difficulty = v5
    else
        local gameplay_settings = p4.gameplay_settings

        if gameplay_settings == nil then
            gameplay_settings = v2.read("../settings/gameplay.json")
        end

        t2.difficulty = Difficulty.load(t2.asset_root, gameplay_settings)
    end

    if not v6 then
        local v14 = import("skate_game/map_library").default_map(t2.asset_root, v2.read("../settings/default-map.json"))

        if v14 ~= nil then
            t2.map = SkateMap.load(v14)
            t2.map_path = v14
        end
    end

    local map_fingerprint, map_path, v15, v16

    if t2.map_path ~= nil then
        if p4.read_file ~= nil then
            map_fingerprint = t1.map_fingerprint
            map_path = t2.map_path

            if t2.map_path ~= nil then
                v15 = p4.read_file(t2.map_path)
            end

            v16 = false
        else
            v16 = true
        end
    else
        map_fingerprint = t1.map_fingerprint
        map_path = t2.map_path

        if t2.map_path ~= nil then
            v15 = p4.read_file(t2.map_path)
        end

        v16 = false
    end

    t2.map_fingerprint = if v16 then nil else map_fingerprint(map_path, v15)

    if t2.teleport ~= nil then
        local teleport = t2.teleport
        local v17 = import("skate_game/teleport_menu").load(t2.asset_root, v2.read("private/teleports.json"))
        local v18

        for _, v19 in ipairs(v17) do
            if v19.id == teleport then
                v18 = v19
                break
            end
        end

        if v18 == nil then
            error("Unknown teleport destination", 0)
        end

        if v18.matrix == nil or t2.map_path == nil or not import("skate_game/teleport_menu").same_map(t2.map_path, v18.map) then
            error("Teleport destination is unavailable or belongs to a different map", 0)
        end
    end

    if t2.verification_capture ~= nil then
        local verification_capture = t2.verification_capture
        local v20 = string.match(verification_capture, "[^/\\]*$") or ""

        if string.match(v20, "^.+%.([^.]*)$") ~= "png" then
            error("--verify output must be a PNG file", 0)
        end
    end

    return t2
end

local function fnv_step(p6, p7, p8) -- line: 216
    local v21 = bit32.bxor(p7, p8)
    local v22 = v21 * 435
    local v24 = math.floor(v22 / 4294967296)
    local v25 = v22 % 4294967296

    return (p6 * 435 + v24 + v21 % 16777216 * 256) % 4294967296, v25
end

function t1.map_fingerprint(p9, p10) -- line: 231
    local v26, v27

    if p9 ~= nil then
        if p10 == nil then
            error("map_fingerprint: no bytes supplied for " .. tostring(p9), 0)
        end

        if type(p10) == "string" then
            local v33 = #p10

            v27 = 3421674724
            v26 = 2216829733

            for i = 1, v33 do
                local v35 = bit32.bxor(v26, (string.byte(p10, i)))
                local v36 = v35 * 435
                local v38 = math.floor(v36 / 4294967296)

                v26 = v36 % 4294967296
                v27 = (v27 * 435 + v38 + v35 % 16777216 * 256) % 4294967296
            end
        else
            local v39 = buffer.len(p10) - 1

            v27 = 3421674724
            v26 = 2216829733

            for i = 0, v39 do
                local v41 = bit32.bxor(v26, (buffer.readu8(p10, i)))
                local v42 = v41 * 435
                local v44 = math.floor(v42 / 4294967296)

                v26 = v42 % 4294967296
                v27 = (v27 * 435 + v44 + v41 % 16777216 * 256) % 4294967296
            end
        end
    else
        v27 = 3421674724
        v26 = 2216829733

        for i = 1, 19 do
            local v29 = bit32.bxor(v26, (string.byte("skate-test-world-v1", i)))
            local v30 = v29 * 435
            local v32 = math.floor(v30 / 4294967296)

            v26 = v30 % 4294967296
            v27 = (v27 * 435 + v32 + v29 % 16777216 * 256) % 4294967296
        end
    end

    return string.format("0x%08X%08X", v27, v26)
end

return t1
