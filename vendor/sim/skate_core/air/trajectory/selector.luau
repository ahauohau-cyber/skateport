-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/air/trajectory/math")
local v2 = import("skate_core/air/trajectory/prediction")
local v3 = import("skate_core/air/trajectory/launch")
local v4 = import("skate_core/air/trajectory/scoring")
local PointGraph = import("skate_core/point_graph").PointGraph
local QueryResult = v2.QueryResult
local ZERO, dot, add, sub = v1.ZERO, v1.dot, v1.add, v1.sub
local scale, angle_between = v1.scale, v1.angle_between
local t1 = {
    WorldWithoutGrindEdges = {},
    Selection = {},
    TrajectorySelector = {}
}
local TrajectorySelector = t1.TrajectorySelector

function t1.TrajectorySelector.default() -- line: 58
    return {
        launch_info = nil,
        batch = nil,
        selection = nil,
        selected_index = nil,
        grind_locked_to_middle = false,
        grind_normal = nil,
        pass = 0,
        adjusted_on_vert = false,
        pending = false,
        valid = false,
        just_changed = false,
        all_predictions_missed = false,
        suggested_normal = nil,
        candidates = {}
    }
end

function t1.TrajectorySelector.new() -- line: 77
    -- upvalues: TrajectorySelector (copy)
    return TrajectorySelector.default()
end

function t1.TrajectorySelector.pending(p1) -- line: 80
    return p1.pending
end

function t1.TrajectorySelector.valid(p2) -- line: 83
    return p2.valid
end

function t1.TrajectorySelector.just_changed(p3) -- line: 86
    return p3.just_changed
end

function t1.TrajectorySelector.all_predictions_missed(p4) -- line: 89
    return p4.all_predictions_missed
end

function t1.TrajectorySelector.suggested_normal(p5) -- line: 92
    -- upvalues: rt (copy)
    return rt.copy(p5.suggested_normal)
end

function t1.TrajectorySelector.selection(p6) -- line: 96
    return p6.selection
end

function t1.TrajectorySelector.selected_index(p7) -- line: 99
    return p7.selected_index
end

function t1.TrajectorySelector.grind_locked_to_middle(p8) -- line: 102
    return p8.grind_locked_to_middle
end

function t1.TrajectorySelector.grind_normal(p9) -- line: 105
    -- upvalues: rt (copy)
    return rt.copy(p9.grind_normal)
end

function t1.TrajectorySelector.launch_info(p10) -- line: 109
    return p10.launch_info
end

function t1.TrajectorySelector.requests(p11) -- line: 113
    if p11.batch == nil then
        return {}
    end

    return p11.batch.requests
end

function t1.TrajectorySelector.com_displacement(p12) -- line: 119
    -- upvalues: rt (copy)
    if p12.batch == nil then
        return nil
    end

    return rt.copy(p12.batch.com_displacement)
end

function t1.TrajectorySelector.local_com_position(p13) -- line: 125
    -- upvalues: rt (copy)
    if p13.batch == nil then
        return nil
    end

    return rt.copy(p13.batch.local_com_position)
end

function t1.TrajectorySelector.local_board_position(p14) -- line: 131
    -- upvalues: rt (copy)
    if p14.batch == nil then
        return nil
    end

    return rt.copy(p14.batch.local_board_position)
end

function t1.TrajectorySelector.board_position(p15) -- line: 137
    -- upvalues: rt (copy)
    if p15.batch == nil then
        return nil
    end

    return rt.copy(p15.batch.board_position)
end

function t1.TrajectorySelector.query_origin(p16) -- line: 143
    -- upvalues: rt (copy)
    if p16.batch == nil then
        return nil
    end

    return rt.copy(p16.batch.origin)
end

function t1.TrajectorySelector.update_without_completion(p17) -- line: 150
    p17.just_changed = false

    return p17.valid
end

