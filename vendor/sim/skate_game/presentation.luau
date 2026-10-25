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

local function rtl_fround(p2) -- line: 16
    -- upvalues: v1 (copy)
    if p2 ~= 0 and p2 > -1.1754943508222875E-38 and p2 < 1.1754943508222875E-38 then
        local v6 = math.abs(p2) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        local v8 = v5 * 1.401298464324817E-45

        if p2 < 0 then
            return -v8
        end

        return v8
    end

    buffer.writef32(v1, 0, p2)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)

local function animation() -- line: 39
    -- upvalues: import (copy)
    return import("skate_game/animation")
end

local function replay_mod() -- line: 42
    -- upvalues: import (copy)
    return import("skate_game/replay")
end

local function camera_runtime() -- line: 45
    -- upvalues: import (copy)
    return import("skate_game/camera/runtime")
end

local function manual_cam() -- line: 48
    -- upvalues: import (copy)
    return import("skate_core/camera/manual_cam")
end

local t1 = {}

local function glam_mat4_determinant(p3) -- line: 55
    local v9 = p3[1][1]
    local v10 = p3[1][2]
    local v11 = p3[1][3]
    local v12 = p3[1][4]
    local v13 = p3[2][1]
    local v14 = p3[2][2]
    local v15 = p3[2][3]
    local v16 = p3[2][4]
    local v17 = p3[3][1]
    local v18 = p3[3][2]
    local v19 = p3[3][3]
    local v20 = p3[3][4]
    local v21 = p3[4][1]
    local v22 = p3[4][2]
    local v23 = p3[4][3]
    local v24 = p3[4][4]
    local v25 = v9 * v14 - v13 * v10
    local v26 = v9 * v15 - v13 * v11
    local v27 = v9 * v16 - v13 * v12
    local v28 = v10 * v15 - v14 * v11
    local v29 = v10 * v16 - v14 * v12
    local v30 = v11 * v16 - v15 * v12
    local v31 = v19 * v24 - v23 * v20
    local v32 = v18 * v24 - v22 * v20
    local v33 = v18 * v23 - v22 * v19
    local v34 = v17 * v24 - v21 * v20
    local v35 = v17 * v23 - v21 * v19
    local v36 = v17 * v22 - v21 * v18

    return v25 * v31 - v26 * v32 + v27 * v33 + v28 * v34 - v29 * v35 + v30 * v36
end

local function glam_quat_from_rotation_axes(p4, p5, p6) -- line: 76
    local v37 = p4[1]
    local v38 = p4[2]
    local v39 = p4[3]
    local v40 = p5[1]
    local v41 = p5[2]
    local v42 = p5[3]
    local v43 = p6[1]
    local v44 = p6[2]
    local v45 = p6[3]

    if v45 <= 0 then
        local v46 = v41 - v37
        local v47 = 1 - v45

        if v46 <= 0 then
            local v48 = v47 - v46
            local v49 = 0.5 / math.sqrt(v48)

            return {
                v48 * v49,
                (v38 + v40) * v49,
                (v39 + v43) * v49,
                (v42 - v44) * v49
            }
        end

        local v50 = v47 + v46
        local v51 = 0.5 / math.sqrt(v50)

        return {
            (v38 + v40) * v51,
            v50 * v51,
            (v42 + v44) * v51,
            (v43 - v39) * v51
        }
    end

    local v52 = v41 + v37
    local v53 = 1 + v45

    if v52 <= 0 then
        local v54 = v53 - v52
        local v55 = 0.5 / math.sqrt(v54)

        return {
            (v39 + v43) * v55,
            (v42 + v44) * v55,
            v54 * v55,
            (v38 - v40) * v55
        }
    end

    local v56 = v53 + v52
    local v57 = 0.5 / math.sqrt(v56)

    return {
        (v42 - v44) * v57,
        (v43 - v39) * v57,
        (v38 - v40) * v57,
        v56 * v57
    }
end

