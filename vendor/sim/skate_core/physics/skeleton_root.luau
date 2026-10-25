-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/board_ground")
local v2 = import("skate_core/physics/board_motion_output")
local v3 = import("skate_core/physics/native_arithmetic")
local v4 = import("skate_core/physics/skeleton_animation_record")
local v5 = import("skate_core/math")
local v6 = import("skate_core/trigonometry")
local angle_between = v1.angle_between
local inverse_length_squared = v2.inverse_length_squared
local dot3 = v3.dot3
local IDENTITY, compose_affine = v4.IDENTITY, v4.compose_affine
local Vector3 = v5.Vector3
local t1 = {}
local compose_affine_into, compose_affine_reference = v4.compose_affine_into, v4.compose_affine_reference

local function copy_row(p1) -- line: 31
    -- upvalues: rt (copy)
    if type(p1) ~= "table" or #p1 ~= 4 then
        return rt.copy(p1)
    end

    return {
        p1[1],
        p1[2],
        p1[3],
        p1[4]
    }
end

local function copy_matrix(p2) -- line: 40
    -- upvalues: rt (copy)
    if type(p2) ~= "table" or p2[5] ~= nil then
        return rt.copy(p2)
    end

    local v7 = p2[1]
    local v8 = p2[2]
    local v9 = p2[3]
    local v10 = p2[4]

    if type(v7) == "table" and type(v8) == "table" and type(v9) == "table" and type(v10) == "table" and #v7 == 4 and #v8 == 4 and #v9 == 4 and #v10 == 4 then
        return {
            {
                v7[1],
                v7[2],
                v7[3],
                v7[4]
            },
            {
                v8[1],
                v8[2],
                v8[3],
                v8[4]
            },
            {
                v9[1],
                v9[2],
                v9[3],
                v9[4]
            },
            {
                v10[1],
                v10[2],
                v10[3],
                v10[4]
            }
        }
    end

    return rt.copy(p2)
end

t1.copy_row = copy_row
t1.copy_matrix = copy_matrix

local function scratch_identity() -- line: 68
    return {
        { 1, 0, 0, 0 },
        { 0, 1, 0, 0 },
        { 0, 0, 1, 0 },
        { 0, 0, 0, 0 }
    }
end

local v11 = scratch_identity()
local v12 = scratch_identity()
local v13 = scratch_identity()
local v14 = scratch_identity()

t1.SkeletonRootFrames = {}

function t1.SkeletonRootFrames.default() -- line: 88
    -- upvalues: rt (copy), IDENTITY (copy)
    return {
        supplied_prediction = nil,
        initialize_heading = true,
        board = rt.copy(IDENTITY),
        inverse_board = rt.copy(IDENTITY),
        previous_board_position = { 0, 0, 0, 0 },
        predicted_board_position = { 0, 0, 0, 0 },
        animation_to_board = rt.copy(IDENTITY),
        animation_to_world = rt.copy(IDENTITY),
        world_to_animation = rt.copy(IDENTITY),
        heading_alignment = rt.copy(IDENTITY)
    }
end

function t1.SkeletonRootFrames.update_teleport(p3, p4, p5, p6) -- line: 106
    -- upvalues: rt (copy), t1 (copy)
    p3.initialize_heading = true
    p3.supplied_prediction = rt.copy(p4[4])
    t1.SkeletonRootFrames.update(p3, rt.copy(p4), { 0, 0, 0, 0 }, 0, p5, p6)
    p3.previous_board_position = rt.copy(p4[4])
end

function t1.SkeletonRootFrames.reset_initial_alignment(p7, p8) -- line: 116
    -- upvalues: rt (copy), t1 (copy)
    p7.animation_to_world = rt.copy(p8)
    p7.world_to_animation = t1.inverse_rigid(p8)
end

