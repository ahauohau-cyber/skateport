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

local function rtl_from_bits(p3) -- line: 24
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p3)

    return (buffer.readf32(v1, 0))
end

local function rtl_is_finite(p4) -- line: 28
    if p4 ~= p4 or p4 == 1e999 then
        return false
    end

    return p4 ~= (-1e999)
end

local import = require(sim.import)
local Vector3 = import("skate_core/math").Vector3
local v8 = import("skate_core/physics/board_world/broadphase")
local conservative_bounds, primitive_bounds = v8.conservative_bounds, v8.primitive_bounds
local v9 = import("skate_core/physics/board_world/query_index")
local by_world = import("skate_core/physics/board_world/objects").by_world
local v10 = import("skate_core/physics/board_world/query_metadata")
local Bounds, QueryMetadata = v10.Bounds, v10.QueryMetadata
local BodyId = import("skate_core/physics/board").BodyId
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime
local CollisionBody = import("skate_core/physics/board_step").CollisionBody
local combine_contact_materials = import("skate_core/physics/contact").combine_contact_materials
local triangle_segment = import("skate_core/physics/triangle_query").triangle_segment
local v11 = import("skate_core/physics/world_contact")
local ContactBuffer, v12 = v11.ContactBuffer, v11.primitive_triangle_world_contacts

v12 = import("skate_core/physics/world_contact/primitive_query")

local primitive_triangle_world_contacts_packed, pack_primitive = v12.primitive_triangle_world_contacts_packed, v12.pack_primitive
local packed = import("packed")
local triangle_from_volume = v11.triangle_from_volume
local t1 = {
    WorldTriangle = {},
    WorldLineHit = {}
}

function t1.WorldLineHit.eq(p5, p6) -- line: 77
    -- upvalues: Vector3 (copy)
    local geometry = p5.geometry
    local geometry2 = p6.geometry

    return Vector3.eq(geometry.position, geometry2.position) and Vector3.eq(geometry.normal, geometry2.normal) and geometry.fraction == geometry2.fraction and geometry.volume_parameter[1] == geometry2.volume_parameter[1] and geometry.volume_parameter[2] == geometry2.volume_parameter[2] and geometry.volume_parameter[3] == geometry2.volume_parameter[3] and p5.tag == p6.tag
end

function t1.WorldTriangle.from_vertices(p7, p8, p9, p10, p11, p12) -- line: 92
    -- upvalues: rt (copy), Vector3 (copy), triangle_from_volume (copy)
    for _, v14 in p7 do
        local x = v14.x

        if x ~= x or x == 1e999 or x == (-1e999) then
            return nil
        end

        local y = v14.y

        if y ~= y or y == 1e999 or y == (-1e999) then
            return nil
        end

        local z = v14.z

        if z ~= z or z == 1e999 or z == (-1e999) then
            return nil
        end
    end

    local v15 = triangle_from_volume(p7, p12, p11, p10)
    local v16 = rt.copy(v15.feature.normal)
    local v17 = false

    for _, v18 in v15.edge_lengths do
        if v18 ~= v18 or v18 == 1e999 or v18 == (-1e999) or v18 <= 0 then
            v17 = true
            break
        end
    end

    if not v17 then
        local x = v16.x

        if x == x and x ~= 1e999 and x ~= (-1e999) then
            local y = v16.y

            if y == y and y ~= 1e999 and y ~= (-1e999) then
                local z = v16.z

                if z == z and z ~= 1e999 and z ~= (-1e999) and not Vector3.eq(v16, Vector3.ZERO) then
                    return {
                        triangle = v15,
                        material = rt.copy(p8),
                        tag = p9
                    }
                end
            end
        end
    end

    return nil
end

t1.ContactRetentionSettings = {}
t1.WheelWorldSettings = {}
t1.BoardWorldVolume = {}
t1.ExternalLineHit = {}
t1.BoardWorld = {}

function t1.BoardWorld.new(p13) -- line: 170
    -- upvalues: rt (copy), Vector3 (copy), v8 (copy), v9 (copy), Bounds (copy)
    local t2 = {}

    for v19, v20 in p13 do
        local v21 = Bounds.from_points(v20.triangle.vertices)

        if v21 == nil then
            v21 = {
                min = Vector3.new((-1e999), (-1e999), (-1e999)),
                max = Vector3.new(1e999, 1e999, 1e999)
            }
        end

        t2[v19] = v21
    end

    local n1 = 0

    for _, v22 in p13 do
        local fatness = v22.triangle.fatness
        local v23 = if fatness == fatness and fatness ~= 1e999 and fatness ~= (-1e999) and v22.triangle.fatness >= 0 then v22.triangle.fatness else 1e999

        n1 = rt.fmax(n1, v23)
    end

    local n2 = 0

    for _, v24 in t2 do
        local v25 = rt.fmax(rt.fmax(v24.max.x - v24.min.x, v24.max.y - v24.min.y), v24.max.z - v24.min.z)

        n2 = rt.fmax(n2, v25 * (2 * v8.THIN_MARGIN))
    end

    return {
        external = nil,
        query_metadata = nil,
        triangles = p13,
        triangle_bounds = t2,
        query_index = v9.QueryIndex.default(),
        maximum_fatness = n1,
        maximum_triangle_margin = n2,
        contacts = {},
        buffer = {
            count = 0,
            flushed = 0,
            capacity = 0,
            dropped = 0,
            distance_squared_threshold = 0,
            allow_flush = 1,
            deferred_reduction = 0,
            full = 0,
            records = rt.filled(50, table.create(64, 0))
        }
    }
end

function t1.BoardWorld.pack(p14) -- line: 234
    -- upvalues: v8 (copy), by_world (copy), packed (copy)
    if packed.is_view(p14.triangles) then
        return nil
    end

    v8.flat_triangle_bounds(p14)
    v8.triangle_super_bounds(p14)

    local v26 = packed.pack(p14.triangles, {
        cache = 1024
    })
    local v27 = packed.pack(p14.triangle_bounds, {
        cache = 64
    })

    p14.triangles = packed.view(v26)
    p14.triangle_bounds = packed.view(v27)

    local v28 = by_world[p14]

    if v28 ~= nil then
        v28.remount(v28)
    end

    return v26, v27
end

function t1.BoardWorld.with_query_metadata(p15, p16) -- line: 254
    -- upvalues: v9 (copy), QueryMetadata (copy), t1 (copy)
    QueryMetadata.validate(p16, p15)

    local v29 = t1.BoardWorld.new(p15)

    v29.query_index = v9.QueryIndex.new(p16.meshes)
    v29.query_metadata = p16

    return v29
end

function t1.BoardWorld.query_metadata(p17) -- line: 263
    local query_metadata = p17.query_metadata

    if query_metadata == nil then
        error("Canonical world has no authored query metadata", 0)
    end

    return query_metadata
end

function t1.BoardWorld.set_external_queries(p18, p19) -- line: 271
    p18.external = p19
end

function t1.BoardWorld.external_line(p20, p21, p22, p23) -- line: 275
    local external = p20.external

    if external == nil then
        return nil
    end

    return external.line(external, p21, p22, p23)
end

function t1.BoardWorld.external_nearby(p24, p25, p26) -- line: 283
    local external = p24.external

    if external == nil then
        return {}
    end

    return external.nearby(external, p25, p26)
end

function t1.BoardWorld.triangles(p27) -- line: 291
    return p27.triangles
end

function t1.BoardWorld.query_thin_line(p28, p29, p30) -- line: 298
    -- upvalues: t1 (copy)
    return t1.BoardWorld.query_swept_line(p28, p29, p30, 0)
end

local function query_swept_line_r3(p31, p32, p33, p34) -- line: 306
    -- upvalues: rt (copy), Vector3 (copy), triangle_segment (copy), t1 (copy)
    if not (p34 == p34 and p34 ~= 1e999 and p34 ~= (-1e999)) or p34 < 0 then
        error("line query radius must be finite and nonnegative", 0)
    end

    local v30 = Vector3.new(p33.x - p32.x, p33.y - p32.y, p33.z - p32.z)
    local v31 = t1.BoardWorld.external_line(p31, p32, p33, p34)
    local v32 = if v31 == nil then nil else rt.copy(v31.hit)

    for _, v33 in t1.BoardWorld.line_candidates(p31, p32, p33, p34) do
        local v34 = v33[2]
        local t3 = {
            fraction = 0,
            position = rt.copy(Vector3.ZERO),
            normal = rt.copy(Vector3.ZERO),
            volume_parameter = table.create(3, 0)
        }

        if triangle_segment(t3, p32, v30, v34.triangle.vertices, p34, v34.triangle.fatness) and (v32 == nil or t3.fraction < v32.geometry.fraction) then
            v32 = {
                geometry = t3
            }
            v32.tag = v34.tag
        end
    end

    return v32
end

t1.BoardWorld.query_swept_line_r3 = query_swept_line_r3

local v35 = false

function t1.set_swept_r3(p35) -- line: 359
    -- upvalues: v35 (ref)
    local v36 = v35

    v35 = p35

    return v36
end

local triangle_segment_transient = import("skate_core/physics/triangle_query").triangle_segment_transient
local line_candidate_indices = v8.BoardWorld.line_candidate_indices
local v37 = table.create(256, 0)
local v38 = table.freeze({
    x = 0,
    y = 0,
    z = 0
})
local v39 = table.freeze({
    x = 0,
    y = 0,
    z = 0
})
local v40 = table.freeze({ 0, 0, 0 })

function t1.BoardWorld.query_swept_line(p36, p37, p38, p39) -- line: 370
    -- upvalues: rt (copy), Vector3 (copy), t1 (copy), query_swept_line_r3 (copy), v35 (ref), triangle_segment_transient (copy), line_candidate_indices (copy), v37 (copy), v38 (copy), v39 (copy), v40 (copy)
    if v35 then
        return (query_swept_line_r3(p36, p37, p38, p39))
    end

    if not (p39 == p39 and p39 ~= 1e999 and p39 ~= (-1e999)) or p39 < 0 then
        error("line query radius must be finite and nonnegative", 0)
    end

    local v41 = Vector3.new(p38.x - p37.x, p38.y - p37.y, p38.z - p37.z)
    local v42 = t1.BoardWorld.external_line(p36, p37, p38, p39)
    local v43 = if v42 == nil then nil else rt.copy(v42.hit)
    local v44 = line_candidate_indices(p36, p37, p38, p39, v37)
    local triangles = p36.triangles
    local t4

    for i = 1, v44 do
        local v45 = triangles[v37[i] + 1]
        local triangle = v45.triangle

        if t4 == nil then
            t4 = {
                fraction = 0,
                position = v38,
                normal = v39,
                volume_parameter = v40
            }
        end

        if triangle_segment_transient(t4, p37, v41, triangle.vertices, p39, triangle.fatness) and (v43 == nil or t4.fraction < v43.geometry.fraction) then
            if t4.position == v38 then
                t4.position = {
                    x = 0,
                    y = 0,
                    z = 0
                }
            end

            if t4.normal == v39 then
                t4.normal = {
                    x = 0,
                    y = 0,
                    z = 0
                }
            end

            if t4.volume_parameter == v40 then
                t4.volume_parameter = { 0, 0, 0 }
            end

            v43 = {
                geometry = t4,
                tag = v45.tag
            }
            t4 = nil
        else
            t4.position = v38
            t4.normal = v39
            t4.fraction = 0
            t4.volume_parameter = v40
        end
    end

    return v43
end

function t1.BoardWorld.query(p40, p41, p42) -- line: 430
    -- upvalues: rt (copy), BodyId (copy), BoardRuntime (copy), t1 (copy)
    local v46 = BoardRuntime.part_transforms(p41)
    local t5 = {}

    for i = 0, 3 do
        local v47 = BodyId.ORDER[i + 1]
        local v48 = BoardRuntime.bodies(p41)[BodyId.index(v47) + 1]

        if v48.state_flags ~= 1 then
            table.insert(t5, {
                body = {
                    tag = "Board",
                    v47
                },
                primitive = {
                    tag = "Sphere",
                    {
                        center = rt.copy(v46[BodyId.index(v47) + 1].translation),
                        radius = p42.radius
                    }
                },
                linear_velocity = rt.copy(v48.rates.linear_velocity),
                material = rt.copy(p42.material)
            })
        end
    end

    return t1.BoardWorld.query_primitives(p40, t5, p42.query, p42.retention)
end

local collision_from_record
local v49 = buffer.create(8)

local function fb(p43) -- line: 462
    -- upvalues: v49 (copy)
    buffer.writeu32(v49, 0, p43)

    return (buffer.readf32(v49, 0))
end

local to_bits = rt.to_bits

local function tb(p44) -- line: 467
    -- upvalues: v49 (copy), to_bits (copy)
    if p44 ~= 0 and p44 > -1.1754943508222875E-38 and p44 < 1.1754943508222875E-38 then
        return to_bits(p44)
    end

    buffer.writef32(v49, 0, p44)

    return (buffer.readu32(v49, 0))
end

