-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local Vector3 = import("skate_core/math").Vector3
local v1 = import("skate_core/physics/board_runtime")
local v2 = import("skate_core/physics/force_queue")
local v3 = import("skate_core/physics/manual/controller")
local v4 = import("skate_core/player/slide_state")
local v5 = import("skate_core/riding/collision_response")
local v6 = import("skate_core/riding/ground_force")
local v7 = import("skate_core/riding/steering")
local BoardRuntime = v1.BoardRuntime
local BoardForceQueue = v2.BoardForceQueue
local angular_correction, sliding_force = v4.angular_correction, v4.sliding_force
local signed_angle = v5.signed_angle
local TruckSteeringState = v7.TruckSteeringState

local function air_phase() -- line: 26
    -- upvalues: import (copy)
    return import("skate_game/physics/air_phase")
end

local function air_trajectory() -- line: 29
    -- upvalues: import (copy)
    return import("skate_game/physics/air_trajectory")
end

local function ground_runtime() -- line: 32
    -- upvalues: import (copy)
    return import("skate_game/physics/ground_runtime")
end

local function skeleton_air() -- line: 35
    -- upvalues: import (copy)
    return import("skate_game/physics/skeleton_air")
end

local t1 = {}
local point_force, xyz, raw, fsel

local function debug_fmt(p1) -- line: 44
    -- upvalues: debug_fmt (copy)
    if type(p1) ~= "table" then
        return (tostring(p1))
    end

    if p1.tag == nil then
        local t2 = {}

        for v8, v9 in p1 do
            table.insert(t2, tostring(v8) .. ": " .. debug_fmt(v9))
        end

        table.sort(t2)

        return "{ " .. table.concat(t2, ", ") .. " }"
    end

    if p1[1] == nil then
        return (tostring(p1.tag))
    end

    return tostring(p1.tag) .. "(" .. debug_fmt(p1[1]) .. ")"
end

