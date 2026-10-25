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
local v2 = import("skate_game/physics/air_phase")
local v3 = import("skate_game/physics/air_trajectory")
local AirTrajectoryRuntime, GrindContext = v3.AirTrajectoryRuntime, v3.GrindContext
local v4 = import("skate_game/physics/ground_runtime")
local GroundRuntime, GroundSettings = v4.GroundRuntime, v4.GroundSettings
local v5 = import("skate_core/air/ground_jump")
local TrajectorySelector = import("skate_core/air/trajectory").TrajectorySelector
local Vector3 = import("skate_core/math").Vector3
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime
local BoardForceQueue = import("skate_core/physics/force_queue").BoardForceQueue
local v6 = import("skate_core/riding/braking")
local v7 = import("skate_core/riding/ground_force")
local DRAG_FREQUENCY = import("skate_core/riding/grounded/drag").DRAG_FREQUENCY
local v8 = import("skate_core/riding/slide_friction")
local TruckSteeringState = import("skate_core/riding/steering").TruckSteeringState
local t1 = {
    NATE_POP = nil,
    NATE_POP_DEFAULT = {
        floor = 4.2,
        keep = 4,
        most = 2.5
    }
}
local point_force, xyz

local function from_bits4(p2) -- line: 52
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p2[1])

    local v10 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p2[2])

    local v12 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p2[3])

    local v14 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, p2[4])

    return {
        v10,
        v12,
        v14,
        (buffer.readf32(v1, 0))
    }
end

function t1.set_drag(p3, p4) -- line: 56
    -- upvalues: BoardRuntime (copy), DRAG_FREQUENCY (copy)
    local v16 = BoardRuntime.bodies_mut(p3.board)

    for i = 1, #v16 do
        v16[i].inertia.linear_drag = p4 * DRAG_FREQUENCY
    end
end

