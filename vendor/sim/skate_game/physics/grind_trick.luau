-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local Vector3 = import("skate_core/math").Vector3
local BodyId = import("skate_core/physics/board").BodyId
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime
local v1 = import("skate_core/physics/board_motion_output")
local BoardForceQueue = import("skate_core/physics/force_queue").BoardForceQueue
local HookDriveState = import("skate_core/physics/hook_drive").HookDriveState
local v2 = import("skate_core/riding/braking")
local DRAG_FREQUENCY = import("skate_core/riding/grounded/drag").DRAG_FREQUENCY
local TruckSteeringState = import("skate_core/riding/steering").TruckSteeringState

local function riding_outputs() -- line: 21
    -- upvalues: import (copy)
    return import("skate_game/physics/riding_outputs")
end

local function ground_animation_skeleton() -- line: 24
    -- upvalues: import (copy)
    return import("skate_game/physics/ground_animation/skeleton")
end

local function ground_runtime() -- line: 27
    -- upvalues: import (copy)
    return import("skate_game/physics/ground_runtime")
end

local t1 = {
    GrindTrick = {}
}
local GrindTrick = t1.GrindTrick

function t1.GrindTrick.default() -- line: 45
    return {
        contact_free_frames = 0,
        released = false,
        velocity = { 0, 0, 0, 0 }
    }
end

function t1.GrindTrick.update_contact(p1, p2) -- line: 53
    -- upvalues: rt (copy)
    if not p1.released then
        if bit32.band(p2, 16384) == 0 then
            p1.contact_free_frames = rt.wrapping_add_u32(p1.contact_free_frames, 1)
        else
            p1.contact_free_frames = 0
        end

        p1.released = p1.contact_free_frames > 3
    end
end

function t1.GrindTrick.wipeout_scale(p3) -- line: 64
    if p3.released then
        return 0.5
    end

    return 2
end

function t1.enter(p4, p5) -- line: 69
    -- upvalues: BoardRuntime (copy), HookDriveState (copy), GrindTrick (copy)
    p5.grind_trick = GrindTrick.default()
    p5.ground_lifecycle.skeleton_elapsed_16505 = true
    p5.ground_lifecycle.board_animated_290 = HookDriveState.enable_angular_only(BoardRuntime.hook_mut(p4.board).drive, p5.ground_lifecycle.board_animated_290)

    if p5.wipeout.state.mode ~= 1 then
        p5.wipeout.state.mode = 1
        p5.wipeout.state.balance = 0
    end
end

function t1.exit(p6) -- line: 82
    -- upvalues: rt (copy), t1 (copy)
    t1.set_drag(p6, 0)
    p6.settings.wheel_material = rt.copy(p6.settings.standard_wheel_material)
end

function t1.set_drag(p7, p8) -- line: 87
    -- upvalues: BoardRuntime (copy), DRAG_FREQUENCY (copy)
    local v3 = BoardRuntime.bodies_mut(p7.board)

    for i = 1, #v3 do
        v3[i].inertia.linear_drag = p8 * DRAG_FREQUENCY
    end
end

function t1.rotate(p9, p10) -- line: 95
    return {
        p9[3][1] * p10[3] + (p9[2][1] * p10[2] + p9[1][1] * p10[1]),
        p9[3][2] * p10[3] + (p9[2][2] * p10[2] + p9[1][2] * p10[1]),
        p9[3][3] * p10[3] + (p9[2][3] * p10[2] + p9[1][3] * p10[1]),
        p9[3][4] * p10[3] + (p9[2][4] * p10[2] + p9[1][4] * p10[1])
    }
end

function t1.xyz(p11) -- line: 104
    -- upvalues: Vector3 (copy)
    return Vector3.new(p11[1], p11[2], p11[3])
end

function t1.normalize(p12) -- line: 108
    -- upvalues: rt (copy), v1 (copy), t1 (copy)
    local v4 = v1.length(t1.xyz(p12))

    if not (v4 > 9.999999974752427E-07) then
        return { 0, 0, 0, 0 }
    end

    return rt.map(p12, function(p13) -- line: 111
        -- upvalues: v4 (copy)
        return p13 / v4
    end)
end

