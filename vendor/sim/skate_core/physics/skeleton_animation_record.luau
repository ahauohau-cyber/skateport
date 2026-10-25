-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/physics/rigid_body")
local v2 = import("skate_core/math")
local basis_from_quaternion = v1.basis_from_quaternion
local Vector3 = v2.Vector3
local t1 = {
    AnimationPartTransform = {},
    IDENTITY = {
        { 1, 0, 0, 0 },
        { 0, 1, 0, 0 },
        { 0, 0, 1, 0 },
        { 0, 0, 0, 0 }
    }
}

function t1.physics_bone_frame(p1, p2) -- line: 37
    -- upvalues: rt (copy), basis_from_quaternion (copy)
    local columns = basis_from_quaternion({
        x = p1[1],
        y = p1[2],
        z = p1[3],
        w = p1[4]
    }).columns
    local v7 = columns[1]
    local v8 = columns[2]
    local v9 = columns[3]

    return {
        {
            v7[1],
            v7[2],
            v7[3],
            v9[3]
        },
        {
            v8[1],
            v8[2],
            v8[3],
            v8[1]
        },
        {
            v9[1],
            v9[2],
            v9[3],
            v7[2]
        },
        rt.copy(p2)
    }
end

function t1.map_animation_parts(p3, p4, p5) -- line: 56
    -- upvalues: t1 (copy)
    for i = 1, 24 do
        if p4[i] >= #p3 then
            error("physics skeleton bone index is outside the animation hierarchy", 0)
        end
    end

    local v10 = table.create(24)

    for i = 0, 23 do
        local v11 = p3[p4[i + 1] + 1]
        local v12 = p5[i + 1]
        local v13 = table.create(4)

        for j = 0, 3 do
            if j == 3 then
                v13[j + 1] = t1.transform_point(v11, v12[4])
            else
                local v14 = table.create(4)

                for k = 0, 3 do
                    local v15 = v12[j + 1][1] * v11[1][k + 1]
                    local v16 = v12[j + 1][2] * v11[2][k + 1] + v15

                    v14[k + 1] = v12[j + 1][3] * v11[3][k + 1] + v16
                end

                v13[j + 1] = v14
            end
        end

        v10[i + 1] = v13
    end

    return v10
end

t1.SkeletonAnimationMasses = {}

function t1.SkeletonAnimationMasses.from_bone_data(p6, p7, p8) -- line: 96
    -- upvalues: t1 (copy)
    local v17 = table.create(24)

    for i = 0, 23 do
        if i ~= 0 and (not (p7[i + 1] >= 3) or i == 1 and p8) then
            v17[i + 1] = p6[i + 1].x * p6[i + 1].y * p6[i + 1].z
        else
            v17[i + 1] = 0
        end
    end

    return t1.SkeletonAnimationMasses.normalize(v17)
end

