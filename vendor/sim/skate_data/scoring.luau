-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
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
local v2 = import("skate_data/collections")
local v3 = import("skate_data/attrib_hash")
local v4 = import("skate_data/scoring_fields")
local AttributeName = import("skate_core/animation/output/attributes").AttributeName
local encode = import("skate_core/animation/skeleton_input/name").encode
local PointGraph = import("skate_core/point_graph").PointGraph
local IDENTIFIERS = import("skate_core/scoring/catalog").IDENTIFIERS
local Collections = v2.Collections
local t1 = {
    SCORABLE = "Hash_6918469984A8C596",
    TUNING = "Hash_349215E2E817703C"
}
local SCORABLE, TUNING = t1.SCORABLE, t1.TUNING

function t1.scorable_keys(p3) -- line: 43
    -- upvalues: v3 (copy), Collections (copy), SCORABLE (copy)
    local t2 = {}

    for _, v5 in Collections.entries(p3) do
        if v3.numeric_name(v5.class_name) == SCORABLE then
            t2[v3.numeric_name(v5.key)] = true
        end
    end

    return t2
end

t1.Definition = {}
t1.ScoringData = {}

function t1.ScoringData.session_rules(p4) -- line: 68
    -- upvalues: rt (copy)
    return {
        combo_capacity = p4.combo_capacity,
        combo_levels = rt.copy(p4.combo_levels),
        combo_refresh_threshold = p4.combo_refresh_threshold,
        line_capacity = p4.line_capacity,
        bail_factor = p4.bail_factor
    }
end

