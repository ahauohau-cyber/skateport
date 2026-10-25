-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local Vector3 = import("skate_core/math").Vector3
local BodyId = import("skate_core/physics/board").BodyId
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime
local transform_triangle_volume = import("skate_core/physics/world_contact").transform_triangle_volume
local capsule, compose
local t1 = {}

function t1.world_volumes_reference(p1, p2) -- line: 21
    -- upvalues: rt (copy), BodyId (copy), BoardRuntime (copy), transform_triangle_volume (copy), capsule (ref), compose (ref)
    local v1 = BoardRuntime.part_transforms(p1)
    local t2 = {}

    for _, v2 in BodyId.ORDER do
        local v3 = BoardRuntime.bodies(p1)[BodyId.index(v2) + 1]

        if v3.state_flags ~= 1 then
            local v4 = rt.copy(v1[BodyId.index(v2) + 1])

            local function add(p3, p4) -- line: 31
                -- upvalues: t2 (copy), v2 (copy), v3 (copy), rt (copy)
                table.insert(t2, {
                    body = {
                        tag = "Board",
                        v2
                    },
                    primitive = p3,
                    material = rt.copy(p4),
                    linear_velocity = rt.copy(v3.rates.linear_velocity)
                })
            end

            if v2 == BodyId.Deck then
                for _, v5 in p2.deck_geometry.children do
                    if v5.collision_enabled then
                        local v6 = compose(v4, v5.transform)
                        local shape = v5.shape
                        local v7

                        if shape.tag == "Sphere" then
                            v7 = {
                                tag = "Sphere",
                                {
                                    center = rt.copy(v6.translation),
                                    radius = shape.radius
                                }
                            }
                        elseif shape.tag == "Capsule" then
                            v7 = capsule(v6, shape.radius, shape.half_length)
                        elseif shape.tag == "RoundedBox" then
                            v7 = {
                                tag = "RoundedBox",
                                center = rt.copy(v6.translation),
                                basis = rt.copy(v6.basis),
                                half_extents = rt.copy(shape.half_extents),
                                radius = shape.radius
                            }
                        elseif shape.tag == "Triangle" then
                            v7 = {
                                tag = "Triangle",
                                (transform_triangle_volume(rt.copy(shape.vertices), shape.fatness, rt.copy(shape.edge_cosines), shape.volume_flags, rt.copy(v6.basis), rt.copy(v6.translation)))
                            }
                        else
                            error("unreachable: DeckShape " .. tostring(shape.tag), 0)
                        end

                        add(v7, p2.deck_material)
                    end
                end
            elseif v2 == BodyId.FrontTruck or v2 == BodyId.BackTruck then
                if p2.truck_collisions then
                    local truck_shape = p2.truck_shape

                    if truck_shape.tag ~= "Capsule" then
                        error("TU382C0A6F8 constructs a capsule for each truck", 0)
                    end

                    add(capsule(v4, truck_shape.radius, truck_shape.half_length), p2.truck_material)
                end
            else
                add({
                    tag = "Sphere",
                    {
                        center = rt.copy(v4.translation),
                        radius = p2.wheel_radius
                    }
                }, p2.wheel_material)
            end
        end
    end

    return t2
end

local function compose_scalar(p5, p6) -- line: 110
    -- upvalues: Vector3 (copy)
    local columns = p5.basis.columns
    local v8 = columns[1]
    local v9 = columns[2]
    local v10 = columns[3]
    local v11 = v8[1]
    local v12 = v8[2]
    local v13 = v8[3]
    local v14 = v9[1]
    local v15 = v9[2]
    local v16 = v9[3]
    local v17 = v10[1]
    local v18 = v10[2]
    local v19 = v10[3]
    local t4 = {}

    for v20, v21 in p6.basis.columns do
        local v22 = v21[1]
        local v23 = v21[2]
        local v24 = v21[3]

        t4[v20] = {
            v24 * v17 + (v23 * v14 + v22 * v11),
            v24 * v18 + (v23 * v15 + v22 * v12),
            v24 * v19 + (v23 * v16 + v22 * v13)
        }
    end

    local translation = p6.translation
    local translation2 = p5.translation
    local x, y, z = translation.x, translation.y, translation.z

    return {
        basis = {
            columns = t4
        },
        translation = Vector3.new(z * v17 + (y * v14 + (x * v11 + translation2.x)), z * v18 + (y * v15 + (x * v12 + translation2.y)), z * v19 + (y * v16 + (x * v13 + translation2.z)))
    }