function t1.TrajectorySelector.cancel_pending(p18) -- line: 155
    p18.pending = false
end

function t1.TrajectorySelector.reset(p19) -- line: 161
    -- upvalues: rt (copy), ZERO (copy)
    p19.valid = false
    p19.suggested_normal = nil
    p19.grind_normal = nil
    p19.just_changed = false
    p19.all_predictions_missed = false
    p19.pass = 0
    p19.grind_locked_to_middle = false

    if p19.selection ~= nil then
        p19.selection.com_trajectory = {
            duration = -1,
            position = rt.copy(ZERO),
            velocity = rt.copy(ZERO),
            acceleration = rt.copy(ZERO)
        }
    end
end

function t1.TrajectorySelector.launch(p20, p21, p22, p23) -- line: 182
    -- upvalues: rt (copy), v3 (copy), TrajectorySelector (copy)
    local v5 = rt.copy(p21)

    if p20.pending then
        return false
    end

    if v5.trajectory_count == 0 then
        error("GetLaunchInfo supplied zero trajectory candidates", 0)
    end

    p20.pass = 0
    p20.valid = false
    p20.selected_index = nil
    p20.grind_normal = nil
    p20.adjusted_on_vert = v3.adjust_velocity(v5, p22, p23)
    p20.launch_info = v5
    TrajectorySelector.launch_pass(p20, p22, p23)

    return true
end

