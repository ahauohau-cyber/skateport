-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local Vector3 = import("skate_core/math").Vector3
local SkeletonBody = import("skate_core/physics/skeleton_body").SkeletonBody
local t1 = {}

function t1.world_volumes(p1, p2) -- line: 17
    -- upvalues: t1 (copy)
    local v1 = t1.enabled_volumes(p1, p2)

    t1.retain_world_volumes(v1, p2)

    return v1
end

function t1.retain_world_volumes(p3, p4) -- line: 26
    local v2 = #p3
    local n1 = 0

    for i = 1, v2 do
        local v3 = p3[i]
        local v4

        if v3.body.tag == "Attached" then
            local v5 = v3.body[1]

            v4 = p4.parts[v5 + 1].volume_group ~= 4
        else
            error("skeleton volumes must reference attached bodies", 0)
        end

        if v4 then
            n1 += 1
            p3[n1] = v3
        end
    end

    for i = v2, n1 + 1, -1 do
        p3[i] = nil
    end
end

function t1.enabled_volumes(p5, p6) -- line: 49
    -- upvalues: t1 (copy)
    return t1.volumes_with_parts(p5, p6.parts)
end

function t1.volumes_with_parts(p7, p8) -- line: 54
    -- upvalues: rt (copy), Vector3 (copy), SkeletonBody (copy)
    local v6 = SkeletonBody.part_transforms(p7)
    local t2 = {}
    local parts = p7.definition.parts

    for i = 0, math.min(#parts, #p8) - 1 do
        local v9 = parts[i + 1]
        local v10 = p8[i + 1]

        if v10.enabled then
            if v10.volume_group ~= 0 and v10.volume_group ~= 4 then
                error(string.format("Skater part%d requires volume group%d world filtering", i, v10.volume_group), 0)
            end

            if v9.hat ~= nil then
                error("The equipped hat requires its original cylinder collision query", 0)
            end

            local v11 = v6[i + 1]

            local function xyz(p9) -- line: 79
                -- upvalues: Vector3 (copy)
                return Vector3.new(p9[1], p9[2], p9[3])
            end

            local v12 = v11[4]
            local v13 = Vector3.new(v12[1], v12[2], v12[3])
            local shape = v9.shape
            local t3

            if shape.tag == "Sphere" then
                t3 = {
                    tag = "Sphere",
                    {
                        center = v13,
                        radius = shape.radius
                    }
                }
            elseif shape.tag == "Capsule" then
                t3 = {
                    tag = "Capsule",
                    center = v13
                }

                local v14 = v11[3]

                t3.axis = Vector3.new(v14[1], v14[2], v14[3])
                t3.half_length = shape.half_length
                t3.radius = shape.radius
            elseif shape.tag == "RoundedBox" then
                t3 = {
                    tag = "RoundedBox",
                    center = v13,
                    basis = {
                        columns = {
                            {
                                v11[1][1],
                                v11[1][2],
                                v11[1][3]
                            },
                            {
                                v11[2][1],
                                v11[2][2],
                                v11[2][3]
                            },
                            {
                                v11[3][1],
                                v11[3][2],
                                v11[3][3]
                            }
                        }
                    },
                    half_extents = rt.copy(shape.half_extents),
                    radius = shape.radius
                }
            else
                error(string.format("Skater part%d has no recovered collision query for %s", i, (tostring(shape.tag))), 0)
            end

            table.insert(t2, {
                body = {
                    tag = "Attached",
                    i
                },
                primitive = t3,
                linear_velocity = rt.copy(SkeletonBody.bodies(p7)[i + 1].rates.linear_velocity),
                material = rt.copy(v10.material)
            })
        end
    end

    return t2
end

local v15 = true

function t1.set_pooled(p10) -- line: 144
    -- upvalues: v15 (ref)
    local v16 = v15

    v15 = p10

    return v16
end

local t5 = {}
local t6 = {}
local v17

local function assign_flat(p11, p12) -- line: 153
    -- upvalues: rt (copy)
    for v18, v19 in p12 do
        if type(v19) == "table" then
            p11[v18] = rt.copy(v19)
        else
            p11[v18] = v19
        end
    end

    for v20 in p11 do
        if p12[v20] == nil then
            p11[v20] = nil
        end
    end
end

function t1.enabled_volumes_pooled(p13, p14) -- line: 164
    -- upvalues: SkeletonBody (copy), t1 (copy), v15 (ref), t5 (copy), t6 (copy), v17 (ref), assign_flat (copy)
    if not v15 then
        return t1.enabled_volumes(p13, p14)
    end

    local parts = p14.parts
    local v21 = v17

    if v21 == nil then
        v21 = SkeletonBody.pose_scratch()
        v17 = v21
    end

    local v22 = SkeletonBody.part_transforms_into(p13, v21)
    local parts2 = p13.definition.parts
    local v25 = math.min(#parts2, #parts) - 1
    local n2 = 0
    local v26

    for i = 0, v25 do
        local v27 = parts2[i + 1]
        local v28 = parts[i + 1]
        local v30
        local v29 = v26

        if v28.enabled then
            if v28.volume_group ~= 0 and v28.volume_group ~= 4 then
                error(string.format("Skater part%d requires volume group%d world filtering", i, v28.volume_group), 0)
            end

            if v27.hat ~= nil then
                error("The equipped hat requires its original cylinder collision query", 0)
            end

            local v31 = v22[i + 1]
            local v32 = v31[4]
            local v33 = t6[i + 1]

            if v33 == nil then
                v33 = {
                    primitive = false,
                    body = {
                        tag = "Attached",
                        i
                    },
                    linear_velocity = {
                        x = 0,
                        y = 0,
                        z = 0
                    },
                    material = {}
                }
                t6[i + 1] = v33
            end

            local primitive = v33.primitive
            local shape = v27.shape
            local tag = shape.tag

            if tag == "Sphere" then
                local v34

                if primitive and primitive.tag == "Sphere" then
                    v34 = primitive
                else
                    v34 = {
                        tag = "Sphere"
                    }
                    v34[1] = {
                        radius = 0,
                        center = {
                            x = 0,
                            y = 0,
                            z = 0
                        }
                    }
                    v33.primitive = v34
                end

                local v35 = v34[1]
                local center = v35.center
                local v36 = v32[1]
                local v37 = v32[2]
                local v38 = v32[3]

                center.x = v36
                center.y = v37
                center.z = v38
                v35.radius = shape.radius
            elseif tag == "Capsule" then
                local v39

                if primitive and primitive.tag == "Capsule" then
                    v39 = primitive
                else
                    v39 = {
                        tag = "Capsule",
                        half_length = 0,
                        radius = 0
                    }
                    v39.center = {
                        x = 0,
                        y = 0,
                        z = 0
                    }
                    v39.axis = {
                        x = 0,
                        y = 0,
                        z = 0
                    }
                    v33.primitive = v39
                end

                local center = v39.center
                local v40 = v32[1]
                local v41 = v32[2]
                local v42 = v32[3]

                center.x = v40
                center.y = v41
                center.z = v42

                local v43 = v31[3]
                local axis = v39.axis
                local v44 = v43[1]
                local v45 = v43[2]
                local v46 = v43[3]

                axis.x = v44
                axis.y = v45
                axis.z = v46
                v39.half_length = shape.half_length
                v39.radius = shape.radius
            elseif tag == "RoundedBox" then
                local v47

                if primitive and primitive.tag == "RoundedBox" then
                    v47 = primitive
                else
                    v47 = {
                        tag = "RoundedBox",
                        radius = 0
                    }
                    v47.center = {
                        x = 0,
                        y = 0,
                        z = 0
                    }
                    v47.basis = {
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
                    v47.half_extents = {}
                    v33.primitive = v47
                end

                local center = v47.center
                local v48 = v32[1]
                local v49 = v32[2]
                local v50 = v32[3]

                center.x = v48
                center.y = v49
                center.z = v50

                local columns = v47.basis.columns
                local v51 = v31[1]
                local v52 = columns[1]
                local v53 = v51[1]
                local v54 = v51[2]
                local v55 = v51[3]

                v52[1] = v53
                v52[2] = v54
                v52[3] = v55

                local v56 = v31[2]
                local v57 = columns[2]
                local v58 = v56[1]
                local v59 = v56[2]
                local v60 = v56[3]

                v57[1] = v58
                v57[2] = v59
                v57[3] = v60

                local v61 = v31[3]
                local v62 = columns[3]
                local v63 = v61[1]
                local v64 = v61[2]
                local v65 = v61[3]

                v62[1] = v63
                v62[2] = v64
                v62[3] = v65
                assign_flat(v47.half_extents, shape.half_extents)
                v47.radius = shape.radius
            else
                error(string.format("Skater part%d has no recovered collision query for %s", i, (tostring(tag))), 0)
            end

            local body = v33.body

            body.tag = "Attached"
            body[1] = i

            if v26 == nil then
                v29 = SkeletonBody.bodies(p13)
            end

            local linear_velocity = v29[i + 1].rates.linear_velocity
            local linear_velocity2 = v33.linear_velocity
            local x, y, z = linear_velocity.x, linear_velocity.y, linear_velocity.z

            linear_velocity2.x = x
            linear_velocity2.y = y
            linear_velocity2.z = z
            assign_flat(v33.material, v28.material)
            v30 = n2 + 1
            t5[v30] = v33
        else
            v30 = n2
        end

        v26 = v29
        n2 = v30
    end

    for i = #t5, n2 + 1, -1 do
        t5[i] = nil
    end

    return t5
end

return t1
