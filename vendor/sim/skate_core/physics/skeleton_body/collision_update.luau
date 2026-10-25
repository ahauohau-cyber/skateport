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
local v9 = import("skate_core/physics/skeleton_body/collision_vector")
local add, clamp_length, cross, dot = v9.add, v9.clamp_length, v9.cross, v9.dot
local length, normalize, scale, sub = v9.length, v9.normalize, v9.scale, v9.sub
local transform = v9.transform

local function collision_feedback() -- line: 39
    -- upvalues: import (copy)
    return import("skate_core/physics/skeleton_body/collision_feedback")
end

local t1 = {
    REGIONS = {
        18446744073709552000, 0, 1, 2, 2, 2, 1, 3,
        3, 3, 1, 1, 1, 1, 1, 6,
        6, 4, 4, 7, 7, 5, 5, 1
    },
    SkeletonCollisionFeedback = {}
}
local SkeletonCollisionFeedback = t1.SkeletonCollisionFeedback
local v10 = false

function t1.set_b3_twin(p3) -- line: 108
    -- upvalues: v10 (ref)
    v10 = p3
end

local REGIONS = t1.REGIONS

local function inverse_length_s(p4) -- line: 116
    local v11 = 1 / math.sqrt(p4)
    local v12 = v11 * 0.5 * (-p4 * (v11 * v11) + 1) + v11

    return v12 * 0.5 * (-p4 * (v12 * v12) + 1) + v12
end

local function record_force_lanes(p5, p6, p7, p8, p9, p10, p11, p12, p13) -- line: 123
    -- upvalues: rt (copy), REGIONS (copy)
    local part = p6.part
    local v13 = p5.bones[part + 1]
    local v14 = p5.regions[REGIONS[part + 1] + 1]
    local v15 = if p7 then v13.specific_force else v13.force
    local normal = p6.normal
    local v16, v17, v18, v19

    if v15 < p12 or v14.force < p12 then
        local v20 = normal[1]
        local v21 = normal[2]
        local v22 = normal[3]
        local v23 = normal[4]

        v16 = -p10 * v21 + p9 * v22
        v17 = -p8 * v22 + p10 * v20
        v18 = -p9 * v20 + p8 * v21
        v19 = -p11 * v23 + p11 * v23
    else
        v16 = 0
        v17 = 0
        v18 = 0
        v19 = 0
    end

    if v15 < p12 then
        local v24 = #normal == 4

        if p7 then
            v13.specific_force = p12

            local specific_normal = v13.specific_normal

            if not v24 or #specific_normal ~= 4 or specific_normal == normal then
                v13.specific_normal = rt.copy(normal)
            else
                local v25 = normal[1]
                local v26 = normal[2]
                local v27 = normal[3]
                local v28 = normal[4]

                specific_normal[1] = v25
                specific_normal[2] = v26
                specific_normal[3] = v27
                specific_normal[4] = v28
            end

            local specific_tangent = v13.specific_tangent

            if #specific_tangent == 4 then
                specific_tangent[1] = v16
                specific_tangent[2] = v17
                specific_tangent[3] = v18
                specific_tangent[4] = v19
            else
                v13.specific_tangent = { v16, v17, v18, v19 }
            end

            v13.specific_tag = p6.tag
        else
            v13.force = p12

            local normal2 = v13.normal

            if v24 and #normal2 == 4 and normal2 ~= normal then
                local v29 = normal[1]
                local v30 = normal[2]
                local v31 = normal[3]
                local v32 = normal[4]

                normal2[1] = v29
                normal2[2] = v30
                normal2[3] = v31
                normal2[4] = v32
            else
                v13.normal = rt.copy(normal)
            end

            local tangent = v13.tangent

            if #tangent == 4 then
                tangent[1] = v16
                tangent[2] = v17
                tangent[3] = v18
                tangent[4] = v19
            else
                v13.tangent = { v16, v17, v18, v19 }
            end

            local point = p6.point
            local point2 = v13.point

            if #point == 4 and #point2 == 4 and point2 ~= point then
                local v33 = point[1]
                local v34 = point[2]
                local v35 = point[3]
                local v36 = point[4]

                point2[1] = v33
                point2[2] = v34
                point2[3] = v35
                point2[4] = v36
            else
                v13.point = rt.copy(point)
            end

            v13.tag = p6.tag
        end

        local other_group = p6.other_group
        local groups = v13.groups

        groups[1] = groups[1] or other_group == 8
        groups[2] = groups[2] or other_group == 11
        groups[3] = groups[3] or other_group == 5

        local v37 = groups[4]

        if v37 then
            groups[4] = v37
        else
            groups[4] = not (other_group == 8 or other_group == 11 or other_group == 5)
        end
    end

    if not (v14.force < p12) then
        return
    end

    local v38 = v16 * v16 + v17 * v17 + v18 * v18
    local v39 = 1 / math.sqrt(v38)
    local v40 = v39 * 0.5 * (-v38 * (v39 * v39) + 1) + v39
    local v41 = v38 * (v40 * 0.5 * (-v38 * (v40 * v40) + 1) + v40)

    v14.force = p12
    v14.weighted_force = p13
    v14.tangent_speed = if v38 == 0 then 0 else v41
    v14.material_flags = bit32.band(p6.tag, 127)
    v14.normal = rt.copy(normal)
    v14.part = part
end

