-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local Vector3 = import("skate_core/math").Vector3
local IDENTITY = import("skate_core/physics/skeleton_animation_record").IDENTITY
local v1 = import("skate_core/player/input_phase/types")

local function input_phase() -- line: 13
    -- upvalues: import (copy)
    return import("skate_game/physics/input_phase")
end

local function player_input() -- line: 16
    -- upvalues: import (copy)
    return import("skate_game/physics/player_input")
end

local function ground_phase() -- line: 19
    -- upvalues: import (copy)
    return import("skate_game/physics/ground_phase")
end

local function ground_runtime() -- line: 22
    -- upvalues: import (copy)
    return import("skate_game/physics/ground_runtime")
end

local function skeleton_input_runtime() -- line: 25
    -- upvalues: import (copy)
    return import("skate_game/physics/skeleton_input_runtime")
end

local function skeleton_controller() -- line: 28
    -- upvalues: import (copy)
    return import("skate_game/physics/skeleton_controller")
end

local function skeleton_air() -- line: 31
    -- upvalues: import (copy)
    return import("skate_game/physics/skeleton_air")
end

local function footplant() -- line: 34
    -- upvalues: import (copy)
    return import("skate_game/physics/footplant")
end

local function handplant() -- line: 37
    -- upvalues: import (copy)
    return import("skate_game/physics/handplant")
end

local function riding_outputs() -- line: 40
    -- upvalues: import (copy)
    return import("skate_game/physics/riding_outputs")
end

local function grab_runtime() -- line: 43
    -- upvalues: import (copy)
    return import("skate_game/physics/biped_ground/grab_runtime")
end

local function board_runtime() -- line: 46
    -- upvalues: import (copy)
    return import("skate_core/physics/board_runtime")
end

local function ground_orientation() -- line: 49
    -- upvalues: import (copy)
    return import("skate_core/riding/ground_orientation")
end

local function wipeout_requests() -- line: 52
    -- upvalues: import (copy)
    return import("skate_core/player/wipeout")
end

local affine
local t1 = {}

t1.Callbacks = {}

function t1.Callbacks.reset_player(p1, p2, p3, p4, p5, p6, p7) -- line: 67
    -- upvalues: rt (copy), import (copy), Vector3 (copy), v1 (copy), t1 (copy), affine (ref)
    import("skate_game/physics/skeleton_controller").SkeletonControllerState.request_ground(p1.life.skeleton_controller, p1.collision_mode)

    local v2 = t1.match_board_stance(t1.horizontal_spawn(p4), p7.flags_2468)

    p5.flags_1296 = bit32.bor(bit32.band(bit32.band(p5.flags_1296, 4293918719), 2181038079), 1610612736)
    p5.previous_spin_input_1360 = 0
    p5.spin_same_direction_frames_1324 = 0
    p5.dismount_request_frames_1332 = 0
    p5.time_on_ground_1352 = 0
    p5.signed_ground_time_1356 = 0
    p5.queued_vector_1280 = { 0, 0, 0, 0 }
    p5.hips_line_test_1488 = v1.LineTestFields.default()
    p5.left_line_test_1536 = v1.LineTestFields.default()
    p5.right_line_test_1584 = v1.LineTestFields.default()
    import("skate_game/physics/player_input").reset_outputs(p6)
    import("skate_core/physics/board_runtime").BoardRuntime.reset_physical(p2, rt.copy(p1.settings.authored), affine(v2), p7.flags_2468, rt.copy(p1.settings.step.simulation.gravity_acceleration))
    p1.wiping_out = import("skate_game/physics/ground_phase").reset_board_state(p1.ground, p3, p1.life, p1.wiping_out)
    import("skate_game/physics/skeleton_air").SkeletonAir.reset_board(p1.skeleton_air)
    import("skate_game/physics/footplant").Footplant.full_reset(p1.footplant)
    import("skate_game/physics/handplant").Handplant.full_reset(p1.handplant)

    local RidingOutputs = import("skate_game/physics/riding_outputs").RidingOutputs

    RidingOutputs.reset_for_teleport(p1.riding)

    local SkeletonInputRuntime = import("skate_game/physics/skeleton_input_runtime").SkeletonInputRuntime
    local t2 = {
        animated = p1.animated,
        body = p1.body,
        drives = p1.drives,
        ik = p1.ik,
        animation_input = p1.animation_input,
        correction = p1.output.correction,
        pose_errors = p1.pose_errors
    }

    p1.life.skeleton_elapsed_16505 = SkeletonInputRuntime.reset_for_teleport(p1.skeleton_input, t2, p1.collision_mode, p1.feedback, p1.output.wobble, p1.life.skeleton_elapsed_16505)
    p1.collision.contact_4070 = p1.feedback.flags.compliant
    p1.collision.has_pose_error_4077 = p1.feedback.flags.has_impulse
    p1.collision.partial_ragdoll = p1.collision_mode.partial_ragdoll
    p1.collision.drive_weight_4028 = p1.feedback.drive_weight
    import("skate_core/riding/ground_orientation").GroundOrientation.reset(p1.riding.reckoning)
    RidingOutputs.update_ground_reckoning(p1.riding, p2, {
        com_to_deck = Vector3.new(p1.animated.record.com_to_deck_world[1], p1.animated.record.com_to_deck_world[2], p1.animated.record.com_to_deck_world[3]),
        body_spin = p1.animation_input.extra.physical_body_spin
    }, p7.flags_2468, p1.animation_input.fields.balance, false, p7)

    local Requests = import("skate_core/player/wipeout").Requests

    Requests.reset_systems(p1.wipeout.state)
    p1.life.skeleton_controller.effective = 0
    p1.life.skeleton_controller.requested = 0
    p1.life.skeleton_controller.has_request = false
    p1.life.skeleton_controller.override_enabled = false
    p1.life.skeleton_controller.flag_18 = false
    import("skate_game/physics/biped_ground/grab_runtime").Owner.invalidate(p1.offboard_grab)
    p5.manager_1856_counter_320 = 0
    p5.probe = v1.ProbeFields.default()

    local v5 = import("skate_game/physics/ground_runtime").GroundRuntime.prepare_toolkit(p3, p2, p7)
    local packet = p1.packet

    import("skate_game/physics/input_phase").Callbacks.process_skeleton(p1, p2, v5, packet, p6, p7)
    SkeletonInputRuntime.update_teleport(p1.skeleton_input, p2, p1.riding.reckoning_frames.system, p7, {
        animated = p1.animated,
        body = p1.body,
        drives = p1.drives,
        ik = p1.ik,
        animation_input = p1.animation_input,
        correction = p1.output.correction,
        pose_errors = p1.pose_errors
    }, p1.globals, p1.collision, p1.settings.step.simulation)
    Requests.teleport(p1.wipeout.state)
    p1.teleported = true
