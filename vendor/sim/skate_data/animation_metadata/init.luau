-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local v1 = buffer.create(8)

local function rtl_from_bits(p1) -- line: 7
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p1)

    return (buffer.readf32(v1, 0))
end

local function rtl_is_finite(p2) -- line: 11
    if p2 ~= p2 or p2 == 1e999 then
        return false
    end

    return p2 ~= (-1e999)
end

local import = require(sim.import)
local v2 = import("skate_data/animation_metadata/native")
local v3 = import("skate_data/animation_metadata/blend_space")
local v4 = import("skate_data/animation_metadata/selection_space")
local t1 = {
    BlendSpaceMetadata = v3.BlendSpaceMetadata,
    BlendSimplexMetadata = v3.BlendSimplexMetadata,
    SelectionCandidateMetadata = v4.SelectionCandidateMetadata,
    SelectionParameterMetadata = v4.SelectionParameterMetadata,
    SelectionSpaceMetadata = v4.SelectionSpaceMetadata
}
local v5

local function sorted_keys(p3) -- line: 41
    local t2 = {}

    for v6 in p3 do
        table.insert(t2, v6)
    end

    table.sort(t2)

    return t2
end

t1.BankSource = {}

function t1.BankSource.eq(p4, p5) -- line: 53
    if p4.source_bank == p5.source_bank and p4.source_sha256 == p5.source_sha256 then
        return p4.source_bytes == p5.source_bytes
    end

    return false
end

t1.ClipAttribute = {}
t1.ClipMetadata = {}
t1.PhaseBlendMetadata = {}
t1.TreeMetadata = {}
t1.SelectorMetadata = {}
t1.UnsupportedTree = {}
t1.File = {}

local function check_fields(p6, p7, p8, p9) -- line: 90
    if type(p6) ~= "table" then
        error(string.format("invalid type: expected struct %s", p7), 0)
    end

    local t3 = {}

    for _, v7 in p8 do
        t3[v7] = true

        if p6[v7] == nil then
            error(string.format("missing field `%s`", v7), 0)
        end
    end

    if p9 ~= nil then
        for _, v8 in p9 do
            t3[v8] = true
        end
    end

    for v9 in p6 do
        if not t3[v9] then
            error(string.format("unknown field `%s`", (tostring(v9))), 0)
        end
    end
end

function t1.File.from_json(p10) -- line: 115
    -- upvalues: check_fields (copy)
    local function v10() -- line: 116
        -- upvalues: p10 (copy)
        return game:GetService("HttpService"):JSONDecode(p10)
    end

    local ok, result = pcall(v10)

    if not ok then
        error(tostring(result), 0)
    end

    check_fields(result, "File", { "version", "source_bank", "source_sha256", "source_bytes", "clips", "unsupported_trees" }, { "phase_blends", "blend_spaces", "selectors", "selection_spaces" })
    result.phase_blends = result.phase_blends or {}
    result.blend_spaces = result.blend_spaces or {}
    result.selectors = result.selectors or {}
    result.selection_spaces = result.selection_spaces or {}

    for _, v11 in result.clips do
        check_fields(v11, "ClipMetadata", { "name", "source_offset", "fps_bits", "frames_bits", "base_speed_bits", "flags_word", "attributes" })

        for _, v12 in v11.attributes do
            check_fields(v12, "ClipAttribute", { "name", "type_id", "begin_bits", "end_bits", "payload_words", "source_offset" })
        end
    end

    for _, v13 in result.phase_blends do
        check_fields(v13, "PhaseBlendMetadata", { "name", "source_offset", "parameter", "children" })
    end

    for _, v14 in result.blend_spaces do
        check_fields(v14, "BlendSpaceMetadata", { "name", "source_offset", "parameters", "children", "simplexes" })

        for _, v15 in v14.simplexes do
            check_fields(v15, "BlendSimplexMetadata", { "children", "vertex_bits", "normal_bits", "scale_bits" })
        end
    end

    for _, v16 in result.selectors do
        check_fields(v16, "SelectorMetadata", { "name", "source_offset", "parameter", "default", "children", "values" })
    end

    for _, v17 in result.selection_spaces do
        check_fields(v17, "SelectionSpaceMetadata", { "name", "source_offset", "parameters", "candidates" })

        for _, v18 in v17.parameters do
            check_fields(v18, "SelectionParameterMetadata", { "name", "mode", "weight_bits", "minimum_bits", "maximum_bits" })
        end

        for _, v19 in v17.candidates do
            check_fields(v19, "SelectionCandidateMetadata", { "child", "value_bits" })
        end
    end

    for _, v20 in result.unsupported_trees do
        check_fields(v20, "UnsupportedTree", { "name", "source_offset", "type_id" })
    end

    return result
