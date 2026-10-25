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
local v1 = import("skate_core/math")
local v2 = import("skate_core/physics/board")
local v3 = import("skate_core/physics/board_runtime")
local v4 = import("skate_core/physics/board_step")
local v5 = import("skate_core/physics/rigid_body")
local v6 = import("skate_core/physics/skeleton_body")
local v7 = import("skate_core/physics/world_contact")
local Vector3 = v1.Vector3
local BodyId = v2.BodyId
local BoardRuntime = v3.BoardRuntime
local ATTACHED_REACTION_BASE = v4.ATTACHED_REACTION_BASE
local world_inverse_inertia = v5.world_inverse_inertia
local SkeletonBody, SkeletonCollisionMode = v6.SkeletonBody, v6.SkeletonCollisionMode
local triangle_from_volume = v7.triangle_from_volume

local function colliders() -- line: 53
    -- upvalues: import (copy)
    return import("skate_game/physics/colliders")
end

local function skeleton_colliders() -- line: 56
    -- upvalues: import (copy)
    return import("skate_game/physics/skeleton_colliders")
end

local function solid_contacts() -- line: 59
    -- upvalues: import (copy)
    return import("skate_game/physics/solid_contacts")
end

local function animation() -- line: 62
    -- upvalues: import (copy)
    return import("skate_game/animation")
end

local function player_physics() -- line: 65
    -- upvalues: import (copy)
    return import("skate_game/modding/player_physics")
end

local function board_manager_runtime() -- line: 68
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/board_manager/runtime")
end

local t1 = {}

local function glam_quat_normalize(p2) -- line: 75
    local v9 = 1 / math.sqrt(p2[1] * p2[1] + p2[2] * p2[2] + p2[3] * p2[3] + p2[4] * p2[4])

    return {
        p2[1] * v9,
        p2[2] * v9,
        p2[3] * v9,
        p2[4] * v9
    }
end

local function glam_mat3_from_quat(p3) -- line: 80
    local v10 = p3[1]
    local v11 = p3[2]
    local v12 = p3[3]
    local v13 = p3[4]
    local v14 = v10 + v10
    local v15 = v11 + v11
    local v16 = v12 + v12
    local v17 = v10 * v14
    local v18 = v10 * v15
    local v19 = v10 * v16
    local v20 = v11 * v15
    local v21 = v11 * v16
    local v22 = v12 * v16
    local v23 = v13 * v14
    local v24 = v13 * v15
    local v25 = v13 * v16

    return {
        {
            1 - (v20 + v22),
            v18 + v25,
            v19 - v24
        },
        {
            v18 - v25,
            1 - (v17 + v22),
            v21 + v23
        },
        {
            v19 + v24,
            v21 - v23,
            1 - (v17 + v20)
        }
    }
end

local function glam_mat4_from_rotation_translation(p4, p5) -- line: 101
    -- upvalues: glam_mat3_from_quat (copy)
    local v26 = glam_mat3_from_quat(p4)

    return {
        {
            v26[1][1],
            v26[1][2],
            v26[1][3],
            0
        },
        {
            v26[2][1],
            v26[2][2],
            v26[2][3],
            0
        },
        {
            v26[3][1],
            v26[3][2],
            v26[3][3],
            0
        },
        {
            p5[1],
            p5[2],
            p5[3],
            1
        }
    }
end

local function glam_mat4_mul(p6, p7) -- line: 111
    local v27 = table.create(4)

    for i = 1, 4 do
        local v28 = p7[i]
        local v29 = v28[1]
        local v30 = v28[2]
        local v31 = v28[3]
        local v32 = v28[4]

        v27[i] = {
            p6[1][1] * v29 + p6[2][1] * v30 + p6[3][1] * v31 + p6[4][1] * v32,
            p6[1][2] * v29 + p6[2][2] * v30 + p6[3][2] * v31 + p6[4][2] * v32,
            p6[1][3] * v29 + p6[2][3] * v30 + p6[3][3] * v31 + p6[4][3] * v32,
            p6[1][4] * v29 + p6[2][4] * v30 + p6[3][4] * v31 + p6[4][4] * v32
        }
    end

    return v27
end

local function glam_mat4_inverse(p8) -- line: 127
    local v33 = p8[1][1]
    local v34 = p8[1][2]
    local v35 = p8[1][3]
    local v36 = p8[1][4]
    local v37 = p8[2][1]
    local v38 = p8[2][2]
    local v39 = p8[2][3]
    local v40 = p8[2][4]
    local v41 = p8[3][1]
    local v42 = p8[3][2]
    local v43 = p8[3][3]
    local v44 = p8[3][4]
    local v45 = p8[4][1]
    local v46 = p8[4][2]
    local v47 = p8[4][3]
    local v48 = p8[4][4]
    local v49 = v33 * v38 - v37 * v34
    local v50 = v33 * v39 - v37 * v35
    local v51 = v33 * v40 - v37 * v36
    local v52 = v34 * v39 - v38 * v35
    local v53 = v34 * v40 - v38 * v36
    local v54 = v35 * v40 - v39 * v36
    local v55 = v43 * v48 - v47 * v44
    local v56 = v42 * v48 - v46 * v44
    local v57 = v42 * v47 - v46 * v43
    local v58 = v41 * v48 - v45 * v44
    local v59 = v41 * v47 - v45 * v43
    local v60 = v41 * v46 - v45 * v42
    local v61 = v49 * v55 - v50 * v56 + v51 * v57 + v52 * v58 - v53 * v59 + v54 * v60
    local v62 = 1 / v61

    return {
        {
            (v38 * v55 - v39 * v56 + v40 * v57) * v62,
            (-v34 * v55 + v35 * v56 - v36 * v57) * v62,
            (v46 * v54 - v47 * v53 + v48 * v52) * v62,
            (-v42 * v54 + v43 * v53 - v44 * v52) * v62
        },
        {
            (-v37 * v55 + v39 * v58 - v40 * v59) * v62,
            (v33 * v55 - v35 * v58 + v36 * v59) * v62,
            (-v45 * v54 + v47 * v51 - v48 * v50) * v62,
            (v41 * v54 - v43 * v51 + v44 * v50) * v62
        },
        {
            (v37 * v56 - v38 * v58 + v40 * v60) * v62,
            (-v33 * v56 + v34 * v58 - v36 * v60) * v62,
            (v45 * v53 - v46 * v51 + v48 * v49) * v62,
            (-v41 * v53 + v42 * v51 - v44 * v49) * v62
        },
        {
            (-v37 * v57 + v38 * v59 - v39 * v60) * v62,
            (v33 * v57 - v34 * v59 + v35 * v60) * v62,
            (-v45 * v52 + v46 * v50 - v47 * v49) * v62,
            (v41 * v52 - v42 * v50 + v43 * v49) * v62
        }
    }, v61
end

