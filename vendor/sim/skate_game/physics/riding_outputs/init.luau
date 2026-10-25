-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_from_bits(p1) -- line: 7
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p1)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local v2 = import("skate_game/physics/riding_outputs/ground_input")
local v3 = import("skate_game/physics/riding_outputs/probes")
local v4 = import("skate_core/air/body_spin")
local BodySpinState = v4.BodySpinState
local Vector3 = import("skate_core/math").Vector3
local BodyId = import("skate_core/physics/board").BodyId
local v5 = import("skate_core/physics/board_ground")
local BoardGroundState, WheelLineState, wheel_lines = v5.BoardGroundState, v5.WheelLineState, v5.wheel_lines
local BoardMotionOutput = import("skate_core/physics/board_motion_output").BoardMotionOutput
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime
local BoardWorld = import("skate_core/physics/board_world").BoardWorld
local GroundOrientation = import("skate_core/riding/ground_orientation").GroundOrientation
local ReckoningFrames = import("skate_core/riding/reckoning_frames").ReckoningFrames
local SpeedAndSlopeSettings = import("skate_core/riding/speed_and_slope").SpeedAndSlopeSettings
local Collections = import("skate_data/collections").Collections
local t1 = {
    BoardProbes = v3.BoardProbes
}
local BoardProbes = t1.BoardProbes
local vector, lanes, graph

