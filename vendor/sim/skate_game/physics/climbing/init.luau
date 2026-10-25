-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_from_bits(p1) -- line: 7
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p1)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local v2 = import("skate_game/physics/climbing/clip")
local v3 = import("skate_game/physics/climbing/contacts")
local v4 = import("skate_game/physics/climbing/ledge")
local Vector3 = import("skate_core/math").Vector3
local map_animation_parts, SkeletonAnimationRecord = import("skate_core/physics/skeleton_animation_record").map_animation_parts, import("skate_core/physics/skeleton_animation_record").SkeletonAnimationRecord
local SkeletonBoardFrames = import("skate_core/physics/skeleton_board_frames").SkeletonBoardFrames
local v5 = import("skate_core/physics/skeleton_body")
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime
local BoardWorld = import("skate_core/physics/board_world").BoardWorld
local CentreOfMassFilter = import("skate_core/physics/centre_of_mass_filter").CentreOfMassFilter
local CorrectionState = import("skate_core/physics/skeleton_output/correction").CorrectionState
local DerivedControllerInput = import("skate_core/input/controller").DerivedControllerInput
local Clip, Clips, blend = v2.Clip, v2.Clips, v2.blend
local SkeletonBody, SkeletonTargets, SkeletonPoseErrors = v5.SkeletonBody, v5.SkeletonTargets, v5.SkeletonPoseErrors

local function animation() -- line: 52
    -- upvalues: import (copy)
    return import("skate_game/animation")
end

local function player_input() -- line: 55
    -- upvalues: import (copy)
    return import("skate_game/physics/player_input")
end

local function riding_outputs() -- line: 58
    -- upvalues: import (copy)
    return import("skate_game/physics/riding_outputs")
end

local function colliders() -- line: 61
    -- upvalues: import (copy)
    return import("skate_game/physics/colliders")
end

local function solve() -- line: 64
    -- upvalues: import (copy)
    return import("skate_game/physics/solve")
end

local function camera_output() -- line: 67
    -- upvalues: import (copy)
    return import("skate_game/physics/camera_output")
end

local function clock() -- line: 70
    -- upvalues: import (copy)
    return import("skate_game/physics/clock")
end

local function player_state() -- line: 73
    -- upvalues: import (copy)
    return import("skate_game/physics/player_state")
end

local t1 = {}
local t2 = {
    1, 1, 1
}

local function glam_add(p2, p3) -- line: 83
    return {
        p2[1] + p3[1],
        p2[2] + p3[2],
        p2[3] + p3[3]
    }
end

local function glam_sub(p4, p5) -- line: 86
    return {
        p4[1] - p5[1],
        p4[2] - p5[2],
        p4[3] - p5[3]
    }
end

local function glam_scale(p6, p7) -- line: 89
    return {
        p6[1] * p7,
        p6[2] * p7,
        p6[3] * p7
    }
end

local function glam_neg(p8) -- line: 92
    return {
        -p8[1],
        -p8[2],
        -p8[3]
    }
end

local function glam_dot(p9, p10) -- line: 95
    return p9[1] * p10[1] + p9[2] * p10[2] + p9[3] * p10[3]
end

local function glam_cross(p11, p12) -- line: 98
    return {
        p11[2] * p12[3] - p12[2] * p11[3],
        p11[3] * p12[1] - p12[3] * p11[1],
        p11[1] * p12[2] - p12[1] * p11[2]
    }
end

local function glam_length(p13) -- line: 105
    return (math.sqrt(p13[1] * p13[1] + p13[2] * p13[2] + p13[3] * p13[3]))
end

local function glam_distance(p14, p15) -- line: 108
    local t3 = {
        p14[1] - p15[1],
        p14[2] - p15[2],
        p14[3] - p15[3]
    }

    return (math.sqrt(t3[1] * t3[1] + t3[2] * t3[2] + t3[3] * t3[3]))
end

local function glam_lerp(p16, p17, p18) -- line: 112
    local v8 = 1 - p18

    return {
        p16[1] * v8 + p17[1] * p18,
        p16[2] * v8 + p17[2] * p18,
        p16[3] * v8 + p17[3] * p18
    }
end

local function glam_normalize(p19) -- line: 117
    local v10 = 1 / math.sqrt(p19[1] * p19[1] + p19[2] * p19[2] + p19[3] * p19[3])

    return {
        p19[1] * v10,
        p19[2] * v10,
        p19[3] * v10
    }
end

local function glam_quat_from_rotation_y(p20) -- line: 122
    return {
        0,
        math.sin(p20 * 0.5),
        0,
        (math.cos(p20 * 0.5))
    }
end