function t1.advance(p14, p15) -- line: 120
    -- upvalues: rt (copy), import (copy), BoardRuntime (copy), BoardForceQueue (copy), v2 (copy), TruckSteeringState (copy), t1 (copy), GrindTrick (copy)
    local rotate, xyz, normalize = t1.rotate, t1.xyz, t1.normalize
    local processed = p15.player_input.processed

    GrindTrick.update_contact(p15.grind_trick, processed.flags_2468)

    local v5 = rt.copy(p15.animated_skeleton.motion.trajectory)

    p15.grind_trick.velocity = rotate(p15.animated_skeleton.roots.animation_to_world, rt.map(v5[4], function(p16) -- line: 127
        return p16 * 60
    end))

    local v6 = normalize(rotate(v5, p14.riding.reckoning_frames.heading))

    p14.riding.reckoning.dynamic_up = xyz(rt.map(processed.vectors_464_480_496_512_528[5], rt.from_bits))
    import("skate_game/physics/riding_outputs").RidingOutputs.update_ground_reckoning_with_heading(p14.riding, p14.board, {
        com_to_deck = xyz(rt.map(processed.animation_com_to_deck_752, rt.from_bits)),
        body_spin = p15.animation_input.extra.physical_body_spin
    }, processed.flags_2468, p15.animation_input.fields.balance, bit32.band(processed.flags_2476, 1073741824) ~= 0, processed, v6)
    import("skate_game/physics/ground_animation/skeleton").advance(p14, p15)
    p15.skeleton_output.correction.pending = true

    local processed2 = p15.player_input.processed
    local GroundSettings = import("skate_game/physics/ground_runtime").GroundSettings

    TruckSteeringState.update(p15.ground.steering, 0, GroundSettings.board(p15.ground_settings).steering.tilt_blending, processed2.flags_2468, processed2.flags_2472)
    p14.settings.wheel_material = rt.copy(p15.ground_settings.wheel_material)

    local toolkit = p15.player_input.toolkit

    if toolkit == nil then
        error("GrindTrick requires current BoardToolkit", 0)
    end

    local ground_normal = p14.riding.reckoning.ground_normal
    local v7 = v2.calculate_linear_drag({
        flags_2468 = processed2.flags_2468,
        absolute_body_speed = toolkit.absolute_speed,
        balance_2720 = p15.animation_input.fields.balance,
        scalar_2724 = p15.ground_lifecycle.manual_drag_2724,
        comparison_scalar = ground_normal.y
    }, rt.copy(GroundSettings.board(p15.ground_settings).linear_drag))
    local v8 = import("skate_game/physics/ground_runtime").GroundRuntime.calculate_collision_force(p15.ground_runtime, {
        flags_2472 = processed2.flags_2472,
        collision_displacement = rt.map(processed2.collision_pose_error_736, rt.from_bits),
        velocity = rt.map(processed2.vectors_400_416[2], rt.from_bits),
        forward = rt.copy(toolkit.travel_direction),
        up = rt.map(processed2.vectors_544_560_592_608[1], rt.from_bits),
        ground_normal = {
            ground_normal.x,
            ground_normal.y,
            ground_normal.z,
            0
        },
        time_step = processed2.timestep_2604,
        mass = toolkit.total_mass
    })

    if v8 ~= nil then
        BoardForceQueue.append(BoardRuntime.forces_mut(p14.board), {
            tag = 15,
            force_world = xyz(v8.force_2528),
            point_body = xyz(v8.point_2544)
        })
    else
        t1.set_drag(p14, v7)
    end
end

function t1.authored_velocity(p17, p18) -- line: 192
    -- upvalues: rt (copy), t1 (copy)
    local v9 = t1.normalize(p18)
    local v10 = v9[1] * p17[1] + v9[2] * p17[2] + v9[3] * p17[3]

    return rt.from_fn(4, function(p19) -- line: 197
        -- upvalues: p17 (copy), p18 (copy), v9 (copy), v10 (copy)
        local v11 = v9[p19 + 1] * v10

        return v11 * 0.10000002384185791 + (p18[p19 + 1] * 1.2599999451637274 + (p17[p19 + 1] - v11))
    end)
end

function t1.post_velocity(p20, p21) -- line: 203
    -- upvalues: BodyId (copy), BoardRuntime (copy), t1 (copy)
    if bit32.band(p21.player_input.processed.flags_2472, 32768) ~= 0 then
        return
    end

    local v12 = BoardRuntime.bodies_mut(p20.board)[BodyId.index(BodyId.Deck) + 1]
    local linear_velocity = v12.rates.linear_velocity

    v12.rates.linear_velocity = t1.xyz(t1.authored_velocity({
        linear_velocity.x,
        linear_velocity.y,
        linear_velocity.z,
        0
    }, p21.grind_trick.velocity))
end

return t1
