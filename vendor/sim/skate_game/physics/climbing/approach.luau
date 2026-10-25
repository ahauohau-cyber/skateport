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
local v1 = import("skate_game/physics/climbing")
local v2 = import("skate_game/physics/climbing/clip")
local v3 = import("skate_game/physics/climbing/contacts")
local v4 = import("skate_game/physics/climbing/ledge")
local PhysicalStateId = import("skate_core/player/state").PhysicalStateId
local FootIkState = import("skate_core/animation/foot_ik/state").FootIkState
local State = import("skate_core/player/offboard/board_possession/manager").State
local Clip = v2.Clip
local Runtime, matrix, native, smooth = v1.Runtime, v1.matrix, v1.native, v1.smooth

local function player_state() -- line: 34
    -- upvalues: import (copy)
    return import("skate_game/physics/player_state")
end

local function solve() -- line: 37
    -- upvalues: import (copy)
    return import("skate_game/physics/solve")
end

local function air_selector() -- line: 40
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/air_selector")
end

local t1 = {}

local function glam_sub(p2, p3) -- line: 48
    return {
        p2[1] - p3[1],
        p2[2] - p3[2],
        p2[3] - p3[3]
    }
end

local function glam_scale(p4, p5) -- line: 51
    return {
        p4[1] * p5,
        p4[2] * p5,
        p4[3] * p5
    }
end

local function glam_dot(p6, p7) -- line: 54
    return p6[1] * p7[1] + p6[2] * p7[2] + p6[3] * p7[3]
end

local function glam_length(p8) -- line: 57
    return (math.sqrt(p8[1] * p8[1] + p8[2] * p8[2] + p8[3] * p8[3]))
end

local function glam_distance(p9, p10) -- line: 60
    local t2 = {
        p9[1] - p10[1],
        p9[2] - p10[2],
        p9[3] - p10[3]
    }

    return (math.sqrt(t2[1] * t2[1] + t2[2] * t2[2] + t2[3] * t2[3]))
end

local function glam_normalize_or_zero(p11) -- line: 64
    local v8 = 1 / math.sqrt(p11[1] * p11[1] + p11[2] * p11[2] + p11[3] * p11[3])

    if not (v8 == v8 and v8 ~= 1e999 and v8 ~= (-1e999) and v8 > 0) then
        return { 0, 0, 0 }
    end

    return {
        p11[1] * v8,
        p11[2] * v8,
        p11[3] * v8
    }
end

local function glam_quat_normalize(p12) -- line: 72
    local v10 = 1 / math.sqrt(p12[1] * p12[1] + p12[2] * p12[2] + p12[3] * p12[3] + p12[4] * p12[4])

    return {
        p12[1] * v10,
        p12[2] * v10,
        p12[3] * v10,
        p12[4] * v10
    }
end

local function glam_acos_approx(p13) -- line: 77
    local v11 = p13 >= 0
    local v12 = math.abs(p13)
    local v13 = 1 - v12

    if v13 < 0 then
        v13 = 0
    end

    local v14 = math.sqrt(v13)
    local v15 = (((((((v12 * -0.0012624911 + 0.00667009) * v12 - 0.017088126) * v12 + 0.03089188) * v12 - 0.050174303) * v12 + 0.08897899) * v12 - 0.2145988) * v12 + 1.5707963) * v14

    if v11 then
        return v15
    end

    return 3.141592653589793 - v15
end

local function glam_quat_slerp(p14, p15, p16) -- line: 100
    -- upvalues: rt (copy), glam_quat_normalize (copy)
    local v16 = p14[1] * p15[1] + p14[2] * p15[2] + p14[3] * p15[3] + p14[4] * p15[4]
    local v17 = p15[1]
    local v18 = p15[2]
    local v19 = p15[3]
    local v20 = p15[4]

    if v16 < 0 then
        v17 = -v17
        v18 = -v18
        v19 = -v19
        v20 = -v20
        v16 = -v16
    end

    if 1 - rt.F32_EPSILON < v16 then
        local v21 = 1 - p16

        return (glam_quat_normalize({
            p14[1] * v21 + v17 * p16,
            p14[2] * v21 + v18 * p16,
            p14[3] * v21 + v19 * p16,
            p14[4] * v21 + v20 * p16
        }))
    end

    local v22 = v16 >= 0
    local v23 = math.abs(v16)
    local v24 = 1 - v23

    if v24 < 0 then
        v24 = 0
    end

    local v25 = math.sqrt(v24)
    local v26 = (((((((v23 * -0.0012624911 + 0.00667009) * v23 - 0.017088126) * v23 + 0.03089188) * v23 - 0.050174303) * v23 + 0.08897899) * v23 - 0.2145988) * v23 + 1.5707963) * v25

    if not v22 then
        v26 = 3.141592653589793 - v26
    end

    local v28 = math.sin(v26 * (1 - p16))
    local v30 = math.sin(v26 * p16)
    local v31 = 1 / math.sin(v26)

    return {
        (p14[1] * v28 + v17 * v30) * v31,
        (p14[2] * v28 + v18 * v30) * v31,
        (p14[3] * v28 + v19 * v30) * v31,
        (p14[4] * v28 + v20 * v30) * v31
    }
