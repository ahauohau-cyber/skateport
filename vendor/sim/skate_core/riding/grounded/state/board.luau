-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/riding/speed_wobble")
local v2 = import("skate_core/riding/steering")
local TruckSteeringState = v2.TruckSteeringState
local BoardForceQueue = import("skate_core/physics/force_queue").BoardForceQueue
local BodyInertias = import("skate_core/riding/grounded/drag").BodyInertias
local CollisionForceResponse = import("skate_core/riding/grounded/state/board_types").CollisionForceResponse
local v3 = import("skate_core/riding/grounded/state/ordinary")
local animated, service
local t1 = {}

t1.GroundBoardOutcome = {}

local function finish_drag(p1, ...) -- line: 32
    if p1 then
        return ...
    end

    error({
        tag = "Drag",
        (...)
    }, 0)

    return ...
end

function t1.update(p2, p3, p4, p5, p6) -- line: 43
    -- upvalues: rt (copy), v1 (copy), v2 (copy), TruckSteeringState (copy), BoardForceQueue (copy), CollisionForceResponse (copy), v3 (copy), animated (ref), service (ref)
    local v4, v5, v6 = v2.calculate_tilt(p4.steering, p5.steering, p2.steering_push_scalar_2640, p2.steering_damped_turn_2644)

    p2.steering_push_scalar_2640 = v5
    p2.steering_damped_turn_2644 = v6
    p5.speed_wobble.tilt = v4
    p5.speed_wobble.center_of_mass_height = service("CenterOfMassHeight", p6.center_of_mass_height_82d38838, p6)

    local v7 = v1.calculate(p3.speed_wobble, p4.speed_wobble, p5.speed_wobble)

    TruckSteeringState.update(p3.truck_steering, v7, p4.steering.tilt_blending, p5.truck_flags_2468, p5.truck_flags_2472)
    service("SetWheelMaterials", p6.set_contact_wheel_materials, p6)

    local v8 = service("ContactResponse", p6.contact_response_82d93df0, p6, p5.contact, rt.copy(p2.vector_2688))

    p2.flag_2731 = v8.active_2731
    p2.vector_2688 = rt.copy(v8.vector_2688)
    p2.scalar_2704 = v8.scalar_2704
    p2.flag_2708 = v8.animated_board_2708
    p2.flag_2720 = false
    service("UpdateBodyAccumulator", p6.update_body_accumulator_82d389dc, p6)

    if p2.flag_2708 then
        return animated(p2, p3, p6)
    end

    local v9 = service("CollisionForce", p6.collision_force_82d944e8, p6, rt.copy(p5.ground_vector_1216))

    if v9 == nil then
        return {
            tag = "Ordinary",
            (v3.update(p2, p3, p4, p5, rt.copy(v8.tag_16_force), p6))
        }
    end

    p2.collision_force_2528 = rt.copy(v9.force_2528)
    p2.collision_point_2544 = rt.copy(v9.point_2544)
    p2.vector_2592 = rt.copy(v9.vector_2592)
    p2.collision_countdown_2652 = p4.collision_response_duration
    service("ApplyCollisionVector", p6.apply_vector_82c07000, p6, rt.copy(v9.vector_2592))
    p3.speed_model.flags_1360 = bit32.bor(p3.speed_model.flags_1360, 2147483648)

    local v10 = BoardForceQueue.append(p3.force_queue, CollisionForceResponse.tagged_force(v9))

    p2.flag_2722 = service("CollisionProjection", p6.collision_force_dot_velocity_82d38e18, p6, rt.copy(v9.force_2528), rt.copy(p5.ground_force.velocity_400)) < -0.75

    return {
        tag = "Collision",
        tag_15_queued = v10
    }
end

function animated(p7, p8, p9) -- line: 107
    -- upvalues: rt (copy), BodyInertias (copy), service (ref), finish_drag (copy)
    service("SetAnimatedVelocity", p9.set_animated_velocity_82c04168, p9, rt.copy(p7.vector_2688))
    service("WriteProcessedVelocity", p9.write_processed_velocity_400, p9, rt.copy(p7.vector_2688))

    local set_linear_drag = BodyInertias.set_linear_drag
    local inertias = p8.inertias
    local t3 = {
        tag = "AllParts"
    }

    finish_drag(pcall(set_linear_drag, inertias, 0, t3))

    local v11 = service("BuildAnimatedPose", p9.build_animated_pose_82d33448, p9)

    service("PublishAnimatedPose", p9.publish_animated_pose_82be33d0, p9, v11)
    service("UpdateExternalPlayer", p9.update_external_player_82d67848, p9, v11, rt.copy(p7.vector_2688))
    service("CommitExternalPlayer", p9.commit_external_player_82d68800, p9)
    service("FinalizeAnimatedBoard", p9.finalize_animated_board_sk83_na_f_01a4, p9)
    p7.flag_2720 = true

    return {
        tag = "Animated"
    }
end

t1.animated = animated

local function finish_service(p10, p11, ...) -- line: 128
    if p11 then
        return ...
    end

    error({
        tag = "Service",
        stage = p10,
        source = ...
    }, 0)

    return ...
end

function service(p12, p13, ...) -- line: 139
    -- upvalues: finish_service (copy)
    return finish_service(p12, pcall(p13, ...))
end

t1.service = service

return t1
