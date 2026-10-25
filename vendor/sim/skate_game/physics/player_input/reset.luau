-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_subnormal_mantissa(p1) -- line: 7
    local v2 = p1 * 7.1362384635298E+44
    local v3 = math.floor(v2)
    local v4 = v2 - v3

    if v4 > 0.5 or v4 == 0.5 and v3 % 2 == 1 then
        return v3 + 1
    end

    return v3
end

local function rtl_to_bits(p2) -- line: 16
    -- upvalues: v1 (copy)
    if p2 ~= 0 and p2 > -1.1754943508222875E-38 and p2 < 1.1754943508222875E-38 then
        local v6 = math.abs(p2) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        if p2 < 0 then
            return v5 + 2147483648
        end

        return v5
    end

    buffer.writef32(v1, 0, p2)

    return (buffer.readu32(v1, 0))
end

local import = require(sim.import)
local ProcessedPhysicsInput = import("skate_core/player/input_phase").ProcessedPhysicsInput
local v8 = false
local t1 = {}

function t1.set_reference(p3) -- line: 35
    -- upvalues: v8 (ref)
    v8 = p3
end

local v9 = import("skate_core/player/input_phase")
local assign_into, copy_into, GrindInvestigationFields = v9.assign_into, v9.copy_into, v9.GrindInvestigationFields
local copy = rt.copy
local t2 = {
    vector_1520 = true,
    matrix_1536 = true,
    byte_1600 = true,
    external_physics_1616 = true,
    probe_1792 = true
}
local v10

local function build_template() -- line: 57
    -- upvalues: v1 (copy), ProcessedPhysicsInput (copy), v9 (copy), t2 (copy), v10 (ref)
    local v11 = ProcessedPhysicsInput.default_reference()

    buffer.writef32(v1, 0, 1)

    local t3 = {
        buffer.readu32(v1, 0),
        0, 0, 0
    }

    buffer.writef32(v1, 0, 1)

    local t4 = {
        0,
        buffer.readu32(v1, 0),
        0, 0
    }

    buffer.writef32(v1, 0, 1)
    v11.effective_anim_transform_192 = {
        t3,
        t4,
        {
            0, 0,
            buffer.readu32(v1, 0),
            0
        },
        { 0, 0, 0, 0 }
    }
    v11.state_variant_index_2528 = 1
    v11.grind_words_2532_2536 = { 4294967295, 0 }
    v11.timestep_2604 = 0.01666666753590107
    v11.gravity_2648 = -9.800000190734863
    v11.actor_query_2952 = 4294967295

    local vectors_544_560_592_608 = v11.vectors_544_560_592_608

    buffer.writef32(v1, 0, 1)
    vectors_544_560_592_608[1] = {
        0,
        buffer.readu32(v1, 0),
        0, 0
    }

    for v12 in t2 do
        v11[v12] = nil
    end

    v10 = v9.freeze_deep(v11)

    return v10
end

local t5
local v13 = table.freeze(table.create(72, 0))

local function build_plan() -- line: 88
    -- upvalues: v10 (ref), build_template (copy), t5 (ref)
    local v14 = v10 or build_template()
    local t6 = {}

    for v15 in v14 do
        table.insert(t6, v15)
    end

    table.sort(t6)

    local t7 = {
        scalar_keys = {},
        scalar_values = {},
        vectors = {},
        arrays = {},
        others = {}
    }

    for _, v16 in t6 do
        local v17 = v14[v16]

        if type(v17) == "table" then
            if v16 ~= "grind" and v16 ~= "grab_records_1888_2176" then
                if #v17 == 4 then
                    if type(v17[1]) == "number" then
                        table.insert(t7.vectors, v16)
                    else
                        local v19 = #v17 > 0
                        local n1 = 0

                        for _, v20 in v17 do
                            n1 += 1

                            if type(v20) ~= "table" or #v20 ~= 4 or type(v20[1]) ~= "number" then
                                v19 = false
                            end
                        end

                        if v19 and n1 == #v17 then
                            table.insert(t7.arrays, v16)
                        else
                            table.insert(t7.others, v16)
                        end
                    end
                else
                    local v22 = #v17 > 0
                    local n2 = 0

                    for _, v23 in v17 do
                        n2 += 1

                        if type(v23) ~= "table" or #v23 ~= 4 or type(v23[1]) ~= "number" then
                            v22 = false
                        end
                    end

                    if v22 and n2 == #v17 then
                        table.insert(t7.arrays, v16)
                    else
                        table.insert(t7.others, v16)
                    end
                end
            end
        else
            table.insert(t7.scalar_keys, v16)
            table.insert(t7.scalar_values, v17)
        end
    end

    local grab_records_1888_2176 = v14.grab_records_1888_2176

    if #grab_records_1888_2176 ~= 2 or #grab_records_1888_2176[1] ~= 72 or #grab_records_1888_2176[2] ~= 72 then
        error("reset_processed: the grab records are not two 72-word records", 0)
    end

    t5 = t7

    return t7
end

local t8 = {
    0, 0, 0, 0
}

