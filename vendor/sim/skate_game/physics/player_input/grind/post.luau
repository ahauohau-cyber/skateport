-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)

local function parent() -- line: 9
    -- upvalues: import (copy)
    return import("skate_game/physics/player_input/grind")
end

local v1 = import("skate_game/physics/player_input/grind/publication")
local EntryKind = import("skate_core/physics/grind_contact/admission").EntryKind
local v2 = import("skate_core/physics/grind_contact/balance")
local v3 = import("skate_core/physics/grind_contact/control")
local v4 = import("skate_core/physics/grind_contact/entry")
local v5 = import("skate_core/physics/grind_contact/manager")
local v6 = import("skate_core/air/trajectory/grind_surface")
local BalanceState = v2.BalanceState
local Control = v3.Control
local Engagement = v4.Engagement
local Jumper = v5.Jumper
local assign_into = import("skate_core/player/input_phase").GrindInvestigationFields.assign_into
local v7 = false
local t1 = {}

function t1.set_reference(p1) -- line: 31
    -- upvalues: v7 (ref)
    v7 = p1
end

t1.GrindInputState = {}

function t1.GrindInputState.post_update(p2, p3, p4, p5, p6, p7) -- line: 53
    -- upvalues: rt (copy), import (copy), v1 (copy), v5 (copy), v6 (copy), BalanceState (copy), Control (copy), Engagement (copy), Jumper (copy), assign_into (copy), t1 (copy), v7 (ref)
    local float, raw, fields, metadata, v8, v9

    if v7 then
        v9 = true
    elseif type(p2.investigation) == "table" then
        if type(p3.grind) == "table" then
            local v10 = import("skate_game/physics/player_input/grind")

            float = v10.float
            raw = v10.raw
            fields = p5.fields

            local geometry = p5.geometry

            metadata = p5.metadata

            if geometry ~= nil then
                if geometry.plan ~= nil then
                    local plan = geometry.plan

                    v8 = v6.resolve(plan, geometry.hits, fields.geometry_flags_1476)
                else
                    v8 = v6.investigate(rt.copy(geometry.input), function(p8, p9) -- line: 70
                        -- upvalues: p3 (copy), p4 (copy), p7 (copy)
                        return p7.surface_probe(p7, p4, {
                            p3.actor_query_2948,
                            p3.actor_query_2952
                        }, p8, p9)
                    end)
                end

                v1.surface(fields, v8)

                local v11, v12 = v5.tweak_geometry({
                    valid = fields.valid_1488,
                    family = fields.family_1248,
                    current_state = p3.state_2508,
                    category = p3.category_2512,
                    air_frames = p2.air_frames,
                    geometry_kind = v8.kind,
                    geometry_flags = v8.flags,
                    far_points = rt.copy(v8.far_points),
                    upmost = rt.copy(v8.upmost_normal),
                    high_side = rt.copy(v8.high_side),
                    point = float(fields.point_1120),
                    direction = float(fields.direction_1136),
                    board_position = rt.copy(p6.board[4]),
                    board_forward = rt.copy(p6.board[3]),
                    velocity = float(p3.vectors_400_416[1]),
                    deck_to_truck = p2.settings.deck_to_truck,
                    previous_exit_angle = p2.balance.exit_angle_degrees,
                    previous_exit_direction = rt.copy(p2.balance.exit_direction),
                    flags = fields.flags_1516
                }, p2.secondary_history)

                p2.secondary_history = v12
                fields.valid_1488 = v11.valid
                fields.family_1248 = v11.family
                fields.flags_1516 = v11.flags
            end

            v9 = false
        else
            v9 = true
        end
    else
        v9 = true
    end

    if v9 then
        return t1.GrindInputState.post_update_reference(p2, p3, p4, p5, p6, p7)
    end

    local v13, v14 = v5.gravity_relief(p2.gravity_timer, fields.valid_1488, p3.category_2512, float(fields.tangent_1104), float(p3.vectors_400_416[1]), p3.timestep_2604, p2.settings.gravity_vertical, p2.settings.gravity_linear)

    p2.gravity_timer = v14
    fields.gravity_relief_1512 = v13

    local t3 = if v8 ~= nil and fields.valid_1488 then {
        surface = v8,
        primitive_direction = float(fields.tangent_1104),
        directed_grind_direction = float(fields.direction_1136),
        kind = fields.family_1248,
        entry_kind = t1.entry_kind(fields.entry_kind_1252)
    } else nil
    local t4 = {
        grind_normal = float(fields.normal_1152),
        target_up = float(fields.target_up_1168)
    }

    BalanceState.update_target_up(p2.balance, {
        category = p3.category_2512,
        previous_state = p3.state_2504,
        board_up = float(p3.vectors_544_560_592_608[1])
    }, t3, t4)
    fields.exit_lean_1500 = BalanceState.update_exit_lean(p2.balance, {
        category = p3.category_2512,
        current_state = p3.state_2508,
        grind_substate = p3.grind_words_2532_2536[2],
        timestep = p3.timestep_2604
    }, t3, p2.settings.exit_lean, t4)
    fields.normal_1152 = raw(t4.grind_normal)
    fields.target_up_1168 = raw(t4.target_up)
    fields.flags_1516 = BalanceState.update_force_exit(p2.balance, float(fields.point_1120), fields.flags_1516, function(p10) -- line: 150
        -- upvalues: p3 (copy), p4 (copy), p7 (copy)
        return p7.force_exit_line(p7, p4, {
            p3.actor_query_2948,
            p3.actor_query_2952
        }, p10)
    end)

    local v15 = Engagement.update(p2.engagement, {
        valid = fields.valid_1488,
        kind = fields.family_1248,
        category = p3.category_2512,
        previous_state_2504 = p3.state_2504,
        speed = p3.scalar_2652,
        balance_2720 = p6.balance_2720,
        direction = float(fields.direction_1136),
        normal = rt.copy(t4.grind_normal),
        up = float(p3.vectors_544_560_592_608[1]),
        board_velocity = float(p3.vectors_400_416[1]),
        air_velocity = float(p3.vectors_544_560_592_608[4]),
        surface_kind = fields.geometry_kind_1464,
        high_side = float(fields.high_side_1440),
        vertical_help = p2.settings.vertical_help,
        max_delta = p2.settings.max_impact,
        flags = fields.flags_1516,
        previous_entry_velocity = float(fields.entry_velocity_1184)
    })

    fields.valid_1488 = v15.valid
    fields.flags_1516 = v15.flags
    fields.entry_velocity_1184 = raw(v15.entry_velocity)
    fields.impact_speed_1492 = v15.impact_speed

    if #v15.wipeout_reasons ~= 0 then
        p3.flags_2468 = bit32.bor(p3.flags_2468, 262144)
    end

    Control.update(p2.control, if fields.valid_1488 then fields.family_1248 else 4294967295, rt.copy(p6.board[3]), rt.copy(t4.grind_normal), bit32.band(fields.flags_1516, 536870912) ~= 0, bit32.band(p3.flags_2468, 1048576) ~= 0, bit32.band(fields.flags_1516, 268435456) ~= 0, p6.translation_2796, p6.stability_nudge_2800, p6.up_down_2804, p6.grab_min_height_2808)
    fields.yaw_1504 = p2.control.yaw
    fields.pitch_1508 = p2.control.pitch

    local t5 = if fields.valid_1488 then {
        geometry_kind = fields.geometry_kind_1464,
        high_side = float(fields.high_side_1440),
        normal = rt.copy(t4.grind_normal),
        direction = float(fields.direction_1136),
        upmost = float(fields.upmost_normal_1408),
        point = float(fields.point_1120)
    } else nil

    p3.flags_2476 = bit32.bor(p3.flags_2476, Jumper.update(p2.jumper, t5, p3.grind_words_2532_2536[1]))

    if fields == p2.investigation or fields == p3.grind then
        p2.investigation = rt.copy(fields)
        p3.grind = rt.copy(fields)
    else
        assign_into(p2.investigation, fields)
        assign_into(p3.grind, fields)
    end

    local v22 = v1.observation(p3, p6, metadata, p2.jumper)

    return {
        wipeout_reasons = v15.wipeout_reasons,
        observation = v22
    }
