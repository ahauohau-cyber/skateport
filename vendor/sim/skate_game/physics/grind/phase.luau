-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/physics/grind/lifecycle")
local v2 = import("skate_game/physics/grind/post")
local State = import("skate_game/physics/grind/state").State
local v3 = import("skate_game/physics/grind/wipeout_output")
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime
local HookDriveState = import("skate_core/physics/hook_drive").HookDriveState
local TrajectorySelector = import("skate_core/air/trajectory").TrajectorySelector

local function grind() -- line: 17
    -- upvalues: import (copy)
    return import("skate_game/physics/grind")
end

local function player_state() -- line: 21
    -- upvalues: import (copy)
    return import("skate_game/physics/player_state")
end

local function solve() -- line: 24
    -- upvalues: import (copy)
    return import("skate_game/physics/solve")
end

return {
    enter = function(p1, p2) -- enter | line: 33
        -- upvalues: rt (copy), import (copy), v1 (copy), State (copy), BoardRuntime (copy), HookDriveState (copy)
        local PlayerState = import("skate_game/physics/player_state").PlayerState

        if PlayerState.current(p2.player_state) == 701 then
            p2.grind.nonspecific_active = true
            p2.grind.nonspecific_jumped = false
            p2.grind.nonspecific_jump_velocity = { 0, 0, 0, 0 }
            p2.ground_lifecycle.skeleton_elapsed_16505 = true
            p2.air_reckoning.state.spin_angle = 0
            p2.air_reckoning.state.spin_speed = 0
            p2.ground_lifecycle.board_animated_290 = HookDriveState.disable_animation(BoardRuntime.hook_mut(p1.board).drive, p2.ground_lifecycle.board_animated_290)
        else
            local v4 = import("skate_game/physics/grind").Family.from_physical_state(PlayerState.current(p2.player_state))

            if v4 == nil then
                error("Grind Enter requires selected state400..405", 0)
            end

            if p2.grind.active ~= nil then
                error("Grind Enter requires prior Exit", 0)
            end

            if p2.player_input.toolkit == nil then
                error("Grind Enter requires current board toolkit", 0)
            end

            local v5 = rt.copy(p2.player_input.toolkit.deck)
            local ground_lifecycle, ground_lifecycle2 = p2.ground_lifecycle, p2.ground_lifecycle
            local v6, v7 = v1.enter(p1.board, p2.ground_lifecycle.board_animated_290, p2.ground_lifecycle.skeleton_elapsed_16505, p2.skeleton_collision)

            ground_lifecycle.board_animated_290 = v6
            ground_lifecycle2.skeleton_elapsed_16505 = v7
            State.enter(p2.grind.states[v4 + 1], v4, v5)
            p2.grind.active = v4
        end
    end,
    exit = function(p3, p4) -- exit | line: 71
        -- upvalues: rt (copy), v1 (copy)
        if p4.grind.nonspecific_active then
            p4.grind.nonspecific_active = false
        else
            local active = p4.grind.active

            if active == nil then
                error("Grind Exit requires active physical state", 0)
            end

            local v8 = rt.map({
                19, 15, 20, 16
            }, function(p5) -- line: 81
                -- upvalues: p4 (copy)
                return p4.skeleton.definition.bones[p5 + 1].has_collision
            end)

            p4.ground_lifecycle.board_animated_290 = v1.exit(p3.board, p4.ground_lifecycle.board_animated_290, p4.skeleton_collision, v8, p4.grind.settings.standard_angular_drag)
            p4.grind.states[active + 1].output.leaving = false
            p4.grind.active = nil
        end
    end,
    fill = function(_, p7) -- fill | line: 99
        -- upvalues: rt (copy), import (copy), v3 (copy)
        if p7.grind.nonspecific_active then
            if p7.grind.nonspecific_jumped then
                p7.player_input.physical.air.launch_velocity_128 = rt.map(p7.grind.nonspecific_jump_velocity, rt.to_bits)
                p7.player_input.physical.air.launched_442 = 1
            end
        else
            if p7.grind.manager == nil then
                error("Grind Fill requires completed manager observation", 0)
            end

            local v9 = rt.copy(p7.grind.manager)
            local v10 = import("skate_game/physics/grind").Runtime.fill_physical(p7.grind, v9, p7.player_input.physical.grinds)

            if v10 == nil then
                error("Grind Fill requires active state", 0)
            end

            local air_jump_velocity_128 = v10.air_jump_velocity_128

            if air_jump_velocity_128 ~= nil then
                p7.player_input.physical.air.launch_velocity_128 = rt.map(air_jump_velocity_128, rt.to_bits)
                p7.player_input.physical.air.launched_442 = 1
            end

            p7.grind.pending_wipeout_impulse = v10.wipeout_impulse_16
            v3.publish(p7)
        end
    end,
    post = function(p8, p9) -- post | line: 127
        -- upvalues: rt (copy), import (copy), v2 (copy), TrajectorySelector (copy)
        local t2 = {
            processed = p9.player_input.processed,
            board = p8.riding.ground,
            collision = p9.collision_feedback,
            deck = import("skate_game/physics/solve").deck_frame(p8.board),
            input_board = rt.copy(p9.animated_skeleton.board_frames.animation_target),
            world_to_animation = rt.copy(p9.animated_skeleton.roots.world_to_animation),
            pose_error = rt.copy(p9.collision_pose_error),
            maximum_pose_error = p9.collision_maximum_error,
            jump_fix_frames = p9.player_state.post.jump_fix_frames,
            air = p9.air_reckoning.state,
            system_up_y = p8.riding.reckoning_frames.system[2][2],
            grind_locked_to_middle = TrajectorySelector.grind_locked_to_middle(p9.trajectory.selector),
            grind_normal = TrajectorySelector.grind_normal(p9.trajectory.selector)
        }

        return v2.check(p9.wipeout.state, rt.copy(p9.grind.settings.post), t2)
    end
}
