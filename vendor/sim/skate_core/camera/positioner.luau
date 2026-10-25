-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/camera/vector_tracker")
local v2 = import("skate_core/camera/tracker")
local v3 = import("skate_core/trigonometry")
local length, length3, refined_reciprocal = v1.length, v1.length3, v1.refined_reciprocal
local ScalarTracker, PERF = v2.ScalarTracker, v2.PERF
local t1 = {
    FatLine = {},
    FatLineResult = {},
    PositionerCollisionProvider = {},
    PositionerConfig = {},
    Positioner = {}
}

function t1.Positioner.update_reference(p1, p2, p3, p4, p5) -- line: 50
    -- upvalues: rt (copy), refined_reciprocal (copy), ScalarTracker (copy), t1 (copy)
    p1.config = rt.copy(p4)
    p1.offset = rt.copy(p4.offset)

    if p1.collision_clear_time < 5 then
        local v4 = p1.collision_clear_time * 0.20000000298023224

        p1.offset = {
            p1.offset[1] * v4,
            p1.offset[2] * v4,
            p1.offset[3] * v4,
            p1.offset[4] * v4
        }
    end

    if p4.bypass_distance_tracker == 0 then
        local v5 = if p1.distance_tracker.position < 1.0499999523162842 then 100 else p4.acceleration_clamp

        p1.tracker_parameters.acceleration_clamp_min = v5
        p1.tracker_parameters.acceleration_clamp_max = v5
        p1.tracker_parameters.speed_clamp = p4.speed_clamp
        p1.tracker_parameters.smoothing_min = p4.smoothing
        p1.tracker_parameters.smoothing_max = p4.smoothing
        ScalarTracker.update(p1.distance_tracker, p2, p4.distance, p1.tracker_parameters)
    else
        p1.distance_tracker.target = p4.distance
        p1.distance_tracker.position = p4.distance
    end

    p1.radius = 0.12999999523162842

    local v6 = rt.copy(p1.position)
    local v7 = t1.Positioner.resolve(p1, p3, p5)

    if p2 > 0 then
        local v8 = refined_reciprocal(p2)
        local t2 = {}

        t2[1] = v8 * (p1.position[1] - v6[1])
        t2[2] = v8 * (p1.position[2] - v6[2])
        t2[3] = v8 * (p1.position[3] - v6[3])
        t2[4] = v8 * (p1.position[4] - v6[4])
        p1.velocity = t2
    end

    if bit32.band(p1.flags, 192) == 0 then
        p1.collision_clear_time += p2
    else
        p1.collision_clear_time = 0
    end

    return v7
end

function t1.Positioner.resolve_reference(p6, p7, p8) -- line: 99
    -- upvalues: rt (copy), length (copy), t1 (copy)
    p6.available_distance = p6.config.distance
    p6.flags = bit32.bor(bit32.band(p6.flags, 193), 12)
    p6.heading = p6.config.heading
    p6.elevation = p6.config.elevation
    p6.distance = p6.distance_tracker.position
    p6.position = t1.Positioner.position_at(p6, p6.elevation, p6.heading, p6.distance)

    local v10 = t1.Positioner.resolve_collision(p6, p7, p8)

    if v10 == 1 or v10 == 2 then
        local t3 = {}

        t3[1] = p6.position[1] - p6.config.anchor[1]
        t3[2] = p6.position[2] - p6.config.anchor[2]
        t3[3] = p6.position[3] - p6.config.anchor[3]
        t3[4] = p6.position[4] - p6.config.anchor[4]

        local v11 = length(t3)

        p6.distance_tracker.target = v11
        p6.distance_tracker.position = v11
        p6.distance_tracker.velocity = 0
        p6.distance_tracker.acceleration = 0
        p6.distance = v11
    end

    if v10 == 3 then
        p6.position = rt.copy(p6.previous_valid_position)
        p6.flags = bit32.band(p6.flags, 247)
    else
        p6.previous_valid_position = rt.copy(p6.position)
        p6.flags = bit32.bor(bit32.band(p6.flags, 223), v10 == 2 and 32 or 0)
    end

    p6.flags = bit32.bor(bit32.band(p6.flags, 63), v10 == 0 and 0 or 128)

    return v10