end

function t1.GrindInputState.post_update_reference(p11, p12, p13, p14, p15, p16) -- line: 236
    -- upvalues: rt (copy), import (copy), v1 (copy), v5 (copy), v6 (copy), BalanceState (copy), Control (copy), Engagement (copy), Jumper (copy), t1 (copy)
    local v23 = import("skate_game/physics/player_input/grind")
    local float, raw = v23.float, v23.raw
    local fields, geometry, metadata = p14.fields, p14.geometry, p14.metadata
    local v24

    if geometry ~= nil then
        local v25

        if geometry.plan ~= nil then
            local plan = geometry.plan

            v25 = v6.resolve(plan, geometry.hits, fields.geometry_flags_1476)
        else
            v25 = v6.investigate(rt.copy(geometry.input), function(p17, p18) -- line: 250
                -- upvalues: p12 (copy), p13 (copy), p16 (copy)
                return p16.surface_probe(p16, p13, {
                    p12.actor_query_2948,
                    p12.actor_query_2952
                }, p17, p18)
            end)
        end

        v24 = v25
        v1.surface(fields, v25)

        local v26, v27 = v5.tweak_geometry({
            valid = fields.valid_1488,
            family = fields.family_1248,
            current_state = p12.state_2508,
            category = p12.category_2512,
            air_frames = p11.air_frames,
            geometry_kind = v25.kind,
            geometry_flags = v25.flags,
            far_points = rt.copy(v25.far_points),
            upmost = rt.copy(v25.upmost_normal),
            high_side = rt.copy(v25.high_side),
            point = float(fields.point_1120),
            direction = float(fields.direction_1136),
            board_position = rt.copy(p15.board[4]),
            board_forward = rt.copy(p15.board[3]),
            velocity = float(p12.vectors_400_416[1]),
            deck_to_truck = p11.settings.deck_to_truck,
            previous_exit_angle = p11.balance.exit_angle_degrees,
            previous_exit_direction = rt.copy(p11.balance.exit_direction),
            flags = fields.flags_1516
        }, p11.secondary_history)

        p11.secondary_history = v27
        fields.valid_1488 = v26.valid
        fields.family_1248 = v26.family
        fields.flags_1516 = v26.flags
    end

    local v28, v29 = v5.gravity_relief(p11.gravity_timer, fields.valid_1488, p12.category_2512, float(fields.tangent_1104), float(p12.vectors_400_416[1]), p12.timestep_2604, p11.settings.gravity_vertical, p11.settings.gravity_linear)

    p11.gravity_timer = v29
    fields.gravity_relief_1512 = v28

    local t6 = if v24 ~= nil and fields.valid_1488 then {
        surface = v24,
        primitive_direction = float(fields.tangent_1104),
        directed_grind_direction = float(fields.direction_1136),
        kind = fields.family_1248,
        entry_kind = t1.entry_kind(fields.entry_kind_1252)
    } else nil
    local t7 = {
        grind_normal = float(fields.normal_1152),
        target_up = float(fields.target_up_1168)
    }

    BalanceState.update_target_up(p11.balance, {
        category = p12.category_2512,
        previous_state = p12.state_2504,
        board_up = float(p12.vectors_544_560_592_608[1])
    }, t6, t7)
    fields.exit_lean_1500 = BalanceState.update_exit_lean(p11.balance, {
        category = p12.category_2512,
        current_state = p12.state_2508,
        grind_substate = p12.grind_words_2532_2536[2],
        timestep = p12.timestep_2604
    }, t6, p11.settings.exit_lean, t7)
    fields.normal_1152 = raw(t7.grind_normal)
    fields.target_up_1168 = raw(t7.target_up)
    fields.flags_1516 = BalanceState.update_force_exit(p11.balance, float(fields.point_1120), fields.flags_1516, function(p19) -- line: 330
        -- upvalues: p12 (copy), p13 (copy), p16 (copy)
        return p16.force_exit_line(p16, p13, {
            p12.actor_query_2948,
            p12.actor_query_2952
        }, p19)
    end)

    local v30 = Engagement.update(p11.engagement, {
        valid = fields.valid_1488,
        kind = fields.family_1248,
        category = p12.category_2512,
        previous_state_2504 = p12.state_2504,
        speed = p12.scalar_2652,
        balance_2720 = p15.balance_2720,
        direction = float(fields.direction_1136),
        normal = rt.copy(t7.grind_normal),
        up = float(p12.vectors_544_560_592_608[1]),
        board_velocity = float(p12.vectors_400_416[1]),
        air_velocity = float(p12.vectors_544_560_592_608[4]),
        surface_kind = fields.geometry_kind_1464,
        high_side = float(fields.high_side_1440),
        vertical_help = p11.settings.vertical_help,
        max_delta = p11.settings.max_impact,
        flags = fields.flags_1516,
        previous_entry_velocity = float(fields.entry_velocity_1184)
    })

    fields.valid_1488 = v30.valid
    fields.flags_1516 = v30.flags
    fields.entry_velocity_1184 = raw(v30.entry_velocity)
    fields.impact_speed_1492 = v30.impact_speed

    if #v30.wipeout_reasons ~= 0 then
        p12.flags_2468 = bit32.bor(p12.flags_2468, 262144)
    end

    Control.update(p11.control, if fields.valid_1488 then fields.family_1248 else 4294967295, rt.copy(p15.board[3]), rt.copy(t7.grind_normal), bit32.band(fields.flags_1516, 536870912) ~= 0, bit32.band(p12.flags_2468, 1048576) ~= 0, bit32.band(fields.flags_1516, 268435456) ~= 0, p15.translation_2796, p15.stability_nudge_2800, p15.up_down_2804, p15.grab_min_height_2808)
    fields.yaw_1504 = p11.control.yaw
    fields.pitch_1508 = p11.control.pitch

    local t8 = if fields.valid_1488 then {
        geometry_kind = fields.geometry_kind_1464,
        high_side = float(fields.high_side_1440),
        normal = rt.copy(t7.grind_normal),
        direction = float(fields.direction_1136),
        upmost = float(fields.upmost_normal_1408),
        point = float(fields.point_1120)
    } else nil

    p12.flags_2476 = bit32.bor(p12.flags_2476, Jumper.update(p11.jumper, t8, p12.grind_words_2532_2536[1]))
    p11.investigation = rt.copy(fields)
    p12.grind = rt.copy(fields)

    local v37 = v1.observation(p12, p15, metadata, p11.jumper)

    return {
        wipeout_reasons = v30.wipeout_reasons,
        observation = v37
    }
end

function t1.entry_kind(p20) -- line: 400
    -- upvalues: EntryKind (copy)
    if p20 == 0 then
        return EntryKind.RideFromAbove
    end

    if p20 == 1 then
        return EntryKind.RideFromBelow
    end

    if p20 == 2 then
        return EntryKind.RideIntoCoping
    end

    if p20 == 3 then
        return EntryKind.StayInGrind
    end

    if p20 == 4 then
        return EntryKind.ChangeGrind
    end

    if p20 == 5 then
        return EntryKind.AirToGrind
    end

    if p20 == 6 then
        return EntryKind.DropIn
    end

    error(string.format("Invalid published grind admission kind %d", p20), 0)
end

return t1
