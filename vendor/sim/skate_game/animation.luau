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

local v9 = require(sim.import)("skate_game/presentation")
local t1 = {}

local function glam_mat4_mul(p3, p4) -- line: 53
    local v10 = table.create(4)

    for i = 1, 4 do
        local v11 = p4[i]
        local v12 = v11[1]
        local v13 = v11[2]
        local v14 = v11[3]
        local v15 = v11[4]

        v10[i] = {
            p3[1][1] * v12 + p3[2][1] * v13 + p3[3][1] * v14 + p3[4][1] * v15,
            p3[1][2] * v12 + p3[2][2] * v13 + p3[3][2] * v14 + p3[4][2] * v15,
            p3[1][3] * v12 + p3[2][3] * v13 + p3[3][3] * v14 + p3[4][3] * v15,
            p3[1][4] * v12 + p3[2][4] * v13 + p3[3][4] * v14 + p3[4][4] * v15
        }
    end

    return v10
end

local function glam_mat4_inverse(p5) -- line: 70
    local v16 = p5[1][1]
    local v17 = p5[1][2]
    local v18 = p5[1][3]
    local v19 = p5[1][4]
    local v20 = p5[2][1]
    local v21 = p5[2][2]
    local v22 = p5[2][3]
    local v23 = p5[2][4]
    local v24 = p5[3][1]
    local v25 = p5[3][2]
    local v26 = p5[3][3]
    local v27 = p5[3][4]
    local v28 = p5[4][1]
    local v29 = p5[4][2]
    local v30 = p5[4][3]
    local v31 = p5[4][4]
    local v32 = v16 * v21 - v20 * v17
    local v33 = v16 * v22 - v20 * v18
    local v34 = v16 * v23 - v20 * v19
    local v35 = v17 * v22 - v21 * v18
    local v36 = v17 * v23 - v21 * v19
    local v37 = v18 * v23 - v22 * v19
    local v38 = v26 * v31 - v30 * v27
    local v39 = v25 * v31 - v29 * v27
    local v40 = v25 * v30 - v29 * v26
    local v41 = v24 * v31 - v28 * v27
    local v42 = v24 * v30 - v28 * v26
    local v43 = v24 * v29 - v28 * v25
    local v44 = v32 * v38 - v33 * v39 + v34 * v40 + v35 * v41 - v36 * v42 + v37 * v43
    local v45 = 1 / v44

    return {
        {
            (v21 * v38 - v22 * v39 + v23 * v40) * v45,
            (-v17 * v38 + v18 * v39 - v19 * v40) * v45,
            (v29 * v37 - v30 * v36 + v31 * v35) * v45,
            (-v25 * v37 + v26 * v36 - v27 * v35) * v45
        },
        {
            (-v20 * v38 + v22 * v41 - v23 * v42) * v45,
            (v16 * v38 - v18 * v41 + v19 * v42) * v45,
            (-v28 * v37 + v30 * v34 - v31 * v33) * v45,
            (v24 * v37 - v26 * v34 + v27 * v33) * v45
        },
        {
            (v20 * v39 - v21 * v41 + v23 * v43) * v45,
            (-v16 * v39 + v17 * v41 - v19 * v43) * v45,
            (v28 * v36 - v29 * v34 + v31 * v32) * v45,
            (-v24 * v36 + v25 * v34 - v27 * v32) * v45
        },
        {
            (-v20 * v40 + v21 * v42 - v22 * v43) * v45,
            (v16 * v40 - v17 * v42 + v18 * v43) * v45,
            (-v28 * v35 + v29 * v33 - v30 * v32) * v45,
            (v24 * v35 - v25 * v33 + v26 * v32) * v45
        }
    }, v44
end

local function glam_quat_from_rotation_axes(p6, p7, p8) -- line: 119
    local v46 = p6[1]
    local v47 = p6[2]
    local v48 = p6[3]
    local v49 = p7[1]
    local v50 = p7[2]
    local v51 = p7[3]
    local v52 = p8[1]
    local v53 = p8[2]
    local v54 = p8[3]

    if v54 <= 0 then
        local v55 = v50 - v46
        local v56 = 1 - v54

        if v55 <= 0 then
            local v57 = v56 - v55
            local v58 = 0.5 / math.sqrt(v57)

            return {
                v57 * v58,
                (v47 + v49) * v58,
                (v48 + v52) * v58,
                (v51 - v53) * v58
            }
        end

        local v59 = v56 + v55
        local v60 = 0.5 / math.sqrt(v59)

        return {
            (v47 + v49) * v60,
            v59 * v60,
            (v51 + v53) * v60,
            (v52 - v48) * v60
        }
    end

    local v61 = v50 + v46
    local v62 = 1 + v54

    if v61 <= 0 then
        local v63 = v62 - v61
        local v64 = 0.5 / math.sqrt(v63)

        return {
            (v48 + v52) * v64,
            (v51 + v53) * v64,
            v63 * v64,
            (v47 - v49) * v64
        }
    end

    local v65 = v62 + v61
    local v66 = 0.5 / math.sqrt(v65)

    return {
        (v51 - v53) * v66,
        (v52 - v48) * v66,
        (v47 - v49) * v66,
        v65 * v66
    }