function t1.SkeletonRootFrames.update(p9, p10, p11, p12, p13, p14) -- line: 139
    -- upvalues: v6 (copy), angle_between (copy), inverse_length_squared (copy), dot3 (copy), compose_affine (copy), Vector3 (copy), t1 (copy), compose_affine_into (copy), copy_row (copy), copy_matrix (copy), v11 (copy), v12 (copy), v13 (copy), v14 (copy)
    p9.previous_board_position = copy_row(p9.board[4])
    p9.board = copy_matrix(p10)
    p9.inverse_board = t1.inverse_rigid(p10)

    local supplied_prediction = p9.supplied_prediction

    p9.supplied_prediction = nil

    if supplied_prediction ~= nil then
        p9.predicted_board_position = supplied_prediction
    else
        local v15 = p10[4]

        p9.predicted_board_position = {
            p11[1] * p12 + v15[1],
            p11[2] * p12 + v15[2],
            p11[3] * p12 + v15[3],
            p11[4] * p12 + v15[4]
        }
    end

    if p9.initialize_heading then
        local v16 = Vector3.new(p13[3][1], 0, p13[3][3])
        local v18 = angle_between(v16, (Vector3.new(0, 0, 1)))
        local t2 = {
            v16.x,
            v16.y,
            v16.z,
            0
        }
        local v19 = dot3(t2, t2)

        if v19 > 9.999999747378752E-05 then
            local v20 = inverse_length_squared(v19, 1)

            if -(v16.x * v20) < 0 then
                v18 = 6.2831854820251465 - v18
            end
        end

        local v21, v22 = v6.sin_cos(v18)

        p9.heading_alignment = {
            { v22, 0, -v21, 0 },
            { 0, 1, 0, 0 },
            { v21, 0, v22, 0 },
            { 0, 0, 0, 0 }
        }
        p9.initialize_heading = false
    end

    local v23 = p13[4]
    local v24 = v11[4]
    local v25 = -v23[1]
    local v26 = -v23[2]
    local v27 = -v23[3]
    local v28 = -v23[4]

    v24[1] = v25
    v24[2] = v26
    v24[3] = v27
    v24[4] = v28
    compose_affine_into(v13, p9.heading_alignment, v11)
    p9.animation_to_board = compose_affine(p14, v13)

    local predicted_board_position = p9.predicted_board_position
    local v29 = v12[4]
    local v30 = predicted_board_position[1]
    local v31 = predicted_board_position[2]
    local v32 = predicted_board_position[3]
    local v33 = predicted_board_position[4]

    v29[1] = v30
    v29[2] = v31
    v29[3] = v32
    v29[4] = v33
    compose_affine_into(v14, v12, p9.animation_to_board)
    p9.animation_to_world = t1.orthonormalize(v14)
    p9.world_to_animation = t1.inverse_rigid(p9.animation_to_world)
end

function t1.SkeletonRootFrames.update_reference(p15, p16, p17, p18, p19, p20) -- line: 201
    -- upvalues: rt (copy), v6 (copy), angle_between (copy), inverse_length_squared (copy), dot3 (copy), IDENTITY (copy), Vector3 (copy), t1 (copy), compose_affine_reference (copy)
    p15.previous_board_position = rt.copy(p15.board[4])
    p15.board = rt.copy(p16)
    p15.inverse_board = t1.inverse_rigid_reference(p16)

    local supplied_prediction = p15.supplied_prediction

    p15.supplied_prediction = nil

    if supplied_prediction ~= nil then
        p15.predicted_board_position = supplied_prediction
    else
        p15.predicted_board_position = {
            p17[1] * p18 + p16[4][1],
            p17[2] * p18 + p16[4][2],
            p17[3] * p18 + p16[4][3],
            p17[4] * p18 + p16[4][4]
        }
    end

    if p15.initialize_heading then
        local v34 = Vector3.new(p19[3][1], 0, p19[3][3])
        local v36 = angle_between(v34, (Vector3.new(0, 0, 1)))
        local t3 = {
            v34.x,
            v34.y,
            v34.z,
            0
        }
        local v37 = dot3(t3, t3)

        if v37 > 9.999999747378752E-05 then
            local v38 = inverse_length_squared(v37, 1)

            if -(v34.x * v38) < 0 then
                v36 = 6.2831854820251465 - v36
            end
        end

        local v39, v40 = v6.sin_cos(v36)

        p15.heading_alignment = {
            { v40, 0, -v39, 0 },
            { 0, 1, 0, 0 },
            { v39, 0, v40, 0 },
            { 0, 0, 0, 0 }
        }
        p15.initialize_heading = false
    end

    local v41 = rt.copy(IDENTITY)

    v41[4] = {
        -p19[4][1],
        -p19[4][2],
        -p19[4][3],
        -p19[4][4]
    }
    p15.animation_to_board = compose_affine_reference(p20, (compose_affine_reference(p15.heading_alignment, v41)))

    local v43 = rt.copy(IDENTITY)

    v43[4] = rt.copy(p15.predicted_board_position)
    p15.animation_to_world = t1.orthonormalize_reference(compose_affine_reference(v43, p15.animation_to_board))
    p15.world_to_animation = t1.inverse_rigid_reference(p15.animation_to_world)
end

