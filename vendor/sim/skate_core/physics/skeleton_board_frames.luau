-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/native_arithmetic")
local v2 = import("skate_core/physics/skeleton_animation_record")
local v3 = import("skate_core/physics/skeleton_root")
local reciprocal_estimate = v1.reciprocal_estimate
local IDENTITY, compose_affine, transform_point = v2.IDENTITY, v2.compose_affine, v2.transform_point
local orthonormalize, orthonormalize_reference = v3.orthonormalize, v3.orthonormalize_reference
local compose_affine_into, compose_affine_reference = v2.compose_affine_into, v2.compose_affine_reference
local copy_row, copy_matrix = v3.copy_row, v3.copy_matrix
local t2 = {
    { 0, 0, 0, 0 },
    { 0, 0, 0, 0 },
    { 0, 0, 0, 0 },
    { 0, 0, 0, 0 }
}
local t3 = {
    { 1, 0, 0, 0 },
    { 0, 1, 0, 0 },
    { 0, 0, 1, 0 },
    { 0, 0, 0, 0 }
}
local v4 = table.create(4)
local t1 = {
    SkeletonBoardFrames = {}
}

function t1.SkeletonBoardFrames.default() -- line: 51
    -- upvalues: rt (copy), IDENTITY (copy)
    return {
        lift_height = 0,
        physical_board = rt.copy(IDENTITY),
        skate_root = rt.copy(IDENTITY),
        animation_target = rt.copy(IDENTITY),
        com_frame = rt.copy(IDENTITY),
        lifted_com_frame = rt.copy(IDENTITY),
        centre_of_mass = { 0, 0, 0, 0 },
        previous_centre_of_mass = { 0, 0, 0, 0 },
        com_velocity = { 0, 0, 0, 0 },
        local_centre_of_mass = { 0, 0, 0, 0 },
        local_board_position = { 0, 0, 0, 0 }
    }
end

function t1.SkeletonBoardFrames.reset(p1, p2) -- line: 70
    -- upvalues: rt (copy)
    p1.com_frame = rt.copy(p2)
    p1.com_frame[4][2] += 1
    p1.lifted_com_frame = rt.copy(p1.com_frame)
    p1.centre_of_mass = rt.copy(p2[4])
    p1.local_centre_of_mass = { 0, 0, 0, 0 }
end

function t1.SkeletonBoardFrames.publish_local_observations(p3, p4, p5) -- line: 80
    -- upvalues: transform_point (copy)
    p3.local_centre_of_mass = transform_point(p4.world_to_animation, p3.centre_of_mass)
    p3.local_board_position = transform_point(p4.world_to_animation, p5[4])
end

function t1.SkeletonBoardFrames.publish_centre_of_mass(p6, p7, p8, p9) -- line: 87
    -- upvalues: rt (copy), reciprocal_estimate (copy)
    p6.previous_centre_of_mass = rt.copy(p6.centre_of_mass)
    p6.centre_of_mass = rt.copy(p7)

    local v5 = reciprocal_estimate(p8)
    local v6 = v5 * (-v5 * p8 + 1) + v5
    local v7 = v6 * (-v6 * p8 + 1) + v6

    p6.com_velocity = {
        (p7[1] - p6.previous_centre_of_mass[1]) * v7,
        (p7[2] - p6.previous_centre_of_mass[2]) * v7,
        (p7[3] - p6.previous_centre_of_mass[3]) * v7,
        (p7[4] - p6.previous_centre_of_mass[4]) * v7
    }

    if bit32.band(p9, 1024) ~= 0 then
        p6.previous_centre_of_mass = rt.copy(p7)
    end
end

function t1.SkeletonBoardFrames.prepare_ground(p10, p11, p12, p13, p14) -- line: 118
    -- upvalues: compose_affine (copy), compose_affine_into (copy), copy_matrix (copy), t1 (copy), t2 (copy), t3 (copy)
    compose_affine_into(t2, p11.animation_to_board, p12)

    local predicted_board_position = p11.predicted_board_position
    local v8 = t3[4]
    local v9 = predicted_board_position[1]
    local v10 = predicted_board_position[2]
    local v11 = predicted_board_position[3]
    local v12 = predicted_board_position[4]

    v8[1] = v9
    v8[2] = v10
    v8[3] = v11
    v8[4] = v12
    p10.animation_target = compose_affine(t3, t2)

    local v13 = bit32.band(p14, 4294443007)

    p10.physical_board = copy_matrix(p13)
    p10.skate_root = copy_matrix(p13)
    t1.SkeletonBoardFrames.update_com_lift(p10, p11.animation_to_world, p10.centre_of_mass, 0)

    return copy_matrix(p10.animation_target), v13
end

