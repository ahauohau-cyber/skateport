-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/contact")
local v2 = import("skate_core/physics/world_contact")
local combine_contact_materials = v1.combine_contact_materials
local PrimitivePairSettings, primitive_pair_contacts = v2.PrimitivePairSettings, v2.primitive_pair_contacts
local t1 = {}

local function append_reference(p1, p2, p3, p4, p5) -- line: 24
    -- upvalues: t1 (copy)
    local v3 = p4 >= 21 or p5.assembly_group >= 21

    if not v3 then
        for _, v4 in ipairs(p5.parts) do
            if v4.part_group >= 21 then
                v3 = true
                break
            end
        end
    end

    if v3 then
        error("Skater collision group is outside the original21x21 table", 0)
    end

    if t1.group_pair_allowed(p4, p5.assembly_group) then
        for _, v5 in ipairs(p2) do
            for _, v6 in ipairs(p3) do
                if v6.body.tag ~= "Attached" then
                    error("internal error: entered unreachable code", 0)
                end

                local v7 = v6.body[1]

                if t1.group_pair_allowed(p4, p5.parts[v7 + 1].part_group) then
                    t1.append_pair_reference(p1, v5, v6)
                end
            end
        end
    end

    for _, v8 in ipairs(p3) do
        if v8.body.tag ~= "Attached" then
            error("internal error: entered unreachable code", 0)
        end

        local v9 = v8.body[1]

        for _, v10 in ipairs(p3) do
            if v10.body.tag ~= "Attached" then
                error("internal error: entered unreachable code", 0)
            end

            local v11 = v10.body[1]

            if v9 ~= v11 and not p5.self_culling[v9 + 1][v11 + 1] then
                t1.append_pair_reference(p1, v8, v10)
            end
        end
    end
end

local t2 = {
    1603325, 0, 1179649, 1, 31185, 1079777, 1079793, 162289,
    1472240, 28929, 20737, 1050864, 1931249, 144369, 677873, 0,
    4096, 24964, 4352, 20481, 6501
}

function t1.group_pair_allowed(p6, p7) -- line: 85
    -- upvalues: t2 (copy)
    if p7 < 21 then
        local v12 = t2[p6 + 1]

        return v12 ~= nil and bit32.band(v12, (bit32.lshift(1, p7))) ~= 0
    end

    return false
end

function t1.append_pair_reference(p8, p9, p10) -- line: 97
    -- upvalues: rt (copy), combine_contact_materials (copy), PrimitivePairSettings (copy), primitive_pair_contacts (copy)
    local v14 = primitive_pair_contacts(p9.primitive, p10.primitive, PrimitivePairSettings.skater_self_collision())

    if v14 == nil then
        return
    end

    local v15 = combine_contact_materials(p9.material, p10.material)

    for i = 0, v14.count - 1 do
        local v16 = v14.points[i + 1]

        table.insert(p8, {
            body_a = rt.copy(p9.body),
            body_b = rt.copy(p10.body),
            contact = {
                tag = 0,
                position_on_a = rt.copy(v16.a),
                position_on_b = rt.copy(v16.b),
                normal = rt.copy(v14.normal),
                restitution = v15.restitution,
                static_friction = v15.static_friction,
                dynamic_friction = v15.dynamic_friction
            }
        })
    end
end

t1.append_reference = append_reference

local v17 = import("skate_core/physics/world_contact/primitive_pair")
local primitive_pair_contacts_flat, flat_points = v17.primitive_pair_contacts_flat, v17.flat_points
local pack = import("skate_core/physics/world_contact/primitive_geometry").pack
local t4 = {}
local n1 = 0

local function copy_body_into(p11, p12) -- line: 152
    p11.tag = p12.tag
    p11[1] = p12[1]
end

local function push_contacts(p13, p14, p15, p16, p17, p18, p19, p20) -- line: 157
    -- upvalues: rt (copy), combine_contact_materials (copy), flat_points (copy), t4 (copy), n1 (ref)
    local v18 = combine_contact_materials(p14.material, p15.material)

    for i = 0, p16 - 1 do
        local v19 = i * 6

        if p20 and n1 < 192 then
            n1 += 1

            local v20 = t4[n1]

            if v20 == nil then
                v20 = {
                    body_a = {},
                    body_b = {},
                    contact = {
                        restitution = 0,
                        static_friction = 0,
                        dynamic_friction = 0,
                        tag = 0,
                        position_on_a = {
                            x = 0,
                            y = 0,
                            z = 0
                        },
                        position_on_b = {
                            x = 0,
                            y = 0,
                            z = 0
                        },
                        normal = {
                            x = 0,
                            y = 0,
                            z = 0
                        }
                    }
                }
                t4[n1] = v20
            end

            local body_a = v20.body_a
            local body = p14.body

            body_a.tag = body.tag
            body_a[1] = body[1]

            local body_b = v20.body_b
            local body2 = p15.body

            body_b.tag = body2.tag
            body_b[1] = body2[1]

            local contact = v20.contact
            local position_on_a = contact.position_on_a
            local v21 = flat_points[v19 + 1]
            local v22 = flat_points[v19 + 2]
            local v23 = flat_points[v19 + 3]

            position_on_a.x = v21
            position_on_a.y = v22
            position_on_a.z = v23

            local position_on_b = contact.position_on_b
            local v24 = flat_points[v19 + 4]
            local v25 = flat_points[v19 + 5]
            local v26 = flat_points[v19 + 6]

            position_on_b.x = v24
            position_on_b.y = v25
            position_on_b.z = v26

            local normal = contact.normal

            normal.x = p17
            normal.y = p18
            normal.z = p19
            contact.restitution = v18.restitution
            contact.static_friction = v18.static_friction
            contact.dynamic_friction = v18.dynamic_friction
            contact.tag = 0
            table.insert(p13, v20)
            continue
        end

        table.insert(p13, {
            body_a = rt.copy(p14.body),
            body_b = rt.copy(p15.body),
            contact = {
                tag = 0,
                position_on_a = {
                    x = flat_points[v19 + 1],
                    y = flat_points[v19 + 2],
                    z = flat_points[v19 + 3]
                },
                position_on_b = {
                    x = flat_points[v19 + 4],
                    y = flat_points[v19 + 5],
                    z = flat_points[v19 + 6]
                },
                normal = {
                    x = p17,
                    y = p18,
                    z = p19
                },
                restitution = v18.restitution,
                static_friction = v18.static_friction,
                dynamic_friction = v18.dynamic_friction
            }
        })
    end
end

local function append_pair_impl(p21, p22, p23, p24) -- line: 216
    -- upvalues: PrimitivePairSettings (copy), primitive_pair_contacts_flat (copy), pack (copy), push_contacts (copy)
    local primitive = p22.primitive
    local primitive2 = p23.primitive
    local v27 = PrimitivePairSettings.skater_self_collision()
    local v28, v29 = pack(primitive)
    local v30, v31 = pack(primitive2)
    local v32, v33, v34, v35 = primitive_pair_contacts_flat(v28, v29, v30, v31, primitive, primitive2, v27)

    if v32 ~= nil then
        push_contacts(p21, p22, p23, v32, v33, v34, v35, p24)
    end
end

function t1.append_pair(p25, p26, p27) -- line: 230
    -- upvalues: append_pair_impl (copy)
    append_pair_impl(p25, p26, p27, false)
end

function t1.append_pair_pooled(p28, p29, p30) -- line: 239
    -- upvalues: append_pair_impl (copy)
    append_pair_impl(p28, p29, p30, true)
end

function t1.append_pair_packed(p31, p32, p33, p34, p35, p36, p37, p38) -- line: 253
    -- upvalues: primitive_pair_contacts_flat (copy), push_contacts (copy)
    local v36, v37, v38, v39 = primitive_pair_contacts_flat(p34, p35, p36, p37, p32.primitive, p33.primitive, p38)

    if v36 ~= nil then
        push_contacts(p31, p32, p33, v36, v37, v38, v39, true)
    end
end

t1.pack = pack
t1.pair_settings = PrimitivePairSettings.skater_self_collision

local t6 = {}
local t7 = {}
local t8 = {}
local t9 = {}

local function append_impl_r3(p39, p40, p41, p42, p43, p44) -- line: 282
    -- upvalues: PrimitivePairSettings (copy), t1 (copy), primitive_pair_contacts_flat (copy), pack (copy), push_contacts (copy), t6 (copy), t7 (copy), t8 (copy), t9 (copy)
    local v40 = p42 >= 21 or p43.assembly_group >= 21

    if not v40 then
        for _, v41 in ipairs(p43.parts) do
            if v41.part_group >= 21 then
                v40 = true
                break
            end
        end
    end

    if v40 then
        error("Skater collision group is outside the original21x21 table", 0)
    end

    table.clear(t9)
    table.clear(t6)
    table.clear(t7)
    table.clear(t8)

    local v42

    if t1.group_pair_allowed(p42, p43.assembly_group) then
        local v43

        for v44, v45 in ipairs(p40) do
            for v47, v48 in ipairs(p41) do
                if v48.body.tag ~= "Attached" then
                    error("internal error: entered unreachable code", 0)
                end

                local v49 = v48.body[1]

                if t1.group_pair_allowed(p42, p43.parts[v49 + 1].part_group) then
                    local primitive = v45.primitive
                    local primitive2 = v48.primitive

                    if v43 == nil then
                        v43 = PrimitivePairSettings.skater_self_collision()
                    end

                    local v50 = t9[v44]

                    if v50 == nil then
                        local v51

                        v50, v51 = pack(primitive)
                        t9[v44] = v50
                        t6[v44] = v51
                    end

                    local v52 = t7[v47]

                    if v52 == nil then
                        local v53

                        v52, v53 = pack(primitive2)
                        t7[v47] = v52
                        t8[v47] = v53
                    end

                    local v54, v55, v56, v57 = primitive_pair_contacts_flat(v50, t6[v44], v52, t8[v47], primitive, primitive2, v43)

                    if v54 ~= nil then
                        push_contacts(p39, v45, v48, v54, v55, v56, v57, p44)
                    end
                end
            end

            v42 = v43
        end
    end

    for v58, v59 in ipairs(p41) do
        if v59.body.tag ~= "Attached" then
            error("internal error: entered unreachable code", 0)
        end

        local v60 = v59.body[1]

        for v62, v63 in ipairs(p41) do
            if v63.body.tag ~= "Attached" then
                error("internal error: entered unreachable code", 0)
            end

            local v64 = v63.body[1]

            if v60 ~= v64 and not p43.self_culling[v60 + 1][v64 + 1] then
                local primitive = v59.primitive
                local primitive2 = v63.primitive

                if v42 == nil then
                    v42 = PrimitivePairSettings.skater_self_collision()
                end

                local v65 = t7[v58]

                if v65 == nil then
                    local v66

                    v65, v66 = pack(primitive)
                    t7[v58] = v65
                    t8[v58] = v66
                end

                local v67 = t7[v62]

                if v67 == nil then
                    local v68

                    v67, v68 = pack(primitive2)
                    t7[v62] = v67
                    t8[v62] = v68
                end

                local v69, v70, v71, v72 = primitive_pair_contacts_flat(v65, t8[v58], v67, t8[v62], primitive, primitive2, v42)

                if v69 ~= nil then
                    push_contacts(p39, v59, v63, v69, v70, v71, v72, p44)
                end
            end
        end
    end

    table.clear(t9)
    table.clear(t6)
    table.clear(t7)
    table.clear(t8)
end

local fix_up_triangle = import("skate_core/physics/collision").fix_up_triangle
local material_scalar_store = v1.material_scalar_store
local v73 = false

function t1.set_float_path(p45) -- line: 465
    -- upvalues: v73 (ref)
    local v74 = not v73

    v73 = not p45

    return v74
end

local v75

function t1.set_float_stats(p46) -- line: 472
    -- upvalues: v75 (ref)
    v75 = p46
end

local sqrt, abs = math.sqrt, math.abs
local v76 = buffer.create(8)
local to_bits = rt.to_bits

local function fr(p47) -- line: 483
    -- upvalues: v76 (copy), to_bits (copy)
    if p47 < 1.1754943508222875E-38 and p47 > -1.1754943508222875E-38 and p47 ~= 0 then
        buffer.writeu32(v76, 0, to_bits(p47))
    else
        buffer.writef32(v76, 0, p47)
    end

    return (buffer.readf32(v76, 0))
end

local v77 = false

function t1.set_vector_rounding(p48) -- line: 503
    -- upvalues: v77 (ref)
    local v78 = not v77

    v77 = not p48

    return v78
end

local create = vector.create

local function frv(p49) -- line: 509
    -- upvalues: v76 (copy), to_bits (copy), v77 (ref), create (copy)
    if v77 or p49 < 1.1754943508222875E-38 and p49 > -1.1754943508222875E-38 and p49 ~= 0 then
        if p49 < 1.1754943508222875E-38 and p49 > -1.1754943508222875E-38 and p49 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(p49))
        else
            buffer.writef32(v76, 0, p49)
        end

        return (buffer.readf32(v76, 0))
    end

    return create(p49, 0, 0).x
end

local function round3(p50, p51, p52) -- line: 515
    -- upvalues: v76 (copy), to_bits (copy), v77 (ref), create (copy)
    if v77 then
        if p50 < 1.1754943508222875E-38 and p50 > -1.1754943508222875E-38 and p50 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(p50))
        else
            buffer.writef32(v76, 0, p50)
        end

        local v79 = buffer.readf32(v76, 0)

        if p51 < 1.1754943508222875E-38 and p51 > -1.1754943508222875E-38 and p51 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(p51))
        else
            buffer.writef32(v76, 0, p51)
        end

        local v80 = buffer.readf32(v76, 0)

        if p52 < 1.1754943508222875E-38 and p52 > -1.1754943508222875E-38 and p52 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(p52))
        else
            buffer.writef32(v76, 0, p52)
        end

        return v79, v80, (buffer.readf32(v76, 0))
    end

    local v81 = create(p50, p51, p52)
    local x, y, z = v81.x, v81.y, v81.z
    local v82

    if not (p50 < 1.1754943508222875E-38) or not (p50 > -1.1754943508222875E-38) or p50 == 0 then
        v82 = x
    else
        if not (p50 < 1.1754943508222875E-38) or not (p50 > -1.1754943508222875E-38) or p50 == 0 then
            buffer.writef32(v76, 0, p50)
        else
            buffer.writeu32(v76, 0, to_bits(p50))
        end

        v82 = buffer.readf32(v76, 0)
    end

    local v83

    if not (p51 < 1.1754943508222875E-38) or not (p51 > -1.1754943508222875E-38) or p51 == 0 then
        v83 = y
    else
        if not (p51 < 1.1754943508222875E-38) or not (p51 > -1.1754943508222875E-38) or p51 == 0 then
            buffer.writef32(v76, 0, p51)
        else
            buffer.writeu32(v76, 0, to_bits(p51))
        end

        v83 = buffer.readf32(v76, 0)
    end

    local v84

    if not (p52 < 1.1754943508222875E-38) or not (p52 > -1.1754943508222875E-38) or p52 == 0 then
        v84 = z
    else
        if not (p52 < 1.1754943508222875E-38) or not (p52 > -1.1754943508222875E-38) or p52 == 0 then
            buffer.writef32(v76, 0, p52)
        else
            buffer.writeu32(v76, 0, to_bits(p52))
        end

        v84 = buffer.readf32(v76, 0)
    end

    return v82, v83, v84
end

t1.frv = frv
t1.round3 = round3

local function inverse_length(p53) -- line: 535
    -- upvalues: sqrt (copy)
    local v85 = 1 / sqrt(p53)
    local v86 = v85 * 0.5 * (-p53 * (v85 * v85) + 1) + v85

    return v86 * 0.5 * (-p53 * (v86 * v86) + 1) + v86
end

local t10 = {
    [0] = "?",
    "Sphere",
    "Capsule",
    "Triangle",
    "Box"
}