local function glam_quat_mul_vec3(p21, p22) -- line: 127
    -- upvalues: glam_cross (copy)
    local v14 = p21[4]
    local t4 = {
        p21[1],
        p21[2],
        p21[3]
    }
    local v15 = t4[1] * t4[1] + t4[2] * t4[2] + t4[3] * t4[3]
    local v16 = v14 * v14 - v15
    local t5 = {
        p22[1] * v16,
        p22[2] * v16,
        p22[3] * v16
    }
    local v17 = (p22[1] * t4[1] + p22[2] * t4[2] + p22[3] * t4[3]) * 2
    local t6 = {
        t4[1] * v17,
        t4[2] * v17,
        t4[3] * v17
    }
    local t7 = {
        t5[1] + t6[1],
        t5[2] + t6[2],
        t5[3] + t6[3]
    }
    local v18 = glam_cross(t4, p22)
    local v19 = v14 * 2
    local t8 = {
        v18[1] * v19,
        v18[2] * v19,
        v18[3] * v19
    }

    return {
        t7[1] + t8[1],
        t7[2] + t8[2],
        t7[3] + t8[3]
    }
end

local function glam_quat_normalize(p23) -- line: 137
    local v21 = 1 / math.sqrt(p23[1] * p23[1] + p23[2] * p23[2] + p23[3] * p23[3] + p23[4] * p23[4])

    return {
        p23[1] * v21,
        p23[2] * v21,
        p23[3] * v21,
        p23[4] * v21
    }
end

local function glam_acos_approx(p24) -- line: 142
    local v22 = p24 >= 0
    local v23 = math.abs(p24)
    local v24 = 1 - v23

    if v24 < 0 then
        v24 = 0
    end

    local v25 = math.sqrt(v24)
    local v26 = (((((((v23 * -0.0012624911 + 0.00667009) * v23 - 0.017088126) * v23 + 0.03089188) * v23 - 0.050174303) * v23 + 0.08897899) * v23 - 0.2145988) * v23 + 1.5707963) * v25

    if v22 then
        return v26
    end

    return 3.141592653589793 - v26
end

local function glam_quat_slerp(p25, p26, p27) -- line: 165
    -- upvalues: rt (copy), glam_quat_normalize (copy)
    local v27 = p25[1] * p26[1] + p25[2] * p26[2] + p25[3] * p26[3] + p25[4] * p26[4]
    local v28 = p26[1]
    local v29 = p26[2]
    local v30 = p26[3]
    local v31 = p26[4]

    if v27 < 0 then
        v28 = -v28
        v29 = -v29
        v30 = -v30
        v31 = -v31
        v27 = -v27
    end

    if 1 - rt.F32_EPSILON < v27 then
        local v32 = 1 - p27

        return (glam_quat_normalize({
            p25[1] * v32 + v28 * p27,
            p25[2] * v32 + v29 * p27,
            p25[3] * v32 + v30 * p27,
            p25[4] * v32 + v31 * p27
        }))
    end

    local v33 = v27 >= 0
    local v34 = math.abs(v27)
    local v35 = 1 - v34

    if v35 < 0 then
        v35 = 0
    end

    local v36 = math.sqrt(v35)
    local v37 = (((((((v34 * -0.0012624911 + 0.00667009) * v34 - 0.017088126) * v34 + 0.03089188) * v34 - 0.050174303) * v34 + 0.08897899) * v34 - 0.2145988) * v34 + 1.5707963) * v36

    if not v33 then
        v37 = 3.141592653589793 - v37
    end

    local v39 = math.sin(v37 * (1 - p27))
    local v41 = math.sin(v37 * p27)
    local v42 = 1 / math.sin(v37)

    return {
        (p25[1] * v39 + v28 * v41) * v42,
        (p25[2] * v39 + v29 * v41) * v42,
        (p25[3] * v39 + v30 * v41) * v42,
        (p25[4] * v39 + v31 * v41) * v42
    }
end

local function glam_quat_from_rotation_axes(p28, p29, p30) -- line: 191
    local v43 = p28[1]
    local v44 = p28[2]
    local v45 = p28[3]
    local v46 = p29[1]
    local v47 = p29[2]
    local v48 = p29[3]
    local v49 = p30[1]
    local v50 = p30[2]
    local v51 = p30[3]

    if v51 <= 0 then
        local v52 = v47 - v43
        local v53 = 1 - v51

        if v52 <= 0 then
            local v54 = v53 - v52
            local v55 = 0.5 / math.sqrt(v54)

            return {
                v54 * v55,
                (v44 + v46) * v55,
                (v45 + v49) * v55,
                (v48 - v50) * v55
            }
        end

        local v56 = v53 + v52
        local v57 = 0.5 / math.sqrt(v56)

        return {
            (v44 + v46) * v57,
            v56 * v57,
            (v48 + v50) * v57,
            (v49 - v45) * v57
        }
    end

    local v58 = v47 + v43
    local v59 = 1 + v51

    if v58 <= 0 then
        local v60 = v59 - v58
        local v61 = 0.5 / math.sqrt(v60)

        return {
            (v45 + v49) * v61,
            (v48 + v50) * v61,
            v60 * v61,
            (v44 - v46) * v61
        }
    end

    local v62 = v59 + v58
    local v63 = 0.5 / math.sqrt(v62)

    return {
        (v48 - v50) * v63,
        (v49 - v45) * v63,
        (v44 - v46) * v63,
        v62 * v63
    }
