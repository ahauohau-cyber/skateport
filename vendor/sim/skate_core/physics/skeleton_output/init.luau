-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/skeleton_output/board")
local compose_affine = import("skate_core/physics/skeleton_animation_record").compose_affine
local inverse_rigid = import("skate_core/animation/foot_ik/transforms").inverse_rigid
local t1 = {
    SkeletonOutput = {},
    Input = {}
}

local function compose_xyz(p1, p2) -- line: 38
    local v2 = p1[1]
    local v3 = p1[2]
    local v4 = p1[3]
    local v5 = p1[4]
    local v6 = v2[1]
    local v7 = v2[2]
    local v8 = v2[3]
    local v9 = v3[1]
    local v10 = v3[2]
    local v11 = v3[3]
    local v12 = v4[1]
    local v13 = v4[2]
    local v14 = v4[3]
    local v15 = p2[1]
    local v16 = p2[2]
    local v17 = p2[3]
    local v18 = p2[4]
    local v19 = v15[1]
    local v20 = v15[2]
    local v21 = v15[3]
    local v22 = v16[1]
    local v23 = v16[2]
    local v24 = v16[3]
    local v25 = v17[1]
    local v26 = v17[2]
    local v27 = v17[3]
    local v28 = v18[1]
    local v29 = v18[2]
    local v30 = v18[3]

    return v21 * v12 + (v20 * v9 + v19 * v6), v21 * v13 + (v20 * v10 + v19 * v7), v21 * v14 + (v20 * v11 + v19 * v8), v24 * v12 + (v23 * v9 + v22 * v6), v24 * v13 + (v23 * v10 + v22 * v7), v24 * v14 + (v23 * v11 + v22 * v8), v27 * v12 + (v26 * v9 + v25 * v6), v27 * v13 + (v26 * v10 + v25 * v7), v27 * v14 + (v26 * v11 + v25 * v8), v12 * v30 + (v9 * v29 + (v6 * v28 + v5[1])), v13 * v30 + (v10 * v29 + (v7 * v28 + v5[2])), v14 * v30 + (v11 * v29 + (v8 * v28 + v5[3]))
end

local function compose_from_xyz(p3, p4, p5, p6, p7, p8, p9, p10, p11, p12, p13, p14, p15) -- line: 64
    local v31 = p3[1]
    local v32 = p3[2]
    local v33 = p3[3]
    local v34 = p3[4]
    local v35 = v31[1]
    local v36 = v31[2]
    local v37 = v31[3]
    local v38 = v31[4]
    local v39 = v32[1]
    local v40 = v32[2]
    local v41 = v32[3]
    local v42 = v32[4]
    local v43 = v33[1]
    local v44 = v33[2]
    local v45 = v33[3]
    local v46 = v33[4]

    return {
        {
            p6 * v43 + (p5 * v39 + p4 * v35),
            p6 * v44 + (p5 * v40 + p4 * v36),
            p6 * v45 + (p5 * v41 + p4 * v37),
            p6 * v46 + (p5 * v42 + p4 * v38)
        },
        {
            p9 * v43 + (p8 * v39 + p7 * v35),
            p9 * v44 + (p8 * v40 + p7 * v36),
            p9 * v45 + (p8 * v41 + p7 * v37),
            p9 * v46 + (p8 * v42 + p7 * v38)
        },
        {
            p12 * v43 + (p11 * v39 + p10 * v35),
            p12 * v44 + (p11 * v40 + p10 * v36),
            p12 * v45 + (p11 * v41 + p10 * v37),
            p12 * v46 + (p11 * v42 + p10 * v38)
        },
        {
            v43 * p15 + (v39 * p14 + (v35 * p13 + v34[1])),
            v44 * p15 + (v40 * p14 + (v36 * p13 + v34[2])),
            v45 * p15 + (v41 * p14 + (v37 * p13 + v34[3])),
            v46 * p15 + (v42 * p14 + (v38 * p13 + v34[4]))
        }
    }
end

