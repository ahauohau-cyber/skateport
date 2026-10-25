-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/air/trajectory/math")
local v2 = import("skate_core/air/trajectory/prediction")
local v3 = import("skate_core/air/trajectory/launch")
local v4 = import("skate_core/air/trajectory/grind")
local PointGraph = import("skate_core/point_graph").PointGraph
local Prediction, QueryResult = v2.Prediction, v2.QueryResult
local GrindEvaluation = v4.GrindEvaluation
local adjust_trajectory = v3.adjust_trajectory
local UP, dot, add, sub = v1.UP, v1.dot, v1.add, v1.sub
local madd, cross, reciprocal, length = v1.madd, v1.cross, v1.reciprocal, v1.length
local normalize = v1.normalize
local t1 = {
    Candidate = {}
}

function t1.score(p1, p2, p3, p4, p5, p6, p7) -- line: 41
    -- upvalues: rt (copy), PointGraph (copy), Prediction (copy), QueryResult (copy), GrindEvaluation (copy), UP (copy), dot (copy), cross (copy), length (copy), normalize (copy), t1 (copy)
    local v5 = #p1 - 1
    local v6 = true
    local n1 = -1E+06

    for i = 0, v5 do
        local v7 = p1[i + 1]

        v7.score = 0
        v7.wall_score = 0
        v7.wall_ride = false
        v7.grind = nil

        local v8, v10
        local v9 = n1

        if QueryResult.valid(v7.prediction.result) then
            if not (v7.prediction.result.contact_frame < p5.minimum_trajectory_frames) then
                v8 = i == 0 and p2 == 1

                local v11 = if not v8 or p3 then 0 else p5.score_middle_bonus

                v7.collision_position = Prediction.collision_position(v7.prediction)
                v7.normal = QueryResult.suggested_normal(v7.prediction.result)
                v7.prediction.result.contact_normal = rt.copy(v7.normal)
                v7.collision_velocity = Prediction.collision_velocity(v7.prediction)

                local v12 = dot(v7.normal, v7.collision_velocity)
                local v13 = length(cross(v7.normal, normalize(v7.collision_velocity)))
                local v14 = PointGraph.evaluate(p5.landing_force_scalar, (math.abs(v12)))
                local v15 = v12 * p5.score_landing_force * v14
                local v16 = v13 * p5.score_landing_direction * v14
                local prediction = v7.prediction
                local v17

                if v8 then
                    local flags_2472 = p4.flags_2472
                    local v18 = bit32.band(flags_2472, 536870912) ~= 0 and bit32.band(p4.offboard_flags_1776, 67108864) ~= 0 and bit32.band(p4.offboard_flags_1776, 134217728) == 0

                    v17 = not v18
                else
                    v17 = v8
                end

                local v19 = p6(prediction, v17)

                v7.grind = rt.copy(v19.target)

                local v20 = if bit32.band(p4.flags_2476, 33554432) ~= 0 then 0
                    elseif v19.score ~= 0 then v19.score
                    elseif p4.grind_lock_distance > 0.5 or not v8 then PointGraph.evaluate(p5.grind_penalty_vs_distance, GrindEvaluation.penalty_input(v19))
                    else 0
                local v21 = n1

                if v20 <= 0 then
                    local v22

                    v22, v21 = t1.wall_score(v7.prediction, v20 < 0, p5, n1, p7)
                    v7.wall_score = v22
                    v7.wall_ride = v7.wall_score > 0

                    if v7.wall_score < 0 then
                        v7.prediction.result.contact_normal = rt.copy(UP)
                    end
                end

                v9 = v21

                local surface_unrideable_score

                if v20 <= 1 then
                    local v24 = bit32.band(bit32.rshift(v7.prediction.result.surface, 7), 31)

                    if v24 == 6 then
                        surface_unrideable_score = p5.surface_unrideable_score
                        v7.prediction.result.contact_normal = rt.copy(p4.reference_up)
                    elseif v24 == 7 then
                        surface_unrideable_score = p5.surface_dont_align_score
                        v7.prediction.result.contact_normal = rt.copy(p4.reference_up)
                    else
                        surface_unrideable_score = if v24 == 8 then p5.surface_dont_align_score else 0
                    end
                else
                    surface_unrideable_score = 0
                end

                v7.normal = rt.copy(v7.prediction.result.contact_normal)

                local v25, v26

                if p3 then
                    if p4.directional_input < 0.5 and v20 > 0 then
                        v7.grind = nil
                        v20 = PointGraph.evaluate(p5.grind_penalty_vs_distance, 0)
                    end

                    v25 = v20

                    local v27 = if p4.directional_input >= 0.5 then 1 else -1
                    local v28 = rt.copy(p4.heading_direction)

                    v28[2] = 0

                    local v30 = if math.abs(v7.prediction.result.contact_time - t1.apex_time(v7.prediction)) >= p5.minimum_time_after_apex then 0 else -500
                    local v32 = (1 - math.abs(p4.ground_normal[2])) * v27 * p5.score_transition

                    v26 = dot(v7.normal, normalize(v28)) * v32 + v30
                else
                    v25 = v20
                    v26 = 0
                end

                v7.score = PointGraph.evaluate(p5.landing_time_bonus, v7.prediction.result.contact_time) + (v16 + 1 + v15 + v11 + v25 + v26)
                v7.score += surface_unrideable_score
            end

            v10 = false
        else
            v10 = v6
        end

        n1 = v9
        v6 = v10
    end

    for _, v33 in p1 do
        if QueryResult.valid(v33.prediction.result) and v33.prediction.result.contact_frame >= p5.minimum_trajectory_frames then
            if v33.wall_score == 0 and n1 < Prediction.collision_position(v33.prediction)[2] then
                v33.wall_score = 2000
            end

            v33.score += v33.wall_score
        end
    end

    return v6
