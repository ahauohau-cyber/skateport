-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_core/animation/output/attributes")
local v2 = import("skate_core/animation/skeleton_input/name")
local v3 = import("skate_core/graph/conditions")
local v4 = import("skate_core/riding/push_behaviors")
local v5 = import("skate_core/input/set_turning")
local v6 = import("skate_data/state_graph/attributes")
local v7 = import("skate_data/state_graph/binding")
local v8 = import("skate_game/input/gesture_catalog")
local v9 = import("skate_game/graph_host/condition_nodes")
local v10 = import("skate_game/graph_host/motion_animation")
local v11 = import("skate_game/graph_host/motion_grind/conditions")
local v12 = import("skate_game/graph_host/motion_stock_gameplay")
local v13 = import("skate_game/graph_host/motion_offboard/dismount")
local v14 = import("skate_game/graph_host/motion_landing")
local v15 = import("skate_game/graph_host/motion_wipeout")
local v16 = import("skate_game/graph_host/motion_offboard/push_off")
local v17 = import("skate_game/graph_host/motion_gameplay_conditions")
local v18 = import("skate_game/graph_host/motion_riding_conditions")
local v19 = import("skate_game/graph_host/motion_offboard/cadence")
local v20 = import("skate_game/graph_host/motion_ground_slope")
local v21 = import("skate_game/graph_host/motion_stock_conditions")
local v22 = import("skate_game/graph_host/motion_spin")
local v23 = import("skate_game/graph_host/outputs")
local t1 = {}
local Attributes = v6.Attributes
local AttributeName = v1.AttributeName
local NumericCondition, ActionCondition = v3.NumericCondition, v3.ActionCondition
local MotionAnimation = v10.MotionAnimation
local GameplayCondition = v17.GameplayCondition
local MotionRidingCondition = v18.MotionRidingCondition
local encode = v2.encode
local t2 = {
    "\t",
    "\n",
    "\011",
    "\012",
    "\r",
    " ",
    "\000",
    "\194\133",
    " ",
    " ",
    " ",
    " ",
    " ",
    " ",
    " ",
    " ",
    " ",
    " ",
    " ",
    " ",
    " ",
    "\226\128\168",
    "\226\128\169",
    " ",
    " ",
    "　"
}

local function trim_whitespace_nul(p1) -- line: 75
    -- upvalues: t2 (copy)
    local v24 = #p1
    local n1 = 1

    while true do
        if n1 <= v24 then
            local v25 = false

            for _, v26 in t2 do
                local v27 = #v26

                if n1 + v27 - 1 <= v24 and string.sub(p1, n1, n1 + v27 - 1) == v26 then
                    n1 += v27
                    v25 = true
                    break
                end
            end

            if v25 then
                continue
            end
        end

        break
    end

    while true do
        if n1 <= v24 then
            local v29 = false

            for _, v30 in t2 do
                local v31 = #v30

                if n1 <= v24 - v31 + 1 and string.sub(p1, v24 - v31 + 1, v24) == v30 then
                    v24 -= v31
                    v29 = true
                    break
                end
            end

            if v29 then
                continue
            end
        end

        break
    end

    return (string.sub(p1, n1, v24))
end

t1.MotionCondition = {}

