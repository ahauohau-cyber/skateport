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
local Vector3 = import("skate_core/math").Vector3
local v8 = import("skate_core/physics/board")
local BODY_COUNT, BodyId = v8.BODY_COUNT, v8.BodyId
local v9 = import("skate_core/physics/board_pose")
local part_transform, set_board_transform, set_part_transform = v9.part_transform, v9.set_board_transform, v9.set_part_transform
local BoardStep = import("skate_core/physics/board_step").BoardStep
local RetailAffineTransform = import("skate_core/physics/drive_frames").RetailAffineTransform
local BoardForceQueue = import("skate_core/physics/force_queue").BoardForceQueue
local HookDriveState = import("skate_core/physics/hook_drive").HookDriveState
local v10 = import("skate_core/physics/rigid_body")
local RetailQuaternion, world_inverse_inertia = v10.RetailQuaternion, v10.world_inverse_inertia
local t1 = {
    BoardMotion = {}
}

function t1.BoardMotion.flags(p4) -- line: 67
    if p4 == "Active" then
        return 4
    end

    if p4 == "Frozen" then
        return 2
    end

    return 1
end

t1.BoardRuntime = {}

function t1.BoardRuntime.take_solver_diagnostics(p5, p6) -- line: 88
    p5.step.diagnostic_capture = p6

    local diagnostic_snapshot = p5.step.diagnostic_snapshot

    p5.step.diagnostic_snapshot = nil

    return diagnostic_snapshot
end

function t1.BoardRuntime.new(p7, p8, p9, p10, p11) -- line: 98
    -- upvalues: rt (copy), BODY_COUNT (copy), set_board_transform (copy), set_part_transform (copy), BoardStep (copy), RetailAffineTransform (copy), BoardForceQueue (copy), HookDriveState (copy), t1 (copy)
    local v11 = rt.from_fn(BODY_COUNT, function(p12) -- line: 99
        -- upvalues: p7 (copy), p8 (copy), p11 (copy), set_part_transform (copy), t1 (copy)
        local t2 = {
            transform = t1.pose_words(p8[p12 + 1]),
            local_mass_frame = t1.mass_frame_words(p7[p12 + 1].local_mass_frame),
            body = table.create(44, 0),
            inertia = if p11 == "Static" then nil else t1.inertia_words(p7[p12 + 1].dynamics)
        }

        set_part_transform(t2, t1.pose_words(p8[p12 + 1]))

        return t2
    end)
    local t3 = {
        local_mass_frame = nil,
        inertia = nil,
        transform = t1.pose_words(RetailAffineTransform.IDENTITY),
        body = table.create(44, 0)
    }

    set_board_transform(v11, t3, t1.pose_words(p9))

    local v12 = rt.from_fn(BODY_COUNT, function(p13) -- line: 116
        -- upvalues: p7 (copy), p10 (copy), p11 (copy), v11 (copy), t1 (copy)
        return t1.initialized_body(v11[p13 + 1], p7[p13 + 1].dynamics, p10, p11)
    end)
    local t4 = {
        body = t1.initialized_body(t3, t1.ZERO_INERTIA, p10, "Static"),
        drive = HookDriveState.initial()
    }

    return {
        collision_group = 4,
        bodies = v12,
        mass_frames = rt.map(p7, function(p14) -- line: 128
            -- upvalues: rt (copy)
            return rt.copy(p14.local_mass_frame)
        end),
        hook = t4,
        step = BoardStep.default(),
        forces = BoardForceQueue.default()
    }
end

function t1.BoardRuntime.collision_group(p15) -- line: 138
    return p15.collision_group
end

function t1.BoardRuntime.set_collision_group(p16, p17) -- line: 143
    p16.collision_group = p17
end

function t1.BoardRuntime.bodies(p18) -- line: 148
    return p18.bodies
end

function t1.BoardRuntime.reset_physical(p19, p20, p21, p22, p23) -- line: 155
    -- upvalues: rt (copy), Vector3 (copy), BODY_COUNT (copy), set_board_transform (copy), set_part_transform (copy), BoardStep (copy), BoardForceQueue (copy), world_inverse_inertia (copy), t1 (copy)
    local v13 = rt.copy(p21)
    local v14 = rt.from_fn(BODY_COUNT, function(p24) -- line: 157
        -- upvalues: p19 (copy), p20 (copy), t1 (copy)
        return {
            transform = t1.pose_words(p20[p24 + 1]),
            local_mass_frame = t1.mass_frame_words(p19.mass_frames[p24 + 1]),
            body = t1.body_pose_words(p19.bodies[p24 + 1].rates),
            inertia = t1.inertia_words(p19.bodies[p24 + 1].inertia)
        }
    end)

    for _, v15 in { 6, 0, 1, 2, 3, 4, 5 } do
        set_part_transform(v14[v15 + 1], t1.pose_words(p20[v15 + 1]))
    end

    if bit32.band(p22, 1048576) ~= 0 then
        for _, v16 in { 0, 2 } do
            v13.basis.columns[v16 + 1] = rt.map(v13.basis.columns[v16 + 1], function(p25) -- line: 170
                return -p25
            end)
        end
    end

    local t5 = {
        local_mass_frame = nil,
        inertia = nil,
        transform = t1.pose_words(t1.BoardRuntime.hook_transform(p19)),
        body = t1.body_pose_words(p19.hook.body.rates)
    }

    set_board_transform(v14, t5, t1.pose_words(v13))

    for i = 1, BODY_COUNT do
        local v17 = p19.bodies[i]
        local v18 = v14[i]

        t1.copy_pose(v18, v17.rates)
        v17.rates.linear_velocity = rt.copy(Vector3.ZERO)
        v17.rates.angular_velocity = rt.copy(Vector3.ZERO)
        v17.rates.force_acceleration = rt.copy(p23)
        v17.rates.torque_acceleration = rt.copy(Vector3.ZERO)
        v17.rates.world_inverse_inertia = world_inverse_inertia(v17.rates.basis, v17.inertia.inverse_tensor)
    end

    t1.copy_pose(t5, p19.hook.body.rates)
    BoardForceQueue.clear(p19.forces)
    p19.step = BoardStep.default()
end

function t1.BoardRuntime.set_transform(p26, p27) -- line: 202
    -- upvalues: rt (copy), BODY_COUNT (copy), set_board_transform (copy), world_inverse_inertia (copy), t1 (copy)
    local v19 = t1.BoardRuntime.part_transforms(p26)
    local v20 = rt.from_fn(BODY_COUNT, function(p28) -- line: 204
        -- upvalues: p26 (copy), v19 (copy), t1 (copy)
        return {
            transform = t1.pose_words(v19[p28 + 1]),
            local_mass_frame = t1.mass_frame_words(p26.mass_frames[p28 + 1]),
            body = t1.body_pose_words(p26.bodies[p28 + 1].rates),
            inertia = t1.inertia_words(p26.bodies[p28 + 1].inertia)
        }
    end)
    local t6 = {
        local_mass_frame = nil,
        inertia = nil,
        transform = t1.pose_words(t1.BoardRuntime.hook_transform(p26)),
        body = t1.body_pose_words(p26.hook.body.rates)
    }

    set_board_transform(v20, t6, t1.pose_words(p27))

    for i = 1, BODY_COUNT do
        local v21 = p26.bodies[i]
        local v22 = v20[i]

        t1.copy_pose(v22, v21.rates)
        v21.rates.world_inverse_inertia = world_inverse_inertia(v21.rates.basis, v21.inertia.inverse_tensor)
    end

    t1.copy_pose(t6, p26.hook.body.rates)
end

function t1.BoardRuntime.bodies_mut(p29) -- line: 230
    return p29.bodies
end

function t1.BoardRuntime.hook(p30) -- line: 234
    return p30.hook
end

function t1.BoardRuntime.hook_mut(p31) -- line: 239
    return p31.hook
end

function t1.BoardRuntime.forces(p32) -- line: 243
    return p32.forces
end

function t1.BoardRuntime.contact_reports(p33) -- line: 247
    -- upvalues: BoardStep (copy)
    return BoardStep.contact_reports(p33.step)
end

function t1.BoardRuntime.solved_reactions(p34) -- line: 252
    -- upvalues: BoardStep (copy)
    return BoardStep.solved_reactions(p34.step)
end

function t1.BoardRuntime.solved_contacts(p35) -- line: 256
    -- upvalues: BoardStep (copy)
    return BoardStep.solved_contacts(p35.step)
end

function t1.BoardRuntime.forces_mut(p36) -- line: 260
    return p36.forces
end