end

local function glam_quat_from_rotation_axes(p17, p18, p19) -- line: 126
    local v32 = p17[1]
    local v33 = p17[2]
    local v34 = p17[3]
    local v35 = p18[1]
    local v36 = p18[2]
    local v37 = p18[3]
    local v38 = p19[1]
    local v39 = p19[2]
    local v40 = p19[3]

    if v40 <= 0 then
        local v41 = v36 - v32
        local v42 = 1 - v40

        if v41 <= 0 then
            local v43 = v42 - v41
            local v44 = 0.5 / math.sqrt(v43)

            return {
                v43 * v44,
                (v33 + v35) * v44,
                (v34 + v38) * v44,
                (v37 - v39) * v44
            }
        end

        local v45 = v42 + v41
        local v46 = 0.5 / math.sqrt(v45)

        return {
            (v33 + v35) * v46,
            v45 * v46,
            (v37 + v39) * v46,
            (v38 - v34) * v46
        }
    end

    local v47 = v36 + v32
    local v48 = 1 + v40

    if v47 <= 0 then
        local v49 = v48 - v47
        local v50 = 0.5 / math.sqrt(v49)

        return {
            (v34 + v38) * v50,
            (v37 + v39) * v50,
            v49 * v50,
            (v33 - v35) * v50
        }
    end

    local v51 = v48 + v47
    local v52 = 0.5 / math.sqrt(v51)

    return {
        (v37 - v39) * v52,
        (v38 - v34) * v52,
        (v33 - v35) * v52,
        v51 * v52
    }
end

local function glam_mat4_mul(p20, p21) -- line: 163
    local v53 = table.create(4)

    for i = 1, 4 do
        local v54 = p21[i]
        local v55 = v54[1]
        local v56 = v54[2]
        local v57 = v54[3]
        local v58 = v54[4]

        v53[i] = {
            p20[1][1] * v55 + p20[2][1] * v56 + p20[3][1] * v57 + p20[4][1] * v58,
            p20[1][2] * v55 + p20[2][2] * v56 + p20[3][2] * v57 + p20[4][2] * v58,
            p20[1][3] * v55 + p20[2][3] * v56 + p20[3][3] * v57 + p20[4][3] * v58,
            p20[1][4] * v55 + p20[2][4] * v56 + p20[3][4] * v57 + p20[4][4] * v58
        }
    end

    return v53
end

local function glam_mat4_inverse(p22) -- line: 179
    local v59 = p22[1][1]
    local v60 = p22[1][2]
    local v61 = p22[1][3]
    local v62 = p22[1][4]
    local v63 = p22[2][1]
    local v64 = p22[2][2]
    local v65 = p22[2][3]
    local v66 = p22[2][4]
    local v67 = p22[3][1]
    local v68 = p22[3][2]
    local v69 = p22[3][3]
    local v70 = p22[3][4]
    local v71 = p22[4][1]
    local v72 = p22[4][2]
    local v73 = p22[4][3]
    local v74 = p22[4][4]
    local v75 = v59 * v64 - v63 * v60
    local v76 = v59 * v65 - v63 * v61
    local v77 = v59 * v66 - v63 * v62
    local v78 = v60 * v65 - v64 * v61
    local v79 = v60 * v66 - v64 * v62
    local v80 = v61 * v66 - v65 * v62
    local v81 = v69 * v74 - v73 * v70
    local v82 = v68 * v74 - v72 * v70
    local v83 = v68 * v73 - v72 * v69
    local v84 = v67 * v74 - v71 * v70
    local v85 = v67 * v73 - v71 * v69
    local v86 = v67 * v72 - v71 * v68
    local v87 = v75 * v81 - v76 * v82 + v77 * v83 + v78 * v84 - v79 * v85 + v80 * v86
    local v88 = 1 / v87

    return {
        {
            (v64 * v81 - v65 * v82 + v66 * v83) * v88,
            (-v60 * v81 + v61 * v82 - v62 * v83) * v88,
            (v72 * v80 - v73 * v79 + v74 * v78) * v88,
            (-v68 * v80 + v69 * v79 - v70 * v78) * v88
        },
        {
            (-v63 * v81 + v65 * v84 - v66 * v85) * v88,
            (v59 * v81 - v61 * v84 + v62 * v85) * v88,
            (-v71 * v80 + v73 * v77 - v74 * v76) * v88,
            (v67 * v80 - v69 * v77 + v70 * v76) * v88
        },
        {
            (v63 * v82 - v64 * v84 + v66 * v86) * v88,
            (-v59 * v82 + v60 * v84 - v62 * v86) * v88,
            (v71 * v79 - v72 * v77 + v74 * v75) * v88,
            (-v67 * v79 + v68 * v77 - v70 * v75) * v88
        },
        {
            (-v63 * v83 + v64 * v85 - v65 * v86) * v88,
            (v59 * v83 - v60 * v85 + v61 * v86) * v88,
            (-v71 * v78 + v72 * v76 - v73 * v75) * v88,
            (v67 * v78 - v68 * v76 + v69 * v75) * v88
        }
    }, v87
