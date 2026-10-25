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
local v1 = import("skate_game/apt_display")
local v2 = import("skate_game/apt_vm")
local v3 = import("skate_game/apt_text")
local DisplayList = v1.DisplayList
local Vm, Value = v2.Vm, v2.Value
local TextAssets, Font = v3.TextAssets, v3.Font
local v4 = table.freeze({})
local t1 = {}

local function sorted_keys(p2) -- line: 43
    local t2 = {}

    for v5 in p2 do
        table.insert(t2, v5)
    end

    table.sort(t2)

    return t2
end

local function number_value(p3) -- line: 52
    return {
        tag = "Number",
        p3
    }
end

t1.Frame = {}
t1.Character = {}
t1.Instance = {}
t1.Movie = {}

local Movie = t1.Movie

function t1.Movie.load(p4) -- line: 83
    -- upvalues: DisplayList (copy), TextAssets (copy), v4 (copy)
    local characters = p4.characters

    if type(characters) ~= "table" then
        error("invalid type: expected a sequence", 0)
    end

    local t3 = {}

    for _, v6 in characters do
        local v7 = DisplayList.default()
        local t4 = {}

        for _, v8 in v6.frames or v4 do
            for _, v9 in v8.controls do
                DisplayList.apply(v7, v9)
            end

            table.insert(t4, {
                depths = table.clone(v7.depths)
            })
        end

        t3[v6.id] = t4
    end

    local t6 = {}

    for _, v10 in characters do
        t6[v10.id] = v10
    end

    local actions = p4.actions

    if type(actions) ~= "table" then
        error("invalid type: expected a map", 0)
    end

    return {
        instance_count = 0,
        root = 18446744073709552000,
        characters = t6,
        instances = {},
        actions = actions,
        pending = {},
        text_assets = TextAssets.load(p4),
        states = t3
    }
end

function t1.Movie.initialize(p5, p6) -- line: 122
    -- upvalues: Vm (copy), Movie (copy)
    p5.root = Movie.create(p5, p6, 0, nil, 0)
    Vm.set(p6, p5.root, "_root", {
        tag = "Object",
        p5.root
    })

    local t7 = {}

    for v11 in p5.instances do
        table.insert(t7, v11)
    end

    table.sort(t7)

    for _, v12 in t7 do
        Vm.set(p6, v12, "_root", {
            tag = "Object",
            p5.root
        })
    end
end

function t1.Movie.create(p7, p8, p9, p10, p11) -- line: 132
    -- upvalues: Vm (copy), v4 (copy), Movie (copy)
    if p11 > 32 or p7.instance_count > 2048 then
        error("APT movie hierarchy limit", 0)
    end

    local v13 = p7.characters[p9]

    if v13 == nil then
        error("APT unknown character", 0)
    end

    local v14 = Vm.object(p8, {
        tag = "Native",
        (("movie:%*"):format(p9))
    })

    if p7.root ~= 18446744073709552000 then
        Vm.set(p8, v14, "_root", {
            tag = "Object",
            p7.root
        })
    end

    if p10 ~= nil then
        Vm.set(p8, v14, "_parent", {
            tag = "Object",
            p10
        })
    end

    Vm.set(p8, v14, "_x", {
        tag = "Number",
        0
    })
    Vm.set(p8, v14, "_y", {
        tag = "Number",
        0
    })
    Vm.set(p8, v14, "_visible", {
        tag = "Bool",
        true
    })
    Vm.set(p8, v14, "_alpha", {
        tag = "Number",
        100
    })

    local text = v13.text

    if text ~= nil then
        local v15 = if type(text) == "table" then text.initial_text else nil

        if type(v15) ~= "string" then
            v15 = ""
        end

        Vm.set(p8, v14, "text", {
            tag = "Text",
            v15
        })
    end

    local v16 = v13.frames or v4

    if p7.instances[v14] == nil then
        p7.instance_count += 1
    end

    p7.instances[v14] = {
        frame = 0,
        placement = nil,
        character = p9,
        playing = #v16 ~= 0,
        children = {}
    }
    Movie.text_changed(p7, p8, v14)

    if #v16 ~= 0 then
        Movie.seek(p7, p8, v14, 0, p11 + 1)
    end

    return v14
end