function t1.BoardRuntime.clear_forces(p37) -- line: 266
    -- upvalues: BoardForceQueue (copy)
    BoardForceQueue.clear(p37.forces)
end

function t1.BoardRuntime.advance(p38, p39, p40, p41) -- line: 270
    -- upvalues: BoardStep (copy)
    BoardStep.advance(p38.step, p38.bodies, p38.hook, p38.forces, p39, p40, p41)
end

function t1.BoardRuntime.advance_attached(p42, p43, p44, p45, p46) -- line: 276
    -- upvalues: BoardStep (copy)
    BoardStep.advance_attached(p42.step, p42.bodies, p42.hook, p42.forces, p43, p44, p45, p46)
end

function t1.BoardRuntime.body_transform(p47, p48) -- line: 290
    -- upvalues: BodyId (copy), t1 (copy)
    return t1.rates_transform(p47.bodies[BodyId.index(p48) + 1].rates)
end

function t1.BoardRuntime.part_transforms_reference(p49) -- line: 298
    -- upvalues: rt (copy), BODY_COUNT (copy), part_transform (copy), t1 (copy)
    return rt.from_fn(BODY_COUNT, function(p50) -- line: 299
        -- upvalues: p49 (copy), part_transform (copy), t1 (copy)
        local t7 = {
            inertia = nil,
            transform = t1.pose_words(t1.rates_transform(p49.bodies[p50 + 1].rates)),
            local_mass_frame = t1.mass_frame_words(p49.mass_frames[p50 + 1]),
            body = t1.body_pose_words(p49.bodies[p50 + 1].rates)
        }

        return t1.transform_from_words(part_transform(t7))
    end)
end

local v23 = buffer.create(8)
local to_bits = rt.to_bits

local function f32r(p51) -- line: 317
    -- upvalues: v23 (copy), to_bits (copy)
    if p51 ~= 0 and p51 > -1.1754943508222875E-38 and p51 < 1.1754943508222875E-38 then
        buffer.writeu32(v23, 0, to_bits(p51))

        return (buffer.readf32(v23, 0))
    end

    buffer.writef32(v23, 0, p51)

    return (buffer.readf32(v23, 0))
end

local function f32r3(p52, p53, p54) -- line: 334
    -- upvalues: v23 (copy), to_bits (copy)
    local v24, v25

    if p52 < 1.1754943508222875E-38 and p52 > -1.1754943508222875E-38 and p52 ~= 0 then
        if p52 ~= 0 and p52 > -1.1754943508222875E-38 and p52 < 1.1754943508222875E-38 then
            buffer.writeu32(v23, 0, to_bits(p52))
        else
            buffer.writef32(v23, 0, p52)
        end

        v24 = buffer.readf32(v23, 0)

        if p53 ~= 0 and p53 > -1.1754943508222875E-38 and p53 < 1.1754943508222875E-38 then
            buffer.writeu32(v23, 0, to_bits(p53))
        else
            buffer.writef32(v23, 0, p53)
        end

        v25 = buffer.readf32(v23, 0)

        if p54 ~= 0 and p54 > -1.1754943508222875E-38 and p54 < 1.1754943508222875E-38 then
            buffer.writeu32(v23, 0, to_bits(p54))

            return v24, v25, (buffer.readf32(v23, 0))
        end

        buffer.writef32(v23, 0, p54)

        return v24, v25, (buffer.readf32(v23, 0))
    end

    if p53 < 1.1754943508222875E-38 and p53 > -1.1754943508222875E-38 and p53 ~= 0 or p54 < 1.1754943508222875E-38 and p54 > -1.1754943508222875E-38 and p54 ~= 0 then
        if p52 == 0 then
            buffer.writef32(v23, 0, p52)
        elseif p52 > -1.1754943508222875E-38 and p52 < 1.1754943508222875E-38 then
            buffer.writeu32(v23, 0, to_bits(p52))
        else
            buffer.writef32(v23, 0, p52)
        end

        v24 = buffer.readf32(v23, 0)

        if p53 == 0 then
            buffer.writef32(v23, 0, p53)
        elseif p53 > -1.1754943508222875E-38 and p53 < 1.1754943508222875E-38 then
            buffer.writeu32(v23, 0, to_bits(p53))
        else
            buffer.writef32(v23, 0, p53)
        end

        v25 = buffer.readf32(v23, 0)

        if p54 ~= 0 and p54 > -1.1754943508222875E-38 and p54 < 1.1754943508222875E-38 then
            buffer.writeu32(v23, 0, to_bits(p54))

            return v24, v25, (buffer.readf32(v23, 0))
        end

        buffer.writef32(v23, 0, p54)

        return v24, v25, (buffer.readf32(v23, 0))
    end

    local v26 = vector.create(p52, p53, p54)

    return v26.x, v26.y, v26.z
end

function t1.BoardRuntime.part_transforms(p55) -- line: 346
    -- upvalues: Vector3 (copy), BODY_COUNT (copy), f32r3 (copy)
    local v27 = table.create(BODY_COUNT)
    local bodies, mass_frames = p55.bodies, p55.mass_frames

    for i = 1, BODY_COUNT do
        local rates = bodies[i].rates
        local v28 = mass_frames[i]
        local columns = rates.basis.columns
        local v29 = columns[1]
        local v30 = columns[2]
        local v31 = columns[3]
        local v32, v33, v34 = f32r3(v29[1], v29[2], v29[3])
        local v35, v36, v37 = f32r3(v30[1], v30[2], v30[3])
        local v38, v39, v40 = f32r3(v31[1], v31[2], v31[3])
        local position = rates.position
        local v41, v42, v43 = f32r3(position.x, position.y, position.z)
        local columns2 = v28.basis.columns
        local v44 = table.create(3)

        for j = 1, 3 do
            local v45 = columns2[j]
            local v46, v47, v48 = f32r3(v45[1], v45[2], v45[3])
            local v49, v50, v51 = f32r3(v48 * v38 + (v47 * v35 + v46 * v32), v48 * v39 + (v47 * v36 + v46 * v33), v48 * v40 + (v47 * v37 + v46 * v34))

            v44[j] = { v49, v50, v51 }
        end

        local translation = v28.translation
        local v52, v53, v54 = f32r3(translation.x, translation.y, translation.z)
        local v55, v56, v57 = f32r3(v54 * v38 + (v53 * v35 + (v52 * v32 + v41)), v54 * v39 + (v53 * v36 + (v52 * v33 + v42)), v54 * v40 + (v53 * v37 + (v52 * v34 + v43)))

        v27[i] = {
            basis = {
                columns = v44
            },
            translation = Vector3.new(v55, v56, v57)
        }
    end

    return v27
end