end

local function glam_mat4_transform_point3(p23, p24) -- line: 227
    return {
        p23[1][1] * p24[1] + p23[2][1] * p24[2] + p23[3][1] * p24[3] + p23[4][1],
        p23[1][2] * p24[1] + p23[2][2] * p24[2] + p23[3][2] * p24[3] + p23[4][2],
        p23[1][3] * p24[1] + p23[2][3] * p24[2] + p23[3][3] * p24[3] + p23[4][3]
    }
end

local function glam_w_axis(p25) -- line: 235
    return {
        p25[4][1],
        p25[4][2],
        p25[4][3]
    }
end

local function glam_transform_from_matrix(p26) -- line: 239
    -- upvalues: rt (copy), glam_quat_from_rotation_axes (copy), glam_mat4_inverse (copy)
    local _, v89 = glam_mat4_inverse(p26)
    local v90 = p26[1]
    local v91 = p26[2]
    local v92 = p26[3]
    local v94 = math.sqrt(v90[1] * v90[1] + v90[2] * v90[2] + v90[3] * v90[3] + v90[4] * v90[4]) * rt.signum(v89)
    local v96 = math.sqrt(v91[1] * v91[1] + v91[2] * v91[2] + v91[3] * v91[3] + v91[4] * v91[4])
    local v98 = math.sqrt(v92[1] * v92[1] + v92[2] * v92[2] + v92[3] * v92[3] + v92[4] * v92[4])
    local v99 = 1 / v94
    local v100 = 1 / v96
    local v101 = 1 / v98
    local v102 = glam_quat_from_rotation_axes({
        v90[1] * v99,
        v90[2] * v99,
        v90[3] * v99
    }, {
        v91[1] * v100,
        v91[2] * v100,
        v91[3] * v100
    }, {
        v92[1] * v101,
        v92[2] * v101,
        v92[3] * v101
    })

    return {
        translation = {
            p26[4][1],
            p26[4][2],
            p26[4][3]
        },
        rotation = v102,
        scale = { v94, v96, v98 }
    }
end

t1.Approach = {}

local update, reach_gain

function t1.advance(p27, p28, p29) -- line: 270
    -- upvalues: t1 (copy)
    if p28.climbing.clips == nil then
        return
    end

    return t1.advance_reference(p27, p28, p29)
end

function t1.advance_reference(p30, p31, p32) -- line: 278
    -- upvalues: Runtime (copy), update (ref)
    local climbing = p31.climbing

    p31.climbing = Runtime.default()
    update(climbing, p30, p31, p32)
    p31.climbing = climbing
end