function t1.SkeletonCollisionFeedback.update(p14, p15, p16) -- line: 212
    -- upvalues: rt (copy), v1 (copy), SkeletonCollisionFeedback (copy), v10 (ref), record_force_lanes (copy)
    if v10 then
        return SkeletonCollisionFeedback.update_r3(p14, p15, p16)
    end

    SkeletonCollisionFeedback.begin_frame(p14, p15)

    local flags = p15.reference_velocity
    local settings = flags[1]
    local ragdoll = flags[2]
    local offboard = flags[3]
    local v42 = flags[4]
    local v43 = settings * settings + ragdoll * ragdoll + offboard * offboard
    local v44 = 1 / math.sqrt(v43)

    v44 = v44 * 0.5 * (-v43 * (v44 * v44) + 1) + v44
    v44 = v44 * 0.5 * (-v43 * (v44 * v44) + 1) + v44

    local v45 = if v43 == 0 then 0 else v43 * v44
    local v46, v47, v48, v49

    if v45 > 1E-06 then
        v46 = settings * v44
        v47 = ragdoll * v44
        v48 = offboard * v44
        v49 = v42 * v44
    else
        v46 = 0
        v47 = 0
        v48 = 0
        v49 = 0
    end

    flags = p14.flags
    settings = p14.settings
    ragdoll = p15.ragdoll
    offboard = p15.offboard

    for _, v50 in ipairs(p16) do
        if not (v50.part < 24) then
            error("SkeletonCollision report part exceeds native24-part array", 0)
        end

        local part = v50.part
        local v52 = bit32.band(bit32.rshift(v50.tag, 7), 31)
        local other_group = v50.other_group
        local v51 = v50.point
        local normal = v50.normal

        flags.any = true

        if other_group == 4 and (part == 15 or part == 16 or part == 19 or part == 20) then
            flags.foot_board = true
        end

        if v52 == 6 then
            flags.material_6 = true
        end

        if v52 == 12 then
            flags.material_12 = true
            p14.material_12_height = v51[2]
        end

        local side_a = v51[1]
        local v53 = v51[2]
        local v54 = v51[3]
        local v55 = normal[1]
        local v56 = normal[2]
        local v57 = normal[3]

        if ragdoll then
            v51 = false
            SkeletonCollisionFeedback.observe_normal(p14, ragdoll, v50, v52)

            local v58, v59, v60

            for _, v61 in ipairs(p14.specific) do
                v52 = v61.world_point
                v58 = side_a - v52[1]
                v59 = v53 - v52[2]
                v60 = v54 - v52[3]

                if part == v61.part and v58 * v58 + v59 * v59 + v60 * v60 < v61.radius_squared then
                    v61.current = true
                    v51 = true
                    v61.recent = true
                end
            end

            v54 = p14.planes

            local body_a = #v54

            if not (body_a >= 20) then
                p14.contact_age[part + 1] = 0
                p14.current[part + 1] = true
                v53 = p14.priority[part + 1]

                if p14.maximum_priority < v53 then
                    p14.maximum_priority = v53
                    table.clear(v54)
                end

                local v62

                if v53 == p14.maximum_priority then
                    v62 = {}
                    v62.normal = rt.copy(normal)
                    v62.part = part
                    table.insert(v54, v62)
                end

                body_a = v50.body_a

                local body_b = v50.body_b

                v62 = if body_a.state_flags == 1 then 0.001 else body_a.inverse_mass
                v54 = 1 / v62
                v62 = if body_b.state_flags == 1 then 0.001 else body_b.inverse_mass
                v53 = 1 / v62
                side_a = v50.side_a
                normal = if side_a then v53 else v54
                v62 = normal > 1E-04 and normal < settings.small_object_mass
                normal = (v53 + v54) / (v53 * v54) * 0.00027777781360782683
                v54 = v50.solved_vector

                local v63 = v54[1] * normal

                v58 = v54[2] * normal
                v59 = v54[3] * normal
                v54 = v63 * v63 + v58 * v58 + v59 * v59
                v60 = 1 / math.sqrt(v54)
                v60 = v60 * 0.5 * (-v54 * (v60 * v60) + 1) + v60
                v59 = v54 * (v60 * 0.5 * (-v54 * (v60 * v60) + 1) + v60)

                if v54 == 0 then
                    v59 = 0
                end

                local v64 = v59 * p15.part_weights[part + 1]

                v53 = p15.physical.velocities[part + 1]
                v63 = v53[1]
                v58 = v53[2]
                v59 = v53[3]
                v60 = v53[4]
                v53 = p15.com_velocity

                local v65 = (v53[1] + v63) * 0.5
                local v66 = (v53[2] + v58) * 0.5
                local v67 = (v53[3] + v59) * 0.5
                local v68 = (v53[4] + v60) * 0.5

                if not side_a then
                    body_b = body_a
                end

                v60 = body_b.linear_velocity

                local v69 = v60[1] - v65

                v66 = v60[2] - v66

                local v70 = v60[3] - v67
                local v71 = v60[4] - v68
                local v73 = math.abs(v69 * v55 + v66 * v56 + v70 * v57)

                if v62 then
                    v73 *= 0.5
                end

                if other_group == 5 then
                    v73 *= if p15.ai_collision_scalar then settings.ai_scalar else settings.skater_scalar
                    v68 = p14.maximum_skater_force

                    if not (v68 - v73 >= 0) then
                        v68 = v73
                    end

                    p14.maximum_skater_force = v68
                    v68 = v50.other_entity

                    if v68 ~= nil then
                        p14.other_skater = v68
                    end

                    flags.nonboard = true
                elseif other_group == 8 then
                    flags.group_8 = true
                    v67 = p14.maximum_group_8_force

                    if not (v67 - v73 >= 0) then
                        v67 = v73
                    end

                    p14.maximum_group_8_force = v67
                    flags.nonboard = true
                elseif other_group == 11 then
                    local v74 = p14.maximum_group_11_force

                    p14.maximum_group_11_force = if not (v74 - v73 >= 0) then v73 else v74
                    flags.nonboard = true
                elseif other_group ~= 4 then
                    flags.nonboard = true
                end

                if part > 0 then
                    record_force_lanes(p14, v50, v51, v69, v66, v70, v71, v73, v64)
                    p14.timer = settings.body.effect_time
                end

                if not p14.compliant[part + 1] or v62 then
                    flags.noncompliant = true
                else
                    flags.compliant = true
                end

                flags.has_impulse = flags.compliant or offboard
            end
        elseif not p15.disable_ground_filter or p15.category_600 then
            local body_a, body_b = p15.plane_normal, p15.plane_point
            local v125 = body_a[1]
            local v126 = body_a[2]
            local v127 = body_a[3]

            body_a = v125 * (side_a - body_b[1]) + v126 * (v53 - body_b[2]) + v127 * (v54 - body_b[3])

            local v128 = if offboard then 0.3 else settings.ground_plane_max_distance

            if body_a < v128 then
                if not offboard then
                    local v130 = math.abs(v55 * v125 + v56 * v126 + v57 * v127)
                    local v129 = settings.ground_plane_max_angle

                    if not (v129 < v130) then
                        v51 = false
                        SkeletonCollisionFeedback.observe_normal(p14, ragdoll, v50, v52)

                        for _, v131 in ipairs(p14.specific) do
                            v52 = v131.world_point
                            v128 = side_a - v52[1]
                            v130 = v53 - v52[2]
                            v129 = v54 - v52[3]

                            if part == v131.part and v128 * v128 + v130 * v130 + v129 * v129 < v131.radius_squared then
                                v131.current = true
                                v51 = true
                                v131.recent = true
                            end
                        end

                        v54 = p14.planes
                        body_a = #v54

                        if not (body_a >= 20) then
                            p14.contact_age[part + 1] = 0
                            p14.current[part + 1] = true
                            v53 = p14.priority[part + 1]

                            if p14.maximum_priority < v53 then
                                p14.maximum_priority = v53
                                table.clear(v54)
                            end

                            if v53 == p14.maximum_priority then
                                v125 = {}
                                v125.normal = rt.copy(normal)
                                v125.part = part
                                table.insert(v54, v125)
                            end

                            body_a = v50.body_a
                            body_b = v50.body_b
                            v125 = if body_a.state_flags == 1 then 0.001 else body_a.inverse_mass
                            v54 = 1 / v125
                            v125 = if body_b.state_flags == 1 then 0.001 else body_b.inverse_mass
                            v53 = 1 / v125
                            side_a = v50.side_a
                            normal = if side_a then v53 else v54
                            v125 = normal > 1E-04 and normal < settings.small_object_mass
                            normal = (v53 + v54) / (v53 * v54) * 0.00027777781360782683
                            v54 = v50.solved_vector
                            v127 = v54[1] * normal
                            v128 = v54[2] * normal
                            v130 = v54[3] * normal
                            v54 = v127 * v127 + v128 * v128 + v130 * v130
                            v129 = 1 / math.sqrt(v54)
                            v129 = v129 * 0.5 * (-v54 * (v129 * v129) + 1) + v129
                            v130 = v54 * (v129 * 0.5 * (-v54 * (v129 * v129) + 1) + v129)

                            if v54 == 0 then
                                v130 = 0
                            end

                            v126 = v130 * p15.part_weights[part + 1]
                            v53 = p15.physical.velocities[part + 1]
                            v127 = v53[1]
                            v128 = v53[2]
                            v130 = v53[3]
                            v129 = v53[4]

                            local v132 = p15.entering_offboard
                            local v133, v134, v135, v136, v137, v138

                            if v132 then
                                normal = p15.com_velocity
                                v133 = normal[1]
                                v134 = normal[3]
                                v135 = normal[4]
                                v136 = 0
                            else
                                v132 = v127 * v46 + v128 * v47 + v130 * v48
                                v133 = v46 * v132
                                v136 = v47 * v132
                                v134 = v48 * v132
                                v135 = v49 * v132
                                v132 = v133 * v133 + v136 * v136 + v134 * v134
                                v137 = 1 / math.sqrt(v132)
                                v137 = v137 * 0.5 * (-v132 * (v137 * v137) + 1) + v137
                                v138 = v132 * (v137 * 0.5 * (-v132 * (v137 * v137) + 1) + v137)

                                if v132 == 0 then
                                    v138 = 0
                                end

                                if not (v138 < 1.52587890625E-05) then
                                    v132 = if v45 - v138 >= 0 then v138 else v45
                                    v137 = 1 / v138
                                    v137 = v137 * (-v137 * v138 + 1) + v137
                                    v137 = v137 * (-v137 * v138 + 1) + v137
                                    v133 = v133 * v132 * v137
                                    v136 = v136 * v132 * v137
                                    v134 = v134 * v132 * v137
                                    v135 = v135 * v132 * v137
                                end
                            end

                            if not side_a then
                                body_b = body_a
                            end

                            v129 = body_b.linear_velocity

                            local v139 = v129[1] - v133

                            v136 = v129[2] - v136

                            local v140 = v129[3] - v134
                            local v141 = v129[4] - v135

                            v138 = math.abs(v139 * v55 + v136 * v56 + v140 * v57)

                            if v125 then
                                v138 *= 0.5
                            end

                            if other_group == 5 then
                                v138 *= if p15.ai_collision_scalar then settings.ai_scalar else settings.skater_scalar
                                v135 = p14.maximum_skater_force

                                if not (v135 - v138 >= 0) then
                                    v135 = v138
                                end

                                p14.maximum_skater_force = v135
                                v135 = v50.other_entity

                                if v135 ~= nil then
                                    p14.other_skater = v135
                                end

                                flags.nonboard = true
                            elseif other_group == 8 then
                                flags.group_8 = true
                                v134 = p14.maximum_group_8_force

                                if not (v134 - v138 >= 0) then
                                    v134 = v138
                                end

                                p14.maximum_group_8_force = v134
                                flags.nonboard = true
                            elseif other_group == 11 then
                                local v142 = p14.maximum_group_11_force

                                p14.maximum_group_11_force = if not (v142 - v138 >= 0) then v138 else v142
                                flags.nonboard = true
                            elseif other_group ~= 4 then
                                flags.nonboard = true
                            end

                            if part > 0 then
                                record_force_lanes(p14, v50, v51, v139, v136, v140, v141, v138, v126)
                                p14.timer = settings.body.effect_time
                            end

                            if not p14.compliant[part + 1] or v125 then
                                flags.noncompliant = true
                            else
                                flags.compliant = true
                            end

                            flags.has_impulse = flags.compliant or offboard
                        end
                    end
                end
            else
                v51 = false
                SkeletonCollisionFeedback.observe_normal(p14, ragdoll, v50, v52)

                local v143, v144

                for _, v145 in ipairs(p14.specific) do
                    v52 = v145.world_point
                    v128 = side_a - v52[1]
                    v143 = v53 - v52[2]
                    v144 = v54 - v52[3]

                    if part == v145.part and v128 * v128 + v143 * v143 + v144 * v144 < v145.radius_squared then
                        v145.current = true
                        v51 = true
                        v145.recent = true
                    end
                end

                v54 = p14.planes
                body_a = #v54

                if not (body_a >= 20) then
                    p14.contact_age[part + 1] = 0
                    p14.current[part + 1] = true
                    v53 = p14.priority[part + 1]

                    if p14.maximum_priority < v53 then
                        p14.maximum_priority = v53
                        table.clear(v54)
                    end

                    if v53 == p14.maximum_priority then
                        v125 = {}
                        v125.normal = rt.copy(normal)
                        v125.part = part
                        table.insert(v54, v125)
                    end

                    body_a = v50.body_a
                    body_b = v50.body_b
                    v125 = if body_a.state_flags == 1 then 0.001 else body_a.inverse_mass
                    v54 = 1 / v125
                    v125 = if body_b.state_flags == 1 then 0.001 else body_b.inverse_mass
                    v53 = 1 / v125
                    side_a = v50.side_a
                    normal = if side_a then v53 else v54
                    v125 = normal > 1E-04 and normal < settings.small_object_mass
                    normal = (v53 + v54) / (v53 * v54) * 0.00027777781360782683
                    v54 = v50.solved_vector
                    v127 = v54[1] * normal
                    v128 = v54[2] * normal
                    v143 = v54[3] * normal
                    v54 = v127 * v127 + v128 * v128 + v143 * v143
                    v144 = 1 / math.sqrt(v54)
                    v144 = v144 * 0.5 * (-v54 * (v144 * v144) + 1) + v144
                    v143 = v54 * (v144 * 0.5 * (-v54 * (v144 * v144) + 1) + v144)

                    if v54 == 0 then
                        v143 = 0
                    end

                    v126 = v143 * p15.part_weights[part + 1]
                    v53 = p15.physical.velocities[part + 1]
                    v127 = v53[1]
                    v128 = v53[2]
                    v143 = v53[3]
                    v144 = v53[4]

                    local v146, v147, v148, v149, v150, v151

                    if offboard then
                        normal = p15.com_velocity
                        v146 = normal[1]
                        v147 = normal[3]
                        v148 = normal[4]
                        v149 = 0
                    else
                        local v152 = p15.entering_offboard

                        if v152 then
                            normal = p15.com_velocity
                            v146 = normal[1]
                            v147 = normal[3]
                            v148 = normal[4]
                            v149 = 0
                        else
                            v152 = v127 * v46 + v128 * v47 + v143 * v48
                            v146 = v46 * v152
                            v149 = v47 * v152
                            v147 = v48 * v152
                            v148 = v49 * v152
                            v152 = v146 * v146 + v149 * v149 + v147 * v147
                            v150 = 1 / math.sqrt(v152)
                            v150 = v150 * 0.5 * (-v152 * (v150 * v150) + 1) + v150
                            v151 = v152 * (v150 * 0.5 * (-v152 * (v150 * v150) + 1) + v150)

                            if v152 == 0 then
                                v151 = 0
                            end

                            if not (v151 < 1.52587890625E-05) then
                                v152 = if v45 - v151 >= 0 then v151 else v45
                                v150 = 1 / v151
                                v150 = v150 * (-v150 * v151 + 1) + v150
                                v150 = v150 * (-v150 * v151 + 1) + v150
                                v146 = v146 * v152 * v150
                                v149 = v149 * v152 * v150
                                v147 = v147 * v152 * v150
                                v148 = v148 * v152 * v150
                            end
                        end
                    end

                    if not side_a then
                        body_b = body_a
                    end

                    v144 = body_b.linear_velocity

                    local v153 = v144[1] - v146

                    v149 = v144[2] - v149

                    local v154 = v144[3] - v147
                    local v155 = v144[4] - v148

                    v151 = math.abs(v153 * v55 + v149 * v56 + v154 * v57)

                    if v125 then
                        v151 *= 0.5
                    end

                    if other_group == 5 then
                        v151 *= if p15.ai_collision_scalar then settings.ai_scalar else settings.skater_scalar
                        v148 = p14.maximum_skater_force

                        if not (v148 - v151 >= 0) then
                            v148 = v151
                        end

                        p14.maximum_skater_force = v148
                        v148 = v50.other_entity

                        if v148 ~= nil then
                            p14.other_skater = v148
                        end

                        flags.nonboard = true
                    elseif other_group == 8 then
                        flags.group_8 = true
                        v147 = p14.maximum_group_8_force

                        if not (v147 - v151 >= 0) then
                            v147 = v151
                        end

                        p14.maximum_group_8_force = v147
                        flags.nonboard = true
                    elseif other_group == 11 then
                        local v156 = p14.maximum_group_11_force

                        p14.maximum_group_11_force = if not (v156 - v151 >= 0) then v151 else v156
                        flags.nonboard = true
                    elseif other_group ~= 4 then
                        flags.nonboard = true
                    end

                    if part > 0 then
                        record_force_lanes(p14, v50, v51, v153, v149, v154, v155, v151, v126)
                        p14.timer = settings.body.effect_time
                    end

                    if not p14.compliant[part + 1] or v125 then
                        flags.noncompliant = true
                    else
                        flags.compliant = true
                    end

                    flags.has_impulse = flags.compliant or offboard
                end
            end
        else
            v51 = false
            SkeletonCollisionFeedback.observe_normal(p14, ragdoll, v50, v52)

            local v107, v108, v109

            for _, v110 in ipairs(p14.specific) do
                v52 = v110.world_point
                v107 = side_a - v52[1]
                v108 = v53 - v52[2]
                v109 = v54 - v52[3]

                if part == v110.part and v107 * v107 + v108 * v108 + v109 * v109 < v110.radius_squared then
                    v110.current = true
                    v51 = true
                    v110.recent = true
                end
            end

            v54 = p14.planes

            local body_a = #v54

            if not (body_a >= 20) then
                p14.contact_age[part + 1] = 0
                p14.current[part + 1] = true
                v53 = p14.priority[part + 1]

                if p14.maximum_priority < v53 then
                    p14.maximum_priority = v53
                    table.clear(v54)
                end

                local v111

                if v53 == p14.maximum_priority then
                    v111 = {}
                    v111.normal = rt.copy(normal)
                    v111.part = part
                    table.insert(v54, v111)
                end

                body_a = v50.body_a

                local body_b = v50.body_b

                v111 = if body_a.state_flags == 1 then 0.001 else body_a.inverse_mass
                v54 = 1 / v111
                v111 = if body_b.state_flags == 1 then 0.001 else body_b.inverse_mass
                v53 = 1 / v111
                side_a = v50.side_a
                normal = if side_a then v53 else v54
                v111 = normal > 1E-04 and normal < settings.small_object_mass
                normal = (v53 + v54) / (v53 * v54) * 0.00027777781360782683
                v54 = v50.solved_vector

                local v112 = v54[1] * normal

                v107 = v54[2] * normal
                v108 = v54[3] * normal
                v54 = v112 * v112 + v107 * v107 + v108 * v108
                v109 = 1 / math.sqrt(v54)
                v109 = v109 * 0.5 * (-v54 * (v109 * v109) + 1) + v109
                v108 = v54 * (v109 * 0.5 * (-v54 * (v109 * v109) + 1) + v109)

                if v54 == 0 then
                    v108 = 0
                end

                local v113 = v108 * p15.part_weights[part + 1]

                v53 = p15.physical.velocities[part + 1]
                v112 = v53[1]
                v107 = v53[2]
                v108 = v53[3]
                v109 = v53[4]

                local v114, v115, v116, v117, v118, v119

                if offboard then
                    normal = p15.com_velocity
                    v114 = normal[1]
                    v115 = normal[3]
                    v116 = normal[4]
                    v117 = 0
                else
                    local v120 = p15.entering_offboard

                    if v120 then
                        normal = p15.com_velocity
                        v114 = normal[1]
                        v115 = normal[3]
                        v116 = normal[4]
                        v117 = 0
                    else
                        v120 = v112 * v46 + v107 * v47 + v108 * v48
                        v114 = v46 * v120
                        v117 = v47 * v120
                        v115 = v48 * v120
                        v116 = v49 * v120
                        v120 = v114 * v114 + v117 * v117 + v115 * v115
                        v118 = 1 / math.sqrt(v120)
                        v118 = v118 * 0.5 * (-v120 * (v118 * v118) + 1) + v118
                        v119 = v120 * (v118 * 0.5 * (-v120 * (v118 * v118) + 1) + v118)

                        if v120 == 0 then
                            v119 = 0
                        end

                        if not (v119 < 1.52587890625E-05) then
                            v120 = if v45 - v119 >= 0 then v119 else v45
                            v118 = 1 / v119
                            v118 = v118 * (-v118 * v119 + 1) + v118
                            v118 = v118 * (-v118 * v119 + 1) + v118
                            v114 = v114 * v120 * v118
                            v117 = v117 * v120 * v118
                            v115 = v115 * v120 * v118
                            v116 = v116 * v120 * v118
                        end
                    end
                end

                if not side_a then
                    body_b = body_a
                end

                v109 = body_b.linear_velocity

                local v121 = v109[1] - v114

                v117 = v109[2] - v117

                local v122 = v109[3] - v115
                local v123 = v109[4] - v116

                v119 = math.abs(v121 * v55 + v117 * v56 + v122 * v57)

                if v111 then
                    v119 *= 0.5
                end

                if other_group == 5 then
                    v119 *= if p15.ai_collision_scalar then settings.ai_scalar else settings.skater_scalar
                    v116 = p14.maximum_skater_force

                    if not (v116 - v119 >= 0) then
                        v116 = v119
                    end

                    p14.maximum_skater_force = v116
                    v116 = v50.other_entity

                    if v116 ~= nil then
                        p14.other_skater = v116
                    end

                    flags.nonboard = true
                elseif other_group == 8 then
                    flags.group_8 = true
                    v115 = p14.maximum_group_8_force

                    if not (v115 - v119 >= 0) then
                        v115 = v119
                    end

                    p14.maximum_group_8_force = v115
                    flags.nonboard = true
                elseif other_group == 11 then
                    local v124 = p14.maximum_group_11_force

                    p14.maximum_group_11_force = if not (v124 - v119 >= 0) then v119 else v124
                    flags.nonboard = true
                elseif other_group ~= 4 then
                    flags.nonboard = true
                end

                if part > 0 then
                    record_force_lanes(p14, v50, v51, v121, v117, v122, v123, v119, v113)
                    p14.timer = settings.body.effect_time
                end

                if not p14.compliant[part + 1] or v111 then
                    flags.noncompliant = true
                else
                    flags.compliant = true
                end

                flags.has_impulse = flags.compliant or offboard
            end
        end
    end

    if ragdoll then
        p14.flags.impaled = SkeletonCollisionFeedback.check_impaled(p14)
    else
        p14.flags.conflicting = SkeletonCollisionFeedback.check_conflicting(p14, p15)
    end

    offboard = p14.settings.body.effect_time

    if offboard == 0 then
        p14.drive_weight = 1
    else
        local v157 = p14.timer / offboard

        if -v157 >= 0 then
            v157 = 0
        end

        if not (1 - v157 >= 0) then
            v157 = 1
        end

        v43 = 1 - v157

        if v43 ~= 0 and v43 > -1.1754943508222875E-38 and v43 < 1.1754943508222875E-38 then
            v49 = math.abs(v43) * 7.1362384635298E+44

            local v158 = math.floor(v49)

            v48 = v49 - v158
            v157 = (if v48 > 0.5 or v48 == 0.5 and v158 % 2 == 1 then v158 + 1 else v158) * 1.401298464324817E-45

            if v43 < 0 then
                v157 = -v157
            end
        else
            buffer.writef32(v1, 0, v43)
            v157 = buffer.readf32(v1, 0)
        end

        p14.drive_weight = v157
    end

    p14.flags.recovering = p14.drive_weight < 1
