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
local v8 = import("skate_game/physics/solve")
local v9 = import("skate_core/physics/board")
local v10 = import("skate_core/physics/board_runtime")
local v11 = import("skate_core/physics/board_step")
local v12 = import("skate_core/physics/contact_feedback")
local v13 = import("skate_core/physics/contact_solver")
local v14 = import("skate_core/physics/skeleton_board_frames")
local v15 = import("skate_core/physics/skeleton_body")
local v16 = import("skate_core/physics/skeleton_output/correction")
local deck_frame = v8.deck_frame
local BodyId = v9.BodyId
local BoardRuntime = v10.BoardRuntime
local CollisionBody = v11.CollisionBody
local spy_contact_jacobians = v12.spy_contact_jacobians
local RetailContactJacobian = v13.RetailContactJacobian
local SkeletonBoardFrames = v14.SkeletonBoardFrames
local SkeletonBody, SkeletonCollisionFeedback, SkeletonCollisionMode, SkeletonPoseErrors = v15.SkeletonBody, v15.SkeletonCollisionFeedback, v15.SkeletonCollisionMode, v15.SkeletonPoseErrors
local CorrectionState = v16.CorrectionState
local v17 = false
local t1 = {}

function t1.set_b3_twin(p4) -- line: 61
    -- upvalues: v17 (ref)
    v17 = p4
end

local t2 = {}

function t1.publish(p5, p6, p7) -- line: 82
    -- upvalues: rt (copy), deck_frame (copy), SkeletonBody (copy), SkeletonCollisionFeedback (copy), SkeletonCollisionMode (copy), SkeletonPoseErrors (copy), CorrectionState (copy), t1 (copy), v17 (ref), t2 (copy)
    if v17 then
        return t1.publish_r3(p5, p6, p7)
    end

    local v18 = t1.collect_scratch(p5, p6)
    local processed = p6.player_input.processed
    local v19 = deck_frame(p5.board)

    CorrectionState.observe_board(p6.skeleton_output.correction, rt.copy(v19[4]), rt.copy(p6.animated_skeleton.roots.predicted_board_position))

    local state_2508 = processed.state_2508
    local v20 = processed.category_2512 == 500 and not (state_2508 == 501 or state_2508 == 503)
    local v21 = rt.map(processed.vectors_464_480_496_512_528[(if state_2508 == 601 or state_2508 == 602 then 1 else 2) + 1], rt.from_bits)
    local ground_normal = p5.riding.reckoning.ground_normal
    local x, y, z = ground_normal.x, ground_normal.y, ground_normal.z
    local v22 = {
        x,
        y,
        z,
        0
    }

    if v20 and bit32.band(processed.flags_2480, 2) ~= 0 then
        v21 = rt.map(processed.vectors_880_896_912_928_944[1], rt.from_bits)
        v22 = rt.map(processed.vectors_880_896_912_928_944[2], rt.from_bits)
    end

    t2.dt = p5.settings.step.simulation.time_step
    t2.plane_point = v21
    t2.plane_normal = v22
    t2.reference_velocity = if state_2508 == 201 then p6.skeleton.record.velocities[24] else p6.skeleton_input.deck_velocity
    t2.com_velocity = p6.animated_skeleton.board_frames.com_velocity
    t2.ragdoll = p6.skeleton_collision.is_ragdoll
    t2.disable_ground_filter = bit32.band(processed.flags_2472, 32768) ~= 0
    t2.ai_collision_scalar = bit32.band(processed.flags_2472, 268435456) ~= 0
    t2.offboard = v20
    t2.entering_offboard = state_2508 == 501 or state_2508 == 503
    t2.category_600 = processed.category_2512 == 600
    t2.request_partial_ragdoll = p7
    t2.physical = p6.skeleton.record
    t2.part_weights = p6.skeleton.definition.animation_masses.part_weights
    t2.body_frames = nil
    t2.body_frames_of = SkeletonBody.part_transforms
    t2.body_frames_owner = p6.skeleton

    local update = SkeletonCollisionFeedback.update
    local collision_feedback = p6.collision_feedback
    local ok, result = pcall(update, collision_feedback, t2, v18)

    t2.plane_point = nil
    t2.plane_normal = nil
    t2.reference_velocity = nil
    t2.com_velocity = nil
    t2.physical = nil
    t2.part_weights = nil
    t2.body_frames = nil
    t2.body_frames_owner = nil

    if not ok then
        error(result, 0)
    end

    SkeletonCollisionMode.finish_contact_frame(p6.skeleton_collision)
    p6.pose_errors.targets = rt.copy(p6.skeleton_input.extra_target_positions)
    SkeletonPoseErrors.update(p6.pose_errors, p6.skeleton.record, rt.copy(p6.animated_skeleton.roots.animation_to_world), p6.skeleton_input.drive_frames)

    local v25 = if p6.skeleton_collision.partial_ragdoll then SkeletonPoseErrors.partial_response(p6.pose_errors) else SkeletonPoseErrors.normal_response(p6.pose_errors, p6.collision_feedback, { x, y, z, 0 })

    p6.collision_pose_error = rt.copy(v25.impulse)
    p6.collision_extra_errors = rt.copy(v25.extra)
    p6.collision_maximum_error = v25.maximum_error
    t1.publish_board_observations(p6.animated_skeleton.board_frames, p6.animated_skeleton.roots, v19, rt.copy(p6.skeleton.record.centre_of_mass), p5.settings.step.simulation.time_step, processed.flags_2472)
