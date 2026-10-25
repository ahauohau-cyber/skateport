-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local ManualCam = import("skate_core/camera").ManualCam
local GameplayActions = import("skate_core/input/gameplay_map").GameplayActions

local function physics_mod() -- line: 18
    -- upvalues: import (copy)
    return import("skate_game/physics")
end

local function input_mod() -- line: 21
    -- upvalues: import (copy)
    return import("skate_game/input")
end

local function graphics_menu() -- line: 24
    -- upvalues: import (copy)
    return import("skate_game/graphics_menu")
end

local t1 = {
    DPAD_RIGHT = 8,
    R3 = 128,
    B = 8192
}
local DPAD_RIGHT, R3, B = t1.DPAD_RIGHT, t1.R3, t1.B
local manual_actions_from_raw

local function glam_quat_from_rotation_axes(p1, p2, p3) -- line: 40
    local v1 = p1[1]
    local v2 = p1[2]
    local v3 = p1[3]
    local v4 = p2[1]
    local v5 = p2[2]
    local v6 = p2[3]
    local v7 = p3[1]
    local v8 = p3[2]
    local v9 = p3[3]

    if v9 <= 0 then
        local v10 = v5 - v1
        local v11 = 1 - v9

        if v10 <= 0 then
            local v12 = v11 - v10
            local v13 = 0.5 / math.sqrt(v12)

            return {
                v12 * v13,
                (v2 + v4) * v13,
                (v3 + v7) * v13,
                (v6 - v8) * v13
            }
        end

        local v14 = v11 + v10
        local v15 = 0.5 / math.sqrt(v14)

        return {
            (v2 + v4) * v15,
            v14 * v15,
            (v6 + v8) * v15,
            (v7 - v3) * v15
        }
    end

    local v16 = v5 + v1
    local v17 = 1 + v9

    if v16 <= 0 then
        local v18 = v17 - v16
        local v19 = 0.5 / math.sqrt(v18)

        return {
            (v3 + v7) * v19,
            (v6 + v8) * v19,
            v18 * v19,
            (v2 - v4) * v19
        }
    end

    local v20 = v17 + v16
    local v21 = 0.5 / math.sqrt(v20)

    return {
        (v6 - v8) * v21,
        (v7 - v3) * v21,
        (v2 - v4) * v21,
        v20 * v21
    }
end

local function glam_quat_normalize(p4) -- line: 78
    local v23 = 1 / math.sqrt(p4[1] * p4[1] + p4[2] * p4[2] + p4[3] * p4[3] + p4[4] * p4[4])

    return {
        p4[1] * v23,
        p4[2] * v23,
        p4[3] * v23,
        p4[4] * v23
    }
end

t1.DebugCam = {}

function t1.DebugCam.default() -- line: 88
    return {
        want_toggle = false,
        want_spawn = false,
        previous_buttons = 0,
        release_controls = false
    }
end

function t1.DebugCam.active(p5) -- line: 100
    -- upvalues: ManualCam (copy)
    return ManualCam.manual_cam_active(p5.manual_cam)
end

function t1.DebugCam.suppress_gameplay(p6, p7) -- line: 105
    -- upvalues: ManualCam (copy)
    return ManualCam.manual_cam_active(p7.manual_cam) or p6.release_controls
end

function t1.DebugCam.pose(p8) -- line: 110
    -- upvalues: ManualCam (copy), glam_quat_from_rotation_axes (copy), glam_quat_normalize (copy)
    local frame = p8.frame

    if frame == nil or not ManualCam.manual_cam_active(p8.manual_cam) then
        return nil
    end

    local v24 = ManualCam.get_matrix(p8.manual_cam, frame)
    local columns = v24.basis.columns
    local v25 = columns[1]
    local v26 = columns[2]
    local v27 = columns[3]

    return {
        translation = {
            v24.position[1],
            v24.position[2],
            v24.position[3]
        },
        rotation = glam_quat_normalize((glam_quat_from_rotation_axes({
            -v25[1],
            -v25[2],
            -v25[3]
        }, {
            v26[1],
            v26[2],
            v26[3]
        }, {
            -v27[1],
            -v27[2],
            -v27[3]
        }))),
        scale = { 1, 1, 1 }
    }
end

t1.DebugCamPlugin = {}

function t1.chord(p9, p10, p11) -- line: 140
    if bit32.band(p9, p10) == p10 then
        return bit32.band(p11, p10) ~= p10
    end

    return false
end

local chord = t1.chord

