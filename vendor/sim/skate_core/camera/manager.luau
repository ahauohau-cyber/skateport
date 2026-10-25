-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/camera/manager_state")
local v2 = import("skate_core/camera/manager_subject")
local v3 = import("skate_core/camera/manager_blends")
local v4 = import("skate_core/camera/manager_frame")
local v5 = import("skate_core/camera/rig")
local v6 = import("skate_core/camera/shot_manager")
local v7 = import("skate_core/camera/rig_orientation")
local v8 = import("skate_core/camera/frame_composer")
local v9 = import("skate_core/camera/drop_predictor")
local v10 = import("skate_core/camera/look_input")
local v11 = import("skate_core/camera/shake")
local v12 = import("skate_core/camera/subject")
local v13 = import("skate_core/camera/manager_output")
local ManagerState = v1.ManagerState
local ManagerSubject = v2.ManagerSubject
local BlendEnvironment = v3.BlendEnvironment
local CameraFrame = v4.CameraFrame
local Rig = v5.Rig
local ShotManager = v6.ShotManager
local RigOrientation = v7.RigOrientation
local FrameComposer = v8.FrameComposer
local DropPredictor = v9.DropPredictor
local LookInput = v10.LookInput
local ShakeEffect = v11.ShakeEffect
local Subject = v12.Subject
local PERF = import("skate_core/camera/tracker").PERF
local t1 = {}

local function as_shot_environment(p1) -- line: 44
    -- upvalues: BlendEnvironment (copy)
    return {
        heading_mirror = function(_) -- heading_mirror | line: 46
            -- upvalues: p1 (copy), BlendEnvironment (copy)
            return BlendEnvironment.heading_mirror(p1)
        end,
        compass_north = function(_, p4) -- compass_north | line: 49
            -- upvalues: p1 (copy), BlendEnvironment (copy)
            return BlendEnvironment.compass_north(p1, p4)
        end,
        special_camera_flag = function(_) -- special_camera_flag | line: 52
            -- upvalues: p1 (copy), BlendEnvironment (copy)
            return BlendEnvironment.special_camera_flag(p1)
        end,
        raw_blend_value = function(_, p7, p8, p9) -- raw_blend_value | line: 55
            -- upvalues: p1 (copy), BlendEnvironment (copy)
            return BlendEnvironment.raw_blend_value(p1, p7, p8, p9)
        end
    }
end

