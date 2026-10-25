-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local v1 = import("skate_game/skater_animation/state")
local PoseEvaluator = import("skate_game/animation_pose").PoseEvaluator
local ActionHost = import("skate_game/graph_host/action").ActionHost
local MotionHost = import("skate_game/graph_host/motion").MotionHost
local MotionAnimation = import("skate_game/graph_host/motion_animation").MotionAnimation
local v2 = import("skate_game/graph_host/outputs")
local IntentMap = import("skate_core/graph/intents").IntentMap
local v3 = import("skate_core/animation/output")
local PacketAttributes = import("skate_core/animation/output/attributes").PacketAttributes
local v4 = import("skate_core/animation/output/packet_reset")
local v5 = import("skate_core/animation/output/physics_packet")
local PosturePose = import("skate_core/animation/posture").PosturePose
local encode = import("skate_core/animation/skeleton_input/name").encode
local Controller = import("skate_core/graph/controller").Controller
local AnimationBanks = import("skate_data/animation_banks").AnimationBanks
local AnimationFrames = import("skate_data/animation_frames").AnimationFrames
local AnimationState = v1.AnimationState
local RESET_POSE = v4.RESET_POSE
local ActionInput, PriorMotionState, GraphDiagnostics = v2.ActionInput, v2.PriorMotionState, v2.GraphDiagnostics
local t1 = {}
local v6 = true

local function graph_host(p1, p2) -- line: 41
    return {
        condition_activation = function(_, p4, p5) -- condition_activation | line: 43
            -- upvalues: p1 (copy), p2 (copy)
            return p1.condition_activation(p2, p4, p5)
        end,
        context = function(_) -- context | line: 46
            -- upvalues: p1 (copy), p2 (copy)
            return p1.context(p2)
        end,
        allocate = function(_, p8, p9) -- allocate | line: 49
            -- upvalues: p1 (copy), p2 (copy)
            return p1.allocate(p2, p8, p9)
        end,
        begin = function(_, p11, p12, p13) -- begin | line: 52
            -- upvalues: p1 (copy), p2 (copy)
            return p1.begin(p2, p11, p12, p13)
        end,
        update = function(_, p15, p16, p17) -- update | line: 55
            -- upvalues: p1 (copy), p2 (copy)
            return p1.update(p2, p15, p16, p17)
        end,
        ["end"] = function(_, p19, p20, p21) -- line: 58
            -- upvalues: p1 (copy), p2 (copy)
            return p1["end"](p2, p19, p20, p21)
        end,
        hook = function(_, p23, p24) -- hook | line: 61
            -- upvalues: p1 (copy), p2 (copy)
            return p1.hook(p2, p23, p24)
        end,
        release = function(_, p26) -- release | line: 64
            -- upvalues: p1 (copy), p2 (copy)
            return p1.release(p2, p26)
        end
    }
end

local function shared_graph_host(p27) -- line: 81
    local t3 = {
        0, 0, 0, 0, 0, 0
    }

    return {
        value = nil,
        scratch = t3,
        condition_activation = function(p28, p29, p30) -- condition_activation | line: 87
            -- upvalues: p27 (copy)
            return p27.condition_activation(p28.value, p29, p30)
        end,
        context = function(_) -- context | line: 90
            -- upvalues: t3 (copy)
            t3[1] = 0
            t3[2] = 0
            t3[3] = 0
            t3[4] = 0
            t3[5] = 0
            t3[6] = 0

            return t3
        end,
        allocate = function(p32, p33, p34) -- allocate | line: 94
            -- upvalues: p27 (copy)
            return p27.allocate(p32.value, p33, p34)
        end,
        begin = function(p35, p36, p37, p38) -- begin | line: 97
            -- upvalues: p27 (copy)
            return p27.begin(p35.value, p36, p37, p38)
        end,
        update = function(p39, p40, p41, p42) -- update | line: 100
            -- upvalues: p27 (copy)
            return p27.update(p39.value, p40, p41, p42)
        end,
        ["end"] = function(p43, p44, p45, p46) -- line: 103
            -- upvalues: p27 (copy)
            return p27["end"](p43.value, p44, p45, p46)
        end,
        hook = function(p47, p48, p49) -- hook | line: 106
            -- upvalues: p27 (copy)
            return p27.hook(p47.value, p48, p49)
        end,
        release = function(p50, p51) -- release | line: 109
            -- upvalues: p27 (copy)
            return p27.release(p50.value, p51)
        end
    }
end

local v7 = shared_graph_host(ActionHost)
local v8 = shared_graph_host(MotionHost)