end

local function glam_mat4_mul(p31, p32) -- line: 229
    local v64 = table.create(4)

    for i = 1, 4 do
        local v65 = p32[i]
        local v66 = v65[1]
        local v67 = v65[2]
        local v68 = v65[3]
        local v69 = v65[4]

        v64[i] = {
            p31[1][1] * v66 + p31[2][1] * v67 + p31[3][1] * v68 + p31[4][1] * v69,
            p31[1][2] * v66 + p31[2][2] * v67 + p31[3][2] * v68 + p31[4][2] * v69,
            p31[1][3] * v66 + p31[2][3] * v67 + p31[3][3] * v68 + p31[4][3] * v69,
            p31[1][4] * v66 + p31[2][4] * v67 + p31[3][4] * v68 + p31[4][4] * v69
        }
    end

    return v64
end

local function glam_mat4_inverse(p33) -- line: 245
    local v70 = p33[1][1]
    local v71 = p33[1][2]
    local v72 = p33[1][3]
    local v73 = p33[1][4]
    local v74 = p33[2][1]
    local v75 = p33[2][2]
    local v76 = p33[2][3]
    local v77 = p33[2][4]
    local v78 = p33[3][1]
    local v79 = p33[3][2]
    local v80 = p33[3][3]
    local v81 = p33[3][4]
    local v82 = p33[4][1]
    local v83 = p33[4][2]
    local v84 = p33[4][3]
    local v85 = p33[4][4]
    local v86 = v70 * v75 - v74 * v71
    local v87 = v70 * v76 - v74 * v72
    local v88 = v70 * v77 - v74 * v73
    local v89 = v71 * v76 - v75 * v72
    local v90 = v71 * v77 - v75 * v73
    local v91 = v72 * v77 - v76 * v73
    local v92 = v80 * v85 - v84 * v81
    local v93 = v79 * v85 - v83 * v81
    local v94 = v79 * v84 - v83 * v80
    local v95 = v78 * v85 - v82 * v81
    local v96 = v78 * v84 - v82 * v80
    local v97 = v78 * v83 - v82 * v79
    local v98 = v86 * v92 - v87 * v93 + v88 * v94 + v89 * v95 - v90 * v96 + v91 * v97
    local v99 = 1 / v98

    return {
        {
            (v75 * v92 - v76 * v93 + v77 * v94) * v99,
            (-v71 * v92 + v72 * v93 - v73 * v94) * v99,
            (v83 * v91 - v84 * v90 + v85 * v89) * v99,
            (-v79 * v91 + v80 * v90 - v81 * v89) * v99
        },
        {
            (-v74 * v92 + v76 * v95 - v77 * v96) * v99,
            (v70 * v92 - v72 * v95 + v73 * v96) * v99,
            (-v82 * v91 + v84 * v88 - v85 * v87) * v99,
            (v78 * v91 - v80 * v88 + v81 * v87) * v99
        },
        {
            (v74 * v93 - v75 * v95 + v77 * v97) * v99,
            (-v70 * v93 + v71 * v95 - v73 * v97) * v99,
            (v82 * v90 - v83 * v88 + v85 * v86) * v99,
            (-v78 * v90 + v79 * v88 - v81 * v86) * v99
        },
        {
            (-v74 * v94 + v75 * v96 - v76 * v97) * v99,
            (v70 * v94 - v71 * v96 + v72 * v97) * v99,
            (-v82 * v89 + v83 * v87 - v84 * v86) * v99,
            (v78 * v89 - v79 * v87 + v80 * v86) * v99
        }
    }, v98
end

local function glam_mat4_transform_point3(p34, p35) -- line: 293
    return {
        p34[1][1] * p35[1] + p34[2][1] * p35[2] + p34[3][1] * p35[3] + p34[4][1],
        p34[1][2] * p35[1] + p34[2][2] * p35[2] + p34[3][2] * p35[3] + p34[4][2],
        p34[1][3] * p35[1] + p34[2][3] * p35[2] + p34[3][3] * p35[3] + p34[4][3]
    }
end

local function glam_mat4_transform_vector3(p36, p37) -- line: 301
    return {
        p36[1][1] * p37[1] + p36[2][1] * p37[2] + p36[3][1] * p37[3],
        p36[1][2] * p37[1] + p36[2][2] * p37[2] + p36[3][2] * p37[3],
        p36[1][3] * p37[1] + p36[2][3] * p37[2] + p36[3][3] * p37[3]
    }
end

local function glam_w_axis(p38) -- line: 309
    return {
        p38[4][1],
        p38[4][2],
        p38[4][3]
    }
end