local function compose_inverse_rigid(p16, p17) -- line: 100
    local v47 = p16[1]
    local v48 = p16[2]
    local v49 = p16[3]
    local v50 = p16[4]
    local v51 = v47[1]
    local v52 = v48[1]
    local v53 = v49[1]
    local v54 = v47[2]
    local v55 = v48[2]
    local v56 = v49[2]
    local v57 = v47[3]
    local v58 = v48[3]
    local v59 = v49[3]
    local v60 = 0 - v50[1]
    local v61 = 0 - v50[2]
    local v62 = 0 - v50[3]
    local v63 = v60 * v51 + (v61 * v54 + v62 * v57)
    local v64 = v60 * v52 + (v61 * v55 + v62 * v58)
    local v65 = v60 * v53 + (v61 * v56 + v62 * v59)
    local v66 = v60 * 0 + (v61 * 0 + v62 * 0)
    local v67 = p17[1]
    local v68 = p17[2]
    local v69 = p17[3]
    local v70 = p17[4]
    local v71 = v67[1]
    local v72 = v67[2]
    local v73 = v67[3]
    local v74 = v68[1]
    local v75 = v68[2]
    local v76 = v68[3]
    local v77 = v69[1]
    local v78 = v69[2]
    local v79 = v69[3]
    local v80 = v70[1]
    local v81 = v70[2]
    local v82 = v70[3]

    return {
        {
            v73 * v57 + (v72 * v54 + v71 * v51),
            v73 * v58 + (v72 * v55 + v71 * v52),
            v73 * v59 + (v72 * v56 + v71 * v53),
            v73 * 0 + (v72 * 0 + v71 * 0)
        },
        {
            v76 * v57 + (v75 * v54 + v74 * v51),
            v76 * v58 + (v75 * v55 + v74 * v52),
            v76 * v59 + (v75 * v56 + v74 * v53),
            v76 * 0 + (v75 * 0 + v74 * 0)
        },
        {
            v79 * v57 + (v78 * v54 + v77 * v51),
            v79 * v58 + (v78 * v55 + v77 * v52),
            v79 * v59 + (v78 * v56 + v77 * v53),
            v79 * 0 + (v78 * 0 + v77 * 0)
        },
        {
            v57 * v82 + (v54 * v81 + (v51 * v80 + v63)),
            v58 * v82 + (v55 * v81 + (v52 * v80 + v64)),
            v59 * v82 + (v56 * v81 + (v53 * v80 + v65)),
            0 * v82 + (0 * v81 + (0 * v80 + v66))
        }
    }
end

function t1.SkeletonOutput.publish(p18, p19, p20, p21) -- line: 150
    -- upvalues: rt (copy), v1 (copy), compose_xyz (copy), compose_from_xyz (copy), compose_inverse_rigid (copy)
    local v83 = #p20 ~= #p21

    if not v83 then
        for _, v84 in ipairs(p18.bone_indices) do
            if #p20 <= v84 then
                v83 = true
                break
            end
        end
    end

    if not v83 then
        for _, v85 in ipairs(v1.BoneIndices.all(p18.board_bones)) do
            if #p21 <= v85 then
                v83 = true
                break
            end
        end
    end

    if v83 then
        error("physical pose output does not match the stock animation hierarchy", 0)
    end

    for i = 0, 23 do
        p20[p18.bone_indices[i + 1] + 1] = compose_from_xyz(p19.world_to_animation, compose_xyz(p19.physical_parts[i + 1], p18.geometry.inverse_part_frames[i + 1]))
    end

    for i = 23, 0, -1 do
        local v86 = p18.bone_indices[i + 1]
        local v87 = p18.geometry.parents[i + 1]

        if v87 ~= nil then
            p21[v86 + 1] = compose_inverse_rigid(p20[p18.bone_indices[v87 + 1] + 1], p20[v86 + 1])
        else
            p21[v86 + 1] = rt.copy(p20[v86 + 1])
        end
    end

    v1.publish(p19.board, p18.board_settings, p18.board_bones, p21)
end

local function compose_from_xyz_into(p22, p23, p24, p25, p26, p27, p28, p29, p30, p31, p32, p33, p34, p35) -- line: 195
    local v88 = p23[1]
    local v89 = p23[2]
    local v90 = p23[3]
    local v91 = p23[4]
    local v92 = v88[1]
    local v93 = v88[2]
    local v94 = v88[3]
    local v95 = v88[4]
    local v96 = v89[1]
    local v97 = v89[2]
    local v98 = v89[3]
    local v99 = v89[4]
    local v100 = v90[1]
    local v101 = v90[2]
    local v102 = v90[3]
    local v103 = v90[4]
    local v104 = v91[1]
    local v105 = v91[2]
    local v106 = v91[3]
    local v107 = v91[4]
    local v108 = p22[1]

    v108[1] = p26 * v100 + (p25 * v96 + p24 * v92)
    v108[2] = p26 * v101 + (p25 * v97 + p24 * v93)
    v108[3] = p26 * v102 + (p25 * v98 + p24 * v94)
    v108[4] = p26 * v103 + (p25 * v99 + p24 * v95)

    local v109 = p22[2]

    v109[1] = p29 * v100 + (p28 * v96 + p27 * v92)
    v109[2] = p29 * v101 + (p28 * v97 + p27 * v93)
    v109[3] = p29 * v102 + (p28 * v98 + p27 * v94)
    v109[4] = p29 * v103 + (p28 * v99 + p27 * v95)

    local v110 = p22[3]

    v110[1] = p32 * v100 + (p31 * v96 + p30 * v92)
    v110[2] = p32 * v101 + (p31 * v97 + p30 * v93)
    v110[3] = p32 * v102 + (p31 * v98 + p30 * v94)
    v110[4] = p32 * v103 + (p31 * v99 + p30 * v95)

    local v111 = p22[4]

    v111[1] = v100 * p35 + (v96 * p34 + (v92 * p33 + v104))
    v111[2] = v101 * p35 + (v97 * p34 + (v93 * p33 + v105))
    v111[3] = v102 * p35 + (v98 * p34 + (v94 * p33 + v106))
    v111[4] = v103 * p35 + (v99 * p34 + (v95 * p33 + v107))