end

function t1.Positioner.submit_collision_reference(p9, p10, p11) -- line: 131
    -- upvalues: rt (copy), t1 (copy)
    p9.reference_position = t1.Positioner.position_at(p9, p9.config.reference_elevation, p9.config.reference_heading, p9.config.distance)

    local t4 = {}

    for i = 0, 5 do
        t4[i + 1] = {
            start = rt.copy(p9.config.query_starts[rt.irem(i, 3) + 1]),
            ["end"] = if i < 3 then rt.copy(p9.position) else rt.copy(p9.reference_position),
            radius = p9.radius
        }
    end

    p11.submit(p11, t4, p10)
end

function t1.Positioner.resolve_collision_reference(p12, p13, p14) -- line: 150
    -- upvalues: length (copy), t1 (copy)
    t1.Positioner.submit_collision(p12, p13, p14)

    local v17 = p14.results(p14)
    local v18 = p12.config.collision_enabled == 0
    local v19

    if not v18 then
        p12.flags = bit32.bor(p12.flags, 2)
        p12.available_distance = 0

        for i = 3, 5 do
            local v20 = v17[i + 1]

            if v20.hit == 0 then
                p12.available_distance = p12.config.distance
                p12.flags = bit32.band(p12.flags, 253)
            else
                local v21 = t1.project_hit(p12.reference_position, p12.config.query_starts[1], v20)
                local t6 = {}

                t6[1] = v21[1] - p12.config.anchor[1]
                t6[2] = v21[2] - p12.config.anchor[2]
                t6[3] = v21[3] - p12.config.anchor[3]
                t6[4] = v21[4] - p12.config.anchor[4]

                local v22 = length(t6)

                if not (p12.available_distance - v22 >= 0) then
                    p12.available_distance = v22
                end
            end
        end

        v19 = v17[1].hit ~= 0 and v17[2].hit ~= 0 and v17[3].hit ~= 0
    end

    if v18 or not v19 then
        return 0
    end

    p12.position = t1.project_hit(p12.position, p12.config.query_starts[1], v17[1])

    local t7 = {}

    t7[1] = p12.position[1] - p12.config.query_starts[1][1]
    t7[2] = p12.position[2] - p12.config.query_starts[1][2]
    t7[3] = p12.position[3] - p12.config.query_starts[1][3]
    t7[4] = p12.position[4] - p12.config.query_starts[1][4]

    if length(t7) < p12.radius + p12.config.minimum_distance then
        return 2
    end

    return 1
end

function t1.Positioner.position_at(p15, p16, p17, p18) -- line: 197
    -- upvalues: t1 (copy)
    return t1.position_from_angles(p15.config.anchor, p15.offset, p16, p17, p18, p15.config.clamp_height, p15.radius + p15.config.floor_height)
end

function t1.project_hit_reference(p19, p20, p21) -- line: 210
    -- upvalues: rt (copy)
    local v23 = p21.position[1]
    local v24 = false

    if v23 == v23 then
        local v25 = p21.position[2]

        if v25 == v25 then
            local v26 = p21.position[3]

            v24 = v26 == v26
        end
    end

    local v27

    if not v24 or p21.hit == 0 then
        return rt.copy(p19)
    else
        v27 = if -p21.fraction >= 0 then 0 else p21.fraction
    end

    if not (1 - v27 >= 0) then
        v27 = 1
    end

    local t8 = {}

    t8[1] = (p19[1] - p20[1]) * v27 + p20[1]
    t8[2] = (p19[2] - p20[2]) * v27 + p20[2]
    t8[3] = (p19[3] - p20[3]) * v27 + p20[3]
    t8[4] = (p19[4] - p20[4]) * v27 + p20[4]

    return t8
end