end

function t1.affine(p8) -- line: 183
    -- upvalues: Vector3 (copy)
    return {
        basis = {
            columns = {
                {
                    p8[1][1],
                    p8[1][2],
                    p8[1][3]
                },
                {
                    p8[2][1],
                    p8[2][2],
                    p8[2][3]
                },
                {
                    p8[3][1],
                    p8[3][2],
                    p8[3][3]
                }
            }
        },
        translation = Vector3.new(p8[4][1], p8[4][2], p8[4][3])
    }
end

affine = t1.affine
t1.SWITCH = 1048576
t1.MIN_HEADING = 0.0010000000474974513

local SWITCH, MIN_HEADING = t1.SWITCH, t1.MIN_HEADING

function t1.horizontal_spawn(p9) -- line: 206
    -- upvalues: rt (copy), IDENTITY (copy), MIN_HEADING (copy)
    local v6 = rt.copy(IDENTITY)
    local v7 = p9[3][1]
    local v8 = p9[3][3]
    local v10 = math.sqrt(v7 * v7 + v8 * v8)

    if v10 <= MIN_HEADING then
        v7 = -p9[1][3]
        v8 = p9[1][1]
        v10 = math.sqrt(v7 * v7 + v8 * v8)
    end

    if MIN_HEADING < v10 then
        v6[3] = {
            v7 / v10,
            0,
            v8 / v10,
            0
        }
        v6[1] = {
            v6[3][3],
            0,
            -v6[3][1],
            0
        }
        v6[2] = { 0, 1, 0, 0 }
    end

    v6[4] = rt.copy(p9[4])
    v6[4][2] += 0.1

    return v6
end

function t1.match_board_stance(p10, p11) -- line: 230
    -- upvalues: rt (copy), t1 (copy), SWITCH (copy)
    local v12 = rt.copy(p10)

    if bit32.band(p11, SWITCH) ~= 0 then
        t1.flip_heading(v12)
    end

    return v12
end

function t1.flip_heading(p12) -- line: 239
    for _, v13 in { 0, 2 } do
        local v14 = p12[v13 + 1]

        p12[v13 + 1] = {
            -v14[1],
            -v14[2],
            -v14[3],
            -v14[4]
        }
    end
end

function t1.facing_from_visual(p13, p14, p15, p16) -- line: 249
    -- upvalues: rt (copy), t1 (copy), SWITCH (copy)
    local v15 = rt.copy(p13)

    if not (if p16 then bit32.band(p14, SWITCH) == 0 else bit32.band(p15, 4) == 0) then
        t1.flip_heading(v15)
    end

    return v15
end

return t1
