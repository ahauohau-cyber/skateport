-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/player/offboard/air_selector/math")
local v2 = import("skate_core/air/trajectory")
local Prediction, QueryResult, Trajectory = v2.Prediction, v2.QueryResult, v2.Trajectory
local Vector3 = import("skate_core/math").Vector3
local v3 = import("skate_core/player/offboard/ground_query")
local inverse_length_squared = import("skate_core/physics/board_motion_output").inverse_length_squared
local v4 = import("skate_core/trigonometry")

local function air_selector() -- line: 15
    -- upvalues: import (copy)
    return import("skate_core/player/offboard/air_selector")
end

local add, cross, dot, length = v1.add, v1.cross, v1.dot, v1.length
local madd, normalize, normalize_or, reciprocal = v1.madd, v1.normalize, v1.normalize_or, v1.reciprocal
local scale, sub, wrap_angle, UP = v1.scale, v1.sub, v1.wrap_angle, v1.UP
local flatten, adjust = v1.flatten, v1.adjust
local t1 = {
    lanes = function(p1) -- lanes | line: 39
        return {
            p1.x,
            p1.y,
            p1.z,
            0
        }
    end
}

function t1.vec3(p2) -- line: 43
    -- upvalues: Vector3 (copy)
    return Vector3.new(p2[1], p2[2], p2[3])
end

local lanes, vec3 = t1.lanes, t1.vec3

function t1.search(p3, p4, p5) -- line: 50
    -- upvalues: rt (copy), Prediction (copy), QueryResult (copy), Trajectory (copy), v3 (copy), vec3 (copy)
    if not QueryResult.valid(p4.result) or p4.result.contact_frame < 16 then
        return nil
    end

    local v5 = Prediction.collision_position(p4)
    local v6 = Trajectory.highest_position(p3.trajectory)
    local v7 = table.create(4)

    v7[1] = rt.fmin(v5[1], v6[1]) - 2
    v7[2] = rt.fmin(v5[2], v6[2]) - 2
    v7[3] = rt.fmin(v5[3], v6[3]) - 2
    v7[4] = rt.fmin(v5[4], v6[4]) - 2

    local v8 = table.create(4)

    v8[1] = rt.fmax(v5[1], v6[1]) + 2
    v8[2] = rt.fmax(v5[2], v6[2]) + 2
    v8[3] = rt.fmax(v5[3], v6[3]) + 2
    v8[4] = rt.fmax(v5[4], v6[4]) + 2

    local IDENTITY = v3.Frame.IDENTITY

    return {
        narrow_forward = false,
        min = vec3(v7),
        max = vec3(v8),
        frame = {
            position = vec3(p3.trajectory.position),
            right = rt.copy(IDENTITY.right),
            up = rt.copy(IDENTITY.up),
            forward = rt.copy(IDENTITY.forward)
        },
        context = {
            selection_flags_2948 = p5.selection_flags_2948,
            matching_id_2952 = p5.matching_group_2952
        }
    }
end

