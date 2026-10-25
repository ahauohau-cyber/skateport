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
local Vector3 = import("skate_core/math").Vector3
local v1 = import("skate_core/physics/assembly")
local BoardConstraints, prepare_drive_frames = v1.BoardConstraints, v1.prepare_drive_frames
local v2 = import("skate_core/physics/board")
local BODY_COUNT, BodyId = v2.BODY_COUNT, v2.BodyId
local v3 = import("skate_core/physics/contact")
local generate_contact = v3.generate_contact
local v4 = import("skate_core/physics/contact_feedback/board_reports")
local build_contact_jacobian = import("skate_core/physics/contact_solver").build_contact_jacobian
local BoardForceQueue = import("skate_core/physics/force_queue").BoardForceQueue
local v5 = import("skate_core/physics/rigid_body")
local RetailReactionCorrections, integrate_body_rates, integrate_body_rates_state, integrate_body_rates_into = v5.RetailReactionCorrections, v5.integrate_body_rates, v5.integrate_body_rates_state, v5.integrate_body_rates_into
local rates_buffer, pack_world_inverse_inertia = v5.rates_buffer, v5.pack_world_inverse_inertia
local solve_constraints = import("skate_core/physics/solver").solve_constraints
local contact_rows = import("skate_core/physics/solver/packed").contact_rows
local v6 = import("skate_core/physics/native_arithmetic")
local v7 = import("skate_core/physics/reciprocal_sqrt")
local to_bits, from_bits = rt.to_bits, rt.from_bits
local t1 = {
    ATTACHED_REACTION_BASE = BODY_COUNT + 1,
    AttachedStep = {}
}

function t1.AttachedStep.world_reaction(p2) -- line: 65
    -- upvalues: t1 (copy)
    return t1.ATTACHED_REACTION_BASE + #p2.bodies
end

t1.BoardCollision = {}
t1.CollisionBody = {}

function t1.CollisionBody.eq(p3, p4) -- line: 81
    if p3.tag == p4.tag then
        return p3[1] == p4[1]
    end

    return false
end

function t1.CollisionBody.contact_id(p5) -- line: 85
    -- upvalues: BodyId (copy), t1 (copy)
    if p5.tag == "Board" then
        return BodyId.index(p5[1])
    end

    if p5.tag ~= "Attached" then
        return 4294967295
    end

    local v8 = t1.ATTACHED_REACTION_BASE + p5[1]

    if v8 > 4294967295 then
        error("attached contact body index exceeds host storage", 0)
    end

    return v8
end

function t1.CollisionBody.from_contact_id(p6) -- line: 99
    -- upvalues: BODY_COUNT (copy), BodyId (copy), t1 (copy)
    if p6 == 4294967295 then
        return {
            tag = "StaticWorld"
        }
    end

    if p6 < BODY_COUNT then
        return {
            tag = "Board",
            BodyId.ORDER[p6 + 1]
        }
    end

    if not (t1.ATTACHED_REACTION_BASE <= p6) then
        error("board target has no collision volume", 0)
    end

    return {
        tag = "Attached",
        p6 - t1.ATTACHED_REACTION_BASE
    }
end

function t1.CollisionBody.decode_contact_id(p7) -- line: 116
    -- upvalues: BODY_COUNT (copy), BodyId (copy), t1 (copy)
    if p7 == 4294967295 then
        return 0, nil
    end

    if p7 < BODY_COUNT then
        return 1, BodyId.ORDER[p7 + 1]
    end

    if not (t1.ATTACHED_REACTION_BASE <= p7) then
        error("board target has no collision volume", 0)
    end

    return 2, p7 - t1.ATTACHED_REACTION_BASE
end

t1.BoardStepSettings = {}
t1.BoardStep = {}

function t1.BoardStep.default() -- line: 152
    return {
        diagnostic_capture = false,
        diagnostic_tick = 0,
        diagnostic_snapshot = nil,
        contacts = {},
        reports = {},
        reactions = {},
        solved_reactions = {}
    }
end

function t1.BoardStep.solved_reactions(p8) -- line: 166
    return p8.solved_reactions
end

function t1.BoardStep.contact_reports(p9) -- line: 170
    return p9.reports
end

function t1.BoardStep.solved_contacts(p10) -- line: 174
    return p10.contacts
end

function t1.BoardStep.advance(p11, p12, p13, p14, p15, p16, p17) -- line: 181
    -- upvalues: t1 (copy)
    t1.BoardStep.advance_attached(p11, p12, p13, p14, p15, p16, p17, {
        bodies = {},
        contacts = {},
        joints = {},
        drives = {}
    })
end

local t2 = {}
local n1 = 0
local t3 = {}
local n2 = 0
local t4 = {}
local n3 = 0
local t5 = {}
local self = setmetatable({}, {
    __mode = "k"
})
local v10, v11
local t8 = {}

local function integrate_recycled(p18, p19, p20, p21) -- line: 278
    -- upvalues: integrate_body_rates_state (copy), integrate_body_rates_into (copy), rates_buffer (copy), t8 (copy)
    local rates = p19.rates
    local v12 = t8[p18]
    local v13

    if v12 == nil or v12.current.rates ~= rates then
        v12 = nil
    else
        v13 = v12.spare
    end

    if v13 == nil then
        v13 = rates_buffer()
    end

    local v14 = integrate_body_rates_into(v13, rates, p19.inertia, p20, p21)

    if v14 == nil then
        t8[p18] = nil

        return integrate_body_rates_state(rates, p19.inertia, p20, p21)
    end

    if v12 ~= nil then
        v12.spare = v12.current
        v12.current = v13
    else
        t8[p18] = {
            spare = nil,
            current = v13
        }
    end

    return v14
end

local function zero_reaction(p22) -- line: 306
    local linear_displacement, position_displacement, angular_displacement, orientation_displacement = p22.linear_displacement, p22.position_displacement, p22.angular_displacement, p22.orientation_displacement

    if linear_displacement == nil or position_displacement == nil or angular_displacement == nil or orientation_displacement == nil then
        return false
    end

    linear_displacement.x = 0
    linear_displacement.y = 0
    linear_displacement.z = 0
    position_displacement.x = 0
    position_displacement.y = 0
    position_displacement.z = 0
    angular_displacement.x = 0
    angular_displacement.y = 0
    angular_displacement.z = 0
    orientation_displacement.x = 0
    orientation_displacement.y = 0
    orientation_displacement.z = 0

    return true
end

local function reset_reactions(p23, p24) -- line: 324
    for i = 1, p24 do
        local v15 = p23[i]
        local v16 = false

        if v15 ~= nil then
            local linear_displacement, position_displacement, angular_displacement, orientation_displacement = v15.linear_displacement, v15.position_displacement, v15.angular_displacement, v15.orientation_displacement
            local v17

            if linear_displacement == nil or position_displacement == nil or angular_displacement == nil or orientation_displacement == nil then
                v17 = false
            else
                linear_displacement.x = 0
                linear_displacement.y = 0
                linear_displacement.z = 0
                position_displacement.x = 0
                position_displacement.y = 0
                position_displacement.z = 0
                angular_displacement.x = 0
                angular_displacement.y = 0
                angular_displacement.z = 0
                orientation_displacement.x = 0
                orientation_displacement.y = 0
                v17 = true
                orientation_displacement.z = 0
            end

            v16 = not not v17
        end

        if not v16 then
            p23[i] = {
                linear_displacement = {
                    x = 0,
                    y = 0,
                    z = 0
                },
                position_displacement = {
                    x = 0,
                    y = 0,
                    z = 0
                },
                angular_displacement = {
                    x = 0,
                    y = 0,
                    z = 0
                },
                orientation_displacement = {
                    x = 0,
                    y = 0,
                    z = 0
                }
            }
        end
    end

    for i = #p23, p24 + 1, -1 do
        p23[i] = nil
    end
end

local function release_step_storage(p25) -- line: 342
    -- upvalues: t3 (copy), n2 (ref), t4 (copy), n3 (ref)
    local contacts = p25.contacts
    local v18 = n2

    for i = 1, #contacts do
        if v18 >= 128 then
            break
        end

        v18 += 1
        t3[v18] = contacts[i]
    end

    n2 = v18

    local solved_reactions = p25.solved_reactions
    local v19 = n3

    for i = 1, #solved_reactions do
        if v19 >= 128 then
            break
        end

        v19 += 1
        t4[v19] = solved_reactions[i]
    end

    n3 = v19
end

