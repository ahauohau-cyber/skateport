-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/player/offboard/contact_toolkit/analyzer_math")
local v2 = import("skate_core/player/offboard/contact_toolkit/profile")
local v3

local function toolkit() -- line: 13
    -- upvalues: import (copy), v3 (ref)
    if v3 == nil then
        v3 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v3
end

local function dot(p1, p2) -- line: 19
    -- upvalues: import (copy), v3 (ref)
    if v3 == nil then
        v3 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v3.dot(p1, p2)
end

local function length(p3) -- line: 22
    -- upvalues: import (copy), v3 (ref)
    if v3 == nil then
        v3 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v3.length(p3)
end

local function scale(p4, p5) -- line: 25
    -- upvalues: import (copy), v3 (ref)
    if v3 == nil then
        v3 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v3.scale(p4, p5)
end

local function sub(p6, p7) -- line: 28
    -- upvalues: import (copy), v3 (ref)
    if v3 == nil then
        v3 = import("skate_core/player/offboard/contact_toolkit")
    end

    return v3.sub(p6, p7)
end

local clamp_normal, madd, plane_segment = v1.clamp_normal, v1.madd, v1.plane_segment
local sort = v2.sort
local infill
local v4 = false
local t1 = {}

function t1.set_reference(p8) -- line: 46
    -- upvalues: v4 (ref)
    v4 = p8
end

local reciprocal_estimate = import("skate_core/physics/native_arithmetic").reciprocal_estimate
local estimate = import("skate_core/physics/reciprocal_sqrt").estimate

local function length3(p9, p10, p11) -- line: 62
    -- upvalues: estimate (copy)
    local v5 = p9 * p9 + p10 * p10 + p11 * p11

    if v5 == 0 then
        return 0
    end

    local v6 = estimate(v5)
    local v7 = v6 * 0.5 * (-v5 * (v6 * v6) + 1) + v6

    return v5 * (v7 * 0.5 * (-v5 * (v7 * v7) + 1) + v7)
end

local function reciprocal2(p12) -- line: 72
    -- upvalues: reciprocal_estimate (copy)
    local v8 = reciprocal_estimate(p12)
    local v9 = v8 * (-v8 * p12 + 1) + v8

    return v9 * (-v9 * p12 + 1) + v9
end

local t2 = {
    0, 0, 0, 0
}
local t3 = {
    0, 0, 0, 0
}
local t4 = {
    0, 0, 0, 0
}

function t1.insert_obstacles(p13, p14) -- line: 101
    -- upvalues: rt (copy), import (copy), v3 (ref), sort (copy), t1 (copy), v4 (ref)
    if v4 then
        return t1.insert_obstacles_reference(p13, p14)
    end

    if v3 == nil then
        v3 = import("skate_core/player/offboard/contact_toolkit")
    end

    local insert = v3.Samples.insert
    local ground, other = p14.ground, p14.other

    for i = 1, #ground - 1 do
        local v10 = ground[i]
        local v11 = ground[i + 1]
        local forward_distance = v10.forward_distance
        local forward_distance2 = v11.forward_distance
        local sort_distance = v10.sort_distance
        local sort_distance2 = v11.sort_distance
        local v12 = 0
        local v13 = rt.fmin(v10.height, v11.height)
        local v14 = rt.fmax(v10.height, v11.height)

        while v12 < #other do
            local v15 = other[v12 + 1]
            local forward_distance3 = v15.forward_distance

            if forward_distance3 < forward_distance or forward_distance2 < forward_distance3 then
                v12 += 1
            else
                local height = v15.height

                if height < v13 then
                    v15.flags = bit32.bor(v15.flags, 2)
                    v12 += 1
                else
                    local sort_distance3 = v15.sort_distance

                    if not (height < v14) and not (sort_distance3 < sort_distance) and not (sort_distance2 < sort_distance3) then
                        v15.flags = bit32.bor(v15.flags, 2)

                        local v16 = v12 + 1
                        local v17 = v12

                        while v16 < #other and math.abs(forward_distance3 - other[v16 + 1].forward_distance) <= 0.001 do
                            local v19 = other[v16 + 1]
                            local height = v19.height

                            v19.flags = bit32.bor(v19.flags, 2)

                            if v14 <= height and height < other[v12 + 1].height then
                                v12 = v16
                            end

                            if other[v17 + 1].height < height then
                                v17 = v16
                            end

                            v16 += 1
                        end

                        local v20 = other[v12 + 1]

                        v20.flags = bit32.bor(bit32.band(v20.flags, 4294967293), 1)

                        local v22 = other[v17 + 1]

                        v22.flags = bit32.bor(bit32.band(v22.flags, 4294967293), 1)

                        local v24 = other[v12 + 1]
                        local height = v24.height

                        insert(p14, p13, v24.position, v24.normal, 1, v24.sort_distance, 1)

                        if v14 < height then
                            v13 = v14
                            v14 = height
                        elseif v13 < height then
                            v13 = height
                        end

                        if v12 ~= v17 then
                            local v25 = other[v17 + 1]

                            insert(p14, p13, v25.position, v25.normal, 1, v25.sort_distance, 1)
                        end

                        v12 = v16 + 1
                    else
                        v12 += 1
                    end
                end
            end
        end
    end

    sort(p14.ground)