function t1.update(p33, p34, p35, p36) -- line: 287
    -- upvalues: rt (copy), import (copy), v3 (copy), v4 (copy), PhysicalStateId (copy), FootIkState (copy), State (copy), Clip (copy), matrix (copy), native (copy), glam_normalize_or_zero (copy), glam_quat_slerp (copy), glam_mat4_mul (copy), glam_mat4_inverse (copy), glam_mat4_transform_point3 (copy), glam_transform_from_matrix (copy), reach_gain (ref)
    local clips = p33.clips

    if clips == nil then
        return
    end

    local reach = clips.reach
    local v103 = matrix(p35.animated_skeleton.roots.animation_to_world)
    local v104 = table.create(#p33.indices)

    for v105, v106 in ipairs(p33.indices) do
        v104[v105] = matrix(p35.render_pose[v106 + 1])
    end

    local v107 = table.create(#v104)

    for i = 0, #v104 - 1 do
        local v108 = v104[i + 1]

        if reach.parents[i + 1] < 0 then
            v107[i + 1] = glam_transform_from_matrix(v108)
        else
            v107[i + 1] = glam_transform_from_matrix((glam_mat4_mul(glam_mat4_inverse(v104[reach.parents[i + 1] + 1]), v108)))
        end
    end

    local v109 = import("skate_game/physics/player_state").PlayerState.current(p35.player_state)
    local v110 = rt.map(p35.player_input.physical.reckoning.vector_16, rt.from_bits)
    local t3 = {
        v110[1],
        v110[2],
        v110[3]
    }
    local v112 = math.sqrt(t3[1] * t3[1] + t3[2] * t3[2] + t3[3] * t3[3])

    if v109 == PhysicalStateId.BipedGround and (#p33.ground_entry == 0 or v112 < 0.3) then
        p33.ground_entry = rt.copy(v107)

        local v113 = Clip.feet(reach, v104)[2]

        for i = 0, #p33.ground_entry - 1 do
            local v114 = p33.ground_entry[i + 1]

            if reach.parents[i + 1] < 0 then
                v114.translation[2] -= v113
            end
        end
    end

    local v115 = v109 == PhysicalStateId.BipedAir

    if not v115 and v109 ~= PhysicalStateId.BipedGround or p33.cooldown > 0 then
        p33.approach = nil

        return
    end

    local v116 = glam_mat4_transform_point3(v103, Clip.feet(reach, v104))
    local v117 = rt.map(p35.player_input.physical.reckoning.vector_16, rt.from_bits)
    local t4 = {
        v117[1],
        v117[2],
        v117[3]
    }
    local offboard_direction = p36.offboard_direction
    local t5

    if offboard_direction ~= nil then
        t5 = {
            offboard_direction[1],
            0,
            offboard_direction[3]
        }

        if not (t5[1] * t5[1] + t5[2] * t5[2] + t5[3] * t5[3] > 0.04) then
            t5 = nil
        end
    end

    if t5 == nil then
        local t6 = {
            v103[3][1],
            v103[3][2],
            v103[3][3]
        }
        local v118 = if bit32.band(p35.player_input.processed.flags_2476, 4) == 0 then 1 else -1

        t5 = {
            t6[1] * v118,
            t6[2] * v118,
            t6[3] * v118
        }
    end

    local v119 = v115 or v112 > 0.15 or offboard_direction ~= nil and offboard_direction[1] * offboard_direction[1] + offboard_direction[3] * offboard_direction[3] > 0.04
    local v120 = if v119 then v4.find_air(p34.world, v116, t5) else nil

    if not v115 then
        local approach = p33.approach

        if approach ~= nil and v120 ~= nil then
            local anchor = approach.ledge.anchor
            local anchor2 = v120.anchor
            local t7 = {
                anchor[1] - anchor2[1],
                anchor[2] - anchor2[2],
                anchor[3] - anchor2[3]
            }

            if math.sqrt(t7[1] * t7[1] + t7[2] * t7[2] + t7[3] * t7[3]) < 0.5 then
                approach.ledge = rt.copy(v120)
            end
        end
    end

    if p33.approach == nil and v120 ~= nil then
        local forward = v120.forward

        if t4[1] * forward[1] + t4[2] * forward[2] + t4[3] * forward[3] >= -0.1 then
            p33.approach = {
                weight = 0,
                ledge = rt.copy(v120)
            }
        end
    end

    local approach = p33.approach

    if approach ~= nil then
        local anchor = approach.ledge.anchor
        local t8 = {
            anchor[1] - v116[1],
            anchor[2] - v116[2],
            anchor[3] - v116[3]
        }
        local v123 = math.sqrt(t8[1] * t8[1] + t8[3] * t8[3])
        local v124

        if v119 then
            v124 = false

            if t8[2] > 0.35 and t8[2] < 2.75 and v123 < 2.7 then
                local forward = approach.ledge.forward

                if t8[1] * forward[1] + t8[2] * forward[2] + t8[3] * forward[3] > 0 then
                    local v125 = glam_normalize_or_zero(t5)
                    local forward = approach.ledge.forward

                    if v125[1] * forward[1] + v125[2] * forward[2] + v125[3] * forward[3] > 0.65 then
                        local forward = approach.ledge.forward

                        if t4[1] * forward[1] + t4[2] * forward[2] + t4[3] * forward[3] >= -0.3 then
                            v124 = v4.clear(p34.world, approach.ledge)
                        end
                    end
                end
            end
        else
            v124 = v119
        end

        local time_step = p34.settings.step.simulation.time_step
        local v126 = if v124 then reach_gain(v123, v115) else 0

        approach.weight = approach.weight + (v126 - approach.weight) * (1 - math.exp(-time_step / 0.1))

        if not (approach.weight < 0.001) or v124 then
            local weight = approach.weight
            local v129 = Clip.sample(reach, Clip.duration(reach))

            for _, v130 in ipairs({ "LEFT", "RIGHT" }) do
                for _, v131 in ipairs({ "SHOULDER", "ARM", "FOREARM", "HAND" }) do
                    local v132 = Clip.index(reach, v130 .. v131)

                    v107[v132 + 1].rotation = glam_quat_slerp(v107[v132 + 1].rotation, v129[v132 + 1].rotation, weight * 0.75)
                end
            end

            local v133 = Clip.globals(reach, v107)
            local v134 = true

            for v135, v136 in ipairs({ "LEFT", "RIGHT" }) do
                local v137 = v135 - 1
                local v138 = v133[Clip.index(reach, v136 .. "ARM") + 1]
                local v139 = glam_mat4_transform_point3(v103, {
                    v138[4][1],
                    v138[4][2],
                    v138[4][3]
                })
                local v140 = v133[Clip.index(reach, v136 .. "FOREARM") + 1]
                local v141 = glam_mat4_transform_point3(v103, {
                    v140[4][1],
                    v140[4][2],
                    v140[4][3]
                })
                local v142 = v133[Clip.index(reach, v136 .. "HAND") + 1]
                local v143 = glam_mat4_transform_point3(v103, {
                    v142[4][1],
                    v142[4][2],
                    v142[4][3]
                })
                local v144 = v3.wrist(approach.ledge, v137)
                local t9 = {
                    v139[1] - v144[1],
                    v139[2] - v144[2],
                    v139[3] - v144[3]
                }
                local v146 = math.sqrt(t9[1] * t9[1] + t9[2] * t9[2] + t9[3] * t9[3])
                local t10 = {
                    v139[1] - v141[1],
                    v139[2] - v141[2],
                    v139[3] - v141[3]
                }
                local v148 = math.sqrt(t10[1] * t10[1] + t10[2] * t10[2] + t10[3] * t10[3])
                local t11 = {
                    v141[1] - v143[1],
                    v141[2] - v143[2],
                    v141[3] - v143[3]
                }

                if not (v146 <= v148 + math.sqrt(t11[1] * t11[1] + t11[2] * t11[2] + t11[3] * t11[3]) - 0.015) then
                    v134 = false
                    break
                end
            end

            v3.hands(reach, v107, v103, approach.ledge, weight)

            local v150 = Clip.globals(reach, v107)

            for i = 1, math.min(#p33.indices, #v150) do
                p35.render_pose[p33.indices[i] + 1] = native(v150[i])
            end

            local t12, v153

            if v115 and v124 and v134 and approach.weight >= 0.95 and #p33.ground_entry ~= 0 then
                local v154 = matrix(import("skate_game/physics/solve").deck_frame(p34.board))

                t12 = {
                    phase = "Catch",
                    time = 0,
                    ledge = rt.copy(approach.ledge),
                    start_root = glam_transform_from_matrix(v103),
                    entry = v107,
                    fallback = rt.copy(p35.render_pose),
                    board_world = glam_mat4_mul(v103, v150[Clip.index(reach, "SKATEBOARD_ROOT") + 1]),
                    physical_board_world = v154
                }
                v153 = p35.skateboard_controller.fields.state_448 == 1
                t12.carry_board = v153
                p33.active = t12
                p33.approach = nil
                import("skate_game/physics/offboard/air_selector").AirSelector.reset(p35.offboard_air_selector)
                State.reset(p35.offboard_feet)
                FootIkState.enable_feet(p35.foot_ik.state, false)
            end
        else
            p33.approach = nil
        end
    end
end

update = t1.update

function t1.reach_gain(p37, p38) -- line: 456
    -- upvalues: smooth (copy)
    return smooth((2.6 - p37) / 1.8) * (if p38 then 1 else 0.45)
end

reach_gain = t1.reach_gain

return t1