end

t1.AnimationMetadata = {}

function t1.AnimationMetadata.load(p11) -- line: 192
    error(string.format("Cannot read animation metadata %s: no file access in Roblox (use AnimationBanks.metadata)", (tostring(p11))), 0)
end

function t1.AnimationMetadata.parse(p12) -- line: 203
    -- upvalues: t1 (copy)
    local v21 = t1.File.from_json(p12)

    return t1.AnimationMetadata.from_file(v21)
end

local function push_entry(p13, p14, p15) -- line: 209
    local v22 = p13[p14]

    if v22 == nil then
        v22 = {}
        p13[p14] = v22
    end

    table.insert(v22, p15)
end

function t1.AnimationMetadata.from_file(p16) -- line: 219
    -- upvalues: v1 (copy), t1 (copy), v5 (ref)
    if p16.version ~= 1 then
        error(string.format("Unsupported animation metadata version %d", p16.version), 0)
    end

    if #p16.source_bank == 0 or #p16.source_sha256 ~= 64 or string.match(p16.source_sha256, "^%x*$") == nil or p16.source_bytes < 48 then
        error("Invalid animation bank source identity", 0)
    end

    local t4 = {}

    for _, v23 in p16.clips do
        v5(v23.name, 36)
        buffer.writeu32(v1, 0, v23.fps_bits)

        local v24 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v23.frames_bits)

        local v25 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v23.base_speed_bits)

        local v26 = buffer.readf32(v1, 0)

        if v24 ~= v24 or v24 == 1e999 or v24 == (-1e999) or v24 <= 0 then
            error(string.format("%s: invalid clip header", v23.name), 0)
        elseif v25 ~= v25 or v25 == 1e999 or v25 == (-1e999) or v25 < 1 then
            error(string.format("%s: invalid clip header", v23.name), 0)
        elseif v26 ~= v26 or v26 == 1e999 or v26 == (-1e999) or v26 <= 0 or v23.source_offset >= p16.source_bytes then
            error(string.format("%s: invalid clip header", v23.name), 0)
        end

        local source_offset = v23.source_offset

        for _, v27 in v23.attributes do
            v5(v27.name, 30)
            buffer.writeu32(v1, 0, v27.begin_bits)

            local v28 = buffer.readf32(v1, 0)

            if v28 == v28 and v28 ~= 1e999 and v28 ~= (-1e999) then
                buffer.writeu32(v1, 0, v27.end_bits)

                local v29 = buffer.readf32(v1, 0)

                if v29 ~= v29 or v29 == 1e999 or v29 == (-1e999) or v27.source_offset <= source_offset or v27.source_offset >= p16.source_bytes then
                    error(string.format("%s: invalid attribute record/order", v23.name), 0)
                end
            else
                error(string.format("%s: invalid attribute record/order", v23.name), 0)
            end

            if (if v27.type_id == 0 then 1
                elseif v27.type_id == 1 then 4
                elseif v27.type_id == 3 then 6
                else 0) > #v27.payload_words then
                error(string.format("%s: truncated %s payload", v23.name, v27.name), 0)
            end

            source_offset = v27.source_offset
        end

        local name = v23.name
        local v30 = t4[name]

        if v30 == nil then
            v30 = {}
            t4[name] = v30
        end

        table.insert(v30, v23)
    end

    local t5 = {}

    for _, v31 in p16.phase_blends do
        v5(v31.name, 36)
        v5(v31.parameter, 30)

        if #v31.children < 2 then
            error(string.format("%s: PhaseBlend needs two children", v31.name), 0)
        end

        if v31.source_offset >= p16.source_bytes then
            error(string.format("%s: tree offset outside bank", v31.name), 0)
        end

        for _, v32 in v31.children do
            v5(v32, 36)
        end

        local name = v31.name
        local v33 = t5[name]

        if v33 == nil then
            v33 = {}
            t5[name] = v33
        end

        table.insert(v33, v31)
    end

    local t6 = {}

    for _, v34 in p16.blend_spaces do
        t1.BlendSpaceMetadata.validate(v34, p16.source_bytes)

        local name = v34.name
        local v35 = t6[name]

        if v35 == nil then
            v35 = {}
            t6[name] = v35
        end

        table.insert(v35, v34)
    end

    local t7 = {}

    for _, v36 in p16.selectors do
        v5(v36.name, 36)
        v5(v36.parameter, 30)
        v5(v36.default, 36)

        if #v36.children ~= #v36.values then
            error(string.format("%s: selector key/child count mismatch", v36.name), 0)
        end

        if v36.source_offset >= p16.source_bytes then
            error(string.format("%s: tree offset outside bank", v36.name), 0)
        end

        for _, v37 in v36.children do
            v5(v37, 36)
        end

        for _, v38 in v36.values do
            v5(v38, 30)
        end

        local name = v36.name
        local v39 = t7[name]

        if v39 == nil then
            v39 = {}
            t7[name] = v39
        end

        table.insert(v39, v36)
    end

    local t8 = {}

    for _, v40 in p16.selection_spaces do
        t1.SelectionSpaceMetadata.validate(v40, p16.source_bytes)

        local name = v40.name
        local v41 = t8[name]

        if v41 == nil then
            v41 = {}
            t8[name] = v41
        end

        table.insert(v41, v40)
    end

    local t9 = {}

    for _, v42 in p16.unsupported_trees do
        v5(v42.name, 36)

        if v42.source_offset >= p16.source_bytes then
            error(string.format("%s: tree offset outside bank", v42.name), 0)
        end

        local name = v42.name
        local t10 = {
            v42.source_offset,
            v42.type_id
        }
        local v43 = t9[name]

        if v43 == nil then
            v43 = {}
            t9[name] = v43
        end

        table.insert(v43, t10)
    end

    local t11 = {}

    for _, v44 in { t4, t5, t6, t7, t8, t9 } do
        for v45 in v44 do
            t11[v45] = 0
        end
    end

    local t12 = {
        {
            source_bank = p16.source_bank,
            source_sha256 = p16.source_sha256,
            source_bytes = p16.source_bytes
        }
    }

    return {
        source_bank = p16.source_bank,
        source_sha256 = p16.source_sha256,
        clips = t4,
        phase_blends = t5,
        blend_spaces = t6,
        selectors = t7,
        selection_spaces = t8,
        unsupported = t9,
        sources = t12,
        origins = t11
    }
