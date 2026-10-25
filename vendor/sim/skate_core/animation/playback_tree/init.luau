-- Порт skate-3-rust-engine (GPL-3.0) — github.com/SK8-ENGINE/skate-3-rust-engine
-- ROBLOX: взято из примерочного плейса (декомпилированный байткод: имена локальных
-- переменных утеряны, f32-округления нет). Сверено с нашим бит-в-бит портом только частично.

local sim = game:GetService("ReplicatedStorage"):WaitForChild("Skate3"):WaitForChild("sim")
local rt = require(sim.rt)
local import = require(sim.import)
local ClipClock = import("skate_core/animation/clip_clock").ClipClock
local v1 = import("skate_core/animation/output/attributes")
local PlaybackClip = import("skate_core/animation/playback_clip").PlaybackClip
local AttributeMirror = import("skate_core/animation/playback_attributes").AttributeMirror
local PosturePose = import("skate_core/animation/posture").PosturePose
local v2

local function PhaseBlend() -- line: 19
    -- upvalues: import (copy), v2 (ref)
    local v3 = v2

    if v3 == nil then
        v3 = import("skate_core/animation/phase_blend").PhaseBlend
        v2 = v3
    end

    return v3
end

local v4

local function BlendSpace() -- line: 28
    -- upvalues: import (copy), v4 (ref)
    local v5 = v4

    if v5 == nil then
        v5 = import("skate_core/animation/playback_tree/blend_space").BlendSpace
        v4 = v5
    end

    return v5
end

local v6

local function SelectionSpace() -- line: 37
    -- upvalues: import (copy), v6 (ref)
    local v7 = v6

    if v7 == nil then
        v7 = import("skate_core/animation/playback_tree/selection_space").SelectionSpace
        v6 = v7
    end

    return v7
end

local v8

local function PlaybackTransition() -- line: 46
    -- upvalues: import (copy), v8 (ref)
    local v9 = v8

    if v9 == nil then
        v9 = import("skate_core/animation/playback_transition").PlaybackTransition
        v8 = v9
    end

    return v9
end

local t1 = {
    PlaybackTree = {},
    PoseCommand = {}
}

function t1.PoseCommand.eq(p1, p2) -- line: 90
    if p1.tag ~= p2.tag then
        return false
    end

    local tag = p1.tag

    if tag == "Clip" then
        if p1.name == p2.name and p1.previous_time == p2.previous_time and p1.time == p2.time then
            return p1.loops == p2.loops
        end

        return false
    end

    if tag == "Blend" then
        return p1.weight == p2.weight
    end

    if tag == "WeightedBlend" then
        if #p1.weights ~= #p2.weights then
            return false
        end

        for i = 1, #p1.weights do
            if p1.weights[i] ~= p2.weights[i] then
                return false
            end
        end

        return true
    end

    if tag == "ChannelBlend" then
        if p1.weight == p2.weight then
            return p1.use_channels_from_weights == p2.use_channels_from_weights
        end

        return false
    end

    if tag == "Pose" then
        return p1.name == p2.name
    end

    if tag == "Add" then
        return p1.motion_is_a == p2.motion_is_a
    end

    return p1.trajectory_mode == p2.trajectory_mode
end

t1.Evaluation = {}

function t1.PlaybackTree.length(p3) -- line: 123
    -- upvalues: import (copy), v4 (ref), v6 (ref), t1 (copy)
    local tag = p3.tag

    if tag == "Clip" then
        return p3.clip.clock.length
    end

    if tag == "PhaseBlend" then
        return p3[1].length
    end

    if tag == "BlendSpace" then
        local v10 = v4

        if v10 == nil then
            v10 = import("skate_core/animation/playback_tree/blend_space").BlendSpace
            v4 = v10
        end

        return v10.length(p3[1])
    end

    if tag == "SelectionSpace" then
        local v11 = v6

        if v11 == nil then
            v11 = import("skate_core/animation/playback_tree/selection_space").SelectionSpace
            v6 = v11
        end

        local v12 = v11.current(p3[1])

        if v12 == nil then
            return 0
        end

        return t1.PlaybackTree.length(v12)
    end

    if tag == "Transition" then
        return t1.PlaybackTree.length(p3[1].to)
    end

    return t1.PlaybackTree.length(p3.motion)
