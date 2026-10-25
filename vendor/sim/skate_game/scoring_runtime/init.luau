-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local FilteredCategory = import("skate_core/physics/filtered_state").FilteredCategory
local v1 = import("skate_core/scoring/carrier")
local LINKS = import("skate_core/scoring/conversions").LINKS
local IDENTIFIERS = import("skate_core/scoring/catalog").IDENTIFIERS
local v2 = import("skate_core/scoring")
local Session = import("skate_core/scoring/session").Session
local PointTimer = import("skate_core/scoring/timer").PointTimer
local PointGraph = import("skate_core/point_graph").PointGraph
local v3 = import("skate_data/scoring")
local v4 = import("skate_game/scoring_runtime/display")
local v5 = import("skate_game/scoring_runtime/rotation")
local Carrier, delay_ticks = v1.Carrier, v1.delay_ticks
local Scorable, ScoreHolder = v2.Scorable, v2.ScoreHolder
local ScoringData, CollectorTuning = v3.ScoringData, v3.CollectorTuning
local Rotation = v5.Rotation
local t1 = {
    Collector = {},
    Frame = {},
    Runtime = {}
}
local Runtime = t1.Runtime

local function saturating_add_u32(p1, p2) -- line: 73
    local v6 = p1 + p2

    if v6 > 4294967295 then
        return 4294967295
    end

    return v6
end

function t1.Runtime.load(p3) -- line: 81
    -- upvalues: Session (copy), ScoringData (copy), Rotation (copy)
    return {
        data = ScoringData.load(p3),
        session = Session.default(),
        collector = "None",
        carriers = {},
        held = table.create(4, 0),
        distance = table.create(4, 0),
        metric_rewards = table.create(4, 0),
        metric_started = table.create(4, false),
        start = table.create(3, 0),
        previous = table.create(3, 0),
        rotation = Rotation.default(),
        spin_turns = 0,
        body_flip_count = 0,
        display_id = nil,
        air_stance = table.create(2, false),
        air_display_started = false,
        line_hold_ticks = 0,
        spin = 0,
        peak = 0,
        air_factor = 1,
        air_repetition = 1,
        air_repetition_set = false,
        grab_chain = 0,
        air_metrics = table.create(5, 0),
        landing_countdown = 0,
        idle_ticks = 0,
        collector_ticks = 0,
        manual_revert_ticks = 0,
        revert_id = nil,
        sequence_active = false,
        sequence_score = 0,
        trick_name = "",
        display_base = "",
        display_spin_degrees = 0,
        trick_seq = 0,
        landing_seq = 0,
        landed_trick = "",
        landed_base = "",
        landed_spin_degrees = 0,
        landed_clean = false,
        landed_sketchy = false,
        bail_seq = 0,
        settled_trick_seq = 0,
        was_bailing = false,
        stance = table.create(4, false),
        clean = false,
        sketchy = false,
        new_trick = false,
        modified_trick = false,
        close_tricks = false
    }
end

function t1.Runtime.trick_name(p4) -- line: 136
    return p4.trick_name
end

function t1.Runtime.trick_seq(p5) -- line: 140
    return p5.trick_seq
end

function t1.Runtime.sequence_score(p6) -- line: 144
    return p6.sequence_score
end

function t1.Runtime.sequence_active(p7) -- line: 148
    return p7.sequence_active
end

function t1.Runtime.line_score(p8) -- line: 152
    return p8.session.holder.snapshot.line
end

function t1.Runtime.multiplier(p9) -- line: 156
    return p9.session.combo.multiplier
end

function t1.Runtime.line_time(p10) -- line: 160
    -- upvalues: rt (copy)
    local v7 = rt.fmax(p10.data.line_drain, 1E-04)

    return p10.session.line.points / v7
end

function t1.Runtime.clean(p11) -- line: 165
    return p11.clean
end

function t1.Runtime.sketchy(p12) -- line: 169
    return p12.sketchy
end

function t1.Runtime.stance(p13) -- line: 173
    -- upvalues: rt (copy)
    return rt.copy(p13.stance)
end

