-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")

require(sim.rt)

local import = require(sim.import)

local function board_manager() -- line: 13
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/board_manager")
end

local function board_manager_runtime() -- line: 16
    -- upvalues: import (copy)
    return import("skate_game/physics/offboard/board_manager/runtime")
end

return {
    update_possession = function(p1, p2) -- update_possession | line: 25
        -- upvalues: import (copy)
        local flags_2484 = p2.player_input.processed.flags_2484
        local state_448 = p2.skateboard_controller.fields.state_448
        local v1 = 5

        if bit32.band(flags_2484, 1) == 0 then
            if state_448 ~= 5 then
                return
            end

            v1 = 1
        elseif state_448 == 2 or state_448 == 3 or state_448 == 4 then
            return
        end

        p2.skateboard_controller.fields.word_444 = 0

        if state_448 == v1 then
            return
        end

        local v2 = import("skate_game/physics/offboard/board_manager/runtime")
        local LiveState = v2.LiveState
        local Owner = import("skate_game/physics/offboard/board_manager").Owner
        local v3 = v2.observe(p1, p2)
        local v4 = LiveState.effects(p2.board_possession_live, p1, p2.ground_lifecycle.board_animated_290, p2.player_input.processed.timestep_2604)

        if v1 == 5 then
            Owner.stop(p2.board_possession, p2.skateboard_controller.fields, v3, v4)
        else
            Owner.hold(p2.board_possession, p2.skateboard_controller.fields, v3, v4)
        end

        p2.ground_lifecycle.board_animated_290 = v4.animated_290
        p1.board_wiping_out = v4.wiping_out
        p2.board_possession_live.alignment_active = v4.alignment_active
        p2.skateboard_controller.fields.state_448 = v1
        LiveState.publish_volumes(p2.board_possession_live, p1)
    end
}
