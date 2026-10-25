-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

local function rtl_is_finite(p1) -- line: 6
    if p1 ~= p1 or p1 == 1e999 then
        return false
    end

    return p1 ~= (-1e999)
end

local import = require(sim.import)

local function parent() -- line: 34
    -- upvalues: import (copy)
    return import("skate_dynamics")
end

local t1 = {}

local function not_ported() -- line: 40
    error("skate_dynamics: Rapier query not ported", 0)
end

local function all_finite(p2) -- line: 44
    for _, v1 in ipairs(p2) do
        if v1 ~= v1 or v1 == 1e999 or v1 == (-1e999) then
            return false
        end
    end

    return true
end

local function glam_is_finite3(p3) -- line: 54
    local x = p3.x
    local v2 = x == x and x ~= 1e999 and x ~= (-1e999)

    if not v2 then
        return v2
    end

    local y = p3.y
    local v3 = y == y and y ~= 1e999 and y ~= (-1e999)

    if not v3 then
        return v3
    end

    local z = p3.z

    if z ~= z or z == 1e999 then
        return false
    end

    return z ~= (-1e999)
end

local function glam_is_finite4(p4) -- line: 57
    local x = p4.x
    local v4 = x == x and x ~= 1e999 and x ~= (-1e999)

    if not v4 then
        return v4
    end

    local y = p4.y
    local v5 = y == y and y ~= 1e999 and y ~= (-1e999)

    if not v5 then
        return v5
    end

    local z = p4.z
    local v6 = z == z and z ~= 1e999 and z ~= (-1e999)

    if not v6 then
        return v6
    end

    local w = p4.w

    if w ~= w or w == 1e999 then
        return false
    end

    return w ~= (-1e999)
end

local function glam_length_squared(p5) -- line: 60
    return p5.x * p5.x + p5.y * p5.y + p5.z * p5.z
end

local function glam_normalize(p6) -- line: 64
    local v8 = 1 / math.sqrt(p6.x * p6.x + p6.y * p6.y + p6.z * p6.z)

    return {
        x = p6.x * v8,
        y = p6.y * v8,
        z = p6.z * v8
    }
end

local function glam_quat_mul_vec3(p7, p8) -- line: 69
    local v9 = p7.x * p7.x + p7.y * p7.y + p7.z * p7.z
    local v10 = (p8.x * p7.x + p8.y * p7.y + p8.z * p7.z) * 2
    local v11 = p7.w * p7.w - v9
    local v12 = p7.w * 2

    return {
        x = p8.x * v11 + p7.x * v10 + (p7.y * p8.z - p8.y * p7.z) * v12,
        y = p8.y * v11 + p7.y * v10 + (p7.z * p8.x - p8.z * p7.x) * v12,
        z = p8.z * v11 + p7.z * v10 + (p7.x * p8.y - p8.x * p7.y) * v12
    }
end

local function glam_quat_mul(p9, p10) -- line: 81
    return {
        x = p9.w * p10.x + p9.x * p10.w + p9.y * p10.z - p9.z * p10.y,
        y = p9.w * p10.y - p9.x * p10.z + p9.y * p10.w + p9.z * p10.x,
        z = p9.w * p10.z + p9.x * p10.y - p9.y * p10.x + p9.z * p10.w,
        w = p9.w * p10.w - p9.x * p10.x - p9.y * p10.y - p9.z * p10.z
    }
end

local function pose_mul(p11, p12) -- line: 90
    -- upvalues: glam_quat_mul_vec3 (copy), glam_quat_mul (copy)
    local v13 = glam_quat_mul_vec3(p11.rotation, p12.translation)

    return {
        translation = {
            x = p11.translation.x + v13.x,
            y = p11.translation.y + v13.y,
            z = p11.translation.z + v13.z
        },
        rotation = glam_quat_mul(p11.rotation, p12.rotation)
    }
end

t1.PLAYER_MEMBERSHIP = 2
t1.ExtraColliderDefinition = {}
t1.BodyDefinition = {}
t1.SolidCollider = {}
t1.SolidBody = {}
t1.SolidContact = {}

