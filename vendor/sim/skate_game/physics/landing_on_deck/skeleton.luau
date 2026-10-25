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
local v2 = import("skate_core/physics/skeleton_animation_record")
local IDENTITY, compose_affine = v2.IDENTITY, v2.compose_affine
local v3 = import("skate_core/physics/skeleton_landing_on_board")
local SkeletonBoardFrames = import("skate_core/physics/skeleton_board_frames").SkeletonBoardFrames

local function input_phase() -- line: 23
    -- upvalues: import (copy)
    return import("skate_game/physics/input_phase")
end

local function skeleton_input_runtime() -- line: 26
    -- upvalues: import (copy)
    return import("skate_game/physics/skeleton_input_runtime")
end

local function skeleton_air() -- line: 29
    -- upvalues: import (copy)
    return import("skate_game/physics/skeleton_air")
end

local function animated_skeleton() -- line: 32
    -- upvalues: import (copy)
    return import("skate_game/physics/animated_skeleton")
end

local function biped_ground() -- line: 35
    -- upvalues: import (copy)
    return import("skate_game/physics/biped_ground")
end

return {
    update = function(p2, p3, p4) -- update | line: 43
        -- upvalues: rt (copy), v1 (copy), import (copy), IDENTITY (copy), compose_affine (copy), v3 (copy), SkeletonBoardFrames (copy)
        local processed, toolkit = p3.player_input.processed, p3.player_input.toolkit

        if toolkit == nil then
            error("Landing skeleton requires the completed board toolkit", 0)
        end

        local v4 = rt.copy(toolkit.deck)
        local animated_skeleton = p3.animated_skeleton
        local v5 = rt.copy(animated_skeleton.roots.animation_to_world)

        animated_skeleton.roots.initialize_heading = true

        local board_frames = animated_skeleton.board_frames
        local skate_root = v3.skate_root
        local v6 = rt.copy(v5)
        local v7 = rt.copy(p3.skeleton.record.centre_of_mass)
        local flags_2480 = processed.flags_2480

        buffer.writeu32(v1, 0, processed.vectors_880_896_912_928_944[1][2])
        board_frames.skate_root = skate_root(v6, v7, flags_2480, buffer.readf32(v1, 0), rt.copy(p3.landing_on_deck.root_settings))
        SkeletonBoardFrames.update_com_lift(animated_skeleton.board_frames, v5, rt.copy(animated_skeleton.board_frames.centre_of_mass), 0)
        animated_skeleton.motion.trajectory = rt.copy(IDENTITY)

        local packet = p3.animation.packet

        if #packet.hierarchy == 0 then
            error("Landing packet has no trajectory bone", 0)
        end

        rt.assign(packet.hierarchy[1], IDENTITY)

        if #packet["local"] == 0 then
            error("Landing packet has no local trajectory bone", 0)
        end

        rt.assign(packet["local"][1], IDENTITY)

        local v9 = if bit32.band(packet.flags, 268435456) == 0 then nil else rt.to_u32(packet.air_dismount_revert_frames)

        v3.update_root(animated_skeleton.roots, p4, rt.copy(animated_skeleton.record.centre_of_mass), p3.landing_on_deck.state.applied_spin, v9, bit32.band(processed.flags_2476, 4) ~= 0)

        local v11 = compose_affine(animated_skeleton.roots.animation_to_world, p3.skeleton_input.drive_frames[1])

        animated_skeleton.board_frames.animation_target = rt.copy(v11)
        processed.flags_2468 = bit32.bor(processed.flags_2468, 524288)

        if bit32.band(processed.flags_2480, 32768) ~= 0 then
            animated_skeleton.board_frames.physical_board = import("skate_game/physics/skeleton_air").SkeletonAir.apply_board(p3.skeleton_air, p2.board, v11, true)
        end

        local v12 = import("skate_game/physics/input_phase").collision(p3)
        local t2 = {
            animated = p3.animated_skeleton,
            body = p3.skeleton,
            drives = p3.skeleton_drives,
            ik = p3.foot_ik,
            animation_input = p3.animation_input,
            correction = p3.skeleton_output.correction,
            pose_errors = p3.pose_errors
        }

        import("skate_game/physics/skeleton_input_runtime").SkeletonInputRuntime.general_update(p3.skeleton_input, p3.player_input.processed, t2, p3.animation.packet.hierarchy, v12, rt.copy(p2.settings.step.simulation))
        import("skate_game/physics/biped_ground").Owner.finish_reckoning(p3.biped_ground, {
            blend = 0.5,
            up = rt.copy(t2.animated.roots.animation_to_world[2]),
            forward = rt.copy(v4[3])
        }, p2.riding, p3.air_reckoning, p3.player_input.processed, t2.animation_input.extra.physical_body_spin)
        import("skate_game/physics/animated_skeleton").AnimatedSkeleton.finish_ground(t2.animated)
        t2.animation_input.fields.flags2468 = p3.player_input.processed.flags_2468
    end
}
