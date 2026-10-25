-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/physics/grind/substate/nonspecific")
local v2 = import("skate_game/physics/grind/substate/settings")
local v3 = import("skate_game/physics/grind/substate/skeleton")
local v4 = import("skate_game/physics/grind/contact")
local v5 = import("skate_game/physics/grind/involuntary")
local v6 = import("skate_game/physics/grind/launch")
local Vector3 = import("skate_core/math").Vector3
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime
local BoardForceQueue = import("skate_core/physics/force_queue").BoardForceQueue
local collision_response = import("skate_core/riding/collision_response").collision_response

local function input_phase() -- line: 21
    -- upvalues: import (copy)
    return import("skate_game/physics/input_phase")
end

local function ground_runtime() -- line: 24
    -- upvalues: import (copy)
    return import("skate_game/physics/ground_runtime")
end

local t1 = {
    execute_nonspecific = v1.execute,
    Settings = v2.Settings
}

function t1.execute(p1, p2, p3) -- line: 41
    -- upvalues: rt (copy), import (copy), v2 (copy), v3 (copy), v4 (copy), v5 (copy), v6 (copy), t1 (copy)
    local active = p2.grind.active

    if active == nil then
        error("Grind substate requires active physical family", 0)
    end

    local v7 = rt.copy(p2.grind.states[active + 1])
    local v8 = t1.collision_force(p1, p2)
    local v9

    if v8 ~= nil then
        v9 = false
    elseif bit32.band(p2.player_input.processed.flags_2468, 4194304) == 0 then
        if v7.already_jumped then
            v8 = nil
        elseif bit32.band(p2.player_input.processed.grind.flags_1516, 1073741824) == 0 then
            if v7.output.substate == 1 then
                v4.advance(p1, p2, p3)
            elseif v7.output.substate == 2 then
                v5.advance(p1, p2, p3)
            end

            v8 = nil
        else
            v8 = rt.map(p2.player_input.processed.grind.entry_velocity_1184, rt.from_bits)
            import("skate_game/physics/ground_runtime").GroundRuntime.set_animated_velocity(p2.ground_runtime, p1.board, v8)
        end

        v9 = false
    else
        local processed = p2.player_input.processed

        if p2.player_input.toolkit == nil then
            error("Grind pop requires current BoardToolkit", 0)
        end

        local v10 = rt.copy(p2.player_input.toolkit.deck[4])
        local v11 = v2.Settings.vertical(p2.grind.settings.substate, active, processed.state_variant_index_2528, p2.animation_input.extra.jump_strength)
        local v12 = v2.side(active, processed.grind.geometry_kind_1464)
        local t2 = {
            velocity_400 = rt.map(processed.vectors_400_416[1], rt.from_bits),
            position_112 = v10,
            current_point_1120 = rt.map(processed.grind.point_1120, rt.from_bits),
            balance_2800 = p2.animation_input.extra.grind_stability_nudge,
            geometry_side_jump = v12,
            vertical_jump = v11
        }
        local v13

        v8, v13 = v6.apply(p1.board, p2.player_input.grind.jumper, p2.player_input.processed.flags_2476, t2)
        p2.player_input.processed.flags_2476 = v13

        local v14 = p2.grind.states[active + 1]

        v14.already_jumped = true
        v14.output.just_jumped = true
        v9 = true
        v14.output.jump_velocity = rt.copy(v8)
    end

    if v8 ~= nil then
        if p2.player_input.toolkit == nil then
            error("Grind prediction requires current BoardToolkit", 0)
        end

        local v15 = rt.copy(p2.player_input.toolkit.deck[4])
        local timestep_2604 = p2.player_input.processed.timestep_2604
        local t3 = {
            v8[1] * timestep_2604 + v15[1],
            v8[2] * timestep_2604 + v15[2],
            v8[3] * timestep_2604 + v15[3],
            v8[4] * timestep_2604 + v15[4]
        }

        p2.animated_skeleton.roots.predicted_board_position = rt.copy(t3)
        p2.animated_skeleton.roots.supplied_prediction = t3
    end

    if v9 then
        v3.animated(p1, p2)
    else
        import("skate_game/physics/input_phase").update_ground(p1, p2)
    end
end

function t1.collision_force(p4, p5) -- line: 137
    -- upvalues: rt (copy), Vector3 (copy), BoardRuntime (copy), BoardForceQueue (copy), collision_response (copy)
    local processed, toolkit = p5.player_input.processed, p5.player_input.toolkit

    if toolkit == nil then
        error("Grind collision requires current BoardToolkit", 0)
    end

    local ground_normal = p4.riding.reckoning.ground_normal
    local v16 = collision_response(p5.grind.settings.substate.collision, {
        flags_2472 = processed.flags_2472,
        collision_displacement = rt.map(processed.collision_pose_error_736, rt.from_bits),
        velocity = rt.map(processed.vectors_400_416[2], rt.from_bits),
        forward = rt.copy(toolkit.travel_direction),
        up = rt.map(processed.vectors_544_560_592_608[1], rt.from_bits),
        ground_normal = {
            ground_normal.x,
            ground_normal.y,
            ground_normal.z,
            0
        },
        time_step = processed.timestep_2604,
        mass = toolkit.total_mass
    })

    if v16 == nil or not v16.applied then
        return nil
    end

    local function xyz(p6) -- line: 157
        -- upvalues: Vector3 (copy)
        return Vector3.new(p6[1], p6[2], p6[3])
    end

    local append = BoardForceQueue.append
    local v17 = BoardRuntime.forces_mut(p4.board)
    local t4 = {
        tag = 15
    }
    local force = v16.force

    t4.force_world = Vector3.new(force[1], force[2], force[3])

    local point = v16.point

    t4.point_body = Vector3.new(point[1], point[2], point[3])
    append(v17, t4)

    return v16.target_velocity
end

return t1
