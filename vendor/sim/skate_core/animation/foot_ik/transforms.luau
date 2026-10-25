-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = require(sim.import)("skate_core/physics/skeleton_animation_record")
local IDENTITY, compose_affine = v1.IDENTITY, v1.compose_affine
local t1 = {
    LimbBinding = {},
    LimbFrames = {}
}

function t1.LimbFrames.default() -- line: 33
    -- upvalues: rt (copy), IDENTITY (copy)
    return {
        within_contact_bounds = false,
        target = rt.copy(IDENTITY),
        world = rt.copy(IDENTITY),
        external_world = rt.copy(IDENTITY),
        board = rt.copy(IDENTITY),
        parent_world = rt.copy(IDENTITY),
        external_parent_world = rt.copy(IDENTITY),
        parent_board = rt.copy(IDENTITY)
    }
end

function t1.inverse_rigid(p1) -- line: 55
    local v2 = p1[1]
    local v3 = p1[2]
    local v4 = p1[3]
    local v5 = p1[4]
    local v6 = v2[1]
    local v7 = v3[1]
    local v8 = v4[1]
    local v9 = v2[2]
    local v10 = v3[2]
    local v11 = v4[2]
    local v12 = v2[3]
    local v13 = v3[3]
    local v14 = v4[3]
    local v15 = 0 - v5[1]
    local v16 = 0 - v5[2]
    local v17 = 0 - v5[3]
    local _ = 0 - v5[4]

    return {
        { v6, v7, v8, 0 },
        { v9, v10, v11, 0 },
        { v12, v13, v14, 0 },
        {
            v15 * v6 + (v16 * v9 + v17 * v12),
            v15 * v7 + (v16 * v10 + v17 * v13),
            v15 * v8 + (v16 * v11 + v17 * v14),
            v15 * 0 + (v16 * 0 + v17 * 0)
        }
    }
end

function t1.inverse_rigid_reference(p2) -- line: 78
    -- upvalues: rt (copy), IDENTITY (copy)
    local v18 = rt.copy(IDENTITY)

    for i = 0, 2 do
        v18[i + 1] = {
            p2[1][i + 1],
            p2[2][i + 1],
            p2[3][i + 1],
            0
        }
    end

    local t2 = {
        0 - p2[4][1],
        0 - p2[4][2],
        0 - p2[4][3],
        0 - p2[4][4]
    }
    local v19 = table.create(4)

    for i = 0, 3 do
        local v20 = t2[3] * v18[3][i + 1]
        local v21 = t2[2] * v18[2][i + 1] + v20

        v19[i + 1] = t2[1] * v18[1][i + 1] + v21
    end

    v18[4] = v19

    return v18
end

local function compose_inverse_rigid(p3, p4) -- line: 99
    local v22 = p3[1]
    local v23 = p3[2]
    local v24 = p3[3]
    local v25 = p3[4]
    local v26 = v22[1]
    local v27 = v23[1]
    local v28 = v24[1]
    local v29 = v22[2]
    local v30 = v23[2]
    local v31 = v24[2]
    local v32 = v22[3]
    local v33 = v23[3]
    local v34 = v24[3]
    local v35 = 0 - v25[1]
    local v36 = 0 - v25[2]
    local v37 = 0 - v25[3]
    local v38 = v35 * v26 + (v36 * v29 + v37 * v32)
    local v39 = v35 * v27 + (v36 * v30 + v37 * v33)
    local v40 = v35 * v28 + (v36 * v31 + v37 * v34)
    local v41 = v35 * 0 + (v36 * 0 + v37 * 0)
    local v42 = p4[1]
    local v43 = p4[2]
    local v44 = p4[3]
    local v45 = p4[4]
    local v46 = v42[1]
    local v47 = v42[2]
    local v48 = v42[3]
    local v49 = v43[1]
    local v50 = v43[2]
    local v51 = v43[3]
    local v52 = v44[1]
    local v53 = v44[2]
    local v54 = v44[3]
    local v55 = v45[1]
    local v56 = v45[2]
    local v57 = v45[3]

    return {
        {
            v48 * v32 + (v47 * v29 + v46 * v26),
            v48 * v33 + (v47 * v30 + v46 * v27),
            v48 * v34 + (v47 * v31 + v46 * v28),
            v48 * 0 + (v47 * 0 + v46 * 0)
        },
        {
            v51 * v32 + (v50 * v29 + v49 * v26),
            v51 * v33 + (v50 * v30 + v49 * v27),
            v51 * v34 + (v50 * v31 + v49 * v28),
            v51 * 0 + (v50 * 0 + v49 * 0)
        },
        {
            v54 * v32 + (v53 * v29 + v52 * v26),
            v54 * v33 + (v53 * v30 + v52 * v27),
            v54 * v34 + (v53 * v31 + v52 * v28),
            v54 * 0 + (v53 * 0 + v52 * 0)
        },
        {
            v32 * v57 + (v29 * v56 + (v26 * v55 + v38)),
            v33 * v57 + (v30 * v56 + (v27 * v55 + v39)),
            v34 * v57 + (v31 * v56 + (v28 * v55 + v40)),
            0 * v57 + (0 * v56 + (0 * v55 + v41))
        }
    }
end

t1.compose_inverse_rigid = compose_inverse_rigid

function t1.prepare_animation_target(p5, p6, p7, p8, p9, p10, p11) -- line: 149
    -- upvalues: rt (copy), compose_affine (copy), compose_inverse_rigid (copy)
    if p5.mode ~= "OnDeck" and not (p5.board_blend > 0) and p5.external_blend >= 1 then
        return
    end

    local v58 = p8[p7.part + 1]

    p6.board = compose_affine(p10, p6.target)
    p5.part_position = rt.copy(p6.board[4])
    p6.world = compose_affine(p9, v58)

    local v59 = true

    for i = 0, 2 do
        if p5.part_position[i + 1] > p11[i + 1] or -p11[i + 1] > p5.part_position[i + 1] then
            v59 = false
            break
        end
    end

    p6.within_contact_bounds = v59

    local parent_part = p7.parent_part

    if parent_part == nil then
        return
    end

    local v60 = compose_inverse_rigid(v58, p8[parent_part + 1])

    p6.parent_board = compose_affine(p6.board, v60)
    p6.parent_world = compose_affine(p6.world, v60)
end

function t1.prepare_animation_target_reference(p12, p13, p14, p15, p16, p17, p18) -- line: 197
    -- upvalues: rt (copy), compose_affine (copy), t1 (copy)
    if p12.mode ~= "OnDeck" and not (p12.board_blend > 0) and p12.external_blend >= 1 then
        return
    end

    local v61 = p15[p14.part + 1]

    p13.board = compose_affine(p17, p13.target)
    p12.part_position = rt.copy(p13.board[4])
    p13.world = compose_affine(p16, v61)

    local v62 = true

    for i = 0, 2 do
        if p12.part_position[i + 1] > p18[i + 1] or -p18[i + 1] > p12.part_position[i + 1] then
            v62 = false
            break
        end
    end

    p13.within_contact_bounds = v62

    local parent_part = p14.parent_part

    if parent_part == nil then
        return
    end

    local v63 = compose_affine(t1.inverse_rigid(v61), p15[parent_part + 1])

    p13.parent_board = compose_affine(p13.board, v63)
    p13.parent_world = compose_affine(p13.world, v63)
end

return t1
