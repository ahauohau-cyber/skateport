-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)
require(sim.import)

local HttpService = game:GetService("HttpService")
local t1 = {}

local function path_parent(p1) -- line: 20
    while #p1 > 1 and (string.sub(p1, -1) == "/" or string.sub(p1, -1) == "\\") do
        p1 = string.sub(p1, 1, -2)
    end

    if p1 == "" or p1 == "/" or p1 == "\\" or string.match(p1, "^%a:[/\\]?$") then
        return nil
    end

    local v2 = #p1
    local v3

    for i = v2, 1, -1 do
        local v4 = string.sub(p1, i, i)

        if v4 == "/" or v4 == "\\" then
            v3 = i
            break
        end

        v3 = nil
    end

    if v3 == nil then
        return ""
    end

    if v3 == 1 then
        return (string.sub(p1, 1, 1))
    end

    local v6 = string.sub(p1, 1, v3 - 1)

    if string.match(v6, "^%a:$") then
        return (string.sub(p1, 1, v3))
    end

    return v6
end

local function path_join(p2, p3) -- line: 50
    if p2 == "" then
        return p3
    end

    local v7 = string.sub(p2, -1)

    if v7 == "/" or v7 == "\\" then
        return p2 .. p3
    end

    return p2 .. "/" .. p3
end

local function installation_root(p4) -- line: 62
    -- upvalues: path_parent (copy)
    local v8 = path_parent(p4)

    if v8 == nil then
        return p4
    end

    return v8
end

local function file_name(p5) -- line: 71
    return string.match(p5, "[^/\\]*$") or ""
end

local function file_stem(p6) -- line: 74
    local v9 = string.match(p6, "[^/\\]*$") or ""

    return if v9 ~= "" and v9 ~= ".." then string.match(v9, "^(.+)%.[^.]*$") or v9 else nil
end

local function extension(p7) -- line: 82
    local v10 = string.match(p7, "[^/\\]*$") or ""

    if v10 == "" or v10 == ".." then
        return nil
    end

    return string.match(v10, "^.+%.([^.]*)$")
end

local function components(p8) -- line: 91
    local t2 = {}
    local v11 = true

    for match in string.gmatch(p8, "[^/\\]+") do
        if match ~= "." or v11 then
            table.insert(t2, match)
        end

        v11 = false
    end

    return t2
end

local function is_absolute(p9) -- line: 103
    local v12 = string.sub(p9, 1, 1)

    if v12 == "/" or v12 == "\\" then
        return true
    end

    return string.match(p9, "^%a:") ~= nil
end

t1.Entry = {}

function t1.discover(_, p11) -- line: 115
    local t3 = {}

    for _, v13 in ipairs(p11 or {}) do
        local v14 = string.match(v13, "[^/\\]*$") or ""
        local v15 = if v14 == "" or v14 == ".." then nil else string.match(v14, "^.+%.([^.]*)$")

        if v15 ~= nil and string.lower(v15) == "skate" then
            local gsub = string.gsub
            local v16 = string.match(v13, "[^/\\]*$") or ""

            table.insert(t3, {
                label = gsub(if v16 == "" or v16 == ".." then nil else string.match(v16, "^(.+)%.[^.]*$") or v16, "_", " "),
                path = v13
            })
        end
    end

    for i = 2, #t3 do
        local v17 = t3[i]
        local v18 = string.lower(v17.label)
        local v19 = i - 1

        while v19 >= 1 and v18 < string.lower(t3[v19].label) do
            t3[v19 + 1] = t3[v19]
            v19 -= 1
        end

        t3[v19 + 1] = v17
    end

    table.insert(t3, 1, {
        label = "Test world",
        path = nil
    })

    return t3
end

