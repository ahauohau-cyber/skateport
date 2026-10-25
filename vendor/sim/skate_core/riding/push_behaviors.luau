-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/riding/push_animation")
local v2 = import("skate_core/point_graph")
local v3 = import("skate_core/physics/native_arithmetic")
local PushAnimationCurves = v1.PushAnimationCurves
local PointGraph = v2.PointGraph
local t1 = {
    PushClipMetrics = {},
    PushAttributes = {}
}

function t1.PushAttributes.from_clips(p1) -- line: 38
    -- upvalues: rt (copy), t1 (copy)
    local native_min, native_max = t1.native_min, t1.native_max
    local t2 = {
        p1[1].begin_velocity,
        p1[2].begin_velocity,
        p1[3].begin_velocity,
        p1[4].begin_velocity
    }
    local t3 = {
        p1[1].end_velocity - p1[1].begin_velocity,
        p1[2].end_velocity - p1[2].begin_velocity,
        p1[3].end_velocity - p1[3].begin_velocity,
        p1[4].end_velocity - p1[4].begin_velocity
    }

    return {
        clips = rt.copy(p1),
        minimum_begin_velocity = native_min(native_min(t2[1], t2[2]), native_min(t2[3], t2[4])),
        maximum_begin_velocity = native_max(native_max(t2[1], t2[2]), native_max(t2[3], t2[4])),
        minimum_delta_velocity = native_min(native_min(t3[1], t3[2]), native_min(t3[3], t3[4])),
        maximum_delta_velocity = native_max(native_max(t3[1], t3[2]), native_max(t3[3], t3[4]))
    }
end

function t1.PushAttributes.target(p2, p3, p4) -- line: 65
    -- upvalues: rt (copy), t1 (copy)
    local bounded, velocity_blend, blended_end, unit = t1.bounded, t1.velocity_blend, t1.blended_end, t1.unit
    local v4 = bounded(t1.nonnegative(p3), p2.minimum_begin_velocity, p2.maximum_begin_velocity)
    local v5 = bounded(p4, p2.minimum_delta_velocity, p2.maximum_delta_velocity)
    local v6 = rt.copy(p2.clips)
    local v7 = v6[1]
    local v8 = v6[2]
    local v9 = v6[3]
    local v10 = v6[4]
    local v11 = bounded(v4, v7.begin_velocity, v8.begin_velocity)
    local v12 = bounded(v4, v9.begin_velocity, v10.begin_velocity)
    local v13 = velocity_blend(v11, v7.length, v7.begin_velocity, v8.length, v8.begin_velocity)
    local v14 = velocity_blend(v12, v9.length, v9.begin_velocity, v10.length, v10.begin_velocity)
    local v15 = (1 - v13) * v7.length + v8.length * v13
    local v16 = (1 - v14) * v9.length + v10.length * v14
    local v17 = blended_end(v13, v7, v8)
    local v18 = blended_end(v14, v9, v10)
    local v19 = velocity_blend(bounded(v5 + v4, v18, v17), v16, v18, v15, v17)

    return {
        hstr_vel_b = unit(v13),
        lstr_vel_b = unit(v14),
        vel_e = unit(v19)
    }
end

function t1.PushAttributes.out_factor(p5, p6, p7, p8, p9) -- line: 105
    -- upvalues: t1 (copy)
    local bounded, unit = t1.bounded, t1.unit
    local v20 = p5.minimum_begin_velocity + p5.minimum_delta_velocity
    local v21 = bounded(t1.nonnegative(p6), v20, p5.maximum_begin_velocity)
    local v22 = unit((bounded(p7, p5.minimum_delta_velocity, p5.maximum_delta_velocity) - p5.minimum_delta_velocity) / (p5.maximum_delta_velocity - p5.minimum_delta_velocity))
    local v23 = unit((v21 - v20) / (p5.maximum_begin_velocity - v20))
    local v24 = v22 * (1 - p8) + v23 * p8

    if -v24 >= 0 then
        v24 = 0
    end

    return t1.native_min(p9, v24)
end

function t1.velocity_blend(p10, p11, p12, p13, p14) -- line: 125
    -- upvalues: t1 (copy)
    local v25 = p11 * p12
    local v26 = p10 * p11
    local v27 = p13 * p14 + v26
    local v28 = v26 - v25
    local v29 = -(p10 * p13 + -(v27 - v25))

    return t1.unit(v28 / v29)
end

function t1.blended_end(p15, p16, p17) -- line: 134
    -- upvalues: t1 (copy)
    local v30 = t1.unit(p15)
    local v31 = v30 * p17.length
    local v32 = (1 - v30) * p16.length

    return (p17.end_velocity * v31 + p16.end_velocity * v32) / (v31 + v32)
end

function t1.native_min(p18, p19) -- line: 141
    if p18 - p19 >= 0 then
        return p19
    end

    return p18
end

function t1.native_max(p20, p21) -- line: 149
    if p20 - p21 >= 0 then
        return p20
    end

    return p21