local function as_rig_subject(p10) -- line: 63
    -- upvalues: Subject (copy)
    return {
        flag_568 = function(_) -- flag_568 | line: 66
            -- upvalues: p10 (copy), Subject (copy)
            return Subject.flag_568(p10)
        end,
        flag_596 = function(_) -- flag_596 | line: 69
            -- upvalues: p10 (copy), Subject (copy)
            return Subject.flag_596(p10)
        end,
        flag_680 = function(_) -- flag_680 | line: 72
            -- upvalues: p10 (copy), Subject (copy)
            return Subject.flag_680(p10)
        end,
        flag_540 = function(_) -- flag_540 | line: 75
            -- upvalues: p10 (copy), Subject (copy)
            return Subject.flag_540(p10)
        end,
        transform_376 = function(_) -- transform_376 | line: 79
            -- upvalues: p10 (copy), Subject (copy)
            return Subject.transform_376(p10)
        end,
        vector_452 = function(_) -- vector_452 | line: 82
            -- upvalues: p10 (copy), Subject (copy)
            return Subject.vector_452(p10)
        end,
        vector_444 = function(_) -- vector_444 | line: 85
            -- upvalues: p10 (copy), Subject (copy)
            return Subject.vector_444(p10)
        end,
        context_532 = function(_) -- context_532 | line: 88
            -- upvalues: p10 (copy), Subject (copy)
            return Subject.context_532(p10)
        end,
        flag_608 = function(_) -- flag_608 | line: 91
            -- upvalues: p10 (copy), Subject (copy)
            return Subject.flag_608(p10)
        end,
        flag_548 = function(_) -- flag_548 | line: 94
            -- upvalues: p10 (copy), Subject (copy)
            return Subject.flag_548(p10)
        end,
        flag_584 = function(_) -- flag_584 | line: 98
            -- upvalues: p10 (copy), Subject (copy)
            return Subject.flag_584(p10)
        end,
        flag_588 = function(_) -- flag_588 | line: 101
            -- upvalues: p10 (copy), Subject (copy)
            return Subject.flag_588(p10)
        end,
        value_476 = function(_) -- value_476 | line: 104
            -- upvalues: p10 (copy), Subject (copy)
            return Subject.value_476(p10)
        end,
        flag_656 = function(_) -- flag_656 | line: 108
            -- upvalues: p10 (copy), Subject (copy)
            return Subject.flag_656(p10)
        end,
        flag_668 = function(_) -- flag_668 | line: 112
            -- upvalues: p10 (copy), Subject (copy)
            return Subject.flag_668(p10)
        end,
        flag_660 = function(_) -- flag_660 | line: 115
            -- upvalues: p10 (copy), Subject (copy)
            return Subject.flag_660(p10)
        end,
        value_524 = function(_) -- value_524 | line: 118
            -- upvalues: p10 (copy), Subject (copy)
            return Subject.value_524(p10)
        end,
        transform_384 = function(_) -- transform_384 | line: 121
            -- upvalues: p10 (copy), Subject (copy)
            return Subject.transform_384(p10)
        end,
        position_360 = function(_, p30) -- position_360 | line: 124
            -- upvalues: p10 (copy), Subject (copy)
            return Subject.position_360(p10, p30)
        end
    }
end

t1.ManagerSettings = {}
t1.CameraMan = {}

function t1.CameraMan.new() -- line: 146
    -- upvalues: ManagerState (copy), CameraFrame (copy), Rig (copy), ShotManager (copy), RigOrientation (copy), FrameComposer (copy), DropPredictor (copy), LookInput (copy), ShakeEffect (copy)
    return {
        heading_multiplier = 1,
        state = ManagerState.new(),
        rig = Rig.new(1),
        shots = ShotManager.new(),
        orientation = RigOrientation.new(),
        composer = FrameComposer.new(),
        drop = DropPredictor.new(),
        look = LookInput.new(),
        shake = {
            ShakeEffect.new(),
            ShakeEffect.new()
        },
        frame = CameraFrame.new(),
        subject_forward = { 0, 0, 1, 0 }
    }
end

function t1.CameraMan.prepare(p31, p32, p33) -- line: 165
    -- upvalues: ManagerState (copy), ShakeEffect (copy)
    ManagerState.update_timing(p31.state, p32, p33.steering_threshold)

    local v14 = ManagerState.update_air(p31.state, p32, p31.rig)

    if v14 ~= nil then
        local v15 = v14[1]
        local v16 = v14[2]

        ShakeEffect.landing_impulse(p31.shake[1], v15, v16, p33.shake)
    end

    ManagerState.update_incline(p31.state, p32)
end

function t1.CameraMan.set_shot(p34, p35, p36, p37, p38) -- line: 177
    -- upvalues: rt (copy), ShotManager (copy), as_shot_environment (copy)
    local t4 = {
        state = p34.state,
        subject = p37,
        rig = p34.rig,
        rig_forward = rt.copy(p34.subject_forward),
        angular_velocity = { 0, 0, 0, 0 },
        heading_multiplier = p34.heading_multiplier,
        previous_distance = p34.shots.previous.distance
    }

    return ShotManager.set_shot(p34.shots, p35, p36, p38, as_shot_environment(t4), {
        anchor = rt.copy(p34.rig.fields.anchor),
        camera_position = rt.copy(p34.rig.positioner.position),
        clamp_height = p34.rig.positioner.config.clamp_height,
        floor_height = p34.rig.positioner.config.floor_height
    })
end

