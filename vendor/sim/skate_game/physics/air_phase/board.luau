-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/air/state")
local Vector3 = import("skate_core/math").Vector3
local BoardForceQueue = import("skate_core/physics/force_queue").BoardForceQueue
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime
local TruckSteeringState = import("skate_core/riding/steering").TruckSteeringState
local AirMath, calculate_velocity_from_jump = v1.AirMath, v1.calculate_velocity_from_jump

local function ground_runtime() -- line: 18
    -- upvalues: import (copy)
    return import("skate_game/physics/ground_runtime")
end

local t1 = {}

local function air_math_trait() -- line: 25
    -- upvalues: AirMath (copy)
    local t2 = {}

    return {
        minimum_vminfp = function(_, p2, p3) -- minimum_vminfp | line: 28
            -- upvalues: t2 (copy), AirMath (copy)
            return AirMath.minimum_vminfp(t2, p2, p3)
        end,
        length_squared_vmsum3fp = function(_, p5) -- length_squared_vmsum3fp | line: 31
            -- upvalues: t2 (copy), AirMath (copy)
            return AirMath.length_squared_vmsum3fp(t2, p5)
        end,
        length_vmsum3fp_vrsqrte = function(_, p7) -- length_vmsum3fp_vrsqrte | line: 34
            -- upvalues: t2 (copy), AirMath (copy)
            return AirMath.length_vmsum3fp_vrsqrte(t2, p7)
        end,
        clamp_vector_within_max_length = function(_, p9, p10) -- clamp_vector_within_max_length | line: 37
            -- upvalues: t2 (copy), AirMath (copy)
            return AirMath.clamp_vector_within_max_length(t2, p9, p10)
        end
    }
end

function t1.advance(p11, p12, p13) -- line: 44
    -- upvalues: rt (copy), import (copy), Vector3 (copy), BoardForceQueue (copy), BoardRuntime (copy), TruckSteeringState (copy), calculate_velocity_from_jump (copy), air_math_trait (copy)
    local processed = p12.player_input.processed

    TruckSteeringState.update(p12.ground.steering, 0, p12.air_settings.steering_blend, processed.flags_2468, processed.flags_2472)

    local toolkit = p12.player_input.toolkit

    if toolkit == nil then
        error("Air collision requires the actual BoardToolkit", 0)
    end

    local ground_normal = p11.riding.reckoning.ground_normal
    local GroundRuntime = import("skate_game/physics/ground_runtime").GroundRuntime
    local v2 = GroundRuntime.calculate_collision_force(p12.ground_runtime, {
        flags_2472 = processed.flags_2472,
        collision_displacement = rt.map(processed.collision_pose_error_736, rt.from_bits),
        velocity = rt.map(processed.vectors_400_416[2], rt.from_bits),
        forward = rt.copy(toolkit.travel_direction),
        up = rt.map(processed.vectors_544_560_592_608[1], rt.from_bits),
        ground_normal = {
            ground_normal.x,
            ground_normal.y,
            ground_normal.z,
            0
        },
        time_step = processed.timestep_2604,
        mass = toolkit.total_mass
    })

    if v2 ~= nil then
        local function xyz(p14) -- line: 70
            -- upvalues: Vector3 (copy)
            return Vector3.new(p14[1], p14[2], p14[3])
        end

        local append = BoardForceQueue.append
        local v4 = BoardRuntime.forces_mut(p11.board)
        local t4 = {
            tag = 15
        }
        local force_2528 = v2.force_2528

        t4.force_world = Vector3.new(force_2528[1], force_2528[2], force_2528[3])

        local point_2544 = v2.point_2544

        t4.point_body = Vector3.new(point_2544[1], point_2544[2], point_2544[3])
        append(v4, t4)
    elseif not p12.air_state.use_centre_of_mass_velocity and p13.frames_since_jump_correction_2576 < 12 then
        local v3 = calculate_velocity_from_jump(p13, p13.frames_since_jump_correction_2576, (air_math_trait()))

        GroundRuntime.set_animated_velocity(p12.ground_runtime, p11.board, v3)
    end
end

return t1