end

function t1.correct_normals(p15, p16) -- line: 176
    -- upvalues: rt (copy), clamp_normal (copy), sort (copy), t1 (copy), infill (ref), v4 (ref), t2 (copy)
    if v4 then
        return t1.correct_normals_reference(p15, p16)
    end

    local up, forward = p15.up, p15.forward
    local v26 = up[1]
    local v27 = up[2]
    local v28 = up[3]
    local position = p15.position
    local v29 = position[1]
    local v30 = position[2]
    local v31 = position[3]

    for _, v32 in p16.ground do
        local position = v32.position
        local v33 = position[1]
        local v34 = position[2]
        local v35 = position[3]
        local v36 = (v33 - v29) * v26 + (v34 - v30) * v27 + (v35 - v31) * v28

        v31 = v35

        if math.abs(v36) < 0.001 then
            v32.normal = rt.copy(up)
        else
            local v37

            if v36 <= 0 then
                v37 = forward
            else
                v37 = t2

                local v38 = forward[1] * -1
                local v39 = forward[2] * -1
                local v40 = forward[3] * -1
                local v41 = forward[4] * -1

                t2[1] = v38
                t2[2] = v39
                t2[3] = v40
                t2[4] = v41
            end

            v32.normal = clamp_normal(v37, up, v32.normal)
        end

        v29 = v33
        v30 = v34
    end

    local ground, other = p16.ground, p16.other

    for i = 1, #ground - 1 do
        local v42 = ground[i]
        local v43 = ground[i + 1]

        for j = 0, #other - 1 do
            local v44 = other[j + 1]

            if bit32.band(v44.flags, 3) == 0 and v42.forward_distance <= v44.forward_distance and v44.forward_distance <= v43.forward_distance then
                infill(p15, p16, v42, v43, j)
            end
        end
    end

    sort(p16.ground)
end

