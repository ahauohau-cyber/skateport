-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)

local function rtl_is_finite(p1) -- line: 6
    if p1 ~= p1 or p1 == 1e999 then
        return false
    end

    return p1 ~= (-1e999)
end

local import = require(sim.import)
local v1 = import("skate_core/camera")
local Collections = import("skate_data/collections").Collections
local CameraCollision = import("skate_game/camera/collision").CameraCollision
local CameraGraph = import("skate_game/camera/graph").CameraGraph
local v2 = import("skate_game/camera/settings")
local v3 = import("skate_game/camera/shake_data")
local StockShots = import("skate_game/camera/shot_data").StockShots
local v4 = import("skate_game/camera/subject")
local v5 = import("skate_game/camera/trajectory")
local CameraMan, ManualCam, ShotManager = v1.CameraMan, v1.ManualCam, v1.ShotManager
local SubjectPublisher = v4.SubjectPublisher
local CameraTrajectory, TrajectoryResult = v5.CameraTrajectory, v5.TrajectoryResult
local PERF = import("skate_core/camera/tracker").PERF
local t1 = {}

t1.CameraRuntime = {}

local function path_join(p2, p3) -- line: 60
    if p2 == nil or tostring(p2) == "" then
        return p3
    end

    local v6 = tostring(p2)
    local v7 = string.sub(v6, -1)

    if v7 == "/" or v7 == "\\" then
        return v6 .. p3
    end

    return v6 .. "/" .. p3
end