end

function t1.apex_time(p8) -- line: 143
    -- upvalues: reciprocal (copy)
    local v34 = p8.request.trajectory.velocity[2]
    local v35 = p8.request.trajectory.acceleration[2]

    if v34 < 0 or v35 >= 0 then
        return 0
    end

    return v34 * reciprocal(-v35)
end

function t1.wall_score(p9, p10, p11, p12, p13) -- line: 155
    -- upvalues: rt (copy), PointGraph (copy), Prediction (copy), adjust_trajectory (copy), dot (copy), add (copy), sub (copy), madd (copy), reciprocal (copy), length (copy)
    local v36 = rt.copy(p9.result.contact_normal)

    if not (math.abs(v36[2]) < 0.5) then
        return 0, p12
    end

    local v38 = madd(v36, p11.wall_ride_test_distance, p9.result.contact_position)
    local v39 = p13(v38, add(v38, { 0, -10, 0, 0 }), 0)

    if v39 == nil or not (dot(v39.normal, v36) < p11.wall_ride_normal_dot_limit) then
        return 0, p12
    end

    local v41 = math.abs(v39.position[2] - v38[2])

    if p10 then
        return v41 * p11.wall_ride_height_score - 1000, p12
    end

    local v42 = Prediction.collision_position(p9)
    local v43 = sub(p9.request.trajectory.position, v42)
    local v44 = v43[2]

    v43[2] = 0

    local v45 = length(v43)

    if v45 > 0.009999999776482582 then
        v44 *= reciprocal(v45)
    end

    if p11.wall_ride_angle_allow_landing < v44 then
        return v41 * p11.wall_ride_height_score - 1000, p12
    end

    if v41 < p11.wall_ride_minimum_height then
        return v41 - 1000, p12
    end

    local v46 = PointGraph.evaluate(p11.wall_ride_boost, v41)
    local v47 = if p12 < v42[2] then v42[2] else p12

    adjust_trajectory(p9.request.trajectory, p9.result.contact_frame, { 0, v46, 0, 0 }, p11.maximum_trajectory_adjust)

    return v41 * p11.wall_ride_height_score, v47
end

return t1
