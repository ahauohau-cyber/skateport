-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/graph/conditions")
local IntentMap = import("skate_core/graph/intents").IntentMap
local v2 = import("skate_core/input/set_turning")
local Binding = import("skate_data/state_graph/binding").Binding
local v3 = import("skate_game/graph_host/outputs")
local v4 = import("skate_game/graph_host/motion_animation")
local t1 = {}

local function gh(p1) -- line: 18
    -- upvalues: import (copy), t1 (copy)
    local v5 = t1[p1]

    if v5 == nil then
        v5 = import("skate_game/graph_host/" .. p1)
        t1[p1] = v5
    end

    return v5
end

local t2 = {
    MotionAnimation = v4.MotionAnimation
}
local MotionAnimation = v4.MotionAnimation
local GraphDiagnostics = v3.GraphDiagnostics

local function error_to_string(p2) -- line: 54
    if not (type(p2) == "table" and type(p2[1]) == "string") then
        return (tostring(p2))
    end

    return p2[1]
end

local function debug_fmt(p3) -- line: 62
    -- upvalues: debug_fmt (copy)
    local v9 = type(p3)

    if v9 == "nil" then
        return "None"
    end

    if v9 == "string" then
        return string.format("\"%s\"", p3)
    end

    if v9 ~= "table" then
        return (tostring(p3))
    end

    local t3 = {}

    for v10 in p3 do
        if type(v10) == "string" and v10 ~= "tag" then
            table.insert(t3, v10)
        end
    end

    table.sort(t3)

    local t4 = {}

    for _, v11 in t3 do
        table.insert(t4, v11 .. ": " .. debug_fmt(p3[v11]))
    end

    local t5 = {}

    for _, v13 in ipairs(p3) do
        table.insert(t5, debug_fmt(v13))
    end

    local tag = p3.tag

    if tag == nil then
        if #t5 > 0 then
            return "[" .. table.concat(t5, ", ") .. "]"
        end

        return "{ " .. table.concat(t4, ", ") .. " }"
    end

    if #t5 > 0 then
        return tag .. "(" .. table.concat(t5, ", ") .. ")"
    end

    if #t4 > 0 then
        return tag .. " { " .. table.concat(t4, ", ") .. " }"
    end

    return tag
end

t2.MotionPhysical = {}
t2.MotionHost = {}

function t2.MotionHost.end_gesture_channels(p4) -- line: 157
    -- upvalues: import (copy), t1 (copy)
    for _, v14 in p4.instances do
        if v14.tag == "CharacterGesture" then
            local motion_character_gesture = t1.motion_character_gesture

            if motion_character_gesture == nil then
                motion_character_gesture = import("skate_game/graph_host/motion_character_gesture")
                t1.motion_character_gesture = motion_character_gesture
            end

            motion_character_gesture.CharacterGesture["end"](v14[1], p4.animation)
        end
    end

    p4.gesture_publication = nil
end

