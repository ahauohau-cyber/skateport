-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local dot3 = import("skate_game/physics/grind/arithmetic").dot3
local v1 = import("skate_game/physics/grind/forces")
local v2 = import("skate_game/physics/grind/lifecycle")
local v3 = import("skate_game/physics/grind/tip_nudge")
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime
local HookDriveState = import("skate_core/physics/hook_drive").HookDriveState
local Requests = import("skate_core/player/wipeout").Requests

local function grind() -- line: 17
    -- upvalues: import (copy)
    return import("skate_game/physics/grind")
end

return {
    advance = function(p1, p2, p3) -- advance | line: 25
        -- upvalues: rt (copy), import (copy), dot3 (copy), v1 (copy), v2 (copy), v3 (copy), BoardRuntime (copy), HookDriveState (copy), Requests (copy)
        local Family = import("skate_game/physics/grind").Family
        local active = p2.grind.active

        if active == nil then
            error("Grind exit requires active family", 0)
        end

        if p2.player_input.toolkit == nil then
            error("Grind exit requires BoardToolkit", 0)
        end

        local v4 = rt.copy(p2.player_input.toolkit.deck)
        local v5 = p2.grind.states[active + 1]
        local kind_1464 = p3.geometry.kind_1464
        local t2 = {
            force_across = false,
            enable_lift = true,
            strength = 100,
            speed_limit = 1,
            lift = 125,
            position = rt.copy(v4[4]),
            point = rt.copy(p3.geometry.point_1120),
            across = rt.copy(v5.output.across),
            normal = rt.copy(v5.output.normal),
            velocity = rt.map(p2.player_input.processed.vectors_400_416[1], rt.from_bits),
            geometry_kind = kind_1464,
            high_side = rt.copy(p3.geometry.high_side_1440)
        }

        if active == Family.Boardslide or active == Family.Darkslide then
            if kind_1464 == 2 then
                t2.strength = 90
                t2.speed_limit = 0.75
                t2.enable_lift = false
                v1.release(p1.board, rt.copy(t2))
            else
                v5.output.slide_wipeout = true

                local direction_1136 = p3.geometry.direction_1136

                v5.output.slide_impulse = {
                    direction_1136[1] * 136,
                    direction_1136[2] * 136,
                    direction_1136[3] * 136,
                    direction_1136[4] * 136
                }
                Requests.request(p2.wipeout.state, 10, 0)
            end

            v2.clear_wheel_spin(p1.board)
        elseif active == Family.FiftyFifty then
            if kind_1464 >= 2 then
                t2.strength = 10
                t2.lift = 0
            end

            v1.release(p1.board, rt.copy(t2))
        elseif active == Family.FiveO then
            t2.strength = kind_1464 < 2 and 120 or 10
            t2.lift = kind_1464 < 2 and 125 or 0
            t2.speed_limit = 0.9
            t2.force_across = kind_1464 == 1 and math.abs((dot3(v4[3], t2.across))) > 0.23
            v1.release(p1.board, rt.copy(t2))
        elseif active == Family.Backslash then
            t2.speed_limit = 0.75
            t2.force_across = kind_1464 == 1
            t2.enable_lift = kind_1464 == 1
            v1.release(p1.board, rt.copy(t2))
            v2.clear_wheel_spin(p1.board)
        elseif active == Family.Tipslide then
            v2.clear_wheel_spin(p1.board)

            local flags_1476 = p3.geometry.flags_1476

            if bit32.band(flags_1476, 134217728) ~= 0 or v5.output.tipslide_97_98_99[1] then
                if not v5.output.tipslide_97_98_99[1] then
                    p2.ground_lifecycle.board_animated_290 = HookDriveState.disable_animation(BoardRuntime.hook_mut(p1.board).drive, p2.ground_lifecycle.board_animated_290)
                    v5.output.tipslide_97_98_99[1] = true
                    v5.output.tipslide_97_98_99[3] = true
                end

                v3.apply(p1.board, t2.position, t2.point, t2.across)
            else
                p2.ground_lifecycle.board_animated_290 = HookDriveState.enable_angular_only(BoardRuntime.hook_mut(p1.board).drive, p2.ground_lifecycle.board_animated_290)
                t2.speed_limit = 1.5
                t2.force_across = true
                t2.enable_lift = false
                v1.release(p1.board, rt.copy(t2))
                v5.output.tipslide_97_98_99[2] = true

                if bit32.band(p3.control.flags_2488, 268435456) ~= 0 then
                    v5.output.tipslide_97_98_99[3] = true
                end
            end
        end
    end
}