function t1.SolidBody.contact(_, _, _, _, _, _, _, p20, p21) -- line: 143
    -- upvalues: not_ported (copy)
    if p20 == p20 and p20 ~= 1e999 and p20 ~= (-1e999) and p20 > 0 and p21 == p21 and p21 ~= 1e999 and p21 ~= (-1e999) and p21 >= 0 then
        return not_ported()
    end

    return nil
end

function t1.collect_solid_parts(p22, p23, p24, p25) -- line: 151
    -- upvalues: rt (copy), t1 (copy), pose_mul (copy)
    if p22.tag == "compound" then
        for _, v14 in ipairs(p22.shapes) do
            local v15 = v14[1]
            local v16 = v14[2]

            t1.collect_solid_parts(v16, pose_mul(p23, v15), p24, p25)
        end
    else
        table.insert(p25, {
            shape = rt.copy(p22),
            pose = p23,
            friction = p24
        })
    end
end

function t1.valid_contact(p26) -- line: 163
    local point_a = p26.point_a
    local x = point_a.x
    local v17 = x == x and x ~= 1e999 and x ~= (-1e999)
    local v18

    if v17 then
        local y = point_a.y
        local v19 = y == y and y ~= 1e999 and y ~= (-1e999)

        if v19 then
            local z = point_a.z

            v18 = z == z and z ~= 1e999 and z ~= (-1e999)
        else
            v18 = v19
        end
    else
        v18 = v17
    end

    if v18 then
        local point_b = p26.point_b
        local x = point_b.x
        local v20 = x == x and x ~= 1e999 and x ~= (-1e999)
        local v21

        if v20 then
            local y = point_b.y
            local v22 = y == y and y ~= 1e999 and y ~= (-1e999)

            if v22 then
                local z = point_b.z

                v21 = z == z and z ~= 1e999 and z ~= (-1e999)
            else
                v21 = v22
            end
        else
            v21 = v20
        end

        if v21 then
            local normal = p26.normal
            local x = normal.x
            local v23 = x == x and x ~= 1e999 and x ~= (-1e999)
            local v24

            if v23 then
                local y = normal.y
                local v25 = y == y and y ~= 1e999 and y ~= (-1e999)

                if v25 then
                    local z = normal.z

                    v24 = z == z and z ~= 1e999 and z ~= (-1e999)
                else
                    v24 = v25
                end
            else
                v24 = v23
            end

            if v24 then
                local distance = p26.distance

                if distance == distance and distance ~= 1e999 and distance ~= (-1e999) then
                    local normal = p26.normal

                    if not (normal.x * normal.x + normal.y * normal.y + normal.z * normal.z < 0.5) then
                        local normal = p26.normal
                        local v27 = 1 / math.sqrt(normal.x * normal.x + normal.y * normal.y + normal.z * normal.z)

                        p26.normal = {
                            x = normal.x * v27,
                            y = normal.y * v27,
                            z = normal.z * v27
                        }

                        return p26
                    end
                end
            end
        end
    end

    return nil
end

t1.DynamicsWorld = {}

function t1.DynamicsWorld.local_center(p27, p28) -- line: 181
    -- upvalues: not_ported (copy)
    if p27.ids[p28] == nil then
        return nil
    end

    return not_ported()
end

function t1.DynamicsWorld.definition_revision(p29, p30) -- line: 189
    local v28 = p29.meta[p30]

    return if v28 ~= nil then v28.geometry_revision * 17 + #v28.extra_hulls else nil
end

function t1.DynamicsWorld.body_definition(p31, p32) -- line: 200
    -- upvalues: rt (copy)
    local v29 = p31.meta[p32]

    if v29 == nil then
        return nil
    end

    local v30 = rt.copy(v29.definition)

    v30.position = { 0, 0, 0 }
    v30.heading = 0

    local t3 = {}

    for _, v31 in ipairs(v29.extra_hulls) do
        table.insert(t3, {
            points = rt.copy(v31.points),
            translation = rt.copy(v31.translation),
            friction = v31.friction
        })
    end

    local v32 = p31.deformations[p32]

    return {
        deformation = if v32 == nil then nil else rt.copy(v32.field),
        body = v30,
        extras = t3
    }
