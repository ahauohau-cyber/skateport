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
local v2 = import("skate_game/graph_host/action_nodes")
local v3 = import("skate_core/graph/conditions")
local v4 = import("skate_core/graph/intent_handlers")
local IntentMap = import("skate_core/graph/intents").IntentMap
local v5 = import("skate_core/input/body_flip_signal")
local v6 = import("skate_core/input/graph_intents")
local v7 = import("skate_game/graph_host/action_board_adjust")
local Collections = import("skate_data/collections").Collections
local Binding = import("skate_data/state_graph/binding").Binding
local v8 = import("skate_game/graph_host/outputs")
local v9 = import("skate_game/input/gesture_mapping")
local v10 = import("skate_game/graph_host/action_conditions")
local v11 = import("skate_game/graph_host/condition_nodes")
local t1 = {}
local ActionFactory, ActionInstance, ActionInstances = v2.ActionFactory, v2.ActionInstance, v2.ActionInstances
local ConstMgIntent, TimeMgIntent = v4.ConstMgIntent, v4.TimeMgIntent
local CreateMgIntent = v6.CreateMgIntent
local GraphDiagnostics = v8.GraphDiagnostics

local function error_to_string(p2) -- line: 45
    if not (type(p2) == "table" and type(p2[1]) == "string") then
        return (tostring(p2))
    end

    return p2[1]
end

local function debug_option_string(p3) -- line: 53
    if p3 == nil then
        return "None"
    end

    return string.format("Some(\"%s\")", p3)
end

t1.PhysicalConditions = {}
t1.ActionHost = {}

function t1.ActionHost.from_graph(p4, p5) -- line: 84
    -- upvalues: rt (copy), Collections (copy), Binding (copy), v8 (copy), v11 (copy), t1 (copy), ActionFactory (copy), ActionInstance (copy), ActionInstances (copy)
    local t2 = {}
    local instantiate_operations = Binding.instantiate_operations
    local binding, source = p4.binding, p4.source
    local t3 = {
        create = function(_, p7, p8, p9) -- create | line: 88
            -- upvalues: t2 (copy), ActionFactory (copy)
            return ActionFactory.create(t2, p7, p8, p9)
        end,
        add_parameter = function(_, p11, p12) -- add_parameter | line: 91
            -- upvalues: t2 (copy), ActionFactory (copy)
            return ActionFactory.add_parameter(t2, p11, p12)
        end
    }
    local ok, result = pcall(instantiate_operations, binding, source, t3)

    if not ok then
        local _error = error
        local v15 = if type(result) ~= "table" then tostring(result) elseif type(result[1]) == "string" then result[1] else tostring(result)

        _error(v15, 0)
    end

    local v17 = ActionInstances.new(result.operations)
    local n1 = 0

    for _, v18 in v17.operations do
        if ActionInstance.unsupported(v18) == nil then
            n1 += 1
        end
    end

    local t4 = {}

    for _, v19 in v17.operations do
        local v20 = ActionInstance.unsupported(v19)

        if v20 ~= nil then
            table.insert(t4, string.format("%s `%s`", tostring(v20.kind), v20.name))
        end
    end

    local v22 = v8.GraphCapabilityReport.default()

    v22.supported_operations = n1
    v22.unsupported_operations = t4

    for _, v23 in p4.runtime.operations.conditions do
        local v24 = ActionInstances.get(v17, v23)

        if v24 ~= nil then
            local v25 = ActionInstance.unsupported(v24)

            if v25 ~= nil then
                table.insert(v22.unsupported_conditions, string.format("%s `%s`", tostring(v25.kind), v25.name))
            end
        end
    end

    for _, v27 in p4.runtime.operations.hooks do
        local v28 = ActionInstances.get(v17, v27)

        if v28 ~= nil then
            local v29 = ActionInstance.unsupported(v28)

            if v29 ~= nil then
                table.insert(v22.unsupported_hooks, string.format("%s `%s`", tostring(v29.kind), v29.name))
            end
        end
    end

    v11.bind_current_states(p4, v17)

    local v31 = t1.ActionHost.new(v17, rt.copy(p4.runtime.operations))

    v31.body_flip_settings = {
        gesture_window = Collections.float(p5, "anim_motion", "body_flip", "extend_bodyflip_gesture"),
        takeoff_window = Collections.float(p5, "anim_motion", "body_flip", "extend_takeoff_point")
    }

    local t5 = {}

    for v32, v33 in p4.binding.states do
        t5[v32] = v33.parent
    end

    v31.state_parents = t5

    return v31
