-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local BodyId = import("skate_core/physics/board").BodyId
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime
local PhysicalStateId = import("skate_core/player/state").PhysicalStateId

local function parent() -- line: 17
    -- upvalues: import (copy)
    return import("skate_game/physics/player_state")
end

local function grab_scene() -- line: 21
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/grab_scene")
end

local function grab_runtime() -- line: 24
    -- upvalues: import (copy)
    return import("skate_game/physics/biped_ground/grab_runtime")
end

local v1 = false

return {
    set_reference = function(p1) -- set_reference | line: 31
        -- upvalues: v1 (ref)
        v1 = p1
    end,
    advance = function(p2, p3) -- advance | line: 36
        -- upvalues: rt (copy), import (copy), BodyId (copy), BoardRuntime (copy), PhysicalStateId (copy), v1 (ref)
        local PlayerState = import("skate_game/physics/player_state").PlayerState
        local player = p3.player_input.player

        player.state_count_1312 = rt.wrapping_add_u32(player.state_count_1312, 1)

        if not PhysicalStateId.is_grind(PlayerState.current(p3.player_state)) then
            local v2 = PlayerState.current(p3.player_state)

            if v2 ~= PhysicalStateId.PhysicsGround and v2 ~= PhysicalStateId.PhysicsAir and v2 ~= PhysicalStateId.PhysicsAirSecondary and v2 ~= PhysicalStateId.FootPlant and v2 ~= PhysicalStateId.Boneless and v2 ~= PhysicalStateId.HandPlant and v2 ~= PhysicalStateId.RevertGround and v2 ~= PhysicalStateId.KnownAir and v2 ~= PhysicalStateId.BipedAir and v2 ~= PhysicalStateId.BipedGround and v2 ~= PhysicalStateId.OffBoardPushing and v2 ~= PhysicalStateId.GroundAnimation and v2 ~= PhysicalStateId.SlideGround and v2 ~= PhysicalStateId.WipeoutGround and v2 ~= PhysicalStateId.Teleporting and v2 ~= PhysicalStateId.LandingOnDeck and v2 ~= PhysicalStateId.Nonspecific then
                error("PreState requires the selected state's actual PredictFutureOfDeck", 0)
            end
        end

        local v3, v4, v5

        if v1 then
            local v6 = BoardRuntime.part_transforms(p2.board)[BodyId.index(BodyId.Deck) + 1]

            v3 = v6.translation.x
            v4 = v6.translation.y
            v5 = v6.translation.z
        else
            v3, v4, v5 = BoardRuntime.part_translation(p2.board, BodyId.index(BodyId.Deck))
        end

        local roots = p3.animated_skeleton.roots

        if v1 then
            local v7 = rt.copy(BoardRuntime.bodies(p2.board)[BodyId.index(BodyId.Deck) + 1].rates.linear_velocity)
            local timestep_2604 = p3.player_input.processed.timestep_2604
            local t2 = {
                v7.x * timestep_2604 + v3,
                v7.y * timestep_2604 + v4,
                v7.z * timestep_2604 + v5,
                0
            }

            roots.predicted_board_position = rt.copy(t2)
            roots.supplied_prediction = rt.copy(t2)
        else
            local linear_velocity = BoardRuntime.bodies(p2.board)[BodyId.index(BodyId.Deck) + 1].rates.linear_velocity
            local timestep_2604 = p3.player_input.processed.timestep_2604
            local v8 = linear_velocity.x * timestep_2604 + v3
            local v9 = linear_velocity.y * timestep_2604 + v4
            local v10 = linear_velocity.z * timestep_2604 + v5

            roots.predicted_board_position = { v8, v9, v10, 0 }
            roots.supplied_prediction = { v8, v9, v10, 0 }
        end

        p3.foot_ik.state.contacts.support_failed = false

        local processed = p3.player_input.processed
        local t3 = {
            selection_flags_2948 = processed.actor_query_2948,
            matching_id_2952 = rt.to_i32(processed.actor_query_2952)
        }
        local v11 = import("skate_game/physics/offboard/grab_scene").Scene.new(p2.world, p2.offboard_grab_scene)

        import("skate_game/physics/biped_ground/grab_runtime").Owner.sync(p3.offboard_grab, v11, t3)
    end
}