end

function t1.DynamicsWorld.spawn_replica(p33, p34) -- line: 227
    -- upvalues: rt (copy), import (copy), not_ported (copy)
    local tag = p34.body.shape.tag

    if #p34.extras > 16 or tag == "Mesh" or tag == "Model" then
        error("unsupported or oversized replica definition", 0)
    end

    if p34.deformation == nil then
        if p34.body.deformation ~= nil then
            error("replica deformation configuration/field mismatch", 0)
        end

        local v33 = rt.copy(p34.body)

        v33.deformation = nil
        v33.body_type = "Dynamic"
        import("skate_dynamics").DynamicsWorld.spawn(p33, v33)
    end

    return not_ported()
end

function t1.DynamicsWorld.upsert_actor_shadow(_, _, p37, p38, p39, p40, p41, p42) -- line: 256
    -- upvalues: not_ported (copy)
    local v34 = #p42 == 0 or #p42 > 32 or not (p38 == p38 and p38 ~= 1e999 and p38 ~= (-1e999)) or p38 < 0

    if not v34 then
        for _, v35 in ipairs(p39) do
            if v35 ~= v35 or v35 == 1e999 or v35 == (-1e999) or v35 < 0 then
                v34 = true
                break
            end
        end
    end

    if not v34 then
        local translation = p37.translation
        local x = translation.x
        local v36 = x == x and x ~= 1e999 and x ~= (-1e999)
        local v37

        if v36 then
            local y = translation.y
            local v38 = y == y and y ~= 1e999 and y ~= (-1e999)

            if v38 then
                local z = translation.z

                v37 = z == z and z ~= 1e999 and z ~= (-1e999)
            else
                v37 = v38
            end
        else
            v37 = v36
        end

        local v39 = not v37
        local v40

        if v39 then
            v40 = v39
        else
            local rotation = p37.rotation
            local x = rotation.x
            local v41 = x == x and x ~= 1e999 and x ~= (-1e999)
            local v42

            if v41 then
                local y = rotation.y
                local v43 = y == y and y ~= 1e999 and y ~= (-1e999)

                if v43 then
                    local z = rotation.z
                    local v44 = z == z and z ~= 1e999 and z ~= (-1e999)

                    if v44 then
                        local w = rotation.w

                        v42 = w == w and w ~= 1e999 and w ~= (-1e999)
                    else
                        v42 = v44
                    end
                else
                    v42 = v43
                end
            else
                v42 = v41
            end

            v40 = not v42

            if not v40 then
                local v45 = false
                local v46

                for _, v47 in ipairs(p40) do
                    if v47 ~= v47 or v47 == 1e999 or v47 == (-1e999) then
                        v46 = false
                        v45 = true
                        break
                    end
                end

                if not v45 then
                    v46 = true
                end

                v40 = not v46

                if not v40 then
                    local v48 = false
                    local v49

                    for _, v50 in ipairs(p41) do
                        if v50 ~= v50 or v50 == 1e999 or v50 == (-1e999) then
                            v49 = false
                            v48 = true
                            break
                        end
                    end

                    if not v48 then
                        v49 = true
                    end

                    v40 = not v49
                end
            end
        end

        v34 = v40
    end

    if v34 then
        error("invalid native actor shadow", 0)
    end

    return not_ported()
end

function t1.DynamicsWorld.solid_bodies(p43) -- line: 282
    -- upvalues: not_ported (copy)
    if next(p43.meta) == nil then
        return {}
    end

    return not_ported()
end

function t1.DynamicsWorld.add_velocity_delta(p44, p45, p46, p47) -- line: 292
    -- upvalues: not_ported (copy)
    local v51 = false
    local v52

    for _, v53 in ipairs(p46) do
        if v53 ~= v53 or v53 == 1e999 or v53 == (-1e999) then
            v52 = false
            v51 = true
            break
        end
    end

    if not v51 then
        v52 = true
    end

    if v52 then
        local v54 = false
        local v55

        for _, v56 in ipairs(p47) do
            if v56 ~= v56 or v56 == 1e999 or v56 == (-1e999) then
                v55 = false
                v54 = true
                break
            end
        end

        if not v54 then
            v55 = true
        end

        if v55 then
            if p44.ids[p45] == nil then
                return false
            end

            return not_ported()
        end
    end

    return false