function t1.BoardWorld.query_primitives_reference(p45, p46, p47, p48) -- line: 474
    -- upvalues: rt (copy), conservative_bounds (copy), primitive_bounds (copy), Bounds (copy), combine_contact_materials (copy), ContactBuffer (copy), primitive_triangle_world_contacts_packed (copy), pack_primitive (copy), t1 (copy)
    table.clear(p45.contacts)
    p45.buffer.count = 0
    p45.buffer.flushed = 0
    p45.buffer.dropped = 0
    p45.buffer.full = 0
    p45.buffer.capacity = p48.capacity
    p45.buffer.distance_squared_threshold = p48.duplicate_distance_squared
    p45.buffer.deferred_reduction = p48.deferred_reduction and 1 or 0

    local volume_padding = p47.volume_padding
    local v50 = false

    if volume_padding == volume_padding and volume_padding ~= 1e999 and volume_padding ~= (-1e999) then
        local maximum_separating_distance = p47.maximum_separating_distance

        v50 = maximum_separating_distance == maximum_separating_distance and maximum_separating_distance ~= 1e999 and maximum_separating_distance ~= (-1e999)
    end

    local v51 = if v50 then rt.fmax(p47.volume_padding, 0) + rt.fmax(p47.maximum_separating_distance, 0) else 1e999
    local v52 = table.create(#p46)
    local v53 = true

    for v54, v55 in p46 do
        local v56 = primitive_bounds(v55.primitive)

        if v56 ~= nil then
            v52[v54] = conservative_bounds(v56, v51 + p45.maximum_fatness)
        else
            v53 = false
            v52[v54] = false
        end
    end

    local v57

    if v53 then
        local t7 = {}

        for _, v58 in v52 do
            table.insert(t7, v58.min)
            table.insert(t7, v58.max)
        end

        v57 = Bounds.from_points(t7)

        if v57 ~= nil then
            v57 = Bounds.expanded(v57, v51)
        end
    end

    local v59 = t1.BoardWorld.candidate_ranges(p45, v57)
    local contacts = p45.contacts
    local v60 = table.create(#p46)
    local v61 = table.create(#p46)
    local triangle_gp = p45.triangle_gp

    if triangle_gp == nil then
        triangle_gp = {}
        p45.triangle_gp = triangle_gp
    end

    local function publish(p49) -- line: 522
        -- upvalues: contacts (copy), t1 (copy)
        for _, v62 in p49 do
            table.insert(contacts, t1.collision_from_record_reference(v62))
        end
    end

    local v63 = p45.query_metadata ~= nil
    local v64 = #p46
    local v65 = table.create(v64)
    local v66 = table.create(v64)
    local v67 = table.create(v64)
    local v68 = table.create(v64)
    local v69 = table.create(v64)
    local v70 = table.create(v64)

    for i = 1, v64 do
        local v71 = v52[i]

        if v71 then
            local x, y, z = v71.min.x, v71.min.y, v71.min.z

            v65[i] = x
            v66[i] = y
            v67[i] = z

            local x2, y2, z2 = v71.max.x, v71.max.y, v71.max.z

            v68[i] = x2
            v69[i] = y2
            v70[i] = z2
        end
    end

    local triangles, triangle_bounds = p45.triangles, p45.triangle_bounds

    for _, v72 in v59 do
        for j = v72.start, v72["end"] - 1 do
            local v73 = triangles[j + 1]
            local x, x2, y, y2, z, z2

            if v63 then
                local v74 = triangle_bounds[j + 1]
                local min, max = v74.min, v74.max

                x2 = min.x
                y2 = min.y
                z2 = min.z
                x = max.x
                y = max.y
                z = max.z
            end

            for k = 1, v64 do
                if not v63 or not v52[k] or not (x < v65[k]) and not (v68[k] < x2) and not (y < v66[k]) and not (v69[k] < y2) and not (z < v67[k]) and not (v70[k] < z2) then
                    local v85 = p46[k]
                    local linear_velocity = v85.linear_velocity
                    local normal = v73.triangle.feature.normal
                    local v86 = -normal.x * (linear_velocity.x * 0.01666666753590107) + -normal.y * (linear_velocity.y * 0.01666666753590107) + -normal.z * (linear_velocity.z * 0.01666666753590107)

                    if -v86 >= 0 then
                        v86 = 0
                    end

                    local maximum_separating_distance = p47.maximum_separating_distance

                    if not (maximum_separating_distance - v86 >= 0) then
                        v86 = maximum_separating_distance
                    end

                    local v87 = v86 + p47.volume_padding
                    local v88 = v60[k]

                    if v88 == nil then
                        local v89

                        v88, v89 = pack_primitive(v85.primitive)
                        v60[k] = v88
                        v61[k] = v89
                    end

                    local v90 = triangle_gp[j + 1]

                    if v90 == nil then
                        v90 = pack_primitive({
                            tag = "Triangle",
                            v73.triangle
                        })
                        triangle_gp[j + 1] = v90
                    end

                    local v91 = primitive_triangle_world_contacts_packed(v88, v61[k], v90, "Triangle", v73.triangle, v87, p47)

                    if v91 ~= nil then
                        local v92 = combine_contact_materials(v85.material, v73.material)

                        for n2 = 0, v91.count - 1 do
                            local v93 = v91.points[n2 + 1]
                            local t11 = {
                                position_on_a = rt.copy(v93.a),
                                position_on_b = rt.copy(v93.b),
                                normal = rt.copy(v91.normal),
                                restitution = v92.restitution,
                                static_friction = v92.static_friction,
                                dynamic_friction = v92.dynamic_friction,
                                tag = v73.tag
                            }
                            local v94 = ContactBuffer.allocate(p45.buffer, publish)

                            if v94 == nil then
                                ContactBuffer.flush(p45.buffer, publish)

                                return p45.contacts
                            end

                            p45.buffer.records[v94 + 1] = t1.retention_record(v85.body, t11)

                            if ContactBuffer.last_is_duplicate(p45.buffer) then
                                p45.buffer.count -= 1
                            end
                        end
                    end
                end
            end
        end
    end

    ContactBuffer.flush(p45.buffer, publish)

    return p45.contacts
end

local primitive_triangle_world_contacts_flat, flat_points = v12.primitive_triangle_world_contacts_flat, v12.flat_points
local primitive_conservative_bounds_scalar, flat_triangle_bounds = v8.primitive_conservative_bounds_scalar, v8.flat_triangle_bounds
local contact_id = CollisionBody.contact_id
local last_is_duplicate = ContactBuffer.last_is_duplicate
local is_finite, fmin, fmax = rt.is_finite, rt.fmin, rt.fmax
local v95 = true
local t12 = {
    {
        used = 0,
        rows = {}
    },
    {
        used = 0,
        rows = {}
    }
}

function t1.set_publish_pool(p50) -- line: 678
    -- upvalues: v95 (ref)
    local v96 = v95

    v95 = p50

    return v96
end

local function collision_into_pool(p51, p52) -- line: 683
    -- upvalues: CollisionBody (copy), v49 (copy)
    local v97, v98 = CollisionBody.decode_contact_id(p52[4])
    local v99 = p51.used + 1

    p51.used = v99

    local rows = p51.rows
    local v100 = rows[v99]

    if v100 == nil then
        v100 = {
            body_a = {},
            body_b = {
                tag = "StaticWorld"
            },
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
        rows[v99] = v100
    end

    local body_a = v100.body_a

    if v97 == 0 then
        body_a.tag = "StaticWorld"
        body_a[1] = nil
    else
        if v97 == 1 then
            body_a.tag = "Board"
        else
            body_a.tag = "Attached"
        end

        body_a[1] = v98
    end

    local body_b = v100.body_b

    body_b.tag = "StaticWorld"
    body_b[1] = nil

    local contact = v100.contact
    local position_on_a = contact.position_on_a

    buffer.writeu32(v49, 0, p52[1])

    local v102 = buffer.readf32(v49, 0)

    buffer.writeu32(v49, 0, p52[2])

    local v104 = buffer.readf32(v49, 0)

    buffer.writeu32(v49, 0, p52[3])

    local v106 = buffer.readf32(v49, 0)

    position_on_a.x = v102
    position_on_a.y = v104
    position_on_a.z = v106

    local position_on_b = contact.position_on_b

    buffer.writeu32(v49, 0, p52[5])

    local v108 = buffer.readf32(v49, 0)

    buffer.writeu32(v49, 0, p52[6])

    local v110 = buffer.readf32(v49, 0)

    buffer.writeu32(v49, 0, p52[7])

    local v112 = buffer.readf32(v49, 0)

    position_on_b.x = v108
    position_on_b.y = v110
    position_on_b.z = v112

    local normal = contact.normal

    buffer.writeu32(v49, 0, p52[9])

    local v114 = buffer.readf32(v49, 0)

    buffer.writeu32(v49, 0, p52[10])

    local v116 = buffer.readf32(v49, 0)

    buffer.writeu32(v49, 0, p52[11])

    local v118 = buffer.readf32(v49, 0)

    normal.x = v114
    normal.y = v116
    normal.z = v118
    buffer.writeu32(v49, 0, p52[12])
    contact.restitution = buffer.readf32(v49, 0)
    buffer.writeu32(v49, 0, p52[16])
    contact.static_friction = buffer.readf32(v49, 0)
    buffer.writeu32(v49, 0, p52[20])
    contact.dynamic_friction = buffer.readf32(v49, 0)
    contact.tag = p52[24]

    return v100
end

local function flush_publish(p53, p54, p55) -- line: 733
    -- upvalues: rt (copy), ContactBuffer (copy), collision_from_record (ref), collision_into_pool (copy)
    if p53.count == 0 then
        return
    end

    if p53.deferred_reduction ~= 0 then
        ContactBuffer.reduce(p53)
    end

    local records = p53.records

    if p55 ~= nil then
        for i = 1, p53.count do
            if p55.used < 256 then
                table.insert(p54, (collision_into_pool(p55, records[i])))
            else
                local collision_from_record2 = collision_from_record

                table.insert(p54, collision_from_record2(records[i]))
            end
        end
    else
        for i = 1, p53.count do
            local collision_from_record2 = collision_from_record

            table.insert(p54, collision_from_record2(records[i]))
        end
    end

    p53.flushed = rt.wrapping_add_u32(p53.flushed, p53.count)
    p53.count = 0
end

local function allocate_publish(p56, p57, p58) -- line: 760
    -- upvalues: rt (copy), ContactBuffer (copy), flush_publish (copy)
    if not (p56.count <= 50) then
        error("assertion failed: self.count <= 50", 0)
    end

    if rt.wrapping_add_u32(p56.count, p56.flushed) >= p56.capacity then
        if p56.full == 0 then
            if p56.deferred_reduction ~= 0 then
                ContactBuffer.reduce(p56)
            end

            if rt.wrapping_add_u32(p56.count, p56.flushed) >= p56.capacity then
                p56.full = 1
            end
        end

        if p56.full ~= 0 then
            p56.dropped = rt.wrapping_add_u32(p56.dropped, 1)

            return nil
        end
    end

    if p56.count >= 50 then
        if p56.allow_flush == 0 then
            p56.full = 1

            return nil
        end

        flush_publish(p56, p57, p58)
    end

    local count = p56.count

    p56.count += 1

    return count
end

local t13 = {}
local t14 = {}
local t15 = {}
local t16 = {}
local t17 = {}
local t18 = {}
local t19 = {}
local t20 = {}
local t21 = {}
local t22 = {}
local n3 = 0
local v125 = table.create(64, 0)
local pack_primitive_into = v12.pack_primitive_into

local function query_primitives_gr(p59, p60, p61, p62) -- line: 831
    -- upvalues: rt (copy), Vector3 (copy), combine_contact_materials (copy), ContactBuffer (copy), pack_primitive (copy), t1 (copy), collision_from_record (ref), v49 (copy), to_bits (copy), primitive_triangle_world_contacts_flat (copy), flat_points (copy), primitive_conservative_bounds_scalar (copy), flat_triangle_bounds (copy), contact_id (copy), last_is_duplicate (copy), is_finite (copy), fmin (copy), fmax (copy), allocate_publish (copy), t13 (copy), t14 (copy), t15 (copy), t16 (copy), t17 (copy), t18 (copy), t19 (copy), t20 (copy), t21 (copy), t22 (copy), n3 (ref), v125 (copy), pack_primitive_into (copy)
    table.clear(p59.contacts)

    local _buffer = p59.buffer

    _buffer.count = 0
    _buffer.flushed = 0
    _buffer.dropped = 0
    _buffer.full = 0
    _buffer.capacity = p62.capacity
    _buffer.distance_squared_threshold = p62.duplicate_distance_squared
    _buffer.deferred_reduction = p62.deferred_reduction and 1 or 0

    local v126 = p61.volume_padding
    local v127, v128

    if v126 == v126 and v126 ~= 1e999 and v126 ~= (-1e999) then
        v126 = p61.maximum_separating_distance
        v127 = v126 == v126 and v126 ~= 1e999 and v126 ~= (-1e999)
        v128 = not not v127
    else
        v128 = false
    end

    local v129 = if v128 then rt.fmax(p61.volume_padding, 0) + rt.fmax(p61.maximum_separating_distance, 0) else 1e999

    v127 = #p60

    if v127 == 0 then
        if p59.triangle_gp == nil then
            p59.triangle_gp = {}
        end

        v126 = p59.contacts

        if _buffer.count ~= 0 then
            if _buffer.deferred_reduction ~= 0 then
                ContactBuffer.reduce(_buffer)
            end

            local records = _buffer.records

            for i = 1, _buffer.count do
                local collision_from_record2 = collision_from_record

                table.insert(v126, collision_from_record2(records[i]))
            end

            _buffer.flushed = rt.wrapping_add_u32(_buffer.flushed, _buffer.count)
            _buffer.count = 0
        end
    else
        local v130 = true
        local v131, v132, v133, maximum_separating_distance

        for i = 1, v127 do
            local v134, v135

            v134, v135, v131, v132, v133, maximum_separating_distance = primitive_conservative_bounds_scalar(p60[i].primitive, v129 + p59.maximum_fatness)

            if v134 ~= nil then
                t13[i] = true
                t14[i] = v134
                t15[i] = v135
                t16[i] = v131
                t17[i] = v132
                t18[i] = v133
                t19[i] = maximum_separating_distance
            else
                v130 = false
                t13[i] = false
            end
        end

        local v136, v137, contacts, v138, triangle_gp, triangles, v139

        if v130 and v127 > 0 then
            v136 = t14[1]

            local v140 = t15[1]
            local v141 = t16[1]

            v138 = is_finite(v136) and is_finite(v140) and is_finite(v141)
            v131 = v136
            v132 = v140
            v133 = v141

            if v138 then
                for i = 1, v127 do
                    local v142, v143, v144, v145, v146

                    if i > 1 then
                        v137 = t14[i]
                        v142 = t15[i]
                        v143 = t16[i]

                        if is_finite(v137) and is_finite(v142) and is_finite(v143) then
                            v144 = fmin(v136, v137)
                            v145 = fmin(v140, v142)
                            v146 = fmin(v141, v143)
                            triangle_gp = fmax(v131, v137)
                            v139 = fmax(v132, v142)
                            triangles = fmax(v133, v143)
                        else
                            v138 = false
                            break
                        end
                    else
                        triangles = v133
                        v144 = v136
                        v145 = v140
                        v146 = v141
                        triangle_gp = v131
                        v139 = v132
                    end

                    v137 = t17[i]
                    v142 = t18[i]
                    v143 = t19[i]

                    if not (is_finite(v137) and is_finite(v142) and is_finite(v143)) then
                        v136 = v144
                        v140 = v145
                        v141 = v146
                        v138 = false
                        v131 = triangle_gp
                        v132 = v139
                        v133 = triangles
                        break
                    end

                    v136 = fmin(v144, v137)
                    v140 = fmin(v145, v142)
                    v141 = fmin(v146, v143)
                    v131 = fmax(triangle_gp, v137)
                    v132 = fmax(v139, v142)
                    v133 = fmax(triangles, v143)
                end
            end

            if v138 then
                contacts = {
                    min = Vector3.new(v136 - v129, v140 - v129, v141 - v129),
                    max = Vector3.new(v131 + v129, v132 + v129, v133 + v129)
                }
            else
                contacts = nil
            end
        end

        v136 = t1.BoardWorld.candidate_ranges(p59, contacts)
        contacts = p59.contacts
        n3 += 1
        v138 = n3
        triangle_gp = p59.triangle_gp

        if triangle_gp == nil then
            triangle_gp = {}
            p59.triangle_gp = triangle_gp
        end

        v139 = p59.query_metadata ~= nil
        triangles = p59.triangles
        maximum_separating_distance = p61.maximum_separating_distance

        local volume_padding = p61.volume_padding
        local v147 = if v139 then flat_triangle_bounds(p59) else nil

        v137 = v139 and v130 and v127 > 0

        local v148, v149, v150, v151, v152, v153, v154, v155, v156, v157, v158

        if v137 then
            local v159 = t14[1]
            local v160 = t15[1]
            local v161 = t16[1]
            local v162 = t17[1]
            local v163 = t18[1]
            local v164 = t19[1]
            local v165 = v159 == v159 and v160 == v160 and v161 == v161 and v162 == v162 and v163 == v163 and v164 == v164 and v137

            v152 = v159
            v153 = v160
            v154 = v161
            v155 = v162
            v156 = v163
            v157 = v164
            v158 = v165

            for i = 2, v127 do
                local v166 = t14[i]
                local v167 = t15[i]

                v148 = t16[i]
                v149 = t17[i]
                v150 = t18[i]
                v151 = t19[i]

                if v166 ~= v166
                    or v167 ~= v167
                    or v148 ~= v148
                    or v149 ~= v149
                    or v150 ~= v150
                    or v151 ~= v151 then
                    v158 = false
                    break
                end

                v158 = v165

                if v166 < v152 then
                    v152 = v166
                end

                if v167 < v153 then
                    v153 = v167
                end

                if v148 < v154 then
                    v154 = v148
                end

                if v155 < v149 then
                    v155 = v149
                end

                if v156 < v150 then
                    v156 = v150
                end

                if v157 < v151 then
                    v157 = v151
                end
            end
        else
            v158 = v137
        end

        for _, v168 in v136 do
            v150 = v168.start
            v148 = v168["end"] - 1

            for j = v150, v148 do
                if v139 then
                    v130 = j * 6
                    v151 = v147[v130 + 1]

                    local v169 = v147[v130 + 2]
                    local v170 = v147[v130 + 3]
                    local v171 = v147[v130 + 4]
                    local v172 = v147[v130 + 5]
                    local v173 = v147[v130 + 6]

                    if v158 then
                        if not (v171 < v152) and not (v155 < v151) and not (v172 < v153) and not (v156 < v169) and not (v173 < v154) and not (v157 < v170) then
                            local v174 = triangles[j + 1]

                            for k = 1, v127 do
                                local v175 = t13[k]

                                if v175 then
                                    v175 = t14[k]

                                    if not (v171 < v175) then
                                        v175 = t17[k]

                                        if not (v175 < v151) then
                                            v175 = t15[k]

                                            if not (v172 < v175) then
                                                v175 = t18[k]

                                                if not (v175 < v169) then
                                                    v175 = t16[k]

                                                    if not (v173 < v175) then
                                                        v175 = t19[k]

                                                        if not (v175 < v170) then
                                                            v175 = p60[k]

                                                            local dynamic_friction = v174.triangle
                                                            local restitution = v175.linear_velocity
                                                            local tag = dynamic_friction.feature.normal
                                                            local v176 = -tag.x * (restitution.x * 0.01666666753590107) + -tag.y * (restitution.y * 0.01666666753590107) + -tag.z * (restitution.z * 0.01666666753590107)

                                                            if -v176 >= 0 then
                                                                v176 = 0
                                                            end

                                                            if not (maximum_separating_distance - v176 >= 0) then
                                                                v176 = maximum_separating_distance
                                                            end

                                                            local static_friction = v176 + volume_padding

                                                            tag = t22[k]

                                                            if tag == v138 then
                                                                restitution = t20[k]
                                                            else
                                                                restitution = t20[k]

                                                                if restitution == nil then
                                                                    restitution = table.create(48, 0)
                                                                    t20[k] = restitution
                                                                end

                                                                tag, v176 = pack_primitive_into(restitution, v175.primitive)
                                                                t21[k] = v176
                                                                t22[k] = v138
                                                            end

                                                            tag = triangle_gp[j + 1]

                                                            if tag == nil then
                                                                tag = pack_primitive({
                                                                    tag = "Triangle",
                                                                    dynamic_friction
                                                                })
                                                                triangle_gp[j + 1] = tag
                                                            end

                                                            local v177, v178, v179

                                                            v176, v177, v178, v179 = primitive_triangle_world_contacts_flat(restitution, t21[k], tag, "Triangle", dynamic_friction, static_friction, p61)

                                                            if v176 ~= nil then
                                                                local v180 = combine_contact_materials(v175.material, v174.material)

                                                                restitution = v180.restitution
                                                                static_friction = v180.static_friction
                                                                dynamic_friction = v180.dynamic_friction
                                                                tag = v174.tag

                                                                for n = 0, v176 - 1 do
                                                                    local v181 = n * 6
                                                                    local v182 = flat_points[v181 + 1]
                                                                    local v183 = flat_points[v181 + 2]
                                                                    local v184 = flat_points[v181 + 3]
                                                                    local v185 = flat_points[v181 + 4]
                                                                    local v186 = flat_points[v181 + 5]
                                                                    local v187 = flat_points[v181 + 6]
                                                                    local v188 = allocate_publish(_buffer, contacts)
                                                                    local v189

                                                                    if v188 == nil then
                                                                        if _buffer.count == 0 then
                                                                            return p59.contacts
                                                                        end

                                                                        if _buffer.deferred_reduction ~= 0 then
                                                                            ContactBuffer.reduce(_buffer)
                                                                        end

                                                                        v188 = _buffer.records
                                                                        v189 = _buffer.count

                                                                        for n2 = 1, v189 do
                                                                            local collision_from_record2 = collision_from_record

                                                                            table.insert(contacts, collision_from_record2(v188[n2]))
                                                                        end

                                                                        _buffer.flushed = rt.wrapping_add_u32(_buffer.flushed, _buffer.count)
                                                                        _buffer.count = 0

                                                                        return p59.contacts
                                                                    end

                                                                    local records = _buffer.records

                                                                    v189 = records[v188 + 1]

                                                                    if v189 ~= nil then
                                                                        if #v189 == 64 then
                                                                            table.move(v125, 1, 64, 1, v189)
                                                                        else
                                                                            v189 = table.create(64, 0)
                                                                            records[v188 + 1] = v189
                                                                        end
                                                                    else
                                                                        v189 = table.create(64, 0)
                                                                        records[v188 + 1] = v189
                                                                    end

                                                                    local v191

                                                                    if v182 == 0 then
                                                                        buffer.writef32(v49, 0, v182)
                                                                        v191 = buffer.readu32(v49, 0)
                                                                    elseif v182 > -1.1754943508222875E-38 and v182 < 1.1754943508222875E-38 then
                                                                        v191 = to_bits(v182)
                                                                    else
                                                                        buffer.writef32(v49, 0, v182)
                                                                        v191 = buffer.readu32(v49, 0)
                                                                    end

                                                                    local v192

                                                                    if v183 == 0 then
                                                                        buffer.writef32(v49, 0, v183)
                                                                        v192 = buffer.readu32(v49, 0)
                                                                    elseif v183 > -1.1754943508222875E-38 and v183 < 1.1754943508222875E-38 then
                                                                        v192 = to_bits(v183)
                                                                    else
                                                                        buffer.writef32(v49, 0, v183)
                                                                        v192 = buffer.readu32(v49, 0)
                                                                    end

                                                                    local v193

                                                                    if v184 == 0 then
                                                                        buffer.writef32(v49, 0, v184)
                                                                        v193 = buffer.readu32(v49, 0)
                                                                    elseif v184 > -1.1754943508222875E-38 and v184 < 1.1754943508222875E-38 then
                                                                        v193 = to_bits(v184)
                                                                    else
                                                                        buffer.writef32(v49, 0, v184)
                                                                        v193 = buffer.readu32(v49, 0)
                                                                    end

                                                                    v189[1] = v191
                                                                    v189[2] = v192
                                                                    v189[3] = v193

                                                                    if v185 == 0 then
                                                                        buffer.writef32(v49, 0, v185)
                                                                        v191 = buffer.readu32(v49, 0)
                                                                    elseif v185 > -1.1754943508222875E-38 and v185 < 1.1754943508222875E-38 then
                                                                        v191 = to_bits(v185)
                                                                    else
                                                                        buffer.writef32(v49, 0, v185)
                                                                        v191 = buffer.readu32(v49, 0)
                                                                    end

                                                                    if v186 == 0 then
                                                                        buffer.writef32(v49, 0, v186)
                                                                        v192 = buffer.readu32(v49, 0)
                                                                    elseif v186 > -1.1754943508222875E-38 and v186 < 1.1754943508222875E-38 then
                                                                        v192 = to_bits(v186)
                                                                    else
                                                                        buffer.writef32(v49, 0, v186)
                                                                        v192 = buffer.readu32(v49, 0)
                                                                    end

                                                                    if v187 == 0 then
                                                                        buffer.writef32(v49, 0, v187)
                                                                        v193 = buffer.readu32(v49, 0)
                                                                    elseif v187 > -1.1754943508222875E-38 and v187 < 1.1754943508222875E-38 then
                                                                        v193 = to_bits(v187)
                                                                    else
                                                                        buffer.writef32(v49, 0, v187)
                                                                        v193 = buffer.readu32(v49, 0)
                                                                    end

                                                                    v189[5] = v191
                                                                    v189[6] = v192
                                                                    v189[7] = v193

                                                                    if v177 == 0 then
                                                                        buffer.writef32(v49, 0, v177)
                                                                        v191 = buffer.readu32(v49, 0)
                                                                    elseif v177 > -1.1754943508222875E-38 and v177 < 1.1754943508222875E-38 then
                                                                        v191 = to_bits(v177)
                                                                    else
                                                                        buffer.writef32(v49, 0, v177)
                                                                        v191 = buffer.readu32(v49, 0)
                                                                    end

                                                                    if v178 == 0 then
                                                                        buffer.writef32(v49, 0, v178)
                                                                        v192 = buffer.readu32(v49, 0)
                                                                    elseif v178 > -1.1754943508222875E-38 and v178 < 1.1754943508222875E-38 then
                                                                        v192 = to_bits(v178)
                                                                    else
                                                                        buffer.writef32(v49, 0, v178)
                                                                        v192 = buffer.readu32(v49, 0)
                                                                    end

                                                                    if v179 == 0 then
                                                                        buffer.writef32(v49, 0, v179)
                                                                        v193 = buffer.readu32(v49, 0)
                                                                    elseif v179 > -1.1754943508222875E-38 and v179 < 1.1754943508222875E-38 then
                                                                        v193 = to_bits(v179)
                                                                    else
                                                                        buffer.writef32(v49, 0, v179)
                                                                        v193 = buffer.readu32(v49, 0)
                                                                    end

                                                                    v189[9] = v191
                                                                    v189[10] = v192
                                                                    v189[11] = v193
                                                                    v189[4] = contact_id(v175.body)
                                                                    v189[8] = 4294967295

                                                                    if restitution == 0 then
                                                                        buffer.writef32(v49, 0, restitution)
                                                                        v189[12] = buffer.readu32(v49, 0)
                                                                    elseif restitution > -1.1754943508222875E-38 and restitution < 1.1754943508222875E-38 then
                                                                        v189[12] = to_bits(restitution)
                                                                    else
                                                                        buffer.writef32(v49, 0, restitution)
                                                                        v189[12] = buffer.readu32(v49, 0)
                                                                    end

                                                                    if static_friction == 0 then
                                                                        buffer.writef32(v49, 0, static_friction)
                                                                        v189[16] = buffer.readu32(v49, 0)
                                                                    elseif static_friction > -1.1754943508222875E-38 and static_friction < 1.1754943508222875E-38 then
                                                                        v189[16] = to_bits(static_friction)
                                                                    else
                                                                        buffer.writef32(v49, 0, static_friction)
                                                                        v189[16] = buffer.readu32(v49, 0)
                                                                    end

                                                                    if dynamic_friction == 0 then
                                                                        buffer.writef32(v49, 0, dynamic_friction)
                                                                        v189[20] = buffer.readu32(v49, 0)
                                                                    elseif dynamic_friction > -1.1754943508222875E-38 and dynamic_friction < 1.1754943508222875E-38 then
                                                                        v189[20] = to_bits(dynamic_friction)
                                                                    else
                                                                        buffer.writef32(v49, 0, dynamic_friction)
                                                                        v189[20] = buffer.readu32(v49, 0)
                                                                    end

                                                                    v189[24] = tag

                                                                    if last_is_duplicate(_buffer) then
                                                                        _buffer.count -= 1
                                                                    end
                                                                end
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                else
                                    v175 = p60[k]

                                    local dynamic_friction = v174.triangle
                                    local restitution = v175.linear_velocity
                                    local tag = dynamic_friction.feature.normal
                                    local v194 = -tag.x * (restitution.x * 0.01666666753590107) + -tag.y * (restitution.y * 0.01666666753590107) + -tag.z * (restitution.z * 0.01666666753590107)

                                    if -v194 >= 0 then
                                        v194 = 0
                                    end

                                    if not (maximum_separating_distance - v194 >= 0) then
                                        v194 = maximum_separating_distance
                                    end

                                    local static_friction = v194 + volume_padding

                                    tag = t22[k]

                                    if tag == v138 then
                                        restitution = t20[k]
                                    else
                                        restitution = t20[k]

                                        if restitution == nil then
                                            restitution = table.create(48, 0)
                                            t20[k] = restitution
                                        end

                                        tag, v194 = pack_primitive_into(restitution, v175.primitive)
                                        t21[k] = v194
                                        t22[k] = v138
                                    end

                                    tag = triangle_gp[j + 1]

                                    if tag == nil then
                                        tag = pack_primitive({
                                            tag = "Triangle",
                                            dynamic_friction
                                        })
                                        triangle_gp[j + 1] = tag
                                    end

                                    local v195, v196, v197

                                    v194, v195, v196, v197 = primitive_triangle_world_contacts_flat(restitution, t21[k], tag, "Triangle", dynamic_friction, static_friction, p61)

                                    if v194 ~= nil then
                                        local v198 = combine_contact_materials(v175.material, v174.material)

                                        restitution = v198.restitution
                                        static_friction = v198.static_friction
                                        dynamic_friction = v198.dynamic_friction
                                        tag = v174.tag

                                        for n3 = 0, v194 - 1 do
                                            local v199 = n3 * 6
                                            local v200 = flat_points[v199 + 1]
                                            local v201 = flat_points[v199 + 2]
                                            local v202 = flat_points[v199 + 3]
                                            local v203 = flat_points[v199 + 4]
                                            local v204 = flat_points[v199 + 5]
                                            local v205 = flat_points[v199 + 6]
                                            local v206 = allocate_publish(_buffer, contacts)
                                            local v207

                                            if v206 == nil then
                                                if _buffer.count == 0 then
                                                    return p59.contacts
                                                end

                                                if _buffer.deferred_reduction ~= 0 then
                                                    ContactBuffer.reduce(_buffer)
                                                end

                                                v206 = _buffer.records
                                                v207 = _buffer.count

                                                for n4 = 1, v207 do
                                                    local collision_from_record2 = collision_from_record

                                                    table.insert(contacts, collision_from_record2(v206[n4]))
                                                end

                                                _buffer.flushed = rt.wrapping_add_u32(_buffer.flushed, _buffer.count)
                                                _buffer.count = 0

                                                return p59.contacts
                                            end

                                            local records = _buffer.records

                                            v207 = records[v206 + 1]

                                            if v207 ~= nil then
                                                if #v207 == 64 then
                                                    table.move(v125, 1, 64, 1, v207)
                                                else
                                                    v207 = table.create(64, 0)
                                                    records[v206 + 1] = v207
                                                end
                                            else
                                                v207 = table.create(64, 0)
                                                records[v206 + 1] = v207
                                            end

                                            local v209

                                            if v200 == 0 then
                                                buffer.writef32(v49, 0, v200)
                                                v209 = buffer.readu32(v49, 0)
                                            elseif v200 > -1.1754943508222875E-38 and v200 < 1.1754943508222875E-38 then
                                                v209 = to_bits(v200)
                                            else
                                                buffer.writef32(v49, 0, v200)
                                                v209 = buffer.readu32(v49, 0)
                                            end

                                            local v210

                                            if v201 == 0 then
                                                buffer.writef32(v49, 0, v201)
                                                v210 = buffer.readu32(v49, 0)
                                            elseif v201 > -1.1754943508222875E-38 and v201 < 1.1754943508222875E-38 then
                                                v210 = to_bits(v201)
                                            else
                                                buffer.writef32(v49, 0, v201)
                                                v210 = buffer.readu32(v49, 0)
                                            end

                                            local v211

                                            if v202 == 0 then
                                                buffer.writef32(v49, 0, v202)
                                                v211 = buffer.readu32(v49, 0)
                                            elseif v202 > -1.1754943508222875E-38 and v202 < 1.1754943508222875E-38 then
                                                v211 = to_bits(v202)
                                            else
                                                buffer.writef32(v49, 0, v202)
                                                v211 = buffer.readu32(v49, 0)
                                            end

                                            v207[1] = v209
                                            v207[2] = v210
                                            v207[3] = v211

                                            if v203 == 0 then
                                                buffer.writef32(v49, 0, v203)
                                                v209 = buffer.readu32(v49, 0)
                                            elseif v203 > -1.1754943508222875E-38 and v203 < 1.1754943508222875E-38 then
                                                v209 = to_bits(v203)
                                            else
                                                buffer.writef32(v49, 0, v203)
                                                v209 = buffer.readu32(v49, 0)
                                            end

                                            if v204 == 0 then
                                                buffer.writef32(v49, 0, v204)
                                                v210 = buffer.readu32(v49, 0)
                                            elseif v204 > -1.1754943508222875E-38 and v204 < 1.1754943508222875E-38 then
                                                v210 = to_bits(v204)
                                            else
                                                buffer.writef32(v49, 0, v204)
                                                v210 = buffer.readu32(v49, 0)
                                            end

                                            if v205 == 0 then
                                                buffer.writef32(v49, 0, v205)
                                                v211 = buffer.readu32(v49, 0)
                                            elseif v205 > -1.1754943508222875E-38 and v205 < 1.1754943508222875E-38 then
                                                v211 = to_bits(v205)
                                            else
                                                buffer.writef32(v49, 0, v205)
                                                v211 = buffer.readu32(v49, 0)
                                            end

                                            v207[5] = v209
                                            v207[6] = v210
                                            v207[7] = v211

                                            if v195 == 0 then
                                                buffer.writef32(v49, 0, v195)
                                                v209 = buffer.readu32(v49, 0)
                                            elseif v195 > -1.1754943508222875E-38 and v195 < 1.1754943508222875E-38 then
                                                v209 = to_bits(v195)
                                            else
                                                buffer.writef32(v49, 0, v195)
                                                v209 = buffer.readu32(v49, 0)
                                            end

                                            if v196 == 0 then
                                                buffer.writef32(v49, 0, v196)
                                                v210 = buffer.readu32(v49, 0)
                                            elseif v196 > -1.1754943508222875E-38 and v196 < 1.1754943508222875E-38 then
                                                v210 = to_bits(v196)
                                            else
                                                buffer.writef32(v49, 0, v196)
                                                v210 = buffer.readu32(v49, 0)
                                            end

                                            if v197 == 0 then
                                                buffer.writef32(v49, 0, v197)
                                                v211 = buffer.readu32(v49, 0)
                                            elseif v197 > -1.1754943508222875E-38 and v197 < 1.1754943508222875E-38 then
                                                v211 = to_bits(v197)
                                            else
                                                buffer.writef32(v49, 0, v197)
                                                v211 = buffer.readu32(v49, 0)
                                            end

                                            v207[9] = v209
                                            v207[10] = v210
                                            v207[11] = v211
                                            v207[4] = contact_id(v175.body)
                                            v207[8] = 4294967295

                                            if restitution == 0 then
                                                buffer.writef32(v49, 0, restitution)
                                                v207[12] = buffer.readu32(v49, 0)
                                            elseif restitution > -1.1754943508222875E-38 and restitution < 1.1754943508222875E-38 then
                                                v207[12] = to_bits(restitution)
                                            else
                                                buffer.writef32(v49, 0, restitution)
                                                v207[12] = buffer.readu32(v49, 0)
                                            end

                                            if static_friction == 0 then
                                                buffer.writef32(v49, 0, static_friction)
                                                v207[16] = buffer.readu32(v49, 0)
                                            elseif static_friction > -1.1754943508222875E-38 and static_friction < 1.1754943508222875E-38 then
                                                v207[16] = to_bits(static_friction)
                                            else
                                                buffer.writef32(v49, 0, static_friction)
                                                v207[16] = buffer.readu32(v49, 0)
                                            end

                                            if dynamic_friction == 0 then
                                                buffer.writef32(v49, 0, dynamic_friction)
                                                v207[20] = buffer.readu32(v49, 0)
                                            elseif dynamic_friction > -1.1754943508222875E-38 and dynamic_friction < 1.1754943508222875E-38 then
                                                v207[20] = to_bits(dynamic_friction)
                                            else
                                                buffer.writef32(v49, 0, dynamic_friction)
                                                v207[20] = buffer.readu32(v49, 0)
                                            end

                                            v207[24] = tag

                                            if last_is_duplicate(_buffer) then
                                                _buffer.count -= 1
                                            end
                                        end
                                    end
                                end
                            end
                        end
                    else
                        local v212 = triangles[j + 1]

                        for n5 = 1, v127 do
                            local v213 = t13[n5]

                            if v213 then
                                v213 = t14[n5]

                                if not (v171 < v213) then
                                    v213 = t17[n5]

                                    if not (v213 < v151) then
                                        v213 = t15[n5]

                                        if not (v172 < v213) then
                                            v213 = t18[n5]

                                            if not (v213 < v169) then
                                                v213 = t16[n5]

                                                if not (v173 < v213) then
                                                    v213 = t19[n5]

                                                    if not (v213 < v170) then
                                                        v213 = p60[n5]

                                                        local dynamic_friction = v212.triangle
                                                        local restitution = v213.linear_velocity
                                                        local tag = dynamic_friction.feature.normal
                                                        local v214 = -tag.x * (restitution.x * 0.01666666753590107) + -tag.y * (restitution.y * 0.01666666753590107) + -tag.z * (restitution.z * 0.01666666753590107)

                                                        if -v214 >= 0 then
                                                            v214 = 0
                                                        end

                                                        if not (maximum_separating_distance - v214 >= 0) then
                                                            v214 = maximum_separating_distance
                                                        end

                                                        local static_friction = v214 + volume_padding

                                                        tag = t22[n5]

                                                        if tag == v138 then
                                                            restitution = t20[n5]
                                                        else
                                                            restitution = t20[n5]

                                                            if restitution == nil then
                                                                restitution = table.create(48, 0)
                                                                t20[n5] = restitution
                                                            end

                                                            tag, v214 = pack_primitive_into(restitution, v213.primitive)
                                                            t21[n5] = v214
                                                            t22[n5] = v138
                                                        end

                                                        tag = triangle_gp[j + 1]

                                                        if tag == nil then
                                                            tag = pack_primitive({
                                                                tag = "Triangle",
                                                                dynamic_friction
                                                            })
                                                            triangle_gp[j + 1] = tag
                                                        end

                                                        local v215, v216, v217

                                                        v214, v215, v216, v217 = primitive_triangle_world_contacts_flat(restitution, t21[n5], tag, "Triangle", dynamic_friction, static_friction, p61)

                                                        if v214 ~= nil then
                                                            local v218 = combine_contact_materials(v213.material, v212.material)

                                                            restitution = v218.restitution
                                                            static_friction = v218.static_friction
                                                            dynamic_friction = v218.dynamic_friction
                                                            tag = v212.tag

                                                            for n6 = 0, v214 - 1 do
                                                                local v219 = n6 * 6
                                                                local v220 = flat_points[v219 + 1]
                                                                local v221 = flat_points[v219 + 2]
                                                                local v222 = flat_points[v219 + 3]
                                                                local v223 = flat_points[v219 + 4]
                                                                local v224 = flat_points[v219 + 5]
                                                                local v225 = flat_points[v219 + 6]
                                                                local v226 = allocate_publish(_buffer, contacts)
                                                                local v227

                                                                if v226 == nil then
                                                                    if _buffer.count == 0 then
                                                                        return p59.contacts
                                                                    end

                                                                    if _buffer.deferred_reduction ~= 0 then
                                                                        ContactBuffer.reduce(_buffer)
                                                                    end

                                                                    v226 = _buffer.records
                                                                    v227 = _buffer.count

                                                                    for n7 = 1, v227 do
                                                                        local collision_from_record2 = collision_from_record

                                                                        table.insert(contacts, collision_from_record2(v226[n7]))
                                                                    end

                                                                    _buffer.flushed = rt.wrapping_add_u32(_buffer.flushed, _buffer.count)
                                                                    _buffer.count = 0

                                                                    return p59.contacts
                                                                end

                                                                local records = _buffer.records

                                                                v227 = records[v226 + 1]

                                                                if v227 ~= nil then
                                                                    if #v227 == 64 then
                                                                        table.move(v125, 1, 64, 1, v227)
                                                                    else
                                                                        v227 = table.create(64, 0)
                                                                        records[v226 + 1] = v227
                                                                    end
                                                                else
                                                                    v227 = table.create(64, 0)
                                                                    records[v226 + 1] = v227
                                                                end

                                                                local v229

                                                                if v220 == 0 then
                                                                    buffer.writef32(v49, 0, v220)
                                                                    v229 = buffer.readu32(v49, 0)
                                                                elseif v220 > -1.1754943508222875E-38 and v220 < 1.1754943508222875E-38 then
                                                                    v229 = to_bits(v220)
                                                                else
                                                                    buffer.writef32(v49, 0, v220)
                                                                    v229 = buffer.readu32(v49, 0)
                                                                end

                                                                local v230

                                                                if v221 == 0 then
                                                                    buffer.writef32(v49, 0, v221)
                                                                    v230 = buffer.readu32(v49, 0)
                                                                elseif v221 > -1.1754943508222875E-38 and v221 < 1.1754943508222875E-38 then
                                                                    v230 = to_bits(v221)
                                                                else
                                                                    buffer.writef32(v49, 0, v221)
                                                                    v230 = buffer.readu32(v49, 0)
                                                                end

                                                                local v231

                                                                if v222 == 0 then
                                                                    buffer.writef32(v49, 0, v222)
                                                                    v231 = buffer.readu32(v49, 0)
                                                                elseif v222 > -1.1754943508222875E-38 and v222 < 1.1754943508222875E-38 then
                                                                    v231 = to_bits(v222)
                                                                else
                                                                    buffer.writef32(v49, 0, v222)
                                                                    v231 = buffer.readu32(v49, 0)
                                                                end

                                                                v227[1] = v229
                                                                v227[2] = v230
                                                                v227[3] = v231

                                                                if v223 == 0 then
                                                                    buffer.writef32(v49, 0, v223)
                                                                    v229 = buffer.readu32(v49, 0)
                                                                elseif v223 > -1.1754943508222875E-38 and v223 < 1.1754943508222875E-38 then
                                                                    v229 = to_bits(v223)
                                                                else
                                                                    buffer.writef32(v49, 0, v223)
                                                                    v229 = buffer.readu32(v49, 0)
                                                                end

                                                                if v224 == 0 then
                                                                    buffer.writef32(v49, 0, v224)
                                                                    v230 = buffer.readu32(v49, 0)
                                                                elseif v224 > -1.1754943508222875E-38 and v224 < 1.1754943508222875E-38 then
                                                                    v230 = to_bits(v224)
                                                                else
                                                                    buffer.writef32(v49, 0, v224)
                                                                    v230 = buffer.readu32(v49, 0)
                                                                end

                                                                if v225 == 0 then
                                                                    buffer.writef32(v49, 0, v225)
                                                                    v231 = buffer.readu32(v49, 0)
                                                                elseif v225 > -1.1754943508222875E-38 and v225 < 1.1754943508222875E-38 then
                                                                    v231 = to_bits(v225)
                                                                else
                                                                    buffer.writef32(v49, 0, v225)
                                                                    v231 = buffer.readu32(v49, 0)
                                                                end

                                                                v227[5] = v229
                                                                v227[6] = v230
                                                                v227[7] = v231

                                                                if v215 == 0 then
                                                                    buffer.writef32(v49, 0, v215)
                                                                    v229 = buffer.readu32(v49, 0)
                                                                elseif v215 > -1.1754943508222875E-38 and v215 < 1.1754943508222875E-38 then
                                                                    v229 = to_bits(v215)
                                                                else
                                                                    buffer.writef32(v49, 0, v215)
                                                                    v229 = buffer.readu32(v49, 0)
                                                                end

                                                                if v216 == 0 then
                                                                    buffer.writef32(v49, 0, v216)
                                                                    v230 = buffer.readu32(v49, 0)
                                                                elseif v216 > -1.1754943508222875E-38 and v216 < 1.1754943508222875E-38 then
                                                                    v230 = to_bits(v216)
                                                                else
                                                                    buffer.writef32(v49, 0, v216)
                                                                    v230 = buffer.readu32(v49, 0)
                                                                end

                                                                if v217 == 0 then
                                                                    buffer.writef32(v49, 0, v217)
                                                                    v231 = buffer.readu32(v49, 0)
                                                                elseif v217 > -1.1754943508222875E-38 and v217 < 1.1754943508222875E-38 then
                                                                    v231 = to_bits(v217)
                                                                else
                                                                    buffer.writef32(v49, 0, v217)
                                                                    v231 = buffer.readu32(v49, 0)
                                                                end

                                                                v227[9] = v229
                                                                v227[10] = v230
                                                                v227[11] = v231
                                                                v227[4] = contact_id(v213.body)
                                                                v227[8] = 4294967295

                                                                if restitution == 0 then
                                                                    buffer.writef32(v49, 0, restitution)
                                                                    v227[12] = buffer.readu32(v49, 0)
                                                                elseif restitution > -1.1754943508222875E-38 and restitution < 1.1754943508222875E-38 then
                                                                    v227[12] = to_bits(restitution)
                                                                else
                                                                    buffer.writef32(v49, 0, restitution)
                                                                    v227[12] = buffer.readu32(v49, 0)
                                                                end

                                                                if static_friction == 0 then
                                                                    buffer.writef32(v49, 0, static_friction)
                                                                    v227[16] = buffer.readu32(v49, 0)
                                                                elseif static_friction > -1.1754943508222875E-38 and static_friction < 1.1754943508222875E-38 then
                                                                    v227[16] = to_bits(static_friction)
                                                                else
                                                                    buffer.writef32(v49, 0, static_friction)
                                                                    v227[16] = buffer.readu32(v49, 0)
                                                                end

                                                                if dynamic_friction == 0 then
                                                                    buffer.writef32(v49, 0, dynamic_friction)
                                                                    v227[20] = buffer.readu32(v49, 0)
                                                                elseif dynamic_friction > -1.1754943508222875E-38 and dynamic_friction < 1.1754943508222875E-38 then
                                                                    v227[20] = to_bits(dynamic_friction)
                                                                else
                                                                    buffer.writef32(v49, 0, dynamic_friction)
                                                                    v227[20] = buffer.readu32(v49, 0)
                                                                end

                                                                v227[24] = tag

                                                                if last_is_duplicate(_buffer) then
                                                                    _buffer.count -= 1
                                                                end
                                                            end
                                                        end
                                                    end
                                                end
                                            end
                                        end
                                    end
                                end
                            else
                                v213 = p60[n5]

                                local dynamic_friction = v212.triangle
                                local restitution = v213.linear_velocity
                                local tag = dynamic_friction.feature.normal
                                local v232 = -tag.x * (restitution.x * 0.01666666753590107) + -tag.y * (restitution.y * 0.01666666753590107) + -tag.z * (restitution.z * 0.01666666753590107)

                                if -v232 >= 0 then
                                    v232 = 0
                                end

                                if not (maximum_separating_distance - v232 >= 0) then
                                    v232 = maximum_separating_distance
                                end

                                local static_friction = v232 + volume_padding

                                tag = t22[n5]

                                if tag == v138 then
                                    restitution = t20[n5]
                                else
                                    restitution = t20[n5]

                                    if restitution == nil then
                                        restitution = table.create(48, 0)
                                        t20[n5] = restitution
                                    end

                                    tag, v232 = pack_primitive_into(restitution, v213.primitive)
                                    t21[n5] = v232
                                    t22[n5] = v138
                                end

                                tag = triangle_gp[j + 1]

                                if tag == nil then
                                    tag = pack_primitive({
                                        tag = "Triangle",
                                        dynamic_friction
                                    })
                                    triangle_gp[j + 1] = tag
                                end

                                local v233, v234, v235

                                v232, v233, v234, v235 = primitive_triangle_world_contacts_flat(restitution, t21[n5], tag, "Triangle", dynamic_friction, static_friction, p61)

                                if v232 ~= nil then
                                    local v236 = combine_contact_materials(v213.material, v212.material)

                                    restitution = v236.restitution
                                    static_friction = v236.static_friction
                                    dynamic_friction = v236.dynamic_friction
                                    tag = v212.tag

                                    for n8 = 0, v232 - 1 do
                                        local v237 = n8 * 6
                                        local v238 = flat_points[v237 + 1]
                                        local v239 = flat_points[v237 + 2]
                                        local v240 = flat_points[v237 + 3]
                                        local v241 = flat_points[v237 + 4]
                                        local v242 = flat_points[v237 + 5]
                                        local v243 = flat_points[v237 + 6]
                                        local v244 = allocate_publish(_buffer, contacts)
                                        local v245

                                        if v244 == nil then
                                            v244 = _buffer.count

                                            if v244 ~= 0 then
                                                if _buffer.deferred_reduction ~= 0 then
                                                    ContactBuffer.reduce(_buffer)
                                                end

                                                v244 = _buffer.records
                                                v245 = _buffer.count

                                                for n9 = 1, v245 do
                                                    local collision_from_record2 = collision_from_record

                                                    table.insert(contacts, collision_from_record2(v244[n9]))
                                                end

                                                _buffer.flushed = rt.wrapping_add_u32(_buffer.flushed, _buffer.count)
                                                _buffer.count = 0
                                            end

                                            return p59.contacts
                                        end

                                        local records = _buffer.records

                                        v245 = records[v244 + 1]

                                        if v245 ~= nil then
                                            if #v245 == 64 then
                                                table.move(v125, 1, 64, 1, v245)
                                            else
                                                v245 = table.create(64, 0)
                                                records[v244 + 1] = v245
                                            end
                                        else
                                            v245 = table.create(64, 0)
                                            records[v244 + 1] = v245
                                        end

                                        local v247

                                        if v238 == 0 then
                                            buffer.writef32(v49, 0, v238)
                                            v247 = buffer.readu32(v49, 0)
                                        elseif v238 > -1.1754943508222875E-38 and v238 < 1.1754943508222875E-38 then
                                            v247 = to_bits(v238)
                                        else
                                            buffer.writef32(v49, 0, v238)
                                            v247 = buffer.readu32(v49, 0)
                                        end

                                        local v248

                                        if v239 == 0 then
                                            buffer.writef32(v49, 0, v239)
                                            v248 = buffer.readu32(v49, 0)
                                        elseif v239 > -1.1754943508222875E-38 and v239 < 1.1754943508222875E-38 then
                                            v248 = to_bits(v239)
                                        else
                                            buffer.writef32(v49, 0, v239)
                                            v248 = buffer.readu32(v49, 0)
                                        end

                                        local v249

                                        if v240 == 0 then
                                            buffer.writef32(v49, 0, v240)
                                            v249 = buffer.readu32(v49, 0)
                                        elseif v240 > -1.1754943508222875E-38 and v240 < 1.1754943508222875E-38 then
                                            v249 = to_bits(v240)
                                        else
                                            buffer.writef32(v49, 0, v240)
                                            v249 = buffer.readu32(v49, 0)
                                        end

                                        v245[1] = v247
                                        v245[2] = v248
                                        v245[3] = v249

                                        if v241 == 0 then
                                            buffer.writef32(v49, 0, v241)
                                            v247 = buffer.readu32(v49, 0)
                                        elseif v241 > -1.1754943508222875E-38 and v241 < 1.1754943508222875E-38 then
                                            v247 = to_bits(v241)
                                        else
                                            buffer.writef32(v49, 0, v241)
                                            v247 = buffer.readu32(v49, 0)
                                        end

                                        if v242 == 0 then
                                            buffer.writef32(v49, 0, v242)
                                            v248 = buffer.readu32(v49, 0)
                                        elseif v242 > -1.1754943508222875E-38 and v242 < 1.1754943508222875E-38 then
                                            v248 = to_bits(v242)
                                        else
                                            buffer.writef32(v49, 0, v242)
                                            v248 = buffer.readu32(v49, 0)
                                        end

                                        if v243 == 0 then
                                            buffer.writef32(v49, 0, v243)
                                            v249 = buffer.readu32(v49, 0)
                                        elseif v243 > -1.1754943508222875E-38 and v243 < 1.1754943508222875E-38 then
                                            v249 = to_bits(v243)
                                        else
                                            buffer.writef32(v49, 0, v243)
                                            v249 = buffer.readu32(v49, 0)
                                        end

                                        v245[5] = v247
                                        v245[6] = v248
                                        v245[7] = v249

                                        if v233 == 0 then
                                            buffer.writef32(v49, 0, v233)
                                            v247 = buffer.readu32(v49, 0)
                                        elseif v233 > -1.1754943508222875E-38 and v233 < 1.1754943508222875E-38 then
                                            v247 = to_bits(v233)
                                        else
                                            buffer.writef32(v49, 0, v233)
                                            v247 = buffer.readu32(v49, 0)
                                        end

                                        if v234 == 0 then
                                            buffer.writef32(v49, 0, v234)
                                            v248 = buffer.readu32(v49, 0)
                                        elseif v234 > -1.1754943508222875E-38 and v234 < 1.1754943508222875E-38 then
                                            v248 = to_bits(v234)
                                        else
                                            buffer.writef32(v49, 0, v234)
                                            v248 = buffer.readu32(v49, 0)
                                        end

                                        if v235 == 0 then
                                            buffer.writef32(v49, 0, v235)
                                            v249 = buffer.readu32(v49, 0)
                                        elseif v235 > -1.1754943508222875E-38 and v235 < 1.1754943508222875E-38 then
                                            v249 = to_bits(v235)
                                        else
                                            buffer.writef32(v49, 0, v235)
                                            v249 = buffer.readu32(v49, 0)
                                        end

                                        v245[9] = v247
                                        v245[10] = v248
                                        v245[11] = v249
                                        v245[4] = contact_id(v213.body)
                                        v245[8] = 4294967295

                                        if restitution == 0 then
                                            buffer.writef32(v49, 0, restitution)
                                            v245[12] = buffer.readu32(v49, 0)
                                        elseif restitution > -1.1754943508222875E-38 and restitution < 1.1754943508222875E-38 then
                                            v245[12] = to_bits(restitution)
                                        else
                                            buffer.writef32(v49, 0, restitution)
                                            v245[12] = buffer.readu32(v49, 0)
                                        end

                                        if static_friction == 0 then
                                            buffer.writef32(v49, 0, static_friction)
                                            v245[16] = buffer.readu32(v49, 0)
                                        elseif static_friction > -1.1754943508222875E-38 and static_friction < 1.1754943508222875E-38 then
                                            v245[16] = to_bits(static_friction)
                                        else
                                            buffer.writef32(v49, 0, static_friction)
                                            v245[16] = buffer.readu32(v49, 0)
                                        end

                                        if dynamic_friction == 0 then
                                            buffer.writef32(v49, 0, dynamic_friction)
                                            v245[20] = buffer.readu32(v49, 0)
                                        elseif dynamic_friction > -1.1754943508222875E-38 and dynamic_friction < 1.1754943508222875E-38 then
                                            v245[20] = to_bits(dynamic_friction)
                                        else
                                            buffer.writef32(v49, 0, dynamic_friction)
                                            v245[20] = buffer.readu32(v49, 0)
                                        end

                                        v245[24] = tag

                                        if last_is_duplicate(_buffer) then
                                            _buffer.count -= 1
                                        end
                                    end
                                end
                            end
                        end
                    end
                else
                    local v250 = triangles[j + 1]

                    for n10 = 1, v127 do
                        local v251 = p60[n10]
                        local dynamic_friction = v250.triangle
                        local restitution = v251.linear_velocity
                        local tag = dynamic_friction.feature.normal
                        local v252 = -tag.x * (restitution.x * 0.01666666753590107) + -tag.y * (restitution.y * 0.01666666753590107) + -tag.z * (restitution.z * 0.01666666753590107)

                        if -v252 >= 0 then
                            v252 = 0
                        end

                        if not (maximum_separating_distance - v252 >= 0) then
                            v252 = maximum_separating_distance
                        end

                        local static_friction = v252 + volume_padding

                        tag = t22[n10]

                        if tag == v138 then
                            restitution = t20[n10]
                        else
                            restitution = t20[n10]

                            if restitution == nil then
                                restitution = table.create(48, 0)
                                t20[n10] = restitution
                            end

                            tag, v252 = pack_primitive_into(restitution, v251.primitive)
                            t21[n10] = v252
                            t22[n10] = v138
                        end

                        tag = triangle_gp[j + 1]

                        if tag == nil then
                            tag = pack_primitive({
                                tag = "Triangle",
                                dynamic_friction
                            })
                            triangle_gp[j + 1] = tag
                        end

                        local v253, v254, v255

                        v252, v253, v254, v255 = primitive_triangle_world_contacts_flat(restitution, t21[n10], tag, "Triangle", dynamic_friction, static_friction, p61)

                        if v252 ~= nil then
                            local v256 = combine_contact_materials(v251.material, v250.material)

                            restitution = v256.restitution
                            static_friction = v256.static_friction
                            dynamic_friction = v256.dynamic_friction
                            tag = v250.tag

                            for n11 = 0, v252 - 1 do
                                local v257 = n11 * 6
                                local v258 = flat_points[v257 + 1]
                                local v259 = flat_points[v257 + 2]
                                local v260 = flat_points[v257 + 3]
                                local v261 = flat_points[v257 + 4]
                                local v262 = flat_points[v257 + 5]
                                local v263 = flat_points[v257 + 6]
                                local v264 = allocate_publish(_buffer, contacts)
                                local v265

                                if v264 == nil then
                                    v264 = _buffer.count

                                    if v264 ~= 0 then
                                        if _buffer.deferred_reduction ~= 0 then
                                            ContactBuffer.reduce(_buffer)
                                        end

                                        v264 = _buffer.records
                                        v265 = _buffer.count

                                        for n12 = 1, v265 do
                                            local collision_from_record2 = collision_from_record

                                            table.insert(contacts, collision_from_record2(v264[n12]))
                                        end

                                        _buffer.flushed = rt.wrapping_add_u32(_buffer.flushed, _buffer.count)
                                        _buffer.count = 0
                                    end

                                    return p59.contacts
                                end

                                local records = _buffer.records

                                v265 = records[v264 + 1]

                                if v265 ~= nil then
                                    if #v265 == 64 then
                                        table.move(v125, 1, 64, 1, v265)
                                    else
                                        v265 = table.create(64, 0)
                                        records[v264 + 1] = v265
                                    end
                                else
                                    v265 = table.create(64, 0)
                                    records[v264 + 1] = v265
                                end

                                local v267

                                if v258 == 0 then
                                    buffer.writef32(v49, 0, v258)
                                    v267 = buffer.readu32(v49, 0)
                                elseif v258 > -1.1754943508222875E-38 and v258 < 1.1754943508222875E-38 then
                                    v267 = to_bits(v258)
                                else
                                    buffer.writef32(v49, 0, v258)
                                    v267 = buffer.readu32(v49, 0)
                                end

                                local v268

                                if v259 == 0 then
                                    buffer.writef32(v49, 0, v259)
                                    v268 = buffer.readu32(v49, 0)
                                elseif v259 > -1.1754943508222875E-38 and v259 < 1.1754943508222875E-38 then
                                    v268 = to_bits(v259)
                                else
                                    buffer.writef32(v49, 0, v259)
                                    v268 = buffer.readu32(v49, 0)
                                end

                                local v269

                                if v260 == 0 then
                                    buffer.writef32(v49, 0, v260)
                                    v269 = buffer.readu32(v49, 0)
                                elseif v260 > -1.1754943508222875E-38 and v260 < 1.1754943508222875E-38 then
                                    v269 = to_bits(v260)
                                else
                                    buffer.writef32(v49, 0, v260)
                                    v269 = buffer.readu32(v49, 0)
                                end

                                v265[1] = v267
                                v265[2] = v268
                                v265[3] = v269

                                if v261 == 0 then
                                    buffer.writef32(v49, 0, v261)
                                    v267 = buffer.readu32(v49, 0)
                                elseif v261 > -1.1754943508222875E-38 and v261 < 1.1754943508222875E-38 then
                                    v267 = to_bits(v261)
                                else
                                    buffer.writef32(v49, 0, v261)
                                    v267 = buffer.readu32(v49, 0)
                                end

                                if v262 == 0 then
                                    buffer.writef32(v49, 0, v262)
                                    v268 = buffer.readu32(v49, 0)
                                elseif v262 > -1.1754943508222875E-38 and v262 < 1.1754943508222875E-38 then
                                    v268 = to_bits(v262)
                                else
                                    buffer.writef32(v49, 0, v262)
                                    v268 = buffer.readu32(v49, 0)
                                end

                                if v263 == 0 then
                                    buffer.writef32(v49, 0, v263)
                                    v269 = buffer.readu32(v49, 0)
                                elseif v263 > -1.1754943508222875E-38 and v263 < 1.1754943508222875E-38 then
                                    v269 = to_bits(v263)
                                else
                                    buffer.writef32(v49, 0, v263)
                                    v269 = buffer.readu32(v49, 0)
                                end

                                v265[5] = v267
                                v265[6] = v268
                                v265[7] = v269

                                if v253 == 0 then
                                    buffer.writef32(v49, 0, v253)
                                    v267 = buffer.readu32(v49, 0)
                                elseif v253 > -1.1754943508222875E-38 and v253 < 1.1754943508222875E-38 then
                                    v267 = to_bits(v253)
                                else
                                    buffer.writef32(v49, 0, v253)
                                    v267 = buffer.readu32(v49, 0)
                                end

                                if v254 == 0 then
                                    buffer.writef32(v49, 0, v254)
                                    v268 = buffer.readu32(v49, 0)
                                elseif v254 > -1.1754943508222875E-38 and v254 < 1.1754943508222875E-38 then
                                    v268 = to_bits(v254)
                                else
                                    buffer.writef32(v49, 0, v254)
                                    v268 = buffer.readu32(v49, 0)
                                end

                                if v255 == 0 then
                                    buffer.writef32(v49, 0, v255)
                                    v269 = buffer.readu32(v49, 0)
                                elseif v255 > -1.1754943508222875E-38 and v255 < 1.1754943508222875E-38 then
                                    v269 = to_bits(v255)
                                else
                                    buffer.writef32(v49, 0, v255)
                                    v269 = buffer.readu32(v49, 0)
                                end

                                v265[9] = v267
                                v265[10] = v268
                                v265[11] = v269
                                v265[4] = contact_id(v251.body)
                                v265[8] = 4294967295

                                if restitution == 0 then
                                    buffer.writef32(v49, 0, restitution)
                                    v265[12] = buffer.readu32(v49, 0)
                                elseif restitution > -1.1754943508222875E-38 and restitution < 1.1754943508222875E-38 then
                                    v265[12] = to_bits(restitution)
                                else
                                    buffer.writef32(v49, 0, restitution)
                                    v265[12] = buffer.readu32(v49, 0)
                                end

                                if static_friction == 0 then
                                    buffer.writef32(v49, 0, static_friction)
                                    v265[16] = buffer.readu32(v49, 0)
                                elseif static_friction > -1.1754943508222875E-38 and static_friction < 1.1754943508222875E-38 then
                                    v265[16] = to_bits(static_friction)
                                else
                                    buffer.writef32(v49, 0, static_friction)
                                    v265[16] = buffer.readu32(v49, 0)
                                end

                                if dynamic_friction == 0 then
                                    buffer.writef32(v49, 0, dynamic_friction)
                                    v265[20] = buffer.readu32(v49, 0)
                                elseif dynamic_friction > -1.1754943508222875E-38 and dynamic_friction < 1.1754943508222875E-38 then
                                    v265[20] = to_bits(dynamic_friction)
                                else
                                    buffer.writef32(v49, 0, dynamic_friction)
                                    v265[20] = buffer.readu32(v49, 0)
                                end

                                v265[24] = tag

                                if last_is_duplicate(_buffer) then
                                    _buffer.count -= 1
                                end
                            end
                        end
                    end
                end
            end
        end

        if _buffer.count ~= 0 then
            if _buffer.deferred_reduction ~= 0 then
                ContactBuffer.reduce(_buffer)
            end

            v157 = _buffer.records

            for i = 1, _buffer.count do
                v148 = collision_from_record
                v149 = v157[i]
                table.insert(contacts, v148(v149))
            end

            _buffer.flushed = rt.wrapping_add_u32(_buffer.flushed, _buffer.count)
            _buffer.count = 0
        end
    end

    return p59.contacts
end

t1.BoardWorld.query_primitives_gr = query_primitives_gr

local v270 = false
local triangle_floats, sphere_triangle_contacts_flat = v12.triangle_floats, v12.sphere_triangle_contacts_flat

local function fr(p63) -- line: 1134
    -- upvalues: v49 (copy), to_bits (copy)
    if p63 < 1.1754943508222875E-38 and p63 > -1.1754943508222875E-38 and p63 ~= 0 then
        buffer.writeu32(v49, 0, to_bits(p63))
    else
        buffer.writef32(v49, 0, p63)
    end

    return (buffer.readf32(v49, 0))
end

local t23 = {}
local t24 = {}
local t25 = {}
local t26 = {}
local t27 = {}
local t28 = {}
local t29 = {}
local t30 = {}
local t31 = {}

function t1.set_query_gr(p64) -- line: 1149
    -- upvalues: v270 (ref)
    local v271 = v270

    v270 = p64

    return v271
end

local function volume_floats(p65, p66, p67) -- line: 1157
    -- upvalues: v49 (copy), to_bits (copy), t23 (copy), t24 (copy), t25 (copy), t26 (copy), t27 (copy), t31 (copy)
    buffer.writeu32(v49, 0, p66[1])

    local v273 = buffer.readf32(v49, 0)

    buffer.writeu32(v49, 0, p66[2])

    local v275 = buffer.readf32(v49, 0)

    buffer.writeu32(v49, 0, p66[3])

    local v277 = buffer.readf32(v49, 0)

    t25[p65] = v273
    t26[p65] = v275
    t27[p65] = v277
    buffer.writeu32(v49, 0, p66[33])
    t24[p65] = buffer.readf32(v49, 0)

    local v279 = t31[p65]

    if v279 == nil then
        v279 = table.create(11, 0)
        t31[p65] = v279
    end

    local v280 = p66[36]
    local n4 = 0

    if p67 == "Sphere" then
        n4 = if v280 == 0 then 1 else 0
    elseif p67 == "Capsule" then
        if v280 == 65536 then
            buffer.writeu32(v49, 0, p66[17])

            local v282 = buffer.readf32(v49, 0)

            buffer.writeu32(v49, 0, p66[18])

            local v284 = buffer.readf32(v49, 0)

            buffer.writeu32(v49, 0, p66[19])

            local v286 = buffer.readf32(v49, 0)

            v279[1] = v282
            v279[2] = v284
            v279[3] = v286
            buffer.writeu32(v49, 0, p66[29])
            n4 = 2
            v279[4] = buffer.readf32(v49, 0)
        end
    elseif p67 == "Triangle" then
        if v280 == 16973824 then
            buffer.writeu32(v49, 0, p66[5])

            local v289 = buffer.readf32(v49, 0)

            buffer.writeu32(v49, 0, p66[6])

            local v291 = buffer.readf32(v49, 0)

            buffer.writeu32(v49, 0, p66[7])

            local v293 = buffer.readf32(v49, 0)

            buffer.writeu32(v49, 0, p66[9])

            local v295 = buffer.readf32(v49, 0)

            buffer.writeu32(v49, 0, p66[10])

            local v297 = buffer.readf32(v49, 0)

            buffer.writeu32(v49, 0, p66[11])

            local v299 = buffer.readf32(v49, 0)

            buffer.writeu32(v49, 0, p66[13])

            local v301 = buffer.readf32(v49, 0)

            buffer.writeu32(v49, 0, p66[14])

            local v303 = buffer.readf32(v49, 0)

            buffer.writeu32(v49, 0, p66[15])

            local v305 = buffer.readf32(v49, 0)
            local v306 = v273 * v289 + v275 * v291 + v277 * v293
            local v307 = v295 * v289 + v297 * v291 + v299 * v293
            local v308 = v301 * v289 + v303 * v291 + v305 * v293
            local v309 = if v306 < v307 then v306 else v307

            if not (v307 < v306) then
                v306 = v307
            end

            v279[1] = v289
            v279[2] = v291
            v279[3] = v293

            if not (v309 < v308) then
                v309 = v308
            end

            if v309 < 1.1754943508222875E-38 and v309 > -1.1754943508222875E-38 and v309 ~= 0 then
                buffer.writeu32(v49, 0, to_bits(v309))
            else
                buffer.writef32(v49, 0, v309)
            end

            v279[4] = buffer.readf32(v49, 0)

            if not (v308 < v306) then
                v306 = v308
            end

            if v306 < 1.1754943508222875E-38 and v306 > -1.1754943508222875E-38 and v306 ~= 0 then
                buffer.writeu32(v49, 0, to_bits(v306))
            else
                buffer.writef32(v49, 0, v306)
            end

            v279[5] = buffer.readf32(v49, 0)
            v279[6] = v295
            v279[7] = v297
            v279[8] = v299
            v279[9] = v301
            v279[10] = v303
            n4 = 3
            v279[11] = v305
        end
    elseif p67 == "Box" then
        buffer.writeu32(v49, 0, p66[29])

        local v311 = buffer.readf32(v49, 0)

        buffer.writeu32(v49, 0, p66[5])

        local v313 = buffer.readf32(v49, 0) * v311

        buffer.writeu32(v49, 0, p66[6])

        local v315 = buffer.readf32(v49, 0) * v311

        buffer.writeu32(v49, 0, p66[7])

        local v317 = buffer.readf32(v49, 0) * v311

        v279[1] = v313
        v279[2] = v315
        v279[3] = v317
        buffer.writeu32(v49, 0, p66[30])

        local v319 = buffer.readf32(v49, 0)

        buffer.writeu32(v49, 0, p66[9])

        local v321 = buffer.readf32(v49, 0) * v319

        buffer.writeu32(v49, 0, p66[10])

        local v323 = buffer.readf32(v49, 0) * v319

        buffer.writeu32(v49, 0, p66[11])

        local v325 = buffer.readf32(v49, 0) * v319

        v279[4] = v321
        v279[5] = v323
        v279[6] = v325
        buffer.writeu32(v49, 0, p66[31])

        local v327 = buffer.readf32(v49, 0)

        buffer.writeu32(v49, 0, p66[13])

        local v329 = buffer.readf32(v49, 0) * v327

        buffer.writeu32(v49, 0, p66[14])

        local v331 = buffer.readf32(v49, 0) * v327

        buffer.writeu32(v49, 0, p66[15])

        local v333 = buffer.readf32(v49, 0) * v327

        v279[7] = v329
        v279[8] = v331
        n4 = 4
        v279[9] = v333
    end

    t23[p65] = n4
end

local function query_primitives_r4(p68, p69, p70, p71) -- line: 1210
    -- upvalues: rt (copy), Vector3 (copy), combine_contact_materials (copy), ContactBuffer (copy), pack_primitive (copy), t1 (copy), collision_from_record (ref), v49 (copy), to_bits (copy), primitive_triangle_world_contacts_flat (copy), flat_points (copy), primitive_conservative_bounds_scalar (copy), flat_triangle_bounds (copy), contact_id (copy), last_is_duplicate (copy), is_finite (copy), fmin (copy), fmax (copy), allocate_publish (copy), t13 (copy), t14 (copy), t15 (copy), t16 (copy), t17 (copy), t18 (copy), t19 (copy), t20 (copy), t21 (copy), t22 (copy), n3 (ref), v125 (copy), pack_primitive_into (copy), triangle_floats (copy), sphere_triangle_contacts_flat (copy), t23 (copy), t24 (copy), t25 (copy), t26 (copy), t27 (copy), t28 (copy), t29 (copy), t30 (copy), t31 (copy), volume_floats (copy)
    table.clear(p68.contacts)

    local _buffer = p68.buffer

    _buffer.count = 0
    _buffer.flushed = 0
    _buffer.dropped = 0
    _buffer.full = 0
    _buffer.capacity = p71.capacity
    _buffer.distance_squared_threshold = p71.duplicate_distance_squared
    _buffer.deferred_reduction = p71.deferred_reduction and 1 or 0

    local v334 = p70.volume_padding
    local v335, v336

    if v334 == v334 and v334 ~= 1e999 and v334 ~= (-1e999) then
        v334 = p70.maximum_separating_distance
        v335 = v334 == v334 and v334 ~= 1e999 and v334 ~= (-1e999)
        v336 = not not v335
    else
        v336 = false
    end

    local v337 = if v336 then rt.fmax(p70.volume_padding, 0) + rt.fmax(p70.maximum_separating_distance, 0) else 1e999

    v335 = #p69

    if v335 == 0 then
        if p68.triangle_gp == nil then
            p68.triangle_gp = {}
        end

        v334 = p68.contacts

        if _buffer.count ~= 0 then
            if _buffer.deferred_reduction ~= 0 then
                ContactBuffer.reduce(_buffer)
            end

            local records = _buffer.records

            for i = 1, _buffer.count do
                local triangle_fp = collision_from_record

                table.insert(v334, triangle_fp(records[i]))
            end

            _buffer.flushed = rt.wrapping_add_u32(_buffer.flushed, _buffer.count)
            _buffer.count = 0
        end
    else
        local triangle_fp = true
        local maximum_separating_distance, v338, v339, v340

        for i = 1, v335 do
            local v341, v342

            v341, v342, v338, v339, v340, maximum_separating_distance = primitive_conservative_bounds_scalar(p69[i].primitive, v337 + p68.maximum_fatness)

            if v341 ~= nil then
                t13[i] = true
                t14[i] = v341
                t15[i] = v342
                t16[i] = v338
                t17[i] = v339
                t18[i] = v340
                t19[i] = maximum_separating_distance
            else
                triangle_fp = false
                t13[i] = false
            end
        end

        local v343, contacts, v344, triangle_gp, triangles, v345, v346

        if triangle_fp and v335 > 0 then
            local v347 = t14[1]
            local v348 = t15[1]
            local v349 = t16[1]

            v344 = is_finite(v347) and is_finite(v348) and is_finite(v349)
            v338 = v347
            v339 = v348
            v340 = v349

            if v344 then
                for i = 1, v335 do
                    local v350 = false
                    local v351 = false
                    local v352 = false
                    local v353, v354

                    if i > 1 then
                        local v355 = t14[i]
                        local v356 = t15[i]
                        local v357 = t16[i]

                        if is_finite(v355) and is_finite(v356) and is_finite(v357) then
                            v346 = fmin(v347, v355)
                            v353 = fmin(v348, v356)
                            v354 = fmin(v349, v357)
                            triangle_gp = fmax(v338, v355)
                            v345 = fmax(v339, v356)
                            triangles = fmax(v340, v357)
                            v350 = true
                        else
                            v351 = true
                        end
                    else
                        v346 = v347
                        v353 = v348
                        v354 = v349
                        triangle_gp = v338
                        v345 = v339
                        triangles = v340
                        v350 = true
                    end

                    local v358, v359

                    if v350 then
                        v343 = t17[i]
                        v358 = t18[i]
                        v359 = t19[i]

                        if not is_finite(v343) or not is_finite(v358) or not is_finite(v359) then
                            v352 = true
                        end
                    end

                    if v352 then
                        v347 = v346
                        v348 = v353
                        v349 = v354
                        v344 = false
                        v338 = triangle_gp
                        v339 = v345
                        v340 = triangles
                        break
                    end

                    if v351 then
                        v344 = false
                        break
                    end

                    v347 = fmin(v346, v343)
                    v348 = fmin(v353, v358)
                    v349 = fmin(v354, v359)
                    v338 = fmax(triangle_gp, v343)
                    v339 = fmax(v345, v358)
                    v340 = fmax(triangles, v359)
                end
            end

            if v344 then
                contacts = {
                    min = Vector3.new(v347 - v337, v348 - v337, v349 - v337),
                    max = Vector3.new(v338 + v337, v339 + v337, v340 + v337)
                }
            else
                contacts = nil
            end
        end

        v346 = t1.BoardWorld.candidate_ranges(p68, contacts)
        contacts = p68.contacts
        n3 += 1
        v344 = n3
        triangle_gp = p68.triangle_gp

        if triangle_gp == nil then
            triangle_gp = {}
            p68.triangle_gp = triangle_gp
        end

        v345 = p68.query_metadata ~= nil
        triangles = p68.triangles
        maximum_separating_distance = p70.maximum_separating_distance

        local volume_padding = p70.volume_padding
        local v360

        if v345 then
            v360 = flat_triangle_bounds(p68)
            v343 = triangle_fp and v335 > 0
        else
            v343 = v345
        end

        local v361, v362, v363, v364, v365, v366, v367, v368

        if v343 then
            local v369 = t14[1]
            local v370 = t15[1]
            local v371 = t16[1]
            local v372 = t17[1]
            local v373 = t18[1]
            local v374 = t19[1]
            local v375 = v369 == v369 and v370 == v370 and v371 == v371 and v372 == v372 and v373 == v373 and v374 == v374 and v343

            v362 = v369
            v363 = v370
            v364 = v371
            v365 = v372
            v366 = v373
            v367 = v374
            v368 = v375

            for i = 2, v335 do
                local v376 = t14[i]
                local v377 = t15[i]
                local v378 = t16[i]
                local v379 = t17[i]
                local v380 = t18[i]

                v361 = t19[i]

                local v381 = false
                local v382, v383, v384, v385, v386, v387

                if v376 == v376 and v377 == v377 and v378 == v378 and v379 == v379 and v380 == v380 and v361 == v361 then
                    v382 = if v376 < v362 then v376 else v362
                    v383 = if v377 < v363 then v377 else v363
                    v384 = if v378 < v364 then v378 else v364
                    v385 = if v365 < v379 then v379 else v365
                    v386 = if v366 < v380 then v380 else v366
                    v387 = if v367 < v361 then v361 else v367
                else
                    v381 = true
                end

                if v381 then
                    v368 = false
                    break
                end

                v368 = v375
                v362 = v382
                v363 = v383
                v364 = v384
                v365 = v385
                v366 = v386
                v367 = v387
            end
        else
            v368 = v343
        end

        triangle_fp = p68.triangle_fp

        if triangle_fp == nil then
            triangle_fp = {}
            p68.triangle_fp = triangle_fp
            p68.triangle_fp_count = 0
        end

        local v388

        for _, v389 in v346 do
            local start = v389.start

            v388 = v389["end"] - 1

            for j = start, v388 do
                local v390 = false
                local v391, v392, v393, v394, v395, v396, v397

                if v345 then
                    v397 = j * 6

                    local v398 = v360[v397 + 1]
                    local v399 = v360[v397 + 2]
                    local v400 = v360[v397 + 3]
                    local v401 = v360[v397 + 4]
                    local v402 = v360[v397 + 5]
                    local v403 = v360[v397 + 6]

                    if not v368 or not (v401 < v362) and not (v365 < v398) and not (v402 < v363) and not (v366 < v399) and not (v403 < v364) and not (v367 < v400) then
                        v392 = v398
                        v394 = v399
                        v396 = v400
                        v391 = v401
                        v393 = v402
                        v395 = v403
                        v390 = true
                    end
                else
                    v390 = true
                end

                if v390 then
                    v397 = nil

                    local v404 = nil
                    local v405 = nil
                    local v406 = nil

                    for k = 1, v335 do
                        local v407 = false
                        local v408 = false
                        local v409 = false
                        local v410 = false
                        local v411 = false
                        local v412 = false
                        local v413, v414, v415, v416

                        if v345 and t13[k] and (v391 < t14[k]
                            or t17[k] < v392
                            or v393 < t15[k]
                            or t18[k] < v394
                            or v395 < t16[k]
                            or t19[k] < v396) then
                            v416 = v406
                            v413 = v397
                            v415 = v404
                            v414 = v405
                        else
                            v407 = true
                        end

                        local v417, v418, v419, v420, v421, v422, v423, v424, v425, v426, v427, v428, v429, v430, v431, v432, v433, writef32, v434, dynamic_friction, tag, v435, v436, v437, v438, v439, v440

                        if v407 then
                            v417 = p69[k]

                            if v397 ~= nil then
                                v440 = v404
                                v439 = v397
                            else
                                v439 = triangles[j + 1]
                                v440 = v439.triangle
                            end

                            if t22[k] == v344 then
                                v418 = t20[k]
                            else
                                v421 = v417.linear_velocity
                                t28[k] = v421.x * 0.01666666753590107
                                t29[k] = v421.y * 0.01666666753590107
                                t30[k] = v421.z * 0.01666666753590107
                                v418 = t20[k]

                                if v418 == nil then
                                    v418 = table.create(48, 0)
                                    t20[k] = v418
                                end

                                local v441

                                tag, v441 = pack_primitive_into(v418, v417.primitive)
                                t21[k] = v441
                                volume_floats(k, v418, v441)
                                t22[k] = v344
                            end

                            if v405 ~= nil then
                                v420 = v406
                                v419 = v405
                            else
                                v419 = triangle_gp[j + 1]

                                if v419 == nil then
                                    v419 = pack_primitive({
                                        tag = "Triangle",
                                        v440
                                    })
                                    triangle_gp[j + 1] = v419
                                end

                                v420 = triangle_fp[j + 1]

                                if v420 == nil then
                                    v420 = triangle_floats(v419, v440)
                                    v421 = p68.triangle_fp_count

                                    if v421 >= 16384 then
                                        v421 = 0
                                        table.clear(triangle_fp)
                                    end

                                    triangle_fp[j + 1] = v420
                                    p68.triangle_fp_count = v421 + 1
                                end
                            end

                            tag = v420[1] * t28[k] + v420[2] * t29[k] + v420[3] * t30[k]

                            if -tag >= 0 then
                                tag = 0
                            end

                            if not (maximum_separating_distance - tag >= 0) then
                                tag = maximum_separating_distance
                            end

                            v421 = tag + volume_padding
                            tag = t23[k]

                            if tag == 0 then
                                v408 = true
                            elseif v420[19] == 1 then
                                dynamic_friction = v420[4]
                                v422 = v420[5]

                                local v442 = v420[6]
                                local v443 = t25[k]

                                v423 = t26[k]
                                v424 = t27[k]
                                v425 = v420[16] + v421 + t24[k]

                                if tag == 1 then
                                    v435 = v443 * dynamic_friction + v423 * v422 + v424 * v442

                                    if not (v435 < 1.1754943508222875E-38) or not (v435 > -1.1754943508222875E-38) or v435 == 0 then
                                        buffer.writef32(v49, 0, v435)
                                    else
                                        buffer.writeu32(v49, 0, to_bits(v435))
                                    end

                                    v436 = buffer.readf32(v49, 0)
                                    v435 = v436 - v420[18]
                                    v436 = v420[17] - v436
                                    v430 = v436 < v435

                                    if not v430 then
                                        v435 = v436
                                    end

                                    if not (v435 < 1.1754943508222875E-38) or not (v435 > -1.1754943508222875E-38) or v435 == 0 then
                                        buffer.writef32(v49, 0, v435)
                                    else
                                        buffer.writeu32(v49, 0, to_bits(v435))
                                    end

                                    v438 = buffer.readf32(v49, 0)

                                    if v425 < v438 then
                                        v416 = v420
                                        v413 = v439
                                        v415 = v440
                                        v414 = v419
                                    else
                                        v426, v427, v428, v429 = sphere_triangle_contacts_flat(v420, v419, v430, v438, v443, v423, v424, t24[k], v440, p70)

                                        if v426 == -1 then
                                            v426, v427, v428, v429 = primitive_triangle_world_contacts_flat(v418, "Sphere", v419, "Triangle", v440, v421, p70)
                                        end

                                        v409 = true
                                    end
                                else
                                    v430 = t31[k]

                                    if tag == 2 then
                                        v435 = v443 * dynamic_friction + v423 * v422 + v424 * v442
                                        v431 = v430[1] * dynamic_friction + v430[2] * v422 + v430[3] * v442
                                        v436 = math.abs(v431) * v430[4]
                                        v431 = v435 - v436

                                        if not (v431 < 1.1754943508222875E-38) or not (v431 > -1.1754943508222875E-38) or v431 == 0 then
                                            buffer.writef32(v49, 0, v431)
                                        else
                                            buffer.writeu32(v49, 0, to_bits(v431))
                                        end

                                        v430 = buffer.readf32(v49, 0) - v420[18]
                                        v431 = v420[17]
                                        v432 = v435 + v436

                                        if not (v432 < 1.1754943508222875E-38) or not (v432 > -1.1754943508222875E-38) or v432 == 0 then
                                            buffer.writef32(v49, 0, v432)
                                        else
                                            buffer.writeu32(v49, 0, to_bits(v432))
                                        end

                                        v437 = v431 - buffer.readf32(v49, 0)

                                        if not (v437 < v430) then
                                            v430 = v437
                                        end

                                        if v430 == v430 then
                                            if not (v430 < 1.1754943508222875E-38) or not (v430 > -1.1754943508222875E-38) or v430 == 0 then
                                                buffer.writef32(v49, 0, v430)
                                            else
                                                buffer.writeu32(v49, 0, to_bits(v430))
                                            end

                                            if v425 < buffer.readf32(v49, 0) then
                                                v416 = v420
                                                v413 = v439
                                                v415 = v440
                                                v414 = v419
                                            else
                                                v412 = true
                                            end
                                        else
                                            v412 = true
                                        end
                                    elseif tag == 3 then
                                        v435 = v430[1]
                                        v436 = v430[2]
                                        v437 = v430[3]
                                        v431 = v420[7] * v435 + v420[8] * v436 + v420[9] * v437
                                        v438 = v420[10] * v435 + v420[11] * v436 + v420[12] * v437
                                        v432 = v420[13] * v435 + v420[14] * v436 + v420[15] * v437
                                        v434 = if v431 < v438 then v431 else v438

                                        if not (v438 < v431) then
                                            v431 = v438
                                        end

                                        v433 = v430[4]

                                        if not (v432 < v431) then
                                            v431 = v432
                                        end

                                        if not (v431 < 1.1754943508222875E-38) or not (v431 > -1.1754943508222875E-38) or v431 == 0 then
                                            buffer.writef32(v49, 0, v431)
                                        else
                                            buffer.writeu32(v49, 0, to_bits(v431))
                                        end

                                        v435 = v433 - buffer.readf32(v49, 0)

                                        if not (v434 < v432) then
                                            v434 = v432
                                        end

                                        if not (v434 < 1.1754943508222875E-38) or not (v434 > -1.1754943508222875E-38) or v434 == 0 then
                                            buffer.writef32(v49, 0, v434)
                                        else
                                            buffer.writeu32(v49, 0, to_bits(v434))
                                        end

                                        v433 = buffer.readf32(v49, 0) - v430[5]

                                        if not (v433 < v435) then
                                            v435 = v433
                                        end

                                        if v435 == v435 then
                                            if not (v435 < 1.1754943508222875E-38) or not (v435 > -1.1754943508222875E-38) or v435 == 0 then
                                                buffer.writef32(v49, 0, v435)
                                            else
                                                buffer.writeu32(v49, 0, to_bits(v435))
                                            end

                                            if v425 < buffer.readf32(v49, 0) then
                                                v416 = v420
                                                v413 = v439
                                                v415 = v440
                                                v414 = v419
                                            else
                                                v431 = v443 * dynamic_friction + v423 * v422 + v424 * v442
                                                v438 = v430[6] * dynamic_friction + v430[7] * v422 + v430[8] * v442
                                                v432 = v430[9] * dynamic_friction + v430[10] * v422 + v430[11] * v442
                                                writef32 = if v431 < v438 then v431 else v438

                                                if not (v438 < v431) then
                                                    v431 = v438
                                                end

                                                if not (writef32 < v432) then
                                                    writef32 = v432
                                                end

                                                if not (writef32 < 1.1754943508222875E-38) or not (writef32 > -1.1754943508222875E-38) or writef32 == 0 then
                                                    buffer.writef32(v49, 0, writef32)
                                                else
                                                    buffer.writeu32(v49, 0, to_bits(writef32))
                                                end

                                                v435 = buffer.readf32(v49, 0) - v420[18]
                                                v434 = v420[17]

                                                if not (v432 < v431) then
                                                    v431 = v432
                                                end

                                                if not (v431 < 1.1754943508222875E-38) or not (v431 > -1.1754943508222875E-38) or v431 == 0 then
                                                    buffer.writef32(v49, 0, v431)
                                                else
                                                    buffer.writeu32(v49, 0, to_bits(v431))
                                                end

                                                v433 = v434 - buffer.readf32(v49, 0)

                                                if not (v433 < v435) then
                                                    v435 = v433
                                                end

                                                if not (v435 < 1.1754943508222875E-38) or not (v435 > -1.1754943508222875E-38) or v435 == 0 then
                                                    buffer.writef32(v49, 0, v435)
                                                else
                                                    buffer.writeu32(v49, 0, to_bits(v435))
                                                end

                                                if v425 < buffer.readf32(v49, 0) then
                                                    v416 = v420
                                                    v413 = v439
                                                    v415 = v440
                                                    v414 = v419
                                                else
                                                    v411 = true
                                                end
                                            end
                                        else
                                            v411 = true
                                        end
                                    else
                                        v435 = v443 * dynamic_friction + v423 * v422 + v424 * v442
                                        v438 = v430[1] * dynamic_friction + v430[2] * v422 + v430[3] * v442
                                        v431 = math.abs(v438)
                                        v432 = v430[4] * dynamic_friction + v430[5] * v422 + v430[6] * v442
                                        v437 = v431 + math.abs(v432)
                                        v438 = v430[7] * dynamic_friction + v430[8] * v422 + v430[9] * v442
                                        v436 = v437 + math.abs(v438)
                                        v430 = v420[20] - (v435 + v436)
                                        v437 = v435 - v436 - v420[21]

                                        if not (v437 < v430) then
                                            v430 = v437
                                        end

                                        if v430 == v430 then
                                            if not (v430 < 1.1754943508222875E-38) or not (v430 > -1.1754943508222875E-38) or v430 == 0 then
                                                buffer.writef32(v49, 0, v430)
                                            else
                                                buffer.writeu32(v49, 0, to_bits(v430))
                                            end

                                            if v425 < buffer.readf32(v49, 0) then
                                                v416 = v420
                                                v413 = v439
                                                v415 = v440
                                                v414 = v419
                                            else
                                                v410 = true
                                            end
                                        else
                                            v410 = true
                                        end
                                    end
                                end
                            else
                                v408 = true
                            end
                        end

                        if v408 then
                            v426, v427, v428, v429 = primitive_triangle_world_contacts_flat(v418, t21[k], v419, "Triangle", v440, v421, p70)
                            v409 = true
                        end

                        if v410 then
                            v426, v427, v428, v429 = primitive_triangle_world_contacts_flat(v418, "Box", v419, "Triangle", v440, v421, p70)
                            v409 = true
                        end

                        if v411 then
                            v426, v427, v428, v429 = primitive_triangle_world_contacts_flat(v418, "Triangle", v419, "Triangle", v440, v421, p70, true)
                            v409 = true
                        end

                        if v412 then
                            v426, v427, v428, v429 = primitive_triangle_world_contacts_flat(v418, "Capsule", v419, "Triangle", v440, v421, p70, true)
                            v409 = true
                        end

                        if v409 then
                            if v426 ~= nil then
                                dynamic_friction = combine_contact_materials(v417.material, v439.material)

                                local restitution, static_friction = dynamic_friction.restitution, dynamic_friction.static_friction

                                dynamic_friction = dynamic_friction.dynamic_friction
                                tag = v439.tag
                                v422 = v426 - 1
                                v413 = v439
                                v415 = v440
                                v414 = v419
                                v416 = v420

                                for n = 0, v422 do
                                    v423 = n * 6
                                    v424 = flat_points[v423 + 1]
                                    v425 = flat_points[v423 + 2]
                                    v430 = flat_points[v423 + 3]
                                    v435 = flat_points[v423 + 4]
                                    v436 = flat_points[v423 + 5]
                                    v437 = flat_points[v423 + 6]
                                    v431 = allocate_publish(_buffer, contacts)

                                    local v444 = false

                                    if v431 ~= nil then
                                        local records = _buffer.records

                                        v438 = records[v431 + 1]

                                        if v438 ~= nil then
                                            if #v438 == 64 then
                                                table.move(v125, 1, 64, 1, v438)
                                            else
                                                v438 = table.create(64, 0)
                                                records[v431 + 1] = v438
                                            end
                                        else
                                            v438 = table.create(64, 0)
                                            records[v431 + 1] = v438
                                        end

                                        if v424 == 0 then
                                            buffer.writef32(v49, 0, v424)
                                            v432 = buffer.readu32(v49, 0)
                                        elseif v424 > -1.1754943508222875E-38 and v424 < 1.1754943508222875E-38 then
                                            v432 = to_bits(v424)
                                        else
                                            buffer.writef32(v49, 0, v424)
                                            v432 = buffer.readu32(v49, 0)
                                        end

                                        if v425 == 0 then
                                            buffer.writef32(v49, 0, v425)
                                            v433 = buffer.readu32(v49, 0)
                                        elseif v425 > -1.1754943508222875E-38 and v425 < 1.1754943508222875E-38 then
                                            v433 = to_bits(v425)
                                        else
                                            buffer.writef32(v49, 0, v425)
                                            v433 = buffer.readu32(v49, 0)
                                        end

                                        local v446

                                        if v430 == 0 then
                                            buffer.writef32(v49, 0, v430)
                                            v446 = buffer.readu32(v49, 0)
                                        elseif v430 > -1.1754943508222875E-38 and v430 < 1.1754943508222875E-38 then
                                            v446 = to_bits(v430)
                                        else
                                            buffer.writef32(v49, 0, v430)
                                            v446 = buffer.readu32(v49, 0)
                                        end

                                        v438[1] = v432
                                        v438[2] = v433
                                        v438[3] = v446

                                        if v435 == 0 then
                                            buffer.writef32(v49, 0, v435)
                                            v432 = buffer.readu32(v49, 0)
                                        elseif v435 > -1.1754943508222875E-38 and v435 < 1.1754943508222875E-38 then
                                            v432 = to_bits(v435)
                                        else
                                            buffer.writef32(v49, 0, v435)
                                            v432 = buffer.readu32(v49, 0)
                                        end

                                        if v436 == 0 then
                                            buffer.writef32(v49, 0, v436)
                                            v433 = buffer.readu32(v49, 0)
                                        elseif v436 > -1.1754943508222875E-38 and v436 < 1.1754943508222875E-38 then
                                            v433 = to_bits(v436)
                                        else
                                            buffer.writef32(v49, 0, v436)
                                            v433 = buffer.readu32(v49, 0)
                                        end

                                        if v437 == 0 then
                                            buffer.writef32(v49, 0, v437)
                                            v446 = buffer.readu32(v49, 0)
                                        elseif v437 > -1.1754943508222875E-38 and v437 < 1.1754943508222875E-38 then
                                            v446 = to_bits(v437)
                                        else
                                            buffer.writef32(v49, 0, v437)
                                            v446 = buffer.readu32(v49, 0)
                                        end

                                        v438[5] = v432
                                        v438[6] = v433
                                        v438[7] = v446

                                        if v427 == 0 then
                                            buffer.writef32(v49, 0, v427)
                                            v446 = buffer.readu32(v49, 0)
                                        elseif v427 > -1.1754943508222875E-38 and v427 < 1.1754943508222875E-38 then
                                            v446 = to_bits(v427)
                                        else
                                            buffer.writef32(v49, 0, v427)
                                            v446 = buffer.readu32(v49, 0)
                                        end

                                        if v428 == 0 then
                                            buffer.writef32(v49, 0, v428)
                                            v434 = buffer.readu32(v49, 0)
                                        elseif v428 > -1.1754943508222875E-38 and v428 < 1.1754943508222875E-38 then
                                            v434 = to_bits(v428)
                                        else
                                            buffer.writef32(v49, 0, v428)
                                            v434 = buffer.readu32(v49, 0)
                                        end

                                        if v429 == 0 then
                                            buffer.writef32(v49, 0, v429)
                                            writef32 = buffer.readu32(v49, 0)
                                        elseif v429 > -1.1754943508222875E-38 and v429 < 1.1754943508222875E-38 then
                                            writef32 = to_bits(v429)
                                        else
                                            buffer.writef32(v49, 0, v429)
                                            writef32 = buffer.readu32(v49, 0)
                                        end

                                        v438[9] = v446
                                        v438[10] = v434
                                        v438[11] = writef32
                                        v438[4] = contact_id(v417.body)
                                        v438[8] = 4294967295

                                        if restitution == 0 then
                                            buffer.writef32(v49, 0, restitution)
                                            v438[12] = buffer.readu32(v49, 0)
                                        elseif restitution > -1.1754943508222875E-38 and restitution < 1.1754943508222875E-38 then
                                            v438[12] = to_bits(restitution)
                                        else
                                            buffer.writef32(v49, 0, restitution)
                                            v438[12] = buffer.readu32(v49, 0)
                                        end

                                        if static_friction == 0 then
                                            buffer.writef32(v49, 0, static_friction)
                                            v438[16] = buffer.readu32(v49, 0)
                                        elseif static_friction > -1.1754943508222875E-38 and static_friction < 1.1754943508222875E-38 then
                                            v438[16] = to_bits(static_friction)
                                        else
                                            buffer.writef32(v49, 0, static_friction)
                                            v438[16] = buffer.readu32(v49, 0)
                                        end

                                        if dynamic_friction == 0 then
                                            buffer.writef32(v49, 0, dynamic_friction)
                                            v438[20] = buffer.readu32(v49, 0)
                                        elseif dynamic_friction > -1.1754943508222875E-38 and dynamic_friction < 1.1754943508222875E-38 then
                                            v438[20] = to_bits(dynamic_friction)
                                        else
                                            buffer.writef32(v49, 0, dynamic_friction)
                                            v438[20] = buffer.readu32(v49, 0)
                                        end

                                        v438[24] = tag

                                        if last_is_duplicate(_buffer) then
                                            _buffer.count -= 1
                                        end
                                    else
                                        if _buffer.count ~= 0 then
                                            if _buffer.deferred_reduction ~= 0 then
                                                ContactBuffer.reduce(_buffer)
                                            end

                                            v431 = _buffer.records
                                            v438 = _buffer.count

                                            for n2 = 1, v438 do
                                                writef32 = collision_from_record
                                                table.insert(contacts, writef32(v431[n2]))
                                            end

                                            _buffer.flushed = rt.wrapping_add_u32(_buffer.flushed, _buffer.count)
                                            _buffer.count = 0
                                        end

                                        v444 = true
                                    end

                                    if v444 then
                                        return p68.contacts
                                    end

                                    v416 = v420
                                    v413 = v439
                                    v415 = v440
                                    v414 = v419
                                end
                            else
                                v416 = v420
                                v413 = v439
                                v415 = v440
                                v414 = v419
                            end
                        end

                        v406 = v416
                        v397 = v413
                        v404 = v415
                        v405 = v414
                    end
                end
            end
        end

        if _buffer.count ~= 0 then
            if _buffer.deferred_reduction ~= 0 then
                ContactBuffer.reduce(_buffer)
            end

            v361 = _buffer.records

            for i = 1, _buffer.count do
                v388 = collision_from_record
                table.insert(contacts, v388(v361[i]))
            end

            _buffer.flushed = rt.wrapping_add_u32(_buffer.flushed, _buffer.count)
            _buffer.count = 0
        end
    end

    return p68.contacts
end

t1.BoardWorld.query_primitives_r4 = query_primitives_r4

local v448 = false
local capsule_triangle_contacts_flat, triangle_triangle_contacts_flat, box_triangle_rejects, triangle_gp_record = v12.capsule_triangle_contacts_flat, v12.triangle_triangle_contacts_flat, v12.box_triangle_rejects, v12.triangle_gp_record
local sphere_triangle_contacts_dense = v12.sphere_triangle_contacts_dense
local t32 = {}
local candidate_ranges_into = v8.candidate_ranges_into
local v449 = table.create(16, 0)
local v450 = table.create(16, 0)
local t33 = {}
local v451 = table.create(48, 0)
local t34 = {
    tag = "Triangle"
}

function t1.set_query_r4(p72) -- line: 1653
    -- upvalues: v448 (ref)
    local v452 = v448

    v448 = p72

    return v452
end

local function volume_floats_dense(p73, p74, p75) -- line: 1660
    -- upvalues: v49 (copy), t23 (copy), t24 (copy), t25 (copy), t26 (copy), t27 (copy), t31 (copy), volume_floats (copy), t32 (copy)
    volume_floats(p73, p74, p75)

    local v453 = t23[p73]
    local v454 = t31[p73]
    local v455 = t25[p73]
    local v456 = t26[p73]
    local v457 = t27[p73]
    local v458 = t24[p73]
    local v459 = false

    if v453 == 1 then
        local v460 = v455 + v456 + v457 + v458

        v459 = v460 - v460 == 0
    elseif v453 == 2 then
        v454[12] = 0

        if p74[20] == 0 then
            local v461 = v455 + v456 + v457 + v458 + v454[1] + v454[2] + v454[3] + v454[4]

            v459 = v461 - v461 == 0
        end
    elseif v453 == 3 then
        buffer.writeu32(v49, 0, p74[17])

        local v463 = buffer.readf32(v49, 0)

        buffer.writeu32(v49, 0, p74[18])

        local v465 = buffer.readf32(v49, 0)

        buffer.writeu32(v49, 0, p74[19])

        local v467 = buffer.readf32(v49, 0)

        buffer.writeu32(v49, 0, p74[21])

        local v469 = buffer.readf32(v49, 0)

        buffer.writeu32(v49, 0, p74[22])

        local v471 = buffer.readf32(v49, 0)

        buffer.writeu32(v49, 0, p74[23])

        local v473 = buffer.readf32(v49, 0)

        buffer.writeu32(v49, 0, p74[25])

        local v475 = buffer.readf32(v49, 0)

        buffer.writeu32(v49, 0, p74[26])

        local v477 = buffer.readf32(v49, 0)

        buffer.writeu32(v49, 0, p74[27])

        local v479 = buffer.readf32(v49, 0)

        v454[12] = v463
        v454[13] = v465
        v454[14] = v467
        v454[15] = v469
        v454[16] = v471
        v454[17] = v473
        v454[18] = v475
        v454[19] = v477
        v454[20] = v479

        if p74[20] == 0 and p74[24] == 0 and p74[28] == 0 then
            local v480 = v455 + v456 + v457 + v458 + v454[1] + v454[2] + v454[3] + v454[4] + v454[5] + v454[6] + v454[7] + v454[8] + v454[9] + v454[10] + v454[11] + v463 + v465 + v467 + v469 + v471 + v473 + v475 + v477 + v479

            v459 = v480 - v480 == 0
        end
    elseif v453 == 4 then
        buffer.writeu32(v49, 0, p74[17])

        local v482 = buffer.readf32(v49, 0)

        buffer.writeu32(v49, 0, p74[18])

        local v484 = buffer.readf32(v49, 0)

        buffer.writeu32(v49, 0, p74[19])

        local v486 = buffer.readf32(v49, 0)

        buffer.writeu32(v49, 0, p74[21])

        local v488 = buffer.readf32(v49, 0)

        buffer.writeu32(v49, 0, p74[22])

        local v490 = buffer.readf32(v49, 0)

        buffer.writeu32(v49, 0, p74[23])

        local v492 = buffer.readf32(v49, 0)

        buffer.writeu32(v49, 0, p74[25])

        local v494 = buffer.readf32(v49, 0)

        buffer.writeu32(v49, 0, p74[26])

        local v496 = buffer.readf32(v49, 0)

        buffer.writeu32(v49, 0, p74[27])

        local v498 = buffer.readf32(v49, 0)

        v454[10] = v482
        v454[11] = v484
        v454[12] = v486
        v454[13] = v488
        v454[14] = v490
        v454[15] = v492
        v454[16] = v494
        v454[17] = v496
        v454[18] = v498
        buffer.writeu32(v49, 0, p74[5])

        local v500 = buffer.readf32(v49, 0)

        buffer.writeu32(v49, 0, p74[6])

        local v502 = buffer.readf32(v49, 0)

        buffer.writeu32(v49, 0, p74[7])

        local v504 = buffer.readf32(v49, 0)

        buffer.writeu32(v49, 0, p74[9])

        local v506 = buffer.readf32(v49, 0)

        buffer.writeu32(v49, 0, p74[10])

        local v508 = buffer.readf32(v49, 0)

        buffer.writeu32(v49, 0, p74[11])

        local v510 = buffer.readf32(v49, 0)

        buffer.writeu32(v49, 0, p74[13])

        local v512 = buffer.readf32(v49, 0)

        buffer.writeu32(v49, 0, p74[14])

        local v514 = buffer.readf32(v49, 0)

        buffer.writeu32(v49, 0, p74[15])

        local v516 = buffer.readf32(v49, 0)

        v454[19] = v500
        v454[20] = v502
        v454[21] = v504
        v454[22] = v506
        v454[23] = v508
        v454[24] = v510
        v454[25] = v512
        v454[26] = v514
        v454[27] = v516

        local v517 = v455 + v456 + v457 + v458 + v454[1] + v454[2] + v454[3] + v454[4] + v454[5] + v454[6] + v454[7] + v454[8] + v454[9] + v482 + v484 + v486 + v488 + v490 + v492 + v494 + v496 + v498 + v500 + v502 + v504 + v506 + v508 + v510 + v512 + v514 + v516

        v459 = v517 - v517 == 0
    end

    t32[p73] = v459

    return v453
end

local v518 = true
local v519
local t35 = {}
local n5 = 0
local t36 = {}
local t37 = {}
local t38 = {}
local t39 = {}
local t40 = {}
local t41 = {}
local t42 = {}
local t43 = {}
local t44 = {}
local t45 = {}
local t46 = {}
local t47 = {}
local t48 = {}

function t1.set_triangle_classes(p76) -- line: 1735
    -- upvalues: v518 (ref)
    local v520 = v518

    v518 = p76

    return v520
end

function t1.set_class_stats(p77) -- line: 1742
    -- upvalues: v519 (ref)
    v519 = p77
end

local function pack_volume(p78, p79) -- line: 1747
    -- upvalues: t20 (copy), t21 (copy), pack_primitive_into (copy), t24 (copy), t28 (copy), t29 (copy), t30 (copy), t31 (copy), t32 (copy), volume_floats_dense (copy), t35 (copy), n5 (ref), t36 (copy), t37 (copy), t38 (copy), t39 (copy), t40 (copy), t41 (copy), t42 (copy), t43 (copy), t44 (copy), t45 (copy)
    local linear_velocity = p79.linear_velocity
    local v521 = linear_velocity.x * 0.01666666753590107
    local v522 = linear_velocity.y * 0.01666666753590107
    local v523 = linear_velocity.z * 0.01666666753590107

    t28[p78] = v521
    t29[p78] = v522
    t30[p78] = v523

    local v524 = t20[p78]

    if v524 == nil then
        v524 = table.create(48, 0)
        t20[p78] = v524
    end

    local _, v525 = pack_primitive_into(v524, p79.primitive)

    t21[p78] = v525

    local v526 = volume_floats_dense(p78, v524, v525)

    t35[p78] = 0

    if v526 == 3 and t32[p78] then
        local v527 = v524[5]
        local v528 = v524[6]
        local v529 = v524[7]
        local v530 = t24[p78]
        local v531 = t31[p78]
        local v532 = v531[4]
        local v533 = v531[5]
        local v534 = n5
        local n6 = 0

        for i = 1, v534 do
            if t36[i] == v527 and t37[i] == v528 and t38[i] == v529 and t39[i] == v521 and t40[i] == v522 and t41[i] == v523 and t42[i] == v530 then
                n6 = i
                break
            end
        end

        if n6 == 0 then
            n6 = n5 + 1
            n5 = n6
            t36[n6] = v527
            t37[n6] = v528
            t38[n6] = v529
            t39[n6] = v521
            t40[n6] = v522
            t41[n6] = v523
            t42[n6] = v530
            t43[n6] = v532
            t44[n6] = v533
        else
            if v532 < t43[n6] then
                t43[n6] = v532
            end

            if t44[n6] < v533 then
                t44[n6] = v533
            end
        end

        t45[n6] = -1
        t35[p78] = n6
    end

    return v526
end

function t1.dense_volume(p80, p81) -- line: 1809
    -- upvalues: t20 (copy), t24 (copy), t25 (copy), t26 (copy), t27 (copy), t31 (copy), t32 (copy), pack_volume (copy)
    return pack_volume(p80, p81), t20[p80], t31[p80], t32[p80], t25[p80], t26[p80], t27[p80], t24[p80]
end

local function triangle_mirror(p82, p83, p84, p85) -- line: 1822
    -- upvalues: pack_primitive_into (copy), triangle_floats (copy), v451 (copy), t34 (copy)
    local triangle_fp_old = p82.triangle_fp_old
    local v535 = if triangle_fp_old == nil then nil else triangle_fp_old[p85 + 1]

    if v535 == nil then
        local triangle = p84[p85 + 1].triangle

        t34[1] = triangle
        pack_primitive_into(v451, t34)
        t34[1] = nil
        v535 = triangle_floats(v451, triangle)
    end

    local triangle_fp_count = p82.triangle_fp_count
    local v536

    if triangle_fp_count >= 4096 then
        p82.triangle_fp_old = p83
        v536 = {}
        triangle_fp_count = 0
        p82.triangle_fp = v536
    else
        v536 = p83
    end

    v536[p85 + 1] = v535
    p82.triangle_fp_count = triangle_fp_count + 1

    return v535, v536
end

function t1.BoardWorld.query_primitives(p86, p87, p88, p89, p90) -- line: 1846
    -- upvalues: rt (copy), by_world (copy), combine_contact_materials (copy), v49 (copy), to_bits (copy), primitive_triangle_world_contacts_flat (copy), flat_points (copy), primitive_conservative_bounds_scalar (copy), flat_triangle_bounds (copy), contact_id (copy), last_is_duplicate (copy), is_finite (copy), fmin (copy), fmax (copy), v95 (ref), t12 (copy), flush_publish (copy), allocate_publish (copy), t14 (copy), t15 (copy), t16 (copy), t17 (copy), t18 (copy), t19 (copy), t20 (copy), t21 (copy), v125 (copy), query_primitives_gr (copy), v270 (ref), t23 (copy), t24 (copy), t25 (copy), t26 (copy), t27 (copy), t28 (copy), t29 (copy), t30 (copy), t31 (copy), query_primitives_r4 (copy), v448 (ref), capsule_triangle_contacts_flat (copy), triangle_triangle_contacts_flat (copy), box_triangle_rejects (copy), triangle_gp_record (copy), sphere_triangle_contacts_dense (copy), t32 (copy), candidate_ranges_into (copy), v449 (copy), v450 (copy), t33 (copy), v518 (ref), v519 (ref), t35 (copy), n5 (ref), t43 (copy), t44 (copy), t45 (copy), t46 (copy), t47 (copy), t48 (copy), pack_volume (copy), triangle_mirror (copy)
    if v270 then
        return (query_primitives_gr(p86, p87, p88, p89))
    end

    if v448 or p86.query_metadata == nil then
        return (query_primitives_r4(p86, p87, p88, p89))
    end

    table.clear(p86.contacts)

    local v537

    if p90 ~= nil and v95 then
        v537 = t12[p90]

        if v537 ~= nil then
            v537.used = 0
        end
    end

    local _buffer = p86.buffer

    _buffer.count = 0
    _buffer.flushed = 0
    _buffer.dropped = 0
    _buffer.full = 0
    _buffer.capacity = p89.capacity
    _buffer.distance_squared_threshold = p89.duplicate_distance_squared
    _buffer.deferred_reduction = p89.deferred_reduction and 1 or 0

    local v538 = p88.volume_padding
    local v539, v540

    if v538 == v538 and v538 ~= 1e999 and v538 ~= (-1e999) then
        v538 = p88.maximum_separating_distance
        v539 = v538 == v538 and v538 ~= 1e999 and v538 ~= (-1e999)
        v540 = not not v539
    else
        v540 = false
    end

    local contacts = if v540 then rt.fmax(p88.volume_padding, 0) + rt.fmax(p88.maximum_separating_distance, 0) else 1e999

    v539 = #p87

    if v539 == 0 then
        if p86.triangle_gp == nil then
            p86.triangle_gp = {}
        end

        flush_publish(_buffer, p86.contacts, v537)
    else
        local v541 = contacts + p86.maximum_fatness
        local v542, v543, v544, triangles, v545

        for i = 1, v539 do
            local v546

            v546, v545, v542, v543, v544, triangles = primitive_conservative_bounds_scalar(p87[i].primitive, v541)

            if v546 == nil then
                return (query_primitives_r4(p86, p87, p88, p89))
            end

            t14[i] = v546
            t15[i] = v545
            t16[i] = v542
            t17[i] = v543
            t18[i] = v544
            t19[i] = triangles
            t23[i] = -1
        end

        v541 = v518
        n5 = 0

        local v547 = v519

        v542 = t14[1]
        v543 = t15[1]
        v544 = t16[1]
        triangles = is_finite(v542) and is_finite(v543) and is_finite(v544)

        local v548 = v542
        local v549 = v543
        local v550 = v544
        local triangle_gp, maximum_separating_distance, volume_padding, v551, v552, v553, v554

        if triangles then
            for i = 1, v539 do
                local v555 = false
                local v556 = false
                local v557 = false
                local v558, v559

                if i > 1 then
                    local v560 = t14[i]
                    local v561 = t15[i]
                    local v562 = t16[i]

                    if is_finite(v560) and is_finite(v561) and is_finite(v562) then
                        v558 = fmin(v542, v560)
                        v559 = fmin(v543, v561)
                        triangle_gp = fmin(v544, v562)
                        maximum_separating_distance = fmax(v548, v560)
                        volume_padding = fmax(v549, v561)
                        v551 = fmax(v550, v562)
                        v555 = true
                    else
                        v556 = true
                    end
                else
                    v558 = v542
                    v559 = v543
                    triangle_gp = v544
                    maximum_separating_distance = v548
                    volume_padding = v549
                    v551 = v550
                    v555 = true
                end

                if v555 then
                    v552 = t17[i]
                    v553 = t18[i]
                    v554 = t19[i]

                    if not is_finite(v552) or not is_finite(v553) or not is_finite(v554) then
                        v557 = true
                    end
                end

                if v557 then
                    v542 = v558
                    v543 = v559
                    v544 = triangle_gp
                    triangles = false
                    v548 = maximum_separating_distance
                    v549 = volume_padding
                    v550 = v551
                    break
                end

                if v556 then
                    triangles = false
                    break
                end

                v542 = fmin(v558, v552)
                v543 = fmin(v559, v553)
                v544 = fmin(triangle_gp, v554)
                v548 = fmax(maximum_separating_distance, v552)
                v549 = fmax(volume_padding, v553)
                v550 = fmax(v551, v554)
            end
        end

        v545 = if triangles then candidate_ranges_into(p86, v542 - contacts, v543 - contacts, v544 - contacts, v548 + contacts, v549 + contacts, v550 + contacts, v449, v450, t33) else candidate_ranges_into(p86, nil, nil, nil, nil, nil, nil, v449, v450, t33)
        contacts = p86.contacts
        triangle_gp = p86.triangle_gp

        if triangle_gp == nil then
            triangle_gp = {}
            p86.triangle_gp = triangle_gp
        end

        triangles = p86.triangles
        maximum_separating_distance = p88.maximum_separating_distance
        volume_padding = p88.volume_padding
        v551 = flat_triangle_bounds(p86)

        local v563 = t14[1]
        local v564 = t15[1]

        v552 = t16[1]
        v553 = t17[1]
        v554 = t18[1]

        local v565 = t19[1]
        local v566 = v563 == v563 and v564 == v564 and v552 == v552 and v553 == v553 and v554 == v554 and v565 == v565

        for i = 2, v539 do
            local v567 = t14[i]
            local v568 = t15[i]
            local v569 = t16[i]
            local v570 = t17[i]
            local v571 = t18[i]
            local v572 = t19[i]
            local v573 = false
            local v574, v575, v576, v577, v578, v579

            if v567 == v567 and v568 == v568 and v569 == v569 and v570 == v570 and v571 == v571 and v572 == v572 then
                v574 = if v567 < v563 then v567 else v563
                v575 = if v568 < v564 then v568 else v564
                v576 = if v569 < v552 then v569 else v552
                v577 = if v553 < v570 then v570 else v553
                v578 = if v554 < v571 then v571 else v554
                v579 = if v565 < v572 then v572 else v565
            else
                v573 = true
            end

            if v573 then
                v566 = false
                break
            end

            v565 = v579
            v563 = v574
            v564 = v575
            v552 = v576
            v553 = v577
            v554 = v578
        end

        local triangle_fp = p86.triangle_fp

        if triangle_fp == nil then
            triangle_fp = {}
            p86.triangle_fp = triangle_fp
            p86.triangle_fp_count = 0
        end

        local v580 = p86.paged ~= nil or by_world[p86] ~= nil

        v550 = v551

        for i = 1, v545 do
            local v581, v582

            if v580 then
                v582 = t33[i]

                if v582 ~= nil then
                    v550 = v582.flat
                    v581 = v582.first
                else
                    v550 = v551
                    v581 = 0
                end
            else
                v581 = 0
            end

            for j = v449[i] - v581, v450[i] - 1 - v581 do
                local v584 = j * 6
                local v585 = false
                local v586, v587, v588, v589, v590, v591, v592

                if v566 then
                    local v593 = v550[v584 + 4]

                    if v593 < v563 then
                        v592 = triangle_fp
                    else
                        local v594 = v550[v584 + 1]

                        if v553 < v594 then
                            v592 = triangle_fp
                        else
                            local v595 = v550[v584 + 5]

                            if v595 < v564 then
                                v592 = triangle_fp
                            else
                                local v596 = v550[v584 + 2]

                                if v554 < v596 then
                                    v592 = triangle_fp
                                else
                                    local v597 = v550[v584 + 6]

                                    if v597 < v552 then
                                        v592 = triangle_fp
                                    else
                                        local v598 = v550[v584 + 3]

                                        if v565 < v598 then
                                            v592 = triangle_fp
                                        else
                                            v587 = v594
                                            v589 = v596
                                            v591 = v598
                                            v586 = v593
                                            v588 = v595
                                            v590 = v597
                                            v585 = true
                                        end
                                    end
                                end
                            end
                        end
                    end
                else
                    v587 = v550[v584 + 1]
                    v589 = v550[v584 + 2]
                    v591 = v550[v584 + 3]
                    v586 = v550[v584 + 4]
                    v588 = v550[v584 + 5]
                    v590 = v550[v584 + 6]
                    v585 = true
                end

                if v585 then
                    v584 = j + v581
                    v592 = triangle_fp

                    local v599 = nil
                    local v600 = nil
                    local v601 = nil
                    local v602 = nil
                    local v603 = nil
                    local v604 = nil
                    local v605 = nil
                    local v606 = nil
                    local v607 = nil
                    local v608 = nil
                    local v609 = nil
                    local v610 = nil
                    local v611 = false
                    local v612 = false
                    local v613 = false
                    local v614 = nil
                    local v615 = nil
                    local v616 = nil
                    local v617 = nil
                    local v618 = nil
                    local v619 = nil
                    local v620 = nil
                    local v621 = nil
                    local v622 = nil

                    for k = 1, v539 do
                        local v623 = false
                        local v624 = false
                        local v625 = false
                        local v626 = false
                        local v627 = false
                        local v628 = false
                        local v629 = false
                        local v630 = false
                        local v631, v632, v633, v634, v635, v636, v637, v638, v639, v640, v641, v642, v643, v644, v645, v646, v647, v648, v649, v650, v651, v652, v653, v654, v655, v656, v657, v658, v659, v660, v661, v662, v663, v664, v665, v666, v667, v668, v669, v670, v671

                        if v586 < t14[k]
                            or t17[k] < v587
                            or v588 < t15[k]
                            or t18[k] < v589
                            or v590 < t16[k]
                            or t19[k] < v591 then
                            v671 = v622
                            v638 = v592
                            v637 = v599
                            v636 = v600
                            v660 = v601
                            v640 = v602
                            v642 = v603
                            v644 = v604
                            v650 = v605
                            v652 = v606
                            v654 = v607
                            v648 = v608
                            v656 = v609
                            v658 = v610
                            v646 = v611
                            v661 = v612
                            v639 = v613
                            v663 = v614
                            v664 = v615
                            v665 = v616
                            v666 = v617
                            v667 = v618
                            v668 = v619
                            v669 = v620
                            v670 = v621
                        else
                            v631 = t23[k]

                            if v631 < 0 then
                                v631 = pack_volume(k, p87[k])
                            end

                            v633 = v592

                            if v599 ~= nil then
                                v634 = v613
                                v632 = v599
                                v641 = v602
                                v643 = v603
                                v645 = v604
                                v651 = v605
                                v653 = v606
                                v655 = v607
                                v649 = v608
                                v657 = v609
                                v659 = v610
                                v647 = v611
                                v662 = v612
                            else
                                v632 = v592[v584 + 1]

                                if v632 == nil then
                                    v632, v633 = triangle_mirror(p86, v592, triangles, v584)
                                end

                                v641 = v632[1]
                                v643 = v632[2]
                                v645 = v632[3]
                                v651 = v632[4]
                                v653 = v632[5]
                                v655 = v632[6]
                                v649 = v632[16]
                                v657 = v632[17]
                                v659 = v632[18]
                                v647 = v632[19] == 1
                                v662 = v632[33] == 1
                                v634 = v541 and v647 and v662
                            end

                            if v634 and v631 == 3 then
                                v635 = t35[k]

                                if v635 == 0 then
                                    v623 = true
                                elseif t45[v635] == v584 and t48[v635] then
                                    v671 = v622
                                    v638 = v633
                                    v637 = v632
                                    v636 = v600
                                    v660 = v601
                                    v640 = v641
                                    v642 = v643
                                    v644 = v645
                                    v650 = v651
                                    v652 = v653
                                    v654 = v655
                                    v648 = v649
                                    v656 = v657
                                    v658 = v659
                                    v646 = v647
                                    v661 = v662
                                    v639 = v634
                                    v663 = v614
                                    v664 = v615
                                    v665 = v616
                                    v666 = v617
                                    v667 = v618
                                    v668 = v619
                                    v669 = v620
                                    v670 = v621
                                else
                                    v623 = true
                                end
                            else
                                v623 = true
                            end
                        end

                        local v672, v673, v674, v675, v676, v677, v678, v679, v680, v681, v682, v683, v684, v685, v686, v687, v688, v689, v690, v691, v692, v693, v694, v695, v696, v697, v698, v699, v700, v701, v702, v703, v704, v705, v706, v707, v708, v709, v710, v711, v712, v713, v714

                        if v623 then
                            local v715 = v641 * t28[k] + v643 * t29[k] + v645 * t30[k]

                            if -v715 >= 0 then
                                v715 = 0
                            end

                            if not (maximum_separating_distance - v715 >= 0) then
                                v715 = maximum_separating_distance
                            end

                            v672 = v715 + volume_padding

                            if v631 == 0 then
                                v624 = true
                            elseif v647 then
                                v673 = t25[k]
                                v674 = t26[k]
                                v675 = t27[k]
                                v676 = v649 + v672 + t24[k]

                                if v631 == 1 then
                                    v692 = v673 * v651 + v674 * v653 + v675 * v655

                                    if not (v692 < 1.1754943508222875E-38) or not (v692 > -1.1754943508222875E-38) or v692 == 0 then
                                        buffer.writef32(v49, 0, v692)
                                    else
                                        buffer.writeu32(v49, 0, to_bits(v692))
                                    end

                                    v693 = buffer.readf32(v49, 0)
                                    v692 = v693 - v659
                                    v693 = v657 - v693

                                    local v716 = v693 < v692

                                    if not v716 then
                                        v692 = v693
                                    end

                                    if not (v692 < 1.1754943508222875E-38) or not (v692 > -1.1754943508222875E-38) or v692 == 0 then
                                        buffer.writef32(v49, 0, v692)
                                    else
                                        buffer.writeu32(v49, 0, to_bits(v692))
                                    end

                                    v684 = buffer.readf32(v49, 0)

                                    if v676 < v684 then
                                        v671 = v622
                                        v638 = v633
                                        v637 = v632
                                        v636 = v600
                                        v660 = v601
                                        v640 = v641
                                        v642 = v643
                                        v644 = v645
                                        v650 = v651
                                        v652 = v653
                                        v654 = v655
                                        v648 = v649
                                        v656 = v657
                                        v658 = v659
                                        v646 = v647
                                        v661 = v662
                                        v639 = v634
                                        v663 = v614
                                        v664 = v615
                                        v665 = v616
                                        v666 = v617
                                        v667 = v618
                                        v668 = v619
                                        v669 = v620
                                        v670 = v621
                                    else
                                        v678, v679, v680, v681 = sphere_triangle_contacts_dense(v632, triangle_gp, triangles, v584, v716, v684, v673, v674, v675, t24[k], p88)
                                        v682 = v601
                                        v696 = v600

                                        if v678 == -1 then
                                            if v600 == nil then
                                                v696 = triangles[v584 + 1]
                                                v682 = v696.triangle
                                            end

                                            v678, v679, v680, v681 = primitive_triangle_world_contacts_flat(t20[k], "Sphere", triangle_gp_record(triangle_gp, v584, v682), "Triangle", v682, v672, p88)
                                        end

                                        v698 = v614
                                        v700 = v615
                                        v702 = v616
                                        v704 = v617
                                        v706 = v618
                                        v708 = v619
                                        v710 = v620
                                        v712 = v621
                                        v714 = v622
                                        v625 = true
                                    end
                                elseif v631 == 2 then
                                    v683 = t31[k]
                                    v692 = v673 * v651 + v674 * v653 + v675 * v655
                                    v695 = v683[1] * v651 + v683[2] * v653 + v683[3] * v655
                                    v686 = math.abs(v695) * v683[4]
                                    v684 = v692 - v686

                                    if not (v684 < 1.1754943508222875E-38) or not (v684 > -1.1754943508222875E-38) or v684 == 0 then
                                        buffer.writef32(v49, 0, v684)
                                    else
                                        buffer.writeu32(v49, 0, to_bits(v684))
                                    end

                                    v685 = buffer.readf32(v49, 0) - v659
                                    v677 = v692 + v686

                                    if not (v677 < 1.1754943508222875E-38) or not (v677 > -1.1754943508222875E-38) or v677 == 0 then
                                        buffer.writef32(v49, 0, v677)
                                    else
                                        buffer.writeu32(v49, 0, to_bits(v677))
                                    end

                                    v695 = v657 - buffer.readf32(v49, 0)
                                    v686 = v695 < v685

                                    if not v686 then
                                        v685 = v695
                                    end

                                    if v685 == v685 then
                                        if not (v685 < 1.1754943508222875E-38) or not (v685 > -1.1754943508222875E-38) or v685 == 0 then
                                            buffer.writef32(v49, 0, v685)
                                        else
                                            buffer.writeu32(v49, 0, to_bits(v685))
                                        end

                                        if v676 < buffer.readf32(v49, 0) then
                                            v671 = v622
                                            v638 = v633
                                            v637 = v632
                                            v636 = v600
                                            v660 = v601
                                            v640 = v641
                                            v642 = v643
                                            v644 = v645
                                            v650 = v651
                                            v652 = v653
                                            v654 = v655
                                            v648 = v649
                                            v656 = v657
                                            v658 = v659
                                            v646 = v647
                                            v661 = v662
                                            v639 = v634
                                            v663 = v614
                                            v664 = v615
                                            v665 = v616
                                            v666 = v617
                                            v667 = v618
                                            v668 = v619
                                            v669 = v620
                                            v670 = v621
                                        else
                                            v687 = v662 and t32[k]
                                            v630 = true
                                        end
                                    else
                                        v687 = false
                                        v630 = true
                                    end
                                elseif v631 == 3 then
                                    v688 = t31[k]
                                    v689 = if v634 then t35[k] else 0

                                    if v689 == 0 then
                                        v627 = true
                                    elseif t45[v689] == v584 then
                                        v690 = t46[v689]
                                        v691 = t47[v689]

                                        if v547 then
                                            v547.shared = (v547.shared or 0) + 1
                                        end

                                        v697 = v614
                                        v699 = v615
                                        v701 = v616
                                        v703 = v617
                                        v705 = v618
                                        v707 = v619
                                        v709 = v620
                                        v711 = v621
                                        v713 = v622
                                        v628 = true
                                    else
                                        v627 = true
                                    end
                                else
                                    local v717 = t31[k]

                                    v692 = v673 * v651 + v674 * v653 + v675 * v655
                                    v684 = v717[1] * v651 + v717[2] * v653 + v717[3] * v655
                                    v695 = math.abs(v684)
                                    v677 = v717[4] * v651 + v717[5] * v653 + v717[6] * v655
                                    v694 = v695 + math.abs(v677)
                                    v684 = v717[7] * v651 + v717[8] * v653 + v717[9] * v655
                                    v693 = v694 + math.abs(v684)
                                    v694 = v632[20] - (v692 + v693)
                                    v695 = v692 - v693 - v632[21]

                                    if not (v695 < v694) then
                                        v694 = v695
                                    end

                                    if v694 == v694 then
                                        if not (v694 < 1.1754943508222875E-38) or not (v694 > -1.1754943508222875E-38) or v694 == 0 then
                                            buffer.writef32(v49, 0, v694)
                                        else
                                            buffer.writeu32(v49, 0, to_bits(v694))
                                        end

                                        if v676 < buffer.readf32(v49, 0) or v662 and t32[k] and box_triangle_rejects(v632, v717, v673, v674, v675, v694, v676) then
                                            v671 = v622
                                            v638 = v633
                                            v637 = v632
                                            v636 = v600
                                            v660 = v601
                                            v640 = v641
                                            v642 = v643
                                            v644 = v645
                                            v650 = v651
                                            v652 = v653
                                            v654 = v655
                                            v648 = v649
                                            v656 = v657
                                            v658 = v659
                                            v646 = v647
                                            v661 = v662
                                            v639 = v634
                                            v663 = v614
                                            v664 = v615
                                            v665 = v616
                                            v666 = v617
                                            v667 = v618
                                            v668 = v619
                                            v669 = v620
                                            v670 = v621
                                        else
                                            v626 = true
                                        end
                                    else
                                        v626 = true
                                    end
                                end
                            else
                                v624 = true
                            end
                        end

                        if v624 then
                            if v600 ~= nil then
                                v682 = v601
                                v696 = v600
                            else
                                v696 = triangles[v584 + 1]
                                v682 = v696.triangle
                            end

                            v678, v679, v680, v681 = primitive_triangle_world_contacts_flat(t20[k], t21[k], triangle_gp_record(triangle_gp, v584, v682), "Triangle", v682, v672, p88)
                            v698 = v614
                            v700 = v615
                            v702 = v616
                            v704 = v617
                            v706 = v618
                            v708 = v619
                            v710 = v620
                            v712 = v621
                            v714 = v622
                            v625 = true
                        end

                        if v626 then
                            if v600 ~= nil then
                                v682 = v601
                                v696 = v600
                            else
                                v696 = triangles[v584 + 1]
                                v682 = v696.triangle
                            end

                            v678, v679, v680, v681 = primitive_triangle_world_contacts_flat(t20[k], "Box", triangle_gp_record(triangle_gp, v584, v682), "Triangle", v682, v672, p88)
                            v698 = v614
                            v700 = v615
                            v702 = v616
                            v704 = v617
                            v706 = v618
                            v708 = v619
                            v710 = v620
                            v712 = v621
                            v714 = v622
                            v625 = true
                        end

                        local v718, v719, v720, v721, v722

                        if v627 then
                            v718 = v688[1]
                            v722 = v688[2]
                            v721 = v688[3]

                            local v723, v724, v725, v726, v727, v728, v729, v730, v731

                            if v614 ~= nil then
                                v731 = v622
                                v723 = v614
                                v724 = v615
                                v725 = v616
                                v726 = v617
                                v727 = v618
                                v728 = v619
                                v729 = v620
                                v730 = v621
                            else
                                v723 = v632[7]
                                v724 = v632[8]
                                v725 = v632[9]
                                v726 = v632[10]
                                v727 = v632[11]
                                v728 = v632[12]
                                v729 = v632[13]
                                v730 = v632[14]
                                v731 = v632[15]
                            end

                            v692 = v723 * v718 + v724 * v722 + v725 * v721
                            v693 = v726 * v718 + v727 * v722 + v728 * v721
                            v694 = v729 * v718 + v730 * v722 + v731 * v721
                            v720 = if v692 < v693 then v692 else v693

                            if not (v693 < v692) then
                                v692 = v693
                            end

                            if not (v694 < v692) then
                                v692 = v694
                            end

                            if not (v692 < 1.1754943508222875E-38) or not (v692 > -1.1754943508222875E-38) or v692 == 0 then
                                buffer.writef32(v49, 0, v692)
                            else
                                buffer.writeu32(v49, 0, to_bits(v692))
                            end

                            v719 = buffer.readf32(v49, 0)

                            if not (v720 < v694) then
                                v720 = v694
                            end

                            if not (v720 < 1.1754943508222875E-38) or not (v720 > -1.1754943508222875E-38) or v720 == 0 then
                                buffer.writef32(v49, 0, v720)
                            else
                                buffer.writeu32(v49, 0, to_bits(v720))
                            end

                            local v732 = buffer.readf32(v49, 0)

                            if v689 == 0 then
                                v697 = v723
                                v699 = v724
                                v701 = v725
                                v703 = v726
                                v705 = v727
                                v707 = v728
                                v709 = v729
                                v711 = v730
                                v713 = v731
                                v690 = v719
                                v691 = v732
                                v628 = true
                            else
                                t45[v689] = v584
                                t46[v689] = v719
                                t47[v689] = v732
                                v721 = t43[v689] - v719
                                v722 = v732 - t44[v689]

                                if not (v722 < v721) then
                                    v721 = v722
                                end

                                if v721 == v721 then
                                    if not (v721 < 1.1754943508222875E-38) or not (v721 > -1.1754943508222875E-38) or v721 == 0 then
                                        buffer.writef32(v49, 0, v721)
                                    else
                                        buffer.writeu32(v49, 0, to_bits(v721))
                                    end

                                    v721 = v676 < buffer.readf32(v49, 0)
                                else
                                    v721 = false
                                end

                                t48[v689] = v721

                                if v547 then
                                    v547.formed = (v547.formed or 0) + 1

                                    if v721 then
                                        v547.rejected = (v547.rejected or 0) + 1
                                    end
                                end

                                if v721 then
                                    v671 = v731
                                    v638 = v633
                                    v637 = v632
                                    v636 = v600
                                    v660 = v601
                                    v640 = v641
                                    v642 = v643
                                    v644 = v645
                                    v650 = v651
                                    v652 = v653
                                    v654 = v655
                                    v648 = v649
                                    v656 = v657
                                    v658 = v659
                                    v646 = v647
                                    v661 = v662
                                    v639 = v634
                                    v663 = v723
                                    v664 = v724
                                    v665 = v725
                                    v666 = v726
                                    v667 = v727
                                    v668 = v728
                                    v669 = v729
                                    v670 = v730
                                else
                                    v697 = v723
                                    v699 = v724
                                    v701 = v725
                                    v703 = v726
                                    v705 = v727
                                    v707 = v728
                                    v709 = v729
                                    v711 = v730
                                    v713 = v731
                                    v690 = v719
                                    v691 = v732
                                    v628 = true
                                end
                            end
                        end

                        local v733, v734, v735, v736, v737, v738, v739

                        if v628 then
                            v734 = v688[4] - v690
                            v677 = v691 - v688[5]
                            v735 = v677 < v734

                            if not v735 then
                                v734 = v677
                            end

                            if v734 == v734 then
                                if not (v734 < 1.1754943508222875E-38) or not (v734 > -1.1754943508222875E-38) or v734 == 0 then
                                    buffer.writef32(v49, 0, v734)
                                else
                                    buffer.writeu32(v49, 0, to_bits(v734))
                                end

                                if v676 < buffer.readf32(v49, 0) then
                                    v671 = v713
                                    v638 = v633
                                    v637 = v632
                                    v636 = v600
                                    v660 = v601
                                    v640 = v641
                                    v642 = v643
                                    v644 = v645
                                    v650 = v651
                                    v652 = v653
                                    v654 = v655
                                    v648 = v649
                                    v656 = v657
                                    v658 = v659
                                    v646 = v647
                                    v661 = v662
                                    v639 = v634
                                    v663 = v697
                                    v664 = v699
                                    v665 = v701
                                    v666 = v703
                                    v667 = v705
                                    v668 = v707
                                    v669 = v709
                                    v670 = v711
                                else
                                    v692 = v673 * v651 + v674 * v653 + v675 * v655
                                    v693 = v688[6] * v651 + v688[7] * v653 + v688[8] * v655
                                    v694 = v688[9] * v651 + v688[10] * v653 + v688[11] * v655
                                    v733 = if v692 < v693 then v692 else v693

                                    if not (v693 < v692) then
                                        v692 = v693
                                    end

                                    if not (v733 < v694) then
                                        v733 = v694
                                    end

                                    if not (v733 < 1.1754943508222875E-38) or not (v733 > -1.1754943508222875E-38) or v733 == 0 then
                                        buffer.writef32(v49, 0, v733)
                                    else
                                        buffer.writeu32(v49, 0, to_bits(v733))
                                    end

                                    v736 = buffer.readf32(v49, 0) - v659

                                    if not (v694 < v692) then
                                        v692 = v694
                                    end

                                    if not (v692 < 1.1754943508222875E-38) or not (v692 > -1.1754943508222875E-38) or v692 == 0 then
                                        buffer.writef32(v49, 0, v692)
                                    else
                                        buffer.writeu32(v49, 0, to_bits(v692))
                                    end

                                    v677 = v657 - buffer.readf32(v49, 0)
                                    v720 = v677 < v736

                                    if not v720 then
                                        v736 = v677
                                    end

                                    if not (v736 < 1.1754943508222875E-38) or not (v736 > -1.1754943508222875E-38) or v736 == 0 then
                                        buffer.writef32(v49, 0, v736)
                                    else
                                        buffer.writeu32(v49, 0, to_bits(v736))
                                    end

                                    if v676 < buffer.readf32(v49, 0) then
                                        v671 = v713
                                        v638 = v633
                                        v637 = v632
                                        v636 = v600
                                        v660 = v601
                                        v640 = v641
                                        v642 = v643
                                        v644 = v645
                                        v650 = v651
                                        v652 = v653
                                        v654 = v655
                                        v648 = v649
                                        v656 = v657
                                        v658 = v659
                                        v646 = v647
                                        v661 = v662
                                        v639 = v634
                                        v663 = v697
                                        v664 = v699
                                        v665 = v701
                                        v666 = v703
                                        v667 = v705
                                        v668 = v707
                                        v669 = v709
                                        v670 = v711
                                    else
                                        v737 = v662 and t32[k]
                                        v738 = v736
                                        v739 = v720
                                        v629 = true
                                    end
                                end
                            else
                                v737 = false
                                v738 = 0
                                v739 = false
                                v629 = true
                            end
                        end

                        if v629 then
                            v682 = v601
                            v696 = v600

                            if v737 then
                                v678, v679, v680, v681 = triangle_triangle_contacts_flat(v632, triangle_gp, triangles, v584, t20[k], v688, v734, v735, v738, v739, v673, v674, v675, v676, v672, p88)
                            else
                                if v600 == nil then
                                    v696 = triangles[v584 + 1]
                                    v682 = v696.triangle
                                end

                                v678, v679, v680, v681 = primitive_triangle_world_contacts_flat(t20[k], "Triangle", triangle_gp_record(triangle_gp, v584, v682), "Triangle", v682, v672, p88, true)
                            end

                            v698 = v697
                            v700 = v699
                            v702 = v701
                            v704 = v703
                            v706 = v705
                            v708 = v707
                            v710 = v709
                            v712 = v711
                            v714 = v713
                            v625 = true
                        end

                        if v630 then
                            v682 = v601
                            v696 = v600

                            if v687 then
                                v678, v679, v680, v681 = capsule_triangle_contacts_flat(v632, triangle_gp, triangles, v584, t20[k], v683, v685, v686, v673, v674, v675, t24[k], v676, v672, p88)
                            else
                                if v600 == nil then
                                    v696 = triangles[v584 + 1]
                                    v682 = v696.triangle
                                end

                                v678, v679, v680, v681 = primitive_triangle_world_contacts_flat(t20[k], "Capsule", triangle_gp_record(triangle_gp, v584, v682), "Triangle", v682, v672, p88, true)
                            end

                            v698 = v614
                            v700 = v615
                            v702 = v616
                            v704 = v617
                            v706 = v618
                            v708 = v619
                            v710 = v620
                            v712 = v621
                            v714 = v622
                            v625 = true
                        end

                        if v625 then
                            if v678 ~= nil then
                                if v696 ~= nil then
                                    v660 = v682
                                    v636 = v696
                                else
                                    v636 = triangles[v584 + 1]
                                    v660 = v636.triangle
                                end

                                v635 = p87[k]

                                local v740 = combine_contact_materials(v635.material, v636.material)
                                local restitution, static_friction, dynamic_friction = v740.restitution, v740.static_friction, v740.dynamic_friction
                                local tag = v636.tag
                                local v741 = v678 - 1

                                v638 = v633
                                v637 = v632
                                v640 = v641
                                v642 = v643
                                v644 = v645
                                v650 = v651
                                v652 = v653
                                v654 = v655
                                v648 = v649
                                v656 = v657
                                v658 = v659
                                v646 = v647
                                v661 = v662
                                v639 = v634
                                v663 = v698
                                v664 = v700
                                v665 = v702
                                v666 = v704
                                v667 = v706
                                v668 = v708
                                v669 = v710
                                v670 = v712
                                v671 = v714

                                for n = 0, v741 do
                                    v693 = n * 6
                                    v694 = flat_points[v693 + 1]
                                    v695 = flat_points[v693 + 2]
                                    v684 = flat_points[v693 + 3]
                                    v677 = flat_points[v693 + 4]

                                    local v742 = flat_points[v693 + 5]

                                    v736 = flat_points[v693 + 6]
                                    v718 = allocate_publish(_buffer, contacts, v537)

                                    if v718 == nil then
                                        flush_publish(_buffer, contacts, v537)

                                        return p86.contacts
                                    end

                                    v671 = v714

                                    local records = _buffer.records

                                    v722 = records[v718 + 1]

                                    if v722 ~= nil then
                                        if #v722 == 64 then
                                            table.move(v125, 1, 64, 1, v722)
                                        else
                                            v722 = table.create(64, 0)
                                            records[v718 + 1] = v722
                                        end
                                    else
                                        v722 = table.create(64, 0)
                                        records[v718 + 1] = v722
                                    end

                                    if v694 == 0 then
                                        buffer.writef32(v49, 0, v694)
                                        v721 = buffer.readu32(v49, 0)
                                    elseif v694 > -1.1754943508222875E-38 and v694 < 1.1754943508222875E-38 then
                                        v721 = to_bits(v694)
                                    else
                                        buffer.writef32(v49, 0, v694)
                                        v721 = buffer.readu32(v49, 0)
                                    end

                                    if v695 == 0 then
                                        buffer.writef32(v49, 0, v695)
                                        v720 = buffer.readu32(v49, 0)
                                    elseif v695 > -1.1754943508222875E-38 and v695 < 1.1754943508222875E-38 then
                                        v720 = to_bits(v695)
                                    else
                                        buffer.writef32(v49, 0, v695)
                                        v720 = buffer.readu32(v49, 0)
                                    end

                                    if v684 == 0 then
                                        buffer.writef32(v49, 0, v684)
                                        v719 = buffer.readu32(v49, 0)
                                    elseif v684 > -1.1754943508222875E-38 and v684 < 1.1754943508222875E-38 then
                                        v719 = to_bits(v684)
                                    else
                                        buffer.writef32(v49, 0, v684)
                                        v719 = buffer.readu32(v49, 0)
                                    end

                                    v722[1] = v721
                                    v722[2] = v720
                                    v722[3] = v719

                                    if v677 == 0 then
                                        buffer.writef32(v49, 0, v677)
                                        v721 = buffer.readu32(v49, 0)
                                    elseif v677 > -1.1754943508222875E-38 and v677 < 1.1754943508222875E-38 then
                                        v721 = to_bits(v677)
                                    else
                                        buffer.writef32(v49, 0, v677)
                                        v721 = buffer.readu32(v49, 0)
                                    end

                                    if v742 == 0 then
                                        buffer.writef32(v49, 0, v742)
                                        v720 = buffer.readu32(v49, 0)
                                    elseif v742 > -1.1754943508222875E-38 and v742 < 1.1754943508222875E-38 then
                                        v720 = to_bits(v742)
                                    else
                                        buffer.writef32(v49, 0, v742)
                                        v720 = buffer.readu32(v49, 0)
                                    end

                                    if v736 == 0 then
                                        buffer.writef32(v49, 0, v736)
                                        v719 = buffer.readu32(v49, 0)
                                    elseif v736 > -1.1754943508222875E-38 and v736 < 1.1754943508222875E-38 then
                                        v719 = to_bits(v736)
                                    else
                                        buffer.writef32(v49, 0, v736)
                                        v719 = buffer.readu32(v49, 0)
                                    end

                                    v722[5] = v721
                                    v722[6] = v720
                                    v722[7] = v719

                                    if v679 == 0 then
                                        buffer.writef32(v49, 0, v679)
                                        v719 = buffer.readu32(v49, 0)
                                    elseif v679 > -1.1754943508222875E-38 and v679 < 1.1754943508222875E-38 then
                                        v719 = to_bits(v679)
                                    else
                                        buffer.writef32(v49, 0, v679)
                                        v719 = buffer.readu32(v49, 0)
                                    end

                                    if v680 == 0 then
                                        buffer.writef32(v49, 0, v680)
                                        v733 = buffer.readu32(v49, 0)
                                    elseif v680 > -1.1754943508222875E-38 and v680 < 1.1754943508222875E-38 then
                                        v733 = to_bits(v680)
                                    else
                                        buffer.writef32(v49, 0, v680)
                                        v733 = buffer.readu32(v49, 0)
                                    end

                                    local writef32

                                    if v681 == 0 then
                                        buffer.writef32(v49, 0, v681)
                                        writef32 = buffer.readu32(v49, 0)
                                    elseif v681 > -1.1754943508222875E-38 and v681 < 1.1754943508222875E-38 then
                                        writef32 = to_bits(v681)
                                    else
                                        buffer.writef32(v49, 0, v681)
                                        writef32 = buffer.readu32(v49, 0)
                                    end

                                    v722[9] = v719
                                    v722[10] = v733
                                    v722[11] = writef32
                                    v722[4] = contact_id(v635.body)
                                    v722[8] = 4294967295

                                    if restitution == 0 then
                                        buffer.writef32(v49, 0, restitution)
                                        v722[12] = buffer.readu32(v49, 0)
                                    elseif restitution > -1.1754943508222875E-38 and restitution < 1.1754943508222875E-38 then
                                        v722[12] = to_bits(restitution)
                                    else
                                        buffer.writef32(v49, 0, restitution)
                                        v722[12] = buffer.readu32(v49, 0)
                                    end

                                    if static_friction == 0 then
                                        buffer.writef32(v49, 0, static_friction)
                                        v722[16] = buffer.readu32(v49, 0)
                                    elseif static_friction > -1.1754943508222875E-38 and static_friction < 1.1754943508222875E-38 then
                                        v722[16] = to_bits(static_friction)
                                    else
                                        buffer.writef32(v49, 0, static_friction)
                                        v722[16] = buffer.readu32(v49, 0)
                                    end

                                    if dynamic_friction == 0 then
                                        buffer.writef32(v49, 0, dynamic_friction)
                                        v722[20] = buffer.readu32(v49, 0)
                                    elseif dynamic_friction > -1.1754943508222875E-38 and dynamic_friction < 1.1754943508222875E-38 then
                                        v722[20] = to_bits(dynamic_friction)
                                    else
                                        buffer.writef32(v49, 0, dynamic_friction)
                                        v722[20] = buffer.readu32(v49, 0)
                                    end

                                    v722[24] = tag

                                    if last_is_duplicate(_buffer) then
                                        _buffer.count -= 1
                                    end

                                    v638 = v633
                                    v637 = v632
                                    v640 = v641
                                    v642 = v643
                                    v644 = v645
                                    v650 = v651
                                    v652 = v653
                                    v654 = v655
                                    v648 = v649
                                    v656 = v657
                                    v658 = v659
                                    v646 = v647
                                    v661 = v662
                                    v639 = v634
                                    v663 = v698
                                    v664 = v700
                                    v665 = v702
                                    v666 = v704
                                    v667 = v706
                                    v668 = v708
                                    v669 = v710
                                    v670 = v712
                                end
                            else
                                v671 = v714
                                v638 = v633
                                v637 = v632
                                v636 = v696
                                v660 = v682
                                v640 = v641
                                v642 = v643
                                v644 = v645
                                v650 = v651
                                v652 = v653
                                v654 = v655
                                v648 = v649
                                v656 = v657
                                v658 = v659
                                v646 = v647
                                v661 = v662
                                v639 = v634
                                v663 = v698
                                v664 = v700
                                v665 = v702
                                v666 = v704
                                v667 = v706
                                v668 = v708
                                v669 = v710
                                v670 = v712
                            end
                        end

                        v622 = v671
                        v592 = v638
                        v599 = v637
                        v600 = v636
                        v601 = v660
                        v602 = v640
                        v603 = v642
                        v604 = v644
                        v605 = v650
                        v606 = v652
                        v607 = v654
                        v608 = v648
                        v609 = v656
                        v610 = v658
                        v611 = v646
                        v612 = v661
                        v613 = v639
                        v614 = v663
                        v615 = v664
                        v616 = v665
                        v617 = v666
                        v618 = v667
                        v619 = v668
                        v620 = v669
                        v621 = v670
                    end
                end

                triangle_fp = v592
            end
        end

        flush_publish(_buffer, contacts, v537)
    end

    return p86.contacts
end

function t1.BoardWorld.contacts(p91) -- line: 2411
    return p91.contacts
end

function t1.BoardWorld.dropped_contacts(p92) -- line: 2415
    return p92.buffer.dropped
end

for v743, v744 in v8.BoardWorld do
    t1.BoardWorld[v743] = v744
end

function t1.retention_record(p93, p94) -- line: 2429
    -- upvalues: v1 (copy), CollisionBody (copy)
    local v745 = table.create(64, 0)

    for _, v746 in {
            {
                0,
                p94.position_on_a
            },
            {
                4,
                p94.position_on_b
            },
            {
                8,
                p94.normal
            }
        } do
        local v747 = v746[1]
        local v748 = v746[2]
        local v749 = v747 + 1
        local x = v748.x
        local v750

        if x == 0 then
            buffer.writef32(v1, 0, x)
            v750 = buffer.readu32(v1, 0)
        elseif x > -1.1754943508222875E-38 and x < 1.1754943508222875E-38 then
            local v751 = math.abs(x) * 7.1362384635298E+44

            v750 = math.floor(v751)

            local v752 = v751 - v750

            if v752 > 0.5 or v752 == 0.5 and v750 % 2 == 1 then
                v750 += 1
            end

            if x < 0 then
                v750 += 2147483648
            end
        else
            buffer.writef32(v1, 0, x)
            v750 = buffer.readu32(v1, 0)
        end

        v745[v749] = v750

        local v753 = v747 + 2
        local y = v748.y
        local v754

        if y == 0 then
            buffer.writef32(v1, 0, y)
            v754 = buffer.readu32(v1, 0)
        elseif y > -1.1754943508222875E-38 and y < 1.1754943508222875E-38 then
            local v755 = math.abs(y) * 7.1362384635298E+44

            v754 = math.floor(v755)

            local v756 = v755 - v754

            if v756 > 0.5 or v756 == 0.5 and v754 % 2 == 1 then
                v754 += 1
            end

            if y < 0 then
                v754 += 2147483648
            end
        else
            buffer.writef32(v1, 0, y)
            v754 = buffer.readu32(v1, 0)
        end

        v745[v753] = v754

        local v757 = v747 + 3
        local z = v748.z
        local v758

        if z == 0 then
            buffer.writef32(v1, 0, z)
            v758 = buffer.readu32(v1, 0)
        elseif z > -1.1754943508222875E-38 and z < 1.1754943508222875E-38 then
            local v759 = math.abs(z) * 7.1362384635298E+44

            v758 = math.floor(v759)

            local v760 = v759 - v758

            if v760 > 0.5 or v760 == 0.5 and v758 % 2 == 1 then
                v758 += 1
            end

            if z < 0 then
                v758 += 2147483648
            end
        else
            buffer.writef32(v1, 0, z)
            v758 = buffer.readu32(v1, 0)
        end

        v745[v757] = v758
    end

    v745[4] = CollisionBody.contact_id(p93)
    v745[8] = 4294967295

    local restitution = p94.restitution
    local v761

    if restitution ~= 0 and restitution > -1.1754943508222875E-38 and restitution < 1.1754943508222875E-38 then
        local v762 = math.abs(restitution) * 7.1362384635298E+44
        local v763 = math.floor(v762)
        local v764 = v762 - v763

        v761 = if v764 > 0.5 or v764 == 0.5 and v763 % 2 == 1 then v763 + 1 else v763

        if restitution < 0 then
            v761 += 2147483648
        end
    else
        buffer.writef32(v1, 0, restitution)
        v761 = buffer.readu32(v1, 0)
    end

    v745[12] = v761

    local static_friction = p94.static_friction
    local v765

    if static_friction ~= 0 and static_friction > -1.1754943508222875E-38 and static_friction < 1.1754943508222875E-38 then
        local v766 = math.abs(static_friction) * 7.1362384635298E+44
        local v767 = math.floor(v766)
        local v768 = v766 - v767

        v765 = if v768 > 0.5 or v768 == 0.5 and v767 % 2 == 1 then v767 + 1 else v767

        if static_friction < 0 then
            v765 += 2147483648
        end
    else
        buffer.writef32(v1, 0, static_friction)
        v765 = buffer.readu32(v1, 0)
    end

    v745[16] = v765

    local dynamic_friction = p94.dynamic_friction
    local v769

    if dynamic_friction ~= 0 and dynamic_friction > -1.1754943508222875E-38 and dynamic_friction < 1.1754943508222875E-38 then
        local v770 = math.abs(dynamic_friction) * 7.1362384635298E+44
        local v771 = math.floor(v770)
        local v772 = v770 - v771

        v769 = if v772 > 0.5 or v772 == 0.5 and v771 % 2 == 1 then v771 + 1 else v771

        if dynamic_friction < 0 then
            v769 += 2147483648
        end
    else
        buffer.writef32(v1, 0, dynamic_friction)
        v769 = buffer.readu32(v1, 0)
    end

    v745[20] = v769
    v745[24] = p94.tag

    return v745
end

function t1.collision_from_record_reference(p95) -- line: 2447
    -- upvalues: v1 (copy), Vector3 (copy), CollisionBody (copy)
    local function f(p96) -- line: 2448
        -- upvalues: p95 (copy), v1 (copy)
        buffer.writeu32(v1, 0, p95[p96 + 1])

        return (buffer.readf32(v1, 0))
    end

    local function vector(p97) -- line: 2451
        -- upvalues: p95 (copy), v1 (copy), Vector3 (copy)
        local new = Vector3.new

        buffer.writeu32(v1, 0, p95[p97 + 1])

        local v775 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, p95[p97 + 1 + 1])

        local v778 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, p95[p97 + 2 + 1])

        return new(v775, v778, (buffer.readf32(v1, 0)))
    end

    local t49 = {
        body_a = CollisionBody.from_contact_id(p95[4]),
        body_b = {
            tag = "StaticWorld"
        }
    }
    local t50 = {}
    local new = Vector3.new

    buffer.writeu32(v1, 0, p95[1])

    local v782 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p95[2])

    local v784 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p95[3])
    t50.position_on_a = new(v782, v784, (buffer.readf32(v1, 0)))

    local new2 = Vector3.new

    buffer.writeu32(v1, 0, p95[5])

    local v787 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p95[6])

    local v789 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p95[7])
    t50.position_on_b = new2(v787, v789, (buffer.readf32(v1, 0)))

    local new3 = Vector3.new

    buffer.writeu32(v1, 0, p95[9])

    local v792 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p95[10])

    local v794 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p95[11])
    t50.normal = new3(v792, v794, (buffer.readf32(v1, 0)))
    buffer.writeu32(v1, 0, p95[12])
    t50.restitution = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, p95[16])
    t50.static_friction = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, p95[20])
    t50.dynamic_friction = buffer.readf32(v1, 0)
    t50.tag = p95[24]
    t49.contact = t50

    return t49
