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

local import = require(sim.import)
local v8 = import("skate_core/physics/board")
local v9 = import("skate_core/physics/constraint_batch")
local v10 = import("skate_core/physics/drive_preparation")
local v11 = import("skate_core/physics/drive_solver")
local v12 = import("skate_core/physics/hook_drive")
local v13 = import("skate_core/physics/joint_builder")
local v14 = import("skate_core/physics/joint_records")
local v15 = import("skate_core/physics/rigid_body")
local v16 = import("skate_core/physics/truck_frames")
local v17 = import("skate_core/math")
local BODY_COUNT, BodyId = v8.BODY_COUNT, v8.BodyId
local compile_active = v9.compile_active
local build_drive_rows = v11.build_drive_rows
local build_retail_joint_jacobian = v13.build_retail_joint_jacobian
local default_joint_records, RetailJointRecord = v14.default_joint_records, v14.RetailJointRecord
local pack_world_inverse_inertia = v15.pack_world_inverse_inertia
local steering_drive_frames = v16.steering_drive_frames
local HookDriveState = v12.HookDriveState
local Vector3 = v17.Vector3
local build_retail_joint_jacobian_bodies = v13.build_retail_joint_jacobian_bodies
local t1 = {
    BodySnapshot = {},
    BoardHook = {},
    HOOK_REACTION = BODY_COUNT,
    BoardConstraints = {}
}

local function joint_body_view(p4) -- line: 85
    -- upvalues: pack_world_inverse_inertia (copy)
    local rates = p4.rates

    return {
        reaction_guest_address = 0,
        state = p4.state_flags,
        orientation = rates.orientation,
        center_of_mass = rates.position,
        basis = rates.basis,
        linear_velocity = rates.linear_velocity,
        angular_velocity = rates.angular_velocity,
        force_acceleration = rates.force_acceleration,
        torque_acceleration = rates.torque_acceleration,
        inverse_mass = p4.inertia.inverse_mass,
        world_inverse_inertia = pack_world_inverse_inertia(rates.world_inverse_inertia)
    }
end

function t1.BoardConstraints.build_reference(p5, p6, p7, p8, p9) -- line: 105
    -- upvalues: rt (copy), BodyId (copy), compile_active (copy), build_drive_rows (copy), build_retail_joint_jacobian (copy), default_joint_records (copy), RetailJointRecord (copy), HookDriveState (copy), t1 (copy), joint_body_view (copy)
    local v20 = compile_active(default_joint_records(), function(p10) -- line: 106
        -- upvalues: p5 (copy), BodyId (copy), RetailJointRecord (copy)
        return {
            p5[BodyId.index(RetailJointRecord.live_body_a(p10)) + 1].state_flags,
            p5[BodyId.index(RetailJointRecord.live_body_b(p10)) + 1].state_flags
        }
    end, function(p11) -- line: 111
        -- upvalues: p5 (copy), p9 (copy), BodyId (copy), build_retail_joint_jacobian (copy), RetailJointRecord (copy), joint_body_view (copy)
        local v21 = RetailJointRecord.live_body_a(p11)
        local v22 = RetailJointRecord.live_body_b(p11)

        return {
            jacobian = build_retail_joint_jacobian({
                joint_guest_address = 0,
                parameters = p11.parameters,
                frames = p11.frames,
                body_a = joint_body_view(p5[BodyId.index(v21) + 1]),
                body_b = joint_body_view(p5[BodyId.index(v22) + 1]),
                time_step = p9
            }),
            reaction_a = BodyId.index(v21),
            reaction_b = BodyId.index(v22)
        }
    end)
    local v25 = compile_active({
        0, 1
    }, function(p12) -- line: 130
        -- upvalues: p5 (copy), BodyId (copy)
        local v24 = ({
            BodyId.FrontTruck,
            BodyId.BackTruck
        })[p12 + 1]

        return {
            p5[BodyId.index(v24) + 1].state_flags,
            p5[BodyId.index(BodyId.Deck) + 1].state_flags
        }
    end, function(p13) -- line: 136
        -- upvalues: p5 (copy), p7 (copy), p8 (copy), p9 (copy), rt (copy), BodyId (copy), build_drive_rows (copy), t1 (copy)
        local v26 = ({
            BodyId.FrontTruck,
            BodyId.BackTruck
        })[p13 + 1]

        return build_drive_rows(t1.drive_body(p5[BodyId.index(v26) + 1], BodyId.index(v26)), t1.drive_body(p5[BodyId.index(BodyId.Deck) + 1], BodyId.index(BodyId.Deck)), rt.copy(p7[p13 + 1]), rt.copy(p8), p9)
    end)
    local v28 = compile_active({
        {}
    }, function(_) -- line: 146
        -- upvalues: p5 (copy), p6 (copy), BodyId (copy)
        return {
            p6.body.state_flags,
            p5[BodyId.index(BodyId.Deck) + 1].state_flags
        }
    end, function(_) -- line: 151
        -- upvalues: p5 (copy), p6 (copy), p7 (copy), p9 (copy), rt (copy), BodyId (copy), build_drive_rows (copy), HookDriveState (copy), t1 (copy)
        return build_drive_rows(t1.drive_body(p6.body, t1.HOOK_REACTION), t1.drive_body(p5[BodyId.index(BodyId.Deck) + 1], BodyId.index(BodyId.Deck)), rt.copy(p7[3]), HookDriveState.solver_dynamics(p6.drive), p9)
    end)

    for i = 1, #v28 do
        table.insert(v25, v28[i])
    end

    return {
        joints = v20,
        drives = v25
    }
