-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local v1 = buffer.create(8)

local function rtl_from_bits(p1) -- line: 7
    -- upvalues: v1 (copy)
    buffer.writeu32(v1, 0, p1)

    return (buffer.readf32(v1, 0))
end

local import = require(sim.import)
local IntentMap = import("skate_core/graph/intents").IntentMap
local v2 = import("skate_core/input/controller")
local v3 = import("skate_core/input/riding_intentions")
local v4 = import("skate_core/input/wipeout_intentions")
local v5 = import("skate_core/input/manual_intentions")
local v6 = import("skate_core/input/gameplay_gestures")
local v7 = import("skate_core/input/anticipation_intentions")
local v8 = import("skate_core/input/trick_intentions")
local TickInput = import("skate_core/input/tick").TickInput
local GameplayActions = import("skate_core/input/gameplay_map").GameplayActions
local DerivedControllerInput = v2.DerivedControllerInput
local PushPreferences = v3.PushPreferences

local function gesture_input() -- line: 30
    -- upvalues: import (copy)
    return import("skate_game/input/gesture_input")
end

local v9 = false
local t1 = {}

function t1.set_reference(p2) -- line: 39
    -- upvalues: v9 (ref)
    v9 = p2
end

local camera_relative_axes, cross_camera_axis, normalize_camera_axis
local t2 = {
    actions = nil,
    value = function(p3, p4) -- value | line: 57
        -- upvalues: GameplayActions (copy)
        return GameplayActions.value(p3.actions, p4)
    end,
    state = function(p5, p6) -- state | line: 60
        -- upvalues: GameplayActions (copy)
        return GameplayActions.state(p5.actions, p6)
    end
}
local v10
local t3 = {
    attribute = 0,
    missing_attribute_value = 0
}
local t4 = {
    { 0, 0 },
    { 0, 0 }
}

local function simulation_actions_trait(p7) -- line: 69
    -- upvalues: t1 (copy)
    return {
        value = function(_, p9) -- value | line: 71
            -- upvalues: p7 (copy), t1 (copy)
            return t1.SimulationActions.value(p7, p9)
        end,
        state = function(_, p11) -- state | line: 74
            -- upvalues: p7 (copy), t1 (copy)
            return t1.SimulationActions.state(p7, p11)
        end
    }
end

t1.PlayerControls = {}

function t1.PlayerControls.default() -- line: 91
    -- upvalues: IntentMap (copy), DerivedControllerInput (copy), PushPreferences (copy)
    local v11 = DerivedControllerInput.from_words(table.create(26, 0))

    DerivedControllerInput.initialize(v11)

    return {
        offboard_direction = nil,
        ticks = 0,
        actor_flags = 0,
        bumper_state_502 = false,
        bumper_state_104 = false,
        offboard_axes = nil,
        gestures = nil,
        controller = v11,
        intents = {},
        named_intents = {},
        action_intents = IntentMap.new(),
        preferences = PushPreferences.default()
    }
end

function t1.sample(p12, p13, p14, p15, p16) -- line: 116
    -- upvalues: TickInput (copy), t1 (copy), v9 (ref), t2 (copy)
    local v12 = false

    if v9 then
        v12 = true
    elseif t2.actions ~= nil then
        v12 = true
    else
        t2.actions = TickInput.actions_borrowed(p12[1])

        local update_for_physics = t1.PlayerControls.update_for_physics
        local ok, result = pcall(update_for_physics, p16, t2, p13, p14, p15)

        t2.actions = nil

        if not ok then
            error("Offboard controller publication: " .. tostring(result), 0)
        end
    end

    if v12 then
        return t1.sample_reference(p12, p13, p14, p15, p16)
    end

    t1.PlayerControls.publish_gestures(p16, p13.animation_profile.physics_mode, p14.player_input.physical.state.state_16, p12[1].stick_hz)
end

function t1.sample_reference(p17, p18, p19, p20, p21) -- line: 136
    -- upvalues: TickInput (copy), GameplayActions (copy), t1 (copy)
    local v13 = TickInput.actions(p17[1])
    local t6 = {
        value = function(_, p23) -- value | line: 140
            -- upvalues: v13 (copy), GameplayActions (copy)
            return GameplayActions.value(v13, p23)
        end,
        state = function(_, p25) -- state | line: 143
            -- upvalues: v13 (copy), GameplayActions (copy)
            return GameplayActions.state(v13, p25)
        end
    }
    local update_for_physics = t1.PlayerControls.update_for_physics
    local ok, result = pcall(update_for_physics, p21, t6, p18, p19, p20)

    if not ok then
        error("Offboard controller publication: " .. tostring(result), 0)
    end

    t1.PlayerControls.publish_gestures(p21, p18.animation_profile.physics_mode, p19.player_input.physical.state.state_16, p17[1].stick_hz)
