-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_subnormal_mantissa(p1) -- line: 7
    local v2 = p1 * 7.1362384635298E+44
    local v3 = math.floor(v2)
    local v4 = v2 - v3

    if v4 > 0.5 or v4 == 0.5 and v3 % 2 == 1 then
        return v3 + 1
    end

    return v3
end

local function rtl_to_bits(p2) -- line: 16
    -- upvalues: v1 (copy)
    if p2 ~= 0 and p2 > -1.1754943508222875E-38 and p2 < 1.1754943508222875E-38 then
        local v6 = math.abs(p2) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        if p2 < 0 then
            return v5 + 2147483648
        end

        return v5
    end

    buffer.writef32(v1, 0, p2)

    return (buffer.readu32(v1, 0))
end

local function rtl_from_bits(p3) -- line: 24
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p3)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local Vector3 = import("skate_core/math").Vector3

local function ground_runtime() -- line: 37
    -- upvalues: import (copy)
    return import("skate_game/physics/ground_runtime")
end

local function skeleton_controller() -- line: 40
    -- upvalues: import (copy)
    return import("skate_game/physics/skeleton_controller")
end

local function skeleton_output() -- line: 43
    -- upvalues: import (copy)
    return import("skate_game/physics/skeleton_output")
end

local function handplant() -- line: 46
    -- upvalues: import (copy)
    return import("skate_game/physics/handplant")
end

local function air_phase() -- line: 49
    -- upvalues: import (copy)
    return import("skate_game/physics/air_phase")
end

local function air_trajectory() -- line: 52
    -- upvalues: import (copy)
    return import("skate_game/physics/air_trajectory")
end

local function solve() -- line: 55
    -- upvalues: import (copy)
    return import("skate_game/physics/solve")
end

local function board_manager_runtime() -- line: 58
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/board_manager/runtime")
end

local function board_possession() -- line: 61
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/board_possession")
end

local function skeleton_targets() -- line: 64
    -- upvalues: import (copy)
    return import("skate_core/physics/skeleton_body")
end

local raw, lanes, xyz
local t1 = {}

t1.GroundEdge = {}
t1.GroundLifecycle = {}

function t1.GroundLifecycle.new() -- line: 95
    -- upvalues: import (copy)
    return {
        skeleton_elapsed_16505 = false,
        board_animated_290 = 0,
        manual_drag_2724 = 0,
        edge = nil,
        pending_wall_jump = nil,
        skeleton_controller = import("skate_game/physics/skeleton_controller").SkeletonControllerState.new()
    }
end

function t1.reset_board_state(p4, p5, p6, _) -- line: 110
    -- upvalues: import (copy)
    p4.steering.deck_tilt = 0
    p4.steering.targets = { 0, 0 }
    import("skate_game/physics/ground_runtime").GroundRuntime.reset_board_toolkit(p5)
    p6.board_animated_290 = 0

    return false
end

function t1.enter(p8, p9) -- line: 122
    -- upvalues: import (copy), t1 (copy)
    local toolkit = p9.player_input.toolkit

    if toolkit == nil then
        error("Ground entry requires PlayerInput's current board toolkit", 0)
    end

    local LiveState = import("skate_game/physics/offboard/board_manager/runtime").LiveState
    local v8 = LiveState.effects(p9.board_possession_live, p8, p9.ground_lifecycle.board_animated_290, p9.player_input.processed.timestep_2604)
    local standard_board = import("skate_game/physics/offboard/board_possession").Effects.standard_board
    local ok, result = pcall(standard_board, v8)

    p9.ground_lifecycle.board_animated_290 = v8.animated_290
    p8.board_wiping_out = v8.wiping_out
    p9.board_possession_live.alignment_active = v8.alignment_active

    if not ok then
        error(result, 0)
    end

    LiveState.publish_volumes(p9.board_possession_live, p8)
    p8.board_wiping_out = t1.enter_components(p8.board, p9.player_input.processed, p9.animation_input, toolkit, p9.ground, p9.ground_lifecycle, p9.air_reckoning.state, p9.wipeout.state, p9.skeleton_collision, p9.foot_ik, p9.skeleton_output, p8.board_wiping_out)
end