function t1.advance(p5, p6) -- line: 65
    -- upvalues: rt (copy), v2 (copy), AirTrajectoryRuntime (copy), GrindContext (copy), GroundRuntime (copy), GroundSettings (copy), v5 (copy), TrajectorySelector (copy), BoardRuntime (copy), BoardForceQueue (copy), v6 (copy), v7 (copy), v8 (copy), TruckSteeringState (copy), t1 (copy), point_force (ref), xyz (ref), from_bits4 (copy)
    local processed, toolkit = p6.player_input.processed, p6.player_input.toolkit

    if toolkit == nil then
        error("GroundAnimation requires current BoardToolkit", 0)
    end

    local ground_settings = p6.ground_settings

    TruckSteeringState.update(p6.ground.steering, 0, GroundSettings.board(ground_settings).steering.tilt_blending, processed.flags_2468, processed.flags_2472)
    p5.settings.wheel_material = rt.copy(ground_settings.wheel_material)

    local v17 = p6.ground_animation_settings.modes[processed.state_variant_index_2528 + 1]

    if v17 == nil then
        error(string.format("Invalid GroundAnimation physics mode %d", processed.state_variant_index_2528), 0)
    end

    local v18 = rt.copy(v17)

    p6.ground_animation.jump = v5.calculate({
        flags_2468 = processed.flags_2468,
        flags_2480 = processed.flags_2480,
        flags_2484 = processed.flags_2484,
        flags_2488 = processed.flags_2488,
        effective_forward = rt.copy(toolkit.effective[3]),
        forward = rt.copy(toolkit.forward),
        current_velocity = from_bits4(processed.vectors_400_416[1]),
        ground_reference_position = from_bits4(processed.vectors_464_480_496_512_528[2]),
        reference_up = from_bits4(processed.vectors_544_560_592_608[1]),
        filtered_ground_normal = rt.copy(toolkit.filtered_normal),
        animation_com_position = from_bits4(processed.vectors_544_560_592_608[3]),
        prepared_velocity = from_bits4(processed.prepared_jump_704),
        jump_strength = p6.animation_input.extra.jump_strength,
        jump_controls = p6.animation_input.extra.jump_controls,
        gravity_y = processed.gravity_2648,
        surface_speed = processed.scalar_2656
    }, v18, p6.ground_animation_settings.jump)

    if p6.ground_animation.jump.active then
        local v19 = rt.copy(p6.ground_animation.jump.velocity)
        local NATE_POP = t1.NATE_POP

        if NATE_POP ~= nil then
            local v20 = from_bits4(processed.vectors_400_416[1])
            local filtered_normal = toolkit.filtered_normal
            local v23 = math.min(v20[2], v20[1] * filtered_normal[1] + v20[2] * filtered_normal[2] + v20[3] * filtered_normal[3]) / (NATE_POP.length or 1) - NATE_POP.floor

            if v23 > 0 then
                v19[2] = v19[2] + math.min(v23 * NATE_POP.keep, NATE_POP.most)
            end
        end

        GroundRuntime.set_animated_velocity(p6.ground_runtime, p5.board, v19)
        p6.ground_animation.launched = true
        t1.set_drag(p5, 0)

        local v26 = v2.launch_info(p5, p6)

        v26.start_velocity = rt.copy(v19)
        v26.player_jumped = true

        local v27 = v2.selector_input(p5, p6)

        AirTrajectoryRuntime.launch(p6.trajectory, v26, rt.copy(v27), p5.world)

        local toolkit2 = p6.player_input.toolkit

        if toolkit2 == nil then
            error("Jump trajectory requires current board toolkit", 0)
        end

        local v28 = GrindContext.from_processed(p6.player_input.processed, rt.copy(toolkit2.deck[4]))

        AirTrajectoryRuntime.update(p6.trajectory, v27, p5.world, v28)

        local v29 = TrajectorySelector.launch_info(p6.trajectory.selector)

        if v29 == nil then
            error("GroundAnimation launch has no retained trajectory packet", 0)
        end

        p6.ground_animation.launch_velocity = rt.copy(v29.start_velocity)
    else
        local v30 = GroundSettings.board(ground_settings)
        local balance = p6.animation_input.fields.balance
        local v31 = if not (balance <= 0) then 0 elseif balance >= -0 then 1 else 2
        local v32 = if not (balance >= -0) then 0 elseif balance <= 0 then 1 else 2

        local function foot(p7, p8, p9) -- line: 156
            -- upvalues: processed (copy), toolkit (copy), v30 (copy), balance (copy), rt (copy), v7 (copy), from_bits4 (copy)
            return v7.calculate(v30.ground_force, {
                argument_1 = 1,
                application_z = p7,
                argument_3 = p8,
                argument_4 = p9,
                balance = balance,
                surface_speed = processed.scalar_2656,
                axis_384 = rt.copy(toolkit.transverse_up),
                velocity_400 = from_bits4(processed.vectors_400_416[1]),
                axis_544 = from_bits4(processed.vectors_544_560_592_608[1])
            })
        end

        local v33 = foot(ground_settings.foot_force_offset, 0, v31)
        local v34 = foot(-ground_settings.foot_force_offset, ground_settings.absorption_rear * 0, v32)
        local v35 = v6.calculate_braking({
            flags_2468 = processed.flags_2468,
            input_2728 = p6.animation_input.fields.brake,
            signed_speed = processed.scalar_2612,
            absolute_body_speed = toolkit.absolute_speed,
            surface_factor = ground_settings.surface_braking_factor,
            direction = xyz(toolkit.horizontal_forward)
        }, rt.copy(v30.propulsion.braking))
        local v36 = v8.calculate(v30.slide_friction, {
            heading_time = processed.state_timer_2664,
            normal = from_bits4(processed.vectors_464_480_496_512_528[1]),
            velocity = from_bits4(processed.vectors_400_416[1]),
            side_axis = rt.copy(toolkit.deck[1]),
            surface_speed = processed.scalar_2656,
            scalar_2764 = processed.scalar_2764
        })
        local v37 = rt.copy(p5.riding.reckoning.ground_normal)
        local v38 = v6.calculate_linear_drag({
            flags_2468 = processed.flags_2468,
            absolute_body_speed = toolkit.absolute_speed,
            balance_2720 = balance,
            scalar_2724 = p6.ground_lifecycle.manual_drag_2724,
            comparison_scalar = v37.y
        }, rt.copy(v30.linear_drag))
        local v39 = GroundRuntime.calculate_collision_force(p6.ground_runtime, {
            flags_2472 = processed.flags_2472,
            collision_displacement = from_bits4(processed.collision_pose_error_736),
            velocity = from_bits4(processed.vectors_400_416[2]),
            forward = rt.copy(toolkit.travel_direction),
            up = from_bits4(processed.vectors_544_560_592_608[1]),
            ground_normal = {
                v37.x,
                v37.y,
                v37.z,
                0
            },
            time_step = processed.timestep_2604,
            mass = toolkit.total_mass
        })

        if v39 ~= nil then
            BoardForceQueue.append(BoardRuntime.forces_mut(p5.board), {
                tag = 15,
                force_world = xyz(v39.force_2528),
                point_body = xyz(v39.point_2544)
            })
        else
            BoardForceQueue.append(BoardRuntime.forces_mut(p5.board), point_force(4, v33))
            BoardForceQueue.append(BoardRuntime.forces_mut(p5.board), point_force(5, v34))
            BoardForceQueue.append(BoardRuntime.forces_mut(p5.board), point_force(1, v36))
            BoardForceQueue.append(BoardRuntime.forces_mut(p5.board), v35)
            t1.set_drag(p5, v38)
        end
    end
end

function point_force(p10, p11) -- line: 223
    -- upvalues: Vector3 (copy)
    return {
        tag = p10,
        force_world = Vector3.new(p11[1], p11[2], p11[3]),
        point_body = Vector3.new(p11[5], p11[6], p11[7])
    }
end

t1.point_force = point_force

function xyz(p12) -- line: 232
    -- upvalues: Vector3 (copy)
    return Vector3.new(p12[1], p12[2], p12[3])
end

t1.xyz = xyz

return t1