function t1.position_from_angles_reference(p22, p23, p24, p25, p26, p27, p28) -- line: 238
    -- upvalues: v3 (copy)
    local v29, v30 = v3.sin_cos(-p24)
    local v31, v32 = v3.sin_cos(-p25)
    local t9 = {
        { 1, 0, 0, 1 },
        { 0, v30, v29, 0 },
        { 0, -v29, v30, 0 }
    }
    local t10 = {
        { v32, 0, -v31, v32 },
        { 0, 1, 0, 0 },
        { v31, 0, v32, v31 }
    }
    local t11 = {}

    for i = 0, 2 do
        local t12 = {}

        for j = 0, 3 do
            local v33 = t10[1][j + 1] * t9[i + 1][1]
            local v34 = t10[2][j + 1] * t9[i + 1][2] + v33

            t12[j + 1] = t10[3][j + 1] * t9[i + 1][3] + v34
        end

        t11[i + 1] = t12
    end

    local t13 = {}

    for i = 0, 3 do
        local v35 = t11[1][i + 1] * 0
        local v36 = t11[2][i + 1] * 0 + v35
        local v37 = t11[3][i + 1] * p26 + v36

        t13[i + 1] = v37 + p23[i + 1] + p22[i + 1]
    end

    if p27 ~= 0 and t13[2] < p28 then
        t13[2] = p28
    end

    return t13
end

local function position_lane(p29, p30, p31, p32, p33, p34, p35) -- line: 304
    local v38 = p31 * 0 + (p30 * 0 + p29 * 1)
    local v39 = p31 * p32 + (p30 * p33 + p29 * 0)

    return (p31 * p33 + (p30 * p34 + p29 * 0)) * p35 + (v39 * 0 + v38 * 0)
end

function t1.position_from_angles_lanes(p36, p37, p38, p39, p40, p41, p42, p43, p44, p45, p46, p47, p48) -- line: 312
    -- upvalues: v3 (copy)
    local v40, v41 = v3.sin_cos(-p44)
    local v42, v43 = v3.sin_cos(-p45)
    local v44 = -v40
    local v45 = v42 * 0 + (v43 * 1 + 0)
    local v46 = v42 * v40 + (v41 * 0 + v43 * 0)
    local v47 = (v42 * v41 + (v44 * 0 + v43 * 0)) * p46 + (v46 * 0 + v45 * 0) + p40 + p36
    local v48 = v40 * 0 + (v41 * 1 + 0)
    local v49 = (v41 * 0 + (v44 * 1 + 0)) * p46 + (v48 * 0 + 0) + p41 + p37
    local v50 = -v42
    local v51 = v43 * 0 + (v50 * 1 + 0)
    local v52 = v43 * v40 + (v41 * 0 + v50 * 0)
    local v53 = (v43 * v41 + (v44 * 0 + v50 * 0)) * p46 + (v52 * 0 + v51 * 0) + p42 + p38
    local v54 = v42 * 0 + (v43 * 1 + 0)
    local v55 = v42 * v40 + (v41 * 0 + v43 * 0)
    local v56 = (v42 * v41 + (v44 * 0 + v43 * 0)) * p46 + (v55 * 0 + v54 * 0) + p43 + p39

    if p47 ~= 0 and v49 < p48 then
        v49 = p48
    end

    return v47, v49, v53, v56
end

local position_from_angles_lanes = t1.position_from_angles_lanes

function t1.project_hit_lanes(p49, p50, p51, p52, p53, p54, p55, p56, p57) -- line: 343
    local position = p57.position
    local v57 = position[1]
    local v58 = position[2]
    local v59 = position[3]
    local v60

    if v57 ~= v57 or v58 ~= v58 or v59 ~= v59 or p57.hit == 0 then
        return p49, p50, p51, p52
    else
        v60 = if -p57.fraction >= 0 then 0 else p57.fraction
    end

    if not (1 - v60 >= 0) then
        v60 = 1
    end

    return (p49 - p53) * v60 + p53, (p50 - p54) * v60 + p54, (p51 - p55) * v60 + p55, (p52 - p56) * v60 + p56
end

local project_hit_lanes2 = t1.project_hit_lanes

