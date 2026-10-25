-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

local function rtl_is_finite(p1) -- line: 6
    if p1 ~= p1 or p1 == 1e999 then
        return false
    end

    return p1 ~= (-1e999)
end

local import = require(sim.import)
local HttpService = game:GetService("HttpService")

local function physics() -- line: 20
    -- upvalues: import (copy)
    return import("skate_game/physics")
end

local t1 = {
    Destination = {},
    Catalog = {}
}

local function catalog_from_json(p2) -- line: 37
    -- upvalues: HttpService (copy)
    local function v1() -- line: 38
        -- upvalues: p2 (copy), HttpService (copy)
        return HttpService:JSONDecode(p2)
    end

    local ok, result = pcall(v1)

    if not ok then
        error(tostring(result), 0)
    end

    if type(result) ~= "table" then
        error("invalid type: expected struct Catalog", 0)
    end

    if result.version == nil then
        error("missing field `version`", 0)
    end

    if type(result.version) ~= "number" or result.version < 0 or result.version % 1 ~= 0 or result.version > 4294967295 then
        error("invalid type: expected u32", 0)
    end

    if result.destinations == nil then
        error("missing field `destinations`", 0)
    end

    if type(result.destinations) ~= "table" then
        error("invalid type: expected a sequence", 0)
    end

    local t2 = {}

    for _, v2 in ipairs(result.destinations) do
        if type(v2) ~= "table" then
            error("invalid type: expected struct Destination", 0)
        end

        for _, v3 in ipairs({ "id", "name", "map" }) do
            if v2[v3] == nil then
                error("missing field `" .. v3 .. "`", 0)
            end

            if type(v2[v3]) ~= "string" then
                error("invalid type: expected a string", 0)
            end
        end

        local v5

        if v2.matrix ~= nil then
            if type(v2.matrix) ~= "table" or #v2.matrix ~= 4 then
                error("invalid length, expected an array of length 4", 0)
            end

            v5 = table.create(4)

            for i = 1, 4 do
                local v6 = v2.matrix[i]

                if type(v6) ~= "table" or #v6 ~= 4 then
                    error("invalid length, expected an array of length 4", 0)
                end

                v5[i] = table.create(4)

                for j = 1, 4 do
                    if type(v6[j]) ~= "number" then
                        error("invalid type: expected f32", 0)
                    end

                    v5[i][j] = v6[j]
                end
            end
        end

        table.insert(t2, {
            id = v2.id,
            name = v2.name,
            map = v2.map,
            matrix = v5
        })
    end

    return {
        version = result.version,
        destinations = t2
    }
end

function t1.load(_, p4) -- line: 100
    -- upvalues: t1 (copy), catalog_from_json (copy)
    if p4 == nil then
        error("Teleport locations: file not found", 0)
    end

    local v8 = catalog_from_json(p4)

    if v8.version ~= 1 then
        error("Unsupported teleport catalog version", 0)
    end

    local t4 = {}

    for _, v9 in ipairs(v8.destinations) do
        local v10 = v9.name == "" or v9.id == ""

        if not v10 then
            if t4[v9.id] then
                v10 = true
            else
                t4[v9.id] = true
            end
        end

        if not v10 then
            v10 = v9.map == "" or string.find(v9.map, "[/\\:]") ~= nil or v9.map == "." or v9.map == ".."
        end

        if v10 then
            error("Invalid teleport destination identity", 0)
        end

        if v9.matrix ~= nil and not t1.valid_matrix(v9.matrix) then
            error("Invalid teleport transform: " .. v9.name, 0)
        end
    end

    return v8.destinations
end

function t1.valid_matrix(p5) -- line: 138
    for i = 1, 4 do
        local v11 = p5[i][1]

        if v11 ~= v11 or v11 == 1e999 or v11 == (-1e999) then
            return false
        end

        local v12 = p5[i][2]

        if v12 ~= v12 or v12 == 1e999 or v12 == (-1e999) then
            return false
        end

        local v13 = p5[i][3]
        local v14, v15

        if v13 == v13 and v13 ~= 1e999 and v13 ~= (-1e999) then
            local v16 = p5[i][4]

            v14 = v16 == v16 and v16 ~= 1e999 and v16 ~= (-1e999)
            v15 = false
        else
            v15 = true
        end

        if v15 or not v14 then
            return false
        end
    end

    if math.abs(p5[1][4]) < 1E-05 then
        if not (math.abs(p5[2][4]) < 1E-05) or not (math.abs(p5[3][4]) < 1E-05) then
            return false
        end

        if math.abs(p5[4][4] - 1) < 1E-05 then
            return p5[3][1] * p5[3][1] + p5[3][3] * p5[3][3] > 1E-06
        end

        return false
    end

    return false
