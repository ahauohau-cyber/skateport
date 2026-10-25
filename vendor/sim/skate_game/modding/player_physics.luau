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
local v8 = import("skate_core/trigonometry")
local Vector3 = import("skate_core/math").Vector3
local v9 = import("skate_core/physics/board")
local v10 = import("skate_core/physics/board_runtime")
local v11 = import("skate_core/physics/board_step")
local v12 = import("skate_core/physics/contact_feedback")
local v13 = import("skate_core/physics/contact_solver")
local v14 = import("skate_core/physics/skeleton_body")
local BodyId = v9.BodyId
local BoardRuntime = v10.BoardRuntime
local CollisionBody, ATTACHED_REACTION_BASE = v11.CollisionBody, v11.ATTACHED_REACTION_BASE
local RetailContactJacobian = v13.RetailContactJacobian
local SkeletonBody = v14.SkeletonBody

local function game_skeleton_body() -- line: 77
    -- upvalues: import (copy)
    return import("skate_game/physics/skeleton_body")
end

local v15 = false
local t1 = {
    set_b3_twin = function(p5) -- set_b3_twin | line: 86
        -- upvalues: v15 (ref)
        v15 = p5
    end
}

local function sorted_keys(p6) -- line: 91
    local t2 = {}

    for v16 in p6 do
        table.insert(t2, v16)
    end

    table.sort(t2)

    return t2
end