function t1.Movie.text_changed(p12, p13, p14) -- line: 178
    -- upvalues: Vm (copy), Value (copy), TextAssets (copy), Font (copy)
    local v17 = p12.instances[p14]

    if v17 == nil then
        return
    end

    local v18 = p12.characters[v17.character]
    local text = v18.text

    if text == nil then
        return
    end

    local v19 = TextAssets.localize(p12.text_assets, Value.text(Vm.get(p13, p14, "text")))

    Vm.set(p13, p14, "_displayText", {
        tag = "Text",
        v19
    })

    local font_id = if type(text) == "table" then text.font_id else nil

    if type(font_id) ~= "number" or font_id ~= math.floor(font_id) then
        error("Invalid text font id", 0)
    end

    local v20 = p12.text_assets.fonts[font_id]

    if v20 == nil then
        error("Missing original text font", 0)
    end

    local font_height = text.font_height

    if type(font_height) ~= "number" then
        error("Invalid text size", 0)
    end

    local v21 = Font.width(v20, v19, font_height)

    Vm.set(p13, p14, "textWidth", {
        tag = "Number",
        v21
    })

    local bounds = v18.bounds

    if bounds == nil then
        error("Missing text bounds", 0)
    end

    local v22 = Value.text(Vm.get(p13, p14, "autoSize"))

    if v22 ~= "left" and v22 ~= "right" and v22 ~= "center" then
        v21 = bounds[3] - bounds[1]
    end

    Vm.set(p13, p14, "_width", {
        tag = "Number",
        v21
    })
end

function t1.Movie.remove(p15, p16, p17) -- line: 219
    -- upvalues: Vm (copy), Movie (copy)
    local v23 = p15.instances[p17]

    if v23 ~= nil then
        p15.instances[p17] = nil
        p15.instance_count -= 1

        local t8 = {}

        for v24 in v23.children do
            table.insert(t8, v24)
        end

        table.sort(t8)

        for _, v25 in t8 do
            Movie.remove(p15, p16, v23.children[v25])
        end
    end

    local set = Vm.set
    local t9 = {
        tag = "Bool",
        false
    }

    pcall(set, p16, p17, "_visible", t9)
end

local function matrix_differs(p18, p19) -- line: 233
    if p18[1] == p19[1] and p18[2] == p19[2] and p18[3] == p19[3] and p18[4] == p19[4] and p18[5] == p19[5] then
        return p18[6] ~= p19[6]
    end

    return true
end

function t1.Movie.seek(p20, p21, p22, p23, p24) -- line: 243
    -- upvalues: Vm (copy), v4 (copy), Movie (copy), matrix_differs (copy)
    local v26 = p20.instances[p22]

    if v26 == nil then
        error("APT absent movie instance", 0)
    end

    local v27 = table.clone(v26)
    local v28 = p20.characters[v27.character]

    if v28 == nil then
        error("APT absent movie character", 0)
    end

    local v29 = v28.frames or v4

    if #v29 <= p23 then
        error(("APT frame %* outside character %*"):format(p23, v28.id), 0)
    end

    local v30 = #v29
    local t10 = {}

    for _, v31 in v29[p23 + 1].controls do
        local v32 = v31.actions_offset or 0

        if v31.type_name == "do_action" and v32 ~= 0 then
            table.insert(t10, v32)
        end
    end

    local v33 = p20.states[v27.character][p23 + 1]
    local t11 = {}
    local t12 = {}

    for v34 in v33.depths do
        table.insert(t12, v34)
    end

    table.sort(t12)

    for _, v35 in t12 do
        local v36 = v33.depths[v35]
        local v37 = v27.children[v35]

        if v37 ~= nil then
            local v38 = p20.instances[v37]

            if v38 ~= nil and v38.placement ~= nil then
                local name = v38.placement.name

                if #name ~= 0 and name ~= v36.name then
                    p21.objects[p22 + 1].fields[name] = nil
                end
            end
        end

        if v37 == nil or p20.instances[v37] == nil or p20.instances[v37].character ~= v36.character then
            if v37 ~= nil then
                Movie.remove(p20, p21, v37)
            end

            v37 = Movie.create(p20, p21, v36.character, p22, p24 + 1)
        end

        local placement = p20.instances[v37].placement

        if placement == nil or matrix_differs(placement.matrix, v36.matrix) then
            Vm.set(p21, v37, "_x", {
                tag = "Number",
                v36.matrix[5]
            })
            Vm.set(p21, v37, "_y", {
                tag = "Number",
                v36.matrix[6]
            })
        end

        if #v36.name ~= 0 then
            Vm.set(p21, p22, v36.name, {
                tag = "Object",
                v37
            })
        end

        p20.instances[v37].placement = v36
        t11[v35] = v37
    end

    local t13 = {}

    for v39 in v27.children do
        table.insert(t13, v39)
    end

    table.sort(t13)

    for _, v40 in t13 do
        local v41 = v27.children[v40]

        if t11[v40] == nil then
            local v42 = p20.instances[v41]

            if v42 ~= nil and v42.placement ~= nil then
                local name = v42.placement.name

                if #name ~= 0 then
                    p21.objects[p22 + 1].fields[name] = nil
                end
            end

            Movie.remove(p20, p21, v41)
        end
    end

    local v43 = p20.instances[p22]

    if v43 == nil then
        error("called `Option::unwrap()` on a `None` value", 0)
    end

    v43.frame = p23
    v43.children = t11
    Vm.set(p21, p22, "_currentframe", {
        tag = "Number",
        p23 + 1
    })
    Vm.set(p21, p22, "_totalframes", {
        tag = "Number",
        v30
    })

    for _, v44 in t10 do
        table.insert(p20.pending, {
            p22,
            v44
        })
    end