end

function t1.same_map(p6, p7) -- line: 155
    local v21 = string.match(p6, "[^/\\]*$") or ""

    if v21 == "" or v21 == ".." then
        return false
    end

    local v22 = string.match(v21, "^(.+)%.[^.]*$") or v21

    return string.lower(v22) == string.lower(p7)
end

t1.Travel = {}

function t1.Travel.default() -- line: 170
    return {
        open = false,
        closed_this_frame = false,
        shown = false,
        selected = 0,
        generation = nil,
        rows = {}
    }
end

function t1.interact(p8, p9, p10, p11, p12, p13) -- line: 199
    -- upvalues: rt (copy), import (copy), t1 (copy)
    p8.closed_this_frame = false

    local v23 = p11.wheel_delta or 0
    local v24

    if p8.generation ~= p10.generation then
        p8.generation = p10.generation
        p8.open = false
        p8.shown = false

        local teleports = p11.teleports

        if teleports == nil then
            teleports = import("skate_data/files").read("private/teleports.json")
        end

        local load = t1.load
        local asset_root = p9.asset_root
        local ok, result = pcall(load, asset_root, teleports)

        if ok then
            p8.rows = result
        else
            v24 = "Travel destinations: " .. tostring(result)
            p8.rows = {}
        end

        local t5 = {}

        for _, v25 in ipairs(p8.rows) do
            if v25.matrix ~= nil and p10.path ~= nil and t1.same_map(p10.path, v25.map) then
                table.insert(t5, v25)
            end
        end

        p8.rows = t5

        if p9.teleport ~= nil then
            local teleport = p9.teleport

            if p10.generation == 0 then
                for _, v26 in ipairs(p8.rows) do
                    if v26.id == teleport then
                        if v26.matrix ~= nil then
                            local travel_to = import("skate_game/physics").SkaterRuntime.travel_to
                            local copy = rt.copy
                            local matrix = v26.matrix

                            pcall(travel_to, p13, copy(matrix))
                        end

                        break
                    end
                end
            end
        end
    end

    if not p8.open or p8.shown then
        local v27 = v24

        if p8.open then
            local v28 = #p8.rows + 1
            local v29 = p11.up == true or bit32.band(p11.nav_pressed or 0, 1) ~= 0
            local v31 = p11.down == true or bit32.band(p11.nav_pressed or 0, 2) ~= 0

            if v29 then
                p8.selected = (p8.selected + v28 - 1) % v28
            end

            if v31 then
                p8.selected = (p8.selected + 1) % v28
            end

            local scroll = p11.scroll

            if scroll ~= nil then
                scroll.y = rt.clamp(scroll.y - v23, 0, rt.fmax(#p8.rows * 36 - 360, 0))

                if (v29 or v31) and p8.selected < #p8.rows then
                    local v33 = p8.selected * 36

                    scroll.y = rt.fmax(rt.fmax(rt.fmin(scroll.y, v33), v33 + 36 - 360), 0)
                end
            end

            local v34 = p11.enter == true
            local v35 = if not v34 then bit32.band(p11.nav_pressed or 0, 4096) == 0 else nil
            local v37 = if v34 or not v35 then p8.selected else nil

            for _, v38 in ipairs(p11.pressed_rows or {}) do
                v37 = v38
            end

            local v39 = p11.escape == true
            local v40 = if not v39 then bit32.band(p11.nav_pressed or 0, 8208) == 0 else nil

            if v39 or not v40 then
                v37 = #p8.rows
            end

            if v37 ~= nil then
                local v42 = p8.rows[v37 + 1]
                local v43 = v24

                if v42 ~= nil and v42.matrix ~= nil then
                    local travel_to = import("skate_game/physics").SkaterRuntime.travel_to
                    local copy = rt.copy
                    local matrix = v42.matrix
                    local ok, result = pcall(travel_to, p13, copy(matrix))

                    if ok then
                        p12.open = false
                    else
                        v43 = "Travel: " .. tostring(result)
                    end
                end

                v27 = v43
                p8.closed_this_frame = p12.open
                p8.open = false
            else
                v27 = v24
            end
        end

        if not p8.open and p8.shown then
            p8.shown = false
        end

        return v27
    end

    p8.selected = 0
    p8.shown = true

    return v24
end

return t1