local function mirror_fill(p54, p55) -- line: 568
    -- upvalues: v76 (copy), to_bits (copy)
    local tag = p55.tag
    local v87, y, v88, vertices, edges, v89, y2, v90

    if tag == "Sphere" then
        v88 = p55[1]
        vertices = v88.center
        edges = vertices.x

        if edges < 1.1754943508222875E-38 and edges > -1.1754943508222875E-38 and edges ~= 0 then
            buffer.writeu32(v76, 0, to_bits(edges))
        else
            buffer.writef32(v76, 0, edges)
        end

        v87 = buffer.readf32(v76, 0)
        y = vertices.y

        if y < 1.1754943508222875E-38 and y > -1.1754943508222875E-38 and y ~= 0 then
            buffer.writeu32(v76, 0, to_bits(y))
        else
            buffer.writef32(v76, 0, y)
        end

        v89 = buffer.readf32(v76, 0)
        y2 = vertices.z

        if y2 < 1.1754943508222875E-38 and y2 > -1.1754943508222875E-38 and y2 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(y2))
        else
            buffer.writef32(v76, 0, y2)
        end

        v90 = buffer.readf32(v76, 0)
        p54[1] = v87
        p54[2] = v89
        p54[3] = v90
        edges = v88.radius

        if edges < 1.1754943508222875E-38 and edges > -1.1754943508222875E-38 and edges ~= 0 then
            buffer.writeu32(v76, 0, to_bits(edges))
        else
            buffer.writef32(v76, 0, edges)
        end

        p54[4] = buffer.readf32(v76, 0)

        return 1
    end

    if tag == "Capsule" then
        v88 = p55.center
        vertices = p55.axis
        edges = v88.x

        if edges < 1.1754943508222875E-38 and edges > -1.1754943508222875E-38 and edges ~= 0 then
            buffer.writeu32(v76, 0, to_bits(edges))
        else
            buffer.writef32(v76, 0, edges)
        end

        v87 = buffer.readf32(v76, 0)
        y = v88.y

        if y < 1.1754943508222875E-38 and y > -1.1754943508222875E-38 and y ~= 0 then
            buffer.writeu32(v76, 0, to_bits(y))
        else
            buffer.writef32(v76, 0, y)
        end

        v89 = buffer.readf32(v76, 0)
        y2 = v88.z

        if y2 < 1.1754943508222875E-38 and y2 > -1.1754943508222875E-38 and y2 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(y2))
        else
            buffer.writef32(v76, 0, y2)
        end

        v90 = buffer.readf32(v76, 0)
        p54[1] = v87
        p54[2] = v89
        p54[3] = v90
        edges = vertices.x

        if edges < 1.1754943508222875E-38 and edges > -1.1754943508222875E-38 and edges ~= 0 then
            buffer.writeu32(v76, 0, to_bits(edges))
        else
            buffer.writef32(v76, 0, edges)
        end

        v87 = buffer.readf32(v76, 0)
        y = vertices.y

        if y < 1.1754943508222875E-38 and y > -1.1754943508222875E-38 and y ~= 0 then
            buffer.writeu32(v76, 0, to_bits(y))
        else
            buffer.writef32(v76, 0, y)
        end

        v89 = buffer.readf32(v76, 0)
        y2 = vertices.z

        if y2 < 1.1754943508222875E-38 and y2 > -1.1754943508222875E-38 and y2 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(y2))
        else
            buffer.writef32(v76, 0, y2)
        end

        v90 = buffer.readf32(v76, 0)
        p54[5] = v87
        p54[6] = v89
        p54[7] = v90
        edges = p55.half_length

        if edges < 1.1754943508222875E-38 and edges > -1.1754943508222875E-38 and edges ~= 0 then
            buffer.writeu32(v76, 0, to_bits(edges))
        else
            buffer.writef32(v76, 0, edges)
        end

        p54[8] = buffer.readf32(v76, 0)
        edges = p55.radius

        if edges < 1.1754943508222875E-38 and edges > -1.1754943508222875E-38 and edges ~= 0 then
            buffer.writeu32(v76, 0, to_bits(edges))
        else
            buffer.writef32(v76, 0, edges)
        end

        p54[4] = buffer.readf32(v76, 0)

        return 2
    end

    local feature, v91, v92, v93

    if tag == "Triangle" then
        v88 = p55[1]
        vertices = v88.vertices
        feature = v88.feature
        edges = vertices[1]
        v92 = edges.x

        if v92 < 1.1754943508222875E-38 and v92 > -1.1754943508222875E-38 and v92 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v92))
        else
            buffer.writef32(v76, 0, v92)
        end

        local v94 = buffer.readf32(v76, 0)

        v92 = edges.y

        if v92 < 1.1754943508222875E-38 and v92 > -1.1754943508222875E-38 and v92 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v92))
        else
            buffer.writef32(v76, 0, v92)
        end

        local v95 = buffer.readf32(v76, 0)

        v92 = edges.z

        if v92 < 1.1754943508222875E-38 and v92 > -1.1754943508222875E-38 and v92 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v92))
        else
            buffer.writef32(v76, 0, v92)
        end

        local v96 = buffer.readf32(v76, 0)

        edges = feature.normal
        v93 = edges.x

        if v93 < 1.1754943508222875E-38 and v93 > -1.1754943508222875E-38 and v93 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v93))
        else
            buffer.writef32(v76, 0, v93)
        end

        v91 = buffer.readf32(v76, 0)
        v93 = edges.y

        if v93 < 1.1754943508222875E-38 and v93 > -1.1754943508222875E-38 and v93 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v93))
        else
            buffer.writef32(v76, 0, v93)
        end

        local v97 = buffer.readf32(v76, 0)

        v93 = edges.z

        if v93 < 1.1754943508222875E-38 and v93 > -1.1754943508222875E-38 and v93 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v93))
        else
            buffer.writef32(v76, 0, v93)
        end

        local v98 = buffer.readf32(v76, 0)

        edges = vertices[2]

        local y = edges.x

        if y < 1.1754943508222875E-38 and y > -1.1754943508222875E-38 and y ~= 0 then
            buffer.writeu32(v76, 0, to_bits(y))
        else
            buffer.writef32(v76, 0, y)
        end

        local v99 = buffer.readf32(v76, 0)

        y = edges.y

        if y < 1.1754943508222875E-38 and y > -1.1754943508222875E-38 and y ~= 0 then
            buffer.writeu32(v76, 0, to_bits(y))
        else
            buffer.writef32(v76, 0, y)
        end

        local v100 = buffer.readf32(v76, 0)

        y = edges.z

        if y < 1.1754943508222875E-38 and y > -1.1754943508222875E-38 and y ~= 0 then
            buffer.writeu32(v76, 0, to_bits(y))
        else
            buffer.writef32(v76, 0, y)
        end

        local v101 = buffer.readf32(v76, 0)

        edges = vertices[3]

        local edge_cosines = edges.x

        if edge_cosines < 1.1754943508222875E-38 and edge_cosines > -1.1754943508222875E-38 and edge_cosines ~= 0 then
            buffer.writeu32(v76, 0, to_bits(edge_cosines))
        else
            buffer.writef32(v76, 0, edge_cosines)
        end

        local v102 = buffer.readf32(v76, 0)

        edge_cosines = edges.y

        if edge_cosines < 1.1754943508222875E-38 and edge_cosines > -1.1754943508222875E-38 and edge_cosines ~= 0 then
            buffer.writeu32(v76, 0, to_bits(edge_cosines))
        else
            buffer.writef32(v76, 0, edge_cosines)
        end

        local v103 = buffer.readf32(v76, 0)

        edge_cosines = edges.z

        if edge_cosines < 1.1754943508222875E-38 and edge_cosines > -1.1754943508222875E-38 and edge_cosines ~= 0 then
            buffer.writeu32(v76, 0, to_bits(edge_cosines))
        else
            buffer.writef32(v76, 0, edge_cosines)
        end

        local v104 = buffer.readf32(v76, 0)

        p54[1] = v94
        p54[2] = v95
        p54[3] = v96
        p54[5] = v91
        p54[6] = v97
        p54[7] = v98
        p54[8] = v99
        p54[9] = v100
        p54[10] = v101
        p54[11] = v102
        p54[12] = v103
        p54[13] = v104
        edges = feature.edges
        vertices = v88.edge_lengths
        edge_cosines = feature.edge_cosines

        for i = 0, 2 do
            feature = edges[i + 1]

            local v105 = i * 3 + 14
            local v106 = v105 + 1
            local v107 = v105 + 2
            local x = feature.x

            if x < 1.1754943508222875E-38 and x > -1.1754943508222875E-38 and x ~= 0 then
                buffer.writeu32(v76, 0, to_bits(x))
            else
                buffer.writef32(v76, 0, x)
            end

            local v108 = buffer.readf32(v76, 0)
            local y = feature.y

            if y < 1.1754943508222875E-38 and y > -1.1754943508222875E-38 and y ~= 0 then
                buffer.writeu32(v76, 0, to_bits(y))
            else
                buffer.writef32(v76, 0, y)
            end

            local v109 = buffer.readf32(v76, 0)
            local z = feature.z

            if z < 1.1754943508222875E-38 and z > -1.1754943508222875E-38 and z ~= 0 then
                buffer.writeu32(v76, 0, to_bits(z))
            else
                buffer.writef32(v76, 0, z)
            end

            local v110 = buffer.readf32(v76, 0)

            p54[v105] = v108
            p54[v106] = v109
            p54[v107] = v110
            v106 = i + 23

            local v111 = vertices[i + 1]

            if v111 < 1.1754943508222875E-38 and v111 > -1.1754943508222875E-38 and v111 ~= 0 then
                buffer.writeu32(v76, 0, to_bits(v111))
            else
                buffer.writef32(v76, 0, v111)
            end

            p54[v106] = buffer.readf32(v76, 0)
            v106 = edge_cosines[i + 1]

            if v106 < 1.1754943508222875E-38 and v106 > -1.1754943508222875E-38 and v106 ~= 0 then
                buffer.writeu32(v76, 0, to_bits(v106))
            else
                buffer.writef32(v76, 0, v106)
            end

            buffer.readf32(v76, 0)
        end

        local v112 = v88.fatness

        if v112 < 1.1754943508222875E-38 and v112 > -1.1754943508222875E-38 and v112 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v112))
        else
            buffer.writef32(v76, 0, v112)
        end

        p54[4] = buffer.readf32(v76, 0)
        edge_cosines = v94 * v91 + v95 * v97 + v96 * v98
        v90 = v99 * v91 + v100 * v97 + v101 * v98

        local v113 = v102 * v91 + v103 * v97 + v104 * v98

        v112 = if edge_cosines < v90 then edge_cosines else v90

        if not (v90 < edge_cosines) then
            edge_cosines = v90
        end

        if not (v112 < v113) then
            v112 = v113
        end

        if v112 < 1.1754943508222875E-38 and v112 > -1.1754943508222875E-38 and v112 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v112))
        else
            buffer.writef32(v76, 0, v112)
        end

        p54[26] = buffer.readf32(v76, 0)

        if not (v113 < edge_cosines) then
            edge_cosines = v113
        end

        if edge_cosines < 1.1754943508222875E-38 and edge_cosines > -1.1754943508222875E-38 and edge_cosines ~= 0 then
            buffer.writeu32(v76, 0, to_bits(edge_cosines))
        else
            buffer.writef32(v76, 0, edge_cosines)
        end

        p54[27] = buffer.readf32(v76, 0)
        p54[28] = 0
        p54[29] = 0

        return 3
    end

    if tag == "RoundedBox" then
        v88 = p55.center
        vertices = p55.basis
        feature = p55.half_extents
        v87 = v88.x

        if v87 < 1.1754943508222875E-38 and v87 > -1.1754943508222875E-38 and v87 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v87))
        else
            buffer.writef32(v76, 0, v87)
        end

        v89 = buffer.readf32(v76, 0)
        y2 = v88.y

        if y2 < 1.1754943508222875E-38 and y2 > -1.1754943508222875E-38 and y2 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(y2))
        else
            buffer.writef32(v76, 0, y2)
        end

        v90 = buffer.readf32(v76, 0)

        local z = v88.z

        if z < 1.1754943508222875E-38 and z > -1.1754943508222875E-38 and z ~= 0 then
            buffer.writeu32(v76, 0, to_bits(z))
        else
            buffer.writef32(v76, 0, z)
        end

        v92 = buffer.readf32(v76, 0)
        p54[1] = v89
        p54[2] = v90
        p54[3] = v92
        v90 = feature.x

        if v90 < 1.1754943508222875E-38 and v90 > -1.1754943508222875E-38 and v90 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v90))
        else
            buffer.writef32(v76, 0, v90)
        end

        v92 = buffer.readf32(v76, 0)
        v90 = feature.y

        if v90 < 1.1754943508222875E-38 and v90 > -1.1754943508222875E-38 and v90 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v90))
        else
            buffer.writef32(v76, 0, v90)
        end

        local v114 = buffer.readf32(v76, 0)

        v90 = feature.z

        if v90 < 1.1754943508222875E-38 and v90 > -1.1754943508222875E-38 and v90 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v90))
        else
            buffer.writef32(v76, 0, v90)
        end

        local v115 = buffer.readf32(v76, 0)

        feature = vertices.columns
        vertices = feature[1]

        local v116 = vertices[1]

        if v116 < 1.1754943508222875E-38 and v116 > -1.1754943508222875E-38 and v116 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v116))
        else
            buffer.writef32(v76, 0, v116)
        end

        v93 = buffer.readf32(v76, 0)
        v116 = vertices[2]

        if v116 < 1.1754943508222875E-38 and v116 > -1.1754943508222875E-38 and v116 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v116))
        else
            buffer.writef32(v76, 0, v116)
        end

        local v117 = buffer.readf32(v76, 0)

        v116 = vertices[3]

        if v116 < 1.1754943508222875E-38 and v116 > -1.1754943508222875E-38 and v116 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v116))
        else
            buffer.writef32(v76, 0, v116)
        end

        local v118 = buffer.readf32(v76, 0)

        p54[5] = v93
        p54[6] = v117
        p54[7] = v118
        v116 = v93 * v92
        v93 = v117 * v92
        v91 = v118 * v92
        p54[17] = v116
        p54[18] = v93
        p54[19] = v91
        vertices = feature[2]
        v116 = vertices[1]

        if v116 < 1.1754943508222875E-38 and v116 > -1.1754943508222875E-38 and v116 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v116))
        else
            buffer.writef32(v76, 0, v116)
        end

        v93 = buffer.readf32(v76, 0)
        v116 = vertices[2]

        if v116 < 1.1754943508222875E-38 and v116 > -1.1754943508222875E-38 and v116 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v116))
        else
            buffer.writef32(v76, 0, v116)
        end

        v117 = buffer.readf32(v76, 0)
        v116 = vertices[3]

        if v116 < 1.1754943508222875E-38 and v116 > -1.1754943508222875E-38 and v116 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v116))
        else
            buffer.writef32(v76, 0, v116)
        end

        v118 = buffer.readf32(v76, 0)
        p54[8] = v93
        p54[9] = v117
        p54[10] = v118
        v116 = v93 * v114
        v93 = v117 * v114
        v91 = v118 * v114
        p54[20] = v116
        p54[21] = v93
        p54[22] = v91
        vertices = feature[3]
        v116 = vertices[1]

        if v116 < 1.1754943508222875E-38 and v116 > -1.1754943508222875E-38 and v116 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v116))
        else
            buffer.writef32(v76, 0, v116)
        end

        v93 = buffer.readf32(v76, 0)
        v116 = vertices[2]

        if v116 < 1.1754943508222875E-38 and v116 > -1.1754943508222875E-38 and v116 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v116))
        else
            buffer.writef32(v76, 0, v116)
        end

        v117 = buffer.readf32(v76, 0)
        v116 = vertices[3]

        if v116 < 1.1754943508222875E-38 and v116 > -1.1754943508222875E-38 and v116 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v116))
        else
            buffer.writef32(v76, 0, v116)
        end

        v118 = buffer.readf32(v76, 0)
        p54[11] = v93
        p54[12] = v117
        p54[13] = v118
        v116 = v93 * v115
        v93 = v117 * v115
        v91 = v118 * v115
        p54[23] = v116
        p54[24] = v93
        p54[25] = v91
        p54[14] = v92
        p54[15] = v114
        p54[16] = v115
        v93 = p55.radius

        if v93 < 1.1754943508222875E-38 and v93 > -1.1754943508222875E-38 and v93 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v93))
        else
            buffer.writef32(v76, 0, v93)
        end

        p54[4] = buffer.readf32(v76, 0)

        return 4
    end

    error("unreachable: ContactPrimitive " .. tostring(tag), 0)
end

local function mirror_of(p56, p57) -- line: 648
    -- upvalues: pack (copy), mirror_fill (copy)
    local ok, result = pcall(mirror_fill, p56, p57)

    if ok then
        return result
    end

    pack(p57)

    return 0
end

local v119 = table.create(15, 0)