end

function t1.publish_r3(p8, p9, p10) -- line: 165
    -- upvalues: rt (copy), deck_frame (copy), SkeletonBody (copy), SkeletonCollisionFeedback (copy), SkeletonCollisionMode (copy), SkeletonPoseErrors (copy), CorrectionState (copy), t1 (copy)
    local v26 = t1.collect_scratch(p8, p9)
    local processed = p9.player_input.processed
    local v27 = deck_frame(p8.board)

    CorrectionState.observe_board(p9.skeleton_output.correction, rt.copy(v27[4]), rt.copy(p9.animated_skeleton.roots.predicted_board_position))

    local state_2508 = processed.state_2508
    local v28 = processed.category_2512 == 500 and not (state_2508 == 501 or state_2508 == 503)
    local v29 = rt.map(processed.vectors_464_480_496_512_528[(if state_2508 == 601 or state_2508 == 602 then 1 else 2) + 1], rt.from_bits)
    local v30 = rt.copy(p8.riding.reckoning.ground_normal)
    local v31 = {
        v30.x,
        v30.y,
        v30.z,
        0
    }

    if v28 and bit32.band(processed.flags_2480, 2) ~= 0 then
        v29 = rt.map(processed.vectors_880_896_912_928_944[1], rt.from_bits)
        v31 = rt.map(processed.vectors_880_896_912_928_944[2], rt.from_bits)
    end

    SkeletonCollisionFeedback.update(p9.collision_feedback, {
        body_frames = nil,
        dt = p8.settings.step.simulation.time_step,
        plane_point = v29,
        plane_normal = v31,
        reference_velocity = if state_2508 == 201 then rt.copy(p9.skeleton.record.velocities[24]) else rt.copy(p9.skeleton_input.deck_velocity),
        com_velocity = rt.copy(p9.animated_skeleton.board_frames.com_velocity),
        ragdoll = p9.skeleton_collision.is_ragdoll,
        disable_ground_filter = bit32.band(processed.flags_2472, 32768) ~= 0,
        ai_collision_scalar = bit32.band(processed.flags_2472, 268435456) ~= 0,
        offboard = v28,
        entering_offboard = state_2508 == 501 or state_2508 == 503,
        category_600 = processed.category_2512 == 600,
        request_partial_ragdoll = p10,
        physical = p9.skeleton.record,
        part_weights = p9.skeleton.definition.animation_masses.part_weights,
        body_frames_of = SkeletonBody.part_transforms,
        body_frames_owner = p9.skeleton
    }, v26)
    SkeletonCollisionMode.finish_contact_frame(p9.skeleton_collision)
    p9.pose_errors.targets = rt.copy(p9.skeleton_input.extra_target_positions)
    SkeletonPoseErrors.update(p9.pose_errors, p9.skeleton.record, rt.copy(p9.animated_skeleton.roots.animation_to_world), p9.skeleton_input.drive_frames)

    local v32 = if p9.skeleton_collision.partial_ragdoll then SkeletonPoseErrors.partial_response(p9.pose_errors) else SkeletonPoseErrors.normal_response(p9.pose_errors, p9.collision_feedback, {
        v30.x,
        v30.y,
        v30.z,
        0
    })

    p9.collision_pose_error = rt.copy(v32.impulse)
    p9.collision_extra_errors = rt.copy(v32.extra)
    p9.collision_maximum_error = v32.maximum_error
    t1.publish_board_observations(p9.animated_skeleton.board_frames, p9.animated_skeleton.roots, v27, rt.copy(p9.skeleton.record.centre_of_mass), p8.settings.step.simulation.time_step, processed.flags_2472)