function t1.CameraMan.update_reference(p39, p40, p41, p42, p43, p44, p45, p46) -- line: 199
    -- upvalues: rt (copy), v4 (copy), ManagerState (copy), ManagerSubject (copy), Rig (copy), ShotManager (copy), RigOrientation (copy), FrameComposer (copy), DropPredictor (copy), LookInput (copy), ShakeEffect (copy), t1 (copy), as_shot_environment (copy), as_rig_subject (copy)
    if ShotManager.current(p39.shots).name == "" then
        error("The stock camera graph has not selected a shot", 0)
    end

    p39.state.frames = rt.wrapping_add_u32(p39.state.frames, 1)

    if p39.state.frames > 30 then
        p39.state.flags = bit32.bor(p39.state.flags, 1)
    end

    ManagerState.update_mirrors(p39.state, p40, p41, p39.rig, p39.shots)

    local v17 = ManagerState.reset_requested(p39.state)

    if bit32.band(p39.state.options, 64) ~= 0 then
        if v17 then
            DropPredictor.reset(p39.drop)
        end

        local v18 = DropPredictor.prediction_velocity(v17, p41.rig.transform, p39.rig.fields.velocity, p42.drop)

        DropPredictor.update(p39.drop, p41.rig.transform[4], v18, ShotManager.current(p39.shots).shot.use_drop_predictor ~= 0 and not v17, p41.rig.off_board ~= 0, p41.rig.context, p42.drop, p46)
    end

    local v19 = (if v17 then ShotManager.first_leaf(p39.shots).use_free_camera_stick else ShotManager.current(p39.shots).shot.use_free_camera_stick) ~= 0

    p39.rig.fields.flags_517 = bit32.bor(bit32.band(p39.rig.fields.flags_517, 4294967279), (bit32.lshift(if v19 then 0 else 1, 4)))
    LookInput.update(p39.look, if v19 then p41.look else { 0, 0 }, p42.look)

    if v17 then
        ShotManager.make_instant(p39.shots)
        p39.rig.fields.velocity = { 0, 0, 0, 0 }
        p39.rig.fields.acceleration = { 0, 0, 0, 0 }
        p39.state.slowmo_frames = 0
        p39.shake = {
            ShakeEffect.new(),
            ShakeEffect.new()
        }
        p39.heading_multiplier = p39.state.heading_mirror.position
        p39.orientation.framing_mirror = p39.state.framing_mirror.position
    else
        if p41.rig.broken_bone_slowmo == 0 then
            p39.state.slowmo_frames = 0
        else
            p39.state.slowmo_frames = rt.wrapping_add_u32(p39.state.slowmo_frames, 1)
        end

        if p39.state.slowmo_frames == 1 then
            local v23 = p42.shake.impulse_magnitude * 20

            if p39.shake[1].impulse < v23 then
                p39.shake[1].impulse = v23
            end
        end
    end

    ShotManager.update(p39.shots, p40, (as_shot_environment({
        state = p39.state,
        subject = p41,
        rig = p39.rig,
        rig_forward = rt.copy(p39.subject_forward),
        angular_velocity = { 0, 0, 0, 0 },
        heading_multiplier = p39.heading_multiplier,
        previous_distance = p39.shots.previous.distance
    })))
    t1.CameraMan.bind_anchor(p39, p41, v17)
    p39.heading_multiplier = ManagerState.bind_shot(p39.state, p39.shots.interpolated, p41, p39.rig, p39.orientation, p39.drop, p39.look, p39.composer.roll, ShotManager.is_transitioning(p39.shots))

    if v17 then
        Rig.teleport(p39.rig)
        p39.frame.shake_translation = { 0, 0, 0, 0 }
    end

    Rig.update(p39.rig, p40, p42.rig, as_rig_subject(p41.rig), p44, p45, p46)
    p39.state.opacity = p39.shots.interpolated.subject_opacity
    p39.state.field_of_view = v4.lens_field_of_view(p39.shots.interpolated.lens_length, p39.state.aspect_ratio)
    p39.orientation.target = FrameComposer.compose(p39.composer, p40, ShotManager.framing_fraction(p39.shots), p39.orientation.framing_mirror, p39.shots.previous, ShotManager.current(p39.shots).shot, p39.rig.anchor.position, p39.rig.positioner.position, {
        positions = rt.copy(p41.rig.reference_positions),
        board_offset_direction = rt.copy(p41.board_offset_direction)
    }, p42.framing)
    p39.rig.fields.flags_516 = RigOrientation.update(p39.orientation, p40, p42.orientation, p39.rig.fields.reset_time, p39.rig.fields.flags_516, p39.rig.fields.flags_517)
    t1.CameraMan.finish_frame(p39, p40, p41, p42.shake, p43, v17)
    p39.shots.instant_changes = v17 or p39.state.instant_frames > 0

    if v17 then
        p39.state.options = bit32.band(p39.state.options, 127)
        p39.state.flags = bit32.bor(p39.state.flags, 2)
    elseif ManagerSubject.is_ground_camera(p41, p39.rig.fields.height_mode) then
        p39.state.flags = bit32.band(p39.state.flags, 4294967293)
    end

    if p39.state.instant_frames > 0 then
        p39.state.instant_frames -= 1
    end

    return rt.copy(p39.frame)