function t1.ScoringData.load(p5) -- line: 79
    -- upvalues: rt (copy), v1 (copy), v3 (copy), encode (copy), IDENTIFIERS (copy), Collections (copy), t1 (copy), SCORABLE (copy), TUNING (copy)
    local t3 = {}
    local v6 = t1.scorable_keys(p5)

    for i = 0, #IDENTIFIERS - 1 do
        local v7 = IDENTIFIERS[i + 1]
        local v8 = v7[1]
        local v9 = v7[2]
        local v10 = v7[3]

        if v6[v3.numeric_name(v8)] then
            local function words(p6) -- line: 91
                -- upvalues: p5 (copy), v8 (copy), Collections (copy), SCORABLE (copy)
                return Collections.words(p5, SCORABLE, v8, p6, 1)[1]
            end

            local v11 = Collections.words(p5, SCORABLE, v8, "Hash_B2383F16252DFE8E", 1)[1]

            if v11 ~= i then
                error(string.format("Scorable %s: enum %d disagrees with VLT %d", v8, i, v11), 0)
            end

            local Hash_843613E915014627 = Collections.field(p5, SCORABLE, v8, "Hash_843613E915014627")

            if Hash_843613E915014627.type_name ~= "EA::Reflection::Text" then
                error(string.format("Invalid scorable label %s", v8), 0)
            end

            table.insert(t3, {
                metadata = {
                    id = i,
                    class = v9,
                    score_type = v10
                },
                identifier = v8,
                encoded_name = encode(v8),
                points = rt.to_i32(Collections.integer(p5, SCORABLE, v8, "Hash_937F62AE5C1ED284")),
                label = Hash_843613E915014627.data,
                trick_type = Collections.words(p5, SCORABLE, v8, "TrickType", 1)[1],
                completion_delay = Collections.float(p5, SCORABLE, v8, "Hash_DC7F402E5680BA02"),
                variant = rt.to_i32(Collections.words(p5, SCORABLE, v8, "Hash_2E90BC04042A0B5A", 1)[1]),
                flags = Collections.words(p5, SCORABLE, v8, "Hash_D34A84B044B60CE3", 1)[1]
            })
        end
    end

    if #t3 == 0 then
        error("No native scorable definitions in owned VLT data", 0)
    end

    local function graph(p7) -- line: 130
        -- upvalues: p5 (copy), v1 (copy), Collections (copy), TUNING (copy)
        local v12 = Collections.words(p5, TUNING, "default", p7, 20)

        buffer.writeu32(v1, 0, v12[5])

        local v14 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v12[6])

        local v16 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v12[7])

        local v18 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v12[8])

        local v20 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v12[9])

        local v22 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v12[10])

        local v24 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v12[11])

        local v26 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v12[12])

        local t5 = {
            v14,
            v16,
            v18,
            v20,
            v22,
            v24,
            v26,
            (buffer.readf32(v1, 0))
        }

        buffer.writeu32(v1, 0, v12[13])

        local v29 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v12[14])

        local v31 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v12[15])

        local v33 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v12[16])

        local v35 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v12[17])

        local v37 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v12[18])

        local v39 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v12[19])

        local v41 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, v12[20])

        local t6 = {
            v29,
            v31,
            v33,
            v35,
            v37,
            v39,
            v41,
            (buffer.readf32(v1, 0))
        }
        local v43 = false

        for _, v44 in t5 do
            if v44 ~= v44 or v44 == 1e999 or v44 == (-1e999) then
                v43 = true
                break
            end
        end

        if not v43 then
            for _, v45 in t6 do
                if v45 ~= v45 or v45 == 1e999 or v45 == (-1e999) then
                    v43 = true
                    break
                end
            end
        end

        if not v43 then
            for i = 1, #t5 - 1 do
                if t5[i] > t5[i + 1] then
                    v43 = true
                    break
                end
            end
        end

        if v43 then
            error(string.format("Invalid native scoring curve %s", p7), 0)
        end

        return {
            x = t5,
            y = t6
        }
    end

    local function f(p8) -- line: 182
        -- upvalues: p5 (copy), Collections (copy), TUNING (copy)
        return Collections.float(p5, TUNING, "default", p8)
    end

    local v46 = t1.CollectorTuning.load(p5)
    local Hash_59D91EAABF033A24 = graph("Hash_59D91EAABF033A24")
    local Hash_263B277F8CA17126 = graph("Hash_263B277F8CA17126")
    local Hash_FE02A45231F7B06A = Collections.float(p5, TUNING, "default", "Hash_FE02A45231F7B06A")
    local Hash_57478337ACCFFF18 = Collections.float(p5, TUNING, "default", "Hash_57478337ACCFFF18")
    local Hash_88407506DC9780ED = Collections.float(p5, TUNING, "default", "Hash_88407506DC9780ED")
    local Hash_28767A5F961C7129 = Collections.float(p5, TUNING, "default", "Hash_28767A5F961C7129")
    local Hash_829887D8C24A5B8A = Collections.float(p5, TUNING, "default", "Hash_829887D8C24A5B8A")
    local Hash_4752056364FF91FE = Collections.float(p5, TUNING, "default", "Hash_4752056364FF91FE")
    local Hash_FB8408A15C17A9D4 = Collections.float(p5, TUNING, "default", "Hash_FB8408A15C17A9D4")
    local Hash_F4993A13ED7B44C1 = Collections.float(p5, TUNING, "default", "Hash_F4993A13ED7B44C1")
    local Hash_30AAE071A7868771 = Collections.float(p5, TUNING, "default", "Hash_30AAE071A7868771")
    local Hash_DC0C3853F6C5FC2E = Collections.float(p5, TUNING, "default", "Hash_DC0C3853F6C5FC2E")
    local Hash_E36197BFC8EA1CAD = Collections.float(p5, TUNING, "default", "Hash_E36197BFC8EA1CAD")
    local Hash_2577DF0FCE5251E4 = Collections.float(p5, TUNING, "default", "Hash_2577DF0FCE5251E4")
    local Hash_B0B56FF046508506 = Collections.float(p5, TUNING, "default", "Hash_B0B56FF046508506")
    local Hash_6DC5982591F80A4C = Collections.float(p5, TUNING, "default", "Hash_6DC5982591F80A4C")

    return {
        collector = v46,
        definitions = t3,
        repetition = Hash_59D91EAABF033A24,
        announcement = Hash_263B277F8CA17126,
        line_drain = Hash_FE02A45231F7B06A,
        line_capacity = Hash_57478337ACCFFF18,
        combo_drain = Hash_88407506DC9780ED,
        combo_capacity = Hash_28767A5F961C7129,
        combo_levels = {
            { Hash_829887D8C24A5B8A, Hash_4752056364FF91FE },
            { Hash_FB8408A15C17A9D4, Hash_F4993A13ED7B44C1 },
            { Hash_30AAE071A7868771, Hash_DC0C3853F6C5FC2E }
        },
        combo_refresh_threshold = Hash_E36197BFC8EA1CAD,
        unannounced_factor = Hash_2577DF0FCE5251E4,
        bail_factor = Hash_B0B56FF046508506,
        sketchy_side_speed = Hash_6DC5982591F80A4C
    }