end

local function glam_transform_from_matrix(p9) -- line: 157
    -- upvalues: rt (copy), glam_mat4_inverse (copy), glam_quat_from_rotation_axes (copy)
    local _, v67 = glam_mat4_inverse(p9)
    local v68 = p9[1]
    local v69 = p9[2]
    local v70 = p9[3]
    local v72 = math.sqrt(v68[1] * v68[1] + v68[2] * v68[2] + v68[3] * v68[3] + v68[4] * v68[4]) * rt.signum(v67)
    local v74 = math.sqrt(v69[1] * v69[1] + v69[2] * v69[2] + v69[3] * v69[3] + v69[4] * v69[4])
    local v76 = math.sqrt(v70[1] * v70[1] + v70[2] * v70[2] + v70[3] * v70[3] + v70[4] * v70[4])
    local v77 = 1 / v72
    local v78 = 1 / v74
    local v79 = 1 / v76
    local v80 = glam_quat_from_rotation_axes({
        v68[1] * v77,
        v68[2] * v77,
        v68[3] * v77
    }, {
        v69[1] * v78,
        v69[2] * v78,
        v69[3] * v78
    }, {
        v70[1] * v79,
        v70[2] * v79,
        v70[3] * v79
    })

    return {
        translation = {
            p9[4][1],
            p9[4][2],
            p9[4][3]
        },
        rotation = v80,
        scale = { v72, v74, v76 }
    }
end

local function glam_transform_to_matrix(p10) -- line: 177
    local rotation = p10.rotation
    local v81 = rotation[1]
    local v82 = rotation[2]
    local v83 = rotation[3]
    local v84 = rotation[4]
    local v85 = v81 + v81
    local v86 = v82 + v82
    local v87 = v83 + v83
    local v88 = v81 * v85
    local v89 = v81 * v86
    local v90 = v81 * v87
    local v91 = v82 * v86
    local v92 = v82 * v87
    local v93 = v83 * v87
    local v94 = v84 * v85
    local v95 = v84 * v86
    local v96 = v84 * v87
    local v97 = p10.scale[1]
    local v98 = p10.scale[2]
    local v99 = p10.scale[3]
    local translation = p10.translation

    return {
        {
            (1 - (v91 + v93)) * v97,
            (v89 + v96) * v97,
            (v90 - v95) * v97,
            0 * v97
        },
        {
            (v89 - v96) * v98,
            (1 - (v88 + v93)) * v98,
            (v92 + v94) * v98,
            0 * v98
        },
        {
            (v90 + v95) * v99,
            (v92 - v94) * v99,
            (1 - (v88 + v91)) * v99,
            0 * v99
        },
        {
            translation[1],
            translation[2],
            translation[3],
            1
        }
    }
end

local function glam_mat4_abs_diff_eq_identity(p11, p12) -- line: 203
    for i = 1, 4 do
        for j = 1, 4 do
            local v100 = if i == j then 1 else 0

            if not (math.abs(p11[i][j] - v100) <= p12) then
                return false
            end
        end
    end

    return true
end

local function position_ignore_ascii_case(p13, p14) -- line: 216
    local v102 = string.lower(p14)

    for v103, v104 in ipairs(p13) do
        if string.lower(v104) == v102 then
            return v103 - 1
        end
    end

    return nil
end

local function has_ancestor(p15, p16, p17) -- line: 227
    for _, v105 in ipairs(p15.iter_ancestors(p15, p16)) do
        if v105 == p17 then
            return true
        end
    end

    return false
end

t1.AnimationStatus = {}

local AnimationStatus = t1.AnimationStatus

t1.BoneBinding = {}

function t1.AnimationStatus.default() -- line: 245
    return {
        ready = false,
        bindings = {}
    }
end

function t1.AnimationStatus.pose_transforms(p18, p19) -- line: 251
    -- upvalues: t1 (copy), glam_mat4_mul (copy), glam_mat4_inverse (copy), glam_transform_from_matrix (copy)
    local t2 = {}

    for _, v106 in ipairs(p18.bindings) do
        local v107 = p19[v106.bone + 1]

        if v107 ~= nil then
            local v108 = glam_mat4_mul(v107, t1.render_basis())

            if v106.parent_bone ~= nil then
                local v109 = p19[v106.parent_bone + 1]

                if v109 ~= nil then
                    v108 = glam_mat4_mul(glam_mat4_inverse((glam_mat4_mul(v109, t1.render_basis()))), v108)
                    table.insert(t2, {
                        v106.entity,
                        (glam_transform_from_matrix(v108))
                    })
                end
            else
                table.insert(t2, {
                    v106.entity,
                    (glam_transform_from_matrix(v108))
                })
            end
        end
    end

    return t2