end

function t1.CameraMan.bind_anchor_reference(p47, p48, p49) -- line: 330
    -- upvalues: rt (copy), ShotManager (copy)
    local anchor

    if p49 then
        anchor = p47.shots.interpolated.anchor
    else
        anchor = ShotManager.current(p47.shots).shot.anchor

        if anchor ~= p47.state.selected_anchor then
            p47.rig.fields.flags_517 = bit32.bor(p47.rig.fields.flags_517, 64)
        end
    end

    p47.state.selected_anchor = anchor

    local v24 = p48.anchors[anchor + 1]

    p47.state.anchor = rt.copy(v24.position)

    local state = p47.state

    if p49 then
        state.anchor_velocity = { 0, 0, 0, 0 }
    else
        state.anchor_velocity = rt.copy(v24.velocity)
    end

    local t5 = {}

    t5[1] = p47.state.anchor_velocity[1] - p47.rig.fields.velocity[1]
    t5[2] = p47.state.anchor_velocity[2] - p47.rig.fields.velocity[2]
    t5[3] = p47.state.anchor_velocity[3] - p47.rig.fields.velocity[3]
    t5[4] = p47.state.anchor_velocity[4] - p47.rig.fields.velocity[4]
    p47.rig.fields.acceleration = t5
    p47.rig.fields.velocity = rt.copy(p47.state.anchor_velocity)
    p47.rig.fields.anchor = rt.copy(p47.state.anchor)
    p47.subject_forward = rt.copy(p48.rig.transform[3])
    p47.rig.fields.flags_516 = bit32.bor(p47.rig.fields.flags_516, 16)

    local composer = p47.composer

    if p49 then
        composer.reference = rt.copy(p47.state.anchor)
    else
        composer.reference = rt.copy(p47.rig.anchor.position)
    end
end