function t1.project_hit(p58, p59, p60) -- line: 371
    -- upvalues: PERF (copy), t1 (copy), project_hit_lanes2 (copy)
    if PERF.reference then
        return t1.project_hit_reference(p58, p59, p60)
    end

    local v62, v63, v64, v65 = project_hit_lanes2(p58[1], p58[2], p58[3], p58[4], p59[1], p59[2], p59[3], p59[4], p60)

    return { v62, v63, v64, v65 }
end

function t1.position_from_angles(p61, p62, p63, p64, p65, p66, p67) -- line: 389
    -- upvalues: PERF (copy), t1 (copy), position_from_angles_lanes (copy)
    if PERF.reference then
        return t1.position_from_angles_reference(p61, p62, p63, p64, p65, p66, p67)
    end

    local v66, v67, v68, v69 = position_from_angles_lanes(p61[1], p61[2], p61[3], p61[4], p62[1], p62[2], p62[3], p62[4], p63, p64, p65, p66, p67)

    return { v66, v67, v68, v69 }
end

local function position_at_into(p68, p69, p70, p71, p72) -- line: 420
    -- upvalues: position_from_angles_lanes (copy)
    local config = p68.config
    local anchor = config.anchor
    local offset = p68.offset
    local v70, v71, v72, v73 = position_from_angles_lanes(anchor[1], anchor[2], anchor[3], anchor[4], offset[1], offset[2], offset[3], offset[4], p70, p71, p72, config.clamp_height, p68.radius + config.floor_height)

    p69[1] = v70
    p69[2] = v71
    p69[3] = v72
    p69[4] = v73
end

local function store_config(p73, p74) -- line: 442
    local anchor = p73.anchor
    local anchor2 = p74.anchor
    local v74 = anchor2[1]
    local v75 = anchor2[2]
    local v76 = anchor2[3]
    local v77 = anchor2[4]

    anchor[1] = v74
    anchor[2] = v75
    anchor[3] = v76
    anchor[4] = v77

    local offset = p73.offset
    local offset2 = p74.offset
    local v78 = offset2[1]
    local v79 = offset2[2]
    local v80 = offset2[3]
    local v81 = offset2[4]

    offset[1] = v78
    offset[2] = v79
    offset[3] = v80
    offset[4] = v81
    p73.reference_heading = p74.reference_heading
    p73.reference_elevation = p74.reference_elevation
    p73.heading = p74.heading
    p73.elevation = p74.elevation
    p73.distance = p74.distance
    p73.minimum_distance = p74.minimum_distance
    p73.collision_enabled = p74.collision_enabled
    p73.bypass_distance_tracker = p74.bypass_distance_tracker
    p73.clamp_height = p74.clamp_height
    p73.floor_height = p74.floor_height
    p73.speed_clamp = p74.speed_clamp
    p73.acceleration_clamp = p74.acceleration_clamp
    p73.smoothing = p74.smoothing

    local query_starts = p73.query_starts
    local query_starts2 = p74.query_starts

    for i = 1, 3 do
        local v82 = query_starts[i]
        local v83 = query_starts2[i]
        local v84 = v83[1]
        local v85 = v83[2]
        local v86 = v83[3]
        local v87 = v83[4]

        v82[1] = v84
        v82[2] = v85
        v82[3] = v86
        v82[4] = v87
    end
end