end

local v30, v31, v32
local t4 = {}
local t5 = { false, false, false }
local build_retail_joint_jacobian_bodies_into = v13.build_retail_joint_jacobian_bodies_into
local build_drive_rows_into = import("skate_core/physics/drive_solver/builder").build_drive_rows_into
local v33 = true

function t1.set_prepared(p16) -- line: 237
    -- upvalues: v33 (ref)
    local v34 = v33

    v33 = p16

    return v34
end

local function solver_packing() -- line: 244
    -- upvalues: import (copy)
    return import("skate_core/physics/solver/packing")
end

local function abandon_pools() -- line: 248
    -- upvalues: import (copy), t4 (ref), t5 (ref)
    local v35 = import("skate_core/physics/solver/packing")

    for _, v36 in ipairs(t4) do
        v35.unregister_joint_jacobian(v36.jacobian)
    end

    t4 = {}

    local v37 = t5[1]

    if v37 then
        v35.unregister_drive_rows(v37.row)
    end

    local v38 = t5[2]

    if v38 then
        v35.unregister_drive_rows(v38.row)
    end

    local v39 = t5[3]

    if v39 then
        v35.unregister_drive_rows(v39.row)
    end

    t5 = { false, false, false }
end

local function drive_body_into(p17, p18, p19) -- line: 272
    -- upvalues: rt (copy)
    local rates = p18.rates

    p17.reaction_index = p19
    p17.state = p18.state_flags

    local orientation = rates.orientation
    local orientation2 = p17.orientation
    local x, y, z, w = orientation.x, orientation.y, orientation.z, orientation.w

    orientation2.x = x
    orientation2.y = y
    orientation2.z = z
    orientation2.w = w

    local basis = rates.basis
    local columns = basis.columns

    if #columns == 3 then
        local columns2 = p17.basis.columns
        local v40 = columns[1]
        local v41 = columns[2]
        local v42 = columns[3]

        if #columns2 == 3 and #v40 == 3 and #v41 == 3 and #v42 == 3 and #columns2[1] == 3 and #columns2[2] == 3 and #columns2[3] == 3 then
            local v43 = columns2[1]
            local v44 = v40[1]
            local v45 = v40[2]
            local v46 = v40[3]

            v43[1] = v44
            v43[2] = v45
            v43[3] = v46

            local v47 = columns2[2]
            local v48 = v41[1]
            local v49 = v41[2]
            local v50 = v41[3]

            v47[1] = v48
            v47[2] = v49
            v47[3] = v50

            local v51 = columns2[3]
            local v52 = v42[1]
            local v53 = v42[2]
            local v54 = v42[3]

            v51[1] = v52
            v51[2] = v53
            v51[3] = v54
        else
            p17.basis = rt.copy(basis)
        end
    else
        p17.basis = rt.copy(basis)
    end

    local position = rates.position
    local center_of_mass = p17.center_of_mass
    local x2, y2, z2 = position.x, position.y, position.z

    center_of_mass.x = x2
    center_of_mass.y = y2
    center_of_mass.z = z2

    local linear_velocity = rates.linear_velocity
    local linear_velocity2 = p17.linear_velocity
    local x3, y3, z3 = linear_velocity.x, linear_velocity.y, linear_velocity.z

    linear_velocity2.x = x3
    linear_velocity2.y = y3
    linear_velocity2.z = z3

    local angular_velocity = rates.angular_velocity
    local angular_velocity2 = p17.angular_velocity
    local x4, y4, z4 = angular_velocity.x, angular_velocity.y, angular_velocity.z

    angular_velocity2.x = x4
    angular_velocity2.y = y4
    angular_velocity2.z = z4

    local force_acceleration = rates.force_acceleration
    local force_acceleration2 = p17.force_acceleration
    local x5, y5, z5 = force_acceleration.x, force_acceleration.y, force_acceleration.z

    force_acceleration2.x = x5
    force_acceleration2.y = y5
    force_acceleration2.z = z5

    local torque_acceleration = rates.torque_acceleration
    local torque_acceleration2 = p17.torque_acceleration
    local x6, y6, z6 = torque_acceleration.x, torque_acceleration.y, torque_acceleration.z

    torque_acceleration2.x = x6
    torque_acceleration2.y = y6
    torque_acceleration2.z = z6
    p17.inverse_mass = p18.inertia.inverse_mass

    local columns2 = rates.world_inverse_inertia.columns
    local v55 = columns2[1]
    local v56 = columns2[2]
    local v57 = columns2[3]
    local world_inverse_inertia = p17.world_inverse_inertia
    local full = world_inverse_inertia.full
    local v58 = v55[1]
    local v59 = v56[1]
    local v60 = v57[1]

    full.x = v58
    full.y = v59
    full.z = v60

    local split = world_inverse_inertia.split
    local v61 = v57[3]
    local v62 = v56[2]
    local v63 = v57[2]

    split.x = v61
    split.y = v62
    split.z = v63

    return p17