function t1.BoardRuntime.part_transforms_r3(p56) -- line: 393
    -- upvalues: Vector3 (copy), BODY_COUNT (copy), v23 (copy), to_bits (copy)
    local v58 = table.create(BODY_COUNT)
    local bodies, mass_frames = p56.bodies, p56.mass_frames

    for i = 1, BODY_COUNT do
        local rates = bodies[i].rates
        local v59 = mass_frames[i]
        local columns = rates.basis.columns
        local v60 = columns[1]
        local v61 = columns[2]
        local v62 = columns[3]
        local v63 = v60[1]

        if v63 ~= 0 and v63 > -1.1754943508222875E-38 and v63 < 1.1754943508222875E-38 then
            buffer.writeu32(v23, 0, to_bits(v63))
        else
            buffer.writef32(v23, 0, v63)
        end

        local v64 = buffer.readf32(v23, 0)

        v63 = v60[2]

        if v63 ~= 0 and v63 > -1.1754943508222875E-38 and v63 < 1.1754943508222875E-38 then
            buffer.writeu32(v23, 0, to_bits(v63))
        else
            buffer.writef32(v23, 0, v63)
        end

        local v65 = buffer.readf32(v23, 0)

        v63 = v60[3]

        if v63 ~= 0 and v63 > -1.1754943508222875E-38 and v63 < 1.1754943508222875E-38 then
            buffer.writeu32(v23, 0, to_bits(v63))
        else
            buffer.writef32(v23, 0, v63)
        end

        local v66 = buffer.readf32(v23, 0)
        local v67 = v61[1]

        if v67 ~= 0 and v67 > -1.1754943508222875E-38 and v67 < 1.1754943508222875E-38 then
            buffer.writeu32(v23, 0, to_bits(v67))
        else
            buffer.writef32(v23, 0, v67)
        end

        v63 = buffer.readf32(v23, 0)
        v67 = v61[2]

        if v67 ~= 0 and v67 > -1.1754943508222875E-38 and v67 < 1.1754943508222875E-38 then
            buffer.writeu32(v23, 0, to_bits(v67))
        else
            buffer.writef32(v23, 0, v67)
        end

        local v68 = buffer.readf32(v23, 0)

        v67 = v61[3]

        if v67 ~= 0 and v67 > -1.1754943508222875E-38 and v67 < 1.1754943508222875E-38 then
            buffer.writeu32(v23, 0, to_bits(v67))
        else
            buffer.writef32(v23, 0, v67)
        end

        local v69 = buffer.readf32(v23, 0)
        local v70 = v62[1]

        if v70 ~= 0 and v70 > -1.1754943508222875E-38 and v70 < 1.1754943508222875E-38 then
            buffer.writeu32(v23, 0, to_bits(v70))
        else
            buffer.writef32(v23, 0, v70)
        end

        v67 = buffer.readf32(v23, 0)
        v70 = v62[2]

        if v70 ~= 0 and v70 > -1.1754943508222875E-38 and v70 < 1.1754943508222875E-38 then
            buffer.writeu32(v23, 0, to_bits(v70))
        else
            buffer.writef32(v23, 0, v70)
        end

        local v71 = buffer.readf32(v23, 0)

        v70 = v62[3]

        if v70 ~= 0 and v70 > -1.1754943508222875E-38 and v70 < 1.1754943508222875E-38 then
            buffer.writeu32(v23, 0, to_bits(v70))
        else
            buffer.writef32(v23, 0, v70)
        end

        local v72 = buffer.readf32(v23, 0)

        v62 = rates.position

        local v73 = v62.x

        if v73 ~= 0 and v73 > -1.1754943508222875E-38 and v73 < 1.1754943508222875E-38 then
            buffer.writeu32(v23, 0, to_bits(v73))
        else
            buffer.writef32(v23, 0, v73)
        end

        v70 = buffer.readf32(v23, 0)
        v73 = v62.y

        if v73 ~= 0 and v73 > -1.1754943508222875E-38 and v73 < 1.1754943508222875E-38 then
            buffer.writeu32(v23, 0, to_bits(v73))
        else
            buffer.writef32(v23, 0, v73)
        end

        local v74 = buffer.readf32(v23, 0)

        v73 = v62.z

        if v73 ~= 0 and v73 > -1.1754943508222875E-38 and v73 < 1.1754943508222875E-38 then
            buffer.writeu32(v23, 0, to_bits(v73))
        else
            buffer.writef32(v23, 0, v73)
        end

        local v75 = buffer.readf32(v23, 0)

        v62 = v59.basis.columns
        v73 = table.create(3)

        local v76, v77, v78, v79, v80, v81

        for j = 1, 3 do
            v60 = v62[j]
            v76 = v60[1]

            if v76 ~= 0 and v76 > -1.1754943508222875E-38 and v76 < 1.1754943508222875E-38 then
                buffer.writeu32(v23, 0, to_bits(v76))
            else
                buffer.writef32(v23, 0, v76)
            end

            v78 = buffer.readf32(v23, 0)
            v76 = v60[2]

            if v76 ~= 0 and v76 > -1.1754943508222875E-38 and v76 < 1.1754943508222875E-38 then
                buffer.writeu32(v23, 0, to_bits(v76))
            else
                buffer.writef32(v23, 0, v76)
            end

            v79 = buffer.readf32(v23, 0)
            v76 = v60[3]

            if v76 ~= 0 and v76 > -1.1754943508222875E-38 and v76 < 1.1754943508222875E-38 then
                buffer.writeu32(v23, 0, to_bits(v76))
            else
                buffer.writef32(v23, 0, v76)
            end

            v77 = buffer.readf32(v23, 0)
            v76 = {}
            v81 = v77 * v67 + (v79 * v63 + v78 * v64)

            if v81 ~= 0 and v81 > -1.1754943508222875E-38 and v81 < 1.1754943508222875E-38 then
                buffer.writeu32(v23, 0, to_bits(v81))
            else
                buffer.writef32(v23, 0, v81)
            end

            v80 = buffer.readf32(v23, 0)

            local v82 = v77 * v71 + (v79 * v68 + v78 * v65)

            if v82 ~= 0 and v82 > -1.1754943508222875E-38 and v82 < 1.1754943508222875E-38 then
                buffer.writeu32(v23, 0, to_bits(v82))
            else
                buffer.writef32(v23, 0, v82)
            end

            v81 = buffer.readf32(v23, 0)

            local v83 = v77 * v72 + (v79 * v69 + v78 * v66)

            if v83 ~= 0 and v83 > -1.1754943508222875E-38 and v83 < 1.1754943508222875E-38 then
                buffer.writeu32(v23, 0, to_bits(v83))
            else
                buffer.writef32(v23, 0, v83)
            end

            v82 = buffer.readf32(v23, 0)
            v76[1] = v80
            v76[2] = v81
            v76[3] = v82
            v73[j] = v76
        end

        v62 = v59.translation
        v78 = v62.x

        if v78 ~= 0 and v78 > -1.1754943508222875E-38 and v78 < 1.1754943508222875E-38 then
            buffer.writeu32(v23, 0, to_bits(v78))
        else
            buffer.writef32(v23, 0, v78)
        end

        local v84 = buffer.readf32(v23, 0)

        v78 = v62.y

        if v78 ~= 0 and v78 > -1.1754943508222875E-38 and v78 < 1.1754943508222875E-38 then
            buffer.writeu32(v23, 0, to_bits(v78))
        else
            buffer.writef32(v23, 0, v78)
        end

        local v85 = buffer.readf32(v23, 0)

        v78 = v62.z

        if v78 ~= 0 and v78 > -1.1754943508222875E-38 and v78 < 1.1754943508222875E-38 then
            buffer.writeu32(v23, 0, to_bits(v78))
        else
            buffer.writef32(v23, 0, v78)
        end

        local v86 = buffer.readf32(v23, 0)

        v78 = {
            basis = {
                columns = v73
            }
        }
        v79 = Vector3.new
        v76 = v86 * v67 + (v85 * v63 + (v84 * v64 + v70))

        if v76 ~= 0 and v76 > -1.1754943508222875E-38 and v76 < 1.1754943508222875E-38 then
            buffer.writeu32(v23, 0, to_bits(v76))
        else
            buffer.writef32(v23, 0, v76)
        end

        v77 = buffer.readf32(v23, 0)
        v80 = v86 * v71 + (v85 * v68 + (v84 * v65 + v74))

        if v80 ~= 0 and v80 > -1.1754943508222875E-38 and v80 < 1.1754943508222875E-38 then
            buffer.writeu32(v23, 0, to_bits(v80))
        else
            buffer.writef32(v23, 0, v80)
        end

        v76 = buffer.readf32(v23, 0)
        v81 = v86 * v72 + (v85 * v69 + (v84 * v66 + v75))

        if v81 ~= 0 and v81 > -1.1754943508222875E-38 and v81 < 1.1754943508222875E-38 then
            buffer.writeu32(v23, 0, to_bits(v81))
        else
            buffer.writef32(v23, 0, v81)
        end

        v78.translation = v79(v77, v76, (buffer.readf32(v23, 0)))
        v58[i] = v78
    end

    return v58
end

function t1.BoardRuntime.transform_scratch() -- line: 433
    -- upvalues: Vector3 (copy)
    return {
        basis = {
            columns = {
                { 0, 0, 0 },
                { 0, 0, 0 },
                { 0, 0, 0 }
            }
        },
        translation = Vector3.new(0, 0, 0)
    }
end

function t1.BoardRuntime.poses_scratch() -- line: 445
    -- upvalues: BODY_COUNT (copy), t1 (copy)
    local v87 = table.create(BODY_COUNT)

    for i = 1, BODY_COUNT do
        v87[i] = t1.BoardRuntime.transform_scratch()
    end

    return v87
end