end

function t1.SkeletonOutput.publish_owned_globals(p36, p37, p38, p39) -- line: 232
    -- upvalues: rt (copy), v1 (copy), compose_xyz (copy), compose_inverse_rigid (copy), compose_from_xyz_into (copy)
    local v112 = #p38 ~= #p39

    if not v112 then
        for _, v113 in ipairs(p36.bone_indices) do
            if #p38 <= v113 then
                v112 = true
                break
            end
        end
    end

    if not v112 then
        for _, v114 in ipairs(v1.BoneIndices.all(p36.board_bones)) do
            if #p39 <= v114 then
                v112 = true
                break
            end
        end
    end

    if v112 then
        error("physical pose output does not match the stock animation hierarchy", 0)
    end

    for i = 0, 23 do
        compose_from_xyz_into(p38[p36.bone_indices[i + 1] + 1], p37.world_to_animation, compose_xyz(p37.physical_parts[i + 1], p36.geometry.inverse_part_frames[i + 1]))
    end

    for i = 23, 0, -1 do
        local v115 = p36.bone_indices[i + 1]
        local v116 = p36.geometry.parents[i + 1]

        if v116 ~= nil then
            p39[v115 + 1] = compose_inverse_rigid(p38[p36.bone_indices[v116 + 1] + 1], p38[v115 + 1])
        else
            p39[v115 + 1] = rt.copy(p38[v115 + 1])
        end
    end

    v1.publish(p37.board, p36.board_settings, p36.board_bones, p39)
end

local function compose_inverse_rigid_into(p40, p41, p42) -- line: 278
    local v117 = p41[1]
    local v118 = p41[2]
    local v119 = p41[3]
    local v120 = p41[4]
    local v121 = v117[1]
    local v122 = v118[1]
    local v123 = v119[1]
    local v124 = v117[2]
    local v125 = v118[2]
    local v126 = v119[2]
    local v127 = v117[3]
    local v128 = v118[3]
    local v129 = v119[3]
    local v130 = 0 - v120[1]
    local v131 = 0 - v120[2]
    local v132 = 0 - v120[3]
    local v133 = v130 * v121 + (v131 * v124 + v132 * v127)
    local v134 = v130 * v122 + (v131 * v125 + v132 * v128)
    local v135 = v130 * v123 + (v131 * v126 + v132 * v129)
    local v136 = v130 * 0 + (v131 * 0 + v132 * 0)
    local v137 = p42[1]
    local v138 = p42[2]
    local v139 = p42[3]
    local v140 = p42[4]
    local v141 = v137[1]
    local v142 = v137[2]
    local v143 = v137[3]
    local v144 = v138[1]
    local v145 = v138[2]
    local v146 = v138[3]
    local v147 = v139[1]
    local v148 = v139[2]
    local v149 = v139[3]
    local v150 = v140[1]
    local v151 = v140[2]
    local v152 = v140[3]
    local v153 = p40[1]

    v153[1] = v143 * v127 + (v142 * v124 + v141 * v121)
    v153[2] = v143 * v128 + (v142 * v125 + v141 * v122)
    v153[3] = v143 * v129 + (v142 * v126 + v141 * v123)
    v153[4] = v143 * 0 + (v142 * 0 + v141 * 0)

    local v154 = p40[2]

    v154[1] = v146 * v127 + (v145 * v124 + v144 * v121)
    v154[2] = v146 * v128 + (v145 * v125 + v144 * v122)
    v154[3] = v146 * v129 + (v145 * v126 + v144 * v123)
    v154[4] = v146 * 0 + (v145 * 0 + v144 * 0)

    local v155 = p40[3]

    v155[1] = v149 * v127 + (v148 * v124 + v147 * v121)
    v155[2] = v149 * v128 + (v148 * v125 + v147 * v122)
    v155[3] = v149 * v129 + (v148 * v126 + v147 * v123)
    v155[4] = v149 * 0 + (v148 * 0 + v147 * 0)

    local v156 = p40[4]

    v156[1] = v127 * v152 + (v124 * v151 + (v121 * v150 + v133))
    v156[2] = v128 * v152 + (v125 * v151 + (v122 * v150 + v134))
    v156[3] = v129 * v152 + (v126 * v151 + (v123 * v150 + v135))
    v156[4] = 0 * v152 + (0 * v151 + (0 * v150 + v136))