end

function t1.publish_board_observations(p11, p12, p13, p14, p15, p16) -- line: 248
    -- upvalues: SkeletonBoardFrames (copy)
    SkeletonBoardFrames.publish_local_observations(p11, p12, p13)
    SkeletonBoardFrames.publish_centre_of_mass(p11, p14, p15, p16)
end

local decode_contact_id = CollisionBody.decode_contact_id
local spy_contact_jacobians_scalar = v12.spy_contact_jacobians_scalar
local to_bits, from_bits = rt.to_bits, rt.from_bits
local t4 = {}
local t5 = {}
local t6 = {}
local t7 = {}

local function new_report() -- line: 292
    return {
        part = 0,
        tag = 0,
        other_group = 0,
        side_a = false,
        normal = { 0, 0, 0, 0 },
        point = { 0, 0, 0, 0 },
        body_a = {
            state_flags = 0,
            inverse_mass = 0,
            linear_velocity = { 0, 0, 0, 0 }
        },
        body_b = {
            state_flags = 0,
            inverse_mass = 0,
            linear_velocity = { 0, 0, 0, 0 }
        },
        solved_vector = { 0, 0, 0, 0 }
    }
end

local function resolve_fast(p17, p18, p19) -- line: 307
    -- upvalues: BodyId (copy), BoardRuntime (copy), SkeletonBody (copy), decode_contact_id (copy)
    local v33, v34 = decode_contact_id(p17)

    if v33 == 0 then
        return nil
    end

    if v33 == 1 then
        return BoardRuntime.bodies(p18.board)[BodyId.index(v34) + 1]
    end

    local v35 = SkeletonBody.bodies(p19.skeleton)

    if v34 < #v35 then
        return v35[v34 + 1]
    end

    local v36 = v34 - #v35
    local bodies = p19.skeleton_drives.targets.bodies

    if v36 < #bodies then
        return bodies[v36 + 1]
    end

    local v37 = v36 - #bodies

    return p18.network_proxies.bodies[v37 + 1]
end

local function spy_center(p20, p21, p22) -- line: 330
    -- upvalues: to_bits (copy), resolve_fast (copy)
    local v38 = resolve_fast(p22, p20, p21)

    if v38 == nil then
        return 0, 0, 0, 0
    end

    local position = v38.rates.position

    return to_bits(position.x), to_bits(position.y), to_bits(position.z), 0
end

local function is_mod_solid_fast(p23, p24) -- line: 340
    -- upvalues: decode_contact_id (copy)
    local v39, v40 = decode_contact_id(p23)

    if v39 == 2 then
        for _, v41 in ipairs(p24.network_proxies.solids) do
            if v41[1] == v40 then
                return true
            end
        end
    end

    return false
end