local function pair_sphere_sphere(p58, p59, p60) -- line: 663
    -- upvalues: sqrt (copy), v76 (copy), to_bits (copy), v77 (ref), create (copy), round3 (copy), v119 (copy)
    local v120 = p58[1]
    local v121 = p58[2]
    local v122 = p58[3]
    local v123 = p59[1]
    local v124 = p59[2]
    local v125 = p59[3]
    local v126 = v123 - v120
    local v127 = v124 - v121
    local v128 = v125 - v122
    local v129 = v126 * v126 + v127 * v127 + v128 * v128
    local v130

    if not v77 and (not (v129 < 1.1754943508222875E-38) or not (v129 > -1.1754943508222875E-38) or v129 == 0) then
        v130 = create(v129, 0, 0).x
    else
        if v129 < 1.1754943508222875E-38 and v129 > -1.1754943508222875E-38 and v129 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v129))
        else
            buffer.writef32(v76, 0, v129)
        end

        v130 = buffer.readf32(v76, 0)
    end

    local v131 = 1 / sqrt(v130)
    local v132 = v131 * 0.5 * (-v130 * (v131 * v131) + 1) + v131
    local v133 = v132 * 0.5 * (-v130 * (v132 * v132) + 1) + v132
    local v134 = if v130 == 0 then 0 else v130 * v133
    local v135

    if not v77 and (not (v134 < 1.1754943508222875E-38) or not (v134 > -1.1754943508222875E-38) or v134 == 0) then
        v135 = create(v134, 0, 0).x
    else
        if v134 < 1.1754943508222875E-38 and v134 > -1.1754943508222875E-38 and v134 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v134))
        else
            buffer.writef32(v76, 0, v134)
        end

        v135 = buffer.readf32(v76, 0)
    end

    local v136 = p58[4]
    local v137 = p59[4]

    if v137 + p60 + v136 < v135 then
        return 0
    end

    local v138, v139, v140 = round3(v126 * v133, v127 * v133, v128 * v133)
    local v141 = v138
    local v142 = v139
    local v143 = v140

    if v134 > 1.1920928955078125E-07 then
        local v144 = v120 * v138 + v121 * v139 + v122 * v140
        local v145

        if v77 then
            if not (v144 < 1.1754943508222875E-38) or not (v144 > -1.1754943508222875E-38) or v144 == 0 then
                buffer.writef32(v76, 0, v144)
            else
                buffer.writeu32(v76, 0, to_bits(v144))
            end

            v145 = buffer.readf32(v76, 0)
        elseif not (v144 < 1.1754943508222875E-38) or not (v144 > -1.1754943508222875E-38) or v144 == 0 then
            v145 = create(v144, 0, 0).x
        else
            if not (v144 < 1.1754943508222875E-38) or not (v144 > -1.1754943508222875E-38) or v144 == 0 then
                buffer.writef32(v76, 0, v144)
            else
                buffer.writeu32(v76, 0, to_bits(v144))
            end

            v145 = buffer.readf32(v76, 0)
        end

        local v146 = v123 * v138 + v124 * v139 + v125 * v140
        local v147

        if not v77 and (not (v146 < 1.1754943508222875E-38) or not (v146 > -1.1754943508222875E-38) or v146 == 0) then
            v147 = create(v146, 0, 0).x
        else
            if v146 < 1.1754943508222875E-38 and v146 > -1.1754943508222875E-38 and v146 ~= 0 then
                buffer.writeu32(v76, 0, to_bits(v146))
            else
                buffer.writef32(v76, 0, v146)
            end

            v147 = buffer.readf32(v76, 0)
        end

        local v148 = v145 - v147
        local v149 = v147 - v145

        if v149 < v148 then
            if v135 <= v148 then
                v141 = -v138
                v142 = -v139
                v143 = -v140
            end
        elseif v135 <= v149 then
        end
    end

    v119[1] = v120 + v141 * v136
    v119[2] = v121 + v142 * v136
    v119[3] = v122 + v143 * v136
    v119[4] = v123 - v141 * v137
    v119[5] = v124 - v142 * v137
    v119[6] = v125 - v143 * v137

    local v150 = -v141
    local v151 = -v142
    local v152 = -v143

    v119[7] = v150
    v119[8] = v151
    v119[9] = v152

    return 1
end

local function pair_sphere_capsule(p61, p62, p63, p64) -- line: 712
    -- upvalues: sqrt (copy), abs (copy), v76 (copy), to_bits (copy), v77 (ref), create (copy), round3 (copy), v119 (copy)
    local v153 = p61[1]
    local v154 = p61[2]
    local v155 = p61[3]
    local v156 = p62[1]
    local v157 = p62[2]
    local v158 = p62[3]
    local v159 = if p64 then p61 else p62
    local v160 = v159[5]
    local v161 = v159[6]
    local v162 = v159[7]
    local v163 = v159[8]
    local v164 = v153 - v156
    local v165 = v154 - v157
    local v166 = v155 - v158
    local v167 = -v166 * v161 + v165 * v162
    local v168 = -v164 * v162 + v166 * v160
    local v169 = -v165 * v160 + v164 * v161
    local v170 = -v169 * v161 + v168 * v162
    local v171 = -v167 * v162 + v169 * v160
    local v172 = -v168 * v160 + v167 * v161
    local v173 = v170 * v170 + v171 * v171 + v172 * v172
    local v174

    if not v77 and (not (v173 < 1.1754943508222875E-38) or not (v173 > -1.1754943508222875E-38) or v173 == 0) then
        v174 = create(v173, 0, 0).x
    else
        if v173 < 1.1754943508222875E-38 and v173 > -1.1754943508222875E-38 and v173 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v173))
        else
            buffer.writef32(v76, 0, v173)
        end

        v174 = buffer.readf32(v76, 0)
    end

    local v175

    if v174 == 0 then
        v175 = 0
    else
        local v176 = 1 / sqrt(v174)
        local v177 = v176 * 0.5 * (-v174 * (v176 * v176) + 1) + v176

        v175 = v174 * (v177 * 0.5 * (-v174 * (v177 * v177) + 1) + v177)
    end

    if not (v175 > 1.1920928955078125E-07) then
        return 2
    end

    local v178 = 1 / sqrt(v173)
    local v179 = v178 * 0.5 * (-v173 * (v178 * v178) + 1) + v178
    local v180 = v179 * 0.5 * (-v173 * (v179 * v179) + 1) + v179
    local v181, v182, v183 = round3(v170 * v180, v171 * v180, v172 * v180)
    local v184 = v153 * v181 + v154 * v182 + v155 * v183
    local v185 = v156 * v181 + v157 * v182 + v158 * v183
    local v187 = abs(v160 * v181 + v161 * v182 + v162 * v183) * v163
    local v188, v189

    if p64 then
        local v190, v191, v192 = round3(v185, v184 - v187, v184 + v187)

        v189 = v191 - v190
        v188 = v190 - v192
    else
        local v193, v194, v195 = round3(v184, v185 + v187, v185 - v187)

        v189 = v193 - v194
        v188 = v195 - v193
    end

    local v196 = v188 < v189

    if not v196 then
        v189 = v188
    end

    local v197

    if not v77 and (not (v189 < 1.1754943508222875E-38) or not (v189 > -1.1754943508222875E-38) or v189 == 0) then
        v197 = create(v189, 0, 0).x
    else
        if v189 < 1.1754943508222875E-38 and v189 > -1.1754943508222875E-38 and v189 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v189))
        else
            buffer.writef32(v76, 0, v189)
        end

        v197 = buffer.readf32(v76, 0)
    end

    local v198 = p61[4]
    local v199 = p62[4]

    if v199 + p63 + v198 < v197 then
        return 0
    end

    if v196 then
        v181 = -v181
        v182 = -v182
        v183 = -v183
    end

    local v201 = if p64 then v153 else v156
    local v202 = if p64 then v154 else v157
    local v203 = if p64 then v155 else v158
    local v204 = if p64 then v156 else v153
    local v205 = if p64 then v157 else v154
    local v206 = if p64 then v158 else v155
    local v200 = if p64 then v160 * v181 + v161 * v182 + v162 * v183 else v160 * -v181 + v161 * -v182 + v162 * -v183

    if not (abs(v200) < 0.05000000074505806) then
        return 2
    end

    local v207 = v160 * v163
    local v208 = v161 * v163
    local v209 = v162 * v163
    local v210, v211, v212 = round3(v201 + v207, v202 + v208, v203 + v209)
    local v213, v214, v215 = round3(v201 - v207, v202 - v208, v203 - v209)
    local v216 = v213 - v210
    local v217 = v214 - v211
    local v218 = v215 - v212
    local v219 = v216 * v216 + v217 * v217 + v218 * v218
    local v220

    if not v77 and (not (v219 < 1.1754943508222875E-38) or not (v219 > -1.1754943508222875E-38) or v219 == 0) then
        v220 = create(v219, 0, 0).x
    else
        if v219 < 1.1754943508222875E-38 and v219 > -1.1754943508222875E-38 and v219 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v219))
        else
            buffer.writef32(v76, 0, v219)
        end

        v220 = buffer.readf32(v76, 0)
    end

    local v221 = 1 / sqrt(v220)
    local v222 = v221 * 0.5 * (-v220 * (v221 * v221) + 1) + v221
    local v223 = if not (v220 > 1.1920928955078125E-07) then 0 elseif v220 == 0 then 0 else v220 * v222
    local v224

    if not v77 and (not (v223 < 1.1754943508222875E-38) or not (v223 > -1.1754943508222875E-38) or v223 == 0) then
        v224 = create(v223, 0, 0).x
    else
        if v223 < 1.1754943508222875E-38 and v223 > -1.1754943508222875E-38 and v223 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v223))
        else
            buffer.writef32(v76, 0, v223)
        end

        v224 = buffer.readf32(v76, 0)
    end

    local v225 = 1 / v223
    local v226 = v225 * (-v225 * v223 + 1) + v225
    local v227, v228, v229

    if v220 > 1.1920928955078125E-07 then
        v227, v228, v229 = round3(v216 * v226, v217 * v226, v218 * v226)
    else
        v227 = 0
        v228 = 0
        v229 = 0
    end

    local v230 = (v204 - v210) * v227 + (v205 - v211) * v228 + (v206 - v212) * v229

    if not (v230 < 0) then
        if v224 < v230 then
            v210, v211, v212 = round3(v227 * v224 + v210, v228 * v224 + v211, v229 * v224 + v212)
        else
            v210, v211, v212 = round3(v227 * v230 + v210, v228 * v230 + v211, v229 * v230 + v212)
        end
    end

    local v231, v232, v233

    if p64 then
        v233 = v158
        v231 = v156
        v232 = v157
    else
        v210, v211, v212, v231, v232, v233 = v153, v154, v155, v210, v211, v212
    end

    local v234 = v231 - v210
    local v235 = v232 - v211
    local v236 = v233 - v212
    local v237 = v234 * v234 + v235 * v235 + v236 * v236
    local v238

    if not v77 and (not (v237 < 1.1754943508222875E-38) or not (v237 > -1.1754943508222875E-38) or v237 == 0) then
        v238 = create(v237, 0, 0).x
    else
        if v237 < 1.1754943508222875E-38 and v237 > -1.1754943508222875E-38 and v237 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v237))
        else
            buffer.writef32(v76, 0, v237)
        end

        v238 = buffer.readf32(v76, 0)
    end

    local v239 = 1 / sqrt(v238)
    local v240 = v239 * 0.5 * (-v238 * (v239 * v239) + 1) + v239
    local v241 = v240 * 0.5 * (-v238 * (v240 * v240) + 1) + v240
    local v242 = if v238 == 0 then 0 else v238 * v241
    local v243 = v181
    local v244 = v182
    local v245 = v183

    if v242 > 1.1920928955078125E-07 then
        local v246, v247, v248 = round3(v234 * v241, v235 * v241, v236 * v241)
        local v249 = v153 * v246 + v154 * v247 + v155 * v248
        local v250 = v156 * v246 + v157 * v247 + v158 * v248
        local v252 = abs(v160 * v246 + v161 * v247 + v162 * v248) * v163
        local v253, v254

        if p64 then
            local v255, v256, v257 = round3(v250, v249 - v252, v249 + v252)

            v254 = v256 - v255
            v253 = v255 - v257
        else
            local v258, v259, v260 = round3(v249, v250 + v252, v250 - v252)

            v254 = v258 - v259
            v253 = v260 - v258
        end

        if v253 < v254 then
            if v197 <= v254 then
                v243 = -v246
                v244 = -v247
                v245 = -v248
            end
        elseif v197 <= v253 then
            v245 = v248
            v243 = v246
            v244 = v247
        end
    end

    v119[1] = v210 + v243 * v198
    v119[2] = v211 + v244 * v198
    v119[3] = v212 + v245 * v198
    v119[4] = v231 - v243 * v199
    v119[5] = v232 - v244 * v199
    v119[6] = v233 - v245 * v199

    local v261 = -v243
    local v262 = -v244
    local v263 = -v245

    v119[7] = v261
    v119[8] = v262
    v119[9] = v263

    return 1
end

local function face_into(p65, p66, p67, p68, p69, p70) -- line: 865
    -- upvalues: sqrt (copy), round3 (copy)
    if (if p70 < 0 then 1 else 0) == 1 then
        local v264 = p66 + 1
        local v265 = p66 + 2
        local v266 = p66 + 3
        local v267 = p65[1]
        local v268 = p65[2]
        local v269 = p65[3]

        p65[v264] = v267
        p65[v265] = v268
        p65[v266] = v269

        local v270 = p66 + 4
        local v271 = p66 + 5
        local v272 = p66 + 6
        local v273 = p65[14]
        local v274 = p65[15]
        local v275 = p65[16]

        p65[v270] = v273
        p65[v271] = v274
        p65[v272] = v275
        p65[p66 + 10] = p65[23]

        local v276 = p66 + 11
        local v277 = p66 + 12
        local v278 = p66 + 13
        local v279 = p65[11]
        local v280 = p65[12]
        local v281 = p65[13]

        p65[v276] = v279
        p65[v277] = v280
        p65[v278] = v281

        local v282 = p66 + 14
        local v283 = p66 + 15
        local v284 = p66 + 16
        local v285 = p65[17]
        local v286 = p65[18]
        local v287 = p65[19]

        p65[v282] = v285
        p65[v283] = v286
        p65[v284] = v287
        p65[p66 + 20] = p65[24]

        local v288 = p66 + 21
        local v289 = p66 + 22
        local v290 = p66 + 23
        local v291 = p65[8]
        local v292 = p65[9]
        local v293 = p65[10]

        p65[v288] = v291
        p65[v289] = v292
        p65[v290] = v293

        local v294 = p66 + 24
        local v295 = p66 + 25
        local v296 = p66 + 26
        local v297 = p65[20]
        local v298 = p65[21]
        local v299 = p65[22]

        p65[v294] = v297
        p65[v295] = v298
        p65[v296] = v299
        p65[p66 + 30] = p65[25]
    else
        local v300 = p66 + 1
        local v301 = p66 + 2
        local v302 = p66 + 3
        local v303 = p65[1]
        local v304 = p65[2]
        local v305 = p65[3]

        p65[v300] = v303
        p65[v301] = v304
        p65[v302] = v305

        local v306 = p66 + 4
        local v307 = p66 + 5
        local v308 = p66 + 6
        local v309 = -p65[20]
        local v310 = -p65[21]
        local v311 = -p65[22]

        p65[v306] = v309
        p65[v307] = v310
        p65[v308] = v311
        p65[p66 + 10] = p65[25]

        local v312 = p66 + 11
        local v313 = p66 + 12
        local v314 = p66 + 13
        local v315 = p65[8]
        local v316 = p65[9]
        local v317 = p65[10]

        p65[v312] = v315
        p65[v313] = v316
        p65[v314] = v317

        local v318 = p66 + 14
        local v319 = p66 + 15
        local v320 = p66 + 16
        local v321 = -p65[17]
        local v322 = -p65[18]
        local v323 = -p65[19]

        p65[v318] = v321
        p65[v319] = v322
        p65[v320] = v323
        p65[p66 + 20] = p65[24]

        local v324 = p66 + 21
        local v325 = p66 + 22
        local v326 = p66 + 23
        local v327 = p65[11]
        local v328 = p65[12]
        local v329 = p65[13]

        p65[v324] = v327
        p65[v325] = v328
        p65[v326] = v329

        local v330 = p66 + 24
        local v331 = p66 + 25
        local v332 = p66 + 26
        local v333 = -p65[14]
        local v334 = -p65[15]
        local v335 = -p65[16]

        p65[v330] = v333
        p65[v331] = v334
        p65[v332] = v335
        p65[p66 + 30] = p65[23]
    end

    for i = p66, p66 + 20, 10 do
        local v336 = p65[i + 4]
        local v337 = p65[i + 5]
        local v338 = p65[i + 6]
        local v339 = -v338 * p68 + v337 * p69
        local v340 = -v336 * p69 + v338 * p67
        local v341 = -v337 * p67 + v336 * p68
        local v342 = v339 * v339 + v340 * v340 + v341 * v341
        local v343 = 1 / sqrt(v342)
        local v344 = v343 * 0.5 * (-v342 * (v343 * v343) + 1) + v343

        if not (v342 > 1.1920928955078125E-07) then
            v344 = 0
        end

        local v345 = i + 8
        local v346 = i + 9
        local v347, v348, v349 = round3(v339 * v344, v340 * v344, v341 * v344)

        p65[i + 7] = v347
        p65[v345] = v348
        p65[v346] = v349
    end