local function glam_transform_from_matrix(p39) -- line: 313
    -- upvalues: rt (copy), glam_quat_from_rotation_axes (copy), glam_mat4_inverse (copy)
    local _, v100 = glam_mat4_inverse(p39)
    local v101 = p39[1]
    local v102 = p39[2]
    local v103 = p39[3]
    local v105 = math.sqrt(v101[1] * v101[1] + v101[2] * v101[2] + v101[3] * v101[3] + v101[4] * v101[4]) * rt.signum(v100)
    local v107 = math.sqrt(v102[1] * v102[1] + v102[2] * v102[2] + v102[3] * v102[3] + v102[4] * v102[4])
    local v109 = math.sqrt(v103[1] * v103[1] + v103[2] * v103[2] + v103[3] * v103[3] + v103[4] * v103[4])
    local v110 = 1 / v105
    local v111 = 1 / v107
    local v112 = 1 / v109
    local v113 = glam_quat_from_rotation_axes({
        v101[1] * v110,
        v101[2] * v110,
        v101[3] * v110
    }, {
        v102[1] * v111,
        v102[2] * v111,
        v102[3] * v111
    }, {
        v103[1] * v112,
        v103[2] * v112,
        v103[3] * v112
    })

    return {
        translation = {
            p39[4][1],
            p39[4][2],
            p39[4][3]
        },
        rotation = v113,
        scale = { v105, v107, v109 }
    }
end

local function glam_transform_to_matrix(p40) -- line: 332
    local rotation = p40.rotation
    local v114 = rotation[1]
    local v115 = rotation[2]
    local v116 = rotation[3]
    local v117 = rotation[4]
    local v118 = v114 + v114
    local v119 = v115 + v115
    local v120 = v116 + v116
    local v121 = v114 * v118
    local v122 = v114 * v119
    local v123 = v114 * v120
    local v124 = v115 * v119
    local v125 = v115 * v120
    local v126 = v116 * v120
    local v127 = v117 * v118
    local v128 = v117 * v119
    local v129 = v117 * v120
    local v130 = p40.scale[1]
    local v131 = p40.scale[2]
    local v132 = p40.scale[3]
    local translation = p40.translation

    return {
        {
            (1 - (v124 + v126)) * v130,
            (v122 + v129) * v130,
            (v123 - v128) * v130,
            0 * v130
        },
        {
            (v122 - v129) * v131,
            (1 - (v121 + v126)) * v131,
            (v125 + v127) * v131,
            0 * v131
        },
        {
            (v123 + v128) * v132,
            (v125 - v127) * v132,
            (1 - (v121 + v124)) * v132,
            0 * v132
        },
        {
            translation[1],
            translation[2],
            translation[3],
            1
        }
    }
end

local function glam_transform(p41, p42) -- line: 357
    -- upvalues: rt (copy), t2 (copy)
    return {
        translation = p41,
        rotation = p42,
        scale = rt.copy(t2)
    }
end

t1.Runtime = {}

local Runtime = t1.Runtime

function t1.Runtime.default() -- line: 373
    return {
        clips = nil,
        active = nil,
        cooldown = 0,
        approach = nil,
        indices = {},
        ground_entry = {}
    }
end

t1.Phase = {
    Catch = "Catch",
    Hang = "Hang",
    Mantle = "Mantle",
    Settle = "Settle"
}
t1.Attached = {}

function t1.Runtime.load(p43, p44, p45) -- line: 396
    -- upvalues: Clips (copy), Runtime (copy)
    local v133 = Clips.load(p43, p45)
    local t9 = {}

    if v133 ~= nil then
        for v134, v135 in ipairs(v133.reach.names) do
            local v136

            for v137, v138 in ipairs(p44) do
                if string.lower(v138) == string.lower(v135) then
                    v136 = v137 - 1
                    break
                end
            end

            if v136 == nil then
                error(("Climbing rig bone %* missing from skater"):format(v135), 0)
            end

            t9[v134] = v136
        end
    end

    local v139 = Runtime.default()

    v139.clips = v133
    v139.indices = t9

    return v139
end

function t1.matrix(p46) -- line: 422
    -- upvalues: import (copy)
    return import("skate_game/animation").native_matrix(p46)
end

local matrix = t1.matrix

function t1.native(p47) -- line: 428
    -- upvalues: rt (copy)
    local v140 = rt.copy(p47)

    v140[4][4] = 0

    return v140
end

local native = t1.native

function t1.point(p48) -- line: 438
    return {
        p48[1],
        p48[2],
        p48[3],
        0
    }
end

local point2 = t1.point

function t1.smooth(p49) -- line: 444
    -- upvalues: rt (copy)
    local v141 = rt.clamp(p49, 0, 1)

    return v141 * v141 * (3 - v141 * 2)
end

local smooth = t1.smooth

function t1.pressed(p50, p51) -- line: 451
    -- upvalues: DerivedControllerInput (copy)
    local v142 = DerivedControllerInput.words(p50.controller)

    if bit32.band(v142[14], (bit32.lshift(1, p51))) == 0 then
        return false
    end

    return bit32.band(v142[7], (bit32.lshift(1, p51))) == 0