end

function t1.ActionHost.new(p13, p14) -- line: 157
    -- upvalues: rt (copy), v1 (copy), v3 (copy), IntentMap (copy), v5 (copy), v7 (copy), v9 (copy), ConstMgIntent (copy), TimeMgIntent (copy), GraphDiagnostics (copy)
    local v34 = #p14.behaviors
    local v35 = table.create(v34)

    for _, v36 in p14.behaviors do
        local v37 = p13.operations[v36 + 1]
        local float_bits = v37.config.float_bits
        local new = ConstMgIntent.new
        local v38 = 0

        if float_bits ~= nil then
            buffer.writeu32(v1, 0, float_bits)
            v38 = buffer.readf32(v1, 0)
        end

        table.insert(v35, new(v38, v37.config.on_update))
    end

    local v39 = rt.filled(v34, TimeMgIntent.default())

    return {
        physical_conditions = nil,
        gameplay_conditions = nil,
        is_tricking = nil,
        dropping_in = nil,
        stance = nil,
        tick = 0,
        next_instance = 1,
        body_flip_settings = nil,
        instances = p13,
        action_intents = IntentMap.new(),
        motion_intents = IntentMap.new(),
        condition_inputs = v3.ConditionInputs.default(),
        animation_attributes = {},
        state_parents = {},
        remap = p14,
        errors = GraphDiagnostics.default(),
        created = table.create(v34, false),
        const_handlers = v35,
        time_handlers = v39,
        board_adjust = rt.filled(v34, v7.State.default()),
        body_flip = rt.filled(v34, v5.State.default()),
        juice_pending = rt.filled(v34, ""),
        trick_handlers = rt.filled(v34, v9.State.default())
    }
end

function t1.ActionHost.apply(p15, p16, p17) -- line: 197
    -- upvalues: IntentMap (copy)
    if p17.tag ~= "None" then
        if p17.tag == "Set" then
            IntentMap.insert(p15.motion_intents, p16, p17[1])
        elseif p17.tag == "Remove" then
            IntentMap.remove(p15.motion_intents, p16)
        end
    end
end

function t1.ActionHost.prepare_input(p18, p19) -- line: 208
    -- upvalues: v8 (copy), GraphDiagnostics (copy)
    GraphDiagnostics.clear(p18.errors)
    p18.tick = p19.tick
    p18.action_intents = v8.ActionInput.into_values(p19.controls)
    p18.motion_intents = v8.PriorMotionState.into_values(p19.prior_motion)
    p18.animation_attributes = p19.animation_attributes
end

function t1.ActionHost.output(p20) -- line: 217
    -- upvalues: v8 (copy)
    return v8.ActionGraphOutput.from_host(p20.tick, p20.action_intents, p20.motion_intents, p20.animation_attributes)
end

function t1.ActionHost.operation(p21, p22) -- line: 227
    -- upvalues: ActionInstances (copy)
    local v40 = p21.remap.behaviors[p22 + 1]

    if v40 == nil then
        return nil
    end

    return ActionInstances.get(p21.instances, v40)
end

function t1.ActionHost.unsupported(p23, p24, p25) -- line: 235
    -- upvalues: ActionInstance (copy), GraphDiagnostics (copy)
    local v41 = ActionInstance.unsupported(p25)

    if v41 == nil then
        return
    end

    GraphDiagnostics.push(p23.errors, string.format("ActionGraph behavior %d: %s `%s`", p24, tostring(v41.kind), v41.name))
