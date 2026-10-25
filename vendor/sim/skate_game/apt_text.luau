-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)
require(sim.import)

local t1 = {}

local function jget(p1, p2) -- line: 14
    return if type(p1) == "table" then p1[p2] else nil
end

local function as_u64(p3) -- line: 22
    return if type(p3) == "number" and p3 >= 0 and p3 == math.floor(p3) then p3 else nil
end

local function as_i64(p4) -- line: 28
    return if type(p4) == "number" and p4 == math.floor(p4) then p4 else nil
end

t1.Glyph = {}
t1.Font = {}
t1.TextAssets = {}

function t1.TextAssets.default() -- line: 56
    return {
        fonts = {},
        language = {}
    }
end

local function glyphs_from_value(p5) -- line: 61
    if type(p5) ~= "table" then
        error("invalid type: expected a sequence", 0)
    end

    local v1 = table.create(#p5)

    for v2, v3 in p5 do
        if type(v3) ~= "table" then
            error("invalid type: expected struct Glyph", 0)
        end

        for _, v4 in { "glyph_index", "width", "height", "x_offset", "y_offset", "x_advance" } do
            if type(v3[v4]) ~= "number" then
                error("missing field `" .. v4 .. "`", 0)
            end
        end

        local atlas_bounds = v3.atlas_bounds

        if type(atlas_bounds) ~= "table" or #atlas_bounds ~= 4 then
            error("missing field `atlas_bounds`", 0)
        end

        v1[v2] = {
            glyph_index = v3.glyph_index,
            width = v3.width,
            height = v3.height,
            x_offset = v3.x_offset,
            y_offset = v3.y_offset,
            x_advance = v3.x_advance,
            atlas_bounds = {
                atlas_bounds[1],
                atlas_bounds[2],
                atlas_bounds[3],
                atlas_bounds[4]
            }
        }
    end

    return v1
end

function t1.TextAssets.load(p6) -- line: 93
    -- upvalues: t1 (copy), glyphs_from_value (copy)
    local v6 = t1.TextAssets.default()
    local language = if type(p6) == "table" then p6.language else nil

    if type(language) ~= "table" then
        error("invalid type: expected a map", 0)
    end

    v6.language = language

    local characters = if type(p6) == "table" then p6.characters else nil

    if type(characters) ~= "table" then
        error("HUD characters missing", 0)
    end

    for _, v7 in characters do
        if (if type(v7) == "table" then v7.type_name else nil) == "font" then
            local font = if type(v7) == "table" then v7.font else nil
            local name = if type(font) == "table" then font.name else nil

            if type(name) ~= "string" then
                error("HUD font name missing", 0)
            end

            local fonts = if type(p6) == "table" then p6.fonts else nil
            local v8 = if type(fonts) == "table" then fonts[name] else nil
            local definition = if type(v8) == "table" then v8.definition else nil
            local v9 = glyphs_from_value(if type(definition) == "table" then definition.glyphs else nil)
            local font_mappings = if type(p6) == "table" then p6.font_mappings else nil
            local v10 = if type(font_mappings) == "table" then font_mappings[name] else nil
            local native_layout = if type(v10) == "table" then v10.native_layout else nil

            local function f(p7) -- line: 116
                -- upvalues: name (copy), native_layout (copy)
                local v11 = if type(native_layout) == "table" then native_layout[p7] else nil

                if type(v11) ~= "number" then
                    error(("Missing native font %*.%*"):format(name, p7), 0)
                end

                return v11
            end

            local texture = if type(v8) == "table" then v8.texture else nil

            if type(texture) ~= "string" then
                error("Font texture missing", 0)
            end

            local textures = if type(definition) == "table" then definition.textures else nil
            local v12 = if type(textures) == "table" then textures[1] else nil
            local width = if type(v12) == "table" then v12.width else nil

            if type(width) ~= "number" or not (width >= 0) or width ~= math.floor(width) then
                width = nil
            end

            if width == nil then
                error("Font width missing", 0)
            end

            local height = if type(v12) == "table" then v12.height else nil

            if type(height) ~= "number" or not (height >= 0) or height ~= math.floor(height) then
                height = nil
            end

            if height == nil then
                error("Font height missing", 0)
            end

            local ScaleX = if type(native_layout) == "table" then native_layout.ScaleX else nil

            if type(ScaleX) ~= "number" then
                error(("Missing native font %*.ScaleX"):format(name), 0)
            end

            local ScaleY = if type(native_layout) == "table" then native_layout.ScaleY else nil

            if type(ScaleY) ~= "number" then
                error(("Missing native font %*.ScaleY"):format(name), 0)
            end

            local OffsetX = if type(native_layout) == "table" then native_layout.OffsetX else nil

            if type(OffsetX) ~= "number" then
                error(("Missing native font %*.OffsetX"):format(name), 0)
            end

            local OffsetY = if type(native_layout) == "table" then native_layout.OffsetY else nil

            if type(OffsetY) ~= "number" then
                error(("Missing native font %*.OffsetY"):format(name), 0)
            end

            local metrics = if type(definition) == "table" then definition.metrics else nil
            local Ascent = if type(metrics) == "table" then metrics.Ascent else nil

            if type(Ascent) ~= "number" then
                error("Font ascent missing", 0)
            end

            local t2 = {
                foreground = nil,
                texture = texture,
                size = { width, height },
                scale = { ScaleX, ScaleY },
                offset = { OffsetX, OffsetY },
                ascent = Ascent,
                glyphs = {}
            }
            local t3 = {}

            for _, v13 in v9 do
                if t3[v13.glyph_index] == nil then
                    t3[v13.glyph_index] = v13
                end
            end

            local characters = if type(definition) == "table" then definition.characters else nil

            if type(characters) ~= "table" then
                error("Font character map missing", 0)
            end

            for _, v14 in characters do
                local glyph_index = if type(v14) == "table" then v14.glyph_index else nil

                if type(glyph_index) ~= "number" or not (glyph_index >= 0) or glyph_index ~= math.floor(glyph_index) then
                    glyph_index = nil
                end

                if glyph_index == nil then
                    error("Invalid font glyph index", 0)
                end

                local v15 = t3[glyph_index]

                if v15 == nil then
                    error("Absent mapped glyph", 0)
                end

                local codepoint = if type(v14) == "table" then v14.codepoint else nil

                if type(codepoint) ~= "number" or not (codepoint >= 0) or codepoint ~= math.floor(codepoint) then
                    codepoint = nil
                end

                if codepoint == nil then
                    error("Invalid font codepoint", 0)
                end

                t2.glyphs[codepoint] = v15
            end

            local id = if type(v7) == "table" then v7.id else nil

            if type(id) ~= "number" or id ~= math.floor(id) then
                id = nil
            end

            if id == nil then
                error("Invalid font character id", 0)
            end

            v6.fonts[id] = t2
        end
    end

    for _, v16 in characters do
        if (if type(v16) == "table" then v16.type_name else nil) == "font" then
            local font = if type(v16) == "table" then v16.font else nil

            if (if type(font) == "table" then font.name else nil) == "Futura Shadow" then
                local id

                for _, v17 in characters do
                    if (if type(v17) == "table" then v17.type_name else nil) == "font" then
                        local font = if type(v17) == "table" then v17.font else nil
                        local v18 = if type(font) == "table" then font.name else nil

                        if type(v18) ~= "string" then
                            v18 = ""
                        end

                        local font_mappings = if type(p6) == "table" then p6.font_mappings else nil
                        local v19 = if type(font_mappings) == "table" then font_mappings[v18] else nil

                        if (if type(v19) == "table" then v19.file_name else nil) == "futuraheavy" then
                            id = if type(v17) == "table" then v17.id else nil

                            if type(id) ~= "number" or id ~= math.floor(id) then
                                id = nil
                            end

                            break
                        end
                    end

                    id = nil
                end

                if id == nil then
                    error("Missing native Futura Shadow foreground font", 0)
                end

                v6.fonts[if type(v16) == "table" then v16.id else nil].foreground = id
            end
        end
    end

    return v6
end

function t1.TextAssets.localize(p8, p9) -- line: 211
    if string.sub(p9, 1, 1) == "#" then
        return (string.sub(p9, 2))
    end

    local v20 = p8.language[p9]

    if v20 == nil then
        return p9
    end

    return v20
end

function t1.Font.glyph(p10, p11) -- line: 224
    local v21 = p10.glyphs[p11]

    if v21 == nil then
        return p10.glyphs[65535]
    end

    return v21
end

function t1.Font.width(p12, p13, p14) -- line: 233
    local glyphs = p12.glyphs
    local v22 = glyphs[65535]
    local v23 = p12.scale[1] * p14
    local n1 = 0

    for _, v24 in utf8.codes(p13) do
        local v25 = glyphs[v24] or v22

        if v25 ~= nil then
            n1 = v25.x_advance * v23 + n1
        end
    end

    return n1
end

return t1
