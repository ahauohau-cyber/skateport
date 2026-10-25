-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local dot3 = import("skate_game/physics/grind/arithmetic").dot3
local v1 = import("skate_game/physics/grind/substate")
local v2 = import("skate_core/physics/grind_forces/reckoning")
local Requests = import("skate_core/player/wipeout").Requests
local TruckSteeringState = import("skate_core/riding/steering").TruckSteeringState

local function grind() -- line: 15
    -- upvalues: import (copy)
    return import("skate_game/physics/grind")
end

local t1 = {}

function t1.advance(p1, p2) -- line: 24
    -- upvalues: rt (copy), import (copy), dot3 (copy), v1 (copy), Requests (copy), TruckSteeringState (copy), t1 (copy)
    if p2.grind.nonspecific_active then
        v1.execute_nonspecific(p1, p2)

        local toolkit = p2.player_input.toolkit

        if toolkit == nil then
            error("701 requires BoardToolkit", 0)
        end

        local v3 = rt.copy(toolkit.deck)
        local v4 = if bit32.band(p2.player_input.processed.flags_2484, 2097152) == 0 then 1 else -1

        t1.reckon(p1, p2, {
            v3[2][1] * v4,
            v3[2][2] * v4,
            v3[2][3] * v4,
            v3[2][4] * v4
        }, rt.copy(v3[3]), 0.98)
    else
        local Family = import("skate_game/physics/grind").Family
        local active = p2.grind.active

        if active == nil then
            error("Grind Update requires active family", 0)
        end

        if p2.grind.manager == nil then
            error("Grind Update requires manager observation", 0)
        end

        local v5 = rt.copy(p2.grind.manager)
        local toolkit = p2.player_input.toolkit

        if toolkit == nil then
            error("Grind Update requires BoardToolkit", 0)
        end

        local v6 = rt.copy(toolkit.deck)
        local scalar_2652 = p2.player_input.processed.scalar_2652
        local v7 = p2.grind.states[active + 1]

        v7.output.just_jumped = false

        local v8 = v7.output.tipslide_97_98_99[1]
        local v9

        if v8 then
            v9 = rt.copy(v6[2])
        else
            v7.output.direction = rt.copy(v5.geometry.direction_1136)
            v7.output.normal = rt.copy(v5.geometry.normal_1152)
            v7.output.across = t1.cross(v7.output.direction, v7.output.normal)
            v9 = rt.copy(v5.geometry.target_up_1168)
        end

        local v10 = not (not v8 and v5.surface.reckon_blend_selector_1500 > 0) and 0.7 or 0.9

        t1.reckon(p1, p2, v9, rt.copy(v6[3]), v10)

        local v11 = p2.grind.states[active + 1]
        local v12 = bit32.band(p2.player_input.processed.flags_2476, 536870912) ~= 0 and (not (active == Family.Boardslide or active == Family.Darkslide) or v5.geometry.kind_1464 == 2)
        local v13, v14

        if v5.engagement.kind_1248 == 2 then
            if bit32.band(v5.geometry.flags_1476, 134217728) == 0 then
                if bit32.band(v5.control.flags_2488, 268435456) == 0 then
                    v14 = false
                elseif scalar_2652 < 1 then
                    v13 = true
                    v14 = true
                else
                    v14 = false
                end
            elseif scalar_2652 < 1 then
                v13 = true
                v14 = true
            else
                v14 = false
            end
        else
            v14 = false
        end

        if not v14 then
            v13 = rt.to_i32(v5.control.flags_1516) < 0 or v12 or v11.updates > 60 and scalar_2652 < 0.15
        end

        if v11.output.substate == 1 and v13 then
            v11.output.substate = 2
        end

        v1.execute(p1, p2, v5)

        local v15 = p2.grind.states[active + 1]

        if v15.output.substate == 2 then
            v15.leaving_updates = rt.to_i32(rt.wrapping_add_u32(rt.to_u32(v15.leaving_updates), 1))
        else
            v15.leaving_updates = 0
        end

        if v15.leaving_updates > 35 then
            Requests.request(p2.wipeout.state, 17, 0)
        end

        v15.output.crouch = math.abs((dot3(v6[3], v15.output.normal))) * 0.4

        local processed = p2.player_input.processed

        TruckSteeringState.update(p2.ground.steering, 0, p2.air_settings.steering_blend, processed.flags_2468, processed.flags_2472)

        local v17 = rt.map(processed.vectors_400_416[1], rt.from_bits)

        p2.skeleton_input.head_tracking_history[6] = {
            v17[1] * p2.grind.settings.look_ahead + v5.geometry.point_1120[1],
            v17[2] * p2.grind.settings.look_ahead + v5.geometry.point_1120[2],
            v17[3] * p2.grind.settings.look_ahead + v5.geometry.point_1120[3],
            v17[4] * p2.grind.settings.look_ahead + v5.geometry.point_1120[4]
        }
        p2.skeleton_input.head_tracking_active = true
        v15.updates = rt.to_i32(rt.wrapping_add_u32(rt.to_u32(v15.updates), 1))
    end
end

function t1.reckon(p3, p4, p5, p6, p7) -- line: 130
    -- upvalues: v2 (copy)
    v2.update(p3.riding.reckoning, p3.riding.reckoning_frames, p3.riding.body_spin, p4.air_reckoning.state, p4.grind.settings.reckoning, p5, p6, p7, bit32.band(p4.player_input.processed.flags_2468, 1048576) ~= 0, 0)
end

function t1.cross(p8, p9) -- line: 145
    return {
        -p8[3] * p9[2] + p8[2] * p9[3],
        -p8[1] * p9[3] + p8[3] * p9[1],
        -p8[2] * p9[1] + p8[1] * p9[2],
        0
    }
end

return t1