end

function t1.ActionHost.publish_board_adjust(p26, p27, p28) -- line: 245
    -- upvalues: IntentMap (copy), v7 (copy)
    local mg_intent_mag = p28.config.mg_intent_mag

    if mg_intent_mag ~= nil then
        local mg_intent_angle = p28.config.mg_intent_angle

        if mg_intent_angle ~= nil then
            local v42 = v7.State.update(p26.board_adjust[p27 + 1], IntentMap.get(p26.action_intents, "BoardAdjustMag"), IntentMap.get(p26.action_intents, "BoardAdjustAngle"), p28.config.angle_filter, p28.config.negate_on_mirror, p26.stance ~= nil and p26.stance[2])

            if v42 ~= nil then
                local v43 = v42[1]
                local v44 = v42[2]

                IntentMap.insert(p26.motion_intents, mg_intent_mag, v43)
                IntentMap.insert(p26.motion_intents, mg_intent_angle, v44)
            else
                IntentMap.remove(p26.motion_intents, mg_intent_mag)
                IntentMap.remove(p26.motion_intents, mg_intent_angle)
            end
        end
    end
end

function t1.ActionHost.condition_activation_reference(p29, p30, p31) -- line: 275
    -- upvalues: v3 (copy), v10 (copy), ActionInstances (copy), GraphDiagnostics (copy), debug_option_string (copy)
    local function v45() -- line: 276
        -- upvalues: p29 (copy), p30 (copy), p31 (copy), v3 (copy), v10 (copy), ActionInstances (copy), debug_option_string (copy)
        local v46 = p29.remap.conditions[p30 + 1]
        local v47 = if v46 == nil then nil else ActionInstances.get(p29.instances, v46)

        if v47 == nil then
            error(string.format("ActionGraph condition %d is unbound", p30), 0)
        end

        local operation = v47.operation

        if operation.tag == "ExtraCondition" then
            return v10.ActionCondition.evaluate(operation[1], p29, p31)
        end

        if operation.tag == "PhysicsRequestsDismount" then
            local physical_conditions = p29.physical_conditions

            if physical_conditions == nil then
                error("PhysicsRequestsDismount requires published State77", 0)
            end

            return physical_conditions.requests_dismount
        end

        if operation.tag == "IsLandingOnBoard" then
            local physical_conditions = p29.physical_conditions

            if physical_conditions == nil then
                error("IsLandingOnBoard requires actual State16", 0)
            end

            return physical_conditions.state == 503
        end

        if operation.tag == "Condition" then
            local evaluate = v3.ActionCondition.evaluate
            local v48 = operation[1]
            local condition_inputs, action_intents = p29.condition_inputs, p29.action_intents
            local current = p31.current
            local state_parents = p29.state_parents
            local ok, result = pcall(evaluate, v48, condition_inputs, action_intents, current, state_parents)

            if not ok then
                error(string.format("ActionGraph condition %d: %s", p30, (tostring(result))), 0)
            end

            return result
        end

        error(string.format("Unsupported ActionGraph condition %d: %s", p30, debug_option_string(v47.config.name)), 0)
    end

    local ok, result = pcall(v45)

    if ok then
        if result then
            return 1
        end
    else
        GraphDiagnostics.push(p29.errors, (tostring(result)))
    end

    return 0
end