end

function t1.PlayerControls.update_for_physics(p26, p27, p28, p29, p30) -- line: 165
    -- upvalues: rt (copy), t1 (copy), v9 (ref), camera_relative_axes (ref), v10 (ref)
    if v9 then
        return t1.PlayerControls.update_for_physics_reference(p26, p27, p28, p29, p30)
    end

    local physical = p29.player_input.physical
    local v14

    if physical.state.category_12 == 500 and physical.off_board.flag_304 == 0 and physical.state.state_16 ~= 503 then
        local frame = p30.frame

        if frame == nil then
            error("Native offboard input requires a completed presentation camera frame", 0)
        end

        local v15 = p27.value(p27, 64)
        local v16 = p27.value(p27, 65)

        v14 = camera_relative_axes({ v15, v16 }, frame.basis.columns)
    end

    local v17 = v10

    if v17 == nil then
        v17 = {
            source = nil,
            offboard_axes = nil,
            value = t1.SimulationActions.value,
            state = t1.SimulationActions.state
        }
        v10 = v17
    end

    v17.source = p27
    v17.offboard_axes = v14
    t1.PlayerControls.update(p26, v17, p28.settings.step.simulation.time_step, p28.settings.input_magnitude_threshold, physical.scoring.capabilities_204)
    v17.source = nil
    v17.offboard_axes = nil
    p26.offboard_axes = rt.copy(v14)

    if v14 ~= nil then
        p26.offboard_direction = {
            v14[1],
            0,
            v14[2],
            0
        }
    else
        p26.offboard_direction = nil
    end
end

function t1.PlayerControls.update_for_physics_reference(p31, p32, p33, p34, p35) -- line: 211
    -- upvalues: rt (copy), t1 (copy), camera_relative_axes (ref), simulation_actions_trait (copy)
    local physical = p34.player_input.physical
    local v18

    if physical.state.category_12 == 500 and physical.off_board.flag_304 == 0 and physical.state.state_16 ~= 503 then
        local frame = p35.frame

        if frame == nil then
            error("Native offboard input requires a completed presentation camera frame", 0)
        end

        local v19 = p32.value(p32, 64)
        local v20 = p32.value(p32, 65)

        v18 = camera_relative_axes({ v19, v20 }, rt.copy(frame.basis.columns))
    end

    t1.PlayerControls.update(p31, simulation_actions_trait({
        source = p32,
        offboard_axes = rt.copy(v18)
    }), p33.settings.step.simulation.time_step, p33.settings.input_magnitude_threshold, physical.scoring.capabilities_204)
    p31.offboard_axes = rt.copy(v18)

    if v18 ~= nil then
        p31.offboard_direction = {
            v18[1],
            0,
            v18[2],
            0
        }
    else
        p31.offboard_direction = nil
    end
end

function t1.PlayerControls.simulation_actions(p36, p37) -- line: 247
    -- upvalues: rt (copy)
    return {
        source = p37,
        offboard_axes = rt.copy(p36.offboard_axes)
    }
end

function t1.PlayerControls.load(p38) -- line: 255
    -- upvalues: import (copy), t1 (copy)
    local v21 = import("skate_game/input/gesture_input").GestureInput.load(p38)
    local v22 = t1.PlayerControls.default()

    v22.gestures = v21

    return v22
end

local v23 = import("skate_game/input/stick_hz")