local v25 = table.freeze({ 0, 0, 0, 0 })
local v26 = table.freeze({ 0, 0 })
local t6 = {
    state = nil,
    subject = nil,
    rig = nil,
    heading_multiplier = 0,
    previous_distance = 0,
    rig_forward = v25,
    angular_velocity = v25
}
local v27 = table.freeze({
    heading_mirror = function(_) -- heading_mirror | line: 389
        -- upvalues: BlendEnvironment (copy), t6 (copy)
        return BlendEnvironment.heading_mirror(t6)
    end,
    compass_north = function(_, p52) -- compass_north | line: 392
        -- upvalues: BlendEnvironment (copy), t6 (copy)
        return BlendEnvironment.compass_north(t6, p52)
    end,
    special_camera_flag = function(_) -- special_camera_flag | line: 395
        -- upvalues: BlendEnvironment (copy), t6 (copy)
        return BlendEnvironment.special_camera_flag(t6)
    end,
    raw_blend_value = function(_, p55, p56, p57) -- raw_blend_value | line: 398
        -- upvalues: BlendEnvironment (copy), t6 (copy)
        return BlendEnvironment.raw_blend_value(t6, p55, p56, p57)
    end
})
local rig
local v28 = table.freeze({
    flag_568 = function(_) -- flag_568 | line: 407
        -- upvalues: rig (ref)
        return rig.in_ground_physics
    end,
    flag_596 = function(_) -- flag_596 | line: 410
        -- upvalues: rig (ref)
        return rig.grinding
    end,
    flag_680 = function(_) -- flag_680 | line: 413
        -- upvalues: rig (ref)
        return rig.subject_flag_328
    end,
    flag_540 = function(_) -- flag_540 | line: 416
        -- upvalues: rig (ref)
        return rig.trajectory_valid
    end,
    transform_376 = function(_) -- transform_376 | line: 420
        -- upvalues: rig (ref)
        return rig.transform
    end,
    vector_452 = function(_) -- vector_452 | line: 423
        -- upvalues: rig (ref)
        return rig.last_valid_ground_up
    end,
    vector_444 = function(_) -- vector_444 | line: 426
        -- upvalues: rig (ref)
        return rig.hips_position
    end,
    context_532 = function(_) -- context_532 | line: 429
        -- upvalues: rig (ref)
        return rig.context
    end,
    flag_608 = function(_) -- flag_608 | line: 432
        -- upvalues: rig (ref)
        return rig.off_board
    end,
    flag_548 = function(_) -- flag_548 | line: 435
        -- upvalues: rig (ref)
        return rig.wiping_out
    end,
    flag_584 = function(_) -- flag_584 | line: 439
        -- upvalues: rig (ref)
        return rig.physically_pushing
    end,
    flag_588 = function(_) -- flag_588 | line: 442
        -- upvalues: rig (ref)
        return rig.at_pushable_speed
    end,
    value_476 = function(_) -- value_476 | line: 445
        -- upvalues: rig (ref)
        return rig.pumping_acceleration
    end,
    flag_656 = function(_) -- flag_656 | line: 449
        -- upvalues: rig (ref)
        return rig.air_flag_452
    end,
    flag_668 = function(_) -- flag_668 | line: 453
        -- upvalues: rig (ref)
        return rig.broken_bone_slowmo
    end,
    flag_660 = function(_) -- flag_660 | line: 456
        -- upvalues: rig (ref)
        return rig.state_flag_81
    end,
    value_524 = function(_) -- value_524 | line: 459
        -- upvalues: rig (ref)
        return rig.state_height_32
    end,
    transform_384 = function(_) -- transform_384 | line: 462
        -- upvalues: rig (ref)
        return rig.skeleton_root
    end,
    position_360 = function(_, p77) -- position_360 | line: 465
        -- upvalues: rig (ref)
        return rig.reference_positions[p77 + 1]
    end
})
local t8 = {
    positions = nil,
    board_offset_direction = nil
}