local function ActionHost_condition_body(p32, p33, p34) -- line: 335
    -- upvalues: v3 (copy), v10 (copy), ActionInstances (copy), debug_option_string (copy)
    local v49 = p32.remap.conditions[p33 + 1]
    local v50 = if v49 == nil then nil else ActionInstances.get(p32.instances, v49)

    if v50 == nil then
        error(string.format("ActionGraph condition %d is unbound", p33), 0)
    end

    local operation = v50.operation

    if operation.tag == "ExtraCondition" then
        return v10.ActionCondition.evaluate(operation[1], p32, p34)
    end

    if operation.tag == "PhysicsRequestsDismount" then
        local physical_conditions = p32.physical_conditions

        if physical_conditions == nil then
            error("PhysicsRequestsDismount requires published State77", 0)
        end

        return physical_conditions.requests_dismount
    end

    if operation.tag == "IsLandingOnBoard" then
        local physical_conditions = p32.physical_conditions

        if physical_conditions == nil then
            error("IsLandingOnBoard requires actual State16", 0)
        end

        return physical_conditions.state == 503
    end

    if operation.tag == "Condition" then
        local evaluate = v3.ActionCondition.evaluate
        local v51 = operation[1]
        local condition_inputs, action_intents = p32.condition_inputs, p32.action_intents
        local current = p34.current
        local state_parents = p32.state_parents
        local ok, result = pcall(evaluate, v51, condition_inputs, action_intents, current, state_parents)

        if not ok then
            error(string.format("ActionGraph condition %d: %s", p33, (tostring(result))), 0)
        end

        return result
    end

    error(string.format("Unsupported ActionGraph condition %d: %s", p33, debug_option_string(v50.config.name)), 0)
end

function t1.ActionHost.condition_activation(p35, p36, p37) -- line: 384
    -- upvalues: GraphDiagnostics (copy), ActionHost_condition_body (copy)
    local ok, result = pcall(ActionHost_condition_body, p35, p36, p37)

    if ok then
        if result then
            return 1
        end
    else
        GraphDiagnostics.push(p35.errors, (tostring(result)))
    end

    return 0
end

function t1.ActionHost.context(_) -- line: 399
    return { 0, 0, 0, 0, 0, 0 }
end

function t1.ActionHost.allocate(p39, p40, _) -- line: 403
    -- upvalues: rt (copy), v5 (copy), v9 (copy), TimeMgIntent (copy)
    p39.created[p40 + 1] = false
    p39.time_handlers[p40 + 1] = TimeMgIntent.default()
    p39.body_flip[p40 + 1] = v5.State.default()
    p39.juice_pending[p40 + 1] = ""
    p39.trick_handlers[p40 + 1] = v9.State.default()

    local next_instance = p39.next_instance

    p39.next_instance = math.max(rt.wrapping_add_u32(p39.next_instance, 1), 1)

    return next_instance
end

function t1.ActionHost.begin(p42, p43, _, _) -- line: 416
    -- upvalues: rt (copy), IntentMap (copy), v5 (copy), v7 (copy), v9 (copy), t1 (copy), ActionInstance (copy), ConstMgIntent (copy), CreateMgIntent (copy), GraphDiagnostics (copy)
    local v53 = t1.ActionHost.operation(p42, p43)

    if v53 == nil then
        return
    end

    local v54 = rt.copy(v53)
    local operation = v54.operation

    if operation.tag == "CreateTrickIntentFromGesture" then
        if p42.stance ~= nil then
            local v55 = p42.stance[2]

            v9.State.begin(p42.trick_handlers[p43 + 1], operation.group, operation.override_name, p42.action_intents, p42.motion_intents, v55)
        else
            GraphDiagnostics.push(p42.errors, "CreateTrickIntentFromGesture requires published skater stance")
        end
    elseif ActionInstance.unsupported(v54) ~= nil then
        t1.ActionHost.unsupported(p42, p43, v54)
    elseif operation.tag ~= "PrintText" then
        if operation.tag == "BodyFlippingSignal" then
            local body_flip_settings = p42.body_flip_settings

            if body_flip_settings ~= nil then
                v5.State.begin(p42.body_flip[p43 + 1], rt.copy(body_flip_settings))
            else
                GraphDiagnostics.push(p42.errors, "BodyFlippingSignal requires stock anim_motion settings")
            end
        elseif operation.tag == "BoardAdjust" then
            v7.State.begin(p42.board_adjust[p43 + 1])
        else
            if operation.tag == "CreateConstMgIntent" then
                local mg_intent = v54.config.mg_intent

                if mg_intent ~= nil then
                    local v56 = ConstMgIntent.begin(p42.const_handlers[p43 + 1])

                    t1.ActionHost.apply(p42, mg_intent, v56)
                end
            end

            if operation.tag == "CreateMgIntent" then
                local mg_intent, ag_intent = v54.config.mg_intent, v54.config.ag_intent

                if mg_intent ~= nil and ag_intent ~= nil then
                    local t6 = {
                        on_update = v54.config.on_update,
                        default_value = v54.config.default_value,
                        scale = if v54.config.scale == nil then 1 else v54.config.scale,
                        filters = rt.copy(v54.config.filters)
                    }
                    local v57 = IntentMap.get(p42.action_intents, ag_intent)
                    local v58, v59 = CreateMgIntent.enter(t6, p42.created[p43 + 1], v57, p42.stance)

                    p42.created[p43 + 1] = v59
                    t1.ActionHost.apply(p42, mg_intent, v58)
                else
                    GraphDiagnostics.push(p42.errors, string.format("ActionGraph behavior %d: missing AGIntent/MGIntent", p43))
                end
            end
        end
    end