end

local function build_face(p71, p72) -- line: 907
    -- upvalues: abs (copy), face_into (copy)
    local v350 = p71[5]
    local v351 = p71[6]
    local v352 = p71[7]
    local v353, v354, v355

    if p72 then
        v353 = -v350
        v354 = -v351
        v355 = -v352
    else
        v355 = v352
        v353 = v350
        v354 = v351
    end

    local v356 = v353 * v350 + v354 * v351 + v355 * v352

    if abs(v356) > 0.949999988079071 then
        face_into(p71, p72 and 60 or 30, v353, v354, v355, v356)

        if p72 then
            p71[29] = 1
        else
            p71[28] = 1
        end

        return 1
    end

    if p72 then
        p71[29] = 2
    else
        p71[28] = 2
    end

    return 2
end

local function face_point(p73, p74, p75, p76, p77, p78, p79, p80) -- line: 934
    -- upvalues: round3 (copy)
    local v357 = p75 * (p73[p74 + 1] - p78) + p76 * (p73[p74 + 2] - p79) + p77 * (p73[p74 + 3] - p80)
    local v358 = p75 * v357 + p78
    local v359 = p76 * v357 + p79
    local v360 = p77 * v357 + p80
    local v361 = p73[p74 + 7] * (v358 - p73[p74 + 1]) + p73[p74 + 8] * (v359 - p73[p74 + 2]) + p73[p74 + 9] * (v360 - p73[p74 + 3])
    local v362 = p73[p74 + 17] * (v358 - p73[p74 + 11]) + p73[p74 + 18] * (v359 - p73[p74 + 12]) + p73[p74 + 19] * (v360 - p73[p74 + 13])
    local v363

    if v361 < v362 then
        v363 = p74 + 10
    else
        v362 = v361
        v363 = p74
    end

    local v364 = p73[p74 + 27] * (v358 - p73[p74 + 21]) + p73[p74 + 28] * (v359 - p73[p74 + 22]) + p73[p74 + 29] * (v360 - p73[p74 + 23])

    if v362 < v364 then
        v363 = p74 + 20
    else
        v364 = v362
    end

    if not (v364 > 0) then
        return round3(v358, v359, v360)
    end

    local v365, v366, v367 = round3(v358 - p73[v363 + 7] * v364, v359 - p73[v363 + 8] * v364, v360 - p73[v363 + 9] * v364)
    local v368 = p73[v363 + 1]
    local v369 = p73[v363 + 2]
    local v370 = p73[v363 + 3]
    local v371 = p73[v363 + 4]
    local v372 = p73[v363 + 5]
    local v373 = p73[v363 + 6]
    local v374 = (v365 - v368) * v371 + (v366 - v369) * v372 + (v367 - v370) * v373

    if v374 < 0 then
        return v368, v369, v370
    end

    local v375 = p73[v363 + 10]

    if v375 < v374 then
        return round3(v371 * v375 + v368, v372 * v375 + v369, v373 * v375 + v370)
    end

    return round3(v371 * v374 + v368, v372 * v374 + v369, v373 * v374 + v370)
end

local t11 = {
    x = 0,
    y = 0,
    z = 0
}
local t12 = {
    x = 0,
    y = 0,
    z = 0
}
local t13 = {
    a = t11,
    b = t12
}
local t14 = {
    t13
}
local t15 = {
    x = 0,
    y = 0,
    z = 0
}
local t16 = {
    reverse = false,
    edge_cos_bend_normal_threshold = 0,
    convexity_epsilon = 0,
    is_object = false
}
local v376 = false

function t1.set_shared_kernels(p81) -- line: 1005
    -- upvalues: v376 (ref)
    local v377 = not v376

    v376 = not p81

    return v377
end

local v378 = import("skate_core/physics/world_contact/primitive_query")
local fix_up_toward, segment_face_xyz = v378.fix_up_toward, v378.segment_face_xyz
local v379 = table.create(49, 0)

local function feature_floats(p82) -- line: 1015
    -- upvalues: v379 (copy)
    local normal = p82.normal
    local x, y, z = normal.x, normal.y, normal.z

    v379[34] = x
    v379[35] = y
    v379[36] = z

    local edges = p82.edges
    local v380 = edges[1]
    local x2, y2, z2 = v380.x, v380.y, v380.z

    v379[37] = x2
    v379[38] = y2
    v379[39] = z2

    local v381 = edges[2]
    local x3, y3, z3 = v381.x, v381.y, v381.z

    v379[40] = x3
    v379[41] = y3
    v379[42] = z3

    local v382 = edges[3]
    local x4, y4, z4 = v382.x, v382.y, v382.z

    v379[43] = x4
    v379[44] = y4
    v379[45] = z4

    local edge_cosines = p82.edge_cosines
    local v383 = edge_cosines[1]
    local v384 = edge_cosines[2]
    local v385 = edge_cosines[3]

    v379[46] = v383
    v379[47] = v384
    v379[48] = v385
    v379[49] = p82.flags

    return v379
end

local t17 = {
    x = 0,
    y = 0,
    z = 0
}
local t18 = {
    x = 0,
    y = 0,
    z = 0
}
local t19 = {
    a = t17,
    b = t18
}
local t20 = {
    t13,
    t19
}

local function triangle_tail(p83, p84, p85, p86, p87, p88, p89, p90, p91, p92, p93, p94, p95) -- line: 1036
    -- upvalues: fix_up_triangle (copy), v119 (copy), t11 (copy), t12 (copy), t13 (copy), t14 (copy), t15 (copy), t16 (copy), v376 (ref), fix_up_toward (copy), feature_floats (copy)
    if not v376 then
        local v386 = fix_up_toward(feature_floats(p83), p91, p92, p93, p84)

        if v386 == 0 then
            return 0
        end

        if v386 == 1 then
            v119[1] = p85 + p91 * p94
            v119[2] = p86 + p92 * p94
            v119[3] = p87 + p93 * p94
            v119[4] = p88 - p91 * p95
            v119[5] = p89 - p92 * p95
            v119[6] = p90 - p93 * p95

            local v387 = -p91
            local v388 = -p92
            local v389 = -p93

            v119[7] = v387
            v119[8] = v388
            v119[9] = v389

            return 1
        end
    end

    t11.x = p85
    t11.y = p86
    t11.z = p87
    t12.x = p88
    t12.y = p89
    t12.z = p90
    t13.a = t11
    t13.b = t12
    t15.x = p91
    t15.y = p92
    t15.z = p93
    t16.reverse = false
    t16.edge_cos_bend_normal_threshold = p84.edge_cos_bend_normal_threshold
    t16.convexity_epsilon = p84.convexity_epsilon
    t16.is_object = false

    if not fix_up_triangle(p83, t15, t14, t16) then
        return 0
    end

    local x, y, z = t15.x, t15.y, t15.z
    local a, b = t13.a, t13.b

    v119[1] = a.x + x * p94
    v119[2] = a.y + y * p94
    v119[3] = a.z + z * p94
    v119[4] = b.x - x * p95
    v119[5] = b.y - y * p95
    v119[6] = b.z - z * p95

    local v390 = -x
    local v391 = -y
    local v392 = -z

    v119[7] = v390
    v119[8] = v391
    v119[9] = v392

    return 1
end

local function triangle_tail2(p96, p97, p98, p99, p100, p101, p102, p103, p104, p105, p106, p107, p108, p109, p110, p111, p112, p113, p114) -- line: 1088
    -- upvalues: fix_up_triangle (copy), v119 (copy), t11 (copy), t12 (copy), t13 (copy), t15 (copy), t16 (copy), fix_up_toward (copy), feature_floats (copy), t17 (copy), t18 (copy), t19 (copy), t20 (copy)
    local v393 = fix_up_toward(feature_floats(p96), p110, p111, p112, p97)

    if v393 == 0 then
        return 0
    end

    if v393 == 1 then
        local v394 = p110 * p113
        local v395 = p111 * p113
        local v396 = p112 * p113
        local v397 = p110 * p114
        local v398 = p111 * p114
        local v399 = p112 * p114
        local v400 = p98 + v394
        local v401 = p99 + v395
        local v402 = p100 + v396

        v119[1] = v400
        v119[2] = v401
        v119[3] = v402

        local v403 = p101 - v397
        local v404 = p102 - v398
        local v405 = p103 - v399

        v119[4] = v403
        v119[5] = v404
        v119[6] = v405

        local v406 = -p110
        local v407 = -p111
        local v408 = -p112

        v119[7] = v406
        v119[8] = v407
        v119[9] = v408

        local v409 = p104 + v394
        local v410 = p105 + v395
        local v411 = p106 + v396

        v119[10] = v409
        v119[11] = v410
        v119[12] = v411

        local v412 = p107 - v397
        local v413 = p108 - v398
        local v414 = p109 - v399

        v119[13] = v412
        v119[14] = v413
        v119[15] = v414
    else
        t11.x = p98
        t11.y = p99
        t11.z = p100
        t12.x = p101
        t12.y = p102
        t12.z = p103
        t13.a = t11
        t13.b = t12
        t17.x = p104
        t17.y = p105
        t17.z = p106
        t18.x = p107
        t18.y = p108
        t18.z = p109
        t19.a = t17
        t19.b = t18
        t15.x = p110
        t15.y = p111
        t15.z = p112
        t16.reverse = false
        t16.edge_cos_bend_normal_threshold = p97.edge_cos_bend_normal_threshold
        t16.convexity_epsilon = p97.convexity_epsilon
        t16.is_object = false

        if not fix_up_triangle(p96, t15, t20, t16) then
            return 0
        end

        local x, y, z = t15.x, t15.y, t15.z
        local v415 = x * p113
        local v416 = y * p113
        local v417 = z * p113
        local v418 = x * p114
        local v419 = y * p114
        local v420 = z * p114
        local a, b = t13.a, t13.b
        local v421 = a.x + v415
        local v422 = a.y + v416
        local v423 = a.z + v417

        v119[1] = v421
        v119[2] = v422
        v119[3] = v423

        local v424 = b.x - v418
        local v425 = b.y - v419
        local v426 = b.z - v420

        v119[4] = v424
        v119[5] = v425
        v119[6] = v426

        local v427 = -x
        local v428 = -y
        local v429 = -z

        v119[7] = v427
        v119[8] = v428
        v119[9] = v429

        local a2, b2 = t19.a, t19.b
        local v430 = a2.x + v415
        local v431 = a2.y + v416
        local v432 = a2.z + v417

        v119[10] = v430
        v119[11] = v431
        v119[12] = v432

        local v433 = b2.x - v418
        local v434 = b2.y - v419
        local v435 = b2.z - v420

        v119[13] = v433
        v119[14] = v434
        v119[15] = v435
    end

    return 3
end

local function pair_triangle_sphere(p115, p116, p117, p118, p119) -- line: 1152
    -- upvalues: sqrt (copy), v76 (copy), to_bits (copy), v77 (ref), create (copy), round3 (copy), build_face (copy), face_point (copy), triangle_tail (copy)
    local v436 = p115[5]
    local v437 = p115[6]
    local v438 = p115[7]
    local v439 = p116[1]
    local v440 = p116[2]
    local v441 = p116[3]
    local v442 = v439 * v436 + v440 * v437 + v441 * v438
    local v443

    if not v77 and (not (v442 < 1.1754943508222875E-38) or not (v442 > -1.1754943508222875E-38) or v442 == 0) then
        v443 = create(v442, 0, 0).x
    else
        if v442 < 1.1754943508222875E-38 and v442 > -1.1754943508222875E-38 and v442 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v442))
        else
            buffer.writef32(v76, 0, v442)
        end

        v443 = buffer.readf32(v76, 0)
    end

    local v444 = p115[26] - v443
    local v445 = v443 - p115[27]
    local v446 = v445 < v444

    if not v446 then
        v444 = v445
    end

    local v447

    if not v77 and (not (v444 < 1.1754943508222875E-38) or not (v444 > -1.1754943508222875E-38) or v444 == 0) then
        v447 = create(v444, 0, 0).x
    else
        if v444 < 1.1754943508222875E-38 and v444 > -1.1754943508222875E-38 and v444 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v444))
        else
            buffer.writef32(v76, 0, v444)
        end

        v447 = buffer.readf32(v76, 0)
    end

    local v448 = p115[4]
    local v449 = p116[4]

    if v449 + p117 + v448 < v447 then
        return 0
    end

    local v450, v451

    if v446 then
        v451 = 60
        v450 = p115[29]
        v436 = -v436
        v437 = -v437
        v438 = -v438
    else
        v451 = 30
        v450 = p115[28]
    end

    if v450 == 0 then
        v450 = build_face(p115, v446)
    end

    if v450 ~= 1 then
        return 2
    end

    local v452, v453, v454 = face_point(p115, v451, v436, v437, v438, v439, v440, v441)
    local v455 = v439 - v452
    local v456 = v440 - v453
    local v457 = v441 - v454
    local v458 = v455 * v455 + v456 * v456 + v457 * v457
    local v459

    if not v77 and (not (v458 < 1.1754943508222875E-38) or not (v458 > -1.1754943508222875E-38) or v458 == 0) then
        v459 = create(v458, 0, 0).x
    else
        if v458 < 1.1754943508222875E-38 and v458 > -1.1754943508222875E-38 and v458 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v458))
        else
            buffer.writef32(v76, 0, v458)
        end

        v459 = buffer.readf32(v76, 0)
    end

    local v460 = 1 / sqrt(v459)
    local v461 = v460 * 0.5 * (-v459 * (v460 * v460) + 1) + v460
    local v462 = v461 * 0.5 * (-v459 * (v461 * v461) + 1) + v461
    local v463 = if v459 == 0 then 0 else v459 * v462
    local v464 = v436
    local v465 = v437
    local v466 = v438

    if v463 > 1.1920928955078125E-07 then
        local v467, v468, v469 = round3(v455 * v462, v456 * v462, v457 * v462)
        local v470 = p115[1] * v467 + p115[2] * v468 + p115[3] * v469
        local v471 = p115[8] * v467 + p115[9] * v468 + p115[10] * v469
        local v472 = p115[11] * v467 + p115[12] * v468 + p115[13] * v469
        local v473 = if v470 < v471 then v470 else v471

        if not (v471 < v470) then
            v470 = v471
        end

        local v474 = v439 * v467 + v440 * v468 + v441 * v469

        if not (v473 < v472) then
            v473 = v472
        end

        if not (v472 < v470) then
            v470 = v472
        end

        local v475, v476, v477 = round3(v474, v473, v470)
        local v478 = v476 - v475
        local v479 = v475 - v477

        if v479 < v478 then
            if v447 <= v478 then
                v464 = -v467
                v465 = -v468
                v466 = -v469
            end
        elseif v447 <= v479 then
            v466 = v469
            v464 = v467
            v465 = v468
        end
    end

    return (triangle_tail(p118, p119, v452, v453, v454, v439, v440, v441, v464, v465, v466, v448, v449))
end

