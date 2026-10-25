-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/physics/wipeout_states/prediction")
local v2 = import("skate_game/physics/wipeout_states/ragdoll")
local v3 = import("skate_core/animation/foot_ik/state")
local Vector3 = import("skate_core/math").Vector3
local v4 = import("skate_core/physics/board")
local v5 = import("skate_core/physics/board_runtime")
local v6 = import("skate_core/physics/hook_drive")
local v7 = import("skate_core/physics/skeleton_body")
local v8 = import("skate_core/player/wipeout_state")
local v9 = import("skate_core/player/wipeout_state/body")
local v10 = import("skate_core/player/wipeout_state/contact_response")
local v11 = import("skate_core/player/wipeout_state/drives")
local v12 = import("skate_core/player/wipeout_state/math")
local Prediction = v1.Prediction
local RagdollSetup = v2.RagdollSetup
local FootIkState = v3.FootIkState
local BodyId = v4.BodyId
local BoardRuntime = v5.BoardRuntime
local HookDriveState = v6.HookDriveState
local SkeletonBody = v7.SkeletonBody
local State = v8.State
local ContactResponse = v10.ContactResponse

return {
    enter = function(p1, p2) -- enter | line: 37
        -- upvalues: rt (copy), Vector3 (copy), v9 (copy), v11 (copy), v12 (copy), Prediction (copy), RagdollSetup (copy), FootIkState (copy), BodyId (copy), BoardRuntime (copy), HookDriveState (copy), SkeletonBody (copy), State (copy), ContactResponse (copy)
        p2.ground_lifecycle.skeleton_elapsed_16505 = false

        local wipeout_state = p2.wipeout_state

        wipeout_state.state = State.default()
        ContactResponse.reset(wipeout_state.contact)
        Prediction.reset(wipeout_state.prediction)
        p1.board_wiping_out = true
        BoardRuntime.set_collision_group(p1.board, 7)
        BoardRuntime.bodies_mut(p1.board)[BodyId.index(BodyId.Deck) + 1].inertia.angular_drag = 0

        local t2 = {
            static_friction = wipeout_state.settings.board_friction,
            dynamic_friction = wipeout_state.settings.board_friction,
            restitution = wipeout_state.settings.board_restitution
        }

        p1.settings.wheel_material = rt.copy(t2)
        p1.settings.truck_material = rt.copy(t2)
        p1.settings.deck_material = rt.copy(t2)
        p2.ground.steering.targets = { 0, 0 }

        local drive = BoardRuntime.hook_mut(p1.board).drive

        HookDriveState.disable_angular(drive)
        HookDriveState.disable_linear(drive)

        for _, v13 in ipairs(p2.foot_ik.state.limbs) do
            v13.board_blend = 0
            v13.external_blend = 0
            v13.mode = "Disabled"
        end

        FootIkState.enable_feet(p2.foot_ik.state, false)
        v11.set_angular_root(p2.skeleton_drives, wipeout_state.drives, 0.5)
        v11.set_linear_root(p2.skeleton_drives, wipeout_state.drives, 0)

        local processed = p2.player_input.processed

        if bit32.band(processed.flags_2488, 2097152) ~= 0 then
            v9.blend_velocity(p2.skeleton, rt.map(processed.vectors_880_896_912_928_944[5], rt.from_bits))
        end

        if p2.wipeout.state.reasons[7] then
            local v14 = rt.map(processed.vectors_544_560_592_608[1], rt.from_bits)

            v9.remove_normal_velocity(p2.skeleton, v14)

            for _, v15 in ipairs(BoardRuntime.bodies_mut(p1.board)) do
                local linear_velocity = v15.rates.linear_velocity
                local v16 = v12.sub({
                    linear_velocity.x,
                    linear_velocity.y,
                    linear_velocity.z,
                    0
                }, v12.scale(v14, v12.dot(v14, {
                    linear_velocity.x,
                    linear_velocity.y,
                    linear_velocity.z,
                    0
                })))

                v15.rates.linear_velocity = Vector3.new(v16[1], v16[2], v16[3])
            end

            BoardRuntime.bodies_mut(p1.board)[BodyId.index(BodyId.Deck) + 1].rates.angular_velocity = rt.copy(Vector3.ZERO)
        end

        v9.limit_velocity(p2.skeleton, 20)

        if bit32.band(processed.flags_2468, 4) ~= 0 then
            SkeletonBody.apply_part_displacement(p2.skeleton, 12, v12.scale(rt.map(processed.vector_1520, rt.from_bits), wipeout_state.settings.push_force))
        end

        if processed.probe_1792.byte_104 ~= 0 then
            v9.add_velocity(p2.skeleton, rt.map(processed.probe_1792.vector_80, rt.from_bits))
        end

        wipeout_state.state.special_surface = bit32.band(processed.flags_2488, 1073741824) ~= 0
        wipeout_state.state.surface_height = processed.collision_scalar_2924
        RagdollSetup.request(wipeout_state.ragdoll, p2.ground_lifecycle.skeleton_controller, wipeout_state.state.special_surface and 10 or 8, p2.skeleton, p2.skeleton_joints, p2.skeleton_collision)

        for _, v17 in ipairs(SkeletonBody.bodies_mut(p2.skeleton)) do
            v17.inertia.linear_drag = 0
        end

        wipeout_state.state.move_board = bit32.band(processed.flags_2472, 2048) ~= 0
        wipeout_state.state.board_offset = rt.map(processed.vectors_720_784_800_816_832_864[4], rt.from_bits)
        wipeout_state.state.board_move_frames = 0
        wipeout_state.state.predicted_time = rt.F32_MAX
        wipeout_state.state.airborne_frames = 15

        if bit32.band(processed.flags_2468, 8) ~= 0 then
            v9.set_velocity(p2.skeleton, rt.map(processed.vectors_544_560_592_608[4], rt.from_bits))
        end

        wipeout_state.state.velocity = rt.copy(p2.animated_skeleton.board_frames.com_velocity)
    end,
    exit = function(p3, p4) -- exit | line: 121
        -- upvalues: rt (copy), BodyId (copy), BoardRuntime (copy)
        p3.board_wiping_out = false

        local wipeout_state = p4.wipeout_state

        BoardRuntime.bodies_mut(p3.board)[BodyId.index(BodyId.Deck) + 1].inertia.angular_drag = wipeout_state.settings.deck_angular_drag
        BoardRuntime.set_collision_group(p3.board, 4)

        local standard_materials = wipeout_state.settings.standard_materials

        p3.settings.wheel_material = rt.copy(standard_materials[1])
        p3.settings.truck_material = rt.copy(standard_materials[2])
        p3.settings.deck_material = rt.copy(standard_materials[3])
        wipeout_state.state.prevent_manual = false
    end,
    post_physics = function(p5) -- post_physics | line: 135
        -- upvalues: rt (copy), State (copy)
        State.post_physics(p5.wipeout_state.state, rt.copy(p5.skeleton.record.velocities[24]), rt.copy(p5.skeleton.record.velocities[2]), p5.collision_feedback.flags.compliant, p5.wipeout_state.settings.recovery)
    end
}
