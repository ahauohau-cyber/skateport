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
local v1 = import("skate_dynamics/model")
local v2 = import("skate_dynamics/solid")
local t1 = {}

local function not_ported() -- line: 38
    error("skate_dynamics: Rapier query not ported", 0)
end

t1.ModelColliderOptions = v1.ModelColliderOptions
t1.BodyDefinition = v2.BodyDefinition
t1.SolidBody = v2.SolidBody
t1.SolidCollider = v2.SolidCollider

local function all_finite(p2) -- line: 50
    for _, v3 in ipairs(p2) do
        if v3 ~= v3 or v3 == 1e999 or v3 == (-1e999) then
            return false
        end
    end

    return true
end

local function sorted_keys(p3) -- line: 59
    local t2 = {}

    for v4 in p3 do
        table.insert(t2, v4)
    end

    table.sort(t2)

    return t2
end

local function u64_to_decimal(p4) -- line: 69
    if type(p4) == "number" then
        return string.format("%d", p4)
    end

    local v5 = string.match(p4, "^0[xX](%x+)$")

    if v5 == nil then
        return (tostring(p4))
    end

    local v7 = string.rep("0", (math.max(0, 16 - #v5))) .. v5
    local v10 = tonumber(string.sub(v7, 1, #v7 - 8), 16)
    local v13 = tonumber(string.sub(v7, #v7 - 7), 16)

    if v10 == 0 and v13 == 0 then
        return "0"
    end

    local t3 = {}

    while true do
        local v14, v15, v16, v17, v18, v19

        if v10 > 0 then
            v14 = v10 % 10
            v15 = v10 / 10
            v10 = math.floor(v15)
            v16 = v14 * 4294967296 + v13
            v17 = v16 / 10
            v13 = math.floor(v17)
            v18 = v16 % 10 + 48
            v19 = string.char(v18)
            table.insert(t3, 1, v19)
            continue
        end

        if v13 > 0 then
            v14 = v10 % 10
            v15 = v10 / 10
            v10 = math.floor(v15)
            v16 = v14 * 4294967296 + v13
            v17 = v16 / 10
            v13 = math.floor(v17)
            v18 = v16 % 10 + 48
            v19 = string.char(v18)
            table.insert(t3, 1, v19)
            continue
        end

        break
    end

    return table.concat(t3)
end

local function deep_eq(p5, p6) -- line: 95
    -- upvalues: deep_eq (copy)
    if type(p5) ~= "table" or type(p6) ~= "table" then
        return p5 == p6
    end

    for v20, v21 in p5 do
        if not deep_eq(v21, p6[v20]) then
            return false
        end
    end

    for v22 in p6 do
        if p5[v22] == nil then
            return false
        end
    end

    return true
end

t1.Shape = {}

function t1.Shape.eq(p7, p8) -- line: 125
    -- upvalues: deep_eq (copy)
    return (deep_eq(p7, p8))
end

t1.BodyType = {}
t1.BodyDesc = {}

function t1.one_mass() -- line: 150
    return 1
end

function t1.one_friction() -- line: 153
    return 0.7
end

function t1.default_group() -- line: 156
    return 1
end

function t1.default_filter() -- line: 159
    return 65535
end

function t1.default_lin_damp() -- line: 162
    return 0.2
end

function t1.default_ang_damp() -- line: 165
    return 0.5
end

function t1.BodyDesc.default() -- line: 169
    return {
        deformation = nil,
        body_type = "Dynamic",
        mass = 1,
        heading = 0,
        friction = 0.7,
        ccd = false,
        sensor = false,
        membership = 1,
        filter = 65535,
        contact_group = 0,
        inertia_half_extents = nil,
        linear_damping = 0.2,
        angular_damping = 0.5,
        shape = {
            tag = "Box",
            half_extents = { 0.5, 0.5, 0.5 }
        },
        position = { 0, 0, 0 },
        center_of_mass = { 0, 0, 0 },
        collider_offset = { 0, 0, 0 }
    }
end

t1.SpringRayDesc = {}

function t1.neg_y() -- line: 204
    return { 0, -1, 0 }
end

function t1.default_max_suspension_force() -- line: 207
    return 6000
end

t1.SpringRayHit = {}
t1.ExtraHull = {}
t1.BodySnapshot = {}
t1.GROUND_BODY_ID = "0x0000000000000000"
t1.RayHit = {}
t1.ContactEvent = {}
t1.ExportedShape = {}
t1.ExportedVolume = {}
t1.MAX_EXPORT_TRIANGLES = 512
t1.BodyMeta = {}
t1.RevoluteJointDesc = {}

function t1.axis_y() -- line: 264
    return { 0, 1, 0 }
end

function t1.true_fn() -- line: 267
    return true
end

t1.JointMotorDesc = {}
t1.PrismaticJointDesc = {}
t1.JointSpringDesc = {}

function t1.one_factor() -- line: 288
    return 1
end

t1.JointKind = {}
t1.DynamicsWorld = {}

local DynamicsWorld = t1.DynamicsWorld

function t1.DynamicsWorld.default() -- line: 314
    return {
        next = 1,
        next_joint = 1,
        ground = false,
        deformations = {},
        gravity = {
            x = 0,
            y = -9.81,
            z = 0
        },
        ids = {},
        reverse = {},
        joints = {},
        joint_kinds = {},
        contacts = {},
        prev_pairs = {},
        meta = {},
        kinematic_motion = {}
    }
end

function t1.DynamicsWorld.has_ground(p9) -- line: 332
    return p9.ground
end

function t1.DynamicsWorld.set_ground(_, p11) -- line: 338
    -- upvalues: not_ported (copy)
    if #p11 == 0 then
        error("dynamics ground has no triangles", 0)
    end

    return not_ported()
end

function t1.DynamicsWorld.spawn(p12, p13) -- line: 348
    -- upvalues: not_ported (copy), DynamicsWorld (copy)
    DynamicsWorld.validate(p12, p13)

    if p13.deformation == nil then
        DynamicsWorld.collider(p12, p13)
    end

    return not_ported()
end

function t1.DynamicsWorld.remove(p14, p15) -- line: 358
    -- upvalues: not_ported (copy)
    if p14.ids[p15] == nil then
        return false
    end

    return not_ported()
end

function t1.DynamicsWorld.add_convex_collider(p16, p17, p18, p19, p20) -- line: 367
    -- upvalues: not_ported (copy)
    if p16.ids[p17] == nil then
        error("unknown body", 0)
    end

    local v23 = p16.meta[p17]
    local v24 = v23 == nil or #v23.extra_hulls >= 16

    if not v24 then
        for _, v25 in ipairs(p19) do
            if v25 ~= v25 or v25 == 1e999 or v25 == (-1e999) or math.abs(v25) > 100 then
                v24 = true
                break
            end
        end
    end

    if not v24 then
        local v26 = v24

        for _, v27 in ipairs(p18) do
            for _, v28 in ipairs(v27) do
                if v28 ~= v28 or v28 == 1e999 or v28 == (-1e999) or math.abs(v28) > 1000 then
                    v26 = true
                    break
                end
            end

            if v26 then
                v24 = v26
                break
            end

            v24 = v26
        end
    end

    if v24 then
        error("extra collider exceeds finite geometry/body limits", 0)
    end

    if #p18 < 4 or #p18 > 512 then
        error("convex needs 4..=512 points", 0)
    end

    if p20 ~= p20 or p20 == 1e999 or p20 == (-1e999) or not (p20 >= 0) or not (p20 <= 2) then
        error("friction must be in 0..2", 0)
    end

    return not_ported()
end

function t1.DynamicsWorld.set_collision_mesh(p21, p22, p23) -- line: 408
    local v29 = p21.meta[p22]

    if v29 == nil then
        return false
    end

    for _, v30 in ipairs(p23) do
        for _, v31 in ipairs(v30) do
            local v32 = false
            local v33

            for _, v34 in ipairs(v31) do
                if v34 ~= v34 or v34 == 1e999 or v34 == (-1e999) then
                    v33 = false
                    v32 = true
                    break
                end
            end

            if not v32 then
                v33 = true
            end

            if not v33 then
                return false
            end
        end
    end

    if #p23 == 0 then
        v29.mesh = nil
    else
        v29.mesh = p23
    end

    return true
end

function t1.DynamicsWorld.upsert_kinematic_proxy(p24, p25, p26, p27, p28, p29) -- line: 427
    -- upvalues: rt (copy), v2 (copy), t1 (copy), DynamicsWorld (copy)
    local v35 = t1.BodyDesc.default()

    v35.shape = rt.copy(p26)
    v35.body_type = "Kinematic"
    v35.mass = 1
    v35.position = p27
    v35.friction = p29
    v35.membership = v2.PLAYER_MEMBERSHIP
    v35.filter = 4294967295
    DynamicsWorld.validate(p24, v35)

    local v36

    if p25 ~= nil then
        local v37 = p24.meta[p25]

        if v37 ~= nil and t1.Shape.eq(v37.shape, p26) and v37.friction == p29 then
            v36 = p25
        end
    end

    if v36 == nil then
        if p25 ~= nil then
            DynamicsWorld.remove(p24, p25)
        end

        v36 = DynamicsWorld.spawn(p24, v35)
    end

    if not DynamicsWorld.set_pose(p24, v36, p27, p28) then
        error("invalid kinematic proxy pose", 0)
    end

    return v36
end

function t1.DynamicsWorld.export_boardworld_volumes(p30) -- line: 462
    -- upvalues: not_ported (copy)
    if next(p30.meta) == nil then
        return {}
    end

    return not_ported()
end

function t1.DynamicsWorld.convex_hull_volume(_, p32, p33, p34, p35, p36, p37) -- line: 472
    -- upvalues: rt (copy), t1 (copy)
    local v38 = t1.hull_triangles(p35, p36, t1.MAX_EXPORT_TRIANGLES)

    return if v38 ~= nil then {
        body = p32,
        position = rt.copy(p34.position),
        rotation = rt.copy(p34.rotation),
        linvel = rt.copy(p34.linvel),
        angvel = rt.copy(p34.angvel),
        mass = p33.mass,
        friction = p37,
        shape = {
            tag = "Triangles",
            tris = v38
        }
    } else nil
end

function t1.DynamicsWorld.overlaps_shapes(p38, p39, _) -- line: 492
    -- upvalues: not_ported (copy)
    if p38.ids[p39] == nil then
        return false
    end

    return not_ported()
end

function t1.DynamicsWorld.read(p41, p42) -- line: 500
    -- upvalues: not_ported (copy)
    if p41.ids[p42] == nil then
        return nil
    end

    return not_ported()
end

function t1.DynamicsWorld.begin_force_frame(p43) -- line: 509
    -- upvalues: DynamicsWorld (copy)
    for _, v39 in p43.meta do
        v39.commanded_force = { 0, 0, 0 }
        v39.commanded_torque = { 0, 0, 0 }
    end

    DynamicsWorld.clear_user_forces(p43)
end

function t1.DynamicsWorld.set_pose(p44, p45, p46, p47) -- line: 518
    -- upvalues: not_ported (copy)
    if p44.ids[p45] == nil then
        return false
    end

    local v40 = false
    local v41

    for _, v42 in ipairs(p46) do
        if v42 ~= v42 or v42 == 1e999 or v42 == (-1e999) then
            v41 = false
            v40 = true
            break
        end
    end

    if not v40 then
        v41 = true
    end

    if v41 then
        local v43 = false
        local v44

        for _, v45 in ipairs(p47) do
            if v45 ~= v45 or v45 == 1e999 or v45 == (-1e999) then
                v44 = false
                v43 = true
                break
            end
        end

        if not v43 then
            v44 = true
        end

        if v44 then
            if p47[1] * p47[1] + p47[2] * p47[2] + p47[3] * p47[3] + p47[4] * p47[4] < 1E-08 then
                return false
            end

            return not_ported()
        end
    end

    return false
end

function t1.DynamicsWorld.apply_force(p48, p49, _, _) -- line: 536
    -- upvalues: not_ported (copy)
    if p48.ids[p49] == nil then
        return false
    end

    return not_ported()
end

function t1.DynamicsWorld.apply_impulse(p52, p53, _, _) -- line: 544
    -- upvalues: not_ported (copy)
    if p52.ids[p53] == nil then
        return false
    end

    return not_ported()
end

function t1.DynamicsWorld.apply_torque(p56, p57, _) -- line: 552
    -- upvalues: not_ported (copy)
    if p56.ids[p57] == nil then
        return false
    end

    return not_ported()
end

function t1.DynamicsWorld.apply_torque_impulse(p59, p60, _) -- line: 560
    -- upvalues: not_ported (copy)
    if p59.ids[p60] == nil then
        return false
    end

    return not_ported()
end

function t1.DynamicsWorld.set_linvel(p62, p63, _) -- line: 568
    -- upvalues: not_ported (copy)
    if p62.ids[p63] == nil then
        return false
    end

    return not_ported()
end

function t1.DynamicsWorld.set_angvel(p65, p66, _) -- line: 576
    -- upvalues: not_ported (copy)
    if p65.ids[p66] == nil then
        return false
    end

    return not_ported()
end

local function joint_checks(p68, p69, p70) -- line: 584
    -- upvalues: u64_to_decimal (copy)
    if p68.ids[p69.body_a] == nil then
        error("unknown body " .. u64_to_decimal(p69.body_a), 0)
    end

    if p68.ids[p69.body_b] == nil then
        error("unknown body " .. u64_to_decimal(p69.body_b), 0)
    end

    if p69.body_a == p69.body_b then
        error("joint bodies must differ", 0)
    end

    if not (math.sqrt(p69.axis[1] * p69.axis[1] + p69.axis[2] * p69.axis[2] + p69.axis[3] * p69.axis[3]) > 1E-06) then
        error("joint axis must be non-zero", 0)
    end

    if p69.limits == nil then
        return
    end

    local v47 = p69.limits[1]
    local v48 = p69.limits[2]

    if v47 ~= v47
        or v47 == 1e999
        or v47 == (-1e999)
        or v48 ~= v48
        or v48 == 1e999
        or v48 == (-1e999)
        or v48 < v47 then
        error(p70, 0)
    end
end

function t1.DynamicsWorld.add_revolute_joint(p71, p72) -- line: 608
    -- upvalues: not_ported (copy), joint_checks (copy)
    joint_checks(p71, p72, "invalid revolute limits")

    return not_ported()
end

function t1.DynamicsWorld.add_prismatic_joint(p73, p74) -- line: 615
    -- upvalues: not_ported (copy), joint_checks (copy)
    joint_checks(p73, p74, "invalid prismatic limits")

    return not_ported()
end

function t1.DynamicsWorld.set_joint_motor(p75, p76, _) -- line: 621
    -- upvalues: not_ported (copy)
    if p75.joint_kinds[p76] ~= "Revolute" or p75.joints[p76] == nil then
        return false
    end

    return not_ported()
end

function t1.DynamicsWorld.revolute_angle(p78, p79) -- line: 632
    -- upvalues: not_ported (copy)
    if p78.joint_kinds[p79] ~= "Revolute" or p78.joints[p79] == nil then
        return nil
    end

    return not_ported()
end

function t1.DynamicsWorld.set_joint_spring(p80, p81, _) -- line: 643
    -- upvalues: not_ported (copy)
    if p80.joint_kinds[p81] ~= "Prismatic" or p80.joints[p81] == nil then
        return false
    end

    return not_ported()
end

function t1.DynamicsWorld.remove_joint(p83, p84) -- line: 654
    -- upvalues: not_ported (copy)
    if p83.joints[p84] == nil then
        return false
    end

    return not_ported()
end

function t1.DynamicsWorld.raycast(p85, p86, p87, p88) -- line: 662
    -- upvalues: DynamicsWorld (copy)
    return DynamicsWorld.raycast_excluding(p85, p86, p87, p88, nil)
end

function t1.DynamicsWorld.raycast_excluding(p89, _, p91, p92, _) -- line: 668
    -- upvalues: not_ported (copy)
    if math.sqrt(p91[1] * p91[1] + p91[2] * p91[2] + p91[3] * p91[3]) > 1E-06 and p92 == p92 and p92 ~= 1e999 and p92 ~= (-1e999) and not (p92 <= 0) then
        if next(p89.ids) == nil then
            return nil
        end

        return not_ported()
    end

    return nil
end

function t1.DynamicsWorld.spring_raycast_excluding(p94, _, p96, p97, _) -- line: 681
    -- upvalues: not_ported (copy)
    if math.sqrt(p96[1] * p96[1] + p96[2] * p96[2] + p96[3] * p96[3]) > 1E-06 and p97 == p97 and p97 ~= 1e999 and p97 ~= (-1e999) and not (p97 <= 0) then
        if next(p94.ids) == nil then
            return nil
        end

        return not_ported()
    end

    return nil
end

function t1.DynamicsWorld.velocity_at(p99, p100, _) -- line: 693
    -- upvalues: not_ported (copy)
    if p99.ids[p100] == nil then
        return nil
    end

    return not_ported()
end

function t1.DynamicsWorld.effective_inv_mass(p102, p103, _, _) -- line: 702
    -- upvalues: not_ported (copy)
    if p102.ids[p103] == nil then
        return nil
    end

    return not_ported()
end

function t1.DynamicsWorld.local_ang_accel_impulse(p106, p107, p108, p109) -- line: 712
    -- upvalues: not_ported (copy)
    if p109 ~= p109 or p109 == 1e999 or p109 == (-1e999) or not (p109 > 0) then
        return nil
    end

    local v51 = false
    local v52

    for _, v53 in ipairs(p108) do
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
        if p106.ids[p107] == nil then
            return nil
        end

        return not_ported()
    end

    return nil
end

function t1.DynamicsWorld.spring_ray(p110, p111, p112) -- line: 725
    -- upvalues: not_ported (copy)
    local dt = p112.dt

    if dt == dt and dt ~= 1e999 and dt ~= (-1e999) and p112.dt > 0 then
        local rest_length = p112.rest_length

        if rest_length == rest_length and rest_length ~= 1e999 and rest_length ~= (-1e999) and p112.rest_length > 0 then
            local max_travel = p112.max_travel

            if max_travel == max_travel and max_travel ~= 1e999 and max_travel ~= (-1e999) and p112.max_travel >= 0 then
                local contact_radius = p112.contact_radius

                if contact_radius == contact_radius and contact_radius ~= 1e999 and contact_radius ~= (-1e999) and p112.contact_radius >= 0 then
                    local stiffness = p112.stiffness

                    if stiffness == stiffness and stiffness ~= 1e999 and stiffness ~= (-1e999) and p112.stiffness > 0 then
                        local compression = p112.compression

                        if compression == compression and compression ~= 1e999 and compression ~= (-1e999) and p112.compression >= 0 then
                            local relaxation = p112.relaxation

                            if relaxation == relaxation and relaxation ~= 1e999 and relaxation ~= (-1e999) and p112.relaxation >= 0 then
                                local max_force = p112.max_force

                                if max_force == max_force and max_force ~= 1e999 and max_force ~= (-1e999) and p112.max_force > 0 then
                                    if p110.ids[p111] == nil then
                                        return nil
                                    end

                                    return not_ported()
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    return nil
end

function t1.DynamicsWorld.drain_contacts(p113) -- line: 745
    local contacts = p113.contacts

    p113.contacts = {}

    return contacts
end

function t1.DynamicsWorld.active_contact_pairs(p114) -- line: 753
    -- upvalues: rt (copy)
    return rt.copy(p114.prev_pairs)
end

function t1.DynamicsWorld.raycast_ground(p115, _, _, _) -- line: 759
    -- upvalues: t1 (copy), not_ported (copy)
    if p115.ids[t1.GROUND_BODY_ID] == nil then
        return nil
    end

    return not_ported()
end

function t1.DynamicsWorld.raycast_excluding_bodies(p119, p120, p121, p122, p123) -- line: 768
    -- upvalues: DynamicsWorld (copy)
    if #p123 == 0 then
        return DynamicsWorld.raycast(p119, p120, p121, p122)
    end

    local v55 = math.sqrt(p121[1] * p121[1] + p121[2] * p121[2] + p121[3] * p121[3])

    if v55 > 1E-06 and p122 == p122 and p122 ~= 1e999 and p122 ~= (-1e999) and not (p122 <= 0) then
        local t4 = {
            p121[1] / v55,
            p121[2] / v55,
            p121[3] / v55
        }
        local t5 = {
            p120[1],
            p120[2],
            p120[3]
        }
        local v56 = p122

        for _ = 0, 15 do
            local v57 = DynamicsWorld.raycast(p119, t5, t4, v56)

            if v57 == nil then
                return nil
            end

            if table.find(p123, v57.body) == nil then
                return v57
            end

            local v58 = v57.toi + 0.15

            if v56 - 1E-04 <= v58 then
                return nil
            end

            v56 -= v58
            t5 = {
                v57.point[1] + t4[1] * 0.15,
                v57.point[2] + t4[2] * 0.15,
                v57.point[3] + t4[3] * 0.15
            }
        end

        return nil
    end

    return nil
end

function t1.DynamicsWorld.step(p124, p125) -- line: 804
    -- upvalues: rt (copy), not_ported (copy), DynamicsWorld (copy)
    if not (p125 == p125 and p125 ~= 1e999 and p125 ~= (-1e999) and p125 > 0) then
        return
    end

    if next(p124.ids) ~= nil then
        return not_ported()
    end

    local v61 = math.clamp(rt.f_to_usize((math.ceil(p125 / 0.008334))), 1, 16)
    local v62 = p125 / v61

    for _ = 0, v61 - 1 do
        DynamicsWorld.advance_kinematic_targets(p124, v62)
    end

    DynamicsWorld.clear_user_forces(p124)
    DynamicsWorld.collect_contacts(p124)
end

function t1.DynamicsWorld.clear_user_forces(p126) -- line: 825
    if next(p126.ids) ~= nil then
        error("skate_dynamics: Rapier query not ported", 0)
    end
end

function t1.DynamicsWorld.iter_ids(p127) -- line: 832
    local t6 = {}

    for v63 in p127.ids do
        table.insert(t6, v63)
    end

    table.sort(t6)

    return t6
end

function t1.DynamicsWorld.collect_contacts(p128) -- line: 839
    -- upvalues: not_ported (copy)
    if next(p128.ids) ~= nil then
        return not_ported()
    end

    local t7 = {}

    for _, v64 in ipairs(p128.prev_pairs) do
        table.insert(p128.contacts, {
            started = false,
            body_a = v64[1],
            body_b = v64[2]
        })
    end

    p128.prev_pairs = t7
end

function t1.DynamicsWorld.validate(_, p130) -- line: 855
    -- upvalues: v1 (copy)
    if p130.contact_group > 20 then
        error("contact_group must be in 0..=20", 0)
    end

    local mass = p130.mass

    if not (mass == mass and mass ~= 1e999 and mass ~= (-1e999)) or p130.mass <= 0 then
        error("mass must be finite and > 0", 0)
    end

    local friction = p130.friction

    if friction ~= friction or friction == 1e999 or friction == (-1e999) or not (p130.friction >= 0) or not (p130.friction <= 2) then
        error("friction must be in 0..2", 0)
    end

    local heading = p130.heading

    if heading ~= heading or heading == 1e999 or heading == (-1e999) then
        error("heading must be finite", 0)
    end

    local linear_damping = p130.linear_damping
    local v65

    if linear_damping ~= linear_damping or linear_damping == 1e999 or linear_damping == (-1e999) or p130.linear_damping < 0 then
        v65 = false
    else
        local angular_damping = p130.angular_damping

        v65 = angular_damping == angular_damping and angular_damping ~= 1e999 and angular_damping ~= (-1e999) and not (p130.angular_damping < 0)
    end

    if not v65 then
        error("damping must be finite and >= 0", 0)
    end

    for _, v66 in ipairs(p130.center_of_mass) do
        if v66 ~= v66 or v66 == 1e999 or v66 == (-1e999) or math.abs(v66) > 10 then
            error("center_of_mass out of range", 0)
        end
    end

    for _, v67 in ipairs(p130.collider_offset) do
        if v67 ~= v67 or v67 == 1e999 or v67 == (-1e999) or math.abs(v67) > 10 then
            error("collider_offset out of range", 0)
        end
    end

    if p130.inertia_half_extents ~= nil then
        for _, v68 in ipairs(p130.inertia_half_extents) do
            if v68 ~= v68 or v68 == 1e999 or v68 == (-1e999) or v68 <= 0 or v68 > 10 then
                error("inertia_half_extents invalid", 0)
            end
        end
    end

    for _, v69 in ipairs(p130.position) do
        if v69 ~= v69 or v69 == 1e999 or v69 == (-1e999) or math.abs(v69) > 1E+05 then
            error("position out of range", 0)
        end
    end

    local shape = p130.shape

    if shape.tag == "Box" then
        for _, v70 in ipairs(shape.half_extents) do
            if v70 ~= v70 or v70 == 1e999 or v70 == (-1e999) or v70 <= 0 or v70 > 100 then
                error("box half_extents invalid", 0)
            end
        end
    elseif shape.tag == "Sphere" or shape.tag == "Capsule" then
        local radius = shape.radius

        if not (radius == radius and radius ~= 1e999 and radius ~= (-1e999)) or radius <= 0 or radius > 100 then
            error("radius invalid", 0)
        end
    elseif shape.tag == "Convex" then
        local points = shape.points

        if #points < 4 or #points > 512 then
            error("convex needs 4..=512 points", 0)
        end

        for _, v71 in ipairs(points) do
            for _, v72 in ipairs(v71) do
                if v72 ~= v72 or v72 == 1e999 or v72 == (-1e999) or math.abs(v72) > 1000 then
                    error("convex points invalid", 0)
                end
            end
        end
    elseif shape.tag == "Compound" then
        v1.validate_hulls(shape.hulls)
    elseif shape.tag == "Model" then
        v1.ModelColliderOptions.validate(shape.options)

        local path, object = shape.path, shape.object

        if path == ""
            or #path > 256
            or string.find(path, "..", 1, true) ~= nil
            or string.find(path, "\\", 1, true) ~= nil
            or string.find(path, ":", 1, true) ~= nil
            or #object > 120 then
            error("model path/object invalid", 0)
        end
    elseif shape.tag == "Mesh" then
        local path, object = shape.path, shape.object

        if path == ""
            or #path > 256
            or string.find(path, "..", 1, true) ~= nil
            or string.find(path, "\\", 1, true) ~= nil
            or object == ""
            or #object > 120 then
            error("mesh path/object invalid", 0)
        end
    end

    if shape.tag == "Capsule" then
        local half_height = shape.half_height

        if half_height ~= half_height or half_height == 1e999 or half_height == (-1e999) or half_height <= 0 or half_height > 100 then
            error("capsule half_height invalid", 0)
        end
    end
end

function t1.DynamicsWorld.collider(_, p132) -- line: 960
    -- upvalues: not_ported (copy)
    local tag = p132.shape.tag

    if tag == "Mesh" or tag == "Model" then
        error("model/mesh shape must be resolved by the host before spawn", 0)
    end

    return not_ported()
end

for v73, v74 in v2.DynamicsWorld do
    t1.DynamicsWorld[v73] = v74
end

function t1.DynamicsWorld.deformation(p133, p134) -- line: 975
    local v75 = p133.deformations[p134]

    return if v75 ~= nil then v75.field else nil
end

function t1.DynamicsWorld.collider_offset(p135, p136) -- line: 983
    -- upvalues: rt (copy)
    local v76 = p135.meta[p136]

    if v76 == nil then
        return nil
    end

    return rt.copy(v76.collider_offset)
end

function t1.hull_triangles(p137, _, _) -- line: 996
    -- upvalues: not_ported (copy)
    if #p137 < 4 then
        return nil
    end

    for _, v77 in ipairs(p137) do
        local v78 = false
        local v79

        for _, v80 in ipairs(v77) do
            if v80 ~= v80 or v80 == 1e999 or v80 == (-1e999) then
                v79 = false
                v78 = true
                break
            end
        end

        if not v78 then
            v79 = true
        end

        if not v79 then
            return nil
        end
    end

    return not_ported()
end

function t1.inertia_half_from_shape(p140) -- line: 1009
    -- upvalues: rt (copy)
    if p140.tag == "Box" then
        return rt.copy(p140.half_extents)
    end

    if p140.tag == "Sphere" then
        return {
            p140.radius,
            p140.radius,
            p140.radius
        }
    end

    if p140.tag == "Capsule" then
        return {
            p140.radius,
            p140.half_height + p140.radius,
            p140.radius
        }
    end

    if p140.tag == "Convex" then
        local t9 = {
            rt.F32_MAX,
            rt.F32_MAX,
            rt.F32_MAX
        }
        local t10 = {
            -rt.F32_MAX,
            -rt.F32_MAX,
            -rt.F32_MAX
        }

        for _, v81 in ipairs(p140.points) do
            for i = 0, 2 do
                t9[i + 1] = rt.fmin(t9[i + 1], v81[i + 1])
                t10[i + 1] = rt.fmax(t10[i + 1], v81[i + 1])
            end
        end

        return {
            rt.fmax((t10[1] - t9[1]) * 0.5, 0.05),
            rt.fmax((t10[2] - t9[2]) * 0.5, 0.05),
            rt.fmax((t10[3] - t9[3]) * 0.5, 0.05)
        }
    end

    if p140.tag ~= "Compound" then
        return { 0.5, 0.5, 0.5 }
    end

    local t11 = {
        rt.F32_MAX,
        rt.F32_MAX,
        rt.F32_MAX
    }
    local t12 = {
        -rt.F32_MAX,
        -rt.F32_MAX,
        -rt.F32_MAX
    }

    for _, v82 in ipairs(p140.hulls) do
        for _, v83 in ipairs(v82) do
            for j = 0, 2 do
                t11[j + 1] = rt.fmin(t11[j + 1], v83[j + 1])
                t12[j + 1] = rt.fmax(t12[j + 1], v83[j + 1])
            end
        end
    end

    return {
        rt.fmax((t12[1] - t11[1]) * 0.5, 0.001),
        rt.fmax((t12[2] - t11[2]) * 0.5, 0.001),
        rt.fmax((t12[3] - t11[3]) * 0.5, 0.001)
    }
end

return t1
