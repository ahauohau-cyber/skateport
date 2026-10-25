-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/hud_runtime")

local function apt_text() -- line: 28
    -- upvalues: import (copy)
    return import("skate_game/apt_text")
end

local function scoring_runtime() -- line: 31
    -- upvalues: import (copy)
    return import("skate_game/scoring_runtime")
end

local function apt_scene() -- line: 34
    -- upvalues: import (copy)
    return import("skate_game/apt_scene")
end

local t1 = {
    Hud = {},
    CANVAS_WIDTH = 1280,
    CANVAS_HEIGHT = 720
}

function t1.load_source() -- line: 61
    -- upvalues: sim (copy)
    local sim_data = sim.Parent:FindFirstChild("sim_data")
    local hud = if sim_data == nil then nil else sim_data:FindFirstChild("hud")
    local index = if hud == nil then nil else hud:FindFirstChild("index")

    if index == nil then
        error("private/hud/runtime/trickdisplay.json: ReplicatedStorage.Skate3.sim_data.hud.index is not installed", 0)
    end

    local v2 = require(index)

    if v2.format ~= 1 then
        error(("private/hud/runtime/trickdisplay.json: unsupported sim_data format %*"):format(v2.format), 0)
    end

    local t2 = {}

    for _, v3 in v2.parts do
        local v4 = hud:FindFirstChild(v3)

        if v4 == nil then
            error(("private/hud/runtime/trickdisplay.json: sim_data.hud.%* is not installed"):format(v3), 0)
        end

        for _, v5 in require(v4) do
            local v6 = t2

            for _, v7 in v5[1] do
                v6 = v6[v7]
            end

            for v8, v9 in v5[2] do
                v6[v8] = v9
            end
        end
    end

    return t2
end

function t1.setup(p1, p2) -- line: 94
    -- upvalues: rt (copy), import (copy), v1 (copy), t1 (copy)
    local v10 = if p2 == nil then t1.load_source() else p2
    local Runtime = import("skate_game/scoring_runtime").Runtime
    local v11 = v1.Runtime.load(v10, Runtime.hud_input(p1.scoring))
    local v12 = import("skate_game/apt_scene").shapes_from_value(v10.shapes)
    local t3 = {}

    for _, v13 in v12 do
        for _, v14 in v13 do
            t3[v14.texture.rgba] = {
                v14.texture.width,
                v14.texture.height
            }
        end
    end

    for _, v15 in v11.bindings.movie.text_assets.fonts do
        t3[v15.texture] = rt.copy(v15.size)
    end

    return {
        generation = 0,
        failed = false,
        runtime = v11,
        source = v10,
        shapes = v12,
        textures = t3
    }
end

function t1.render(p3) -- line: 124
    -- upvalues: import (copy)
    if p3 == nil or p3.failed then
        return {}
    end

    local display_list = import("skate_game/apt_scene").display_list
    local movie = p3.runtime.bindings.movie
    local vm = p3.runtime.vm
    local shapes = p3.shapes
    local ok, result = pcall(display_list, movie, vm, shapes)

    if ok then
        return result
    end

    p3.failed = true

    return {}, result
end

local humanize_trick_id

function t1.display_trick(p4, p5) -- line: 141
    -- upvalues: t1 (copy)
    if #p5 == 0 then
        return ""
    end

    local text_assets = if p4 == nil then nil else p4.runtime.bindings.text_assets

    return t1.localize_trick(p5, text_assets)
end

function t1.localize_trick(p6, p7) -- line: 155
    -- upvalues: import (copy), humanize_trick_id (ref)
    if string.sub(p6, 1, 1) == "#" then
        return (string.sub(p6, 2))
    end

    local t4 = {}

    for match in string.gmatch(p6, "%S+") do
        local v16 = if p7 == nil then match else import("skate_game/apt_text").TextAssets.localize(p7, match)

        if string.sub(v16, 1, 3) == "ID_" then
            local humanize_trick_id2 = humanize_trick_id

            table.insert(t4, humanize_trick_id2(v16))
        else
            table.insert(t4, v16)
        end
    end

    return table.concat(t4, " ")
end

function t1.humanize_trick_id(p8) -- line: 178
    local v17 = if string.sub(p8, 1, 9) == "ID_TRICK_" then string.sub(p8, 10) elseif string.sub(p8, 1, 3) == "ID_" then string.sub(p8, 4) else p8
    local t5 = {}

    for match in string.gmatch(v17, "[^_]+") do
        local v18 = string.lower(match)

        table.insert(t5, string.upper((string.sub(v18, 1, 1))) .. string.sub(v18, 2))
    end

    return table.concat(t5, " ")
end

humanize_trick_id = t1.humanize_trick_id

function t1.reset(p9, p10, p11) -- line: 201
    -- upvalues: import (copy), v1 (copy)
    if p9 == nil or p9.generation == p11.generation then
        return
    end

    local Runtime = import("skate_game/scoring_runtime").Runtime
    local load = v1.Runtime.load
    local source = p9.source
    local v20 = Runtime.hud_input(p10.scoring)
    local text_assets = p9.runtime.bindings.text_assets
    local ok, result = pcall(load, source, v20, text_assets)

    if not ok then
        p9.failed = true

        return
    end

    p9.runtime = result
    p9.generation = p11.generation
    p9.failed = false
end

function t1.advance(p12, p13, p14) -- line: 232
    -- upvalues: import (copy), v1 (copy)
    if p12 == nil or p12.failed or p12.generation ~= p14.generation then
        return nil
    end

    local Runtime = import("skate_game/scoring_runtime").Runtime
    local update = v1.Runtime.update
    local runtime = p12.runtime
    local v21 = Runtime.hud_input(p13.scoring)
    local new_trick, modified_trick, close_tricks = p13.scoring.new_trick, p13.scoring.modified_trick, p13.scoring.close_tricks
    local ok, result = pcall(update, runtime, v21, new_trick, modified_trick, close_tricks)

    if ok then
        return result
    end

    p12.failed = true

    return nil
end

return t1