end

function t1.DynamicsWorld.correct_pose(p48, p49, p50, p51) -- line: 305
    local v57 = false
    local v58

    for _, v59 in ipairs(p50) do
        if v59 ~= v59 or v59 == 1e999 or v59 == (-1e999) then
            v58 = false
            v57 = true
            break
        end
    end

    if not v57 then
        v58 = true
    end

    if not v58 then
        return
    end

    local v60 = false
    local v61

    for _, v62 in ipairs(p51) do
        if v62 ~= v62 or v62 == 1e999 or v62 == (-1e999) then
            v61 = false
            v60 = true
            break
        end
    end

    if not v60 then
        v61 = true
    end

    if v61 and p48.ids[p49] ~= nil then
        error("skate_dynamics: Rapier query not ported", 0)
    end
end

function t1.DynamicsWorld.set_kinematic_motion(p52, p53, p54, p55) -- line: 319
    local v63 = false
    local v64

    for _, v65 in ipairs(p54) do
        if v65 ~= v65 or v65 == 1e999 or v65 == (-1e999) then
            v64 = false
            v63 = true
            break
        end
    end

    if not v63 then
        v64 = true
    end

    if not v64 then
        return
    end

    local v66 = false
    local v67

    for _, v68 in ipairs(p55) do
        if v68 ~= v68 or v68 == 1e999 or v68 == (-1e999) then
            v67 = false
            v66 = true
            break
        end
    end

    if not v66 then
        v67 = true
    end

    if v67 and p52.ids[p53] ~= nil then
        error("skate_dynamics: Rapier query not ported", 0)
    end
end

function t1.DynamicsWorld.advance_kinematic_targets(p56, _) -- line: 330
    for v69 in p56.kinematic_motion do
        if p56.ids[v69] ~= nil then
            error("skate_dynamics: Rapier query not ported", 0)
        end
    end
end

function t1.DynamicsWorld.capsule_clear(p58, p59, p60, p61, p62, p63) -- line: 341
    -- upvalues: not_ported (copy)
    if not (p61 * 2 <= p60) or not (p61 > 0) or not (p62 >= 0) then
        return false
    end

    local v70 = false
    local v71

    for _, v72 in ipairs(p59) do
        if v72 ~= v72 or v72 == 1e999 or v72 == (-1e999) then
            v71 = false
            v70 = true
            break
        end
    end

    if not v70 then
        v71 = true
    end

    if v71 then
        for v73 in p58.ids do
            if table.find(p63, v73) == nil then
                return not_ported()
            end
        end

        return true
    end

    return false
end

function t1.sweep_sphere(p64, p65, p66, p67) -- line: 359
    -- upvalues: not_ported (copy)
    local t6 = {
        p66[1] - p65[1],
        p66[2] - p65[2],
        p66[3] - p65[3]
    }
    local v74 = false
    local v75

    for _, v76 in ipairs(p65) do
        if v76 ~= v76 or v76 == 1e999 or v76 == (-1e999) then
            v75 = false
            v74 = true
            break
        end
    end

    if not v74 then
        v75 = true
    end

    if v75 then
        local v77 = false
        local v78

        for _, v79 in ipairs(t6) do
            if v79 ~= v79 or v79 == 1e999 or v79 == (-1e999) then
                v78 = false
                v77 = true
                break
            end
        end

        if not v77 then
            v78 = true
        end

        if v78 and p67 == p67 and p67 ~= 1e999 and p67 ~= (-1e999) and not (p67 < 0) then
            for _, v80 in ipairs(p64) do
                for _ in ipairs(v80.colliders) do
                    return not_ported()
                end
            end

            return nil
        end
    end

    return nil
end

function t1.collider_triangles(_) -- line: 376
    -- upvalues: not_ported (copy)
    return not_ported()
end

return t1