local function map_from_bits(p2) -- line: 51
    -- upvalues: v1 (copy)
    local v6 = table.create(#p2)

    for i = 1, #p2 do
        buffer.writeu32(v1, 0, p2[i])
        v6[i] = buffer.readf32(v1, 0)
    end

    return v6
end

t1.RidingPoseInputs = {}
t1.RidingOutputs = {}

function t1.RidingOutputs.reset_for_teleport(p3) -- line: 80
    -- upvalues: rt (copy), BoardGroundState (copy), WheelLineState (copy), BoardProbes (copy)
    local time_without_wheel_contact = p3.ground.time_without_wheel_contact
    local v8 = rt.copy(p3.ground.wheel_angular_drag)

    p3.ground = BoardGroundState.default()
    p3.ground.time_without_wheel_contact = time_without_wheel_contact
    p3.ground.wheel_angular_drag = v8
    p3.wheel_lines = WheelLineState.default()
    BoardProbes.reset_results(p3.probes)
end

function t1.RidingOutputs.load(p4, p5, p6) -- line: 93
    -- upvalues: rt (copy), v1 (copy), BodySpinState (copy), BoardGroundState (copy), WheelLineState (copy), BoardMotionOutput (copy), GroundOrientation (copy), ReckoningFrames (copy), SpeedAndSlopeSettings (copy), Collections (copy), BoardProbes (copy), graph (ref)
    local function f(p7) -- line: 94
        -- upvalues: p4 (copy), Collections (copy)
        return Collections.float(p4, "physics_reckoning", "default", p7)
    end

    local function control(p8) -- line: 97
        -- upvalues: p4 (copy), v1 (copy), Collections (copy)
        local v9 = Collections.words(p4, "physics_reckoning", "default", p8, 4)
        local v10 = table.create(#v9)

        for i = 1, #v9 do
            buffer.writeu32(v1, 0, v9[i])
            v10[i] = buffer.readf32(v1, 0)
        end

        return v10
    end

    local function curve(p9) -- line: 100
        -- upvalues: p4 (copy), graph (ref)
        return graph(p4, "physics_reckoning", p9)
    end

    local v12 = Collections.words(p4, "physics_reckoning", "default", "DeckAngleUsageVsSpeed", 20)
    local v13 = table.create(#v12)

    for i = 1, #v12 do
        buffer.writeu32(v1, 0, v12[i])
        v13[i] = buffer.readf32(v1, 0)
    end

    local v15 = Collections.words(p4, "physics_reckoning", "default", "GroundNormalSmoothing", 4)
    local v16 = table.create(#v15)

    for i = 1, #v15 do
        buffer.writeu32(v1, 0, v15[i])
        v16[i] = buffer.readf32(v1, 0)
    end

    local v18 = Collections.words(p4, "physics_reckoning", "default", "UpVectorSmoothingSlow", 4)
    local v19 = table.create(#v18)

    for i = 1, #v18 do
        buffer.writeu32(v1, 0, v18[i])
        v19[i] = buffer.readf32(v1, 0)
    end

    local v21 = Collections.words(p4, "physics_reckoning", "default", "UpVectorSmoothingFast", 4)
    local v22 = table.create(#v21)

    for i = 1, #v21 do
        buffer.writeu32(v1, 0, v21[i])
        v22[i] = buffer.readf32(v1, 0)
    end

    local t2 = {
        ground_normal_smoothing = v16,
        up_vector_smoothing_slow = v19,
        up_vector_smoothing_fast = v22,
        dynamic_up_vs_ground_y = graph(p4, "physics_reckoning", "DynamicUpVsGroundY"),
        ground_vector_blend = graph(p4, "physics_reckoning", "GroundVectorBlendGraph"),
        deck_angle_usage_vs_speed = {
            x = rt.slice(v13, 4, 12),
            y = rt.slice(v13, 12, 20)
        },
        up_vector_smoothing_vs_speed = graph(p4, "physics_reckoning", "UpVectorSmoothingVsSpeed"),
        up_vector_max_delta_vs_speed = graph(p4, "physics_reckoning", "UpVectorMaxDeltaVsSpeed"),
        ground_blend_max_delta = Collections.float(p4, "physics_reckoning", "default", "GroundVMaxBlendDelta"),
        up_vector_max_acceleration = Collections.float(p4, "physics_reckoning", "default", "UpVectorMaxAcceleration"),
        anti_wobble_damping = Collections.float(p4, "physics_reckoning", "default", "UpVectAntiWobbleDamping"),
        extra_side_damping = Collections.float(p4, "physics_reckoning", "default", "ExtraSideDamping"),
        minimum_wheels_for_ground_blend = rt.to_i32(Collections.integer(p4, "physics_reckoning", "default", "MinWheelsToUseGroundVector"))
    }
    local t3 = {
        turn_torque_vs_speed = graph(p4, "physics_heading", "TurnTorqueVsSpeed"),
        turn_torque_vs_slope = graph(p4, "physics_heading", "TurnTorqueVsSlope"),
        heading_adjust_max_speed = Collections.float(p4, "physics_heading", "default", "HeadingAdjustMaxSpeed")
    }
    local v24 = GroundOrientation.new(t2)
    local v25 = BoardMotionOutput.from_board(p5, rt.copy(v24.ground_normal), p6)
    local v26 = BoardGroundState.default()
    local v27 = SpeedAndSlopeSettings.calculate(t3, v26.wheel_normal.y, v25.forward_speed)

    return {
        pending_wheel_queries = nil,
        ground = v26,
        wheel_lines = WheelLineState.default(),
        probes = BoardProbes.default(),
        reckoning = v24,
        reckoning_frames = ReckoningFrames.new(),
        body_spin = BodySpinState.new(),
        motion = v25,
        orientation_settings = t2,
        tilt_vs_rotation = graph(p4, "physics_reckoning", "TiltVsRotGround"),
        tilt_vs_slope = graph(p4, "physics_reckoning", "TiltVsSlopeGround"),
        speed_settings = t3,
        maximum_ground_angle = Collections.float(p4, "physics_reckoning", "default", "MaxAllowedGroundNormalFromUp"),
        heading_adjust_factor = v27
    }
end

function t1.RidingOutputs.update_input_heading(p10, p11, p12) -- line: 182
    -- upvalues: SpeedAndSlopeSettings (copy)
    p10.heading_adjust_factor = SpeedAndSlopeSettings.calculate(p10.speed_settings, p11, p12)

    return p10.heading_adjust_factor
end

function t1.RidingOutputs.heading_adjust_factor(p13) -- line: 187
    return p13.heading_adjust_factor
end

local v28 = BoardRuntime.transform_scratch()
local v29 = false

function t1.set_reference_x2(p14) -- line: 222
    -- upvalues: v29 (ref)
    v29 = p14
end

local ground_reckoning_with_deck_r3

local function ground_reckoning_with_deck(p15, p16, p17, p18, p19, p20, p21, p22, p23) -- line: 226
    -- upvalues: rt (copy), v2 (copy), v4 (copy), Vector3 (copy), BodyId (copy), BoardMotionOutput (copy), BoardRuntime (copy), GroundOrientation (copy), ReckoningFrames (copy), vector (ref), lanes (ref), v28 (copy), v29 (ref), ground_reckoning_with_deck_r3 (ref)
    if v29 then
        return ground_reckoning_with_deck_r3(p15, p16, p17, p18, p19, p20, p21, p22, p23)
    end

    local v30 = v2.GroundPacketInputs.from_processed(p21)
    local v31 = if p23 == nil then BoardRuntime.part_transform_into(p16, BodyId.index(BodyId.Deck), v28) else p23
    local v32 = p15.reckoning_frames.system[1]
    local v33 = v32[1]
    local v34 = v32[2]
    local v35 = v32[3]

    p15.reckoning_frames.heading = rt.copy(p22)
    v4.update_ground(p15.body_spin, p17.body_spin)

    local v36, v37, v38 = BoardMotionOutput.effective_forward(p16, p18)
    local v39

    if v36 ~= nil then
        v39 = Vector3.new(v36, v37, v38)
    else
        local v40 = BoardMotionOutput.from_board(p16, rt.copy(p15.reckoning.ground_normal), p18)

        v39 = vector(v40.effective_basis.columns[3])
    end

    local columns = v31.basis.columns

    GroundOrientation.update(p15.reckoning, p15.orientation_settings, {
        com_to_deck = rt.copy(p17.com_to_deck),
        ground_normal = v30.wheel_normal,
        dynamic_up = v30.dynamic_up,
        speed = v30.speed,
        wheel_contact_count = v30.wheel_count,
        animation_balance = p19,
        deck_angle_curve_input = v30.absolute_speed,
        board_up = vector(columns[2]),
        board_forward = vector(columns[3]),
        effective_board_forward = v39,
        previous_reckoning_right = Vector3.new(v33, v34, v35),
        prevent_up_behind_board = p20
    })

    local v41 = lanes(p15.reckoning.up)

    ReckoningFrames.calculate_transform(p15.reckoning_frames, rt.copy(v41), lanes(p15.reckoning.ground_normal))
    ReckoningFrames.calculate_dynamic_lean(p15.reckoning_frames, rt.copy(v41), lanes(p15.reckoning.dynamic_up))
    ReckoningFrames.calculate_tilt(p15.reckoning_frames, bit32.band(p18, 1048576) ~= 0, p15.tilt_vs_rotation, p15.tilt_vs_slope)
end

function ground_reckoning_with_deck_r3(p24, p25, p26, p27, p28, p29, p30, p31, p32) -- line: 293
    -- upvalues: rt (copy), v2 (copy), v4 (copy), Vector3 (copy), BodyId (copy), BoardMotionOutput (copy), BoardRuntime (copy), GroundOrientation (copy), ReckoningFrames (copy), vector (ref), lanes (ref), v28 (copy)
    local v42 = v2.GroundPacketInputs.from_processed(p30)
    local v43 = if p32 == nil then BoardRuntime.part_transform_into(p25, BodyId.index(BodyId.Deck), v28) else p32
    local v44 = rt.copy(p24.reckoning_frames.system[1])

    p24.reckoning_frames.heading = rt.copy(p31)
    v4.update_ground(p24.body_spin, p26.body_spin)

    local v45 = BoardMotionOutput.from_board(p25, rt.copy(p24.reckoning.ground_normal), p27)

    GroundOrientation.update(p24.reckoning, p24.orientation_settings, {
        com_to_deck = rt.copy(p26.com_to_deck),
        ground_normal = rt.copy(v42.wheel_normal),
        dynamic_up = rt.copy(v42.dynamic_up),
        speed = v42.speed,
        wheel_contact_count = v42.wheel_count,
        animation_balance = p28,
        deck_angle_curve_input = v42.absolute_speed,
        board_up = vector(v43.basis.columns[2]),
        board_forward = vector(v43.basis.columns[3]),
        effective_board_forward = vector(v45.effective_basis.columns[3]),
        previous_reckoning_right = Vector3.new(v44[1], v44[2], v44[3]),
        prevent_up_behind_board = p29
    })

    local v46 = lanes(p24.reckoning.up)

    ReckoningFrames.calculate_transform(p24.reckoning_frames, rt.copy(v46), lanes(p24.reckoning.ground_normal))
    ReckoningFrames.calculate_dynamic_lean(p24.reckoning_frames, rt.copy(v46), lanes(p24.reckoning.dynamic_up))
    ReckoningFrames.calculate_tilt(p24.reckoning_frames, bit32.band(p27, 1048576) ~= 0, p24.tilt_vs_rotation, p24.tilt_vs_slope)
end

function t1.RidingOutputs.update_ground_reckoning(p33, p34, p35, p36, p37, p38, p39) -- line: 337
    -- upvalues: BodyId (copy), BoardRuntime (copy), v28 (copy), ground_reckoning_with_deck (copy)
    local v47 = BoardRuntime.part_transform_into(p34, BodyId.index(BodyId.Deck), v28)

    ground_reckoning_with_deck(p33, p34, p35, p36, p37, p38, p39, {
        v47.basis.columns[3][1],
        v47.basis.columns[3][2],
        v47.basis.columns[3][3],
        0
    }, v47)
end

function t1.RidingOutputs.update_ground_reckoning_with_heading(p40, p41, p42, p43, p44, p45, p46, p47) -- line: 371
    -- upvalues: ground_reckoning_with_deck (copy)
    ground_reckoning_with_deck(p40, p41, p42, p43, p44, p45, p46, p47, nil)
end

function t1.RidingOutputs.update_ground_reckoning_reference(p48, p49, p50, p51, p52, p53, p54) -- line: 406
    -- upvalues: BodyId (copy), BoardRuntime (copy), t1 (copy)
    local v48 = BoardRuntime.part_transforms(p49)[BodyId.index(BodyId.Deck) + 1]

    t1.RidingOutputs.update_ground_reckoning_with_heading_reference(p48, p49, p50, p51, p52, p53, p54, {
        v48.basis.columns[3][1],
        v48.basis.columns[3][2],
        v48.basis.columns[3][3],
        0
    })
end

function t1.RidingOutputs.update_ground_reckoning_with_heading_reference(p55, p56, p57, p58, p59, p60, p61, p62) -- line: 432
    -- upvalues: rt (copy), v2 (copy), v4 (copy), Vector3 (copy), BodyId (copy), BoardMotionOutput (copy), BoardRuntime (copy), GroundOrientation (copy), ReckoningFrames (copy), vector (ref), lanes (ref)
    local v49 = v2.GroundPacketInputs.from_processed(p61)
    local v50 = BoardRuntime.part_transforms(p56)[BodyId.index(BodyId.Deck) + 1]
    local v51 = rt.copy(p55.reckoning_frames.system[1])

    p55.reckoning_frames.heading = rt.copy(p62)
    v4.update_ground(p55.body_spin, p57.body_spin)

    local v52 = BoardMotionOutput.from_board(p56, rt.copy(p55.reckoning.ground_normal), p58)

    GroundOrientation.update(p55.reckoning, p55.orientation_settings, {
        com_to_deck = rt.copy(p57.com_to_deck),
        ground_normal = rt.copy(v49.wheel_normal),
        dynamic_up = rt.copy(v49.dynamic_up),
        speed = v49.speed,
        wheel_contact_count = v49.wheel_count,
        animation_balance = p59,
        deck_angle_curve_input = v49.absolute_speed,
        board_up = vector(v50.basis.columns[2]),
        board_forward = vector(v50.basis.columns[3]),
        effective_board_forward = vector(v52.effective_basis.columns[3]),
        previous_reckoning_right = Vector3.new(v51[1], v51[2], v51[3]),
        prevent_up_behind_board = p60
    })

    local v53 = lanes(p55.reckoning.up)

    ReckoningFrames.calculate_transform(p55.reckoning_frames, rt.copy(v53), lanes(p55.reckoning.ground_normal))
    ReckoningFrames.calculate_dynamic_lean(p55.reckoning_frames, rt.copy(v53), lanes(p55.reckoning.dynamic_up))
    ReckoningFrames.calculate_tilt(p55.reckoning_frames, bit32.band(p58, 1048576) ~= 0, p55.tilt_vs_rotation, p55.tilt_vs_slope)
end

function t1.RidingOutputs.update_slide_reckoning(p63, p64, p65, p66, p67) -- line: 478
    -- upvalues: rt (copy), v1 (copy), v4 (copy), Vector3 (copy), GroundOrientation (copy), ReckoningFrames (copy), lanes (ref)
    local function raw(p68) -- line: 479
        -- upvalues: v1 (copy), Vector3 (copy)
        local v54 = table.create(#p68)

        for i = 1, #p68 do
            buffer.writeu32(v1, 0, p68[i])
            v54[i] = buffer.readf32(v1, 0)
        end

        return Vector3.new(v54[1], v54[2], v54[3])
    end

    local function xyz(p69) -- line: 483
        -- upvalues: Vector3 (copy)
        return Vector3.new(p69[1], p69[2], p69[3])
    end

    local v56 = rt.copy(p63.reckoning_frames.system[1])

    p63.reckoning_frames.heading = rt.copy(p65.deck[3])

    local reckoning = p63.reckoning
    local v57 = p64.vectors_464_480_496_512_528[5]
    local v58 = table.create(#v57)

    for i = 1, #v57 do
        buffer.writeu32(v1, 0, v57[i])
        v58[i] = buffer.readf32(v1, 0)
    end

    reckoning.dynamic_up = Vector3.new(v58[1], v58[2], v58[3])
    v4.update_ground(p63.body_spin, p66)

    local update = GroundOrientation.update
    local reckoning2, orientation_settings = p63.reckoning, p63.orientation_settings
    local t4 = {}
    local animation_com_to_deck_752 = p64.animation_com_to_deck_752
    local v60 = table.create(#animation_com_to_deck_752)

    for i = 1, #animation_com_to_deck_752 do
        buffer.writeu32(v1, 0, animation_com_to_deck_752[i])
        v60[i] = buffer.readf32(v1, 0)
    end

    t4.com_to_deck = Vector3.new(v60[1], v60[2], v60[3])

    local v62 = p64.vectors_464_480_496_512_528[1]
    local v63 = table.create(#v62)

    for i = 1, #v62 do
        buffer.writeu32(v1, 0, v62[i])
        v63[i] = buffer.readf32(v1, 0)
    end

    t4.ground_normal = Vector3.new(v63[1], v63[2], v63[3])

    local v65 = p64.vectors_464_480_496_512_528[5]
    local v66 = table.create(#v65)

    for i = 1, #v65 do
        buffer.writeu32(v1, 0, v65[i])
        v66[i] = buffer.readf32(v1, 0)
    end

    t4.dynamic_up = Vector3.new(v66[1], v66[2], v66[3])
    t4.speed = p64.scalar_2652
    t4.wheel_contact_count = rt.to_i32(p64.wheel_count_2556)
    t4.animation_balance = p67
    t4.deck_angle_curve_input = p65.absolute_speed

    local v68 = p65.deck[2]

    t4.board_up = Vector3.new(v68[1], v68[2], v68[3])

    local v69 = p65.deck[3]

    t4.board_forward = Vector3.new(v69[1], v69[2], v69[3])

    local v70 = p65.effective[3]

    t4.effective_board_forward = Vector3.new(v70[1], v70[2], v70[3])
    t4.previous_reckoning_right = Vector3.new(v56[1], v56[2], v56[3])
    t4.prevent_up_behind_board = bit32.band(p64.flags_2476, 1073741824) ~= 0
    update(reckoning2, orientation_settings, t4)

    local v71 = lanes(p63.reckoning.up)

    ReckoningFrames.calculate_transform(p63.reckoning_frames, rt.copy(v71), lanes(p63.reckoning.ground_normal))
    ReckoningFrames.calculate_dynamic_lean(p63.reckoning_frames, rt.copy(v71), lanes(p63.reckoning.dynamic_up))
    ReckoningFrames.calculate_tilt(p63.reckoning_frames, bit32.band(p64.flags_2468, 1048576) ~= 0, p63.tilt_vs_rotation, p63.tilt_vs_slope)
end

function t1.RidingOutputs.start_wheel_queries(p70, p71, p72) -- line: 519
    -- upvalues: rt (copy), wheel_lines (copy), BoardWorld (copy), BoardProbes (copy), v29 (ref)
    if p70.pending_wheel_queries ~= nil then
        error("Wheel queries were started twice without result publication", 0)
    end

    local v73 = wheel_lines(p71, if v29 then rt.copy(p70.reckoning.up) else p70.reckoning.up)
    local t5 = {}

    for i = 0, 3 do
        local v74 = v73[i + 1]
        local query_thin_line = BoardWorld.query_thin_line
        local start, v75 = v74.start, v74["end"]
        local ok, result = pcall(query_thin_line, p72, start, v75)

        if not ok then
            error(string.format("Wheel%d stock line query: %s", i, (tostring(result))), 0)
        end

        if result ~= nil then
            t5[i + 1] = {
                fraction = result.geometry.fraction,
                normal = rt.copy(result.geometry.normal),
                surface_tag = result.tag
            }
        end
    end

    BoardProbes.start(p70.probes, p71, p72)
    p70.pending_wheel_queries = t5
end

function t1.RidingOutputs.finish_wheel_queries(p73) -- line: 550
    -- upvalues: WheelLineState (copy), BoardProbes (copy)
    local pending_wheel_queries = p73.pending_wheel_queries

    p73.pending_wheel_queries = nil

    if pending_wheel_queries == nil then
        error("EndBoard requires its submitted wheel query batch", 0)
    end

    WheelLineState.publish(p73.wheel_lines, pending_wheel_queries)

    return BoardProbes.publish(p73.probes)
end

function t1.RidingOutputs.finish_post_physics(p74, p75, p76, p77, p78) -- line: 571
    -- upvalues: BoardGroundState (copy), BoardMotionOutput (copy), BoardRuntime (copy), t1 (copy), v29 (ref)
    if v29 then
        return t1.RidingOutputs.finish_post_physics_r3(p74, p75, p76, p77, p78)
    end

    BoardGroundState.update(p74.ground, BoardRuntime.contact_reports(p75), p74.wheel_lines, p74.reckoning.up, p74.maximum_ground_angle, p76)
    BoardGroundState.sample_body_accelerations(p74.ground, BoardRuntime.bodies(p75), p78)
    BoardGroundState.advance_contact_time(p74.ground, p78)

    local v76 = BoardRuntime.bodies_mut(p75)
    local wheel_angular_drag = p74.ground.wheel_angular_drag

    for i = 1, math.min(4, #wheel_angular_drag) do
        v76[i].inertia.angular_drag = wheel_angular_drag[i]
    end

    p74.motion = BoardMotionOutput.from_board(p75, p74.reckoning.ground_normal, p77)
end

function t1.RidingOutputs.finish_post_physics_r3(p79, p80, p81, p82, p83) -- line: 602
    -- upvalues: rt (copy), BoardGroundState (copy), BoardMotionOutput (copy), BoardRuntime (copy)
    BoardGroundState.update(p79.ground, BoardRuntime.contact_reports(p80), p79.wheel_lines, rt.copy(p79.reckoning.up), p79.maximum_ground_angle, p81)

    local v78 = BoardRuntime.bodies(p80)

    BoardGroundState.sample_accelerations(p79.ground, rt.from_fn(#v78, function(p84) -- line: 620
        -- upvalues: v78 (copy), rt (copy)
        return rt.copy(v78[p84 + 1].rates.linear_velocity)
    end), p83)
    BoardGroundState.advance_contact_time(p79.ground, p83)

    local v79 = BoardRuntime.bodies_mut(p80)
    local wheel_angular_drag = p79.ground.wheel_angular_drag

    for i = 1, math.min(4, #wheel_angular_drag) do
        v79[i].inertia.angular_drag = wheel_angular_drag[i]
    end

    p79.motion = BoardMotionOutput.from_board(p80, rt.copy(p79.reckoning.ground_normal), p82)
end

function t1.RidingOutputs.graph_speeds(p85) -- line: 637
    return {
        speed = p85.motion.ground_speed,
        forward_speed = p85.motion.forward_speed,
        speed_and_slope = p85.heading_adjust_factor
    }
end

function vector(p86) -- line: 646
    -- upvalues: Vector3 (copy)
    return Vector3.new(p86[1], p86[2], p86[3])
end

t1.vector = vector

function lanes(p87) -- line: 652
    return {
        p87.x,
        p87.y,
        p87.z,
        0
    }
end

t1.lanes = lanes

function graph(p88, p89, p90) -- line: 658
    -- upvalues: rt (copy), v1 (copy), Collections (copy)
    local v81 = Collections.words(p88, p89, "default", p90, 16)
    local v82 = table.create(#v81)

    for i = 1, #v81 do
        buffer.writeu32(v1, 0, v81[i])
        v82[i] = buffer.readf32(v1, 0)
    end

    return {
        x = rt.slice(v82, 0, 8),
        y = rt.slice(v82, 8, 16)
    }
end

t1.graph = graph

return t1