end

t1.compose_scalar = compose_scalar

local function add_volume(p7, p8, p9, p10, p11) -- line: 142
    -- upvalues: rt (copy)
    table.insert(p7, {
        body = {
            tag = "Board",
            p8
        },
        primitive = p10,
        material = rt.copy(p11),
        linear_velocity = rt.copy(p9.rates.linear_velocity)
    })
end

function t1.world_volumes(p12, p13) -- line: 162
    -- upvalues: rt (copy), BodyId (copy), BoardRuntime (copy), transform_triangle_volume (copy), capsule (ref), compose_scalar (copy), add_volume (copy)
    local v25 = BoardRuntime.part_transforms(p12)
    local t6 = {}

    for _, v26 in BodyId.ORDER do
        local v27 = BoardRuntime.bodies(p12)[BodyId.index(v26) + 1]

        if v27.state_flags ~= 1 then
            local v28 = v25[BodyId.index(v26) + 1]

            if v26 == BodyId.Deck then
                for _, v29 in p13.deck_geometry.children do
                    if v29.collision_enabled then
                        local v30 = compose_scalar(v28, v29.transform)
                        local shape = v29.shape
                        local v31

                        if shape.tag == "Sphere" then
                            v31 = {
                                tag = "Sphere",
                                {
                                    center = v30.translation,
                                    radius = shape.radius
                                }
                            }
                        elseif shape.tag == "Capsule" then
                            v31 = capsule(v30, shape.radius, shape.half_length)
                        elseif shape.tag == "RoundedBox" then
                            v31 = {
                                tag = "RoundedBox",
                                center = v30.translation,
                                basis = v30.basis,
                                half_extents = rt.copy(shape.half_extents),
                                radius = shape.radius
                            }
                        elseif shape.tag == "Triangle" then
                            v31 = {
                                tag = "Triangle",
                                (transform_triangle_volume(shape.vertices, shape.fatness, shape.edge_cosines, shape.volume_flags, v30.basis, v30.translation))
                            }
                        else
                            error("unreachable: DeckShape " .. tostring(shape.tag), 0)
                        end

                        add_volume(t6, v26, v27, v31, p13.deck_material)
                    end
                end
            elseif v26 == BodyId.FrontTruck or v26 == BodyId.BackTruck then
                if p13.truck_collisions then
                    local truck_shape = p13.truck_shape

                    if truck_shape.tag ~= "Capsule" then
                        error("TU382C0A6F8 constructs a capsule for each truck", 0)
                    end

                    add_volume(t6, v26, v27, capsule(v28, truck_shape.radius, truck_shape.half_length), p13.truck_material)
                end
            else
                add_volume(t6, v26, v27, {
                    tag = "Sphere",
                    {
                        center = rt.copy(v28.translation),
                        radius = p13.wheel_radius
                    }
                }, p13.wheel_material)
            end
        end
    end

    return t6
end

local v32 = true

function t1.set_pooled(p14) -- line: 265
    -- upvalues: v32 (ref)
    local v33 = v32

    v32 = p14

    return v33
end

local transform_triangle_volume_into = import("skate_core/physics/world_contact/primitive_geometry").transform_triangle_volume_into
local t7 = {}
local v34
local v35 = false

function t1.set_b3_twin(p15) -- line: 276
    -- upvalues: v35 (ref)
    v35 = p15
end

local t8 = {}

local function assign_flat(p16, p17) -- line: 282
    -- upvalues: rt (copy)
    for v36, v37 in p17 do
        if type(v37) == "table" then
            p16[v36] = rt.copy(v37)
        else
            p16[v36] = v37
        end
    end

    for v38 in p16 do
        if p17[v38] == nil then
            p16[v38] = nil
        end
    end