function t1.MotionCondition.parse(p2) -- line: 139
    -- upvalues: rt (copy), v8 (copy), v9 (copy), v11 (copy), v12 (copy), v13 (copy), v14 (copy), v15 (copy), v16 (copy), v19 (copy), v20 (copy), v21 (copy), Attributes (copy), GameplayCondition (copy), MotionRidingCondition (copy), encode (copy), trim_whitespace_nul (copy)
    local v33 = v11.Condition.parse(p2)

    if v33 ~= nil then
        return {
            tag = "Grind",
            v33
        }
    end

    local v34 = v14.Condition.parse(p2)

    if v34 ~= nil then
        return {
            tag = "Landing",
            v34
        }
    end

    local v35 = v15.Condition.parse(p2)

    if v35 ~= nil then
        return {
            tag = "Wipeout",
            v35
        }
    end

    local v36 = v16.IsPushOffEnabled.parse(p2)

    if v36 ~= nil then
        return {
            tag = "PushOff",
            v36
        }
    end

    local v37 = v13.Condition.parse(p2)

    if v37 ~= nil then
        return {
            tag = "DisableDismount",
            v37
        }
    end

    local function numeric() -- line: 170
        -- upvalues: p2 (copy), v9 (copy)
        return v9.numeric(p2)
    end

    local function text_or(p3, p4) -- line: 173
        -- upvalues: p2 (copy), Attributes (copy)
        local v38 = Attributes.text(p2, p3)

        if v38 == nil then
            return p4
        end

        return v38
    end

    local name = Attributes.text(p2, "name")

    if name == nil then
        name = ""
    end

    local v39 = trim_whitespace_nul(name)

    if v39 == "HasTweak" then
        return {
            tag = "HasTweak",
            (v9.numeric(p2))
        }
    end

    if v39 == "CurrentGrabType" then
        local grab = Attributes.text(p2, "grab")

        if grab == nil then
            error("CurrentGrabType requires grab", 0)
        end

        return {
            tag = "CurrentGrabType",
            (v12.GrabType.parse(grab))
        }
    end

    if v39 == "ManualOutTimerIsActive" then
        return {
            tag = "ManualOutTimerIsActive"
        }
    end

    if v39 == "HasGestureIntent" then
        local parse = v8.Group.parse
        local group = Attributes.text(p2, "group")

        if group == nil then
            group = ""
        end

        return {
            tag = "Gesture",
            (parse(group))
        }
    end

    if v39 == "HasIntent" or v39 == "HasFilteredMotionGraphIntent" then
        local t4 = {
            tag = "Intent"
        }
        local intent = Attributes.text(p2, "intent")

        t4.name = if intent == nil then "" else intent
        t4.filtered = Attributes.text(p2, "name") == "HasFilteredMotionGraphIntent"
        t4.numeric = v9.numeric(p2)

        return t4
    end

    if v39 == "HasAnimAttribute" then
        local t5 = {
            tag = "AnimationAttribute"
        }
        local attribute = Attributes.text(p2, "attribute")

        if attribute == nil then
            attribute = ""
        end

        t5.name = encode(attribute)
        t5.sequence_id = rt.f_to_i32(rt.from_bits(Attributes.float_bits(p2, "sequenceid", rt.to_bits(-1))))
        t5.numeric = v9.numeric(p2)

        return t5
    end

    if v39 == "ExpireInTime" then
        return {
            tag = "ExpireInTime",
            (v9.numeric(p2))
        }
    end

    if v39 == "WillExpire" then
        local InTimeTag = Attributes.text(p2, "InTimeTag")

        if InTimeTag ~= nil and InTimeTag == "" then
            InTimeTag = nil
        end

        return {
            tag = "WillExpire",
            in_time = rt.from_bits(Attributes.float_bits(p2, "InTime", 0)),
            tag_ = InTimeTag,
            wait_for_transitions = Attributes.boolean_byte(p2, "waitForTransitions", 1) ~= 0
        }
    end

    if v39 == "InTimeWindow" then
        return {
            tag = "InTimeWindow",
            start = rt.from_bits(Attributes.float_bits(p2, "StartTime", 0)),
            length = rt.from_bits(Attributes.float_bits(p2, "WindowFrameLength", 0))
        }
    end

    if v39 == "InStateForTime" then
        local t6 = {
            tag = "InStateForTime",
            target = nil
        }
        local state = Attributes.text(p2, "state")

        t6.name = if state == nil then "" else state
        t6.numeric = v9.numeric(p2)

        return t6
    end

    if v39 == "InParentStateForTime" then
        return {
            tag = "InParentStateForTime",
            target = nil,
            numeric = v9.numeric(p2)
        }
    end

    if v39 == "IsProSkater" then
        local skater = Attributes.text(p2, "skater")

        if skater == nil then
            skater = ""
        end

        return {
            tag = "ProSkater",
            (encode(skater))
        }
    end

    if v39 == "BreakOutOfPush" then
        return {
            tag = "BreakOutOfPush"
        }
    end

    if v39 == "ShouldLeaveSlide" then
        return {
            tag = "ShouldLeaveSlide",
            right = Attributes.boolean_byte(p2, "right", 1) ~= 0
        }
    end

    if v39 == "IsRidingGoofy" then
        return {
            tag = "RidingGoofy"
        }
    end

    if v39 == "IsRidingSwitch" then
        return {
            tag = "RidingSwitch"
        }
    end

    if v39 == "MongoPushFootToFar" then
        return {
            tag = "MongoPushFootTooFar"
        }
    end

    if v39 == "LastState" then
        local t8 = {
            tag = "LastState",
            target = nil
        }
        local state = Attributes.text(p2, "state")

        t8.name = if state == nil then "" else state

        return t8
    end

    if GameplayCondition.recognizes(v39) then
        return {
            tag = "Gameplay",
            (GameplayCondition.parse(p2))
        }
    end

    if MotionRidingCondition.recognizes(v39) then
        return {
            tag = "Riding",
            (MotionRidingCondition.parse(p2))
        }
    end

    if v39 == "TimeToLand" then
        return {
            tag = "TimeToLand",
            (v9.numeric(p2))
        }
    end

    if v39 == "OBTimeToLand" then
        return {
            tag = "ObTimeToLand",
            (v9.numeric(p2))
        }
    end

    if v39 == "OBTrajTime" then
        return {
            tag = "ObTrajTime",
            (v9.numeric(p2))
        }
    end

    if v39 == "LocoState" then
        return {
            tag = "LocoState",
            (v19.LocoState.parse(p2))
        }
    end

    if v39 == "GroundSlopeType" then
        return {
            tag = "GroundSlopeType",
            (v20.GroundSlopeType.parse(p2))
        }
    end

    if v39 == "IsBipedGroundThin" then
        return {
            tag = "IsBipedGroundThin"
        }
    end

    if v39 == "IsHoldingSkateboard" then
        return {
            tag = "IsHoldingSkateboard"
        }
    end

    if v39 == "IsStandingOnMovingObject" then
        return {
            tag = "IsStandingOnMovingObject"
        }
    end

    if v39 == "IsInDebugAnimationsMode" then
        return {
            tag = "DebugAnimationsMode"
        }
    end

    if v21.Condition.recognizes(v39) then
        return {
            tag = "StockGameplay",
            (v21.Condition.parse(p2))
        }
    end

    local v40 = v9.parse(p2)

    return if v40 ~= nil then {
        tag = "Shared",
        v40
    } else nil
