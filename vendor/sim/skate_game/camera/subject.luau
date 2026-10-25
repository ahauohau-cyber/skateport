-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/camera")
local Anchors, Compass, CompassPoseInputs, ReferencePointInputs = v1.Anchors, v1.Compass, v1.CompassPoseInputs, v1.ReferencePointInputs
local ShotManager, SubjectPosePublisher = v1.ShotManager, v1.SubjectPosePublisher
local PERF = import("skate_core/camera/tracker").PERF
local t1 = {
    CameraSubjectSnapshot = {},
    SubjectPublisher = {}
}

function t1.SubjectPublisher.new() -- line: 42
    -- upvalues: Anchors (copy), Compass (copy), SubjectPosePublisher (copy)
    return {
        last_tick = nil,
        pose = SubjectPosePublisher.new(),
        anchors = Anchors.new(),
        compass = Compass.new()
    }
end

function t1.SubjectPublisher.publish(p1, p2, p3, p4) -- line: 60
    -- upvalues: rt (copy), Anchors (copy), Compass (copy), CompassPoseInputs (copy), ReferencePointInputs (copy), ShotManager (copy), SubjectPosePublisher (copy), t1 (copy), PERF (copy)
    if PERF.reference then
        return t1.SubjectPublisher.publish_reference(p1, p2, p3, p4)
    end

    local last_tick = p1.last_tick

    if last_tick ~= nil and p2.tick <= last_tick then
        error(string.format("Camera subject publication is not monotonic: previous=%s, current=%s", tostring(last_tick), (tostring(p2.tick))), 0)
    end

    p1.last_tick = p2.tick

    local v3 = SubjectPosePublisher.publish(p1.pose, p2.pose)

    p2.subject.rig.transform = rt.copy(v3.transform)
    p2.subject.rig.skeleton_root = rt.copy(p2.pose.skeleton_root)
    p2.anchors.damped_center_of_mass = rt.copy(v3.damped_center_of_mass)
    Anchors.update(p1.anchors, p2.anchors)
    p2.subject.anchors = rt.copy(p1.anchors.entries)
    p2.reference_points.damped_centre_of_mass = rt.copy(v3.damped_center_of_mass)
    p2.reference_points.tracked_anchor = rt.copy(p3.rig.anchor.position)
    p2.reference_points.incline_normal = rt.copy(p3.state.incline_normal)
    p2.subject.rig.reference_positions = ReferencePointInputs.positions(p2.reference_points)

    local v4 = if #ShotManager.current(p3.shots).name == 0 then 5 else ShotManager.current(p3.shots).shot.compass_north
    local v5 = CompassPoseInputs.bind(p2.compass, p2.subject, p3.frame.position, v4)

    p2.subject.compass = Compass.update(p1.compass, p2.subject.reset == 0 and 0.01666666753590107 or 0, v5, p4)

    return p2.subject
end

function t1.SubjectPublisher.publish_reference(p5, p6, p7, p8) -- line: 102
    -- upvalues: rt (copy), Anchors (copy), Compass (copy), CompassPoseInputs (copy), ReferencePointInputs (copy), ShotManager (copy), SubjectPosePublisher (copy)
    local last_tick = p5.last_tick

    if last_tick ~= nil and p6.tick <= last_tick then
        error(string.format("Camera subject publication is not monotonic: previous=%s, current=%s", tostring(last_tick), (tostring(p6.tick))), 0)
    end

    p5.last_tick = p6.tick

    local v7 = SubjectPosePublisher.publish(p5.pose, rt.copy(p6.pose))

    p6.subject.rig.transform = rt.copy(v7.transform)
    p6.subject.rig.skeleton_root = rt.copy(p6.pose.skeleton_root)
    p6.anchors.damped_center_of_mass = rt.copy(v7.damped_center_of_mass)
    Anchors.update(p5.anchors, rt.copy(p6.anchors))
    p6.subject.anchors = rt.copy(p5.anchors.entries)
    p6.reference_points.damped_centre_of_mass = rt.copy(v7.damped_center_of_mass)
    p6.reference_points.tracked_anchor = rt.copy(p7.rig.anchor.position)
    p6.reference_points.incline_normal = rt.copy(p7.state.incline_normal)
    p6.subject.rig.reference_positions = ReferencePointInputs.positions(rt.copy(p6.reference_points))

    local v8 = if #ShotManager.current(p7.shots).name == 0 then 5 else ShotManager.current(p7.shots).shot.compass_north
    local v9 = CompassPoseInputs.bind(rt.copy(p6.compass), p6.subject, rt.copy(p7.frame.position), v8)

    p6.subject.compass = Compass.update(p5.compass, p6.subject.reset == 0 and 0.01666666753590107 or 0, v9, p8)

    return p6.subject
end

local function zero4() -- line: 164
    return { 0, 0, 0, 0 }
end

local function zero_matrix() -- line: 167
    return {
        { 0, 0, 0, 0 },
        { 0, 0, 0, 0 },
        { 0, 0, 0, 0 },
        { 0, 0, 0, 0 }
    }
end