function t1.Positioner.update(p75, p76, p77, p78, p79) -- line: 469
    -- upvalues: refined_reciprocal (copy), ScalarTracker (copy), PERF (copy), t1 (copy), store_config (copy)
    if PERF.reference then
        return t1.Positioner.update_reference(p75, p76, p77, p78, p79)
    end

    local config = p75.config

    if p78 ~= config then
        store_config(config, p78)
    end

    local offset = config.offset
    local offset2 = p75.offset
    local v88 = offset[1]
    local v89 = offset[2]
    local v90 = offset[3]
    local v91 = offset[4]

    if p75.collision_clear_time < 5 then
        local v92 = p75.collision_clear_time * 0.20000000298023224

        v88 *= v92
        v89 *= v92
        v90 *= v92
        v91 *= v92
    end

    offset2[1] = v88
    offset2[2] = v89
    offset2[3] = v90
    offset2[4] = v91

    if config.bypass_distance_tracker == 0 then
        local v93 = if p75.distance_tracker.position < 1.0499999523162842 then 100 else config.acceleration_clamp
        local tracker_parameters = p75.tracker_parameters

        tracker_parameters.acceleration_clamp_min = v93
        tracker_parameters.acceleration_clamp_max = v93
        tracker_parameters.speed_clamp = config.speed_clamp
        tracker_parameters.smoothing_min = config.smoothing
        tracker_parameters.smoothing_max = config.smoothing
        ScalarTracker.update(p75.distance_tracker, p76, config.distance, tracker_parameters)
    else
        p75.distance_tracker.target = config.distance
        p75.distance_tracker.position = config.distance
    end

    p75.radius = 0.12999999523162842

    local position = p75.position
    local v94 = position[1]
    local v95 = position[2]
    local v96 = position[3]
    local v97 = position[4]
    local v98 = t1.Positioner.resolve(p75, p77, p79)

    if p76 > 0 then
        local v99 = refined_reciprocal(p76)
        local position = p75.position
        local v100 = v99 * (position[1] - v94)
        local v101 = v99 * (position[2] - v95)
        local v102 = v99 * (position[3] - v96)
        local v103 = v99 * (position[4] - v97)
        local velocity = p75.velocity

        velocity[1] = v100
        velocity[2] = v101
        velocity[3] = v102
        velocity[4] = v103
    end

    if bit32.band(p75.flags, 192) == 0 then
        p75.collision_clear_time += p76
    else
        p75.collision_clear_time = 0
    end

    return v98
end

function t1.Positioner.resolve(p80, p81, p82) -- line: 527
    -- upvalues: length3 (copy), PERF (copy), t1 (copy), position_from_angles_lanes (copy)
    if PERF.reference then
        return t1.Positioner.resolve_reference(p80, p81, p82)
    end

    local config = p80.config

    p80.available_distance = config.distance
    p80.flags = bit32.bor(bit32.band(p80.flags, 193), 12)
    p80.heading = config.heading
    p80.elevation = config.elevation
    p80.distance = p80.distance_tracker.position

    local position, elevation, heading, distance = p80.position, p80.elevation, p80.heading, p80.distance
    local config2 = p80.config
    local anchor = config2.anchor
    local offset = p80.offset
    local v105, v106, v107, v108 = position_from_angles_lanes(anchor[1], anchor[2], anchor[3], anchor[4], offset[1], offset[2], offset[3], offset[4], elevation, heading, distance, config2.clamp_height, p80.radius + config2.floor_height)

    position[1] = v105
    position[2] = v106
    position[3] = v107
    position[4] = v108

    local v109 = t1.Positioner.resolve_collision(p80, p81, p82)

    if v109 == 1 or v109 == 2 then
        local position = p80.position
        local anchor = config.anchor
        local v110 = length3(position[1] - anchor[1], position[2] - anchor[2], position[3] - anchor[3])
        local distance_tracker = p80.distance_tracker

        distance_tracker.target = v110
        distance_tracker.position = v110
        distance_tracker.velocity = 0
        distance_tracker.acceleration = 0
        p80.distance = v110
    end

    if v109 == 3 then
        local position, previous_valid_position = p80.position, p80.previous_valid_position
        local v111 = previous_valid_position[1]
        local v112 = previous_valid_position[2]
        local v113 = previous_valid_position[3]
        local v114 = previous_valid_position[4]

        position[1] = v111
        position[2] = v112
        position[3] = v113
        position[4] = v114
        p80.flags = bit32.band(p80.flags, 247)
    else
        local position, previous_valid_position = p80.position, p80.previous_valid_position
        local v115 = position[1]
        local v116 = position[2]
        local v117 = position[3]
        local v118 = position[4]

        previous_valid_position[1] = v115
        previous_valid_position[2] = v116
        previous_valid_position[3] = v117
        previous_valid_position[4] = v118
        p80.flags = bit32.bor(bit32.band(p80.flags, 223), v109 == 2 and 32 or 0)
    end

    p80.flags = bit32.bor(bit32.band(p80.flags, 63), v109 == 0 and 0 or 128)

    return v109