end

local function pooled_volume(p18, p19, p20, p21) -- line: 293
    -- upvalues: t8 (copy), assign_flat (copy)
    local v39 = t8[p18]

    if v39 == nil then
        v39 = {
            primitive = false,
            body = {
                tag = "Board",
                p19
            },
            material = {},
            linear_velocity = {
                x = 0,
                y = 0,
                z = 0
            }
        }
        t8[p18] = v39
    end

    local body = v39.body

    body.tag = "Board"
    body[1] = p19
    assign_flat(v39.material, p21)

    local linear_velocity = p20.rates.linear_velocity
    local linear_velocity2 = v39.linear_velocity
    local x, y, z = linear_velocity.x, linear_velocity.y, linear_velocity.z

    linear_velocity2.x = x
    linear_velocity2.y = y
    linear_velocity2.z = z

    return v39
end

local function pooled_sphere(p22, p23, p24, p25, p26) -- line: 314
    local primitive = p22.primitive

    if not primitive or primitive.tag ~= "Sphere" then
        primitive = {
            tag = "Sphere",
            {
                radius = 0,
                center = {
                    x = 0,
                    y = 0,
                    z = 0
                }
            }
        }
        p22.primitive = primitive
    end

    local v40 = primitive[1]
    local center = v40.center

    center.x = p23
    center.y = p24
    center.z = p25
    v40.radius = p26
end

local function pooled_capsule(p27, p28, p29, p30, p31, p32, p33, p34, p35) -- line: 326
    local primitive = p27.primitive

    if not primitive or primitive.tag ~= "Capsule" then
        primitive = {
            tag = "Capsule",
            half_length = 0,
            radius = 0,
            center = {
                x = 0,
                y = 0,
                z = 0
            },
            axis = {
                x = 0,
                y = 0,
                z = 0
            }
        }
        p27.primitive = primitive
    end

    local center = primitive.center

    center.x = p28
    center.y = p29
    center.z = p30

    local axis = primitive.axis

    axis.x = p31
    axis.y = p32
    axis.z = p33
    primitive.half_length = p35
    primitive.radius = p34
end