local function update_core(p78, p79, p80, p81, p82, p83, p84, p85) -- line: 472
    -- upvalues: rt (copy), v4 (copy), ManagerState (copy), ManagerSubject (copy), Rig (copy), ShotManager (copy), RigOrientation (copy), FrameComposer (copy), DropPredictor (copy), LookInput (copy), ShakeEffect (copy), t1 (copy), v25 (copy), v26 (copy), t6 (copy), v27 (copy), rig (ref), v28 (copy), t8 (copy)
    local shots, state, rig2 = p78.shots, p78.state, p78.rig
    local fields = rig2.fields

    if ShotManager.current(shots).name == "" then
        error("The stock camera graph has not selected a shot", 0)
    end

    state.frames = rt.wrapping_add_u32(state.frames, 1)

    if state.frames > 30 then
        state.flags = bit32.bor(state.flags, 1)
    end

    ManagerState.update_mirrors(state, p79, p80, rig2, shots)

    local v29 = ManagerState.reset_requested(state)
    local rig3 = p80.rig

    if bit32.band(state.options, 64) ~= 0 then
        if v29 then
            DropPredictor.reset(p78.drop)
        end

        local v30, _, v31 = DropPredictor.prediction_velocity_lanes(v29, rig3.transform, fields.velocity, p81.drop)

        DropPredictor.update_lanes(p78.drop, rig3.transform[4], v30, v31, ShotManager.current(shots).shot.use_drop_predictor ~= 0 and not v29, rig3.off_board ~= 0, rig3.context, p81.drop, p85)
    end

    local v32 = (if v29 then ShotManager.first_leaf(shots).use_free_camera_stick else ShotManager.current(shots).shot.use_free_camera_stick) ~= 0

    fields.flags_517 = bit32.bor(bit32.band(fields.flags_517, 4294967279), (bit32.lshift(if v32 then 0 else 1, 4)))
    LookInput.update(p78.look, if v32 then p80.look else v26, p81.look)

    if v29 then
        ShotManager.make_instant(shots)
        fields.velocity = { 0, 0, 0, 0 }
        fields.acceleration = { 0, 0, 0, 0 }
        state.slowmo_frames = 0
        p78.shake = {
            ShakeEffect.new(),
            ShakeEffect.new()
        }
        p78.heading_multiplier = state.heading_mirror.position
        p78.orientation.framing_mirror = state.framing_mirror.position
    else
        if rig3.broken_bone_slowmo == 0 then
            state.slowmo_frames = 0
        else
            state.slowmo_frames = rt.wrapping_add_u32(state.slowmo_frames, 1)
        end

        if state.slowmo_frames == 1 then
            local v36 = p81.shake.impulse_magnitude * 20

            if p78.shake[1].impulse < v36 then
                p78.shake[1].impulse = v36
            end
        end
    end

    t6.state = state
    t6.subject = p80
    t6.rig = rig2
    t6.rig_forward = p78.subject_forward
    t6.heading_multiplier = p78.heading_multiplier
    t6.previous_distance = shots.previous.distance
    ShotManager.update(shots, p79, v27)
    t6.state = nil
    t6.subject = nil
    t6.rig = nil
    t6.rig_forward = v25
    t1.CameraMan.bind_anchor(p78, p80, v29)
    p78.heading_multiplier = ManagerState.bind_shot(state, shots.interpolated, p80, rig2, p78.orientation, p78.drop, p78.look, p78.composer.roll, ShotManager.is_transitioning(shots))

    if v29 then
        Rig.teleport(rig2)
        p78.frame.shake_translation = { 0, 0, 0, 0 }
    end

    rig = rig3
    Rig.update(rig2, p79, p81.rig, v28, p83, p84, p85)
    rig = nil
    state.opacity = shots.interpolated.subject_opacity
    state.field_of_view = v4.lens_field_of_view(shots.interpolated.lens_length, state.aspect_ratio)
    t8.positions = rig3.reference_positions
    t8.board_offset_direction = p80.board_offset_direction
    FrameComposer.compose_into(p78.composer, p78.orientation.target, p79, ShotManager.framing_fraction(shots), p78.orientation.framing_mirror, shots.previous, ShotManager.current(shots).shot, rig2.anchor.position, rig2.positioner.position, t8, p81.framing)
    t8.positions = nil
    t8.board_offset_direction = nil
    fields.flags_516 = RigOrientation.update(p78.orientation, p79, p81.orientation, fields.reset_time, fields.flags_516, fields.flags_517)
    t1.CameraMan.finish_frame(p78, p79, p80, p81.shake, p82, v29)
    shots.instant_changes = v29 or state.instant_frames > 0

    if v29 then
        state.options = bit32.band(state.options, 127)
        state.flags = bit32.bor(state.flags, 2)
    elseif ManagerSubject.is_ground_camera(p80, fields.height_mode) then
        state.flags = bit32.band(state.flags, 4294967293)
    end

    if state.instant_frames > 0 then
        state.instant_frames -= 1
    end
