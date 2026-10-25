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
local v9 = import("skate_game/customiser_material")

local function customiser_mod() -- line: 31
    -- upvalues: import (copy)
    return import("skate_game/customiser")
end

local t1 = {
    JSON_NULL = "\000json:null"
}
local JSON_NULL = t1.JSON_NULL

local function json_is_object(p3) -- line: 48
    if type(p3) == "table" then
        return #p3 == 0
    end

    return false
end

local function json_is_array(p4) -- line: 52
    if type(p4) == "table" then
        return #p4 > 0
    end

    return false
end

local function json_index(p5, p6) -- line: 57
    -- upvalues: JSON_NULL (copy)
    local v10 = type(p5) == "table" and #p5 == 0
    local v11, v12

    if v10 then
        v11 = p5[p6]
        v12 = v11 == nil
    end

    if not v10 or v12 then
        return JSON_NULL
    end

    return v11
end

local function json_get(p7, p8) -- line: 68
    return if type(p7) == "table" and #p7 == 0 then p7[p8] else nil
end

local function json_as_str(p9) -- line: 75
    -- upvalues: JSON_NULL (copy)
    return if type(p9) == "string" and p9 ~= JSON_NULL then p9 else nil
end

local function json_as_f64(p10) -- line: 82
    return if type(p10) == "number" then p10 else nil
end

local function json_as_u64(p11) -- line: 89
    return if type(p11) == "number" and p11 >= 0 and p11 == math.floor(p11) then p11 else nil
end

local function json_keys(p12) -- line: 97
    local t2 = {}

    for v13 in p12 do
        table.insert(t2, v13)
    end

    table.sort(t2)

    return t2
end

local function json_eq(p13, p14) -- line: 107
    -- upvalues: JSON_NULL (copy), json_eq (copy)
    local v14 = if p13 == nil then JSON_NULL else p13
    local v15 = if p14 == nil then JSON_NULL else p14

    if type(v14) ~= "table" or type(v15) ~= "table" then
        return v14 == v15
    end

    if #v14 ~= #v15 then
        return false
    end

    for v16, v17 in v14 do
        if v15[v16] == nil or not json_eq(v17, v15[v16]) then
            return false
        end
    end

    for v18 in v15 do
        if v14[v18] == nil then
            return false
        end
    end

    return true
end

local function json_rgb(p15) -- line: 134
    -- upvalues: v1 (copy)
    if type(p15) ~= "table" or #p15 ~= 3 then
        return nil
    end

    local n1 = 0

    for _ in p15 do
        n1 += 1
    end

    local t3, v19

    if n1 == 3 and type(p15[1]) == "number" and type(p15[2]) == "number" and type(p15[3]) == "number" then
        t3 = {}

        local v23 = p15[1]

        if v23 == 0 then
            buffer.writef32(v1, 0, v23)
            v19 = buffer.readf32(v1, 0)
        elseif v23 > -1.1754943508222875E-38 and v23 < 1.1754943508222875E-38 then
            local v24 = math.abs(v23) * 7.1362384635298E+44
            local v25 = math.floor(v24)
            local v26 = v24 - v25

            if v26 > 0.5 or v26 == 0.5 and v25 % 2 == 1 then
                v25 += 1
            end

            v19 = v25 * 1.401298464324817E-45

            if v23 < 0 then
                v19 = -v19
            end
        else
            buffer.writef32(v1, 0, v23)
            v19 = buffer.readf32(v1, 0)
        end

        local v27 = p15[2]
        local v28

        if v27 ~= 0 and v27 > -1.1754943508222875E-38 and v27 < 1.1754943508222875E-38 then
            local v29 = math.abs(v27) * 7.1362384635298E+44
            local v30 = math.floor(v29)
            local v31 = v29 - v30

            v28 = (if v31 > 0.5 or v31 == 0.5 and v30 % 2 == 1 then v30 + 1 else v30) * 1.401298464324817E-45

            if v27 < 0 then
                v28 = -v28
            end
        else
            buffer.writef32(v1, 0, v27)
            v28 = buffer.readf32(v1, 0)
        end

        local v32 = p15[3]
        local v33

        if v32 ~= 0 and v32 > -1.1754943508222875E-38 and v32 < 1.1754943508222875E-38 then
            local v34 = math.abs(v32) * 7.1362384635298E+44
            local v35 = math.floor(v34)
            local v36 = v34 - v35

            v33 = (if v36 > 0.5 or v36 == 0.5 and v35 % 2 == 1 then v35 + 1 else v35) * 1.401298464324817E-45

            if v32 < 0 then
                v33 = -v33
            end
        else
            buffer.writef32(v1, 0, v32)
            v33 = buffer.readf32(v1, 0)
        end

        t3[1] = v19
        t3[2] = v28
        t3[3] = v33

        return t3
    end

    return nil
end

t1.json = {
    NULL = JSON_NULL,
    is_object = json_is_object,
    is_array = json_is_array,
    index = json_index,
    get = json_get,
    as_str = json_as_str,
    as_f64 = json_as_f64,
    as_u64 = json_as_u64,
    keys = json_keys,
    eq = json_eq,
    rgb = json_rgb
}

local function contains(p16, p17) -- line: 162
    for _, v37 in p16 do
        if v37 == p17 then
            return true
        end
    end

    return false
end

local function in_range(p18, p19, p20) -- line: 172
    if p19 <= p18 then
        return p18 <= p20
    end

    return false
end

t1.Part = {}

function t1.Part.flag(p21, p22) -- line: 179
    local v38 = p21.flags[p22]

    if v38 == nil then
        return ""
    end

    return v38
end

t1.Material = {}

