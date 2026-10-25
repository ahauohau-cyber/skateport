-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/animation/foot_ik/physical_solve")
local v2 = import("skate_core/animation/foot_ik/post_contact")
local LIMBS = import("skate_core/animation/foot_ik/state").LIMBS
local dot3 = import("skate_core/physics/native_arithmetic").dot3
local compose_affine = import("skate_core/physics/skeleton_animation_record").compose_affine
local SkeletonBody = import("skate_core/physics/skeleton_body").SkeletonBody
local t1 = {
    Input = {}
}

local function sub(p1, p2) -- line: 32
    return {
        p1[1] - p2[1],
        p1[2] - p2[2],
        p1[3] - p2[3],
        p1[4] - p2[4]
    }
end

local function unwrap(p3) -- line: 36
    if p3 == nil then
        error("called `Option::unwrap()` on a `None` value", 0)
    end

    return p3
end

local function feet(p4, p5, p6, p7, p8, p9, p10) -- line: 44
    -- upvalues: rt (copy), v1 (copy), v2 (copy), LIMBS (copy), dot3 (copy), compose_affine (copy), SkeletonBody (copy)
    local v3 = rt.copy(p9.board)

    if bit32.band(p9.flags_2484, 2097152) ~= 0 then
        v3[1][1] = v3[1][1] * -1
        v3[1][2] = v3[1][2] * -1
        v3[1][3] = v3[1][3] * -1
        v3[1][4] = v3[1][4] * -1
        v3[2][1] = v3[2][1] * -1
        v3[2][2] = v3[2][2] * -1
        v3[2][3] = v3[2][3] * -1
        v3[2][4] = v3[2][4] * -1
    end

    local v4 = rt.copy(v3[2])
    local v5 = v4[1] * p9.world_to_animation[1][2]
    local v6 = v4[2] * p9.world_to_animation[2][2] + v5
    local v7 = v4[3] * p9.world_to_animation[3][2] + v6
    local v8 = bit32.band(p9.flags_2468, 262144) ~= 0

    if not (bit32.band(p9.flags_2484, 1048576) ~= 0 or v7 < p8.minimum_board_up or v8 and p9.value_2664 > 0.03999999910593033) then
        local v9 = if v8 then p9.state_2520 == 500 else nil

        if not v8 or not v9 then
            for i = 0, 1 do
                local v10 = rt.copy(LIMBS[i + 1])
                local parent_part = v10.parent_part

                if parent_part == nil then
                    error("called `Option::unwrap()` on a `None` value", 0)
                end

                local v11 = p4.frames[i + 1]

                if not v11.within_contact_bounds or p9.wipeout then
                    if not p4.limbs[i + 1].external_target_set then
                        local v12 = rt.copy(p5.record.pose[v10.part + 1])

                        if not (dot3(v12[2], v4) <= 0) then
                            local v13 = v2.target(v3, rt.copy(v12[4]), rt.copy(p5.record.pose[parent_part + 1][4]), rt.copy(p4.limbs[i + 1].part_position), p9.wipeout, p7, p8)

                            if v13 ~= nil then
                                local v14 = v12[4]
                                local v15 = dot3(v4, {
                                    v13[1] - v14[1],
                                    v13[2] - v14[2],
                                    v13[3] - v14[3],
                                    v13[4] - v14[4]
                                })
                                local t2 = {
                                    v4[1] * v15,
                                    v4[2] * v15,
                                    v4[3] * v15,
                                    v4[4] * v15
                                }

                                if v1.solve(p5, p6, parent_part, t2) then
                                    v12[4] = v13
                                    SkeletonBody.set_part_transform(p5, v10.part, v12)

                                    local v16 = rt.copy(p5.record.pose[parent_part + 1])

                                    v16[4][1] += t2[1]
                                    v16[4][2] += t2[2]
                                    v16[4][3] += t2[3]
                                    v16[4][4] += t2[4]
                                    SkeletonBody.set_part_transform(p5, parent_part, v16)
                                    p10[i + 1] = true
                                end
                            end
                        end
                    end
                else
                    v11.world = compose_affine(p9.board, v11.board)
                    v11.parent_world = compose_affine(p9.board, v11.parent_board)

                    local v17 = v11.parent_world[4]
                    local v18 = p5.record.pose[parent_part + 1][4]
                    local t3 = {
                        v17[1] - v18[1],
                        v17[2] - v18[2],
                        v17[3] - v18[3],
                        v17[4] - v18[4]
                    }

                    if v1.solve(p5, p6, parent_part, t3) then
                        SkeletonBody.set_part_transform(p5, v10.part, rt.copy(v11.world))
                        SkeletonBody.set_part_transform(p5, parent_part, rt.copy(v11.parent_world))
                        p10[i + 1] = true
                    end
                end
            end
        end
    end
end

function t1.update(p11, p12, p13, p14, p15, p16) -- line: 114
    -- upvalues: rt (copy), v1 (copy), LIMBS (copy), compose_affine (copy), SkeletonBody (copy), feet (copy)
    local t4 = {
        false,
        false,
        false,
        false
    }

    if p16.state_id ~= 702 then
        local v19 = p16.state_id == 200 or p16.state_id == 201

        if (not v19 or p16.board_body_flag_868) and p16.category_id ~= 500 then
            feet(p11, p12, p13, p14, p15, p16, t4)
        end

        if v19 and p16.board_body_flag_868 then
            for i = 2, 3 do
                if p11.frames[i + 1].within_contact_bounds then
                    p11.frames[i + 1].world = compose_affine(p16.board, p11.frames[i + 1].board)

                    local part = LIMBS[i + 1].part
                    local v20 = p11.frames[i + 1].world[4]
                    local v21 = p12.record.pose[part + 1][4]
                    local t5 = {
                        v20[1] - v21[1],
                        v20[2] - v21[2],
                        v20[3] - v21[3],
                        v20[4] - v21[4]
                    }

                    if v1.solve(p12, p13, part, t5) then
                        SkeletonBody.set_part_transform(p12, part, rt.copy(p11.frames[i + 1].world))
                        t4[i + 1] = true
                    end
                end
            end
        end
    end

    for i = 0, 1 do
        if not (p11.limbs[i + 1].external_blend <= 0) then
            local v22 = rt.copy(LIMBS[i + 1])
            local parent_part = v22.parent_part

            if parent_part == nil then
                error("called `Option::unwrap()` on a `None` value", 0)
            end

            local v23 = p11.frames[i + 1].parent_world[4]
            local v24 = p12.record.pose[parent_part + 1][4]
            local t6 = {
                v23[1] - v24[1],
                v23[2] - v24[2],
                v23[3] - v24[3],
                v23[4] - v24[4]
            }

            if v1.solve(p12, p13, parent_part, t6) then
                SkeletonBody.set_part_transform(p12, v22.part, rt.copy(p11.frames[i + 1].world))
                SkeletonBody.set_part_transform(p12, parent_part, rt.copy(p11.frames[i + 1].parent_world))
                t4[i + 1] = true
            end
        end
    end

    p11.external_targets[1].normal_set = false
    p11.limbs[1].external_target_set = false
    p11.limbs[1].local_target_set = false
    p11.external_targets[2].normal_set = false
    p11.limbs[2].external_target_set = false
    p11.limbs[2].local_target_set = false
    p11.external_targets[3].normal_set = false
    p11.limbs[3].external_target_set = false
    p11.limbs[3].local_target_set = false
    p11.external_targets[4].normal_set = false
    p11.limbs[4].external_target_set = false
    p11.limbs[4].local_target_set = false

    return t4
end

t1.feet = feet
t1.sub = sub

return t1