function t1.infill(p17, p18, p19, p20, p21) -- line: 219
    -- upvalues: rt (copy), import (copy), v3 (ref), clamp_normal (copy), plane_segment (copy), t1 (copy), v4 (ref), estimate (copy), t2 (copy), t3 (copy), t4 (copy)
    if v4 then
        return t1.infill_reference(p17, p18, p19, p20, p21)
    end

    local v45 = p18.other[p21 + 1]
    local normal = p19.normal
    local normal2 = p20.normal
    local normal3 = v45.normal
    local position = p19.position
    local position2 = p20.position
    local position3 = v45.position
    local v46 = normal[1]
    local v47 = normal[2]
    local v48 = normal[3]
    local v49 = normal[4]
    local v50 = normal2[1]
    local v51 = normal2[2]
    local v52 = normal2[3]
    local v53 = normal2[4]
    local v54 = position[1]
    local v55 = position[2]
    local v56 = position[3]
    local v57 = position[4]
    local v58 = position2[1]
    local v59 = position2[2]
    local v60 = position2[3]
    local v61 = position2[4]
    local v62, v63, v64, v65

    if v46 * v50 + v47 * v51 + v48 * v52 > 0.99 and v46 * normal3[1] + v47 * normal3[2] + v48 * normal3[3] > 0.99 and math.abs((v58 - v54) * v50 + (v59 - v55) * v51 + (v60 - v56) * v52) < 0.01 then
        v62 = position3[1] - v54
        v63 = position3[2] - v55
        v64 = position3[3] - v56

        local v67 = v62 * v62 + v63 * v63 + v64 * v64

        if v67 == 0 then
            v65 = 0
        else
            local v68 = estimate(v67)
            local v69 = v68 * 0.5 * (-v67 * (v68 * v68) + 1) + v68

            v65 = v67 * (v69 * 0.5 * (-v67 * (v69 * v69) + 1) + v69)
        end

        if v65 < 0.01 then
            v62 = position3[1] - v58
            v63 = position3[2] - v59
            v64 = position3[3] - v60
        end

        if math.abs(v62 * v50 + v63 * v51 + v64 * v52) < 0.01 then
            return
        end
    end

    local forward = p17.forward
    local v71 = forward

    if p20.height > p19.height then
        v71 = t2

        local v72 = forward[1] * -1
        local v73 = forward[2] * -1
        local v74 = forward[3] * -1
        local v75 = forward[4] * -1

        t2[1] = v72
        t2[2] = v73
        t2[3] = v74
        t2[4] = v75
    end

    local v76 = clamp_normal(v71, p17.up, normal3)
    local v77 = v58 - v54
    local v78 = v59 - v55
    local v79 = v60 - v56
    local v80 = v61 - v57
    local v81 = v46 * v77 + v47 * v78 + v48 * v79
    local v82 = (v77 - v46 * v81) * 1.1 + v54
    local v83 = (v78 - v47 * v81) * 1.1 + v55
    local v84 = (v79 - v48 * v81) * 1.1 + v56
    local v85 = (v80 - v49 * v81) * 1.1 + v57

    t3[1] = v82
    t3[2] = v83
    t3[3] = v84
    t3[4] = v85

    local v86 = v50 * v77 + v51 * v78 + v52 * v79
    local v87 = v58 - (v77 - v50 * v86) * 1.1
    local v88 = v59 - (v78 - v51 * v86) * 1.1
    local v89 = v60 - (v79 - v52 * v86) * 1.1
    local v90 = v61 - (v80 - v53 * v86) * 1.1

    t4[1] = v87
    t4[2] = v88
    t4[3] = v89
    t4[4] = v90

    local v91 = plane_segment(position3, v76, position, t3)
    local v92 = plane_segment(position3, v76, t4, position2)
    local position4, up = p17.position, p17.up

    for i = 1, 2 do
        local v93 = if i == 1 then v91 else v92

        if v93 ~= nil then
            local v95 = v93[1]
            local v96 = v93[2]
            local v97 = v93[3]
            local v98 = v95 - position4[1]
            local v99 = v96 - position4[2]
            local v100 = v97 - position4[3]
            local v101 = forward[1] * v98 + forward[2] * v99 + forward[3] * v100
            local v102 = up[1] * v98 + up[2] * v99 + up[3] * v100
            local v94

            if p19.forward_distance <= v101 and v101 <= p20.forward_distance and rt.fmin(p19.height, p20.height) <= v102 and v102 <= rt.fmax(p19.height, p20.height) then
                local v103 = v95 - v54
                local v104 = v96 - v55
                local v105 = v97 - v56
                local v106 = v103 * v103 + v104 * v104 + v105 * v105

                if v106 == 0 then
                    v94 = 0
                else
                    local v107 = estimate(v106)
                    local v108 = v107 * 0.5 * (-v106 * (v107 * v107) + 1) + v107

                    v94 = v106 * (v108 * 0.5 * (-v106 * (v108 * v108) + 1) + v108)
                end

                local v109 = v77 * v77 + v78 * v78 + v79 * v79
                local v110

                if v109 == 0 then
                    v110 = 0
                else
                    local v111 = estimate(v109)
                    local v112 = v111 * 0.5 * (-v109 * (v111 * v111) + 1) + v111

                    v110 = v109 * (v112 * 0.5 * (-v109 * (v112 * v112) + 1) + v112)
                end

                local v113 = v94 / v110 * (p20.sort_distance - p19.sort_distance) + p19.sort_distance

                if v3 == nil then
                    v3 = import("skate_core/player/offboard/contact_toolkit")
                end

                v3.Samples.insert(p18, p17, v93, v76, 1, v113, 2)
                p18.other[p21 + 1].flags = bit32.bor(p18.other[p21 + 1].flags, 4)
            end
        end
    end
end