function t1.Material.flag(p23, p24) -- line: 189
    local v39 = p23.flags[p24]

    if v39 == nil then
        return ""
    end

    return v39
end

t1.Library = {}

function t1.Library.default() -- line: 200
    return {
        models = {},
        materials = {},
        defaults = {},
        morphs = {},
        tattoos = {},
        colours = {}
    }
end

function t1.Library.from_value(p25) -- line: 205
    return {
        models = p25.models,
        materials = p25.materials,
        defaults = p25.defaults,
        morphs = p25.morphs,
        tattoos = p25.tattoos or {},
        colours = p25.colours or {}
    }
end

t1.Parts = {}

function t1.Parts.default() -- line: 221
    -- upvalues: t1 (copy), JSON_NULL (copy)
    return {
        library = t1.Library.default(),
        applied = JSON_NULL
    }
end

function t1.Parts.for_test(p26) -- line: 230
    -- upvalues: t1 (copy)
    local v40 = t1.Parts.default()

    v40.library = p26

    return v40
end

function t1.Parts.resolve(p27, p28) -- line: 237
    -- upvalues: rt (copy), t1 (copy), JSON_NULL (copy), json_rgb (copy)
    local library = p27.library
    local v41 = type(p28) == "table" and #p28 == 0
    local v42, selections

    if v41 then
        selections = p28.gender
        v42 = selections == nil
    end

    if not v41 or v42 then
        selections = JSON_NULL
    end

    if type(selections) ~= "string" or selections == JSON_NULL then
        selections = nil
    end

    local v43

    if selections ~= nil then
        local v44 = false

        for _, v45 in { "male", "female" } do
            if v45 == selections then
                v43 = true
                v44 = true
                break
            end
        end

        if not v44 then
            v43 = false
        end

        if not v43 then
            error("Invalid body", 0)
        end
    end

    local v46, v47, v48

    for _, v49 in {
            { "truck", 1 },
            { "wheel", 1 },
            { "stance", 1 },
            { "style", 3 },
            { "posture", 3 }
        } do
        v46 = v49[1]
        v47 = v49[2]
        v48 = if type(p28) == "table" and #p28 == 0 then p28[v46] else nil

        if v48 ~= nil then
            if type(v48) ~= "number" then
                v48 = nil
            end

            if v48 == nil or not (v48 >= 0 and v48 <= v47) then
                error(("Invalid %*"):format(v46), 0)
            end
        end
    end

    v43 = type(p28) == "table" and #p28 == 0

    local colours, v50

    if v43 then
        colours = p28.colours
        v50 = colours == nil
    end

    if not v43 or v50 then
        colours = JSON_NULL
    end

    if type(colours) == "table" and #colours == 0 then
        local t5 = {}

        for v51 in colours do
            table.insert(t5, v51)
        end

        table.sort(t5)

        for _, v52 in t5 do
            v47 = colours[v52]

            if v47 ~= JSON_NULL then
                v48 = json_rgb(v47)

                if v48 == nil then
                    error("Invalid clothing colour", 0)
                end

                for _, v53 in v48 do
                    if not (v53 >= 0 and v53 <= 1) then
                        error("Invalid clothing colour", 0)
                    end
                end
            end
        end
    end

    for _, v54 in { "skin_tint", "hair_tint" } do
        v46 = if type(p28) == "table" and #p28 == 0 then p28[v54] else nil

        if v46 ~= nil then
            v47 = json_rgb(v46)

            if v47 == nil then
                error("Invalid colour", 0)
            end

            for _, v55 in v47 do
                if not (v55 >= 0 and v55 <= 1) then
                    error("Invalid colour", 0)
                end
            end
        end
    end

    colours = type(p28) == "table" and #p28 == 0

    local morphs, v56

    if colours then
        morphs = p28.morphs
        v56 = morphs == nil
    end

    if not colours or v56 then
        morphs = JSON_NULL
    end

    if type(morphs) == "table" and #morphs == 0 then
        for v57, v58 in morphs do
            v47 = if type(v58) == "number" then v58 else nil

            local v59 = false
            local v60

            for _, v61 in library.morphs do
                if v61 == v57 then
                    v60 = true
                    v59 = true
                    break
                end
            end

            if not v59 then
                v60 = false
            end

            if not v60 or v47 == nil or not (v47 >= 0 and v47 <= 0.5) then
                error("Invalid face or body value", 0)
            end
        end
    end

    morphs = type(p28) == "table" and #p28 == 0

    local gestures, v62

    if morphs then
        gestures = p28.gestures
        v62 = gestures == nil
    end

    if not morphs or v62 then
        gestures = JSON_NULL
    end

    local v63

    if type(gestures) == "table" and #gestures == 0 then
        for v64, v65 in gestures do
            v47 = if type(v65) == "number" and v65 >= 0 and v65 == math.floor(v65) then v65 else nil

            local v66 = false

            for _, v67 in { "0", "1", "2", "3" } do
                if v67 == v64 then
                    v63 = true
                    v66 = true
                    break
                end
            end

            if not v66 then
                v63 = false
            end

            if not v63 or v47 == nil or v47 >= 37 then
                error("Invalid gesture", 0)
            end
        end
    end

    gestures = type(p28) == "table" and #p28 == 0

    local tattoos, v68

    if gestures then
        tattoos = p28.tattoos
        v68 = tattoos == nil
    end

    if not gestures or v68 then
        tattoos = JSON_NULL
    end

    local v69

    if type(tattoos) == "table" and #tattoos == 0 then
        for v70, v71 in tattoos do
            local morphs

            if type(v71) == "table" and #v71 == 0 then
                morphs = v71.id

                if morphs == nil then
                    morphs = JSON_NULL
                end
            else
                morphs = JSON_NULL
            end

            if type(morphs) ~= "string" or morphs == JSON_NULL then
                morphs = nil
            end

            local _error

            if type(v71) == "table" and #v71 == 0 then
                _error = v71.side

                if _error == nil then
                    _error = JSON_NULL
                end
            else
                _error = JSON_NULL
            end

            if type(_error) ~= "number" or not (_error >= 0) or _error ~= math.floor(_error) then
                _error = nil
            end

            local v72 = false

            for _, v73 in { "Arm", "Leg" } do
                if v73 == v70 then
                    v69 = true
                    v72 = true
                    break
                end
            end

            if not v72 then
                v69 = false
            end

            if v69 then
                if morphs ~= nil then
                    if library.tattoos[morphs] ~= nil then
                        if _error ~= nil then
                            morphs = if v70 == "Arm" then 3 else 1

                            if morphs < _error then
                                error("Invalid tattoo", 0)
                            end
                        end
                    else
                        error("Invalid tattoo", 0)
                    end
                elseif _error ~= nil then
                    morphs = if v70 == "Arm" then 3 else 1

                    if morphs < _error then
                        error("Invalid tattoo", 0)
                    end
                end
            else
                error("Invalid tattoo", 0)
            end
        end
    end

    local v74 = rt.copy(p28)
    local v75 = type(p28) == "table" and #p28 == 0
    local gender, v76

    if v75 then
        gender = p28.gender
        v76 = gender == nil
    end

    if not v75 or v76 then
        gender = JSON_NULL
    end

    if type(gender) ~= "string" or gender == JSON_NULL then
        gender = nil
    end

    local v77 = gender or "male"

    selections = if type(p28) == "table" and #p28 == 0 then p28.hair_choice else nil

    if selections ~= nil then
        if v74.selections == nil or v74.selections == JSON_NULL then
            v74.selections = {}
        end

        gender = v74.selections

        if type(gender) ~= "table" or #gender ~= 0 then
            error("cannot access key \"Hair\" in JSON value", 0)
        end

        v74.selections.Hair = rt.copy(selections)
    end

    selections = v74.selections

    if type(selections) ~= "table" or #selections ~= 0 then
        error("No outfit selected", 0)
    end

    for v78, v79 in selections do
        if v79 == JSON_NULL then
            selections[v78] = nil
        end
    end

    local t6 = {}

    for v80 in selections do
        table.insert(t6, v80)
    end

    table.sort(t6)

    local Gender

    for _, v81 in t6 do
        v69 = selections[v81]

        local asset_id

        if type(v69) == "table" and #v69 == 0 then
            asset_id = v69.asset_id

            if asset_id == nil then
                asset_id = JSON_NULL
            end
        else
            asset_id = JSON_NULL
        end

        if type(asset_id) ~= "string" or asset_id == JSON_NULL then
            asset_id = nil
        end

        if asset_id == nil then
            error("Invalid item", 0)
        end

        local v82 = library.models[asset_id]

        if v82 == nil then
            error("Item unavailable", 0)
        end

        local material_id

        if v82.slot == v81 then
            material_id = {
                "",
                v77,
                "unisex"
            }
            Gender = t1.Part.flag(v82, "Gender")

            local v83 = false
            local v84

            for _, v85 in material_id do
                if v85 == Gender then
                    v84 = true
                    v83 = true
                    break
                end
            end

            if not v83 then
                v84 = false
            end

            if not v84 then
                error("Choose an item for this body", 0)
            end
        else
            error("Choose an item for this body", 0)
        end

        if type(v69) == "table" and #v69 == 0 then
            material_id = v69.material_id

            if material_id == nil then
                material_id = JSON_NULL
            end
        else
            material_id = JSON_NULL
        end

        if type(material_id) ~= "string" or material_id == JSON_NULL then
            material_id = nil
        end

        if material_id == nil then
            error("Invalid colour", 0)
        end

        local v86 = false
        local v87

        for _, v88 in v82.materials do
            if v88 == material_id then
                v87 = true
                v86 = true
                break
            end
        end

        if not v86 then
            v87 = false
        end

        if not v87 or library.materials[material_id] == nil then
            error("Colour unavailable", 0)
        end
    end

    local function model(p29, p30) -- line: 379
        -- upvalues: library (copy), JSON_NULL (copy)
        local v89 = p29[p30]

        if v89 == nil then
            return nil
        end

        local v90 = type(v89) == "table" and #v89 == 0
        local asset_id, v91

        if v90 then
            asset_id = v89.asset_id
            v91 = asset_id == nil
        end

        if not v90 or v91 then
            asset_id = JSON_NULL
        end

        if type(asset_id) ~= "string" or asset_id == JSON_NULL then
            asset_id = nil
        end

        return if asset_id ~= nil then library.models[asset_id] else nil
    end

    local function smallest(p31, p32) -- line: 391
        -- upvalues: library (copy)
        local v92

        for v93, v94 in library.models do
            if v94.slot == p31 and p32(v94) and (v92 == nil or v93 < v92) then
                v92 = v93
            end
        end

        return v92
    end

    local function choose(p33, p34, p35, p36) -- line: 400
        -- upvalues: library (copy), v77 (copy), smallest (copy), t1 (copy), JSON_NULL (copy)
        local v95 = false
        local v96 = false
        local v97 = false
        local v98 = false
        local v99 = false
        local v100 = false

        if p36 == "" then
            v100 = true
        else
            v95 = true
        end

        if v95 then
            if p36 == "none" then
                v100 = true
            else
                v96 = true
            end
        end

        v95 = false

        local v101

        if v96 then
            v101 = p33[p34]

            if v101 ~= nil then
                v95 = true
            else
                v97 = true
            end
        end

        v96 = false

        local v102

        if v95 then
            if type(v101) == "table" then
                v96 = true
            else
                v102 = false
                v98 = true
            end
        end

        v95 = false

        if v96 then
            if #v101 == 0 then
                v99 = true
            else
                v95 = true
            end
        end

        if v95 then
            v102 = false
            v98 = true
        end

        v95 = false

        if v99 then
            v102 = true
            v98 = true
        end

        v99 = false

        if v98 then
            if v102 then
                v99 = true
            else
                v95 = true
            end
        end

        v98 = false

        local asset_id

        if v99 then
            asset_id = v101.asset_id

            if asset_id ~= nil then
                v98 = true
            else
                v95 = true
            end
        end

        v99 = false

        local v103

        if v98 then
            v103 = asset_id
            v99 = true
        end

        v98 = false

        if v95 then
            v103 = JSON_NULL
            v99 = true
        end

        v95 = false

        if v99 then
            if type(v103) == "string" then
                v98 = true
            else
                v95 = true
            end
        end

        v99 = false

        if v98 then
            if v103 == JSON_NULL then
                v95 = true
            else
                v99 = true
            end
        end

        v98 = false

        local v104

        if v99 then
            v104 = v103
            v98 = true
        end

        v99 = false

        if v95 then
            v104 = nil
            v98 = true
        end

        v95 = false

        if v98 then
            if v104 ~= nil then
                v99 = true
            else
                v95 = true
            end
        end

        local v105

        if v99 then
            v105 = library.models[v104]
            v100 = false
        end

        if v95 then
            v105 = nil
            v100 = false
        end

        if v97 then
            v105 = nil
            v100 = false
        end

        if v100 then
            p33[p34] = nil
        elseif v105 == nil or t1.Part.flag(v105, p35) ~= p36 then
            local v106 = smallest(p34, function(p37) -- line: 411
                -- upvalues: p35 (copy), p36 (copy), v77 (copy), t1 (copy)
                local t7 = {
                    "",
                    v77,
                    "unisex"
                }
                local Gender = t1.Part.flag(p37, "Gender")
                local v107 = false
                local v108

                for _, v109 in t7 do
                    if v109 == Gender then
                        v108 = true
                        v107 = true
                        break
                    end
                end

                if not v107 then
                    v108 = false
                end

                return v108 and t1.Part.flag(p37, p35) == p36
            end)

            if v106 == nil then
                error(("No matching %*"):format(p34), 0)
            end

            local v110 = library.models[v106]
            local v111

            for _, v112 in v110.materials do
                local v113 = library.materials[v112]

                if v113 ~= nil and t1.Material.flag(v113, "IsDefault") == "yes" then
                    v111 = v112
                    break
                end

                v111 = nil
            end

            if v111 == nil then
                for _, v114 in v110.materials do
                    if library.materials[v114] ~= nil then
                        v111 = v114
                        break
                    end
                end
            end

            if v111 == nil then
                error("No matching material", 0)
            end

            p33[p34] = {
                asset_id = v106,
                material_id = v111
            }
        end
    end

    v63 = selections.OuterTorso

    if v63 ~= nil then
        local v115 = type(v63) == "table" and #v63 == 0
        local asset_id, v116

        if v115 then
            asset_id = v63.asset_id
            v116 = asset_id == nil
        end

        if not v115 or v116 then
            asset_id = JSON_NULL
        end

        if type(asset_id) ~= "string" or asset_id == JSON_NULL then
            asset_id = nil
        end

        v47 = if asset_id ~= nil then library.models[asset_id] else nil
    else
        v47 = nil
    end

    if v47 ~= nil then
        choose(selections, "Arm", "ArmModelType", t1.Part.flag(v47, "ArmModelRequired"))
        choose(selections, "InnerTorso", "InnerCutType", t1.Part.flag(v47, "InnerCutTypeRequired"))

        if t1.Part.flag(v47, "SupportsWristItem") == "no" then
            selections.WristItem = nil
        end

        if t1.Part.flag(v47, "IsNecklaceRemoved") == "yes" then
            selections.Jewellery = nil
        end
    end

    v63 = selections.Pants

    if v63 ~= nil then
        local v117 = type(v63) == "table" and #v63 == 0
        local asset_id, v118

        if v117 then
            asset_id = v63.asset_id
            v118 = asset_id == nil
        end

        if not v117 or v118 then
            asset_id = JSON_NULL
        end

        if type(asset_id) ~= "string" or asset_id == JSON_NULL then
            asset_id = nil
        end

        v47 = if asset_id ~= nil then library.models[asset_id] else nil
    else
        v47 = nil
    end

    if v47 ~= nil then
        choose(selections, "Leg", "LegModelType", t1.Part.flag(v47, "LegModelRequired"))
    end

    v47 = selections.Leg

    local asset_id

    if v47 ~= nil then
        local v119 = type(v47) == "table" and #v47 == 0
        local v120

        if v119 then
            asset_id = v47.asset_id
            v120 = asset_id == nil
        end

        if not v119 or v120 then
            asset_id = JSON_NULL
        end

        if type(asset_id) ~= "string" or asset_id == JSON_NULL then
            asset_id = nil
        end

        v46 = if asset_id ~= nil then library.models[asset_id] else nil
    else
        v46 = nil
    end

    local v121

    if v46 ~= nil then
        v63 = selections.Sock

        if v63 ~= nil then
            local v122 = type(v63) == "table" and #v63 == 0
            local material_id, v123

            if v122 then
                material_id = v63.material_id
                v123 = material_id == nil
            end

            if not v122 or v123 then
                material_id = JSON_NULL
            end

            if type(material_id) ~= "string" or material_id == JSON_NULL then
                material_id = nil
            end

            asset_id = if material_id ~= nil then library.materials[material_id] else nil
            v121 = if asset_id ~= nil then t1.Material.flag(asset_id, "SockStyle") else "none"
        else
            v121 = "none"
        end

        if v121 == "none" then
            v121 = ""
        end

        v69 = t1.Part.flag(v46, "RequiresSockStyle")

        if v69 ~= v121 and (v121 ~= "" or v69 ~= "none") then
            local v124 = v46
            local v125 = v121

            v69 = smallest("Leg", function(p38) -- line: 473
                -- upvalues: v77 (copy), v124 (copy), v125 (copy), t1 (copy)
                local RequiresSockStyle = t1.Part.flag(p38, "RequiresSockStyle")
                local t8 = {
                    "",
                    v77,
                    "unisex"
                }
                local Gender = t1.Part.flag(p38, "Gender")
                local v126 = false
                local v127

                for _, v128 in t8 do
                    if v128 == Gender then
                        v127 = true
                        v126 = true
                        break
                    end
                end

                if not v126 then
                    v127 = false
                end

                if v127 then
                    v127 = t1.Part.flag(p38, "LegModelType") == t1.Part.flag(v124, "LegModelType") and (RequiresSockStyle == v125 or v125 == "" and RequiresSockStyle == "none")
                end

                return v127
            end)

            if v69 == nil then
                error("Choose another sock length", 0)
            end

            selections.Leg = {
                asset_id = v69,
                material_id = library.models[v69].materials[1]
            }
        end
    end

    if selections.Hat == nil then
        v63 = selections.Hair

        if v63 ~= nil then
            local v129 = type(v63) == "table" and #v63 == 0
            local asset_id, v130

            if v129 then
                asset_id = v63.asset_id
                v130 = asset_id == nil
            end

            if not v129 or v130 then
                asset_id = JSON_NULL
            end

            if type(asset_id) ~= "string" or asset_id == JSON_NULL then
                asset_id = nil
            end

            v121 = if asset_id ~= nil then library.models[asset_id] else nil
        else
            v121 = nil
        end

        if v121 ~= nil and t1.Part.flag(v121, "HairModelType") ~= "full" then
            local v131 = v121

            v63 = smallest("Hair", function(p39) -- line: 490
                -- upvalues: v131 (copy), t1 (copy)
                if t1.Part.flag(p39, "HairStyle") == t1.Part.flag(v131, "HairStyle") and t1.Part.flag(p39, "Gender") == t1.Part.flag(v131, "Gender") then
                    return t1.Part.flag(p39, "HairModelType") == "full"
                end

                return false
            end)

            if v63 ~= nil then
                selections.Hair = {
                    asset_id = v63,
                    material_id = library.models[v63].materials[1]
                }
            end
        end
    end

    v63 = selections.Hat

    if v63 ~= nil then
        local v132 = type(v63) == "table" and #v63 == 0
        local asset_id, v133

        if v132 then
            asset_id = v63.asset_id
            v133 = asset_id == nil
        end

        if not v132 or v133 then
            asset_id = JSON_NULL
        end

        if type(asset_id) ~= "string" or asset_id == JSON_NULL then
            asset_id = nil
        end

        v121 = if asset_id ~= nil then library.models[asset_id] else nil
    else
        v121 = nil
    end

    local Hair, v134, v135, v136

    if v121 ~= nil then
        local RequiresHairModelType = t1.Part.flag(v121, "RequiresHairModelType")
        local v137 = false
        local v138 = false
        local v139 = false
        local v140 = false
        local v141 = false
        local v142 = false

        if RequiresHairModelType == "none" then
            v142 = true
        else
            v137 = true
        end

        if v137 then
            Hair = selections.Hair

            if Hair ~= nil then
                v138 = true
            else
                v139 = true
            end
        end

        v137 = false

        if v138 then
            if type(Hair) == "table" then
                v137 = true
            else
                v134 = false
                v140 = true
            end
        end

        v138 = false

        if v137 then
            if #Hair == 0 then
                v141 = true
            else
                v138 = true
            end
        end

        if v138 then
            v134 = false
            v140 = true
        end

        v138 = false

        if v141 then
            v134 = true
            v140 = true
        end

        v141 = false

        if v140 then
            if v134 then
                v141 = true
            else
                v138 = true
            end
        end

        v140 = false

        local asset_id

        if v141 then
            asset_id = Hair.asset_id

            if asset_id ~= nil then
                v140 = true
            else
                v138 = true
            end
        end

        v141 = false

        local v143

        if v140 then
            v143 = asset_id
            v141 = true
        end

        v140 = false

        if v138 then
            v143 = JSON_NULL
            v141 = true
        end

        v138 = false

        if v141 then
            if type(v143) == "string" then
                v140 = true
            else
                v138 = true
            end
        end

        v141 = false

        if v140 then
            if v143 == JSON_NULL then
                v138 = true
            else
                v141 = true
            end
        end

        v140 = false

        if v141 then
            v135 = v143
            v140 = true
        end

        v141 = false

        if v138 then
            v135 = nil
            v140 = true
        end

        v138 = false

        if v140 then
            if v135 ~= nil then
                v141 = true
            else
                v138 = true
            end
        end

        if v141 then
            v136 = library.models[v135]
            v142 = false
        end

        if v138 then
            v136 = nil
            v142 = false
        end

        if v139 then
            v136 = nil
            v142 = false
        end

        if v142 then
            selections.Hair = nil
        elseif v136 ~= nil and RequiresHairModelType ~= "" and t1.Part.flag(v136, "HairModelType") ~= RequiresHairModelType then
            local v144 = v136

            Hair = smallest("Hair", function(p40) -- line: 511
                -- upvalues: v77 (copy), RequiresHairModelType (copy), v144 (copy), t1 (copy)
                if t1.Part.flag(p40, "HairStyle") ~= t1.Part.flag(v144, "HairStyle") or t1.Part.flag(p40, "HairModelType") ~= RequiresHairModelType then
                    return false
                end

                local t9 = {
                    "",
                    v77,
                    "unisex"
                }
                local Gender = t1.Part.flag(p40, "Gender")

                for _, v145 in t9 do
                    if v145 == Gender then
                        return true
                    end
                end

                return false
            end)

            if Hair ~= nil then
                selections.Hair = {
                    asset_id = Hair,
                    material_id = library.models[Hair].materials[1]
                }
            else
                selections.Hair = nil
            end
        end
    end

    local v146 = {}
    local v147 = {}

    for v148 in selections do
        table.insert(v147, v148)
    end

    table.sort(v147)

    local v149, v150

    for _, v151 in v147 do
        Gender = selections[v151]

        if Gender ~= nil then
            if type(Gender) == "table" and #Gender == 0 then
                v149 = Gender.asset_id

                if v149 == nil then
                    v149 = JSON_NULL
                end
            else
                v149 = JSON_NULL
            end

            if type(v149) ~= "string" or v149 == JSON_NULL then
                v149 = nil
            end

            v134 = if v149 ~= nil then library.models[v149] else nil
        else
            v134 = nil
        end

        if v134 ~= nil then
            for match in string.gmatch(t1.Part.flag(v134, "RequiresRemovalOfComponents"), "[^,]*") do
                v150 = string.match(match, "^%s*(.-)%s*$")

                if v150 ~= "" then
                    table.insert(v146, v150)
                end
            end
        end
    end

    for _, v152 in v146 do
        selections[v152] = nil
    end

    v136 = selections.Hair

    if v136 ~= nil then
        local v153 = type(v136) == "table" and #v136 == 0
        local asset_id, v154

        if v153 then
            asset_id = v136.asset_id
            v154 = asset_id == nil
        end

        if not v153 or v154 then
            asset_id = JSON_NULL
        end

        if type(asset_id) ~= "string" or asset_id == JSON_NULL then
            asset_id = nil
        end

        v147 = if asset_id ~= nil then library.models[asset_id] else nil
    else
        v147 = nil
    end

    v146 = if v147 == nil then "" elseif t1.Part.flag(v147, "RequiresHairlineShadowStyle") == "on" then "on" else ""
    v136 = selections.Rostral

    local material_id

    if v136 ~= nil then
        local v155 = type(v136) == "table" and #v136 == 0
        local v156

        if v155 then
            material_id = v136.material_id
            v156 = material_id == nil
        end

        if not v155 or v156 then
            material_id = JSON_NULL
        end

        if type(material_id) ~= "string" or material_id == JSON_NULL then
            material_id = nil
        end
    end

    v147 = if material_id ~= nil then library.materials[material_id] else nil

    if v147 == nil then
        error("Head unavailable", 0)
    end

    v135 = type(p28) == "table" and #p28 == 0

    local skin, v157

    if v135 then
        skin = p28.skin
        v157 = skin == nil
    end

    if not v135 or v157 then
        skin = JSON_NULL
    end

    if type(skin) ~= "string" or skin == JSON_NULL then
        skin = nil
    end

    v136 = skin or t1.Material.flag(v147, "SkinTone")

    if v77 == "female" then
        Hair = ""
    else
        local v158 = type(p28) == "table" and #p28 == 0
        local beard, v159

        if v158 then
            beard = p28.beard
            v159 = beard == nil
        end

        if not v158 or v159 then
            beard = JSON_NULL
        end

        if type(beard) ~= "string" or beard == JSON_NULL then
            beard = nil
        end

        Hair = beard or t1.Material.flag(v147, "FacialHairStyle")
    end

    local t10 = {}

    for v160 in selections do
        table.insert(t10, v160)
    end

    table.sort(t10)

    for _, v161 in t10 do
        v147 = selections[v161]

        local material_id

        if type(v147) == "table" and #v147 == 0 then
            material_id = v147.material_id

            if material_id == nil then
                material_id = JSON_NULL
            end
        else
            material_id = JSON_NULL
        end

        if type(material_id) ~= "string" or material_id == JSON_NULL then
            material_id = nil
        end

        v149 = library.materials[material_id]

        if v149 == nil then
            error("no entry found for key", 0)
        end

        if t1.Material.flag(v149, "SkinTone") ~= "" then
            v150 = library.models

            local asset_id

            if type(v147) == "table" and #v147 == 0 then
                asset_id = v147.asset_id

                if asset_id == nil then
                    asset_id = JSON_NULL
                end
            else
                asset_id = JSON_NULL
            end

            if type(asset_id) ~= "string" or asset_id == JSON_NULL then
                asset_id = nil
            end

            local materials = v150[asset_id].materials

            v150 = nil

            local v162 = nil

            for _, v163 in materials do
                local v164 = library.materials[v163]

                if v164 ~= nil and t1.Material.flag(v164, "SkinTone") == v136 then
                    if v161 == "Rostral" then
                        if t1.Material.flag(v164, "FacialHairStyle") == Hair then
                            local v165 = if v161 ~= "Rostral" then 0 elseif t1.Material.flag(v164, "HairlineShadowStyle") == v146 then 0 else 100

                            if v163 ~= material_id then
                                local n2 = 0

                                for v166, v167 in v149.flags do
                                    if v166 ~= "SkinTone" and v166 ~= "FacialHairStyle" and v164.flags[v166] ~= v167 then
                                        n2 += 1
                                    end
                                end

                                v165 += n2 + 1
                            end

                            if v150 == nil or v165 < v162 then
                                v162 = v165
                                v150 = v163
                            end
                        end
                    else
                        local n3 = 0

                        if v163 ~= material_id then
                            local n4 = 0

                            for v168, v169 in v149.flags do
                                if v168 ~= "SkinTone" and v168 ~= "FacialHairStyle" and v164.flags[v168] ~= v169 then
                                    n4 += 1
                                end
                            end

                            n3 += n4 + 1
                        end

                        if v150 == nil or n3 < v162 then
                            v162 = n3
                            v150 = v163
                        end
                    end
                end
            end

            if v150 == nil then
                error("This skin and facial hair combination is unavailable", 0)
            end

            v147.material_id = v150
        end
    end

    return v74