function t1.BoardRuntime.part_transforms_into(p57, p58) -- line: 453
    -- upvalues: BODY_COUNT (copy), f32r3 (copy)
    local bodies, mass_frames = p57.bodies, p57.mass_frames

    for i = 1, BODY_COUNT do
        local rates = bodies[i].rates
        local v88 = mass_frames[i]
        local columns = rates.basis.columns
        local v89 = columns[1]
        local v90 = columns[2]
        local v91 = columns[3]
        local v92, v93, v94 = f32r3(v89[1], v89[2], v89[3])
        local v95, v96, v97 = f32r3(v90[1], v90[2], v90[3])
        local v98, v99, v100 = f32r3(v91[1], v91[2], v91[3])
        local position = rates.position
        local v101, v102, v103 = f32r3(position.x, position.y, position.z)
        local columns2 = v88.basis.columns
        local v104 = p58[i]
        local columns3 = v104.basis.columns

        for j = 1, 3 do
            local v105 = columns2[j]
            local v106, v107, v108 = f32r3(v105[1], v105[2], v105[3])
            local v109, v110, v111 = f32r3(v108 * v98 + (v107 * v95 + v106 * v92), v108 * v99 + (v107 * v96 + v106 * v93), v108 * v100 + (v107 * v97 + v106 * v94))
            local v112 = columns3[j]

            v112[1] = v109
            v112[2] = v110
            v112[3] = v111
        end

        local translation = v88.translation
        local v113, v114, v115 = f32r3(translation.x, translation.y, translation.z)
        local v116, v117, v118 = f32r3(v115 * v98 + (v114 * v95 + (v113 * v92 + v101)), v115 * v99 + (v114 * v96 + (v113 * v93 + v102)), v115 * v100 + (v114 * v97 + (v113 * v94 + v103)))
        local translation2 = v104.translation

        translation2.x = v116
        translation2.y = v117
        translation2.z = v118
    end

    return p58
end

function t1.BoardRuntime.part_transform_into_reference(p59, p60, p61) -- line: 496
    -- upvalues: t1 (copy)
    local v119 = t1.BoardRuntime.part_transforms_reference(p59)[p60 + 1]
    local columns = p61.basis.columns

    for i = 1, 3 do
        local v120 = columns[i]
        local v121 = v119.basis.columns[i]
        local v122 = v121[1]
        local v123 = v121[2]
        local v124 = v121[3]

        v120[1] = v122
        v120[2] = v123
        v120[3] = v124
    end

    local translation = p61.translation
    local x, y, z = v119.translation.x, v119.translation.y, v119.translation.z

    translation.x = x
    translation.y = y
    translation.z = z

    return p61
end

function t1.BoardRuntime.part_transform_into(p62, p63, p64) -- line: 515
    -- upvalues: f32r3 (copy)
    local rates = p62.bodies[p63 + 1].rates
    local v125 = p62.mass_frames[p63 + 1]
    local columns = rates.basis.columns
    local v126 = columns[1]
    local v127 = columns[2]
    local v128 = columns[3]
    local v129, v130, v131 = f32r3(v126[1], v126[2], v126[3])
    local v132, v133, v134 = f32r3(v127[1], v127[2], v127[3])
    local v135, v136, v137 = f32r3(v128[1], v128[2], v128[3])
    local position = rates.position
    local v138, v139, v140 = f32r3(position.x, position.y, position.z)
    local columns2 = v125.basis.columns
    local columns3 = p64.basis.columns

    for i = 1, 3 do
        local v141 = columns2[i]
        local v142, v143, v144 = f32r3(v141[1], v141[2], v141[3])
        local v145 = columns3[i]
        local v146, v147, v148 = f32r3(v144 * v135 + (v143 * v132 + v142 * v129), v144 * v136 + (v143 * v133 + v142 * v130), v144 * v137 + (v143 * v134 + v142 * v131))

        v145[1] = v146
        v145[2] = v147
        v145[3] = v148
    end

    local translation = v125.translation
    local v149, v150, v151 = f32r3(translation.x, translation.y, translation.z)
    local translation2 = p64.translation
    local v152, v153, v154 = f32r3(v151 * v135 + (v150 * v132 + (v149 * v129 + v138)), v151 * v136 + (v150 * v133 + (v149 * v130 + v139)), v151 * v137 + (v150 * v134 + (v149 * v131 + v140)))

    translation2.x = v152
    translation2.y = v153
    translation2.z = v154

    return p64
end

function t1.BoardRuntime.part_transform_into_r3(p65, p66, p67) -- line: 555
    -- upvalues: v23 (copy), to_bits (copy)
    local rates = p65.bodies[p66 + 1].rates
    local v155 = p65.mass_frames[p66 + 1]
    local columns = rates.basis.columns
    local v156 = columns[1]
    local columns2 = columns[2]
    local v157 = columns[3]
    local v158 = v156[1]

    if v158 ~= 0 and v158 > -1.1754943508222875E-38 and v158 < 1.1754943508222875E-38 then
        buffer.writeu32(v23, 0, to_bits(v158))
    else
        buffer.writef32(v23, 0, v158)
    end

    local v159 = buffer.readf32(v23, 0)

    v158 = v156[2]

    if v158 ~= 0 and v158 > -1.1754943508222875E-38 and v158 < 1.1754943508222875E-38 then
        buffer.writeu32(v23, 0, to_bits(v158))
    else
        buffer.writef32(v23, 0, v158)
    end

    local v160 = buffer.readf32(v23, 0)

    v158 = v156[3]

    if v158 ~= 0 and v158 > -1.1754943508222875E-38 and v158 < 1.1754943508222875E-38 then
        buffer.writeu32(v23, 0, to_bits(v158))
    else
        buffer.writef32(v23, 0, v158)
    end

    local v161 = buffer.readf32(v23, 0)
    local v162 = columns2[1]

    if v162 ~= 0 and v162 > -1.1754943508222875E-38 and v162 < 1.1754943508222875E-38 then
        buffer.writeu32(v23, 0, to_bits(v162))
    else
        buffer.writef32(v23, 0, v162)
    end

    v158 = buffer.readf32(v23, 0)
    v162 = columns2[2]

    if v162 ~= 0 and v162 > -1.1754943508222875E-38 and v162 < 1.1754943508222875E-38 then
        buffer.writeu32(v23, 0, to_bits(v162))
    else
        buffer.writef32(v23, 0, v162)
    end

    local v163 = buffer.readf32(v23, 0)

    v162 = columns2[3]

    if v162 ~= 0 and v162 > -1.1754943508222875E-38 and v162 < 1.1754943508222875E-38 then
        buffer.writeu32(v23, 0, to_bits(v162))
    else
        buffer.writef32(v23, 0, v162)
    end

    local v164 = buffer.readf32(v23, 0)
    local v165 = v157[1]

    if v165 ~= 0 and v165 > -1.1754943508222875E-38 and v165 < 1.1754943508222875E-38 then
        buffer.writeu32(v23, 0, to_bits(v165))
    else
        buffer.writef32(v23, 0, v165)
    end

    v162 = buffer.readf32(v23, 0)
    v165 = v157[2]

    if v165 ~= 0 and v165 > -1.1754943508222875E-38 and v165 < 1.1754943508222875E-38 then
        buffer.writeu32(v23, 0, to_bits(v165))
    else
        buffer.writef32(v23, 0, v165)
    end

    local v166 = buffer.readf32(v23, 0)

    v165 = v157[3]

    if v165 ~= 0 and v165 > -1.1754943508222875E-38 and v165 < 1.1754943508222875E-38 then
        buffer.writeu32(v23, 0, to_bits(v165))
    else
        buffer.writef32(v23, 0, v165)
    end

    local v167 = buffer.readf32(v23, 0)

    v157 = rates.position

    local v168 = v157.x

    if v168 ~= 0 and v168 > -1.1754943508222875E-38 and v168 < 1.1754943508222875E-38 then
        buffer.writeu32(v23, 0, to_bits(v168))
    else
        buffer.writef32(v23, 0, v168)
    end

    v165 = buffer.readf32(v23, 0)
    v168 = v157.y

    if v168 ~= 0 and v168 > -1.1754943508222875E-38 and v168 < 1.1754943508222875E-38 then
        buffer.writeu32(v23, 0, to_bits(v168))
    else
        buffer.writef32(v23, 0, v168)
    end

    local v169 = buffer.readf32(v23, 0)

    v168 = v157.z

    if v168 ~= 0 and v168 > -1.1754943508222875E-38 and v168 < 1.1754943508222875E-38 then
        buffer.writeu32(v23, 0, to_bits(v168))
    else
        buffer.writef32(v23, 0, v168)
    end

    local v170 = buffer.readf32(v23, 0)

    v157 = v155.basis.columns
    columns2 = p67.basis.columns

    local v171, v172

    for i = 1, 3 do
        v156 = v157[i]

        local v173 = v156[1]

        if v173 ~= 0 and v173 > -1.1754943508222875E-38 and v173 < 1.1754943508222875E-38 then
            buffer.writeu32(v23, 0, to_bits(v173))
        else
            buffer.writef32(v23, 0, v173)
        end

        v171 = buffer.readf32(v23, 0)
        v173 = v156[2]

        if v173 ~= 0 and v173 > -1.1754943508222875E-38 and v173 < 1.1754943508222875E-38 then
            buffer.writeu32(v23, 0, to_bits(v173))
        else
            buffer.writef32(v23, 0, v173)
        end

        v172 = buffer.readf32(v23, 0)
        v173 = v156[3]

        if v173 ~= 0 and v173 > -1.1754943508222875E-38 and v173 < 1.1754943508222875E-38 then
            buffer.writeu32(v23, 0, to_bits(v173))
        else
            buffer.writef32(v23, 0, v173)
        end

        local v174 = buffer.readf32(v23, 0)

        v156 = columns2[i]

        local v175 = v174 * v162 + (v172 * v158 + v171 * v159)

        if v175 ~= 0 and v175 > -1.1754943508222875E-38 and v175 < 1.1754943508222875E-38 then
            buffer.writeu32(v23, 0, to_bits(v175))
        else
            buffer.writef32(v23, 0, v175)
        end

        v156[1] = buffer.readf32(v23, 0)
        v175 = v174 * v166 + (v172 * v163 + v171 * v160)

        if v175 ~= 0 and v175 > -1.1754943508222875E-38 and v175 < 1.1754943508222875E-38 then
            buffer.writeu32(v23, 0, to_bits(v175))
        else
            buffer.writef32(v23, 0, v175)
        end

        v156[2] = buffer.readf32(v23, 0)
        v175 = v174 * v167 + (v172 * v164 + v171 * v161)

        if v175 ~= 0 and v175 > -1.1754943508222875E-38 and v175 < 1.1754943508222875E-38 then
            buffer.writeu32(v23, 0, to_bits(v175))
        else
            buffer.writef32(v23, 0, v175)
        end

        v156[3] = buffer.readf32(v23, 0)
    end

    v157 = v155.translation
    v171 = v157.x

    if v171 ~= 0 and v171 > -1.1754943508222875E-38 and v171 < 1.1754943508222875E-38 then
        buffer.writeu32(v23, 0, to_bits(v171))
    else
        buffer.writef32(v23, 0, v171)
    end

    v168 = buffer.readf32(v23, 0)
    v171 = v157.y

    if v171 ~= 0 and v171 > -1.1754943508222875E-38 and v171 < 1.1754943508222875E-38 then
        buffer.writeu32(v23, 0, to_bits(v171))
    else
        buffer.writef32(v23, 0, v171)
    end

    local v176 = buffer.readf32(v23, 0)

    v171 = v157.z

    if v171 ~= 0 and v171 > -1.1754943508222875E-38 and v171 < 1.1754943508222875E-38 then
        buffer.writeu32(v23, 0, to_bits(v171))
    else
        buffer.writef32(v23, 0, v171)
    end

    local v177 = buffer.readf32(v23, 0)

    v157 = p67.translation
    v172 = v177 * v162 + (v176 * v158 + (v168 * v159 + v165))

    if v172 ~= 0 and v172 > -1.1754943508222875E-38 and v172 < 1.1754943508222875E-38 then
        buffer.writeu32(v23, 0, to_bits(v172))
    else
        buffer.writef32(v23, 0, v172)
    end

    v157.x = buffer.readf32(v23, 0)
    v172 = v177 * v166 + (v176 * v163 + (v168 * v160 + v169))

    if v172 ~= 0 and v172 > -1.1754943508222875E-38 and v172 < 1.1754943508222875E-38 then
        buffer.writeu32(v23, 0, to_bits(v172))
    else
        buffer.writef32(v23, 0, v172)
    end

    v157.y = buffer.readf32(v23, 0)
    v172 = v177 * v167 + (v176 * v164 + (v168 * v161 + v170))

    if v172 ~= 0 and v172 > -1.1754943508222875E-38 and v172 < 1.1754943508222875E-38 then
        buffer.writeu32(v23, 0, to_bits(v172))
    else
        buffer.writef32(v23, 0, v172)
    end

    v157.z = buffer.readf32(v23, 0)

    return p67
