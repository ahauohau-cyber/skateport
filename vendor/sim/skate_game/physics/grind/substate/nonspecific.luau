-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/physics/grind/substate/skeleton")
local v2 = import("skate_game/physics/grind/launch")
local v3 = import("skate_game/physics/grind/board")
local _ = import("skate_core/physics/board_runtime").BoardRuntime
local is_skateboard_animated = import("skate_core/player/selector/conditions").is_skateboard_animated
local v4 = import("skate_core/riding/anti_flip")
local TruckSteeringState = import("skate_core/riding/steering").TruckSteeringState

local function grind() -- line: 17
    -- upvalues: import (copy)
    return import("skate_game/physics/grind")
end

local function substate() -- line: 20
    -- upvalues: import (copy)
    return import("skate_game/physics/grind/substate")
end

local function ground_runtime() -- line: 24
    -- upvalues: import (copy)
    return import("skate_game/physics/ground_runtime")
end

local function skeleton_air() -- line: 27
    -- upvalues: import (copy)
    return import("skate_game/physics/skeleton_air")
end

return {
    execute = function(p1, p2) -- execute | line: 37
        -- upvalues: rt (copy), import (copy), v1 (copy), v2 (copy), v3 (copy), is_skateboard_animated (copy), v4 (copy), TruckSteeringState (copy)
        p2.grind.nonspecific_jumped = false

        local processed = p2.player_input.processed

        if bit32.band(processed.flags_2468, 4194304) == 0 then
            local v5 = is_skateboard_animated({
                mode_16420 = p2.skeleton_input.force_mode,
                back_chain_lane_12656 = p2.skeleton_input.drive_frames[1][3][2],
                threshold_800 = p2.grind.settings.substate.animated_board_threshold
            })
            local v6 = if v5 then bit32.band(processed.flags_2472, 4194304) == 0 else nil
            local v7 = if not v5 or v6 then v1.ground_target(p1, p2) else v1.animated_target(p1, p2)
            local processed2 = p2.player_input.processed
            local GroundSettings = import("skate_game/physics/ground_runtime").GroundSettings

            TruckSteeringState.update(p2.ground.steering, 0, GroundSettings.board(p2.ground_settings).steering.tilt_blending, processed2.flags_2468, processed2.flags_2472)
            import("skate_game/physics/skeleton_air").SkeletonAir.capture_physics_error(p2.skeleton_air, p1.board, v7)

            local toolkit = p2.player_input.toolkit

            if toolkit == nil then
                error("Nonspecific board update requires current BoardToolkit", 0)
            end

            local v8 = rt.map(processed2.vectors_544_560_592_608[1], rt.from_bits)
            local v9 = v4.calculate(rt.copy(GroundSettings.board(p2.ground_settings).anti_flip), {
                flags_2468 = processed2.flags_2468,
                balance = p2.animation_input.fields.balance,
                axis_96 = rt.copy(toolkit.deck[3]),
                axis_64 = rt.copy(toolkit.deck[1]),
                projection_axis_544 = rt.copy(v8)
            })

            import("skate_game/physics/ground_runtime").GroundRuntime.apply_angular_displacement(p2.ground_runtime, p1.board, v9)
            v3.apply_world_force(p1.board, {
                v8[1] * -40,
                v8[2] * -40,
                v8[3] * -40,
                v8[4] * -40
            }, toolkit.deck[4])
            import("skate_game/physics/grind/substate").collision_force(p1, p2)
        else
            if p2.player_input.toolkit == nil then
                error("Nonspecific pop requires current BoardToolkit", 0)
            end

            local v10 = rt.copy(p2.player_input.toolkit.deck[4])
            local t2 = {
                geometry_side_jump = 0.699999988079071,
                velocity_400 = rt.map(processed.vectors_400_416[1], rt.from_bits),
                position_112 = v10,
                current_point_1120 = rt.map(processed.grind.point_1120, rt.from_bits),
                balance_2800 = p2.animation_input.extra.grind_stability_nudge,
                vertical_jump = import("skate_game/physics/grind/substate").Settings.vertical(p2.grind.settings.substate, import("skate_game/physics/grind").Family.FiftyFifty, processed.state_variant_index_2528, p2.animation_input.extra.jump_strength)
            }
            local v11, v12 = v2.apply(p1.board, p2.player_input.grind.jumper, p2.player_input.processed.flags_2476, t2)

            p2.player_input.processed.flags_2476 = v12
            p2.grind.nonspecific_jump_velocity = rt.copy(v11)
            p2.grind.nonspecific_jumped = true
            v1.animated(p1, p2)
            import("skate_game/physics/ground_runtime").GroundRuntime.set_animated_velocity(p2.ground_runtime, p1.board, v11)
        end
    end
}