local function contact_body_into(p25, p26, p27, p28) -- line: 355
    local linear_velocity = p25.linear_velocity

    if p26 ~= nil then
        if p28 then
            local rates = p26.rates
            local position = rates.position
            local v42 = p27[1] - position.x
            local v43 = p27[2] - position.y
            local v44 = p27[3] - position.z
            local angular_velocity, linear_velocity2 = rates.angular_velocity, rates.linear_velocity

            linear_velocity[1] = linear_velocity2.x + angular_velocity.y * v44 - angular_velocity.z * v43
            linear_velocity[2] = linear_velocity2.y + angular_velocity.z * v42 - angular_velocity.x * v44
            linear_velocity[3] = linear_velocity2.z + angular_velocity.x * v43 - angular_velocity.y * v42
        else
            local linear_velocity2 = p26.rates.linear_velocity
            local x, y, z = linear_velocity2.x, linear_velocity2.y, linear_velocity2.z

            linear_velocity[1] = x
            linear_velocity[2] = y
            linear_velocity[3] = z
        end

        linear_velocity[4] = 0
        p25.state_flags = p26.state_flags
        p25.inverse_mass = p26.inertia.inverse_mass
    else
        p25.state_flags = 1
        p25.inverse_mass = 0
        linear_velocity[1] = 0
        linear_velocity[2] = 0
        linear_velocity[3] = 0
        linear_velocity[4] = 0
    end
end

local function collect_impl(p29, p30, p31) -- line: 383
    -- upvalues: BoardRuntime (copy), RetailContactJacobian (copy), SkeletonBody (copy), decode_contact_id (copy), spy_contact_jacobians_scalar (copy), from_bits (copy), t4 (copy), t5 (copy), t6 (copy), t7 (copy), new_report (copy), resolve_fast (copy), spy_center (copy), contact_body_into (copy)
    local v45 = BoardRuntime.solved_contacts(p29.board)
    local v46 = #v45
    local v47 = t4

    if v46 * 64 > 8192 then
        v47 = table.create(v46 * 64)
    end

    local n1 = 0

    for _, v48 in ipairs(v45) do
        local v49 = RetailContactJacobian.words(v48)
        local v50 = #v49

        table.move(v49, 1, v50, n1 + 1, v47)
        n1 += v50
    end

    if not (v46 * 64 <= n1) then
        error("assertion failed: storage.len() >= contact_count as usize * 64", 0)
    end

    local v51 = spy_contact_jacobians_scalar(v47, v46, 0, p29.settings.step.simulation.frequency, spy_center, p29, p30)
    local v52, t8

    if p31 then
        v52 = t6
        t8 = t7
        table.clear(t6)
        table.clear(t7)
    else
        v52 = table.create(16)
        t8 = {}
    end

    local v53 = v51 - 1
    local n2 = 0

    for i = 0, v53 do
        local v54 = i * 28
        local v55 = v47[v54 + 25]
        local v56 = v47[v54 + 26]
        local v57, v58 = decode_contact_id(v55)
        local v59, v60 = decode_contact_id(v56)
        local v61 = #SkeletonBody.bodies(p30.skeleton) + #p30.skeleton_drives.targets.bodies
        local v62 = n2

        if v57 == 0 or v57 == 2 and v61 <= v58 or v59 == 0 or v59 == 2 and v61 <= v60 then
            v62 = n2

            for j = 1, 2 do
                local v63, v64, v65, v66, v67

                if j == 1 then
                    v63 = v57
                    v64 = v58
                    v66 = v59
                    v67 = v60
                    v65 = true
                else
                    v63 = v59
                    v64 = v60
                    v66 = v57
                    v67 = v58
                    v65 = false
                end

                local v68, v69, v70

                if v63 ~= 2 or v64 >= 24 then
                    v70 = v62
                else
                    if p31 and v62 < 64 then
                        v68 = v62 + 1
                        v69 = t5[v68]

                        if v69 == nil then
                            v69 = new_report()
                            t5[v68] = v69
                        end
                    else
                        v68 = v62
                        v69 = new_report()
                    end

                    local point = v69.point

                    point[1] = from_bits(v47[v54 + 13])
                    point[2] = from_bits(v47[v54 + 14])
                    point[3] = from_bits(v47[v54 + 15])
                    point[4] = from_bits(v47[v54 + 16])

                    local v71 = if v65 then 1 else -1
                    local normal = v69.normal

                    normal[1] = from_bits(v47[v54 + 1]) * v71
                    normal[2] = from_bits(v47[v54 + 2]) * v71
                    normal[3] = from_bits(v47[v54 + 3]) * v71
                    normal[4] = from_bits(v47[v54 + 4]) * v71

                    local v72

                    if v66 == 0 then
                        v72 = 0
                    elseif v66 == 1 then
                        v72 = BoardRuntime.collision_group(p29.board)
                    else
                        local v73 = p29.network_proxies.groups[v67]

                        if v73 == nil then
                            v73 = p30.skeleton_collision.assembly_group
                        end

                        v72 = v73
                    end

                    local v74 = false

                    if v66 == 2 then
                        for _, v75 in ipairs(p29.network_proxies.solids) do
                            if v75[1] == v67 then
                                v74 = true
                                break
                            end

                            v74 = false
                        end
                    end

                    local v76 = if v74 then t8 else v52
                    local v77 = v72 == 8
                    local v78 = v47[v54 + 27]

                    v69.part = v64

                    if v65 then
                        v69.tag = bit32.band(v78, 65535)
                    else
                        v69.tag = bit32.rshift(v78, 16)
                    end

                    v69.other_group = v72

                    local body_a = v69.body_a
                    local v79 = resolve_fast(v55, p29, p30)
                    local v80 = v77

                    if v77 then
                        local v81, v82 = decode_contact_id(v55)

                        v80 = false

                        if v81 == 2 then
                            for _, v83 in ipairs(p29.network_proxies.solids) do
                                if v83[1] == v82 then
                                    v80 = true
                                    break
                                end

                                v80 = false
                            end
                        end
                    end

                    contact_body_into(body_a, v79, point, v80)

                    local body_b = v69.body_b
                    local v84 = resolve_fast(v56, p29, p30)

                    if v77 then
                        local v85, v86 = decode_contact_id(v56)

                        v77 = false

                        if v85 == 2 then
                            for _, v87 in ipairs(p29.network_proxies.solids) do
                                if v87[1] == v86 then
                                    v77 = true
                                    break
                                end

                                v77 = false
                            end
                        end
                    end

                    v70 = v68
                    contact_body_into(body_b, v84, point, v77)
                    v69.side_a = v65

                    local solved_vector = v69.solved_vector

                    solved_vector[1] = from_bits(v47[v54 + 21])
                    solved_vector[2] = from_bits(v47[v54 + 22])
                    solved_vector[3] = from_bits(v47[v54 + 23])
                    solved_vector[4] = from_bits(v47[v54 + 24])
                    table.insert(v76, v69)
                end

                v62 = v70
            end
        end

        n2 = v62
    end

    for _, v88 in ipairs(v52) do
        table.insert(t8, v88)
    end

    for i = #t8, 17, -1 do
        t8[i] = nil
    end

    return t8