local function glam_transform_from_matrix(p7) -- line: 114
    -- upvalues: rt (copy), glam_mat4_determinant (copy), glam_quat_from_rotation_axes (copy)
    local v58 = glam_mat4_determinant(p7)
    local v59 = p7[1]
    local v60 = p7[2]
    local v61 = p7[3]
    local v63 = math.sqrt(v59[1] * v59[1] + v59[2] * v59[2] + v59[3] * v59[3] + v59[4] * v59[4]) * rt.signum(v58)
    local v65 = math.sqrt(v60[1] * v60[1] + v60[2] * v60[2] + v60[3] * v60[3] + v60[4] * v60[4])
    local v67 = math.sqrt(v61[1] * v61[1] + v61[2] * v61[2] + v61[3] * v61[3] + v61[4] * v61[4])
    local v68 = 1 / v63
    local v69 = 1 / v65
    local v70 = 1 / v67
    local v71 = glam_quat_from_rotation_axes({
        v59[1] * v68,
        v59[2] * v68,
        v59[3] * v68
    }, {
        v60[1] * v69,
        v60[2] * v69,
        v60[3] * v69
    }, {
        v61[1] * v70,
        v61[2] * v70,
        v61[3] * v70
    })

    return {
        translation = {
            p7[4][1],
            p7[4][2],
            p7[4][3]
        },
        rotation = v71,
        scale = { v63, v65, v67 }
    }
end

local function glam_quat_normalize(p8) -- line: 134
    local v73 = 1 / math.sqrt(p8[1] * p8[1] + p8[2] * p8[2] + p8[3] * p8[3] + p8[4] * p8[4])

    return {
        p8[1] * v73,
        p8[2] * v73,
        p8[3] * v73,
        p8[4] * v73
    }
end

local function glam_quat_slerp(p9, p10, p11) -- line: 141
    -- upvalues: rt (copy), v1 (copy), glam_quat_normalize (copy)
    local v74 = p10[1]
    local v75 = p10[2]
    local v76 = p10[3]
    local v77 = p10[4]
    local v78 = p9[1] * v74 + p9[2] * v75 + p9[3] * v76 + p9[4] * v77

    if v78 < 0 then
        v74 = -v74
        v75 = -v75
        v76 = -v76
        v77 = -v77
        v78 = -v78
    end

    local v79 = 1 - rt.F32_EPSILON
    local v80

    if v78 ~= 0 and v78 > -1.1754943508222875E-38 and v78 < 1.1754943508222875E-38 then
        local v81 = math.abs(v78) * 7.1362384635298E+44
        local v82 = math.floor(v81)
        local v83 = v81 - v82

        v80 = (if v83 > 0.5 or v83 == 0.5 and v82 % 2 == 1 then v82 + 1 else v82) * 1.401298464324817E-45

        if v78 < 0 then
            v80 = -v80
        end
    else
        buffer.writef32(v1, 0, v78)
        v80 = buffer.readf32(v1, 0)
    end

    if v79 < v80 then
        local v84 = 1 - p11

        return (glam_quat_normalize({
            p9[1] * v84 + v74 * p11,
            p9[2] * v84 + v75 * p11,
            p9[3] * v84 + v76 * p11,
            p9[4] * v84 + v77 * p11
        }))
    end

    local v85 = math.acos(v78)
    local v87 = math.sin(v85 * (1 - p11))
    local v89 = math.sin(v85 * p11)
    local v90 = 1 / math.sin(v85)

    return {
        (p9[1] * v87 + v74 * v89) * v90,
        (p9[2] * v87 + v75 * v89) * v90,
        (p9[3] * v87 + v76 * v89) * v90,
        (p9[4] * v87 + v77 * v89) * v90
    }
end

local function glam_vec3_lerp(p12, p13, p14) -- line: 169
    local v91 = 1 - p14

    return {
        p12[1] * v91 + p13[1] * p14,
        p12[2] * v91 + p13[2] * p14,
        p12[3] * v91 + p13[3] * p14
    }
end

t1.PresentationPlugin = {}
t1.Snapshot = {}
t1.Presentation = {}