end

function t1.BoardRuntime.part_translation_reference(p68, p69) -- line: 585
    -- upvalues: t1 (copy)
    local translation = t1.BoardRuntime.part_transforms_reference(p68)[p69 + 1].translation

    return translation.x, translation.y, translation.z
end

function t1.BoardRuntime.part_translation(p70, p71) -- line: 593
    -- upvalues: f32r3 (copy)
    local rates = p70.bodies[p71 + 1].rates
    local columns = rates.basis.columns
    local v178 = columns[1]
    local v179 = columns[2]
    local v180 = columns[3]
    local v181, v182, v183 = f32r3(v178[1], v178[2], v178[3])
    local v184, v185, v186 = f32r3(v179[1], v179[2], v179[3])
    local v187, v188, v189 = f32r3(v180[1], v180[2], v180[3])
    local position = rates.position
    local v190, v191, v192 = f32r3(position.x, position.y, position.z)
    local translation = p70.mass_frames[p71 + 1].translation
    local v193, v194, v195 = f32r3(translation.x, translation.y, translation.z)

    return f32r3(v195 * v187 + (v194 * v184 + (v193 * v181 + v190)), v195 * v188 + (v194 * v185 + (v193 * v182 + v191)), v195 * v189 + (v194 * v186 + (v193 * v183 + v192)))
end

function t1.BoardRuntime.part_translation_r3(p72, p73) -- line: 618
    -- upvalues: v23 (copy), to_bits (copy)
    local rates = p72.bodies[p73 + 1].rates
    local columns = rates.basis.columns
    local v196 = columns[1]
    local v197 = columns[2]
    local v198 = columns[3]
    local v199 = v196[1]

    if v199 ~= 0 and v199 > -1.1754943508222875E-38 and v199 < 1.1754943508222875E-38 then
        buffer.writeu32(v23, 0, to_bits(v199))
    else
        buffer.writef32(v23, 0, v199)
    end

    local v200 = buffer.readf32(v23, 0)
    local v201 = v196[2]

    if v201 ~= 0 and v201 > -1.1754943508222875E-38 and v201 < 1.1754943508222875E-38 then
        buffer.writeu32(v23, 0, to_bits(v201))
    else
        buffer.writef32(v23, 0, v201)
    end

    local v202 = buffer.readf32(v23, 0)
    local v203 = v196[3]

    if v203 ~= 0 and v203 > -1.1754943508222875E-38 and v203 < 1.1754943508222875E-38 then
        buffer.writeu32(v23, 0, to_bits(v203))
    else
        buffer.writef32(v23, 0, v203)
    end

    local v204 = buffer.readf32(v23, 0)
    local v205 = v197[1]

    if v205 ~= 0 and v205 > -1.1754943508222875E-38 and v205 < 1.1754943508222875E-38 then
        buffer.writeu32(v23, 0, to_bits(v205))
    else
        buffer.writef32(v23, 0, v205)
    end

    local v206 = buffer.readf32(v23, 0)
    local v207 = v197[2]

    if v207 ~= 0 and v207 > -1.1754943508222875E-38 and v207 < 1.1754943508222875E-38 then
        buffer.writeu32(v23, 0, to_bits(v207))
    else
        buffer.writef32(v23, 0, v207)
    end

    local v208 = buffer.readf32(v23, 0)
    local v209 = v197[3]

    if v209 ~= 0 and v209 > -1.1754943508222875E-38 and v209 < 1.1754943508222875E-38 then
        buffer.writeu32(v23, 0, to_bits(v209))
    else
        buffer.writef32(v23, 0, v209)
    end

    local v210 = buffer.readf32(v23, 0)
    local v211 = v198[1]

    if v211 ~= 0 and v211 > -1.1754943508222875E-38 and v211 < 1.1754943508222875E-38 then
        buffer.writeu32(v23, 0, to_bits(v211))
    else
        buffer.writef32(v23, 0, v211)
    end

    local v212 = buffer.readf32(v23, 0)
    local v213 = v198[2]

    if v213 ~= 0 and v213 > -1.1754943508222875E-38 and v213 < 1.1754943508222875E-38 then
        buffer.writeu32(v23, 0, to_bits(v213))
    else
        buffer.writef32(v23, 0, v213)
    end

    local v214 = buffer.readf32(v23, 0)
    local v215 = v198[3]

    if v215 ~= 0 and v215 > -1.1754943508222875E-38 and v215 < 1.1754943508222875E-38 then
        buffer.writeu32(v23, 0, to_bits(v215))
    else
        buffer.writef32(v23, 0, v215)
    end

    local v216 = buffer.readf32(v23, 0)
    local position = rates.position
    local x = position.x

    if x ~= 0 and x > -1.1754943508222875E-38 and x < 1.1754943508222875E-38 then
        buffer.writeu32(v23, 0, to_bits(x))
    else
        buffer.writef32(v23, 0, x)
    end

    local v217 = buffer.readf32(v23, 0)
    local y = position.y

    if y ~= 0 and y > -1.1754943508222875E-38 and y < 1.1754943508222875E-38 then
        buffer.writeu32(v23, 0, to_bits(y))
    else
        buffer.writef32(v23, 0, y)
    end

    local v218 = buffer.readf32(v23, 0)
    local z = position.z

    if z ~= 0 and z > -1.1754943508222875E-38 and z < 1.1754943508222875E-38 then
        buffer.writeu32(v23, 0, to_bits(z))
    else
        buffer.writef32(v23, 0, z)
    end

    local v219 = buffer.readf32(v23, 0)
    local translation = p72.mass_frames[p73 + 1].translation
    local x2 = translation.x

    if x2 ~= 0 and x2 > -1.1754943508222875E-38 and x2 < 1.1754943508222875E-38 then
        buffer.writeu32(v23, 0, to_bits(x2))
    else
        buffer.writef32(v23, 0, x2)
    end

    local v220 = buffer.readf32(v23, 0)
    local y2 = translation.y

    if y2 ~= 0 and y2 > -1.1754943508222875E-38 and y2 < 1.1754943508222875E-38 then
        buffer.writeu32(v23, 0, to_bits(y2))
    else
        buffer.writef32(v23, 0, y2)
    end

    local v221 = buffer.readf32(v23, 0)
    local z2 = translation.z

    if z2 ~= 0 and z2 > -1.1754943508222875E-38 and z2 < 1.1754943508222875E-38 then
        buffer.writeu32(v23, 0, to_bits(z2))
    else
        buffer.writef32(v23, 0, z2)
    end

    local v222 = buffer.readf32(v23, 0)
    local v223 = v222 * v212 + (v221 * v206 + (v220 * v200 + v217))

    if v223 ~= 0 and v223 > -1.1754943508222875E-38 and v223 < 1.1754943508222875E-38 then
        buffer.writeu32(v23, 0, to_bits(v223))
    else
        buffer.writef32(v23, 0, v223)
    end

    local v224 = buffer.readf32(v23, 0)
    local v225 = v222 * v214 + (v221 * v208 + (v220 * v202 + v218))

    if v225 ~= 0 and v225 > -1.1754943508222875E-38 and v225 < 1.1754943508222875E-38 then
        buffer.writeu32(v23, 0, to_bits(v225))
    else
        buffer.writef32(v23, 0, v225)
    end

    local v226 = buffer.readf32(v23, 0)
    local v227 = v222 * v216 + (v221 * v210 + (v220 * v204 + v219))

    if v227 ~= 0 and v227 > -1.1754943508222875E-38 and v227 < 1.1754943508222875E-38 then
        buffer.writeu32(v23, 0, to_bits(v227))

        return v224, v226, (buffer.readf32(v23, 0))
    end

    buffer.writef32(v23, 0, v227)

    return v224, v226, (buffer.readf32(v23, 0))