end

function t1.collect(p32, p33) -- line: 523
    -- upvalues: collect_impl (copy)
    return (collect_impl(p32, p33, false))
end

function t1.collect_scratch(p34, p35) -- line: 531
    -- upvalues: collect_impl (copy)
    return (collect_impl(p34, p35, true))
end

function t1.collect_reference(p36, p37) -- line: 539
    -- upvalues: rt (copy), v1 (copy), BoardRuntime (copy), CollisionBody (copy), spy_contact_jacobians (copy), RetailContactJacobian (copy), SkeletonBody (copy), t1 (copy)
    local v89 = BoardRuntime.solved_contacts(p36.board)
    local t9 = {}

    for _, v90 in ipairs(v89) do
        for _, v91 in ipairs(RetailContactJacobian.words(v90)) do
            table.insert(t9, v91)
        end
    end

    local v93 = spy_contact_jacobians(t9, #v89, 0, p36.settings.step.simulation.frequency, function(p38) -- line: 548
        -- upvalues: p36 (copy), p37 (copy), v1 (copy), t1 (copy)
        local v94 = t1.resolve(p38, p36, p37)

        if v94 == nil then
            return { 0, 0, 0, 0 }
        end

        local position = v94.rates.position
        local x = position.x
        local v95

        if x ~= 0 and x > -1.1754943508222875E-38 and x < 1.1754943508222875E-38 then
            local v96 = math.abs(x) * 7.1362384635298E+44
            local v97 = math.floor(v96)
            local v98 = v96 - v97

            v95 = if v98 > 0.5 or v98 == 0.5 and v97 % 2 == 1 then v97 + 1 else v97

            if x < 0 then
                v95 += 2147483648
            end
        else
            buffer.writef32(v1, 0, x)
            v95 = buffer.readu32(v1, 0)
        end

        local y = position.y
        local v99

        if y ~= 0 and y > -1.1754943508222875E-38 and y < 1.1754943508222875E-38 then
            local v100 = math.abs(y) * 7.1362384635298E+44
            local v101 = math.floor(v100)
            local v102 = v100 - v101

            v99 = if v102 > 0.5 or v102 == 0.5 and v101 % 2 == 1 then v101 + 1 else v101

            if y < 0 then
                v99 += 2147483648
            end
        else
            buffer.writef32(v1, 0, y)
            v99 = buffer.readu32(v1, 0)
        end

        local z = position.z
        local v103

        if z ~= 0 and z > -1.1754943508222875E-38 and z < 1.1754943508222875E-38 then
            local v104 = math.abs(z) * 7.1362384635298E+44
            local v105 = math.floor(v104)
            local v106 = v104 - v105

            v103 = if v106 > 0.5 or v106 == 0.5 and v105 % 2 == 1 then v105 + 1 else v105

            if z < 0 then
                v103 += 2147483648
            end
        else
            buffer.writef32(v1, 0, z)
            v103 = buffer.readu32(v1, 0)
        end

        return {
            v95,
            v99,
            v103,
            0
        }
    end)
    local v107 = table.create(16)
    local t11 = {}

    for i = 0, v93 - 1 do
        local v108 = i * 28
        local v109 = CollisionBody.from_contact_id(t9[v108 + 24 + 1])
        local v110 = CollisionBody.from_contact_id(t9[v108 + 25 + 1])
        local v111 = #SkeletonBody.bodies(p37.skeleton) + #p37.skeleton_drives.targets.bodies

        if not (v109.tag ~= "StaticWorld" and (v109.tag ~= "Attached" or not (v111 <= v109[1])) and not (v110.tag == "StaticWorld" or v110.tag == "Attached" and v111 <= v110[1])) then
            local t12 = {
                { v109, v110, true },
                { v110, v109, false }
            }

            for _, v113 in ipairs(t12) do
                local v114 = v113[1]
                local v115 = v113[2]
                local v116 = v113[3]

                if v114.tag == "Attached" then
                    local v117 = v114[1]

                    if not (v117 >= 24) then
                        local function vector(p39) -- line: 583
                            -- upvalues: t9 (copy), v108 (copy), v1 (copy)
                            buffer.writeu32(v1, 0, t9[v108 + p39 + 1])

                            local v119 = buffer.readf32(v1, 0)

                            buffer.writeu32(v1, 0, t9[v108 + p39 + 2])

                            local v121 = buffer.readf32(v1, 0)

                            buffer.writeu32(v1, 0, t9[v108 + p39 + 3])

                            local v123 = buffer.readf32(v1, 0)

                            buffer.writeu32(v1, 0, t9[v108 + p39 + 4])

                            return {
                                v119,
                                v121,
                                v123,
                                (buffer.readf32(v1, 0))
                            }
                        end

                        local v125 = vector(12)
                        local v126 = if v116 then 1 else -1
                        local v127 = rt.map(vector(0), function(p40) -- line: 593
                            -- upvalues: v126 (copy)
                            return p40 * v126
                        end)
                        local v128

                        if v115.tag == "StaticWorld" then
                            v128 = 0
                        elseif v115.tag == "Board" then
                            v128 = BoardRuntime.collision_group(p36.board)
                        else
                            v128 = p36.network_proxies.groups[v115[1]]

                            if v128 == nil then
                                v128 = p37.skeleton_collision.assembly_group
                            end
                        end

                        local v129 = false

                        if v115.tag == "Attached" then
                            for _, v130 in ipairs(p36.network_proxies.solids) do
                                if v130[1] == v115[1] then
                                    v129 = true
                                    break
                                end

                                v129 = false
                            end
                        end

                        local v131 = if v129 then t11 else v107
                        local v132 = v128 == 8
                        local v133 = t9[v108 + 26 + 1]

                        table.insert(v131, {
                            other_entity = nil,
                            part = v117,
                            normal = v127,
                            point = rt.copy(v125),
                            tag = if v116 then bit32.band(v133, 65535) else bit32.rshift(v133, 16),
                            other_group = v128,
                            body_a = t1.contact_body(t1.resolve(t9[v108 + 24 + 1], p36, p37), v125, v132 and t1.is_mod_solid_contact(t9[v108 + 24 + 1], p36)),
                            body_b = t1.contact_body(t1.resolve(t9[v108 + 25 + 1], p36, p37), v125, v132 and t1.is_mod_solid_contact(t9[v108 + 25 + 1], p36)),
                            side_a = v116,
                            solved_vector = vector(20)
                        })
                    end
                end
            end
        end
    end

    for _, v134 in ipairs(v107) do
        table.insert(t11, v134)
    end

    for i = #t11, 17, -1 do
        t11[i] = nil
    end

    return t11