local function capsule_feature(p120, p121, p122, p123) -- line: 1220
    -- upvalues: sqrt (copy), abs (copy), v76 (copy), to_bits (copy), v77 (ref), create (copy), round3 (copy)
    local v480 = p120[5]
    local v481 = p120[6]
    local v482 = p120[7]
    local v483 = p120[8]
    local v484 = p120[1]
    local v485 = p120[2]
    local v486 = p120[3]
    local v487 = v480 * p121 + v481 * p122 + v482 * p123

    if abs(v487) < 0.05000000074505806 then
        local v488 = v480 * v483
        local v489 = v481 * v483
        local v490 = v482 * v483
        local v491, v492, v493 = round3(v484 + v488, v485 + v489, v486 + v490)
        local v494, v495, v496 = round3(v484 - v488, v485 - v489, v486 - v490)
        local v497 = v494 - v491
        local v498 = v495 - v492
        local v499 = v496 - v493
        local v500 = v497 * v497 + v498 * v498 + v499 * v499
        local v501

        if not v77 and (not (v500 < 1.1754943508222875E-38) or not (v500 > -1.1754943508222875E-38) or v500 == 0) then
            v501 = create(v500, 0, 0).x
        else
            if v500 < 1.1754943508222875E-38 and v500 > -1.1754943508222875E-38 and v500 ~= 0 then
                buffer.writeu32(v76, 0, to_bits(v500))
            else
                buffer.writef32(v76, 0, v500)
            end

            v501 = buffer.readf32(v76, 0)
        end

        local v502 = 1 / sqrt(v501)
        local v503 = v502 * 0.5 * (-v501 * (v502 * v502) + 1) + v502
        local v504 = if not (v501 > 1.1920928955078125E-07) then 0 elseif v501 == 0 then 0 else v501 * v503
        local v505 = 1 / v504
        local v506 = v505 * (-v505 * v504 + 1) + v505

        if not (v501 > 1.1920928955078125E-07) then
            if not (v77 or v504 < 1.1754943508222875E-38 and v504 > -1.1754943508222875E-38 and v504 ~= 0) then
                return 1, v491, v492, v493, 0, 0, 0, create(v504, 0, 0).x
            end

            if v504 < 1.1754943508222875E-38 and v504 > -1.1754943508222875E-38 and v504 ~= 0 then
                buffer.writeu32(v76, 0, to_bits(v504))
            else
                buffer.writef32(v76, 0, v504)
            end

            return 1, v491, v492, v493, 0, 0, 0, (buffer.readf32(v76, 0))
        end

        local v507 = v497 * v506
        local v508

        if v77 then
            if not (v507 < 1.1754943508222875E-38) or not (v507 > -1.1754943508222875E-38) or v507 == 0 then
                buffer.writef32(v76, 0, v507)
            else
                buffer.writeu32(v76, 0, to_bits(v507))
            end

            v508 = buffer.readf32(v76, 0)
        elseif not (v507 < 1.1754943508222875E-38) or not (v507 > -1.1754943508222875E-38) or v507 == 0 then
            v508 = create(v507, 0, 0).x
        else
            if not (v507 < 1.1754943508222875E-38) or not (v507 > -1.1754943508222875E-38) or v507 == 0 then
                buffer.writef32(v76, 0, v507)
            else
                buffer.writeu32(v76, 0, to_bits(v507))
            end

            v508 = buffer.readf32(v76, 0)
        end

        local v509 = v498 * v506
        local v510

        if not v77 and (not (v509 < 1.1754943508222875E-38) or not (v509 > -1.1754943508222875E-38) or v509 == 0) then
            v510 = create(v509, 0, 0).x
        else
            if v509 < 1.1754943508222875E-38 and v509 > -1.1754943508222875E-38 and v509 ~= 0 then
                buffer.writeu32(v76, 0, to_bits(v509))
            else
                buffer.writef32(v76, 0, v509)
            end

            v510 = buffer.readf32(v76, 0)
        end

        local v511 = v499 * v506
        local v512

        if not v77 and (not (v511 < 1.1754943508222875E-38) or not (v511 > -1.1754943508222875E-38) or v511 == 0) then
            v512 = create(v511, 0, 0).x
        else
            if v511 < 1.1754943508222875E-38 and v511 > -1.1754943508222875E-38 and v511 ~= 0 then
                buffer.writeu32(v76, 0, to_bits(v511))
            else
                buffer.writef32(v76, 0, v511)
            end

            v512 = buffer.readf32(v76, 0)
        end

        if not (v77 or v504 < 1.1754943508222875E-38 and v504 > -1.1754943508222875E-38 and v504 ~= 0) then
            return 1, v491, v492, v493, v508, v510, v512, create(v504, 0, 0).x
        end

        if v504 < 1.1754943508222875E-38 and v504 > -1.1754943508222875E-38 and v504 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v504))
        else
            buffer.writef32(v76, 0, v504)
        end

        return 1, v491, v492, v493, v508, v510, v512, (buffer.readf32(v76, 0))
    end

    if v487 > 0 then
        local v513 = v480 * v483 + v484
        local v514

        if not v77 and (not (v513 < 1.1754943508222875E-38) or not (v513 > -1.1754943508222875E-38) or v513 == 0) then
            v514 = create(v513, 0, 0).x
        else
            if v513 < 1.1754943508222875E-38 and v513 > -1.1754943508222875E-38 and v513 ~= 0 then
                buffer.writeu32(v76, 0, to_bits(v513))
            else
                buffer.writef32(v76, 0, v513)
            end

            v514 = buffer.readf32(v76, 0)
        end

        local v515 = v481 * v483 + v485
        local v516

        if not v77 and (not (v515 < 1.1754943508222875E-38) or not (v515 > -1.1754943508222875E-38) or v515 == 0) then
            v516 = create(v515, 0, 0).x
        else
            if v515 < 1.1754943508222875E-38 and v515 > -1.1754943508222875E-38 and v515 ~= 0 then
                buffer.writeu32(v76, 0, to_bits(v515))
            else
                buffer.writef32(v76, 0, v515)
            end

            v516 = buffer.readf32(v76, 0)
        end

        local v517 = v482 * v483 + v486
        local v518

        if not v77 and (not (v517 < 1.1754943508222875E-38) or not (v517 > -1.1754943508222875E-38) or v517 == 0) then
            v518 = create(v517, 0, 0).x
        else
            if v517 < 1.1754943508222875E-38 and v517 > -1.1754943508222875E-38 and v517 ~= 0 then
                buffer.writeu32(v76, 0, to_bits(v517))
            else
                buffer.writef32(v76, 0, v517)
            end

            v518 = buffer.readf32(v76, 0)
        end

        return 0, v514, v516, v518, 0, 0, 0, 0
    end

    local v519 = v484 - v480 * v483
    local v520

    if not v77 and (not (v519 < 1.1754943508222875E-38) or not (v519 > -1.1754943508222875E-38) or v519 == 0) then
        v520 = create(v519, 0, 0).x
    else
        if v519 < 1.1754943508222875E-38 and v519 > -1.1754943508222875E-38 and v519 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v519))
        else
            buffer.writef32(v76, 0, v519)
        end

        v520 = buffer.readf32(v76, 0)
    end

    local v521 = v485 - v481 * v483
    local v522

    if not v77 and (not (v521 < 1.1754943508222875E-38) or not (v521 > -1.1754943508222875E-38) or v521 == 0) then
        v522 = create(v521, 0, 0).x
    else
        if v521 < 1.1754943508222875E-38 and v521 > -1.1754943508222875E-38 and v521 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v521))
        else
            buffer.writef32(v76, 0, v521)
        end

        v522 = buffer.readf32(v76, 0)
    end

    local v523 = v486 - v482 * v483
    local v524

    if not v77 and (not (v523 < 1.1754943508222875E-38) or not (v523 > -1.1754943508222875E-38) or v523 == 0) then
        v524 = create(v523, 0, 0).x
    else
        if v523 < 1.1754943508222875E-38 and v523 > -1.1754943508222875E-38 and v523 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v523))
        else
            buffer.writef32(v76, 0, v523)
        end

        v524 = buffer.readf32(v76, 0)
    end

    return 0, v520, v522, v524, 0, 0, 0, 0
end

local function closest_on_segment(p124, p125, p126, p127, p128, p129, p130, p131, p132, p133) -- line: 1254
    -- upvalues: round3 (copy)
    local v525 = (p131 - p124) * p127 + (p132 - p125) * p128 + (p133 - p126) * p129

    if v525 < 0 then
        return p124, p125, p126
    end

    if p130 < v525 then
        return round3(p127 * p130 + p124, p128 * p130 + p125, p129 * p130 + p126)
    end

    return round3(p127 * v525 + p124, p128 * v525 + p125, p129 * v525 + p126)
end

local function segment_segment(p134, p135, p136, p137, p138, p139, p140, p141, p142, p143, p144, p145, p146, p147) -- line: 1268
    -- upvalues: sqrt (copy), v76 (copy), to_bits (copy), v77 (ref), create (copy), closest_on_segment (copy)
    local v526 = -p139 * p145 + p138 * p146
    local v527 = -p137 * p146 + p139 * p144
    local v528 = -p138 * p144 + p137 * p145
    local v529 = v526 * v526 + v527 * v527 + v528 * v528

    if not (v529 > 1.1920928955078125E-07) then
        return false, 0, 0, 0, 0, 0, 0
    end

    local v530 = 1 / sqrt(v529)
    local v531 = v530 * 0.5 * (-v529 * (v530 * v530) + 1) + v530
    local v532 = v531 * 0.5 * (-v529 * (v531 * v531) + 1) + v531
    local v533 = v526 * v532
    local v534 = v527 * v532
    local v535 = v528 * v532
    local v536 = -v535 * p145 + v534 * p146
    local v537 = -v533 * p146 + v535 * p144
    local v538 = -v534 * p144 + v533 * p145
    local v539 = ((p141 - p134) * v536 + (p142 - p135) * v537 + (p143 - p136) * v538) / (p137 * v536 + p138 * v537 + p139 * v538)

    if v539 < 0 then
        v539 = 0
    end

    if p140 < v539 then
        v539 = p140
    end

    local v540 = p137 * v539 + p134
    local v541

    if not v77 and (not (v540 < 1.1754943508222875E-38) or not (v540 > -1.1754943508222875E-38) or v540 == 0) then
        v541 = create(v540, 0, 0).x
    else
        if v540 < 1.1754943508222875E-38 and v540 > -1.1754943508222875E-38 and v540 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v540))
        else
            buffer.writef32(v76, 0, v540)
        end

        v541 = buffer.readf32(v76, 0)
    end

    local v542 = p138 * v539 + p135
    local v543

    if not v77 and (not (v542 < 1.1754943508222875E-38) or not (v542 > -1.1754943508222875E-38) or v542 == 0) then
        v543 = create(v542, 0, 0).x
    else
        if v542 < 1.1754943508222875E-38 and v542 > -1.1754943508222875E-38 and v542 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v542))
        else
            buffer.writef32(v76, 0, v542)
        end

        v543 = buffer.readf32(v76, 0)
    end

    local v544 = p139 * v539 + p136
    local v545

    if not v77 and (not (v544 < 1.1754943508222875E-38) or not (v544 > -1.1754943508222875E-38) or v544 == 0) then
        v545 = create(v544, 0, 0).x
    else
        if v544 < 1.1754943508222875E-38 and v544 > -1.1754943508222875E-38 and v544 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v544))
        else
            buffer.writef32(v76, 0, v544)
        end

        v545 = buffer.readf32(v76, 0)
    end

    local v546, v547, v548 = closest_on_segment(p141, p142, p143, p144, p145, p146, p147, v541, v543, v545)
    local v549, v550, v551 = closest_on_segment(p134, p135, p136, p137, p138, p139, p140, v546, v547, v548)

    return true, v549, v550, v551, v546, v547, v548
end

local function capsule_capsule_separation(p148, p149, p150, p151, p152) -- line: 1300
    -- upvalues: abs (copy), v76 (copy), to_bits (copy), v77 (ref), create (copy), round3 (copy)
    local v552 = p148[1] * p150 + p148[2] * p151 + p148[3] * p152
    local v554 = abs(p148[5] * p150 + p148[6] * p151 + p148[7] * p152) * p148[8]
    local v555 = p149[1] * p150 + p149[2] * p151 + p149[3] * p152
    local v557 = abs(p149[5] * p150 + p149[6] * p151 + p149[7] * p152) * p149[8]
    local v558, v559, v560 = round3(v552 - v554, v555 + v557, v555 - v557)
    local v561 = v558 - v559
    local v562 = v552 + v554
    local v563

    if not v77 and (not (v562 < 1.1754943508222875E-38) or not (v562 > -1.1754943508222875E-38) or v562 == 0) then
        v563 = create(v562, 0, 0).x
    else
        if v562 < 1.1754943508222875E-38 and v562 > -1.1754943508222875E-38 and v562 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v562))
        else
            buffer.writef32(v76, 0, v562)
        end

        v563 = buffer.readf32(v76, 0)
    end

    local v564 = v560 - v563

    if v564 < v561 then
        return v561, true
    end

    return v564, false
end