end

function t1.PlaybackTree.time(p4) -- line: 144
    -- upvalues: import (copy), ClipClock (copy), v6 (ref), t1 (copy)
    local tag = p4.tag

    if tag == "Clip" then
        return ClipClock.sample_time(p4.clip.clock)
    end

    if tag == "PhaseBlend" or tag == "BlendSpace" then
        return p4[1].time
    end

    if tag == "SelectionSpace" then
        local v13 = v6

        if v13 == nil then
            v13 = import("skate_core/animation/playback_tree/selection_space").SelectionSpace
            v6 = v13
        end

        local v14 = v13.current(p4[1])

        if v14 == nil then
            return 0
        end

        return t1.PlaybackTree.time(v14)
    end

    if tag == "Transition" then
        return t1.PlaybackTree.time(p4[1].to)
    end

    return t1.PlaybackTree.time(p4.motion)
end

function t1.PlaybackTree.set_time(p5, p6) -- line: 165
    -- upvalues: import (copy), ClipClock (copy), v2 (ref), v4 (ref), v6 (ref), t1 (copy)
    local tag = p5.tag

    if tag == "Clip" then
        ClipClock.set_time(p5.clip.clock, p6)
    elseif tag == "PhaseBlend" then
        local v15 = v2

        if v15 == nil then
            v15 = import("skate_core/animation/phase_blend").PhaseBlend
            v2 = v15
        end

        v15.set_time(p5[1], p6)
    elseif tag == "BlendSpace" then
        local v16 = v4

        if v16 == nil then
            v16 = import("skate_core/animation/playback_tree/blend_space").BlendSpace
            v4 = v16
        end

        v16.set_time(p5[1], p6)
    elseif tag == "SelectionSpace" then
        local v17 = v6

        if v17 == nil then
            v17 = import("skate_core/animation/playback_tree/selection_space").SelectionSpace
            v6 = v17
        end

        v17.set_time(p5[1], p6)
    elseif tag == "Transition" then
        t1.PlaybackTree.set_time(p5[1].to, p6)
    else
        t1.PlaybackTree.set_time(p5.motion, p6)
    end
end

function t1.PlaybackTree.set_speed(p7, p8) -- line: 182
    -- upvalues: import (copy), ClipClock (copy), v2 (ref), v4 (ref), v6 (ref), t1 (copy)
    local tag = p7.tag

    if tag == "Clip" then
        ClipClock.set_speed(p7.clip.clock, p8)
    elseif tag == "PhaseBlend" then
        local v18 = v2

        if v18 == nil then
            v18 = import("skate_core/animation/phase_blend").PhaseBlend
            v2 = v18
        end

        v18.set_speed(p7[1], p8)
    elseif tag == "BlendSpace" then
        local v19 = v4

        if v19 == nil then
            v19 = import("skate_core/animation/playback_tree/blend_space").BlendSpace
            v4 = v19
        end

        v19.set_speed(p7[1], p8)
    elseif tag == "SelectionSpace" then
        local v20 = v6

        if v20 == nil then
            v20 = import("skate_core/animation/playback_tree/selection_space").SelectionSpace
            v6 = v20
        end

        v20.set_speed(p7[1], p8)
    elseif tag == "Transition" then
        t1.PlaybackTree.set_speed(p7[1].to, p8)
    else
        t1.PlaybackTree.set_speed(p7.motion, p8)
    end
end

