-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/player/offboard/air_selector/math")
local v2 = import("skate_core/player/offboard/air_selector/ledge")
local v3 = import("skate_core/air/trajectory")
local QueryResult, Trajectory = v3.QueryResult, v3.Trajectory
local v4 = import("skate_core/player/offboard/biped_air/selection")
local SelectorState = import("skate_core/player/offboard/biped_air/sampling").SelectorState

local function air_selector() -- line: 15
    -- upvalues: import (copy)
    return import("skate_core/player/offboard/air_selector")
end

local dot, sub, UP = v1.dot, v1.sub, v1.UP
local t1 = {
    Selector = {}
}

function t1.Selector.observe_launch(p1, p2) -- line: 31
    -- upvalues: rt (copy), import (copy), QueryResult (copy), Trajectory (copy), UP (copy)
    local DT = import("skate_core/player/offboard/air_selector").DT

    if not p1.sampling.pending_8492 or #p2 ~= #p1.candidates then
        error("BipedAir launch completion does not match pending batch", 0)
    end

    for i = 1, math.min(#p1.candidates, #p1.predictions, #p2) do
        local v8 = p1.candidates[i]
        local v9 = p1.predictions[i]
        local v10 = rt.copy(p2[i])

        v9.result = rt.copy(v10)

        if QueryResult.valid(v10) then
            v8.contact_position_96 = rt.copy(v10.contact_position)
            v8.normal_64 = QueryResult.suggested_normal(v10)
            v9.result.contact_normal = rt.copy(v8.normal_64)
            v8.contact_velocity_80 = Trajectory.velocity_at(v8.trajectory, v10.contact_frame * DT)
            v8.landing_frame_116 = v10.contact_frame
            v8.valid_120 = true
        else
            v8.normal_64 = rt.copy(UP)
            v8.contact_velocity_80 = { 0, 0, 0, 0 }
            v8.landing_frame_116 = 120
            v8.valid_120 = false
        end
    end
end

function t1.Selector.select_launch(p3, p4, p5, p6) -- line: 62
    -- upvalues: rt (copy), import (copy), v2 (copy), v4 (copy), SelectorState (copy), dot (copy), sub (copy)
    local DT = import("skate_core/player/offboard/air_selector").DT

    if not p3.sampling.pending_8492 or #p3.candidates == 0 then
        error("BipedAir select without pending launch", 0)
    end

    if p6 ~= nil then
        v2.Adjustment.apply(p6, p3.candidates[1])
        p3.ledge_normal_8320 = rt.copy(p3.candidates[1].normal_64)
        p3.ledge_selected_8496 = true
    end

    for i = 0, #p3.candidates - 1 do
        local v11 = rt.copy(p3.candidates[i + 1])

        p3.scores[i + 1] = 0

        if v11.valid_120 then
            local v12 = if i == 0 then rt.copy(p5) else v11
            local v13 = sub(v12.contact_position_96, v12.trajectory.position)
            local v14 = rt.copy(v12.normal_64)
            local v15 = v11.landing_frame_116 * DT
            local v16 = if i ~= 0 or not p3.ledge_selected_8496 then 0 else 1
            local n1 = 0

            if v15 <= 0.5 then
                v16 = 0
                n1 = -1 - (0.5 - v15) * 2
            end

            local v17 = if i == 0 then 1 else 0

            if bit32.band(p3.predictions[i + 1].result.surface, 3968) == 768 then
                p3.predictions[i + 1].result.contact_normal = rt.copy(p4.up_544)
            end

            local v18 = rt.fmin(2.2222223 * ((v14[2] - 0.45) * 5), 0)

            if dot(v14, p3.launch.forward_64) > 0 then
                v18 = 0
            end

            local v19 = rt.fmax(dot(p3.launch.forward_64, v13), 1)
            local v20 = rt.fmax(v13[2], 0)

            if p3.launch.kind_108 <= i then
                if v13[2] < 0.4 then
                    v20 -= 10000
                else
                    v20 *= 8
                    v19 = dot(p3.launch.secondary_velocity_16, v13)
                end
            end

            p3.scores[i + 1] = 0 + v19 + v20 + v18 + v17 + n1 + v16
        end
    end

    local v21 = v4.selected_index(p3.scores)

    if v21 == nil then
        error("BipedAir empty candidate batch", 0)
    end

    p3.selected_index = v21
    p3.selected_candidate = rt.copy(p3.candidates[v21 + 1])

    if SelectorState.commit(p3.sampling, p3.selected_candidate, p3.predictions[v21 + 1], p3.offset_8272) then
        p3.just_changed_8497 = true
    end

    return v21
end

function t1.Selector.complete_requery(p7, p8) -- line: 124
    -- upvalues: rt (copy), import (copy), QueryResult (copy), Trajectory (copy), dot (copy), sub (copy)
    local DT = import("skate_core/player/offboard/air_selector").DT

    if not p7.requery_pending_8499 then
        error("BipedAir requery completion without submission", 0)
    end

    p7.requery_pending_8499 = false

    if #p7.predictions > 0 then
        rt.assign(p7.predictions[1], p8)
    end

    if not QueryResult.valid(p8.result) then
        return
    end

    local v22 = rt.copy(p8.result)

    if p7.requery_count_8488 <= 0 then
        p7.requery_position_8352 = rt.copy(v22.contact_position)
        p7.requery_normal_8368 = QueryResult.suggested_normal(v22)
    else
        local v23 = sub(p7.requery_position_8352, v22.contact_position)

        if dot(v23, v23) > 1E-04 then
            p7.requery_position_8352 = rt.copy(v22.contact_position)
            p7.requery_normal_8368 = QueryResult.suggested_normal(v22)

            local selection = p7.sampling.selection

            selection.landing_frame_8480 = v22.contact_frame
            selection.scalar_8392 = v22.contact_frame * DT
            selection.velocity_6160 = Trajectory.velocity_at(p8.request.trajectory, v22.contact_frame * DT)
            selection.position_6176 = rt.copy(v22.contact_position)
            selection.normal_6144 = QueryResult.suggested_normal(v22)
        end
    end

    p7.requery_count_8488 = rt.to_i32(rt.wrapping_add_u32(rt.to_u32(p7.requery_count_8488), rt.to_u32(1)))
end

return t1
