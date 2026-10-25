-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local Vector3 = import("skate_core/math").Vector3
local BodyId = import("skate_core/physics/board").BodyId
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime
local target_velocity = import("skate_core/physics/board_animation").target_velocity
local update_plant_roots = import("skate_core/physics/skeleton_air_frames").update_plant_roots
local v1 = import("skate_core/physics/skeleton_animation_record")
local IDENTITY, compose_affine = v1.IDENTITY, v1.compose_affine
local SkeletonBoardFrames = import("skate_core/physics/skeleton_board_frames").SkeletonBoardFrames

local function input_phase() -- line: 20
    -- upvalues: import (copy)
    return import("skate_game/physics/input_phase")
end

local function skeleton_input_runtime() -- line: 23
    -- upvalues: import (copy)
    return import("skate_game/physics/skeleton_input_runtime")
end

local function skeleton_air() -- line: 26
    -- upvalues: import (copy)
    return import("skate_game/physics/skeleton_air")
end

local function animated_skeleton() -- line: 29
    -- upvalues: import (copy)
    return import("skate_game/physics/animated_skeleton")
end

return {
    advance = function(p1, p2, p3, p4) -- advance | line: 38
        -- upvalues: rt (copy), import (copy), Vector3 (copy), BodyId (copy), BoardRuntime (copy), target_velocity (copy), update_plant_roots (copy), IDENTITY (copy), compose_affine (copy), SkeletonBoardFrames (copy)
        local v2 = import("skate_game/physics/input_phase").collision(p2)
        local processed = p2.player_input.processed
        local animated_skeleton = p2.animated_skeleton
        local v3 = if p4 == nil then rt.copy(animated_skeleton.record.centre_of_mass) else rt.copy(p2.skeleton_input.drive_frames[p4 + 1][4])

        update_plant_roots(animated_skeleton.roots, p1.riding.reckoning_frames.system, p3, v3)
        animated_skeleton.motion.trajectory = rt.copy(IDENTITY)
        animated_skeleton.motion.inverse_trajectory = rt.copy(IDENTITY)

        local v4 = if p4 == nil then p2.skeleton_input.drive_frames[1] else animated_skeleton.record.pose[1]
        local v5 = compose_affine(animated_skeleton.roots.animation_to_world, v4)

        processed.flags_2468 = bit32.bor(processed.flags_2468, 524288)
        animated_skeleton.board_frames.animation_target = rt.copy(v5)

        local v6 = import("skate_game/physics/skeleton_air").SkeletonAir.apply_board(p2.skeleton_air, p1.board, v5, true)

        animated_skeleton.board_frames.physical_board = rt.copy(v6)
        animated_skeleton.board_frames.skate_root = rt.copy(v6)

        if p4 == nil then
            local position = BoardRuntime.bodies(p1.board)[BodyId.index(BodyId.Deck) + 1].rates.position
            local v7 = target_velocity(v6[4], {
                position.x,
                position.y,
                position.z,
                0
            }, processed.timestep_2604)

            for _, v8 in BoardRuntime.bodies_mut(p1.board) do
                v8.rates.linear_velocity = Vector3.new(v7[1], v7[2], v7[3])
            end
        end

        SkeletonBoardFrames.update_com_lift(animated_skeleton.board_frames, animated_skeleton.roots.animation_to_world, rt.copy(animated_skeleton.board_frames.centre_of_mass), 0)

        local t2 = {
            animated = animated_skeleton,
            body = p2.skeleton,
            drives = p2.skeleton_drives,
            ik = p2.foot_ik,
            animation_input = p2.animation_input,
            correction = p2.skeleton_output.correction,
            pose_errors = p2.pose_errors
        }

        import("skate_game/physics/skeleton_input_runtime").SkeletonInputRuntime.general_update(p2.skeleton_input, processed, t2, p2.animation.packet.hierarchy, v2, rt.copy(p1.settings.step.simulation))
        import("skate_game/physics/animated_skeleton").AnimatedSkeleton.finish_ground(t2.animated)
        t2.animation_input.fields.flags2468 = processed.flags_2468
    end,
    hold_foot = function(p5, p6, p7, p8) -- hold_foot | line: 99
        -- upvalues: rt (copy)
        local v9 = if p6 then 1 else 0

        p5.foot_ik.state.external_targets[v9 + 1].world_position = rt.copy(p7)
        p5.foot_ik.state.limbs[v9 + 1].external_target_set = true
        p5.foot_ik.state.limbs[v9 + 1].target_blend = 1

        if p8 ~= 0 then
            local t3 = if p6 then { 19, 20, 21 } else { 15, 16, 17 }

            for _, v10 in t3 do
                p5.skeleton_collision.pending_reenable = true
                p5.skeleton_collision.disable_count[v10 + 1] = p8
                p5.skeleton_collision.parts[v10 + 1].enabled = false
            end
        end
    end
}