function t1.filter_edges(p6, p7) -- line: 84
    -- upvalues: rt (copy), add (copy), cross (copy), dot (copy), normalize (copy), normalize_or (copy), scale (copy), sub (copy), UP (copy), lanes (copy)
    local v9 = table.create(#p6)

    for v10, v11 in p6 do
        v9[v10] = normalize(sub(lanes(v11["end"]), lanes(v11.start)))
    end

    local t2 = {}

    for i = 0, #p6 - 1 do
        local v12 = p6[i + 1]
        local v13 = lanes(v12.start)
        local v14 = scale(add(v13, lanes(v12["end"])), 0.5)
        local v15 = #p6 - 1
        local v16 = false

        for j = 0, v15 do
            local v17 = p6[j + 1]

            if i ~= j then
                local v18 = cross(v9[i + 1], v9[j + 1])

                if dot(v18, v18) < 1E-04 then
                    local v19 = sub(lanes(v17.start), v13)
                    local v20 = sub(v19, scale(v9[j + 1], dot(v9[j + 1], v19)))
                    local v21 = dot(v20, v20)

                    if v21 > 1E-04 and v21 < 0.010000001 then
                        local v22 = sub(lanes(v17.start), v14)

                        if dot(v22, sub(lanes(v17["end"]), v14)) < 0 then
                            local v23 = add(v14, sub(v22, scale(v9[j + 1], dot(v9[j + 1], v22))))
                            local v24 = sub(v14, p7)
                            local v25 = sub(v23, p7)
                            local v27 = dot(v19, (normalize_or(cross(v9[i + 1], cross(UP, v9[i + 1])), { 0, 0, 0, 0 })))

                            if v27 > -0.02 and dot(v24, v24) > dot(v25, v25) or v27 > 0.02 then
                                v16 = true
                                break
                            end
                        end
                    end
                end
            end
        end

        if not v16 then
            table.insert(t2, rt.copy(v12))

            if #t2 == 40 then
                break
            end
        end
    end

    return t2
end

function t1.plane_time(p8, p9, p10) -- line: 139
    -- upvalues: rt (copy), inverse_length_squared (copy), dot (copy), reciprocal (copy), scale (copy)
    local v28 = dot(p10, scale(p8.acceleration, 0.5))
    local v29 = dot(p10, p8.velocity)
    local v30 = dot(p10, p8.position) - dot(p9, p10)
    local v31 = v29 * v29 - 4 * v28 * v30

    if not (v31 < 0) then
        local v32 = reciprocal(2 * v28)

        if v31 > 0 then
            local v33 = v31 * inverse_length_squared(v31, 2)

            return rt.fmax(v32 * (-v29 + v33), v32 * (-v29 - v33))
        end

        local v34 = v32 * -v29

        if v34 > 0 then
            return v34
        end
    end

    return nil
end

function t1.closest(p11, p12) -- line: 161
    -- upvalues: rt (copy), dot (copy), length (copy), madd (copy), reciprocal (copy), scale (copy), sub (copy), lanes (copy)
    local v35 = lanes(p12.start)
    local v36 = sub(lanes(p12["end"]), v35)
    local v37 = length(v36)

    if v37 > 1.52587890625E-05 then
        v36 = scale(v36, reciprocal(v37))
    end

    return madd(v36, rt.fmax(rt.fmin(dot(v36, sub(p11, v35)), v37), 0), v35)
end

function t1.angle(p13, p14, p15) -- line: 171
    -- upvalues: rt (copy), inverse_length_squared (copy), v4 (copy), cross (copy), dot (copy), scale (copy), sub (copy), wrap_angle (copy)
    if not (dot(p13, p13) * dot(p14, p14) > 1.52587890625E-05) then
        return 0
    end

    local v38 = sub(p13, scale(p15, dot(p15, p13)))
    local v39 = sub(p14, scale(p15, dot(p15, p14)))
    local v40 = dot(v38, v38)
    local v41 = dot(v39, v39)

    if not (v40 > 1E-04 and v41 > 1E-04) then
        return 0
    end

    local v42 = scale(v38, inverse_length_squared(v40, 1))
    local v43 = scale(v39, inverse_length_squared(v41, 1))
    local v44 = v4.acos(rt.fmin(rt.fmax(dot(v42, v43), -1), 1))

    if dot(cross(v42, v43), p15) < 0 then
        v44 = 6.283185307179586 - v44
    end

    return (math.abs((wrap_angle(v44))))
end

t1.Adjustment = {}

function t1.Adjustment.apply(p16, p17) -- line: 200
    -- upvalues: rt (copy), import (copy), Trajectory (copy), add (copy), cross (copy), normalize_or (copy), sub (copy), UP (copy), lanes (copy)
    local DT = import("skate_core/player/offboard/air_selector").DT

    p17.trajectory = rt.copy(p16.lowered_trajectory)
    p17.trajectory.position = add(p17.trajectory.position, {
        0,
        p16.radius,
        0, 0
    })
    p17.normal_64 = normalize_or(cross(sub(lanes(p16.edge["end"]), lanes(p16.edge.start)), cross(UP, sub(lanes(p16.edge["end"]), lanes(p16.edge.start)))), UP)
    p17.contact_position_96 = rt.copy(p16.point)
    p17.landing_frame_116 = p16.landing_frame
    p17.contact_velocity_80 = Trajectory.velocity_at(p16.lowered_trajectory, p16.landing_frame * DT)
    p17.special_121 = true
end

function t1.choose(p18, p19, p20, p21, p22) -- line: 218
    -- upvalues: rt (copy), QueryResult (copy), Trajectory (copy), add (copy), cross (copy), dot (copy), length (copy), normalize_or (copy), scale (copy), sub (copy), UP (copy), flatten (copy), adjust (copy), t1 (copy), lanes (copy)
    if not QueryResult.valid(p19.result) or p19.result.contact_frame < 16 then
        return nil
    end

    local v46 = rt.copy(p18.trajectory)
    local v47 = rt.copy(v46)

    v47.position = add(v46.position, { 0, -p21, 0, 0 })

    local t3

    for _, v48 in p22 do
        local v49 = sub(lanes(v48["end"]), lanes(v48.start))
        local v50 = normalize_or(cross(v49, cross(UP, v49)), UP)
        local v51 = t1.plane_time(v46, lanes(v48.start), v50)

        if v51 ~= nil then
            local v52 = Trajectory.position_at(v46, v51)
            local v53 = t1.closest(v52, v48)

            if v50[2] > 0.71 then
                local v54 = flatten(sub(v53, v47.position))
                local v55 = length(v54)

                if v55 > 0.3 then
                    local v56 = scale(v54, 1 / v55)

                    if dot(v56, normalize_or(flatten(p20.forward_224), { 0, 0, 0, 0 })) > 0.71 then
                        local v57 = rt.f_to_i32(v51 * 59.999996)
                        local v58 = rt.copy(v47)

                        adjust(v58, v57, sub(v53, v52), 10)

                        local v59 = sub(v58.velocity, v46.velocity)
                        local v60 = v53[2] - p19.result.contact_position[2]

                        if v60 > -0.05 and dot(v59, v59) < 2.25 then
                            if v60 < 0.05 then
                                if dot(v56, normalize_or(flatten(v49), { 0, 0, 0, 0 })) >= 0.71 and t1.angle(v58.velocity, v46.velocity, p20.up_544) < 10 * 0.01745329238474369 and (t3 == nil or not (t3.point[2] > v53[2])) then
                                    t3 = {}
                                    t3.edge = rt.copy(v48)
                                    t3.point = v53
                                    t3.lowered_trajectory = v58
                                    t3.landing_frame = v57
                                    t3.radius = p21
                                end
                            elseif t1.angle(v58.velocity, v46.velocity, p20.up_544) < 40 * 0.01745329238474369 and (t3 == nil or not (t3.point[2] > v53[2])) then
                                t3 = {}
                                t3.edge = rt.copy(v48)
                                t3.point = v53
                                t3.lowered_trajectory = v58
                                t3.landing_frame = v57
                                t3.radius = p21
                            end
                        end
                    end
                end
            end
        end
    end

    return t3
end

function t1.lines(p23, p24) -- line: 281
    -- upvalues: add (copy), cross (copy), dot (copy), length (copy), madd (copy), normalize_or (copy), scale (copy), sub (copy), UP (copy), lanes (copy), vec3 (copy)
    local edge = p23.edge
    local v61 = sub(lanes(edge["end"]), lanes(edge.start))
    local v62 = cross(v61, cross(UP, v61))

    if length(v62) < 1E-05 then
        return nil
    end

    local v63 = normalize_or(v62, v62)
    local v64 = normalize_or(v61, v61)
    local v65 = lanes(edge.start)
    local v66 = madd(v64, dot(sub(p23.point, v65), v64), v65)
    local v67 = sub(p23.point, sub(p23.point, v66))
    local v68 = cross(v63, v64)
    local v69 = scale(v68, 0.09)
    local v70 = scale(v68, p24)
    local v71 = scale(v63, 0.04)
    local v72 = scale(v63, p24 * 1.059999942779541)

    local function line(p25, p26, p27) -- line: 298
        -- upvalues: add (copy), sub (copy), vec3 (copy)
        return {
            start = vec3(add(p25, p26)),
            ["end"] = vec3(sub(p25, p26)),
            radius = p27
        }
    end

    return {
        line(add(v67, v69), v71, 0),
        line(sub(v67, v69), v71, 0),
        line(add(v67, v70), v72, 0),
        line(sub(v67, v70), v72, 0),
        line(v67, v71, 0),
        (line(add(v67, scale(v63, 0.09)), v69, 0.001))
    }
end

function t1.consume_lines(p28) -- line: 320
    if (if p28.n == nil then #p28 else p28.n) ~= 6 then
        error("BipedAir ledge completion requires exactly six lines", 0)
    end
end

return t1