function t1.default_map(p12, p13) -- line: 145
    -- upvalues: HttpService (copy), path_parent (copy), components (copy)
    if p13 == nil then
        return nil
    end

    local function v20() -- line: 153
        -- upvalues: p13 (copy), HttpService (copy)
        return HttpService:JSONDecode(p13)
    end

    local ok, result = pcall(v20)

    if not ok then
        error(tostring(result), 0)
    end

    if result == nil then
        return nil
    end

    if type(result) ~= "string" then
        error("invalid type: expected a string or null at line 1 column 1", 0)
    end

    local v21 = string.sub(result, 1, 1)
    local v22 = v21 == "/" or v21 == "\\" or string.match(result, "^%a:") ~= nil

    if not v22 then
        for _, v23 in ipairs((components(result))) do
            if v23 == "." or v23 == ".." then
                v22 = true
                break
            end
        end
    end

    if v22 then
        error("Invalid installed default map path", 0)
    end

    local v24 = path_parent(p12)

    if v24 == nil then
        v24 = p12
    end

    if v24 == "" then
        return result
    end

    local v25 = string.sub(v24, -1)

    if v25 == "/" or v25 == "\\" then
        return v24 .. result
    end

    return v24 .. "/" .. result
end

function t1.save_default(p14, p15) -- line: 185
    -- upvalues: HttpService (copy), path_parent (copy), components (copy)
    local v26 = path_parent(p14)

    if v26 == nil then
        v26 = p14
    end

    local v27 = false
    local v28 = false
    local v29 = false
    local v30 = false
    local v31 = false

    if p15 ~= nil then
        v27 = true
    else
        v31 = true
    end

    local v33, v34, v35

    if v27 then
        v33 = components(v26)
        v34 = components(p15)

        if #v34 >= #v33 then
            v28 = true
        else
            v35 = false
            v31 = false
        end
    end

    v27 = false

    local v36, v37

    if v28 then
        v36 = string.sub(v26, 1, 1)

        if v36 == "/" then
            v37 = true
            v29 = true
        else
            v27 = true
        end
    end

    v28 = false

    if v27 then
        if v36 == "\\" then
            v37 = true
            v29 = true
        else
            v28 = true
        end
    end

    v27 = false

    if v28 then
        if string.match(v26, "^%a:") ~= nil then
            v27 = true
        else
            v30 = true
        end
    end

    v28 = false

    if v27 then
        v37 = true
        v29 = true
    end

    v27 = false

    if v30 then
        v37 = false
        v29 = true
    end

    v30 = false

    local v38, v39

    if v29 then
        v38 = string.sub(p15, 1, 1)

        if v38 == "/" then
            v39 = true
            v27 = true
        else
            v30 = true
        end
    end

    v29 = false

    if v30 then
        if v38 == "\\" then
            v39 = true
            v27 = true
        else
            v29 = true
        end
    end

    v30 = false

    if v29 then
        if string.match(p15, "^%a:") ~= nil then
            v30 = true
        else
            v28 = true
        end
    end

    if v30 then
        v39 = true
        v27 = true
    end

    v30 = false

    if v28 then
        v39 = false
        v27 = true
    end

    v28 = false

    if v27 then
        if v37 == v39 then
            v30 = true
        else
            v28 = true
        end
    end

    if v28 then
        v35 = false
        v31 = false
    end

    if v30 then
        v35 = true
        v31 = false
    end

    local v32

    if not v31 then
        if v35 then
            for v40, v41 in ipairs(v33) do
                if v34[v40] ~= v41 then
                    v35 = false
                    break
                end
            end
        end

        if not v35 then
            error("Map is outside this installation; default map unchanged", 0)
        end

        local t6 = {}

        for i = #v33 + 1, #v34 do
            table.insert(t6, v34[i])
        end

        v32 = table.concat(t6, "/")
    end

    local v43

    if v26 == "" then
        v43 = "settings"
    else
        local v44 = string.sub(v26, -1)

        v43 = if v44 == "/" or v44 == "\\" then v26 .. "settings" else v26 .. "/" .. "settings"
    end

    local v45 = if v32 == nil then "null" else HttpService:JSONEncode(v32)
    local v46

    if v43 == "" then
        v46 = "default-map.json"
    else
        local v47 = string.sub(v43, -1)

        v46 = if v47 == "/" or v47 == "\\" then v43 .. "default-map.json" else v43 .. "/" .. "default-map.json"
    end

    return v46, v45
end

return t1