function t1.Runtime.hud_input(p14) -- line: 179
    -- upvalues: rt (copy)
    return {
        sequence_score = rt.f_to_i32(p14.sequence_score),
        line_score = rt.f_to_i32(p14.session.holder.snapshot.line),
        sequence_timer = rt.f_to_i32(p14.session.line.points / p14.data.line_drain),
        line_time = p14.session.line.points / p14.data.line_drain,
        line_capacity = p14.data.line_capacity,
        multiplier = p14.session.combo.multiplier,
        clean = p14.clean,
        sketchy = p14.sketchy,
        stance = rt.copy(p14.stance),
        trick_name = p14.trick_name,
        trick_metrics = {
            {
                tag = "Text",
                p14.trick_name
            },
            {
                tag = "Bool",
                p14.stance[1]
            },
            {
                tag = "Bool",
                p14.stance[2]
            },
            {
                tag = "Bool",
                p14.was_bailing
            },
            {
                tag = "Bool",
                p14.new_trick
            }
        },
        context_tricks = {}
    }
end

function t1.Runtime.penalty(p15, p16) -- line: 203
    -- upvalues: PointGraph (copy), Scorable (copy), ScoreHolder (copy), ScoringData (copy)
    local v8 = ScoringData.by_id(p15.data, p16)

    if v8 == nil or not Scorable.repetition_applies(v8.metadata) then
        return 1
    end

    local v9 = ScoreHolder.repetition_count(p15.session.holder, v8.metadata)

    if v9 == nil then
        v9 = 0
    end

    return PointGraph.evaluate(p15.data.repetition, v9)
end

function t1.Runtime.finish(p17, p18, p19, p20) -- line: 220
    -- upvalues: rt (copy), Carrier (copy), ScoreHolder (copy)
    local v10 = p17.carriers[p18 + 1]

    p17.carriers[p18 + 1] = nil

    if v10 ~= nil and p19 then
        Carrier.complete(v10, p17.data.unannounced_factor)

        if p17.collector == "Air" then
            ScoreHolder.end_trick(p17.session.holder, v10.scorable, v10.reward)
        else
            local v11 = p17.collector == "Grind" or p17.collector == "Ground" and p18 < 3
            local v12, v13

            if p20 then
                if p17.collector == "Ground" then
                    v13 = true
                else
                    v12 = 0
                    v13 = false
                end
            else
                v12 = if not v11 then v10.reward elseif v10.scorable.score_type == 9 then rt.fmax(v10.reward, p17.metric_rewards[p18 + 1]) else rt.fmax(p17.metric_rewards[p18 + 1], 0)
                v13 = false
            end

            if not v13 then
                ScoreHolder.credit_trick(p17.session.holder, v10.scorable, v12)
            end
        end
    end

    if p20 then
        return
    end

    p17.metric_started[p18 + 1] = false
    p17.held[p18 + 1] = 0
    p17.distance[p18 + 1] = 0
    p17.metric_rewards[p18 + 1] = 0
end