function t1.orthonormalize(p21) -- line: 280
    -- upvalues: inverse_length_squared (copy), IDENTITY (copy), t1 (copy), copy_row (copy)
    local v44 = p21[1]
    local v45 = p21[2]
    local v46 = p21[3]
    local v47 = p21[4]

    if p21[5] ~= nil
        or type(v44) ~= "table"
        or type(v45) ~= "table"
        or type(v46) ~= "table"
        or #v44 ~= 4
        or #v45 ~= 4
        or #v46 ~= 4 then
        return t1.orthonormalize_reference(p21)
    end

    local v48 = v46[1]
    local v49 = v46[2]
    local v50 = v46[3]
    local v51 = v46[4]
    local v52 = v48 * v48 + v49 * v49 + v50 * v50
    local v53, v54, v55, v56

    if v52 <= 9.999999974752427E-07 then
        local v57 = IDENTITY[3]

        v53 = v57[1]
        v54 = v57[2]
        v55 = v57[3]
        v56 = v57[4]
    else
        local v58 = inverse_length_squared(v52, 2)

        v53 = v48 * v58
        v54 = v49 * v58
        v55 = v50 * v58
        v56 = v51 * v58
    end

    local v59 = v45[1]
    local v60 = v45[2]
    local v61 = v45[3]
    local v62 = v45[4]
    local v63 = v53 * v59 + v54 * v60 + v55 * v61
    local v64 = v59 - v53 * v63
    local v65 = v60 - v54 * v63
    local v66 = v61 - v55 * v63
    local v67 = v62 - v56 * v63
    local v68 = v64 * v64 + v65 * v65 + v66 * v66
    local v69, v70, v71, v72

    if v68 <= 9.999999974752427E-07 then
        local v73 = IDENTITY[2]

        v69 = v73[1]
        v70 = v73[2]
        v71 = v73[3]
        v72 = v73[4]
    else
        local v74 = inverse_length_squared(v68, 2)

        v69 = v64 * v74
        v70 = v65 * v74
        v71 = v66 * v74
        v72 = v67 * v74
    end

    local v75 = v44[1]
    local v76 = v44[2]
    local v77 = v44[3]
    local v78 = v44[4]
    local v79 = v53 * v75 + v54 * v76 + v55 * v77
    local v80 = v75 - v53 * v79
    local v81 = v76 - v54 * v79
    local v82 = v77 - v55 * v79
    local v83 = v78 - v56 * v79
    local v84 = v69 * v75 + v70 * v76 + v71 * v77
    local v85 = v80 - v69 * v84
    local v86 = v81 - v70 * v84
    local v87 = v82 - v71 * v84
    local v88 = v83 - v72 * v84
    local v89 = v85 * v85 + v86 * v86 + v87 * v87
    local v90, v91, v92, v93

    if v89 <= 9.999999974752427E-07 then
        local v94 = IDENTITY[1]

        v90 = v94[1]
        v91 = v94[2]
        v92 = v94[3]
        v93 = v94[4]
    else
        local v95 = inverse_length_squared(v89, 2)

        v90 = v85 * v95
        v91 = v86 * v95
        v92 = v87 * v95
        v93 = v88 * v95
    end

    return {
        { v90, v91, v92, v93 },
        { v69, v70, v71, v72 },
        { v53, v54, v55, v56 },
        copy_row(v47)
    }
end

function t1.orthonormalize_reference(p22) -- line: 351
    -- upvalues: rt (copy), inverse_length_squared (copy), dot3 (copy), IDENTITY (copy)
    local v96 = rt.copy(p22)

    for i = 2, 0, -1 do
        local v97 = rt.copy(p22[i + 1])

        for j = 2, i + 1, -1 do
            local v98 = dot3(v96[j + 1], p22[i + 1])

            v97[1] -= v96[j + 1][1] * v98
            v97[2] -= v96[j + 1][2] * v98
            v97[3] -= v96[j + 1][3] * v98
            v97[4] -= v96[j + 1][4] * v98
        end

        local v99 = dot3(v97, v97)

        if v99 <= 9.999999974752427E-07 then
            v96[i + 1] = rt.copy(IDENTITY[i + 1])
        else
            local v100 = inverse_length_squared(v99, 2)

            v96[i + 1] = {
                v97[1] * v100,
                v97[2] * v100,
                v97[3] * v100,
                v97[4] * v100
            }
        end
    end

    return v96
end

function t1.inverse_rigid(p23) -- line: 388
    local v101 = p23[1]
    local v102 = p23[2]
    local v103 = p23[3]
    local v104 = p23[4]
    local v105 = v101[1]
    local v106 = v101[2]
    local v107 = v101[3]
    local v108 = v102[1]
    local v109 = v102[2]
    local v110 = v102[3]
    local v111 = v103[1]
    local v112 = v103[2]
    local v113 = v103[3]
    local v114 = 0 - v104[1]
    local v115 = 0 - v104[2]
    local v116 = 0 - v104[3]

    return {
        { v105, v108, v111, 0 },
        { v106, v109, v112, 0 },
        { v107, v110, v113, 0 },
        {
            v114 * v105 + (v115 * v106 + v116 * v107),
            v114 * v108 + (v115 * v109 + v116 * v110),
            v114 * v111 + (v115 * v112 + v116 * v113),
            v114 * 0 + (v115 * 0 + v116 * 0)
        }
    }
end

function t1.inverse_rigid_reference(p24) -- line: 410
    -- upvalues: rt (copy), IDENTITY (copy)
    local v117 = rt.copy(IDENTITY)

    for i = 0, 2 do
        v117[i + 1] = {
            p24[1][i + 1],
            p24[2][i + 1],
            p24[3][i + 1],
            0
        }
    end

    local t4 = {
        0 - p24[4][1],
        0 - p24[4][2],
        0 - p24[4][3],
        0 - p24[4][4]
    }
    local v118 = table.create(4)

    for i = 0, 3 do
        local v119 = t4[3] * v117[3][i + 1]
        local v120 = t4[2] * v117[2][i + 1] + v119

        v118[i + 1] = t4[1] * v117[1][i + 1] + v120
    end

    v117[4] = v118

    return v117
end

return t1
