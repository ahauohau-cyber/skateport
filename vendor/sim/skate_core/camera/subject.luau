-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

require(sim.import)

local t1 = {
    Subject = {},
    ReferencePointInputs = {}
}

function t1.ReferencePointInputs.positions(p1) -- line: 45
    -- upvalues: rt (copy)
    local t2 = {}

    t2[1] = (p1.left_foot[1] + p1.right_foot[1]) * 0.5
    t2[2] = (p1.left_foot[2] + p1.right_foot[2]) * 0.5
    t2[3] = (p1.left_foot[3] + p1.right_foot[3]) * 0.5
    t2[4] = (p1.left_foot[4] + p1.right_foot[4]) * 0.5

    return {
        rt.copy(p1.head),
        rt.copy(p1.hips),
        if p1.grinding == 0 then rt.copy(p1.board) else rt.copy(p1.grind_position),
        rt.copy(p1.centre_of_mass),
        rt.copy(p1.board),
        rt.copy(p1.centre_of_mass),
        rt.copy(p1.tracked_anchor),
        t2,
        rt.copy(p1.damped_centre_of_mass),
        rt.copy(p1.incline_normal)
    }
end

function t1.ReferencePointInputs.positions_into(p2, p3, p4, p5, p6, p7, p8, p9) -- line: 67
    local head, hips, board, centre_of_mass = p3.head, p3.hips, p3.board, p3.centre_of_mass
    local left_foot, right_foot = p3.left_foot, p3.right_foot
    local v1 = if p3.grinding == 0 then board else p3.grind_position
    local v2 = p2[1]
    local v3 = head[1]
    local v4 = head[2]
    local v5 = head[3]
    local v6 = head[4]

    v2[1] = v3
    v2[2] = v4
    v2[3] = v5
    v2[4] = v6

    local v7 = p2[2]
    local v8 = hips[1]
    local v9 = hips[2]
    local v10 = hips[3]
    local v11 = hips[4]

    v7[1] = v8
    v7[2] = v9
    v7[3] = v10
    v7[4] = v11

    local v12 = p2[3]
    local v13 = v1[1]
    local v14 = v1[2]
    local v15 = v1[3]
    local v16 = v1[4]

    v12[1] = v13
    v12[2] = v14
    v12[3] = v15
    v12[4] = v16

    local v17 = p2[4]
    local v18 = centre_of_mass[1]
    local v19 = centre_of_mass[2]
    local v20 = centre_of_mass[3]
    local v21 = centre_of_mass[4]

    v17[1] = v18
    v17[2] = v19
    v17[3] = v20
    v17[4] = v21

    local v22 = p2[5]
    local v23 = board[1]
    local v24 = board[2]
    local v25 = board[3]
    local v26 = board[4]

    v22[1] = v23
    v22[2] = v24
    v22[3] = v25
    v22[4] = v26

    local v27 = p2[6]
    local v28 = centre_of_mass[1]
    local v29 = centre_of_mass[2]
    local v30 = centre_of_mass[3]
    local v31 = centre_of_mass[4]

    v27[1] = v28
    v27[2] = v29
    v27[3] = v30
    v27[4] = v31

    local v32 = p2[7]
    local v33 = p8[1]
    local v34 = p8[2]
    local v35 = p8[3]
    local v36 = p8[4]

    v32[1] = v33
    v32[2] = v34
    v32[3] = v35
    v32[4] = v36

    local v37 = p2[8]

    v37[1] = (left_foot[1] + right_foot[1]) * 0.5
    v37[2] = (left_foot[2] + right_foot[2]) * 0.5
    v37[3] = (left_foot[3] + right_foot[3]) * 0.5
    v37[4] = (left_foot[4] + right_foot[4]) * 0.5

    local v38 = p2[9]

    v38[1] = p4
    v38[2] = p5
    v38[3] = p6
    v38[4] = p7

    local v39 = p2[10]
    local v40 = p9[1]
    local v41 = p9[2]
    local v42 = p9[3]
    local v43 = p9[4]

    v39[1] = v40
    v39[2] = v41
    v39[3] = v42
    v39[4] = v43
end

function t1.Subject.flag_568(p10) -- line: 106
    return p10.in_ground_physics
end

function t1.Subject.flag_596(p11) -- line: 109
    return p11.grinding
end

function t1.Subject.flag_680(p12) -- line: 112
    return p12.subject_flag_328
end

function t1.Subject.flag_540(p13) -- line: 115
    return p13.trajectory_valid
end

function t1.Subject.transform_376(p14) -- line: 120
    -- upvalues: rt (copy)
    return rt.copy(p14.transform)
end

function t1.Subject.vector_452(p15) -- line: 123
    -- upvalues: rt (copy)
    return rt.copy(p15.last_valid_ground_up)
end

function t1.Subject.vector_444(p16) -- line: 126
    -- upvalues: rt (copy)
    return rt.copy(p16.hips_position)
end

function t1.Subject.context_532(p17) -- line: 129
    return p17.context
end

function t1.Subject.flag_608(p18) -- line: 132
    return p18.off_board
end

function t1.Subject.flag_548(p19) -- line: 135
    return p19.wiping_out
end

function t1.Subject.flag_584(p20) -- line: 140
    return p20.physically_pushing
end

function t1.Subject.flag_588(p21) -- line: 143
    return p21.at_pushable_speed
end

function t1.Subject.value_476(p22) -- line: 146
    return p22.pumping_acceleration
end

function t1.Subject.flag_656(p23) -- line: 152
    return p23.air_flag_452
end

function t1.Subject.flag_668(p24) -- line: 158
    return p24.broken_bone_slowmo
end

function t1.Subject.flag_660(p25) -- line: 162
    return p25.state_flag_81
end

function t1.Subject.value_524(p26) -- line: 165
    return p26.state_height_32
end

function t1.Subject.transform_384(p27) -- line: 168
    -- upvalues: rt (copy)
    return rt.copy(p27.skeleton_root)
end

function t1.Subject.position_360(p28, p29) -- line: 171
    -- upvalues: rt (copy)
    return rt.copy(p28.reference_positions[p29 + 1])
end

return t1