function t1.SkeletonBoardFrames.prepare_teleport(p15, p16, p17, p18, p19) -- line: 139
    -- upvalues: rt (copy), compose_affine (copy), compose_affine_into (copy), copy_matrix (copy), t1 (copy), t2 (copy), t3 (copy)
    compose_affine_into(t2, p16.animation_to_board, p17)

    local predicted_board_position = p16.predicted_board_position
    local v14 = t3[4]
    local v15 = predicted_board_position[1]
    local v16 = predicted_board_position[2]
    local v17 = predicted_board_position[3]
    local v18 = predicted_board_position[4]

    v14[1] = v15
    v14[2] = v16
    v14[3] = v17
    v14[4] = v18
    p15.animation_target = compose_affine(t3, t2)

    local v19 = bit32.band(p19, 4294443007)

    p15.physical_board = copy_matrix(p18)
    p15.skate_root = copy_matrix(p18)

    local v20 = rt.copy(p18[4])

    v20[2] += 1
    t1.SkeletonBoardFrames.update_com_lift(p15, p16.animation_to_world, v20, 0)

    return copy_matrix(p15.animation_target), v19
end

function t1.SkeletonBoardFrames.prepare_ground_reference(p20, p21, p22, p23, p24) -- line: 158
    -- upvalues: rt (copy), IDENTITY (copy), compose_affine_reference (copy), t1 (copy)
    local v21 = compose_affine_reference(p21.animation_to_board, p22)
    local v22 = rt.copy(IDENTITY)

    v22[4] = rt.copy(p21.predicted_board_position)
    p20.animation_target = compose_affine_reference(v22, v21)

    local v23 = bit32.band(p24, 4294443007)

    p20.physical_board = rt.copy(p23)
    p20.skate_root = rt.copy(p23)
    t1.SkeletonBoardFrames.update_com_lift_reference(p20, p21.animation_to_world, rt.copy(p20.centre_of_mass), 0)

    return rt.copy(p20.animation_target), v23
end

function t1.SkeletonBoardFrames.prepare_teleport_reference(p25, p26, p27, p28, p29) -- line: 173
    -- upvalues: rt (copy), IDENTITY (copy), compose_affine_reference (copy), t1 (copy)
    local v24 = compose_affine_reference(p26.animation_to_board, p27)
    local v25 = rt.copy(IDENTITY)

    v25[4] = rt.copy(p26.predicted_board_position)
    p25.animation_target = compose_affine_reference(v25, v24)

    local v26 = bit32.band(p29, 4294443007)

    p25.physical_board = rt.copy(p28)
    p25.skate_root = rt.copy(p28)

    local v27 = rt.copy(p28[4])

    v27[2] += 1
    t1.SkeletonBoardFrames.update_com_lift_reference(p25, p26.animation_to_world, v27, 0)

    return rt.copy(p25.animation_target), v26
end

function t1.SkeletonBoardFrames.update_com_lift(p30, p31, p32, p33) -- line: 196
    -- upvalues: orthonormalize (copy), copy_row (copy), t1 (copy), v4 (copy)
    if p31[5] ~= nil then
        return t1.SkeletonBoardFrames.update_com_lift_reference(p30, p31, p32, p33)
    end

    local v28 = p30.lift_height - 0.03999999910593033
    local v29 = p30.lift_height + 0.03999999910593033

    if not (v28 - p33 >= 0) then
        v28 = p33
    end

    if v29 - v28 >= 0 then
        p30.lift_height = v28
    else
        p30.lift_height = v29
    end

    local v30 = p31[1]
    local v31 = p31[2]
    local v32 = p31[3]

    v4[1] = v30
    v4[2] = v31
    v4[3] = v32
    v4[4] = p32

    local v33 = orthonormalize(v4)

    v4[1] = nil
    v4[2] = nil
    v4[3] = nil
    v4[4] = nil
    p30.com_frame = v33

    local v34 = p30.lift_height + 0.30000001192092896
    local v35 = v33[2]
    local v36 = v33[4]

    p30.lifted_com_frame = {
        copy_row(v33[1]),
        copy_row(v35),
        copy_row(v33[3]),
        {
            v35[1] * v34 + v36[1],
            v35[2] * v34 + v36[2],
            v35[3] * v34 + v36[3],
            v35[4] * v34 + v36[4]
        }
    }
end

function t1.SkeletonBoardFrames.update_com_lift_reference(p34, p35, p36, p37) -- line: 236
    -- upvalues: rt (copy), orthonormalize_reference (copy)
    local v37 = p34.lift_height - 0.03999999910593033
    local v38 = p34.lift_height + 0.03999999910593033

    if not (v37 - p37 >= 0) then
        v37 = p37
    end

    if v38 - v37 >= 0 then
        p34.lift_height = v37
    else
        p34.lift_height = v38
    end

    local v39 = rt.copy(p35)

    v39[4] = rt.copy(p36)
    p34.com_frame = orthonormalize_reference(v39)
    p34.lifted_com_frame = rt.copy(p34.com_frame)

    local v40 = p34.lift_height + 0.30000001192092896

    p34.lifted_com_frame[4] = {
        p34.com_frame[2][1] * v40 + p34.com_frame[4][1],
        p34.com_frame[2][2] * v40 + p34.com_frame[4][2],
        p34.com_frame[2][3] * v40 + p34.com_frame[4][3],
        p34.com_frame[2][4] * v40 + p34.com_frame[4][4]
    }
end

return t1