end

local v41, RightToeBase, LeftToeBase

local function payload_matches(p5, p6) -- line: 300
    for i = 1, 5 do
        local v42 = p5.payload[1][i]

        if v42 == nil or v42 ~= p6[1][i] then
            return false
        end
    end

    return true
end

local function mongo_push_foot_too_far_reference(p7) -- line: 312
    -- upvalues: v4 (copy), AttributeName (copy), MotionAnimation (copy), encode (copy)
    local v43
    local push_contact = encode("push_contact")
    local v44

    for _, v45 in MotionAnimation.tree_attributes(p7.animation) do
        if AttributeName.eq(v45.name, push_contact) then
            v43 = v45
            v44 = v45
            break
        end
    end

    if v44 == nil then
        return false
    end

    local function matches(p8) -- line: 325
        -- upvalues: v43 (ref), encode (copy)
        local v46 = encode(p8)

        for i = 1, 5 do
            local v47 = v43.payload[1][i]

            if v47 == nil or v47 ~= v46[1][i] then
                return false
            end
        end

        return true
    end

    local RightToeBase = matches("RightToeBase")
    local LeftToeBase = matches("LeftToeBase")
    local is_mirrored = p7.playback_context.is_mirrored

    if is_mirrored == nil then
        error("MongoPushFootToFar requires actual mirrored stance", 0)
    end

    local foot_frame

    if not is_mirrored and RightToeBase then
        if p7.physical ~= nil then
            foot_frame = p7.physical.foot_frame
        end

        if foot_frame == nil then
            error("MongoPushFootToFar requires actual foot frame", 0)
        end

        return v4.PushFootFrame.out_distance(foot_frame, RightToeBase)[1] < -0.5
    end

    if not is_mirrored or not LeftToeBase then
        return false
    end

    foot_frame = if p7.physical ~= nil then p7.physical.foot_frame else nil

    if foot_frame == nil then
        error("MongoPushFootToFar requires actual foot frame", 0)
    end

    return v4.PushFootFrame.out_distance(foot_frame, RightToeBase)[1] < -0.5
end

