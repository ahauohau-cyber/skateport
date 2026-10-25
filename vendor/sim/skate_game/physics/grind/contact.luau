-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local dot3 = import("skate_game/physics/grind/arithmetic").dot3
local apply_world_force = import("skate_game/physics/grind/board").apply_world_force
local v1 = import("skate_game/physics/grind/forces")
local v2 = import("skate_game/physics/grind/lifecycle")
local Vector3 = import("skate_core/math").Vector3
local BoardRuntime = import("skate_core/physics/board_runtime").BoardRuntime
local HookDriveState = import("skate_core/physics/hook_drive").HookDriveState
local v3 = import("skate_core/physics/grind_forces/noise")
local v4 = import("skate_core/physics/grind_forces/orientation")
local v5 = import("skate_core/physics/grind_forces/support")

local function grind() -- line: 21
    -- upvalues: import (copy)
    return import("skate_game/physics/grind")
end

local t1 = {
    Op = {}
}

function t1.advance(p1, p2, p3) -- line: 37
    -- upvalues: rt (copy), import (copy), dot3 (copy), apply_world_force (copy), v1 (copy), v2 (copy), Vector3 (copy), BoardRuntime (copy), HookDriveState (copy), v3 (copy), v4 (copy), v5 (copy), t1 (copy)
    local Family = import("skate_game/physics/grind").Family
    local active = p2.grind.active

    if active == nil then
        error("Grind contact requires active family", 0)
    end

    if p2.player_input.toolkit == nil then
        error("Grind contact requires board toolkit", 0)
    end

    local v6 = rt.copy(p2.player_input.toolkit)
    local v7 = rt.copy(v6.deck)
    local processed = p2.player_input.processed
    local v8 = rt.map(processed.vectors_400_416[1], rt.from_bits)
    local v9 = rt.copy(p2.grind.states[active + 1])
    local v10 = rt.copy(v7[4])
    local v11 = rt.copy(v9.output.normal)
    local v12 = rt.copy(v9.output.across)
    local v13 = rt.copy(v9.output.direction)
    local v14 = table.create(8)

    if active == Family.Darkslide or active == Family.Boardslide then
        v14 = {
            {
                tag = "Orient"
            },
            {
                tag = "Translate"
            },
            {
                tag = "Pin"
            },
            {
                tag = "Friction",
                { 55, 55, 60 }
            },
            {
                tag = "Coping"
            },
            {
                tag = "ExitLean"
            },
            {
                tag = "Wheels"
            }
        }
    elseif active == Family.FiftyFifty then
        v14 = {
            {
                tag = "Friction",
                { 50, 40, 40 }
            },
            {
                tag = "Align",
                800, 0, 0.07
            },
            {
                tag = "Coping"
            },
            {
                tag = "Pin"
            },
            {
                tag = "ExitLean"
            },
            {
                tag = "Orient"
            }
        }
    elseif active == Family.Tipslide then
        v14 = {
            {
                tag = "Orient"
            },
            {
                tag = "TipStability"
            },
            {
                tag = "Friction",
                { 60, 60, 60 }
            },
            {
                tag = "Coping"
            },
            {
                tag = "Pin"
            },
            {
                tag = "ExitLean"
            },
            {
                tag = "Wheels"
            }
        }
    elseif active == Family.FiveO then
        v14 = {
            {
                tag = "Orient"
            },
            {
                tag = "Align",
                3000, 0.234, 0.07
            },
            {
                tag = "Pin"
            },
            {
                tag = "Friction",
                { 50, 40, 40 }
            },
            {
                tag = "Coping"
            },
            {
                tag = "ExitLean"
            }
        }
    elseif active == Family.Backslash then
        v14 = {
            {
                tag = "Orient"
            },
            {
                tag = "Align",
                3000, 0.39, 0.025
            },
            {
                tag = "Friction",
                { 70, 80, 80 }
            },
            {
                tag = "Coping"
            },
            {
                tag = "Pin"
            },
            {
                tag = "ExitLean"
            },
            {
                tag = "Wheels"
            }
        }
    end

    for _, v15 in ipairs(v14) do
        local tag = v15.tag

        if tag == "Orient" then
            local v16 = v4.target(active, {
                board = rt.copy(v7),
                direction = rt.copy(v13),
                normal = rt.copy(v11),
                point = rt.copy(p3.geometry.point_1120),
                yaw_1504 = processed.grind.yaw_1504,
                pitch_1508 = processed.grind.pitch_1508,
                switched = bit32.band(processed.flags_2468, 1048576) ~= 0
            })
            local v17 = v4.blend(rt.copy(v7), v16.frame)

            if v16.noise_amount > 0 then
                local v18 = import("skate_game/physics/grind").Runtime.take_orientation_noise(p2.grind)

                v17 = v3.apply(v17, processed.scalar_2652, v16.noise_amount, v18)
            end

            v9.frame = v17
            BoardRuntime.set_hook_transform(p1.board, {
                basis = {
                    columns = {
                        {
                            v9.frame[1][1],
                            v9.frame[1][2],
                            v9.frame[1][3]
                        },
                        {
                            v9.frame[2][1],
                            v9.frame[2][2],
                            v9.frame[2][3]
                        },
                        {
                            v9.frame[3][1],
                            v9.frame[3][2],
                            v9.frame[3][3]
                        }
                    }
                },
                translation = Vector3.new(v9.frame[4][1], v9.frame[4][2], v9.frame[4][3])
            })
            p2.ground_lifecycle.board_animated_290 = HookDriveState.enable_angular_only(BoardRuntime.hook_mut(p1.board).drive, p2.ground_lifecycle.board_animated_290)

            if active == Family.FiveO or active == Family.FiftyFifty then
                apply_world_force(p1.board, v5.truck_compensation(v11, processed.grind.pitch_1508), v10)
            end
        elseif tag == "Friction" then
            local v19 = v15[1]

            v1.friction(p1.board, p3, v10, v8, v11, v19)
        elseif tag == "Align" then
            local v20 = v15[1]
            local v21 = v15[2]
            local v22 = v15[3]

            v1.lateral_pin(p1.board, p3, v7, v12, v11, v8, v20, v21, v22, p2.grind.settings.pin_vs_slope)
        elseif tag == "Pin" then
            local v23 = v5.pin(v11, p3.surface.gravity_relief_1512)

            if v23 ~= nil then
                apply_world_force(p1.board, v23, v10)
            end
        elseif tag == "Coping" then
            local v24 = v5.coping(p3.geometry.upmost_normal_1408, v8, p3.surface.gravity_relief_1512)

            if v24 ~= nil then
                apply_world_force(p1.board, v24, v10)
            end
        elseif tag == "ExitLean" then
            local v25 = v5.exit_lean(p3.geometry.high_side_1440, p3.surface.reckon_blend_selector_1500, p2.grind.settings.exit_assist)

            if v25 ~= nil then
                apply_world_force(p1.board, v25, v10)
            end
        elseif tag == "Wheels" then
            v2.manage_wheel_spin(p1.board, {
                p1.riding.ground.parts[1].in_contact,
                p1.riding.ground.parts[2].in_contact,
                p1.riding.ground.parts[3].in_contact,
                p1.riding.ground.parts[4].in_contact
            })
        elseif tag == "Translate" then
            v9.preparing_jump = v9.preparing_jump or bit32.band(processed.flags_2468, 2097152) ~= 0
            v1.slide(p1.board, active == Family.Darkslide and "Darkslide" or "Boardslide", {
                position = rt.copy(v10),
                point = rt.copy(p3.geometry.point_1120),
                direction = rt.copy(v13),
                across = rt.copy(v12),
                velocity = rt.copy(v8),
                translation_2796 = p3.control.translation_2796,
                total_mass_2660 = v6.total_mass,
                update_frequency = p1.settings.step.simulation.frequency,
                preparing_jump = v9.preparing_jump,
                geometry_kind = p3.geometry.kind_1464
            })
        elseif tag == "TipStability" then
            local v26 = t1.sub(v10, p3.geometry.point_1120)
            local v27 = t1.scale(v12, if dot3(v12, v26) > 0 then -1 else 1)
            local v28 = if bit32.band(p3.control.flags_1516, 33554432) == 0 then (if dot3(v11, t1.cross(v13, v26)) > 0 then p3.control.balance_2800 else -p3.control.balance_2800) * 37 else 39

            apply_world_force(p1.board, t1.scale(v27, v28), v10)
        end
    end

    if active == Family.Darkslide then
        if p3.geometry.kind_1464 == 2 then
            if dot3(p3.geometry.high_side_1440, v6.effective[3]) > 0 then
                v9.output.classification_104 = 2
            else
                v9.output.classification_104 = 1
            end
        elseif dot3(t1.scale(v12, dot3(t1.sub(v10, p3.geometry.point_1120), v12)), v6.effective[3]) > 0 then
            v9.output.classification_104 = 1
        else
            v9.output.classification_104 = 2
        end
    end

    p2.grind.states[active + 1] = v9
end

function t1.scale(p4, p5) -- line: 243
    return {
        p4[1] * p5,
        p4[2] * p5,
        p4[3] * p5,
        p4[4] * p5
    }
end

function t1.sub(p6, p7) -- line: 247
    return {
        p6[1] - p7[1],
        p6[2] - p7[2],
        p6[3] - p7[3],
        p6[4] - p7[4]
    }
end

function t1.cross(p8, p9) -- line: 251
    return {
        -p8[3] * p9[2] + p8[2] * p9[3],
        -p8[1] * p9[3] + p8[3] * p9[1],
        -p8[2] * p9[1] + p8[1] * p9[2],
        0
    }
end

return t1