local function glam_quat_from_rotation_axes(p9, p10, p11) -- line: 175
    local v63 = p9[1]
    local v64 = p9[2]
    local v65 = p9[3]
    local v66 = p10[1]
    local v67 = p10[2]
    local v68 = p10[3]
    local v69 = p11[1]
    local v70 = p11[2]
    local v71 = p11[3]

    if v71 <= 0 then
        local v72 = v67 - v63
        local v73 = 1 - v71

        if v72 <= 0 then
            local v74 = v73 - v72
            local v75 = 0.5 / math.sqrt(v74)

            return {
                v74 * v75,
                (v64 + v66) * v75,
                (v65 + v69) * v75,
                (v68 - v70) * v75
            }
        end

        local v76 = v73 + v72
        local v77 = 0.5 / math.sqrt(v76)

        return {
            (v64 + v66) * v77,
            v76 * v77,
            (v68 + v70) * v77,
            (v69 - v65) * v77
        }
    end

    local v78 = v67 + v63
    local v79 = 1 + v71

    if v78 <= 0 then
        local v80 = v79 - v78
        local v81 = 0.5 / math.sqrt(v80)

        return {
            (v65 + v69) * v81,
            (v68 + v70) * v81,
            v80 * v81,
            (v64 - v66) * v81
        }
    end

    local v82 = v79 + v78
    local v83 = 0.5 / math.sqrt(v82)

    return {
        (v68 - v70) * v83,
        (v69 - v65) * v83,
        (v64 - v66) * v83,
        v82 * v83
    }
end

local function glam_transform_from_matrix(p12) -- line: 212
    -- upvalues: rt (copy), glam_mat4_inverse (copy), glam_quat_from_rotation_axes (copy)
    local _, v84 = glam_mat4_inverse(p12)
    local v85 = p12[1]
    local v86 = p12[2]
    local v87 = p12[3]
    local v89 = math.sqrt(v85[1] * v85[1] + v85[2] * v85[2] + v85[3] * v85[3] + v85[4] * v85[4]) * rt.signum(v84)
    local v91 = math.sqrt(v86[1] * v86[1] + v86[2] * v86[2] + v86[3] * v86[3] + v86[4] * v86[4])
    local v93 = math.sqrt(v87[1] * v87[1] + v87[2] * v87[2] + v87[3] * v87[3] + v87[4] * v87[4])
    local v94 = 1 / v89
    local v95 = 1 / v91
    local v96 = 1 / v93
    local v97 = glam_quat_from_rotation_axes({
        v85[1] * v94,
        v85[2] * v94,
        v85[3] * v94
    }, {
        v86[1] * v95,
        v86[2] * v95,
        v86[3] * v95
    }, {
        v87[1] * v96,
        v87[2] * v96,
        v87[3] * v96
    })

    return {
        p12[4][1],
        p12[4][2],
        p12[4][3]
    }, v97
end

local function glam_transform_point3(p13, p14) -- line: 227
    return {
        p13[1][1] * p14[1] + p13[2][1] * p14[2] + p13[3][1] * p14[3] + p13[4][1],
        p13[1][2] * p14[1] + p13[2][2] * p14[2] + p13[3][2] * p14[3] + p13[4][2],
        p13[1][3] * p14[1] + p13[2][3] * p14[2] + p13[3][3] * p14[3] + p13[4][3]
    }
end

local function glam_transform_vector3(p15, p16) -- line: 234
    return {
        p15[1][1] * p16[1] + p15[2][1] * p16[2] + p15[3][1] * p16[3],
        p15[1][2] * p16[1] + p15[2][2] * p16[2] + p15[3][2] * p16[3],
        p15[1][3] * p16[1] + p15[2][3] * p16[2] + p15[3][3] * p16[3]
    }
end