end

function t1.AnimationMetadata.merge(p17, p18) -- line: 359
    local t13 = {}

    for v46 in p18.origins do
        table.insert(t13, v46)
    end

    table.sort(t13)

    for _, v47 in t13 do
        if p17.origins[v47] ~= nil then
            error(string.format("Animation bank merge collides at %s", v47), 0)
        end
    end

    local v48 = #p17.sources

    for v49, v50 in p18.origins do
        p17.origins[v49] = v48 + v50
    end

    for _, v51 in p18.sources do
        table.insert(p17.sources, v51)
    end

    for v52, v53 in p18.clips do
        p17.clips[v52] = v53
    end

    for v54, v55 in p18.phase_blends do
        p17.phase_blends[v54] = v55
    end

    for v56, v57 in p18.blend_spaces do
        p17.blend_spaces[v56] = v57
    end

    for v58, v59 in p18.selectors do
        p17.selectors[v58] = v59
    end

    for v60, v61 in p18.selection_spaces do
        p17.selection_spaces[v60] = v61
    end

    for v62, v63 in p18.unsupported do
        p17.unsupported[v62] = v63
    end
end

function t1.AnimationMetadata.sources(p19) -- line: 392
    return p19.sources
end

function t1.AnimationMetadata.source_for(p20, p21) -- line: 396
    local v64 = p20.origins[string.upper(p21)]

    return if v64 ~= nil then p20.sources[v64 + 1] else nil