end

function t1.Parts.profile_material(p41, p42, p43, p44) -- line: 630
    -- upvalues: rt (copy), v9 (copy), t1 (copy), JSON_NULL (copy), json_rgb (copy)
    local v170 = p41.library.models[p42]

    if v170 == nil then
        return nil
    end

    local v171 = p41.library.materials[p43]

    if v171 == nil then
        return nil
    end

    local v172

    if t1.Material.flag(v171, "SkinTone") == "" then
        if v170.slot == "Hair" then
            if type(p44) == "table" and #p44 == 0 then
                v172 = p44.hair_tint
            end
        else
            local v173 = type(p44) == "table" and #p44 == 0
            local colours, v174

            if v173 then
                colours = p44.colours
                v174 = colours == nil
            end

            if not v173 or v174 then
                colours = JSON_NULL
            end

            local slot = v170.slot

            if type(colours) == "table" and #colours == 0 then
                v172 = colours[slot]
            end
        end
    elseif type(p44) == "table" and #p44 == 0 then
        v172 = p44.skin_tint
    end

    local v175 = (if v172 == nil then nil else json_rgb(v172)) or rt.copy(v171.tint)
    local t11 = {
        base_color = {
            v175[1],
            v175[2],
            v175[3]
        },
        diffuse = v171.diffuse,
        normal = v171.normal,
        rough = v171.rough,
        opacity = v171.opacity,
        alpha = v171.alpha,
        double_sided = v171.opacity ~= nil,
        metallic = v171.metallic,
        perceptual_roughness = if v171.rough == nil then v171.roughness else 1
    }
    local v176 = if v170.slot ~= "OuterTorso" or t1.Part.flag(v170, "TopType") ~= "" then v170.slot else "Arm"
    local v177 = type(p44) == "table" and #p44 == 0
    local tattoos, v178

    if v177 then
        tattoos = p44.tattoos
        v178 = tattoos == nil
    end

    if not v177 or v178 then
        tattoos = JSON_NULL
    end

    local v179 = type(tattoos) == "table" and #tattoos == 0
    local v180, v181

    if v179 then
        v180 = tattoos[v176]
        v181 = v180 == nil
    end

    if not v179 or v181 then
        v180 = JSON_NULL
    end

    local v182 = v9.SkinStamp.default()

    if v171.opacity ~= nil then
        v182.enabled = { 0, 1, 0, 0 }
    else
        v182.enabled = { 0, 0, 0, 0 }
    end

    local v183 = type(v180) == "table" and #v180 == 0
    local id, v184

    if v183 then
        id = v180.id
        v184 = id == nil
    end

    if not v183 or v184 then
        id = JSON_NULL
    end

    if type(id) ~= "string" or id == JSON_NULL then
        id = nil
    end

    local v185 = if id == nil then nil else p41.library.tattoos[id]

    if v185 ~= nil then
        local v186 = type(v180) == "table" and #v180 == 0
        local side, v187

        if v186 then
            side = v180.side
            v187 = side == nil
        end

        if not v186 or v187 then
            side = JSON_NULL
        end

        if type(side) ~= "number" or not (side >= 0) or side ~= math.floor(side) then
            side = nil
        end

        local v188 = side or 0
        local v189 = if v188 == 1 then "StampUVConstraintQ4"
            elseif v188 == 2 then "StampUVConstraintQ1"
            elseif v188 == 3 then "StampUVConstraintQ2"
            else "StampUVConstraintQ3"
        local t12 = {}

        for match in string.gmatch(t1.Part.flag(v170, v189), "[^,]+") do
            local v190 = if string.find(match, "^[%+%-]?[%d%.]+[eE]?[%+%-]?%d*$") then tonumber(match) else nil

            if v190 ~= nil then
                table.insert(t12, v190)
            end
        end

        if #t12 == 4 then
            local v191, v192 = v9.placement(t12, v185.bounds)

            v182.texture = v185.texture
            v182.transform = v191
            v182.rectangle = v192
            v182.enabled[1] = 1
            t11.tattoo = id
        end
    end

    t11.extension = v182

    return t11
