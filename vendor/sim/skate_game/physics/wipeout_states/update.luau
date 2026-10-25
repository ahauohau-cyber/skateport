-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_subnormal_mantissa(p1) -- line: 7
    local v2 = p1 * 7.1362384635298E+44
    local v3 = math.floor(v2)
    local v4 = v2 - v3

    if v4 > 0.5 or v4 == 0.5 and v3 % 2 == 1 then
        return v3 + 1
    end

    return v3
end

local function rtl_fround(p2) -- line: 16
    -- upvalues: v1 (copy)
    if p2 ~= 0 and p2 > -1.1754943508222875E-38 and p2 < 1.1754943508222875E-38 then
        local v6 = math.abs(p2) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        local v8 = v5 * 1.401298464324817E-45

        if p2 < 0 then
            return -v8
        end

        return v8
    end

    buffer.writef32(v1, 0, p2)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local v9 = import("skate_game/physics/wipeout_states/contact")
local v10 = import("skate_game/physics/wipeout_states/prediction")
local v11 = import("skate_game/physics/wipeout_states/ragdoll")
local v12 = import("skate_game/physics/wipeout_states/skeleton")
local v13 = import("skate_core/air/trajectory")
local Vector3 = import("skate_core/math").Vector3
local v14 = import("skate_core/physics/board")
local v15 = import("skate_core/physics/board_runtime")
local v16 = import("skate_core/player/wipeout_state")
local v17 = import("skate_core/player/wipeout_state/body")
local v18 = import("skate_core/player/wipeout_state/control_air")
local v19 = import("skate_core/player/wipeout_state/control_ground")
local v20 = import("skate_core/player/wipeout_state/control_profile_air")
local v21 = import("skate_core/player/wipeout_state/drives")
local v22 = import("skate_core/player/wipeout_state/math")
local v23 = import("skate_core/player/wipeout_state/profiles")
local v24 = import("skate_core/player/wipeout_state/response")
local v25 = import("skate_core/player/wipeout_state/weights")
local v26 = import("skate_core/riding/ground_correction_math")
local v27 = import("skate_core/riding/steering")
local Prediction = v10.Prediction
local RagdollSetup = v11.RagdollSetup
local QueryResult = v13.QueryResult
local BodyId = v14.BodyId
local BoardRuntime = v15.BoardRuntime
local State = v16.State
local apply_world_force = v26.apply_world_force
local TruckSteeringState = v27.TruckSteeringState
local vector
local t1 = {}

t1.DT = 0.01666666753590107

local DT = t1.DT