function t1.reset_processed(p4) -- line: 160
    -- upvalues: t1 (copy), v8 (ref), v9 (copy), assign_into (copy), copy_into (copy), GrindInvestigationFields (copy), copy (copy), t2 (copy), v10 (ref), build_template (copy), t5 (ref), v13 (copy), build_plan (copy), t8 (copy)
    if v8 then
        return t1.reset_processed_reference(p4)
    end

    local v25 = v10 or build_template()
    local external_physics_1616, vectors_720_784_800_816_832_864 = p4.external_physics_1616, p4.vectors_720_784_800_816_832_864
    local v26 = vectors_720_784_800_816_832_864[5]
    local v28 = bit32.bor(8192, (bit32.band(p4.flags_2468, 8)))
    local v29 = bit32.band(p4.flags_2488, 2097151)

    external_physics_1616.flags = bit32.band(external_physics_1616.flags, 33554431)
    vectors_720_784_800_816_832_864[5] = t8

    for v30 in p4 do
        if v25[v30] == nil and not t2[v30] then
            p4[v30] = nil
        end
    end

    if v9.general() then
        for v31, v32 in v25 do
            if type(v32) == "table" then
                local v33 = p4[v31]

                if type(v33) == "table" then
                    assign_into(v33, v32)
                else
                    p4[v31] = copy(v32)
                end
            else
                p4[v31] = v32
            end
        end
    else
        local v34 = t5 or build_plan()
        local scalar_keys, scalar_values = v34.scalar_keys, v34.scalar_values

        for i = 1, #scalar_keys do
            p4[scalar_keys[i]] = scalar_values[i]
        end

        local vectors = v34.vectors

        for i = 1, #vectors do
            local v35 = vectors[i]

            copy_into(p4, v35, v25[v35])
        end

        local arrays = v34.arrays

        for i = 1, #arrays do
            local v36 = arrays[i]
            local v37 = v25[v36]
            local v38 = p4[v36]
            local v39 = #v37

            if type(v38) ~= "table" or #v38 ~= v39 then
                copy_into(p4, v36, v37)
            else
                for j = 1, v39 do
                    copy_into(v38, j, v37[j])
                end
            end
        end

        local others = v34.others

        for i = 1, #others do
            local v40 = others[i]

            copy_into(p4, v40, v25[v40])
        end

        local grind = p4.grind

        if type(grind) == "table" then
            GrindInvestigationFields.assign_into(grind, v25.grind)
        else
            p4.grind = copy(v25.grind)
        end

        local grab_records_1888_2176 = p4.grab_records_1888_2176

        if type(grab_records_1888_2176) ~= "table" or #grab_records_1888_2176 ~= 2 then
            copy_into(p4, "grab_records_1888_2176", v25.grab_records_1888_2176)
        else
            for i = 1, 2 do
                local v41 = grab_records_1888_2176[i]

                if type(v41) ~= "table" or #v41 ~= 72 then
                    copy_into(grab_records_1888_2176, i, v13)
                else
                    table.move(v13, 1, 72, 1, v41)
                end
            end
        end
    end

    p4.vectors_720_784_800_816_832_864[5] = v26
    p4.flags_2468 = v28
    p4.flags_2488 = v29
end

function t1.reset_processed_reference(p5) -- line: 253
    -- upvalues: rt (copy), v1 (copy), ProcessedPhysicsInput (copy)
    local v42 = rt.copy(p5.external_physics_1616)
    local v43 = rt.copy(p5.vectors_720_784_800_816_832_864[5])
    local v44 = ProcessedPhysicsInput.default()

    buffer.writef32(v1, 0, 1)

    local t9 = {
        buffer.readu32(v1, 0),
        0, 0, 0
    }

    buffer.writef32(v1, 0, 1)

    local t10 = {
        0,
        buffer.readu32(v1, 0),
        0, 0
    }

    buffer.writef32(v1, 0, 1)
    v44.effective_anim_transform_192 = {
        t9,
        t10,
        {
            0, 0,
            buffer.readu32(v1, 0),
            0
        },
        { 0, 0, 0, 0 }
    }
    v44.vector_1520 = rt.copy(p5.vector_1520)
    v44.matrix_1536 = rt.copy(p5.matrix_1536)
    v44.byte_1600 = p5.byte_1600
    v44.external_physics_1616 = v42
    v44.probe_1792 = rt.copy(p5.probe_1792)
    v44.flags_2468 = bit32.bor(8192, (bit32.band(p5.flags_2468, 8)))
    v44.flags_2488 = bit32.band(p5.flags_2488, 2097151)
    v44.state_variant_index_2528 = 1
    v44.grind_words_2532_2536 = { 4294967295, 0 }
    v44.timestep_2604 = 0.01666666753590107
    v44.gravity_2648 = -9.800000190734863
    v44.actor_query_2952 = 4294967295
    v44.external_physics_1616.flags = bit32.band(v44.external_physics_1616.flags, 33554431)

    local vectors_544_560_592_608 = v44.vectors_544_560_592_608

    buffer.writef32(v1, 0, 1)
    vectors_544_560_592_608[1] = {
        0,
        buffer.readu32(v1, 0),
        0, 0
    }
    v44.vectors_720_784_800_816_832_864[5] = v43
    rt.assign(p5, v44)
end

return t1