function t1.Runtime.carrier(p21, p22, p23, p24) -- line: 258
    -- upvalues: rt (copy), LINKS (copy), PointGraph (copy), v4 (copy), Carrier (copy), delay_ticks (copy), ScoringData (copy), CollectorTuning (copy), Runtime (copy)
    local v14 = p21.carriers[p22 + 1]

    if (if v14 == nil then nil else v14.scorable.id) ~= p23 then
        local v15 = if p23 ~= nil and p21.collector == "Air" and v14 ~= nil and LINKS[p23 + 1][2] >= 0 then p23 else nil
        local v16 = false

        if p21.collector == "Air" then
            local v17 = if p23 == nil then nil else ScoringData.by_id(p21.data, p23)

            v16 = v17 ~= nil and v17.metadata.class == 2 and v14 ~= nil and v14.scorable.class == 2 and not v14.announced
        end

        local v18 = if v14 == nil then nil else v14.start_tick
        local v19 = p23 ~= nil and (p21.collector == "Grind" or p21.collector == "Ground" and p22 == 0)

        if v15 == nil then
            if v16 then
                p21.carriers[p22 + 1] = nil
                p21.grab_chain += 1
            else
                Runtime.finish(p21, p22, true, v19)
                p21.grab_chain = 0
            end
        end

        if p23 ~= nil then
            local v20 = ScoringData.by_id(p21.data, p23)

            if v20 == nil then
                error(("Missing native scorable %*"):format(p23), 0)
            end

            local v21 = Runtime.penalty(p21, p23) * (if p21.collector == "Air" then p21.air_factor else 1)

            if not v16 or v18 == nil then
                v18 = p24.tick
            end

            local v24 = Carrier.new(v20.metadata, v20.points, v21, PointGraph.evaluate(p21.data.announcement, v20.points), v18, delay_ticks(v20.completion_delay, if p21.grab_chain > 1 then CollectorTuning.scalar(p21.data.collector, 1688) else 0), p24.switch, p24.fakie)
            local v25 = p21.carriers[p22 + 1]

            if v25 ~= nil then
                Carrier.convert_to(v25, v24, p21.data.unannounced_factor)
                p21.modified_trick = true
            end

            if v15 ~= nil then
                p21.display_id = p23
                p21.trick_name = v20.label
            end

            p21.carriers[p22 + 1] = v24
            p21.sequence_active = true
            p21.idle_ticks = 0
        end
    end

    local v26 = p21.carriers[p22 + 1]
    local v27 = if v26 == nil then 1 else Runtime.penalty(p21, v26.scorable.id)
    local v28 = false
    local v29 = false
    local v30 = false
    local v31 = false

    if v26 ~= nil then
        v28 = true
    else
        v31 = true
    end

    if v28 then
        if Carrier.announce(v26, p24.tick, p21.data.unannounced_factor) then
            v29 = true
        else
            v31 = false
        end
    end

    v28 = false

    local v32

    if v29 then
        v32 = ScoringData.by_id(p21.data, v26.scorable.id)

        if v32 ~= nil then
            v30 = true
        else
            v28 = true
        end
    end

    v29 = false

    if v28 then
        v30 = true
        error("Missing announced scorable", 0)
    end

    v28 = false

    if v30 then
        p21.trick_name = v32.label
        p21.display_id = v26.scorable.id

        if p21.collector == "Air" then
            v28 = true
        else
            v29 = true
        end
    end

    v30 = false

    if v28 then
        v29 = true
        p21.air_display_started = true
    end

    v28 = false

    local v33

    if v29 then
        p21.stance = {
            p24.switch,
            p24.fakie,
            true,
            v4.nollie(v32)
        }
        p21.new_trick = true
        v33 = p21.trick_seq + 1

        if v33 > 4294967295 then
            v30 = true
        else
            v28 = true
        end
    end

    v29 = false

    local v34

    if v28 then
        v34 = v33
        v29 = true
    end

    if v30 then
        v34 = 4294967295
        v29 = true
    end

    v30 = false

    if v29 then
        p21.trick_seq = v34

        if p21.collector == "Air" then
            v30 = true
        else
            v31 = false
        end
    end

    v29 = false

    if v30 then
        if p21.air_repetition_set then
            v31 = false
        else
            v29 = true
        end
    end

    if v29 then
        p21.air_repetition = v27
        v31 = false
        p21.air_repetition_set = true
    end

    if v31 then
        return
    end

    local v35 = p21.collector == "Grind" or p21.collector == "Ground" and p22 < 3
    local v36 = p21.metric_started[p22 + 1]

    p21.metric_started[p22 + 1] = true

    if not v26.announced or p21.collector == "Air" and p24.suspend_air then
        return
    end

    if not v35 or v36 then
        p21.held[p22 + 1] += p24.dt
    end

    local v37 = p21.distance[p22 + 1]
    local t2 = {
        p24.position[1] - p21.previous[1],
        p24.position[2] - p21.previous[2],
        p24.position[3] - p21.previous[3]
    }
    local v38 = if p21.collector ~= "Ground" or p22 ~= 1 then math.sqrt(0 + t2[1] * t2[1] + t2[2] * t2[2] + t2[3] * t2[3]) else 0 + t2[1] * p24.forward[1] + t2[2] * p24.forward[2] + t2[3] * p24.forward[3]

    if v36 and v38 > 0.004999999888241291 then
        p21.distance[p22 + 1] += v38
    end

    local v40 = if p21.collector == "Air" and v26.scorable.class == 2 then 1120 elseif p21.collector == "Offboard" then 320 else nil

    if v40 ~= nil then
        v26.reward += CollectorTuning.curve(p21.data.collector, v40, p21.held[p22 + 1]) * p24.dt * v26.announcement_threshold
    end

    local v41, v42

    if p21.collector == "Ground" and v26.scorable.score_type == 9 then
        v41 = 0
        v42 = 80
    elseif p21.collector == "Ground" and v26.scorable.score_type == 8 then
        v41 = 240
        v42 = 160
    elseif p21.collector == "Ground" and p22 == 2 then
        v41 = 560
        v42 = 480
    elseif p21.collector == "Grind" then
        v41 = 720
        v42 = 640
    end

    if v41 ~= nil then
        local v43 = rt.fmax(CollectorTuning.curve(p21.data.collector, v41, p21.distance[p22 + 1]) - CollectorTuning.curve(p21.data.collector, v41, v37), 0)

        p21.metric_rewards[p22 + 1] = (CollectorTuning.curve(p21.data.collector, v42, p21.held[p22 + 1]) * p24.dt + v43) * v26.announcement_threshold + p21.metric_rewards[p22 + 1]
    end