function t1.PlayerControls.publish_gestures(p39, p40, p41, p42) -- line: 270
    -- upvalues: v1 (copy), import (copy), DerivedControllerInput (copy), t1 (copy), v9 (ref), t4 (copy), v23 (copy)
    local gestures = p39.gestures

    if gestures ~= nil then
        if v23.per_tick > 1 then
            return t1.PlayerControls.publish_gestures_hz(p39, p40, p41, p42)
        end

        if gestures.hz_mode ~= nil then
            import("skate_game/input/gesture_input").GestureInput.reset_recognizers(gestures)
            gestures.hz_mode = nil
        end
    end

    if v9 then
        return t1.PlayerControls.publish_gestures_reference(p39, p40, p41)
    end

    if gestures == nil then
        return
    end

    local v24 = DerivedControllerInput.words(p39.controller)
    local v25 = t4[1]
    local v26 = t4[2]

    buffer.writeu32(v1, 0, v24[8])

    local v28 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v24[9])

    local v30 = buffer.readf32(v1, 0)

    v25[1] = v28
    v25[2] = v30
    buffer.writeu32(v1, 0, v24[10])

    local v32 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v24[11])

    local v34 = buffer.readf32(v1, 0)

    v26[1] = v32
    v26[2] = v34

    for _, v35 in import("skate_game/input/gesture_input").GestureInput.publish(gestures, t4, p40, p39.actor_flags, p41, p39.action_intents) do
        local v36 = v35[1]
        local v37 = v35[2]

        if math.abs(v37) > 0.01 then
            p39.named_intents[v36] = v37
        end
    end
end

function t1.PlayerControls.publish_gestures_hz(p43, p44, p45, p46) -- line: 310
    -- upvalues: v1 (copy), import (copy), DerivedControllerInput (copy), t4 (copy)
    local gestures = p43.gestures
    local GestureInput = import("skate_game/input/gesture_input").GestureInput

    if gestures.hz_mode == nil then
        GestureInput.reset_recognizers(gestures)
        gestures.hz_mode = true
    end

    local v38 = DerivedControllerInput.words(p43.controller)
    local v39 = t4[1]
    local v40 = t4[2]

    buffer.writeu32(v1, 0, v38[8])

    local v42 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v38[9])

    local v44 = buffer.readf32(v1, 0)

    v39[1] = v42
    v39[2] = v44
    buffer.writeu32(v1, 0, v38[10])

    local v46 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v38[11])

    local v48 = buffer.readf32(v1, 0)

    v40[1] = v46
    v40[2] = v48

    for _, v49 in GestureInput.publish_hz(gestures, t4, p46, p44, p43.actor_flags, p45, p43.action_intents) do
        local v50 = v49[1]
        local v51 = v49[2]

        if math.abs(v51) > 0.01 then
            p43.named_intents[v50] = v51
        end
    end
end

function t1.PlayerControls.publish_gestures_reference(p47, p48, p49) -- line: 331
    -- upvalues: v1 (copy), import (copy), DerivedControllerInput (copy)
    local gestures = p47.gestures

    if gestures == nil then
        return
    end

    local v52 = DerivedControllerInput.words(p47.controller)

    buffer.writeu32(v1, 0, v52[8])

    local v54 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v52[9])

    local t7 = {
        v54,
        (buffer.readf32(v1, 0))
    }

    buffer.writeu32(v1, 0, v52[10])

    local v57 = buffer.readf32(v1, 0)

    buffer.writeu32(v1, 0, v52[11])

    local t8 = {
        t7,
        {
            v57,
            (buffer.readf32(v1, 0))
        }
    }

    for _, v59 in import("skate_game/input/gesture_input").GestureInput.publish(gestures, t8, p48, p47.actor_flags, p49, p47.action_intents) do
        local v60 = v59[1]
        local v61 = v59[2]

        if math.abs(v61) > 0.01 then
            p47.named_intents[v60] = v61
        end
    end
end

function t1.PlayerControls.update(p50, p51, p52, p53, p54) -- line: 362
    -- upvalues: v3 (copy), DerivedControllerInput (copy), t1 (copy), v9 (ref), t3 (copy)
    if v9 then
        return t1.PlayerControls.update_reference(p50, p51, p52, p53, p54)
    end

    p50.offboard_axes = nil
    t3.attribute = p53
    t3.missing_attribute_value = 0
    DerivedControllerInput.update(p50.controller, p51, p52, p50.bumper_state_502, p50.bumper_state_104, t3)
    p50.intents = v3.produce(p50.controller, p50.actor_flags, p50.preferences)
    t1.PlayerControls.finish_update(p50, p54)
end

function t1.PlayerControls.update_reference(p55, p56, p57, p58, p59) -- line: 377
    -- upvalues: rt (copy), v3 (copy), DerivedControllerInput (copy), t1 (copy)
    p55.offboard_axes = nil
    DerivedControllerInput.update(p55.controller, p56, p57, p55.bumper_state_502, p55.bumper_state_104, {
        missing_attribute_value = 0,
        attribute = p58
    })
    p55.intents = v3.produce(p55.controller, p55.actor_flags, rt.copy(p55.preferences))
    t1.PlayerControls.finish_update(p55, p59)