local function mongo_push_foot_too_far(p9) -- line: 358
    -- upvalues: v4 (copy), AttributeName (copy), MotionAnimation (copy), encode (copy), v41 (ref), RightToeBase (ref), LeftToeBase (ref), payload_matches (copy)
    local v48 = v41

    if v48 == nil then
        v48 = encode("push_contact")

        local RightToeBase2 = encode("RightToeBase")
        local LeftToeBase2 = encode("LeftToeBase")

        v41 = v48
        RightToeBase = RightToeBase2
        LeftToeBase = LeftToeBase2
    end

    local v49

    for _, v50 in MotionAnimation.tree_attributes(p9.animation) do
        if AttributeName.eq(v50.name, v48) then
            v49 = v50
            break
        end
    end

    if v49 == nil then
        return false
    end

    local v51 = payload_matches(v49, RightToeBase)
    local v52 = payload_matches(v49, LeftToeBase)
    local is_mirrored = p9.playback_context.is_mirrored

    if is_mirrored == nil then
        error("MongoPushFootToFar requires actual mirrored stance", 0)
    end

    local foot_frame

    if not is_mirrored and v51 then
        if p9.physical ~= nil then
            foot_frame = p9.physical.foot_frame
        end

        if foot_frame == nil then
            error("MongoPushFootToFar requires actual foot frame", 0)
        end

        return v4.PushFootFrame.out_distance(foot_frame, v51)[1] < -0.5
    end

    if not is_mirrored or not v52 then
        return false
    end

    foot_frame = if p9.physical ~= nil then p9.physical.foot_frame else nil

    if foot_frame == nil then
        error("MongoPushFootToFar requires actual foot frame", 0)
    end

    return v4.PushFootFrame.out_distance(foot_frame, v51)[1] < -0.5
end

t1.mongo_push_foot_too_far = mongo_push_foot_too_far
t1.mongo_push_foot_too_far_reference = mongo_push_foot_too_far_reference