function t1.TrajectorySelector.launch_pass(p24, p25, p26) -- line: 202
    -- upvalues: rt (copy), v3 (copy), QueryResult (copy), ZERO (copy)
    if p24.launch_info == nil then
        error("Launch owns the packet before its batch", 0)
    end

    local v6 = rt.copy(p24.launch_info)

    p24.all_predictions_missed = false

    if p24.selection ~= nil then
        p24.selection.wall_ride = false
    end

    local v7 = v3.batch(v6, p25, p26)
    local v10 = math.max(#p24.candidates, #v7.requests)

    for i = #p24.candidates + 1, v10 do
        p24.candidates[i] = {
            score = 0,
            wall_score = 0,
            wall_ride = false,
            grind = nil,
            prediction = {
                request = rt.copy(v7.requests[1]),
                result = QueryResult.miss()
            },
            start_velocity = rt.copy(ZERO),
            normal = rt.copy(ZERO),
            collision_velocity = rt.copy(ZERO),
            collision_position = rt.copy(ZERO)
        }
    end

    for i = 0, math.min(#p24.candidates, #v7.requests) - 1 do
        local v13 = p24.candidates[i + 1]

        v13.start_velocity = rt.copy(v7.velocities[i + 1])
        v13.prediction = {
            request = rt.copy(v7.requests[i + 1]),
            result = QueryResult.miss()
        }
    end

    p24.batch = v7
    p24.pending = true
end

function t1.TrajectorySelector.complete_batch(p27, p28, p29, p30, p31, p32) -- line: 248
    -- upvalues: rt (copy), v4 (copy), ZERO (copy), angle_between (copy), TrajectorySelector (copy)
    p27.just_changed = false

    if p27.pending then
        local v14 = #TrajectorySelector.requests(p27)

        if #p28 ~= v14 then
            error("Trajectory completion count differs from submitted batch", 0)
        end

        p27.just_changed = p27.pass == 2
        p27.pending = false
        p27.pass += 1

        for i = 1, math.min(#p27.candidates, #p28) do
            p27.candidates[i].prediction.result = rt.copy(p28[i])
        end

        local v17 = table.create(v14)

        for i = 1, v14 do
            v17[i] = p27.candidates[i]
        end

        p27.all_predictions_missed = v4.score(v17, p27.pass, p27.adjusted_on_vert, p29, p30, p31, p32)

        local v19 = math.min(#p27.candidates, v14) - 1
        local n1 = 0
        local n2 = -1E+08

        for i = 0, v19 do
            local v20 = p27.candidates[i + 1]

            if n2 < v20.score then
                n1 = i
                n2 = v20.score
            end
        end

        local v21 = rt.copy(p27.candidates[n1 + 1])

        for i = 1, math.min(#p27.candidates, v14) do
            local grind = p27.candidates[i].grind

            if grind ~= nil then
                p27.grind_normal = rt.copy(grind.vertical_normal)
                break
            end
        end

        p27.selected_index = n1

        local v23 = if p27.selection == nil then nil else rt.copy(p27.selection.com_trajectory)

        if v23 == nil then
            v23 = {
                duration = -1,
                position = rt.copy(ZERO),
                velocity = rt.copy(ZERO),
                acceleration = rt.copy(ZERO)
            }
        end

        local t2 = {
            candidate_index = n1,
            prediction = rt.copy(v21.prediction),
            start_velocity = rt.copy(v21.start_velocity),
            landing_normal = rt.copy(v21.normal),
            collision_velocity = rt.copy(v21.collision_velocity),
            collision_position = rt.copy(v21.collision_position),
            com_trajectory = v23,
            surface_category = if p27.selection == nil then 0 else p27.selection.surface_category,
            wall_ride = v21.wall_ride,
            grind = rt.copy(v21.grind)
        }

        if v21.prediction.result.contact_time < p30.minimum_valid_time then
            p27.suggested_normal = rt.copy(v21.prediction.result.contact_normal)
            p27.valid = false
            p27.just_changed = false
            p27.selection = t2

            return false
        end

        t2.surface_category = bit32.band(bit32.rshift(v21.prediction.result.surface, 7), 31)
        t2.com_trajectory = TrajectorySelector.com_trajectory(p27, t2, p29, p30)

        if n1 == 0 then
            p27.grind_locked_to_middle = v21.grind ~= nil
        else
            p27.grind_locked_to_middle = false
        end

        local v25, v26

        if p27.pass == 1 and v14 >= 2 then
            local v27 = not p27.grind_locked_to_middle

            if v27 then
                v25 = angle_between(t2.landing_normal, p29.ground_normal) < p30.minimum_normal_delta_second_pass
                v26 = not v25
            else
                v26 = v27
            end
        else
            v26 = false
        end

        p27.selection = rt.copy(t2)
        p27.valid = true

        if v26 then
            if p27.launch_info == nil then
                error("completed launch packet", 0)
            end

            local launch_info = p27.launch_info

            launch_info.start_velocity = rt.copy(t2.start_velocity)
            launch_info.cone_angle_x = p30.cone_x_second_pass
            launch_info.cone_angle_z = p30.cone_z_second_pass
            TrajectorySelector.launch_pass(p27, p29, p30)
            p27.pass = 2
        end
    end

    return p27.valid
end

function t1.TrajectorySelector.com_trajectory(p33, p34, p35, p36) -- line: 345
    -- upvalues: rt (copy), v3 (copy), PointGraph (copy), dot (copy), add (copy), sub (copy), scale (copy)
    if p33.launch_info == nil then
        error("completed launch packet", 0)
    end

    local v28 = rt.copy(p33.launch_info)

    if p33.batch == nil then
        error("completed query batch", 0)
    end

    local batch = p33.batch
    local v29 = rt.copy(p34.prediction.request.trajectory)
    local v30 = PointGraph.evaluate(p36.landing_com_scalar_vs_slope, p34.landing_normal[2])
    local v31 = sub(v28.animation_com_position, v29.position)
    local v33 = math.abs((dot(p35.reference_up, sub(batch.origin, v28.animation_com_position)))) * v30
    local v34 = scale(p34.landing_normal, v33)

    if p34.prediction.result.contact_frame > 0 then
        v29.position = add(v29.position, v31)
        v3.adjust_trajectory(v29, p34.prediction.result.contact_frame, sub(v34, v31), p36.maximum_trajectory_adjust)
    end

    return v29
end

return t1