end

function t1.BoardRuntime.hook_transform(p74) -- line: 634
    -- upvalues: t1 (copy)
    return t1.rates_transform(p74.hook.body.rates)
end

function t1.BoardRuntime.set_hook_transform(p75, p76) -- line: 640
    -- upvalues: set_part_transform (copy), t1 (copy)
    local t8 = {
        local_mass_frame = nil,
        inertia = nil,
        transform = t1.pose_words(t1.BoardRuntime.hook_transform(p75)),
        body = t1.body_pose_words(p75.hook.body.rates)
    }

    set_part_transform(t8, t1.pose_words(p76))
    t1.copy_pose(t8, p75.hook.body.rates)
end

t1.ZERO_INERTIA = {
    inverse_mass = 0,
    spherical = 0,
    maximum_linear_velocity = 0,
    maximum_angular_velocity = 0,
    linear_drag = 0,
    angular_drag = 0,
    inverse_tensor = rt.copy(Vector3.ZERO)
}

function t1.initialized_body(p77, p78, p79, p80) -- line: 663
    -- upvalues: rt (copy), Vector3 (copy), RetailAffineTransform (copy), RetailQuaternion (copy), world_inverse_inertia (copy), t1 (copy)
    local v228 = p80 == "Static"
    local v229 = if v228 then rt.copy(t1.ZERO_INERTIA) else rt.copy(p78)
    local t9 = {
        orientation = rt.copy(RetailQuaternion.IDENTITY),
        basis = rt.copy(RetailAffineTransform.IDENTITY.basis),
        world_inverse_inertia = {
            columns = rt.filled(3, table.create(3, 0))
        },
        position = rt.copy(Vector3.ZERO),
        linear_velocity = rt.copy(Vector3.ZERO),
        angular_velocity = rt.copy(Vector3.ZERO),
        force_acceleration = if v228 then rt.copy(Vector3.ZERO) else rt.copy(p79.gravity_acceleration),
        torque_acceleration = rt.copy(Vector3.ZERO),
        kinetic_energy = if v228 then 0 else rt.F32_MAX,
        cool_down = if p80 == "Active" then 0 else p79.cool_down
    }

    t1.copy_pose(p77, t9)
    t9.world_inverse_inertia = world_inverse_inertia(t9.basis, v229.inverse_tensor)

    return {
        state_flags = t1.BoardMotion.flags(p80),
        rates = t9,
        inertia = v229
    }
end

function t1.copy_pose(p81, p82) -- line: 689
    -- upvalues: v1 (copy), Vector3 (copy)
    local body = p81.body

    if body == nil then
        error("transient pose adapter has a body", 0)
    end

    local function f(p83) -- line: 694
        -- upvalues: body (copy), v1 (copy)
        buffer.writeu32(v1, 0, body[p83 + 1])

        return (buffer.readf32(v1, 0))
    end

    local t10 = {}

    buffer.writeu32(v1, 0, body[1])
    t10.x = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, body[2])
    t10.y = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, body[3])
    t10.z = buffer.readf32(v1, 0)
    buffer.writeu32(v1, 0, body[4])
    t10.w = buffer.readf32(v1, 0)
    p82.orientation = t10

    local new = Vector3.new

    buffer.writeu32(v1, 0, body[5])

    local v236 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, body[6])

    local v238 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, body[7])
    p82.position = new(v236, v238, (buffer.readf32(v1, 0)))

    local t11 = {}

    buffer.writeu32(v1, 0, body[17])

    local v241 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, body[18])

    local v243 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, body[19])

    local t12 = {
        v241,
        v243,
        (buffer.readf32(v1, 0))
    }

    buffer.writeu32(v1, 0, body[21])

    local v246 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, body[22])

    local v248 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, body[23])

    local t13 = {
        v246,
        v248,
        (buffer.readf32(v1, 0))
    }

    buffer.writeu32(v1, 0, body[25])

    local v251 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, body[26])

    local v253 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, body[27])
    t11.columns = {
        t12,
        t13,
        {
            v251,
            v253,
            (buffer.readf32(v1, 0))
        }
    }
    p82.basis = t11
end

function t1.rates_transform(p84) -- line: 714
    -- upvalues: rt (copy)
    return {
        basis = rt.copy(p84.basis),
        translation = rt.copy(p84.position)
    }
end