local function u64_to_decimal(p7) -- line: 101
    if type(p7) == "number" then
        return string.format("%d", p7)
    end

    local v17 = string.match(p7, "^0[xX](%x+)$")

    if v17 == nil then
        return (tostring(p7))
    end

    local v19 = string.rep("0", (math.max(0, 16 - #v17))) .. v17
    local v22 = tonumber(string.sub(v19, 1, #v19 - 8), 16)
    local v25 = tonumber(string.sub(v19, #v19 - 7), 16)

    if v22 == 0 and v25 == 0 then
        return "0"
    end

    local t3 = {}

    while true do
        local v26, v27, v28, v29, v30, v31

        if v22 > 0 then
            v26 = v22 % 10
            v27 = v22 / 10
            v22 = math.floor(v27)
            v28 = v26 * 4294967296 + v25
            v29 = v28 / 10
            v25 = math.floor(v29)
            v30 = v28 % 10 + 48
            v31 = string.char(v30)
            table.insert(t3, 1, v31)
            continue
        end

        if v25 > 0 then
            v26 = v22 % 10
            v27 = v22 / 10
            v22 = math.floor(v27)
            v28 = v26 * 4294967296 + v25
            v29 = v28 / 10
            v25 = math.floor(v29)
            v30 = v28 % 10 + 48
            v31 = string.char(v30)
            table.insert(t3, 1, v31)
            continue
        end

        break
    end

    return table.concat(t3)
end

local function glam_add(p8, p9) -- line: 127
    return {
        p8[1] + p9[1],
        p8[2] + p9[2],
        p8[3] + p9[3]
    }
end

local function glam_sub(p10, p11) -- line: 130
    return {
        p10[1] - p11[1],
        p10[2] - p11[2],
        p10[3] - p11[3]
    }
end

local function glam_scale(p12, p13) -- line: 133
    return {
        p12[1] * p13,
        p12[2] * p13,
        p12[3] * p13
    }
end

local function glam_dot(p14, p15) -- line: 136
    return p14[1] * p15[1] + p14[2] * p15[2] + p14[3] * p15[3]
end

local function glam_cross(p16, p17) -- line: 139
    return {
        p16[2] * p17[3] - p17[2] * p16[3],
        p16[3] * p17[1] - p17[3] * p16[1],
        p16[1] * p17[2] - p17[1] * p16[2]
    }
end

local function glam_is_finite(p18) -- line: 146
    local v32 = p18[1]
    local v33 = v32 == v32 and v32 ~= 1e999 and v32 ~= (-1e999)

    if not v33 then
        return v33
    end

    local v34 = p18[2]
    local v35 = v34 == v34 and v34 ~= 1e999 and v34 ~= (-1e999)

    if not v35 then
        return v35
    end

    local v36 = p18[3]

    if v36 ~= v36 or v36 == 1e999 then
        return false
    end

    return v36 ~= (-1e999)
end

local disabled_drives, part_name, body_value, arr, motion_flags

function t1.set(p19, p20, p21, p22) -- line: 155
    if #p19.skeleton_joints.records <= p21 then
        error("unknown native joint", 0)
    end

    local v37 = p19.mod_joint_overrides[p21]

    if v37 ~= nil and v37[1] ~= p20 then
        error("joint override is owned by another mod", 0)
    end

    if p22 ~= nil then
        p19.mod_joint_overrides[p21] = { p20, p22 }
    else
        p19.mod_joint_overrides[p21] = nil
    end
end

function t1.clear(p23, p24) -- line: 172
    -- upvalues: t1 (copy)
    if p23 == nil then
        return
    end

    for v38, v39 in p23.mod_part_overrides do
        if p24 == nil or v39[1] == p24 then
            p23.mod_part_overrides[v38] = nil
        end
    end

    for v40, v41 in p23.mod_joint_overrides do
        if p24 == nil or v41[1] == p24 then
            p23.mod_joint_overrides[v40] = nil
        end
    end

    if p24 == nil then
        p23.mod_contact_frame = t1.ContactFrame.default()
    end
end

function t1.apply(p25, p26, p27) -- line: 192
    -- upvalues: v1 (copy), v8 (copy)
    local words = p25.records[p26 + 1].parameters.words

    if p27.swing_limit ~= nil then
        local swing_limit = p27.swing_limit
        local v42

        if swing_limit == 0 then
            buffer.writef32(v1, 0, swing_limit)
            v42 = buffer.readu32(v1, 0)
        elseif swing_limit > -1.1754943508222875E-38 and swing_limit < 1.1754943508222875E-38 then
            local v43 = math.abs(swing_limit) * 7.1362384635298E+44

            v42 = math.floor(v43)

            local v44 = v43 - v42

            if v44 > 0.5 or v44 == 0.5 and v42 % 2 == 1 then
                v42 += 1
            end

            if swing_limit < 0 then
                v42 += 2147483648
            end
        else
            buffer.writef32(v1, 0, swing_limit)
            v42 = buffer.readu32(v1, 0)
        end

        words[11] = v42

        local v45 = v8.cos(swing_limit)
        local v46

        if v45 ~= 0 and v45 > -1.1754943508222875E-38 and v45 < 1.1754943508222875E-38 then
            local v47 = math.abs(v45) * 7.1362384635298E+44
            local v48 = math.floor(v47)
            local v49 = v47 - v48

            v46 = if v49 > 0.5 or v49 == 0.5 and v48 % 2 == 1 then v48 + 1 else v48

            if v45 < 0 then
                v46 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v45)
            v46 = buffer.readu32(v1, 0)
        end

        words[13] = v46
    end

    if p27.twist_limit ~= nil then
        local twist_limit = p27.twist_limit
        local v50

        if twist_limit == 0 then
            buffer.writef32(v1, 0, twist_limit)
            v50 = buffer.readu32(v1, 0)
        elseif twist_limit > -1.1754943508222875E-38 and twist_limit < 1.1754943508222875E-38 then
            local v51 = math.abs(twist_limit) * 7.1362384635298E+44

            v50 = math.floor(v51)

            local v52 = v51 - v50

            if v52 > 0.5 or v52 == 0.5 and v50 % 2 == 1 then
                v50 += 1
            end

            if twist_limit < 0 then
                v50 += 2147483648
            end
        else
            buffer.writef32(v1, 0, twist_limit)
            v50 = buffer.readu32(v1, 0)
        end

        words[12] = v50

        local v53 = v8.cos(twist_limit)
        local v54

        if v53 ~= 0 and v53 > -1.1754943508222875E-38 and v53 < 1.1754943508222875E-38 then
            local v55 = math.abs(v53) * 7.1362384635298E+44
            local v56 = math.floor(v55)
            local v57 = v55 - v56

            v54 = if v57 > 0.5 or v57 == 0.5 and v56 % 2 == 1 then v56 + 1 else v56

            if v53 < 0 then
                v54 += 2147483648
            end
        else
            buffer.writef32(v1, 0, v53)
            v54 = buffer.readu32(v1, 0)
        end

        words[14] = v54
    end

    if p27.free_swing ~= nil then
        words[15] = p27.free_swing and 4 or 1
    end

    if p27.free_twist ~= nil then
        words[16] = p27.free_twist and 2 or 1
    end
end

local apply = t1.apply

function t1.joints(p28) -- line: 214
    -- upvalues: rt (copy), apply (copy)
    local t4 = {
        records = rt.copy(p28.skeleton_joints.records)
    }
    local _ipairs = ipairs
    local t5 = {}

    for v58 in p28.mod_joint_overrides do
        table.insert(t5, v58)
    end

    table.sort(t5)

    for _, v59 in _ipairs(t5) do
        apply(t4, v59, p28.mod_joint_overrides[v59][2])
    end

    return t4
end

function t1.joints_view(p29) -- line: 229
    -- upvalues: t1 (copy)
    if next(p29.mod_joint_overrides) == nil then
        return {
            records = p29.skeleton_joints.records
        }
    end

    return t1.joints(p29)
end

function t1.filter_drives(p30, p31) -- line: 251
    -- upvalues: t1 (copy)
    if next(p30.mod_joint_overrides) == nil and next(p30.mod_part_overrides) == nil then
        local v60 = #p31.rows

        if #p31.identities == v60 and #p31.spy == v60 then
            return
        end
    end

    return t1.filter_drives_reference(p30, p31)
end

function t1.filter_drives_reference(p32, p33) -- line: 262
    -- upvalues: disabled_drives (ref)
    local v61 = disabled_drives(p32, false)
    local rows = p33.rows

    p33.rows = {}

    local identities = p33.identities

    p33.identities = {}

    local spy = p33.spy

    p33.spy = {}

    for i = 1, math.min(#rows, #identities, #spy) do
        local v65 = identities[i]

        if v65.tag ~= "Bone" or not v61[v65.part] then
            table.insert(p33.rows, rows[i])
            table.insert(p33.identities, v65)
            table.insert(p33.spy, spy[i])
        end
    end
end

function t1.body(p34, p35, p36) -- line: 285
    -- upvalues: BodyId (copy), BoardRuntime (copy), CollisionBody (copy), SkeletonBody (copy)
    local v68 = CollisionBody.from_contact_id(p34)

    if v68.tag == "Board" then
        return BoardRuntime.bodies(p35.board)[BodyId.index(v68[1]) + 1]
    end

    if v68.tag ~= "Attached" then
        return nil
    end

    local v69 = v68[1]
    local v70 = SkeletonBody.bodies(p36.skeleton)

    if v69 < #v70 then
        return v70[v69 + 1]
    end

    local v71 = v69 - #v70
    local bodies = p36.skeleton_drives.targets.bodies

    if v71 < #bodies then
        return bodies[v71 + 1]
    end

    local v72 = v71 - #bodies

    return p35.network_proxies.bodies[v72 + 1]
end

local body = t1.body

function t1.identity(p37, p38) -- line: 312
    -- upvalues: BodyId (copy), CollisionBody (copy), u64_to_decimal (copy)
    local v73, v74 = CollisionBody.decode_contact_id(p37)

    if v73 == 1 then
        return {
            kind = "board",
            index = BodyId.index(v74)
        }
    end

    if v73 ~= 2 then
        return {
            kind = "world"
        }
    end

    if v74 < 26 then
        return {
            kind = "skater",
            index = v74
        }
    end

    local v75 = p38.network_proxies.actors[v74]

    if v75 == nil then
        local v76

        for _, v77 in ipairs(p38.network_proxies.solids) do
            if v77[1] == v74 then
                v76 = u64_to_decimal(v77[2].id)
                break
            end
        end

        return {
            kind = "external",
            index = v74,
            solid_id = v76
        }
    end

    local v78 = v75[1]
    local v79 = v75[2]
    local t6 = {
        kind = "remote",
        index = v74,
        peer = u64_to_decimal(v78)
    }

    t6.part_kind = v79 < 7 and "board" or "skater"

    if not (v79 < 7) then
        v79 -= 7
    end

    t6.part = v79

    return t6
end

local identity = t1.identity

function t1.identity_reference(p39, p40) -- line: 351
    -- upvalues: BodyId (copy), CollisionBody (copy), u64_to_decimal (copy)
    local v80 = CollisionBody.from_contact_id(p39)

    if v80.tag == "Board" then
        return {
            kind = "board",
            index = BodyId.index(v80[1])
        }
    end

    if v80.tag ~= "Attached" then
        return {
            kind = "world"
        }
    end

    local v81 = v80[1]

    if v81 < 26 then
        return {
            kind = "skater",
            index = v81
        }
    end

    local v82 = p40.network_proxies.actors[v81]

    if v82 == nil then
        local v83

        for _, v84 in ipairs(p40.network_proxies.solids) do
            if v84[1] == v81 then
                v83 = u64_to_decimal(v84[2].id)
                break
            end
        end

        return {
            kind = "external",
            index = v81,
            solid_id = v83
        }
    end

    local v85 = v82[1]
    local v86 = v82[2]
    local t7 = {
        kind = "remote",
        index = v81,
        peer = u64_to_decimal(v85)
    }

    t7.part_kind = v86 < 7 and "board" or "skater"

    if not (v86 < 7) then
        v86 -= 7
    end

    t7.part = v86

    return t7
end

function t1.snapshot(p41, p42, p43) -- line: 389
    -- upvalues: rt (copy), v1 (copy), import (copy), BoardRuntime (copy), SkeletonBody (copy), t1 (copy), u64_to_decimal (copy), disabled_drives (ref), part_name (ref), body_value (ref), motion_flags (ref)
    local time_step = p41.settings.step.simulation.time_step
    local v87 = rt.copy(p42.mod_contact_frame.contacts)

    for _, v88 in ipairs(v87) do
        for _, v89 in ipairs({ "a", "b" }) do
            local v90 = v88[v89] and v88[v89].solid_id

            if type(v90) == "string" then
                for _, v91 in ipairs(p43.bodies) do
                    if u64_to_decimal(v91[2]) == v90 then
                        v88[v89].owner = v91[1][1]
                        v88[v89].key = v91[1][2]
                        break
                    end
                end
            end
        end
    end

    local v92 = disabled_drives(p42, false)
    local v93 = disabled_drives(p42, true)
    local JOINT_NAMES = import("skate_game/physics/skeleton_body").JOINT_NAMES
    local t8 = {}

    for v94, v95 in ipairs(t1.joints(p42).records) do
        local v96 = v94 - 1
        local words = v95.parameters.words
        local v97 = p42.mod_joint_overrides[v96]
        local t9 = {
            index = v96,
            name = JOINT_NAMES[v96 + 1],
            parent = v95.parent,
            child = v95.child
        }

        buffer.writeu32(v1, 0, words[11])
        t9.swing_limit = buffer.readf32(v1, 0)
        buffer.writeu32(v1, 0, words[12])
        t9.twist_limit = buffer.readf32(v1, 0)
        t9.free_swing = words[15] == 4
        t9.free_twist = words[16] == 2
        t9.enabled = not (v97 ~= nil and v97[2].enabled == false)
        t9.drive_enabled = not v92[v95.child]
        t9.possession_enabled = not v93[v95.child]
        t9.load = rt.copy(p42.mod_contact_frame.joint_loads[v96])
        t9.parameters = rt.copy(words)
        t9.frames = rt.copy(v95.frames.words)
        t9.override_owner = if v97 == nil then nil else v97[1]
        table.insert(t8, t9)
    end

    local t10 = {}

    for v100, v101 in ipairs(SkeletonBody.bodies(p42.skeleton)) do
        local v102 = v100 - 1
        local v103 = body_value("skater", v102, v101)
        local v104

        for v105, v106 in ipairs(p42.skeleton_joints.records) do
            if v106.child == v102 then
                v104 = v105 - 1
                break
            end
        end

        v103.joint = v104
        v103.name = part_name(v102, p42)

        local v107 = p42.mod_part_overrides[v102]

        if v107 ~= nil then
            v103.override = {
                owner = v107[1],
                options = rt.copy(v107[2])
            }
        else
            v103.override = nil
        end

        local v108 = if v107 == nil then nil else v107[2]
        local v109 = p42.skeleton_collision.parts[v102 + 1]
        local v110 = if v108 == nil then nil else v108.friction

        if v108 == nil or v108.motion == nil then
            v103.state_flags = v101.state_flags
        else
            v103.state_flags = motion_flags(v108.motion)
        end

        if v108 == nil or v108.collision == nil then
            v103.collision_enabled = v109.enabled
        else
            v103.collision_enabled = v108.collision
        end

        v103.animation_drives = not v92[v102]
        v103.possession_drives = not v93[v102]
        v103.material = {
            static_friction = if v110 == nil then v109.material.static_friction else v110,
            dynamic_friction = if v110 == nil then v109.material.dynamic_friction else v110
        }
        table.insert(t10, v103)
    end

    local t12 = {}

    for v111, v112 in ipairs(BoardRuntime.bodies(p41.board)) do
        local body_value2 = body_value

        table.insert(t12, body_value2("board", v111 - 1, v112))
    end

    return {
        tick = p42.mod_contact_frame.tick,
        dt = time_step,
        contacts = v87,
        contacts_truncated = p42.mod_contact_frame.truncated,
        joints = t8,
        parts = t10,
        board = t12,
        ragdoll = p42.skeleton_collision.is_ragdoll,
        partial_ragdoll = p42.skeleton_collision.partial_ragdoll
    }
end

function t1.selected_parts(p44, p45) -- line: 486
    local t13 = {}
    local _ipairs = ipairs
    local t14 = {}

    for v114 in p44.mod_joint_overrides do
        table.insert(t14, v114)
    end

    table.sort(t14)

    for _, v115 in _ipairs(t14) do
        local v116 = p44.mod_joint_overrides[v115][2]

        if p45(v116) then
            local t15 = {
                [p44.skeleton_joints.records[v115 + 1].child] = true
            }

            if v116.descendants then
                for _ = 0, 25 do
                    for _, v117 in ipairs(p44.skeleton_joints.records) do
                        if t15[v117.parent] then
                            t15[v117.child] = true
                        end
                    end
                end
            end

            for v118 in t15 do
                t13[v118] = true
            end
        end
    end

    return t13
end

local selected_parts2 = t1.selected_parts

function t1.disabled_drives(p46, p47) -- line: 512
    -- upvalues: selected_parts2 (copy)
    local v119 = selected_parts2(p46, function(p48) -- line: 513
        -- upvalues: p47 (copy)
        if p47 then
            return p48.possession_enabled == false
        end

        return p48.drive_enabled == false
    end)

    for v120, v121 in p46.mod_part_overrides do
        local v122 = v121[2]

        if if p47 then v122.possession_drives == false else v122.animation_drives == false then
            v119[v120] = true
        end
    end

    return v119
end

disabled_drives = t1.disabled_drives

function t1.filter_possession(p49, p50, p51) -- line: 537
    -- upvalues: t1 (copy)
    if next(p49.mod_joint_overrides) ~= nil or next(p49.mod_part_overrides) ~= nil then
        return t1.filter_possession_reference(p49, p50, p51)
    end
end

function t1.filter_possession_reference(p52, p53, p54) -- line: 545
    -- upvalues: ATTACHED_REACTION_BASE (copy), disabled_drives (ref)
    local v123 = disabled_drives(p52, true)
    local v124 = #p53
    local n1 = 0
    local n2 = 0

    for i = 1, v124 do
        local v125 = p53[i]
        local v126 = n1 < p54

        if not v126 then
            local v127 = false

            for _, v128 in ipairs({
                    v125.frame_a_body.reaction_index,
                    v125.frame_b_body.reaction_index
                }) do
                if ATTACHED_REACTION_BASE <= v128 and v123[v128 - ATTACHED_REACTION_BASE] then
                    v127 = true
                    break
                end
            end

            v126 = not v127
        end

        n1 += 1

        if v126 then
            n2 += 1
            p53[n2] = v125
        end
    end

    for i = v124, n2 + 1, -1 do
        p53[i] = nil
    end
end

function t1.filter_joints(p55, p56) -- line: 576
    -- upvalues: t1 (copy)
    if next(p55.mod_joint_overrides) == nil then
        return
    end

    return t1.filter_joints_reference(p55, p56)
end

function t1.filter_joints_reference(p57, p58) -- line: 584
    -- upvalues: ATTACHED_REACTION_BASE (copy)
    local t16 = {}

    for v129, v130 in p57.mod_joint_overrides do
        if v130[2].enabled == false then
            t16[p57.skeleton_joints.records[v129 + 1].child + ATTACHED_REACTION_BASE] = true
        end
    end

    local v131 = #p58
    local n3 = 0

    for i = 1, v131 do
        local v132 = p58[i]

        if not t16[v132.reaction_a] then
            n3 += 1
            p58[n3] = v132
        end
    end

    for i = v131, n3 + 1, -1 do
        p58[i] = nil
    end
end

function t1.part_name(p59, p60) -- line: 606
    local v133 = p60.animated_skeleton.bone_indices[p59 + 1]
    local v134 = v133 == nil
    local v135, v136

    if not v134 then
        v135 = p60.animation.evaluator.frames.bone_names[v133 + 1]
        v136 = v135 == nil
    end

    if v134 or v136 then
        return "PART_" .. tostring(p59)
    end

    return v135
end

part_name = t1.part_name

function t1.body_value(p61, p62, p63) -- line: 619
    -- upvalues: rt (copy), arr (ref)
    local orientation = p63.rates.orientation

    return {
        kind = p61,
        index = p62,
        position = arr(p63.rates.position),
        rotation = {
            orientation.x,
            orientation.y,
            orientation.z,
            orientation.w
        },
        velocity = arr(p63.rates.linear_velocity),
        angvel = arr(p63.rates.angular_velocity),
        inverse_mass = p63.inertia.inverse_mass,
        inverse_inertia = rt.copy(p63.rates.world_inverse_inertia.columns),
        state_flags = p63.state_flags
    }
end

body_value = t1.body_value

function t1.arr(p64) -- line: 636
    return {
        p64.x,
        p64.y,
        p64.z
    }
end

arr = t1.arr

function t1.vec(p65) -- line: 642
    -- upvalues: Vector3 (copy)
    return Vector3.new(p65[1], p65[2], p65[3])
end

local vec = t1.vec

function t1.point_velocity(p66, p67) -- line: 648
    -- upvalues: glam_cross (copy), arr (ref)
    if p66 == nil then
        return { 0, 0, 0 }
    end

    local v137 = arr(p66.rates.linear_velocity)
    local v138 = arr(p66.rates.angular_velocity)
    local v139 = arr(p66.rates.position)
    local v140 = glam_cross(v138, {
        p67[1] - v139[1],
        p67[2] - v139[2],
        p67[3] - v139[3]
    })

    return {
        v137[1] + v140[1],
        v137[2] + v140[2],
        v137[3] + v140[3]
    }
end

local point_velocity = t1.point_velocity

function t1.impulse(p68, p69, p70, p71, p72, p73) -- line: 662
    -- upvalues: BoardRuntime (copy), SkeletonBody (copy), glam_cross (copy), arr (ref), vec (copy)
    local function apply_impulse(p74, p75, p76, p77) -- line: 663
        -- upvalues: glam_cross (copy), arr (ref), vec (copy)
        if p74.inertia.inverse_mass <= 0 then
            error("native body has no dynamic mass", 0)
        end

        local t17 = {
            p75[1],
            p75[2],
            p75[3]
        }
        local v141

        if p77 then
            v141 = t17
        elseif p76 ~= nil then
            local v142 = arr(p74.rates.position)

            v141 = glam_cross({
                p76[1] - v142[1],
                p76[2] - v142[2],
                p76[3] - v142[3]
            }, t17)
        else
            v141 = { 0, 0, 0 }
        end

        local columns = p74.rates.world_inverse_inertia.columns
        local v143 = columns[1]
        local v144 = v141[1]
        local t18 = {
            v143[1] * v144,
            v143[2] * v144,
            v143[3] * v144
        }
        local v145 = columns[2]
        local v146 = v141[2]
        local t19 = {
            v145[1] * v146,
            v145[2] * v146,
            v145[3] * v146
        }
        local t20 = {
            t18[1] + t19[1],
            t18[2] + t19[2],
            t18[3] + t19[3]
        }
        local v147 = columns[3]
        local v148 = v141[3]
        local t21 = {
            v147[1] * v148,
            v147[2] * v148,
            v147[3] * v148
        }
        local t22 = {
            t20[1] + t21[1],
            t20[2] + t21[2],
            t20[3] + t21[3]
        }

        if not p77 then
            local rates = p74.rates
            local v149 = arr(p74.rates.linear_velocity)
            local inverse_mass = p74.inertia.inverse_mass
            local t23 = {
                t17[1] * inverse_mass,
                t17[2] * inverse_mass,
                t17[3] * inverse_mass
            }

            rates.linear_velocity = vec({
                v149[1] + t23[1],
                v149[2] + t23[2],
                v149[3] + t23[3]
            })
        end

        local rates = p74.rates
        local v150 = arr(p74.rates.angular_velocity)

        rates.angular_velocity = vec({
            v150[1] + t22[1],
            v150[2] + t22[2],
            v150[3] + t22[3]
        })
    end

    if p70.kind == "board" then
        local v151 = BoardRuntime.bodies_mut(p68.board)[p70.index + 1]

        if v151 == nil then
            error("index out of bounds", 0)
        end

        apply_impulse(v151, p71, p72, p73)
    else
        local v152 = SkeletonBody.bodies_mut(p69.skeleton)[p70.index + 1]

        if v152 == nil then
            error("index out of bounds", 0)
        end

        apply_impulse(v152, p71, p72, p73)
    end
end

t1.ContactFrame = {}

function t1.ContactFrame.default() -- line: 707
    return {
        tick = 0,
        truncated = false,
        contacts = {},
        joint_loads = {},
        pairs = {}
    }
end

function t1.before_solve(p78, p79) -- line: 718
    -- upvalues: rt (copy), BoardRuntime (copy), CollisionBody (copy), SkeletonBody (copy)
    local t24 = {}

    for v153, v154 in ipairs(BoardRuntime.bodies(p78.board)) do
        t24[v153 - 1] = rt.copy(v154)
    end

    local n4 = 0

    local function insert(p80) -- line: 724
        -- upvalues: t24 (copy), n4 (ref), rt (copy), CollisionBody (copy)
        t24[CollisionBody.contact_id({
            tag = "Attached",
            n4
        })] = rt.copy(p80)
        n4 += 1
    end

    for _, v155 in ipairs(SkeletonBody.bodies(p79.skeleton)) do
        t24[CollisionBody.contact_id({
            tag = "Attached",
            n4
        })] = rt.copy(v155)
        n4 += 1
    end

    for _, v156 in ipairs(p79.skeleton_drives.targets.bodies) do
        t24[CollisionBody.contact_id({
            tag = "Attached",
            n4
        })] = rt.copy(v156)
        n4 += 1
    end

    for _, v157 in ipairs(p78.network_proxies.bodies) do
        t24[CollisionBody.contact_id({
            tag = "Attached",
            n4
        })] = rt.copy(v157)
        n4 += 1
    end

    return t24
end

function t1.before_solve_rates_reference(p81, p82) -- line: 744
    -- upvalues: rt (copy), BoardRuntime (copy), CollisionBody (copy), SkeletonBody (copy)
    local t25 = {}

    local function snapshot(p83) -- line: 746
        -- upvalues: rt (copy)
        local rates = p83.rates

        return {
            rates = {
                linear_velocity = rt.copy(rates.linear_velocity),
                angular_velocity = rt.copy(rates.angular_velocity),
                position = rt.copy(rates.position)
            }
        }
    end

    for v158, v159 in ipairs(BoardRuntime.bodies(p81.board)) do
        t25[v158 - 1] = snapshot(v159)
    end

    local n5 = 0

    local function insert(p84) -- line: 760
        -- upvalues: t25 (copy), snapshot (copy), n5 (ref), CollisionBody (copy)
        t25[CollisionBody.contact_id({
            tag = "Attached",
            n5
        })] = snapshot(p84)
        n5 += 1
    end

    for _, v160 in ipairs(SkeletonBody.bodies(p82.skeleton)) do
        t25[CollisionBody.contact_id({
            tag = "Attached",
            n5
        })] = snapshot(v160)
        n5 += 1
    end

    for _, v161 in ipairs(p82.skeleton_drives.targets.bodies) do
        t25[CollisionBody.contact_id({
            tag = "Attached",
            n5
        })] = snapshot(v161)
        n5 += 1
    end

    for _, v162 in ipairs(p81.network_proxies.bodies) do
        t25[CollisionBody.contact_id({
            tag = "Attached",
            n5
        })] = snapshot(v162)
        n5 += 1
    end

    return t25
end

local function rates_snapshot(p85) -- line: 776
    local rates = p85.rates

    return {
        rates = {
            linear_velocity = table.clone(rates.linear_velocity),
            angular_velocity = table.clone(rates.angular_velocity),
            position = table.clone(rates.position)
        }
    }
end

function t1.before_solve_rates(p86, p87) -- line: 792
    -- upvalues: BoardRuntime (copy), ATTACHED_REACTION_BASE (copy), SkeletonBody (copy), rates_snapshot (copy)
    local t26 = {}

    for v163, v164 in ipairs(BoardRuntime.bodies(p86.board)) do
        t26[v163 - 1] = rates_snapshot(v164)
    end

    local n6 = 0

    for _, v165 in ipairs(SkeletonBody.bodies(p87.skeleton)) do
        local v166 = ATTACHED_REACTION_BASE + n6

        if v166 > 4294967295 then
            error("attached contact body index exceeds host storage", 0)
        end

        t26[v166] = rates_snapshot(v165)
        n6 += 1
    end

    for _, v167 in ipairs(p87.skeleton_drives.targets.bodies) do
        local v168 = ATTACHED_REACTION_BASE + n6

        if v168 > 4294967295 then
            error("attached contact body index exceeds host storage", 0)
        end

        t26[v168] = rates_snapshot(v167)
        n6 += 1
    end

    for _, v169 in ipairs(p86.network_proxies.bodies) do
        local v170 = ATTACHED_REACTION_BASE + n6

        if v170 > 4294967295 then
            error("attached contact body index exceeds host storage", 0)
        end

        t26[v170] = rates_snapshot(v169)
        n6 += 1
    end

    return t26
end

local t27 = {}
local n7 = 0
local n8 = 0

local function rates_snapshot_into(p88, p89, p90) -- line: 840
    -- upvalues: rates_snapshot (copy)
    local rates = p90.rates
    local v171 = p88[p89]

    if v171 ~= nil then
        local rates2 = v171.rates
        local linear_velocity = rates.linear_velocity
        local linear_velocity2 = rates2.linear_velocity
        local x, y, z = linear_velocity.x, linear_velocity.y, linear_velocity.z

        linear_velocity2.x = x
        linear_velocity2.y = y
        linear_velocity2.z = z

        local angular_velocity = rates.angular_velocity
        local angular_velocity2 = rates2.angular_velocity
        local x2, y2, z2 = angular_velocity.x, angular_velocity.y, angular_velocity.z

        angular_velocity2.x = x2
        angular_velocity2.y = y2
        angular_velocity2.z = z2

        local position = rates.position
        local position2 = rates2.position
        local x3, y3, z3 = position.x, position.y, position.z

        position2.x = x3
        position2.y = y3
        position2.z = z3
    else
        p88[p89] = rates_snapshot(p90)
    end
end

function t1.before_solve_rates_scratch(p91, p92) -- line: 856
    -- upvalues: BoardRuntime (copy), ATTACHED_REACTION_BASE (copy), SkeletonBody (copy), t27 (copy), n7 (ref), n8 (ref), rates_snapshot_into (copy)
    local n9 = 0

    for v172, v173 in ipairs(BoardRuntime.bodies(p91.board)) do
        n9 = v172
        rates_snapshot_into(t27, v172 - 1, v173)
    end

    local n10 = 0

    for _, v174 in ipairs(SkeletonBody.bodies(p92.skeleton)) do
        local v175 = ATTACHED_REACTION_BASE + n10

        if v175 > 4294967295 then
            error("attached contact body index exceeds host storage", 0)
        end

        rates_snapshot_into(t27, v175, v174)
        n10 += 1
    end

    for _, v176 in ipairs(p92.skeleton_drives.targets.bodies) do
        local v177 = ATTACHED_REACTION_BASE + n10

        if v177 > 4294967295 then
            error("attached contact body index exceeds host storage", 0)
        end

        rates_snapshot_into(t27, v177, v176)
        n10 += 1
    end

    for _, v178 in ipairs(p91.network_proxies.bodies) do
        local v179 = ATTACHED_REACTION_BASE + n10

        if v179 > 4294967295 then
            error("attached contact body index exceeds host storage", 0)
        end

        rates_snapshot_into(t27, v179, v178)
        n10 += 1
    end

    for i = n9, n7 - 1 do
        t27[i] = nil
    end

    for i = n10, n8 - 1 do
        t27[ATTACHED_REACTION_BASE + i] = nil
    end

    n7 = n9
    n8 = n10

    return t27
end

local function json_display(p93) -- line: 904
    if type(p93) == "string" then
        return "\"" .. string.gsub(p93, "[\\\"]", function(p94) -- line: 906
            return "\\" .. p94
        end) .. "\""
    end

    if p93 == nil then
        return "null"
    end

    if type(p93) == "number" then
        return string.format("%d", p93)
    end

    return (tostring(p93))
end

function t1.after_solve_reference(p95, p96, p97) -- line: 920
    -- upvalues: rt (copy), v1 (copy), v12 (copy), BoardRuntime (copy), RetailContactJacobian (copy), t1 (copy), body (copy), identity (copy), point_velocity (copy), json_display (copy)
    local time_step = p95.settings.step.simulation.time_step
    local v180 = t1.ContactFrame.default()

    v180.tick = p95.ticks

    for _, v181 in ipairs(BoardRuntime.solved_contacts(p95.board)) do
        local v182 = rt.copy(RetailContactJacobian.words(v181))

        if v12.spy_contact_jacobians(v182, 1, 0, p95.settings.step.simulation.frequency, function(p98) -- line: 927
            -- upvalues: p95 (copy), p96 (copy), v1 (copy), body (copy)
            local v183 = body(p98, p95, p96)

            if v183 == nil then
                return { 0, 0, 0, 0 }
            end

            local x = v183.rates.position.x
            local v184

            if x ~= 0 and x > -1.1754943508222875E-38 and x < 1.1754943508222875E-38 then
                local v185 = math.abs(x) * 7.1362384635298E+44
                local v186 = math.floor(v185)
                local v187 = v185 - v186

                v184 = if v187 > 0.5 or v187 == 0.5 and v186 % 2 == 1 then v186 + 1 else v186

                if x < 0 then
                    v184 += 2147483648
                end
            else
                buffer.writef32(v1, 0, x)
                v184 = buffer.readu32(v1, 0)
            end

            local y = v183.rates.position.y
            local v188

            if y ~= 0 and y > -1.1754943508222875E-38 and y < 1.1754943508222875E-38 then
                local v189 = math.abs(y) * 7.1362384635298E+44
                local v190 = math.floor(v189)
                local v191 = v189 - v190

                v188 = if v191 > 0.5 or v191 == 0.5 and v190 % 2 == 1 then v190 + 1 else v190

                if y < 0 then
                    v188 += 2147483648
                end
            else
                buffer.writef32(v1, 0, y)
                v188 = buffer.readu32(v1, 0)
            end

            local z = v183.rates.position.z
            local v192

            if z ~= 0 and z > -1.1754943508222875E-38 and z < 1.1754943508222875E-38 then
                local v193 = math.abs(z) * 7.1362384635298E+44
                local v194 = math.floor(v193)
                local v195 = v193 - v194

                v192 = if v195 > 0.5 or v195 == 0.5 and v194 % 2 == 1 then v194 + 1 else v194

                if z < 0 then
                    v192 += 2147483648
                end
            else
                buffer.writef32(v1, 0, z)
                v192 = buffer.readu32(v1, 0)
            end

            return {
                v184,
                v188,
                v192,
                0
            }
        end) ~= 0 then
            local function v(p99) -- line: 942
                -- upvalues: v182 (copy), v1 (copy)
                buffer.writeu32(v1, 0, v182[p99 + 1])

                local v197 = buffer.readf32(v1, 0)

                buffer.writeu32(v1, 0, v182[p99 + 2])

                local v199 = buffer.readf32(v1, 0)

                buffer.writeu32(v1, 0, v182[p99 + 3])

                return {
                    v197,
                    v199,
                    (buffer.readf32(v1, 0))
                }
            end

            local v201 = v182[25]
            local v202 = v182[26]

            buffer.writeu32(v1, 0, v182[13])

            local v204 = buffer.readf32(v1, 0)

            buffer.writeu32(v1, 0, v182[14])

            local v206 = buffer.readf32(v1, 0)

            buffer.writeu32(v1, 0, v182[15])

            local t29 = {
                v204,
                v206,
                (buffer.readf32(v1, 0))
            }

            buffer.writeu32(v1, 0, v182[1])

            local v209 = buffer.readf32(v1, 0)

            buffer.writeu32(v1, 0, v182[2])

            local v211 = buffer.readf32(v1, 0)

            buffer.writeu32(v1, 0, v182[3])

            local t30 = {
                v209,
                v211,
                (buffer.readf32(v1, 0))
            }

            buffer.writeu32(v1, 0, v182[17])

            local v214 = buffer.readf32(v1, 0)

            buffer.writeu32(v1, 0, v182[18])

            local v216 = buffer.readf32(v1, 0)

            buffer.writeu32(v1, 0, v182[19])

            local t31 = {
                v214,
                v216,
                (buffer.readf32(v1, 0))
            }

            buffer.writeu32(v1, 0, v182[21])

            local v219 = buffer.readf32(v1, 0)

            buffer.writeu32(v1, 0, v182[22])

            local v221 = buffer.readf32(v1, 0)

            buffer.writeu32(v1, 0, v182[23])

            local t32 = {
                v219,
                v221,
                (buffer.readf32(v1, 0))
            }
            local t33 = {
                t31[1] + t32[1],
                t31[2] + t32[2],
                t31[3] + t32[3]
            }
            local v223 = point_velocity(p97[v201], t29)
            local v224 = point_velocity(p97[v202], t29)
            local t34 = {
                v223[1] - v224[1],
                v223[2] - v224[2],
                v223[3] - v224[3]
            }
            local v225 = t29[1]
            local v226 = v225 == v225 and v225 ~= 1e999 and v225 ~= (-1e999)

            if v226 then
                local v227 = t29[2]

                v226 = v227 == v227 and v227 ~= 1e999 and v227 ~= (-1e999)

                if v226 then
                    local v228 = t29[3]

                    v226 = v228 == v228 and v228 ~= 1e999 and v228 ~= (-1e999)
                end
            end

            if v226 then
                local v229 = t33[1]
                local v230 = v229 == v229 and v229 ~= 1e999 and v229 ~= (-1e999)

                if v230 then
                    local v231 = t33[2]

                    v230 = v231 == v231 and v231 ~= 1e999 and v231 ~= (-1e999)

                    if v230 then
                        local v232 = t33[3]

                        v230 = v232 == v232 and v232 ~= 1e999 and v232 ~= (-1e999)
                    end
                end

                if v230 then
                    local v233 = t34[1]
                    local v234 = v233 == v233 and v233 ~= 1e999 and v233 ~= (-1e999)

                    if v234 then
                        local v235 = t34[2]

                        v234 = v235 == v235 and v235 ~= 1e999 and v235 ~= (-1e999)

                        if v234 then
                            local v236 = t34[3]

                            v234 = v236 == v236 and v236 ~= 1e999 and v236 ~= (-1e999)
                        end
                    end

                    if v234 then
                        local function stable(p100) -- line: 965
                            -- upvalues: p95 (copy), identity (copy), json_display (copy)
                            local v237 = identity(p100, p95)

                            if v237.kind == "remote" then
                                return "peer:" .. json_display(v237.peer) .. ":" .. json_display(v237.part_kind) .. ":" .. json_display(v237.part)
                            end

                            if type(v237.solid_id) == "string" then
                                return "solid:" .. v237.solid_id
                            end

                            return "native:" .. string.format("%d", p100)
                        end

                        local t35 = {
                            stable(v201),
                            (stable(v202))
                        }

                        if t35[2] < t35[1] then
                            local v238 = t35[2]
                            local v239 = t35[1]

                            t35[1] = v238
                            t35[2] = v239
                        end

                        local v240 = t35[1] .. "/" .. t35[2]
                        local t36 = {
                            id = v240,
                            phase = if p96.mod_contact_frame.pairs[v240] == nil then "begin" else "stay",
                            a = identity(v201, p95),
                            b = identity(v202, p95),
                            point = t29,
                            normal = t30,
                            relative_velocity_before_solve = {
                                t34[1],
                                t34[2],
                                t34[3]
                            },
                            closing_speed = rt.fmax(-(t34[1] * t30[1] + t34[2] * t30[2] + t34[3] * t30[3]), 0),
                            force = t33,
                            normal_force = t31,
                            friction_force = t32,
                            impulse = {
                                t33[1] * time_step,
                                t33[2] * time_step,
                                t33[3] * time_step
                            },
                            static_friction = RetailContactJacobian.static_friction(v181),
                            dynamic_friction = RetailContactJacobian.dynamic_friction(v181),
                            material_tags = {
                                bit32.band(v182[27], 65535),
                                (bit32.rshift(v182[27], 16))
                            }
                        }

                        v180.pairs[v240] = rt.copy(t36)

                        if #v180.contacts < 128 then
                            table.insert(v180.contacts, t36)
                        else
                            v180.truncated = true
                        end
                    end
                end
            end
        end
    end

    local _ipairs = ipairs
    local pairs = p96.mod_contact_frame.pairs
    local t37 = {}

    for v244 in pairs do
        table.insert(t37, v244)
    end

    table.sort(t37)

    for _, v245 in _ipairs(t37) do
        if v180.pairs[v245] == nil then
            local v246 = rt.copy(p96.mod_contact_frame.pairs[v245])

            v246.phase = "end"
            v246.force = { 0, 0, 0 }
            v246.normal_force = { 0, 0, 0 }
            v246.friction_force = { 0, 0, 0 }
            v246.impulse = { 0, 0, 0 }
            v246.closing_speed = 0
            v246.relative_velocity_before_solve = { 0, 0, 0 }

            if #v180.contacts < 256 then
                table.insert(v180.contacts, v246)
            else
                v180.truncated = true
            end
        end
    end

    return v180
end

local decode_contact_id = CollisionBody.decode_contact_id
local to_bits, from_bits, is_finite = rt.to_bits, rt.from_bits, rt.is_finite
local v247 = table.create(64, 0)

local function body_fast(p101, p102, p103) -- line: 1039
    -- upvalues: BodyId (copy), BoardRuntime (copy), SkeletonBody (copy), decode_contact_id (copy)
    local v248, v249 = decode_contact_id(p101)

    if v248 == 1 then
        return BoardRuntime.bodies(p102.board)[BodyId.index(v249) + 1]
    end

    if v248 ~= 2 then
        return nil
    end

    local v250 = SkeletonBody.bodies(p103.skeleton)

    if v249 < #v250 then
        return v250[v249 + 1]
    end

    local v251 = v249 - #v250
    local bodies = p103.skeleton_drives.targets.bodies

    if v251 < #bodies then
        return bodies[v251 + 1]
    end

    local v252 = v251 - #bodies

    return p102.network_proxies.bodies[v252 + 1]
end

local function after_center(p104, p105, p106) -- line: 1062
    -- upvalues: to_bits (copy), body_fast (copy)
    local v253 = body_fast(p106, p104, p105)

    if v253 == nil then
        return 0, 0, 0, 0
    end

    local position = v253.rates.position

    return to_bits(position.x), to_bits(position.y), to_bits(position.z), 0
end

local function point_velocity_xyz(p107, p108, p109, p110) -- line: 1073
    if p107 == nil then
        return 0, 0, 0
    end

    local rates = p107.rates
    local linear_velocity, angular_velocity, position = rates.linear_velocity, rates.angular_velocity, rates.position
    local v254 = p108 - position.x
    local v255 = p109 - position.y
    local v256 = p110 - position.z
    local x, y, z = angular_velocity.x, angular_velocity.y, angular_velocity.z

    return linear_velocity.x + (y * v256 - v255 * z), linear_velocity.y + (z * v254 - v256 * x), linear_velocity.z + (x * v255 - v254 * y)
end

local t38 = {}
local n11 = 0

local function stable_key(p111, p112) -- line: 1092
    -- upvalues: v15 (ref), json_display (copy), t38 (copy), n11 (ref)
    if p111.kind == "remote" then
        return "peer:" .. json_display(p111.peer) .. ":" .. json_display(p111.part_kind) .. ":" .. json_display(p111.part)
    end

    if type(p111.solid_id) == "string" then
        return "solid:" .. p111.solid_id
    end

    if not v15 and type(p112) == "number" then
        local v257 = t38[p112]

        if v257 == nil then
            v257 = "native:" .. string.format("%d", p112)

            if n11 < 1024 then
                n11 += 1
                t38[p112] = v257
            end
        end

        return v257
    end

    return "native:" .. string.format("%d", p112)
end

function t1.after_solve(p113, p114, p115) -- line: 1141
    -- upvalues: rt (copy), v12 (copy), BoardRuntime (copy), RetailContactJacobian (copy), v15 (ref), t1 (copy), identity (copy), from_bits (copy), is_finite (copy), v247 (copy), after_center (copy), point_velocity_xyz (copy), stable_key (copy)
    local time_step = p113.settings.step.simulation.time_step
    local v258 = t1.ContactFrame.default()

    v258.tick = p113.ticks

    for _, v259 in ipairs(BoardRuntime.solved_contacts(p113.board)) do
        local v260 = RetailContactJacobian.words(v259)
        local v261 = #v260

        if not (v261 >= 64) or bit32.band(v260[12], 8) ~= 0 and from_bits(v260[21]) > 0 then
            local v298

            if v261 == 64 then
                v298 = v247
                table.move(v260, 1, 64, 1, v247)
            else
                v298 = table.clone(v260)
            end

            if v12.spy_contact_jacobians_scalar(v298, 1, 0, p113.settings.step.simulation.frequency, after_center, p113, p114) ~= 0 then
                local v299 = v298[25]
                local v300 = v298[26]
                local v301 = from_bits(v298[13])
                local v302 = from_bits(v298[14])
                local v303 = from_bits(v298[15])
                local v304 = from_bits(v298[1])
                local v305 = from_bits(v298[2])
                local v306 = from_bits(v298[3])
                local v307 = from_bits(v298[17])
                local v308 = from_bits(v298[18])
                local v309 = from_bits(v298[19])
                local v310 = from_bits(v298[21])
                local v311 = from_bits(v298[22])
                local v312 = from_bits(v298[23])
                local v313 = v307 + v310
                local v314 = v308 + v311
                local v315 = v309 + v312
                local v316, v317, v318 = point_velocity_xyz(p115[v299], v301, v302, v303)
                local v319, v320, v321 = point_velocity_xyz(p115[v300], v301, v302, v303)
                local v322 = v316 - v319
                local v323 = v317 - v320
                local v324 = v318 - v321

                if is_finite(v301) and is_finite(v302) and is_finite(v303) and is_finite(v313) and is_finite(v314) and is_finite(v315) and is_finite(v322) and is_finite(v323) and is_finite(v324) then
                    local v325 = identity(v299, p113)
                    local v326 = identity(v300, p113)
                    local v327 = stable_key(v325, v299)
                    local v328 = stable_key(v326, v300)

                    if not (v328 < v327) then
                        v327, v328 = v328, v327
                    end

                    local v329 = v328 .. "/" .. v327
                    local v330 = if p114.mod_contact_frame.pairs[v329] == nil then "begin" else "stay"
                    local v331 = v298[27]
                    local t40 = {
                        id = v329,
                        phase = v330,
                        a = v325,
                        b = v326,
                        point = {
                            v301,
                            v302,
                            v303
                        },
                        normal = {
                            v304,
                            v305,
                            v306
                        },
                        relative_velocity_before_solve = {
                            v322,
                            v323,
                            v324
                        },
                        closing_speed = rt.fmax(-(v322 * v304 + v323 * v305 + v324 * v306), 0),
                        force = {
                            v313,
                            v314,
                            v315
                        },
                        normal_force = {
                            v307,
                            v308,
                            v309
                        },
                        friction_force = {
                            v310,
                            v311,
                            v312
                        },
                        impulse = {
                            v313 * time_step,
                            v314 * time_step,
                            v315 * time_step
                        },
                        static_friction = RetailContactJacobian.static_friction(v259),
                        dynamic_friction = RetailContactJacobian.dynamic_friction(v259),
                        material_tags = {
                            bit32.band(v331, 65535),
                            (bit32.rshift(v331, 16))
                        }
                    }
                    local pairs = v258.pairs

                    if v15 then
                        pairs[v329] = rt.copy(t40)
                    else
                        pairs[v329] = t40
                    end

                    if #v258.contacts < 128 then
                        table.insert(v258.contacts, t40)
                    else
                        v258.truncated = true
                    end
                end
            end
        end
    end

    local pairs = p114.mod_contact_frame.pairs
    local t41

    if v15 then
        t41 = {}

        for v333 in pairs do
            table.insert(t41, v333)
        end
    else
        local pairs2 = v258.pairs

        for v334 in pairs do
            if pairs2[v334] == nil then
                if t41 == nil then
                    t41 = {}
                end

                table.insert(t41, v334)
            end
        end

        if t41 == nil then
            return v258
        end
    end

    table.sort(t41)

    for _, v335 in ipairs(t41) do
        if v258.pairs[v335] == nil then
            local v336 = rt.copy(p114.mod_contact_frame.pairs[v335])

            v336.phase = "end"
            v336.force = { 0, 0, 0 }
            v336.normal_force = { 0, 0, 0 }
            v336.friction_force = { 0, 0, 0 }
            v336.impulse = { 0, 0, 0 }
            v336.closing_speed = 0
            v336.relative_velocity_before_solve = { 0, 0, 0 }

            if #v258.contacts < 256 then
                table.insert(v258.contacts, v336)
            else
                v258.truncated = true
            end
        end
    end

    return v258
end

function t1.joint_loads_reference(p116, p117, p118) -- line: 1270
    -- upvalues: rt (copy), v1 (copy), ATTACHED_REACTION_BASE (copy)
    local t42 = {}

    for _, v337 in ipairs(p117) do
        if not (v337.reaction_a < ATTACHED_REACTION_BASE) then
            local v338 = v337.reaction_a - ATTACHED_REACTION_BASE
            local v339

            for v340, v341 in ipairs(p116.skeleton_joints.records) do
                if v341.child == v338 then
                    v339 = v340 - 1
                    break
                end
            end

            if v339 ~= nil then
                local words = v337.jacobian.words

                local function project(p119, p120) -- line: 1291
                    -- upvalues: words (copy), v1 (copy)
                    local t43 = { 0, 0, 0 }

                    for i = 0, 2 do
                        buffer.writeu32(v1, 0, words[p120 + i * 4 + 1])

                        local v343 = buffer.readf32(v1, 0)

                        buffer.writeu32(v1, 0, words[p120 + i * 4 + 1 + 1])

                        local v345 = buffer.readf32(v1, 0)

                        buffer.writeu32(v1, 0, words[p120 + i * 4 + 2 + 1])

                        local t44 = {
                            v343,
                            v345,
                            (buffer.readf32(v1, 0))
                        }

                        buffer.writeu32(v1, 0, words[p119 + i + 1])

                        local v348 = buffer.readf32(v1, 0)
                        local t45 = {
                            t44[1] * v348,
                            t44[2] * v348,
                            t44[3] * v348
                        }

                        t43 = {
                            t43[1] + t45[1],
                            t43[2] + t45[2],
                            t43[3] + t45[3]
                        }
                    end

                    return t43
                end

                local v349 = project(8, 48)
                local t46 = {
                    v349[1] / p118,
                    v349[2] / p118,
                    v349[3] / p118
                }
                local v350 = project(12, 60)
                local t47 = {
                    v350[1] / p118,
                    v350[2] / p118,
                    v350[3] / p118
                }
                local v351 = t46[1]
                local v352 = v351 == v351 and v351 ~= 1e999 and v351 ~= (-1e999)

                if v352 then
                    local v353 = t46[2]

                    v352 = v353 == v353 and v353 ~= 1e999 and v353 ~= (-1e999)

                    if v352 then
                        local v354 = t46[3]

                        v352 = v354 == v354 and v354 ~= 1e999 and v354 ~= (-1e999)
                    end
                end

                if v352 then
                    local v355 = t47[1]
                    local v356 = v355 == v355 and v355 ~= 1e999 and v355 ~= (-1e999)

                    if v356 then
                        local v357 = t47[2]

                        v356 = v357 == v357 and v357 ~= 1e999 and v357 ~= (-1e999)

                        if v356 then
                            local v358 = t47[3]

                            v356 = v358 == v358 and v358 ~= 1e999 and v358 ~= (-1e999)
                        end
                    end

                    if v356 then
                        t42[v339] = {
                            linear_impulse = {
                                t46[1],
                                t46[2],
                                t46[3]
                            },
                            angular_impulse = {
                                t47[1],
                                t47[2],
                                t47[3]
                            },
                            force = {
                                t46[1] / p118,
                                t46[2] / p118,
                                t46[3] / p118
                            },
                            torque = {
                                t47[1] / p118,
                                t47[2] / p118,
                                t47[3] / p118
                            },
                            solver_words = rt.copy(words)
                        }
                    end
                end
            end
        end
    end

    return t42
end

function t1.joint_loads(p121, p122, p123) -- line: 1329
    -- upvalues: rt (copy), ATTACHED_REACTION_BASE (copy)
    local from_bits, is_finite = rt.from_bits, rt.is_finite
    local t48 = {}

    for _, v359 in ipairs(p122) do
        if not (v359.reaction_a < ATTACHED_REACTION_BASE) then
            local v360 = v359.reaction_a - ATTACHED_REACTION_BASE
            local v361

            for v362, v363 in ipairs(p121.skeleton_joints.records) do
                if v363.child == v360 then
                    v361 = v362 - 1
                    break
                end
            end

            if v361 ~= nil then
                local words = v359.jacobian.words
                local v364 = from_bits(words[9])
                local v365 = from_bits(words[10])
                local v366 = from_bits(words[11])
                local v367 = (0 + from_bits(words[49]) * v364 + from_bits(words[53]) * v365 + from_bits(words[57]) * v366) / p123
                local v368 = (0 + from_bits(words[50]) * v364 + from_bits(words[54]) * v365 + from_bits(words[58]) * v366) / p123
                local v369 = (0 + from_bits(words[51]) * v364 + from_bits(words[55]) * v365 + from_bits(words[59]) * v366) / p123
                local v370 = from_bits(words[13])
                local v371 = from_bits(words[14])
                local v372 = from_bits(words[15])
                local v373 = (0 + from_bits(words[61]) * v370 + from_bits(words[65]) * v371 + from_bits(words[69]) * v372) / p123
                local v374 = (0 + from_bits(words[62]) * v370 + from_bits(words[66]) * v371 + from_bits(words[70]) * v372) / p123
                local v375 = (0 + from_bits(words[63]) * v370 + from_bits(words[67]) * v371 + from_bits(words[71]) * v372) / p123

                if is_finite(v367) and is_finite(v368) and is_finite(v369) and is_finite(v373) and is_finite(v374) and is_finite(v375) then
                    t48[v361] = {
                        linear_impulse = { v367, v368, v369 },
                        angular_impulse = { v373, v374, v375 },
                        force = {
                            v367 / p123,
                            v368 / p123,
                            v369 / p123
                        },
                        torque = {
                            v373 / p123,
                            v374 / p123,
                            v375 / p123
                        },
                        solver_words = table.clone(words)
                    }
                end
            end
        end
    end

    return t48
end

local t49 = {}

function t1.joint_loads_into(p124, p125, p126, p127) -- line: 1392
    -- upvalues: ATTACHED_REACTION_BASE (copy), t1 (copy), from_bits (copy), is_finite (copy), t49 (copy)
    if p124 == nil then
        return t1.joint_loads(p125, p126, p127)
    end

    table.clear(t49)

    for _, v376 in ipairs(p126) do
        if not (v376.reaction_a < ATTACHED_REACTION_BASE) then
            local v377 = v376.reaction_a - ATTACHED_REACTION_BASE
            local v378

            for v379, v380 in ipairs(p125.skeleton_joints.records) do
                if v380.child == v377 then
                    v378 = v379 - 1
                    break
                end
            end

            if v378 ~= nil then
                local words = v376.jacobian.words
                local v381 = from_bits(words[9])
                local v382 = from_bits(words[10])
                local v383 = from_bits(words[11])
                local v384 = (0 + from_bits(words[49]) * v381 + from_bits(words[53]) * v382 + from_bits(words[57]) * v383) / p127
                local v385 = (0 + from_bits(words[50]) * v381 + from_bits(words[54]) * v382 + from_bits(words[58]) * v383) / p127
                local v386 = (0 + from_bits(words[51]) * v381 + from_bits(words[55]) * v382 + from_bits(words[59]) * v383) / p127
                local v387 = from_bits(words[13])
                local v388 = from_bits(words[14])
                local v389 = from_bits(words[15])
                local v390 = (0 + from_bits(words[61]) * v387 + from_bits(words[65]) * v388 + from_bits(words[69]) * v389) / p127
                local v391 = (0 + from_bits(words[62]) * v387 + from_bits(words[66]) * v388 + from_bits(words[70]) * v389) / p127
                local v392 = (0 + from_bits(words[63]) * v387 + from_bits(words[67]) * v388 + from_bits(words[71]) * v389) / p127

                if is_finite(v384) and is_finite(v385) and is_finite(v386) and is_finite(v390) and is_finite(v391) and is_finite(v392) then
                    local v393 = p124[v378]
                    local linear_impulse, angular_impulse, force, torque, solver_words

                    if v393 ~= nil then
                        linear_impulse = v393.linear_impulse
                        angular_impulse = v393.angular_impulse
                        force = v393.force
                        torque = v393.torque
                        solver_words = v393.solver_words
                    end

                    if linear_impulse == nil
                        or angular_impulse == nil
                        or force == nil
                        or torque == nil
                        or solver_words == nil
                        or solver_words == words then
                        p124[v378] = {
                            linear_impulse = {
                                v384,
                                v385,
                                v386
                            },
                            angular_impulse = {
                                v390,
                                v391,
                                v392
                            },
                            force = {
                                v384 / p127,
                                v385 / p127,
                                v386 / p127
                            },
                            torque = {
                                v390 / p127,
                                v391 / p127,
                                v392 / p127
                            },
                            solver_words = table.clone(words)
                        }
                    elseif #solver_words == #words and #linear_impulse == 3 and #angular_impulse == 3 and #force == 3 and #torque == 3 then
                        linear_impulse[1] = v384
                        linear_impulse[2] = v385
                        linear_impulse[3] = v386
                        angular_impulse[1] = v390
                        angular_impulse[2] = v391
                        angular_impulse[3] = v392

                        local v394 = v384 / p127
                        local v395 = v385 / p127
                        local v396 = v386 / p127

                        force[1] = v394
                        force[2] = v395
                        force[3] = v396

                        local v397 = v390 / p127
                        local v398 = v391 / p127
                        local v399 = v392 / p127

                        torque[1] = v397
                        torque[2] = v398
                        torque[3] = v399
                        table.move(words, 1, #words, 1, solver_words)
                    else
                        p124[v378] = {
                            linear_impulse = {
                                v384,
                                v385,
                                v386
                            },
                            angular_impulse = {
                                v390,
                                v391,
                                v392
                            },
                            force = {
                                v384 / p127,
                                v385 / p127,
                                v386 / p127
                            },
                            torque = {
                                v390 / p127,
                                v391 / p127,
                                v392 / p127
                            },
                            solver_words = table.clone(words)
                        }
                    end

                    t49[v378] = true
                end
            end
        end
    end

    for v400 in p124 do
        if not t49[v400] then
            p124[v400] = nil
        end
    end

    return p124
end

function t1.set_part(p128, p129, p130, p131) -- line: 1473
    -- upvalues: SkeletonBody (copy)
    if #SkeletonBody.bodies(p128.skeleton) <= p130 then
        error("unknown physical part", 0)
    end

    local v401 = p128.mod_part_overrides[p130]

    if v401 ~= nil and v401[1] ~= p129 then
        error("part is owned by another mod", 0)
    end

    if p131 ~= nil then
        p128.mod_part_overrides[p130] = { p129, p131 }
    else
        p128.mod_part_overrides[p130] = nil
    end
end

t1.PartRestore = {}

function t1.apply_parts(p132) -- line: 1493
    -- upvalues: rt (copy), SkeletonBody (copy), motion_flags (ref)
    local t52 = {}
    local _ipairs = ipairs
    local t53 = {}

    for v402 in p132.mod_part_overrides do
        table.insert(t53, v402)
    end

    table.sort(t53)

    for _, v403 in _ipairs(t53) do
        local v404 = p132.mod_part_overrides[v403][2]

        table.insert(t52, {
            v403,
            SkeletonBody.bodies(p132.skeleton)[v403 + 1].state_flags,
            rt.copy(p132.skeleton_collision.parts[v403 + 1])
        })

        if v404.motion ~= nil then
            SkeletonBody.bodies_mut(p132.skeleton)[v403 + 1].state_flags = motion_flags(v404.motion)
        end

        local v405 = p132.skeleton_collision.parts[v403 + 1]

        if v404.collision ~= nil then
            v405.enabled = v404.collision
        end

        if v404.friction ~= nil then
            v405.material.static_friction = v404.friction
            v405.material.dynamic_friction = v404.friction
        end
    end

    return { t52 }
end

function t1.PartRestore.restore(p133, p134) -- line: 1518
    -- upvalues: SkeletonBody (copy)
    for _, v406 in ipairs(p133[1]) do
        local v407 = v406[1]
        local v408 = v406[2]
        local v409 = v406[3]

        SkeletonBody.bodies_mut(p134.skeleton)[v407 + 1].state_flags = v408
        p134.skeleton_collision.parts[v407 + 1] = v409
    end
end

function t1.motion_flags(p135) -- line: 1527
    if p135 == "dynamic" then
        return 4
    end

    if p135 == "frozen" then
        return 2
    end

    return 1
end

motion_flags = t1.motion_flags

function t1.collision_parts(p136) -- line: 1540
    -- upvalues: rt (copy)
    local v410 = rt.copy(p136.skeleton_collision.parts)
    local _ipairs = ipairs
    local t55 = {}

    for v411 in p136.mod_part_overrides do
        table.insert(t55, v411)
    end

    table.sort(t55)

    for _, v412 in _ipairs(t55) do
        local v413 = p136.mod_part_overrides[v412][2]

        if v413.collision ~= nil then
            v410[v412 + 1].enabled = v413.collision
        end

        if v413.friction ~= nil then
            v410[v412 + 1].material.static_friction = v413.friction
            v410[v412 + 1].material.dynamic_friction = v413.friction
        end
    end

    return v410
end

return t1