local function update_controller(p52, p53, p54, p55, p56, p57) -- line: 118
    -- upvalues: Controller (copy), v6 (ref)
    p56.value = p57

    if v6 then
        Controller.update_typed(p52, p53, p54, p56, p55, p57, p56.scratch)
    else
        Controller.update(p52, p53, p54, p56)
    end

    p56.value = nil
end

function t1.set_typed_controller(p58) -- line: 135
    -- upvalues: v6 (ref)
    v6 = p58
end

local function debug_buffer_error(p59) -- line: 140
    if type(p59) ~= "table" or p59.tag == nil then
        return (tostring(p59))
    end

    if p59.tag == "UninitializedBone" then
        return string.format("UninitializedBone { bone: %d }", p59.bone)
    end

    return p59.tag
end

t1.AnimationSource = {}

local AnimationSource = t1.AnimationSource

function t1.AnimationSource.load(p60, p61) -- line: 158
    -- upvalues: PoseEvaluator (copy), AnimationBanks (copy)
    local v9 = AnimationBanks.load(p60)
    local v10 = PoseEvaluator.from_banks(v9)

    PoseEvaluator.load_authored_clips(v10, p60, p61)

    return {
        banks = v9,
        evaluator = v10
    }
end

t1.AnimationPhysical = {}
t1.SkaterAnimation = {}

local SkaterAnimation = t1.SkaterAnimation

t1.SkaterAnimation.graph_host = graph_host
t1.SkaterAnimation.shared_graph_host = shared_graph_host

function t1.SkaterAnimation.checkpoint_stance(p62) -- line: 191
    -- upvalues: AnimationState (copy)
    local publication = p62.state.publication

    if (publication.natural_stance == 0 and publication.relative_stance == 0 or publication.natural_stance == 1 and publication.relative_stance == 1) == AnimationState.fakie(p62.state) then
        return 0
    end

    return 1
end

function t1.SkaterAnimation.request_checkpoint_stance(p63, p64) -- line: 200
    local natural_stance = p63.state.publication.natural_stance
    local v11 = if p64 == 0 then natural_stance ~= 1 else natural_stance == 1

    p63.motion.animation.requested_stance = v11 and 1 or 0
end

function t1.SkaterAnimation.foot_forward(p65) -- line: 212
    -- upvalues: SkaterAnimation (copy)
    return SkaterAnimation.checkpoint_stance(p65) ~= 0
end

function t1.SkaterAnimation.restore_foot_forward(p66, p67) -- line: 217
    -- upvalues: SkaterAnimation (copy)
    SkaterAnimation.request_checkpoint_stance(p66, p67 and 1 or 0)
end

function t1.SkaterAnimation.set_customisation(p68, p69, p70) -- line: 224
    -- upvalues: rt (copy), encode (copy)
    if p69 <= 1 and p68.state.publication.natural_stance ~= rt.to_i32(p69) then
        p68.state.publication.natural_stance = rt.to_i32(p69)
        p68.state.flags = bit32.bxor(p68.state.flags, 3221225472)
    end

    local v12 = if p70 == 1 then "Loose"
        elseif p70 == 2 then "Gonzo"
        elseif p70 == 3 then "Aggressive"
        else ""

    p68.motion.playback_context.pro_skater = encode(v12)
end

function t1.SkaterAnimation.stance(p71) -- line: 245
    -- upvalues: AnimationState (copy)
    return AnimationState.fakie(p71.state), AnimationState.mirrored(p71.state)
end

function t1.SkaterAnimation.evaluate_initial_pose(p72) -- line: 254
    -- upvalues: PoseEvaluator (copy)
    p72.pose = PoseEvaluator.evaluate(p72.evaluator, {
        {
            tag = "Pose",
            name = "RIG_TPOSE"
        }
    })

    return PoseEvaluator.hierarchy(p72.evaluator, p72.pose)
end

function t1.SkaterAnimation.load(p73, p74, p75, p76, p77) -- line: 261
    -- upvalues: AnimationSource (copy), SkaterAnimation (copy)
    return SkaterAnimation.from_source(p74, p75, p76, AnimationSource.load(p73, p77))
end