end

function t1.is_mod_solid_contact(p41, p42) -- line: 656
    -- upvalues: CollisionBody (copy)
    local v135 = CollisionBody.from_contact_id(p41)

    if v135.tag == "Attached" then
        for _, v136 in ipairs(p42.network_proxies.solids) do
            if v136[1] == v135[1] then
                return true
            end
        end
    end

    return false
end

function t1.resolve(p43, p44, p45) -- line: 669
    -- upvalues: BodyId (copy), BoardRuntime (copy), CollisionBody (copy), SkeletonBody (copy)
    local v137 = CollisionBody.from_contact_id(p43)

    if v137.tag == "StaticWorld" then
        return nil
    end

    if v137.tag == "Board" then
        return BoardRuntime.bodies(p44.board)[BodyId.index(v137[1]) + 1]
    end

    local v138 = v137[1]
    local v139 = SkeletonBody.bodies(p45.skeleton)

    if v138 < #v139 then
        return v139[v138 + 1]
    end

    local v140 = v138 - #v139
    local bodies = p45.skeleton_drives.targets.bodies

    if v140 < #bodies then
        return bodies[v140 + 1]
    end

    local v141 = v140 - #bodies

    return p44.network_proxies.bodies[v141 + 1]
end

function t1.contact_body(p46, p47, p48) -- line: 692
    -- upvalues: t1 (copy)
    if p46 == nil then
        return {
            state_flags = 1,
            inverse_mass = 0,
            linear_velocity = { 0, 0, 0, 0 }
        }
    end

    local v142

    if p48 then
        v142 = t1.linear_velocity_at_point(p46, p47)
    else
        local linear_velocity = p46.rates.linear_velocity

        v142 = {
            linear_velocity.x,
            linear_velocity.y,
            linear_velocity.z,
            0
        }
    end

    return {
        state_flags = p46.state_flags,
        inverse_mass = p46.inertia.inverse_mass,
        linear_velocity = v142
    }
end

function t1.linear_velocity_at_point(p49, p50) -- line: 718
    local t14 = {
        p50[1] - p49.rates.position.x,
        p50[2] - p49.rates.position.y,
        p50[3] - p49.rates.position.z,
        0
    }
    local angular_velocity, linear_velocity = p49.rates.angular_velocity, p49.rates.linear_velocity

    return {
        linear_velocity.x + angular_velocity.y * t14[3] - angular_velocity.z * t14[2],
        linear_velocity.y + angular_velocity.z * t14[1] - angular_velocity.x * t14[3],
        linear_velocity.z + angular_velocity.x * t14[2] - angular_velocity.y * t14[1],
        0
    }
end

return t1