end

function t1.AnimationMetadata.clip(p22, p23) -- line: 408
    -- upvalues: v5 (ref)
    local v65 = string.upper(p23)

    v5(v65, 36)

    local v66 = p22.clips[v65]
    local v67

    if v66 ~= nil then
        local v68

        for _, v69 in v66 do
            if v68 == nil or v69.source_offset >= v68.source_offset then
                v68 = v69
            end

            v67 = v68
        end
    end

    if v67 == nil then
        error(string.format("Missing direct clip %s", v65), 0)
    end

    return v67
end

local v70 = table.freeze({})

function t1.AnimationMetadata.tree(p24, p25) -- line: 430
    -- upvalues: v5 (ref), v70 (copy)
    local v71 = string.upper(p25)

    v5(v71, 36)

    local v72 = p24.clips[v71] or v70
    local v73 = p24.unsupported[v71] or v70
    local v74 = p24.phase_blends[v71] or v70
    local v75 = p24.blend_spaces[v71] or v70
    local v76 = p24.selectors[v71] or v70
    local v77 = p24.selection_spaces[v71] or v70
    local v78

    for _, v79 in { v72, v74, v75, v76, v77 } do
        for _, v81 in v79 do
            if v78 == nil or v78 < v81.source_offset then
                v78 = v81.source_offset
            end
        end
    end

    for _, v82 in v73 do
        if v78 == nil or v78 < v82[1] then
            v78 = v82[1]
        end
    end

    if v78 ~= nil then
        for _, v83 in v72 do
            if v83.source_offset == v78 then
                return {
                    tag = "Clip",
                    v83
                }
            end
        end

        for _, v84 in v74 do
            if v84.source_offset == v78 then
                return {
                    tag = "PhaseBlend",
                    v84
                }
            end
        end

        for _, v85 in v75 do
            if v85.source_offset == v78 then
                return {
                    tag = "BlendSpace",
                    v85
                }
            end
        end

        for _, v86 in v76 do
            if v86.source_offset == v78 then
                return {
                    tag = "Selector",
                    v86
                }
            end
        end

        for _, v87 in v77 do
            if v87.source_offset == v78 then
                return {
                    tag = "SelectionSpace",
                    v87
                }
            end
        end

        for _, v88 in v73 do
            if v88[1] == v78 then
                error(string.format("Animation %s is tree type %d; tree evaluation is required", v71, v88[2]), 0)
            end
        end
    end

    error(string.format("Missing animation %s in %s", v71, p24.source_bank), 0)
end

function t1.AnimationMetadata.clip_count(p26) -- line: 489
    local n1 = 0

    for _, v89 in p26.clips do
        n1 += #v89
    end

    return n1
end

v5 = function(p27, p28) -- line: 498
    if #p27 == 0 or p28 < #p27 or string.match(p27, "^[A-Z0-9_]*$") == nil then
        error(string.format("Invalid canonical FastString name \"%s\"", p27), 0)
    end
end

t1.validate_name = v5

for v90, v91 in v2.AnimationMetadata do
    t1.AnimationMetadata[v90] = v91
end

return t1