function t1.SkaterAnimation.from_source(p78, p79, p80, p81) -- line: 267
    -- upvalues: rt (copy), ActionHost (copy), MotionHost (copy), MotionAnimation (copy), PacketAttributes (copy), PosturePose (copy), encode (copy), Controller (copy), AnimationBanks (copy), AnimationFrames (copy), AnimationState (copy), RESET_POSE (copy)
    local evaluator = p81.evaluator
    local v13 = AnimationState.new(true)
    local v14 = #evaluator.frames.bone_names
    local v15 = AnimationBanks.metadata(p81.banks)
    local t5 = {
        board_available = nil,
        transition_override = nil,
        is_switch = AnimationState.switch(v13),
        is_mirrored = AnimationState.mirrored(v13),
        pro_skater = encode(p80)
    }
    local from_graph = MotionHost.from_graph
    local motion = p79.motion
    local ok, result = pcall(from_graph, motion, p78, v15, t5)

    if not ok then
        error("Stock MotionGraph initialization: " .. tostring(result), 0)
    end

    MotionAnimation.set_hierarchy(result.animation, evaluator.frames.bone_names, evaluator.frames.mirror_indices)

    for _, v16 in ipairs({ "Stiff", "Slouch", "Buff" }) do
        local v17 = AnimationFrames.named_pose(evaluator.frames, PosturePose.name(v16))

        if #v17.samples ~= v14 then
            error(string.format("Stock posture %s has %d bones; skater hierarchy has %d", PosturePose.name(v16), #v17.samples, v14), 0)
        end
    end

    result.animation.posture_bank_valid = true
    result.animation.skater_animation_flags = v13.flags

    local from_graph2 = ActionHost.from_graph
    local action = p79.action
    local ok2, result2 = pcall(from_graph2, action, p78)

    if not ok2 then
        error("Stock ActionGraph initialization: " .. tostring(result2), 0)
    end

    return {
        ticks = 0,
        action = result2,
        motion = result,
        evaluator = evaluator,
        source = p81,
        pose = {},
        attributes = PacketAttributes.default(),
        state = v13,
        action_controller = Controller.new(#p79.action.runtime.program.topology.states),
        motion_controller = Controller.new(#p79.motion.runtime.program.topology.states),
        packet = {
            bone_count = v14,
            hierarchy = rt.filled(v14, RESET_POSE),
            ["local"] = rt.filled(v14, RESET_POSE),
            timestep = 0.01666666753590107,
            foot_surface_ids = { 0, 0 },
            flags = 0,
            board_flipped = false,
            mirrored = false,
            riding_switch = false,
            riding_fakie = false,
            weight_forwards = false,
            regular_stance = false,
            air_dismount_revert_frames = 0
        }
    }
end

local function reset_and_publish_reference(p82, p83, p84, p85) -- line: 337
    -- upvalues: v4 (copy), v5 (copy)
    local reset = v4.reset
    local packet = p82.packet
    local ok, result = pcall(reset, packet, p85)

    if not ok then
        error("Animation packet reset: " .. (if type(result) ~= "table" then tostring(result)
            elseif result.tag == nil then tostring(result)
            elseif result.tag == "UninitializedBone" then string.format("UninitializedBone { bone: %d }", result.bone)
            else result.tag), 0)
    end

    local publish_evaluated = v5.publish_evaluated
    local publication = p82.state.publication
    local packet2 = p82.packet
    local signup, signup2 = pcall(publish_evaluated, publication, p83, p84, packet2, 0.01666666753590107, "signup")

    if signup then
        return
    end

    error("Skater pose publication: " .. (if type(signup2) ~= "table" then tostring(signup2)
        elseif signup2.tag == nil then tostring(signup2)
        elseif signup2.tag == "UninitializedBone" then string.format("UninitializedBone { bone: %d }", signup2.bone)
        else signup2.tag), 0)
end

t1.SkaterAnimation.reset_and_publish_reference = reset_and_publish_reference

local function reset_and_publish(p86, p87, p88, p89) -- line: 371
    -- upvalues: v4 (copy), v5 (copy), reset_and_publish_reference (copy)
    local packet = p86.packet
    local bone_count = packet.bone_count

    if not (bone_count >= 0)
        or not (bone_count < 2147483648)
        or #p87 < bone_count
        or #p88 < bone_count
        or #packet.hierarchy < bone_count
        or #packet["local"] < bone_count then
        return reset_and_publish_reference(p86, p87, p88, p89)
    else
        local reset_without_pose = v4.reset_without_pose
        local ok, result = pcall(reset_without_pose, packet, p89)

        if not ok then
            error("Animation packet reset: " .. (if type(result) ~= "table" then tostring(result)
                elseif result.tag == nil then tostring(result)
                elseif result.tag == "UninitializedBone" then string.format("UninitializedBone { bone: %d }", result.bone)
                else result.tag), 0)
        end
    end

    local publish_evaluated_owned = v5.publish_evaluated_owned
    local publication = p86.state.publication
    local signup, signup2 = pcall(publish_evaluated_owned, publication, p87, p88, packet, 0.01666666753590107, "signup")

    if signup then
        return
    end

    error("Skater pose publication: " .. (if type(signup2) ~= "table" then tostring(signup2)
        elseif signup2.tag == nil then tostring(signup2)
        elseif signup2.tag == "UninitializedBone" then string.format("UninitializedBone { bone: %d }", signup2.bone)
        else signup2.tag), 0)
end

t1.SkaterAnimation.reset_and_publish = reset_and_publish

local function reset_and_publish_in_place(p90, p91, p92) -- line: 430
    -- upvalues: PoseEvaluator (copy), v4 (copy), v5 (copy)
    local packet = p90.packet
    local reset_without_pose = v4.reset_without_pose
    local ok, result = pcall(reset_without_pose, packet, p92)

    if not ok then
        error("Animation packet reset: " .. (if type(result) ~= "table" then tostring(result)
            elseif result.tag == nil then tostring(result)
            elseif result.tag == "UninitializedBone" then string.format("UninitializedBone { bone: %d }", result.bone)
            else result.tag), 0)
    end

    local hierarchy, v19 = packet.hierarchy, packet["local"]

    PoseEvaluator.write_matrices(p90.evaluator, p91, hierarchy, v19)

    local publish_evaluated_owned = v5.publish_evaluated_owned
    local publication = p90.state.publication
    local signup, signup2 = pcall(publish_evaluated_owned, publication, hierarchy, v19, packet, 0.01666666753590107, "signup")

    if signup then
        return
    end

    error("Skater pose publication: " .. (if type(signup2) ~= "table" then tostring(signup2)
        elseif signup2.tag == nil then tostring(signup2)
        elseif signup2.tag == "UninitializedBone" then string.format("UninitializedBone { bone: %d }", signup2.bone)
        else signup2.tag), 0)
end

t1.SkaterAnimation.reset_and_publish_in_place = reset_and_publish_in_place

function t1.SkaterAnimation.advance(p93, p94, p95, p96, p97, p98) -- line: 458
    -- upvalues: rt (copy), PoseEvaluator (copy), ActionHost (copy), MotionHost (copy), MotionAnimation (copy), IntentMap (copy), v3 (copy), PacketAttributes (copy), Controller (copy), AnimationState (copy), ActionInput (copy), PriorMotionState (copy), GraphDiagnostics (copy), v6 (ref), v7 (copy), v8 (copy), SkaterAnimation (copy), reset_and_publish (copy), reset_and_publish_in_place (copy)
    local ticks = p93.ticks

    SkaterAnimation.publish_physical(p93, p97)
    ActionHost.prepare_input(p93.action, {
        tick = ticks,
        controls = ActionInput.from_values(p96),
        prior_motion = PriorMotionState.from_values(p93.motion.animation.motion_intents),
        animation_attributes = rt.copy(MotionAnimation.tree_attributes(p93.motion.animation))
    })
    p93.action.is_tricking = p93.motion.flags.doing_trick

    local action_controller = p93.action_controller
    local program = p94.action.runtime.program
    local action = p93.action

    v7.value = action

    if v6 then
        Controller.update_typed(action_controller, program, p95, v7, ActionHost, action, v7.scratch)
    else
        Controller.update(action_controller, program, p95, v7)
    end

    v7.value = nil

    if not GraphDiagnostics.is_empty(p93.action.errors) then
        error(GraphDiagnostics.join(p93.action.errors, "\n"), 0)
    end

    local v20 = ActionHost.output(p93.action)

    MotionAnimation.begin_graph_update(p93.motion.animation)
    MotionHost.accept_action_graph(p93.motion, {
        tick = v20.tick,
        action = v20
    })
    p93.motion.animation_phase = p93.state.phase

    local motion_controller = p93.motion_controller
    local program2 = p94.motion.runtime.program
    local motion = p93.motion

    v8.value = motion

    if v6 then
        Controller.update_typed(motion_controller, program2, p95, v8, MotionHost, motion, v8.scratch)
    else
        Controller.update(motion_controller, program2, p95, v8)
    end

    v8.value = nil
    p93.state.phase = p93.motion.animation_phase

    if not GraphDiagnostics.is_empty(p93.motion.errors) then
        error(GraphDiagnostics.join(p93.motion.errors, "\n"), 0)
    end

    local skater_animation_flags = p93.motion.animation.skater_animation_flags

    if skater_animation_flags == nil then
        error("MotionGraph lost the SkaterAnim flag owner", 0)
    end

    p93.state.flags = skater_animation_flags

    local air_dismount_revert_frames = p93.motion.animation.air_dismount_revert_frames

    p93.motion.animation.air_dismount_revert_frames = nil

    if air_dismount_revert_frames ~= nil then
        p93.state.publication.air_dismount_revert_frames = air_dismount_revert_frames
    end

    p93.state.publication.relative_stance = rt.to_i32(p93.motion.animation.relative_stance)

    local reset_action_intents = p93.motion.animation.reset_action_intents

    p93.motion.animation.reset_action_intents = false

    if reset_action_intents then
        IntentMap.clear(p93.action.action_intents)
    end

    MotionAnimation.apply_parameters(p93.motion.animation)
    MotionAnimation.advance(p93.motion.animation, p95, p93.state.phase)
    MotionAnimation.refresh_tree_attributes(p93.motion.animation)
    AnimationState.apply_stance_events(p93.state, MotionAnimation.tree_attributes(p93.motion.animation))

    local v21 = MotionAnimation.evaluate_pose(p93.motion.animation, {
        update_history = true,
        cull_threshold = AnimationState.cull_threshold(p93.state)
    })
    local pose = p93.pose
    local v22 = PoseEvaluator.evaluate(p93.evaluator, v21)

    p93.pose = v22

    if pose ~= v22 then
        PoseEvaluator.release(pose)
    end

    local packet = p93.packet
    local bone_count = packet.bone_count
    local v23 = #v22 == bone_count and bone_count >= 0 and bone_count < 2147483648 and #packet.hierarchy == bone_count and #packet["local"] == bone_count
    local v24, v25

    if v23 then
        PoseEvaluator.check_hierarchy(p93.evaluator, v22)
    else
        v24 = PoseEvaluator.hierarchy(p93.evaluator, v22)
        v25 = table.create(#v22)

        for v26, v27 in ipairs(v22) do
            v25[v26] = v3.sqt_to_matrix(v27)
        end
    end

    PacketAttributes.replace_from(p93.attributes, p93.motion.animation.motion_attributes, MotionAnimation.tree_attributes(p93.motion.animation))
    AnimationState.prepare_publication(p93.state)

    if v23 then
        reset_and_publish_in_place(p93, v22, p98)
    else
        reset_and_publish(p93, v24, v25, p98)
    end

    AnimationState.finish_publication(p93.state)
    p93.motion.animation.skater_animation_flags = p93.state.flags
    p93.ticks += 1
end

function t1.SkaterAnimation.publish_physical(p99, p100) -- line: 564
    -- upvalues: rt (copy), AnimationState (copy)
    p99.motion.animation.natural_stance = rt.to_u32(p99.state.publication.natural_stance)
    p99.motion.animation.relative_stance = rt.to_u32(p99.state.publication.relative_stance)

    local speeds = p100.conditions.speeds

    if speeds == nil then
        error("Animation requires completed board speed output", 0)
    end

    local v28 = AnimationState.fakie(p99.state)
    local v29 = AnimationState.mirrored(p99.state)

    p99.action.stance = { v28, v29 }
    p99.action.condition_inputs = rt.copy(p100.conditions)
    p99.motion.condition_inputs = p100.conditions
    p99.motion.playback_context.is_mirrored = AnimationState.mirrored(p99.state)
    p99.motion.playback_context.is_switch = AnimationState.switch(p99.state)
    p99.motion.playback_context.board_available = p100.board_present
    p99.motion.physical = {
        turning = p100.feedback.turning,
        stance = { v28, v29 },
        forward_speed = speeds.forward_speed,
        time_since_teleport = p100.time_since_teleport,
        is_switch = AnimationState.switch(p99.state),
        foot_frame = p100.foot_frame
    }
    p99.motion.physical_stance = p100.physical_stance
    p99.motion.crouching_physical = p100.feedback.crouching
    p99.motion.body_tilt_physical = p100.body_tilt
    p99.motion.fakie_physical = p100.fakie
    p99.motion.pumping_acceleration = p100.feedback.pumping_acceleration

    local v30 = p100.board_present or not p100.physical_28_byte75

    p99.state.flags = bit32.bor(bit32.band(p99.state.flags, 4294836223), (bit32.lshift(if v30 then 1 else 0, 17)))
    p99.motion.animation.skater_animation_flags = p99.state.flags
end

return t1