end

function t1.ScoringData.by_name(p9, p10) -- line: 224
    -- upvalues: AttributeName (copy)
    for _, v47 in p9.definitions do
        if AttributeName.eq(v47.encoded_name, p10) then
            return v47
        end
    end

    return nil
end

function t1.ScoringData.by_id(p11, p12) -- line: 234
    for _, v48 in p11.definitions do
        if v48.metadata.id == p12 then
            return v48
        end
    end

    return nil
end

t1.CollectorTuning = {}

function t1.CollectorTuning.load(p13) -- line: 248
    -- upvalues: v1 (copy), v4 (copy), Collections (copy)
    local t7 = {
        scalars = {},
        curves = {}
    }

    for _, v49 in v4.FIELDS do
        local v50 = v49[1]
        local v51 = v49[2]

        if v49[3] == 4 then
            t7.scalars[v50] = Collections.float(p13, "Hash_546C36B656038E04", "default", v51)
        else
            local v52 = Collections.words(p13, "Hash_546C36B656038E04", "default", v51, 20)
            local curves = t7.curves
            local t8 = {}

            buffer.writeu32(v1, 0, v52[5])

            local v54 = buffer.readf32(v1, 0)

            buffer.writeu32(v1, 0, v52[6])

            local v56 = buffer.readf32(v1, 0)

            buffer.writeu32(v1, 0, v52[7])

            local v58 = buffer.readf32(v1, 0)

            buffer.writeu32(v1, 0, v52[8])

            local v60 = buffer.readf32(v1, 0)

            buffer.writeu32(v1, 0, v52[9])

            local v62 = buffer.readf32(v1, 0)

            buffer.writeu32(v1, 0, v52[10])

            local v64 = buffer.readf32(v1, 0)

            buffer.writeu32(v1, 0, v52[11])

            local v66 = buffer.readf32(v1, 0)

            buffer.writeu32(v1, 0, v52[12])
            t8.x = {
                v54,
                v56,
                v58,
                v60,
                v62,
                v64,
                v66,
                (buffer.readf32(v1, 0))
            }
            buffer.writeu32(v1, 0, v52[13])

            local v69 = buffer.readf32(v1, 0)

            buffer.writeu32(v1, 0, v52[14])

            local v71 = buffer.readf32(v1, 0)

            buffer.writeu32(v1, 0, v52[15])

            local v73 = buffer.readf32(v1, 0)

            buffer.writeu32(v1, 0, v52[16])

            local v75 = buffer.readf32(v1, 0)

            buffer.writeu32(v1, 0, v52[17])

            local v77 = buffer.readf32(v1, 0)

            buffer.writeu32(v1, 0, v52[18])

            local v79 = buffer.readf32(v1, 0)

            buffer.writeu32(v1, 0, v52[19])

            local v81 = buffer.readf32(v1, 0)

            buffer.writeu32(v1, 0, v52[20])
            t8.y = {
                v69,
                v71,
                v73,
                v75,
                v77,
                v79,
                v81,
                (buffer.readf32(v1, 0))
            }
            curves[v50] = t8
        end
    end

    return t7
end

function t1.CollectorTuning.scalar(p14, p15) -- line: 287
    local v83 = p14.scalars[p15]

    if v83 == nil then
        error("no entry found for key", 0)
    end

    return v83
end

function t1.CollectorTuning.curve(p16, p17, p18) -- line: 296
    -- upvalues: PointGraph (copy)
    local v84 = p16.curves[p17]

    if v84 == nil then
        error("no entry found for key", 0)
    end

    return PointGraph.evaluate(v84, p18)
end

return t1