end

function t1.setup() -- line: 705
    -- upvalues: sim (copy), t1 (copy)
    local customiser = sim.Parent:WaitForChild("sim_data"):FindFirstChild("customiser")

    if customiser == nil then
        return t1.Parts.default(), nil
    end

    local index = require(customiser:WaitForChild("index"))
    local t13 = {
        models = {},
        materials = {},
        tattoos = {}
    }

    for v193, v194 in index.library do
        for _, v195 in v194 do
            for v196, v197 in require(customiser:WaitForChild(v195)) do
                t13[v193][v196] = v197
            end
        end
    end

    local v198 = require(customiser:WaitForChild(index.misc))

    t13.defaults = v198.defaults
    t13.morphs = v198.morphs
    t13.colours = v198.colours

    local v199 = t1.Parts.default()

    v199.library = t1.Library.from_value(t13)

    return v199, index
end

t1.UNAVAILABLE = "Character assets are unavailable. Update this copy's character assets; your skater is unchanged."

function t1.update(p45, p46, p47, p48) -- line: 743
    -- upvalues: rt (copy), v1 (copy), import (copy), t1 (copy), JSON_NULL (copy), json_eq (copy)
    local v200, v201

    if not p46.enabled or p47 then
        return nil
    else
        v200 = import("skate_game/customiser").Customiser.preview(p46, p45)
        v201 = type(v200) == "table" and #v200 == 0
    end

    local selections, v203

    if v201 then
        selections = v200.selections
        v203 = selections == nil
    end

    if not v201 or v203 then
        selections = JSON_NULL
    end

    if type(selections) ~= "table" or #selections ~= 0 then
        return nil
    end

    local t14 = {}
    local t15 = {}

    for v204 in selections do
        table.insert(t15, v204)
    end

    table.sort(t15)

    for _, v205 in t15 do
        local v206 = selections[v205]
        local asset_id

        if type(v206) == "table" and #v206 == 0 then
            asset_id = v206.asset_id

            if asset_id == nil then
                asset_id = JSON_NULL
            end
        else
            asset_id = JSON_NULL
        end

        if type(asset_id) ~= "string" or asset_id == JSON_NULL then
            asset_id = nil
        end

        local material_id

        if type(v206) == "table" and #v206 == 0 then
            material_id = v206.material_id

            if material_id == nil then
                material_id = JSON_NULL
            end
        else
            material_id = JSON_NULL
        end

        if type(material_id) ~= "string" or material_id == JSON_NULL then
            material_id = nil
        end

        if asset_id ~= nil and material_id ~= nil then
            table.insert(t14, {
                asset_id,
                material_id
            })
        end
    end

    local v207 = #t14 == 0
    local v208

    if not v207 then
        local resolve = t1.Parts.resolve

        v208 = pcall(resolve, p45, v200)
    end

    if v207 or not v208 then
        if p46.status ~= t1.UNAVAILABLE then
            p46.status = t1.UNAVAILABLE
            p46.redraw = true
        end

        return nil
    end

    if json_eq(p45.applied, v200) and not p46.open or json_eq(p45.applied, v200) then
        return nil
    end

    local v209 = true

    for _, v210 in t14 do
        local v211 = v210[1]
        local v212 = v210[2]
        local v213 = p45.library.models[v211]
        local v214 = if v213.slot == "OuterTorso" and t1.Part.flag(v213, "TopType") == "" then "Arm" else v213.slot
        local draft = p46.draft
        local tattoos

        if type(draft) == "table" and #draft == 0 then
            tattoos = draft.tattoos

            if tattoos == nil then
                tattoos = JSON_NULL
            end
        else
            tattoos = JSON_NULL
        end

        local v215

        if type(tattoos) == "table" and #tattoos == 0 then
            v215 = tattoos[v214]

            if v215 == nil then
                v215 = JSON_NULL
            end
        else
            v215 = JSON_NULL
        end

        local id

        if type(v215) == "table" and #v215 == 0 then
            id = v215.id

            if id == nil then
                id = JSON_NULL
            end
        else
            id = JSON_NULL
        end

        if type(id) ~= "string" or id == JSON_NULL then
            id = nil
        end

        if not p48(v211, v212, id) then
            v209 = false
        end
    end

    if not v209 then
        return nil
    end

    local t17 = {
        wanted = {},
        parts = {},
        weights = {}
    }

    for _, v216 in t14 do
        t17.wanted[v216[1]] = true
    end

    for _, v217 in t14 do
        local v218 = v217[1]
        local v219 = v217[2]

        table.insert(t17.parts, {
            asset_id = v218,
            material_id = v219,
            slot = p45.library.models[v218].slot,
            material = t1.Parts.profile_material(p45, v218, v219, p46.draft)
        })
    end

    for v220, v221 in p45.library.morphs do
        local v222 = v220 - 1
        local draft = p46.draft
        local morphs

        if type(draft) == "table" and #draft == 0 then
            morphs = draft.morphs

            if morphs == nil then
                morphs = JSON_NULL
            end
        else
            morphs = JSON_NULL
        end

        local v223

        if type(morphs) == "table" and #morphs == 0 then
            v223 = morphs[v221]

            if v223 == nil then
                v223 = JSON_NULL
            end
        else
            v223 = JSON_NULL
        end

        if type(v223) ~= "number" then
            v223 = nil
        end

        if v223 == nil then
            v223 = if v222 >= 2 and v222 < 19 then 0.25 else 0
        end

        local weights = t17.weights
        local v224 = rt.clamp(v223, 0, 0.5)
        local v225

        if v224 == 0 then
            buffer.writef32(v1, 0, v224)
            v225 = buffer.readf32(v1, 0)
        elseif v224 > -1.1754943508222875E-38 and v224 < 1.1754943508222875E-38 then
            local v226 = math.abs(v224) * 7.1362384635298E+44
            local v227 = math.floor(v226)
            local v228 = v226 - v227

            if v228 > 0.5 or v228 == 0.5 and v227 % 2 == 1 then
                v227 += 1
            end

            v225 = v227 * 1.401298464324817E-45

            if v224 < 0 then
                v225 = -v225
            end
        else
            buffer.writef32(v1, 0, v224)
            v225 = buffer.readf32(v1, 0)
        end

        table.insert(weights, v225)
    end

    p45.applied = v200
    p46.status = ""
    p46.redraw = true

    return t17
end

return t1