end

local t7 = {
    on_update = false,
    default_value = nil,
    scale = 1,
    filters = nil
}

local function update_instance(p46, p47, p48, p49, p50) -- line: 504
    -- upvalues: rt (copy), IntentMap (copy), v5 (copy), v9 (copy), t1 (copy), ActionInstance (copy), ConstMgIntent (copy), TimeMgIntent (copy), CreateMgIntent (copy), GraphDiagnostics (copy), t7 (copy)
    local operation = p49.operation

    if operation.tag == "CreateTrickIntentFromGesture" then
        v9.State.update(p46.trick_handlers[p47 + 1], p46.motion_intents)
    elseif ActionInstance.unsupported(p49) ~= nil then
        t1.ActionHost.unsupported(p46, p47, p49)
    elseif operation.tag == "JuiceHook" then
        IntentMap.remove(p46.motion_intents, p46.juice_pending[p47 + 1])
        p46.juice_pending[p47 + 1] = ""
    elseif operation.tag == "BodyFlippingSignal" then
        local body_flip_settings = p46.body_flip_settings

        if body_flip_settings ~= nil then
            local physical_state = p46.condition_inputs.physical_state

            if physical_state ~= nil then
                local t8 = {
                    "FrontFlip",
                    "BackFlip"
                }
                local t9 = {
                    IntentMap.contains_key(p46.action_intents, t8[1]),
                    IntentMap.contains_key(p46.action_intents, t8[2])
                }
                local v60 = v5.State.update(p46.body_flip[p47 + 1], t9, physical_state.category, p48.dt, rt.copy(body_flip_settings))

                if v60 ~= nil then
                    IntentMap.insert(p46.motion_intents, t8[v60 + 1], 1)
                else
                    for _, v61 in t8 do
                        IntentMap.remove(p46.motion_intents, v61)
                    end
                end
            else
                GraphDiagnostics.push(p46.errors, "BodyFlippingSignal requires published filtered state")
            end
        else
            GraphDiagnostics.push(p46.errors, "BodyFlippingSignal requires stock anim_motion settings")
        end
    elseif operation.tag == "BoardAdjust" then
        t1.ActionHost.publish_board_adjust(p46, p47, p49)
    elseif operation.tag == "CreateConstMgIntent" then
        local mg_intent = p49.config.mg_intent

        if mg_intent ~= nil then
            local v62 = ConstMgIntent.update(p46.const_handlers[p47 + 1])

            t1.ActionHost.apply(p46, mg_intent, v62)
        end
    else
        local ag_intent = p49.config.ag_intent

        if ag_intent ~= nil then
            local mg_intent = p49.config.mg_intent

            if mg_intent ~= nil then
                local v63 = IntentMap.get(p46.action_intents, ag_intent)
                local v64

                if operation.tag == "CreateMgIntent" then
                    local t10

                    if p50 then
                        local config = p49.config

                        t10 = t7
                        t7.on_update = config.on_update
                        t7.default_value = config.default_value
                        t7.scale = if config.scale == nil then 1 else config.scale
                        t7.filters = config.filters
                    else
                        t10 = {
                            on_update = p49.config.on_update,
                            default_value = p49.config.default_value
                        }

                        if p49.config.scale ~= nil then
                            t10.scale = p49.config.scale
                        else
                            t10.scale = 1
                        end

                        t10.filters = rt.copy(p49.config.filters)
                    end

                    local v66

                    v64, v66 = CreateMgIntent.update(t10, p46.created[p47 + 1], v63, p46.stance)
                    p46.created[p47 + 1] = v66
                else
                    if operation.tag ~= "CreateMgTimeIntent" then
                        return
                    end

                    v64 = TimeMgIntent.update(p46.time_handlers[p47 + 1], v63, p48.dt)
                end

                t1.ActionHost.apply(p46, mg_intent, v64)
            end
        end
    end
