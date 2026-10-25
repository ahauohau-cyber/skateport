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

require(sim.import)

local t1 = {
    Hud = {},
    Texture = {},
    Primitive = {},
    Vertex = {},
    MarkerHudRoot = {}
}

local function path_join(p2, p3) -- line: 38
    if p2 == nil or tostring(p2) == "" then
        return p3
    end

    local v1 = tostring(p2)
    local v2 = string.sub(v1, -1)

    if v2 == "/" or v2 == "\\" then
        return v1 .. p3
    end

    return v1 .. "/" .. p3
end

function t1.overlay_path(p4) -- line: 52
    if p4 == nil or tostring(p4) == "" then
        return "private/session-marker"
    end

    local v3 = tostring(p4)
    local v4 = string.sub(v3, -1)

    if v4 == "/" or v4 == "\\" then
        return v3 .. "private/session-marker"
    end

    return v3 .. "/" .. "private/session-marker"
end

function t1.load(p5, p6) -- line: 65
    if p5.version ~= 1 or p5.canvas[1] ~= 1280 or p5.canvas[2] ~= 720 then
        return "Unsupported original HUD manifest"
    end

    local n1 = 0

    for v5, v6 in p5.textures do
        if v6.file == "" or string.find(v6.file, "[/\\]") ~= nil or v6.width == 0 or v6.height == 0 then
            return "Invalid marker texture descriptor"
        end

        local v7 = p6[v5]

        if v7 == nil then
            return (("Missing marker texture %*"):format(v6.file))
        end

        if v7 ~= v6.width * v6.height * 4 then
            return "Invalid marker texture length"
        end

        n1 += 1
    end

    for _, v8 in p5.meshes do
        local v9 = #v8.vertices % 3 ~= 0 or v8.texture ~= nil and n1 <= v8.texture

        if not v9 then
            for _, v10 in v8.vertices do
                local v11 = v10.position[1]

                if v11 ~= v11 or v11 == 1e999 or v11 == (-1e999) then
                    v9 = true
                    break
                end

                local v12 = v10.position[2]

                if v12 ~= v12 or v12 == 1e999 or v12 == (-1e999) then
                    v9 = true
                    break
                end

                local v13 = v10.uv[1]

                if v13 ~= v13 or v13 == 1e999 or v13 == (-1e999) then
                    v9 = true
                    break
                end

                local v14 = v10.uv[2]

                if v14 ~= v14 or v14 == 1e999 or v14 == (-1e999) then
                    v9 = true
                    break
                end
            end
        end

        if v9 then
            return "Invalid marker HUD geometry"
        end
    end

    return nil
end

function t1.present(p7, p8) -- line: 120
    -- upvalues: rt (copy)
    local v15 = rt.fmin(p8.width / 1280, p8.height / 720)

    return p7.visible, {
        -p8.width / 2,
        p8.height / 2,
        0
    }, v15
end

return t1
