-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

local function rtl_is_finite(p1) -- line: 5
    if p1 ~= p1 or p1 == 1e999 then
        return false
    end

    return p1 ~= (-1e999)
end

local import = require(sim.import)
local v1 = import("skate_game/apt_vm")
local v2 = import("skate_game/apt_text")
local Vm, Value = v1.Vm, v1.Value
local Font = v2.Font
local t1 = {}

local function sorted_keys(p2) -- line: 71
    local t2 = {}

    for v3 in p2 do
        table.insert(t2, v3)
    end

    table.sort(t2)

    return t2
end

t1.Vertex = {}
t1.Texture = {}
t1.Shape = {}
t1.Shapes = {}

function t1.shapes_from_value(p3) -- line: 98
    if type(p3) ~= "table" then
        error("invalid type: expected a map", 0)
    end

    local t3 = {}

    for v4, v5 in p3 do
        local v6 = tonumber(v4)

        if v6 == nil or v6 ~= math.floor(v6) then
            error(("invalid value: expected i32, found \"%*\""):format(v4), 0)
        end

        t3[v6] = v5
    end

    return t3
end

t1.Draw = {}

function t1.compose(p4, p5) -- line: 117
    return {
        p4[1] * p5[1] + p4[3] * p5[2],
        p4[2] * p5[1] + p4[4] * p5[2],
        p4[1] * p5[3] + p4[3] * p5[4],
        p4[2] * p5[3] + p4[4] * p5[4],
        p4[1] * p5[5] + p4[3] * p5[6] + p4[5],
        p4[2] * p5[5] + p4[4] * p5[6] + p4[6]
    }
end

local compose2 = t1.compose

function t1.transform(p6, p7) -- line: 130
    return {
        position = {
            p6[1] * p7.position[1] + p6[3] * p7.position[2] + p6[5],
            p6[2] * p7.position[1] + p6[4] * p7.position[2] + p6[6]
        },
        uv = {
            p7.uv[1],
            p7.uv[2]
        }
    }
end

local transform2 = t1.transform

function t1.draw(p8, p9, p10) -- line: 142
    -- upvalues: t1 (copy)
    local t4 = {}

    t1.visit(p8, p9, p10, p8.root, { 1, 0, 0, 1, 0, 0 }, { 1, 1, 1, 1 }, { 0, 0, 0, 0 }, t4)

    return t4
end

local function node_state(p11, p12, p13, p14, p15, p16) -- line: 150
    -- upvalues: rt (copy), Vm (copy), Value (copy), compose2 (copy)
    if not Value.truth(Vm.get(p12, p13, "_visible")) then
        return nil
    end

    local v7 = p11.instances[p13]

    if v7 == nil then
        error("no entry found for key", 0)
    end

    local placement = v7.placement
    local v8 = if placement == nil then { 1, 0, 0, 1, 0, 0 } else rt.copy(placement.matrix)

    v8[5] = Value.number(Vm.get(p12, p13, "_x"))
    v8[6] = Value.number(Vm.get(p12, p13, "_y"))

    local v9 = compose2(p14, v8)

    for i = 1, 6 do
        local v10 = v9[i]

        if v10 ~= v10 or v10 == 1e999 or v10 == (-1e999) then
            error(("Nonfinite HUD transform on character %*"):format(v7.character), 0)
        end
    end

    local v11 = if placement == nil then { 255, 255, 255, 255, 0, 0, 0, 0 } else placement.color
    local t5 = {
        p15[1] * v11[2] / 255,
        p15[2] * v11[3] / 255,
        p15[3] * v11[4] / 255,
        p15[4] * v11[1] / 255
    }
    local t6 = {
        p16[1] + p15[1] * v11[6] / 255,
        p16[2] + p15[2] * v11[7] / 255,
        p16[3] + p15[3] * v11[8] / 255,
        p16[4] + p15[4] * v11[5] / 255
    }
    local v12 = rt.clamp(Value.number(Vm.get(p12, p13, "_alpha")) / 100, 0, 1)

    t5[4] *= v12
    t6[4] *= v12

    if not (t5[4] <= 0 and t6[4] <= 0) then
        return v7, v9, t5, t6
    end

    return nil