end

function t1.SkeletonCollisionFeedback.update_r3(p17, p18, p19) -- line: 416
    -- upvalues: rt (copy), v1 (copy), add (copy), clamp_length (copy), dot (copy), length (copy), normalize (copy), scale (copy), sub (copy), t1 (copy), SkeletonCollisionFeedback (copy)
    SkeletonCollisionFeedback.begin_frame(p17, p18)

    local v159 = length(p18.reference_velocity)
    local v160 = normalize(p18.reference_velocity)

    for _, v161 in ipairs(p19) do
        if not (v161.part < 24) then
            error("SkeletonCollision report part exceeds native24-part array", 0)
        end

        local part = v161.part
        local v163 = bit32.band(bit32.rshift(v161.tag, 7), 31)

        p17.flags.any = true

        if v161.other_group == 4 and (part == 15 or part == 16 or part == 19 or part == 20) then
            p17.flags.foot_board = true
        end

        if v163 == 6 then
            p17.flags.material_6 = true
        end

        if v163 == 12 then
            p17.flags.material_12 = true
            p17.material_12_height = v161.point[2]
        end

        if not SkeletonCollisionFeedback.ignore_ground(p17, p18, v161) then
            SkeletonCollisionFeedback.observe_normal(p17, p18.ragdoll, v161, v163)

            local v164 = false

            for _, v165 in ipairs(p17.specific) do
                local v166 = sub(v161.point, v165.world_point)

                if part == v165.part and dot(v166, v166) < v165.radius_squared then
                    v165.current = true
                    v164 = true
                    v165.recent = true
                end
            end

            if not (#p17.planes >= 20) then
                p17.contact_age[part + 1] = 0
                p17.current[part + 1] = true

                if p17.priority[part + 1] > p17.maximum_priority then
                    p17.maximum_priority = p17.priority[part + 1]
                    table.clear(p17.planes)
                end

                if p17.priority[part + 1] == p17.maximum_priority then
                    table.insert(p17.planes, {
                        normal = rt.copy(v161.normal),
                        part = part
                    })
                end

                local v167 = t1.mass(v161.body_a)
                local v168 = t1.mass(v161.body_b)
                local v169 = if v161.side_a then v168 else v167
                local v170 = v169 > 1E-04 and v169 < p17.settings.small_object_mass
                local v171 = (v168 + v167) / (v168 * v167) * 0.00027777781360782683
                local v172 = length(scale(v161.solved_vector, v171)) * p18.part_weights[part + 1]
                local v173 = rt.copy(p18.physical.velocities[part + 1])
                local v174

                if p18.ragdoll then
                    v174 = scale(add(p18.com_velocity, v173), 0.5)
                elseif p18.offboard or p18.entering_offboard then
                    v174 = rt.copy(p18.com_velocity)
                    v174[2] = 0
                else
                    v174 = clamp_length(scale(v160, dot(v173, v160)), v159)
                end

                local v177 = sub((if v161.side_a then v161.body_b else v161.body_a).linear_velocity, v174)
                local v179 = math.abs((dot(v177, v161.normal)))

                if v170 then
                    v179 *= 0.5
                end

                local other_group = v161.other_group

                if other_group == 5 then
                    v179 *= if p18.ai_collision_scalar then p17.settings.ai_scalar else p17.settings.skater_scalar
                    p17.maximum_skater_force = t1.maximum(p17.maximum_skater_force, v179)

                    local other_entity = v161.other_entity

                    if other_entity ~= nil then
                        p17.other_skater = other_entity
                    end

                    p17.flags.nonboard = true
                elseif other_group == 8 then
                    p17.flags.group_8 = true
                    p17.maximum_group_8_force = t1.maximum(p17.maximum_group_8_force, v179)
                    p17.flags.nonboard = true
                elseif other_group == 11 then
                    p17.maximum_group_11_force = t1.maximum(p17.maximum_group_11_force, v179)
                    p17.flags.nonboard = true
                elseif other_group ~= 4 then
                    p17.flags.nonboard = true
                end

                if part > 0 then
                    SkeletonCollisionFeedback.record_force(p17, v161, v164, v177, v179, v172)
                    p17.timer = p17.settings.body.effect_time
                end

                if not p17.compliant[part + 1] or v170 then
                    p17.flags.noncompliant = true
                else
                    p17.flags.compliant = true
                end

                p17.flags.has_impulse = p17.flags.compliant or p18.offboard
            end
        end
    end

    if p18.ragdoll then
        p17.flags.impaled = SkeletonCollisionFeedback.check_impaled(p17)
    else
        p17.flags.conflicting = SkeletonCollisionFeedback.check_conflicting(p17, p18)
    end

    local effect_time = p17.settings.body.effect_time

    if effect_time == 0 then
        p17.drive_weight = 1
    else
        local v180 = p17.timer / effect_time

        if -v180 >= 0 then
            v180 = 0
        end

        if not (1 - v180 >= 0) then
            v180 = 1
        end

        local v181 = 1 - v180
        local v182

        if v181 ~= 0 and v181 > -1.1754943508222875E-38 and v181 < 1.1754943508222875E-38 then
            local v183 = math.abs(v181) * 7.1362384635298E+44
            local v184 = math.floor(v183)
            local v185 = v183 - v184

            v182 = (if v185 > 0.5 or v185 == 0.5 and v184 % 2 == 1 then v184 + 1 else v184) * 1.401298464324817E-45

            if v181 < 0 then
                v182 = -v182
            end
        else
            buffer.writef32(v1, 0, v181)
            v182 = buffer.readf32(v1, 0)
        end

        p17.drive_weight = v182
    end

    p17.flags.recovering = p17.drive_weight < 1
end

local function reset_bone(p20) -- line: 556
    if p20 == nil then
        return false
    end

    local normal, specific_normal, tangent, specific_tangent = p20.normal, p20.specific_normal, p20.tangent, p20.specific_tangent
    local point, groups = p20.point, p20.groups

    if normal ~= nil and specific_normal ~= nil and tangent ~= nil and specific_tangent ~= nil and point ~= nil and groups ~= nil then
        if #normal ~= 4
            or #specific_normal ~= 4
            or #tangent ~= 4
            or #specific_tangent ~= 4
            or #point ~= 4
            or #groups ~= 4 then
            return false
        end

        normal[1] = 0
        normal[2] = 0
        normal[3] = 0
        normal[4] = 0
        specific_normal[1] = 0
        specific_normal[2] = 0
        specific_normal[3] = 0
        specific_normal[4] = 0
        tangent[1] = 0
        tangent[2] = 0
        tangent[3] = 0
        tangent[4] = 0
        specific_tangent[1] = 0
        specific_tangent[2] = 0
        specific_tangent[3] = 0
        specific_tangent[4] = 0
        point[1] = 0
        point[2] = 0
        point[3] = 0
        point[4] = 0
        p20.force = 0
        p20.specific_force = 0
        p20.tag = 0
        p20.specific_tag = 0
        groups[1] = false
        groups[2] = false
        groups[3] = false
        groups[4] = false

        return true
    end

    return false
end

local t3 = {
    force = true,
    weighted_force = true,
    tangent_speed = true,
    material_flags = true,
    normal = true
}

function t1.SkeletonCollisionFeedback.begin_frame(p21, p22) -- line: 610
    -- upvalues: rt (copy), import (copy), transform (copy), reset_bone (copy), t3 (copy)
    local v186 = import("skate_core/physics/skeleton_body/collision_feedback")

    p21.timer -= p22.dt
    p21.wipeout_times[3] += p22.dt

    local v187 = v186.SkeletonContactFlags.default()

    v187.ragdoll = p22.ragdoll
    p21.flags = v187
    table.clear(p21.planes)
    p21.maximum_priority = 0
    p21.maximum_skater_force = 0
    p21.other_skater = -1
    p21.maximum_group_8_force = 0
    p21.maximum_group_11_force = 0
    p21.material_12_height = 0
    p21.highest_normal = { 0, -1, 0, 0 }
    p21.foot_normal = table.create(4, 0)
    p21.material_normals = rt.filled(2, { 0, -1, 0, 0 })

    local bones = p21.bones

    for i = 0, 23 do
        p21.contact_age[i + 1] -= p22.dt
        p21.current[i + 1] = false

        if not reset_bone(bones[i + 1]) then
            bones[i + 1] = v186.BoneContact.default()
        end
    end

    for _, v188 in ipairs(p21.regions) do
        for v189 in v188 do
            if not t3[v189] then
                v188[v189] = nil
            end
        end

        v188.force = 0
        v188.weighted_force = 0
        v188.tangent_speed = 0
        v188.normal = table.create(4, 0)
    end

    if not p22.ragdoll then
        p21.wipeout_times = table.create(3, 0)
    end

    for _, v190 in ipairs(p21.specific) do
        v190.recent = v190.recent and p22.ragdoll
        v190.current = false
        v190.world_point = transform(p22.physical.pose[v190.part + 1], v190.local_point)
    end

    if p22.request_partial_ragdoll then
        p21.timer = p21.settings.body.effect_time
    end
end

function t1.SkeletonCollisionFeedback.begin_frame_reference(p23, p24) -- line: 664
    -- upvalues: rt (copy), import (copy), transform (copy)
    local v191 = import("skate_core/physics/skeleton_body/collision_feedback")

    p23.timer -= p24.dt
    p23.wipeout_times[3] += p24.dt

    local v192 = v191.SkeletonContactFlags.default()

    v192.ragdoll = p24.ragdoll
    p23.flags = v192
    table.clear(p23.planes)
    p23.maximum_priority = 0
    p23.maximum_skater_force = 0
    p23.other_skater = -1
    p23.maximum_group_8_force = 0
    p23.maximum_group_11_force = 0
    p23.material_12_height = 0
    p23.highest_normal = { 0, -1, 0, 0 }
    p23.foot_normal = table.create(4, 0)
    p23.material_normals = rt.filled(2, { 0, -1, 0, 0 })

    for i = 0, 23 do
        p23.contact_age[i + 1] -= p24.dt
        p23.current[i + 1] = false
        p23.bones[i + 1] = v191.BoneContact.default()
    end

    for _, v193 in ipairs(p23.regions) do
        local v194 = v191.ContactRegion.default()

        v194.material_flags = v193.material_flags
        rt.assign(v193, v194)
    end

    if not p24.ragdoll then
        p23.wipeout_times = table.create(3, 0)
    end

    for _, v195 in ipairs(p23.specific) do
        v195.recent = v195.recent and p24.ragdoll
        v195.current = false
        v195.world_point = transform(p24.physical.pose[v195.part + 1], v195.local_point)
    end

    if p24.request_partial_ragdoll then
        p23.timer = p23.settings.body.effect_time
    end
end

function t1.SkeletonCollisionFeedback.ignore_ground(p25, p26, p27) -- line: 705
    -- upvalues: dot (copy), sub (copy)
    if p26.ragdoll or p26.disable_ground_filter and not p26.category_600 then
        return false
    end

    local v196 = dot(p26.plane_normal, sub(p27.point, p26.plane_point))
    local v197 = if p26.offboard then 0.3 else p25.settings.ground_plane_max_distance
    local offboard

    if v196 < v197 then
        offboard = p26.offboard

        if not offboard then
            offboard = math.abs((dot(p27.normal, p26.plane_normal))) > p25.settings.ground_plane_max_angle
        end
    else
        offboard = false
    end

    return offboard
end

function t1.SkeletonCollisionFeedback.observe_normal(p28, p29, p30, p31) -- line: 720
    -- upvalues: rt (copy)
    local normal = p30.normal

    if normal[2] > p28.highest_normal[2] then
        p28.highest_normal = rt.copy(normal)
    end

    if p29 then
        if p31 == 10 and normal[2] > p28.material_normals[1][2] then
            p28.material_normals[1] = rt.copy(normal)
            p28.flags.material_10 = true
        elseif p31 == 11 and normal[2] > p28.material_normals[2][2] then
            p28.material_normals[2] = rt.copy(normal)
            p28.flags.material_11 = true
        end
    elseif (p30.part == 15 or p30.part == 19) and normal[2] > p28.foot_normal[2] then
        p28.foot_normal = rt.copy(normal)
    end
end

function t1.SkeletonCollisionFeedback.record_force(p32, p33, p34, p35, p36, p37) -- line: 738
    -- upvalues: rt (copy), cross (copy), length (copy), t1 (copy)
    local v199 = p32.bones[p33.part + 1]
    local v200 = p32.regions[t1.REGIONS[p33.part + 1] + 1]
    local v201 = if p34 then v199.specific_force else v199.force
    local v202 = if v201 < p36 or v200.force < p36 then cross(p35, p33.normal) else table.create(4, 0)

    if v201 < p36 then
        if p34 then
            v199.specific_force = p36
            v199.specific_normal = rt.copy(p33.normal)
            v199.specific_tangent = rt.copy(v202)
            v199.specific_tag = p33.tag
        else
            v199.force = p36
            v199.normal = rt.copy(p33.normal)
            v199.tangent = rt.copy(v202)
            v199.point = rt.copy(p33.point)
            v199.tag = p33.tag
        end

        local t4 = {
            8, 11, 5
        }

        v199.groups[1] = v199.groups[1] or p33.other_group == t4[1]
        v199.groups[2] = v199.groups[2] or p33.other_group == t4[2]
        v199.groups[3] = v199.groups[3] or p33.other_group == t4[3]

        local groups = v199.groups
        local v203 = v199.groups[4]

        if v203 then
            groups[4] = v203
        else
            groups[4] = not (p33.other_group == 8 or p33.other_group == 11 or p33.other_group == 5)
        end
    end

    if not (v200.force < p36) then
        return
    end

    rt.assign(v200, {
        force = p36,
        weighted_force = p37,
        tangent_speed = length(v202),
        material_flags = bit32.band(p33.tag, 127),
        normal = p33.normal,
        part = p33.part
    })
end

function t1.SkeletonCollisionFeedback.check_conflicting(p38, p39) -- line: 786
    -- upvalues: dot (copy), sub (copy)
    for v204, v205 in ipairs(p38.regions) do
        local part = v205.part

        if part ~= nil and v205.force > 0 and p38.compliant[part + 1] then
            for v206, v207 in ipairs(p38.regions) do
                local part2 = v207.part

                if part2 ~= nil and v204 ~= v206 and v207.force > 0 and p38.compliant[part2 + 1] and dot(v205.normal, v207.normal) < -0.7 then
                    local body_frames = p39.body_frames

                    if body_frames == nil then
                        body_frames = p39.body_frames_of(p39.body_frames_owner)
                        p39.body_frames = body_frames
                    end

                    if dot(sub(body_frames[part2 + 1][4], body_frames[part + 1][4]), v205.normal) < 0 then
                        return true
                    end
                end
            end
        end
    end

    return false
end

function t1.SkeletonCollisionFeedback.check_impaled(p40) -- line: 824
    -- upvalues: dot (copy), sub (copy)
    local bones = p40.bones

    for i = 1, 22 do
        local v208 = bones[i + 1]

        if v208.force > 0 then
            for j = i + 1, 23 do
                local v209 = bones[j + 1]

                if v209.force > 0 and dot(v208.normal, v209.normal) < -0.99 and math.abs((dot(v208.normal, sub(v208.point, v209.point)))) < 0.03 then
                    return true
                end
            end
        end
    end

    return false
end

function t1.SkeletonCollisionFeedback.check_impaled_reference(p41) -- line: 849
    -- upvalues: rt (copy), dot (copy), sub (copy)
    for i = 1, 22 do
        local v211 = rt.copy(p41.bones[i + 1])

        if v211.force > 0 then
            for j = i + 1, 23 do
                local v212 = p41.bones[j + 1]

                if v212.force > 0 and dot(v211.normal, v212.normal) < -0.99 and math.abs((dot(v211.normal, sub(v211.point, v212.point)))) < 0.03 then
                    return true
                end
            end
        end
    end

    return false
end

function t1.mass(p42) -- line: 870
    return 1 / (if p42.state_flags == 1 then 0.001 else p42.inverse_mass)
end

function t1.maximum(p43, p44) -- line: 874
    if p43 - p44 >= 0 then
        return p43
    end

    return p44
end

return t1