function t1.MotionCondition.evaluate(p10, p11, p12) -- line: 408
    -- upvalues: v5 (copy), v8 (copy), v9 (copy), v11 (copy), v13 (copy), v14 (copy), v15 (copy), v16 (copy), v19 (copy), v20 (copy), v21 (copy), v22 (copy), v23 (copy), AttributeName (copy), NumericCondition (copy), ActionCondition (copy), MotionAnimation (copy), GameplayCondition (copy), MotionRidingCondition (copy), mongo_push_foot_too_far (copy)
    local tag = p10.tag

    if tag == "Grind" then
        local grind_conditions = p11.grind_conditions

        if grind_conditions == nil then
            error("Grind condition requires completed physical output", 0)
        end

        return v11.Condition.evaluate(p10[1], grind_conditions)
    end

    if tag == "CurrentGrabType" then
        return p11.animation.grab_type == p10[1]
    end

    if tag == "HasTweak" then
        local v53 = p10[1]
        local TweakX = MotionAnimation.filtered_intent(p11.animation, "TweakX")
        local TweakY = MotionAnimation.filtered_intent(p11.animation, "TweakY")

        if TweakX == nil and TweakY == nil then
            return false
        end

        if v53.comparison == "None" then
            return true
        end

        local v54 = if TweakX == nil then 0 else TweakX

        if TweakY == nil then
            TweakY = 0
        end

        return NumericCondition.matches(v53, (math.sqrt(v54 ^ 2 + TweakY ^ 2)))
    end

    if tag == "ManualOutTimerIsActive" then
        return p11.riding.manual_out_timer > 0
    end

    if tag == "ShouldLeaveSlide" then
        return v5.SlideLatch.should_leave(p11.slide_latch, p10.right)
    end

    if tag == "Gesture" then
        return v8.Group.has_intent(p10[1], function(p13) -- line: 441
            -- upvalues: p11 (copy), v23 (copy)
            return v23.ActionControls.has(p11.action_controls, p13)
        end)
    end

    if tag == "DisableDismount" then
        return v13.Condition.evaluate(p10[1], p11.condition_inputs.push_brake)
    end

    if tag == "Shared" then
        return ActionCondition.evaluate(p10[1], p11.condition_inputs, p11.action_intents, p12.current, p11.state_parents)
    end

    if tag == "Gameplay" then
        return GameplayCondition.evaluate(p10[1], p11)
    end

    if tag == "Riding" then
        return MotionRidingCondition.evaluate(p10[1], p11)
    end

    if tag == "TimeToLand" then
        local gameplay_conditions = p11.gameplay_conditions

        if gameplay_conditions == nil then
            error("TimeToLand requires physical condition publication", 0)
        end

        return gameplay_conditions.time_to_land_valid and NumericCondition.matches(p10[1], gameplay_conditions.time_to_land)
    end

    if tag == "ObTimeToLand" then
        local gameplay_conditions = p11.gameplay_conditions

        if gameplay_conditions == nil then
            error("OBTimeToLand requires physical condition publication", 0)
        end

        return NumericCondition.matches(p10[1], gameplay_conditions.offboard_time_to_land)
    end

    if tag == "ObTrajTime" then
        local gameplay_conditions = p11.gameplay_conditions

        if gameplay_conditions == nil then
            error("OBTrajTime requires physical condition publication", 0)
        end

        return gameplay_conditions.offboard_trajectory_valid and NumericCondition.matches(p10[1], gameplay_conditions.offboard_trajectory_time)
    end

    if tag == "DebugAnimationsMode" then
        return false
    end

    if tag == "LocoState" then
        local offboard_locomotion_state = p11.offboard_locomotion_state

        if offboard_locomotion_state == nil then
            error("LocoState requires retained Biped locomotion through OffBoard84", 0)
        end

        return v19.LocoState.evaluate(p10[1], offboard_locomotion_state)
    end

    if tag == "GroundSlopeType" then
        local ground_slope_type = p11.ground_slope_type

        if ground_slope_type == nil then
            error("GroundSlopeType requires the completed ground slope publication", 0)
        end

        return v20.GroundSlopeType.matches(p10[1], ground_slope_type)
    end

    if tag == "IsBipedGroundThin" then
        local biped_ground_thin = p11.biped_ground_thin

        if biped_ground_thin == nil then
            error("IsBipedGroundThin requires the native ground geometry publication", 0)
        end

        return biped_ground_thin
    end

    if tag == "IsHoldingSkateboard" then
        local toggle_board_physical = p11.toggle_board_physical

        return toggle_board_physical ~= nil and toggle_board_physical.holding_board
    end

    if tag == "IsStandingOnMovingObject" then
        local gameplay_conditions = p11.gameplay_conditions

        if gameplay_conditions == nil then
            error("IsStandingOnMovingObject requires the physical state publication", 0)
        end

        return gameplay_conditions.moving_object
    end

    if tag == "StockGameplay" then
        return v21.Condition.evaluate(p10[1], p11)
    end

    if tag == "PushOff" then
        return v16.IsPushOffEnabled.evaluate(p10[1])
    end

    if tag == "Wipeout" then
        return v15.Condition.evaluate(p10[1], p11.wipeout_physical)
    end

    if tag == "Landing" then
        local prelanding_physical = p11.prelanding_physical
        local v56 = if prelanding_physical == nil then nil else v22.PrelandingPhysical.override_prelanding(prelanding_physical, p11.spin)

        return v14.Condition.evaluate(p10[1], p11.landing_physical, p11.flags, v56)
    end

    if tag == "LastState" then
        local target = p10.target
        local last = p12.last

        if target == nil then
            return false
        end

        while true do
            if last == nil then
                return false
            end

            if last == target then
                break
            end

            last = p11.state_parents[last + 1]
        end

        return true
    end

    if tag == "Intent" then
        local numeric = p10.numeric
        local v57 = if p10.filtered then MotionAnimation.filtered_intent(p11.animation, p10.name) else MotionAnimation.motion_intent(p11.animation, p10.name)

        if v57 == nil then
            return false
        end

        if numeric.comparison == "None" then
            return true
        end

        return (NumericCondition.matches(numeric, v57))
    end

    if tag == "AnimationAttribute" then
        return v9.animation_attribute(MotionAnimation.tree_attributes(p11.animation), p10.name, p10.sequence_id, p10.numeric)
    end

    if tag == "ExpireInTime" then
        return NumericCondition.matches(p10[1], MotionAnimation.property(p11.animation).remaining_before_wrap)
    end

    if tag == "WillExpire" then
        local tag_ = p10.tag_
        local time_tags = p11.time_tags
        local v58

        if tag_ == nil or time_tags == nil then
            v58 = p10.in_time
        else
            v58 = time_tags[tag_]

            if v58 == nil then
                error(("Missing MotionGraph float tag %*"):format(tag_), 0)
            end
        end

        if p10.wait_for_transitions and MotionAnimation.in_transition(p11.animation) then
            return false
        end

        local v59 = MotionAnimation.property(p11.animation)

        return v59.crossed_end or not (v58 < v59.remaining_before_wrap)
    end

    if tag == "InTimeWindow" then
        if MotionAnimation.in_transition(p11.animation) then
            return false
        end

        local v60 = MotionAnimation.current_time(p11.animation)

        return not (v60 < p10.start) and not (p10.start + p10.length < v60)
    end

    if tag == "InStateForTime" or tag == "InParentStateForTime" then
        return v9.state_time(p12, p10.target, p10.numeric)
    end

    if tag == "ProSkater" then
        return AttributeName.eq(p11.playback_context.pro_skater, p10[1])
    end

    if tag == "BreakOutOfPush" then
        local push_state = p11.push_state

        if push_state == nil then
            error("BreakOutOfPush requires initialized native push state", 0)
        end

        local v61 = MotionAnimation.current_time(p11.animation)
        local v62 = MotionAnimation.current_length(p11.animation)

        return not (v61 < push_state.out_factor * v62) and not push_state.continue_push
    end

    if tag == "RidingGoofy" then
        local physical_stance = p11.physical_stance

        if physical_stance == nil then
            error("IsRidingGoofy requires PhysOutAnimation stance bytes", 0)
        end

        return physical_stance[1] == physical_stance[2]
    end

    if tag == "RidingSwitch" then
        local is_switch = p11.playback_context.is_switch

        if is_switch == nil then
            error("IsRidingSwitch requires actual relative stance", 0)
        end

        return is_switch
    end

    if tag == "MongoPushFootTooFar" then
        return (mongo_push_foot_too_far(p11))
    end

    error("internal error: entered unreachable code", 0)