function t1.gameplay_blocked(p12, p13, p14, p15, p16, p17) -- line: 148
    -- upvalues: import (copy)
    local active = p13.active
    local v28, v29

    if active then
        v28 = active
        v29 = true
    else
        local v30 = not import("skate_game/graphics_menu").gameplay_active(p12)

        if v30 then
            v28 = v30
            v29 = true
        elseif p14 ~= nil then
            local open = p14.open

            if open then
                v28 = open
                v29 = true
            else
                v29 = false
            end
        else
            v29 = false
        end
    end

    if not v29 then
        local v31 = false

        if p15 ~= nil then
            local open = p15.open

            if open then
                v28 = open
                v31 = true
            elseif p16 ~= nil then
                local open = p16.open

                if open then
                    v28 = open
                    v31 = true
                end
            end
        elseif p16 ~= nil then
            local open = p16.open

            if open then
                v28 = open
                v31 = true
            end
        end

        if not v31 then
            v28 = p17 ~= nil and p17.open
        end
    end

    return v28
end

local gameplay_blocked = t1.gameplay_blocked

function t1.idle(p18, p19, p20) -- line: 159
    if p18 ~= 0 then
        return false
    end

    for _, v32 in p19 do
        if not (v32 < 0.05) then
            return false
        end
    end

    for _, v33 in p20 do
        for _, v34 in v33 do
            if not (math.abs(v34) < 0.18) then
                return false
            end
        end
    end

    return true
end

local idle = t1.idle

function t1.on_camera_input(p21, p22, p23, p24, p25, p26, p27, p28, p29, p30, p31) -- line: 184
    -- upvalues: rt (copy), import (copy), ManualCam (copy), DPAD_RIGHT (copy), R3 (copy), B (copy), manual_actions_from_raw (ref), chord (copy), gameplay_blocked (copy), idle (copy)
    if p25.active and ManualCam.manual_cam_active(p22.manual_cam) then
        p21.want_toggle = true
    end

    local v35 = import("skate_game/input").ControllerInput.raw_input(p24)

    if not gameplay_blocked(p26, p25, p27, p28, p29, p30) then
        if chord(v35.buttons, bit32.bor(DPAD_RIGHT, R3), p21.previous_buttons) then
            p21.want_toggle = true
        end

        if ManualCam.manual_cam_active(p22.manual_cam) and chord(v35.buttons, B, p21.previous_buttons) then
            p21.want_spawn = true
        end
    end

    p21.previous_buttons = v35.buttons

    local v36 = ManualCam.manual_cam_active(p22.manual_cam)
    local want_toggle, want_spawn = p21.want_toggle, p21.want_spawn

    p21.want_toggle = false
    p21.want_spawn = false

    if want_toggle then
        local v37 = rt.copy(p22.frame)

        if v36 then
            ManualCam.set_manual_cam_mode(p22.manual_cam, false, v37)
            p21.release_controls = true
        elseif v37 ~= nil then
            ManualCam.set_manual_cam_mode(p22.manual_cam, true, v37)
            p21.release_controls = true
        end
    end

    if want_spawn and ManualCam.manual_cam_active(p22.manual_cam) then
        local v38 = ManualCam.spawn_matrix(p22.manual_cam)
        local v39 = rt.copy(p22.frame)

        ManualCam.set_manual_cam_mode(p22.manual_cam, false, v39)
        p21.release_controls = true

        local travel_to = import("skate_game/physics").SkaterRuntime.travel_to

        pcall(travel_to, p23, v38)
    end

    if ManualCam.manual_cam_active(p22.manual_cam) then
        local v40 = rt.copy(p22.manual_cam_settings)
        local v41 = manual_actions_from_raw(v35)

        ManualCam.update_manual_cam(p22.manual_cam, v41, v40, p31)
    end

    if p21.release_controls and not ManualCam.manual_cam_active(p22.manual_cam) and idle(v35.buttons, v35.triggers, {
        v35.left,
        v35.right
    }) then
        p21.release_controls = false
    end
end

function t1.manual_actions_from_raw(p32) -- line: 255
    -- upvalues: GameplayActions (copy)
    return GameplayActions.from_values({
        p32.left[1],
        p32.left[2],
        if bit32.band(p32.buttons, 64) == 0 then 0 else 1,
        p32.right[1],
        p32.right[2],
        0,
        p32.triggers[1],
        p32.triggers[2],
        0, 0, 0, 0, 0, 0, 0, 0,
        0, 0
    })
end

manual_actions_from_raw = t1.manual_actions_from_raw
t1.DebugCamOverlay = {}

return t1