function t1.PlaybackTree.advance(p9, p10, p11, p12) -- line: 200
    -- upvalues: import (copy), ClipClock (copy), v2 (ref), v4 (ref), v6 (ref), v8 (ref), t1 (copy)
    local tag = p9.tag

    if tag == "Clip" then
        ClipClock.advance(p9.clip.clock, p10, p11, p12)
    elseif tag == "PhaseBlend" then
        local v21 = v2

        if v21 == nil then
            v21 = import("skate_core/animation/phase_blend").PhaseBlend
            v2 = v21
        end

        v21.advance(p9[1], p10, p11, p12)
    elseif tag == "BlendSpace" then
        local v22 = v4

        if v22 == nil then
            v22 = import("skate_core/animation/playback_tree/blend_space").BlendSpace
            v4 = v22
        end

        v22.advance(p9[1], p10, p11, p12)
    elseif tag == "SelectionSpace" then
        local v23 = v6

        if v23 == nil then
            v23 = import("skate_core/animation/playback_tree/selection_space").SelectionSpace
            v6 = v23
        end

        local v24 = v23.current_mut(p9[1])

        if v24 ~= nil then
            t1.PlaybackTree.advance(v24, p10, p11, p12)
        end
    elseif tag == "Transition" then
        local v25 = v8

        if v25 == nil then
            v25 = import("skate_core/animation/playback_transition").PlaybackTransition
            v8 = v25
        end

        v25.advance(p9[1], p10, p11, p12)
    else
        t1.PlaybackTree.advance(p9.motion, p10, p11, p12)
    end
end

function t1.PlaybackTree.set_attributes(p13, p14) -- line: 221
    -- upvalues: import (copy), v2 (ref), v4 (ref), v6 (ref), v8 (ref), t1 (copy)
    local tag = p13.tag

    if tag == "Clip" then
        return false
    end

    if tag == "PhaseBlend" then
        local v26 = v2

        if v26 == nil then
            v26 = import("skate_core/animation/phase_blend").PhaseBlend
            v2 = v26
        end

        return v26.set_attributes(p13[1], p14)
    end

    if tag == "BlendSpace" then
        local v27 = v4

        if v27 == nil then
            v27 = import("skate_core/animation/playback_tree/blend_space").BlendSpace
            v4 = v27
        end

        return v27.set_attributes(p13[1], p14)
    end

    if tag == "SelectionSpace" then
        local v28 = v6

        if v28 == nil then
            v28 = import("skate_core/animation/playback_tree/selection_space").SelectionSpace
            v6 = v28
        end

        return v28.set_attributes(p13[1], p14)
    end

    if tag ~= "Transition" then
        return t1.PlaybackTree.set_attributes(p13.motion, p14)
    end

    local v29 = v8

    if v29 == nil then
        v29 = import("skate_core/animation/playback_transition").PlaybackTransition
        v8 = v29
    end

    return v29.set_attributes(p13[1], p14)
end

function t1.PlaybackTree.attributes(p15, p16) -- line: 239
    -- upvalues: import (copy), PlaybackClip (copy), AttributeMirror (copy), v2 (ref), v4 (ref), v6 (ref), v8 (ref), t1 (copy)
    local tag = p15.tag

    if tag == "Clip" then
        return PlaybackClip.attributes(p15.clip, p16)
    end

    if tag == "PhaseBlend" then
        local v30 = v2

        if v30 == nil then
            v30 = import("skate_core/animation/phase_blend").PhaseBlend
            v2 = v30
        end

        return v30.attributes(p15[1], p16)
    end

    if tag == "BlendSpace" then
        local v31 = v4

        if v31 == nil then
            v31 = import("skate_core/animation/playback_tree/blend_space").BlendSpace
            v4 = v31
        end

        return v31.attributes(p15[1], p16)
    end

    if tag == "SelectionSpace" then
        local v32 = v6

        if v32 == nil then
            v32 = import("skate_core/animation/playback_tree/selection_space").SelectionSpace
            v6 = v32
        end

        local v33 = v32.current(p15[1])

        if v33 == nil then
            error("SelectionSpace attributes requested before native selection", 0)
        end

        return t1.PlaybackTree.attributes(v33, p16)
    end

    if tag == "Transition" then
        local v34 = v8

        if v34 == nil then
            v34 = import("skate_core/animation/playback_transition").PlaybackTransition
            v8 = v34
        end

        return v34.attributes(p15[1], p16)
    end

    local v35 = t1.PlaybackTree.attributes(p15.motion, p16)

    for _ = 1, #p15.mirror_modes do
        for _, v36 in v35 do
            AttributeMirror.apply(p15.attribute_mirror, v36)
        end
    end

    return v35
