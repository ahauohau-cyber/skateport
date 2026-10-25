-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_subnormal_mantissa(p1) -- line: 6
    local v2 = p1 * 7.1362384635298E+44
    local v3 = math.floor(v2)
    local v4 = v2 - v3

    if v4 > 0.5 or v4 == 0.5 and v3 % 2 == 1 then
        return v3 + 1
    end

    return v3
end

local function rtl_fround(p2) -- line: 15
    -- upvalues: v1 (copy)
    if p2 ~= 0 and p2 > -1.1754943508222875E-38 and p2 < 1.1754943508222875E-38 then
        local v6 = math.abs(p2) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        local v8 = v5 * 1.401298464324817E-45

        if p2 < 0 then
            return -v8
        end

        return v8
    end

    buffer.writef32(v1, 0, p2)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local v9 = import("skate_game/customiser_parts")
local v10 = import("skate_game/custom_models")
local encode = import("skate_core/animation/skeleton_input/name").encode
local PendingPosture = import("skate_core/animation/posture").PendingPosture
local Parts, Part, Material, json = v9.Parts, v9.Part, v9.Material, v9.json
local NULL = json.NULL

local function physics_mod() -- line: 41
    -- upvalues: import (copy)
    return import("skate_game/physics")
end

local function skater_animation_mod() -- line: 44
    -- upvalues: import (copy)
    return import("skate_game/skater_animation")
end

local t1 = {
    Entry = {}
}

function t1.Entry.default() -- line: 55
    return {
        label = "",
        patch = nil,
        scalar = nil,
        note = nil,
        gender = nil,
        children = {},
        options = {}
    }
end

function t1.Entry.from_value(p3) -- line: 60
    -- upvalues: t1 (copy)
    local v11 = t1.Entry.default()

    v11.label = p3.label

    for _, v12 in p3.children or {} do
        table.insert(v11.children, t1.Entry.from_value(v12))
    end

    for _, v13 in p3.options or {} do
        table.insert(v11.options, t1.Entry.from_value(v13))
    end

    v11.patch = p3.patch
    v11.scalar = p3.scalar
    v11.note = p3.note
    v11.gender = p3.gender
    v11.minimum = p3.minimum
    v11.maximum = p3.maximum
    v11.initial = p3.initial
    v11.step = p3.step

    return v11
end

t1.Navigation = {}

function t1.Navigation.default() -- line: 84
    return {
        pressed = 0,
        preview_turn = 0,
        previous = 0,
        held_for = 0,
        repeat_at = 0
    }
end

t1.Customiser = {}

local Customiser = t1.Customiser

function t1.Customiser.begin(p4) -- line: 96
    p4.open = true
    p4.enabled = true
    p4.just_opened = true
    p4.preview_yaw = 0
    table.clear(p4.path)
    p4.search = ""
    p4.selected = 0
    p4.status = ""
    p4.redraw = true
end

function t1.Customiser.page(p5) -- line: 109
    local v14 = p5.index

    for _, v15 in p5.path do
        v14 = v14.children[v15 + 1]
    end

    return v14
end

function t1.Customiser.visible(p6) -- line: 118
    -- upvalues: json (copy), Customiser (copy)
    local v16 = json.as_str(json.index(p6.draft, "gender")) or "male"
    local t2 = {}
    local v17 = string.lower(p6.search)

    for v18, v19 in Customiser.page(p6).children do
        local v20 = v18 - 1

        if (v19.gender == nil or v19.gender == v16 or v19.gender == "unisex") and (p6.search == "" or string.find(string.lower(v19.label), v17, 1, true) ~= nil) then
            table.insert(t2, v20)
        end
    end

    return t2
end

function t1.Customiser.preview_camera(p7) -- line: 136
    -- upvalues: Customiser (copy)
    local v21, v22, v23 = Customiser.preview_framing(p7)

    return v21, v22, v23 + p7.preview_yaw
end

local function contains(p8, p9) -- line: 141
    for _, v24 in p8 do
        if v24 == p9 then
            return true
        end
    end

    return false
end

function t1.Customiser.preview_framing(p10) -- line: 151
    -- upvalues: json (copy)
    local t3 = {}
    local v25 = p10.index

    for _, v26 in p10.path do
        v25 = v25.children[v26 + 1]
        table.insert(t3, v25.label)
    end

    local v27 = false
    local v28

    for _, v29 in t3 do
        if v29 == "Upper body" then
            v28 = true
            v27 = true
            break
        end
    end

    if not v27 then
        v28 = false
    end

    if not v28 then
        local v30 = false
        local v31

        for _, v32 in t3 do
            if v32 == "Lower body" then
                v31 = true
                v30 = true
                break
            end
        end

        if not v30 then
            v31 = false
        end

        if not v31 then
            for _, v33 in t3 do
                local v34 = false
                local v35

                for _, v36 in { "Face", "Face presets", "Hair", "Hair colour", "Facial hair", "Skin tone" } do
                    if v36 == v33 then
                        v35 = true
                        v34 = true
                        break
                    end
                end

                if not v34 then
                    v35 = false
                end

                if v35 then
                    return 1.48, 1.65, 0
                end
            end

            local v37 = false
            local v38

            for _, v39 in t3 do
                if v39 == "Board" then
                    v38 = true
                    v37 = true
                    break
                end
            end

            if not v37 then
                v38 = false
            end

            if v38 then
                return 0.25, 2, 0.6
            end

            return 0.95, 3.2, 0
        end
    end

    local v40 = false
    local v41

    for _, v42 in t3 do
        if v42 == "Upper body" then
            v41 = true
            v40 = true
            break
        end
    end

    if not v40 then
        v41 = false
    end

    local v43 = json.as_u64(json.index(json.index(json.index(p10.draft, "tattoos"), if v41 then "Arm" else "Leg"), "side")) or 0
    local v44 = if v43 == 0 then -0.65
        elseif v43 == 1 then 0.65
        elseif v43 == 3 then 3.141592653589793
        else 0

    return if v41 then 1.15 else 0.5, 2.2, v44
end