function t1.enter_components(p10, p11, p12, p13, p14, p15, p16, p17, p18, p19, p20, p21) -- line: 169
    -- upvalues: import (copy)
    local v11 = bit32.band(bit32.lshift(if p21 then 1 else 0, 7), 255)

    local function collision(p22) -- line: 185
        -- upvalues: p15 (copy), p18 (copy), import (copy)
        if p22 ~= 6 then
            error("Ground requested a non-ground skeleton collision state", 0)
        end

        return import("skate_game/physics/skeleton_controller").SkeletonControllerState.request_ground(p15.skeleton_controller, p18)
    end

    local function landing(p23) -- line: 191
        -- upvalues: p20 (copy), import (copy)
        import("skate_game/physics/skeleton_output").SkeletonOutput.trigger_wobble(p20, true, p23)
    end

    local t2 = {
        foot_ik = p19,
        skeleton_elapsed_16505 = p15.skeleton_elapsed_16505,
        reckoning_spin_angle = p16.spin_angle,
        reckoning_spin_speed = p16.spin_speed,
        board_flags_8384 = v11,
        board_animated_290 = p15.board_animated_290,
        wipeout_mode = p17.mode,
        wipeout_timer = p17.balance,
        set_skeleton_collision_state = collision,
        enter_air_landing_modifier = landing
    }
    local enter = import("skate_game/physics/ground_runtime").GroundState.enter
    local ok, result = pcall(enter, p14, p10, p11, p12, p13, t2)

    p15.skeleton_elapsed_16505 = t2.skeleton_elapsed_16505
    p16.spin_angle = t2.reckoning_spin_angle
    p16.spin_speed = t2.reckoning_spin_speed

    local board_flags_8384 = t2.board_flags_8384

    p15.board_animated_290 = t2.board_animated_290
    p17.mode = t2.wipeout_mode
    p17.balance = t2.wipeout_timer

    local v12 = bit32.band(board_flags_8384, 128) ~= 0

    if not ok then
        error(result, 0)
    end

    return v12
end