local Presentation = t1.Presentation

function t1.Presentation.default() -- line: 191
    return {
        pair = nil,
        generation = 0,
        period = 0
    }
end

function t1.Presentation.view(p15, p16, p17) -- line: 197
    -- upvalues: rt (copy), import (copy), Presentation (copy)
    if p16.active then
        return import("skate_game/replay").Replay.sample(p16)
    end

    local v92, v93 = Presentation.pair(p15)

    if v92 == nil then
        return nil
    end

    return v92, v93, rt.clamp(p17, 0, 1)
end

function t1.Presentation.pair(p18) -- line: 211
    local pair = p18.pair

    if pair == nil then
        return nil
    end

    return pair[1], pair[2]
end

function t1.capture_reference(p19, p20, p21, p22, p23) -- line: 228
    -- upvalues: rt (copy), import (copy), t1 (copy), glam_transform_from_matrix (copy)
    if p19.pose_generation == p22.generation and not import("skate_core/camera/manual_cam").ManualCam.manual_cam_active(p20.manual_cam) then
        return
    end

    local v94 = import("skate_game/camera/runtime").CameraRuntime.presentation_frame(p20)

    if v94 ~= nil then
        local native_matrix = import("skate_game/animation").native_matrix
        local v95 = table.create(#p19.render_pose)

        for v96, v97 in ipairs(p19.render_pose) do
            v95[v96] = native_matrix(v97)
        end

        local t2 = {
            root = glam_transform_from_matrix(native_matrix(p19.animated_skeleton.roots.animation_to_world)),
            bones = v95,
            camera = t1.camera_transform(v94),
            fov = math.rad(v94.field_of_view_degrees)
        }
        local discontinuity = v94.discontinuity

        if not discontinuity then
            discontinuity = bit32.band(p19.player_input.processed.flags_2472, 1024) ~= 0 or p22.period ~= p21.timestep
        end

        import("skate_game/replay").Replay.record_copy(p23, t2, p21.delta_secs_f64, discontinuity)

        local pair = p22.pair

        if pair ~= nil then
            if discontinuity then
                pair[1] = rt.copy(t2)
            elseif #pair[2].bones == #t2.bones then
                local v98 = pair[1]

                pair[1] = pair[2]
                pair[2] = v98
            else
                pair[1] = rt.copy(t2)
            end

            pair[2] = t2
        else
            p22.pair = {
                rt.copy(t2),
                t2
            }
        end

        p22.generation = p19.pose_generation
        p22.period = p21.timestep
    end
end

t1.CAPTURE_POOLED = true

local function new_snapshot(p24) -- line: 292
    local v99 = table.create(p24)

    for i = 1, p24 do
        v99[i] = {
            { 0, 0, 0, 0 },
            { 0, 0, 0, 0 },
            { 0, 0, 0, 0 },
            { 0, 0, 0, 1 }
        }
    end

    return {
        fov = 0,
        root = {
            translation = { 0, 0, 0 },
            rotation = { 0, 0, 0, 1 },
            scale = { 1, 1, 1 }
        },
        bones = v99,
        camera = {
            translation = { 0, 0, 0 },
            rotation = { 0, 0, 0, 1 },
            scale = { 1, 1, 1 }
        }
    }
end

local function quat_from_axes(p25, p26, p27, p28, p29, p30, p31, p32, p33) -- line: 306
    if p33 <= 0 then
        local v100 = p29 - p25
        local v101 = 1 - p33

        if v100 <= 0 then
            local v102 = v101 - v100
            local v103 = 0.5 / math.sqrt(v102)

            return v102 * v103, (p26 + p28) * v103, (p27 + p31) * v103, (p30 - p32) * v103
        end

        local v104 = v101 + v100
        local v105 = 0.5 / math.sqrt(v104)

        return (p26 + p28) * v105, v104 * v105, (p30 + p32) * v105, (p31 - p27) * v105
    end

    local v106 = p29 + p25
    local v107 = p33 + 1

    if v106 <= 0 then
        local v108 = v107 - v106
        local v109 = 0.5 / math.sqrt(v108)

        return (p27 + p31) * v109, (p30 + p32) * v109, v108 * v109, (p26 - p28) * v109
    end

    local v110 = v107 + v106
    local v111 = 0.5 / math.sqrt(v110)

    return (p30 - p32) * v111, (p31 - p27) * v111, (p26 - p28) * v111, v110 * v111
end

function t1.capture(p34, p35, p36, p37, p38) -- line: 334
    -- upvalues: rt (copy), import (copy), t1 (copy), new_snapshot (copy), quat_from_axes (copy)
    if not t1.CAPTURE_POOLED then
        return t1.capture_reference(p34, p35, p36, p37, p38)
    end

    if p34.pose_generation ~= p37.generation or import("skate_core/camera/manual_cam").ManualCam.manual_cam_active(p35.manual_cam) then
        local v112 = import("skate_game/camera/runtime").CameraRuntime.presentation_frame(p35)

        if v112 ~= nil then
            local render_pose = p34.render_pose
            local v113 = #render_pose
            local spare = p37.spare

            p37.spare = nil

            if spare == nil or #spare.bones ~= v113 then
                spare = new_snapshot(v113)
            end

            spare.locals_for = nil

            local bones = spare.bones

            for i = 1, v113 do
                local v114 = render_pose[i]
                local v115 = bones[i]
                local v116 = v114[1]
                local v117 = v115[1]
                local v118 = v116[1]
                local v119 = v116[2]
                local v120 = v116[3]

                v117[1] = v118
                v117[2] = v119
                v117[3] = v120
                v117[4] = 0

                local v121 = v114[2]
                local v122 = v115[2]
                local v123 = v121[1]
                local v124 = v121[2]
                local v125 = v121[3]

                v122[1] = v123
                v122[2] = v124
                v122[3] = v125
                v122[4] = 0

                local v126 = v114[3]
                local v127 = v115[3]
                local v128 = v126[1]
                local v129 = v126[2]
                local v130 = v126[3]

                v127[1] = v128
                v127[2] = v129
                v127[3] = v130
                v127[4] = 0

                local v131 = v114[4]
                local v132 = v115[4]
                local v133 = v131[1]
                local v134 = v131[2]
                local v135 = v131[3]

                v132[1] = v133
                v132[2] = v134
                v132[3] = v135
                v132[4] = 1
            end

            local animation_to_world = p34.animated_skeleton.roots.animation_to_world
            local v136 = animation_to_world[1]
            local v137 = animation_to_world[2]
            local v138 = animation_to_world[3]
            local v139 = animation_to_world[4]
            local v140 = v136[1]
            local v141 = v136[2]
            local v142 = v136[3]
            local v143 = v137[1]
            local v144 = v137[2]
            local v145 = v137[3]
            local v146 = v138[1]
            local v147 = v138[2]
            local v148 = v138[3]
            local v149 = v139[1]
            local v150 = v139[2]
            local v151 = v139[3]
            local v152 = v140 * v144 - v143 * v141
            local v153 = v140 * v145 - v143 * v142
            local v154 = v140 * 0 - v143 * 0
            local v155 = v141 * v145 - v144 * v142
            local v156 = v141 * 0 - v144 * 0
            local v157 = v142 * 0 - v145 * 0
            local v158 = v148 * 1 - v151 * 0
            local v159 = v147 * 1 - v150 * 0
            local v160 = v147 * v151 - v150 * v148
            local v161 = v146 * 1 - v149 * 0
            local v162 = v146 * v151 - v149 * v148
            local v163 = v146 * v150 - v149 * v147
            local v164 = v152 * v158 - v153 * v159 + v154 * v160 + v155 * v161 - v156 * v162 + v157 * v163
            local v166 = math.sqrt(v140 * v140 + v141 * v141 + v142 * v142 + 0) * rt.signum(v164)
            local v168 = math.sqrt(v143 * v143 + v144 * v144 + v145 * v145 + 0)
            local v170 = math.sqrt(v146 * v146 + v147 * v147 + v148 * v148 + 0)
            local v171 = 1 / v166
            local v172 = 1 / v168
            local v173 = 1 / v170
            local v174, v175, v176, v177 = quat_from_axes(v140 * v171, v141 * v171, v142 * v171, v143 * v172, v144 * v172, v145 * v172, v146 * v173, v147 * v173, v148 * v173)
            local root = spare.root
            local translation, rotation, scale = root.translation, root.rotation, root.scale

            translation[1] = v149
            translation[2] = v150
            translation[3] = v151
            rotation[1] = v174
            rotation[2] = v175
            rotation[3] = v176
            rotation[4] = v177
            scale[1] = v166
            scale[2] = v168
            scale[3] = v170

            local columns = v112.basis.columns
            local v178 = columns[1]
            local v179 = columns[2]
            local v180 = columns[3]
            local v181, v182, v183, v184 = quat_from_axes(-v178[1], -v178[2], -v178[3], v179[1], v179[2], v179[3], -v180[1], -v180[2], -v180[3])
            local v186 = 1 / math.sqrt(v181 * v181 + v182 * v182 + v183 * v183 + v184 * v184)
            local camera = spare.camera
            local translation2, rotation2, scale2 = camera.translation, camera.rotation, camera.scale
            local position = v112.position
            local v187 = position[1]
            local v188 = position[2]
            local v189 = position[3]

            translation2[1] = v187
            translation2[2] = v188
            translation2[3] = v189

            local v190 = v181 * v186
            local v191 = v182 * v186
            local v192 = v183 * v186
            local v193 = v184 * v186

            rotation2[1] = v190
            rotation2[2] = v191
            rotation2[3] = v192
            rotation2[4] = v193
            scale2[1] = 1
            scale2[2] = 1
            scale2[3] = 1
            spare.fov = math.rad(v112.field_of_view_degrees)

            local discontinuity = v112.discontinuity

            if not discontinuity then
                discontinuity = bit32.band(p34.player_input.processed.flags_2472, 1024) ~= 0 or p37.period ~= p36.timestep
            end

            import("skate_game/replay").Replay.record_copy(p38, spare, p36.delta_secs_f64, discontinuity)

            local pair = p37.pair

            if pair ~= nil then
                if discontinuity then
                    pair[1] = rt.copy(spare)
                elseif #pair[2].bones == #spare.bones then
                    local v194 = pair[1]

                    pair[1] = pair[2]
                    p37.spare = v194
                else
                    pair[1] = rt.copy(spare)
                end

                pair[2] = spare
            else
                p37.pair = {
                    rt.copy(spare),
                    spare
                }
            end

            p37.generation = p34.pose_generation
            p37.period = p36.timestep
        end
    end
end

function t1.camera_transform(p39) -- line: 439
    -- upvalues: glam_quat_from_rotation_axes (copy), glam_quat_normalize (copy)
    local columns = p39.basis.columns
    local v195 = columns[1]
    local v196 = columns[2]
    local v197 = columns[3]

    return {
        translation = {
            p39.position[1],
            p39.position[2],
            p39.position[3]
        },
        rotation = glam_quat_normalize((glam_quat_from_rotation_axes({
            -v195[1],
            -v195[2],
            -v195[3]
        }, {
            v196[1],
            v196[2],
            v196[3]
        }, {
            -v197[1],
            -v197[2],
            -v197[3]
        }))),
        scale = { 1, 1, 1 }
    }
end

function t1.blend(p40, p41, p42) -- line: 458
    -- upvalues: glam_quat_normalize (copy), glam_quat_slerp (copy), glam_vec3_lerp (copy)
    return {
        translation = glam_vec3_lerp(p40.translation, p41.translation, p42),
        rotation = glam_quat_slerp(glam_quat_normalize(p40.rotation), glam_quat_normalize(p41.rotation), p42),
        scale = glam_vec3_lerp(p40.scale, p41.scale, p42)
    }
end

return t1