function t1.board(p2, p3) -- line: 63
    -- upvalues: rt (copy), import (copy), v3 (copy), v6 (copy), v7 (copy), BoardRuntime (copy), BoardForceQueue (copy), angular_correction (copy), sliding_force (copy), TruckSteeringState (copy), t1 (copy), point_force (ref), xyz (ref), raw (ref), fsel (ref), debug_fmt (copy)
    local v11 = rt.copy(p3.animated_skeleton.board_frames.animation_target)

    import("skate_game/physics/skeleton_air").SkeletonAir.capture_physics_error(p3.skeleton_air, p2.board, v11)

    local processed, toolkit = p3.player_input.processed, p3.player_input.toolkit

    if toolkit == nil then
        error("Slide requires current BoardToolkit", 0)
    end

    if processed.surface_mode_2540 < 1 then
        error("Slide requires the selected SurfacePhysics profile", 0)
    end

    local v12 = processed.surface_mode_2540 - 1
    local v13 = p3.slide_state.surfaces[v12 + 1]

    if v13 == nil then
        error(string.format("Invalid Slide surface mode %d", processed.surface_mode_2540), 0)
    end

    local v14 = v13[1]
    local v15 = v13[2]

    p2.settings.wheel_material = rt.copy(v15)

    local v16 = rt.copy(p3.ground_lifecycle.edge)
    local GroundSettings = import("skate_game/physics/ground_runtime").GroundSettings
    local v18 = GroundSettings.input(p3.ground_settings, toolkit, processed, p3.animation_input, p3.ground.pumping, import("skate_game/physics/ground_runtime").GroundPumping.mode(p3.ground.pumping_settings, processed.state_variant_index_2528).unintentional_scalar, p2.riding, p3.animated_skeleton, rt.copy(p2.settings.step.base_truck_transforms), {
        manual_drag_2724 = p3.ground_lifecycle.manual_drag_2724,
        trajectory_state_bits = processed.external_physics_1616.flags,
        edge_flags = if v16 == nil then 0 else v16.flags,
        edge_point = if v16 == nil then { 0, 0, 0, 0 } else v16.point
    })
    local v19 = GroundSettings.board(p3.ground_settings)
    local state = p3.slide_state.state
    local v20, v21, v22 = v7.calculate_tilt(v19.steering, v18.steering, state.steering_push, state.damped_turn)

    state.steering_push = v21
    state.damped_turn = v22
    TruckSteeringState.update(p3.ground.steering, v20, v19.steering.tilt_blending, processed.flags_2468, processed.flags_2472)
    v18.manual.powersliding = true

    local t5 = {}
    local t4 = {
        angle_between = function(_, p5, p6, p7) -- angle_between | line: 117
            -- upvalues: t5 (copy), t1 (copy)
            return t1.Angle.angle_between(t5, p5, p6, p7)
        end
    }
    local calculate = v3.calculate
    local manual = p3.ground.manual
    local manual2, manual_mode = v19.manual, v19.manual_mode
    local manual3 = v18.manual
    local ok, result = pcall(calculate, manual, manual2, manual_mode, manual3, t4)

    if not ok then
        error(string.format("Slide manual controller: %s", (debug_fmt(result))), 0)
    end

    local v23 = raw(processed.vectors_464_480_496_512_528[1])
    local v24 = raw(processed.vectors_544_560_592_608[1])
    local v25 = raw(processed.vectors_400_416[1])
    local v26 = rt.copy(v18.contact)

    v26.scalar_2756 = 0

    local GroundRuntime = import("skate_game/physics/ground_runtime").GroundRuntime
    local v27 = GroundRuntime.contact_response_with_previous(p3.ground_runtime, v26, {
        board_normal = v23,
        up = v24,
        velocity = v25,
        board_mass = toolkit.total_mass,
        gravity = processed.gravity_2648,
        speed = processed.scalar_2652,
        contact_count = rt.to_i32(processed.wheel_count_2556)
    }, { 0, 0, 0, 0 })

    state.wall_riding = v27.active_2731

    if v27.animated_board_2708 then
        GroundRuntime.set_animated_velocity(p3.ground_runtime, p2.board, rt.copy(v27.vector_2688))

        for _, v28 in ipairs(BoardRuntime.bodies_mut(p2.board)) do
            v28.inertia.linear_drag = 0
        end

        local v29 = import("skate_game/physics/air_phase").launch_info(p2, p3)

        v29.start_velocity = rt.copy(v27.vector_2688)
        v29.player_jumped = true

        local v30 = import("skate_game/physics/air_phase").selector_input(p2, p3)
        local AirTrajectoryRuntime = import("skate_game/physics/air_trajectory").AirTrajectoryRuntime

        AirTrajectoryRuntime.launch(p3.trajectory, v29, rt.copy(v30), p2.world)

        local toolkit = p3.player_input.toolkit

        if toolkit == nil then
            error("Slide trajectory requires current board toolkit", 0)
        end

        local v31 = import("skate_game/physics/air_trajectory").GrindContext.from_processed(p3.player_input.processed, rt.copy(toolkit.deck[4]))

        AirTrajectoryRuntime.update(p3.trajectory, v30, p2.world, v31)
    else
        local t6 = {
            velocity = v25,
            normal = v23,
            side = rt.copy(toolkit.deck[1]),
            effective_forward = rt.copy(toolkit.effective[3]),
            reference_forward = rt.copy(toolkit.forward),
            angular_velocity = raw(processed.vectors_720_784_800_816_832_864[1]),
            absolute_speed = toolkit.absolute_speed,
            surface_speed = processed.scalar_2656,
            slide = p3.animation_input.fields.slide,
            elapsed = processed.state_timer_2664,
            wheel_hardness = processed.scalar_2764
        }
        local v32 = angular_correction(p3.slide_state.settings, v14, rt.copy(t6))

        GroundRuntime.apply_angular_displacement(p3.ground_runtime, p2.board, v32)

        local manual_scalar = p3.slide_state.manual_scalar
        local v33 = rt.map(result.angular_displacement, function(p8) -- line: 181
            -- upvalues: manual_scalar (copy)
            return p8 * manual_scalar
        end)

        GroundRuntime.apply_angular_displacement(p3.ground_runtime, p2.board, v33)

        local ground_force = v18.ground_force
        local balance_2720 = ground_force.balance_2720
        local v34 = if balance_2720 > 0 then 0 else fsel(balance_2720, 1, 2)
        local v35 = fsel(balance_2720, if balance_2720 > 0 then 2 else 1, 0)
        local v36 = v6.calculate(v19.ground_force, {
            argument_3 = 0,
            argument_1 = ground_force.argument_1_2752,
            application_z = ground_force.ground_scalar_1216,
            argument_4 = v34,
            balance = balance_2720,
            surface_speed = ground_force.surface_speed_2656,
            axis_384 = rt.copy(ground_force.axis_384),
            velocity_400 = rt.copy(ground_force.velocity_400),
            axis_544 = rt.copy(ground_force.axis_544)
        })
        local v37 = v6.calculate(v19.ground_force, {
            argument_1 = ground_force.argument_1_2752,
            application_z = -ground_force.ground_scalar_1240,
            argument_3 = ground_force.ground_scalar_1236 * 0,
            argument_4 = v35,
            balance = balance_2720,
            surface_speed = ground_force.surface_speed_2656,
            axis_384 = rt.copy(ground_force.axis_384),
            velocity_400 = rt.copy(ground_force.velocity_400),
            axis_544 = rt.copy(ground_force.axis_544)
        })
        local v38 = sliding_force(p3.slide_state.settings, v14, t6)
        local ground_normal = p2.riding.reckoning.ground_normal
        local v39 = GroundRuntime.calculate_collision_force(p3.ground_runtime, {
            flags_2472 = processed.flags_2472,
            collision_displacement = raw(processed.collision_pose_error_736),
            velocity = raw(processed.vectors_400_416[2]),
            forward = rt.copy(toolkit.travel_direction),
            up = v24,
            ground_normal = {
                ground_normal.x,
                ground_normal.y,
                ground_normal.z,
                0
            },
            time_step = processed.timestep_2604,
            mass = toolkit.total_mass
        })
        local v40 = BoardRuntime.forces_mut(p2.board)

        if v39 ~= nil then
            BoardForceQueue.append(v40, {
                tag = 15,
                force_world = xyz(v39.force_2528),
                point_body = xyz(v39.point_2544)
            })
        else
            BoardForceQueue.append(v40, point_force(4, v36))
            BoardForceQueue.append(v40, point_force(5, v37))
            BoardForceQueue.append(v40, rt.copy(v27.tag_16_force))
            BoardForceQueue.append(v40, v38)
        end
    end
end

t1.Angle = {}

function t1.Angle.angle_between(_, p10, p11, p12) -- line: 250
    -- upvalues: signed_angle (copy), xyz (ref)
    return signed_angle(xyz(p10), xyz(p11), xyz(p12))
end

function point_force(p13, p14) -- line: 255
    -- upvalues: Vector3 (copy)
    return {
        tag = p13,
        force_world = Vector3.new(p14[1], p14[2], p14[3]),
        point_body = Vector3.new(p14[5], p14[6], p14[7])
    }
end

t1.point_force = point_force

function xyz(p15) -- line: 265
    -- upvalues: Vector3 (copy)
    return Vector3.new(p15[1], p15[2], p15[3])
end

t1.xyz = xyz

function raw(p16) -- line: 271
    -- upvalues: rt (copy)
    return rt.map(p16, rt.from_bits)
end

t1.raw = raw

function fsel(p17, p18, p19) -- line: 277
    if p17 >= -0 then
        return p18
    end

    return p19
end

t1.fsel = fsel

return t1