function t1.advance(p24, p25) -- line: 227
    -- upvalues: rt (copy), v1 (copy), import (copy), Vector3 (copy), raw (ref), lanes (ref), xyz (ref)
    import("skate_game/physics/handplant").ground_query(p24, p25)

    local v13 = import("skate_game/physics/air_phase").selector_input(p24, p25)
    local processed, toolkit = p25.player_input.processed, p25.player_input.toolkit

    if toolkit == nil then
        error("Ground update requires PlayerInput's current board toolkit", 0)
    end

    local ground_lifecycle = p25.ground_lifecycle

    if ground_lifecycle.pending_wall_jump ~= nil then
        error("Ground wall jump is pending its trajectory selector continuation", 0)
    end

    local v14 = if ground_lifecycle.edge == nil then {
        flags = 0,
        point = { 0, 0, 0, 0 },
        start = Vector3.new(0, 0, 0),
        ["end"] = Vector3.new(0, 0, 0)
    } else rt.copy(ground_lifecycle.edge)
    local v15 = raw(processed.vectors_464_480_496_512_528[1])
    local v16 = raw(processed.vectors_544_560_592_608[1])
    local v17 = raw(processed.vectors_400_416[1])
    local v18 = rt.copy(v17)
    local v19 = rt.copy(p25.animated_skeleton.roots.predicted_board_position)
    local targets = p25.skeleton_drives.targets

    local function move_future(p26) -- line: 258
        -- upvalues: v19 (copy), targets (copy), import (copy)
        import("skate_core/physics/skeleton_body").SkeletonTargets.apply_future_deck_displacement(targets, p26)
        v19[1] += p26.x
        v19[2] += p26.y
        v19[3] += p26.z
    end

    local v20 = import("skate_game/physics/air_trajectory").GrindContext.from_processed(p25.player_input.processed, rt.copy(import("skate_game/physics/solve").deck_frame(p24.board)[4]))

    local function launch(p27) -- line: 268
        -- upvalues: p24 (copy), p25 (copy), v13 (copy), v20 (copy), rt (copy), import (copy)
        local AirTrajectoryRuntime = import("skate_game/physics/air_trajectory").AirTrajectoryRuntime
        local v21 = rt.copy(v13)

        v21.board_vertical_velocity = p27.velocity[2]
        AirTrajectoryRuntime.launch(p25.trajectory, import("skate_game/physics/ground_runtime").GroundLaunchInfo.selector_launch(p27), rt.copy(v21), p24.world)
        AirTrajectoryRuntime.update(p25.trajectory, rt.copy(v21), p24.world, rt.copy(v20))
    end

    local t3 = {
        skeleton_record = p25.animated_skeleton.record,
        wall_ride = {
            board_normal = rt.copy(v15),
            up = rt.copy(v16),
            velocity = rt.copy(v18),
            board_mass = toolkit.total_mass,
            gravity = processed.gravity_2648,
            speed = processed.scalar_2652,
            contact_count = rt.to_i32(processed.wheel_count_2556)
        },
        collision = {
            flags_2472 = processed.flags_2472,
            collision_displacement = raw(processed.collision_pose_error_736),
            velocity = raw(processed.vectors_400_416[2]),
            forward = rt.copy(toolkit.travel_direction),
            up = rt.copy(v16),
            ground_normal = lanes(p24.riding.reckoning.ground_normal),
            time_step = processed.timestep_2604,
            mass = toolkit.total_mass
        },
        hang_geometry = {
            edge_start = rt.copy(v14.start),
            edge_end = rt.copy(v14["end"]),
            reference_point = xyz(v14.point)
        },
        processed_velocity = v18,
        wheel_material = p24.settings.wheel_material,
        wipeout = p25.wipeout.state,
        time_step = processed.timestep_2604,
        launch_physical = {
            reckoning = p24.riding.reckoning_frames,
            skeleton_vector_16208 = rt.copy(p25.animated_skeleton.board_frames.local_centre_of_mass),
            skeleton_vector_16240 = rt.copy(p25.animated_skeleton.board_frames.local_board_position),
            board_position = rt.copy(toolkit.deck[4]),
            physical_center_of_mass = raw(processed.vectors_544_560_592_608[3]),
            velocity = rt.copy(v17),
            angular_velocity = raw(processed.prepared_jump_704),
            flags_2468 = processed.flags_2468,
            time_step = processed.timestep_2604
        },
        launch_and_update = launch
    }
    local t4 = {
        foot_ik = p25.foot_ik,
        skeleton_elapsed_16505 = ground_lifecycle.skeleton_elapsed_16505,
        board_correction_pending = p25.skeleton_output.correction.pending,
        move_future_deck = move_future,
        offboard_grab = p25.offboard_grab
    }
    local update = import("skate_game/physics/ground_runtime").GroundState.update
    local ground, ground_runtime = p25.ground, p25.ground_runtime
    local board, world = p24.board, p24.world
    local ground_settings = p25.ground_settings
    local t5 = {
        processed = processed,
        animation = p25.animation_input,
        riding = p24.riding,
        skeleton = p25.animated_skeleton,
        toolkit = toolkit,
        base_trucks = rt.copy(p24.settings.step.base_truck_transforms),
        extra = {
            manual_drag_2724 = ground_lifecycle.manual_drag_2724,
            trajectory_state_bits = processed.external_physics_1616.flags,
            edge_flags = v14.flags,
            edge_point = rt.copy(v14.point)
        }
    }
    local ok, result = pcall(update, ground, ground_runtime, board, world, ground_settings, t5, t3, t4)

    ground_lifecycle.skeleton_elapsed_16505 = t4.skeleton_elapsed_16505
    p25.skeleton_output.correction.pending = t4.board_correction_pending

    local vectors_400_416 = p25.player_input.processed.vectors_400_416
    local v22 = v18[1]
    local v23

    if v22 ~= 0 and v22 > -1.1754943508222875E-38 and v22 < 1.1754943508222875E-38 then
        local v24 = math.abs(v22) * 7.1362384635298E+44
        local v25 = math.floor(v24)
        local v26 = v24 - v25

        v23 = if v26 > 0.5 or v26 == 0.5 and v25 % 2 == 1 then v25 + 1 else v25

        if v22 < 0 then
            v23 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v22)
        v23 = buffer.readu32(v1, 0)
    end

    local v27 = v18[2]
    local v28

    if v27 ~= 0 and v27 > -1.1754943508222875E-38 and v27 < 1.1754943508222875E-38 then
        local v29 = math.abs(v27) * 7.1362384635298E+44
        local v30 = math.floor(v29)
        local v31 = v29 - v30

        v28 = if v31 > 0.5 or v31 == 0.5 and v30 % 2 == 1 then v30 + 1 else v30

        if v27 < 0 then
            v28 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v27)
        v28 = buffer.readu32(v1, 0)
    end

    local v32 = v18[3]
    local v33

    if v32 ~= 0 and v32 > -1.1754943508222875E-38 and v32 < 1.1754943508222875E-38 then
        local v34 = math.abs(v32) * 7.1362384635298E+44
        local v35 = math.floor(v34)
        local v36 = v34 - v35

        v33 = if v36 > 0.5 or v36 == 0.5 and v35 % 2 == 1 then v35 + 1 else v35

        if v32 < 0 then
            v33 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v32)
        v33 = buffer.readu32(v1, 0)
    end

    local v37 = v18[4]
    local v38

    if v37 ~= 0 and v37 > -1.1754943508222875E-38 and v37 < 1.1754943508222875E-38 then
        local v39 = math.abs(v37) * 7.1362384635298E+44
        local v40 = math.floor(v39)
        local v41 = v39 - v40

        v38 = if v41 > 0.5 or v41 == 0.5 and v40 % 2 == 1 then v40 + 1 else v40

        if v37 < 0 then
            v38 += 2147483648
        end
    else
        buffer.writef32(v1, 0, v37)
        v38 = buffer.readu32(v1, 0)
    end

    vectors_400_416[1] = {
        v23,
        v28,
        v33,
        v38
    }
    p25.animated_skeleton.roots.predicted_board_position = v19

    if not ok then
        error(result, 0)
    end

    return result
end

function t1.raw(p28) -- line: 369
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p28[1])

    local v43 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p28[2])

    local v45 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p28[3])

    local v47 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p28[4])

    return {
        v43,
        v45,
        v47,
        (buffer.readf32(v1, 0))
    }
end

raw = t1.raw

function t1.lanes(p29) -- line: 374
    return {
        p29.x,
        p29.y,
        p29.z,
        0
    }
end

lanes = t1.lanes

function t1.xyz(p30) -- line: 379
    -- upvalues: Vector3 (copy)
    return Vector3.new(p30[1], p30[2], p30[3])
end

xyz = t1.xyz

return t1