function t1.body_pose_words(p85) -- line: 722
    -- upvalues: v1 (copy)
    local v255 = table.create(44, 0)
    local orientation = p85.orientation
    local x = orientation.x
    local v256

    if x ~= 0 and x > -1.1754943508222875E-38 and x < 1.1754943508222875E-38 then
        local v257 = math.abs(x) * 7.1362384635298E+44
        local v258 = math.floor(v257)
        local v259 = v257 - v258

        v256 = if v259 > 0.5 or v259 == 0.5 and v258 % 2 == 1 then v258 + 1 else v258

        if x < 0 then
            v256 += 2147483648
        end
    else
        buffer.writef32(v1, 0, x)
        v256 = buffer.readu32(v1, 0)
    end

    v255[1] = v256

    local y = orientation.y
    local v260

    if y ~= 0 and y > -1.1754943508222875E-38 and y < 1.1754943508222875E-38 then
        local v261 = math.abs(y) * 7.1362384635298E+44
        local v262 = math.floor(v261)
        local v263 = v261 - v262

        v260 = if v263 > 0.5 or v263 == 0.5 and v262 % 2 == 1 then v262 + 1 else v262

        if y < 0 then
            v260 += 2147483648
        end
    else
        buffer.writef32(v1, 0, y)
        v260 = buffer.readu32(v1, 0)
    end

    v255[2] = v260

    local z = orientation.z
    local v264

    if z ~= 0 and z > -1.1754943508222875E-38 and z < 1.1754943508222875E-38 then
        local v265 = math.abs(z) * 7.1362384635298E+44
        local v266 = math.floor(v265)
        local v267 = v265 - v266

        v264 = if v267 > 0.5 or v267 == 0.5 and v266 % 2 == 1 then v266 + 1 else v266

        if z < 0 then
            v264 += 2147483648
        end
    else
        buffer.writef32(v1, 0, z)
        v264 = buffer.readu32(v1, 0)
    end

    v255[3] = v264

    local w = orientation.w
    local v268

    if w ~= 0 and w > -1.1754943508222875E-38 and w < 1.1754943508222875E-38 then
        local v269 = math.abs(w) * 7.1362384635298E+44
        local v270 = math.floor(v269)
        local v271 = v269 - v270

        v268 = if v271 > 0.5 or v271 == 0.5 and v270 % 2 == 1 then v270 + 1 else v270

        if w < 0 then
            v268 += 2147483648
        end
    else
        buffer.writef32(v1, 0, w)
        v268 = buffer.readu32(v1, 0)
    end

    v255[4] = v268

    local x2 = p85.position.x
    local v272

    if x2 ~= 0 and x2 > -1.1754943508222875E-38 and x2 < 1.1754943508222875E-38 then
        local v273 = math.abs(x2) * 7.1362384635298E+44
        local v274 = math.floor(v273)
        local v275 = v273 - v274

        v272 = if v275 > 0.5 or v275 == 0.5 and v274 % 2 == 1 then v274 + 1 else v274

        if x2 < 0 then
            v272 += 2147483648
        end
    else
        buffer.writef32(v1, 0, x2)
        v272 = buffer.readu32(v1, 0)
    end

    v255[5] = v272

    local y2 = p85.position.y
    local v276

    if y2 ~= 0 and y2 > -1.1754943508222875E-38 and y2 < 1.1754943508222875E-38 then
        local v277 = math.abs(y2) * 7.1362384635298E+44
        local v278 = math.floor(v277)
        local v279 = v277 - v278

        v276 = if v279 > 0.5 or v279 == 0.5 and v278 % 2 == 1 then v278 + 1 else v278

        if y2 < 0 then
            v276 += 2147483648
        end
    else
        buffer.writef32(v1, 0, y2)
        v276 = buffer.readu32(v1, 0)
    end

    v255[6] = v276

    local z2 = p85.position.z
    local v280

    if z2 ~= 0 and z2 > -1.1754943508222875E-38 and z2 < 1.1754943508222875E-38 then
        local v281 = math.abs(z2) * 7.1362384635298E+44
        local v282 = math.floor(v281)
        local v283 = v281 - v282

        v280 = if v283 > 0.5 or v283 == 0.5 and v282 % 2 == 1 then v282 + 1 else v282

        if z2 < 0 then
            v280 += 2147483648
        end
    else
        buffer.writef32(v1, 0, z2)
        v280 = buffer.readu32(v1, 0)
    end

    v255[7] = v280

    for i = 0, 2 do
        local v284 = p85.basis.columns[i + 1]
        local v285 = i * 4 + 16 + 0 + 1
        local v286 = v284[1]

        if v286 ~= 0 and v286 > -1.1754943508222875E-38 and v286 < 1.1754943508222875E-38 then
            local v287 = math.abs(v286) * 7.1362384635298E+44
            local v288 = math.floor(v287)
            local v289 = v287 - v288
            local v290 = if v289 > 0.5 or v289 == 0.5 and v288 % 2 == 1 then v288 + 1 else v288

            if v286 < 0 then
                v255[v285] = v290 + 2147483648
            else
                v255[v285] = v290
            end
        else
            buffer.writef32(v1, 0, v286)
            v255[v285] = buffer.readu32(v1, 0)
        end

        local v291 = i * 4 + 16 + 1 + 1
        local v292 = v284[2]

        if v292 ~= 0 and v292 > -1.1754943508222875E-38 and v292 < 1.1754943508222875E-38 then
            local v293 = math.abs(v292) * 7.1362384635298E+44
            local v294 = math.floor(v293)
            local v295 = v293 - v294
            local v296 = if v295 > 0.5 or v295 == 0.5 and v294 % 2 == 1 then v294 + 1 else v294

            if v292 < 0 then
                v255[v291] = v296 + 2147483648
            else
                v255[v291] = v296
            end
        else
            buffer.writef32(v1, 0, v292)
            v255[v291] = buffer.readu32(v1, 0)
        end

        local v297 = i * 4 + 16 + 2 + 1
        local v298 = v284[3]

        if v298 ~= 0 and v298 > -1.1754943508222875E-38 and v298 < 1.1754943508222875E-38 then
            local v299 = math.abs(v298) * 7.1362384635298E+44
            local v300 = math.floor(v299)
            local v301 = v299 - v300
            local v302 = if v301 > 0.5 or v301 == 0.5 and v300 % 2 == 1 then v300 + 1 else v300

            if v298 < 0 then
                v255[v297] = v302 + 2147483648
            else
                v255[v297] = v302
            end
        else
            buffer.writef32(v1, 0, v298)
            v255[v297] = buffer.readu32(v1, 0)
        end
    end

    return v255
end

function t1.inertia_words(p86) -- line: 742
    -- upvalues: v1 (copy)
    local x = p86.inverse_tensor.x
    local v303

    if x ~= 0 and x > -1.1754943508222875E-38 and x < 1.1754943508222875E-38 then
        local v304 = math.abs(x) * 7.1362384635298E+44
        local v305 = math.floor(v304)
        local v306 = v304 - v305

        v303 = if v306 > 0.5 or v306 == 0.5 and v305 % 2 == 1 then v305 + 1 else v305

        if x < 0 then
            v303 += 2147483648
        end
    else
        buffer.writef32(v1, 0, x)
        v303 = buffer.readu32(v1, 0)
    end

    local y = p86.inverse_tensor.y
    local v307

    if y ~= 0 and y > -1.1754943508222875E-38 and y < 1.1754943508222875E-38 then
        local v308 = math.abs(y) * 7.1362384635298E+44
        local v309 = math.floor(v308)
        local v310 = v308 - v309

        v307 = if v310 > 0.5 or v310 == 0.5 and v309 % 2 == 1 then v309 + 1 else v309

        if y < 0 then
            v307 += 2147483648
        end
    else
        buffer.writef32(v1, 0, y)
        v307 = buffer.readu32(v1, 0)
    end

    local z = p86.inverse_tensor.z
    local v311

    if z ~= 0 and z > -1.1754943508222875E-38 and z < 1.1754943508222875E-38 then
        local v312 = math.abs(z) * 7.1362384635298E+44
        local v313 = math.floor(v312)
        local v314 = v312 - v313

        v311 = if v314 > 0.5 or v314 == 0.5 and v313 % 2 == 1 then v313 + 1 else v313

        if z < 0 then
            v311 += 2147483648
        end
    else
        buffer.writef32(v1, 0, z)
        v311 = buffer.readu32(v1, 0)
    end

    buffer.writef32(v1, 0, 0)

    local v315 = buffer.readu32(v1, 0)
    local inverse_mass = p86.inverse_mass
    local v316

    if inverse_mass ~= 0 and inverse_mass > -1.1754943508222875E-38 and inverse_mass < 1.1754943508222875E-38 then
        local v317 = math.abs(inverse_mass) * 7.1362384635298E+44
        local v318 = math.floor(v317)
        local v319 = v317 - v318

        v316 = if v319 > 0.5 or v319 == 0.5 and v318 % 2 == 1 then v318 + 1 else v318

        if inverse_mass < 0 then
            v316 += 2147483648
        end
    else
        buffer.writef32(v1, 0, inverse_mass)
        v316 = buffer.readu32(v1, 0)
    end

    local spherical = p86.spherical
    local v320

    if spherical ~= 0 and spherical > -1.1754943508222875E-38 and spherical < 1.1754943508222875E-38 then
        local v321 = math.abs(spherical) * 7.1362384635298E+44
        local v322 = math.floor(v321)
        local v323 = v321 - v322

        v320 = if v323 > 0.5 or v323 == 0.5 and v322 % 2 == 1 then v322 + 1 else v322

        if spherical < 0 then
            v320 += 2147483648
        end
    else
        buffer.writef32(v1, 0, spherical)
        v320 = buffer.readu32(v1, 0)
    end

    local maximum_linear_velocity = p86.maximum_linear_velocity
    local v324

    if maximum_linear_velocity ~= 0 and maximum_linear_velocity > -1.1754943508222875E-38 and maximum_linear_velocity < 1.1754943508222875E-38 then
        local v325 = math.abs(maximum_linear_velocity) * 7.1362384635298E+44
        local v326 = math.floor(v325)
        local v327 = v325 - v326

        v324 = if v327 > 0.5 or v327 == 0.5 and v326 % 2 == 1 then v326 + 1 else v326

        if maximum_linear_velocity < 0 then
            v324 += 2147483648
        end
    else
        buffer.writef32(v1, 0, maximum_linear_velocity)
        v324 = buffer.readu32(v1, 0)
    end

    local maximum_angular_velocity = p86.maximum_angular_velocity
    local v328

    if maximum_angular_velocity ~= 0 and maximum_angular_velocity > -1.1754943508222875E-38 and maximum_angular_velocity < 1.1754943508222875E-38 then
        local v329 = math.abs(maximum_angular_velocity) * 7.1362384635298E+44
        local v330 = math.floor(v329)
        local v331 = v329 - v330

        v328 = if v331 > 0.5 or v331 == 0.5 and v330 % 2 == 1 then v330 + 1 else v330

        if maximum_angular_velocity < 0 then
            v328 += 2147483648
        end
    else
        buffer.writef32(v1, 0, maximum_angular_velocity)
        v328 = buffer.readu32(v1, 0)
    end

    local linear_drag = p86.linear_drag
    local v332

    if linear_drag ~= 0 and linear_drag > -1.1754943508222875E-38 and linear_drag < 1.1754943508222875E-38 then
        local v333 = math.abs(linear_drag) * 7.1362384635298E+44
        local v334 = math.floor(v333)
        local v335 = v333 - v334

        v332 = if v335 > 0.5 or v335 == 0.5 and v334 % 2 == 1 then v334 + 1 else v334

        if linear_drag < 0 then
            v332 += 2147483648
        end
    else
        buffer.writef32(v1, 0, linear_drag)
        v332 = buffer.readu32(v1, 0)
    end

    local angular_drag = p86.angular_drag
    local v336

    if angular_drag ~= 0 and angular_drag > -1.1754943508222875E-38 and angular_drag < 1.1754943508222875E-38 then
        local v337 = math.abs(angular_drag) * 7.1362384635298E+44
        local v338 = math.floor(v337)
        local v339 = v337 - v338

        v336 = if v339 > 0.5 or v339 == 0.5 and v338 % 2 == 1 then v338 + 1 else v338

        if angular_drag < 0 then
            v336 += 2147483648
        end
    else
        buffer.writef32(v1, 0, angular_drag)
        v336 = buffer.readu32(v1, 0)
    end

    return {
        v303,
        v307,
        v311,
        v315,
        v316,
        v320,
        v324,
        v328,
        v332,
        v336
    }