function t1.BoardStep.advance_attached(p26, p27, p28, p29, p30, p31, p32, p33) -- line: 365
    -- upvalues: rt (copy), BoardConstraints (copy), prepare_drive_frames (copy), BODY_COUNT (copy), BodyId (copy), v4 (copy), solve_constraints (copy), contact_rows (copy), t1 (copy), t2 (copy), n1 (ref), t3 (copy), n2 (ref), t4 (copy), n3 (ref), t5 (copy), self (copy), v10 (ref), v11 (ref), integrate_recycled (copy), reset_reactions (copy), release_step_storage (copy)
    local v20 = rt.copy(p32.simulation)
    local time_step = v20.time_step

    if not (time_step == time_step and time_step ~= 1e999 and time_step ~= (-1e999) and v20.time_step > 0) then
        error("assertion failed: simulation.time_step.is_finite() && simulation.time_step > 0.0", 0)
    end

    v20.frequency = 1 / v20.time_step

    for _, v21 in p30 do
        if t1.CollisionBody.eq(v21.body_a, v21.body_b) then
            error("assertion `left != right` failed", 0)
        end
    end

    t1.apply_deck_forces(p27, p29, p32.force_point_y_offset)

    local v22 = prepare_drive_frames(rt.copy(p32.base_truck_transforms), rt.copy(p31), p28)
    local v23 = t1.AttachedStep.world_reaction(p33)

    reset_reactions(p26.reactions, v23 + 1)
    release_step_storage(p26)
    table.clear(p26.contacts)
    table.clear(p26.reports)
    table.clear(p26.solved_reactions)

    local v24 = true

    for i = 1, BODY_COUNT do
        if bit32.band(p27[i].state_flags, 4) ~= 0 then
            v24 = false
            break
        end
    end

    if v24 and bit32.band(p28.body.state_flags, 4) ~= 0 then
        v24 = false
    end

    if v24 then
        for _, v25 in p33.bodies do
            if bit32.band(v25.state_flags, 4) ~= 0 then
                v24 = false
                break
            end
        end
    end

    if v24 then
        return
    end

    table.clear(t5)

    local contacts = p26.contacts
    local bodies = p33.bodies
    local time_step2 = v20.time_step

    v11()

    local n4 = 0

    for _, v26 in p30 do
        local v27, words

        if n2 > 0 then
            v27 = t3[n2]
            t3[n2] = nil
            n2 -= 1
            words = v27.words

            if not self[words] then
                words = nil
            end
        else
            v27 = {}
        end

        if words == nil then
            if n1 > 0 then
                words = t2[n1]
                t2[n1] = nil
                n1 -= 1
            else
                words = table.create(64, 0)
                self[words] = true
            end
        end

        local v28 = contact_rows[n4 + 1]

        if v28 == nil then
            v28 = table.create(65, 0)
            contact_rows[n4 + 1] = v28
        end

        local v29, v30 = v10(words, v28, v26, p27, bodies, v23, time_step2)

        v27.words = words
        v27.reaction_index_a = v29
        v27.reaction_index_b = v30
        n4 += 1
        t5[n4] = words
        contacts[n4] = v27
    end

    local v31 = BoardConstraints.build(p27, p28, v22, rt.copy(p32.truck_dynamics), v20.time_step)
    local v32 = #p26.contacts
    local v33 = #v31.joints
    local v34 = #v31.drives

    for _, v35 in p33.contacts do
        table.insert(p26.contacts, rt.copy(v35))
    end

    for _, v36 in p33.joints do
        table.insert(v31.joints, v36)
    end

    for _, v37 in p33.drives do
        table.insert(v31.drives, v37)
    end

    solve_constraints(p26.contacts, v31.joints, v31.drives, p26.reactions, p32.iterations, true, n4)

    local contacts2 = p26.contacts

    for i = 1, n4 do
        local v38 = t5[i]

        t5[i] = nil

        if contacts2[i].words ~= v38 and n1 < 128 then
            n1 += 1
            t2[n1] = v38
        end
    end

    p26.diagnostic_tick += 1

    if p26.diagnostic_capture and rt.irem(p26.diagnostic_tick, 6) == 0 then
        local v39 = BodyId.index(BodyId.Deck)
        local t9 = {}

        for i = 0, #v31.joints - 1 do
            local v40 = v31.joints[i + 1]

            if v40.reaction_a == v39 or v40.reaction_b == v39 then
                table.insert(t9, (("(%*, %*, %*)"):format(i, v40.reaction_a, v40.reaction_b)))
            end
        end

        local t10 = {}

        for i = 0, #v31.drives - 1 do
            local v42 = v31.drives[i + 1]

            if v42.frame_a_body.reaction_index == v39 or v42.frame_b_body.reaction_index == v39 then
                table.insert(t10, (tostring(i)))
            end
        end

        local position, linear_velocity = p27[v39 + 1].rates.position, p27[v39 + 1].rates.linear_velocity
        local linear_displacement = p26.reactions[v39 + 1].linear_displacement
        local v44 = table.concat(t9, ", ")
        local v45 = table.concat(t10, ", ")

        p26.diagnostic_snapshot = ("tick=%* body=(position=(%*, %*, %*) linear_velocity=(%*, %*, %*))"):format(p26.diagnostic_tick, position.x, position.y, position.z, linear_velocity.x, linear_velocity.y, linear_velocity.z) .. (" reaction=(linear_displacement=(%*, %*, %*)) joints=[%*] drives=[%*]"):format(linear_displacement.x, linear_displacement.y, linear_displacement.z, v44, v45)
    end

    table.clear(p26.solved_reactions)

    local solved_reactions = p26.solved_reactions

    for v46, v47 in p26.reactions do
        local linear_displacement, position_displacement, angular_displacement, orientation_displacement = v47.linear_displacement, v47.position_displacement, v47.angular_displacement, v47.orientation_displacement
        local v48

        if n3 > 0 then
            v48 = t4[n3]
            t4[n3] = nil
            n3 -= 1
        end

        local linear_displacement2, position_displacement2, angular_displacement2, orientation_displacement2

        if v48 ~= nil then
            linear_displacement2 = v48.linear_displacement
            position_displacement2 = v48.position_displacement
            angular_displacement2 = v48.angular_displacement
            orientation_displacement2 = v48.orientation_displacement
        end

        if linear_displacement2 == nil or position_displacement2 == nil or angular_displacement2 == nil or orientation_displacement2 == nil then
            solved_reactions[v46] = {
                linear_displacement = {
                    x = linear_displacement.x,
                    y = linear_displacement.y,
                    z = linear_displacement.z
                },
                position_displacement = {
                    x = position_displacement.x,
                    y = position_displacement.y,
                    z = position_displacement.z
                },
                angular_displacement = {
                    x = angular_displacement.x,
                    y = angular_displacement.y,
                    z = angular_displacement.z
                },
                orientation_displacement = {
                    x = orientation_displacement.x,
                    y = orientation_displacement.y,
                    z = orientation_displacement.z
                }
            }
        else
            local x, y, z = linear_displacement.x, linear_displacement.y, linear_displacement.z

            linear_displacement2.x = x
            linear_displacement2.y = y
            linear_displacement2.z = z

            local x2, y2, z2 = position_displacement.x, position_displacement.y, position_displacement.z

            position_displacement2.x = x2
            position_displacement2.y = y2
            position_displacement2.z = z2

            local x3, y3, z3 = angular_displacement.x, angular_displacement.y, angular_displacement.z

            angular_displacement2.x = x3
            angular_displacement2.y = y3
            angular_displacement2.z = z3

            local x4, y4, z4 = orientation_displacement.x, orientation_displacement.y, orientation_displacement.z

            orientation_displacement2.x = x4
            orientation_displacement2.y = y4
            orientation_displacement2.z = z4
            solved_reactions[v46] = v48
        end
    end

    local v49 = #p33.bodies

    for i = 0, math.min(BODY_COUNT + 1 + v49, #p26.reactions) - 1 do
        local v52 = if i < BODY_COUNT then p27[i + 1] elseif i == BODY_COUNT then p28.body else p33.bodies[i - BODY_COUNT]

        if bit32.band(v52.state_flags, 4) ~= 0 then
            v52.rates = integrate_recycled(i + 1, v52, v20, p26.reactions[i + 1])
        end

        local v53 = p26.reactions[i + 1]
        local linear_displacement, position_displacement, angular_displacement, orientation_displacement = v53.linear_displacement, v53.position_displacement, v53.angular_displacement, v53.orientation_displacement

        if linear_displacement ~= nil and position_displacement ~= nil and angular_displacement ~= nil and orientation_displacement ~= nil then
            linear_displacement.x = 0
            linear_displacement.y = 0
            linear_displacement.z = 0
            position_displacement.x = 0
            position_displacement.y = 0
            position_displacement.z = 0
            angular_displacement.x = 0
            angular_displacement.y = 0
            angular_displacement.z = 0
            orientation_displacement.x = 0
            orientation_displacement.y = 0
            orientation_displacement.z = 0
        else
            v53.linear_displacement = {
                x = 0,
                y = 0,
                z = 0
            }
            v53.position_displacement = {
                x = 0,
                y = 0,
                z = 0
            }
            v53.angular_displacement = {
                x = 0,
                y = 0,
                z = 0
            }
            v53.orientation_displacement = {
                x = 0,
                y = 0,
                z = 0
            }
        end
    end

    v4.collect(p26.reports, p26.contacts, p27, p33.bodies, v20.frequency)

    for i = 0, #p33.contacts - 1 do
        p33.contacts[i + 1] = rt.copy(p26.contacts[v32 + i + 1])
    end

    for i = 0, #p33.joints - 1 do
        p33.joints[i + 1] = v31.joints[v33 + i + 1]
    end

    for i = 0, #p33.drives - 1 do
        p33.drives[i + 1] = v31.drives[v34 + i + 1]
    end
end

function t1.BoardStep.advance_attached_reference(p34, p35, p36, p37, p38, p39, p40, p41) -- line: 666
    -- upvalues: rt (copy), BoardConstraints (copy), prepare_drive_frames (copy), BODY_COUNT (copy), BodyId (copy), generate_contact (copy), v4 (copy), build_contact_jacobian (copy), RetailReactionCorrections (copy), integrate_body_rates (copy), solve_constraints (copy), t1 (copy)
    local v54 = rt.copy(p40.simulation)
    local time_step = v54.time_step

    if not (time_step == time_step and time_step ~= 1e999 and time_step ~= (-1e999) and v54.time_step > 0) then
        error("assertion failed: simulation.time_step.is_finite() && simulation.time_step > 0.0", 0)
    end

    v54.frequency = 1 / v54.time_step

    for _, v55 in p38 do
        if t1.CollisionBody.eq(v55.body_a, v55.body_b) then
            error("assertion `left != right` failed", 0)
        end
    end

    t1.apply_deck_forces(p35, p37, p40.force_point_y_offset)

    local v56 = prepare_drive_frames(rt.copy(p40.base_truck_transforms), rt.copy(p39), p36)
    local v57 = t1.AttachedStep.world_reaction(p41)

    table.clear(p34.reactions)

    for i = 1, v57 + 1 do
        p34.reactions[i] = RetailReactionCorrections.default()
    end

    table.clear(p34.contacts)
    table.clear(p34.reports)
    table.clear(p34.solved_reactions)

    local v58 = true

    for i = 1, BODY_COUNT do
        if bit32.band(p35[i].state_flags, 4) ~= 0 then
            v58 = false
            break
        end
    end

    if v58 and bit32.band(p36.body.state_flags, 4) ~= 0 then
        v58 = false
    end

    if v58 then
        for _, v59 in p41.bodies do
            if bit32.band(v59.state_flags, 4) ~= 0 then
                v58 = false
                break
            end
        end
    end

    if v58 then
        return
    end

    for _, v60 in p38 do
        local v61 = generate_contact(rt.copy(v60.contact), t1.contact_body(v60.body_a, p35, p41.bodies, v57), t1.contact_body(v60.body_b, p35, p41.bodies, v57))

        table.insert(p34.contacts, build_contact_jacobian(v61, v54.time_step))
    end

    local v62 = BoardConstraints.build(p35, p36, v56, rt.copy(p40.truck_dynamics), v54.time_step)
    local v63 = #p34.contacts
    local v64 = #v62.joints
    local v65 = #v62.drives

    for _, v66 in p41.contacts do
        table.insert(p34.contacts, rt.copy(v66))
    end

    for _, v67 in p41.joints do
        table.insert(v62.joints, v67)
    end

    for _, v68 in p41.drives do
        table.insert(v62.drives, v68)
    end

    solve_constraints(p34.contacts, v62.joints, v62.drives, p34.reactions, p40.iterations)
    p34.diagnostic_tick += 1

    if p34.diagnostic_capture and rt.irem(p34.diagnostic_tick, 6) == 0 then
        local v69 = BodyId.index(BodyId.Deck)
        local t16 = {}

        for i = 0, #v62.joints - 1 do
            local v70 = v62.joints[i + 1]

            if v70.reaction_a == v69 or v70.reaction_b == v69 then
                table.insert(t16, (("(%*, %*, %*)"):format(i, v70.reaction_a, v70.reaction_b)))
            end
        end

        local t17 = {}

        for i = 0, #v62.drives - 1 do
            local v72 = v62.drives[i + 1]

            if v72.frame_a_body.reaction_index == v69 or v72.frame_b_body.reaction_index == v69 then
                table.insert(t17, (tostring(i)))
            end
        end

        local position, linear_velocity = p35[v69 + 1].rates.position, p35[v69 + 1].rates.linear_velocity
        local linear_displacement = p34.reactions[v69 + 1].linear_displacement
        local v74 = table.concat(t16, ", ")
        local v75 = table.concat(t17, ", ")

        p34.diagnostic_snapshot = ("tick=%* body=(position=(%*, %*, %*) linear_velocity=(%*, %*, %*))"):format(p34.diagnostic_tick, position.x, position.y, position.z, linear_velocity.x, linear_velocity.y, linear_velocity.z) .. (" reaction=(linear_displacement=(%*, %*, %*)) joints=[%*] drives=[%*]"):format(linear_displacement.x, linear_displacement.y, linear_displacement.z, v74, v75)
    end

    table.clear(p34.solved_reactions)

    for v76, v77 in p34.reactions do
        p34.solved_reactions[v76] = rt.copy(v77)
    end

    local v78 = #p41.bodies

    for i = 0, math.min(BODY_COUNT + 1 + v78, #p34.reactions) - 1 do
        local v81 = if i < BODY_COUNT then p35[i + 1] elseif i == BODY_COUNT then p36.body else p41.bodies[i - BODY_COUNT]

        if bit32.band(v81.state_flags, 4) ~= 0 then
            v81.rates = integrate_body_rates(v81.rates, v81.inertia, v54, p34.reactions[i + 1]).state
        end

        rt.assign(p34.reactions[i + 1], RetailReactionCorrections.default())
    end

    local t18 = {}

    for v82, v83 in p41.bodies do
        t18[v82] = v83
    end

    v4.collect(p34.reports, p34.contacts, p35, t18, v54.frequency)

    for i = 0, #p41.contacts - 1 do
        p41.contacts[i + 1] = rt.copy(p34.contacts[v63 + i + 1])
    end

    for i = 0, #p41.joints - 1 do
        p41.joints[i + 1] = v62.joints[v64 + i + 1]
    end

    for i = 0, #p41.drives - 1 do
        p41.drives[i + 1] = v62.drives[v65 + i + 1]
    end
end

function t1.apply_deck_forces(p42, p43, p44) -- line: 835
    -- upvalues: rt (copy), BodyId (copy), BoardForceQueue (copy)
    local v84 = p42[BodyId.index(BodyId.Deck) + 1]
    local v85 = BoardForceQueue.apply_to_deck(p43, {
        force_acceleration = rt.copy(v84.rates.force_acceleration),
        torque_acceleration = rt.copy(v84.rates.torque_acceleration),
        cool_down = v84.rates.cool_down
    }, v84.rates.basis, v84.inertia.inverse_mass, v84.rates.world_inverse_inertia, p44)

    v84.rates.force_acceleration = rt.copy(v85.force_acceleration)
    v84.rates.torque_acceleration = rt.copy(v85.torque_acceleration)
    v84.rates.cool_down = v85.cool_down
end

function t1.contact_body(p45, p46, p47, p48) -- line: 855
    -- upvalues: rt (copy), Vector3 (copy), BodyId (copy), pack_world_inverse_inertia (copy), t1 (copy)
    if p45.tag == "StaticWorld" then
        return {
            contact_body_id = 4294967295,
            inverse_mass = 0,
            state = 0,
            kinetic_energy = 0,
            cool_down = 0,
            reaction_id = p48,
            center_of_mass = rt.copy(Vector3.ZERO),
            inverse_inertia_full = rt.copy(Vector3.ZERO),
            inverse_inertia_split = rt.copy(Vector3.ZERO),
            force_acceleration = rt.copy(Vector3.ZERO),
            torque_acceleration = rt.copy(Vector3.ZERO),
            linear_velocity = rt.copy(Vector3.ZERO),
            angular_velocity = rt.copy(Vector3.ZERO)
        }
    end

    local v86 = t1.CollisionBody.contact_id(p45)
    local v87

    if p45.tag == "Board" then
        v87 = p46[BodyId.index(p45[1]) + 1]
    elseif p45.tag == "Attached" then
        v87 = p47[p45[1] + 1]

        if v87 == nil then
            error(("index out of bounds: the len is %* but the index is %*"):format(#p47, p45[1]), 0)
        end
    else
        error("internal error: entered unreachable code", 0)
    end

    local v88 = rt.copy(v87.rates)
    local v89 = pack_world_inverse_inertia(v88.world_inverse_inertia)

    return {
        contact_body_id = v86,
        reaction_id = v86,
        center_of_mass = rt.copy(v88.position),
        inverse_inertia_full = rt.copy(v89.full),
        inverse_inertia_split = rt.copy(v89.split),
        inverse_mass = v87.inertia.inverse_mass,
        state = bit32.bor(v87.state_flags, 8),
        force_acceleration = rt.copy(v88.force_acceleration),
        torque_acceleration = rt.copy(v88.torque_acceleration),
        linear_velocity = rt.copy(v88.linear_velocity),
        angular_velocity = rt.copy(v88.angular_velocity),
        kinetic_energy = v88.kinetic_energy,
        cool_down = v88.cool_down
    }
end

local create = vector.create
local v90 = buffer.create(8)

local function round3(p49, p50, p51) -- line: 930
    -- upvalues: to_bits (copy), from_bits (copy), create (copy)
    local v91 = create(p49, p50, p51)
    local x, y, z = v91.x, v91.y, v91.z

    if p49 < 1.1754943508222875E-38 and p49 > -1.1754943508222875E-38 and p49 ~= 0 then
        x = from_bits(to_bits(p49))
    end

    if p50 < 1.1754943508222875E-38 and p50 > -1.1754943508222875E-38 and p50 ~= 0 then
        y = from_bits(to_bits(p50))
    end

    if p51 < 1.1754943508222875E-38 and p51 > -1.1754943508222875E-38 and p51 ~= 0 then
        z = from_bits(to_bits(p51))
    end

    return x, y, z
end

local function word(p52) -- line: 944
    -- upvalues: to_bits (copy), v90 (copy)
    if p52 ~= 0 and p52 > -1.1754943508222875E-38 and p52 < 1.1754943508222875E-38 then
        return to_bits(p52)
    end

    buffer.writef32(v90, 0, p52)

    return (buffer.readu32(v90, 0))
end

local reciprocal_estimate = v6.reciprocal_estimate
local estimate = v7.estimate
local CONTACT_TANGENT_MINIMUM_SQUARED, CONTACT_FALLBACK_HALF = v3.CONTACT_TANGENT_MINIMUM_SQUARED, v3.CONTACT_FALLBACK_HALF
local v92 = table.create(25, 0)
local v93 = table.create(25, 0)

local function fill_contact_body(p53, p54, p55, p56, p57) -- line: 962
    -- upvalues: BodyId (copy), t1 (copy)
    if p54.tag == "StaticWorld" then
        p53[1] = 4294967295
        p53[2] = p57
        p53[3] = 0
        p53[4] = 0
        p53[5] = 0
        p53[6] = 0
        p53[7] = 0
        p53[8] = 0
        p53[9] = 0
        p53[10] = 0
        p53[11] = 0
        p53[12] = 0
        p53[13] = 0
        p53[14] = 0
        p53[15] = 0
        p53[16] = 0
        p53[17] = 0
        p53[18] = 0
        p53[19] = 0
        p53[20] = 0
        p53[21] = 0
        p53[22] = 0
        p53[23] = 0
        p53[24] = 0
        p53[25] = 0
    else
        local v94 = t1.CollisionBody.contact_id(p54)
        local v95

        if p54.tag == "Board" then
            v95 = p55[BodyId.index(p54[1]) + 1]
        elseif p54.tag == "Attached" then
            v95 = p56[p54[1] + 1]

            if v95 == nil then
                error(("index out of bounds: the len is %* but the index is %*"):format(#p56, p54[1]), 0)
            end
        else
            error("internal error: entered unreachable code", 0)
        end

        local rates = v95.rates
        local columns = rates.world_inverse_inertia.columns
        local v96 = columns[1]
        local v97 = columns[2]
        local v98 = columns[3]

        p53[1] = v94
        p53[2] = v94

        local position = rates.position
        local x, y, z = position.x, position.y, position.z

        p53[3] = x
        p53[4] = y
        p53[5] = z

        local v99 = v96[1]
        local v100 = v97[1]
        local v101 = v98[1]

        p53[6] = v99
        p53[7] = v100
        p53[8] = v101

        local v102 = v98[3]
        local v103 = v97[2]
        local v104 = v98[2]

        p53[9] = v102
        p53[10] = v103
        p53[11] = v104
        p53[12] = v95.inertia.inverse_mass
        p53[13] = bit32.bor(v95.state_flags, 8)

        local force_acceleration = rates.force_acceleration
        local x2, y2, z2 = force_acceleration.x, force_acceleration.y, force_acceleration.z

        p53[14] = x2
        p53[15] = y2
        p53[16] = z2

        local torque_acceleration = rates.torque_acceleration
        local x3, y3, z3 = torque_acceleration.x, torque_acceleration.y, torque_acceleration.z

        p53[17] = x3
        p53[18] = y3
        p53[19] = z3

        local linear_velocity = rates.linear_velocity
        local x4, y4, z4 = linear_velocity.x, linear_velocity.y, linear_velocity.z

        p53[20] = x4
        p53[21] = y4
        p53[22] = z4

        local angular_velocity = rates.angular_velocity
        local x5, y5, z5 = angular_velocity.x, angular_velocity.y, angular_velocity.z

        p53[23] = x5
        p53[24] = y5
        p53[25] = z5
    end
end

local function jacobian_response(p58, p59, p60, p61, p62, p63, p64, p65, p66, p67, p68, p69, p70) -- line: 1006
    local v105 = -p60 * p62 + (p59 * p63 + 0)
    local v106 = -p58 * p63 + (p60 * p61 + 0)
    local v107 = -p59 * p61 + (p58 * p62 + 0)

    return v105, v106, v107, p66 * v107 + (p65 * v106 + (p64 * v105 + 0)), p69 * v107 + (p68 * v106 + (p65 * v105 + 0)), p67 * v107 + (p69 * v106 + (p66 * v105 + 0)), p70 * v107 + (p70 * v106 + (p70 * v105 + 0))
end

local function fill_collision_words_w3(p71, p72, p73, p74, p75, p76, p77) -- line: 1039
    -- upvalues: to_bits (copy), from_bits (copy), create (copy), v90 (copy), round3 (copy), reciprocal_estimate (copy), estimate (copy), CONTACT_TANGENT_MINIMUM_SQUARED (copy), CONTACT_FALLBACK_HALF (copy), v92 (copy), v93 (copy), fill_contact_body (copy), jacobian_response (copy)
    local contact = p73.contact

    fill_contact_body(v92, p73.body_a, p74, p75, p76)
    fill_contact_body(v93, p73.body_b, p74, p75, p76)

    local v108 = contact.position_on_a
    local x, y, z = v108.x, v108.y, v108.z

    v108 = contact.position_on_b

    local x2, y2, z2 = v108.x, v108.y, v108.z

    v108 = contact.normal

    local v109, v110, z3 = v108.x, v108.y, v108.z
    local v111 = x - v92[3]
    local v112 = y - v92[4]
    local v113 = z - v92[5]
    local v114 = x2 - v93[3]
    local v115 = y2 - v93[4]
    local v116 = z2 - v93[5]

    v108 = v113 * v92[24] + (-v112 * v92[25] + v92[20])

    local v117 = v111 * v92[25] + (-v113 * v92[23] + v92[21])

    v113 = v112 * v92[23] + (-v111 * v92[24] + v92[22])
    v112 = v116 * v93[24] + (-v115 * v93[25] + v93[20])
    v111 = v114 * v93[25] + (-v116 * v93[23] + v93[21])
    v116 = v115 * v93[23] + (-v114 * v93[24] + v93[22])

    local v118 = v112 - v108
    local v119 = v111 - v117
    local v120 = v116 - v113

    v117 = v119 * z3 + (-v120 * v110 + 0)
    v116 = v120 * v109 + (-v118 * z3 + 0)
    v115 = v118 * v110 + (-v119 * v109 + 0)
    v114 = v115 * v115 + (v116 * v116 + (v117 * v117 + 0))

    local v121

    if not (CONTACT_TANGENT_MINIMUM_SQUARED <= v114) then
        v117 = -v109 * v109 + 1
        v116 = -v110 * v109 + 0
        v115 = -z3 * v109 + 0
        v108 = -v109 * z3 + 0
        v121 = -v110 * z3 + 0
        v114 = -z3 * z3 + 1

        if -v109 * v109 + CONTACT_FALLBACK_HALF >= -0 then
            v114 = v117
        else
            v117 = -v108
            v116 = -v121
            v115 = -v114
        end
    end

    v121 = estimate(v114)

    local v122 = v117 * v121 + 0
    local v123 = v116 * v121 + 0
    local v124 = v115 * v121 + 0
    local v125 = (-v116 * z3 + (v115 * v110 + 0)) * v121 + 0
    local v126 = (-v115 * v109 + (v117 * z3 + 0)) * v121 + 0
    local v127 = (-v117 * v110 + (v116 * v109 + 0)) * v121 + 0

    v111 = p77 == p77 and p77 ~= 1e999 and p77 ~= (-1e999)

    if not (v111 and p77 > 0) then
        error("assertion failed: time_step.is_finite() && time_step > 0.0", 0)
    end

    local v128, v129, v130 = round3(x, y, z)
    local v131, v132, v133 = round3(x2, y2, z2)

    v111, v112, v113 = round3(v109, v110, z3)
    v114, v115, v116 = round3(v122, v123, v124)

    local v134, v135

    v117, v134, v135 = round3(v125, v126, v127)

    local v136, v137, v138 = round3(v118, v119, v120)
    local v139, v140

    v139, v140, v121 = round3(contact.restitution, contact.static_friction, contact.dynamic_friction)

    local v141 = contact.static_friction

    if v141 ~= 0 and v141 > -1.1754943508222875E-38 and v141 < 1.1754943508222875E-38 then
        v127 = to_bits(v141)
    else
        buffer.writef32(v90, 0, v141)
        v127 = buffer.readu32(v90, 0)
    end

    v141 = contact.dynamic_friction

    if v141 ~= 0 and v141 > -1.1754943508222875E-38 and v141 < 1.1754943508222875E-38 then
        v126 = to_bits(v141)
    else
        buffer.writef32(v90, 0, v141)
        v126 = buffer.readu32(v90, 0)
    end

    v141 = v92[13]

    local v142 = v93[13]

    v125 = bit32.band(v141, 4) == 4
    v124 = bit32.band(v142, 4) == 4

    local v143, v144, v145 = round3(v92[3], v92[4], v92[5])
    local v146, v147, v148 = round3(v93[3], v93[4], v93[5])
    local v149 = v128 - v143
    local v150 = v129 - v144
    local v151 = v130 - v145
    local v152 = v131 - v146
    local v153 = v132 - v147
    local v154 = v133 - v148
    local v155, v156, v157

    if v125 and v124 then
        v147 = v92[12]

        local v158 = v93[12]
        local v159 = create(v147, v158, 0)
        local x, y = v159.x, v159.y

        v156 = v159.z

        if v147 < 1.1754943508222875E-38 and v147 > -1.1754943508222875E-38 and v147 ~= 0 then
            x = from_bits(to_bits(v147))
        end

        v157 = x
        v155 = if not (v158 < 1.1754943508222875E-38) or not (v158 > -1.1754943508222875E-38) or v158 == 0 then y else from_bits(to_bits(v158))
    elseif v125 then
        v145 = v92[12]
        v146 = create(v145, 0, 0)

        local x = v146.x

        v147 = v146.y

        local _ = v146.z

        if v145 < 1.1754943508222875E-38 and v145 > -1.1754943508222875E-38 and v145 ~= 0 then
            x = from_bits(to_bits(v145))
        end

        v157 = x
        v155 = 0
    else
        if v124 then
            v145 = v93[12]

            local x = create(v145, 0, 0)
            local x2 = x.x

            v147 = x.y

            local _ = x.z

            if v145 < 1.1754943508222875E-38 and v145 > -1.1754943508222875E-38 and v145 ~= 0 then
                x2 = from_bits(to_bits(v145))
            end

            v155 = x2
        else
            v155 = 0
        end

        v157 = 0
    end

    local v160, v161, v162, v163, v164

    if v125 then
        v156, v160, v161 = round3(v92[6], v92[7], v92[8])
        v162, v163, v164 = round3(v92[9], v92[10], v92[11])
    else
        v156 = 0
        v160 = 0
        v161 = 0
        v162 = 0
        v163 = 0
        v164 = 0
    end

    local v165, v166, v167, v168, v169, v170

    if v124 then
        v165, v166, v167 = round3(v93[6], v93[7], v93[8])
        v168, v169, v170 = round3(v93[9], v93[10], v93[11])
    else
        v165 = 0
        v166 = 0
        v167 = 0
        v168 = 0
        v169 = 0
        v170 = 0
    end

    local v171, v172, v173, v174, v175, v176 = jacobian_response(v149, v150, v151, v111, v112, v113, v156, v160, v161, v162, v163, v164, v157)
    local v177, v178, v179, v180, v181, v182 = jacobian_response(v152, v153, v154, v111, v112, v113, v165, v166, v167, v168, v169, v170, v155)

    v110 = v177 * v180 + (v171 * v174 + 0)
    v177 = v178 * v181 + (v172 * v175 + 0)
    v178 = v179 * v182 + (v173 * v176 + 0)

    local v183 = reciprocal_estimate(v178 + (v110 + v157) + (v177 + v155))
    local v184

    if v174 ~= 0 and v174 > -1.1754943508222875E-38 and v174 < 1.1754943508222875E-38 then
        v184 = to_bits(v174)
    else
        buffer.writef32(v90, 0, v174)
        v184 = buffer.readu32(v90, 0)
    end

    local v185

    if v175 ~= 0 and v175 > -1.1754943508222875E-38 and v175 < 1.1754943508222875E-38 then
        v185 = to_bits(v175)
    else
        buffer.writef32(v90, 0, v175)
        v185 = buffer.readu32(v90, 0)
    end

    local v186

    if v176 ~= 0 and v176 > -1.1754943508222875E-38 and v176 < 1.1754943508222875E-38 then
        v186 = to_bits(v176)
    else
        buffer.writef32(v90, 0, v176)
        v186 = buffer.readu32(v90, 0)
    end

    local v187

    if v157 ~= 0 and v157 > -1.1754943508222875E-38 and v157 < 1.1754943508222875E-38 then
        v187 = to_bits(v157)
    else
        buffer.writef32(v90, 0, v157)
        v187 = buffer.readu32(v90, 0)
    end

    p71[33] = v184
    p71[34] = v185
    p71[35] = v186
    p71[36] = v187

    if v180 ~= 0 and v180 > -1.1754943508222875E-38 and v180 < 1.1754943508222875E-38 then
        v184 = to_bits(v180)
    else
        buffer.writef32(v90, 0, v180)
        v184 = buffer.readu32(v90, 0)
    end

    if v181 ~= 0 and v181 > -1.1754943508222875E-38 and v181 < 1.1754943508222875E-38 then
        v185 = to_bits(v181)
    else
        buffer.writef32(v90, 0, v181)
        v185 = buffer.readu32(v90, 0)
    end

    if v182 ~= 0 and v182 > -1.1754943508222875E-38 and v182 < 1.1754943508222875E-38 then
        v186 = to_bits(v182)
    else
        buffer.writef32(v90, 0, v182)
        v186 = buffer.readu32(v90, 0)
    end

    if v155 ~= 0 and v155 > -1.1754943508222875E-38 and v155 < 1.1754943508222875E-38 then
        v187 = to_bits(v155)
    else
        buffer.writef32(v90, 0, v155)
        v187 = buffer.readu32(v90, 0)
    end

    p71[37] = v184
    p71[38] = v185
    p71[39] = v186
    p71[40] = v187

    if p72 then
        v184, v185, v186 = round3(v174, v175, v176)
        p72[33] = v184
        p72[34] = v185
        p72[35] = v186
        v184, v185, v186 = round3(v180, v181, v182)
        p72[37] = v184
        p72[38] = v185
        p72[39] = v186
        p72[36] = v157
        p72[40] = v155
    end

    v171, v172, v173, v174, v175, v176, v177 = jacobian_response(v149, v150, v151, v114, v115, v116, v156, v160, v161, v162, v163, v164, v157)
    v178, v179, v180, v181, v182, v184, v185 = jacobian_response(v152, v153, v154, v114, v115, v116, v165, v166, v167, v168, v169, v170, v155)
    v109 = v178 * v181 + (v171 * v174 + 0)
    v178 = v179 * v182 + (v172 * v175 + 0)
    v179 = v180 * v184 + (v173 * v176 + 0)
    v186 = reciprocal_estimate(v179 + (v109 + v157) + (v178 + v155))

    local v188

    if v174 ~= 0 and v174 > -1.1754943508222875E-38 and v174 < 1.1754943508222875E-38 then
        v188 = to_bits(v174)
    else
        buffer.writef32(v90, 0, v174)
        v188 = buffer.readu32(v90, 0)
    end

    if v175 ~= 0 and v175 > -1.1754943508222875E-38 and v175 < 1.1754943508222875E-38 then
        v187 = to_bits(v175)
    else
        buffer.writef32(v90, 0, v175)
        v187 = buffer.readu32(v90, 0)
    end

    local v189

    if v176 ~= 0 and v176 > -1.1754943508222875E-38 and v176 < 1.1754943508222875E-38 then
        v189 = to_bits(v176)
    else
        buffer.writef32(v90, 0, v176)
        v189 = buffer.readu32(v90, 0)
    end

    local v190

    if v177 ~= 0 and v177 > -1.1754943508222875E-38 and v177 < 1.1754943508222875E-38 then
        v190 = to_bits(v177)
    else
        buffer.writef32(v90, 0, v177)
        v190 = buffer.readu32(v90, 0)
    end

    p71[45] = v188
    p71[46] = v187
    p71[47] = v189
    p71[48] = v190

    if v181 ~= 0 and v181 > -1.1754943508222875E-38 and v181 < 1.1754943508222875E-38 then
        v188 = to_bits(v181)
    else
        buffer.writef32(v90, 0, v181)
        v188 = buffer.readu32(v90, 0)
    end

    if v182 ~= 0 and v182 > -1.1754943508222875E-38 and v182 < 1.1754943508222875E-38 then
        v187 = to_bits(v182)
    else
        buffer.writef32(v90, 0, v182)
        v187 = buffer.readu32(v90, 0)
    end

    if v184 ~= 0 and v184 > -1.1754943508222875E-38 and v184 < 1.1754943508222875E-38 then
        v189 = to_bits(v184)
    else
        buffer.writef32(v90, 0, v184)
        v189 = buffer.readu32(v90, 0)
    end

    if v185 ~= 0 and v185 > -1.1754943508222875E-38 and v185 < 1.1754943508222875E-38 then
        v190 = to_bits(v185)
    else
        buffer.writef32(v90, 0, v185)
        v190 = buffer.readu32(v90, 0)
    end

    p71[49] = v188
    p71[50] = v187
    p71[51] = v189
    p71[52] = v190

    if p72 then
        v188, v187, v189 = round3(v174, v175, v176)
        p72[45] = v188
        p72[46] = v187
        p72[47] = v189
        v188, v187, v189 = round3(v181, v182, v184)
        p72[49] = v188
        p72[50] = v187
        p72[51] = v189
    end

    v171, v172, v173, v174, v175, v176, v177 = jacobian_response(v149, v150, v151, v117, v134, v135, v156, v160, v161, v162, v163, v164, v157)
    v178, v179, v180, v181, v182, v184, v185 = jacobian_response(v152, v153, v154, v117, v134, v135, v165, v166, v167, v168, v169, v170, v155)
    v188 = v178 * v181 + (v171 * v174 + 0)
    v178 = v179 * v182 + (v172 * v175 + 0)
    v179 = v180 * v184 + (v173 * v176 + 0)
    v187 = reciprocal_estimate(v179 + (v188 + v157) + (v178 + v155))

    local v191

    if v174 ~= 0 and v174 > -1.1754943508222875E-38 and v174 < 1.1754943508222875E-38 then
        v191 = to_bits(v174)
    else
        buffer.writef32(v90, 0, v174)
        v191 = buffer.readu32(v90, 0)
    end

    if v175 ~= 0 and v175 > -1.1754943508222875E-38 and v175 < 1.1754943508222875E-38 then
        v189 = to_bits(v175)
    else
        buffer.writef32(v90, 0, v175)
        v189 = buffer.readu32(v90, 0)
    end

    if v176 ~= 0 and v176 > -1.1754943508222875E-38 and v176 < 1.1754943508222875E-38 then
        v190 = to_bits(v176)
    else
        buffer.writef32(v90, 0, v176)
        v190 = buffer.readu32(v90, 0)
    end

    local v192

    if v177 ~= 0 and v177 > -1.1754943508222875E-38 and v177 < 1.1754943508222875E-38 then
        v192 = to_bits(v177)
    else
        buffer.writef32(v90, 0, v177)
        v192 = buffer.readu32(v90, 0)
    end

    p71[57] = v191
    p71[58] = v189
    p71[59] = v190
    p71[60] = v192

    if v181 ~= 0 and v181 > -1.1754943508222875E-38 and v181 < 1.1754943508222875E-38 then
        v191 = to_bits(v181)
    else
        buffer.writef32(v90, 0, v181)
        v191 = buffer.readu32(v90, 0)
    end

    if v182 ~= 0 and v182 > -1.1754943508222875E-38 and v182 < 1.1754943508222875E-38 then
        v189 = to_bits(v182)
    else
        buffer.writef32(v90, 0, v182)
        v189 = buffer.readu32(v90, 0)
    end

    if v184 ~= 0 and v184 > -1.1754943508222875E-38 and v184 < 1.1754943508222875E-38 then
        v190 = to_bits(v184)
    else
        buffer.writef32(v90, 0, v184)
        v190 = buffer.readu32(v90, 0)
    end

    if v185 ~= 0 and v185 > -1.1754943508222875E-38 and v185 < 1.1754943508222875E-38 then
        v192 = to_bits(v185)
    else
        buffer.writef32(v90, 0, v185)
        v192 = buffer.readu32(v90, 0)
    end

    p71[61] = v191
    p71[62] = v189
    p71[63] = v190
    p71[64] = v192

    if p72 then
        v191, v189, v190 = round3(v174, v175, v176)
        p72[57] = v191
        p72[58] = v189
        p72[59] = v190
        v191, v189, v190 = round3(v181, v182, v184)
        p72[61] = v191
        p72[62] = v189
        p72[63] = v190
    end

    if v125 then
        v179, v180, v181 = round3(v92[14], v92[15], v92[16])
        v182, v184, v185 = round3(v92[17], v92[18], v92[19])
        v176 = v151 * v184 + (-v150 * v185 + v179)
        v177 = v149 * v185 + (-v151 * v182 + v180)
        v178 = v150 * v182 + (-v149 * v184 + v181)
    else
        v176 = 0
        v177 = 0
        v178 = 0
    end

    if v124 then
        v182, v184, v185 = round3(v93[14], v93[15], v93[16])
        v188, v191, v189 = round3(v93[17], v93[18], v93[19])
        v179 = v154 * v191 + (-v153 * v189 + v182)
        v180 = v152 * v189 + (-v154 * v188 + v184)
        v181 = v153 * v188 + (-v152 * v191 + v185)
    else
        v179 = 0
        v180 = 0
        v181 = 0
    end

    v182 = v131 - v128
    v184 = v132 - v129
    v185 = v133 - v130
    v188 = v179 - v176
    v191 = v180 - v177
    v189 = v181 - v178
    v190 = p77 * v136 + 0
    v192 = p77 * v137 + 0

    local v193 = p77 * v138 + 0

    v181 = v188 * (p77 * p77) + 0
    v188 = v191 * (p77 * p77) + 0
    v191 = v189 * (p77 * p77) + 0

    local v194 = v190 + (v182 + v181)
    local v195 = v192 + (v184 + v188)
    local v196 = v193 + (v185 + v191)

    v189 = -v190 * v139 + 0
    v190 = -v192 * v139 + 0
    v192 = -v193 * v139 + 0
    v193 = v113 * v185 + (v112 * v184 + (v111 * v182 + 0))
    v191 = v113 * v192 + (v112 * v190 + (v111 * v189 + 0))
    v192 = v113 * v196 + (v112 * v195 + (v111 * v194 + 0))
    v190 = v116 * v196 + (v115 * v195 + (v114 * v194 + 0))
    v189 = v135 * v196 + (v134 * v195 + (v117 * v194 + 0))
    v171 = v193 * v183 + 0
    v172 = v191 * v183 + 0
    v173 = v192 * v183 + 0
    v174 = v190 * v186 + 0
    v175 = v189 * v187 + 0
    v176 = v92[2]
    v177 = v93[2]
    v178 = v111 * v183 + 0
    v179 = v114 * v186 + 0
    v180 = v117 * v187 + 0
    v181 = v112 * v183 + 0
    v182 = v115 * v186 + 0
    v184 = v134 * v187 + 0
    v185 = v113 * v183 + 0
    v186 = v116 * v186 + 0
    v187 = v135 * v187 + 0

    if v149 ~= 0 and v149 > -1.1754943508222875E-38 and v149 < 1.1754943508222875E-38 then
        v189 = to_bits(v149)
    else
        buffer.writef32(v90, 0, v149)
        v189 = buffer.readu32(v90, 0)
    end

    if v150 ~= 0 and v150 > -1.1754943508222875E-38 and v150 < 1.1754943508222875E-38 then
        v190 = to_bits(v150)
    else
        buffer.writef32(v90, 0, v150)
        v190 = buffer.readu32(v90, 0)
    end

    if v151 ~= 0 and v151 > -1.1754943508222875E-38 and v151 < 1.1754943508222875E-38 then
        v192 = to_bits(v151)
    else
        buffer.writef32(v90, 0, v151)
        v192 = buffer.readu32(v90, 0)
    end

    p71[1] = v189
    p71[2] = v190
    p71[3] = v192
    p71[4] = v176

    if v152 ~= 0 and v152 > -1.1754943508222875E-38 and v152 < 1.1754943508222875E-38 then
        v189 = to_bits(v152)
    else
        buffer.writef32(v90, 0, v152)
        v189 = buffer.readu32(v90, 0)
    end

    if v153 ~= 0 and v153 > -1.1754943508222875E-38 and v153 < 1.1754943508222875E-38 then
        v190 = to_bits(v153)
    else
        buffer.writef32(v90, 0, v153)
        v190 = buffer.readu32(v90, 0)
    end

    if v154 ~= 0 and v154 > -1.1754943508222875E-38 and v154 < 1.1754943508222875E-38 then
        v192 = to_bits(v154)
    else
        buffer.writef32(v90, 0, v154)
        v192 = buffer.readu32(v90, 0)
    end

    p71[5] = v189
    p71[6] = v190
    p71[7] = v192
    p71[8] = v177

    if v178 ~= 0 and v178 > -1.1754943508222875E-38 and v178 < 1.1754943508222875E-38 then
        v189 = to_bits(v178)
    else
        buffer.writef32(v90, 0, v178)
        v189 = buffer.readu32(v90, 0)
    end

    if v179 ~= 0 and v179 > -1.1754943508222875E-38 and v179 < 1.1754943508222875E-38 then
        v190 = to_bits(v179)
    else
        buffer.writef32(v90, 0, v179)
        v190 = buffer.readu32(v90, 0)
    end

    if v180 ~= 0 and v180 > -1.1754943508222875E-38 and v180 < 1.1754943508222875E-38 then
        v192 = to_bits(v180)
    else
        buffer.writef32(v90, 0, v180)
        v192 = buffer.readu32(v90, 0)
    end

    v193 = bit32.band(bit32.bor(v141, v142), 8)
    p71[9] = v189
    p71[10] = v190
    p71[11] = v192
    p71[12] = v193

    if v181 ~= 0 and v181 > -1.1754943508222875E-38 and v181 < 1.1754943508222875E-38 then
        v189 = to_bits(v181)
    else
        buffer.writef32(v90, 0, v181)
        v189 = buffer.readu32(v90, 0)
    end

    if v182 ~= 0 and v182 > -1.1754943508222875E-38 and v182 < 1.1754943508222875E-38 then
        v190 = to_bits(v182)
    else
        buffer.writef32(v90, 0, v182)
        v190 = buffer.readu32(v90, 0)
    end

    if v184 ~= 0 and v184 > -1.1754943508222875E-38 and v184 < 1.1754943508222875E-38 then
        v192 = to_bits(v184)
    else
        buffer.writef32(v90, 0, v184)
        v192 = buffer.readu32(v90, 0)
    end

    p71[13] = v189
    p71[14] = v190
    p71[15] = v192
    p71[16] = v127

    if v185 ~= 0 and v185 > -1.1754943508222875E-38 and v185 < 1.1754943508222875E-38 then
        v189 = to_bits(v185)
    else
        buffer.writef32(v90, 0, v185)
        v189 = buffer.readu32(v90, 0)
    end

    if v186 ~= 0 and v186 > -1.1754943508222875E-38 and v186 < 1.1754943508222875E-38 then
        v190 = to_bits(v186)
    else
        buffer.writef32(v90, 0, v186)
        v190 = buffer.readu32(v90, 0)
    end

    if v187 ~= 0 and v187 > -1.1754943508222875E-38 and v187 < 1.1754943508222875E-38 then
        v192 = to_bits(v187)
    else
        buffer.writef32(v90, 0, v187)
        v192 = buffer.readu32(v90, 0)
    end

    p71[17] = v189
    p71[18] = v190
    p71[19] = v192
    p71[20] = v126
    v189 = if v172 >= 0 then 0 else v171 + v172

    if not (v171 >= 0) then
        v172 = v189
    end

    if v173 <= 0 then
        v172 = 0
    end

    v190 = v173 - v172
    v192 = v174 - 0
    v193 = v175 - 0

    if v190 ~= 0 and v190 > -1.1754943508222875E-38 and v190 < 1.1754943508222875E-38 then
        v194 = to_bits(v190)
    else
        buffer.writef32(v90, 0, v190)
        v194 = buffer.readu32(v90, 0)
    end

    if v192 ~= 0 and v192 > -1.1754943508222875E-38 and v192 < 1.1754943508222875E-38 then
        v195 = to_bits(v192)
    else
        buffer.writef32(v90, 0, v192)
        v195 = buffer.readu32(v90, 0)
    end

    if v193 ~= 0 and v193 > -1.1754943508222875E-38 and v193 < 1.1754943508222875E-38 then
        v196 = to_bits(v193)
    else
        buffer.writef32(v90, 0, v193)
        v196 = buffer.readu32(v90, 0)
    end

    local v197

    if v171 ~= 0 and v171 > -1.1754943508222875E-38 and v171 < 1.1754943508222875E-38 then
        v197 = to_bits(v171)
    else
        buffer.writef32(v90, 0, v171)
        v197 = buffer.readu32(v90, 0)
    end

    p71[25] = v194
    p71[26] = v195
    p71[27] = v196
    p71[28] = v197

    if v111 ~= 0 and v111 > -1.1754943508222875E-38 and v111 < 1.1754943508222875E-38 then
        v194 = to_bits(v111)
    else
        buffer.writef32(v90, 0, v111)
        v194 = buffer.readu32(v90, 0)
    end

    if v112 ~= 0 and v112 > -1.1754943508222875E-38 and v112 < 1.1754943508222875E-38 then
        v195 = to_bits(v112)
    else
        buffer.writef32(v90, 0, v112)
        v195 = buffer.readu32(v90, 0)
    end

    if v113 ~= 0 and v113 > -1.1754943508222875E-38 and v113 < 1.1754943508222875E-38 then
        v196 = to_bits(v113)
    else
        buffer.writef32(v90, 0, v113)
        v196 = buffer.readu32(v90, 0)
    end

    v197 = v92[1]
    p71[29] = v194
    p71[30] = v195
    p71[31] = v196
    p71[32] = v197

    if v114 ~= 0 and v114 > -1.1754943508222875E-38 and v114 < 1.1754943508222875E-38 then
        v194 = to_bits(v114)
    else
        buffer.writef32(v90, 0, v114)
        v194 = buffer.readu32(v90, 0)
    end

    if v115 ~= 0 and v115 > -1.1754943508222875E-38 and v115 < 1.1754943508222875E-38 then
        v195 = to_bits(v115)
    else
        buffer.writef32(v90, 0, v115)
        v195 = buffer.readu32(v90, 0)
    end

    if v116 ~= 0 and v116 > -1.1754943508222875E-38 and v116 < 1.1754943508222875E-38 then
        v196 = to_bits(v116)
    else
        buffer.writef32(v90, 0, v116)
        v196 = buffer.readu32(v90, 0)
    end

    v197 = v93[1]
    p71[41] = v194
    p71[42] = v195
    p71[43] = v196
    p71[44] = v197

    if v117 ~= 0 and v117 > -1.1754943508222875E-38 and v117 < 1.1754943508222875E-38 then
        v194 = to_bits(v117)
    else
        buffer.writef32(v90, 0, v117)
        v194 = buffer.readu32(v90, 0)
    end

    if v134 ~= 0 and v134 > -1.1754943508222875E-38 and v134 < 1.1754943508222875E-38 then
        v195 = to_bits(v134)
    else
        buffer.writef32(v90, 0, v134)
        v195 = buffer.readu32(v90, 0)
    end

    if v135 ~= 0 and v135 > -1.1754943508222875E-38 and v135 < 1.1754943508222875E-38 then
        v196 = to_bits(v135)
    else
        buffer.writef32(v90, 0, v135)
        v196 = buffer.readu32(v90, 0)
    end

    v197 = contact.tag
    p71[53] = v194
    p71[54] = v195
    p71[55] = v196
    p71[56] = v197
    p71[21] = 0
    p71[22] = 0
    p71[23] = 0
    p71[24] = 0

    if p72 then
        v194, v195, v196 = round3(v149, v150, v151)
        p72[1] = v194
        p72[2] = v195
        p72[3] = v196
        v194, v195, v196 = round3(v152, v153, v154)
        p72[5] = v194
        p72[6] = v195
        p72[7] = v196
        v194, v195, v196 = round3(v178, v179, v180)
        p72[9] = v194
        p72[10] = v195
        p72[11] = v196
        v194, v195, v196 = round3(v181, v182, v184)
        p72[13] = v194
        p72[14] = v195
        p72[15] = v196
        v194, v195, v196 = round3(v185, v186, v187)
        p72[17] = v194
        p72[18] = v195
        p72[19] = v196
        p72[16] = v140
        p72[20] = v121
        p72[21] = 0
        p72[22] = 0
        p72[23] = 0
        p72[24] = 0
        v194, v195, v196 = round3(v190, v192, v193)
        p72[25] = v194
        p72[26] = v195
        p72[27] = v196

        local v198 = create(v171, 0, 0)

        v196 = v198.x
        v197 = v198.y

        local _ = v198.z

        if v171 < 1.1754943508222875E-38 and v171 > -1.1754943508222875E-38 and v171 ~= 0 then
            v196 = from_bits(to_bits(v171))
        end

        p72[28] = v196
        p72[29] = v111
        p72[30] = v112
        p72[31] = v113
        p72[41] = v114
        p72[42] = v115
        p72[43] = v116
        p72[53] = v117
        p72[54] = v134
        p72[55] = v135
    end

    return v176, v177
end

local v199 = table.create(64, 0)
local v200 = table.create(41, 0)

v200[1] = 4294967295

local t20 = {}
local t21 = {}
local t22 = {}
local t23 = {}
local n5 = 0
local v201 = true

function t1.set_body_records(p78) -- line: 1353
    -- upvalues: v201 (ref)
    local v202 = v201

    v201 = p78

    return v202
end

v11 = function() -- line: 1358
    -- upvalues: n5 (ref)
    n5 += 1
end

local function body_record(p79, p80, p81) -- line: 1362
    -- upvalues: BodyId (copy), to_bits (copy), from_bits (copy), t1 (copy), create (copy), round3 (copy), t20 (copy), t21 (copy), t22 (copy), t23 (copy), n5 (ref), v201 (ref)
    local v203 = t1.CollisionBody.contact_id(p79)
    local v204

    if p79.tag == "Board" then
        v204 = p80[BodyId.index(p79[1]) + 1]
    elseif p79.tag == "Attached" then
        v204 = p81[p79[1] + 1]

        if v204 == nil then
            error(("index out of bounds: the len is %* but the index is %*"):format(#p81, p79[1]), 0)
        end
    else
        error("internal error: entered unreachable code", 0)
    end

    local rates = v204.rates
    local v205 = v203 + 1
    local v206 = t20[v205]

    if v206 ~= nil then
        if t21[v205] == n5 and t22[v205] == v204 and t23[v205] == rates and v201 then
            return v206
        end
    else
        v206 = table.create(41, 0)
        t20[v205] = v206
    end

    t21[v205] = -1

    local columns = rates.world_inverse_inertia.columns
    local v207 = columns[1]
    local v208 = columns[2]
    local v209 = columns[3]

    v206[1] = v203
    v206[2] = v203

    local position = rates.position
    local x, y, z = position.x, position.y, position.z

    v206[3] = x
    v206[4] = y
    v206[5] = z

    local v210 = v207[1]
    local v211 = v208[1]
    local v212 = v209[1]

    v206[6] = v210
    v206[7] = v211
    v206[8] = v212

    local v213 = v209[3]
    local v214 = v208[2]
    local v215 = v209[2]

    v206[9] = v213
    v206[10] = v214
    v206[11] = v215
    v206[12] = v204.inertia.inverse_mass

    local v216 = bit32.bor(v204.state_flags, 8)

    v206[13] = v216

    local force_acceleration = rates.force_acceleration
    local x2, y2, z2 = force_acceleration.x, force_acceleration.y, force_acceleration.z

    v206[14] = x2
    v206[15] = y2
    v206[16] = z2

    local torque_acceleration = rates.torque_acceleration
    local x3, y3, z3 = torque_acceleration.x, torque_acceleration.y, torque_acceleration.z

    v206[17] = x3
    v206[18] = y3
    v206[19] = z3

    local linear_velocity = rates.linear_velocity
    local x4, y4, z4 = linear_velocity.x, linear_velocity.y, linear_velocity.z

    v206[20] = x4
    v206[21] = y4
    v206[22] = z4

    local angular_velocity = rates.angular_velocity
    local x5, y5, z5 = angular_velocity.x, angular_velocity.y, angular_velocity.z

    v206[23] = x5
    v206[24] = y5
    v206[25] = z5

    local v217, v218, v219 = round3(v206[3], v206[4], v206[5])

    v206[26] = v217
    v206[27] = v218
    v206[28] = v219

    if bit32.band(v216, 4) == 4 then
        local v220 = v206[12]
        local v221 = create(v220, 0, 0)
        local x, _, _ = v221.x, v221.y, v221.z

        if v220 < 1.1754943508222875E-38 and v220 > -1.1754943508222875E-38 and v220 ~= 0 then
            x = from_bits(to_bits(v220))
        end

        v206[29] = x

        local v222, v223, v224 = round3(v206[6], v206[7], v206[8])

        v206[30] = v222
        v206[31] = v223
        v206[32] = v224

        local v225, v226, v227 = round3(v206[9], v206[10], v206[11])

        v206[33] = v225
        v206[34] = v226
        v206[35] = v227

        local v228, v229, v230 = round3(v206[14], v206[15], v206[16])

        v206[36] = v228
        v206[37] = v229
        v206[38] = v230

        local v231, v232, v233 = round3(v206[17], v206[18], v206[19])

        v206[39] = v231
        v206[40] = v232
        v206[41] = v233
    else
        v206[29] = 0
        v206[30] = 0
        v206[31] = 0
        v206[32] = 0
        v206[33] = 0
        v206[34] = 0
        v206[35] = 0
        v206[36] = 0
        v206[37] = 0
        v206[38] = 0
        v206[39] = 0
        v206[40] = 0
        v206[41] = 0
    end

    t22[v205] = v204
    t23[v205] = rates
    t21[v205] = n5

    return v206
end

local v234 = true

function t1.set_b3(p82) -- line: 1429
    -- upvalues: v234 (ref)
    local v235 = v234

    v234 = p82

    return v235
end

v10 = function(p83, p84, p85, p86, p87, p88, p89) -- line: 1434
    -- upvalues: to_bits (copy), v90 (copy), round3 (copy), estimate (copy), CONTACT_TANGENT_MINIMUM_SQUARED (copy), CONTACT_FALLBACK_HALF (copy), fill_collision_words_w3 (copy), v199 (copy), v200 (copy), body_record (copy), v234 (ref)
    if not v234 then
        return fill_collision_words_w3(p83, p84, p85, p86, p87, p88, p89)
    end

    p84 = p84 or v199

    local contact, v237 = p85.contact, p85.body_a
    local v238

    if v237.tag == "StaticWorld" then
        v238 = v200
        v200[2] = p88
    else
        v238 = body_record(v237, p86, p87)
    end

    v237 = p85.body_b

    local v239 = v237.tag == "StaticWorld"
    local v240

    if v239 then
        v240 = v200
        v200[2] = p88
    else
        v240 = body_record(v237, p86, p87)
    end

    v237 = contact.position_on_a

    local x, y, z = v237.x, v237.y, v237.z

    v237 = contact.position_on_b

    local x2, y2, z2 = v237.x, v237.y, v237.z

    v237 = contact.normal

    local v241, v242, z3 = v237.x, v237.y, v237.z
    local v243 = x - v238[3]
    local v244 = y - v238[4]
    local v245 = z - v238[5]
    local v246 = x2 - v240[3]
    local v247 = y2 - v240[4]
    local v248 = z2 - v240[5]

    v237 = v245 * v238[24] + (-v244 * v238[25] + v238[20])

    local v249 = v243 * v238[25] + (-v245 * v238[23] + v238[21])

    v245 = v244 * v238[23] + (-v243 * v238[24] + v238[22])
    v244 = v248 * v240[24] + (-v247 * v240[25] + v240[20])
    v243 = v246 * v240[25] + (-v248 * v240[23] + v240[21])
    v248 = v247 * v240[23] + (-v246 * v240[24] + v240[22])

    local v250 = v244 - v237
    local v251 = v243 - v249
    local v252 = v248 - v245

    v249 = v251 * z3 + (-v252 * v242 + 0)
    v248 = v252 * v241 + (-v250 * z3 + 0)
    v247 = v250 * v242 + (-v251 * v241 + 0)
    v246 = v247 * v247 + (v248 * v248 + (v249 * v249 + 0))

    local v253

    if not (CONTACT_TANGENT_MINIMUM_SQUARED <= v246) then
        v249 = -v241 * v241 + 1
        v248 = -v242 * v241 + 0
        v247 = -z3 * v241 + 0
        v237 = -v241 * z3 + 0
        v253 = -v242 * z3 + 0
        v246 = -z3 * z3 + 1

        if -v241 * v241 + CONTACT_FALLBACK_HALF >= -0 then
            v246 = v249
        else
            v249 = -v237
            v248 = -v253
            v247 = -v246
        end
    end

    v253 = estimate(v246)

    local v254 = v249 * v253 + 0
    local v255 = v248 * v253 + 0
    local v256 = v247 * v253 + 0
    local v257 = (-v248 * z3 + (v247 * v242 + 0)) * v253 + 0
    local v258 = (-v247 * v241 + (v249 * z3 + 0)) * v253 + 0
    local v259 = (-v249 * v242 + (v248 * v241 + 0)) * v253 + 0

    v243 = p89 == p89 and p89 ~= 1e999 and p89 ~= (-1e999)

    if not (v243 and p89 > 0) then
        error("assertion failed: time_step.is_finite() && time_step > 0.0", 0)
    end

    local v260, v261, v262 = round3(x, y, z)
    local v263, v264, v265 = round3(x2, y2, z2)

    v243, v244, v245 = round3(v241, v242, z3)
    v246, v247, v248 = round3(v254, v255, v256)

    local v266, v267

    v249, v266, v267 = round3(v257, v258, v259)

    local v268, v269, v270 = round3(v250, v251, v252)
    local v271, v272

    v271, v272, v253 = round3(contact.restitution, contact.static_friction, contact.dynamic_friction)

    local v273 = contact.static_friction

    if v273 ~= 0 and v273 > -1.1754943508222875E-38 and v273 < 1.1754943508222875E-38 then
        v259 = to_bits(v273)
    else
        buffer.writef32(v90, 0, v273)
        v259 = buffer.readu32(v90, 0)
    end

    v273 = contact.dynamic_friction

    if v273 ~= 0 and v273 > -1.1754943508222875E-38 and v273 < 1.1754943508222875E-38 then
        v258 = to_bits(v273)
    else
        buffer.writef32(v90, 0, v273)
        v258 = buffer.readu32(v90, 0)
    end

    v273 = v238[13]

    local v274 = v240[13]

    v257 = bit32.band(v273, 4) == 4
    v256 = bit32.band(v274, 4) == 4

    local v275 = v260 - v238[26]
    local v276 = v261 - v238[27]
    local v277 = v262 - v238[28]
    local v278 = v263 - v240[26]
    local v279 = v264 - v240[27]
    local v280 = v265 - v240[28]
    local v281 = v238[29]
    local v282 = v240[29]
    local v283 = v238[30]
    local v284 = v238[31]
    local v285 = v238[32]
    local v286 = v238[33]
    local v287 = v238[34]
    local v288 = v238[35]
    local v289 = v240[30]
    local v290 = v240[31]
    local v291 = v240[32]
    local v292 = v240[33]
    local v293 = v240[34]
    local v294 = v240[35]

    if not v239 or v256 then
        v255 = false
    else
        v254 = v278 + v279 + v280 + v243 + v244 + v245 + v246 + v247 + v248 + v249 + v266 + v267
        v255 = v254 - v254 == 0
    end

    v242 = -v277 * v244 + (v276 * v245 + 0)
    v241 = -v275 * v245 + (v277 * v243 + 0)
    v239 = -v276 * v243 + (v275 * v244 + 0)

    local v295 = v285 * v239 + (v284 * v241 + (v283 * v242 + 0))
    local v296 = v288 * v239 + (v287 * v241 + (v284 * v242 + 0))
    local v297 = v286 * v239 + (v288 * v241 + (v285 * v242 + 0))
    local v298, v299, v300, v301, v302, v303, v304

    if v255 then
        v298 = v242 * v295 + 0
        v299 = v241 * v296 + 0
        v300 = v239 * v297 + 0
        p83[37] = 0
        p83[38] = 0
        p83[39] = 0
        p83[40] = 0
        p84[37] = 0
        p84[38] = 0
        p84[39] = 0
    else
        v304 = -v280 * v244 + (v279 * v245 + 0)

        local v305 = -v278 * v245 + (v280 * v243 + 0)
        local v306 = -v279 * v243 + (v278 * v244 + 0)
        local v307 = v291 * v306 + (v290 * v305 + (v289 * v304 + 0))

        v301 = v294 * v306 + (v293 * v305 + (v290 * v304 + 0))
        v302 = v292 * v306 + (v294 * v305 + (v291 * v304 + 0))
        v298 = v304 * v307 + (v242 * v295 + 0)
        v299 = v305 * v301 + (v241 * v296 + 0)
        v300 = v306 * v302 + (v239 * v297 + 0)

        if not (v307 < 1.1754943508222875E-38) or not (v307 > -1.1754943508222875E-38) or v307 == 0 then
            buffer.writef32(v90, 0, v307)
            v303 = buffer.readu32(v90, 0)
        else
            v303 = to_bits(v307)
            buffer.writeu32(v90, 0, v303)
        end

        p83[37] = v303
        p84[37] = buffer.readf32(v90, 0)

        if v301 < 1.1754943508222875E-38 and v301 > -1.1754943508222875E-38 and v301 ~= 0 then
            v303 = to_bits(v301)
            buffer.writeu32(v90, 0, v303)
        else
            buffer.writef32(v90, 0, v301)
            v303 = buffer.readu32(v90, 0)
        end

        p83[38] = v303
        p84[38] = buffer.readf32(v90, 0)

        if v302 < 1.1754943508222875E-38 and v302 > -1.1754943508222875E-38 and v302 ~= 0 then
            v303 = to_bits(v302)
            buffer.writeu32(v90, 0, v303)
        else
            buffer.writef32(v90, 0, v302)
            v303 = buffer.readu32(v90, 0)
        end

        p83[39] = v303
        p84[39] = buffer.readf32(v90, 0)

        if v282 ~= 0 and v282 > -1.1754943508222875E-38 and v282 < 1.1754943508222875E-38 then
            p83[40] = to_bits(v282)
        else
            buffer.writef32(v90, 0, v282)
            p83[40] = buffer.readu32(v90, 0)
        end
    end

    local v308 = 1 / (v300 + (v298 + v281) + (v299 + v282))

    if v295 < 1.1754943508222875E-38 and v295 > -1.1754943508222875E-38 and v295 ~= 0 then
        v304 = to_bits(v295)
        buffer.writeu32(v90, 0, v304)
    else
        buffer.writef32(v90, 0, v295)
        v304 = buffer.readu32(v90, 0)
    end

    p83[33] = v304
    p84[33] = buffer.readf32(v90, 0)

    if v296 < 1.1754943508222875E-38 and v296 > -1.1754943508222875E-38 and v296 ~= 0 then
        v304 = to_bits(v296)
        buffer.writeu32(v90, 0, v304)
    else
        buffer.writef32(v90, 0, v296)
        v304 = buffer.readu32(v90, 0)
    end

    p83[34] = v304
    p84[34] = buffer.readf32(v90, 0)

    if v297 < 1.1754943508222875E-38 and v297 > -1.1754943508222875E-38 and v297 ~= 0 then
        v304 = to_bits(v297)
        buffer.writeu32(v90, 0, v304)
    else
        buffer.writef32(v90, 0, v297)
        v304 = buffer.readu32(v90, 0)
    end

    p83[35] = v304
    p84[35] = buffer.readf32(v90, 0)

    if v281 ~= 0 and v281 > -1.1754943508222875E-38 and v281 < 1.1754943508222875E-38 then
        p83[36] = to_bits(v281)
    else
        buffer.writef32(v90, 0, v281)
        p83[36] = buffer.readu32(v90, 0)
    end

    p84[36] = v281
    p84[40] = v282
    v295 = -v277 * v247 + (v276 * v248 + 0)
    v296 = -v275 * v248 + (v277 * v246 + 0)
    v297 = -v276 * v246 + (v275 * v247 + 0)
    v298 = v285 * v297 + (v284 * v296 + (v283 * v295 + 0))
    v299 = v288 * v297 + (v287 * v296 + (v284 * v295 + 0))
    v300 = v286 * v297 + (v288 * v296 + (v285 * v295 + 0))
    v304 = v281 * v297 + (v281 * v296 + (v281 * v295 + 0))

    local v309, v310, v311, v312

    if v255 then
        v309 = v295 * v298 + 0
        v310 = v296 * v299 + 0
        v311 = v297 * v300 + 0
        p83[49] = 0
        p83[50] = 0
        p83[51] = 0
        p83[52] = 0
        p84[49] = 0
        p84[50] = 0
        p84[51] = 0
    else
        v301 = -v280 * v247 + (v279 * v248 + 0)
        v302 = -v278 * v248 + (v280 * v246 + 0)
        v303 = -v279 * v246 + (v278 * v247 + 0)
        v312 = v291 * v303 + (v290 * v302 + (v289 * v301 + 0))

        local v313 = v294 * v303 + (v293 * v302 + (v290 * v301 + 0))
        local v314 = v292 * v303 + (v294 * v302 + (v291 * v301 + 0))
        local v315 = v282 * v303 + (v282 * v302 + (v282 * v301 + 0))

        v309 = v301 * v312 + (v295 * v298 + 0)
        v310 = v302 * v313 + (v296 * v299 + 0)
        v311 = v303 * v314 + (v297 * v300 + 0)

        local v316

        if not (v312 < 1.1754943508222875E-38) or not (v312 > -1.1754943508222875E-38) or v312 == 0 then
            buffer.writef32(v90, 0, v312)
            v316 = buffer.readu32(v90, 0)
        else
            v316 = to_bits(v312)
            buffer.writeu32(v90, 0, v316)
        end

        p83[49] = v316
        p84[49] = buffer.readf32(v90, 0)

        if v313 < 1.1754943508222875E-38 and v313 > -1.1754943508222875E-38 and v313 ~= 0 then
            v316 = to_bits(v313)
            buffer.writeu32(v90, 0, v316)
        else
            buffer.writef32(v90, 0, v313)
            v316 = buffer.readu32(v90, 0)
        end

        p83[50] = v316
        p84[50] = buffer.readf32(v90, 0)

        if v314 < 1.1754943508222875E-38 and v314 > -1.1754943508222875E-38 and v314 ~= 0 then
            v316 = to_bits(v314)
            buffer.writeu32(v90, 0, v316)
        else
            buffer.writef32(v90, 0, v314)
            v316 = buffer.readu32(v90, 0)
        end

        p83[51] = v316
        p84[51] = buffer.readf32(v90, 0)

        if v315 ~= 0 and v315 > -1.1754943508222875E-38 and v315 < 1.1754943508222875E-38 then
            p83[52] = to_bits(v315)
        else
            buffer.writef32(v90, 0, v315)
            p83[52] = buffer.readu32(v90, 0)
        end
    end

    local v317 = 1 / (v311 + (v309 + v281) + (v310 + v282))

    if v298 < 1.1754943508222875E-38 and v298 > -1.1754943508222875E-38 and v298 ~= 0 then
        v301 = to_bits(v298)
        buffer.writeu32(v90, 0, v301)
    else
        buffer.writef32(v90, 0, v298)
        v301 = buffer.readu32(v90, 0)
    end

    p83[45] = v301
    p84[45] = buffer.readf32(v90, 0)

    if v299 < 1.1754943508222875E-38 and v299 > -1.1754943508222875E-38 and v299 ~= 0 then
        v301 = to_bits(v299)
        buffer.writeu32(v90, 0, v301)
    else
        buffer.writef32(v90, 0, v299)
        v301 = buffer.readu32(v90, 0)
    end

    p83[46] = v301
    p84[46] = buffer.readf32(v90, 0)

    if v300 < 1.1754943508222875E-38 and v300 > -1.1754943508222875E-38 and v300 ~= 0 then
        v301 = to_bits(v300)
        buffer.writeu32(v90, 0, v301)
    else
        buffer.writef32(v90, 0, v300)
        v301 = buffer.readu32(v90, 0)
    end

    p83[47] = v301
    p84[47] = buffer.readf32(v90, 0)

    if v304 ~= 0 and v304 > -1.1754943508222875E-38 and v304 < 1.1754943508222875E-38 then
        p83[48] = to_bits(v304)
    else
        buffer.writef32(v90, 0, v304)
        p83[48] = buffer.readu32(v90, 0)
    end

    v295 = -v277 * v266 + (v276 * v267 + 0)
    v296 = -v275 * v267 + (v277 * v249 + 0)
    v297 = -v276 * v249 + (v275 * v266 + 0)
    v298 = v285 * v297 + (v284 * v296 + (v283 * v295 + 0))
    v299 = v288 * v297 + (v287 * v296 + (v284 * v295 + 0))
    v300 = v286 * v297 + (v288 * v296 + (v285 * v295 + 0))
    v304 = v281 * v297 + (v281 * v296 + (v281 * v295 + 0))

    local v318, v319, v320, v321, v322, v323, v324

    if v255 then
        v318 = v295 * v298 + 0
        v319 = v296 * v299 + 0
        v320 = v297 * v300 + 0
        p83[61] = 0
        p83[62] = 0
        p83[63] = 0
        p83[64] = 0
        p84[61] = 0
        p84[62] = 0
        p84[63] = 0
    else
        v301 = -v280 * v266 + (v279 * v267 + 0)
        v302 = -v278 * v267 + (v280 * v249 + 0)
        v303 = -v279 * v249 + (v278 * v266 + 0)
        v312 = v291 * v303 + (v290 * v302 + (v289 * v301 + 0))
        v321 = v294 * v303 + (v293 * v302 + (v290 * v301 + 0))
        v322 = v292 * v303 + (v294 * v302 + (v291 * v301 + 0))
        v323 = v282 * v303 + (v282 * v302 + (v282 * v301 + 0))
        v318 = v301 * v312 + (v295 * v298 + 0)
        v319 = v302 * v321 + (v296 * v299 + 0)
        v320 = v303 * v322 + (v297 * v300 + 0)

        if not (v312 < 1.1754943508222875E-38) or not (v312 > -1.1754943508222875E-38) or v312 == 0 then
            buffer.writef32(v90, 0, v312)
            v324 = buffer.readu32(v90, 0)
        else
            v324 = to_bits(v312)
            buffer.writeu32(v90, 0, v324)
        end

        p83[61] = v324
        p84[61] = buffer.readf32(v90, 0)

        if v321 < 1.1754943508222875E-38 and v321 > -1.1754943508222875E-38 and v321 ~= 0 then
            v324 = to_bits(v321)
            buffer.writeu32(v90, 0, v324)
        else
            buffer.writef32(v90, 0, v321)
            v324 = buffer.readu32(v90, 0)
        end

        p83[62] = v324
        p84[62] = buffer.readf32(v90, 0)

        if v322 < 1.1754943508222875E-38 and v322 > -1.1754943508222875E-38 and v322 ~= 0 then
            v324 = to_bits(v322)
            buffer.writeu32(v90, 0, v324)
        else
            buffer.writef32(v90, 0, v322)
            v324 = buffer.readu32(v90, 0)
        end

        p83[63] = v324
        p84[63] = buffer.readf32(v90, 0)

        if v323 ~= 0 and v323 > -1.1754943508222875E-38 and v323 < 1.1754943508222875E-38 then
            p83[64] = to_bits(v323)
        else
            buffer.writef32(v90, 0, v323)
            p83[64] = buffer.readu32(v90, 0)
        end
    end

    local v325 = 1 / (v320 + (v318 + v281) + (v319 + v282))

    if v298 < 1.1754943508222875E-38 and v298 > -1.1754943508222875E-38 and v298 ~= 0 then
        v301 = to_bits(v298)
        buffer.writeu32(v90, 0, v301)
    else
        buffer.writef32(v90, 0, v298)
        v301 = buffer.readu32(v90, 0)
    end

    p83[57] = v301
    p84[57] = buffer.readf32(v90, 0)

    if v299 < 1.1754943508222875E-38 and v299 > -1.1754943508222875E-38 and v299 ~= 0 then
        v301 = to_bits(v299)
        buffer.writeu32(v90, 0, v301)
    else
        buffer.writef32(v90, 0, v299)
        v301 = buffer.readu32(v90, 0)
    end

    p83[58] = v301
    p84[58] = buffer.readf32(v90, 0)

    if v300 < 1.1754943508222875E-38 and v300 > -1.1754943508222875E-38 and v300 ~= 0 then
        v301 = to_bits(v300)
        buffer.writeu32(v90, 0, v301)
    else
        buffer.writef32(v90, 0, v300)
        v301 = buffer.readu32(v90, 0)
    end

    p83[59] = v301
    p84[59] = buffer.readf32(v90, 0)

    if v304 ~= 0 and v304 > -1.1754943508222875E-38 and v304 < 1.1754943508222875E-38 then
        p83[60] = to_bits(v304)
    else
        buffer.writef32(v90, 0, v304)
        p83[60] = buffer.readu32(v90, 0)
    end

    if v257 then
        v319 = v238[36]
        v320 = v238[37]
        v301 = v238[38]
        v302 = v238[39]
        v303 = v238[40]
        v312 = v238[41]
        v300 = v277 * v303 + (-v276 * v312 + v319)
        v304 = v275 * v312 + (-v277 * v302 + v320)
        v318 = v276 * v302 + (-v275 * v303 + v301)
    else
        v300 = 0
        v304 = 0
        v318 = 0
    end

    if v256 then
        v302 = v240[36]
        v303 = v240[37]
        v312 = v240[38]
        v321 = v240[39]
        v322 = v240[40]
        v323 = v240[41]
        v319 = v280 * v322 + (-v279 * v323 + v302)
        v320 = v278 * v323 + (-v280 * v321 + v303)
        v301 = v279 * v321 + (-v278 * v322 + v312)
    else
        v319 = 0
        v320 = 0
        v301 = 0
    end

    v302 = v263 - v260
    v303 = v264 - v261
    v312 = v265 - v262
    v321 = v319 - v300
    v322 = v320 - v304
    v323 = v301 - v318
    v324 = p89 * v268 + 0

    local v326 = p89 * v269 + 0
    local v327 = p89 * v270 + 0

    v301 = v321 * (p89 * p89) + 0
    v321 = v322 * (p89 * p89) + 0
    v322 = v323 * (p89 * p89) + 0

    local v328 = v324 + (v302 + v301)
    local v329 = v326 + (v303 + v321)
    local v330 = v327 + (v312 + v322)

    v323 = -v324 * v271 + 0
    v324 = -v326 * v271 + 0
    v326 = -v327 * v271 + 0
    v327 = v245 * v312 + (v244 * v303 + (v243 * v302 + 0))
    v322 = v245 * v326 + (v244 * v324 + (v243 * v323 + 0))
    v326 = v245 * v330 + (v244 * v329 + (v243 * v328 + 0))
    v324 = v248 * v330 + (v247 * v329 + (v246 * v328 + 0))
    v323 = v267 * v330 + (v266 * v329 + (v249 * v328 + 0))
    v295 = v327 * v308 + 0
    v296 = v322 * v308 + 0
    v297 = v326 * v308 + 0
    v298 = v324 * v317 + 0
    v299 = v323 * v325 + 0
    v300 = v238[2]
    v304 = v240[2]
    v318 = v243 * v308 + 0
    v319 = v246 * v317 + 0
    v320 = v249 * v325 + 0
    v301 = v244 * v308 + 0
    v302 = v247 * v317 + 0
    v303 = v266 * v325 + 0
    v312 = v245 * v308 + 0
    v321 = v248 * v317 + 0
    v322 = v267 * v325 + 0

    if v275 < 1.1754943508222875E-38 and v275 > -1.1754943508222875E-38 and v275 ~= 0 then
        v323 = to_bits(v275)
        buffer.writeu32(v90, 0, v323)
    else
        buffer.writef32(v90, 0, v275)
        v323 = buffer.readu32(v90, 0)
    end

    p83[1] = v323
    p84[1] = buffer.readf32(v90, 0)

    if v276 < 1.1754943508222875E-38 and v276 > -1.1754943508222875E-38 and v276 ~= 0 then
        v323 = to_bits(v276)
        buffer.writeu32(v90, 0, v323)
    else
        buffer.writef32(v90, 0, v276)
        v323 = buffer.readu32(v90, 0)
    end

    p83[2] = v323
    p84[2] = buffer.readf32(v90, 0)

    if v277 < 1.1754943508222875E-38 and v277 > -1.1754943508222875E-38 and v277 ~= 0 then
        v323 = to_bits(v277)
        buffer.writeu32(v90, 0, v323)
    else
        buffer.writef32(v90, 0, v277)
        v323 = buffer.readu32(v90, 0)
    end

    p83[3] = v323
    p84[3] = buffer.readf32(v90, 0)
    p83[4] = v300

    if v278 < 1.1754943508222875E-38 and v278 > -1.1754943508222875E-38 and v278 ~= 0 then
        v323 = to_bits(v278)
        buffer.writeu32(v90, 0, v323)
    else
        buffer.writef32(v90, 0, v278)
        v323 = buffer.readu32(v90, 0)
    end

    p83[5] = v323
    p84[5] = buffer.readf32(v90, 0)

    if v279 < 1.1754943508222875E-38 and v279 > -1.1754943508222875E-38 and v279 ~= 0 then
        v323 = to_bits(v279)
        buffer.writeu32(v90, 0, v323)
    else
        buffer.writef32(v90, 0, v279)
        v323 = buffer.readu32(v90, 0)
    end

    p83[6] = v323
    p84[6] = buffer.readf32(v90, 0)

    if v280 < 1.1754943508222875E-38 and v280 > -1.1754943508222875E-38 and v280 ~= 0 then
        v323 = to_bits(v280)
        buffer.writeu32(v90, 0, v323)
    else
        buffer.writef32(v90, 0, v280)
        v323 = buffer.readu32(v90, 0)
    end

    p83[7] = v323
    p84[7] = buffer.readf32(v90, 0)
    p83[8] = v304

    if v318 < 1.1754943508222875E-38 and v318 > -1.1754943508222875E-38 and v318 ~= 0 then
        v323 = to_bits(v318)
        buffer.writeu32(v90, 0, v323)
    else
        buffer.writef32(v90, 0, v318)
        v323 = buffer.readu32(v90, 0)
    end

    p83[9] = v323
    p84[9] = buffer.readf32(v90, 0)

    if v319 < 1.1754943508222875E-38 and v319 > -1.1754943508222875E-38 and v319 ~= 0 then
        v323 = to_bits(v319)
        buffer.writeu32(v90, 0, v323)
    else
        buffer.writef32(v90, 0, v319)
        v323 = buffer.readu32(v90, 0)
    end

    p83[10] = v323
    p84[10] = buffer.readf32(v90, 0)

    if v320 < 1.1754943508222875E-38 and v320 > -1.1754943508222875E-38 and v320 ~= 0 then
        v323 = to_bits(v320)
        buffer.writeu32(v90, 0, v323)
    else
        buffer.writef32(v90, 0, v320)
        v323 = buffer.readu32(v90, 0)
    end

    p83[11] = v323
    p84[11] = buffer.readf32(v90, 0)
    p83[12] = bit32.band(bit32.bor(v273, v274), 8)

    if v301 < 1.1754943508222875E-38 and v301 > -1.1754943508222875E-38 and v301 ~= 0 then
        v323 = to_bits(v301)
        buffer.writeu32(v90, 0, v323)
    else
        buffer.writef32(v90, 0, v301)
        v323 = buffer.readu32(v90, 0)
    end

    p83[13] = v323
    p84[13] = buffer.readf32(v90, 0)

    if v302 < 1.1754943508222875E-38 and v302 > -1.1754943508222875E-38 and v302 ~= 0 then
        v323 = to_bits(v302)
        buffer.writeu32(v90, 0, v323)
    else
        buffer.writef32(v90, 0, v302)
        v323 = buffer.readu32(v90, 0)
    end

    p83[14] = v323
    p84[14] = buffer.readf32(v90, 0)

    if v303 < 1.1754943508222875E-38 and v303 > -1.1754943508222875E-38 and v303 ~= 0 then
        v323 = to_bits(v303)
        buffer.writeu32(v90, 0, v323)
    else
        buffer.writef32(v90, 0, v303)
        v323 = buffer.readu32(v90, 0)
    end

    p83[15] = v323
    p84[15] = buffer.readf32(v90, 0)
    p83[16] = v259

    if v312 < 1.1754943508222875E-38 and v312 > -1.1754943508222875E-38 and v312 ~= 0 then
        v323 = to_bits(v312)
        buffer.writeu32(v90, 0, v323)
    else
        buffer.writef32(v90, 0, v312)
        v323 = buffer.readu32(v90, 0)
    end

    p83[17] = v323
    p84[17] = buffer.readf32(v90, 0)

    if v321 < 1.1754943508222875E-38 and v321 > -1.1754943508222875E-38 and v321 ~= 0 then
        v323 = to_bits(v321)
        buffer.writeu32(v90, 0, v323)
    else
        buffer.writef32(v90, 0, v321)
        v323 = buffer.readu32(v90, 0)
    end

    p83[18] = v323
    p84[18] = buffer.readf32(v90, 0)

    if v322 < 1.1754943508222875E-38 and v322 > -1.1754943508222875E-38 and v322 ~= 0 then
        v323 = to_bits(v322)
        buffer.writeu32(v90, 0, v323)
    else
        buffer.writef32(v90, 0, v322)
        v323 = buffer.readu32(v90, 0)
    end

    p83[19] = v323
    p84[19] = buffer.readf32(v90, 0)
    p83[20] = v258
    v323 = if v296 >= 0 then 0 else v295 + v296

    if not (v295 >= 0) then
        v296 = v323
    end

    if v297 <= 0 then
        v296 = 0
    end

    local v331 = v297 - v296

    if v331 < 1.1754943508222875E-38 and v331 > -1.1754943508222875E-38 and v331 ~= 0 then
        v324 = to_bits(v331)
        buffer.writeu32(v90, 0, v324)
    else
        buffer.writef32(v90, 0, v331)
        v324 = buffer.readu32(v90, 0)
    end

    p83[25] = v324
    p84[25] = buffer.readf32(v90, 0)
    v331 = v298 - 0

    if v331 < 1.1754943508222875E-38 and v331 > -1.1754943508222875E-38 and v331 ~= 0 then
        v324 = to_bits(v331)
        buffer.writeu32(v90, 0, v324)
    else
        buffer.writef32(v90, 0, v331)
        v324 = buffer.readu32(v90, 0)
    end

    p83[26] = v324
    p84[26] = buffer.readf32(v90, 0)
    v331 = v299 - 0

    if v331 < 1.1754943508222875E-38 and v331 > -1.1754943508222875E-38 and v331 ~= 0 then
        v324 = to_bits(v331)
        buffer.writeu32(v90, 0, v324)
    else
        buffer.writef32(v90, 0, v331)
        v324 = buffer.readu32(v90, 0)
    end

    p83[27] = v324
    p84[27] = buffer.readf32(v90, 0)

    if v295 < 1.1754943508222875E-38 and v295 > -1.1754943508222875E-38 and v295 ~= 0 then
        v324 = to_bits(v295)
        buffer.writeu32(v90, 0, v324)
    else
        buffer.writef32(v90, 0, v295)
        v324 = buffer.readu32(v90, 0)
    end

    p83[28] = v324
    p84[28] = buffer.readf32(v90, 0)

    if v243 ~= 0 and v243 > -1.1754943508222875E-38 and v243 < 1.1754943508222875E-38 then
        v324 = to_bits(v243)
    else
        buffer.writef32(v90, 0, v243)
        v324 = buffer.readu32(v90, 0)
    end

    if v244 ~= 0 and v244 > -1.1754943508222875E-38 and v244 < 1.1754943508222875E-38 then
        v326 = to_bits(v244)
    else
        buffer.writef32(v90, 0, v244)
        v326 = buffer.readu32(v90, 0)
    end

    if v245 ~= 0 and v245 > -1.1754943508222875E-38 and v245 < 1.1754943508222875E-38 then
        v327 = to_bits(v245)
    else
        buffer.writef32(v90, 0, v245)
        v327 = buffer.readu32(v90, 0)
    end

    v328 = v238[1]
    p83[29] = v324
    p83[30] = v326
    p83[31] = v327
    p83[32] = v328

    if v246 ~= 0 and v246 > -1.1754943508222875E-38 and v246 < 1.1754943508222875E-38 then
        v324 = to_bits(v246)
    else
        buffer.writef32(v90, 0, v246)
        v324 = buffer.readu32(v90, 0)
    end

    if v247 ~= 0 and v247 > -1.1754943508222875E-38 and v247 < 1.1754943508222875E-38 then
        v326 = to_bits(v247)
    else
        buffer.writef32(v90, 0, v247)
        v326 = buffer.readu32(v90, 0)
    end

    if v248 ~= 0 and v248 > -1.1754943508222875E-38 and v248 < 1.1754943508222875E-38 then
        v327 = to_bits(v248)
    else
        buffer.writef32(v90, 0, v248)
        v327 = buffer.readu32(v90, 0)
    end

    v328 = v240[1]
    p83[41] = v324
    p83[42] = v326
    p83[43] = v327
    p83[44] = v328

    if v249 ~= 0 and v249 > -1.1754943508222875E-38 and v249 < 1.1754943508222875E-38 then
        v324 = to_bits(v249)
    else
        buffer.writef32(v90, 0, v249)
        v324 = buffer.readu32(v90, 0)
    end

    if v266 ~= 0 and v266 > -1.1754943508222875E-38 and v266 < 1.1754943508222875E-38 then
        v326 = to_bits(v266)
    else
        buffer.writef32(v90, 0, v266)
        v326 = buffer.readu32(v90, 0)
    end

    if v267 ~= 0 and v267 > -1.1754943508222875E-38 and v267 < 1.1754943508222875E-38 then
        v327 = to_bits(v267)
    else
        buffer.writef32(v90, 0, v267)
        v327 = buffer.readu32(v90, 0)
    end

    v328 = contact.tag
    p83[53] = v324
    p83[54] = v326
    p83[55] = v327
    p83[56] = v328
    p83[21] = 0
    p83[22] = 0
    p83[23] = 0
    p83[24] = 0
    p84[16] = v272
    p84[20] = v253
    p84[21] = 0
    p84[22] = 0
    p84[23] = 0
    p84[24] = 0
    p84[29] = v243
    p84[30] = v244
    p84[31] = v245
    p84[41] = v246
    p84[42] = v247
    p84[43] = v248
    p84[53] = v249
    p84[54] = v266
    p84[55] = v267

    return v300, v304
end

function t1.collision_contact(p90, p91, p92, p93, p94) -- line: 2103
    -- upvalues: v10 (ref), v11 (ref)
    local v332 = table.create(64, 0)

    v11()

    local v333, v334 = v10(v332, nil, p90, p91, p92, p93, p94)

    return {
        words = v332,
        reaction_index_a = v333,
        reaction_index_b = v334
    }
end

function t1.collision_contact_floats(p95, p96, p97, p98, p99) -- line: 2120
    -- upvalues: v10 (ref), v11 (ref)
    local v335 = table.create(64, 0)
    local v336 = table.create(64, false)

    v11()

    local v337, v338 = v10(v335, v336, p95, p96, p97, p98, p99)

    return {
        words = v335,
        reaction_index_a = v337,
        reaction_index_b = v338
    }, v336
end

function t1.collision_rows(p100, p101, p102, p103, p104) -- line: 2132
    -- upvalues: v10 (ref), v11 (ref)
    local v339 = table.create(#p100)
    local v340 = table.create(#p100)

    v11()

    for v341, v342 in p100 do
        local v343 = table.create(64, 0)
        local v344 = table.create(64, false)
        local v345, v346 = v10(v343, v344, v342, p101, p102, p103, p104)

        v339[v341] = {
            words = v343,
            reaction_index_a = v345,
            reaction_index_b = v346
        }
        v340[v341] = v344
    end

    return v339, v340
end

function t1.collision_contact_reference(p105, p106, p107, p108, p109) -- line: 2147
    -- upvalues: rt (copy), generate_contact (copy), build_contact_jacobian (copy), t1 (copy)
    return build_contact_jacobian(generate_contact(rt.copy(p105.contact), t1.contact_body(p105.body_a, p106, p107, p108), t1.contact_body(p105.body_b, p106, p107, p108)), p109)
end

return t1