local function pair_capsule_capsule(p153, p154, p155) -- line: 1322
    -- upvalues: sqrt (copy), v76 (copy), to_bits (copy), v77 (ref), create (copy), round3 (copy), v119 (copy), capsule_feature (copy), closest_on_segment (copy), segment_segment (copy), capsule_capsule_separation (copy)
    local v565 = p153[5]
    local v566 = p153[6]
    local v567 = p153[7]
    local v568 = p154[5]
    local v569 = p154[6]
    local v570 = p154[7]
    local v571 = -v567 * v569 + v566 * v570
    local v572 = -v565 * v570 + v567 * v568
    local v573 = -v566 * v568 + v565 * v569
    local v574 = v571 * v571 + v572 * v572 + v573 * v573
    local v575 = p153[4]
    local v576 = p154[4]
    local v577 = v576 + p155 + v575
    local v578, v579, v580, v581, v582, v583

    if v574 > 0.0010000000474974513 then
        local v584 = 1 / sqrt(v574)
        local v585 = v584 * 0.5 * (-v574 * (v584 * v584) + 1) + v584
        local v586 = v585 * 0.5 * (-v574 * (v585 * v585) + 1) + v585

        v578, v579, v580 = round3(v571 * v586, v572 * v586, v573 * v586)
        v581, v582 = capsule_capsule_separation(p153, p154, v578, v579, v580)

        if v581 ~= v581 then
            return 2
        end

        local v587

        if v77 then
            if not (v581 < 1.1754943508222875E-38) or not (v581 > -1.1754943508222875E-38) or v581 == 0 then
                buffer.writef32(v76, 0, v581)
            else
                buffer.writeu32(v76, 0, to_bits(v581))
            end

            v587 = buffer.readf32(v76, 0)
        elseif not (v581 < 1.1754943508222875E-38) or not (v581 > -1.1754943508222875E-38) or v581 == 0 then
            v587 = create(v581, 0, 0).x
        else
            if not (v581 < 1.1754943508222875E-38) or not (v581 > -1.1754943508222875E-38) or v581 == 0 then
                buffer.writef32(v76, 0, v581)
            else
                buffer.writeu32(v76, 0, to_bits(v581))
            end

            v587 = buffer.readf32(v76, 0)
        end

        if v577 < v587 then
            return 0
        end

        v583 = false
    else
        v583 = true
        v581 = 0
        v582 = false
        v578 = 0
        v579 = 0
        v580 = 0
    end

    local v588

    if not v77 and (not (v574 < 1.1754943508222875E-38) or not (v574 > -1.1754943508222875E-38) or v574 == 0) then
        v588 = create(v574, 0, 0).x
    else
        if v574 < 1.1754943508222875E-38 and v574 > -1.1754943508222875E-38 and v574 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v574))
        else
            buffer.writef32(v76, 0, v574)
        end

        v588 = buffer.readf32(v76, 0)
    end

    local v589

    if v588 == 0 then
        v589 = 0
    else
        local v590 = 1 / sqrt(v588)
        local v591 = v590 * 0.5 * (-v588 * (v590 * v590) + 1) + v590

        v589 = v588 * (v591 * 0.5 * (-v588 * (v591 * v591) + 1) + v591)
    end

    local v592, v593, v594, v595, v596

    if v589 > 1.1920928955078125E-07 then
        local v597 = -v567 * v572 + v566 * v573
        local v598 = -v565 * v573 + v567 * v571
        local v599 = -v566 * v571 + v565 * v572
        local v600 = v597 * v597 + v598 * v598 + v599 * v599
        local v601 = 1 / sqrt(v600)
        local v602 = v601 * 0.5 * (-v600 * (v601 * v601) + 1) + v601
        local v603 = v602 * 0.5 * (-v600 * (v602 * v602) + 1) + v602
        local v604, v605, v606 = round3(v597 * v603, v598 * v603, v599 * v603)
        local v607, v608 = capsule_capsule_separation(p153, p154, v604, v605, v606)

        if v583 then
            if v607 ~= v607 then
                return 2
            end

            v581 = v607
            v583 = false
        elseif v581 < v607 then
            v581 = v607
        else
            v606 = v580
            v608 = v582
            v604 = v578
            v605 = v579
        end

        local v609

        if not v77 and (not (v607 < 1.1754943508222875E-38) or not (v607 > -1.1754943508222875E-38) or v607 == 0) then
            v609 = create(v607, 0, 0).x
        else
            if v607 < 1.1754943508222875E-38 and v607 > -1.1754943508222875E-38 and v607 ~= 0 then
                buffer.writeu32(v76, 0, to_bits(v607))
            else
                buffer.writef32(v76, 0, v607)
            end

            v609 = buffer.readf32(v76, 0)
        end

        if v577 < v609 then
            return 0
        end

        local v610 = -v570 * v572 + v569 * v573
        local v611 = -v568 * v573 + v570 * v571
        local v612 = -v569 * v571 + v568 * v572
        local v613 = v610 * v610 + v611 * v611 + v612 * v612
        local v614 = 1 / sqrt(v613)
        local v615 = v614 * 0.5 * (-v613 * (v614 * v614) + 1) + v614
        local v616 = v615 * 0.5 * (-v613 * (v615 * v615) + 1) + v615

        v592, v593, v594 = round3(v610 * v616, v611 * v616, v612 * v616)

        local v617

        v617, v595 = capsule_capsule_separation(p153, p154, v592, v593, v594)

        if v581 < v617 then
            v596 = v617
        else
            v594 = v606
            v596 = v581
            v595 = v608
            v592 = v604
            v593 = v605
        end

        local v618

        if not v77 and (not (v617 < 1.1754943508222875E-38) or not (v617 > -1.1754943508222875E-38) or v617 == 0) then
            v618 = create(v617, 0, 0).x
        else
            if v617 < 1.1754943508222875E-38 and v617 > -1.1754943508222875E-38 and v617 ~= 0 then
                buffer.writeu32(v76, 0, to_bits(v617))
            else
                buffer.writef32(v76, 0, v617)
            end

            v618 = buffer.readf32(v76, 0)
        end

        if v577 < v618 then
            return 0
        end
    else
        v594 = v580
        v596 = v581
        v595 = v582
        v592 = v578
        v593 = v579
    end

    if v583 then
        return 2
    end

    local v619

    if not v77 and (not (v596 < 1.1754943508222875E-38) or not (v596 > -1.1754943508222875E-38) or v596 == 0) then
        v619 = create(v596, 0, 0).x
    else
        if v596 < 1.1754943508222875E-38 and v596 > -1.1754943508222875E-38 and v596 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v596))
        else
            buffer.writef32(v76, 0, v596)
        end

        v619 = buffer.readf32(v76, 0)
    end

    if v595 then
        v592 = -v592
        v593 = -v593
        v594 = -v594
    end

    local v620, v621, v622, v623, v624, v625, v626, v627 = capsule_feature(p153, v592, v593, v594)
    local v628, v629, v630, v631, v632, v633, v634, v635 = capsule_feature(p154, -v592, -v593, -v594)

    if v620 == 0 then
        if v628 ~= 0 then
            v629, v630, v631 = closest_on_segment(v629, v630, v631, v632, v633, v634, v635, v621, v622, v623)
        end
    elseif v628 == 0 then
        v621, v622, v623 = closest_on_segment(v621, v622, v623, v624, v625, v626, v627, v629, v630, v631)
    else
        local v636

        v636, v621, v622, v623, v629, v630, v631 = segment_segment(v621, v622, v623, v624, v625, v626, v627, v629, v630, v631, v632, v633, v634, v635)

        if not v636 then
            return 2
        end
    end

    local v637 = v629 - v621
    local v638 = v630 - v622
    local v639 = v631 - v623
    local v640 = v637 * v637 + v638 * v638 + v639 * v639
    local v641

    if not v77 and (not (v640 < 1.1754943508222875E-38) or not (v640 > -1.1754943508222875E-38) or v640 == 0) then
        v641 = create(v640, 0, 0).x
    else
        if v640 < 1.1754943508222875E-38 and v640 > -1.1754943508222875E-38 and v640 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v640))
        else
            buffer.writef32(v76, 0, v640)
        end

        v641 = buffer.readf32(v76, 0)
    end

    local v642 = 1 / sqrt(v641)
    local v643 = v642 * 0.5 * (-v641 * (v642 * v642) + 1) + v642
    local v644 = v643 * 0.5 * (-v641 * (v643 * v643) + 1) + v643
    local v645 = if v641 == 0 then 0 else v641 * v644
    local v646 = v592
    local v647 = v593
    local v648 = v594

    if v645 > 1.1920928955078125E-07 then
        v646, v647, v648 = round3(v637 * v644, v638 * v644, v639 * v644)

        local v649, v650 = capsule_capsule_separation(p153, p154, v646, v647, v648)

        if v619 <= v649 then
            if v650 then
                v646 = -v646
                v647 = -v647
                v648 = -v648
            end
        else
            v648 = v594
            v646 = v592
            v647 = v593
        end
    end

    v119[1] = v621 + v646 * v575
    v119[2] = v622 + v647 * v575
    v119[3] = v623 + v648 * v575
    v119[4] = v629 - v646 * v576
    v119[5] = v630 - v647 * v576
    v119[6] = v631 - v648 * v576

    local v651 = -v646
    local v652 = -v647
    local v653 = -v648

    v119[7] = v651
    v119[8] = v652
    v119[9] = v653

    return 1
end