end

function t1.mass_frame_words(p87) -- line: 758
    -- upvalues: t1 (copy)
    return t1.pose_words({
        basis = p87.basis,
        translation = p87.translation
    })
end

function t1.pose_words(p88) -- line: 766
    -- upvalues: v1 (copy)
    local v340 = table.create(16, 0)

    for i = 0, 2 do
        local v341 = p88.basis.columns[i + 1]
        local v342 = i * 4 + 0 + 1
        local v343 = v341[1]

        if v343 ~= 0 and v343 > -1.1754943508222875E-38 and v343 < 1.1754943508222875E-38 then
            local v344 = math.abs(v343) * 7.1362384635298E+44
            local v345 = math.floor(v344)
            local v346 = v344 - v345
            local v347 = if v346 > 0.5 or v346 == 0.5 and v345 % 2 == 1 then v345 + 1 else v345

            if v343 < 0 then
                v340[v342] = v347 + 2147483648
            else
                v340[v342] = v347
            end
        else
            buffer.writef32(v1, 0, v343)
            v340[v342] = buffer.readu32(v1, 0)
        end

        local v348 = i * 4 + 1 + 1
        local v349 = v341[2]

        if v349 ~= 0 and v349 > -1.1754943508222875E-38 and v349 < 1.1754943508222875E-38 then
            local v350 = math.abs(v349) * 7.1362384635298E+44
            local v351 = math.floor(v350)
            local v352 = v350 - v351
            local v353 = if v352 > 0.5 or v352 == 0.5 and v351 % 2 == 1 then v351 + 1 else v351

            if v349 < 0 then
                v340[v348] = v353 + 2147483648
            else
                v340[v348] = v353
            end
        else
            buffer.writef32(v1, 0, v349)
            v340[v348] = buffer.readu32(v1, 0)
        end

        local v354 = i * 4 + 2 + 1
        local v355 = v341[3]

        if v355 ~= 0 and v355 > -1.1754943508222875E-38 and v355 < 1.1754943508222875E-38 then
            local v356 = math.abs(v355) * 7.1362384635298E+44
            local v357 = math.floor(v356)
            local v358 = v356 - v357
            local v359 = if v358 > 0.5 or v358 == 0.5 and v357 % 2 == 1 then v357 + 1 else v357

            if v355 < 0 then
                v340[v354] = v359 + 2147483648
            else
                v340[v354] = v359
            end
        else
            buffer.writef32(v1, 0, v355)
            v340[v354] = buffer.readu32(v1, 0)
        end
    end

    local translation = p88.translation
    local x = translation.x
    local v360

    if x ~= 0 and x > -1.1754943508222875E-38 and x < 1.1754943508222875E-38 then
        local v361 = math.abs(x) * 7.1362384635298E+44
        local v362 = math.floor(v361)
        local v363 = v361 - v362

        v360 = if v363 > 0.5 or v363 == 0.5 and v362 % 2 == 1 then v362 + 1 else v362

        if x < 0 then
            v360 += 2147483648
        end
    else
        buffer.writef32(v1, 0, x)
        v360 = buffer.readu32(v1, 0)
    end

    v340[13] = v360

    local y = translation.y
    local v364

    if y ~= 0 and y > -1.1754943508222875E-38 and y < 1.1754943508222875E-38 then
        local v365 = math.abs(y) * 7.1362384635298E+44
        local v366 = math.floor(v365)
        local v367 = v365 - v366

        v364 = if v367 > 0.5 or v367 == 0.5 and v366 % 2 == 1 then v366 + 1 else v366

        if y < 0 then
            v364 += 2147483648
        end
    else
        buffer.writef32(v1, 0, y)
        v364 = buffer.readu32(v1, 0)
    end

    v340[14] = v364

    local z = translation.z
    local v368

    if z ~= 0 and z > -1.1754943508222875E-38 and z < 1.1754943508222875E-38 then
        local v369 = math.abs(z) * 7.1362384635298E+44
        local v370 = math.floor(v369)
        local v371 = v369 - v370

        v368 = if v371 > 0.5 or v371 == 0.5 and v370 % 2 == 1 then v370 + 1 else v370

        if z < 0 then
            v368 += 2147483648
        end
    else
        buffer.writef32(v1, 0, z)
        v368 = buffer.readu32(v1, 0)
    end

    v340[15] = v368

    return v340
end

function t1.transform_from_words(p89) -- line: 782
    -- upvalues: v1 (copy), Vector3 (copy)
    local function f(p90) -- line: 783
        -- upvalues: p89 (copy), v1 (copy)
        buffer.writeu32(v1, 0, p89[p90 + 1])

        return (buffer.readf32(v1, 0))
    end

    local t15 = {}
    local t16 = {}

    buffer.writeu32(v1, 0, p89[1])

    local v374 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p89[2])

    local v376 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p89[3])

    local t17 = {
        v374,
        v376,
        (buffer.readf32(v1, 0))
    }

    buffer.writeu32(v1, 0, p89[5])

    local v379 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p89[6])

    local v381 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p89[7])

    local t18 = {
        v379,
        v381,
        (buffer.readf32(v1, 0))
    }

    buffer.writeu32(v1, 0, p89[9])

    local v384 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p89[10])

    local v386 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p89[11])
    t16.columns = {
        t17,
        t18,
        {
            v384,
            v386,
            (buffer.readf32(v1, 0))
        }
    }
    t15.basis = t16

    local new = Vector3.new

    buffer.writeu32(v1, 0, p89[13])

    local v389 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p89[14])

    local v391 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p89[15])
    t15.translation = new(v389, v391, (buffer.readf32(v1, 0)))

    return t15
end

return t1