local function debug_value(p4) -- line: 73
    -- upvalues: debug_value (copy)
    if type(p4) ~= "table" then
        return (tostring(p4))
    end

    local v8 = table.create(#p4)

    for v9, v10 in p4 do
        v8[v9] = debug_value(v10)
    end

    return "[" .. table.concat(v8, ", ") .. "]"
end

function t1.CameraRuntime.load(p5, p6) -- line: 92
    -- upvalues: rt (copy), import (copy), Collections (copy), CameraGraph (copy), v2 (copy), v3 (copy), StockShots (copy), CameraMan (copy), ManualCam (copy), SubjectPublisher (copy), TrajectoryResult (copy)
    local v11 = Collections.load(p5)
    local v12 = Collections.words(v11, "slowmotion_controller", "default", "timescale", 32)
    local v13 = rt.map(v12, rt.from_bits)
    local t2 = {
        timescale = {
            x = {
                v13[1],
                v13[2],
                v13[3],
                v13[4],
                v13[5],
                v13[6],
                v13[7],
                v13[8],
                v13[9],
                v13[10],
                v13[11],
                v13[12],
                v13[13],
                v13[14],
                v13[15],
                v13[16]
            },
            y = {
                v13[17],
                v13[18],
                v13[19],
                v13[20],
                v13[21],
                v13[22],
                v13[23],
                v13[24],
                v13[25],
                v13[26],
                v13[27],
                v13[28],
                v13[29],
                v13[30],
                v13[31],
                v13[32]
            }
        },
        fps_at_scale_one = Collections.float(v11, "slowmotion_controller", "default", "fps_at_scale_one")
    }
    local load = CameraGraph.load
    local v14

    if p5 == nil or tostring(p5) == "" then
        v14 = "private/stock/data/script/camera/Default_cameragraph.stategraph"
    else
        local v15 = tostring(p5)
        local v16 = string.sub(v15, -1)

        v14 = if v16 == "/" or v16 == "\\" then v15 .. "private/stock/data/script/camera/Default_cameragraph.stategraph" else v15 .. "/" .. "private/stock/data/script/camera/Default_cameragraph.stategraph"
    end

    local v17 = load(v14, t2)

    local function samples(p7) -- line: 142
        -- upvalues: p5 (copy), p6 (copy), import (copy), v3 (copy)
        local v18

        if p5 == nil or tostring(p5) == "" then
            v18 = "private/stock/data/camera"
        else
            local v19 = tostring(p5)
            local v20 = string.sub(v19, -1)

            v18 = if v20 == "/" or v20 == "\\" then v19 .. "private/stock/data/camera" else v19 .. "/" .. "private/stock/data/camera"
        end

        local v21

        if v18 == nil or tostring(v18) == "" then
            v21 = p7
        else
            local v22 = tostring(v18)
            local v23 = string.sub(v22, -1)

            v21 = if v23 == "/" or v23 == "\\" then v22 .. p7 else v22 .. "/" .. p7
        end

        local v24 = if p6 == nil then nil else p6[p7]

        if v24 == nil then
            v24 = import("skate_data/files").read("private/stock/data/camera/" .. p7)
        end

        if type(v24) ~= "string" then
            error(("%*: the camera shake text was not supplied (shake_files[\"%*\"])"):format(v21, p7), 0)
        end

        return v3.parse(v24)
    end

    local v25 = CameraMan.new()
    local v26 = SubjectPublisher.new()
    local v27 = StockShots.from_collections(v11)
    local v28 = v2.manager_settings(v11)
    local v29 = v2.compass_settings(v11)
    local v30 = samples("1.shk")
    local v31 = samples("2.shk")
    local t3 = {
        TrajectoryResult.new(),
        TrajectoryResult.new(),
        TrajectoryResult.new()
    }
    local v32 = ManualCam.default()
    local v33 = v2.manual_cam_settings(v11)

    return {
        frame = nil,
        latest_subject = nil,
        manager = v25,
        subject = v26,
        graph = v17,
        shots = v27,
        settings = v28,
        compass_settings = v29,
        shakes = { v30, v31 },
        trajectories = t3,
        simulation_rate_requests = {},
        manual_cam = v32,
        manual_cam_settings = v33
    }
end

function t1.CameraRuntime.set_aspect_ratio(p8, p9) -- line: 189
    if p9 == p9 and p9 ~= 1e999 and p9 ~= (-1e999) and p9 > 0 then
        p8.manager.state.aspect_ratio = p9
    end
end

function t1.CameraRuntime.selected_shot(p10) -- line: 195
    -- upvalues: ShotManager (copy)
    return ShotManager.current(p10.manager.shots).name
end

function t1.CameraRuntime.presentation_frame(p11) -- line: 201
    -- upvalues: ManualCam (copy)
    local frame = p11.frame

    if frame == nil then
        return nil
    end

    return ManualCam.get_matrix(p11.manual_cam, frame)
end

local function store_copy(p12, p13) -- line: 233
    -- upvalues: rt (copy), store_copy (copy)
    for v34 in p12 do
        if p13[v34] == nil then
            p12[v34] = nil
        end
    end

    for v35, v36 in p13 do
        if type(v36) == "table" then
            local v37 = p12[v35]

            if type(v37) == "table" then
                store_copy(v37, v36)
            else
                p12[v35] = rt.copy(v36)
            end
        else
            p12[v35] = v36
        end
    end
end

t1.store_copy = store_copy

local function advance_impl(p14, p15, p16, p17, p18, p19, p20, p21) -- line: 254
    -- upvalues: rt (copy), CameraCollision (copy), CameraGraph (copy), CameraMan (copy), SubjectPublisher (copy), CameraTrajectory (copy), debug_value (copy), store_copy (copy)
    local latest_subject = p14.latest_subject

    if latest_subject ~= nil and p16.tick <= latest_subject.tick then
        error(string.format("Camera received non-monotonic subject tick: previous=%s, current=%s", tostring(latest_subject.tick), (tostring(p16.tick))), 0)
    end

    if p21 or latest_subject == nil then
        p14.latest_subject = rt.copy(p16)
    else
        store_copy(latest_subject, p16)
    end

    local v39 = SubjectPublisher.publish(p14.subject, if p21 then rt.copy(p16) else p16, p14.manager, p14.compass_settings)

    CameraMan.prepare(p14.manager, v39, p14.settings)

    for _, v40 in (CameraGraph.update(p14.graph, p15, p14.manager, v39, p16.graph, p19, p14.shots)) do
        table.insert(p14.simulation_rate_requests, v40)
    end

    local v41 = table.create(3)

    for i = 1, 3 do
        local t4 = {
            world = p17,
            gravity = rt.copy(p18),
            result = p14.trajectories[i]
        }

        v41[i] = {
            submit = function(_, p23, p24, p25) -- submit | line: 289
                -- upvalues: t4 (copy), CameraTrajectory (copy)
                CameraTrajectory.submit(t4, p23, p24, p25)
            end,
            is_ready = function(_) -- is_ready | line: 292
                -- upvalues: t4 (copy), CameraTrajectory (copy)
                return CameraTrajectory.is_ready(t4)
            end,
            collision_time = function(_) -- collision_time | line: 295
                -- upvalues: t4 (copy), CameraTrajectory (copy)
                return CameraTrajectory.collision_time(t4)
            end
        }
    end

    local v42 = CameraCollision.new(p17)
    local t6 = {
        query = function(_, p29, p30) -- query | line: 303
            -- upvalues: v42 (copy), CameraCollision (copy)
            return CameraCollision.query(v42, p29, p30)
        end,
        submit = function(_, p32, p33) -- submit | line: 306
            -- upvalues: v42 (copy), CameraCollision (copy)
            CameraCollision.submit(v42, p32, p33)
        end,
        results = function(_) -- results | line: 309
            -- upvalues: v42 (copy), CameraCollision (copy)
            return CameraCollision.results(v42)
        end
    }
    local v43 = CameraMan.update(p14.manager, p15, v39, p14.settings, {
        p14.shakes[1],
        p14.shakes[2]
    }, v41, p20, t6)

    if v42.error ~= nil then
        error(v42.error, 0)
    end

    for _, v44 in p14.trajectories do
        if v44.error ~= nil then
            error(v44.error, 0)
        end
    end

    local v45 = true

    for _, v46 in v43.position do
        if v46 ~= v46 or v46 == 1e999 or v46 == (-1e999) then
            v45 = false
        end
    end

    for _, v47 in v43.basis.columns do
        for _, v49 in v47 do
            if v49 ~= v49 or v49 == 1e999 or v49 == (-1e999) then
                v45 = false
            end
        end
    end

    local field_of_view_degrees = v43.field_of_view_degrees

    if field_of_view_degrees ~= field_of_view_degrees or field_of_view_degrees == 1e999 or field_of_view_degrees == (-1e999) or not v45 then
        error(string.format("Normal gameplay camera produced a non-finite frame: frame=%s; lens_length=%s; aspect_ratio=%s; subject_transform=%s; skeleton_root=%s; ground_normal=%s; launch_position=%s; landing_position=%s", string.format("CameraFrame { basis: %s, position: %s, field_of_view_degrees: %s }", debug_value(v43.basis.columns), debug_value(v43.position), (tostring(v43.field_of_view_degrees))), tostring(p14.manager.shots.interpolated.lens_length), tostring(p14.manager.state.aspect_ratio), debug_value(v39.rig.transform), debug_value(v39.rig.skeleton_root), debug_value(v39.ground_normal), debug_value(v39.launch_position), (debug_value(v39.landing_position))), 0)
    end

    p14.frame = rt.copy(v43)

    return v43
end

function t1.CameraRuntime.advance(p35, p36, p37, p38, p39, p40, p41) -- line: 373
    -- upvalues: t1 (copy), PERF (copy), advance_impl (copy)
    if PERF.reference then
        return t1.CameraRuntime.advance_reference(p35, p36, p37, p38, p39, p40, p41)
    end

    return (advance_impl(p35, p36, p37, p38, p39, p40, p41, false))
end

function t1.CameraRuntime.advance_reference(p42, p43, p44, p45, p46, p47, p48) -- line: 380
    -- upvalues: advance_impl (copy)
    return (advance_impl(p42, p43, p44, p45, p46, p47, p48, true))
end

local v54 = CameraCollision.new(nil)
local v55 = true
local v57 = table.freeze({
    borrows_lines = true,
    query = function(_, p50, p51) -- query | line: 417
        -- upvalues: CameraCollision (copy), v54 (copy)
        return CameraCollision.query(v54, p50, p51)
    end,
    query_into = function(_, p53, p54, p55) -- query_into | line: 420
        -- upvalues: CameraCollision (copy), v54 (copy)
        return CameraCollision.query_into(v54, p53, p54, p55)
    end,
    submit = function(_, p57, p58) -- submit | line: 423
        -- upvalues: CameraCollision (copy), v54 (copy), v55 (ref)
        v55 = false
        CameraCollision.submit(v54, p57, p58)
    end,
    results = function(_) -- results | line: 427
        -- upvalues: v54 (copy), v55 (ref)
        local results = v54.results

        if v55 then
            for i = 1, 6 do
                local v56 = results[i]
                local position, normal = v56.position, v56.normal

                position[1] = 0
                position[2] = 0
                position[3] = 0
                position[4] = 0
                normal[1] = 0
                normal[2] = 0
                normal[3] = 0
                normal[4] = 0
                v56.fraction = 0
                v56.hit = 0
                v56.surface = 0
            end

            v55 = false
        end

        return results
    end
})
local v58 = table.create(3)
local v59 = table.create(3)

for i = 1, 3 do
    local t8 = {
        world = nil,
        gravity = nil,
        result = nil
    }

    v58[i] = t8
    v59[i] = table.freeze({
        borrows_path = true,
        submit = function(_, p61, p62, p63) -- submit | line: 452
            -- upvalues: CameraTrajectory (copy), t8 (copy)
            CameraTrajectory.submit(t8, p61, p62, p63)
        end,
        is_ready = function(_) -- is_ready | line: 455
            -- upvalues: CameraTrajectory (copy), t8 (copy)
            return CameraTrajectory.is_ready(t8)
        end,
        collision_time = function(_) -- collision_time | line: 458
            -- upvalues: CameraTrajectory (copy), t8 (copy)
            return CameraTrajectory.collision_time(t8)
        end
    })
end

local function unbind() -- line: 464
    -- upvalues: v54 (copy), v58 (copy)
    v54.world = nil

    local v60 = v58[1]

    v60.world = nil
    v60.gravity = nil
    v60.result = nil

    local v61 = v58[2]

    v61.world = nil
    v61.gravity = nil
    v61.result = nil

    local v62 = v58[3]

    v62.world = nil
    v62.gravity = nil
    v62.result = nil
end

local is_finite = rt.is_finite

local function finite4(p66) -- line: 473
    -- upvalues: is_finite (copy)
    return is_finite(p66[1]) and is_finite(p66[2]) and is_finite(p66[3]) and is_finite(p66[4])
end

local function finite_columns(p67) -- line: 476
    -- upvalues: is_finite (copy)
    for _, v63 in p67 do
        for _, v64 in v63 do
            if not is_finite(v64) then
                return false
            end
        end
    end

    return true
end

local function store_basis(p68, p69) -- line: 487
    local columns = p68.columns
    local columns2 = p69.columns
    local v65 = columns[1]
    local v66 = columns2[1]
    local v67 = v66[1]
    local v68 = v66[2]
    local v69 = v66[3]

    v65[1] = v67
    v65[2] = v68
    v65[3] = v69

    local v70 = columns[2]
    local v71 = columns2[2]
    local v72 = v71[1]
    local v73 = v71[2]
    local v74 = v71[3]

    v70[1] = v72
    v70[2] = v73
    v70[3] = v74

    local v75 = columns[3]
    local v76 = columns2[3]
    local v77 = v76[1]
    local v78 = v76[2]
    local v79 = v76[3]

    v75[1] = v77
    v75[2] = v78
    v75[3] = v79
end

local function store4(p70, p71) -- line: 494
    local v80 = p71[1]
    local v81 = p71[2]
    local v82 = p71[3]
    local v83 = p71[4]

    p70[1] = v80
    p70[2] = v81
    p70[3] = v82
    p70[4] = v83
end

function t1.CameraRuntime.advance_in_place(p72, p73, p74, p75, p76, p77, p78) -- line: 498
    -- upvalues: rt (copy), CameraGraph (copy), CameraMan (copy), SubjectPublisher (copy), debug_value (copy), v54 (copy), v55 (ref), v57 (copy), v58 (copy), v59 (copy), is_finite (copy), finite_columns (copy), store_basis (copy)
    local latest_subject = p72.latest_subject

    if p74 ~= latest_subject then
        if latest_subject ~= nil and p74.tick <= latest_subject.tick then
            error(string.format("Camera received non-monotonic subject tick: previous=%s, current=%s", tostring(latest_subject.tick), (tostring(p74.tick))), 0)
        end

        p72.latest_subject = p74
    end

    local manager = p72.manager
    local v85 = SubjectPublisher.publish_into(p72.subject, p74, manager, p72.compass_settings)

    CameraMan.prepare(manager, v85, p72.settings)

    local v86 = CameraGraph.update_transient(p72.graph, p73, manager, v85, p74.graph, p77, p72.shots)

    if #v86 > 0 then
        local simulation_rate_requests = p72.simulation_rate_requests

        for _, v87 in v86 do
            table.insert(simulation_rate_requests, v87)
        end
    end

    local trajectories = p72.trajectories
    local v88 = v58[1]
    local v89 = trajectories[1]

    v88.world = p75
    v88.gravity = p76
    v88.result = v89

    local v90 = v58[2]
    local v91 = trajectories[2]

    v90.world = p75
    v90.gravity = p76
    v90.result = v91

    local v92 = v58[3]
    local v93 = trajectories[3]

    v92.world = p75
    v92.gravity = p76
    v92.result = v93
    v54.world = p75
    v54.error = nil
    v55 = true
    CameraMan.update_in_place(manager, p73, v85, p72.settings, p72.shakes, v59, p78, v57)

    local _error = v54.error

    v54.error = nil
    v54.world = nil

    local v94 = v58[1]

    v94.world = nil
    v94.gravity = nil
    v94.result = nil

    local v95 = v58[2]

    v95.world = nil
    v95.gravity = nil
    v95.result = nil

    local v96 = v58[3]

    v96.world = nil
    v96.gravity = nil
    v96.result = nil

    if _error ~= nil then
        error(_error, 0)
    end

    for _, v97 in trajectories do
        if v97.error ~= nil then
            error(v97.error, 0)
        end
    end

    local frame = manager.frame
    local position = frame.position

    if not (is_finite(position[1]) and is_finite(position[2]) and is_finite(position[3]) and is_finite(position[4]) and finite_columns(frame.basis.columns) and is_finite(frame.field_of_view_degrees)) then
        error(string.format("Normal gameplay camera produced a non-finite frame: frame=%s; lens_length=%s; aspect_ratio=%s; subject_transform=%s; skeleton_root=%s; ground_normal=%s; launch_position=%s; landing_position=%s", string.format("CameraFrame { basis: %s, position: %s, field_of_view_degrees: %s }", debug_value(frame.basis.columns), debug_value(frame.position), (tostring(frame.field_of_view_degrees))), tostring(manager.shots.interpolated.lens_length), tostring(manager.state.aspect_ratio), debug_value(v85.rig.transform), debug_value(v85.rig.skeleton_root), debug_value(v85.ground_normal), debug_value(v85.launch_position), (debug_value(v85.landing_position))), 0)
    end

    local frame2 = p72.frame

    if frame2 ~= nil then
        store_basis(frame2.basis, frame.basis)

        local position = frame2.position
        local position2 = frame.position
        local v102 = position2[1]
        local v103 = position2[2]
        local v104 = position2[3]
        local v105 = position2[4]

        position[1] = v102
        position[2] = v103
        position[3] = v104
        position[4] = v105
        store_basis(frame2.previous_basis, frame.previous_basis)

        local previous_position = frame2.previous_position
        local previous_position2 = frame.previous_position
        local v106 = previous_position2[1]
        local v107 = previous_position2[2]
        local v108 = previous_position2[3]
        local v109 = previous_position2[4]

        previous_position[1] = v106
        previous_position[2] = v107
        previous_position[3] = v108
        previous_position[4] = v109

        local linear_velocity = frame2.linear_velocity
        local linear_velocity2 = frame.linear_velocity
        local v110 = linear_velocity2[1]
        local v111 = linear_velocity2[2]
        local v112 = linear_velocity2[3]
        local v113 = linear_velocity2[4]

        linear_velocity[1] = v110
        linear_velocity[2] = v111
        linear_velocity[3] = v112
        linear_velocity[4] = v113

        local angular_velocity = frame2.angular_velocity
        local angular_velocity2 = frame.angular_velocity
        local v114 = angular_velocity2[1]
        local v115 = angular_velocity2[2]
        local v116 = angular_velocity2[3]
        local v117 = angular_velocity2[4]

        angular_velocity[1] = v114
        angular_velocity[2] = v115
        angular_velocity[3] = v116
        angular_velocity[4] = v117

        local shake_translation = frame2.shake_translation
        local shake_translation2 = frame.shake_translation
        local v118 = shake_translation2[1]
        local v119 = shake_translation2[2]
        local v120 = shake_translation2[3]
        local v121 = shake_translation2[4]

        shake_translation[1] = v118
        shake_translation[2] = v119
        shake_translation[3] = v120
        shake_translation[4] = v121
        frame2.discontinuity = frame.discontinuity
        frame2.field_of_view_degrees = frame.field_of_view_degrees
        frame2.opacity = frame.opacity
        frame2.blur = frame.blur
    else
        p72.frame = rt.copy(frame)
    end
end

return t1