end

function t1.SkeletonOutput.publish_owned(p43, p44, p45, p46) -- line: 332
    -- upvalues: v1 (copy), compose_xyz (copy), compose_from_xyz_into (copy), compose_inverse_rigid_into (copy)
    local bone_indices = p43.bone_indices
    local v157 = #p45
    local v158 = #p46
    local v159 = v157 ~= v158

    if not v159 then
        for _, v160 in ipairs(bone_indices) do
            if v157 <= v160 then
                v159 = true
                break
            end
        end
    end

    local v161

    if v159 then
        v161 = v159
    else
        local board_bones = p43.board_bones

        v161 = v158 <= board_bones.front_truck
            or v158 <= board_bones.back_truck
            or v158 <= board_bones.front_left_wheel
            or v158 <= board_bones.front_right_wheel
            or v158 <= board_bones.back_left_wheel
            or v158 <= board_bones.back_right_wheel
    end

    if v161 then
        error("physical pose output does not match the stock animation hierarchy", 0)
    end

    local geometry = p43.geometry
    local physical_parts = p44.physical_parts
    local inverse_part_frames = geometry.inverse_part_frames
    local world_to_animation = p44.world_to_animation

    for i = 1, 24 do
        compose_from_xyz_into(p45[bone_indices[i] + 1], world_to_animation, compose_xyz(physical_parts[i], inverse_part_frames[i]))
    end

    local parents = geometry.parents

    for i = 24, 1, -1 do
        local v162 = bone_indices[i]
        local v163 = parents[i]
        local v164 = p45[v162 + 1]

        if v163 == nil then
            local v165 = p46[v162 + 1]
            local v166 = v165[1]
            local v167 = v164[1]
            local v168 = v167[1]
            local v169 = v167[2]
            local v170 = v167[3]
            local v171 = v167[4]

            v166[1] = v168
            v166[2] = v169
            v166[3] = v170
            v166[4] = v171

            local v172 = v165[2]
            local v173 = v164[2]
            local v174 = v173[1]
            local v175 = v173[2]
            local v176 = v173[3]
            local v177 = v173[4]

            v172[1] = v174
            v172[2] = v175
            v172[3] = v176
            v172[4] = v177

            local v178 = v165[3]
            local v179 = v164[3]
            local v180 = v179[1]
            local v181 = v179[2]
            local v182 = v179[3]
            local v183 = v179[4]

            v178[1] = v180
            v178[2] = v181
            v178[3] = v182
            v178[4] = v183

            local v184 = v165[4]
            local v185 = v164[4]
            local v186 = v185[1]
            local v187 = v185[2]
            local v188 = v185[3]
            local v189 = v185[4]

            v184[1] = v186
            v184[2] = v187
            v184[3] = v188
            v184[4] = v189
            continue
        end

        compose_inverse_rigid_into(p46[v162 + 1], p45[bone_indices[v163 + 1] + 1], v164)
    end

    v1.publish_owned(p44.board, p43.board_settings, p43.board_bones, p46)
end

function t1.SkeletonOutput.publish_reference(p47, p48, p49, p50) -- line: 392
    -- upvalues: rt (copy), v1 (copy), compose_affine (copy), inverse_rigid (copy)
    local v190 = #p49 ~= #p50

    if not v190 then
        for _, v191 in ipairs(p47.bone_indices) do
            if #p49 <= v191 then
                v190 = true
                break
            end
        end
    end

    if not v190 then
        for _, v192 in ipairs(v1.BoneIndices.all(p47.board_bones)) do
            if #p50 <= v192 then
                v190 = true
                break
            end
        end
    end

    if v190 then
        error("physical pose output does not match the stock animation hierarchy", 0)
    end

    for i = 0, 23 do
        local v193 = compose_affine(p48.physical_parts[i + 1], p47.geometry.inverse_part_frames[i + 1])

        p49[p47.bone_indices[i + 1] + 1] = compose_affine(p48.world_to_animation, v193)
    end

    for i = 23, 0, -1 do
        local v194 = p47.bone_indices[i + 1]
        local v195 = p47.geometry.parents[i + 1]

        if v195 ~= nil then
            p50[v194 + 1] = compose_affine(inverse_rigid(p49[p47.bone_indices[v195 + 1] + 1]), p49[v194 + 1])
        else
            p50[v194 + 1] = rt.copy(p49[v194 + 1])
        end
    end

    v1.publish(p48.board, p47.board_settings, p47.board_bones, p50)
end

return t1
