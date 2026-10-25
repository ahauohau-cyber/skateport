-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/physics/wipeout")
local v2 = import("skate_game/physics/solve")
local v3 = import("skate_core/air/trajectory")
local v4 = import("skate_core/player/state")
local Observations = v1.Observations
local TrajectorySelector = v3.TrajectorySelector
local PhysicalStateId = v4.PhysicalStateId

local function biped_air() -- line: 20
    -- upvalues: import (copy)
    return import("skate_game/physics/biped_air")
end

local function biped_ground() -- line: 23
    -- upvalues: import (copy)
    return import("skate_game/physics/biped_ground")
end

local function landing_on_deck() -- line: 26
    -- upvalues: import (copy)
    return import("skate_game/physics/landing_on_deck")
end

local function player_state() -- line: 29
    -- upvalues: import (copy)
    return import("skate_game/physics/player_state")
end

return {
    advance = function(p1, p2) -- advance | line: 36
        -- upvalues: rt (copy), import (copy), v2 (copy), Observations (copy), TrajectorySelector (copy), PhysicalStateId (copy)
        local v5 = import("skate_game/physics/player_state").PlayerState.current(p2.player_state)

        if v5 ~= PhysicalStateId.BipedGround and v5 ~= PhysicalStateId.OffBoardPushing and v5 ~= PhysicalStateId.BipedAir and v5 ~= PhysicalStateId.LandingOnDeck then
            return
        end

        local v6 = Observations.frame({
            processed = p2.player_input.processed,
            board = p1.riding.ground,
            collision = p2.collision_feedback,
            deck = v2.deck_frame(p1.board),
            input_board = rt.copy(p2.animated_skeleton.board_frames.animation_target),
            world_to_animation = rt.copy(p2.animated_skeleton.roots.world_to_animation),
            pose_error = rt.copy(p2.collision_pose_error),
            maximum_pose_error = p2.collision_maximum_error,
            jump_fix_frames = p2.player_state.post.jump_fix_frames,
            air = p2.air_reckoning.state,
            system_up_y = p1.riding.reckoning_frames.system[2][2],
            grind_locked_to_middle = TrajectorySelector.grind_locked_to_middle(p2.trajectory.selector),
            grind_normal = TrajectorySelector.grind_normal(p2.trajectory.selector)
        })

        if v5 == PhysicalStateId.LandingOnDeck then
            return import("skate_game/physics/landing_on_deck").post(p2, v6)
        end

        if v5 == PhysicalStateId.BipedAir then
            return import("skate_game/physics/biped_air").post(p2, v6)
        end

        if v5 == PhysicalStateId.BipedGround or v5 == PhysicalStateId.OffBoardPushing then
            local t2 = {
                shared = v6,
                skeleton_velocity_16336 = rt.copy(p2.skeleton_input.root_velocity),
                contact_flag_4072 = p2.collision_feedback.flags.group_8,
                contact_force_4056 = p2.collision_feedback.maximum_group_8_force
            }

            import("skate_game/physics/biped_ground").post(p2, t2)
        else
            error("internal error: entered unreachable code: offboard state checked before borrowing its observations", 0)
        end
    end
}
