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

local function rtl_to_bits(p2) -- line: 16
    -- upvalues: v1 (copy)
    if p2 ~= 0 and p2 > -1.1754943508222875E-38 and p2 < 1.1754943508222875E-38 then
        local v6 = math.abs(p2) * 7.1362384635298E+44
        local v5 = math.floor(v6)
        local v7 = v6 - v5

        if v7 > 0.5 or v7 == 0.5 and v5 % 2 == 1 then
            v5 += 1
        end

        if p2 < 0 then
            return v5 + 2147483648
        end

        return v5
    end

    buffer.writef32(v1, 0, p2)

    return (buffer.readu32(v1, 0))
end

local import = require(sim.import)
local choose_surface = import("skate_core/physics/contact_feedback").choose_surface
local v8 = import("skate_core/physics/filtered_state")
local FilteredState, GrindState = v8.FilteredState, v8.GrindState
local CurrentStateFields = import("skate_core/player/input_phase").CurrentStateFields
local PhysicalStateId = import("skate_core/player/state").PhysicalStateId
local State = import("skate_core/player/offboard/landing_state").State
local TrajectorySelector = import("skate_core/air/trajectory").TrajectorySelector
local v9 = import("skate_core/air/state")
local v10 = import("skate_game/physics/player_state/wipeout_output")

local function parent() -- line: 41
    -- upvalues: import (copy)
    return import("skate_game/physics/player_state")
end

local function board_manager_runtime() -- line: 45
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/board_manager/runtime")
end

local function known_air() -- line: 48
    -- upvalues: import (copy)
    return import("skate_game/physics/known_air")
end

local function biped_air() -- line: 51
    -- upvalues: import (copy)
    return import("skate_game/physics/biped_air")
end

local function landing_on_deck() -- line: 54
    -- upvalues: import (copy)
    return import("skate_game/physics/landing_on_deck")
end

local function grind() -- line: 57
    -- upvalues: import (copy)
    return import("skate_game/physics/grind")
end

local function biped_ground() -- line: 60
    -- upvalues: import (copy)
    return import("skate_game/physics/biped_ground")
end

local function ground_runtime() -- line: 63
    -- upvalues: import (copy)
    return import("skate_game/physics/ground_runtime")
end

local function wipeout() -- line: 66
    -- upvalues: import (copy)
    return import("skate_game/physics/wipeout")
end

local function footplant() -- line: 69
    -- upvalues: import (copy)
    return import("skate_game/physics/footplant")
end

local function ground_animation() -- line: 72
    -- upvalues: import (copy)
    return import("skate_game/physics/ground_animation")
end

local function teleport_state() -- line: 75
    -- upvalues: import (copy)
    return import("skate_game/physics/teleport_state")
end

local t1 = {}