function t2.MotionHost.from_graph(p5, p6, p7, p8) -- line: 170
    -- upvalues: rt (copy), import (copy), v1 (copy), IntentMap (copy), v2 (copy), Binding (copy), v3 (copy), t1 (copy), MotionAnimation (copy), GraphDiagnostics (copy)
    local motion_nodes = t1.motion_nodes

    if motion_nodes == nil then
        motion_nodes = import("skate_game/graph_host/motion_nodes")
        t1.motion_nodes = motion_nodes
    end

    local MotionFactory = motion_nodes.MotionFactory
    local t6 = {}
    local instantiate_operations = Binding.instantiate_operations
    local binding, source = p5.binding, p5.source
    local t7 = {
        create = function(_, p10, p11, p12) -- create | line: 176
            -- upvalues: MotionFactory (copy), t6 (copy)
            return MotionFactory.create(t6, p10, p11, p12)
        end,
        add_parameter = function(_, p14, p15) -- add_parameter | line: 179
            -- upvalues: MotionFactory (copy), t6 (copy)
            return MotionFactory.add_parameter(t6, p14, p15)
        end
    }
    local ok, result = pcall(instantiate_operations, binding, source, t7)

    if not ok then
        local _error = error
        local v15 = if type(result) ~= "table" then tostring(result) elseif type(result[1]) == "string" then result[1] else tostring(result)

        _error(v15, 0)
    end

    local operations = result.operations
    local motion_conditions = t1.motion_conditions

    if motion_conditions == nil then
        motion_conditions = import("skate_game/graph_host/motion_conditions")
        t1.motion_conditions = motion_conditions
    end

    motion_conditions.bind_states(p5, operations)

    local motion_instances = t1.motion_instances

    if motion_instances == nil then
        motion_instances = import("skate_game/graph_host/motion_instances")
        t1.motion_instances = motion_instances
    end

    local Instance = motion_instances.Instance
    local v17 = table.create(#p5.runtime.operations.behaviors)

    for _, v18 in p5.runtime.operations.behaviors do
        table.insert(v17, Instance.new(operations[v18 + 1]))
    end

    local n1 = 0

    for _, v20 in operations do
        if v20.tag ~= "Unsupported" then
            n1 += 1
        end
    end

    local t8 = {}

    for _, v21 in operations do
        if v21.tag == "Unsupported" then
            table.insert(t8, string.format("%s `%s`", tostring(v21.kind), v21.name))
        end
    end

    local v23 = v3.GraphCapabilityReport.default()

    v23.supported_operations = n1
    v23.unsupported_operations = t8

    for _, v24 in p5.runtime.operations.conditions do
        local v25 = operations[v24 + 1]

        if v25 ~= nil and v25.tag == "Unsupported" then
            table.insert(v23.unsupported_conditions, string.format("%s `%s`", tostring(v25.kind), v25.name))
        end
    end

    for _, v27 in p5.runtime.operations.hooks do
        local v28 = operations[v27 + 1]

        if v28 ~= nil and v28.tag == "Unsupported" then
            table.insert(v23.unsupported_hooks, string.format("%s `%s`", tostring(v28.kind), v28.name))
        end
    end

    local t9 = {
        hstr_vel_b = 0,
        lstr_vel_b = 0,
        vel_e = 0
    }
    local t10 = {
        out_factor = 0,
        current_push_dv = 0,
        continue_push = false,
        current = rt.copy(t9),
        target = rt.copy(t9)
    }
    local pushing_settings = t1.pushing_settings

    if pushing_settings == nil then
        pushing_settings = import("skate_game/graph_host/pushing_settings")
        t1.pushing_settings = pushing_settings
    end

    local v30 = pushing_settings.PushingSettings.load(p6, {
        metadata = function(_, p17, p18) -- metadata | line: 242
            -- upvalues: p7 (copy), pushing_settings (ref)
            return pushing_settings.AnimationMetadata.metadata(p7, p17, p18)
        end
    })
    local t12 = {}

    local function parents_of_states() -- line: 247
        -- upvalues: p5 (copy), t12 (copy)
        for v31, v32 in p5.binding.states do
            t12[v31] = v32.parent
        end

        return t12
    end

    local t13 = {
        animation = MotionAnimation.from_metadata(p7),
        playback_context = p8,
        condition_inputs = v1.ConditionInputs.default(),
        gameplay_conditions = nil,
        manual_exit = nil,
        deck_yaw_pitch = nil,
        riding_conditions = nil
    }
    local motion_riding_conditions = t1.motion_riding_conditions

    if motion_riding_conditions == nil then
        motion_riding_conditions = import("skate_game/graph_host/motion_riding_conditions")
        t1.motion_riding_conditions = motion_riding_conditions
    end

    t13.condition_random = motion_riding_conditions.MotionRandom.new()
    t13.native_physical = nil
    t13.prelanding_physical = nil
    t13.air_leg_physical = nil
    t13.gesture_physical = nil
    t13.gesture_publication = nil
    t13.toggle_board_physical = nil
    t13.runout_physical = nil
    t13.grind_physical = nil
    t13.grind_conditions = nil

    local motion_grind = t1.motion_grind

    if motion_grind == nil then
        motion_grind = import("skate_game/graph_host/motion_grind")
        t1.motion_grind = motion_grind
    end

    t13.grind_settings = motion_grind.Settings.load(p6)
    t13.shove_physical = nil

    local motion_hand_services = t1.motion_hand_services

    if motion_hand_services == nil then
        motion_hand_services = import("skate_game/graph_host/motion_hand_services")
        t1.motion_hand_services = motion_hand_services
    end

    t13.hand_services = motion_hand_services.HandServices.default()
    t13.slide_latch = v2.SlideLatch.default()
    t13.is_power_sliding = false

    local motion_native = t1.motion_native

    if motion_native == nil then
        motion_native = import("skate_game/graph_host/motion_native")
        t1.motion_native = motion_native
    end

    t13.score_packet = motion_native.ScorePacket.default()

    local motion_tricks = t1.motion_tricks

    if motion_tricks == nil then
        motion_tricks = import("skate_game/graph_host/motion_tricks")
        t1.motion_tricks = motion_tricks
    end

    t13.trick_requests = motion_tricks.Requests.default()
    t13.trick_height_settings = { true, true }
    t13.action_controls = v3.ActionControls.default()
    t13.action_intents = IntentMap.new()
    t13.turning_output = v3.TurningOutput.default()
    t13.graph_effects = v3.GraphEffects.default()
    t13.time_tags = nil
    t13.physical = nil
    t13.offboard_cadence_phase = nil
    t13.offboard_locomotion_state = nil
    t13.ground_slope_type = nil
    t13.biped_ground_thin = nil
    t13.animation_phase = 0

    local motion_stock_gameplay = t1.motion_stock_gameplay

    if motion_stock_gameplay == nil then
        motion_stock_gameplay = import("skate_game/graph_host/motion_stock_gameplay")
        t1.motion_stock_gameplay = motion_stock_gameplay
    end

    t13.moving_objects = motion_stock_gameplay.MovingObjectRegistry.default()
    t13.push_state = t10
    t13.applying_body_tilt = false
    t13.crouching_physical = nil
    t13.body_tilt_physical = nil
    t13.hold_fakie = false

    local motion_fakie_hold = t1.motion_fakie_hold

    if motion_fakie_hold == nil then
        motion_fakie_hold = import("skate_game/graph_host/motion_fakie_hold")
        t1.motion_fakie_hold = motion_fakie_hold
    end

    t13.automatic_fakie_conditions = motion_fakie_hold.bind(p5.binding)
    t13.fakie_physical = nil
    t13.physical_stance = nil

    local motion_landing = t1.motion_landing

    if motion_landing == nil then
        motion_landing = import("skate_game/graph_host/motion_landing")
        t1.motion_landing = motion_landing
    end

    t13.flags = motion_landing.Flags.default()
    t13.landing_physical = nil
    t13.wipeout_physical = nil

    local motion_wipeout = t1.motion_wipeout

    if motion_wipeout == nil then
        motion_wipeout = import("skate_game/graph_host/motion_wipeout")
        t1.motion_wipeout = motion_wipeout
    end

    t13.wipeout_controls = motion_wipeout.Controls.default()

    local motion_wipeout2 = t1.motion_wipeout

    if motion_wipeout2 == nil then
        motion_wipeout2 = import("skate_game/graph_host/motion_wipeout")
        t1.motion_wipeout = motion_wipeout2
    end

    t13.wipeout_settings = motion_wipeout2.Settings.load(p6)
    t13.pumping_acceleration = nil
    t13.bump_acceleration = nil

    local motion_bump = t1.motion_bump

    if motion_bump == nil then
        motion_bump = import("skate_game/graph_host/motion_bump")
        t1.motion_bump = motion_bump
    end

    t13.bump_settings = motion_bump.Settings.load(p6)
    t13.allow_pumping = true

    local motion_riding = t1.motion_riding

    if motion_riding == nil then
        motion_riding = import("skate_game/graph_host/motion_riding")
        t1.motion_riding = motion_riding
    end

    t13.riding = motion_riding.RidingState.new()
    t13.errors = GraphDiagnostics.default()

    for v33, v34 in p5.binding.states do
        t12[v33] = v34.parent
    end

    t13.state_parents = t12
    t13.operations = operations
    t13.instances = v17
    t13.remap = rt.copy(p5.runtime.operations)
    t13.pushing = v30

    local turning_settings = t1.turning_settings

    if turning_settings == nil then
        turning_settings = import("skate_game/graph_host/turning_settings")
        t1.turning_settings = turning_settings
    end

    t13.turning = turning_settings.load(p6)

    local crouching_settings = t1.crouching_settings

    if crouching_settings == nil then
        crouching_settings = import("skate_game/graph_host/crouching_settings")
        t1.crouching_settings = crouching_settings
    end

    t13.crouching = crouching_settings.load(p6)

    local motion_riding2 = t1.motion_riding

    if motion_riding2 == nil then
        motion_riding2 = import("skate_game/graph_host/motion_riding")
        t1.motion_riding = motion_riding2
    end

    t13.body_tilt = motion_riding2.body_tilt_settings(p6)

    local pumping_settings = t1.pumping_settings

    if pumping_settings == nil then
        pumping_settings = import("skate_game/graph_host/pumping_settings")
        t1.pumping_settings = pumping_settings
    end

    t13.pumping = pumping_settings.load(p6)

    local motion_sliding = t1.motion_sliding

    if motion_sliding == nil then
        motion_sliding = import("skate_game/graph_host/motion_sliding")
        t1.motion_sliding = motion_sliding
    end

    t13.sliding = motion_sliding.Settings.load(p6)

    local motion_spin = t1.motion_spin

    if motion_spin == nil then
        motion_spin = import("skate_game/graph_host/motion_spin")
        t1.motion_spin = motion_spin
    end

    t13.spin = motion_spin.Settings.load(p6)

    local motion_air_leg = t1.motion_air_leg

    if motion_air_leg == nil then
        motion_air_leg = import("skate_game/graph_host/motion_air_leg")
        t1.motion_air_leg = motion_air_leg
    end

    t13.air_leg = motion_air_leg.load(p6)

    local motion_kickturn = t1.motion_kickturn

    if motion_kickturn == nil then
        motion_kickturn = import("skate_game/graph_host/motion_kickturn")
        t1.motion_kickturn = motion_kickturn
    end

    t13.kickturn = motion_kickturn.load_settings(p6)

    local motion_manual = t1.motion_manual

    if motion_manual == nil then
        motion_manual = import("skate_game/graph_host/motion_manual")
        t1.motion_manual = motion_manual
    end

    t13.manual = motion_manual.settings(p6)

    local motion_hippy_jump = t1.motion_hippy_jump

    if motion_hippy_jump == nil then
        motion_hippy_jump = import("skate_game/graph_host/motion_hippy_jump")
        t1.motion_hippy_jump = motion_hippy_jump
    end

    t13.hippy_jump = motion_hippy_jump.Settings.load(p6)

    local motion_finger_flip = t1.motion_finger_flip

    if motion_finger_flip == nil then
        motion_finger_flip = import("skate_game/graph_host/motion_finger_flip")
        t1.motion_finger_flip = motion_finger_flip
    end

    t13.finger_flip = motion_finger_flip.Settings.load(p6)
    t13.next_instance = 1

    return t13
end

function t2.MotionHost.accept_action_graph(p19, p20) -- line: 333
    -- upvalues: rt (copy), v3 (copy), MotionAnimation (copy), GraphDiagnostics (copy)
    local tick, action = p20.tick, p20.action

    if tick ~= action.tick then
        error(string.format("assertion `left == right` failed\n  left: %s\n right: %s", tostring(tick), (tostring(action.tick))), 0)
    end

    GraphDiagnostics.clear(p19.errors)
    p19.turning_output = rt.copy(action.turning)
    p19.graph_effects = rt.copy(action.effects)
    p19.action_controls = rt.copy(action.controls)
    p19.action_intents = v3.ActionControls.authored_values(action.controls)
    MotionAnimation.accept_action_graph(p19.animation, action)
end

function t2.MotionHost.run(p21, p22, p23, p24) -- line: 356
    -- upvalues: t2 (copy), GraphDiagnostics (copy)
    local execute = t2.MotionHost.execute
    local ok, result = pcall(execute, p21, p22, p23, p24)

    if not ok then
        GraphDiagnostics.push(p21.errors, string.format("MotionGraph behavior %d: %s", p22, (tostring(result))))
    end
end

function t2.MotionHost.condition_activation_reference(p25, p26, p27) -- line: 366
    -- upvalues: import (copy), t1 (copy), GraphDiagnostics (copy), debug_fmt (copy)
    local v36 = p25.remap.conditions[p26 + 1]

    if v36 ~= nil then
        local motion_fakie_hold = t1.motion_fakie_hold

        if motion_fakie_hold == nil then
            motion_fakie_hold = import("skate_game/graph_host/motion_fakie_hold")
            t1.motion_fakie_hold = motion_fakie_hold
        end

        if motion_fakie_hold.blocked(p25.hold_fakie, p25.automatic_fakie_conditions, v36) then
            return 0
        end
    end

    local function v37() -- line: 376
        -- upvalues: p25 (copy), p26 (copy), p27 (copy), import (copy), t1 (copy), debug_fmt (copy)
        local v38 = p25.remap.conditions[p26 + 1]
        local v39 = if v38 == nil then nil else p25.operations[v38 + 1]

        if v39 == nil then
            error("Unbound MotionGraph condition", 0)
        end

        if v39.tag == "Condition" then
            local motion_conditions = t1.motion_conditions

            if motion_conditions == nil then
                motion_conditions = import("skate_game/graph_host/motion_conditions")
                t1.motion_conditions = motion_conditions
            end

            return motion_conditions.MotionCondition.evaluate(v39[1], p25, p27)
        end

        error(string.format("Unsupported MotionGraph condition %s", debug_fmt(v39)), 0)
    end

    local ok, result = pcall(v37)

    if ok then
        if result then
            return 1
        end
    else
        GraphDiagnostics.push(p25.errors, (tostring(result)))
    end

    return 0
end

local function MotionHost_condition_body(p28, p29, p30) -- line: 402
    -- upvalues: import (copy), t1 (copy), debug_fmt (copy)
    local v40 = p28.remap.conditions[p29 + 1]
    local v41 = if v40 == nil then nil else p28.operations[v40 + 1]

    if v41 == nil then
        error("Unbound MotionGraph condition", 0)
    end

    if v41.tag == "Condition" then
        local motion_conditions = t1.motion_conditions

        if motion_conditions == nil then
            motion_conditions = import("skate_game/graph_host/motion_conditions")
            t1.motion_conditions = motion_conditions
        end

        return motion_conditions.MotionCondition.evaluate(v41[1], p28, p30)
    end

    error(string.format("Unsupported MotionGraph condition %s", debug_fmt(v41)), 0)
end

function t2.MotionHost.condition_activation(p31, p32, p33) -- line: 418
    -- upvalues: import (copy), t1 (copy), GraphDiagnostics (copy), MotionHost_condition_body (copy)
    local v42 = p31.remap.conditions[p32 + 1]

    if v42 ~= nil then
        local motion_fakie_hold = t1.motion_fakie_hold

        if motion_fakie_hold == nil then
            motion_fakie_hold = import("skate_game/graph_host/motion_fakie_hold")
            t1.motion_fakie_hold = motion_fakie_hold
        end

        if motion_fakie_hold.blocked(p31.hold_fakie, p31.automatic_fakie_conditions, v42) then
            return 0
        end
    end

    local ok, result = pcall(MotionHost_condition_body, p31, p32, p33)

    if ok then
        if result then
            return 1
        end
    else
        GraphDiagnostics.push(p31.errors, (tostring(result)))
    end

    return 0
end

function t2.MotionHost.context(_) -- line: 442
    return { 0, 0, 0, 0, 0, 0 }
end

function t2.MotionHost.allocate(p35, p36, _) -- line: 446
    -- upvalues: rt (copy), import (copy), t1 (copy)
    local v43 = p35.remap.behaviors[p36 + 1]

    if v43 ~= nil then
        local instances = p35.instances
        local v44 = p36 + 1
        local motion_instances = t1.motion_instances

        if motion_instances == nil then
            motion_instances = import("skate_game/graph_host/motion_instances")
            t1.motion_instances = motion_instances
        end

        instances[v44] = motion_instances.Instance.new(p35.operations[v43 + 1])
    end

    local next_instance = p35.next_instance

    p35.next_instance = math.max(rt.wrapping_add_u32(p35.next_instance, 1), 1)

    return next_instance
end

function t2.MotionHost.begin(p38, p39, _, p41) -- line: 456
    -- upvalues: t2 (copy)
    t2.MotionHost.run(p38, p39, p41, 0)
end

function t2.MotionHost.update(p42, p43, _, p45) -- line: 462
    -- upvalues: t2 (copy), GraphDiagnostics (copy)
    local execute = t2.MotionHost.execute
    local ok, result = pcall(execute, p42, p43, p45, 1)

    if not ok then
        GraphDiagnostics.push(p42.errors, string.format("MotionGraph behavior %d: %s", p43, (tostring(result))))
    end
end

t2.MotionHost["end"] = function(p46, p47, _, p49) -- line: 472
    -- upvalues: t2 (copy)
    t2.MotionHost.run(p46, p47, p49, 2)
end

function t2.MotionHost.hook(p50, p51, _) -- line: 476
    -- upvalues: rt (copy), v2 (copy), MotionAnimation (copy), GraphDiagnostics (copy), debug_fmt (copy)
    local v46 = p50.remap.hooks[p51 + 1]
    local v47 = if v46 == nil then nil else p50.operations[v46 + 1]

    if v47 ~= nil and v47.tag == "Hook" then
        local v48 = rt.copy(v47[1])

        if v48.tag == "GrabSlide" then
            v2.SlideLatch.grab(p50.slide_latch, v48.right)
        elseif v48.tag == "Override" then
            p50.playback_context.transition_override = v48[1]
        elseif v48.tag == "MongoPushToAntic" then
            local animation = v48.animation
            local t14 = {
                priority = 0,
                keep_alive = false,
                mirrored = false,
                speed = 1,
                blend_in = 0.10000000149011612,
                hold_during_blend_in = false,
                blend_out = 0.07000000029802322,
                hold_during_blend_out = false,
                use_attributes = false
            }
            local new_channel = MotionAnimation.new_channel
            local animation2 = p50.animation
            local ok, result = pcall(new_channel, animation2, animation, animation, t14)

            if not ok then
                GraphDiagnostics.push(p50.errors, (tostring(result)))
            end
        end
    else
        local v49 = if v47 == nil then "None" else "Some(" .. debug_fmt(v47) .. ")"

        GraphDiagnostics.push(p50.errors, string.format("Unsupported MotionGraph hook %s", v49))
    end
end

function t2.MotionHost.release(_, _) -- line: 519
end

for _, v50 in { "motion_toggle_execute", "motion_air_execute", "motion_execute", "motion_score_execute", "motion_filter_execute", "motion_sliding_execute", "motion_wipeout_execute" } do
    local v51 = t1[v50]

    if v51 == nil then
        v51 = import("skate_game/graph_host/" .. v50)
        t1[v50] = v51
    end

    if v51.MotionHost ~= nil then
        for v52, v53 in v51.MotionHost do
            t2.MotionHost[v52] = v53
        end
    end
end

return t2