end

function t1.ActionHost.update_reference(p51, p52, _, p54) -- line: 603
    -- upvalues: rt (copy), t1 (copy), update_instance (copy)
    local v67 = t1.ActionHost.operation(p51, p52)

    if v67 == nil then
        return
    end

    return update_instance(p51, p52, p54, (rt.copy(v67)))
end

function t1.ActionHost.update(p55, p56, _, p58) -- line: 619
    -- upvalues: update_instance (copy)
    local v69 = p55.remap.behaviors[p56 + 1]

    if v69 == nil then
        return
    end

    local v70 = p55.instances.operations[v69 + 1]

    if v70 == nil then
        return
    end

    return update_instance(p55, p56, p58, v70, true)
end

t1.ActionHost["end"] = function(p59, p60, _, _) -- line: 637
    -- upvalues: rt (copy), IntentMap (copy), v9 (copy), t1 (copy), ConstMgIntent (copy), TimeMgIntent (copy)
    local v71 = t1.ActionHost.operation(p59, p60)

    if v71 == nil then
        return
    end

    local v72 = rt.copy(v71)
    local operation = v72.operation

    if operation.tag == "BoardAdjust" then
        local mg_intent_mag = v72.config.mg_intent_mag

        if mg_intent_mag ~= nil then
            IntentMap.remove(p59.motion_intents, mg_intent_mag)
        end

        local mg_intent_angle = v72.config.mg_intent_angle

        if mg_intent_angle ~= nil then
            IntentMap.remove(p59.motion_intents, mg_intent_angle)
        end
    elseif operation.tag == "CreateTrickIntentFromGesture" then
        v9.State["end"](p59.trick_handlers[p60 + 1], p59.motion_intents)
    else
        local mg_intent = v72.config.mg_intent

        if mg_intent ~= nil then
            local v73 = if operation.tag == "CreateConstMgIntent" then ConstMgIntent["end"](p59.const_handlers[p60 + 1])
                elseif operation.tag == "CreateMgTimeIntent" then TimeMgIntent["end"](p59.time_handlers[p60 + 1])
                else {
                    tag = "Remove"
                }

            t1.ActionHost.apply(p59, mg_intent, v73)
        end
    end
end

function t1.ActionHost.hook(p63, p64, _) -- line: 674
    -- upvalues: rt (copy), t1 (copy), ActionInstance (copy), ActionInstances (copy), GraphDiagnostics (copy)
    local v74 = p63.remap.hooks[p64 + 1]
    local v75 = if v74 == nil then nil else ActionInstances.get(p63.instances, v74)

    if v75 ~= nil then
        local v76 = rt.copy(v75)

        if ActionInstance.unsupported(v76) ~= nil then
            t1.ActionHost.unsupported(p63, p64, v76)
        end
    else
        GraphDiagnostics.push(p63.errors, string.format("ActionGraph hook index %d is unbound", p64))
    end
end

function t1.ActionHost.release(_, _) -- line: 690
end

return t1