end

function t1.bounded(p22, p23, p24) -- line: 157
    -- upvalues: t1 (copy)
    return t1.native_min(p24, t1.native_max(p23, p22))
end

function t1.nonnegative(p25) -- line: 161
    if p25 >= 0 then
        return p25
    end

    return 0
end

function t1.unit(p26) -- line: 169
    local v33 = if -p26 >= 0 then 0 else p26

    if 1 - v33 >= 0 then
        return v33
    end

    return 1
end

t1.PushState = {}

function t1.PushState.initialize_push(p27) -- line: 193
    -- upvalues: rt (copy)
    p27.continue_push = false
    p27.current_push_dv = 0
    p27.current = {
        hstr_vel_b = -1,
        lstr_vel_b = -1,
        vel_e = -1
    }
    p27.target = rt.copy(p27.current)
end

t1.FirstPushStrength = {}

function t1.FirstPushStrength.begin(p28, p29) -- line: 213
    return {
        simulated_held_seconds = 0,
        first_push = true,
        first_update = true,
        push_from_teleport = p28 < p29
    }
end

function t1.FirstPushStrength.update(p30, p31, p32, p33, p34, p35) -- line: 225
    -- upvalues: PushAnimationCurves (copy), t1 (copy)
    if p33 == nil then
        p30.first_push = false
    end

    if p30.first_push or p30.push_from_teleport then
        local simulated_held_seconds

        if p30.push_from_teleport then
            simulated_held_seconds = p30.simulated_held_seconds
            p30.simulated_held_seconds = p35 + p30.simulated_held_seconds
        else
            simulated_held_seconds = if p33 ~= nil then p33 else 0
        end

        local v34 = PushAnimationCurves.strength(p32, simulated_held_seconds, t1.nonnegative(p34))

        if p31.current_push_dv < v34 then
            p31.current_push_dv = v34
        end
    end

    p30.first_update = false
end

t1.PushIntents = {}

function t1.PushIntents.default() -- line: 257
    return {
        pushing = nil,
        new_push = false,
        configured_foot = false
    }
end

t1.PushCyclePhase = {}
t1.PushCycle = {}

function t1.PushCycle.begin(p36, p37, p38) -- line: 275
    -- upvalues: PointGraph (copy)
    local v35 = p38.pushing ~= nil and p38.configured_foot

    p36.continue_push = v35

    return {
        phase = if v35 then "HoldingFirst" else "WaitingNext",
        next_push_dv = PointGraph.evaluate(p37.button_time_to_dv, 0)
    }
end

function t1.PushCycle.update(p39, p40, p41, p42, p43, p44) -- line: 292
    -- upvalues: PushAnimationCurves (copy), PointGraph (copy), t1 (copy)
    local v36 = t1.nonnegative(p43)

    if p39.phase == "HoldingFirst" then
        local pushing = p42.pushing

        if pushing ~= nil then
            p39.next_push_dv = PushAnimationCurves.strength(p41, pushing, v36)

            if p44 < p39.next_push_dv then
                p39.next_push_dv = p44
                p40.current_push_dv = p44
            end

            if p40.current_push_dv < p39.next_push_dv then
                p40.current_push_dv = p39.next_push_dv
            end
        else
            p39.phase = "WaitingNext"
            p39.next_push_dv = PointGraph.evaluate(p41.button_time_to_dv, 0)
            p40.continue_push = false
        end
    end

    if p39.phase == "WaitingNext" and p42.new_push and p42.configured_foot then
        p39.phase = "HoldingNext"
    end

    if p39.phase == "HoldingNext" and not p42.configured_foot then
        p39.phase = "NextReleased"
        p40.current_push_dv = p39.next_push_dv
    end

    if p39.phase == "HoldingNext" then
        local v37 = if p42.pushing == nil then 0 else p42.pushing

        p39.next_push_dv = PushAnimationCurves.strength(p41, v37, v36)

        if p40.current_push_dv < p39.next_push_dv then
            p40.current_push_dv = p39.next_push_dv
        end

        p40.continue_push = true
    end
end

t1.PushFootFrame = {}

function t1.PushFootFrame.out_distance(p45, p46) -- line: 348
    -- upvalues: rt (copy), v3 (copy)
    local v38 = if p46 then rt.copy(p45.right_foot) else rt.copy(p45.left_foot)
    local t4 = {
        v38[1] - p45.deck_position[1],
        v38[2] - p45.deck_position[2],
        v38[3] - p45.deck_position[3],
        v38[4] - p45.deck_position[4]
    }
    local v39 = if p45.skateboard_flipped then {
        -p45.deck_z[1],
        -p45.deck_z[2],
        -p45.deck_z[3],
        -p45.deck_z[4]
    } else rt.copy(p45.deck_z)

    return {
        v3.dot3(t4, v39),
        v3.dot3(t4, p45.deck_y)
    }
end

return t1