function t1.Customiser.preview(p11, p12) -- line: 187
    -- upvalues: rt (copy), Parts (copy), Part (copy), json (copy)
    local v45 = rt.copy(p11.draft)

    if p11.open then
        local v46 = p11.index
        local v48 = false
        local v47

        for _, v49 in p11.path do
            v46 = v46.children[v49 + 1]

            if v46.label == "Tattoos" then
                v48 = true
            end

            if v48 then
                if v46.label == "Upper body" then
                    v47 = "OuterTorso"
                end

                if v46.label == "Lower body" then
                    v47 = "Pants"
                end
            end
        end

        if v47 ~= nil then
            local v50 = json.as_str(json.index(v45, "gender")) or "male"
            local v51

            for v52, v53 in p12.library.models do
                local v54 = v53.slot == v47 and Part.flag(v53, "Gender") == v50 and (if v47 == "OuterTorso" then Part.flag(v53, "TopType") == "" else string.lower(Part.flag(v53, "IsTattooViewingChoice")) == "true")

                if v54 and (v51 == nil or v52 < v51) then
                    v51 = v52
                end
            end

            if v51 ~= nil then
                local v55 = p12.library.models[v51]

                if not json.is_object(v45.selections) then
                    v45.selections = {}
                end

                v45.selections[v47] = {
                    asset_id = v51,
                    material_id = v55.materials[1]
                }

                local resolve = Parts.resolve
                local ok, result = pcall(resolve, p12, v45)

                if ok then
                    return result
                end
            end
        end
    end

    return v45
end