end

function t1.AnimationStatus.online_bindings(p20) -- line: 277
    local v111 = table.create(#p20.bindings)

    for v112, v113 in ipairs(p20.bindings) do
        v111[v112] = {
            v113.entity,
            v113.bone,
            v113.parent_bone
        }
    end

    return v111
end

function t1.AnimationStatus.for_scene(p21, p22, p23, p24, p25) -- line: 287
    -- upvalues: glam_transform_to_matrix (copy), glam_mat4_abs_diff_eq_identity (copy), position_ignore_ascii_case (copy)
    local t5 = {}
    local t6 = {}

    for _, v114 in ipairs(p23) do
        local v115 = v114[1]
        local v116 = v114[2]
        local v117 = false
        local v118

        for _, v119 in ipairs(p25.iter_ancestors(p25, v115)) do
            if v119 == p21 then
                v118 = true
                v117 = true
                break
            end
        end

        if not v117 then
            v118 = false
        end

        if v118 then
            for _, v120 in ipairs(v116.joints) do
                if not t6[v120] then
                    t6[v120] = true

                    local v121 = false
                    local v122

                    for _, v123 in ipairs(p25.iter_ancestors(p25, v120)) do
                        if v123 == p21 then
                            v122 = true
                            v121 = true
                            break
                        end
                    end

                    if not v121 then
                        v122 = false
                    end

                    if not v122 then
                        error("Imported skin refers to a joint outside its scene", 0)
                    end

                    local v124 = p24.get(p24, v120)

                    if v124 == nil then
                        error("Imported joint has no name/transform", 0)
                    end

                    local v125 = position_ignore_ascii_case(p22, v124)

                    if v125 == nil then
                        error("Unsupported imported bone: " .. v124, 0)
                    end

                    local v126

                    for _, v127 in ipairs(p25.iter_ancestors(p25, v120)) do
                        if v127 == p21 then
                            v126 = nil
                            break
                        end

                        local v128, v129 = p24.get(p24, v127)

                        if v128 ~= nil then
                            v126 = position_ignore_ascii_case(p22, v128)

                            if v126 ~= nil then
                                break
                            end

                            if not glam_mat4_abs_diff_eq_identity(glam_transform_to_matrix(v129), 1E-05) then
                                error("Imported armature has an unsupported ancestor transform", 0)
                            end
                        end

                        v126 = nil
                    end

                    table.insert(t5, {
                        entity = v120,
                        bone = v125,
                        parent_bone = v126
                    })
                end
            end
        end
    end

    if #t5 == 0 then
        error("Imported scene has no skinned character", 0)
    end

    return {
        ready = true,
        bindings = t5
    }
end

t1.AnimationPlugin = {}

function t1.bind(p26, p27, p28, p29, p30, p31, p32, p33) -- line: 350
    -- upvalues: glam_transform_to_matrix (copy), glam_mat4_abs_diff_eq_identity (copy), position_ignore_ascii_case (copy)
    if p26 ~= "Ready" or p28.ready then
        return
    end

    local bone_names = p27.animation.evaluator.frames.bone_names

    local function below_root(p34) -- line: 356
        -- upvalues: p31 (copy), p33 (copy)
        for _, v130 in ipairs(p31.iter_ancestors(p31, p34)) do
            if p33.contains(p33, v130) then
                return true
            end
        end

        return false
    end

    local v145 = (function() -- build | line: 365
        -- upvalues: p29 (copy), p30 (copy), p31 (copy), p32 (copy), p33 (copy), bone_names (copy), below_root (copy), glam_transform_to_matrix (copy), glam_mat4_abs_diff_eq_identity (copy), position_ignore_ascii_case (copy)
        local t8 = {}
        local t9 = {}

        for _, v131 in ipairs(p29) do
            local v132 = v131[1]
            local v133 = v131[2]

            if below_root(v132) then
                local v134 = false

                for _, v135 in ipairs(p31.iter_ancestors(p31, v132)) do
                    if p32.get(p32, v135) == "Hidden" then
                        v134 = true
                        break
                    end
                end

                if not v134 then
                    local v136 = table.create(#v133.joints)

                    for _, v137 in ipairs(v133.joints) do
                        if not t9[v137] then
                            t9[v137] = true

                            local v138 = p30.get(p30, v137)

                            if v138 == nil then
                                error("Skater skin joint is missing its name or transform", 0)
                            end

                            local v139 = position_ignore_ascii_case(bone_names, v138)

                            if v139 == nil then
                                error("Skater skin bone " .. v138 .. " is absent from the stock rig", 0)
                            end

                            local v140

                            for _, v141 in ipairs(p31.iter_ancestors(p31, v137)) do
                                if p33.contains(p33, v141) then
                                    v140 = nil
                                    break
                                end

                                local v142, v143 = p30.get(p30, v141)

                                if v142 ~= nil then
                                    v140 = position_ignore_ascii_case(bone_names, v142)

                                    if v140 ~= nil then
                                        break
                                    end

                                    if not glam_mat4_abs_diff_eq_identity(glam_transform_to_matrix(v143), 1E-05) then
                                        error("Skater armature ancestor " .. v142 .. " has an unsupported transform", 0)
                                    end
                                end

                                v140 = nil
                            end

                            table.insert(v136, {
                                entity = v137,
                                bone = v139,
                                parent_bone = v140
                            })
                        end
                    end

                    for _, v144 in ipairs(v136) do
                        table.insert(t8, v144)
                    end
                end
            end
        end

        return if #t8 ~= 0 then t8 else nil
    end)()

    if v145 ~= nil then
        p28.bindings = v145
        p28.ready = true
    end
end

function t1.present(p35, p36, p37, p38, p39) -- line: 446
    -- upvalues: v9 (copy), t1 (copy), glam_mat4_mul (copy), glam_mat4_inverse (copy), glam_transform_from_matrix (copy), AnimationStatus (copy)
    if not p39.ready then
        return {}
    end

    local v146 = t1.render_basis()
    local v147, v148, v149 = v9.Presentation.view(p35, p37, p38)

    if v147 == nil then
        local v150 = table.create(#p36.render_pose)

        for v151, v152 in ipairs(p36.render_pose) do
            v150[v151] = t1.native_matrix(v152)
        end

        return AnimationStatus.pose_transforms(p39, v150)
    end

    local v153 = table.create(#p39.bindings)

    for _, v154 in ipairs(p39.bindings) do
        local function local_(p40) -- line: 466
            -- upvalues: v146 (copy), v154 (copy), glam_mat4_mul (copy), glam_mat4_inverse (copy), glam_transform_from_matrix (copy)
            local v155 = glam_mat4_mul(p40.bones[v154.bone + 1], v146)

            if v154.parent_bone == nil then
                return (glam_transform_from_matrix(v155))
            end

            return (glam_transform_from_matrix((glam_mat4_mul(glam_mat4_inverse((glam_mat4_mul(p40.bones[v154.parent_bone + 1], v146))), v155))))
        end

        table.insert(v153, {
            v154.entity,
            v9.blend(local_(v147), local_(v148), v149)
        })
    end

    return v153
end

local function new_mat4() -- line: 493
    return {
        { 0, 0, 0, 0 },
        { 0, 0, 0, 0 },
        { 0, 0, 0, 0 },
        { 0, 0, 0, 0 }
    }
end

local function new_transform() -- line: 496
    return {
        translation = { 0, 0, 0 },
        rotation = { 0, 0, 0, 0 },
        scale = { 0, 0, 0 }
    }
end

local v157 = new_mat4()
local v158 = new_mat4()
local v159 = new_mat4()
local v160 = new_mat4()
local v161 = new_transform()
local v162 = new_transform()
local v163 = 1 - rt.F32_EPSILON

local function mat4_mul_into(p41, p42, p43) -- line: 504
    local v164 = p42[1]
    local v165 = p42[2]
    local v166 = p42[3]
    local v167 = p42[4]
    local v168 = v164[1]
    local v169 = v164[2]
    local v170 = v164[3]
    local v171 = v164[4]
    local v172 = v165[1]
    local v173 = v165[2]
    local v174 = v165[3]
    local v175 = v165[4]
    local v176 = v166[1]
    local v177 = v166[2]
    local v178 = v166[3]
    local v179 = v166[4]
    local v180 = v167[1]
    local v181 = v167[2]
    local v182 = v167[3]
    local v183 = v167[4]

    for i = 1, 4 do
        local v184 = p43[i]
        local v185 = v184[1]
        local v186 = v184[2]
        local v187 = v184[3]
        local v188 = v184[4]
        local v189 = p41[i]

        v189[1] = v168 * v185 + v172 * v186 + v176 * v187 + v180 * v188
        v189[2] = v169 * v185 + v173 * v186 + v177 * v187 + v181 * v188
        v189[3] = v170 * v185 + v174 * v186 + v178 * v187 + v182 * v188
        v189[4] = v171 * v185 + v175 * v186 + v179 * v187 + v183 * v188
    end
end

local function mat4_inverse_into(p44, p45) -- line: 523
    local v190 = p45[1][1]
    local v191 = p45[1][2]
    local v192 = p45[1][3]
    local v193 = p45[1][4]
    local v194 = p45[2][1]
    local v195 = p45[2][2]
    local v196 = p45[2][3]
    local v197 = p45[2][4]
    local v198 = p45[3][1]
    local v199 = p45[3][2]
    local v200 = p45[3][3]
    local v201 = p45[3][4]
    local v202 = p45[4][1]
    local v203 = p45[4][2]
    local v204 = p45[4][3]
    local v205 = p45[4][4]
    local v206 = v190 * v195 - v194 * v191
    local v207 = v190 * v196 - v194 * v192
    local v208 = v190 * v197 - v194 * v193
    local v209 = v191 * v196 - v195 * v192
    local v210 = v191 * v197 - v195 * v193
    local v211 = v192 * v197 - v196 * v193
    local v212 = v200 * v205 - v204 * v201
    local v213 = v199 * v205 - v203 * v201
    local v214 = v199 * v204 - v203 * v200
    local v215 = v198 * v205 - v202 * v201
    local v216 = v198 * v204 - v202 * v200
    local v217 = v198 * v203 - v202 * v199
    local v218 = 1 / (v206 * v212 - v207 * v213 + v208 * v214 + v209 * v215 - v210 * v216 + v211 * v217)
    local v219 = p44[1]

    v219[1] = (v195 * v212 - v196 * v213 + v197 * v214) * v218
    v219[2] = (-v191 * v212 + v192 * v213 - v193 * v214) * v218
    v219[3] = (v203 * v211 - v204 * v210 + v205 * v209) * v218
    v219[4] = (-v199 * v211 + v200 * v210 - v201 * v209) * v218

    local v220 = p44[2]

    v220[1] = (-v194 * v212 + v196 * v215 - v197 * v216) * v218
    v220[2] = (v190 * v212 - v192 * v215 + v193 * v216) * v218
    v220[3] = (-v202 * v211 + v204 * v208 - v205 * v207) * v218
    v220[4] = (v198 * v211 - v200 * v208 + v201 * v207) * v218

    local v221 = p44[3]

    v221[1] = (v194 * v213 - v195 * v215 + v197 * v217) * v218
    v221[2] = (-v190 * v213 + v191 * v215 - v193 * v217) * v218
    v221[3] = (v202 * v210 - v203 * v208 + v205 * v206) * v218
    v221[4] = (-v198 * v210 + v199 * v208 - v201 * v206) * v218

    local v222 = p44[4]

    v222[1] = (-v194 * v214 + v195 * v216 - v196 * v217) * v218
    v222[2] = (v190 * v214 - v191 * v216 + v192 * v217) * v218
    v222[3] = (-v202 * v209 + v203 * v207 - v204 * v206) * v218
    v222[4] = (v198 * v209 - v199 * v207 + v200 * v206) * v218
end

local function mat4_determinant(p46) -- line: 565
    local v223 = p46[1][1]
    local v224 = p46[1][2]
    local v225 = p46[1][3]
    local v226 = p46[1][4]
    local v227 = p46[2][1]
    local v228 = p46[2][2]
    local v229 = p46[2][3]
    local v230 = p46[2][4]
    local v231 = p46[3][1]
    local v232 = p46[3][2]
    local v233 = p46[3][3]
    local v234 = p46[3][4]
    local v235 = p46[4][1]
    local v236 = p46[4][2]
    local v237 = p46[4][3]
    local v238 = p46[4][4]
    local v239 = v223 * v228 - v227 * v224
    local v240 = v223 * v229 - v227 * v225
    local v241 = v223 * v230 - v227 * v226
    local v242 = v224 * v229 - v228 * v225
    local v243 = v224 * v230 - v228 * v226
    local v244 = v225 * v230 - v229 * v226
    local v245 = v233 * v238 - v237 * v234
    local v246 = v232 * v238 - v236 * v234
    local v247 = v232 * v237 - v236 * v233
    local v248 = v231 * v238 - v235 * v234
    local v249 = v231 * v237 - v235 * v233
    local v250 = v231 * v236 - v235 * v232

    return v239 * v245 - v240 * v246 + v241 * v247 + v242 * v248 - v243 * v249 + v244 * v250
end

local function transform_from_matrix_into(p47, p48) -- line: 586
    -- upvalues: rt (copy), mat4_determinant (copy)
    local v251 = mat4_determinant(p48)
    local v252 = p48[1]
    local v253 = p48[2]
    local v254 = p48[3]
    local v256 = math.sqrt(v252[1] * v252[1] + v252[2] * v252[2] + v252[3] * v252[3] + v252[4] * v252[4]) * rt.signum(v251)
    local v258 = math.sqrt(v253[1] * v253[1] + v253[2] * v253[2] + v253[3] * v253[3] + v253[4] * v253[4])
    local v260 = math.sqrt(v254[1] * v254[1] + v254[2] * v254[2] + v254[3] * v254[3] + v254[4] * v254[4])
    local v261 = 1 / v256
    local v262 = 1 / v258
    local v263 = 1 / v260
    local v264 = v252[1] * v261
    local v265 = v252[2] * v261
    local v266 = v252[3] * v261
    local v267 = v253[1] * v262
    local v268 = v253[2] * v262
    local v269 = v253[3] * v262
    local v270 = v254[1] * v263
    local v271 = v254[2] * v263
    local v272 = v254[3] * v263
    local v273, v274, v275, v276

    if v272 <= 0 then
        local v277 = v268 - v264
        local v278 = 1 - v272

        if v277 <= 0 then
            local v279 = v278 - v277
            local v280 = 0.5 / math.sqrt(v279)

            v273 = v279 * v280
            v274 = (v265 + v267) * v280
            v275 = (v266 + v270) * v280
            v276 = (v269 - v271) * v280
        else
            local v281 = v278 + v277
            local v282 = 0.5 / math.sqrt(v281)

            v273 = (v265 + v267) * v282
            v274 = v281 * v282
            v275 = (v269 + v271) * v282
            v276 = (v270 - v266) * v282
        end
    else
        local v283 = v268 + v264
        local v284 = 1 + v272

        if v283 <= 0 then
            local v285 = v284 - v283
            local v286 = 0.5 / math.sqrt(v285)

            v273 = (v266 + v270) * v286
            v274 = (v269 + v271) * v286
            v275 = v285 * v286
            v276 = (v265 - v267) * v286
        else
            local v287 = v284 + v283
            local v288 = 0.5 / math.sqrt(v287)

            v273 = (v269 - v271) * v288
            v274 = (v270 - v266) * v288
            v275 = (v265 - v267) * v288
            v276 = v287 * v288
        end
    end

    local v289 = p48[4]
    local translation = p47.translation
    local v290 = v289[1]
    local v291 = v289[2]
    local v292 = v289[3]

    translation[1] = v290
    translation[2] = v291
    translation[3] = v292

    local rotation = p47.rotation

    rotation[1] = v273
    rotation[2] = v274
    rotation[3] = v275
    rotation[4] = v276

    local scale = p47.scale

    scale[1] = v256
    scale[2] = v258
    scale[3] = v260
end

local function binding_local_into(p49, p50, p51, p52) -- line: 633
    -- upvalues: v157 (copy), v158 (copy), v159 (copy), v160 (copy), mat4_mul_into (copy), mat4_inverse_into (copy), transform_from_matrix_into (copy)
    mat4_mul_into(v157, p50.bones[p51.bone + 1], p52)

    if p51.parent_bone ~= nil then
        mat4_mul_into(v158, p50.bones[p51.parent_bone + 1], p52)
        mat4_inverse_into(v159, v158)
        mat4_mul_into(v160, v159, v157)
        transform_from_matrix_into(p49, v160)
    else
        transform_from_matrix_into(p49, v157)
    end
end

local function blend_into(p53, p54, p55, p56) -- line: 646
    -- upvalues: v1 (copy), v163 (copy)
    local v293 = 1 - p56
    local translation = p54.translation
    local translation2 = p55.translation
    local translation3 = p53.translation
    local v294 = translation[1] * v293 + translation2[1] * p56
    local v295 = translation[2] * v293 + translation2[2] * p56
    local v296 = translation[3] * v293 + translation2[3] * p56

    translation3[1] = v294
    translation3[2] = v295
    translation3[3] = v296

    local rotation = p54.rotation
    local rotation2 = p55.rotation
    local v298 = 1 / math.sqrt(rotation[1] * rotation[1] + rotation[2] * rotation[2] + rotation[3] * rotation[3] + rotation[4] * rotation[4])
    local v299 = rotation[1] * v298
    local v300 = rotation[2] * v298
    local v301 = rotation[3] * v298
    local v302 = rotation[4] * v298
    local v304 = 1 / math.sqrt(rotation2[1] * rotation2[1] + rotation2[2] * rotation2[2] + rotation2[3] * rotation2[3] + rotation2[4] * rotation2[4])
    local v305 = rotation2[1] * v304
    local v306 = rotation2[2] * v304
    local v307 = rotation2[3] * v304
    local v308 = rotation2[4] * v304
    local v309 = v299 * v305 + v300 * v306 + v301 * v307 + v302 * v308

    if v309 < 0 then
        v305 = -v305
        v306 = -v306
        v307 = -v307
        v308 = -v308
        v309 = -v309
    end

    local v310

    if v309 ~= 0 and v309 > -1.1754943508222875E-38 and v309 < 1.1754943508222875E-38 then
        local v311 = math.abs(v309) * 7.1362384635298E+44
        local v312 = math.floor(v311)
        local v313 = v311 - v312

        v310 = (if v313 > 0.5 or v313 == 0.5 and v312 % 2 == 1 then v312 + 1 else v312) * 1.401298464324817E-45

        if v309 < 0 then
            v310 = -v310
        end
    else
        buffer.writef32(v1, 0, v309)
        v310 = buffer.readf32(v1, 0)
    end

    local v314, v315, v316, v317

    if v163 < v310 then
        local v318 = 1 - p56
        local v319 = v299 * v318 + v305 * p56
        local v320 = v300 * v318 + v306 * p56
        local v321 = v301 * v318 + v307 * p56
        local v322 = v302 * v318 + v308 * p56
        local v324 = 1 / math.sqrt(v319 * v319 + v320 * v320 + v321 * v321 + v322 * v322)

        v314 = v319 * v324
        v315 = v320 * v324
        v316 = v321 * v324
        v317 = v322 * v324
    else
        local v325 = math.acos(v309)
        local v327 = math.sin(v325 * (1 - p56))
        local v329 = math.sin(v325 * p56)
        local v330 = 1 / math.sin(v325)

        v314 = (v299 * v327 + v305 * v329) * v330
        v315 = (v300 * v327 + v306 * v329) * v330
        v316 = (v301 * v327 + v307 * v329) * v330
        v317 = (v302 * v327 + v308 * v329) * v330
    end

    local rotation3 = p53.rotation

    rotation3[1] = v314
    rotation3[2] = v315
    rotation3[3] = v316
    rotation3[4] = v317

    local scale = p54.scale
    local scale2 = p55.scale
    local scale3 = p53.scale
    local v331 = scale[1] * v293 + scale2[1] * p56
    local v332 = scale[2] * v293 + scale2[2] * p56
    local v333 = scale[3] * v293 + scale2[3] * p56

    scale3[1] = v331
    scale3[2] = v332
    scale3[3] = v333
end

local v334

function t1.present_into(p57, p58, p59, p60, p61, p62) -- line: 687
    -- upvalues: v9 (copy), t1 (copy), AnimationStatus (copy), new_transform (copy), v161 (copy), v162 (copy), binding_local_into (copy), blend_into (copy), v334 (ref)
    if not p62.ready then
        return {}
    end

    local v335 = v334

    if v335 == nil then
        v335 = t1.render_basis()
        v334 = v335
    end

    local v336, v337, v338 = v9.Presentation.view(p58, p60, p61)

    if v336 == nil then
        local v339 = table.create(#p59.render_pose)

        for v340, v341 in ipairs(p59.render_pose) do
            v339[v340] = t1.native_matrix(v341)
        end

        return AnimationStatus.pose_transforms(p62, v339)
    end

    local n1 = 0

    for _, v342 in ipairs(p62.bindings) do
        n1 += 1

        local v343 = p57[n1]

        if v343 ~= nil then
            v343[1] = v342.entity
        else
            v343 = {
                v342.entity,
                (new_transform())
            }
            p57[n1] = v343
        end

        binding_local_into(v161, v336, v342, v335)
        binding_local_into(v162, v337, v342, v335)
        blend_into(v343[2], v161, v162, v338)
    end

    for i = #p57, n1 + 1, -1 do
        p57[i] = nil
    end

    return p57
end

local t12 = {}
local t13 = {}
local t14 = {}
local v344 = new_transform()

local function snapshot_locals(p63, p64, p65) -- line: 752
    -- upvalues: new_mat4 (copy), v160 (copy), mat4_mul_into (copy), mat4_inverse_into (copy), transform_from_matrix_into (copy), t12 (copy), t13 (copy), t14 (copy), v344 (copy)
    local v345 = #p64
    local locals = p63.locals

    if locals == nil or #locals ~= v345 * 7 then
        locals = table.create(v345 * 7, 0)
        p63.locals = locals
    end

    local bones = p63.bones
    local v346 = #bones

    for i = #t12 + 1, v346 do
        t12[i] = new_mat4()
        t13[i] = new_mat4()
    end

    for i = 1, v346 do
        t14[i] = false
    end

    for i = 1, v346 do
        mat4_mul_into(t12[i], bones[i], p65)
    end

    local translation, rotation = v344.translation, v344.rotation
    local n2 = 0

    for _, v347 in ipairs(p64) do
        local v348 = t12[v347.bone + 1]
        local parent_bone = v347.parent_bone

        if parent_bone ~= nil then
            local v349 = parent_bone + 1

            if not t14[v349] then
                mat4_inverse_into(t13[v349], t12[v349])
                t14[v349] = true
            end

            mat4_mul_into(v160, t13[v349], v348)
            transform_from_matrix_into(v344, v160)
        else
            transform_from_matrix_into(v344, v348)
        end

        local v350 = rotation[1]
        local v351 = rotation[2]
        local v352 = rotation[3]
        local v353 = rotation[4]
        local v355 = 1 / math.sqrt(v350 * v350 + v351 * v351 + v352 * v352 + v353 * v353)
        local v356 = n2 + 1
        local v357 = n2 + 2
        local v358 = n2 + 3
        local v359 = translation[1]
        local v360 = translation[2]
        local v361 = translation[3]

        locals[v356] = v359
        locals[v357] = v360
        locals[v358] = v361

        local v362 = n2 + 4
        local v363 = n2 + 5
        local v364 = n2 + 6
        local v365 = n2 + 7
        local v366 = v350 * v355
        local v367 = v351 * v355
        local v368 = v352 * v355
        local v369 = v353 * v355

        locals[v362] = v366
        locals[v363] = v367
        locals[v364] = v368
        locals[v365] = v369
        n2 += 7
    end

    p63.locals_for = p64

    return locals
end

t1.snapshot_locals = snapshot_locals

function t1.present_locals(p66, p67, _, p69, p70, p71) -- line: 802
    -- upvalues: v1 (copy), v9 (copy), t1 (copy), v163 (copy), v334 (ref), snapshot_locals (copy)
    if not p71.ready or p69.active then
        return nil
    end

    local v370, v371, v372 = v9.Presentation.view(p67, p69, p70)

    if v370 == nil then
        return nil
    end

    local bindings = p71.bindings
    local v373 = v334

    if v373 == nil then
        v373 = t1.render_basis()
        v334 = v373
    end

    local v374 = if v371.locals_for == bindings then v371.locals else snapshot_locals(v371, bindings, v373)
    local v375 = #v374

    if v372 == 1 then
        for i = 1, v375 do
            p66[i] = v374[i]
        end
    else
        local v376 = if v370.locals_for == bindings then v370.locals else snapshot_locals(v370, bindings, v373)
        local v377 = 1 - v372

        for i = 0, v375 - 7, 7 do
            local v378 = i + 2
            local v379 = i + 3
            local v380 = v376[i + 1] * v377 + v374[i + 1] * v372
            local v381 = v376[i + 2] * v377 + v374[i + 2] * v372
            local v382 = v376[i + 3] * v377 + v374[i + 3] * v372

            p66[i + 1] = v380
            p66[v378] = v381
            p66[v379] = v382

            local v383 = v376[i + 4]
            local v384 = v376[i + 5]
            local v385 = v376[i + 6]
            local v386 = v376[i + 7]
            local v387 = v374[i + 4]
            local v388 = v374[i + 5]
            local v389 = v374[i + 6]
            local v390 = v374[i + 7]
            local v391 = v383 * v387 + v384 * v388 + v385 * v389 + v386 * v390

            if v391 < 0 then
                v387 = -v387
                v388 = -v388
                v389 = -v389
                v390 = -v390
                v391 = -v391
            end

            local v392

            if v391 ~= 0 and v391 > -1.1754943508222875E-38 and v391 < 1.1754943508222875E-38 then
                local v393 = math.abs(v391) * 7.1362384635298E+44
                local v394 = math.floor(v393)
                local v395 = v393 - v394

                v392 = (if v395 > 0.5 or v395 == 0.5 and v394 % 2 == 1 then v394 + 1 else v394) * 1.401298464324817E-45

                if v391 < 0 then
                    v392 = -v392
                end
            else
                buffer.writef32(v1, 0, v391)
                v392 = buffer.readf32(v1, 0)
            end

            if v163 < v392 then
                local v396 = 1 - v372
                local v397 = v383 * v396 + v387 * v372
                local v398 = v384 * v396 + v388 * v372
                local v399 = v385 * v396 + v389 * v372
                local v400 = v386 * v396 + v390 * v372
                local v402 = 1 / math.sqrt(v397 * v397 + v398 * v398 + v399 * v399 + v400 * v400)
                local v403 = i + 5
                local v404 = i + 6
                local v405 = i + 7
                local v406 = v397 * v402
                local v407 = v398 * v402
                local v408 = v399 * v402
                local v409 = v400 * v402

                p66[i + 4] = v406
                p66[v403] = v407
                p66[v404] = v408
                p66[v405] = v409
            else
                local v410 = math.acos(v391)
                local v412 = math.sin(v410 * (1 - v372))
                local v414 = math.sin(v410 * v372)
                local v415 = 1 / math.sin(v410)

                p66[i + 4] = (v383 * v412 + v387 * v414) * v415
                p66[i + 5] = (v384 * v412 + v388 * v414) * v415
                p66[i + 6] = (v385 * v412 + v389 * v414) * v415
                p66[i + 7] = (v386 * v412 + v390 * v414) * v415
            end
        end
    end

    return v375 / 7
end

function t1.render_basis() -- line: 859
    return {
        { 1, 0, 0, 0 },
        { 0, 0, -1, 0 },
        { 0, 1, 0, 0 },
        { 0, 0, 0, 1 }
    }
end

function t1.native_matrix(p72) -- line: 870
    return {
        {
            p72[1][1],
            p72[1][2],
            p72[1][3],
            0
        },
        {
            p72[2][1],
            p72[2][2],
            p72[2][3],
            0
        },
        {
            p72[3][1],
            p72[3][2],
            p72[3][3],
            0
        },
        {
            p72[4][1],
            p72[4][2],
            p72[4][3],
            1
        }
    }
end

return t1