end

local v123 = table.create(6)

for i = 1, 6 do
    v123[i] = {
        start = false,
        ["end"] = false,
        radius = 0
    }
end

function t1.Positioner.submit_collision(p83, p84, p85) -- line: 573
    -- upvalues: rt (copy), PERF (copy), t1 (copy), position_from_angles_lanes (copy), v123 (copy)
    if PERF.reference then
        return t1.Positioner.submit_collision_reference(p83, p84, p85)
    end

    local config, reference_position = p83.config, p83.reference_position
    local reference_elevation, reference_heading, distance = config.reference_elevation, config.reference_heading, config.distance
    local config2 = p83.config
    local anchor = config2.anchor
    local offset = p83.offset
    local v124, v125, v126, v127 = position_from_angles_lanes(anchor[1], anchor[2], anchor[3], anchor[4], offset[1], offset[2], offset[3], offset[4], reference_elevation, reference_heading, distance, config2.clamp_height, p83.radius + config2.floor_height)

    reference_position[1] = v124
    reference_position[2] = v125
    reference_position[3] = v126
    reference_position[4] = v127

    local query_starts = config.query_starts

    if p85.borrows_lines == true then
        local position, reference_position, radius = p83.position, p83.reference_position, p83.radius

        for i = 0, 5 do
            local v128 = v123[i + 1]

            v128.start = query_starts[rt.irem(i, 3) + 1]

            if i < 3 then
                v128["end"] = position
            else
                v128["end"] = reference_position
            end

            v128.radius = radius
        end

        p85.submit(p85, v123, p84)
    else
        local t14 = {}

        for i = 0, 5 do
            t14[i + 1] = {
                start = rt.copy(query_starts[rt.irem(i, 3) + 1]),
                ["end"] = if i < 3 then rt.copy(p83.position) else rt.copy(p83.reference_position),
                radius = p83.radius
            }
        end

        p85.submit(p85, t14, p84)
    end
end

function t1.Positioner.resolve_collision(p86, p87, p88) -- line: 603
    -- upvalues: length3 (copy), PERF (copy), t1 (copy), project_hit_lanes2 (copy)
    if PERF.reference then
        return t1.Positioner.resolve_collision_reference(p86, p87, p88)
    end

    t1.Positioner.submit_collision(p86, p87, p88)

    local v130 = p88.results(p88)
    local config = p86.config
    local v131 = config.collision_enabled == 0
    local v132, v133, v134, v135, v136

    if not v131 then
        p86.flags = bit32.bor(p86.flags, 2)
        p86.available_distance = 0

        local v137 = config.query_starts[1]

        v132 = v137[1]
        v133 = v137[2]
        v134 = v137[3]
        v135 = v137[4]

        local anchor = config.anchor

        for i = 3, 5 do
            local v138 = v130[i + 1]

            if v138.hit == 0 then
                p86.available_distance = config.distance
                p86.flags = bit32.band(p86.flags, 253)
            else
                local reference_position = p86.reference_position
                local v139, v140, v141 = project_hit_lanes2(reference_position[1], reference_position[2], reference_position[3], reference_position[4], v132, v133, v134, v135, v138)
                local v142 = length3(v139 - anchor[1], v140 - anchor[2], v141 - anchor[3])

                if not (p86.available_distance - v142 >= 0) then
                    p86.available_distance = v142
                end
            end
        end

        v136 = v130[1].hit ~= 0 and v130[2].hit ~= 0 and v130[3].hit ~= 0
    end

    if v131 or not v136 then
        return 0
    end

    local position = p86.position
    local v143, v144, v145, v146 = project_hit_lanes2(position[1], position[2], position[3], position[4], v132, v133, v134, v135, v130[1])

    position[1] = v143
    position[2] = v144
    position[3] = v145
    position[4] = v146

    if length3(v143 - v132, v144 - v133, v145 - v134) < p86.radius + config.minimum_distance then
        return 2
    end

    return 1
end

return t1