function t1.world_volumes_pooled(p36, p37) -- line: 346
    -- upvalues: BodyId (copy), BoardRuntime (copy), t1 (copy), v32 (ref), transform_triangle_volume_into (copy), t7 (copy), v34 (ref), v35 (ref), assign_flat (copy), pooled_volume (copy), pooled_sphere (copy), pooled_capsule (copy)
    if not v32 then
        return t1.world_volumes(p36, p37)
    end

    local v41

    if v35 then
        v41 = BoardRuntime.part_transforms(p36)
    else
        local v42 = v34

        if v42 == nil then
            v42 = BoardRuntime.poses_scratch()
            v34 = v42
        end

        v41 = BoardRuntime.part_transforms_into(p36, v42)
    end

    local n1 = 0

    for _, v43 in BodyId.ORDER do
        local v44 = BoardRuntime.bodies(p36)[BodyId.index(v43) + 1]

        if v44.state_flags ~= 1 then
            local v45 = v41[BodyId.index(v43) + 1]

            if v43 == BodyId.Deck then
                local v46 = v45.basis.columns
                local v47 = v46[1]
                local v48 = v46[2]
                local transform = v46[3]
                local v49 = v47[1]
                local v50 = v47[2]
                local v51 = v47[3]
                local v52 = v48[1]
                local v53 = v48[2]
                local v54 = v48[3]
                local v55 = transform[1]
                local v56 = transform[2]
                local v57 = transform[3]

                transform = v45.translation

                local x, y, z = transform.x, transform.y, transform.z
                local v58 = n1

                for v59, v60 in p37.deck_geometry.children do
                    if v60.collision_enabled then
                        transform = v60.transform
                        v48 = transform.translation

                        local x2, tag, shape = v48.x, v48.y, v48.z

                        v48 = shape * v55 + (tag * v52 + (x2 * v49 + x))
                        v47 = shape * v56 + (tag * v53 + (x2 * v50 + y))
                        v46 = shape * v57 + (tag * v54 + (x2 * v51 + z))
                        shape = v60.shape
                        tag = shape.tag

                        local v61 = pooled_volume(64 + v59, v43, v44, p37.deck_material)

                        if tag == "Sphere" then
                            pooled_sphere(v61, v48, v47, v46, shape.radius)
                        elseif tag == "Capsule" then
                            local v62 = transform.basis.columns[3]
                            local v63 = v62[1]
                            local v64 = v62[2]
                            local v65 = v62[3]

                            pooled_capsule(v61, v48, v47, v46, v65 * v55 + (v64 * v52 + v63 * v49), v65 * v56 + (v64 * v53 + v63 * v50), v65 * v57 + (v64 * v54 + v63 * v51), shape.radius, shape.half_length)
                        elseif tag == "RoundedBox" or tag == "Triangle" then
                            local v66 = transform.basis.columns

                            if #v66 ~= 3 then
                                return t1.world_volumes(p36, p37)
                            end

                            local v67 = v66[1]
                            local v68 = v67[1]
                            local v69 = v67[2]
                            local primitive = v67[3]
                            local v70 = primitive * v55 + (v69 * v52 + v68 * v49)
                            local v71 = primitive * v56 + (v69 * v53 + v68 * v50)
                            local v72 = primitive * v57 + (v69 * v54 + v68 * v51)

                            v67 = v66[2]
                            v68 = v67[1]
                            v69 = v67[2]
                            primitive = v67[3]

                            local v73 = primitive * v55 + (v69 * v52 + v68 * v49)
                            local v74 = primitive * v56 + (v69 * v53 + v68 * v50)
                            local v75 = primitive * v57 + (v69 * v54 + v68 * v51)

                            v67 = v66[3]
                            v68 = v67[1]
                            v69 = v67[2]
                            primitive = v67[3]
                            v67 = primitive * v55 + (v69 * v52 + v68 * v49)
                            v66 = primitive * v56 + (v69 * v53 + v68 * v50)

                            local v76 = primitive * v57 + (v69 * v54 + v68 * v51)

                            primitive = v61.primitive

                            if tag == "RoundedBox" then
                                if not primitive or primitive.tag ~= "RoundedBox" then
                                    primitive = {
                                        tag = "RoundedBox",
                                        radius = 0
                                    }
                                    primitive.center = {
                                        x = 0,
                                        y = 0,
                                        z = 0
                                    }
                                    primitive.basis = {
                                        columns = {
                                            {
                                                0, 0, 0
                                            },
                                            {
                                                0, 0, 0
                                            },
                                            {
                                                0, 0, 0
                                            }
                                        }
                                    }
                                    primitive.half_extents = {}
                                    v61.primitive = primitive
                                end

                                v69 = primitive.center
                                v69.x = v48
                                v69.y = v47
                                v69.z = v46
                                v69 = primitive.basis.columns
                                v68 = v69[1]
                                v68[1] = v70
                                v68[2] = v71
                                v68[3] = v72
                                v68 = v69[2]
                                v68[1] = v73
                                v68[2] = v74
                                v68[3] = v75
                                v68 = v69[3]
                                v68[1] = v67
                                v68[2] = v66
                                v68[3] = v76
                                assign_flat(primitive.half_extents, shape.half_extents)
                                primitive.radius = shape.radius
                            else
                                if not primitive or primitive.tag ~= "Triangle" then
                                    primitive = {
                                        tag = "Triangle"
                                    }
                                    primitive[1] = {
                                        fatness = 0,
                                        vertices = {
                                            {
                                                x = 0,
                                                y = 0,
                                                z = 0
                                            },
                                            {
                                                x = 0,
                                                y = 0,
                                                z = 0
                                            },
                                            {
                                                x = 0,
                                                y = 0,
                                                z = 0
                                            }
                                        },
                                        feature = {
                                            flags = 0,
                                            normal = {
                                                x = 0,
                                                y = 0,
                                                z = 0
                                            },
                                            edges = {
                                                {
                                                    x = 0,
                                                    y = 0,
                                                    z = 0
                                                },
                                                {
                                                    x = 0,
                                                    y = 0,
                                                    z = 0
                                                },
                                                {
                                                    x = 0,
                                                    y = 0,
                                                    z = 0
                                                }
                                            },
                                            edge_cosines = {
                                                0, 0, 0
                                            }
                                        },
                                        edge_lengths = {
                                            0, 0, 0
                                        }
                                    }
                                    v61.primitive = primitive
                                end

                                transform_triangle_volume_into(primitive[1], shape.vertices, shape.fatness, shape.edge_cosines, shape.volume_flags, v70, v71, v72, v73, v74, v75, v67, v66, v76, v48, v47, v46)
                            end
                        else
                            error("unreachable: DeckShape " .. tostring(tag), 0)
                        end

                        v58 += 1
                        t7[v58] = v61
                    end

                    n1 = v58
                end
            elseif v43 == BodyId.FrontTruck or v43 == BodyId.BackTruck then
                local v77 = p37.truck_collisions

                if v77 then
                    v77 = p37.truck_shape

                    if v77.tag ~= "Capsule" then
                        error("TU382C0A6F8 constructs a capsule for each truck", 0)
                    end

                    local v78 = pooled_volume(BodyId.index(v43), v43, v44, p37.truck_material)
                    local translation = v45.translation
                    local transform = v45.basis.columns[3]

                    pooled_capsule(v78, translation.x, translation.y, translation.z, transform[1], transform[2], transform[3], v77.radius, v77.half_length)
                    n1 += 1
                    t7[n1] = v78
                end
            else
                local v79 = pooled_volume(BodyId.index(v43), v43, v44, p37.wheel_material)
                local translation = v45.translation

                pooled_sphere(v79, translation.x, translation.y, translation.z, p37.wheel_radius)
                n1 += 1
                t7[n1] = v79
            end
        end
    end

    for i = #t7, n1 + 1, -1 do
        t7[i] = nil
    end

    return t7