end

local t15 = {}
local t16 = {}
local v45 = false

local function advance_seeks(p25, p26, p27, p28) -- line: 340
    -- upvalues: v4 (copy), Movie (copy)
    for i = 1, p28, 3 do
        local v46 = p27[i]
        local v47 = p27[i + 1]
        local v48 = p27[i + 2]

        if p25.instances[v46] ~= nil then
            local v49 = #(p25.characters[v47].frames or v4)

            if v49 > 1 then
                Movie.seek(p25, p26, v46, (v48 + 1) % v49, 0)
            end
        end
    end
end

function t1.Movie.advance(p29, p30) -- line: 352
    -- upvalues: Movie (copy), t15 (copy), t16 (copy), v45 (ref), advance_seeks (copy)
    if v45 then
        return Movie.advance_reference(p29, p30)
    end

    local instances = p29.instances

    table.clear(t15)

    local n1 = 0

    for v50 in instances do
        n1 += 1
        t15[n1] = v50
    end

    table.sort(t15)

    local n2 = 0

    for i = 1, n1 do
        local v51 = t15[i]
        local v52 = instances[v51]

        if v52.playing then
            local v53 = n2 + 1
            local v54 = n2 + 2
            local v55 = n2 + 3
            local character, frame = v52.character, v52.frame

            t16[v53] = v51
            t16[v54] = character
            t16[v55] = frame
            n2 += 3
        end
    end

    v45 = true

    local ok, result = pcall(advance_seeks, p29, p30, t16, n2)

    v45 = false

    if not ok then
        error(result, 0)
    end
end

function t1.Movie.advance_reference(p31, p32) -- line: 384
    -- upvalues: v4 (copy), Movie (copy)
    local t17 = {}
    local t18 = {}

    for v56 in p31.instances do
        table.insert(t18, v56)
    end

    table.sort(t18)

    for _, v57 in t18 do
        local v58 = p31.instances[v57]

        if v58.playing then
            table.insert(t17, {
                v57,
                v58.character,
                v58.frame
            })
        end
    end

    for _, v59 in t17 do
        local v60 = v59[1]
        local v61 = v59[2]
        local v62 = v59[3]

        if p31.instances[v60] ~= nil then
            local v63 = #(p31.characters[v61].frames or v4)

            if v63 > 1 then
                Movie.seek(p31, p32, v60, (v62 + 1) % v63, 0)
            end
        end
    end
end

function t1.Movie.method(p33, p34, p35, p36, p37) -- line: 405
    -- upvalues: rt (copy), Value (copy), v4 (copy), Movie (copy)
    local v64 = p33.instances[p35]

    if v64 == nil then
        return false
    end

    if p36 == "stop" then
        v64.playing = false
    elseif p36 == "play" then
        v64.playing = true
    else
        if p36 ~= "gotoAndPlay" and p36 ~= "gotoAndStop" then
            return false
        end

        local v65 = p33.characters[v64.character]
        local v66 = p37[1]

        if v66 == nil then
            error("APT goto requires frame", 0)
        end

        local v67

        if v66.tag == "Text" then
            local v68 = v66[1]
            local v69

            for v70, v71 in v65.frames or v4 do
                for _, v72 in v71.controls do
                    if v72.type_name == "frame_label" and v72.label == v68 then
                        v69 = v70 - 1
                        break
                    end
                end

                if v69 ~= nil then
                    v67 = v69
                    break
                end

                v67 = v69
            end

            if v67 == nil then
                error(("APT character %* lacks label %*"):format(v65.id, v68), 0)
            end
        else
            local v73 = Value.number(v66)

            if not (v73 == v73 and v73 ~= 1e999 and v73 ~= (-1e999)) or v73 < 0 then
                error(("Invalid APT frame %* in %* on character %*"):format(v73, p36, v65.id), 0)
            end

            v67 = math.max(rt.f_to_usize(v73) - 1, 0)
        end

        Movie.seek(p33, p34, p35, v67, 0)

        local v75 = p33.instances[p35]

        if v75 == nil then
            error("called `Option::unwrap()` on a `None` value", 0)
        end

        v75.playing = p36 == "gotoAndPlay"
    end

    return true
end

return t1