function t1.advance(p3, p4) -- line: 68
    -- upvalues: rt (copy), v1 (copy), v9 (copy), v12 (copy), v17 (copy), v18 (copy), v19 (copy), v20 (copy), v21 (copy), v22 (copy), v23 (copy), v24 (copy), v25 (copy), Prediction (copy), RagdollSetup (copy), QueryResult (copy), BodyId (copy), BoardRuntime (copy), State (copy), apply_world_force (copy), TruckSteeringState (copy), vector (ref), DT (copy)
    local processed = p4.player_input.processed
    local wipeout_state = p4.wipeout_state
    local state = wipeout_state.state
    local v28 = p4.collision_feedback.flags.any or state.below_surface

    if v28 then
        state.airborne_frames = -1
    else
        state.airborne_frames = rt.to_i32(rt.wrapping_add_u32(rt.to_u32(state.airborne_frames), rt.to_u32(1)))
    end

    if not state.special_surface and bit32.band(processed.flags_2488, 1073741824) ~= 0 then
        state.special_surface = true
        state.surface_height = processed.collision_scalar_2924
        RagdollSetup.request(wipeout_state.ragdoll, p4.ground_lifecycle.skeleton_controller, 10, p4.skeleton, p4.skeleton_joints, p4.skeleton_collision)
    end

    local v29 = rt.map(processed.vectors_544_560_592_608[4], rt.from_bits)

    if v29[2] > 5 and v29[2] - state.velocity[2] > 5 then
        v17.limit_velocity(p4.skeleton, 5)
    end

    state.velocity = rt.copy(v29)

    local v30 = v22.length(v29)

    v24.retained_velocity(state, p4.skeleton, p4.skeleton_drives, wipeout_state.drives, v28, processed.flags_2468, v29)

    local v31 = rt.map(processed.vectors_544_560_592_608[3], rt.from_bits)

    if state.special_surface then
        state.below_surface = v31[2] - state.surface_height < 0
        v17.special_surface(p4.skeleton, state.surface_height)
    end

    local v32 = rt.map(processed.effective_anim_transform_192, function(p5) -- line: 111
        -- upvalues: rt (copy)
        return rt.map(p5, rt.from_bits)
    end)
    local v33 = rt.copy(p4.animation_input.extra.wipeout_control)
    local v34 = rt.copy(p4.animation_input.extra.wipeout_gesture)

    if not state.below_surface then
        v9.update(state, wipeout_state.contact, p4.skeleton, p4.collision_feedback, p4.ground_lifecycle.skeleton_controller, p4.skeleton_collision, p4.skeleton_joints, wipeout_state.ragdoll, v28, v29, rt.copy(v32[3]), v33)

        local v35 = if not state.slow or not v28 then 0 elseif state.over then v22.clamp(state.settled_time * 0.15 + 0.05, 0, 0.5) else 0.05

        v17.set_wipeout_drag(p4.skeleton, v35)
    end

    local v36 = state.time + DT
    local v37

    if v36 ~= 0 and v36 > -1.1754943508222875E-38 and v36 < 1.1754943508222875E-38 then
        local v38 = math.abs(v36) * 7.1362384635298E+44
        local v39 = math.floor(v38)
        local v40 = v38 - v39

        v37 = (if v40 > 0.5 or v40 == 0.5 and v39 % 2 == 1 then v39 + 1 else v39) * 1.401298464324817E-45

        if v36 < 0 then
            v37 = -v37
        end
    else
        buffer.writef32(v1, 0, v36)
        v37 = buffer.readf32(v1, 0)
    end

    state.time = v37

    local v41 = state.response_time + DT
    local v42

    if v41 ~= 0 and v41 > -1.1754943508222875E-38 and v41 < 1.1754943508222875E-38 then
        local v43 = math.abs(v41) * 7.1362384635298E+44
        local v44 = math.floor(v43)
        local v45 = v43 - v44

        v42 = (if v45 > 0.5 or v45 == 0.5 and v44 % 2 == 1 then v44 + 1 else v44) * 1.401298464324817E-45

        if v41 < 0 then
            v42 = -v42
        end
    else
        buffer.writef32(v1, 0, v41)
        v42 = buffer.readf32(v1, 0)
    end

    state.response_time = v42

    local v46 = state.extra_weight_zero_time + DT
    local v47

    if v46 ~= 0 and v46 > -1.1754943508222875E-38 and v46 < 1.1754943508222875E-38 then
        local v48 = math.abs(v46) * 7.1362384635298E+44
        local v49 = math.floor(v48)
        local v50 = v48 - v49

        v47 = (if v50 > 0.5 or v50 == 0.5 and v49 % 2 == 1 then v49 + 1 else v49) * 1.401298464324817E-45

        if v46 < 0 then
            v47 = -v47
        end
    else
        buffer.writef32(v1, 0, v46)
        v47 = buffer.readf32(v1, 0)
    end

    state.extra_weight_zero_time = v47

    if state.extra_weight > 0 then
        state.extra_weight_zero_time = 0
    end

    state.response_scalar = 0

    local v51 = state.slow_time + DT
    local v52

    if v51 ~= 0 and v51 > -1.1754943508222875E-38 and v51 < 1.1754943508222875E-38 then
        local v53 = math.abs(v51) * 7.1362384635298E+44
        local v54 = math.floor(v53)
        local v55 = v53 - v54

        v52 = (if v55 > 0.5 or v55 == 0.5 and v54 % 2 == 1 then v54 + 1 else v54) * 1.401298464324817E-45

        if v51 < 0 then
            v52 = -v52
        end
    else
        buffer.writef32(v1, 0, v51)
        v52 = buffer.readf32(v1, 0)
    end

    state.slow_time = v52

    if v30 - state.maximum_speed >= 0 then
        state.maximum_speed = v30
    else
        state.maximum_speed = state.maximum_speed
    end

    if v30 > 2 then
        state.slow_time = 0
    end

    v24.update_counter(state, v28)

    local v56 = rt.copy(p4.animated_skeleton.board_frames.centre_of_mass)
    local v57

    if state.below_surface or state.imminent_surface_twelve then
        v57 = false
        v18.update(state, p4.skeleton, v56, v33, true)
    else
        local flags_2484 = processed.flags_2484
        local response_normal, v58, v59

        if bit32.band(flags_2484, 256) == 0 then
            v59 = true
        elseif state.response_time >= 0.1 then
            response_normal = v24.response_normal

            if p4.collision_feedback.flags.compliant then
                v58 = rt.copy(p4.collision_feedback.highest_normal)
            end

            v59 = false
        else
            v59 = true
        end

        if v59 then
            if not (state.airborne_frames > 15) or state.over then
                if (v28 or not (state.airborne_frames > 15)) and not state.over then
                    v23.prepare(state, wipeout_state.profiles, v34, v33)
                    v57 = true
                    v19.update(state, p4.skeleton, v56, v32, processed, wipeout_state.profiles[state.profile + 1], p4.animated_skeleton.roots.animation_to_world, p4.animated_skeleton.record.pose)
                else
                    v57 = v18.update(state, p4.skeleton, v56, v33, v28)
                end
            else
                v23.prepare(state, wipeout_state.profiles, v34, v33)

                local v60 = wipeout_state.profiles[state.profile + 1]

                v20.update(state, p4.skeleton, v56, v32, v33, v60)
                v57 = true
                v23.drift(state, p4.skeleton, v60)
            end
        else
            local v61 = response_normal(v58, if QueryResult.valid(wipeout_state.prediction.result) then rt.copy(wipeout_state.prediction.result.landing_normal) else nil)

            v57 = false
            v24.trigger(state, p4.skeleton, v61, v33)
        end
    end

    local v62 = v25.update(state, {
        remove_target_time = wipeout_state.settings.remove_target_time,
        remove_drives_time = wipeout_state.settings.remove_drives_time,
        collision_step = wipeout_state.settings.collision_weight_step,
        controlled_step = wipeout_state.settings.controlled_weight_step
    }, v28, v57, processed.flags_2472, v34)

    TruckSteeringState.update(p4.ground.steering, 0, p4.air_settings.steering_blend, processed.flags_2468, processed.flags_2472)
    v21.set_angular_root(p4.skeleton_drives, wipeout_state.drives, v62.target_weight)

    local t2 = {
        animated = p4.animated_skeleton,
        body = p4.skeleton,
        drives = p4.skeleton_drives,
        ik = p4.foot_ik,
        animation_input = p4.animation_input,
        correction = p4.skeleton_output.correction,
        pose_errors = p4.pose_errors
    }

    v12.update(p4.skeleton_input, t2, processed, p4.animation.packet.hierarchy, wipeout_state.drives, v62.start, v62["end"], v62.controlled, v62.extra, state.retained_velocity_active)

    if state.move_board and rt.to_i32(state.board_move_frames) < 21 then
        local v63 = rt.copy(BoardRuntime.part_transforms(p3.board)[BodyId.index(BodyId.Deck) + 1].translation)
        local toolkit = p4.player_input.toolkit

        if toolkit == nil then
            error("Wipeout board force requires the current BoardToolkit", 0)
        end

        local v64 = rt.copy(toolkit.deck[4])

        apply_world_force(BoardRuntime.bodies_mut(p3.board)[BodyId.index(BodyId.Deck) + 1], v63, vector(state.board_offset), vector(v64))
        state.board_move_frames = rt.wrapping_add_u32(state.board_move_frames, 1)
    end

    State.manage_recovery(state, processed.flags_2468, processed.flags_2472, processed.flags_2484, processed.timestep_2604, wipeout_state.settings.recovery)

    local gravity_acceleration = p3.settings.step.simulation.gravity_acceleration

    return Prediction.advance(wipeout_state.prediction, state, p3.world, v31, {
        gravity_acceleration.x,
        gravity_acceleration.y,
        gravity_acceleration.z,
        0
    })
end

function vector(p6) -- line: 247
    -- upvalues: Vector3 (copy)
    return Vector3.new(p6[1], p6[2], p6[3])
end

t1.vector = vector

return t1