local t2 = {
    anchors = false,
    board_offset_direction = false,
    ground_normal = false,
    launch_position = false,
    launch_normal = false,
    landing_position = false,
    landing_normal = false,
    apex_position = false,
    direction_424 = false,
    look = false,
    steering = false,
    trajectory_time = 0,
    trajectory_duration = 0,
    apex_time = 0,
    value_512 = 0,
    value_516 = 0,
    reset = 0,
    flag_556 = 0,
    stance_560 = 0,
    stance_592 = 0,
    flag_652 = 0,
    shake_variant = 0,
    special_effect = 0,
    flag_684 = 0,
    rig = {
        skeleton_root = false,
        hips_position = false,
        last_valid_ground_up = false,
        context = 0,
        pumping_acceleration = 0,
        state_height_32 = 0,
        in_ground_physics = 0,
        grinding = 0,
        trajectory_valid = 0,
        wiping_out = 0,
        physically_pushing = 0,
        at_pushable_speed = 0,
        off_board = 0,
        air_flag_452 = 0,
        state_flag_81 = 0,
        broken_bone_slowmo = 0,
        subject_flag_328 = 0,
        transform = {
            { 0, 0, 0, 0 },
            { 0, 0, 0, 0 },
            { 0, 0, 0, 0 },
            { 0, 0, 0, 0 }
        },
        reference_positions = {
            { 0, 0, 0, 0 },
            { 0, 0, 0, 0 },
            { 0, 0, 0, 0 },
            { 0, 0, 0, 0 },
            { 0, 0, 0, 0 },
            { 0, 0, 0, 0 },
            { 0, 0, 0, 0 },
            { 0, 0, 0, 0 },
            { 0, 0, 0, 0 },
            { 0, 0, 0, 0 }
        }
    },
    compass = table.create(9, 0)
}
local v10 = CompassPoseInputs.bind_record()

function t1.SubjectPublisher.publish_into(p9, p10, p11, p12) -- line: 222
    -- upvalues: Anchors (copy), Compass (copy), CompassPoseInputs (copy), ReferencePointInputs (copy), ShotManager (copy), SubjectPosePublisher (copy), t2 (copy), v10 (copy)
    local last_tick = p9.last_tick

    if last_tick ~= nil and p10.tick <= last_tick then
        error(string.format("Camera subject publication is not monotonic: previous=%s, current=%s", tostring(last_tick), (tostring(p10.tick))), 0)
    end

    p9.last_tick = p10.tick

    local subject = p10.subject
    local rig = subject.rig
    local rig2 = t2.rig

    rig2.skeleton_root = p10.pose.skeleton_root
    rig2.hips_position = rig.hips_position
    rig2.last_valid_ground_up = rig.last_valid_ground_up
    rig2.context = rig.context
    rig2.pumping_acceleration = rig.pumping_acceleration
    rig2.state_height_32 = rig.state_height_32
    rig2.in_ground_physics = rig.in_ground_physics
    rig2.grinding = rig.grinding
    rig2.trajectory_valid = rig.trajectory_valid
    rig2.wiping_out = rig.wiping_out
    rig2.physically_pushing = rig.physically_pushing
    rig2.at_pushable_speed = rig.at_pushable_speed
    rig2.off_board = rig.off_board
    rig2.air_flag_452 = rig.air_flag_452
    rig2.state_flag_81 = rig.state_flag_81
    rig2.broken_bone_slowmo = rig.broken_bone_slowmo
    rig2.subject_flag_328 = rig.subject_flag_328
    t2.board_offset_direction = subject.board_offset_direction
    t2.ground_normal = subject.ground_normal
    t2.launch_position = subject.launch_position
    t2.launch_normal = subject.launch_normal
    t2.landing_position = subject.landing_position
    t2.landing_normal = subject.landing_normal
    t2.apex_position = subject.apex_position
    t2.direction_424 = subject.direction_424
    t2.look = subject.look
    t2.steering = subject.steering
    t2.trajectory_time = subject.trajectory_time
    t2.trajectory_duration = subject.trajectory_duration
    t2.apex_time = subject.apex_time
    t2.value_512 = subject.value_512
    t2.value_516 = subject.value_516
    t2.reset = subject.reset
    t2.flag_556 = subject.flag_556
    t2.stance_560 = subject.stance_560
    t2.stance_592 = subject.stance_592
    t2.flag_652 = subject.flag_652
    t2.shake_variant = subject.shake_variant
    t2.special_effect = subject.special_effect
    t2.flag_684 = subject.flag_684

    local v12, v13, v14, v15 = SubjectPosePublisher.publish_into(p9.pose, p10.pose, rig2.transform)
    local anchors = p9.anchors

    Anchors.update_damped(anchors, p10.anchors, v12, v13, v14, v15)
    t2.anchors = anchors.entries
    ReferencePointInputs.positions_into(rig2.reference_positions, p10.reference_points, v12, v13, v14, v15, p11.rig.anchor.position, p11.state.incline_normal)

    local v16 = ShotManager.current(p11.shots)
    local v17 = if #v16.name == 0 then 5 else v16.shot.compass_north
    local v18 = CompassPoseInputs.bind_into(v10, p10.compass, t2, p11.frame.position, v17)
    local compass = p9.compass

    Compass.update_headings(compass, t2.reset == 0 and 0.01666666753590107 or 0, v18, p12)

    local headings = compass.headings
    local compass2 = t2.compass

    compass2[1] = headings[1]
    compass2[2] = headings[2]
    compass2[3] = headings[3]
    compass2[4] = headings[4]
    compass2[5] = headings[5]
    compass2[6] = headings[6]
    compass2[7] = headings[7]
    compass2[8] = headings[8]
    compass2[9] = headings[9]

    return t2
end

return t1