local function u64_halves(p17) -- line: 243
    local v98 = string.match(p17, "^0[xX](%x+)$") or "0"
    local v100 = string.rep("0", (math.max(0, 16 - #v98))) .. v98

    return tonumber(string.sub(v100, 1, #v100 - 8), 16), (tonumber(string.sub(v100, #v100 - 7), 16))
end

local function u64_test(p18, p19) -- line: 249
    -- upvalues: u64_halves (copy)
    local v106, v107 = u64_halves(p18)

    if p19 < 32 then
        return bit32.band(v107, (bit32.lshift(1, p19))) ~= 0
    end

    if not (p19 < 64) then
        return false
    end

    return bit32.band(v106, (bit32.lshift(1, p19 - 32))) ~= 0
end

local transform

function t1.pose(p20) -- line: 262
    -- upvalues: glam_quat_normalize (copy), glam_transform_from_matrix (copy)
    local v111, v112 = glam_transform_from_matrix(p20)

    return {
        p = v111,
        q = glam_quat_normalize(v112)
    }
end

function t1.matrix(p21) -- line: 271
    -- upvalues: glam_quat_normalize (copy), glam_mat4_from_rotation_translation (copy)
    return (glam_mat4_from_rotation_translation(glam_quat_normalize(p21.q), p21.p))
end

function t1.xyz(p22) -- line: 276
    return {
        p22.x,
        p22.y,
        p22.z
    }
end

local xyz2 = t1.xyz

function t1.vector(p23) -- line: 282
    -- upvalues: Vector3 (copy)
    return Vector3.new(p23[1], p23[2], p23[3])
end

local vector = t1.vector

function t1.body_pose(p24) -- line: 288
    -- upvalues: glam_quat_normalize (copy), xyz2 (copy)
    local orientation = p24.rates.orientation

    return {
        p = xyz2(p24.rates.position),
        q = glam_quat_normalize({
            orientation.x,
            orientation.y,
            orientation.z,
            orientation.w
        })
    }
end

local body_pose = t1.body_pose

function t1.anchors(p25) -- line: 298
    -- upvalues: rt (copy)
    local v113 = rt.copy(p25.animated_skeleton.bone_indices)
    local board_bones = p25.skeleton_output.pose.board_bones

    table.insert(v113, board_bones.front_truck)
    table.insert(v113, board_bones.back_truck)
    table.insert(v113, board_bones.front_left_wheel)
    table.insert(v113, board_bones.front_right_wheel)
    table.insert(v113, board_bones.back_left_wheel)
    table.insert(v113, board_bones.back_right_wheel)

    for v114, v115 in ipairs(p25.animation.evaluator.frames.bone_names) do
        if string.upper(v115) == "HEAD" then
            table.insert(v113, v114 - 1)
            break
        end
    end

    table.sort(v113)

    local t2 = {}

    for _, v117 in ipairs(v113) do
        if t2[#t2] ~= v117 then
            table.insert(t2, v117)
        end
    end

    return t2
end

function t1.capture_body(p26, p27) -- line: 327
    -- upvalues: import (copy), BodyId (copy), BoardRuntime (copy), SkeletonBody (copy), t1 (copy), xyz2 (copy), body_pose (copy)
    local n1 = 0
    local n2 = 0

    local function set(p28) -- line: 330
        -- upvalues: n1 (ref), n2 (ref)
        if p28 < 32 then
            local v118 = n2

            n2 = bit32.bor(v118, (bit32.lshift(1, p28)))
        else
            local v120 = n1

            n1 = bit32.bor(v120, (bit32.lshift(1, p28 - 32)))
        end
    end

    local LiveState = import("skate_game/physics/offboard/board_manager/runtime").LiveState

    for v123, v124 in ipairs(BoardRuntime.bodies(p26.board)) do
        local v125 = v123 - 1

        if v124.state_flags ~= 1 and LiveState.volume_enabled(p27.board_possession_live, {
            tag = "Board",
            BodyId.ORDER[v125 + 1]
        }) then
            if v125 < 32 then
                local v126 = bit32.lshift(1, v125)

                n2 = bit32.bor(n2, v126)
            else
                local v129 = bit32.lshift(1, v125 - 32)

                n1 = bit32.bor(n1, v129)
            end
        end
    end

    for v131, v132 in ipairs(import("skate_game/modding/player_physics").collision_parts(p27)) do
        local v133 = v131 - 1

        if v132.enabled and v132.volume_group == 0 then
            local v134 = 7 + v133

            if v134 < 32 then
                local v135 = bit32.lshift(1, v134)

                n2 = bit32.bor(n2, v135)
            else
                local v138 = bit32.lshift(1, v134 - 32)

                n1 = bit32.bor(n1, v138)
            end
        end
    end

    if p27.skeleton_collision.is_ragdoll then
        n1 = bit32.bor(n1, 2147483648)
    end

    local t3 = {}

    local function push(p29) -- line: 359
        -- upvalues: t3 (copy), xyz2 (copy), body_pose (copy)
        table.insert(t3, {
            pose = body_pose(p29),
            velocity = xyz2(p29.rates.linear_velocity),
            angular = xyz2(p29.rates.angular_velocity)
        })
    end

    for _, v141 in ipairs(BoardRuntime.bodies(p26.board)) do
        push(v141)
    end

    for _, v142 in ipairs(SkeletonBody.bodies(p27.skeleton)) do
        push(v142)
    end

    return {
        root = t1.pose(import("skate_game/animation").native_matrix(p27.animated_skeleton.roots.animation_to_world)),
        enabled = string.format("0x%08X%08X", n1, n2),
        bodies = t3
    }
end

function t1.capture_pose(p30, p31) -- line: 380
    -- upvalues: import (copy), t1 (copy)
    local t5 = {}

    for _, v143 in ipairs(p31) do
        local v144 = p30.render_pose[v143 + 1]

        if v144 ~= nil then
            table.insert(t5, {
                index = v143,
                pose = t1.pose(import("skate_game/animation").native_matrix(v144))
            })
        end
    end

    return {
        root = t1.pose(import("skate_game/animation").native_matrix(p30.animated_skeleton.roots.animation_to_world)),
        bones = t5
    }
end

t1.Schema = {}

function t1.Schema.visual_colliders(p32, p33, p34) -- line: 405
    -- upvalues: rt (copy), import (copy), t1 (copy), glam_mat4_mul (copy), glam_mat4_inverse (copy), u64_halves (copy), transform (ref)
    local v145 = glam_mat4_mul(p34, (glam_mat4_inverse(t1.matrix(p33.root))))
    local t7 = {}

    for _, v146 in ipairs(p32.volumes) do
        local v147 = v146[1]
        local v148 = v146[2]
        local v149, v150 = u64_halves(p33.enabled)
        local v151 = if v147 < 32 then bit32.band(v150, (bit32.lshift(1, v147))) ~= 0 else v147 < 64 and bit32.band(v149, (bit32.lshift(1, v147 - 32))) ~= 0

        if v151 then
            local v155 = p33.bodies[v147 + 1]

            if v155 ~= nil then
                local v156 = transform(rt.copy(v148.primitive), (glam_mat4_mul(v145, t1.matrix(v155.pose))))
                local v157, v158 = import("skate_game/physics/solid_contacts").shape(v156)

                if v157 ~= nil then
                    table.insert(t7, {
                        friction = 0,
                        shape = v157,
                        pose = v158
                    })
                end
            end
        end
    end

    return t7
end

function t1.Schema.new(p35, p36) -- line: 428
    -- upvalues: rt (copy), import (copy), BodyId (copy), SkeletonCollisionMode (copy), t1 (copy), glam_mat4_inverse (copy), transform (ref)
    local v159 = SkeletonCollisionMode.new_normal(rt.copy(p36.skeleton_collision.settings), false)

    for _, v160 in ipairs(v159.parts) do
        v160.enabled = true
        v160.volume_group = 0
    end

    local v161 = import("skate_game/physics/colliders").world_volumes(p35.board, p35.settings)

    for _, v162 in ipairs(import("skate_game/physics/skeleton_colliders").world_volumes(p36.skeleton, v159)) do
        table.insert(v161, v162)
    end

    local v163 = t1.capture_body(p35, p36)
    local v164 = table.create(#v161)

    for _, v165 in ipairs(v161) do
        local v166

        if v165.body.tag == "Board" then
            v166 = BodyId.index(v165.body[1])
        elseif v165.body.tag == "Attached" then
            v166 = v165.body[1] + 7
        else
            error("internal error: entered unreachable code", 0)
        end

        v165.primitive = transform(v165.primitive, (glam_mat4_inverse(t1.matrix(v163.bodies[v166 + 1].pose))))
        table.insert(v164, {
            v166,
            v165
        })
    end

    return {
        fingerprint = nil,
        volumes = v164
    }
end

function t1.transform(p37, p38) -- line: 465
    -- upvalues: rt (copy), triangle_from_volume (copy), glam_transform_point3 (copy), glam_transform_vector3 (copy), xyz2 (copy), vector (copy)
    local function point(p39) -- line: 466
        -- upvalues: p38 (copy), glam_transform_point3 (copy), xyz2 (copy), vector (copy)
        return vector((glam_transform_point3(p38, xyz2(p39))))
    end

    local function direction(p40) -- line: 469
        -- upvalues: p38 (copy), glam_transform_vector3 (copy), xyz2 (copy), vector (copy)
        return vector((glam_transform_vector3(p38, xyz2(p40))))
    end

    if p37.tag == "Sphere" then
        local v167 = rt.copy(p37[1])

        v167.center = vector((glam_transform_point3(p38, xyz2(p37[1].center))))

        return {
            tag = "Sphere",
            v167
        }
    end

    if p37.tag == "Capsule" then
        return {
            tag = "Capsule",
            center = vector((glam_transform_point3(p38, xyz2(p37.center)))),
            axis = vector((glam_transform_vector3(p38, xyz2(p37.axis)))),
            half_length = p37.half_length,
            radius = p37.radius
        }
    end

    if p37.tag == "RoundedBox" then
        local v168 = table.create(3)

        for i = 1, 3 do
            local v169 = p37.basis.columns[i]

            v168[i] = {
                p38[1][1] * v169[1] + p38[2][1] * v169[2] + p38[3][1] * v169[3],
                p38[1][2] * v169[1] + p38[2][2] * v169[2] + p38[3][2] * v169[3],
                p38[1][3] * v169[1] + p38[2][3] * v169[2] + p38[3][3] * v169[3]
            }
        end

        return {
            tag = "RoundedBox",
            center = vector((glam_transform_point3(p38, xyz2(p37.center)))),
            basis = {
                columns = v168
            },
            half_extents = rt.copy(p37.half_extents),
            radius = p37.radius
        }
    end

    local v170 = p37[1]

    return {
        tag = "Triangle",
        (triangle_from_volume({
            vector((glam_transform_point3(p38, xyz2(v170.vertices[1])))),
            vector((glam_transform_point3(p38, xyz2(v170.vertices[2])))),
            point(v170.vertices[3])
        }, v170.fatness, { -1, -1, -1 }, 0))
    }
end

transform = t1.transform

function t1.bounds(p41) -- line: 520
    -- upvalues: rt (copy)
    if p41.tag == "Sphere" then
        local v174 = p41[1]

        return {
            x = v174.center.x,
            y = v174.center.y,
            z = v174.center.z
        }, v174.radius
    end

    if p41.tag == "Capsule" then
        return {
            x = p41.center.x,
            y = p41.center.y,
            z = p41.center.z
        }, p41.half_length + p41.radius
    end

    if p41.tag == "RoundedBox" then
        local half_extents = p41.half_extents

        return {
            x = p41.center.x,
            y = p41.center.y,
            z = p41.center.z
        }, math.sqrt(half_extents.x * half_extents.x + half_extents.y * half_extents.y + half_extents.z * half_extents.z) + p41.radius
    end

    local v176 = p41[1]
    local vertices = v176.vertices
    local t14 = {
        x = (vertices[1].x + vertices[2].x + vertices[3].x) / 3,
        y = (vertices[1].y + vertices[2].y + vertices[3].y) / 3,
        z = (vertices[1].z + vertices[2].z + vertices[3].z) / 3
    }
    local n3 = 0

    for i = 1, 3 do
        local v177 = vertices[i].x - t14.x
        local v178 = vertices[i].y - t14.y
        local v179 = vertices[i].z - t14.z

        n3 = rt.fmax(n3, (math.sqrt(v177 * v177 + v178 * v178 + v179 * v179)))
    end

    return t14, n3 + v176.fatness
end

t1.Proxies = {}

function t1.Proxies.default() -- line: 559
    return {
        bodies = {},
        volumes = {},
        solids = {},
        groups = {},
        actors = {},
        dynamics_before = {},
        dynamics_deltas = {}
    }
end

function t1.Proxies.append(p42, p43, p44, p45, p46, p47, p48) -- line: 574
    -- upvalues: rt (copy), Vector3 (copy), BoardRuntime (copy), world_inverse_inertia (copy), SkeletonBody (copy), t1 (copy), glam_quat_normalize (copy), glam_mat3_from_quat (copy), u64_halves (copy), transform (ref), vector (copy), body_pose (copy)
    local v181 = #SkeletonBody.bodies(p47.skeleton) + #p47.skeleton_drives.targets.bodies + #p42.bodies
    local v182 = #p42.bodies
    local t15 = {}

    for _, v183 in ipairs(BoardRuntime.bodies(p46.board)) do
        table.insert(t15, v183)
    end

    for _, v184 in ipairs(SkeletonBody.bodies(p47.skeleton)) do
        table.insert(t15, v184)
    end

    for i = 0, math.min(#t15, #p44.bodies) - 1 do
        local v187 = t15[i + 1]
        local v188 = p44.bodies[i + 1]
        local v189 = rt.copy(v187)

        if i < 7 then
            v189.inertia = rt.copy(p46.settings.masses[i + 1].dynamics)
        else
            local v190 = p47.skeleton.definition.parts[i - 7 + 1]
            local v192 = bit32.band(u64_halves(p44.enabled), 2147483648) ~= 0 and i - 7 >= 1 and i - 7 < 24
            local v193 = rt.copy(if v192 then v190.ragdoll.dynamics else v190.animated.dynamics)

            if v192 then
                v193.inverse_mass = v190.inverse_mass_ragdoll
            else
                v193.inverse_mass = v190.inverse_mass_animated
            end

            v189.inertia = v193
        end

        local v194 = p48.body(p48, v188)
        local v195 = glam_quat_normalize(v194.pose.q)

        v189.rates.orientation = {
            x = v195[1],
            y = v195[2],
            z = v195[3],
            w = v195[4]
        }
        v189.rates.basis = {
            columns = glam_mat3_from_quat(v195)
        }
        v189.rates.world_inverse_inertia = world_inverse_inertia(v189.rates.basis, v189.inertia.inverse_tensor)
        v189.rates.position = vector(v194.pose.p)
        v189.rates.linear_velocity = vector(v194.velocity)
        v189.rates.angular_velocity = vector(v194.angular)
        v189.rates.force_acceleration = Vector3.default()
        v189.rates.torque_acceleration = Vector3.default()
        v189.state_flags = 4

        local groups = p42.groups
        local v196 = v181 + i

        if i < 7 then
            groups[v196] = BoardRuntime.collision_group(p46.board)
        else
            groups[v196] = p47.skeleton_collision.assembly_group
        end

        p42.actors[v181 + i] = { p43, i }
        table.insert(p42.bodies, v189)
    end

    for _, v197 in ipairs(p45.volumes) do
        local v198 = v197[1]
        local v199 = v197[2]
        local v200, v201 = u64_halves(p44.enabled)
        local v202 = if v198 < 32 then bit32.band(v201, (bit32.lshift(1, v198))) ~= 0 else v198 < 64 and bit32.band(v200, (bit32.lshift(1, v198 - 32))) ~= 0

        if v202 then
            local v206 = p42.bodies[v182 + v198 + 1]

            if v206 == nil then
                error("index out of bounds", 0)
            end

            table.insert(p42.volumes, {
                body = {
                    tag = "Attached",
                    v181 + v198
                },
                primitive = transform(rt.copy(v199.primitive), t1.matrix(body_pose(v206))),
                linear_velocity = rt.copy(v206.rates.linear_velocity),
                material = rt.copy(v199.material)
            })
        end
    end
end

function t1.Proxies.append_solid(p49, p50, p51, p52, p53) -- line: 647
    -- upvalues: rt (copy), Vector3 (copy), BoardRuntime (copy), world_inverse_inertia (copy), SkeletonBody (copy), glam_quat_normalize (copy), glam_mat3_from_quat (copy), vector (copy)
    local function finite3(p54) -- line: 648
        local x = p54.x
        local v207 = x == x and x ~= 1e999 and x ~= (-1e999)

        if not v207 then
            return v207
        end

        local y = p54.y
        local v208 = y == y and y ~= 1e999 and y ~= (-1e999)

        if not v208 then
            return v208
        end

        local z = p54.z

        if z ~= z or z == 1e999 then
            return false
        end

        return z ~= (-1e999)
    end

    local inertia_rotation, center_of_mass = p50.inertia_rotation, p50.center_of_mass
    local x = center_of_mass.x
    local v209 = x == x and x ~= 1e999 and x ~= (-1e999)
    local v210

    if v209 then
        local y = center_of_mass.y
        local v211 = y == y and y ~= 1e999 and y ~= (-1e999)

        if v211 then
            local z = center_of_mass.z

            v210 = z == z and z ~= 1e999 and z ~= (-1e999)
        else
            v210 = v211
        end
    else
        v210 = v209
    end

    if not v210 then
        return
    end

    local linvel = p50.linvel
    local x2 = linvel.x
    local v212 = x2 == x2 and x2 ~= 1e999 and x2 ~= (-1e999)
    local v213

    if v212 then
        local y = linvel.y
        local v214 = y == y and y ~= 1e999 and y ~= (-1e999)

        if v214 then
            local z = linvel.z

            v213 = z == z and z ~= 1e999 and z ~= (-1e999)
        else
            v213 = v214
        end
    else
        v213 = v212
    end

    if not v213 then
        return
    end

    local angvel = p50.angvel
    local x3 = angvel.x
    local v215 = x3 == x3 and x3 ~= 1e999 and x3 ~= (-1e999)
    local v216

    if v215 then
        local y = angvel.y
        local v217 = y == y and y ~= 1e999 and y ~= (-1e999)

        if v217 then
            local z = angvel.z

            v216 = z == z and z ~= 1e999 and z ~= (-1e999)
        else
            v216 = v217
        end
    else
        v216 = v215
    end

    if v216 then
        local x = inertia_rotation.x

        if x == x and x ~= 1e999 and x ~= (-1e999) then
            local y = inertia_rotation.y

            if y == y and y ~= 1e999 and y ~= (-1e999) then
                local z = inertia_rotation.z

                if z == z and z ~= 1e999 and z ~= (-1e999) then
                    local w = inertia_rotation.w

                    if w == w and w ~= 1e999 and w ~= (-1e999) then
                        local v218 = #SkeletonBody.bodies(p52.skeleton) + #p52.skeleton_drives.targets.bodies + #p49.bodies
                        local v219 = rt.copy(BoardRuntime.bodies(p51.board)[1])
                        local v220 = glam_quat_normalize({
                            inertia_rotation.x,
                            inertia_rotation.y,
                            inertia_rotation.z,
                            inertia_rotation.w
                        })

                        v219.rates.position = vector({
                            p50.center_of_mass.x,
                            p50.center_of_mass.y,
                            p50.center_of_mass.z
                        })
                        v219.rates.orientation = {
                            x = v220[1],
                            y = v220[2],
                            z = v220[3],
                            w = v220[4]
                        }
                        v219.rates.basis = {
                            columns = glam_mat3_from_quat(v220)
                        }
                        v219.inertia.inverse_mass = p50.inverse_mass
                        v219.inertia.inverse_tensor = vector({
                            p50.inverse_inertia.x,
                            p50.inverse_inertia.y,
                            p50.inverse_inertia.z
                        })
                        v219.inertia.linear_drag = 0
                        v219.inertia.angular_drag = 0
                        v219.inertia.maximum_linear_velocity = 1E+05
                        v219.inertia.maximum_angular_velocity = 1E+05
                        v219.rates.world_inverse_inertia = world_inverse_inertia(v219.rates.basis, v219.inertia.inverse_tensor)
                        v219.rates.linear_velocity = vector({
                            p50.linvel.x,
                            p50.linvel.y,
                            p50.linvel.z
                        })
                        v219.rates.angular_velocity = vector({
                            p50.angvel.x,
                            p50.angvel.y,
                            p50.angvel.z
                        })
                        v219.rates.force_acceleration = Vector3.default()
                        v219.rates.torque_acceleration = Vector3.default()
                        v219.state_flags = 4
                        p49.groups[v218] = p50.contact_group

                        if p53 and p50.inverse_mass > 0 then
                            table.insert(p49.dynamics_before, {
                                p50.id,
                                v218,
                                {
                                    p50.linvel.x,
                                    p50.linvel.y,
                                    p50.linvel.z
                                },
                                {
                                    p50.angvel.x,
                                    p50.angvel.y,
                                    p50.angvel.z
                                }
                            })
                        end

                        table.insert(p49.bodies, v219)
                        table.insert(p49.solids, {
                            v218,
                            p50
                        })
                    end
                end
            end
        end
    end
end

local function assembly_contacts() -- line: 762
    -- upvalues: import (copy)
    return import("skate_game/physics/solve/assembly_contacts")
end

function t1.bounds_xyzr(p55) -- line: 768
    -- upvalues: rt (copy)
    local tag = p55.tag

    if tag == "Sphere" then
        local v221 = p55[1]
        local center = v221.center

        return center.x, center.y, center.z, v221.radius
    end

    if tag == "Capsule" then
        local center = p55.center

        return center.x, center.y, center.z, p55.half_length + p55.radius
    end

    if tag == "RoundedBox" then
        local half_extents, center = p55.half_extents, p55.center

        return center.x, center.y, center.z, math.sqrt(half_extents.x * half_extents.x + half_extents.y * half_extents.y + half_extents.z * half_extents.z) + p55.radius
    end

    local v223 = p55[1]
    local vertices = v223.vertices
    local v224 = (vertices[1].x + vertices[2].x + vertices[3].x) / 3
    local v225 = (vertices[1].y + vertices[2].y + vertices[3].y) / 3
    local v226 = (vertices[1].z + vertices[2].z + vertices[3].z) / 3
    local n4 = 0

    for i = 1, 3 do
        local v227 = vertices[i].x - v224
        local v228 = vertices[i].y - v225
        local v229 = vertices[i].z - v226

        n4 = rt.fmax(n4, (math.sqrt(v227 * v227 + v228 * v228 + v229 * v229)))
    end

    return v224, v225, v226, n4 + v223.fatness
end

local bounds_xyzr = t1.bounds_xyzr

local function schema_reach(p56) -- line: 799
    -- upvalues: bounds_xyzr (copy)
    local v231 = table.create(64, 0)
    local n5 = 0
    local n6 = -1

    for _, v232 in ipairs(p56.volumes) do
        local v233 = v232[1]
        local v234, v235, v236, v237 = bounds_xyzr(v232[2].primitive)
        local v239 = math.sqrt(v234 * v234 + v235 * v235 + v236 * v236) + v237

        if v233 >= 0 and v233 < 64 and v231[v233 + 1] < v239 then
            v231[v233 + 1] = v239
        end

        if n5 < v239 then
            n5 = v239
        end

        if n6 < v233 then
            n6 = v233
        end
    end

    local t19 = {
        body_reach = v231,
        reach = n5,
        max_index = n6
    }

    p56.deferred = t19

    return t19
end

local t20 = {
    owner = nil,
    tick = -1,
    count = 0,
    literal = false,
    base0 = 0,
    board_group = 0,
    assembly_group = 0,
    entries = {},
    kinetic = table.create(33, 0),
    cool = table.create(33, 0)
}

t1.Proxies.deferred_stats = {
    resolved = 0,
    culled = 0,
    bodies_tested = 0,
    bodies_placed = 0,
    volumes_placed = 0,
    candidates = 0,
    pairs = 0,
    rows = 0,
    bodies = 0,
    full = 0,
    literal = 0
}

local deferred_stats = t1.Proxies.deferred_stats

t1.Proxies.deferred_error = nil

function t1.Proxies.deferred(p57) -- line: 856
    -- upvalues: t20 (copy)
    if t20.owner == p57 then
        return t20.count
    end

    return 0
end

function t1.Proxies.clear_deferred(p58) -- line: 865
    -- upvalues: t20 (copy)
    t20.owner = p58
    t20.tick = -1
    t20.count = 0
    t20.literal = false
end

function t1.Proxies.defer(p59, p60, p61, p62, p63, p64, p65) -- line: 876
    -- upvalues: BoardRuntime (copy), SkeletonBody (copy), t1 (copy), u64_halves (copy), schema_reach (copy), t20 (copy), deferred_stats (copy)
    if t20.owner ~= p59 or t20.tick ~= p63.ticks then
        t20.owner = p59
        t20.tick = p63.ticks
        t20.count = 0
        t20.literal = false
    end

    local v240 = p62.deferred or schema_reach(p62)
    local v241 = BoardRuntime.bodies(p63.board)
    local v242 = SkeletonBody.bodies(p64.skeleton)

    if not t20.literal and not (v240.max_index >= 33) and #v241 == 7 and #v242 == 26 and not (#p61.bodies < 33) and type(p65.travel) == "number" and (t20.count ~= 0 or not (#p59.bodies > 0)) and not (#p59.solids > 0) and next(p64.mod_part_overrides) == nil then
        if t20.count == 0 then
            t20.base0 = #v242 + #p64.skeleton_drives.targets.bodies + #p59.bodies
            t20.board_group = BoardRuntime.collision_group(p63.board)
            t20.assembly_group = p64.skeleton_collision.assembly_group

            local kinetic, cool = t20.kinetic, t20.cool

            for i = 1, 7 do
                local rates = v241[i].rates
                local kinetic_energy, cool_down = rates.kinetic_energy, rates.cool_down

                kinetic[i] = kinetic_energy
                cool[i] = cool_down
            end

            for i = 1, 26 do
                local rates = v242[i].rates
                local v243 = i + 7
                local kinetic_energy, cool_down = rates.kinetic_energy, rates.cool_down

                kinetic[i + 7] = kinetic_energy
                cool[v243] = cool_down
            end
        end

        local v244 = t20.count + 1

        t20.count = v244

        local v245 = t20.entries[v244]

        if v245 == nil then
            v245 = {
                enabled = "",
                hi = 0,
                lo = 0,
                bound_frame = nil,
                bound_version = nil,
                cx = 0,
                cy = 0,
                cz = 0,
                radius = 0,
                speed = 0,
                prediction = {},
                infos = table.create(33),
                state = table.create(33, 0)
            }
            t20.entries[v244] = v245
        end

        v245.peer = p60
        v245.frame = p61
        v245.schema = p62

        local prediction = v245.prediction
        local travel, speed, body = p65.travel, p65.speed, p65.body

        prediction.travel = travel
        prediction.speed = speed
        prediction.body = body

        if v245.enabled ~= p61.enabled then
            v245.enabled = p61.enabled

            local v246, v247 = u64_halves(p61.enabled)

            v245.hi = v246
            v245.lo = v247
        end

        return true
    end

    for i = 1, t20.count do
        local v248 = t20.entries[i]

        t1.Proxies.append(p59, v248.peer, v248.frame, v248.schema, p63, p64, v248.prediction)
        deferred_stats.literal += 1
    end

    t20.count = 0
    t20.literal = true
    t1.Proxies.append(p59, p60, p61, p62, p63, p64, p65)
    deferred_stats.literal += 1

    return false
end

local function local_all_inactive(p66, p67) -- line: 957
    -- upvalues: BoardRuntime (copy), SkeletonBody (copy)
    for _, v249 in ipairs(BoardRuntime.bodies(p66.board)) do
        if bit32.band(v249.state_flags, 4) ~= 0 then
            return false
        end
    end

    if bit32.band(BoardRuntime.hook(p66.board).body.state_flags, 4) ~= 0 then
        return false
    end

    for _, v250 in ipairs(SkeletonBody.bodies(p67.skeleton)) do
        if bit32.band(v250.state_flags, 4) ~= 0 then
            return false
        end
    end

    for _, v251 in ipairs(p67.skeleton_drives.targets.bodies) do
        if bit32.band(v251.state_flags, 4) ~= 0 then
            return false
        end
    end

    return true
end

local function frame_bound(p68, p69) -- line: 981
    local version = p69.version

    if p68.bound_frame == p69 and version ~= nil and p68.bound_version == version then
        return
    end

    local bodies = p69.bodies
    local n7 = 1e999
    local n8 = 1e999
    local n9 = 1e999
    local n10 = (-1e999)
    local n11 = (-1e999)
    local n12 = (-1e999)
    local n13 = 0

    for i = 1, 33 do
        local v252 = bodies[i]
        local p = v252.pose.p
        local velocity = v252.velocity
        local v253 = p[1]
        local v254 = p[2]
        local v255 = p[3]

        if v253 < n7 then
            n7 = v253
        end

        if n10 < v253 then
            n10 = v253
        end

        if v254 < n8 then
            n8 = v254
        end

        if n11 < v254 then
            n11 = v254
        end

        if v255 < n9 then
            n9 = v255
        end

        if n12 < v255 then
            n12 = v255
        end

        local v256 = velocity[1] * velocity[1] + velocity[2] * velocity[2] + velocity[3] * velocity[3]

        if n13 < v256 then
            n13 = v256
        end
    end

    local v257 = (n7 + n10) * 0.5
    local v258 = (n8 + n11) * 0.5
    local v259 = (n9 + n12) * 0.5
    local n14 = 0

    for i = 1, 33 do
        local p = bodies[i].pose.p
        local v260 = p[1] - v257
        local v261 = p[2] - v258
        local v262 = p[3] - v259
        local v263 = v260 * v260 + v261 * v261 + v262 * v262

        if n14 < v263 then
            n14 = v263
        end
    end

    p68.cx = v257
    p68.cy = v258
    p68.cz = v259
    p68.radius = math.sqrt(n14)
    p68.speed = math.sqrt(n13)
    p68.bound_frame = p69
    p68.bound_version = version
end

local function proxy_body(p70, p71, p72, p73, p74) -- line: 1038
    -- upvalues: rt (copy), Vector3 (copy), world_inverse_inertia (copy), glam_mat3_from_quat (copy), vector (copy)
    local i = p74.i
    local v264

    if i < 7 then
        v264 = rt.copy(p72.settings.masses[i + 1].dynamics)
    else
        local v265 = p73.skeleton.definition.parts[i - 7 + 1]
        local v266 = p71.hi >= 2147483648 and i - 7 >= 1 and i - 7 < 24

        v264 = rt.copy(if v266 then v265.ragdoll.dynamics else v265.animated.dynamics)

        if v266 then
            v264.inverse_mass = v265.inverse_mass_ragdoll
        else
            v264.inverse_mass = v265.inverse_mass_animated
        end
    end

    local q = p74.q
    local t21 = {
        columns = glam_mat3_from_quat(q)
    }

    return {
        state_flags = 4,
        inertia = v264,
        rates = {
            orientation = {
                x = q[1],
                y = q[2],
                z = q[3],
                w = q[4]
            },
            basis = t21,
            world_inverse_inertia = world_inverse_inertia(t21, v264.inverse_tensor),
            position = vector(p74.p),
            linear_velocity = vector(p74.v),
            angular_velocity = vector(p74.w),
            force_acceleration = Vector3.default(),
            torque_acceleration = Vector3.default(),
            kinetic_energy = p70.kinetic[i + 1],
            cool_down = p70.cool[i + 1]
        }
    }
end

local function place_body(p75, p76) -- line: 1079
    -- upvalues: t1 (copy), glam_quat_normalize (copy), body_pose (copy)
    local prediction = p75.prediction
    local v267 = prediction.body(prediction, p75.frame.bodies[p76 + 1])
    local p = v267.pose.p
    local velocity, angular = v267.velocity, v267.angular
    local v268 = glam_quat_normalize(v267.pose.q)
    local t22 = {
        matrix = nil,
        used = false,
        label = -1,
        i = p76,
        p = {
            p[1],
            p[2],
            p[3]
        },
        q = v268,
        v = {
            velocity[1],
            velocity[2],
            velocity[3]
        },
        w = {
            angular[1],
            angular[2],
            angular[3]
        }
    }

    t22.matrix = t1.matrix(body_pose({
        rates = {
            position = {
                x = p[1],
                y = p[2],
                z = p[3]
            },
            orientation = {
                x = v268[1],
                y = v268[2],
                z = v268[3],
                w = v268[4]
            }
        }
    }))

    return t22
end

local n15 = 0
local t23 = {}
local t24 = {}
local t25 = {}
local t26 = {}
local t27 = {}
local t28 = {}
local t29 = {}
local t30 = {}
local t31 = {}
local t32 = {}
local t33 = {}
local t34 = {}
local t35 = {}
local t36 = {}
local t37 = {}

t1.Proxies.pack_once = true

local function resolve_inner(p77, p78, p79, p80, p81, p82, p83, p84) -- line: 1120
    -- upvalues: rt (copy), import (copy), t1 (copy), transform (ref), bounds_xyzr (copy), t20 (copy), deferred_stats (copy), local_all_inactive (copy), frame_bound (copy), proxy_body (copy), place_body (copy), n15 (ref), t23 (copy), t24 (copy), t25 (copy), t26 (copy), t27 (copy), t28 (copy), t29 (copy), t30 (copy), t31 (copy), t32 (copy), t33 (copy), t34 (copy), t35 (copy), t36 (copy), t37 (copy)
    local count = t20.count

    t20.count = 0
    n15 = 1

    local v269 = p83 ~= nil

    if not v269 and local_all_inactive(p81, p82) then
        v269 = true
    end

    if v269 then
        deferred_stats.full += 1
    end

    deferred_stats.resolved += count

    local v270 = #p79
    local v271 = v270 + #p80
    local n16 = 1e999
    local n17 = 1e999
    local n18 = 1e999
    local n19 = (-1e999)
    local n20 = (-1e999)
    local n21 = (-1e999)
    local v272, schema, body_reach, v273, pack

    for i = 1, v271 do
        pack = if i <= v270 then p79[i] else p80[i - v270]
        v272, body_reach, schema, v273 = bounds_xyzr(pack.primitive)
        t23[i] = v272
        t24[i] = body_reach
        t25[i] = schema
        t26[i] = v273
        pack = v273 + 0.05

        if v272 - pack < n16 then
            n16 = v272 - pack
        end

        if n19 < v272 + pack then
            n19 = v272 + pack
        end

        if body_reach - pack < n17 then
            n17 = body_reach - pack
        end

        if n20 < body_reach + pack then
            n20 = body_reach + pack
        end

        if schema - pack < n18 then
            n18 = schema - pack
        end

        if n21 < schema + pack then
            n21 = schema + pack
        end
    end

    local n22 = 0
    local travel, infos, state, cz, v274, v275, v276

    for i = 1, count do
        v272 = t20.entries[i]
        body_reach = v272.frame
        schema = v272.schema
        v273 = schema.deferred
        travel = v272.prediction.travel
        infos = v272.infos
        state = v272.state
        table.clear(infos)

        local v277 = false
        local v278 = false
        local v279 = false
        local v280 = false
        local v281 = false

        if v269 then
        else
            v277 = true
        end

        local cx, cy, v282

        if v277 then
            frame_bound(v272, body_reach)
            cx = v272.cx
            cy = v272.cy
            cz = v272.cz
            v282 = v272.radius + v272.speed * math.abs(travel) + v273.reach + 1E-04

            if cx < n16 then
                v279 = true
            else
                v278 = true
            end
        end

        v277 = false

        if v278 then
            if n19 < cx then
                v280 = true
            else
                v277 = true
            end
        end

        v278 = false

        if v277 then
            v276 = 0
            v278 = true
        end

        v277 = false

        if v280 then
            v276 = cx - n19
            v278 = true
        end

        v280 = false

        if v279 then
            v276 = n16 - cx
            v278 = true
        end

        v279 = false

        if v278 then
            if cy < n17 then
                v277 = true
            else
                v280 = true
            end
        end

        v278 = false

        if v280 then
            if n20 < cy then
                v279 = true
            else
                v278 = true
            end
        end

        v280 = false

        local v283

        if v278 then
            v283 = 0
            v280 = true
        end

        v278 = false

        if v279 then
            v283 = cy - n20
            v280 = true
        end

        v279 = false

        if v277 then
            v283 = n17 - cy
            v280 = true
        end

        v277 = false

        if v280 then
            if cz < n18 then
                v278 = true
            else
                v279 = true
            end
        end

        v280 = false

        if v279 then
            if n21 < cz then
                v277 = true
            else
                v280 = true
            end
        end

        v279 = false

        local v284

        if v280 then
            v284 = 0
            v279 = true
        end

        if v277 then
            v284 = cz - n21
            v279 = true
        end

        if v278 then
            v284 = n18 - cz
            v279 = true
        end

        if v279 then
            v281 = not (v276 * v276 + v283 * v283 + v284 * v284 <= v282 * v282)
        end

        if v281 then
            deferred_stats.culled += 1
        else
            for j = 1, 33 do
                state[j] = 0
            end

            if v269 then
                for k = 0, 32 do
                    local v285 = place_body(v272, k)

                    v285.used = true
                    infos[k + 1] = v285
                    state[k + 1] = 2
                end

                deferred_stats.bodies_placed += 33
            end

            local hi, lo = v272.hi, v272.lo
            local bodies = body_reach.bodies

            body_reach = v273.body_reach

            local v286 = n22

            for _, v287 in ipairs(schema.volumes) do
                v274 = v287[1]

                local v288 = v287[2]
                local v289 = v274 < 32
                local v290, v291, v292

                if v289 then
                    v275 = bit32.lshift(1, v274)
                    v290 = bit32.band(lo, v275) == 0
                else
                    v292 = v274 - 32
                    v275 = bit32.lshift(1, v292)
                    v291 = bit32.band(hi, v275) == 0
                end

                if v289 and not v290 or not v289 and not v291 then
                    v273 = state[v274 + 1]

                    local v293, v294, v295, v296, v297

                    if v273 == 0 then
                        deferred_stats.bodies_tested += 1
                        v293 = bodies[v274 + 1]
                        v294 = v293.pose.p
                        v275 = v293.velocity
                        v295 = v294[1] + v275[1] * travel
                        v292 = v294[2] + v275[2] * travel
                        v296 = v294[3] + v275[3] * travel
                        v275 = body_reach[v274 + 1] + 1E-04
                        v294 = if v295 < n16 then n16 - v295 elseif n19 < v295 then v295 - n19 else 0
                        v293 = if v292 < n17 then n17 - v292 elseif n20 < v292 then v292 - n20 else 0
                        v297 = if v296 < n18 then n18 - v296 elseif n21 < v296 then v296 - n21 else 0
                        v273 = 1

                        if v294 * v294 + v293 * v293 + v297 * v297 <= v275 * v275 then
                            for n = 1, v271 do
                                local v298 = v295 - t23[n]
                                local v299 = v292 - t24[n]
                                local v300 = v296 - t25[n]
                                local v301 = v275 + t26[n] + 0.05

                                if v298 * v298 + v299 * v299 + v300 * v300 <= v301 * v301 then
                                    v273 = 2
                                    break
                                end
                            end
                        end

                        if v273 == 2 then
                            infos[v274 + 1] = place_body(v272, v274)
                            deferred_stats.bodies_placed += 1
                        end

                        state[v274 + 1] = v273
                    end

                    if v273 ~= 1 then
                        v273 = infos[v274 + 1]

                        local v302 = transform(v288.primitive, v273.matrix)

                        deferred_stats.volumes_placed += 1
                        v293, v294, v275, v295 = bounds_xyzr(v302)

                        if v269 then
                            v286 += 1
                            v292 = v273.v
                            v297 = {}
                            v297.body = {
                                tag = "Attached",
                                -1
                            }
                            v297.primitive = v302
                            v297.linear_velocity = {
                                x = v292[1],
                                y = v292[2],
                                z = v292[3]
                            }
                            v297.material = rt.copy(v288.material)
                            t27[v286] = v297
                            t28[v286] = v293
                            t29[v286] = v294
                            t30[v286] = v275
                            t31[v286] = v295
                            t32[v286] = v273
                        else
                            v292 = v295 + 1E-04
                            v296 = if v293 < n16 then n16 - v293 elseif n19 < v293 then v293 - n19 else 0
                            v297 = if v294 < n17 then n17 - v294 elseif n20 < v294 then v294 - n20 else 0

                            local v303 = if v275 < n18 then n18 - v275 elseif n21 < v275 then v275 - n21 else 0

                            if v296 * v296 + v297 * v297 + v303 * v303 <= v292 * v292 then
                                v286 += 1
                                v292 = v273.v
                                v297 = {}
                                v297.body = {
                                    tag = "Attached",
                                    -1
                                }
                                v297.primitive = v302
                                v303 = {}
                                v303.x = v292[1]
                                v303.y = v292[2]
                                v303.z = v292[3]
                                v297.linear_velocity = v303
                                v297.material = rt.copy(v288.material)
                                t27[v286] = v297
                                t28[v286] = v293
                                t29[v286] = v294
                                t30[v286] = v275
                                t31[v286] = v295
                                t32[v286] = v273
                            end
                        end
                    end
                end

                n22 = v286
            end
        end
    end

    deferred_stats.candidates += n22
    n15 = 2

    local v304, v305

    if n22 > 0 and p83 ~= "list" then
        v304 = import("skate_game/physics/solve/assembly_contacts")

        local append_pair_pooled, append_pair_packed = v304.append_pair_pooled, v304.append_pair_packed

        pack = v304.pack
        n20 = t1.Proxies.pack_once
        n19 = nil

        for i = 1, v271 do
            n18 = if i <= v270 then p79[i] else p80[i - v270]
            v273 = t23[i]
            travel = t24[i]
            infos = t25[i]
            state = t26[i]

            for j = 1, n22 do
                n17 = v273 - t28[j]
                n16 = travel - t29[j]
                v269 = infos - t30[j]

                local v306

                if n17 * n17 + n16 * n16 + v269 * v269 <= (state + t31[j] + 0.05) ^ 2 then
                    v305 = #p78
                    deferred_stats.pairs += 1

                    local v307
                    local v308 = n19

                    if n20 then
                        v276 = t27[j]

                        if n19 == nil then
                            v308 = v304.pair_settings()
                        end

                        local v309 = t34[i]

                        if v309 == nil then
                            v309, v307 = pack(n18.primitive)
                            t34[i] = v309
                            t35[i] = v307
                        end

                        local v310 = t36[j]

                        if v310 == nil then
                            v310, v274 = pack(v276.primitive)
                            t36[j] = v310
                            t37[j] = v274
                        end

                        v275 = t35[i]
                        append_pair_packed(p78, n18, v276, v309, v275, v310, t37[j], v308)
                    else
                        append_pair_pooled(p78, n18, t27[j])
                    end

                    v276 = #p78
                    v306 = v308

                    if v305 < v276 then
                        t32[j].used = true
                        v307 = v305 + 1

                        for k = v307, v276 do
                            v306 = v308
                            t33[k - p84] = j
                        end
                    end
                else
                    v306 = n19
                end

                n19 = v306
            end
        end
    end

    v271 = #p78 - p84
    deferred_stats.rows += v271
    n15 = 3
    v304 = t20.base0
    v270 = 0

    for i = 1, count do
        body_reach = t20.entries[i]
        schema = body_reach.infos

        for j = 0, 32 do
            state = schema[j + 1]

            local v311, groups, v312
            local v313 = v270

            if state ~= nil and state.used then
                v311 = v304 + #p77.bodies
                state.label = v311
                groups = p77.groups
                v312 = if j < 7 then t20.board_group else t20.assembly_group
                groups[v311] = v312
                p77.actors[v311] = {
                    body_reach.peer,
                    j
                }
                cz = p77.bodies
                v305 = proxy_body(t20, body_reach, p81, p82, state)
                table.insert(cz, v305)
                v313 = v270 + 1
            end

            v270 = v313
        end
    end

    deferred_stats.bodies += v270

    for i = 1, n22 do
        v304 = t32[i]

        if v304.used then
            count = t27[i]
            count.body[1] = v304.label
            schema = p77.volumes
            table.insert(schema, count)
        end
    end

    for i = 1, v271 do
        p78[p84 + i].body_b[1] = t32[t33[i]].label
    end

    return v270 > 0
end

function t1.Proxies.resolve(p85, p86, p87, p88, p89, p90, p91) -- line: 1362
    -- upvalues: t1 (copy), t20 (copy), n15 (ref), t27 (copy), t32 (copy), t34 (copy), t35 (copy), t36 (copy), t37 (copy), resolve_inner (copy)
    if t20.owner ~= p85 or t20.count == 0 then
        return false
    end

    if t20.tick ~= p89.ticks then
        t20.count = 0

        return false
    end

    local v314 = #p86
    local v315 = #p85.bodies
    local ok, result = pcall(resolve_inner, p85, p86, p87, p88, p89, p90, p91, v314)

    table.clear(t27)
    table.clear(t32)
    table.clear(t34)
    table.clear(t35)
    table.clear(t36)
    table.clear(t37)

    for i = 1, #t20.entries do
        table.clear(t20.entries[i].infos)
    end

    if ok then
        return result
    end

    if n15 == 2 then
        error(result, 0)
    end

    for i = #p86, v314 + 1, -1 do
        p86[i] = nil
    end

    for i = #p85.bodies, v315 + 1, -1 do
        p85.bodies[i] = nil
    end

    table.clear(p85.volumes)
    table.clear(p85.groups)
    table.clear(p85.actors)
    t1.Proxies.deferred_error = tostring(result)

    return false
end

function t1.Proxies.capture_dynamics_reactions(p92, p93, p94) -- line: 1409
    -- upvalues: ATTACHED_REACTION_BASE (copy), xyz2 (copy)
    table.clear(p92.dynamics_deltas)

    if p94 == p94 and p94 ~= 1e999 and p94 ~= (-1e999) and p94 > 0 then
        for _, v316 in ipairs(p92.dynamics_before) do
            local v317 = v316[1]
            local v319 = p93[ATTACHED_REACTION_BASE + v316[2] + 1]

            if v319 ~= nil then
                local v320 = xyz2(v319.linear_displacement)
                local v321 = xyz2(v319.angular_displacement)

                table.insert(p92.dynamics_deltas, {
                    v317,
                    {
                        v320[1] / p94,
                        v320[2] / p94,
                        v320[3] / p94
                    },
                    {
                        v321[1] / p94,
                        v321[2] / p94,
                        v321[3] / p94
                    },
                    xyz2(v319.position_displacement),
                    xyz2(v319.orientation_displacement)
                })
            end
        end
    end
end

return t1