end

function t1.PlayerControls.finish_update(p60, p61) -- line: 389
    -- upvalues: IntentMap (copy), v4 (copy), v5 (copy), v6 (copy), v7 (copy), v8 (copy)
    for _, v62 in v5.produce(p60.controller, p60.actor_flags) do
        table.insert(p60.intents, v62)
    end

    for _, v63 in v6.produce(p60.controller) do
        table.insert(p60.intents, v63)
    end

    for _, v64 in v4.produce(p60.controller, p60.actor_flags, p61) do
        if v64.name == "WipeoutControlX" then
            v64.value = -v64.value
        end

        table.insert(p60.intents, v64)
    end

    for _, v65 in v7.produce(p60.controller) do
        table.insert(p60.intents, v65)
    end

    for _, v66 in v8.produce(p60.controller) do
        table.insert(p60.intents, {
            name = v66.name,
            value = v66.value
        })
    end

    IntentMap.clear(p60.action_intents)
    table.clear(p60.named_intents)

    for _, v67 in p60.intents do
        IntentMap.insert(p60.action_intents, v67.name, v67.value)

        if math.abs(v67.value) > 0.01 then
            p60.named_intents[v67.name] = v67.value
        end
    end

    p60.ticks += 1
end

t1.SimulationActions = {}

function t1.SimulationActions.value(p62, p63) -- line: 432
    local offboard_axes = p62.offboard_axes

    if offboard_axes ~= nil then
        if p63 == 64 then
            return offboard_axes[1]
        end

        if p63 == 65 then
            return offboard_axes[2]
        end
    end

    return p62.source.value(p62.source, p63)
end

function t1.SimulationActions.state(p64, p65) -- line: 445
    -- upvalues: t1 (copy)
    if p64.offboard_axes == nil or p65 ~= 64 and p65 ~= 65 then
        return p64.source.state(p64.source, p65)
    end

    if t1.SimulationActions.value(p64, p65) == 0 then
        return 0
    end

    return 1
end

function camera_relative_axes(p66, p67) -- line: 455
    -- upvalues: cross_camera_axis (ref), normalize_camera_axis (ref)
    local v68 = p67[1]
    local v69 = p67[2]
    local v70 = p67[3]

    if math.abs(v70[2]) < 0.9900000095367432 then
        v68 = normalize_camera_axis(cross_camera_axis({ 0, 1, 0 }, v70))
        v70 = normalize_camera_axis(cross_camera_axis(v68, { 0, 1, 0 }))
        v69 = normalize_camera_axis(cross_camera_axis(v70, v68))
    end

    local t10 = {
        -p66[1],
        0,
        p66[2]
    }
    local t11 = {
        v70[1] * t10[3] + (v69[1] * t10[2] + v68[1] * t10[1]),
        v70[2] * t10[3] + (v69[2] * t10[2] + v68[2] * t10[1]),
        v70[3] * t10[3] + (v69[3] * t10[2] + v68[3] * t10[1])
    }
    local v72 = if t11[1] >= 0 then 0 else -t11[1]
    local v73 = if t11[1] > 0 then t11[1] else 0
    local v74 = if t11[3] >= 0 then 0 else -t11[3]
    local v75 = if t11[3] <= 0 then 0 else t11[3]

    return {
        v73 - v72,
        v75 - v74
    }
end

t1.camera_relative_axes = camera_relative_axes

function cross_camera_axis(p68, p69) -- line: 482
    return {
        -p68[3] * p69[2] + p68[2] * p69[3],
        -p68[1] * p69[3] + p68[3] * p69[1],
        -p68[2] * p69[1] + p68[1] * p69[2]
    }
end

t1.cross_camera_axis = cross_camera_axis

function normalize_camera_axis(p70) -- line: 491
    local v76 = p70[1] * p70[1] + p70[2] * p70[2] + p70[3] * p70[3]
    local v77 = 1 / math.sqrt(v76)
    local v78 = -v76 * (v77 * v77) + 1
    local v79 = v77 * 0.5 * v78 + v77
    local v80 = -v76 * (v79 * v79) + 1
    local v81 = v79 * 0.5 * v80 + v79

    return {
        p70[1] * v81,
        p70[2] * v81,
        p70[3] * v81
    }
end

t1.normalize_camera_axis = normalize_camera_axis

return t1