end

function t1.CameraMan.update(p86, p87, p88, p89, p90, p91, p92, p93) -- line: 608
    -- upvalues: rt (copy), PERF (copy), t1 (copy), update_core (copy)
    if PERF.reference then
        return t1.CameraMan.update_reference(p86, p87, p88, p89, p90, p91, p92, p93)
    end

    update_core(p86, p87, p88, p89, p90, p91, p92, p93)

    return rt.copy(p86.frame)
end

function t1.CameraMan.update_in_place(p94, p95, p96, p97, p98, p99, p100, p101) -- line: 617
    -- upvalues: PERF (copy), t1 (copy), update_core (copy)
    if PERF.reference then
        t1.CameraMan.update_reference(p94, p95, p96, p97, p98, p99, p100, p101)
    else
        update_core(p94, p95, p96, p97, p98, p99, p100, p101)
    end
end

function t1.CameraMan.bind_anchor(p102, p103, p104) -- line: 631
    -- upvalues: ShotManager (copy), PERF (copy), t1 (copy)
    if PERF.reference then
        return t1.CameraMan.bind_anchor_reference(p102, p103, p104)
    end

    local shots, state = p102.shots, p102.state
    local fields = p102.rig.fields
    local anchor

    if p104 then
        anchor = shots.interpolated.anchor
    else
        anchor = ShotManager.current(shots).shot.anchor

        if anchor ~= state.selected_anchor then
            fields.flags_517 = bit32.bor(fields.flags_517, 64)
        end
    end

    state.selected_anchor = anchor

    local v37 = p103.anchors[anchor + 1]
    local position = v37.position
    local v38 = position[1]
    local v39 = position[2]
    local v40 = position[3]
    local v41 = position[4]
    local v42, v43, v44, v45

    if p104 then
        v42 = 0
        v43 = 0
        v44 = 0
        v45 = 0
    else
        local velocity = v37.velocity

        v42 = velocity[1]
        v43 = velocity[2]
        v44 = velocity[3]
        v45 = velocity[4]
    end

    local anchor2 = state.anchor

    anchor2[1] = v38
    anchor2[2] = v39
    anchor2[3] = v40
    anchor2[4] = v41

    local anchor_velocity = state.anchor_velocity

    anchor_velocity[1] = v42
    anchor_velocity[2] = v43
    anchor_velocity[3] = v44
    anchor_velocity[4] = v45

    local velocity, acceleration = fields.velocity, fields.acceleration
    local v46 = v42 - velocity[1]
    local v47 = v43 - velocity[2]
    local v48 = v44 - velocity[3]
    local v49 = v45 - velocity[4]

    acceleration[1] = v46
    acceleration[2] = v47
    acceleration[3] = v48
    acceleration[4] = v49
    velocity[1] = v42
    velocity[2] = v43
    velocity[3] = v44
    velocity[4] = v45

    local anchor3 = fields.anchor

    anchor3[1] = v38
    anchor3[2] = v39
    anchor3[3] = v40
    anchor3[4] = v41

    local v50 = p103.rig.transform[3]
    local subject_forward = p102.subject_forward
    local v51 = v50[1]
    local v52 = v50[2]
    local v53 = v50[3]
    local v54 = v50[4]

    subject_forward[1] = v51
    subject_forward[2] = v52
    subject_forward[3] = v53
    subject_forward[4] = v54
    fields.flags_516 = bit32.bor(fields.flags_516, 16)

    local reference = p102.composer.reference

    if p104 then
        reference[1] = v38
        reference[2] = v39
        reference[3] = v40
        reference[4] = v41
    else
        local position = p102.rig.anchor.position
        local v55 = position[1]
        local v56 = position[2]
        local v57 = position[3]
        local v58 = position[4]

        reference[1] = v55
        reference[2] = v56
        reference[3] = v57
        reference[4] = v58
    end
end

for v59, v60 in v13.CameraMan do
    t1.CameraMan[v59] = v60
end

return t1
