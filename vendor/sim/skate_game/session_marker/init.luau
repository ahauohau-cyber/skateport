-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)

import("skate_game/session_marker/effect")
import("skate_game/session_marker/hud")

local v1 = import("skate_game/session_marker/state")
local v2 = import("skate_game/session_marker/validation")
local ControllerInput = import("skate_game/input").ControllerInput
local v3 = import("skate_game/physics")
local PlayerInputRuntime = import("skate_game/physics/player_input").PlayerInputRuntime
local Runtime = import("skate_game/physics/teleport_state").Runtime
local SkaterAnimation = import("skate_game/skater_animation").SkaterAnimation
local BodyId = import("skate_core/physics/board").BodyId
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime

local function graphics_menu() -- line: 21
    -- upvalues: import (copy)
    return import("skate_game/graphics_menu")
end

local Hold = v1.Hold
local Validation = v2.Validation
local v4 = false
local t1 = {
    Marker = {},
    SessionMarker = {}
}

function t1.SessionMarker.default() -- line: 54
    -- upvalues: Hold (copy)
    return {
        marker = nil,
        generation = 0,
        visible = false,
        can_place = false,
        can_return = false,
        progress = 0,
        blocked_until_release = false,
        ui_time = 0,
        last_batch = 0,
        hold = Hold.default()
    }
end

t1.SessionMarkerPlugin = {}

function t1.SessionMarkerPlugin.build(p1) -- line: 80
    -- upvalues: Validation (copy), t1 (copy)
    local load = Validation.load
    local ok, result = pcall(load, p1)

    if ok then
        return result, t1.SessionMarker.default()
    end

    return nil
end

function t1.suspend(p2, p3, p4, p5, p6) -- line: 92
    -- upvalues: rt (copy), import (copy), Hold (copy), t1 (copy)
    if p2.generation ~= p3.generation then
        local v5 = t1.SessionMarker.default()

        v5.generation = p3.generation
        v5.blocked_until_release = true
        rt.assign(p2, v5)
    end

    if import("skate_game/graphics_menu").gameplay_active(p4) and not p5.active then
        if not p2.blocked_until_release then
            p2.ui_time += p6
        end

        return
    end

    Hold.cancel(p2.hold)
    p2.visible = false
    p2.progress = 0
    p2.blocked_until_release = true
    p2.ui_time = 0
end

function t1.update(p7, p8, p9, p10, p11, p12, p13) -- line: 116
    -- upvalues: rt (copy), ControllerInput (copy), v3 (copy), PlayerInputRuntime (copy), Runtime (copy), SkaterAnimation (copy), BodyId (copy), BoardRuntime (copy), Hold (copy), Validation (copy), v4 (ref)
    if p13.active then
        return
    end

    local v6, v7, v8 = ControllerInput.session_marker_actions(p8)

    if not p7.blocked_until_release then
        local physical, processed = p11.player_input.physical, p11.player_input.processed
        local v9 = physical.state.category_12 ~= 500
        local state_16 = physical.state.state_16
        local v10

        if v4 or v6 then
            local v11 = rt.copy(BoardRuntime.part_transforms(p10.board)[BodyId.index(BodyId.Deck) + 1])
            local v12 = rt.copy(p11.animated_skeleton.roots.animation_to_world)

            if v9 then
                for i = 0, 2 do
                    v12[i + 1][1] = v11.basis.columns[i + 1][1]
                    v12[i + 1][2] = v11.basis.columns[i + 1][2]
                    v12[i + 1][3] = v11.basis.columns[i + 1][3]
                end

                v12[4] = {
                    v11.translation.x,
                    v11.translation.y + 0.2,
                    v11.translation.z,
                    0
                }
            end

            v10 = v3.facing_from_visual(v12, processed.flags_2468, processed.flags_2476, v9)

            local v13, v14

            if physical.state.category_12 ~= 100 or not (physical.collision.wheel_count_0 >= 2) or state_16 == 104 then
                v14 = false
            elseif v11.basis.columns[2][2] > 0.71 then
                v13 = true
                v14 = true
            else
                v14 = false
            end

            if not v14 then
                v13 = physical.state.category_12 == 500 and state_16 == 500
            end

            if v6 then
                if v13 then
                    v13 = physical.surface_default_mode ~= 8 and Validation.check(p12, v3.GamePhysics.world(p10), v10[4])
                end
            else
                v13 = v6
            end

            p7.can_place = v13
        else
            p7.can_place = false
        end

        local marker = p7.marker
        local v15, v16

        if marker ~= nil then
            if marker.generation == p9.generation then
                v15 = state_16 == 104 or state_16 == 502
                v16 = not v15
            else
                v16 = false
            end
        else
            v16 = false
        end

        p7.can_return = v16
        p7.visible = v6

        if v7 and p7.last_batch ~= p8.consumed_batches and p7.can_place then
            p7.marker = {
                transform = rt.copy(v10),
                on_board = v9,
                foot_forward = SkaterAnimation.foot_forward(p11.animation),
                generation = p9.generation
            }
        end

        p7.last_batch = p8.consumed_batches

        local v17, v18

        if physical.state.flag_69 ~= 0 or state_16 == 702 then
            v18 = false
        else
            v17 = p10.board_wiping_out and physical.skeleton.teleport_pending_604 ~= 0
            v18 = not v17 and PlayerInputRuntime.pending_teleport(p11.player_input) == nil
        end

        local marker2 = p7.marker
        local v19 = 0

        if marker2 ~= nil then
            local v20 = p11.animated_skeleton.roots.animation_to_world[4]
            local v21 = marker2.transform[4]
            local v22 = v20[1] - v21[1]
            local v23 = v20[2] - v21[2]
            local v24 = v20[3] - v21[3]

            v19 = math.sqrt(v22 * v22 + v23 * v23 + v24 * v24)
        end

        local can_return = p7.can_return

        while p7.ui_time >= 0.016666666666666666 do
            p7.ui_time -= 0.016666666666666666

            local v26 = Hold.update(p7.hold, v8, can_return, v19, v18)

            p7.progress = v26.progress

            if v26.relocate then
                local v27 = rt.copy(p7.marker)

                if v27 ~= nil then
                    local request_teleport = PlayerInputRuntime.request_teleport
                    local player_input = p11.player_input
                    local copy = rt.copy
                    local transform = v27.transform

                    if pcall(request_teleport, player_input, copy(transform)) then
                        SkaterAnimation.restore_foot_forward(p11.animation, v27.foot_forward)
                        Runtime.request_manual(p11.teleport_state, v27.transform, v27.on_board)
                    else
                        Hold.cancel(p7.hold)
                    end
                end
            end
        end
    elseif not v6 then
        p7.blocked_until_release = false
    end
end

function t1.update_reference(p14, p15, p16, p17, p18, p19, p20) -- line: 226
    -- upvalues: v4 (ref), t1 (copy)
    local v28 = v4

    v4 = true

    local update = t1.update
    local ok, result = pcall(update, p14, p15, p16, p17, p18, p19, p20)

    v4 = v28

    if not ok then
        error(result, 0)
    end
end

return t1