local function pair_triangle_capsule(p156, p157, p158, p159, p160) -- line: 1461
    -- upvalues: sqrt (copy), abs (copy), v76 (copy), to_bits (copy), v77 (ref), create (copy), round3 (copy), build_face (copy), face_point (copy), v376 (ref), segment_face_xyz (copy), triangle_tail (copy), triangle_tail2 (copy), capsule_feature (copy), closest_on_segment (copy), segment_segment (copy)
    local v654 = p156[4]
    local v655 = p157[4]
    local v656 = v655 + p158 + v654
    local v657 = p157[1]
    local v658 = p157[2]
    local v659 = p157[3]
    local v660 = p157[5]
    local v661 = p157[6]
    local v662 = p157[7]
    local v663 = p157[8]
    local v664 = p156[5]
    local v665 = p156[6]
    local v666 = p156[7]
    local v667 = p156[1]
    local v668 = p156[2]
    local v669 = p156[3]
    local v670 = p156[8]
    local v671 = p156[9]
    local v672 = p156[10]
    local v673 = p156[11]
    local v674 = p156[12]
    local v675 = p156[13]
    local v676 = v657 * v664 + v658 * v665 + v659 * v666
    local v678 = abs(v660 * v664 + v661 * v665 + v662 * v666) * v663
    local v677 = p156[26]
    local v679 = v676 + v678
    local v680

    if not v77 and (not (v679 < 1.1754943508222875E-38) or not (v679 > -1.1754943508222875E-38) or v679 == 0) then
        v680 = create(v679, 0, 0).x
    else
        if v679 < 1.1754943508222875E-38 and v679 > -1.1754943508222875E-38 and v679 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v679))
        else
            buffer.writef32(v76, 0, v679)
        end

        v680 = buffer.readf32(v76, 0)
    end

    local v681 = v677 - v680

    v679 = v676 - v678

    if not v77 and (not (v679 < 1.1754943508222875E-38) or not (v679 > -1.1754943508222875E-38) or v679 == 0) then
        v680 = create(v679, 0, 0).x
    else
        if v679 < 1.1754943508222875E-38 and v679 > -1.1754943508222875E-38 and v679 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v679))
        else
            buffer.writef32(v76, 0, v679)
        end

        v680 = buffer.readf32(v76, 0)
    end

    v677 = v680 - p156[27]

    local v682 = v677 < v681

    if not v682 then
        v681 = v677
    end

    if v681 ~= v681 then
        return 2
    end

    if not v77 and (not (v681 < 1.1754943508222875E-38) or not (v681 > -1.1754943508222875E-38) or v681 == 0) then
        v680 = create(v681, 0, 0).x
    else
        if v681 < 1.1754943508222875E-38 and v681 > -1.1754943508222875E-38 and v681 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v681))
        else
            buffer.writef32(v76, 0, v681)
        end

        v680 = buffer.readf32(v76, 0)
    end

    if v656 < v680 then
        return 0
    end

    v676 = v664
    v678 = v665

    local v683 = v666
    local v684 = true
    local v685, v686, v687, v688, v689, v690, v691

    for i = 14, 20, 3 do
        v677 = p156[i]
        v680 = p156[i + 1]
        v679 = p156[i + 2]
        v689 = -v679 * v661 + v680 * v662
        v690 = -v677 * v662 + v679 * v660
        v679 = -v680 * v660 + v677 * v661
        v680 = v689 * v689 + v690 * v690 + v679 * v679

        local v692, v693, v694, v695, v696

        if v680 > 0.0010000000474974513 then
            v688 = 1 / sqrt(v680)
            v688 = v688 * 0.5 * (-v680 * (v688 * v688) + 1) + v688
            v688 = v688 * 0.5 * (-v680 * (v688 * v688) + 1) + v688
            v685, v686, v687 = round3(v689 * v688, v690 * v688, v679 * v688)
            v688 = v667 * v685 + v668 * v686 + v669 * v687

            local v697 = v670 * v685 + v671 * v686 + v672 * v687
            local v698 = v673 * v685 + v674 * v686 + v675 * v687
            local v699 = if v688 < v697 then v688 else v697

            v693 = if v697 < v688 then v688 else v697

            local v700 = v657 * v685 + v658 * v686 + v659 * v687
            local v701 = v660 * v685 + v661 * v686 + v662 * v687

            v677 = abs(v701) * v663

            local v702 = if v699 < v698 then v699 else v698

            if not v77 and (not (v702 < 1.1754943508222875E-38) or not (v702 > -1.1754943508222875E-38) or v702 == 0) then
                v701 = create(v702, 0, 0).x
            else
                if v702 < 1.1754943508222875E-38 and v702 > -1.1754943508222875E-38 and v702 ~= 0 then
                    buffer.writeu32(v76, 0, to_bits(v702))
                else
                    buffer.writef32(v76, 0, v702)
                end

                v701 = buffer.readf32(v76, 0)
            end

            local v703 = v700 + v677

            if not v77 and (not (v703 < 1.1754943508222875E-38) or not (v703 > -1.1754943508222875E-38) or v703 == 0) then
                v702 = create(v703, 0, 0).x
            else
                if v703 < 1.1754943508222875E-38 and v703 > -1.1754943508222875E-38 and v703 ~= 0 then
                    buffer.writeu32(v76, 0, to_bits(v703))
                else
                    buffer.writef32(v76, 0, v703)
                end

                v702 = buffer.readf32(v76, 0)
            end

            v692 = v701 - v702
            v702 = v700 - v677

            if not v77 and (not (v702 < 1.1754943508222875E-38) or not (v702 > -1.1754943508222875E-38) or v702 == 0) then
                v701 = create(v702, 0, 0).x
            else
                if v702 < 1.1754943508222875E-38 and v702 > -1.1754943508222875E-38 and v702 ~= 0 then
                    buffer.writeu32(v76, 0, to_bits(v702))
                else
                    buffer.writef32(v76, 0, v702)
                end

                v701 = buffer.readf32(v76, 0)
            end

            if not (v698 < v693) then
                v693 = v698
            end

            if not v77 and (not (v693 < 1.1754943508222875E-38) or not (v693 > -1.1754943508222875E-38) or v693 == 0) then
                v702 = create(v693, 0, 0).x
            else
                if v693 < 1.1754943508222875E-38 and v693 > -1.1754943508222875E-38 and v693 ~= 0 then
                    buffer.writeu32(v76, 0, to_bits(v693))
                else
                    buffer.writef32(v76, 0, v693)
                end

                v702 = buffer.readf32(v76, 0)
            end

            local v704 = v701 - v702

            v693 = v704 < v692

            if not v693 then
                v692 = v704
            end

            if not v77 and (not (v692 < 1.1754943508222875E-38) or not (v692 > -1.1754943508222875E-38) or v692 == 0) then
                v701 = create(v692, 0, 0).x
            else
                if v692 < 1.1754943508222875E-38 and v692 > -1.1754943508222875E-38 and v692 ~= 0 then
                    buffer.writeu32(v76, 0, to_bits(v692))
                else
                    buffer.writef32(v76, 0, v692)
                end

                v701 = buffer.readf32(v76, 0)
            end

            if v656 < v701 then
                return 0
            end

            if v681 < v692 then
                v694 = v685
                v695 = v686
                v691 = v687
                v696 = false
            else
                v696 = v684
                v692 = v681
                v693 = v682
                v694 = v676
                v695 = v678
                v691 = v683
            end
        else
            v696 = v684
            v692 = v681
            v693 = v682
            v694 = v676
            v695 = v678
            v691 = v683
        end

        v684 = v696
        v681 = v692
        v682 = v693
        v676 = v694
        v678 = v695
        v683 = v691
    end

    if not v77 and (not (v681 < 1.1754943508222875E-38) or not (v681 > -1.1754943508222875E-38) or v681 == 0) then
        v656 = create(v681, 0, 0).x
    else
        if v681 < 1.1754943508222875E-38 and v681 > -1.1754943508222875E-38 and v681 ~= 0 then
            buffer.writeu32(v76, 0, to_bits(v681))
        else
            buffer.writef32(v76, 0, v681)
        end

        v656 = buffer.readf32(v76, 0)
    end

    if v682 then
        v676 = -v676
        v678 = -v678
        v683 = -v683
    end

    v688, v680, v679, v689, v690, v685, v686, v687 = capsule_feature(p157, -v676, -v678, -v683)
    v691 = v676 * v664 + v678 * v665 + v683 * v666

    local v705, v706

    if not (abs(v691) > 0.949999988079071) or v688 == 0 or v376 then
        v706 = true
    else
        v705 = v691 < 0
        v706 = false
    end

    local v707, v708, v709, v710, v711, v712, v713, v714, v715, v716, v717, v718, v719, v720, v721, v722, v723, v724, v725, v726, v727, v728, v729, v730, v731

    if not v706 then
        local v732, v733

        if v705 then
            v733 = 60
            v732 = p156[29]
        else
            v733 = 30
            v732 = p156[28]
        end

        if v732 == 0 then
            v732 = build_face(p156, v705)
        end

        if v732 ~= 1 then
            return 2
        end

        v732 = v676 + v678 + v683 + v664 + v665 + v666 + v680 + v679 + v689 + v690 + v685 + v686 + v687

        local v734 = v733 + 20

        for i = v733, v734, 10 do
            v732 += p156[i + 1] + p156[i + 2] + p156[i + 3] + p156[i + 4] + p156[i + 5] + p156[i + 6] + p156[i + 10]
        end

        if v732 - v732 ~= 0 then
            return 2
        end

        local v735, v736, v737, v738

        v734, v707, v708, v715, v709, v710, v711, v712, v680, v679, v689, v713, v735, v714, v736, v737, v738 = segment_face_xyz(p156, v733, v676, v678, v683, v664, v665, v666, v680, v679, v689, v690, v685, v686, v687)
        v721 = v708
        v722 = v715
        v723 = v709
        v724 = v707

        if v734 == 1 then
            v716 = v680 - v710
            v717 = v679 - v711
            v718 = v689 - v712
            v719 = v716 * v716 + v717 * v717 + v718 * v718
            v720 = v77

            if v720 then
                if not (v719 < 1.1754943508222875E-38) or not (v719 > -1.1754943508222875E-38) or v719 == 0 then
                    buffer.writef32(v76, 0, v719)
                else
                    buffer.writeu32(v76, 0, to_bits(v719))
                end

                v720 = buffer.readf32(v76, 0)
            elseif not (v719 < 1.1754943508222875E-38) or not (v719 > -1.1754943508222875E-38) or v719 == 0 then
                v720 = create(v719, 0, 0).x
            else
                if not (v719 < 1.1754943508222875E-38) or not (v719 > -1.1754943508222875E-38) or v719 == 0 then
                    buffer.writef32(v76, 0, v719)
                else
                    buffer.writeu32(v76, 0, to_bits(v719))
                end

                v720 = buffer.readf32(v76, 0)
            end

            v686 = 1 / sqrt(v720)
            v686 = v686 * 0.5 * (-v720 * (v686 * v686) + 1) + v686
            v686 = v686 * 0.5 * (-v720 * (v686 * v686) + 1) + v686
            v685 = if v720 == 0 then 0 else v720 * v686

            if v685 > 1.1920928955078125E-07 then
                v721, v722, v723 = round3(v716 * v686, v717 * v686, v718 * v686)
                v724 = true
            end
        end

        v728 = v676
        v729 = v678
        v730 = v683

        if v724 then
            v725 = v667 * v721 + v668 * v722 + v669 * v723
            v726 = v670 * v721 + v671 * v722 + v672 * v723
            v727 = v673 * v721 + v674 * v722 + v675 * v723
            v731 = if v725 < v726 then v725 else v726

            if not (v726 < v725) then
                v725 = v726
            end

            v690 = v657 * v721 + v658 * v722 + v659 * v723
            v717 = v660 * v721 + v661 * v722 + v662 * v723
            v726 = abs(v717) * v663

            if not (v731 < v727) then
                v731 = v727
            end

            v718 = v77

            if not v718 and (not (v731 < 1.1754943508222875E-38) or not (v731 > -1.1754943508222875E-38) or v731 == 0) then
                v718 = create(v731, 0, 0).x
            else
                if v731 < 1.1754943508222875E-38 and v731 > -1.1754943508222875E-38 and v731 ~= 0 then
                    buffer.writeu32(v76, 0, to_bits(v731))
                else
                    buffer.writef32(v76, 0, v731)
                end

                v718 = buffer.readf32(v76, 0)
            end

            v715 = v690 + v726
            v709 = v77

            if not v709 and (not (v715 < 1.1754943508222875E-38) or not (v715 > -1.1754943508222875E-38) or v715 == 0) then
                v709 = create(v715, 0, 0).x
            else
                if v715 < 1.1754943508222875E-38 and v715 > -1.1754943508222875E-38 and v715 ~= 0 then
                    buffer.writeu32(v76, 0, to_bits(v715))
                else
                    buffer.writef32(v76, 0, v715)
                end

                v709 = buffer.readf32(v76, 0)
            end

            v681 = v718 - v709
            v717 = v690 - v726
            v718 = v77

            if not v718 and (not (v717 < 1.1754943508222875E-38) or not (v717 > -1.1754943508222875E-38) or v717 == 0) then
                v718 = create(v717, 0, 0).x
            else
                if v717 < 1.1754943508222875E-38 and v717 > -1.1754943508222875E-38 and v717 ~= 0 then
                    buffer.writeu32(v76, 0, to_bits(v717))
                else
                    buffer.writef32(v76, 0, v717)
                end

                v718 = buffer.readf32(v76, 0)
            end

            if not (v727 < v725) then
                v725 = v727
            end

            v709 = v77

            if not v709 and (not (v725 < 1.1754943508222875E-38) or not (v725 > -1.1754943508222875E-38) or v725 == 0) then
                v709 = create(v725, 0, 0).x
            else
                if v725 < 1.1754943508222875E-38 and v725 > -1.1754943508222875E-38 and v725 ~= 0 then
                    buffer.writeu32(v76, 0, to_bits(v725))
                else
                    buffer.writef32(v76, 0, v725)
                end

                v709 = buffer.readf32(v76, 0)
            end

            v731 = v718 - v709

            if v731 < v681 then
                if v656 <= v681 then
                    v728 = -v721
                    v729 = -v722
                    v730 = -v723
                end
            elseif v656 <= v731 then
                v730 = v723
                v728 = v721
                v729 = v722
            end
        end

        if v734 == 2 then
            return (triangle_tail2(p159, p160, v710, v711, v712, v680, v679, v689, v713, v735, v714, v736, v737, v738, v728, v729, v730, v654, v655))
        end

        return (triangle_tail(p159, p160, v710, v711, v712, v680, v679, v689, v728, v729, v730, v654, v655))
    end

    if abs(v691) > 0.949999988079071 then
        if v688 ~= 0 or not v684 then
            return 2
        end

        if v682 then
            v728 = 60
            v729 = p156[29]
        else
            v728 = 30
            v729 = p156[28]
        end

        if v729 == 0 then
            v729 = build_face(p156, v682)
        end

        if v729 ~= 1 then
            return 2
        end

        v710, v711, v712 = face_point(p156, v728, v676, v678, v683, v680, v679, v689)
    else
        local v739 = false
        local v740 = false
        local v741 = false
        local v742 = false
        local v743 = false
        local v744 = false
        local v745 = false

        if v688 == 0 then
            v745 = true
        else
            v739 = true
        end

        if v739 then
            v728 = v676 * v667 + v678 * v668 + v683 * v669
            v729 = v676 * v670 + v678 * v671 + v683 * v672
            v730 = v676 * v673 + v678 * v674 + v683 * v675
            v717 = v676 * p156[14] + v678 * p156[15] + v683 * p156[16]
            v716 = abs(v717)
            v715 = v676 * p156[17] + v678 * p156[18] + v683 * p156[19]
            v717 = abs(v715)
            v709 = v676 * p156[20] + v678 * p156[21] + v683 * p156[22]
            v715 = abs(v709)

            if v729 < v728 then
                v740 = true
            else
                v741 = true
            end
        end

        v739 = false

        if v740 then
            if v730 < v728 then
                v739 = true
            else
                v741 = true
            end
        end

        v740 = false

        if v741 then
            if v730 < v729 then
                v742 = true
            else
                v740 = true
            end
        end

        v741 = false

        if v740 then
            if v716 < 0.05000000074505806 then
                v741 = true
            else
                v743 = true
            end
        end

        v740 = false

        if v741 then
            if v716 < v717 then
                v740 = true
            else
                v743 = true
            end
        end

        v741 = false

        if v743 then
            if v717 < 0.05000000074505806 then
                v744 = true
            else
                v741 = true
            end
        end

        if v741 then
            v721 = 2
            v722 = nil
            v745 = false
        end

        v741 = false

        if v744 then
            v721 = 2
            v722 = 1
            v745 = false
        end

        v744 = false

        if v740 then
            v721 = 2
            v722 = 0
            v745 = false
        end

        v740 = false

        if v742 then
            if v717 < 0.05000000074505806 then
                v744 = true
            else
                v741 = true
            end
        end

        v742 = false

        if v744 then
            if v717 < v715 then
                v742 = true
            else
                v741 = true
            end
        end

        v744 = false

        if v741 then
            if v715 < 0.05000000074505806 then
                v740 = true
            else
                v744 = true
            end
        end

        if v744 then
            v721 = 1
            v722 = nil
            v745 = false
        end

        v744 = false

        if v740 then
            v721 = 1
            v722 = 2
            v745 = false
        end

        v740 = false

        if v742 then
            v721 = 1
            v722 = 1
            v745 = false
        end

        v742 = false

        if v739 then
            if v716 < 0.05000000074505806 then
                v740 = true
            else
                v744 = true
            end
        end

        v739 = false

        if v740 then
            if v716 < v715 then
                v739 = true
            else
                v744 = true
            end
        end

        v740 = false

        if v744 then
            if v715 < 0.05000000074505806 then
                v742 = true
            else
                v740 = true
            end
        end

        if v740 then
            v721 = 0
            v722 = nil
            v745 = false
        end

        if v742 then
            v721 = 0
            v722 = 2
            v745 = false
        end

        if v739 then
            v721 = 0
            v722 = 0
            v745 = false
        end

        if v745 then
            return 2
        end

        if v722 ~= nil then
            v718 = if v722 == 0 then 1 elseif v722 == 1 then 11 else 8
            v717 = 14 + 3 * v722
            v723 = p156[v718]
            v712 = p156[v718 + 1]

            local v746 = p156[v718 + 2]
            local v747 = p156[v717]
            local v748 = p156[v717 + 1]

            v713 = p156[v717 + 2]
            v718 = p156[23 + v722]
            v714, v710, v711, v712, v680, v679, v689 = segment_segment(v723, v712, v746, v747, v748, v713, v718, v680, v679, v689, v690, v685, v686, v687)

            if not v714 then
                return 2
            end
        else
            v716 = if v721 == 0 then 1 elseif v721 == 1 then 8 else 11
            v710 = p156[v716]
            v711 = p156[v716 + 1]
            v712 = p156[v716 + 2]
            v680, v679, v689 = closest_on_segment(v680, v679, v689, v690, v685, v686, v687, v710, v711, v712)
        end
    end

    v707 = false
    v708 = 0
    v715 = 0
    v709 = 0
    v716 = v680 - v710
    v717 = v679 - v711
    v718 = v689 - v712
    v719 = v716 * v716 + v717 * v717 + v718 * v718
    v720 = v77

    if v720 then
        if not (v719 < 1.1754943508222875E-38) or not (v719 > -1.1754943508222875E-38) or v719 == 0 then
            buffer.writef32(v76, 0, v719)
        else
            buffer.writeu32(v76, 0, to_bits(v719))
        end

        v720 = buffer.readf32(v76, 0)
    elseif not (v719 < 1.1754943508222875E-38) or not (v719 > -1.1754943508222875E-38) or v719 == 0 then
        v720 = create(v719, 0, 0).x
    else
        if not (v719 < 1.1754943508222875E-38) or not (v719 > -1.1754943508222875E-38) or v719 == 0 then
            buffer.writef32(v76, 0, v719)
        else
            buffer.writeu32(v76, 0, to_bits(v719))
        end

        v720 = buffer.readf32(v76, 0)
    end

    v686 = 1 / sqrt(v720)
    v686 = v686 * 0.5 * (-v720 * (v686 * v686) + 1) + v686
    v686 = v686 * 0.5 * (-v720 * (v686 * v686) + 1) + v686
    v685 = if v720 == 0 then 0 else v720 * v686

    if v685 > 1.1920928955078125E-07 then
        v721, v722, v723 = round3(v716 * v686, v717 * v686, v718 * v686)
        v724 = true
    else
        v723 = v709
        v724 = v707
        v721 = v708
        v722 = v715
    end

    v728 = v676
    v729 = v678
    v730 = v683

    if v724 then
        v725 = v667 * v721 + v668 * v722 + v669 * v723
        v726 = v670 * v721 + v671 * v722 + v672 * v723
        v727 = v673 * v721 + v674 * v722 + v675 * v723
        v731 = if v725 < v726 then v725 else v726

        if not (v726 < v725) then
            v725 = v726
        end

        v690 = v657 * v721 + v658 * v722 + v659 * v723
        v717 = v660 * v721 + v661 * v722 + v662 * v723
        v726 = abs(v717) * v663

        if not (v731 < v727) then
            v731 = v727
        end

        v718 = v77

        if v718 then
            if not (v731 < 1.1754943508222875E-38) or not (v731 > -1.1754943508222875E-38) or v731 == 0 then
                buffer.writef32(v76, 0, v731)
            else
                buffer.writeu32(v76, 0, to_bits(v731))
            end

            v718 = buffer.readf32(v76, 0)
        elseif not (v731 < 1.1754943508222875E-38) or not (v731 > -1.1754943508222875E-38) or v731 == 0 then
            v718 = create(v731, 0, 0).x
        else
            if not (v731 < 1.1754943508222875E-38) or not (v731 > -1.1754943508222875E-38) or v731 == 0 then
                buffer.writef32(v76, 0, v731)
            else
                buffer.writeu32(v76, 0, to_bits(v731))
            end

            v718 = buffer.readf32(v76, 0)
        end

        v715 = v690 + v726
        v709 = v77

        if v709 then
            if not (v715 < 1.1754943508222875E-38) or not (v715 > -1.1754943508222875E-38) or v715 == 0 then
                buffer.writef32(v76, 0, v715)
            else
                buffer.writeu32(v76, 0, to_bits(v715))
            end

            v709 = buffer.readf32(v76, 0)
        elseif not (v715 < 1.1754943508222875E-38) or not (v715 > -1.1754943508222875E-38) or v715 == 0 then
            v709 = create(v715, 0, 0).x
        else
            if not (v715 < 1.1754943508222875E-38) or not (v715 > -1.1754943508222875E-38) or v715 == 0 then
                buffer.writef32(v76, 0, v715)
            else
                buffer.writeu32(v76, 0, to_bits(v715))
            end

            v709 = buffer.readf32(v76, 0)
        end

        v681 = v718 - v709
        v717 = v690 - v726
        v718 = v77

        if v718 then
            if not (v717 < 1.1754943508222875E-38) or not (v717 > -1.1754943508222875E-38) or v717 == 0 then
                buffer.writef32(v76, 0, v717)
            else
                buffer.writeu32(v76, 0, to_bits(v717))
            end

            v718 = buffer.readf32(v76, 0)
        elseif not (v717 < 1.1754943508222875E-38) or not (v717 > -1.1754943508222875E-38) or v717 == 0 then
            v718 = create(v717, 0, 0).x
        else
            if not (v717 < 1.1754943508222875E-38) or not (v717 > -1.1754943508222875E-38) or v717 == 0 then
                buffer.writef32(v76, 0, v717)
            else
                buffer.writeu32(v76, 0, to_bits(v717))
            end

            v718 = buffer.readf32(v76, 0)
        end

        if not (v727 < v725) then
            v725 = v727
        end

        v709 = v77

        if v709 then
            if not (v725 < 1.1754943508222875E-38) or not (v725 > -1.1754943508222875E-38) or v725 == 0 then
                buffer.writef32(v76, 0, v725)
            else
                buffer.writeu32(v76, 0, to_bits(v725))
            end

            v709 = buffer.readf32(v76, 0)
        elseif not (v725 < 1.1754943508222875E-38) or not (v725 > -1.1754943508222875E-38) or v725 == 0 then
            v709 = create(v725, 0, 0).x
        else
            if not (v725 < 1.1754943508222875E-38) or not (v725 > -1.1754943508222875E-38) or v725 == 0 then
                buffer.writef32(v76, 0, v725)
            else
                buffer.writeu32(v76, 0, to_bits(v725))
            end

            v709 = buffer.readf32(v76, 0)
        end

        v731 = v718 - v709

        if v731 < v681 then
            if v656 <= v681 then
                v728 = -v721
                v729 = -v722
                v730 = -v723
            end
        elseif v656 <= v731 then
            v730 = v723
            v728 = v721
            v729 = v722
        end
    end

    return (triangle_tail(p159, p160, v710, v711, v712, v680, v679, v689, v728, v729, v730, v654, v655))
end