function t1.insert_obstacles_reference(p22, p23) -- line: 294
    -- upvalues: rt (copy), import (copy), v3 (ref), sort (copy)
    if v3 == nil then
        v3 = import("skate_core/player/offboard/contact_toolkit")
    end

    local Samples = v3.Samples
    local v115 = rt.copy(p23.ground)

    for i = 1, #v115 - 1 do
        local v116 = v115[i]
        local v117 = v115[i + 1]
        local v118 = rt.fmin(v116.height, v117.height)
        local v119 = rt.fmax(v116.height, v117.height)
        local v120 = 0

        while v120 < #p23.other do
            local v121 = rt.copy(p23.other[v120 + 1])

            if v116.forward_distance > v121.forward_distance or v121.forward_distance > v117.forward_distance then
                v120 += 1
            elseif v121.height < v118 then
                p23.other[v120 + 1].flags = bit32.bor(p23.other[v120 + 1].flags, 2)
                v120 += 1
            elseif not (v121.height < v119) and not (v121.sort_distance < v116.sort_distance) and not (v121.sort_distance > v117.sort_distance) then
                p23.other[v120 + 1].flags = bit32.bor(p23.other[v120 + 1].flags, 2)

                local v124 = v120 + 1
                local v125 = v120

                while v124 < #p23.other and math.abs(v121.forward_distance - p23.other[v124 + 1].forward_distance) <= 0.001 do
                    local v127 = rt.copy(p23.other[v124 + 1])

                    p23.other[v124 + 1].flags = bit32.bor(p23.other[v124 + 1].flags, 2)

                    if v119 <= v127.height and p23.other[v120 + 1].height > v127.height then
                        v120 = v124
                    end

                    if v127.height > p23.other[v125 + 1].height then
                        v125 = v124
                    end

                    v124 += 1
                end

                for _, v129 in { v120, v125 } do
                    p23.other[v129 + 1].flags = bit32.bor(bit32.band(p23.other[v129 + 1].flags, 4294967293), 1)
                end

                local v132 = rt.copy(p23.other[v120 + 1])

                Samples.insert(p23, p22, v132.position, v132.normal, 1, v132.sort_distance, 1)

                if v119 < v132.height then
                    v118 = v119
                    v119 = v132.height
                elseif v118 < v132.height then
                    v118 = v132.height
                end

                if v120 ~= v125 then
                    local v133 = rt.copy(p23.other[v125 + 1])

                    Samples.insert(p23, p22, v133.position, v133.normal, 1, v133.sort_distance, 1)
                end

                v120 = v124 + 1
            else
                v120 += 1
            end
        end
    end

    sort(p23.ground)
end

function t1.correct_normals_reference(p24, p25) -- line: 356
    -- upvalues: rt (copy), import (copy), v3 (ref), clamp_normal (copy), sort (copy), t1 (copy)
    local v134 = rt.copy(p24.position)

    for _, v135 in p25.ground do
        local position = v135.position

        if v3 == nil then
            v3 = import("skate_core/player/offboard/contact_toolkit")
        end

        local v136 = v3.sub(position, v134)
        local up = p24.up

        if v3 == nil then
            v3 = import("skate_core/player/offboard/contact_toolkit")
        end

        local v137 = v3.dot(v136, up)

        if math.abs(v137) < 0.001 then
            v135.normal = rt.copy(p24.up)
        else
            local v138

            if v137 <= 0 then
                v138 = p24.forward
            else
                local forward = p24.forward

                if v3 == nil then
                    v3 = import("skate_core/player/offboard/contact_toolkit")
                end

                v138 = v3.scale(forward, -1)
            end

            v135.normal = clamp_normal(v138, p24.up, v135.normal)
        end

        v134 = rt.copy(v135.position)
    end

    local v139 = rt.copy(p25.ground)

    for i = 1, #v139 - 1 do
        for j = 0, #p25.other - 1 do
            local v140 = p25.other[j + 1]

            if bit32.band(v140.flags, 3) == 0 and v139[i].forward_distance <= v140.forward_distance and v140.forward_distance <= v139[i + 1].forward_distance then
                t1.infill_reference(p24, p25, v139[i], v139[i + 1], j)
            end
        end
    end

    sort(p25.ground)
end