end

function capsule(p38, p39, p40) -- line: 524
    -- upvalues: rt (copy), Vector3 (copy)
    local v80 = p38.basis.columns[3]

    return {
        tag = "Capsule",
        center = rt.copy(p38.translation),
        axis = Vector3.new(v80[1], v80[2], v80[3]),
        half_length = p40,
        radius = p39
    }
end

t1.capsule = capsule

local function transform(p41, p42, p43) -- line: 537
    -- upvalues: Vector3 (copy)
    local t15 = {
        p43.x,
        p43.y,
        p43.z
    }

    local function component(p44) -- line: 539
        -- upvalues: p41 (copy), p42 (copy), t15 (copy)
        return p42.z * p41.columns[3][p44 + 1] + (p42.y * p41.columns[2][p44 + 1] + (p42.x * p41.columns[1][p44 + 1] + t15[p44 + 1]))
    end

    return Vector3.new(p42.z * p41.columns[3][1] + (p42.y * p41.columns[2][1] + (p42.x * p41.columns[1][1] + t15[1])), p42.z * p41.columns[3][2] + (p42.y * p41.columns[2][2] + (p42.x * p41.columns[1][2] + t15[2])), p42.z * p41.columns[3][3] + (p42.y * p41.columns[2][3] + (p42.x * p41.columns[1][3] + t15[3])))
end

t1.transform = transform

function compose(p45, p46) -- line: 547
    -- upvalues: transform (copy)
    local t16 = {}

    for v81, v82 in p46.basis.columns do
        t16[v81] = {
            v82[3] * p45.basis.columns[3][1] + (v82[2] * p45.basis.columns[2][1] + v82[1] * p45.basis.columns[1][1]),
            v82[3] * p45.basis.columns[3][2] + (v82[2] * p45.basis.columns[2][2] + v82[1] * p45.basis.columns[1][2]),
            v82[3] * p45.basis.columns[3][3] + (v82[2] * p45.basis.columns[2][3] + v82[1] * p45.basis.columns[1][3])
        }
    end

    return {
        basis = {
            columns = t16
        },
        translation = transform(p45.basis, p46.translation, p45.translation)
    }
end

t1.compose = compose

return t1