end

function t1.PlaybackTree.attribute(p17, p18, p19) -- line: 267
    -- upvalues: rt (copy), v1 (copy), t1 (copy)
    local v37 = v1.MotionGraphAttribute.to_animation({
        value = 0,
        name = rt.copy(p18)
    })

    return if t1.PlaybackTree.query_attribute(p17, p18, p19, v37) then v37 else nil
end

function t1.PlaybackTree.query_attribute_reference(p20, p21, p22, p23) -- line: 276
    -- upvalues: import (copy), v1 (copy), PlaybackClip (copy), AttributeMirror (copy), v2 (ref), v4 (ref), v6 (ref), v8 (ref), t1 (copy)
    local tag = p20.tag

    if tag == "PhaseBlend" then
        local v38 = v2

        if v38 == nil then
            v38 = import("skate_core/animation/phase_blend").PhaseBlend
            v2 = v38
        end

        return v38.query_attribute(p20[1], p21, p22, p23)
    end

    if tag == "BlendSpace" then
        local v39 = v4

        if v39 == nil then
            v39 = import("skate_core/animation/playback_tree/blend_space").BlendSpace
            v4 = v39
        end

        return v39.query_attribute(p20[1], p21, p22, p23)
    end

    if tag == "SelectionSpace" then
        local v40 = v6

        if v40 == nil then
            v40 = import("skate_core/animation/playback_tree/selection_space").SelectionSpace
            v6 = v40
        end

        local v41 = v40.current(p20[1])

        if v41 == nil then
            error("SelectionSpace attribute requested before native selection", 0)
        end

        return t1.PlaybackTree.query_attribute(v41, p21, p22, p23)
    end

    if tag == "Transition" then
        local v42 = v8

        if v42 == nil then
            v42 = import("skate_core/animation/playback_transition").PlaybackTransition
            v8 = v42
        end

        return v42.query_attribute(p20[1], p21, p22, p23)
    end

    if tag == "BindPose" then
        local v43 = t1.PlaybackTree.query_attribute(p20.motion, p21, p22, p23)

        if v43 then
            for _ = 1, #p20.mirror_modes do
                AttributeMirror.apply(p20.attribute_mirror, p23)
            end
        end

        return v43
    end

    local v44 = PlaybackClip.attribute(p20.clip, p21, p22)

    if v44 == nil then
        return false
    end

    v1.AnimationAttribute.copy_from(p23, v44)

    return true
end

function t1.PlaybackTree.query_attribute(p24, p25, p26, p27) -- line: 313
    -- upvalues: import (copy), PlaybackClip (copy), AttributeMirror (copy), v2 (ref), v4 (ref), v6 (ref), v8 (ref), t1 (copy)
    local tag = p24.tag

    if tag == "PhaseBlend" then
        local v45 = v2

        if v45 == nil then
            v45 = import("skate_core/animation/phase_blend").PhaseBlend
            v2 = v45
        end

        return v45.query_attribute(p24[1], p25, p26, p27)
    end

    if tag == "BlendSpace" then
        local v46 = v4

        if v46 == nil then
            v46 = import("skate_core/animation/playback_tree/blend_space").BlendSpace
            v4 = v46
        end

        return v46.query_attribute(p24[1], p25, p26, p27)
    end

    if tag == "SelectionSpace" then
        local v47 = v6

        if v47 == nil then
            v47 = import("skate_core/animation/playback_tree/selection_space").SelectionSpace
            v6 = v47
        end

        local v48 = v47.current(p24[1])

        if v48 == nil then
            error("SelectionSpace attribute requested before native selection", 0)
        end

        return t1.PlaybackTree.query_attribute(v48, p25, p26, p27)
    end

    if tag == "Transition" then
        local v49 = v8

        if v49 == nil then
            v49 = import("skate_core/animation/playback_transition").PlaybackTransition
            v8 = v49
        end

        return v49.query_attribute(p24[1], p25, p26, p27)
    end

    if tag ~= "BindPose" then
        return PlaybackClip.query_into(p24.clip, p25, p26, p27)
    end

    local v50 = t1.PlaybackTree.query_attribute(p24.motion, p25, p26, p27)

    if v50 then
        for _ = 1, #p24.mirror_modes do
            AttributeMirror.apply(p24.attribute_mirror, p27)
        end
    end

    return v50