function t1.infill_reference(p26, p27, p28, p29, p30) -- line: 388
    -- upvalues: rt (copy), import (copy), v3 (ref), clamp_normal (copy), madd (copy), plane_segment (copy)
    if v3 == nil then
        v3 = import("skate_core/player/offboard/contact_toolkit")
    end

    local Samples = v3.Samples
    local v141 = rt.copy(p27.other[p30 + 1])
    local normal = p28.normal
    local normal2 = p29.normal

    if v3 == nil then
        v3 = import("skate_core/player/offboard/contact_toolkit")
    end

    if v3.dot(normal, normal2) > 0.99 then
        local normal = p28.normal
        local normal2 = v141.normal

        if v3 == nil then
            v3 = import("skate_core/player/offboard/contact_toolkit")
        end

        if v3.dot(normal, normal2) > 0.99 then
            local position = p29.position
            local position2 = p28.position

            if v3 == nil then
                v3 = import("skate_core/player/offboard/contact_toolkit")
            end

            local v142 = v3.sub(position, position2)
            local normal = p29.normal

            if v3 == nil then
                v3 = import("skate_core/player/offboard/contact_toolkit")
            end

            if math.abs((v3.dot(v142, normal))) < 0.01 then
                local position = v141.position
                local position2 = p28.position

                if v3 == nil then
                    v3 = import("skate_core/player/offboard/contact_toolkit")
                end

                local v144 = v3.sub(position, position2)

                if v3 == nil then
                    v3 = import("skate_core/player/offboard/contact_toolkit")
                end

                if v3.length(v144) < 0.01 then
                    local position = v141.position
                    local position2 = p29.position

                    if v3 == nil then
                        v3 = import("skate_core/player/offboard/contact_toolkit")
                    end

                    v144 = v3.sub(position, position2)
                end

                local normal = p29.normal

                if v3 == nil then
                    v3 = import("skate_core/player/offboard/contact_toolkit")
                end

                if math.abs((v3.dot(v144, normal))) < 0.01 then
                    return
                end
            end
        end
    end

    local v146

    if p29.height > p28.height then
        local forward = p26.forward

        if v3 == nil then
            v3 = import("skate_core/player/offboard/contact_toolkit")
        end

        v146 = v3.scale(forward, -1)
    else
        v146 = p26.forward
    end

    local v147 = clamp_normal(v146, p26.up, v141.normal)
    local position = p29.position
    local position2 = p28.position

    if v3 == nil then
        v3 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v148 = v3.sub(position, position2)
    local normal3, normal4 = p28.normal, p28.normal

    if v3 == nil then
        v3 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v149 = v3.dot(normal4, v148)

    if v3 == nil then
        v3 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v150 = v3.scale(normal3, v149)

    if v3 == nil then
        v3 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v151 = madd(v3.sub(v148, v150), 1.1, p28.position)
    local position3, normal5, normal6 = p29.position, p29.normal, p29.normal

    if v3 == nil then
        v3 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v152 = v3.dot(normal6, v148)

    if v3 == nil then
        v3 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v153 = v3.scale(normal5, v152)

    if v3 == nil then
        v3 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v154 = v3.sub(v148, v153)

    if v3 == nil then
        v3 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v155 = v3.scale(v154, 1.1)

    if v3 == nil then
        v3 = import("skate_core/player/offboard/contact_toolkit")
    end

    local v156 = v3.sub(position3, v155)
    local v157 = plane_segment(v141.position, v147, p28.position, v151)
    local v158 = plane_segment(v141.position, v147, v156, p29.position)

    for i = 1, 2 do
        local v159 = if i == 1 then v157 else v158

        if v159 ~= nil then
            local position = p26.position

            if v3 == nil then
                v3 = import("skate_core/player/offboard/contact_toolkit")
            end

            local v160 = v3.sub(v159, position)
            local forward = p26.forward

            if v3 == nil then
                v3 = import("skate_core/player/offboard/contact_toolkit")
            end

            local v161 = v3.dot(forward, v160)
            local up = p26.up

            if v3 == nil then
                v3 = import("skate_core/player/offboard/contact_toolkit")
            end

            local v162 = v3.dot(up, v160)

            if p28.forward_distance <= v161 and v161 <= p29.forward_distance and rt.fmin(p28.height, p29.height) <= v162 and v162 <= rt.fmax(p28.height, p29.height) then
                local position = p28.position

                if v3 == nil then
                    v3 = import("skate_core/player/offboard/contact_toolkit")
                end

                local v163 = v3.sub(v159, position)

                if v3 == nil then
                    v3 = import("skate_core/player/offboard/contact_toolkit")
                end

                local v164 = v3.length(v163)

                if v3 == nil then
                    v3 = import("skate_core/player/offboard/contact_toolkit")
                end

                local v165 = v164 / v3.length(v148) * (p29.sort_distance - p28.sort_distance) + p28.sort_distance

                Samples.insert(p27, p26, v159, v147, 1, v165, 2)
                p27.other[p30 + 1].flags = bit32.bor(p27.other[p30 + 1].flags, 4)
            end
        end
    end
end

infill = t1.infill

return t1