function t1.Customiser.preload_entries(p13) -- line: 242
    -- upvalues: rt (copy), t1 (copy), Customiser (copy)
    if not p13.open then
        return {}
    end

    local v56 = Customiser.visible(p13)
    local v57 = rt.idiv(p13.selected, p13.page_size) * p13.page_size
    local t4 = {}
    local children = Customiser.page(p13).children

    for i = v57, math.min(v57 + p13.page_size, #v56) - 1 do
        local v60 = children[v56[i + 1] + 1]
        local v61 = t1.option_index(v60, p13.draft) or 0

        for v62, v63 in v60.options do
            local v64 = v62 - 1

            if v64 < 4 or math.abs(v64 - v61) <= 2 then
                table.insert(t4, v63)
            end
        end

        table.insert(t4, v60)
    end

    return t4
end

function t1.Customiser.preload_outfits(p14, p15) -- line: 265
    -- upvalues: rt (copy), Parts (copy), json (copy), t1 (copy), Customiser (copy)
    local t5 = {}

    for _, v66 in Customiser.preload_entries(p14) do
        local patch = v66.patch

        if patch ~= nil then
            local v67 = rt.copy(p14.draft)
            local v68 = json.as_str(json.index(patch, "gender"))

            if v68 ~= nil then
                local v70 = p15.library.defaults[v68]

                if v70 ~= nil then
                    local v71 = rt.copy(v70)
                    local resolve = Parts.resolve
                    local ok, result = pcall(resolve, p15, v71)

                    if ok then
                        table.insert(t5, result)
                    end
                end
            else
                local v69 = t1.merge(v67, patch)
                local Hair = json.get(json.index(patch, "selections"), "Hair")

                if Hair ~= nil then
                    v69.hair_choice = rt.copy(Hair)
                end

                local resolve = Parts.resolve
                local ok, result = pcall(resolve, p15, v69)

                if ok then
                    table.insert(t5, result)
                end
            end
        end
    end

    return t5
end

t1.BACK = -1
t1.NEXT = -2
t1.PREV = -3
t1.RESET = -4

function t1.navigation(p16, p17, p18, p19) -- line: 315
    -- upvalues: rt (copy)
    local v72 = if p19 == nil then 0 else rt.clamp(p19.state.right[1] / 32767, -1, 1)

    p16.preview_turn = rt.signum(v72) * rt.fmax((math.abs(v72) - 0.24) / 0.76, 0)

    local v73 = 0

    if p19 ~= nil then
        local v74 = if p19.state.left[2] > 16000 then 1 elseif p19.state.left[2] < -16000 then 2 else 0
        local v75 = if p19.state.left[1] > 16000 then 8 elseif p19.state.left[1] < -16000 then 4 else 0

        v73 = bit32.bor(p19.state.buttons, v74, v75)
    end

    for _, v76 in {
            { "ArrowUp", 1 },
            { "ArrowDown", 2 },
            { "ArrowLeft", 4 },
            { "ArrowRight", 8 }
        } do
        if p18.pressed(p18, v76[1]) then
            v73 = bit32.bor(v73, v76[2])
        end
    end

    p16.pressed = bit32.band(v73, bit32.bnot(p16.previous), 65535)

    local v79 = bit32.band(v73, 15) == 0
    local v80 = if not v79 then bit32.band(v73, 15) == bit32.band(p16.previous, 15) else nil

    if v79 or not v80 then
        p16.held_for = 0
        p16.repeat_at = 0.35
    else
        p16.held_for += p17

        if p16.held_for >= p16.repeat_at then
            p16.pressed = bit32.bor(p16.pressed, (bit32.band(v73, 15)))
            p16.repeat_at += 0.09
        end
    end

    p16.previous = v73
end

function t1.rotate_preview(p20, p21, p22) -- line: 345
    -- upvalues: rt (copy)
    if p20.open and p21.preview_turn ~= 0 then
        p20.preview_yaw = rt.rem_euclid(p20.preview_yaw + p21.preview_turn * 2 * math.min(p22, 0.1), 6.283185307179586)
    end
end

function t1.page(p23, p24) -- line: 354
    -- upvalues: t1 (copy)
    local v83 = t1.Entry.default()

    v83.label = p23
    v83.children = p24

    return v83
end

function t1.choice(p25, p26) -- line: 362
    -- upvalues: t1 (copy)
    local v84 = t1.Entry.default()

    v84.label = p25
    v84.patch = p26

    return v84
end

function t1.tidy(p27) -- line: 370
    local t6 = {}

    for match in string.gmatch(p27, "%S+") do
        table.insert(t6, string.upper((string.sub(match, 1, 1))) .. string.sub(match, 2))
    end

    return table.concat(t6, " ")
end

local function sorted_keys(p28) -- line: 378
    local t7 = {}

    for v86 in p28 do
        table.insert(t7, v86)
    end

    table.sort(t7)

    return t7
end

local function ends_with(p29, p30) -- line: 387
    if #p29 >= #p30 then
        return string.sub(p29, #p29 - #p30 + 1) == p30
    end

    return false
end

function t1.menu(p31, p32) -- line: 394
    -- upvalues: rt (copy), Part (copy), Material (copy), NULL (copy), t1 (copy)
    local function model_page(p33, p34, p35) -- line: 395
        -- upvalues: p31 (copy), rt (copy), Part (copy), Material (copy), NULL (copy), t1 (copy)
        local t8 = {}
        local v88 = false
        local v89

        for _, v90 in { "Hat", "Hair", "Sock", "Glasses", "Jewellery", "WristItem", "Accessory" } do
            if v90 == p34 then
                v89 = true
                v88 = true
                break
            end
        end

        if not v88 then
            v89 = false
        end

        if v89 then
            table.insert(t8, t1.choice("None", {
                selections = {
                    [p34] = NULL
                }
            }))
        end

        local models = p31.models
        local t10 = {}

        for v91 in models do
            table.insert(t10, v91)
        end

        table.sort(t10)

        if p33 == "T-shirts" then
            for _, v92 in t10 do
                local v93 = p31.models[v92]

                if v93.slot == "OuterTorso" and Part.flag(v93, "TopType") == "" then
                    local v94 = t1.choice("No top", {
                        selections = {
                            OuterTorso = {
                                asset_id = v92,
                                material_id = v93.materials[1]
                            }
                        }
                    })

                    v94.gender = Part.flag(v93, "Gender")
                    table.insert(t8, v94)
                end
            end
        end

        local t11 = {}

        for _, v95 in t10 do
            local v96 = p31.models[v95]

            if v96.slot == p34 and (p34 ~= "Hair" or Part.flag(v96, "HairModelType") == "full") then
                if #p35 == 0 then
                    table.insert(t11, v95)
                else
                    local TopType = Part.flag(v96, "TopType")
                    local v100 = false
                    local v101

                    for _, v102 in p35 do
                        if v102 == TopType then
                            v101 = true
                            v100 = true
                            break
                        end
                    end

                    if not v100 then
                        v101 = false
                    end

                    if v101 then
                        table.insert(t11, v95)
                    end
                end
            end
        end

        table.sort(t11, function(p36, p37) -- line: 427
            -- upvalues: p31 (copy)
            local name = p31.models[p36].name
            local name2 = p31.models[p37].name

            if name == name2 then
                return p36 < p37
            end

            return name < name2
        end)

        for _, v103 in t11 do
            local v104 = p31.models[v103]
            local t12 = {}

            for _, v105 in v104.materials do
                local v106 = p31.materials[v105]

                if v106 ~= nil then
                    table.insert(t12, t1.choice(v106.name, {
                        selections = {
                            [p34] = {
                                asset_id = v103,
                                material_id = v105
                            }
                        },
                        colours = {
                            [p34] = NULL
                        }
                    }))

                    if string.lower(Material.flag(v106, "IsColourizable")) == "true" then
                        for _, v107 in p31.colours do
                            table.insert(t12, t1.choice(v107.name, {
                                selections = {
                                    [p34] = {
                                        asset_id = v103,
                                        material_id = v105
                                    }
                                },
                                colours = {
                                    [p34] = rt.copy(v107.rgb)
                                }
                            }))
                        end
                    end
                end
            end

            if #t12 ~= 0 then
                local Gender = Part.flag(v104, "Gender")
                local v108 = t1.Entry.default()

                if p34 == "Hair" then
                    v108.label = t1.tidy((string.gsub(Part.flag(v104, "HairStyle"), "moosed", "moussed")))
                else
                    v108.label = v104.name
                end

                v108.options = t12
                v108.gender = if Gender == "" then nil else Gender
                table.insert(t8, v108)
            end
        end

        local v109 = false
        local v110

        for _, v111 in { "SkateBoard", "SkateTruck", "SkateWheel" } do
            if v111 == p34 then
                v110 = true
                v109 = true
                break
            end
        end

        if not v109 then
            v110 = false
        end

        if v110 then
            local t15 = {}

            for _, v112 in t8 do
                for _, v113 in v112.options do
                    local v114 = v113.label

                    while true and #v114 >= 7 and string.sub(v114, #v114 - 7 + 1) == " (Worn)" do
                        v114 = string.sub(v114, 1, #v114 - 7)
                    end

                    local label = v113.label

                    v113.label = #label >= 7 and string.sub(label, #label - 7 + 1) == " (Worn)" and "Worn" or "New"

                    if t15[v114] == nil then
                        t15[v114] = {}
                    end

                    table.insert(t15[v114], v113)
                end
            end

            t8 = {}

            local t16 = {}

            for v120 in t15 do
                table.insert(t16, v120)
            end

            table.sort(t16)

            for _, v121 in t16 do
                local v122 = t1.Entry.default()

                v122.label = v121
                v122.options = t15[v121]
                table.insert(t8, v122)
            end
        end

        return t1.page(p33, t8)
    end

    local function morph(p38, p39) -- line: 502
        -- upvalues: t1 (copy)
        local v123 = t1.Entry.default()

        v123.label = p38
        v123.scalar = ("morphs.%*"):format(p39)
        v123.minimum = 0
        v123.maximum = 0.5
        v123.initial = (p39 == "fat" or p39 == "thin") and 0 or 0.25
        v123.step = 0.025

        return v123
    end

    local t17 = {}
    local t18 = {}

    for _, v124 in p31.materials do
        local FacialHairStyle = Material.flag(v124, "FacialHairStyle")

        if FacialHairStyle ~= "" then
            t18[FacialHairStyle] = true
        end
    end

    local t19 = {}

    for v125 in t18 do
        table.insert(t19, v125)
    end

    table.sort(t19)

    for _, v126 in t19 do
        local v127 = if v126 == "none" then "Clean shaven"
            elseif v126 == "billygoat" then "Long goatee"
            elseif v126 == "soulpatch" then "Soul patch"
            elseif v126 == "magnum" then "Thick moustache"
            else t1.tidy(v126)
        local v128 = t1.choice(v127, {
            beard = v126
        })

        v128.gender = "male"
        table.insert(t17, v128)
    end

    local page = t1.page
    local v129 = t1.page("Gender", {
        t1.choice("Male", {
            gender = "male"
        }),
        t1.choice("Female", {
            gender = "female"
        })
    })
    local v130 = t1.page("Skin tone", {
        t1.choice(t1.tidy("light"), {
            skin = "light"
        }),
        t1.choice(t1.tidy("dark"), {
            skin = "dark"
        })
    })
    local v131 = model_page("Hair", "Hair", {})
    local page2 = t1.page
    local v132 = t1.Entry.default()

    v132.label = "Weight"
    v132.scalar = "morphs.fat"
    v132.minimum = 0
    v132.maximum = 0.5
    v132.initial = 0
    v132.step = 0.025

    local v133 = t1.Entry.default()

    v133.label = "Definition"
    v133.scalar = "morphs.thin"
    v133.minimum = 0
    v133.maximum = 0.5
    v133.initial = 0
    v133.step = 0.025

    local v134 = page2("Build", { v132, v133 })
    local page3, page4 = t1.page, t1.page
    local v135 = t1.Entry.default()

    v135.label = "Depth"
    v135.scalar = "morphs.local_brows_depth"
    v135.minimum = 0
    v135.maximum = 0.5
    v135.initial = 0.25
    v135.step = 0.025

    local v136 = t1.Entry.default()

    v136.label = "Height"
    v136.scalar = "morphs.local_brows_height"
    v136.minimum = 0
    v136.maximum = 0.5
    v136.initial = 0.25
    v136.step = 0.025

    local v137 = t1.Entry.default()

    v137.label = "Angle"
    v137.scalar = "morphs.local_brows_rotation"
    v137.minimum = 0
    v137.maximum = 0.5
    v137.initial = 0.25
    v137.step = 0.025

    local v138 = page4("Brows", { v135, v136, v137 })
    local page5 = t1.page
    local v139 = t1.Entry.default()

    v139.label = "Height"
    v139.scalar = "morphs.local_eye_height"
    v139.minimum = 0
    v139.maximum = 0.5
    v139.initial = 0.25
    v139.step = 0.025

    local v140 = t1.Entry.default()

    v140.label = "Angle"
    v140.scalar = "morphs.local_eye_rotation"
    v140.minimum = 0
    v140.maximum = 0.5
    v140.initial = 0.25
    v140.step = 0.025

    local v141 = t1.Entry.default()

    v141.label = "Width"
    v141.scalar = "morphs.local_eye_width"
    v141.minimum = 0
    v141.maximum = 0.5
    v141.initial = 0.25
    v141.step = 0.025

    local v142 = page5("Eyes", { v139, v140, v141 })
    local page6 = t1.page
    local v143 = t1.Entry.default()

    v143.label = "Curve"
    v143.scalar = "morphs.local_nose_curve"
    v143.minimum = 0
    v143.maximum = 0.5
    v143.initial = 0.25
    v143.step = 0.025

    local v144 = t1.Entry.default()

    v144.label = "Height"
    v144.scalar = "morphs.local_nose_height"
    v144.minimum = 0
    v144.maximum = 0.5
    v144.initial = 0.25
    v144.step = 0.025

    local v145 = t1.Entry.default()

    v145.label = "Length"
    v145.scalar = "morphs.local_nose_length"
    v145.minimum = 0
    v145.maximum = 0.5
    v145.initial = 0.25
    v145.step = 0.025

    local v146 = t1.Entry.default()

    v146.label = "Width"
    v146.scalar = "morphs.local_nose_width"
    v146.minimum = 0
    v146.maximum = 0.5
    v146.initial = 0.25
    v146.step = 0.025

    local v147 = page6("Nose", { v143, v144, v145, v146 })
    local page7 = t1.page
    local v148 = t1.Entry.default()

    v148.label = "Corners"
    v148.scalar = "morphs.local_mouth_corner"
    v148.minimum = 0
    v148.maximum = 0.5
    v148.initial = 0.25
    v148.step = 0.025

    local v149 = t1.Entry.default()

    v149.label = "Height"
    v149.scalar = "morphs.local_mouth_height"
    v149.minimum = 0
    v149.maximum = 0.5
    v149.initial = 0.25
    v149.step = 0.025

    local v150 = t1.Entry.default()

    v150.label = "Fullness"
    v150.scalar = "morphs.local_mouth_lipsize"
    v150.minimum = 0
    v150.maximum = 0.5
    v150.initial = 0.25
    v150.step = 0.025

    local v151 = t1.Entry.default()

    v151.label = "Width"
    v151.scalar = "morphs.local_mouth_width"
    v151.minimum = 0
    v151.maximum = 0.5
    v151.initial = 0.25
    v151.step = 0.025

    local v152 = page7("Mouth", { v148, v149, v150, v151 })
    local page8 = t1.page
    local v153 = t1.Entry.default()

    v153.label = "Definition"
    v153.scalar = "morphs.local_jaw_chiseled"
    v153.minimum = 0
    v153.maximum = 0.5
    v153.initial = 0.25
    v153.step = 0.025

    local v154 = t1.Entry.default()

    v154.label = "Depth"
    v154.scalar = "morphs.local_jaw_depth"
    v154.minimum = 0
    v154.maximum = 0.5
    v154.initial = 0.25
    v154.step = 0.025

    local v155 = t1.Entry.default()

    v155.label = "Chin length"
    v155.scalar = "morphs.local_chin_length"
    v155.minimum = 0
    v155.maximum = 0.5
    v155.initial = 0.25
    v155.step = 0.025

    local v156 = page("Body", {
        v129,
        v130,
        v131,
        v134,
        page3("Face", {
            v138,
            v142,
            v147,
            v152,
            page8("Jaw & chin", { v153, v154, v155 })
        }),
        t1.page("Facial hair", t17)
    })
    local tattoos = p31.tattoos
    local t20 = {}

    for v157 in tattoos do
        table.insert(t20, v157)
    end

    table.sort(t20)
    table.sort(t20, function(p40, p41) -- line: 584
        -- upvalues: p31 (copy)
        local name = p31.tattoos[p40].name
        local name2 = p31.tattoos[p41].name

        if name == name2 then
            return p40 < p41
        end

        return name < name2
    end)

    local t21 = {}

    for _, v158 in {
            { "Upper body", "Arm" },
            { "Lower body", "Leg" }
        } do
        local v159 = v158[1]
        local v160 = v158[2]
        local t22 = {
            t1.choice("None", {
                tattoos = {
                    [v160] = {
                        id = NULL
                    }
                }
            })
        }

        for _, v161 in t20 do
            table.insert(t22, t1.choice(p31.tattoos[v161].name, {
                tattoos = {
                    [v160] = {
                        id = v161
                    }
                }
            }))
        end

        local t24 = {
            t1.choice(if v160 == "Arm" then "Left arm" else "Left leg", {
                tattoos = {
                    [v160] = {
                        side = 0
                    }
                }
            }),
            t1.choice(if v160 == "Arm" then "Right arm" else "Right leg", {
                tattoos = {
                    [v160] = {
                        side = 1
                    }
                }
            })
        }

        if v160 == "Arm" then
            table.insert(t24, t1.choice("Chest", {
                tattoos = {
                    [v160] = {
                        side = 2
                    }
                }
            }))
            table.insert(t24, t1.choice("Back", {
                tattoos = {
                    [v160] = {
                        side = 3
                    }
                }
            }))
        end

        table.insert(t21, t1.page(v159, {
            t1.page("Design", t22),
            t1.page("Placement", t24)
        }))
    end

    table.insert(v156.children, t1.page("Tattoos", t21))

    local v162 = t1.page("Clothes", {
        model_page("Hats", "Hat", {}),
        model_page("T-shirts", "OuterTorso", { "tshirt", "ls_tshirt", "tanktop" }),
        model_page("Shirts", "OuterTorso", { "buttonshirt" }),
        model_page("Hoodies", "OuterTorso", { "hoody" }),
        model_page("Jackets", "OuterTorso", { "jacket" }),
        model_page("Sweaters", "OuterTorso", { "sweater" }),
        model_page("Pants & shorts", "Pants", {}),
        model_page("Shoes", "Feet", {}),
        model_page("Socks", "Sock", {}),
        t1.page("Accessories", {
            model_page("Glasses", "Glasses", {}),
            model_page("Necklaces", "Jewellery", {}),
            model_page("Wristwear", "WristItem", {}),
            model_page("Other", "Accessory", {})
        })
    })

    local function slider(p42, p43) -- line: 628
        -- upvalues: t1 (copy)
        local v163 = t1.Entry.default()

        v163.label = p42
        v163.scalar = p43
        v163.minimum = 0
        v163.maximum = 1
        v163.initial = 0.7
        v163.step = 0.1

        return v163
    end

    local page10 = t1.page
    local v164 = model_page("Deck", "SkateBoard", {})
    local v165 = model_page("Trucks", "SkateTruck", {})
    local v166 = model_page("Wheels", "SkateWheel", {})
    local v167 = t1.Entry.default()

    v167.label = "Truck tightness"
    v167.scalar = "truck"
    v167.minimum = 0
    v167.maximum = 1
    v167.initial = 0.7
    v167.step = 0.1

    local v168 = t1.Entry.default()

    v168.label = "Wheel hardness"
    v168.scalar = "wheel"
    v168.minimum = 0
    v168.maximum = 1
    v168.initial = 0.7
    v168.step = 0.1

    local v169 = page10("Board", { v164, v165, v166, v167, v168 })
    local t28 = {}

    for v170, v171 in { "Default", "Stiff", "Slouch", "Buff" } do
        table.insert(t28, t1.choice(v171, {
            posture = v170 - 1
        }))
    end

    local v172 = t1.page("Your skater", {
        v156,
        v162,
        v169,
        t1.page("Style", { t1.page("Posture", t28) })
    })

    for _, v173 in p32 do
        if v173.label == "Style" then
            for _, v174 in v173.children do
                table.insert(v172.children[4].children, v174)
            end
        else
            local v175

            for v176, v177 in v172.children[1].children do
                if v177.label == v173.label then
                    v175 = v176
                    break
                end
            end

            if v175 ~= nil then
                v172.children[1].children[v175] = v173
            else
                table.insert(v172.children[1].children, v173)
            end
        end
    end

    return v172
end

function t1.setup(p44, p45, p46, p47) -- line: 684
    -- upvalues: rt (copy), Parts (copy), t1 (copy)
    local male = p44.library.defaults.male
    local v178 = if male == nil then {
        selections = {},
        morphs = {}
    } else rt.copy(male)
    local v179 = false

    if p46 ~= nil then
        local resolve = Parts.resolve
        local ok, result = pcall(resolve, p44, p46)

        if ok then
            v178 = result
            v179 = true
        end
    end

    local t30 = {}

    for _, v180 in p47 or {} do
        table.insert(t30, t1.Entry.from_value(v180))
    end

    return {
        open = false,
        just_opened = false,
        preview_yaw = 0,
        selected = 0,
        page_size = 7,
        search = "",
        status = "",
        redraw = true,
        enabled = v179,
        index = t1.menu(p44.library, t30),
        path = {},
        draft = v178,
        settings = p45
    }
end

function t1.merge(p48, p49) -- line: 724
    -- upvalues: rt (copy), json (copy), NULL (copy), t1 (copy)
    if json.is_object(p48) and json.is_object(p49) then
        for _, v181 in json.keys(p49) do
            local v182 = p48[v181]

            if v182 == nil then
                v182 = NULL
            end

            p48[v181] = t1.merge(v182, p49[v181])
        end

        return p48
    end

    return rt.copy(p49)
end

function t1.scalar(p50, p51, p52) -- line: 740
    -- upvalues: json (copy)
    for match in string.gmatch(p51, "[^%.]+") do
        p50 = json.get(p50, match)

        if p50 == nil then
            return p52
        end
    end

    local v184 = json.as_f64(p50)

    if v184 == nil then
        return p52
    end

    return v184
end

function t1.matches_patch(p53, p54) -- line: 754
    -- upvalues: json (copy), t1 (copy)
    if not json.is_object(p54) then
        return json.eq(p53, p54)
    end

    for v185, v186 in p54 do
        if not t1.matches_patch(json.index(p53, v185), v186) then
            return false
        end
    end

    return true
end

function t1.option_index(p55, p56) -- line: 768
    -- upvalues: json (copy), t1 (copy)
    for v187, v188 in p55.options do
        local patch = v188.patch
        local v189 = patch ~= nil and json.is_object(patch)

        if v189 then
            local v190 = v189

            for v191, v192 in patch do
                if v191 == "selections" then
                    if json.is_object(v192) then
                        for v193, v194 in v192 do
                            local hair_choice

                            if v193 == "Hair" then
                                hair_choice = json.get(p56, "hair_choice")

                                if hair_choice == nil then
                                    hair_choice = json.index(json.index(p56, "selections"), v193)
                                end
                            else
                                hair_choice = json.index(json.index(p56, "selections"), v193)
                            end

                            if not json.eq(hair_choice, v194) then
                                v190 = false
                                break
                            end
                        end
                    else
                        v190 = false
                    end
                else
                    v190 = t1.matches_patch(json.index(p56, v191), v192)
                end

                if not v190 then
                    v189 = v190
                    break
                end

                v189 = v190
            end
        end

        if v189 then
            return v187 - 1
        end
    end

    return nil
end

local function position(p57, p58) -- line: 809
    for v195, v196 in p57 do
        if v196 == p58 then
            return v195 - 1
        end
    end

    return nil
end

function t1.interact(p59, p60, p61, p62, p63, p64, p65, p66, p67, p68, p69) -- line: 832
    -- upvalues: rt (copy), Parts (copy), json (copy), t1 (copy), Customiser (copy)
    if p64.open then
        if p64.just_opened then
            p64.just_opened = false
        else
            local v197 = true

            for _, v198 in Customiser.page(p64).children do
                if #v198.children ~= 0 then
                    v197 = false
                    break
                end
            end

            if v197 then
                for _, v199 in p63 do
                    if v199.pressed and not p59.pressed(p59, "ControlLeft") and not p59.pressed(p59, "ControlRight") then
                        local text = v199.text

                        if text ~= nil then
                            for match in string.gmatch(text, "[%w %-]") do
                                if #p64.search < 32 then
                                    p64.search ..= match
                                    p64.selected = 0
                                    p64.redraw = true
                                end
                            end
                        end
                    end
                end
            end

            if p64.search ~= "" then
                if p59.just_pressed(p59, "Backspace") then
                    p64.search = string.sub(p64.search, 1, -2)
                    p64.selected = 0
                    p64.redraw = true

                    return
                end

                local Escape = p59.just_pressed(p59, "Escape")
                local v200 = if not Escape then bit32.band(p61.pressed, 8192) == 0 else nil

                if Escape or not v200 then
                    p64.search = ""
                    p64.selected = 0
                    p64.redraw = true

                    return
                end
            end

            local v201 = Customiser.visible(p64)
            local v202 = #v201
            local Escape = p59.just_pressed(p59, "Escape")

            if not Escape then
                Escape = p59.just_pressed(p59, "Backspace")

                if not Escape then
                    Escape = bit32.band(p61.pressed, 8192) ~= 0
                end
            end

            local ArrowUp = p59.just_pressed(p59, "ArrowUp")
            local v203 = if not ArrowUp then bit32.band(p61.pressed, 1) == 0 else nil
            local v204 = if ArrowUp or not v203 then 0 - 1 else 0
            local ArrowDown = p59.just_pressed(p59, "ArrowDown")
            local v205 = if not ArrowDown then bit32.band(p61.pressed, 2) == 0 else nil

            if ArrowDown or not v205 then
                v204 += 1
            end

            for _, v206 in p62 do
                if v206.y > 0 then
                    v204 -= 1
                elseif v206.y < 0 then
                    v204 += 1
                end
            end

            if p59.just_pressed(p59, "PageDown") then
                v204 += p64.page_size
            end

            if p59.just_pressed(p59, "PageUp") then
                v204 -= p64.page_size
            end

            local v207, v208

            if v202 > 0 then
                if v204 ~= 0 then
                    p64.selected = (p64.selected + v204) % v202
                    p64.redraw = true
                end

                local Enter = p59.just_pressed(p59, "Enter")
                local v209 = if not Enter then bit32.band(p61.pressed, 4096) == 0 else nil

                if Enter or not v209 then
                    v207 = v201[p64.selected + 1]
                end

                v208 = 0

                local ArrowRight = p59.just_pressed(p59, "ArrowRight")
                local v210 = if not ArrowRight then bit32.band(p61.pressed, 8) == 0 else nil

                if ArrowRight or not v210 then
                    v207 = v201[p64.selected + 1]
                    v208 = 1
                end

                local ArrowLeft = p59.just_pressed(p59, "ArrowLeft")
                local v211 = if not ArrowLeft then bit32.band(p61.pressed, 4) == 0 else nil

                if ArrowLeft or not v211 then
                    v207 = v201[p64.selected + 1]
                    v208 = -1
                end
            else
                v208 = 0
            end

            if p60 then
                local v212 = v207
                local v213 = v208
                local v214 = Escape

                for _, v215 in p67 do
                    if v215.pressed then
                        local row = v215.row

                        if row == t1.BACK then
                            v214 = true
                        elseif row == t1.NEXT then
                            if v202 > 0 then
                                p64.selected = math.min(p64.selected + p64.page_size, v202 - 1)
                                p64.redraw = true
                            end
                        elseif row == t1.PREV then
                            p64.selected = math.max(p64.selected - p64.page_size, 0)
                            p64.redraw = true
                        elseif row == t1.RESET then
                            local v219 = json.as_str(json.index(p64.draft, "gender")) or "male"
                            local v220 = p65.library.defaults[v219]

                            if v220 ~= nil then
                                p64.draft = rt.copy(v220)
                                p64.redraw = true
                            end
                        else
                            local v221 = false
                            local v222

                            for v223, v224 in v201 do
                                if v224 == row then
                                    v222 = v223 - 1
                                    v221 = true
                                    break
                                end
                            end

                            if not v221 then
                                v222 = nil
                            end

                            p64.selected = v222 or 0
                            v212 = row
                            v213 = 0
                        end
                    end

                    Escape = v214
                    v207 = v212
                    v208 = v213
                end

                local v225 = v207
                local v226 = v208

                for _, v227 in p68 do
                    if v227.pressed then
                        local index = v227.index
                        local v228 = false
                        local v229

                        for v230, v231 in v201 do
                            if v231 == index then
                                v229 = v230 - 1
                                v228 = true
                                break
                            end
                        end

                        if not v228 then
                            v229 = nil
                        end

                        p64.selected = v229 or 0
                        v225 = v227.index
                        v226 = v227.direction
                    end

                    v208 = v226
                    v207 = v225
                end
            end

            if Escape then
                p64.search = ""

                local v232 = table.remove(p64.path)

                if v232 ~= nil then
                    local v233 = false
                    local v234

                    for v235, v236 in (Customiser.visible(p64)) do
                        if v236 == v232 then
                            v234 = v235 - 1
                            v233 = true
                            break
                        end
                    end

                    if not v233 then
                        v234 = nil
                    end

                    p64.selected = v234 or 0
                else
                    local draft = p64.draft
                    local ok, result = pcall(p69, draft)

                    if ok then
                        p64.open = false
                        p66.open = false
                    else
                        p64.status = ("Could not save: %*"):format((tostring(result)))
                    end
                end

                p64.redraw = true
            elseif v207 ~= nil then
                local v237 = Customiser.page(p64).children[v207 + 1]

                if v237 == nil then
                    return
                end

                if #v237.children == 0 then
                    local v238 = false
                    local v239 = false
                    local v240 = false
                    local v241 = false
                    local v242 = false
                    local v243 = false

                    if v237.note ~= nil then
                        v243 = true
                    else
                        v238 = true
                    end

                    local v244, scalar

                    if v238 then
                        v244 = rt.copy(p64.draft)
                        scalar = v237.scalar

                        if scalar ~= nil then
                            v239 = true
                        else
                            v240 = true
                        end
                    end

                    v238 = false

                    if v239 then
                        if v208 < 0 then
                            v241 = true
                        else
                            v238 = true
                        end
                    end

                    v239 = false

                    local v245

                    if v238 then
                        v245 = 1
                        v239 = true
                    end

                    v238 = false

                    if v241 then
                        v245 = -1
                        v239 = true
                    end

                    v241 = false

                    local v246, v247

                    if v239 then
                        v246 = rt.clamp(t1.scalar(v244, scalar, v237.initial or 0) + v245 * (v237.step or 0.1), v237.minimum or 0, v237.maximum or 1)
                        v247 = string.find(scalar, ".", 1, true)

                        if v247 ~= nil then
                            v241 = true
                        else
                            v238 = true
                        end
                    end

                    v239 = false

                    local v248, v249

                    if v241 then
                        v248 = string.sub(scalar, 1, v247 - 1)
                        v249 = string.sub(scalar, v247 + 1)

                        if json.is_object(v244[v248]) then
                            v242 = true
                        else
                            v239 = true
                        end
                    end

                    v241 = false

                    if v239 then
                        v242 = true
                        v244[v248] = {}
                    end

                    v239 = false

                    local v252

                    if v242 then
                        v244[v248][v249] = v246
                        v252 = v244
                        v243 = false
                    end

                    v242 = false

                    if v238 then
                        v244[scalar] = v246
                        v252 = v244
                        v243 = false
                    end

                    v238 = false

                    if v240 then
                        if #v237.options == 0 then
                            v239 = true
                        else
                            v242 = true
                        end
                    end

                    v240 = false

                    local v253

                    if v242 then
                        v253 = t1.option_index(v237, v244)

                        if v253 ~= nil then
                            v240 = true
                        else
                            v238 = true
                        end
                    end

                    v242 = false

                    if v240 then
                        if v208 == 0 then
                            v241 = true
                        else
                            v242 = true
                        end
                    end

                    v240 = false

                    local v254

                    if v242 then
                        v254 = v208
                        v240 = true
                    end

                    if v241 then
                        v254 = 1
                        v240 = true
                    end

                    v241 = false

                    local v255

                    if v240 then
                        v255 = (v253 + v254) % #v237.options
                        v241 = true
                    end

                    v240 = false

                    if v238 then
                        v255 = 0
                        v241 = true
                    end

                    local patch

                    if v241 then
                        patch = v237.options[v255 + 1].patch
                        v240 = true
                    end

                    v241 = false

                    if v239 then
                        patch = v237.patch
                        v240 = true
                    end

                    v239 = false

                    if v240 then
                        if patch ~= nil then
                            v241 = true
                        else
                            v252 = v244
                            v243 = false
                        end
                    end

                    v240 = false

                    local v256

                    if v241 then
                        v256 = json.as_str(json.index(patch, "gender"))

                        if v256 ~= nil then
                            v240 = true
                        else
                            v239 = true
                        end
                    end

                    v241 = false

                    local v257

                    if v240 then
                        v257 = p65.library.defaults[v256]

                        if v257 ~= nil then
                            v241 = true
                        else
                            v252 = v244
                            v243 = false
                        end
                    end

                    if v241 then
                        v252 = rt.copy(v257)
                        v243 = false
                    end

                    v241 = false

                    local v258, Hair

                    if v239 then
                        v258 = t1.merge(v244, patch)
                        Hair = json.get(json.index(patch, "selections"), "Hair")

                        if Hair ~= nil then
                            v241 = true
                        else
                            v252 = v258
                            v243 = false
                        end
                    end

                    if v241 then
                        v258.hair_choice = rt.copy(Hair)
                        v252 = v258
                        v243 = false
                    end

                    if v243 then
                        p64.status = v237.note
                    else
                        local resolve = Parts.resolve
                        local ok, result = pcall(resolve, p65, v252)

                        if ok then
                            p64.draft = result
                            p64.status = ""
                        else
                            p64.status = tostring(result)
                        end
                    end
                else
                    p64.search = ""
                    table.insert(p64.path, v207)
                    p64.selected = 0
                    p64.status = ""
                end

                p64.redraw = true
            end
        end
    end
end

function t1.preferences(p70, p71, p72, p73) -- line: 1054
    -- upvalues: import (copy), v10 (copy), encode (copy), PendingPosture (copy), t1 (copy)
    t1.apply_preferences(p70.draft, p72, p73.animation)

    local v259 = v10.CustomModels.native_style(p71)

    if v259 == nil then
        return
    end

    p73.animation.motion.playback_context.pro_skater = encode(v259)
    PendingPosture.set_profile(p73.animation.motion.animation.posture, 0)
    import("skate_game/physics").GamePhysics.set_gesture_preferences(p72, nil)
end

function t1.apply_preferences(p74, p75, p76) -- line: 1065
    -- upvalues: rt (copy), v1 (copy), import (copy), PendingPosture (copy), json (copy), t1 (copy)
    local GamePhysics = import("skate_game/physics").GamePhysics
    local set_equipment_preferences = GamePhysics.set_equipment_preferences
    local v260 = t1.scalar(p74, "truck", 0.7)
    local v261

    if v260 ~= 0 and v260 > -1.1754943508222875E-38 and v260 < 1.1754943508222875E-38 then
        local v262 = math.abs(v260) * 7.1362384635298E+44
        local v263 = math.floor(v262)
        local v264 = v262 - v263

        v261 = (if v264 > 0.5 or v264 == 0.5 and v263 % 2 == 1 then v263 + 1 else v263) * 1.401298464324817E-45

        if v260 < 0 then
            v261 = -v261
        end
    else
        buffer.writef32(v1, 0, v260)
        v261 = buffer.readf32(v1, 0)
    end

    local v265 = t1.scalar(p74, "wheel", 0.7)
    local v266

    if v265 ~= 0 and v265 > -1.1754943508222875E-38 and v265 < 1.1754943508222875E-38 then
        local v267 = math.abs(v265) * 7.1362384635298E+44
        local v268 = math.floor(v267)
        local v269 = v267 - v268

        v266 = (if v269 > 0.5 or v269 == 0.5 and v268 % 2 == 1 then v268 + 1 else v268) * 1.401298464324817E-45

        if v265 < 0 then
            v266 = -v266
        end
    else
        buffer.writef32(v1, 0, v265)
        v266 = buffer.readf32(v1, 0)
    end

    set_equipment_preferences(p75, v261, v266)

    local gestures = json.index(p74, "gestures")
    local v270 = if json.is_object(gestures) then rt.from_fn(4, function(p77) -- line: 1078
        -- upvalues: gestures (copy), json (copy)
        local v271 = json.as_u64(json.index(gestures, (tostring(p77))))

        if v271 == nil then
            return p77
        end

        return v271 % 4294967296
    end) else nil

    GamePhysics.set_gesture_preferences(p75, v270)
    import("skate_game/skater_animation").SkaterAnimation.set_customisation(p76, rt.f_to_u32(t1.scalar(p74, "stance", 1)), rt.f_to_u32(t1.scalar(p74, "style", 0)))
    PendingPosture.set_profile(p76.motion.animation.posture, rt.f_to_u32(t1.scalar(p74, "posture", 0)))
end

function t1.draw(p78, p79) -- line: 1112
    -- upvalues: rt (copy), t1 (copy), Customiser (copy)
    local open = p78.open

    if not p78.open then
        return open, nil
    end

    local v274 = math.clamp(rt.f_to_usize((math.floor((p79.height * 0.92 - 255) / 90))), 1, 10)

    if v274 ~= p78.page_size then
        p78.page_size = v274
        p78.redraw = true
    end

    if not p78.redraw then
        return open, nil
    end

    p78.redraw = false

    local v275 = Customiser.page(p78)
    local v276 = Customiser.visible(p78)
    local v277 = rt.idiv(p78.selected, p78.page_size) * p78.page_size
    local v278

    if p78.search == "" then
        if #p78.path == 0 then
            v278 = "Make it yours"
        else
            local t31 = {}
            local v279 = p78.index

            for _, v280 in p78.path do
                table.insert(t31, v279.label)
                v279 = v279.children[v280 + 1]
            end

            v278 = table.concat(t31, " / ")
        end
    else
        v278 = ("Search: %*"):format(p78.search)
    end

    local t32 = {
        subtitle = v278,
        title = v275.label,
        rows = {},
        footer = {}
    }

    if #v276 == 0 then
        t32.empty = "No matches. Esc clears your search."
    end

    for i = v277, math.min(v277 + p78.page_size, #v276) - 1 do
        local v283 = v276[i + 1]
        local v284 = v275.children[v283 + 1]
        local v285 = t1.option_index(v284, p78.draft)
        local v286

        if v284.scalar ~= nil then
            local v288 = t1.scalar(p78.draft, v284.scalar, v284.initial or 0)
            local v289 = v284.minimum or 0

            v286 = string.format("%d%%   − / +", rt.f_to_i32(rt.round((v288 - v289) / ((v284.maximum or 1) - v289) * 100)))
        elseif #v284.options == 0 then
            v286 = if #v284.children ~= 0 or v284.patch == nil then "" elseif t1.matches_patch(p78.draft, v284.patch) then "Selected" else "Select"
        else
            local v287 = v285 or 0

            v286 = string.format("%s  ·  %d/%d", v284.options[v287 + 1].label, v287 + 1, #v284.options)
        end

        local v290 = v284.scalar ~= nil or #v284.options > 1
        local v292 = math.clamp(p79.width * 0.38, 370, 520) - 44 - 24 - (if v290 then 68 else 0)
        local v293 = v284.label .. (if #v284.children == 0 then "" else "  ›")
        local v296 = math.clamp(v292 / (math.max(utf8.len(v293) or #v293, 1) * 0.64), 16, 18)
        local v299 = math.clamp(v292 / (math.max(utf8.len(v286) or #v286, 1) * 0.64), 10, 12)

        table.insert(t32.rows, {
            index = v283,
            selected = i == p78.selected,
            label = v293,
            label_size = v296,
            detail = v286,
            detail_size = v299,
            adjustable = v290
        })
    end

    if p78.status ~= "" then
        t32.status = p78.status
    end

    local t34 = {
        {
            t1.BACK,
            if #p78.path == 0 then "Done" else "‹ Back"
        },
        {
            t1.PREV,
            "‹"
        },
        {
            t1.NEXT,
            "›"
        }
    }

    for _, v301 in t34 do
        local v302 = v301[1]
        local v303 = v301[2]

        if v302 == t1.BACK or not (#v276 <= p78.page_size) then
            table.insert(t32.footer, {
                id = v302,
                title = v303
            })
        end
    end

    if #v276 > p78.page_size then
        t32.page_label = string.format("%d / %d", rt.idiv(v277, p78.page_size) + 1, (math.ceil(#v276 / p78.page_size)))
    end

    t32.hint = #p78.path == 0 and "Right stick: Rotate   •   Done saves and resumes." or "↑↓ Browse   ←→ Change   Right stick: Rotate\nType to search"

    return open, t32
end

return t1