end

local function pooled_drive_bodies(p20, p21, p22, p23, p24) -- line: 320
    -- upvalues: t1 (copy), t5 (ref), drive_body_into (copy)
    local v64 = t5[p20]

    if v64 then
        return v64, drive_body_into(v64.state_a, p21, p22), (drive_body_into(v64.state_b, p23, p24))
    end

    return false, t1.drive_body(p21, p22), t1.drive_body(p23, p24)
end

local function pooled_drive_rows(p25, p26, p27, p28, p29, p30, p31) -- line: 331
    -- upvalues: import (copy), build_drive_rows (copy), t5 (ref), build_drive_rows_into (copy)
    if p26 then
        return build_drive_rows_into(p26.row, p27, p28, p29, p30, p31)
    end

    local v65 = build_drive_rows(p27, p28, p29, p30, p31)
    local t6 = t5

    t6[p25] = {
        state_a = p27,
        state_b = p28,
        row = v65
    }
    import("skate_core/physics/solver/packing").register_drive_rows(v65)

    return v65
end

local function build_fresh(p32, p33, p34, p35, p36, p37) -- line: 342
    -- upvalues: BodyId (copy), build_drive_rows (copy), RetailJointRecord (copy), HookDriveState (copy), build_retail_joint_jacobian_bodies (copy), t1 (copy)
    local t7 = {}

    for _, v66 in ipairs(p32) do
        local v67 = RetailJointRecord.live_body_a(v66)
        local v68 = RetailJointRecord.live_body_b(v66)
        local v69 = p33[BodyId.index(v67) + 1]
        local v70 = p33[BodyId.index(v68) + 1]

        if bit32.band(bit32.bor(v69.state_flags, v70.state_flags), 4) ~= 0 then
            t7[#t7 + 1] = {
                jacobian = build_retail_joint_jacobian_bodies(v66.parameters, v66.frames, v69, v70, p37),
                reaction_a = BodyId.index(v67),
                reaction_b = BodyId.index(v68)
            }
        end
    end

    local t8 = {}
    local v72 = BodyId.index(BodyId.Deck)

    for i = 0, 1 do
        local v73 = if i == 0 then BodyId.FrontTruck else BodyId.BackTruck
        local v74 = BodyId.index(v73)

        if bit32.band(bit32.bor(p33[v74 + 1].state_flags, p33[v72 + 1].state_flags), 4) ~= 0 then
            t8[#t8 + 1] = build_drive_rows(t1.drive_body(p33[v74 + 1], v74), t1.drive_body(p33[v72 + 1], v72), p35[i + 1], p36, p37)
        end
    end

    if bit32.band(bit32.bor(p34.body.state_flags, p33[v72 + 1].state_flags), 4) ~= 0 then
        t8[#t8 + 1] = build_drive_rows(t1.drive_body(p34.body, t1.HOOK_REACTION), t1.drive_body(p33[v72 + 1], v72), p35[3], HookDriveState.solver_dynamics(p34.drive), p37)
    end

    return {
        joints = t7,
        drives = t8
    }
end

function t1.BoardConstraints.build(p38, p39, p40, p41, p42) -- line: 390
    -- upvalues: import (copy), BodyId (copy), default_joint_records (copy), RetailJointRecord (copy), HookDriveState (copy), t1 (copy), v30 (ref), v31 (ref), v32 (ref), t4 (ref), t5 (ref), build_retail_joint_jacobian_bodies_into (copy), v33 (ref), abandon_pools (copy), drive_body_into (copy), pooled_drive_rows (copy)
    local v77 = v30

    if v77 == nil then
        v77 = default_joint_records()
        v30 = v77
    end

    if v31 ~= p38 or v32 ~= p39 then
        abandon_pools()
        v31 = p38
        v32 = p39
    end

    local t9 = {}
    local n1 = 0

    for _, v78 in ipairs(v77) do
        local v79 = RetailJointRecord.live_body_a(v78)
        local v80 = RetailJointRecord.live_body_b(v78)
        local v81 = p38[BodyId.index(v79) + 1]
        local v82 = p38[BodyId.index(v80) + 1]

        if bit32.band(bit32.bor(v81.state_flags, v82.state_flags), 4) ~= 0 then
            n1 += 1

            local v84 = t4[n1]

            if v84 == nil then
                local v85 = table.create(96, 0)
                local t10 = {
                    words = v85
                }

                v84 = {
                    words = v85,
                    jacobian = t10,
                    row = {
                        reaction_a = 0,
                        reaction_b = 0,
                        jacobian = t10
                    }
                }

                local t11 = t4

                t11[n1] = v84
                v84.packed = import("skate_core/physics/solver/packing").register_joint_jacobian(t10)
            end

            local words, packed = v84.words, v84.packed

            if v33 then
                packed.prepared = false

                local _, v86 = build_retail_joint_jacobian_bodies_into(words, v78.parameters, v78.frames, v81, v82, p42, packed.floats)

                if v86 then
                    packed.prepared = words
                end
            else
                packed.prepared = false
                build_retail_joint_jacobian_bodies_into(words, v78.parameters, v78.frames, v81, v82, p42)
            end

            local row = v84.row

            v84.jacobian.words = words
            row.jacobian = v84.jacobian
            row.reaction_a = BodyId.index(v79)
            row.reaction_b = BodyId.index(v80)
            t9[n1] = row
        end
    end

    local t12 = {}
    local v87 = BodyId.index(BodyId.Deck)

    for i = 0, 1 do
        local v88 = if i == 0 then BodyId.FrontTruck else BodyId.BackTruck
        local v89 = BodyId.index(v88)

        if bit32.band(bit32.bor(p38[v89 + 1].state_flags, p38[v87 + 1].state_flags), 4) ~= 0 then
            local v91 = p38[v89 + 1]
            local v92 = p38[v87 + 1]
            local v93 = t5[i + 1]
            local v94, v95

            if v93 then
                v94 = drive_body_into(v93.state_a, v91, v89)
                v95 = drive_body_into(v93.state_b, v92, v87)
            else
                v93 = false
                v94 = t1.drive_body(v91, v89)
                v95 = t1.drive_body(v92, v87)
            end

            t12[#t12 + 1] = pooled_drive_rows(i + 1, v93, v94, v95, p40[i + 1], p41, p42)
        end
    end

    if bit32.band(bit32.bor(p39.body.state_flags, p38[v87 + 1].state_flags), 4) ~= 0 then
        local body = p39.body
        local HOOK_REACTION = t1.HOOK_REACTION
        local v97 = p38[v87 + 1]
        local v98 = t5[3]
        local v99, v100

        if v98 then
            v99 = drive_body_into(v98.state_a, body, HOOK_REACTION)
            v100 = drive_body_into(v98.state_b, v97, v87)
        else
            v98 = false
            v99 = t1.drive_body(body, HOOK_REACTION)
            v100 = t1.drive_body(v97, v87)
        end

        t12[#t12 + 1] = pooled_drive_rows(3, v98, v99, v100, p40[3], HookDriveState.solver_dynamics(p39.drive), p42)
    end

    return {
        joints = t9,
        drives = t12
    }
end

function t1.prepare_drive_frames(p43, p44, p45) -- line: 481
    -- upvalues: v1 (copy), v10 (copy), steering_drive_frames (copy), t1 (copy)
    local normalize_drive_frames = v10.normalize_drive_frames
    local v101 = steering_drive_frames(p43, p44)
    local v102 = table.create(#v101)

    for i = 1, #v101 do
        local v103 = v101[i]
        local v104 = table.create(16, 0)
        local t13 = {
            v103.body_a,
            v103.body_b
        }

        for j = 0, 1 do
            local v105 = t13[j + 1]
            local orientation, translation = v105.orientation, v105.translation
            local t14 = {
                orientation.x,
                orientation.y,
                orientation.z,
                orientation.w,
                translation.x,
                translation.y,
                translation.z,
                0
            }

            for k = 0, 7 do
                local v106 = j * 8 + k + 1
                local v107 = t14[k + 1]

                if v107 ~= 0 and v107 > -1.1754943508222875E-38 and v107 < 1.1754943508222875E-38 then
                    local v108 = math.abs(v107) * 7.1362384635298E+44
                    local v109 = math.floor(v108)
                    local v110 = v108 - v109
                    local v111 = if v110 > 0.5 or v110 == 0.5 and v109 % 2 == 1 then v109 + 1 else v109

                    if v107 < 0 then
                        v104[v106] = v111 + 2147483648
                    else
                        v104[v106] = v111
                    end
                else
                    buffer.writef32(v1, 0, v107)
                    v104[v106] = buffer.readu32(v1, 0)
                end
            end
        end

        normalize_drive_frames(v104)
        v102[i] = t1.hook_frames(v104)
    end

    normalize_drive_frames(p45.drive.frames)

    return {
        v102[1],
        v102[2],
        t1.hook_frames(p45.drive.frames)
    }
end

function t1.hook_frames(p46) -- line: 505
    -- upvalues: v1 (copy), Vector3 (copy)
    local function f(p47) -- line: 506
        -- upvalues: p46 (copy), v1 (copy)
        buffer.writeu32(v1, 0, p46[p47 + 1])

        return (buffer.readf32(v1, 0))
    end

    local function frame(p48) -- line: 509
        -- upvalues: p46 (copy), v1 (copy), Vector3 (copy)
        local t15 = {}
        local t16 = {}

        buffer.writeu32(v1, 0, p46[p48 + 1])
        t16.x = buffer.readf32(v1, 0)
        buffer.writeu32(v1, 0, p46[p48 + 1 + 1])
        t16.y = buffer.readf32(v1, 0)
        buffer.writeu32(v1, 0, p46[p48 + 2 + 1])
        t16.z = buffer.readf32(v1, 0)
        buffer.writeu32(v1, 0, p46[p48 + 3 + 1])
        t16.w = buffer.readf32(v1, 0)
        t15.orientation = t16

        local new = Vector3.new

        buffer.writeu32(v1, 0, p46[p48 + 4 + 1])

        local v122 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, p46[p48 + 5 + 1])

        local v125 = buffer.readf32(v1, 0)

        buffer.writeu32(v1, 0, p46[p48 + 6 + 1])
        t15.translation = new(v122, v125, (buffer.readf32(v1, 0)))

        return t15
    end

    return {
        body_a = frame(0),
        body_b = frame(8)
    }
end

function t1.joint_body(p49) -- line: 526
    -- upvalues: rt (copy), pack_world_inverse_inertia (copy)
    local rates = p49.rates

    return {
        reaction_guest_address = 0,
        state = p49.state_flags,
        orientation = rt.copy(rates.orientation),
        center_of_mass = rt.copy(rates.position),
        basis = rt.copy(rates.basis),
        linear_velocity = rt.copy(rates.linear_velocity),
        angular_velocity = rt.copy(rates.angular_velocity),
        force_acceleration = rt.copy(rates.force_acceleration),
        torque_acceleration = rt.copy(rates.torque_acceleration),
        inverse_mass = p49.inertia.inverse_mass,
        world_inverse_inertia = pack_world_inverse_inertia(rates.world_inverse_inertia)
    }
end

function t1.drive_body(p50, p51) -- line: 543
    -- upvalues: rt (copy), pack_world_inverse_inertia (copy)
    local rates = p50.rates

    return {
        reaction_index = p51,
        state = p50.state_flags,
        orientation = rt.copy(rates.orientation),
        basis = rt.copy(rates.basis),
        center_of_mass = rt.copy(rates.position),
        linear_velocity = rt.copy(rates.linear_velocity),
        angular_velocity = rt.copy(rates.angular_velocity),
        force_acceleration = rt.copy(rates.force_acceleration),
        torque_acceleration = rt.copy(rates.torque_acceleration),
        inverse_mass = p50.inertia.inverse_mass,
        world_inverse_inertia = pack_world_inverse_inertia(rates.world_inverse_inertia)
    }
end

return t1