local function pair_box_round(p161, p162, p163, p164) -- line: 1704
    -- upvalues: abs (copy), v76 (copy), to_bits (copy), v77 (ref), create (copy)
    local v749 = p162[4] + p163 + p161[4]
    local v750 = p161[1]
    local v751 = p161[2]
    local v752 = p161[3]
    local v753 = p161[17]
    local v754 = p161[18]
    local v755 = p161[19]
    local v756 = p161[20]
    local v757 = p161[21]
    local v758 = p161[22]
    local v759 = p161[23]
    local v760 = p161[24]
    local v761 = p161[25]
    local v762 = p162[1]
    local v763 = p162[2]
    local v764 = p162[3]
    local v765 = true

    for i = 11, 5, -3 do
        local v766 = p161[i]
        local v767 = p161[i + 1]
        local v768 = p161[i + 2]
        local v769 = v750 * v766 + v751 * v767 + v752 * v768
        local v771 = abs(v753 * v766 + v754 * v767 + v755 * v768)
        local v773 = abs(v756 * v766 + v757 * v767 + v758 * v768)
        local v775 = abs(v759 * v766 + v760 * v767 + v761 * v768)
        local v776 = v771 + v773 + v775
        local v777 = v762 * v766 + v763 * v767 + v764 * v768
        local v778, v779

        if p164 then
            local v781 = abs(p162[5] * v766 + p162[6] * v767 + p162[7] * v768) * p162[8]
            local v782 = v769 - v776
            local v783

            if v77 then
                if not (v782 < 1.1754943508222875E-38) or not (v782 > -1.1754943508222875E-38) or v782 == 0 then
                    buffer.writef32(v76, 0, v782)
                else
                    buffer.writeu32(v76, 0, to_bits(v782))
                end

                v783 = buffer.readf32(v76, 0)
            elseif not (v782 < 1.1754943508222875E-38) or not (v782 > -1.1754943508222875E-38) or v782 == 0 then
                v783 = create(v782, 0, 0).x
            else
                if not (v782 < 1.1754943508222875E-38) or not (v782 > -1.1754943508222875E-38) or v782 == 0 then
                    buffer.writef32(v76, 0, v782)
                else
                    buffer.writeu32(v76, 0, to_bits(v782))
                end

                v783 = buffer.readf32(v76, 0)
            end

            local v784 = v777 + v781
            local v785

            if not v77 and (not (v784 < 1.1754943508222875E-38) or not (v784 > -1.1754943508222875E-38) or v784 == 0) then
                v785 = create(v784, 0, 0).x
            else
                if v784 < 1.1754943508222875E-38 and v784 > -1.1754943508222875E-38 and v784 ~= 0 then
                    buffer.writeu32(v76, 0, to_bits(v784))
                else
                    buffer.writef32(v76, 0, v784)
                end

                v785 = buffer.readf32(v76, 0)
            end

            v778 = v783 - v785

            local v786 = v777 - v781
            local v787

            if not v77 and (not (v786 < 1.1754943508222875E-38) or not (v786 > -1.1754943508222875E-38) or v786 == 0) then
                v787 = create(v786, 0, 0).x
            else
                if v786 < 1.1754943508222875E-38 and v786 > -1.1754943508222875E-38 and v786 ~= 0 then
                    buffer.writeu32(v76, 0, to_bits(v786))
                else
                    buffer.writef32(v76, 0, v786)
                end

                v787 = buffer.readf32(v76, 0)
            end

            local v788 = v769 + v776
            local v789

            if not v77 and (not (v788 < 1.1754943508222875E-38) or not (v788 > -1.1754943508222875E-38) or v788 == 0) then
                v789 = create(v788, 0, 0).x
            else
                if v788 < 1.1754943508222875E-38 and v788 > -1.1754943508222875E-38 and v788 ~= 0 then
                    buffer.writeu32(v76, 0, to_bits(v788))
                else
                    buffer.writef32(v76, 0, v788)
                end

                v789 = buffer.readf32(v76, 0)
            end

            v779 = v787 - v789
        else
            local v790

            if not v77 and (not (v777 < 1.1754943508222875E-38) or not (v777 > -1.1754943508222875E-38) or v777 == 0) then
                v790 = create(v777, 0, 0).x
            else
                if v777 < 1.1754943508222875E-38 and v777 > -1.1754943508222875E-38 and v777 ~= 0 then
                    buffer.writeu32(v76, 0, to_bits(v777))
                else
                    buffer.writef32(v76, 0, v777)
                end

                v790 = buffer.readf32(v76, 0)
            end

            local v791 = v769 - v776
            local v792

            if not v77 and (not (v791 < 1.1754943508222875E-38) or not (v791 > -1.1754943508222875E-38) or v791 == 0) then
                v792 = create(v791, 0, 0).x
            else
                if v791 < 1.1754943508222875E-38 and v791 > -1.1754943508222875E-38 and v791 ~= 0 then
                    buffer.writeu32(v76, 0, to_bits(v791))
                else
                    buffer.writef32(v76, 0, v791)
                end

                v792 = buffer.readf32(v76, 0)
            end

            v778 = v792 - v790

            local v793 = v769 + v776
            local v794

            if not v77 and (not (v793 < 1.1754943508222875E-38) or not (v793 > -1.1754943508222875E-38) or v793 == 0) then
                v794 = create(v793, 0, 0).x
            else
                if v793 < 1.1754943508222875E-38 and v793 > -1.1754943508222875E-38 and v793 ~= 0 then
                    buffer.writeu32(v76, 0, to_bits(v793))
                else
                    buffer.writef32(v76, 0, v793)
                end

                v794 = buffer.readf32(v76, 0)
            end

            v779 = v790 - v794
        end

        if not (v779 < v778) then
            v778 = v779
        end

        if v765 then
            if v778 ~= v778 then
                return 2
            end

            v765 = false
        end

        local v795

        if not v77 and (not (v778 < 1.1754943508222875E-38) or not (v778 > -1.1754943508222875E-38) or v778 == 0) then
            v795 = create(v778, 0, 0).x
        else
            if v778 < 1.1754943508222875E-38 and v778 > -1.1754943508222875E-38 and v778 ~= 0 then
                buffer.writeu32(v76, 0, to_bits(v778))
            else
                buffer.writef32(v76, 0, v778)
            end

            v795 = buffer.readf32(v76, 0)
        end

        if v749 < v795 then
            return 0
        end
    end

    return 2
end

local function float_pair(p165, p166, p167, p168, p169, p170, p171) -- line: 1745
    -- upvalues: pair_sphere_sphere (copy), pair_sphere_capsule (copy), pair_triangle_sphere (copy), pair_capsule_capsule (copy), pair_triangle_capsule (copy), pair_box_round (copy)
    if p168 == 1 then
        if p166 == 3 then
            return (pair_triangle_sphere(p165, p167, p169, p170.primitive[1].feature, p171))
        end

        if p166 == 1 then
            return (pair_sphere_sphere(p165, p167, p169))
        end

        if p166 == 2 then
            return (pair_sphere_capsule(p165, p167, p169, true))
        end

        if p166 == 4 then
            return (pair_box_round(p165, p167, p169, false))
        end
    elseif p168 == 2 then
        if p166 == 3 then
            return (pair_triangle_capsule(p165, p167, p169, p170.primitive[1].feature, p171))
        end

        if p166 == 1 then
            return (pair_sphere_capsule(p165, p167, p169, false))
        end

        if p166 == 2 then
            return (pair_capsule_capsule(p165, p167, p169))
        end

        if p166 == 4 then
            return (pair_box_round(p165, p167, p169, true))
        end
    end

    return 2
end

local function push_point(p172, p173, p174, p175) -- line: 1772
    -- upvalues: rt (copy), t4 (copy), n1 (ref), material_scalar_store (copy), v119 (copy)
    local material = p173.material
    local material2 = p174.material
    local v796 = if material.static_friction > material2.static_friction then material.static_friction else material2.static_friction
    local v797 = if material.dynamic_friction > material2.dynamic_friction then material.dynamic_friction else material2.dynamic_friction
    local v798 = if material.restitution < material2.restitution then material.restitution else material2.restitution

    if v796 ~= v796 then
        v796 = material_scalar_store(v796)
    end

    if v797 ~= v797 then
        v797 = material_scalar_store(v797)
    end

    if v798 ~= v798 then
        v798 = material_scalar_store(v798)
    end

    if p175 and n1 < 192 then
        n1 += 1

        local v799 = t4[n1]

        if v799 == nil then
            v799 = {
                body_a = {},
                body_b = {},
                contact = {
                    restitution = 0,
                    static_friction = 0,
                    dynamic_friction = 0,
                    tag = 0,
                    position_on_a = {
                        x = 0,
                        y = 0,
                        z = 0
                    },
                    position_on_b = {
                        x = 0,
                        y = 0,
                        z = 0
                    },
                    normal = {
                        x = 0,
                        y = 0,
                        z = 0
                    }
                }
            }
            t4[n1] = v799
        end

        local body_a = v799.body_a
        local body = p173.body

        body_a.tag = body.tag
        body_a[1] = body[1]

        local body_b = v799.body_b
        local body2 = p174.body

        body_b.tag = body2.tag
        body_b[1] = body2[1]

        local contact = v799.contact
        local position_on_a = contact.position_on_a
        local v800 = v119[1]
        local v801 = v119[2]
        local v802 = v119[3]

        position_on_a.x = v800
        position_on_a.y = v801
        position_on_a.z = v802

        local position_on_b = contact.position_on_b
        local v803 = v119[4]
        local v804 = v119[5]
        local v805 = v119[6]

        position_on_b.x = v803
        position_on_b.y = v804
        position_on_b.z = v805

        local normal = contact.normal
        local v806 = v119[7]
        local v807 = v119[8]
        local v808 = v119[9]

        normal.x = v806
        normal.y = v807
        normal.z = v808
        contact.restitution = v798
        contact.static_friction = v796
        contact.dynamic_friction = v797
        contact.tag = 0
        table.insert(p172, v799)
    else
        table.insert(p172, {
            body_a = rt.copy(p173.body),
            body_b = rt.copy(p174.body),
            contact = {
                tag = 0,
                position_on_a = {
                    x = v119[1],
                    y = v119[2],
                    z = v119[3]
                },
                position_on_b = {
                    x = v119[4],
                    y = v119[5],
                    z = v119[6]
                },
                normal = {
                    x = v119[7],
                    y = v119[8],
                    z = v119[9]
                },
                restitution = v798,
                static_friction = v796,
                dynamic_friction = v797
            }
        })
    end
end

local t22 = {}
local t23 = {}
local t24 = {}
local t25 = {}
local t26 = {}
local t27 = {}
local t28 = {}
local v809
local t29 = {}
local t30 = {}
local pack_into = import("skate_core/physics/world_contact/primitive_geometry").pack_into

local function append_float(p176, p177, p178, p179, p180, p181) -- line: 1881
    -- upvalues: PrimitivePairSettings (copy), t1 (copy), primitive_pair_contacts_flat (copy), pack (copy), push_contacts (copy), t6 (copy), t8 (copy), append_impl_r3 (copy), v75 (ref), t10 (copy), mirror_fill (copy), v119 (copy), float_pair (copy), push_point (copy), t22 (copy), t23 (copy), t24 (copy), t25 (copy), t26 (copy), t27 (copy), t28 (copy), v809 (ref), t29 (copy), t30 (copy), pack_into (copy)
    local v810 = p179 >= 21 or p180.assembly_group >= 21

    if not v810 then
        for _, v811 in ipairs(p180.parts) do
            if v811.part_group >= 21 then
                v810 = true
                break
            end
        end
    end

    if v810 then
        error("Skater collision group is outside the original21x21 table", 0)
    end

    local parts, self_culling = p180.parts, p180.self_culling

    if type(self_culling) ~= "table" then
        return append_impl_r3(p176, p177, p178, p179, p180, p181)
    end

    local n2 = 0

    for v812, v813 in ipairs(p178) do
        local body = if type(v813) == "table" then v813.body else nil

        if type(body) ~= "table" or body.tag ~= "Attached" then
            table.clear(t27)

            return append_impl_r3(p176, p177, p178, p179, p180, p181)
        end

        local v814 = body[1]

        if type(v814) ~= "number" then
            table.clear(t27)

            return append_impl_r3(p176, p177, p178, p179, p180, p181)
        end

        local v815 = parts[v814 + 1]
        local v816 = self_culling[v814 + 1]

        if type(v815) ~= "table" or type(v816) ~= "table" or type(v815.part_group) ~= "number" then
            table.clear(t27)

            return append_impl_r3(p176, p177, p178, p179, p180, p181)
        end

        n2 = v812
        t26[v812] = v814
        t27[v812] = v816
        t28[v812] = v815.part_group
    end

    local v817 = v809

    if v817 == nil then
        v817 = PrimitivePairSettings.skater_self_collision()
        v809 = v817
    end

    local v818 = v817.padding_b + v817.padding_a + v817.additional_padding

    table.clear(t24)
    table.clear(t25)
    table.clear(t6)
    table.clear(t8)

    local v819 = v75

    if t1.group_pair_allowed(p179, p180.assembly_group) then
        for i = 1, n2 do
            t28[i] = t1.group_pair_allowed(p179, t28[i])
        end

        for v820, v821 in ipairs(p177) do
            local v822 = t22[v820]

            if v822 == nil then
                v822 = table.create(90, 0)
                t22[v820] = v822
            end

            local v823 = t24[v820]

            for j = 1, n2 do
                if t28[j] then
                    local v824 = p178[j]
                    local result = v823

                    if v823 == nil then
                        local primitive = v821.primitive
                        local ok

                        ok, result = pcall(mirror_fill, v822, primitive)

                        if not ok then
                            result = 0
                            pack(primitive)
                        end

                        t24[v820] = result
                    end

                    v823 = result

                    local v825 = t23[j]

                    if v825 == nil then
                        v825 = table.create(90, 0)
                        t23[j] = v825
                    end

                    local v826 = t25[j]

                    if v826 == nil then
                        local primitive = v824.primitive
                        local ok, result = pcall(mirror_fill, v825, primitive)

                        if not ok then
                            result = 0
                            pack(primitive)
                        end

                        v826 = result
                        t25[j] = result
                    end

                    local v827 = float_pair(v822, result, v825, v826, v818, v821, v817)

                    if v819 ~= nil then
                        local v828 = t10[result] .. "/" .. t10[v826] .. " " .. v827

                        v819[v828] = (v819[v828] or 0) + 1
                    end

                    if v827 == 1 then
                        push_point(p176, v821, v824, p181)
                    elseif v827 == 3 then
                        push_point(p176, v821, v824, p181)

                        local v829 = v119[10]
                        local v830 = v119[11]
                        local v831 = v119[12]
                        local v832 = v119[13]
                        local v833 = v119[14]
                        local v834 = v119[15]

                        v119[1] = v829
                        v119[2] = v830
                        v119[3] = v831
                        v119[4] = v832
                        v119[5] = v833
                        v119[6] = v834
                        push_point(p176, v821, v824, p181)
                    elseif v827 == 2 then
                        local primitive = v821.primitive
                        local primitive2 = v824.primitive
                        local v835 = t29[v820]

                        if v835 == nil then
                            v835 = table.create(48, 0)
                            t29[v820] = v835
                        end

                        local v836 = t6[v820]

                        if v836 == nil then
                            local v837

                            v837, v836 = pack_into(v835, primitive)
                            t6[v820] = v836
                        end

                        local v838 = t30[j]

                        if v838 == nil then
                            v838 = table.create(48, 0)
                            t30[j] = v838
                        end

                        local v839 = t8[j]

                        if v839 == nil then
                            local v840

                            v840, v839 = pack_into(v838, primitive2)
                            t8[j] = v839
                        end

                        local v841, v842, v843, v844 = primitive_pair_contacts_flat(v835, v836, v838, v839, primitive, primitive2, v817)

                        if v841 ~= nil then
                            push_contacts(p176, v821, v824, v841, v842, v843, v844, p181)
                        end
                    end
                end
            end
        end
    end

    for i = 1, n2 do
        local v845 = t26[i]
        local v846 = t27[i]
        local v847 = p178[i]
        local v848 = t23[i]

        if v848 == nil then
            v848 = table.create(90, 0)
            t23[i] = v848
        end

        for j = 1, n2 do
            local v849 = t26[j]

            if v845 ~= v849 and not v846[v849 + 1] then
                local v850 = p178[j]
                local result = t25[i]

                if result == nil then
                    local primitive = v847.primitive
                    local ok

                    ok, result = pcall(mirror_fill, v848, primitive)

                    if not ok then
                        result = 0
                        pack(primitive)
                    end

                    t25[i] = result
                end

                local v851 = t23[j]

                if v851 == nil then
                    v851 = table.create(90, 0)
                    t23[j] = v851
                end

                local v852 = t25[j]

                if v852 == nil then
                    local primitive = v850.primitive
                    local ok, result = pcall(mirror_fill, v851, primitive)

                    if not ok then
                        result = 0
                        pack(primitive)
                    end

                    v852 = result
                    t25[j] = result
                end

                local v853 = float_pair(v848, result, v851, v852, v818, v847, v817)

                if v819 ~= nil then
                    local v854 = t10[result] .. "/" .. t10[v852] .. " " .. v853

                    v819[v854] = (v819[v854] or 0) + 1
                end

                if v853 == 1 then
                    push_point(p176, v847, v850, p181)
                elseif v853 == 3 then
                    push_point(p176, v847, v850, p181)

                    local v855 = v119[10]
                    local v856 = v119[11]
                    local v857 = v119[12]
                    local v858 = v119[13]
                    local v859 = v119[14]
                    local v860 = v119[15]

                    v119[1] = v855
                    v119[2] = v856
                    v119[3] = v857
                    v119[4] = v858
                    v119[5] = v859
                    v119[6] = v860
                    push_point(p176, v847, v850, p181)
                elseif v853 == 2 then
                    local primitive = v847.primitive
                    local primitive2 = v850.primitive
                    local v861 = t30[i]

                    if v861 == nil then
                        v861 = table.create(48, 0)
                        t30[i] = v861
                    end

                    local v862 = t8[i]

                    if v862 == nil then
                        local v863

                        v863, v862 = pack_into(v861, primitive)
                        t8[i] = v862
                    end

                    local v864 = t30[j]

                    if v864 == nil then
                        v864 = table.create(48, 0)
                        t30[j] = v864
                    end

                    local v865 = t8[j]

                    if v865 == nil then
                        local v866

                        v866, v865 = pack_into(v864, primitive2)
                        t8[j] = v865
                    end

                    local v867, v868, v869, v870 = primitive_pair_contacts_flat(v861, v862, v864, v865, primitive, primitive2, v817)

                    if v867 ~= nil then
                        push_contacts(p176, v847, v850, v867, v868, v869, v870, p181)
                    end
                end
            end
        end
    end

    table.clear(t24)
    table.clear(t25)
    table.clear(t6)
    table.clear(t8)
    table.clear(t27)
end

t1.append_float = append_float

function t1.append(p182, p183, p184, p185, p186) -- line: 2107
    -- upvalues: append_impl_r3 (copy), v73 (ref), append_float (copy)
    if v73 then
        return append_impl_r3(p182, p183, p184, p185, p186, false)
    end

    append_float(p182, p183, p184, p185, p186, false)
end

function t1.append_pooled(p187, p188, p189, p190, p191) -- line: 2119
    -- upvalues: n1 (ref), append_impl_r3 (copy), v73 (ref), append_float (copy)
    n1 = 0

    if v73 then
        return append_impl_r3(p187, p188, p189, p190, p191, true)
    end

    append_float(p187, p188, p189, p190, p191, true)
end

return t1