end

function t1.Runtime.advance(p25, p26) -- line: 427
    -- upvalues: rt (copy), FilteredCategory (copy), IDENTIFIERS (copy), Session (copy), PointTimer (copy), v4 (copy), ScoreHolder (copy), ScoringData (copy), CollectorTuning (copy), Rotation (copy), Runtime (copy)
    local data = p25.data
    local collector = data.collector
    local holder = p25.session.holder
    local v44 = p26.category == FilteredCategory.Wipeout

    if v44 and not p25.was_bailing then
        local v45 = p25.bail_seq + 1

        p25.bail_seq = if v45 > 4294967295 then 4294967295 else v45
    end

    p25.was_bailing = v44
    p25.new_trick = false
    p25.modified_trick = false
    p25.close_tricks = false

    local t3

    if p26.descriptor ~= nil then
        local v46 = ScoringData.by_name(data, p26.descriptor)

        if v46 ~= nil and (bit32.band(p26.flags, 33554432) == 0 or v46.metadata.id ~= 67 and v46.metadata.id ~= 68 and v46.metadata.id ~= 69) then
            t3 = {
                v46.metadata.id,
                v46.metadata.class,
                v46.metadata.score_type
            }
        end
    end

    local v47 = if p26.category == FilteredCategory.Ground then "Ground"
        elseif p26.category == FilteredCategory.Air then "Air"
        elseif p26.category == FilteredCategory.Grind then "Grind"
        elseif p26.category == FilteredCategory.Offboard or p26.category == FilteredCategory.OffboardAir then "Offboard"
        else "None"

    if p26.state == 600 and (v47 == "Ground" or v47 == "Air") then
        v47 = "Special"
    end

    if v47 == "Air" and p25.collector == "Ground" and t3 ~= nil and t3[2] == 0 then
        v47 = "Ground"
    end

    if v47 == "Ground" and p25.collector == "Air" and t3 ~= nil and t3[2] == 3 then
        v47 = "Air"
    end

    if p26.teleported then
        v47 = "None"
    end

    if v47 ~= p25.collector then
        if p25.collector == "Air" then
        end

        local v48 = v47 ~= "None"
        local v49 = p25.carriers[1]
        local score_type = if v49 == nil then nil else v49.scorable.score_type
        local v50 = p25.carriers[2]

        if v50 ~= nil then
            score_type = v50.scorable.score_type
        end

        local v51 = p25.carriers[3]

        if v51 ~= nil then
            score_type = v51.scorable.score_type
        end

        local v52 = p25.carriers[4]

        if v52 ~= nil then
            score_type = v52.scorable.score_type
        end

        for i = 0, 3 do
            Runtime.finish(p25, i, v48, false)
        end

        if p25.collector == "Air" then
            if v48 then
                local v53 = rt.copy(p25.air_metrics)

                for i = 0, 4 do
                    local v54 = v53[i + 1]
                    local v55 = i + 129
                    local v56 = IDENTIFIERS[v55 + 1]
                    local v57 = v56[2]
                    local v58 = v56[3]

                    ScoreHolder.end_trick(holder, {
                        id = v55,
                        class = v57,
                        score_type = v58
                    }, v54)
                end
            end

            ScoreHolder.finish_collector(holder)
            p25.landing_countdown = 2
        end

        p25.collector = v47
        p25.start = rt.copy(p26.position)
        p25.peak = p26.position[2]
        p25.spin = 0
        Rotation.reset(p25.rotation, p26.player_basis, p26.board_basis)
        p25.spin_turns = 0
        p25.body_flip_count = 0
        p25.air_metrics = table.create(5, 0)
        p25.air_repetition = 1
        p25.air_repetition_set = false
        p25.air_factor = 1
        p25.grab_chain = 0
        p25.collector_ticks = 0
        p25.manual_revert_ticks = 0
        p25.revert_id = nil

        if v47 == "Air" then
            p25.air_stance = {
                p26.switch,
                p26.fakie
            }
            p25.air_display_started = false
            p25.display_id = nil
            ScoreHolder.reward_sequence(holder, 1)
            p25.landing_countdown = 0

            if score_type == 8 then
                p25.air_factor *= CollectorTuning.scalar(collector, 1676)
            end

            if score_type == 5 then
                p25.air_factor *= CollectorTuning.scalar(collector, 1680)
            end

            local v59 = 0 + p26.reckoning_up[1] * p26.reckoning_up[1] + p26.reckoning_up[2] * p26.reckoning_up[2] + p26.reckoning_up[3] * p26.reckoning_up[3]
            local v60 = (0 + p26.velocity[1] * p26.reckoning_up[1] + p26.velocity[2] * p26.reckoning_up[2] + p26.velocity[3] * p26.reckoning_up[3]) / v59

            if 0 + (p26.velocity[1] - p26.reckoning_up[1] * v60) ^ 2 + (p26.velocity[2] - p26.reckoning_up[2] * v60) ^ 2 + (p26.velocity[3] - p26.reckoning_up[3] * v60) ^ 2 < CollectorTuning.scalar(collector, 1644) ^ 2 then
                p25.air_factor *= CollectorTuning.scalar(collector, 1672)
            end

            if p26.switch and not p26.fakie then
                p25.air_factor *= CollectorTuning.scalar(collector, 1668)
            end

            if p26.fakie and not p26.switch then
                p25.air_factor *= CollectorTuning.scalar(collector, 1684)
            end
        end
    end

    local t4 = {}

    if p25.collector ~= "Air" or not p26.suspend_air then
        local v61 = p25.collector_ticks + 1

        p25.collector_ticks = if v61 > 4294967295 then 4294967295 else v61
    end

    if p25.collector == "Ground" then
        t4[1] = if bit32.band(p26.flags, 2147483648) ~= 0 then 0 elseif bit32.band(p26.flags, 1073741824) == 0 then nil else 1
        t4[2] = if bit32.band(p26.flags, 134217728) ~= 0 then 2 elseif bit32.band(p26.flags, 67108864) == 0 then nil else 3

        if t4[2] == nil or not p26.reverting then
            p25.manual_revert_ticks = 0
        else
            p25.manual_revert_ticks += 1
            t4[2] = nil
        end

        if p25.manual_revert_ticks > 6 then
            t4[2] = nil
        end

        if t4[2] ~= nil then
            local v62 = p25.carriers[2]

            if v62 ~= nil then
                t4[2] = v62.scorable.id
            end
        end

        local v63 = t3 ~= nil and t3[1] == 60 and bit32.band(p26.flags, 33554432) ~= 0

        t4[3] = if v63 then t3[1] else nil

        if bit32.band(p26.flags, 536870912) == 0 then
            if bit32.band(p26.flags, 268435456) ~= 0 then
                p25.revert_id = 5
            end
        else
            p25.revert_id = 4
        end

        t4[4] = if p26.reverting then p25.revert_id else nil
    elseif p25.collector == "Air" then
        if t3 ~= nil and t3[3] ~= 5 then
            t4[1] = t3[1]
        end
    elseif p25.collector == "Grind" then
        if p26.grind_id >= 0 then
            t4[1] = p26.grind_id
        end
    elseif p25.collector == "Offboard" then
        if t3 ~= nil and t3[3] == 6 then
            t4[1] = t3[1]
        end
    elseif p25.collector == "Special" and t3 ~= nil and t3[1] == 234 then
        t4[1] = t3[1]
    end

    for i = 0, 3 do
        Runtime.carrier(p25, i, t4[i + 1], p26)
    end

    if p25.collector == "Air" and not p26.suspend_air then
        if p25.collector_ticks > 5 or bit32.band(p26.flags, 16777216) ~= 0 then
            p25.sequence_active = true
        end

        p25.spin = Rotation.update(p25.rotation, p26.player_basis, p26.board_basis, p26.reckoning_up, p25.carriers[1] ~= nil)
        p25.peak = rt.fmax(p25.peak, p26.position[2])

        local v64 = p26.position[1] - p25.start[1]
        local v65 = p26.position[3] - p25.start[3]
        local v66 = p25.air_factor * p25.air_repetition

        p25.air_metrics[1] = CollectorTuning.curve(collector, 960, (math.sqrt(v64 * v64 + v65 * v65))) * v66
        p25.air_metrics[2] = CollectorTuning.curve(collector, 1040, p25.peak - p25.start[2]) * v66
        p25.air_metrics[3] = CollectorTuning.curve(collector, 800, p26.position[2] - p25.start[2]) * v66

        local v69 = rt.f_to_i32((math.abs((math.deg(p25.spin))) + CollectorTuning.scalar(collector, 1596)) / 180)

        p25.air_metrics[4] = CollectorTuning.curve(collector, 880, v69 * 180) * v66

        if p25.spin < 0 then
            v69 = -v69
        end

        if v69 ~= p25.spin_turns then
            p25.spin_turns = v69

            if p25.display_id ~= nil or p25.spin_turns == 0 or p25.new_trick or p25.air_display_started then
                p25.modified_trick = true
            else
                p25.air_display_started = true
                p25.new_trick = true

                local v70 = p25.trick_seq + 1

                p25.trick_seq = if v70 > 4294967295 then 4294967295 else v70
            end
        end

        local v71 = p25.carriers[1]

        if p26.body_flip and v71 ~= nil and v71.announced and v71.scorable.class == 2 then
            local v72 = if p26.front_flip then 1 else -1

            if v72 ~= p25.body_flip_count then
                p25.body_flip_count = v72
                p25.modified_trick = true
            end
        end

        p25.air_metrics[5] = math.abs(p25.body_flip_count) * CollectorTuning.scalar(collector, 1600) * v66
    end

    if p25.new_trick or p25.modified_trick then
        local v73, v74

        if p25.collector == "Air" then
            v73 = p25.air_stance[1]
            v74 = p25.air_stance[2]
        else
            v73 = p26.switch
            v74 = p26.fakie
        end

        local v75, v76 = v4.compose(data, p25.display_id, p25.spin_turns, p25.body_flip_count, v73, v74, p26.regular)

        p25.display_base = v4.compose(data, p25.display_id, 0, 0, v73, v74, p26.regular)
        p25.display_spin_degrees = p25.spin_turns * 180
        p25.trick_name = v75
        p25.stance = v76
    elseif not p25.sequence_active then
        p25.stance = {
            p26.switch,
            p26.fakie,
            true,
            false
        }
    end

    local v77 = p25.carriers[1] ~= nil

    if p25.carriers[2] ~= nil then
        v77 = true
    end

    if p25.carriers[3] ~= nil then
        v77 = true
    end

    if p25.carriers[4] ~= nil then
        v77 = true
    end

    if not v77 then
        v77 = p25.collector == "Air" or p25.collector == "Ground" and bit32.band(p26.flags, 16777216) ~= 0
    end

    local v78

    if v77 then
        v78 = 0
    else
        v78 = p25.idle_ticks + 1

        if v78 > 4294967295 then
            v78 = 4294967295
        end
    end

    p25.idle_ticks = v78

    if ScoreHolder.has_pending_sequence(holder) then
        if p26.landing.landing_data_167 then
            p25.clean = p26.landing.landing_type_96 == 0

            if p26.landing.landing_type_96 == 1 and p26.landing.sideways_speed_84 > data.sketchy_side_speed then
                p25.sketchy = math.abs(p26.landing.spin_92) > 0.5
            else
                p25.sketchy = false
            end
        end

        if p25.landing_countdown == 0 then
            local v79 = if not p26.switch then 1 elseif p26.fakie then 1 else 1 * CollectorTuning.scalar(collector, 1564)

            if p26.fakie and not p26.switch then
                v79 *= CollectorTuning.scalar(collector, 1580)
            end

            if p25.collector == "Grind" then
                v79 *= CollectorTuning.scalar(collector, 1576)
            end

            if p25.clean then
                v79 *= CollectorTuning.scalar(collector, 1584)
            end

            if p25.sketchy then
                v79 *= CollectorTuning.scalar(collector, 1568)
            end

            ScoreHolder.reward_sequence(holder, v79)
        else
            p25.landing_countdown -= 1
        end
    end

    local v80, v81

    if p25.collector == "Air" then
        v80 = 1640
        v81 = 1636
    elseif p25.collector == "Grind" then
        v80 = 1560
        v81 = 1556
    elseif p25.collector == "Offboard" then
        v80 = 1544
        v81 = 1540
    else
        v80 = 1552
        v81 = 1548
    end

    local v82, v83

    if v77 then
        v82 = CollectorTuning.scalar(collector, v80)
        v83 = CollectorTuning.scalar(collector, v81)
    else
        v82 = 1
        v83 = 1
    end

    local v84 = rt.f_to_u32(CollectorTuning.scalar(collector, 1532) * 60)
    local sequence_active = p25.sequence_active and (p25.collector ~= "Ground" or p25.line_hold_ticks < v84)
    local v85

    if not PointTimer.advance(p25.session.line, p26.dt, data.line_drain, v82, sequence_active) or p25.collector ~= "Ground" then
        v85 = 0
    else
        v85 = p25.line_hold_ticks + 1

        if v85 > 4294967295 then
            v85 = 4294967295
        end
    end

    p25.line_hold_ticks = v85
    PointTimer.advance(p25.session.combo.timer, p26.dt, data.combo_drain, v83, false)

    local v86 = p25.collector == "None" and p25.sequence_active

    if p25.sequence_active and (v86 or p25.idle_ticks >= 3 and p25.landing_countdown == 0) then
        if v86 then
            ScoreHolder.cancel_pending(holder)
        end

        p25.sequence_score = Session.publish_sequence(p25.session, ScoringData.session_rules(data), 1, v86, true)

        if not v86 and not p26.teleported and p26.category == FilteredCategory.Ground and p25.trick_seq > p25.settled_trick_seq and #p25.trick_name ~= 0 then
            local v87 = p25.landing_seq + 1

            if v87 > 4294967295 then
                v87 = 4294967295
            end

            p25.landing_seq = v87
            p25.landed_trick = p25.trick_name
            p25.landed_base = p25.display_base
            p25.landed_spin_degrees = p25.display_spin_degrees
            p25.landed_clean = p25.clean
            p25.landed_sketchy = p25.sketchy
        end

        p25.settled_trick_seq = p25.trick_seq
        p25.sequence_active = false
        p25.close_tricks = v86
    elseif p25.sequence_active then
        local snapshot = holder.snapshot
        local n1 = 0

        for i = 0, 3 do
            local v88 = p25.carriers[i + 1]

            if v88 ~= nil then
                if p25.collector ~= "Grind" and (p25.collector ~= "Ground" or not (i < 3)) then
                    n1 += v88.reward
                elseif v88.scorable.score_type == 9 then
                    n1 += rt.fmax(v88.reward, p25.metric_rewards[i + 1])
                else
                    n1 += p25.metric_rewards[i + 1]
                end
            end
        end

        local v89 = 0 + p25.air_metrics[1] + p25.air_metrics[2] + p25.air_metrics[4] + p25.air_metrics[5]

        p25.sequence_score = (snapshot.accumulated + snapshot.general_pending + snapshot.fingerflip_pending + n1 + v89) * p25.session.combo.multiplier
    end

    if p25.session.line.expired or p26.teleported or v86 then
        p25.sequence_score = 0
    end

    Session.settle_line(p25.session, p26.teleported or v86, v77)
    p25.previous = rt.copy(p26.position)
end

function t1.Runtime.mod_catalog(p27) -- line: 837
    local v90 = table.create(#p27.data.definitions)

    for _, v91 in p27.data.definitions do
        table.insert(v90, {
            id = v91.metadata.id,
            identifier = v91.identifier,
            label = v91.label,
            points = v91.points,
            type = v91.trick_type,
            class = v91.metadata.class,
            score_type = v91.metadata.score_type,
            variant = v91.variant
        })
    end

    return v90
end

return t1