local function map_to_bits(p3) -- line: 81
    -- upvalues: v1 (copy)
    local v11 = table.create(#p3)

    for i = 1, #p3 do
        local v12 = p3[i]

        if v12 ~= 0 and v12 > -1.1754943508222875E-38 and v12 < 1.1754943508222875E-38 then
            local v13 = math.abs(v12) * 7.1362384635298E+44
            local v14 = math.floor(v13)
            local v15 = v13 - v14
            local v16 = if v15 > 0.5 or v15 == 0.5 and v14 % 2 == 1 then v14 + 1 else v14

            if v12 < 0 then
                v11[i] = v16 + 2147483648
            else
                v11[i] = v16
            end
        else
            buffer.writef32(v1, 0, v12)
            v11[i] = buffer.readu32(v1, 0)
        end
    end

    return v11
end

local function u8_from(p4) -- line: 89
    if p4 then
        return 1
    end

    return 0
end

local function state_debug(p5) -- line: 94
    -- upvalues: PhysicalStateId (copy)
    for v17, v18 in PhysicalStateId do
        if type(v18) == "number" and v18 == p5 then
            return v17
        end
    end

    return (tostring(p5))
end

local v19 = false

function t1.set_reference(p6) -- line: 119
    -- upvalues: v19 (ref)
    v19 = p6
end

local v20

local function set(p7, p8) -- line: 124
    -- upvalues: v20 (ref)
    local v21 = v20

    v21[p7 - 52 + 1] = p8
end

local t2 = {
    false,
    false,
    false,
    false
}
local t3 = {}
local v22 = table.freeze(GrindState.default())

function t1.wheel_surface(p9) -- line: 133
    -- upvalues: choose_surface (copy), t2 (copy)
    local parts = p9.riding.ground.parts
    local in_contact = parts[1].in_contact
    local in_contact2 = parts[2].in_contact
    local in_contact3 = parts[3].in_contact
    local in_contact4 = parts[4].in_contact

    t2[1] = in_contact
    t2[2] = in_contact2
    t2[3] = in_contact3
    t2[4] = in_contact4

    return choose_surface(p9.riding.wheel_lines.physics_surfaces, t2, bit32.band(p9.riding.ground.collision_flags, 33554432) ~= 0)
end

function t1.wheel_surface_reference(p10) -- line: 145
    -- upvalues: rt (copy), choose_surface (copy)
    return choose_surface(rt.copy(p10.riding.wheel_lines.physics_surfaces), {
        p10.riding.ground.parts[1].in_contact,
        p10.riding.ground.parts[2].in_contact,
        p10.riding.ground.parts[3].in_contact,
        p10.riding.ground.parts[4].in_contact
    }, bit32.band(p10.riding.ground.collision_flags, 33554432) ~= 0)
end

function t1.filtered_input_view(_, p12, p13, p14, p15) -- line: 159
    -- upvalues: import (copy), PhysicalStateId (copy), t3 (copy), v22 (copy)
    local physical = p12.player_input.physical

    t3.physics_category = PhysicalStateId.category(p13)
    t3.physics_state = p13
    t3.anything_in_contact = physical.collision.flag_3477 ~= 0
    t3.physics_surface_type = p14
    t3.wall_ride_exit = p15 ~= nil and p15.ground_32.wall_ride_exit
    t3.targeting_grind = p13 == PhysicalStateId.KnownAir and p12.known_air.state.targeting_grind_213
    t3.offboard_has_landed = physical.off_board.flag_320 ~= 0
    t3.offboard_on_deck = physical.off_board.flag_315 ~= 0
    t3.grind = if PhysicalStateId.is_grind(p13) then import("skate_game/physics/grind").Runtime.filtered_output(physical.grinds) else v22
    t3.last_grind_distance = import("skate_game/physics/grind").Runtime.last_grind_distance(p12.grind)

    return t3
end

function t1.filtered_input_reference(_, p17, p18, p19, p20) -- line: 177
    -- upvalues: import (copy), GrindState (copy), PhysicalStateId (copy)
    local physical = p17.player_input.physical

    return {
        physics_category = PhysicalStateId.category(p18),
        physics_state = p18,
        anything_in_contact = physical.collision.flag_3477 ~= 0,
        physics_surface_type = p19,
        wall_ride_exit = p20 ~= nil and p20.ground_32.wall_ride_exit,
        targeting_grind = p18 == PhysicalStateId.KnownAir and p17.known_air.state.targeting_grind_213,
        offboard_has_landed = physical.off_board.flag_320 ~= 0,
        offboard_on_deck = physical.off_board.flag_315 ~= 0,
        grind = if PhysicalStateId.is_grind(p18) then import("skate_game/physics/grind").Runtime.filtered_output(physical.grinds) else GrindState.default(),
        last_grind_distance = import("skate_game/physics/grind").Runtime.last_grind_distance(p17.grind)
    }
end

function t1.publish(p21, p22) -- line: 199
    -- upvalues: rt (copy), v1 (copy), import (copy), FilteredState (copy), CurrentStateFields (copy), PhysicalStateId (copy), State (copy), TrajectorySelector (copy), v9 (copy), v10 (copy), t1 (copy), v19 (ref), v20 (ref)
    local v27 = import("skate_game/physics/player_state").PlayerState.current(p22.player_state)

    import("skate_game/physics/offboard/board_manager/runtime").publish(p21, p22)

    local v28 = p22.biped_ground.controller.state
    local processed = p22.player_input.physical.off_board
    local v29 = v28.frame_output.velocity
    local v30 = table.create(#v29)
    local v32, v33, v34

    for i = 1, #v29 do
        v32 = v29[i]

        if v32 ~= 0 and v32 > -1.1754943508222875E-38 and v32 < 1.1754943508222875E-38 then
            local v35 = math.abs(v32) * 7.1362384635298E+44

            v33 = math.floor(v35)

            local v36 = v35 - v33

            v34 = if v36 > 0.5 or v36 == 0.5 and v33 % 2 == 1 then v33 + 1 else v33

            if v32 < 0 then
                v30[i] = v34 + 2147483648
            else
                v30[i] = v34
            end
        else
            buffer.writef32(v1, 0, v32)
            v30[i] = buffer.readu32(v1, 0)
        end
    end

    processed.vector_64 = v30
    p22.player_input.physical.off_board.cadence_phase_80 = v28.cadence.phase.phase
    p22.player_input.physical.off_board.locomotion_state_84 = v28.cadence.locomotion_index

    local v37, physical

    if not PhysicalStateId.is_grind(v27) and v27 ~= PhysicalStateId.Nonspecific and v27 ~= PhysicalStateId.PhysicsGround and v27 ~= PhysicalStateId.PhysicsAir and v27 ~= PhysicalStateId.PhysicsAirSecondary and v27 ~= PhysicalStateId.FootPlant and v27 ~= PhysicalStateId.Boneless and v27 ~= PhysicalStateId.HandPlant and v27 ~= PhysicalStateId.RevertGround and v27 ~= PhysicalStateId.KnownAir and v27 ~= PhysicalStateId.BipedAir and v27 ~= PhysicalStateId.BipedGround and v27 ~= PhysicalStateId.OffBoardPushing and v27 ~= PhysicalStateId.GroundAnimation and v27 ~= PhysicalStateId.SlideGround and v27 ~= PhysicalStateId.WipeoutGround and v27 ~= PhysicalStateId.Teleporting and v27 ~= PhysicalStateId.LandingOnDeck then
        processed = error
        physical = string.format
        v29 = "FillPhysOut requires the actual %s output owner"

        local v38 = false

        for v39, v40 in PhysicalStateId do
            if type(v40) == "number" and v40 == v27 then
                v37 = v39
                v38 = true
                break
            end
        end

        if not v38 then
            v37 = tostring(v27)
        end

        processed(physical(v29, v37), 0)
    end

    if v27 == PhysicalStateId.KnownAir then
        import("skate_game/physics/known_air").fill(p21, p22)
    end

    if v27 == PhysicalStateId.BipedAir then
        import("skate_game/physics/biped_air").fill(p22)
    end

    if v27 == PhysicalStateId.LandingOnDeck then
        import("skate_game/physics/landing_on_deck").fill(p22)
    end

    if PhysicalStateId.is_grind(v27) or v27 == PhysicalStateId.Nonspecific then
        import("skate_game/physics/grind").fill(p21, p22)
    end

    if v27 == PhysicalStateId.BipedGround or v27 == PhysicalStateId.OffBoardPushing then
        processed = import("skate_game/physics/biped_ground").fill(p22, p22.offboard_feet)
        v28 = import("skate_game/physics/biped_ground").publish_fields(processed, p22.player_input.physical)
    else
        v28 = nil
    end

    processed = p22.player_input.processed
    physical = p22.player_input.toolkit

    if physical == nil then
        error("State output requires actual board toolkit", 0)
    end

    v29 = if v27 == PhysicalStateId.PhysicsGround then import("skate_game/physics/ground_runtime").GroundState.output(p22.ground, processed, p22.animation_input, physical) else nil
    physical = p22.player_input.player
    p22.player_state.state_count = physical.state_count_1312
    p22.player_state.update_count = physical.update_count_1316
    v37 = p22.player_state.state_flags

    if not v19 and #v37 == 36 and next(v37, 36) == nil then
        for i = 1, 36 do
            v37[i] = false
        end
    else
        rt.assign(v37, table.create(36, false))
    end

    v20 = v37

    local air = bit32.band(processed.flags_2468, 1073741824) ~= 0

    v20[1] = air
    air = bit32.band(processed.flags_2468, 536870912) ~= 0
    v20[3] = air
    air = bit32.band(processed.flags_2468, 33554432) ~= 0
    v20[4] = air
    air = bit32.band(processed.flags_2468, 134217728) ~= 0
    v20[5] = air
    air = bit32.band(processed.flags_2468, 67108864) ~= 0
    v20[6] = air
    air = bit32.band(processed.flags_2468, 268435456) ~= 0
    v20[7] = air
    air = bit32.band(processed.flags_2468, 262144) ~= 0
    v20[8] = air
    air = p22.animation_input.fields.balance ~= 0
    v20[9] = air
    air = bit32.band(processed.flags_2472, 1024) ~= 0
    v20[11] = air
    air = v27 == PhysicalStateId.LandingOnDeck and State.requests_board_flip(p22.landing_on_deck.state)
    v20[12] = air
    air = v27 == PhysicalStateId.RevertGround and p22.revert_state.active
    v20[15] = air
    air = import("skate_game/physics/wipeout").Wipeout.requests_wipeout(p22.wipeout, processed)
    v20[14] = air
    air = import("skate_game/physics/wipeout").Wipeout.requests_runout(p22.wipeout, processed)
    v20[27] = air
    air = bit32.band(physical.flags_1296, 16777216) ~= 0
    v20[20] = air
    air = bit32.band(processed.flags_2476, 16777216) ~= 0
    v20[22] = air
    air = v27 == PhysicalStateId.HandPlant and p22.handplant.continuation
    v20[23] = air
    air = PhysicalStateId.category(v27) == 500
    v20[24] = air
    air = v27 == 500
    v20[25] = air

    if processed.state_identifier_2496 == 500 then
        physical.dismount_request_frames_1332 = 3
    end

    v37 = physical.dismount_request_frames_1332 > 0

    if v37 then
        physical.dismount_request_frames_1332 -= 1
    end

    v20[26] = v37
    air = processed.state_variant_index_2528 == 3
    v20[28] = air
    air = bit32.band(processed.flags_2484, 2097152) ~= 0
    v20[29] = air
    air = p22.footplant.perform or p22.footplant.flag_627

    local v41 = v20

    v41[32] = air

    if v29 ~= nil then
        air = v29.state_28.flag_84
        v41 = v20
        v41[33] = air
        air = v29.state_28.has_world_grab_intent_without_object
        v41 = v20
        v41[35] = air
        v37 = v29.state_28.manual_correction_write_78

        if v37 ~= nil then
            air = v20
            air[27] = v37
        end
    end

    air = bit32.band(processed.flags_2484, 1024) ~= 0
    v41 = v20
    v41[36] = air

    if v28 ~= nil then
        air = v28.flag_86
        v41 = v20
        v41[35] = air
    end

    if v27 == PhysicalStateId.SlideGround then
        air = p22.slide_state.state.wall_riding
        v41 = v20
        v41[33] = air
    end

    physical = p22.player_input.physical
    physical.component_1832_word_1876 = p22.handplant.flags
    air = physical.air

    local anchor = p22.handplant.anchor

    v32 = table.create(#anchor)

    local v43, v44

    for i = 1, #anchor do
        v33 = anchor[i]

        if v33 ~= 0 and v33 > -1.1754943508222875E-38 and v33 < 1.1754943508222875E-38 then
            v43 = math.abs(v33) * 7.1362384635298E+44

            local v45 = math.floor(v43)
            local v46 = v43 - v45

            v44 = if v46 > 0.5 or v46 == 0.5 and v45 % 2 == 1 then v45 + 1 else v45

            if v33 < 0 then
                v32[i] = v44 + 2147483648
            else
                v32[i] = v44
            end
        else
            buffer.writef32(v1, 0, v33)
            v32[i] = buffer.readu32(v1, 0)
        end
    end

    air.handplant_position_304 = v32
    physical.air.handplant_time_320 = p22.handplant.phase
    physical.air.flag_446 = bit32.band(p22.handplant.flags, 2147483648) ~= 0 and 1 or 0
    import("skate_game/physics/footplant").Footplant.publish(p22.footplant, physical.air)
    air = physical.off_board
    v34 = processed.flags_2480
    air.flag_308 = bit32.band(v34, 524288) ~= 0 and 1 or 0
    air = TrajectorySelector.selection(p22.trajectory.selector)
    v41 = physical.air
    v32 = air ~= nil and air.wall_ride
    v41.flag_444 = v32 and 1 or 0
    physical.air.flag_441 = p22.air_reckoning.state.flip_active and 1 or 0
    physical.air.flag_445 = p22.air_reckoning.state.flip_side and 1 or 0

    if v27 == PhysicalStateId.GroundAnimation then
        import("skate_game/physics/ground_animation").GroundAnimationRuntime.fill(p22.ground_animation, processed, physical.air)
    end

    air = CurrentStateFields.default()
    air.category_12 = PhysicalStateId.category(v27)
    air.state_16 = v27
    anchor = v27 == PhysicalStateId.RevertGround and p22.revert_state.active
    air.flag_66 = anchor and 1 or 0
    anchor = v27 == PhysicalStateId.HandPlant and p22.handplant.continuation
    air.flag_74 = anchor and 1 or 0
    air.flag_69 = p22.player_state.selector.request_teleport and 1 or 0
    physical.state = air
    p22.player_state.state_flags[18] = physical.state.flag_69 ~= 0

    if v28 ~= nil then
        physical.state.counter_36 = v28.word_36
        physical.state.skitch_value_40 = v28.word_40
    end

    local v47, v48, state, v49, v50, v51, v52, v53

    if v29 ~= nil then
        physical.state.skitch_value_40 = v29.state_28.grab_spline_object_id
        physical.state.signed_ground_step_84 = v29.state_28.flag_84 and 1 or 0
        state = physical.ground
        v32 = v29.ground_32.anti_flip_torque
        v34 = table.create(#v32)

        for i = 1, #v32 do
            v44 = v32[i]

            if v44 ~= 0 and v44 > -1.1754943508222875E-38 and v44 < 1.1754943508222875E-38 then
                v28 = math.abs(v44) * 7.1362384635298E+44

                local v55 = math.floor(v28)

                v43 = v28 - v55

                local v56 = if v43 > 0.5 or v43 == 0.5 and v55 % 2 == 1 then v55 + 1 else v55

                if v44 < 0 then
                    v34[i] = v56 + 2147483648
                else
                    v34[i] = v56
                end
            else
                buffer.writef32(v1, 0, v44)
                v34[i] = buffer.readu32(v1, 0)
            end
        end

        state.vector_128 = v34
        physical.ground.scalar_276 = v29.ground_32.time_to_skitch
        physical.ground.flag_317 = v29.ground_32.anti_flip_nudge_present and 1 or 0
        physical.ground.flag_318 = v29.ground_32.is_pinning and 1 or 0
        physical.off_board.flag_304 = v29.is_grabbing_object_72_304 and 1 or 0
        physical.animation.manual_opposition_168 = v29.manual_opposition_56_168 and 1 or 0
    elseif v27 == PhysicalStateId.PhysicsAir then
        state = v9.fill_physics_output(p22.air_state)
        v49 = physical.air
        v34 = state.landing_normal
        v47 = table.create(#v34)
        v50 = #v34

        for i = 1, v50 do
            v48 = v34[i]

            if v48 ~= 0 and v48 > -1.1754943508222875E-38 and v48 < 1.1754943508222875E-38 then
                v51 = math.abs(v48) * 7.1362384635298E+44
                v52 = math.floor(v51)
                v53 = v51 - v52

                local v54 = if v53 > 0.5 or v53 == 0.5 and v52 % 2 == 1 then v52 + 1 else v52

                if v48 < 0 then
                    v47[i] = v54 + 2147483648
                else
                    v47[i] = v54
                end
            else
                buffer.writef32(v1, 0, v48)
                v47[i] = buffer.readu32(v1, 0)
            end
        end

        v49.landing_normal_144 = v47
        physical.air.jump_height_200 = state.jump_height
        physical.air.reached_apex_436 = state.is_at_apex and 1 or 0
        v49 = state.scalar_184_write

        if v49 ~= nil then
            physical.air.scalar_184 = v49
        end
    elseif v27 == PhysicalStateId.SlideGround then
        physical.state.signed_ground_step_84 = p22.slide_state.state.wall_riding and 1 or 0
    end

    state = physical.air
    v32 = bit32.band(physical.air.handplant_flags_324, 268435455)
    v47 = physical.component_1832_word_1876
    v34 = bit32.band(v47, 4026531840)
    state.handplant_flags_324 = bit32.bor(v32, v34)

    if v29 ~= nil then
        state = v29.velocity_projection_36

        if state ~= nil then
            v49 = physical.reckoning
            v34 = state.velocity_without_axis_component
            v47 = table.create(#v34)
            v50 = #v34

            for i = 1, v50 do
                v48 = v34[i]

                if v48 ~= 0 and v48 > -1.1754943508222875E-38 and v48 < 1.1754943508222875E-38 then
                    v51 = math.abs(v48) * 7.1362384635298E+44
                    v52 = math.floor(v51)
                    v53 = v51 - v52

                    local v57 = if v53 > 0.5 or v53 == 0.5 and v52 % 2 == 1 then v52 + 1 else v52

                    if v48 < 0 then
                        v47[i] = v57 + 2147483648
                    else
                        v47[i] = v57
                    end
                else
                    buffer.writef32(v1, 0, v48)
                    v47[i] = buffer.readu32(v1, 0)
                end
            end

            v49.vector_144 = v47
            physical.reckoning.flag_164 = state.active and 1 or 0
        end
    end

    v20 = nil
    state = if v19 then t1.wheel_surface_reference(p21) else t1.wheel_surface(p21)
    import("skate_game/physics/grind").condition(p21, p22)
    physical = p22.player_input.physical

    if v19 then
        v32 = FilteredState.update(p22.player_state.filtered, t1.filtered_input_reference(p21, p22, v27, state, v29))
        physical.filtered_state_0 = v32.category
        p22.player_state.filtered_output = rt.copy(v32)
    else
        v32 = t1.filtered_input_view(p21, p22, v27, state, v29)
        v34 = FilteredState.update(p22.player_state.filtered, v32)
        v32.grind = nil
        physical.filtered_state_0 = v34.category
        p22.player_state.filtered_output = v34
    end

    p22.player_state.ground_output = v29

    if v27 == PhysicalStateId.WipeoutGround then
        v10.publish(p22)
    end

    if v27 == PhysicalStateId.Teleporting then
        import("skate_game/physics/teleport_state").Runtime.publish_output(p22.teleport_state, p22.player_input.physical)
    end
end

return t1