function t1.SkeletonAnimationMasses.normalize(p9) -- line: 110
    -- upvalues: rt (copy)
    local v18 = #p9 - 1
    local n1 = 0

    for i = 0, v18 do
        local v19 = p9[i + 1]

        if i % 8 == 0 or i % 8 == 7 then
            n1 = v19 + n1
        else
            n1 += v19
        end
    end

    local v20 = 1 / n1
    local v21 = table.create(#p9)

    for i = 1, #p9 do
        v21[i] = p9[i] * v20
    end

    return {
        part_weights = rt.copy(p9),
        total = n1,
        fractional = v21
    }
end

t1.SkeletonAnimationRecord = {}

function t1.SkeletonAnimationRecord.default() -- line: 138
    -- upvalues: rt (copy), t1 (copy)
    return {
        reset_scalar = 0,
        pose = rt.filled(24, t1.IDENTITY),
        centre_of_mass = { 0, 0, 0, 0 },
        centre_of_mass_delta = { 0, 0, 0, 0 },
        com_to_deck_world = { 0, 0, 0, 0 },
        com_to_deck_world_delta = { 0, 0, 0, 0 }
    }
end

function t1.SkeletonAnimationRecord.reset_history(p10) -- line: 153
    p10.centre_of_mass = { 0, 0, 0, 0 }
    p10.centre_of_mass_delta = { 0, 0, 0, 0 }
    p10.com_to_deck_world = { 0, 0, 0, 0 }
    p10.com_to_deck_world_delta = { 0, 0, 0, 0 }
end

function t1.SkeletonAnimationRecord.update(p11, p12, p13, p14) -- line: 200
    -- upvalues: rt (copy)
    local pose = p11.pose
    local v22 = #p12
    local v23 = type(pose) == "table" and pose ~= p12 and #pose == v22

    if v23 then
        for i = 1, v22 do
            local v24 = p12[i]
            local v25 = pose[i]

            if type(v24) ~= "table" or type(v25) ~= "table" or v24 == v25 or #v24 ~= 4 or #v25 ~= 4 then
                v23 = false
                break
            end

            local v26 = v24[1]
            local v27 = v24[2]
            local v28 = v24[3]
            local v29 = v24[4]
            local v30 = v25[1]
            local v31 = v25[2]
            local v32 = v25[3]
            local v33 = v25[4]

            if type(v26) ~= "table"
                or type(v27) ~= "table"
                or type(v28) ~= "table"
                or type(v29) ~= "table"
                or type(v30) ~= "table"
                or type(v31) ~= "table"
                or type(v32) ~= "table"
                or type(v33) ~= "table"
                or #v26 ~= 4
                or #v27 ~= 4
                or #v28 ~= 4
                or #v29 ~= 4
                or #v30 ~= 4
                or #v31 ~= 4
                or #v32 ~= 4
                or #v33 ~= 4 then
                v23 = false
                break
            end

            local v34 = v26[1]
            local v35 = v26[2]
            local v36 = v26[3]
            local v37 = v26[4]

            v30[1] = v34
            v30[2] = v35
            v30[3] = v36
            v30[4] = v37

            local v38 = v27[1]
            local v39 = v27[2]
            local v40 = v27[3]
            local v41 = v27[4]

            v31[1] = v38
            v31[2] = v39
            v31[3] = v40
            v31[4] = v41

            local v42 = v28[1]
            local v43 = v28[2]
            local v44 = v28[3]
            local v45 = v28[4]

            v32[1] = v42
            v32[2] = v43
            v32[3] = v44
            v32[4] = v45

            local v46 = v29[1]
            local v47 = v29[2]
            local v48 = v29[3]
            local v49 = v29[4]

            v33[1] = v46
            v33[2] = v47
            v33[3] = v48
            v33[4] = v49
        end
    end

    if not v23 then
        pose = rt.copy(p12)
        p11.pose = pose
    end

    local fractional = p14.fractional
    local n2 = 0
    local n3 = 0
    local n4 = 0
    local n5 = 0

    for i = 1, math.min(#pose, #fractional) do
        local v53 = pose[i][4]
        local v54 = fractional[i]

        n2 = v53[1] * v54 + n2
        n3 = v53[2] * v54 + n3
        n4 = v53[3] * v54 + n4
        n5 = v53[4] * v54 + n5
    end

    local centre_of_mass, centre_of_mass_delta, com_to_deck_world, com_to_deck_world_delta = p11.centre_of_mass, p11.centre_of_mass_delta, p11.com_to_deck_world, p11.com_to_deck_world_delta
    local v55 = type(centre_of_mass) == "table" and type(centre_of_mass_delta) == "table" and type(com_to_deck_world) == "table" and type(com_to_deck_world_delta) == "table" and centre_of_mass ~= centre_of_mass_delta and centre_of_mass ~= com_to_deck_world and centre_of_mass ~= com_to_deck_world_delta and centre_of_mass_delta ~= com_to_deck_world and centre_of_mass_delta ~= com_to_deck_world_delta and com_to_deck_world ~= com_to_deck_world_delta and #centre_of_mass == 4 and #centre_of_mass_delta == 4 and #com_to_deck_world == 4 and #com_to_deck_world_delta == 4

    if v55 then
        local v56 = n2 - centre_of_mass[1]
        local v57 = n3 - centre_of_mass[2]
        local v58 = n4 - centre_of_mass[3]
        local v59 = n5 - centre_of_mass[4]

        centre_of_mass_delta[1] = v56
        centre_of_mass_delta[2] = v57
        centre_of_mass_delta[3] = v58
        centre_of_mass_delta[4] = v59
        centre_of_mass[1] = n2
        centre_of_mass[2] = n3
        centre_of_mass[3] = n4
        centre_of_mass[4] = n5
    else
        p11.centre_of_mass_delta = {
            n2 - centre_of_mass[1],
            n3 - centre_of_mass[2],
            n4 - centre_of_mass[3],
            n5 - centre_of_mass[4]
        }
        p11.centre_of_mass = { n2, n3, n4, n5 }
    end

    local v60 = p13[1]
    local v61 = p13[2]
    local v62 = p13[3]
    local v63 = p13[4]
    local v64 = pose[1][4]
    local v65 = v64[1]
    local v66 = v64[2]
    local v67 = v64[3]
    local v68 = v62[1] * n4 + (v61[1] * n3 + (v60[1] * n2 + v63[1])) - (v62[1] * v67 + (v61[1] * v66 + (v60[1] * v65 + v63[1])))
    local v69 = v62[2] * n4 + (v61[2] * n3 + (v60[2] * n2 + v63[2])) - (v62[2] * v67 + (v61[2] * v66 + (v60[2] * v65 + v63[2])))
    local v70 = v62[3] * n4 + (v61[3] * n3 + (v60[3] * n2 + v63[3])) - (v62[3] * v67 + (v61[3] * v66 + (v60[3] * v65 + v63[3])))
    local v71 = v62[4] * n4 + (v61[4] * n3 + (v60[4] * n2 + v63[4])) - (v62[4] * v67 + (v61[4] * v66 + (v60[4] * v65 + v63[4])))
    local reset_scalar = p11.reset_scalar

    if v55 then
        local v72 = (v68 - com_to_deck_world[1]) * reset_scalar
        local v73 = (v69 - com_to_deck_world[2]) * reset_scalar
        local v74 = (v70 - com_to_deck_world[3]) * reset_scalar
        local v75 = (v71 - com_to_deck_world[4]) * reset_scalar

        com_to_deck_world_delta[1] = v72
        com_to_deck_world_delta[2] = v73
        com_to_deck_world_delta[3] = v74
        com_to_deck_world_delta[4] = v75
        com_to_deck_world[1] = v68
        com_to_deck_world[2] = v69
        com_to_deck_world[3] = v70
        com_to_deck_world[4] = v71
    else
        local com_to_deck_world = p11.com_to_deck_world

        p11.com_to_deck_world_delta = {
            (v68 - com_to_deck_world[1]) * reset_scalar,
            (v69 - com_to_deck_world[2]) * reset_scalar,
            (v70 - com_to_deck_world[3]) * reset_scalar,
            (v71 - com_to_deck_world[4]) * reset_scalar
        }
        p11.com_to_deck_world = { v68, v69, v70, v71 }
    end

    p11.reset_scalar = 1
end

function t1.SkeletonAnimationRecord.update_reference(p15, p16, p17, p18) -- line: 324
    -- upvalues: rt (copy), t1 (copy)
    p15.pose = rt.copy(p16)

    local t2 = {
        0, 0, 0, 0
    }

    for i = 1, math.min(#p15.pose, #p18.fractional) do
        local v78 = p15.pose[i]
        local v79 = p18.fractional[i]

        t2[1] = v78[4][1] * v79 + t2[1]
        t2[2] = v78[4][2] * v79 + t2[2]
        t2[3] = v78[4][3] * v79 + t2[3]
        t2[4] = v78[4][4] * v79 + t2[4]
    end

    p15.centre_of_mass_delta = {
        t2[1] - p15.centre_of_mass[1],
        t2[2] - p15.centre_of_mass[2],
        t2[3] - p15.centre_of_mass[3],
        t2[4] - p15.centre_of_mass[4]
    }
    p15.centre_of_mass = rt.copy(t2)

    local v80 = t1.transform_point(p17, t2)
    local v81 = t1.transform_point(p17, p15.pose[1][4])
    local t3 = {
        v80[1] - v81[1],
        v80[2] - v81[2],
        v80[3] - v81[3],
        v80[4] - v81[4]
    }

    p15.com_to_deck_world_delta = {
        (t3[1] - p15.com_to_deck_world[1]) * p15.reset_scalar,
        (t3[2] - p15.com_to_deck_world[2]) * p15.reset_scalar,
        (t3[3] - p15.com_to_deck_world[3]) * p15.reset_scalar,
        (t3[4] - p15.com_to_deck_world[4]) * p15.reset_scalar
    }
    p15.com_to_deck_world = t3
    p15.reset_scalar = 1
end

function t1.copy_pose_buffered(p19, p20) -- line: 378
    -- upvalues: rt (copy)
    if type(p20) ~= "table" then
        return rt.copy(p20), p19
    end

    local v82 = #p20
    local v83, v84, v85

    if p19 ~= nil then
        if p19.count == v82 then
            local array, frames = p19.array, p19.frames

            if p20 == array then
                v85 = false
            elseif #array == v82 then
                v83 = array
                v84 = frames
                v85 = true
            else
                v85 = false
            end
        else
            v85 = true
        end
    else
        v85 = true
    end

    if not v85 then
        return rt.copy(p20), p19
    end

    for i = 1, v82 do
        local v86 = p20[i]

        if type(v86) ~= "table" or v86[5] ~= nil or v84 ~= nil and v86 == v84[i] then
            return rt.copy(p20), p19
        end

        local v87 = v86[1]
        local v88 = v86[2]
        local v89 = v86[3]
        local v90 = v86[4]

        if type(v87) ~= "table"
            or type(v88) ~= "table"
            or type(v89) ~= "table"
            or type(v90) ~= "table"
            or #v87 ~= 4
            or #v88 ~= 4
            or #v89 ~= 4
            or #v90 ~= 4 then
            return rt.copy(p20), p19
        end
    end

    local v91

    if v84 ~= nil then
        v91 = p19
    else
        v83 = table.create(v82)
        v84 = table.create(v82)

        for i = 1, v82 do
            v84[i] = {
                { 0, 0, 0, 0 },
                { 0, 0, 0, 0 },
                { 0, 0, 0, 0 },
                { 0, 0, 0, 0 }
            }
        end

        v91 = {
            count = v82,
            array = v83,
            frames = v84
        }
    end

    for i = 1, v82 do
        local v92 = p20[i]
        local v93 = v84[i]

        v83[i] = v93

        local v94 = v92[1]
        local v95 = v92[2]
        local v96 = v92[3]
        local v97 = v92[4]
        local v98 = v93[1]
        local v99 = v93[2]
        local v100 = v93[3]
        local v101 = v93[4]
        local v102 = v94[1]
        local v103 = v94[2]
        local v104 = v94[3]
        local v105 = v94[4]

        v98[1] = v102
        v98[2] = v103
        v98[3] = v104
        v98[4] = v105

        local v106 = v95[1]
        local v107 = v95[2]
        local v108 = v95[3]
        local v109 = v95[4]

        v99[1] = v106
        v99[2] = v107
        v99[3] = v108
        v99[4] = v109

        local v110 = v96[1]
        local v111 = v96[2]
        local v112 = v96[3]
        local v113 = v96[4]

        v100[1] = v110
        v100[2] = v111
        v100[3] = v112
        v100[4] = v113

        local v114 = v97[1]
        local v115 = v97[2]
        local v116 = v97[3]
        local v117 = v97[4]

        v101[1] = v114
        v101[2] = v115
        v101[3] = v116
        v101[4] = v117
    end

    return v83, v91
end

function t1.SkeletonAnimationRecord.com_to_deck(p21) -- line: 434
    -- upvalues: Vector3 (copy)
    local com_to_deck_world = p21.com_to_deck_world

    return Vector3.new(com_to_deck_world[1], com_to_deck_world[2], com_to_deck_world[3])
end

function t1.transform_point_reference(p22, p23) -- line: 439
    local v118 = table.create(4)

    for i = 0, 3 do
        local v119 = p22[1][i + 1] * p23[1] + p22[4][i + 1]
        local v120 = p22[2][i + 1] * p23[2] + v119

        v118[i + 1] = p22[3][i + 1] * p23[3] + v120
    end

    return v118
end

function t1.transform_point(p24, p25) -- line: 452
    local v121 = p24[1]
    local v122 = p24[2]
    local v123 = p24[3]
    local v124 = p24[4]
    local v125 = p25[1]
    local v126 = p25[2]
    local v127 = p25[3]

    return {
        v123[1] * v127 + (v122[1] * v126 + (v121[1] * v125 + v124[1])),
        v123[2] * v127 + (v122[2] * v126 + (v121[2] * v125 + v124[2])),
        v123[3] * v127 + (v122[3] * v126 + (v121[3] * v125 + v124[3])),
        v123[4] * v127 + (v122[4] * v126 + (v121[4] * v125 + v124[4]))
    }
end

function t1.compose_affine(p26, p27) -- line: 474
    local v128 = p26[1]
    local v129 = p26[2]
    local v130 = p26[3]
    local v131 = p26[4]
    local v132 = v128[1]
    local v133 = v128[2]
    local v134 = v128[3]
    local v135 = v128[4]
    local v136 = v129[1]
    local v137 = v129[2]
    local v138 = v129[3]
    local v139 = v129[4]
    local v140 = v130[1]
    local v141 = v130[2]
    local v142 = v130[3]
    local v143 = v130[4]
    local v144 = p27[1]
    local v145 = p27[2]
    local v146 = p27[3]
    local v147 = p27[4]
    local v148 = v144[1]
    local v149 = v144[2]
    local v150 = v144[3]
    local v151 = v145[1]
    local v152 = v145[2]
    local v153 = v145[3]
    local v154 = v146[1]
    local v155 = v146[2]
    local v156 = v146[3]
    local v157 = v147[1]
    local v158 = v147[2]
    local v159 = v147[3]

    return {
        {
            v150 * v140 + (v149 * v136 + v148 * v132),
            v150 * v141 + (v149 * v137 + v148 * v133),
            v150 * v142 + (v149 * v138 + v148 * v134),
            v150 * v143 + (v149 * v139 + v148 * v135)
        },
        {
            v153 * v140 + (v152 * v136 + v151 * v132),
            v153 * v141 + (v152 * v137 + v151 * v133),
            v153 * v142 + (v152 * v138 + v151 * v134),
            v153 * v143 + (v152 * v139 + v151 * v135)
        },
        {
            v156 * v140 + (v155 * v136 + v154 * v132),
            v156 * v141 + (v155 * v137 + v154 * v133),
            v156 * v142 + (v155 * v138 + v154 * v134),
            v156 * v143 + (v155 * v139 + v154 * v135)
        },
        {
            v140 * v159 + (v136 * v158 + (v132 * v157 + v131[1])),
            v141 * v159 + (v137 * v158 + (v133 * v157 + v131[2])),
            v142 * v159 + (v138 * v158 + (v134 * v157 + v131[3])),
            v143 * v159 + (v139 * v158 + (v135 * v157 + v131[4]))
        }
    }
end

function t1.compose_affine_into(p28, p29, p30) -- line: 520
    local v160 = p29[1]
    local v161 = p29[2]
    local v162 = p29[3]
    local v163 = p29[4]
    local v164 = v160[1]
    local v165 = v160[2]
    local v166 = v160[3]
    local v167 = v160[4]
    local v168 = v161[1]
    local v169 = v161[2]
    local v170 = v161[3]
    local v171 = v161[4]
    local v172 = v162[1]
    local v173 = v162[2]
    local v174 = v162[3]
    local v175 = v162[4]
    local v176 = v163[1]
    local v177 = v163[2]
    local v178 = v163[3]
    local v179 = v163[4]
    local v180 = p30[1]
    local v181 = p30[2]
    local v182 = p30[3]
    local v183 = p30[4]
    local v184 = v180[1]
    local v185 = v180[2]
    local v186 = v180[3]
    local v187 = v181[1]
    local v188 = v181[2]
    local v189 = v181[3]
    local v190 = v182[1]
    local v191 = v182[2]
    local v192 = v182[3]
    local v193 = v183[1]
    local v194 = v183[2]
    local v195 = v183[3]
    local v196 = p28[1]

    v196[1] = v186 * v172 + (v185 * v168 + v184 * v164)
    v196[2] = v186 * v173 + (v185 * v169 + v184 * v165)
    v196[3] = v186 * v174 + (v185 * v170 + v184 * v166)
    v196[4] = v186 * v175 + (v185 * v171 + v184 * v167)

    local v197 = p28[2]

    v197[1] = v189 * v172 + (v188 * v168 + v187 * v164)
    v197[2] = v189 * v173 + (v188 * v169 + v187 * v165)
    v197[3] = v189 * v174 + (v188 * v170 + v187 * v166)
    v197[4] = v189 * v175 + (v188 * v171 + v187 * v167)

    local v198 = p28[3]

    v198[1] = v192 * v172 + (v191 * v168 + v190 * v164)
    v198[2] = v192 * v173 + (v191 * v169 + v190 * v165)
    v198[3] = v192 * v174 + (v191 * v170 + v190 * v166)
    v198[4] = v192 * v175 + (v191 * v171 + v190 * v167)

    local v199 = p28[4]

    v199[1] = v172 * v195 + (v168 * v194 + (v164 * v193 + v176))
    v199[2] = v173 * v195 + (v169 * v194 + (v165 * v193 + v177))
    v199[3] = v174 * v195 + (v170 * v194 + (v166 * v193 + v178))
    v199[4] = v175 * v195 + (v171 * v194 + (v167 * v193 + v179))

    return p28
end

function t1.compose_affine_reference(p31, p32) -- line: 563
    -- upvalues: t1 (copy)
    local v200 = table.create(4)

    for i = 0, 3 do
        if i == 3 then
            v200[i + 1] = t1.transform_point(p31, p32[4])
        else
            local v201 = table.create(4)

            for j = 0, 3 do
                local v202 = p32[i + 1][1] * p31[1][j + 1]
                local v203 = p32[i + 1][2] * p31[2][j + 1] + v202

                v201[j + 1] = p32[i + 1][3] * p31[3][j + 1] + v203
            end

            v200[i + 1] = v201
        end
    end

    return v200
end

return t1