end

function t1.bind_states(p14, p15) -- line: 622
    -- upvalues: v7 (copy)
    local t9 = {}

    for v63, v64 in p14.source.elements do
        local v65 = v63 - 1

        for _, v66 in v64.children do
            t9[v66 + 1] = v65
        end
    end

    for _, v67 in p14.runtime.operations.conditions do
        local v68 = p15[v67 + 1]

        if v68 == nil then
            error("index out of bounds", 0)
        end

        if v68.tag == "Condition" then
            local v69 = v68[1]

            if v69.tag == "Shared" and v69[1].tag == "CurrentState" then
                local name = v69[1].name

                v69 = v69[1]

                local v70 = t9[p14.binding.operations[v67 + 1].element + 1]

                while true do
                    if v70 ~= nil then
                        local v71

                        for v72, v73 in p14.binding.states do
                            if v73.element == v70 then
                                v71 = v72 - 1
                                break
                            end
                        end

                        if v71 == nil then
                            v70 = t9[v70 + 1]
                            continue
                        end

                        if name ~= nil then
                            v69.target = v7.Binding.find_state(p14.binding, v71, name, true)
                        else
                            v69.target = v71
                        end
                    end

                    break
                end
            elseif v69.tag == "InStateForTime" or v69.tag == "LastState" then
                local name = v69.name
                local v74 = t9[p14.binding.operations[v67 + 1].element + 1]

                while true do
                    if v74 ~= nil then
                        local v75

                        for v76, v77 in p14.binding.states do
                            if v77.element == v74 then
                                v75 = v76 - 1
                                break
                            end
                        end

                        if v75 == nil then
                            v74 = t9[v74 + 1]
                            continue
                        end

                        if name ~= nil then
                            v69.target = v7.Binding.find_state(p14.binding, v75, name, true)
                        else
                            v69.target = v75
                        end
                    end

                    break
                end
            elseif v69.tag == "InParentStateForTime" then
                local v78 = t9[p14.binding.operations[v67 + 1].element + 1]

                while true do
                    if v78 ~= nil then
                        local v79

                        for v80, v81 in p14.binding.states do
                            if v81.element == v78 then
                                v79 = v80 - 1
                                break
                            end
                        end

                        if v79 == nil then
                            v78 = t9[v78 + 1]
                            continue
                        end

                        v69.target = v79
                    end

                    break
                end
            end
        end
    end
end

return t1