end

local pressed = t1.pressed
local zero_rates, publish_pose

function t1.advance(p52, p53, p54, p55) -- line: 470
    -- upvalues: t1 (copy), Runtime (copy)
    if p53.climbing.clips == nil then
        return Runtime.advance(p53.climbing, p52, p53, p54, p55)
    end

    return t1.advance_reference(p52, p53, p54, p55)
end

function t1.advance_reference(p56, p57, p58, p59) -- line: 478
    -- upvalues: Runtime (copy)
    local climbing = p57.climbing

    p57.climbing = Runtime.default()

    local advance = Runtime.advance
    local ok, result = pcall(advance, climbing, p56, p57, p58, p59)

    p57.climbing = climbing

    if not ok then
        error(result, 0)
    end

    return result
end

function t1.Runtime.advance(p60, p61, p62, p63, p64) -- line: 492
    -- upvalues: rt (copy), v1 (copy), import (copy), v3 (copy), v4 (copy), Vector3 (copy), BoardRuntime (copy), BoardWorld (copy), DerivedControllerInput (copy), Clip (copy), blend (copy), t2 (copy), glam_cross (copy), glam_lerp (copy), glam_quat_mul_vec3 (copy), glam_quat_slerp (copy), glam_quat_from_rotation_axes (copy), glam_mat4_mul (copy), glam_mat4_inverse (copy), glam_mat4_transform_point3 (copy), glam_mat4_transform_vector3 (copy), glam_transform_from_matrix (copy), glam_transform_to_matrix (copy), matrix (copy), native (copy), smooth (copy), pressed (copy), zero_rates (ref), publish_pose (ref)
    local time_step = p61.settings.step.simulation.time_step

    if import("skate_game/physics/player_input").PlayerInputRuntime.pending_teleport(p62.player_input) == nil then
        p60.cooldown = rt.fmax(p60.cooldown - time_step, 0)

        local clips = p60.clips

        if clips == nil then
            return false
        end

        local reach = clips.reach

        if p60.active == nil then
            return false
        end

        local active = p60.active

        if active.phase == "Hang" and pressed(p63, 23) and v4.clear(p61.world, active.ledge) then
            active.phase = "Mantle"
            active.time = 0
        end

        active.time += time_step

        local v149 = math.atan2(active.ledge.forward[1], active.ledge.forward[3])
        local t10 = {
            0,
            math.sin(v149 * 0.5),
            0,
            (math.cos(v149 * 0.5))
        }
        local v153 = Clip.sample(reach, Clip.duration(reach))
        local v154 = Clip.globals(reach, v153)
        local anchor = active.ledge.anchor
        local v155 = glam_quat_mul_vec3(t10, Clip.hands(reach, v154))
        local t11 = {
            anchor[1] - v155[1],
            anchor[2] - v155[2],
            anchor[3] - v155[3]
        }
        local v156 = glam_quat_mul_vec3(t10, v3.clearance(reach, v154))
        local t12 = {
            t11[1] + v156[1],
            t11[2] + v156[2],
            t11[3] + v156[3]
        }
        local mantle = clips.mantle
        local v157 = Clip.sample(mantle, Clip.duration(mantle))
        local phase, time = active.phase, active.time
        local v158, t13, v159

        if active.phase == "Catch" then
            local fmin = rt.fmin
            local translation = active.start_root.translation
            local t14 = {
                translation[1] - t12[1],
                translation[2] - t12[2],
                translation[3] - t12[3]
            }
            local v161 = fmin(math.sqrt(t14[1] * t14[1] + t14[2] * t14[2] + t14[3] * t14[3]) * 0.18 + 0.22, 0.5)
            local v162 = rt.fmin(active.time / v161, 1)

            v158 = rt.copy(v153)

            local v163 = smooth(v162)

            for i = 1, math.min(#v158, #active.entry) do
                v158[i] = blend(active.entry[i], v158[i], v163)
            end

            t13 = {
                translation = glam_lerp(active.start_root.translation, t12, v163),
                rotation = glam_quat_slerp(active.start_root.rotation, t10, v163),
                scale = rt.copy(t2)
            }

            if v162 >= 1 then
                active.phase = "Hang"
                active.time = 0
            end

            v159 = false
        elseif active.phase == "Hang" then
            v159 = false
            v158 = rt.copy(v153)
            t13 = {
                translation = t12,
                rotation = rt.copy(t10),
                scale = rt.copy(t2)
            }
        elseif active.phase == "Mantle" then
            v158 = Clip.sample(mantle, active.time)

            for i = 1, math.min(#v158, #v153) do
                v158[i] = blend(v153[i], v158[i], smooth(active.time / 0.22))
            end

            local v168 = Clip.globals(reach, v158)
            local anchor = active.ledge.anchor
            local v169 = glam_quat_mul_vec3(t10, Clip.hands(reach, v168))
            local t15 = {
                anchor[1] - v169[1],
                anchor[2] - v169[2],
                anchor[3] - v169[3]
            }
            local v170 = glam_quat_mul_vec3(t10, v3.clearance(reach, v168))
            local v171 = {
                t15[1] + v170[1],
                t15[2] + v170[2],
                t15[3] + v170[3]
            }
            local anchor2 = active.ledge.anchor
            local v172 = glam_quat_mul_vec3(t10, Clip.hands(reach, Clip.globals(reach, Clip.sample(mantle, Clip.duration(mantle) * 0.55))))
            local t16 = {
                anchor2[1] - v172[1],
                anchor2[2] - v172[2],
                anchor2[3] - v172[3]
            }
            local v173 = smooth((active.time / Clip.duration(mantle) - 0.55) / 0.45)
            local landing = active.ledge.landing
            local v174 = glam_quat_mul_vec3(t10, Clip.feet(reach, Clip.globals(reach, v157)))
            local t17 = {
                landing[1] - v174[1],
                landing[2] - v174[2],
                landing[3] - v174[3]
            }

            if v173 > 0 then
                v171 = glam_lerp(t16, t17, v173)
            end

            if active.time >= Clip.duration(mantle) then
                active.phase = "Settle"
                active.time = 0
            end

            v159 = false
            t13 = {
                translation = v171,
                rotation = rt.copy(t10),
                scale = rt.copy(t2)
            }
        else
            local v175 = smooth(active.time / 0.25)

            v158 = {}

            for i = 1, math.min(#v157, #p60.ground_entry) do
                v158[i] = blend(v157[i], p60.ground_entry[i], v175)
            end

            local landing = active.ledge.landing
            local v178 = glam_quat_mul_vec3(t10, Clip.feet(reach, Clip.globals(reach, v158)))
            local t18 = {
                landing[1] - v178[1],
                landing[2] - v178[2],
                landing[3] - v178[3]
            }

            v159 = active.time >= 0.25
            t13 = {
                translation = t18,
                rotation = rt.copy(t10),
                scale = rt.copy(t2)
            }
        end

        local v179 = glam_transform_to_matrix(t13)
        local v180 = if phase == "Catch" or phase == "Hang" then 1 elseif phase == "Mantle" then 1 - smooth((time / Clip.duration(mantle) - 0.5) / 0.05) else 0

        if v180 > 0 then
            v3.hands(reach, v158, v179, active.ledge, v180)
        end

        local v181 = Clip.globals(reach, v158)
        local SKATEBOARD_ROOT = Clip.index(reach, "SKATEBOARD_ROOT")
        local v182

        if active.carry_board then
            local v183 = v181[Clip.index(reach, "HIPS") + 1]
            local v184 = glam_mat4_transform_point3(v179, {
                v183[4][1],
                v183[4][2],
                v183[4][3]
            })
            local v185 = v181[Clip.index(reach, "SPINE3") + 1]
            local v186 = glam_mat4_transform_point3(v179, {
                v185[4][1],
                v185[4][2],
                v185[4][3]
            })
            local t19 = {
                v186[1] - v184[1],
                v186[2] - v184[2],
                v186[3] - v184[3]
            }
            local v188 = 1 / math.sqrt(t19[1] * t19[1] + t19[2] * t19[2] + t19[3] * t19[3])
            local t20 = {
                t19[1] * v188,
                t19[2] * v188,
                t19[3] * v188
            }
            local v189 = v181[Clip.index(reach, "LEFTARM") + 1]
            local t21 = {
                v189[4][1],
                v189[4][2],
                v189[4][3]
            }
            local v190 = v181[Clip.index(reach, "RIGHTARM") + 1]
            local t22 = {
                v190[4][1],
                v190[4][2],
                v190[4][3]
            }
            local v192 = glam_cross(glam_mat4_transform_vector3(v179, {
                t21[1] - t22[1],
                t21[2] - t22[2],
                t21[3] - t22[3]
            }), t20)
            local v194 = 1 / math.sqrt(v192[1] * v192[1] + v192[2] * v192[2] + v192[3] * v192[3])
            local t23 = {
                v192[1] * v194,
                v192[2] * v194,
                v192[3] * v194
            }
            local v195 = glam_cross(t20, t23)
            local v197 = 1 / math.sqrt(v195[1] * v195[1] + v195[2] * v195[2] + v195[3] * v195[3])
            local t24 = {
                v195[1] * v197,
                v195[2] * v197,
                v195[3] * v197
            }
            local t25 = {
                v184[1] + v186[1],
                v184[2] + v186[2],
                v184[3] + v186[3]
            }
            local t26 = {
                t25[1] * 0.5,
                t25[2] * 0.5,
                t25[3] * 0.5
            }
            local t27 = {
                t23[1] * 0.2,
                t23[2] * 0.2,
                t23[3] * 0.2
            }
            local t28 = {
                translation = {
                    t26[1] - t27[1],
                    t26[2] - t27[2],
                    t26[3] - t27[3]
                },
                rotation = glam_quat_from_rotation_axes(t24, {
                    -t23[1],
                    -t23[2],
                    -t23[3]
                }, t20),
                scale = rt.copy(t2)
            }
            local v201 = blend(glam_transform_from_matrix(active.board_world), t28, rt.fmax(smooth(active.time / 0.2), if active.phase == "Catch" then 0 else 1))

            if phase == "Settle" then
                v201 = blend(v201, glam_transform_from_matrix((glam_mat4_mul(v179, Clip.globals(reach, p60.ground_entry)[SKATEBOARD_ROOT + 1]))), smooth(time / 0.25))
            end

            v182 = glam_transform_to_matrix(v201)
        else
            local RidingOutputs = import("skate_game/physics/riding_outputs").RidingOutputs

            BoardRuntime.clear_forces(p61.board)
            RidingOutputs.start_wheel_queries(p61.riding, p61.board, p61.world)
            RidingOutputs.finish_wheel_queries(p61.riding)

            local v203 = import("skate_game/physics/colliders").world_volumes(p61.board, p61.settings)
            local v204 = rt.copy(BoardWorld.query_primitives(p61.world, v203, p61.query, p61.retention))

            p61.contact_count = #v204
            BoardRuntime.advance(p61.board, v204, { 0, 0 }, p61.settings.step)
            RidingOutputs.finish_post_physics(p61.riding, p61.board, p61.board_wiping_out, p61.processed_flags_2468, time_step)
            v182 = glam_mat4_mul(glam_mat4_mul(matrix(import("skate_game/physics/solve").deck_frame(p61.board)), (glam_mat4_inverse(active.physical_board_world))), active.board_world)
        end

        local v205 = glam_mat4_mul(glam_mat4_mul(glam_mat4_inverse(v179), v182), (glam_mat4_inverse(v181[SKATEBOARD_ROOT + 1])))

        for i = 0, #v181 - 1 do
            local v206 = i

            while v206 >= 0 and v206 ~= SKATEBOARD_ROOT do
                v206 = reach.parents[v206 + 1]
            end

            if v206 == SKATEBOARD_ROOT then
                v181[i + 1] = glam_mat4_mul(v205, v181[i + 1])
            end
        end

        local v207 = rt.copy(active.fallback)

        for i = 1, math.min(#p60.indices, #v181) do
            v207[p60.indices[i] + 1] = native(v181[i])
        end

        local v210 = glam_mat4_mul(glam_mat4_mul(v182, (glam_mat4_inverse(active.board_world))), active.physical_board_world)

        if active.carry_board then
            BoardRuntime.set_transform(p61.board, {
                basis = {
                    columns = {
                        {
                            v210[1][1],
                            v210[1][2],
                            v210[1][3]
                        },
                        {
                            v210[2][1],
                            v210[2][2],
                            v210[2][3]
                        },
                        {
                            v210[3][1],
                            v210[3][2],
                            v210[3][3]
                        }
                    }
                },
                translation = Vector3.new(v210[4][1], v210[4][2], v210[4][3])
            })

            for _, v211 in ipairs(BoardRuntime.bodies_mut(p61.board)) do
                zero_rates(v211.rates)
            end
        end

        publish_pose(p61, p62, v179, v207)

        local v212 = DerivedControllerInput.words(p63.controller)
        local extra = p62.animation_input.extra

        buffer.writeu32(v1, 0, v212[10])
        extra.look_x = buffer.readf32(v1, 0)

        local extra2 = p62.animation_input.extra

        buffer.writeu32(v1, 0, v212[11])
        extra2.look_y = buffer.readf32(v1, 0)

        local v215 = rt.copy(p62.physical_feedback)

        import("skate_game/physics/camera_output").advance(p61, p62, v215, p64)
        p61.ticks += 1
        import("skate_game/physics/clock").SimulationClock.finish_tick(p61.clock)

        if v159 then
            import("skate_game/physics/player_state").resume_after_climb(p61, p62)
            p60.active = nil
            p60.cooldown = 0.3
        end

        return true
    end

    p60.active = nil
    p60.approach = nil
    p60.cooldown = 0.3

    return false
end

function t1.zero_rates(p65) -- line: 724
    -- upvalues: rt (copy), Vector3 (copy)
    p65.linear_velocity = rt.copy(Vector3.ZERO)
    p65.angular_velocity = rt.copy(Vector3.ZERO)
    p65.force_acceleration = rt.copy(Vector3.ZERO)
    p65.torque_acceleration = rt.copy(Vector3.ZERO)
end

zero_rates = t1.zero_rates

function t1.publish_pose(_, p67, p68, p69) -- line: 734
    -- upvalues: rt (copy), map_animation_parts (copy), SkeletonAnimationRecord (copy), SkeletonBoardFrames (copy), CentreOfMassFilter (copy), CorrectionState (copy), SkeletonBody (copy), SkeletonTargets (copy), SkeletonPoseErrors (copy), glam_mat4_mul (copy), glam_mat4_inverse (copy), glam_mat4_transform_point3 (copy), matrix (copy), native (copy), point2 (copy), zero_rates (ref)
    local function native_to_bits(p70) -- line: 735
        -- upvalues: rt (copy)
        return rt.map(p70, function(p71) -- line: 736
            -- upvalues: rt (copy)
            return rt.map(p71, rt.to_bits)
        end)
    end

    local animated_skeleton = p67.animated_skeleton
    local v216 = map_animation_parts(p69, animated_skeleton.bone_indices, animated_skeleton.physics_frames)

    animated_skeleton.roots.animation_to_world = native(p68)
    animated_skeleton.roots.world_to_animation = native((glam_mat4_inverse(p68)))
    SkeletonAnimationRecord.update(animated_skeleton.record, v216, animated_skeleton.roots.animation_to_board, animated_skeleton.masses)
    animated_skeleton.animation_hips = rt.copy(v216[24])
    animated_skeleton.animation_board = rt.copy(v216[1])

    local v217 = glam_mat4_transform_point3(p68, {
        animated_skeleton.record.centre_of_mass[1],
        animated_skeleton.record.centre_of_mass[2],
        animated_skeleton.record.centre_of_mass[3]
    })

    SkeletonBoardFrames.update_com_lift(animated_skeleton.board_frames, native(p68), point2(v217), 0.24)
    animated_skeleton.board_frames.centre_of_mass = point2(v217)
    animated_skeleton.board_frames.previous_centre_of_mass = point2(v217)
    animated_skeleton.board_frames.com_velocity = { 0, 0, 0, 0 }

    for i = 0, #v216 - 1 do
        SkeletonBody.set_part_transform(p67.skeleton, i, native((glam_mat4_mul(p68, matrix(v216[i + 1])))))
    end

    SkeletonBody.set_part_transform(p67.skeleton, 24, rt.copy(animated_skeleton.board_frames.lifted_com_frame))
    SkeletonBody.set_part_transform(p67.skeleton, 25, rt.copy(animated_skeleton.board_frames.com_frame))
    SkeletonTargets.reset(p67.skeleton_drives.targets, native((glam_mat4_mul(p68, matrix(v216[24])))), native((glam_mat4_mul(p68, matrix(v216[1])))))

    local v218 = SkeletonTargets.update_extra_targets(p67.skeleton_drives.targets, p67.skeleton, animated_skeleton.board_frames.com_frame, animated_skeleton.board_frames.lifted_com_frame)

    p67.skeleton_input.extra_target_positions = {
        rt.copy(v218.com),
        rt.copy(v218.lifted_com),
        rt.copy(v218.following_com)
    }
    SkeletonPoseErrors.set_targets(p67.pose_errors, v218)
    p67.skeleton_input.drive_frames = v216

    for _, v219 in ipairs(SkeletonBody.bodies_mut(p67.skeleton)) do
        zero_rates(v219.rates)
    end

    p67.skeleton.animation_to_world = native(p68)
    p67.skeleton_input.previous_root_position = point2({
        p68[4][1],
        p68[4][2],
        p68[4][3]
    })
    p67.skeleton_input.root_velocity = { 0, 0, 0, 0 }
    p67.skeleton_output.correction = CorrectionState.default()
    SkeletonBody.publish_physical_record(p67.skeleton, native((glam_mat4_mul(p68, matrix(v216[1])))))

    local processed = p67.player_input.processed
    local v220 = native(p68)

    processed.effective_anim_transform_192 = rt.map(v220, function(p72) -- line: 736
        -- upvalues: rt (copy)
        return rt.map(p72, rt.to_bits)
    end)
    processed.vectors_544_560_592_608[3] = rt.map(point2(v217), rt.to_bits)
    processed.vectors_544_560_592_608[4] = { 0, 0, 0, 0 }
    processed.flags_2472 = bit32.band(processed.flags_2472, 4294966271)

    local physical = p67.player_input.physical
    local skeleton = physical.skeleton
    local v221 = native(p68)

    skeleton.anim_to_world_11920 = rt.map(v221, function(p73) -- line: 736
        -- upvalues: rt (copy)
        return rt.map(p73, rt.to_bits)
    end)
    physical.reckoning.vector_64 = rt.map(point2(v217), rt.to_bits)
    physical.reckoning.vector_16 = { 0, 0, 0, 0 }
    physical.reckoning.vector_96 = rt.map({ 0, 1, 0, 0 }, rt.to_bits)
    physical.air.flag_441 = 0
    physical.air.use_air_reckoning_452 = 0
    p67.centre_of_mass_output = CentreOfMassFilter.update(p67.centre_of_mass_filter, point2(v217), { 0, 0, 0, 0 })
    p67.render_pose = p69
    p67.pose_generation += 1
    p67.player_input.player.update_count_1316 = rt.wrapping_add_u32(p67.player_input.player.update_count_1316, 1)
end

publish_pose = t1.publish_pose

return t1