end

local function text_pass(p17, p18, p19, p20, p21, p22) -- line: 203
    -- upvalues: Vm (copy), Value (copy), Font (copy)
    local font_height = p20.font_height

    if type(font_height) ~= "number" then
        error("Invalid text height", 0)
    end

    local v13 = p21.scale[1] * font_height
    local v14 = p21.scale[2] * font_height
    local v15 = Value.text(Vm.get(p17, p18, "_displayText"))
    local bounds = p19.bounds

    if bounds == nil then
        error("Missing text bounds", 0)
    end

    local v16 = Font.width(p21, v15, font_height)
    local alignment = p20.alignment
    local v17, v18

    if type(alignment) ~= "number" or alignment < 0 then
        v18 = false
    elseif alignment == math.floor(alignment) then
        v17 = alignment
        v18 = true
    else
        v18 = false
    end

    if not v18 then
        v17 = 0
    end

    if Value.text(Vm.get(p17, p18, "autoSize")) == "left" then
        v17 = 0
    end

    local v19 = if v17 == 1 then bounds[3] - bounds[1] - v16 elseif v17 == 2 then (bounds[3] - bounds[1] - v16) * 0.5 else 0
    local v20 = bounds[1] + p22 + p21.offset[1] * v13 + v19
    local v21 = bounds[2] + p21.offset[2] * v14
    local color_argb = p20.color_argb

    if type(color_argb) ~= "string" then
        error("Missing text color", 0)
    end

    local v22 = string.gsub(color_argb, "^#+", "")
    local v23 = if string.match(v22, "^%x+$") == nil or not (#v22 <= 8) then nil else tonumber(v22, 16)

    if v23 == nil then
        error("invalid digit found in string", 0)
    end

    return v13, v14, v15, bounds, v16, v17, v20, v21, {
        bit32.band(bit32.rshift(v23, 16), 255) / 255,
        bit32.band(bit32.rshift(v23, 8), 255) / 255,
        bit32.band(v23, 255) / 255,
        bit32.rshift(v23, 24) / 255
    }
end

local function text_font(p23, p24) -- line: 254
    local font_id = p24.font_id

    if type(font_id) ~= "number" or font_id ~= math.floor(font_id) then
        error("Invalid text font", 0)
    end

    local v27 = p23.text_assets.fonts[font_id]

    if v27 == nil then
        error("no entry found for key", 0)
    end

    return v27, font_id
end

function t1.visit(p25, p26, p27, p28, p29, p30, p31, p32) -- line: 268
    -- upvalues: rt (copy), Font (copy), t1 (copy), transform2 (copy), node_state (copy), text_pass (copy)
    local v28, v29, v30, v31 = node_state(p25, p26, p28, p29, p30, p31)

    if v28 == nil then
        return
    end

    local v32 = p25.characters[v28.character]

    if v32.type_name == "shape" then
        local v33 = p27[v32.id]

        if v33 == nil then
            error("Missing original shape geometry", 0)
        end

        for _, v34 in v33 do
            local t7 = {}

            for _, v35 in v34.triangles do
                for _, v36 in v35 do
                    table.insert(t7, transform2(v29, v36))
                end
            end

            table.insert(p32, {
                texture = v34.texture.rgba,
                vertices = t7,
                multiply = {
                    v30[1] * v34.color[1],
                    v30[2] * v34.color[2],
                    v30[3] * v34.color[3],
                    v30[4] * v34.color[4]
                },
                add = rt.copy(v31)
            })
        end
    elseif v32.text ~= nil then
        local text = v32.text
        local font_id = text.font_id

        if type(font_id) ~= "number" or font_id ~= math.floor(font_id) then
            error("Invalid text font", 0)
        end

        local v37 = p25.text_assets.fonts[font_id]

        if v37 == nil then
            error("no entry found for key", 0)
        end

        local t9

        if v37.foreground ~= nil then
            local v38 = p25.text_assets.fonts[v37.foreground]

            if v38 == nil then
                error("no entry found for key", 0)
            end

            t9 = {
                { v37, true, 0 },
                { v38, false, 1 }
            }
        else
            t9 = { { v37, false, 0 } }
        end

        for _, v39 in t9 do
            local v40 = v39[1]
            local v41 = v39[2]
            local v43, v44, v45, _, _, _, v46, v47, v48 = text_pass(p26, p28, v32, text, v40, v39[3])
            local t10 = {}

            for _, v49 in utf8.codes(v45) do
                local v50 = Font.glyph(v40, v49)

                if v50 ~= nil then
                    local v51 = v46 + v50.x_offset * v43
                    local v52 = v47 + (v40.ascent - v50.y_offset) * v44
                    local v53 = v51 + v50.width * v43
                    local v54 = v52 + v50.height * v44
                    local v55 = v50.atlas_bounds[1]
                    local v56 = v50.atlas_bounds[2]
                    local v57 = v50.atlas_bounds[3]
                    local v58 = v50.atlas_bounds[4]
                    local t11 = {
                        { v51, v52 },
                        { v53, v52 },
                        { v53, v54 },
                        { v51, v54 }
                    }
                    local t12 = {
                        { v55, v56 },
                        { v57, v56 },
                        { v57, v58 },
                        { v55, v58 }
                    }

                    for _, v59 in { 0, 1, 2, 0, 2, 3 } do
                        table.insert(t10, transform2(v29, {
                            position = t11[v59 + 1],
                            uv = {
                                t12[v59 + 1][1] / v40.size[1],
                                t12[v59 + 1][2] / v40.size[2]
                            }
                        }))
                    end

                    v46 = v50.x_advance * v43 + v46
                end
            end

            if #t10 ~= 0 then
                local t14 = {}

                if v41 then
                    t14[1] = 0
                    t14[2] = 0
                    t14[3] = 0
                else
                    t14[1] = v30[1] * v48[1]
                    t14[2] = v30[2] * v48[2]
                    t14[3] = v30[3] * v48[3]
                end

                t14[4] = v30[4] * v48[4]
                table.insert(p32, {
                    texture = v40.texture,
                    vertices = t10,
                    multiply = t14,
                    add = rt.copy(v31)
                })
            end
        end
    end

    local t16 = {}

    for v60 in v28.children do
        table.insert(t16, v60)
    end

    table.sort(t16)

    for _, v61 in t16 do
        t1.visit(p25, p26, p27, v28.children[v61], v29, v30, v31, p32)
    end
end

local self = setmetatable({}, {
    __mode = "k"
})

local function shape_box(p33) -- line: 372
    -- upvalues: self (copy)
    local v63 = self[p33]

    if v63 == nil then
        local n1 = 1e999
        local n2 = 1e999
        local n3 = (-1e999)
        local n4 = (-1e999)

        for _, v64 in p33.triangles do
            for _, v69 in v64 do
                n1 = math.min(n1, v69.position[1])
                n2 = math.min(n2, v69.position[2])
                n3 = math.max(n3, v69.position[1])
                n4 = math.max(n4, v69.position[2])
            end
        end

        local n5 = 0
        local n6 = 0
        local n7 = 1
        local n8 = 1

        for _, v74 in p33.triangles do
            for _, v79 in v74 do
                if v79.position[1] == n1 then
                    n5 = v79.uv[1]
                end

                if v79.position[1] == n3 then
                    n7 = v79.uv[1]
                end

                if v79.position[2] == n2 then
                    n6 = v79.uv[2]
                end

                if v79.position[2] == n4 then
                    n8 = v79.uv[2]
                end
            end
        end

        if n3 < n1 then
            n1 = 0
            n2 = 0
            n3 = 0
            n4 = 0
        end

        v63 = {
            bounds = { n1, n2, n3, n4 },
            uv = { n5, n6, n7, n8 }
        }
        self[p33] = v63
    end

    return v63
end

local function visit_list(p34, p35, p36, p37, p38, p39, p40, p41) -- line: 410
    -- upvalues: rt (copy), Font (copy), node_state (copy), text_pass (copy), shape_box (copy), visit_list (copy)
    local v80, v81, v82, v83 = node_state(p34, p35, p37, p38, p39, p40)

    if v80 == nil then
        return
    end

    local v84 = p34.characters[v80.character]

    if v84.type_name == "shape" then
        local v85 = p36[v84.id]

        if v85 == nil then
            error("Missing original shape geometry", 0)
        end

        for v86, v87 in v85 do
            local v88 = shape_box(v87)
            local rgba = v87.texture.rgba

            table.insert(p41, {
                kind = rgba == "" and "shape" or "sprite",
                order = #p41 + 1,
                instance = p37,
                character = v84.id,
                matrix = rt.copy(v81),
                bounds = rt.copy(v88.bounds),
                multiply = {
                    v82[1] * v87.color[1],
                    v82[2] * v87.color[2],
                    v82[3] * v87.color[3],
                    v82[4] * v87.color[4]
                },
                add = rt.copy(v83),
                part = v86 - 1,
                texture = rgba,
                texture_width = v87.texture.width,
                texture_height = v87.texture.height,
                uv = rt.copy(v88.uv),
                triangles = v87.triangles
            })
        end
    elseif v84.text ~= nil then
        local text = v84.text
        local font_id = text.font_id

        if type(font_id) ~= "number" or font_id ~= math.floor(font_id) then
            error("Invalid text font", 0)
        end

        local v89 = p34.text_assets.fonts[font_id]

        if v89 == nil then
            error("no entry found for key", 0)
        end

        local t20

        if v89.foreground ~= nil then
            local v90 = p34.text_assets.fonts[v89.foreground]

            if v90 == nil then
                error("no entry found for key", 0)
            end

            t20 = {
                { v89, true, 0, font_id },
                {
                    v90,
                    false,
                    1,
                    v89.foreground
                }
            }
        else
            t20 = { { v89, false, 0, font_id } }
        end

        for v91, v92 in t20 do
            local v93 = v92[1]
            local v94 = v92[2]
            local v95 = v92[3]
            local v96 = v92[4]
            local v97, v98, v99, v100, v101, v102, v103, v104, v105 = text_pass(p35, p37, v84, text, v93, v95)
            local v106 = false

            for _, v107 in utf8.codes(v99) do
                if Font.glyph(v93, v107) ~= nil then
                    v106 = true
                    break
                end
            end

            if v106 then
                local t21 = {}

                if v94 then
                    t21[1] = 0
                    t21[2] = 0
                    t21[3] = 0
                else
                    t21[1] = v82[1] * v105[1]
                    t21[2] = v82[2] * v105[2]
                    t21[3] = v82[3] * v105[3]
                end

                t21[4] = v82[4] * v105[4]
                table.insert(p41, {
                    kind = "text",
                    order = #p41 + 1,
                    instance = p37,
                    character = v84.id,
                    matrix = rt.copy(v81),
                    bounds = rt.copy(v100),
                    multiply = t21,
                    add = rt.copy(v83),
                    text = v99,
                    font = v96,
                    texture = v93.texture,
                    pass = v91 - 1,
                    shadow = v94,
                    font_height = text.font_height,
                    scale = { v97, v98 },
                    alignment = v102,
                    x = v103,
                    y = v104,
                    width = v101,
                    ascent = v93.ascent * v98,
                    color = v105
                })
            end
        end
    end

    local t23 = {}

    for v108 in v80.children do
        table.insert(t23, v108)
    end

    table.sort(t23)

    for _, v109 in t23 do
        visit_list(p34, p35, p36, v80.children[v109], v81, v82, v83, p41)
    end
end

function t1.display_list(p42, p43, p44) -- line: 512
    -- upvalues: visit_list (copy)
    local t24 = {}

    visit_list(p42, p43, p44, p42.root, { 1, 0, 0, 1, 0, 0 }, { 1, 1, 1, 1 }, { 0, 0, 0, 0 }, t24)

    return t24
end

return t1