end

function collision_from_record(p98) -- line: 2473
    -- upvalues: CollisionBody (copy), v49 (copy)
    local t51 = {
        body_a = CollisionBody.from_contact_id(p98[4]),
        body_b = {
            tag = "StaticWorld"
        }
    }
    local t52 = {}
    local t53 = {}

    buffer.writeu32(v49, 0, p98[1])
    t53.x = buffer.readf32(v49, 0)
    buffer.writeu32(v49, 0, p98[2])
    t53.y = buffer.readf32(v49, 0)
    buffer.writeu32(v49, 0, p98[3])
    t53.z = buffer.readf32(v49, 0)
    t52.position_on_a = t53

    local t54 = {}

    buffer.writeu32(v49, 0, p98[5])
    t54.x = buffer.readf32(v49, 0)
    buffer.writeu32(v49, 0, p98[6])
    t54.y = buffer.readf32(v49, 0)
    buffer.writeu32(v49, 0, p98[7])
    t54.z = buffer.readf32(v49, 0)
    t52.position_on_b = t54

    local t55 = {}

    buffer.writeu32(v49, 0, p98[9])
    t55.x = buffer.readf32(v49, 0)
    buffer.writeu32(v49, 0, p98[10])
    t55.y = buffer.readf32(v49, 0)
    buffer.writeu32(v49, 0, p98[11])
    t55.z = buffer.readf32(v49, 0)
    t52.normal = t55
    buffer.writeu32(v49, 0, p98[12])
    t52.restitution = buffer.readf32(v49, 0)
    buffer.writeu32(v49, 0, p98[16])
    t52.static_friction = buffer.readf32(v49, 0)
    buffer.writeu32(v49, 0, p98[20])
    t52.dynamic_friction = buffer.readf32(v49, 0)
    t52.tag = p98[24]
    t51.contact = t52

    return t51
end

t1.collision_from_record = collision_from_record

return t1