end

function t1.PlaybackTree.evaluate(p28, p29, p30, p31) -- line: 345
    -- upvalues: import (copy), ClipClock (copy), PosturePose (copy), v2 (ref), v4 (ref), v6 (ref), v8 (ref), t1 (copy)
    local tag = p28.tag

    if tag == "PhaseBlend" then
        local v51 = v2

        if v51 == nil then
            v51 = import("skate_core/animation/phase_blend").PhaseBlend
            v2 = v51
        end

        return v51.evaluate(p28[1], p29, p30, p31)
    end

    if tag == "BlendSpace" then
        local v52 = v4

        if v52 == nil then
            v52 = import("skate_core/animation/playback_tree/blend_space").BlendSpace
            v4 = v52
        end

        return v52.evaluate(p28[1], p29, p30, p31)
    end

    if tag == "SelectionSpace" then
        if not p30 then
            return false
        end

        local v53 = v6

        if v53 == nil then
            v53 = import("skate_core/animation/playback_tree/selection_space").SelectionSpace
            v6 = v53
        end

        local v54 = v53.current_mut(p28[1])

        if v54 == nil then
            error("SelectionSpace evaluated before native selection", 0)
        end

        return t1.PlaybackTree.evaluate(v54, p29, true, p31)
    end

    if tag == "Transition" then
        local v55 = v8

        if v55 == nil then
            v55 = import("skate_core/animation/playback_transition").PlaybackTransition
            v8 = v55
        end

        return v55.evaluate(p28[1], p29, p30, p31)
    end

    if tag == "BindPose" then
        local v56 = t1.PlaybackTree.evaluate(p28.motion, p29, p30, p31)

        if v56 then
            if p28.posture ~= nil then
                local posture = p28.posture

                table.insert(p31, {
                    tag = "Pose",
                    name = PosturePose.name(posture)
                })
                table.insert(p31, {
                    tag = "Add",
                    motion_is_a = true
                })
            end

            table.insert(p31, {
                tag = "Pose",
                name = "RIG_TPOSE"
            })
            table.insert(p31, {
                tag = "Add",
                motion_is_a = true
            })

            if p28.board_backwards then
                table.insert(p31, {
                    tag = "Pose",
                    name = "BOARD_BACKWARDS"
                })
                table.insert(p31, {
                    tag = "Add",
                    motion_is_a = false
                })
                table.insert(p31, {
                    tag = "Pose",
                    name = "BOARD_BACKWARDS_IK"
                })
                table.insert(p31, {
                    tag = "Add",
                    motion_is_a = true
                })
            end

            for _, v57 in p28.mirror_modes do
                table.insert(p31, {
                    tag = "Mirror",
                    trajectory_mode = v57
                })
            end
        end

        return v56
    end

    local clock = p28.clip.clock
    local v58 = clock.base_speed * clock.speed
    local v59 = (clock.frames - 1) / clock.fps

    local function bound(p32) -- line: 388
        -- upvalues: v59 (copy)
        local v60 = if -p32 >= 0 then 0 else p32

        if v59 - v60 >= 0 then
            return v60
        end

        return v59
    end

    local v61 = clock.previous_time * v58

    if -v61 >= 0 then
        v61 = 0
    end

    if not (v59 - v61 >= 0) then
        v61 = v59
    end

    local v62 = ClipClock.sample_time(clock) * v58

    if -v62 >= 0 then
        v62 = 0
    end

    if not (v59 - v62 >= 0) then
        v62 = v59
    end

    if clock.loops_since_evaluation == 0 and v62 < v61 then
        v61 = v62
    end

    if p30 then
        table.insert(p31, {
            tag = "Clip",
            name = p28.name,
            previous_time = v61,
            time = v62,
            loops = clock.loops_since_evaluation
        })
    end

    if p29.update_history then
        ClipClock.commit_evaluation(clock)
    end

    return p30
end

return t1
